use std::cell::RefCell;
use std::collections::{HashMap, HashSet};
use std::ops::Range;

use crate::Format;
use crate::lex::{Doc, Kind, NONE, Token, comment_key, hash, lex, reindent, same, shift, within_len};
use crate::myers::{self, Op, Tag};

/// What a merge did.
#[derive(Default, Debug, Clone)]
pub struct Stats {
    /// Text edits applied to `before`.
    pub edits: usize,
    /// Blocks of code that the edit moved.
    pub moves: usize,
    /// Blocks of code that the printer moved in the classes the edit changed; they follow its order.
    pub reordered: usize,
    /// Comments next to deleted code that were kept, since they could belong to the code above.
    pub ambiguous_comments_kept: usize,
    pub deleted_comments: usize,
    /// Tokens of `before` that `before_canonical` does not have, or the reverse.
    pub align_mismatches: usize,
}

/// Changed runs of tokens: `c` in the canonical text, `b` in `after`.
#[derive(Clone, Debug, PartialEq, Eq)]
struct Edit {
    c: Range<usize>,
    b: Range<usize>,
}

/// Insert `ins` is code that delete `del` removed; `sub` is the diff of the two.
struct Move {
    del: usize,
    ins: usize,
    sub: Vec<Op>,
}

struct TextEdit {
    start: usize,
    end: usize,
    text: String,
}

const GOOD_BEFORE: [&str; 10] = [
    ";",
    ",",
    "(",
    "{",
    "[",
    "equation",
    "algorithm",
    "public",
    "protected",
    "initial",
];
const UNIT_START: [&str; 7] = [
    "equation",
    "algorithm",
    "public",
    "protected",
    "initial",
    "annotation",
    "end",
];
const CLASS_KEYWORDS: [&str; 9] = [
    "model",
    "class",
    "block",
    "connector",
    "record",
    "package",
    "function",
    "type",
    "operator",
];
const MIN_MOVE: usize = 3;
const MIN_NEAR_MOVE: usize = 5;
const NEAR_MOVE_BUDGET: usize = 4_000_000;

pub fn merge(before: &str, before_canonical: &str, after: &str) -> (String, Stats) {
    let mut stats = Stats::default();
    let merged = if before == after {
        before.to_owned()
    } else {
        merge_texts(before, before_canonical, after, &mut stats)
    };
    (merged, stats)
}

pub fn render(before: &str, merged: &str, format: Format) -> String {
    match format {
        Format::Plain => merged.to_owned(),
        _ => render_diff(before, merged, format),
    }
}

pub fn code_equal(a: &str, b: &str) -> bool {
    let code = |text: &str| -> Vec<Token> {
        let toks: Vec<Token> = lex(text).into_iter().filter(|t| !t.kind.is_trivia()).collect();
        toks[within_len(&toks, text)..].to_vec()
    };
    let (ta, tb) = (code(a), code(b));
    ta.len() == tb.len()
        && ta
            .iter()
            .zip(&tb)
            .all(|(x, y)| same(x.kind, &a[x.start..x.end], y.kind, &b[y.start..y.end]))
}

fn merge_texts(a: &str, c: &str, b: &str, stats: &mut Stats) -> String {
    let (da, dc, db) = (Doc::new(a), Doc::new(c), Doc::new(b));
    if da.sig.is_empty() {
        return b.to_owned();
    }
    let ops_cb = token_diff(&dc, &db);
    let mut edits = slide(collapse(&ops_cb), &dc, &dc.dkeys, &db, &db.dkeys);
    let wc = dc.within_len();
    if wc > 0 && db.within_len() == 0 {
        edits.retain(|e| !(e.c == (0..wc) && e.b.is_empty()));
    }
    let ops_ac = align(&da, &dc);
    match reorder(&da, &dc, &ops_ac, &edits, stats) {
        None => merge_docs(&da, &dc, &db, &ops_ac, &ops_cb, &edits, stats),
        Some(a1) => {
            let da1 = Doc::new(&a1);
            let ops1 = align(&da1, &dc);
            merge_docs(&da1, &dc, &db, &ops1, &ops_cb, &edits, stats)
        }
    }
}

/// `da` with the code that the printer put elsewhere moved there, in the
/// classes that `edits` (canonical to after) change, so that their order is
/// the order of `dc`. `ops` is the diff of `da` and `dc`.
fn reorder(da: &Doc, dc: &Doc, ops: &[Op], edits: &[Edit], stats: &mut Stats) -> Option<String> {
    if edits.is_empty() || ops.iter().all(|o| o.tag == Tag::Equal) {
        return None;
    }
    let class = class_of(dc);
    let class_at = |pos: usize| class.get(pos).copied().unwrap_or(NONE);
    let touched: HashSet<usize> = edits.iter().map(|e| class_at(e.c.start)).collect();
    let moved = slide(collapse(ops), da, &da.keys, dc, &dc.keys);
    let moves = find_moves(&moved, &da.keys, &dc.keys, false, |ins, del| {
        let at = class_at(ins.b.start);
        touched.contains(&at) && del.is_none_or(|d| class_at(d.b.start) == at)
    });
    if moves.is_empty() {
        return None;
    }
    stats.reordered += moves.len();
    let amap: Vec<usize> = (0..da.sig.len()).collect();
    let creg: Vec<(usize, usize)> = (0..da.sig.len()).map(|i| (i, i + 1)).collect();
    let bmap = targets(ops, &amap, dc.sig.len());
    let ctx = Ctx::new(da, dc, &creg, &bmap);
    let tes = ctx.build_all(&moved, &moves, false, true, stats);
    Some(apply(da.text, tes))
}

/// `da` with the changes `edits` from `dc` to `db`; `ops_ac` is the diff of `da` and `dc`.
fn merge_docs(da: &Doc, dc: &Doc, db: &Doc, ops_ac: &[Op], ops_cb: &[Op], edits: &[Edit], stats: &mut Stats) -> String {
    let (amap, creg) = canonical_maps(ops_ac, dc.sig.len(), stats);
    let moves = find_moves(edits, &dc.dkeys, &db.dkeys, true, |_, _| true);
    stats.moves += moves.len();
    let bmap = targets(ops_cb, &amap, db.sig.len());
    let ctx = Ctx::new(da, db, &creg, &bmap);
    let tes = ctx.build_all(edits, &moves, true, false, stats);
    stats.edits += tes.len();
    apply(da.text, tes)
}

/// For each canonical token, the token of `before` it is (or NONE), and the
/// range of `before` it stands for: its token, or the tokens of the same
/// difference when the printer changed them.
fn canonical_maps(ops: &[Op], n: usize, stats: &mut Stats) -> (Vec<usize>, Vec<(usize, usize)>) {
    let mut amap = vec![NONE; n];
    let mut creg = vec![(0, 0); n];
    let mut k = 0;
    while k < ops.len() {
        if ops[k].tag == Tag::Equal {
            for d in 0..ops[k].a.len() {
                amap[ops[k].b.start + d] = ops[k].a.start + d;
                creg[ops[k].b.start + d] = (ops[k].a.start + d, ops[k].a.start + d + 1);
            }
            k += 1;
            continue;
        }
        let (mut ar, mut br) = (ops[k].a.clone(), ops[k].b.clone());
        k += 1;
        while k < ops.len() && ops[k].tag != Tag::Equal {
            ar.end = ops[k].a.end;
            br.end = ops[k].b.end;
            k += 1;
        }
        stats.align_mismatches += ar.len().max(br.len());
        for i in br {
            creg[i] = (ar.start, ar.end);
        }
    }
    (amap, creg)
}

/// For each token of the target of `ops`, the token of `before` it is, or NONE.
fn targets(ops: &[Op], amap: &[usize], n: usize) -> Vec<usize> {
    let mut bmap = vec![NONE; n];
    for op in ops.iter().filter(|o| o.tag == Tag::Equal) {
        for d in 0..op.a.len() {
            bmap[op.b.start + d] = amap[op.a.start + d];
        }
    }
    bmap
}

/// For each token, the start of the innermost long class definition
/// (`model M ... end M;`) around it, or NONE.
fn class_of(d: &Doc) -> Vec<usize> {
    let n = d.sig.len();
    let mut stack: Vec<(&str, usize)> = Vec::new();
    let mut spans = Vec::new();
    let mut k = 0;
    while k < n {
        let t = d.st(k);
        if t == "end" && k + 2 < n && d.st(k + 2) == ";" && stack.last().is_some_and(|(name, _)| *name == d.st(k + 1)) {
            if let Some((_, start)) = stack.pop() {
                spans.push(start..k + 3);
            }
            k += 3;
            continue;
        }
        if CLASS_KEYWORDS.contains(&t) && d.encl[k] == NONE {
            let mut j = k + 1;
            while j < n && (CLASS_KEYWORDS.contains(&d.st(j)) || d.st(j) == "extends") {
                j += 1;
            }
            if j < n && d.sig[j].kind == Kind::Ident && !matches!(d.sig.get(j + 1).map(|t| d.s(t)), Some("=" | "(")) {
                stack.push((d.st(j), k));
                k = j + 1;
                continue;
            }
        }
        k += 1;
    }
    spans.sort_by_key(|r| r.start);
    let mut class = vec![NONE; n];
    for r in spans {
        class[r.clone()].fill(r.start);
    }
    class
}

fn hash_keys(keys: &[u64]) -> u64 {
    keys.iter().fold(0, |h, k| hash(h, &k.to_le_bytes()))
}

fn code_lines(d: &Doc) -> Vec<Range<usize>> {
    let lines = d.sig_lines();
    let mut out = Vec::new();
    let mut start = 0;
    for k in 1..=lines.len() {
        if k == lines.len() || lines[k] != lines[k - 1] {
            out.push(start..k);
            start = k;
        }
    }
    out
}

/// Statements: runs of tokens that end with a `;` outside brackets, or before
/// a section keyword, `annotation` or `end`.
fn units(d: &Doc) -> Vec<Range<usize>> {
    let mut out = Vec::new();
    let mut start = 0;
    for k in 0..d.sig.len() {
        if d.encl[k] != NONE {
            continue;
        }
        let t = d.st(k);
        if k > start && UNIT_START.contains(&t) {
            out.push(start..k);
            start = k;
        }
        if t == ";" {
            out.push(start..k + 1);
            start = k + 1;
        }
    }
    if start < d.sig.len() {
        out.push(start..d.sig.len());
    }
    out
}

/// Pairs of equal elements of `a` and `b`, in order: the patience diff, which
/// anchors on elements that occur once in both and recurses between them.
fn patience(a: &[u64], b: &[u64]) -> Vec<(usize, usize)> {
    let mut out = Vec::new();
    let mut todo = vec![(0, a.len(), 0, b.len())];
    while let Some((mut a0, mut a1, mut b0, mut b1)) = todo.pop() {
        while a0 < a1 && b0 < b1 && a[a0] == b[b0] {
            out.push((a0, b0));
            a0 += 1;
            b0 += 1;
        }
        while a0 < a1 && b0 < b1 && a[a1 - 1] == b[b1 - 1] {
            a1 -= 1;
            b1 -= 1;
            out.push((a1, b1));
        }
        if a0 == a1 || b0 == b1 {
            continue;
        }
        let mut seen: HashMap<u64, (u32, u32, usize, usize)> = HashMap::new();
        for (i, k) in a.iter().enumerate().take(a1).skip(a0) {
            let e = seen.entry(*k).or_insert((0, 0, i, 0));
            e.0 += 1;
        }
        for (j, k) in b.iter().enumerate().take(b1).skip(b0) {
            if let Some(e) = seen.get_mut(k) {
                e.1 += 1;
                e.3 = j;
            }
        }
        let mut pairs: Vec<(usize, usize)> = seen
            .values()
            .filter(|e| e.0 == 1 && e.1 == 1)
            .map(|e| (e.2, e.3))
            .collect();
        pairs.sort_unstable();
        let anchors = increasing(&pairs);
        if anchors.is_empty() {
            continue;
        }
        let (mut pa, mut pb) = (a0, b0);
        for &(i, j) in &anchors {
            todo.push((pa, i, pb, j));
            out.push((i, j));
            pa = i + 1;
            pb = j + 1;
        }
        todo.push((pa, a1, pb, b1));
    }
    out.sort_unstable();
    out
}

/// The longest subsequence of `pairs` (sorted by .0) that also increases in .1.
fn increasing(pairs: &[(usize, usize)]) -> Vec<(usize, usize)> {
    let mut tails: Vec<usize> = Vec::new();
    let mut prev = vec![NONE; pairs.len()];
    for (k, &(_, j)) in pairs.iter().enumerate() {
        let pos = tails.partition_point(|&t| pairs[t].1 < j);
        if pos > 0 {
            prev[k] = tails[pos - 1];
        }
        if pos == tails.len() {
            tails.push(k);
        } else {
            tails[pos] = k;
        }
    }
    let mut out = Vec::new();
    let mut k = tails.last().copied().unwrap_or(NONE);
    while k != NONE {
        out.push(pairs[k]);
        k = prev[k];
    }
    out.reverse();
    out
}

/// The diff of `before` and its listing: statements first, where the printer
/// may have moved many of them, then tokens within the statements that differ.
fn align(da: &Doc, dc: &Doc) -> Vec<Op> {
    let (ua, uc) = (units(da), units(dc));
    let ka: Vec<u64> = ua.iter().map(|r| hash_keys(&da.keys[r.clone()])).collect();
    let kc: Vec<u64> = uc.iter().map(|r| hash_keys(&dc.keys[r.clone()])).collect();
    let mut ops = Vec::new();
    let (mut ta, mut tc) = (0, 0);
    let gap = |ops: &mut Vec<Op>, ra: Range<usize>, rc: Range<usize>| {
        for op in myers::diff(&da.keys[ra.clone()], &dc.keys[rc.clone()]) {
            ops.push(op.shifted(ra.start, rc.start));
        }
    };
    for (ia, ic) in patience(&ka, &kc) {
        let (ra, rc) = (ua[ia].clone(), uc[ic].clone());
        gap(&mut ops, ta..ra.start, tc..rc.start);
        if da.keys[ra.clone()] == dc.keys[rc.clone()] {
            ops.push(Op {
                tag: Tag::Equal,
                a: ra.clone(),
                b: rc.clone(),
            });
        } else {
            gap(&mut ops, ra.clone(), rc.clone());
        }
        ta = ra.end;
        tc = rc.end;
    }
    gap(&mut ops, ta..da.sig.len(), tc..dc.sig.len());
    myers::merge_adjacent(ops)
}

/// Diff of the significant tokens, by lines first: both texts come from the
/// printer, which puts an element on a line of its own.
fn token_diff(c: &Doc, b: &Doc) -> Vec<Op> {
    let (lc, lb) = (code_lines(c), code_lines(b));
    let kc: Vec<u64> = lc.iter().map(|r| hash_keys(&c.dkeys[r.clone()])).collect();
    let kb: Vec<u64> = lb.iter().map(|r| hash_keys(&b.dkeys[r.clone()])).collect();
    let tokens = |lines: &[Range<usize>], r: &Range<usize>, n: usize| -> Range<usize> {
        if r.is_empty() {
            let s = lines.get(r.start).map_or(n, |l| l.start);
            s..s
        } else {
            lines[r.start].start..lines[r.end - 1].end
        }
    };
    let mut ops = Vec::new();
    let mut pending: Option<(Range<usize>, Range<usize>)> = None;
    let flush = |pending: &mut Option<(Range<usize>, Range<usize>)>, ops: &mut Vec<Op>| {
        if let Some((rc, rb)) = pending.take() {
            for op in myers::diff(&c.dkeys[rc.clone()], &b.dkeys[rb.clone()]) {
                ops.push(op.shifted(rc.start, rb.start));
            }
        }
    };
    for op in myers::diff(&kc, &kb) {
        let rc = tokens(&lc, &op.a, c.sig.len());
        let rb = tokens(&lb, &op.b, b.sig.len());
        if op.tag == Tag::Equal {
            flush(&mut pending, &mut ops);
            ops.push(Op {
                tag: Tag::Equal,
                a: rc,
                b: rb,
            });
        } else {
            pending = Some(match pending {
                None => (rc, rb),
                Some((pc, pb)) => (
                    pc.start.min(rc.start)..pc.end.max(rc.end),
                    pb.start.min(rb.start)..pb.end.max(rb.end),
                ),
            });
        }
    }
    flush(&mut pending, &mut ops);
    myers::merge_adjacent(ops)
}

fn collapse(ops: &[Op]) -> Vec<Edit> {
    let mut edits: Vec<Edit> = Vec::new();
    for op in ops.iter().filter(|o| o.tag != Tag::Equal) {
        match edits.last_mut() {
            Some(e) if e.c.end == op.a.start && e.b.end == op.b.start => {
                e.c.end = op.a.end;
                e.b.end = op.b.end;
            }
            _ => edits.push(Edit {
                c: op.a.clone(),
                b: op.b.clone(),
            }),
        }
    }
    edits
}

/// Slides pure insertions and deletions along equal tokens to where they
/// start and end at a separator, e.g. `x;` rather than `; x` (the diff slider).
fn slide(edits: Vec<Edit>, c: &Doc, ck: &[u64], b: &Doc, bk: &[u64]) -> Vec<Edit> {
    let mut out: Vec<Edit> = Vec::with_capacity(edits.len());
    for (n, e) in edits.iter().enumerate() {
        let lo_c = out.last().map_or(0, |x| x.c.end);
        let hi_c = edits.get(n + 1).map_or(ck.len(), |x| x.c.start);
        let (doc, seq, pos, run, lo, hi) = if e.c.is_empty() && !e.b.is_empty() {
            (
                b,
                bk,
                e.b.start,
                e.b.len(),
                e.b.start.saturating_sub(e.c.start - lo_c),
                e.b.end + (hi_c - e.c.end),
            )
        } else if e.b.is_empty() && !e.c.is_empty() {
            (c, ck, e.c.start, e.c.len(), lo_c, hi_c)
        } else {
            out.push(e.clone());
            continue;
        };
        let mut cands = vec![0isize];
        let mut s = pos;
        while s > lo && seq[s - 1] == seq[s + run - 1] {
            s -= 1;
            cands.push(s as isize - pos as isize);
        }
        let mut s = pos;
        while s + run < hi.min(seq.len()) && seq[s] == seq[s + run] {
            s += 1;
            cands.push(s as isize - pos as isize);
        }
        let score = |d: isize| {
            let first = (pos as isize + d) as usize;
            let end = first + run;
            let mut sc = 0;
            if first > 0 && GOOD_BEFORE.contains(&doc.st(first - 1)) {
                sc += 2;
            }
            if doc.st(first) == "," {
                sc += 1;
            }
            if matches!(doc.st(end - 1), ";" | ",") {
                sc += 2;
            }
            if end < doc.sig.len() && matches!(doc.st(end), ")" | "}" | "]") {
                sc += 1;
            }
            (sc, d)
        };
        let d = cands.into_iter().max_by_key(|&d| score(d)).unwrap_or(0);
        let mv = |r: &Range<usize>| (r.start as isize + d) as usize..(r.end as isize + d) as usize;
        out.push(Edit {
            c: mv(&e.c),
            b: mv(&e.b),
        });
    }
    out
}

/// Pairs insertions with deletions of the same code, the nearest first, where
/// `keep(insertion, Some(deletion))` holds; `keep(insertion, None)` selects the
/// insertions. With `near`, the inserted code may differ a little and may be
/// part of a longer deletion.
fn find_moves(
    edits: &[Edit],
    ck: &[u64],
    bk: &[u64],
    near: bool,
    keep: impl Fn(&Edit, Option<&Edit>) -> bool,
) -> Vec<Move> {
    let mut dels: HashMap<u64, Vec<usize>> = HashMap::new();
    for (i, e) in edits.iter().enumerate() {
        if e.b.is_empty() && e.c.len() >= MIN_MOVE {
            dels.entry(hash_keys(&ck[e.c.clone()])).or_default().push(i);
        }
    }
    let mut used = HashSet::new();
    let mut moves = Vec::new();
    let mut rest = Vec::new();
    for (i, e) in edits.iter().enumerate() {
        if !e.c.is_empty() || e.b.len() < MIN_MOVE || !keep(e, None) {
            continue;
        }
        let run = &bk[e.b.clone()];
        let found = dels.get(&hash_keys(run)).and_then(|v| {
            v.iter()
                .copied()
                .filter(|d| !used.contains(d) && ck[edits[*d].c.clone()] == *run && keep(e, Some(&edits[*d])))
                .min_by_key(|d| edits[*d].b.start.abs_diff(e.b.start))
        });
        match found {
            Some(d) => {
                used.insert(d);
                let sub = vec![Op {
                    tag: Tag::Equal,
                    a: edits[d].c.clone(),
                    b: e.b.clone(),
                }];
                moves.push(Move { del: d, ins: i, sub });
            }
            None => rest.push(i),
        }
    }
    if !near {
        return moves;
    }
    let mut budget = NEAR_MOVE_BUDGET;
    for i in rest {
        let e = &edits[i];
        if e.b.len() < MIN_NEAR_MOVE {
            continue;
        }
        let mut best: Option<(usize, usize, Range<usize>)> = None;
        for (d, de) in edits.iter().enumerate() {
            if !de.b.is_empty() || de.c.len() < MIN_MOVE || used.contains(&d) || !keep(e, Some(de)) {
                continue;
            }
            let cost = de.c.len() * e.b.len();
            if cost > budget {
                continue;
            }
            budget -= cost;
            let ops = myers::diff(&ck[de.c.clone()], &bk[e.b.clone()]);
            let mut eq = ops.iter().filter(|o| o.tag == Tag::Equal);
            let matched: usize = eq.clone().map(|o| o.a.len()).sum();
            if matched < MIN_NEAR_MOVE || matched * 10 < e.b.len() * 7 {
                continue;
            }
            let first = eq.next().map_or(0, |o| o.a.start);
            let last = ops.iter().rev().find(|o| o.tag == Tag::Equal).map_or(0, |o| o.a.end);
            if best.as_ref().is_none_or(|b| matched > b.0) {
                best = Some((matched, d, de.c.start + first..de.c.start + last));
            }
        }
        if let Some((_, d, src)) = best {
            used.insert(d);
            let sub = myers::diff(&ck[src.clone()], &bk[e.b.clone()])
                .into_iter()
                .map(|o| o.shifted(src.start, e.b.start))
                .collect();
            moves.push(Move { del: d, ins: i, sub });
        }
    }
    moves
}

fn apply(text: &str, mut tes: Vec<TextEdit>) -> String {
    tes.sort_by_key(|t| (t.start, t.end));
    let mut out = String::with_capacity(text.len() + 256);
    let mut cur = 0;
    for te in tes {
        let s = te.start.max(cur);
        let e = te.end.max(s);
        out.push_str(&text[cur..s]);
        out.push_str(&te.text);
        cur = e;
    }
    out.push_str(&text[cur..]);
    out
}

/// A token diff of `a` and `merged`, whitespace included, for the color and XML formats.
fn render_diff(a: &str, merged: &str, format: Format) -> String {
    let (ta, tm) = (lex(a), lex(merged));
    let ka: Vec<u64> = ta.iter().map(|t| hash(0, a[t.start..t.end].as_bytes())).collect();
    let km: Vec<u64> = tm.iter().map(|t| hash(0, merged[t.start..t.end].as_bytes())).collect();
    let span = |toks: &[Token], text: &'_ str, r: &Range<usize>| -> String {
        if r.is_empty() {
            String::new()
        } else {
            text[toks[r.start].start..toks[r.end - 1].end].to_owned()
        }
    };
    let (eq, add, del): ((&str, &str), (&str, &str), (&str, &str)) = match format {
        Format::Xml => (("<equal>", "</equal>"), ("<add>", "</add>"), ("<del>", "</del>")),
        _ => (("", ""), ("\x1b[4;32m", "\x1b[0m"), ("\x1b[9;31m", "\x1b[0m")),
    };
    let mut out = String::with_capacity(merged.len() + 256);
    for op in myers::diff(&ka, &km) {
        let (tag, text) = match op.tag {
            Tag::Equal => (eq, span(&ta, a, &op.a)),
            Tag::Delete => (del, span(&ta, a, &op.a)),
            Tag::Insert => (add, span(&tm, merged, &op.b)),
        };
        if !text.is_empty() {
            out.push_str(tag.0);
            out.push_str(&text);
            out.push_str(tag.1);
        }
    }
    out
}

fn has_blank_line(s: &str) -> bool {
    let parts: Vec<&str> = s.split('\n').collect();
    parts.len() >= 3 && parts[1..parts.len() - 1].iter().any(|p| p.trim().is_empty())
}

fn wordish(c: char) -> bool {
    c.is_alphanumeric() || matches!(c, '_' | '\'' | '"')
}

/// Builds the text edits of `before` (`a`). `b` is the text whose order and
/// code win; `creg` maps its canonical tokens to `a` (see `canonical_maps`),
/// `bmap` maps the tokens of `b` to `a`.
struct Ctx<'d, 't> {
    a: &'d Doc<'t>,
    b: &'d Doc<'t>,
    creg: &'d [(usize, usize)],
    bmap: &'d [usize],
    /// Comments of `a`; `b` has them too where the AST kept them, often elsewhere.
    known: HashSet<String>,
    /// The text of `b` copied into the result.
    emitted: RefCell<Vec<Range<usize>>>,
}

impl<'d, 't> Ctx<'d, 't> {
    fn new(a: &'d Doc<'t>, b: &'d Doc<'t>, creg: &'d [(usize, usize)], bmap: &'d [usize]) -> Self {
        let known = a.comments.iter().map(|c| comment_key(a, c)).collect();
        Ctx {
            a,
            b,
            creg,
            bmap,
            known,
            emitted: RefCell::new(Vec::new()),
        }
    }

    fn build_all(
        &self,
        edits: &[Edit],
        moves: &[Move],
        new_comments: bool,
        moves_only: bool,
        stats: &mut Stats,
    ) -> Vec<TextEdit> {
        let by_ins: HashMap<usize, &Move> = moves.iter().map(|m| (m.ins, m)).collect();
        let dels: HashSet<usize> = moves.iter().map(|m| m.del).collect();
        let mut tes = Vec::new();
        for (i, e) in edits.iter().enumerate() {
            if let Some(m) = by_ins.get(&i) {
                tes.push(self.insert_moved(m, edits, stats));
                continue;
            }
            if moves_only && !dels.contains(&i) {
                continue;
            }
            let (p, q) = self.a_range(&e.c);
            if p == q && e.b.is_empty() {
                continue;
            }
            tes.push(self.build_edit(p, q, e.b.start, e.b.end, stats));
        }
        if new_comments {
            tes.extend(self.new_comments());
        }
        tes
    }

    /// The token of `a` that canonical boundary `i` sits before.
    fn to_a(&self, i: usize) -> usize {
        self.creg.get(i).map_or(self.a.sig.len(), |r| r.0)
    }

    /// The tokens of `a` that canonical tokens `c` stand for.
    fn a_range(&self, c: &Range<usize>) -> (usize, usize) {
        if c.is_empty() {
            let p = self.to_a(c.start);
            return (p, p);
        }
        let (p, q) = (self.creg[c.start].0, self.creg[c.end - 1].1);
        (p, q.max(p))
    }

    fn comments_in(&self, s: usize, e: usize) -> usize {
        self.a.comments.iter().filter(|c| s <= c.start && c.end <= e).count()
    }

    fn known_comment(&self, c: &Token) -> bool {
        self.known.contains(&comment_key(self.b, c))
    }

    /// Text [s, e) of `b` without the comments that `a` has.
    fn b_text(&self, s: usize, e: usize) -> String {
        let b = self.b;
        self.emitted.borrow_mut().push(s..e);
        let mut out = String::with_capacity(e - s);
        let mut cur = s;
        let from = b.comments.partition_point(|c| c.start < s);
        for c in b.comments[from..].iter().take_while(|c| c.end <= e) {
            if !self.known_comment(c) {
                continue;
            }
            let (ls, le) = (b.line_start(c.start), b.line_end(c.end));
            let (rs, re) = if ls >= cur
                && le < e
                && b.text[ls..c.start].trim().is_empty()
                && b.text[c.end..le].trim().is_empty()
            {
                (ls, le + 1)
            } else {
                let ws = b.text[cur..c.start].len() - b.text[cur..c.start].trim_end_matches([' ', '\t']).len();
                (c.start - ws, c.end)
            };
            out.push_str(&b.text[cur..rs]);
            cur = re;
        }
        out.push_str(&b.text[cur..e]);
        out
    }

    fn b_trivia(&self, j1: usize, j2: usize) -> ((usize, usize), (usize, usize)) {
        let b = self.b;
        let pre = if j1 > 0 { b.sig[j1 - 1].end } else { 0 };
        let post = b.sig.get(j2).map_or(b.text.len(), |t| t.start);
        ((pre, b.sig[j1].start), (b.sig[j2 - 1].end, post))
    }

    /// Where a comment-only block directly above the line at `s` starts, if it
    /// belongs to token p: not when it sits between two elements without a blank line.
    fn leading_comment_start(&self, p: usize, s: usize, stats: &mut Stats) -> usize {
        let a = self.a;
        let ln = a.line_of(s);
        let mut top = ln;
        while top > 0 && !a.has_code(top - 1) && !a.line_text(top - 1).trim().is_empty() {
            top -= 1;
        }
        if top == ln {
            return s;
        }
        if top == 0 || a.line_text(top - 1).trim().is_empty() {
            return a.line_start_of(top);
        }
        if p > 0 && matches!(a.st(p - 1), ";" | ",") {
            stats.ambiguous_comments_kept += 1;
            return s;
        }
        a.line_start_of(top)
    }

    /// The text that deleting tokens [p, q) (p < q) removes, and whether the
    /// tokens around it then need a space between them.
    fn delete_span(&self, p: usize, q: usize, stats: &mut Stats) -> (usize, usize, bool) {
        let a = self.a;
        let len = a.text.len();
        let (first, last) = (a.sig[p], a.sig[q - 1]);
        let (mut s, mut e);
        if a.first_on_line(p) && a.last_on_line(q - 1) {
            s = a.line_start(first.start);
            e = (a.line_end(a.trail_end(q - 1)) + 1).min(len);
            s = self.leading_comment_start(p, s, stats);
            let above_blank = s >= 2 && a.text[a.line_start(s - 1)..s - 1].trim().is_empty();
            if above_blank && e < len && a.text[e..a.line_end(e)].trim().is_empty() {
                e = (a.line_end(e) + 1).min(len);
            }
        } else {
            s = first.start;
            e = last.end;
            let after_end = a.sig.get(q).map_or(len, |t| t.start);
            let before_start = if p > 0 { a.sig[p - 1].end } else { 0 };
            let (after, before) = (&a.text[e..after_end], &a.text[before_start..s]);
            if !before.is_empty() && before.trim().is_empty() && !before.contains('\n') {
                s = before_start;
            } else if after.trim().is_empty() && !after.contains('\n') {
                e = after_end;
            }
        }
        let glue = s > 0
            && e < len
            && a.text[..s].chars().next_back().is_some_and(wordish)
            && a.text[e..].chars().next().is_some_and(wordish);
        (s, e, glue)
    }

    /// Indentations of a line in `b` and of the same line in `a`, to indent
    /// the inserted tokens [j1, j2) at token p of `a` like their neighbours.
    fn ref_indents(&self, p: usize, j1: usize, j2: usize) -> (&'t str, &'t str) {
        let (a, b) = (self.a, self.b);
        let first = b.sig.get(j1).map_or("", |t| b.indent(t.start));
        let mut cands: Vec<(&'t str, &'t str)> = Vec::new();
        if p < a.sig.len() && j2 < b.sig.len() && a.first_on_line(p) && b.first_on_line(j2) {
            cands.push((b.indent(b.sig[j2].start), a.indent(a.sig[p].start)));
        }
        if j1 > 0 {
            let ls = b.line_start(b.sig[j1 - 1].start);
            let j0 = b.sig.partition_point(|t| t.start < ls);
            match self.bmap.get(j0).copied() {
                Some(k) if k != NONE && a.first_on_line(k) => {
                    cands.push((b.indent(b.sig[j0].start), a.indent(a.sig[k].start)));
                }
                _ if p > 0 => cands.push((b.indent(b.sig[j1 - 1].start), a.indent(a.sig[p - 1].start))),
                _ => {}
            }
        }
        cands
            .iter()
            .find(|(bi, _)| *bi == first)
            .or(cands.first())
            .copied()
            .unwrap_or(("", ""))
    }

    /// The trivia after the commas of the list around the insertion point, if
    /// the user put its elements on lines of their own.
    fn separator_style(&self, p: usize) -> Option<String> {
        let a = self.a;
        let k = if p > 0 { p - 1 } else { p };
        if k >= a.sig.len() {
            return None;
        }
        let owner = if matches!(a.st(k), "(" | "{" | "[") {
            k
        } else {
            a.encl[k]
        };
        if owner == NONE {
            return None;
        }
        let gaps: Vec<&str> = match a.commas().get(&owner) {
            Some(seps) => seps
                .iter()
                .filter(|&&s| s + 1 < a.sig.len())
                .map(|&s| &a.text[a.sig[s].end..a.sig[s + 1].start])
                .collect(),
            None if owner + 1 < a.sig.len() => vec![&a.text[a.sig[owner].end..a.sig[owner + 1].start]],
            None => Vec::new(),
        };
        if !gaps.is_empty() && gaps.iter().all(|g| g.contains('\n')) {
            gaps.last().map(|g| g.to_string())
        } else {
            None
        }
    }

    fn same_line(&self, p: usize) -> bool {
        let a = self.a;
        p > 0 && p < a.sig.len() && a.line_of(a.sig[p - 1].end) == a.line_of(a.sig[p].start)
    }

    fn line_mode(&self, p: usize, j1: usize, j2: usize) -> bool {
        let ((ps, pe), (qs, qe)) = self.b_trivia(j1, j2);
        let (bpre, bpost) = (&self.b.text[ps..pe], &self.b.text[qs..qe]);
        (bpre.contains('\n') || j1 == 0) && (bpost.contains('\n') || j2 == self.b.sig.len()) && !self.same_line(p)
    }

    /// Whole lines inserted before token p, after the line of token p-1 and its comments.
    fn place_lines(&self, p: usize, mut body: String, mut blank: bool) -> TextEdit {
        let a = self.a;
        let len = a.text.len();
        let mut off = if p > 0 {
            (a.line_end(a.trail_end(p - 1)) + 1).min(len)
        } else {
            a.line_start(a.sig[0].start)
        };
        if let Some(t) = a.sig.get(p).filter(|t| off > t.start) {
            let text = format!("{}\n{}", body.trim_start(), a.indent(t.start));
            return TextEdit {
                start: t.start,
                end: t.start,
                text,
            };
        }
        if p > 0 && off == len && !a.text.ends_with('\n') {
            body.insert(0, '\n');
        }
        if blank
            && off < len
            && a.text[off..a.line_end(off)].trim().is_empty()
            && a.sig.get(p).is_none_or(|t| a.line_end(off) < t.start)
        {
            off = (a.line_end(off) + 1).min(len);
            blank = false;
        }
        let text = format!("{}{body}\n", if blank { "\n" } else { "" });
        TextEdit {
            start: off,
            end: off,
            text,
        }
    }

    /// Text inserted inline at token p: the trivia before the inserted tokens
    /// [j1, j2) of `b`, `body` and the trivia after them.
    fn place_inline(&self, p: usize, j1: usize, j2: usize, body: String, style: Option<&str>) -> TextEdit {
        let (a, b) = (self.a, self.b);
        let ((ps, pe), (qs, qe)) = self.b_trivia(j1, j2);
        let (ref_b, ref_a) = self.ref_indents(p, j1, j2);
        let (bpre, bpost) = (self.b_text(ps, pe), self.b_text(qs, qe));
        if p < a.sig.len() && bpre.contains('\n') && bpost.is_empty() {
            let st = a.sig[p].start;
            return TextEdit {
                start: st,
                end: st,
                text: body,
            };
        }
        let off = if p > 0 { a.sig[p - 1].end } else { a.sig[p].start };
        let (gs, ge) = a.gap(p);
        let agap = &a.text[gs..ge];
        let mut end = off;
        let mut post = bpost.clone();
        if bpost.contains('\n') && agap.trim().is_empty() && !agap.contains('\n') {
            end = ge;
        } else if let (true, Some(nl)) = (agap.contains('\n'), bpost.rfind('\n')) {
            post = bpost[..nl].to_owned();
        } else if agap.contains('\n') {
            post = bpost.trim_end_matches([' ', '\t']).to_owned();
        }
        if let Some(st) = style.filter(|_| b.st(j2 - 1) == "," && !post.contains('\n')) {
            post = st.to_owned();
        }
        let text = format!(
            "{}{body}{}",
            reindent(&bpre, ref_b, ref_a),
            reindent(&post, ref_b, ref_a)
        );
        TextEdit { start: off, end, text }
    }

    /// The first line of `b` to copy for the tokens from offset `bs` on: lines
    /// right above with only new comments go with them.
    fn lines_from(&self, bs: usize, j1: usize) -> usize {
        let b = self.b;
        let floor = if j1 > 0 { b.sig[j1 - 1].end } else { 0 };
        let mut ls = b.line_start(bs);
        while ls > floor && ls > 0 {
            let line = b.line_of(ls - 1);
            let (s, e) = (b.line_start_of(line), b.line_end(b.line_start_of(line)));
            let from = b.comments.partition_point(|c| c.end <= s);
            let mut cs = b.comments[from..].iter().take_while(|c| c.start < e).peekable();
            if b.has_code(line) || s < floor || cs.peek().is_none() || cs.any(|c| self.known_comment(c)) {
                break;
            }
            ls = s;
        }
        ls
    }

    fn build_edit(&self, p: usize, q: usize, j1: usize, j2: usize, stats: &mut Stats) -> TextEdit {
        let (a, b) = (self.a, self.b);
        if j1 == j2 {
            if p >= q {
                let at = a.sig.get(p).map_or(a.text.len(), |t| t.start);
                return TextEdit {
                    start: at,
                    end: at,
                    text: String::new(),
                };
            }
            let (s, e, glue) = self.delete_span(p, q, stats);
            stats.deleted_comments += self.comments_in(s, e);
            return TextEdit {
                start: s,
                end: e,
                text: if glue { " ".into() } else { String::new() },
            };
        }
        let (bs, be) = (b.sig[j1].start, b.sig[j2 - 1].end);
        let (ref_b, ref_a) = self.ref_indents(p, j1, j2);
        if p < q {
            let text = reindent(&self.b_text(bs, be), ref_b, ref_a);
            return TextEdit {
                start: a.sig[p].start,
                end: a.sig[q - 1].end,
                text,
            };
        }
        if j1 == 0 && b.st(0) == "within" && b.st(j2 - 1) == ";" {
            let off = a.line_start(a.sig[0].start);
            return TextEdit {
                start: off,
                end: off,
                text: format!("{}\n", self.b_text(bs, be)),
            };
        }
        if self.line_mode(p, j1, j2) {
            let ls = self.lines_from(bs, j1);
            let body = reindent(&format!("\n{}", self.b_text(ls, b.line_end(be))), ref_b, ref_a);
            let ((ps, _), _) = self.b_trivia(j1, j2);
            let blank = has_blank_line(&b.text[ps..ls.max(ps)]);
            return self.place_lines(p, body[1..].to_owned(), blank);
        }
        let style = self.separator_style(p);
        let body = match &style {
            Some(st) => self.separated(j1, j2, st),
            None => reindent(&self.b_text(bs, be), ref_b, ref_a),
        };
        self.place_inline(p, j1, j2, body, style.as_deref())
    }

    /// The moved code with the text of `a`, at its place in `b`.
    fn insert_moved(&self, m: &Move, edits: &[Edit], stats: &mut Stats) -> TextEdit {
        let (a, b) = (self.a, self.b);
        let ins = &edits[m.ins];
        let (j1, j2) = (ins.b.start, ins.b.end);
        let p = self.to_a(ins.c.start);
        let first = m.sub.iter().position(|o| o.tag == Tag::Equal);
        let last = m.sub.iter().rposition(|o| o.tag == Tag::Equal);
        let (Some(fi), Some(li)) = (first, last) else {
            return self.build_edit(p, p, j1, j2, stats);
        };
        let span = m.sub[fi].a.start..m.sub[li].a.end;
        let (p1, p2) = self.a_range(&span);
        if p1 >= p2 {
            return self.build_edit(p, p, j1, j2, stats);
        }
        let lead = self.b_text(b.sig[j1].start, b.sig[m.sub[fi].b.start].start);
        let trail = self.b_text(b.sig[m.sub[li].b.end - 1].end, b.sig[j2 - 1].end);
        let line_whole = self.line_mode(p, j1, j2)
            && span == edits[m.del].c
            && lead.is_empty()
            && trail.is_empty()
            && a.first_on_line(p1)
            && a.last_on_line(p2 - 1);
        let (s, e) = if line_whole {
            let (s, e, _) = self.delete_span(p1, p2, &mut Stats::default());
            (s, e)
        } else {
            (a.sig[p1].start, a.sig[p2 - 1].end)
        };
        let tes = collapse(&m.sub[fi..=li])
            .into_iter()
            .map(|ed| {
                let (q1, q2) = self.a_range(&ed.c);
                let mut te = self.build_edit(q1, q2, ed.b.start, ed.b.end, stats);
                te.start = te.start.clamp(s, e);
                te.end = te.end.clamp(te.start, e);
                te.start -= s;
                te.end -= s;
                te
            })
            .collect();
        let moved = apply(&a.text[s..e], tes);
        let old = a.indent(a.sig[p1].start);
        if line_whole {
            let (ref_b, ref_a) = self.ref_indents(p, j1, j2);
            let target = shift(b.indent(b.sig[j1].start), ref_b, ref_a);
            let body = reindent(&format!("\n{}", moved.trim_end_matches('\n')), old, &target);
            let ((ps, pe), _) = self.b_trivia(j1, j2);
            return self.place_lines(p, body[1..].to_owned(), has_blank_line(&b.text[ps..pe]));
        }
        let at = if p > 0 { a.sig[p - 1].end } else { a.sig[p].start };
        let body = format!("{lead}{}{trail}", reindent(&moved, old, a.indent(at)));
        let style = self.separator_style(p);
        self.place_inline(p, j1, j2, body, style.as_deref())
    }

    /// Tokens [j1, j2) of `b` with `style` after each top-level comma.
    fn separated(&self, j1: usize, j2: usize, style: &str) -> String {
        let b = self.b;
        let mut out = String::new();
        let mut last = b.sig[j1].start;
        let mut depth = 0i32;
        for k in j1..j2 - 1 {
            match b.st(k) {
                "(" | "{" | "[" => depth += 1,
                ")" | "}" | "]" => depth -= 1,
                "," if depth == 0 => {
                    let (e, next) = (b.sig[k].end, b.sig[k + 1].start);
                    let gap = &b.text[e..next];
                    if gap.trim().is_empty() && !gap.contains('\n') {
                        out.push_str(&self.b_text(last, e));
                        out.push_str(style);
                        last = next;
                    }
                }
                _ => {}
            }
        }
        out.push_str(&self.b_text(last, b.sig[j2 - 1].end));
        out
    }

    /// Comments of `b` that `a` does not have and that no inserted text
    /// carries; each goes next to the token it is next to in `b`.
    fn new_comments(&self) -> Vec<TextEdit> {
        let (a, b) = (self.a, self.b);
        let mut count: HashMap<String, usize> = HashMap::new();
        for c in &a.comments {
            *count.entry(comment_key(a, c)).or_default() += 1;
        }
        let emitted = self.emitted.borrow();
        let mut out = Vec::new();
        for c in &b.comments {
            match count.get_mut(&comment_key(b, c)) {
                Some(n) if *n > 0 => {
                    *n -= 1;
                    continue;
                }
                _ => {}
            }
            if emitted.iter().any(|r| r.start <= c.start && c.end <= r.end) {
                continue;
            }
            let j = b.sig.partition_point(|t| t.start < c.end);
            let own_line = b.text[b.line_start(c.start)..c.start].trim().is_empty();
            let next = self.bmap.get(j).copied().filter(|&k| k != NONE);
            let prev = j.checked_sub(1).map(|i| self.bmap[i]).filter(|&k| k != NONE);
            let text = b.s(c);
            let before_line = |k: usize| {
                let off = a.line_start(a.sig[k].start);
                TextEdit {
                    start: off,
                    end: off,
                    text: format!("{}{text}\n", a.indent(a.sig[k].start)),
                }
            };
            let after_line = |k: usize| {
                let off = (a.line_end(a.trail_end(k)) + 1).min(a.text.len());
                let nl = if off == a.text.len() && !a.text.ends_with('\n') {
                    "\n"
                } else {
                    ""
                };
                TextEdit {
                    start: off,
                    end: off,
                    text: format!("{nl}{}{text}\n", a.indent(a.sig[k].start)),
                }
            };
            match (own_line, next, prev) {
                (true, Some(k), _) => out.push(before_line(k)),
                (false, _, Some(k)) if a.last_on_line(k) && a.trail_end(k) == a.sig[k].end => {
                    let off = a.line_end(a.sig[k].end);
                    out.push(TextEdit {
                        start: off,
                        end: off,
                        text: format!(" {text}"),
                    });
                }
                (_, _, Some(k)) => out.push(after_line(k)),
                (false, Some(k), None) => out.push(before_line(k)),
                _ => {}
            }
        }
        out
    }
}

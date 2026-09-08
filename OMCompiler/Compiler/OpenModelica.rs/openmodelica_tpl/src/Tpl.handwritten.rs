// mmtorust-replaces: Text emptyTxt isEmpty writeStr writeTok writeText softNewLine
// mmtorust-replaces: newLine pushBlock popBlock pushIter popIter nextIter getIteri_i0
// mmtorust-replaces: textStringBuf strTokText textStrTok stringText strTokString
// mmtorust-replaces: redirectToFile closeFile
// mmtorust-drops: writeChars writeLineOrStr takeLineOrString isAtStartOfLine
// mmtorust-drops: isAtStartOfLineTok tokensString tokensFile tokString tokFileText
// mmtorust-drops: tokFile stringListString stringListFile blockString
// mmtorust-drops: iterSeparatorString iterSeparatorAlignWrapString iterAlignWrapString
// mmtorust-drops: tryWrapString blockFile iterSeparatorFile iterSeparatorAlignWrapFile
// mmtorust-drops: iterAlignWrapFile tryWrapFile getTextOpaqueFile stringFile
// mmtorust-drops: newlineFile textFileTell handleTok
//
// The text engine of Tpl.mo. A text is a (buffer, length) view of an
// append-only token vector: appending to the handle that owns the tip pushes
// in place, appending to any other handle copies its prefix first, so clones
// are O(1) and the persistent semantics of Tpl.mo's cons list hold.

use std::sync::{Arc, LazyLock, Mutex};
use metamodelica::gc::{MMTrace, MMVisitor};
use super::*;
use metamodelica::List;

#[derive(Clone)]
enum Tok {
    NewLine,
    Str(ArcStr),
    Line(ArcStr),
    Block(Toks, Arc<BlockType>),
    /// ST_STRING_LIST or ST_BLOCK built by generated code.
    Mm(Arc<StringToken>),
}

impl Tok {
    fn from_mm(tok: &Arc<StringToken>) -> Tok {
        match &**tok {
            StringToken::ST_NEW_LINE => Tok::NewLine,
            StringToken::ST_STRING { value } => Tok::Str(value.clone()),
            StringToken::ST_LINE { line } => Tok::Line(line.clone()),
            _ => Tok::Mm(tok.clone()),
        }
    }

    fn to_mm(&self) -> Arc<StringToken> {
        match self {
            Tok::NewLine => interned_ST_NEW_LINE(),
            Tok::Str(s) => Arc::new(StringToken::ST_STRING { value: s.clone() }),
            Tok::Line(s) => Arc::new(StringToken::ST_LINE { line: s.clone() }),
            Tok::Block(toks, bt) => Arc::new(StringToken::ST_BLOCK { tokens: toks.to_mm_list(), blockType: bt.clone() }),
            Tok::Mm(t) => t.clone(),
        }
    }

    fn at_start_of_line(&self) -> bool {
        match self {
            Tok::NewLine | Tok::Line(_) => true,
            Tok::Str(_) => false,
            Tok::Block(toks, _) => toks.last().is_some_and(|t| t.at_start_of_line()),
            Tok::Mm(t) => mm_at_start_of_line(t),
        }
    }
}

fn mm_at_start_of_line(tok: &Arc<StringToken>) -> bool {
    match &**tok {
        StringToken::ST_NEW_LINE | StringToken::ST_LINE { .. } => true,
        StringToken::ST_STRING_LIST { lastHasNewLine, .. } => *lastHasNewLine,
        // the list is reversed: its head is the last token
        StringToken::ST_BLOCK { tokens, .. } => match &**tokens {
            ListNode::Cons { head, .. } => mm_at_start_of_line(head),
            ListNode::Nil => false,
        },
        StringToken::ST_STRING { .. } => false,
    }
}

impl MMTrace for Tok {
    fn mm_accept(&self, v: &mut dyn MMVisitor) -> std::result::Result<(), ()> {
        match self {
            Tok::NewLine | Tok::Str(_) | Tok::Line(_) => Ok(()),
            Tok::Block(toks, bt) => {
                toks.mm_accept(v)?;
                bt.mm_accept(v)
            }
            Tok::Mm(t) => t.mm_accept(v),
        }
    }
}

type Buf = Mutex<Vec<Tok>>;

/// The tokens of a text in output order: a prefix view of a shared buffer.
#[derive(Clone, Default)]
struct Toks {
    buf: Option<Arc<Buf>>,
    len: usize,
}

impl Toks {
    fn is_empty(&self) -> bool {
        self.len == 0
    }

    fn get(&self, i: usize) -> Tok {
        self.buf.as_ref().unwrap().lock().unwrap()[i].clone()
    }

    fn last(&self) -> Option<Tok> {
        if self.len == 0 { None } else { Some(self.get(self.len - 1)) }
    }

    fn push(&mut self, tok: Tok) {
        if let Some(buf) = &self.buf {
            let mut v = buf.lock().unwrap();
            if v.len() == self.len {
                v.push(tok);
            } else {
                let mut copy = Vec::with_capacity(self.len + 8);
                copy.extend_from_slice(&v[..self.len]);
                copy.push(tok);
                drop(v);
                self.buf = Some(Arc::new(Mutex::new(copy)));
            }
        } else {
            let mut v = Vec::with_capacity(8);
            v.push(tok);
            self.buf = Some(Arc::new(Mutex::new(v)));
        }
        self.len += 1;
    }

    fn same_buf(&self, other: &Toks) -> bool {
        matches!((&self.buf, &other.buf), (Some(a), Some(b)) if Arc::ptr_eq(a, b))
    }

    fn snapshot(&self) -> Toks {
        if self.len == 0 {
            return Toks::default();
        }
        let v = self.buf.as_ref().unwrap().lock().unwrap()[..self.len].to_vec();
        Toks { buf: Some(Arc::new(Mutex::new(v))), len: self.len }
    }

    /// `Tpl.Tokens` keeps the tokens reversed.
    fn to_mm_list(&self) -> Tokens {
        let mut lst = nil();
        for i in 0..self.len {
            lst = cons(self.get(i).to_mm(), lst);
        }
        lst
    }
}

impl MMTrace for Toks {
    fn mm_accept(&self, v: &mut dyn MMVisitor) -> std::result::Result<(), ()> {
        let Some(buf) = &self.buf else { return Ok(()) };
        if !v.visit_shared(Arc::as_ptr(buf) as *const (), Arc::strong_count(buf), "Tpl::Toks") {
            return Ok(());
        }
        let r = match buf.try_lock() {
            Ok(g) => g.iter().try_for_each(|t| t.mm_accept(v)),
            Err(_) => Err(()),
        };
        v.leave_shared();
        r
    }
}

#[derive(Clone, Default)]
pub struct MemText {
    toks: Toks,
    /// Open blocks, innermost first: the tokens written before the block was
    /// pushed, and the block type.
    stack: List<(Toks, Arc<BlockType>)>,
}

struct FileBlock {
    bt: Arc<BlockType>,
    nchars: i32,
    aind: i32,
    isstart: bool,
    /// Bytes written when the block was pushed; tells whether it is still empty.
    tell: i64,
    /// Separator to write before the next token of an iteration.
    septok: Option<Arc<StringToken>>,
}

struct FileState {
    nchars: i32,
    aind: i32,
    isstart: bool,
    written: i64,
    /// Open blocks, innermost last.
    blocks: Vec<FileBlock>,
}

pub struct FileText {
    file: File::File,
    state: Mutex<FileState>,
}

#[derive(Clone)]
pub enum Text {
    Mem(MemText),
    File(Arc<FileText>),
}

impl Default for Text {
    fn default() -> Self {
        Text::Mem(MemText::default())
    }
}

impl std::fmt::Debug for Text {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Text::Mem(m) => write!(f, "MEM_TEXT({} tokens, {} open blocks)", m.toks.len, listLength(m.stack.clone())),
            Text::File(t) => write!(f, "FILE_TEXT({:?})", t.file),
        }
    }
}

impl MMTrace for Text {
    fn mm_accept(&self, v: &mut dyn MMVisitor) -> std::result::Result<(), ()> {
        match self {
            Text::Mem(m) => {
                m.toks.mm_accept(v)?;
                m.stack.mm_accept(v)
            }
            Text::File(t) => {
                if !v.visit_shared(Arc::as_ptr(t) as *const (), Arc::strong_count(t), "Tpl::FileText") {
                    return Ok(());
                }
                let r = match t.state.try_lock() {
                    Ok(g) => g.blocks.iter().try_for_each(|b| {
                        b.bt.mm_accept(v)?;
                        b.septok.mm_accept(v)
                    }),
                    Err(_) => Err(()),
                };
                v.leave_shared();
                r
            }
        }
    }
}

pub static emptyTxt: LazyLock<Text> = LazyLock::new(Text::default);

fn mem(toks: Toks) -> Text {
    Text::Mem(MemText { toks, stack: nil() })
}

fn trace_fail(msg: &'static str) -> &'static str {
    if Flags::isSet(Flags::FAILTRACE.clone()).unwrap_or(false) {
        let _ = Debug::trace(ArcStr::from(msg));
    }
    "fail"
}

pub fn isEmpty(txt: Text) -> bool {
    match &txt {
        Text::Mem(m) => m.toks.is_empty(),
        Text::File(_) => false,
    }
}

pub fn writeStr(mut inText: Text, inStr: ArcStr) -> Result<Text> {
    if inStr.is_empty() {
        return Ok(inText);
    }
    if !inStr.as_bytes().contains(&b'\n') {
        match &mut inText {
            Text::Mem(m) => m.toks.push(Tok::Str(inStr)),
            Text::File(f) => stringFile(&f.file, &mut f.state.lock().unwrap(), &inStr, false)?,
        }
        return Ok(inText);
    }
    writeChars(inText, &inStr)
}

/// A string with new-lines becomes lines (`ST_LINE`, "\r\n" normalised to
/// "\n") and bare new-lines; a trailing segment without new-line stays a
/// string.
fn writeChars(mut inText: Text, s: &str) -> Result<Text> {
    let mut rest = s;
    while !rest.is_empty() {
        if let Some(r) = rest.strip_prefix('\n') {
            newLine_inplace(&mut inText)?;
            rest = r;
        } else if let Some(r) = rest.strip_prefix("\r\n") {
            newLine_inplace(&mut inText)?;
            rest = r;
        } else {
            match rest.find('\n') {
                None => {
                    writeLineOrStr(&mut inText, ArcStr::from(rest), false)?;
                    rest = "";
                }
                Some(p) => {
                    let seg_end = if rest.as_bytes()[p - 1] == b'\r' { p - 1 } else { p };
                    let mut line = String::with_capacity(seg_end + 1);
                    line.push_str(&rest[..seg_end]);
                    line.push('\n');
                    writeLineOrStr(&mut inText, ArcStr::from(line), true)?;
                    rest = &rest[p + 1..];
                }
            }
        }
    }
    Ok(inText)
}

fn writeLineOrStr(txt: &mut Text, s: ArcStr, is_line: bool) -> Result<()> {
    if s.is_empty() {
        return Ok(());
    }
    match txt {
        Text::Mem(m) => m.toks.push(if is_line { Tok::Line(s) } else { Tok::Str(s) }),
        Text::File(f) => stringFile(&f.file, &mut f.state.lock().unwrap(), &s, is_line)?,
    }
    Ok(())
}

pub fn writeTok(mut inText: Text, inToken: Arc<StringToken>) -> Result<Text> {
    match &*inToken {
        StringToken::ST_BLOCK { tokens, .. } if tokens.is_empty() => return Ok(inText),
        StringToken::ST_STRING { value } if value.is_empty() => return Ok(inText),
        _ => {}
    }
    match &mut inText {
        Text::Mem(m) => m.toks.push(Tok::from_mm(&inToken)),
        Text::File(f) => {
            let st = &mut *f.state.lock().unwrap();
            tokFileText(&f.file, st, &Tok::from_mm(&inToken), true)?;
        }
    }
    Ok(inText)
}

pub fn writeText(mut inText: Text, inTextToWrite: Text) -> Result<Text> {
    let Text::Mem(other) = inTextToWrite else {
        return Err(trace_fail("-!!!Tpl.writeText failed - incomplete text was passed to be written\n"));
    };
    if other.toks.is_empty() {
        return Ok(inText);
    }
    if !other.stack.is_empty() {
        return Err(trace_fail("-!!!Tpl.writeText failed - incomplete text was passed to be written\n"));
    }
    match &mut inText {
        Text::Mem(m) => {
            // Embedding a text into its own buffer would make the buffer refer to itself.
            let toks = if m.toks.same_buf(&other.toks) { other.toks.snapshot() } else { other.toks };
            m.toks.push(Tok::Block(toks, interned_BT_TEXT()));
        }
        Text::File(f) => {
            let st = &mut *f.state.lock().unwrap();
            for i in 0..other.toks.len {
                tokFileText(&f.file, st, &other.toks.get(i), true)?;
            }
        }
    }
    Ok(inText)
}

pub fn softNewLine(mut inText: Text) -> Result<Text> {
    match &mut inText {
        Text::Mem(m) => {
            if let Some(last) = m.toks.last() && !last.at_start_of_line() {
                m.toks.push(Tok::NewLine);
            }
        }
        Text::File(f) => {
            let st = &mut *f.state.lock().unwrap();
            if !st.isstart {
                newlineFile(&f.file, st)?;
            }
        }
    }
    Ok(inText)
}

pub fn newLine(mut inText: Text) -> Result<Text> {
    newLine_inplace(&mut inText)?;
    Ok(inText)
}

fn newLine_inplace(txt: &mut Text) -> Result<()> {
    match txt {
        Text::Mem(m) => m.toks.push(Tok::NewLine),
        Text::File(f) => newlineFile(&f.file, &mut f.state.lock().unwrap())?,
    }
    Ok(())
}

pub fn pushBlock(mut txt: Text, inBlockType: Arc<BlockType>) -> Result<Text> {
    match &mut txt {
        Text::Mem(m) => {
            let toks = std::mem::take(&mut m.toks);
            m.stack = cons((toks, inBlockType), std::mem::take(&mut m.stack));
        }
        Text::File(f) => pushBlockFile(&mut f.state.lock().unwrap(), inBlockType),
    }
    Ok(txt)
}

fn pushBlockFile(st: &mut FileState, bt: Arc<BlockType>) {
    let (nchars, aind, isstart) = (st.nchars, st.aind, st.isstart);
    st.blocks.push(FileBlock { bt: bt.clone(), nchars, aind, isstart, tell: st.written, septok: None });
    match &*bt {
        BlockType::BT_INDENT { width } => {
            st.nchars = nchars + width;
            st.aind = aind + width;
        }
        BlockType::BT_ABS_INDENT { width } => {
            if isstart {
                st.nchars = 0;
            }
            st.aind = *width;
        }
        BlockType::BT_REL_INDENT { offset } => st.aind = aind + offset,
        BlockType::BT_ANCHOR { offset } => st.aind = nchars + offset,
        _ => {}
    }
}

pub fn popBlock(mut txt: Text) -> Result<Text> {
    match &mut txt {
        Text::Mem(m) => {
            let (mut outer, bt) = match &*m.stack {
                ListNode::Cons { head, .. } => head.clone(),
                ListNode::Nil => return Err(trace_fail("-!!!Tpl.popBlock failed - probably pushBlock and popBlock are not well balanced !\n")),
            };
            let inner = std::mem::take(&mut m.toks);
            if !inner.is_empty() {
                outer.push(Tok::Block(inner, bt));
            }
            m.toks = outer;
            m.stack = listRest(std::mem::take(&mut m.stack))?;
        }
        Text::File(f) => {
            let st = &mut *f.state.lock().unwrap();
            let Some(blk) = st.blocks.pop() else {
                return Err(trace_fail("-!!!Tpl.popBlock failed - probably pushBlock and popBlock are not well balanced !\n"));
            };
            match &*blk.bt {
                BlockType::BT_INDENT { .. } => {
                    if st.isstart {
                        st.nchars = blk.nchars;
                    }
                    st.aind = blk.aind;
                }
                BlockType::BT_ABS_INDENT { .. } | BlockType::BT_REL_INDENT { .. } | BlockType::BT_ANCHOR { .. } => {
                    if st.isstart && st.written == blk.tell {
                        st.nchars = blk.nchars;
                    } else if st.isstart {
                        st.nchars = blk.aind;
                    }
                    st.aind = blk.aind;
                }
                _ => {}
            }
        }
    }
    Ok(txt)
}

pub fn pushIter(mut txt: Text, inIterOptions: Arc<IterOptions>) -> Result<Text> {
    let i0 = inIterOptions.startIndex0;
    match &mut txt {
        Text::Mem(m) => {
            let toks = std::mem::take(&mut m.toks);
            let iter = Arc::new(BlockType::BT_ITER { options: inIterOptions, index0: Mutable::create(i0) });
            let stack = std::mem::take(&mut m.stack);
            m.stack = cons((Toks::default(), iter), cons((toks, interned_BT_TEXT()), stack));
        }
        Text::File(f) => {
            if inIterOptions.alignNum != 0 || inIterOptions.wrapWidth != 0 {
                Error::addInternalError(literal!("Tpl.mo FILE_TEXT does not support aligning or wrapping elements"), metamodelica::sourceInfo!("Template/Tpl.mo"))?;
                return Err("fail");
            }
            let iter = Arc::new(BlockType::BT_ITER { options: inIterOptions, index0: Mutable::create(i0) });
            pushBlockFile(&mut f.state.lock().unwrap(), iter);
        }
    }
    Ok(txt)
}

pub fn popIter(mut txt: Text) -> Result<Text> {
    const MSG: &str = "-!!!Tpl.popIter failed - probably pushIter and popIter are not well balanced or something was written between the last nextIter and popIter ?\n";
    match &mut txt {
        Text::Mem(m) => {
            if !m.toks.is_empty() {
                return Err(trace_fail(MSG));
            }
            let (items, bt, mut outer, rest) = match &*m.stack {
                ListNode::Cons { head: (items, bt), tail } => match &**tail {
                    ListNode::Cons { head: (outer, _), tail: rest } => (items.clone(), bt.clone(), outer.clone(), rest.clone()),
                    ListNode::Nil => return Err(trace_fail(MSG)),
                },
                ListNode::Nil => return Err(trace_fail(MSG)),
            };
            if !items.is_empty() {
                outer.push(Tok::Block(items, bt));
            }
            m.toks = outer;
            m.stack = rest;
        }
        Text::File(f) => {
            if f.state.lock().unwrap().blocks.pop().is_none() {
                return Err(trace_fail(MSG));
            }
        }
    }
    Ok(txt)
}

pub fn nextIter(mut txt: Text) -> Result<Text> {
    fn non_iteration() -> &'static str {
        let _ = Error::addInternalError(literal!("-!!!Tpl.nextIter failed - nextIter was called in a non-iteration context?"), metamodelica::sourceInfo!("Template/Tpl.mo"));
        "fail"
    }
    match &mut txt {
        Text::Mem(m) => {
            let (mut items, bt, rest) = match &*m.stack {
                ListNode::Cons { head: (items, bt), tail } if matches!(&**bt, BlockType::BT_ITER { .. }) => (items.clone(), bt.clone(), tail.clone()),
                _ => return Err(non_iteration()),
            };
            let BlockType::BT_ITER { options, index0 } = &*bt else { unreachable!() };
            let item = if m.toks.is_empty() {
                options.empty.as_ref().map(Tok::from_mm)
            } else if m.toks.len == 1 {
                Some(m.toks.get(0))
            } else {
                Some(Tok::Block(std::mem::take(&mut m.toks), interned_BT_TEXT()))
            };
            if let Some(item) = item {
                Mutable::update(index0.clone(), Mutable::access(index0.clone()) + 1);
                items.push(item);
                m.toks = Toks::default();
                m.stack = cons((items, bt), rest);
            }
        }
        Text::File(f) => {
            let st = &mut *f.state.lock().unwrap();
            let Some(blk) = st.blocks.last() else { return Err(non_iteration()) };
            let (bt, blk_tell) = (blk.bt.clone(), blk.tell);
            let BlockType::BT_ITER { options, index0 } = &*bt else { return Err(non_iteration()) };
            let tellpos = st.written;
            let have_token = if blk_tell != tellpos {
                st.blocks.last_mut().unwrap().tell = tellpos;
                true
            } else {
                match &options.empty {
                    None => false,
                    Some(emptok) => {
                        Mutable::update(index0.clone(), Mutable::access(index0.clone()) + 1);
                        tokFileText(&f.file, st, &Tok::from_mm(emptok), true)?;
                        true
                    }
                }
            };
            if have_token {
                let cur = Mutable::access(index0.clone());
                st.blocks.last_mut().unwrap().septok = options.separator.clone();
                Mutable::update(index0.clone(), cur + 1);
            }
        }
    }
    Ok(txt)
}

pub fn getIteri_i0(inText: Text) -> Result<i32> {
    const MSG: &str = "-!!!Tpl.getIter_i0 failed - getIter_i0 was called in a non-iteration context ? \n";
    match &inText {
        Text::Mem(m) => match &*m.stack {
            ListNode::Cons { head: (_, bt), .. } => match &**bt {
                BlockType::BT_ITER { index0, .. } => Ok(Mutable::access(index0.clone())),
                _ => Err(trace_fail(MSG)),
            },
            ListNode::Nil => Err(trace_fail(MSG)),
        },
        Text::File(f) => {
            let st = f.state.lock().unwrap();
            match st.blocks.last().map(|b| &*b.bt) {
                Some(BlockType::BT_ITER { index0, .. }) => Ok(Mutable::access(index0.clone())),
                _ => Err(trace_fail(MSG)),
            }
        }
    }
}

// ── rendering ────────────────────────────────────────────────────────────────

trait Sink {
    fn write(&mut self, s: &str);
    fn space(&mut self, n: i32);
    fn pos(&self) -> i64;
    /// Position after a string written at the start of a line: the C runtime
    /// measures the print buffer but computes it for files, which differs for
    /// a negative indent.
    fn start_pos(&self, nchars: i32, len: i32, written: i32) -> i32;
}

struct BufSink<'a>(&'a mut String);

impl Sink for BufSink<'_> {
    fn write(&mut self, s: &str) {
        self.0.push_str(s);
    }
    fn space(&mut self, n: i32) {
        for _ in 0..n {
            self.0.push(' ');
        }
    }
    fn pos(&self) -> i64 {
        self.0.len() as i64
    }
    fn start_pos(&self, _nchars: i32, _len: i32, written: i32) -> i32 {
        written
    }
}

struct FileSink<'a> {
    file: &'a File::File,
    written: &'a mut i64,
    err: Option<&'static str>,
}

impl FileSink<'_> {
    fn check(&mut self, r: Result<()>) {
        if let Err(e) = r && self.err.is_none() {
            self.err = Some(e);
        }
    }
}

impl Sink for FileSink<'_> {
    fn write(&mut self, s: &str) {
        *self.written += s.len() as i64;
        let r = File::write_str(self.file, s);
        self.check(r);
    }
    fn space(&mut self, n: i32) {
        *self.written += n.max(0) as i64;
        let r = File::write_space(self.file, n);
        self.check(r);
    }
    fn pos(&self) -> i64 {
        *self.written
    }
    fn start_pos(&self, nchars: i32, len: i32, _written: i32) -> i32 {
        nchars + len
    }
}

/// The token source of a block: a text buffer, or a `Tpl.Tokens` list in
/// output order.
enum Items<'a> {
    Buf(&'a Toks),
    Vec(Vec<Tok>),
}

impl Items<'_> {
    fn len(&self) -> usize {
        match self {
            Items::Buf(t) => t.len,
            Items::Vec(v) => v.len(),
        }
    }
    fn get(&self, i: usize) -> Tok {
        match self {
            Items::Buf(t) => t.get(i),
            Items::Vec(v) => v[i].clone(),
        }
    }
    fn from_mm_list(toks: &Tokens) -> Items<'static> {
        let mut v: Vec<Tok> = toks.iter().map(Tok::from_mm).collect();
        v.reverse();
        Items::Vec(v)
    }
}

type Pos = (i32, bool, i32);

fn tok<S: Sink>(s: &mut S, t: &Tok, (nchars, isstart, aind): Pos) -> Pos {
    match t {
        Tok::NewLine => {
            s.write("\n");
            (aind, true, aind)
        }
        Tok::Str(str) => {
            if isstart {
                let p0 = s.pos();
                s.space(nchars);
                s.write(str);
                (s.start_pos(nchars, str.len() as i32, (s.pos() - p0) as i32), false, aind)
            } else {
                s.write(str);
                (nchars + str.len() as i32, false, aind)
            }
        }
        Tok::Line(str) => {
            if isstart {
                s.space(nchars);
            }
            s.write(str);
            (aind, true, aind)
        }
        Tok::Block(toks, bt) => block(s, bt, &Items::Buf(toks), (nchars, isstart, aind)),
        Tok::Mm(t) => match &**t {
            StringToken::ST_STRING_LIST { strList, .. } => stringList(s, strList, (nchars, isstart, aind)),
            StringToken::ST_BLOCK { tokens, blockType } => block(s, blockType, &Items::from_mm_list(tokens), (nchars, isstart, aind)),
            _ => tok(s, &Tok::from_mm(t), (nchars, isstart, aind)),
        },
    }
}

fn tokens<S: Sink>(s: &mut S, items: &Items, from: usize, mut pos: Pos) -> Pos {
    for i in from..items.len() {
        pos = tok(s, &items.get(i), pos);
    }
    pos
}

fn stringList<S: Sink>(s: &mut S, strs: &List<ArcStr>, (mut nchars, mut isstart, aind): Pos) -> Pos {
    for str in strs {
        if str.is_empty() {
            continue;
        }
        let has_nl = str.ends_with('\n');
        if isstart {
            let p0 = s.pos();
            s.space(nchars);
            s.write(str);
            let written = (s.pos() - p0) as i32;
            nchars = if has_nl { aind } else { s.start_pos(nchars, str.len() as i32, written) };
        } else {
            s.write(str);
            nchars = if has_nl { aind } else { nchars + str.len() as i32 };
        }
        isstart = has_nl;
    }
    (aind, isstart, aind)
}

fn block<S: Sink>(s: &mut S, bt: &BlockType, items: &Items, (nchars, isstart, aind): Pos) -> Pos {
    // Every indenting block pops its indent when it ends at the start of a line.
    let indented = |s: &mut S, pos: Pos| -> Pos {
        let p0 = s.pos();
        let (tsnchars, st, _) = tokens(s, items, 0, pos);
        let nc = if isstart && s.pos() == p0 { nchars } else if st { aind } else { tsnchars };
        (nc, st, aind)
    };
    match bt {
        BlockType::BT_TEXT => tokens(s, items, 0, (nchars, isstart, aind)),
        BlockType::BT_INDENT { width: w } => {
            if isstart {
                let (tsnchars, st, _) = tokens(s, items, 0, (w + nchars, true, w + aind));
                (if st { nchars } else { tsnchars }, st, aind)
            } else {
                s.space(*w);
                let (tsnchars, st, _) = tokens(s, items, 0, (w + nchars, false, w + aind));
                (if st { aind } else { tsnchars }, st, aind)
            }
        }
        BlockType::BT_ABS_INDENT { width: w } => {
            if isstart { indented(s, (0, true, *w)) } else { indented(s, (nchars, false, *w)) }
        }
        BlockType::BT_REL_INDENT { offset: w } => indented(s, (nchars, isstart, aind + w)),
        BlockType::BT_ANCHOR { offset: w } => indented(s, (nchars, isstart, nchars + w)),
        BlockType::BT_ITER { options, .. } => {
            if items.len() == 0 {
                return (nchars, isstart, aind);
            }
            let o = &**options;
            match (&o.separator, o.alignNum, o.wrapWidth) {
                (None, 0, 0) => tokens(s, items, 0, (nchars, isstart, aind)),
                (Some(sep), 0, 0) => {
                    let (mut pos, mut st, a) = tok(s, &items.get(0), (nchars, isstart, aind));
                    let mut ai = a;
                    for i in 1..items.len() {
                        (pos, st, ai) = tok(s, &Tok::from_mm(sep), (pos, st, ai));
                        (pos, st, ai) = tok(s, &items.get(i), (pos, st, ai));
                    }
                    (pos, st, a)
                }
                (Some(sep), anum, wwidth) => {
                    let (mut pos, mut st, a) = tok(s, &items.get(0), (nchars, isstart, aind));
                    let mut ai = a;
                    let mut idx = 1 + o.alignOfset;
                    for i in 1..items.len() {
                        let septok = if anum != 0 && idx > 0 && intMod(idx, anum) == 0 { &o.alignSeparator } else { sep };
                        (pos, st, ai) = tok(s, &Tok::from_mm(septok), (pos, st, ai));
                        if wwidth > 0 && pos >= wwidth {
                            (pos, st, ai) = tok(s, &Tok::from_mm(&o.wrapSeparator), (pos, st, ai));
                        }
                        (pos, st, ai) = tok(s, &items.get(i), (pos, st, ai));
                        idx += 1;
                    }
                    (pos, st, a)
                }
                (None, anum, wwidth) => {
                    let (mut pos, mut st, mut ai) = (nchars, isstart, aind);
                    let mut idx = o.alignOfset;
                    for i in 0..items.len() {
                        if anum != 0 && idx > 0 && intMod(idx, anum) == 0 {
                            (pos, st, ai) = tok(s, &Tok::from_mm(&o.alignSeparator), (pos, st, ai));
                            if wwidth > 0 && pos >= wwidth {
                                (pos, st, ai) = tok(s, &Tok::from_mm(&o.wrapSeparator), (pos, st, ai));
                            }
                        } else if wwidth > 0 && pos >= wwidth {
                            (pos, st, ai) = tok(s, &Tok::from_mm(&o.wrapSeparator), (pos, st, ai));
                        }
                        (pos, st, ai) = tok(s, &items.get(i), (pos, st, ai));
                        idx += 1;
                    }
                    (pos, st, aind)
                }
            }
        }
    }
}

pub fn textStringBuf(inText: Text) -> Result<()> {
    let Text::Mem(m) = &inText else {
        return Err(trace_fail("-!!!Tpl.textString failed.\n"));
    };
    if !m.stack.is_empty() {
        return Err(trace_fail("-!!!Tpl.textString failed - a non-comlete text was given.\n"));
    }
    Print::with_buf(|buf| {
        tokens(&mut BufSink(buf), &Items::Buf(&m.toks), 0, (0, true, 0));
    });
    Ok(())
}

pub fn strTokText(inStringToken: Arc<StringToken>) -> Text {
    let mut toks = Toks::default();
    toks.push(Tok::from_mm(&inStringToken));
    mem(toks)
}

pub fn textStrTok(inText: Text) -> Result<Arc<StringToken>> {
    match &inText {
        Text::Mem(m) if m.toks.is_empty() => Ok(Arc::new(StringToken::ST_STRING { value: literal!("") })),
        Text::Mem(m) if m.stack.is_empty() => Ok(Arc::new(StringToken::ST_BLOCK { tokens: m.toks.to_mm_list(), blockType: interned_BT_TEXT() })),
        _ => Err(trace_fail("-!!!Tpl.textStrTok failed - incomplete text was passed to be converted.\n")),
    }
}

pub fn stringText(inString: ArcStr) -> Text {
    let mut toks = Toks::default();
    toks.push(Tok::Str(inString));
    mem(toks)
}

pub fn strTokString(inStringToken: Arc<StringToken>) -> Result<ArcStr> {
    textString(strTokText(inStringToken))
}

// ── FILE_TEXT ────────────────────────────────────────────────────────────────

pub fn redirectToFile(text: Text, fileName: ArcStr) -> Result<Text> {
    let file = File::File(File::noReference())?;
    if Testsuite::isRunning()? {
        System::appendFile(Testsuite::getTempFilesFile()?, arcstr::format!("{fileName}\n"))?;
    }
    File::open(file.clone(), fileName, File::Mode::Write)?;
    // The registry reference keeps the file flushed at exit like the C runtime's refcount.
    File::getReference(file.clone());
    let out = Text::File(Arc::new(FileText {
        file,
        state: Mutex::new(FileState { nchars: 0, aind: 0, isstart: true, written: 0, blocks: Vec::new() }),
    }));
    writeText(out, text)
}

pub fn closeFile(text: Text) -> Result<Text> {
    let Text::File(f) = &text else {
        Error::addInternalError(literal!("tokFile got non-file text input"), metamodelica::sourceInfo!("Template/Tpl.mo"))?;
        return Err("fail");
    };
    let _ = File::releaseReference(f.file.clone());
    File::flush(&f.file)?;
    Ok(emptyTxt.clone())
}

/// Writes the pending iteration separator, then the token.
fn tokFileText(file: &File::File, st: &mut FileState, t: &Tok, handle: bool) -> Result<()> {
    if handle {
        handleTok(file, st)?;
    }
    let mut sink = FileSink { file, written: &mut st.written, err: None };
    let (nchars, isstart, aind) = tok(&mut sink, t, (st.nchars, st.isstart, st.aind));
    if let Some(e) = sink.err {
        return Err(e);
    }
    st.nchars = nchars;
    st.isstart = isstart;
    st.aind = aind;
    Ok(())
}

fn handleTok(file: &File::File, st: &mut FileState) -> Result<()> {
    let sep = match st.blocks.last_mut() {
        Some(blk) if matches!(&*blk.bt, BlockType::BT_ITER { .. }) => blk.septok.take(),
        _ => None,
    };
    match sep {
        Some(sep) => tokFileText(file, st, &Tok::from_mm(&sep), false),
        None => Ok(()),
    }
}

/// Like ST_STRING or ST_LINE.
fn stringFile(file: &File::File, st: &mut FileState, s: &str, line: bool) -> Result<()> {
    handleTok(file, st)?;
    let nchars = st.nchars;
    if !line {
        if st.isstart {
            st.written += nchars.max(0) as i64;
            File::write_space(file, nchars)?;
            st.isstart = false;
        }
        st.nchars = nchars + s.len() as i32;
    } else {
        if st.isstart {
            st.written += nchars.max(0) as i64;
            File::write_space(file, nchars)?;
        } else {
            st.isstart = true;
        }
        st.nchars = st.aind;
    }
    st.written += s.len() as i64;
    File::write_str(file, s)
}

fn newlineFile(file: &File::File, st: &mut FileState) -> Result<()> {
    st.written += 1;
    File::write_str(file, "\n")?;
    st.nchars = st.aind;
    st.isstart = true;
    Ok(())
}

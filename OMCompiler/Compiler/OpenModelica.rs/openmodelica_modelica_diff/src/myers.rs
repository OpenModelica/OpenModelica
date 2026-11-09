//! Myers' O(ND) difference algorithm in linear space (the middle-snake
//! bisection of E. Myers, "An O(ND) Difference Algorithm and Its Variations",
//! 1986, as in diff-match-patch).

use std::ops::Range;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum Tag {
    Equal,
    Delete,
    Insert,
}

/// A run of the edit script. Delete has an empty `b`, Insert an empty `a`,
/// each positioned where the run belongs.
#[derive(Clone, PartialEq, Eq, Debug)]
pub struct Op {
    pub tag: Tag,
    pub a: Range<usize>,
    pub b: Range<usize>,
}

impl Op {
    pub fn shifted(&self, da: usize, db: usize) -> Op {
        Op {
            tag: self.tag,
            a: self.a.start + da..self.a.end + da,
            b: self.b.start + db..self.b.end + db,
        }
    }
}

/// A shortest edit script from `a` to `b`.
pub fn diff(a: &[u64], b: &[u64]) -> Vec<Op> {
    let mut ops = Vec::new();
    conquer(a, 0..a.len(), b, 0..b.len(), &mut ops);
    merge_adjacent(ops)
}

fn conquer(a: &[u64], mut ar: Range<usize>, b: &[u64], mut br: Range<usize>, ops: &mut Vec<Op>) {
    let pre = a[ar.clone()]
        .iter()
        .zip(&b[br.clone()])
        .take_while(|(x, y)| x == y)
        .count();
    if pre > 0 {
        ops.push(Op {
            tag: Tag::Equal,
            a: ar.start..ar.start + pre,
            b: br.start..br.start + pre,
        });
        ar.start += pre;
        br.start += pre;
    }
    let suf = a[ar.clone()]
        .iter()
        .rev()
        .zip(b[br.clone()].iter().rev())
        .take_while(|(x, y)| x == y)
        .count();
    let tail = Op {
        tag: Tag::Equal,
        a: ar.end - suf..ar.end,
        b: br.end - suf..br.end,
    };
    ar.end -= suf;
    br.end -= suf;

    if ar.is_empty() && br.is_empty() {
    } else if br.is_empty() {
        ops.push(Op {
            tag: Tag::Delete,
            a: ar.clone(),
            b: br.start..br.start,
        });
    } else if ar.is_empty() {
        ops.push(Op {
            tag: Tag::Insert,
            a: ar.start..ar.start,
            b: br.clone(),
        });
    } else if let Some((x, y)) = bisect(&a[ar.clone()], &b[br.clone()]) {
        conquer(a, ar.start..ar.start + x, b, br.start..br.start + y, ops);
        conquer(a, ar.start + x..ar.end, b, br.start + y..br.end, ops);
    } else {
        ops.push(Op {
            tag: Tag::Delete,
            a: ar.clone(),
            b: br.start..br.start,
        });
        ops.push(Op {
            tag: Tag::Insert,
            a: ar.end..ar.end,
            b: br.clone(),
        });
    }
    if suf > 0 {
        ops.push(tail);
    }
}

/// The point where a shortest path through the edit graph crosses its middle,
/// or None when `a` and `b` have nothing in common.
fn bisect(a: &[u64], b: &[u64]) -> Option<(usize, usize)> {
    let n = a.len() as isize;
    let m = b.len() as isize;
    let max_d = (n + m + 1) / 2;
    let v_off = max_d;
    let v_len = (2 * max_d + 2) as usize;
    let mut v1 = vec![-1isize; v_len];
    let mut v2 = vec![-1isize; v_len];
    v1[(v_off + 1) as usize] = 0;
    v2[(v_off + 1) as usize] = 0;
    let delta = n - m;
    let front = delta % 2 != 0;
    let (mut k1start, mut k1end, mut k2start, mut k2end) = (0, 0, 0, 0);
    for d in 0..max_d {
        let mut k1 = -d + k1start;
        while k1 <= d - k1end {
            let k1o = (v_off + k1) as usize;
            let mut x1 = if k1 == -d || (k1 != d && v1[k1o - 1] < v1[k1o + 1]) {
                v1[k1o + 1]
            } else {
                v1[k1o - 1] + 1
            };
            let mut y1 = x1 - k1;
            while x1 < n && y1 < m && a[x1 as usize] == b[y1 as usize] {
                x1 += 1;
                y1 += 1;
            }
            v1[k1o] = x1;
            if x1 > n {
                k1end += 2;
            } else if y1 > m {
                k1start += 2;
            } else if front {
                let k2o = v_off + delta - k1;
                if k2o >= 0 && (k2o as usize) < v_len && v2[k2o as usize] != -1 && x1 >= n - v2[k2o as usize] {
                    return Some((x1 as usize, y1 as usize));
                }
            }
            k1 += 2;
        }
        let mut k2 = -d + k2start;
        while k2 <= d - k2end {
            let k2o = (v_off + k2) as usize;
            let mut x2 = if k2 == -d || (k2 != d && v2[k2o - 1] < v2[k2o + 1]) {
                v2[k2o + 1]
            } else {
                v2[k2o - 1] + 1
            };
            let mut y2 = x2 - k2;
            while x2 < n && y2 < m && a[(n - x2 - 1) as usize] == b[(m - y2 - 1) as usize] {
                x2 += 1;
                y2 += 1;
            }
            v2[k2o] = x2;
            if x2 > n {
                k2end += 2;
            } else if y2 > m {
                k2start += 2;
            } else if !front {
                let k1o = v_off + delta - k2;
                if k1o >= 0 && (k1o as usize) < v_len && v1[k1o as usize] != -1 {
                    let x1 = v1[k1o as usize];
                    let y1 = v_off + x1 - k1o;
                    if x1 >= n - x2 {
                        return Some((x1 as usize, y1 as usize));
                    }
                }
            }
            k2 += 2;
        }
    }
    None
}

/// Joins neighbouring runs of the same kind and drops empty runs.
pub fn merge_adjacent(ops: Vec<Op>) -> Vec<Op> {
    let mut out: Vec<Op> = Vec::with_capacity(ops.len());
    for op in ops {
        if op.a.is_empty() && op.b.is_empty() {
            continue;
        }
        match out.last_mut() {
            Some(last) if last.tag == op.tag && last.a.end == op.a.start && last.b.end == op.b.start => {
                last.a.end = op.a.end;
                last.b.end = op.b.end;
            }
            _ => out.push(op),
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn lcs(a: &[u64], b: &[u64]) -> usize {
        let mut t = vec![vec![0usize; b.len() + 1]; a.len() + 1];
        for i in (0..a.len()).rev() {
            for j in (0..b.len()).rev() {
                t[i][j] = if a[i] == b[j] {
                    t[i + 1][j + 1] + 1
                } else {
                    t[i + 1][j].max(t[i][j + 1])
                };
            }
        }
        t[0][0]
    }

    fn check(a: &[u64], b: &[u64]) {
        let ops = diff(a, b);
        let (mut i, mut j, mut equal) = (0, 0, 0);
        for op in &ops {
            assert_eq!(op.a.start, i);
            assert_eq!(op.b.start, j);
            match op.tag {
                Tag::Equal => {
                    assert_eq!(a[op.a.clone()], b[op.b.clone()]);
                    equal += op.a.len();
                }
                Tag::Delete => assert!(op.b.is_empty()),
                Tag::Insert => assert!(op.a.is_empty()),
            }
            i = op.a.end;
            j = op.b.end;
        }
        assert_eq!((i, j), (a.len(), b.len()));
        assert_eq!(equal, lcs(a, b), "{a:?} {b:?}");
    }

    #[test]
    fn shortest_scripts() {
        let mut seed = 0x2545f4914f6cdd1du64;
        let mut rnd = |m: u64| {
            seed ^= seed << 13;
            seed ^= seed >> 7;
            seed ^= seed << 17;
            seed % m
        };
        for _ in 0..3000 {
            let alpha = 1 + rnd(4);
            let a: Vec<u64> = (0..rnd(14)).map(|_| rnd(alpha)).collect();
            let b: Vec<u64> = (0..rnd(14)).map(|_| rnd(alpha)).collect();
            check(&a, &b);
        }
        check(&[], &[]);
        check(&[1, 2, 3], &[]);
        check(&[], &[1, 2, 3]);
        check(&[1, 2, 3], &[4, 5]);
    }
}

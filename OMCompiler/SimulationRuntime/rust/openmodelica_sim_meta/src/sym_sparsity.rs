//! A Jacobian sparsity pattern whose sizes are only known at runtime: the new
//! backend's resizable sparsity rows (for-loop iterators, affine subscripts) with
//! [`Sz`] sizes, expanded once the sizes are resolved. The expansion follows
//! C's `initialResizableAnalyticJacobian` (`resizableColCountRegular` pairs a
//! regular whole-array dependency element-wise, everything else is the cross
//! product).

use alloc::vec;
use alloc::vec::Vec;

use crate::Sz;

/// An array variable of the row or the column space, starting at `base`.
#[derive(Clone, Debug, PartialEq)]
pub struct SymVar {
    pub base: Sz,
    pub dims: Vec<Sz>,
}

/// `c + Σ k[i] * iterator_i`.
#[derive(Clone, Debug, PartialEq)]
pub struct Affine {
    pub c: Sz,
    pub k: Vec<i64>,
}

#[derive(Clone, Debug, PartialEq)]
pub enum SymSub {
    All,
    Index(Affine),
    Slice { start: Affine, step: i64, stop: Affine },
}

#[derive(Clone, Debug, PartialEq)]
pub struct SymRef {
    pub var: u32,
    pub subs: Vec<SymSub>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct SymIter {
    pub start: Sz,
    pub step: i64,
    pub size: Sz,
}

#[derive(Clone, Debug, PartialEq)]
pub struct SymRow {
    pub iters: Vec<SymIter>,
    pub solved: Vec<SymRef>,
    /// The seed and whether it may pair element-wise (not repeated, a plain
    /// dependency).
    pub deps: Vec<(SymRef, bool)>,
}

#[derive(Clone, Debug, PartialEq, Default)]
pub struct SymPattern {
    pub n: Sz,
    pub rows_vars: Vec<SymVar>,
    pub cols_vars: Vec<SymVar>,
    pub rows: Vec<SymRow>,
}

enum Pos {
    All,
    Some(Vec<usize>),
}

struct Bound {
    base: usize,
    dims: Vec<(usize, Pos)>,
}

impl Bound {
    fn whole_1d(&self) -> bool {
        self.dims.len() == 1 && matches!(self.dims[0].1, Pos::All)
    }

    fn offsets(&self) -> Vec<usize> {
        let mut offs = vec![0usize];
        for (dim, p) in &self.dims {
            let mut next = Vec::new();
            for o in &offs {
                match p {
                    Pos::All => next.extend((0..*dim).map(|q| o * dim + q)),
                    Pos::Some(ps) => next.extend(ps.iter().map(|q| o * dim + q)),
                }
            }
            offs = next;
        }
        offs.into_iter().map(|o| self.base + o).collect()
    }
}

impl SymPattern {
    /// Rows per column, `None` when the expansion leaves the `n × n` square.
    pub fn expand(&self, params: &[i64]) -> Option<Vec<Vec<u32>>> {
        let ev = |s: &Sz| s.eval(params);
        let n = usize::try_from(ev(&self.n)).ok()?;
        let vars = |vs: &[SymVar]| -> Option<Vec<(usize, Vec<usize>)>> {
            vs.iter()
                .map(|v| {
                    let dims = v.dims.iter().map(|d| usize::try_from(ev(d)).ok()).collect::<Option<Vec<_>>>()?;
                    Some((usize::try_from(ev(&v.base)).ok()?, dims))
                })
                .collect()
        };
        let (row_vars, col_vars) = (vars(&self.rows_vars)?, vars(&self.cols_vars)?);
        let mut cols: Vec<Vec<u32>> = vec![Vec::new(); n];
        let mut add = |r: usize, c: usize| {
            if r < n && c < n {
                cols[c].push(r as u32);
            }
        };
        for row in &self.rows {
            let iters: Vec<(i64, i64, usize)> = row
                .iters
                .iter()
                .map(|it| Some((ev(&it.start), it.step, usize::try_from(ev(&it.size)).ok()?)))
                .collect::<Option<_>>()?;
            let total: usize = iters.iter().map(|i| i.2).product();
            let mut pos = vec![0usize; iters.len()];
            let mut vals = vec![0i64; iters.len()];
            for flat in 0..total {
                for (k, (start, step, _)) in iters.iter().enumerate() {
                    vals[k] = start + step * pos[k] as i64;
                }
                let bind = |r: &SymRef, table: &[(usize, Vec<usize>)]| -> Option<Bound> {
                    let (base, dims) = table.get(r.var as usize)?;
                    let aff = |a: &Affine| a.c.eval(params) + a.k.iter().zip(&vals).map(|(k, v)| k * v).sum::<i64>();
                    let mut out = Vec::with_capacity(dims.len());
                    for (k, &dim) in dims.iter().enumerate() {
                        let p = match r.subs.get(k).unwrap_or(&SymSub::All) {
                            SymSub::All => Pos::All,
                            SymSub::Index(a) => Pos::Some(usize::try_from(aff(a) - 1).ok().filter(|&p| p < dim).into_iter().collect()),
                            SymSub::Slice { start, step, stop } => {
                                let (mut v, stop) = (aff(start), aff(stop));
                                let mut ps = Vec::new();
                                while *step != 0 && ((*step > 0 && v <= stop) || (*step < 0 && v >= stop)) {
                                    if let Ok(p) = usize::try_from(v - 1)
                                        && p < dim
                                    {
                                        ps.push(p);
                                    }
                                    v += step;
                                }
                                Pos::Some(ps)
                            }
                        };
                        out.push((dim, p));
                    }
                    Some(Bound { base: *base, dims: out })
                };
                for sc in &row.solved {
                    let sc = bind(sc, &row_vars)?;
                    // A trailing whole dimension of a looped residual is the loop itself.
                    let iter_row = !iters.is_empty() && sc.dims.last().is_some_and(|(_, p)| matches!(p, Pos::All));
                    let sc_offs = match iter_row {
                        true => vec![sc.base + flat],
                        false => sc.offsets(),
                    };
                    let whole_2d = sc.dims.len() == 2 && sc.dims.iter().all(|(_, p)| matches!(p, Pos::All));
                    let pairs_regular = sc.whole_1d() || (iter_row && !whole_2d);
                    for (seed, may_pair) in &row.deps {
                        let seed = bind(seed, &col_vars)?;
                        if *may_pair && seed.whole_1d() && pairs_regular {
                            match iters.is_empty() {
                                true => (0..sc.dims.first().map_or(0, |d| d.0)).for_each(|k| add(sc.base + k, seed.base + k)),
                                false => add(sc.base + flat, seed.base + flat),
                            }
                            continue;
                        }
                        for c in seed.offsets() {
                            for &r in &sc_offs {
                                add(r, c);
                            }
                        }
                    }
                }
                for (p, it) in pos.iter_mut().zip(&iters) {
                    *p += 1;
                    if *p < it.2 {
                        break;
                    }
                    *p = 0;
                }
            }
        }
        for c in &mut cols {
            c.sort_unstable();
            c.dedup();
        }
        Some(cols)
    }
}

/// Greedy column coloring: a color's columns share no row. The colors already
/// used in each row are a bitset, so a column costs its rows times the colors / 64.
pub fn color_columns(rows_by_col: &[Vec<u32>]) -> Vec<Vec<u32>> {
    let nrows = rows_by_col.iter().flatten().map(|&r| r as usize + 1).max().unwrap_or(0);
    let mut used: Vec<Vec<u64>> = vec![Vec::new(); nrows];
    let mut groups: Vec<Vec<u32>> = Vec::new();
    let mut forbidden: Vec<u64> = Vec::new();
    for (j, rows) in rows_by_col.iter().enumerate() {
        forbidden.clear();
        forbidden.resize(groups.len().div_ceil(64), 0);
        for &r in rows {
            for (f, u) in forbidden.iter_mut().zip(&used[r as usize]) {
                *f |= u;
            }
        }
        let chosen = forbidden
            .iter()
            .enumerate()
            .find(|(_, w)| **w != u64::MAX)
            .map(|(k, w)| k * 64 + w.trailing_ones() as usize)
            .filter(|&c| c < groups.len())
            .unwrap_or(groups.len());
        if chosen == groups.len() {
            groups.push(Vec::new());
        }
        groups[chosen].push(j as u32);
        let (word, bit) = (chosen / 64, chosen % 64);
        for &r in rows {
            let u = &mut used[r as usize];
            if u.len() <= word {
                u.resize(word + 1, 0);
            }
            u[word] |= 1 << bit;
        }
    }
    groups
}

pub(crate) fn put(o: &mut Vec<u8>, p: &Option<SymPattern>) {
    let Some(p) = p else {
        o.push(0);
        return;
    };
    o.push(1);
    let u32_ = |o: &mut Vec<u8>, v: u32| o.extend_from_slice(&v.to_le_bytes());
    let i64_ = |o: &mut Vec<u8>, v: i64| o.extend_from_slice(&v.to_le_bytes());
    let aff = |o: &mut Vec<u8>, a: &Affine| {
        a.c.encode(o);
        u32_(o, a.k.len() as u32);
        for k in &a.k {
            i64_(o, *k);
        }
    };
    let rf = |o: &mut Vec<u8>, r: &SymRef| {
        u32_(o, r.var);
        u32_(o, r.subs.len() as u32);
        for s in &r.subs {
            match s {
                SymSub::All => o.push(0),
                SymSub::Index(a) => {
                    o.push(1);
                    aff(o, a);
                }
                SymSub::Slice { start, step, stop } => {
                    o.push(2);
                    aff(o, start);
                    i64_(o, *step);
                    aff(o, stop);
                }
            }
        }
    };
    p.n.encode(o);
    for vars in [&p.rows_vars, &p.cols_vars] {
        u32_(o, vars.len() as u32);
        for v in vars {
            v.base.encode(o);
            u32_(o, v.dims.len() as u32);
            for d in &v.dims {
                d.encode(o);
            }
        }
    }
    u32_(o, p.rows.len() as u32);
    for r in &p.rows {
        u32_(o, r.iters.len() as u32);
        for it in &r.iters {
            it.start.encode(o);
            i64_(o, it.step);
            it.size.encode(o);
        }
        u32_(o, r.solved.len() as u32);
        for s in &r.solved {
            rf(o, s);
        }
        u32_(o, r.deps.len() as u32);
        for (s, pair) in &r.deps {
            rf(o, s);
            o.push(*pair as u8);
        }
    }
}

pub(crate) fn get(b: &[u8], p: &mut usize) -> Result<Option<SymPattern>, &'static str> {
    fn take<'a>(b: &'a [u8], p: &mut usize, n: usize) -> Result<&'a [u8], &'static str> {
        let s = b.get(*p..*p + n).ok_or("sim_meta: truncated sparsity")?;
        *p += n;
        Ok(s)
    }
    fn u8_(b: &[u8], p: &mut usize) -> Result<u8, &'static str> {
        Ok(take(b, p, 1)?[0])
    }
    fn u32_(b: &[u8], p: &mut usize) -> Result<u32, &'static str> {
        Ok(u32::from_le_bytes(take(b, p, 4)?.try_into().unwrap()))
    }
    fn i64_(b: &[u8], p: &mut usize) -> Result<i64, &'static str> {
        Ok(i64::from_le_bytes(take(b, p, 8)?.try_into().unwrap()))
    }
    fn aff(b: &[u8], p: &mut usize) -> Result<Affine, &'static str> {
        let c = Sz::decode(b, p)?;
        let n = u32_(b, p)?;
        let k = (0..n).map(|_| i64_(b, p)).collect::<Result<_, _>>()?;
        Ok(Affine { c, k })
    }
    fn rf(b: &[u8], p: &mut usize) -> Result<SymRef, &'static str> {
        let var = u32_(b, p)?;
        let n = u32_(b, p)?;
        let mut subs = Vec::new();
        for _ in 0..n {
            subs.push(match u8_(b, p)? {
                0 => SymSub::All,
                1 => SymSub::Index(aff(b, p)?),
                _ => {
                    let start = aff(b, p)?;
                    let step = i64_(b, p)?;
                    SymSub::Slice { start, step, stop: aff(b, p)? }
                }
            });
        }
        Ok(SymRef { var, subs })
    }
    if u8_(b, p)? == 0 {
        return Ok(None);
    }
    let n = Sz::decode(b, p)?;
    let mut var_lists: [Vec<SymVar>; 2] = Default::default();
    for vars in var_lists.iter_mut() {
        for _ in 0..u32_(b, p)? {
            let base = Sz::decode(b, p)?;
            let nd = u32_(b, p)?;
            let dims = (0..nd).map(|_| Sz::decode(b, p)).collect::<Result<_, _>>()?;
            vars.push(SymVar { base, dims });
        }
    }
    let [rows_vars, cols_vars] = var_lists;
    let mut rows = Vec::new();
    for _ in 0..u32_(b, p)? {
        let mut iters = Vec::new();
        for _ in 0..u32_(b, p)? {
            let start = Sz::decode(b, p)?;
            let step = i64_(b, p)?;
            iters.push(SymIter { start, step, size: Sz::decode(b, p)? });
        }
        let solved = (0..u32_(b, p)?).map(|_| rf(b, p)).collect::<Result<_, _>>()?;
        let mut deps = Vec::new();
        for _ in 0..u32_(b, p)? {
            let r = rf(b, p)?;
            deps.push((r, u8_(b, p)? != 0));
        }
        rows.push(SymRow { iters, solved, deps });
    }
    Ok(Some(SymPattern { n, rows_vars, cols_vars, rows }))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cascade_pattern() {
        // der(x[i]) depends on x[i] and x[i-1] for i in 1:N.
        let n = Sz::param(0);
        let var = SymVar { base: Sz::lit(0), dims: vec![n.clone()] };
        let it = |c: i64| Affine { c: Sz::lit(c), k: vec![1] };
        let p = SymPattern {
            n: n.clone(),
            rows_vars: vec![var.clone()],
            cols_vars: vec![var],
            rows: vec![SymRow {
                iters: vec![SymIter { start: Sz::lit(1), step: 1, size: n }],
                solved: vec![SymRef { var: 0, subs: vec![SymSub::All] }],
                deps: vec![
                    (SymRef { var: 0, subs: vec![SymSub::Index(it(0))] }, false),
                    (SymRef { var: 0, subs: vec![SymSub::Index(it(-1))] }, false),
                ],
            }],
        };
        let cols = p.expand(&[4]).unwrap();
        assert_eq!(cols, vec![vec![0, 1], vec![1, 2], vec![2, 3], vec![3]]);
        assert_eq!(color_columns(&cols).len(), 2);
        let mut b = Vec::new();
        put(&mut b, &Some(p.clone()));
        let mut pos = 0;
        assert_eq!(get(&b, &mut pos).unwrap(), Some(p));
    }
}

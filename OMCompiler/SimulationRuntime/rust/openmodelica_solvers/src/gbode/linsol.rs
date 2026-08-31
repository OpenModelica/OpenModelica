//! The factorizations behind gbode's Newton matrices: LINPACK's dense LU, or —
//! past a size threshold, under the `sparse` feature — an `rsparse` LU (CSparse
//! with AMD ordering), standing in for C's KLU. The matrix arrives assembled
//! dense either way; the sparse path scans it for structural nonzeros, so a
//! system that turned out dense still gets the dense factorization.

use alloc::vec;
use alloc::vec::Vec;

use crate::Result;

/// Below this order the `n³` is trivial and the sparse setup costs more than it
/// saves; C runs KLU regardless, which only a profile would tell apart here.
#[cfg(feature = "sparse")]
const SPARSE_MIN_SIZE: usize = 64;

pub(super) enum GbLu {
    Dense {
        lu: Vec<f64>,
        ipvt: Vec<i32>,
        n: usize,
    },
    #[cfg(feature = "sparse")]
    Sparse {
        s: rsparse::data::Symb,
        nm: rsparse::data::Nmrc<f64>,
        x: Vec<f64>,
        n: usize,
    },
}

/// Factorize the column-major `n*n` matrix. The diagonal is taken as structural
/// (every gbode system has `±I` or `gamma/h*I` on it), so the sparse pattern
/// always admits a pivot.
pub(super) fn factor(a: &[f64], n: usize) -> Result<GbLu> {
    #[cfg(feature = "sparse")]
    if n >= SPARSE_MIN_SIZE {
        let mut p = vec![0isize; n + 1];
        let mut i: Vec<usize> = Vec::new();
        let mut x: Vec<f64> = Vec::new();
        for c in 0..n {
            for r in 0..n {
                let v = a[c * n + r];
                if v != 0.0 || r == c {
                    i.push(r);
                    x.push(v);
                }
            }
            p[c + 1] = i.len() as isize;
        }
        // Keep genuinely sparse systems only: LU fill on a dense-ish matrix costs
        // more than the dense factorization it would replace.
        if i.len() * 4 <= n * n {
            let nzmax = i.len();
            let sp = rsparse::data::Sprs { nzmax, m: n, n, p, i, x };
            let mut s = rsparse::sqr(&sp, 2, false);
            let nm = rsparse::lu(&sp, &mut s, 1.0)
                .map_err(|_| "CodegenWasmJit: gbode: singular Newton matrix")?;
            return Ok(GbLu::Sparse { s, nm, x: vec![0.0; n], n });
        }
    }
    let mut lu = a[..n * n].to_vec();
    let mut ipvt = vec![0i32; n];
    let mut info = 0i32;
    daskr::linpack::dgefa(&mut lu, n as i32, n as i32, &mut ipvt, &mut info);
    if info != 0 {
        return Err("CodegenWasmJit: gbode: singular Newton matrix");
    }
    Ok(GbLu::Dense { lu, ipvt, n })
}

impl GbLu {
    /// Solve `A x = b` in place with the stored factorization.
    pub(super) fn solve(&mut self, b: &mut [f64]) {
        match self {
            GbLu::Dense { lu, ipvt, n } => {
                daskr::linpack::dgesl(lu, *n as i32, *n as i32, ipvt, b, 0);
            }
            #[cfg(feature = "sparse")]
            GbLu::Sparse { s, nm, x, n } => {
                let n = *n;
                match &nm.pinv {
                    Some(p) => {
                        for k in 0..n {
                            x[p[k] as usize] = b[k];
                        }
                    }
                    None => x[..n].copy_from_slice(&b[..n]),
                }
                rsparse::lsolve(&nm.l, &mut x[..n]);
                rsparse::usolve(&nm.u, &mut x[..n]);
                match &s.q {
                    Some(q) => {
                        for k in 0..n {
                            b[q[k] as usize] = x[k];
                        }
                    }
                    None => b[..n].copy_from_slice(&x[..n]),
                }
            }
        }
    }
}

/// Greedy distance-2 coloring of a column pattern, C's `colorSparsePattern`
/// (`gbode_sparse.c`) for one stage block: columns whose row sets are disjoint
/// share a color and can be differenced (or seeded) together.
pub(super) fn color_columns(rows_by_col: &[Vec<usize>], n_rows: usize) -> Vec<Vec<usize>> {
    let n_cols = rows_by_col.len();
    let mut colored = vec![false; n_cols];
    let mut row_mark = vec![0usize; n_rows];
    let mut groups: Vec<Vec<usize>> = Vec::new();
    let mut remaining = n_cols;
    let mut color = 0usize;
    while remaining > 0 {
        color += 1;
        let mut group = Vec::new();
        for col in 0..n_cols {
            if colored[col] {
                continue;
            }
            if rows_by_col[col].iter().any(|&r| row_mark[r] == color) {
                continue;
            }
            colored[col] = true;
            remaining -= 1;
            for &r in &rows_by_col[col] {
                row_mark[r] = color;
            }
            group.push(col);
        }
        groups.push(group);
    }
    groups
}

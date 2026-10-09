//! The factorizations behind gbode's Newton matrices.
//!
//! The internal solver keeps C's layout: every system is `struct(I + J)` in CSC
//! ([`NlsPattern`]), and all of them share one KLU symbolic analysis
//! ([`GbLinSys`]), the conjugate-pair ones factored complex. Without KLU the same
//! CSC goes to LINPACK's dense LU, or past a size threshold under the `sparse`
//! feature to an `rsparse` LU, a complex system as its real `2n` embedding.
//!
//! The generic solvers' own Newton (without the runtime's) still assembles
//! dense matrices and uses [`factor`], which scans them for structural nonzeros.

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
                .map_err(|_| "##GBODE## singular Newton matrix")?;
            return Ok(GbLu::Sparse { s, nm, x: vec![0.0; n], n });
        }
    }
    let mut lu = a[..n * n].to_vec();
    let mut ipvt = vec![0i32; n];
    let mut info = 0i32;
    daskr::linpack::dgefa(&mut lu, n as i32, n as i32, &mut ipvt, &mut info);
    if info != 0 {
        return Err("##GBODE## singular Newton matrix");
    }
    Ok(GbLu::Dense { lu, ipvt, n })
}

impl GbLu {
    /// Factorize the `n*n` CSC matrix; `None` if it is singular.
    fn from_csc(n: usize, ap: &[i32], ai: &[i32], ax: &[f64]) -> Option<GbLu> {
        #[cfg(feature = "sparse")]
        if n >= SPARSE_MIN_SIZE {
            let sp = rsparse::data::Sprs {
                nzmax: ax.len(),
                m: n,
                n,
                p: ap.iter().map(|&v| v as isize).collect(),
                i: ai.iter().map(|&v| v as usize).collect(),
                x: ax.to_vec(),
            };
            let mut s = rsparse::sqr(&sp, 2, false);
            let nm = rsparse::lu(&sp, &mut s, 1.0).ok()?;
            return Some(GbLu::Sparse { s, nm, x: vec![0.0; n], n });
        }
        let mut lu = vec![0.0; n * n];
        for c in 0..n {
            for nz in ap[c] as usize..ap[c + 1] as usize {
                lu[c * n + ai[nz] as usize] = ax[nz];
            }
        }
        let mut ipvt = vec![0i32; n];
        let mut info = 0i32;
        daskr::linpack::dgefa(&mut lu, n as i32, n as i32, &mut ipvt, &mut info);
        (info == 0).then_some(GbLu::Dense { lu, ipvt, n })
    }

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
pub(crate) fn color_columns(rows_by_col: &[Vec<usize>], n_rows: usize) -> Vec<Vec<usize>> {
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

/// The ODE Jacobian's pattern in CSC, rows in the model's order, with its
/// colouring: C's `getJacobianCscPattern`. A model without one is dense.
pub(super) struct OdePattern {
    pub ap: Vec<u32>,
    pub ai: Vec<u32>,
    pub colors: Vec<Vec<u32>>,
}

impl OdePattern {
    pub(super) fn new(n: usize, rows_by_col: &[Vec<u32>], colors: &[Vec<u32>]) -> Self {
        let mut ap = Vec::with_capacity(n + 1);
        let mut ai = Vec::new();
        ap.push(0);
        for c in 0..n {
            match rows_by_col.get(c) {
                Some(rows) => ai.extend_from_slice(rows),
                None => ai.extend(0..n as u32),
            }
            ap.push(ai.len() as u32);
        }
        let colors = match colors {
            [] => (0..n as u32).map(|c| vec![c]).collect(),
            c => c.to_vec(),
        };
        OdePattern { ap, ai, colors }
    }

    pub(super) fn nnz(&self) -> usize {
        self.ai.len()
    }

    /// C's `reduceSparsePattern` onto the principal submatrix of `idx`, then
    /// `colorSparsePattern` over it.
    pub(super) fn reduce(&self, idx: &[usize], n_full: usize) -> Self {
        let mut pos = vec![u32::MAX; n_full];
        for (i, &k) in idx.iter().enumerate() {
            pos[k] = i as u32;
        }
        let mut ap = Vec::with_capacity(idx.len() + 1);
        let mut ai = Vec::new();
        ap.push(0);
        for &c in idx {
            for nz in self.ap[c] as usize..self.ap[c + 1] as usize {
                let r = pos[self.ai[nz] as usize];
                if r != u32::MAX {
                    ai.push(r);
                }
            }
            ap.push(ai.len() as u32);
        }
        let colors = color_csc(&ap, &ai, idx.len());
        OdePattern { ap, ai, colors }
    }
}

/// C's `colorSparsePattern` for one block: greedily, columns whose rows are
/// disjoint share a colour.
fn color_csc(ap: &[u32], ai: &[u32], n: usize) -> Vec<Vec<u32>> {
    let mut colored = vec![false; n];
    let mut row_mark = vec![0u32; n];
    let mut groups: Vec<Vec<u32>> = Vec::new();
    let mut remaining = n;
    while remaining > 0 {
        let color = groups.len() as u32 + 1;
        let mut group = Vec::new();
        for col in 0..n {
            let rows = &ai[ap[col] as usize..ap[col + 1] as usize];
            if colored[col] || rows.iter().any(|&r| row_mark[r as usize] == color) {
                continue;
            }
            colored[col] = true;
            remaining -= 1;
            for &r in rows {
                row_mark[r as usize] = color;
            }
            group.push(col as u32);
        }
        groups.push(group);
    }
    groups
}

/// C's `sparsePatternWithDiagonal` and `gbodeMapSparsePattern`: `struct(I + J)`
/// with sorted rows, where each ODE Jacobian entry lands in it, and each
/// column's diagonal.
pub(super) struct NlsPattern {
    pub n: usize,
    pub ap: Vec<i32>,
    pub ai: Vec<i32>,
    pub ode_to_nls: Vec<u32>,
    pub diag: Vec<u32>,
}

impl NlsPattern {
    pub(super) fn new(n: usize, ode: &OdePattern) -> Self {
        let mut ap = Vec::with_capacity(n + 1);
        let mut ai: Vec<i32> = Vec::with_capacity(ode.nnz() + n);
        let mut ode_to_nls = vec![0u32; ode.nnz()];
        let mut diag = vec![0u32; n];
        let mut col: Vec<i32> = Vec::new();
        ap.push(0);
        for c in 0..n {
            let (lo, hi) = (ode.ap[c] as usize, ode.ap[c + 1] as usize);
            col.clear();
            col.extend(ode.ai[lo..hi].iter().map(|&r| r as i32));
            col.push(c as i32);
            col.sort_unstable();
            col.dedup();
            let base = ai.len();
            for nz in lo..hi {
                let pos = col.binary_search(&(ode.ai[nz] as i32)).unwrap();
                ode_to_nls[nz] = (base + pos) as u32;
            }
            diag[c] = (base + col.binary_search(&(c as i32)).unwrap()) as u32;
            ai.extend_from_slice(&col);
            ap.push(ai.len() as i32);
        }
        NlsPattern { n, ap, ai, ode_to_nls, diag }
    }

    pub(super) fn nnz(&self) -> usize {
        self.ai.len()
    }
}

/// C's `KLUInternals`: `n_real` real and `n_cmplx` complex matrices over one
/// [`NlsPattern`]. Statuses follow `klu_common.status`: negative is a failure,
/// `1` a singular matrix, whose solves then leave the right-hand side alone.
pub(super) struct GbLinSys {
    pub pat: NlsPattern,
    klu: Option<crate::klu::Shared>,
    real: Vec<Option<GbLu>>,
    cmplx: Vec<Option<GbLu>>,
    work: Vec<f64>,
}

impl GbLinSys {
    pub(super) fn new(mut pat: NlsPattern, n_real: usize, n_cmplx: usize) -> Self {
        let klu = crate::klu::Shared::analyze(pat.n, &mut pat.ap, &mut pat.ai, n_real, n_cmplx);
        GbLinSys {
            pat,
            klu,
            real: (0..n_real).map(|_| None).collect(),
            cmplx: (0..n_cmplx).map(|_| None).collect(),
            work: Vec::new(),
        }
    }

    pub(super) fn factor_real(&mut self, sys: usize, ax: &mut [f64]) -> i32 {
        if let Some(klu) = self.klu.as_mut() {
            return klu.factor_real(sys, &mut self.pat.ap, &mut self.pat.ai, ax);
        }
        self.real[sys] = GbLu::from_csc(self.pat.n, &self.pat.ap, &self.pat.ai, ax);
        if self.real[sys].is_some() { 0 } else { 1 }
    }

    pub(super) fn solve_real(&mut self, sys: usize, b: &mut [f64]) {
        if let Some(klu) = self.klu.as_mut() {
            klu.solve_real(sys, b);
        } else if let Some(lu) = self.real[sys].as_mut() {
            lu.solve(b);
        }
    }

    /// `ax` holds `re, im` per pattern entry.
    pub(super) fn factor_cmplx(&mut self, sys: usize, ax: &mut [f64]) -> i32 {
        if let Some(klu) = self.klu.as_mut() {
            return klu.factor_cmplx(sys, &mut self.pat.ap, &mut self.pat.ai, ax);
        }
        // `[[Re, -Im], [Im, Re]]` acting on `[x_re; x_im]`.
        let (n, pat) = (self.pat.n, &self.pat);
        let mut ap = Vec::with_capacity(2 * n + 1);
        let mut ai = Vec::with_capacity(4 * pat.nnz());
        let mut vx = Vec::with_capacity(4 * pat.nnz());
        ap.push(0i32);
        for half in 0..2 {
            for c in 0..n {
                let range = pat.ap[c] as usize..pat.ap[c + 1] as usize;
                for nz in range.clone() {
                    ai.push(pat.ai[nz]);
                    vx.push(if half == 0 { ax[2 * nz] } else { -ax[2 * nz + 1] });
                }
                for nz in range {
                    ai.push(pat.ai[nz] + n as i32);
                    vx.push(if half == 0 { ax[2 * nz + 1] } else { ax[2 * nz] });
                }
                ap.push(ai.len() as i32);
            }
        }
        self.cmplx[sys] = GbLu::from_csc(2 * n, &ap, &ai, &vx);
        if self.cmplx[sys].is_some() { 0 } else { 1 }
    }

    /// `b` holds `re, im` per unknown.
    pub(super) fn solve_cmplx(&mut self, sys: usize, b: &mut [f64]) {
        if let Some(klu) = self.klu.as_mut() {
            klu.solve_cmplx(sys, b);
            return;
        }
        let n = self.pat.n;
        let Some(lu) = self.cmplx[sys].as_mut() else { return };
        self.work.resize(2 * n, 0.0);
        for i in 0..n {
            self.work[i] = b[2 * i];
            self.work[n + i] = b[2 * i + 1];
        }
        lu.solve(&mut self.work);
        for i in 0..n {
            b[2 * i] = self.work[i];
            b[2 * i + 1] = self.work[n + i];
        }
    }
}

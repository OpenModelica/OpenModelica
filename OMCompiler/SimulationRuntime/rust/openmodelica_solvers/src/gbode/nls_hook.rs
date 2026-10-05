//! C's `solveNLS` for `-gbnls=kinsol`, `experimental-kinsol` and `newton`, which
//! `openmodelica_nls` (a dependent of this crate) registers with [`set_nls_hook`].

use alloc::vec;
use alloc::vec::Vec;
use core::sync::atomic::{AtomicUsize, Ordering};

pub use super::conf::NlsMethod;
use super::tableau::Tableau;

/// C's `set_kinsol_parameters` for one phase of `solveNLS_gb`.
#[derive(Clone, Copy, Debug)]
pub struct KinsolParams {
    pub max_iters: u32,
    /// `KINSetNoInitSetup`: keep the Jacobian of the previous solve.
    pub no_init_setup: bool,
    pub max_setup_calls: u32,
    pub fnorm_tol: f64,
}

/// One gbode nonlinear system, as C hands its `NONLINEAR_SYSTEM_DATA` to `solveNLS`.
pub struct GbNlsRequest<'a> {
    pub method: NlsMethod,
    /// One solver memory per gbode system: 0 the single-rate one, 1 the fast states'.
    pub handle: u32,
    pub n: usize,
    /// C's `sparsePattern_NLS` in CSC, with its 0-based column colours.
    pub colptr: &'a [i32],
    pub rowidx: &'a [i32],
    pub colors: &'a [u32],
    pub nominal: &'a [f64],
    pub min: &'a [f64],
    pub max: &'a [f64],
    /// C's `nlsxExtrapolation` and `nlsxOld`; `x` is `nlsx`, written on success.
    pub start: &'a [f64],
    pub old: &'a [f64],
    pub x: &'a mut [f64],
    pub kinsol: KinsolParams,
    pub time: f64,
    pub eval: &'a mut dyn FnMut(&[f64], &mut [f64]),
    /// The CSC values of C's symbolic `jacobian_*_column`; `None` differences them.
    pub jacobian: Option<&'a mut dyn FnMut(&[f64], &mut [f64])>,
    /// Set by the solver: its Jacobian evaluations (C's `numberOfJEval`).
    pub jac_evals: u64,
}

pub type GbNlsHook = fn(&mut GbNlsRequest) -> bool;

static HOOK: AtomicUsize = AtomicUsize::new(0);

pub fn set_nls_hook(f: Option<GbNlsHook>) {
    HOOK.store(f.map_or(0, |f| f as usize), Ordering::Relaxed);
}

pub(super) fn nls_hook() -> Option<GbNlsHook> {
    match HOOK.load(Ordering::Relaxed) {
        0 => None,
        p => Some(unsafe { core::mem::transmute::<usize, GbNlsHook>(p) }),
    }
}

/// C's `SPARSE_PATTERN` of a gbode system, in CSC.
pub(super) struct NlsPattern {
    pub colptr: Vec<i32>,
    pub rowidx: Vec<i32>,
    pub colors: Vec<u32>,
    pub groups: Vec<Vec<usize>>,
}

impl NlsPattern {
    fn from_columns(cols: Vec<Vec<usize>>, colors: Vec<u32>) -> Self {
        let mut colptr = vec![0i32];
        let mut rowidx = Vec::new();
        for c in &cols {
            rowidx.extend(c.iter().map(|&r| r as i32));
            colptr.push(rowidx.len() as i32);
        }
        let n_colors = colors.iter().map(|&c| c as usize + 1).max().unwrap_or(0);
        let mut groups = vec![Vec::new(); n_colors];
        for (col, &c) in colors.iter().enumerate() {
            groups[c as usize].push(col);
        }
        NlsPattern { colptr, rowidx, colors, groups }
    }

    /// C's `sparsePatternWithDiagonal`: `struct(I + J)`, reusing `source_colors`
    /// when every column already had its diagonal, else C's colouring.
    pub fn with_diagonal(rows_by_col: &[Vec<usize>], source_colors: &[Vec<u32>]) -> Self {
        let n = rows_by_col.len();
        let mut had_diagonal = 0;
        let cols: Vec<Vec<usize>> = rows_by_col
            .iter()
            .enumerate()
            .map(|(col, rows)| {
                let mut out = Vec::with_capacity(rows.len() + 1);
                let mut diagonal = false;
                for &row in rows {
                    if !diagonal && row > col {
                        out.push(col);
                        diagonal = true;
                    }
                    if row == col {
                        diagonal = true;
                        had_diagonal += 1;
                    }
                    out.push(row);
                }
                if !diagonal {
                    out.push(col);
                }
                out
            })
            .collect();
        let colors = if had_diagonal == n && !source_colors.is_empty() {
            let mut colors = vec![0u32; n];
            for (g, group) in source_colors.iter().enumerate() {
                for &c in group {
                    colors[c as usize] = g as u32;
                }
            }
            colors
        } else {
            color_stages(&cols, n, 1)
        };
        Self::from_columns(cols, colors)
    }

    /// C's `initializeSparsePattern_IRK`: the ODE pattern in every block the Butcher
    /// matrix couples, plus the diagonal, coloured stage by stage.
    pub fn irk(rows_by_col: &[Vec<usize>], t: &Tableau) -> Self {
        let n = rows_by_col.len();
        let s = t.n_stages;
        let mut cols = Vec::with_capacity(n * s);
        for k in 0..s {
            for col in 0..n {
                let gc = col + k * n;
                let mut out = Vec::new();
                let mut diagonal = false;
                for l in 0..s {
                    for &row in &rows_by_col[col] {
                        let gr = row + l * n;
                        if gc < gr && !diagonal {
                            out.push(gc);
                            diagonal = true;
                        }
                        if t.a_at(l, k) != 0.0 {
                            if gc == gr {
                                diagonal = true;
                            }
                            out.push(gr);
                        }
                    }
                }
                if !diagonal {
                    out.push(gc);
                }
                cols.push(out);
            }
        }
        let colors = color_stages(&cols, n * s, s);
        Self::from_columns(cols, colors)
    }
}

/// C's `colorSparsePattern`: greedy colours within each stage's block of columns,
/// 0-based here.
fn color_stages(cols: &[Vec<usize>], n_rows: usize, n_stages: usize) -> Vec<u32> {
    let stage_size = cols.len() / n_stages;
    let mut colors = vec![0u32; cols.len()];
    let mut work = vec![0u32; n_rows];
    let mut color = 0u32;
    for stage in 0..n_stages {
        let range = stage * stage_size..(stage + 1) * stage_size;
        let mut remaining = stage_size;
        while remaining > 0 {
            color += 1;
            for col in range.clone() {
                if colors[col] != 0 || cols[col].iter().any(|&r| work[r] == color) {
                    continue;
                }
                colors[col] = color;
                remaining -= 1;
                for &r in &cols[col] {
                    work[r] = color;
                }
            }
        }
    }
    colors.iter().map(|&c| c - 1).collect()
}

/// The ODE Jacobian's rows by column, every row where the model gives no pattern.
pub(super) fn ode_rows_by_col(rows: &[Vec<u32>], n: usize) -> Vec<Vec<usize>> {
    if rows.is_empty() {
        return (0..n).map(|_| (0..n).collect()).collect();
    }
    rows.iter().map(|r| r.iter().map(|&v| v as usize).collect()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_missing_diagonal_is_inserted_in_row_order_and_recoloured() {
        let p = NlsPattern::with_diagonal(&[vec![1], vec![0, 1]], &[vec![0, 1]]);
        assert_eq!(p.colptr, [0, 2, 4]);
        assert_eq!(p.rowidx, [0, 1, 0, 1]);
        assert_eq!(p.colors, [0, 1]);
    }

    #[test]
    fn a_full_diagonal_keeps_the_source_colouring() {
        let p = NlsPattern::with_diagonal(&[vec![0], vec![1]], &[vec![0, 1]]);
        assert_eq!(p.rowidx, [0, 1]);
        assert_eq!(p.colors, [0, 0]);
        assert_eq!(p.groups, [vec![0, 1]]);
    }

    #[test]
    fn stages_never_share_a_colour() {
        assert_eq!(color_stages(&[vec![0], vec![1]], 2, 2), [0, 1]);
        assert_eq!(color_stages(&[vec![0], vec![1]], 2, 1), [0, 0]);
    }
}

// Manually written file.
//
// Rust port of the `external "C"` bodies declared in
// `OMCompiler/Compiler/NBackEnd/Util/NBASSC.mo`, whose C side lives in
// `OMCompiler/Compiler/runtime/ASSCEXT_omc.cpp`. These are wired in via
// `external_c_calls::external_c_impl_path` (`ASSC_setMatrix` →
// `crate::NBASSCExt::ASSC_setMatrix`, etc.), so the generated `NBASSC.rs`
// calls into this hand-written module rather than emitting `todo!()`.

use std::sync::Arc;

use metamodelica::{Result, Array, List};

/// Operation recorded during Bareiss elimination, matching `ASSC_OPERATION` in ASSCEXT.h.
enum AsscOp {
    // mode 0: pivot-update (normal Bareiss step)
    PivotUpdate { pivot_index: i32, pivot_value: i32, update_index: i32, update_value: i32 },
    // mode 1: row swap
    SwapRows { index1: i32, index2: i32 },
    // mode 2: GCD reduction
    Gcd { index: i32, gcd_value: i32 },
}

/// Sparse matrix store: CSR triplets plus sorted per-row `(index, value)` pairs,
/// row permutation, and Bareiss operation log. Mirrors the C globals in ASSCEXT.cpp.
#[derive(Default)]
struct AsscMatrix {
    nv: i32,
    ne: i32,
    col_ptrs: Vec<i32>,
    col_ids: Vec<i32>,
    col_val: Vec<i32>,
    rows: Vec<Vec<(i32, i32)>>,
    /// mapping[i] gives the physical row index for logical row i (updated by Bareiss swaps).
    mapping: Vec<usize>,
    /// Operations recorded by the last `ASSC_bareiss()` call.
    operations: Vec<AsscOp>,
}

thread_local! {
    static ASSC_MATRIX: std::cell::RefCell<Option<AsscMatrix>> =
        const { std::cell::RefCell::new(None) };
}

/// `ASSC_setMatrix(nv, ne, nz, adj, val)`: store the adjacency/value matrix in
/// CSR form. `adj` holds 1-based column indices; we store them 0-based, mirroring
/// the C implementation.
pub fn ASSC_setMatrix(
    nv: i32,
    ne: i32,
    nz: i32,
    adj: Array<Arc<List<i32>>>,
    val: Array<Arc<List<i32>>>,
) {
    let mut m = AsscMatrix {
        nv,
        ne,
        col_ptrs: Vec::with_capacity(ne as usize + 1),
        col_ids: Vec::with_capacity(nz as usize),
        col_val: Vec::with_capacity(nz as usize),
        rows: Vec::with_capacity(ne as usize),
        mapping: (0..ne as usize).collect(),
        operations: Vec::new(),
    };
    m.col_ptrs.push(0);
    let adj = adj.borrow();
    let val = val.borrow();
    for i in 0..ne as usize {
        let mut row = Vec::new();
        for (a, v) in (&*adj[i]).into_iter().zip(&*val[i]) {
            m.col_ids.push(*a - 1);
            m.col_val.push(*v);
            row.push((*a - 1, *v));
        }
        m.col_ptrs.push(m.col_ids.len() as i32);
        m.rows.push(row);
    }
    ASSC_MATRIX.with(|s| *s.borrow_mut() = Some(m));
}

/// `ASSC_getMatrix(adj, val)`: fill pre-allocated adj/val arrays from the stored
/// rows, respecting the row permutation established by the last Bareiss call.
pub fn ASSC_getMatrix(adj: Array<Arc<List<i32>>>, val: Array<Arc<List<i32>>>) {
    ASSC_MATRIX.with(|s| {
        let borrow = s.borrow();
        let Some(m) = borrow.as_ref() else { return };
        let ne = adj.borrow().len();
        for i in 0..ne {
            let row_idx = m.mapping[i];
            if !m.rows[row_idx].is_empty() {
                // Build immutable cons lists in forward order by folding in reverse.
                let adj_list = m.rows[row_idx].iter().rev().fold(
                    Arc::new(List::Nil),
                    |tail, &(idx, _)| Arc::new(List::Cons { head: idx, tail }),
                );
                let val_list = m.rows[row_idx].iter().rev().fold(
                    Arc::new(List::Nil),
                    |tail, &(_, v)| Arc::new(List::Cons { head: v, tail }),
                );
                adj.borrow_mut()[i] = adj_list;
                val.borrow_mut()[i] = val_list;
            }
        }
    });
}

/// `ASSC_freeMatrix()`: drop the stored matrix.
pub fn ASSC_freeMatrix() {
    ASSC_MATRIX.with(|s| *s.borrow_mut() = None);
}

/// `ASSC_printMatrix()`: print the stored matrix to stdout in CSR and element-list formats.
pub fn ASSC_printMatrix() {
    ASSC_MATRIX.with(|s| {
        let borrow = s.borrow();
        let Some(m) = borrow.as_ref() else { return };
        println!("Sparse Matrix:\n================");
        for i in 0..m.ne as usize {
            print!("{i}: ");
            for j in m.col_ptrs[i]..m.col_ptrs[i + 1] {
                print!("({},{})", m.col_ids[j as usize], m.col_val[j as usize]);
            }
            println!();
        }
        for row in &m.rows {
            for (index, value) in row {
                print!("({index}: {value}) ");
            }
            println!();
        }
    });
}

/// `ASSC_bareiss()`: run Bareiss elimination on the stored matrix, updating the row
/// permutation and recording all operations for later retrieval.
pub fn ASSC_bareiss() {
    ASSC_MATRIX.with(|s| {
        let mut borrow = s.borrow_mut();
        let Some(m) = borrow.as_mut() else { return };
        bareiss_impl(m);
    });
}

/// `ASSC_getNumberOfOperations(nop)`: return the number of recorded operations and
/// write it into `nop[0]` (the single-element output array).
pub fn ASSC_getNumberOfOperations(nop: Array<i32>) -> i32 {
    ASSC_MATRIX.with(|s| {
        let borrow = s.borrow();
        let num = borrow.as_ref().map_or(0, |m| m.operations.len() as i32);
        nop.borrow_mut()[0] = num;
        num
    })
}

/// `ASSC_getOperations(op_modes, op_val1..4)`: fill five pre-allocated arrays with
/// the operation log from the last `ASSC_bareiss()` call. Mirrors the MMC_THROW
/// paths in `ASSCEXT_omc.cpp`.
pub fn ASSC_getOperations(
    op_modes: Array<i32>,
    op_val1: Array<i32>,
    op_val2: Array<i32>,
    op_val3: Array<i32>,
    op_val4: Array<i32>,
) -> Result<()> {
    ASSC_MATRIX.with(|s| {
        let borrow = s.borrow();
        let Some(m) = borrow.as_ref() else {
            return Err("ASSCEXT.getOperations failed because ops == NULL");
        };
        let ops = &m.operations;
        let expected = ops.len();
        let len_modes = op_modes.borrow().len();
        let len1 = op_val1.borrow().len();
        let len2 = op_val2.borrow().len();
        let len3 = op_val3.borrow().len();
        let len4 = op_val4.borrow().len();
        if expected != len_modes {
            return Err("BackendDAEEXT.getAssignment failed because op_modes length={len_modes}!={expected}=op length");
        }
        if expected != len1 {
            return Err("BackendDAEEXT.getAssignment failed because op_val1 length={len1}!={expected}=op length");
        }
        if expected != len2 {
            return Err("BackendDAEEXT.getAssignment failed because op_val2 length={len2}!={expected}=op length");
        }
        if expected != len3 {
            return Err("BackendDAEEXT.getAssignment failed because op_val3 length={len3}!={expected}=op length");
        }
        if expected != len4 {
            return Err("BackendDAEEXT.getAssignment failed because op_val4 length={len4}!={expected}=op length");
        }
        let mut modes = op_modes.borrow_mut();
        let mut v1 = op_val1.borrow_mut();
        let mut v2 = op_val2.borrow_mut();
        let mut v3 = op_val3.borrow_mut();
        let mut v4 = op_val4.borrow_mut();
        for (i, op) in ops.iter().enumerate() {
            match op {
                AsscOp::PivotUpdate { pivot_index, pivot_value, update_index, update_value } => {
                    modes[i] = 0;
                    v1[i] = *pivot_index;
                    v2[i] = *pivot_value;
                    v3[i] = *update_index;
                    v4[i] = *update_value;
                }
                AsscOp::SwapRows { index1, index2 } => {
                    modes[i] = 1;
                    v1[i] = *index1;
                    v2[i] = *index2;
                }
                AsscOp::Gcd { index, gcd_value } => {
                    modes[i] = 2;
                    v1[i] = *index;
                    v2[i] = *gcd_value;
                }
            }
        }
        Ok(())
    })
}

/// GCD of two integers (Euclidean algorithm, always returns non-negative).
fn gcd(a: i32, b: i32) -> i32 {
    let (mut a, mut b) = (a.abs(), b.abs());
    while b != 0 {
        let t = b;
        b = a % b;
        a = t;
    }
    a
}

/// Faithful Rust port of `bareiss()` from `ASSCEXT.cpp`.
///
/// Operates on `m.rows` (sorted sparse rows), updating `m.mapping` to track row
/// swaps and appending to `m.operations`. The algorithm is an integer-preserving
/// Gaussian elimination (Bareiss): no divisions occur until the optional GCD
/// reduction step, so all intermediate values remain exact integers.
fn bareiss_impl(m: &mut AsscMatrix) {
    let n = (m.ne.min(m.nv)) as usize;
    if n == 0 {
        return;
    }
    // Re-initialize mapping for the first n rows (Bareiss resets it on each call).
    for i in 0..n {
        m.mapping[i] = i;
    }
    // Singular check: if any row is empty the matrix is immediately singular.
    for row in 0..m.ne as usize {
        if m.rows[m.mapping[row]].is_empty() {
            return;
        }
    }
    m.operations.clear();
    let mut shift = 0i32;

    for k in 0..n.saturating_sub(1) {
        let initial_pivot_idx = m.rows[m.mapping[k]][0].0;

        if initial_pivot_idx != k as i32 + shift {
            // No element at the expected pivot position — search [k..n) for the row
            // whose first element has the smallest column index.
            let mut index_new = n as i32;
            let mut pivot_ind = k;
            for k_new in k..n {
                let first_idx = m.rows[m.mapping[k_new]][0].0;
                if first_idx < index_new {
                    index_new = first_idx;
                    pivot_ind = k_new;
                }
            }
            if index_new != k as i32 {
                // No pivot at column k — empty column (singular), record shift.
                shift = index_new - k as i32;
            } else {
                // Pivot found at column k in row pivot_ind — bring it to position k.
                m.mapping.swap(k, pivot_ind);
            }
            m.operations.push(AsscOp::SwapRows {
                index1: k as i32,
                index2: pivot_ind as i32,
            });
        }

        let pivot_val = m.rows[m.mapping[k]][0].1;

        for i in k + 1..n {
            let first_idx = m.rows[m.mapping[i]].first().map_or(i32::MAX, |e| e.0);
            if first_idx != k as i32 + shift {
                continue;
            }
            // Pop the m_{i,k} element from the front of the update row.
            let m_ik = m.rows[m.mapping[i]].remove(0);
            m.operations.push(AsscOp::PivotUpdate {
                pivot_index: k as i32,
                pivot_value: pivot_val,
                update_index: i as i32,
                update_value: m_ik.1,
            });
            // Sparse Bareiss merge-update.
            let pivot_phys = m.mapping[k];
            let update_phys = m.mapping[i];
            bareiss_merge(&mut m.rows, pivot_phys, update_phys, pivot_val, m_ik.1, n as i32);
            // GCD reduction: when every element of the updated row has |v| >= 1000,
            // divide the whole row by the GCD to keep values bounded.
            let row = &m.rows[m.mapping[i]];
            if !row.is_empty() && row.iter().all(|&(_, v)| v.abs() >= 1000) {
                let gcd_val = row.iter().map(|&(_, v)| v.abs()).reduce(gcd).unwrap_or(0);
                if gcd_val != 0 {
                    m.operations.push(AsscOp::Gcd {
                        index: i as i32,
                        gcd_value: gcd_val,
                    });
                    for elem in m.rows[m.mapping[i]].iter_mut() {
                        elem.1 /= gcd_val;
                    }
                }
            }
        }
    }
}

/// Sparse Bareiss merge: update `rows[update_phys]` in-place using
/// `rows[pivot_phys]` (from element 1 onward, skipping the pivot at [0]).
///
/// For each column j present in either row:
/// - j in both:      new = update[j]*pivot_val - m_ik*pivot[j]
/// - j only update:  new = update[j]*pivot_val
/// - j only pivot:   new = -(m_ik * pivot[j])  (insert)
/// Zero results are dropped (integer sparsification).
///
/// Direct translation of the three-case sorted-merge loop in `ASSCEXT.cpp`.
fn bareiss_merge(
    rows: &mut Vec<Vec<(i32, i32)>>,
    pivot_phys: usize,
    update_phys: usize,
    pivot_val: i32,
    m_ik_val: i32,
    n_sentinel: i32,
) {
    // Clone the pivot tail to avoid aliasing with the mutable update row.
    let pivot_tail: Vec<(i32, i32)> = rows[pivot_phys][1..].to_vec();
    // Take ownership of update row; slot is temporarily empty.
    let update_row = std::mem::take(&mut rows[update_phys]);

    let mut result: Vec<(i32, i32)> = Vec::new();
    let mut pi = 0usize;
    let mut ui = 0usize;

    loop {
        let (pe_idx, pe_val) = pivot_tail.get(pi).copied().unwrap_or((n_sentinel, 0));
        let (ue_idx, ue_val) = update_row.get(ui).copied().unwrap_or((n_sentinel, 0));

        if pe_idx == n_sentinel && ue_idx == n_sentinel {
            // Case 0: both exhausted — merge done.
            break;
        } else if pe_idx == ue_idx {
            // Case 1: same column index — Bareiss formula.
            let nv = ue_val * pivot_val - m_ik_val * pe_val;
            if nv != 0 {
                result.push((pe_idx, nv));
            }
            pi += 1;
            ui += 1;
        } else if pe_idx > ue_idx {
            // Case 2: update column smaller — scale by pivot.
            let nv = ue_val * pivot_val;
            if nv != 0 {
                result.push((ue_idx, nv));
            }
            ui += 1;
        } else {
            // Case 3: pivot column smaller — insert negated m_ik contribution.
            let nv = -m_ik_val * pe_val;
            if nv != 0 {
                result.push((pe_idx, nv));
            }
            pi += 1;
        }
    }

    rows[update_phys] = result;
}

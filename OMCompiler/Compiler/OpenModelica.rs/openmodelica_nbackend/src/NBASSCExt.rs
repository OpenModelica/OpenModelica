// Manually written file.
//
// Rust port of the `external "C"` bodies declared in
// `OMCompiler/Compiler/NBackEnd/Util/NBASSC.mo`, whose C side lives in
// `OMCompiler/Compiler/runtime/ASSCEXT_omc.cpp`. These are wired in via
// `external_c_calls::external_c_impl_path` (`ASSC_setMatrix` →
// `crate::NBASSCExt::ASSC_setMatrix`, etc.), so the generated `NBASSC.rs`
// calls into this hand-written module rather than emitting `todo!()`.
//
// The analytical-to-structural singularity conversion matrix store is an
// unfinished upstream feature: `NBASSC.main` builds a dummy matrix,
// `ASSC_setMatrix` stores it in C globals in CSR form, and nothing ever reads
// it back (the `printMatrix` call in NBASSC.mo is commented out). We mirror the
// storage semantics with a thread-local — the C globals are only touched from
// the single-threaded backend, and a thread-local keeps the Rust port safe if
// that ever changes.

use std::sync::Arc;

use metamodelica::{Array, List};

/// CSR matrix plus per-row `(index, value)` pairs, mirroring the C globals
/// `col_ptrs`/`col_ids`/`col_val` and the `rows` linked lists.
#[derive(Default)]
struct AsscMatrix {
    ne: i32,
    col_ptrs: Vec<i32>,
    col_ids: Vec<i32>,
    col_val: Vec<i32>,
    rows: Vec<Vec<(i32, i32)>>,
}

thread_local! {
    static ASSC_MATRIX: std::cell::RefCell<Option<AsscMatrix>> =
        const { std::cell::RefCell::new(None) };
}

/// `ASSC_setMatrix(nv, ne, nz, adj, val)`: store the adjacency/value matrix in
/// CSR form. `adj` holds 1-based column indices; the C side stores them 0-based,
/// and so do we. `nv` (variable count) is stored by the C side but never read;
/// the row/nonzero counts come from `ne` and the list contents.
pub fn ASSC_setMatrix(
    _nv: i32,
    ne: i32,
    nz: i32,
    adj: Array<Arc<List<i32>>>,
    val: Array<Arc<List<i32>>>,
) {
    let mut m = AsscMatrix {
        ne,
        col_ptrs: Vec::with_capacity(ne as usize + 1),
        col_ids: Vec::with_capacity(nz as usize),
        col_val: Vec::with_capacity(nz as usize),
        rows: Vec::with_capacity(ne as usize),
    };
    m.col_ptrs.push(0);
    let adj = adj.borrow();
    let val = val.borrow();
    for i in 0..ne as usize {
        let mut row = Vec::new();
        // Like the C loop, walk both lists in lockstep, stopping at the
        // shorter one.
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

/// `ASSC_freeMatrix()`: drop the stored matrix.
pub fn ASSC_freeMatrix() {
    ASSC_MATRIX.with(|s| *s.borrow_mut() = None);
}

/// `ASSC_printMatrix()`: print the stored matrix to stdout in the same two
/// formats as the C implementation (CSR triplets per row, then the per-row
/// `(index: value)` element lists).
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

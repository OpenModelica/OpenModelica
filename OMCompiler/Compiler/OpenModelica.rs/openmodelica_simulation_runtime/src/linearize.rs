//! `-l`'s C half: the four `analyticJacobians[INDEX_JAC_{A,B,C,D}]` C's
//! `linearization/linearize.cpp` drives, handed to the shared implementation
//! through the flat window [`Layout::linz_off`] describes.

use core::ffi::c_int;
use core::sync::atomic::{AtomicU8, Ordering};

use openmodelica_sim_meta::{Layout, LinInfo, LinLanguage, LinVar, Neg};

use crate::abi::*;

/// `A`,`B`,`C`,`D` as `(rows, cols)`. C takes these from `modelData` rather than
/// from the Jacobians, which lets the layout size the window before any of them is
/// initialized.
fn shapes(md: &MODEL_DATA) -> ([u32; 4], [u32; 4]) {
    let (x, u, y) = (md.nStates as u32, md.nInputVars as u32, md.nOutputVars as u32);
    ([x, x, y, y], [x, u, x, u])
}

fn jac_off(layout: &Layout, md: &MODEL_DATA, k: usize) -> u32 {
    let (rows, cols) = shapes(md);
    layout.linz_off + (0..k).map(|j| rows[j] * cols[j] * 8).sum::<u32>()
}

/// [`Layout::n_linz`]. Zero unless `-l` asked: C allocates the matrices inside
/// `linearize` alone.
pub fn words(md: &MODEL_DATA) -> u32 {
    if !openmodelica_sim_meta::simflags::with_flags(|f| f.linearize.is_some()) {
        return 0;
    }
    let (rows, cols) = shapes(md);
    (0..4).map(|k| rows[k] * cols[k]).sum()
}

/// Which matrices have a symbolic Jacobian, in `A`,`B`,`C`,`D` order.
static SYM_MASK: AtomicU8 = AtomicU8::new(0);

/// `initialAnalyticJacobian{B,C,D}`. C runs them inside `linearize`; the shared
/// implementation asks which matrices are symbolic before the run, so they run
/// here. `A`'s ran in `data::init_jac_a`, and C reads its `sizeTmpVars` rather
/// than a return code.
pub fn initialize(data: *mut DATA, thread_data: *mut threadData_t) {
    if words(unsafe { &*(*data).modelData }) == 0 {
        return;
    }
    let sym_a = crate::data::jac_a(data).is_some_and(|j| j.sizeTmpVars > 0);
    if !sym_a {
        return;
    }
    let cb = unsafe { &*(*data).callback };
    let mut mask = 1u8;
    let rest = [
        (cb.INDEX_JAC_B, cb.initialAnalyticJacobianB),
        (cb.INDEX_JAC_C, cb.initialAnalyticJacobianC),
        (cb.INDEX_JAC_D, cb.initialAnalyticJacobianD),
    ];
    for (k, (index, init)) in rest.into_iter().enumerate() {
        let Some(j) = jacobian(data, index) else { continue };
        let Some(init) = init else { continue };
        if unsafe { init(data, thread_data, j) } == 0 {
            mask |= 1 << (k + 1);
        }
    }
    SYM_MASK.store(mask, Ordering::Relaxed);
}

fn jacobian(data: *mut DATA, index: c_int) -> Option<*mut JACOBIAN> {
    let si = unsafe { (*data).simulationInfo.as_ref()? };
    (index >= 0 && !si.analyticJacobians.is_null())
        .then(|| unsafe { si.analyticJacobians.add(index as usize) })
}

pub fn index_of(name: &str) -> Option<usize> {
    ["linearJacA", "linearJacB", "linearJacC", "linearJacD"].iter().position(|&n| n == name)
}

/// C's `functionJacA` .. `functionJacD`.
pub fn eval(data: *mut DATA, thread_data: *mut threadData_t, k: usize, out: &mut Vec<f64>) {
    let cb = unsafe { &*(*data).callback };
    let (index, column) = match k {
        0 => (cb.INDEX_JAC_A, cb.functionJacA_column),
        1 => (cb.INDEX_JAC_B, cb.functionJacB_column),
        2 => (cb.INDEX_JAC_C, cb.functionJacC_column),
        _ => (cb.INDEX_JAC_D, cb.functionJacD_column),
    };
    let (Some(jac), Some(column)) = (jacobian(data, index), column) else { return };
    if let Some(f) = unsafe { (*jac).constantEqns } {
        unsafe { f(data, thread_data, jac, core::ptr::null_mut()) };
    }
    eval_columns(data, thread_data, jac, column, out);
}

/// Seed one column at a time and collect `resultVars`, column-major: C's
/// `functionJac<X>` and `getJacobianMatrix<X>` are both this loop. The model
/// writes through `jac`, so nothing here may hold a reference into it.
pub fn eval_columns(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    jac: *mut JACOBIAN,
    column: unsafe extern "C" fn(*mut DATA, *mut threadData_t, *mut JACOBIAN, *mut JACOBIAN) -> c_int,
    out: &mut Vec<f64>,
) {
    let (cols, rows) = unsafe { ((*jac).sizeCols, (*jac).sizeRows) };
    let (seeds, results) = unsafe { ((*jac).seedVars, (*jac).resultVars) };
    for i in 0..cols {
        unsafe { *seeds.add(i) = 1.0 };
        unsafe { column(data, thread_data, jac, core::ptr::null_mut()) };
        out.extend((0..rows).map(|r| unsafe { *results.add(r) }));
        unsafe { *seeds.add(i) = 0.0 };
    }
}

pub fn window(layout: &Layout, data: *mut DATA, k: usize) -> u32 {
    jac_off(layout, unsafe { &*(*data).modelData }, k)
}

/// `linear_model_frame()`, which prints its own diagnostic and returns `""` where
/// the code generator disabled linearization -- so it is asked at the point C
/// asks it, not baked into the metadata.
pub fn frame(data: *mut DATA, datarec: bool) -> String {
    let cb = unsafe { &*(*data).callback };
    let f = if datarec { cb.linear_model_datarecovery_frame } else { cb.linear_model_frame };
    match f {
        Some(f) => {
            let p = unsafe { f() };
            if p.is_null() {
                String::new()
            } else {
                unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
            }
        }
        None => String::new(),
    }
}

/// [`SimMeta::lin`]; the frames come from [`frame`] instead.
pub fn describe(data: *mut DATA, layout: &Layout) -> Option<LinInfo> {
    let md = unsafe { &*(*data).modelData };
    if words(md) == 0 {
        return None;
    }
    let (jac_rows, jac_cols) = shapes(md);
    // The flat mirrors of `simulationInfo->inputVars` / `outputVars`.
    let slots = |base: u32, n: u32| {
        (0..n).map(|i| LinVar { off: base + i * 8, negate: Neg::None }).collect()
    };
    let x = crate::data::extra(layout, md);
    Some(LinInfo {
        input_vars: slots(x.input_vars, md.nInputVars as u32),
        output_vars: slots(x.output_vars, md.nOutputVars as u32),
        language: match md.linearizationDumpLanguage {
            1 => LinLanguage::Matlab,
            2 => LinLanguage::Julia,
            3 => LinLanguage::Python,
            _ => LinLanguage::Modelica,
        },
        frame: String::new(),
        frame_datarec: String::new(),
        disabled_reason: String::new(),
        sym_mask: SYM_MASK.load(Ordering::Relaxed),
        run_testsuite: md.runTestsuite != 0,
        jac_rows,
        jac_cols,
    })
}

//! `-reconcile*`'s C half: the three variable lists `data_function` /
//! `setc_function` / `setb_function` copy between `simulationInfo` and the model,
//! and the `F`/`H` Jacobians `getJacobianMatrixF`/`H` assemble.

use core::ffi::{c_char, c_int};

use openmodelica_sim_meta::{Layout, Neg, ReconInfo, ReconJac, ReconVar};

use crate::abi::*;
use crate::model_data::cstr;

/// `(rows, cols)` of `F` and `H`, packed, from [`initialize`]: the layout needs
/// them before the driver starts.
static SHAPE: [core::sync::atomic::AtomicU64; 2] =
    [core::sync::atomic::AtomicU64::new(0), core::sync::atomic::AtomicU64::new(0)];

fn shape(k: usize) -> Option<(u32, u32)> {
    let v = SHAPE[k].load(core::sync::atomic::Ordering::Relaxed);
    (v != 0).then(|| ((v >> 32) as u32, v as u32))
}

pub fn jac_words() -> (u32, u32) {
    let n = |k| shape(k).map_or(0, |(r, c)| r * c);
    (n(0), n(1))
}

fn jacobian(data: *mut DATA, index: c_int) -> Option<*mut JACOBIAN> {
    let si = unsafe { (*data).simulationInfo.as_ref()? };
    (index >= 0 && !si.analyticJacobians.is_null())
        .then(|| unsafe { si.analyticJacobians.add(index as usize) })
}

/// Run both `initialAnalyticJacobian*` and record what they sized. C rebuilds and
/// frees them around every assembly; nothing else in a run touches these two, so
/// they stay allocated.
pub fn initialize(data: *mut DATA, thread_data: *mut threadData_t) {
    if !asked() {
        return;
    }
    let cb = unsafe { &*(*data).callback };
    for (k, (index, init)) in
        [(cb.INDEX_JAC_F, cb.initialAnalyticJacobianF), (cb.INDEX_JAC_H, cb.initialAnalyticJacobianH)]
            .into_iter()
            .enumerate()
    {
        let (Some(j), Some(init)) = (jacobian(data, index), init) else { continue };
        unsafe { init(data, thread_data, j) };
        let j = unsafe { &*j };
        if j.sizeCols > 0 && !j.seedVars.is_null() && !j.resultVars.is_null() {
            let v = ((j.sizeRows as u64) << 32) | j.sizeCols as u64;
            SHAPE[k].store(v, core::sync::atomic::Ordering::Relaxed);
        }
    }
}

fn asked() -> bool {
    openmodelica_sim_meta::simflags::with_flags(|f| f.reconcile || f.reconcile_boundary || f.reconcile_state)
}

pub fn index_of(name: &str) -> Option<usize> {
    ["reconJacF", "reconJacH"].iter().position(|&n| n == name)
}

/// C's `getJacobianMatrixF`/`H`.
pub fn eval(data: *mut DATA, thread_data: *mut threadData_t, k: usize, out: &mut Vec<f64>) {
    let cb = unsafe { &*(*data).callback };
    let (index, column) = match k {
        0 => (cb.INDEX_JAC_F, cb.functionJacF_column),
        _ => (cb.INDEX_JAC_H, cb.functionJacH_column),
    };
    let (Some(jac), Some(column)) = (jacobian(data, index), column) else { return };
    crate::linearize::eval_columns(data, thread_data, jac, column, out);
}

pub fn window(layout: &Layout, data: *mut DATA, k: usize) -> u32 {
    let x = crate::data::extra(layout, unsafe { &*(*data).modelData });
    if k == 0 { x.recon_jac_f } else { x.recon_jac_h }
}

/// The names one of the two `char**` callbacks fills into `n` caller-owned slots.
fn names(
    data: *mut DATA,
    n: usize,
    f: Option<unsafe extern "C" fn(*mut DATA, *mut *mut c_char) -> c_int>,
) -> Vec<String> {
    let Some(f) = f else { return vec![String::new(); n] };
    let mut buf: Vec<*mut c_char> = vec![core::ptr::null_mut(); n.max(1)];
    unsafe { f(data, buf.as_mut_ptr()) };
    buf.iter().take(n).map(|&p| cstr(p)).collect()
}

/// C's report lookup: the `displayUnit` and comment of the real variable of that
/// name.
fn attrs(md: &MODEL_DATA, name: &str) -> (String, String) {
    for i in 0..md.nVariablesReal.max(0) as usize {
        let v = unsafe { &*md.realVarsData.add(i) };
        if cstr(v.info.name) == name {
            return (crate::model_data::string_value(v.attribute.displayUnit), cstr(v.info.comment));
        }
    }
    (String::new(), String::new())
}

/// [`SimMeta::recon`]. The `setc` set is only counted and read, so C names it
/// nowhere and neither does this.
pub fn describe(data: *mut DATA, layout: &Layout, version: &str) -> Option<ReconInfo> {
    if !asked() {
        return None;
    }
    let md = unsafe { &*(*data).modelData };
    let cb = unsafe { &*(*data).callback };
    let x = crate::data::extra(layout, md);
    let n = |v: core::ffi::c_long| v.max(0) as usize;
    let named = |base: u32, names: Vec<String>| -> Vec<ReconVar> {
        names
            .into_iter()
            .enumerate()
            .map(|(i, name)| {
                let (unit, comment) = attrs(md, &name);
                ReconVar { off: base + (i as u32) * 8, negate: Neg::None, name, unit, comment }
            })
            .collect()
    };
    let plain = |base: u32, count: usize| -> Vec<ReconVar> {
        (0..count as u32)
            .map(|i| ReconVar { off: base + i * 8, negate: Neg::None, ..Default::default() })
            .collect()
    };
    let jac = |k: usize| shape(k).map(|(rows, cols)| ReconJac { rows, cols, off: window(layout, data, k) });
    Some(ReconInfo {
        input_vars: named(x.recon_in, names(data, n(md.ndataReconVars), cb.dataReconciliationInputNames)),
        setc_vars: plain(x.recon_setc, n(md.nSetcVars)),
        setb_vars: named(
            x.recon_setb,
            names(data, n(md.nSetbVars), cb.dataReconciliationUnmeasuredVariables),
        ),
        jac_f: jac(0),
        jac_h: jac(1),
        n_related_boundary: md.nRelatedBoundaryConditions.max(0) as u32,
        model_file: cstr(md.modelFileName),
        model_dir: cstr(md.modelDir),
        version: version.to_string(),
    })
}

//! `method="optimization"`'s C half: the objective terms, the input variables, the
//! time grid and the three symbolic Jacobians the collocation solver
//! differentiates through, all as `data->callback` already states them.

use core::ffi::{c_int, c_void};

use openmodelica_sim_meta::{Layout, OptInfo, OptJac, OptTerm};

use crate::abi::*;
use crate::model_data::cstr;

fn indices(cb: &OpenModelicaGeneratedFunctionCallbacks) -> [c_int; 3] {
    [cb.INDEX_JAC_B, cb.INDEX_JAC_C, cb.INDEX_JAC_D]
}

fn jacobian(data: *mut DATA, index: c_int) -> Option<*mut JACOBIAN> {
    let si = unsafe { (*data).simulationInfo.as_ref()? };
    (index >= 0 && !si.analyticJacobians.is_null())
        .then(|| unsafe { si.analyticJacobians.add(index as usize) })
}

/// C's `solver_main`'s choice: `-s` over the init XML's `method`. Nothing below may
/// be asked of a model translated without `+gDynOpt` -- its generated
/// `mayer`/`lagrange` *throw* rather than reporting an absent term.
fn asked(data: *mut DATA) -> bool {
    use openmodelica_sim_meta::simflags::Solver;
    match openmodelica_sim_meta::simflags::with_flags(|f| f.solver) {
        Some(s) => s == Solver::Optimization,
        None => {
            let m = unsafe { (*(*data).simulationInfo).solverMethod };
            !m.is_null() && cstr(m) == "optimization"
        }
    }
}

/// Whether this is an optimization run, from [`initialize`]. The layout is built
/// before the metadata, and `data::extra` cannot re-ask [`asked`] without the
/// `DATA` it does not have.
static ASKED: core::sync::atomic::AtomicBool = core::sync::atomic::AtomicBool::new(false);

pub fn is_optimization() -> bool {
    ASKED.load(core::sync::atomic::Ordering::Relaxed)
}

/// [`Layout::n_opt_attr`]: one `min`/`max`/`nominal`/`useNominal` per real
/// variable, which only the optimizer reads.
pub fn n_attrs(md: &MODEL_DATA) -> u32 {
    match is_optimization() {
        true => md.nVariablesReal.max(0) as u32,
        false => 0,
    }
}

/// Seeds then results of each matrix, as the window holds them.
pub fn opt_jac_words() -> [u32; 3] {
    core::array::from_fn(|k| WORDS[k].load(core::sync::atomic::Ordering::Relaxed))
}

static WORDS: [core::sync::atomic::AtomicU32; 3] = [
    core::sync::atomic::AtomicU32::new(0),
    core::sync::atomic::AtomicU32::new(0),
    core::sync::atomic::AtomicU32::new(0),
];

fn measure(data: *mut DATA) -> [u32; 3] {
    let cb = unsafe { &*(*data).callback };
    let mut out = [0u32; 3];
    for (k, index) in indices(cb).into_iter().enumerate() {
        if let Some(j) = jacobian(data, index) {
            let j = unsafe { &*j };
            if !j.seedVars.is_null() && !j.resultVars.is_null() {
                out[k] = (j.sizeCols + j.sizeRows) as u32;
            }
        }
    }
    out
}

/// `initialAnalyticJacobian{B,C,D}`, which C runs at optimizer setup
/// (`DerStructure.c`); the layout needs the shapes before that.
pub fn initialize(data: *mut DATA, thread_data: *mut threadData_t) {
    if !asked(data) {
        return;
    }
    let cb = unsafe { &*(*data).callback };
    let inits = [cb.initialAnalyticJacobianB, cb.initialAnalyticJacobianC, cb.initialAnalyticJacobianD];
    for (index, init) in indices(cb).into_iter().zip(inits) {
        let (Some(j), Some(init)) = (jacobian(data, index), init) else { continue };
        unsafe { init(data, thread_data, j) };
    }
    for (slot, w) in WORDS.iter().zip(measure(data)) {
        slot.store(w, core::sync::atomic::Ordering::Relaxed);
    }
    ASKED.store(true, core::sync::atomic::Ordering::Relaxed);
}

/// The names `Model::eval_jac_colored` calls each matrix by.
const COLUMN_FNS: [&str; 3] = ["optJacB_column", "optJacC_column", "optJacD_column"];
const CONST_FNS: [&str; 3] =
    ["optJacB_constantEqns", "optJacC_constantEqns", "optJacD_constantEqns"];

/// Which matrix `name` asks for, and whether it wants the constant equations.
pub fn index_of(name: &str) -> Option<(usize, bool)> {
    if let Some(k) = COLUMN_FNS.iter().position(|&n| n == name) {
        return Some((k, false));
    }
    CONST_FNS.iter().position(|&n| n == name).map(|k| (k, true))
}

/// One column of matrix `k`, or its seed-independent equations. The shared code
/// wrote the seeds through the window, so there is no seeding loop here.
pub fn eval(data: *mut DATA, thread_data: *mut threadData_t, k: usize, constant: bool) {
    let cb = unsafe { &*(*data).callback };
    let columns = [cb.functionJacB_column, cb.functionJacC_column, cb.functionJacD_column];
    let Some(jac) = jacobian(data, indices(cb)[k]) else { return };
    let f = match constant {
        true => unsafe { (*jac).constantEqns },
        false => columns[k],
    };
    let Some(f) = f else { return };
    unsafe { f(data, thread_data, jac, core::ptr::null_mut()) };
}

/// C's `dim->index_mayer` / `index_lagrange`. The callback hands back a pointer
/// *into* `realVars`, so the index is the offset, as `DerStructure.c` takes it;
/// `index_Dres`/`index_DresB`/`index_DresC` are the Jacobian rows.
fn term(data: *mut DATA, lagrange: bool) -> Option<OptTerm> {
    let cb = unsafe { &*(*data).callback };
    let base = unsafe { (*(*data).localData).as_ref()?.realVars };
    let mut res: *mut modelica_real = core::ptr::null_mut();
    let (mut b, mut c) = (-1i16, -1i16);
    let ok = match lagrange {
        true => cb.lagrange.map(|f| unsafe { f(data, &mut res, &mut b, &mut c) }),
        false => cb.mayer.map(|f| unsafe { f(data, &mut res, &mut c) }),
    };
    if ok? < 0 || res.is_null() || base.is_null() {
        return None;
    }
    let index = (unsafe { res.offset_from(base) }).try_into().ok()?;
    let row = |v: i16| (v >= 0).then_some(v as u32);
    Some(OptTerm { index, row_b: row(b), row_c: row(c) })
}

/// C's `getTimeGrid`, which names the `isTimeGrid` parameters by index.
fn tgrid(data: *mut DATA, layout: &Layout) -> Vec<u32> {
    let Some(f) = (unsafe { (*(*data).callback).getTimeGrid }) else { return Vec::new() };
    let mut n: modelica_integer = -1;
    let mut idx: *mut modelica_integer = core::ptr::null_mut();
    unsafe { f(data, &mut n, &mut idx) };
    if n <= 0 || idx.is_null() {
        if !idx.is_null() {
            unsafe { libc::free(idx as *mut libc::c_void) };
        }
        return Vec::new();
    }
    let out = (0..=n as usize)
        .map(|i| layout.rparam_off + (unsafe { *idx.add(i) } as u32) * 8)
        .collect();
    unsafe { libc::free(idx as *mut libc::c_void) };
    out
}

/// [`SimMeta::opt`]. `real_names` is in scalarized real-variable order.
pub fn describe(data: *mut DATA, layout: &Layout, real_names: Vec<String>) -> Option<OptInfo> {
    if !is_optimization() {
        return None;
    }
    let md = unsafe { &*(*data).modelData };
    let cb = unsafe { &*(*data).callback };
    let n_u = md.nInputVars.max(0) as usize;
    let mut idx = vec![0 as c_int; n_u.max(1)];
    let mut loop_idx = vec![-1 as c_int; n_u.max(1)];
    if let Some(f) = cb.getInputVarIndicesInOptimization {
        unsafe { f(data, idx.as_mut_ptr(), loop_idx.as_mut_ptr()) };
    }
    let inputs: Vec<u32> = idx[..n_u].iter().map(|&i| i.max(0) as u32).collect();
    let loop_inputs = (0..n_u)
        .filter(|&k| loop_idx[k] >= 0)
        .map(|k| (k as u32, loop_idx[k] as u32))
        .collect();
    Some(OptInfo {
        n_con: md.nOptimizeConstraints.max(0) as u32,
        n_final_con: md.nOptimizeFinalConstraints.max(0) as u32,
        inputs,
        loop_inputs,
        mayer: term(data, false),
        lagrange: term(data, true),
        real_names,
        tgrid: tgrid(data, layout),
        // The Optimica `startTime` class attribute would start a pre-simulation.
        // The code generator emits C's `startTime - 1.0` default and nothing else,
        // so there is no slot to name; the wasm codegen says `None` too.
        start_time_opt: None,
        jac_b: jac(data, layout, 0),
        jac_c: jac(data, layout, 1),
        jac_d: jac(data, layout, 2),
    })
}

/// The parts of `analyticJacobians[INDEX_JAC_<X>]` that
/// `diffSynColoredOptimizerSystem` reads.
fn jac(data: *mut DATA, layout: &Layout, k: usize) -> Option<OptJac> {
    let cb = unsafe { &*(*data).callback };
    let j = unsafe { &*jacobian(data, indices(cb)[k])? };
    if j.sizeCols == 0 || j.seedVars.is_null() || j.resultVars.is_null() {
        return None;
    }
    let (cols, rows) = (j.sizeCols as u32, j.sizeRows as u32);
    let sp = unsafe { j.sparsePattern.as_ref()? };
    if sp.maxColors == 0 {
        return None;
    }
    let rows_by_col: Vec<Vec<u32>> = (0..cols as usize)
        .map(|c| {
            let from = unsafe { *sp.leadindex.add(c) } as usize;
            let to = unsafe { *sp.leadindex.add(c + 1) } as usize;
            (from..to).map(|i| unsafe { *sp.index.add(i) }).collect()
        })
        .collect();
    let mut colors = vec![Vec::new(); sp.maxColors as usize];
    for c in 0..cols as usize {
        let col = unsafe { *sp.colorCols.add(c) } as usize;
        if col == 0 || col > colors.len() {
            return None;
        }
        colors[col - 1].push(c as u32);
    }
    let base = crate::data::extra(layout, unsafe { &*(*data).modelData }).opt_jac[k];
    Some(OptJac {
        n_cols: cols,
        n_rows: rows,
        colors,
        rows_by_col,
        seed_offs: (0..cols).map(|c| base + c * 8).collect(),
        result_offs: (0..rows).map(|r| base + (cols + r) * 8).collect(),
        column_fn: COLUMN_FNS[k].to_string(),
        const_fn: match j.constantEqns.is_some() {
            true => CONST_FNS[k].to_string(),
            false => String::new(),
        },
    })
}

/// The seed/result windows, for the region map.
pub fn regions(data: *mut DATA, layout: &Layout) -> Vec<(u32, u32, *mut c_void)> {
    let cb = unsafe { &*(*data).callback };
    let x = crate::data::extra(layout, unsafe { &*(*data).modelData });
    let mut out = Vec::new();
    for (k, index) in indices(cb).into_iter().enumerate() {
        let Some(j) = jacobian(data, index) else { continue };
        let j = unsafe { &*j };
        if j.seedVars.is_null() || j.resultVars.is_null() {
            continue;
        }
        let base = x.opt_jac[k];
        out.push((base, j.sizeCols as u32 * 8, j.seedVars as *mut c_void));
        out.push((base + j.sizeCols as u32 * 8, j.sizeRows as u32 * 8, j.resultVars as *mut c_void));
    }
    out
}

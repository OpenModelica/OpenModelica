//! Dynamic state selection: the `STATE_SET_DATA` side of the shared driver's
//! `$STATESET` handling.
//!
//! The pivoting itself (C's `pivot.c`, `comparePivot`, `setAMatrix`) is the
//! driver's, and it addresses everything through flat offsets. This file is what
//! makes those offsets exist for a C model: the per-set Jacobian is initialized
//! here, its `seedVars`/`resultVars` are mapped into the flat address space, and
//! `functionStateSetJacobians` runs every set's column equations over them.

use openmodelica_sim_meta::{Layout, StateSetInfo};

use crate::abi::*;

/// `f64` slots one set adds to the flat layout: its Jacobian's seeds (one per
/// candidate) followed by its result rows (one per dummy state).
fn set_words(data: *mut DATA, i: usize) -> (usize, usize) {
    let si = unsafe { &*(*data).simulationInfo };
    let set = unsafe { &*si.stateSetData.add(i) };
    if set.jacobianIndex < 0 {
        return (0, 0);
    }
    let j = unsafe { &*si.analyticJacobians.add(set.jacobianIndex as usize) };
    (j.sizeCols, j.sizeRows)
}

/// Total of [`set_words`] over every set, which is `Layout`'s `n_stateset_f64`.
pub fn scratch_words(data: *mut DATA) -> u32 {
    let md = unsafe { &*(*data).modelData };
    (0..md.nStateSets.max(0) as usize)
        .map(|i| {
            let (c, r) = set_words(data, i);
            (c + r) as u32
        })
        .sum()
}

/// Where set `i`'s seeds and results start in the flat layout.
fn set_base(data: *mut DATA, layout: &Layout, i: usize) -> u32 {
    let mut off = layout.stateset_off;
    for k in 0..i {
        let (c, r) = set_words(data, k);
        off += ((c + r) * 8) as u32;
    }
    off
}

/// C's `initializeStateSetJacobians` + `initializeStateSetPivoting`: give every set
/// its analytic Jacobian, and start `A` at the selection the driver's own initial
/// pivot order describes (the identity, candidates `0..nStates`).
pub fn initialize_state_sets(data: *mut DATA, thread_data: *mut threadData_t) {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &mut *(*data).simulationInfo };
    for i in 0..md.nStateSets.max(0) as usize {
        let set = unsafe { &mut *si.stateSetData.add(i) };
        if set.jacobianIndex < 0 {
            crate::throw(thread_data, "can not initialze Jacobians for dynamic state selection");
        }
        let jacobian = unsafe { si.analyticJacobians.add(set.jacobianIndex as usize) };
        let failed = match set.initialAnalyticalJacobian {
            Some(f) => (unsafe { f(data, thread_data, jacobian) }) != 0,
            None => true,
        };
        if failed {
            crate::throw(thread_data, "can not initialze Jacobians for dynamic state selection");
        }

        // `initializeStateSetPivoting`'s `A`: zeroed, then 1 on the diagonal. The
        // driver's `init_state_pivots` starts from the matching pivot order, so the
        // two agree on the initial selection and it sees no change at the first step.
        let (nc, ns) = (set.nCandidates.max(0) as usize, set.nStates.max(0) as usize);
        let base = a_base(data, set);
        let a = unsafe { (**(*data).localData).integerVars };
        for k in 0..nc * ns {
            unsafe { *a.add(base + k) = 0 };
        }
        for n in 0..ns {
            unsafe { *a.add(base + n * nc + n) = 1 };
        }
    }
}

/// Scalar index of `$STATESET<i>.A[1,1]` in `integerVars`. C reaches it as
/// `A->id - integerVarsData[0].info.id`; the array index the `VAR_INFO` belongs to
/// is exact where that arithmetic assumes scalarized variables.
fn a_base(data: *mut DATA, set: &STATE_SET_DATA) -> usize {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    let a = array_index(set.A, md.integerVarsData.cast(), core::mem::size_of::<STATIC_INTEGER_DATA>());
    unsafe { *si.integerVarsIndex.add(a) }
}

/// The array a `VAR_INFO*` belongs to: the generated `initializeStateSets` takes
/// every one as `&modelData-><group>Data[k].info`, so the offset from the group's
/// base divided by its stride is `k`.
fn array_index(info: *mut VAR_INFO, base: *const u8, stride: usize) -> usize {
    let off = info as usize - base as usize;
    off / stride
}

/// The flat offset of the real variable a candidate or state `VAR_INFO*` names.
fn real_off(data: *mut DATA, info: *mut VAR_INFO) -> u32 {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    let a = array_index(info, md.realVarsData.cast(), core::mem::size_of::<STATIC_REAL_DATA>());
    openmodelica_sim_meta::REAL_OFF + (unsafe { *si.realVarsIndex.add(a) } * 8) as u32
}

/// The [`StateSetInfo`] list the driver selects states from.
pub fn describe(data: *mut DATA, layout: &Layout) -> Vec<StateSetInfo> {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    let mut out = Vec::new();
    for i in 0..md.nStateSets.max(0) as usize {
        let set = unsafe { &*si.stateSetData.add(i) };
        let (nc, ns, nd) = (
            set.nCandidates.max(0) as usize,
            set.nStates.max(0) as usize,
            set.nDummyStates.max(0) as usize,
        );
        let (n_seed, n_res) = set_words(data, i);
        let base = set_base(data, layout, i);
        let a0 = a_base(data, set);
        out.push(StateSetInfo {
            n_candidates: nc as u32,
            n_states: ns as u32,
            n_dummy: nd as u32,
            candidate_offs: (0..nc)
                .map(|k| real_off(data, unsafe { *set.statescandidates.add(k) }))
                .collect(),
            state_offs: (0..ns).map(|k| real_off(data, unsafe { *set.states.add(k) })).collect(),
            a_offs: (0..ns * nc).map(|k| layout.int_off + ((a0 + k) * 4) as u32).collect(),
            seed_offs: (0..n_seed.min(nc)).map(|k| base + (k * 8) as u32).collect(),
            result_offs: (0..n_res.min(nd)).map(|k| base + ((n_seed + k) * 8) as u32).collect(),
            candidate_names: (0..nc)
                .map(|k| unsafe { cstr((**set.statescandidates.add(k)).name) })
                .collect(),
        });
    }
    out
}

fn cstr(p: *const core::ffi::c_char) -> String {
    if p.is_null() {
        return String::new();
    }
    unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
}

/// The flat region each set's seeds and results occupy, for the region map:
/// `(offset, bytes, native base)` twice per set.
pub fn regions(data: *mut DATA, layout: &Layout) -> Vec<(u32, u32, *mut core::ffi::c_void)> {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    let mut out = Vec::new();
    for i in 0..md.nStateSets.max(0) as usize {
        let set = unsafe { &*si.stateSetData.add(i) };
        if set.jacobianIndex < 0 {
            continue;
        }
        let j = unsafe { &*si.analyticJacobians.add(set.jacobianIndex as usize) };
        let (n_seed, n_res) = (j.sizeCols, j.sizeRows);
        let base = set_base(data, layout, i);
        out.push((base, (n_seed * 8) as u32, j.seedVars.cast()));
        out.push((base + (n_seed * 8) as u32, (n_res * 8) as u32, j.resultVars.cast()));
    }
    out
}

/// The model entry point the driver names once per Jacobian column: C has one
/// `analyticalJacobianColumn` per set rather than a single function, so run them
/// all. The sets the driver did not seed contribute zero columns, which is what
/// the wasm-jit codegen's single `functionStateSetJacobians` does too.
pub fn eval_jacobians(data: *mut DATA, thread_data: *mut threadData_t) -> Result<(), &'static str> {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    for i in 0..md.nStateSets.max(0) as usize {
        let set = unsafe { &*si.stateSetData.add(i) };
        if set.jacobianIndex < 0 {
            continue;
        }
        let jacobian = unsafe { si.analyticJacobians.add(set.jacobianIndex as usize) };
        let j = unsafe { &*jacobian };
        let stage = crate::support::error_stage::SIMULATION;
        if let Some(f) = j.constantEqns
            && !crate::support::protected(thread_data, stage, || {
                unsafe { f(data, thread_data, jacobian, core::ptr::null_mut()) };
            })
        {
            return Err(crate::systems::MODEL_THREW);
        }
        let Some(f) = j.evalColumn else {
            return Err("a state set's Jacobian has no column evaluation");
        };
        if !crate::support::protected(thread_data, stage, || {
            unsafe { f(data, thread_data, jacobian, core::ptr::null_mut()) };
        }) {
            return Err(crate::systems::MODEL_THREW);
        }
    }
    Ok(())
}

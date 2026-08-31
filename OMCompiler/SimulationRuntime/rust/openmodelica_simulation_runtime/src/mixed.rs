//! Mixed systems: `initializeMixedSystems`, `solve_mixed_system` and
//! `check_mixed_solutions`.
//!
//! Port of `mixedSystem.c` + `mixedSearchSolver.c`. A mixed system's continuous
//! part is an ordinary (non)linear system the generated `solveContinuousPart`
//! solves; what is left here is C's search over the Boolean iteration variables:
//! solve, read them back, and if they moved try the next combination of flips
//! against their `pre` values.

use core::ffi::{c_int, c_void};

use openmodelica_solvers::omclog;

use crate::abi::*;

/// `enum MIXED_SOLVER` (util/simulation_options.h): the only one C implements.
const MIXED_SEARCH: c_int = 1;

unsafe extern "C" {
    fn omr_protected_call_data(
        f: unsafe extern "C" fn(*mut c_void),
        data: *mut c_void,
        thread_data: *mut threadData_t,
        stage: c_int,
    ) -> c_int;
}

/// C's `DATA_SEARCHMIXED_SOLVER`.
struct Search {
    /// The iteration variables before and after one continuous solve.
    before: Vec<modelica_boolean>,
    after: Vec<modelica_boolean>,
    /// Which of them the search currently flips relative to their `pre` values.
    state: Vec<bool>,
}

/// C's `nextVar`: the next combination of flips, in order of increasing weight
/// (`000, 100, 010, 001, 110, 101, 011, 111`). False once every one has been tried.
fn next_var(b: &mut [bool]) -> bool {
    let n = b.len();
    let ones = b.iter().filter(|v| **v).count();
    if ones == n {
        return false;
    }
    let last = b.iter().rposition(|v| *v);
    match last {
        None => {
            b[0] = true;
            true
        }
        Some(k) if k < n - 1 => {
            b[k] = false;
            b[k + 1] = true;
            true
        }
        Some(_) => {
            // The tail is all ones: move the last `10` one place right and reset
            // the ones behind it to the front of what follows.
            let mut ip = n as isize - 2;
            let mut nr1 = 1usize;
            while ip >= 0 {
                if b[ip as usize] && !b[ip as usize + 1] {
                    nr1 += 1;
                    break;
                } else if b[ip as usize] {
                    nr1 += 1;
                    ip -= 1;
                } else {
                    ip -= 1;
                }
            }
            if ip < 0 {
                // Only ones at the end: start the next weight class.
                b.iter_mut().for_each(|v| *v = false);
                for v in b.iter_mut().take(nr1 + 1) {
                    *v = true;
                }
                return true;
            }
            let ip = ip as usize;
            for v in b.iter_mut().skip(ip) {
                *v = false;
            }
            for v in b.iter_mut().skip(ip + 1).take(nr1) {
                *v = true;
            }
            true
        }
    }
}

/// C's `initializeMixedSystems`. The `iterationVarsPtr` / `iterationPreVarsPtr`
/// arrays are the model's to fill (`initialMixedSystem`); only the search's own
/// scratch is allocated here.
pub fn initialize_mixed_systems(data: *mut DATA, thread_data: *mut threadData_t) {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &mut *(*data).simulationInfo };
    if md.nMixedSystems == 0 {
        return;
    }
    if si.mixedMethod != MIXED_SEARCH {
        crate::throw(thread_data, "unrecognized mixed solver");
    }
    omclog::info(omclog::MIXED, true, "initialize mixed system solvers");
    omclog::info(omclog::MIXED, false, &format!("{} mixed systems", md.nMixedSystems));
    for i in 0..md.nMixedSystems as usize {
        let sys = unsafe { &mut *si.mixedSystemData.add(i) };
        let size = sys.size.max(0) as usize;
        sys.iterationVarsPtr = crate::model_data::calloc(size.max(1));
        sys.iterationPreVarsPtr = crate::model_data::calloc(size.max(1));
        sys.solved = 1;
        sys.solverData = Box::into_raw(Box::new(Search {
            before: vec![0; size],
            after: vec![0; size],
            state: vec![false; size],
        })) as *mut c_void;
    }
    omclog::close(omclog::MIXED);
}

/// C's `solve_mixed_system` over `solveMixedSearch`. Always returns 0, as C's
/// does; `check_mixed_solutions` is what reports a failure.
#[unsafe(no_mangle)]
pub extern "C" fn solve_mixed_system(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    sys_number: c_int,
) -> c_int {
    let si = unsafe { &mut *(*data).simulationInfo };
    let sys = unsafe { &mut *si.mixedSystemData.add(sys_number as usize) };
    if si.mixedMethod != MIXED_SEARCH {
        crate::throw(thread_data, "unrecognized mixed solver");
    }
    sys.solved = solve_mixed_search(data, thread_data, sys_number) as modelica_boolean;
    0
}

fn solve_mixed_search(
    data: *mut DATA,
    thread_data: *mut threadData_t,
    sys_number: c_int,
) -> bool {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &mut *(*data).simulationInfo };
    let sys = unsafe { &mut *si.mixedSystemData.add(sys_number as usize) };
    let size = sys.size.max(0) as usize;
    let sd: &mut Search = unsafe { &mut *(sys.solverData as *mut Search) };
    let time = unsafe { (**(*data).localData).timeValue };
    let n_rel = md.nRelations.max(0) as usize;

    omclog::info(
        omclog::MIXED,
        true,
        &format!("\n####  Start solver mixed equation system at time {time}."),
    );
    // C's `memset(stateofSearch, 0, systemData->size)` clears `size` *bytes* of a
    // `modelica_boolean` (an `int`) array, so its flip mask starts partly
    // uninitialised. This clears the whole thing, which is a deliberate divergence:
    // the mask decides which combination the search tries next, and there is no
    // faithful way to reproduce reading uninitialised memory.
    sd.state.iter_mut().for_each(|v| *v = false);
    // C's `iterationVarsPre`: the values the search flips against, read once.
    let pre: Vec<modelica_boolean> =
        (0..size).map(|i| unsafe { **sys.iterationVarsPtr.add(i) }).collect();

    let mut iterations = 0;
    let mut success = false;
    loop {
        for i in 0..size {
            sd.before[i] = unsafe { **sys.iterationVarsPtr.add(i) };
        }
        let mut failed = false;
        for f in [sys.solveContinuousPart, sys.updateIterationExps] {
            let Some(f) = f else { continue };
            let rc = unsafe {
                omr_protected_call_data(
                    f,
                    data as *mut c_void,
                    thread_data,
                    crate::support::error_stage::NONLINEARSOLVER,
                )
            };
            failed |= rc == -1;
        }
        for i in 0..size {
            sd.after[i] = unsafe { **sys.iterationVarsPtr.add(i) };
        }
        let mut found: i32 = sys.continuous_solution as i32;

        // C's restart on a changed relation: the discrete state has not settled.
        if relations_changed(si, n_rel) {
            update_relations_pre(si, n_rel);
            if let Some(f) = sys.updateIterationExps {
                unsafe {
                    omr_protected_call_data(
                        f,
                        data as *mut c_void,
                        thread_data,
                        crate::support::error_stage::NONLINEARSOLVER,
                    )
                };
            }
            iterations += 1;
            if iterations > 200 {
                found = -4;
            }
        }

        if found == -1 || failed {
            found = -2;
        } else {
            found = 1;
            for i in 0..size {
                if sd.before[i] != sd.after[i] {
                    found = 0;
                    break;
                }
            }
        }

        if found == 0 {
            if next_var(&mut sd.state) {
                for i in 0..size {
                    unsafe { **sys.iterationVarsPtr.add(i) = ((pre[i] != 0) != sd.state[i]) as modelica_boolean };
                }
            } else {
                if si.initial == 0 {
                    omclog::warning(
                        omclog::STDOUT,
                        false,
                        &format!(
                            "Error solving mixed equation system with index {} at time {}",
                            sys.equationIndex,
                            openmodelica_sim_meta::driver::format_e(time)
                        ),
                    );
                }
                si.needToIterate = 1;
                found = -1;
            }
        }
        if found == 1 {
            success = true;
        }
        iterations += 1;
        if found != 0 {
            break;
        }
    }
    omclog::close(omclog::MIXED);
    success
}

/// C's `checkRelations`: whether any relation moved since the last `pre` copy.
fn relations_changed(si: &SIMULATION_INFO, n: usize) -> bool {
    (0..n).any(|i| unsafe { *si.relationsPre.add(i) != *si.relations.add(i) })
}

/// C's `updateRelationsPre`.
fn update_relations_pre(si: &SIMULATION_INFO, n: usize) {
    unsafe { core::ptr::copy_nonoverlapping(si.relations, si.relationsPre, n) };
}

/// C's `check_mixed_solutions`.
#[unsafe(no_mangle)]
pub extern "C" fn check_mixed_solutions(data: *mut DATA, print: c_int) -> c_int {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    let mut ret = 0;
    for i in 0..md.nMixedSystems as usize {
        let sys = unsafe { &*si.mixedSystemData.add(i) };
        if sys.solved == 0 {
            ret = 1;
            if print != 0 {
                let time = unsafe { (**(*data).localData).timeValue };
                omclog::warning(
                    omclog::MIXED,
                    false,
                    &format!(
                        "mixed system fails: {} at t={}",
                        sys.equationIndex,
                        openmodelica_sim_meta::driver::format_g(time, 6)
                    ),
                );
            }
        }
    }
    ret
}

//! The FMI 3.0 interface as **core exports**, for a host that links this module
//! rather than instantiating a component.
//!
//! A component is compiled as one artifact, so the ~1 MB of adapter, libc and
//! runtime inside it is compiled again for every model — 0.3 s of a small
//! model's 0.4 s export. Linked as a dylink library instead, the adapter is
//! *fixed*: the host compiles it once and keeps the `.cwasm` under
//! `~/.openmodelica/cache`, as it already does for the simulation runtime and the
//! `external "C"` libraries.
//!
//! The entry points follow the standard's names and argument order under an
//! `om_` prefix, with every pointer an offset into this module's linear memory —
//! which is the host's too, since the model, the adapter and the runtime share
//! one. There is no `fmi3Instance` argument and no callbacks: a host links this
//! module per run, and the log goes to stdout, where the `-lv` streams already go
//! and where the host already reads them.

use alloc::string::String;
use alloc::vec::Vec;

// The lifecycle and variable access are declared on both resources and given one
// body by `shared_instance_methods!`, so a call has to name which trait it goes
// through; either resolves to the same code.
use crate::exports::fmi::fmi3::co_simulation::GuestCoSimulationInstance;
use crate::exports::fmi::fmi3::model_exchange::GuestModelExchangeInstance;
use crate::{Instance, Status};

// ── The instance ────────────────────────────────────────────────────────────

static mut INSTANCE: Option<Instance> = None;

fn instance() -> Option<&'static Instance> {
    unsafe { (*core::ptr::addr_of!(INSTANCE)).as_ref() }
}

const OK: i32 = 0;
const ERROR: i32 = 3;

fn status(s: Status) -> i32 {
    match s {
        Status::Ok => 0,
        Status::Warning => 1,
        Status::Discard => 2,
        Status::Error => 3,
        Status::Fatal => 4,
    }
}

/// The status of a call on an instance that was never created.
fn with<R>(f: impl FnOnce(&Instance) -> R, absent: R) -> R {
    match instance() {
        Some(i) => f(i),
        None => absent,
    }
}

unsafe fn slice_u32<'a>(p: u32, n: u32) -> &'a [u32] {
    if n == 0 { &[] } else { unsafe { core::slice::from_raw_parts(p as *const u32, n as usize) } }
}

unsafe fn slice_f64<'a>(p: u32, n: u32) -> &'a [f64] {
    if n == 0 { &[] } else { unsafe { core::slice::from_raw_parts(p as *const f64, n as usize) } }
}

/// Copy `values` out to the caller's buffer, refusing a short one as the standard
/// requires (`nValues` must match what the variables need).
fn write_f64(p: u32, n: u32, values: &[f64]) -> i32 {
    if values.len() != n as usize {
        return ERROR;
    }
    unsafe { core::ptr::copy_nonoverlapping(values.as_ptr(), p as *mut f64, values.len()) };
    OK
}

fn write_i32(p: u32, n: u32, values: &[i32]) -> i32 {
    if values.len() != n as usize {
        return ERROR;
    }
    unsafe { core::ptr::copy_nonoverlapping(values.as_ptr(), p as *mut i32, values.len()) };
    OK
}

// ── Lifecycle ───────────────────────────────────────────────────────────────

/// `fmi3InstantiateModelExchange`. The name is a UTF-8 pointer/length pair
/// rather than a C string: the host has the length and this module has no
/// `strlen` of its own.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3InstantiateModelExchange(name: u32, name_len: u32, logging_on: i32) -> u32 {
    // The guest's own `instantiate_model_exchange` wraps the state in a component
    // resource, which would drag the resource intrinsics into a module nothing
    // instantiates as a component. Same steps, no wrapper.
    let name = read_str(name, name_len);
    crate::init_logging(name, logging_on != 0);
    openmodelica_codegen_wasm_jit_runtime::set_resources_dir("/");
    match crate::new_state() {
        Some(st) => {
            unsafe { INSTANCE = Some(Instance { st: core::cell::RefCell::new(st) }) };
            1
        }
        None => 0,
    }
}

/// `fmi3InstantiateCoSimulation`, with `eventModeUsed` and `earlyReturnAllowed`
/// both following `event_mode`: the master that drives one drives the other.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3InstantiateCoSimulation(
    name: u32,
    name_len: u32,
    logging_on: i32,
    event_mode: i32,
) -> u32 {
    let name = read_str(name, name_len);
    crate::init_logging(name, logging_on != 0);
    openmodelica_codegen_wasm_jit_runtime::set_resources_dir("/");
    match crate::new_state() {
        Some(mut st) => {
            st.defer = if event_mode != 0 {
                openmodelica_sim_meta::driver::CsDefer::Any
            } else {
                openmodelica_sim_meta::driver::CsDefer::None
            };
            // C's `fmi2Instantiate` sets the internal solver up here, CS only.
            openmodelica_sim_meta::driver::log_cs_solver_setup(&st.meta, st.defer);
            unsafe { INSTANCE = Some(Instance { st: core::cell::RefCell::new(st) }) };
            1
        }
        None => 0,
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3FreeInstance() {
    unsafe { INSTANCE = None };
}

fn read_str(p: u32, len: u32) -> String {
    if len == 0 {
        return String::new();
    }
    let bytes = unsafe { core::slice::from_raw_parts(p as *const u8, len as usize) };
    String::from_utf8_lossy(bytes).into_owned()
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3EnterInitializationMode(
    tolerance_defined: i32,
    tolerance: f64,
    start_time: f64,
    stop_time_defined: i32,
    stop_time: f64,
) -> i32 {
    with(
        |i| {
            status(GuestModelExchangeInstance::enter_initialization_mode(i, 
                (tolerance_defined != 0).then_some(tolerance),
                start_time,
                (stop_time_defined != 0).then_some(stop_time),
            ))
        },
        ERROR,
    )
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3ExitInitializationMode() -> i32 {
    with(|i| status(GuestModelExchangeInstance::exit_initialization_mode(i, )), ERROR)
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3EnterEventMode() -> i32 {
    with(|i| status(GuestModelExchangeInstance::enter_event_mode(i, )), ERROR)
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3EnterContinuousTimeMode() -> i32 {
    with(|i| status(i.enter_continuous_time_mode()), ERROR)
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3EnterConfigurationMode() -> i32 {
    with(|i| status(GuestModelExchangeInstance::enter_configuration_mode(i)), ERROR)
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3ExitConfigurationMode() -> i32 {
    with(|i| status(GuestModelExchangeInstance::exit_configuration_mode(i)), ERROR)
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3EnterStepMode() -> i32 {
    with(|i| status(GuestCoSimulationInstance::enter_step_mode(i)), ERROR)
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3Terminate() -> i32 {
    with(|i| status(GuestModelExchangeInstance::terminate(i, )), ERROR)
}

/// `fmi3UpdateDiscreteStates`. The five flags and the next event time are written
/// to `out`: `[needUpdate, terminate, nominalsChanged, statesChanged,
/// nextEventTimeDefined]` as `i32`, then the time as an `f64` at `out + 24`.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3UpdateDiscreteStates(out: u32) -> i32 {
    with(
        |i| match GuestModelExchangeInstance::update_discrete_states(i, ) {
            Ok(d) => {
                let flags = [
                    d.new_discrete_states_needed as i32,
                    d.terminate_simulation as i32,
                    d.nominals_of_continuous_states_changed as i32,
                    d.values_of_continuous_states_changed as i32,
                    d.next_event_time_defined as i32,
                ];
                unsafe {
                    core::ptr::copy_nonoverlapping(flags.as_ptr(), out as *mut i32, flags.len());
                    core::ptr::write_unaligned((out + 24) as *mut f64, d.next_event_time);
                }
                OK
            }
            Err(s) => status(s),
        },
        ERROR,
    )
}

// ── Model Exchange ──────────────────────────────────────────────────────────

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3SetTime(time: f64) -> i32 {
    with(|i| status(i.set_time(time)), ERROR)
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3SetContinuousStates(states: u32, n: u32) -> i32 {
    with(|i| status(i.set_continuous_states(unsafe { slice_f64(states, n) }.to_vec())), ERROR)
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3GetContinuousStates(states: u32, n: u32) -> i32 {
    with(
        |i| match i.get_continuous_states() {
            Ok(v) => write_f64(states, n, &v),
            Err(s) => status(s),
        },
        ERROR,
    )
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3GetContinuousStateDerivatives(ders: u32, n: u32) -> i32 {
    with(
        |i| match i.get_continuous_state_derivatives() {
            Ok(v) => write_f64(ders, n, &v),
            Err(s) => status(s),
        },
        ERROR,
    )
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3GetEventIndicators(z: u32, n: u32) -> i32 {
    with(
        |i| match i.get_event_indicators() {
            Ok(v) => write_f64(z, n, &v),
            Err(s) => status(s),
        },
        ERROR,
    )
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3GetNominalsOfContinuousStates(nominals: u32, n: u32) -> i32 {
    with(
        |i| match i.get_nominals_of_continuous_states() {
            Ok(v) => write_f64(nominals, n, &v),
            Err(s) => status(s),
        },
        ERROR,
    )
}

/// `[enterEventMode, terminateSimulation]` as `i32` at `out`.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3CompletedIntegratorStep(no_set_state_prior: i32, out: u32) -> i32 {
    with(
        |i| match i.completed_integrator_step(no_set_state_prior != 0) {
            Ok(r) => write_i32(out, 2, &[r.enter_event_mode as i32, r.terminate_simulation as i32]),
            Err(s) => status(s),
        },
        ERROR,
    )
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3GetNumberOfContinuousStates(out: u32) -> i32 {
    with(
        |i| match i.get_number_of_continuous_states() {
            Ok(n) => write_i32(out, 1, &[n as i32]),
            Err(s) => status(s),
        },
        ERROR,
    )
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3GetNumberOfEventIndicators(out: u32) -> i32 {
    with(
        |i| match i.get_number_of_event_indicators() {
            Ok(n) => write_i32(out, 1, &[n as i32]),
            Err(s) => status(s),
        },
        ERROR,
    )
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3GetDirectionalDerivative(
    unknowns: u32,
    n_unknowns: u32,
    knowns: u32,
    n_knowns: u32,
    seed: u32,
    n_seed: u32,
    sensitivity: u32,
    n_sensitivity: u32,
) -> i32 {
    with(
        |i| {
            let (u, k, s) = unsafe {
                (slice_u32(unknowns, n_unknowns).to_vec(), slice_u32(knowns, n_knowns).to_vec(), slice_f64(seed, n_seed).to_vec())
            };
            match GuestModelExchangeInstance::get_directional_derivative(i, u, k, s) {
                Ok(v) => write_f64(sensitivity, n_sensitivity, &v),
                Err(st) => status(st),
            }
        },
        ERROR,
    )
}

// ── Co-Simulation ───────────────────────────────────────────────────────────

/// `fmi3DoStep`. `[eventHandlingNeeded, terminate, earlyReturn]` as `i32` at
/// `out`, then `lastSuccessfulTime` as an `f64` at `out + 16`.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3DoStep(point: f64, size: f64, no_set_state_prior: i32, out: u32) -> i32 {
    with(
        |i| match i.do_step(point, size, no_set_state_prior != 0) {
            Ok(r) => {
                let flags =
                    [r.event_handling_needed as i32, r.terminate_simulation as i32, r.early_return as i32];
                unsafe {
                    core::ptr::copy_nonoverlapping(flags.as_ptr(), out as *mut i32, flags.len());
                    core::ptr::write_unaligned((out + 16) as *mut f64, r.last_successful_time);
                }
                OK
            }
            Err(s) => status(s),
        },
        ERROR,
    )
}

// ── Variable access ─────────────────────────────────────────────────────────
// One entry point per base type, as the standard has: the master reads and
// writes in the type the variable is declared with.

macro_rules! getter {
    ($name:ident, $call:ident, $ty:ty, $out:ty) => {
        #[unsafe(no_mangle)]
        pub extern "C" fn $name(vrs: u32, n_vrs: u32, values: u32, n_values: u32) -> i32 {
            with(
                |i| match GuestModelExchangeInstance::$call(i, unsafe { slice_u32(vrs, n_vrs) }.to_vec()) {
                    Ok(v) => {
                        if v.len() != n_values as usize {
                            return ERROR;
                        }
                        let buf: Vec<$out> = v.into_iter().map(|x| x as $out).collect();
                        unsafe {
                            core::ptr::copy_nonoverlapping(buf.as_ptr(), values as *mut $out, buf.len())
                        };
                        OK
                    }
                    Err(s) => status(s),
                },
                ERROR,
            )
        }
    };
}

macro_rules! setter {
    ($name:ident, $call:ident, $ty:ty, $wire:ty) => {
        #[unsafe(no_mangle)]
        pub extern "C" fn $name(vrs: u32, n_vrs: u32, values: u32, n_values: u32) -> i32 {
            with(
                |i| {
                    let vrs = unsafe { slice_u32(vrs, n_vrs) }.to_vec();
                    let src = if n_values == 0 {
                        &[][..]
                    } else {
                        unsafe { core::slice::from_raw_parts(values as *const $wire, n_values as usize) }
                    };
                    let v: Vec<$ty> = src.iter().map(|x| *x as $ty).collect();
                    status(GuestModelExchangeInstance::$call(i, vrs, v))
                },
                ERROR,
            )
        }
    };
}

getter!(om_fmi3GetFloat64, get_float64, f64, f64);
getter!(om_fmi3GetFloat32, get_float32, f32, f32);
getter!(om_fmi3GetInt8, get_int8, i8, i8);
getter!(om_fmi3GetUInt8, get_uint8, u8, u8);
getter!(om_fmi3GetInt16, get_int16, i16, i16);
getter!(om_fmi3GetUInt16, get_uint16, u16, u16);
getter!(om_fmi3GetInt32, get_int32, i32, i32);
getter!(om_fmi3GetUInt32, get_uint32, u32, u32);
getter!(om_fmi3GetInt64, get_int64, i64, i64);
getter!(om_fmi3GetUInt64, get_uint64, u64, u64);

setter!(om_fmi3SetFloat64, set_float64, f64, f64);
setter!(om_fmi3SetFloat32, set_float32, f32, f32);
setter!(om_fmi3SetInt8, set_int8, i8, i8);
setter!(om_fmi3SetUInt8, set_uint8, u8, u8);
setter!(om_fmi3SetInt16, set_int16, i16, i16);
setter!(om_fmi3SetUInt16, set_uint16, u16, u16);
setter!(om_fmi3SetInt32, set_int32, i32, i32);
setter!(om_fmi3SetUInt32, set_uint32, u32, u32);
setter!(om_fmi3SetInt64, set_int64, i64, i64);
setter!(om_fmi3SetUInt64, set_uint64, u64, u64);

/// Booleans cross as `i32`, since wasm has no narrower value type and the host
/// writes what the standard's `fmi3Boolean` is on this side.
#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3GetBoolean(vrs: u32, n_vrs: u32, values: u32, n_values: u32) -> i32 {
    with(
        |i| match GuestModelExchangeInstance::get_boolean(i, unsafe { slice_u32(vrs, n_vrs) }.to_vec()) {
            Ok(v) => {
                let buf: Vec<i32> = v.into_iter().map(|b| b as i32).collect();
                write_i32(values, n_values, &buf)
            }
            Err(s) => status(s),
        },
        ERROR,
    )
}

#[unsafe(no_mangle)]
pub extern "C" fn om_fmi3SetBoolean(vrs: u32, n_vrs: u32, values: u32, n_values: u32) -> i32 {
    with(
        |i| {
            let vrs = unsafe { slice_u32(vrs, n_vrs) }.to_vec();
            let src = if n_values == 0 {
                &[][..]
            } else {
                unsafe { core::slice::from_raw_parts(values as *const i32, n_values as usize) }
            };
            status(GuestModelExchangeInstance::set_boolean(i, vrs, src.iter().map(|b| *b != 0).collect()))
        },
        ERROR,
    )
}

// ── The model's own simulation runtime ───────────────────────────────────────

/// What [`om_sim_run`] hands back, in this module's memory. The host reads the
/// fields it wants and the buffers stay alive until the next call.
#[repr(C)]
#[derive(Default)]
struct RunOut {
    /// 0 on success; 1 with `file` holding the failure text.
    status: u32,
    file: u32,
    file_len: u32,
    lin_name: u32,
    lin_name_len: u32,
    lin_content: u32,
    lin_content_len: u32,
    rows: u32,
    solver: u32,
    solver_len: u32,
    /// `+profiling`'s files as a self-describing blob: per file a `u32` name
    /// length, the name, a `u32` content length, the content.
    prof: u32,
    prof_len: u32,
    /// The report asked for gnuplot + xsltproc (`+profiling=...+html`), which the
    /// host runs over the files above.
    prof_html: u32,
}

static mut RUN_OUT: RunOut = RunOut {
    status: 0,
    file: 0,
    file_len: 0,
    lin_name: 0,
    lin_name_len: 0,
    lin_content: 0,
    lin_content_len: 0,
    rows: 0,
    solver: 0,
    solver_len: 0,
    prof: 0,
    prof_len: 0,
    prof_html: 0,
};
static mut RUN_KEEP: Option<(Vec<u8>, String, String, String, Vec<u8>)> = None;

/// Serialize named files into the blob [`RunOut::prof`] describes.
fn pack_files(files: &[(String, Vec<u8>)]) -> Vec<u8> {
    let mut o = Vec::new();
    for (name, content) in files {
        o.extend_from_slice(&(name.len() as u32).to_le_bytes());
        o.extend_from_slice(name.as_bytes());
        o.extend_from_slice(&(content.len() as u32).to_le_bytes());
        o.extend_from_slice(content);
    }
    o
}

/// Run the whole simulation in-wasm, as `om:sim/simulation.run` does for a
/// component. `args` is the flag list as NUL-separated UTF-8, without the program
/// name. Returns a pointer to a [`RunOut`].
#[unsafe(no_mangle)]
pub extern "C" fn om_sim_run(args: u32, args_len: u32) -> u32 {
    let blob = if args_len == 0 {
        &[][..]
    } else {
        unsafe { core::slice::from_raw_parts(args as *const u8, args_len as usize) }
    };
    let argv: Vec<String> = blob
        .split(|b| *b == 0)
        .filter(|s| !s.is_empty())
        .map(|s| String::from_utf8_lossy(s).into_owned())
        .collect();
    let (out, keep) = match crate::sim_run::run(argv) {
        Ok(r) => {
            let (name, content) = r.linear_file.unwrap_or_default();
            let keep = (r.file, name, content, r.solver, pack_files(&r.prof_files));
            let mut out = RunOut { status: 0, rows: r.rows, ..RunOut::default() };
            out.file = keep.0.as_ptr() as u32;
            out.file_len = keep.0.len() as u32;
            out.lin_name = keep.1.as_ptr() as u32;
            out.lin_name_len = keep.1.len() as u32;
            out.lin_content = keep.2.as_ptr() as u32;
            out.lin_content_len = keep.2.len() as u32;
            out.solver = keep.3.as_ptr() as u32;
            out.solver_len = keep.3.len() as u32;
            out.prof = keep.4.as_ptr() as u32;
            out.prof_len = keep.4.len() as u32;
            out.prof_html = r.prof_html as u32;
            (out, keep)
        }
        Err(e) => {
            let keep = (e.into_bytes(), String::new(), String::new(), String::new(), Vec::new());
            let mut out = RunOut { status: 1, ..RunOut::default() };
            out.file = keep.0.as_ptr() as u32;
            out.file_len = keep.0.len() as u32;
            (out, keep)
        }
    };
    unsafe {
        RUN_KEEP = Some(keep);
        RUN_OUT = out;
        core::ptr::addr_of!(RUN_OUT) as u32
    }
}

//! The FMI 3.0 masters over an artifact the host links itself.
//!
//! [`super::artifact`]'s other backend instantiates a component; this one loads
//! the model kernel and the FMI3 adapter as dylink libraries sharing one linear
//! memory, and calls the adapter's `om_fmi3*` core exports. The adapter is then a
//! *fixed* library, compiled once into `~/.openmodelica/cache` instead of into
//! every model's component — which is what a small model's export was spending
//! almost all of its time on.
//!
//! Every array crosses through scratch this side allocates in the shared memory
//! (`rt_alloc`), which is what the FMI 3.0 C API's pointers are here.

use openmodelica_fmi_driver::api::{
    CompletedStep, DiscreteStates, DoStep, Fmi3, Fmi3CoSimulation, Fmi3ModelExchange,
};
use openmodelica_fmi_driver::{Error, Result};
use openmodelica_fmi::VarType;
use openmodelica_wasm_jit::sim_runtime::{ArtifactLib, DylinkFmu};
use wasmtime::Val;

/// What the artifact's own simulation runtime returned (`om_sim_run`).
pub struct SimRun {
    pub file: Vec<u8>,
    pub linear_file: Option<(String, String)>,
    /// `+profiling`'s report files, each as a name and its content.
    pub prof_files: Vec<(String, Vec<u8>)>,
    /// The report asked for gnuplot + xsltproc (`+profiling=...+html`).
    pub prof_html: bool,
    pub rows: u32,
    pub solver: String,
}

pub struct DylinkInstance {
    fmu: DylinkFmu,
    /// Scratch big enough for the widest array a call passes, grown as needed.
    scratch: (u32, u32),
}

fn err(call: &'static str, e: String) -> Error {
    Error::Load(format!("{call}: {e}"))
}

fn status(call: &'static str, raw: i32) -> Result<()> {
    openmodelica_fmi_driver::api::check(call, raw)
}

impl DylinkInstance {
    pub fn load(
        model: &[u8],
        ext: &[ArtifactLib],
        external_c: bool,
        lapack: bool,
        resources: &str,
    ) -> Result<DylinkInstance> {
        // One non-PIC module for the runtime, the driver and the adapter, so the
        // model and the driver share one runtime copy. `OMC_WASM_FUSED_ARTIFACT=0`
        // falls back to the dylink adapter.
        let fused = std::env::var("OMC_WASM_FUSED_ARTIFACT").as_deref() != Ok("0")
            && !openmodelica_wasm_jit::FMI3_FUSED_WASIP1.is_empty();
        let fmu = if fused {
            DylinkFmu::load_fused(model, ext, external_c, lapack, resources).map_err(Error::Load)?
        } else {
            DylinkFmu::load(
                openmodelica_wasm_jit::FMI3_MECS_CAPI_ADAPTER,
                model,
                ext,
                external_c,
                lapack,
                resources,
            )
            .map_err(Error::Load)?
        };
        Ok(DylinkInstance { fmu, scratch: (0, 0) })
    }

    /// Scratch of at least `bytes`, reused between calls.
    fn scratch(&mut self, bytes: u32) -> Result<u32> {
        if self.scratch.1 < bytes {
            let p = self.fmu.alloc(bytes.max(256)).map_err(|e| err("rt_alloc", e))?;
            self.scratch = (p, bytes.max(256));
        }
        Ok(self.scratch.0)
    }

    /// `vrs` and a values buffer, back to back in one scratch block.
    fn vrs_and_values(&mut self, vrs: &[u32], value_bytes: usize) -> Result<(u32, u32)> {
        let vr_bytes = vrs.len() * 4;
        let base = self.scratch((vr_bytes + value_bytes) as u32 + 16)?;
        let mut buf = Vec::with_capacity(vr_bytes);
        for v in vrs {
            buf.extend_from_slice(&v.to_le_bytes());
        }
        self.fmu.write(base, &buf).map_err(|e| err("artifact", e))?;
        Ok((base, base + vr_bytes as u32))
    }

    /// Drop the FMI instance, so the next `instantiate` starts from a clean model
    /// the way `fmi3FreeInstance` promises.
    pub fn free_instance(&mut self) {
        let _ = self.fmu.call_void("om_fmi3FreeInstance", &[]);
    }

    pub fn instantiate_me(&mut self, name: &str, logging_on: bool) -> Result<()> {
        let (p, n) = self.write_str(name)?;
        let ok = self
            .fmu
            .call("om_fmi3InstantiateModelExchange", &[Val::I32(p as i32), Val::I32(n as i32), Val::I32(logging_on as i32)])
            .map_err(|e| err("fmi3InstantiateModelExchange", e))?;
        if ok == 0 {
            return Err(Error::Instantiate { call: "fmi3InstantiateModelExchange", log: Vec::new() });
        }
        Ok(())
    }

    pub fn instantiate_cs(&mut self, name: &str, logging_on: bool, event_mode: bool) -> Result<()> {
        let (p, n) = self.write_str(name)?;
        let ok = self
            .fmu
            .call(
                "om_fmi3InstantiateCoSimulation",
                &[Val::I32(p as i32), Val::I32(n as i32), Val::I32(logging_on as i32), Val::I32(event_mode as i32)],
            )
            .map_err(|e| err("fmi3InstantiateCoSimulation", e))?;
        if ok == 0 {
            return Err(Error::Instantiate { call: "fmi3InstantiateCoSimulation", log: Vec::new() });
        }
        Ok(())
    }

    fn write_str(&mut self, s: &str) -> Result<(u32, u32)> {
        let p = self.scratch(s.len() as u32 + 16)?;
        self.fmu.write(p, s.as_bytes()).map_err(|e| err("artifact", e))?;
        Ok((p, s.len() as u32))
    }

    /// The artifact's own simulation runtime, the third face.
    pub fn run_simulation(&mut self, args: &[String]) -> Result<SimRun> {
        let mut blob = Vec::new();
        for a in args {
            blob.extend_from_slice(a.as_bytes());
            blob.push(0);
        }
        let p = self.scratch(blob.len() as u32 + 16)?;
        self.fmu.write(p, &blob).map_err(|e| err("artifact", e))?;
        let out = self
            .fmu
            .call("om_sim_run", &[Val::I32(p as i32), Val::I32(blob.len() as i32)])
            .map_err(|e| err("om_sim_run", e))? as u32;
        // The header is thirteen words: status, then (pointer, length) for the
        // result file, the linearized model's name and content, the row count, the
        // solver's name, `+profiling`'s packed files, and whether the report wants
        // gnuplot and xsltproc run over them.
        let read = (|| -> std::result::Result<SimRun, String> {
            let mut head = [0u32; 13];
            for (i, w) in head.iter_mut().enumerate() {
                *w = self.fmu.read_u32(out + i as u32 * 4)?;
            }
            let mut bytes = |ptr: u32, len: u32| -> std::result::Result<Vec<u8>, String> {
                let mut v = vec![0u8; len as usize];
                if len > 0 {
                    self.fmu.read(ptr, &mut v)?;
                }
                Ok(v)
            };
            let file = bytes(head[1], head[2])?;
            if head[0] != 0 {
                return Err(String::from_utf8_lossy(&file).into_owned());
            }
            let name = bytes(head[3], head[4])?;
            let content = bytes(head[5], head[6])?;
            let solver = bytes(head[8], head[9])?;
            Ok(SimRun {
                file,
                linear_file: (!name.is_empty()).then(|| {
                    (String::from_utf8_lossy(&name).into_owned(), String::from_utf8_lossy(&content).into_owned())
                }),
                prof_files: unpack_files(&bytes(head[10], head[11])?),
                prof_html: head[12] != 0,
                rows: head[7],
                solver: String::from_utf8_lossy(&solver).into_owned(),
            })
        })();
        read.map_err(Error::Simulation)
    }
}

/// The named files `om_sim_run` packed: per file a `u32` name length, the name, a
/// `u32` content length, the content. A truncated blob ends the list.
fn unpack_files(blob: &[u8]) -> Vec<(String, Vec<u8>)> {
    let word = |p: usize| u32::from_le_bytes(blob[p..p + 4].try_into().unwrap()) as usize;
    let mut out = Vec::new();
    let mut p = 0usize;
    while p + 4 <= blob.len() {
        let n = word(p);
        p += 4;
        if p + n + 4 > blob.len() {
            break;
        }
        let name = String::from_utf8_lossy(&blob[p..p + n]).into_owned();
        p += n;
        let len = word(p);
        p += 4;
        if p + len > blob.len() {
            break;
        }
        out.push((name, blob[p..p + len].to_vec()));
        p += len;
    }
    out
}

/// The `om_fmi3Get*`/`Set*` entry point for a base type, and how wide one value is.
fn numeric_call(ty: VarType, get: bool) -> Option<(&'static str, usize)> {
    Some(match (ty, get) {
        (VarType::Float64, true) => ("om_fmi3GetFloat64", 8),
        (VarType::Float64, false) => ("om_fmi3SetFloat64", 8),
        (VarType::Float32, true) => ("om_fmi3GetFloat32", 4),
        (VarType::Float32, false) => ("om_fmi3SetFloat32", 4),
        (VarType::Int8, true) => ("om_fmi3GetInt8", 1),
        (VarType::Int8, false) => ("om_fmi3SetInt8", 1),
        (VarType::UInt8, true) => ("om_fmi3GetUInt8", 1),
        (VarType::UInt8, false) => ("om_fmi3SetUInt8", 1),
        (VarType::Int16, true) => ("om_fmi3GetInt16", 2),
        (VarType::Int16, false) => ("om_fmi3SetInt16", 2),
        (VarType::UInt16, true) => ("om_fmi3GetUInt16", 2),
        (VarType::UInt16, false) => ("om_fmi3SetUInt16", 2),
        (VarType::Int32, true) => ("om_fmi3GetInt32", 4),
        (VarType::Int32, false) => ("om_fmi3SetInt32", 4),
        (VarType::UInt32, true) => ("om_fmi3GetUInt32", 4),
        (VarType::UInt32, false) => ("om_fmi3SetUInt32", 4),
        (VarType::Int64, true) => ("om_fmi3GetInt64", 8),
        (VarType::Int64, false) => ("om_fmi3SetInt64", 8),
        (VarType::UInt64, true) => ("om_fmi3GetUInt64", 8),
        (VarType::UInt64, false) => ("om_fmi3SetUInt64", 8),
        // The adapter takes and gives a boolean as an i32: wasm has nothing narrower.
        (VarType::Boolean, true) => ("om_fmi3GetBoolean", 4),
        (VarType::Boolean, false) => ("om_fmi3SetBoolean", 4),
        _ => return None,
    })
}

/// Decode `n` values of `ty` out of the bytes the adapter wrote.
fn decode(ty: VarType, width: usize, raw: &[u8], out: &mut [f64]) {
    for (i, o) in out.iter_mut().enumerate() {
        let b = &raw[i * width..(i + 1) * width];
        *o = match (ty, width) {
            (VarType::Float64, _) => f64::from_le_bytes(b.try_into().unwrap()),
            (VarType::Float32, _) => f32::from_le_bytes(b.try_into().unwrap()) as f64,
            (VarType::Boolean, _) => (i32::from_le_bytes(b.try_into().unwrap()) != 0) as u8 as f64,
            (VarType::Int8, _) => b[0] as i8 as f64,
            (VarType::UInt8, _) => b[0] as f64,
            (VarType::Int16, _) => i16::from_le_bytes(b.try_into().unwrap()) as f64,
            (VarType::UInt16, _) => u16::from_le_bytes(b.try_into().unwrap()) as f64,
            (VarType::Int32, _) => i32::from_le_bytes(b.try_into().unwrap()) as f64,
            (VarType::UInt32, _) => u32::from_le_bytes(b.try_into().unwrap()) as f64,
            (VarType::Int64, _) => i64::from_le_bytes(b.try_into().unwrap()) as f64,
            (VarType::UInt64, _) => u64::from_le_bytes(b.try_into().unwrap()) as f64,
            _ => 0.0,
        };
    }
}

fn encode(ty: VarType, width: usize, values: &[f64], raw: &mut Vec<u8>) {
    for v in values {
        match (ty, width) {
            (VarType::Float64, _) => raw.extend_from_slice(&v.to_le_bytes()),
            (VarType::Float32, _) => raw.extend_from_slice(&(*v as f32).to_le_bytes()),
            (VarType::Boolean, _) => raw.extend_from_slice(&((*v != 0.0) as i32).to_le_bytes()),
            (VarType::Int8, _) => raw.push(*v as i8 as u8),
            (VarType::UInt8, _) => raw.push(*v as u8),
            (VarType::Int16, _) => raw.extend_from_slice(&(*v as i16).to_le_bytes()),
            (VarType::UInt16, _) => raw.extend_from_slice(&(*v as u16).to_le_bytes()),
            (VarType::Int32, _) => raw.extend_from_slice(&(*v as i32).to_le_bytes()),
            (VarType::UInt32, _) => raw.extend_from_slice(&(*v as u32).to_le_bytes()),
            (VarType::Int64, _) => raw.extend_from_slice(&(*v as i64).to_le_bytes()),
            (VarType::UInt64, _) => raw.extend_from_slice(&(*v as u64).to_le_bytes()),
            _ => {}
        }
    }
}

/// An array of `f64` out of one of the Model Exchange getters.
fn get_vector(inst: &mut DylinkInstance, call: &'static str, out: &mut [f64]) -> Result<()> {
    let p = inst.scratch(out.len() as u32 * 8 + 16)?;
    let raw = inst
        .fmu
        .call(call, &[Val::I32(p as i32), Val::I32(out.len() as i32)])
        .map_err(|e| err(call, e))?;
    status(call, raw)?;
    for (i, o) in out.iter_mut().enumerate() {
        *o = inst.fmu.read_f64(p + i as u32 * 8).map_err(|e| err(call, e))?;
    }
    Ok(())
}

impl Fmi3 for DylinkInstance {
    fn get_version(&mut self) -> String {
        "3.0".to_string()
    }

    fn enter_initialization_mode(
        &mut self,
        tolerance: Option<f64>,
        start_time: f64,
        stop_time: Option<f64>,
    ) -> Result<()> {
        let raw = self
            .fmu
            .call(
                "om_fmi3EnterInitializationMode",
                &[
                    Val::I32(tolerance.is_some() as i32),
                    Val::F64(tolerance.unwrap_or(0.0).to_bits()),
                    Val::F64(start_time.to_bits()),
                    Val::I32(stop_time.is_some() as i32),
                    Val::F64(stop_time.unwrap_or(0.0).to_bits()),
                ],
            )
            .map_err(|e| err("fmi3EnterInitializationMode", e))?;
        status("fmi3EnterInitializationMode", raw)
    }

    fn exit_initialization_mode(&mut self) -> Result<()> {
        let raw = self.fmu.call("om_fmi3ExitInitializationMode", &[]).map_err(|e| err("fmi3ExitInitializationMode", e))?;
        status("fmi3ExitInitializationMode", raw)
    }

    fn set_debug_logging(&mut self, logging_on: bool, categories: &[&str]) -> Result<()> {
        let (p, n) = self.write_str(&categories.join("\n"))?;
        let raw = self
            .fmu
            .call("om_fmi3SetDebugLogging", &[Val::I32(logging_on as i32), Val::I32(p as i32), Val::I32(n as i32)])
            .map_err(|e| err("fmi3SetDebugLogging", e))?;
        status("fmi3SetDebugLogging", raw)
    }

    fn enter_event_mode(&mut self) -> Result<()> {
        let raw = self.fmu.call("om_fmi3EnterEventMode", &[]).map_err(|e| err("fmi3EnterEventMode", e))?;
        status("fmi3EnterEventMode", raw)
    }

    fn update_discrete_states(&mut self) -> Result<DiscreteStates> {
        let p = self.scratch(64)?;
        let raw = self
            .fmu
            .call("om_fmi3UpdateDiscreteStates", &[Val::I32(p as i32)])
            .map_err(|e| err("fmi3UpdateDiscreteStates", e))?;
        status("fmi3UpdateDiscreteStates", raw)?;
        let f = |s: &mut Self, i: u32| s.fmu.read_u32(p + i * 4).map_err(|e| err("fmi3UpdateDiscreteStates", e));
        let need_update = f(self, 0)? != 0;
        let terminate = f(self, 1)? != 0;
        let nominals_changed = f(self, 2)? != 0;
        let states_changed = f(self, 3)? != 0;
        let defined = f(self, 4)? != 0;
        let time = self.fmu.read_f64(p + 24).map_err(|e| err("fmi3UpdateDiscreteStates", e))?;
        Ok(DiscreteStates {
            need_update,
            terminate,
            nominals_changed,
            states_changed,
            next_event_time: defined.then_some(time),
        })
    }

    fn terminate(&mut self) -> Result<()> {
        let raw = self.fmu.call("om_fmi3Terminate", &[]).map_err(|e| err("fmi3Terminate", e))?;
        status("fmi3Terminate", raw)
    }

    fn enter_configuration_mode(&mut self) -> Result<()> {
        let raw = self.fmu.call("om_fmi3EnterConfigurationMode", &[]).map_err(|e| err("fmi3EnterConfigurationMode", e))?;
        status("fmi3EnterConfigurationMode", raw)
    }

    fn exit_configuration_mode(&mut self) -> Result<()> {
        let raw = self.fmu.call("om_fmi3ExitConfigurationMode", &[]).map_err(|e| err("fmi3ExitConfigurationMode", e))?;
        status("fmi3ExitConfigurationMode", raw)
    }

    fn get_numeric(&mut self, ty: VarType, vrs: &[u32], values: &mut [f64]) -> Result<()> {
        let (call, width) = numeric_call(ty.wire(), true)
            .ok_or_else(|| Error::Unsupported(format!("reading a {} as a number", ty.as_str())))?;
        let (vp, valp) = self.vrs_and_values(vrs, values.len() * width)?;
        let raw = self
            .fmu
            .call(call, &[Val::I32(vp as i32), Val::I32(vrs.len() as i32), Val::I32(valp as i32), Val::I32(values.len() as i32)])
            .map_err(|e| err(call, e))?;
        status(call, raw)?;
        let mut buf = vec![0u8; values.len() * width];
        self.fmu.read(valp, &mut buf).map_err(|e| err(call, e))?;
        decode(ty.wire(), width, &buf, values);
        Ok(())
    }

    fn set_numeric(&mut self, ty: VarType, vrs: &[u32], values: &[f64]) -> Result<()> {
        let (call, width) = numeric_call(ty.wire(), false)
            .ok_or_else(|| Error::Unsupported(format!("writing a {} as a number", ty.as_str())))?;
        let (vp, valp) = self.vrs_and_values(vrs, values.len() * width)?;
        let mut buf = Vec::with_capacity(values.len() * width);
        encode(ty.wire(), width, values, &mut buf);
        self.fmu.write(valp, &buf).map_err(|e| err(call, e))?;
        let raw = self
            .fmu
            .call(call, &[Val::I32(vp as i32), Val::I32(vrs.len() as i32), Val::I32(valp as i32), Val::I32(values.len() as i32)])
            .map_err(|e| err(call, e))?;
        status(call, raw)
    }
}

impl Fmi3ModelExchange for DylinkInstance {
    fn enter_continuous_time_mode(&mut self) -> Result<()> {
        let raw =
            self.fmu.call("om_fmi3EnterContinuousTimeMode", &[]).map_err(|e| err("fmi3EnterContinuousTimeMode", e))?;
        status("fmi3EnterContinuousTimeMode", raw)
    }

    fn set_time(&mut self, time: f64) -> Result<()> {
        let raw = self.fmu.call("om_fmi3SetTime", &[Val::F64(time.to_bits())]).map_err(|e| err("fmi3SetTime", e))?;
        status("fmi3SetTime", raw)
    }

    fn set_continuous_states(&mut self, states: &[f64]) -> Result<()> {
        let p = self.scratch(states.len() as u32 * 8 + 16)?;
        let mut buf = Vec::with_capacity(states.len() * 8);
        for v in states {
            buf.extend_from_slice(&v.to_le_bytes());
        }
        self.fmu.write(p, &buf).map_err(|e| err("fmi3SetContinuousStates", e))?;
        let raw = self
            .fmu
            .call("om_fmi3SetContinuousStates", &[Val::I32(p as i32), Val::I32(states.len() as i32)])
            .map_err(|e| err("fmi3SetContinuousStates", e))?;
        status("fmi3SetContinuousStates", raw)
    }

    fn get_continuous_states(&mut self, states: &mut [f64]) -> Result<()> {
        get_vector(self, "om_fmi3GetContinuousStates", states)
    }

    fn get_continuous_state_derivatives(&mut self, ders: &mut [f64]) -> Result<()> {
        get_vector(self, "om_fmi3GetContinuousStateDerivatives", ders)
    }

    fn get_event_indicators(&mut self, indicators: &mut [f64]) -> Result<()> {
        get_vector(self, "om_fmi3GetEventIndicators", indicators)
    }

    fn get_nominals_of_continuous_states(&mut self, nominals: &mut [f64]) -> Result<()> {
        get_vector(self, "om_fmi3GetNominalsOfContinuousStates", nominals)
    }

    fn completed_integrator_step(&mut self, no_set_state_prior: bool) -> Result<CompletedStep> {
        let p = self.scratch(16)?;
        let raw = self
            .fmu
            .call("om_fmi3CompletedIntegratorStep", &[Val::I32(no_set_state_prior as i32), Val::I32(p as i32)])
            .map_err(|e| err("fmi3CompletedIntegratorStep", e))?;
        status("fmi3CompletedIntegratorStep", raw)?;
        let enter = self.fmu.read_u32(p).map_err(|e| err("fmi3CompletedIntegratorStep", e))? != 0;
        let terminate = self.fmu.read_u32(p + 4).map_err(|e| err("fmi3CompletedIntegratorStep", e))? != 0;
        Ok(CompletedStep { enter_event_mode: enter, terminate })
    }

    fn get_directional_derivative(
        &mut self,
        unknowns: &[u32],
        knowns: &[u32],
        seed: &[f64],
        sensitivity: &mut [f64],
    ) -> Result<()> {
        let call = "om_fmi3GetDirectionalDerivative";
        let bytes = unknowns.len() * 4 + knowns.len() * 4 + seed.len() * 8 + sensitivity.len() * 8;
        let base = self.scratch(bytes as u32 + 32)?;
        let (up, kp) = (base, base + (unknowns.len() * 4) as u32);
        let sp = kp + (knowns.len() * 4) as u32;
        let op = sp + (seed.len() * 8) as u32;
        let mut buf = Vec::with_capacity(bytes);
        for v in unknowns {
            buf.extend_from_slice(&v.to_le_bytes());
        }
        for v in knowns {
            buf.extend_from_slice(&v.to_le_bytes());
        }
        for v in seed {
            buf.extend_from_slice(&v.to_le_bytes());
        }
        self.fmu.write(base, &buf).map_err(|e| err(call, e))?;
        let raw = self
            .fmu
            .call(
                call,
                &[
                    Val::I32(up as i32),
                    Val::I32(unknowns.len() as i32),
                    Val::I32(kp as i32),
                    Val::I32(knowns.len() as i32),
                    Val::I32(sp as i32),
                    Val::I32(seed.len() as i32),
                    Val::I32(op as i32),
                    Val::I32(sensitivity.len() as i32),
                ],
            )
            .map_err(|e| err(call, e))?;
        status(call, raw)?;
        for (i, o) in sensitivity.iter_mut().enumerate() {
            *o = self.fmu.read_f64(op + i as u32 * 8).map_err(|e| err(call, e))?;
        }
        Ok(())
    }

    fn get_number_of_continuous_states(&mut self) -> Result<usize> {
        let p = self.scratch(16)?;
        let raw = self
            .fmu
            .call("om_fmi3GetNumberOfContinuousStates", &[Val::I32(p as i32)])
            .map_err(|e| err("fmi3GetNumberOfContinuousStates", e))?;
        status("fmi3GetNumberOfContinuousStates", raw)?;
        Ok(self.fmu.read_u32(p).map_err(|e| err("fmi3GetNumberOfContinuousStates", e))? as usize)
    }

    fn get_number_of_event_indicators(&mut self) -> Result<usize> {
        let p = self.scratch(16)?;
        let raw = self
            .fmu
            .call("om_fmi3GetNumberOfEventIndicators", &[Val::I32(p as i32)])
            .map_err(|e| err("fmi3GetNumberOfEventIndicators", e))?;
        status("fmi3GetNumberOfEventIndicators", raw)?;
        Ok(self.fmu.read_u32(p).map_err(|e| err("fmi3GetNumberOfEventIndicators", e))? as usize)
    }
}

impl Fmi3CoSimulation for DylinkInstance {
    fn enter_step_mode(&mut self) -> Result<()> {
        let raw = self.fmu.call("om_fmi3EnterStepMode", &[]).map_err(|e| err("fmi3EnterStepMode", e))?;
        status("fmi3EnterStepMode", raw)
    }

    fn do_step(&mut self, point: f64, size: f64, no_set_state_prior: bool) -> Result<DoStep> {
        let p = self.scratch(32)?;
        let raw = self
            .fmu
            .call(
                "om_fmi3DoStep",
                &[Val::F64(point.to_bits()), Val::F64(size.to_bits()), Val::I32(no_set_state_prior as i32), Val::I32(p as i32)],
            )
            .map_err(|e| err("fmi3DoStep", e))?;
        status("fmi3DoStep", raw)?;
        let f = |s: &mut Self, i: u32| s.fmu.read_u32(p + i * 4).map_err(|e| err("fmi3DoStep", e));
        let event = f(self, 0)? != 0;
        let terminate = f(self, 1)? != 0;
        let early = f(self, 2)? != 0;
        let last = self.fmu.read_f64(p + 16).map_err(|e| err("fmi3DoStep", e))?;
        Ok(DoStep { event_handling_needed: event, terminate, early_return: early, last_successful_time: last })
    }
}

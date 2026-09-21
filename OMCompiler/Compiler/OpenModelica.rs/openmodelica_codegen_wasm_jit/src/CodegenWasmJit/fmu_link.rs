//! Linking the fmi-ls-wasm component (adapter + model + libraries) and the
//! FMI value-reference table.

use super::*;

pub(super) fn link_err(e: impl core::fmt::Debug) -> &'static str {
    record_error(format!("CodegenWasmJit: FMI3 component link failed: {e:?}"));
    "CodegenWasmJit: FMI3 component link failed"
}

/// The `vr -> SimData slot` table the FMI3 adapter resolves getters/setters with.
/// The value references are `getFMI3ValueReference`'s, the ones `CodegenFMU3`
/// writes into `modelDescription.xml`. Variables with no slot are skipped; the
/// adapter reports an unresolvable vr as an error.
/// Also the fmi-ls-dae `EnableDAEParameter` value reference, 0 for a model without a DAE
/// formulation. The synthetic variables follow `CodegenFMU3`: time, then the event
/// indicators, then (`--daeMode`) the DAE-mode switch and the residuals.
pub(super) fn build_fmi_vrs(sim_code: &SimCode::SimCode, map: &SimVarMap, layout: &SimLayout) -> Result<(Vec<FmiVr>, u32)> {
    use openmodelica_backend::SimCodeUtil;
    let vars = &sim_code.modelInfo.vars;
    let all = lst(&vars.stateVars)
        .chain(lst(&vars.derivativeVars))
        .chain(lst(&vars.algVars))
        .chain(lst(&vars.discreteAlgVars))
        .chain(lst(&vars.paramVars))
        .chain(lst(&vars.aliasVars))
        .chain(lst(&vars.intAlgVars))
        .chain(lst(&vars.intParamVars))
        .chain(lst(&vars.intAliasVars))
        .chain(lst(&vars.boolAlgVars))
        .chain(lst(&vars.boolParamVars))
        .chain(lst(&vars.boolAliasVars));
    // C's `mapOutputReference2RealOutputDerivatives`.
    let mut out_der: HashMap<String, u32> = HashMap::new();
    for sv in lst(&vars.outputVars) {
        let key = sim_cref_key(&sv.name)?;
        if let Some(slot) = map.vars.get(&format!("${key}_der")) {
            out_der.insert(key, slot.off);
        }
    }
    let mut lens: HashMap<String, u32> = HashMap::new();
    if let Some(ms) = &sim_code.modelStructure {
        for a in lst(&ms.fmiArrays) {
            lens.insert(sim_cref_key(&a.first)?, u32::try_from(a.numElements).unwrap_or(1));
        }
    }
    let mut out = Vec::new();
    for sv in all {
        let key = sim_cref_key(&sv.name)?;
        let Some(slot) = map.vars.get(&key).copied() else { continue };
        let vr: u32 = SimCodeUtil::getFMI3ValueReference(sv.clone(), sim_code.clone())?
            .parse()
            .map_err(|_| "CodegenWasmJit: FMI3 value reference is not a number")?;
        // A real variable's start slot: an init-mode set must go to the `start`
        // attribute, not to the live slot `setAllVarsToStart` is about to rewrite.
        let start_off = map.start_slots.get(&key).copied().unwrap_or(0);
        let der_off = out_der.get(&key).copied().unwrap_or(0);
        out.push(FmiVr {
            vr,
            off: slot.off,
            wty: slot.wty,
            negate: slot.negate,
            start_off,
            is_string: false,
            der_off,
            len: lens.get(&key).copied().unwrap_or(1),
        });
    }
    // String variables: `is_string` marks the slot as an i32 runtime-String
    // handle, so the adapter reads/writes it via `rt_str_*`, not as a number.
    for sv in lst(&vars.stringAlgVars)
        .chain(lst(&vars.stringParamVars))
        .chain(lst(&vars.stringAliasVars))
    {
        let key = sim_cref_key(&sv.name)?;
        let Some(slot) = map.vars.get(&key).copied() else { continue };
        let vr: u32 = SimCodeUtil::getFMI3ValueReference(sv.clone(), sim_code.clone())?
            .parse()
            .map_err(|_| "CodegenWasmJit: FMI3 value reference is not a number")?;
        out.push(FmiVr {
            vr,
            off: slot.off,
            wty: slot.wty,
            negate: slot.negate,
            start_off: 0,
            is_string: true,
            der_off: 0,
            len: lens.get(&key).copied().unwrap_or(1),
        });
    }
    // time, then the event indicators after it (`EventIndicatorVariables3`).
    let time_vr: u32 = SimCodeUtil::getFMI3TimeValueReference(sim_code.clone())?
        .parse()
        .map_err(|_| "CodegenWasmJit: FMI3 time value reference is not a number")?;
    out.push(FmiVr {
        vr: time_vr,
        off: TIME_OFF,
        wty: WTy::F64,
        negate: Neg::None,
        start_off: 0,
        is_string: false,
        der_off: 0,
        len: 1,
    });
    for k in 0..layout.n_zc {
        out.push(FmiVr {
            vr: time_vr + 1 + k,
            off: layout.zc_off + k * 8,
            wty: WTy::F64,
            negate: Neg::None,
            start_off: 0,
            is_string: false,
            der_off: 0,
            len: 1,
        });
    }
    let mut dae_enable_vr = 0;
    if let Some(d) = &sim_code.daeModeData {
        dae_enable_vr = time_vr + 1 + layout.n_zc;
        for sv in lst(&d.residualVars) {
            let i = u32::try_from(sv.index).map_err(|_| "CodegenWasmJit: DAE mode residual has no index")?;
            out.push(FmiVr {
                vr: dae_enable_vr + 1 + i,
                off: layout.dae_res_off + i * 8,
                wty: WTy::F64,
                negate: Neg::None,
                start_off: 0,
                is_string: false,
                der_off: 0,
                len: 1,
            });
        }
    }
    out.sort_by_key(|e| e.vr);
    out.dedup_by_key(|e| e.vr);
    Ok((out, dae_enable_vr))
}

/// CRC-32 (IEEE) for the ZIP entries.
pub(super) fn crc32(data: &[u8]) -> u32 {
    let mut crc: u32 = 0xffff_ffff;
    for &b in data {
        crc ^= b as u32;
        for _ in 0..8 {
            crc = (crc >> 1) ^ (0xedb8_8320 & (0u32.wrapping_sub(crc & 1)));
        }
    }
    !crc
}

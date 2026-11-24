//! `CEngine` as an FMI host: what `openmodelica_fmi3_wasm`'s state machine needs
//! of the runtime it runs in, where the wasm component answers from the in-wasm
//! runtime's globals.

use openmodelica_fmi3_wasm::FmiHost;
use openmodelica_sim_meta::delay::DelayState;
use openmodelica_sim_meta::simflags;
use openmodelica_sim_meta::spatial::SpatialState;

use crate::engine::CEngine;

impl FmiHost for CEngine {
    /// What this archive actually links, so a flag the export baked in but the
    /// link left out is rejected rather than quietly ignored.
    fn sim_capabilities(&self) -> simflags::Capabilities {
        simflags::Capabilities {
            klu: openmodelica_solvers::klu::AVAILABLE,
            kinsol: openmodelica_nls::kinsol::AVAILABLE,
            lis: false,
            ida: openmodelica_sim_meta::IDA,
            cvode: openmodelica_sim_meta::CVODE,
            alarm: true,
            // The importer decides what it reads; an FMU writes no result file.
            variable_filter: false,
            // Ipopt is deliberately not in the FMU archive: it would bring MUMPS
            // and a libgfortran dependency for an entry point no FMU has.
            optimization: false,
        }
    }

    /// C's `readFlag`s: the solver choices land in `SIMULATION_INFO`, which is
    /// where the generated code and the solvers read them from.
    fn apply_sim_flags(&mut self, flags: &simflags::SimFlags) {
        let si = unsafe { &mut *(*self.rt.data).simulationInfo };
        crate::systems::apply_solver_flags(si, flags);
    }

    /// The string variables of every ring slot, which C's `fmi2GetFMUstate` keeps
    /// and the layout holds only as handles, then the operator histories.
    fn opaque_state(&mut self, _sim_data: u32, _layout: &openmodelica_sim_meta::Layout) -> Vec<u8> {
        let mut out = Vec::new();
        for slot in string_slots(self.rt.data) {
            let s = crate::model_data::string_bytes(unsafe { *slot });
            out.extend((s.len() as u64).to_le_bytes());
            out.extend(s);
        }
        let mut words = Vec::new();
        crate::operators::to_words(self.rt.data, &mut words);
        crate::spatial::to_words(self.rt.data, &mut words);
        out.extend(words.iter().flat_map(|w| w.to_le_bytes()));
        out
    }

    fn opaque_state_fits(&mut self, _sim_data: u32, _layout: &openmodelica_sim_meta::Layout, state: &[u8]) -> bool {
        read_opaque(self.rt.data, state).is_some()
    }

    fn set_opaque_state(&mut self, _sim_data: u32, _layout: &openmodelica_sim_meta::Layout, state: &[u8]) -> bool {
        let Some((strings, delay, spatial)) = read_opaque(self.rt.data, state) else {
            return false;
        };
        crate::operators::restore(self.rt.data, delay);
        crate::spatial::restore(self.rt.data, spatial);
        for (slot, s) in string_slots(self.rt.data).zip(strings) {
            unsafe { crate::model_data::string_set_new(slot, s) };
        }
        true
    }
}

/// The string variables and histories in `state`, not applied yet; `None` if
/// [`FmiHost::opaque_state`] did not write it for this model.
fn read_opaque(
    data: *mut crate::abi::DATA,
    state: &[u8],
) -> Option<(Vec<&[u8]>, Option<DelayState>, Option<SpatialState>)> {
    let mut strings = Vec::new();
    let mut at = 0;
    for _ in string_slots(data) {
        let len = u64::from_le_bytes(state.get(at..at + 8)?.try_into().unwrap()) as usize;
        let end = (at + 8).checked_add(len)?;
        strings.push(state.get(at + 8..end)?);
        at = end;
    }
    let rest = &state[at..];
    if rest.len() % 8 != 0 {
        return None;
    }
    let mut words = rest.chunks_exact(8).map(|b| f64::from_le_bytes(b.try_into().unwrap()));
    let delay = crate::operators::from_words(data, &mut words)?;
    let spatial = crate::spatial::from_words(data, &mut words)?;
    words.next().is_none().then_some((strings, delay, spatial))
}

fn string_slots(data: *mut crate::abi::DATA) -> impl Iterator<Item = *mut crate::abi::modelica_string> {
    let n = unsafe { (*(*data).modelData).nVariablesString }.max(0) as usize;
    (0..crate::data::RING).flat_map(move |r| {
        let sd = unsafe { *(*data).localData.add(r) };
        (0..n).map(move |i| unsafe { (*sd).stringVars.add(i) })
    })
}

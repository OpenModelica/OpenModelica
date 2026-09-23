//! `CEngine` as an FMI host: what `openmodelica_fmi3_wasm`'s state machine needs
//! of the runtime it runs in, where the wasm component answers from the in-wasm
//! runtime's globals.

use openmodelica_fmi3_wasm::FmiHost;
use openmodelica_sim_meta::simflags;

use crate::engine::CEngine;

impl FmiHost for CEngine {
    /// What this archive actually links, so a flag the export baked in but the
    /// link left out is rejected rather than quietly ignored.
    fn sim_capabilities(&self) -> simflags::Capabilities {
        simflags::Capabilities {
            klu: openmodelica_solvers::klu::AVAILABLE,
            kinsol: openmodelica_nls::kinsol::AVAILABLE,
            // `-ls`/`-lss=umfpack` fall back to KLU here (src/systems.rs).
            umfpack: openmodelica_solvers::klu::AVAILABLE,
            lis: false,
            ida: openmodelica_sim_meta::IDA,
            cvode: openmodelica_sim_meta::CVODE,
            alarm: true,
            // The importer decides what it reads; an FMU writes no result file.
            variable_filter: false,
            // Ipopt is deliberately not in the FMU archive: it would bring MUMPS
            // and a libgfortran dependency for an entry point no FMU has.
            optimization: false,
            qss: true,
        }
    }

    /// C's `readFlag`s: the solver choices land in `SIMULATION_INFO`, which is
    /// where the generated code and the solvers read them from.
    fn apply_sim_flags(&mut self, flags: &simflags::SimFlags) {
        let si = unsafe { &mut *(*self.rt.data).simulationInfo };
        crate::systems::apply_solver_flags(si, flags);
    }
}

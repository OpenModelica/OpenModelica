//! wasm stub for [`crate::CevalScriptOMSimulator`]. The native module drives the
//! OMSimulator scripting API (`oms_*`) through `openmodelica_util::OMSimulatorExt`,
//! which dlopen()s libOMSimulator — no wasm target. On wasm the dispatcher
//! reports the API unavailable; everything else routes through it via `ceval`.

use std::sync::Arc;

use anyhow::{Result, bail};
use arcstr::ArcStr;

use openmodelica_frontend_types::Values;

pub fn ceval(
    inFunctionName: ArcStr,
    _inVals: Arc<metamodelica::List<Arc<Values::Value>>>,
) -> Result<Arc<Values::Value>> {
    bail!("CevalScriptOMSimulator: the OMSimulator scripting API (libOMSimulator) is unavailable on wasm (called `{inFunctionName}`)")
}

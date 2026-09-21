//! The fmi-ls-dae layered standard: the manifest that turns a Model Exchange FMU
//! into a DAE one — the structural parameter that enables the mode, the algebraic
//! variables the importer then solves for beside the states, and the residuals it
//! drives to zero, with a `<ModelStructure>` that replaces the model description's.

use crate::description::Unknown;
use crate::parse::{child, children, u32_attr};
use crate::{Error, Result};

pub const MANIFEST_PATH: &str = "extra/org.fmi-standard.fmi-ls-dae/fmi-ls-manifest.xml";
pub const LS_NAME: &str = "org.fmi-standard.fmi-ls-dae";

#[derive(Clone, Debug)]
pub struct Manifest {
    pub version: String,
    /// The Boolean structural parameter set to `true` in Configuration Mode.
    pub enable_vr: u32,
    /// The algebraic unknowns, in the order the residual Jacobian's columns follow the states.
    pub algebraic_variables: Vec<u32>,
    /// The `<Residual>` constraints the importer drives to zero, in row order.
    pub residuals: Vec<Unknown>,
    /// The `<ModelStructure>` overriding the model description's; each list is
    /// empty when the manifest leaves it out.
    pub outputs: Vec<Unknown>,
    pub continuous_state_derivatives: Vec<Unknown>,
    pub initial_unknowns: Vec<Unknown>,
    pub event_indicators: Vec<Unknown>,
}

impl Manifest {
    pub fn parse(xml: &str) -> Result<Manifest> {
        let doc = roxmltree::Document::parse(xml).map_err(|e| Error::Xml(e.to_string()))?;
        let root = doc.root_element();
        if root.tag_name().name() != "fmiDAEManifest" {
            return Err(Error::Xml(format!("root element is <{}>, not <fmiDAEManifest>", root.tag_name().name())));
        }
        let enable = child(root, "EnableDAEParameter")
            .ok_or_else(|| Error::Xml("<fmiDAEManifest> has no <EnableDAEParameter>".into()))?;
        let enable_vr = u32_attr(enable, "valueReference")
            .ok_or_else(|| Error::Xml("<EnableDAEParameter> has no valueReference".into()))?;
        let algebraic_variables = child(root, "AlgebraicVariables")
            .map(|a| children(a, "AlgebraicVariable").filter_map(|v| u32_attr(v, "valueReference")).collect())
            .unwrap_or_default();
        let ms = child(root, "ModelStructure");
        let unknowns = |tag| ms.map(|ms| crate::parse::unknowns3(ms, tag)).unwrap_or_default();
        Ok(Manifest {
            version: root.attribute(("http://fmi-standard.org/fmi-ls-manifest", "fmi-ls-version"))
                .or_else(|| root.attribute("fmi-ls-version"))
                .unwrap_or_default()
                .to_string(),
            enable_vr,
            algebraic_variables,
            residuals: unknowns("Residual"),
            outputs: unknowns("Output"),
            continuous_state_derivatives: unknowns("ContinuousStateDerivative"),
            initial_unknowns: unknowns("InitialUnknown"),
            event_indicators: unknowns("EventIndicator"),
        })
    }

    /// The residual variables in row order.
    pub fn residual_vrs(&self) -> Vec<u32> {
        self.residuals.iter().map(|r| r.value_reference).collect()
    }
}

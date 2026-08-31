//! The fmi-ls-dae layered standard: the manifest that turns a Model Exchange FMU
//! into a DAE one — the structural parameter that enables the mode, the algebraic
//! variables the importer then solves for beside the states, and the residuals it
//! drives to zero, with a `<ModelStructure>` that replaces the model description's.

use crate::description::{DependenciesKind, Unknown};
use crate::parse::{child, children, list_attr, u32_attr};
use crate::{Error, Result};

pub const MANIFEST_PATH: &str = "extra/org.fmi-standard.fmi-ls-dae/fmi-ls-manifest.xml";
pub const LS_NAME: &str = "org.fmi-standard.fmi-ls-dae";

/// One `<Formulation>`: a residual variable, and how many times the constraint
/// it came from was differentiated to get it.
#[derive(Clone, Debug)]
pub struct Formulation {
    pub value_reference: u32,
    pub index: Option<u32>,
    /// `None`: depends on every known.
    pub dependencies: Option<Vec<u32>>,
    pub dependencies_kind: Vec<DependenciesKind>,
}

/// A `<Residual>`: one constraint, in one or more differentiated forms.
#[derive(Clone, Debug)]
pub struct Residual {
    pub formulations: Vec<Formulation>,
}

#[derive(Clone, Debug)]
pub struct Manifest {
    pub version: String,
    /// The Boolean structural parameter set to `true` in Configuration Mode.
    pub enable_vr: u32,
    /// The algebraic unknowns, in the order the residual Jacobian's columns follow the states.
    pub algebraic_variables: Vec<u32>,
    pub residuals: Vec<Residual>,
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
        if root.tag_name().name() != "fmi-ls-dae" {
            return Err(Error::Xml(format!("root element is <{}>, not <fmi-ls-dae>", root.tag_name().name())));
        }
        let enable = child(root, "EnableDAE").ok_or_else(|| Error::Xml("<fmi-ls-dae> has no <EnableDAE>".into()))?;
        let enable_vr = u32_attr(enable, "valueReference")
            .ok_or_else(|| Error::Xml("<EnableDAE> has no valueReference".into()))?;
        let algebraic_variables = child(root, "AlgebraicVariables")
            .map(|a| children(a, "AlgebraicVariable").filter_map(|v| u32_attr(v, "valueReference")).collect())
            .unwrap_or_default();
        let ms = child(root, "ModelStructure");
        let residuals = ms
            .map(|ms| {
                children(ms, "Residual")
                    .map(|r| Residual {
                        formulations: children(r, "Formulation")
                            .filter_map(|f| {
                                Some(Formulation {
                                    value_reference: u32_attr(f, "valueReference")?,
                                    index: u32_attr(f, "index"),
                                    dependencies: list_attr(f, "dependencies"),
                                    dependencies_kind: crate::parse::dependencies_kind(f),
                                })
                            })
                            .collect(),
                    })
                    .collect()
            })
            .unwrap_or_default();
        let unknowns = |tag| ms.map(|ms| crate::parse::unknowns3(ms, tag)).unwrap_or_default();
        Ok(Manifest {
            version: root.attribute(("http://fmi-standard.org/fmi-ls-manifest", "fmi-ls-version"))
                .or_else(|| root.attribute("fmi-ls-version"))
                .unwrap_or_default()
                .to_string(),
            enable_vr,
            algebraic_variables,
            residuals,
            outputs: unknowns("Output"),
            continuous_state_derivatives: unknowns("ContinuousStateDerivative"),
            initial_unknowns: unknowns("InitialUnknown"),
            event_indicators: unknowns("EventIndicator"),
        })
    }

    /// The residual variables in row order, every formulation of every residual.
    pub fn residual_vrs(&self) -> Vec<u32> {
        self.residuals.iter().flat_map(|r| r.formulations.iter().map(|f| f.value_reference)).collect()
    }
}

//! FMI 1.0 `modelDescription.xml`, normalised onto the 3.0 shape.
//!
//! 1.0 has no causality for parameters — a parameter is a *variability*, and
//! `internal`/`none` causality are what 2.0 calls `local`. It also has no
//! `<ModelStructure>`: an output's `<DirectDependency>` names are turned into
//! the dependencies of an `<Output>` unknown. Aliases have no counterpart at
//! all and are kept as [`Alias`].

use super::*;

pub fn parse(root: Node) -> Result<ModelDescription> {
    let model_identifier = required(root, "modelIdentifier")?.to_string();
    let mut md = ModelDescription {
        fmi_version: FmiVersion::Fmi1,
        model_name: required(root, "modelName")?.to_string(),
        instantiation_token: required(root, "guid")?.to_string(),
        description: string_attr(root, "description"),
        author: string_attr(root, "author"),
        version: string_attr(root, "version"),
        generation_tool: string_attr(root, "generationTool"),
        generation_date_and_time: string_attr(root, "generationDateAndTime"),
        variable_naming_convention: attr(root, "variableNamingConvention")
            .unwrap_or("flat")
            .to_string(),
        default_experiment: default_experiment(root),
        units: units(root),
        type_definitions: type_definitions(root),
        number_of_event_indicators: u32_attr(root, "numberOfEventIndicators").unwrap_or(0),
        number_of_continuous_states: u32_attr(root, "numberOfContinuousStates"),
        ..Default::default()
    };
    match child(root, "Implementation") {
        Some(imp) => md.co_simulation = Some(co_simulation(imp, model_identifier)),
        None => {
            md.model_exchange = Some(Interface {
                model_identifier,
                needs_completed_integrator_step: true,
                ..Default::default()
            })
        }
    }
    md.variables = variables(root)?;
    md.model_structure = model_structure(root, &md.variables);
    Ok(md)
}

fn co_simulation(imp: Node, model_identifier: String) -> Interface {
    let tool = child(imp, "CoSimulation_Tool");
    let cs = tool.or_else(|| child(imp, "CoSimulation_StandAlone"));
    let caps = cs.and_then(|c| child(c, "Capabilities"));
    let cap = |name, default| caps.map(|c| bool_attr(c, name, default)).unwrap_or(default);
    Interface {
        model_identifier,
        // A Tool FMU drives its own tool, which is 2.0's needsExecutionTool.
        needs_execution_tool: tool.is_some(),
        can_handle_variable_communication_step_size: cap(
            "canHandleVariableCommunicationStepSize",
            false,
        ),
        can_handle_events: cap("canHandleEvents", false),
        can_reject_steps: cap("canRejectSteps", false),
        can_interpolate_inputs: cap("canInterpolateInputs", false),
        can_run_asynchronously: cap("canRunAsynchronuously", false),
        can_signal_events: cap("canSignalEvents", false),
        can_be_instantiated_only_once_per_process: cap(
            "canBeInstantiatedOnlyOncePerProcess",
            false,
        ),
        can_not_use_memory_management_functions: cap(
            "canNotUseMemoryManagementFunctions",
            false,
        ),
        max_output_derivative_order: caps
            .and_then(|c| u32_attr(c, "maxOutputDerivativeOrder"))
            .unwrap_or(0),
        ..Default::default()
    }
}

fn var_type(tag: &str) -> Option<VarType> {
    Some(match tag {
        "Real" => VarType::Float64,
        "Integer" => VarType::Int32,
        "Boolean" => VarType::Boolean,
        "String" => VarType::String,
        "Enumeration" => VarType::Enumeration,
        _ => return None,
    })
}

fn variables(root: Node) -> Result<Vec<Variable>> {
    let mv = child(root, "ModelVariables")
        .ok_or_else(|| Error::Xml("no <ModelVariables>".into()))?;
    let mut vars = Vec::new();
    for n in children(mv, "ScalarVariable") {
        let index = vars.len() as u32 + 1;
        let vr = required(n, "valueReference")?
            .trim()
            .parse()
            .map_err(|_| Error::Xml("valueReference is not a number".into()))?;
        let t = n
            .children()
            .filter(Node::is_element)
            .find_map(|c| var_type(c.tag_name().name()).map(|ty| (c, ty)));
        // A 1.0 variable may carry no type element at all; treat it as a Real,
        // which is what the value reference then means.
        let (tn, ty) = match t {
            Some(v) => (Some(v.0), v.1),
            None => (None, VarType::Float64),
        };
        let mut v = blank_variable(required(n, "name")?.to_string(), vr, index, ty);
        v.description = string_attr(n, "description");
        v.alias = match attr(n, "alias") {
            Some("alias") => Alias::Alias,
            Some("negatedAlias") => Alias::NegatedAlias,
            _ => Alias::NoAlias,
        };
        let (causality, variability) = kind(attr(n, "causality"), attr(n, "variability"));
        v.causality = causality;
        v.variability = variability;
        if let Some(tn) = tn {
            v.declared_type = string_attr(tn, "declaredType");
            v.quantity = string_attr(tn, "quantity");
            v.unit = string_attr(tn, "unit");
            v.display_unit = string_attr(tn, "displayUnit");
            v.relative_quantity = bool_attr(tn, "relativeQuantity", false);
            v.min = f64_attr(tn, "min");
            v.max = f64_attr(tn, "max");
            v.nominal = f64_attr(tn, "nominal");
            v.start = start(tn, ty);
            // 1.0's `fixed` says whether the start value is exact or a guess the
            // FMU may refine, which is 2.0's `initial`.
            if v.start.is_some() {
                v.initial = Some(if bool_attr(tn, "fixed", true) {
                    Initial::Exact
                } else {
                    Initial::Approx
                });
            }
        }
        vars.push(v);
    }
    Ok(vars)
}

/// 1.0's `variability="parameter"` is 2.0's `causality="parameter"`, and its
/// `internal`/`none` causality is 2.0's `local`.
fn kind(causality: Option<&str>, variability: Option<&str>) -> (Causality, Variability) {
    match variability {
        Some("parameter") => (Causality::Parameter, Variability::Fixed),
        Some("constant") => (Causality::Local, Variability::Constant),
        v => {
            let c = match causality {
                Some("input") => Causality::Input,
                Some("output") => Causality::Output,
                _ => Causality::Local,
            };
            (c, super::variability(v, Variability::Continuous))
        }
    }
}

fn start(n: Node, ty: VarType) -> Option<Start> {
    let s = attr(n, "start")?;
    Some(match ty {
        VarType::Float64 => Start::Reals(vec![s.trim().parse().ok()?]),
        VarType::Boolean => Start::Bools(vec![s == "true" || s == "1"]),
        VarType::String => Start::Strings(vec![s.to_string()]),
        _ => Start::Ints(vec![s.trim().parse().ok()?]),
    })
}

/// `<DirectDependency>` as 2.0's `<Outputs>`: every output is an unknown, and
/// the names it lists become its dependencies. No `<DirectDependency>` means
/// the output depends on every input, which is what an absent `dependencies`
/// attribute says in the later versions.
fn model_structure(root: Node, vars: &[Variable]) -> ModelStructure {
    let Some(mv) = child(root, "ModelVariables") else { return ModelStructure::default() };
    let outputs = children(mv, "ScalarVariable")
        .enumerate()
        .filter(|(i, _)| vars.get(*i).map(|v| v.causality == Causality::Output).unwrap_or(false))
        .map(|(i, n)| {
            let deps = child(n, "DirectDependency").map(|dd| {
                children(dd, "Name")
                    .filter_map(|name| {
                        let text = name.text()?.trim();
                        vars.iter().find(|v| v.name == text).map(|v| v.value_reference)
                    })
                    .collect()
            });
            Unknown {
                value_reference: vars[i].value_reference,
                index: i as u32 + 1,
                dependencies: deps,
                dependencies_kind: Vec::new(),
            }
        })
        .collect();
    ModelStructure { outputs, ..Default::default() }
}

/// 1.0 hangs the display units off `<BaseUnit unit=…>`, and its conversion is
/// `gain`/`offset` rather than `factor`/`offset`.
fn units(root: Node) -> Vec<Unit> {
    let Some(uds) = child(root, "UnitDefinitions") else { return Vec::new() };
    children(uds, "BaseUnit")
        .filter_map(|u| {
            Some(Unit {
                name: attr(u, "unit")?.to_string(),
                base_unit: None,
                display_units: children(u, "DisplayUnitDefinition")
                    .filter_map(|d| {
                        Some(DisplayUnit {
                            name: attr(d, "displayUnit")?.to_string(),
                            factor: f64_attr(d, "gain").unwrap_or(1.0),
                            offset: f64_attr(d, "offset").unwrap_or(0.0),
                            inverse: false,
                        })
                    })
                    .collect(),
            })
        })
        .collect()
}

fn type_definitions(root: Node) -> Vec<TypeDefinition> {
    let Some(tds) = child(root, "TypeDefinitions") else { return Vec::new() };
    children(tds, "Type")
        .filter_map(|t| {
            let name = attr(t, "name")?.to_string();
            let n = t.children().filter(Node::is_element).find_map(|c| {
                var_type(c.tag_name().name().strip_suffix("Type")?).map(|ty| (c, ty))
            })?;
            let (n, ty) = n;
            Some(TypeDefinition {
                name,
                ty,
                description: string_attr(t, "description"),
                quantity: string_attr(n, "quantity"),
                unit: string_attr(n, "unit"),
                display_unit: string_attr(n, "displayUnit"),
                relative_quantity: bool_attr(n, "relativeQuantity", false),
                unbounded: false,
                min: f64_attr(n, "min"),
                max: f64_attr(n, "max"),
                nominal: f64_attr(n, "nominal"),
                // 1.0 items have no value: they are numbered by position.
                items: children(n, "Item")
                    .enumerate()
                    .filter_map(|(i, it)| {
                        Some(EnumerationItem {
                            name: attr(it, "name")?.to_string(),
                            value: i as i64 + 1,
                            description: string_attr(it, "description"),
                        })
                    })
                    .collect(),
            })
        })
        .collect()
}

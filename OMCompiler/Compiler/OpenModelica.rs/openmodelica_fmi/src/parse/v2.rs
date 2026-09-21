//! FMI 2.0 `modelDescription.xml`. Normalised onto the 3.0 shape: `guid` is the
//! instantiation token, `<Real>` a `Float64`, and the variable *indices* that
//! `derivative` and `<ModelStructure>` use become value references.

use super::*;

pub fn parse(root: Node) -> Result<ModelDescription> {
    let mut md = ModelDescription {
        fmi_version: FmiVersion::Fmi2,
        model_name: required(root, "modelName")?.to_string(),
        instantiation_token: required(root, "guid")?.to_string(),
        description: string_attr(root, "description"),
        author: string_attr(root, "author"),
        version: string_attr(root, "version"),
        copyright: string_attr(root, "copyright"),
        license: string_attr(root, "license"),
        generation_tool: string_attr(root, "generationTool"),
        generation_date_and_time: string_attr(root, "generationDateAndTime"),
        variable_naming_convention: attr(root, "variableNamingConvention")
            .unwrap_or("flat")
            .to_string(),
        model_exchange: child(root, "ModelExchange").map(interface).transpose()?,
        co_simulation: child(root, "CoSimulation").map(interface).transpose()?,
        default_experiment: default_experiment(root),
        units: units(root),
        type_definitions: type_definitions(root),
        log_categories: log_categories(root),
        number_of_event_indicators: u32_attr(root, "numberOfEventIndicators").unwrap_or(0),
        ..Default::default()
    };
    md.variables = variables(root)?;
    // `derivative` and `<Unknown index=…>` are 1-based positions in
    // `<ModelVariables>`, resolvable only once every variable is read.
    let derivatives: Vec<Option<u32>> = md
        .variables
        .iter()
        .map(|v| v.derivative.and_then(|ix| index_to_vr(&md.variables, ix)))
        .collect();
    for (v, d) in md.variables.iter_mut().zip(derivatives) {
        v.derivative = d;
    }
    md.model_structure = model_structure(root, &md.variables);
    Ok(md)
}

fn interface(n: Node) -> Result<Interface> {
    Ok(Interface {
        model_identifier: required(n, "modelIdentifier")?.to_string(),
        needs_execution_tool: bool_attr(n, "needsExecutionTool", false),
        can_be_instantiated_only_once_per_process: bool_attr(
            n,
            "canBeInstantiatedOnlyOncePerProcess",
            false,
        ),
        can_not_use_memory_management_functions: bool_attr(
            n,
            "canNotUseMemoryManagementFunctions",
            false,
        ),
        can_get_and_set_state: bool_attr(n, "canGetAndSetFMUstate", false),
        can_serialize_state: bool_attr(n, "canSerializeFMUstate", false),
        provides_directional_derivatives: bool_attr(n, "providesDirectionalDerivative", false),
        needs_completed_integrator_step: !bool_attr(n, "completedIntegratorStepNotNeeded", false),
        can_handle_variable_communication_step_size: bool_attr(
            n,
            "canHandleVariableCommunicationStepSize",
            false,
        ),
        max_output_derivative_order: u32_attr(n, "maxOutputDerivativeOrder").unwrap_or(0),
        can_interpolate_inputs: bool_attr(n, "canInterpolateInputs", false),
        can_run_asynchronously: bool_attr(n, "canRunAsynchronuously", false),
        source_files: source_files(n),
        ..Default::default()
    })
}

fn source_files(n: Node) -> Vec<String> {
    let Some(sf) = child(n, "SourceFiles") else { return Vec::new() };
    children(sf, "File").filter_map(|f| string_attr(f, "name")).collect()
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
        let Some(t) = n.children().filter(Node::is_element).find_map(|c| {
            var_type(c.tag_name().name()).map(|ty| (c, ty))
        }) else {
            return Err(Error::Xml(format!(
                "<ScalarVariable name=\"{}\"> has no type element",
                attr(n, "name").unwrap_or_default()
            )));
        };
        let (tn, ty) = t;
        let index = vars.len() as u32 + 1;
        let vr = required(n, "valueReference")?
            .trim()
            .parse()
            .map_err(|_| Error::Xml("valueReference is not a number".into()))?;
        let mut v = blank_variable(required(n, "name")?.to_string(), vr, index, ty);
        v.description = string_attr(n, "description");
        v.causality = causality(attr(n, "causality"), Causality::Local);
        v.variability = variability(attr(n, "variability"), Variability::Continuous);
        v.initial = initial(attr(n, "initial"));
        v.can_handle_multiple_set_per_time_instant =
            bool_attr(n, "canHandleMultipleSetPerTimeInstant", true);
        v.declared_type = string_attr(tn, "declaredType");
        v.quantity = string_attr(tn, "quantity");
        v.unit = string_attr(tn, "unit");
        v.display_unit = string_attr(tn, "displayUnit");
        v.relative_quantity = bool_attr(tn, "relativeQuantity", false);
        v.unbounded = bool_attr(tn, "unbounded", false);
        v.min = f64_attr(tn, "min");
        v.max = f64_attr(tn, "max");
        v.nominal = f64_attr(tn, "nominal");
        // The state this differentiates, still as a variable index.
        v.derivative = u32_attr(tn, "derivative");
        v.reinit = bool_attr(tn, "reinit", false);
        v.start = start(tn, ty);
        vars.push(v);
    }
    Ok(vars)
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

fn unknowns(parent: Node, vars: &[Variable]) -> Vec<Unknown> {
    children(parent, "Unknown")
        .filter_map(|u| {
            let index = u32_attr(u, "index")?;
            Some(Unknown {
                value_reference: index_to_vr(vars, index)?,
                index,
                dependencies: list_attr::<u32>(u, "dependencies").map(|d| {
                    d.into_iter().filter_map(|ix| index_to_vr(vars, ix)).collect()
                }),
                dependencies_kind: dependencies_kind(u),
            })
        })
        .collect()
}

fn model_structure(root: Node, vars: &[Variable]) -> ModelStructure {
    let Some(ms) = child(root, "ModelStructure") else { return ModelStructure::default() };
    let group = |name| child(ms, name).map(|g| unknowns(g, vars)).unwrap_or_default();
    ModelStructure {
        outputs: group("Outputs"),
        continuous_state_derivatives: group("Derivatives"),
        initial_unknowns: group("InitialUnknowns"),
        ..Default::default()
    }
}

fn units(root: Node) -> Vec<Unit> {
    let Some(uds) = child(root, "UnitDefinitions") else { return Vec::new() };
    children(uds, "Unit")
        .filter_map(|u| {
            Some(Unit {
                name: attr(u, "name")?.to_string(),
                base_unit: child(u, "BaseUnit").map(base_unit),
                display_units: children(u, "DisplayUnit")
                    .filter_map(|d| {
                        Some(DisplayUnit {
                            name: attr(d, "name")?.to_string(),
                            factor: f64_attr(d, "factor").unwrap_or(1.0),
                            offset: f64_attr(d, "offset").unwrap_or(0.0),
                            inverse: false,
                        })
                    })
                    .collect(),
            })
        })
        .collect()
}

fn base_unit(n: Node) -> BaseUnit {
    let e = |name| i32_attr(n, name).unwrap_or(0);
    BaseUnit {
        kg: e("kg"),
        m: e("m"),
        s: e("s"),
        a: e("A"),
        k: e("K"),
        mol: e("mol"),
        cd: e("cd"),
        rad: e("rad"),
        factor: f64_attr(n, "factor").unwrap_or(1.0),
        offset: f64_attr(n, "offset").unwrap_or(0.0),
    }
}

fn type_definitions(root: Node) -> Vec<TypeDefinition> {
    let Some(tds) = child(root, "TypeDefinitions") else { return Vec::new() };
    children(tds, "SimpleType")
        .filter_map(|t| {
            let name = attr(t, "name")?.to_string();
            let d = t.children().filter(Node::is_element).find_map(|c| {
                var_type(c.tag_name().name()).map(|ty| (c, ty))
            })?;
            let (n, ty) = d;
            Some(TypeDefinition {
                name,
                ty,
                description: string_attr(t, "description"),
                quantity: string_attr(n, "quantity"),
                unit: string_attr(n, "unit"),
                display_unit: string_attr(n, "displayUnit"),
                relative_quantity: bool_attr(n, "relativeQuantity", false),
                unbounded: bool_attr(n, "unbounded", false),
                min: f64_attr(n, "min"),
                max: f64_attr(n, "max"),
                nominal: f64_attr(n, "nominal"),
                items: children(n, "Item")
                    .filter_map(|i| {
                        Some(EnumerationItem {
                            name: attr(i, "name")?.to_string(),
                            value: attr(i, "value")?.trim().parse().ok()?,
                            description: string_attr(i, "description"),
                        })
                    })
                    .collect(),
            })
        })
        .collect()
}

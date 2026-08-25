//! FMI 3.0 `modelDescription.xml`.

use super::*;

pub fn parse(root: Node) -> Result<ModelDescription> {
    let mut md = ModelDescription {
        fmi_version: FmiVersion::Fmi3,
        model_name: required(root, "modelName")?.to_string(),
        instantiation_token: required(root, "instantiationToken")?.to_string(),
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
        scheduled_execution: child(root, "ScheduledExecution").map(interface).transpose()?,
        default_experiment: default_experiment(root),
        units: units(root),
        type_definitions: type_definitions(root),
        log_categories: log_categories(root),
        ..Default::default()
    };
    md.variables = variables(root)?;
    md.model_structure = model_structure(root);
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
        can_get_and_set_state: bool_attr(n, "canGetAndSetFMUState", false),
        can_serialize_state: bool_attr(n, "canSerializeFMUState", false),
        provides_directional_derivatives: bool_attr(n, "providesDirectionalDerivatives", false),
        provides_adjoint_derivatives: bool_attr(n, "providesAdjointDerivatives", false),
        provides_per_element_dependencies: bool_attr(n, "providesPerElementDependencies", false),
        provides_evaluate_discrete_states: bool_attr(n, "providesEvaluateDiscreteStates", false),
        needs_completed_integrator_step: bool_attr(n, "needsCompletedIntegratorStep", false),
        can_handle_variable_communication_step_size: bool_attr(
            n,
            "canHandleVariableCommunicationStepSize",
            false,
        ),
        fixed_internal_step_size: f64_attr(n, "fixedInternalStepSize"),
        max_output_derivative_order: u32_attr(n, "maxOutputDerivativeOrder").unwrap_or(0),
        recommended_intermediate_input_smoothness: i32_attr(
            n,
            "recommendedIntermediateInputSmoothness",
        )
        .unwrap_or(0),
        provides_intermediate_update: bool_attr(n, "providesIntermediateUpdate", false),
        might_return_early_from_do_step: bool_attr(n, "mightReturnEarlyFromDoStep", false),
        can_return_early_after_intermediate_update: bool_attr(
            n,
            "canReturnEarlyAfterIntermediateUpdate",
            false,
        ),
        has_event_mode: bool_attr(n, "hasEventMode", false),
        ..Default::default()
    })
}

fn var_type(tag: &str) -> Option<VarType> {
    Some(match tag {
        "Float32" => VarType::Float32,
        "Float64" => VarType::Float64,
        "Int8" => VarType::Int8,
        "UInt8" => VarType::UInt8,
        "Int16" => VarType::Int16,
        "UInt16" => VarType::UInt16,
        "Int32" => VarType::Int32,
        "UInt32" => VarType::UInt32,
        "Int64" => VarType::Int64,
        "UInt64" => VarType::UInt64,
        "Boolean" => VarType::Boolean,
        "String" => VarType::String,
        "Binary" => VarType::Binary,
        "Enumeration" => VarType::Enumeration,
        "Clock" => VarType::Clock,
        _ => return None,
    })
}

fn variables(root: Node) -> Result<Vec<Variable>> {
    let mv = child(root, "ModelVariables")
        .ok_or_else(|| Error::Xml("no <ModelVariables>".into()))?;
    let mut vars = Vec::new();
    for n in mv.children().filter(Node::is_element) {
        let Some(ty) = var_type(n.tag_name().name()) else { continue };
        let index = vars.len() as u32 + 1;
        let vr = required(n, "valueReference")?
            .trim()
            .parse()
            .map_err(|_| Error::Xml("valueReference is not a number".into()))?;
        let mut v = blank_variable(required(n, "name")?.to_string(), vr, index, ty);
        v.description = string_attr(n, "description");
        v.causality = causality(attr(n, "causality"), Causality::Local);
        // No schema default: continuous only makes sense for the float types.
        v.variability = variability(
            attr(n, "variability"),
            match (ty, v.causality) {
                (_, Causality::StructuralParameter) => Variability::Fixed,
                (VarType::Float32 | VarType::Float64, _) => Variability::Continuous,
                _ => Variability::Discrete,
            },
        );
        v.initial = initial(attr(n, "initial"));
        v.declared_type = string_attr(n, "declaredType");
        v.quantity = string_attr(n, "quantity");
        v.unit = string_attr(n, "unit");
        v.display_unit = string_attr(n, "displayUnit");
        v.relative_quantity = bool_attr(n, "relativeQuantity", false);
        v.unbounded = bool_attr(n, "unbounded", false);
        v.min = f64_attr(n, "min");
        v.max = f64_attr(n, "max");
        v.nominal = f64_attr(n, "nominal");
        v.derivative = u32_attr(n, "derivative");
        v.reinit = bool_attr(n, "reinit", false);
        v.previous = u32_attr(n, "previous");
        v.intermediate_update = bool_attr(n, "intermediateUpdate", false);
        v.clocks = list_attr(n, "clocks").unwrap_or_default();
        v.can_handle_multiple_set_per_time_instant =
            bool_attr(n, "canHandleMultipleSetPerTimeInstant", true);
        v.dimensions = children(n, "Dimension")
            .map(|d| match u64_attr(d, "start") {
                Some(k) => Dimension::Fixed(k),
                None => Dimension::ValueReference(u32_attr(d, "valueReference").unwrap_or(0)),
            })
            .collect();
        v.start = start(n, ty);
        v.clock = (ty == VarType::Clock).then(|| clock_info(n));
        v.aliases = children(n, "Alias")
            .filter_map(|a| {
                Some(VariableAlias {
                    name: attr(a, "name")?.to_string(),
                    description: string_attr(a, "description"),
                    display_unit: string_attr(a, "displayUnit"),
                })
            })
            .collect();
        vars.push(v);
    }
    Ok(vars)
}

/// FMI 3.0 puts an array's start values in one whitespace-separated attribute;
/// `String` and `Binary` use one `<Start value=…>` element per element instead.
fn start(n: Node, ty: VarType) -> Option<Start> {
    match ty {
        VarType::String => {
            let v: Vec<String> = children(n, "Start")
                .map(|s| attr(s, "value").unwrap_or_default().to_string())
                .collect();
            (!v.is_empty()).then_some(Start::Strings(v))
        }
        VarType::Binary => {
            let v: Vec<Vec<u8>> = children(n, "Start")
                .map(|s| hex_bytes(attr(s, "value").unwrap_or_default()))
                .collect();
            (!v.is_empty()).then_some(Start::Binaries(v))
        }
        VarType::Float32 | VarType::Float64 => list_attr(n, "start").map(Start::Reals),
        VarType::Boolean => attr(n, "start").map(|s| {
            Start::Bools(s.split_whitespace().map(|b| b == "true" || b == "1").collect())
        }),
        VarType::Clock => None,
        _ => list_attr(n, "start").map(Start::Ints),
    }
}

fn hex_bytes(s: &str) -> Vec<u8> {
    let d: Vec<u8> = s.bytes().filter(|b| !b.is_ascii_whitespace()).collect();
    d.chunks_exact(2)
        .filter_map(|p| u8::from_str_radix(std::str::from_utf8(p).ok()?, 16).ok())
        .collect()
}

fn clock_info(n: Node) -> ClockInfo {
    ClockInfo {
        interval_variability: match attr(n, "intervalVariability") {
            Some("constant") => IntervalVariability::Constant,
            Some("fixed") => IntervalVariability::Fixed,
            Some("tunable") => IntervalVariability::Tunable,
            Some("changing") => IntervalVariability::Changing,
            Some("countdown") => IntervalVariability::Countdown,
            _ => IntervalVariability::Triggered,
        },
        can_be_deactivated: bool_attr(n, "canBeDeactivated", false),
        priority: u32_attr(n, "priority"),
        interval_decimal: f64_attr(n, "intervalDecimal"),
        shift_decimal: f64_attr(n, "shiftDecimal").unwrap_or(0.0),
        supports_fraction: bool_attr(n, "supportsFraction", false),
        resolution: u64_attr(n, "resolution"),
        interval_counter: u64_attr(n, "intervalCounter"),
        shift_counter: u64_attr(n, "shiftCounter").unwrap_or(0),
    }
}

fn unknowns(ms: Node, tag: &'static str) -> Vec<Unknown> {
    children(ms, tag)
        .filter_map(|u| {
            Some(Unknown {
                value_reference: u32_attr(u, "valueReference")?,
                index: 0,
                dependencies: list_attr(u, "dependencies"),
                dependencies_kind: dependencies_kind(u),
            })
        })
        .collect()
}

fn model_structure(root: Node) -> ModelStructure {
    let Some(ms) = child(root, "ModelStructure") else { return ModelStructure::default() };
    ModelStructure {
        outputs: unknowns(ms, "Output"),
        continuous_state_derivatives: unknowns(ms, "ContinuousStateDerivative"),
        clocked_states: unknowns(ms, "ClockedState"),
        initial_unknowns: unknowns(ms, "InitialUnknown"),
        event_indicators: unknowns(ms, "EventIndicator"),
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
                            inverse: bool_attr(d, "inverse", false),
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

/// FMI 3.0 type definitions are `<Float64Type>`, `<EnumerationType>`, … — the
/// variable element name with `Type` appended.
fn type_definitions(root: Node) -> Vec<TypeDefinition> {
    let Some(tds) = child(root, "TypeDefinitions") else { return Vec::new() };
    tds.children()
        .filter(Node::is_element)
        .filter_map(|t| {
            let tag = t.tag_name().name();
            let ty = var_type(tag.strip_suffix("Type")?)?;
            Some(TypeDefinition {
                name: attr(t, "name")?.to_string(),
                ty,
                description: string_attr(t, "description"),
                quantity: string_attr(t, "quantity"),
                unit: string_attr(t, "unit"),
                display_unit: string_attr(t, "displayUnit"),
                relative_quantity: bool_attr(t, "relativeQuantity", false),
                unbounded: bool_attr(t, "unbounded", false),
                min: f64_attr(t, "min"),
                max: f64_attr(t, "max"),
                nominal: f64_attr(t, "nominal"),
                items: children(t, "Item")
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

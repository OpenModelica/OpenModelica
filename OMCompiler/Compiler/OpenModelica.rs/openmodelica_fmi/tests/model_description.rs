//! What each FMI version's `modelDescription.xml` turns into, especially where
//! the versions differ and the parser normalises.

use openmodelica_fmi::*;

const FMI3: &str = r#"<?xml version="1.0" encoding="UTF-8"?>
<fmiModelDescription fmiVersion="3.0" modelName="M" instantiationToken="{tok}">
  <ModelExchange modelIdentifier="M" needsCompletedIntegratorStep="true"/>
  <CoSimulation modelIdentifier="M" hasEventMode="true" mightReturnEarlyFromDoStep="true"
                fixedInternalStepSize="0.1"/>
  <UnitDefinitions>
    <Unit name="rad"><BaseUnit rad="1"/><DisplayUnit name="deg" factor="57.29"/></Unit>
  </UnitDefinitions>
  <TypeDefinitions>
    <Float64Type name="Angle" quantity="Angle" unit="rad"/>
  </TypeDefinitions>
  <DefaultExperiment startTime="0" stopTime="3" stepSize="0.01"/>
  <ModelVariables>
    <Float64 name="time" valueReference="0" causality="independent"/>
    <Float64 name="h" valueReference="1" start="1" declaredType="Angle"/>
    <Float64 name="der(h)" valueReference="2" derivative="1"/>
    <Float64 name="v" valueReference="3" start="0 1 2">
      <Dimension start="3"/>
    </Float64>
    <Boolean name="b" valueReference="4" start="true"/>
    <Int32 name="n" valueReference="5" causality="parameter" start="7"/>
  </ModelVariables>
  <ModelStructure>
    <ContinuousStateDerivative valueReference="2" dependencies="1 3"/>
    <EventIndicator valueReference="1"/>
  </ModelStructure>
</fmiModelDescription>"#;

const FMI2: &str = r#"<?xml version="1.0" encoding="UTF-8"?>
<fmiModelDescription fmiVersion="2.0" modelName="M" guid="{tok}" numberOfEventIndicators="2">
  <ModelExchange modelIdentifier="M" completedIntegratorStepNotNeeded="true"/>
  <ModelVariables>
    <ScalarVariable name="h" valueReference="1" causality="local">
      <Real start="1" unit="m"/>
    </ScalarVariable>
    <ScalarVariable name="der(h)" valueReference="2"><Real derivative="1"/></ScalarVariable>
    <ScalarVariable name="k" valueReference="3" causality="parameter" variability="fixed">
      <Real start="0.5"/>
    </ScalarVariable>
  </ModelVariables>
  <ModelStructure>
    <Derivatives><Unknown index="2" dependencies="1 3"/></Derivatives>
    <InitialUnknowns><Unknown index="2"/></InitialUnknowns>
  </ModelStructure>
</fmiModelDescription>"#;

const FMI1: &str = r#"<?xml version="1.0" encoding="UTF-8"?>
<fmiModelDescription fmiVersion="1.0" modelName="M" modelIdentifier="M" guid="{tok}"
                     numberOfContinuousStates="1" numberOfEventIndicators="1">
  <UnitDefinitions>
    <BaseUnit unit="rad"><DisplayUnitDefinition displayUnit="deg" gain="57.29"/></BaseUnit>
  </UnitDefinitions>
  <ModelVariables>
    <ScalarVariable name="h" valueReference="1" causality="output">
      <Real start="1" fixed="true" unit="m"/>
      <DirectDependency><Name>k</Name></DirectDependency>
    </ScalarVariable>
    <ScalarVariable name="k" valueReference="2" variability="parameter">
      <Real start="0.5"/>
    </ScalarVariable>
    <ScalarVariable name="minus_h" valueReference="1" alias="negatedAlias">
      <Real/>
    </ScalarVariable>
  </ModelVariables>
</fmiModelDescription>"#;

#[test]
fn fmi3_keeps_what_only_3_0_has() {
    let md = model_description(FMI3).expect("parse");
    assert_eq!(md.fmi_version, FmiVersion::Fmi3);
    assert_eq!(md.instantiation_token, "{tok}");
    let cs = md.co_simulation.as_ref().expect("CoSimulation");
    assert!(cs.has_event_mode && cs.might_return_early_from_do_step);
    assert_eq!(cs.fixed_internal_step_size, Some(0.1));
    assert!(md.model_exchange.as_ref().unwrap().needs_completed_integrator_step);
    // An `<EventIndicator>` per crossing rather than a count attribute.
    assert_eq!(md.number_of_event_indicators, 1);
    assert_eq!(md.continuous_states(), vec![1]);
    let v = md.variable_by_name("v").unwrap();
    assert_eq!(v.fixed_len(), Some(3));
    assert_eq!(v.start, Some(Start::Reals(vec![0.0, 1.0, 2.0])));
    assert_eq!(md.variable_by_name("b").unwrap().start, Some(Start::Bools(vec![true])));
    // The unit comes from the declared type.
    assert_eq!(md.variable_by_name("h").unwrap().unit.as_deref(), Some("rad"));
    assert_eq!(md.time_variable().map(|v| v.name.as_str()), Some("time"));
}

#[test]
fn fmi2_indices_become_value_references() {
    let md = model_description(FMI2).expect("parse");
    assert_eq!(md.fmi_version, FmiVersion::Fmi2);
    assert_eq!(md.instantiation_token, "{tok}");
    // `derivative="1"` is the *index* of h in `<ModelVariables>`, which becomes
    // the value reference of the state der(h) differentiates.
    assert_eq!(md.variable_by_name("der(h)").unwrap().derivative, Some(1));
    assert_eq!(md.continuous_states(), vec![1]);
    let d = &md.model_structure.continuous_state_derivatives[0];
    assert_eq!(d.value_reference, 2);
    assert_eq!(d.dependencies, Some(vec![1, 3]));
    assert_eq!(md.number_of_event_indicators, 2);
    // `completedIntegratorStepNotNeeded` is the inverse of the 3.0 attribute.
    assert!(!md.model_exchange.as_ref().unwrap().needs_completed_integrator_step);
    assert_eq!(md.variable_by_name("h").unwrap().ty, VarType::Float64);
}

#[test]
fn fmi1_parameters_and_aliases() {
    let md = model_description(FMI1).expect("parse");
    assert_eq!(md.fmi_version, FmiVersion::Fmi1);
    assert!(md.model_exchange.is_some() && md.co_simulation.is_none());
    assert_eq!(md.number_of_continuous_states(), 1);
    // 1.0's `variability="parameter"` is 2.0's `causality="parameter"`.
    let k = md.variable_by_name("k").unwrap();
    assert_eq!(k.causality, Causality::Parameter);
    assert_eq!(k.variability, Variability::Fixed);
    assert_eq!(md.variable_by_name("minus_h").unwrap().alias, Alias::NegatedAlias);
    // An alias shares the value reference; lookups find the variable itself.
    assert_eq!(md.variable_by_vr(1).map(|v| v.name.as_str()), Some("h"));
    // `<DirectDependency>` is 2.0's `<Outputs>` with dependencies.
    let out = &md.model_structure.outputs;
    assert_eq!(out.len(), 1);
    assert_eq!(out[0].dependencies, Some(vec![2]));
    assert_eq!(md.units[0].display_units[0].factor, 57.29);
}

#[test]
fn a_co_simulation_only_fmi1_fmu_reads_its_capabilities() {
    let xml = FMI1.replace(
        "<ModelVariables>",
        "<Implementation><CoSimulation_StandAlone><Capabilities \
         canHandleVariableCommunicationStepSize=\"true\" canHandleEvents=\"true\" \
         maxOutputDerivativeOrder=\"2\"/></CoSimulation_StandAlone></Implementation>\
         <ModelVariables>",
    );
    let md = model_description(&xml).expect("parse");
    let cs = md.co_simulation.as_ref().expect("CoSimulation");
    assert!(cs.can_handle_variable_communication_step_size && cs.can_handle_events);
    assert_eq!(cs.max_output_derivative_order, 2);
    assert!(md.model_exchange.is_none());
}

#[test]
fn a_malformed_description_is_rejected_with_a_reason() {
    assert!(model_description("<nope/>").is_err());
    assert!(model_description(r#"<fmiModelDescription fmiVersion="4.0"/>"#).is_err());
    // No modelName.
    assert!(model_description(r#"<fmiModelDescription fmiVersion="3.0"/>"#).is_err());
}

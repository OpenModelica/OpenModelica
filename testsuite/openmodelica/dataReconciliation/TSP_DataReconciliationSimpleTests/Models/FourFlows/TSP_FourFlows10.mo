within TSP_DataReconciliationSimpleTests.Models.FourFlows;
model TSP_FourFlows10
  parameter Boolean specific_enthalpy_as_state_variable=true;
  Components.BoundaryConditions.Sink sink1(
    h0=1e6)
    annotation (Placement(visible=true,transformation(origin={90,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      start=15e5,
      uncertain=Uncertainty.refine),
    Q(
      start=100.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=473),
    deltaP(
      start=1.e5),
    flow_reversal=false,
    h(
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={-50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa",
      start=15e5,
      uncertain=Uncertainty.refine),
    Q(
      start=100,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=470),
    deltaP(
      start=1.e5),
    flow_reversal=false,
    h(
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={0,20},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss3(
    Pm(
      displayUnit="Pa",
      start=15e5,
      uncertain=Uncertainty.refine),
    Q(
      start=99,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=465),
    deltaP(
      start=1.e5),
    flow_reversal=false,
    h(
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={0,-20},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss4(
    Pm(
      displayUnit="Pa",
      start=15e5,
      uncertain=Uncertainty.refine),
    Q(
      start=98,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=472),
    deltaP(
      start=1.e5),
    flow_reversal=false,
    h(
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={60,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.VolumeATh staticDrum1(
    P(
      displayUnit="Pa",
      start=2900000,
      uncertain=Uncertainty.refine),
    T(
      start=473),
    h(
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=specific_enthalpy_as_state_variable)
    annotation (Placement(visible=true,transformation(origin={-22,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.VolumeATh staticDrum2(
    P(
      displayUnit="Pa",
      start=2500000,
      uncertain=Uncertainty.refine),
    T(
      start=471),
    h(
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=specific_enthalpy_as_state_variable)
    annotation (Placement(visible=true,transformation(origin={28,0},extent={{-10,-10},{10,10}},rotation=90)));
  Components.BoundaryConditions.SourcePQ source1(
    P0=3000000,
    Q0=100,
    h0=1e6)
    annotation (Placement(visible=true,transformation(origin={-90,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(singularPressureLoss4.C2,sink1.C)
    annotation (Line(points={{70,0},{80,0}},color={0,0,255}));
  connect(source1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-80,0},{-60,0},{-60,0},{-60,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,staticDrum1.Ce1)
    annotation (Line(points={{-40,0},{-32,0}},color={0,0,255}));
  connect(staticDrum1.Cs2,singularPressureLoss3.C1)
    annotation (Line(points={{-22,-10},{-24,-10},{-24,-20},{-10,-20}},color={0,0,255}));
  connect(staticDrum1.Cs1,singularPressureLoss2.C1)
    annotation (Line(points={{-12,0},{-10,0},{-10,20}},color={0,0,255}));
  connect(singularPressureLoss2.C2,staticDrum2.Ce2)
    annotation (Line(points={{10,20},{18,20},{18,0}},color={0,0,255}));
  connect(singularPressureLoss3.C2,staticDrum2.Ce1)
    annotation (Line(points={{10,-20},{28,-20},{28,-10}},color={0,0,255}));
  connect(staticDrum2.Cs2,singularPressureLoss4.C1)
    annotation (Line(points={{38,0},{50,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_FourFlows10_Inputs.csv"));
end TSP_FourFlows10;

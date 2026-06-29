within TSP_DataReconciliationSimpleTests.Models.Pipe;
model TSP_Pipe6
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=1.2e5,
      uncertain=Uncertainty.refine),
    h(
      start=100000),
    p_rho=990000,
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={-30,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=1.2e5,
      uncertain=Uncertainty.refine),
    h(
      start=100000),
    p_rho=990000,
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={32,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP1(
    option_temperature=2)
    annotation (Placement(visible=true,transformation(origin={-70,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkP sinkP1(
    option_temperature=2)
    annotation (Placement(visible=true,transformation(origin={72,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.VolumeATh volumeB1(
    P(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    T(
      start=1.2e5,
      uncertain=Uncertainty.refine),
    h(
      start=100000),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={0,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(sourceP1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-60,0},{-40,0},{-40,0},{-40,0}},color={0,0,255}));
  connect(singularPressureLoss2.C2,sinkP1.C)
    annotation (Line(points={{42,0},{62,0},{62,0},{62,0},{62,0},{62,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,volumeB1.Ce1)
    annotation (Line(points={{-20,0},{-10,0}},color={0,0,255}));
  connect(volumeB1.Cs1,singularPressureLoss2.C1)
    annotation (Line(points={{10,0},{22,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Pipe6_Inputs.csv"));
end TSP_Pipe6;

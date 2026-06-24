within TSP_DataReconciliationSimpleTests.Models.FourFlows;
model TSP_FourFlows3
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa"),
    Q(
      start=100.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa"),
    Q(
      start=50.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={0,20},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss3(
    Pm(
      displayUnit="Pa"),
    Q(
      start=49.0,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={0,-20},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss4(
    Pm(
      displayUnit="Pa"),
    Q(
      start=99.5,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    flow_reversal=false,
    rho(
      displayUnit="kg/m3"),
    specific_enthalpy_as_state_variable=false)
    annotation (Placement(visible=true,transformation(origin={50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP1
    annotation (Placement(visible=true,transformation(origin={-90,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkP sinkP1
    annotation (Placement(visible=true,transformation(origin={92,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.VolumeATh volumeB1
    annotation (Placement(visible=true,transformation(origin={-20,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.VolumeATh volumeB2(
    P(
      displayUnit="Pa"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={20,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(sourceP1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-80,0},{-60,0},{-60,0},{-60,0}},color={0,0,255}));
  connect(singularPressureLoss4.C2,sinkP1.C)
    annotation (Line(points={{60,0},{82,0},{82,0},{82,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,volumeB1.Ce1)
    annotation (Line(points={{-40,0},{-30,0}},color={0,0,255}));
  connect(volumeB1.Cs1,singularPressureLoss2.C1)
    annotation (Line(points={{-10,0},{-10,20}},color={0,0,255}));
  connect(volumeB1.Cs2,singularPressureLoss3.C1)
    annotation (Line(points={{-20,-10},{-20,-20},{-10,-20}},color={0,0,255}));
  connect(singularPressureLoss3.C2,volumeB2.Ce1)
    annotation (Line(points={{10,-20},{10,0}},color={0,0,255}));
  connect(singularPressureLoss2.C2,volumeB2.Ce2)
    annotation (Line(points={{10,20},{20,20},{20,10}},color={0,0,255}));
  connect(volumeB2.Cs1,singularPressureLoss4.C1)
    annotation (Line(points={{30,0},{40,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_FourFlows3_Inputs.csv"));
end TSP_FourFlows3;

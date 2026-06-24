within TSP_DataReconciliationSimpleTests.Models.Splitter;
model TSP_Splitter1
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={48,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss3(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,-30},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21
    annotation (Placement(visible=true,transformation(origin={3,0},extent={{-9,-10},{9,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP1
    annotation (Placement(visible=true,transformation(origin={-90,30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP2
    annotation (Placement(visible=true,transformation(origin={-90,-30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkP sinkP1
    annotation (Placement(visible=true,transformation(origin={90,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(mixer21.Cs,singularPressureLoss1.C1)
    annotation (Line(points={{12,0},{38,0}},color={0,0,255}));
  connect(sourceP1.C,singularPressureLoss2.C1)
    annotation (Line(points={{-80,30},{-60,30},{-60,30},{-60,30}},color={0,0,255}));
  connect(singularPressureLoss2.C2,mixer21.Ce1)
    annotation (Line(points={{-40,30},{0,30},{0,10},{0,10}},color={0,0,255}));
  connect(sourceP2.C,singularPressureLoss3.C1)
    annotation (Line(points={{-80,-30},{-60,-30},{-60,-30},{-60,-30}},color={0,0,255}));
  connect(singularPressureLoss3.C2,mixer21.Ce2)
    annotation (Line(points={{-40,-30},{0,-30},{0,-10},{0,-10}},color={0,0,255}));
  connect(singularPressureLoss1.C2,sinkP1.C)
    annotation (Line(points={{58,0},{80,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Splitter1_Inputs.csv"));
end TSP_Splitter1;

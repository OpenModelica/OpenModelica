within TSP_DataReconciliationSimpleTests.Models.Pipe;
model TSP_Pipe12
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=320,
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-60,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=320),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={64,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP1
    annotation (Placement(visible=true,transformation(origin={-94,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkP sinkP1
    annotation (Placement(visible=true,transformation(origin={94,0},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Junctions.MassFlowMultiplier volume(
    P(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    T(
      uncertain=Uncertainty.refine),
    alpha=1,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={4,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(volume.Cs,singularPressureLoss2.C1)
    annotation (Line(points={{14,0},{54,0}},color={0,0,255}));
  connect(singularPressureLoss2.C2,sinkP1.C)
    annotation (Line(points={{74,0},{84,0}},color={0,0,255}));
  connect(sourceP1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-84,0},{-70,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,volume.Ce)
    annotation (Line(points={{-50,0},{-6,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Pipe12_Inputs.csv"));
end TSP_Pipe12;

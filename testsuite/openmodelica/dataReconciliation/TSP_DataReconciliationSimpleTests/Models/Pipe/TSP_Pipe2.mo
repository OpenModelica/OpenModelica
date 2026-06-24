within TSP_DataReconciliationSimpleTests.Models.Pipe;
model TSP_Pipe2
  "OK? - Pressures correctly reconciled?"
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      start=1e5,
      uncertain=Uncertainty.refine),
    Q(
      start=100.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=290,
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-49,0},extent={{-9,-10},{9,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa",
      start=1e5,
      uncertain=Uncertainty.refine),
    Q(
      start=99.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=290,
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP1(
    P0=217000,
    T0(
      displayUnit="K"))
    annotation (Placement(visible=true,transformation(origin={-90,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkP sinkP1(
    P0=200000)
    annotation (Placement(visible=true,transformation(origin={90,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.VolumeATh volumeATh(
    P(
      displayUnit="Pa",
      start=1e5,
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={2,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(sourceP1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-80,0},{-58,0}},color={0,0,255}));
  connect(singularPressureLoss2.C2,sinkP1.C)
    annotation (Line(points={{60,0},{80,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,volumeATh.Ce1)
    annotation (Line(points={{-40,0},{-8,0}},color={0,0,255}));
  connect(volumeATh.Cs1,singularPressureLoss2.C1)
    annotation (Line(points={{12,0},{40,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Pipe2_Inputs.csv"));
end TSP_Pipe2;

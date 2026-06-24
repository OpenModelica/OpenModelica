within TSP_DataReconciliationSimpleTests.Models.Pipe;
model TSP_Pipe5
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-30,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={30,20},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceP sourceP1
    annotation (Placement(visible=true,transformation(origin={-70,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkP sinkP1
    annotation (Placement(visible=true,transformation(origin={70,20},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Volumes.VolumeB volumeB1(
    P(
      uncertain=Uncertainty.refine))
    annotation (Placement(visible=true,transformation(origin={0,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(sourceP1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-60,0},{-40,0},{-40,0},{-40,0}},color={0,0,255}));
  connect(singularPressureLoss2.C2,sinkP1.C)
    annotation (Line(points={{40,20},{60,20},{60,20},{60,20},{60,20},{60,20}},color={0,0,255}));
  connect(singularPressureLoss1.C2,volumeB1.Ce1)
    annotation (Line(points={{-20,0},{-10,0}},color={0,0,255}));
  connect(volumeB1.Cs1,singularPressureLoss2.C1)
    annotation (Line(points={{0,10},{0,10},{0,20},{20,20},{20,20}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Pipe5_Inputs.csv"));
end TSP_Pipe5;

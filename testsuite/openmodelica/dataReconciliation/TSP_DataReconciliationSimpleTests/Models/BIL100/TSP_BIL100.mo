within TSP_DataReconciliationSimpleTests.Models.BIL100;
model TSP_BIL100
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      start=29e5,
      uncertain=Uncertainty.refine),
    Q(
      start=2,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=510,
      uncertain=Uncertainty.refine),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={50,-26},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa",
      start=29e5,
      uncertain=Uncertainty.refine),
    Q(
      start=1,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=510,
      uncertain=Uncertainty.refine),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss3(
    Pm(
      displayUnit="Pa",
      start=84e5,
      uncertain=Uncertainty.refine),
    Q(
      start=1,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K",
      start=920,
      uncertain=Uncertainty.refine),
    fluid=3,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={52,20},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourcePQ sourceQ2(
    P0=9000000,
    h0=6e6)
    annotation (Placement(visible=true,transformation(origin={-90,30},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Junctions.StaticDrum staticDrum1(
    P(
      displayUnit="Pa",
      start=29e5,
      uncertain=Uncertainty.refine),
    T(
      start=505,
      uncertain=Uncertainty.refine),
    hl(
      start=1e6),
    hv(
      start=2e6),
    x=0.99)
    annotation (Placement(visible=true,transformation(origin={0,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.Sink sink1(
    h0=2e6)
    annotation (Placement(visible=true,transformation(origin={90,-26},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink
    annotation (Placement(visible=true,transformation(origin={0,78},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ(
    Q0=95)
    annotation (Placement(visible=true,transformation(origin={92,20},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(sourceQ2.C,singularPressureLoss2.C1)
    annotation (Line(points={{-80,30},{-60,30},{-60,30},{-60,30}},color={0,0,255}));
  connect(singularPressureLoss2.C2,staticDrum1.Ce_steam)
    annotation (Line(points={{-40,30},{-4,30},{-4,10},{-4,10}},color={0,0,255}));
  connect(singularPressureLoss1.C2,sink1.C)
    annotation (Line(points={{60,-26},{80,-26},{80,-26},{80,-26}},color={0,0,255}));
  connect(staticDrum1.Cs_sur,singularPressureLoss3.C1)
    annotation (Line(points={{4,10},{4,20},{42,20}},color={0,0,255}));
  connect(staticDrum1.Cs_eva,singularPressureLoss1.C1)
    annotation (Line(points={{4,-10},{4,-26},{40,-26}},color={0,0,255}));
  connect(singularPressureLoss3.C2,sinkQ.C)
    annotation (Line(points={{62,20},{82,20}},color={0,0,255}));
  connect(staticDrum1.Cth,heatSink.C[1])
    annotation (Line(points={{0,0},{0,68}}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_STDOUT,LOG_ASSERT,LOG_STATS",
      s="dassl",
      sx="modelica://EDF_NewDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_BIL100_Inputs.csv"));
end TSP_BIL100;

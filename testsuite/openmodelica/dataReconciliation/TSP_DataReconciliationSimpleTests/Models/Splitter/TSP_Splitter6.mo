within TSP_DataReconciliationSimpleTests.Models.Splitter;
model TSP_Splitter6
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      start=230e5,
      uncertain=Uncertainty.refine),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    flow_reversal=false,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa",
      start=230e5,
      uncertain=Uncertainty.refine),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    flow_reversal=false,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss3(
    Pm(
      displayUnit="Pa",
      start=230e5,
      uncertain=Uncertainty.refine),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    flow_reversal=false,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,-30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceQ sourceQ3(
    h0=2e6)
    annotation (Placement(visible=true,transformation(origin={-90,-30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourceQ sourceQ2(
    h0=2e6)
    annotation (Placement(visible=true,transformation(origin={-90,30},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.WaterSteam.Junctions.StaticDrum staticDrum1(
    P(
      displayUnit="Pa",
      start=230e5,
      uncertain=Uncertainty.refine),
    T(
      start=673,
      uncertain=Uncertainty.refine),
    hl(
      start=2e6),
    hv(
      start=2e6))
    annotation (Placement(visible=true,transformation(origin={0,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.Sink sink1(
    h0=2e6)
    annotation (Placement(visible=true,transformation(origin={90,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(sourceQ3.C,singularPressureLoss3.C1)
    annotation (Line(points={{-80,-30},{-60,-30},{-60,-30},{-60,-30}},color={0,0,255}));
  connect(sourceQ2.C,singularPressureLoss2.C1)
    annotation (Line(points={{-80,30},{-60,30},{-60,30},{-60,30}},color={0,0,255}));
  connect(singularPressureLoss2.C2,staticDrum1.Ce_steam)
    annotation (Line(points={{-40,30},{-4,30},{-4,10},{-4,10}},color={0,0,255}));
  connect(singularPressureLoss3.C2,staticDrum1.Ce_eco)
    annotation (Line(points={{-40,-30},{-4,-30},{-4,-10},{-4,-10}},color={0,0,255}));
  connect(staticDrum1.Cs_sup,singularPressureLoss1.C1)
    annotation (Line(points={{10,4},{20,4},{20,0},{40,0},{40,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,sink1.C)
    annotation (Line(points={{60,0},{80,0},{80,0},{80,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Splitter6_Inputs.csv"));
end TSP_Splitter6;

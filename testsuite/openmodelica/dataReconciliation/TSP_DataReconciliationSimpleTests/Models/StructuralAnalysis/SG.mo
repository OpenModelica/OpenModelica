within TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis;
model SG
  TSP_DataReconciliationSimpleTests.Components.BoundaryConditions.SourcePQ Source_ARE(
    C.h(
      start=1e6),
    P0=7.1e6,
    Q0=550,
    h0=0.98e6)
    annotation (Placement(transformation(origin={0,-86},extent={{-100,20},{-80,40}})));
  TSP_DataReconciliationSimpleTests.Components.BoundaryConditions.Sink Puit_VVP(
    C.h(
      start=2.7e6),
    h0=2.7e6)
    annotation (Placement(transformation(extent={{60,20},{80,40}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.PressureLoss.SingularPressureLoss_KDR singularPressureLoss_ARE(
    h(
      start=1e6),
    Pm(
      start=6.9e6),
    rho(
      start=835),
    p_rho(
      displayUnit="kg/m3"))
    annotation (Placement(transformation(origin={-34,-86},extent={{-20,20},{0,40}})));
  TSP_DataReconciliationSimpleTests.Components.Volumes.StaticDrum staticDrum(
    P(
      start=68e5
    /*,uncertain = Uncertainty.refine*/
    ))
    annotation (Placement(transformation(origin={-12,0},extent={{-10,-10},{10,10}})));
  TSP_DataReconciliationSimpleTests.Components.PressureLoss.SingularPressureLoss_KDR singularPressureLoss_purge(
    K=1e4,
    p_rho(
      displayUnit="kg/m3")=800)
    annotation (Placement(transformation(origin={36,-42},extent={{-20,20},{0,40}})));
  TSP_DataReconciliationSimpleTests.Components.PressureLoss.SingularPressureLoss_KDR singularPressureLoss_VVP(
    Q(
      start=500),
    rho(
      start=35),
    Pm(
      start=6.5e6),
    h(
      start=2.7e6))
    annotation (Placement(transformation(origin={36,0},extent={{-20,20},{0,40}})));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink
    annotation (Placement(transformation(origin={-46,30},extent={{-10,-10},{10,10}})));
  TSP_DataReconciliationSimpleTests.Components.BoundaryConditions.SinkQ Puit_purge(
    C.h(
      start=1.2e6),
    Q0=5,
    h0=1.2e6)
    annotation (Placement(transformation(origin={66,-12},extent={{-10,-10},{10,10}})));
equation
  connect(Source_ARE.C,singularPressureLoss_ARE.C1)
    annotation (Line(points={{-80,-56},{-54,-56}},color={0,0,255}));
  connect(singularPressureLoss_ARE.C2,staticDrum.Ce_eco)
    annotation (Line(points={{-34,-56},{-34,-9},{-16,-9}},color={0,0,255}));
  connect(singularPressureLoss_purge.C1,staticDrum.Cs_purg)
    annotation (Line(points={{16,-12},{-3,-12},{-3,-3}},color={0,0,255}));
  connect(singularPressureLoss_VVP.C2,Puit_VVP.C)
    annotation (Line(points={{36,30},{60,30}},color={0,0,255}));
  connect(singularPressureLoss_VVP.C1,staticDrum.Cs_sur)
    annotation (Line(points={{16,30},{16,19.5},{-8,19.5},{-8,9}},color={0,0,255}));
  connect(heatSink.C[1],staticDrum.Cth)
    annotation (Line(points={{-46,20},{-46,0},{-12,0}}));
  connect(singularPressureLoss_purge.C2,Puit_purge.C)
    annotation (Line(points={{36,-12},{56,-12}},color={0,0,255}));
end SG;

within TSP_DataReconciliationSimpleTests.Models.StructuralAnalysis;
model PressureLossModel
  Components.BoundaryConditions.SourcePQ Source_ARE(
    C.h(
      start=1e6),
    P0=7.1e6,
    Q0=550,
    h0=0.98e6)
    annotation (Placement(transformation(origin={0,-86},extent={{-100,20},{-80,40}})));
  Components.PressureLoss.SingularPressureLoss_KDR singularPressureLoss_ARE(
    h(
      start=1e6),
    Pm(
      start=6.9e6),
    rho(
      start=835),
    p_rho(
      displayUnit="kg/m3"))
    annotation (Placement(transformation(origin={-34,-86},extent={{-20,20},{0,40}})));
  Components.BoundaryConditions.Sink Puit_ARE(
    C(
      h(
        start=2.7e6)),
    h0=2.7e6)
    annotation (Placement(transformation(origin={-80,-86},extent={{60,20},{80,40}})));
equation
  connect(Source_ARE.C,singularPressureLoss_ARE.C1)
    annotation (Line(points={{-80,-56},{-54,-56}},color={0,0,255}));
  connect(singularPressureLoss_ARE.C2,Puit_ARE.C)
    annotation (Line(points={{-34,-56},{-20,-56}},color={0,0,255}));
end PressureLossModel;

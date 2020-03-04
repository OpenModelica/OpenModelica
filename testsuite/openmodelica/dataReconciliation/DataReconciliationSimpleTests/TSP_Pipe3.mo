within DataReconciliationSimpleTests;

model TSP_Pipe3
  SourcePQ sourcePQ1 annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Sink sink1 annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss1 (Q(uncertain=Uncertainty.refine), T(uncertain=Uncertainty.refine)) annotation(
    Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss2 (Q(uncertain=Uncertainty.refine), T(uncertain=Uncertainty.refine)) annotation(
    Placement(visible = true, transformation(origin = {2, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss3 (Q(uncertain=Uncertainty.refine), T(uncertain=Uncertainty.refine)) annotation(
    Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(sourcePQ1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-60, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, singularPressureLoss2.C1) annotation(
    Line(points = {{-40, 0}, {-8, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, singularPressureLoss3.C1) annotation(
    Line(points = {{12, 0}, {40, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss3.C2, sink1.C) annotation(
    Line(points = {{60, 0}, {80, 0}, {80, 0}, {80, 0}, {80, 0}}, color = {0, 0, 255}));
end TSP_Pipe3;

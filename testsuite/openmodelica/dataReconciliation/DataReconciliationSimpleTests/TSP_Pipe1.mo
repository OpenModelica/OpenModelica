within DataReconciliationSimpleTests;

model TSP_Pipe1
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss1 (Q(uncertain=Uncertainty.refine))  annotation(
    Placement(visible = true, transformation(origin = {-30, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss2 (Q(uncertain=Uncertainty.refine)) annotation(
    Placement(visible = true, transformation(origin = {30, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SourceP sourceP1 annotation(
    Placement(visible = true, transformation(origin = {-70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SinkP sinkP1 annotation(
    Placement(visible = true, transformation(origin = {70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(singularPressureLoss1.C2, singularPressureLoss2.C1) annotation(
    Line(points = {{-20, 0}, {18, 0}, {18, 0}, {20, 0}, {20, 0}}, color = {0, 0, 255}));
  connect(sourceP1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-60, 0}, {-40, 0}, {-40, 0}, {-40, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, sinkP1.C) annotation(
    Line(points = {{40, 0}, {60, 0}, {60, 0}, {60, 0}}, color = {0, 0, 255}));
end TSP_Pipe1;

within DataReconciliationSimpleTests;

model TSP_Pipe5
  SingularPressureLoss singularPressureLoss1 ( Pm(uncertain=Uncertainty.refine),Q(uncertain=Uncertainty.refine), continuous_flow_reversal = true)  annotation(
    Placement(visible = true, transformation(origin = {-30, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SingularPressureLoss singularPressureLoss2 ( Pm(uncertain=Uncertainty.refine),Q(uncertain=Uncertainty.refine), continuous_flow_reversal = true) annotation(
    Placement(visible = true, transformation(origin = {30, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SourceP sourceP1 annotation(
    Placement(visible = true, transformation(origin = {-70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SinkP sinkP1 annotation(
    Placement(visible = true, transformation(origin = {70, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Volumes.VolumeB volumeB1 (P(uncertain=Uncertainty.refine)) annotation(
    Placement(visible = true, transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(sourceP1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-60, 0}, {-40, 0}, {-40, 0}, {-40, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, sinkP1.C) annotation(
    Line(points = {{40, 20}, {60, 20}, {60, 20}, {60, 20}, {60, 20}, {60, 20}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, volumeB1.Ce1) annotation(
    Line(points = {{-20, 0}, {-10, 0}}, color = {0, 0, 255}));
  connect(volumeB1.Cs1, singularPressureLoss2.C1) annotation(
    Line(points = {{0, 10}, {0, 10}, {0, 20}, {20, 20}, {20, 20}}, color = {0, 0, 255}));
end TSP_Pipe5;

within DataReconciliationSimpleTests;

model TSP_Pipe4
  SingularPressureLoss singularPressureLoss1 (Pm(uncertain = Uncertainty.refine), continuous_flow_reversal = true)  annotation(
    Placement(visible = true, transformation(origin = {-30, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SingularPressureLoss singularPressureLoss2 (Pm(uncertain = Uncertainty.refine), continuous_flow_reversal = true) annotation(
    Placement(visible = true, transformation(origin = {30, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SourcePQ sourcePQ1 annotation(
    Placement(visible = true, transformation(origin = {-72, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Sink sink1 annotation(
    Placement(visible = true, transformation(origin = {72, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Volumes.VolumeB volumeB1 (P(uncertain=Uncertainty.refine)) annotation(
    Placement(visible = true, transformation(origin = { 0, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(sourcePQ1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-62, 0}, {-40, 0}, {-40, 0}, {-40, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, sink1.C) annotation(
    Line(points = {{40, 20}, {62, 20}, {62, 20}, {62, 20}}, color = {0, 0, 255}));
  connect(volumeB1.Cs1, singularPressureLoss2.C1) annotation(
    Line(points = {{0, 9}, {0, 20}, {20, 20}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, volumeB1.Ce1) annotation(
    Line(points = {{-20, 0}, {-10, 0}}, color = {0, 0, 255}));
end TSP_Pipe4;

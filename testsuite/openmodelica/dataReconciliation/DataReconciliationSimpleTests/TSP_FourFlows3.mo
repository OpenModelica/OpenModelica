within DataReconciliationSimpleTests;

model TSP_FourFlows3
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss1(Q(uncertain=Uncertainty.refine, start=100.3)) annotation(
    Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss2(Q(uncertain=Uncertainty.refine, start=50.3)) annotation(
    Placement(visible = true, transformation(origin = {0, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss3(Q(uncertain=Uncertainty.refine, start=49.0)) annotation(
    Placement(visible = true, transformation(origin = {0, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss4(Q(uncertain=Uncertainty.refine, start=99.5)) annotation(
    Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Volumes.VolumeB volumeB1 annotation(
    Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Volumes.VolumeB volumeB2 annotation(
    Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
  SourceP sourceP1 annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SinkP sinkP1 annotation(
    Placement(visible = true, transformation(origin = {92, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(volumeB1.Cs1, singularPressureLoss2.C1) annotation(
    Line(points = {{-20, 10}, {-20, 10}, {-20, 20}, {-10, 20}, {-10, 20}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, volumeB2.Ce1) annotation(
    Line(points = {{10, 20}, {20, 20}, {20, 10}}, color = {0, 0, 255}));
  connect(volumeB1.Cs2, singularPressureLoss3.C1) annotation(
    Line(points = {{-20, -10}, {-20, -10}, {-20, -20}, {-10, -20}, {-10, -20}}, color = {0, 0, 255}));
  connect(singularPressureLoss3.C2, volumeB2.Ce2) annotation(
    Line(points = {{10, -20}, {20, -20}, {20, -10}, {20, -10}}, color = {0, 0, 255}));
  connect(volumeB2.Cs1, singularPressureLoss4.C1) annotation(
    Line(points = {{30, 0}, {40, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, volumeB1.Ce1) annotation(
    Line(points = {{-40, 0}, {-30, 0}, {-30, 0}, {-30, 0}}, color = {0, 0, 255}));
  connect(sourceP1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-60, 0}, {-60, 0}, {-60, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss4.C2, sinkP1.C) annotation(
    Line(points = {{60, 0}, {82, 0}, {82, 0}, {82, 0}}, color = {0, 0, 255}));
end TSP_FourFlows3;

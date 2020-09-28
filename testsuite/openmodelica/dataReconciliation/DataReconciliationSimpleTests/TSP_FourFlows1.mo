within DataReconciliationSimpleTests;

model TSP_FourFlows1
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss1(Q(uncertain=Uncertainty.refine, start=100.3)) annotation(
    Placement(visible = true, transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss2(Q(uncertain=Uncertainty.refine, start=50.3)) annotation(
    Placement(visible = true, transformation(origin = {0, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss3(Q(uncertain=Uncertainty.refine, start=49.0)) annotation(
    Placement(visible = true, transformation(origin = {0, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss singularPressureLoss4(Q(uncertain=Uncertainty.refine, start=99.5)) annotation(
    Placement(visible = true, transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(
    Placement(visible = true, transformation(origin = {-24, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(
    Placement(visible = true, transformation(origin = {24, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Sources.Constante constante1(k = 0.5)  annotation(
    Placement(visible = true, transformation(origin = {-70, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  SourceP sourceP1 annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Sink sink1 annotation(
    Placement(visible = true, transformation(origin = {92, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(singularPressureLoss3.C2, mixer21.Ce2) annotation(
    Line(points = {{10, -20}, {20, -20}, {20, -10}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, mixer21.Ce1) annotation(
    Line(points = {{10, 20}, {20, 20}, {20, 10}}, color = {0, 0, 255}));
  connect(splitter21.Cs1, singularPressureLoss2.C1) annotation(
    Line(points = {{-20, 10}, {-20, 20}, {-10, 20}}, color = {0, 0, 255}));
  connect(splitter21.Cs2, singularPressureLoss3.C1) annotation(
    Line(points = {{-20, -10}, {-20, -20}, {-10, -20}}, color = {0, 0, 255}));
  connect(mixer21.Cs, singularPressureLoss4.C1) annotation(
    Line(points = {{34, 0}, {50, 0}, {50, 2}, {50, 2}, {50, 0}, {50, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, splitter21.Ce) annotation(
    Line(points = {{-50, 0}, {-34, 0}, {-34, 0}, {-34, 0}}, color = {0, 0, 255}));
  connect(constante1.y, splitter21.Ialpha1) annotation(
    Line(points = {{-58, 30}, {-40, 30}, {-40, 6}, {-22, 6}, {-22, 6}}, color = {0, 0, 255}));
  connect(sourceP1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-70, 0}, {-70, 0}, {-70, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss4.C2, sink1.C) annotation(
    Line(points = {{70, 0}, {82, 0}, {82, 0}, {82, 0}}, color = {0, 0, 255}));
end TSP_FourFlows1;

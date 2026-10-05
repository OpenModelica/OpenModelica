within NewDataReconciliationSimpleTests;

model TSP_Splitter4 "OK"
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss1(Pm(displayUnit = "Pa"),Q(uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss2(Pm(displayUnit = "Pa"),Q(uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {-50, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss3(Pm(displayUnit = "Pa"),Q(uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {-50, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(
    Placement(visible = true, transformation(origin = {3, 0}, extent = {{-9, -10}, {9, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SourcePQ sourcePQ1 annotation(
    Placement(visible = true, transformation(origin = {-90, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.Sink sink1 annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SourceQ sourceQ1 annotation(
    Placement(visible = true, transformation(origin = {-90, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(mixer21.Cs, singularPressureLoss1.C1) annotation(
    Line(points = {{12, 0}, {40, 0}, {40, 0}, {40, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, mixer21.Ce1) annotation(
    Line(points = {{-40, 30}, {0, 30}, {0, 10}, {0, 10}}, color = {0, 0, 255}));
  connect(singularPressureLoss3.C2, mixer21.Ce2) annotation(
    Line(points = {{-40, -30}, {0, -30}, {0, -10}, {0, -10}}, color = {0, 0, 255}));
  connect(sourcePQ1.C, singularPressureLoss2.C1) annotation(
    Line(points = {{-80, 30}, {-60, 30}, {-60, 30}, {-60, 30}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, sink1.C) annotation(
    Line(points = {{60, 0}, {80, 0}, {80, 0}, {80, 0}}, color = {0, 0, 255}));
  connect(sourceQ1.C, singularPressureLoss3.C1) annotation(
    Line(points = {{-80, -30}, {-62, -30}, {-62, -30}, {-60, -30}}, color = {0, 0, 255}));
end TSP_Splitter4;

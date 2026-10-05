within NewDataReconciliationSimpleTests;

model TSP_Pipe8 "OK"
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss1 (Pm(displayUnit = "Pa",start = 1e5, uncertain = Uncertainty.refine),Q(start = 100.3, uncertain = Uncertainty.refine), T(displayUnit = "K",start = 290, uncertain = Uncertainty.refine), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {-49, 0}, extent = {{-9, -10}, {9, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss2 (Pm(displayUnit = "Pa",start = 1e5, uncertain = Uncertainty.refine),Q(start = 99.3, uncertain = Uncertainty.refine), T(displayUnit = "K",start = 290, uncertain = Uncertainty.refine), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SourceP sourceP1 (T(start=290)) annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SinkP sinkP1 (T(start=310)) annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(sourceP1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-58, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, sinkP1.C) annotation(
    Line(points = {{60, 0}, {82, 0}, {82, 0}, {80, 0}, {80, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, singularPressureLoss2.C1) annotation(
    Line(points = {{-40, 0}, {40, 0}}, color = {0, 0, 255}));
protected
end TSP_Pipe8;

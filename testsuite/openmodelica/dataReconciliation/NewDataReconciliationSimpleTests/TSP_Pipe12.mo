within NewDataReconciliationSimpleTests;

model TSP_Pipe12 "OK? - Correct the values of the half width confidence interval for reduced values"
  NewDataReconciliationSimpleTests.Sink sink1 annotation(
    Placement(visible = true, transformation(origin = {92, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss1 ( Pm(displayUnit = "Pa"), Pm_meas (displayUnit = "bar") = 304999.9999999999,Pm_red(displayUnit = "Pa", uncertain = Uncertainty.refine), Q_meas = 100.3,Q_red(start = 100.3, uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, h_meas = 100000, h_red(start = 1e5, uncertain = Uncertainty.refine), mode = 1, p_rho(displayUnit = "kg/m3") = 998, positive_flow = true, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {-48, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss2 ( Pm(displayUnit = "Pa"), Pm_meas = 295000,Pm_red(displayUnit = "Pa", uncertain = Uncertainty.refine), Q_meas = 99.3,Q_red(start = 99.3, uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, h_meas = 110000, h_red( start=1.1e5,uncertain=Uncertainty.refine), mode = 1, p_rho(displayUnit = "kg/m3") = 998, positive_flow = true, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SourcePQ sourcePQ1(h0 = 105000) annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(sourcePQ1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-58, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, sink1.C) annotation(
    Line(points = {{60, 0}, {82, 0}, {82, 0}, {82, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, singularPressureLoss2.C1) annotation(
    Line(points = {{-38, 0}, {40, 0}}, color = {0, 0, 255}));
end TSP_Pipe12;

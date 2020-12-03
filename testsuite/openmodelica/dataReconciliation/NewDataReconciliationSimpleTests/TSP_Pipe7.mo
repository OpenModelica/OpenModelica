within NewDataReconciliationSimpleTests;

model TSP_Pipe7 "OK"
  NewDataReconciliationSimpleTests.Sink sink1 annotation(
    Placement(visible = true, transformation(origin = {92, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss1 (Pm(displayUnit = "Pa"),Q(start = 100.3, uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, h(start = 1e5, uncertain = Uncertainty.refine), rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss2 (Pm(displayUnit = "Pa"),Q(start = 99.3, uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, h( start=1.1e5,uncertain=Uncertainty.refine), rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.VolumeATh volumeATh1 (h(uncertain=Uncertainty.refine, start=1)) annotation(
    Placement(visible = true, transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SourcePQ sourcePQ1(h0 = 105000) annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(singularPressureLoss1.C2, volumeATh1.Ce1) annotation(
    Line(points = {{-40, 0}, {-10, 0}}, color = {0, 0, 255}));
  connect(volumeATh1.Cs1, singularPressureLoss2.C1) annotation(
    Line(points = {{10, 0}, {40, 0}}, color = {0, 0, 255}));
  connect(sourcePQ1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-60, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, sink1.C) annotation(
    Line(points = {{60, 0}, {82, 0}, {82, 0}, {82, 0}}, color = {0, 0, 255}));
end TSP_Pipe7;

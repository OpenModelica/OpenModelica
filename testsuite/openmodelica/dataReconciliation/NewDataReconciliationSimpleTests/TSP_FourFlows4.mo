within NewDataReconciliationSimpleTests;

model TSP_FourFlows4 "NOK - Simulation execution failed for model"
  NewDataReconciliationSimpleTests.Sink sink1(h0 = 1e6)  annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss1 (Pm(displayUnit = "Pa",start = 29.2e5, uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss2 (Pm(displayUnit = "Pa",start = 28.3e5, uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {0, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss3 (Pm(displayUnit = "Pa",start = 30e5, uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {0, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss4 (Pm(displayUnit = "Pa",start = 29.9e5, uncertain = Uncertainty.refine), T(displayUnit = "K"), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Junctions.StaticDrum staticDrum1 (P(uncertain=Uncertainty.refine, start=29.2e5)) annotation(
    Placement(visible = true, transformation(origin = {-22, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Junctions.StaticDrum staticDrum2 (P(uncertain=Uncertainty.refine, start=28.3e5)) annotation(
    Placement(visible = true, transformation(origin = {28, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.Source source1(h0 = 1e6)  annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(singularPressureLoss4.C2, sink1.C) annotation(
    Line(points = {{70, 0}, {80, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, staticDrum1.Ce_sup) annotation(
    Line(points = {{-40, 0}, {-40, 4}, {-31, 4}}, color = {0, 0, 255}));
  connect(staticDrum1.Cs_sur, singularPressureLoss2.C1) annotation(
    Line(points = {{-18, 9}, {-20, 9}, {-20, 20}, {-10, 20}}, color = {0, 0, 255}));
  connect(staticDrum1.Cs_eva, singularPressureLoss3.C1) annotation(
    Line(points = {{-18, -9}, {-18, -20}, {-10, -20}}, color = {0, 0, 255}));
  connect(singularPressureLoss3.C2, staticDrum2.Ce_eco) annotation(
    Line(points = {{10, -20}, {24, -20}, {24, -10}, {24, -10}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, staticDrum2.Ce_steam) annotation(
    Line(points = {{10, 20}, {24, 20}, {24, 10}, {24, 10}, {24, 10}}, color = {0, 0, 255}));
  connect(source1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-60, 0}, {-60, 0}, {-60, 0}}, color = {0, 0, 255}));
  connect(staticDrum2.Cs_sup, singularPressureLoss4.C1) annotation(
    Line(points = {{38, 4}, {50, 4}, {50, 0}, {50, 0}}, color = {0, 0, 255}));
end TSP_FourFlows4;

within NewDataReconciliationSimpleTests;

model TSP_FourFlows5 "NOK - Failed to build model"
  NewDataReconciliationSimpleTests.Sink sink1 annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss1( Pm(displayUnit = "Pa", start = 15e5),Q( start=2.10,uncertain=Uncertainty.refine), T( displayUnit = "K",start=470,uncertain=Uncertainty.refine), deltaP(start=1.e5), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss2( Pm(displayUnit = "Pa", start = 4e5),Q( start=1.10,uncertain=Uncertainty.refine), T( displayUnit = "K",start=465,uncertain=Uncertainty.refine), continuous_flow_reversal = true, deltaP(start=1.e5), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {0, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss3( Pm(displayUnit = "Pa", start = 4e5),Q( start=0.95,uncertain=Uncertainty.refine), T( displayUnit = "K",start=473,uncertain=Uncertainty.refine), deltaP(start=1.e5), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {0, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss4( Pm(displayUnit = "Pa", start = 4e5),Q( start=2.00,uncertain=Uncertainty.refine), T( displayUnit = "K",start=462,uncertain=Uncertainty.refine), deltaP(start=1.e5), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Junctions.StaticDrum staticDrum1 (P(start=4e5), T(uncertain=Uncertainty.refine, start=470)) annotation(
    Placement(visible = true, transformation(origin = {-22, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 (P(start=4e5), T(uncertain=Uncertainty.refine, start=470)) annotation(
    Placement(visible = true, transformation(origin = {24, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SourceQ sourceQ1(Q0 = 2, h0 = 1e6)  annotation(
    Placement(visible = true, transformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(singularPressureLoss4.C2, sink1.C) annotation(
    Line(points = {{60, 0}, {80, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss1.C2, staticDrum1.Ce_sup) annotation(
    Line(points = {{-40, 0}, {-40, 4}, {-31, 4}}, color = {0, 0, 255}));
  connect(staticDrum1.Cs_sur, singularPressureLoss2.C1) annotation(
    Line(points = {{-18, 9}, {-18, 20}, {-10, 20}}, color = {0, 0, 255}));
  connect(staticDrum1.Cs_eva, singularPressureLoss3.C1) annotation(
    Line(points = {{-18, -9}, {-18, -20}, {-10, -20}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, mixer21.Ce1) annotation(
    Line(points = {{10, 20}, {20, 20}, {20, 10}, {20, 10}}, color = {0, 0, 255}));
  connect(singularPressureLoss3.C2, mixer21.Ce2) annotation(
    Line(points = {{10, -20}, {20, -20}, {20, -10}, {20, -10}}, color = {0, 0, 255}));
  connect(mixer21.Cs, singularPressureLoss4.C1) annotation(
    Line(points = {{34, 0}, {38, 0}, {38, 2}, {40, 2}, {40, 0}}, color = {0, 0, 255}));
  connect(sourceQ1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-60, 0}, {-60, 0}, {-60, 0}}, color = {0, 0, 255}));
end TSP_FourFlows5;

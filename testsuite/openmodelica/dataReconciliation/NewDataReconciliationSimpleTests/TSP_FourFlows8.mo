within NewDataReconciliationSimpleTests;

model TSP_FourFlows8 "NOK - Division by zero at time 0"
  NewDataReconciliationSimpleTests.Sink sink1(h0 = 1e6)  annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss1( Pm(displayUnit = "Pa", start = 15e5),Q( start=100.3,uncertain=Uncertainty.refine), T( displayUnit = "K",start=473), continuous_flow_reversal = true, deltaP(start=1.e5), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {-50, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss2( Pm(displayUnit = "Pa", start = 15e5),Q( start=100,uncertain=Uncertainty.refine), T( displayUnit = "K",start=470), deltaP(start=1.e5), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {0, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss3( Pm(displayUnit = "Pa", start = 15e5),Q( start=99,uncertain=Uncertainty.refine), T( displayUnit = "K",start=465), deltaP(start=1.e5), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {0, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SingularPressureLoss singularPressureLoss4( Pm(displayUnit = "Pa", start = 15e5),Q( start=98,uncertain=Uncertainty.refine), T( displayUnit = "K",start=472), deltaP(start=1.e5), flow_reversal = false, rho(displayUnit = "kg/m3"), specific_enthalpy_as_state_variable = false) annotation(
    Placement(visible = true, transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Junctions.StaticDrum staticDrum1 (P(start=2900000), T(start=473)) annotation(
    Placement(visible = true, transformation(origin = {-22, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Volumes.VolumeB staticDrum2 (P(displayUnit = "Pa", start=2500000), T( start=471), rho(displayUnit = "kg/m3")) annotation(
    Placement(visible = true, transformation(origin = {28, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
  NewDataReconciliationSimpleTests.SourceQ source1(Q0 = 100, h0 = 1e6)  annotation(
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
  connect(source1.C, singularPressureLoss1.C1) annotation(
    Line(points = {{-80, 0}, {-60, 0}, {-60, 0}, {-60, 0}}, color = {0, 0, 255}));
  connect(singularPressureLoss2.C2, staticDrum2.Ce2) annotation(
    Line(points = {{10, 20}, {28, 20}, {28, 10}}, color = {0, 0, 255}));
  connect(singularPressureLoss3.C2, staticDrum2.Ce1) annotation(
    Line(points = {{10, -20}, {28, -20}, {28, -10}}, color = {0, 0, 255}));
  connect(staticDrum2.Cs2, singularPressureLoss4.C1) annotation(
    Line(points = {{38, 0}, {50, 0}}, color = {0, 0, 255}));
end TSP_FourFlows8;

within NewDataReconciliationSimpleTests;

model TSP_Splitter7 "OK"
  ThermoSysPro.WaterSteam.Junctions.StaticDrum staticDrum1 annotation(
    Placement(visible = true, transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.LumpedStraightPipe lumpedStraightPipe2 (Q(uncertain = Uncertainty.refine), continuous_flow_reversal = true) annotation(
    Placement(visible = true, transformation(origin = {-48, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SourceQ sourceQ1(h0 = 1e6)  annotation(
    Placement(visible = true, transformation(origin = {-90, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.SourceQ sourceQ2(h0 = 1e6)  annotation(
    Placement(visible = true, transformation(origin = {-88, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.LumpedStraightPipe lumpedStraightPipe3 (Q(uncertain = Uncertainty.refine), continuous_flow_reversal = true) annotation(
    Placement(visible = true, transformation(origin = {-50, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.LumpedStraightPipe lumpedStraightPipe1 (Q(uncertain = Uncertainty.refine), continuous_flow_reversal = true) annotation(
    Placement(visible = true, transformation(origin = {40, 4}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  NewDataReconciliationSimpleTests.Sink new_Sink1 annotation(
    Placement(visible = true, transformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(sourceQ1.C, lumpedStraightPipe2.C1) annotation(
    Line(points = {{-80, 30}, {-60, 30}, {-60, 30}, {-58, 30}, {-58, 30}}, color = {0, 0, 255}));
  connect(lumpedStraightPipe2.C2, staticDrum1.Ce_steam) annotation(
    Line(points = {{-38, 30}, {-4, 30}, {-4, 10}, {-4, 10}}, color = {0, 0, 255}));
  connect(sourceQ2.C, lumpedStraightPipe3.C1) annotation(
    Line(points = {{-78, -30}, {-60, -30}, {-60, -30}, {-60, -30}}, color = {0, 0, 255}));
  connect(lumpedStraightPipe3.C2, staticDrum1.Ce_eco) annotation(
    Line(points = {{-40, -30}, {-4, -30}, {-4, -10}, {-4, -10}}, color = {0, 0, 255}));
  connect(staticDrum1.Cs_sup, lumpedStraightPipe1.C1) annotation(
    Line(points = {{10, 4}, {30, 4}}, color = {0, 0, 255}));
  connect(lumpedStraightPipe1.C2, new_Sink1.C) annotation(
    Line(points = {{50, 4}, {70, 4}, {70, 0}, {80, 0}}, color = {0, 0, 255}));
end TSP_Splitter7;

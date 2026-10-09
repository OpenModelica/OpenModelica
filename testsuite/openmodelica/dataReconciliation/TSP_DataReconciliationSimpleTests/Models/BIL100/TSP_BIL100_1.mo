within TSP_DataReconciliationSimpleTests.Models.BIL100;
model TSP_BIL100_1
  Components.BoundaryConditions.SourcePQ sourceQ2(
    P0=9000000,
    h0=6e6)
    annotation (Placement(visible=true,transformation(origin={-32,-30},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.Sink sink1(
    h0=2e6)
    annotation (Placement(visible=true,transformation(origin={46,-4},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink
    annotation (Placement(visible=true,transformation(origin={-40,40},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ(
    Q0=95)
    annotation (Placement(visible=true,transformation(origin={32,60},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.SGVALI GV1(
    SG_volume(
      T(
        uncertain=Uncertainty.refine),
      P(
        uncertain=Uncertainty.refine)),
    DP_are(
      Q(
        uncertain=Uncertainty.refine)),
    DP_vvp1(
      Q(
        uncertain=Uncertainty.refine)),
    DP_pur(
      Q(
        uncertain=Uncertainty.refine)))
    annotation (Placement(visible=true,transformation(origin={0,10},extent={{-32,-28},{32,28}},rotation=0)));
equation
  connect(heatSink.C[1],GV1.thermalPort)
    annotation (Line(points={{-40,30},{-40,21},{-13,21}}));
  connect(GV1.C3_vvp,sinkQ.C)
    annotation (Line(points={{0,38},{0,60},{22,60}},color={255,0,0}));
  connect(GV1.C2_pur,sink1.C)
    annotation (Line(points={{10,-4},{36,-4}},color={255,0,0}));
  connect(sourceQ2.C,GV1.C1_are)
    annotation (Line(points={{-22,-30},{0,-30},{0,-18}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_STDOUT,LOG_ASSERT,LOG_STATS",
      s="dassl",
      sx="modelica://EDF_NewDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_BIL100_1_Inputs.csv"));
end TSP_BIL100_1;

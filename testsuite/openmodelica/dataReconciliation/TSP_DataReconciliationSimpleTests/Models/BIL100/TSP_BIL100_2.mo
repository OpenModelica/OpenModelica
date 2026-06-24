within TSP_DataReconciliationSimpleTests.Models.BIL100;
model TSP_BIL100_2
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
    annotation (Placement(visible=true,transformation(extent={{-40,-30},{-20,-10}},rotation=0)));
  Components.Volumes.SGVALI GV2(
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
    annotation (Placement(visible=true,transformation(extent={{20,-30},{40,-10}},rotation=0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourcePQ
    annotation (Placement(visible=true,transformation(origin={0,-90},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkQ sinkQ
    annotation (Placement(visible=true,transformation(origin={0,96},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink
    annotation (Placement(visible=true,transformation(origin={-62,-16},extent={{-10,10},{10,-10}},rotation=-90)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink1
    annotation (Placement(visible=true,transformation(origin={0,-16},extent={{-10,10},{10,-10}},rotation=-90)));
  ThermoSysPro.WaterSteam.BoundaryConditions.Sink sinkQ1
    annotation (Placement(visible=true,transformation(extent={{50,-40},{70,-20}},rotation=0)));
  ThermoSysPro.WaterSteam.BoundaryConditions.SinkQ sinkQ2
    annotation (Placement(visible=true,transformation(extent={{-8,-42},{12,-22}},rotation=0)));
  ThermoSysPro.WaterSteam.Junctions.Splitter2 SEP_ARE(
    P(
      uncertain=Uncertainty.refine),
    T(
      uncertain=Uncertainty.refine))
    annotation (Placement(visible=true,transformation(origin={0,-60},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.WaterSteam.Junctions.Mixer2 MEL_GCT(
    P(
      uncertain=Uncertainty.refine),
    T(
      uncertain=Uncertainty.refine))
    annotation (Placement(visible=true,transformation(origin={0,58},extent={{-10,-10},{10,10}},rotation=90)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV1
    annotation (Placement(visible=true,transformation(origin={-30,22},extent={{-10,-10},{10,10}},rotation=90)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV2
    annotation (Placement(visible=true,transformation(origin={28,20},extent={{-10,-10},{10,10}},rotation=90)));
equation
  connect(heatSink.C[1],GV1.thermalPort)
    annotation (Line(points={{-52.2,-16},{-34,-16}}));
  connect(heatSink1.C[1],GV2.thermalPort)
    annotation (Line(points={{9.8,-16},{26,-16}}));
  connect(GV2.C2_pur,sinkQ1.C)
    annotation (Line(points={{33,-25},{41.5,-25},{41.5,-30},{50,-30}},color={255,0,0}));
  connect(GV1.C2_pur,sinkQ2.C)
    annotation (Line(points={{-27,-25},{-21.5,-25},{-21.5,-32},{-8,-32}},color={255,0,0}));
  connect(SEP_ARE.Ce,sourcePQ.C)
    annotation (Line(points={{0,-70},{0,-80}},color={0,0,255}));
  connect(SEP_ARE.Cs2,GV2.C1_are)
    annotation (Line(points={{10,-56},{30,-56},{30,-29.8}},color={0,0,255}));
  connect(SEP_ARE.Cs1,GV1.C1_are)
    annotation (Line(points={{-10,-56},{-30,-56},{-30,-29.8}},color={0,0,255}));
  connect(sinkQ.C,MEL_GCT.Cs)
    annotation (Line(points={{0,86},{0,68}},color={0,0,255}));
  connect(GV1.C3_vvp,DP_GV1.C1)
    annotation (Line(points={{-30,-10},{-30,12}},color={255,0,0}));
  connect(GV2.C3_vvp,DP_GV2.C1)
    annotation (Line(points={{30,-10},{28,-10},{28,10}},color={255,0,0}));
  connect(DP_GV2.C2,MEL_GCT.Ce2)
    annotation (Line(points={{28,30},{28,54},{10,54}},color={0,0,255}));
  connect(DP_GV1.C2,MEL_GCT.Ce1)
    annotation (Line(points={{-30,32},{-30,54},{-10,54}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_STDOUT,LOG_ASSERT,LOG_STATS",
      s="dassl",
      sx="modelica://EDF_NewDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_BIL100_2_Inputs.csv"));
end TSP_BIL100_2;

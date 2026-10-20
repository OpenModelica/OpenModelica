within TSP_DataReconciliationSimpleTests.Models.BIL100;
model TSP_BIL100_4
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
    annotation (Placement(visible=true,transformation(extent={{-150,-30},{-130,-10}},rotation=0)));
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
    annotation (Placement(visible=true,transformation(extent={{150,-30},{170,-10}},rotation=0)));
  Components.BoundaryConditions.SourcePQ sourcePQ(
    P0=999999.9999999999,
    Q0=200)
    annotation (Placement(visible=true,transformation(origin={-46,-110},extent={{-10,-10},{10,10}},rotation=90)));
  Components.BoundaryConditions.SinkQ sinkQ
    annotation (Placement(visible=true,transformation(origin={-46,150},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink
    annotation (Placement(visible=true,transformation(origin={-172,-16},extent={{-10,10},{10,-10}},rotation=-90)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink1
    annotation (Placement(visible=true,transformation(origin={130,-16},extent={{-10,10},{10,-10}},rotation=-90)));
  Components.BoundaryConditions.Sink sinkQ1
    annotation (Placement(visible=true,transformation(extent={{180,-40},{200,-20}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ2
    annotation (Placement(visible=true,transformation(extent={{-116,-36},{-96,-16}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV1(
    Q(
      uncertain=Uncertainty.refine))
    annotation (Placement(visible=true,transformation(origin={-140,30},extent={{-10,-10},{10,10}},rotation=90)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV2(
    Q(
      uncertain=Uncertainty.refine))
    annotation (Placement(visible=true,transformation(origin={160,28},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.WaterSteam.Sensors.SensorQ sensorGCT(
    Q(
      uncertain=Uncertainty.refine))
    annotation (Placement(visible=true,transformation(origin={-38,110},extent={{10,-10},{-10,10}},rotation=-90)));
  Components.Volumes.SGVALI GV3(
    DP_are(
      Q(
        uncertain=Uncertainty.refine)),
    DP_pur(
      Q(
        uncertain=Uncertainty.refine)),
    DP_vvp1(
      Q(
        uncertain=Uncertainty.refine)),
    SG_volume(
      P(
        uncertain=Uncertainty.refine),
      T(
        uncertain=Uncertainty.refine)))
    annotation (Placement(visible=true,transformation(extent={{-56,-32},{-36,-12}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ3
    annotation (Placement(visible=true,transformation(extent={{-22,-38},{-2,-18}},rotation=0)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink2
    annotation (Placement(visible=true,transformation(origin={-78,-18},extent={{-10,10},{10,-10}},rotation=-90)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV3(
    Q(
      uncertain=Uncertainty.refine))
    annotation (Placement(visible=true,transformation(origin={-46,30},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.WaterSteam.Junctions.Mixer3 MEL_GCT
    annotation (Placement(visible=true,transformation(origin={-46,64},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.WaterSteam.Junctions.Splitter3 SEP_ARE(
    P(
      uncertain=Uncertainty.refine),
    Cs1(
      Q(
        uncertain=Uncertainty.refine)),
    Cs2(
      Q(
        uncertain=Uncertainty.refine)),
    Cs3(
      Q(
        uncertain=Uncertainty.refine)),
    Ce(
      Q(
        uncertain=Uncertainty.refine)))
    annotation (Placement(visible=true,transformation(origin={-46,-70},extent={{-10,-10},{10,10}},rotation=90)));
equation
  connect(heatSink.C[1],GV1.thermalPort)
    annotation (Line(points={{-162.2,-16},{-144,-16}}));
  connect(heatSink1.C[1],GV2.thermalPort)
    annotation (Line(points={{139.8,-16},{156,-16}}));
  connect(GV2.C2_pur,sinkQ1.C)
    annotation (Line(points={{163,-25},{171.5,-25},{171.5,-30},{180,-30}},color={255,0,0}));
  connect(GV1.C2_pur,sinkQ2.C)
    annotation (Line(points={{-137,-25},{-131.5,-25},{-131.5,-26},{-116,-26}},color={255,0,0}));
  connect(GV1.C3_vvp,DP_GV1.C1)
    annotation (Line(points={{-140,-10},{-140,20}},color={255,0,0}));
  connect(GV2.C3_vvp,DP_GV2.C1)
    annotation (Line(points={{160,-10},{160,18}},color={255,0,0}));
  connect(sinkQ.C,sensorGCT.C2)
    annotation (Line(points={{-46,140},{-46,120}},color={0,0,255}));
  connect(DP_GV3.C1,GV3.C3_vvp)
    annotation (Line(points={{-46,20},{-46,-12}},color={0,0,255}));
  connect(DP_GV1.C2,MEL_GCT.Ce1)
    annotation (Line(points={{-140,40},{-140,60},{-56,60}},color={0,0,255}));
  connect(sensorGCT.C1,MEL_GCT.Cs)
    annotation (Line(points={{-46,100},{-46,74}},color={0,0,255}));
  connect(DP_GV3.C2,MEL_GCT.Ce3)
    annotation (Line(points={{-46,40},{-46,54}},color={0,0,255}));
  connect(DP_GV2.C2,MEL_GCT.Ce2)
    annotation (Line(points={{160,38},{160,60},{-36,60}},color={0,0,255}));
  connect(SEP_ARE.Ce,sourcePQ.C)
    annotation (Line(points={{-46,-79.8},{-46,-99.8}},color={0,0,255}));
  connect(GV3.C1_are,SEP_ARE.Cs3)
    annotation (Line(points={{-46,-32},{-46,-60}},color={0,0,255}));
  connect(SEP_ARE.Cs2,GV2.C1_are)
    annotation (Line(points={{-36,-66},{160,-66},{160,-30}},color={0,0,255}));
  connect(SEP_ARE.Cs1,GV1.C1_are)
    annotation (Line(points={{-56,-66},{-140,-66},{-140,-30}},color={0,0,255}));
  connect(GV3.C2_pur,sinkQ3.C)
    annotation (Line(points={{-42,-26},{-22,-26},{-22,-28}},color={255,0,0}));
  connect(heatSink2.C[1],GV3.thermalPort)
    annotation (Line(points={{-68,-18},{-50,-18}}));
  annotation (
    Icon(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-200,-200},{200,200}})),
    Diagram(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-200,-200},{200,200}})),
    __OpenModelica_simulationFlags(
      lv="LOG_STDOUT,LOG_ASSERT,LOG_STATS",
      s="dassl",
      sx="modelica://EDF_NewDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_BIL100_4_Inputs.csv"));
end TSP_BIL100_4;

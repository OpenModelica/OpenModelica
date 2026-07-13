within TSP_DataReconciliationSimpleTests.Models.BIL100;
model BIL100
  parameter Real rho=0;
  parameter Real GV1_CFDP1=1;
  parameter Real GV2_CFDP1=1;
  parameter Real GV3_CFDP1=1;
  parameter Real GV4_CFDP1=1;
  parameter Real VVP_1A_VAPF=0.99986;
  parameter Real VVP_2A_VAPF=0.99999;
  parameter Real VVP_3A_VAPF=0.99995;
  parameter Real VVP_4A_VAPF=0.99999;
  parameter Real DP_GV1_CFDP=1;
  parameter Real DP_GV2_CFDP=1;
  parameter Real DP_GV3_CFDP=1;
  parameter Real DP_GV4_CFDP=1;
  parameter Real DP_BAR1_CFDP=1;
  parameter Real DP_BAR2_CFDP=1;
  parameter Real DP_BAR3_CFDP=1;
  parameter Real DP_BAR4_CFDP=1;
  parameter Real QPUR12=1;
  parameter Real QPUR13=1;
  parameter Real QPUR14=1;

  /* Boundary conditions */
  parameter Real QARE0=2126.272222;
  parameter Real PARE0=7032392.1;
  parameter Real TARE0=500.2497543;
  parameter Real TGRE0=552.6833333;
  parameter Real QGSS0=183.713226;
  parameter Real QGRE0=1922.331218;
  parameter Real QSTR0=0;
  Components.Volumes.SGVALI GV1(
    CoeffDeltaP_are=GV1_CFDP1,
    DPnom_vvp(
      displayUnit="bar")=2.14e-05,
    Qnom_vvp=532,
    fluid=3,
    x_vvp=VVP_1A_VAPF)
    annotation (Placement(visible=true,transformation(origin={-220,-110},extent={{-20,-20},{20,20}},rotation=0)));
  Components.BoundaryConditions.SourcePQ sourcePQ(
    P0=999999.9999999999,
    Q0=200)
    annotation (Placement(visible=true,transformation(origin={-190,-260},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ
    annotation (Placement(visible=true,transformation(origin={480,90},extent={{-10,-10},{10,10}},rotation=0)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink1
    annotation (Placement(visible=true,transformation(origin={-468,-84},extent={{-10,10},{10,-10}},rotation=-90)));
  Components.BoundaryConditions.Sink sinkQ1
    annotation (Placement(visible=true,transformation(extent={{120,-10},{140,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ2
    annotation (Placement(visible=true,transformation(extent={{-180,-132},{-160,-112}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV1(
    CoeffDeltaP=DP_GV1_CFDP,
    Qnom=539,
    deltaPnom=90000)
    annotation (Placement(visible=true,transformation(origin={-168,180},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ3
    annotation (Placement(visible=true,transformation(extent={{-100,-90},{-80,-70}},rotation=0)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink2
    annotation (Placement(visible=true,transformation(origin={-468,-102},extent={{-10,10},{10,-10}},rotation=-90)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV2(
    CoeffDeltaP=DP_GV1_CFDP,
    Qnom=538,
    deltaPnom=90000)
    annotation (Placement(visible=true,transformation(origin={-110,140},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Junctions.Mixer4 MEL_GCT(
    Cs(
      Q(
        start=100)),
    P(
      displayUnit="Pa"),
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={245,90},extent={{-9,-12},{9,12}},rotation=0)));
  Components.Junctions.Splitter44 SEP_ARE(
    P(
      displayUnit="Pa"),
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={-100,-202},extent={{-10,-10},{10,10}},rotation=90)));
  Components.BoundaryConditions.SinkQ sinkQ4
    annotation (Placement(visible=true,transformation(extent={{-20,-52},{0,-32}},rotation=0)));
  Components.Volumes.SGVALI GV3(
    CoeffDeltaP_are=GV3_CFDP1,
    DPnom_vvp(
      displayUnit="bar")=2.03e-05,
    Qnom_vvp=539,
    fluid=3,
    x_vvp=VVP_3A_VAPF)
    annotation (Placement(visible=true,transformation(origin={-60,-32},extent={{-20,-20},{20,20}},rotation=0)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink3
    annotation (Placement(visible=true,transformation(origin={-466,-122},extent={{-10,10},{10,-10}},rotation=-90)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV3(
    CoeffDeltaP=DP_GV1_CFDP,
    Qnom=514,
    deltaPnom=90000)
    annotation (Placement(visible=true,transformation(origin={-30,100},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI DP_BAR1(
    CoeffDeltaP=DP_BAR1_CFDP,
    Qnom=547,
    deltaPnom=99999.99999999999)
    annotation (Placement(visible=true,transformation(origin={-50,180},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI DP_BAR2(
    CoeffDeltaP=DP_BAR2_CFDP,
    Qnom=541.1,
    deltaPnom=98999.99999999999)
    annotation (Placement(visible=true,transformation(origin={12,140},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.SGVALI GV2(
    CoeffDeltaP_are=GV2_CFDP1,
    DPnom_vvp(
      displayUnit="bar")=2.24e-05,
    Qnom_vvp=527,
    fluid=3,
    x_vvp=VVP_2A_VAPF)
    annotation (Placement(visible=true,transformation(origin={-140,-70},extent={{-20,-20},{20,20}},rotation=0)));
  Components.Volumes.SGVALI GV4(
    CoeffDeltaP_are=GV4_CFDP1,
    DPnom_vvp(
      displayUnit="bar")=2.01e-05,
    Qnom_vvp=527,
    fluid=3,
    x_vvp=VVP_4A_VAPF)
    annotation (Placement(visible=true,transformation(origin={0,10},extent={{-20,-20},{20,20}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI DP_GV4(
    CoeffDeltaP=DP_GV1_CFDP,
    Qnom=515,
    deltaPnom=90000)
    annotation (Placement(visible=true,transformation(origin={52,60},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI DP_BAR3(
    CoeffDeltaP=DP_BAR3_CFDP,
    Qnom=551.8,
    deltaPnom=122000)
    annotation (Placement(visible=true,transformation(origin={90,100},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLossVALI DP_BAR4(
    CoeffDeltaP=DP_BAR4_CFDP,
    Qnom=537.2,
    deltaPnom=115000)
    annotation (Placement(visible=true,transformation(origin={170,60},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Junctions.Splitter33 SEP_VAP
    annotation (Placement(visible=true,transformation(origin={378,90},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLossGSS(
    Pm(
      displayUnit="Pa"),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={422,120},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLossSTR
    annotation (Placement(visible=true,transformation(origin={418,60},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ5
    annotation (Placement(visible=true,transformation(origin={478,120},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SinkQ sinkQ6
    annotation (Placement(visible=true,transformation(origin={478,60},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLossARE(
    Pm(
      displayUnit="Pa"),
    T(
      displayUnit="K"),
    flow_reversal=false,
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-130,-260},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Sensors.SensorGCT sensorGCT(
    flow_reversal=false)
    annotation (Placement(visible=true,transformation(origin={310,98},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Sensors.SensorGRE sensorGRE(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={430,98},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Sensors.SensorVVP sensorVVP1(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={-110,188},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Sensors.SensorVVP sensorVVP2(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={-50,148},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Sensors.SensorVVP sensorVVP3(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={30,108},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Sensors.SensorVVP sensorVVP4(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={110,68},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Sensors.SensorAREx sensorARE4(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={8,-170},extent={{10,-10},{-10,10}},rotation=-90)));
  Components.Sensors.SensorAREx sensorARE3(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={-52,-130},extent={{10,-10},{-10,10}},rotation=-90)));
  Components.Sensors.SensorAREx sensorARE2(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={-148,-130},extent={{-10,-10},{10,10}},rotation=90)));
  Components.Sensors.SensorARE1 sensorARE1(
    flow_reversal=false,
    fluid=3)
    annotation (Placement(visible=true,transformation(origin={-228,-168},extent={{-10,-10},{10,10}},rotation=90)));
  TSP_DataReconciliationSimpleTests.Models.BIL100.BIL100W BIL100
    annotation (Placement(visible=true,transformation(origin={-391,-103},extent={{-47,-47},{47,47}},rotation=0)));
  ThermoSysPro.Thermal.BoundaryConditions.HeatSink heatSink4
    annotation (Placement(visible=true,transformation(origin={-468,-140},extent={{-10,10},{10,-10}},rotation=-90)));
  Components.Sensors.SensorQ sensorQPUR
    annotation (Placement(visible=true,transformation(origin={68,8},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(GV1.C2_pur,sinkQ2.C)
    annotation (Line(points={{-214,-120},{-217.5,-120},{-217.5,-122},{-180,-122}},color={255,0,0}));
  connect(GV1.C3_vvp,DP_GV1.C1)
    annotation (Line(points={{-220,-90},{-220,180},{-178,180}},color={255,0,0}));
  connect(GV3.C2_pur,sinkQ4.C)
    annotation (Line(points={{-54,-42},{-20,-42}},color={255,0,0}));
  connect(GV3.C3_vvp,DP_GV3.C1)
    annotation (Line(points={{-60,-12},{-60,100},{-40,100}},color={255,0,0}));
  connect(DP_BAR1.C2,MEL_GCT.Ce1)
    annotation (Line(points={{-40,180},{241.4,180},{241.4,102}},color={0,0,255}));
  connect(DP_BAR2.C2,MEL_GCT.Ce3)
    annotation (Line(points={{22,140},{200,140},{200,94.8},{236,94.8}},color={0,0,255}));
  connect(GV2.C3_vvp,DP_GV2.C1)
    annotation (Line(points={{-140,-50},{-140,140},{-120,140}},color={255,0,0}));
  connect(GV2.C2_pur,sinkQ3.C)
    annotation (Line(points={{-134,-80},{-100,-80}},color={255,0,0}));
  connect(GV4.C3_vvp,DP_GV4.C1)
    annotation (Line(points={{0,30},{0,60},{42,60}},color={255,0,0}));
  connect(DP_BAR3.C2,MEL_GCT.Ce4)
    annotation (Line(points={{100,100},{160,100},{160,85.44},{236,85.44}},color={0,0,255}));
  connect(DP_BAR4.C2,MEL_GCT.Ce2)
    annotation (Line(points={{180,60},{241.4,60},{241.4,78}},color={0,0,255}));
  connect(SEP_VAP.Cs1,singularPressureLossGSS.C1)
    annotation (Line(points={{382,100},{382,120},{412,120}},color={0,0,255}));
  connect(SEP_VAP.Cs2,singularPressureLossSTR.C1)
    annotation (Line(points={{382,80},{382,60},{408,60}},color={0,0,255}));
  connect(singularPressureLossGSS.C2,sinkQ5.C)
    annotation (Line(points={{432,120},{468,120}},color={0,0,255}));
  connect(singularPressureLossSTR.C2,sinkQ6.C)
    annotation (Line(points={{428,60},{468,60}},color={0,0,255}));
  connect(sourcePQ.C,singularPressureLossARE.C1)
    annotation (Line(points={{-180,-260},{-140,-260}},color={0,0,255}));
  connect(singularPressureLossARE.C2,SEP_ARE.Ce)
    annotation (Line(points={{-120,-260},{-100.2,-260},{-100.2,-212}},color={0,0,255}));
  connect(sensorGCT.fluidOutletI,SEP_VAP.Ce)
    annotation (Line(points={{320,90},{368.2,90}},color={255,0,0}));
  connect(SEP_VAP.Cs3,sensorGRE.fluidInletI)
    annotation (Line(points={{388,90},{420,90}},color={0,0,255}));
  connect(sensorGRE.fluidOutletI,sinkQ.C)
    annotation (Line(points={{440,90},{470,90}},color={255,0,0}));
  connect(DP_GV1.C2,sensorVVP1.fluidInletI)
    annotation (Line(points={{-158,180},{-120,180}},color={0,0,255}));
  connect(sensorVVP1.fluidOutletI,DP_BAR1.C1)
    annotation (Line(points={{-100,180},{-60,180}},color={255,0,0}));
  connect(DP_GV2.C2,sensorVVP2.fluidInletI)
    annotation (Line(points={{-100,140},{-60,140}},color={0,0,255}));
  connect(sensorVVP2.fluidOutletI,DP_BAR2.C1)
    annotation (Line(points={{-40,140},{2,140}},color={255,0,0}));
  connect(DP_GV3.C2,sensorVVP3.fluidInletI)
    annotation (Line(points={{-20,100},{20,100}},color={0,0,255}));
  connect(sensorVVP3.fluidOutletI,DP_BAR3.C1)
    annotation (Line(points={{40,100},{80,100}},color={255,0,0}));
  connect(DP_GV4.C2,sensorVVP4.fluidInletI)
    annotation (Line(points={{62,60},{100,60}},color={0,0,255}));
  connect(sensorVVP4.fluidOutletI,DP_BAR4.C1)
    annotation (Line(points={{120,60},{160,60}},color={255,0,0}));
  connect(SEP_ARE.Cs2,sensorARE4.fluidInletI)
    annotation (Line(points={{-90,-198},{0,-198},{0,-180}},color={0,0,255}));
  connect(GV4.C1_are,sensorARE4.fluidOutletI)
    annotation (Line(points={{0,-9.6},{0,-160}},color={0,0,255}));
  connect(SEP_ARE.Cs4,sensorARE3.fluidInletI)
    annotation (Line(points={{-96,-192},{-98,-192},{-98,-160},{-60,-160},{-60,-140}},color={0,0,255}));
  connect(GV3.C1_are,sensorARE3.fluidOutletI)
    annotation (Line(points={{-60,-51.6},{-60,-120}},color={0,0,255}));
  connect(sensorARE2.fluidInletI,SEP_ARE.Cs3)
    annotation (Line(points={{-140,-140},{-140,-160},{-104,-160},{-104,-192}},color={0,0,255}));
  connect(GV2.C1_are,sensorARE2.fluidOutletI)
    annotation (Line(points={{-140,-89.6},{-140,-120}},color={0,0,255}));
  connect(GV1.C1_are,sensorARE1.fluidOutletI)
    annotation (Line(points={{-220,-129.6},{-220,-158}},color={0,0,255}));
  connect(sensorARE1.fluidInletI,SEP_ARE.Cs1)
    annotation (Line(points={{-220,-178},{-220,-198},{-110,-198}},color={0,0,255}));
  connect(heatSink1.C[1],BIL100.Ce1)
    annotation (Line(points={{-458.2,-84},{-448,-84},{-448,-84.2},{-438,-84.2}}));
  connect(heatSink2.C[1],BIL100.Ce2)
    annotation (Line(points={{-458.2,-102},{-448.1,-102},{-448.1,-103},{-438,-103}}));
  connect(heatSink3.C[1],BIL100.Ce3)
    annotation (Line(points={{-456.2,-122},{-448,-122},{-448,-121.8},{-438,-121.8}}));
  connect(heatSink4.C[1],BIL100.Ce4)
    annotation (Line(points={{-458.2,-140},{-448.1,-140},{-448.1,-140.6},{-438,-140.6}}));
  connect(BIL100.Cs4,GV1.thermalPort)
    annotation (Line(points={{-344,-140.6},{-240,-140.6},{-240,-102},{-228,-102}}));
  connect(BIL100.Cs3,GV2.thermalPort)
    annotation (Line(points={{-344,-121.8},{-262,-121.8},{-262,-62},{-148,-62}}));
  connect(BIL100.Cs2,GV3.thermalPort)
    annotation (Line(points={{-344,-103},{-298,-103},{-298,-24},{-68,-24}}));
  connect(BIL100.Cs1,GV4.thermalPort)
    annotation (Line(points={{-344,-84.2},{-318,-84.2},{-318,18},{-8,18}}));
  connect(GV4.C2_pur,sensorQPUR.C1)
    annotation (Line(points={{6,0},{58,0}},color={255,0,0}));
  connect(sensorQPUR.C2,sinkQ1.C)
    annotation (Line(points={{78.2,0},{120,0}},color={0,0,255}));
  connect(sensorQPUR.Measure,sinkQ4.IMassFlow)
    annotation (Line(points={{68,18.2},{68,40},{180,40},{180,-20},{-10,-20},{-10,-37}},color={0,0,255}));
  connect(sensorQPUR.Measure,sinkQ3.IMassFlow)
    annotation (Line(points={{68,18.2},{68,40},{180,40},{180,-60},{-90,-60},{-90,-75}},color={0,0,255}));
  connect(sensorQPUR.Measure,sinkQ2.IMassFlow)
    annotation (Line(points={{68,18.2},{68,40},{180,40},{180,-100},{-170,-100},{-170,-117}},color={0,0,255}));
  connect(MEL_GCT.Cs,sensorGCT.fluidInletI)
    annotation (Line(points={{254,90},{300,90}},color={0,0,255}));
  annotation (
    Icon(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-500,-300},{500,200}})),
    Diagram(
      coordinateSystem(
        preserveAspectRatio=false,
        extent={{-500,-300},{500,200}})));
end BIL100;

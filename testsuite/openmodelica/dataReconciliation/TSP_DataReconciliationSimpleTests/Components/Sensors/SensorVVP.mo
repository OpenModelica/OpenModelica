within TSP_DataReconciliationSimpleTests.Components.Sensors;
model SensorVVP
  parameter Integer fluid=1
    "1: water/steam - 2: C3H3F5 - 3: Simple";
  parameter Boolean flow_reversal=true
    "true: with flow reversal - false: without flow reversal";
  ThermoSysPro.WaterSteam.Connectors.FluidInletI fluidInletI
    annotation (Placement(transformation(extent={{-110,-90},{-90,-70}},rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI fluidOutletI
    annotation (Placement(transformation(extent={{90,-90},{110,-70}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorQ N01MD(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{-60,58},{-40,78}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorQ N02MD(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{-20,58},{0,78}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorP N04MP(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{-40,-2},{-20,18}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorP N05MP(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{-10,-2},{10,18}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorP N06MP(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{20,-2},{40,18}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorP N07MP(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{50,-2},{70,18}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorT N08MT(
    flow_reversal=flow_reversal,
    fluid=fluid)
    annotation (Placement(transformation(extent={{0,-62},{20,-42}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorP N09YP(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{40,-62},{60,-42}},rotation=0)));
equation
  connect(fluidInletI,N01MD.C1)
    annotation (Line(points={{-100,-80},{-80,-80},{-80,60},{-60,60}}));
  connect(N01MD.C2,N02MD.C1)
    annotation (Line(points={{-39.8,60},{-20,60}},color={0,0,255}));
  connect(N09YP.C2,fluidOutletI)
    annotation (Line(points={{60.2,-60},{80,-60},{80,-80},{100,-80}},color={0,0,255}));
  connect(N07MP.C2,N08MT.C1)
    annotation (Line(points={{70.2,0},{80,0},{80,-20},{-60,-20},{-60,-60},{0,-60}},color={0,0,255}));
  connect(N08MT.C2,N09YP.C1)
    annotation (Line(points={{20.2,-60},{40,-60}},color={0,0,255}));
  connect(N02MD.C2,N04MP.C1)
    annotation (Line(points={{0.2,60},{20,60},{20,40},{-60,40},{-60,0},{-40,0}},color={0,0,255}));
  connect(N04MP.C2,N05MP.C1)
    annotation (Line(points={{-19.8,0},{-10,0}},color={0,0,255}));
  connect(N05MP.C2,N06MP.C1)
    annotation (Line(points={{10.2,0},{20,0}},color={0,0,255}));
  connect(N06MP.C2,N07MP.C1)
    annotation (Line(points={{40.2,0},{50,0}},color={0,0,255}));
  annotation (
    Diagram(
      graphics),
    Icon(
      graphics={
        Ellipse(
          extent={{-60,90},{60,-30}},
          lineColor={0,0,255},
          fillColor={170,85,255},
          fillPattern=FillPattern.Solid),
        Line(
          points={{0,-30},{0,-80}}),
        Line(
          points={{-100,-80},{100,-80}}),
        Text(
          extent={{-60,58},{60,-2}},
          lineColor={0,0,255},
          fillColor={170,85,255},
          fillPattern=FillPattern.Solid,
          textString="P, ...")}));
end SensorVVP;

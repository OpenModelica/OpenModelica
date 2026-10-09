within TSP_DataReconciliationSimpleTests.Components.Sensors;
model SensorAREx
  parameter Integer fluid=1
    "1: water/steam - 2: C3H3F5 - 3: Simple";
  parameter Boolean flow_reversal=true
    "true: with flow reversal - false: without flow reversal";
  ThermoSysPro.WaterSteam.Connectors.FluidInletI fluidInletI
    annotation (Placement(transformation(extent={{-110,-90},{-90,-70}},rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI fluidOutletI
    annotation (Placement(transformation(extent={{90,-90},{110,-70}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorQ N20YD(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{-20,-62},{0,-42}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorQ N01MD(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{-60,58},{-40,78}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorQ N02MD(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{-20,58},{0,78}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorT N10MT(
    flow_reversal=flow_reversal,
    fluid=fluid)
    annotation (Placement(transformation(extent={{-40,-2},{-20,18}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorT N11YT(
    flow_reversal=flow_reversal,
    fluid=fluid)
    annotation (Placement(transformation(extent={{0,-2},{20,18}},rotation=0)));
equation
  connect(fluidInletI,N01MD.C1)
    annotation (Line(points={{-100,-80},{-80,-80},{-80,60},{-60,60}}));
  connect(N02MD.C2,N10MT.C1)
    annotation (Line(points={{0.2,60},{20,60},{20,40},{-60,40},{-60,0},{-40,0}},color={0,0,255}));
  connect(N10MT.C2,N11YT.C1)
    annotation (Line(points={{-19.8,0},{0,0}},color={0,0,255}));
  connect(N11YT.C2,N20YD.C1)
    annotation (Line(points={{20.2,0},{40,0},{40,-20},{-40,-20},{-40,-60},{-20,-60}},color={0,0,255}));
  connect(N01MD.C2,N02MD.C1)
    annotation (Line(points={{-39.8,60},{-20,60}},color={0,0,255}));
  connect(N20YD.C2,fluidOutletI)
    annotation (Line(points={{0.2,-60},{80,-60},{80,-80},{100,-80}},color={0,0,255}));
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
          textString="P, ...")}));
end SensorAREx;

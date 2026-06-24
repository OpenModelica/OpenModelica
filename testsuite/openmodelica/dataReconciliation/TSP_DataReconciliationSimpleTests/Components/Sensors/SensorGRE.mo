within TSP_DataReconciliationSimpleTests.Components.Sensors;
model SensorGRE
  parameter Integer fluid=1
    "1: water/steam - 2: C3H3F5 - 3: Simple";
  parameter Boolean flow_reversal=true
    "true: with flow reversal - false: without flow reversal";
  ThermoSysPro.WaterSteam.Connectors.FluidInletI fluidInletI
    annotation (Placement(transformation(extent={{-110,-90},{-90,-70}},rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI fluidOutletI
    annotation (Placement(transformation(extent={{90,-90},{110,-70}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorT N001MT(
    flow_reversal=flow_reversal,
    fluid=fluid)
    annotation (Placement(transformation(extent={{-60,-62},{-40,-42}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorT N776MT(
    flow_reversal=flow_reversal,
    fluid=fluid)
    annotation (Placement(transformation(extent={{-10,-62},{10,-42}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorT N777MT(
    flow_reversal=flow_reversal,
    fluid=fluid)
    annotation (Placement(transformation(extent={{40,-62},{60,-42}},rotation=0)));
equation
  connect(fluidInletI,N001MT.C1)
    annotation (Line(points={{-100,-80},{-80,-80},{-80,-60},{-60,-60}}));
  connect(N001MT.C2,N776MT.C1)
    annotation (Line(points={{-39.8,-60},{-10,-60}},color={0,0,255}));
  connect(N776MT.C2,N777MT.C1)
    annotation (Line(points={{10.2,-60},{40,-60}},color={0,0,255}));
  connect(N777MT.C2,fluidOutletI)
    annotation (Line(points={{60.2,-60},{80,-60},{80,-80},{100,-80}},color={0,0,255}));
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
end SensorGRE;

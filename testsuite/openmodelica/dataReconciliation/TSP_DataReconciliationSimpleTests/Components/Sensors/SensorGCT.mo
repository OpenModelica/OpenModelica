within TSP_DataReconciliationSimpleTests.Components.Sensors;
model SensorGCT
  parameter Boolean flow_reversal=true
    "true: with flow reversal - false: without flow reversal";
  ThermoSysPro.WaterSteam.Connectors.FluidInletI fluidInletI
    annotation (Placement(transformation(extent={{-110,-90},{-90,-70}},rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutletI fluidOutletI
    annotation (Placement(transformation(extent={{90,-90},{110,-70}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorP N002MP(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{20,-62},{40,-42}},rotation=0)));
  TSP_DataReconciliationSimpleTests.Components.Sensors.SensorP N001MP(
    flow_reversal=flow_reversal)
    annotation (Placement(transformation(extent={{-40,-62},{-20,-42}},rotation=0)));
equation
  connect(N002MP.C2,fluidOutletI)
    annotation (Line(points={{40.2,-60},{80,-60},{80,-80},{100,-80}},color={0,0,255}));
  connect(N001MP.C2,N002MP.C1)
    annotation (Line(points={{-19.8,-60},{20,-60}},color={0,0,255}));
  connect(fluidInletI,N001MP.C1)
    annotation (Line(points={{-100,-80},{-80,-80},{-80,-60},{-40,-60}}));
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
end SensorGCT;

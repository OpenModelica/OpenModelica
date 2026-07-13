within TSP_DataReconciliationSimpleTests.Components.Sensors;
model SensorW
  "Heat flow rate sensor"
  Modelica.Units.SI.HeatFlowRate W(
    start=500)
    "Heat flow rate";
public
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Measure
    annotation (Placement(transformation(origin={0,102},extent={{-10,-10},{10,10}},rotation=90)));
  ThermoSysPro.Thermal.Connectors.ThermalPort C1
    annotation (Placement(transformation(extent={{-110,-90},{-90,-70}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort C2
    annotation (Placement(transformation(extent={{90,-90},{110,-70}},rotation=0)));
equation
  C1.T=C2.T;
  C1.W=-C2.W;
  W=C1.W;

  /* Sensor signal */
  Measure.signal=W;
  annotation (
    Diagram(
      graphics={
        Ellipse(
          extent={{-60,92},{60,-28}},
          lineColor={0,0,255},
          fillColor={255,128,0},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-60,60},{60,0}},
          lineColor={0,0,0},
          fillPattern=FillPattern.VerticalCylinder,
          fillColor={120,255,0},
          textString="W"),
        Line(
          points={{0,-28},{0,-80}},
          color={255,128,0}),
        Line(
          points={{-98,-80},{102,-80}},
          color={255,128,0})}),
    Icon(
      graphics={
        Ellipse(
          extent={{-60,92},{60,-28}},
          lineColor={0,0,255},
          fillColor={255,128,0},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-60,60},{60,0}},
          lineColor={0,0,0},
          fillPattern=FillPattern.VerticalCylinder,
          fillColor={120,255,0},
          textString="W"),
        Line(
          points={{0,-28},{0,-80}},
          color={255,128,0}),
        Line(
          points={{-98,-80},{102,-80}},
          color={255,128,0})}));
end SensorW;

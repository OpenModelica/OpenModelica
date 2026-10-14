within ModelicaDataReconciliationSimpleTests.Components.Sensors;
model SensorP "Pressure sensor"
  parameter Boolean flow_reversal=true "true: with flow reversal - false: without flow reversal";
  parameter Boolean continuous_flow_reversal=false "true : continuous flow reversal - false : discontinuous flow reversal";
  parameter Boolean positive_flow=true "true: positive flows are assumed - false: negative flows are assumed (active if flow_reversal = false)";
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.Units.SI.MassFlowRate Qeps=1.e-3 "Minimum mass flow for continuous flow reversal";
public
  Modelica.Units.SI.MassFlowRate Q(start=500) "Mass flow rate";
public
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal Measure annotation (Placement(transformation(
        origin={0,102},
        extent={{-10,-10},{10,10}},
        rotation=90)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet C1 annotation (Placement(transformation(extent={{-110,-90},{-90,-70}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C2 annotation (Placement(transformation(extent={{92,-90},{112,-70}}, rotation=0)));
equation
  C1.P = C2.P;
  C1.h = C2.h;
  C1.Q = C2.Q;
  Q = C1.Q;

  /* Flow reversal */
  if flow_reversal then
    if continuous_flow_reversal then
      0 = noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < (-Qeps) then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
    else
      0 = if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
    end if;
  else
    if positive_flow then
      0 = C1.h - C1.h_vol;
    else
      0 = C2.h - C2.h_vol;
    end if;
  end if;

  /* Sensor signal */
  Measure.signal = C1.P;
  annotation (
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Ellipse(
          extent={{-60,92},{60,-28}},
          lineColor={0,0,255},
          fillColor={0,255,0},
          fillPattern=FillPattern.Solid),Line(points={{0,-28},{0,-80}}),Line(points={{-98,-80},{102,-80}}),Text(extent={{-60,60},{60,0}}, textString="P")}),
    Window(
      x=0.62,
      y=0.25,
      width=0.35,
      height=0.49),
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Ellipse(
          extent={{-60,92},{60,-28}},
          lineColor={0,0,255},
          fillColor={0,255,0},
          fillPattern=FillPattern.Solid),Line(points={{0,-28},{0,-80}}),Line(points={{-98,-80},{102,-80}}),Text(extent={{-60,60},{60,0}}, textString="P")}),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
    ", revisions="<html>
<p><u><b>Author</b></u></p>
<ul>
<li>Daniel Bouskela </li>
</ul>
</html>"));
end SensorP;

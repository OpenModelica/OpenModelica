within ;
model PulseSource "Simple inverter circuit"
//--------------------------------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------------------------------
  extends Modelica.Icons.Example;

encapsulated model V_pulse "Pulse voltage source"
extends Modelica.Electrical.Analog.Interfaces.OnePort;
  import Modelica;

  parameter Modelica.SIunits.Voltage V1=0 "Initial value";
  parameter Modelica.SIunits.Voltage V2=0 "Pulsed value";
  parameter Modelica.SIunits.Time TD=0.0 "Delay time";
  parameter Modelica.SIunits.Time TR(start=1) "Rise time";
  parameter Modelica.SIunits.Time TF=TR "Fall time";
  parameter Modelica.SIunits.Time PW=Modelica.Constants.inf "Pulse width";
  parameter Modelica.SIunits.Time PER=Modelica.Constants.inf "Period";

  protected
  parameter Modelica.SIunits.Time Trising=TR
      "End time of rising phase within one period";
  parameter Modelica.SIunits.Time Twidth=Trising + PW
      "End time of width phase within one period";
  parameter Modelica.SIunits.Time Tfalling=Twidth + TF
      "End time of falling phase within one period";
  Modelica.SIunits.Time T0(final start=TD) "Start time of current period";
  Integer counter(start=-1, fixed=true) "Period counter";
  Integer counter2(start=-1, fixed=true);

equation
  when pre(counter2) <> 0 and sample(TD, PER) then
    T0 = time;
    counter2 = pre(counter);
    counter = pre(counter) - (if pre(counter) > 0 then 1 else 0);
  end when;
  v = V1 + (if (time < TD or counter2 == 0 or time >= T0 +
    Tfalling) then 0 else if (time < T0 + Trising) then (time - T0)*
    (V2-V1)/Trising else if (time < T0 + Twidth) then V2-V1 else
    (T0 + Tfalling - time)*(V2-V1)/(Tfalling - Twidth));

  annotation (
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Text(
          extent={{-120,49},{-20,-1}},
          lineColor={0,0,255},
          textString="+"),
        Text(
          extent={{25,53},{125,3}},
          lineColor={0,0,255},
          textString="-"),
        Text(
          extent={{-157,-62},{143,-102}},
          textString="%name",
          lineColor={0,0,255}),
         Ellipse(
           extent={{-51,50},{49,-50}},
           lineColor={0,0,255},
           fillColor={255,255,255},
           fillPattern=FillPattern.Solid),
         Line(points={{-90,0},{50,0}},  color={0,0,255}),
         Line(points={{50,0},{90,0}}, color={0,0,255}),
        Line(points={{-86,-74},{-65,-74},{-35,66},{-4,66},{25,-74},{46,-74},
              {75,66}}, color={192,192,192})}),
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics),
    Window(
      x=0.21,
      y=0.22,
      width=0.6,
      height=0.63),
    Documentation(info="<html>
<p>Periodic pulse source with not limited number of periods.</p>
<p>A single pulse is described by the following table:</p>
<table cellspacing=\"2\" cellpadding=\"0\" border=\"0\"><tr>
<td><h4>time</h4></td>
<td><h4>value</h4></td>
</tr>
<tr>
<td><p>0</p></td>
<td><p>V1</p></td>
</tr>
<tr>
<td><p>TD</p></td>
<td><p>V1</p></td>
</tr>
<tr>
<td><p>TD+TR</p></td>
<td><p>V2</p></td>
</tr>
<tr>
<td><p>TD+TR+PW</p></td>
<td><p>V2</p></td>
</tr>
<tr>
<td><p>TD+TR+PW+TF</p></td>
<td><p>V1</p></td>
</tr>
<tr>
<td><p>TSTOP</p></td>
<td><p>V1</p></td>
</tr>
</table>
<p>Intermediate points are determined by linear interpolation.</p>
<p>A pulse it looks like a saw tooth, use this parameters e.g.:</p>
<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr>
<td><h4>Parameter</h4></td>
<td><h4>Value</h4></td>
</tr>
<tr>
<td><p>V1</p></td>
<td><p>0</p></td>
</tr>
<tr>
<td><p>V2</p></td>
<td><p>1</p></td>
</tr>
<tr>
<td><p>TD</p></td>
<td><p>0</p></td>
</tr>
<tr>
<td><p>TR</p></td>
<td><p>1</p></td>
</tr>
<tr>
<td><p>TF</p></td>
<td><p>1</p></td>
</tr>
<tr>
<td><p>PW</p></td>
<td><p>2</p></td>
</tr>
<tr>
<td><p>PER</p></td>
<td><p>1</p></td>
</tr>
</table>
<h4>Note:</h4>
<ul>
<li>All parameters of sources should be set explicitly.</li>
<li>since TSTEP and TSTOP are not available for modeling in Modelica, differences to SPICE may occur if not all parameters are set.</li>
</ul>
</html>"),
    uses(Modelica(version="3.2")));
end V_pulse;

  Modelica.Electrical.Spice3.Basic.Ground ground
    annotation (Placement(transformation(extent={{-14,-60},{6,-40}})));
  V_pulse vin(
    V2=5,
    TD=4e-12,
    TR=0.1e-12,
    TF=0.1e-12,
    PW=1e-12,
    PER=2e-12) annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={-40,-16})));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R=1) annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={-4,-16})));
equation
  connect(vin.n, ground.p)     annotation (Line(
      points={{-40,-26},{-40,-40},{-4,-40}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(ground.p, resistor.n) annotation (Line(
      points={{-4,-40},{-4,-26}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(vin.p, resistor.p) annotation (Line(
      points={{-40,-6},{-4,-6}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation ( Diagram(
        coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
                        graphics),
    Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
            100,100}}), graphics),
    experiment(
      StopTime=1e-011,
      NumberOfIntervals=2000,
      Tolerance=1e-007),
    Documentation(info="<html>
<p>An inverter is an electrical circuit that consists of a PMOS and a NMOS transistor. Its task is to turn the input voltage from high potential to low potential or the other way round.</p>
<p>Simulate until 1.e-11 s. Display the input voltage Vin.p.v as well as the output voltage mp.S.v. It shows that the input voltage is inverted.</p>
</html>",
      revisions="<html>
<ul>
<li><i>March 2009 </i>by Kristin Majetta initially implemented</li>
</ul>
</html>"),
    uses(Modelica(version="3.2.1")),
    __Dymola_experimentSetupOutput);
end PulseSource;

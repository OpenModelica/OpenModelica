within ThermoSysPro.WaterSteam.BoundaryConditions;
model RefH "Fixed specific enthalpy reference"
  parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000.0 "Fixed fluid specific enthalpy";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,255,0}),Line(points={{0,100},{0,40}}, color={0,0,255}),Line(points={{20,60},{0,40},{-20,60}}, color={0,0,255}),Line(points={{-90,0},{-40,0}}, color={0,0,255}),Line(points={{40,0},{90,0}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-28,30},{28,-26}}, fillColor={0,0,255}, textString="H")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,255,0}),Line(points={{0,100},{0,40}}, color={0,0,255}),Line(points={{20,60},{0,40},{-20,60}}, color={0,0,255}),Line(points={{-90,0},{-40,0}}, color={0,0,255}),Line(points={{40,0},{90,0}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-28,30},{28,-26}}, fillColor={0,0,255}, textString="H")}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"), DymolaStoredErrors);
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-270.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-270.0)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow rate for continuous flow reversal";
equation
  if cardinality(ISpecificEnthalpy) == 0 then
    ISpecificEnthalpy.signal=h0;
  end if;
  C1.P=C2.P;
  C1.h=C2.h;
  C1.Q=C2.Q;
  Q=C1.Q;
  C1.h=ISpecificEnthalpy.signal;
  if continuous_flow_reversal then
    0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
end RefH;

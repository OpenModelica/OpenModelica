within ThermoSysPro.WaterSteam.BoundaryConditions;
model Sink "Water/steam sink"
  parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000 "Fluid specific enthalpy (active if IEnthalpy connector is not connected)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy annotation(Placement(transformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0), iconTransformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0)));
  Connectors.FluidInlet C annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  ThermoSysPro.Units.SpecificEnthalpy h "Fluid specific enthalpy";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-90,0},{-40,0},{-54,10}}),Line(color={0,0,255}, points={{-54,-10},{-40,0}}),Text(lineColor={0,0,255}, extent={{10,-40},{30,-60}}, textString="h"),Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={255,255,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{10,-40},{30,-60}}, textString="h"),Line(color={0,0,255}, points={{-92,0},{-40,0},{-54,10}}),Line(color={0,0,255}, points={{-54,-10},{-40,0}})}), Documentation(info="<html>
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
"));
equation
  C.P=P;
  C.Q=Q;
  C.h_vol=h;
  if cardinality(ISpecificEnthalpy) == 0 then
    ISpecificEnthalpy.signal=h0;
  end if;
  h=ISpecificEnthalpy.signal;
end Sink;

within ThermoSysPro.InstrumentationAndControl.Blocks.Continu;
block Derivee
  parameter Real k=1 "Gain";
  parameter Real Ti(min=Modelica.Constants.small)=0.001 "Constante de temps (s)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ureset annotation(Placement(transformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Real x;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{62,0},{102,0}}),Rectangle(lineColor={0,0,255}, extent={{-60,60},{60,-60}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(points={{-50,0},{50,0}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-54,52},{50,10}}, textString="k s", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-54,-6},{52,-52}}, textString="T s + 1", fillColor={0,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,-100},{100,100}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Rectangle(extent={{-100,-100},{100,100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,255}),Line(points={{-80,78},{-80,-90}}, color={192,192,192}),Polygon(points={{-80,90},{-88,68},{-72,68},{-80,90}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(points={{-90,-80},{82,-80}}, color={192,192,192}),Polygon(points={{90,-80},{68,-72},{68,-88},{90,-80}}, fillPattern=FillPattern.Solid, lineColor={192,192,192}, fillColor={192,192,192}),Line(color={0,0,255}, points={{-80,-80},{-80,60},{-70,17.95},{-60,-11.46},{-50,-32.05},{-40,-46.45},{-30,-56.53},{-20,-63.58},{-10,-68.51},{0,-71.96},{10,-74.37},{20,-76.06},{30,-77.25},{40,-78.07},{50,-78.65},{60,-79.06}}),Text(lineColor={0,0,255}, extent={{-30,30},{30,90}}, textString="DT1", fillColor={192,192,192}),Text(lineColor={0,0,255}, extent={{-36,32},{54,-8}}, textString="K=%k", fillColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-34,-12},{56,-52}}, textString="Ti=%Ti", fillColor={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Continuous library</b></p>
</HTML>
<html>
<p><b>Version 1.7</b></p>
</HTML>
"));
initial equation
  x=u.signal - Ti/k*ureset.signal;
equation
  if cardinality(ureset) == 0 then
    ureset.signal=0;
  end if;
  der(x)=if noEvent(abs(k) >= Modelica.Constants.eps) then (u.signal - x)/Ti else 0;
  y.signal=if noEvent(abs(k) >= Modelica.Constants.eps) then k/Ti*(u.signal - x) else 0;
end Derivee;

within ThermoSysPro.InstrumentationAndControl.Blocks.Math;
block Feedback "Différence entre la commande et le feedback"
  annotation(Documentation(info="<html>
<p><b>Adapted from the Modelica.Blocks.Math library</b></p>
</HTML>
<html>
<p><b>Version 1.6</b></p>
</HTML>
"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-20,20},{20,-20}}, pattern=LinePattern.Solid, lineThickness=0.25, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-100,0},{-20,0}}),Line(color={0,0,255}, points={{20,0},{100,0}}),Line(color={0,0,255}, points={{0,-20},{0,-100}}),Text(lineColor={0,0,255}, extent={{-16,-18},{44,-52}}, fillColor={0,0,255}, textString="-"),Text(lineColor={0,0,255}, extent={{-56,4},{-6,-24}}, fillColor={0,0,255}, textString="+"),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-20,20},{20,-20}}, pattern=LinePattern.Solid, lineThickness=0.25, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-100,0},{-20,0}}),Line(color={0,0,255}, points={{20,0},{100,0}}),Line(color={0,0,255}, points={{0,-20},{0,-100}}),Text(lineColor={0,0,255}, extent={{-54,2},{-4,-26}}, fillColor={0,0,255}, textString="+"),Text(lineColor={0,0,255}, extent={{-14,-20},{46,-54}}, fillColor={0,0,255}, textString="-"),Text(lineColor={0,0,255}, extent={{-100,26},{-72,10}}, fillColor={0,0,255}, textString="u1"),Text(lineColor={0,0,255}, extent={{4,-84},{42,-94}}, fillColor={0,0,255}, textString="u2"),Text(lineColor={0,0,255}, extent={{70,26},{98,10}}, fillColor={0,0,255}, textString="y")}));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u2 annotation(Placement(transformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0), iconTransformation(x=0.0, y=-110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=-90.0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u1 annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  y.signal=u1.signal - u2.signal;
end Feedback;

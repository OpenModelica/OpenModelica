within ThermoSysPro.InstrumentationAndControl.Blocks.Logique;
block Terminate
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Line(color={0,0,255}, points={{-80,0},{40,0}}),Line(color={0,0,255}, points={{40,40},{40,-40}}),Rectangle(extent={{-100,-100},{100,102}}, lineColor={0,0,255}, pattern=LinePattern.Solid, lineThickness=0.25, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(points={{-70,-20},{-70,40},{-30,80},{30,80},{70,40},{70,-20},{30,-60},{-30,-60},{-70,-20}}, lineColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-48,40},{50,-20}}, textString="STOP", fillColor={0,0,0})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-70,-20},{-70,40},{-30,80},{30,80},{70,40},{70,-20},{30,-60},{-30,-60},{-70,-20}}, lineColor={0,0,0}),Text(lineColor={0,0,255}, extent={{-48,40},{50,-20}}, textString="STOP", fillColor={0,0,0})}), Documentation(info="<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical uL annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
algorithm
  when uL.signal then
      terminate("Fin de la simulation");
  end when;
end Terminate;

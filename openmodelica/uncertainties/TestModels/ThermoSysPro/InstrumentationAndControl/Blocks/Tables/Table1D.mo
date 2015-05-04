within ThermoSysPro.InstrumentationAndControl.Blocks.Tables;
block Table1D
  parameter Real Table[:,2]=[0,0;0,0] "Table (entrées = première colonne, sorties = deuxième colonne)";
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal u annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real Tu[1,:]=transpose(matrix(Table[:,1])) "Entrées de la table";
  parameter Real Ty[1,:]=transpose(matrix(Table[:,2])) "Sorties de la table";
  parameter Integer n[1,1]=[size(Tu, 2)] "Taille de la table";
  Real vu[1,1];
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-80,80},{80,-80}}, fillPattern=FillPattern.None),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(points={{28,40},{28,-40}}, color={0,0,0}),Rectangle(extent={{-26,40},{0,20}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,20},{0,0}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,0},{0,-20}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,-20},{0,-40}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-24,56},{-6,44}}, textString="u"),Text(lineColor={0,0,255}, extent={{2,56},{26,44}}, textString="y"),Text(lineColor={0,0,255}, extent={{-98,14},{-80,2}}, textString="u"),Text(lineColor={0,0,255}, extent={{78,14},{102,2}}, textString="y"),Line(color={0,0,255}, points={{-80,0},{-100,0}}),Line(points={{0,40},{28,40}}, color={0,0,0}),Line(points={{0,20},{28,20}}, color={0,0,0}),Line(points={{0,0},{28,0}}, color={0,0,0}),Line(points={{0,-20},{28,-20}}, color={0,0,0}),Line(points={{0,-40},{28,-40}}, color={0,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name"),Rectangle(lineColor={0,0,255}, extent={{-80,80},{80,-80}}, fillPattern=FillPattern.None),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(points={{28,42},{28,-38}}, color={0,0,0}),Rectangle(extent={{-26,42},{0,22}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,22},{0,2}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,2},{0,-18}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,-18},{0,-38}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-24,58},{-6,46}}, textString="u"),Text(lineColor={0,0,255}, extent={{2,58},{26,46}}, textString="y"),Text(lineColor={0,0,255}, extent={{-98,14},{-80,2}}, textString="u"),Text(lineColor={0,0,255}, extent={{78,14},{102,2}}, textString="y"),Line(color={0,0,255}, points={{-80,0},{-100,0}}),Line(points={{0,42},{28,42}}, color={0,0,0}),Line(points={{0,22},{28,22}}, color={0,0,0}),Line(points={{0,2},{28,2}}, color={0,0,0}),Line(points={{0,-18},{28,-18}}, color={0,0,0}),Line(points={{0,-38},{28,-38}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the ModelicaAdditions.Blocks.Tables library</b></p>
</HTML>
<html>
<p><b>Version 1.2</b></p>
</HTML>
"));
equation
  vu=[u.signal];
  y.signal=Interpolate(n, Tu, Ty, vu);
end Table1D;

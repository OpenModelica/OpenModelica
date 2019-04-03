within ThermoSysPro.InstrumentationAndControl.Blocks.Tables;
block Table1DTemps
  parameter Real Table[:,2]=[0,0;0,0] "Table (temps = première colonne)";
  parameter String nomTable="NoName" "Nom de la table C (optionnel)";
  parameter String nomFichier="NoName" "Nom du fichier où est stockée la table (optionnel)";
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal y annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real icol[:]={2} "Colonnes de la table à interpoler";
  Real tableID(start=0);
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-80,80},{80,-80}}, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-24,56},{-6,44}}, textString="temps"),Text(lineColor={0,0,255}, extent={{2,56},{26,44}}, textString="y"),Text(lineColor={0,0,255}, extent={{78,14},{102,2}}, textString="y"),Line(points={{0,40},{28,40}}, color={0,0,0}),Rectangle(extent={{-26,40},{0,20}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,20},{0,0}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,0},{0,-20}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,-20},{0,-40}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Line(points={{28,40},{28,-40}}, color={0,0,0}),Line(points={{0,20},{28,20}}, color={0,0,0}),Line(points={{0,0},{28,0}}, color={0,0,0}),Line(points={{0,-20},{28,-20}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{78,14},{102,2}}, textString="y"),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(points={{0,-40},{28,-40}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{-150,150},{150,110}}, textString="%name")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-80,80},{80,-80}}, fillPattern=FillPattern.None),Text(lineColor={0,0,255}, extent={{-24,56},{-6,44}}, textString="temps"),Text(lineColor={0,0,255}, extent={{2,56},{26,44}}, textString="y"),Text(lineColor={0,0,255}, extent={{78,14},{102,2}}, textString="y"),Line(points={{0,40},{28,40}}, color={0,0,0}),Rectangle(extent={{-26,40},{0,20}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,20},{0,0}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,0},{0,-20}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Rectangle(extent={{-26,-20},{0,-40}}, lineColor={0,0,0}, fillColor={255,255,0}, fillPattern=FillPattern.Solid),Line(points={{28,40},{28,-40}}, color={0,0,0}),Line(points={{0,20},{28,20}}, color={0,0,0}),Line(points={{0,0},{28,0}}, color={0,0,0}),Line(points={{0,-20},{28,-20}}, color={0,0,0}),Text(lineColor={0,0,255}, extent={{78,14},{102,2}}, textString="y"),Line(color={0,0,255}, points={{80,0},{100,0}}),Line(points={{0,-40},{28,-40}}, color={0,0,0})}), Documentation(info="<html>
<p><b>Adapted from the ModelicaAdditions.Blocks.Tables library</b></p>
</HTML>
<html>
<p><b>Version 1.0</b></p>
</HTML>
"));
equation
  when initial() then
    tableID=dymTableTimeIni(time, 0.0, nomTable, nomFichier, Table, 0.0);
  end when;
  y.signal=dymTableTimeIpo(tableID, icol[1], time);
end Table1DTemps;

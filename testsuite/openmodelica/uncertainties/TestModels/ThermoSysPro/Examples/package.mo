within ThermoSysPro;
package Examples
  annotation(Icon(coordinateSystem(extent={{0,0},{312,210}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-120,135},{120,70}}, textString="%name", fillColor={255,0,0}),Text(lineColor={0,0,255}, extent={{-90,40},{70,10}}, textString="Library", fillColor={160,160,160}),Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),Polygon(points={{16,-71},{29,-67},{29,-74},{16,-71}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid),Polygon(points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b><font style=\"font-size: 12pt; color: #008000; \">Examples library </font></b></p>
<p><h4>Licensed by EDF under the Modelica License 2. </h4></p>
<p>Copyright &copy; EDF 2002 - 2012</p>
<p><i>This Modelica package is free software and the use is completely at your own risk; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <u>ThermoSysPro.UsersGuide.ModelicaLicense2</i></u> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">http://www.modelica.org/licenses/ModelicaLicense2</a>. </p>
<p>The purpose of this library is to provide examples for the testing of the library components with respect to the variety of existing Modelica tools, and to illustrate their use for the modelling of power plants and energy systems.</p>
<p>Starting from Dymola 7.4 FD01, in order to take full benefit of the simulation speed-up provided by the analytic Jacobian, you should execute the following Modelica script before compiling the model:</p>
<dd>Hidden.UseNewTearing = true;</dd>
<dd>Advanced.GenerateAnalyticJacobian = true;</dd>
<dd>Advanced.SolveNonlinearEquationSymbolically = false; </dd>
<p>This script can be found in the file ThermoSysPro\\Examples\\CombinedCyclePowerPlant\\AJ_D74_FD1.mos</p>
</html>"));
end Examples;

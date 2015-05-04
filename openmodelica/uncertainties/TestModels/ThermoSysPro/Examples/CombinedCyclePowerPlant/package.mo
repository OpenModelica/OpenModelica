within ThermoSysPro.Examples;
package CombinedCyclePowerPlant
  annotation(Icon(coordinateSystem(extent={{0,0},{312,210}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,-100},{80,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,70},{100,-80},{80,-100},{80,50},{100,70}}, fillColor={235,235,235}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-120,135},{120,70}}, textString="%name", fillColor={255,0,0}),Text(lineColor={0,0,255}, extent={{-90,40},{70,10}}, textString="Library", fillColor={160,160,160}),Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),Polygon(points={{16,-71},{29,-67},{29,-74},{16,-71}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid),Polygon(points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}}, lineColor={0,0,0}, fillColor={0,0,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
<p><b><font style=\"font-size: 12pt; color: #008000; \">Combined cycle power plant model </font></b></p><p><h4>Licensed by EDF under the Modelica License 2. </h4></p>
<p>Copyright &copy; EDF 2002 - 2012</p>
<p><i>This Modelica package is free software and the use is completely at your own risk; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <u>ThermoSysPro.UsersGuide.ModelicaLicense2</u> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">http://www.modelica.org/licenses/ModelicaLicense2</a></i>. </p>
<p>Two models of the same combined cycle power plant are provided to simulate two different transients:</p>
<p><ul>
<li>CombinedCycle_Load_100_50, to simulate a load decrease from 100&percnt; to 50&percnt;</li>
<li>CombinedCycle_TripTAC, to simulate a full combustion turbine trip</li>
</ul></p>
<p>Initialization scripts are provided in order to set the correct iteration values. These scripts must be executed after model compilation and before model simulation.</p>
<p>The initialization script to be executed depends on the version of Dymola:</p>
<p><ul>
<li>Dymola 6.1: CombinedCycle_init_D6.1.mos</li>
<li>Dymola 7.4 FD01: CombinedCycle_init_D7.4_FD01.mos</li>
<li>Dymola 2012: CombinedCycle_init_D2012.mos</li>
</ul></p>
<p>They can be found in the directory ThermoSysPro\\Examples\\CombinedCyclePowerPlant\\</p>
<p>Starting from Dymola 7.4 FD01, you should execute the script AJ_D74_FD1.mos in order to get full advantage of the simulation speed-up provided by the analytic jacobian.This script should be run before model compilation.</p>
<p>A conference paper explaining the two models can be found here:
<a href=\"https://www.modelica.org/events/modelica2011/Proceedings/pages/papers/15_2_ID_115_a_fv.pdf\">https://www.modelica.org/events/modelica2011/Proceedings/pages/papers/15_2_ID_115_a_fv.pdf</a>.
</p></html>"));
end CombinedCyclePowerPlant;

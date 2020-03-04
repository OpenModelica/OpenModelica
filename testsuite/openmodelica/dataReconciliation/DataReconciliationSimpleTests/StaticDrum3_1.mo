within DataReconciliationSimpleTests;

model StaticDrum3_1 "Staic drum"
  parameter Real x = 1 "Vapor separation efficiency at the outlet";
  Modelica.SIunits.Temperature T "Fluid temperature";
  Modelica.SIunits.AbsolutePressure P(start = 10.e5) "Fluid pressure";
  Modelica.SIunits.SpecificEnthalpy hl(start = 100000) "Liquid phase specific enthalpy";
  Modelica.SIunits.SpecificEnthalpy hv(start = 2800000) "Gas phase specific enthalpy";
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce_eco annotation(
    Placement(transformation(extent = {{-50, -104}, {-30, -84}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs_sup annotation(
    Placement(transformation(extent = {{84, 24}, {104, 44}}, rotation = 0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce_steam annotation(
    Placement(transformation(extent = {{-48, 84}, {-28, 104}}, rotation = 0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cth annotation(
    Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
/* Fluid pressure */
  P = Ce_steam.P;
  P = Ce_eco.P;
  P = Cs_sup.P;
/* Fluid specific enthalpies at the inlets and outlets */
  Ce_eco.h_vol = hl;
  Ce_steam.h_vol = hv;
  Cs_sup.h_vol = hl;
/* Mass balance equation */
  Ce_eco.Q + Ce_steam.Q - Cs_sup.Q = 0;
/* Energy balance equation */
  Ce_eco.Q * Ce_eco.h + Ce_steam.Q * Ce_steam.h - Cs_sup.Q * Cs_sup.h + Cth.W = 0;
/* Fluid thermodynamic properties */
  hl = 100000;
  hv = 200000;
  T = 300;
  Cth.T = T;
  annotation(
    Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Line(points = {{0, 90}, {0, -100}}), Ellipse(extent = {{-98, 96}, {98, -96}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 0}, fillPattern = FillPattern.Solid), Line(points = {{-86, -44}, {86, -44}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{-44, -86}, {44, -86}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{-64, -72}, {64, -72}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{-78, -58}, {76, -58}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Text(extent = {{-56, 94}, {-56, 92}}, textString = "Esteam")}),
    Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Line(points = {{0, 90}, {0, -100}}), Ellipse(extent = {{-98, 96}, {98, -96}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 0}, fillPattern = FillPattern.Solid), Line(points = {{-86, -44}, {86, -44}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{-44, -86}, {44, -86}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{-64, -72}, {64, -72}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{-78, -58}, {76, -58}}, color = {0, 0, 255}, pattern = LinePattern.Dash)}),
    Window(x = 0.33, y = 0.08, width = 0.66, height = 0.69),
    Documentation(info = "<html>
<p><b>Copyright &copy; EDF 2002 - 2012</b> </p>
<p><b>ThermoSysPro Version 3.0</b> </p>
</html>", revisions = "<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Daniel Bouskela</li>
</ul>
</html>
    "));
end StaticDrum3_1;

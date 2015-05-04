within ThermoSysPro.WaterSteam.Junctions;
model SteamExtractionSplitter "Splitter for steam extraction"
  parameter Real alpha=1 "Steam extraction rate (0 <= alpha <= 1)";
  parameter Integer mode_e=0 "IF97 region at the inlet. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Real x_ex(start=0.99) "Vapor mass fraction at the extraction outlet";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proe annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-100,30},{-100,-30},{-40,-30},{20,-100},{20,-100},{60,-100},{70,-100},{0,-30},{100,-30},{100,30},{-100,30}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-100,28},{-100,-32},{-40,-32},{20,-102},{20,-102},{60,-102},{70,-102},{0,-32},{100,-32},{100,28},{-100,28}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0})}), Documentation(info="<html>
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
  Connectors.FluidInlet Ce annotation(Placement(transformation(x=-103.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-103.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs annotation(Placement(transformation(x=103.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=103.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation(Placement(transformation(x=-10.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cex "Extraction outlet" annotation(Placement(transformation(x=40.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  P=Ce.P;
  P=Cs.P;
  P=Cex.P;
  Ce.h_vol=h;
  Cs.h_vol=h;
  Cex.h_vol=if noEvent(x_ex < 1) then (1 - x_ex)*lsat.h + x_ex*vsat.h else h;
  0=Ce.Q - Cs.Q - Cex.Q;
  0=Ce.Q*Ce.h - Cs.Q*Cs.h - Cex.Q*Cex.h;
  proe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, Ce.h, mode_e);
  (lsat,vsat)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P);
  x_ex=1 - alpha*(1 - proe.x);
end SteamExtractionSplitter;

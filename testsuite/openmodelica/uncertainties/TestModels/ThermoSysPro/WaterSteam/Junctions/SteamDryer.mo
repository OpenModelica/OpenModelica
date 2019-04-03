within ThermoSysPro.WaterSteam.Junctions;
model SteamDryer "Steam dryer"
  parameter Real eta=1 "Steam dryer efficiency (0 < eta <= 1)";
  parameter Integer mode_e=0 "IF97 region at the inlet. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy h(start=1000000.0) "Fluid specific enthalpy";
  Real xe(start=1.0) "Vapor mass fraction at the inlet";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proe annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-98,40},{-18,-100},{22,-100},{102,40},{-98,40}}, fillPattern=FillPattern.Solid, fillColor={255,255,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,40},{-20,-100},{20,-100},{100,40},{-100,40}}, fillPattern=FillPattern.Solid, fillColor={255,255,0})}), Documentation(info="<html>
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
  Connectors.FluidInlet Cev annotation(Placement(transformation(x=-99.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-99.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Csv annotation(Placement(transformation(x=99.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=99.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat1 annotation(Placement(transformation(x=-90.0, y=-88.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat1 annotation(Placement(transformation(x=-66.0, y=-88.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Csl annotation(Placement(transformation(x=1.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=1.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  assert(eta > 0 and eta <= 1, "SteamDryer - Parameter eta should be > 0 and <= 1");
  P=Cev.P;
  P=Csv.P;
  P=Csl.P;
  Cev.h_vol=h;
  Csv.h_vol=h;
  Csl.h_vol=lsat1.h;
  Csv.Q=Cev.Q*xe/eta;
  0=Cev.Q - Csv.Q - Csl.Q;
  0=Cev.Q*Cev.h - Csv.Q*Csv.h - Csl.Q*Csl.h;
  proe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Cev.P, Cev.h, mode_e);
  xe=proe.x;
  (lsat1,vsat1)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(Cev.P);
end SteamDryer;

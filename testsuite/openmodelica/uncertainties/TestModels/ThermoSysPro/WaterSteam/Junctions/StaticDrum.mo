within ThermoSysPro.WaterSteam.Junctions;
model StaticDrum "Staic drum"
  parameter Real x=1.0 "Vapor mass fraction at the outlet";
  ThermoSysPro.Units.AbsolutePressure P(start=1000000.0) "Fluid pressure";
  ThermoSysPro.Units.SpecificEnthalpy hl(start=100000) "Liquid phase specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hv(start=2800000) "Gas phase specific enthalpy";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{0,90},{0,-100}}),Ellipse(lineColor={0,0,255}, extent={{-98,96},{98,-96}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(color={0,0,255}, points={{-86,-44},{86,-44}}, pattern=LinePattern.Dash),Line(color={0,0,255}, points={{-44,-86},{44,-86}}, pattern=LinePattern.Dash),Line(color={0,0,255}, points={{-64,-72},{64,-72}}, pattern=LinePattern.Dash),Line(color={0,0,255}, points={{-78,-58},{76,-58}}, pattern=LinePattern.Dash),Text(lineColor={0,0,255}, extent={{-56,94},{-56,92}}, textString="Esteam")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{0,90},{0,-100}}),Ellipse(lineColor={0,0,255}, extent={{-98,96},{98,-96}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(color={0,0,255}, points={{-86,-44},{86,-44}}, pattern=LinePattern.Dash),Line(color={0,0,255}, points={{-44,-86},{44,-86}}, pattern=LinePattern.Dash),Line(color={0,0,255}, points={{-64,-72},{64,-72}}, pattern=LinePattern.Dash),Line(color={0,0,255}, points={{-78,-58},{76,-58}}, pattern=LinePattern.Dash)}), Documentation(info="<html>
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
  Connectors.FluidInlet Ce_eva annotation(Placement(transformation(x=-94.0, y=-34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-94.0, y=-34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce_eco annotation(Placement(transformation(x=-40.0, y=-94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-40.0, y=-94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs_sup annotation(Placement(transformation(x=94.0, y=34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=94.0, y=34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs_eva annotation(Placement(transformation(x=40.0, y=-94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=-94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs_sur annotation(Placement(transformation(x=38.0, y=94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=38.0, y=94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs_purg annotation(Placement(transformation(x=94.0, y=-34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=94.0, y=-34.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce_steam annotation(Placement(transformation(x=-38.0, y=94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-38.0, y=94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce_sup annotation(Placement(transformation(x=-94.0, y=36.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-94.0, y=36.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation(Placement(transformation(x=-91.0, y=82.0, scale=0.13, aspectRatio=1.23076923076923, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation(Placement(transformation(x=86.0, y=84.0, scale=0.14, aspectRatio=1.14285714285714, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(Ce_steam) == 0 then
    Ce_steam.Q=0;
    Ce_steam.h=100000.0;
    Ce_steam.b=true;
  end if;
  if cardinality(Ce_sup) == 0 then
    Ce_sup.Q=0;
    Ce_sup.h=100000.0;
    Ce_sup.b=true;
  end if;
  if cardinality(Ce_eva) == 0 then
    Ce_eva.Q=0;
    Ce_eva.h=100000.0;
    Ce_eva.b=true;
  end if;
  if cardinality(Ce_eco) == 0 then
    Ce_eco.Q=0;
    Ce_eco.h=100000.0;
    Ce_eco.b=true;
  end if;
  if cardinality(Cs_eva) == 0 then
    Cs_eva.Q=0;
    Cs_eva.h=100000.0;
    Cs_eva.a=true;
  end if;
  if cardinality(Cs_purg) == 0 then
    Cs_purg.Q=0;
    Cs_purg.h=100000.0;
    Cs_purg.a=true;
  end if;
  if cardinality(Cs_sup) == 0 then
    Cs_sup.Q=0;
    Cs_sup.h=100000.0;
    Cs_sup.a=true;
  end if;
  if cardinality(Cs_sur) == 0 then
    Cs_sur.Q=0;
    Cs_sur.h=100000.0;
    Cs_sur.a=true;
  end if;
  P=Ce_steam.P;
  P=Ce_sup.P;
  P=Ce_eva.P;
  P=Ce_eco.P;
  P=Cs_eva.P;
  P=Cs_purg.P;
  P=Cs_sup.P;
  P=Cs_sur.P;
  Ce_sup.h_vol=hl;
  Ce_eva.h_vol=hl;
  Ce_eco.h_vol=hl;
  Ce_steam.h_vol=hv;
  Cs_purg.h_vol=hl;
  Cs_sup.h_vol=hl;
  Cs_eva.h_vol=hl;
  Cs_sur.h_vol=(1 - x)*hl + x*hv;
  Ce_eco.Q + Ce_steam.Q + Ce_sup.Q + Ce_eva.Q - Cs_eva.Q - Cs_sur.Q - Cs_purg.Q - Cs_sup.Q=0;
  Ce_eco.Q*Ce_eco.h + Ce_steam.Q*Ce_steam.h + Ce_sup.Q*Ce_sup.h + Ce_eva.Q*Ce_eva.h - Cs_eva.Q*Cs_eva.h - Cs_sur.Q*Cs_sur.h - Cs_purg.Q*Cs_purg.h - Cs_sup.Q*Cs_sup.h=0;
  (lsat,vsat)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P);
  hl=lsat.h;
  hv=vsat.h;
end StaticDrum;

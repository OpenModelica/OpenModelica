within ThermoSysPro.WaterSteam.BoundaryConditions;
model SourceP "Water/steam source with fixed pressure"
  parameter ThermoSysPro.Units.AbsolutePressure P0=300000 "Source pressure";
  parameter ThermoSysPro.Units.AbsoluteTemperature T0=290 "Source temperature (active if option_temperature=1)";
  parameter ThermoSysPro.Units.SpecificEnthalpy h0=100000 "Source specific enthalpy (active if option_temperature=2)";
  parameter Integer option_temperature=1 "1:temperature fixed - 2:specific enthalpy fixed";
  parameter Integer mode=1 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure P "Fluid pressure";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  ThermoSysPro.Units.AbsoluteTemperature T "Fluid temperature";
  ThermoSysPro.Units.SpecificEnthalpy h "Fluid enthalpy";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{40,0},{90,0},{72,10}}),Line(color={0,0,255}, points={{90,0},{72,-10}}),Text(lineColor={0,0,255}, extent={{-58,30},{-40,10}}, textString="P"),Text(lineColor={0,0,255}, extent={{-40,-40},{-10,-60}}, textString="h / T"),Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Text(lineColor={0,0,255}, extent={{-94,28},{98,-28}}, textString="P")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{40,0},{90,0},{72,10}}),Rectangle(lineColor={0,0,255}, extent={{-40,40},{40,-40}}, fillPattern=FillPattern.Solid, fillColor={127,255,0}),Line(color={0,0,255}, points={{90,0},{72,-10}}),Text(lineColor={0,0,255}, extent={{-94,28},{98,-28}}, textString="P"),Text(lineColor={0,0,255}, extent={{-58,30},{-40,10}}, textString="P"),Text(lineColor={0,0,255}, extent={{-40,-40},{-10,-60}}, textString="h / T")}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
<li>
    Baligh El Hefni</li>
</ul>
</html>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure annotation(Placement(transformation(x=-50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-50.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ISpecificEnthalpy annotation(Placement(transformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0), iconTransformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=true, rotation=90.0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet C annotation(Placement(visible=true, transformation(origin={100.0,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={100.342,-0.4992}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ITemperature annotation(Placement(transformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
equation
  C.P=P;
  C.Q=Q;
  C.h_vol=h;
  if cardinality(IPressure) == 0 then
    IPressure.signal=P0;
  end if;
  P=IPressure.signal;
  if cardinality(ITemperature) == 0 then
    ITemperature.signal=T0;
  end if;
  if cardinality(ISpecificEnthalpy) == 0 then
    ISpecificEnthalpy.signal=h0;
  end if;
  if option_temperature == 1 then
    T=ITemperature.signal;
    h=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(P, T, 0);
  elseif option_temperature == 2 then
    h=ISpecificEnthalpy.signal;
    T=pro.T;
  else
    assert(false, "SourcePressureWaterSteam: incorrect option");
  end if;
  pro=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, h, mode);
end SourceP;

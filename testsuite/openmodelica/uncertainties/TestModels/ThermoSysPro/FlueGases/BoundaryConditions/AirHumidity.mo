within ThermoSysPro.FlueGases.BoundaryConditions;
model AirHumidity "Air humidity"
  parameter Real hum0=0.5 "Air humidiy";
  parameter Integer mode=2 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure P "Air pressure";
  ThermoSysPro.Units.AbsoluteTemperature T "Air temperature";
  Modelica.SIunits.Density rho_vap(start=200) "H20 density";
  Modelica.SIunits.Density rho_air(start=0.8) "Air density";
  ThermoSysPro.Units.AbsolutePressure psvap(start=100000.0) "Vapor stauration pressure in the air";
  ThermoSysPro.Units.AbsolutePressure ppvap(start=10000.0) "Vapor partial pressure";
  ThermoSysPro.Units.AbsolutePressure ppair "Air partial pressure";
  Real hum "Air relative humidity";
  Real Xo2as(start=0.2) "O2 mass fraction in dry air";
  Real Xco2 "CO2 mass fraction at the outlet";
  Real Xh2o "H2O mass fraction at the outlet";
  Real Xo2 "O2 mass fraction at the outlet";
  Real Xso2 "SO2 mas fraction at the outlet";
  Real Xn2 "N2 mass fraction at the outlet";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_pT pro annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal humidity "Air humidity" annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  ThermoSysPro.Units.AbsolutePressure ppvap0(start=10000.0) "Intermediate vapor partial pressure";
  Modelica.SIunits.Density rho_vap0(start=200) "Intermediate H2O density";
equation
  if cardinality(humidity) == 0 then
    humidity.signal=hum0;
  end if;
  hum=humidity.signal;
  C1.P=C2.P;
  C1.T=C2.T;
  C1.Q=C2.Q;
  P=C1.P;
  T=C1.T;
  Xo2as=C1.Xo2;
  Xco2=0;
  Xso2=0;
  Xh2o=rho_vap/(rho_vap + rho_air);
  Xo2=Xo2as*(1 - Xh2o);
  Xn2=1 - Xco2 - Xh2o - Xo2 - Xso2;
  C2.Xco2=Xco2;
  C2.Xso2=Xso2;
  C2.Xh2o=Xh2o;
  C2.Xo2=Xo2;
  ppvap=psvap*hum;
  0=if ppvap < 6.108e-06 then ppvap0 - 6.108e-06 else ppvap - ppvap0;
  ppair=P - ppvap;
  psvap=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.psat(T);
  pro=ThermoSysPro.Properties.WaterSteam.IF97.Water_PT(ppvap, T, mode);
  rho_vap0=pro.d;
  0=if ppvap < 6.108e-06 then rho_vap - rho_vap0*ppvap/ppvap0 else rho_vap - rho_vap0;
  rho_air=ThermoSysPro.Properties.FlueGases.FlueGases_rho(ppair, T, Xco2, Xh2o, Xo2as, Xso2);
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-40,40},{40,-40}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(points={{0,100},{0,40}}, color={0,0,255}),Line(points={{20,60},{0,40},{-20,60}}, color={0,0,255}),Line(points={{-90,0},{-40,0}}, color={0,0,255}),Line(points={{40,0},{90,0}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-28,30},{28,-26}}, fillColor={0,0,255}, textString="H2O")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-40,40},{40,-40}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Line(points={{0,100},{0,40}}, color={0,0,255}),Line(points={{20,60},{0,40},{-20,60}}, color={0,0,255}),Line(points={{-90,0},{-40,0}}, color={0,0,255}),Line(points={{40,0},{90,0}}, color={0,0,255}),Text(lineColor={0,0,255}, extent={{-28,30},{28,-26}}, fillColor={0,0,255}, textString="H2O")}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end AirHumidity;

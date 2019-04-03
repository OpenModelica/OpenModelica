within ThermoSysPro.WaterSteam.HeatExchangers;
model StaticCondenser "Static condenser"
  parameter Modelica.SIunits.Area SCO=10000 "Heat exchange surface";
  parameter Real CPCE=0.02 "Pressure loss coefficient for the water side (Pa.s²/(kg.m**3))";
  parameter Modelica.SIunits.Height z=5 "Water level in the condenser";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer KCO=1 "Reference heat exchange coefficient";
  parameter Modelica.SIunits.MassFlowRate QC0=100 "Reference mass flow rate";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tref=293 "Rerence temperature";
  parameter Real COPR=1 "Reference fouling coefficient";
  parameter Real COP=1 "Actual fouling coefficient";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer mode_ee=1 "IF97 region at the water inlet. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_se=1 "IF97 region at the water outlet. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_ex=0 "IF97 region at the extraction point. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Modelica.SIunits.MassFlowRate Qee(start=10) "Cooling water mass flow rate at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hee(start=250000) "Cooling water specific anthalpy at the inlet";
  ThermoSysPro.Units.AbsolutePressure Pee(start=100000.0) "Cooling water pressure at the inlet";
  Modelica.SIunits.MassFlowRate Qep(start=10) "Drain mass flow rate at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hep(start=1000000) "Drain specific enthalpy at the inlet";
  Modelica.SIunits.MassFlowRate Qev(start=10) "Vapor mass flow rate at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hev(start=2500000) "Vapor specific enthalpy at the inlet";
  Modelica.SIunits.MassFlowRate Qvt(start=10) "Vapor mass flow rate leaving the turbine";
  ThermoSysPro.Units.SpecificEnthalpy Hvt(start=2500000) "Vapor specific enthalpy leaving the turbine";
  Modelica.SIunits.MassFlowRate Qse(start=10) "Cooling water mass flow rate at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hse(start=500000) "Cooling water specific enthalpy at the outlet";
  ThermoSysPro.Units.AbsolutePressure Pse(start=100000.0) "Cooling water pressure at the outlet";
  Modelica.SIunits.MassFlowRate Qex(start=10) "Drain mass flow rate at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hex(start=500000) "Drain specific enthalpy at the outlet";
  ThermoSysPro.Units.AbsolutePressure Pex(start=100000.0) "Drain pressure at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hsate(start=200000) "Water specific enthalpy at the saturation point";
  ThermoSysPro.Units.AbsolutePressure Pcond(start=17000) "Vapor pressure inside the condenser";
  ThermoSysPro.Units.AbsoluteTemperature Tsat(start=500) "Water temperature at the saturation point";
  ThermoSysPro.Units.AbsoluteTemperature Tee(start=300) "Cooling water temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tse(start=400) "Cooling water temperature at the outlet";
  Modelica.SIunits.Density rho_ee(start=900) "Cooling water density at the inlet";
  Modelica.SIunits.Density rho_ex(start=900) "Water density at the extraction point";
  Modelica.SIunits.CoefficientOfHeatTransfer KT1(start=50) "First reference value for the exchange coefficient";
  Modelica.SIunits.CoefficientOfHeatTransfer KT2(start=50) "Second reference value for the exchange coefficient";
  Modelica.SIunits.CoefficientOfHeatTransfer XKCO(start=200) "Heat transfer coefficient";
  ThermoSysPro.Units.SpecificEnthalpy Hmv(start=2500000) "Fluid input average specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hml(start=250000) "Extraction water average specific enthalpy";
  Modelica.SIunits.Power W "Heat power released to the cold source";
  Connectors.FluidInlet Cee "Cooling water inlet" annotation(Placement(transformation(x=-100.0, y=-61.0, scale=0.12, aspectRatio=0.916666666666667, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-61.0, scale=0.12, aspectRatio=0.916666666666667, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cse "Cooling water outlet" annotation(Placement(transformation(x=102.0, y=-61.0, scale=0.12, aspectRatio=0.916666666666667, flipHorizontal=false, flipVertical=false), iconTransformation(x=102.0, y=-61.0, scale=0.12, aspectRatio=0.916666666666667, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cex "Extraction water" annotation(Placement(transformation(x=1.0, y=-102.0, scale=0.13, aspectRatio=0.923076923076923, flipHorizontal=false, flipVertical=false), iconTransformation(x=1.0, y=-102.0, scale=0.13, aspectRatio=0.923076923076923, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Cvt "Turbine outlet" annotation(Placement(transformation(x=0.0, y=101.0, scale=0.13, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=101.0, scale=0.13, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proex "Propriétés de l'eau" annotation(Placement(transformation(x=70.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proee "Propriétés de l'eau" annotation(Placement(transformation(x=30.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prose "Propriétés de l'eau" annotation(Placement(transformation(x=90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat1 annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat1 annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Cep "Drain inlet" annotation(Placement(transformation(x=-100.0, y=19.0, scale=0.12, aspectRatio=0.916666666666667, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=19.0, scale=0.12, aspectRatio=0.916666666666667, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Cev "Vapor inlet" annotation(Placement(transformation(x=-100.0, y=61.0, scale=0.12, aspectRatio=0.916666666666667, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=61.0, scale=0.12, aspectRatio=0.916666666666667, flipHorizontal=false, flipVertical=false)));
protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=1.0 "Small number for pressure loss equation";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow rate for continuous flow reversal";
equation
  if cardinality(Cev) == 0 then
    Cev.Q=0;
    Cev.h=100000.0;
    Cev.b=true;
  end if;
  if cardinality(Cep) == 0 then
    Cep.Q=0;
    Cep.h=100000.0;
    Cep.b=true;
  end if;
  Qep=Cep.Q;
  Hep=Cep.h;
  Qev=Cev.Q;
  Hev=Cev.h;
  Qvt=Cvt.Q;
  Hvt=Cvt.h;
  Qee=Cee.Q;
  Hee=Cee.h;
  Pee=Cee.P;
  Qse=Cse.Q;
  Hse=Cse.h;
  Pse=Cse.P;
  Qex=Cex.Q;
  Pex=Cex.P;
  if continuous_flow_reversal then
    0=noEvent(if Qee > Qeps then Cee.h - Cee.h_vol else if Qee < -Qeps then Cse.h - Cse.h_vol else Cee.h - 0.5*((Cee.h_vol - Cse.h_vol)*Modelica.Math.sin(pi*Qee/2/Qeps) + Cee.h_vol + Cse.h_vol));
  else
    0=if Qee > 0 then Cee.h - Cee.h_vol else Cse.h - Cse.h_vol;
  end if;
  Qee=Qse;
  Pse=noEvent(if rho_ee > 0 then Pee - CPCE*ThermoSysPro.Functions.ThermoSquare(Qee, eps)/rho_ee else Pee);
  W=Qee*(Hse - Hee);
  Pcond=Cep.P;
  Pcond=Cev.P;
  Pcond=Cvt.P;
  Pex=Pcond + rho_ex*g*z;
  Hmv=Cvt.h_vol;
  Hmv=Cep.h_vol;
  Hmv=Cev.h_vol;
  Hex=Cex.h_vol;
  Qex=Qvt + Qep + Qev;
  W=Qvt*(Hvt - Hsate) + Qep*(Hep - Hsate) + Qev*(Hev - Hsate);
  Hmv=(Hvt*Qvt + Hev*Qev + Hep*Qep)/Qex;
  Hml=(Hsate + Hex)/2;
  Hex=noEvent(if rho_ex > 0 then Hsate + (Pex - Pcond)/rho_ex else Hsate);
  KT1=-0.05*(Tref - 273.16)^2 + 3.3*(Tref - 273.16) + 52;
  KT2=-0.05*(Tee - 273.16)^2 + 3.3*(Tee - 273.16) + 52;
  XKCO=KCO*(COP/COPR)*(KT2/KT1)*ThermoSysPro.Functions.ThermoRoot(Qee/QC0, Modelica.Constants.eps);
  0=Tsat - Tse - (Tsat - Tee)*exp(XKCO*SCO*((Tee - Tse)/W));
  proee=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pee, Hee, mode_ee);
  proex=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pex, Hex, mode_ex);
  prose=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pse, Hse, mode_se);
  rho_ee=proee.d;
  rho_ex=proex.d;
  Tee=proee.T;
  Tse=prose.T;
  Pcond=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.psat(Tsat);
  (lsat1,vsat1)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(Pcond);
  Hsate=lsat1.h;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{100,-82},{100,80},{-100,80},{-100,-82},{100,-82}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Text(lineColor={0,0,255}, extent={{-22,88},{20,70}}, fillColor={255,0,0}, lineThickness=1.0, textString="Turbine outlet"),Text(lineColor={0,0,255}, extent={{-82,24},{-52,16}}, fillColor={255,0,0}, lineThickness=1.0, textString="Drain inlet"),Text(lineColor={0,0,255}, extent={{-24,-52},{26,-72}}, fillColor={255,0,0}, lineThickness=1.0, textString="Extraction water"),Text(lineColor={0,0,255}, extent={{38,-58},{86,-66}}, fillColor={255,0,0}, lineThickness=1.0, textString="Cooling water outlet"),Text(lineColor={0,0,255}, extent={{-86,-52},{-32,-74}}, fillColor={255,0,0}, lineThickness=1.0, textString="Cooling water inlet"),Text(lineColor={0,0,255}, extent={{-86,66},{-50,54}}, fillColor={255,0,0}, lineThickness=1.0, textString="Vapor inlet"),Line(points={{0,8},{0,-70}}, color={255,0,0}, thickness=1.0),Polygon(points={{0,-90},{-11,-70},{11,-70},{0,-90}}, fillPattern=FillPattern.Solid, lineColor={255,0,0}, lineThickness=0.5, fillColor={191,0,0}),Line(points={{-100,8},{100,8}}, color={0,0,255}, thickness=0.5),Line(color={0,0,255}, points={{-100,-14},{80,-14},{80,-20},{-90,-20},{-90,-26},{80,-26},{80,-32},{-90,-32},{-90,-38},{100,-38}}, thickness=0.5)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{100,-86},{100,80},{-100,80},{-100,-86},{100,-86}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(color={0,0,255}, points={{-100,-14},{80,-14},{80,-20},{-90,-20},{-90,-26},{80,-26},{80,-32},{-90,-32},{-90,-38},{100,-38}}, thickness=0.5),Polygon(points={{0,-90},{-11,-70},{11,-70},{0,-90}}, fillPattern=FillPattern.Solid, lineColor={255,0,0}, lineThickness=0.5, fillColor={191,0,0}),Line(points={{0,8},{0,-70}}, color={255,0,0}, thickness=1.0),Line(points={{-100,8},{100,8}}, color={0,0,255}, thickness=0.5)}), Documentation(info="<html>
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
</ul>
</html>
"));
end StaticCondenser;

within ThermoSysPro.WaterSteam.Volumes;
model Pressurizer "Pressurizer"
  parameter Modelica.SIunits.Volume V=61.1 "Pressurizer volume";
  parameter Modelica.SIunits.Radius Rp=1.265 "Pressurizer cross-sectional radius";
  parameter Modelica.SIunits.Area Ae=1 "Wall surface";
  parameter Modelica.SIunits.Position Zm=10.15 "Hauteur de la gamme de mesure niveau";
  parameter Real Yw0=50 "Initial water level - percent of the measure scale level (active if steady_state=false)";
  parameter ThermoSysPro.Units.AbsolutePressure P0=15500000.0 "Initial fluid pressure (active if steady_state=false)";
  parameter Real Ccond=0.1 "Condensation coefficient";
  parameter Real Cevap=0.5 "Evaporation coefficient";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer Klv=500000.0 "Heat exchange coefficient between the liquid and gas phases";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer Klp=50000 "Heat exchange coefficient between the liquid phase and the wall";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer Kvp=25 "Heat exchange coefficient between the gas phase and the wall";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer Kpa=542 "Heat exchange coefficient between the wall and the outside";
  parameter Modelica.SIunits.Mass Mp=117000.0 "Wall mass";
  parameter Modelica.SIunits.SpecificHeatCapacity cpp=600 "Wall specific heat";
  parameter Boolean steady_state=true "true: start from steady state - false: start from (P0, Yw0)";
  Modelica.SIunits.Area Slpin "Exchange surface between the liquid and the wall";
  Modelica.SIunits.Area Svpin "Exchange surface between the vapor and the wall";
  Real Yw(start=50) "Liquid level as a percent of the measure scale";
  Real y(start=0.5) "Liquid level as a proportion of the measure scale";
  Modelica.SIunits.Position Zl(start=20) "Liquid level in the pressurizer";
  Modelica.SIunits.Volume Vl "Liquid phase volume";
  Modelica.SIunits.Volume Vv "Gas phase volume";
  ThermoSysPro.Units.AbsolutePressure P(start=15500000.0) "Average fluid pressure";
  ThermoSysPro.Units.AbsolutePressure Pfond "Fluid pressure at the bottom of the drum";
  ThermoSysPro.Units.SpecificEnthalpy hl "Liquid phase specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hv "Gas phase specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hls "Liquid phase saturation specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hvs "Gas phase saturation specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature Tl "Liquid phase temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tv "Gas phase temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tp(start=617.24) "Wall temperature";
  ThermoSysPro.Units.AbsoluteTemperature Ta "External temperature";
  Modelica.SIunits.Power Wlv "Thermal power exchanged from the gas phase to the liquid phase";
  Modelica.SIunits.Power Wpl "Thermal power exchanged from the liquid phase to the wall";
  Modelica.SIunits.Power Wpv "Thermal power exchanged from the gas phase to the wall";
  Modelica.SIunits.Power Wpa "Thermal power exchanged from the outside to the wall";
  Modelica.SIunits.Power Wch "Power released by the electrical heaters";
  Modelica.SIunits.MassFlowRate Qcond "Condensation mass flow rate from the vapor phase";
  Modelica.SIunits.MassFlowRate Qevap "Evaporation mass flow rate from the liquid phase";
  Modelica.SIunits.Density rhol(start=996) "Liquid phase density";
  Modelica.SIunits.Density rhov(start=1.5) "Vapor phase density";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{100,90},{100,60},{80,60},{80,60}}, thickness=1.0),Ellipse(lineColor={0,0,255}, extent={{-80,-92},{80,-42}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Rectangle(extent={{-80,-14},{80,-68}}, fillPattern=FillPattern.Solid, lineColor={127,191,255}, fillColor={127,191,255}),Ellipse(lineColor={0,0,255}, extent={{-80,42},{80,92}}, fillPattern=FillPattern.Solid, fillColor={255,255,255}),Line(color={0,0,255}, points={{0,40},{0,92}}, thickness=1.0),Line(points={{0,38},{0,92}}, color={255,255,255}),Rectangle(lineColor={0,0,255}, extent={{-80,-14},{80,68}}, fillPattern=FillPattern.Solid, fillColor={255,255,255}),Line(points={{-79,68},{80,68}}, color={255,255,255}),Line(points={{80,60},{100,60},{100,90}}, color={255,255,255})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-80,-92},{80,-42}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Rectangle(extent={{-80,-14},{80,-68}}, fillPattern=FillPattern.Solid, lineColor={127,191,255}, fillColor={127,191,255}),Ellipse(lineColor={0,0,255}, extent={{-80,42},{80,92}}, fillPattern=FillPattern.Solid, fillColor={255,255,255}),Line(color={0,0,255}, points={{0,40},{0,92}}, thickness=1.0),Line(points={{0,38},{0,92}}, color={255,255,255}),Rectangle(lineColor={0,0,255}, extent={{-80,-14},{80,68}}, fillPattern=FillPattern.Solid, fillColor={255,255,255}),Line(points={{-79,68},{80,68}}, color={255,255,255}),Text(lineColor={0,0,255}, extent={{58,4},{58,-10}}, fillColor={0,0,255}, textString="Niveau"),Line(color={0,0,255}, points={{100,90},{100,60},{80,60},{80,60}}, thickness=1.0),Line(points={{80,60},{100,60},{100,90}}, color={255,255,255})}), Documentation(info="<html>
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
  Connectors.FluidInlet Cas "Water input" annotation(Placement(transformation(x=0.0, y=100.0, scale=0.08, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=100.0, scale=0.08, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs "Steam output" annotation(Placement(transformation(x=100.0, y=98.0, scale=0.08, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=98.0, scale=0.08, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Ca "Thermal input to the wall" annotation(Placement(transformation(x=-90.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cc "Thermal input to the liquid" annotation(Placement(transformation(x=0.0, y=-32.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-32.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal yLevel "Water level" annotation(Placement(transformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cex "Water output" annotation(Placement(transformation(x=0.0, y=-100.0, scale=0.08, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-100.0, scale=0.08, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "Pi";
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  parameter Modelica.SIunits.Area Ap=pi*Rp*Rp "Pressurizer cross-sectional area";
protected
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prol;
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prov;
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat;
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat;
initial equation
  if steady_state then
    der(P)=0;
    der(hl)=0;
    der(hv)=0;
    der(y)=0;
    der(Tp)=0;
  else
    P=P0;
    hl=hls;
    hv=hvs;
    Yw=Yw0;
    der(Tp)=0;
  end if;
equation
  if cardinality(Cas) == 0 then
    Cas.Q=0;
    Cas.h=100000.0;
    Cas.b=true;
  end if;
  if cardinality(Cex) == 0 then
    Cex.Q=0;
    Cex.h=100000.0;
    Cex.a=true;
  end if;
  if cardinality(Cs) == 0 then
    Cs.Q=0;
    Cs.h=100000.0;
    Cs.a=true;
  end if;
  Cas.P=P;
  Cs.P=P;
  Cex.P=Pfond;
  Cas.h_vol=hl;
  Cs.h_vol=hv;
  Cex.h_vol=hl;
  Ca.W=Wpa;
  Ca.T=Ta;
  Cc.W=Wch;
  Cc.T=Tl;
  yLevel.signal=Yw;
  Yw=100*y;
  Zl=Zm*y + 0.5*(V/Ap - Zm);
  Vl=Ap*Zl;
  Vv=V - Vl;
  Slpin=Zl*2*pi*Rp;
  Svpin=(V/Ap - Zl)*2*pi*Rp;
  rhol*Ap*Zm*der(y) + Vl*prol.ddph*der(P) + Vl*prol.ddhp*der(hl)=Cas.Q - Cex.Q + Qcond - Qevap;
  -rhov*Ap*Zm*der(y) + Vv*prov.ddph*der(P) + Vv*prov.ddhp*der(hv)=Qevap - Cs.Q - Qcond;
  rhol*Vl*der(hl) - Vl*der(P)=(Qcond + Cas.Q)*(hls - hl) - Qevap*(hvs - hl) - Cex.Q*(Cex.h - hl) - Wpl + Wlv + Wch;
  rhov*Vv*der(hv) - Vv*der(P)=Qevap*(hvs - hv) - Qcond*(hls - hv) - Cas.Q*(hls - Cas.h) - Wpv - Wlv - Cs.Q*(Cs.h - hv);
  Mp*cpp*der(Tp)=Wpl + Wpv + Wpa;
  Wlv=Klv*Ap*(Tv - Tl);
  Wpl=Klp*Slpin*(Tl - Tp);
  Wpv=Kvp*Svpin*(Tv - Tp);
  Wpa=Kpa*Ae*(Ta - Tp);
  Pfond=P + g*(Vl*rhol + Vv*rhov)/Ap;
  Qevap=Cevap*rhol*Vl*(hl - hls)/(hvs - hls);
  Qcond=noEvent(Ccond*rhov*Vv*(hvs - hv)/(hvs - hls) + (Cas.Q*(hls - Cas.h) + 0.5*(Wpv + abs(Wpv)) + Wlv)/(hv - hls));
  prol=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, hl, 0);
  prov=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, hv, 0);
  (lsat,vsat)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P);
  Tl=prol.T;
  Tv=prov.T;
  rhol=prol.d;
  rhov=prov.d;
  hls=lsat.h;
  hvs=vsat.h;
end Pressurizer;

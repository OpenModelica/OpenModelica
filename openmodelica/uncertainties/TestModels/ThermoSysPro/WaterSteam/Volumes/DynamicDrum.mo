within ThermoSysPro.WaterSteam.Volumes;
model DynamicDrum "Dynamic drum"
  parameter Boolean Vertical=true "true: vertical cylinder - false: horizontal cylinder";
  parameter Modelica.SIunits.Radius R=1.05 "Radius of the drum cross-sectional area";
  parameter Modelica.SIunits.Length L=16.27 "Drum length";
  parameter Real Vf0=0.5 "Fraction of initial water volume in the drum (active if steady_state=false)";
  parameter ThermoSysPro.Units.AbsolutePressure P0=5000000.0 "Fluid initial pressure (active if steady_state=false)";
  parameter Real Ccond=0.01 "Condensation coefficient";
  parameter Real Cevap=0.09 "Evaporation coefficient";
  parameter Real Xlo=0.0025 "Vapor mass fraction in the liquid phase from which the liquid starts to evaporate";
  parameter Real Xvo=0.9975 "Vapor mass fraction in the gas phase from which the liquid starts to condensate";
  parameter Real Kvl=1000 "Heat exchange coefficient between the liquid and gas phases";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer Klp=400 "Heat exchange coefficient between the liquid phase and the wall";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer Kvp=100 "Heat exchange coefficient between the gas phase and the wall";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer Kpa=25 "Heat exchange coefficient between the wall and the outside";
  parameter Modelica.SIunits.Mass Mp=117000.0 "Wall mass";
  parameter Modelica.SIunits.SpecificHeatCapacity cpp=600 "Wall specific heat";
  parameter Boolean steady_state=true "true: start from steady state - false: start from (P0, Vf0)";
  ThermoSysPro.Units.AbsolutePressure P "Fluid average pressure";
  ThermoSysPro.Units.AbsolutePressure Pfond "Fluid pressure at the bottom of the drum";
  ThermoSysPro.Units.SpecificEnthalpy hl "Liquid phase specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hv "Gas phase specific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature Tl "Liquid phase temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tv "Gas phase temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tp(start=550) "Wall temperature";
  ThermoSysPro.Units.AbsoluteTemperature Ta "External temperature";
  Modelica.SIunits.Volume Vl "Liquid phase volume";
  Modelica.SIunits.Volume Vv "Gas phase volume";
  Modelica.SIunits.Area Alp "Liquid phase surface on contact with the wall";
  Modelica.SIunits.Area Avp "Gas phase surface on contact with the wall";
  Modelica.SIunits.Area Ape "Wall surface on contact with the outside";
  Real xl(start=0.5) "Mass vapor fraction in the liquid phase";
  Real xv(start=0) "Mass vapor fraction in the vapor phase";
  Real xmv(start=0.5) "Mass vapor fraction in the ascending tube";
  Modelica.SIunits.Density rhol(start=996) "Liquid phase density";
  Modelica.SIunits.Density rhov(start=1.5) "Gas phase density";
  Modelica.SIunits.MassFlowRate BQl "Right hand side of the mass balance equation of the liquid phase";
  Modelica.SIunits.MassFlowRate BQv "Right hand side of the mass balance equation of the gas phase";
  Modelica.SIunits.Power BHl "Right hand side of the energy balance equation of the liquid phase";
  Modelica.SIunits.Power BHv "Right hand side of the energy balance equation of the gas phase";
  Modelica.SIunits.MassFlowRate Qcond "Condensation mass flow rate from the vapor phase";
  Modelica.SIunits.MassFlowRate Qevap "Evaporation mass flow rate from the liquid phase";
  Modelica.SIunits.Power Wlv "Thermal power exchanged from the gas phase to the liquid phase";
  Modelica.SIunits.Power Wpl "Thermal power exchanged from the liquid phase to the wall";
  Modelica.SIunits.Power Wpv "Thermal power exchanged from the gas phase to the wall";
  Modelica.SIunits.Power Wpa "Thermal power exchanged from the outside to the wall";
  Modelica.SIunits.Position zl(start=1.05) "Liquid level in drum";
  Modelica.SIunits.Area Al "Cross sectional area of the liquid phase";
  Modelica.SIunits.Angle theta "Angle";
  Modelica.SIunits.Area Avl(start=1.0) "Heat exchange surface between the liquid and gas phases";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prol "Propriétés de l'eau dans le ballon" annotation(Placement(transformation(x=-40.0, y=60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prov "Propriétés de la vapeur dans le ballon" annotation(Placement(transformation(x=20.0, y=60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prom annotation(Placement(transformation(x=-40.0, y=0.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation(Placement(transformation(x=-40.0, y=-60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation(Placement(transformation(x=20.0, y=-60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-90,100},{-68,100},{-60,80}}),Line(color={0,0,255}, points={{-90,-100},{-68,-100},{-60,-80}}),Line(color={0,0,255}, points={{62,80},{70,100},{90,100}}),Polygon(lineColor={0,0,255}, points={{0,100},{-20,98},{-40,92},{-60,80},{-80,60},{-92,40},{-98,20},{-100,0},{-98,-20},{98,-20},{100,0},{98,20},{92,40},{80,60},{60,80},{40,92},{20,98},{0,100}}, fillPattern=FillPattern.Solid, fillColor={255,255,255}),Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Line(color={0,0,255}, points={{60,-80},{72,-100},{90,-100}}),Polygon(lineColor={0,0,255}, points={{0,100},{-20,98},{-40,92},{-60,80},{-80,60},{-92,40},{-98,20},{-100,0},{-98,-20},{98,-20},{100,0},{98,20},{92,40},{80,60},{60,80},{40,92},{20,98},{0,100}}, fillPattern=FillPattern.Solid, fillColor={159,223,223})}), Documentation(info="<html>
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
  Connectors.FluidInlet Ce1 "Feedwater input 1" annotation(Placement(transformation(x=-100.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Cm "Evaporation loop outlet" annotation(Placement(transformation(x=100.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cd "Evaporation loop inlet" annotation(Placement(transformation(x=-100.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cv "Steam outlet" annotation(Placement(transformation(x=100.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal yLevel "Water level " annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cth "Thermal input to the liquid" annotation(Placement(transformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cex "Thermal input to the wall" annotation(Placement(transformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prod annotation(Placement(transformation(x=20.0, y=0.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce2 "Feedwater input 2" annotation(Placement(transformation(x=-100.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce3 "Feedwater input 3" annotation(Placement(transformation(x=-100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cs "Water outlet" annotation(Placement(transformation(x=100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-40.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  parameter Modelica.SIunits.Volume V=pi*R^2*L "Drum volume";
  parameter Modelica.SIunits.Volume Vmin=1e-06;
initial equation
  if steady_state then
    der(hl)=0;
    der(hv)=0;
    der(P)=0;
    der(Vl)=0;
    der(Tp)=0;
  else
    hl=lsat.h;
    hv=vsat.h;
    P=P0;
    Vl=Vf0*V;
    der(Tp)=0;
  end if;
equation
  if cardinality(Ce1) == 0 then
    Ce1.Q=0;
    Ce1.h=100000.0;
    Ce1.b=true;
  end if;
  if cardinality(Ce2) == 0 then
    Ce2.Q=0;
    Ce2.h=100000.0;
    Ce2.b=true;
  end if;
  if cardinality(Ce3) == 0 then
    Ce3.Q=0;
    Ce3.h=100000.0;
    Ce3.b=true;
  end if;
  if cardinality(Cd) == 0 then
    Cd.Q=0;
    Cd.h=100000.0;
    Cd.a=true;
  end if;
  if cardinality(Cs) == 0 then
    Cs.Q=0;
    Cs.h=100000.0;
    Cs.a=true;
  end if;
  if cardinality(Cm) == 0 then
    Cm.Q=0;
    Cm.h=100000.0;
    Cm.b=true;
  end if;
  if cardinality(Cv) == 0 then
    Cv.Q=0;
    Cv.h=100000.0;
    Cv.a=true;
  end if;
  Ce1.P=P;
  Ce2.P=P;
  Ce3.P=P;
  Cv.P=P;
  Cd.P=Pfond;
  Cs.P=P;
  Cm.P=P;
  if Vertical then
    theta=1;
    Al=pi*R^2;
    Vl=Al*zl;
    Avl=Al;
  else
    theta=Modelica.Math.asin(max(-0.9999, min(0.9999, (R - zl)/R)));
    Al=(pi/2 - theta)*R^2 - R*(R - zl)*Modelica.Math.cos(theta);
    Vl=Al*L;
    Avl=2*R*Modelica.Math.cos(theta)*L;
  end if;
  Vl + Vv=V;
  yLevel.signal=zl;
  Alp=if Vertical then 2*sqrt(pi/Al)*Vl + Al else (pi - 2*theta)*R*L + 2*Al;
  Avp=if Vertical then 2*sqrt(pi/Al)*Vv + Al else (pi + 2*theta)*R*L + 2*Al;
  Ape=Alp + Avp;
  Pfond=P + prod.d*g*zl;
  BQl=Ce1.Q + Ce2.Q + Ce3.Q - Cd.Q - Cs.Q + (1 - xmv)*Cm.Q + Qcond - Qevap;
  rhol*der(Vl) + Vl*(prol.ddph*der(P) + prol.ddhp*der(hl))=BQl;
  BQv=xmv*Cm.Q - Cv.Q + Qevap - Qcond;
  rhov*der(Vv) + Vv*(prov.ddph*der(P) + prov.ddhp*der(hv))=BQv;
  BHl=Ce1.Q*(Ce1.h - (hl - P/rhol)) + Ce2.Q*(Ce2.h - (hl - P/rhol)) + Ce3.Q*(Ce3.h - (hl - P/rhol)) - Cd.Q*(Cd.h - (hl - P/rhol)) - Cs.Q*(Cs.h - (hl - P/rhol)) + (1 - xmv)*Cm.Q*((if xmv > 0 then lsat.h else Cm.h) - (hl - P/rhol)) + Qcond*(lsat.h - (hl - P/rhol)) - Qevap*(vsat.h - (hl - P/rhol)) + Wlv - Wpl + Cth.W;
  Vl*((P/rhol*prol.ddph - 1)*der(P) + (P/rhol*prol.ddhp + rhol)*der(hl))=BHl;
  Ce1.h_vol=hl;
  Ce2.h_vol=hl;
  Ce3.h_vol=hl;
  Cd.h_vol=noEvent(min(lsat.h, hl));
  Cs.h_vol=hl;
  BHv=xmv*Cm.Q*((if xmv < 1 then vsat.h else Cm.h) - (hv - P/rhov)) - Cv.Q*(Cv.h - (hv - P/rhov)) + Qevap*(vsat.h - (hv - P/rhov)) - Qcond*(lsat.h - (hv - P/rhov)) - Wlv - Wpv;
  Vv*((P/rhov*prov.ddph - 1)*der(P) + (P/rhov*prov.ddhp + rhov)*der(hv))=BHv;
  Cm.h_vol=hl;
  Cv.h_vol=hv;
  Mp*cpp*der(Tp)=Wpl + Wpv + Wpa;
  Wlv=Kvl*Avl*(Tv - Tl);
  Wpl=Klp*Alp*(Tl - Tp);
  Wpv=Kvp*Avp*(Tv - Tp);
  Wpa=Kpa*Ape*(Ta - Tp);
  Qcond=if noEvent(xv < Xvo) then Ccond*rhov*Vv*(Xvo - xv) else 0;
  Qevap=if noEvent(xl > Xlo) then Cevap*rhol*Vl*(xl - Xlo) else 0;
  prol=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, hl);
  prov=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, hv);
  prod=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pfond, Cd.h);
  prom=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, Cm.h);
  (lsat,vsat)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P);
  Tl=prol.T;
  rhol=prol.d;
  xl=prol.x;
  Tv=prov.T;
  rhov=prov.d;
  xv=prov.x;
  xmv=if noEvent(Cm.Q > 0) then prom.x else 0;
  Cth.T=Tl;
  Cex.T=Ta;
  Cex.W=Wpa;
end DynamicDrum;

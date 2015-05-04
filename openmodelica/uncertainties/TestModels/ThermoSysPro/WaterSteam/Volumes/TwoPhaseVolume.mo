within ThermoSysPro.WaterSteam.Volumes;
model TwoPhaseVolume "TwoPhaseVolume"
  parameter Modelica.SIunits.Volume V=1 "Cavity volume";
  parameter Modelica.SIunits.Area A=1 "Cavity cross-sectional area";
  parameter Real Vf0=0.5 "Fraction of initial water volume in the drum (active if steady_state=false)";
  parameter ThermoSysPro.Units.AbsolutePressure P0=10000.0 "Fluid initial pressure (active if steady_state=false)";
  parameter Real Ccond=0.01 "Condensation coefficient";
  parameter Real Cevap=0.09 "Evaporation coefficient";
  parameter Real Xlo=0.0025 "Vapor mass fraction in the liquid phase from which the liquid starts to evaporate";
  parameter Real Xvo=0.9975 "Vapor mass fraction in the gas phase from which the liquid starts to condensate";
  parameter Modelica.SIunits.Area Avl=A "Heat exchange surface between the liquid and gas phases";
  parameter Real Kvl=1000 "Heat exchange coefficient between the liquid and gas phases";
  parameter Boolean steady_state=true "true: start from steady state - false: start from (P0, Vl0)";
  ThermoSysPro.Units.AbsolutePressure P "Fluid average pressure";
  ThermoSysPro.Units.AbsolutePressure Pfond "Fluid pressure at the bottom of the cavity";
  ThermoSysPro.Units.SpecificEnthalpy hl "Liquid phase spepcific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hv "Gas phase spepcific enthalpy";
  ThermoSysPro.Units.AbsoluteTemperature Tl "Liquid phase temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tv "Gas phase temperature";
  Modelica.SIunits.Volume Vl "Liquid phase volume";
  Modelica.SIunits.Volume Vv "Gas phase volume";
  Real xl(start=0.5) "Mass vapor fraction in the liquid phase";
  Real xv(start=0) "Mass vapor fraction in the gas phase";
  Modelica.SIunits.Density rhol(start=996) "Liquid phase density";
  Modelica.SIunits.Density rhov(start=1.5) "Gas phase density";
  Modelica.SIunits.MassFlowRate BQl "Right hand side of the mass balance equation of the liquid phase";
  Modelica.SIunits.MassFlowRate BQv "Right hand side of the mass balance equation of the gas phaser";
  Modelica.SIunits.Power BHl "Right hand side of the energy balance equation of the liquid phase";
  Modelica.SIunits.Power BHv "Right hand side of the energy balance equation of the gas phase";
  Modelica.SIunits.MassFlowRate Qcond "Condensation mass flow rate from the vapor phase";
  Modelica.SIunits.MassFlowRate Qevap "Evaporation mass flow rate from the liquid phase";
  Modelica.SIunits.Power Wvl "Thermal power exchanged from the gas phase to the liquid phase";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prol "Propriétés de l'eau dans le ballon" annotation(Placement(transformation(x=-40.0, y=60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prov "Propriétés de la vapeur dans le ballon" annotation(Placement(transformation(x=20.0, y=60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation(Placement(transformation(x=-40.0, y=-60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation(Placement(transformation(x=20.0, y=-60.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{0,100},{-20,98},{-40,92},{-60,80},{-80,60},{-92,40},{-98,20},{-100,0},{-98,-20},{98,-20},{100,0},{98,20},{92,40},{80,60},{60,80},{40,92},{20,98},{0,100}}, fillPattern=FillPattern.Solid, fillColor={255,255,255}),Ellipse(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Polygon(lineColor={0,0,255}, points={{0,100},{-20,98},{-40,92},{-60,80},{-80,60},{-92,40},{-98,20},{-100,0},{-98,-20},{98,-20},{100,0},{98,20},{92,40},{80,60},{60,80},{40,92},{20,98},{0,100}}, fillPattern=FillPattern.Solid, fillColor={159,223,223})}), Documentation(info="<html>
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
  Connectors.FluidInlet Cv "Steam input" annotation(Placement(transformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet Cl "Water output" annotation(Placement(transformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cth annotation(Placement(transformation(x=0.0, y=20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal yLevel "Water level" annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prod annotation(Placement(transformation(x=-40.0, y=0.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet Ce "Water input" annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
initial equation
  if steady_state then
    der(hl)=0;
    der(hv)=0;
    der(Vl)=0;
    der(P)=0;
  else
    hl=lsat.h;
    hv=vsat.h;
    Vl=Vf0*V;
    P=P0;
  end if;
equation
  if cardinality(Cl) == 0 then
    Cl.Q=0;
    Cl.h=100000.0;
    Cl.b=true;
  end if;
  if cardinality(Cv) == 0 then
    Cv.Q=0;
    Cv.h=100000.0;
    Cv.a=true;
  end if;
  if cardinality(Ce) == 0 then
    Ce.Q=0;
    Ce.h=100000.0;
    Ce.b=true;
  end if;
  Cl.P=Pfond;
  Cv.P=P;
  Ce.P=P;
  V=Vl + Vv;
  Pfond=P + prod.d*g*Vl/A;
  BQl=-Cl.Q + Qcond - Qevap + Ce.Q;
  rhol*der(Vl) + Vl*(prol.ddph*der(P) + prol.ddhp*der(hl))=BQl;
  BQv=Cv.Q + Qevap - Qcond;
  rhov*der(Vv) + Vv*(prov.ddph*der(P) + prov.ddhp*der(hv))=BQv;
  BHl=-Cl.Q*(Cl.h - (hl - P/rhol)) + Qcond*(lsat.h - (hl - P/rhol)) - Qevap*(vsat.h - (hl - P/rhol)) + Ce.Q*(Ce.h - (hl - P/rhol)) + Wvl;
  Vl*((P/rhol*prol.ddph - 1)*der(P) + (P/rhol*prol.ddhp + rhol)*der(hl))=BHl;
  Cl.h_vol=hl;
  Ce.h_vol=hl;
  BHv=Cv.Q*(Cv.h - (hv - P/rhov)) + Qevap*(vsat.h - (hv - P/rhov)) - Qcond*(lsat.h - (hv - P/rhov)) - Wvl + Cth.W;
  Vv*((P/rhov*prov.ddph - 1)*der(P) + (P/rhov*prov.ddhp + rhov)*der(hv))=BHv;
  Cv.h_vol=hv;
  Wvl=Kvl*Avl*(Tv - Tl);
  Qcond=if xv < Xvo then Ccond*rhov*Vv*(Xvo - xv) else 0;
  Qevap=if xl > Xlo then Cevap*rhol*Vl*(xl - Xlo) else 0;
  yLevel.signal=Vl/A;
  prol=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, hl);
  prov=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P, hv);
  prod=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pfond, Cl.h);
  (lsat,vsat)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P);
  Tl=prol.T;
  rhol=prol.d;
  xl=prol.x;
  Tv=prov.T;
  rhov=prov.d;
  xv=prov.x;
  Cth.T=Tv;
end TwoPhaseVolume;

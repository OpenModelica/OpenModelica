within ThermoSysPro.HeatNetworksCooling;
model LatentHeatStorage "Latent heat storage"
  parameter Modelica.SIunits.Area S=1 "Exchange surface";
  parameter Modelica.SIunits.Area Samb=1 "Exchange surface with the ambient air";
  parameter Modelica.SIunits.Volume V=1 "Storage volume";
  parameter Modelica.SIunits.SpecificHeatCapacity CpL=4.18 "Fluid specific heat capacity";
  parameter Modelica.SIunits.SpecificHeatCapacity CpS=4.18 "Storage specific heat capacity";
  parameter Modelica.SIunits.ThermalConductivity Lambda=0.585 "PCM (phase change material) thermal conductivity";
  parameter Modelica.SIunits.ThermalConductivity LambdaC=0.585 "Insulation thermal conductivity";
  parameter Modelica.SIunits.Length ep=0.1 "PCM thickness";
  parameter Modelica.SIunits.Length epC=0.1 "Insulation thickness";
  parameter Modelica.SIunits.Density rhom=1000 "PCM density";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer h=20 "Convective heat exchange coefficient with the water";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer ha=20 "Convective heat exchange coefficient with the ambient air";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tamb "Ambient air temperature";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tsl0 "Initial storage temperature (active if steady_state=false)";
  parameter Real xL0=0.5 "Initial liquid PCM fraction";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tfusion=293 "PCM fusion temperature";
  parameter Modelica.SIunits.SpecificEnergy hfus "PCM fusion specific enthalpy";
  parameter Real Fremp=0.5 "Volume fraction of the storage filled by the PCM";
  parameter Boolean steady_state=false "true: start from steady state - false: start from Tsl0";
  parameter Integer mode_e=0 "IF97 region at the inlet. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_s=0 "IF97 region at the outlet. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Modelica.SIunits.MassFlowRate Q "Water mass flow rate";
  Modelica.SIunits.Mass m "PCM mass";
  ThermoSysPro.Units.AbsoluteTemperature Tsl "Storage average temperature";
  Real xL "Liquid PCM fraction in the storage";
  ThermoSysPro.Units.AbsoluteTemperature T1 "Water temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature T2 "Water temperature at the outlet";
  Modelica.SIunits.Power Ws "Stored power";
  Modelica.SIunits.Power We "Power exchanged with the water";
  Modelica.SIunits.Power Wa "Power exchanged with the ambient air";
  ThermoSysPro.Units.SpecificEnthalpy Hsl "Storage specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy HsatL "Storage specific enthalpy at the liquid saturation temperature";
  ThermoSysPro.Units.SpecificEnthalpy HsatS "Storage specific enthalpy at the solid saturation temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tm(start=293) "Water average temperature";
  ThermoSysPro.Units.AbsolutePressure Pm(start=100000.0) "Water average pressure";
  ThermoSysPro.Units.SpecificEnthalpy hm(start=100000) "Water average specific enthalpy";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proe "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,50},{-40,100},{40,100},{80,52},{80,-50},{40,-100},{-40,-100},{-80,-48},{-80,50}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={0,191,0}),Text(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, textString="L", fillColor={0,0,255})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,50},{-40,100},{40,100},{80,52},{80,-50},{40,-100},{-40,-100},{-80,-48},{-80,50}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={0,191,0}),Text(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillColor={0,0,255}, textString="L")}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Benoît Bride</li>
</ul>
</html>
"));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce annotation(Placement(transformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs annotation(Placement(transformation(x=90.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=-30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pros "Propriétés de l'eau" annotation(Placement(transformation(x=90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
initial equation
  if steady_state then
    der(Hsl)=0;
  else
    if Tsl0 < Tfusion then
      Hsl=CpS*(Tsl0 - 273);
    elseif Tsl0 > Tfusion then
      Hsl=CpS*(Tfusion - 273) + hfus + CpL*(Tsl0 - Tfusion);
    else
      Hsl=CpS*(Tfusion - 273) + hfus*xL0;
    end if;
  end if;
equation
  if cardinality(Ce) == 0 then
    Ce.Q=0;
    Ce.h=100000.0;
    Ce.b=true;
  end if;
  if cardinality(Cs) == 0 then
    Cs.Q=0;
    Cs.h=100000.0;
    Cs.a=true;
  end if;
  Ce.P=Cs.P;
  Ce.Q=Cs.Q;
  Q=Ce.Q;
  0=noEvent(if Q > Qeps then Ce.h - Ce.h_vol else if Q < -Qeps then Cs.h - Cs.h_vol else Ce.h - 0.5*((Ce.h_vol - Cs.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + Ce.h_vol + Cs.h_vol));
  Pm=Ce.P;
  if abs(Q) < Qeps then
    Tm=T2;
  else
    Tm=(T1 + T2)/2;
  end if;
  hm=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(Pm, Tm, 0);
  proe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ce.P, Ce.h, mode_e);
  pros=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Cs.P, Cs.h, mode_s);
  T1=proe.T;
  T2=pros.T;
  HsatL=CpS*(Tfusion - 273) + hfus;
  HsatS=CpS*(Tfusion - 273);
  Ws=m*der(Hsl);
  Ws=We + Wa;
  if Hsl < HsatS then
    xL=0;
    Tsl=273 + Hsl/CpS;
  elseif Hsl > HsatL then
    xL=1;
    Tsl=Tfusion + (Hsl - HsatL)/CpL;
  else
    xL=(Hsl - HsatS)/(HsatL - HsatS);
    Tsl=Tfusion;
  end if;
  if abs(Q) < Qeps then
    We=0;
    Tm=Tsl;
  else
    We=Q*(Ce.h - Cs.h);
    Tm=Tsl + We*(ep/Lambda + 1/h)/S;
  end if;
  Wa=1/(epC/LambdaC + 1/ha)*Samb*(Tamb - Tsl);
  m=rhom*V*Fremp;
end LatentHeatStorage;

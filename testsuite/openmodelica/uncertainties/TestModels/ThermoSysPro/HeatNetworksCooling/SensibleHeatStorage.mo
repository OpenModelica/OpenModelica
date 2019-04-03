within ThermoSysPro.HeatNetworksCooling;
model SensibleHeatStorage "Sensible heat storage"
  parameter Modelica.SIunits.Area S=1 "Exchange surface between the water and the surface";
  parameter Modelica.SIunits.Area Samb=1 "Echange surface with the ambient air";
  parameter Modelica.SIunits.Volume V=1 "Storage volume";
  parameter Modelica.SIunits.SpecificHeatCapacity Cp=4000 "PCM specific heat capacity";
  parameter Modelica.SIunits.ThermalConductivity Lambda=20 "PCM thermal conductivity";
  parameter Modelica.SIunits.ThermalConductivity LambdaC=0.04 "Insulation thermal conductivity";
  parameter Modelica.SIunits.Length ep=0.1 "PCM thickness";
  parameter Modelica.SIunits.Length epC=0.1 "Insulation thickness";
  parameter Modelica.SIunits.Density rhom=2000 "PCM density";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer h=20 "Convective heat exchange coefficient with the water";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer ha=20 "Convective heat exchange coefficient with the ambient air";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tamb "Ambient air temperature";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tss0 "Initial storage temperature (active if steady_state=false)";
  parameter Real Fremp=0.5 "Volume fraction of the solid matrix in the storage";
  parameter Boolean steady_state=false "true: start from steady state - false: start from Tss0";
  parameter Integer mode_e=0 "IF97 region at the inlet. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer mode_s=0 "IF97 region at the outlet. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Modelica.SIunits.MassFlowRate Q "Water mass flow rate";
  Modelica.SIunits.Mass m "PCM mass";
  ThermoSysPro.Units.AbsoluteTemperature Tss(start=293) "Storage average temperature";
  ThermoSysPro.Units.AbsoluteTemperature T1 "Water temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature T2 "Water temperature at the outlet";
  Modelica.SIunits.Power Ws "Stored power";
  Modelica.SIunits.Power We "Power exchanged with the water";
  Modelica.SIunits.Power Wa "Power exchanged with the ambient air";
  ThermoSysPro.Units.AbsoluteTemperature Tm(start=293) "Average temperature";
  ThermoSysPro.Units.AbsolutePressure Pm(start=100000.0) "Average pressure";
  ThermoSysPro.Units.SpecificEnthalpy hm(start=100000) "Average specific enthalpy";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proe "Propriétés de l'eau" annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,50},{-40,100},{40,100},{80,52},{80,-50},{40,-100},{-40,-100},{-80,-48},{-80,50}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={0,191,0}),Text(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillColor={0,0,255}, textString="S")}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-80,50},{-40,100},{40,100},{80,52},{80,-50},{40,-100},{-40,-100},{-80,-48},{-80,50}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={0,191,0}),Text(lineColor={0,0,255}, extent={{-100,100},{100,-100}}, fillColor={0,0,255}, textString="S")}), Documentation(info="<html>
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
initial equation
  if steady_state then
    der(Tss)=0;
  else
    Tss=Tss0;
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
  0=if Q > 0 then hm - Ce.h_vol else hm - Cs.h_vol;
  Pm=Ce.P;
  Tm=(T1 + T2)/2;
  hm=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(Pm, Tm, 0);
  proe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ce.P, Ce.h, mode_e);
  pros=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Cs.P, Cs.h, mode_s);
  T1=proe.T;
  T2=pros.T;
  Ws=m*Cp*der(Tss);
  Ws=We + Wa;
  We=1/(ep/Lambda + 1/h)*S*(Tm - Tss);
  We=Q*(Ce.h - Cs.h);
  Wa=1/(epC/LambdaC + 1/ha)*Samb*(Tamb - Tss);
  m=rhom*V*Fremp;
end SensibleHeatStorage;

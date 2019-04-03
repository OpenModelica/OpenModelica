within ThermoSysPro.WaterSteam.HeatExchangers;
model SimpleStaticCondenser "Simple static condenser"
  parameter Real Kc=10 "Friction pressure loss coefficient for the hot side";
  parameter Real Kf=10 "Friction pressure loss coefficient for the cold side";
  parameter Modelica.SIunits.Position z1c=0 "Hot inlet altitude";
  parameter Modelica.SIunits.Position z2c=0 "Hot outlet altitude";
  parameter Modelica.SIunits.Position z1f=0 "Cold inlet altitude";
  parameter Modelica.SIunits.Position z2f=0 "Cold outlet altitude";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Modelica.SIunits.Density p_rhoc=0 "If > 0, fixed fluid density for the hot side";
  parameter Modelica.SIunits.Density p_rhof=0 "If > 0, fixed fluid density for the cold side";
  parameter Integer modec=0 "IF97 region of the water for the hot side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer modecs=0 "IF97 region of the water at the outlet of the hot side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  parameter Integer modef=0 "IF97 region of the water for the cold side. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Modelica.SIunits.Power W(start=1000000.0) "Power exchanged from the hot side to the cold side";
  ThermoSysPro.Units.AbsoluteTemperature Tec(start=500) "Fluid temperature at the inlet of the hot side";
  ThermoSysPro.Units.AbsoluteTemperature Tsc(start=400) "Fluid temperature at the outlet of the hot side";
  ThermoSysPro.Units.AbsoluteTemperature Tef(start=350) "Fluid temperature at the inlet of the cold side";
  ThermoSysPro.Units.AbsoluteTemperature Tsf(start=350) "Fluid temperature at the outlet of the cold side";
  ThermoSysPro.Units.DifferentialPressure DPfc(start=1000.0) "Friction pressure loss in the hot side";
  ThermoSysPro.Units.DifferentialPressure DPgc(start=100.0) "Gravity pressure loss in the hot side";
  ThermoSysPro.Units.DifferentialPressure DPc(start=1000.0) "Total pressure loss in the hot side";
  ThermoSysPro.Units.DifferentialPressure DPff(start=1000.0) "Friction pressure loss in the cold side";
  ThermoSysPro.Units.DifferentialPressure DPgf(start=100.0) "Gravity pressure loss in the cold side";
  ThermoSysPro.Units.DifferentialPressure DPf(start=1000.0) "Total pressure loss in the cold side";
  Modelica.SIunits.Density rhoc(start=998) "Density of the fluid in the hot side";
  Modelica.SIunits.Density rhof(start=998) "Density of the fluid in the cold side";
  Modelica.SIunits.MassFlowRate Qc(start=100) "Hot fluid mass flow rate";
  Modelica.SIunits.MassFlowRate Qf(start=100) "Cold fluid mass flow rate";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(points={{-60,-90},{-60,38},{0,-8},{60,40},{60,-90}}, color={0,0,255}, thickness=0.5)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,60},{100,-60}}, fillPattern=FillPattern.Solid, fillColor={255,255,0}),Line(points={{-60,-90},{-60,38},{0,-8},{60,40},{60,-90}}, color={0,0,255}, thickness=0.5),Text(lineColor={0,0,255}, extent={{-110,21},{-90,11}}, fillColor={0,0,255}, textString="Cold inlet"),Text(lineColor={0,0,255}, extent={{-46,-93},{-26,-103}}, fillColor={0,0,255}, textString="Hot inlet"),Text(lineColor={0,0,255}, extent={{28,-93},{48,-103}}, fillColor={0,0,255}, textString="Hot outlet"),Text(lineColor={0,0,255}, extent={{88,20},{110,9}}, fillColor={0,0,255}, textString="Cold outlet")}), Documentation(info="<html>
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
"), DymolaStoredErrors);
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ec annotation(Placement(visible=true, transformation(origin={-60.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-60.4049,-100.342}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ef annotation(Placement(visible=true, transformation(origin={-98.0031,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={-97.8459,1.4976}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Sf annotation(Placement(visible=true, transformation(origin={100.0,2.1541}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={99.8428,1.4976}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Sc annotation(Placement(visible=true, transformation(origin={60.0,-100.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0), iconTransformation(origin={60.4049,-99.3436}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proce annotation(Placement(transformation(x=-90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph procs annotation(Placement(transformation(x=90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profe annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph promf annotation(Placement(transformation(x=-10.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation(Placement(transformation(x=90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation(Placement(transformation(x=50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph promc annotation(Placement(transformation(x=10.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph profs annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=1.0 "Small number for pressure loss equation";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow rate for continuous flow reversal";
equation
  if continuous_flow_reversal then
    0=noEvent(if Qc > Qeps then Ec.h - Ec.h_vol else if Qc < -Qeps then Sc.h - Sc.h_vol else Ec.h - 0.5*((Ec.h_vol - Sc.h_vol)*Modelica.Math.sin(pi*Qc/2/Qeps) + Ec.h_vol + Sc.h_vol));
  else
    0=if Qc > 0 then Ec.h - Ec.h_vol else Sc.h - Sc.h_vol;
  end if;
  if continuous_flow_reversal then
    0=noEvent(if Qf > Qeps then Ef.h - Ef.h_vol else if Qf < -Qeps then Sf.h - Sf.h_vol else Ef.h - 0.5*((Ef.h_vol - Sf.h_vol)*Modelica.Math.sin(pi*Qf/2/Qeps) + Ef.h_vol + Sf.h_vol));
  else
    0=if Qf > 0 then Ef.h - Ef.h_vol else Sf.h - Sf.h_vol;
  end if;
  Ec.Q=Sc.Q;
  Qc=Ec.Q;
  Ef.Q=Sf.Q;
  Qf=Ef.Q;
  Sc.h=lsat.h;
  W=Qf*(Sf.h - Ef.h);
  W=Qc*(Ec.h - Sc.h);
  Ec.P - Sc.P=DPc;
  DPfc=Kc*ThermoSysPro.Functions.ThermoSquare(Qc, eps)/rhoc;
  annotation(_OpenModelica_ApproximatedEquation=true);
  DPgc=rhoc*g*(z2c - z1c);
  DPc=DPfc + DPgc;
  Ef.P - Sf.P=DPf;
  DPff=Kf*ThermoSysPro.Functions.ThermoSquare(Qf, eps)/rhof;
  annotation(_OpenModelica_ApproximatedEquation=true);
  DPgf=rhof*g*(z2f - z1f);
  DPf=DPff + DPgf;
  proce=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ec.P, Ec.h, modec);
  procs=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sc.P, Sc.h, modecs);
  promc=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Ec.P + Sc.P)/2, (Ec.h + Sc.h)/2, modec);
  Tec=proce.T;
  Tsc=procs.T;
  (lsat,vsat)=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(Ec.P);
  if p_rhoc > 0 then
    rhoc=p_rhoc;
  else
    rhoc=promc.d;
  end if;
  profe=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Ef.P, Ef.h, modef);
  profs=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Sf.P, Sf.h, modef);
  promf=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Ef.P + Sf.P)/2, (Ef.h + Sf.h)/2, modef);
  Tef=profe.T;
  Tsf=profs.T;
  if p_rhof > 0 then
    rhof=p_rhof;
  else
    rhof=promf.d;
  end if;
end SimpleStaticCondenser;

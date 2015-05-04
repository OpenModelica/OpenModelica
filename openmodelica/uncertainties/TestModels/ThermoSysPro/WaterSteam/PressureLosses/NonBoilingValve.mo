within ThermoSysPro.WaterSteam.PressureLosses;
model NonBoilingValve "Non boiling valve"
  parameter ThermoSysPro.Units.DifferentialPressure Psecu=10000.0 "Security margin to avoid boiling";
  parameter ThermoSysPro.Units.SpecificEnthalpy Hmax=5000000.0 "Fluid maximum specific enthalpy";
  parameter ThermoSysPro.Units.SpecificEnthalpy Hmin=60000.0 "Fluid minimum specific enthalpy";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow rate";
  ThermoSysPro.Units.AbsolutePressure Pebul(start=100000.0) "Fluid saturation pressure corresponding to Pec";
  ThermoSysPro.Units.AbsolutePressure Pec(start=500000.0) "Pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Psc(start=500000.0) "Pressure at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hec(start=500000.0) "Specific fluid enthalpy at the inlet";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,-60},{0,0},{-100,60},{-100,-42},{-100,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{86,-52},{0,0},{100,60},{100,-60},{86,-52}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-90,-54},{0,0},{-100,60},{-100,-60},{-90,-54}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{100,-60},{0,0},{100,60},{100,-42},{100,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid)}), Documentation(info="<html>
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
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-2.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant ThermoSysPro.Units.AbsolutePressure Pcrit=22064000.0 "Critical pressure";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
equation
  Pec=C1.P;
  Psc=C2.P;
  Hec=C1.h;
  C1.h=C2.h;
  C1.Q=C2.Q;
  Q=C1.Q;
  if continuous_flow_reversal then
    0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
  if Psc < Pcrit then
    Pebul=ThermoSysPro.Properties.WaterSteam.IF97.Pressure_sat_hl(Hec);
    Pec=if Psc - Psecu < Pebul then Pebul + Psecu else Psc;
  else
    Pebul=Psc;
    Pec=Psc + Psecu;
  end if;
end NonBoilingValve;

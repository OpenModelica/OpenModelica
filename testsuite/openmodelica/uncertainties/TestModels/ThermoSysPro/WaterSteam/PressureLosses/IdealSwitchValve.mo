within ThermoSysPro.WaterSteam.PressureLosses;
model IdealSwitchValve "Ideal switch valve"
  parameter Modelica.SIunits.MassFlowRate Qmin=1e-06 "Mass flow when the valve is closed";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  ThermoSysPro.Units.DifferentialPressure deltaP "Pressure difference between the inlet and the outlet";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,-100},{0,-60},{-100,-20},{-100,-100},{-100,-100}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{0,-60},{100,-20},{100,-100},{0,-60},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-40,60},{40,60}}, thickness=1.0),Line(color={0,0,255}, points={{0,60},{0,-60}}),Text(lineColor={0,0,255}, extent={{-104,34},{88,-22}}, textString="DP=0")}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,-100},{0,-60},{-100,-20},{-100,-100},{-100,-100}}, fillColor={127,255,0}, fillPattern=FillPattern.Solid),Polygon(lineColor={0,0,255}, points={{0,-60},{100,-20},{100,-100},{0,-60},{0,-60}}, fillColor={0,255,0}, fillPattern=FillPattern.Solid),Line(color={0,0,255}, points={{-40,60},{40,60}}, thickness=1.0),Line(color={0,0,255}, points={{0,60},{0,-60}}),Text(lineColor={0,0,255}, extent={{-104,34},{88,-22}}, textString="DP=0")}), Documentation(info="<html>
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
</ul>
</html>
"));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical Ouv annotation(Placement(transformation(x=0.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow for continuous flow reversal";
equation
  C1.Q=C2.Q;
  C1.h=C2.h;
  Q=C1.Q;
  deltaP=C1.P - C2.P;
  if continuous_flow_reversal then
    0=noEvent(if Q > Qeps then C1.h - C1.h_vol else if Q < -Qeps then C2.h - C2.h_vol else C1.h - 0.5*((C1.h_vol - C2.h_vol)*Modelica.Math.sin(pi*Q/2/Qeps) + C1.h_vol + C2.h_vol));
  else
    0=if Q > 0 then C1.h - C1.h_vol else C2.h - C2.h_vol;
  end if;
  if Ouv.signal then
    deltaP=0;
  else
    Q - Qmin=0;
  end if;
end IdealSwitchValve;

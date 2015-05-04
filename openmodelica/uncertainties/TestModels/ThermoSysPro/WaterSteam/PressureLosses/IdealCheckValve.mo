within ThermoSysPro.WaterSteam.PressureLosses;
model IdealCheckValve "Ideal check valve"
  parameter ThermoSysPro.Units.DifferentialPressure dPOuvert=0.01 "Pressure difference when the valve opens";
  parameter Modelica.SIunits.MassFlowRate Qmin=1e-06 "Mass flow trhough the valve when the valve is closed";
  parameter Boolean continuous_flow_reversal=false "true: continuous flow reversal - false: discontinuous flow reversal";
  Boolean ouvert(start=true, fixed=true) "Valve state";
  discrete Boolean touvert(start=false, fixed=true);
  discrete Boolean tferme(start=false, fixed=true);
  Modelica.SIunits.MassFlowRate Q "Mass flow rate";
  ThermoSysPro.Units.DifferentialPressure deltaP "Pressure difference between the inlet and the outlet";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-70,70},{-50,50}}, fillPattern=FillPattern.Solid, fillColor={0,0,255}),Line(color={0,0,255}, points={{-90,0},{-60,0}}),Line(color={0,0,255}, points={{60,0},{100,0}}),Text(lineColor={0,0,255}, extent={{-96,-56},{96,-112}}, textString="DP=0"),Line(points={{-60,-60},{-60,60},{60,-60},{60,60}}, color={0,191,0}, thickness=0.5)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(lineColor={0,0,255}, extent={{-70,70},{-50,50}}, fillPattern=FillPattern.Solid, fillColor={0,0,255}),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{60,0},{100,0}}),Text(lineColor={0,0,255}, extent={{-96,-56},{96,-112}}, textString="DP=0"),Line(points={{-60,-60},{-60,60},{60,-60},{60,60}}, color={0,191,0}, thickness=0.5)}), Documentation(info="<html>
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
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
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
  if ouvert then
    deltaP=0;
  else
    Q - Qmin=0;
  end if;
  touvert=deltaP > dPOuvert;
  tferme=not Q > 0;
  when {pre(tferme),pre(touvert)} then
    ouvert=pre(touvert);
  end when;
end IdealCheckValve;

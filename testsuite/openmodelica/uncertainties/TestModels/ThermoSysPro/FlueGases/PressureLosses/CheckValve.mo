within ThermoSysPro.FlueGases.PressureLosses;
model CheckValve "Check valve"
  parameter ThermoSysPro.Units.DifferentialPressure dPOuvert=10 "Pressure difference when the valve opens";
  parameter ThermoSysPro.Units.DifferentialPressure dPFerme=0 "Pressure difference when the valve closes";
  parameter ThermoSysPro.Units.PressureLossCoefficient k=1000 "Pressure loss coefficient";
  parameter Modelica.SIunits.MassFlowRate Qmin=1e-06 "Mass flow when the valve is closed";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  Boolean ouvert(start=true, fixed=true) "Valve state";
  discrete Boolean touvert(start=false, fixed=true);
  discrete Boolean tferme(start=false, fixed=true);
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow";
  ThermoSysPro.Units.DifferentialPressure deltaP(start=10) "Singular pressure loss";
  Modelica.SIunits.Density rho(start=1) "Fluid density";
  ThermoSysPro.Units.AbsoluteTemperature T(start=300) "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Fluid average pressure";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-70,70},{-50,50}}, lineColor={0,0,0}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{60,0},{100,0}}),Line(points={{-60,-60},{-60,60},{60,-60},{60,60}}, color={0,191,0}, thickness=0.5)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-100,0},{-60,0}}),Line(color={0,0,255}, points={{60,0},{100,0}}),Ellipse(extent={{-70,70},{-50,50}}, lineColor={0,0,0}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Line(points={{-60,-60},{-60,60},{60,-60},{60,60}}, color={0,191,0}, thickness=0.5)}), Documentation(info="<html>
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
  Connectors.FlueGasesInlet C1 annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesOutlet C2 annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=0.001 "Small number for pressure loss equation";
equation
  C1.Q=C2.Q;
  C1.T=C2.T;
  Q=C1.Q;
  deltaP=C1.P - C2.P;
  C2.Xco2=C1.Xco2;
  C2.Xh2o=C1.Xh2o;
  C2.Xo2=C1.Xo2;
  C2.Xso2=C1.Xso2;
  if ouvert then
    deltaP - k*ThermoSysPro.Functions.ThermoSquare(Q, eps)/2/rho=0;
  else
    Q - Qmin=0;
  end if;
  touvert=deltaP > dPOuvert;
  tferme=deltaP < dPFerme;
  when {pre(tferme),pre(touvert)} then
    ouvert=pre(touvert);
  end when;
  P=(C1.P + C2.P)/2;
  T=C1.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=ThermoSysPro.Properties.FlueGases.FlueGases_rho(P, T, C2.Xco2, C2.Xh2o, C2.Xo2, C2.Xso2);
  end if;
end CheckValve;

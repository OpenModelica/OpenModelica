within ThermoSysPro.FlueGases.PressureLosses;
model SingularPressureLoss "Singular pressure loss for flue gases"
  parameter Real K=10 "Friction pressure loss coefficient";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  ThermoSysPro.Units.DifferentialPressure deltaPf(start=100.0) "Friction pressure loss";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow";
  Modelica.SIunits.Density rho(start=1) "Fluid density";
  ThermoSysPro.Units.AbsoluteTemperature T(start=290) "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Average fluid pressure";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,40}}, lineColor={0,0,255}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}}, lineColor={0,0,255}, fillColor={127,255,0}, fillPattern=FillPattern.Backward)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,40},{-40,20},{-20,10},{0,8},{20,10},{40,20},{60,40},{-60,40}}, lineColor={0,0,255}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}}, lineColor={0,0,255}, fillColor={127,255,0}, fillPattern=FillPattern.Backward)}), Documentation(info="<html>
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
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=0.001 "Small number for pressure loss equation";
equation
  C1.P - C2.P=deltaPf;
  C1.T=C2.T;
  C1.Q=C2.Q;
  C2.Xco2=C1.Xco2;
  C2.Xh2o=C1.Xh2o;
  C2.Xo2=C1.Xo2;
  C2.Xso2=C1.Xso2;
  Q=C1.Q;
  deltaPf=K*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;
  P=(C1.P + C2.P)/2;
  T=C2.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=ThermoSysPro.Properties.FlueGases.FlueGases_rho(P, T, C2.Xco2, C2.Xh2o, C2.Xo2, C2.Xso2);
  end if;
end SingularPressureLoss;

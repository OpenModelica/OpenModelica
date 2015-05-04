within ThermoSysPro.FlueGases.PressureLosses;
model ControlValve "Control valve"
  parameter ThermoSysPro.Units.Cv Cvmax=5000 "Maximum CV (active if mode_caract=0)";
  parameter Real caract[:,2]=[0,0;1,Cvmax] "Position vs. Cv characteristics (active if mode_caract=1)";
  parameter Integer mode_caract=0 "0:linear characteristics - 1:characteristics is given by caract[]";
  parameter Modelica.SIunits.Density p_rho=0 "If > 0, fixed fluid density";
  ThermoSysPro.Units.Cv Cv(start=100) "Cv";
  Modelica.SIunits.MassFlowRate Q(start=100) "Mass flow";
  ThermoSysPro.Units.DifferentialPressure deltaP(start=10) "Singular pressure loss";
  Modelica.SIunits.Density rho(start=1) "Fluid density";
  ThermoSysPro.Units.AbsoluteTemperature T(start=300) "Fluid temperature";
  ThermoSysPro.Units.AbsolutePressure P(start=100000.0) "Fluid average pressure";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{40,40},{-40,40},{-40,56},{-38,74},{-32,84},{-20,94},{0,100},{20,94},{32,84},{38,72},{40,54},{40,40}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(lineColor={0,0,255}, points={{0,-60},{40,40},{-40,40},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(lineColor={0,0,255}, points={{-100,-100},{0,-60},{-100,-20},{-100,-102},{-100,-100}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(lineColor={0,0,255}, points={{0,-60},{100,-20},{100,-102},{0,-60},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward)}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(lineColor={0,0,255}, points={{-100,-100},{0,-60},{-100,-20},{-100,-102},{-100,-100}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(lineColor={0,0,255}, points={{0,-60},{100,-20},{100,-102},{0,-60},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(lineColor={0,0,255}, points={{0,-60},{40,40},{-40,40},{0,-60}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward),Polygon(lineColor={0,0,255}, points={{40,40},{-40,40},{-40,56},{-38,74},{-32,84},{-20,94},{0,100},{20,94},{32,84},{38,72},{40,54},{40,40}}, fillColor={127,255,0}, fillPattern=FillPattern.Backward)}), Documentation(info="<html>
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
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal Ouv annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  Connectors.FlueGasesInlet C1 annotation(Placement(transformation(x=-100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FlueGasesOutlet C2 annotation(Placement(transformation(x=100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=0.001 "Small number for pressure loss equation";
equation
  C1.T=C2.T;
  C1.Q=C2.Q;
  Q=C1.Q;
  deltaP=C1.P - C2.P;
  C2.Xco2=C1.Xco2;
  C2.Xh2o=C1.Xh2o;
  C2.Xo2=C1.Xo2;
  C2.Xso2=C1.Xso2;
  deltaP*Cv*abs(Cv)=1733000000000.0*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho^2;
  if mode_caract == 0 then
    Cv=Ouv.signal*Cvmax;
  elseif mode_caract == 1 then
    Cv=ThermoSysPro.Functions.Interpolation(Ouv.signal, caract[:,1], caract[:,2]);
  else
    assert(false, "VanneReglante : mode de calcul du Cv incorrect");
  end if;
  P=(C1.P + C2.P)/2;
  T=C1.T;
  if p_rho > 0 then
    rho=p_rho;
  else
    rho=ThermoSysPro.Properties.FlueGases.FlueGases_rho(P, T, C2.Xco2, C2.Xh2o, C2.Xo2, C2.Xso2);
  end if;
end ControlValve;

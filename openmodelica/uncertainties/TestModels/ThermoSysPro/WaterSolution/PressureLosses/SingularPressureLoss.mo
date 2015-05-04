within ThermoSysPro.WaterSolution.PressureLosses;
model SingularPressureLoss "Singular pressure loss"
  parameter Real K=10 "Friction pressure loss coefficient";
  parameter Modelica.SIunits.Density rho=1000 "Fluid density";
  ThermoSysPro.Units.DifferentialPressure deltaPf(start=100.0) "Friction pressure loss";
  Modelica.SIunits.MassFlowRate Q(start=500) "Mass flow";
  ThermoSysPro.Units.AbsoluteTemperature T(start=290) "Fluid temperature";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,40},{-40,18},{-20,10},{0,8},{20,10},{40,18},{60,40},{-60,40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159}),Polygon(points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Polygon(points={{-60,40},{-40,18},{-20,10},{0,8},{20,10},{40,18},{60,40},{-60,40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159}),Polygon(points={{-60,-40},{-40,-20},{-20,-12},{0,-10},{20,-12},{40,-20},{60,-40},{-60,-40}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159})}), Documentation(info="<html>
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
<li>
    Daniel Bouskela</li>
</html>
"));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionInlet C1 annotation(Placement(transformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSolution.Connectors.WaterSolutionOutlet C2 annotation(Placement(transformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  parameter Real eps=0.001 "Small number for pressure loss equation";
equation
  C1.P - C2.P=deltaPf;
  C1.T=C2.T;
  C1.Q=C2.Q;
  C2.Xh2o=C1.Xh2o;
  Q=C1.Q;
  T=C1.T;
  deltaPf=K*ThermoSysPro.Functions.ThermoSquare(Q, eps)/rho;
end SingularPressureLoss;

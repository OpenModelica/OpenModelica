within ThermoSysPro.ElectroMechanics.Machines;
model Shaft "Mechanical coupling"
  parameter Real Ke=0.2 "Elasticity coefficient (s.u.)";
  parameter Real D=0.3 "Damping coefficient (n.u.)";
  parameter Boolean steady_state_mech=true "true: start from steady state - false: start from delta=0";
  Modelica.SIunits.Angle delta(start=0) "Torsion angle";
  Modelica.SIunits.AngularVelocity w_rel "Relative angular speed between the two extremities of the shaft";
  Modelica.SIunits.Torque Ctr "Transmitted torque";
  annotation(Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,20},{80,-20}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={160,160,160}),Polygon(points={{-100,10},{-100,-8},{-80,-14},{-80,14},{-100,10}}, fillPattern=FillPattern.Solid, lineColor={160,160,160}, fillColor={160,160,160}),Polygon(points={{80,14},{100,10},{100,-12},{80,-14},{80,14}}, fillPattern=FillPattern.Solid, lineColor={160,160,160}, fillColor={160,160,160})}), Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,20},{80,-20}}, lineColor={0,0,0}, fillPattern=FillPattern.HorizontalCylinder, fillColor={160,160,160}),Polygon(points={{-100,10},{-100,-8},{-80,-14},{-80,14},{-100,10}}, fillPattern=FillPattern.Solid, lineColor={160,160,160}, fillColor={160,160,160}),Polygon(points={{80,14},{100,10},{100,-12},{80,-14},{80,14}}, fillPattern=FillPattern.Solid, lineColor={160,160,160}, fillColor={160,160,160})}), Documentation(info="<html>
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
  ThermoSysPro.ElectroMechanics.Connectors.MechanichalTorque C2 annotation(Placement(transformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.ElectroMechanics.Connectors.MechanichalTorque C1 annotation(Placement(transformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-110.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
initial equation
  if steady_state_mech then
    der(delta)=0;
  else
    delta=0;
  end if;
equation
  w_rel=C1.w - C2.w;
  der(delta)=w_rel;
  Ctr=Ke*delta + D*w_rel;
  C1.Ctr=Ctr;
  C2.Ctr=Ctr;
end Shaft;

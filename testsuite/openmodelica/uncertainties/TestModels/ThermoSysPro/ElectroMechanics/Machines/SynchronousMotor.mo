within ThermoSysPro.ElectroMechanics.Machines;
model SynchronousMotor "Synchronous electrical motor"
  parameter ThermoSysPro.Units.RotationVelocity Vrot=1400.0 "Nominal rotational speed";
  parameter ThermoSysPro.Units.RotationVelocity Vrot0=0 "Initial rotational speed (active if steady_state_mech=true)";
  parameter Modelica.SIunits.Voltage Ualim=380.0 "Voltage";
  parameter Real D=10.0 "Damping coefficient (mechanical losses) (n.u.)";
  parameter Modelica.SIunits.Inductance Lm=1.0 "Motor nductance";
  parameter Modelica.SIunits.Resistance Rm=1e-05 "Motor resistance";
  parameter Real Ki=1.0 "Proportionnality coef. between Cm and Im (N.m/A)";
  parameter Modelica.SIunits.MomentOfInertia J=4.0 "Motor moment of inertia";
  parameter Boolean steady_state_mech=true "true: start from steady state - false : start from Vrot0";
  parameter Boolean mech_coupling=true "Use mechanical coupling component";
  Modelica.SIunits.AngularVelocity w "Angular speed";
  Modelica.SIunits.Torque Cm "Motor torque";
  Modelica.SIunits.Torque Ctr "Mechanical torque";
  Modelica.SIunits.Current Im "Current";
  Modelica.SIunits.Voltage Um "Voltage";
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-60,32},{62,-34}}, fillPattern=FillPattern.Solid, fillColor={0,127,255}),Rectangle(lineColor={0,0,255}, extent={{-60,-4},{62,0}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{-60,16},{62,20}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{-60,-22},{62,-18}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{62,12},{92,-12}}, fillPattern=FillPattern.Solid, fillColor={0,127,255}),Rectangle(lineColor={0,0,255}, extent={{-90,12},{-60,-12}}, fillPattern=FillPattern.Solid, fillColor={0,127,255}),Line(color={0,0,255}, points={{92,-22},{90,-26},{88,-28},{84,-30},{80,-30},{76,-28},{72,-22},{70,-14},{70,-6},{70,16},{72,22},{74,26},{76,28},{80,30},{82,30},{86,28},{88,26},{90,22},{90,28},{86,24},{90,22}}),Rectangle(lineColor={0,0,255}, extent={{-60,30},{62,34}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{-60,-36},{62,-32}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-60,32},{62,-34}}, fillPattern=FillPattern.Solid, fillColor={0,127,255}),Rectangle(lineColor={0,0,255}, extent={{-60,-4},{62,0}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{-60,16},{62,20}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{-60,-22},{62,-18}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{62,12},{92,-12}}, fillPattern=FillPattern.Solid, fillColor={0,127,255}),Rectangle(lineColor={0,0,255}, extent={{-90,12},{-60,-12}}, fillPattern=FillPattern.Solid, fillColor={0,127,255}),Line(color={0,0,255}, points={{92,-22},{90,-26},{88,-28},{84,-30},{80,-30},{76,-28},{72,-22},{70,-14},{70,-6},{70,16},{72,22},{74,26},{76,28},{80,30},{82,30},{86,28},{88,26},{90,22},{90,28},{86,24},{90,22}}),Rectangle(lineColor={0,0,255}, extent={{-60,30},{62,34}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0}),Rectangle(lineColor={0,0,255}, extent={{-60,-36},{62,-32}}, fillPattern=FillPattern.Sphere, fillColor={255,0,0})}), Documentation(info="<html>
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
  ThermoSysPro.InstrumentationAndControl.Connectors.InputLogical marche annotation(Placement(transformation(x=0.0, y=44.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=44.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  ThermoSysPro.ElectroMechanics.Connectors.MechanichalTorque C annotation(Placement(transformation(x=102.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=102.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real Km=30*Ualim/(pi*Vrot) "Voltage in rotor under stationary state";
initial equation
  if steady_state_mech then
    if mech_coupling then
      der(w)=0;
    end if;
    der(Im)=0;
  else
    if mech_coupling then
      w=pi/30*Vrot0;
    end if;
    Im=0;
  end if;
equation
  C.w=w;
  C.Ctr=Ctr;
  J*der(w)=Cm - D*w - Ctr;
  Lm*der(Im)=Um - Km*w - Rm*Im;
  Um=if marche.signal then Ualim else 0;
  Cm=Ki*Im;
end SynchronousMotor;

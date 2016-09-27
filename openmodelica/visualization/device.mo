within ;
model device

  Modelica_DeviceDrivers.Blocks.InputDevices.KeyboardKeyInput key(keyCode="W")
  annotation (Placement(transformation(extent={{-78,36},{-58,56}})));
  Modelica.Blocks.Logical.Switch switch1
    annotation (Placement(transformation(extent={{-30,28},{-10,48}})));
  Modelica.Blocks.Sources.RealExpression realExpression(y=-0.1)
    annotation (Placement(transformation(extent={{-70,56},{-50,76}})));
  Modelica.Blocks.Sources.RealExpression realExpression1(y=0)
    annotation (Placement(transformation(extent={{-68,0},{-48,20}})));
  Modelica.Blocks.Continuous.Integrator integrator
    annotation (Placement(transformation(extent={{-26,-16},{-6,4}})));
  Modelica.Blocks.Sources.BooleanExpression booleanExpression
    annotation (Placement(transformation(extent={{-72,16},{-52,36}})));
  Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape shape(
    r={integrator.y,0,0},
    length=0.5,
    width=0.5,
    height=0.5) annotation (Placement(transformation(extent={{50,-2},{70,18}})));
equation
  connect(realExpression.y,switch1. u1) annotation (Line(
      points={{-49,66},{-40,66},{-40,46},{-32,46}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(realExpression1.y,switch1. u3) annotation (Line(
      points={{-47,10},{-38,10},{-38,30},{-32,30}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(switch1.y,integrator. u) annotation (Line(
      points={{-9,38},{-4,38},{-4,16},{-34,16},{-34,-6},{-28,-6}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(key.keyState, switch1.u2) annotation (Line(
      points={{-57,46},{-44,46},{-44,38},{-32,38}},
      color={255,0,255},
      smooth=Smooth.None));
  annotation (uses(Modelica_DeviceDrivers(version="1.4.4"), Modelica(version="3.2.1")));
end device;

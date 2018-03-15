within ;
model ElectricalCircuit5
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-58,-70},{-38,-50}})));
  Modelica.Electrical.Analog.Basic.Resistor R(R=1)
    annotation (Placement(transformation(extent={{-78,-50},{-58,-30}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent constantCurrent(I=1)
    annotation (Placement(transformation(extent={{-38,-50},{-18,-30}})));
  Modelica.Electrical.Analog.Basic.Resistor R1(R=1)
    annotation (Placement(transformation(extent={{-78,10},{-58,30}})));
  Modelica.Electrical.Analog.Basic.Resistor R2(R=1)
    annotation (Placement(transformation(extent={{-38,10},{-18,30}})));
  Modelica.Electrical.Analog.Basic.Capacitor C1(C=1)
    annotation (Placement(transformation(extent={{-58,-10},{-38,10}})));
equation
  connect(R.n, constantCurrent.p)        annotation (Line(
      points={{-58,-40},{-38,-40}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, constantCurrent.p) annotation (Line(
      points={{-48,-50},{-48,-40},{-38,-40}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R.p, R1.p)               annotation (Line(
      points={{-78,-40},{-90,-40},{-90,20},{-78,20}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C1.n, R2.n)               annotation (Line(
      points={{-38,0},{-18,0},{-18,20}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(C1.p, R1.p)               annotation (Line(
      points={{-58,0},{-78,0},{-78,20}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R2.p, R1.n)               annotation (Line(
      points={{-38,20},{-58,20}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(constantCurrent.n, R2.n) annotation (Line(
      points={{-18,-40},{-18,20}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end ElectricalCircuit5;

within ;
model Tearing10
  "'Continuous System Simulation', Francois Cellier, Homework Problems [H7.5], p.313"

  Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage(V=230, freqHz=50)
    annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={-50,14})));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-22,-62},{-2,-42}})));
  Modelica.Electrical.Analog.Basic.Resistor R1(R=10) annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={-12,42})));
  Modelica.Electrical.Analog.Basic.Resistor R4(R=10) annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={-12,-16})));
  Modelica.Electrical.Analog.Basic.Resistor R2(R=10) annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={56,42})));
  Modelica.Electrical.Analog.Basic.Resistor R5(R=10) annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={56,-16})));
  Modelica.Electrical.Analog.Basic.Resistor R3(R=10)
    annotation (Placement(transformation(extent={{12,4},{32,24}})));
equation
  connect(sineVoltage.p, R1.p) annotation (Line(
      points={{-50,24},{-50,72},{-12,72},{-12,52}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R1.p, R2.p) annotation (Line(
      points={{-12,52},{-12,72},{56,72},{56,52}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R2.n, R5.p) annotation (Line(
      points={{56,32},{56,-6}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R2.n, R3.n) annotation (Line(
      points={{56,32},{56,14},{32,14}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R5.n, ground.p) annotation (Line(
      points={{56,-26},{56,-42},{-12,-42}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, sineVoltage.n) annotation (Line(
      points={{-12,-42},{-50,-42},{-50,4}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, R4.n) annotation (Line(
      points={{-12,-42},{-12,-34},{-12,-26},{-12,-26}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R1.n, R3.p) annotation (Line(
      points={{-12,32},{-12,14},{12,14}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(R3.p, R4.p) annotation (Line(
      points={{12,14},{-12,14},{-12,-6}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (uses(Modelica(version="3.2.2")), Diagram(graphics));
end Tearing10;

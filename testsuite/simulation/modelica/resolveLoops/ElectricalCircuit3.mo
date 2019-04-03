within ;
model ElectricalCircuit3
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-60,-20},{-40,0}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R=1)
    annotation (Placement(transformation(extent={{-80,0},{-60,20}})));
  Modelica.Electrical.Analog.Sources.ConstantCurrent constantCurrent(I=1)
    annotation (Placement(transformation(extent={{-40,0},{-20,20}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor1(R=1)
    annotation (Placement(transformation(extent={{-80,60},{-60,80}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor2(R=1)
    annotation (Placement(transformation(extent={{-40,60},{-20,80}})));
  Modelica.Electrical.Analog.Basic.Capacitor capacitor(C=1)
    annotation (Placement(transformation(extent={{-60,40},{-40,60}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor3(R=1)
    annotation (Placement(transformation(extent={{0,60},{20,80}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor4(R=1)
    annotation (Placement(transformation(extent={{40,60},{60,80}})));
  Modelica.Electrical.Analog.Basic.Capacitor capacitor1(C=1)
    annotation (Placement(transformation(extent={{20,40},{40,60}})));
equation
  connect(resistor.n, constantCurrent.p) annotation (Line(
      points={{-60,10},{-40,10}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, constantCurrent.p) annotation (Line(
      points={{-50,0},{-50,10},{-40,10}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor.p, resistor1.p) annotation (Line(
      points={{-80,10},{-92,10},{-92,70},{-80,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(capacitor.n, resistor2.n) annotation (Line(
      points={{-40,50},{-20,50},{-20,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(capacitor.p, resistor1.p) annotation (Line(
      points={{-60,50},{-80,50},{-80,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor3.n, resistor4.p) annotation (Line(
      points={{20,70},{40,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(capacitor1.n, resistor4.n) annotation (Line(
      points={{40,50},{60,50},{60,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(capacitor1.p, resistor3.p) annotation (Line(
      points={{20,50},{0,50},{0,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor2.n, resistor3.p) annotation (Line(
      points={{-20,70},{0,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor4.n, constantCurrent.n) annotation (Line(
      points={{60,70},{74,70},{74,10},{-20,10}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor2.p, resistor1.n) annotation (Line(
      points={{-40,70},{-60,70}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end ElectricalCircuit3;

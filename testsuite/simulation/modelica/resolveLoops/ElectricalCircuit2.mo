within ;
model test2
  Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage
    annotation (Placement(transformation(extent={{-66,0},{-46,20}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor
    annotation (Placement(transformation(extent={{-12,74},{8,94}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor1
    annotation (Placement(transformation(extent={{-14,48},{6,68}})));
  Modelica.Electrical.Analog.Basic.Inductor inductor
    annotation (Placement(transformation(extent={{-60,60},{-40,80}})));
  Modelica.Electrical.Analog.Basic.Inductor inductor1
    annotation (Placement(transformation(extent={{32,60},{52,80}})));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-48,-34},{-28,-14}})));
equation
  connect(resistor.p, resistor1.p) annotation (Line(
      points={{-12,84},{-14,84},{-14,58}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor.n, resistor1.n) annotation (Line(
      points={{8,84},{8,58},{6,58}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor1.p, resistor1.n) annotation (Line(
      points={{32,70},{8,70},{8,58},{6,58}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor.n, resistor1.p) annotation (Line(
      points={{-40,70},{-14,70},{-14,58}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor.p, sineVoltage.p) annotation (Line(
      points={{-60,70},{-76,70},{-76,10},{-66,10}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, sineVoltage.n) annotation (Line(
      points={{-38,-14},{-42,-14},{-42,10},{-46,10}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(sineVoltage.n, inductor1.n) annotation (Line(
      points={{-46,10},{72,10},{72,70},{52,70}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (uses(Modelica(version="3.2")), Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end test2;


model electricalCircuit2
  Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage(V=50, freqHz=100)
    annotation (Placement(transformation(extent={{-70,28},{-50,48}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R=100)
    annotation (Placement(transformation(extent={{-38,72},{-18,92}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor1(R=100)
    annotation (Placement(transformation(extent={{-40,46},{-20,66}})));
  Modelica.Electrical.Analog.Basic.Inductor inductor(L=1)
    annotation (Placement(transformation(extent={{-66,60},{-46,80}})));
  Modelica.Electrical.Analog.Basic.Inductor inductor1(L=1)
    annotation (Placement(transformation(extent={{-12,60},{8,80}})));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-52,4},{-32,24}})));
equation
  connect(resistor.p, resistor1.p) annotation (Line(
      points={{-38,82},{-40,82},{-40,56}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor.n, resistor1.n) annotation (Line(
      points={{-18,82},{-18,56},{-20,56}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor1.p, resistor1.n) annotation (Line(
      points={{-12,70},{-18,70},{-18,56},{-20,56}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor.n, resistor1.p) annotation (Line(
      points={{-46,70},{-40,70},{-40,56}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor.p, sineVoltage.p) annotation (Line(
      points={{-66,70},{-74,70},{-74,38},{-70,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, sineVoltage.n) annotation (Line(
      points={{-42,24},{-42,38},{-50,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(sineVoltage.n, inductor1.n) annotation (Line(
      points={{-50,38},{12,38},{12,70},{8,70}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (uses(Modelica(version="3.2")), Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end electricalCircuit2;

model ElectricalCircuit2
  Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage(V=50, freqHz=5)
    annotation (Placement(transformation(extent={{-70,28},{-50,48}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R=100)
    annotation (Placement(transformation(extent={{-38,72},{-18,92}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor1(R=100)
    annotation (Placement(transformation(extent={{-40,46},{-20,66}})));
  Modelica.Electrical.Analog.Basic.Inductor inductor(L=1)
    annotation (Placement(transformation(extent={{-66,60},{-46,80}})));
  Modelica.Electrical.Analog.Basic.Inductor inductor1(L=1)
    annotation (Placement(transformation(extent={{-12,60},{8,80}})));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-52,4},{-32,24}})));
equation
  connect(resistor.p, resistor1.p) annotation (Line(
      points={{-38,82},{-40,82},{-40,56}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor.n, resistor1.n) annotation (Line(
      points={{-18,82},{-18,56},{-20,56}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor1.p, resistor1.n) annotation (Line(
      points={{-12,70},{-18,70},{-18,56},{-20,56}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor.n, resistor1.p) annotation (Line(
      points={{-46,70},{-40,70},{-40,56}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor.p, sineVoltage.p) annotation (Line(
      points={{-66,70},{-74,70},{-74,38},{-70,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, sineVoltage.n) annotation (Line(
      points={{-42,24},{-42,38},{-50,38}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(sineVoltage.n, inductor1.n) annotation (Line(
      points={{-50,38},{12,38},{12,70},{8,70}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end ElectricalCircuit2;

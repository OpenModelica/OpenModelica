model SimpleResistor " simple testcase with 3 simple equations"
  Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage(V=50, freqHz=10)
    annotation (Placement(transformation(extent={{-58,60},{-38,80}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R=100) annotation (
      Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=-90,
        origin={20,60})));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{32,-4},{52,16}})));
equation
  connect(sineVoltage.n, resistor.p) annotation (Line(
      points={{-38,70},{20,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor.n, sineVoltage.p) annotation (Line(
      points={{20,50},{20,34},{-58,34},{-58,70}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, resistor.n) annotation (Line(
      points={{42,16},{42,50},{20,50}},
      color={0,0,255},
      smooth=Smooth.None));
end SimpleResistor;

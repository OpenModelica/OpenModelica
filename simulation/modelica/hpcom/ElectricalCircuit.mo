model ElectricalCircuit
  Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage(V=220, freqHz=50)
    annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={-46,26})));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R=100)
    annotation (Placement(transformation(extent={{-30,32},{-10,52}})));
  Modelica.Electrical.Analog.Basic.Capacitor capacitor(C=2)
    annotation (Placement(transformation(extent={{30,32},{50,52}})));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-56,-34},{-36,-14}})));
equation
  connect(capacitor.p, resistor.n) annotation (Line(
      points={{30,42},{-10,42}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor.p, sineVoltage.n) annotation (Line(
      points={{-30,42},{-46,42},{-46,36}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(capacitor.n, sineVoltage.p) annotation (Line(
      points={{50,42},{58,42},{58,8},{-46,8},{-46,16}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(ground.p, sineVoltage.p) annotation (Line(
      points={{-46,-14},{-46,16}},
      color={0,0,255},
      smooth=Smooth.None));
end ElectricalCircuit;

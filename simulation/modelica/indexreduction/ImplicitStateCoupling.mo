within ;
model ImplicitStateCoupling
  parameter Real R=1;
  parameter Real L=0.5;
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{4,-24},{24,-4}})));
  Modelica.Electrical.Analog.Sources.SineVoltage   signalVoltage(V=230, freqHz=
        50)                                                      annotation (
      Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={-32,14})));
  Modelica.Electrical.Analog.Basic.Inductor inductor(L=L)
    annotation (Placement(transformation(extent={{-20,26},{0,46}})));
  Modelica.Electrical.Analog.Basic.Inductor inductor1(L=L)
    annotation (Placement(transformation(extent={{34,26},{54,46}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R=R)
    annotation (Placement(transformation(extent={{8,36},{28,56}})));
  Modelica.Electrical.Analog.Basic.Resistor resistor1(R=R)
    annotation (Placement(transformation(extent={{8,16},{28,36}})));
equation
  connect(ground.p, signalVoltage.n) annotation (Line(
      points={{14,-4},{-32,-4},{-32,4}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(signalVoltage.p, inductor.p) annotation (Line(
      points={{-32,24},{-32,36},{-20,36}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor.n, resistor.p) annotation (Line(
      points={{0,36},{0,46},{8,46}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor.n, resistor1.p) annotation (Line(
      points={{0,36},{0,26},{8,26}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor.n, inductor1.p) annotation (Line(
      points={{28,46},{34,46},{34,36}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor1.n, inductor1.p) annotation (Line(
      points={{28,26},{34,26},{34,36}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(inductor1.n, ground.p) annotation (Line(
      points={{54,36},{62,36},{62,-4},{14,-4}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (uses(Modelica(version="3.2.1")), Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
                                                     graphics));
end ImplicitStateCoupling;

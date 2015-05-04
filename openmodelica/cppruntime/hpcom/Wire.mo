package Wire

model WireN

  constant Integer N = 200 "Number of individual elements";
  parameter Modelica.SIunits.Resistance R = 1000;
  parameter Modelica.SIunits.Capacitance C = 0.001;

  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{-72,-34},{-52,-14}})));
  Modelica.Electrical.Analog.Sources.SineVoltage sineVoltage annotation (
      Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={-62,12})));
  Modelica.Electrical.Analog.Basic.Resistor resistor[N](each R=R/N)
    annotation (Placement(transformation(extent={{-48,22},{-28,42}})));
  Modelica.Electrical.Analog.Basic.Capacitor capacitor[N-1](each C=C/N)  annotation (
      Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={-16,10})));

  Modelica.Electrical.Analog.Basic.Capacitor capacitorl(C=C)
                                                       annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={14,10})));
  Modelica.Electrical.Analog.Basic.Resistor resistorl(R=R)
                                                      annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={42,10})));
equation
  connect(sineVoltage.p, ground.p) annotation (Line(
      points={{-62,2},{-62,-14}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(sineVoltage.n, resistor[1].p) annotation (Line(
      points={{-62,22},{-62,32},{-48,32}},
      color={0,0,255},
      smooth=Smooth.None));
  for i in 1:N-1 loop
  connect(capacitor[i].n, ground.p) annotation (Line(
      points={{-16,0},{-16,-14},{-62,-14}},
      color={0,0,255},
      smooth=Smooth.None));
  end for;
  connect(capacitorl.n, ground.p) annotation (Line(
      points={{14,0},{14,-14},{-62,-14}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistorl.n, ground.p) annotation (Line(
      points={{42,0},{42,-14},{-62,-14}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistorl.p, resistor[N].n) annotation (Line(
      points={{42,20},{42,32},{-28,32}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(capacitorl.p, resistor[N].n) annotation (Line(
      points={{14,20},{14,32},{-28,32}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor[1:N-1].n, capacitor[1:N-1].p) annotation (Line(
      points={{-28,32},{-16,32},{-16,20}},
      color={0,0,255},
      smooth=Smooth.None));
  connect(resistor[1:N-1].n, resistor[2:N].p) annotation (Line(
      points={{-28,32},{-28,50},{-50,50},{-50,32},{-48,32}},
      color={0,0,255},
      smooth=Smooth.None));
  annotation (uses(Modelica(version="3.2")), Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end WireN;

  model Wire_2
    extends WireN(N = 2);
  end Wire_2;

  model Wire_3
    extends WireN(N = 3);
  end Wire_3;

  model Wire_10
    extends WireN(N = 10);
  end Wire_10;

  model Wire_100
    extends WireN(N = 100);
  end Wire_100;

  model Wire_500
    extends WireN(N = 500);
  end Wire_500;

  model Wire_1000
    extends WireN(N = 1000);
  end Wire_1000;

  model Wire_2000
    extends WireN(N = 2000);
  end Wire_2000;

  model Wire_3000
    extends WireN(N = 3000);
  end Wire_3000;

  model Wire_4000
    extends WireN(N = 4000);
  end Wire_4000;

  model Wire_5000
    extends WireN(N = 5000);
  end Wire_5000;

  model Wire_6000
    extends WireN(N = 6000);
  end Wire_6000;

  model Wire_7000
    extends WireN(N = 7000);
  end Wire_7000;

  model Wire_8000
    extends WireN(N = 8000);
  end Wire_8000;

  model Wire_9000
    extends WireN(N = 9000);
  end Wire_9000;

  model Wire_10000
    extends WireN(N = 10000);
  end Wire_10000;

  model Wire_11000
    extends WireN(N = 11000);
  end Wire_11000;

  model Wire_12000
    extends WireN(N = 12000);
  end Wire_12000;

  annotation (uses(Modelica(version="3.2")));
end Wire;

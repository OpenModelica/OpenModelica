encapsulated package RedBoxIssue
  import Modelica;
  import PowerSystems;
  import PowerSystems_Control_Modulation_SVPWM;
  import ElettricoCeraolo;
  // euro symbol €

  package Support
    model PulseDelay
      annotation(
        Icon(coordinateSystem(preserveAspectRatio = false)),
        Diagram(coordinateSystem(preserveAspectRatio = false)));
    end PulseDelay;

    model QMonoSensor "Sensor to measure the reactive power"
      Modelica.Electrical.Analog.Interfaces.PositivePin pc "Positive pin, current path" annotation(
        Placement(transformation(extent = {{-90, -10}, {-110, 10}}, rotation = 0)));
      Modelica.Electrical.Analog.Interfaces.NegativePin nc "Negative pin, current path" annotation(
        Placement(transformation(extent = {{110, -10}, {90, 10}}, rotation = 0)));
      Modelica.Electrical.Analog.Interfaces.PositivePin pv "Positive pin, voltage path" annotation(
        Placement(transformation(extent = {{-10, 110}, {10, 90}}, rotation = 0)));
      Modelica.Electrical.Analog.Interfaces.NegativePin nv "Negative pin, voltage path" annotation(
        Placement(transformation(extent = {{10, -110}, {-10, -90}}, rotation = 0)));
      Modelica.Blocks.Interfaces.RealOutput power annotation(
        Placement(transformation(origin = {-80, -110}, extent = {{-10, 10}, {10, -10}}, rotation = 270)));
      Modelica.Electrical.Analog.Sensors.VoltageSensor voltageSensor annotation(
        Placement(transformation(origin = {0, -30}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
      Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor annotation(
        Placement(transformation(extent = {{-50, -10}, {-30, 10}}, rotation = 0)));
      Modelica.Blocks.Math.Product product annotation(
        Placement(transformation(origin = {-30, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
      Modelica.Blocks.Nonlinear.VariableDelay variableDelay(delayMax = 1.0) annotation(
        Placement(transformation(extent = {{32, -40}, {52, -20}})));
      Modelica.Blocks.Sources.Constant const(k = 1 / (50 * 4)) annotation(
        Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {18, -66})));
    equation
      connect(pv, voltageSensor.p) annotation(
        Line(points = {{0, 100}, {0, -20}, {6.12323e-016, -20}}, color = {0, 0, 255}));
      connect(voltageSensor.n, nv) annotation(
        Line(points = {{-6.12323e-016, -40}, {-6.12323e-016, -63}, {0, -63}, {0, -100}}, color = {0, 0, 255}));
      connect(pc, currentSensor.p) annotation(
        Line(points = {{-100, 0}, {-50, 0}}, color = {0, 0, 255}));
      connect(currentSensor.n, nc) annotation(
        Line(points = {{-30, 0}, {100, 0}}, color = {0, 0, 255}));
      connect(currentSensor.i, product.u2) annotation(
        Line(points = {{-40, -11}, {-40, -30}, {-36, -30}, {-36, -38}}, color = {0, 0, 127}));
      connect(product.y, power) annotation(
        Line(points = {{-30, -61}, {-30, -80}, {-80, -80}, {-80, -110}}, color = {0, 0, 127}));
      connect(variableDelay.u, voltageSensor.v) annotation(
        Line(points = {{30, -30}, {11, -30}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(const.y, variableDelay.delayTime) annotation(
        Line(points = {{18, -55}, {18, -36}, {30, -36}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(variableDelay.y, product.u1) annotation(
        Line(points = {{53, -30}, {68, -30}, {68, 20}, {-24, 20}, {-24, -38}}, color = {0, 0, 127}, smooth = Smooth.None));
      annotation(
        Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics = {Ellipse(extent = {{-70, 70}, {70, -70}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, 100}, {0, 70}}, color = {0, 0, 255}), Line(points = {{0, -70}, {0, -100}}, color = {0, 0, 255}), Line(points = {{-80, -100}, {-80, 0}}, color = {0, 0, 255}), Line(points = {{-100, 0}, {100, 0}}, color = {0, 0, 255}), Text(extent = {{150, 120}, {-150, 160}}, textString = "%name", lineColor = {0, 0, 255}), Line(points = {{0, 70}, {0, 40}}, color = {0, 0, 0}), Line(points = {{22.9, 32.8}, {40.2, 57.3}}, color = {0, 0, 0}), Line(points = {{-22.9, 32.8}, {-40.2, 57.3}}, color = {0, 0, 0}), Line(points = {{37.6, 13.7}, {65.8, 23.9}}, color = {0, 0, 0}), Line(points = {{-37.6, 13.7}, {-65.8, 23.9}}, color = {0, 0, 0}), Line(points = {{0, 0}, {9.02, 28.6}}, color = {0, 0, 0}), Polygon(points = {{-0.48, 31.6}, {18, 26}, {18, 57.2}, {-0.48, 31.6}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-5, 5}, {5, -5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-29, -11}, {30, -70}}, lineColor = {0, 0, 0}, textString = "Q")}),
        Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, grid = {2, 2}), graphics),
        Documentation(info = "<html>
<p>This power sensor measures instantaneous electrical power of a singlephase system and has a separated voltage and current path. The pins of the voltage path are pv and nv, the pins of the current path are pc and nc. The internal resistance of the current path is zero, the internal resistance of the voltage path is infinite.</p>
</html>", revisions = "<html>
<ul>
<li><i>January 12, 2006</i> by Anton Haumer implemented</li>
</ul>
</html>"));
    end QMonoSensor;

    block PwmPulser
      Modelica.Blocks.Interfaces.RealInput ampl annotation(
        Placement(transformation(extent = {{-140, 40}, {-100, 80}}), iconTransformation(extent = {{-140, 44}, {-100, 84}})));
      Modelica.Blocks.Interfaces.RealInput ph_deg annotation(
        Placement(transformation(extent = {{-138, -76}, {-98, -36}}), iconTransformation(extent = {{-140, -74}, {-100, -34}})));
      parameter Modelica.SIunits.Frequency fCar = 1050 "Carrier Frequency";
      parameter Modelica.SIunits.Time carStartTime = 0 "Carrier start time";
      import PI = Modelica.Constants.pi;
    protected
      Modelica.Blocks.Sources.Trapezoid carrier(rising = 1 / (2 * fCar), width = 0, falling = 1 / (2 * fCar), period = 1 / fCar, amplitude = 2, offset = -1, startTime = carStartTime) annotation(
        Placement(transformation(extent = {{14, -56}, {34, -36}})));
      Modelica.Blocks.Math.Sin sin annotation(
        Placement(transformation(extent = {{-20, -28}, {0, -8}})));
      Modelica.Blocks.Continuous.Integrator integrator annotation(
        Placement(transformation(extent = {{-50, 16}, {-32, 34}})));
      Modelica.Blocks.Sources.RealExpression realExpression(y = 2 * PI * fSig) annotation(
        Placement(transformation(extent = {{-90, 14}, {-64, 36}})));
    public
      Modelica.Blocks.Math.Add add annotation(
        Placement(transformation(extent = {{-54, -28}, {-34, -8}})));
      Modelica.Blocks.Math.Gain ToRAD(k = PI / 180) annotation(
        Placement(transformation(extent = {{-66, -62}, {-54, -50}})));
      Modelica.Blocks.Math.Product signal annotation(
        Placement(transformation(extent = {{14, -22}, {32, -4}})));
      Modelica.Blocks.Interfaces.BooleanOutput up annotation(
        Placement(transformation(extent = {{100, 10}, {120, 30}}), iconTransformation(extent = {{100, 56}, {120, 76}})));
      Modelica.Blocks.Logical.Greater greater annotation(
        Placement(transformation(extent = {{46, -24}, {66, -4}})));
      Modelica.Blocks.Interfaces.BooleanOutput down annotation(
        Placement(transformation(extent = {{100, -62}, {120, -42}}), iconTransformation(extent = {{100, -68}, {120, -48}})));
      Modelica.Blocks.Logical.Not not1 annotation(
        Placement(transformation(extent = {{60, -60}, {80, -40}})));
      parameter Modelica.SIunits.Frequency fSig = 50 "Signal Frequency";
    equation
      connect(ToRAD.u, ph_deg) annotation(
        Line(points = {{-67.2, -56}, {-118, -56}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(sin.u, add.y) annotation(
        Line(points = {{-22, -18}, {-33, -18}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(signal.u2, sin.y) annotation(
        Line(points = {{12.2, -18.4}, {14, -18.4}, {14, -18}, {1, -18}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(add.u1, integrator.y) annotation(
        Line(points = {{-56, -12}, {-64, -12}, {-64, 2}, {-24, 2}, {-24, 25}, {-31.1, 25}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(signal.u1, ampl) annotation(
        Line(points = {{12.2, -7.6}, {12.2, 60}, {-120, 60}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(add.u2, ToRAD.y) annotation(
        Line(points = {{-56, -24}, {-64, -24}, {-64, -34}, {-46, -34}, {-46, -56}, {-53.4, -56}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(greater.u1, signal.y) annotation(
        Line(points = {{44, -14}, {46.45, -14}, {46.45, -13}, {32.9, -13}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(greater.u2, carrier.y) annotation(
        Line(points = {{44, -22}, {44, -46}, {35, -46}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(up, greater.y) annotation(
        Line(points = {{110, 20}, {74, 20}, {74, -14}, {67, -14}}, color = {255, 0, 255}, smooth = Smooth.None));
      connect(not1.y, down) annotation(
        Line(points = {{81, -50}, {84, -50}, {84, -52}, {110, -52}}, color = {255, 0, 255}, smooth = Smooth.None));
      connect(not1.u, greater.y) annotation(
        Line(points = {{58, -50}, {52, -50}, {52, -32}, {74, -32}, {74, -14}, {67, -14}}, color = {255, 0, 255}, smooth = Smooth.None));
      connect(integrator.u, realExpression.y) annotation(
        Line(points = {{-51.8, 25}, {-62.7, 25}}, color = {0, 0, 127}, smooth = Smooth.None));
      annotation(
        Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -80}, {100, 80}})),
        Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 127}, fillPattern = FillPattern.Solid, fillColor = {255, 255, 255}), Text(extent = {{-98, 88}, {-40, 60}}, lineColor = {0, 0, 127}, textString = "ampl"), Text(extent = {{-98, -62}, {-28, -88}}, lineColor = {0, 0, 127}, textString = "ph(°)"), Text(extent = {{28, 86}, {100, 60}}, lineColor = {255, 0, 255}, textString = "u"), Text(extent = {{42, -62}, {96, -88}}, lineColor = {255, 0, 255}, textString = "d", fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-60, -60}, {-40, 62}, {-20, -60}, {0, 60}, {20, -62}, {40, 60}, {60, -62}, {80, 58}}, color = {0, 0, 127}, smooth = Smooth.None), Line(points = {{-80, 20}, {-38, 40}, {0, 44}, {42, 40}, {80, 20}}, color = {0, 0, 127}, smooth = Smooth.None, thickness = 0.5), Text(extent = {{-100, 140}, {100, 110}}, lineColor = {0, 0, 255}, textString = "%name")}),
        __OpenModelica_commandLineOptions = "");
    end PwmPulser;

    block PwmPulser3
      Modelica.Blocks.Interfaces.RealInput ampl annotation(
        Placement(transformation(extent = {{-140, 40}, {-100, 80}}), iconTransformation(extent = {{-140, 44}, {-100, 84}})));
      Modelica.Blocks.Interfaces.RealInput ph_deg annotation(
        Placement(transformation(extent = {{-138, -76}, {-98, -36}}), iconTransformation(extent = {{-140, -74}, {-100, -34}})));
      parameter Modelica.SIunits.Frequency fCar = 1050 "Carrier Frequency";
      import PI = Modelica.Constants.pi;
      Modelica.Blocks.Interfaces.BooleanOutput up[3] annotation(
        Placement(transformation(extent = {{100, 30}, {120, 50}}), iconTransformation(extent = {{100, 56}, {120, 76}})));
      Modelica.Blocks.Interfaces.BooleanOutput down[3] annotation(
        Placement(transformation(extent = {{100, -50}, {120, -30}}), iconTransformation(extent = {{100, -68}, {120, -48}})));
      parameter Modelica.SIunits.Frequency fSig = 50 "Modulating signal Frequency";
      PwmPulser pwmPulser[3](fCar = fill(fCar, 3), carStartTime = 3 / fCar * {-1, -2, 0}, fSig = fill(fSig, 3)) annotation(
        Placement(transformation(extent = {{36, -10}, {56, 10}})));
      Modelica.Blocks.Routing.Replicator replicator(nout = 3) annotation(
        Placement(transformation(extent = {{-58, 0}, {-38, 20}})));
      Modelica.Blocks.Routing.Replicator replicator1(nout = 3) annotation(
        Placement(transformation(extent = {{-88, -66}, {-68, -46}})));
      Modelica.Blocks.Math.Add add[3] annotation(
        Placement(transformation(extent = {{-10, -60}, {10, -40}})));
      Modelica.Blocks.Sources.Constant const[3](k = {0, -120, 120}) annotation(
        Placement(transformation(extent = {{-52, -38}, {-32, -18}})));
    equation
      connect(replicator.u, ampl) annotation(
        Line(points = {{-60, 10}, {-80, 10}, {-80, 60}, {-120, 60}}, color = {0, 0, 127}));
      connect(replicator.y, pwmPulser.ampl) annotation(
        Line(points = {{-37, 10}, {-26, 10}, {-26, 6.4}, {34, 6.4}}, color = {0, 0, 127}));
      connect(replicator1.u, ph_deg) annotation(
        Line(points = {{-90, -56}, {-118, -56}}, color = {0, 0, 127}));
      connect(add.u2, replicator1.y) annotation(
        Line(points = {{-12, -56}, {-67, -56}}, color = {0, 0, 127}));
      connect(const.y, add.u1) annotation(
        Line(points = {{-31, -28}, {-20, -28}, {-20, -44}, {-12, -44}}, color = {0, 0, 127}));
      connect(pwmPulser.ph_deg, add.y) annotation(
        Line(points = {{34, -5.4}, {28, -5.4}, {28, -6}, {22, -6}, {22, -50}, {11, -50}}, color = {0, 0, 127}));
      connect(pwmPulser.up, up) annotation(
        Line(points = {{57, 6.6}, {72, 6.6}, {72, 40}, {110, 40}}, color = {255, 0, 255}));
      connect(down, pwmPulser.down) annotation(
        Line(points = {{110, -40}, {66, -40}, {66, -5.8}, {57, -5.8}}, color = {255, 0, 255}));
      annotation(
        Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -80}, {100, 80}})),
        Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 127}, fillPattern = FillPattern.Solid, fillColor = {255, 255, 255}), Text(extent = {{-98, 88}, {-40, 60}}, lineColor = {0, 0, 127}, textString = "ampl"), Text(extent = {{-98, -62}, {-28, -88}}, lineColor = {0, 0, 127}, textString = "ph(°)"), Text(extent = {{48, 88}, {104, 62}}, lineColor = {255, 0, 255}, textString = "u"), Text(extent = {{56, -60}, {100, -86}}, lineColor = {255, 0, 255}, textString = "d", fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-60, -60}, {-40, 62}, {-20, -60}, {0, 60}, {20, -62}, {40, 60}, {60, -62}, {80, 58}}, color = {0, 0, 127}, smooth = Smooth.None), Line(points = {{-80, 20}, {-38, 40}, {0, 44}, {42, 40}, {80, 20}}, color = {0, 0, 127}, smooth = Smooth.None, thickness = 0.5), Text(extent = {{-100, 140}, {100, 110}}, lineColor = {0, 0, 255}, textString = "%name"), Text(extent = {{-26, 50}, {34, -54}}, lineColor = {238, 46, 47}, textString = "3")}),
        __OpenModelica_commandLineOptions = "");
    end PwmPulser3;

    model ToPark "Semplice PMM con modello funzionale inverter"
      parameter Integer p "number of pole pairs";
      Modelica.Electrical.Machines.SpacePhasors.Blocks.Rotator rotator annotation(
        Placement(transformation(extent = {{0, 0}, {20, 20}})));
      Modelica.Blocks.Interfaces.RealOutput y[2] annotation(
        Placement(transformation(extent = {{100, -10}, {120, 10}}), iconTransformation(extent = {{100, -10}, {120, 10}})));
      Modelica.Blocks.Interfaces.RealInput X[3] annotation(
        Placement(transformation(extent = {{-140, -20}, {-100, 20}}), iconTransformation(extent = {{-140, -20}, {-100, 20}})));
      Modelica.Blocks.Interfaces.RealInput phi annotation(
        Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = 90, origin = {10, -110}), iconTransformation(extent = {{-20, -20}, {20, 20}}, rotation = 90, origin = {0, -120})));
      Modelica.Electrical.Machines.SpacePhasors.Blocks.ToSpacePhasor toSpacePhasor annotation(
        Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {-30, 10})));
      Modelica.Blocks.Math.Gain gain(k = p) annotation(
        Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {10, -42})));
    equation
      connect(toSpacePhasor.y, rotator.u) annotation(
        Line(points = {{-19, 10}, {-2, 10}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(rotator.y, y) annotation(
        Line(points = {{21, 10}, {66, 10}, {66, 0}, {110, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(toSpacePhasor.u, X) annotation(
        Line(points = {{-42, 10}, {-82, 10}, {-82, 0}, {-120, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(gain.y, rotator.angle) annotation(
        Line(points = {{10, -31}, {10, -2}}, color = {0, 0, 127}, smooth = Smooth.None));
      connect(gain.u, phi) annotation(
        Line(points = {{10, -54}, {10, -110}}, color = {0, 0, 127}, smooth = Smooth.None));
      annotation(
        Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics),
        experiment(StopTime = 5, Interval = 0.001),
        Documentation(info = "<html>
<p>Converts variables phase quantities into Park&apos;s</p>
</html>"),
        __Dymola_experimentSetupOutput,
        Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-96, 32}, {96, -22}}, lineColor = {0, 0, 127}, textString = "=>P"), Text(extent = {{-106, 144}, {104, 106}}, lineColor = {0, 0, 255}, textString = "%name")}));
    end ToPark;
  end Support;

  model MyModel "With Ideal Switches NO OM 1.9.4-dev-490"
    Modelica.Electrical.MultiPhase.Basic.Star star2 annotation(
      Placement(visible = true, transformation(origin = {31, -59}, extent = {{9, -9}, {-9, 9}}, rotation = 90)));
    Modelica.Electrical.MultiPhase.Basic.Resistor Rload(R = fill(1, 3)) annotation(
      Placement(visible = true, transformation(origin = {32, -26}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Modelica.Electrical.MultiPhase.Basic.Capacitor Cf(C = fill(5e-005, 3)) annotation(
      Placement(visible = true, transformation(origin = {0, -26}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Modelica.Electrical.MultiPhase.Basic.Inductor Lf(L = fill(0.001, 3)) annotation(
      Placement(visible = true, transformation(origin = {24, 16}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Electrical.MultiPhase.Basic.Resistor Rf(R = fill(0.05, 3)) annotation(
      Placement(visible = true, transformation(origin = {-2, 16}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Electrical.MultiPhase.Basic.Star star1 annotation(
      Placement(visible = true, transformation(origin = {-34, -60}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
    Modelica.Electrical.MultiPhase.Basic.Star star annotation(
      Placement(visible = true, transformation(origin = {-34, 58}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Modelica.Electrical.MultiPhase.Ideal.IdealOpeningSwitch downSW(Ron = fill(1e-4, 3), Goff = fill(1e-4, 3)) annotation(
      Placement(visible = true, transformation(origin = {-34, -30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Modelica.Electrical.MultiPhase.Ideal.IdealOpeningSwitch upSW(Ron = fill(1e-4, 3), Goff = fill(1e-4, 3)) annotation(
      Placement(visible = true, transformation(origin = {-34, 30}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Modelica.Blocks.Sources.Constant ampl[3](k = fill(0.7, 3)) annotation(
      Placement(visible = true, transformation(origin = {78, 64}, extent = {{-10, 10}, {10, -10}}, rotation = 180)));
    Modelica.Blocks.Sources.Constant phase[3](k = {0, 120, -120}) annotation(
      Placement(visible = true, transformation(origin = {82, 16}, extent = {{-10, 10}, {10, -10}}, rotation = 180)));
    Support.PwmPulser pwmPulser[3](fCar = fill(2000, 3)) annotation(
      Placement(visible = true, transformation(origin = {18, 48}, extent = {{-13, 13}, {13, -13}}, rotation = 180)));
    Modelica.Electrical.Analog.Sources.ConstantVoltage V1(V = 50) annotation(
      Placement(visible = true, transformation(origin = {-90, 18}, extent = {{-10, 10}, {10, -10}}, rotation = 270)));
    Modelica.Electrical.Analog.Basic.Ground ground1 annotation(
      Placement(visible = true, transformation(origin = {-112, -24}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Electrical.Analog.Basic.Resistor Rbat(R = 0.2) annotation(
      Placement(visible = true, transformation(origin = {-90, 46}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    Modelica.Electrical.Analog.Basic.Inductor Lf1(L = 1e-003) annotation(
      Placement(visible = true, transformation(origin = {-72, 68}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Electrical.Analog.Basic.Capacitor dcCap(C = 5e-5, v(fixed = true, start = 100)) annotation(
      Placement(visible = true, transformation(origin = {-56, 0}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    AronSensor aron annotation(
      Placement(visible = true, transformation(origin = {48, 2}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Modelica.Electrical.Analog.Basic.Inductor Lf2(L = 1e-003) annotation(
      Placement(visible = true, transformation(origin = {-72, -70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Electrical.Analog.Basic.Resistor resistor1(R = 0.2) annotation(
      Placement(visible = true, transformation(origin = {-90, -52}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
    Modelica.Electrical.Analog.Sources.ConstantVoltage V2(V = 50) annotation(
      Placement(visible = true, transformation(origin = {-90, -14}, extent = {{-10, 10}, {10, -10}}, rotation = 270)));
  equation
    connect(dcCap.n, star1.pin_n) annotation(
      Line(points = {{-56, -10}, {-56, -70}, {-34, -70}}, color = {0, 0, 255}));
    connect(dcCap.p, Lf1.n) annotation(
      Line(points = {{-56, 10}, {-56, 68}, {-62, 68}}, color = {0, 0, 255}));
    connect(downSW.plug_n, star1.plug_p) annotation(
      Line(points = {{-34, -40}, {-34, -50}}, color = {0, 0, 255}));
    connect(Lf2.n, star1.pin_n) annotation(
      Line(points = {{-62, -70}, {-34, -70}, {-34, -70}, {-34, -70}}, color = {0, 0, 255}));
    connect(resistor1.n, Lf2.p) annotation(
      Line(points = {{-90, -62}, {-90, -62}, {-90, -70}, {-82, -70}, {-82, -70}}, color = {0, 0, 255}));
    connect(upSW.plug_p, star.plug_p) annotation(
      Line(points = {{-34, 40}, {-34, 48}}, color = {0, 0, 255}));
    connect(star.pin_n, Lf1.n) annotation(
      Line(points = {{-34, 68}, {-62, 68}}, color = {0, 0, 255}));
    connect(Rf.plug_p, downSW.plug_p) annotation(
      Line(points = {{-12, 16}, {-34, 16}, {-34, -20}}, color = {0, 0, 255}));
    connect(upSW.plug_n, downSW.plug_p) annotation(
      Line(points = {{-34, 20}, {-34, -20}}, color = {0, 0, 255}));
    connect(pwmPulser.down, downSW.control) annotation(
      Line(points = {{3.7, 40.46}, {-18, 40.46}, {-18, -30}, {-27, -30}}, color = {255, 0, 255}));
    connect(pwmPulser.up, upSW.control) annotation(
      Line(points = {{3.7, 56.58}, {-22, 56.58}, {-22, 30}, {-27, 30}}, color = {255, 0, 255}));
    connect(V2.n, resistor1.p) annotation(
      Line(points = {{-90, -24}, {-90, -24}, {-90, -42}, {-90, -42}, {-90, -42}}, color = {0, 0, 255}));
    connect(ground1.p, V2.p) annotation(
      Line(points = {{-112, -14}, {-112, -14}, {-112, -4}, {-90, -4}, {-90, -4}}, color = {0, 0, 255}));
    connect(V2.p, V1.n) annotation(
      Line(points = {{-90, -4}, {-90, -4}, {-90, 8}, {-90, 8}}, color = {0, 0, 255}));
    connect(Lf1.p, Rbat.p) annotation(
      Line(points = {{-82, 68}, {-90, 68}, {-90, 56}}, color = {0, 0, 255}));
    connect(V1.p, Rbat.n) annotation(
      Line(points = {{-90, 28}, {-90, 36}}, color = {0, 0, 255}));
    connect(Rload.plug_n, star2.plug_p) annotation(
      Line(points = {{32, -36}, {32, -39}, {31, -39}, {31, -50}}, color = {0, 0, 255}));
    connect(aron.n, Lf.plug_n) annotation(
      Line(points = {{48, 12}, {48, 16}, {34, 16}}, color = {0, 0, 255}));
    connect(aron.p, Cf.plug_p) annotation(
      Line(points = {{48, -8}, {48, -16}, {0, -16}}, color = {0, 0, 255}));
    connect(phase.y, pwmPulser.ph_deg) annotation(
      Line(points = {{71, 16}, {60, 16}, {60, 40.98}, {33.6, 40.98}}, color = {0, 0, 127}));
    connect(ampl.y, pwmPulser.ampl) annotation(
      Line(points = {{67, 64}, {60, 64}, {60, 56.32}, {33.6, 56.32}}, color = {0, 0, 127}));
    connect(Rf.plug_n, Lf.plug_p) annotation(
      Line(points = {{8, 16}, {14, 16}}, color = {0, 0, 255}));
    connect(Cf.plug_p, Rload.plug_p) annotation(
      Line(points = {{0, -16}, {32, -16}}, color = {0, 0, 255}));
    connect(Cf.plug_n, Rload.plug_n) annotation(
      Line(points = {{0, -36}, {32, -36}}, color = {0, 0, 255}));
    annotation(
      experimentSetupOutput,
      Documentation(info = "<html>
  <p>Il risultato &egrave; identico a quello che si ha con interruttori pilotati e dioidi in antiparallelo entrambi iteali.</p>
  <p>Questo perch&eacute; con un controllo senza blanking time i due inverter sono identici.</p>
  <p>Il sisema pi&ugrave; fisico &egrave; superiore perch&eacute; consente di valutare anche gli effetti del blanking time.</p>
  </html>"),
      experiment(StopTime = 0.04, Interval = 2e-005),
      Icon(coordinateSystem(extent = {{-120, -100}, {100, 100}})),
      Diagram(coordinateSystem(extent = {{-120, -80}, {100, 80}}, preserveAspectRatio = false)),
      __OpenModelica_commandLineOptions = "");
  end MyModel;
  annotation(
    uses(Modelica(version = "3.2.3"), PowerSystems(version = "0.6.0")),
    Documentation(info = "<html><head></head><body><p><font size=\"4\">Inverter reference data:</font></p>
<p><font size=\"4\">Total DC voltage 100 V</font></p>
<p><font size=\"4\">When a passive load is fed: resistance 1 ohm, inductance 5mH</font></p>
<p><font size=\"4\">Filter resistance 0.05 ohm</font></p>
</body></html>"));
end RedBoxIssue;

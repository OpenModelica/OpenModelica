within ;
model Aufgabe1_1

  Modelica.Electrical.Analog.Basic.Resistor resistor(R=13.8)
    annotation (Placement(transformation(extent={{-30,30},{-10,50}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Inductor inductor(L=0.0061, i(start=0, fixed
        =true))
    annotation (Placement(transformation(extent={{8,30},{28,50}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{30,-40},{50,-20}}, rotation=0)));
  Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage
    annotation (Placement(transformation(
        origin={-40,10},
        extent={{-10,10},{10,-10}},
        rotation=270)));
  Modelica.Electrical.Analog.Basic.EMF emf(k=1.016)
                                           annotation (Placement(transformation(
          extent={{30,0},{50,20}}, rotation=0)));
  Modelica.Blocks.Sources.Ramp ramp(duration=0.1, height=100)
    annotation (Placement(transformation(extent={{-80,0},{-60,20}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.Inertia motorInertia(
                                                     J=0.0025,
    phi(fixed=true, start=0),
    w(fixed=true, start=0))
    annotation (Placement(transformation(extent={{60,0},{80,20}}, rotation=0)));
  Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor
    annotation (Placement(transformation(extent={{8,-30},{-12,-10}}, rotation=0)));
equation
  connect(signalVoltage.p,resistor. p) annotation (Line(points={{-40,20},{-40,
          40},{-30,40}}, color={0,0,255}));
  connect(resistor.n,inductor. p)
    annotation (Line(points={{-10,40},{8,40}}, color={0,0,255}));
  connect(inductor.n,emf. p) annotation (Line(points={{28,40},{40,40},{40,20}},
        color={0,0,255}));
  connect(emf.n,ground. p)
    annotation (Line(points={{40,0},{40,-20}}, color={0,0,255}));
  connect(ramp.y,signalVoltage. v) annotation (Line(points={{-59,10},{-53,10},{
          -53,10},{-47,10}},
        color={0,0,127}));
  connect(motorInertia.flange_a,emf.flange)
    annotation (Line(points={{60,10},{50,10}}, color={0,0,0}));
  connect(currentSensor.n, signalVoltage.n) annotation (Line(points={{-12,-20},
          {-40,-20},{-40,0}}, color={0,0,255}));
  connect(currentSensor.p, ground.p)
    annotation (Line(points={{8,-20},{40,-20}}, color={0,0,255}));
  annotation (uses(Modelica(version="3.2.1")),   Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
                                                       graphics),
    experiment(StopTime=0.2),
    experimentSetupOutput,
    Commands(file="Plot ramp.y und Jmotor.w.mos" "Plot ramp.y und Jmotor.w"),
    version="1",
    conversion(from(version="", script="ConvertFromAufgabe1_1_.mos")));
end Aufgabe1_1;

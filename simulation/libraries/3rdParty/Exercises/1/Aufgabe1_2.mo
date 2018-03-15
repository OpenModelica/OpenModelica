within ;
model Aufgabe1_2
/*
parameter Real controller_k=30 "Verstaerkung vom PI Regler";
parameter Modelica.SIunits.Time controller_T=0.005
    "Zeitkonstante vom PI Regler";
*/
  Modelica.Electrical.Analog.Basic.Resistor resistor(R=13.8)
    annotation (Placement(transformation(extent={{-30,30},{-10,50}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Inductor inductor(L=0.061, i(start=0, fixed=
          true))
    annotation (Placement(transformation(extent={{0,30},{20,50}}, rotation=0)));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{20,-40},{40,-20}}, rotation=0)));
  Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage
    annotation (Placement(transformation(
        origin={-40,10},
        extent={{-10,10},{10,-10}},
        rotation=270)));
  Modelica.Electrical.Analog.Basic.EMF emf(k=1.016)
                                           annotation (Placement(transformation(
          extent={{20,0},{40,20}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.Inertia motorInertia(
                                                     J=0.0025)
    annotation (Placement(transformation(extent={{46,0},{66,20}}, rotation=0)));
  Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor
    annotation (Placement(transformation(extent={{-2,-30},{-22,-10}}, rotation=
            0)));
  Modelica.Mechanics.Rotational.Components.IdealGear idealGear(
                                                    ratio=105, useSupport=true)
    annotation (Placement(transformation(extent={{74,0},{94,20}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.SpringDamper springDamper(
                                                          c=5.0e5, d=500,
    phi_rel(fixed=true),
    w_rel(fixed=true))
    annotation (Placement(transformation(extent={{106,0},{126,20}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.Inertia loadInertia(
                                                    J=100,
    phi(fixed=true, start=0),
    w(fixed=true, start=0),
    a(fixed=false))
    annotation (Placement(transformation(extent={{138,0},{158,20}}, rotation=0)));
  Modelica.Blocks.Continuous.PI PI(k=30, T=0.005,
    initType=Modelica.Blocks.Types.Init.InitialState)
    annotation (Placement(transformation(extent={{-108,0},{-88,20}}, rotation=0)));
  Modelica.Blocks.Math.Feedback feedback annotation (Placement(transformation(
          extent={{-138,0},{-118,20}}, rotation=0)));
  Modelica.Blocks.Sources.Step step(height=4.7)
    annotation (Placement(transformation(extent={{-166,0},{-146,20}}, rotation=
            0)));
  Modelica.Blocks.Continuous.FirstOrder firstOrder(T=0.001, initType=Modelica.Blocks.Types.Init.InitialState)
    annotation (Placement(transformation(extent={{-76,0},{-56,20}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.Fixed fixed
                                            annotation (Placement(
        transformation(extent={{74,-26},{94,-6}}, rotation=0)));
equation
  connect(signalVoltage.p,resistor. p) annotation (Line(points={{-40,20},{-40,
          40},{-30,40}}, color={0,0,255}));
  connect(resistor.n,inductor. p)
    annotation (Line(points={{-10,40},{0,40}}, color={0,0,255}));
  connect(inductor.n,emf. p) annotation (Line(points={{20,40},{30,40},{30,20}},
        color={0,0,255}));
  connect(emf.n,ground. p)
    annotation (Line(points={{30,0},{30,-20}}, color={0,0,255}));
  connect(motorInertia.flange_a,emf.flange)
    annotation (Line(points={{46,10},{40,10}}, color={0,0,0}));
  connect(currentSensor.n, signalVoltage.n) annotation (Line(points={{-22,-20},
          {-40,-20},{-40,0}}, color={0,0,255}));
  connect(currentSensor.p, ground.p)
    annotation (Line(points={{-2,-20},{30,-20}}, color={0,0,255}));
  connect(idealGear.flange_b, springDamper.flange_a)
    annotation (Line(points={{94,10},{106,10}}, color={0,0,0}));
  connect(springDamper.flange_b, loadInertia.flange_a)
    annotation (Line(points={{126,10},{138,10}}, color={0,0,0}));
  connect(feedback.y, PI.u) annotation (Line(points={{-119,10},{-110,10}},
        color={0,0,127}));
  connect(step.y, feedback.u1) annotation (Line(points={{-145,10},{-136,10}},
        color={0,0,127}));
  connect(currentSensor.i, feedback.u2) annotation (Line(points={{-12,-30},{-12,
          -36},{-128,-36},{-128,2}}, color={0,0,127}));
  connect(motorInertia.flange_b, idealGear.flange_a)
    annotation (Line(points={{66,10},{74,10}}, color={0,0,0}));
  connect(PI.y, firstOrder.u)
    annotation (Line(points={{-87,10},{-78,10}}, color={0,0,127}));
  connect(firstOrder.y, signalVoltage.v)
    annotation (Line(points={{-55,10},{-51,10},{-47,10}},
                                                 color={0,0,127}));
  connect(fixed.flange,idealGear.support)
    annotation (Line(points={{84,-16},{84,0}}, color={0,0,0}));
  annotation (uses(Modelica(version="3.2.1")),   Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-180,-100},{180,100}}), graphics),
    experiment(StopTime=0.2),
    __Dymola_Commands(file="Plot feedback.u1 und u2.mos"
        "Plot feedback.u1 und u2"),
    version="1",
    conversion(from(version="", script="ConvertFromAufgabe1_2_.mos")));
end Aufgabe1_2;

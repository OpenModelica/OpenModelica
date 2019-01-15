package DualMassOscillator
  model System1
    parameter Real s1_start = 1.0;
    parameter Real v1_start = 0.0;
    parameter Real m1 = 1.0;
    parameter Real c1 = 1e4;
    parameter Real d1 = 2;

    Modelica.Mechanics.Translational.Components.Fixed fixed(s0=0.0) annotation(
      Placement(transformation(extent={{-10,-10}, {10,10}}, rotation=0, origin={-70,0})));
    Modelica.Mechanics.Translational.Components.Mass mass1( L=0.0, m=m1, s(fixed=true, start=s1_start), v(fixed=true, start=v1_start)) annotation(
      Placement(transformation(extent={{-14,-10}, {6,10}})));
    Modelica.Mechanics.Translational.Components.SpringDamper springDamper1(c=c1, d=d1, s_rel0=1.0) annotation(
      Placement(transformation(extent={{-50,-10}, {-30,10}})));
    Modelica.Mechanics.Translational.Sensors.PositionSensor positionSensor annotation(
      Placement(transformation(extent={{20,-40}, {40,-20}})));
    Modelica.Mechanics.Translational.Sensors.SpeedSensor speedSensor annotation(
      Placement(transformation(extent={{20,-60}, {40,-40}})));
    Modelica.Mechanics.Translational.Sensors.AccSensor accSensor annotation(
      Placement(transformation(extent={{20,-80}, {40,-60}})));
    Modelica.Mechanics.Translational.Sources.Force force annotation(
      Placement(transformation(extent={{40,-10}, {20,10}})));
    Modelica.Blocks.Interfaces.RealInput F annotation(
      Placement(transformation(extent={{120,-10}, {100,10}}), iconTransformation(extent={{120,-10}, {100,10}})));
    Modelica.Blocks.Interfaces.RealOutput s1 annotation(
      Placement(transformation(extent={{100,-40}, {120,-20}}), iconTransformation(extent={{100,-40}, {120,-20}})));
    Modelica.Blocks.Interfaces.RealOutput v1 annotation(
      Placement(transformation(extent={{100,-60}, {120,-40}}), iconTransformation(extent={{100,-60}, {120,-40}})));
    Modelica.Blocks.Interfaces.RealOutput a1 annotation(
      Placement(transformation(extent={{100,-80}, {120,-60}}), iconTransformation(extent={{100,-80}, {120,-60}})));
  equation
    connect(fixed.flange, springDamper1.flange_a) annotation(
      Line(points={{-70,0}, {-60,0}, {-50,0}}, color={0,127,0}));
    connect(springDamper1.flange_b, mass1.flange_a) annotation(
      Line(points={{-30,0}, {-22,0}, {-14,0}}, color={0,127,0}));
    connect(mass1.flange_b, positionSensor.flange) annotation(
      Line(points={{6,0}, {12,0}, {12, -30}, {20,-30}}, color={0,127,0}));
    connect(mass1.flange_b, speedSensor.flange) annotation(
      Line(points={{6,0}, {12,0}, {12,-50}, {20,-50}}, color={0,127,0}));
    connect(mass1.flange_b, accSensor.flange) annotation(
      Line(points={{6,0}, {12,0}, {12,-70}, {20,-70}}, color={0,127,0}));
    connect(force.flange, mass1.flange_b) annotation(
      Line(points={{20,0}, {6,0}}, color={0,127,0}));
    connect(accSensor.a, a1) annotation(
      Line(points={{41,-70}, {110,-70}}, color={0,0,127}));
    connect(speedSensor.v, v1) annotation(
      Line(points={{41,-50}, {110,-50}}, color={0,0,127}));
    connect(positionSensor.s, s1) annotation(
      Line(points={{41,-30}, {110,-30}}, color={0,0,127}));
    connect(force.f, F) annotation(
      Line(points={{42,0}, {110,0}}, color={0,0,127}));
    annotation(Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(coordinateSystem(preserveAspectRatio=false)));
  end System1;

  model System2
    parameter Real s2_start = 2.0;
    parameter Real v2_start = 0.0;
    parameter Real m2 = 1.0;
    parameter Real c2 = 1e5;
    parameter Real d2 = 6.3246;
    parameter Real cc = 1e6;
    parameter Real dc = 14.1421;

    Real s2 = mass2.s;

    Modelica.Mechanics.Translational.Components.Fixed fixed(s0=3.0) annotation(
      Placement(transformation(extent={{80, -10}, {100, 10}})));
    Modelica.Mechanics.Translational.Components.Mass mass2( L=0.0, m=m2, s(fixed=true, start=s2_start), v(fixed=true, start=v2_start)) annotation(
      Placement(transformation(extent={{20, -10}, {40, 10}})));
    Modelica.Mechanics.Translational.Components.SpringDamper springDamper2(c=c2, d=d2, s_rel0=1.0) annotation(
      Placement(transformation(extent={{50, -10}, {70, 10}})));
    Modelica.Mechanics.Translational.Components.SpringDamper springDamper_coupling(c=cc, d=dc, s_rel0=1.0) annotation(
      Placement(transformation(extent={{-10, -10}, {10, 10}})));
    Modelica.Blocks.Interfaces.RealOutput F annotation(
      Placement(transformation(extent={{-100, -10}, {-120, 10}})));
    Modelica.Blocks.Interfaces.RealInput s1 annotation(
      Placement(transformation(extent={{-120, -40}, {-100, -20}})));
    Modelica.Blocks.Interfaces.RealInput v1 annotation(
      Placement(transformation(extent={{-120, -60}, {-100, -40}})));
    Modelica.Blocks.Interfaces.RealInput a1 annotation(
      Placement(transformation(extent={{-120, -80}, {-100, -60}})));
    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor annotation(
      Placement(transformation(extent={{-20, 10}, {-40, -10}})));
    Modelica.Mechanics.Translational.Sources.Move move annotation(
      Placement(transformation(extent={{-68, -10}, {-48, 10}})));
  equation
    connect(forceSensor.f, F) annotation(
      Line(points={{-22, 11}, {-90, 11}, {-90, 0}, {-110, 0}}, color={0,0,127}));
    connect(s1, move.u[1]) annotation(
      Line(points={{-110, -30}, {-80, -30}, {-80, -1.33333}, {-70, -1.33333}}, color={0,0,127}));
    connect(v1, move.u[2]) annotation(
      Line(points={{-110, -50}, {-80, -50}, {-80, 0}, {-70, 0}}, color={0,0,127}));
    connect(a1, move.u[3]) annotation(
      Line(points={{-110, -70}, {-80, -70}, {-80, 1.33333}, {-70, 1.33333}}, color={0,0,127}));
    connect(springDamper_coupling.flange_b, mass2.flange_a) annotation(
      Line(points={{10, 0}, {15, 0}, {20, 0}}, color={0,127,0}));
    connect(mass2.flange_b, springDamper2.flange_a) annotation(
      Line(points={{40, 0}, {45, 0}, {50, 0}}, color={0,127,0}));
    connect(springDamper2.flange_b, fixed.flange) annotation(
      Line(points={{70, 0}, {80, 0}, {90, 0}}, color={0,127,0}));
    connect(forceSensor.flange_a, springDamper_coupling.flange_a) annotation(
      Line(points={{-20, 0}, {-15, 0}, {-10, 0}}, color={0,127,0}));
    connect(move.flange, forceSensor.flange_b) annotation(
      Line(points={{-48, 0}, {-44, 0}, {-40, 0}}, color={0,127,0}));
    annotation(Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(coordinateSystem(preserveAspectRatio=false)));
  end System2;

  model CoupledSystem
    System1 system1 annotation(
      Placement(transformation(extent={{-30, -10}, {-10, 10}})));
    System2 system2 annotation(
      Placement(transformation(extent={{10, -10}, {30, 10}})));
  equation
    connect(system2.F, system1.F) annotation(
      Line(points={{9, 0}, {-9, 0}}, color={0,0,127}));
    connect(system1.s1, system2.s1) annotation(
      Line(points={{-9, -3}, {-9, -3}, {9, -3}}, color={0,0,127}));
    connect(system1.v1, system2.v1) annotation(
      Line(points={{-9, -5}, {-9, -5}, {9, -5}}, color={0,0,127}));
    connect(system1.a1, system2.a1) annotation(
      Line(points={{-9, -7}, {-9, -7}, {9, -7}}, color={0,0,127}));
    annotation(Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(coordinateSystem(preserveAspectRatio=false)));
  end CoupledSystem;

  model ReferenceSystem
    parameter Real s1_start = 1.0;
    parameter Real v1_start = 0.0;
    parameter Real m1 = 1.0;
    parameter Real s2_start = 2.0;
    parameter Real v2_start = 0.0;
    parameter Real m2 = 1.0;
    parameter Real c1 = 1e4;
    parameter Real d1 = 2;
    parameter Real c2 = 1e5;
    parameter Real d2 = 6.3246;
    parameter Real cc = 1e6;
    parameter Real dc = 14.1421;

    Real s1 = mass1.s;
    Real s2 = mass2.s;

    Modelica.Mechanics.Translational.Components.Fixed fixed(s0=0.0) annotation(
      Placement(transformation(extent={{-10, 10}, {10, -10}}, rotation=90, origin={-86, 0})));
    Modelica.Mechanics.Translational.Components.Mass mass1( L=0.0, m=m1, s(fixed=true, start=s1_start), v(fixed=true, start=v1_start)) annotation(
      Placement(transformation(extent={{-40, -10}, {-20, 10}})));
    Modelica.Mechanics.Translational.Components.SpringDamper springDamper1(c=c1, d=d1, s_rel0=1.0) annotation(
      Placement(transformation(extent={{-70, -10}, {-50, 10}})));
    Modelica.Mechanics.Translational.Components.Fixed fixed1(s0=3.0) annotation(
      Placement(transformation(extent={{-10, -10}, {10, 10}}, rotation=90, origin={86, 0})));
    Modelica.Mechanics.Translational.Components.Mass mass2( L=0.0, m=m2, s(fixed=true, start=s2_start), v(fixed=true, start=v2_start)) annotation(
      Placement(transformation(extent={{20, -10}, {40, 10}})));
    Modelica.Mechanics.Translational.Components.SpringDamper springDamper2(c=c2, d=d2, s_rel0=1.0) annotation(
      Placement(transformation(extent={{50, -10}, {70, 10}})));
    Modelica.Mechanics.Translational.Components.SpringDamper springDamper_coupling(c=cc, d=dc, s_rel0=1.0) annotation(
      Placement(transformation(extent={{-10, -10}, {10, 10}})));
  equation
    connect(fixed.flange, springDamper1. flange_a) annotation(
      Line(points={{-86, 0}, {-86, 0}, {-70, 0}}, color={0,127,0}));
    connect(springDamper1.flange_b, mass1. flange_a) annotation(
      Line(points={{-50, 0}, {-40, 0}}, color={0,127,0}));
    connect(springDamper_coupling.flange_b, mass2. flange_a) annotation(
      Line(points={{10, 0}, {10, 0}, {20, 0}}, color={0,127,0}));
    connect(mass2.flange_b, springDamper2. flange_a) annotation(
      Line(points={{40, 0}, {40, 0}, {50, 0}}, color={0,127,0}));
    connect(springDamper2.flange_b, fixed1.flange) annotation(
      Line(points={{70, 0}, {70, 0}, {86, 0}}, color={0,127,0}));
    connect(mass1.flange_b, springDamper_coupling.flange_a) annotation(
      Line(points={{-20, 0}, {-20, 0}, {-10, 0}}, color={0,127,0}));
    annotation(Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100, -20}, {100, 20}})), Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100, -20}, {100, 20}})));
  end ReferenceSystem;
  annotation(uses(Modelica(version="3.2.2")));
end DualMassOscillator;

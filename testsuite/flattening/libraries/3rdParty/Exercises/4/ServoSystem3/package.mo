within ;
package ServoSystem3 "Musterloesung von Aufgabe 3 und Aufgabe 4"


expandable connector ControlBus
  extends Modelica.Icons.SignalBus;
end ControlBus;


  model NonlinearSpring
  "Nonlinear 1D rotational spring (= gear characteristic)"
    import SI = Modelica.SIunits;
    parameter SI.RotationalSpringConstant c_min = 1.95e5
    "Spring constant for small angles";
    parameter SI.RotationalSpringConstant c_max = 5.84e5
    "Spring constant for nominal torque";
    parameter SI.Torque tau_n=500 "Nominal torque";
    SI.Angle phi_rel "Relative rotation angle (flange_b.phi - flange_a.phi)";
    SI.Angle phi_n "Nominal angle at nominal torque tau_n";
    Real a3 "Coefficient a3 of the polynomial";
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (Placement(
          transformation(extent={{-110,-10},{-90,10}}, rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b annotation (Placement(
          transformation(extent={{90,-10},{110,10}}, rotation=0)));
  equation
    phi_n   = 3*tau_n/(c_max + 2*c_min);
    a3      = (c_max - c_min)/(3*phi_n*phi_n);
    phi_rel = flange_b.phi - flange_a.phi;
    0       = flange_a.tau + flange_b.tau;
    flange_b.tau = (c_min + a3*phi_rel*phi_rel)*phi_rel;
    annotation (
      Documentation(info="
<HTML>
<p>
A <b>non-linear 1D rotational spring</b> with a characteristic
which is typical for the elasticity of a gearbox. The elasticity
is described by the spring constant c_min for small deformation
angles, by the spring constant c_max for nominal (large) deformation
angles, and by the nominal torque tau_n. With these parameters the
gearbox characteristic is approximated by a polynomial of degree 3.
</p>
</HTML>
"),   Icon(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={1,1}), graphics={
        Text(
          extent={{-151,110},{149,50}},
          textString="%name",
          lineColor={0,0,255}),
        Text(
          extent={{-114,-63},{119,-103}},
          lineColor={0,0,0},
          textString="c_max=%c_max"),
        Line(
          points={{-100,0},{-58,0},{-43,-30},{-13,30},{17,-30},{47,30},{62,0},{
              100,0}},
          color={0,0,0},
          pattern=LinePattern.Solid,
          thickness=0.25,
          arrow={Arrow.None,Arrow.None}),
        Line(points={{-80,-60},{-60,-20},{60,20},{80,60}}, color={255,0,0})}),
      Diagram(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={1,1}), graphics={
        Line(points={{-68,0},{-68,65}}, color={128,128,128}),
        Line(points={{72,0},{72,65}}, color={128,128,128}),
        Line(points={{-68,60},{72,60}}, color={128,128,128}),
        Polygon(
          points={{62,63},{72,60},{62,57},{62,63}},
          lineColor={128,128,128},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-22,62},{18,87}},
          lineColor={0,0,255},
          textString="phi_rel"),
        Line(points={{-96,0},{-60,0},{-42,-32},{-12,30},{18,-30},{48,28},{62,0},
              {96,0}})}));
  end NonlinearSpring;


  model Gear1
  "Realistisches Modell eines Getriebes mit nichlinearer Getriebeelastizitaet und Daempfung"
    parameter Real ratio=105 "Getriebe-Uebersetzung";
    Modelica.Mechanics.Rotational.Components.IdealGear gear(
                                                 ratio=ratio, useSupport=true)
      annotation (Placement(transformation(extent={{-60,-10},{-40,10}},
          rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}},
          rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b
      annotation (Placement(transformation(extent={{90,-10},{110,10}}, rotation=
           0)));
    NonlinearSpring nonlinearSpring annotation (Placement(transformation(extent=
           {{20,10},{40,30}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Damper damper(d=500,
    phi_rel(fixed=true),
    w_rel(fixed=true))
      annotation (Placement(transformation(extent={{20,-30},{40,-10}}, rotation=
           0)));
    Modelica.Mechanics.Rotational.Components.Fixed fixed
      annotation (Placement(transformation(extent={{-60,-49},{-40,-29}},
          rotation=0)));
    Modelica.Mechanics.Rotational.Components.Damper damper2(
                                                 d=100,
    phi_rel(fixed=false),
    w_rel(fixed=false))
      annotation (Placement(transformation(
        origin={-30,-20},
        extent={{-10,-10},{10,10}},
        rotation=270)));
  equation
    connect(gear.flange_a, flange_a)
      annotation (Line(points={{-60,0},{-100,0}}, color={0,0,0}));
    connect(gear.flange_b, nonlinearSpring.flange_a)
      annotation (Line(points={{-40,0},{0,0},{0,20},{20,20}}, color={0,0,0}));
  connect(gear.flange_b, damper.flange_a)
      annotation (Line(points={{-40,0},{0,0},{0,-20},{20,-20}}, color={0,0,0}));
    connect(nonlinearSpring.flange_b, flange_b)
      annotation (Line(points={{40,20},{60,20},{60,0},{100,0}}, color={0,0,0}));
  connect(damper.flange_b, flange_b)
      annotation (Line(points={{40,-20},{60,-20},{60,0},{100,0}}, color={0,0,0}));
    connect(fixed.flange,   damper2.flange_b)
      annotation (Line(points={{-50,-39},{-50,-30},{-30,-30}}, color={0,0,0}));
    connect(gear.support,fixed.flange)
      annotation (Line(points={{-50,-10},{-50,-39}}, color={0,0,0}));
    connect(damper2.flange_a, gear.flange_b) annotation (Line(points={{-30,-10},
          {-30,0},{-40,0}}, color={0,0,0}));
    annotation (
      Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Rectangle(
          extent={{-100,10},{-60,-10}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Rectangle(
          extent={{60,10},{100,-10}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Rectangle(
          extent={{-40,60},{40,-60}},
          lineColor={0,0,0},
          pattern=LinePattern.Solid,
          lineThickness=0.25,
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Polygon(
          points={{-60,10},{-60,20},{-40,40},{-40,-40},{-60,-20},{-60,10}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={128,128,128}),
        Polygon(
          points={{60,20},{40,40},{40,-40},{60,-20},{60,20}},
          lineColor={128,128,128},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-60,-90},{-50,-90},{-20,-30},{20,-30},{48,-90},{60,-90},{60,
              -100},{-60,-100},{-60,-90}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Text(extent={{-100,128},{100,68}}, textString="%name"),
        Text(
          extent={{-98,-106},{102,-148}},
          lineColor={0,0,0},
          textString="ratio=%ratio")}),
      Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics));
  end Gear1;


model ControlledMotor "Current controlled DC motor"
  parameter Real k=30 "Gain of PI current controller";
  parameter Modelica.SIunits.Time T=0.005
    "Time Constant of PI current controller (T>0 required)";
  Modelica.Electrical.Machines.BasicMachines.DCMachines.DC_PermanentMagnet DCPM(
    Ra=13.8,
    La=0.061,
    IaNominal=4.7,
    Jr =    0.0025,
    VaNominal=380,
  wNominal=(2960)*2*3.14159265358979323846/60,
    TaOperational=293.15,
    TaNominal=293.15,
    TaRef=293.15,
    alpha20a=Modelica.Electrical.Machines.Thermal.Constants.alpha20Zero,
    la(i(start=0, fixed=true)))
                     annotation (Placement(transformation(extent={{70,-10},{
          90,10}}, rotation=0)));
  Modelica.Mechanics.Rotational.Interfaces.Flange_b flange
    annotation (Placement(transformation(extent={{90,-10},{110,10}}, rotation=
         0)));
  Modelica.Blocks.Interfaces.RealInput refCurrent "Reference current of motor"
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}},
        rotation=0)));
  Modelica.Blocks.Math.Feedback feedback
    annotation (Placement(transformation(extent={{-90,-10},{-70,10}},
        rotation=0)));
  Modelica.Blocks.Continuous.PI PI(T=T, k=k,
    initType=Modelica.Blocks.Types.Init.InitialState)
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}},
        rotation=0)));
  Modelica.Blocks.Continuous.FirstOrder firstOrder(T=0.001, initType=Modelica.Blocks.Types.Init.InitialState)
    annotation (Placement(transformation(extent={{-20,-10},{0,10}}, rotation=
          0)));
  Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage
    annotation (Placement(transformation(
      origin={20,0},
      extent={{-10,10},{10,-10}},
      rotation=270)));
  Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor
    annotation (Placement(transformation(extent={{50,-30},{30,-10}}, rotation=
         0)));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{50,-52},{70,-32}}, rotation=
         0)));
equation

  connect(DCPM.flange,   flange)
    annotation (Line(points={{90,0},{100,0}}, color={0,0,0}));
  connect(feedback.u1, refCurrent)
    annotation (Line(points={{-88,0},{-120,0}}, color={0,0,127}));
  connect(feedback.y, PI.u)
    annotation (Line(points={{-71,0},{-62,0}}, color={0,0,127}));
  connect(PI.y, firstOrder.u)
    annotation (Line(points={{-39,0},{-22,0}}, color={0,0,127}));
  connect(firstOrder.y, signalVoltage.v) annotation (Line(points={{1,0},{13,0},
          {13,1.28588e-015}},color={0,0,127}));
  connect(currentSensor.n, signalVoltage.n) annotation (Line(points={{30,-20},{
          20,-20},{20,-10}},color={0,0,255}));
  connect(signalVoltage.p, DCPM.pin_ap) annotation (Line(points={{20,10},{20,32},
          {86,32},{86,10}},   color={0,0,255}));
  connect(ground.p, currentSensor.p) annotation (Line(points={{60,-32},{60,
        -20},{50,-20}}, color={0,0,255}));
  connect(currentSensor.i, feedback.u2) annotation (Line(points={{40,-30},{40,
        -40},{-80,-40},{-80,-8}}, color={0,0,127}));
  connect(currentSensor.p, DCPM.pin_an) annotation (Line(points={{50,-20},{60,
        -20},{60,10},{74,10}}, color={0,0,255}));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}),
                      graphics),
                       Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Rectangle(
          extent={{-100,50},{30,-50}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={255,0,0}),
        Polygon(
          points={{-100,-90},{-90,-90},{-60,-20},{-10,-20},{20,-90},{30,-90},{
              30,-100},{-100,-100},{-100,-90}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{30,10},{100,-10}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Text(
          extent={{-146,96},{148,66}},
          lineColor={0,0,255},
          textString="%name")}));
end ControlledMotor;


model ControlledMotorWithBus "Current controlled DC motor with bus"
  parameter Real k=30 "Gain of PI current controller";
  parameter Modelica.SIunits.Time T=0.005
    "Time Constant of PI current controller (T>0 required)";
  Modelica.Electrical.Machines.BasicMachines.DCMachines.DC_PermanentMagnet DCPM(
    Ra=13.8,
    La=0.061,
    IaNominal=4.7,
    Jr =    0.0025,
    VaNominal=380,
  wNominal=(2960)*2*3.14159265358979323846/60,
    TaOperational=293.15,
    TaNominal=293.15,
    TaRef=293.15,
    alpha20a=Modelica.Electrical.Machines.Thermal.Constants.alpha20Zero,
    la(i(start=0, fixed=true)))
                     annotation (Placement(transformation(extent={{70,-10},{
          90,10}}, rotation=0)));
  Modelica.Mechanics.Rotational.Interfaces.Flange_b flange
    annotation (Placement(transformation(extent={{90,-10},{110,10}}, rotation=
         0)));
  Modelica.Blocks.Math.Feedback feedback
    annotation (Placement(transformation(extent={{-70,-10},{-50,10}},
        rotation=0)));
  Modelica.Blocks.Continuous.PI PI(T=T, k=k,
    initType=Modelica.Blocks.Types.Init.InitialState)
    annotation (Placement(transformation(extent={{-40,-10},{-20,10}},
        rotation=0)));
  Modelica.Blocks.Continuous.FirstOrder firstOrder(T=0.001, initType=Modelica.Blocks.Types.Init.InitialState)
    annotation (Placement(transformation(extent={{-8,-10},{12,10}}, rotation=
          0)));
  Modelica.Electrical.Analog.Sources.SignalVoltage signalVoltage
    annotation (Placement(transformation(
      origin={26,0},
      extent={{-10,10},{10,-10}},
      rotation=270)));
  Modelica.Electrical.Analog.Sensors.CurrentSensor currentSensor
    annotation (Placement(transformation(extent={{54,-30},{34,-10}}, rotation=
         0)));
  Modelica.Electrical.Analog.Basic.Ground ground
    annotation (Placement(transformation(extent={{50,-52},{70,-32}}, rotation=
         0)));
  ControlBus controlBus annotation (Placement(transformation(
        extent={{-20,-20},{20,20}},
        rotation=90,
        origin={-102,0})));
  Modelica.Mechanics.Rotational.Sensors.AngleSensor angleSensor
    annotation (Placement(transformation(
      origin={94,-38},
      extent={{-10,10},{10,-10}},
      rotation=270)));
  Modelica.Mechanics.Rotational.Sensors.SpeedSensor speedSensor annotation (
      Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={94,50})));
equation

  connect(DCPM.flange,   flange)
    annotation (Line(points={{90,0},{100,0}}, color={0,0,0}));
  connect(feedback.y, PI.u)
    annotation (Line(points={{-51,0},{-42,0}}, color={0,0,127}));
  connect(PI.y, firstOrder.u)
    annotation (Line(points={{-19,0},{-10,0}}, color={0,0,127}));
  connect(firstOrder.y, signalVoltage.v) annotation (Line(points={{13,0},{19,0},
          {19,1.28588e-015}},color={0,0,127}));
  connect(currentSensor.n, signalVoltage.n) annotation (Line(points={{34,-20},{
          26,-20},{26,-10}},color={0,0,255}));
  connect(signalVoltage.p, DCPM.pin_ap) annotation (Line(points={{26,10},{26,32},
          {86,32},{86,10}},   color={0,0,255}));
  connect(ground.p, currentSensor.p) annotation (Line(points={{60,-32},{60,-20},
          {54,-20}},    color={0,0,255}));
  connect(currentSensor.i, feedback.u2) annotation (Line(points={{44,-30},{44,
          -40},{-60,-40},{-60,-8}},
                                  color={0,0,127}));
  connect(currentSensor.p, DCPM.pin_an) annotation (Line(points={{54,-20},{60,
          -20},{60,10},{74,10}},
                               color={0,0,255}));
  connect(controlBus.referenceCurrent, feedback.u1) annotation (Line(
      points={{-102,0},{-68,0}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  connect(DCPM.flange, angleSensor.flange) annotation (Line(
      points={{90,0},{94,0},{94,-28}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(controlBus.motorAngle, angleSensor.phi) annotation (Line(
      points={{-102,0},{-98,0},{-98,-6},{-82,-6},{-82,-60},{94,-60},{94,-49}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  connect(speedSensor.flange, flange) annotation (Line(
      points={{94,40},{94,0},{100,0}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(controlBus.motorSpeed, speedSensor.w) annotation (Line(
      points={{-102,0},{-98,0},{-98,8},{-86,8},{-86,66},{94,66},{94,61}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false,extent={{-100,-100},
            {100,100}}),
                      graphics),
                       Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Rectangle(
          extent={{-100,50},{30,-50}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={255,0,0}),
        Polygon(
          points={{-100,-90},{-90,-90},{-60,-20},{-10,-20},{20,-90},{30,-90},{
              30,-100},{-100,-100},{-100,-90}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{30,10},{100,-10}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Text(
          extent={{-146,96},{148,66}},
          lineColor={0,0,255},
          textString="%name")}));
end ControlledMotorWithBus;


  model Controller1 "PI Geschwindigkeits-Regler (Aufgabe 3)"
  import SI = Modelica.SIunits;
    parameter Real ks "Verstaerkung vom PI Geschwindigkeitsregler";
    parameter SI.Time Ts "Zeitkonstante vom PI Geschwindigkeitsregler";
    parameter Real ratio=105 "Getriebe-Uebersetzung";

    Modelica.Blocks.Interfaces.RealInput refSpeed "Reference speed of load"
      annotation (Placement(
        transformation(extent={{-140,-20},{-100,20}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealOutput refCurrent
    "Reference current of motor"
      annotation (Placement(
        transformation(extent={{100,-10},{120,10}}, rotation=0)));
    Modelica.Blocks.Interfaces.RealInput motorSpeed "Actual speed of motor"
                                                      annotation (
      Placement(transformation(
        origin={0,-120},
        extent={{-20,-20},{20,20}},
        rotation=90)));
    Modelica.Blocks.Math.Feedback feedback
      annotation (Placement(transformation(extent={{-10,-10},{10,10}}, rotation=
           0)));
    Modelica.Blocks.Math.Gain gain(k=ratio)
      annotation (Placement(transformation(extent={{-50,-10},{-30,10}},
          rotation=0)));
    Modelica.Blocks.Continuous.PI PI(T=Ts, k=ks,
    initType=Modelica.Blocks.Types.Init.InitialState)
      annotation (Placement(transformation(extent={{30,-10},{50,10}}, rotation=
            0)));
  equation
    connect(gain.y,feedback.u1)             annotation (Line(points={{-29,0},{
          -8,0}}, color={0,0,127}));
    connect(feedback.y,PI.u)             annotation (Line(points={{9,0},{28,0}},
        color={0,0,127}));
    connect(PI.y,       refCurrent) annotation (Line(points={{51,0},{110,0}},
        color={0,0,127}));
    connect(gain.u,      refSpeed)
      annotation (Line(points={{-52,0},{-120,0}}, color={0,0,127}));
    connect(feedback.u2,      motorSpeed)
      annotation (Line(points={{0,-8},{0,-120}}, color={0,0,127}));
    annotation (
      Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics),
      Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={
        Rectangle(
          extent={{-100,-100},{100,100}},
          lineColor={0,0,0},
          pattern=LinePattern.Solid,
          lineThickness=0.25,
          fillColor={235,235,235},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-30,54},{30,24}},
          lineColor={0,0,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-30,40},{-60,50},{-60,30},{-30,40}},
          lineColor={0,0,255},
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid),
        Line(points={{-31,-41},{-78,-41},{-78,39},{-30,39}}),
        Rectangle(
          extent={{-30,-26},{30,-56}},
          lineColor={0,0,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{60,-32},{30,-42},{60,-52},{60,-32}},
          lineColor={0,0,255},
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid),
        Line(points={{30,39},{76,39},{76,-41},{30,-41}}),
        Text(extent={{-100,150},{100,110}}, textString="%name")}));
  end Controller1;


  model Controller2 "P-PI Kaskadenregler"
  import SI = Modelica.SIunits;
    parameter Real kp=1 "Verstaerkung vom Positionsregler";
    parameter Real ks=1 "Verstaerkung vom PI Geschwindigkeitsregler";
    parameter SI.Time Ts=1 "Zeitkonstante vom PI Geschwindigkeitsregler";
    parameter Real ratio=105 "Getriebe-Uebersetzung";

    Modelica.Blocks.Math.Gain gain1(k=ratio)
      annotation (Placement(transformation(extent={{-70,10},{-50,30}},
          rotation=0)));
    Modelica.Blocks.Continuous.PI PI(T=Ts, k=ks,
      initType=Modelica.Blocks.Types.Init.InitialState)
      annotation (Placement(transformation(extent={{66,-10},{86,10}}, rotation=
            0)));
    Modelica.Blocks.Math.Gain P(k=kp)   annotation (Placement(transformation(
          extent={{-2,-10},{18,10}},  rotation=0)));
    Modelica.Blocks.Math.Add3 add3(k3=-1) annotation (Placement(transformation(
          extent={{38,-10},{58,10}}, rotation=0)));
    Modelica.Blocks.Math.Gain gain2(k=ratio)
      annotation (Placement(transformation(extent={{-70,40},{-50,60}}, rotation=
           0)));
  ControlBus controlBus annotation (Placement(transformation(
        extent={{-20,-20},{20,20}},
        rotation=180,
        origin={0,-100})));
  Modelica.Blocks.Math.Add add(k2=-1)
    annotation (Placement(transformation(extent={{-34,-10},{-14,10}})));
  Modelica.Blocks.Math.Add add1(k1=-1)
    annotation (Placement(transformation(extent={{40,-40},{50,-30}})));
  equation
    connect(P.y,add3.u2)             annotation (Line(points={{19,0},{36,0}},
        color={0,0,127}));
    connect(add3.y,PI.u)             annotation (Line(points={{59,0},{64,0}}));
    connect(gain2.y,add3.u1)
      annotation (Line(points={{-49,50},{20,50},{20,8},{36,8}}, color={0,0,127}));
  connect(controlBus.referenceAngle, gain1.u) annotation (Line(
      points={{0,-100},{-4,-100},{-4,-96},{-86,-96},{-86,20},{-72,20}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  connect(controlBus.referenceSpeed, gain2.u) annotation (Line(
      points={{0,-100},{-99,-100},{-99,50},{-72,50}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  connect(controlBus.motorAngle, add.u2) annotation (Line(
      points={{0,-100},{0,-98},{-7,-98},{-7,-70},{-70,-70},{-70,-6},{-36,-6}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  connect(add.y, P.u) annotation (Line(
      points={{-13,0},{-4,0}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(gain1.y, add.u1) annotation (Line(
      points={{-49,20},{-46,20},{-46,6},{-36,6}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(PI.y, controlBus.referenceCurrent) annotation (Line(
      points={{87,0},{108,0},{108,-95},{5,-95},{5,-100},{0,-100}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
  connect(controlBus.motorSpeed, add3.u3) annotation (Line(
      points={{0,-100},{0,-70},{16,-70},{16,-8},{36,-8}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  connect(gain1.y, controlBus.referenceMotorAngle) annotation (Line(
      points={{-49,20},{113,20},{113,-97},{-5,-97},{-5,-101},{-4,-101},{-4,-103},
          {0,-103},{0,-100}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
  connect(gain2.y, controlBus.referenceMotorSpeed) annotation (Line(
      points={{-49,50},{117,50},{117,-100},{0,-100}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
  connect(add.y, controlBus.motorAngleError) annotation (Line(
      points={{-13,0},{-8,0},{-8,-50},{-3,-50},{-3,-98},{0,-98},{0,-100}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(add3.u1, add1.u2) annotation (Line(
      points={{36,8},{30,8},{30,-38},{39,-38}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(add1.u1, add3.u3) annotation (Line(
      points={{39,-32},{32,-32},{32,-8},{36,-8}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(add1.y, controlBus.motorSpeedError) annotation (Line(
      points={{50.5,-35},{75,-35},{75,-89},{4,-89},{4,-95},{0,-95},{0,-100}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
    annotation (
      Diagram(coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics),
      Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Rectangle(
          extent={{-100,-100},{100,100}},
          lineColor={0,0,0},
          pattern=LinePattern.Solid,
          lineThickness=0.25,
          fillColor={235,235,235},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-30,54},{30,24}},
          lineColor={0,0,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-30,40},{-60,50},{-60,30},{-30,40}},
          lineColor={0,0,255},
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid),
        Line(points={{-31,-41},{-78,-41},{-78,39},{-30,39}}),
        Rectangle(
          extent={{-30,-26},{30,-56}},
          lineColor={0,0,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{60,-32},{30,-42},{60,-52},{60,-32}},
          lineColor={0,0,255},
          fillColor={0,0,255},
          fillPattern=FillPattern.Solid),
        Line(points={{30,39},{76,39},{76,-41},{30,-41}}),
        Text(extent={{-100,150},{100,110}}, textString="%name")}));
  end Controller2;


  model Servo1 "Drehzahlgeregelter Motor mit Getriebe"
  import SI = Modelica.SIunits;
    parameter Real ks "Verstaerkung vom PI Geschwindigkeitsregler";
    parameter SI.Time Ts "Zeitkonstante vom PI Geschwindigkeitsregler";
    parameter Real km=30 "Verstaerkung vom PI Motorregler";
    parameter SI.Time Tm=0.005 "Zeitkonstante vom PI Motorregler";
    parameter Real ratio=105 "Getriebeuebersetzung";
    Modelica.Blocks.Interfaces.RealInput refSpeed "Reference speed of load"
      annotation (Placement(
        transformation(extent={{-140,-20},{-100,20}}, rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b
      annotation (Placement(
        transformation(extent={{90,-10},{110,10}}, rotation=0)));
    ServoSystem3.ControlledMotor motor(k=km, T=Tm)
                            annotation (Placement(transformation(extent={{-20,
            -10},{0,10}}, rotation=0)));
    Controller1 controller(
      ks=ks,
      Ts=Ts,
      ratio=ratio) annotation (Placement(transformation(extent={{-70,-10},{-50,
            10}}, rotation=0)));
    Modelica.Blocks.Math.Feedback speedError
      annotation (Placement(transformation(extent={{-40,40},{-20,60}}, rotation=
           0)));
    Modelica.Mechanics.Rotational.Sensors.SpeedSensor speedSensor2
      annotation (Placement(transformation(
        origin={70,20},
        extent={{-10,-10},{10,10}},
        rotation=90)));
    Modelica.Mechanics.Rotational.Sensors.SpeedSensor speedSensor1
      annotation (Placement(transformation(
        origin={10,-20},
        extent={{-10,-10},{10,10}},
        rotation=270)));
    Gear1 gear1(ratio=ratio) annotation (Placement(transformation(extent={{30,
            -10},{50,10}}, rotation=0)));
  equation
    connect(speedSensor2.w, speedError.u2)
      annotation (Line(points={{70,31},{70,34},{-30,34},{-30,42}}, color={0,0,
          127}));
    connect(refSpeed, controller.refSpeed)
      annotation (Line(points={{-120,0},{-72,0}}, color={0,0,127}));
    connect(controller.refCurrent, motor.refCurrent)
      annotation (Line(points={{-49,0},{-22,0}}, color={0,0,127}));
    connect(speedError.u1,      refSpeed)
      annotation (Line(points={{-38,50},{-90,50},{-90,0},{-120,0}}, color={0,0,
          127}));
    connect(motor.flange,speedSensor1.flange)    annotation (Line(points={{0,0},{
          10,0},{10,-10}},  color={0,0,0}));
    connect(speedSensor1.w, controller.motorSpeed) annotation (Line(points={{10,
          -31},{10,-40},{-60,-40},{-60,-12}}, color={0,0,127}));
    connect(motor.flange, gear1.flange_a)
      annotation (Line(points={{0,0},{30,0}}, color={0,0,0}));
    connect(gear1.flange_b, flange_b)
      annotation (Line(points={{50,0},{100,0}}, color={0,0,0}));
    connect(gear1.flange_b,speedSensor2.flange)    annotation (Line(points={{50,
          0},{70,0},{70,10}}, color={0,0,0}));
    annotation (
      Icon(coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Rectangle(
          extent={{-100,50},{30,-50}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={255,0,0}),
        Rectangle(
          extent={{30,10},{100,-10}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Polygon(
          points={{-100,-90},{-90,-90},{-60,-20},{-10,-20},{20,-90},{30,-90},{
              30,-100},{-100,-100},{-100,-90}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-101,126},{99,68}},
          textString="%name",
          lineColor={0,0,255}),
        Text(
          extent={{-100,-106},{100,-140}},
          lineColor={0,0,0},
          textString="ks=%ks, Ts=%Ts"),
        Text(
          extent={{-100,31},{30,1}},
          lineColor={0,0,0},
          textString="servo")}),
      Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics));
  end Servo1;


  model Servo2 "Positionsgeregelter Motor mit Getriebe"
    import SI = Modelica.SIunits;
    parameter Real kp "Verstaerkung vom Positionsregler";
    parameter Real ks = 0.8 "Verstaerkung vom PI Geschwindigkeitsregler";
    parameter SI.Time Ts = 0.1 "Zeitkonstante vom PI Geschwindigkeitsregler";
    parameter Real km=30 "Verstaerkung vom PI Motorregler";
    parameter SI.Time Tm=0.005 "Zeitkonstante vom PI Motorregler";
    parameter Real ratio=105 "Getriebeuebersetzung";

    Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b
      annotation (Placement(
        transformation(extent={{90,-10},{110,10}},  rotation=0)));
    ControlledMotorWithBus motor(      k=km, T=Tm)
                            annotation (Placement(transformation(extent={{0,-10},
              {20,10}},     rotation=0)));
    ServoSystem3.Gear1 gear(ratio=ratio)
                            annotation (Placement(transformation(extent={{32,-10},
              {52,10}},    rotation=0)));
    ServoSystem3.Controller2 controller(
      ks=ks,
      Ts=Ts,
      ratio=ratio,
      kp=kp) annotation (Placement(transformation(extent={{-52,-10},{-32,10}},
          rotation=0)));
    Modelica.Blocks.Math.Feedback speedError
    "y(redeclare type SignalType=SI.AngularVelocity)"
      annotation (Placement(transformation(extent={{20,80},{30,90}},  rotation=
            0)));
    Modelica.Mechanics.Rotational.Sensors.SpeedSensor speedSensor
      annotation (Placement(transformation(
        origin={86,24},
        extent={{-10,-10},{10,10}},
        rotation=90)));
    Modelica.Mechanics.Rotational.Sensors.AngleSensor angleSensor
      annotation (Placement(transformation(
        origin={62,24},
        extent={{10,10},{-10,-10}},
        rotation=270)));
    Modelica.Blocks.Math.Feedback angleError
      annotation (Placement(transformation(extent={{-15,55},{-5,65}},  rotation=
           0)));
    ControlBus controlBus annotation (Placement(transformation(
          extent={{-20,-20},{20,20}},
          rotation=90,
          origin={-100,0})));
  equation
    connect(speedSensor.w, speedError.u2)
      annotation (Line(points={{86,35},{86,60},{25,60},{25,81}},
                                                               color={0,0,127}));
    connect(angleSensor.flange, gear.flange_b)   annotation (Line(points={{62,14},
          {62,0},{52,0}},                     color={0,0,0}));
    connect(gear.flange_b, flange_b)
      annotation (Line(points={{52,0},{100,0}}, color={0,0,0}));
    connect(gear.flange_b, speedSensor.flange)
      annotation (Line(points={{52,0},{86,0},{86,14}}, color={0,0,0}));
    connect(motor.flange, gear.flange_a)
      annotation (Line(points={{20,0},{20,0},{32,0}},
                                                color={0,0,0}));
    connect(angleSensor.phi, angleError.u2)
      annotation (Line(points={{62,35},{62,42},{62,50},{-10,50},{-10,53},{-10,
          56}},                                                    color={0,0,
          127}));
    connect(controller.controlBus, controlBus) annotation (Line(
        points={{-42,-10},{-42,-20},{-90,-20},{-90,-6},{-96,-6},{-96,0},{-100,0}},
        color={255,170,85},
        smooth=Smooth.None,
        thickness=0.5));
    connect(controlBus, motor.controlBus) annotation (Line(
        points={{-100,0},{-96,0},{-96,-6},{-90,-6},{-90,-20},{-20,-20},{-20,0},
          {-0.2,0}},
        color={255,170,85},
        thickness=0.5,
        smooth=Smooth.None));
    connect(controlBus.referenceAngle, angleError.u1) annotation (Line(
        points={{-100,0},{-74,0},{-74,60},{-14,60}},
        color={0,0,127},
        smooth=Smooth.None), __Dymola_Text(
        string="%first",
        index=-1,
        extent={{-6,3},{-6,3}}));
    connect(controlBus.referenceSpeed, speedError.u1) annotation (Line(
        points={{-100,0},{-96,0},{-96,4},{-84,4},{-84,85},{21,85}},
        color={0,0,127},
        smooth=Smooth.None), __Dymola_Text(
        string="%first",
        index=-1,
        extent={{-6,3},{-6,3}}));

  connect(speedError.y, controlBus.speedError) annotation (Line(
      points={{29.5,85},{49,85},{49,96},{-88,96},{-88,8},{-100,8},{-100,0}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
  connect(angleError.y, controlBus.angleError) annotation (Line(
      points={{-5.5,60},{12,60},{12,70},{-78,70},{-78,2},{-98,2},{-98,0},{-100,
          0}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
    connect(controlBus.angle, angleSensor.phi) annotation (Line(
        points={{-100,0},{-97,0},{-97,-2},{-69,-2},{-69,50},{62,50},{62,35}},
        color={0,0,127},
        smooth=Smooth.None), __Dymola_Text(
        string="%first",
        index=-1,
        extent={{-6,3},{-6,3}}));
    connect(controlBus.speed, speedSensor.w) annotation (Line(
        points={{-100,0},{-98,0},{-98,3},{-81,3},{-81,75},{25,75},{25,60},{86,60},
            {86,35}},
        color={0,0,127},
        smooth=Smooth.None), __Dymola_Text(
        string="%first",
        index=-1,
        extent={{-6,3},{-6,3}}));
    annotation (
      Icon(coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Rectangle(
          extent={{-100,50},{30,-50}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={255,0,0}),
        Rectangle(
          extent={{30,10},{100,-10}},
          lineColor={0,0,0},
          fillPattern=FillPattern.HorizontalCylinder,
          fillColor={192,192,192}),
        Polygon(
          points={{-100,-90},{-90,-90},{-60,-20},{-10,-20},{20,-90},{30,-90},{
              30,-100},{-100,-100},{-100,-90}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-100,126},{100,68}},
          textString="%name",
          lineColor={0,0,255}),
        Text(
          extent={{-100,-106},{100,-140}},
          lineColor={0,0,0},
          textString="ks=%ks, Ts=%Ts"),
        Text(
          extent={{-100,30},{30,0}},
          lineColor={0,0,0},
          textString="servo")}),
      Diagram(coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics));
  end Servo2;


model Servo3
  extends Servo2;
  Modelica.Mechanics.Rotational.Components.InitializeFlange initializeFlange
    annotation (Placement(transformation(extent={{26,-70},{46,-50}})));

  Modelica.Blocks.Math.Gain gain(k=ratio)
    annotation (Placement(transformation(extent={{-16,-75},{-6,-65}})));
initial equation
  0 = gear.damper.w_rel;
  0 = der(gear.damper.w_rel);

equation
  connect(initializeFlange.flange, motor.flange) annotation (Line(
      points={{46,-60},{50,-60},{50,-30},{20,-30},{20,0}},
      color={0,0,0},
      smooth=Smooth.None));
  connect(controlBus.referenceMotorAngle, initializeFlange.phi_start)
    annotation (Line(
      points={{-100,0},{-100,-6},{-96,-6},{-96,-52},{24,-52}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  connect(controlBus.referenceMotorSpeed, initializeFlange.w_start) annotation (
     Line(
      points={{-100,0},{-98,0},{-98,-60},{24,-60}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  connect(gain.y, initializeFlange.a_start) annotation (Line(
      points={{-5.5,-70},{0,-70},{0,-68},{24,-68}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(controlBus.referenceAcceleration, gain.u) annotation (Line(
      points={{-100,0},{-100,-70},{-17,-70}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%first",
      index=-1,
      extent={{-6,3},{-6,3}}));
  annotation (Diagram(coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics), Icon(coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={1,1})));
end Servo3;


  model PathPlanning
  "Generierung von Sollwinkel (controlBus.referenceAngle) und Solldrehzahl (controlBus.referenceSpeed)"
    import SI = Modelica.SIunits;
    parameter SI.Angle angleBeg "Start angle";
    parameter SI.Angle angleEnd "End angle";
    parameter SI.AngularVelocity speedMax "Maximum axis speed";
    parameter SI.AngularAcceleration accMax "Maximum axis acceleration";
    parameter SI.Time startTime=0 "Start time of movement";

    Modelica.Blocks.Sources.KinematicPTP2 kinematicPTP2(
      startTime=startTime,
      q_begin={angleBeg},
      q_end={angleEnd},
      qd_max={speedMax},
      qdd_max={accMax}) annotation (Placement(transformation(extent={{-20,-10},
            {0,10}},      rotation=0)));
    ControlBus controlBus annotation (Placement(transformation(
        extent={{-20,-20},{20,20}},
        rotation=-90,
        origin={100,0})));
  equation
    connect(kinematicPTP2.q[1], controlBus.referenceAngle) annotation (Line(
      points={{1,8},{99,8},{99,1},{100,1},{100,0}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
    connect(kinematicPTP2.qd[1], controlBus.referenceSpeed) annotation (Line(
      points={{1,3},{99,3},{99,0},{100,0}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
  connect(kinematicPTP2.qdd[1], controlBus.referenceAcceleration) annotation (
      Line(
      points={{1,-3},{99,-3},{99,-2},{100,-2},{100,0}},
      color={0,0,127},
      smooth=Smooth.None), __Dymola_Text(
      string="%second",
      index=1,
      extent={{6,3},{6,3}}));
    annotation (
      Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(extent={{-119,178},{121,102}}, textString="%name"),
        Polygon(
          points={{-80,90},{-88,68},{-72,68},{-80,88},{-80,90}},
          lineColor={192,192,192},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Line(points={{-80,78},{-80,-82}}, color={192,192,192}),
        Line(points={{-90,0},{82,0}}, color={192,192,192}),
        Polygon(
          points={{90,0},{68,8},{68,-8},{90,0}},
          lineColor={192,192,192},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-42,55},{29,12}},
          lineColor={192,192,192},
          textString="w"),
        Line(points={{-80,0},{-41,69},{26,69},{58,0}}, color={0,0,0})}),
      Documentation(info="<HTML>
<p>
Given
</p>
<ul>
<li> start and end angle of load</li>
<li> maximum speed of load</li>
<li> maximum acceleration of load</li>
</ul>
<p>
this component computes the fastest movement under the
given constraints. This means, that:
</p>
<ol>
<li> The load accelerates with the maximum acceleration
     until the maximum speed is reached.</li>
<li> Drives with the maximum speed as long as possible.</li>
<li> Decelerates with the negative of the maximum acceleration
     until rest.</li>
</ol>
<p>
The acceleration, constant velocity and deceleration
phase are determined in such a way that the movement
starts form the start angle and ends at the end angle.
</p>
<p>
The output of this block are the reference angle and
reference speed as function of time.
</p>
</HTML>
"),   Diagram(coordinateSystem(
        preserveAspectRatio=true,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics));
  end PathPlanning;


  model OneArmRobot "Einfacher Roboter mit einem Arm (= einfaches Pendel)"
    import SI = Modelica.SIunits;
    parameter SI.Mass loadMass=100 "Load mass";
    Modelica.Mechanics.Rotational.Interfaces.Flange_a axis2
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}},
          rotation=0)));
    inner Modelica.Mechanics.MultiBody.World world
                                     annotation (Placement(transformation(
          extent={{-70,-80},{-50,-60}}, rotation=0)));
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute2(
      n={-1,0,0},
      cylinderLength=0.5,
      animation=false,
    useAxisFlange=true)
                       annotation (Placement(transformation(extent={{0,-20},{20,
            0}}, rotation=0)));
    Modelica.Mechanics.MultiBody.Visualizers.FixedShape body0(
      shapeType="cylinder",
      r_shape={0,-0.4,0},
      lengthDirection={0,1,0},
      widthDirection={1,0,0},
      length=0.225,
      width=0.3,
      height=0.3,
      color={0,0,255}) annotation (Placement(transformation(
        origin={20,-50},
        extent={{-10,-10},{10,10}},
        rotation=90)));
    Modelica.Mechanics.MultiBody.Parts.BodyShape body1(
      r={0,0,0},
      I_22=5,
      shapeType="box",
      r_shape={0,-0.175,0},
      lengthDirection={0,1,0},
      widthDirection={1,0,0},
      length=0.25,
      width=0.15,
      height=0.2,
      color={255,0,0},
      animateSphere=false,
    r_CM={0,0,0},
    m=1)                   annotation (Placement(transformation(
        origin={-10,-40},
        extent={{-10,-10},{10,10}},
        rotation=90)));
    Modelica.Mechanics.MultiBody.Parts.BodyShape body2(
      r={0,1,0},
      r_CM={0.15,0.5,0},
      m=75,
      I_11=4,
      I_22=1.5,
      I_33=4,
      shapeType="beam",
      r_shape={0.15,0,0},
      lengthDirection={0,1,0},
      widthDirection={0,0,1},
      width=0.2,
      height=0.15,
      color={255,180,0},
      animateSphere=false) annotation (Placement(transformation(
        origin={40,20},
        extent={{-10,-10},{10,10}},
        rotation=90)));
    Modelica.Mechanics.MultiBody.Parts.BodyShape load(
      shapeType="box",
      r={0,0,0},
      r_shape={0,0,0},
      lengthDirection={0,1,0},
      widthDirection={1,0,0},
      I_11=1,
      I_22=1,
      I_33=1,
      length=0.2,
      width=0.1,
      height=0.1,
      m=loadMass,
      color={255,0,0},
      animateSphere=false,
    r_CM={0,0,0})          annotation (Placement(transformation(
        origin={40,52},
        extent={{-10,-10},{10,10}},
        rotation=90)));
    Modelica.Mechanics.MultiBody.Parts.FixedRotation rotate(
                                                           rotationType=
          Modelica.Mechanics.MultiBody.Types.RotationTypes.
          PlanarRotationSequence, angles={0,-80,0})
      annotation (Placement(transformation(extent={{-40,-80},{-20,-60}},
          rotation=0)));
  equation
    connect(revolute2.axis, axis2)
                            annotation (Line(points={{10,0},{10,20},{-50,20},{
          -50,0},{-100,0}}, color={0,0,0}));
    connect(rotate.frame_a, world.frame_b)
      annotation (Line(points={{-40,-70},{-50,-70}}));
    connect(revolute2.frame_b, body2.frame_a)
                                    annotation (Line(
      points={{20,-10},{40,-10},{40,10}},
      color={0,0,0},
      thickness=0.5));
    connect(load.frame_a, body2.frame_b)
                                      annotation (Line(
      points={{40,42},{40,30}},
      color={0,0,0},
      thickness=0.5));
    connect(revolute2.frame_a, body1.frame_b)
                                    annotation (Line(
      points={{0,-10},{-10,-10},{-10,-30}},
      color={0,0,0},
      thickness=0.5));
    connect(rotate.frame_b, body1.frame_a)
                                        annotation (Line(
      points={{-20,-70},{-10,-70},{-10,-50}},
      color={0,0,0},
      thickness=0.5));
    connect(rotate.frame_b, body0.frame_a)
                                        annotation (Line(
      points={{-20,-70},{20,-70},{20,-60}},
      color={0,0,0},
      thickness=0.5));
    annotation (
      Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics={
        Rectangle(
          extent={{-100,100},{100,-101}},
          lineColor={0,0,0},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Text(extent={{-107,154},{114,101}}, textString="%name"),
        Rectangle(
          extent={{-64,-48},{-18,-86}},
          lineColor={0,0,0},
          fillColor={0,0,191},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-57,-28},{54,86},{75,66},{-35,-49},{-57,-28}},
          lineColor={0,0,0},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid)}),
      Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics));
  end OneArmRobot;


  model Aufgabe3_2 "Musterloesung von Aufgabe 3.2"
  import SI = Modelica.SIunits;
    extends Modelica.Icons.Example;
    parameter Real ks = 0.8 "Verstaerkung vom PI Geschwindigkeitsregler";
    parameter SI.Time Ts= 0.08 "Zeitkonstante vom PI Geschwindigkeitsregler";
    Servo1 servo1(ks=ks, Ts=Ts) annotation (Placement(transformation(extent={{
            -20,0},{0,20}}, rotation=0)));
    Servo1 servo2(ks=ks, Ts=Ts) annotation (Placement(transformation(extent={{
            -20,-40},{0,-20}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Inertia load1(
                                                J=170,
    phi(fixed=true, start=0),
    w(fixed=true, start=0))
      annotation (Placement(transformation(extent={{20,0},{40,20}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Inertia load2(
                                                J=50,
    phi(start=0, fixed=true),
    w(start=0, fixed=true))
      annotation (Placement(transformation(extent={{20,-40},{40,-20}}, rotation=
           0)));
    Modelica.Blocks.Sources.Ramp ramp(duration=1.17, height=2.95)
      annotation (Placement(transformation(extent={{-60,0},{-40,20}}, rotation=
            0)));
  equation
    connect(ramp.y, servo1.refSpeed) annotation (Line(points={{-39,10},{-22,10}},
        color={0,0,127}));
    connect(ramp.y, servo2.refSpeed) annotation (Line(points={{-39,10},{-30,10},
          {-30,-30},{-22,-30}}, color={0,0,127}));
    connect(servo1.flange_b, load1.flange_a)
      annotation (Line(points={{0,10},{20,10}}, color={0,0,0}));
    connect(servo2.flange_b, load2.flange_a)
      annotation (Line(points={{0,-30},{20,-30}}, color={0,0,0}));
    annotation (
      Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics),
      experiment(StopTime=2),
    __Dymola_Commands(file="Scripts/plot load.w, speedError.mos"
        "plot load.w, speedError", file="Scripts/plot current.mos"
        "plot current"));
  end Aufgabe3_2;


model Aufgabe3_3 "Musterloesung von Aufgabe 3.2"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Example;
  parameter Real ks = 0.8 "Verstaerkung vom PI Geschwindigkeitsregler";
  parameter SI.Time Ts= 0.08 "Zeitkonstante vom PI Geschwindigkeitsregler";
  Servo1 servo1(ks=ks, Ts=Ts) annotation (Placement(transformation(extent={{-20,
            0},{0,20}}, rotation=0)));
  Servo1 servo2(ks=ks, Ts=Ts) annotation (Placement(transformation(extent={{-20,
            -40},{0,-20}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.Inertia load1(
                                              J=170,
    phi(fixed=true, start=0),
    w(fixed=true, start=0))
    annotation (Placement(transformation(extent={{20,0},{40,20}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.Inertia load2(
                                              J=50,
    phi(start=0, fixed=true),
    w(start=0, fixed=true))
    annotation (Placement(transformation(extent={{20,-40},{40,-20}}, rotation=0)));
  Modelica.Blocks.Sources.Step step(height=2.95)
    annotation (Placement(transformation(extent={{-60,0},{-40,20}}, rotation=0)));
equation
  connect(servo1.flange_b, load1.flange_a)
    annotation (Line(points={{0,10},{20,10}}, color={0,0,0}));
  connect(servo2.flange_b, load2.flange_a)
    annotation (Line(points={{0,-30},{20,-30}}, color={0,0,0}));
  connect(step.y, servo1.refSpeed)
    annotation (Line(points={{-39,10},{-22,10}}, color={0,0,127}));
  connect(step.y, servo2.refSpeed) annotation (Line(points={{-39,10},{-32,10},{
          -32,-30},{-22,-30}}, color={0,0,127}));
  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics),
    experiment(StopTime=2));
end Aufgabe3_3;


  model Aufgabe4_1
  "Einstellung von Positionsregler fuer Servomotor mit Getriebe und Last (Aufgabe 4.1)"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Example;

    ServoSystem3.Servo2 servo(kp=5)
             annotation (Placement(transformation(extent={{0,0},{20,20}},
          rotation=0)));
    Modelica.Mechanics.Rotational.Components.Inertia load(
                                               J=170,
    phi(fixed=true, start=0),
    w(fixed=true, start=0))
      annotation (Placement(transformation(extent={{40,0},{60,20}}, rotation=0)));
    ServoSystem3.PathPlanning pathPlanning(
      startTime=0,
      speedMax=2.95,
      accMax=2.53,
      angleBeg=0,
      angleEnd=6.2831853071796)
                  annotation (Placement(transformation(extent={{-40,0},{
            -20,20}}, rotation=0)));
  equation
    connect(load.flange_a, servo.flange_b)
      annotation (Line(points={{40,10},{20,10}}, color={0,0,0}));
    connect(pathPlanning.controlBus, servo.controlBus) annotation (Line(
        points={{-20,10},{0,10}},
        color={255,170,85},
        smooth=Smooth.None,
        thickness=0.5));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
            -100},{100,100}}),
                        graphics),
      experiment(StopTime=4));
  end Aufgabe4_1;


  model Aufgabe4_2
  "Einstellung von Positionsregler fuer Servormotor mit Getriebe und Roboter (Aufgabe 4.2)"
    extends Modelica.Icons.Example;

    ServoSystem3.PathPlanning pathPlanning(
      speedMax=2.95,
      accMax=2.53,
      startTime=0,
    angleBeg=0,
    angleEnd=1.5707963267949)
                      annotation (Placement(transformation(extent={{-60,0},{-40,
            20}}, rotation=0)));
    ServoSystem3.Servo2 servo(kp=5, gear(damper2(phi_rel(fixed=true), w_rel(
            fixed=true))))
               annotation (Placement(transformation(extent={{-20,0},{0,20}},
          rotation=0)));
    ServoSystem3.OneArmRobot robot annotation (Placement(transformation(extent=
            {{20,0},{40,20}}, rotation=0)));
  equation
    connect(servo.flange_b, robot.axis2)
      annotation (Line(points={{0,10},{20,10}}, color={0,0,0}));
    connect(pathPlanning.controlBus, servo.controlBus) annotation (Line(
        points={{-40,10},{-20,10}},
        color={255,170,85},
        thickness=0.5,
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
            -100},{100,100}}),
                        graphics),
      experiment(StopTime=3));
  end Aufgabe4_2;


  model Aufgabe4_3a
  "Wegen falscher Anfangsbedingungen faehrt der Roboter sehr schlecht (Aufgabe 4.3a)"
    extends ServoSystem3.Aufgabe4_2(pathPlanning(angleBeg=1.5707963267949,
        angleEnd=0));
    annotation (experiment(StopTime=3));
  end Aufgabe4_3a;


  model Aufgabe4_3b
  "Anfangsbedingungen so gesetzt, dass der Roboter am Anfang beim Beginn der Sollbahn steht (Aufgabe 4.3b)"
    extends ServoSystem3.Aufgabe4_2(
      servo(gear(damper2(phi_rel(fixed=false),w_rel(fixed=false)))),
      pathPlanning(angleBeg=1.5707963267949, angleEnd=0),
      robot(revolute2(phi(
            fixed=true,
            start=pathPlanning.angleBeg), w(fixed=true))));
    annotation (experiment(StopTime=3));
  end Aufgabe4_3b;


  model Aufgabe4_4a
  "Wenn der Roboter 1 s am Anfang steht, gibt es unnoetige Vibrationen (Aufgabe 4.4a)"
    extends ServoSystem3.Aufgabe4_3b(pathPlanning(startTime=1));
    annotation (experiment(StopTime=4));
  end Aufgabe4_4a;


  model Aufgabe4_4b
  "Wichtig: Es muss Option 'Advanced.DefaultSteadyStateInitialization = true' gesetzt werden (Aufgabe 4.4 b)"

    extends Modelica.Icons.Example;

    ServoSystem3.PathPlanning pathPlanning(
      speedMax=2.95,
      accMax=2.53,
    angleEnd=0,
    angleBeg=1.5707963267949,
    startTime=1)      annotation (Placement(transformation(extent={{-60,0},{-40,
            20}}, rotation=0)));
    Servo3 servo(             kp=5, motor(DCPM(la(i(fixed=false)))),gear(damper(phi_rel(fixed=false),w_rel(fixed=false))))
               annotation (Placement(transformation(extent={{-20,0},{0,20}},
          rotation=0)));
    ServoSystem3.OneArmRobot robot annotation (Placement(transformation(extent=
            {{20,0},{40,20}}, rotation=0)));
  equation
    connect(servo.flange_b, robot.axis2)
      annotation (Line(points={{0,10},{20,10}}, color={0,0,0}));

  connect(pathPlanning.controlBus, servo.controlBus) annotation (Line(
      points={{-40,10},{-20,10}},
      color={255,170,85},
      smooth=Smooth.None,
      thickness=0.5));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
            -100},{100,100}}),
                        graphics={Text(
          extent={{-104,-26},{88,-34}},
          lineColor={0,0,255},
          textString="Advanced.DefaultSteadyStateInitialization = true"), Text(
          extent={{-102,-36},{90,-44}},
          lineColor={0,0,255},
          textString="required")}),
      experiment(StopTime=4),
      __Dymola_Commands(file="Scripts/Aufgabe4_4b.mos"
        "StationaryInitialization"));
  end Aufgabe4_4b;


  annotation (uses(Modelica(version="3.2")));
end ServoSystem3;

within ;
package ServoSystem1


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
            points={{-100,0},{-58,0},{-43,-30},{-13,30},{17,-30},{47,30},{62,0},
                {100,0}},
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
          Line(points={{-96,0},{-60,0},{-42,-32},{-12,30},{18,-30},{48,28},{62,
                0},{96,0}})}));
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
    Modelica.Mechanics.Rotational.Components.Damper damper1(
                                                 d=500,
    phi_rel(fixed=true),
    w_rel(fixed=true))
      annotation (Placement(transformation(extent={{20,-30},{40,-10}}, rotation=
           0)));
    Modelica.Mechanics.Rotational.Components.Fixed fixed
      annotation (Placement(transformation(extent={{-60,-49},{-40,-29}},
          rotation=0)));
    Modelica.Mechanics.Rotational.Components.Damper damper2(
                                                 d=100,
    phi_rel(fixed=true),
    w_rel(fixed=true))
      annotation (Placement(transformation(
        origin={-30,-20},
        extent={{-10,-10},{10,10}},
        rotation=270)));
  equation
    connect(gear.flange_a, flange_a)
      annotation (Line(points={{-60,0},{-100,0}}, color={0,0,0}));
    connect(gear.flange_b, nonlinearSpring.flange_a)
      annotation (Line(points={{-40,0},{0,0},{0,20},{20,20}}, color={0,0,0}));
    connect(gear.flange_b, damper1.flange_a)
      annotation (Line(points={{-40,0},{0,0},{0,-20},{20,-20}}, color={0,0,0}));
    connect(nonlinearSpring.flange_b, flange_b)
      annotation (Line(points={{40,20},{60,20},{60,0},{100,0}}, color={0,0,0}));
    connect(damper1.flange_b, flange_b)
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


  model ControlledMotor "Current controlled DC motor"
    parameter Real k=30 "Gain of PI current controller";
    parameter Modelica.SIunits.Time T=0.005
    "Time Constant of PI current controller (T>0 required)";
    Modelica.Electrical.Machines.BasicMachines.DCMachines.DC_PermanentMagnet
    DCPM(
      Ra=13.8,
      La=0.061,
      IaNominal=4.7,
      Jr =    0.0025,
      VaNominal=380,
    wNominal=(2960)*2*3.14159265358979323846/60,
    la(i(start=0, fixed=true)),
    TaOperational=293.15,
    TaNominal=293.15,
    TaRef=293.15,
    alpha20a=Modelica.Electrical.Machines.Thermal.Constants.alpha20Zero)
                       annotation (Placement(transformation(extent={{70,-8},{90,
            12}},    rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_b flange
      annotation (Placement(transformation(extent={{90,-10},{110,10}}, rotation=
           0)));
    Modelica.Blocks.Interfaces.RealInput refCurrent
    "Reference current of motor"
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
      annotation (Line(points={{90,2},{96,2},{96,0},{100,0}},
                                                color={0,0,0}));
    connect(feedback.u1, refCurrent)
      annotation (Line(points={{-88,0},{-120,0}}, color={0,0,127}));
    connect(feedback.y, PI.u)
      annotation (Line(points={{-71,0},{-62,0}}, color={0,0,127}));
    connect(PI.y, firstOrder.u)
      annotation (Line(points={{-39,0},{-22,0}}, color={0,0,127}));
    connect(firstOrder.y, signalVoltage.v) annotation (Line(points={{1,0},{13,0},
          {13,-1.28584e-015}}, color={0,0,127}));
    connect(currentSensor.n, signalVoltage.n) annotation (Line(points={{30,-20},
          {20,-20},{20,-10}}, color={0,0,255}));
    connect(signalVoltage.p, DCPM.pin_ap) annotation (Line(points={{20,10},{20,
          32},{86,32},{86,12}}, color={0,0,255}));
    connect(ground.p, currentSensor.p) annotation (Line(points={{60,-32},{60,
          -20},{50,-20}}, color={0,0,255}));
    connect(currentSensor.i, feedback.u2) annotation (Line(points={{40,-30},{40,
          -40},{-80,-40},{-80,-8}}, color={0,0,127}));
    connect(currentSensor.p, DCPM.pin_an) annotation (Line(points={{50,-20},{60,
          -20},{60,12},{74,12}}, color={0,0,255}));
    annotation (Diagram(graphics),
                         Icon(coordinateSystem(preserveAspectRatio=false,
            extent={{-100,-100},{100,100}}), graphics={
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
    ServoSystem1.ControlledMotor motor(k=km, T=Tm)
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
    connect(motor.flange,speedSensor1.flange)    annotation (Line(points={{0,0},
          {10,0},{10,-10}}, color={0,0,0}));
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
        preserveAspectRatio=false,
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
        Text(extent={{-100,126},{100,68}}, textString="%name"),
        Text(
          extent={{-100,-106},{100,-140}},
          lineColor={0,0,0},
          textString="ks=%ks, Ts=%Ts")}),
      Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={1,1}), graphics));
  end Servo1;


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
                                                J=170)
      annotation (Placement(transformation(extent={{20,0},{40,20}}, rotation=0)));
    Modelica.Mechanics.Rotational.Components.Inertia load2(
                                                J=50)
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
    __Dymola_Commands(file="Scripts/plot load.w, speedError2.mos"
        "plot load.w, speedError", file="Scripts/plot current2.mos"
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
                                              J=170)
    annotation (Placement(transformation(extent={{20,0},{40,20}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.Inertia load2(
                                              J=50)
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
    experiment(StopTime=2),
    __Dymola_Commands(file="Scripts/plot load.w, speedError3.mos"
        "plot load.w, speedError", file="Scripts/plot current3.mos"
        "plot current"));
end Aufgabe3_3;


  annotation (uses(Modelica(version="3.2")));
end ServoSystem1;

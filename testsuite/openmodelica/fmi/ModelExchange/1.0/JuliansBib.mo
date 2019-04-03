within ;
package JuliansBib
  model frictionRotational

    import SI = Modelica.SIunits;

   parameter SI.Torque Mdf = 8;  // Coulomb'sches Reibmoment
   parameter SI.Torque Msf = 10;  // Haftreibmoment
   SI.AngularVelocity Winkelgeschwindigkeit;
   SI.AngularAcceleration Winkelbeschleunigung;
   SI.Torque MR;  // Gegenmoment, falls anliegendes Moment kleiner ist als das Haftreibmoment -->keine Bew.
   Boolean Stiction;
   Boolean StartForw;
   Boolean Forward;
   Boolean StartBack;
   Boolean Backward;

   constant SI.Torque unitTorque = 1 annotation(HideResult=true);
    // kann man unten gekennzeichneten Grund für Fehlermeldung auch eleganter unterdrücken ?
   Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
  equation
   Winkelgeschwindigkeit = der(flange_a.phi);
   Winkelbeschleunigung = der(Winkelgeschwindigkeit);

   flange_a.tau =
   if Forward then Mdf else if Backward then -Mdf
   else if StartForw then Mdf
   else if StartBack then -Mdf
   else MR;

  0 = if Stiction or initial() then Winkelbeschleunigung
   else MR/unitTorque;   // Fehlermeldung wegen verschiedener Einheiten taucht hier auf !

    Forward = initial() and Winkelgeschwindigkeit > 0 or
  pre(StartForw) and Winkelgeschwindigkeit > 0 or
  pre(Forward) and not Winkelgeschwindigkeit <= 0;
  Backward = initial() and Winkelgeschwindigkeit < 0 or
  pre(StartBack) and Winkelgeschwindigkeit < 0 or
  pre(Backward) and not Winkelgeschwindigkeit >= 0;
  StartForw = pre(Stiction) and MR > Msf or
  pre(StartForw) and not
  (Winkelgeschwindigkeit>0 or Winkelbeschleunigung<=0 and not Winkelgeschwindigkeit>0);
  StartBack = pre(Stiction) and MR<- Msf or
  pre(StartBack) and not
  (Winkelgeschwindigkeit<0 or Winkelbeschleunigung>=0 and not Winkelgeschwindigkeit<0);
  Stiction = not (Forward or Backward or
  StartForw or StartBack);

  when Stiction and not initial() then
  reinit(Winkelgeschwindigkeit,0);
  end when;

    annotation (uses(Modelica(version="3.2.1")), Icon(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
          Ellipse(
            extent={{-60,60},{60,-60}},
            lineColor={0,128,255},
            fillPattern=FillPattern.Solid,
            fillColor={0,0,0}),
          Ellipse(
            extent={{-42,42},{42,-42}},
            lineColor={0,0,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-82,66},{16,76},{-32,82},{-26,72},{-28,60},{16,76},{-82,66}},
            lineColor={0,128,255},
            smooth=Smooth.None,
            fillColor={0,128,255},
            fillPattern=FillPattern.Solid)}),
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
              100}}), graphics));
  end frictionRotational;

  model lever_arm_simple_2D
    import SI = Modelica.SIunits;
    import Modelica.Constants.pi;
    parameter SI.Length Ls(displayUnit="mm") = 2;
    parameter SI.Length Lm(displayUnit="mm") = 3;
    parameter SI.Position ZylinderfusspunktX(displayUnit="mm") = 2;
    parameter SI.Position ZylinderfusspunktY(displayUnit="mm") = -1;
    parameter SI.Angle Startwinkel(displayUnit="deg") = 0;
    parameter SI.Mass Masse = 2500;
    parameter SI.Length ZylinderlaengeX(displayUnit="mm") = (Ls * cos(Startwinkel))-ZylinderfusspunktX;
     // soll nicht eingegeben werden! Aber Parameter da sonst Initialization problem bei Actuated Prismatic
    parameter SI.Length ZylinderlaengeY(displayUnit="mm") = (Ls * sin(Startwinkel))-ZylinderfusspunktY;
     // soll nicht eingegeben werden! Aber Parameter da sonst Initialization problem bei Actuated Prismatic
    parameter SI.Acceleration Erdbeschleunigung = 9.81;
    parameter SI.AngularVelocity Anfangsgeschwindigkeit(displayUnit="deg/s") = pi/18;
    parameter SI.Inertia Traegheitsmoment = 0.02;
    parameter SI.Inertia TraegheitsmomentHebelarm = 0.02;
    parameter Real viskoserReibbeiwert = 0.1;   // Einheit fehlt noch [Nms/Grad]
    parameter SI.Torque Mdf = 8;  // Coulomb'sches Reibmoment
    parameter SI.Torque Msf = 10;  // Haftreibmoment

    PlanarMechanicsStandard.Parts.Body body(      I=Traegheitsmoment, m=Masse,
      g={0,-Erdbeschleunigung})
      annotation (Placement(transformation(extent={{40,40},{60,60}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation(r={Ls,0})
      annotation (Placement(transformation(extent={{-20,10},{0,30}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation1(r={Lm,0})
      annotation (Placement(transformation(extent={{0,40},{20,60}})));

    PlanarMechanicsStandard.Joints.ActuatedRevolute actuatedRevolute(
      w_start=Anfangsgeschwindigkeit,
      phi_start=Startwinkel,
      initialize=false)
      annotation (Placement(transformation(extent={{-60,10},{-40,30}})));
    PlanarMechanicsStandard.Parts.Fixed fixed(r={0,0}) annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-80,20})));
   SI.AngularVelocity Winkelgeschwindigkeit = der(actuatedRevolute.flange_a.phi);
    SI.AngularAcceleration Winkelbeschleunigung = der(Winkelgeschwindigkeit);
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a
      "Anschluss im Festlager z.B. für einen rotatorischen Antriebsmotor"
      annotation (Placement(transformation(extent={{-110,-30},{-90,-10}})));
    Modelica.Mechanics.Rotational.Components.Inertia inertia(J=
          TraegheitsmomentHebelarm)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-50,50})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a1 annotation (
        Placement(transformation(extent={{0,-10},{20,10}}), iconTransformation(
            extent={{0,-10},{20,10}})));
    Ausleger ausleger1 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={30,20})));
    Modelica.Blocks.Interfaces.RealOutput beta annotation (Placement(
          transformation(extent={{0,-60},{20,-40}}), iconTransformation(extent=
              {{0,-60},{20,-40}})));
  equation
    connect(fixedTranslation1.frame_b, body.frame_a) annotation (Line(
        points={{20,50},{40,50}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(actuatedRevolute.frame_b, fixedTranslation.frame_a) annotation (Line(
        points={{-40,20},{-20,20}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixed.frame_a, actuatedRevolute.frame_a) annotation (Line(
        points={{-70,20},{-60,20}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(flange_a, actuatedRevolute.flange_a) annotation (Line(
        points={{-100,-20},{-92,-20},{-92,40},{-70,40},{-70,30},{-50,30}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(inertia.flange_a, actuatedRevolute.flange_a) annotation (Line(
        points={{-50,40},{-50,30}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(fixedTranslation1.frame_a, actuatedRevolute.frame_b) annotation (
        Line(
        points={{0,50},{-30,50},{-30,20},{-40,20}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation.frame_b, ausleger1.frame_a) annotation (Line(
        points={{0,20},{23,20}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(flange_a1, ausleger1.flange_a) annotation (Line(
        points={{10,0},{29,0},{29,17}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(ausleger1.beta, beta) annotation (Line(
        points={{29,25},{29,30},{48,30},{48,-30},{-10,-30},{-10,-50},{10,-50}},

        color={0,0,127},
        smooth=Smooth.None));
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=90,
          origin={68,-16})),
                Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}), graphics),
      Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
          graphics={
          Polygon(
            points={{-76,-20},{-70,-26},{40,44},{34,52},{-76,-20}},
            lineColor={0,0,255},
            smooth=Smooth.None,
            fillColor={0,128,255},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{30,86},{82,34}},
            lineColor={0,0,255},
            fillColor={0,128,255},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-16,22},{-6,12}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-14,12},{-8,-16}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-18,-16},{-4,-60}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{24,78},{88,46}},
            lineColor={0,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid,
            textString="m",
            textStyle={TextStyle.Bold}),
          Line(
            points={{-18,-16},{-4,-16},{-4,-60},{-18,-60},{-18,-16},{-14,-16},{
                -14,14},{-8,12}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-8,-16},{-8,16},{-8,16}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-18,-60},{-32,-80},{10,-80},{-4,-60}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-24,-80},{-32,-88}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-10,-80},{-18,-88}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{4,-80},{-4,-88}},
            color={0,0,0},
            smooth=Smooth.None),
          Ellipse(
            extent={{-78,-18},{-68,-28}},
            lineColor={0,0,255},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-68,-22},{-60,-40},{-86,-40},{-78,-22},{-68,-22}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-64,-40},{-70,-46},{-64,-40}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-72,-40},{-78,-46}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-80,-40},{-86,-46}},
            color={0,0,0},
            smooth=Smooth.None),
          Ellipse(
            extent={{-18,-54},{-4,-68}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid)}));
  end lever_arm_simple_2D;

  model Test_Reibung

    import SI = Modelica.SIunits;

   SI.Torque MR = 0;

    Modelica.Mechanics.Rotational.Components.Inertia inertia(
      phi(start=0),
      w(start=0),
      a(start=0),
      J=100)
      annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
    Modelica.Mechanics.Rotational.Sources.Torque torque
      annotation (Placement(transformation(extent={{-70,-10},{-50,10}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation(r={3,0})
      annotation (Placement(transformation(extent={{50,-40},{70,-20}})));
    PlanarMechanicsStandard.Joints.ActuatedRevolute actuatedRevolute(
      initialize=true,
      w_start=0,
      phi_start=5.7595865315813)
      annotation (Placement(transformation(extent={{20,-40},{40,-20}})));
    PlanarMechanicsStandard.Parts.Fixed fixed annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={0,-30})));
    PlanarMechanicsStandard.Parts.Body body(
      g={0,-9.81},
      m=10,
      I=10) annotation (Placement(transformation(extent={{80,-40},{100,-20}})));
    Modelica.Blocks.Sources.RealExpression realExpression(y=MR)
      annotation (Placement(transformation(extent={{-100,-10},{-80,10}})));
    frictionRotational frictionRotational1
      annotation (Placement(transformation(extent={{30,-10},{50,10}})));
  equation
    connect(torque.flange, inertia.flange_a) annotation (Line(
        points={{-50,0},{-40,0}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(actuatedRevolute.frame_b,fixedTranslation. frame_a) annotation (Line(
        points={{40,-30},{50,-30}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixed.frame_a, actuatedRevolute.frame_a) annotation (Line(
        points={{10,-30},{20,-30}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation.frame_b, body.frame_a) annotation (Line(
        points={{70,-30},{80,-30}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(realExpression.y, torque.tau) annotation (Line(
        points={{-79,0},{-72,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(inertia.flange_b, frictionRotational1.flange_a) annotation (Line(
        points={{-20,0},{30,0}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(frictionRotational1.flange_a, actuatedRevolute.flange_a) annotation (
       Line(
        points={{30,0},{10,0},{10,-20},{30,-20}},
        color={0,0,0},
        smooth=Smooth.None));
    annotation (uses(Modelica(version="3.2.1")), Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
  end Test_Reibung;

  model lever_arm_advanced_2D
    import SI = Modelica.SIunits;
    import Modelica.Constants.pi;
  parameter SI.Acceleration Erdbeschleunigung = 9.81;
  parameter SI.Angle Drehwinkel(displayUnit="deg") = 0;
  parameter SI.AngularVelocity Anfangsgeschwindigkeit(displayUnit="deg/s") = pi/18;
  parameter Real viskoserReibbeiwert = 0.1;   // Einheit fehlt noch [Nms/Grad]
  parameter SI.Inertia TraegheitsmomentHebelarm = 1;
  parameter SI.Torque Mdf = 8;  // Coulomb'sches Reibmoment
  parameter SI.Torque Msf = 10;  // Haftreibmoment
  SI.AngularVelocity Winkelgeschwindigkeit = der(flange_a.phi);
  SI.AngularAcceleration Winkelbeschleunigung = der(Winkelgeschwindigkeit);
  parameter SI.Mass Masse1 = 850;
  parameter SI.Mass Masse2 = 750;
  parameter SI.Position[2] FZF1 = {-1,-1};
  parameter SI.Position[2] FZF2 = {1,-1};
  parameter SI.Position[2] FZA1 = {-1,0};
  parameter SI.Position[2] FZA2 = {1,0};
  parameter SI.Position[2] F1 = {-1,1};
  parameter SI.Position[2] F2 = {1,1};
  parameter SI.Position[2] m1 = {-2,0};
  parameter SI.Position[2] m2 = {2,0};
  parameter SI.Position[2] L = {0,0};
  parameter SI.Force Fx1 = 10;
  parameter SI.Force Fy1 = 10;
  parameter SI.Force Fx2 = 10;
  parameter SI.Force Fy2 = 10;

    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation(r={abs(FZA2
          [1] - L[1]),abs(FZA2[2] - L[2])})
      annotation (Placement(transformation(extent={{20,-30},{40,-10}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation1(r={abs(L[1]
           - FZA1[1]),abs(L[2] - FZA1[2])})
      annotation (Placement(transformation(extent={{-50,-30},{-30,-10}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation2(r={abs(m2[
          1] - L[1]),abs(m2[2] - L[2])})
      annotation (Placement(transformation(extent={{20,-10},{40,10}})));
    PlanarMechanicsStandard.Parts.Body body(      I=10,
      g={0,-Erdbeschleunigung},
      m=Masse1)                                         annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-90,0})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation5(r={abs(L[1]
           - m1[1]),abs(L[2] - m1[2])})
      annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
    PlanarMechanicsStandard.Parts.Body body1(      I=10,
      g={0,-Erdbeschleunigung},
      m=Masse2)                                          annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={70,0})));
    PlanarMechanicsStandard.Parts.Fixed fixed(r={L[1],L[2]})
                                                       annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-10,-80})));
    PlanarMechanicsStandard.Joints.ActuatedRevolute actuatedRevolute(
      w_start=Anfangsgeschwindigkeit,
      phi_start=Drehwinkel,
      initialize=false)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-10,-50})));
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a
      "Anschluss im Festlager z.B. für einen rotatorischen Antriebsmotor"
      annotation (Placement(transformation(extent={{-10,-40},{10,-20}}),
          iconTransformation(extent={{-10,-40},{10,-20}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_x3 annotation (
        Placement(transformation(extent={{-40,90},{-20,110}}), iconTransformation(
            extent={{-60,90},{-40,110}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_x4 annotation (
        Placement(transformation(extent={{20,90},{40,110}}),   iconTransformation(
            extent={{10,90},{30,110}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_2
      "mechanischer Anschluss 2 zur Krafteinleitung, z.B. für einen Zylinder"
      annotation (Placement(transformation(extent={{90,-40},{110,-20}}),
          iconTransformation(extent={{90,-10},{110,10}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_1
      "mechanischer Anschluss 2 zur Krafteinleitung, z.B. für einen Zylinder"
      annotation (Placement(transformation(extent={{-110,-40},{-90,-20}}),
          iconTransformation(extent={{-90,-10},{-110,10}})));
    Ausleger ausleger annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-60,-50})));
    Ausleger ausleger1 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={56,-48})));
    PlanarMechanicsStandard.Parts.FixedTranslation KraftF1(r={abs(FZF1[1] - L[1]),
          abs(FZF1[2] - L[2])})          annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-30,20})));
    PlanarMechanicsStandard.Parts.FixedTranslation KraftF2(r={abs(FZF2[1] - L[1]),
          abs(FZF2[2] - L[2])})          annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={10,20})));
    PlanarMechanicsStandard.Forces.AbsoluteForce absoluteForce annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-70,20})));
    PlanarMechanicsStandard.Forces.AbsoluteForce absoluteForce1 annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={50,20})));
    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor
      annotation (Placement(transformation(extent={{-100,80},{-80,100}})));
    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor1
      annotation (Placement(transformation(extent={{-50,74},{-30,94}})));
    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor2
      annotation (Placement(transformation(extent={{0,80},{20,100}})));
    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor3
      annotation (Placement(transformation(extent={{50,74},{70,94}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_y3 annotation (
        Placement(transformation(extent={{-20,90},{0,110}}),   iconTransformation(
            extent={{-30,90},{-10,110}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_y4 annotation (
        Placement(transformation(extent={{40,90},{60,110}}),   iconTransformation(
            extent={{40,90},{60,110}})));

    Modelica.Blocks.Interfaces.RealOutput y annotation (Placement(transformation(
            extent={{90,-60},{110,-40}}), iconTransformation(extent={{90,-60},{110,
              -40}})));
    Modelica.Blocks.Interfaces.RealOutput y1 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-100,-50}), iconTransformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-100,-50})));
    Modelica.Mechanics.Translational.Sources.Position position annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-70,74})));
    Modelica.Blocks.Sources.RealExpression realExpression(y=KraftF1.frame_a.x)
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-70,50})));
    Modelica.Mechanics.Translational.Sources.Position position1 annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={80,74})));
    Modelica.Blocks.Sources.RealExpression realExpression1(y=KraftF2.frame_a.y)
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={80,50})));
    Modelica.Mechanics.Translational.Sources.Position position2 annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-20,74})));
    Modelica.Blocks.Sources.RealExpression realExpression2(y=KraftF1.frame_a.y)
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-20,50})));
    Modelica.Mechanics.Translational.Sources.Position position3 annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={30,74})));
    Modelica.Blocks.Sources.RealExpression realExpression3(y=KraftF2.frame_a.x)
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={30,50})));
    PlanarMechanicsStandard.Interfaces.Frame_a frame_a
      annotation (Placement(transformation(extent={{90,0},{110,20}})));
  equation

    connect(actuatedRevolute.frame_b, fixed.frame_a) annotation (Line(
        points={{-10,-60},{-10,-70}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation1.frame_b, actuatedRevolute.frame_a) annotation (Line(
        points={{-30,-20},{-10,-20},{-10,-40}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation5.frame_b, actuatedRevolute.frame_a) annotation (Line(
        points={{-40,0},{-22,0},{-22,-20},{-10,-20},{-10,-40}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation.frame_a, actuatedRevolute.frame_a) annotation (Line(
        points={{20,-20},{-10,-20},{-10,-40}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation2.frame_a, actuatedRevolute.frame_a) annotation (Line(
        points={{20,0},{2,0},{2,-20},{-10,-20},{-10,-40}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(flange_a, actuatedRevolute.flange_a)  annotation (Line(
        points={{0,-30},{0,-50}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(flange_a, flange_a) annotation (Line(
        points={{0,-30},{0,-30}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(flange_x3, flange_x3) annotation (Line(
        points={{-30,100},{-30,100}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(ausleger.frame_a, fixedTranslation1.frame_a) annotation (Line(
        points={{-60,-43},{-60,-20},{-50,-20}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(flange_1, ausleger.flange_a) annotation (Line(
        points={{-100,-30},{-70,-30},{-70,-49},{-63,-49}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(fixedTranslation.frame_b, ausleger1.frame_a) annotation (Line(
        points={{40,-20},{56,-20},{56,-41}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(KraftF1.frame_b, actuatedRevolute.frame_a)           annotation (Line(
        points={{-20,20},{-16,20},{-16,-20},{-10,-20},{-10,-40}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(absoluteForce.frame_b, KraftF1.frame_a)           annotation (Line(
        points={{-60,20},{-40,20}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(absoluteForce1.frame_b, KraftF2.frame_a)           annotation (Line(
        points={{40,20},{20,20}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(KraftF2.frame_b, actuatedRevolute.frame_a)           annotation (Line(
        points={{0,20},{-4,20},{-4,-20},{-10,-20},{-10,-40}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(body.frame_a, fixedTranslation5.frame_a) annotation (Line(
        points={{-80,0},{-60,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation2.frame_b, body1.frame_a) annotation (Line(
        points={{40,0},{60,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(forceSensor.flange_a, flange_x3)
                                            annotation (Line(
        points={{-100,90},{-100,100},{-30,100}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_x4, forceSensor2.flange_a) annotation (Line(
        points={{30,100},{0,100},{0,90}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_y4, forceSensor3.flange_a) annotation (Line(
        points={{50,100},{50,84}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(forceSensor.f, absoluteForce.u[1]) annotation (Line(
        points={{-98,79},{-98,19},{-82,19}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(forceSensor1.f, absoluteForce.u[2]) annotation (Line(
        points={{-48,73},{-48,30},{-90,30},{-90,21},{-82,21}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(forceSensor3.f, absoluteForce1.u[2]) annotation (Line(
        points={{52,73},{52,36},{80,36},{80,19},{62,19}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(forceSensor2.f, absoluteForce1.u[1]) annotation (Line(
        points={{2,79},{2,32},{76,32},{76,21},{62,21}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(ausleger.beta, y1) annotation (Line(
        points={{-55,-49},{-50,-49},{-50,-70},{-80,-70},{-80,-50},{-100,-50}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(ausleger1.flange_a, flange_2) annotation (Line(
        points={{53,-47},{50,-47},{50,-70},{80,-70},{80,-30},{100,-30}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(ausleger1.beta, y) annotation (Line(
        points={{61,-47},{76.5,-47},{76.5,-50},{100,-50}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(realExpression1.y, position1.s_ref) annotation (Line(
        points={{80,61},{80,62}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(position1.flange, forceSensor3.flange_b) annotation (Line(
        points={{80,84},{70,84}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(realExpression2.y, position2.s_ref) annotation (Line(
        points={{-20,61},{-20,62}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(position2.flange, forceSensor1.flange_b) annotation (Line(
        points={{-20,84},{-30,84}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(realExpression3.y, position3.s_ref) annotation (Line(
        points={{30,61},{30,62}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(position3.flange, forceSensor2.flange_b) annotation (Line(
        points={{30,84},{30,90},{20,90}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(realExpression.y, position.s_ref) annotation (Line(
        points={{-70,61},{-70,62}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(forceSensor.flange_b, position.flange) annotation (Line(
        points={{-80,90},{-70,90},{-70,84}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_y3, flange_y3) annotation (Line(
        points={{-10,100},{-10,100}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_y3, forceSensor1.flange_a) annotation (Line(
        points={{-10,100},{-10,94},{-54,94},{-54,84},{-50,84}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(fixedTranslation2.frame_b, frame_a) annotation (Line(
        points={{40,0},{40,10},{100,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}), graphics), uses(Modelica(version="3.2.1")),
      Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
          graphics={
          Ellipse(
            extent={{-10,44},{-2,36}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-10,40},{-16,30},{4,30},{-2,40},{-6,40}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-78,24},{78,66},{80,60},{-76,18},{-78,24},{-76,18}},
            color={0,0,0},
            smooth=Smooth.None),
          Ellipse(
            extent={{94,74},{76,56}},
            lineColor={0,128,255},
            fillColor={0,128,255},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-76,28},{-94,10}},
            lineColor={0,128,255},
            fillColor={0,128,255},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-6,30},{-10,26},{-10,26}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-12,30},{-16,26},{-16,26}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{0,30},{-4,26},{0,30}},
            color={0,0,0},
            smooth=Smooth.None),
          Rectangle(
            extent={{-3,14},{3,-14}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid,
            origin={53,40},
            rotation=360),
          Rectangle(
            extent={{-7,22},{7,-22}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid,
            origin={53,4},
            rotation=360),
          Line(
            points={{-7,7},{7,7},{7,-37},{-7,-37},{-7,7},{-3,7},{-3,37},{3,35}},
            color={0,0,0},
            smooth=Smooth.None,
            origin={53,19},
            rotation=360),
          Line(
            points={{0,-16},{0,16},{0,16}},
            color={0,0,0},
            smooth=Smooth.None,
            origin={56,42},
            rotation=360),
          Ellipse(
            extent={{-7,7},{7,-7}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid,
            origin={53,-19},
            rotation=360),
          Rectangle(
            extent={{-56,24},{-50,-4}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-60,-4},{-46,-48}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-60,-4},{-46,-4},{-46,-48},{-60,-48},{-60,-4},{-56,-4},{-56,26},
                {-50,24}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-50,-4},{-50,28},{-50,28}},
            color={0,0,0},
            smooth=Smooth.None),
          Ellipse(
            extent={{-60,-42},{-46,-56}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-60,-48},{-74,-68},{-32,-68},{-46,-48}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-66,-68},{-74,-76}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-52,-68},{-60,-76}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-38,-68},{-46,-76}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{46,-18},{32,-38},{74,-38},{60,-18}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{40,-38},{32,-46}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{54,-38},{46,-46}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{68,-38},{60,-46}},
            color={0,0,0},
            smooth=Smooth.None),
          Ellipse(
            extent={{-58,30},{-50,22}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{50,60},{58,52}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-30,38},{-36,52},{-24,52},{-24,52},{-30,38}},
            lineColor={255,0,0},
            smooth=Smooth.None,
            fillPattern=FillPattern.Solid,
            fillColor={255,0,0}),
          Polygon(
            points={{30,54},{24,68},{36,68},{36,68},{30,54}},
            lineColor={255,0,0},
            smooth=Smooth.None,
            fillPattern=FillPattern.Solid,
            fillColor={255,0,0}),
          Rectangle(
            extent={{-32,50},{-28,74}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{28,66},{32,88}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-34,38},{-26,30}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{26,54},{34,46}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid)}));
  end lever_arm_advanced_2D;

  model Test_Hebelarm_komplex

  Real KraftFX1 = 10;
  Real KraftFY1 = 10;
  Real KraftFX2 = 10;
  Real KraftFY2 = 10;

    lever_arm_advanced_2D lever_arm_advanced_2D1(
      FZF1={4,-1},
      FZF2={-1,2},
      m1={3,4},
      m2={-1,-1},
      L={2,1},
      F1={2,-1},
      F2={1,2},
      FZA1={0,0.5},
      FZA2={-4,-2})
      annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
    inner DC_HydrauLib.Fluids.FluidConfiguration fluidconfiguration
      annotation (Placement(transformation(extent={{80,-100},{100,-80}})));
    Modelica.Mechanics.Translational.Sources.ConstantForce FZ1(f_constant=100)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-50,0})));
    Modelica.Mechanics.Translational.Sources.ConstantForce FZ2(f_constant=10)
                         annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={50,0})));
    Modelica.Mechanics.Rotational.Sources.ConstantTorque constantTorque(
        tau_constant=0)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-30,-30})));
    Modelica.Mechanics.Translational.Sources.Force force annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-30,50})));
    Modelica.Blocks.Sources.RealExpression realExpression(y=KraftFX1)
      annotation (Placement(transformation(extent={{-64,40},{-44,60}})));
    Modelica.Mechanics.Translational.Sources.Force force1
                                                         annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={30,80})));
    Modelica.Blocks.Sources.RealExpression realExpression1(y=KraftFX2)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=180,
          origin={54,80})));
    Modelica.Mechanics.Translational.Sources.Force force2
                                                         annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-30,80})));
    Modelica.Blocks.Sources.RealExpression realExpression2(y=KraftFY1)
      annotation (Placement(transformation(extent={{-64,70},{-44,90}})));
    Modelica.Mechanics.Translational.Sources.Force force3
                                                         annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={30,50})));
    Modelica.Blocks.Sources.RealExpression realExpression3(y=KraftFY2)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=180,
          origin={54,50})));
  equation
    connect(constantTorque.flange, lever_arm_advanced_2D1.flange_a) annotation (
       Line(
        points={{-20,-30},{0,-30},{0,-3}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(realExpression.y,force. f) annotation (Line(
        points={{-43,50},{-42,50}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(force1.f,realExpression1. y) annotation (Line(
        points={{42,80},{43,80}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(lever_arm_advanced_2D1.flange_2, FZ2.flange)            annotation (
        Line(
        points={{10,0},{14,0},{14,1.33227e-015},{40,1.33227e-015}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(lever_arm_advanced_2D1.flange_1, FZ1.flange)           annotation (
        Line(
        points={{-10,0},{-25,0},{-25,0},{-40,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(realExpression2.y, force2.f)
                                       annotation (Line(
        points={{-43,80},{-42,80}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(force3.f,realExpression3. y) annotation (Line(
        points={{42,50},{43,50}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(force1.flange, lever_arm_advanced_2D1.flange_x4) annotation (Line(
        points={{20,80},{2,80},{2,10}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(force.flange, lever_arm_advanced_2D1.flange_x3) annotation (Line(
        points={{-20,50},{-5,50},{-5,10}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(force2.flange, lever_arm_advanced_2D1.flange_y3) annotation (Line(
        points={{-20,80},{-2,80},{-2,10}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(force3.flange, lever_arm_advanced_2D1.flange_y4) annotation (Line(
        points={{20,50},{5,50},{5,10}},
        color={0,127,0},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}), graphics), Icon(coordinateSystem(extent={{-100,
              -100},{100,100}})));
  end Test_Hebelarm_komplex;

  model Ausleger_xy
    import SI = Modelica.SIunits;
  parameter SI.Position[2] Zylinderlaenge = {1,1};
  parameter SI.Position[2] Lagerpunkt = {2,2};
    PlanarMechanicsStandard.Joints.ActuatedPrismatic actuatedPrismatic1(
      s_start=0,
      v_start=0,
      r={Zylinderlaenge[1],Zylinderlaenge[2]})
                 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={10,0})));
    PlanarMechanicsStandard.Joints.Revolute revolute1
      annotation (Placement(transformation(extent={{30,-10},{50,10}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation(r={
          Zylinderlaenge[1],Zylinderlaenge[2]})
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-20,0})));
    PlanarMechanicsStandard.Interfaces.Frame_a frame_a
      annotation (Placement(transformation(extent={{60,-10},{80,10}})));
    Kraftzerlegung kraftzerlegung
      annotation (Placement(transformation(extent={{0,60},{20,80}})));
    Modelica.Mechanics.Translational.Sources.Force force annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={10,30})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a
      annotation (Placement(transformation(extent={{-40,60},{-20,80}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a1
      annotation (Placement(transformation(extent={{40,60},{60,80}})));
  equation
    connect(actuatedPrismatic1.frame_a, fixedTranslation.frame_b) annotation (
        Line(
        points={{0,0},{-10,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(actuatedPrismatic1.frame_b,revolute1. frame_a) annotation (Line(
        points={{20,0},{30,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(revolute1.frame_b, frame_a) annotation (Line(
        points={{50,0},{70,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(kraftzerlegung.y, force.f) annotation (Line(
        points={{10,60},{10,42}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(force.flange, actuatedPrismatic1.flange_a) annotation (Line(
        points={{10,20},{10,9}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_a, kraftzerlegung.flange_x) annotation (Line(
        points={{-30,70},{0,70}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(kraftzerlegung.flange_y, flange_a1) annotation (Line(
        points={{20,70},{34,70},{34,70},{50,70}},
        color={0,127,0},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}), graphics), Icon(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
          graphics={
          Line(
            points={{-50,10},{-90,30},{-90,-30},{-50,-10},{-50,-2}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-100,30},{-90,20},{-90,10},{-90,0},{-100,10},{-90,0},{-90,
                -20},{-100,-10}},
            color={0,0,0},
            smooth=Smooth.None),
          Rectangle(
            extent={{-50,10},{0,-10}},
            lineColor={0,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-60,10},{-40,-10}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{0,4},{42,-4}},
            lineColor={0,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{40,10},{60,-10}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid)}));
  end Ausleger_xy;

  model Test_Hebelarm_einfach
    Modelica.Mechanics.Rotational.Sources.ConstantTorque constantTorque(
        tau_constant=100)
      annotation (Placement(transformation(extent={{-40,-12},{-20,8}})));
    inner DC_HydrauLib.Fluids.FluidConfiguration fluidconfiguration
      annotation (Placement(transformation(extent={{80,-100},{100,-80}})));
    lever_arm_simple_2D lever_arm_simple_2D1(
      Traegheitsmoment=0.02,
      TraegheitsmomentHebelarm=0.02,
      Anfangsgeschwindigkeit=0,
      Masse=1000)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
    Modelica.Mechanics.Translational.Sources.ConstantForce constantForce(
        f_constant=10000) annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={30,0})));
  equation
    connect(constantTorque.flange, lever_arm_simple_2D1.flange_a) annotation (
        Line(
        points={{-20,-2},{-10,-2}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(lever_arm_simple_2D1.flange_a1, constantForce.flange) annotation (
        Line(
        points={{1,0},{20,0}},
        color={0,127,0},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}),      graphics));
  end Test_Hebelarm_einfach;

  model Reibkomponente
  import SI = Modelica.SIunits;
  parameter SI.Inertia TraegheitsmomentHebelarm = 1;
  parameter Real viskoserReibbeiwert = 0.1;   // Einheit fehlt noch [Nms/Grad]
  SI.AngularVelocity Winkelgeschwindigkeit = der(flange_a.phi);
  SI.AngularAcceleration Winkelbeschleunigung = der(Winkelgeschwindigkeit);

    Modelica.Mechanics.Rotational.Sources.Torque
                              torque1(useSupport=false)
                              annotation (Placement(transformation(extent={{32,16},
              {52,36}},         rotation=0)));
    Modelica.Mechanics.Rotational.Components.Inertia inertia(J=
          TraegheitsmomentHebelarm)
      annotation (Placement(transformation(extent={{20,-10},{40,10}})));
    Modelica.Blocks.Sources.RealExpression realExpression2(
                                                          y=
          TraegheitsmomentHebelarm*Winkelbeschleunigung)
      annotation (Placement(transformation(extent={{8,16},{28,36}})));
    frictionRotational frictionRotational1
      annotation (Placement(transformation(extent={{28,-32},{48,-12}})));
    Modelica.Blocks.Sources.RealExpression realExpression3(y=-sign(
          Winkelgeschwindigkeit)*Winkelgeschwindigkeit*viskoserReibbeiwert)
      annotation (Placement(transformation(extent={{-44,-34},{-24,-14}})));
    Modelica.Mechanics.Rotational.Sources.Torque
                              torque2(useSupport=false)
                              annotation (Placement(transformation(extent={{-20,-34},
              {0,-14}},         rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
        Placement(transformation(extent={{-110,-10},{-90,10}}),
          iconTransformation(extent={{-110,-10},{-90,10}})));
  equation
    connect(torque1.flange,inertia. flange_b) annotation (Line(
        points={{52,26},{52,0},{40,0}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(inertia.flange_a,frictionRotational1. flange_a) annotation (Line(
        points={{20,0},{20,-22},{28,-22}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(realExpression2.y, torque1.tau) annotation (Line(
        points={{29,26},{30,26}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(realExpression3.y, torque2.tau) annotation (Line(
        points={{-23,-24},{-22,-24}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(flange_a, torque2.flange) annotation (Line(
        points={{-100,0},{0,0},{0,-24}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(flange_a, inertia.flange_a) annotation (Line(
        points={{-100,0},{0,0},{0,0},{20,0}},
        color={0,0,0},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{
              -100,-100},{100,100}}), graphics), Icon(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
          graphics={
          Ellipse(
            extent={{-60,60},{60,-60}},
            lineColor={0,128,255},
            fillPattern=FillPattern.Solid,
            fillColor={0,0,0}),
          Ellipse(
            extent={{-42,42},{42,-42}},
            lineColor={0,0,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Polygon(
            points={{-82,66},{16,76},{-32,82},{-26,72},{-28,60},{16,76},{-82,66}},
            lineColor={0,128,255},
            smooth=Smooth.None,
            fillColor={0,128,255},
            fillPattern=FillPattern.Solid)}));
  end Reibkomponente;

  model DceMechInConnector

    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor;
    Modelica.Mechanics.Translational.Sources.Position position;
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a;
    Modelica.Blocks.Interfaces.RealInput u;
    Modelica.Blocks.Interfaces.RealOutput y;
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a1
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
    Modelica.Blocks.Interfaces.RealOutput F
      annotation (Placement(transformation(extent={{90,-50},{110,-30}})));
    Modelica.Blocks.Interfaces.RealInput v
      annotation (Placement(transformation(extent={{110,-10},{90,10}})));
    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor1
      annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
    Modelica.Mechanics.Translational.Sources.Speed speed annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={30,0})));
  equation
    connect(position.flange, forceSensor.flange_a);
    connect(forceSensor.flange_b, flange_a);
    connect(position.s_ref, u);
    connect(forceSensor.f, y);
    connect(speed.v_ref, v) annotation (Line(
        points={{42,-1.33227e-015},{58,-1.33227e-015},{58,0},{100,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(flange_a1, forceSensor1.flange_a) annotation (Line(
        points={{-100,0},{-40,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(forceSensor1.f, F) annotation (Line(
        points={{-38,-11},{-38,-40},{100,-40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(forceSensor1.flange_b, speed.flange) annotation (Line(
        points={{-20,0},{20,0}},
        color={0,127,0},
        smooth=Smooth.None));
    annotation (uses(Modelica(version="3.2.1")), Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
          graphics));
  end DceMechInConnector;

  model Connector_Hebelarm_einfach

    DceMechOutConnector dceMechOutConnector
      annotation (Placement(transformation(extent={{30,-10},{50,10}})));
    lever_arm_simple_2D lever_arm_simple_2D1
      annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
    Modelica.Blocks.Interfaces.RealInput F
      annotation (Placement(transformation(extent={{110,20},{90,40}}),
          iconTransformation(extent={{90,20},{110,40}})));
    Modelica.Blocks.Interfaces.RealOutput s
      annotation (Placement(transformation(extent={{90,-10},{110,10}})));
    Modelica.Blocks.Interfaces.RealOutput v
      annotation (Placement(transformation(extent={{90,-40},{110,-20}})));
    DceRotOutConnector dceRotOutConnector annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-40,0})));
    Modelica.Blocks.Interfaces.RealOutput alpha
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-100,0})));
    Modelica.Blocks.Interfaces.RealOutput omega
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-100,-30})));
    Modelica.Blocks.Interfaces.RealOutput theta
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-100,-60})));
    Modelica.Blocks.Interfaces.RealInput M
      annotation (Placement(transformation(extent={{-110,40},{-90,20}})));
    Modelica.Blocks.Interfaces.RealOutput a
      annotation (Placement(transformation(extent={{90,-70},{110,-50}})));
    Modelica.Blocks.Interfaces.RealOutput beta annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={0,-100})));
  equation

    connect(lever_arm_simple_2D1.flange_a1, dceMechOutConnector.flange_a)
      annotation (Line(
        points={{1,0},{30,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(dceMechOutConnector.F, F) annotation (Line(
        points={{50,4},{70,4},{70,30},{100,30}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(s, dceMechOutConnector.s) annotation (Line(
        points={{100,0},{50,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(v, dceMechOutConnector.v) annotation (Line(
        points={{100,-30},{70,-30},{70,-4},{50,-4}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceRotOutConnector.flange_a, lever_arm_simple_2D1.flange_a)
      annotation (Line(
        points={{-30,-1.33227e-015},{-10,-1.33227e-015},{-10,-2}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(M, dceRotOutConnector.M) annotation (Line(
        points={{-100,30},{-70,30},{-70,4},{-50,4}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceMechOutConnector.a, a) annotation (Line(
        points={{50,-8},{60,-8},{60,-60},{100,-60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(alpha, dceRotOutConnector.alpha) annotation (Line(
        points={{-100,0},{-50,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(omega, dceRotOutConnector.omega) annotation (Line(
        points={{-100,-30},{-70,-30},{-70,-4},{-50,-4}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(theta, dceRotOutConnector.theta) annotation (Line(
        points={{-100,-60},{-60,-60},{-60,-8},{-50,-8}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(lever_arm_simple_2D1.beta, beta) annotation (Line(
        points={{1,-5},{10,-5},{10,-20},{0,-20},{0,-100}},
        color={0,0,127},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}), graphics), Icon(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
          graphics));
  end Connector_Hebelarm_einfach;

  model DceMechOutConnector

    Modelica.Mechanics.Translational.Sources.Force force
      annotation (Placement(transformation(extent={{0,30},{-20,50}})));
    Modelica.Mechanics.Translational.Sensors.PositionSensor positionSensor
      annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
    Modelica.Blocks.Interfaces.RealOutput s
      annotation (Placement(transformation(extent={{90,-10},{110,10}})));
    Modelica.Blocks.Interfaces.RealOutput v
      annotation (Placement(transformation(extent={{90,-50},{110,-30}})));
    Modelica.Blocks.Interfaces.RealInput F
      annotation (Placement(transformation(extent={{110,30},{90,50}})));
    Modelica.Blocks.Interfaces.RealOutput a
      annotation (Placement(transformation(extent={{90,-90},{110,-70}})));
    Modelica.Blocks.Continuous.Derivative derivative1(initType=Modelica.Blocks.Types.Init.InitialState)
      annotation (Placement(transformation(extent={{60,-90},{80,-70}})));
    Modelica.Blocks.Continuous.Derivative derivative(initType=Modelica.Blocks.Types.Init.InitialState)
      annotation (Placement(transformation(extent={{0,-50},{20,-30}})));
  equation
    connect(force.f,F)  annotation (Line(
        points={{2,40},{100,40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(flange_a, positionSensor.flange) annotation (Line(
        points={{-100,0},{-60,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(s, positionSensor.s) annotation (Line(
        points={{100,0},{-39,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(force.flange, flange_a) annotation (Line(
        points={{-20,40},{-70,40},{-70,0},{-100,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(derivative1.y, a) annotation (Line(
        points={{81,-80},{100,-80}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(positionSensor.s, derivative.u) annotation (Line(
        points={{-39,0},{-20,0},{-20,-40},{-2,-40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(derivative.y, v) annotation (Line(
        points={{21,-40},{100,-40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(derivative.y, derivative1.u) annotation (Line(
        points={{21,-40},{40,-40},{40,-80},{58,-80}},
        color={0,0,127},
        smooth=Smooth.None));
                              annotation (Line(
        points={{90,72},{90,72}},
        color={0,0,127},
        smooth=Smooth.None),
             uses(Modelica(version = "3.2.1")), Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics),
      Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
              100}}), graphics));
  end DceMechOutConnector;

  model DceRotOutConnector
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a
      "Anschluss im Festlager z.B. für einen rotatorischen Antriebsmotor"
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
    Modelica.Mechanics.Rotational.Sensors.AngleSensor angleSensor
      annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
    Modelica.Blocks.Interfaces.RealOutput alpha
      annotation (Placement(transformation(extent={{90,-10},{110,10}})));
    Modelica.Blocks.Continuous.Derivative derivative(initType=Modelica.Blocks.Types.Init.InitialState)
      annotation (Placement(transformation(extent={{0,30},{20,50}})));
    Modelica.Blocks.Interfaces.RealOutput omega
      annotation (Placement(transformation(extent={{90,30},{110,50}})));
    Modelica.Blocks.Interfaces.RealOutput theta
      annotation (Placement(transformation(extent={{90,70},{110,90}})));
    Modelica.Blocks.Continuous.Derivative derivative1(initType=Modelica.Blocks.Types.Init.InitialState)
      annotation (Placement(transformation(extent={{60,70},{80,90}})));
    Modelica.Mechanics.Rotational.Sources.Torque torque annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-10,-40})));
    Modelica.Blocks.Interfaces.RealInput M
      annotation (Placement(transformation(extent={{110,-50},{90,-30}})));
  equation
    connect(flange_a, angleSensor.flange) annotation (Line(
        points={{-100,0},{-60,0}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(angleSensor.phi, alpha) annotation (Line(
        points={{-39,0},{100,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(derivative.u, angleSensor.phi) annotation (Line(
        points={{-2,40},{-20,40},{-20,0},{-39,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(derivative.y, omega) annotation (Line(
        points={{21,40},{100,40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(derivative1.u, derivative.y) annotation (Line(
        points={{58,80},{40,80},{40,40},{21,40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(derivative1.y, theta) annotation (Line(
        points={{81,80},{100,80}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(torque.flange, flange_a) annotation (Line(
        points={{-20,-40},{-70,-40},{-70,0},{-100,0}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(torque.tau, M) annotation (Line(
        points={{2,-40},{100,-40}},
        color={0,0,127},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{
              -100,-100},{100,100}}), graphics));
  end DceRotOutConnector;

  model DceRotInConnector
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a
      "Anschluss im Festlager z.B. für einen rotatorischen Antriebsmotor"
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
    Modelica.Blocks.Interfaces.RealOutput M
      annotation (Placement(transformation(extent={{90,-50},{110,-30}})));
    Modelica.Blocks.Interfaces.RealInput omega
      annotation (Placement(transformation(extent={{110,-10},{90,10}})));
    Modelica.Mechanics.Rotational.Sensors.TorqueSensor torqueSensor
      annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
    Modelica.Mechanics.Rotational.Sources.Speed speed annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={30,0})));
  equation
    connect(flange_a, torqueSensor.flange_a) annotation (Line(
        points={{-100,0},{-40,0}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(torqueSensor.tau, M) annotation (Line(
        points={{-38,-11},{-38,-40},{100,-40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(speed.w_ref, omega) annotation (Line(
        points={{42,0},{100,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(torqueSensor.flange_b, speed.flange) annotation (Line(
        points={{-20,0},{20,0}},
        color={0,0,0},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{
              -100,-100},{100,100}}), graphics));
  end DceRotInConnector;

  model Connector_Hebelarm_komplex
    lever_arm_advanced_2D lever_arm_advanced_2D1
      annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
    DceRotOutConnector dceRotOutConnector annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={0,-30})));
    DceMechOutConnector dceMechOutConnector
      annotation (Placement(transformation(extent={{40,-10},{60,10}})));
    DceMechOutConnector dceMechOutConnector1 annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-50,0})));
    Modelica.Blocks.Interfaces.RealInput FZ1
      annotation (Placement(transformation(extent={{-110,-70},{-90,-50}})));
    Modelica.Blocks.Interfaces.RealInput FZ2
      annotation (Placement(transformation(extent={{110,70},{90,50}})));
    Modelica.Blocks.Interfaces.RealInput M annotation (Placement(transformation(
          extent={{10,10},{-10,-10}},
          rotation=270,
          origin={-60,-100})));
    Modelica.Blocks.Interfaces.RealOutput a1
      annotation (Placement(transformation(extent={{-90,70},{-110,50}})));
    Modelica.Blocks.Interfaces.RealOutput v1
      annotation (Placement(transformation(extent={{-90,30},{-110,10}})));
    Modelica.Blocks.Interfaces.RealOutput s1
      annotation (Placement(transformation(extent={{-90,-10},{-110,-30}})));
    Modelica.Blocks.Interfaces.RealOutput s2
      annotation (Placement(transformation(extent={{90,10},{110,30}})));
    Modelica.Blocks.Interfaces.RealOutput v2
      annotation (Placement(transformation(extent={{90,-30},{110,-10}})));
    Modelica.Blocks.Interfaces.RealOutput a2
      annotation (Placement(transformation(extent={{90,-70},{110,-50}})));
    Modelica.Blocks.Interfaces.RealOutput alpha annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-20,-100})));
    Modelica.Blocks.Interfaces.RealOutput omega annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={20,-100})));
    Modelica.Blocks.Interfaces.RealOutput theta annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={60,-100})));
    Modelica.Blocks.Interfaces.RealInput Fx1
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-66,100})));
    Modelica.Blocks.Interfaces.RealInput Fx2
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=270,
          origin={34,100})));
    Modelica.Blocks.Interfaces.RealInput Fy1
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-16,100})));
    Modelica.Blocks.Interfaces.RealInput Fy2
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=270,
          origin={84,100})));
    DceMechOutConnectorII dceMechOutConnectorII annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-50,50})));
    DceMechOutConnectorII dceMechOutConnectorII1 annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-20,50})));
    DceMechOutConnectorII dceMechOutConnectorII2 annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={20,50})));
    DceMechOutConnectorII dceMechOutConnectorII3 annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={50,50})));
    Modelica.Blocks.Interfaces.RealOutput PosF1x annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-90,100})));
    Modelica.Blocks.Interfaces.RealOutput PosF1y annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-40,100})));
    Modelica.Blocks.Interfaces.RealOutput PosF2x annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={10,100})));
    Modelica.Blocks.Interfaces.RealOutput PosF2y annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={60,100})));
    Modelica.Blocks.Interfaces.RealOutput beta1 annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={-90,-100})));
    Modelica.Blocks.Interfaces.RealOutput beta2 annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={90,-100})));
  equation
    connect(lever_arm_advanced_2D1.flange_a, dceRotOutConnector.flange_a)
      annotation (Line(
        points={{0,-3},{0,-20},{1.77636e-015,-20}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(FZ1, dceMechOutConnector1.F) annotation (Line(
        points={{-100,-60},{-70,-60},{-70,-4},{-60,-4}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(s1, dceMechOutConnector1.s) annotation (Line(
        points={{-100,-20},{-80,-20},{-80,0},{-60,0}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(v1, dceMechOutConnector1.v) annotation (Line(
        points={{-100,20},{-80,20},{-80,4},{-60,4}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(a1, dceMechOutConnector1.a) annotation (Line(
        points={{-100,60},{-70,60},{-70,8},{-60,8}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceMechOutConnector.F, FZ2) annotation (Line(
        points={{60,4},{70,4},{70,60},{100,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceMechOutConnector.a, a2) annotation (Line(
        points={{60,-8},{70,-8},{70,-60},{100,-60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceMechOutConnector.s, s2) annotation (Line(
        points={{60,0},{80,0},{80,20},{100,20}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceMechOutConnector.v, v2) annotation (Line(
        points={{60,-4},{80,-4},{80,-20},{100,-20}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(lever_arm_advanced_2D1.flange_2, dceMechOutConnector.flange_a)
      annotation (Line(
        points={{10,0},{40,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(dceMechOutConnector1.flange_a, lever_arm_advanced_2D1.flange_1)
      annotation (Line(
        points={{-40,0},{-10,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(theta, dceRotOutConnector.theta) annotation (Line(
        points={{60,-100},{60,-76},{8,-76},{8,-40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceRotOutConnector.omega, omega) annotation (Line(
        points={{4,-40},{4,-80},{20,-80},{20,-100}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceRotOutConnector.alpha, alpha) annotation (Line(
        points={{-1.77636e-015,-40},{-1.77636e-015,-80},{-20,-80},{-20,-100}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceRotOutConnector.M, M) annotation (Line(
        points={{-4,-40},{-4,-76},{-60,-76},{-60,-100}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(dceMechOutConnectorII.flange_a, lever_arm_advanced_2D1.flange_x3)
      annotation (Line(
        points={{-50,40},{-50,20},{-5,20},{-5,10}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(dceMechOutConnectorII1.flange_a, lever_arm_advanced_2D1.flange_y3)
      annotation (Line(
        points={{-20,40},{-20,26},{-2,26},{-2,10}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(dceMechOutConnectorII3.flange_a, lever_arm_advanced_2D1.flange_y4)
      annotation (Line(
        points={{50,40},{50,20},{5,20},{5,10}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(dceMechOutConnectorII2.flange_a, lever_arm_advanced_2D1.flange_x4)
      annotation (Line(
        points={{20,40},{20,26},{2,26},{2,10}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(PosF1x, dceMechOutConnectorII.s) annotation (Line(
        points={{-90,100},{-90,72},{-52,72},{-52,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(Fx1, dceMechOutConnectorII.F) annotation (Line(
        points={{-66,100},{-66,80},{-48,80},{-48,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(PosF1y, dceMechOutConnectorII1.s) annotation (Line(
        points={{-40,100},{-40,80},{-22,80},{-22,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(Fy1, dceMechOutConnectorII1.F) annotation (Line(
        points={{-16,100},{-16,80},{-18,80},{-18,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(PosF2x, dceMechOutConnectorII2.s) annotation (Line(
        points={{10,100},{10,80},{18,80},{18,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(Fx2, dceMechOutConnectorII2.F) annotation (Line(
        points={{34,100},{34,80},{22,80},{22,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(PosF2y, dceMechOutConnectorII3.s) annotation (Line(
        points={{60,100},{60,80},{48,80},{48,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(Fy2, dceMechOutConnectorII3.F) annotation (Line(
        points={{84,100},{84,70},{52,70},{52,60}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(lever_arm_advanced_2D1.y1, beta1) annotation (Line(
        points={{-10,-5},{-20,-5},{-20,-6},{-30,-6},{-30,-72},{-90,-72},{-90,
            -100}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(lever_arm_advanced_2D1.y, beta2) annotation (Line(
        points={{10,-5},{20,-5},{20,-6},{30,-6},{30,-72},{90,-72},{90,-100}},
        color={0,0,127},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}),      graphics), Icon(coordinateSystem(extent={{-100,
              -100},{100,100}})));
  end Connector_Hebelarm_komplex;

  model lever_arm_advanced_plus_2D

    import SI = Modelica.SIunits;
    import Modelica.Constants.pi;
  parameter SI.Acceleration Erdbeschleunigung = 9.81;
  parameter SI.Angle Drehwinkel(displayUnit="deg") = 0;
  parameter SI.AngularVelocity Anfangsgeschwindigkeit(displayUnit="deg/s") = pi/18;
  parameter SI.Inertia TraegheitsmomentHebelarm = 1;
  parameter Real viskoserReibbeiwert = 0.1;   // Einheit fehlt noch [Nms/Grad]
  parameter SI.Torque Mdf = 8;  // Coulomb'sches Reibmoment
  parameter SI.Torque Msf = 10;  // Haftreibmoment
  SI.AngularVelocity Winkelgeschwindigkeit = der(flange_a.phi);
  SI.AngularAcceleration Winkelbeschleunigung = der(Winkelgeschwindigkeit);
  parameter SI.Mass Masse1 = 850;
  parameter SI.Mass Masse2 = 750;
  parameter SI.Position[2] FZF1 = {-1,-1};
  parameter SI.Position[2] FZF2 = {1,-1};
  parameter SI.Position[2] FZA1 = {-1,0};
  parameter SI.Position[2] FZA2 = {1,0};
  parameter SI.Position[2] F1 = {-1,1};
  parameter SI.Position[2] F2 = {1,1};
  parameter SI.Position[2] m1 = {-2,0};
  parameter SI.Position[2] m2 = {2,0};
  parameter SI.Position[2] L = {0,0};
  parameter SI.Force Fx1 = 10;
  parameter SI.Force Fy1 = 10;
  parameter SI.Force Fx2 = 10;
  parameter SI.Force Fy2 = 10;
  Real KraftF1;
  Real KraftF2;
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation(r={abs(FZA2
          [1] - L[1]),abs(FZA2[2] - L[2])})
      annotation (Placement(transformation(extent={{30,-10},{50,10}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation1(r={abs(L[1]
           - FZA1[1]),abs(L[2] - FZA1[2])})
      annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation2(r={abs(m2[
          1] - L[1]),abs(m2[2] - L[2])})
      annotation (Placement(transformation(extent={{40,20},{60,40}})));
    PlanarMechanicsStandard.Parts.Body body(      I=10,
      g={0,-Erdbeschleunigung},
      m=Masse2)                                         annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={90,30})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation5(r={abs(L[1]
           - m1[1]),abs(L[2] - m1[2])})
      annotation (Placement(transformation(extent={{-60,0},{-40,20}})));
    PlanarMechanicsStandard.Parts.Body body1(      I=10,
      g={0,-Erdbeschleunigung},
      m=Masse1)                                          annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-90,10})));
    PlanarMechanicsStandard.Parts.Fixed fixed(r={L[1],L[2]})
                                                       annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={0,-90})));
    JuliansBib.Ausleger_xy
             ausleger2(Lagerpunkt={F1[1],F1[2]}, Zylinderlaenge={abs(L[1] - F1[
          1]),abs(L[2] - F1[2])})
      annotation (Placement(transformation(extent={{-40,20},{-20,40}})));
    JuliansBib.Ausleger_xy
             ausleger3(Lagerpunkt={F2[1],F2[2]}, Zylinderlaenge={abs(F2[1] - L[
          1]),abs(F2[2] - L[2])})                annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={8,50})));
    PlanarMechanicsStandard.Joints.ActuatedRevolute actuatedRevolute(
      w_start=Anfangsgeschwindigkeit,
      phi_start=Drehwinkel,
      initialize=false)
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=270,
          origin={0,-16})));
    Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a
      "Anschluss im Festlager z.B. für einen rotatorischen Antriebsmotor"
      annotation (Placement(transformation(extent={{10,-20},{30,0}}),
          iconTransformation(extent={{10,-20},{30,0}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_x3 annotation (
        Placement(transformation(extent={{-60,90},{-40,110}}), iconTransformation(
            extent={{-60,90},{-40,110}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_y4
      annotation (Placement(transformation(extent={{40,90},{60,110}})));
    PlanarMechanicsStandard.Joints.ActuatedPrismatic actuatedPrismatic1(r={0,1})
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={0,-40})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a5
      "mechanischer Anschluss 1 zur Krafteinleitung, z.B. für einen Zylinder"
      annotation (Placement(transformation(extent={{-40,-50},{-20,-30}}),
          iconTransformation(extent={{-40,-20},{-20,0}})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation3(r={0,
          0.0001})                                                   annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={0,-66})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_x4 annotation (
        Placement(transformation(extent={{10,90},{30,110}}),   iconTransformation(
            extent={{10,90},{30,110}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_y3
      annotation (Placement(transformation(extent={{-30,90},{-10,110}})));
    Ausleger ausleger annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-80,-30})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_1
      "mechanischer Anschluss 2 zur Krafteinleitung, z.B. für einen Zylinder"
      annotation (Placement(transformation(extent={{-110,-20},{-90,0}}),
          iconTransformation(extent={{-110,-20},{-90,0}})));
    Ausleger ausleger1 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={70,0})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_2
      "mechanischer Anschluss 2 zur Krafteinleitung, z.B. für einen Zylinder"
      annotation (Placement(transformation(extent={{90,-30},{110,-10}}),
          iconTransformation(extent={{90,-20},{110,0}})));
  equation
    connect(fixedTranslation2.frame_b,body. frame_a) annotation (Line(
        points={{60,30},{80,30}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(body1.frame_a,fixedTranslation5. frame_a) annotation (Line(
        points={{-80,10},{-60,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation1.frame_b,actuatedRevolute. frame_a) annotation (Line(
        points={{-20,0},{0,0},{0,-6}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation5.frame_b,actuatedRevolute. frame_a) annotation (Line(
        points={{-40,10},{-12,10},{-12,0},{0,0},{0,-6}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(ausleger2.frame_a,actuatedRevolute. frame_a) annotation (Line(
        points={{-23,30},{-6,30},{-6,0},{0,0},{0,-6}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation.frame_a,actuatedRevolute. frame_a) annotation (Line(
        points={{30,0},{0,0},{0,-6}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation2.frame_a,actuatedRevolute. frame_a) annotation (Line(
        points={{40,30},{14,30},{14,0},{0,0},{0,-6}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(ausleger3.frame_a,actuatedRevolute. frame_a) annotation (Line(
        points={{8,43},{8,0},{0,0},{0,-6}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(flange_a,actuatedRevolute. flange_a)  annotation (Line(
        points={{20,-10},{20,-16},{10,-16}},
        color={0,0,0},
        smooth=Smooth.None));
    connect(flange_x3,flange_x3)  annotation (Line(
        points={{-50,100},{-50,100}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(actuatedRevolute.frame_b, actuatedPrismatic1.frame_b)
                                                                 annotation (Line(
        points={{0,-26},{0,-30}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(flange_a5, actuatedPrismatic1.flange_a)
                                                   annotation (Line(
        points={{-30,-40},{-9,-40}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(actuatedPrismatic1.frame_a, fixedTranslation3.frame_b)
                                                                  annotation (
        Line(
        points={{0,-50},{0,-56}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixed.frame_a, fixedTranslation3.frame_a) annotation (Line(
        points={{0,-80},{0,-76}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(flange_1, ausleger.flange_a) annotation (Line(
        points={{-100,-10},{-92,-10},{-92,-29},{-83,-29}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(ausleger.frame_a, fixedTranslation1.frame_a) annotation (Line(
        points={{-80,-23},{-50,-23},{-50,0},{-40,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation.frame_b, ausleger1.frame_a) annotation (Line(
        points={{50,0},{63,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(ausleger1.flange_a, flange_2) annotation (Line(
        points={{69,-3},{69,-19.5},{100,-19.5},{100,-20}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_x3, ausleger2.flange_a1) annotation (Line(
        points={{-50,100},{-50,54},{-24,54},{-24,37},{-25,37}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_y3, ausleger2.flange_a) annotation (Line(
        points={{-20,100},{-33,100},{-33,37}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_x4, ausleger3.flange_a1) annotation (Line(
        points={{20,100},{20,45},{15,45}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(flange_y4, ausleger3.flange_a) annotation (Line(
        points={{50,100},{50,53},{15,53}},
        color={0,127,0},
        smooth=Smooth.None));
    annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}),
                           graphics={
          Ellipse(
            extent={{-10,44},{-2,36}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-10,40},{-16,30},{4,30},{-2,40},{-6,40}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-78,24},{78,66},{80,60},{-76,18},{-78,24},{-76,18}},
            color={0,0,0},
            smooth=Smooth.None),
          Ellipse(
            extent={{94,74},{76,56}},
            lineColor={0,128,255},
            fillColor={0,128,255},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-76,28},{-94,10}},
            lineColor={0,128,255},
            fillColor={0,128,255},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-6,30},{-10,26},{-10,26}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-12,30},{-16,26},{-16,26}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{0,30},{-4,26},{0,30}},
            color={0,0,0},
            smooth=Smooth.None),
          Rectangle(
            extent={{-3,14},{3,-14}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid,
            origin={53,40},
            rotation=360),
          Rectangle(
            extent={{-7,22},{7,-22}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid,
            origin={53,4},
            rotation=360),
          Line(
            points={{-7,7},{7,7},{7,-37},{-7,-37},{-7,7},{-3,7},{-3,37},{3,35}},
            color={0,0,0},
            smooth=Smooth.None,
            origin={53,19},
            rotation=360),
          Line(
            points={{0,-16},{0,16},{0,16}},
            color={0,0,0},
            smooth=Smooth.None,
            origin={56,42},
            rotation=360),
          Ellipse(
            extent={{-7,7},{7,-7}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid,
            origin={53,-19},
            rotation=360),
          Rectangle(
            extent={{-56,24},{-50,-4}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-60,-4},{-46,-48}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-60,-4},{-46,-4},{-46,-48},{-60,-48},{-60,-4},{-56,-4},{-56,26},
                {-50,24}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-50,-4},{-50,28},{-50,28}},
            color={0,0,0},
            smooth=Smooth.None),
          Ellipse(
            extent={{-60,-42},{-46,-56}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-60,-48},{-74,-68},{-32,-68},{-46,-48}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-66,-68},{-74,-76}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-52,-68},{-60,-76}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-38,-68},{-46,-76}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{46,-18},{32,-38},{74,-38},{60,-18}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{40,-38},{32,-46}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{54,-38},{46,-46}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{68,-38},{60,-46}},
            color={0,0,0},
            smooth=Smooth.None),
          Ellipse(
            extent={{-58,30},{-50,22}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{50,60},{58,52}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-6,20},{-12,6},{-6,20},{0,6},{-6,20},{-6,-38},{-12,-24},{-6,-38},
                {0,-24},{-6,-30},{-12,-24},{-6,-30},{-6,12},{-12,6},{-6,12},{0,6},
                {-6,20}},
            color={0,0,0},
            smooth=Smooth.None),
          Polygon(
            points={{-30,38},{-36,52},{-24,52},{-24,52},{-30,38}},
            lineColor={255,0,0},
            smooth=Smooth.None,
            fillPattern=FillPattern.Solid,
            fillColor={255,0,0}),
          Polygon(
            points={{30,54},{24,68},{36,68},{36,68},{30,54}},
            lineColor={255,0,0},
            smooth=Smooth.None,
            fillPattern=FillPattern.Solid,
            fillColor={255,0,0}),
          Rectangle(
            extent={{-32,50},{-28,74}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{28,66},{32,88}},
            lineColor={255,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-34,38},{-26,30}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{26,54},{34,46}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid)}), Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
  end lever_arm_advanced_plus_2D;

  model Kraftzerlegung
    Modelica.Blocks.Math.Sqrt sqrt1 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={0,-30})));
    Modelica.Blocks.Math.Product product1 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-50,-30})));
    Modelica.Blocks.Math.Product product2 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={30,50})));
    Modelica.Blocks.Math.Add add(k1=1, k2=1) annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={0,10})));
    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor
      annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));
    Modelica.Mechanics.Translational.Sensors.ForceSensor forceSensor1
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={70,0})));
    Modelica.Mechanics.Translational.Components.Fixed fixed annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=90,
          origin={-50,0})));
    Modelica.Mechanics.Translational.Components.Fixed fixed1 annotation (
        Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={50,0})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_x
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_y
      annotation (Placement(transformation(extent={{90,-10},{110,10}})));
    Modelica.Blocks.Interfaces.RealOutput y annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={0,-100})));
  equation
    connect(add.y, sqrt1.u) annotation (Line(
        points={{0,-1},{0,-18}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(add.u1, product2.y) annotation (Line(
        points={{6,22},{6,50},{19,50}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(fixed1.flange, forceSensor1.flange_b) annotation (Line(
        points={{50,0},{60,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(forceSensor.flange_b, fixed.flange) annotation (Line(
        points={{-60,0},{-50,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(product1.y, add.u2) annotation (Line(
        points={{-39,-30},{-20,-30},{-20,30},{-6,30},{-6,22}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(flange_x, forceSensor.flange_a) annotation (Line(
        points={{-100,0},{-80,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(forceSensor1.flange_a, flange_y) annotation (Line(
        points={{80,0},{100,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(forceSensor.f, product1.u2) annotation (Line(
        points={{-78,-11},{-78,-36},{-62,-36}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(forceSensor.f, product1.u1) annotation (Line(
        points={{-78,-11},{-78,-24},{-62,-24}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(forceSensor1.f, product2.u2) annotation (Line(
        points={{78,11},{78,56},{42,56}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(forceSensor1.f, product2.u1) annotation (Line(
        points={{78,11},{78,44},{42,44}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(sqrt1.y, y) annotation (Line(
        points={{0,-41},{0,-100}},
        color={0,0,127},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}),      graphics), Icon(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
          graphics));
  end Kraftzerlegung;

  model Ausleger
    import SI = Modelica.SIunits;
  parameter SI.Position[2] Zylinderlaenge = {1,1};
  parameter SI.Position[2] Lagerpunkt = {2,2};
      Real X;
      Real Y;

    PlanarMechanicsStandard.Joints.ActuatedPrismatic actuatedPrismatic1(
      s_start=0,
      v_start=0,
      initialize=true,
      r={Zylinderlaenge[1],Zylinderlaenge[2]})
                 annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={10,0})));
    PlanarMechanicsStandard.Joints.Revolute revolute1
      annotation (Placement(transformation(extent={{30,-10},{50,10}})));
    PlanarMechanicsStandard.Parts.Fixed fixed(r={Lagerpunkt[1],Lagerpunkt[2]})
      annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-80,0})));
    PlanarMechanicsStandard.Joints.Revolute revolute  annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-50,0})));
    PlanarMechanicsStandard.Parts.FixedTranslation fixedTranslation(r={
          Zylinderlaenge[1],Zylinderlaenge[2]})
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-20,0})));
    PlanarMechanicsStandard.Interfaces.Frame_a frame_a
      annotation (Placement(transformation(extent={{60,-10},{80,10}})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a
      annotation (Placement(transformation(extent={{0,20},{20,40}})));

    PlanarMechanicsStandard.Sensors.AbsoluteRotation absoluteRotation
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-10,-30})));
    Modelica.Blocks.Interfaces.RealOutput beta annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={10,-50})));
  equation
    X = abs(actuatedPrismatic1.frame_a.x-actuatedPrismatic1.frame_b.x);
    Y = abs(actuatedPrismatic1.frame_a.y-actuatedPrismatic1.frame_b.y);

    connect(revolute.frame_a,fixed. frame_a)   annotation (Line(
        points={{-60,0},{-70,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation.frame_a,revolute. frame_b)   annotation (Line(
        points={{-30,0},{-40,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(actuatedPrismatic1.frame_a,fixedTranslation. frame_b) annotation (
        Line(
        points={{0,0},{-10,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(actuatedPrismatic1.frame_b,revolute1. frame_a) annotation (Line(
        points={{20,0},{30,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(revolute1.frame_b,frame_a)  annotation (Line(
        points={{50,0},{70,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(flange_a, actuatedPrismatic1.flange_a) annotation (Line(
        points={{10,30},{10,9}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(revolute.frame_b, absoluteRotation.frame_b) annotation (Line(
        points={{-40,0},{-36,0},{-36,-30},{-20,-30}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(absoluteRotation.y, beta) annotation (Line(
        points={{1,-30},{10,-30},{10,-50}},
        color={0,0,127},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}),      graphics), Icon(graphics={
          Line(
            points={{-50,10},{-90,30},{-90,-30},{-50,-10},{-50,-2}},
            color={0,0,0},
            smooth=Smooth.None),
          Line(
            points={{-100,30},{-90,20},{-90,10},{-90,0},{-100,10},{-90,0},{-90,-20},
                {-100,-10}},
            color={0,0,0},
            smooth=Smooth.None),
          Rectangle(
            extent={{-50,10},{0,-10}},
            lineColor={0,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-60,10},{-40,-10}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{0,4},{42,-4}},
            lineColor={0,0,0},
            fillColor={255,0,0},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{40,10},{60,-10}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid)}));
  end Ausleger;

  model DceMechOutConnectorII
    Modelica.Mechanics.Translational.Sources.Force force annotation (Placement(
          transformation(
          extent={{-10,-10},{10,10}},
          rotation=0,
          origin={-10,20})));
    Modelica.Blocks.Interfaces.RealInput F
      annotation (Placement(transformation(extent={{10,-10},{-10,10}},
          rotation=180,
          origin={-100,20})));
    Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a
      annotation (Placement(transformation(extent={{90,-10},{110,10}})));
    Modelica.Mechanics.Translational.Sensors.PositionSensor positionSensor
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-10,-20})));
    Modelica.Blocks.Interfaces.RealOutput s
      annotation (Placement(transformation(extent={{-10,-10},{10,10}},
          rotation=180,
          origin={-100,-20})));
  equation
    connect(force.flange, flange_a) annotation (Line(
        points={{0,20},{60,20},{60,0},{100,0}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(s, positionSensor.s) annotation (Line(
        points={{-100,-20},{-21,-20}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(F, force.f) annotation (Line(
        points={{-100,20},{-22,20}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(positionSensor.flange, flange_a) annotation (Line(
        points={{0,-20},{60,-20},{60,0},{100,0}},
        color={0,127,0},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
              -100},{100,100}}),      graphics));
  end DceMechOutConnectorII;
  annotation (uses(Modelica(version="3.2.1")));
end JuliansBib;

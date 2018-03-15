within ;
package cranes
  model crane

    inner Modelica.Mechanics.MultiBody.World world(enableAnimation=false)
      annotation (Placement(transformation(extent={{-80,40},{-60,60}})));
    Modelica.Mechanics.MultiBody.Parts.BodyShape bodyShape(m=1, r={0,0,0},
      r_CM={0,0,0})
      annotation (Placement(transformation(extent={{18,40},{38,60}})));
    Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic(useAxisFlange=true,
      v(fixed=true, start=0),
      s(fixed=false, start=0))
      annotation (Placement(transformation(extent={{-30,40},{-10,60}})));
    Modelica.Mechanics.Translational.Sources.Position position(useSupport=true)
      annotation (Placement(transformation(extent={{-34,68},{-14,88}})));
    Modelica.Blocks.Sources.Sine sine(amplitude=1, freqHz=0.2)
      annotation (Placement(transformation(extent={{-94,68},{-74,88}})));
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute(cylinderLength=0.2,
      phi(fixed=true, start=0),
      w(fixed=true, start=0))
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={42,26})));
    Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation(r={0,-1,
          0}) annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={42,-10})));
    Modelica.Mechanics.MultiBody.Parts.Body body(m=500, r_CM={0,0,0})
                                                        annotation (Placement(
          transformation(
          extent={{-10,-11},{10,11}},
          rotation=270,
          origin={42,-39})));
  equation
    connect(world.frame_b, prismatic.frame_a) annotation (Line(
        points={{-60,50},{-30,50}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(bodyShape.frame_a, prismatic.frame_b) annotation (Line(
        points={{18,50},{-10,50}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(prismatic.support, position.support) annotation (Line(
        points={{-24,56},{-24,68}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(position.flange, prismatic.axis) annotation (Line(
        points={{-14,78},{-14,56},{-12,56}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(position.s_ref, sine.y) annotation (Line(
        points={{-36,78},{-73,78}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(bodyShape.frame_b, revolute.frame_a) annotation (Line(
        points={{38,50},{42,50},{42,36}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(revolute.frame_b, fixedTranslation.frame_a) annotation (Line(
        points={{42,16},{42,0}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation.frame_b, body.frame_a) annotation (Line(
        points={{42,-20},{42,-29}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    annotation (                                 Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
  end crane;

  model crane_input
    inner Modelica.Mechanics.MultiBody.World world
      annotation (Placement(transformation(extent={{-70,50},{-50,70}})));
    Modelica.Mechanics.MultiBody.Parts.BodyShape bodyShape(m=1, r={0,0,0})
      annotation (Placement(transformation(extent={{28,50},{48,70}})));
    Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic(useAxisFlange=true)
      annotation (Placement(transformation(extent={{-20,50},{0,70}})));
    Modelica.Mechanics.Translational.Sources.Position position(useSupport=true)
      annotation (Placement(transformation(extent={{-24,78},{-4,98}})));
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute(cylinderLength=0.2)
      annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={52,36})));
    Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation(r={0,-1,
          0}) annotation (Placement(transformation(
          extent={{-10,-10},{10,10}},
          rotation=270,
          origin={52,0})));
    Modelica.Mechanics.MultiBody.Parts.Body body(m=500) annotation (Placement(
          transformation(
          extent={{-10,-11},{10,11}},
          rotation=270,
          origin={52,-29})));
    Modelica_DeviceDrivers.Blocks.OperatingSystem.SynchronizeRealtime
                                        synchronizeRealtime
      annotation (Placement(transformation(extent={{-102,4},{-82,24}})));
    Modelica_DeviceDrivers.Blocks.InputDevices.KeyboardInput
                               keyboardInput
      annotation (Placement(transformation(extent={{-144,-38},{-124,-18}})));
    Modelica.Blocks.Logical.Switch switch1
      annotation (Placement(transformation(extent={{-56,-50},{-36,-30}})));
    Modelica.Blocks.Sources.Constant drive(k=1)
      annotation (Placement(transformation(extent={{-100,-30},{-80,-10}})));
    Modelica.Blocks.Sources.Constant no_drive(k=0)
      annotation (Placement(transformation(extent={{-100,-78},{-80,-58}})));
    Modelica.Blocks.Continuous.Integrator integrator
      annotation (Placement(transformation(extent={{-20,-50},{0,-30}})));
  equation
    connect(world.frame_b,prismatic. frame_a) annotation (Line(
        points={{-50,60},{-20,60}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(bodyShape.frame_a,prismatic. frame_b) annotation (Line(
        points={{28,60},{0,60}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(prismatic.support,position. support) annotation (Line(
        points={{-14,66},{-14,78}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(position.flange,prismatic. axis) annotation (Line(
        points={{-4,88},{-4,66},{-2,66}},
        color={0,127,0},
        smooth=Smooth.None));
    connect(bodyShape.frame_b,revolute. frame_a) annotation (Line(
        points={{48,60},{52,60},{52,46}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(revolute.frame_b,fixedTranslation. frame_a) annotation (Line(
        points={{52,26},{52,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(fixedTranslation.frame_b,body. frame_a) annotation (Line(
        points={{52,-10},{52,-10},{52,-20},{52,-20},{52,-20},{52,-19}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(no_drive.y, switch1.u3) annotation (Line(
        points={{-79,-68},{-70,-68},{-70,-48},{-58,-48}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(keyboardInput.keyRight, switch1.u2) annotation (Line(
        points={{-128,-39},{-64,-39},{-64,-40},{-58,-40}},
        color={255,0,255},
        smooth=Smooth.None));
    connect(drive.y, switch1.u1) annotation (Line(
        points={{-79,-20},{-74,-20},{-74,-32},{-58,-32}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(switch1.y, integrator.u) annotation (Line(
        points={{-35,-40},{-22,-40}},
        color={0,0,127},
        smooth=Smooth.None));
    connect(integrator.y, position.s_ref) annotation (Line(
        points={{1,-40},{2,-40},{2,40},{-90,40},{-90,88},{-26,88}},
        color={0,0,127},
        smooth=Smooth.None));
    annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{
              -100,-100},{100,100}}), graphics));
  end crane_input;
end cranes;

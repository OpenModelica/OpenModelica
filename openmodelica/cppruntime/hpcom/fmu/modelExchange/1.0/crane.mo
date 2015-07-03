within ;
model crane
  inner Modelica.Mechanics.MultiBody.World world
    annotation (Placement(transformation(extent={{-80,40},{-60,60}})));
  Modelica.Mechanics.MultiBody.Parts.BodyShape bodyShape(m=1, r={0,0,0})
    annotation (Placement(transformation(extent={{18,40},{38,60}})));
  Modelica.Mechanics.MultiBody.Joints.Prismatic prismatic(useAxisFlange=true)
    annotation (Placement(transformation(extent={{-30,40},{-10,60}})));
  Modelica.Mechanics.Translational.Sources.Position position(useSupport=true)
    annotation (Placement(transformation(extent={{-34,68},{-14,88}})));
  Modelica.Blocks.Sources.Sine sine(amplitude=1, freqHz=0.2)
    annotation (Placement(transformation(extent={{-94,68},{-74,88}})));
  Modelica.Mechanics.MultiBody.Joints.Revolute revolute(cylinderLength=0.2)
    annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={42,26})));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation fixedTranslation(r={0,-1,
        0}) annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=270,
        origin={42,-10})));
  Modelica.Mechanics.MultiBody.Parts.Body body(m=500) annotation (Placement(
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
      points={{42,-20},{42,-20},{42,-30},{42,-30},{42,-30},{42,-29}},
      color={95,95,95},
      thickness=0.5,
      smooth=Smooth.None));
  annotation (uses(Modelica(version="3.2.1")), Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics));
end crane;

within ;
model Engine1a_output "Model of one cylinder engine"
  extends Modelica.Icons.Example;
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder Piston(diameter=0.1, r={0,-0.1,
        0}) annotation (Placement(transformation(
        origin={90.5,66.5},
        extent={{-10.5,30.5},{10.5,-30.5}},
        rotation=270)));
  Modelica.Mechanics.MultiBody.Parts.BodyBox Rod(
    widthDirection={1,0,0},
    width=0.02,
    height=0.06,
    r={0,-0.2,0},
    color={0,0,200}) annotation (Placement(transformation(
        origin={90,5},
        extent={{10,-10},{-10,10}},
        rotation=90)));
  Modelica.Mechanics.MultiBody.Joints.Revolute B2(
    n={1,0,0},
    cylinderLength=0.02,
    cylinderDiameter=0.05) annotation (Placement(transformation(extent={{80,22},
            {100,42}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Joints.Revolute Bearing(
    useAxisFlange=true,
    n={1,0,0},
    cylinderLength=0.02,
    cylinderDiameter=0.05) annotation (Placement(transformation(extent={{-10,-80},
            {10,-100}}, rotation=0)));
  inner Modelica.Mechanics.MultiBody.World world annotation (Placement(
        transformation(extent={{-50,-100},{-30,-80}}, rotation=0)));
  Modelica.Mechanics.Rotational.Components.Inertia Inertia(
    stateSelect=StateSelect.always,
    phi(fixed=true, start=0),
    w(fixed=true, start=10),
    J=1) annotation (Placement(transformation(extent={{-28,-120},{-8,-100}},
          rotation=0)));
  Modelica.Mechanics.MultiBody.Parts.BodyBox Crank4(
    height=0.05,
    widthDirection={1,0,0},
    width=0.02,
    r={0,-0.1,0}) annotation (Placement(transformation(
        origin={115.5,-75},
        extent={{10,-10},{-10,10}},
        rotation=90)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder Crank3(r={0.1,0,0}, diameter=
        0.03) annotation (Placement(transformation(extent={{81.5,-71},{101.5,-51}},
          rotation=0)));
  Modelica.Mechanics.MultiBody.Parts.BodyCylinder Crank1(diameter=0.05, r={0.1,
        0,0}) annotation (Placement(transformation(extent={{24,-100},{44,-80}},
          rotation=0)));
  Modelica.Mechanics.MultiBody.Parts.BodyBox Crank2(
    r={0,0.1,0},
    height=0.05,
    widthDirection={1,0,0},
    width=0.02) annotation (Placement(transformation(
        origin={70,-76},
        extent={{-10,-10},{10,10}},
        rotation=90)));
  Modelica.Mechanics.MultiBody.Joints.RevolutePlanarLoopConstraint B1(
    n={1,0,0},
    cylinderLength=0.02,
    cylinderDiameter=0.05) annotation (Placement(transformation(extent={{80,-30},
            {100,-10}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation Mid(r={0.05,0,0})
    annotation (Placement(transformation(extent={{70,-53},{90,-33}}, rotation=0)));
  Modelica.Mechanics.MultiBody.Joints.Prismatic Cylinder(
    boxWidth=0.02,
    n={0,-1,0},
    s(start=0.15)) annotation (Placement(transformation(
        origin={90,96},
        extent={{-10,-10},{10,10}},
        rotation=270)));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation cylPosition(animation=
        false, r={0.15,0.45,0}) annotation (Placement(transformation(extent={{-0.5,
            100},{19.5,120}}, rotation=0)));
  Modelica.Blocks.Interfaces.RealOutput speed
    annotation (Placement(transformation(extent={{42,-4},{62,16}})));
  Modelica.Mechanics.Rotational.Sensors.SpeedSensor speedSensor
    annotation (Placement(transformation(extent={{10,-34},{30,-14}})));
equation
  connect(world.frame_b, Bearing.frame_a) annotation (Line(
      points={{-30,-90},{-10,-90}},
      color={95,95,95},
      thickness=0.5));
  connect(Crank2.frame_a, Crank1.frame_b) annotation (Line(
      points={{70,-86},{70,-90},{44,-90}},
      color={95,95,95},
      thickness=0.5));
  connect(Crank2.frame_b, Crank3.frame_a) annotation (Line(
      points={{70,-66},{70,-61},{81.5,-61}},
      color={95,95,95},
      thickness=0.5));
  connect(Bearing.frame_b, Crank1.frame_a) annotation (Line(
      points={{10,-90},{24,-90}},
      color={95,95,95},
      thickness=0.5));
  connect(cylPosition.frame_b, Cylinder.frame_a) annotation (Line(
      points={{19.5,110},{90,110},{90,106}},
      color={95,95,95},
      thickness=0.5));
  connect(world.frame_b, cylPosition.frame_a) annotation (Line(
      points={{-30,-90},{-20,-90},{-20,110},{-0.5,110}},
      color={95,95,95},
      thickness=0.5));
  connect(Crank3.frame_b, Crank4.frame_a) annotation (Line(
      points={{101.5,-61},{115,-61},{115,-65},{115.5,-65}},
      color={95,95,95},
      thickness=0.5));
  connect(B1.frame_a, Mid.frame_b) annotation (Line(
      points={{80,-20},{70,-20},{70,-32},{98,-32},{98,-43},{90,-43}},
      color={95,95,95},
      thickness=0.5));
  connect(B1.frame_b, Rod.frame_b) annotation (Line(
      points={{100,-20},{112,-20},{112,-9},{90,-9},{90,-5}},
      color={95,95,95},
      thickness=0.5));
  connect(Rod.frame_a, B2.frame_b) annotation (Line(
      points={{90,15},{90,21},{110,21},{110,32},{100,32}},
      color={95,95,95},
      thickness=0.5));
  connect(B2.frame_a, Piston.frame_b) annotation (Line(
      points={{80,32},{70,32},{70,46},{90.5,46},{90.5,56}},
      color={95,95,95},
      thickness=0.5));
  connect(Inertia.flange_b, Bearing.axis)
    annotation (Line(points={{-8,-110},{0,-110},{0,-100}}, color={0,0,0}));
  connect(Mid.frame_a, Crank2.frame_b) annotation (Line(
      points={{70,-43},{63,-43},{63,-61},{70,-61},{70,-66}},
      color={95,95,95},
      thickness=0.5));
  connect(Cylinder.frame_b, Piston.frame_a) annotation (Line(
      points={{90,86},{90,77},{90.5,77}},
      color={95,95,95},
      thickness=0.5));
  connect(speedSensor.flange, Bearing.axis) annotation (Line(
      points={{10,-24},{-4,-24},{-4,-48},{16,-48},{16,-106},{0,-106},{0,-100}},

      color={0,0,0},
      smooth=Smooth.None));
  connect(speedSensor.w, speed) annotation (Line(
      points={{31,-24},{36.5,-24},{36.5,6},{52,6}},
      color={0,0,127},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(extent={{-130,-130},{130,130}},
          preserveAspectRatio=false), graphics),
    experiment(StopTime=5), Documentation(info="<html>
<p>
This is a model of the mechanical part of one cylinder of an engine.
The combustion is not modelled. The \"inertia\" component at the lower
left part is the output inertia of the engine driving the gearbox.
The angular velocity of the output inertia has a start value of 10 rad/s
in order to demonstrate the movement of the engine.
</p>
<p>
The engine is modeled solely by revolute and prismatic joints.
Since this results in a <b>planar</b> loop there is the well known
difficulty that the cut-forces perpendicular to the loop cannot be
uniquely computed, as well as the cut-torques within the plane.
This ambiguity is resolved by using the option <b>planarCutJoint</b>
in the <b>Advanced</b> menu of one revolute joint in every planar loop
(here: joint B1). This option sets the cut-force in direction of the
axis of rotation, as well as the cut-torques perpendicular to the axis
of rotation at this joint to zero and makes the problem mathematically
well-formed.
</p>
<p>
An animation of this example is shown in the figure below.
</p>

<IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Examples/Loops/Engine.png\" ALT=\"model Examples.Loops.Engine\">
</html>"),
    uses(Modelica(version="3.2.1")));
end Engine1a_output;

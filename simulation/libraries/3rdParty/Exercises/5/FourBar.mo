within ;
package FourBar
  partial model PartialPlanarLoop "Basic elements of a planar loop"
    import SI = Modelica.SIunits;
    parameter SI.Length rh1[3]={0.5,0,0} "Position vector from r1 to r4";
    parameter SI.Length rv1[3]={0,0.5,0} "Position vector from r1 to r2";
    parameter SI.Length rv2[3]={0.1,0.5,0} "Position vector from r4 to r2";
    final parameter SI.Length rh2[3]=rv2 + rh1 - rv1
      "Position vector from r2 to r3";

    inner Modelica.Mechanics.MultiBody.World world(axisDiameter=0.6/40,
        axisLength=0.8)                            annotation (Placement(
          transformation(extent={{-80,-50},{-60,-30}}, rotation=0)));
    Modelica.Mechanics.MultiBody.Joints.Revolute r1(useAxisFlange=true)
      annotation (Placement(transformation(
          origin={-50,0},
          extent={{-10,-10},{10,10}},
          rotation=90)));
    Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod1(r=rv1)
      annotation (Placement(transformation(
          origin={-50,30},
          extent={{-10,-10},{10,10}},
          rotation=90)));
    Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod2(r=rh1)
      annotation (Placement(transformation(extent={{-40,-50},{-20,-30}},
            rotation=0)));
    Modelica.Mechanics.Rotational.Interfaces.Flange_a r1_axis
      "1-dim. rotational flange that drives the joint"
      annotation (Placement(transformation(extent={{-110,-10},{-90,10}},
            rotation=0)));

  equation
    connect(world.frame_b, r1.frame_a)  annotation (Line(
        points={{-60,-40},{-50,-40},{-50,-10}},
        color={95,95,95},
        thickness=0.5));
    connect(rod1.frame_a, r1.frame_b)
      annotation (Line(
        points={{-50,20},{-50,10}},
        color={0,0,0},
        thickness=0.5));
    connect(rod2.frame_a, world.frame_b)
      annotation (Line(
        points={{-40,-40},{-60,-40}},
        color={95,95,95},
        thickness=0.5));
    connect(r1.axis, r1_axis)
      annotation (Line(points={{-60,6.12323e-016},{-90,6.12323e-016},{-90,0},{
            -100,0}}, color={0,0,0}));
    annotation (
      experiment(StopTime=5),
      Documentation(info="<html>

</html>"),
      Diagram(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={2,2},
          initialScale=0.1), graphics),
      Icon(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={2,2},
          initialScale=0.1), graphics={
          Bitmap(extent={{-80,90},{100,-80}}, fileName="loop.png"),
          Line(points={{-104,0},{-76,0},{-76,-51},{-63,-51}}, color={0,0,0}),
          Text(
            extent={{-124,122},{138,84}},
            lineColor={0,0,255},
            textString="%name")}));
  end PartialPlanarLoop;

  model PlanarLoop1 "PlanarLoop1: direct modeling with 4 revolute joints"
    extends FourBar.PartialPlanarLoop;

    Modelica.Mechanics.MultiBody.Joints.Revolute r2
      annotation (Placement(transformation(extent={{-30,40},{-10,60}}, rotation=
             0)));
    Modelica.Mechanics.MultiBody.Parts.BodyShape bodyShape(
      m=1,
      r=rh2,
      r_CM=rh2/2)
      annotation (Placement(transformation(extent={{6,40},{26,60}}, rotation=0)));
    Modelica.Mechanics.MultiBody.Joints.Revolute r3
      annotation (Placement(transformation(extent={{40,40},{60,60}}, rotation=0)));
    Modelica.Mechanics.MultiBody.Joints.RevolutePlanarLoopConstraint r4
      annotation (Placement(transformation(extent={{40,-50},{60,-30}}, rotation=
             0)));
    Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod3(r=rv2)
      annotation (Placement(transformation(
          origin={70,0},
          extent={{-10,-10},{10,10}},
          rotation=90)));
  equation
    connect(r2.frame_b, bodyShape.frame_a) annotation (Line(
        points={{-10,50},{6,50}},
        color={95,95,95},
        thickness=0.5));
    connect(rod1.frame_b, r2.frame_a) annotation (Line(
        points={{-50,40},{-50,50},{-30,50}},
        color={95,95,95},
        thickness=0.5));
    connect(bodyShape.frame_b, r3.frame_a) annotation (Line(
        points={{26,50},{40,50}},
        color={95,95,95},
        thickness=0.5));
    connect(rod2.frame_b, r4.frame_a) annotation (Line(
        points={{-20,-40},{40,-40}},
        color={95,95,95},
        thickness=0.5));
    connect(r4.frame_b, rod3.frame_a) annotation (Line(
        points={{60,-40},{70,-40},{70,-10}},
        color={95,95,95},
        thickness=0.5));
    connect(rod3.frame_b, r3.frame_b) annotation (Line(
        points={{70,10},{70,50},{60,50}},
        color={95,95,95},
        thickness=0.5));
    annotation (
      experiment(StopTime=5),
      Documentation(info="<html>

</html>"),
      Diagram(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics),
      Icon(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={Text(
            extent={{-53,19},{54,-4}},
            lineColor={0,0,0},
            textString="loop 1")}));

  end PlanarLoop1;

  model PlanarLoop2 "PlanarLoop2: modeling with SphericalSpherical joint"
    extends FourBar.PartialPlanarLoop;

    Modelica.Mechanics.MultiBody.Joints.Revolute r4
      annotation (Placement(transformation(extent={{40,-50},{60,-30}}, rotation=
             0)));
    Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod3(r=rv2)
      annotation (Placement(transformation(
          origin={70,0},
          extent={{-10,-10},{10,10}},
          rotation=90)));
    Modelica.Mechanics.MultiBody.Joints.SphericalSpherical sphericalSpherical(
                               m=1,
      computeRodLength=false,
      rodLength=sqrt(rh2*rh2)) annotation (Placement(transformation(extent={{-8,
              40},{12,60}}, rotation=0)));
  equation
    connect(rod2.frame_b, r4.frame_a) annotation (Line(
        points={{-20,-40},{40,-40}},
        color={95,95,95},
        thickness=0.5));
    connect(r4.frame_b, rod3.frame_a) annotation (Line(
        points={{60,-40},{70,-40},{70,-10}},
        color={95,95,95},
        thickness=0.5));
    connect(rod1.frame_b, sphericalSpherical.frame_a) annotation (Line(
        points={{-50,40},{-50,50},{-8,50}},
        color={95,95,95},
        thickness=0.5));
    connect(sphericalSpherical.frame_b, rod3.frame_b) annotation (Line(
        points={{12,50},{70,50},{70,10}},
        color={95,95,95},
        thickness=0.5));
    annotation (
      experiment(StopTime=5),
      Documentation(info="<html>

</html>"),
      Diagram(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics),
      Icon(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={2,2}), graphics={Text(
            extent={{-53,19},{54,-4}},
            lineColor={0,0,0},
            textString="loop 2")}));
  end PlanarLoop2;

  model PlanarLoop3 "PlanarLoop3: using analytic loop handling"
    extends FourBar.PartialPlanarLoop;

    Modelica.Mechanics.MultiBody.Joints.Assemblies.JointRRR jointRRR1(
      rRod1_ia=rh2,
      rRod2_ib=rv2)         annotation (Placement(transformation(
          origin={20,0},
          extent={{-20,-20},{20,20}},
          rotation=270)));
    Modelica.Mechanics.MultiBody.Parts.Body body1(
      m=1,
      cylinderColor={155,155,155},
      r_CM=rh2/2)
      annotation (Placement(transformation(
          origin={46,60},
          extent={{-10,-10},{10,10}},
          rotation=90)));
  equation
    connect(jointRRR1.frame_ia, body1.frame_a) annotation (Line(
        points={{40,16},{46,16},{46,50}},
        color={95,95,95},
        thickness=0.5));
    connect(rod1.frame_b, jointRRR1.frame_a) annotation (Line(
        points={{-50,40},{-50,50},{20,50},{20,20}},
        color={95,95,95},
        thickness=0.5));
    connect(rod2.frame_b, jointRRR1.frame_b) annotation (Line(
        points={{-20,-40},{20,-40},{20,-20}},
        color={95,95,95},
        thickness=0.5));

    annotation (
      experiment(StopTime=5),
      Documentation(info="<html>

</html>"),
      Diagram(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={1,1}), graphics),
      Icon(coordinateSystem(
          preserveAspectRatio=false,
          extent={{-100,-100},{100,100}},
          grid={1,1}), graphics={Text(
            extent={{-50,17},{57,-6}},
            lineColor={0,0,0},
            textString="loop 3")}));
  end PlanarLoop3;

  model TestPlanarLoops

    Modelica.Mechanics.Rotational.Sources.Position position(useSupport=false, w(fixed=
            true))
      annotation (Placement(transformation(extent={{-40,0},{-20,20}}, rotation=
              0)));
    Modelica.Blocks.Sources.Sine sine(amplitude=0.7, freqHz=1)
      annotation (Placement(transformation(extent={{-80,0},{-60,20}}, rotation=
              0)));
    replaceable PlanarLoop3 planarLoop constrainedby PartialPlanarLoop
      annotation (Placement(transformation(extent={{0,0},{20,20}})));
  equation
    connect(sine.y, position.phi_ref) annotation (Line(points={{-59,10},{-42,10}},
          color={0,0,127}));
    connect(position.flange, planarLoop.r1_axis) annotation (Line(
        points={{-20,10},{0,10}},
        color={0,0,0},
        smooth=Smooth.None));
    annotation (
      Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
              100,100}}),
              graphics),
      experiment(StopTime=5),
      experimentSetupOutput);
  end TestPlanarLoops;
  annotation (uses(Modelica(version="3.2.2")));
end FourBar;

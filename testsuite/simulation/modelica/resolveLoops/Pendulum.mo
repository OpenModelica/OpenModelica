within ;
package Pendulum
  model NPendulum
    constant Integer N = 10;
    parameter Modelica.SIunits.RotationalDampingConstant d = 0.1 annotation(Evaluate=true);
    parameter Modelica.SIunits.Length l = 1
     annotation(Evaluate=true);

    Modelica.SIunits.Angle phi[N] = revolute.phi;
    Modelica.SIunits.Angle w[N] = revolute.w;

  protected
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute[N](
      each useAxisFlange=true,
      each phi(start=0, fixed=true),
      each w(start=0, fixed=true),
      each animation=false)
      annotation (Placement(transformation(extent={{-60,0},{-40,20}})));
    inner Modelica.Mechanics.MultiBody.World world
      annotation (Placement(transformation(extent={{-100,0},{-80,20}})));
    Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder[N](each r={l/N,0,0},
        each diameter=l/20)
      annotation (Placement(transformation(extent={{-20,0},{0,20}})));
  equation
    connect(world.frame_b, revolute[1].frame_a) annotation (Line(
        points={{-80,10},{-60,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(revolute[1:N].frame_b, bodyCylinder[1:N].frame_a) annotation (Line(
        points={{-40,10},{-20,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(bodyCylinder[1:N-1].frame_b, revolute[2:N].frame_a) annotation (Line(
        points={{0,10},{10,10},{10,-12},{-70,-12},{-70,10},{-60,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    annotation (                               Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics),
      experiment(StopTime=10));
  end NPendulum;

  model Pendulum2
    constant Integer N = 2;
    parameter Modelica.SIunits.RotationalDampingConstant d = 0.1 annotation(Evaluate=true);
    parameter Modelica.SIunits.Length l = 1
     annotation(Evaluate=true);

    Modelica.SIunits.Angle phi[N] = revolute.phi;
    Modelica.SIunits.Angle w[N] = revolute.w;

  protected
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute[N](
      each useAxisFlange=true,
      each phi(start=0, fixed=true),
      each w(start=0, fixed=true),
      each animation=false)
      annotation (Placement(transformation(extent={{-60,0},{-40,20}})));
    inner Modelica.Mechanics.MultiBody.World world
      annotation (Placement(transformation(extent={{-100,0},{-80,20}})));
    Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder[N](each r={l/N,0,0},
        each diameter=l/20)
      annotation (Placement(transformation(extent={{-20,0},{0,20}})));
  equation
    connect(world.frame_b, revolute[1].frame_a) annotation (Line(
        points={{-80,10},{-60,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(revolute[1:N].frame_b, bodyCylinder[1:N].frame_a) annotation (Line(
        points={{-40,10},{-20,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(bodyCylinder[1:N-1].frame_b, revolute[2:N].frame_a) annotation (Line(
        points={{0,10},{10,10},{10,-12},{-70,-12},{-70,10},{-60,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    annotation (                               Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics),
      experiment(StopTime=10));
  end Pendulum2;

  model Pendulum3
    constant Integer N = 3;
    parameter Modelica.SIunits.RotationalDampingConstant d = 0.1 annotation(Evaluate=true);
    parameter Modelica.SIunits.Length l = 1
     annotation(Evaluate=true);

    Modelica.SIunits.Angle phi[N] = revolute.phi;
    Modelica.SIunits.Angle w[N] = revolute.w;

  protected
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute[N](
      each useAxisFlange=true,
      each phi(start=0, fixed=true),
      each w(start=0, fixed=true),
      each animation=false)
      annotation (Placement(transformation(extent={{-60,0},{-40,20}})));
    inner Modelica.Mechanics.MultiBody.World world
      annotation (Placement(transformation(extent={{-100,0},{-80,20}})));
    Modelica.Mechanics.MultiBody.Parts.BodyCylinder bodyCylinder[N](each r={l/N,0,0},
        each diameter=l/20)
      annotation (Placement(transformation(extent={{-20,0},{0,20}})));
  equation
    connect(world.frame_b, revolute[1].frame_a) annotation (Line(
        points={{-80,10},{-60,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(revolute[1:N].frame_b, bodyCylinder[1:N].frame_a) annotation (Line(
        points={{-40,10},{-20,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    connect(bodyCylinder[1:N-1].frame_b, revolute[2:N].frame_a) annotation (Line(
        points={{0,10},{10,10},{10,-12},{-70,-12},{-70,10},{-60,10}},
        color={95,95,95},
        thickness=0.5,
        smooth=Smooth.None));
    annotation (                               Diagram(coordinateSystem(
            preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics),
      experiment(StopTime=10));
  end Pendulum3;
end Pendulum;

within ;
model revoluteConstraint
  inner Modelica.Mechanics.MultiBody.World world
    annotation (Placement(transformation(extent={{-100,46},{-80,66}})));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation cs_achsschenkel_R(
                  r={0,-0.760,-0.115}, animation=false)
    annotation (Placement(transformation(extent={{-4,90},{32,126}})));
  Modelica.Mechanics.MultiBody.Parts.FixedTranslation cs_lenkkolben(animation=
        false, r={-0.180,-0.34,-0.115})
    annotation (Placement(transformation(extent={{-34,-2},{-12,20}})));
  Modelica.Mechanics.MultiBody.Parts.BodyShape bd_achsschenkel_R(
    m=259.1,
    r={0,0,0},
    r_CM={-0.001,-0.135,0},
    I_11=4.892,
    I_22=6.270,
    I_33=4.607,
    I_21=-0.035,
    I_31=-0.016,
    I_32=0.020,
    useQuaternions=true,
    enforceStates=false,
    lengthDirection={1,0,0},
    color={200,0,0},
    animation=false)
    annotation (Placement(transformation(extent={{254,96},{278,120}})));
  Modelica.Mechanics.MultiBody.Joints.Assemblies.JointRRR planares_dreigelenk_R(
    n_a={0,0,1},
    rRod2_ib={-0.180,0.041,0},
    phi_offset=0,
    animation=false,
    phi_guess=0,
    rRod1_ia={0,-0.379,0}) annotation (Placement(transformation(
        extent={{20,-20},{-20,20}},
        rotation=-90,
        origin={176,68})));
  Modelica.Mechanics.MultiBody.Parts.BodyShape bd_spurstange_R(
    r_CM={0,-0.189,0},
    m=3.1,
    I_11=0.049,
    I_22=0.001,
    I_33=0.050,
    I_21=0,
    I_31=0,
    I_32=0,
    r={0,0,0},
    useQuaternions=true,
    enforceStates=false,
    lengthDirection={1,0,0},
    color={200,0,0},
    animation=false)
    annotation (Placement(transformation(extent={{224,40},{246,62}})));
equation
  connect(cs_achsschenkel_R.frame_b,planares_dreigelenk_R. frame_b) annotation (
     Line(
      points={{32,108},{176,108},{176,88}},
      color={95,95,95},
      thickness=0.5,
      smooth=Smooth.None));
  connect(planares_dreigelenk_R.frame_ia,bd_spurstange_R. frame_a) annotation (
      Line(
      points={{196,52},{208,52},{208,51},{224,51}},
      color={95,95,95},
      thickness=0.5,
      smooth=Smooth.None));
  connect(cs_lenkkolben.frame_a, world.frame_b) annotation (Line(
      points={{-34,9},{-44,9},{-44,56},{-80,56}},
      color={95,95,95},
      thickness=0.5,
      smooth=Smooth.None));
  connect(cs_achsschenkel_R.frame_a, world.frame_b) annotation (Line(
      points={{-4,108},{-42,108},{-42,56},{-80,56}},
      color={95,95,95},
      thickness=0.5,
      smooth=Smooth.None));
  connect(bd_achsschenkel_R.frame_a, planares_dreigelenk_R.frame_ib)
    annotation (Line(
      points={{254,108},{226,108},{226,84},{196,84}},
      color={95,95,95},
      thickness=0.5,
      smooth=Smooth.None));
  connect(cs_lenkkolben.frame_b, planares_dreigelenk_R.frame_a) annotation (
      Line(
      points={{-12,9},{82,9},{82,8},{176,8},{176,48}},
      color={95,95,95},
      thickness=0.5,
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics), uses(Modelica(version="3.2.1")));
end revoluteConstraint;

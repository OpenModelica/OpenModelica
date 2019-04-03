within ;
package PlanarMechanicsForTesting
  "A planar mechanical library for didactical purposes"

  import SI = Modelica.SIunits;
  import MB = Modelica.Mechanics.MultiBody;

  model World
    parameter SI.Acceleration g[2] = {0,-9.81} "Gravity Accleration";
    parameter Boolean animation = true
      "Enable Animation as default for components";
    annotation(defaultComponentPrefixes="inner",defaultComponentName="world",
      Icon(graphics={
          Rectangle(
            extent={{-100,100},{100,-100}},
            lineColor={0,0,0},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-100,-118},{-100,61}},
            color={0,0,0},
            thickness=0.5),
          Polygon(
            points={{-100,100},{-120,60},{-80,60},{-100,100},{-100,100}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Line(
            points={{-119,-100},{59,-100}},
            color={0,0,0},
            thickness=0.5),
          Polygon(
            points={{99,-100},{59,-80},{59,-120},{99,-100}},
            lineColor={0,0,0},
            fillColor={0,0,0},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-150,145},{150,105}},
            textString="%name",
            lineColor={0,0,0}),
          Line(points={{-56,78},{-56,-26}}, color={0,0,255}),
          Polygon(
            points={{-68,-26},{-56,-66},{-44,-26},{-68,-26}},
            fillColor={0,0,255},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Line(points={{2,78},{2,-26}}, color={0,0,255}),
          Polygon(
            points={{-10,-26},{2,-66},{14,-26},{-10,-26}},
            fillColor={0,0,255},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Line(points={{66,80},{66,-26}}, color={0,0,255}),
          Polygon(
            points={{54,-26},{66,-66},{78,-26},{54,-26}},
            fillColor={0,0,255},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255})}));
  end World;

  package Interfaces
    connector Frame "General Connector for planar mechanical components"
      SI.Position x "x-position";
      SI.Position y "y-position";
      SI.Angle phi "angle (clockwise)";
      flow SI.Force fx "force in x-direction";
      flow SI.Force fy "force in y-direction";
      flow SI.Torque t "torque (clockwise)";
    end Frame;

    connector Frame_a
      extends Frame;
      annotation (Icon(graphics={
            Rectangle(
              extent={{-40,100},{40,-100}},
              lineColor={95,95,95},
              fillColor={203,237,255},
              fillPattern=FillPattern.Solid,
              lineThickness=0.5),
            Line(
              points={{-18,0},{22,0}},
              color={95,95,95},
              smooth=Smooth.None),
            Line(
              points={{0,20},{0,-20}},
              color={95,95,95},
              smooth=Smooth.None)}));
    end Frame_a;

    connector Frame_b
      extends Frame;
      annotation (Icon(graphics={
            Rectangle(
              extent={{-40,100},{40,-100}},
              lineColor={95,95,95},
              fillColor={85,170,255},
              fillPattern=FillPattern.Solid,
              lineThickness=0.5),
            Line(
              points={{-18,0},{22,0}},
              color={95,95,95},
              smooth=Smooth.None),
            Line(
              points={{0,20},{0,-20}},
              color={95,95,95},
              smooth=Smooth.None)}));
    end Frame_b;

    model PlanarToMultiBody
      "This model enables to connect planar models to 3D Models"

      Frame_a frame_a annotation (Placement(transformation(extent={{-46,-8},{-26,12}}),
            iconTransformation(extent={{-48,-20},{-8,20}})));
      MB.Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{6,
                -16},{38,16}}), iconTransformation(extent={{8,-16},{40,16}})));

    protected
      SI.Force fz "Normal Force";
      SI.Force f0[3] "Force vector";

    equation
      //connect the translatory position w.r.t inertial system
      frame_a.x = frame_b.r_0[1];
      frame_a.y = frame_b.r_0[2];
      0 = frame_b.r_0[3];

      //Express 3D-rotation as planar rotation around z-axes
      MB.Frames.planarRotation({0,0,1},-frame_a.phi, -der(frame_a.phi)) = frame_b.R;

      //define force vector
      f0 = {frame_a.fx, frame_a.fy, fz};
      //the MulitBody force vector is resolved within the body system
      f0*frame_b.R.T + frame_b.f = zeros(3);

      //connect the torque
      -frame_a.t + frame_b.t[3] = 0;

      //This element determines the orientation matrix fully, hence it is a "root-element"
      Connections.root(frame_b.R);

      annotation (Icon(graphics={Line(
              points={{-18,0},{16,0}},
              color={95,95,95},
              smooth=Smooth.None,
              thickness=0.5)}), Diagram(graphics));
    end PlanarToMultiBody;
  end Interfaces;

  package Parts
    model Body "Body component with mass and inertia"

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,2},{-80,22}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));

      parameter SI.Mass m "mass of the body";
      parameter SI.Inertia I "Inertia of the Body";

      parameter SI.Acceleration g[2] = {0,0} "local gravity acting on the mass";

      SI.Force f[2] "force";
      SI.Position r[2] "transl. position";
      SI.Velocity v[2] "velocity";
      SI.Acceleration a[2] "acceleration";

      SI.AngularVelocity w "angular velocity";
      SI.AngularAcceleration z "angular acceleration";

      parameter Boolean animate = true "enable Animation"
                                                         annotation(Dialog(group="Animation"));

      //Visualization
      MB.Visualizers.Advanced.Shape sphere(
        shapeType="sphere",
        color={63,63,255},
        specularCoefficient=0.5,
        length=0.15,
        width=0.15,
        height=0.15,
        lengthDirection={0,0,1},
        widthDirection={1,0,0},
        r_shape={0,0,-0.075},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.nullRotation()) if animate;

    equation
      //The velocity is a time-derivative of the position
      r = {frame_a.x, frame_a.y};
      v = der(r);
      w = der(frame_a.phi);

      //The acceleration is a time-derivative of the velocity
      a = der(v);
      z = der(w);

      //Newton's law
      f = {frame_a.fx, frame_a.fy};
      f + m*g = m*a;
      frame_a.t = I*z;

      annotation (Icon(graphics={
            Rectangle(
              extent={{-100,40},{-20,-40}},
              lineColor={0,0,0},
              fillColor={85,170,255},
              fillPattern=FillPattern.HorizontalCylinder),
            Ellipse(
              extent={{-60,60},{60,-60}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255}),
            Text(
              extent={{-100,-80},{100,-120}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name")}), Diagram(graphics));
    end Body;

    model Fixed "FixedPosition"

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));

      parameter SI.Position r[2] = {0,0} "fixed x,y-position";
      parameter SI.Angle phi = 0 "fixed angle";

    equation
      {frame_a.x,frame_a.y} = r;
      frame_a.phi = phi;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-80},{100,-120}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"),
            Line(
              points={{-92,0},{0,0}},
              color={0,0,0},
              smooth=Smooth.None),
            Line(
              points={{0,80},{0,-80}},
              color={0,0,0},
              smooth=Smooth.None),
            Line(
              points={{0,40},{80,0}},
              color={0,0,0},
              smooth=Smooth.None),
            Line(
              points={{0,80},{80,40}},
              color={0,0,0},
              smooth=Smooth.None),
            Line(
              points={{0,0},{80,-40}},
              color={0,0,0},
              smooth=Smooth.None),
            Line(
              points={{0,-40},{80,-80}},
              color={0,0,0},
              smooth=Smooth.None)}), Diagram(graphics));
    end Fixed;

    model FixedTranslation
      "A fixed translation between two components (rigid rod)"

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));
      Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{80,0},{
                100,20}}),  iconTransformation(extent={{80,-20},{120,20}})));

      parameter SI.Length r[2] = {1,0}
        "length of the rod resolved w.r.t to body frame at phi = 0";
      final parameter SI.Length l = sqrt(r*r);
      SI.Length r0[2] "length of the rod resolved w.r.t to inertal frame";
      Real R[2,2] "Rotation matrix";

      parameter Boolean animate = true "enable Animation"
                                                         annotation(Dialog(group="Animation"));

      //Visualization
      MB.Visualizers.Advanced.Shape cylinder(
        shapeType="cylinder",
        color={128,128,128},
        specularCoefficient=0.5,
        length=l,
        width=0.1,
        height=0.1,
        lengthDirection={r0[1]/l,r0[2]/l,0},
        widthDirection={0,0,1},
        r_shape={0,0,0},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.nullRotation()) if  animate;

    equation
      //resolve the rod w.r.t inertial system
    //  sx0 = cos(frame_a.phi)*sx + sin(frame_a.phi)*sy;
    //  sy0 = -sin(frame_a.phi)*sx + cos(frame_a.phi)*sy;
      R = {{cos(frame_a.phi), sin(frame_a.phi)}, {-sin(frame_a.phi),cos(frame_a.phi)}};
      r0 = R*r;

      //rigidly connect positions
      frame_a.x + r0[1] = frame_b.x;
      frame_a.y + r0[2] = frame_b.y;
      frame_a.phi = frame_b.phi;

      //balance forces including lever principle
      frame_a.fx + frame_b.fx = 0;
      frame_a.fy + frame_b.fy = 0;
    //  frame_a.t + frame_b.t - sx0*frame_b.fy + sy0*frame_b.fx = 0;
      frame_a.t  + frame_b.t + r0*{-frame_b.fy,frame_b.fx} = 0;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-40},{100,-80}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"), Rectangle(
              extent={{-92,6},{92,-6}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Solid,
              fillColor={175,175,175})}), Diagram(graphics));
    end FixedTranslation;

    model FixedRotation
      "A fixed translation between two components (rigid rod)"

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));
      Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{80,0},{
                100,20}}),  iconTransformation(extent={{80,-20},{120,20}})));

      parameter SI.Angle alpha "fixed rotation angle";

    equation
      frame_a.x = frame_b.x;
      frame_a.y = frame_b.y;
      frame_a.phi + alpha = frame_b.phi;

      frame_a.fx + frame_b.fx = 0;
      frame_a.fy + frame_b.fy = 0;
      frame_a.t + frame_b.t = 0;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-40},{100,-80}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"),
            Polygon(
              points={{4,48},{92,8},{92,-12},{0,32},{-92,-10},{-92,8},{-6,48},{4,48}},
              lineColor={0,0,0},
              smooth=Smooth.None,
              fillColor={175,175,175},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-20,60},{20,20}},
              lineColor={0,0,0},
              fillColor={175,175,175},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-10,50},{10,30}},
              lineColor={255,255,255},
              fillColor={175,175,175},
              fillPattern=FillPattern.Solid,
              lineThickness=0.5)}),       Diagram(graphics));
    end FixedRotation;

  end Parts;

  package Joints "Planar joint models"
    model Revolute "A revolute joint "

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));
      Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{80,0},{
                100,20}}),  iconTransformation(extent={{80,-20},{120,20}})));

      parameter Boolean initialize = false "Initialize Position and Velocity";
      parameter SI.Angle phi_start = 0;
      parameter SI.AngularVelocity w_start = 0;

      parameter Boolean animate = true "enable Animation"
                                                         annotation(Dialog(group="Animation"));

      parameter Boolean enforceStates = false
        "enforce the state of the revolute to become the state of the total system"
                                                                                                            annotation(Dialog(group="Advanced"));

      SI.Angle phi(stateSelect = if enforceStates then StateSelect.always else StateSelect.prefer)
        "Angular position";
      SI.AngularVelocity w(stateSelect = if enforceStates then StateSelect.always else StateSelect.prefer)
        "Angular velocity";
      SI.AngularAcceleration z "Angular acceleration";
      SI.Torque t "Torque";

      //Visualization
      MB.Visualizers.Advanced.Shape cylinder(
        shapeType="cylinder",
        color={255,0,0},
        specularCoefficient=0.5,
        length=0.2,
        width=0.1,
        height=0.1,
        lengthDirection={0,0,1},
        widthDirection={1,0,0},
        r_shape={0,0,-0.05},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.nullRotation()) if  animate;

    initial equation

      //Initialization of Position and Velocity
      if initialize then
        phi = phi_start;
        w = w_start;
      end if;

    equation

      //Differential Equations
      w = der(phi);
      z = der(w);

      //No torque
      t = 0;

      //rigidly connect positions
      frame_a.x = frame_b.x;
      frame_a.y = frame_b.y;
      frame_a.phi + phi = frame_b.phi;

      //balance forces
      frame_a.fx + frame_b.fx = 0;
      frame_a.fy + frame_b.fy = 0;
      frame_a.t + frame_b.t = 0;
      frame_a.t = t;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-80},{100,-120}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"), Rectangle(
              extent={{-20,20},{20,-20}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175}),
                                   Rectangle(
              extent={{-100,60},{-20,-62}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175}),
                                   Rectangle(
              extent={{20,60},{100,-60}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175})}), Diagram(graphics));
    end Revolute;

    model Prismatic "A prismatic joint"

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));
      Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{80,0},{
                100,20}}),  iconTransformation(extent={{80,-20},{120,20}})));

      parameter SI.Distance r[2]
        "direction of the rod wrt. body system at phi=0";
      final parameter SI.Distance l = sqrt(r*r) "lengt of r";
      final parameter SI.Distance e[2]= r/l "normalized r";
      SI.Length s(stateSelect = if enforceStates then StateSelect.always else StateSelect.prefer)
        "Elongation of the joint";
      Real e0[2] "direction of the prismatic rod resolved wrt.inertial frame";
      SI.Length r0[2]
        "translation vector of the prismatic rod resolved wrt.inertial frame";
      Real R[2,2] "Rotation Matrix";

      SI.Velocity v(stateSelect = if enforceStates then StateSelect.always else StateSelect.prefer)
        "velocity of elongation";
      SI.Acceleration a "acceleration of elongation";
      SI.Force f "force in direction of elongation";

      parameter Boolean initialize = false "Initialize Position and Velocity";
      parameter SI.Length s_start = 0;
      parameter SI.Velocity v_start = 0;

      parameter Boolean animate = true "enable Animation"
                                                         annotation(Dialog(group="Animation"));

      parameter Boolean enforceStates = false
        "enforce the state of the prismatic joint to become the state of the total system";

      //Visualization
      MB.Visualizers.Advanced.Shape box(
        shapeType="box",
        color={255,63,63},
        specularCoefficient=0.5,
        length=s,
        width=0.1,
        height=0.1,
        lengthDirection={e0[1],e0[2],0},
        widthDirection={0,0,1},
        r_shape={0,0,0},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.nullRotation()) if  animate;

    initial equation

      //Initialization of Position and Velocity
     if initialize then
        s = s_start;
        v = v_start;
      end if;

    equation

      //resolve the rod w.r.t. inertial system
      R = {{cos(frame_a.phi), sin(frame_a.phi)}, {-sin(frame_a.phi),cos(frame_a.phi)}};
      e0 = R*e;
      r0 = e0*s;

      //differential equations
      v = der(s);
      a = der(v);
      f = 0;

      //rigidly connect positions
      frame_a.x + r0[1] = frame_b.x;
      frame_a.y + r0[2] = frame_b.y;
      frame_a.phi = frame_b.phi;

      //balance forces including lever principle
      frame_a.fx + frame_b.fx = 0;
      frame_a.fy + frame_b.fy = 0;
      frame_a.t  + frame_b.t + r0*{-frame_b.fy,frame_b.fx} = 0;
      {frame_a.fx,frame_a.fy}*e0 = 0;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-60},{100,-100}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"), Rectangle(
              extent={{-100,40},{-20,-40}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175}),
                                   Rectangle(
              extent={{-20,-20},{100,20}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175})}), Diagram(graphics));
    end Prismatic;

    model ActuatedRevolute "A revolute joint "

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));
      Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{80,0},{
                100,20}}),  iconTransformation(extent={{80,-20},{120,20}})));

      parameter Boolean initialize = false "Initialize Position and Velocity";
      parameter SI.Angle phi_start = 0;
      parameter SI.AngularVelocity w_start = 0;

      SI.Angle phi(stateSelect = if enforceStates then StateSelect.always else StateSelect.prefer)
        "Angular position";
      SI.AngularVelocity w(stateSelect = if enforceStates then StateSelect.always else StateSelect.prefer)
        "Angular velocity";
      SI.AngularAcceleration z "Angular acceleration";
      SI.Torque t "Torque";

      parameter Boolean animate = true "enable Animation"
                                                         annotation(Dialog(group="Animation"));

      parameter Boolean enforceStates = false
        "enforce the state of the prismatic joint to become the state of the total system";

      MB.Visualizers.Advanced.Shape cylinder(
        shapeType="cylinder",
        color={255,0,0},
        specularCoefficient=0.5,
        length=0.2,
        width=0.1,
        height=0.1,
        lengthDirection={0,0,1},
        widthDirection={1,0,0},
        r_shape={0,0,-0.05},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.nullRotation()) if  animate;

      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
          Placement(transformation(extent={{-20,80},{0,100}}), iconTransformation(
              extent={{-10,90},{10,110}})));
    initial equation
      if initialize then
        phi = phi_start;
        w = w_start;
      end if;

    equation

      //Differential Equations
      phi = flange_a.phi;
      w = der(phi);
      z = der(w);

      //Acturation Torque
      t = flange_a.tau;

      //rigidly connect positions
      frame_a.x = frame_b.x;
      frame_a.y = frame_b.y;
      frame_a.phi + phi = frame_b.phi;

      //balance forces
      frame_a.fx + frame_b.fx = 0;
      frame_a.fy + frame_b.fy = 0;
      frame_a.t + frame_b.t = 0;
      frame_a.t = t;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-80},{100,-120}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"), Rectangle(
              extent={{-20,20},{20,-20}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175}),
                                   Rectangle(
              extent={{-100,60},{-20,-62}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175}),
                                   Rectangle(
              extent={{20,60},{100,-60}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175}),
            Line(
              points={{0,80},{0,20}},
              color={0,0,0},
              smooth=Smooth.None)}),      Diagram(graphics));
    end ActuatedRevolute;

    model ActuatedPrismatic "A prismatic joint"

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));
      Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{80,0},{
                100,20}}),  iconTransformation(extent={{80,-20},{120,20}})));

      parameter SI.Distance r[2]
        "direction of the rod wrt. body system at phi=0";
      final parameter SI.Distance l = sqrt(r*r) "lengt of r";
      final parameter SI.Distance e[2]= r/l "normalized r";
      SI.Length s(stateSelect = if enforceStates then StateSelect.always else StateSelect.prefer)
        "Elongation of the joint";
      Real e0[2] "direction of the prismatic rod resolved wrt.inertial frame";
      SI.Length r0[2]
        "translation vector of the prismatic rod resolved wrt.inertial frame";
      Real R[2,2] "Rotation Matrix";

      SI.Velocity v(stateSelect = if enforceStates then StateSelect.always else StateSelect.prefer)
        "velocity of elongation";
      SI.Acceleration a "acceleration of elongation";
      SI.Force f "force in direction of elongation";

      parameter Boolean initialize = false "Initialize Position and Velocity";
      parameter SI.Length s_start = 0;
      parameter SI.Velocity v_start = 0;

      parameter Boolean animate = true "enable Animation"
                                                         annotation(Dialog(group="Animation"));

      parameter Boolean enforceStates = false
        "enforce the state of the prismatic joint to become the state of the total system";

      //Visualization
      MB.Visualizers.Advanced.Shape box(
        shapeType="box",
        color={255,63,63},
        specularCoefficient=0.5,
        length=s,
        width=0.1,
        height=0.1,
        lengthDirection={e0[1],e0[2],0},
        widthDirection={0,0,1},
        r_shape={0,0,0},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.nullRotation()) if  animate;

      Modelica.Mechanics.Translational.Interfaces.Flange_a flange_a annotation (
          Placement(transformation(extent={{-8,80},{12,100}}), iconTransformation(
              extent={{-10,80},{10,100}})));
    initial equation

      //Initialization of Position and Velocity
     if initialize then
        s = s_start;
        v = v_start;
      end if;

    equation

      //resolve the rod w.r.t. inertial system
      R = {{cos(frame_a.phi), sin(frame_a.phi)}, {-sin(frame_a.phi),cos(frame_a.phi)}};
      e0 = R*e;
      r0 = e0*s;

      //differential equations
      s = flange_a.s;
      v = der(s);
      a = der(v);

      //actuation force
      f = flange_a.f;

      //rigidly connect positions
      frame_a.x + r0[1] = frame_b.x;
      frame_a.y + r0[2] = frame_b.y;
      frame_a.phi = frame_b.phi;

      //balance forces including lever principle
      frame_a.fx + frame_b.fx = 0;
      frame_a.fy + frame_b.fy = 0;
      frame_a.t  + frame_b.t + r0*{-frame_b.fy,frame_b.fx} = 0;
      {frame_a.fx,frame_a.fy}*e0 = f;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-60},{100,-100}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"), Rectangle(
              extent={{-100,40},{-20,-40}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175}),
                                   Rectangle(
              extent={{-20,-20},{100,20}},
              lineColor={0,0,0},
              fillPattern=FillPattern.HorizontalCylinder,
              fillColor={175,175,175}),
            Line(
              points={{0,80},{0,20}},
              color={0,0,0},
              smooth=Smooth.None)}),      Diagram(graphics));
    end ActuatedPrismatic;

    model IdealRolling "A revolute joint "

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));

      parameter SI.Length R = 1.0 "Radius of the wheel";

      parameter Boolean initialize = false "Initialize Position and Velocity";
      parameter SI.Position x_start = 0;
      parameter SI.Angle phi_start = 0;
      parameter SI.AngularVelocity w_start = 0;

      parameter Boolean animate = true "enable Animation"
                                                         annotation(Dialog(group="Animation"));

      SI.Angle phi "Angular position";
      SI.AngularVelocity w "Angular velocity";
      SI.AngularAcceleration z "Angular acceleration";
      SI.Velocity vx "Velocity in x-direction";

      //Visualization
      MB.Visualizers.Advanced.Shape cylinder(
        shapeType="cylinder",
        color={255,0,0},
        specularCoefficient=0.5,
        length=0.06,
        width=2*R,
        height=2*R,
        lengthDirection={0,0,1},
        widthDirection={1,0,0},
        r_shape={0,0,-0.03},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.nullRotation()) if  animate;

      MB.Visualizers.Advanced.Shape rim1(
        shapeType="cylinder",
        color={195,195,195},
        specularCoefficient=0.5,
        length=R*2,
        width=0.1,
        height=0.1,
        lengthDirection={1,0,0},
        widthDirection={0,0,1},
        r_shape={-R,0,0},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.planarRotation({0,0,1},-phi,0)) if animate;

      MB.Visualizers.Advanced.Shape rim2(
        shapeType="cylinder",
        color={195,195,195},
        specularCoefficient=0.5,
        length=R*2,
        width=0.1,
        height=0.1,
        lengthDirection={1,0,0},
        widthDirection={0,0,1},
        r_shape={-R,0,0},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.planarRotation({0,0,1},-phi+Modelica.Constants.pi/2,0)) if animate;

    initial equation

      //Initialization of Position and Velocity
      if initialize then
        phi = phi_start;
        w = w_start;
        frame_a.x = x_start;
      end if;

    equation
      //Differential Equations
      phi = frame_a.phi;
      w = der(phi);
      z = der(w);
      vx = der(frame_a.x);

      //holonomic constraint
      frame_a.y = R;

      //non-holonomic constraint
      vx = w*R;

      //balance forces
      frame_a.fx*R = -frame_a.t;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-80},{100,-120}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"),
            Ellipse(
              extent={{-80,80},{80,-80}},
              pattern=LinePattern.None,
              fillColor={95,95,95},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,0}),
            Ellipse(
              extent={{-70,70},{70,-70}},
              pattern=LinePattern.None,
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,0}),
            Ellipse(
              extent={{-20,20},{20,-20}},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Line(
              points={{-20,0},{-92,0}},
              color={0,0,255},
              smooth=Smooth.None)}),      Diagram(graphics));
    end IdealRolling;

    model SlipBasedRolling "A revolute joint "

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));

      parameter SI.Length R = 1.0 "Radius of the wheel";

      parameter SI.Velocity vAdhesion "adhesion velocity";
      parameter SI.Velocity vSlide "sliding velocity";
      parameter Real mu_A "friction coefficient at adhesion";
      parameter Real mu_S "friction coefficient at sliding";

      parameter Boolean initialize = false "Initialize Position and Velocity";
      parameter SI.Position x_start = 0;
      parameter SI.Velocity vx_start = 0;
      parameter SI.Angle phi_start = 0;
      parameter SI.AngularVelocity w_start = 0;

      parameter Boolean animate = true "enable Animation"
                                                         annotation(Dialog(group="Animation"));

      SI.Angle phi "Angular position";
      SI.AngularVelocity w "Angular velocity";
      SI.AngularAcceleration z "Angular acceleration";
      SI.Velocity vx "Velocity in x-direction";

      SI.Force N "normal force";
      SI.Velocity v_slip "slip velocity";

      //Visualization
      MB.Visualizers.Advanced.Shape cylinder(
        shapeType="cylinder",
        color={255,0,0},
        specularCoefficient=0.5,
        length=0.06,
        width=2*R,
        height=2*R,
        lengthDirection={0,0,1},
        widthDirection={1,0,0},
        r_shape={0,0,-0.03},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.nullRotation()) if  animate;

      MB.Visualizers.Advanced.Shape rim1(
        shapeType="cylinder",
        color={195,195,195},
        specularCoefficient=0.5,
        length=R*2,
        width=0.1,
        height=0.1,
        lengthDirection={1,0,0},
        widthDirection={0,0,1},
        r_shape={-R,0,0},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.planarRotation({0,0,1},-phi,0)) if animate;

      MB.Visualizers.Advanced.Shape rim2(
        shapeType="cylinder",
        color={195,195,195},
        specularCoefficient=0.5,
        length=R*2,
        width=0.1,
        height=0.1,
        lengthDirection={1,0,0},
        widthDirection={0,0,1},
        r_shape={-R,0,0},
        r={frame_a.x,frame_a.y,0},
        R=MB.Frames.planarRotation({0,0,1},-phi+Modelica.Constants.pi/2,0)) if animate;

    initial equation

      //Initialization of Position and Velocity
      if initialize then
        phi = phi_start;
        w = w_start;
        frame_a.x = x_start;
        vx = vx_start;
      end if;

    equation
      //Differential Equations
      phi = frame_a.phi;
      w = der(phi);
      z = der(w);
      vx = der(frame_a.x);

      //holonomic constraint
      frame_a.y = R;

      //dry-friction law
      v_slip = vx - w*R;
      N = -frame_a.fy;
      frame_a.fx = N*noEvent(Utilities.TripleS_Func(vAdhesion,vSlide,mu_A,mu_S,v_slip));

      //balance forces
      frame_a.fx*R = -frame_a.t;

      annotation (Icon(graphics={
            Text(
              extent={{-100,-80},{100,-120}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"),
            Ellipse(
              extent={{-80,80},{80,-80}},
              pattern=LinePattern.None,
              fillColor={95,95,95},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,0}),
            Ellipse(
              extent={{-70,70},{70,-70}},
              pattern=LinePattern.None,
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,0}),
            Ellipse(
              extent={{-20,20},{20,-20}},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Line(
              points={{-20,0},{-92,0}},
              color={0,0,255},
              smooth=Smooth.None)}),      Diagram(graphics));
    end SlipBasedRolling;
  end Joints;

  package Forces "Force models... Spring and Dampers"
    model Damper "A fixed translation between two components (rigid rod)"

      Interfaces.Frame_a frame_a
        annotation (Placement(transformation(extent={{-100,0},{-80,20}}),
            iconTransformation(extent={{-120,-20},{-80,20}})));
      Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{80,0},{
                100,20}}),  iconTransformation(extent={{80,-20},{120,20}})));

      parameter SI.TranslationalDampingConstant d=1;
      SI.Length[2] r0;
      Real[2] d0;
      SI.Velocity vx;
      SI.Velocity vy;
      SI.Velocity v;
      SI.Force f;
    equation
      frame_a.x + r0[1] = frame_b.x;
      frame_b.y + r0[2] = frame_b.y;
      d0= Modelica.Math.Vectors.normalize(r0);
      der(frame_a.x) + vx = der(frame_b.x);
      der(frame_a.y) + vy = der(frame_b.y);
      v = {vx,vy}*d0;
      f = -d*v;
      frame_a.fx = d0[1] * f;
      frame_a.fy = d0[2] * f;
      frame_a.t = 0;
      frame_a.fx + frame_b.fx = 0;
      frame_a.fy + frame_b.fy = 0;
      frame_a.t + frame_b.t = 0;

    annotation(Dialog(group="Animation"),
                  Icon(graphics={
            Text(
              extent={{-100,-40},{100,-80}},
              lineColor={0,0,0},
              fillPattern=FillPattern.Sphere,
              fillColor={85,170,255},
              textString="%name"),
            Line(points={{-60,30},{60,30}}, color={0,0,0}),
            Line(points={{-60,-30},{60,-30}}, color={0,0,0}),
            Line(points={{30,0},{100,0}}, color={0,0,0}),
            Line(points={{-101,0},{-60,0}}, color={0,0,0}),
            Rectangle(
              extent={{-60,30},{30,-30}},
              lineColor={0,0,0},
              fillColor={192,192,192},
              fillPattern=FillPattern.Solid)}),
                                          Diagram(graphics));
    end Damper;

    model AbsoluteForce

      Interfaces.Frame_b frame_b
        annotation (Placement(transformation(extent={{80,-20},{120,20}})));
      Modelica.Blocks.Interfaces.RealInput u[2]
        annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
    equation
      {frame_b.fx,frame_b.fy} = u;
      frame_b.t = 0;
      annotation (Icon(graphics={
            Polygon(
              points={{-100,10},{20,10},{20,41},{90,0},{20,-41},{20,-10},{-100,-10},
                  {-100,10}},
              lineColor={0,127,0},
              fillColor={215,215,215},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-100,-40},{100,-80}},
              textString="%name",
              lineColor={0,0,0})}));
    end AbsoluteForce;
  end Forces;

  package Examples
    model FreeBody "AcceleratingBody"

      Parts.Body body(
        m=1,
        I=0.1,
        g={0,-9.81})
        annotation (Placement(transformation(extent={{0,0},{20,20}})));
      annotation (
        experiment(StopTime=3),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>A simple free falling body.</p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/FreeBody_1.png\"/></p>
<p><br/>The&nbsp;DAE&nbsp;has&nbsp;73&nbsp;scalar&nbsp;unknowns&nbsp;and&nbsp;73&nbsp;scalar&nbsp;equations.</p>
<p>Warning:&nbsp;The&nbsp;initial&nbsp;conditions&nbsp;for&nbsp;variables&nbsp;of&nbsp;type&nbsp;Real&nbsp;are&nbsp;not&nbsp;fully&nbsp;specified.</p>
<p>Assuming&nbsp;fixed&nbsp;default&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;body.frame_a.phi(start&nbsp;=&nbsp;0.0)</p><p>&nbsp;&nbsp;&nbsp;&nbsp;body.r[1](start&nbsp;=&nbsp;0.0)</p><p>&nbsp;&nbsp;&nbsp;&nbsp;body.r[2](start&nbsp;=&nbsp;0.0)</p><p>&nbsp;&nbsp;&nbsp;&nbsp;body.v[1](start&nbsp;=&nbsp;0.0)</p><p>&nbsp;&nbsp;&nbsp;&nbsp;body.v[2](start&nbsp;=&nbsp;0.0)</p><p>&nbsp;&nbsp;&nbsp;&nbsp;body.w(start&nbsp;=&nbsp;0.0)</p>
<p><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;body.frame_a.phi</p>
<p>&nbsp;&nbsp;body.r[1]</p>
<p>&nbsp;&nbsp;body.r[2]</p>
<p>&nbsp;&nbsp;body.v[1]</p>
<p>&nbsp;&nbsp;body.v[2]</p>
<p>&nbsp;&nbsp;body.w</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end FreeBody;

    model Pendulum "A free swinging pendulum"

      Parts.Body body(
        m=1,
        I=0.1,
        g={0,-9.81})
        annotation (Placement(transformation(extent={{40,-10},{60,10}})));
      Joints.Revolute revolute(initialize=true)
        annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
      Parts.FixedTranslation fixedTranslation(r= {1,0})
        annotation (Placement(transformation(extent={{0,-10},{20,10}})));
      Parts.Fixed fixed(phi=0) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-70,0})));
    equation
      connect(fixed.frame_a, revolute.frame_a) annotation (Line(
          points={{-60,-1.22465e-015},{-50,-1.22465e-015},{-50,0},{-40,0}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_b, fixedTranslation.frame_a) annotation (Line(
          points={{-20,0},{0,0}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation.frame_b, body.frame_a) annotation (Line(
          points={{20,0},{30,0},{30,0},{40,0}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=3),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>A free swinging pendulum</p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/Pendulum_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/Pendulum_2.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/Pendulum_3.png\"/></p>
<p><br/><br/><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end Pendulum;

    model DoublePendulum

      Parts.Body body(
        m=1,
        I=0.1,
        g={0,-9.81})
        annotation (Placement(transformation(extent={{20,60},{40,80}})));
      Joints.Revolute revolute(initialize=true)
        annotation (Placement(transformation(extent={{-60,60},{-40,80}})));
      Parts.FixedTranslation fixedTranslation(r={1,0})
        annotation (Placement(transformation(extent={{-20,60},{0,80}})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-90,70})));
      Parts.Body body1(
        g={0,-9.81},
        m=0.2,
        I=0.01)
        annotation (Placement(transformation(extent={{60,20},{80,40}})));
      Joints.Revolute revolute1(
                               initialize=true)
        annotation (Placement(transformation(extent={{-20,20},{0,40}})));
      Parts.FixedTranslation fixedTranslation1(r={0.4,0})
        annotation (Placement(transformation(extent={{20,20},{40,40}})));
    equation
      connect(fixed.frame_a, revolute.frame_a) annotation (Line(
          points={{-80,70},{-60,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_b, fixedTranslation.frame_a) annotation (Line(
          points={{-40,70},{-20,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation.frame_b, body.frame_a) annotation (Line(
          points={{0,70},{20,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute1.frame_b, fixedTranslation1.frame_a)
                                                          annotation (Line(
          points={{0,30},{20,30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation1.frame_b, body1.frame_a)
                                                      annotation (Line(
          points={{40,30},{60,30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute1.frame_a, fixedTranslation.frame_b) annotation (Line(
          points={{-20,30},{-32,30},{-32,50},{10,50},{10,70},{0,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=10),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>A double pendulum.</p>
<p><br/>Beware this is a chaotic system. However, the crazy part should start after 10s.</p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/DoublePendulum_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/DoublePendulum_2.png\"/></p>
<p><br/><br/><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
<p>&nbsp;&nbsp;revolute1.phi</p>
<p>&nbsp;&nbsp;revolute1.w</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end DoublePendulum;

    model CounterSpin
      Joints.SlipBasedRolling slipBasedRolling(
        R=0.1,
        initialize=true,
        x_start=0,
        phi_start=0,
        mu_A=0.4,
        mu_S=0.15,
        vx_start=2,
        w_start=-15,
        vAdhesion=0.01,
        vSlide=0.1)
        annotation (Placement(transformation(extent={{-10,0},{10,20}})));
      Parts.Body body(
        g={0,-9.81},
        animate=false,
        m=0.01,
        I=0.0005) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-50,10})));
    equation
      connect(body.frame_a, slipBasedRolling.frame_a) annotation (Line(
          points={{-40,10},{-25,10},{-25,10},{-10,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=3),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>Wheel with counter-spin and dry-friction law.</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/CounterSpin_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/CounterSpin_2.png\"/></p>
<p><br/>The model contains a large local stiffness before 2s</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/CounterSpin_3.png\"/></p>
<p><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;body.r[1]</p>
<p>&nbsp;&nbsp;body.v[1]</p>
<p>&nbsp;&nbsp;slipBasedRolling.phi</p>
<p>&nbsp;&nbsp;slipBasedRolling.w</p>
<p>&nbsp;</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end CounterSpin;

    model CraneCrab

      Parts.Body body(
        I=0.1,
        g={0,-9.81},
        m=0.5) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,-50})));
      Joints.Revolute revolute(initialize=true, phi_start=-2.7925268031909)
        annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,20})));
      Parts.FixedTranslation fixedTranslation(r={0,-1}) annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,-10})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-70,50})));
      Joints.Prismatic prismatic(r={1,0},
        initialize=true)
        annotation (Placement(transformation(extent={{-40,40},{-20,60}})));
      Parts.Body body1(
        m=1,
        I=0.1,
        g={0,-9.81})
        annotation (Placement(transformation(extent={{0,40},{20,60}})));
      Forces.Damper damper(d=5)
        annotation (Placement(transformation(extent={{-40,60},{-20,80}})));
    equation
      connect(revolute.frame_b, fixedTranslation.frame_a) annotation (Line(
          points={{-10,10},{-10,7.5},{-10,7.5},{-10,5},{-10,0},{-10,0}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation.frame_b, body.frame_a) annotation (Line(
          points={{-10,-20},{-10,-25},{-10,-25},{-10,-30},{-10,-40},{-10,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));

      connect(prismatic.frame_a, fixed.frame_a) annotation (Line(
          points={{-40,50},{-60,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(body1.frame_a, prismatic.frame_b) annotation (Line(
          points={{0,50},{-20,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_a, prismatic.frame_b) annotation (Line(
          points={{-10,30},{-10,50},{-20,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(damper.frame_b, body1.frame_a) annotation (Line(
          points={{-20,70},{-10,70},{-10,50},{0,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(damper.frame_a, fixed.frame_a) annotation (Line(
          points={{-40,70},{-50,70},{-50,50},{-60,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=10),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>A damped crane crab </p>
<p><img src=\"modelica://PlanarMechanicsForTesting/CraneCrab_1.png\"/></p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/CraneCrab_2.png\"/></p>
<p><br/><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;prismatic.s</p>
<p>&nbsp;&nbsp;prismatic.v</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end CraneCrab;

    model ControlledCraneCrab

      Parts.Body body(
        g={0,-9.81},
        m=70,
        I=0)   annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,-70})));
      Parts.FixedTranslation fixedTranslation(r={0,2.5})
                                                        annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,-30})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-70,30})));
      Parts.Body body1(
        g={0,-9.81},
        m=250,
        I=0)
        annotation (Placement(transformation(extent={{0,20},{20,40}})));
      Joints.ActuatedPrismatic actuatedPrismatic(r={1,0}, initialize=true)
        annotation (Placement(transformation(extent={{-40,20},{-20,40}})));
      Modelica.Mechanics.Rotational.Sensors.AngleSensor angleSensor
        annotation (Placement(transformation(extent={{20,-10},{40,10}})));
      Joints.ActuatedRevolute actuatedRevolute(initialize=true, phi_start=
            0.69813170079773) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,0})));
      Modelica.Mechanics.Translational.Sources.Force force annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-30,60})));
      Modelica.Blocks.Continuous.PID PID(
        Ti=1000000000000.0,
        k=320*9.81*5,
        Td=0.2) annotation (Placement(transformation(extent={{40,70},{20,90}})));
    equation
      connect(fixedTranslation.frame_b, body.frame_a) annotation (Line(
          points={{-10,-40},{-10,-45},{-10,-45},{-10,-50},{-10,-60},{-10,-60}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));

      connect(actuatedPrismatic.frame_a, fixed.frame_a) annotation (Line(
          points={{-40,30},{-60,30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedPrismatic.frame_b, body1.frame_a) annotation (Line(
          points={{-20,30},{0,30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedRevolute.frame_b, fixedTranslation.frame_a) annotation (
          Line(
          points={{-10,-10},{-10,-12.5},{-10,-12.5},{-10,-15},{-10,-20},{-10,
              -20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedRevolute.frame_a, body1.frame_a) annotation (Line(
          points={{-10,10},{-10,30},{0,30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedRevolute.flange_a, angleSensor.flange) annotation (Line(
          points={{0,-1.83697e-015},{10,-1.83697e-015},{10,0},{20,0}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(force.flange, actuatedPrismatic.flange_a) annotation (Line(
          points={{-30,50},{-30,44.5},{-30,44.5},{-30,39}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(force.f, PID.y) annotation (Line(
          points={{-30,72},{-30,80},{19,80}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(angleSensor.phi, PID.u) annotation (Line(
          points={{41,0},{70,0},{70,80},{42,80}},
          color={0,0,127},
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=3),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>A controlled crane crab. A simple PID (actually PD) controlles the pendulum into upright position.</p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/ControlledCraneCrab_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/ControlledCraneCrab_2.png\"/></p>
<p><br/>Warning:&nbsp;The&nbsp;initial&nbsp;conditions&nbsp;for&nbsp;variables&nbsp;of&nbsp;type&nbsp;Real&nbsp;are&nbsp;not&nbsp;fully&nbsp;specified.</p>
<p>Assuming&nbsp;fixed&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;PID.D.x(start&nbsp;=&nbsp;PID.D.x_start)</p>
<p>&nbsp;</p>
<p>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;actuatedPrismatic.s</p>
<p>&nbsp;&nbsp;actuatedPrismatic.v</p>
<p>&nbsp;&nbsp;actuatedRevolute.phi</p>
<p>&nbsp;&nbsp;actuatedRevolute.w</p>
<p>&nbsp;&nbsp;PID.D.x</p>
<p>&nbsp;&nbsp;PID.I.y</p>
<p>&nbsp;</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end ControlledCraneCrab;

    model InvertedCraneCrab

      Parts.Body body(
        I=0.1,
        g={0,-9.81},
        m=0.5) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,-70})));
      Parts.FixedTranslation fixedTranslation(r={0,1})  annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,-30})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-60,30})));
      Parts.Body body1(
        m=1,
        I=0.1,
        g={0,-9.81})
        annotation (Placement(transformation(extent={{0,20},{20,40}})));
      Joints.ActuatedPrismatic actuatedPrismatic(r={1,0},
        initialize=true)
        annotation (Placement(transformation(extent={{-40,20},{-20,40}})));
      Joints.ActuatedRevolute actuatedRevolute(initialize=false, phi_start=
            0.34906585039887) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,0})));
      Modelica.Mechanics.Translational.Sources.Force force
        annotation (Placement(transformation(extent={{0,60},{-20,80}})));
      Modelica.Mechanics.Rotational.Sensors.AngleSensor angleSensor
        annotation (Placement(transformation(extent={{8,-10},{28,10}})));
      Modelica.Blocks.Math.InverseBlockConstraints inverseBlockConstraints
        annotation (Placement(transformation(extent={{38,-20},{88,20}})));
      Modelica.Blocks.Sources.Ramp ramp(
        startTime=0,
        height=-0.5,
        offset=0.5,
        duration=0.5) annotation (Placement(transformation(
            extent={{-6,6},{6,-6}},
            rotation=180,
            origin={74,0})));
      Modelica.Blocks.Continuous.FirstOrder firstOrder(initType=Modelica.Blocks.Types.Init.SteadyState,
          T=0.1) annotation (Placement(transformation(extent={{62,-6},{50,6}})));
    equation

      connect(actuatedPrismatic.frame_a, fixed.frame_a) annotation (Line(
          points={{-40,30},{-50,30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedPrismatic.frame_b, body1.frame_a) annotation (Line(
          points={{-20,30},{0,30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedRevolute.frame_b, fixedTranslation.frame_a) annotation (
          Line(
          points={{-10,-10},{-10,-12.5},{-10,-12.5},{-10,-15},{-10,-20},{-10,
              -20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedRevolute.frame_a, body1.frame_a) annotation (Line(
          points={{-10,10},{-10,30},{0,30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(force.flange, actuatedPrismatic.flange_a) annotation (Line(
          points={{-20,70},{-30,70},{-30,39}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(angleSensor.flange, actuatedRevolute.flange_a) annotation (Line(
          points={{8,0},{4,0},{4,-1.83697e-015},{0,-1.83697e-015}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(inverseBlockConstraints.u1, angleSensor.phi) annotation (Line(
          points={{35.5,0},{29,0}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(inverseBlockConstraints.y1, force.f) annotation (Line(
          points={{89.25,0},{96,0},{96,70},{2,70}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(fixedTranslation.frame_b, body.frame_a) annotation (Line(
          points={{-10,-40},{-10,-45},{-10,-45},{-10,-50},{-10,-60},{-10,-60}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));

      connect(ramp.y, firstOrder.u) annotation (Line(
          points={{67.4,8.08267e-016},{64.7,8.08267e-016},{64.7,0},{63.2,0}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(firstOrder.y, inverseBlockConstraints.u2) annotation (Line(
          points={{49.4,0},{43,0}},
          color={0,0,127},
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=3),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>An inverted model of a pendulum. The trajectory is stipulated, the force is being measured.</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/InvertedCraneCrab_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/InvertedCraneCrab_2.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/InvertedCraneCrab_3.png\"/></p>
<p><br/><br/><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;actuatedPrismatic.s</p>
<p>&nbsp;&nbsp;actuatedPrismatic.v</p>
<p>&nbsp;&nbsp;actuatedRevolute.phi</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end InvertedCraneCrab;

    model WheelBasedCranCrab

      Joints.IdealRolling idealRolling(R=0.3, initialize=true)
                                              annotation (Placement(
            transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={-10,50})));
      Parts.Body body(
        m=1,
        I=0.1,
        g={0,-9.81})
        annotation (Placement(transformation(extent={{20,20},{40,40}})));
      Joints.Revolute revolute(initialize=true, phi_start=-1.3962634015955)
                               annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,10})));
      Parts.FixedTranslation fixedTranslation(r={1,0}) annotation (Placement(
            transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,-20})));
      Parts.Body body1(
        g={0,-9.81},
        m=2,
        I=0.2)       annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-10,-50})));
    equation
      connect(revolute.frame_a, idealRolling.frame_a) annotation (Line(
          points={{-10,20},{-10,30},{-10,30},{-10,40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(body.frame_a, idealRolling.frame_a) annotation (Line(
          points={{20,30},{-10,30},{-10,40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(body1.frame_a, fixedTranslation.frame_b) annotation (Line(
          points={{-10,-40},{-10,-37.5},{-10,-37.5},{-10,-35},{-10,-30},{-10,
              -30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation.frame_a, revolute.frame_b) annotation (Line(
          points={{-10,-10},{-10,-7.5},{-10,-7.5},{-10,-5},{-10,0},{-10,0}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=4.5),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>A pendulum mounted on an ideal rolling wheel.</p>
<p>This model contains non-holonomic constriants.</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/WheelBasedCranCrab_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/WheelBasedCranCrab_2.png\"/></p>
<p><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;body1.frame_a.phi</p>
<p>&nbsp;&nbsp;body1.r[1]</p>
<p>&nbsp;&nbsp;body1.w</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end WheelBasedCranCrab;

    model PistonEngine "A Piston Engine"

      Parts.Body bodyDrive(
        m=1,
        I=0.1,
        g={0,-9.81})
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-62,20})));
      Joints.Revolute revoluteDrive(
        initialize=true,
        phi_start=0,
        w_start=1,
        enforceStates=true)
        annotation (Placement(transformation(extent={{-70,40},{-50,60}})));
      Parts.FixedTranslation fixedTranslationDisc(r={0.3,0})
        annotation (Placement(transformation(extent={{-40,40},{-20,60}})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-90,50})));
      Joints.Prismatic prismatic(r={1,0})
        annotation (Placement(transformation(extent={{20,-60},{40,-40}})));
      Parts.Fixed fixed1   annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={70,-50})));
      Joints.Revolute revoluteDisc(initialize=false)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,30})));
      Parts.FixedTranslation pistonRod(r={0.8,0})
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,0})));
      Parts.Body bodyPiston(
        I=0.1,
        g={0,-9.81},
        m=3)
        annotation (Placement(transformation(extent={{30,-30},{50,-10}})));
      Joints.Revolute revolutePiston(initialize=false)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,-30})));
    equation
      connect(fixed.frame_a, revoluteDrive.frame_a)
                                               annotation (Line(
          points={{-80,50},{-70,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revoluteDrive.frame_b, fixedTranslationDisc.frame_a)
                                                          annotation (Line(
          points={{-50,50},{-40,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixed1.frame_a, prismatic.frame_b) annotation (Line(
          points={{60,-50},{40,-50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslationDisc.frame_b, revoluteDisc.frame_a) annotation (
          Line(
          points={{-20,50},{0,50},{0,40},{1.83697e-015,40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(bodyDrive.frame_a, revoluteDrive.frame_b) annotation (Line(
          points={{-52,20},{-44,20},{-44,50},{-50,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revoluteDisc.frame_b, pistonRod.frame_a) annotation (Line(
          points={{-1.83697e-015,20},{1.83697e-015,20},{1.83697e-015,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolutePiston.frame_b, pistonRod.frame_b) annotation (Line(
          points={{6.12323e-016,-20},{6.12323e-016,-12},{-1.83697e-015,-12},{
              -1.83697e-015,-10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(prismatic.frame_a, revolutePiston.frame_a) annotation (Line(
          points={{20,-50},{-6.12323e-016,-50},{-6.12323e-016,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(prismatic.frame_a, bodyPiston.frame_a) annotation (Line(
          points={{20,-50},{14,-50},{14,-20},{30,-20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        Documentation(info="<html>
<p>A PistonEngine</p>
<p>This example contains an algebraic loop. A non-linear system must be solved for initialization and at simulation.</p>
<p>In this version, the state are manually selected.</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/PistonEngine_1.png\"/></p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/PistonEngine_2.png\"/></p>
<p>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;revoluteDrive.phi</p>
<p>&nbsp;&nbsp;revoluteDrive.w</p>
<p>&nbsp;</p>
<p>Warning:&nbsp;The&nbsp;following&nbsp;variables&nbsp;are&nbsp;iteration&nbsp;variables&nbsp;of&nbsp;the&nbsp;initialization&nbsp;problem:</p>
<p>&nbsp;&nbsp;prismatic.s</p>
<p>&nbsp;&nbsp;revoluteDisc.frame_b.phi</p>
<p>&nbsp;</p>
<p>but&nbsp;they&nbsp;are&nbsp;not&nbsp;given&nbsp;any&nbsp;explicit&nbsp;start&nbsp;values.&nbsp;Zero&nbsp;will&nbsp;be&nbsp;used.</p>
<p>Finished</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"),
        experiment(StopTime=15),
        __Dymola_experimentSetupOutput);
    end PistonEngine;

    model PistonEngine_DynamicStateSelection "A Piston Engine"

      Parts.Body bodyDrive(
        m=1,
        I=0.1,
        g={0,-9.81})
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-62,20})));
      Joints.Revolute revoluteDrive(
        initialize=true,
        phi_start=0,
        w_start=1)
        annotation (Placement(transformation(extent={{-70,40},{-50,60}})));
      Parts.FixedTranslation fixedTranslationDisc(r={0.3,0})
        annotation (Placement(transformation(extent={{-40,40},{-20,60}})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-90,50})));
      Joints.Prismatic prismatic(r={1,0})
        annotation (Placement(transformation(extent={{20,-60},{40,-40}})));
      Parts.Fixed fixed1   annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={70,-50})));
      Joints.Revolute revoluteDisc(initialize=false)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,30})));
      Parts.FixedTranslation pistonRod(r={0.8,0})
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,0})));
      Parts.Body bodyPiston(
        I=0.1,
        g={0,-9.81},
        m=3)
        annotation (Placement(transformation(extent={{30,-30},{50,-10}})));
      Joints.Revolute revolutePiston(initialize=false)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,-30})));
    equation
      connect(fixed.frame_a, revoluteDrive.frame_a)
                                               annotation (Line(
          points={{-80,50},{-70,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revoluteDrive.frame_b, fixedTranslationDisc.frame_a)
                                                          annotation (Line(
          points={{-50,50},{-40,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixed1.frame_a, prismatic.frame_b) annotation (Line(
          points={{60,-50},{40,-50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslationDisc.frame_b, revoluteDisc.frame_a) annotation (
          Line(
          points={{-20,50},{0,50},{0,40},{1.83697e-015,40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(bodyDrive.frame_a, revoluteDrive.frame_b) annotation (Line(
          points={{-52,20},{-44,20},{-44,50},{-50,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revoluteDisc.frame_b, pistonRod.frame_a) annotation (Line(
          points={{-1.83697e-015,20},{1.83697e-015,20},{1.83697e-015,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolutePiston.frame_b, pistonRod.frame_b) annotation (Line(
          points={{6.12323e-016,-20},{6.12323e-016,-12},{-1.83697e-015,-12},{
              -1.83697e-015,-10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(prismatic.frame_a, revolutePiston.frame_a) annotation (Line(
          points={{20,-50},{-6.12323e-016,-50},{-6.12323e-016,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(prismatic.frame_a, bodyPiston.frame_a) annotation (Line(
          points={{20,-50},{14,-50},{14,-20},{30,-20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        Documentation(info="<html>
<p>A PistonEngine</p>
<p>This example contains an algebraic loop. A non-linear system must be solved for initialization and at simulation.</p>
<p>This version does not stipulate the state selection</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/PistonEngine_1.png\"/></p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/PistonEngine_2.png\"/></p>
<p><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p><br/>There&nbsp;are&nbsp;2&nbsp;sets&nbsp;of&nbsp;dynamic&nbsp;state&nbsp;selection.</p>
<p>From&nbsp;set&nbsp;1&nbsp;there&nbsp;is&nbsp;1&nbsp;state&nbsp;to&nbsp;be&nbsp;selected&nbsp;from:</p>
<p>&nbsp;&nbsp;prismatic.s</p>
<p>&nbsp;&nbsp;revoluteDisc.phi</p>
<p>&nbsp;&nbsp;revolutePiston.phi</p>
<p>&nbsp;</p>
<p>From&nbsp;set&nbsp;2&nbsp;there&nbsp;is&nbsp;1&nbsp;state&nbsp;to&nbsp;be&nbsp;selected&nbsp;from:</p>
<p>&nbsp;&nbsp;prismatic.v</p>
<p>&nbsp;&nbsp;revoluteDisc.w</p>
<p>&nbsp;&nbsp;revoluteDrive.w</p>
<p>&nbsp;</p>
<p>Warning:&nbsp;The&nbsp;following&nbsp;variables&nbsp;are&nbsp;iteration&nbsp;variables&nbsp;of&nbsp;the&nbsp;initialization&nbsp;problem:</p>
<p>&nbsp;&nbsp;prismatic.s</p>
<p>&nbsp;&nbsp;revoluteDisc.frame_b.phi</p>
<p>&nbsp;</p>
<p>but&nbsp;they&nbsp;are&nbsp;not&nbsp;given&nbsp;any&nbsp;explicit&nbsp;start&nbsp;values.&nbsp;Zero&nbsp;will&nbsp;be&nbsp;used.</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"),
        experiment(StopTime=15),
        __Dymola_experimentSetupOutput);
    end PistonEngine_DynamicStateSelection;

    model KinematicLoop

      Joints.Revolute revolute(phi(stateSelect=StateSelect.always), w(
            stateSelect=StateSelect.always))
                               annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-20,50})));
      Joints.Revolute revolute1 annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={80,50})));
      Joints.Revolute revolute2
        annotation (Placement(transformation(extent={{10,-10},{30,10}})));
      Joints.Revolute revolute3(
        initialize=true,
        w_start=0,
        phi_start=-0.69813170079773)
                     annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-20,-30})));
      Parts.FixedTranslation fixedTranslation1(r={0, -0.5}) annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-20,20})));
      Parts.FixedTranslation fixedTranslation2(r={0, -0.5}) annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={80,20})));
      Parts.FixedTranslation fixedTranslation3(r={0, -0.6}) annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={10,-50})));
      Parts.Body body(
        m=1,
        I=0.1,
        g={0,-9.81}) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={50,-50})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-50,70})));
      Joints.ActuatedPrismatic actuatedPrismatic(r={1,0},
        initialize=true,
        s_start=0.4,
        v_start=0)
        annotation (Placement(transformation(extent={{20,60},{40,80}})));
      Modelica.Mechanics.Translational.Components.SpringDamper springDamper(
        s_rel0=0.6,
        c=20,
        d=5) annotation (Placement(transformation(extent={{0,80},{20,100}})));
      Modelica.Mechanics.Translational.Components.Fixed fixed1 annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-46,90})));
    equation
      connect(fixedTranslation1.frame_a, revolute.frame_b) annotation (Line(
          points={{-20,30},{-20,32.5},{-20,32.5},{-20,35},{-20,40},{-20,40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation2.frame_a, revolute1.frame_b) annotation (Line(
          points={{80,30},{80,40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute2.frame_a, fixedTranslation1.frame_b) annotation (Line(
          points={{10,0},{-20,0},{-20,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute2.frame_b, fixedTranslation2.frame_b) annotation (Line(
          points={{30,0},{80,0},{80,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation3.frame_a, revolute3.frame_b) annotation (Line(
          points={{0,-50},{-20,-50},{-20,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedPrismatic.frame_b, revolute1.frame_a) annotation (Line(
          points={{40,70},{80,70},{80,60}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedPrismatic.frame_a, fixed.frame_a) annotation (Line(
          points={{20,70},{-40,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_a, fixed.frame_a) annotation (Line(
          points={{-20,60},{-20,70},{-40,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(springDamper.flange_b, actuatedPrismatic.flange_a) annotation (
          Line(
          points={{20,90},{30,90},{30,79}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(fixed1.flange, springDamper.flange_a) annotation (Line(
          points={{-46,90},{0,90}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(revolute3.frame_a, fixedTranslation1.frame_b) annotation (Line(
          points={{-20,-20},{-20,-12.5},{-20,-12.5},{-20,-5},{-20,10},{-20,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));

      connect(body.frame_a, fixedTranslation3.frame_b) annotation (Line(
          points={{40,-50},{20,-50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=6),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>Another example of a kinematic loop.</p>
<p>In this version, the states are manually selected:</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/KinematicLoop_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/KinematicLoop_2.png\"/></p>
<p><br/>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
<p>&nbsp;&nbsp;revolute3.phi</p>
<p>&nbsp;&nbsp;revolute3.w</p>
<p>&nbsp;</p>
<p>Warning:&nbsp;The&nbsp;following&nbsp;variables&nbsp;are&nbsp;iteration&nbsp;variables&nbsp;of&nbsp;the&nbsp;initialization&nbsp;problem:</p>
<p>&nbsp;&nbsp;revolute.frame_b.phi</p>
<p>&nbsp;&nbsp;revolute1.frame_b.phi</p>
<p>&nbsp;</p>
<p>but&nbsp;they&nbsp;are&nbsp;not&nbsp;given&nbsp;any&nbsp;explicit&nbsp;start&nbsp;values.&nbsp;Zero&nbsp;will&nbsp;be&nbsp;used.</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end KinematicLoop;

    model KinematicLoop_DynamicStateSelection

      Joints.Revolute revolute                        annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-20,50})));
      Joints.Revolute revolute1 annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={80,50})));
      Joints.Revolute revolute2
        annotation (Placement(transformation(extent={{10,-10},{30,10}})));
      Joints.Revolute revolute3(
        initialize=true,
        w_start=0,
        phi_start=-0.69813170079773)
                     annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-20,-30})));
      Parts.FixedTranslation fixedTranslation1(r={0, -0.5}) annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-20,20})));
      Parts.FixedTranslation fixedTranslation2(r={0, -0.5}) annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={80,20})));
      Parts.FixedTranslation fixedTranslation3(r={0, -0.6}) annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={10,-50})));
      Parts.Body body(
        m=1,
        I=0.1,
        g={0,-9.81}) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={50,-50})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-50,70})));
      Joints.ActuatedPrismatic actuatedPrismatic(r={1,0},
        initialize=true,
        s_start=0.4,
        v_start=0)
        annotation (Placement(transformation(extent={{20,60},{40,80}})));
      Modelica.Mechanics.Translational.Components.SpringDamper springDamper(
        s_rel0=0.6,
        c=20,
        d=5) annotation (Placement(transformation(extent={{0,80},{20,100}})));
      Modelica.Mechanics.Translational.Components.Fixed fixed1 annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-46,90})));
    equation
      connect(fixedTranslation1.frame_a, revolute.frame_b) annotation (Line(
          points={{-20,30},{-20,32.5},{-20,32.5},{-20,35},{-20,40},{-20,40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation2.frame_a, revolute1.frame_b) annotation (Line(
          points={{80,30},{80,40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute2.frame_a, fixedTranslation1.frame_b) annotation (Line(
          points={{10,0},{-20,0},{-20,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute2.frame_b, fixedTranslation2.frame_b) annotation (Line(
          points={{30,0},{80,0},{80,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation3.frame_a, revolute3.frame_b) annotation (Line(
          points={{0,-50},{-20,-50},{-20,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedPrismatic.frame_b, revolute1.frame_a) annotation (Line(
          points={{40,70},{80,70},{80,60}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedPrismatic.frame_a, fixed.frame_a) annotation (Line(
          points={{20,70},{-40,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_a, fixed.frame_a) annotation (Line(
          points={{-20,60},{-20,70},{-40,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(springDamper.flange_b, actuatedPrismatic.flange_a) annotation (
          Line(
          points={{20,90},{30,90},{30,79}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(fixed1.flange, springDamper.flange_a) annotation (Line(
          points={{-46,90},{0,90}},
          color={0,127,0},
          smooth=Smooth.None));
      connect(revolute3.frame_a, fixedTranslation1.frame_b) annotation (Line(
          points={{-20,-20},{-20,-12.5},{-20,-12.5},{-20,-5},{-20,10},{-20,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));

      connect(body.frame_a, fixedTranslation3.frame_b) annotation (Line(
          points={{40,-50},{20,-50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=6),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>Another example of a kinematic loop.</p>
<p>In this version, the states are manually selected:</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/KinematicLoop_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/KinematicLoop_2.png\"/></p>
<p>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;revolute3.phi</p>
<p>&nbsp;&nbsp;revolute3.w</p>
<p>&nbsp;</p>
<p>There&nbsp;are&nbsp;2&nbsp;sets&nbsp;of&nbsp;dynamic&nbsp;state&nbsp;selection.</p>
<p>From&nbsp;set&nbsp;1&nbsp;there&nbsp;is&nbsp;1&nbsp;state&nbsp;to&nbsp;be&nbsp;selected&nbsp;from:</p>
<p>&nbsp;&nbsp;actuatedPrismatic.s</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute2.phi</p>
<p>&nbsp;</p>
<p>From&nbsp;set&nbsp;2&nbsp;there&nbsp;is&nbsp;1&nbsp;state&nbsp;to&nbsp;be&nbsp;selected&nbsp;from:</p>
<p>&nbsp;&nbsp;actuatedPrismatic.v</p>
<p>&nbsp;&nbsp;revolute.w</p>
<p>&nbsp;&nbsp;revolute2.w</p>
<p>&nbsp;</p>
<p>Warning:&nbsp;The&nbsp;following&nbsp;variables&nbsp;are&nbsp;iteration&nbsp;variables&nbsp;of&nbsp;the&nbsp;initialization&nbsp;problem:</p>
<p>&nbsp;&nbsp;revolute.frame_b.phi</p>
<p>&nbsp;&nbsp;revolute1.frame_b.phi</p>
<p>&nbsp;</p>
<p>but&nbsp;they&nbsp;are&nbsp;not&nbsp;given&nbsp;any&nbsp;explicit&nbsp;start&nbsp;values.&nbsp;Zero&nbsp;will&nbsp;be&nbsp;used.</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end KinematicLoop_DynamicStateSelection;

    model TestIdealWheel

      VehicleComponents.Wheels.IdealWheelJoint idealWheelJoint(
        radius=0.3,
        r={1,0}) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,40})));
      Joints.Prismatic prismatic(
        r={0,1}, s(start=1, fixed=true))
                    annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,10})));
      Joints.Revolute revolute(enforceStates=true, w_start=0)
                               annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,-20})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,-50})));
      Modelica.Mechanics.Rotational.Sources.ConstantTorque engineTorque(
          tau_constant=2)
        annotation (Placement(transformation(extent={{-32,70},{-12,90}})));
      Parts.Body body(m=10, I=1)
        annotation (Placement(transformation(extent={{20,10},{40,30}})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia(
        phi(fixed=true, start=0),
        w(fixed=true, start=0),
        J=1)                    annotation (Placement(transformation(
            extent={{-10,10},{10,-10}},
            rotation=270,
            origin={0,70})));
    equation
      connect(idealWheelJoint.frame_a, prismatic.frame_b) annotation (Line(
          points={{-2.93915e-016,35.2},{-2.93915e-016,38.6},{6.12323e-016,38.6},
              {6.12323e-016,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(prismatic.frame_a, revolute.frame_b) annotation (Line(
          points={{-6.12323e-016,0},{6.12323e-016,0},{6.12323e-016,-10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_a, fixed.frame_a) annotation (Line(
          points={{-6.12323e-016,-30},{1.83697e-015,-30},{1.83697e-015,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(engineTorque.flange, inertia.flange_a) annotation (Line(
          points={{-12,80},{1.83697e-015,80}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(inertia.flange_b, idealWheelJoint.flange_a) annotation (Line(
          points={{-1.83697e-015,60},{0,52},{6.12323e-016,50}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(body.frame_a, prismatic.frame_b) annotation (Line(
          points={{20,20},{6.12323e-016,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=10),
        __Dymola_experimentSetupOutput,
      Documentation(info="<html>
<p>This is an ideal wheel. It introduces one non-holonomic constraint. Difficult for index-reduction.</p>
<p><br/><br/><img src=\"modelica://PlanarMechanicsForTesting/TestIdealWheel_1.png\"/></p>
<p><br/><br/><img src=\"modelica://PlanarMechanicsForTesting/TestIdealWheel_2.png\"/></p>
<p>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;inertia.phi</p>
<p>&nbsp;&nbsp;prismatic.s</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
<p>&nbsp;Warning:&nbsp;The&nbsp;following&nbsp;variables&nbsp;are&nbsp;iteration&nbsp;variables&nbsp;of&nbsp;the&nbsp;initialization&nbsp;problem:</p>
<p>&nbsp;&nbsp;body.frame_a.phi</p>
<p>&nbsp;&nbsp;der(prismatic.s)</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end TestIdealWheel;

    model TestDryFrictionWheel

      Joints.Prismatic prismatic(
        r={0,1},
        s(start=1)) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,10})));
      Joints.Revolute revolute annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,-20})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,-50})));
      Modelica.Mechanics.Rotational.Sources.ConstantTorque engineTorque(
          tau_constant=2)
        annotation (Placement(transformation(extent={{-32,70},{-12,90}})));
      Parts.Body body(m=10, I=1)
        annotation (Placement(transformation(extent={{20,10},{40,30}})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia(
        phi(fixed=true, start=0),
        w(fixed=true, start=0),
        J=1)                    annotation (Placement(transformation(
            extent={{-10,10},{10,-10}},
            rotation=270,
            origin={0,70})));
      VehicleComponents.Wheels.DryFrictionWheelJoint dryFrictionWheelJoint(
        radius=0.3,
        r={1,0},
        N=100,
        vAdhesion=0.1,
        vSlide=0.3,
        mu_A=0.8,
        mu_S=0.4) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,42})));
    equation
      connect(prismatic.frame_a, revolute.frame_b) annotation (Line(
          points={{-6.12323e-016,0},{6.12323e-016,0},{6.12323e-016,-10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_a, fixed.frame_a) annotation (Line(
          points={{-6.12323e-016,-30},{1.83697e-015,-30},{1.83697e-015,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(engineTorque.flange, inertia.flange_a) annotation (Line(
          points={{-12,80},{1.83697e-015,80}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(body.frame_a, prismatic.frame_b) annotation (Line(
          points={{20,20},{6.12323e-016,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(dryFrictionWheelJoint.frame_a, prismatic.frame_b) annotation (
          Line(
          points={{-2.93915e-016,37.2},{-2.93915e-016,28.6},{6.12323e-016,28.6},
              {6.12323e-016,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(dryFrictionWheelJoint.flange_a, inertia.flange_b) annotation (
          Line(
          points={{6.12323e-016,52},{-1.83697e-015,52},{-1.83697e-015,60}},
          color={0,0,0},
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=20),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>DryFriction Wheel</p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/TestDryFrictionWheel_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/TestDryFrictionWheel_2.png\"/></p>
<p><br/><br/><br/><br/>Warning:&nbsp;The&nbsp;initial&nbsp;conditions&nbsp;for&nbsp;variables&nbsp;of&nbsp;type&nbsp;Real&nbsp;are&nbsp;not&nbsp;fully&nbsp;specified.</p>
<p>Assuming&nbsp;fixed&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;prismatic.s(start&nbsp;=&nbsp;1)</p>
<p>&nbsp;</p>
<p>Assuming&nbsp;fixed&nbsp;default&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;prismatic.v(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;revolute.phi(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;revolute.w(start&nbsp;=&nbsp;0.0)</p>
<p><br/>&nbsp;</p>
<p>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;inertia.phi</p>
<p>&nbsp;&nbsp;inertia.w</p>
<p>&nbsp;&nbsp;prismatic.s</p>
<p>&nbsp;&nbsp;prismatic.v</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end TestDryFrictionWheel;

    model TestSlipBasedWheel

      Joints.Prismatic prismatic(r={0,1},
        s(start=1)) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,10})));
      Joints.Revolute revolute annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,-20})));
      Parts.Fixed fixed annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,-50})));
      Modelica.Mechanics.Rotational.Sources.ConstantTorque engineTorque(
          tau_constant=2)
        annotation (Placement(transformation(extent={{-32,70},{-12,90}})));
      Parts.Body body(m=10, I=1)
        annotation (Placement(transformation(extent={{20,10},{40,30}})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia(
        phi(fixed=true, start=0),
        w(fixed=true, start=0),
        J=1)                    annotation (Placement(transformation(
            extent={{-10,10},{10,-10}},
            rotation=270,
            origin={0,70})));
      VehicleComponents.Wheels.SlipBasedWheelJoint slipBasedWheelJoint(
        radius=0.3, r = {1,0},
        mu_A=0.8,
        mu_S=0.4,
        N=100,
        sAdhesion=0.04,
        sSlide=0.12,
        vAdhesion_min=0.05,
        vSlide_min=0.15)
                  annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,42})));
      Modelica.Blocks.Sources.Constant const(k=0)
        annotation (Placement(transformation(extent={{-60,32},{-40,52}})));
    equation
      connect(prismatic.frame_a, revolute.frame_b) annotation (Line(
          points={{-6.12323e-016,0},{6.12323e-016,0},{6.12323e-016,-10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_a, fixed.frame_a) annotation (Line(
          points={{-6.12323e-016,-30},{1.83697e-015,-30},{1.83697e-015,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(engineTorque.flange, inertia.flange_a) annotation (Line(
          points={{-12,80},{1.83697e-015,80}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(body.frame_a, prismatic.frame_b) annotation (Line(
          points={{20,20},{6.12323e-016,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(slipBasedWheelJoint.frame_a, prismatic.frame_b) annotation (Line(
          points={{-2.93915e-016,37.2},{-2.93915e-016,28.6},{6.12323e-016,28.6},
              {6.12323e-016,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(slipBasedWheelJoint.flange_a, inertia.flange_b) annotation (Line(
          points={{6.12323e-016,52},{-1.83697e-015,52},{-1.83697e-015,60}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(const.y, slipBasedWheelJoint.dynamicLoad) annotation (Line(
          points={{-39,42},{-10,42}},
          color={0,0,127},
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        Documentation(info="<html>
<p>A Slip-Based Wheel</p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/TestSlipBasedWheel_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/TestSlipBasedWheel_2.png\"/></p>
<p><br/>Warning:&nbsp;The&nbsp;initial&nbsp;conditions&nbsp;for&nbsp;variables&nbsp;of&nbsp;type&nbsp;Real&nbsp;are&nbsp;not&nbsp;fully&nbsp;specified.</p>
<p>Assuming&nbsp;fixed&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;prismatic.s(start&nbsp;=&nbsp;1)</p>
<p>&nbsp;</p>
<p>Assuming&nbsp;fixed&nbsp;default&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;prismatic.v(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;revolute.phi(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;revolute.w(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;inertia.phi</p>
<p>&nbsp;&nbsp;inertia.w</p>
<p>&nbsp;&nbsp;prismatic.s</p>
<p>&nbsp;&nbsp;prismatic.v</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"),
        experiment(StopTime=20),
        __Dymola_experimentSetupOutput);
    end TestSlipBasedWheel;

    model SingleTrackWithEngine "AcceleratingBody"

      Parts.Body bodyFront( r(start={0,0},each fixed=true),
        I=0.1,
        m=2,
        g={0,0})
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=0,
            origin={40,50})));
      VehicleComponents.Wheels.IdealWheelJoint idealWheelFront(
        r={0,1},
        radius=0.3)
              annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={0,50})));
      Parts.FixedTranslation chassis(r={0,1})             annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={20,-40})));
      Parts.Body bodyRear(
        I=0.1,
        g={0,0},
        m=10) annotation (Placement(transformation(extent={{30,-90},{50,-70}})));
      VehicleComponents.Wheels.IdealWheelJoint idealWheelRear(
        r={0,1},
        radius=0.3) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={0,-80})));
      Joints.Revolute revolute(
        initialize=true,
        w_start=0,
        phi_start=-0.69813170079773,
        enforceStates=true)
                   annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={20,0})));
      Modelica.Mechanics.Rotational.Sources.ConstantTorque engineTorque(
          tau_constant=2)
        annotation (Placement(transformation(extent={{-40,-90},{-20,-70}})));
      Parts.FixedTranslation trail(r={0,-0.1})            annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={20,30})));
    initial equation
      bodyFront.frame_a.phi = 0.0;
      idealWheelFront.flange_a.phi = 0.0;
      idealWheelFront.v_long = 0.0;
      idealWheelRear.flange_a.phi = 0.0;
    equation
      connect(idealWheelFront.frame_a, bodyFront.frame_a)
                                                     annotation (Line(
          points={{4.8,50},{30,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(chassis.frame_a, idealWheelRear.frame_a)             annotation (
          Line(
          points={{20,-50},{20,-80},{4.8,-80}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(bodyRear.frame_a, chassis.frame_a)        annotation (Line(
          points={{30,-80},{20,-80},{20,-50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(revolute.frame_a, chassis.frame_b)           annotation (Line(
          points={{20,-10},{20,-30}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(engineTorque.flange, idealWheelRear.flange_a)      annotation (
          Line(
          points={{-20,-80},{-10,-80}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(trail.frame_a, revolute.frame_b) annotation (Line(
          points={{20,20},{20,10}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(trail.frame_b, idealWheelFront.frame_a) annotation (Line(
          points={{20,40},{20,50},{4.8,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=6),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>An ideal rolling single track model.</p>
<p><br/>There is dynamic state selection applied. It might be avoided by picking Rear.v_long as state.</p>
<p><br/><img src=\"modelica://PlanarMechanicsForTesting/SingleTrackWithEngine_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/SingleTrackWithEngine_2.png\"/></p>
<p><br/><br/><br/><br/>Warning:&nbsp;The&nbsp;initial&nbsp;conditions&nbsp;for&nbsp;variables&nbsp;of&nbsp;type&nbsp;Real&nbsp;are&nbsp;not&nbsp;fully&nbsp;specified.</p>
<p>Assuming&nbsp;fixed&nbsp;default&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;bodyFront.frame_a.phi(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;bodyFront.r[1](start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;bodyFront.r[2](start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;idealWheelFront.flange_a.phi(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;idealWheelFront.v_long(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;idealWheelRear.flange_a.phi(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;</p>
<p>&nbsp;</p>
<p>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;bodyFront.frame_a.phi</p>
<p>&nbsp;&nbsp;bodyFront.r[1]</p>
<p>&nbsp;&nbsp;bodyFront.r[2]</p>
<p>&nbsp;&nbsp;idealWheelFront.flange_a.phi</p>
<p>&nbsp;&nbsp;idealWheelRear.flange_a.phi</p>
<p>&nbsp;&nbsp;revolute.phi</p>
<p>&nbsp;&nbsp;revolute.w</p>
<p>&nbsp;</p>
<p>There&nbsp;is&nbsp;one&nbsp;set&nbsp;of&nbsp;dynamic&nbsp;state&nbsp;selection.</p>
<p>There&nbsp;is&nbsp;one&nbsp;state&nbsp;to&nbsp;be&nbsp;selected&nbsp;from:</p>
<p>&nbsp;&nbsp;bodyFront.w</p>
<p>&nbsp;&nbsp;idealWheelFront.v_long</p>
<p>&nbsp;&nbsp;idealWheelRear.v_long</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end SingleTrackWithEngine;

    model SimpleCarWithDifferentialGear "AcceleratingBody"

      Parts.Body body(
        g={0,0},
        m=100,
        I=1)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=90,
            origin={-40,90})));
      VehicleComponents.Wheels.DryFrictionWheelJoint WheelJoint1(
        vAdhesion=0.1,
        r = {0,1},
        vSlide=0.3,
        mu_A=1,
        mu_S=0.7,
        radius=0.25,
        N=1000)
              annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-62,70})));
      Parts.FixedTranslation fixedTranslation1(r={0,2})   annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={0,-2})));
      Parts.Body body1( r(start={0,0},each fixed=true),
        I=0.1,
        g={0,0},
        m=300)
              annotation (Placement(transformation(extent={{12,-30},{32,-10}})));
      VehicleComponents.Wheels.DryFrictionWheelJoint WheelJoint2(
        r= {0,1},
        vAdhesion=0.1,
        vSlide=0.3,
        mu_A=1,
        mu_S=0.7,
        radius=0.25,
        N=1500)
               annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-60,-40})));
      Modelica.Mechanics.Rotational.Sources.ConstantTorque constantTorque1(
          tau_constant=25)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=0,
            origin={-50,-80})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia(
        phi(fixed=true, start=0),
        w(fixed=true, start=0),
        J=1)                    annotation (Placement(transformation(
            extent={{-10,10},{10,-10}},
            rotation=0,
            origin={-90,70})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia1(
        phi(fixed=true, start=0),
        w(fixed=true, start=0),
        J=1)                    annotation (Placement(transformation(
            extent={{-10,10},{10,-10}},
            rotation=0,
            origin={-92,-40})));
      Parts.FixedTranslation fixedTranslation2(r={0.75,0})   annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={-20,-40})));
      Parts.FixedTranslation fixedTranslation3(r={-0.75,0})  annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={20,-40})));
      VehicleComponents.Wheels.DryFrictionWheelJoint WheelJoint3(
        r = {0,1},
        vAdhesion=0.1,
        vSlide=0.3,
        mu_A=1,
        mu_S=0.7,
        radius=0.25,
        N=1500)
               annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={62,-40})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia2(
        phi(fixed=false, start=0),
        w(fixed=false, start=0),
        J=1)                    annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={90,-40})));
      Parts.FixedTranslation fixedTranslation4(r={0.75,0})   annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={-20,20})));
      Parts.FixedTranslation fixedTranslation5(r={-0.75,0})  annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={20,20})));
      VehicleComponents.Wheels.DryFrictionWheelJoint WheelJoint4(
        vAdhesion=0.1,
        r={0,1},
        vSlide=0.3,
        mu_A=1,
        mu_S=0.7,
        radius=0.25,
        N=1000)
              annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=0,
            origin={60,70})));
      Modelica.Mechanics.Rotational.Components.Inertia inertia3(
        phi(fixed=true, start=0),
        w(fixed=true, start=0),
        J=1)                    annotation (Placement(transformation(
            extent={{-10,10},{10,-10}},
            rotation=180,
            origin={90,70})));
      Parts.Body body2(
        g={0,0},
        m=100,
        I=1)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=90,
            origin={40,90})));
      Joints.ActuatedRevolute actuatedRevolute(
        initialize=true,
        w_start=0,
        phi_start=0.43633231299858) annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={-40,40})));
      Joints.ActuatedRevolute actuatedRevolute1 annotation (Placement(
            transformation(
            extent={{-10,10},{10,-10}},
            rotation=270,
            origin={40,40})));
      Modelica.Mechanics.Rotational.Sources.Torque torque
        annotation (Placement(transformation(extent={{-10,70},{-30,90}})));
      Modelica.Blocks.Sources.Pulse pulse(
        period=2,
        offset=0,
        startTime=1,
        width=30,
        amplitude=2)
        annotation (Placement(transformation(extent={{20,70},{0,90}})));
      VehicleComponents.DifferentialGear differentialGear
        annotation (Placement(transformation(extent={{-10,-72},{10,-52}})));
      Parts.FixedTranslation leftTrail(r={0.,-0.05})         annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={-40,64})));
      Parts.FixedTranslation rightTrail(r={0.,-0.05})        annotation (
          Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=90,
            origin={40,66})));
    initial equation
      body1.frame_a.phi=0;

    equation
      connect(WheelJoint2.flange_a, inertia1.flange_b) annotation (Line(
          points={{-70,-40},{-82,-40}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(inertia.flange_b, WheelJoint1.flange_a) annotation (Line(
          points={{-80,70},{-72,70}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(fixedTranslation2.frame_b, fixedTranslation1.frame_a) annotation (
         Line(
          points={{-10,-40},{0,-40},{0,-12},{-6.12323e-016,-12}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation2.frame_a, WheelJoint2.frame_a) annotation (Line(
          points={{-30,-40},{-55.2,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation3.frame_b, fixedTranslation1.frame_a) annotation (
         Line(
          points={{10,-40},{-6.12323e-016,-40},{-6.12323e-016,-12}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(WheelJoint3.frame_a, fixedTranslation3.frame_a) annotation (Line(
          points={{57.2,-40},{30,-40}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(inertia2.flange_b, WheelJoint3.flange_a) annotation (Line(
          points={{80,-40},{72,-40}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(body1.frame_a, fixedTranslation1.frame_a) annotation (Line(
          points={{12,-20},{-6.12323e-016,-20},{-6.12323e-016,-12}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation1.frame_b, fixedTranslation4.frame_b) annotation (
         Line(
          points={{6.12323e-016,8},{0,8},{0,20},{-10,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(fixedTranslation1.frame_b, fixedTranslation5.frame_b) annotation (
         Line(
          points={{6.12323e-016,8},{0,8},{0,20},{10,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(inertia3.flange_b, WheelJoint4.flange_a) annotation (Line(
          points={{80,70},{70,70}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(actuatedRevolute1.frame_b, fixedTranslation5.frame_a) annotation (
         Line(
          points={{40,30},{40,20},{30,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedRevolute.frame_b, fixedTranslation4.frame_a) annotation (
          Line(
          points={{-40,30},{-40,20},{-30,20}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(actuatedRevolute.flange_a, actuatedRevolute1.flange_a)
        annotation (Line(
          points={{-30,40},{30,40}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(torque.flange, actuatedRevolute.flange_a) annotation (Line(
          points={{-30,80},{-30,40}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(pulse.y, torque.tau) annotation (Line(
          points={{-1,80},{-8,80}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(differentialGear.flange_right, WheelJoint3.flange_a) annotation (
          Line(
          points={{10,-62},{78,-62},{78,-40},{72,-40}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(differentialGear.flange_left, WheelJoint2.flange_a) annotation (
          Line(
          points={{-10,-62},{-70,-62},{-70,-40}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(constantTorque1.flange, differentialGear.flange_b) annotation (
          Line(
          points={{-40,-80},{0,-72}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(body.frame_a, leftTrail.frame_b) annotation (Line(
          points={{-40,80},{-40,74}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(leftTrail.frame_b, WheelJoint1.frame_a) annotation (Line(
          points={{-40,74},{-52,74},{-52,70},{-57.2,70}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(leftTrail.frame_a, actuatedRevolute.frame_a) annotation (Line(
          points={{-40,54},{-40,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(body2.frame_a, rightTrail.frame_b) annotation (Line(
          points={{40,80},{40,76}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(rightTrail.frame_a, actuatedRevolute1.frame_a) annotation (Line(
          points={{40,56},{40,50}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      connect(WheelJoint4.frame_a, rightTrail.frame_b) annotation (Line(
          points={{55.2,70},{44,70},{44,76},{40,76}},
          color={95,95,95},
          thickness=0.5,
          smooth=Smooth.None));
      annotation (Diagram(graphics),
        experiment(StopTime=10),
        __Dymola_experimentSetupOutput,
        Documentation(info="<html>
<p>Two track model of a car.</p>
<p><img src=\"modelica://PlanarMechanicsForTesting/SimpleCarWithDifferentialGear_1.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/SimpleCarWithDifferentialGear_2.png\"/></p>
<p><img src=\"modelica://PlanarMechanicsForTesting/SimpleCarWithDifferentialGear_3.png\"/></p>
<p><br/><br/><br/><br/>Warning:&nbsp;The&nbsp;initial&nbsp;conditions&nbsp;for&nbsp;variables&nbsp;of&nbsp;type&nbsp;Real&nbsp;are&nbsp;not&nbsp;fully&nbsp;specified.</p>
<p>Assuming&nbsp;fixed&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;inertia2.phi(start&nbsp;=&nbsp;0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;inertia2.w(start&nbsp;=&nbsp;0)</p>
<p>&nbsp;</p>
<p>Assuming&nbsp;fixed&nbsp;default&nbsp;start&nbsp;value&nbsp;for&nbsp;the&nbsp;continuous&nbsp;states:</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;body.v[1](start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;body1.frame_a.phi(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;body1.r[1](start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;body1.r[2](start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;body1.w(start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;body2.v[2](start&nbsp;=&nbsp;0.0)</p>
<p>&nbsp;&nbsp;</p>
<p>SELECTED&nbsp;CONTINUOUS&nbsp;TIME&nbsp;STATES</p>
<p>&nbsp;&nbsp;actuatedRevolute.phi</p>
<p>&nbsp;&nbsp;actuatedRevolute.w</p>
<p>&nbsp;&nbsp;body.v[1]</p>
<p>&nbsp;&nbsp;body1.frame_a.phi</p>
<p>&nbsp;&nbsp;body1.r[1]</p>
<p>&nbsp;&nbsp;body1.r[2]</p>
<p>&nbsp;&nbsp;body1.w</p>
<p>&nbsp;&nbsp;body2.v[2]</p>
<p>&nbsp;&nbsp;inertia.phi</p>
<p>&nbsp;&nbsp;inertia.w</p>
<p>&nbsp;&nbsp;inertia1.phi</p>
<p>&nbsp;&nbsp;inertia1.w</p>
<p>&nbsp;&nbsp;inertia2.phi</p>
<p>&nbsp;&nbsp;inertia2.w</p>
<p>&nbsp;&nbsp;inertia3.phi</p>
<p>&nbsp;&nbsp;inertia3.w</p>
</html>", revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
    end SimpleCarWithDifferentialGear;

    annotation (Documentation(revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
  end Examples;

  package Utilities
    function S_Func "Models an S-Function"

      input Real x_min;
      input Real x_max;
      input Real y_min;
      input Real y_max;

      input Real x;
      output Real y;

    protected
      Real x2;

    algorithm
      x2 := x - x_max/2 - x_min/2;
      x2 := x2*2/(x_max-x_min);

      if x2 > 1 then
        y := 1;
      elseif x2 < -1 then
        y := -1;
      else
        y := -0.5*x2^3 + 1.5*x2;
      end if;

      y := y*(y_max-y_min)/2;
      y := y + y_max/2 + y_min/2;

      annotation(smoothOrder=1);
    end S_Func;

    function TripleS_Func "Models a point-symmetric Triple S-Function"

      input Real x_max;
      input Real x_sat;
      input Real y_max;
      input Real y_sat;

      input Real x;
      output Real y;

    algorithm
      if x > x_max then
        y := S_Func(x_max,x_sat,y_max,y_sat,x);
      elseif x < -x_max then
        y := S_Func(-x_max,-x_sat,-y_max,-y_sat,x);
      else
        y := S_Func(-x_max,x_max,-y_max,y_max,x);
      end if;

      annotation(smoothOrder=1);
    end TripleS_Func;

    block S_FuncBlock
      extends Modelica.Blocks.Interfaces.SISO;

      parameter Real x_min = 0;
      parameter Real x_max = 1;
      parameter Real y_min = 0;
      parameter Real y_max = 1;

    equation
      y = S_Func(x_min,x_max,y_min,y_max,u);

      annotation (Icon(graphics={
        Line(points={{-70,-78},{-70,78}}, color={192,192,192}),
        Polygon(
          points={{-70,100},{-78,78},{-62,78},{-70,100}},
          lineColor={192,192,192},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{100,-70},{78,-62},{78,-78},{100,-70}},
          lineColor={192,192,192},
          fillColor={192,192,192},
          fillPattern=FillPattern.Solid),
        Line(points={{-80,-70},{78,-70}}, color={192,192,192}),
        Text(
          extent={{2,6},{74,-42}},
          lineColor={192,192,192},
              textString="S"),
        Line(points={{-70,-70},{-62,-70},{-50,-66},{-40,-58},{-30,-40},{-18,-12},
                  {-2,22},{10,40},{22,52},{32,60},{42,64},{56,68},{70,68}},
                                                          color={0,0,0})}));
    end S_FuncBlock;
  end Utilities;

  package VehicleComponents
    package Wheels
      model IdealWheelJoint

        Interfaces.Frame_a frame_a annotation (Placement(transformation(extent={{-48,0},
                  {-28,20}}), iconTransformation(extent={{-68,-20},{-28,20}})));
        Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
            Placement(transformation(extent={{90,-8},{110,12}}), iconTransformation(
                extent={{90,-10},{110,10}})));

        parameter SI.Length radius "radius of the wheel";

        parameter SI.Length r[2]
          "driving direction of the wheel at angle phi = 0";

        final parameter SI.Length l = sqrt(r*r);
        final parameter Real e[2] =  r/l "normalized direction";

        Real e0[2] "normalized direction w.r.t inertial system";
        Real R[2,2] "Rotation Matrix";

        SI.AngularVelocity w_roll "roll velocity of wheel";
        SI.Velocity v[2] "velocity";

        SI.Velocity v_long
          "driving velocity in (longitudinal) driving direction";
        SI.Acceleration a "acceleration of driving velocity";
        SI.Force f_long "longitudinal force";

        parameter Boolean animate = true "enable Animation"
                                                           annotation(Dialog(group="Animation"));
        parameter Boolean SimVis = false "perform animation with SimVis" annotation(Dialog(group="Animation"));

        MB.Visualizers.Advanced.Shape cylinder(
          shapeType="cylinder",
          color={63,63,63},
          specularCoefficient=0.5,
          length=0.06,
          width=radius*2,
          height=radius*2,
          lengthDirection={-e0[2],e0[1],0},
          widthDirection={0,0,1},
          r_shape=-0.03*{-e0[2],e0[1],0},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.nullRotation()) if animate;

        MB.Visualizers.Advanced.Shape rim1(
          shapeType="cylinder",
          color={195,195,195},
          specularCoefficient=0.5,
          length=radius*2,
          width=0.1,
          height=0.1,
          lengthDirection={0,0,1},
          widthDirection={1,0,0},
          r_shape={0,0,-radius},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.planarRotation({-e0[2],e0[1],0},flange_a.phi,0)) if animate;

        MB.Visualizers.Advanced.Shape rim2(
          shapeType="cylinder",
          color={195,195,195},
          specularCoefficient=0.5,
          length=radius*2,
          width=0.1,
          height=0.1,
          lengthDirection={0,0,1},
          widthDirection={1,0,0},
          r_shape={0,0,-radius},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.planarRotation({-e0[2],e0[1],0},flange_a.phi+Modelica.Constants.pi/2,0)) if animate;

      equation
        R = {{cos(frame_a.phi), sin(frame_a.phi)}, {-sin(frame_a.phi),cos(frame_a.phi)}};
        e0 = R*e;

        v = der({frame_a.x,frame_a.y});
        v = v_long*e0;

        w_roll = der(flange_a.phi);
        v_long = radius*w_roll;
        a = der(v_long);

        -f_long*radius = flange_a.tau;

        frame_a.t = 0;
        {frame_a.fx, frame_a.fy}*e0 = f_long;

        annotation (Icon(graphics={
              Rectangle(
                extent={{-40,100},{40,-100}},
                lineColor={95,95,95},
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={231,231,231}),
              Line(
                points={{-40,30},{40,30}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-30},{40,-30}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,60},{40,60}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,80},{40,80}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,90},{40,90}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,100},{40,100}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-80},{40,-80}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-90},{40,-90}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-100},{40,-100}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-60},{40,-60}},
                color={95,95,95},
                smooth=Smooth.None),
              Rectangle(
                extent={{100,10},{40,-10}},
                lineColor={0,0,0},
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={231,231,231}),
              Text(
                extent={{-100,-100},{100,-140}},
                lineColor={0,0,0},
                fillPattern=FillPattern.Sphere,
                fillColor={85,170,255},
                textString="%name")}),      Diagram(graphics));
      end IdealWheelJoint;

      model DryFrictionWheelJoint

        Interfaces.Frame_a frame_a annotation (Placement(transformation(extent={{-48,0},
                  {-28,20}}), iconTransformation(extent={{-68,-20},{-28,20}})));
        Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
            Placement(transformation(extent={{90,-8},{110,12}}), iconTransformation(
                extent={{90,-10},{110,10}})));

        parameter SI.Length radius "radius of the wheel";

        parameter SI.Length r[2]
          "driving direction of the wheel at angle phi = 0";

        parameter SI.Force N "normal force";
        parameter SI.Velocity vAdhesion "adhesion velocity";
        parameter SI.Velocity vSlide "sliding velocity";
        parameter Real mu_A "friction coefficient at adhesion";
        parameter Real mu_S "friction coefficient at sliding";

        final parameter SI.Length l = sqrt(r*r);
        final parameter Real e[2] =  r/l "normalized direction";

        Real e0[2] "normalized direction w.r.t inertial system";
        Real R[2,2] "Rotation Matrix";

        SI.AngularVelocity w_roll "roll velocity of wheel";
        SI.Velocity v[2] "velocity";

        SI.Velocity v_lat "driving in lateral direction";
        SI.Velocity v_long "velocity in longitudinal direction";

        SI.Velocity v_slip_long "slip velocity in longitudinal direction";
        SI.Velocity v_slip_lat "slip velocity in lateral direction";
        SI.Velocity v_slip "slip velocity";

        SI.Force f "longitudinal force";
        SI.Force f_lat "longitudinal force";
        SI.Force f_long "longitudinal force";

        parameter Boolean animate = true "enable Animation"
                                                           annotation(Dialog(group="Animation"));
        parameter Boolean SimVis = false "perform animation with SimVis" annotation(Dialog(group="Animation"));

        MB.Visualizers.Advanced.Shape cylinder(
          shapeType="cylinder",
          color={63,63,63},
          specularCoefficient=0.5,
          length=0.06,
          width=radius*2,
          height=radius*2,
          lengthDirection={-e0[2],e0[1],0},
          widthDirection={0,0,1},
          r_shape=-0.03*{-e0[2],e0[1],0},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.nullRotation()) if animate;

        MB.Visualizers.Advanced.Shape rim1(
          shapeType="cylinder",
          color={195,195,195},
          specularCoefficient=0.5,
          length=radius*2,
          width=0.1,
          height=0.1,
          lengthDirection={0,0,1},
          widthDirection={1,0,0},
          r_shape={0,0,-radius},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.planarRotation({-e0[2],e0[1],0},flange_a.phi,0)) if animate;

        MB.Visualizers.Advanced.Shape rim2(
          shapeType="cylinder",
          color={195,195,195},
          specularCoefficient=0.5,
          length=radius*2,
          width=0.1,
          height=0.1,
          lengthDirection={0,0,1},
          widthDirection={1,0,0},
          r_shape={0,0,-radius},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.planarRotation({-e0[2],e0[1],0},flange_a.phi+Modelica.Constants.pi/2,0)) if animate;

      equation
        R = {{cos(frame_a.phi), sin(frame_a.phi)}, {-sin(frame_a.phi),cos(frame_a.phi)}};
        e0 = R*e;
        v = der({frame_a.x,frame_a.y});
        w_roll = der(flange_a.phi);

        v_long = v*e0;
        v_lat = -v[1]*e0[2] + v[2]*e0[1];

        v_slip_lat = v_lat - 0;
        v_slip_long = v_long - radius*w_roll;
        v_slip = sqrt(v_slip_long^2 + v_slip_lat^2)+0.0001;

        -f_long*radius = flange_a.tau;
        frame_a.t = 0;

        f = N*noEvent(Utilities.TripleS_Func(vAdhesion,vSlide,mu_A,mu_S,v_slip));

        f_long =f*v_slip_long/v_slip;
        f_lat  =f*v_slip_lat/v_slip;
        f_long = {frame_a.fx, frame_a.fy}*e0;
        f_lat = {frame_a.fy, -frame_a.fx}*e0;

        annotation (Icon(graphics={
              Rectangle(
                extent={{-40,100},{40,-100}},
                lineColor={95,95,95},
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={231,231,231}),
              Line(
                points={{-40,30},{40,30}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-30},{40,-30}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,60},{40,60}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,80},{40,80}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,90},{40,90}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,100},{40,100}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-80},{40,-80}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-90},{40,-90}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-100},{40,-100}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-60},{40,-60}},
                color={95,95,95},
                smooth=Smooth.None),
              Rectangle(
                extent={{100,10},{40,-10}},
                lineColor={0,0,0},
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={231,231,231}),
              Text(
                extent={{-100,-100},{100,-140}},
                lineColor={0,0,0},
                fillPattern=FillPattern.Sphere,
                fillColor={85,170,255},
                textString="%name")}),      Diagram(graphics));
      end DryFrictionWheelJoint;

      model SlipBasedWheelJoint

        Interfaces.Frame_a frame_a annotation (Placement(transformation(extent={{-48,0},
                  {-28,20}}), iconTransformation(extent={{-68,-20},{-28,20}})));
        Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_a annotation (
            Placement(transformation(extent={{90,-8},{110,12}}), iconTransformation(
                extent={{90,-10},{110,10}})));

        Modelica.Blocks.Interfaces.RealInput dynamicLoad(unit="N") annotation (Placement(transformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={0,100}), iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={0,100})));

        parameter SI.Length radius "radius of the wheel";

        parameter SI.Length r[2]
          "driving direction of the wheel at angle phi = 0";

        parameter SI.Force N "base normal load";
        parameter SI.Velocity vAdhesion_min "minimum adhesion velocity";
        parameter SI.Velocity vSlide_min "minimum sliding velocity";

        parameter Real sAdhesion "adhesion slippage";
        parameter Real sSlide "sliding slippage";

        parameter Real mu_A "friction coefficient at adhesion";
        parameter Real mu_S "friction coefficient at sliding";

        final parameter SI.Length l = sqrt(r*r);
        final parameter Real e[2] =  r/l "normalized direction";

        Real e0[2] "normalized direction w.r.t inertial system";
        Real R[2,2] "Rotation Matrix";

        SI.AngularVelocity w_roll "roll velocity of wheel";
        SI.Velocity v[2] "velocity";

        SI.Velocity v_lat "driving in lateral direction";
        SI.Velocity v_long "velocity in longitudinal direction";

        SI.Velocity v_slip_long "slip velocity in longitudinal direction";
        SI.Velocity v_slip_lat "slip velocity in lateral direction";
        SI.Velocity v_slip "slip velocity";

        SI.Force f "longitudinal force";
        SI.Force f_lat "longitudinal force";
        SI.Force f_long "longitudinal force";
        SI.Force fN "base normal load";

        SI.Velocity vAdhesion "adhesion velocity";
        SI.Velocity vSlide "sliding velocity";

        parameter Boolean animate = true "enable Animation"
                                                           annotation(Dialog(group="Animation"));

        MB.Visualizers.Advanced.Shape cylinder(
          shapeType="cylinder",
          color={63,63,63},
          specularCoefficient=0.5,
          length=0.06,
          width=radius*2,
          height=radius*2,
          lengthDirection={-e0[2],e0[1],0},
          widthDirection={0,0,1},
          r_shape=-0.03*{-e0[2],e0[1],0},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.nullRotation()) if animate;

        MB.Visualizers.Advanced.Shape rim1(
          shapeType="cylinder",
          color={195,195,195},
          specularCoefficient=0.5,
          length=radius*2,
          width=0.1,
          height=0.1,
          lengthDirection={0,0,1},
          widthDirection={1,0,0},
          r_shape={0,0,-radius},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.planarRotation({-e0[2],e0[1],0},flange_a.phi,0)) if animate;

        MB.Visualizers.Advanced.Shape rim2(
          shapeType="cylinder",
          color={195,195,195},
          specularCoefficient=0.5,
          length=radius*2,
          width=0.1,
          height=0.1,
          lengthDirection={0,0,1},
          widthDirection={1,0,0},
          r_shape={0,0,-radius},
          r={frame_a.x,frame_a.y,0},
          R=MB.Frames.planarRotation({-e0[2],e0[1],0},flange_a.phi+Modelica.Constants.pi/2,0)) if animate;

      equation
        R = {{cos(frame_a.phi), sin(frame_a.phi)}, {-sin(frame_a.phi),cos(frame_a.phi)}};
        e0 = R*e;
        v = der({frame_a.x,frame_a.y});
        w_roll = der(flange_a.phi);

        v_long = v*e0;
        v_lat = -v[1]*e0[2] + v[2]*e0[1];

        v_slip_lat = v_lat - 0;
        v_slip_long = v_long - radius*w_roll;
        v_slip = sqrt(v_slip_long^2 + v_slip_lat^2)+0.0001;

        -f_long*radius = flange_a.tau;
        frame_a.t = 0;

        vAdhesion = noEvent(max(sAdhesion*abs(radius*w_roll),vAdhesion_min));
        vSlide = noEvent(max(sSlide*abs(radius*w_roll),vSlide_min));
        fN = max(0, N+dynamicLoad);

        f = fN*noEvent(Utilities.TripleS_Func(vAdhesion,vSlide,mu_A,mu_S,v_slip));

        f_long =f*v_slip_long/v_slip;
        f_lat  =f*v_slip_lat/v_slip;
        f_long = {frame_a.fx, frame_a.fy}*e0;
        f_lat = {frame_a.fy, -frame_a.fx}*e0;

        annotation (Icon(graphics={
              Rectangle(
                extent={{-40,100},{40,-100}},
                lineColor={95,95,95},
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={231,231,231}),
              Line(
                points={{-40,30},{40,30}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-30},{40,-30}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,60},{40,60}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,80},{40,80}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,90},{40,90}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,100},{40,100}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-80},{40,-80}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-90},{40,-90}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-100},{40,-100}},
                color={95,95,95},
                smooth=Smooth.None),
              Line(
                points={{-40,-60},{40,-60}},
                color={95,95,95},
                smooth=Smooth.None),
              Rectangle(
                extent={{100,10},{40,-10}},
                lineColor={0,0,0},
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={231,231,231}),
              Text(
                extent={{-100,-100},{100,-140}},
                lineColor={0,0,0},
                fillPattern=FillPattern.Sphere,
                fillColor={85,170,255},
                textString="%name")}),      Diagram(graphics));
      end SlipBasedWheelJoint;
    end Wheels;

    model DifferentialGear "\"Simple Model of a differential gear\""

      Modelica.Mechanics.Rotational.Components.IdealPlanetary idealPlanetary(
          ratio=-2)  annotation (Placement(transformation(
            extent={{-10,-10},{10,10}},
            rotation=270,
            origin={0,-52})));
      Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b
        annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_left
        annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
      Modelica.Mechanics.Rotational.Interfaces.Flange_a flange_right
        annotation (Placement(transformation(extent={{90,-10},{110,10}})));
    equation
      connect(flange_b,idealPlanetary. ring) annotation (Line(
          points={{0,-100},{0,-62},{-1.83697e-015,-62}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(idealPlanetary.carrier, flange_right) annotation (Line(
          points={{4,-42},{4,0},{100,0}},
          color={0,0,0},
          pattern=LinePattern.None,
          smooth=Smooth.None));
      connect(idealPlanetary.sun, flange_left) annotation (Line(
          points={{1.83697e-015,-42},{0,-42},{0,0},{-100,0}},
          color={0,0,0},
          smooth=Smooth.None));
      annotation (Diagram(graphics), Icon(graphics={
            Rectangle(
              extent={{-60,50},{40,-50}},
              fillColor={175,175,175},
              fillPattern=FillPattern.Solid,
              pattern=LinePattern.None),
            Rectangle(
              extent={{-48,40},{40,-40}},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid,
              pattern=LinePattern.None,
              lineColor={0,0,0}),
            Polygon(
              points={{40,-60},{60,-80},{60,80},{40,60},{40,-60}},
              pattern=LinePattern.None,
              smooth=Smooth.None,
              fillColor={175,175,175},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,0}),
            Polygon(
              points={{20,-60},{40,-80},{-40,-80},{-20,-60},{20,-60}},
              pattern=LinePattern.None,
              smooth=Smooth.None,
              fillColor={175,175,175},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,0}),
            Polygon(
              points={{14,10},{34,-10},{-34,-10},{-14,10},{14,10}},
              pattern=LinePattern.None,
              smooth=Smooth.None,
              fillColor={135,135,135},
              fillPattern=FillPattern.Solid,
              origin={-30,0},
              rotation=270),
            Polygon(
              points={{14,10},{34,-10},{-32,-10},{-12,10},{14,10}},
              pattern=LinePattern.None,
              smooth=Smooth.None,
              fillColor={135,135,135},
              fillPattern=FillPattern.Solid,
              origin={-4,-26},
              rotation=360),
            Polygon(
              points={{16,10},{36,-10},{-32,-10},{-12,10},{16,10}},
              pattern=LinePattern.None,
              smooth=Smooth.None,
              fillColor={135,135,135},
              fillPattern=FillPattern.Solid,
              origin={24,-2},
              rotation=90),
            Rectangle(
              extent={{-100,10},{-40,-10}},
              pattern=LinePattern.None,
              fillColor={135,135,135},
              fillPattern=FillPattern.Solid),
            Rectangle(
              extent={{34,10},{102,-10}},
              pattern=LinePattern.None,
              fillColor={135,135,135},
              fillPattern=FillPattern.Solid),
            Rectangle(
              extent={{-10,-100},{10,-80}},
              pattern=LinePattern.None,
              fillColor={175,175,175},
              fillPattern=FillPattern.Solid),
            Rectangle(
              extent={{-16,-36},{10,-40}},
              pattern=LinePattern.None,
              fillColor={175,175,175},
              fillPattern=FillPattern.Solid)}));
    end DifferentialGear;
  end VehicleComponents;

  package Sensors
    model AbsoluteRotation

      Interfaces.Frame_b frame_b annotation (Placement(transformation(extent={{60,40},
                {80,60}}), iconTransformation(extent={{80,-20},{120,20}})));
      Modelica.Blocks.Interfaces.RealOutput y annotation (Placement(transformation(
              extent={{-122,4},{-102,24}}), iconTransformation(
            extent={{-10,-10},{10,10}},
            rotation=180,
            origin={-110,0})));

    equation
      y = frame_b.phi;

      frame_b.fx = 0;
      frame_b.fy = 0;
      frame_b.t = 0;

      annotation (Icon(graphics={
            Line(points={{-100,0},{-74,0}},
                                          color={0,0,127}),
            Ellipse(
              extent={{-74,70},{66,-70}},
              lineColor={0,0,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Line(points={{-4,70},{-4,40}},
                                         color={0,0,0}),
            Line(points={{18.9,32.8},{36.2,57.3}}, color={0,0,0}),
            Line(points={{-26.9,32.8},{-44.2,57.3}}, color={0,0,0}),
            Line(points={{33.6,13.7},{61.8,23.9}}, color={0,0,0}),
            Line(points={{-41.6,13.7},{-69.8,23.9}}, color={0,0,0}),
            Line(points={{-4,0},{5.02,28.6}},color={0,0,0}),
            Polygon(
              points={{-4.48,31.6},{14,26},{14,57.2},{-4.48,31.6}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-9,5},{1,-5}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
                                   Text(
              extent={{60,80},{110,40}},
              lineColor={0,0,0},
              textString="phi"),
            Line(points={{86,0},{66,0}},   color={0,0,0}),
            Text(
              extent={{-100,-80},{100,-120}},
              textString="%name",
              lineColor={0,0,0})}));
    end AbsoluteRotation;
  end Sensors;
  annotation (uses(
        Modelica(version="3.1" /* Originally 3.2 */)), Documentation(revisions="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>", info="<html>
<p>(c) Copyright by Dirk Zimmer</p>
<p>The library was creates and is owned by Dr. Dirk Zimmer. </p>
<p>dirk.zimmer@dlr.de</p>
</html>"));
end PlanarMechanicsForTesting;

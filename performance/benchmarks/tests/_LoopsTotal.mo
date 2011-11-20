package ModelicaServices
  "Models and functions used in the Modelica Standard Library requiring a tool specific implementation"

package Animation "Models and functions for 3-dim. animation"

model Shape
  "Different visual shapes with variable size; all data have to be set as modifiers (see info layer)"
  extends
    Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialShape;

    import T = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
    import SI = Modelica.SIunits;
    import Modelica.Mechanics.MultiBody.Frames;
    import Modelica.Mechanics.MultiBody.Types;

    function PackShape
      input Types.ShapeType shapeType;
      output Real pack;
    algorithm 
      pack:=1.2;
    end PackShape;
    
    function PackMaterial
      input Real material1;
      input Real material2;
      input Real material3;
      input Types.SpecularCoefficient sp;
      output Real mat;
    algorithm 
      mat:=material1 + material2 + material3 + sp;
    end PackMaterial;

protected
  Real abs_n_x(final unit="1")=Modelica.Math.Vectors.length(
                             lengthDirection);
  Real e_x[3](each final unit="1")=noEvent(if abs_n_x < 1.e-10 then {1,0,0} else lengthDirection
      /abs_n_x);
  Real n_z_aux[3](each final unit="1")=cross(e_x, widthDirection);
  Real e_y[3](each final unit="1")=noEvent(cross(Modelica.Math.Vectors.normalize(
                                             cross(e_x, if n_z_aux*n_z_aux
       > 1.0e-6 then widthDirection else (if abs(e_x[1]) > 1.0e-6 then {0,1,
      0} else {1,0,0}))), e_x));
  output Real Form;
public
  output Real rxvisobj[3](each final unit="1")
    "x-axis unit vector of shape, resolved in world frame";
  output Real ryvisobj[3](each final unit="1")
    "y-axis unit vector of shape, resolved in world frame";
  output SI.Position rvisobj[3]
    "position vector from world frame to shape frame, resolved in world frame";

protected
  output SI.Length size[3] "{length,width,height} of shape";
  output Real Material;
  output Real Extra;

equation
  /* Outputs to file. */
  Form = (987000 + PackShape(shapeType))*1E20;
  /*
  rxry = Frames.TransformationMatrices.to_exy(
    Frames.TransformationMatrices.absoluteRotation(R.T,
    Frames.TransformationMatrices.from_nxy(lengthDirection, widthDirection)));
  rxvisobj = rxry[:, 1];
  ryvisobj = rxry[:, 2];
*/
  rxvisobj = transpose(R.T)*e_x;
  ryvisobj = transpose(R.T)*e_y;
  rvisobj = r + T.resolve1(R.T, r_shape);
  size = {length,width,height};
  Material = PackMaterial(color[1]/255.0, color[2]/255.0, color[3]/255.0,
    specularCoefficient);
  Extra = extra;
end Shape;
end Animation;
end ModelicaServices;

package Modelica "Modelica Standard Library (Version 3.1)"
extends Modelica.Icons.Library;

  package Blocks
  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;

    package Continuous
    "Library of continuous control blocks with internal states"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
      extends Modelica.Icons.Library;

      block CriticalDamping
      "Output the input signal filtered with an n-th order filter with critical damping"

        import Modelica.Blocks.Types.Init;
        extends Modelica.Blocks.Interfaces.SISO;

        parameter Integer n=2 "Order of filter";
        parameter Modelica.SIunits.Frequency f(start=1) "Cut-off frequency";
        parameter Boolean normalized = true
        "= true, if amplitude at f_cut is 3 dB, otherwise unmodified filter";
        parameter Modelica.Blocks.Types.Init initType=Modelica.Blocks.Types.Init.NoInit
        "Type of initialization (1: no init, 2: steady state, 3: initial state, 4: initial output)";
        parameter Real x_start[n]=zeros(n) "Initial or guess values of states";
        parameter Real y_start=0.0
        "Initial value of output (remaining states are in steady state)";

        output Real x[n](start=x_start) "Filter states";
    protected
        parameter Real alpha=if normalized then sqrt(2^(1/n) - 1) else 1.0
        "Frequency correction factor for normalized filter";
        parameter Real w=2*Modelica.Constants.pi*f/alpha;
      initial equation
        if initType == Init.SteadyState then
          der(x) = zeros(n);
        elseif initType == Init.InitialState then
          x = x_start;
        elseif initType == Init.InitialOutput then
          y = y_start;
          der(x[1:n-1]) = zeros(n-1);
        end if;
      equation
        der(x[1]) = (u - x[1])*w;
        for i in 2:n loop
          der(x[i]) = (x[i - 1] - x[i])*w;
        end for;
        y = x[n];
      end CriticalDamping;
    end Continuous;

    package Interfaces
    "Library of connectors and partial models for input/output blocks"
      import Modelica.SIunits;
        extends Modelica.Icons.Library;

    connector RealInput = input Real "'input Real' as connector";

    connector RealOutput = output Real "'output Real' as connector";

        partial block BlockIcon "Basic graphical layout of input/output block"


        end BlockIcon;

        partial block SO "Single Output continuous control block"
          extends BlockIcon;

          RealOutput y "Connector of Real output signal";

        end SO;

        partial block SISO
      "Single Input Single Output continuous control block"
          extends BlockIcon;

          RealInput u "Connector of Real input signal";
          RealOutput y "Connector of Real output signal";
        end SISO;
    end Interfaces;

    package Sources
    "Library of signal source blocks generating Real and Boolean signals"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
          extends Modelica.Icons.Library;

          block Constant "Generate constant signal of type Real"
            parameter Real k(start=1) "Constant output value";
            extends Interfaces.SO;

          equation
            y = k;
          end Constant;

          block Sine "Generate sine signal"
            parameter Real amplitude=1 "Amplitude of sine wave";
            parameter SIunits.Frequency freqHz(start=1)
        "Frequency of sine wave";
            parameter SIunits.Angle phase=0 "Phase of sine wave";
            parameter Real offset=0 "Offset of output signal";
            parameter SIunits.Time startTime=0
        "Output = offset for time < startTime";
            extends Interfaces.SO;
    protected
            constant Real pi=Modelica.Constants.pi;

          equation
            y = offset + (if time < startTime then 0 else amplitude*
              Modelica.Math.sin(2*pi*freqHz*(time - startTime) + phase));
          end Sine;
    end Sources;

    package Types
    "Library of constants and types with choices, especially to build menus"
      extends Modelica.Icons.Library;

      type Init = enumeration(
        NoInit
          "No initialization (start values are used as guess values with fixed=false)", 

        SteadyState
          "Steady state initialization (derivatives of states are zero)",
        InitialState "Initialization with initial states",
        InitialOutput
          "Initialization with initial outputs (and steady state of the states if possibles)")
      "Enumeration defining initialization of a block";
    end Types;
  end Blocks;

  package Mechanics
  "Library of 1-dim. and 3-dim. mechanical components (multi-body, rotational, translational)"
  extends Modelica.Icons.Library2;

    package MultiBody "Library to model 3-dimensional mechanical systems"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Library;

    model World
      "World coordinate system + gravity field + default animation definition"

      import SI = Modelica.SIunits;
      import Modelica.Mechanics.MultiBody.Types.GravityTypes;
      import Modelica.Mechanics.MultiBody.Types;

        Interfaces.Frame_b frame_b
        "Coordinate system fixed in the origin of the world frame";


      parameter Boolean enableAnimation=true
        "= true, if animation of all components is enabled";
      parameter Boolean animateWorld=true
        "= true, if world coordinate system shall be visualized";
      parameter Boolean animateGravity=true
        "= true, if gravity field shall be visualized (acceleration vector or field center)";
      parameter Types.AxisLabel label1="x" "Label of horizontal axis in icon";
      parameter Types.AxisLabel label2="y" "Label of vertical axis in icon";
      parameter Types.GravityTypes gravityType=GravityTypes.UniformGravity
        "Type of gravity field";
      parameter SI.Acceleration g=9.81 "Constant gravity acceleration";
      parameter Types.Axis n={0,-1,0}
        "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
      parameter Real mue(
        unit="m3/s2",
        min=0) = 3.986e14
        "Gravity field constant (default = field constant of earth)";
      parameter Boolean driveTrainMechanics3D=true
        "= true, if 3-dim. mechanical effects of Parts.Mounting1D/Rotor1D/BevelGear1D shall be taken into account";

      parameter SI.Distance axisLength=nominalLength/2
        "Length of world axes arrows";
      parameter SI.Distance axisDiameter=axisLength/defaultFrameDiameterFraction
        "Diameter of world axes arrows";
      parameter Boolean axisShowLabels=true "= true, if labels shall be shown";
      input Types.Color axisColor_x=Modelica.Mechanics.MultiBody.Types.Defaults.FrameColor
        "Color of x-arrow";
      input Types.Color axisColor_y=axisColor_x;
      input Types.Color axisColor_z=axisColor_x "Color of z-arrow";

      parameter SI.Position gravityArrowTail[3]={0,0,0}
        "Position vector from origin of world frame to arrow tail, resolved in world frame";
      parameter SI.Length gravityArrowLength=axisLength/2
        "Length of gravity arrow";
      parameter SI.Diameter gravityArrowDiameter=gravityArrowLength/
          defaultWidthFraction "Diameter of gravity arrow";
      input Types.Color gravityArrowColor={0,230,0} "Color of gravity arrow";
      parameter SI.Diameter gravitySphereDiameter=12742000
        "Diameter of sphere representing gravity center (default = mean diameter of earth)";
      input Types.Color gravitySphereColor={0,230,0} "Color of gravity sphere";

      parameter SI.Length nominalLength=1
        "\"Nominal\" length of multi-body system";
      parameter SI.Length defaultAxisLength=nominalLength/5
        "Default for length of a frame axis (but not world frame)";
      parameter SI.Length defaultJointLength=nominalLength/10
        "Default for the fixed length of a shape representing a joint";
      parameter SI.Length defaultJointWidth=nominalLength/20
        "Default for the fixed width of a shape representing a joint";
      parameter SI.Length defaultForceLength=nominalLength/10
        "Default for the fixed length of a shape representing a force (e.g. damper)";
      parameter SI.Length defaultForceWidth=nominalLength/20
        "Default for the fixed width of a shape represening a force (e.g. spring, bushing)";
      parameter SI.Length defaultBodyDiameter=nominalLength/9
        "Default for diameter of sphere representing the center of mass of a body";
      parameter Real defaultWidthFraction=20
        "Default for shape width as a fraction of shape length (e.g., for Parts.FixedTranslation)";
      parameter SI.Length defaultArrowDiameter=nominalLength/40
        "Default for arrow diameter (e.g., of forces, torques, sensors)";
      parameter Real defaultFrameDiameterFraction=40
        "Default for arrow diameter of a coordinate system as a fraction of axis length";
      parameter Real defaultSpecularCoefficient(min=0) = 0.7
        "Default reflection of ambient light (= 0: light is completely absorbed)";
      parameter Real defaultN_to_m(unit="N/m", min=0) = 1000
        "Default scaling of force arrows (length = force/defaultN_to_m)";
      parameter Real defaultNm_to_m(unit="N.m/m", min=0) = 1000
        "Default scaling of torque arrows (length = torque/defaultNm_to_m)";

      /* The World object can only use the Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape model, but no
     other models in package Modelica.Mechanics.MultiBody.Visualizers, since the other models access
     data of the "outer Modelica.Mechanics.MultiBody.World world" object, i.e., there are
     mutually dependent classes. For this reason, the higher level visualization
     objects cannot be used.
  */
    protected
      parameter Integer ndim=if enableAnimation and animateWorld then 1 else 0;
      parameter Integer ndim2=if enableAnimation and animateWorld and 
          axisShowLabels then 1 else 0;

      // Parameters to define axes
      parameter SI.Length headLength=min(axisLength, axisDiameter*Types.Defaults.
          FrameHeadLengthFraction);
      parameter SI.Length headWidth=axisDiameter*Types.Defaults.
          FrameHeadWidthFraction;
      parameter SI.Length lineLength=max(0, axisLength - headLength);
      parameter SI.Length lineWidth=axisDiameter;

      // Parameters to define axes labels
      parameter SI.Length scaledLabel=Modelica.Mechanics.MultiBody.Types.Defaults.FrameLabelHeightFraction*
          axisDiameter;
      parameter SI.Length labelStart=1.05*axisLength;

      // x-axis
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape x_arrowLine(
        shapeType="cylinder",
        length=lineLength,
        width=lineWidth,
        height=lineWidth,
        lengthDirection={1,0,0},
        widthDirection={0,1,0},
        color=axisColor_x,
        specularCoefficient=0) if enableAnimation and animateWorld;
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape x_arrowHead(
        shapeType="cone",
        length=headLength,
        width=headWidth,
        height=headWidth,
        lengthDirection={1,0,0},
        widthDirection={0,1,0},
        color=axisColor_x,
        r={lineLength,0,0},
        specularCoefficient=0) if enableAnimation and animateWorld;
      Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines x_label(
        lines=scaledLabel*{[0, 0; 1, 1],[0, 1; 1, 0]},
        diameter=axisDiameter,
        color=axisColor_x,
        r_lines={labelStart,0,0},
        n_x={1,0,0},
        n_y={0,1,0},
        specularCoefficient=0) if enableAnimation and animateWorld and axisShowLabels;

      // y-axis
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape y_arrowLine(
        shapeType="cylinder",
        length=lineLength,
        width=lineWidth,
        height=lineWidth,
        lengthDirection={0,1,0},
        widthDirection={1,0,0},
        color=axisColor_y,
        specularCoefficient=0) if enableAnimation and animateWorld;
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape y_arrowHead(
        shapeType="cone",
        length=headLength,
        width=headWidth,
        height=headWidth,
        lengthDirection={0,1,0},
        widthDirection={1,0,0},
        color=axisColor_y,
        r={0,lineLength,0},
        specularCoefficient=0) if enableAnimation and animateWorld;
      Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines y_label(
        lines=scaledLabel*{[0, 0; 1, 1.5],[0, 1.5; 0.5, 0.75]},
        diameter=axisDiameter,
        color=axisColor_y,
        r_lines={0,labelStart,0},
        n_x={0,1,0},
        n_y={-1,0,0},
        specularCoefficient=0) if enableAnimation and animateWorld and axisShowLabels;

      // z-axis
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape z_arrowLine(
        shapeType="cylinder",
        length=lineLength,
        width=lineWidth,
        height=lineWidth,
        lengthDirection={0,0,1},
        widthDirection={0,1,0},
        color=axisColor_z,
        specularCoefficient=0) if enableAnimation and animateWorld;
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape z_arrowHead(
        shapeType="cone",
        length=headLength,
        width=headWidth,
        height=headWidth,
        lengthDirection={0,0,1},
        widthDirection={0,1,0},
        color=axisColor_z,
        r={0,0,lineLength},
        specularCoefficient=0) if enableAnimation and animateWorld;
      Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines z_label(
        lines=scaledLabel*{[0, 0; 1, 0],[0, 1; 1, 1],[0, 1; 1, 0]},
        diameter=axisDiameter,
        color=axisColor_z,
        r_lines={0,0,labelStart},
        n_x={0,0,1},
        n_y={0,1,0},
        specularCoefficient=0) if enableAnimation and animateWorld and axisShowLabels;

      // Uniform gravity visualization
      parameter SI.Length gravityHeadLength=min(gravityArrowLength,
          gravityArrowDiameter*Types.Defaults.ArrowHeadLengthFraction);
      parameter SI.Length gravityHeadWidth=gravityArrowDiameter*Types.Defaults.ArrowHeadWidthFraction;
      parameter SI.Length gravityLineLength=max(0, gravityArrowLength - gravityHeadLength);
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravityArrowLine(
        shapeType="cylinder",
        length=gravityLineLength,
        width=gravityArrowDiameter,
        height=gravityArrowDiameter,
        lengthDirection=n,
        widthDirection={0,1,0},
        color=gravityArrowColor,
        r_shape=gravityArrowTail,
        specularCoefficient=0) if enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity;
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravityArrowHead(
        shapeType="cone",
        length=gravityHeadLength,
        width=gravityHeadWidth,
        height=gravityHeadWidth,
        lengthDirection=n,
        widthDirection={0,1,0},
        color=gravityArrowColor,
        r_shape=gravityArrowTail + Modelica.Math.Vectors.normalize(
                                                    n)*gravityLineLength,
        specularCoefficient=0) if enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity;

      // Point gravity visualization
      parameter Integer ndim_pointGravity=if enableAnimation and animateGravity
           and gravityType == 2 then 1 else 0;
      Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravitySphere(
        shapeType="sphere",
        r_shape={-gravitySphereDiameter/2,0,0},
        lengthDirection={1,0,0},
        length=gravitySphereDiameter,
        width=gravitySphereDiameter,
        height=gravitySphereDiameter,
        color=gravitySphereColor,
        specularCoefficient=0) if enableAnimation and animateGravity and gravityType == GravityTypes.PointGravity;

      function gravityAcceleration = gravityAccelerationTypes (
          gravityType=gravityType,
          g=g*Modelica.Math.Vectors.normalize(
                                         n),
          mue=mue);

    protected
      function gravityAccelerationTypes
        "Gravity field acceleration depending on field type and position"
        import Modelica.Mechanics.MultiBody.Types.GravityTypes;
        extends Modelica.Icons.Function;
        input SI.Position r[3]
          "Position vector from world frame to actual point, resolved in world frame";
        input GravityTypes gravityType "Type of gravity field";
        input SI.Acceleration g[3]
          "Constant gravity acceleration, resolved in world frame, if gravityType=1";
        input Real mue(unit="m3/s2")
          "Field constant of point gravity field, if gravityType=2";
        output SI.Acceleration gravity[3]
          "Gravity acceleration at point r, resolved in world frame";
      algorithm
        gravity := if gravityType == GravityTypes.UniformGravity then g else 
                   if gravityType == GravityTypes.PointGravity then 
                      -(mue/(r*r))*(r/Modelica.Math.Vectors.length(
                                                    r)) else 
                        zeros(3);
      end gravityAccelerationTypes;
    equation
      Connections.root(frame_b.R);

      assert(Modelica.Math.Vectors.length(
                           n) > 1.e-10,
        "Parameter n of World object is wrong (lenght(n) > 0 required)");
      frame_b.r_0 = zeros(3);
      frame_b.R = Frames.nullRotation();
    end World;

      package Examples
      "Examples that demonstrate the usage of the MultiBody library"
      extends Modelica.Icons.Library;

        package Loops "Examples with kinematic loops"
        extends Modelica.Icons.Library;

          model Engine1a "Model of one cylinder engine"
            import SI = Modelica.SIunits;
            extends Modelica.Icons.Example;
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder Piston(diameter=0.1, r={0,-0.1,0});
            Modelica.Mechanics.MultiBody.Parts.BodyBox Rod(
              widthDirection={1,0,0},
              width=0.02,
              height=0.06,
              r={0,-0.2,0},
              color={0,0,200});
            Modelica.Mechanics.MultiBody.Joints.Revolute B2(
              n={1,0,0},
              cylinderLength=0.02,
              cylinderDiameter=0.05);
            Modelica.Mechanics.MultiBody.Joints.Revolute Bearing(useAxisFlange=true,
              n={1,0,0},
              cylinderLength=0.02,
              cylinderDiameter=0.05);
            inner Modelica.Mechanics.MultiBody.World world;
            Modelica.Mechanics.Rotational.Components.Inertia Inertia(
                stateSelect=StateSelect.always,
                phi(fixed=true, start=0),
                w(fixed=true, start=10),
              J=1);
            Modelica.Mechanics.MultiBody.Parts.BodyBox Crank4(
              height=0.05,
              widthDirection={1,0,0},
              width=0.02,
              r={0,-0.1,0});
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder Crank3(r={0.1,0,0}, diameter=0.03);
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder Crank1(diameter=0.05, r={0.1,0,0});
            Modelica.Mechanics.MultiBody.Parts.BodyBox Crank2(
              r={0,0.1,0},
              height=0.05,
              widthDirection={1,0,0},
              width=0.02);
            Joints.RevolutePlanarLoopConstraint B1(
              n={1,0,0},
              cylinderLength=0.02,
              cylinderDiameter=0.05);
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation Mid(r={0.05,0,0});
            Modelica.Mechanics.MultiBody.Joints.Prismatic Cylinder(
              boxWidth=0.02,
              n={0,-1,0},
              s(start=0.15));
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation cylPosition(                 animation=false, r={0.15,
                  0.45,0});
          equation
            connect(world.frame_b, Bearing.frame_a);
            connect(Crank2.frame_a, Crank1.frame_b);
            connect(Crank2.frame_b, Crank3.frame_a);
            connect(Bearing.frame_b, Crank1.frame_a);
            connect(cylPosition.frame_b, Cylinder.frame_a);
            connect(world.frame_b, cylPosition.frame_a);
            connect(Crank3.frame_b, Crank4.frame_a);
            connect(B1.frame_a, Mid.frame_b);
            connect(B1.frame_b, Rod.frame_b);
            connect(Rod.frame_a, B2.frame_b);
            connect(B2.frame_a, Piston.frame_b);
            connect(Inertia.flange_b, Bearing.axis);
            connect(Mid.frame_a, Crank2.frame_b);
            connect(Cylinder.frame_b, Piston.frame_a);
          end Engine1a;

          model Engine1b
          "Model of one cylinder engine with gas force and preparation for assembly joint JointRRP"
            import SI = Modelica.SIunits;
            extends Modelica.Icons.Example;
            extends Utilities.Engine1bBase;
            Joints.RevolutePlanarLoopConstraint B2(
              n={1,0,0},
              cylinderLength=0.02,
              cylinderDiameter=0.05);
            Modelica.Mechanics.MultiBody.Joints.Revolute B1(
              n={1,0,0},
              cylinderLength=0.02,
              cylinderDiameter=0.05);
            Modelica.Mechanics.MultiBody.Joints.Prismatic Cylinder(useAxisFlange=true,
              boxWidth=0.02, n={0,-1,0});
            Parts.FixedTranslation Rod1(r={0,0.2,0}, animation=false);
            Parts.FixedTranslation Rod3(r={0,-0.1,0}, animation=false);
          equation
            connect(B1.frame_b, Rod1.frame_a);
            connect(Rod1.frame_b, B2.frame_b);
            connect(Cylinder.frame_b, Rod3.frame_a);
            connect(B2.frame_a, Rod3.frame_b);
            connect(cylPosition.frame_b, Cylinder.frame_a);
            connect(gasForce.flange_a, Cylinder.support);
            connect(Cylinder.axis, gasForce.flange_b);
            connect(Piston.frame_a, Rod3.frame_a);
            connect(B1.frame_b, Rod2.frame_a);
            connect(Mid.frame_b, B1.frame_a);
          end Engine1b;

          model Engine1b_analytic
          "Model of one cylinder engine with gas force and analytic loop handling"
            import SI = Modelica.SIunits;
            extends Modelica.Icons.Example;
            extends Utilities.Engine1bBase;
            Joints.Assemblies.JointRRP jointRRP(
              n_a={1,0,0},
              n_b={0,-1,0},
              animation=false,
              rRod1_ia={0,0.2,0},
              rRod2_ib={0,-0.1,0});
          equation
            connect(Mid.frame_b, jointRRP.frame_a);
            connect(jointRRP.frame_b, cylPosition.frame_b);
            connect(jointRRP.axis, gasForce.flange_b);
            connect(jointRRP.bearing, gasForce.flange_a);
            connect(jointRRP.frame_ib, Piston.frame_a);
            connect(jointRRP.frame_ia, Rod2.frame_a);
          end Engine1b_analytic;

          model EngineV6
          "V6 engine with 6 cylinders, 6 planar loops and 1 degree-of-freedom"

            import Cv = Modelica.SIunits.Conversions;

            extends Modelica.Icons.Example;
            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            output Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm
            engineSpeed_rpm=
                   Modelica.SIunits.Conversions.to_rpm(load.w) "Engine speed";
            output Modelica.SIunits.Torque engineTorque = filter.u
            "Torque generated by engine";
            output Modelica.SIunits.Torque filteredEngineTorque = filter.y
            "Filtered torque generated by engine";

            Modelica.Mechanics.MultiBody.Joints.Revolute bearing(useAxisFlange=true,
              n={1,0,0},
              cylinderLength=0.02,
              cylinderDiameter=0.06,
              animation=animation);
            inner Modelica.Mechanics.MultiBody.World world(animateWorld=false,
                animateGravity =                                                              false);
            Utilities.Cylinder cylinder1(
              crankAngleOffset=Cv.from_deg(-30),
              cylinderInclination=Cv.from_deg(-30),
              animation=animation);
            Utilities.Cylinder cylinder2(
              crankAngleOffset=Cv.from_deg(90),
              cylinderInclination=Cv.from_deg(30),
              animation=animation);
            Utilities.Cylinder cylinder3(
              cylinderInclination=Cv.from_deg(-30),
              animation=animation,
              crankAngleOffset=Cv.from_deg(210));
            Utilities.Cylinder cylinder4(
              cylinderInclination=Cv.from_deg(30),
              animation=animation,
              crankAngleOffset=Cv.from_deg(210));
            Utilities.Cylinder cylinder5(
              cylinderInclination=Cv.from_deg(-30),
              animation=animation,
              crankAngleOffset=Cv.from_deg(90));
            Utilities.Cylinder cylinder6(
              cylinderInclination=Cv.from_deg(30),
              animation=animation,
              crankAngleOffset=Cv.from_deg(-30));
            Modelica.Mechanics.Rotational.Components.Inertia load(
                                    phi(
                start=0,
                fixed=true), w(
                start=10,
                fixed=true),
              stateSelect=StateSelect.always,
              J=1);
            Modelica.Mechanics.Rotational.Sources.QuadraticSpeedDependentTorque
            load2(                                         tau_nominal=-100, w_nominal=
                  200,
              useSupport=false);
            Rotational.Sensors.TorqueSensor torqueSensor;
            Blocks.Continuous.CriticalDamping filter(
              n=2,
              initType=Modelica.Blocks.Types.Init.SteadyState,
              f=5);
          equation

            connect(bearing.frame_b, cylinder1.crank_a);
            connect(cylinder1.crank_b, cylinder2.crank_a);
            connect(cylinder2.crank_b, cylinder3.crank_a);
            connect(cylinder3.crank_b, cylinder4.crank_a);
            connect(cylinder4.crank_b, cylinder5.crank_a);
            connect(cylinder5.crank_b, cylinder6.crank_a);
            connect(cylinder5.cylinder_b, cylinder6.cylinder_a);
            connect(cylinder4.cylinder_b, cylinder5.cylinder_a);
            connect(cylinder4.cylinder_a, cylinder3.cylinder_b);
            connect(cylinder3.cylinder_a, cylinder2.cylinder_b);
            connect(cylinder2.cylinder_a, cylinder1.cylinder_b);
            connect(world.frame_b, cylinder1.cylinder_a);
            connect(world.frame_b, bearing.frame_a);
            connect(load2.flange, load.flange_b);
            connect(torqueSensor.flange_b, load.flange_a);
            connect(torqueSensor.tau,filter. u);
            connect(torqueSensor.flange_a, bearing.axis);
          end EngineV6;

          model EngineV6_analytic
          "V6 engine with 6 cylinders, 6 planar loops, 1 degree-of-freedom and analytic handling of kinematic loops"

            import Cv = Modelica.SIunits.Conversions;
            import SI = Modelica.SIunits;
            extends Modelica.Icons.Example;
            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            output Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm
            engineSpeed_rpm=
                   Modelica.SIunits.Conversions.to_rpm(load.w) "Engine speed";
            output Modelica.SIunits.Torque engineTorque = filter.u
            "Torque generated by engine";
            output Modelica.SIunits.Torque filteredEngineTorque = filter.y
            "Filtered torque generated by engine";

            inner Modelica.Mechanics.MultiBody.World world(animateWorld=false,
                animateGravity =                                                              false);
            Utilities.EngineV6_analytic engine(redeclare model Cylinder = 

                Modelica.Mechanics.MultiBody.Examples.Loops.Utilities.Cylinder_analytic_CAD);
            Modelica.Mechanics.Rotational.Components.Inertia load(
                                                       phi(
                start=0,
                fixed=true), w(
                start=10,
                fixed=true),
              stateSelect=StateSelect.always,
              J=1);
            Modelica.Mechanics.Rotational.Sources.QuadraticSpeedDependentTorque
            load2(                                         tau_nominal=-100, w_nominal=
                  200,
              useSupport=false);
            Rotational.Sensors.TorqueSensor torqueSensor;
            Blocks.Continuous.CriticalDamping filter(
              n=2,
              initType=Modelica.Blocks.Types.Init.SteadyState,
              f=5);
          equation

            connect(world.frame_b, engine.frame_a);
            connect(load2.flange, load.flange_b);
            connect(torqueSensor.flange_a, engine.flange_b);
            connect(torqueSensor.flange_b, load.flange_a);
            connect(torqueSensor.tau, filter.u);
          end EngineV6_analytic;

          model Fourbar1
          "One kinematic loop with four bars (with only revolute joints; 5 non-linear equations)"

            import SI = Modelica.SIunits;
            extends Modelica.Icons.Example;

            output SI.Angle j1_phi "angle of revolute joint j1";
            output SI.Position j2_s "distance of prismatic joint j2";
            output SI.AngularVelocity j1_w "axis speed of revolute joint j1";
            output SI.Velocity j2_v "axis velocity of prismatic joint j2";

            inner Modelica.Mechanics.MultiBody.World world;
            Modelica.Mechanics.MultiBody.Joints.Revolute j1(
              n={1,0,0},
              stateSelect=StateSelect.always,
              phi(fixed=true),
              w(displayUnit="deg/s",
                start=5.235987755982989,
                fixed=true));
            Modelica.Mechanics.MultiBody.Joints.Prismatic j2(
              n={1,0,0},
              s(start=-0.2),
              boxWidth=0.05);
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder b1(r={0,0.5,0.1}, diameter=0.05);
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder b2(r={0,0.2,0}, diameter=0.05);
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder b3(r={-1,0.3,0.1}, diameter=0.05);
            Modelica.Mechanics.MultiBody.Joints.Revolute rev(n={0,1,0});
            Modelica.Mechanics.MultiBody.Joints.Revolute rev1;
            Modelica.Mechanics.MultiBody.Joints.Revolute j3(n={1,0,0});
            Modelica.Mechanics.MultiBody.Joints.Revolute j4(n={0,1,0});
            Modelica.Mechanics.MultiBody.Joints.Revolute j5(n={0,0,1});
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation b0(animation=false, r={1.2,0,0});
          equation
            connect(j2.frame_b, b2.frame_a);
            connect(j1.frame_b, b1.frame_a);
            connect(rev.frame_a, b2.frame_b);
            connect(rev.frame_b, rev1.frame_a);
            connect(rev1.frame_b, b3.frame_a);
            connect(world.frame_b, j1.frame_a);
            connect(b1.frame_b, j3.frame_a);
            connect(j3.frame_b, j4.frame_a);
            connect(j4.frame_b, j5.frame_a);
            connect(j5.frame_b, b3.frame_b);
            connect(b0.frame_a, world.frame_b);
            connect(b0.frame_b, j2.frame_a);
            j1_phi = j1.phi;
            j2_s = j2.s;
            j1_w = j1.w;
            j2_v = j2.v;
          end Fourbar1;

          model Fourbar2
          "One kinematic loop with four bars (with UniversalSpherical joint; 1 non-linear equation)"

            import SI = Modelica.SIunits;
            extends Modelica.Icons.Example;

            output SI.Angle j1_phi "angle of revolute joint j1";
            output SI.Position j2_s "distance of prismatic joint j2";
            output SI.AngularVelocity j1_w "axis speed of revolute joint j1";
            output SI.Velocity j2_v "axis velocity of prismatic joint j2";

            inner Modelica.Mechanics.MultiBody.World world;
            Modelica.Mechanics.MultiBody.Joints.Revolute j1(useAxisFlange=true,
              n={1,0,0},
              stateSelect=StateSelect.always,
              phi(fixed=true),
              w(displayUnit="deg/s",
                start=5.235987755982989,
                fixed=true));
            Modelica.Mechanics.MultiBody.Joints.Prismatic j2(
              n={1,0,0},
              boxWidth=0.05,
              s(fixed=true, start=-0.2));
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder b1(r={0,0.5,0.1}, diameter=0.05);
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder b2(r={0,0.2,0}, diameter=0.05);
            Modelica.Mechanics.MultiBody.Joints.UniversalSpherical
            universalSpherical(
              n1_a={0,1,0},
              computeRodLength=true,
              rRod_ia={-1,0.3,0.1});
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation b3(r={1.2,0,0}, animation=false);
            Modelica.Mechanics.MultiBody.Visualizers.FixedFrame fixedFrame(color_x={0,0,255});
          equation
            j1_phi = j1.phi;
            j2_s = j2.s;
            j1_w = j1.w;
            j2_v = j2.v;
            connect(j2.frame_b, b2.frame_a);
            connect(j1.frame_b, b1.frame_a);
            connect(j1.frame_a, world.frame_b);
            connect(b1.frame_b, universalSpherical.frame_b);
            connect(universalSpherical.frame_a, b2.frame_b);
            connect(b3.frame_a, world.frame_b);
            connect(b3.frame_b, j2.frame_a);
            connect(fixedFrame.frame_a, universalSpherical.frame_ia);
          end Fourbar2;

          model Fourbar_analytic
          "One kinematic loop with four bars (with JointSSP joint; analytic solution of non-linear algebraic loop)"

            import SI = Modelica.SIunits;
            extends Modelica.Icons.Example;

            output SI.Angle j1_phi "angle of revolute joint j1";
            output SI.Position j2_s "distance of prismatic joint j2";
            output SI.AngularVelocity j1_w "axis speed of revolute joint j1";
            output SI.Velocity j2_v "axis velocity of prismatic joint j2";

            inner Modelica.Mechanics.MultiBody.World world(animateGravity=false);
            Modelica.Mechanics.MultiBody.Joints.Revolute j1(useAxisFlange=true,
              n={1,0,0},
              stateSelect=StateSelect.always,
              phi(fixed=true),
              w(displayUnit="deg/s",
                start=5.235987755982989,
                fixed=true));
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder b1(r={0,0.5,0.1}, diameter=0.05);
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation b3(r={1.2,0,0}, animation=false);
            Modelica.Mechanics.MultiBody.Joints.Assemblies.JointSSP jointSSP(
              rod1Length=sqrt({-1,0.3,0.1}*{-1,0.3,0.1}),
              n_b={1,0,0},
              s_offset=-0.2,
              rRod2_ib={0,0.2,0},
              rod1Color={0,128,255},
              rod2Color={0,128,255},
              checkTotalPower=true);
            Modelica.Mechanics.MultiBody.Parts.BodyCylinder b2(
              r={0,0.2,0},
              diameter=0.05,
              animation=false);
          equation
            j1_phi = j1.phi;
            j2_s = jointSSP.prismatic.distance;
            j1_w = j1.w;
            j2_v = der(jointSSP.prismatic.distance);
            connect(j1.frame_b, b1.frame_a);
            connect(j1.frame_a, world.frame_b);
            connect(b3.frame_a, world.frame_b);
            connect(b1.frame_b, jointSSP.frame_a);
            connect(b3.frame_b, jointSSP.frame_b);
            connect(b2.frame_a, jointSSP.frame_ib);
          end Fourbar_analytic;

          model PlanarLoops_analytic
          "Mechanism with three planar kinematic loops and one degree-of-freedom with analytic loop handling (with JointRRR joints)"

            import SI = Modelica.SIunits;
            extends Modelica.Icons.Example;
            parameter SI.Length rh[3]={0.5,0,0}
            "Position vector from 'lower left' revolute to 'lower right' revolute joint for all the 3 loops";
            parameter SI.Length rv[3]={0,0.5,0}
            "Position vector from 'lower left' revolute to 'upper left' revolute joint in the first loop";

            parameter SI.Length r1b[3]={0.1,0.5,0}
            "Position vector from 'lower right' revolute to 'upper right' revolute joint in the first loop";
            final parameter SI.Length r1a[3]=r1b + rh - rv
            "Position vector from 'upper left' revolute to 'upper right' revolute joint in the first loop";

            parameter SI.Length r2b[3]={0.1,0.6,0}
            "Position vector from 'lower right' revolute to 'upper right' revolute joint in the second loop";
            final parameter SI.Length r2a[3]=r2b + rh - r1b
            "Position vector from 'upper left' revolute to 'upper right' revolute joint in the second loop";

            parameter SI.Length r3b[3]={0,0.55,0}
            "Position vector from 'lower right' revolute to 'upper right' revolute joint in the third loop";
            final parameter SI.Length r3a[3]=r3b + rh - r2b
            "Position vector from 'upper left' revolute to 'upper right' revolute joint in the third loop";


            inner Modelica.Mechanics.MultiBody.World world;
            Modelica.Mechanics.MultiBody.Joints.Assemblies.JointRRR jointRRR1(
              rRod1_ia=r1a,
              rRod2_ib=r1b,
              checkTotalPower=true);
            Modelica.Mechanics.MultiBody.Joints.Revolute rev(useAxisFlange=true,w(fixed=true));
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod1(r=rv);
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod2(r=rh);
            Modelica.Mechanics.MultiBody.Parts.Body body1(
              m=1,
              cylinderColor={155,155,155},
              r_CM=jointRRR1.rRod1_ia/2);
            Modelica.Mechanics.Rotational.Sources.Position position(useSupport=true);
            Modelica.Blocks.Sources.Sine sine(amplitude=0.7, freqHz=1);
            Modelica.Mechanics.MultiBody.Joints.Assemblies.JointRRR jointRRR2(
              rRod1_ia=r2a,
              rRod2_ib=r2b,
              checkTotalPower=true);
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod3(r=rh);
            Modelica.Mechanics.MultiBody.Parts.Body body2(
              m=1,
              cylinderColor={155,155,155},
              r_CM=jointRRR2.rRod1_ia/2);
            Modelica.Mechanics.MultiBody.Joints.Assemblies.JointRRR jointRRR3(
              rRod1_ia=r3a,
              rRod2_ib=r3b,
              checkTotalPower=true);
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod4(r=rh);
            Modelica.Mechanics.MultiBody.Parts.Body body3(
              m=1,
              cylinderColor={155,155,155},
              r_CM=jointRRR3.rRod1_ia/2);
            Parts.Mounting1D mounting1D;
          equation
            connect(world.frame_b, rev.frame_a);
            connect(rod1.frame_a, rev.frame_b);
            connect(rod1.frame_b, jointRRR1.frame_a);
            connect(rod2.frame_a, world.frame_b);
            connect(rod2.frame_b, jointRRR1.frame_b);
            connect(jointRRR1.frame_ia, body1.frame_a);
            connect(rod3.frame_a, rod2.frame_b);
            connect(rod3.frame_b, jointRRR2.frame_b);
            connect(jointRRR2.frame_ia, body2.frame_a);
            connect(jointRRR1.frame_im, jointRRR2.frame_a);
            connect(rod3.frame_b, rod4.frame_a);
            connect(rod4.frame_b, jointRRR3.frame_b);
            connect(jointRRR2.frame_im, jointRRR3.frame_a);
            connect(jointRRR3.frame_ia, body3.frame_a);
            connect(sine.y, position.phi_ref);
            connect(mounting1D.flange_b, position.support);
            connect(mounting1D.frame_a, world.frame_b);
            connect(position.flange, rev.axis);
          end PlanarLoops_analytic;

          package Utilities "Utility models for Examples.Loops"
            extends Modelica.Icons.Library;

            model Cylinder "Cylinder with rod and crank of a combustion engine"
              import SI = Modelica.SIunits;
              parameter Boolean animation=true
              "= true, if animation shall be enabled";
              parameter SI.Length cylinderTopPosition=0.42
              "Length from crank shaft to end of cylinder.";
              parameter SI.Length pistonLength=0.1 "Length of cylinder";
              parameter SI.Length rodLength=0.2 "Length of rod";
              parameter SI.Length crankLength=0.2
              "Length of crank shaft in x direction";
              parameter SI.Length crankPinOffset=0.1
              "Offset of crank pin from center axis";
              parameter SI.Length crankPinLength=0.1
              "Offset of crank pin from center axis";
              parameter SI.Angle cylinderInclination=0
              "Inclination of cylinder";
              parameter SI.Angle crankAngleOffset=0 "Offset for crank angle";
              parameter SI.Length cylinderLength=cylinderTopPosition - (pistonLength +
                  rodLength - crankPinOffset)
              "Maximum length of cylinder volume";

              Modelica.Mechanics.MultiBody.Parts.BodyCylinder Piston(
                diameter=0.1,
                r={0,pistonLength,0},
                color={180,180,180},
                animation=animation);
              Modelica.Mechanics.MultiBody.Parts.BodyBox Rod(
                widthDirection={1,0,0},
                height=0.06,
                color={0,0,200},
                width=0.02,
                r_shape={0,-0.02,0},
                r={0,rodLength,0},
                animation=animation);
              Modelica.Mechanics.MultiBody.Joints.Revolute B2(
                n={1,0,0},
                cylinderLength=0.02,
                animation=animation,
                cylinderDiameter=0.055);
              Modelica.Mechanics.MultiBody.Parts.BodyBox Crank4(
                height=0.05,
                widthDirection={1,0,0},
                width=0.02,
                r={0,-crankPinOffset,0},
                animation=animation);
              Modelica.Mechanics.MultiBody.Parts.BodyCylinder Crank3(
                r_shape={-0.01,0,0},
                length=0.12,
                diameter=0.03,
                r={crankPinLength,0,0},
                color={180,180,180},
                animation=animation);
              Modelica.Mechanics.MultiBody.Parts.BodyCylinder Crank1(
                diameter=0.05,
                r_shape={-0.01,0,0},
                length=0.12,
                r={crankLength - crankPinLength,0,0},
                color={180,180,180},
                animation=animation);
              Modelica.Mechanics.MultiBody.Parts.BodyBox Crank2(
                height=0.05,
                widthDirection={1,0,0},
                width=0.02,
                r={0,crankPinOffset,0},
                animation=animation);
              Joints.RevolutePlanarLoopConstraint B1(
                n={1,0,0},
                cylinderLength=0.02,
                animation=animation,
                cylinderDiameter=0.055);
              Modelica.Mechanics.MultiBody.Parts.FixedTranslation Mid(r={crankPinLength/2,0,0}, animation=
                    false);
              Modelica.Mechanics.MultiBody.Joints.Prismatic Cylinder(useAxisFlange=true,
                s(start=-0.3),
                n={0,-1,0},
                boxWidth=0.02);
              Modelica.Mechanics.MultiBody.Parts.FixedTranslation Mounting(r={crankLength,0,0}, animation=
                    false);
              Modelica.Mechanics.MultiBody.Parts.FixedRotation
              CylinderInclination(
                r={crankLength - crankPinLength/2,0,0},
                n_y={0,cos(cylinderInclination),sin(cylinderInclination)},
                animation=false,
                rotationType=Modelica.Mechanics.MultiBody.Types.RotationTypes.TwoAxesVectors);
              Modelica.Mechanics.MultiBody.Parts.FixedRotation CrankAngle1(
                n_y={0,cos(crankAngleOffset),sin(crankAngleOffset)},
                animation=false,
                rotationType=Modelica.Mechanics.MultiBody.Types.RotationTypes.TwoAxesVectors);
              Modelica.Mechanics.MultiBody.Parts.FixedRotation CrankAngle2(
                n_y={0,cos(-crankAngleOffset),sin(-crankAngleOffset)},
                animation=false,
                rotationType=Modelica.Mechanics.MultiBody.Types.RotationTypes.TwoAxesVectors);
              Modelica.Mechanics.MultiBody.Parts.FixedTranslation CylinderTop(r={0,cylinderTopPosition,0},
                  animation=false);
              GasForce gasForce(L=cylinderLength, d=0.1);
              Interfaces.Frame_a cylinder_a;
              Interfaces.Frame_a cylinder_b;
              Interfaces.Frame_a crank_a;
              Interfaces.Frame_a crank_b;
            equation
              connect(B1.frame_a, Mid.frame_b);
              connect(Rod.frame_a, B1.frame_b);
              connect(Cylinder.frame_b, Piston.frame_b);
              connect(Crank1.frame_a, CrankAngle1.frame_b);
              connect(B2.frame_a, Piston.frame_a);
              connect(Rod.frame_b, B2.frame_b);
              connect(Crank4.frame_b, CrankAngle2.frame_a);
              connect(Cylinder.support, gasForce.flange_b);
              connect(Cylinder.axis, gasForce.flange_a);
              connect(CylinderInclination.frame_b, CylinderTop.frame_a);
              connect(Crank1.frame_b, Crank2.frame_a);
              connect(Crank3.frame_b, Crank4.frame_a);
              connect(Crank3.frame_a, Crank2.frame_b);
              connect(Crank2.frame_b, Mid.frame_a);
              connect(CylinderTop.frame_b, Cylinder.frame_a);
              connect(CylinderInclination.frame_a, cylinder_a);
              connect(Mounting.frame_a, cylinder_a);
              connect(Mounting.frame_b, cylinder_b);
              connect(CrankAngle1.frame_a, crank_a);
              connect(CrankAngle2.frame_b, crank_b);

            end Cylinder;

            model GasForce "Simple gas force computation for combustion engine"
              import SI = Modelica.SIunits;

              extends
              Modelica.Mechanics.Translational.Interfaces.PartialCompliant;
              parameter SI.Length L "Length of cylinder";
              parameter SI.Diameter d "Diameter of cylinder";
              parameter SIunits.Volume k0=0.01
              "Volume V = k0 + k1*(1-x), with x = 1 + s_rel/L";
              parameter SIunits.Volume k1=1
              "Volume V = k0 + k1*(1-x), with x = 1 + s_rel/L";
              parameter SIunits.HeatCapacity k=1 "Gas constant (p*V = k*T)";
              constant Real pi=Modelica.Constants.pi;

              // Only for compatibility reasons
              Real x "Normalized position of cylinder";
              Real y "Normalized relative movement (= -s_rel/L)";
              SI.Density dens;
              Modelica.SIunits.Conversions.NonSIunits.Pressure_bar press
              "cylinder pressure";
              SI.Volume V;
              SI.Temperature T;
              SI.Velocity v_rel;
          protected
              constant SI.Mass unitMass=1;
              Modelica.SIunits.Pressure p;
            equation
              y = -s_rel/L;
              x = 1 + s_rel/L;
              v_rel = der(s_rel);

              press = p/1e5;
              p = (if v_rel < 0 then (if x < 0.987 then 177.4132*x^4 - 287.2189*x^3 +
                151.8252*x^2 - 24.9973*x + 2.4 else 2836360*x^4 - 10569296*x^3 + 14761814
                *x^2 - 9158505*x + 2129670) else (if x > 0.93 then -3929704*x^4 +
                14748765*x^3 - 20747000*x^2 + 12964477*x - 3036495 else 145.930*x^4 -
                131.707*x^3 + 17.3438*x^2 + 17.9272*x + 2.4))*1e5;

              f = -1.0E5*press*pi*d^2/4;

              V = k0 + k1*(1 - x);
              dens = unitMass/V;
              (p/1e5)*V = k*T;
            end GasForce;

            model GasForce2 "Rough approximation of gas force in a cylinder"
              import SI = Modelica.SIunits;

              extends
              Modelica.Mechanics.Translational.Interfaces.PartialCompliant;
              parameter SI.Length L "Length of cylinder";
              parameter SI.Length d "diameter of cylinder";
              parameter SIunits.Volume k0=0.01
              "Volume V = k0 + k1*(1-x), with x = 1 - s_rel/L";
              parameter SIunits.Volume k1=1
              "Volume V = k0 + k1*(1-x), with x = 1 - s_rel/L";
              parameter SIunits.HeatCapacity k=1 "Gas constant (p*V = k*T)";

            /*
  parameter Real k0=0.01;
  parameter Real k1=1;
  parameter Real k=1;
*/
              constant Real pi=Modelica.Constants.pi;
              Real x "Normalized position of cylinder (= 1 - s_rel/L)";
              SI.Density dens;
              Modelica.SIunits.AbsolutePressure press "Cylinder pressure";
              SI.Volume V;
              SI.Temperature T;
              SI.Velocity v_rel;

          protected
              Modelica.SIunits.SpecificHeatCapacity R_air = Modelica.Constants.R/0.0289651159;
            equation
              x = 1 - s_rel/L;
              v_rel = der(s_rel);

              press = 1.0E5*(if v_rel < 0 then (if x < 0.987 then 177.4132*x^4 - 287.2189*x^3 +
                151.8252*x^2 - 24.9973*x + 2.4 else 2836360*x^4 - 10569296*x^3 + 14761814
                *x^2 - 9158505*x + 2129670) else (if x > 0.93 then -3929704*x^4 +
                14748765*x^3 - 20747000*x^2 + 12964477*x - 3036495 else 145.930*x^4 -
                131.707*x^3 + 17.3438*x^2 + 17.9272*x + 2.4));

              f = -press*pi*d^2/4;

              V = k0 + k1*(1 - x);
              dens = press/(R_air*T);
              press*V = k*T;

              assert(s_rel >= -1.e-12, "flange_b.s - flange_a.s (= " + String(s_rel) +
                                       ") >= 0 required for GasForce component.\n" +
                                       "Most likely, the component has to be flipped.");
              assert(s_rel <= L + 1.e-12, " flange_b.s - flange_a.s (= " + String(s_rel) +
                                          " <= L (" + String(L) + ") required for GasForce component.\n" +
                                          "Most likely, parameter L is not correct.");
            end GasForce2;

            model CylinderBase
            "One cylinder with analytic handling of kinematic loop"
              import SI = Modelica.SIunits;
              import Cv = Modelica.SIunits.Conversions;
              parameter Boolean animation=true
              "= true, if animation shall be enabled";
              parameter SI.Length cylinderTopPosition=0.42
              "Length from crank shaft to end of cylinder.";
              parameter SI.Length crankLength=0.14
              "Length of crank shaft in x direction";
              parameter SI.Length crankPinOffset=0.05
              "Offset of crank pin from center axis";
              parameter SI.Length crankPinLength=0.1
              "Offset of crank pin from center axis";
              parameter Cv.NonSIunits.Angle_deg cylinderInclination=0
              "Inclination of cylinder";
              parameter Cv.NonSIunits.Angle_deg crankAngleOffset=0
              "Offset for crank angle";
              parameter SI.Length pistonLength=0.1 " Length of cylinder";
              parameter SI.Length pistonCenterOfMass=pistonLength/2
              " Distance from frame_a to center of mass of piston";
              parameter SI.Mass pistonMass(min=0) = 6 " Mass of piston";
              parameter SI.Inertia pistonInertia_11(min=0) = 0.0088
              " Inertia 11 of piston with respect to center of mass frame, parallel to frame_a";
              parameter SI.Inertia pistonInertia_22(min=0) = 0.0076
              " Inertia 22 of piston with respect to center of mass frame, parallel to frame_a";
              parameter SI.Inertia pistonInertia_33(min=0) = 0.0088
              " Inertia 33 of piston with respect to center of mass frame, parallel to frame_a";

              parameter SI.Length rodLength=0.175 " Length of rod";
              parameter SI.Length rodCenterOfMass=rodLength/2
              " Distance from frame_a to center of mass of piston";
              parameter SI.Mass rodMass(min=0) = 1 " Mass of rod";
              parameter SI.Inertia rodInertia_11(min=0) = 0.006
              " Inertia 11 of rod with respect to center of mass frame, parallel to frame_a";
              parameter SI.Inertia rodInertia_22(min=0) = 0.0005
              " Inertia 22 of rod with respect to center of mass frame, parallel to frame_a";
              parameter SI.Inertia rodInertia_33(min=0) = 0.006
              " Inertia 33 of rod with respect to center of mass frame, parallel to frame_a";
              final parameter SI.Length cylinderLength=cylinderTopPosition - (
                  pistonLength + rodLength - crankPinOffset)
              "Maximum length of cylinder volume";

              Modelica.Mechanics.MultiBody.Parts.FixedTranslation Mid(animation=false, r={crankLength -
                    crankPinLength/2,crankPinOffset,0});
              Modelica.Mechanics.MultiBody.Parts.FixedTranslation Mounting(r={crankLength,0,0}, animation=
                    false);
              Modelica.Mechanics.MultiBody.Parts.FixedRotation
              CylinderInclination(
                r={crankLength - crankPinLength/2,0,0},
                animation=false,
                rotationType=Modelica.Mechanics.MultiBody.Types.RotationTypes.RotationAxis,
                n={1,0,0},
                angle=cylinderInclination);
              Modelica.Mechanics.MultiBody.Parts.FixedRotation CrankAngle(
                animation=false,
                rotationType=Modelica.Mechanics.MultiBody.Types.RotationTypes.RotationAxis,
                n={1,0,0},
                angle=crankAngleOffset);
              Joints.Assemblies.JointRRP jointRRP(
                n_a={1,0,0},
                n_b={0,-1,0},
                rRod1_ia={0,rodLength,0},
                animation=false,
                rRod2_ib=-{0,pistonLength,0},
                s_offset=-cylinderTopPosition);
              Modelica.Mechanics.MultiBody.Parts.BodyShape Rod(
                animation=animation,
                r={0,rodLength,0},
                r_CM={0,rodLength/2,0},
                shapeType="2",
                lengthDirection={1,0,0},
                widthDirection={0,0,-1},
                length=rodLength/1.75,
                width=rodLength/1.75,
                height=rodLength/1.75,
                color={155,155,155},
                extra=1,
                r_shape={0,0,0},
                animateSphere=false,
                m=rodMass,
                I_11=rodInertia_11,
                I_22=rodInertia_22,
                I_33=rodInertia_33);
              Modelica.Mechanics.MultiBody.Parts.BodyShape Piston(
                animation=animation,
                r={0,pistonLength,0},
                r_CM={0,pistonLength/2,0},
                shapeType="3",
                length=0.08,
                width=0.08,
                height=0.08,
                extra=1,
                lengthDirection={1,0,0},
                widthDirection={0,0,-1},
                color={180,180,180},
                animateSphere=false,
                m=pistonMass,
                I_11=pistonInertia_11,
                I_22=pistonInertia_22,
                I_33=pistonInertia_33);
              GasForce gasForce(L=cylinderLength, d=0.1);

              Modelica.Mechanics.MultiBody.Parts.FixedTranslation Crank(animation=false, r={crankLength,0,0});
              Interfaces.Frame_a cylinder_a;
              Interfaces.Frame_a cylinder_b;
              Interfaces.Frame_a crank_a;
              Interfaces.Frame_a crank_b;
            equation

              connect(jointRRP.frame_ia, Rod.frame_a);
              connect(Mid.frame_b, jointRRP.frame_a);
              connect(gasForce.flange_a, jointRRP.axis);
              connect(jointRRP.bearing, gasForce.flange_b);
              connect(jointRRP.frame_ib, Piston.frame_b);
              connect(jointRRP.frame_b, CylinderInclination.frame_b);
              connect(CrankAngle.frame_b, Mid.frame_a);
              connect(cylinder_a, CylinderInclination.frame_a);
              connect(cylinder_a, Mounting.frame_a);
              connect(cylinder_b, Mounting.frame_b);
              connect(CrankAngle.frame_a, crank_a);
              connect(crank_a, Crank.frame_a);
              connect(Crank.frame_b, crank_b);
            end CylinderBase;

            model Cylinder_analytic_CAD
            "One cylinder with analytic handling of kinematic loop and CAD visualization"
              extends CylinderBase;
              Visualizers.FixedShape CrankShape(
                animation=animation,
                shapeType="1",
                lengthDirection={1,0,0},
                extra=1,
                widthDirection={0,1,0},
                length=crankPinOffset/0.5,
                width=crankPinOffset/0.5,
                height=crankPinOffset/0.5,
                r_shape={crankLength - crankPinLength/2 - 0.002,0,0});
            equation

              connect(CrankShape.frame_a, CrankAngle.frame_b);
            end Cylinder_analytic_CAD;

            model EngineV6_analytic "V6 engine with analytic loop handling"
              import SI = Modelica.SIunits;
              parameter Boolean animation=true
              "= true, if animation shall be enabled";
              replaceable model Cylinder = Cylinder_analytic_CAD constrainedby
              CylinderBase "Cylinder type";

              Cylinder cylinder1(
                crankAngleOffset=-30,
                cylinderInclination=-30,
                animation=animation);
              Cylinder cylinder2(
                crankAngleOffset=90,
                cylinderInclination=30,
                animation=animation);
              Cylinder cylinder3(
                cylinderInclination=-30,
                animation=animation,
                crankAngleOffset=210);
              Cylinder cylinder4(
                cylinderInclination=30,
                animation=animation,
                crankAngleOffset=210);
              Cylinder cylinder5(
                cylinderInclination=-30,
                animation=animation,
                crankAngleOffset=90);
              Cylinder cylinder6(
                cylinderInclination=30,
                animation=animation,
                crankAngleOffset=-30);
              Joints.Revolute bearing(useAxisFlange=true,
                n={1,0,0},
                cylinderLength=0.02,
                cylinderDiameter=0.06,
                animation=true);
              Parts.BodyShape crank(
                animation=false,
                r_CM={6*0.1/2,0,0},
                I_22=1.e-5,
                I_33=1.e-5,
                m=6*30,
                I_11=0.1);
              Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b;
              Interfaces.Frame_a frame_a;
            equation
              connect(cylinder1.crank_b, cylinder2.crank_a);
              connect(cylinder2.cylinder_a, cylinder1.cylinder_b);
              connect(cylinder3.cylinder_a, cylinder2.cylinder_b);
              connect(cylinder3.crank_a, cylinder2.crank_b);
              connect(cylinder3.cylinder_b, cylinder4.cylinder_a);
              connect(cylinder3.crank_b, cylinder4.crank_a);
              connect(cylinder4.cylinder_b, cylinder5.cylinder_a);
              connect(cylinder4.crank_b, cylinder5.crank_a);
              connect(cylinder5.cylinder_b, cylinder6.cylinder_a);
              connect(cylinder5.crank_b, cylinder6.crank_a);
              connect(bearing.frame_b, crank.frame_a);
              connect(crank.frame_b, cylinder1.crank_a);
              connect(bearing.axis, flange_b);
              connect(frame_a, bearing.frame_a);
              connect(bearing.frame_a, cylinder1.cylinder_a);
            end EngineV6_analytic;

            partial model Engine1bBase
            "Model of one cylinder engine with gas force"
              import SI = Modelica.SIunits;
              extends Modelica.Icons.Example;
              Modelica.Mechanics.MultiBody.Parts.BodyCylinder Piston(diameter=0.1, r={0,-0.1,0});
              Modelica.Mechanics.MultiBody.Parts.BodyBox Rod2(
                widthDirection={1,0,0},
                width=0.02,
                height=0.06,
                color={0,0,200},
                r={0,0.2,0});
              Modelica.Mechanics.MultiBody.Joints.Revolute Bearing(useAxisFlange=true,
                n={1,0,0},
                cylinderLength=0.02,
                cylinderDiameter=0.05);
              inner Modelica.Mechanics.MultiBody.World world;
              Modelica.Mechanics.Rotational.Components.Inertia Inertia(
                stateSelect=StateSelect.always,
                J=0.1,
                w(fixed=true),
                phi(
                  fixed=true,
                  start=0.001,
                  displayUnit="rad"));
              Modelica.Mechanics.MultiBody.Parts.BodyBox Crank4(
                height=0.05,
                widthDirection={1,0,0},
                width=0.02,
                r={0,-0.1,0});
              Modelica.Mechanics.MultiBody.Parts.BodyCylinder Crank3(r={0.1,0,0}, diameter=0.03);
              Modelica.Mechanics.MultiBody.Parts.BodyCylinder Crank1(diameter=0.05, r={0.1,0,0});
              Modelica.Mechanics.MultiBody.Parts.BodyBox Crank2(
                height=0.05,
                widthDirection={1,0,0},
                width=0.02,
                r={0,0.1,0});
              Modelica.Mechanics.MultiBody.Parts.FixedTranslation Mid(r={0.05,0,0});
              Modelica.Mechanics.MultiBody.Parts.FixedTranslation cylPosition(                 animation=false, r={0.15,
                    0.55,0});
              Utilities.GasForce2 gasForce(        d=0.1, L=0.35);
            equation
              connect(world.frame_b, Bearing.frame_a);
              connect(Crank2.frame_a, Crank1.frame_b);
              connect(Crank2.frame_b, Crank3.frame_a);
              connect(Bearing.frame_b, Crank1.frame_a);
              connect(world.frame_b, cylPosition.frame_a);
              connect(Crank3.frame_b, Crank4.frame_a);
              connect(Inertia.flange_b, Bearing.axis);
              connect(Mid.frame_a, Crank2.frame_b);
            end Engine1bBase;
          end Utilities;
        end Loops;
      end Examples;

      package Frames "Functions to transform rotational frame quantities"
        extends Modelica.Icons.Library;

        record Orientation
        "Orientation object defining rotation from a frame 1 into a frame 2"

          import SI = Modelica.SIunits;
          extends Modelica.Icons.Record;
          Real T[3, 3] "Transformation matrix from world frame to local frame";
          SI.AngularVelocity w[3]
          "Absolute angular velocity of local frame, resolved in local frame";

          encapsulated function equalityConstraint
          "Return the constraint residues to express that two frames have the same orientation"

            import Modelica;
            import Modelica.Mechanics.MultiBody.Frames;
            extends Modelica.Icons.Function;
            input Frames.Orientation R1
            "Orientation object to rotate frame 0 into frame 1";
            input Frames.Orientation R2
            "Orientation object to rotate frame 0 into frame 2";
            output Real residue[3]
            "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)";
          algorithm
            residue := {
               Modelica.Math.atan2(cross(R1.T[1, :], R1.T[2, :])*R2.T[2, :],R1.T[1,:]*R2.T[1,:]),
               Modelica.Math.atan2(-cross(R1.T[1, :],R1.T[2, :])*R2.T[1, :],R1.T[2,:]*R2.T[2,:]),
               Modelica.Math.atan2(R1.T[2, :]*R2.T[1, :],R1.T[3,:]*R2.T[3,:])};
            annotation(Inline=true);               
          end equalityConstraint;


        end Orientation;

        function angularVelocity2
        "Return angular velocity resolved in frame 2 from orientation object"

          extends Modelica.Icons.Function;
          input Orientation R
          "Orientation object to rotate frame 1 into frame 2";
          output Modelica.SIunits.AngularVelocity w[3]
          "Angular velocity of frame 2 with respect to frame 1 resolved in frame 2";
        algorithm
          w := R.w;
          annotation(Inline=true);
        end angularVelocity2;

        function resolve1 "Transform vector from frame 2 to frame 1"
          extends Modelica.Icons.Function;
          input Orientation R
          "Orientation object to rotate frame 1 into frame 2";
          input Real v2[3] "Vector in frame 2";
          output Real v1[3] "Vector in frame 1";
        algorithm
          v1 := transpose(R.T)*v2;
        end resolve1;

        function resolve2 "Transform vector from frame 1 to frame 2"
          extends Modelica.Icons.Function;
          input Orientation R
          "Orientation object to rotate frame 1 into frame 2";
          input Real v1[3] "Vector in frame 1";
          output Real v2[3] "Vector in frame 2";
        algorithm
          v2 := R.T*v1;
        end resolve2;

        function resolveRelative
        "Transform vector from frame 1 to frame 2 using absolute orientation objects of frame 1 and of frame 2"

          extends Modelica.Icons.Function;
          input Real v1[3] "Vector in frame 1";
          input Orientation R1
          "Orientation object to rotate frame 0 into frame 1";
          input Orientation R2
          "Orientation object to rotate frame 0 into frame 2";
          output Real v2[3] "Vector in frame 2";
        algorithm
          v2 := resolve2(R2, resolve1(R1, v1));
        end resolveRelative;

        function resolveDyade1
        "Transform second order tensor from frame 2 to frame 1"
          extends Modelica.Icons.Function;
          input Orientation R
          "Orientation object to rotate frame 1 into frame 2";
          input Real D2[3, 3] "Second order tensor resolved in frame 2";
          output Real D1[3, 3] "Second order tensor resolved in frame 1";
        algorithm
          D1 := transpose(R.T)*D2*R.T;
        end resolveDyade1;

        function nullRotation
        "Return orientation object that does not rotate a frame"
          extends Modelica.Icons.Function;
          output Orientation R
          "Orientation object such that frame 1 and frame 2 are identical";
        algorithm
          R := Orientation(T=identity(3),w= zeros(3));
        end nullRotation;

        function relativeRotation "Return relative orientation object"
          extends Modelica.Icons.Function;
          input Orientation R1
          "Orientation object to rotate frame 0 into frame 1";
          input Orientation R2
          "Orientation object to rotate frame 0 into frame 2";
          output Orientation R_rel
          "Orientation object to rotate frame 1 into frame 2";
        algorithm
          R_rel := Orientation(T=R2.T*transpose(R1.T),w= R2.w - resolve2(R2, resolve1(
             R1, R1.w)));
        end relativeRotation;

        function absoluteRotation
        "Return absolute orientation object from another absolute and a relative orientation object"

          extends Modelica.Icons.Function;
          input Orientation R1
          "Orientation object to rotate frame 0 into frame 1";
          input Orientation R_rel
          "Orientation object to rotate frame 1 into frame 2";
          output Orientation R2
          "Orientation object to rotate frame 0 into frame 2";
        algorithm
          R2 := Orientation(T=R_rel.T*R1.T,w= resolve2(R_rel, R1.w) + R_rel.w);
        end absoluteRotation;

        function planarRotation
        "Return orientation object of a planar rotation"
          import Modelica.Math;
          extends Modelica.Icons.Function;
          input Real e[3](each final unit="1")
          "Normalized axis of rotation (must have length=1)";
          input Modelica.SIunits.Angle angle
          "Rotation angle to rotate frame 1 into frame 2 along axis e";
          input Modelica.SIunits.AngularVelocity der_angle "= der(angle)";
          output Orientation R
          "Orientation object to rotate frame 1 into frame 2";
        algorithm
          R := Orientation(T=[e]*transpose([e]) + (identity(3) - [e]*transpose([e]))*
            Math.cos(angle) - skew(e)*Math.sin(angle),w= e*der_angle);

        end planarRotation;

        function planarRotationAngle
        "Return angle of a planar rotation, given the rotation axis and the representations of a vector in frame 1 and frame 2"

          extends Modelica.Icons.Function;
          input Real e[3](each final unit="1")
          "Normalized axis of rotation to rotate frame 1 around e into frame 2 (must have length=1)";
          input Real v1[3]
          "A vector v resolved in frame 1 (shall not be parallel to e)";
          input Real v2[3]
          "Vector v resolved in frame 2, i.e., v2 = resolve2(planarRotation(e,angle),v1)";
          output Modelica.SIunits.Angle angle
          "Rotation angle to rotate frame 1 into frame 2 along axis e in the range: -pi <= angle <= pi";
        algorithm
          /* Vector v is resolved in frame 1 and frame 2 according to:
        (1)  v2 = (e*transpose(e) + (identity(3) - e*transpose(e))*cos(angle) - skew(e)*sin(angle))*v1;
                = e*(e*v1) + (v1 - e*(e*v1))*cos(angle) - cross(e,v1)*sin(angle)
       Equation (1) is multiplied with "v1" resulting in (note: e*e = 1)
            v1*v2 = (e*v1)*(e*v2) + (v1*v1 - (e*v1)*(e*v1))*cos(angle)
       and therefore:
        (2) cos(angle) = ( v1*v2 - (e*v1)*(e*v2)) / (v1*v1 - (e*v1)*(e*v1))
       Similiarly, equation (1) is multiplied with cross(e,v1), i.e., a
       a vector that is orthogonal to e and to v1:
              cross(e,v1)*v2 = - cross(e,v1)*cross(e,v1)*sin(angle)
       and therefore:
          (3) sin(angle) = -cross(e,v1)*v2/(cross(e,v1)*cross(e,v1));
       We have e*e=1; Therefore:
          (4) v1*v1 - (e*v1)*(e*v1) = |v1|^2 - (|v1|*cos(e,v1))^2
       and
          (5) cross(e,v1)*cross(e,v1) = (|v1|*sin(e,v1))^2
                                      = |v1|^2*(1 - cos(e,v1)^2)
                                      = |v1|^2 - (|v1|*cos(e,v1))^2
       The denominators of (2) and (3) are identical, according to (4) and (5).
       Furthermore, the denominators are always positive according to (5).
       Therefore, in the equation "angle = atan2(sin(angle), cos(angle))" the
       denominators of sin(angle) and cos(angle) can be removed,
       resulting in:
          angle = atan2(-cross(e,v1)*v2, v1*v2 - (e*v1)*(e*v2));
    */
          angle := Modelica.Math.atan2(-cross(e, v1)*v2, v1*v2 - (e*v1)*(e*v2));
        end planarRotationAngle;

        function axesRotations
        "Return fixed rotation object to rotate in sequence around fixed angles along 3 axes"

          import TM =
          Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
          extends Modelica.Icons.Function;
          input Integer sequence[3](
            min={1,1,1},
            max={3,3,3}) = {1,2,3}
          "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
          input Modelica.SIunits.Angle angles[3]
          "Rotation angles around the axes defined in 'sequence'";
          input Modelica.SIunits.AngularVelocity der_angles[3] "= der(angles)";
          output Orientation R
          "Orientation object to rotate frame 1 into frame 2";
        algorithm
          /*
  R := absoluteRotation(absoluteRotation(axisRotation(sequence[1], angles[1],
    der_angles[1]), axisRotation(sequence[2], angles[2], der_angles[2])),
    axisRotation(sequence[3], angles[3], der_angles[3]));
*/
          R := Orientation(T=TM.axisRotation(sequence[3], angles[3])*TM.axisRotation(
            sequence[2], angles[2])*TM.axisRotation(sequence[1], angles[1]),w=
            Frames.axis(sequence[3])*der_angles[3] + TM.resolve2(TM.axisRotation(
            sequence[3], angles[3]), Frames.axis(sequence[2])*der_angles[2]) +
            TM.resolve2(TM.axisRotation(sequence[3], angles[3])*TM.axisRotation(
            sequence[2], angles[2]), Frames.axis(sequence[1])*der_angles[1]));
        end axesRotations;

        function axesRotationsAngles
        "Return the 3 angles to rotate in sequence around 3 axes to construct the given orientation object"

          import SI = Modelica.SIunits;

          extends Modelica.Icons.Function;
          input Orientation R
          "Orientation object to rotate frame 1 into frame 2";
          input Integer sequence[3](
            min={1,1,1},
            max={3,3,3}) = {1,2,3}
          "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
          input SI.Angle guessAngle1=0
          "Select angles[1] such that |angles[1] - guessAngle1| is a minimum";
          output SI.Angle angles[3]
          "Rotation angles around the axes defined in 'sequence' such that R=Frames.axesRotation(sequence,angles); -pi < angles[i] <= pi";
      protected
          Real e1_1[3](each final unit="1")
          "First rotation axis, resolved in frame 1";
          Real e2_1a[3](each final unit="1")
          "Second rotation axis, resolved in frame 1a";
          Real e3_1[3](each final unit="1")
          "Third rotation axis, resolved in frame 1";
          Real e3_2[3](each final unit="1")
          "Third rotation axis, resolved in frame 2";
          Real A
          "Coefficient A in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
          Real B
          "Coefficient B in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
          SI.Angle angle_1a "Solution 1 for angles[1]";
          SI.Angle angle_1b "Solution 2 for angles[1]";
          TransformationMatrices.Orientation T_1a
          "Orientation object to rotate frame 1 into frame 1a";
        algorithm
          /* The rotation object R is constructed by:
     (1) Rotating frame 1 along axis e1 (= axis sequence[1]) with angles[1]
         arriving at frame 1a.
     (2) Rotating frame 1a along axis e2 (= axis sequence[2]) with angles[2]
         arriving at frame 1b.
     (3) Rotating frame 1b along axis e3 (= axis sequence[3]) with angles[3]
         arriving at frame 2.
     The goal is to determine angles[1:3]. This is performed in the following way:
     1. e2 and e3 are perpendicular to each other, i.e., e2*e3 = 0;
        Both vectors are resolved in frame 1 (T_ij is transformation matrix
        from frame j to frame i; e1_1*e2_1a = 0, since the vectors are
        perpendicular to each other):
           e3_1 = T_12*e3_2
                = R[sequence[3],:];
           e2_1 = T_11a*e2_1a
                = ( e1_1*transpose(e1_1) + (identity(3) - e1_1*transpose(e1_1))*cos(angles[1])
                    + skew(e1_1)*sin(angles[1]) )*e2_1a
                = e2_1a*cos(angles[1]) + cross(e1_1, e2_1a)*sin(angles[1]);
        From this follows finally an equation for angles[1]
           e2_1*e3_1 = 0
                     = (e2_1a*cos(angles[1]) + cross(e1_1, e2_1a)*sin(angles[1]))*e3_1
                     = (e2_1a*e3_1)*cos(angles[1]) + cross(e1_1, e2_1a)*e3_1*sin(angles[1])
                     = A*cos(angles[1]) + B*sin(angles[1])
                       with A = e2_1a*e3_1, B = cross(e1_1, e2_1a)*e3_1
        This equation has two solutions in the range -pi < angles[1] <= pi:
           sin(angles[1]) =  k*A/sqrt(A*A + B*B)
           cos(angles[1]) = -k*B/sqrt(A*A + B*B)
                        k = +/-1
           tan(angles[1]) = k*A/(-k*B)
        that is:
           angles[1] = atan2(k*A, -k*B)
        If A and B are both zero at the same time, there is a singular configuration
        resulting in an infinite number of solutions for angles[1] (every value
        is possible).
     2. angles[2] is determined with function Frames.planarRotationAngle.
        This function requires to provide e_3 in frame 1a and in frame 1b:
          e3_1a = Frames.resolve2(planarRotation(e1_1,angles[1]), e3_1);
          e3_1b = e3_2
     3. angles[3] is determined with function Frames.planarRotationAngle.
        This function requires to provide e_2 in frame 1b and in frame 2:
          e2_1b = e2_1a
          e2_2  = Frames.resolve2( R, Frames.resolve1(planarRotation(e1_1,angles[1]), e2_1a));
  */
          assert(sequence[1] <> sequence[2] and sequence[2] <> sequence[3],
            "input argument 'sequence[1:3]' is not valid");
          e1_1 := if sequence[1] == 1 then {1,0,0} else if sequence[1] == 2 then {0,1,
            0} else {0,0,1};
          e2_1a := if sequence[2] == 1 then {1,0,0} else if sequence[2] == 2 then {0,
            1,0} else {0,0,1};
          e3_1 := R.T[sequence[3], :];
          e3_2 := if sequence[3] == 1 then {1,0,0} else if sequence[3] == 2 then {0,1,
            0} else {0,0,1};

          A := e2_1a*e3_1;
          B := cross(e1_1, e2_1a)*e3_1;
          if abs(A) <= 1.e-12 and abs(B) <= 1.e-12 then
            angles[1] := guessAngle1;
          else
            angle_1a := Modelica.Math.atan2(A, -B);
            angle_1b := Modelica.Math.atan2(-A, B);
            angles[1] := if abs(angle_1a - guessAngle1) <= abs(angle_1b - guessAngle1) then 
                    angle_1a else angle_1b;
          end if;
          T_1a := TransformationMatrices.planarRotation(e1_1, angles[1]);
          angles[2] := planarRotationAngle(e2_1a, TransformationMatrices.resolve2(
            T_1a, e3_1), e3_2);
          angles[3] := planarRotationAngle(e3_2, e2_1a,
            TransformationMatrices.resolve2(R.T, TransformationMatrices.resolve1(T_1a,
             e2_1a)));

        end axesRotationsAngles;

        function from_nxy
        "Return fixed orientation object from n_x and n_y vectors"
          extends Modelica.Icons.Function;
          input Real n_x[3](each final unit="1")
          "Vector in direction of x-axis of frame 2, resolved in frame 1";
          input Real n_y[3](each final unit="1")
          "Vector in direction of y-axis of frame 2, resolved in frame 1";
          output Orientation R
          "Orientation object to rotate frame 1 into frame 2";
      protected
          Real abs_n_x=sqrt(n_x*n_x);
          Real e_x[3](each final unit="1")=if abs_n_x < 1.e-10 then {1,0,0} else n_x/abs_n_x;
          Real n_z_aux[3](each final unit="1")=cross(e_x, n_y);
          Real n_y_aux[3](each final unit="1")=if n_z_aux*n_z_aux > 1.0e-6 then n_y else (if abs(e_x[1])
               > 1.0e-6 then {0,1,0} else {1,0,0});
          Real e_z_aux[3](each final unit="1")=cross(e_x, n_y_aux);
          Real e_z[3](each final unit="1")=e_z_aux/sqrt(e_z_aux*e_z_aux);
        algorithm
          R := Orientation(T={e_x,cross(e_z, e_x),e_z},w= zeros(3));
        end from_nxy;

        function from_T
        "Return orientation object R from transformation matrix T"
          extends Modelica.Icons.Function;
          input Real T[3, 3]
          "Transformation matrix to transform vector from frame 1 to frame 2 (v2=T*v1)";
          input Modelica.SIunits.AngularVelocity w[3]
          "Angular velocity from frame 2 with respect to frame 1, resolved in frame 2 (skew(w)=T*der(transpose(T)))";
          output Orientation R
          "Orientation object to rotate frame 1 into frame 2";
        algorithm
          R := Orientation(T=T,w= w);
        end from_T;

        function from_Q
        "Return orientation object R from quaternion orientation object Q"

          extends Modelica.Icons.Function;
          input Quaternions.Orientation Q
          "Quaternions orientation object to rotate frame 1 into frame 2";
          input Modelica.SIunits.AngularVelocity w[3]
          "Angular velocity from frame 2 with respect to frame 1, resolved in frame 2";
          output Orientation R
          "Orientation object to rotate frame 1 into frame 2";
        algorithm
          /*
  T := (2*Q[4]*Q[4] - 1)*identity(3) + 2*([Q[1:3]]*transpose([Q[1:3]]) - Q[4]*
    skew(Q[1:3]));
*/
          R := Orientation([2*(Q[1]*Q[1] + Q[4]*Q[4]) - 1, 2*(Q[1]*Q[2] + Q[3]*Q[4]),
             2*(Q[1]*Q[3] - Q[2]*Q[4]); 2*(Q[2]*Q[1] - Q[3]*Q[4]), 2*(Q[2]*Q[2] + Q[4]
            *Q[4]) - 1, 2*(Q[2]*Q[3] + Q[1]*Q[4]); 2*(Q[3]*Q[1] + Q[2]*Q[4]), 2*(Q[3]
            *Q[2] - Q[1]*Q[4]), 2*(Q[3]*Q[3] + Q[4]*Q[4]) - 1],w= w);
        end from_Q;

        function to_Q
        "Return quaternion orientation object Q from orientation object R"

          extends Modelica.Icons.Function;
          input Orientation R
          "Orientation object to rotate frame 1 into frame 2";
          input Quaternions.Orientation Q_guess=Quaternions.nullRotation()
          "Guess value for output Q (there are 2 solutions; the one closer to Q_guess is used";
          output Quaternions.Orientation Q
          "Quaternions orientation object to rotate frame 1 into frame 2";
        algorithm
          Q := Quaternions.from_T(R.T, Q_guess);
        end to_Q;

        function axis "Return unit vector for x-, y-, or z-axis"
          extends Modelica.Icons.Function;
          input Integer axis(min=1, max=3) "Axis vector to be returned";
          output Real e[3](each final unit="1") "Unit axis vector";
        algorithm
          e := if axis == 1 then {1,0,0} else (if axis == 2 then {0,1,0} else {0,0,1});
        end axis;

        package Quaternions
        "Functions to transform rotational frame quantities based on quaternions (also called Euler parameters)"
          extends Modelica.Icons.Library;

          type Orientation
          "Orientation type defining rotation from a frame 1 into a frame 2 with quaternions {p1,p2,p3,p0}"

            extends Internal.QuaternionBase;

            encapsulated function equalityConstraint
            "Return the constraint residues to express that two frames have the same quaternion orientation"

              import Modelica;
              import Modelica.Mechanics.MultiBody.Frames.Quaternions;
              extends Modelica.Icons.Function;
              input Quaternions.Orientation Q1
              "Quaternions orientation object to rotate frame 0 into frame 1";
              input Quaternions.Orientation Q2
              "Quaternions orientation object to rotate frame 0 into frame 2";
              output Real residue[3]
              "The half of the rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (shall be zero)";
            algorithm
              residue := [Q1[4], Q1[3], -Q1[2], -Q1[1]; -Q1[3], Q1[4], Q1[1], -Q1[2];
                 Q1[2], -Q1[1], Q1[4], -Q1[3]]*Q2;
              annotation(Inline=true);
            end equalityConstraint;

          end Orientation;

          type der_Orientation = Real[4] (each unit="1/s")
          "First time derivative of Quaternions.Orientation";

          function orientationConstraint
          "Return residues of orientation constraints (shall be zero)"
            extends Modelica.Icons.Function;
            input Quaternions.Orientation Q
            "Quaternions orientation object to rotate frame 1 into frame 2";
            output Real residue[1] "Residue constraint (shall be zero)";
          algorithm
            residue := {Q*Q - 1};
            annotation(Inline=true);
          end orientationConstraint;

          function angularVelocity2
          "Compute angular velocity resolved in frame 2 from quaternions orientation object and its derivative"

            extends Modelica.Icons.Function;
            input Quaternions.Orientation Q
            "Quaternions orientation object to rotate frame 1 into frame 2";
            input der_Orientation der_Q "Derivative of Q";
            output Modelica.SIunits.AngularVelocity w[3]
            "Angular velocity of frame 2 with respect to frame 1 resolved in frame 2";
          algorithm
            w := 2*([Q[4], Q[3], -Q[2], -Q[1]; -Q[3], Q[4], Q[1], -Q[2]; Q[2], -Q[1],
               Q[4], -Q[3]]*der_Q);
          end angularVelocity2;

          function nullRotation
          "Return quaternions orientation object that does not rotate a frame"

            extends Modelica.Icons.Function;
            output Quaternions.Orientation Q
            "Quaternions orientation object to rotate frame 1 into frame 2";
          algorithm
            Q := {0,0,0,1};
          end nullRotation;

          function from_T
          "Return quaternions orientation object Q from transformation matrix T"

            extends Modelica.Icons.Function;
            input Real T[3, 3]
            "Transformation matrix to transform vector from frame 1 to frame 2 (v2=T*v1)";
            input Quaternions.Orientation Q_guess=nullRotation()
            "Guess value for Q (there are 2 solutions; the one close to Q_guess is used";
            output Quaternions.Orientation Q
            "Quaternions orientation object to rotate frame 1 into frame 2 (Q and -Q have same transformation matrix)";
        protected
            Real paux;
            Real paux4;
            Real c1;
            Real c2;
            Real c3;
            Real c4;
            constant Real p4limit=0.1;
            constant Real c4limit=4*p4limit*p4limit;
          algorithm
            /*
   Note, for quaternions, Q and -Q have the same transformation matrix.
   Calculation of quaternions from transformation matrix T:
   It is guaranteed that c1>=0, c2>=0, c3>=0, c4>=0 and
   that not all of them can be zero at the same time
   (e.g. if 3 of them are zero, the 4th variable is 1).
   Since the sqrt(..) has to be performed on one of these variables,
   it is applied on a variable which is far enough from zero.
   This guarantees that the sqrt(..) is never taken near zero
   and therefore the derivative of sqrt(..) can never be infinity.
   There is an ambiguity for quaternions, since Q and -Q
   lead to the same transformation matrix. The ambiguity
   is resolved here by selecting the Q that is closer to
   the input argument Q_guess.
*/
            c1 := 1 + T[1, 1] - T[2, 2] - T[3, 3];
            c2 := 1 + T[2, 2] - T[1, 1] - T[3, 3];
            c3 := 1 + T[3, 3] - T[1, 1] - T[2, 2];
            c4 := 1 + T[1, 1] + T[2, 2] + T[3, 3];

            if c4 > c4limit or (c4 > c1 and c4 > c2 and c4 > c3) then
              paux := sqrt(c4)/2;
              paux4 := 4*paux;
              Q := {(T[2, 3] - T[3, 2])/paux4,(T[3, 1] - T[1, 3])/paux4,(T[1, 2] - T[
                2, 1])/paux4,paux};

            elseif c1 > c2 and c1 > c3 and c1 > c4 then
              paux := sqrt(c1)/2;
              paux4 := 4*paux;
              Q := {paux,(T[1, 2] + T[2, 1])/paux4,(T[1, 3] + T[3, 1])/paux4,(T[2, 3]
                 - T[3, 2])/paux4};

            elseif c2 > c1 and c2 > c3 and c2 > c4 then
              paux := sqrt(c2)/2;
              paux4 := 4*paux;
              Q := {(T[1, 2] + T[2, 1])/paux4,paux,(T[2, 3] + T[3, 2])/paux4,(T[3, 1]
                 - T[1, 3])/paux4};

            else
              paux := sqrt(c3)/2;
              paux4 := 4*paux;
              Q := {(T[1, 3] + T[3, 1])/paux4,(T[2, 3] + T[3, 2])/paux4,paux,(T[1, 2]
                 - T[2, 1])/paux4};
            end if;

            if Q*Q_guess < 0 then
              Q := -Q;
            end if;
          end from_T;
        end Quaternions;

        package TransformationMatrices "Functions for transformation matrices"
          extends Modelica.Icons.Library;

          type Orientation
          "Orientation type defining rotation from a frame 1 into a frame 2 with a transformation matrix"

            extends Internal.TransformationMatrix;

            encapsulated function equalityConstraint
            "Return the constraint residues to express that two frames have the same orientation"

              import Modelica;
              import Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
              extends Modelica.Icons.Function;
              input TransformationMatrices.Orientation T1
              "Orientation object to rotate frame 0 into frame 1";
              input TransformationMatrices.Orientation T2
              "Orientation object to rotate frame 0 into frame 2";
              output Real residue[3]
              "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)";
            algorithm
              residue := {cross(T1[1, :], T1[2, :])*T2[2, :],-cross(T1[1, :], T1[2, :])
                *T2[1, :],T1[2, :]*T2[1, :]};
            end equalityConstraint;
          end Orientation;

          function resolve1 "Transform vector from frame 2 to frame 1"
            extends Modelica.Icons.Function;
            input TransformationMatrices.Orientation T
            "Orientation object to rotate frame 1 into frame 2";
            input Real v2[3] "Vector in frame 2";
            output Real v1[3] "Vector in frame 1";
          algorithm
            v1 := transpose(T)*v2;
          end resolve1;

          function resolve2 "Transform vector from frame 1 to frame 2"
            extends Modelica.Icons.Function;
            input TransformationMatrices.Orientation T
            "Orientation object to rotate frame 1 into frame 2";
            input Real v1[3] "Vector in frame 1";
            output Real v2[3] "Vector in frame 2";
          algorithm
            v2 := T*v1;
          end resolve2;

          function absoluteRotation
          "Return absolute orientation object from another absolute and a relative orientation object"

            extends Modelica.Icons.Function;
            input TransformationMatrices.Orientation T1
            "Orientation object to rotate frame 0 into frame 1";
            input TransformationMatrices.Orientation T_rel
            "Orientation object to rotate frame 1 into frame 2";
            output TransformationMatrices.Orientation T2
            "Orientation object to rotate frame 0 into frame 2";
          algorithm
            T2 := T_rel*T1;
          end absoluteRotation;

          function planarRotation
          "Return orientation object of a planar rotation"
            import Modelica.Math;
            extends Modelica.Icons.Function;
            input Real e[3](each final unit="1")
            "Normalized axis of rotation (must have length=1)";
            input Modelica.SIunits.Angle angle
            "Rotation angle to rotate frame 1 into frame 2 along axis e";
            output TransformationMatrices.Orientation T
            "Orientation object to rotate frame 1 into frame 2";
          algorithm
            T := [e]*transpose([e]) + (identity(3) - [e]*transpose([e]))*Math.cos(
              angle) - skew(e)*Math.sin(angle);
          end planarRotation;

          function axisRotation
          "Return rotation object to rotate around one frame axis"
            import Modelica.Math.*;
            extends Modelica.Icons.Function;
            input Integer axis(min=1, max=3) "Rotate around 'axis' of frame 1";
            input Modelica.SIunits.Angle angle
            "Rotation angle to rotate frame 1 into frame 2 along 'axis' of frame 1";
            output TransformationMatrices.Orientation T
            "Orientation object to rotate frame 1 into frame 2";
          algorithm
            T := if axis == 1 then [1, 0, 0; 0, cos(angle), sin(angle); 0, -sin(angle),
               cos(angle)] else if axis == 2 then [cos(angle), 0, -sin(angle); 0, 1,
              0; sin(angle), 0, cos(angle)] else [cos(angle), sin(angle), 0; -sin(
              angle), cos(angle), 0; 0, 0, 1];
          end axisRotation;

          function from_nxy
          "Return orientation object from n_x and n_y vectors"
            extends Modelica.Icons.Function;
            input Real n_x[3](each final unit="1")
            "Vector in direction of x-axis of frame 2, resolved in frame 1";
            input Real n_y[3](each final unit="1")
            "Vector in direction of y-axis of frame 2, resolved in frame 1";
            output TransformationMatrices.Orientation T
            "Orientation object to rotate frame 1 into frame 2";
        protected
            Real abs_n_x=sqrt(n_x*n_x);
            Real e_x[3](each final unit="1")=if abs_n_x < 1.e-10 then {1,0,0} else n_x/abs_n_x;
            Real n_z_aux[3](each final unit="1")=cross(e_x, n_y);
            Real n_y_aux[3](each final unit="1")=if n_z_aux*n_z_aux > 1.0e-6 then n_y else (if abs(e_x[1])
                 > 1.0e-6 then {0,1,0} else {1,0,0});
            Real e_z_aux[3](each final unit="1")=cross(e_x, n_y_aux);
            Real e_z[3](each final unit="1")=e_z_aux/sqrt(e_z_aux*e_z_aux);
          algorithm
            T := {e_x,cross(e_z, e_x),e_z};
          end from_nxy;
        end TransformationMatrices;

        package Internal
        "Internal definitions that may be removed or changed (do not use)"
          extends Modelica.Icons.Library;

          type TransformationMatrix = Real[3, 3];

          type QuaternionBase = Real[4];

          function maxWithoutEvent
          "Maximum of the input arguments, without event and without warning message when differentiating"

            input Real u1;
            input Real u2;
            output Real y;
            //  annotation (Header="#include \"MultiBody.h\"");
        protected
            Integer dummy;
          algorithm
            y := if u1 > u2 then u1 else u2;
            dummy := 0;
          end maxWithoutEvent;

          function maxWithoutEvent_d
          "First derivative of function maxWithoutEvent(..)"
            input Real u1;
            input Real u2;
            input Real u1_d;
            input Real u2_d;
            output Real y_d;
            //annotation (Header="#include \"MultiBody.h\"");
        protected
            Integer dummy;
          algorithm
            y_d := if u1 > u2 then u1_d else u2_d;
            dummy := 0;
          end maxWithoutEvent_d;

          function maxWithoutEvent_dd
          "First derivative of function maxWithoutEvent_d(..)"
            input Real u1;
            input Real u2;
            input Real u1_d;
            input Real u2_d;
            input Real u1_dd;
            input Real u2_dd;
            output Real y_dd;
          algorithm
            y_dd := if u1 > u2 then u1_dd else u2_dd;
          end maxWithoutEvent_dd;

          function resolve1_der "Derivative of function Frames.resolve1(..)"
            import Modelica.Mechanics.MultiBody.Frames;
            extends Modelica.Icons.Function;
            input Orientation R
            "Orientation object to rotate frame 1 into frame 2";
            input Real v2[3] "Vector resolved in frame 2";
            input Real v2_der[3] "= der(v2)";
            output Real v1_der[3] "Derivative of vector v resolved in frame 1";
          algorithm
            v1_der := Frames.resolve1(R, v2_der + cross(R.w, v2));
          end resolve1_der;

          function resolve2_der "Derivative of function Frames.resolve2(..)"
            import Modelica.Mechanics.MultiBody.Frames;
            extends Modelica.Icons.Function;
            input Orientation R
            "Orientation object to rotate frame 1 into frame 2";
            input Real v1[3] "Vector resolved in frame 1";
            input Real v1_der[3] "= der(v1)";
            output Real v2_der[3] "Derivative of vector v resolved in frame 2";
          algorithm
            v2_der := Frames.resolve2(R, v1_der) - cross(R.w, Frames.resolve2(R, v1));
          end resolve2_der;

          function resolveRelative_der
          "Derivative of function Frames.resolveRelative(..)"
            import Modelica.Mechanics.MultiBody.Frames;
            extends Modelica.Icons.Function;
            input Real v1[3] "Vector in frame 1";
            input Orientation R1
            "Orientation object to rotate frame 0 into frame 1";
            input Orientation R2
            "Orientation object to rotate frame 0 into frame 2";
            input Real v1_der[3] "= der(v1)";
            output Real v2_der[3] "Derivative of vector v resolved in frame 2";
          algorithm
            v2_der := Frames.resolveRelative(v1_der+cross(R1.w,v1), R1, R2)
                      - cross(R2.w, Frames.resolveRelative(v1, R1, R2));

            /* skew(w) = T*der(T'), -skew(w) = der(T)*T'

     v2 = T2*(T1'*v1)
     der(v2) = der(T2)*T1'*v1 + T2*der(T1')*v1 + T2*T1'*der(v1)
             = der(T2)*T2'*T2*T1'*v1 + T2*T1'*T1*der(T1')*v1 + T2*T1'*der(v1)
             = -w2 x (T2*T1'*v1) + T2*T1'*(w1 x v1) + T2*T1'*der(v1)
             = T2*T1'*(der(v1) + w1 x v1) - w2 x (T2*T1'*v1)
  */
          end resolveRelative_der;
        end Internal;
      end Frames;

      package Interfaces
      "Connectors and partial models for 3-dim. mechanical components"
        extends Modelica.Icons.Library;

        connector Frame
        "Coordinate system fixed to the component with one cut-force and cut-torque (no icon)"
          import SI = Modelica.SIunits;
          SI.Position r_0[3]
          "Position vector from world frame to the connector frame origin, resolved in world frame";
          Frames.Orientation R
          "Orientation object to rotate the world frame into the connector frame";
          flow SI.Force f[3] "Cut-force resolved in connector frame";
          flow SI.Torque t[3] "Cut-torque resolved in connector frame";
        end Frame;

        connector Frame_a
        "Coordinate system fixed to the component with one cut-force and cut-torque (filled rectangular icon)"
          extends Frame;

        end Frame_a;

        connector Frame_b
        "Coordinate system fixed to the component with one cut-force and cut-torque (non-filled rectangular icon)"
          extends Frame;

        end Frame_b;

      connector Frame_resolve "Coordinate system fixed to the component used to express in which
coordinate system a vector is resolved (non-filled rectangular icon)"
        extends Frame;

      end Frame_resolve;

        partial model PartialTwoFrames
        "Base model for components providing two frame connectors + outer world + assert to guarantee that the component is connected"

          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the component with one cut-force and cut-torque";
      protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          assert(cardinality(frame_a) > 0,
            "Connector frame_a of component is not connected");
          assert(cardinality(frame_b) > 0,
            "Connector frame_b of component is not connected");

        end PartialTwoFrames;

        partial model PartialTwoFramesDoubleSize
        "Base model for components providing two frame connectors + outer world + assert to guarantee that the component is connected (default icon size is factor 2 larger as usual)"

          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the component with one cut-force and cut-torque";


      protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          assert(cardinality(frame_a) > 0,
            "Connector frame_a of component is not connected");
          assert(cardinality(frame_b) > 0,
            "Connector frame_b of component is not connected");
        end PartialTwoFramesDoubleSize;

        partial model PartialElementaryJoint
        "Base model for elementary joints (has two frames + outer world + assert to guarantee that the joint is connected)"

          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the joint with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the joint with one cut-force and cut-torque";

      protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          Connections.branch(frame_a.R, frame_b.R);
          assert(cardinality(frame_a) > 0,
            "Connector frame_a of joint object is not connected");
          assert(cardinality(frame_b) > 0,
            "Connector frame_b of joint object is not connected");
        end PartialElementaryJoint;

        partial model PartialVisualizer
        "Base model for visualizers (has a frame_a on the left side + outer world + assert to guarantee that the component is connected)"

          Interfaces.Frame_a frame_a
          "Coordinate system in which visualization data is resolved";
      protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          assert(cardinality(frame_a) > 0,
            "Connector frame_a of visualizer object is not connected");
        end PartialVisualizer;

        model ZeroPosition
        "Set absolute position vector of frame_resolve to a zero vector and the orientation object to a null rotation"
           extends Modelica.Blocks.Interfaces.BlockIcon;
          Interfaces.Frame_resolve frame_resolve;
        equation
          Connections.root(frame_resolve.R);
          frame_resolve.R = Modelica.Mechanics.MultiBody.Frames.nullRotation();
          frame_resolve.r_0 = zeros(3);
        end ZeroPosition;
      end Interfaces;

      package Joints "Components that constrain the motion between two frames"
        import SI = Modelica.SIunits;
        extends Modelica.Icons.Library;

        model Prismatic
        "Prismatic joint (1 translational degree-of-freedom, 2 potential states, optional axis flange)"

          import SI = Modelica.SIunits;
          extends
          Modelica.Mechanics.MultiBody.Interfaces.PartialElementaryJoint;
          Modelica.Mechanics.Translational.Interfaces.Flange_a axis if useAxisFlange
          "1-dim. translational flange that drives the joint";
          Modelica.Mechanics.Translational.Interfaces.Flange_b support if useAxisFlange
          "1-dim. translational flange of the drive drive support (assumed to be fixed in the world frame, NOT in the joint)";

          parameter Boolean useAxisFlange=false
          "= true, if axis flange is enabled";
          parameter Boolean animation=true
          "= true, if animation shall be enabled";
          parameter Modelica.Mechanics.MultiBody.Types.Axis n={1,0,0}
          "Axis of translation resolved in frame_a (= same as in frame_b)";
          constant SI.Position s_offset=0
          "Relative distance offset (distance between frame_a and frame_b = s_offset + s)";
          parameter Types.Axis boxWidthDirection={0,1,0}
          "Vector in width direction of box, resolved in frame_a";
          parameter SI.Distance boxWidth=world.defaultJointWidth
          "Width of prismatic joint box";
          parameter SI.Distance boxHeight=boxWidth
          "Height of prismatic joint box";
          input Types.Color boxColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
          "Color of prismatic joint box";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";
          parameter StateSelect stateSelect=StateSelect.prefer
          "Priority to use distance s and v=der(s) as states";
          final parameter Real e[3](each final unit="1")=Modelica.Math.Vectors.normalize(
                                                     n)
          "Unit vector in direction of prismatic axis n";

          SI.Position s(start=0, final stateSelect=stateSelect)
          "Relative distance between frame_a and frame_b";

          SI.Velocity v(start=0,final stateSelect=stateSelect)
          "First derivative of s (relative velocity)";
          SI.Acceleration a(start=0)
          "Second derivative of s (relative acceleration)";
          SI.Force f "Actuation force in direction of joint axis";


      protected
          Visualizers.Advanced.Shape box(
            shapeType="box",
            color=boxColor,
            specularCoefficient=specularCoefficient,
            length=if noEvent(abs(s + s_offset) > 1.e-6) then s + s_offset else 1.e-6,
            width=boxWidth,
            height=boxHeight,
            lengthDirection=e,
            widthDirection=boxWidthDirection,
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
          Translational.Components.Fixed fixed;
          Translational.Interfaces.InternalSupport internalAxis(f = f);
          Translational.Sources.ConstantForce constantForce(f_constant=0) if not useAxisFlange;
        equation
          v = der(s);
          a = der(v);

          // relationships between kinematic quantities of frame_a and of frame_b
          frame_b.r_0 = frame_a.r_0 + Frames.resolve1(frame_a.R, e*(s_offset + s));
          frame_b.R = frame_a.R;

          // Force and torque balance
          zeros(3) = frame_a.f + frame_b.f;
          zeros(3) = frame_a.t + frame_b.t + cross(e*(s_offset + s), frame_b.f);

          // d'Alemberts principle
          f = -e*frame_b.f;

          // Connection to internal connectors
          s = internalAxis.s;

          connect(fixed.flange, support);
          connect(internalAxis.flange, axis);
          connect(constantForce.flange, internalAxis.flange);
        end Prismatic;

        model Revolute
        "Revolute joint (1 rotational degree-of-freedom, 2 potential states, optional axis flange)"

          import SI = Modelica.SIunits;

          Modelica.Mechanics.Rotational.Interfaces.Flange_a axis if useAxisFlange
          "1-dim. rotational flange that drives the joint";
          Modelica.Mechanics.Rotational.Interfaces.Flange_b support if useAxisFlange
          "1-dim. rotational flange of the drive support (assumed to be fixed in the world frame, NOT in the joint)";

          Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a
          "Coordinate system fixed to the joint with one cut-force and cut-torque";
          Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b
          "Coordinate system fixed to the joint with one cut-force and cut-torque";

          parameter Boolean useAxisFlange=false
          "= true, if axis flange is enabled";
          parameter Boolean animation=true
          "= true, if animation shall be enabled (show axis as cylinder)";
          parameter Modelica.Mechanics.MultiBody.Types.Axis n={0,0,1}
          "Axis of rotation resolved in frame_a (= same as in frame_b)";
          constant SI.Angle phi_offset=0
          "Relative angle offset (angle = phi_offset + phi)";
          parameter SI.Distance cylinderLength=world.defaultJointLength
          "Length of cylinder representing the joint axis";
          parameter SI.Distance cylinderDiameter=world.defaultJointWidth
          "Diameter of cylinder representing the joint axis";
          input Modelica.Mechanics.MultiBody.Types.Color cylinderColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
          "Color of cylinder representing the joint axis";
          input Modelica.Mechanics.MultiBody.Types.SpecularCoefficient
          specularCoefficient =                                                              world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";
          parameter StateSelect stateSelect=StateSelect.prefer
          "Priority to use joint angle phi and w=der(phi) as states";

          SI.Angle phi(start=0, final stateSelect=stateSelect)
          "Relative rotation angle from frame_a to frame_b";
          SI.AngularVelocity w(start=0, stateSelect=stateSelect)
          "First derivative of angle phi (relative angular velocity)";
          SI.AngularAcceleration a(start=0)
          "Second derivative of angle phi (relative angular acceleration)";
          SI.Torque tau "Driving torque in direction of axis of rotation";
          SI.Angle angle "= phi_offset + phi";

      protected
          outer Modelica.Mechanics.MultiBody.World world;
          parameter Real e[3](each final unit="1")=Modelica.Math.Vectors.normalize(
                                               n)
          "Unit vector in direction of rotation axis, resolved in frame_a (= same as in frame_b)";
          Frames.Orientation R_rel
          "Relative orientation object from frame_a to frame_b or from frame_b to frame_a";
          Visualizers.Advanced.Shape cylinder(
            shapeType="cylinder",
            color=cylinderColor,
            specularCoefficient=specularCoefficient,
            length=cylinderLength,
            width=cylinderDiameter,
            height=cylinderDiameter,
            lengthDirection=e,
            widthDirection={0,1,0},
            r_shape=-e*(cylinderLength/2),
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;

      protected
          Modelica.Mechanics.Rotational.Components.Fixed fixed
          "support flange is fixed to ground";
          Rotational.Interfaces.InternalSupport internalAxis(tau=tau);
          Rotational.Sources.ConstantTorque constantTorque(tau_constant=0) if not useAxisFlange;
        equation
          Connections.branch(frame_a.R, frame_b.R);

          assert(cardinality(frame_a) > 0,
            "Connector frame_a of revolute joint is not connected");
          assert(cardinality(frame_b) > 0,
            "Connector frame_b of revolute joint is not connected");

          angle = phi_offset + phi;
          w = der(phi);
          a = der(w);

          // relationships between quantities of frame_a and of frame_b
          frame_b.r_0 = frame_a.r_0;

          if rooted(frame_a.R) then
            R_rel = Frames.planarRotation(e, phi_offset + phi, w);
            frame_b.R = Frames.absoluteRotation(frame_a.R, R_rel);
            frame_a.f = -Frames.resolve1(R_rel, frame_b.f);
            frame_a.t = -Frames.resolve1(R_rel, frame_b.t);
          else
            R_rel = Frames.planarRotation(-e, phi_offset + phi, w);
            frame_a.R = Frames.absoluteRotation(frame_b.R, R_rel);
            frame_b.f = -Frames.resolve1(R_rel, frame_a.f);
            frame_b.t = -Frames.resolve1(R_rel, frame_a.t);
          end if;

          // d'Alemberts principle
          tau = -frame_b.t*e;

          // Connection to internal connectors
          phi = internalAxis.phi;

          connect(fixed.flange, support);
          connect(internalAxis.flange, axis);
          connect(constantTorque.flange, internalAxis.flange);
        end Revolute;

        model RevolutePlanarLoopConstraint
        "Revolute joint that is described by 2 positional constraints for usage in a planar loop (the ambiguous cut-force perpendicular to the loop and the ambiguous cut-torques are set arbitrarily to zero)"

          import SI = Modelica.SIunits;
          import Cv = Modelica.SIunits.Conversions;
          import T = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
          import Modelica.Mechanics.MultiBody.Types;

          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the joint with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the joint with one cut-force and cut-torque";

          parameter Boolean animation=true
          "= true, if animation shall be enabled (show axis as cylinder)";
          parameter Modelica.Mechanics.MultiBody.Types.Axis n={0,0,1}
          "Axis of rotation resolved in frame_a (= same as in frame_b)";
          parameter SI.Distance cylinderLength=world.defaultJointLength
          "Length of cylinder representing the joint axis";
          parameter SI.Distance cylinderDiameter=world.defaultJointWidth
          "Diameter of cylinder representing the joint axis";
          input Types.Color cylinderColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
          "Color of cylinder representing the joint axis";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";
      protected
          outer Modelica.Mechanics.MultiBody.World world;
          parameter Real e[3](each final unit="1")=Modelica.Math.Vectors.normalize(
                                               n)
          "Unit vector in direction of rotation axis, resolved in frame_a (= same as in frame_b)";
          parameter Real nnx_a[3](each final unit="1")=if abs(e[1]) > 0.1 then {0,1,0} else (if abs(e[2])
               > 0.1 then {0,0,1} else {1,0,0})
          "Arbitrary vector that is not aligned with rotation axis n";
          parameter Real ey_a[3](each final unit="1")=Modelica.Math.Vectors.normalize(
                                                  cross(e, nnx_a))
          "Unit vector orthogonal to axis n of revolute joint, resolved in frame_a";
          parameter Real ex_a[3](each final unit="1")=cross(ey_a, e)
          "Unit vector orthogonal to axis n of revolute joint and to ey_a, resolved in frame_a";
          Real ey_b[3](each final unit="1") "ey_a, resolved in frame_b";
          Real ex_b[3](each final unit="1") "ex_a, resolved in frame_b";
          Frames.Orientation R_rel
          "Dummy or relative orientation object from frame_a to frame_b";
          Modelica.SIunits.Position r_rel_a[3]
          "Position vector from origin of frame_a to origin of frame_b, resolved in frame_a";
          SI.Force f_c[2]
          "Dummy or constraint forces in direction of ex_a, ey_a";

          Visualizers.Advanced.Shape cylinder(
            shapeType="cylinder",
            color=cylinderColor,
            specularCoefficient=specularCoefficient,
            length=cylinderLength,
            width=cylinderDiameter,
            height=cylinderDiameter,
            lengthDirection=e,
            widthDirection={0,1,0},
            r_shape=-e*(cylinderLength/2),
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
        equation
          assert(cardinality(frame_a) > 0,
            "Connector frame_a of revolute joint is not connected");
          assert(cardinality(frame_b) > 0,
            "Connector frame_b of revolute joint is not connected");

          // Determine relative position vector resolved in frame_a
          R_rel = Frames.relativeRotation(frame_a.R, frame_b.R);
          r_rel_a = Frames.resolve2(frame_a.R, frame_b.r_0 - frame_a.r_0);
          // r_rel_a = T.resolve1(R_rel.T, T.resolve2(frame_b.R.T, frame_b.r_0 - frame_a.r_0));

          // Constraint equations
          0 = ex_a*r_rel_a;
          0 = ey_a*r_rel_a;

          /* Transform forces and torques
     (the torques are assumed to be zero by the assumption
      of a planar joint)
  */
          frame_a.t = zeros(3);
          frame_b.t = zeros(3);

          frame_a.f = [ex_a, ey_a]*f_c;
          frame_b.f = -Frames.resolve2(R_rel, frame_a.f);

          // check that revolute joint is used in planar loop
          ex_b = Frames.resolve2(R_rel, ex_a);
          ey_b = Frames.resolve2(R_rel, ey_a);
          assert(noEvent(abs(e*r_rel_a) <= 1.e-10 and abs(e*ex_b) <= 1.e-10 and 
              abs(e*ey_b) <= 1.e-10), "
The MultiBody.Joints.RevolutePlanarLoopConstraint joint is used as cut-joint of a
planar loop. However, the revolute joint is not part of a planar loop where the
axis of the revolute joint (parameter n) is orthogonal to the possible movements.
Either use instead joint MultiBody.Joints.Revolute or correct the
definition of the axes vectors n in the revolute joints of the planar loop.
");
        end RevolutePlanarLoopConstraint;

        model SphericalSpherical
        "Spherical - spherical joint aggregation (1 constraint, no potential states) with an optional point mass in the middle"

          import SI = Modelica.SIunits;
          import Modelica.Mechanics.MultiBody.Types;
          extends Interfaces.PartialTwoFrames;

          parameter Boolean animation=true
          "= true, if animation shall be enabled";
          parameter Boolean showMass=true
          "= true, if mass shall be shown (provided animation = true and m > 0)";
          parameter Boolean computeRodLength=false
          "= true, if rodLength shall be computed during initialization (see info)";
          parameter SI.Length rodLength(
            min=Modelica.Constants.eps,
            fixed=not computeRodLength, start = 1)
          "Distance between the origins of frame_a and frame_b (if computeRodLength=true, guess value)";
          parameter SI.Mass m(min=0)=0
          "Mass of rod (= point mass located in middle of rod)";
          parameter SI.Diameter sphereDiameter=world.defaultJointLength
          "Diameter of spheres respresenting the spherical joints";
          input Types.Color sphereColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
          "Color of spheres respresenting the spherical joints";
          parameter SI.Diameter rodDiameter=sphereDiameter/Types.Defaults.JointRodDiameterFraction
          "Diameter of rod connecting the two spherical joint";
          input Types.Color rodColor=Modelica.Mechanics.MultiBody.Types.Defaults.RodColor
          "Color of rod connecting the two spherical joints";
          parameter SI.Diameter massDiameter=sphereDiameter
          "Diameter of sphere representing the mass point";
          input Types.Color massColor=Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor
          "Color of sphere representing the mass point";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";

          parameter Boolean kinematicConstraint=true
          "= false, if no constraint shall be defined, due to analytically solving a kinematic loop (\"false\" should not be used by user, but only by MultiBody.Joints.Assemblies joints)";
          Real constraintResidue = rRod_0*rRod_0 - rodLength*rodLength
          "Constraint equation of joint in residue form: Either length constraint (= default) or equation to compute rod force (for analytic solution of loops in combination with Internal.RevoluteWithLengthConstraint/PrismaticWithLengthConstraint)";
          parameter Boolean checkTotalPower=false
          "= true, if total power flowing into this component shall be determined (must be zero)";

          SI.Force f_rod
          "Constraint force in direction of the rod (positive on frame_a, when directed from frame_a to frame_b)";
          SI.Position rRod_0[3]
          "Position vector from frame_a to frame_b resolved in world frame";
          SI.Position rRod_a[3]
          "Position vector from frame_a to frame_b resolved in frame_a";
          Real eRod_a[3](each final unit="1")
          "Unit vector in direction from frame_a to frame_b, resolved in frame_a";
          SI.Position r_CM_0[3]
          "Dummy if m==0, or position vector from world frame to mid-point of rod, resolved in world frame";
          SI.Velocity v_CM_0[3] "First derivative of r_CM_0";
          SI.Force f_CM_a[3]
          "Dummy if m==0, or inertial force acting at mid-point of rod due to mass oint acceleration, resolved in frame_a";
          SI.Force f_CM_e[3]
          "Dummy if m==0, or projection of f_CM_a onto eRod_a, resolved in frame_a";
          SI.Force f_b_a1[3]
          "Force acting at frame_b, but without force in rod, resolved in frame_a";
          SI.Power totalPower
          "Total power flowing into this element, if checkTotalPower=true (otherwise dummy)";


      protected
          Visualizers.Advanced.Shape shape_rod(
            shapeType="cylinder",
            color=rodColor,
            specularCoefficient=specularCoefficient,
            length=rodLength,
            width=rodDiameter,
            height=rodDiameter,
            lengthDirection=eRod_a,
            widthDirection={0,1,0},
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape shape_a(
            shapeType="sphere",
            color=sphereColor,
            specularCoefficient=specularCoefficient,
            length=sphereDiameter,
            width=sphereDiameter,
            height=sphereDiameter,
            lengthDirection=eRod_a,
            widthDirection={0,1,0},
            r_shape=-eRod_a*(sphereDiameter/2),
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape shape_b(
            shapeType="sphere",
            color=sphereColor,
            specularCoefficient=specularCoefficient,
            length=sphereDiameter,
            width=sphereDiameter,
            height=sphereDiameter,
            lengthDirection=eRod_a,
            widthDirection={0,1,0},
            r_shape=eRod_a*(rodLength - sphereDiameter/2),
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape shape_mass(
            shapeType="sphere",
            color=massColor,
            specularCoefficient=specularCoefficient,
            length=massDiameter,
            width=massDiameter,
            height=massDiameter,
            lengthDirection=eRod_a,
            widthDirection={0,1,0},
            r_shape=eRod_a*(rodLength/2 - sphereDiameter/2),
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation and showMass and m > 0;
        equation
          // Determine relative position vector between the two frames
          if kinematicConstraint then
            rRod_0 = transpose(frame_b.R.T)*(frame_b.R.T*frame_b.r_0) - transpose(
              frame_a.R.T)*(frame_a.R.T*frame_a.r_0);
          else
            rRod_0 = frame_b.r_0 - frame_a.r_0;
          end if;

          //rRod_0 = frame_b.r_0 - frame_a.r_0;
          rRod_a = Frames.resolve2(frame_a.R, rRod_0);
          eRod_a = rRod_a/rodLength;

          // Constraint equation
          constraintResidue = 0;

          // Cut-torques at frame_a and frame_b
          frame_a.t = zeros(3);
          frame_b.t = zeros(3);

          /* Force and torque balance of rod
     - Kinematics for center of mass CM of mass point
       r_CM_0 = frame_a.r_0 + rRod_0/2;
       v_CM_0 = der(r_CM_0);
       a_CM_a = resolve2(frame_a.R, der(v_CM_0) - world.gravityAcceleration(r_CM_0));
     - Inertial and gravity force in direction (f_CM_e) and orthogonal (f_CM_n) to rod
       f_CM_a = m*a_CM_a
       f_CM_e = f_CM_a*eRod_a;           // in direction of rod
       f_CM_n = rodLength(f_CM_a - f_CM_e);  // orthogonal to rod
     - Force balance in direction of rod
       f_CM_e = fa_rod_e + fb_rod_e;
     - Force balance orthogonal to rod
       f_CM_n = fa_rod_n + fb_rod_n;
     - Torque balance with respect to frame_a
       0 = (-f_CM_n)*rodLength/2 + fb_rod_n*rodLength
     The result is:
     fb_rod_n = f_CM_n/2;
     fa_rod_n = fb_rod_n;
     fb_rod_e = f_CM_e - fa_rod_e;
     fa_rod_e is the unknown computed from loop
  */

            // f_b_a1 is needed in aggregation joints to solve kinematic loops analytically
          if m > 0 then
            r_CM_0 = frame_a.r_0 + rRod_0/2;
            v_CM_0 = der(r_CM_0);
            f_CM_a = m*Frames.resolve2(frame_a.R, der(v_CM_0) -
              world.gravityAcceleration(r_CM_0));
            f_CM_e = (f_CM_a*eRod_a)*eRod_a;
            frame_a.f = (f_CM_a - f_CM_e)/2 + f_rod*eRod_a;
            f_b_a1 = (f_CM_a + f_CM_e)/2;
            frame_b.f = Frames.resolveRelative(f_b_a1 - f_rod*eRod_a, frame_a.R,
              frame_b.R);
          else
            r_CM_0 = zeros(3);
            v_CM_0 = zeros(3);
            f_CM_a = zeros(3);
            f_CM_e = zeros(3);
            f_b_a1 = zeros(3);
            frame_a.f = f_rod*eRod_a;
            frame_b.f = -Frames.resolveRelative(frame_a.f, frame_a.R, frame_b.R);
          end if;

          if checkTotalPower then
            totalPower = frame_a.f*Frames.resolve2(frame_a.R, der(frame_a.r_0)) +
              frame_b.f*Frames.resolve2(frame_b.R, der(frame_b.r_0)) + (-m)*(der(
              v_CM_0) - world.gravityAcceleration(r_CM_0))*v_CM_0 + frame_a.t*
              Frames.angularVelocity2(frame_a.R) + frame_b.t*Frames.angularVelocity2(
              frame_b.R);
          else
            totalPower = 0;
          end if;
        end SphericalSpherical;

        model UniversalSpherical
        "Universal - spherical joint aggregation (1 constraint, no potential states)"

          import SI = Modelica.SIunits;
          import Modelica.Mechanics.MultiBody.Types;

          extends Interfaces.PartialTwoFrames;
          Interfaces.Frame_a frame_ia
          "Coordinate system at the origin of frame_a, fixed at the rod connecting the universal with the spherical joint";
          parameter Boolean animation=true
          "= true, if animation shall be enabled";
          parameter Boolean showUniversalAxes=true
          " = true, if universal joint shall be visualized with two cylinders, otherwise with a sphere (provided animation=true)";
          parameter Boolean computeRodLength=false
          "= true, if distance between frame_a and frame_b shall be computed during initialization (see info)";
          parameter Modelica.Mechanics.MultiBody.Types.Axis n1_a={0,0,1}
          "Axis 1 of universal joint resolved in frame_a (axis 2 is orthogonal to axis 1 and to rod)";
          parameter SI.Position rRod_ia[3]={1,0,0}
          "Vector from origin of frame_a to origin of frame_b, resolved in frame_ia (if computeRodLength=true, rRod_ia is only an axis vector along the connecting rod)";
          parameter SI.Diameter sphereDiameter=world.defaultJointLength
          "Diameter of spheres representing the universal and the spherical joint";
          input Types.Color sphereColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
          "Color of spheres representing the universal and the spherical joint";
          parameter Types.ShapeType rodShapeType="cylinder"
          "Shape type of rod connecting the universal and the spherical joint";
          parameter SI.Distance rodWidth=sphereDiameter/Types.Defaults.JointRodDiameterFraction
          "Width of rod shape in direction of axis 2 of universal joint.";
          parameter SI.Distance rodHeight=rodWidth
          "Height of rod shape in direction that is orthogonal to rod and to axis 2";
          parameter Types.ShapeExtra rodExtra=0.0
          "Additional parameter depending on rodShapeType";
          input Types.Color rodColor=Modelica.Mechanics.MultiBody.Types.Defaults.RodColor
          "Color of rod shape connecting the universal and the spherical joints";
          parameter SI.Distance cylinderLength=world.defaultJointLength
          "Length of cylinders representing the two universal joint axes";
          parameter SI.Distance cylinderDiameter=world.defaultJointWidth
          "Diameter of cylinders representing the two universal joint axes";
          input Types.Color cylinderColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
          "Color of cylinders representing the two universal joint axes";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";

          parameter Boolean kinematicConstraint=true
          "= false, if no constraint shall be defined, due to analytically solving a kinematic loop";
          Real constraintResidue = rRod_0*rRod_0 - rodLength*rodLength
          "Constraint equation of joint in residue form: Either length constraint (= default) or equation to compute rod force (for analytic solution of loops in combination with Internal.RevoluteWithLengthConstraint/PrismaticWithLengthConstraint)";
          parameter Boolean checkTotalPower=false
          "= true, if total power flowing into this component shall be determined (must be zero)";
          SI.Force f_rod
          "Constraint force in direction of the rod (positive, if rod is pressed)";
          final parameter SI.Distance rodLength(fixed=not computeRodLength)=
            Modelica.Math.Vectors.length(
                          rRod_ia)
          "Length of rod (distance between origin of frame_a and origin of frame_b)";
          final parameter Real eRod_ia[3](each final unit="1")=Modelica.Math.Vectors.normalize(
                                                           rRod_ia)
          "Unit vector from origin of frame_a to origin of frame_b, resolved in frame_ia";
          final parameter Real e2_ia[3](each final unit="1")=Modelica.Math.Vectors.normalize(
                                                         cross(n1_a, eRod_ia))
          "Unit vector in direction of axis 2 of universal joint, resolved in frame_ia (orthogonal to n1_a and eRod_ia; note: frame_ia is parallel to frame_a when the universal joint angles are zero)";
          final parameter Real e3_ia[3](each final unit="1")=cross(eRod_ia, e2_ia)
          "Unit vector perpendicular to eRod_ia and e2_ia, resolved in frame_ia";
          SI.Power totalPower
          "Total power flowing into this element, if checkTotalPower=true (otherwise dummy)";
          SI.Force f_b_a1[3]
          "frame_b.f without f_rod part, resolved in frame_a (needed for analytic loop handling)";
          Real eRod_a[3](each final unit="1")
          "Unit vector in direction of rRod_a, resolved in frame_a (needed for analytic loop handling)";
          SI.Position rRod_0[3](start=rRod_ia)
          "Position vector from origin of frame_a to origin of frame_b resolved in world frame";
          SI.Position rRod_a[3](start=rRod_ia)
          "Position vector from origin of frame_a to origin of frame_b resolved in frame_a";

      protected
          SI.Force f_b_a[3] "frame_b.f resolved in frame_a";
          SI.Force f_ia_a[3] "frame_ia.f resolved in frame_a";
          SI.Torque t_ia_a[3] "frame_ia.t resolved in frame_a";
          Real n2_a[3](each final unit="1")
          "Vector in direction of axis 2 of the universal joint (e2_ia), resolved in frame_a";
          Real length2_n2_a(start=1, unit="m2")
          "Square of length of vector n2_a";
          SI.Length length_n2_a "Length of vector n2_a";
          Real e2_a[3](each final unit="1")
          "Unit vector in direction of axis 2 of the universal joint (e2_ia), resolved in frame_a";
          Real e3_a[3](each final unit="1")
          "Unit vector perpendicular to eRod_ia and e2_a, resolved in frame_a";
          Real der_rRod_a_L[3](each unit="1/s") "= der(rRod_a)/rodLength";
          SI.AngularVelocity w_rel_ia1[3];
          Frames.Orientation R_rel_ia1;
          Frames.Orientation R_rel_ia2;
          // Real T_rel_ia[3, 3];
          Frames.Orientation R_rel_ia "Rotation from frame_a to frame_ia";

          Visualizers.Advanced.Shape rodShape(
            shapeType=rodShapeType,
            color=rodColor,
            specularCoefficient=specularCoefficient,
            length=rodLength,
            width=rodWidth,
            height=rodHeight,
            lengthDirection=eRod_ia,
            widthDirection=e2_ia,
            r=frame_ia.r_0,
            R=frame_ia.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape sphericalShape_b(
            shapeType="sphere",
            color=sphereColor,
            specularCoefficient=specularCoefficient,
            length=sphereDiameter,
            width=sphereDiameter,
            height=sphereDiameter,
            lengthDirection={1,0,0},
            widthDirection={0,1,0},
            r_shape={-0.5,0,0}*sphereDiameter,
            r=frame_b.r_0,
            R=frame_b.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape sphericalShape_a(
            shapeType="sphere",
            color=sphereColor,
            specularCoefficient=specularCoefficient,
            length=sphereDiameter,
            width=sphereDiameter,
            height=sphereDiameter,
            lengthDirection={1,0,0},
            widthDirection={0,1,0},
            r_shape={-0.5,0,0}*sphereDiameter,
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation and not showUniversalAxes;
          Visualizers.Advanced.Shape universalShape1(
            shapeType="cylinder",
            color=cylinderColor,
            specularCoefficient=specularCoefficient,
            length=cylinderLength,
            width=cylinderDiameter,
            height=cylinderDiameter,
            lengthDirection=n1_a,
            widthDirection={0,1,0},
            r_shape=-n1_a*(cylinderLength/2),
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation and showUniversalAxes;
          Visualizers.Advanced.Shape universalShape2(
            shapeType="cylinder",
            color=cylinderColor,
            specularCoefficient=specularCoefficient,
            length=cylinderLength,
            width=cylinderDiameter,
            height=cylinderDiameter,
            lengthDirection=e2_ia,
            widthDirection={0,1,0},
            r_shape=-e2_ia*(cylinderLength/2),
            r=frame_ia.r_0,
            R=frame_ia.R) if world.enableAnimation and animation and showUniversalAxes;

        equation
          Connections.branch(frame_a.R, frame_ia.R);
          if kinematicConstraint then
            rRod_0 = transpose(frame_b.R.T)*(frame_b.R.T*frame_b.r_0) - transpose(
              frame_a.R.T)*(frame_a.R.T*frame_a.r_0);
          else
            rRod_0 = frame_b.r_0 - frame_a.r_0;
          end if;
          //rRod_0 = frame_b.r_0 - frame_a.r_0;
          rRod_a = Frames.resolve2(frame_a.R, rRod_0);

          // Constraint equation
          constraintResidue = 0;

          /* Determine relative Rotation R_rel_ia from frame_a to frame_ia
     and absolute rotation of frame_a.R.
  */
          eRod_a = rRod_a/rodLength;
          n2_a = cross(n1_a, eRod_a);
          length2_n2_a = n2_a*n2_a;

          assert(length2_n2_a > 1.e-10, "
A Modelica.Mechanics.MultiBody.Joints.UniversalSpherical joint (consisting of
a universal joint and a spherical joint connected together
by a rigid rod) is in the singular configuration of the
universal joint. This means that axis 1 of the universal
joint defined via parameter \"n1_a\" is parallel to vector
\"rRod_ia\" that is directed from the origin of frame_a to the
origin of frame_b.
   You may try to use another \"n1_a\" vector. If this fails,
use instead Modelica.Mechanics.MultiBody.Joints.SphericalSpherical, if this is
possible, because this joint aggregation does not have a
singular configuration.
");

          length_n2_a = sqrt(length2_n2_a);
          e2_a = n2_a/length_n2_a;
          e3_a = cross(eRod_a, e2_a);

          /* The statements below are an efficient implementation of the
   original equations:
     T_rel_ia = [eRod_ia, e2_ia, e3_ia]*transpose([eRod_a, e2_a, e3_a]);
     R_rel_ia = Frames.from_T(T_rel_ia,
                   Frames.TransformationMatrices.angularVelocity2(T_rel_ia, der(T_rel_ia)));
   To perform this, the rotation is split into two parts:
     R_rel_ia : Rotation object from frame_a to frame_ia
     R_rel_ia1: Rotation object from frame_a to frame_ia1
                (frame that is fixed in frame_ia such that x-axis
                is along the rod axis)
                T = transpose([eRod_a, e2_a, e3_a]; w = w_rel_ia1
     R_rel_ia2: Fixed rotation object from frame_ia1 to frame_ia
                T = [eRod_ia, e2_ia, e3_ia]; w = zeros(3)

   The difficult part is to compute w_rel_ia1:
      w_rel_ia1 = [  e3_a*der(e2_a);
                    -e3_a*der(eRod_a);
                     e2_a*der(eRod_a)]
   der(eRod_a) is directly given, since eRod_a is a function
   of translational quantities only.
      der(eRod_a) = (der(rRod_a) - eRod_a*(eRod_a*der(rRod_a)))/rodLength
      der(n2_a)   = cross(n1_a, der(eRod_a))
      der(e2_a)   = (der(n2_a) - e2_a*(e2_a*der(n2_a)))/length_n2_a
   Inserting these equations in w_rel_ia1 results in:
      e3_a*der(eRod_a) = e3_a*der(rRod_a)/rodLength       // e3_a*eRod_a = 0
      e2_a*der(eRod_a) = e2_a*der(rRod_a)/rodLength       // e2_a*eRod_a = 0
      e3_a*der(e2_a)   = e3_a*der(n2_a)/lenght_n2_a       // e3_a*e2_a = 0
                       = e3_a*cross(n1_a, der(eRod_a))/length_n2_a
                       = e3_a*cross(n1_a, der(rRod_a) - eRod_a*(eRod_a*der(rRod_a)))/(length_n2_a*rodLength)
                       = e3_a*cross(n1_a, der(rRod_a))/(length_n2_a*rodLength)
   Furthermore, we have:
     rRod_a            = resolve2(frame_a.R, rRod_0);
     der(rRod_a)       = resolve2(frame_a.R, der(rRod_0)) - cross(frame_a.R.w, rRod_a));
*/
          der_rRod_a_L = (Frames.resolve2(frame_a.R, der(rRod_0)) - cross(frame_a.R.w,
             rRod_a))/rodLength;
          w_rel_ia1 = {e3_a*cross(n1_a, der_rRod_a_L)/length_n2_a,-e3_a*der_rRod_a_L,
            e2_a*der_rRod_a_L};
          R_rel_ia1 = Frames.from_T(transpose([eRod_a, e2_a, e3_a]), w_rel_ia1);
          R_rel_ia2 = Frames.from_T([eRod_ia, e2_ia, e3_ia], zeros(3));
          R_rel_ia = Frames.absoluteRotation(R_rel_ia1, R_rel_ia2);
          /*
  T_rel_ia = [eRod_ia, e2_ia, e3_ia]*transpose([eRod_a, e2_a, e3_a]);
  R_rel_ia = Frames.from_T(T_rel_ia,
    Frames.TransformationMatrices.angularVelocity2(T_rel_ia, der(T_rel_ia)));
*/

          // Compute kinematic quantities of frame_ia
          frame_ia.r_0 = frame_a.r_0;
          frame_ia.R = Frames.absoluteRotation(frame_a.R, R_rel_ia);

          /* In the following formulas f_a, f_b, f_ia, t_a, t_b, t_ia are
     the forces and torques at frame_a, frame_b, frame_ia, respectively,
     resolved in frame_a. e_x, e_y, e_z are the unit vectors resolved in frame_a.
     Torque balance at the rod around the origin of frame_a:
       0 = t_a + t_ia + cross(rRod_a, f_b)
     with
         rRod_a = rodLength*e_x
         f_b     = -f_rod*e_x + f_b[2]*e_y + f_b[3]*e_z
     follows:
       0 = t_a + t_ia + rodLength*(f_b[2]*e_z - f_b[3]*e_y)
     The projection of t_a with respect to universal joint axes vanishes:
       n1_a*t_a = 0
       e_y*t_a = 0
     Therefore:
        0 = n1_a*t_ia + rodLength*f_b[2]*(n1_a*e_z)
        0 = e_y*t_ia - rodLength*f_b[3]
     or
        f_b = -f_rod*e_x - e_y*(n1_a*t_ia)/(rodLength*(n1_a*e_z)) + e_z*(e_y*t_ia)/rodLength
     Force balance:
        0 = f_a + f_b + f_ia
  */
          f_ia_a = Frames.resolve1(R_rel_ia, frame_ia.f);
          t_ia_a = Frames.resolve1(R_rel_ia, frame_ia.t);

            // f_b_a1 is needed in aggregation joints to solve kinematic loops analytically
          f_b_a1 = -e2_a*((n1_a*t_ia_a)/(rodLength*(n1_a*e3_a))) + e3_a*((e2_a*t_ia_a)
            /rodLength);
          f_b_a = -f_rod*eRod_a + f_b_a1;
          frame_b.f = Frames.resolveRelative(f_b_a, frame_a.R, frame_b.R);
          frame_b.t = zeros(3);
          zeros(3) = frame_a.f + f_b_a + f_ia_a;
          zeros(3) = frame_a.t + t_ia_a + cross(rRod_a, f_b_a);

          // Measure power for test purposes
          if checkTotalPower then
            totalPower = frame_a.f*Frames.resolve2(frame_a.R, der(frame_a.r_0)) +
              frame_b.f*Frames.resolve2(frame_b.R, der(frame_b.r_0)) + frame_ia.f*
              Frames.resolve2(frame_ia.R, der(frame_ia.r_0)) + frame_a.t*
              Frames.angularVelocity2(frame_a.R) + frame_b.t*Frames.angularVelocity2(
              frame_b.R) + frame_ia.t*Frames.angularVelocity2(frame_ia.R);
          else
            totalPower = 0;
          end if;
        end UniversalSpherical;

        package Assemblies "Joint aggregations for analytic loop handling"
          import SI = Modelica.SIunits;
          extends Modelica.Icons.Library;

          model JointUSR
          "Universal - spherical - revolute joint aggregation (no constraints, no potential states)"

            import SI = Modelica.SIunits;
            import Cv = Modelica.SIunits.Conversions;
            import Modelica.Mechanics.MultiBody.Types;

            extends Interfaces.PartialTwoFramesDoubleSize;
            Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_ia
            "Coordinate system at origin of frame_a fixed at connecting rod of universal and spherical joint";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_ib
            "Coordinate system at origin of frame_b fixed at connecting rod of spherical and revolute joint";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_im
            "Coordinate system at origin of spherical joint fixed at connecting rod of spherical and revolute joint";
            Modelica.Mechanics.Rotational.Interfaces.Flange_a axis
            "1-dim. rotational flange that drives the revolute joint";
            Modelica.Mechanics.Rotational.Interfaces.Flange_b bearing
            "1-dim. rotational flange of the drive bearing of the revolute joint";

            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            parameter Boolean showUniversalAxes=true
            " = true, if universal joint shall be visualized with two cylinders, otherwise with a sphere (provided animation=true)";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n1_a={0,0,1}
            "Axis 1 of universal joint fixed and resolved in frame_a (axis 2 is orthogonal to axis 1 and to rod 1)";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n_b={0,0,1}
            "Axis of revolute joint fixed and resolved in frame_b";
            parameter SI.Position rRod1_ia[3]={1,0,0}
            "Vector from origin of frame_a to spherical joint, resolved in frame_ia";
            parameter SI.Position rRod2_ib[3]={-1,0,0}
            "Vector from origin of frame_ib to spherical joint, resolved in frame_ib";
            parameter Cv.NonSIunits.Angle_deg phi_offset=0
            "Relative angle offset of revolute joint (angle = phi(t) + from_deg(phi_offset))";
            parameter Cv.NonSIunits.Angle_deg phi_guess=0
            "Select the configuration such that at initial time |phi(t0) - from_deg(phi_guess)|is minimal";
            parameter SI.Diameter sphereDiameter=world.defaultJointLength
            "Diameter of the spheres representing the universal and the spherical joint";
            input Types.Color sphereColor=Modelica.Mechanics.MultiBody.Types.Defaults.
                 JointColor
            "Color of the spheres representing the universal and the spherical joint";
            parameter SI.Diameter rod1Diameter=sphereDiameter/Types.Defaults.
                JointRodDiameterFraction
            "Diameter of rod 1 connecting the universal and the spherical joint";
            input Types.Color rod1Color=Modelica.Mechanics.MultiBody.Types.Defaults.
                RodColor
            "Color of rod 1 connecting the universal and the spherical joint";

            parameter SI.Diameter rod2Diameter=rod1Diameter
            "Diameter of rod 2 connecting the revolute and the spherical joint";
            input Types.Color rod2Color=rod1Color
            "Color of rod 2 connecting the revolute and the spherical joint";
            parameter SI.Diameter revoluteDiameter=world.defaultJointWidth
            "Diameter of cylinder representing the revolute joint";
            parameter SI.Distance revoluteLength=world.defaultJointLength
            "Length of cylinder representing the revolute joint";
            input Types.Color revoluteColor=Modelica.Mechanics.MultiBody.Types.
                Defaults.JointColor
            "Color of cylinder representing the revolute joint";
            input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
            "Reflection of ambient light (= 0: light is completely absorbed)";
            parameter SI.Distance cylinderLength=world.defaultJointLength
            "Length of cylinders representing the two universal joint axes";
            parameter SI.Distance cylinderDiameter=world.defaultJointWidth
            "Diameter of cylinders representing the two universal joint axes";
            input Types.Color cylinderColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
            "Color of cylinders representing the two universal joint axes";
            parameter Boolean checkTotalPower=false
            "= true, if total power flowing into this component shall be determined (must be zero)";
            final parameter Real eRod1_ia[3](each final unit="1")=rod1.eRod_ia
            "Unit vector from origin of frame_a to origin of spherical joint, resolved in frame_ia";
            final parameter Real e2_ia[3](each final unit="1")=rod1.e2_ia
            "Unit vector in direction of axis 2 of universal joint, resolved in frame_ia";
            final parameter SI.Distance rod1Length=rod1.rodLength
            "Length of rod 1 (= distance between universal and spherical joint";
            SI.Power totalPower
            "Total power flowing into this element, if checkTotalPower=true (otherwise dummy)";
            SI.Position aux
            "Denominator used to compute force in rod connecting universal and spherical joint";
            SI.Force f_rod
            "Constraint force in direction of the rod (positive, if rod is pressed)";


            Modelica.Mechanics.MultiBody.Joints.Internal.RevoluteWithLengthConstraint
            revolute(
              animation=animation,
              lengthConstraint=rod1Length,
              n=n_b,
              phi_offset=phi_offset,
              phi_guess=phi_guess,
              cylinderDiameter=revoluteDiameter,
              cylinderLength=revoluteLength,
              cylinderColor=revoluteColor,
              specularCoefficient=specularCoefficient);
            Modelica.Mechanics.MultiBody.Joints.UniversalSpherical rod1(
              animation=animation,
              showUniversalAxes=showUniversalAxes,
              rRod_ia=rRod1_ia,
              n1_a=n1_a,
              sphereDiameter=sphereDiameter,
              sphereColor=sphereColor,
              rodWidth=rod1Diameter,
              rodHeight=rod1Diameter,
              rodColor=rod1Color,
              cylinderLength=cylinderLength,
              cylinderDiameter=cylinderDiameter,
              cylinderColor=cylinderColor,
              specularCoefficient=specularCoefficient,
              kinematicConstraint=false,
              constraintResidue=rod1.f_rod - f_rod);
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod2(
              animation=animation,
              width=rod2Diameter,
              height=rod2Diameter,
              color=rod2Color,
              specularCoefficient=specularCoefficient,
              r=rRod2_ib);
            Sensors.RelativePosition relativePosition(resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB.frame_a);
            Modelica.Blocks.Sources.Constant position_b[3](k=rRod2_ib);
          equation
           // Connections.root(frame_ib.R);

            /* Compute the unknown force in the rod of the rod1 joint
     by a torque balance at the revolute joint:
       0 = revolute.frame_b.t + frame_ib.t + frame_im.t + cross(rRod2_ib, frame_im.f)
           + cross(r_ib, -rod1.f_b_a1)
           + cross(r_ib, Frames.resolve2(rod1.R_rel, rod1.f_rod*rod1.eRod1_ia))
     The condition is that the projection of the torque in the revolute
     joint along the axis of the revolute joint is equal to the driving
     axis torque in the flange:
       -revolute.tau = revolute.e*frame_b.t
     Therefore, we have
        tau = e*(frame_ib.t  + frame_im.t + cross(rRod2_ib, frame_im.f)
              + cross(rRod2_ib, -rod1.f_b_a1))
              + e*cross(rRod2_ib, Frames.resolve2(rod1.R_rel, rod1.f_rod*rod1.eRod_a))
            = e*(frame_ib.t + frame_im.t + cross(rRod2_ib, frame_im.f)
              + cross(rRod2_ib, -rod.f_b_a1))
              + rod1.f_rod*e*cross(rRod2_ib, Frames.resolve2(rod1.R_rel, rod1.eRod_a))
     Solving this equation for f_rod results in
       f_rod = (-tau - e*(frame_ib.t + frame_im.t + cross(rRod2_ib, frame_im.f)
               + cross(rRod2_ib, -rod1.f_b_a1)))
               / (cross(e,rRod2_ib)*Frames.resolve2(rod1.R_rel, rod1.eRod_a)))
     Additionally, a guard against division by zero is introduced

     f_rod is passed to component JointsUSR.rod1 via variable "constraintResidue" in the Advanced menu
  */
            aux = cross(revolute.e, rRod2_ib)*Frames.resolveRelative(rod1.eRod_a,
              rod1.frame_a.R, rod1.frame_b.R);
            f_rod = (-revolute.tau - revolute.e*(frame_ib.t + frame_im.t + cross(
              rRod2_ib, frame_im.f) - cross(rRod2_ib, Frames.resolveRelative(rod1.
              f_b_a1, rod1.frame_a.R, rod1.frame_b.R))))/noEvent(if abs(aux) < 1.e-10 then 
                    1.e-10 else aux);

            // Measure power for test purposes
            if checkTotalPower then
              totalPower = frame_a.f*Frames.resolve2(frame_a.R, der(frame_a.r_0)) +
                frame_b.f*Frames.resolve2(frame_b.R, der(frame_b.r_0)) + frame_ia.f*
                Frames.resolve2(frame_ia.R, der(frame_ia.r_0)) + frame_ib.f*
                Frames.resolve2(frame_ib.R, der(frame_ib.r_0)) + frame_im.f*
                Frames.resolve2(frame_im.R, der(frame_im.r_0)) + frame_a.t*
                Frames.angularVelocity2(frame_a.R) + frame_b.t*
                Frames.angularVelocity2(frame_b.R) + frame_ia.t*
                Frames.angularVelocity2(frame_ia.R) + frame_ib.t*
                Frames.angularVelocity2(frame_ib.R) + frame_im.t*
                Frames.angularVelocity2(frame_im.R) + axis.tau*der(axis.phi) +
                bearing.tau*der(bearing.phi);
            else
              totalPower = 0;
            end if;

            connect(revolute.frame_b, rod2.frame_a);
            connect(rod2.frame_b, rod1.frame_b);
            connect(revolute.frame_a, frame_b);
            connect(rod2.frame_a, frame_ib);
            connect(rod1.frame_a, frame_a);
            connect(relativePosition.frame_b, frame_a);
            connect(relativePosition.frame_a, frame_b);
            connect(position_b.y, revolute.position_b);
            connect(rod2.frame_b, frame_im);
            connect(rod1.frame_ia, frame_ia);
            connect(revolute.axis, axis);
            connect(relativePosition.r_rel, revolute.position_a);
            connect(revolute.bearing, bearing);
          end JointUSR;

          model JointUSP
          "Universal - spherical - prismatic joint aggregation (no constraints, no potential states)"

            import SI = Modelica.SIunits;
            import Modelica.Mechanics.MultiBody.Types;

            extends Interfaces.PartialTwoFramesDoubleSize;
            Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_ia
            "Coordinate system at origin of frame_a fixed at connecting rod of universal and spherical joint";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_ib
            "Coordinate system at origin of frame_b fixed at connecting rod of spherical and prismatic joint";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_im
            "Coordinate system at origin of spherical joint fixed at connecting rod of spherical and prismatic joint";
            Modelica.Mechanics.Translational.Interfaces.Flange_a axis
            "1-dim. translational flange that drives the prismatic joint";
            Modelica.Mechanics.Translational.Interfaces.Flange_b bearing
            "1-dim. translational flange of the drive bearing of the prismatic joint";

            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            parameter Boolean showUniversalAxes=true
            " = true, if universal joint shall be visualized with two cylinders, otherwise with a sphere (provided animation=true)";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n1_a={0,0,1}
            "Axis 1 of universal joint fixed and resolved in frame_a (axis 2 is orthogonal to axis 1 and to rod 1)";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n_b={-1,0,0}
            "Axis of prismatic joint fixed and resolved in frame_b";
            parameter SI.Position rRod1_ia[3]={1,0,0}
            "Vector from origin of frame_a to spherical joint, resolved in frame_ia";
            parameter SI.Position rRod2_ib[3]={-1,0,0}
            "Vector from origin of frame_ib to spherical joint, resolved in frame_ib (frame_ib is parallel to frame_b)";
            parameter SI.Position s_offset=0
            "Relative distance offset of prismatic joint (distance between the prismatic joint frames = s(t) + s_offset)";
            parameter SI.Position s_guess=0
            "Select the configuration such that at initial time |s(t0)-s_guess|is minimal";
            parameter SI.Diameter sphereDiameter=world.defaultJointLength
            "Diameter of the spheres representing the universal and the spherical joint";
            input Types.Color sphereColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
            "Color of the spheres representing the universal and the spherical joint";
            parameter SI.Diameter rod1Diameter=sphereDiameter/Types.Defaults.
                JointRodDiameterFraction
            "Diameter of rod 1 connecting the universal and the spherical joint";
            input Types.Color rod1Color=Modelica.Mechanics.MultiBody.Types.Defaults.RodColor
            "Color of rod 1 connecting the universal and the spherical joint";
            parameter SI.Diameter rod2Diameter=rod1Diameter
            "Diameter of rod 2 connecting the prismatic and the spherical joint";
            input Types.Color rod2Color=rod1Color
            "Color of rod 2 connecting the prismatic and the spherical joint";
            parameter Types.Axis boxWidthDirection={0,1,0}
            "Vector in width direction of prismatic joint, resolved in frame_b";
            parameter SI.Distance boxWidth=world.defaultJointWidth
            "Width of prismatic joint box";
            parameter SI.Distance boxHeight=boxWidth
            "Height of prismatic joint box";
            input Types.Color boxColor=sphereColor
            "Color of prismatic joint box";
            input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
            "Reflection of ambient light (= 0: light is completely absorbed)";
            parameter SI.Distance cylinderLength=world.defaultJointLength
            "Length of cylinders representing the two universal joint axes";
            parameter SI.Distance cylinderDiameter=world.defaultJointWidth
            "Diameter of cylinders representing the two universal joint axes";
            input Types.Color cylinderColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
            "Color of cylinders representing the two universal joint axes";
            parameter Boolean checkTotalPower=false
            "= true, if total power flowing into this component shall be determined (must be zero)";
            final parameter Real eRod1_ia[3](each final unit="1")=rod1.eRod_ia
            "Unit vector from origin of frame_a to origin of spherical joint, resolved in frame_ia";
            final parameter Real e2_ia[3](each final unit="1")=rod1.e2_ia
            "Unit vector in direction of axis 2 of universal joint, resolved in frame_ia";
            final parameter SI.Distance rod1Length=rod1.rodLength
            "Length of rod 1 (= distance between universal and spherical joint";
            SI.Force f_rod
            "Constraint force in direction of the rod (positive, if rod is pressed)";
            SI.Power totalPower
            "Total power flowing into this element, if checkTotalPower=true (otherwise dummy)";

            Modelica.Mechanics.MultiBody.Joints.Internal.PrismaticWithLengthConstraint
            prismatic(
              animation=animation,
              length=rod1.rodLength,
              n=n_b,
              s_offset=s_offset,
              s_guess=s_guess,
              boxWidthDirection=boxWidthDirection,
              boxWidth=boxWidth,
              boxHeight=boxHeight,
              boxColor=boxColor,
              specularCoefficient=specularCoefficient);
            Modelica.Mechanics.MultiBody.Joints.UniversalSpherical rod1(
              animation=animation,
              showUniversalAxes=showUniversalAxes,
              rRod_ia=rRod1_ia,
              n1_a=n1_a,
              sphereDiameter=sphereDiameter,
              sphereColor=sphereColor,
              rodWidth=rod1Diameter,
              rodHeight=rod1Diameter,
              rodColor=rod1Color,
              specularCoefficient=specularCoefficient,
              cylinderLength=cylinderLength,
              cylinderDiameter=cylinderDiameter,
              cylinderColor=cylinderColor,
              kinematicConstraint=false,
              constraintResidue=rod1.f_rod - f_rod);
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod2(
              animation=animation,
              r=rRod2_ib,
              width=rod2Diameter,
              height=rod2Diameter,
              specularCoefficient=specularCoefficient,
              color=rod2Color);
            Sensors.RelativePosition relativePosition(resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB.frame_a);
            Modelica.Blocks.Sources.Constant position_b[3](k=rRod2_ib);
        protected
            Real aux
            "Denominator used to compute force in rod connecting universal and spherical joint";
          equation
            /* Compute the unknown force in rod1 connecting the universal and
     the spherical joint by a force balance at the prismatic joint
        0 = -prismatic.frame_b.f + frame_ib.f + frame_im.f - rod1.frame_b.f
     The force at rod1.frame_b is split into two parts:
        rod1.frame_b.f = Frames.resolve2(rod1.R_rel, rod1.f_b_a1 - rod1.f_rod*rod1.eRod_a)
     where rod1.f_rod is the unknown force in rod1.
     The condition is that the projection of the force in the prismatic
     joint along the axis of its translation axis is equal to the driving
     axis force in the flange:
       -prismatic.f = prismatic.e*prismatic.frame_b.f
     Therefore, we have with e=prismatic.e and f=prismatic.f
       -f = e*(frame_ib.f + frame_im.f
               - Frames.resolve2(rod1.R_rel, rod1.f_b_a1 - rod1.f_rod*rod1.eRod_a))
          = e*(frame_ib.f + frame_im.f - Frames.resolve2(rod1.R_rel, rod1.f_b_a1)
              + rod1.f_rod*Frames.resolve2(rod1.R_rel, rod1.eRod_a))
     Solving this equation for f_rod results in
       rod1.f_rod = -(f+e*(frame_ib.f + frame_im.f - Frames.resolve2(rod1.R_rel, rod1.f_b_a1))
                   /(e*Frames.resolve2(rod1.R_rel, rod1.eRod_a))
     Additionally, a guard against division by zero is introduced
  */
            aux = prismatic.e*Frames.resolveRelative(rod1.eRod_a, rod1.frame_a.R,
              rod1.frame_b.R);
            f_rod = (-prismatic.f - prismatic.e*(frame_ib.f + frame_im.f -
              Frames.resolveRelative(rod1.f_b_a1, rod1.frame_a.R, rod1.frame_b.R)))/
              noEvent(if abs(aux) < 1.e-10 then 1.e-10 else aux);
            // Measure power for test purposes
            if checkTotalPower then
              totalPower = frame_a.f*Frames.resolve2(frame_a.R, der(frame_a.r_0)) +
                frame_b.f*Frames.resolve2(frame_b.R, der(frame_b.r_0)) + frame_ia.f*
                Frames.resolve2(frame_ia.R, der(frame_ia.r_0)) + frame_ib.f*
                Frames.resolve2(frame_ib.R, der(frame_ib.r_0)) + frame_im.f*
                Frames.resolve2(frame_im.R, der(frame_im.r_0)) + frame_a.t*
                Frames.angularVelocity2(frame_a.R) + frame_b.t*
                Frames.angularVelocity2(frame_b.R) + frame_ia.t*
                Frames.angularVelocity2(frame_ia.R) + frame_ib.t*
                Frames.angularVelocity2(frame_ib.R) + frame_im.t*
                Frames.angularVelocity2(frame_im.R) + axis.f*der(axis.s) + bearing.f*
                der(bearing.s);
            else
              totalPower = 0;
            end if;

            connect(prismatic.frame_b, rod2.frame_a);
            connect(rod2.frame_b, rod1.frame_b);
            connect(prismatic.frame_a, frame_b);
            connect(rod2.frame_a, frame_ib);
            connect(rod1.frame_a, frame_a);
            connect(relativePosition.frame_b, frame_a);
            connect(relativePosition.frame_a, frame_b);
            connect(rod2.frame_b, frame_im);
            connect(rod1.frame_ia, frame_ia);
            connect(position_b.y, prismatic.position_b);
            connect(prismatic.axis, axis);
            connect(prismatic.bearing, bearing);
            connect(relativePosition.r_rel, prismatic.position_a);
          end JointUSP;

          model JointSSP
          "Spherical - spherical - prismatic joint aggregation with mass (no constraints, no potential states)"

            import SI = Modelica.SIunits;
            import Cv = Modelica.SIunits.Conversions;
            import Modelica.Mechanics.MultiBody.Types;

            extends Interfaces.PartialTwoFramesDoubleSize;
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_ib
            "Coordinate system at origin of frame_b fixed at connecting rod of spherical and prismatic joint";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_im
            "Coordinate system at origin of spherical joint in the middle fixed at connecting rod of spherical and prismatic joint";
            Modelica.Mechanics.Translational.Interfaces.Flange_a axis
            "1-dim. translational flange that drives the prismatic joint";
            Modelica.Mechanics.Translational.Interfaces.Flange_b bearing
            "1-dim. translational flange of the drive bearing of the prismatic joint";

            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            parameter Boolean showMass=true
            "= true, if point mass on rod 1 shall be shown (provided animation = true and rod1Mass > 0)";
            parameter SI.Length rod1Length(min=Modelica.Constants.eps, start = 1)
            "Distance between the origins of the two spherical joints ";
            parameter SI.Mass rod1Mass(min=0)=0
            "Mass of rod 1 (= point mass located in middle of rod connecting the two spherical joints)";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n_b={0,0,1}
            "Axis of prismatic joint fixed and resolved in frame_b";
            parameter SI.Position rRod2_ib[3]={1,0,0}
            "Vector from origin of frame_ib to spherical joint in the middle, resolved in frame_ib";
            parameter SI.Position s_offset=0
            "Relative distance offset of prismatic joint (distance between frame_b and frame_ib = s(t) + s_offset)";
            parameter SI.Position s_guess=0
            "Select the configuration such that at initial time |s(t0)-s_guess|is minimal";

            parameter SI.Diameter sphereDiameter=world.defaultJointLength
            "Diameter of the spheres representing the two spherical joints";
            input Types.Color sphereColor=Modelica.Mechanics.MultiBody.Types.Defaults.
                 JointColor
            "Color of the spheres representing the two spherical joints";
            parameter SI.Diameter rod1Diameter=sphereDiameter/Types.Defaults.
                JointRodDiameterFraction
            "Diameter of rod 1 connecting the two spherical joints";
            input Types.Color rod1Color=Modelica.Mechanics.MultiBody.Types.Defaults.
                RodColor "Color of rod 1 connecting the two spherical joint";

            parameter SI.Diameter rod2Diameter=rod1Diameter
            "Diameter of rod 2 connecting the revolute joint and spherical joint 2";
            input Types.Color rod2Color=rod1Color
            "Color of rod 2 connecting the revolute joint and spherical joint 2";

            parameter Types.Axis boxWidthDirection={0,1,0}
            "Vector in width direction of prismatic joint box, resolved in frame_b";
            parameter SI.Distance boxWidth=world.defaultJointWidth
            "Width of prismatic joint box";
            parameter SI.Distance boxHeight=boxWidth
            "Height of prismatic joint box";
            input Types.Color boxColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
            "Color of prismatic joint box";
            input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
            "Reflection of ambient light (= 0: light is completely absorbed)";
            parameter Boolean checkTotalPower=false
            "= true, if total power flowing into this component shall be determined (must be zero)";
            Real aux
            "Denominator used to compute force in rod connecting universal and spherical joint";
            SI.Force f_rod
            "Constraint force in direction of the rod (positive, if rod is pressed)";
            SI.Power totalPower
            "Total power flowing into this element, if checkTotalPower=true (otherwise dummy)";

            Modelica.Mechanics.MultiBody.Joints.Internal.PrismaticWithLengthConstraint
            prismatic(
              animation=animation,
              length=rod1Length,
              n=n_b,
              s_offset=s_offset,
              s_guess=s_guess,
              boxWidthDirection=boxWidthDirection,
              boxWidth=boxWidth,
              boxHeight=boxHeight,
              specularCoefficient=specularCoefficient,
              boxColor=boxColor);
            Modelica.Mechanics.MultiBody.Joints.SphericalSpherical rod1(
              animation=animation,
              showMass=showMass,
              m=rod1Mass,
              rodLength=rod1Length,
              rodDiameter=rod1Diameter,
              sphereDiameter=sphereDiameter,
              rodColor=rod1Color,
              kinematicConstraint=false,
              specularCoefficient=specularCoefficient,
              sphereColor=sphereColor,
              constraintResidue=rod1.f_rod - f_rod);
            Modelica.Mechanics.MultiBody.Parts.FixedTranslation rod2(
              animation=animation,
              width=rod2Diameter,
              height=rod2Diameter,
              specularCoefficient=specularCoefficient,
              color=rod2Color,
              r=rRod2_ib);
            Sensors.RelativePosition relativePosition(resolveInFrame=Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB.frame_a);
            Modelica.Blocks.Sources.Constant position_b[3](k=rRod2_ib);
          equation
            /* Compute the unknown force in the rod of the rod1 joint
     by a force balance:
       0 = frame_b.f + frame_ib.f + frame_im.f +
           Frames.resolve2(rod1.R_rel, rod1.f_rod*rod1.eRod_a)
     The condition is that the projection of the force in the prismatic
     joint along the axis of the prismatic joint is equal to the driving
     axis force in the flange:
       -prismatic.f = prismatic.e*frame_b.f
     Therefore, we have with e=prismatic.e and f=prismatic.f
        f = e*(frame_ib.f + frame_im.f +
               Frames.resolve2(rod1.R_rel, rod1.f_rod*rod1.eRod_a))
          = e*(frame_ib.f + frame_im.f +
               rod1.f_rod*Frames.resolve2(rod1.R_rel, rod1.eRod_a))
     Solving this equation for f_rod results in
       rod1.f_rod = (f - e*(frame_ib.f + frame_im.f))
                    / (e*Frames.resolve2(rod1.R_rel, rod1.eRod_a))
     Additionally, a guard against division by zero is introduced
  */
            aux = prismatic.e*Frames.resolveRelative(rod1.eRod_a, rod1.frame_a.R,
              rod1.frame_b.R);
            f_rod = (-prismatic.f - prismatic.e*(frame_ib.f + frame_im.f))/
              noEvent(if abs(aux) < 1.e-10 then 1.e-10 else aux);

            // Measure power for test purposes
            if checkTotalPower then
              totalPower = frame_a.f*Frames.resolve2(frame_a.R, der(frame_a.r_0)) +
                frame_b.f*Frames.resolve2(frame_b.R, der(frame_b.r_0)) + frame_ib.f*
                Frames.resolve2(frame_ib.R, der(frame_ib.r_0)) + frame_im.f*
                Frames.resolve2(frame_im.R, der(frame_im.r_0)) + frame_a.t*
                Frames.angularVelocity2(frame_a.R) + frame_b.t*
                Frames.angularVelocity2(frame_b.R) + frame_ib.t*
                Frames.angularVelocity2(frame_ib.R) + frame_im.t*
                Frames.angularVelocity2(frame_im.R) + axis.f*der(axis.s) + bearing.f*
                der(bearing.s) + (-rod1Mass)*(der(rod1.v_CM_0) -
                world.gravityAcceleration(rod1.r_CM_0))*rod1.v_CM_0;
            else
              totalPower = 0;
            end if;

            connect(prismatic.frame_b, rod2.frame_a);
            connect(rod2.frame_b, rod1.frame_b);
            connect(prismatic.frame_a, frame_b);
            connect(rod2.frame_a, frame_ib);
            connect(rod1.frame_a, frame_a);
            connect(relativePosition.frame_b, frame_a);
            connect(relativePosition.frame_a, frame_b);
            connect(position_b.y, prismatic.position_b);
            connect(prismatic.axis, axis);
            connect(prismatic.bearing, bearing);
            connect(rod2.frame_b, frame_im);
            connect(relativePosition.r_rel, prismatic.position_a);
          end JointSSP;

          model JointRRR
          "Planar revolute - revolute - revolute joint aggregation (no constraints, no potential states)"

            import SI = Modelica.SIunits;
            import Cv = Modelica.SIunits.Conversions;
            import Modelica.Mechanics.MultiBody.Types;

            extends Interfaces.PartialTwoFramesDoubleSize;

            Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_ia
            "Coordinate system at origin of frame_a fixed at connecting rod of left and middle revolute joint";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_ib
            "Coordinate system at origin of frame_b fixed at connecting rod of middle and right revolute joint";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_im
            "Coordinate system at origin of revolute joint in the middle fixed at connecting rod of middle and right revolute joint";
            Modelica.Mechanics.Rotational.Interfaces.Flange_a axis
            "1-dim. rotational flange that drives the right revolute joint at frame_b";
            Modelica.Mechanics.Rotational.Interfaces.Flange_b bearing
            "1-dim. rotational flange of the drive bearing of the right revolute joint at frame_b";

            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n_a={0,0,1}
            "Axes of revolute joints resolved in frame_a (all axes are parallel to each other)";
            final parameter Real n_b[3](each final unit="1", each fixed=false) = {0,0,1}
            "Axis of revolute joint fixed and resolved in frame_b";
            parameter SI.Position rRod1_ia[3]={1,0,0}
            "Vector from origin of frame_a to revolute joint in the middle, resolved in frame_ia";
            parameter SI.Position rRod2_ib[3]={-1,0,0}
            "Vector from origin of frame_ib to revolute joint in the middle, resolved in frame_ib";
            parameter Cv.NonSIunits.Angle_deg phi_offset=0
            "Relative angle offset of revolute joint at frame_b (angle = phi(t) + from_deg(phi_offset))";
            parameter Cv.NonSIunits.Angle_deg phi_guess=0
            "Select the configuration such that at initial time |phi(t0) - from_deg(phi_guess)|is minimal";
            parameter SI.Distance cylinderLength=world.defaultJointLength
            "Length of cylinders representing the revolute joints";
            parameter SI.Distance cylinderDiameter=world.defaultJointWidth
            "Diameter of cylinders representing the revolute joints";
            input Types.Color cylinderColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
            "Color of cylinders representing the revolute joints";
            parameter SI.Diameter rodDiameter=1.1*cylinderDiameter
            "Diameter of the two rods connecting the revolute joints";
            input Types.Color rodColor=Modelica.Mechanics.MultiBody.Types.Defaults.RodColor
            "Color of the two rods connecting the revolute joint";
            input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
            "Reflection of ambient light (= 0: light is completely absorbed)";

            parameter Boolean checkTotalPower=false
            "= true, if total power flowing into this component shall be determined (must be zero)";
            final parameter Real e_a[3](each final unit="1")=Modelica.Math.Vectors.normalize(
                                                         n_a)
            "Unit vector along axes of rotations, resolved in frame_a";
            final parameter Real e_ia[3](each final unit="1")=jointUSR.e2_ia
            "Unit vector along axes of rotations, resolved in frame_ia";
            final parameter Real e_b[3](each final unit="1")=jointUSR.revolute.e
            "Unit vector along axes of rotations, resolved in frame_b, frame_ib and frame_im";
            SI.Power totalPower=jointUSR.totalPower
            "Total power flowing into this element, if checkTotalPower=true (otherwise dummy)";


            JointUSR jointUSR(
              animation=false,
              n1_a=n_a,
              n_b=n_b,
              phi_offset=phi_offset,
              rRod2_ib=rRod2_ib,
              showUniversalAxes=false,
              rRod1_ia=rRod1_ia,
              checkTotalPower=checkTotalPower,
              phi_guess=phi_guess);

        protected
           Visualizers.Advanced.Shape shape_rev1(
              shapeType="cylinder",
              color=cylinderColor,
              specularCoefficient=specularCoefficient,
              length=cylinderLength,
              width=cylinderDiameter,
              height=cylinderDiameter,
              lengthDirection=e_a,
              widthDirection={0,1,0},
              r_shape=-e_a*(cylinderLength/2),
              r=frame_a.r_0,
              R=frame_a.R) if world.enableAnimation and animation;
            Visualizers.Advanced.Shape shape_rev2(
              shapeType="cylinder",
              color=cylinderColor,
              specularCoefficient=specularCoefficient,
              length=cylinderLength,
              width=cylinderDiameter,
              height=cylinderDiameter,
              lengthDirection=e_b,
              widthDirection={0,1,0},
              r_shape=-e_b*(cylinderLength/2),
              r=frame_im.r_0,
              R=frame_im.R) if world.enableAnimation and animation;
            Visualizers.Advanced.Shape shape_rev3(
              shapeType="cylinder",
              color=cylinderColor,
              specularCoefficient=specularCoefficient,
              length=cylinderLength,
              width=cylinderDiameter,
              height=cylinderDiameter,
              lengthDirection=e_b,
              widthDirection={0,1,0},
              r_shape=-e_b*(cylinderLength/2),
              r=frame_b.r_0,
              R=frame_b.R) if world.enableAnimation and animation;
            Visualizers.Advanced.Shape shape_rod1(
              shapeType="cylinder",
              color=rodColor,
              specularCoefficient=specularCoefficient,
              length=Modelica.Math.Vectors.length(
                                   rRod1_ia),
              width=rodDiameter,
              height=rodDiameter,
              lengthDirection=rRod1_ia,
              widthDirection=e_ia,
              r=frame_ia.r_0,
              R=frame_ia.R) if world.enableAnimation and animation;
            Visualizers.Advanced.Shape shape_rod2(
              shapeType="cylinder",
              color=rodColor,
              specularCoefficient=specularCoefficient,
              length=Modelica.Math.Vectors.length(
                                   rRod2_ib),
              width=rodDiameter,
              height=rodDiameter,
              lengthDirection=rRod2_ib,
              widthDirection=e_b,
              r=frame_ib.r_0,
              R=frame_ib.R) if world.enableAnimation and animation;
          initial equation
            n_b = Frames.resolve2(frame_b.R, Frames.resolve1(frame_a.R, n_a));
          equation
            connect(jointUSR.frame_a, frame_a);
            connect(jointUSR.frame_b, frame_b);
            connect(jointUSR.frame_ia, frame_ia);
            connect(jointUSR.frame_im, frame_im);
            connect(jointUSR.frame_ib, frame_ib);
            connect(jointUSR.axis, axis);
            connect(jointUSR.bearing, bearing);
          end JointRRR;

          model JointRRP
          "Planar revolute - revolute - prismatic joint aggregation (no constraints, no potential states)"

            import SI = Modelica.SIunits;
            import Cv = Modelica.SIunits.Conversions;
            import Modelica.Mechanics.MultiBody.Types;

            extends Interfaces.PartialTwoFramesDoubleSize;
            Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_ia
            "Coordinate system at origin of frame_a fixed at connecting rod of revolute joints";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_ib
            "Coordinate system at origin of frame_b fixed at connecting rod of revolute and prismatic joint";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_im
            "Coordinate system at origin of revolute joint in the middle fixed at connecting rod of revolute and prismatic joint";
            Modelica.Mechanics.Translational.Interfaces.Flange_a axis
            "1-dim. translational flange that drives the prismatic joint";
            Modelica.Mechanics.Translational.Interfaces.Flange_b bearing
            "1-dim. translational flange of the drive bearing of the prismatic joint";

            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n_a={0,0,1}
            "Axes of the two revolute joints resolved in frame_a (both axes are parallel to each other)";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n_b={-1,0,0}
            "Axis of prismatic joint fixed and resolved in frame_b (must be orthogonal to revolute joint axes)";
            parameter SI.Position rRod1_ia[3]={1,0,0}
            "Vector from origin of frame_a to revolute joint in the middle, resolved in frame_ia";
            parameter SI.Position rRod2_ib[3]={-1,0,0}
            "Vector from origin of frame_ib to revolute joint in the middle, resolved in frame_ib (frame_ib is parallel to frame_b)";
            parameter SI.Position s_offset=0
            "Relative distance offset of prismatic joint (distance between the prismatic joint frames = s(t) + s_offset)";
            parameter SI.Position s_guess=0
            "Select the configuration such that at initial time |s(t0)-s_guess|is minimal";
            parameter SI.Distance cylinderLength=world.defaultJointLength
            "Length of cylinders representing the revolute joints";
            parameter SI.Distance cylinderDiameter=world.defaultJointWidth
            "Diameter of cylinders representing the revolute joints";
            input Types.Color cylinderColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
            "Color of cylinders representing the revolute joints";
            parameter Types.Axis boxWidthDirection={0,1,0}
            "Vector in width direction of prismatic joint, resolved in frame_b";
            parameter SI.Distance boxWidth=world.defaultJointWidth
            "Width of prismatic joint box";
            parameter SI.Distance boxHeight=boxWidth
            "Height of prismatic joint box";
            input Types.Color boxColor=cylinderColor
            "Color of prismatic joint box";
            parameter SI.Diameter rodDiameter=1.1*cylinderDiameter
            "Diameter of the two rods connecting the joints";
            input Types.Color rodColor=Modelica.Mechanics.MultiBody.Types.Defaults.RodColor
            "Color of the two rods connecting the joints";
            input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
            "Reflection of ambient light (= 0: light is completely absorbed)";
            parameter Boolean checkTotalPower=false
            "= true, if total power flowing into this component shall be determined (must be zero)";
            final parameter Real e_a[3](each final unit="1")=Modelica.Math.Vectors.normalize(
                                                         n_a)
            "Unit vector along axes of rotations, resolved in frame_a";
            final parameter Real e_ia[3](each final unit="1")=jointUSP.e2_ia
            "Unit vector along axes of rotations, resolved in frame_ia";
            final parameter Real e_im[3](each final unit="1", each fixed=false)
            "Unit vector along axes of rotations, resolved in frame_im";
            final parameter Real e_b[3](each final unit="1")=jointUSP.prismatic.e
            "Unit vector along axes of translation of the prismatic joint, resolved in frame_b and frame_ib";
            SI.Power totalPower=jointUSP.totalPower
            "Total power flowing into this element, if checkTotalPower=true (otherwise dummy)";


            JointUSP jointUSP(
              animation=false,
              showUniversalAxes=false,
              n1_a=n_a,
              n_b=n_b,
              s_offset=s_offset,
              s_guess=s_guess,
              rRod1_ia=rRod1_ia,
              rRod2_ib=rRod2_ib,
              checkTotalPower=checkTotalPower);

        protected
            Visualizers.Advanced.Shape shape_rev1(
              shapeType="cylinder",
              color=cylinderColor,
              specularCoefficient=specularCoefficient,
              length=cylinderLength,
              width=cylinderDiameter,
              height=cylinderDiameter,
              lengthDirection=e_a,
              widthDirection={0,1,0},
              r_shape=-e_a*(cylinderLength/2),
              r=frame_a.r_0,
              R=frame_a.R) if world.enableAnimation and animation;
            Visualizers.Advanced.Shape shape_rev2(
              shapeType="cylinder",
              color=cylinderColor,
              specularCoefficient=specularCoefficient,
              length=cylinderLength,
              width=cylinderDiameter,
              height=cylinderDiameter,
              lengthDirection=e_im,
              widthDirection={0,1,0},
              r_shape=-e_im*(cylinderLength/2),
              r=frame_im.r_0,
              R=frame_im.R) if world.enableAnimation and animation;
            Visualizers.Advanced.Shape shape_prism(
              shapeType="box",
              color=boxColor,
              specularCoefficient=specularCoefficient,
              length=jointUSP.prismatic.distance,
              width=boxWidth,
              height=boxHeight,
              lengthDirection=e_b,
              widthDirection=e_im,
              r=frame_b.r_0,
              R=frame_b.R) if world.enableAnimation and animation;
            Visualizers.Advanced.Shape shape_rod1(
              shapeType="cylinder",
              color=rodColor,
              specularCoefficient=specularCoefficient,
              length=Modelica.Math.Vectors.length(
                                   rRod1_ia),
              width=rodDiameter,
              height=rodDiameter,
              lengthDirection=rRod1_ia,
              widthDirection=e_ia,
              r=frame_ia.r_0,
              R=frame_ia.R) if world.enableAnimation and animation;
            Visualizers.Advanced.Shape shape_rod2(
              shapeType="cylinder",
              color=rodColor,
              specularCoefficient=specularCoefficient,
              length=Modelica.Math.Vectors.length(
                                   rRod2_ib),
              width=rodDiameter,
              height=rodDiameter,
              lengthDirection=rRod2_ib,
              widthDirection=e_b,
              r=frame_ib.r_0,
              R=frame_ib.R) if world.enableAnimation and animation;
          initial equation
            e_im = Frames.resolve2(frame_im.R, Frames.resolve1(frame_a.R, e_a));
          equation
            connect(jointUSP.frame_a, frame_a);
            connect(jointUSP.frame_b, frame_b);
            connect(jointUSP.frame_ia, frame_ia);
            connect(jointUSP.frame_im, frame_im);
            connect(jointUSP.frame_ib, frame_ib);
            connect(jointUSP.axis, axis);
            connect(jointUSP.bearing, bearing);
          end JointRRP;
        end Assemblies;

        package Internal
        "Components used for analytic solution of kinematic loops (use only if you know what you are doing)"
          extends Modelica.Icons.Library;

          model RevoluteWithLengthConstraint
          "Revolute joint where the rotation angle is computed from a length constraint (1 degree-of-freedom, no potential state)"

            import SI = Modelica.SIunits;
            import Cv = Modelica.SIunits.Conversions;
            extends Modelica.Mechanics.MultiBody.Interfaces.PartialTwoFrames;
            Modelica.Mechanics.Rotational.Interfaces.Flange_a axis
            "1-dim. rotational flange that drives the joint";
            Modelica.Mechanics.Rotational.Interfaces.Flange_b bearing
            "1-dim. rotational flange of the drive bearing";

            Modelica.Blocks.Interfaces.RealInput position_a[3](each final
              quantity =                                                           "Position", each
              final unit =                                                                                     "m")
            "Position vector from frame_a to frame_a side of length constraint, resolved in frame_a of revolute joint";
            Modelica.Blocks.Interfaces.RealInput position_b[3](each final
              quantity =                                                           "Position",
              each final unit="m")
            "Position vector from frame_b to frame_b side of length constraint, resolved in frame_b of revolute joint";

            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            parameter SI.Position lengthConstraint(start=1)
            "Fixed length of length constraint";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n={0,0,1}
            "Axis of rotation resolved in frame_a (= same as in frame_b)";
            parameter Cv.NonSIunits.Angle_deg phi_offset=0
            "Relative angle offset (angle = phi + from_deg(phi_offset))";
            parameter Cv.NonSIunits.Angle_deg phi_guess=0
            "Select the configuration such that at initial time |phi - from_deg(phi_guess)|is minimal";
            parameter SI.Distance cylinderLength=world.defaultJointLength
            "Length of cylinder representing the joint axis";
            parameter SI.Distance cylinderDiameter=world.defaultJointWidth
            "Diameter of cylinder representing the joint axis";
            input Types.Color cylinderColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
            "Color of cylinder representing the joint axis";
            input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
            "Reflection of ambient light (= 0: light is completely absorbed)";

            final parameter Boolean positiveBranch(fixed=false)
            "Based on phi_guess, selection of one of the two solutions of the non-linear constraint equation";
            final parameter Real e[3](each final unit="1")=Modelica.Math.Vectors.normalize(              n)
            "Unit vector in direction of rotation axis, resolved in frame_a";

            SI.Angle phi "Rotation angle of revolute joint";
            Frames.Orientation R_rel
            "Relative orientation object from frame_a to frame_b";
            SI.Angle angle
            "= phi + from_deg(phi_offset) (relative rotation angle between frame_a and frame_b)";
            SI.Torque tau "= axis.tau (driving torque in the axis)";


        protected
            SI.Position r_a[3]=position_a
            "Position vector from frame_a to frame_a side of length constraint, resolved in frame_a of revolute joint";
            SI.Position r_b[3]=position_b
            "Position vector from frame_b to frame_b side of length constraint, resolved in frame_b of revolute joint";
            Real e_r_a "Projection of r_a on e";
            Real e_r_b "Projection of r_b on e";
            Real A "Coefficient A of equation: A*cos(phi) + B*sin(phi) + C = 0";
            Real B "Coefficient B of equation: A*cos(phi) + B*sin(phi) + C = 0";
            Real C "Coefficient C of equation: A*cos(phi) + B*sin(phi) + C = 0";
            Real k1 "Constant of quadratic equation";
            Real k2 "Constant of quadratic equation";
            Real k1a(start=1);
            Real k1b;
            Real kcos_angle "= k1*cos(angle)";
            Real ksin_angle "= k1*sin(angle)";

            Visualizers.Advanced.Shape cylinder(
              shapeType="cylinder",
              color=cylinderColor,
              specularCoefficient=specularCoefficient,
              length=cylinderLength,
              width=cylinderDiameter,
              height=cylinderDiameter,
              lengthDirection=e,
              widthDirection={0,1,0},
              r_shape=-e*(cylinderLength/2),
              r=frame_a.r_0,
              R=frame_a.R) if world.enableAnimation and animation;

            function selectBranch
            "Determine branch which is closest to initial angle=0"

              import Modelica.Math.*;
              input SI.Length L "Length of length constraint";
              input Real e[3](each final unit="1")
              "Unit vector along axis of rotation, resolved in frame_a (= same in frame_b)";
              input SI.Angle angle_guess
              "Select the configuration such that at initial time |angle-angle_guess|is minimal (angle=0: frame_a and frame_b coincide)";
              input SI.Position r_a[3]
              "Position vector from frame_a to frame_a side of length constraint, resolved in frame_a of revolute joint";
              input SI.Position r_b[3]
              "Position vector from frame_b to frame_b side of length constraint, resolved in frame_b of revolute joint";
              output Boolean positiveBranch "Branch of the initial solution";
          protected
              Real e_r_a "Projection of r_a on e";
              Real e_r_b "Projection of r_b on e";
              Real A
              "Coefficient A of equation: A*cos(phi) + B*sin(phi) + C = 0";
              Real B
              "Coefficient B of equation: A*cos(phi) + B*sin(phi) + C = 0";
              Real C
              "Coefficient C of equation: A*cos(phi) + B*sin(phi) + C = 0";
              Real k1 "Constant of quadratic equation";
              Real k2 "Constant of quadratic equation";
              Real k1a;
              Real k1b;
              Real kcos1 "k1*cos(angle1)";
              Real ksin1 "k1*sin(angle1)";
              Real kcos2 "k2*cos(angle2)";
              Real ksin2 "k2*sin(angle2)";
              SI.Angle angle1 "solution 1 of nonlinear equation";
              SI.Angle angle2 "solution 2 of nonlinear equation";
            algorithm
              /* The position vector r_rel from frame_a to frame_b of the length constraint
       element, resolved in frame_b of the revolute joint is given by
       (T_rel is the planar transformation matrix from frame_a to frame_b of
        the revolute joint):
          r_rel = r_b - T_rel*r_a
       The length constraint can therefore be formulated as:
          r_rel*r_rel = L*L
       with
          (r_b - T_rel*r_a)*(r_b - T_rel*r_a)
             = r_b*r_b - 2*r_b*T_rel*r_a + r_a*transpose(T_rel)*T_rel*r_a
             = r_b*r_b + r_a*r_a - 2*r_b*T_rel*r_a
       follows
          (1) 0 = r_a*r_a + r_b*r_b - 2*r_b*T_rel*r_a - L*L
       The vectors r_a, r_b and parameter L are NOT a function of
       the angle of the revolute joint. Since T_rel = T_rel(angle) is a function
       of the unknown angle of the revolute joint, this is a non-linear
       equation in this angle.
          T_rel = [e]*tranpose([e]) + (identity(3) - [e]*transpose([e]))*cos(angle)
                  - skew(e)*sin(angle);
       with
          r_b*T_rel*r_a
             = r_b*(e*(e*r_a) + (r_a - e*(e*r_a))*cos(angle) - cross(e,r_a)*sin(angle)
             = (e*r_b)*(e*r_a) + (r_b*r_a - (e*r_b)*(e*r_a))*cos(angle) - r_b*cross(e,r_a)*sin(angle)
       follows for the constraint equation (1)
          (2) 0 = r_a*r_a + r_b*r_b - L*L
                  - 2*(e*r_b)*(e*r_a)
                  - 2*(r_b*r_a - (e*r_b)*(e*r_a))*cos(angle)
                  + 2*r_b*cross(e,r_a)*sin(angle)
       or
          (3) A*cos(angle) + B*sin(angle) + C = 0
       with
              A = -2*(r_b*r_a - (e*r_b)*(e*r_a))
              B = 2*r_b*cross(e,r_a)
              C = r_a*r_a + r_b*r_b - L*L - 2*(e*r_b)*(e*r_a)
       Equation (3) is solved by computing sin(angle) and cos(angle)
       independently from each other. This allows to compute
       angle in the range: -180 deg <= angle <= 180 deg
    */
              e_r_a := e*r_a;
              e_r_b := e*r_b;
              A := -2*(r_b*r_a - e_r_b*e_r_a);
              B := 2*r_b*cross(e, r_a);
              C := r_a*r_a + r_b*r_b - L*L - 2*e_r_b*e_r_a;
              k1 := A*A + B*B;
              k1a :=k1 - C*C;
              assert(k1a > 1.e-10, "
Singular position of loop (either no or two analytic solutions;
the mechanism has lost one-degree-of freedom in this position).
Try first to use another Modelica.Mechanics.MultiBody.Joints.Assemblies.JointXXX component.
In most cases it is best that the joints outside of the JointXXX
component are revolute and NOT prismatic joints. If this also
lead to singular positions, it could be that this kinematic loop
cannot be solved analytically. In this case you have to build
up the loop with basic joints (NO aggregation JointXXX components)
and rely on dynamic state selection, i.e., during simulation
the states will be dynamically selected in such a way that in no
position a degree of freedom is lost.
");
              k1b := max(k1a, 1.0e-12);
              k2 := sqrt(k1b);

              kcos1 := -A*C + B*k2;
              ksin1 := -B*C - A*k2;
              angle1 := atan2(ksin1, kcos1);

              kcos2 := -A*C - B*k2;
              ksin2 := -B*C + A*k2;
              angle2 := atan2(ksin2, kcos2);

              if abs(angle1 - angle_guess) <= abs(angle2 - angle_guess) then
                positiveBranch := true;
              else
                positiveBranch := false;
              end if;
            end selectBranch;
          initial equation
            positiveBranch = selectBranch(lengthConstraint, e, Cv.from_deg(phi_offset
               + phi_guess), r_a, r_b);
          equation
            Connections.branch(frame_a.R, frame_b.R);
            axis.tau = tau;
            axis.phi = phi;
            bearing.phi = 0;

            angle = Cv.from_deg(phi_offset) + phi;

            // transform kinematic quantities from frame_a to frame_b
            frame_b.r_0 = frame_a.r_0;

            R_rel = Frames.planarRotation(e, angle, der(angle));
            frame_b.R = Frames.absoluteRotation(frame_a.R, R_rel);

            // Force and torque balance
            zeros(3) = frame_a.f + Frames.resolve1(R_rel, frame_b.f);
            zeros(3) = frame_a.t + Frames.resolve1(R_rel, frame_b.t);

            // Compute rotation angle (details, see function "selectBranch")
            e_r_a = e*r_a;
            e_r_b = e*r_b;
            A = -2*(r_b*r_a - e_r_b*e_r_a);
            B = 2*r_b*cross(e, r_a);
            C = r_a*r_a + r_b*r_b - lengthConstraint*lengthConstraint - 2*e_r_b*e_r_a;
            k1 = A*A + B*B;
            k1a = k1 - C*C;

            assert(k1a > 1.e-10, "
Singular position of loop (either no or two analytic solutions;
the mechanism has lost one-degree-of freedom in this position).
Try first to use another Modelica.Mechanics.MultiBody.Joints.Assemblies.JointXXX component.
In most cases it is best that the joints outside of the JointXXX
component are revolute and NOT prismatic joints. If this also
lead to singular positions, it could be that this kinematic loop
cannot be solved analytically. In this case you have to build
up the loop with basic joints (NO aggregation JointXXX components)
and rely on dynamic state selection, i.e., during simulation
the states will be dynamically selected in such a way that in no
position a degree of freedom is lost.
");

            k1b = Frames.Internal.maxWithoutEvent(k1a, 1.0e-12);
            k2 = sqrt(k1b);
            kcos_angle = -A*C + (if positiveBranch then B else -B)*k2;
            ksin_angle = -B*C + (if positiveBranch then -A else A)*k2;

            angle = Modelica.Math.atan2(ksin_angle, kcos_angle);
          end RevoluteWithLengthConstraint;

          model PrismaticWithLengthConstraint
          "Prismatic joint where the translational distance is computed from a length constraint (1 degree-of-freedom, no potential state)"

            import SI = Modelica.SIunits;
            import Cv = Modelica.SIunits.Conversions;
            extends Modelica.Mechanics.MultiBody.Interfaces.PartialTwoFrames;
            Modelica.Mechanics.Translational.Interfaces.Flange_a axis
            "1-dim. translational flange that drives the joint";
            Modelica.Mechanics.Translational.Interfaces.Flange_b bearing
            "1-dim. translational flange of the drive bearing";
            Modelica.Blocks.Interfaces.RealInput position_a[3]
            "Position vector from frame_a to frame_a side of length constraint, resolved in frame_a of revolute joint";
            Modelica.Blocks.Interfaces.RealInput position_b[3]
            "Position vector from frame_b to frame_b side of length constraint, resolved in frame_b of revolute joint";

            parameter Boolean animation=true
            "= true, if animation shall be enabled";
            parameter SI.Position length(start=1)
            "Fixed length of length constraint";
            parameter Modelica.Mechanics.MultiBody.Types.Axis n={1,0,0}
            "Axis of translation resolved in frame_a (= same as in frame_b)";
            parameter SI.Position s_offset=0
            "Relative distance offset (distance between frame_a and frame_b = s(t) + s_offset)";
            parameter SI.Position s_guess=0
            "Select the configuration such that at initial time |s(t0)-s_guess|is minimal";
            parameter Types.Axis boxWidthDirection={0,1,0}
            "Vector in width direction of box, resolved in frame_a";
            parameter SI.Distance boxWidth=world.defaultJointWidth
            "Width of prismatic joint box";
            parameter SI.Distance boxHeight=boxWidth
            "Height of prismatic joint box";
            input Types.Color boxColor=Modelica.Mechanics.MultiBody.Types.Defaults.JointColor
            "Color of prismatic joint box";
            input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
            "Reflection of ambient light (= 0: light is completely absorbed)";

            final parameter Boolean positiveBranch(fixed=false)
            "Selection of one of the two solutions of the non-linear constraint equation";
            final parameter Real e[3](each final unit="1")=Modelica.Math.Vectors.normalize(              n)
            "Unit vector in direction of translation axis, resolved in frame_a";
            SI.Position s
            "Relative distance between frame_a and frame_b along axis n = s + s_offset)";
            SI.Position distance
            "Relative distance between frame_a and frame_b along axis n";
            SI.Position r_rel_a[3]
            "Position vector from frame_a to frame_b resolved in frame_a";
            SI.Force f "= axis.f (driving force in the axis)";


        protected
            SI.Position r_a[3]=position_a
            "Position vector from frame_a to frame_a side of length constraint, resolved in frame_a of revolute joint";
            SI.Position r_b[3]=position_b
            "Position vector from frame_b to frame_b side of length constraint, resolved in frame_b of revolute joint";
            Modelica.SIunits.Position rbra[3] "= rb - ra";
            Real B "Coefficient B of equation: s*s + B*s + C = 0";
            Real C "Coefficient C of equation: s*s + B*s + C = 0";
            Real k1 "Constant of quadratic equation solution";
            Real k2 "Constant of quadratic equation solution";
            Real k1a(start=1);
            Real k1b;

            Visualizers.Advanced.Shape box(
              shapeType="box",
              color=boxColor,
              specularCoefficient=specularCoefficient,
              length=if noEvent(abs(s + s_offset) > 1.e-6) then s + s_offset else 1.e-6,
              width=boxWidth,
              height=boxHeight,
              lengthDirection=e,
              widthDirection=boxWidthDirection,
              r=frame_a.r_0,
              R=frame_a.R) if world.enableAnimation and animation;

            function selectBranch
            "Determine branch which is closest to initial angle=0"
              import Modelica.Math.*;
              input SI.Length L "Length of length constraint";
              input Real e[3](each final unit="1")
              "Unit vector along axis of translation, resolved in frame_a (= same in frame_b)";
              input SI.Position d_guess
              "Select the configuration such that at initial time |d-d_guess|is minimal (d: distance between origin of frame_a and origin of frame_b)";
              input SI.Position r_a[3]
              "Position vector from frame_a to frame_a side of length constraint, resolved in frame_a of prismatic joint";
              input SI.Position r_b[3]
              "Position vector from frame_b to frame_b side of length constraint, resolved in frame_b of prismatic joint";
              output Boolean positiveBranch "Branch of the initial solution";
          protected
              Modelica.SIunits.Position rbra[3] "= rb - ra";
              Real B "Coefficient B of equation: d*d + B*d + C = 0";
              Real C "Coefficient C of equation: d*d + B*d + C = 0";
              Real k1 "Constant of quadratic equation solution";
              Real k2 "Constant of quadratic equation solution";
              Real k1a;
              Real k1b;
              Real d1 "solution 1 of quadratic equation";
              Real d2 "solution 2 of quadratic equation";
            algorithm
              /* The position vector r_rel from frame_a to frame_b of the length constraint
       element, resolved in frame_b of the prismatic joint (frame_a and frame_b
       of the prismatic joint are parallel to each other) is given by:
          r_rel = d*e + r_b - r_a
       The length constraint can therefore be formulated as:
          r_rel*r_rel = L*L
       with
          (d*e + r_b - r_a)*(d*e + r_b - r_a)
                   = d*d + 2*d*e*(r_b - r_a) + (r_b - r_a)*(r_b - r_a)
       follows
          (1)  0 = d*d + d*2*e*(r_b - r_a) + (r_b - r_a)*(r_b - r_a) - L*L
       The vectors r_a, r_b and parameter L are NOT a function of
       the distance d of the prismatic joint. Therefore, (1) is a quadratic
       equation in the single unknown "d":
          (2) d*d + B*d + C = 0
              with   B = 2*e*(r_b - r_a)
                     C = (r_b - r_a)*(r_b - r_a) - L*L
       The solution is
          (3) d = - B/2 +/- sqrt(B*B/4 - C)
    */
              rbra := r_b - r_a;
              B := 2*(e*rbra);
              C := rbra*rbra - L*L;
              k1 := B/2;
              k1a :=k1*k1 - C;
            assert(noEvent(k1a > 1.e-10), "
Singular position of loop (either no or two analytic solutions;
the mechanism has lost one-degree-of freedom in this position).
Try first to use another Modelica.Mechanics.MultiBody.Joints.Assemblies.JointXXX component.
If this also lead to singular positions, it could be that this
kinematic loop cannot be solved analytically with a fixed state
selection. In this case you have to build up the loop with
basic joints (NO aggregation JointXXX components) and rely on
dynamic state selection, i.e., during simulation the states will
be dynamically selected in such a way that in no position a
degree of freedom is lost.
");
              k1b :=max(k1a, 1.0e-12);
              k2 :=sqrt(k1b);
              d1 := -k1 + k2;
              d2 := -k1 - k2;
              if abs(d1 - d_guess) <= abs(d2 - d_guess) then
                positiveBranch := true;
              else
                positiveBranch := false;
              end if;
            end selectBranch;
          initial equation
            positiveBranch = selectBranch(length, e, s_offset + s_guess, r_a, r_b);
          equation
            Connections.branch(frame_a.R, frame_b.R);

            axis.f = f;
            axis.s = s;
            bearing.s = 0;
            distance = s_offset + s;

            // relationships of frame_a and frame_b quantities
            r_rel_a = e*distance;
            frame_b.r_0 = frame_a.r_0 + Frames.resolve1(frame_a.R, r_rel_a);
            frame_b.R = frame_a.R;
            zeros(3) = frame_a.f + frame_b.f;
            zeros(3) = frame_a.t + frame_b.t + cross(r_rel_a, frame_b.f);

            // Compute translational distance (details, see function "selectBranch")
            rbra = r_b - r_a;
            B = 2*(e*rbra);
            C = rbra*rbra - length*length;
            k1 = B/2;
            k1a = k1*k1 - C;
            assert(noEvent(k1a > 1.e-10), "
Singular position of loop (either no or two analytic solutions;
the mechanism has lost one-degree-of freedom in this position).
Try first to use another Modelica.Mechanics.MultiBody.Joints.Assemblies.JointXXX component.
If this also lead to singular positions, it could be that this
kinematic loop cannot be solved analytically with a fixed state
selection. In this case you have to build up the loop with
basic joints (NO aggregation JointXXX components) and rely on
dynamic state selection, i.e., during simulation the states will
be dynamically selected in such a way that in no position a
degree of freedom is lost.
");
            k1b = Frames.Internal.maxWithoutEvent(k1a, 1.0e-12);
            k2 = sqrt(k1b);
            distance = -k1 + (if positiveBranch then k2 else -k2);
          end PrismaticWithLengthConstraint;
        end Internal;
      end Joints;

      package Parts
      "Rigid components such as bodies with mass and inertia and massless rods"
        import SI = Modelica.SIunits;
        extends Modelica.Icons.Library;

        model FixedTranslation
        "Fixed translation of frame_b with respect to frame_a"

          import SI = Modelica.SIunits;
          import Modelica.Mechanics.MultiBody.Types;
          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the component with one cut-force and cut-torque";

          parameter Boolean animation=true
          "= true, if animation shall be enabled";
          parameter SI.Position r[3](start={0,0,0})
          "Vector from frame_a to frame_b resolved in frame_a";
          parameter Types.ShapeType shapeType="cylinder" " Type of shape";
          parameter SI.Position r_shape[3]={0,0,0}
          " Vector from frame_a to shape origin, resolved in frame_a";
          parameter Types.Axis lengthDirection=r - r_shape
          " Vector in length direction of shape, resolved in frame_a";
          parameter Types.Axis widthDirection={0,1,0}
          " Vector in width direction of shape, resolved in frame_a";
          parameter SI.Length length=Modelica.Math.Vectors.length(
                                                   r - r_shape)
          " Length of shape";
          parameter SI.Distance width=length/world.defaultWidthFraction
          " Width of shape";
          parameter SI.Distance height=width " Height of shape.";
          parameter Types.ShapeExtra extra=0.0
          " Additional parameter depending on shapeType (see docu of Visualizers.Advanced.Shape).";
          input Types.Color color=Modelica.Mechanics.MultiBody.Types.Defaults.RodColor
          " Color of shape";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";


      protected
          outer Modelica.Mechanics.MultiBody.World world;
          Visualizers.Advanced.Shape shape(
            shapeType=shapeType,
            color=color,
            specularCoefficient=specularCoefficient,
            r_shape=r_shape,
            lengthDirection=lengthDirection,
            widthDirection=widthDirection,
            length=length,
            width=width,
            height=height,
            extra=extra,
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
        equation
          Connections.branch(frame_a.R, frame_b.R);
          assert(cardinality(frame_a) > 0 or cardinality(frame_b) > 0,
            "Neither connector frame_a nor frame_b of FixedTranslation object is connected");

          frame_b.r_0 = frame_a.r_0 + Frames.resolve1(frame_a.R, r);
          frame_b.R = frame_a.R;

          /* Force and torque balance */
          zeros(3) = frame_a.f + frame_b.f;
          zeros(3) = frame_a.t + frame_b.t + cross(r, frame_b.f);
        end FixedTranslation;

        model FixedRotation
        "Fixed translation followed by a fixed rotation of frame_b with respect to frame_a"

          import Modelica.Mechanics.MultiBody.Frames;
          import Modelica.Mechanics.MultiBody.Types;
          import SI = Modelica.SIunits;
          import Cv = Modelica.SIunits.Conversions;
          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the component with one cut-force and cut-torque";

          parameter Boolean animation=true
          "= true, if animation shall be enabled";
          parameter SI.Position r[3]={0,0,0}
          "Vector from frame_a to frame_b resolved in frame_a";
          parameter Modelica.Mechanics.MultiBody.Types.RotationTypes
          rotationType=
                    Modelica.Mechanics.MultiBody.Types.RotationTypes.RotationAxis
          "Type of rotation description";
          parameter Types.Axis n={1,0,0}
          " Axis of rotation in frame_a (= same as in frame_b)";
          parameter Cv.NonSIunits.Angle_deg angle=0
          " Angle to rotate frame_a around axis n into frame_b";

          parameter Types.Axis n_x={1,0,0}
          " Vector along x-axis of frame_b resolved in frame_a";
          parameter Types.Axis n_y={0,1,0}
          " Vector along y-axis of frame_b resolved in frame_a";

          parameter Types.RotationSequence sequence(
            min={1,1,1},
            max={3,3,3}) = {1,2,3} " Sequence of rotations";
          parameter Cv.NonSIunits.Angle_deg angles[3]={0,0,0}
          " Rotation angles around the axes defined in 'sequence'";
          parameter Types.ShapeType shapeType="cylinder" " Type of shape";
          parameter SI.Position r_shape[3]={0,0,0}
          " Vector from frame_a to shape origin, resolved in frame_a";
          parameter Types.Axis lengthDirection=r - r_shape
          " Vector in length direction of shape, resolved in frame_a";
          parameter Types.Axis widthDirection={0,1,0}
          " Vector in width direction of shape, resolved in frame_a";
          parameter SI.Length length=Modelica.Math.Vectors.length(
                                                   r - r_shape)
          " Length of shape";
          parameter SI.Distance width=length/world.defaultWidthFraction
          " Width of shape";
          parameter SI.Distance height=width " Height of shape.";
          parameter Types.ShapeExtra extra=0.0
          " Additional parameter depending on shapeType (see docu of Visualizers.Advanced.Shape).";
        /*
  parameter Boolean checkTotalPower=false
    "= true, if total power flowing into this component shall be determined (must be zero)"
    annotation (Dialog(tab="Advanced"));
*/

          input Types.Color color=Modelica.Mechanics.MultiBody.Types.Defaults.RodColor
          " Color of shape";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";
          final parameter Frames.Orientation R_rel=if rotationType == 1 then 
              Frames.planarRotation(Modelica.Math.Vectors.normalize(
                                                     n), Cv.from_deg(angle), 0) else 
              if rotationType == 2 then Frames.from_nxy(n_x, n_y) else 
              Frames.axesRotations(sequence, Cv.from_deg(angles), zeros(3))
          "Fixed rotation object from frame_a to frame_b";
        /*
  SI.Power totalPower
    "Total power flowing into this element, if checkTotalPower=true (otherwise dummy)";
*/
      protected
          outer Modelica.Mechanics.MultiBody.World world;

          /*
  parameter Frames.Orientation R_rel_inv=
      Frames.inverseRotation(R_rel)
*/
          parameter Frames.Orientation R_rel_inv=Frames.from_T(transpose(R_rel.T),
              zeros(3)) "Inverse of R_rel (rotate from frame_b to frame_a)";
          Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape shape(
            shapeType=shapeType,
            color=color,
            specularCoefficient=specularCoefficient,
            r_shape=r_shape,
            lengthDirection=lengthDirection,
            widthDirection=widthDirection,
            length=length,
            width=width,
            height=height,
            extra=extra,
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;

        equation
          Connections.branch(frame_a.R, frame_b.R);
          assert(cardinality(frame_a) > 0 or cardinality(frame_b) > 0,
            "Neither connector frame_a nor frame_b of FixedRotation object is connected");

          /* Relationships between quantities of frame_a and frame_b */
          frame_b.r_0 = frame_a.r_0 + Frames.resolve1(frame_a.R, r);
          if rooted(frame_a.R) then
            frame_b.R = Frames.absoluteRotation(frame_a.R, R_rel);
            zeros(3) = frame_a.f + Frames.resolve1(R_rel, frame_b.f);
            zeros(3) = frame_a.t + Frames.resolve1(R_rel, frame_b.t) - cross(r, frame_a.f);
          else
            frame_a.R = Frames.absoluteRotation(frame_b.R, R_rel_inv);
            zeros(3) = frame_b.f + Frames.resolve1(R_rel_inv, frame_a.f);
            zeros(3) = frame_b.t + Frames.resolve1(R_rel_inv, frame_a.t) + cross(Frames.resolve1(R_rel_inv,r), frame_b.f);
          end if;

        /*
  if checkTotalPower then
    totalPower = frame_a.f*Frames.resolve2(frame_a.R, der(frame_a.r_0)) +
                 frame_b.f*Frames.resolve2(frame_b.R, der(frame_b.r_0)) +
                 frame_a.t*Frames.angularVelocity2(frame_a.R) +
                 frame_b.t*Frames.angularVelocity2(frame_b.R);
  else
    totalPower = 0;
  end if;
*/
        end FixedRotation;

        model Body
        "Rigid body with mass, inertia tensor and one frame connector (12 potential states)"

          import SI = Modelica.SIunits;
          import C = Modelica.Constants;
          import Modelica.Math.*;
          import Modelica.Mechanics.MultiBody.Types;
          import Modelica.Mechanics.MultiBody.Frames;
          Interfaces.Frame_a frame_a "Coordinate system fixed at body";
          parameter Boolean animation=true
          "= true, if animation shall be enabled (show cylinder and sphere)";
          parameter SI.Position r_CM[3](start={0,0,0})
          "Vector from frame_a to center of mass, resolved in frame_a";
          parameter SI.Mass m(min=0, start = 1) "Mass of rigid body";
          parameter SI.Inertia I_11(min=0) = 0.001
          " (1,1) element of inertia tensor";
          parameter SI.Inertia I_22(min=0) = 0.001
          " (2,2) element of inertia tensor";
          parameter SI.Inertia I_33(min=0) = 0.001
          " (3,3) element of inertia tensor";
          parameter SI.Inertia I_21(min=-C.inf)=0
          " (2,1) element of inertia tensor";
          parameter SI.Inertia I_31(min=-C.inf)=0
          " (3,1) element of inertia tensor";
          parameter SI.Inertia I_32(min=-C.inf)=0
          " (3,2) element of inertia tensor";

          SI.Position r_0[3](start={0,0,0}, each stateSelect=if enforceStates then 
                      StateSelect.always else StateSelect.avoid)
          "Position vector from origin of world frame to origin of frame_a";
          SI.Velocity v_0[3](start={0,0,0}, each stateSelect=if enforceStates then StateSelect.always else 
                      StateSelect.avoid)
          "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
          SI.Acceleration a_0[3](start={0,0,0})
          "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";

          parameter Boolean angles_fixed = false
          "= true, if angles_start are used as initial values, else as guess values";
          parameter SI.Angle angles_start[3]={0,0,0}
          "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
          parameter Types.RotationSequence sequence_start={1,2,3}
          "Sequence of rotations to rotate frame_a into frame_b at initial time";

          parameter Boolean w_0_fixed = false
          "= true, if w_0_start are used as initial values, else as guess values";
          parameter SI.AngularVelocity w_0_start[3]={0,0,0}
          "Initial or guess values of angular velocity of frame_a resolved in world frame";

          parameter Boolean z_0_fixed = false
          "= true, if z_0_start are used as initial values, else as guess values";
          parameter SI.AngularAcceleration z_0_start[3]={0,0,0}
          "Initial values of angular acceleration z_0 = der(w_0)";

          parameter SI.Diameter sphereDiameter=world.defaultBodyDiameter
          "Diameter of sphere";
          input Types.Color sphereColor=Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor
          "Color of sphere";
          parameter SI.Diameter cylinderDiameter=sphereDiameter/Types.Defaults.
              BodyCylinderDiameterFraction "Diameter of cylinder";
          input Types.Color cylinderColor=sphereColor "Color of cylinder";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";
          parameter Boolean enforceStates=false
          " = true, if absolute variables of body object shall be used as states (StateSelect.always)";
          parameter Boolean useQuaternions=true
          " = true, if quaternions shall be used as potential states otherwise use 3 angles as potential states";
          parameter Types.RotationSequence sequence_angleStates={1,2,3}
          " Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";

          final parameter SI.Inertia I[3, 3]=[I_11, I_21, I_31; I_21, I_22, I_32;
              I_31, I_32, I_33] "inertia tensor";
          final parameter Frames.Orientation R_start=Modelica.Mechanics.MultiBody.Frames.axesRotations(
              sequence_start, angles_start, zeros(3))
          "Orientation object from world frame to frame_a at initial time";
          final parameter SI.AngularAcceleration z_a_start[3]=Frames.resolve2(R_start, z_0_start)
          "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";

          SI.AngularVelocity w_a[3](start=Frames.resolve2(R_start, w_0_start),
                                    fixed=fill(w_0_fixed,3),
                                    each stateSelect=if enforceStates then (if useQuaternions then 
                                    StateSelect.always else StateSelect.never) else StateSelect.avoid)
          "Absolute angular velocity of frame_a resolved in frame_a";
          SI.AngularAcceleration z_a[3](start=Frames.resolve2(R_start, z_0_start),fixed=fill(z_0_fixed,3))
          "Absolute angular acceleration of frame_a resolved in frame_a";
          SI.Acceleration g_0[3] "Gravity acceleration resolved in world frame";

      protected
          outer Modelica.Mechanics.MultiBody.World world;

          // Declarations for quaternions (dummies, if quaternions are not used)
          parameter Frames.Quaternions.Orientation Q_start=Frames.to_Q(R_start)
          "Quaternion orientation object from world frame to frame_a at initial time";
          Frames.Quaternions.Orientation Q(start=Q_start, each stateSelect=if 
                enforceStates then (if useQuaternions then StateSelect.prefer else 
                StateSelect.never) else StateSelect.avoid)
          "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";

          // Declaration for 3 angles
          parameter SI.Angle phi_start[3]=if sequence_start[1] ==
              sequence_angleStates[1] and sequence_start[2] == sequence_angleStates[2]
               and sequence_start[3] == sequence_angleStates[3] then angles_start else 
               Frames.axesRotationsAngles(R_start, sequence_angleStates)
          "Potential angle states at initial time";
          SI.Angle phi[3](start=phi_start, each stateSelect=if enforceStates then (if 
                useQuaternions then StateSelect.never else StateSelect.always) else 
                StateSelect.avoid)
          "Dummy or 3 angles to rotate world frame into frame_a of body";
          SI.AngularVelocity phi_d[3](each stateSelect=if enforceStates then (if 
                useQuaternions then StateSelect.never else StateSelect.always) else 
                StateSelect.avoid) "= der(phi)";
          SI.AngularAcceleration phi_dd[3] "= der(phi_d)";

          // Declarations for animation
          Visualizers.Advanced.Shape cylinder(
            shapeType="cylinder",
            color=cylinderColor,
            specularCoefficient=specularCoefficient,
            length=if Modelica.Math.Vectors.length(r_CM) > sphereDiameter/2 then 
                      Modelica.Math.Vectors.length(r_CM) - (if cylinderDiameter > 1.1*
                sphereDiameter then sphereDiameter/2 else 0) else 0,
            width=cylinderDiameter,
            height=cylinderDiameter,
            lengthDirection=r_CM,
            widthDirection={0,1,0},
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape sphere(
            shapeType="sphere",
            color=sphereColor,
            specularCoefficient=specularCoefficient,
            length=sphereDiameter,
            width=sphereDiameter,
            height=sphereDiameter,
            lengthDirection={1,0,0},
            widthDirection={0,1,0},
            r_shape=r_CM - {1,0,0}*sphereDiameter/2,
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation and sphereDiameter > 0;
        initial equation
          if angles_fixed then
            // Initialize positional variables
            if not Connections.isRoot(frame_a.R) then
              // frame_a.R is computed somewhere else
              zeros(3) = Frames.Orientation.equalityConstraint(frame_a.R, R_start);
            elseif useQuaternions then
              // frame_a.R is computed from quaternions Q
              zeros(3) = Frames.Quaternions.Orientation.equalityConstraint(Q, Q_start);
            else
              // frame_a.R is computed from the 3 angles 'phi'
              phi = phi_start;
            end if;
          end if;

        equation
          if enforceStates then
            Connections.root(frame_a.R);
          else
            Connections.potentialRoot(frame_a.R);
          end if;
          r_0 = frame_a.r_0;

          if not Connections.isRoot(frame_a.R) then
            // Body does not have states
            // Dummies
            Q = {0,0,0,1};
            phi = zeros(3);
            phi_d = zeros(3);
            phi_dd = zeros(3);
          elseif useQuaternions then
            // Use Quaternions as states (with dynamic state selection)
            frame_a.R = Frames.from_Q(Q, Frames.Quaternions.angularVelocity2(Q, der(Q)));
            {0} = Frames.Quaternions.orientationConstraint(Q);

            // Dummies
            phi = zeros(3);
            phi_d = zeros(3);
            phi_dd = zeros(3);
          else
            // Use Cardan angles as states
            phi_d = der(phi);
            phi_dd = der(phi_d);
            frame_a.R = Frames.axesRotations(sequence_angleStates, phi, phi_d);

            // Dummies
            Q = {0,0,0,1};
          end if;

          // gravity acceleration at center of mass resolved in world frame
          g_0 = world.gravityAcceleration(frame_a.r_0 + Frames.resolve1(frame_a.R,
            r_CM));

          // translational kinematic differential equations
          v_0 = der(frame_a.r_0);
          a_0 = der(v_0);

          // rotational kinematic differential equations
          w_a = Frames.angularVelocity2(frame_a.R);
          z_a = der(w_a);

          /* Newton/Euler equations with respect to center of mass
            a_CM = a_a + cross(z_a, r_CM) + cross(w_a, cross(w_a, r_CM));
            f_CM = m*(a_CM - g_a);
            t_CM = I*z_a + cross(w_a, I*w_a);
       frame_a.f = f_CM
       frame_a.t = t_CM + cross(r_CM, f_CM);
    Inserting the first three equations in the last two results in:
  */
          frame_a.f = m*(Frames.resolve2(frame_a.R, a_0 - g_0) + cross(z_a, r_CM) +
            cross(w_a, cross(w_a, r_CM)));
          frame_a.t = I*z_a + cross(w_a, I*w_a) + cross(r_CM, frame_a.f);
        end Body;

        model BodyShape
        "Rigid body with mass, inertia tensor, different shapes for animation, and two frame connectors (12 potential states)"

          import SI = Modelica.SIunits;
          import C = Modelica.Constants;
          import Modelica.Mechanics.MultiBody.Types;

          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the component with one cut-force and cut-torque";

          parameter Boolean animation=true
          "= true, if animation shall be enabled (show shape between frame_a and frame_b and optionally a sphere at the center of mass)";
          parameter Boolean animateSphere=true
          "= true, if mass shall be animated as sphere provided animation=true";
          parameter SI.Position r[3](start={0,0,0})
          "Vector from frame_a to frame_b resolved in frame_a";
          parameter SI.Position r_CM[3](start={0,0,0})
          "Vector from frame_a to center of mass, resolved in frame_a";
          parameter SI.Mass m(min=0, start = 1) "Mass of rigid body";
          parameter SI.Inertia I_11(min=0) = 0.001
          " (1,1) element of inertia tensor";
          parameter SI.Inertia I_22(min=0) = 0.001
          " (2,2) element of inertia tensor";
          parameter SI.Inertia I_33(min=0) = 0.001
          " (3,3) element of inertia tensor";
          parameter SI.Inertia I_21(min=-C.inf) = 0
          " (2,1) element of inertia tensor";
          parameter SI.Inertia I_31(min=-C.inf) = 0
          " (3,1) element of inertia tensor";
          parameter SI.Inertia I_32(min=-C.inf) = 0
          " (3,2) element of inertia tensor";

          SI.Position r_0[3](start={0,0,0}, each stateSelect=if enforceStates then 
                      StateSelect.always else StateSelect.avoid)
          "Position vector from origin of world frame to origin of frame_a";
          SI.Velocity v_0[3](start={0,0,0}, each stateSelect=if enforceStates then StateSelect.always else 
                      StateSelect.avoid)
          "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
          SI.Acceleration a_0[3](start={0,0,0})
          "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";

          parameter Boolean angles_fixed = false
          "= true, if angles_start are used as initial values, else as guess values";
          parameter SI.Angle angles_start[3]={0,0,0}
          "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
          parameter Types.RotationSequence sequence_start={1,2,3}
          "Sequence of rotations to rotate frame_a into frame_b at initial time";

          parameter Boolean w_0_fixed = false
          "= true, if w_0_start are used as initial values, else as guess values";
          parameter SI.AngularVelocity w_0_start[3]={0,0,0}
          "Initial or guess values of angular velocity of frame_a resolved in world frame";

          parameter Boolean z_0_fixed = false
          "= true, if z_0_start are used as initial values, else as guess values";
          parameter SI.AngularAcceleration z_0_start[3]={0,0,0}
          "Initial values of angular acceleration z_0 = der(w_0)";

          parameter Types.ShapeType shapeType="cylinder" " Type of shape";
          parameter SI.Position r_shape[3]={0,0,0}
          " Vector from frame_a to shape origin, resolved in frame_a";
          parameter Types.Axis lengthDirection=r - r_shape
          " Vector in length direction of shape, resolved in frame_a";
          parameter Types.Axis widthDirection={0,1,0}
          " Vector in width direction of shape, resolved in frame_a";
          parameter SI.Length length=Modelica.Math.Vectors.length(
                                                   r - r_shape)
          " Length of shape";
          parameter SI.Distance width=length/world.defaultWidthFraction
          " Width of shape";
          parameter SI.Distance height=width " Height of shape.";
          parameter Types.ShapeExtra extra=0.0
          " Additional parameter depending on shapeType (see docu of Visualizers.Advanced.Shape).";
          input Types.Color color=Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor
          " Color of shape";
          parameter SI.Diameter sphereDiameter=2*width " Diameter of sphere";
          input Types.Color sphereColor=color " Color of sphere of mass";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";
          parameter Boolean enforceStates=false
          " = true, if absolute variables of body object shall be used as states (StateSelect.always)";
          parameter Boolean useQuaternions=true
          " = true, if quaternions shall be used as potential states otherwise use 3 angles as potential states";
          parameter Types.RotationSequence sequence_angleStates={1,2,3}
          " Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";

          FixedTranslation frameTranslation(r=r, animation=false);
          Body body(
            r_CM=r_CM,
            m=m,
            I_11=I_11,
            I_22=I_22,
            I_33=I_33,
            I_21=I_21,
            I_31=I_31,
            I_32=I_32,
            animation=false,
            sequence_start=sequence_start,
            angles_fixed=angles_fixed,
            angles_start=angles_start,
            w_0_fixed=w_0_fixed,
            w_0_start=w_0_start,
            z_0_fixed=z_0_fixed,
            z_0_start=z_0_start,
            useQuaternions=useQuaternions,
            enforceStates=enforceStates,
            sequence_angleStates=sequence_angleStates);
      protected
          outer Modelica.Mechanics.MultiBody.World world;
          Visualizers.Advanced.Shape shape1(
            shapeType=shapeType,
            color=color,
            specularCoefficient=specularCoefficient,
            length=length,
            width=width,
            height=height,
            lengthDirection=lengthDirection,
            widthDirection=widthDirection,
            r_shape=r_shape,
            extra=extra,
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape shape2(
            shapeType="sphere",
            color=sphereColor,
            specularCoefficient=specularCoefficient,
            length=sphereDiameter,
            width=sphereDiameter,
            height=sphereDiameter,
            lengthDirection={1,0,0},
            widthDirection={0,1,0},
            r_shape=r_CM - {1,0,0}*sphereDiameter/2,
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation and animateSphere;
        equation
          r_0 = frame_a.r_0;
          v_0 = der(r_0);
          a_0 = der(v_0);
          connect(frame_a, frameTranslation.frame_a);
          connect(frame_b, frameTranslation.frame_b);
          connect(frame_a, body.frame_a);
        end BodyShape;

        model BodyBox
        "Rigid body with box shape. Mass and animation properties are computed from box data and density (12 potential states)"

          import SI = Modelica.SIunits;
          import Modelica.Mechanics.MultiBody.Types;

          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          parameter Boolean animation=true
          "= true, if animation shall be enabled (show box between frame_a and frame_b)";
          parameter SI.Position r[3](start={0.1,0,0})
          "Vector from frame_a to frame_b resolved in frame_a";
          parameter SI.Position r_shape[3]={0,0,0}
          "Vector from frame_a to box origin, resolved in frame_a";
          parameter Modelica.Mechanics.MultiBody.Types.Axis lengthDirection=r - r_shape
          "Vector in length direction of box, resolved in frame_a";
          parameter Modelica.Mechanics.MultiBody.Types.Axis widthDirection={0,1,0}
          "Vector in width direction of box, resolved in frame_a";
          parameter SI.Length length=Modelica.Math.Vectors.length(
                                                   r - r_shape) "Length of box";
          parameter SI.Distance width=length/world.defaultWidthFraction
          "Width of box";
          parameter SI.Distance height=width "Height of box";
          parameter SI.Distance innerWidth=0
          "Width of inner box surface (0 <= innerWidth <= width)";
          parameter SI.Distance innerHeight=innerWidth
          "Height of inner box surface (0 <= innerHeight <= height)";
          parameter SI.Density density = 7700
          "Density of cylinder (e.g., steel: 7700 .. 7900, wood : 400 .. 800)";
          input Modelica.Mechanics.MultiBody.Types.Color color=Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor
          "Color of box";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";

          SI.Position r_0[3](start={0,0,0}, each stateSelect=if enforceStates then 
                      StateSelect.always else StateSelect.avoid)
          "Position vector from origin of world frame to origin of frame_a";
          SI.Velocity v_0[3](start={0,0,0}, each stateSelect=if enforceStates then StateSelect.always else 
                      StateSelect.avoid)
          "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
          SI.Acceleration a_0[3](start={0,0,0})
          "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";

          parameter Boolean angles_fixed = false
          "= true, if angles_start are used as initial values, else as guess values";
          parameter SI.Angle angles_start[3]={0,0,0}
          "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
          parameter Types.RotationSequence sequence_start={1,2,3}
          "Sequence of rotations to rotate frame_a into frame_b at initial time";

          parameter Boolean w_0_fixed = false
          "= true, if w_0_start are used as initial values, else as guess values";
          parameter SI.AngularVelocity w_0_start[3]={0,0,0}
          "Initial or guess values of angular velocity of frame_a resolved in world frame";

          parameter Boolean z_0_fixed = false
          "= true, if z_0_start are used as initial values, else as guess values";
          parameter SI.AngularAcceleration z_0_start[3]={0,0,0}
          "Initial values of angular acceleration z_0 = der(w_0)";

          parameter Boolean enforceStates=false
          " = true, if absolute variables of body object shall be used as states (StateSelect.always)";
          parameter Boolean useQuaternions=true
          " = true, if quaternions shall be used as potential states otherwise use 3 angles as potential states";
          parameter Types.RotationSequence sequence_angleStates={1,2,3}
          " Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";

          final parameter SI.Mass mo(min=0)=density*length*width*height
          "Mass of box without hole";
          final parameter SI.Mass mi(min=0)=density*length*innerWidth*innerHeight
          "Mass of hole of box";
          final parameter SI.Mass m(min=0)=mo - mi "Mass of box";
          final parameter Frames.Orientation R=Frames.from_nxy(r, widthDirection)
          "Orientation object from frame_a to coordinates system spanned by r and widthDirection";
          final parameter SI.Position r_CM[3]=Modelica.Math.Vectors.normalize(
                                                               r)*length/2
          "Position vector from origin of frame_a to center of mass, resolved in frame_a";
          final parameter SI.Inertia I[3, 3]=Frames.resolveDyade1(R, diagonal({mo*(
              width*width + height*height) - mi*(innerWidth*innerWidth + innerHeight*
              innerHeight),mo*(length*length + height*height) - mi*(length*length +
              innerHeight*innerHeight),mo*(length*length + width*width) - mi*(length*
              length + innerWidth*innerWidth)}/12))
          "Inertia tensor of body box with respect to center of mass, parallel to frame_a";
          Body body(
            animation=false,
            r_CM=r_CM,
            m=m,
            I_11=I[1, 1],
            I_22=I[2, 2],
            I_33=I[3, 3],
            I_21=I[2, 1],
            I_31=I[3, 1],
            I_32=I[3, 2],
            sequence_start=sequence_start,
            angles_fixed=angles_fixed,
            angles_start=angles_start,
            w_0_fixed=w_0_fixed,
            w_0_start=w_0_start,
            z_0_fixed=z_0_fixed,
            z_0_start=z_0_start,
            useQuaternions=useQuaternions,
            enforceStates=enforceStates,
            sequence_angleStates=sequence_angleStates);
          FixedTranslation frameTranslation(
            r=r,
            animation=animation,
            shapeType="box",
            r_shape=r_shape,
            lengthDirection=lengthDirection,
            widthDirection=widthDirection,
            length=length,
            width=width,
            height=height,
            color=color,
           specularCoefficient=specularCoefficient);

      protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          r_0 = frame_a.r_0;
          v_0 = der(r_0);
          a_0 = der(v_0);

          assert(innerWidth <= width,
            "parameter innerWidth is greater as parameter width");
          assert(innerHeight <= height,
            "parameter innerHeight is greater as paraemter height");
          connect(frameTranslation.frame_a, frame_a);
          connect(frameTranslation.frame_b, frame_b);
          connect(frame_a, body.frame_a);
        end BodyBox;

        model BodyCylinder
        "Rigid body with cylinder shape. Mass and animation properties are computed from cylinder data and density (12 potential states)"

          import SI = Modelica.SIunits;
          import NonSI = Modelica.SIunits.Conversions.NonSIunits;
          import Modelica.Mechanics.MultiBody.Types;
          Interfaces.Frame_a frame_a
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b
          "Coordinate system fixed to the component with one cut-force and cut-torque";
          parameter Boolean animation=true
          "= true, if animation shall be enabled (show cylinder between frame_a and frame_b)";
          parameter SI.Position r[3](start={0.1,0,0})
          "Vector from frame_a to frame_b, resolved in frame_a";
          parameter SI.Position r_shape[3]={0,0,0}
          "Vector from frame_a to cylinder origin, resolved in frame_a";
          parameter Modelica.Mechanics.MultiBody.Types.Axis lengthDirection=r - r_shape
          "Vector in length direction of cylinder, resolved in frame_a";
          parameter SI.Length length=Modelica.Math.Vectors.length(
                                                   r - r_shape)
          "Length of cylinder";
          parameter SI.Distance diameter=length/world.defaultWidthFraction
          "Diameter of cylinder";
          parameter SI.Distance innerDiameter=0
          "Inner diameter of cylinder (0 <= innerDiameter <= Diameter)";
          parameter SI.Density density = 7700
          "Density of cylinder (e.g., steel: 7700 .. 7900, wood : 400 .. 800)";
          input Modelica.Mechanics.MultiBody.Types.Color color=Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor
          "Color of cylinder";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";

          SI.Position r_0[3](start={0,0,0}, each stateSelect=if enforceStates then 
                      StateSelect.always else StateSelect.avoid)
          "Position vector from origin of world frame to origin of frame_a";
          SI.Velocity v_0[3](start={0,0,0}, each stateSelect=if enforceStates then StateSelect.always else 
                      StateSelect.avoid)
          "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
          SI.Acceleration a_0[3](start={0,0,0})
          "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";

          parameter Boolean angles_fixed = false
          "= true, if angles_start are used as initial values, else as guess values";
          parameter SI.Angle angles_start[3]={0,0,0}
          "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
          parameter Types.RotationSequence sequence_start={1,2,3}
          "Sequence of rotations to rotate frame_a into frame_b at initial time";

          parameter Boolean w_0_fixed = false
          "= true, if w_0_start are used as initial values, else as guess values";
          parameter SI.AngularVelocity w_0_start[3]={0,0,0}
          "Initial or guess values of angular velocity of frame_a resolved in world frame";

          parameter Boolean z_0_fixed = false
          "= true, if z_0_start are used as initial values, else as guess values";
          parameter SI.AngularAcceleration z_0_start[3]={0,0,0}
          "Initial values of angular acceleration z_0 = der(w_0)";

          parameter Boolean enforceStates=false
          " = true, if absolute variables of body object shall be used as states (StateSelect.always)";
          parameter Boolean useQuaternions=true
          " = true, if quaternions shall be used as potential states otherwise use 3 angles as potential states";
          parameter Types.RotationSequence sequence_angleStates={1,2,3}
          " Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";

          constant Real pi=Modelica.Constants.pi;
          final parameter SI.Distance radius=diameter/2 "Radius of cylinder";
          final parameter SI.Distance innerRadius=innerDiameter/2
          "Inner-Radius of cylinder";
          final parameter SI.Mass mo(min=0)=density*pi*length*radius*radius
          "Mass of cylinder without hole";
          final parameter SI.Mass mi(min=0)=density*pi*length*innerRadius*innerRadius
          "Mass of hole of cylinder";
          final parameter SI.Inertia I22=(mo*(length*length + 3*radius*radius) - mi*(
              length*length + 3*innerRadius*innerRadius))/12
          "Inertia with respect to axis through center of mass, perpendicular to cylinder axis";
          final parameter SI.Mass m(min=0)=mo - mi "Mass of cylinder";
          final parameter Frames.Orientation R=Frames.from_nxy(r, {0,1,0})
          "Orientation object from frame_a to frame spanned by cylinder axis and axis perpendicular to cylinder axis";
          final parameter SI.Position r_CM[3]=Modelica.Math.Vectors.normalize(
                                                               r)*length/2
          "Position vector from frame_a to center of mass, resolved in frame_a";
          final parameter SI.Inertia I[3, 3]=Frames.resolveDyade1(R, diagonal({(mo*
              radius*radius - mi*innerRadius*innerRadius)/2,I22,I22}))
          "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";

          Body body(
            r_CM=r_CM,
            m=m,
            I_11=I[1, 1],
            I_22=I[2, 2],
            I_33=I[3, 3],
            I_21=I[2, 1],
            I_31=I[3, 1],
            I_32=I[3, 2],
            animation=false,
            sequence_start=sequence_start,
            angles_fixed=angles_fixed,
            angles_start=angles_start,
            w_0_fixed=w_0_fixed,
            w_0_start=w_0_start,
            z_0_fixed=z_0_fixed,
            z_0_start=z_0_start,
            useQuaternions=useQuaternions,
            enforceStates=enforceStates,
            sequence_angleStates=sequence_angleStates);
          FixedTranslation frameTranslation(
            r=r,
            animation=animation,
            shapeType="pipecylinder",
            r_shape=r_shape,
            lengthDirection=lengthDirection,
            length=length,
            width=diameter,
            height=diameter,
            extra=innerDiameter/diameter,
            color=color,
            specularCoefficient=specularCoefficient,
            widthDirection={0,1,0});

      protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          r_0 = frame_a.r_0;
          v_0 = der(r_0);
          a_0 = der(v_0);

          assert(innerDiameter < diameter,
            "parameter innerDiameter is greater as parameter diameter.");
          connect(frameTranslation.frame_a, frame_a);
          connect(frameTranslation.frame_b, frame_b);
          connect(frame_a, body.frame_a);
        end BodyCylinder;

        model Mounting1D
        "Propagate 1-dim. support torque to 3-dim. system (provided world.driveTrainMechanics3D=true)"
          parameter Modelica.SIunits.Angle phi0=0
          "Fixed offset angle of housing";
          parameter Modelica.Mechanics.MultiBody.Types.Axis n={1,0,0}
          "Axis of rotation = axis of support torque (resolved in frame_a)";

          Modelica.Mechanics.Rotational.Interfaces.Flange_b flange_b
          "(right) flange fixed in housing";
          Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a if world.driveTrainMechanics3D
          "Frame in which housing is fixed (connector is removed, if world.driveTrainMechanics3D=false)";
      protected
          outer Modelica.Mechanics.MultiBody.World world;

          encapsulated model Housing
            import Modelica;
            input Modelica.SIunits.Torque t[3];
            Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
          equation
            frame_a.f=zeros(3);
            frame_a.t=t;
          end Housing;
          Housing housing(t=-n*flange_b.tau) if world.driveTrainMechanics3D;
        equation
          flange_b.phi = phi0;
          connect(housing.frame_a, frame_a);
        end Mounting1D;
      end Parts;

      package Sensors "Sensors to measure variables"
        extends Modelica.Icons.Library;

        model RelativePosition
        "Measure relative position vector between the origins of two frame connectors"
          extends Internal.PartialRelativeSensor;
          Blocks.Interfaces.RealOutput r_rel[3]
          "Relative position vector resolved in frame defined by resolveInFrame";

          Modelica.Mechanics.MultiBody.Interfaces.Frame_resolve frame_resolve
          if                                                                     resolveInFrame ==
            Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB.frame_resolve
          "Coordinate system in which r_rel is optionally resolved";

          parameter Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB
          resolveInFrame=
          Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB.frame_a
          "Frame in which output vector r_rel shall be resolved (1: world, 2: frame_a, 3: frame_b, 4: frame_resolve)";

      protected
          Internal.BasicRelativePosition relativePosition(resolveInFrame=resolveInFrame);

          Modelica.Mechanics.MultiBody.Interfaces.ZeroPosition zeroPosition if 
            not (resolveInFrame == Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB.frame_resolve);

        equation
          connect(relativePosition.frame_a, frame_a);
          connect(relativePosition.frame_b, frame_b);
          connect(relativePosition.frame_resolve, frame_resolve);
          connect(zeroPosition.frame_resolve, relativePosition.frame_resolve);
          connect(relativePosition.r_rel, r_rel);
        end RelativePosition;

        package Internal "Internal package, should not be used by user"

          partial model PartialRelativeSensor
          "Partial relative sensor model for sensors defined by components"
            extends Modelica.Icons.RotationalSensor;

            Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a
            "Coordinate system a";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b
            "Coordinate system b";

          equation
             assert(cardinality(frame_a) > 0, "Connector frame_a must be connected at least once");
             assert(cardinality(frame_b) > 0, "Connector frame_b must be connected at least once");
          end PartialRelativeSensor;

          model PartialRelativeBaseSensor
          "Partial relative sensor models for sensors defined by equations (frame_resolve must be connected exactly once)"
            extends Modelica.Icons.RotationalSensor;

            Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a
            "Coordinate system a (measurement is between frame_a and frame_b)";
            Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b
            "Coordinate system b (measurement is between frame_a and frame_b)";

            Modelica.Mechanics.MultiBody.Interfaces.Frame_resolve frame_resolve
            "Coordinate system in which vector is optionally resolved";

          equation
             assert(cardinality(frame_a) > 0, "Connector frame_a must be connected at least once");
             assert(cardinality(frame_b) > 0, "Connector frame_b must be connected at least once");
             assert(cardinality(frame_resolve) == 1, "Connector frame_resolve must be connected exactly once");
             frame_a.f = zeros(3);
             frame_a.t = zeros(3);
             frame_b.f = zeros(3);
             frame_b.t = zeros(3);
             frame_resolve.f = zeros(3);
             frame_resolve.t = zeros(3);
          end PartialRelativeBaseSensor;

          model BasicRelativePosition
          "Measure relative position vector (same as Sensors.RelativePosition, but frame_resolve is not conditional and must be connected)"
            import Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB;
            extends
            Modelica.Mechanics.MultiBody.Sensors.Internal.PartialRelativeBaseSensor;
            Modelica.Blocks.Interfaces.RealOutput r_rel[3](each final quantity="Position", each
              final unit =   "m")
            "Relative position vector frame_b.r_0 - frame_a.r_0 resolved in frame defined by resolveInFrame";

            parameter Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB
            resolveInFrame=
            Modelica.Mechanics.MultiBody.Types.ResolveInFrameAB.frame_a
            "Frame in which output vector r_rel is resolved (1: world, 2: frame_a, 3: frame_b, 4: frame_resolve)";

          equation
             if resolveInFrame == ResolveInFrameAB.frame_a then
                r_rel = Frames.resolve2(frame_a.R, frame_b.r_0 - frame_a.r_0);
             elseif resolveInFrame == ResolveInFrameAB.frame_b then
                r_rel = Frames.resolve2(frame_b.R, frame_b.r_0 - frame_a.r_0);
             elseif resolveInFrame == ResolveInFrameAB.world then
                r_rel = frame_b.r_0 - frame_a.r_0;
             elseif resolveInFrame == ResolveInFrameAB.frame_resolve then
                r_rel = Frames.resolve2(frame_resolve.R, frame_b.r_0 - frame_a.r_0);
             else
                assert(false, "Wrong value for parameter resolveInFrame");
                r_rel = zeros(3);
             end if;
          end BasicRelativePosition;
        end Internal;
      end Sensors;

      package Types
      "Constants and types with choices, especially to build menus"
        extends Modelica.Icons.Library;

        type Axis = Modelica.Icons.TypeReal[3](each final unit="1")
        "Axis vector with choices for menus";

        type AxisLabel = Modelica.Icons.TypeString
        "Label of axis with choices for menus";

        type RotationSequence = Modelica.Icons.TypeInteger[3] (min={1,1,1}, max={3,3,3})
        "Sequence of planar frame rotations with choices for menus";

        type Color = Modelica.Icons.TypeInteger[3] (each min=0, each max=255)
        "RGB representation of color (will be improved with a color editor)";

        type SpecularCoefficient = Modelica.Icons.TypeReal
        "Reflection of ambient light (= 0: light is completely absorbed)";

        type ShapeType = Modelica.Icons.TypeString
        "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, dxf-file)";

        type ShapeExtra = Modelica.Icons.TypeReal
        "Reflection of ambient light (= 0: light is completely absorbed)";

        type ResolveInFrameAB = enumeration(
          world "Resolve in world frame",
          frame_a "Resolve in frame_a",
          frame_b "Resolve in frame_b",
          frame_resolve
            "Resolve in frame_resolve (frame_resolve must be connected)")
        "Enumeration to define the frame in which a relative vector is resolved (world, frame_a, frame_b, frame_resolve)";

        type RotationTypes = enumeration(
          RotationAxis "Rotating frame_a around an angle with a fixed axis",
          TwoAxesVectors "Resolve two vectors of frame_b in frame_a",
          PlanarRotationSequence "Planar rotation sequence")
        "Enumeration defining in which way the fixed orientation of frame_b with respect to frame_a is specified";

        type GravityTypes = enumeration(
          NoGravity "No gravity field",
          UniformGravity "Uniform gravity field",
          PointGravity "Point gravity field")
        "Enumeration defining the type of the gravity field";

        package Defaults
        "Default settings of the MultiBody library via constants"
          extends Modelica.Icons.Library;

          constant Types.Color BodyColor={0,128,255}
          "Default color for body shapes that have mass (light blue)";

          constant Types.Color RodColor={155,155,155}
          "Default color for massless rod shapes (grey)";

          constant Types.Color JointColor={255,0,0}
          "Default color for elementary joints (red)";

          constant Types.Color FrameColor={0,0,0}
          "Default color for frame axes and labels (black)";

          constant Real FrameHeadLengthFraction=5.0
          "Frame arrow head length / arrow diameter";

          constant Real FrameHeadWidthFraction=3.0
          "Frame arrow head width / arrow diameter";

          constant Real FrameLabelHeightFraction=3.0
          "Height of frame label / arrow diameter";

          constant Real ArrowHeadLengthFraction=4.0
          "Arrow head length / arrow diameter";

          constant Real ArrowHeadWidthFraction=3.0
          "Arrow head width / arrow diameter";

          constant SI.Diameter BodyCylinderDiameterFraction=3
          "Default for body cylinder diameter as a fraction of body sphere diameter";

          constant Real JointRodDiameterFraction=2
          "Default for rod diameter as a fraction of joint sphere diameter attached to rod";
        end Defaults;
      end Types;

      package Visualizers "3-dimensional visual objects used for animation"
        extends Modelica.Icons.Library;

        model FixedShape
        "Animation shape of a part with fixed shape type and dynamically varying shape definition"
          import SI = Modelica.SIunits;
          import Modelica.Mechanics.MultiBody.Types;
          extends Modelica.Mechanics.MultiBody.Interfaces.PartialVisualizer;

          parameter Boolean animation=true
          "= true, if animation shall be enabled";
          parameter Types.ShapeType shapeType="box" "Type of shape";
          input SI.Position r_shape[3]={0,0,0}
          "Vector from frame_a to shape origin, resolved in frame_a";
          input Types.Axis lengthDirection={1,0,0}
          "Vector in length direction of shape, resolved in frame_a";
          input Types.Axis widthDirection={0,1,0}
          "Vector in width direction of shape, resolved in frame_a";
          input SI.Distance length(start=1) "Length of shape";
          input SI.Distance width(start=0.1) "Width of shape";
          input SI.Distance height(start=0.1) "Height of shape";
          input Modelica.Mechanics.MultiBody.Types.Color color={0,128,255}
          "Color of shape";
          input Types.ShapeExtra extra=0.0
          "Additional data for cylinder, cone, pipe, gearwheel and spring";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";

      protected
          Advanced.Shape vis(
            shapeType=shapeType,
            r_shape=r_shape,
            lengthDirection=lengthDirection,
            widthDirection=widthDirection,
            length=length,
            width=width,
            height=height,
            color=color,
            extra=extra,
            specularCoefficient=specularCoefficient,
            r=frame_a.r_0,
            R=frame_a.R) if world.enableAnimation and animation;
        equation
          // No forces and torques
          frame_a.f = zeros(3);
          frame_a.t = zeros(3);
        end FixedShape;

        model FixedFrame
        "Visualizing a coordinate system including axes labels (visualization data may vary dynamically)"

          import SI = Modelica.SIunits;
          import Modelica.Mechanics.MultiBody.Types;
          extends Modelica.Mechanics.MultiBody.Interfaces.PartialVisualizer;
          parameter Boolean animation=true
          "= true, if animation shall be enabled";
          parameter Boolean showLabels=true "= true, if labels shall be shown";
          input SI.Distance length=0.5 "Length of axes arrows";
          input SI.Distance diameter=length/world.defaultFrameDiameterFraction
          "Diameter of axes arrows";
          input Types.Color color_x=Modelica.Mechanics.MultiBody.Types.Defaults.
              FrameColor "Color of x-arrow";
          input Types.Color color_y=color_x "Color of y-arrow";
          input Types.Color color_z=color_x "Color of z-arrow";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient
          "Reflection of ambient light (= 0: light is completely absorbed)";
      protected
          parameter Boolean animation2 = world.enableAnimation and animation;
          parameter Boolean showLabels2= world.enableAnimation and animation and showLabels;

          // Parameters to define axes
          SI.Length headLength=min(length, diameter*Types.Defaults.FrameHeadLengthFraction);
          SI.Length headWidth=diameter*Types.Defaults.FrameHeadWidthFraction;
          SI.Length lineLength=max(0, length - headLength);
          SI.Length lineWidth=diameter;

          // Parameters to define axes labels
          SI.Length scaledLabel=Modelica.Mechanics.MultiBody.Types.Defaults.FrameLabelHeightFraction*diameter;
          SI.Length labelStart=1.05*length;

          // x-axis
          Visualizers.Advanced.Shape x_arrowLine(
            shapeType="cylinder",
            length=lineLength,
            width=lineWidth,
            height=lineWidth,
            lengthDirection={1,0,0},
            widthDirection={0,1,0},
            color=color_x,
            specularCoefficient=specularCoefficient,
            r=frame_a.r_0,
            R=frame_a.R) if animation2;
          Visualizers.Advanced.Shape x_arrowHead(
            shapeType="cone",
            length=headLength,
            width=headWidth,
            height=headWidth,
            lengthDirection={1,0,0},
            widthDirection={0,1,0},
            color=color_x,
            specularCoefficient=specularCoefficient,
            r=frame_a.r_0 + Frames.resolve1(frame_a.R, {lineLength,0,0}),
            R=frame_a.R) if animation2;
          Visualizers.Internal.Lines x_label(
            lines=scaledLabel*{[0, 0; 1, 1],[0, 1; 1, 0]},
            diameter=diameter,
            color=color_x,
            specularCoefficient=specularCoefficient,
            r_lines={labelStart,0,0},
            n_x={1,0,0},
            n_y={0,1,0},
            r=frame_a.r_0,
            R=frame_a.R) if showLabels2;

          // y-axis
          Visualizers.Advanced.Shape y_arrowLine(
            shapeType="cylinder",
            length=lineLength,
            width=lineWidth,
            height=lineWidth,
            lengthDirection={0,1,0},
            widthDirection={1,0,0},
            color=color_y,
            specularCoefficient=specularCoefficient,
            r=frame_a.r_0,
            R=frame_a.R) if animation2;
          Visualizers.Advanced.Shape y_arrowHead(
            shapeType="cone",
            length=headLength,
            width=headWidth,
            height=headWidth,
            lengthDirection={0,1,0},
            widthDirection={1,0,0},
            color=color_y,
            specularCoefficient=specularCoefficient,
            r=frame_a.r_0 + Frames.resolve1(frame_a.R, {0,lineLength,0}),
            R=frame_a.R) if animation2;
          Visualizers.Internal.Lines y_label(
            lines=scaledLabel*{[0, 0; 1, 1.5],[0, 1.5; 0.5, 0.75]},
            diameter=diameter,
            color=color_y,
            specularCoefficient=specularCoefficient,
            r_lines={0,labelStart,0},
            n_x={0,1,0},
            n_y={-1,0,0},
            r=frame_a.r_0,
            R=frame_a.R) if showLabels2;

          // z-axis
          Visualizers.Advanced.Shape z_arrowLine(
            shapeType="cylinder",
            length=lineLength,
            width=lineWidth,
            height=lineWidth,
            lengthDirection={0,0,1},
            widthDirection={0,1,0},
            color=color_z,
            specularCoefficient=specularCoefficient,
            r=frame_a.r_0,
            R=frame_a.R) if animation2;
          Visualizers.Advanced.Shape z_arrowHead(
            shapeType="cone",
            length=headLength,
            width=headWidth,
            height=headWidth,
            lengthDirection={0,0,1},
            widthDirection={0,1,0},
            color=color_z,
            specularCoefficient=specularCoefficient,
            r=frame_a.r_0 + Frames.resolve1(frame_a.R, {0,0,lineLength}),
            R=frame_a.R) if animation2;
          Visualizers.Internal.Lines z_label(
            lines=scaledLabel*{[0, 0; 1, 0],[0, 1; 1, 1],[0, 1; 1, 0]},
            diameter=diameter,
            color=color_z,
            specularCoefficient=specularCoefficient,
            r_lines={0,0,labelStart},
            n_x={0,0,1},
            n_y={0,1,0},
            r=frame_a.r_0,
            R=frame_a.R) if showLabels2;
        equation
          frame_a.f = zeros(3);
          frame_a.t = zeros(3);

        end FixedFrame;

        package Advanced
        "Visualizers that require basic knowledge about Modelica in order to use them"
          extends Modelica.Icons.Library;

          model Shape
          "Different visual shapes with variable size; all data have to be set as modifiers (see info layer)"

             extends
            Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialShape;
             extends ModelicaServices.Animation.Shape;

          end Shape;
        end Advanced;

        package Internal
        "Visualizers that will be replaced by improved versions in the future (don't use them)"
          extends Modelica.Icons.Library;

          model Lines
          "Visualizing a set of lines as cylinders with variable size, e.g., used to display characters (no Frame connector)"

            import SI = Modelica.SIunits;
            import Modelica.Mechanics.MultiBody;
            import Modelica.Mechanics.MultiBody.Types;
            import Modelica.Mechanics.MultiBody.Frames;
            import T =
            Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
            input Modelica.Mechanics.MultiBody.Frames.Orientation R=Frames.nullRotation()
            "Orientation object to rotate the world frame into the object frame";
            input SI.Position r[3]={0,0,0}
            "Position vector from origin of world frame to origin of object frame, resolved in world frame";
            input SI.Position r_lines[3]={0,0,0}
            "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
            input Real n_x[3](each final unit="1")={1,0,0}
            "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
            input Real n_y[3](each final unit="1")={0,1,0}
            "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
            input SI.Position lines[:, 2, 2]=zeros(0, 2, 2)
            "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
            input SI.Length diameter(min=0) = 0.05
            "Diameter of the cylinders defined by lines";
            input Modelica.Mechanics.MultiBody.Types.Color color={0,128,255}
            "Color of cylinders";
            input Types.SpecularCoefficient specularCoefficient = 0.7
            "Reflection of ambient light (= 0: light is completely absorbed)";
        protected
            parameter Integer n=size(lines, 1) "Number of cylinders";
            T.Orientation R_rel=T.from_nxy(n_x, n_y);
            T.Orientation R_lines=T.absoluteRotation(R.T, R_rel);
            Modelica.SIunits.Position r_abs[3]=r + T.resolve1(R.T, r_lines);
            Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape cylinders[n](
              each shapeType="cylinder",
              lengthDirection={T.resolve1(R_rel, vector([lines[i, 2, :] - lines[i, 1,
                   :]; 0])) for i in 1:n},
              length={Modelica.Math.Vectors.length(
                                              lines[i, 2, :] - lines[i, 1, :]) for i in 
                      1:n},
              r={r_abs + T.resolve1(R_lines, vector([lines[i, 1, :]; 0])) for i in 1:
                  n},
              each width=diameter,
              each height=diameter,
              each widthDirection={0,1,0},
              each color=color,
              each R=R,
              each specularCoefficient=specularCoefficient);

          end Lines;
        end Internal;
      end Visualizers;
    end MultiBody;

    package Rotational
    "Library to model 1-dimensional, rotational mechanical systems"
      extends Modelica.Icons.Library2;
      import SI = Modelica.SIunits;

      package Components "Components for 1D rotational mechanical drive trains"
        extends Modelica.Icons.Library2;

        model Fixed "Flange fixed in housing at a given angle"
          parameter SI.Angle phi0=0 "Fixed offset angle of housing";

          Interfaces.Flange_b flange "(right) flange fixed in housing";

        equation
          flange.phi = phi0;
        end Fixed;

        model Inertia "1D-rotational component with inertia"
          import SI = Modelica.SIunits;
          Rotational.Interfaces.Flange_a flange_a "Left flange of shaft";
          Rotational.Interfaces.Flange_b flange_b "Right flange of shaft";
          parameter SI.Inertia J(min=0, start=1) "Moment of inertia";
          parameter StateSelect stateSelect=StateSelect.default
          "Priority to use phi and w as states";
          SI.Angle phi(stateSelect=stateSelect)
          "Absolute rotation angle of component";
          SI.AngularVelocity w(stateSelect=stateSelect)
          "Absolute angular velocity of component (= der(phi))";
          SI.AngularAcceleration a
          "Absolute angular acceleration of component (= der(w))";


        equation
          phi = flange_a.phi;
          phi = flange_b.phi;
          w = der(phi);
          a = der(w);
          J*a = flange_a.tau + flange_b.tau;
        end Inertia;
      end Components;

      package Sources "Sources to drive 1D rotational mechanical components"
        extends Modelica.Icons.Library2;

        model Position
        "Forced movement of a flange according to a reference angle signal"
          import SI = Modelica.SIunits;
          extends
          Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport2;
          parameter Boolean exact=false
          "true/false exact treatment/filtering the input signal";
          parameter SI.Frequency f_crit=50
          "if exact=false, critical frequency of filter to filter input signal";
          SI.Angle phi(stateSelect=if exact then StateSelect.default else StateSelect.prefer)
          "Rotation angle of flange with respect to support";
          SI.AngularVelocity w(start=0,stateSelect=if exact then StateSelect.default else StateSelect.prefer)
          "If exact=false, Angular velocity of flange with respect to support else dummy";
          SI.AngularAcceleration a(start=0)
          "If exact=false, Angular acceleration of flange with respect to support else dummy";
          Modelica.Blocks.Interfaces.RealInput phi_ref(final quantity="Angle", final unit
            =                                                                             "rad", displayUnit="deg")
          "Reference angle of flange with respect to support as input signal";

      protected
          parameter Modelica.SIunits.AngularFrequency w_crit=2*Modelica.Constants.pi*f_crit
          "Critical frequency";
          constant Real af=1.3617 "s coefficient of Bessel filter";
          constant Real bf=0.6180 "s*s coefficient of Bessel filter";
        initial equation
          if not exact then
            phi = phi_ref;
          end if;
        equation
          phi = flange.phi - phi_support;
          if exact then
            phi = phi_ref;
            w = 0;
            a = 0;
          else
            // Filter: a = phi_ref*s^2/(1 + (af/w_crit)*s + (bf/w_crit^2)*s^2)
            w = der(phi);
            a = der(w);
            a = ((phi_ref - phi)*w_crit - af*w)*(w_crit/bf);
          end if;
        end Position;

        model QuadraticSpeedDependentTorque
        "Quadratic dependency of torque versus speed"
          extends Modelica.Mechanics.Rotational.Interfaces.PartialTorque;
          parameter Modelica.SIunits.Torque tau_nominal
          "Nominal torque (if negative, torque is acting as load)";
          parameter Boolean TorqueDirection=true
          "Same direction of torque in both directions of rotation";
          parameter Modelica.SIunits.AngularVelocity w_nominal(min=Modelica.Constants.eps)
          "Nominal speed";
          Modelica.SIunits.AngularVelocity w
          "Angular velocity of flange with respect to support (= der(phi))";
          Modelica.SIunits.Torque tau
          "Accelerating torque acting at flange (= -flange.tau)";
        equation
          w = der(phi);
          tau = -flange.tau;
          if TorqueDirection then
            tau = tau_nominal*(w/w_nominal)^2;
          else
            tau = tau_nominal*smooth(1,if w >= 0 then (w/w_nominal)^2 else -(w/w_nominal)^2);
          end if;
        end QuadraticSpeedDependentTorque;

        model ConstantTorque "Constant torque, not dependent on speed"
          extends Rotational.Interfaces.PartialTorque;
          parameter Modelica.SIunits.Torque tau_constant
          "Constant torque (if negative, torque is acting as load)";
          Modelica.SIunits.Torque tau
          "Accelerating torque acting at flange (= -flange.tau)";
        equation
          tau = -flange.tau;
          tau = tau_constant;
        end ConstantTorque;
      end Sources;

      package Sensors
      "Sensors to measure variables in 1D rotational mechanical components"
        extends Modelica.Icons.Library2;

        model TorqueSensor
        "Ideal sensor to measure the torque between two flanges (= flange_a.tau)"

          extends Rotational.Interfaces.PartialRelativeSensor;
          Modelica.Blocks.Interfaces.RealOutput tau
          "Torque in flange flange_a and flange_b (tau = flange_a.tau = -flange_b.tau)";

        equation
          flange_a.phi = flange_b.phi;
          flange_a.tau = tau;
        end TorqueSensor;
      end Sensors;

      package Interfaces
      "Connectors and partial models for 1D rotational mechanical components"
        extends Modelica.Icons.Library;

        connector Flange_a
        "1-dim. rotational flange of a shaft (filled square icon)"
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
        end Flange_a;

        connector Flange_b
        "1-dim. rotational flange of a shaft (non-filled square icon)"
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
        end Flange_b;

        connector Support "Support/housing of a 1-dim. rotational shaft"

          SI.Angle phi "Absolute rotation angle of the support/housing";
          flow SI.Torque tau "Reaction torque in the support/housing";

        end Support;

        model InternalSupport
        "Adapter model to utilize conditional support connector"
          input Modelica.SIunits.Torque tau
          "External support torque (must be computed via torque balance in model where InternalSupport is used; = flange.tau)";
          Modelica.SIunits.Angle phi "External support angle (= flange.phi)";
          Flange_a flange
          "Internal support flange (must be connected to the conditional support connector for useSupport=true and to conditional fixed model for useSupport=false)";
        equation
          flange.tau = tau;
          flange.phi = phi;
        end InternalSupport;

        partial model PartialElementaryOneFlangeAndSupport2
        "Partial model for a component with one rotational 1-dim. shaft flange and a support used for textual modeling, i.e., for elementary models"
          parameter Boolean useSupport=false
          "= true, if support flange enabled, otherwise implicitly grounded";
          Flange_b flange "Flange of shaft";
          Support support(phi = phi_support, tau = -flange.tau) if useSupport
          "Support/housing of component";
      protected
          Modelica.SIunits.Angle phi_support "Absolute angle of support flange";
        equation
          if not useSupport then
             phi_support = 0;
          end if;
        end PartialElementaryOneFlangeAndSupport2;

        partial model PartialTorque
        "Partial model of a torque acting at the flange (accelerates the flange)"
          extends
          Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport2;
          Modelica.SIunits.Angle phi
          "Angle of flange with respect to support (= flange.phi - support.phi)";

        equation
          phi = flange.phi - phi_support;
        end PartialTorque;

        partial model PartialRelativeSensor
        "Partial model to measure a single relative variable between two flanges"

          Flange_a flange_a "Left flange of shaft";
          Flange_b flange_b "Right flange of shaft";

        equation
          0 = flange_a.tau + flange_b.tau;
        end PartialRelativeSensor;
      end Interfaces;
    end Rotational;

    package Translational
    "Library to model 1-dimensional, translational mechanical systems"
      extends Modelica.Icons.Library2;
      import SI = Modelica.SIunits;

      package Components
      "Components for 1D translational mechanical drive trains"
        extends Modelica.Icons.Library2;

        model Fixed "Fixed flange"
          parameter SI.Position s0=0 "fixed offset position of housing";


          Interfaces.Flange_b flange;
        equation
          flange.s = s0;
        end Fixed;
      end Components;

      package Sources "Sources to drive 1D translational mechanical components"
        extends Modelica.Icons.Library2;

        model ConstantForce "Constant force, not dependent on speed"
          extends Modelica.Mechanics.Translational.Interfaces.PartialForce;
          parameter Modelica.SIunits.Force f_constant
          "Nominal force (if negative, force is acting as load)";
        equation
          f = -f_constant;
        end ConstantForce;
      end Sources;

      package Interfaces
      "Interfaces for 1-dim. translational mechanical components"
          extends Modelica.Icons.Library;

        connector Flange_a
        "(left) 1D translational flange (flange axis directed INTO cut plane, e. g. from left to right)"


          SI.Position s "absolute position of flange";
          flow SI.Force f "cut force directed into flange";
        end Flange_a;

        connector Flange_b
        "right 1D translational flange (flange axis directed OUT OF cut plane)"

          SI.Position s "absolute position of flange";
          flow SI.Force f "cut force directed into flange";
        end Flange_b;

        connector Support "Support/housing 1D translational flange"

          SI.Position s "absolute position of flange";
          flow SI.Force f "cut force directed into flange";
        end Support;

        model InternalSupport
        "Adapter model to utilize conditional support connector"
          input SI.Force f
          "External support force (must be computed via force balance in model where InternalSupport is used; = flange.f)";
          SI.Position s "External support position (= flange.s)";
          Flange_a flange
          "Internal support flange (must be connected to the conditional support connector for useSupport=true and to conditional fixed model for useSupport=false)";
        equation
          flange.f = f;
          flange.s = s;
        end InternalSupport;

        partial model PartialCompliant
        "Compliant connection of two translational 1D flanges"

          Flange_a flange_a
          "Left flange of compliant 1-dim. translational component";
          Flange_b flange_b
          "Right flange of compliant 1-dim. translational component";
          SI.Distance s_rel(start=0)
          "relative distance (= flange_b.s - flange_a.s)";
          SI.Force f
          "force between flanges (positive in direction of flange axis R)";

        equation
          s_rel = flange_b.s - flange_a.s;
          flange_b.f = f;
          flange_a.f = -f;
        end PartialCompliant;

        partial model PartialElementaryOneFlangeAndSupport2
        "Partial model for a component with one translational 1-dim. shaft flange and a support used for textual modeling, i.e., for elementary models"
          parameter Boolean useSupport=false
          "= true, if support flange enabled, otherwise implicitly grounded";
          Modelica.SIunits.Length s = flange.s - s_support
          "distance between flange and support (= flange.s - support.s)";
          Flange_b flange "Flange of component";
          Support support(s=s_support, f=-flange.f) if useSupport
          "Support/housing of component";
      protected
          Modelica.SIunits.Length s_support
          "Absolute position of support flange";
        equation
          if not useSupport then
             s_support = 0;
          end if;

        end PartialElementaryOneFlangeAndSupport2;

      partial model PartialForce
        "Partial model of a force acting at the flange (accelerates the flange)"
        extends PartialElementaryOneFlangeAndSupport2;
        Modelica.SIunits.Force f = flange.f
          "Accelerating force acting at flange (= flange.f)";
      end PartialForce;
      end Interfaces;
    end Translational;
  end Mechanics;

  package Math
  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;

  package Vectors "Library of functions operating on vectors"
    extends Modelica.Icons.Library;

    function length
    "Return length of a vectorReturn length of a vector (better as norm(), if further symbolic processing is performed)"
      extends Modelica.Icons.Function;
      input Real v[:] "Vector";
      output Real result "Length of vector v";
    algorithm
      result := sqrt(v*v);
    end length;

    function normalize
    "Return normalized vector such that length = 1Return normalized vector such that length = 1 and prevent zero-division for zero vector"
      extends Modelica.Icons.Function;
      input Real v[:] "Vector";
      input Real eps = 100*Modelica.Constants.eps
      "if |v| < eps then result = v/eps";
      output Real result[size(v, 1)] "Input vector v normalized to length=1";

    algorithm
      result := smooth(0,if length(v) >= eps then v/length(v) else v/eps);
    end normalize;
  end Vectors;

  function sin "Sine"
    extends baseIcon1;
    input SI.Angle u;
    output Real y;


  external "C" y=  sin(u);
  end sin;

  function cos "Cosine"
    extends baseIcon1;
    input SI.Angle u;
    output Real y;


  external "C" y=  cos(u);
  end cos;

  function asin "Inverse sine (-1 <= u <= 1)"
    extends baseIcon2;
    input Real u;
    output SI.Angle y;


  external "C" y=  asin(u);
  end asin;

  function atan2 "Four quadrant inverse tangent"
    extends baseIcon2;
    input Real u1;
    input Real u2;
    output SI.Angle y;


  external "C" y=  atan2(u1, u2);
  end atan2;

  partial function baseIcon1
    "Basic icon for mathematical function with y-axis on left side"

  end baseIcon1;

  partial function baseIcon2
    "Basic icon for mathematical function with y-axis in middle"

  end baseIcon2;
  end Math;

  package Utilities
  "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)"
    extends Modelica.Icons.Library;

    package Internal
    "Internal components that a user should usually not directly utilize"

    partial package PartialModelicaServices
      "Interfaces of components requiring a tool specific implementation"
      package Animation "Models and functions for 3-dim. animation"

      partial model PartialShape
          "Different visual shapes with variable size; all data have to be set as modifiers"

        import SI = Modelica.SIunits;
        import Modelica.Mechanics.MultiBody.Frames;
        import Modelica.Mechanics.MultiBody.Types;

        parameter Types.ShapeType shapeType="box"
            "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring)";
        input Frames.Orientation R=Frames.nullRotation()
            "Orientation object to rotate the world frame into the object frame";
        input SI.Position r[3]={0,0,0}
            "Position vector from origin of world frame to origin of object frame, resolved in world frame";
        input SI.Position r_shape[3]={0,0,0}
            "Position vector from origin of object frame to shape origin, resolved in object frame";
        input Real lengthDirection[3](each final unit="1")={1,0,0}
            "Vector in length direction, resolved in object frame";
        input Real widthDirection[3](each final unit="1")={0,1,0}
            "Vector in width direction, resolved in object frame";
        input SI.Length length=0 "Length of visual object";
        input SI.Length width=0 "Width of visual object";
        input SI.Length height=0 "Height of visual object";
        input Types.ShapeExtra extra=0.0
            "Additional size data for some of the shape types";
        input Real color[3]={255,0,0} "Color of shape";
        input Types.SpecularCoefficient specularCoefficient = 0.7
            "Reflection of ambient light (= 0: light is completely absorbed)";
        // Real rxry[3, 2];

      end PartialShape;
      end Animation;

    end PartialModelicaServices;
    end Internal;
  end Utilities;

  package Constants
  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Library2;

    final constant Real pi=2*Modelica.Math.asin(1.0);

    final constant Real eps=1.e-15 "Biggest number such that 1.0 + eps = 1.0";

    final constant Real inf=1.e+60
    "Biggest Real number such that inf and -inf are representable on the machine";

    final constant Real R(final unit="J/(mol.K)") = 8.314472
    "Molar gas constant";
  end Constants;

  package Icons "Library of icons"

    partial package Library "Icon for library"

    end Library;

    partial package Library2
    "Icon for library where additional icon elements shall be added"

    end Library2;

    partial model Example "Icon for an example model"

    equation

    end Example;

    partial function Function "Icon for a function"

    end Function;

    partial record Record "Icon for a record"

    end Record;

    type TypeReal "Icon for a Real type"
        extends Real;
    end TypeReal;

    type TypeInteger "Icon for an Integer type"
        extends Integer;
    end TypeInteger;

    type TypeString "Icon for a String type"
        extends String;
    end TypeString;

    partial model RotationalSensor
    "Icon representing rotational measurement device"

    equation

    end RotationalSensor;
  end Icons;

  package SIunits
  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;

    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Library2;

      package NonSIunits "Type definitions of non SI units"
        extends Modelica.Icons.Library2;

        type Angle_deg = Real (final quantity="Angle", final unit="deg")
        "Angle in degree";

        type AngularVelocity_rpm = Real (final quantity="AngularVelocity", final unit
            =      "1/min")
        "Angular velocity in revolutions per minute. Alias unit names that are outside of the SI system: rpm, r/min, rev/min";

        type Pressure_bar = Real (final quantity="Pressure", final unit="bar")
        "Absolute pressure in bar";
      end NonSIunits;

      function from_deg "Convert from degree to radian"
        extends ConversionIcon;
        input NonSIunits.Angle_deg degree "degree value";
        output Angle radian "radian value";
      algorithm
        radian := (Modelica.Constants.pi/180.0)*degree;
      end from_deg;

      function to_rpm
      "Convert from radian per second to revolutions per minute"
        extends ConversionIcon;
        input AngularVelocity rs "radian per second value";
        output NonSIunits.AngularVelocity_rpm rpm
        "revolutions per minute value";
      algorithm
        rpm := (30/Modelica.Constants.pi)*rs;
      end to_rpm;

      partial function ConversionIcon "Base icon for conversion functions"
      end ConversionIcon;
    end Conversions;

    type Angle = Real (
        final quantity="Angle",
        final unit="rad",
        displayUnit="deg");

    type Length = Real (final quantity="Length", final unit="m");

    type Position = Length;

    type Distance = Length (min=0);

    type Diameter = Length(min=0);

    type Volume = Real (final quantity="Volume", final unit="m3");

    type Time = Real (final quantity="Time", final unit="s");

    type AngularVelocity = Real (
        final quantity="AngularVelocity",
        final unit="rad/s");

    type AngularAcceleration = Real (final quantity="AngularAcceleration", final unit
        =      "rad/s2");

    type Velocity = Real (final quantity="Velocity", final unit="m/s");

    type Acceleration = Real (final quantity="Acceleration", final unit="m/s2");

    type Frequency = Real (final quantity="Frequency", final unit="Hz");

    type AngularFrequency = Real (final quantity="AngularFrequency", final unit
        =   "rad/s");

    type Mass = Real (
        quantity="Mass",
        final unit="kg",
        min=0);

    type Density = Real (
        final quantity="Density",
        final unit="kg/m3",
        displayUnit="g/cm3",
        min=0);

    type MomentOfInertia = Real (final quantity="MomentOfInertia", final unit=
            "kg.m2");

    type Inertia = MomentOfInertia;

    type Force = Real (final quantity="Force", final unit="N");

    type Torque = Real (final quantity="Torque", final unit="N.m");

    type Pressure = Real (
        final quantity="Pressure",
        final unit="Pa",
        displayUnit="bar");

    type AbsolutePressure = Pressure (min=0);

    type Power = Real (final quantity="Power", final unit="W");

    type ThermodynamicTemperature = Real (
        final quantity="ThermodynamicTemperature",
        final unit="K",
        min = 0,
        displayUnit="degC")
    "Absolute temperature (use type TemperatureDifference for relative temperatures)";

    type Temperature = ThermodynamicTemperature;

    type HeatCapacity = Real (final quantity="HeatCapacity", final unit="J/K");

    type SpecificHeatCapacity = Real (final quantity="SpecificHeatCapacity",
          final unit="J/(kg.K)");
  end SIunits;
end Modelica;

model BigEngineModel  
  Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6 ev6[100];
  Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic ev6analytic[100];
  
  Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6 ev6_[100];
  Modelica.Mechanics.MultiBody.Examples.Loops.EngineV6_analytic ev6analytic_[100];
end BigEngineModel;

package Modelica_Mechanics_MultiBody_Examples_Loops
 extends Modelica.Mechanics.MultiBody.Examples.Loops;
  annotation(experiment(
    StopTime=1,
    NumberOfIntervals=500,
    Tolerance=0.0001,
    Algorithm="dassl"),uses(Modelica(version="3.1")));
end Modelica_Mechanics_MultiBody_Examples_Loops;

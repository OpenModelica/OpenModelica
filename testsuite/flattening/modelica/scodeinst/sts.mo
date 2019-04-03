package ScalableTestSuite  "A library of scalable Modelica test models" 
  package Mechanical  "Models from the mechanical domain" 
    package FlexibleBeam  "Models of flexible beams" 
      package Models  
        model FlexibleBeamModelica  "Cantilever beam implementation by the Modelica Standard Library" 
          import Modelica.SIunits;
          inner Modelica.Mechanics.MultiBody.World world(gravityType = Modelica.Mechanics.MultiBody.Types.GravityTypes.NoGravity);
          parameter Integer N = 1 "number of elements";
          parameter SIunits.Length L "length of the beam";
          final parameter SIunits.Length l = L / N "length of the each BodyBox";
          parameter SIunits.Length W "width of the beam";
          parameter SIunits.Height H "height of the beam";
          parameter SIunits.Density D "density of the material";
          parameter SIunits.ModulusOfElasticity E "young's modulus of the material";
          final parameter SIunits.SecondMomentOfArea J = W * H ^ 3 / 12 "area moment of inertia";
          parameter SIunits.RotationalDampingConstant DampCoeff "damping coefficient";
          final parameter SIunits.RotationalSpringConstant SpringCoeff = E * J / l "spring coefficient";
          parameter SIunits.PerUnit F "force component at y-axis";
          Modelica.Mechanics.MultiBody.Joints.Revolute[N] revolute(each useAxisFlange = true, phi(each fixed = true), w(each fixed = true)) "N revolute joint";
          Modelica.Mechanics.Rotational.Components.SpringDamper[N] springdamper(each c = SpringCoeff, each d = DampCoeff) "N spring damper to connect to N revolute";
          Modelica.Mechanics.MultiBody.Parts.BodyBox bodybox1(length = l / 2, width = W, height = H, r = {l / 2, 0, 0}, density = D) "first bodybox connected to world";
          Modelica.Mechanics.MultiBody.Parts.BodyBox bodyboxN(length = l / 2, width = W, height = H, r = {l / 2, 0, 0}, density = D) "last bodybox which is free end";
          Modelica.Mechanics.MultiBody.Parts.BodyBox[N - 1] bodybox(each length = l, each width = W, each height = H, each r = {l, 0, 0}, each density = D) "discretization of the element";
          Modelica.Mechanics.MultiBody.Forces.WorldForce force(resolveInFrame = Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.world) "force component";
        equation
          force.force = if time < 0.001 then {0, 0, 0} else if time < 0.002 then {0, F, 0} else {0, 0, 0};
          connect(world.frame_b, bodybox1.frame_a);
          connect(bodybox1.frame_b, revolute[1].frame_a);
          for i in 1:N loop
            connect(revolute[i].axis, springdamper[i].flange_b);
            connect(revolute[i].support, springdamper[i].flange_a);
          end for;
          for i in 1:N - 1 loop
            connect(revolute[i].frame_b, bodybox[i].frame_a);
            connect(bodybox[i].frame_b, revolute[i + 1].frame_a);
          end for;
          connect(revolute[N].frame_b, bodyboxN.frame_a);
          connect(bodyboxN.frame_b, force.frame_b);
        end FlexibleBeamModelica;
      end Models;

      package ScaledExperiments  
        extends Modelica.Icons.ExamplesPackage;

        model FlexibleBeamModelica_N_2  
          extends Models.FlexibleBeamModelica(N = 2, L = 0.5, W = 0.05, H = 0.02, D = 2700, E = 6.9e10, DampCoeff = 0.00001, F = -100);
          annotation(experiment(StopTime = 0.15, Tolerance = 1e-6)); 
        end FlexibleBeamModelica_N_2;
      end ScaledExperiments;
    end FlexibleBeam;
  end Mechanical;
  annotation(version = "1.9.3"); 
end ScalableTestSuite;

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation" 
  extends Modelica.Icons.Package;

  package Animation  "Models and functions for 3-dim. animation" 
    extends Modelica.Icons.Package;

    model Shape  "Different visual shapes with variable size; all data have to be set as modifiers (see info layer)" 
      extends Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialShape;
    end Shape;
  end Animation;

  package Machine  
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1.e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1.e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
  end Machine;
  annotation(Protection(access = Access.hide), version = "3.2.2", versionBuild = 0, versionDate = "2016-01-15", dateModified = "2016-01-15 08:44:41Z"); 
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.2" 
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)" 
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks" 
      import Modelica.SIunits;
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector";
    end Interfaces;

    package Icons  "Icons for Blocks" 
      extends Modelica.Icons.IconsPackage;

      partial block Block  "Basic graphical layout of input/output block" end Block;
    end Icons;
  end Blocks;

  package Mechanics  "Library of 1-dim. and 3-dim. mechanical components (multi-body, rotational, translational)" 
    extends Modelica.Icons.Package;

    package MultiBody  "Library to model 3-dimensional mechanical systems" 
      extends Modelica.Icons.Package;
      import SI = Modelica.SIunits;
      import Cv = Modelica.SIunits.Conversions;
      import C = Modelica.Constants;

      model World  "World coordinate system + gravity field + default animation definition" 
        import Modelica.Mechanics.MultiBody.Types.GravityTypes;
        import Modelica.Mechanics.MultiBody.Types;
        Interfaces.Frame_b frame_b "Coordinate system fixed in the origin of the world frame";
        parameter Boolean enableAnimation = true "= true, if animation of all components is enabled";
        parameter Boolean animateWorld = true "= true, if world coordinate system shall be visualized";
        parameter Boolean animateGravity = true "= true, if gravity field shall be visualized (acceleration vector or field center)";
        parameter Types.AxisLabel label1 = "x" "Label of horizontal axis in icon";
        parameter Types.AxisLabel label2 = "y" "Label of vertical axis in icon";
        parameter Types.GravityTypes gravityType = GravityTypes.UniformGravity "Type of gravity field" annotation(Evaluate = true);
        parameter SI.Acceleration g = 9.81 "Constant gravity acceleration";
        parameter Types.Axis n = {0, -1, 0} "Direction of gravity resolved in world frame (gravity = g*n/length(n))" annotation(Evaluate = true);
        parameter Real mue(unit = "m3/s2", min = 0) = 3.986e14 "Gravity field constant (default = field constant of earth)";
        parameter Boolean driveTrainMechanics3D = true "= true, if 3-dim. mechanical effects of Parts.Mounting1D/Rotor1D/BevelGear1D shall be taken into account";
        parameter SI.Distance axisLength = nominalLength / 2 "Length of world axes arrows";
        parameter SI.Distance axisDiameter = axisLength / defaultFrameDiameterFraction "Diameter of world axes arrows";
        parameter Boolean axisShowLabels = true "= true, if labels shall be shown";
        input Types.Color axisColor_x = Modelica.Mechanics.MultiBody.Types.Defaults.FrameColor "Color of x-arrow";
        input Types.Color axisColor_y = axisColor_x;
        input Types.Color axisColor_z = axisColor_x "Color of z-arrow";
        parameter SI.Position[3] gravityArrowTail = {0, 0, 0} "Position vector from origin of world frame to arrow tail, resolved in world frame";
        parameter SI.Length gravityArrowLength = axisLength / 2 "Length of gravity arrow";
        parameter SI.Diameter gravityArrowDiameter = gravityArrowLength / defaultWidthFraction "Diameter of gravity arrow";
        input Types.Color gravityArrowColor = {0, 230, 0} "Color of gravity arrow";
        parameter SI.Diameter gravitySphereDiameter = 12742000 "Diameter of sphere representing gravity center (default = mean diameter of earth)";
        input Types.Color gravitySphereColor = {0, 230, 0} "Color of gravity sphere";
        parameter SI.Length nominalLength = 1 "\"Nominal\" length of multi-body system";
        parameter SI.Length defaultAxisLength = nominalLength / 5 "Default for length of a frame axis (but not world frame)";
        parameter SI.Length defaultJointLength = nominalLength / 10 "Default for the fixed length of a shape representing a joint";
        parameter SI.Length defaultJointWidth = nominalLength / 20 "Default for the fixed width of a shape representing a joint";
        parameter SI.Length defaultForceLength = nominalLength / 10 "Default for the fixed length of a shape representing a force (e.g., damper)";
        parameter SI.Length defaultForceWidth = nominalLength / 20 "Default for the fixed width of a shape representing a force (e.g., spring, bushing)";
        parameter SI.Length defaultBodyDiameter = nominalLength / 9 "Default for diameter of sphere representing the center of mass of a body";
        parameter Real defaultWidthFraction = 20 "Default for shape width as a fraction of shape length (e.g., for Parts.FixedTranslation)";
        parameter SI.Length defaultArrowDiameter = nominalLength / 40 "Default for arrow diameter (e.g., of forces, torques, sensors)";
        parameter Real defaultFrameDiameterFraction = 40 "Default for arrow diameter of a coordinate system as a fraction of axis length";
        parameter Real defaultSpecularCoefficient(min = 0) = 0.7 "Default reflection of ambient light (= 0: light is completely absorbed)";
        parameter Real defaultN_to_m(unit = "N/m", min = 0) = 1000 "Default scaling of force arrows (length = force/defaultN_to_m)";
        parameter Real defaultNm_to_m(unit = "N.m/m", min = 0) = 1000 "Default scaling of torque arrows (length = torque/defaultNm_to_m)";
        replaceable function gravityAcceleration = Modelica.Mechanics.MultiBody.Forces.Internal.standardGravityAcceleration(gravityType = gravityType, g = g * Modelica.Math.Vectors.normalizeWithAssert(n), mue = mue) constrainedby Modelica.Mechanics.MultiBody.Interfaces.partialGravityAcceleration;
      protected
        parameter Integer ndim = if enableAnimation and animateWorld then 1 else 0;
        parameter Integer ndim2 = if enableAnimation and animateWorld and axisShowLabels then 1 else 0;
        parameter SI.Length headLength = min(axisLength, axisDiameter * Types.Defaults.FrameHeadLengthFraction);
        parameter SI.Length headWidth = axisDiameter * Types.Defaults.FrameHeadWidthFraction;
        parameter SI.Length lineLength = max(0, axisLength - headLength);
        parameter SI.Length lineWidth = axisDiameter;
        parameter SI.Length scaledLabel = Modelica.Mechanics.MultiBody.Types.Defaults.FrameLabelHeightFraction * axisDiameter;
        parameter SI.Length labelStart = 1.05 * axisLength;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape x_arrowLine(shapeType = "cylinder", length = lineLength, width = lineWidth, height = lineWidth, lengthDirection = {1, 0, 0}, widthDirection = {0, 1, 0}, color = axisColor_x, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape x_arrowHead(shapeType = "cone", length = headLength, width = headWidth, height = headWidth, lengthDirection = {1, 0, 0}, widthDirection = {0, 1, 0}, color = axisColor_x, r = {lineLength, 0, 0}, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines x_label(lines = scaledLabel * {[0, 0; 1, 1], [0, 1; 1, 0]}, diameter = axisDiameter, color = axisColor_x, r_lines = {labelStart, 0, 0}, n_x = {1, 0, 0}, n_y = {0, 1, 0}, specularCoefficient = 0) if enableAnimation and animateWorld and axisShowLabels;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape y_arrowLine(shapeType = "cylinder", length = lineLength, width = lineWidth, height = lineWidth, lengthDirection = {0, 1, 0}, widthDirection = {1, 0, 0}, color = axisColor_y, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape y_arrowHead(shapeType = "cone", length = headLength, width = headWidth, height = headWidth, lengthDirection = {0, 1, 0}, widthDirection = {1, 0, 0}, color = axisColor_y, r = {0, lineLength, 0}, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines y_label(lines = scaledLabel * {[0, 0; 1, 1.5], [0, 1.5; 0.5, 0.75]}, diameter = axisDiameter, color = axisColor_y, r_lines = {0, labelStart, 0}, n_x = {0, 1, 0}, n_y = {-1, 0, 0}, specularCoefficient = 0) if enableAnimation and animateWorld and axisShowLabels;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape z_arrowLine(shapeType = "cylinder", length = lineLength, width = lineWidth, height = lineWidth, lengthDirection = {0, 0, 1}, widthDirection = {0, 1, 0}, color = axisColor_z, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape z_arrowHead(shapeType = "cone", length = headLength, width = headWidth, height = headWidth, lengthDirection = {0, 0, 1}, widthDirection = {0, 1, 0}, color = axisColor_z, r = {0, 0, lineLength}, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines z_label(lines = scaledLabel * {[0, 0; 1, 0], [0, 1; 1, 1], [0, 1; 1, 0]}, diameter = axisDiameter, color = axisColor_z, r_lines = {0, 0, labelStart}, n_x = {0, 0, 1}, n_y = {0, 1, 0}, specularCoefficient = 0) if enableAnimation and animateWorld and axisShowLabels;
        parameter SI.Length gravityHeadLength = min(gravityArrowLength, gravityArrowDiameter * Types.Defaults.ArrowHeadLengthFraction);
        parameter SI.Length gravityHeadWidth = gravityArrowDiameter * Types.Defaults.ArrowHeadWidthFraction;
        parameter SI.Length gravityLineLength = max(0, gravityArrowLength - gravityHeadLength);
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravityArrowLine(shapeType = "cylinder", length = gravityLineLength, width = gravityArrowDiameter, height = gravityArrowDiameter, lengthDirection = n, widthDirection = {0, 1, 0}, color = gravityArrowColor, r_shape = gravityArrowTail, specularCoefficient = 0) if enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravityArrowHead(shapeType = "cone", length = gravityHeadLength, width = gravityHeadWidth, height = gravityHeadWidth, lengthDirection = n, widthDirection = {0, 1, 0}, color = gravityArrowColor, r_shape = gravityArrowTail + Modelica.Math.Vectors.normalize(n) * gravityLineLength, specularCoefficient = 0) if enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity;
        parameter Integer ndim_pointGravity = if enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity then 1 else 0;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravitySphere(shapeType = "sphere", r_shape = {-gravitySphereDiameter / 2, 0, 0}, lengthDirection = {1, 0, 0}, length = gravitySphereDiameter, width = gravitySphereDiameter, height = gravitySphereDiameter, color = gravitySphereColor, specularCoefficient = 0) if enableAnimation and animateGravity and gravityType == GravityTypes.PointGravity;
      equation
        Connections.root(frame_b.R);
        assert(Modelica.Math.Vectors.length(n) > 1.e-10, "Parameter n of World object is wrong (length(n) > 0 required)");
        frame_b.r_0 = zeros(3);
        frame_b.R = Frames.nullRotation();
        annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "No \"world\" component is defined. A default world
      component with the default gravity field will be used
      (g=9.81 in negative y-axis). If this is not desired,
      drag Modelica.Mechanics.MultiBody.World into the top level of your model."); 
      end World;

      package Forces  "Components that exert forces and/or torques between frames" 
        extends Modelica.Icons.SourcesPackage;

        model WorldForce  "External force acting at frame_b, defined by 3 input signals and resolved in frame world, frame_b or frame_resolve" 
          extends Interfaces.PartialOneFrame_b;
          Interfaces.Frame_resolve frame_resolve if resolveInFrame == Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.frame_resolve "The input signals are optionally resolved in this frame";
          Modelica.Blocks.Interfaces.RealInput[3] force(each final quantity = "Force", each final unit = "N") "x-, y-, z-coordinates of force resolved in frame defined by resolveInFrame";
          parameter Boolean animation = true "= true, if animation shall be enabled";
          parameter Modelica.Mechanics.MultiBody.Types.ResolveInFrameB resolveInFrame = Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.world "Frame in which input force is resolved (1: world, 2: frame_b, 3: frame_resolve)";
          parameter Real N_to_m(unit = "N/m") = world.defaultN_to_m "Force arrow scaling (length = force/N_to_m)";
          input SI.Diameter diameter = world.defaultArrowDiameter "Diameter of force arrow";
          input Types.Color color = Modelica.Mechanics.MultiBody.Types.Defaults.ForceColor "Color of arrow";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
        protected
          SI.Position[3] f_in_m = frame_b.f / N_to_m "Force mapped from N to m for animation";
          Visualizers.Advanced.Arrow arrow(diameter = diameter, color = color, specularCoefficient = specularCoefficient, R = frame_b.R, r = frame_b.r_0, r_tail = f_in_m, r_head = -f_in_m) if world.enableAnimation and animation;
        public
          Internal.BasicWorldForce basicWorldForce(resolveInFrame = resolveInFrame);
        protected
          Interfaces.ZeroPosition zeroPosition if not resolveInFrame == Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.frame_resolve;
        equation
          connect(basicWorldForce.frame_b, frame_b);
          connect(basicWorldForce.force, force);
          connect(basicWorldForce.frame_resolve, frame_resolve);
          connect(zeroPosition.frame_resolve, basicWorldForce.frame_resolve);
        end WorldForce;

        package Internal  "Internal package, should not be used by user" 
          extends Modelica.Icons.InternalPackage;

          model BasicWorldForce  "External force acting at frame_b, defined by 3 input signals" 
            import Modelica.Mechanics.MultiBody.Types.ResolveInFrameB;
            extends Interfaces.PartialOneFrame_b;
            Interfaces.Frame_resolve frame_resolve "The input signals are optionally resolved in this frame";
            Modelica.Blocks.Interfaces.RealInput[3] force(each final quantity = "Force", each final unit = "N") "x-, y-, z-coordinates of force resolved in frame defined by resolveInFrame";
            parameter Modelica.Mechanics.MultiBody.Types.ResolveInFrameB resolveInFrame = Modelica.Mechanics.MultiBody.Types.ResolveInFrameB.world "Frame in which force is resolved (1: world, 2: frame_b, 3: frame_resolve)";
          equation
            assert(cardinality(frame_resolve) > 0, "Connector frame_resolve must be connected at least once and frame_resolve.r_0/.R must be set");
            frame_resolve.f = zeros(3);
            frame_resolve.t = zeros(3);
            if resolveInFrame == ResolveInFrameB.world then
              frame_b.f = -Frames.resolve2(frame_b.R, force);
            elseif resolveInFrame == ResolveInFrameB.frame_b then
              frame_b.f = -force;
            elseif resolveInFrame == ResolveInFrameB.frame_resolve then
              frame_b.f = -Frames.resolveRelative(force, frame_resolve.R, frame_b.R);
            else
              assert(false, "Wrong value for parameter resolveInFrame");
              frame_b.f = zeros(3);
            end if;
            frame_b.t = zeros(3);
          end BasicWorldForce;

          function standardGravityAcceleration  "Standard gravity fields (no/parallel/point field)" 
            extends Modelica.Icons.Function;
            extends Modelica.Mechanics.MultiBody.Interfaces.partialGravityAcceleration;
            import Modelica.Mechanics.MultiBody.Types.GravityTypes;
            input GravityTypes gravityType "Type of gravity field";
            input Modelica.SIunits.Acceleration[3] g "Constant gravity acceleration, resolved in world frame, if gravityType=UniformGravity";
            input Real mue(unit = "m3/s2") "Field constant of point gravity field, if gravityType=PointGravity";
          algorithm
            gravity := if gravityType == GravityTypes.UniformGravity then g else if gravityType == GravityTypes.PointGravity then -mue / (r * r) * (r / Modelica.Math.Vectors.length(r)) else zeros(3);
            annotation(Inline = true); 
          end standardGravityAcceleration;
        end Internal;
      end Forces;

      package Frames  "Functions to transform rotational frame quantities" 
        extends Modelica.Icons.Package;

        record Orientation  "Orientation object defining rotation from a frame 1 into a frame 2" 
          extends Modelica.Icons.Record;
          Real[3, 3] T "Transformation matrix from world frame to local frame";
          SI.AngularVelocity[3] w "Absolute angular velocity of local frame, resolved in local frame";

          encapsulated function equalityConstraint  "Return the constraint residues to express that two frames have the same orientation" 
            import Modelica;
            import Modelica.Mechanics.MultiBody.Frames;
            extends Modelica.Icons.Function;
            input Frames.Orientation R1 "Orientation object to rotate frame 0 into frame 1";
            input Frames.Orientation R2 "Orientation object to rotate frame 0 into frame 2";
            output Real[3] residue "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)";
          algorithm
            residue := {Modelica.Math.atan2(cross(R1.T[1, :], R1.T[2, :]) * R2.T[2, :], R1.T[1, :] * R2.T[1, :]), Modelica.Math.atan2(-cross(R1.T[1, :], R1.T[2, :]) * R2.T[1, :], R1.T[2, :] * R2.T[2, :]), Modelica.Math.atan2(R1.T[2, :] * R2.T[1, :], R1.T[3, :] * R2.T[3, :])};
            annotation(Inline = true); 
          end equalityConstraint;
        end Orientation;

        function angularVelocity2  "Return angular velocity resolved in frame 2 from orientation object" 
          extends Modelica.Icons.Function;
          input Orientation R "Orientation object to rotate frame 1 into frame 2";
          output Modelica.SIunits.AngularVelocity[3] w "Angular velocity of frame 2 with respect to frame 1 resolved in frame 2";
        algorithm
          w := R.w;
          annotation(Inline = true); 
        end angularVelocity2;

        function resolve1  "Transform vector from frame 2 to frame 1" 
          extends Modelica.Icons.Function;
          input Orientation R "Orientation object to rotate frame 1 into frame 2";
          input Real[3] v2 "Vector in frame 2";
          output Real[3] v1 "Vector in frame 1";
        algorithm
          v1 := transpose(R.T) * v2;
          annotation(derivative(noDerivative = R) = Internal.resolve1_der, InlineAfterIndexReduction = true); 
        end resolve1;

        function resolve2  "Transform vector from frame 1 to frame 2" 
          extends Modelica.Icons.Function;
          input Orientation R "Orientation object to rotate frame 1 into frame 2";
          input Real[3] v1 "Vector in frame 1";
          output Real[3] v2 "Vector in frame 2";
        algorithm
          v2 := R.T * v1;
          annotation(derivative(noDerivative = R) = Internal.resolve2_der, InlineAfterIndexReduction = true); 
        end resolve2;

        function resolveRelative  "Transform vector from frame 1 to frame 2 using absolute orientation objects of frame 1 and of frame 2" 
          extends Modelica.Icons.Function;
          input Real[3] v1 "Vector in frame 1";
          input Orientation R1 "Orientation object to rotate frame 0 into frame 1";
          input Orientation R2 "Orientation object to rotate frame 0 into frame 2";
          output Real[3] v2 "Vector in frame 2";
        algorithm
          v2 := resolve2(R2, resolve1(R1, v1));
          annotation(derivative(noDerivative = R1, noDerivative = R2) = Internal.resolveRelative_der, InlineAfterIndexReduction = true); 
        end resolveRelative;

        function resolveDyade1  "Transform second order tensor from frame 2 to frame 1" 
          extends Modelica.Icons.Function;
          input Orientation R "Orientation object to rotate frame 1 into frame 2";
          input Real[3, 3] D2 "Second order tensor resolved in frame 2";
          output Real[3, 3] D1 "Second order tensor resolved in frame 1";
        algorithm
          D1 := transpose(R.T) * D2 * R.T;
          annotation(Inline = true); 
        end resolveDyade1;

        function nullRotation  "Return orientation object that does not rotate a frame" 
          extends Modelica.Icons.Function;
          output Orientation R "Orientation object such that frame 1 and frame 2 are identical";
        algorithm
          R := Orientation(T = identity(3), w = zeros(3));
          annotation(Inline = true); 
        end nullRotation;

        function absoluteRotation  "Return absolute orientation object from another absolute and a relative orientation object" 
          extends Modelica.Icons.Function;
          input Orientation R1 "Orientation object to rotate frame 0 into frame 1";
          input Orientation R_rel "Orientation object to rotate frame 1 into frame 2";
          output Orientation R2 "Orientation object to rotate frame 0 into frame 2";
        algorithm
          R2 := Orientation(T = R_rel.T * R1.T, w = resolve2(R_rel, R1.w) + R_rel.w);
          annotation(Inline = true); 
        end absoluteRotation;

        function planarRotation  "Return orientation object of a planar rotation" 
          import Modelica.Math;
          extends Modelica.Icons.Function;
          input Real[3] e(each final unit = "1") "Normalized axis of rotation (must have length=1)";
          input Modelica.SIunits.Angle angle "Rotation angle to rotate frame 1 into frame 2 along axis e";
          input Modelica.SIunits.AngularVelocity der_angle "= der(angle)";
          output Orientation R "Orientation object to rotate frame 1 into frame 2";
        algorithm
          R := Orientation(T = [e] * transpose([e]) + (identity(3) - [e] * transpose([e])) * Math.cos(angle) - skew(e) * Math.sin(angle), w = e * der_angle);
          annotation(Inline = true); 
        end planarRotation;

        function planarRotationAngle  "Return angle of a planar rotation, given the rotation axis and the representations of a vector in frame 1 and frame 2" 
          extends Modelica.Icons.Function;
          input Real[3] e(each final unit = "1") "Normalized axis of rotation to rotate frame 1 around e into frame 2 (must have length=1)";
          input Real[3] v1 "A vector v resolved in frame 1 (shall not be parallel to e)";
          input Real[3] v2 "Vector v resolved in frame 2, i.e., v2 = resolve2(planarRotation(e,angle),v1)";
          output Modelica.SIunits.Angle angle "Rotation angle to rotate frame 1 into frame 2 along axis e in the range: -pi <= angle <= pi";
        algorithm
          angle := Modelica.Math.atan2(-cross(e, v1) * v2, v1 * v2 - e * v1 * (e * v2));
          annotation(Inline = true); 
        end planarRotationAngle;

        function axesRotations  "Return fixed rotation object to rotate in sequence around fixed angles along 3 axes" 
          import TM = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
          extends Modelica.Icons.Function;
          input Integer[3] sequence(min = {1, 1, 1}, max = {3, 3, 3}) = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
          input Modelica.SIunits.Angle[3] angles "Rotation angles around the axes defined in 'sequence'";
          input Modelica.SIunits.AngularVelocity[3] der_angles "= der(angles)";
          output Orientation R "Orientation object to rotate frame 1 into frame 2";
        algorithm
          R := Orientation(T = TM.axisRotation(sequence[3], angles[3]) * TM.axisRotation(sequence[2], angles[2]) * TM.axisRotation(sequence[1], angles[1]), w = Frames.axis(sequence[3]) * der_angles[3] + TM.resolve2(TM.axisRotation(sequence[3], angles[3]), Frames.axis(sequence[2]) * der_angles[2]) + TM.resolve2(TM.axisRotation(sequence[3], angles[3]) * TM.axisRotation(sequence[2], angles[2]), Frames.axis(sequence[1]) * der_angles[1]));
          annotation(Inline = true); 
        end axesRotations;

        function axesRotationsAngles  "Return the 3 angles to rotate in sequence around 3 axes to construct the given orientation object" 
          extends Modelica.Icons.Function;
          input Orientation R "Orientation object to rotate frame 1 into frame 2";
          input Integer[3] sequence(min = {1, 1, 1}, max = {3, 3, 3}) = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
          input SI.Angle guessAngle1 = 0 "Select angles[1] such that |angles[1] - guessAngle1| is a minimum";
          output SI.Angle[3] angles "Rotation angles around the axes defined in 'sequence' such that R=Frames.axesRotation(sequence,angles); -pi < angles[i] <= pi";
        protected
          Real[3] e1_1(each final unit = "1") "First rotation axis, resolved in frame 1";
          Real[3] e2_1a(each final unit = "1") "Second rotation axis, resolved in frame 1a";
          Real[3] e3_1(each final unit = "1") "Third rotation axis, resolved in frame 1";
          Real[3] e3_2(each final unit = "1") "Third rotation axis, resolved in frame 2";
          Real A "Coefficient A in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
          Real B "Coefficient B in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
          SI.Angle angle_1a "Solution 1 for angles[1]";
          SI.Angle angle_1b "Solution 2 for angles[1]";
          TransformationMatrices.Orientation T_1a "Orientation object to rotate frame 1 into frame 1a";
        algorithm
          assert(sequence[1] <> sequence[2] and sequence[2] <> sequence[3], "input argument 'sequence[1:3]' is not valid");
          e1_1 := if sequence[1] == 1 then {1, 0, 0} else if sequence[1] == 2 then {0, 1, 0} else {0, 0, 1};
          e2_1a := if sequence[2] == 1 then {1, 0, 0} else if sequence[2] == 2 then {0, 1, 0} else {0, 0, 1};
          e3_1 := R.T[sequence[3], :];
          e3_2 := if sequence[3] == 1 then {1, 0, 0} else if sequence[3] == 2 then {0, 1, 0} else {0, 0, 1};
          A := e2_1a * e3_1;
          B := cross(e1_1, e2_1a) * e3_1;
          if abs(A) <= 1.e-12 and abs(B) <= 1.e-12 then
            angles[1] := guessAngle1;
          else
            angle_1a := Modelica.Math.atan2(A, -B);
            angle_1b := Modelica.Math.atan2(-A, B);
            angles[1] := if abs(angle_1a - guessAngle1) <= abs(angle_1b - guessAngle1) then angle_1a else angle_1b;
          end if;
          T_1a := TransformationMatrices.planarRotation(e1_1, angles[1]);
          angles[2] := planarRotationAngle(e2_1a, TransformationMatrices.resolve2(T_1a, e3_1), e3_2);
          angles[3] := planarRotationAngle(e3_2, e2_1a, TransformationMatrices.resolve2(R.T, TransformationMatrices.resolve1(T_1a, e2_1a)));
        end axesRotationsAngles;

        function from_nxy  "Return fixed orientation object from n_x and n_y vectors" 
          extends Modelica.Icons.Function;
          input Real[3] n_x(each final unit = "1") "Vector in direction of x-axis of frame 2, resolved in frame 1";
          input Real[3] n_y(each final unit = "1") "Vector in direction of y-axis of frame 2, resolved in frame 1";
          output Orientation R "Orientation object to rotate frame 1 into frame 2";
        protected
          Real abs_n_x = sqrt(n_x * n_x);
          Real[3] e_x(each final unit = "1") = if abs_n_x < 1.e-10 then {1, 0, 0} else n_x / abs_n_x;
          Real[3] n_z_aux(each final unit = "1") = cross(e_x, n_y);
          Real[3] n_y_aux(each final unit = "1") = if n_z_aux * n_z_aux > 1.0e-6 then n_y else if abs(e_x[1]) > 1.0e-6 then {0, 1, 0} else {1, 0, 0};
          Real[3] e_z_aux(each final unit = "1") = cross(e_x, n_y_aux);
          Real[3] e_z(each final unit = "1") = e_z_aux / sqrt(e_z_aux * e_z_aux);
        algorithm
          R := Orientation(T = {e_x, cross(e_z, e_x), e_z}, w = zeros(3));
        end from_nxy;

        function from_Q  "Return orientation object R from quaternion orientation object Q" 
          extends Modelica.Icons.Function;
          input Quaternions.Orientation Q "Quaternions orientation object to rotate frame 1 into frame 2";
          input Modelica.SIunits.AngularVelocity[3] w "Angular velocity from frame 2 with respect to frame 1, resolved in frame 2";
          output Orientation R "Orientation object to rotate frame 1 into frame 2";
        algorithm
          R := Orientation([2 * (Q[1] * Q[1] + Q[4] * Q[4]) - 1, 2 * (Q[1] * Q[2] + Q[3] * Q[4]), 2 * (Q[1] * Q[3] - Q[2] * Q[4]); 2 * (Q[2] * Q[1] - Q[3] * Q[4]), 2 * (Q[2] * Q[2] + Q[4] * Q[4]) - 1, 2 * (Q[2] * Q[3] + Q[1] * Q[4]); 2 * (Q[3] * Q[1] + Q[2] * Q[4]), 2 * (Q[3] * Q[2] - Q[1] * Q[4]), 2 * (Q[3] * Q[3] + Q[4] * Q[4]) - 1], w = w);
          annotation(Inline = true); 
        end from_Q;

        function to_Q  "Return quaternion orientation object Q from orientation object R" 
          extends Modelica.Icons.Function;
          input Orientation R "Orientation object to rotate frame 1 into frame 2";
          input Quaternions.Orientation Q_guess = Quaternions.nullRotation() "Guess value for output Q (there are 2 solutions; the one closer to Q_guess is used";
          output Quaternions.Orientation Q "Quaternions orientation object to rotate frame 1 into frame 2";
        algorithm
          Q := Quaternions.from_T(R.T, Q_guess);
          annotation(Inline = true); 
        end to_Q;

        function axis  "Return unit vector for x-, y-, or z-axis" 
          extends Modelica.Icons.Function;
          input Integer axis(min = 1, max = 3) "Axis vector to be returned";
          output Real[3] e(each final unit = "1") "Unit axis vector";
        algorithm
          e := if axis == 1 then {1, 0, 0} else if axis == 2 then {0, 1, 0} else {0, 0, 1};
          annotation(Inline = true); 
        end axis;

        package Quaternions  "Functions to transform rotational frame quantities based on quaternions (also called Euler parameters)" 
          extends Modelica.Icons.FunctionsPackage;

          type Orientation  "Orientation type defining rotation from a frame 1 into a frame 2 with quaternions {p1,p2,p3,p0}" 
            extends Internal.QuaternionBase;

            encapsulated function equalityConstraint  "Return the constraint residues to express that two frames have the same quaternion orientation" 
              import Modelica;
              import Modelica.Mechanics.MultiBody.Frames.Quaternions;
              extends Modelica.Icons.Function;
              input Quaternions.Orientation Q1 "Quaternions orientation object to rotate frame 0 into frame 1";
              input Quaternions.Orientation Q2 "Quaternions orientation object to rotate frame 0 into frame 2";
              output Real[3] residue "Zero vector if Q1 and Q2 are identical (the first three elements of the relative transformation (is {0,0,0} for the null rotation, guarded by atan2 to make the mirrored solution invalid";
            algorithm
              residue := {atan2({Q1[4], Q1[3], -Q1[2], -Q1[1]} * Q2, Q1 * Q2), atan2({-Q1[3], Q1[4], Q1[1], -Q1[2]} * Q2, Q1 * Q2), atan2({Q1[2], -Q1[1], Q1[4], -Q1[3]} * Q2, Q1 * Q2)};
              annotation(Inline = true); 
            end equalityConstraint;
          end Orientation;

          type der_Orientation = Real[4](each unit = "1/s") "First time derivative of Quaternions.Orientation";

          function orientationConstraint  "Return residues of orientation constraints (shall be zero)" 
            extends Modelica.Icons.Function;
            input Quaternions.Orientation Q "Quaternions orientation object to rotate frame 1 into frame 2";
            output Real[1] residue "Residue constraint (shall be zero)";
          algorithm
            residue := {Q * Q - 1};
            annotation(Inline = true); 
          end orientationConstraint;

          function angularVelocity2  "Compute angular velocity resolved in frame 2 from quaternions orientation object and its derivative" 
            extends Modelica.Icons.Function;
            input Quaternions.Orientation Q "Quaternions orientation object to rotate frame 1 into frame 2";
            input der_Orientation der_Q "Derivative of Q";
            output Modelica.SIunits.AngularVelocity[3] w "Angular velocity of frame 2 with respect to frame 1 resolved in frame 2";
          algorithm
            w := 2 * ([Q[4], Q[3], -Q[2], -Q[1]; -Q[3], Q[4], Q[1], -Q[2]; Q[2], -Q[1], Q[4], -Q[3]] * der_Q);
            annotation(Inline = true); 
          end angularVelocity2;

          function nullRotation  "Return quaternion orientation object that does not rotate a frame" 
            extends Modelica.Icons.Function;
            output Quaternions.Orientation Q "Quaternions orientation object to rotate frame 1 into frame 2";
          algorithm
            Q := {0, 0, 0, 1};
            annotation(Inline = true); 
          end nullRotation;

          function from_T  "Return quaternion orientation object Q from transformation matrix T" 
            extends Modelica.Icons.Function;
            input Real[3, 3] T "Transformation matrix to transform vector from frame 1 to frame 2 (v2=T*v1)";
            input Quaternions.Orientation Q_guess = nullRotation() "Guess value for Q (there are 2 solutions; the one close to Q_guess is used";
            output Quaternions.Orientation Q "Quaternions orientation object to rotate frame 1 into frame 2 (Q and -Q have same transformation matrix)";
          protected
            Real paux;
            Real paux4;
            Real c1;
            Real c2;
            Real c3;
            Real c4;
            constant Real p4limit = 0.1;
            constant Real c4limit = 4 * p4limit * p4limit;
          algorithm
            c1 := 1 + T[1, 1] - T[2, 2] - T[3, 3];
            c2 := 1 + T[2, 2] - T[1, 1] - T[3, 3];
            c3 := 1 + T[3, 3] - T[1, 1] - T[2, 2];
            c4 := 1 + T[1, 1] + T[2, 2] + T[3, 3];
            if c4 > c4limit or c4 > c1 and c4 > c2 and c4 > c3 then
              paux := sqrt(c4) / 2;
              paux4 := 4 * paux;
              Q := {(T[2, 3] - T[3, 2]) / paux4, (T[3, 1] - T[1, 3]) / paux4, (T[1, 2] - T[2, 1]) / paux4, paux};
            elseif c1 > c2 and c1 > c3 and c1 > c4 then
              paux := sqrt(c1) / 2;
              paux4 := 4 * paux;
              Q := {paux, (T[1, 2] + T[2, 1]) / paux4, (T[1, 3] + T[3, 1]) / paux4, (T[2, 3] - T[3, 2]) / paux4};
            elseif c2 > c1 and c2 > c3 and c2 > c4 then
              paux := sqrt(c2) / 2;
              paux4 := 4 * paux;
              Q := {(T[1, 2] + T[2, 1]) / paux4, paux, (T[2, 3] + T[3, 2]) / paux4, (T[3, 1] - T[1, 3]) / paux4};
            else
              paux := sqrt(c3) / 2;
              paux4 := 4 * paux;
              Q := {(T[1, 3] + T[3, 1]) / paux4, (T[2, 3] + T[3, 2]) / paux4, paux, (T[1, 2] - T[2, 1]) / paux4};
            end if;
            if Q * Q_guess < 0 then
              Q := -Q;
            else
            end if;
          end from_T;
        end Quaternions;

        package TransformationMatrices  "Functions for transformation matrices" 
          extends Modelica.Icons.FunctionsPackage;

          type Orientation  "Orientation type defining rotation from a frame 1 into a frame 2 with a transformation matrix" 
            extends Internal.TransformationMatrix;

            encapsulated function equalityConstraint  "Return the constraint residues to express that two frames have the same orientation" 
              import Modelica;
              import Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
              extends Modelica.Icons.Function;
              input TransformationMatrices.Orientation T1 "Orientation object to rotate frame 0 into frame 1";
              input TransformationMatrices.Orientation T2 "Orientation object to rotate frame 0 into frame 2";
              output Real[3] residue "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)";
            algorithm
              residue := {cross(T1[1, :], T1[2, :]) * T2[2, :], -cross(T1[1, :], T1[2, :]) * T2[1, :], T1[2, :] * T2[1, :]};
              annotation(Inline = true); 
            end equalityConstraint;
          end Orientation;

          function resolve1  "Transform vector from frame 2 to frame 1" 
            extends Modelica.Icons.Function;
            input TransformationMatrices.Orientation T "Orientation object to rotate frame 1 into frame 2";
            input Real[3] v2 "Vector in frame 2";
            output Real[3] v1 "Vector in frame 1";
          algorithm
            v1 := transpose(T) * v2;
            annotation(Inline = true); 
          end resolve1;

          function resolve2  "Transform vector from frame 1 to frame 2" 
            extends Modelica.Icons.Function;
            input TransformationMatrices.Orientation T "Orientation object to rotate frame 1 into frame 2";
            input Real[3] v1 "Vector in frame 1";
            output Real[3] v2 "Vector in frame 2";
          algorithm
            v2 := T * v1;
            annotation(Inline = true); 
          end resolve2;

          function absoluteRotation  "Return absolute orientation object from another absolute and a relative orientation object" 
            extends Modelica.Icons.Function;
            input TransformationMatrices.Orientation T1 "Orientation object to rotate frame 0 into frame 1";
            input TransformationMatrices.Orientation T_rel "Orientation object to rotate frame 1 into frame 2";
            output TransformationMatrices.Orientation T2 "Orientation object to rotate frame 0 into frame 2";
          algorithm
            T2 := T_rel * T1;
            annotation(Inline = true); 
          end absoluteRotation;

          function planarRotation  "Return orientation object of a planar rotation" 
            import Modelica.Math;
            extends Modelica.Icons.Function;
            input Real[3] e(each final unit = "1") "Normalized axis of rotation (must have length=1)";
            input Modelica.SIunits.Angle angle "Rotation angle to rotate frame 1 into frame 2 along axis e";
            output TransformationMatrices.Orientation T "Orientation object to rotate frame 1 into frame 2";
          algorithm
            T := [e] * transpose([e]) + (identity(3) - [e] * transpose([e])) * Math.cos(angle) - skew(e) * Math.sin(angle);
            annotation(Inline = true); 
          end planarRotation;

          function axisRotation  "Return rotation object to rotate around one frame axis" 
            extends Modelica.Icons.Function;
            input Integer axis(min = 1, max = 3) "Rotate around 'axis' of frame 1";
            input Modelica.SIunits.Angle angle "Rotation angle to rotate frame 1 into frame 2 along 'axis' of frame 1";
            output TransformationMatrices.Orientation T "Orientation object to rotate frame 1 into frame 2";
          algorithm
            T := if axis == 1 then [1, 0, 0; 0, cos(angle), sin(angle); 0, -sin(angle), cos(angle)] else if axis == 2 then [cos(angle), 0, -sin(angle); 0, 1, 0; sin(angle), 0, cos(angle)] else [cos(angle), sin(angle), 0; -sin(angle), cos(angle), 0; 0, 0, 1];
            annotation(Inline = true); 
          end axisRotation;

          function from_nxy  "Return orientation object from n_x and n_y vectors" 
            extends Modelica.Icons.Function;
            input Real[3] n_x(each final unit = "1") "Vector in direction of x-axis of frame 2, resolved in frame 1";
            input Real[3] n_y(each final unit = "1") "Vector in direction of y-axis of frame 2, resolved in frame 1";
            output TransformationMatrices.Orientation T "Orientation object to rotate frame 1 into frame 2";
          protected
            Real abs_n_x = sqrt(n_x * n_x);
            Real[3] e_x(each final unit = "1") = if abs_n_x < 1.e-10 then {1, 0, 0} else n_x / abs_n_x;
            Real[3] n_z_aux(each final unit = "1") = cross(e_x, n_y);
            Real[3] n_y_aux(each final unit = "1") = if n_z_aux * n_z_aux > 1.0e-6 then n_y else if abs(e_x[1]) > 1.0e-6 then {0, 1, 0} else {1, 0, 0};
            Real[3] e_z_aux(each final unit = "1") = cross(e_x, n_y_aux);
            Real[3] e_z(each final unit = "1") = e_z_aux / sqrt(e_z_aux * e_z_aux);
          algorithm
            T := {e_x, cross(e_z, e_x), e_z};
          end from_nxy;
        end TransformationMatrices;

        package Internal  "Internal definitions that may be removed or changed (do not use)" 
          extends Modelica.Icons.InternalPackage;
          type TransformationMatrix = Real[3, 3];
          type QuaternionBase = Real[4];

          function resolve1_der  "Derivative of function Frames.resolve1(..)" 
            import Modelica.Mechanics.MultiBody.Frames;
            extends Modelica.Icons.Function;
            input Orientation R "Orientation object to rotate frame 1 into frame 2";
            input Real[3] v2 "Vector resolved in frame 2";
            input Real[3] v2_der "= der(v2)";
            output Real[3] v1_der "Derivative of vector v resolved in frame 1";
          algorithm
            v1_der := Frames.resolve1(R, v2_der + cross(R.w, v2));
            annotation(Inline = true); 
          end resolve1_der;

          function resolve2_der  "Derivative of function Frames.resolve2(..)" 
            import Modelica.Mechanics.MultiBody.Frames;
            extends Modelica.Icons.Function;
            input Orientation R "Orientation object to rotate frame 1 into frame 2";
            input Real[3] v1 "Vector resolved in frame 1";
            input Real[3] v1_der "= der(v1)";
            output Real[3] v2_der "Derivative of vector v resolved in frame 2";
          algorithm
            v2_der := Frames.resolve2(R, v1_der) - cross(R.w, Frames.resolve2(R, v1));
            annotation(Inline = true); 
          end resolve2_der;

          function resolveRelative_der  "Derivative of function Frames.resolveRelative(..)" 
            import Modelica.Mechanics.MultiBody.Frames;
            extends Modelica.Icons.Function;
            input Real[3] v1 "Vector in frame 1";
            input Orientation R1 "Orientation object to rotate frame 0 into frame 1";
            input Orientation R2 "Orientation object to rotate frame 0 into frame 2";
            input Real[3] v1_der "= der(v1)";
            output Real[3] v2_der "Derivative of vector v resolved in frame 2";
          algorithm
            v2_der := Frames.resolveRelative(v1_der + cross(R1.w, v1), R1, R2) - cross(R2.w, Frames.resolveRelative(v1, R1, R2));
            annotation(Inline = true); 
          end resolveRelative_der;
        end Internal;
      end Frames;

      package Interfaces  "Connectors and partial models for 3-dim. mechanical components" 
        extends Modelica.Icons.InterfacesPackage;

        connector Frame  "Coordinate system fixed to the component with one cut-force and cut-torque (no icon)" 
          SI.Position[3] r_0 "Position vector from world frame to the connector frame origin, resolved in world frame";
          Frames.Orientation R "Orientation object to rotate the world frame into the connector frame";
          flow SI.Force[3] f "Cut-force resolved in connector frame" annotation(unassignedMessage = "All Forces cannot be uniquely calculated.
        The reason could be that the mechanism contains
        a planar loop or that joints constrain the
        same motion. For planar loops, use for one
        revolute joint per loop the joint
        Joints.RevolutePlanarLoopConstraint instead of
        Joints.Revolute.");
          flow SI.Torque[3] t "Cut-torque resolved in connector frame";
        end Frame;

        connector Frame_a  "Coordinate system fixed to the component with one cut-force and cut-torque (filled rectangular icon)" 
          extends Frame;
        end Frame_a;

        connector Frame_b  "Coordinate system fixed to the component with one cut-force and cut-torque (non-filled rectangular icon)" 
          extends Frame;
        end Frame_b;

        connector Frame_resolve  "Coordinate system fixed to the component used to express in which coordinate system a vector is resolved (non-filled rectangular icon)" 
          extends Frame;
        end Frame_resolve;

        partial model PartialOneFrame_b  "Base model for components providing one frame_b connector + outer world + assert to guarantee that the component is connected" 
          Interfaces.Frame_b frame_b "Coordinate system fixed to the component with one cut-force and cut-torque";
        protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          assert(cardinality(frame_b) > 0, "Connector frame_b of component is not connected");
        end PartialOneFrame_b;

        model ZeroPosition  "Set absolute position vector of frame_resolve to a zero vector and the orientation object to a null rotation" 
          extends Modelica.Blocks.Icons.Block;
          Interfaces.Frame_resolve frame_resolve;
        equation
          Connections.root(frame_resolve.R);
          frame_resolve.R = Modelica.Mechanics.MultiBody.Frames.nullRotation();
          frame_resolve.r_0 = zeros(3);
        end ZeroPosition;

        partial function partialGravityAcceleration  
          extends Modelica.Icons.Function;
          input Modelica.SIunits.Position[3] r "Position vector from world frame to actual point, resolved in world frame";
          output Modelica.SIunits.Acceleration[3] gravity "Gravity acceleration at position r, resolved in world frame";
        end partialGravityAcceleration;
      end Interfaces;

      package Joints  "Components that constrain the motion between two frames" 
        extends Modelica.Icons.Package;

        model Revolute  "Revolute joint (1 rotational degree-of-freedom, 2 potential states, optional axis flange)" 
          Modelica.Mechanics.Rotational.Interfaces.Flange_a axis if useAxisFlange "1-dim. rotational flange that drives the joint";
          Modelica.Mechanics.Rotational.Interfaces.Flange_b support if useAxisFlange "1-dim. rotational flange of the drive support (assumed to be fixed in the world frame, NOT in the joint)";
          Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a "Coordinate system fixed to the joint with one cut-force and cut-torque";
          Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b "Coordinate system fixed to the joint with one cut-force and cut-torque";
          parameter Boolean useAxisFlange = false "= true, if axis flange is enabled" annotation(Evaluate = true, HideResult = true);
          parameter Boolean animation = true "= true, if animation shall be enabled (show axis as cylinder)";
          parameter Modelica.Mechanics.MultiBody.Types.Axis n = {0, 0, 1} "Axis of rotation resolved in frame_a (= same as in frame_b)" annotation(Evaluate = true);
          constant SI.Angle phi_offset = 0 "Relative angle offset (angle = phi_offset + phi)";
          parameter SI.Distance cylinderLength = world.defaultJointLength "Length of cylinder representing the joint axis";
          parameter SI.Distance cylinderDiameter = world.defaultJointWidth "Diameter of cylinder representing the joint axis";
          input Modelica.Mechanics.MultiBody.Types.Color cylinderColor = Modelica.Mechanics.MultiBody.Types.Defaults.JointColor "Color of cylinder representing the joint axis";
          input Modelica.Mechanics.MultiBody.Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
          parameter StateSelect stateSelect = StateSelect.prefer "Priority to use joint angle phi and w=der(phi) as states";
          SI.Angle phi(start = 0, final stateSelect = stateSelect) "Relative rotation angle from frame_a to frame_b" annotation(unassignedMessage = "
        The rotation angle phi of a revolute joint cannot be determined.
        Possible reasons:
        - A non-zero mass might be missing on either side of the parts
          connected to the revolute joint.
        - Too many StateSelect.always are defined and the model
          has less degrees of freedom as specified with this setting
          (remove all StateSelect.always settings).
          ");
          SI.AngularVelocity w(start = 0, stateSelect = stateSelect) "First derivative of angle phi (relative angular velocity)";
          SI.AngularAcceleration a(start = 0) "Second derivative of angle phi (relative angular acceleration)";
          SI.Torque tau "Driving torque in direction of axis of rotation";
          SI.Angle angle "= phi_offset + phi";
        protected
          outer Modelica.Mechanics.MultiBody.World world;
          parameter Real[3] e(each final unit = "1") = Modelica.Math.Vectors.normalizeWithAssert(n) "Unit vector in direction of rotation axis, resolved in frame_a (= same as in frame_b)";
          Frames.Orientation R_rel "Relative orientation object from frame_a to frame_b or from frame_b to frame_a";
          Visualizers.Advanced.Shape cylinder(shapeType = "cylinder", color = cylinderColor, specularCoefficient = specularCoefficient, length = cylinderLength, width = cylinderDiameter, height = cylinderDiameter, lengthDirection = e, widthDirection = {0, 1, 0}, r_shape = -e * (cylinderLength / 2), r = frame_a.r_0, R = frame_a.R) if world.enableAnimation and animation;
          Modelica.Mechanics.Rotational.Components.Fixed fixed "support flange is fixed to ground";
          Rotational.Interfaces.InternalSupport internalAxis(tau = tau);
          Rotational.Sources.ConstantTorque constantTorque(tau_constant = 0) if not useAxisFlange;
        equation
          Connections.branch(frame_a.R, frame_b.R);
          assert(cardinality(frame_a) > 0, "Connector frame_a of revolute joint is not connected");
          assert(cardinality(frame_b) > 0, "Connector frame_b of revolute joint is not connected");
          angle = phi_offset + phi;
          w = der(phi);
          a = der(w);
          frame_b.r_0 = frame_a.r_0;
          if Connections.rooted(frame_a.R) then
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
          tau = -frame_b.t * e;
          phi = internalAxis.phi;
          connect(fixed.flange, support);
          connect(internalAxis.flange, axis);
          connect(constantTorque.flange, internalAxis.flange);
        end Revolute;
      end Joints;

      package Parts  "Rigid components such as bodies with mass and inertia and massless rods" 
        extends Modelica.Icons.Package;

        model FixedTranslation  "Fixed translation of frame_b with respect to frame_a" 
          import Modelica.Mechanics.MultiBody.Types;
          import Modelica.SIunits.Conversions.to_unit1;
          Interfaces.Frame_a frame_a "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b "Coordinate system fixed to the component with one cut-force and cut-torque";
          parameter Boolean animation = true "= true, if animation shall be enabled";
          parameter SI.Position[3] r(start = {0, 0, 0}) "Vector from frame_a to frame_b resolved in frame_a";
          parameter Types.ShapeType shapeType = "cylinder" "Type of shape";
          parameter SI.Position[3] r_shape = {0, 0, 0} "Vector from frame_a to shape origin, resolved in frame_a";
          parameter Types.Axis lengthDirection = to_unit1(r - r_shape) "Vector in length direction of shape, resolved in frame_a" annotation(Evaluate = true);
          parameter Types.Axis widthDirection = {0, 1, 0} "Vector in width direction of shape, resolved in frame_a" annotation(Evaluate = true);
          parameter SI.Length length = Modelica.Math.Vectors.length(r - r_shape) "Length of shape";
          parameter SI.Distance width = length / world.defaultWidthFraction "Width of shape";
          parameter SI.Distance height = width "Height of shape";
          parameter Types.ShapeExtra extra = 0.0 "Additional parameter depending on shapeType (see docu of Visualizers.Advanced.Shape)";
          input Types.Color color = Modelica.Mechanics.MultiBody.Types.Defaults.RodColor "Color of shape";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
        protected
          outer Modelica.Mechanics.MultiBody.World world;
          Visualizers.Advanced.Shape shape(shapeType = shapeType, color = color, specularCoefficient = specularCoefficient, r_shape = r_shape, lengthDirection = lengthDirection, widthDirection = widthDirection, length = length, width = width, height = height, extra = extra, r = frame_a.r_0, R = frame_a.R) if world.enableAnimation and animation;
        equation
          Connections.branch(frame_a.R, frame_b.R);
          assert(cardinality(frame_a) > 0 or cardinality(frame_b) > 0, "Neither connector frame_a nor frame_b of FixedTranslation object is connected");
          frame_b.r_0 = frame_a.r_0 + Frames.resolve1(frame_a.R, r);
          frame_b.R = frame_a.R;
          zeros(3) = frame_a.f + frame_b.f;
          zeros(3) = frame_a.t + frame_b.t + cross(r, frame_b.f);
        end FixedTranslation;

        model Body  "Rigid body with mass, inertia tensor and one frame connector (12 potential states)" 
          import Modelica.Mechanics.MultiBody.Types;
          import Modelica.Mechanics.MultiBody.Frames;
          import Modelica.SIunits.Conversions.to_unit1;
          Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a "Coordinate system fixed at body";
          parameter Boolean animation = true "= true, if animation shall be enabled (show cylinder and sphere)";
          parameter SI.Position[3] r_CM(start = {0, 0, 0}) "Vector from frame_a to center of mass, resolved in frame_a";
          parameter SI.Mass m(min = 0, start = 1) "Mass of rigid body";
          parameter SI.Inertia I_11(min = 0) = 0.001 "(1,1) element of inertia tensor";
          parameter SI.Inertia I_22(min = 0) = 0.001 "(2,2) element of inertia tensor";
          parameter SI.Inertia I_33(min = 0) = 0.001 "(3,3) element of inertia tensor";
          parameter SI.Inertia I_21(min = -C.inf) = 0 "(2,1) element of inertia tensor";
          parameter SI.Inertia I_31(min = -C.inf) = 0 "(3,1) element of inertia tensor";
          parameter SI.Inertia I_32(min = -C.inf) = 0 "(3,2) element of inertia tensor";
          SI.Position[3] r_0(start = {0, 0, 0}, each stateSelect = if enforceStates then StateSelect.always else StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
          SI.Velocity[3] v_0(start = {0, 0, 0}, each stateSelect = if enforceStates then StateSelect.always else StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
          SI.Acceleration[3] a_0(start = {0, 0, 0}) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
          parameter Boolean angles_fixed = false "= true, if angles_start are used as initial values, else as guess values" annotation(Evaluate = true);
          parameter SI.Angle[3] angles_start = {0, 0, 0} "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
          parameter Types.RotationSequence sequence_start = {1, 2, 3} "Sequence of rotations to rotate frame_a into frame_b at initial time" annotation(Evaluate = true);
          parameter Boolean w_0_fixed = false "= true, if w_0_start are used as initial values, else as guess values" annotation(Evaluate = true);
          parameter SI.AngularVelocity[3] w_0_start = {0, 0, 0} "Initial or guess values of angular velocity of frame_a resolved in world frame";
          parameter Boolean z_0_fixed = false "= true, if z_0_start are used as initial values, else as guess values" annotation(Evaluate = true);
          parameter SI.AngularAcceleration[3] z_0_start = {0, 0, 0} "Initial values of angular acceleration z_0 = der(w_0)";
          parameter SI.Diameter sphereDiameter = world.defaultBodyDiameter "Diameter of sphere";
          input Types.Color sphereColor = Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor "Color of sphere";
          parameter SI.Diameter cylinderDiameter = sphereDiameter / Types.Defaults.BodyCylinderDiameterFraction "Diameter of cylinder";
          input Types.Color cylinderColor = sphereColor "Color of cylinder";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
          parameter Boolean enforceStates = false "= true, if absolute variables of body object shall be used as states (StateSelect.always)" annotation(Evaluate = true);
          parameter Boolean useQuaternions = true "= true, if quaternions shall be used as potential states otherwise use 3 angles as potential states" annotation(Evaluate = true);
          parameter Types.RotationSequence sequence_angleStates = {1, 2, 3} "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states" annotation(Evaluate = true);
          final parameter SI.Inertia[3, 3] I = [I_11, I_21, I_31; I_21, I_22, I_32; I_31, I_32, I_33] "inertia tensor";
          final parameter Frames.Orientation R_start = Modelica.Mechanics.MultiBody.Frames.axesRotations(sequence_start, angles_start, zeros(3)) "Orientation object from world frame to frame_a at initial time";
          final parameter SI.AngularAcceleration[3] z_a_start = Frames.resolve2(R_start, z_0_start) "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";
          SI.AngularVelocity[3] w_a(start = Frames.resolve2(R_start, w_0_start), fixed = fill(w_0_fixed, 3), each stateSelect = if enforceStates then if useQuaternions then StateSelect.always else StateSelect.never else StateSelect.avoid) "Absolute angular velocity of frame_a resolved in frame_a";
          SI.AngularAcceleration[3] z_a(start = Frames.resolve2(R_start, z_0_start), fixed = fill(z_0_fixed, 3)) "Absolute angular acceleration of frame_a resolved in frame_a";
          SI.Acceleration[3] g_0 "Gravity acceleration resolved in world frame";
        protected
          outer Modelica.Mechanics.MultiBody.World world;
          parameter Frames.Quaternions.Orientation Q_start = Frames.to_Q(R_start) "Quaternion orientation object from world frame to frame_a at initial time";
          Frames.Quaternions.Orientation Q(start = Q_start, each stateSelect = if enforceStates then if useQuaternions then StateSelect.prefer else StateSelect.never else StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
          parameter SI.Angle[3] phi_start = if sequence_start[1] == sequence_angleStates[1] and sequence_start[2] == sequence_angleStates[2] and sequence_start[3] == sequence_angleStates[3] then angles_start else Frames.axesRotationsAngles(R_start, sequence_angleStates) "Potential angle states at initial time";
          SI.Angle[3] phi(start = phi_start, each stateSelect = if enforceStates then if useQuaternions then StateSelect.never else StateSelect.always else StateSelect.avoid) "Dummy or 3 angles to rotate world frame into frame_a of body";
          SI.AngularVelocity[3] phi_d(each stateSelect = if enforceStates then if useQuaternions then StateSelect.never else StateSelect.always else StateSelect.avoid) "= der(phi)";
          SI.AngularAcceleration[3] phi_dd "= der(phi_d)";
          Visualizers.Advanced.Shape cylinder(shapeType = "cylinder", color = cylinderColor, specularCoefficient = specularCoefficient, length = if Modelica.Math.Vectors.length(r_CM) > sphereDiameter / 2 then Modelica.Math.Vectors.length(r_CM) - (if cylinderDiameter > 1.1 * sphereDiameter then sphereDiameter / 2 else 0) else 0, width = cylinderDiameter, height = cylinderDiameter, lengthDirection = to_unit1(r_CM), widthDirection = {0, 1, 0}, r = frame_a.r_0, R = frame_a.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape sphere(shapeType = "sphere", color = sphereColor, specularCoefficient = specularCoefficient, length = sphereDiameter, width = sphereDiameter, height = sphereDiameter, lengthDirection = {1, 0, 0}, widthDirection = {0, 1, 0}, r_shape = r_CM - {1, 0, 0} * sphereDiameter / 2, r = frame_a.r_0, R = frame_a.R) if world.enableAnimation and animation and sphereDiameter > 0;
        initial equation
          if angles_fixed then
            if not Connections.isRoot(frame_a.R) then
              zeros(3) = Frames.Orientation.equalityConstraint(frame_a.R, R_start);
            elseif useQuaternions then
              zeros(3) = Frames.Quaternions.Orientation.equalityConstraint(Q, Q_start);
            else
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
            Q = {0, 0, 0, 1};
            phi = zeros(3);
            phi_d = zeros(3);
            phi_dd = zeros(3);
          elseif useQuaternions then
            frame_a.R = Frames.from_Q(Q, Frames.Quaternions.angularVelocity2(Q, der(Q)));
            {0} = Frames.Quaternions.orientationConstraint(Q);
            phi = zeros(3);
            phi_d = zeros(3);
            phi_dd = zeros(3);
          else
            phi_d = der(phi);
            phi_dd = der(phi_d);
            frame_a.R = Frames.axesRotations(sequence_angleStates, phi, phi_d);
            Q = {0, 0, 0, 1};
          end if;
          g_0 = world.gravityAcceleration(frame_a.r_0 + Frames.resolve1(frame_a.R, r_CM));
          v_0 = der(frame_a.r_0);
          a_0 = der(v_0);
          w_a = Frames.angularVelocity2(frame_a.R);
          z_a = der(w_a);
          frame_a.f = m * (Frames.resolve2(frame_a.R, a_0 - g_0) + cross(z_a, r_CM) + cross(w_a, cross(w_a, r_CM)));
          frame_a.t = I * z_a + cross(w_a, I * w_a) + cross(r_CM, frame_a.f);
        end Body;

        model BodyBox  "Rigid body with box shape. Mass and animation properties are computed from box data and density (12 potential states)" 
          import Modelica.Mechanics.MultiBody.Types;
          import Modelica.Math.Vectors.normalizeWithAssert;
          import Modelica.SIunits.Conversions.to_unit1;
          Interfaces.Frame_a frame_a "Coordinate system fixed to the component with one cut-force and cut-torque";
          Interfaces.Frame_b frame_b "Coordinate system fixed to the component with one cut-force and cut-torque";
          parameter Boolean animation = true "= true, if animation shall be enabled (show box between frame_a and frame_b)";
          parameter SI.Position[3] r(start = {0.1, 0, 0}) "Vector from frame_a to frame_b resolved in frame_a";
          parameter SI.Position[3] r_shape = {0, 0, 0} "Vector from frame_a to box origin, resolved in frame_a";
          parameter Modelica.Mechanics.MultiBody.Types.Axis lengthDirection = to_unit1(r - r_shape) "Vector in length direction of box, resolved in frame_a" annotation(Evaluate = true);
          parameter Modelica.Mechanics.MultiBody.Types.Axis widthDirection = {0, 1, 0} "Vector in width direction of box, resolved in frame_a" annotation(Evaluate = true);
          parameter SI.Length length = Modelica.Math.Vectors.length(r - r_shape) "Length of box";
          parameter SI.Distance width = length / world.defaultWidthFraction "Width of box";
          parameter SI.Distance height = width "Height of box";
          parameter SI.Distance innerWidth = 0 "Width of inner box surface (0 <= innerWidth <= width)";
          parameter SI.Distance innerHeight = innerWidth "Height of inner box surface (0 <= innerHeight <= height)";
          parameter SI.Density density = 7700 "Density of cylinder (e.g., steel: 7700 .. 7900, wood : 400 .. 800)";
          input Modelica.Mechanics.MultiBody.Types.Color color = Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor "Color of box";
          input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
          SI.Position[3] r_0(start = {0, 0, 0}, each stateSelect = if enforceStates then StateSelect.always else StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
          SI.Velocity[3] v_0(start = {0, 0, 0}, each stateSelect = if enforceStates then StateSelect.always else StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
          SI.Acceleration[3] a_0(start = {0, 0, 0}) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
          parameter Boolean angles_fixed = false "= true, if angles_start are used as initial values, else as guess values" annotation(Evaluate = true);
          parameter SI.Angle[3] angles_start = {0, 0, 0} "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
          parameter Types.RotationSequence sequence_start = {1, 2, 3} "Sequence of rotations to rotate frame_a into frame_b at initial time" annotation(Evaluate = true);
          parameter Boolean w_0_fixed = false "= true, if w_0_start are used as initial values, else as guess values" annotation(Evaluate = true);
          parameter SI.AngularVelocity[3] w_0_start = {0, 0, 0} "Initial or guess values of angular velocity of frame_a resolved in world frame";
          parameter Boolean z_0_fixed = false "= true, if z_0_start are used as initial values, else as guess values" annotation(Evaluate = true);
          parameter SI.AngularAcceleration[3] z_0_start = {0, 0, 0} "Initial values of angular acceleration z_0 = der(w_0)";
          parameter Boolean enforceStates = false "= true, if absolute variables of body object shall be used as states (StateSelect.always)";
          parameter Boolean useQuaternions = true "= true, if quaternions shall be used as potential states otherwise use 3 angles as potential states";
          parameter Types.RotationSequence sequence_angleStates = {1, 2, 3} "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states" annotation(Evaluate = true);
          final parameter SI.Mass mo(min = 0) = density * length * width * height "Mass of box without hole";
          final parameter SI.Mass mi(min = 0) = density * length * innerWidth * innerHeight "Mass of hole of box";
          final parameter SI.Mass m(min = 0) = mo - mi "Mass of box";
          final parameter Frames.Orientation R = Frames.from_nxy(r, widthDirection) "Orientation object from frame_a to coordinates system spanned by r and widthDirection";
          final parameter SI.Position[3] r_CM = r_shape + normalizeWithAssert(lengthDirection) * length / 2 "Position vector from origin of frame_a to center of mass, resolved in frame_a";
          final parameter SI.Inertia[3, 3] I = Frames.resolveDyade1(R, diagonal({mo * (width * width + height * height) - mi * (innerWidth * innerWidth + innerHeight * innerHeight), mo * (length * length + height * height) - mi * (length * length + innerHeight * innerHeight), mo * (length * length + width * width) - mi * (length * length + innerWidth * innerWidth)} / 12)) "Inertia tensor of body box with respect to center of mass, parallel to frame_a";
          Body body(animation = false, r_CM = r_CM, m = m, I_11 = I[1, 1], I_22 = I[2, 2], I_33 = I[3, 3], I_21 = I[2, 1], I_31 = I[3, 1], I_32 = I[3, 2], sequence_start = sequence_start, angles_fixed = angles_fixed, angles_start = angles_start, w_0_fixed = w_0_fixed, w_0_start = w_0_start, z_0_fixed = z_0_fixed, z_0_start = z_0_start, useQuaternions = useQuaternions, sequence_angleStates = sequence_angleStates, enforceStates = false);
          FixedTranslation frameTranslation(r = r, animation = animation, shapeType = "box", r_shape = r_shape, lengthDirection = lengthDirection, widthDirection = widthDirection, length = length, width = width, height = height, color = color, specularCoefficient = specularCoefficient);
        protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          r_0 = frame_a.r_0;
          v_0 = der(r_0);
          a_0 = der(v_0);
          assert(innerWidth <= width, "parameter innerWidth is greater than parameter width");
          assert(innerHeight <= height, "parameter innerHeight is greater than parameter height");
          connect(frameTranslation.frame_a, frame_a);
          connect(frameTranslation.frame_b, frame_b);
          connect(frame_a, body.frame_a);
        end BodyBox;
      end Parts;

      package Visualizers  "3-dimensional visual objects used for animation" 
        extends Modelica.Icons.Package;

        package Advanced  "Visualizers that require basic knowledge about Modelica in order to use them" 
          extends Modelica.Icons.Package;

          model Arrow  "Visualizing an arrow with variable size; all data have to be set as modifiers (see info layer)" 
            import Modelica.Mechanics.MultiBody.Types;
            import Modelica.Mechanics.MultiBody.Frames;
            import T = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
            import Modelica.SIunits.Conversions.to_unit1;
            input Frames.Orientation R = Frames.nullRotation() "Orientation object to rotate the world frame into the arrow frame";
            input SI.Position[3] r = {0, 0, 0} "Position vector from origin of world frame to origin of arrow frame, resolved in world frame";
            input SI.Position[3] r_tail = {0, 0, 0} "Position vector from origin of arrow frame to arrow tail, resolved in arrow frame";
            input SI.Position[3] r_head = {0, 0, 0} "Position vector from arrow tail to the head of the arrow, resolved in arrow frame";
            input SI.Diameter diameter = world.defaultArrowDiameter "Diameter of arrow line";
            input Modelica.Mechanics.MultiBody.Types.Color color = Modelica.Mechanics.MultiBody.Types.Defaults.ArrowColor "Color of arrow";
            input Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Material property describing the reflecting of ambient light (= 0 means, that light is completely absorbed)";
          protected
            outer Modelica.Mechanics.MultiBody.World world;
            SI.Length length = Modelica.Math.Vectors.length(r_head) "Length of arrow";
            Real[3] e_x(each final unit = "1", start = {1, 0, 0}) = noEvent(if length < 1.e-10 then {1, 0, 0} else r_head / length);
            Real[3] rxvisobj(each final unit = "1") = transpose(R.T) * e_x "X-axis unit vector of shape, resolved in world frame" annotation(HideResult = true);
            SI.Position[3] rvisobj = r + T.resolve1(R.T, r_tail) "Position vector from world frame to shape frame, resolved in world frame" annotation(HideResult = true);
            SI.Length arrowLength = noEvent(max(0, length - diameter * Types.Defaults.ArrowHeadLengthFraction)) annotation(HideResult = true);
            Visualizers.Advanced.Shape arrowLine(length = arrowLength, width = diameter, height = diameter, lengthDirection = to_unit1(r_head), widthDirection = {0, 1, 0}, shapeType = "cylinder", color = color, specularCoefficient = specularCoefficient, r_shape = r_tail, r = r, R = R) if world.enableAnimation;
            Visualizers.Advanced.Shape arrowHead(length = noEvent(max(0, min(length, diameter * Types.Defaults.ArrowHeadLengthFraction))), width = noEvent(max(0, diameter * MultiBody.Types.Defaults.ArrowHeadWidthFraction)), height = noEvent(max(0, diameter * MultiBody.Types.Defaults.ArrowHeadWidthFraction)), lengthDirection = to_unit1(r_head), widthDirection = {0, 1, 0}, shapeType = "cone", color = color, specularCoefficient = specularCoefficient, r = rvisobj + rxvisobj * arrowLength, R = R) if world.enableAnimation;
          end Arrow;

          model Shape  "Visualizing an elementary object with variable size; all data have to be set as modifiers (see info layer)" 
            extends ModelicaServices.Animation.Shape;
            extends Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialShape;
          end Shape;
        end Advanced;

        package Internal  "Visualizers that will be replaced by improved versions in the future (do not use them)" 
          extends Modelica.Icons.InternalPackage;

          model Lines  "Visualizing a set of lines as cylinders with variable size, e.g., used to display characters (no Frame connector)" 
            import Modelica.Mechanics.MultiBody;
            import Modelica.Mechanics.MultiBody.Types;
            import Modelica.Mechanics.MultiBody.Frames;
            import T = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices;
            input Modelica.Mechanics.MultiBody.Frames.Orientation R = Frames.nullRotation() "Orientation object to rotate the world frame into the object frame";
            input SI.Position[3] r = {0, 0, 0} "Position vector from origin of world frame to origin of object frame, resolved in world frame";
            input SI.Position[3] r_lines = {0, 0, 0} "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
            input Real[3] n_x(each final unit = "1") = {1, 0, 0} "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
            input Real[3] n_y(each final unit = "1") = {0, 1, 0} "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
            input SI.Position[:, 2, 2] lines = zeros(0, 2, 2) "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
            input SI.Length diameter(min = 0) = 0.05 "Diameter of the cylinders defined by lines";
            input Modelica.Mechanics.MultiBody.Types.Color color = {0, 128, 255} "Color of cylinders";
            input Types.SpecularCoefficient specularCoefficient = 0.7 "Reflection of ambient light (= 0: light is completely absorbed)";
          protected
            parameter Integer n = size(lines, 1) "Number of cylinders";
            T.Orientation R_rel = T.from_nxy(n_x, n_y);
            T.Orientation R_lines = T.absoluteRotation(R.T, R_rel);
            Modelica.SIunits.Position[3] r_abs = r + T.resolve1(R.T, r_lines);
            Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape[n] cylinders(each shapeType = "cylinder", lengthDirection = {T.resolve1(R_rel, vector([lines[i, 2, :] - lines[i, 1, :]; 0])) for i in 1:n}, length = {Modelica.Math.Vectors.length(lines[i, 2, :] - lines[i, 1, :]) for i in 1:n}, r = {r_abs + T.resolve1(R_lines, vector([lines[i, 1, :]; 0])) for i in 1:n}, each width = diameter, each height = diameter, each widthDirection = {0, 1, 0}, each color = color, each R = R, each specularCoefficient = specularCoefficient);
          end Lines;
        end Internal;
      end Visualizers;

      package Types  "Constants and types with choices, especially to build menus" 
        extends Modelica.Icons.TypesPackage;
        type Axis = Modelica.Icons.TypeReal[3](each final unit = "1") "Axis vector with choices for menus" annotation(Evaluate = true);
        type AxisLabel = Modelica.Icons.TypeString "Label of axis with choices for menus";
        type RotationSequence = Modelica.Icons.TypeInteger[3](min = {1, 1, 1}, max = {3, 3, 3}) "Sequence of planar frame rotations with choices for menus" annotation(Evaluate = true);
        type Color = Modelica.Icons.TypeInteger[3](each min = 0, each max = 255) "RGB representation of color";
        type SpecularCoefficient = Modelica.Icons.TypeReal(min = 0) "Reflection of ambient light (= 0: light is completely absorbed)";
        type ShapeType = Modelica.Icons.TypeString "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
        type ShapeExtra = Modelica.Icons.TypeReal "Type of the additional data that can be defined for an elementary ShapeType";
        type ResolveInFrameB = enumeration(world "Resolve in world frame", frame_b "Resolve in frame_b", frame_resolve "Resolve in frame_resolve (frame_resolve must be connected)") "Enumeration to define the frame in which an absolute vector is resolved (world, frame_b, frame_resolve)";
        type GravityTypes = enumeration(NoGravity "No gravity field", UniformGravity "Uniform gravity field", PointGravity "Point gravity field") "Enumeration defining the type of the gravity field";

        package Defaults  "Default settings of the MultiBody library via constants" 
          extends Modelica.Icons.Package;
          constant Types.Color BodyColor = {0, 128, 255} "Default color for body shapes that have mass (light blue)";
          constant Types.Color RodColor = {155, 155, 155} "Default color for massless rod shapes (grey)";
          constant Types.Color JointColor = {255, 0, 0} "Default color for elementary joints (red)";
          constant Types.Color ForceColor = {0, 128, 0} "Default color for force arrow (dark green)";
          constant Types.Color FrameColor = {0, 0, 0} "Default color for frame axes and labels (black)";
          constant Types.Color ArrowColor = {0, 0, 255} "Default color for arrows and double arrows (blue)";
          constant Real FrameHeadLengthFraction = 5.0 "Frame arrow head length / arrow diameter";
          constant Real FrameHeadWidthFraction = 3.0 "Frame arrow head width / arrow diameter";
          constant Real FrameLabelHeightFraction = 3.0 "Height of frame label / arrow diameter";
          constant Real ArrowHeadLengthFraction = 4.0 "Arrow head length / arrow diameter";
          constant Real ArrowHeadWidthFraction = 3.0 "Arrow head width / arrow diameter";
          constant SI.Diameter BodyCylinderDiameterFraction = 3 "Default for body cylinder diameter as a fraction of body sphere diameter";
        end Defaults;
      end Types;
    end MultiBody;

    package Rotational  "Library to model 1-dimensional, rotational mechanical systems" 
      extends Modelica.Icons.Package;
      import SI = Modelica.SIunits;

      package Components  "Components for 1D rotational mechanical drive trains" 
        extends Modelica.Icons.Package;

        model Fixed  "Flange fixed in housing at a given angle" 
          parameter SI.Angle phi0 = 0 "Fixed offset angle of housing";
          Interfaces.Flange_b flange "(right) flange fixed in housing";
        equation
          flange.phi = phi0;
        end Fixed;

        model SpringDamper  "Linear 1D rotational spring and damper in parallel" 
          parameter SI.RotationalSpringConstant c(final min = 0, start = 1.0e5) "Spring constant";
          parameter SI.RotationalDampingConstant d(final min = 0, start = 0) "Damping constant";
          parameter SI.Angle phi_rel0 = 0 "Unstretched spring angle";
          extends Modelica.Mechanics.Rotational.Interfaces.PartialCompliantWithRelativeStates;
          extends Modelica.Thermal.HeatTransfer.Interfaces.PartialElementaryConditionalHeatPortWithoutT;
        protected
          Modelica.SIunits.Torque tau_c "Spring torque";
          Modelica.SIunits.Torque tau_d "Damping torque";
        equation
          tau_c = c * (phi_rel - phi_rel0);
          tau_d = d * w_rel;
          tau = tau_c + tau_d;
          lossPower = tau_d * w_rel;
        end SpringDamper;
      end Components;

      package Sources  "Sources to drive 1D rotational mechanical components" 
        extends Modelica.Icons.SourcesPackage;

        model ConstantTorque  "Constant torque, not dependent on speed" 
          extends Rotational.Interfaces.PartialTorque;
          parameter Modelica.SIunits.Torque tau_constant "Constant torque (if negative, torque is acting as load in positive direction of rotation)";
          Modelica.SIunits.AngularVelocity w "Angular velocity of flange with respect to support (= der(phi))";
          Modelica.SIunits.Torque tau "Accelerating torque acting at flange (= -flange.tau)";
        equation
          w = der(phi);
          tau = -flange.tau;
          tau = tau_constant;
        end ConstantTorque;
      end Sources;

      package Interfaces  "Connectors and partial models for 1D rotational mechanical components" 
        extends Modelica.Icons.InterfacesPackage;

        connector Flange_a  "One-dimensional rotational flange of a shaft (filled circle icon)" 
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
        end Flange_a;

        connector Flange_b  "One-dimensional rotational flange of a shaft  (non-filled circle icon)" 
          SI.Angle phi "Absolute rotation angle of flange";
          flow SI.Torque tau "Cut torque in the flange";
        end Flange_b;

        connector Support  "Support/housing of a 1-dim. rotational shaft" 
          SI.Angle phi "Absolute rotation angle of the support/housing";
          flow SI.Torque tau "Reaction torque in the support/housing";
        end Support;

        model InternalSupport  "Adapter model to utilize conditional support connector" 
          input Modelica.SIunits.Torque tau "External support torque (must be computed via torque balance in model where InternalSupport is used; = flange.tau)";
          Modelica.SIunits.Angle phi "External support angle (= flange.phi)";
          Flange_a flange "Internal support flange (must be connected to the conditional support connector for useSupport=true and to conditional fixed model for useSupport=false)";
        equation
          flange.tau = tau;
          flange.phi = phi;
        end InternalSupport;

        partial model PartialCompliantWithRelativeStates  "Partial model for the compliant connection of two rotational 1-dim. shaft flanges where the relative angle and speed are used as preferred states" 
          Modelica.SIunits.Angle phi_rel(start = 0, stateSelect = stateSelect, nominal = if phi_nominal >= Modelica.Constants.eps then phi_nominal else 1) "Relative rotation angle (= flange_b.phi - flange_a.phi)";
          Modelica.SIunits.AngularVelocity w_rel(start = 0, stateSelect = stateSelect) "Relative angular velocity (= der(phi_rel))";
          Modelica.SIunits.AngularAcceleration a_rel(start = 0) "Relative angular acceleration (= der(w_rel))";
          Modelica.SIunits.Torque tau "Torque between flanges (= flange_b.tau)";
          Flange_a flange_a "Left flange of compliant 1-dim. rotational component";
          Flange_b flange_b "Right flange of compliant 1-dim. rotational component";
          parameter SI.Angle phi_nominal(displayUnit = "rad", min = 0.0) = 1e-4 "Nominal value of phi_rel (used for scaling)";
          parameter StateSelect stateSelect = StateSelect.prefer "Priority to use phi_rel and w_rel as states" annotation(HideResult = true);
        equation
          phi_rel = flange_b.phi - flange_a.phi;
          w_rel = der(phi_rel);
          a_rel = der(w_rel);
          flange_b.tau = tau;
          flange_a.tau = -tau;
        end PartialCompliantWithRelativeStates;

        partial model PartialElementaryOneFlangeAndSupport2  "Partial model for a component with one rotational 1-dim. shaft flange and a support used for textual modeling, i.e., for elementary models" 
          parameter Boolean useSupport = false "= true, if support flange enabled, otherwise implicitly grounded" annotation(Evaluate = true, HideResult = true);
          Flange_b flange "Flange of shaft";
          Support support(phi = phi_support, tau = -flange.tau) if useSupport "Support/housing of component";
        protected
          Modelica.SIunits.Angle phi_support "Absolute angle of support flange";
        equation
          if not useSupport then
            phi_support = 0;
          end if;
        end PartialElementaryOneFlangeAndSupport2;

        partial model PartialTorque  "Partial model of a torque acting at the flange (accelerates the flange)" 
          extends Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport2;
          Modelica.SIunits.Angle phi "Angle of flange with respect to support (= flange.phi - support.phi)";
        equation
          phi = flange.phi - phi_support;
        end PartialTorque;
      end Interfaces;
    end Rotational;
  end Mechanics;

  package Thermal  "Library of thermal system components to model heat transfer and simple thermo-fluid pipe flow" 
    extends Modelica.Icons.Package;

    package HeatTransfer  "Library of 1-dimensional heat transfer with lumped elements" 
      extends Modelica.Icons.Package;

      package Interfaces  "Connectors and partial models" 
        extends Modelica.Icons.InterfacesPackage;

        partial connector HeatPort  "Thermal port for 1-dim. heat transfer" 
          Modelica.SIunits.Temperature T "Port temperature";
          flow Modelica.SIunits.HeatFlowRate Q_flow "Heat flow rate (positive if flowing from outside into the component)";
        end HeatPort;

        connector HeatPort_a  "Thermal port for 1-dim. heat transfer (filled rectangular icon)" 
          extends HeatPort;
        end HeatPort_a;

        partial model PartialElementaryConditionalHeatPortWithoutT  "Partial model to include a conditional HeatPort in order to dissipate losses, used for textual modeling, i.e., for elementary models" 
          parameter Boolean useHeatPort = false "=true, if heatPort is enabled" annotation(Evaluate = true, HideResult = true);
          Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(final Q_flow = -lossPower) if useHeatPort "Optional port to which dissipated losses are transported in form of heat";
          Modelica.SIunits.Power lossPower "Loss power leaving component via heatPort (> 0, if heat is flowing out of component)";
        end PartialElementaryConditionalHeatPortWithoutT;
      end Interfaces;
    end HeatTransfer;
  end Thermal;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices" 
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Vectors  "Library of functions operating on vectors" 
      extends Modelica.Icons.Package;

      function length  "Return length of a vector (better as norm(), if further symbolic processing is performed)" 
        extends Modelica.Icons.Function;
        input Real[:] v "Real vector";
        output Real result "Length of vector v";
      algorithm
        result := sqrt(v * v);
        annotation(Inline = true); 
      end length;

      function normalize  "Return normalized vector such that length = 1 and prevent zero-division for zero vector" 
        extends Modelica.Icons.Function;
        input Real[:] v "Real vector";
        input Real eps(min = 0.0) = 100 * Modelica.Constants.eps "if |v| < eps then result = v/eps";
        output Real[size(v, 1)] result "Input vector v normalized to length=1";
      algorithm
        result := smooth(0, if length(v) >= eps then v / length(v) else v / eps);
        annotation(Inline = true); 
      end normalize;

      function normalizeWithAssert  "Return normalized vector such that length = 1 (trigger an assert for zero vector)" 
        import Modelica.Math.Vectors.length;
        extends Modelica.Icons.Function;
        input Real[:] v "Real vector";
        output Real[size(v, 1)] result "Input vector v normalized to length=1";
      algorithm
        assert(length(v) > 0.0, "Vector v={0,0,0} shall be normalized (= v/sqrt(v*v)), but this results in a division by zero.\nProvide a non-zero vector!");
        result := v / length(v);
        annotation(Inline = true); 
      end normalizeWithAssert;
    end Vectors;

    package Icons  "Icons for Math" 
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  "Basic icon for mathematical function with y-axis on left side" end AxisLeft;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center" end AxisCenter;
    end Icons;

    function sin  "Sine" 
      extends Modelica.Math.Icons.AxisLeft;
      input Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = sin(u);
    end sin;

    function cos  "Cosine" 
      extends Modelica.Math.Icons.AxisLeft;
      input SI.Angle u;
      output Real y;
      external "builtin" y = cos(u);
    end cos;

    function asin  "Inverse sine (-1 <= u <= 1)" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output SI.Angle y;
      external "builtin" y = asin(u);
    end asin;

    function atan2  "Four quadrant inverse tangent" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      output SI.Angle y;
      external "builtin" y = atan2(u1, u2);
    end atan2;

    function exp  "Exponential, base e" 
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
    end exp;
  end Math;

  package Utilities  "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)" 
    extends Modelica.Icons.Package;

    package Internal  "Internal components that a user should usually not directly utilize" 
      extends Modelica.Icons.InternalPackage;

      partial package PartialModelicaServices  "Interfaces of components requiring a tool specific implementation" 
        extends Modelica.Icons.InternalPackage;

        package Animation  "Models and functions for 3-dim. animation" 
          extends Modelica.Icons.Package;

          partial model PartialShape  "Interface for 3D animation of elementary shapes" 
            import SI = Modelica.SIunits;
            import Modelica.Mechanics.MultiBody.Frames;
            import Modelica.Mechanics.MultiBody.Types;
            parameter Types.ShapeType shapeType = "box" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
            input Frames.Orientation R = Frames.nullRotation() "Orientation object to rotate the world frame into the object frame";
            input SI.Position[3] r = {0, 0, 0} "Position vector from origin of world frame to origin of object frame, resolved in world frame";
            input SI.Position[3] r_shape = {0, 0, 0} "Position vector from origin of object frame to shape origin, resolved in object frame";
            input Real[3] lengthDirection(each final unit = "1") = {1, 0, 0} "Vector in length direction, resolved in object frame";
            input Real[3] widthDirection(each final unit = "1") = {0, 1, 0} "Vector in width direction, resolved in object frame";
            input SI.Length length = 0 "Length of visual object";
            input SI.Length width = 0 "Width of visual object";
            input SI.Length height = 0 "Height of visual object";
            input Types.ShapeExtra extra = 0.0 "Additional size data for some of the shape types";
            input Real[3] color = {255, 0, 0} "Color of shape";
            input Types.SpecularCoefficient specularCoefficient = 0.7 "Reflection of ambient light (= 0: light is completely absorbed)";
          end PartialShape;
        end Animation;
      end PartialModelicaServices;
    end Internal;
  end Utilities;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)" 
    import SI = Modelica.SIunits;
    import NonSI = Modelica.SIunits.Conversions.NonSIunits;
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Modelica.Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant Real inf = ModelicaServices.Machine.inf "Biggest Real number such that inf and -inf are representable on the machine";
    final constant SI.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
  end Constants;

  package Icons  "Library of icons" 
    extends Icons.Package;

    partial package ExamplesPackage  "Icon for packages containing runnable examples" 
      extends Modelica.Icons.Package;
    end ExamplesPackage;

    partial package Package  "Icon for standard packages" end Package;

    partial package InterfacesPackage  "Icon for packages containing interfaces" 
      extends Modelica.Icons.Package;
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources" 
      extends Modelica.Icons.Package;
    end SourcesPackage;

    partial package TypesPackage  "Icon for packages containing type definitions" 
      extends Modelica.Icons.Package;
    end TypesPackage;

    partial package FunctionsPackage  "Icon for packages containing functions" 
      extends Modelica.Icons.Package;
    end FunctionsPackage;

    partial package IconsPackage  "Icon for packages containing icons" 
      extends Modelica.Icons.Package;
    end IconsPackage;

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)" end InternalPackage;

    partial function Function  "Icon for functions" end Function;

    partial record Record  "Icon for records" end Record;

    type TypeReal  "Icon for Real types" 
      extends Real;
    end TypeReal;

    type TypeInteger  "Icon for Integer types" 
      extends Integer;
    end TypeInteger;

    type TypeString  "Icon for String types" 
      extends String;
    end TypeString;
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992" 
    extends Modelica.Icons.Package;

    package Icons  "Icons for SIunits" 
      extends Modelica.Icons.IconsPackage;

      partial function Conversion  "Base icon for conversion functions" end Conversion;
    end Icons;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units" 
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units" 
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
      end NonSIunits;

      function to_unit1  "Change the unit of a Real number to unit=\"1\"" 
        extends Modelica.SIunits.Icons.Conversion;
        input Real r "Real number";
        output Real result(unit = "1") "Real number r with unit=\"1\"";
      algorithm
        result := r;
        annotation(Inline = true); 
      end to_unit1;
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Length = Real(final quantity = "Length", final unit = "m");
    type Position = Length;
    type Distance = Length(min = 0);
    type Height = Length(min = 0);
    type Diameter = Length(min = 0);
    type AngularVelocity = Real(final quantity = "AngularVelocity", final unit = "rad/s");
    type AngularAcceleration = Real(final quantity = "AngularAcceleration", final unit = "rad/s2");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type MomentOfInertia = Real(final quantity = "MomentOfInertia", final unit = "kg.m2");
    type Inertia = MomentOfInertia;
    type Force = Real(final quantity = "Force", final unit = "N");
    type Torque = Real(final quantity = "Torque", final unit = "N.m");
    type RotationalSpringConstant = Real(final quantity = "RotationalSpringConstant", final unit = "N.m/rad");
    type RotationalDampingConstant = Real(final quantity = "RotationalDampingConstant", final unit = "N.m.s/rad");
    type Stress = Real(final unit = "Pa");
    type ModulusOfElasticity = Stress;
    type SecondMomentOfArea = Real(final quantity = "SecondMomentOfArea", final unit = "m4");
    type Power = Real(final quantity = "Power", final unit = "W");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temperature = ThermodynamicTemperature;
    type HeatFlowRate = Real(final quantity = "Power", final unit = "W");
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    type PerUnit = Real(unit = "1");
  end SIunits;
  annotation(version = "3.2.2", versionBuild = 3, versionDate = "2016-04-03", dateModified = "2016-04-03 08:44:41Z"); 
end Modelica;

model FlexibleBeamModelica_N_2_total
  extends ScalableTestSuite.Mechanical.FlexibleBeam.ScaledExperiments.FlexibleBeamModelica_N_2;
 annotation(experiment(StopTime = 0.15, Tolerance = 1e-6));
end FlexibleBeamModelica_N_2_total;

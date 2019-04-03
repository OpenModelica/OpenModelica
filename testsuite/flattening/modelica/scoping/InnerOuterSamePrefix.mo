// name:     InnerOuterSamePrefix.mo [BUG: #2650]
// keywords: dynamic scope, lookup
// status:   correct
//
//  components with inner prefix references an outer component with
//  the same name and one variable is generated for all of them.
//

package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Animation  "Models and functions for 3-dim. animation"
    extends Modelica.Icons.Package;

    model Shape  "Different visual shapes with variable size; all data have to be set as modifiers (see info layer)"
      extends Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialShape;
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-150, -110}, {150, -140}}, lineColor = {0, 0, 0}, textString = "default")}), Documentation(info = "<html>
       <p>
       The interface of this model is documented at
       <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>.
       </p>

       </html>"));
    end Shape;
  end Animation;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 1e-015 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1e-060 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 9.999999999999999e+059 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    annotation(Documentation(info = "<html>
     <p>
     Package in which processor specific constants are defined that are needed
     by numerical algorithms. Typically these constants are not directly used,
     but indirectly via the alias definition in
     <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
     </p>
     </html>"));
  end Machine;
  annotation(Protection(access = Access.hide), preferredView = "info", version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z", revisionId = "$Id:: package.mo 6931 2013-08-14 11:38:51Z #$", uses(Modelica(version = "3.2.1")), conversion(noneFromVersion = "1.0", noneFromVersion = "1.1", noneFromVersion = "1.2"), Documentation(info = "<html>
   <p>
   This package contains a set of functions and models to be used in the
   Modelica Standard Library that requires a tool specific implementation.
   These are:
   </p>

   <ul>
   <li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Shape</a>
        provides a 3-dim. visualization of elementary
        mechanical objects. It is used in
   <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
        via inheritance.</li>

   <li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Surface</a>
        provides a 3-dim. visualization of
        moveable parameterized surface. It is used in
   <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
        via inheritance.</li>

   <li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">loadResource</a>
        provides a function to return the absolute path name of an URI or a local file name. It is used in
   <a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
        via inheritance.</li>

   <li> <a href=\"modelica://ModelicaServices.Machine\">ModelicaServices.Machine</a>
        provides a package of machine constants. It is used in
   <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

   <li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
        provides a string defining the integration method to solve differential equations in
        a clocked discretized continuous-time partition (see Modelica 3.3 language specification).
        It is not yet used in the Modelica Standard Library, but in the Modelica_Synchronous library
        that provides convenience blocks for the clock operators of Modelica version &ge; 3.3.</li>
   </ul>

   <p>
   This is the default implementation, if no tool-specific implementation is available.
   This ModelicaServices package provides only \"dummy\" models that do nothing.
   </p>

   <p>
   <b>Licensed by DLR and Dassault Syst&egrave;mes AB under the Modelica License 2</b><br>
   Copyright &copy; 2009-2013, DLR and Dassault Syst&egrave;mes AB.
   </p>

   <p>
   <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
   </p>

   </html>"));
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 2)"
  extends Modelica.Icons.Package;

  package Mechanics  "Library of 1-dim. and 3-dim. mechanical components (multi-body, rotational, translational)"
    extends Modelica.Icons.Package;

    package MultiBody  "Library to model 3-dimensional mechanical systems"
      extends Modelica.Icons.Package;

      model World  "World coordinate system + gravity field + default animation definition"
        Interfaces.Frame_b frame_b "Coordinate system fixed in the origin of the world frame" annotation(Placement(transformation(extent = {{84, -16}, {116, 16}}, rotation = 0)));
        parameter Boolean enableAnimation = true "= true, if animation of all components is enabled";
        parameter Boolean animateWorld = true "= true, if world coordinate system shall be visualized" annotation(Dialog(enable = enableAnimation));
        parameter Boolean animateGravity = true "= true, if gravity field shall be visualized (acceleration vector or field center)" annotation(Dialog(enable = enableAnimation));
        parameter .Modelica.Mechanics.MultiBody.Types.AxisLabel label1 = "x" "Label of horizontal axis in icon";
        parameter .Modelica.Mechanics.MultiBody.Types.AxisLabel label2 = "y" "Label of vertical axis in icon";
        parameter .Modelica.Mechanics.MultiBody.Types.GravityTypes gravityType = Types.GravityTypes.UniformGravity "Type of gravity field" annotation(Evaluate = true);
        parameter .Modelica.SIunits.Acceleration g = 9.81 "Constant gravity acceleration" annotation(Dialog(enable = gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity));
        parameter .Modelica.Mechanics.MultiBody.Types.Axis n = {0, -1, 0} "Direction of gravity resolved in world frame (gravity = g*n/length(n))" annotation(Evaluate = true, Dialog(enable = gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity));
        parameter Real mue(unit = "m3/s2", min = 0) = 398600000000000.0 "Gravity field constant (default = field constant of earth)" annotation(Dialog(enable = gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.PointGravity));
        parameter Boolean driveTrainMechanics3D = true "= true, if 3-dim. mechanical effects of Parts.Mounting1D/Rotor1D/BevelGear1D shall be taken into account";
        parameter .Modelica.SIunits.Distance axisLength = nominalLength / 2 "Length of world axes arrows" annotation(Dialog(tab = "Animation", group = "if animateWorld = true", enable = enableAnimation and animateWorld));
        parameter .Modelica.SIunits.Distance axisDiameter = axisLength / defaultFrameDiameterFraction "Diameter of world axes arrows" annotation(Dialog(tab = "Animation", group = "if animateWorld = true", enable = enableAnimation and animateWorld));
        parameter Boolean axisShowLabels = true "= true, if labels shall be shown" annotation(Dialog(tab = "Animation", group = "if animateWorld = true", enable = enableAnimation and animateWorld));
        input .Modelica.Mechanics.MultiBody.Types.Color axisColor_x = Types.Defaults.FrameColor "Color of x-arrow" annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animateWorld = true", enable = enableAnimation and animateWorld));
        input .Modelica.Mechanics.MultiBody.Types.Color axisColor_y = axisColor_x annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animateWorld = true", enable = enableAnimation and animateWorld));
        input .Modelica.Mechanics.MultiBody.Types.Color axisColor_z = axisColor_x "Color of z-arrow" annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animateWorld = true", enable = enableAnimation and animateWorld));
        parameter .Modelica.SIunits.Position[3] gravityArrowTail = {0, 0, 0} "Position vector from origin of world frame to arrow tail, resolved in world frame" annotation(Dialog(tab = "Animation", group = "if animateGravity = true and gravityType = UniformGravity", enable = enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity));
        parameter .Modelica.SIunits.Length gravityArrowLength = axisLength / 2 "Length of gravity arrow" annotation(Dialog(tab = "Animation", group = "if animateGravity = true and gravityType = UniformGravity", enable = enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity));
        parameter .Modelica.SIunits.Diameter gravityArrowDiameter = gravityArrowLength / defaultWidthFraction "Diameter of gravity arrow" annotation(Dialog(tab = "Animation", group = "if animateGravity = true and gravityType = UniformGravity", enable = enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity));
        input .Modelica.Mechanics.MultiBody.Types.Color gravityArrowColor = {0, 230, 0} "Color of gravity arrow" annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animateGravity = true and gravityType = UniformGravity", enable = enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity));
        parameter .Modelica.SIunits.Diameter gravitySphereDiameter = 12742000 "Diameter of sphere representing gravity center (default = mean diameter of earth)" annotation(Dialog(tab = "Animation", group = "if animateGravity = true and gravityType = PointGravity", enable = enableAnimation and animateGravity and gravityType == GravityTypes.PointGravity));
        input .Modelica.Mechanics.MultiBody.Types.Color gravitySphereColor = {0, 230, 0} "Color of gravity sphere" annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animateGravity = true and gravityType = PointGravity", enable = enableAnimation and animateGravity and gravityType == GravityTypes.PointGravity));
        parameter .Modelica.SIunits.Length nominalLength = 1 "\"Nominal\" length of multi-body system" annotation(Dialog(tab = "Defaults"));
        parameter .Modelica.SIunits.Length defaultAxisLength = nominalLength / 5 "Default for length of a frame axis (but not world frame)" annotation(Dialog(tab = "Defaults"));
        parameter .Modelica.SIunits.Length defaultJointLength = nominalLength / 10 "Default for the fixed length of a shape representing a joint" annotation(Dialog(tab = "Defaults"));
        parameter .Modelica.SIunits.Length defaultJointWidth = nominalLength / 20 "Default for the fixed width of a shape representing a joint" annotation(Dialog(tab = "Defaults"));
        parameter .Modelica.SIunits.Length defaultForceLength = nominalLength / 10 "Default for the fixed length of a shape representing a force (e.g., damper)" annotation(Dialog(tab = "Defaults"));
        parameter .Modelica.SIunits.Length defaultForceWidth = nominalLength / 20 "Default for the fixed width of a shape representing a force (e.g., spring, bushing)" annotation(Dialog(tab = "Defaults"));
        parameter .Modelica.SIunits.Length defaultBodyDiameter = nominalLength / 9 "Default for diameter of sphere representing the center of mass of a body" annotation(Dialog(tab = "Defaults"));
        parameter Real defaultWidthFraction = 20 "Default for shape width as a fraction of shape length (e.g., for Parts.FixedTranslation)" annotation(Dialog(tab = "Defaults"));
        parameter .Modelica.SIunits.Length defaultArrowDiameter = nominalLength / 40 "Default for arrow diameter (e.g., of forces, torques, sensors)" annotation(Dialog(tab = "Defaults"));
        parameter Real defaultFrameDiameterFraction = 40 "Default for arrow diameter of a coordinate system as a fraction of axis length" annotation(Dialog(tab = "Defaults"));
        parameter Real defaultSpecularCoefficient(min = 0) = 0.7 "Default reflection of ambient light (= 0: light is completely absorbed)" annotation(Dialog(tab = "Defaults"));
        parameter Real defaultN_to_m(unit = "N/m", min = 0) = 1000 "Default scaling of force arrows (length = force/defaultN_to_m)" annotation(Dialog(tab = "Defaults"));
        parameter Real defaultNm_to_m(unit = "N.m/m", min = 0) = 1000 "Default scaling of torque arrows (length = torque/defaultNm_to_m)" annotation(Dialog(tab = "Defaults"));
        function gravityAcceleration = gravityAccelerationTypes(gravityType = gravityType, g = g * Modelica.Math.Vectors.normalize(n), mue = mue);

      protected
        function gravityAccelerationTypes  "Gravity field acceleration depending on field type and position"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Position[3] r "Position vector from world frame to actual point, resolved in world frame";
          input .Modelica.Mechanics.MultiBody.Types.GravityTypes gravityType "Type of gravity field";
          input .Modelica.SIunits.Acceleration[3] g "Constant gravity acceleration, resolved in world frame, if gravityType=1";
          input Real mue(unit = "m3/s2") "Field constant of point gravity field, if gravityType=2";
          output .Modelica.SIunits.Acceleration[3] gravity "Gravity acceleration at point r, resolved in world frame";
        algorithm
          gravity := if gravityType == .Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity then g else if gravityType == .Modelica.Mechanics.MultiBody.Types.GravityTypes.PointGravity then -mue / (r * r) * r / Modelica.Math.Vectors.length(r) else zeros(3);
          annotation(Inline = true);
        end gravityAccelerationTypes;

        parameter Integer ndim = if enableAnimation and animateWorld then 1 else 0;
        parameter Integer ndim2 = if enableAnimation and animateWorld and axisShowLabels then 1 else 0;
        parameter .Modelica.SIunits.Length headLength = min(axisLength, axisDiameter * Types.Defaults.FrameHeadLengthFraction);
        parameter .Modelica.SIunits.Length headWidth = axisDiameter * Types.Defaults.FrameHeadWidthFraction;
        parameter .Modelica.SIunits.Length lineLength = max(0, axisLength - headLength);
        parameter .Modelica.SIunits.Length lineWidth = axisDiameter;
        parameter .Modelica.SIunits.Length scaledLabel = Types.Defaults.FrameLabelHeightFraction * axisDiameter;
        parameter .Modelica.SIunits.Length labelStart = 1.05 * axisLength;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape x_arrowLine(shapeType = "cylinder", length = lineLength, width = lineWidth, height = lineWidth, lengthDirection = {1, 0, 0}, widthDirection = {0, 1, 0}, color = axisColor_x, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape x_arrowHead(shapeType = "cone", length = headLength, width = headWidth, height = headWidth, lengthDirection = {1, 0, 0}, widthDirection = {0, 1, 0}, color = axisColor_x, r = {lineLength, 0, 0}, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines x_label(lines = scaledLabel * {[0, 0; 1, 1], [0, 1; 1, 0]}, diameter = axisDiameter, color = axisColor_x, r_lines = {labelStart, 0, 0}, n_x = {1, 0, 0}, n_y = {0, 1, 0}, specularCoefficient = 0) if enableAnimation and animateWorld and axisShowLabels;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape y_arrowLine(shapeType = "cylinder", length = lineLength, width = lineWidth, height = lineWidth, lengthDirection = {0, 1, 0}, widthDirection = {1, 0, 0}, color = axisColor_y, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape y_arrowHead(shapeType = "cone", length = headLength, width = headWidth, height = headWidth, lengthDirection = {0, 1, 0}, widthDirection = {1, 0, 0}, color = axisColor_y, r = {0, lineLength, 0}, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines y_label(lines = scaledLabel * {[0, 0; 1, 1.5], [0, 1.5; 0.5, 0.75]}, diameter = axisDiameter, color = axisColor_y, r_lines = {0, labelStart, 0}, n_x = {0, 1, 0}, n_y = {-1, 0, 0}, specularCoefficient = 0) if enableAnimation and animateWorld and axisShowLabels;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape z_arrowLine(shapeType = "cylinder", length = lineLength, width = lineWidth, height = lineWidth, lengthDirection = {0, 0, 1}, widthDirection = {0, 1, 0}, color = axisColor_z, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape z_arrowHead(shapeType = "cone", length = headLength, width = headWidth, height = headWidth, lengthDirection = {0, 0, 1}, widthDirection = {0, 1, 0}, color = axisColor_z, r = {0, 0, lineLength}, specularCoefficient = 0) if enableAnimation and animateWorld;
        Modelica.Mechanics.MultiBody.Visualizers.Internal.Lines z_label(lines = scaledLabel * {[0, 0; 1, 0], [0, 1; 1, 1], [0, 1; 1, 0]}, diameter = axisDiameter, color = axisColor_z, r_lines = {0, 0, labelStart}, n_x = {0, 0, 1}, n_y = {0, 1, 0}, specularCoefficient = 0) if enableAnimation and animateWorld and axisShowLabels;
        parameter .Modelica.SIunits.Length gravityHeadLength = min(gravityArrowLength, gravityArrowDiameter * Types.Defaults.ArrowHeadLengthFraction);
        parameter .Modelica.SIunits.Length gravityHeadWidth = gravityArrowDiameter * Types.Defaults.ArrowHeadWidthFraction;
        parameter .Modelica.SIunits.Length gravityLineLength = max(0, gravityArrowLength - gravityHeadLength);
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravityArrowLine(shapeType = "cylinder", length = gravityLineLength, width = gravityArrowDiameter, height = gravityArrowDiameter, lengthDirection = n, widthDirection = {0, 1, 0}, color = gravityArrowColor, r_shape = gravityArrowTail, specularCoefficient = 0) if enableAnimation and animateGravity and gravityType == Types.GravityTypes.UniformGravity;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravityArrowHead(shapeType = "cone", length = gravityHeadLength, width = gravityHeadWidth, height = gravityHeadWidth, lengthDirection = n, widthDirection = {0, 1, 0}, color = gravityArrowColor, r_shape = gravityArrowTail + Modelica.Math.Vectors.normalize(n) * gravityLineLength, specularCoefficient = 0) if enableAnimation and animateGravity and gravityType == Types.GravityTypes.UniformGravity;
        parameter Integer ndim_pointGravity = if enableAnimation and animateGravity and gravityType == Types.GravityTypes.UniformGravity then 1 else 0;
        Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape gravitySphere(shapeType = "sphere", r_shape = {-gravitySphereDiameter / 2, 0, 0}, lengthDirection = {1, 0, 0}, length = gravitySphereDiameter, width = gravitySphereDiameter, height = gravitySphereDiameter, color = gravitySphereColor, specularCoefficient = 0) if enableAnimation and animateGravity and gravityType == Types.GravityTypes.PointGravity;
      equation
        Connections.root(frame_b.R);
        assert(Modelica.Math.Vectors.length(n) > 1e-010, "Parameter n of World object is wrong (length(n) > 0 required)");
        frame_b.r_0 = zeros(3);
        frame_b.R = Frames.nullRotation();
        annotation(defaultComponentName = "world", defaultComponentPrefixes = "inner", missingInnerMessage = "No \"world\" component is defined. A default world
         component with the default gravity field will be used
         (g=9.81 in negative y-axis). If this is not desired,
         drag Modelica.Mechanics.MultiBody.World into the top level of your model.", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-100, -118}, {-100, 61}}, color = {0, 0, 0}, thickness = 0.5), Polygon(points = {{-100, 100}, {-120, 60}, {-80, 60}, {-100, 100}, {-100, 100}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Line(points = {{-119, -100}, {59, -100}}, color = {0, 0, 0}, thickness = 0.5), Polygon(points = {{99, -100}, {59, -80}, {59, -120}, {99, -100}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 145}, {150, 105}}, textString = "%name", lineColor = {0, 0, 255}), Text(extent = {{95, -113}, {144, -162}}, lineColor = {0, 0, 0}, textString = "%label1"), Text(extent = {{-170, 127}, {-119, 77}}, lineColor = {0, 0, 0}, textString = "%label2"), Line(points = {{-56, 78}, {-56, -26}}, color = {0, 0, 255}), Polygon(points = {{-68, -26}, {-56, -66}, {-44, -26}, {-68, -26}}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 255}), Line(points = {{2, 78}, {2, -26}}, color = {0, 0, 255}), Polygon(points = {{-10, -26}, {2, -66}, {14, -26}, {-10, -26}}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 255}), Line(points = {{66, 80}, {66, -26}}, color = {0, 0, 255}), Polygon(points = {{54, -26}, {66, -66}, {78, -26}, {54, -26}}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 255})}), Documentation(info = "<HTML>
         <p>
         Model <b>World</b> represents a global coordinate system fixed in
         ground. This model serves several purposes:
         <ul>
         <li> It is used as <b>inertial system</b> in which
              the equations of all elements of the MultiBody library
              are defined.</li>
         <li> It is the world frame of an <b>animation window</b> in which
              all elements of the MultiBody library are visualized.</li>
         <li> It is used to define the <b>gravity field</b> in which a
              multi-body model is present. Default is a uniform gravity
              field where the gravity acceleration vector g is the
              same at every position. Additionally, a point gravity field or no
              gravity can be selected. Also, function gravityAcceleration can
              be redeclared to a user-defined function that computes the gravity
              acceleration, see example
              <a href=\"modelica://Modelica.Mechanics.MultiBody.Examples.Elementary.UserDefinedGravityField\">Examples.Elementary.UserDefinedGravityField</a>.
              </li>
         <li> It is used to define <b>default settings</b> of animation properties
              (e.g., the diameter of a sphere representing by default
              the center of mass of a body, or the diameters of the cylinders
              representing a revolute joint).</li>
         <li> It is used to define a <b>visual representation</b> of the
              world model (= 3 coordinate axes with labels) and of the defined
              gravity field.<br>
             <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/world.png\" ALT=\"MultiBody.World\">
         </li>
         </ul>
         <p>
         Since the gravity field function is required from all bodies with mass
         and the default settings of animation properties are required
         from nearly every component, exactly one instance of model World needs
         to be present in every model on the top level. The basic declaration
         needs to be:
         </p>
         <pre>
             <b>inner</b> Modelica.Mechanics.MultiBody.World world
         </pre>
         <p>
         Note, it must be an <b>inner</b> declaration with instance name <b>world</b>
         in order that this world object can be accessed from all objects in the
         model. When dragging the \"World\" object from the package browser into
         the diagram layer, this declaration is automatically generated
         (this is defined via annotations in model World).
         </p>
         <p>
         All vectors and tensors of a mechanical system are resolved in a
         frame that is local to the corresponding component. Usually,
         if all relative joint coordinates vanish, the local frames
         of all components are parallel to each other, as well as to the
         world frame (this holds as long as a Parts.FixedRotation,
         component is <b>not</b> used). In this \"reference configuration\"
         it is therefore
         alternatively possible to resolve all vectors in the world
         frame, since all frames are parallel to each other.
         This is often very convenient. In order to give some visual
         support in such a situation, in the icon of a World instance
         two axes of the world frame are shown and the labels
         of these axes can be set via parameters.
         </p>
         </html>"));
      end World;

      package Frames  "Functions to transform rotational frame quantities"
        extends Modelica.Icons.Package;

        record Orientation  "Orientation object defining rotation from a frame 1 into a frame 2"
          extends Modelica.Icons.Record;
          Real[3, 3] T "Transformation matrix from world frame to local frame";
          .Modelica.SIunits.AngularVelocity[3] w "Absolute angular velocity of local frame, resolved in local frame";

          encapsulated function equalityConstraint  "Return the constraint residues to express that two frames have the same orientation"
            extends .Modelica.Icons.Function;
            input .Modelica.Mechanics.MultiBody.Frames.Orientation R1 "Orientation object to rotate frame 0 into frame 1";
            input .Modelica.Mechanics.MultiBody.Frames.Orientation R2 "Orientation object to rotate frame 0 into frame 2";
            output Real[3] residue "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)";
          algorithm
            residue := {.Modelica.Math.atan2(cross(R1.T[1, :], R1.T[2, :]) * R2.T[2, :], R1.T[1, :] * R2.T[1, :]), .Modelica.Math.atan2(-cross(R1.T[1, :], R1.T[2, :]) * R2.T[1, :], R1.T[2, :] * R2.T[2, :]), .Modelica.Math.atan2(R1.T[2, :] * R2.T[1, :], R1.T[3, :] * R2.T[3, :])};
            annotation(Inline = true);
          end equalityConstraint;
          annotation(Documentation(info = "<html>
           <p>
           This object describes the <b>rotation</b> from a <b>frame 1</b> into a <b>frame 2</b>.
           An instance of this type should never be directly accessed but
           only with the access functions provided
           in package Modelica.Mechanics.MultiBody.Frames. As a consequence, it is not necessary to know
           the internal representation of this object as described in the next paragraphs.
           </p>
           <p>
           \"Orientation\" is defined to be a record consisting of two
           elements: \"Real T[3,3]\", the transformation matrix to rotate frame 1
           into frame 2 and \"Real w[3]\", the angular velocity of frame 2 with
           respect to frame 1, resolved in frame 2. Element \"T\"
           has the following interpretation:
           </p>
           <pre>
              Orientation R;
              <b>R.T</b> = [<b>e</b><sub>x</sub>, <b>e</b><sub>y</sub>, <b>e</b><sub>z</sub>];
                  e.g., <b>R.T</b> = [1,0,0; 0,1,0; 0,0,1]
           </pre>
           <p>
           where <b>e</b><sub>x</sub>,<b>e</b><sub>y</sub>,<b>e</b><sub>z</sub>
           are unit vectors in the direction of the x-axis, y-axis, and z-axis
           of frame 1, resolved in frame 2, respectively. Therefore, if <b>v</b><sub>1</sub>
           is vector <b>v</b> resolved in frame 1 and <b>v</b><sub>2</sub> is
           vector <b>v</b> resolved in frame 2, the following relationship holds:
           </p>
           <pre>
               <b>v</b><sub>2</sub> = <b>R.T</b> * <b>v</b><sub>1</sub>
           </pre>
           <p>
           The <b>inverse</b> orientation
           <b>R_inv.T</b> = <b>R.T</b><sup>T</sup> describes the rotation
           from frame 2 into frame 1.
           </p>
           <p>
           Since the orientation is described by 9 variables, there are
           6 constraints between these variables. These constraints
           are defined in function <b>Frames.orientationConstraint</b>.
           </p>
           <p>
           R.w is the angular velocity of frame 2 with respect to frame 1, resolved
           in frame 2. Formally, R.w is defined as:<br>
           <b>skew</b>(R.w) = R.T*<b>der</b>(transpose(R.T))
           with
           </p>
           <pre>
                        |   0   -w[3]  w[2] |
              <b>skew</b>(w) = |  w[3]   0   -w[1] |
                        | -w[2]  w[1]     0 |
           </pre>
           </html>"));
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
          extends Modelica.Icons.Function;
          input Real[3] e(each final unit = "1") "Normalized axis of rotation (must have length=1)";
          input Modelica.SIunits.Angle angle "Rotation angle to rotate frame 1 into frame 2 along axis e";
          input Modelica.SIunits.AngularVelocity der_angle "= der(angle)";
          output Orientation R "Orientation object to rotate frame 1 into frame 2";
        algorithm
          R := Orientation(T = [e] * transpose([e]) + (identity(3) - [e] * transpose([e])) * .Modelica.Math.cos(angle) - skew(e) * .Modelica.Math.sin(angle), w = e * der_angle);
          annotation(Inline = true);
        end planarRotation;

        function planarRotationAngle  "Return angle of a planar rotation, given the rotation axis and the representations of a vector in frame 1 and frame 2"
          extends Modelica.Icons.Function;
          input Real[3] e(each final unit = "1") "Normalized axis of rotation to rotate frame 1 around e into frame 2 (must have length=1)";
          input Real[3] v1 "A vector v resolved in frame 1 (shall not be parallel to e)";
          input Real[3] v2 "Vector v resolved in frame 2, i.e., v2 = resolve2(planarRotation(e,angle),v1)";
          output Modelica.SIunits.Angle angle "Rotation angle to rotate frame 1 into frame 2 along axis e in the range: -pi <= angle <= pi";
        algorithm
          angle := Modelica.Math.atan2(-cross(e, v1) * v2, v1 * v2 - e * v1 * e * v2);
          annotation(Inline = true, Documentation(info = "<HTML>
           <p>
           A call to this function of the form
           </p>
           <pre>
               Real[3]                e, v1, v2;
               Modelica.SIunits.Angle angle;
             <b>equation</b>
               angle = <b>planarRotationAngle</b>(e, v1, v2);
           </pre>
           <p>
           computes the rotation angle \"<b>angle</b>\" of a planar
           rotation along unit vector <b>e</b>, rotating frame 1 into frame 2, given
           the coordinate representations of a vector \"v\" in frame 1 (<b>v1</b>)
           and in frame 2 (<b>v2</b>). Therefore, the result of this function
           fulfills the following equation:
           </p>
           <pre>
               v2 = <b>resolve2</b>(<b>planarRotation</b>(e,angle), v1)
           </pre>
           <p>
           The rotation angle is returned in the range
           </p>
           <pre>
               -<font face=\"Symbol\">p</font> &lt;= angle &lt;= <font face=\"Symbol\">p</font>
           </pre>
           <p>
           This function makes the following assumptions on the input arguments
           </p>
           <ul>
           <li> Vector <b>e</b> has length 1, i.e., length(e) = 1</li>
           <li> Vector \"v\" is not parallel to <b>e</b>, i.e.,
                length(cross(e,v1)) &ne; 0</li>
           </ul>
           <p>
           The function does not check the above assumptions. If these
           assumptions are violated, a wrong result will be returned
           and/or a division by zero will occur.
           </p>
           </HTML>"));
        end planarRotationAngle;

        function axesRotations  "Return fixed rotation object to rotate in sequence around fixed angles along 3 axes"
          extends Modelica.Icons.Function;
          input Integer[3] sequence(min = {1, 1, 1}, max = {3, 3, 3}) = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
          input Modelica.SIunits.Angle[3] angles "Rotation angles around the axes defined in 'sequence'";
          input Modelica.SIunits.AngularVelocity[3] der_angles "= der(angles)";
          output Orientation R "Orientation object to rotate frame 1 into frame 2";
        algorithm
          R := Orientation(T = TransformationMatrices.axisRotation(sequence[3], angles[3]) * TransformationMatrices.axisRotation(sequence[2], angles[2]) * TransformationMatrices.axisRotation(sequence[1], angles[1]), w = Frames.axis(sequence[3]) * der_angles[3] + TransformationMatrices.resolve2(TransformationMatrices.axisRotation(sequence[3], angles[3]), Frames.axis(sequence[2]) * der_angles[2]) + TransformationMatrices.resolve2(TransformationMatrices.axisRotation(sequence[3], angles[3]) * TransformationMatrices.axisRotation(sequence[2], angles[2]), Frames.axis(sequence[1]) * der_angles[1]));
          annotation(Inline = true);
        end axesRotations;

        function axesRotationsAngles  "Return the 3 angles to rotate in sequence around 3 axes to construct the given orientation object"
          extends Modelica.Icons.Function;
          input Orientation R "Orientation object to rotate frame 1 into frame 2";
          input Integer[3] sequence(min = {1, 1, 1}, max = {3, 3, 3}) = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
          input .Modelica.SIunits.Angle guessAngle1 = 0 "Select angles[1] such that |angles[1] - guessAngle1| is a minimum";
          output .Modelica.SIunits.Angle[3] angles "Rotation angles around the axes defined in 'sequence' such that R=Frames.axesRotation(sequence,angles); -pi < angles[i] <= pi";
        protected
          Real[3] e1_1(each final unit = "1") "First rotation axis, resolved in frame 1";
          Real[3] e2_1a(each final unit = "1") "Second rotation axis, resolved in frame 1a";
          Real[3] e3_1(each final unit = "1") "Third rotation axis, resolved in frame 1";
          Real[3] e3_2(each final unit = "1") "Third rotation axis, resolved in frame 2";
          Real A "Coefficient A in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
          Real B "Coefficient B in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
          .Modelica.SIunits.Angle angle_1a "Solution 1 for angles[1]";
          .Modelica.SIunits.Angle angle_1b "Solution 2 for angles[1]";
          TransformationMatrices.Orientation T_1a "Orientation object to rotate frame 1 into frame 1a";
        algorithm
          assert(sequence[1] <> sequence[2] and sequence[2] <> sequence[3], "input argument 'sequence[1:3]' is not valid");
          e1_1 := if sequence[1] == 1 then {1, 0, 0} else if sequence[1] == 2 then {0, 1, 0} else {0, 0, 1};
          e2_1a := if sequence[2] == 1 then {1, 0, 0} else if sequence[2] == 2 then {0, 1, 0} else {0, 0, 1};
          e3_1 := R.T[sequence[3], :];
          e3_2 := if sequence[3] == 1 then {1, 0, 0} else if sequence[3] == 2 then {0, 1, 0} else {0, 0, 1};
          A := e2_1a * e3_1;
          B := cross(e1_1, e2_1a) * e3_1;
          if abs(A) <= 1e-012 and abs(B) <= 1e-012 then
            angles[1] := guessAngle1;
          else
            angle_1a := Modelica.Math.atan2(A, -B);
            angle_1b := Modelica.Math.atan2(-A, B);
            angles[1] := if abs(angle_1a - guessAngle1) <= abs(angle_1b - guessAngle1) then angle_1a else angle_1b;
          end if;
          T_1a := TransformationMatrices.planarRotation(e1_1, angles[1]);
          angles[2] := planarRotationAngle(e2_1a, TransformationMatrices.resolve2(T_1a, e3_1), e3_2);
          angles[3] := planarRotationAngle(e3_2, e2_1a, TransformationMatrices.resolve2(R.T, TransformationMatrices.resolve1(T_1a, e2_1a)));
          annotation(Documentation(info = "<HTML>
           <p>
           A call to this function of the form
           </p>
           <pre>
               Frames.Orientation     R;
               <b>parameter</b> Integer      sequence[3] = {1,2,3};
               Modelica.SIunits.Angle angles[3];
             <b>equation</b>
               angle = <b>axesRotationAngles</b>(R, sequence);
           </pre>
           <p>
           computes the rotation angles \"<b>angles</b>[1:3]\" to rotate frame 1
           into frame 2 along axes <b>sequence</b>[1:3], given the orientation
           object <b>R</b> from frame 1 to frame 2. Therefore, the result of
           this function fulfills the following equation:
           </p>
           <pre>
               R = <b>axesRotation</b>(sequence, angles)
           </pre>
           <p>
           The rotation angles are returned in the range
           </p>
           <pre>
               -<font face=\"Symbol\">p</font> &lt;= angles[i] &lt;= <font face=\"Symbol\">p</font>
           </pre>
           <p>
           There are <b>two solutions</b> for \"angles[1]\" in this range.
           Via the third argument <b>guessAngle1</b> (default = 0) the
           returned solution is selected such that |angles[1] - guessAngle1| is
           minimal. The orientation object R may be in a singular configuration, i.e.,
           there is an infinite number of angle values leading to the same R. The returned solution is
           selected by setting angles[1] = guessAngle1. Then angles[2]
           and angles[3] can be uniquely determined in the above range.
           </p>
           <p>
           Note, that input argument <b>sequence</b> has the restriction that
           only values 1,2,3 can be used and that sequence[1] &ne; sequence[2]
           and sequence[2] &ne; sequence[3]. Often used values are:
           </p>
           <pre>
             sequence = <b>{1,2,3}</b>  // Cardan angle sequence
                      = <b>{3,1,3}</b>  // Euler angle sequence
                      = <b>{3,2,1}</b>  // Tait-Bryan angle sequence
           </pre>
           </HTML>"));
        end axesRotationsAngles;

        function from_nxy  "Return fixed orientation object from n_x and n_y vectors"
          extends Modelica.Icons.Function;
          input Real[3] n_x(each final unit = "1") "Vector in direction of x-axis of frame 2, resolved in frame 1";
          input Real[3] n_y(each final unit = "1") "Vector in direction of y-axis of frame 2, resolved in frame 1";
          output Orientation R "Orientation object to rotate frame 1 into frame 2";
        protected
          Real abs_n_x = sqrt(n_x * n_x);
          Real[3] e_x(each final unit = "1") = if abs_n_x < 1e-010 then {1, 0, 0} else n_x / abs_n_x;
          Real[3] n_z_aux(each final unit = "1") = cross(e_x, n_y);
          Real[3] n_y_aux(each final unit = "1") = if n_z_aux * n_z_aux > 1e-006 then n_y else if abs(e_x[1]) > 1e-006 then {0, 1, 0} else {1, 0, 0};
          Real[3] e_z_aux(each final unit = "1") = cross(e_x, n_y_aux);
          Real[3] e_z(each final unit = "1") = e_z_aux / sqrt(e_z_aux * e_z_aux);
        algorithm
          R := Orientation(T = {e_x, cross(e_z, e_x), e_z}, w = zeros(3));
          annotation(Documentation(info = "<html>
           <p>
           It is assumed that the two input vectors n_x and n_y are
           resolved in frame 1 and are directed along the x and y axis
           of frame 2 (i.e., n_x and n_y are orthogonal to each other)
           The function returns the orientation object R to rotate from
           frame 1 to frame 2.
           </p>
           <p>
           The function is robust in the sense that it returns always
           an orientation object R, even if n_y is not orthogonal to n_x.
           This is performed in the following way:
           </p>
           <p>
           If n_x and n_y are not orthogonal to each other, first a unit
           vector e_y is determined that is orthogonal to n_x and is lying
           in the plane spanned by n_x and n_y. If n_x and n_y are parallel
           or nearly parallel to each other, a vector e_y is selected
           arbitrarily such that e_x and e_y are orthogonal to each other.
           </p>
           </html>"));
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
          extends Modelica.Icons.Package;

          type Orientation  "Orientation type defining rotation from a frame 1 into a frame 2 with quaternions {p1,p2,p3,p0}"
            extends Internal.QuaternionBase;

            encapsulated function equalityConstraint  "Return the constraint residues to express that two frames have the same quaternion orientation"
              extends .Modelica.Icons.Function;
              input .Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation Q1 "Quaternions orientation object to rotate frame 0 into frame 1";
              input .Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation Q2 "Quaternions orientation object to rotate frame 0 into frame 2";
              output Real[3] residue "The half of the rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (shall be zero)";
            algorithm
              residue := [Q1[4], Q1[3], -Q1[2], -Q1[1]; -Q1[3], Q1[4], Q1[1], -Q1[2]; Q1[2], -Q1[1], Q1[4], -Q1[3]] * Q2;
              annotation(Inline = true);
            end equalityConstraint;
            annotation(Documentation(info = "<html>
             <p>
             This type describes the <b>rotation</b> to rotate a frame 1 into
             a frame 2 using quaternions (also called <b>Euler parameters</b>)
             according to the following definition:
             </p>
             <pre>
                Quaternions.Orientation Q;
                Real  n[3];
                Real  phi(unit=\"rad\");
                Q = [ n*sin(phi/2)
                        cos(phi/2) ]
             </pre>
             <p>
             where \"n\" is the <b>axis of rotation</b> to rotate frame 1 into
             frame 2 and \"phi\" is the <b>rotation angle</b> for this rotation.
             Vector \"n\" is either resolved in frame 1 or in frame 2
             (the result is the same since the coordinates of \"n\" with respect to
             frame 1 are identical to its coordinates with respect to frame 2).
             </p>
             <p>
             The term \"quaternions\" is preferred over the historically
             more reasonable \"Euler parameters\" in order to not get
             confused with Modelica \"parameters\".
             </p>
             </html>"));
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
            w := 2 * [Q[4], Q[3], -Q[2], -Q[1]; -Q[3], Q[4], Q[1], -Q[2]; Q[2], -Q[1], Q[4], -Q[3]] * der_Q;
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
          annotation(Documentation(info = "<HTML>
           <p>
           Package <b>Frames.Quaternions</b> contains type definitions and
           functions to transform rotational frame quantities with quaternions.
           Functions of this package are currently only utilized in
           MultiBody.Parts.Body components, when quaternions shall be used
           as parts of the body states.
           Some functions are also used in a new Modelica package for
           B-Spline interpolation that is able to interpolate paths consisting of
           position vectors and orientation objects.
           </p>
           <h4>Content</h4>
           <p>In the table below an example is given for every function definition.
           The used variables have the following declaration:
           </p>
           <pre>
              Quaternions.Orientation Q, Q1, Q2, Q_rel, Q_inv;
              Real[3,3]   T, T_inv;
              Real[3]     v1, v2, w1, w2, n_x, n_y, n_z, res_ori, phi;
              Real[6]     res_equal;
              Real        L, angle;
           </pre>
           <table border=1 cellspacing=0 cellpadding=2>
             <tr><th><b><i>Function/type</i></b></th><th><b><i>Description</i></b></th></tr>
             <tr><td valign=\"top\"><b>Orientation Q;</b></td>
                 <td valign=\"top\">New type defining a quaternion object that describes<br>
                     the rotation of frame 1 into frame 2.
                 </td>
             </tr>
             <tr><td valign=\"top\"><b>der_Orientation</b> der_Q;</td>
                 <td valign=\"top\">New type defining the first time derivative
                    of Frames.Quaternions.Orientation.
                 </td>
             </tr>
             <tr><td valign=\"top\">res_ori = <b>orientationConstraint</b>(Q);</td>
                 <td valign=\"top\">Return the constraints between the variables of a quaternion object<br>
                 (shall be zero).</td>
             </tr>
             <tr><td valign=\"top\">w1 = <b>angularVelocity1</b>(Q, der_Q);</td>
                 <td valign=\"top\">Return angular velocity resolved in frame 1 from
                     quaternion object Q<br> and its derivative der_Q.
                </td>
             </tr>
             <tr><td valign=\"top\">w2 = <b>angularVelocity2</b>(Q, der_Q);</td>
                 <td valign=\"top\">Return angular velocity resolved in frame 2 from
                     quaternion object Q<br> and its derivative der_Q.
                </td>
             </tr>
             <tr><td valign=\"top\">v1 = <b>resolve1</b>(Q,v2);</td>
                 <td valign=\"top\">Transform vector v2 from frame 2 to frame 1.
                 </td>
             </tr>
             <tr><td valign=\"top\">v2 = <b>resolve2</b>(Q,v1);</td>
                 <td valign=\"top\">Transform vector v1 from frame 1 to frame 2.
                </td>
             </tr>
             <tr><td valign=\"top\">[v1,w1] = <b>multipleResolve1</b>(Q, [v2,w2]);</td>
                 <td valign=\"top\">Transform several vectors from frame 2 to frame 1.
                 </td>
             </tr>
             <tr><td valign=\"top\">[v2,w2] = <b>multipleResolve2</b>(Q, [v1,w1]);</td>
                 <td valign=\"top\">Transform several vectors from frame 1 to frame 2.
                 </td>
             </tr>
             <tr><td valign=\"top\">Q = <b>nullRotation</b>()</td>
                 <td valign=\"top\">Return quaternion object R that does not rotate a frame.
             </tr>
             <tr><td valign=\"top\">Q_inv = <b>inverseRotation</b>(Q);</td>
                 <td valign=\"top\">Return inverse quaternion object.
                 </td>
             </tr>
             <tr><td valign=\"top\">Q_rel = <b>relativeRotation</b>(Q1,Q2);</td>
                 <td valign=\"top\">Return relative quaternion object from two absolute
                     quaternion objects.
                 </td>
             </tr>
             <tr><td valign=\"top\">Q2 = <b>absoluteRotation</b>(Q1,Q_rel);</td>
                 <td valign=\"top\">Return absolute quaternion object from another
                     absolute<br> and a relative quaternion object.
                 </td>
             </tr>
             <tr><td valign=\"top\">Q = <b>planarRotation</b>(e, angle);</td>
                 <td valign=\"top\">Return quaternion object of a planar rotation.
                 </td>
             </tr>
             <tr><td valign=\"top\">phi = <b>smallRotation</b>(Q);</td>
                 <td valign=\"top\">Return rotation angles phi valid for a small rotation.
                 </td>
             </tr>
             <tr><td valign=\"top\">Q = <b>from_T</b>(T);</td>
                 <td valign=\"top\">Return quaternion object Q from transformation matrix T.
                 </td>
             </tr>
             <tr><td valign=\"top\">Q = <b>from_T_inv</b>(T_inv);</td>
                 <td valign=\"top\">Return quaternion object Q from inverse transformation matrix T_inv.
                 </td>
             </tr>
             <tr><td valign=\"top\">T = <b>to_T</b>(Q);</td>
                 <td valign=\"top\">Return transformation matrix T from quaternion object Q.
             </tr>
             <tr><td valign=\"top\">T_inv = <b>to_T_inv</b>(Q);</td>
                 <td valign=\"top\">Return inverse transformation matrix T_inv from quaternion object Q.
                 </td>
             </tr>
           </table>
           </HTML>"));
        end Quaternions;

        package TransformationMatrices  "Functions for transformation matrices"
          extends Modelica.Icons.Package;

          type Orientation  "Orientation type defining rotation from a frame 1 into a frame 2 with a transformation matrix"
            extends Internal.TransformationMatrix;

            encapsulated function equalityConstraint  "Return the constraint residues to express that two frames have the same orientation"
              extends .Modelica.Icons.Function;
              input .Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.Orientation T1 "Orientation object to rotate frame 0 into frame 1";
              input .Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.Orientation T2 "Orientation object to rotate frame 0 into frame 2";
              output Real[3] residue "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)";
            algorithm
              residue := {cross(T1[1, :], T1[2, :]) * T2[2, :], -cross(T1[1, :], T1[2, :]) * T2[1, :], T1[2, :] * T2[1, :]};
              annotation(Inline = true);
            end equalityConstraint;
            annotation(Documentation(info = "<html>
             <p>
             This type describes the <b>rotation</b> from a <b>frame 1</b> into a <b>frame 2</b>.
             An instance <b>R</b> of type <b>Orientation</b> has the following interpretation:
             </p>
             <pre>
                <b>T</b> = [<b>e</b><sub>x</sub>, <b>e</b><sub>y</sub>, <b>e</b><sub>z</sub>];
                    e.g., <b>T</b> = [1,0,0; 0,1,0; 0,0,1]
             </pre>
             <p>
             where <b>e</b><sub>x</sub>,<b>e</b><sub>y</sub>,<b>e</b><sub>z</sub>
             are unit vectors in the direction of the x-axis, y-axis, and z-axis
             of frame 1, resolved in frame 2, respectively. Therefore, if <b>v</b><sub>1</sub>
             is vector <b>v</b> resolved in frame 1 and <b>v</b><sub>2</sub> is
             vector <b>v</b> resolved in frame 2, the following relationship holds:
             </p>
             <pre>
                 <b>v</b><sub>2</sub> = <b>T</b> * <b>v</b><sub>1</sub>
             </pre>
             <p>
             The <b>inverse</b> orientation
             <b>T_inv</b> = <b>T</b><sup>T</sup> describes the rotation
             from frame 2 into frame 1.
             </p>
             <p>
             Since the orientation is described by 9 variables, there are
             6 constraints between these variables. These constraints
             are defined in function <b>TransformationMatrices.orientationConstraint</b>.
             </p>
             <p>
             Note, that in the MultiBody library the rotation object is
             never directly accessed but only with the access functions provided
             in package TransformationMatrices. As a consequence, other implementations of
             Rotation can be defined by adapting this package correspondingly.
             </p>
             </html>"));
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
            extends Modelica.Icons.Function;
            input Real[3] e(each final unit = "1") "Normalized axis of rotation (must have length=1)";
            input Modelica.SIunits.Angle angle "Rotation angle to rotate frame 1 into frame 2 along axis e";
            output TransformationMatrices.Orientation T "Orientation object to rotate frame 1 into frame 2";
          algorithm
            T := [e] * transpose([e]) + (identity(3) - [e] * transpose([e])) * .Modelica.Math.cos(angle) - skew(e) * .Modelica.Math.sin(angle);
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
            Real[3] e_x(each final unit = "1") = if abs_n_x < 1e-010 then {1, 0, 0} else n_x / abs_n_x;
            Real[3] n_z_aux(each final unit = "1") = cross(e_x, n_y);
            Real[3] n_y_aux(each final unit = "1") = if n_z_aux * n_z_aux > 1e-006 then n_y else if abs(e_x[1]) > 1e-006 then {0, 1, 0} else {1, 0, 0};
            Real[3] e_z_aux(each final unit = "1") = cross(e_x, n_y_aux);
            Real[3] e_z(each final unit = "1") = e_z_aux / sqrt(e_z_aux * e_z_aux);
          algorithm
            T := {e_x, cross(e_z, e_x), e_z};
            annotation(Documentation(info = "<html>
             <p>
             It is assumed that the two input vectors n_x and n_y are
             resolved in frame 1 and are directed along the x and y axis
             of frame 2 (i.e., n_x and n_y are orthogonal to each other)
             The function returns the orientation object T to rotate from
             frame 1 to frame 2.
             </p>
             <p>
             The function is robust in the sense that it returns always
             an orientation object T, even if n_y is not orthogonal to n_x.
             This is performed in the following way:
             </p>
             <p>
             If n_x and n_y are not orthogonal to each other, first a unit
             vector e_y is determined that is orthogonal to n_x and is lying
             in the plane spanned by n_x and n_y. If n_x and n_y are parallel
             or nearly parallel to each other, a vector e_y is selected
             arbitrarily such that e_x and e_y are orthogonal to each other.
             </p>
             </html>"));
          end from_nxy;
          annotation(Documentation(info = "<HTML>
           <p>
           Package <b>Frames.TransformationMatrices</b> contains type definitions and
           functions to transform rotational frame quantities using
           transformation matrices.
           </p>
           <h4>Content</h4>
           <p>In the table below an example is given for every function definition.
           The used variables have the following declaration:
           </p>
           <pre>
              Orientation T, T1, T2, T_rel, T_inv;
              Real[3]     v1, v2, w1, w2, n_x, n_y, n_z, e, e_x, res_ori, phi;
              Real[6]     res_equal;
              Real        L, angle;
           </pre>
           <table border=1 cellspacing=0 cellpadding=2>
             <tr><th><b><i>Function/type</i></b></th><th><b><i>Description</i></b></th></tr>
             <tr><td valign=\"top\"><b>Orientation T;</b></td>
                 <td valign=\"top\">New type defining an orientation object that describes<br>
                     the rotation of frame 1 into frame 2.
                 </td>
             </tr>
             <tr><td valign=\"top\"><b>der_Orientation</b> der_T;</td>
                 <td valign=\"top\">New type defining the first time derivative
                    of Frames.Orientation.
                 </td>
             </tr>
             <tr><td valign=\"top\">res_ori = <b>orientationConstraint</b>(T);</td>
                 <td valign=\"top\">Return the constraints between the variables of an orientation object<br>
                 (shall be zero).</td>
             </tr>
             <tr><td valign=\"top\">w1 = <b>angularVelocity1</b>(T, der_T);</td>
                 <td valign=\"top\">Return angular velocity resolved in frame 1 from
                     orientation object T<br> and its derivative der_T.
                </td>
             </tr>
             <tr><td valign=\"top\">w2 = <b>angularVelocity2</b>(T, der_T);</td>
                 <td valign=\"top\">Return angular velocity resolved in frame 2 from
                     orientation object T<br> and its derivative der_T.
                </td>
             </tr>
             <tr><td valign=\"top\">v1 = <b>resolve1</b>(T,v2);</td>
                 <td valign=\"top\">Transform vector v2 from frame 2 to frame 1.
                 </td>
             </tr>
             <tr><td valign=\"top\">v2 = <b>resolve2</b>(T,v1);</td>
                 <td valign=\"top\">Transform vector v1 from frame 1 to frame 2.
                </td>
             </tr>
             <tr><td valign=\"top\">[v1,w1] = <b>multipleResolve1</b>(T, [v2,w2]);</td>
                 <td valign=\"top\">Transform several vectors from frame 2 to frame 1.
                 </td>
             </tr>
             <tr><td valign=\"top\">[v2,w2] = <b>multipleResolve2</b>(T, [v1,w1]);</td>
                 <td valign=\"top\">Transform several vectors from frame 1 to frame 2.
                 </td>
             </tr>
             <tr><td valign=\"top\">D1 = <b>resolveDyade1</b>(T,D2);</td>
                 <td valign=\"top\">Transform second order tensor D2 from frame 2 to frame 1.
                 </td>
             </tr>
             <tr><td valign=\"top\">D2 = <b>resolveDyade2</b>(T,D1);</td>
                 <td valign=\"top\">Transform second order tensor D1 from frame 1 to frame 2.
                </td>
             </tr>
             <tr><td valign=\"top\">T= <b>nullRotation</b>()</td>
                 <td valign=\"top\">Return orientation object T that does not rotate a frame.
             </tr>
             <tr><td valign=\"top\">T_inv = <b>inverseRotation</b>(T);</td>
                 <td valign=\"top\">Return inverse orientation object.
                 </td>
             </tr>
             <tr><td valign=\"top\">T_rel = <b>relativeRotation</b>(T1,T2);</td>
                 <td valign=\"top\">Return relative orientation object from two absolute
                     orientation objects.
                 </td>
             </tr>
             <tr><td valign=\"top\">T2 = <b>absoluteRotation</b>(T1,T_rel);</td>
                 <td valign=\"top\">Return absolute orientation object from another
                     absolute<br> and a relative orientation object.
                 </td>
             </tr>
             <tr><td valign=\"top\">T = <b>planarRotation</b>(e, angle);</td>
                 <td valign=\"top\">Return orientation object of a planar rotation.
                 </td>
             </tr>
             <tr><td valign=\"top\">angle = <b>planarRotationAngle</b>(e, v1, v2);</td>
                 <td valign=\"top\">Return angle of a planar rotation, given the rotation axis<br>
                   and the representations of a vector in frame 1 and frame 2.
                 </td>
             </tr>
             <tr><td valign=\"top\">T = <b>axisRotation</b>(i, angle);</td>
                 <td valign=\"top\">Return orientation object T for rotation around axis i of frame 1.
                 </td>
             </tr>
             <tr><td valign=\"top\">T = <b>axesRotations</b>(sequence, angles);</td>
                 <td valign=\"top\">Return rotation object to rotate in sequence around 3 axes. Example:<br>
                     T = axesRotations({1,2,3},{90,45,-90});
                 </td>
             </tr>
             <tr><td valign=\"top\">angles = <b>axesRotationsAngles</b>(T, sequence);</td>
                 <td valign=\"top\">Return the 3 angles to rotate in sequence around 3 axes to<br>
                     construct the given orientation object.
                 </td>
             </tr>
             <tr><td valign=\"top\">phi = <b>smallRotation</b>(T);</td>
                 <td valign=\"top\">Return rotation angles phi valid for a small rotation.
                 </td>
             </tr>
             <tr><td valign=\"top\">T = <b>from_nxy</b>(n_x, n_y);</td>
                 <td valign=\"top\">Return orientation object from n_x and n_y vectors.
                 </td>
             </tr>
             <tr><td valign=\"top\">T = <b>from_nxz</b>(n_x, n_z);</td>
                 <td valign=\"top\">Return orientation object from n_x and n_z vectors.
                 </td>
             </tr>
             <tr><td valign=\"top\">R = <b>from_T</b>(T);</td>
                 <td valign=\"top\">Return orientation object R from transformation matrix T.
                 </td>
             </tr>
             <tr><td valign=\"top\">R = <b>from_T_inv</b>(T_inv);</td>
                 <td valign=\"top\">Return orientation object R from inverse transformation matrix T_inv.
                 </td>
             </tr>
             <tr><td valign=\"top\">T = <b>from_Q</b>(Q);</td>
                 <td valign=\"top\">Return orientation object T from quaternion orientation object Q.
                 </td>
             </tr>
             <tr><td valign=\"top\">T = <b>to_T</b>(R);</td>
                 <td valign=\"top\">Return transformation matrix T from orientation object R.
             </tr>
             <tr><td valign=\"top\">T_inv = <b>to_T_inv</b>(R);</td>
                 <td valign=\"top\">Return inverse transformation matrix T_inv from orientation object R.
                 </td>
             </tr>
             <tr><td valign=\"top\">Q = <b>to_Q</b>(T);</td>
                 <td valign=\"top\">Return quaternion orientation object Q from orientation object T.
                 </td>
             </tr>
             <tr><td valign=\"top\">exy = <b>to_exy</b>(T);</td>
                 <td valign=\"top\">Return [e_x, e_y] matrix of an orientation object T, <br>
                     with e_x and e_y vectors of frame 2, resolved in frame 1.
             </tr>
           </table>
           </HTML>"));
        end TransformationMatrices;

        package Internal  "Internal definitions that may be removed or changed (do not use)"
          extends Modelica.Icons.InternalPackage;
          type TransformationMatrix = Real[3, 3];
          type QuaternionBase = Real[4];

          function resolve1_der  "Derivative of function Frames.resolve1(..)"
            extends Modelica.Icons.Function;
            input Orientation R "Orientation object to rotate frame 1 into frame 2";
            input Real[3] v2 "Vector resolved in frame 2";
            input Real[3] v2_der "= der(v2)";
            output Real[3] v1_der "Derivative of vector v resolved in frame 1";
          algorithm
            v1_der := .Modelica.Mechanics.MultiBody.Frames.resolve1(R, v2_der + cross(R.w, v2));
            annotation(Inline = true);
          end resolve1_der;

          function resolve2_der  "Derivative of function Frames.resolve2(..)"
            extends Modelica.Icons.Function;
            input Orientation R "Orientation object to rotate frame 1 into frame 2";
            input Real[3] v1 "Vector resolved in frame 1";
            input Real[3] v1_der "= der(v1)";
            output Real[3] v2_der "Derivative of vector v resolved in frame 2";
          algorithm
            v2_der := .Modelica.Mechanics.MultiBody.Frames.resolve2(R, v1_der) - cross(R.w, .Modelica.Mechanics.MultiBody.Frames.resolve2(R, v1));
            annotation(Inline = true);
          end resolve2_der;
        end Internal;
        annotation(Documentation(info = "<HTML>
         <p>
         Package <b>Frames</b> contains type definitions and
         functions to transform rotational frame quantities. The basic idea is to
         hide the actual definition of an <b>orientation</b> in this package
         by providing essentially type <b>Orientation</b> together with
         <b>functions</b> operating on instances of this type.
         </p>
         <h4>Content</h4>
         <p>In the table below an example is given for every function definition.
         The used variables have the following declaration:
         </p>
         <pre>
            Frames.Orientation R, R1, R2, R_rel, R_inv;
            Real[3,3]   T, T_inv;
            Real[3]     v1, v2, w1, w2, n_x, n_y, n_z, e, e_x, res_ori, phi;
            Real[6]     res_equal;
            Real        L, angle;
         </pre>
         <table border=1 cellspacing=0 cellpadding=2>
           <tr><th><b><i>Function/type</i></b></th><th><b><i>Description</i></b></th></tr>
           <tr><td valign=\"top\"><b>Orientation R;</b></td>
               <td valign=\"top\">New type defining an orientation object that describes<br>
                   the rotation of frame 1 into frame 2.
               </td>
           </tr>
           <tr><td valign=\"top\">res_ori = <b>orientationConstraint</b>(R);</td>
               <td valign=\"top\">Return the constraints between the variables of an orientation object<br>
               (shall be zero).</td>
           </tr>
           <tr><td valign=\"top\">w1 = <b>angularVelocity1</b>(R);</td>
               <td valign=\"top\">Return angular velocity resolved in frame 1 from
                   orientation object R.
              </td>
           </tr>
           <tr><td valign=\"top\">w2 = <b>angularVelocity2</b>(R);</td>
               <td valign=\"top\">Return angular velocity resolved in frame 2 from
                   orientation object R.
              </td>
           </tr>
           <tr><td valign=\"top\">v1 = <b>resolve1</b>(R,v2);</td>
               <td valign=\"top\">Transform vector v2 from frame 2 to frame 1.
               </td>
           </tr>
           <tr><td valign=\"top\">v2 = <b>resolve2</b>(R,v1);</td>
               <td valign=\"top\">Transform vector v1 from frame 1 to frame 2.
              </td>
           </tr>
           <tr><td valign=\"top\">v2 = <b>resolveRelative</b>(v1,R1,R2);</td>
               <td valign=\"top\">Transform vector v1 from frame 1 to frame 2
                   using absolute orientation objects R1 of frame 1 and R2 of frame 2.
               </td>
           </tr>
           <tr><td valign=\"top\">D1 = <b>resolveDyade1</b>(R,D2);</td>
               <td valign=\"top\">Transform second order tensor D2 from frame 2 to frame 1.
               </td>
           </tr>
           <tr><td valign=\"top\">D2 = <b>resolveDyade2</b>(R,D1);</td>
               <td valign=\"top\">Transform second order tensor D1 from frame 1 to frame 2.
              </td>
           </tr>
           <tr><td valign=\"top\">R = <b>nullRotation</b>()</td>
               <td valign=\"top\">Return orientation object R that does not rotate a frame.
           </tr>
           <tr><td valign=\"top\">R_inv = <b>inverseRotation</b>(R);</td>
               <td valign=\"top\">Return inverse orientation object.
               </td>
           </tr>
           <tr><td valign=\"top\">R_rel = <b>relativeRotation</b>(R1,R2);</td>
               <td valign=\"top\">Return relative orientation object from two absolute
                   orientation objects.
               </td>
           </tr>
           <tr><td valign=\"top\">R2 = <b>absoluteRotation</b>(R1,R_rel);</td>
               <td valign=\"top\">Return absolute orientation object from another
                   absolute<br> and a relative orientation object.
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>planarRotation</b>(e, angle, der_angle);</td>
               <td valign=\"top\">Return orientation object of a planar rotation.
               </td>
           </tr>
           <tr><td valign=\"top\">angle = <b>planarRotationAngle</b>(e, v1, v2);</td>
               <td valign=\"top\">Return angle of a planar rotation, given the rotation axis<br>
                 and the representations of a vector in frame 1 and frame 2.
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>axisRotation</b>(axis, angle, der_angle);</td>
               <td valign=\"top\">Return orientation object R to rotate around angle along axis of frame 1.
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>axesRotations</b>(sequence, angles, der_angles);</td>
               <td valign=\"top\">Return rotation object to rotate in sequence around 3 axes. Example:<br>
                   R = axesRotations({1,2,3},{pi/2,pi/4,-pi}, zeros(3));
               </td>
           </tr>
           <tr><td valign=\"top\">angles = <b>axesRotationsAngles</b>(R, sequence);</td>
               <td valign=\"top\">Return the 3 angles to rotate in sequence around 3 axes to<br>
                   construct the given orientation object.
               </td>
           </tr>
           <tr><td valign=\"top\">phi = <b>smallRotation</b>(R);</td>
               <td valign=\"top\">Return rotation angles phi valid for a small rotation R.
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>from_nxy</b>(n_x, n_y);</td>
               <td valign=\"top\">Return orientation object from n_x and n_y vectors.
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>from_nxz</b>(n_x, n_z);</td>
               <td valign=\"top\">Return orientation object from n_x and n_z vectors.
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>from_T</b>(T,w);</td>
               <td valign=\"top\">Return orientation object R from transformation matrix T and
                   its angular velocity w.
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>from_T2</b>(T,der(T));</td>
               <td valign=\"top\">Return orientation object R from transformation matrix T and
                   its derivative der(T).
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>from_T_inv</b>(T_inv,w);</td>
               <td valign=\"top\">Return orientation object R from inverse transformation matrix T_inv and
                   its angular velocity w.
               </td>
           </tr>
           <tr><td valign=\"top\">R = <b>from_Q</b>(Q,w);</td>
               <td valign=\"top\">Return orientation object R from quaternion orientation object Q
                   and its angular velocity w.
               </td>
           </tr>
           <tr><td valign=\"top\">T = <b>to_T</b>(R);</td>
               <td valign=\"top\">Return transformation matrix T from orientation object R.
           </tr>
           <tr><td valign=\"top\">T_inv = <b>to_T_inv</b>(R);</td>
               <td valign=\"top\">Return inverse transformation matrix T_inv from orientation object R.
               </td>
           </tr>
           <tr><td valign=\"top\">Q = <b>to_Q</b>(R);</td>
               <td valign=\"top\">Return quaternion orientation object Q from orientation object R.
               </td>
           </tr>
           <tr><td valign=\"top\">exy = <b>to_exy</b>(R);</td>
               <td valign=\"top\">Return [e_x, e_y] matrix of an orientation object R, <br>
                   with e_x and e_y vectors of frame 2, resolved in frame 1.
           </tr>
           <tr><td valign=\"top\">L = <b>length</b>(n_x);</td>
               <td valign=\"top\">Return length L of a vector n_x.
               </td>
           </tr>
           <tr><td valign=\"top\">e_x = <b>normalize</b>(n_x);</td>
               <td valign=\"top\">Return normalized vector e_x of n_x such that length of e_x is one.
               </td>
           </tr>
           <tr><td valign=\"top\">e = <b>axis</b>(i);</td>
               <td valign=\"top\">Return unit vector e directed along axis i
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Frames.Quaternions\">Quaternions</a></td>
               <td valign=\"top\"><b>Package</b> with functions to transform rotational frame quantities based
                   on quaternions (also called Euler parameters).
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Frames.TransformationMatrices\">TransformationMatrices</a></td>
               <td valign=\"top\"><b>Package</b> with functions to transform rotational frame quantities based
                   on transformation matrices.
               </td>
           </tr>
         </table>
         </HTML>"), Icon(graphics = {Line(points = {{-2, -18}, {80, -60}}, color = {95, 95, 95}), Line(points = {{-2, -18}, {-2, 80}}, color = {95, 95, 95}), Line(points = {{-78, -56}, {-2, -18}}, color = {95, 95, 95})}));
      end Frames;

      package Interfaces  "Connectors and partial models for 3-dim. mechanical components"
        extends Modelica.Icons.InterfacesPackage;

        connector Frame  "Coordinate system fixed to the component with one cut-force and cut-torque (no icon)"
          .Modelica.SIunits.Position[3] r_0 "Position vector from world frame to the connector frame origin, resolved in world frame";
          Frames.Orientation R "Orientation object to rotate the world frame into the connector frame";
          flow .Modelica.SIunits.Force[3] f "Cut-force resolved in connector frame" annotation(unassignedMessage = "All Forces cannot be uniquely calculated.
            The reason could be that the mechanism contains
            a planar loop or that joints constrain the
            same motion. For planar loops, use for one
            revolute joint per loop the joint
            Joints.RevolutePlanarLoopConstraint instead of
            Joints.Revolute.");
          flow .Modelica.SIunits.Torque[3] t "Cut-torque resolved in connector frame";
          annotation(Documentation(info = "<html>
           <p>
           Basic definition of a coordinate system that is fixed to a mechanical
           component. In the origin of the coordinate system the cut-force
           and the cut-torque is acting. This component has no icon definition
           and is only used by inheritance from frame connectors to define
           different icons.
           </p>
           </html>"));
        end Frame;

        connector Frame_a  "Coordinate system fixed to the component with one cut-force and cut-torque (filled rectangular icon)"
          extends Frame;
          annotation(defaultComponentName = "frame_a", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.16), graphics = {Rectangle(extent = {{-10, 10}, {10, -10}}, lineColor = {95, 95, 95}, lineThickness = 0.5), Rectangle(extent = {{-30, 100}, {30, -100}}, lineColor = {0, 0, 0}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.16), graphics = {Text(extent = {{-140, -50}, {140, -88}}, lineColor = {0, 0, 0}, textString = "%name"), Rectangle(extent = {{-12, 40}, {12, -40}}, lineColor = {0, 0, 0}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
           <p>
           Basic definition of a coordinate system that is fixed to a mechanical
           component. In the origin of the coordinate system the cut-force
           and the cut-torque is acting.
           This component has a filled rectangular icon.
           </p>
           </html>"));
        end Frame_a;

        connector Frame_b  "Coordinate system fixed to the component with one cut-force and cut-torque (non-filled rectangular icon)"
          extends Frame;
          annotation(defaultComponentName = "frame_b", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.16), graphics = {Rectangle(extent = {{-10, 10}, {10, -10}}, lineColor = {95, 95, 95}, lineThickness = 0.5), Rectangle(extent = {{-30, 100}, {30, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.16), graphics = {Text(extent = {{-140, -50}, {140, -88}}, lineColor = {0, 0, 0}, textString = "%name"), Rectangle(extent = {{-12, 40}, {12, -40}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
           <p>
           Basic definition of a coordinate system that is fixed to a mechanical
           component. In the origin of the coordinate system the cut-force
           and the cut-torque is acting. This component has a non-filled rectangular icon.
           </p>
           </html>"));
        end Frame_b;
        annotation(Documentation(info = "<html>
         <p>
         This package contains connectors and partial models (i.e., models
         that are only used to build other models) of the MultiBody library.
         </p>
         </html>"));
      end Interfaces;

      package Joints  "Components that constrain the motion between two frames"
        extends Modelica.Icons.Package;

        model Revolute  "Revolute joint (1 rotational degree-of-freedom, 2 potential states, optional axis flange)"
          Modelica.Mechanics.Rotational.Interfaces.Flange_a axis if useAxisFlange "1-dim. rotational flange that drives the joint" annotation(Placement(transformation(extent = {{10, 90}, {-10, 110}}, rotation = 0)));
          Modelica.Mechanics.Rotational.Interfaces.Flange_b support if useAxisFlange "1-dim. rotational flange of the drive support (assumed to be fixed in the world frame, NOT in the joint)" annotation(Placement(transformation(extent = {{-70, 90}, {-50, 110}}, rotation = 0)));
          Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a "Coordinate system fixed to the joint with one cut-force and cut-torque" annotation(Placement(transformation(extent = {{-116, -16}, {-84, 16}}, rotation = 0)));
          Modelica.Mechanics.MultiBody.Interfaces.Frame_b frame_b "Coordinate system fixed to the joint with one cut-force and cut-torque" annotation(Placement(transformation(extent = {{84, -16}, {116, 16}}, rotation = 0)));
          parameter Boolean useAxisFlange = false "= true, if axis flange is enabled" annotation(Evaluate = true, HideResult = true, choices(checkBox = true));
          parameter Boolean animation = true "= true, if animation shall be enabled (show axis as cylinder)";
          parameter Modelica.Mechanics.MultiBody.Types.Axis n = {0, 0, 1} "Axis of rotation resolved in frame_a (= same as in frame_b)" annotation(Evaluate = true);
          constant .Modelica.SIunits.Angle phi_offset = 0 "Relative angle offset (angle = phi_offset + phi)";
          parameter .Modelica.SIunits.Distance cylinderLength = world.defaultJointLength "Length of cylinder representing the joint axis" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.SIunits.Distance cylinderDiameter = world.defaultJointWidth "Diameter of cylinder representing the joint axis" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          input Modelica.Mechanics.MultiBody.Types.Color cylinderColor = Modelica.Mechanics.MultiBody.Types.Defaults.JointColor "Color of cylinder representing the joint axis" annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animation = true", enable = animation));
          input Modelica.Mechanics.MultiBody.Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter StateSelect stateSelect = StateSelect.prefer "Priority to use joint angle phi and w=der(phi) as states" annotation(Dialog(tab = "Advanced"));
          .Modelica.SIunits.Angle phi(start = 0, final stateSelect = stateSelect) "Relative rotation angle from frame_a to frame_b" annotation(unassignedMessage = "
            The rotation angle phi of a revolute joint cannot be determined.
            Possible reasons:
            - A non-zero mass might be missing on either side of the parts
              connected to the revolute joint.
            - Too many StateSelect.always are defined and the model
              has less degrees of freedom as specified with this setting
              (remove all StateSelect.always settings).
            ");
          .Modelica.SIunits.AngularVelocity w(start = 0, stateSelect = stateSelect) "First derivative of angle phi (relative angular velocity)";
          .Modelica.SIunits.AngularAcceleration a(start = 0) "Second derivative of angle phi (relative angular acceleration)";
          .Modelica.SIunits.Torque tau "Driving torque in direction of axis of rotation";
          .Modelica.SIunits.Angle angle "= phi_offset + phi";
        protected
          outer Modelica.Mechanics.MultiBody.World world;
          parameter Real[3] e(each final unit = "1") = Modelica.Math.Vectors.normalizeWithAssert(n) "Unit vector in direction of rotation axis, resolved in frame_a (= same as in frame_b)";
          Frames.Orientation R_rel "Relative orientation object from frame_a to frame_b or from frame_b to frame_a";
          Visualizers.Advanced.Shape cylinder(shapeType = "cylinder", color = cylinderColor, specularCoefficient = specularCoefficient, length = cylinderLength, width = cylinderDiameter, height = cylinderDiameter, lengthDirection = e, widthDirection = {0, 1, 0}, r_shape = -e * cylinderLength / 2, r = frame_a.r_0, R = frame_a.R) if world.enableAnimation and animation;
          Modelica.Mechanics.Rotational.Components.Fixed fixed "support flange is fixed to ground" annotation(Placement(transformation(extent = {{-70, 70}, {-50, 90}})));
          Rotational.Interfaces.InternalSupport internalAxis(tau = tau) annotation(Placement(transformation(extent = {{-10, 90}, {10, 70}})));
          Rotational.Sources.ConstantTorque constantTorque(tau_constant = 0) if not useAxisFlange annotation(Placement(transformation(extent = {{40, 70}, {20, 90}})));
        equation
          Connections.branch(frame_a.R, frame_b.R);
          assert(cardinality(frame_a) > 0, "Connector frame_a of revolute joint is not connected");
          assert(cardinality(frame_b) > 0, "Connector frame_b of revolute joint is not connected");
          angle = phi_offset + phi;
          w = der(phi);
          a = der(w);
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
          tau = -frame_b.t * e;
          phi = internalAxis.phi;
          connect(fixed.flange, support) annotation(Line(points = {{-60, 80}, {-60, 100}}, color = {0, 0, 0}, smooth = Smooth.None));
          connect(internalAxis.flange, axis) annotation(Line(points = {{0, 80}, {0, 100}}, color = {0, 0, 0}, smooth = Smooth.None));
          connect(constantTorque.flange, internalAxis.flange) annotation(Line(points = {{20, 80}, {0, 80}}, color = {0, 0, 0}, smooth = Smooth.None));
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, -60}, {-30, 60}}, lineColor = {64, 64, 64}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {255, 255, 255}, radius = 10), Rectangle(extent = {{30, -60}, {100, 60}}, lineColor = {64, 64, 64}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {255, 255, 255}, radius = 10), Rectangle(extent = {{-100, 60}, {-30, -60}}, lineColor = {64, 64, 64}, radius = 10), Rectangle(extent = {{30, 60}, {100, -60}}, lineColor = {64, 64, 64}, radius = 10), Text(extent = {{-90, 14}, {-54, -11}}, lineColor = {128, 128, 128}, textString = "a"), Text(extent = {{51, 11}, {87, -14}}, lineColor = {128, 128, 128}, textString = "b"), Line(visible = useAxisFlange, points = {{-20, 80}, {-20, 60}}, color = {0, 0, 0}), Line(visible = useAxisFlange, points = {{20, 80}, {20, 60}}, color = {0, 0, 0}), Rectangle(visible = useAxisFlange, extent = {{-10, 100}, {10, 50}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.VerticalCylinder, fillColor = {192, 192, 192}), Polygon(visible = useAxisFlange, points = {{-10, 30}, {10, 30}, {30, 50}, {-30, 50}, {-10, 30}}, lineColor = {64, 64, 64}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-30, 11}, {30, -10}}, lineColor = {64, 64, 64}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Polygon(visible = useAxisFlange, points = {{10, 30}, {30, 50}, {30, -50}, {10, -30}, {10, 30}}, lineColor = {64, 64, 64}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, -110}, {150, -80}}, lineColor = {0, 0, 0}, textString = "n=%n"), Text(visible = useAxisFlange, extent = {{-150, -155}, {150, -115}}, textString = "%name", lineColor = {0, 0, 255}), Line(visible = useAxisFlange, points = {{-20, 70}, {-60, 70}, {-60, 60}}, color = {0, 0, 0}, smooth = Smooth.None), Line(visible = useAxisFlange, points = {{20, 70}, {50, 70}, {50, 60}}, color = {0, 0, 0}, smooth = Smooth.None), Line(visible = useAxisFlange, points = {{-90, 100}, {-30, 100}}, color = {0, 0, 0}), Line(visible = useAxisFlange, points = {{-30, 100}, {-50, 80}}, color = {0, 0, 0}), Line(visible = useAxisFlange, points = {{-49, 100}, {-70, 80}}, color = {0, 0, 0}), Line(visible = useAxisFlange, points = {{-70, 100}, {-90, 80}}, color = {0, 0, 0}), Text(visible = not useAxisFlange, extent = {{-150, 70}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>

           <p>
           Joint where frame_b rotates around axis n which is fixed in frame_a.
           The two frames coincide when the rotation angle \"phi = 0\".
           </p>

           <p>
           Optionally, two additional 1-dimensional mechanical flanges
           (flange \"axis\" represents the driving flange and
           flange \"support\" represents the bearing) can be enabled via
           parameter <b>useAxisFlange</b>. The enabled axis flange can be
           driven with elements of the
           <a href=\"modelica://Modelica.Mechanics.Rotational\">Modelica.Mechanics.Rotational</a>
           library.

           </p>

           <p>
           In the \"Advanced\" menu it can be defined via parameter <b>stateSelect</b>
           that the rotation angle \"phi\" and its derivative shall be definitely
           used as states by setting stateSelect=StateSelect.always.
           Default is StateSelect.prefer to use the joint angle and its
           derivative as preferred states. The states are usually selected automatically.
           In certain situations, especially when closed kinematic loops are present,
           it might be slightly more efficient, when using the StateSelect.always setting.
           </p>
           <p>
           If a <b>planar loop</b> is present, e.g., consisting of 4 revolute joints
           where the joint axes are all parallel to each other, then there is no
           longer a unique mathematical solution and the symbolic algorithms will
           fail. Usually, an error message will be printed pointing out this
           situation. In this case, one revolute joint of the loop has to be replaced
           by a Joints.RevolutePlanarLoopConstraint joint. The
           effect is that from the 5 constraints of a usual revolute joint,
           3 constraints are removed and replaced by appropriate known
           variables (e.g., the force in the direction of the axis of rotation is
           treated as known with value equal to zero; for standard revolute joints,
           this force is an unknown quantity).
           </p>

           <p>
           In the following figure the animation of a revolute
           joint is shown. The light blue coordinate system is
           frame_a and the dark blue coordinate system is
           frame_b of the joint. The black arrow is parameter
           vector \"n\" defining the translation axis
           (here: n = {0,0,1}, phi.start = 45<sup>o</sup>).
           </p>

           <p>
           <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/Revolute.png\">
           </p>

           </html>"));
        end Revolute;
        annotation(Documentation(info = "<HTML>
         <p>
         This package contains <b>joint components</b>,
         that is, idealized, massless elements that constrain
         the motion between frames. In subpackage <b>Assemblies</b>
         aggregation joint components are provided to handle
         kinematic loops analytically (this means that non-linear systems
         of equations occurring in these joint aggregations are analytically
         solved, i.e., robustly and efficiently).
         </p>
         <h4>Content</h4>
         <table border=1 cellspacing=0 cellpadding=2>
           <tr><th><b><i>Model</i></b></th><th><b><i>Description</i></b></th></tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.Prismatic\">Prismatic</a>
               <td valign=\"top\">Prismatic joint and actuated prismatic joint
                   (1 translational degree-of-freedom, 2 potential states)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/Prismatic.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.Revolute\">Revolute</a>
          </td>
               <td valign=\"top\">Revolute and actuated revolute joint
                   (1 rotational degree-of-freedom, 2 potential states)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/Revolute.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.Cylindrical\">Cylindrical</a></td>
               <td valign=\"top\">Cylindrical joint (2 degrees-of-freedom, 4 potential states)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/Cylindrical.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.Universal\">Universal</a></td>
               <td valign=\"top\">Universal joint (2 degrees-of-freedom, 4 potential states)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/Universal.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.Planar\">Planar</a></td>
               <td valign=\"top\">Planar joint (3 degrees-of-freedom, 6 potential states)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/Planar.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.Spherical\">Spherical</a></td>
               <td valign=\"top\">Spherical joint (3 constraints and no potential states, or 3 degrees-of-freedom and 3 states)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/Spherical.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.FreeMotion\">FreeMotion</a></td>
               <td valign=\"top\">Free motion joint (6 degrees-of-freedom, 12 potential states)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/FreeMotion.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.SphericalSpherical\">SphericalSpherical</a></td>
               <td valign=\"top\">Spherical - spherical joint aggregation (1 constraint,
                   no potential states) with an optional point mass in the middle<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/SphericalSpherical.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.UniversalSpherical\">UniversalSpherical</a></td>
               <td valign=\"top\">Universal - spherical joint aggregation (1 constraint, no potential states)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Joints/UniversalSpherical.png\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.GearConstraint\">GearConstraint</a></td>
               <td valign=\"top\">Ideal 3-dim. gearbox (arbitrary shaft directions)
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.Assemblies\">MultiBody.Joints.Assemblies</a></td>
               <td valign=\"top\"><b>Package</b> of joint aggregations for analytic loop handling.
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Joints.Constraints\">MultiBody.Joints.Constraints</a></td>
               <td valign=\"top\"><b>Package</b> of components that define joints by constraints
               </td>
           </tr>
         </table>
         </HTML>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{6, 6}, {28, -2}, {54, 80}, {32, 86}, {6, 6}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.Sphere, smooth = Smooth.None, fillColor = {255, 255, 255}), Polygon(points = {{-12, -18}, {0, -36}, {-70, -84}, {-82, -66}, {-12, -18}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.Sphere, smooth = Smooth.None, fillColor = {255, 255, 255}), Ellipse(extent = {{-12, 8}, {34, -38}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.Sphere, fillColor = {95, 95, 95})}));
      end Joints;

      package Parts  "Rigid components such as bodies with mass and inertia and massless rods"
        extends Modelica.Icons.Package;

        model FixedTranslation  "Fixed translation of frame_b with respect to frame_a"
          Interfaces.Frame_a frame_a "Coordinate system fixed to the component with one cut-force and cut-torque" annotation(Placement(transformation(extent = {{-116, -16}, {-84, 16}}, rotation = 0)));
          Interfaces.Frame_b frame_b "Coordinate system fixed to the component with one cut-force and cut-torque" annotation(Placement(transformation(extent = {{84, -16}, {116, 16}}, rotation = 0)));
          parameter Boolean animation = true "= true, if animation shall be enabled";
          parameter .Modelica.SIunits.Position[3] r(start = {0, 0, 0}) "Vector from frame_a to frame_b resolved in frame_a";
          parameter .Modelica.Mechanics.MultiBody.Types.ShapeType shapeType = "cylinder" "Type of shape" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.SIunits.Position[3] r_shape = {0, 0, 0} "Vector from frame_a to shape origin, resolved in frame_a" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.Mechanics.MultiBody.Types.Axis lengthDirection = .Modelica.SIunits.Conversions.to_unit1(r - r_shape) "Vector in length direction of shape, resolved in frame_a" annotation(Evaluate = true, Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.Mechanics.MultiBody.Types.Axis widthDirection = {0, 1, 0} "Vector in width direction of shape, resolved in frame_a" annotation(Evaluate = true, Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.SIunits.Length length = Modelica.Math.Vectors.length(r - r_shape) "Length of shape" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.SIunits.Distance width = length / world.defaultWidthFraction "Width of shape" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.SIunits.Distance height = width "Height of shape" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.Mechanics.MultiBody.Types.ShapeExtra extra = 0.0 "Additional parameter depending on shapeType (see docu of Visualizers.Advanced.Shape)" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          input .Modelica.Mechanics.MultiBody.Types.Color color = Modelica.Mechanics.MultiBody.Types.Defaults.RodColor "Color of shape" annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animation = true", enable = animation));
          input .Modelica.Mechanics.MultiBody.Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
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
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-99, 5}, {101, -5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 85}, {150, 45}}, textString = "%name", lineColor = {0, 0, 255}), Text(extent = {{150, -50}, {-150, -20}}, lineColor = {0, 0, 0}, textString = "%=r"), Text(extent = {{-89, 38}, {-53, 13}}, lineColor = {128, 128, 128}, textString = "a"), Text(extent = {{57, 39}, {93, 14}}, lineColor = {128, 128, 128}, textString = "b")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 5}, {100, -5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Line(points = {{-95, 20}, {-58, 20}}, color = {128, 128, 128}, arrow = {Arrow.None, Arrow.Filled}), Line(points = {{-94, 18}, {-94, 50}}, color = {128, 128, 128}, arrow = {Arrow.None, Arrow.Filled}), Text(extent = {{-72, 35}, {-58, 24}}, lineColor = {128, 128, 128}, textString = "x"), Text(extent = {{-113, 57}, {-98, 45}}, lineColor = {128, 128, 128}, textString = "y"), Line(points = {{-100, -4}, {-100, -69}}, color = {128, 128, 128}), Line(points = {{-100, -63}, {90, -63}}, color = {128, 128, 128}), Text(extent = {{-22, -39}, {16, -63}}, lineColor = {128, 128, 128}, textString = "r"), Polygon(points = {{88, -59}, {88, -68}, {100, -63}, {88, -59}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Line(points = {{100, -3}, {100, -68}}, color = {128, 128, 128}), Line(points = {{69, 20}, {106, 20}}, color = {128, 128, 128}, arrow = {Arrow.None, Arrow.Filled}), Line(points = {{70, 18}, {70, 50}}, color = {128, 128, 128}, arrow = {Arrow.None, Arrow.Filled}), Text(extent = {{92, 35}, {106, 24}}, lineColor = {128, 128, 128}, textString = "x"), Text(extent = {{51, 57}, {66, 45}}, lineColor = {128, 128, 128}, textString = "y")}), Documentation(info = "<HTML>
           <p>
           Component for a <b>fixed translation</b> of frame_b with respect
           to frame_a, i.e., the relationship between connectors frame_a and frame_b
           remains constant and frame_a is always <b>parallel</b> to frame_b.
           </p>
           <p>
           By default, this component is visualized by a cylinder connecting
           frame_a and frame_b, as shown in the figure below. Note, that the
           two visualized frames are not part of the component animation and that
           the animation may be switched off via parameter animation = <b>false</b>.
           </p>

           <p>
           <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/FixedTranslation.png\" ALT=\"Parts.FixedTranslation\">
           </p>
           </HTML>"));
        end FixedTranslation;

        model Body  "Rigid body with mass, inertia tensor and one frame connector (12 potential states)"
          Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a "Coordinate system fixed at body" annotation(Placement(transformation(extent = {{-116, -16}, {-84, 16}}, rotation = 0)));
          parameter Boolean animation = true "= true, if animation shall be enabled (show cylinder and sphere)";
          parameter .Modelica.SIunits.Position[3] r_CM(start = {0, 0, 0}) "Vector from frame_a to center of mass, resolved in frame_a";
          parameter .Modelica.SIunits.Mass m(min = 0, start = 1) "Mass of rigid body";
          parameter .Modelica.SIunits.Inertia I_11(min = 0) = 0.001 "(1,1) element of inertia tensor" annotation(Dialog(group = "Inertia tensor (resolved in center of mass, parallel to frame_a)"));
          parameter .Modelica.SIunits.Inertia I_22(min = 0) = 0.001 "(2,2) element of inertia tensor" annotation(Dialog(group = "Inertia tensor (resolved in center of mass, parallel to frame_a)"));
          parameter .Modelica.SIunits.Inertia I_33(min = 0) = 0.001 "(3,3) element of inertia tensor" annotation(Dialog(group = "Inertia tensor (resolved in center of mass, parallel to frame_a)"));
          parameter .Modelica.SIunits.Inertia I_21(min = -.Modelica.Constants.inf) = 0 "(2,1) element of inertia tensor" annotation(Dialog(group = "Inertia tensor (resolved in center of mass, parallel to frame_a)"));
          parameter .Modelica.SIunits.Inertia I_31(min = -.Modelica.Constants.inf) = 0 "(3,1) element of inertia tensor" annotation(Dialog(group = "Inertia tensor (resolved in center of mass, parallel to frame_a)"));
          parameter .Modelica.SIunits.Inertia I_32(min = -.Modelica.Constants.inf) = 0 "(3,2) element of inertia tensor" annotation(Dialog(group = "Inertia tensor (resolved in center of mass, parallel to frame_a)"));
          .Modelica.SIunits.Position[3] r_0(start = {0, 0, 0}, each stateSelect = if enforceStates then StateSelect.always else StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a" annotation(Dialog(tab = "Initialization", showStartAttribute = true));
          .Modelica.SIunits.Velocity[3] v_0(start = {0, 0, 0}, each stateSelect = if enforceStates then StateSelect.always else StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))" annotation(Dialog(tab = "Initialization", showStartAttribute = true));
          .Modelica.SIunits.Acceleration[3] a_0(start = {0, 0, 0}) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))" annotation(Dialog(tab = "Initialization", showStartAttribute = true));
          parameter Boolean angles_fixed = false "= true, if angles_start are used as initial values, else as guess values" annotation(Evaluate = true, choices(checkBox = true), Dialog(tab = "Initialization"));
          parameter .Modelica.SIunits.Angle[3] angles_start = {0, 0, 0} "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b" annotation(Dialog(tab = "Initialization"));
          parameter .Modelica.Mechanics.MultiBody.Types.RotationSequence sequence_start = {1, 2, 3} "Sequence of rotations to rotate frame_a into frame_b at initial time" annotation(Evaluate = true, Dialog(tab = "Initialization"));
          parameter Boolean w_0_fixed = false "= true, if w_0_start are used as initial values, else as guess values" annotation(Evaluate = true, choices(checkBox = true), Dialog(tab = "Initialization"));
          parameter .Modelica.SIunits.AngularVelocity[3] w_0_start = {0, 0, 0} "Initial or guess values of angular velocity of frame_a resolved in world frame" annotation(Dialog(tab = "Initialization"));
          parameter Boolean z_0_fixed = false "= true, if z_0_start are used as initial values, else as guess values" annotation(Evaluate = true, choices(checkBox = true), Dialog(tab = "Initialization"));
          parameter .Modelica.SIunits.AngularAcceleration[3] z_0_start = {0, 0, 0} "Initial values of angular acceleration z_0 = der(w_0)" annotation(Dialog(tab = "Initialization"));
          parameter .Modelica.SIunits.Diameter sphereDiameter = world.defaultBodyDiameter "Diameter of sphere" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          input .Modelica.Mechanics.MultiBody.Types.Color sphereColor = Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor "Color of sphere" annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animation = true", enable = animation));
          parameter .Modelica.SIunits.Diameter cylinderDiameter = sphereDiameter / .Modelica.Mechanics.MultiBody.Types.Defaults.BodyCylinderDiameterFraction "Diameter of cylinder" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          input .Modelica.Mechanics.MultiBody.Types.Color cylinderColor = sphereColor "Color of cylinder" annotation(Dialog(colorSelector = true, tab = "Animation", group = "if animation = true", enable = animation));
          input .Modelica.Mechanics.MultiBody.Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)" annotation(Dialog(tab = "Animation", group = "if animation = true", enable = animation));
          parameter Boolean enforceStates = false "= true, if absolute variables of body object shall be used as states (StateSelect.always)" annotation(Evaluate = true, Dialog(tab = "Advanced"));
          parameter Boolean useQuaternions = true "= true, if quaternions shall be used as potential states otherwise use 3 angles as potential states" annotation(Evaluate = true, Dialog(tab = "Advanced"));
          parameter .Modelica.Mechanics.MultiBody.Types.RotationSequence sequence_angleStates = {1, 2, 3} "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states" annotation(Evaluate = true, Dialog(tab = "Advanced", enable = not useQuaternions));
          final parameter .Modelica.SIunits.Inertia[3, 3] I = [I_11, I_21, I_31; I_21, I_22, I_32; I_31, I_32, I_33] "inertia tensor";
          final parameter .Modelica.Mechanics.MultiBody.Frames.Orientation R_start = Modelica.Mechanics.MultiBody.Frames.axesRotations(sequence_start, angles_start, zeros(3)) "Orientation object from world frame to frame_a at initial time";
          final parameter .Modelica.SIunits.AngularAcceleration[3] z_a_start = .Modelica.Mechanics.MultiBody.Frames.resolve2(R_start, z_0_start) "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";
          .Modelica.SIunits.AngularVelocity[3] w_a(start = .Modelica.Mechanics.MultiBody.Frames.resolve2(R_start, w_0_start), fixed = fill(w_0_fixed, 3), each stateSelect = if enforceStates then if useQuaternions then StateSelect.always else StateSelect.never else StateSelect.avoid) "Absolute angular velocity of frame_a resolved in frame_a";
          .Modelica.SIunits.AngularAcceleration[3] z_a(start = .Modelica.Mechanics.MultiBody.Frames.resolve2(R_start, z_0_start), fixed = fill(z_0_fixed, 3)) "Absolute angular acceleration of frame_a resolved in frame_a";
          .Modelica.SIunits.Acceleration[3] g_0 "Gravity acceleration resolved in world frame";
        protected
          outer Modelica.Mechanics.MultiBody.World world;
          parameter .Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation Q_start = .Modelica.Mechanics.MultiBody.Frames.to_Q(R_start) "Quaternion orientation object from world frame to frame_a at initial time";
          .Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation Q(start = Q_start, each stateSelect = if enforceStates then if useQuaternions then StateSelect.prefer else StateSelect.never else StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
          parameter .Modelica.SIunits.Angle[3] phi_start = if sequence_start[1] == sequence_angleStates[1] and sequence_start[2] == sequence_angleStates[2] and sequence_start[3] == sequence_angleStates[3] then angles_start else .Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles(R_start, sequence_angleStates) "Potential angle states at initial time";
          .Modelica.SIunits.Angle[3] phi(start = phi_start, each stateSelect = if enforceStates then if useQuaternions then StateSelect.never else StateSelect.always else StateSelect.avoid) "Dummy or 3 angles to rotate world frame into frame_a of body";
          .Modelica.SIunits.AngularVelocity[3] phi_d(each stateSelect = if enforceStates then if useQuaternions then StateSelect.never else StateSelect.always else StateSelect.avoid) "= der(phi)";
          .Modelica.SIunits.AngularAcceleration[3] phi_dd "= der(phi_d)";
          Visualizers.Advanced.Shape cylinder(shapeType = "cylinder", color = cylinderColor, specularCoefficient = specularCoefficient, length = if Modelica.Math.Vectors.length(r_CM) > sphereDiameter / 2 then Modelica.Math.Vectors.length(r_CM) - (if cylinderDiameter > 1.1 * sphereDiameter then sphereDiameter / 2 else 0) else 0, width = cylinderDiameter, height = cylinderDiameter, lengthDirection = .Modelica.SIunits.Conversions.to_unit1(r_CM), widthDirection = {0, 1, 0}, r = frame_a.r_0, R = frame_a.R) if world.enableAnimation and animation;
          Visualizers.Advanced.Shape sphere(shapeType = "sphere", color = sphereColor, specularCoefficient = specularCoefficient, length = sphereDiameter, width = sphereDiameter, height = sphereDiameter, lengthDirection = {1, 0, 0}, widthDirection = {0, 1, 0}, r_shape = r_CM - {1, 0, 0} * sphereDiameter / 2, r = frame_a.r_0, R = frame_a.R) if world.enableAnimation and animation and sphereDiameter > 0;
        initial equation
          if angles_fixed then
            if not Connections.isRoot(frame_a.R) then
              zeros(3) = .Modelica.Mechanics.MultiBody.Frames.Orientation.equalityConstraint(frame_a.R, R_start);
            elseif useQuaternions then
              zeros(3) = .Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation.equalityConstraint(Q, Q_start);
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
            frame_a.R = .Modelica.Mechanics.MultiBody.Frames.from_Q(Q, .Modelica.Mechanics.MultiBody.Frames.Quaternions.angularVelocity2(Q, der(Q)));
            {0} = .Modelica.Mechanics.MultiBody.Frames.Quaternions.orientationConstraint(Q);
            phi = zeros(3);
            phi_d = zeros(3);
            phi_dd = zeros(3);
          else
            phi_d = der(phi);
            phi_dd = der(phi_d);
            frame_a.R = .Modelica.Mechanics.MultiBody.Frames.axesRotations(sequence_angleStates, phi, phi_d);
            Q = {0, 0, 0, 1};
          end if;
          g_0 = world.gravityAcceleration(frame_a.r_0 + .Modelica.Mechanics.MultiBody.Frames.resolve1(frame_a.R, r_CM));
          v_0 = der(frame_a.r_0);
          a_0 = der(v_0);
          w_a = .Modelica.Mechanics.MultiBody.Frames.angularVelocity2(frame_a.R);
          z_a = der(w_a);
          frame_a.f = m * (.Modelica.Mechanics.MultiBody.Frames.resolve2(frame_a.R, a_0 - g_0) + cross(z_a, r_CM) + cross(w_a, cross(w_a, r_CM)));
          frame_a.t = I * z_a + cross(w_a, I * w_a) + cross(r_CM, frame_a.f);
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 30}, {-3, -31}}, lineColor = {0, 24, 48}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {0, 127, 255}, radius = 10), Text(extent = {{150, -100}, {-150, -70}}, lineColor = {0, 0, 0}, textString = "m=%m"), Text(extent = {{-150, 110}, {150, 70}}, textString = "%name", lineColor = {0, 0, 255}), Ellipse(extent = {{-20, 60}, {100, -60}}, lineColor = {0, 24, 48}, fillPattern = FillPattern.Sphere, fillColor = {0, 127, 255})}), Documentation(info = "<HTML>
           <p>
           <b>Rigid body</b> with mass and inertia tensor.
           All parameter vectors have to be resolved in frame_a.
           The <b>inertia tensor</b> has to be defined with respect to a
           coordinate system that is parallel to frame_a with the
           origin at the center of mass of the body.
           </p>
           <p>
           By default, this component is visualized by a <b>cylinder</b> located
           between frame_a and the center of mass and by a <b>sphere</b> that has
           its center at the center of mass. If the cylinder length is smaller as
           the radius of the sphere, e.g., since frame_a is located at the
           center of mass, the cylinder is not displayed. Note, that
           the animation may be switched off via parameter animation = <b>false</b>.
           </p>
           <p>
           <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Body.png\" ALT=\"Parts.Body\">
           </p>

           <p>
           <b>States of Body Components</b>
           </p>
           <p>
           Every body has potential states. If possible a tool will select
           the states of joints and not the states of bodies because this is
           usually the most efficient choice. In this case the position, orientation,
           velocity and angular velocity of frame_a of the body will be computed
           by the component that is connected to frame_a. However, if a body is moving
           freely in space, variables of the body have to be used as states. The potential
           states of the body are:
           </p>
           <ul>
           <li> The <b>position vector</b> frame_a.r_0 from the origin of the
                world frame to the origin of frame_a of the body, resolved in
                the world frame and the <b>absolute velocity</b> v_0 of the origin of
                frame_a, resolved in the world frame (= der(frame_a.r_0)).
           </li>
           <li> If parameter <b>useQuaternions</b> in the \"Advanced\" menu
                is <b>true</b> (this is the default), then <b>4 quaternions</b>
                are potential states. Additionally, the coordinates of the
                absolute angular velocity vector of the
                body are 3 potential states.<br>
                If <b>useQuaternions</b> in the \"Advanced\" menu
                is <b>false</b>, then <b>3 angles</b> and the derivatives of
                these angles are potential states. The orientation of frame_a
                is computed by rotating the world frame along the axes defined
                in parameter vector \"sequence_angleStates\" (default = {1,2,3}, i.e.,
                the Cardan angle sequence) around the angles used as potential states.
                For example, the default is to rotate the x-axis of the world frame
                around angles[1], the new y-axis around angles[2] and the new z-axis
                around angles[3], arriving at frame_a.
            </li>
           </ul>
           <p>
           The quaternions have the slight disadvantage that there is a
           non-linear constraint equation between the 4 quaternions.
           Therefore, at least one non-linear equation has to be solved
           during simulation. A tool might, however, analytically solve this
           simple constraint equation. Using the 3 angles as states has the
           disadvantage that there is a singular configuration in which a
           division by zero will occur. If it is possible to determine in advance
           for an application class that this singular configuration is outside
           of the operating region, the 3 angles might be used as potential
           states by setting <b>useQuaternions</b> = <b>false</b>.
           </p>
           <p>
           In text books about 3-dimensional mechanics often 3 angles and the
           angular velocity are used as states. This is not the case here, since
           3 angles and their derivatives are used as potential states
           (if useQuaternions = false). The reason
           is that for real-time simulation the discretization formula of the
           integrator might be \"inlined\" and solved together with the body equations.
           By appropriate symbolic transformation the performance is
           drastically increased if angles and their
           derivatives are used as states, instead of angles and the angular
           velocity.
           </p>
           <p>
           Whether or not variables of the body are used as states is usually
           automatically selected by the Modelica translator. If parameter
           <b>enforceStates</b> is set to <b>true</b> in the \"Advanced\" menu,
           then body variables are forced to be used as states according
           to the setting of parameters \"useQuaternions\" and
           \"sequence_angleStates\".
           </p>
           </HTML>"));
        end Body;

        model BodyCylinder  "Rigid body with cylinder shape. Mass and animation properties are computed from cylinder data and density (12 potential states)"
          Interfaces.Frame_a frame_a "Coordinate system fixed to the component with one cut-force and cut-torque" annotation(Placement(transformation(extent = {{-116, -16}, {-84, 16}}, rotation = 0)));
          Interfaces.Frame_b frame_b "Coordinate system fixed to the component with one cut-force and cut-torque" annotation(Placement(transformation(extent = {{84, -16}, {116, 16}}, rotation = 0)));
          parameter Boolean animation = true "= true, if animation shall be enabled (show cylinder between frame_a and frame_b)";
          parameter .Modelica.SIunits.Position[3] r(start = {0.1, 0, 0}) "Vector from frame_a to frame_b, resolved in frame_a";
          parameter .Modelica.SIunits.Position[3] r_shape = {0, 0, 0} "Vector from frame_a to cylinder origin, resolved in frame_a";
          parameter Modelica.Mechanics.MultiBody.Types.Axis lengthDirection = .Modelica.SIunits.Conversions.to_unit1(r - r_shape) "Vector in length direction of cylinder, resolved in frame_a" annotation(Evaluate = true);
          parameter .Modelica.SIunits.Length length = Modelica.Math.Vectors.length(r - r_shape) "Length of cylinder";
          parameter .Modelica.SIunits.Distance diameter = length / world.defaultWidthFraction "Diameter of cylinder";
          parameter .Modelica.SIunits.Distance innerDiameter = 0 "Inner diameter of cylinder (0 <= innerDiameter <= Diameter)";
          parameter .Modelica.SIunits.Density density = 7700 "Density of cylinder (e.g., steel: 7700 .. 7900, wood : 400 .. 800)";
          input Modelica.Mechanics.MultiBody.Types.Color color = Modelica.Mechanics.MultiBody.Types.Defaults.BodyColor "Color of cylinder" annotation(Dialog(colorSelector = true, enable = animation));
          input .Modelica.Mechanics.MultiBody.Types.SpecularCoefficient specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)" annotation(Dialog(enable = animation));
          .Modelica.SIunits.Position[3] r_0(start = {0, 0, 0}, each stateSelect = if enforceStates then StateSelect.always else StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a" annotation(Dialog(tab = "Initialization", showStartAttribute = true));
          .Modelica.SIunits.Velocity[3] v_0(start = {0, 0, 0}, each stateSelect = if enforceStates then StateSelect.always else StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))" annotation(Dialog(tab = "Initialization", showStartAttribute = true));
          .Modelica.SIunits.Acceleration[3] a_0(start = {0, 0, 0}) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))" annotation(Dialog(tab = "Initialization", showStartAttribute = true));
          parameter Boolean angles_fixed = false "= true, if angles_start are used as initial values, else as guess values" annotation(Evaluate = true, choices(checkBox = true), Dialog(tab = "Initialization"));
          parameter .Modelica.SIunits.Angle[3] angles_start = {0, 0, 0} "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b" annotation(Dialog(tab = "Initialization"));
          parameter .Modelica.Mechanics.MultiBody.Types.RotationSequence sequence_start = {1, 2, 3} "Sequence of rotations to rotate frame_a into frame_b at initial time" annotation(Evaluate = true, Dialog(tab = "Initialization"));
          parameter Boolean w_0_fixed = false "= true, if w_0_start are used as initial values, else as guess values" annotation(Evaluate = true, choices(checkBox = true), Dialog(tab = "Initialization"));
          parameter .Modelica.SIunits.AngularVelocity[3] w_0_start = {0, 0, 0} "Initial or guess values of angular velocity of frame_a resolved in world frame" annotation(Dialog(tab = "Initialization"));
          parameter Boolean z_0_fixed = false "= true, if z_0_start are used as initial values, else as guess values" annotation(Evaluate = true, choices(checkBox = true), Dialog(tab = "Initialization"));
          parameter .Modelica.SIunits.AngularAcceleration[3] z_0_start = {0, 0, 0} "Initial values of angular acceleration z_0 = der(w_0)" annotation(Dialog(tab = "Initialization"));
          parameter Boolean enforceStates = false "= true, if absolute variables of body object shall be used as states (StateSelect.always)" annotation(Dialog(tab = "Advanced"));
          parameter Boolean useQuaternions = true "= true, if quaternions shall be used as potential states otherwise use 3 angles as potential states" annotation(Dialog(tab = "Advanced"));
          parameter .Modelica.Mechanics.MultiBody.Types.RotationSequence sequence_angleStates = {1, 2, 3} "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states" annotation(Evaluate = true, Dialog(tab = "Advanced", enable = not useQuaternions));
          constant Real pi = Modelica.Constants.pi;
          final parameter .Modelica.SIunits.Distance radius = diameter / 2 "Radius of cylinder";
          final parameter .Modelica.SIunits.Distance innerRadius = innerDiameter / 2 "Inner-Radius of cylinder";
          final parameter .Modelica.SIunits.Mass mo(min = 0) = density * pi * length * radius * radius "Mass of cylinder without hole";
          final parameter .Modelica.SIunits.Mass mi(min = 0) = density * pi * length * innerRadius * innerRadius "Mass of hole of cylinder";
          final parameter .Modelica.SIunits.Inertia I22 = (mo * (length * length + 3 * radius * radius) - mi * (length * length + 3 * innerRadius * innerRadius)) / 12 "Inertia with respect to axis through center of mass, perpendicular to cylinder axis";
          final parameter .Modelica.SIunits.Mass m(min = 0) = mo - mi "Mass of cylinder";
          final parameter Frames.Orientation R = Frames.from_nxy(r, {0, 1, 0}) "Orientation object from frame_a to frame spanned by cylinder axis and axis perpendicular to cylinder axis";
          final parameter .Modelica.SIunits.Position[3] r_CM = r_shape + .Modelica.Math.Vectors.normalizeWithAssert(lengthDirection) * length / 2 "Position vector from frame_a to center of mass, resolved in frame_a";
          final parameter .Modelica.SIunits.Inertia[3, 3] I = Frames.resolveDyade1(R, diagonal({(mo * radius * radius - mi * innerRadius * innerRadius) / 2, I22, I22})) "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
          Body body(r_CM = r_CM, m = m, I_11 = I[1, 1], I_22 = I[2, 2], I_33 = I[3, 3], I_21 = I[2, 1], I_31 = I[3, 1], I_32 = I[3, 2], animation = false, sequence_start = sequence_start, angles_fixed = angles_fixed, angles_start = angles_start, w_0_fixed = w_0_fixed, w_0_start = w_0_start, z_0_fixed = z_0_fixed, z_0_start = z_0_start, useQuaternions = useQuaternions, sequence_angleStates = sequence_angleStates, enforceStates = false) annotation(Placement(transformation(extent = {{-30, -80}, {10, -40}}, rotation = 0)));
          FixedTranslation frameTranslation(r = r, animation = animation, shapeType = "pipecylinder", r_shape = r_shape, lengthDirection = lengthDirection, length = length, width = diameter, height = diameter, extra = innerDiameter / diameter, color = color, specularCoefficient = specularCoefficient, widthDirection = {0, 1, 0}) annotation(Placement(transformation(extent = {{-30, -20}, {10, 20}}, rotation = 0)));
        protected
          outer Modelica.Mechanics.MultiBody.World world;
        equation
          r_0 = frame_a.r_0;
          v_0 = der(r_0);
          a_0 = der(v_0);
          assert(innerDiameter < diameter, "parameter innerDiameter is greater than parameter diameter");
          connect(frameTranslation.frame_a, frame_a) annotation(Line(points = {{-30, 0}, {-100, 0}}, color = {95, 95, 95}, thickness = 0.5));
          connect(frameTranslation.frame_b, frame_b) annotation(Line(points = {{10, 0}, {100, 0}}, color = {95, 95, 95}, thickness = 0.5));
          connect(frame_a, body.frame_a) annotation(Line(points = {{-100, 0}, {-70, 0}, {-70, -60}, {-30, -60}}, color = {95, 95, 95}, thickness = 0.5));
          annotation(Documentation(info = "<HTML>
           <p>
           <b>Rigid body</b> with <b>cylinder</b> shape.
           The mass properties of the body (mass, center of mass,
           inertia tensor) are computed
           from the cylinder data. Optionally, the cylinder may be hollow.
           The cylinder shape is by default used in the animation.
           The two connector frames <b>frame_a</b> and <b>frame_b</b>
           are always parallel to each other. Example of component
           animation (note, that
           the animation may be switched off via parameter animation = <b>false</b>):
           </p>

           <p>
           <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/BodyCylinder.png\" ALT=\"Parts.BodyCylinder\">
           </p>

           <p>
           A BodyCylinder component has potential states. For details of these
           states and of the \"Advanced\" menu parameters, see model
           <a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.Body\">MultiBody.Parts.Body</a>.</html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-150, 90}, {150, 50}}, textString = "%name", lineColor = {0, 0, 255}), Text(extent = {{150, -80}, {-150, -50}}, lineColor = {0, 0, 0}, textString = "%=r"), Rectangle(extent = {{-100, 40}, {100, -40}}, lineColor = {0, 24, 48}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {0, 127, 255}, radius = 10), Text(extent = {{-87, 13}, {-51, -12}}, lineColor = {0, 0, 0}, textString = "a"), Text(extent = {{51, 12}, {87, -13}}, lineColor = {0, 0, 0}, textString = "b")}));
        end BodyCylinder;
        annotation(Documentation(info = "<HTML>
         <p>
         Package <b>Parts</b> contains <b>rigid components</b> of a
         multi-body system. These components may be used to build up
         more complicated structures. For example, a part may be built up of
         a \"Body\" and of several \"FixedTranslation\" components.
         </p>
         <h4>Content</h4>
         <table border=1 cellspacing=0 cellpadding=2>
           <tr><th><b><i>Model</i></b></th><th><b><i>Description</i></b></th></tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.Fixed\">Fixed</a></td>
               <td valign=\"top\">Frame fixed in world frame at a given position.
                   It is visualized with a shape, see <b>shapeType</b> below
                  (the frames on the two
                   sides do not belong to the component):<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Fixed.png\" ALT=\"model Parts.Fixed\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.FixedTranslation\">FixedTranslation</a></td>
               <td valign=\"top\">Fixed translation of frame_b with respect to frame_a.
                   It is visualized with a shape, see <b>shapeType</b> below
                   (the frames on the two sides do not belong to the component):<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/FixedTranslation.png\" ALT=\"model Parts.FixedTranslation\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.FixedRotation\">FixedRotation</a></td>
               <td valign=\"top\">Fixed translation and fixed rotation of frame_b with respect to frame_a
                   It is visualized with a shape, see <b>shapeType</b>  below
                   (the frames on the two sides do not belong to the component):<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/FixedRotation.png\" ALT=\"model Parts.FixedRotation\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.Body\">Body</a></td>
               <td valign=\"top\">Rigid body with mass, inertia tensor and one frame connector.
                   It is visualized with a cylinder and a sphere at the
                   center of mass:<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Body.png\" ALT=\"model Parts.Body\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.BodyShape\">BodyShape</a></td>
               <td valign=\"top\">Rigid body with mass, inertia tensor, different shapes
                   (see <b>shapeType</b> below)
                   for animation, and two frame connectors:<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/BodyShape.png\" ALT=\"model Parts.BodyShape\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.Fixed\">Fixed BodyBox</a></td>
               <td valign=\"top\">Rigid body with box shape (mass and animation properties are computed
                   from box data and from density):<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/BodyBox.png\" ALT=\"model Parts.BodyBox\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.BodyCylinder\">BodyCylinder</a></td>
               <td valign=\"top\">Rigid body with cylinder shape (mass and animation properties
                   are computed from cylinder data and from density):<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/BodyCylinder.png\" ALT=\"model Parts.BodyCylinder\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.PointMass\">PointMass</a></td>
               <td valign=\"top\">Rigid body where inertia tensor and rotation is neglected:<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Parts/PointMass.png\" ALT=\"model Parts.PointMass\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.Mounting1D\">Mounting1D</a></td>
               <td valign=\"top\"> Propagate 1-dim. support torque to 3-dim. system
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.Rotor1D\">Rotor1D</a></td>
               <td valign=\"top\">1D inertia attachable on 3-dim. bodies (without neglecting dynamic effects)<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Parts/Rotor1D.png\" ALT=\"model Parts.Rotor1D\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Parts.BevelGear1D\">BevelGear1D</a></td>
               <td valign=\"top\">1D gearbox with arbitrary shaft directions (3D bearing frame)
               </td>
           </tr>
         </table>
         <p>
         Components <b>Fixed</b>, <b>FixedTranslation</b>, <b>FixedRotation</b>
         and <b>BodyShape</b> are visualized according to parameter
         <b>shapeType</b>, that may have the following values (e.g., shapeType = \"box\"): <br>&nbsp;<br>
         </p>
         <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/FixedShape.png\" ALT=\"model Visualizers.FixedShape\">
         <p>
         All the details of the visualization shape parameters are
         given in
         <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.FixedShape\">Visualizers.FixedShape</a>
         </p>
         <p>
         Colors in all animation parts are defined via parameter <b>color</b>.
         This is an Integer vector with 3 elements, {r, g, b}, and specifies the
         color of the shape. {r,g,b} are the \"red\", \"green\" and \"blue\" color parts,
         given in the ranges 0 .. 255, respectively. The predefined type
         <b>MultiBody.Types.Color</b> contains a menu
         definition of the colors used in the MultiBody library
         (this will be replaced by a color editor).
         </p>
         </html>"), Icon(graphics = {Rectangle(extent = {{-80, 28}, {2, -16}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {215, 215, 215}, radius = 10), Ellipse(extent = {{-8, 52}, {86, -42}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.Sphere, fillColor = {215, 215, 215})}));
      end Parts;

      package Visualizers  "3-dimensional visual objects used for animation"
        extends Modelica.Icons.Package;

        package Advanced  "Visualizers that require basic knowledge about Modelica in order to use them"
          extends Modelica.Icons.Package;

          model Shape  "Visualizing an elementary object with variable size; all data have to be set as modifiers (see info layer)"
            extends ModelicaServices.Animation.Shape;
            extends Modelica.Utilities.Internal.PartialModelicaServices.Animation.PartialShape;
            annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, -100}, {80, 60}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-100, 60}, {-80, 100}, {100, 100}, {80, 60}, {-100, 60}}, lineColor = {0, 0, 255}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Polygon(points = {{100, 100}, {100, -60}, {80, -100}, {80, 60}, {100, 100}}, lineColor = {0, 0, 255}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid), Text(extent = {{-100, -54}, {80, 8}}, lineColor = {0, 0, 0}, textString = "%shapeType"), Text(extent = {{-150, 150}, {150, 110}}, lineColor = {0, 0, 255}, textString = "%name")}), Documentation(info = "<HTML>
             <p>
             Model <b>Shape</b> defines a visual shape that is
             shown at the location of its reference coordinate system, called
             'object frame' below. All describing variables such
             as size and color can vary dynamically (with the only exception
             of parameter shapeType). The default equations in the
             declarations should be modified by providing appropriate modifier
             equations. Model <b>Shape</b> is usually used as a basic building block to
             implement simpler to use graphical components.
             </p>
             <p>
             The following shapes are supported via
             parameter <b>shapeType</b> (e.g., shapeType=\"box\"):<br>&nbsp;
             </p>

             <p>
             <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Shape.png\" ALT=\"model Visualizers.FixedShape\">
             </p>

             <p>&nbsp;<br>
             The dark blue arrows in the figure above are directed along
             variable <b>lengthDirection</b>. The light blue arrows are directed
             along variable <b>widthDirection</b>. The <b>coordinate systems</b>
             in the figure represent frame_a of the Shape component.
             </p>

             <p>
             Additionally, <b>external shapes</b> can be specified as (not all options might be supported by all tools):
             </p>

             <ul>
             <li> <b>\"1\", \"2\", ...</b><br>
                  define external shapes specified in DXF format in files \"1.dxf\", \"2.dxf\", ...
                  The DXF-files must be found either in the current directory or in the directory where
                  the Shape instance is stored that references the DXF file.
                  This (very limited) option should not be used for new models. Example:<br>
                 shapeType=\"1\".<br></li>

             <li> \"<b>modelica:</b>//&lt;Modelica-name&gt;/&lt;relative-path-file-name&gt;\"<br>
                  characterizes the file that is stored under the location of the
                  &lt;Modelica-name&gt; library path with the given relative file name.
                  Example:<br> shapeType = \"modelica://Modelica/Resources/Data/Shapes/Engine/piston.dxf\".<br></li>

             <li> \"<b>file:</b>//&lt;absolute-file-name&gt;\"<br>
                  characterizes an absolute file name in the file system. Example:<br>
                  shapeType=\"file://C:/users/myname/shapes/piston.dxf\".</li>
             </ul>

             <p>
             The supported file formats are tool dependent. Most tools support
             at least DXF-files (a tool might support 3-dim. Face of the DXF format only),
             but may support other format as well (such as stl, obj, 3ds).
             Since visualization files contain color and other data, the corresponding
             information in the model is usually ignored.
             </p>

             <p>
             The sizes of any of the above components are specified by the
             <b>length</b>, <b>width</b> and <b>height</b> variables.
             Via variable <b>extra</b> additional data can be defined:
             </p>
             <table border=1 cellspacing=0 cellpadding=2>
             <tr><th><b>shapeType</b></th><th>Meaning of parameter <b>extra</b></th></tr>
             <tr>
               <td valign=\"top\">\"cylinder\"</td>
               <td valign=\"top\">if extra &gt; 0, a black line is included in the
                   cylinder to show the rotation of it.</td>
             </tr>
             <tr>
               <td valign=\"top\">\"cone\"</td>
               <td valign=\"top\">extra = diameter-left-side / diameter-right-side, i.e.,<br>
                   extra = 1: cylinder<br>
                   extra = 0: \"real\" cone.</td>
             </tr>
             <tr>
               <td valign=\"top\">\"pipe\"</td>
               <td valign=\"top\">extra = outer-diameter / inner-diameter, i.e, <br>
                   extra = 1: cylinder that is completely hollow<br>
                   extra = 0: cylinder without a hole.</td>
             </tr>
             <tr>
               <td valign=\"top\">\"gearwheel\"</td>
               <td valign=\"top\">extra is the number of teeth of the (external) gear.
             If extra &lt; 0, an internal gear is visualized with |extra| teeth.
             The axis of the gearwheel is along \"lengthDirection\", and usually:
             width = height = 2*radiusOfGearWheel.</td>
             </tr>
             <tr>
               <td valign=\"top\">\"spring\"</td>
               <td valign=\"top\">extra is the number of windings of the spring.
                   Additionally, \"height\" is <b>not</b> the \"height\" but
                   2*coil-width.</td>
             </tr>
             <tr>
               <td valign=\"top\">external shape</td>
               <td valign=\"top\">extra = 0: Visualization from file is not scaled.<br>
                                extra = 1: Visualization from file is scaled with \"length\", \"width\" and height\"
                                           of the shape</td>
             </tr>
             </table>
             <p>
             Parameter <b>color</b> is a vector with 3 elements,
             {r, g, b}, and specifies the color of the shape.
             {r,g,b} are the \"red\", \"green\" and \"blue\" color parts.
             Note, r g, b are given as Integer[3] in the ranges 0 .. 255,
             respectively. The predefined type
             <a href=\"modelica://Modelica.Mechanics.MultiBody.Types.Color\">MultiBody.Types.Color</a> contains a menu
             definition of the colors used in the MultiBody library together with a color editor.
             </p>

             <p>
             The variables under heading <b>Parameters</b> below
             are declared as (time varying) <b>input</b> variables.
             If the default equation is not appropriate, a corresponding
             modifier equation has to be provided in the
             model where a <b>Shape</b> instance is used, e.g., in the form
             </p>
             <pre>
                 Visualizers.Advanced.Shape shape(length = sin(time));
             </pre>
             </html>"));
          end Shape;
          annotation(Documentation(info = "<HTML>
           <p>
           Package <b>Visualizers.Advanced</b> contains components to visualize
           3-dimensional shapes with dynamical sizes. None of the components
           has a frame connector. The position and orientation is set via
           modifiers. Basic knowledge of Modelica
           is needed in order to utilize the components of this package.
           These components have also to be used for models,
           where the forces and torques in the frame connector are set via
           equations (in this case, the models of the Visualizers package cannot be used,
           since they all have frame connectors).
           </p>
           <h4>Content</h4>
           <table border=1 cellspacing=0 cellpadding=2>
             <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Arrow\">Arrow</a></td>
                 <td valign=\"top\">Visualizing an arrow where all parts of the arrow can vary dynamically:<br>
                 <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/Arrow.png\" ALT=\"model Visualizers.Advanced.Arrow\">
                 </td>
             </tr>
             <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.DoubleArrow\">DoubleArrow</a></td>
                 <td valign=\"top\">Visualizing a double arrow where all parts of the arrow can vary dynamically:<br>
                 <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/DoubleArrow.png\" ALT=\"model Visualizers.Advanced.DoubleArrow\">
                 </td>
             </tr>
             <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Shape</a></td>
                 <td valign=\"top\">Visualizing an elementary object with variable size.
                 The following shape types are supported:<br>&nbsp;<br>
                 <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/FixedShape.png\" ALT=\"model Visualizers.Advanced.Shape\">
                 </td>
             </tr>

             <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Surface</a></td>
                 <td valign=\"top\">Visualizing a moveable parameterized surface:<br>
                 <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/Surface_small.png\">
                 </td>
             </tr>

             <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.PipeWithScalarField\">PipeWithScalarField</a></td>
                 <td valign=\"top\">Visualizing a pipe with a scalar field represented by a color coding:<br>
                 <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/PipeWithScalarFieldIcon.png\">
                 </td>
             </tr>
           </table>
           </HTML>"));
        end Advanced;

        package Internal  "Visualizers that will be replaced by improved versions in the future (do not use them)"
          extends Modelica.Icons.InternalPackage;

          model Lines  "Visualizing a set of lines as cylinders with variable size, e.g., used to display characters (no Frame connector)"
            input Modelica.Mechanics.MultiBody.Frames.Orientation R = .Modelica.Mechanics.MultiBody.Frames.nullRotation() "Orientation object to rotate the world frame into the object frame" annotation();
            input .Modelica.SIunits.Position[3] r = {0, 0, 0} "Position vector from origin of world frame to origin of object frame, resolved in world frame" annotation();
            input .Modelica.SIunits.Position[3] r_lines = {0, 0, 0} "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame" annotation();
            input Real[3] n_x(each final unit = "1") = {1, 0, 0} "Vector in direction of x-axis of 'lines' frame, resolved in object frame" annotation();
            input Real[3] n_y(each final unit = "1") = {0, 1, 0} "Vector in direction of y-axis of 'lines' frame, resolved in object frame" annotation();
            input .Modelica.SIunits.Position[:, 2, 2] lines = zeros(0, 2, 2) "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}" annotation();
            input .Modelica.SIunits.Length diameter(min = 0) = 0.05 "Diameter of the cylinders defined by lines" annotation();
            input Modelica.Mechanics.MultiBody.Types.Color color = {0, 128, 255} "Color of cylinders" annotation(Dialog(colorSelector = true));
            input .Modelica.Mechanics.MultiBody.Types.SpecularCoefficient specularCoefficient = 0.7 "Reflection of ambient light (= 0: light is completely absorbed)" annotation();
          protected
            parameter Integer n = size(lines, 1) "Number of cylinders";
            .Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.Orientation R_rel = .Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.from_nxy(n_x, n_y);
            .Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.Orientation R_lines = .Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.absoluteRotation(R.T, R_rel);
            Modelica.SIunits.Position[3] r_abs = r + .Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1(R.T, r_lines);
            Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape[n] cylinders(each shapeType = "cylinder", lengthDirection = array(.Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1(R_rel, vector([lines[i, 2, :] - lines[i, 1, :]; 0])) for i in 1:n), length = array(Modelica.Math.Vectors.length(lines[i, 2, :] - lines[i, 1, :]) for i in 1:n), r = array(r_abs + .Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1(R_lines, vector([lines[i, 1, :]; 0])) for i in 1:n), each width = diameter, each height = diameter, each widthDirection = {0, 1, 0}, each color = color, each R = R, each specularCoefficient = specularCoefficient);
            annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {128, 128, 128}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-24, -34}, {-82, 40}, {-72, 46}, {-14, -26}, {-24, -34}}, lineColor = {0, 127, 255}, fillColor = {0, 127, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-82, -24}, {-20, 46}, {-10, 38}, {-72, -32}, {-82, -24}}, lineColor = {0, 127, 255}, fillColor = {0, 127, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{42, -18}, {10, 40}, {20, 48}, {50, -6}, {42, -18}}, lineColor = {0, 127, 255}, fillColor = {0, 127, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{10, -68}, {84, 48}, {96, 42}, {24, -72}, {10, -68}}, lineColor = {0, 127, 255}, fillColor = {0, 127, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 145}, {150, 105}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<HTML>
             <p>
             With model <b>Lines</b> a set of dynamic lines is defined
             that are located relatively to frame_a. Every line
             is represented by a cylinder. This allows, e.g., to define simple shaped
             3-dimensional characters. Note, if the lines are fixed relatively to frame_a,
             it is more convenient to use model <b>Visualizers.FixedLines</b>.
             An example for dynamic lines is shown in the following figure:<br>&nbsp;
             </p>
             <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/FixedLines.png\" ALT=\"model Visualizers.FixedLines\">
             <p>&nbsp;<br>
             The two letters \"x\" and \"y\" are constructed with 4 lines
             by providing the following data for input variable <b>lines</b>
             </p>
             <pre>
                lines = {[0, 0; 1, 1],[0, 1; 1, 0],[1.5, -0.5; 2.5, 1],[1.5, 1; 2, 0.25]}
             </pre>
             <p>
             Via vectors <b>n_x</b> and <b>n_y</b> a two-dimensional
             coordinate system is defined. The points defined with variable
             <b>lines</b> are with respect to this coordinate system. For example
             \"[0, 0; 1, 1]\" defines a line that starts at {0,0} and ends at {1,1}.
             The diameter and color of all line cylinders are identical
             and are defined by parameters.
             </p>

             </html>"));
          end Lines;
          annotation(Documentation(info = "<html>
           <p>
           This package contains components to construct 3-dim. fonts
           with \"cylinder\" elements for the animation window.
           This is just a temporary hack until 3-dim. fonts are supported in
           Modelica tools. The components are used to construct the \"x\", \"y\",
           \"z\" labels of coordinates systems in the animation.
           </p>
           </html>"));
        end Internal;
        annotation(Documentation(info = "<HTML>
         <p>
         Package <b>Visualizers</b> contains components to visualize
         3-dimensional shapes. These components are the basis for the
         animation features of the MultiBody library.
         </p>
         <h4>Content</h4>
         <table border=1 cellspacing=0 cellpadding=2>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.FixedShape\">FixedShape</a><br>
                      <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.FixedShape2\">FixedShape2</a></td>
               <td valign=\"top\">Visualizing an elementary shape with dynamically varying shape attributes.
               FixedShape has one connector frame_a, whereas FixedShape2 has additionally
                   a frame_b for easier connection to further visual objects.
                   The following shape types are supported:<br>&nbsp;<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/FixedShape.png\" ALT=\"model Visualizers.FixedShape\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.FixedFrame\">FixedFrame</a></td>
               <td valign=\"top\">Visualizing a coordinate system including axes labels with fixed sizes:<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/FixedFrame2.png\"
                ALT=\"model Visualizers.FixedFrame\">
               </td>
           </tr>
           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.FixedArrow\">FixedArrow</a>,<br>
         <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.SignalArrow\">SignalArrow</a></td>
               <td valign=\"top\">Visualizing an arrow. Model \"FixedArrow\" provides
               a fixed sized arrow, model \"SignalArrow\" provides
               an arrow with dynamically varying length that is defined
               by an input signal vector:<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/Arrow.png\">
               </td>
           </tr>

           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Ground\">Ground</a></td>
               <td valign=\"top\">Visualizing the x-y plane by a box:<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/GroundSmall.png\">
               </td>
           </tr>

           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Torus\">Torus</a></td>
               <td valign=\"top\">Visualizing a torus:<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/TorusIcon.png\">
               </td>
           </tr>

           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.VoluminousWheel\">VoluminousWheel</a></td>
               <td valign=\"top\">Visualizing a wheel:<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/VoluminousWheelIcon.png\">
               </td>
           </tr>

           <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.PipeWithScalarField\">PipeWithScalarField</a></td>
               <td valign=\"top\">Visualizing a pipe with a scalar field represented by a color coding:<br>
               <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/PipeWithScalarFieldIcon.png\">
               </td>
           </tr>

         <tr><td valign=\"top\"><a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced\">Advanced</a></td>
               <td valign=\"top\"> <b>Package</b> that contains components to visualize
                   3-dimensional shapes where all parts of the shape
                   can vary dynamically. Basic knowledge of Modelica is
                   needed in order to utilize the components of this package.
               </td>
           </tr>
         </table>
         <p>
         The colors of the visualization components are declared with
         the predefined type <b>MultiBody.Types.Color</b>.
         This is a vector with 3 elements,
         {r, g, b}, and specifies the color of the shape.
         {r,g,b} are the \"red\", \"green\" and \"blue\" color parts.
         Note, r g, b are given as Integer[3] in the ranges 0 .. 255,
         respectively.
         </p>
         </HTML>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-80, 26}, {26, -70}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.Solid, fillColor = {245, 245, 245}), Polygon(points = {{-80, 26}, {-16, 70}, {80, 70}, {26, 26}, {-80, 26}}, lineColor = {95, 95, 95}, smooth = Smooth.None, fillColor = {245, 245, 245}, fillPattern = FillPattern.Solid), Polygon(points = {{80, 70}, {26, 26}, {26, -70}, {80, -32}, {80, 70}}, lineColor = {95, 95, 95}, smooth = Smooth.None, fillColor = {245, 245, 245}, fillPattern = FillPattern.Solid)}));
      end Visualizers;

      package Types  "Constants and types with choices, especially to build menus"
        extends Modelica.Icons.TypesPackage;
        type Axis = Modelica.Icons.TypeReal[3](each final unit = "1") "Axis vector with choices for menus" annotation(preferredView = "text", Evaluate = true, choices(choice = {1, 0, 0}, choice = {0, 1, 0}, choice = {0, 0, 1}, choice = {-1, 0, 0}, choice = {0, -1, 0}, choice = {0, 0, -1}), Documentation(info = "<html>
          </html>"));
        type AxisLabel = Modelica.Icons.TypeString "Label of axis with choices for menus" annotation(preferredView = "text", choices(choice = "x", choice = "y", choice = "z"));
        type RotationSequence = Modelica.Icons.TypeInteger[3](min = {1, 1, 1}, max = {3, 3, 3}) "Sequence of planar frame rotations with choices for menus" annotation(preferredView = "text", Evaluate = true, choices(choice = {1, 2, 3}, choice = {3, 1, 3}, choice = {3, 2, 1}));
        type Color = Modelica.Icons.TypeInteger[3](each min = 0, each max = 255) "RGB representation of color" annotation(Dialog(colorSelector = true), choices(choice = {0, 0, 0}, choice = {155, 0, 0}, choice = {255, 0, 0}, choice = {255, 65, 65}, choice = {0, 128, 0}, choice = {0, 180, 0}, choice = {0, 230, 0}, choice = {0, 0, 200}, choice = {0, 0, 255}, choice = {0, 128, 255}, choice = {255, 255, 0}, choice = {255, 0, 255}, choice = {100, 100, 100}, choice = {155, 155, 155}, choice = {255, 255, 255}), Documentation(info = "<html>
          <p>
          Type <b>Color</b> is an Integer vector with 3 elements,
          {r, g, b}, and specifies the color of a shape.
          {r,g,b} are the \"red\", \"green\" and \"blue\" color parts.
          Note, r g, b are given in the range 0 .. 255.
          </p>
          </html>"));
        type SpecularCoefficient = Modelica.Icons.TypeReal(min = 0) "Reflection of ambient light (= 0: light is completely absorbed)" annotation(choices(choice = 0, choice = 0.7, choice = 1), Documentation(info = "<html>
          <p>
          Type <b>SpecularCoefficient</b> defines the reflection of
          ambient light on shape surfaces. If value = 0, the light
          is completely absorbed. Often, 0.7 is a reasonable value.
          It might be that from some viewing directions, a body is no
          longer visible, if the SpecularCoefficient value is too high.
          In the following image, the different values of SpecularCoefficient
          are shown for a cylinder:
          </p>

          <p>
          <img src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Visualizers/SpecularCoefficient.png\" />
          </p>
          </html>"));
        type ShapeType = Modelica.Icons.TypeString "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)" annotation(choices(choice = "box", choice = "sphere", choice = "cylinder", choice = "pipecylinder", choice = "cone", choice = "pipe", choice = "beam", choice = "gearwheel", choice = "spring", choice = "modelica://PackageName/PathName.dxf"), Documentation(info = "<html>
          <p>
          Type <b>ShapeType</b> is used to define the shape of the
          visual object as parameter String. Usually, \"shapeType\" is used
          as instance name. The following
          values for shapeType are possible, e.g., shapeType=\"box\":
          </p>

          <p>
          <IMG src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/Shape.png\" ALT=\"model Visualizers.FixedShape\">
          </p>

          <p>
          The dark blue arrows in the figure above are directed along
          variable <b>lengthDirection</b>. The light blue arrows are directed
          along variable <b>widthDirection</b>. The <b>coordinate systems</b>
          in the figure represent frame_a of the Shape component.
          </p>

          <p>
          Additionally, external shapes can be specified as (not all options might be supported by all tools):
          </p>

          <ul>
          <li> <b>\"1\", \"2\", ...</b><br>
               define external shapes specified in DXF format in files \"1.dxf\", \"2.dxf\", ...
               The DXF-files must be found either in the current directory or in the directory where
               the Shape instance is stored that references the DXF file.
               This (very limited) option should not be used for new models. Example:<br>
              shapeType=\"1\".<br></li>

          <li> \"<b>modelica:</b>//&lt;Modelica-name&gt;/&lt;relative-path-file-name&gt;\"<br>
               characterizes the file that is stored under the location of the
               &lt;Modelica-name&gt; library path with the given relative file name.
               Example:<br> shapeType = \"modelica://Modelica/Resources/Data/Shapes/Engine/piston.dxf\".<br></li>

          <li> \"<b>file:</b>//&lt;absolute-file-name&gt;\"<br>
               characterizes an absolute file name in the file system. Example:<br>
               shapeType=\"file://C:/users/myname/shapes/piston.dxf\".</li>
          </ul>

          <p>
          The supported file formats are tool dependent. Most tools support
          at least DXF-files (a tool might support 3-dim. Face of the DXF format only),
          but may support other format as well (such as stl, obj, 3ds).
          Since visualization files contain color and other data, the corresponding
          information in the model is usually ignored.
          </p>
          </html>"));
        type ShapeExtra = Modelica.Icons.TypeReal "Type of the additional data that can be defined for an elementary ShapeType" annotation(Documentation(info = "<html>
          <p>
          This type is used in shapes of visual objects to define
          extra data depending on the shape type. Usually, input
          variable <b>extra</b> is used as instance name:
          </p>

          <table border=1 cellspacing=0 cellpadding=2>
          <tr><th><b>shapeType</b></th><th>Meaning of parameter <b>extra</b></th></tr>
          <tr>
            <td valign=\"top\">\"cylinder\"</td>
            <td valign=\"top\">if extra &gt; 0, a black line is included in the
                cylinder to show the rotation of it.</td>
          </tr>
          <tr>
            <td valign=\"top\">\"cone\"</td>
            <td valign=\"top\">extra = diameter-left-side / diameter-right-side, i.e.,<br>
                extra = 1: cylinder<br>
                extra = 0: \"real\" cone.</td>
          </tr>
          <tr>
            <td valign=\"top\">\"pipe\"</td>
            <td valign=\"top\">extra = outer-diameter / inner-diameter, i.e, <br>
                extra = 1: cylinder that is completely hollow<br>
                extra = 0: cylinder without a hole.</td>
          </tr>
          <tr>
            <td valign=\"top\">\"gearwheel\"</td>
            <td valign=\"top\">extra is the number of teeth of the (external) gear.
          If extra &lt; 0, an internal gear is visualized with |extra| teeth.
          The axis of the gearwheel is along \"lengthDirection\", and usually:
          width = height = 2*radiusOfGearWheel.</td>
          </tr>
          <tr>
            <td valign=\"top\">\"spring\"</td>
            <td valign=\"top\">extra is the number of windings of the spring.
                Additionally, \"height\" is <b>not</b> the \"height\" but
                2*coil-width.</td>
          </tr>
          <tr>
            <td valign=\"top\">external shape</td>
            <td valign=\"top\">extra = 0: Visualization from file is not scaled.<br>
                               extra = 1: Visualization from file is scaled with \"length\", \"width\" and height\"
                                          of the shape</td>
          </tr>

          </table>

          </html>"));
        type GravityTypes = enumeration(NoGravity "No gravity field", UniformGravity "Uniform gravity field", PointGravity "Point gravity field") "Enumeration defining the type of the gravity field" annotation(Documentation(info = "<html>
          <table border=1 cellspacing=0 cellpadding=2>
          <tr><th><b>Types.GravityTypes.</b></th><th><b>Meaning</b></th></tr>
          <tr><td valign=\"top\">NoGravity</td>
              <td valign=\"top\">No gravity field</td></tr>

          <tr><td valign=\"top\">UniformGravity</td>
              <td valign=\"top\">Gravity field is described by a vector of constant gravity acceleration</td></tr>

          <tr><td valign=\"top\">PointGravity</td>
              <td valign=\"top\">Central gravity field. The gravity acceleration vector is directed to
                  the field center and the gravity is proportional to 1/r^2, where
                  r is the distance to the field center.</td></tr>
          </table>
          </html>"));

        package Defaults  "Default settings of the MultiBody library via constants"
          extends Modelica.Icons.Package;
          constant Types.Color BodyColor = {0, 128, 255} "Default color for body shapes that have mass (light blue)";
          constant Types.Color RodColor = {155, 155, 155} "Default color for massless rod shapes (grey)";
          constant Types.Color JointColor = {255, 0, 0} "Default color for elementary joints (red)";
          constant Types.Color FrameColor = {0, 0, 0} "Default color for frame axes and labels (black)";
          constant Real FrameHeadLengthFraction = 5.0 "Frame arrow head length / arrow diameter";
          constant Real FrameHeadWidthFraction = 3.0 "Frame arrow head width / arrow diameter";
          constant Real FrameLabelHeightFraction = 3.0 "Height of frame label / arrow diameter";
          constant Real ArrowHeadLengthFraction = 4.0 "Arrow head length / arrow diameter";
          constant Real ArrowHeadWidthFraction = 3.0 "Arrow head width / arrow diameter";
          constant .Modelica.SIunits.Diameter BodyCylinderDiameterFraction = 3 "Default for body cylinder diameter as a fraction of body sphere diameter";
          annotation(Documentation(info = "<html>
           <p>
           This package contains constants used as default setting
           in the MultiBody library.
           </p>
           </html>"));
        end Defaults;
        annotation(Documentation(info = "<HTML>
         <p>
         In this package <b>types</b> and <b>constants</b> are defined that are used in the
         MultiBody library. The types have additional annotation choices
         definitions that define the menus to be built up in the graphical
         user interface when the type is used as parameter in a declaration.
         </p>
         </HTML>"));
      end Types;
      annotation(Documentation(info = "<HTML>
       <p>
       Library <b>MultiBody</b> is a <b>free</b> Modelica package providing
       3-dimensional mechanical components to model in a convenient way
       <b>mechanical systems</b>, such as robots, mechanisms, vehicles.
       Typical animations generated with this library are shown
       in the next figure:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Mechanics/MultiBody/MultiBody.png\">
       </p>

       <p>
       For an introduction, have especially a look at:
       </p>
       <ul>
       <li> <a href=\"modelica://Modelica.Mechanics.MultiBody.UsersGuide\">MultiBody.UsersGuide</a>
            discusses the most important aspects how to use this library.</li>
       <li> <a href=\"modelica://Modelica.Mechanics.MultiBody.Examples\">MultiBody.Examples</a>
            contains examples that demonstrate the usage of this library.</li>
       </ul>

       <p>
       Copyright &copy; 1998-2013, Modelica Association and DLR.
       </p>
       <p>
       <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
       </p>
       </HTML>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-58, 76}, {6, 76}, {-26, 50}, {-58, 76}}, lineColor = {95, 95, 95}, smooth = Smooth.None, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-26, 50}, {28, -50}}, color = {0, 0, 0}, smooth = Smooth.None), Ellipse(extent = {{-4, -14}, {60, -78}}, lineColor = {135, 135, 135}, fillPattern = FillPattern.Sphere, fillColor = {255, 255, 255})}));
    end MultiBody;

    package Rotational  "Library to model 1-dimensional, rotational mechanical systems"
      extends Modelica.Icons.Package;

      package Components  "Components for 1D rotational mechanical drive trains"
        extends Modelica.Icons.Package;

        model Fixed  "Flange fixed in housing at a given angle"
          parameter .Modelica.SIunits.Angle phi0 = 0 "Fixed offset angle of housing";
          Interfaces.Flange_b flange "(right) flange fixed in housing" annotation(Placement(transformation(extent = {{10, -10}, {-10, 10}}, rotation = 0)));
        equation
          flange.phi = phi0;
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-150, -90}, {150, -130}}, lineColor = {0, 0, 255}, textString = "%name"), Line(points = {{-80, -40}, {80, -40}}, color = {0, 0, 0}), Line(points = {{80, -40}, {40, -80}}, color = {0, 0, 0}), Line(points = {{40, -40}, {0, -80}}, color = {0, 0, 0}), Line(points = {{0, -40}, {-40, -80}}, color = {0, 0, 0}), Line(points = {{-40, -40}, {-80, -80}}, color = {0, 0, 0}), Line(points = {{0, -40}, {0, -10}}, color = {0, 0, 0})}), Documentation(info = "<html>
           <p>
           The <b>flange</b> of a 1D rotational mechanical system is <b>fixed</b>
           at an angle phi0 in the <b>housing</b>. May be used:
           </p>
           <ul>
           <li> to connect a compliant element, such as a spring or a damper,
                between an inertia or gearbox component and the housing.
           <li> to fix a rigid element, such as an inertia, with a specific
                angle to the housing.
           </ul>

           </html>"), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, -40}, {80, -40}}, color = {0, 0, 0}), Line(points = {{80, -40}, {40, -80}}, color = {0, 0, 0}), Line(points = {{40, -40}, {0, -80}}, color = {0, 0, 0}), Line(points = {{0, -40}, {-40, -80}}, color = {0, 0, 0}), Line(points = {{-40, -40}, {-80, -80}}, color = {0, 0, 0}), Line(points = {{0, -40}, {0, -4}}, color = {0, 0, 0})}));
        end Fixed;
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Rectangle(origin = {13.5135, 76.9841}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-63.5135, -126.9841}, {36.4865, -26.9841}}, radius = 10.0), Rectangle(origin = {13.5135, 76.9841}, lineColor = {64, 64, 64}, fillPattern = FillPattern.None, extent = {{-63.5135, -126.9841}, {36.4865, -26.9841}}, radius = 10.0), Rectangle(origin = {-3.0, 73.07689999999999}, lineColor = {64, 64, 64}, fillColor = {192, 192, 192}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-87.0, -83.07689999999999}, {-47.0, -63.0769}}), Rectangle(origin = {22.3077, 70.0}, lineColor = {64, 64, 64}, fillColor = {192, 192, 192}, fillPattern = FillPattern.HorizontalCylinder, extent = {{27.6923, -80.0}, {67.6923, -60.0}})}), Documentation(info = "<html>
         <p>
         This package contains basic components 1D mechanical rotational drive trains.
         </p>
         </html>"));
      end Components;

      package Sources  "Sources to drive 1D rotational mechanical components"
        extends Modelica.Icons.SourcesPackage;

        model ConstantTorque  "Constant torque, not dependent on speed"
          extends Rotational.Interfaces.PartialTorque;
          parameter Modelica.SIunits.Torque tau_constant "Constant torque (if negative, torque is acting as load)";
          Modelica.SIunits.Torque tau "Accelerating torque acting at flange (= -flange.tau)";
        equation
          tau = -flange.tau;
          tau = tau_constant;
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-98, 0}, {100, 0}}, color = {0, 0, 127}), Text(extent = {{-124.0, -40.0}, {120.0, -16.0}}, textString = "%tau_constant")}), Documentation(info = "<HTML>
           <p>
           Model of constant torque, not dependent on angular velocity of flange.<br>
           Positive torque acts accelerating.
           </p>
           </HTML>"));
        end ConstantTorque;
        annotation(Documentation(info = "<html>
         <p>
         This package contains ideal sources to drive 1D mechanical rotational drive trains.
         </p>
         </html>"));
      end Sources;

      package Interfaces  "Connectors and partial models for 1D rotational mechanical components"
        extends Modelica.Icons.InterfacesPackage;

        connector Flange_a  "1-dim. rotational flange of a shaft (filled square icon)"
          .Modelica.SIunits.Angle phi "Absolute rotation angle of flange";
          flow .Modelica.SIunits.Torque tau "Cut torque in the flange";
          annotation(defaultComponentName = "flange_a", Documentation(info = "<html>
           <p>
           This is a connector for 1-dim. rotational mechanical systems and models
           the mechanical flange of a shaft. The following variables are defined in this connector:
           </p>

           <table border=1 cellspacing=0 cellpadding=2>
             <tr><td valign=\"top\"> <b>phi</b></td>
                 <td valign=\"top\"> Absolute rotation angle of the shaft flange in [rad] </td>
             </tr>
             <tr><td valign=\"top\"> <b>tau</b></td>
                 <td valign=\"top\"> Cut-torque in the shaft flange in [Nm] </td>
             </tr>
           </table>

           <p>
           There is a second connector for flanges: Flange_b. The connectors
           Flange_a and Flange_b are completely identical. There is only a difference
           in the icons, in order to easier identify a flange variable in a diagram.
           For a discussion on the actual direction of the cut-torque tau and
           of the rotation angle, see section
           <a href=\"modelica://Modelica.Mechanics.Rotational.UsersGuide.SignConventions\">Sign Conventions</a>
           in the user's guide of Rotational.
           </p>

           <p>
           If needed, the absolute angular velocity w and the
           absolute angular acceleration a of the flange can be determined by
           differentiation of the flange angle phi:
           </p>
           <pre>
                w = der(phi);    a = der(w)
           </pre>
           </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-160, 90}, {40, 50}}, lineColor = {0, 0, 0}, textString = "%name"), Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid)}));
        end Flange_a;

        connector Flange_b  "1-dim. rotational flange of a shaft (non-filled square icon)"
          .Modelica.SIunits.Angle phi "Absolute rotation angle of flange";
          flow .Modelica.SIunits.Torque tau "Cut torque in the flange";
          annotation(defaultComponentName = "flange_b", Documentation(info = "<html>
           <p>
           This is a connector for 1-dim. rotational mechanical systems and models
           the mechanical flange of a shaft. The following variables are defined in this connector:
           </p>

           <table border=1 cellspacing=0 cellpadding=2>
             <tr><td valign=\"top\"> <b>phi</b></td>
                 <td valign=\"top\"> Absolute rotation angle of the shaft flange in [rad] </td>
             </tr>
             <tr><td valign=\"top\"> <b>tau</b></td>
                 <td valign=\"top\"> Cut-torque in the shaft flange in [Nm] </td>
             </tr>
           </table>

           <p>
           There is a second connector for flanges: Flange_a. The connectors
           Flange_a and Flange_b are completely identical. There is only a difference
           in the icons, in order to easier identify a flange variable in a diagram.
           For a discussion on the actual direction of the cut-torque tau and
           of the rotation angle, see section
           <a href=\"modelica://Modelica.Mechanics.Rotational.UsersGuide.SignConventions\">Sign Conventions</a>
           in the user's guide of Rotational.
           </p>

           <p>
           If needed, the absolute angular velocity w and the
           absolute angular acceleration a of the flange can be determined by
           differentiation of the flange angle phi:
           </p>
           <pre>
                w = der(phi);    a = der(w)
           </pre>
           </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-98, 100}, {102, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-40, 90}, {160, 50}}, lineColor = {0, 0, 0}, textString = "%name")}));
        end Flange_b;

        connector Support  "Support/housing of a 1-dim. rotational shaft"
          .Modelica.SIunits.Angle phi "Absolute rotation angle of the support/housing";
          flow .Modelica.SIunits.Torque tau "Reaction torque in the support/housing";
          annotation(Documentation(info = "<html>
           <p>
           This is a connector for 1-dim. rotational mechanical systems and models
           the support or housing of a shaft. The following variables are defined in this connector:
           </p>

           <table border=1 cellspacing=0 cellpadding=2>
             <tr><td valign=\"top\"> <b>phi</b></td>
                 <td valign=\"top\"> Absolute rotation angle of the support/housing in [rad] </td>
             </tr>
             <tr><td valign=\"top\"> <b>tau</b></td>
                 <td valign=\"top\"> Reaction torque in the support/housing in [Nm] </td>
             </tr>
           </table>

           <p>
           The support connector is usually defined as conditional connector.
           It is most convenient to utilize it
           </p>

           <ul>
           <li> For models to be build graphically (i.e., the model is build up by drag-and-drop
                from elementary components):<br>
                <a href=\"modelica://Modelica.Mechanics.Rotational.Interfaces.PartialOneFlangeAndSupport\">PartialOneFlangeAndSupport</a>,<br>
                <a href=\"modelica://Modelica.Mechanics.Rotational.Interfaces.PartialTwoFlangesAndSupport\">PartialTwoFlangesAndSupport</a>, <br> &nbsp; </li>

           <li> For models to be build textually (i.e., elementary models):<br>
                <a href=\"modelica://Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport\">PartialElementaryOneFlangeAndSupport</a>,<br>
                <a href=\"modelica://Modelica.Mechanics.Rotational.Interfaces.PartialElementaryTwoFlangesAndSupport\">PartialElementaryTwoFlangesAndSupport</a>,<br>
                <a href=\"modelica://Modelica.Mechanics.Rotational.Interfaces.PartialElementaryRotationalToTranslational\">PartialElementaryRotationalToTranslational</a>.</li>
           </ul>
           </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.1), graphics = {Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-150, 150}, {150, -150}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, initialScale = 0.1), graphics = {Rectangle(extent = {{-60, 60}, {60, -60}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-160, 100}, {40, 60}}, lineColor = {0, 0, 0}, textString = "%name"), Ellipse(extent = {{-40, 40}, {40, -40}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid)}));
        end Support;

        model InternalSupport  "Adapter model to utilize conditional support connector"
          input Modelica.SIunits.Torque tau "External support torque (must be computed via torque balance in model where InternalSupport is used; = flange.tau)";
          Modelica.SIunits.Angle phi "External support angle (= flange.phi)";
          Flange_a flange "Internal support flange (must be connected to the conditional support connector for useSupport=true and to conditional fixed model for useSupport=false)" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
        equation
          flange.tau = tau;
          flange.phi = phi;
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-20, 20}, {20, -20}}, lineColor = {135, 135, 135}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Text(extent = {{-200, 80}, {200, 40}}, lineColor = {0, 0, 255}, textString = "%name")}), Documentation(info = "<html>
           <p>
           This is an adapter model to utilize a conditional support connector
           in an elementary component, i.e., where the component equations are
           defined textually:
           </p>

           <ul>
           <li> If <i>useSupport = true</i>, the flange has to be connected to the conditional
                support connector.</li>
           <li> If <i>useSupport = false</i>, the flange has to be connected to the conditional
                fixed model.</li>
           </ul>

           <p>
           Variable <b>tau</b> is defined as <b>input</b> and must be provided when using
           this component as a modifier (computed via a torque balance in
           the model where InternalSupport is used). Usually, model InternalSupport is
           utilized via the partial models:
           </p>

           <blockquote>
           <a href=\"modelica://Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport\">
           PartialElementaryOneFlangeAndSupport</a>,<br>
           <a href=\"modelica://Modelica.Mechanics.Rotational.Interfaces.PartialElementaryTwoFlangesAndSupport\">
           PartialElementaryTwoFlangesAndSupport</a>,<br>
           <a href=\"modelica://Modelica.Mechanics.Rotational.Interfaces.PartialElementaryRotationalToTranslational\">
           PartialElementaryRotationalToTranslational</a>.
           </blockquote>

           <p>
           Note, the support angle can always be accessed as internalSupport.phi, and
           the support torque can always be accessed as internalSupport.tau.
           </p>
           </html>"));
        end InternalSupport;

        partial model PartialElementaryOneFlangeAndSupport2  "Partial model for a component with one rotational 1-dim. shaft flange and a support used for textual modeling, i.e., for elementary models"
          parameter Boolean useSupport = false "= true, if support flange enabled, otherwise implicitly grounded" annotation(Evaluate = true, HideResult = true, choices(checkBox = true));
          Flange_b flange "Flange of shaft" annotation(Placement(transformation(extent = {{90, -10}, {110, 10}}, rotation = 0)));
          Support support(phi = phi_support, tau = -flange.tau) if useSupport "Support/housing of component" annotation(Placement(transformation(extent = {{-10, -110}, {10, -90}})));
        protected
          Modelica.SIunits.Angle phi_support "Absolute angle of support flange";
        equation
          if not useSupport then
            phi_support = 0;
          end if;
          annotation(Documentation(info = "<html>
           <p>
           This is a 1-dim. rotational component with one flange and a support/housing.
           It is used to build up elementary components of a drive train with
           equations in the text layer.
           </p>

           <p>
           If <i>useSupport=true</i>, the support connector is conditionally enabled
           and needs to be connected.<br>
           If <i>useSupport=false</i>, the support connector is conditionally disabled
           and instead the component is internally fixed to ground.
           </p>
           </html>"), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(visible = not useSupport, points = {{-50, -120}, {-30, -100}}, color = {0, 0, 0}), Line(visible = not useSupport, points = {{-30, -120}, {-10, -100}}, color = {0, 0, 0}), Line(visible = not useSupport, points = {{-10, -120}, {10, -100}}, color = {0, 0, 0}), Line(visible = not useSupport, points = {{10, -120}, {30, -100}}, color = {0, 0, 0}), Line(visible = not useSupport, points = {{-30, -100}, {30, -100}}, color = {0, 0, 0})}));
        end PartialElementaryOneFlangeAndSupport2;

        partial model PartialTorque  "Partial model of a torque acting at the flange (accelerates the flange)"
          extends Modelica.Mechanics.Rotational.Interfaces.PartialElementaryOneFlangeAndSupport2;
          Modelica.SIunits.Angle phi "Angle of flange with respect to support (= flange.phi - support.phi)";
        equation
          phi = flange.phi - phi_support;
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-96, 96}, {96, -96}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, -62}, {0, -100}}, color = {0, 0, 0}), Line(points = {{-92, 0}, {-76, 36}, {-54, 62}, {-30, 80}, {-14, 88}, {10, 92}, {26, 90}, {46, 80}, {64, 62}}, color = {0, 0, 0}, smooth = Smooth.Bezier), Text(extent = {{-150, 140}, {150, 100}}, lineColor = {0, 0, 255}, textString = "%name"), Polygon(points = {{94, 16}, {80, 74}, {50, 52}, {94, 16}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Line(points = {{-58, -82}, {-42, -68}, {-20, -56}, {0, -54}, {18, -56}, {34, -62}, {44, -72}, {54, -82}, {60, -94}}, color = {0, 0, 0}, smooth = Smooth.Bezier), Polygon(points = {{-65, -98}, {-46, -80}, {-58, -72}, {-65, -98}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Line(visible = not useSupport, points = {{-50, -120}, {-30, -100}}, color = {0, 0, 0}), Line(visible = not useSupport, points = {{-30, -120}, {-10, -100}}, color = {0, 0, 0}), Line(visible = not useSupport, points = {{-10, -120}, {10, -100}}, color = {0, 0, 0}), Line(visible = not useSupport, points = {{10, -120}, {30, -100}}, color = {0, 0, 0}), Line(visible = not useSupport, points = {{-30, -100}, {30, -100}}, color = {0, 0, 0})}), Documentation(info = "<HTML>
           <p>
           Partial model of torque that accelerates the flange.
           </p>

           <p>
           If <i>useSupport=true</i>, the support connector is conditionally enabled
           and needs to be connected.<br>
           If <i>useSupport=false</i>, the support connector is conditionally disabled
           and instead the component is internally fixed to ground.
           </p>
           </html>"));
        end PartialTorque;
        annotation(Documentation(info = "<html>
         <p>
         This package contains connectors and partial models for 1-dim.
         rotational mechanical components. The components of this package can
         only be used as basic building elements for models.
         </p>
         </html>"));
      end Interfaces;
      annotation(Documentation(info = "<html>

       <p>
       Library <b>Rotational</b> is a <b>free</b> Modelica package providing
       1-dimensional, rotational mechanical components to model in a convenient way
       drive trains with frictional losses. A typical, simple example is shown
       in the next figure:
       </p>

       <img src=\"modelica://Modelica/Resources/Images/Mechanics/Rotational/driveExample.png\">

       <p>
       For an introduction, have especially a look at:
       </p>
       <ul>
       <li> <a href=\"modelica://Modelica.Mechanics.Rotational.UsersGuide\">Rotational.UsersGuide</a>
            discusses the most important aspects how to use this library.</li>
       <li> <a href=\"modelica://Modelica.Mechanics.Rotational.Examples\">Rotational.Examples</a>
            contains examples that demonstrate the usage of this library.</li>
       </ul>

       <p>
       In version 3.0 of the Modelica Standard Library, the basic design of the
       library has changed: Previously, bearing connectors could or could not be connected.
       In 3.0, the bearing connector is renamed to \"<b>support</b>\" and this connector
       is enabled via parameter \"useSupport\". If the support connector is enabled,
       it must be connected, and if it is not enabled, it must not be connected.
       </p>

       <p>
       In version 3.2 of the Modelica Standard Library, all <b>dissipative</b> components
       of the Rotational library got an optional <b>heatPort</b> connector to which the
       dissipated energy is transported in form of heat. This connector is enabled
       via parameter \"useHeatPort\". If the heatPort connector is enabled,
       it must be connected, and if it is not enabled, it must not be connected.
       Independently, whether the heatPort is enabled or not,
       the dissipated power is available from the new variable \"<b>lossPower</b>\" (which is
       positive if heat is flowing out of the heatPort). For an example, see
       <a href=\"modelica://Modelica.Mechanics.Rotational.Examples.HeatLosses\">Examples.HeatLosses</a>.
       </p>

       <p>
       Copyright &copy; 1998-2013, Modelica Association and DLR.
       </p>
       <p>
       <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
       </p>
       </html>", revisions = ""), Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Line(visible = true, origin = {-2.0, 46.0}, points = {{-83.0, -66.0}, {-63.0, -66.0}}), Line(visible = true, origin = {29.0, 48.0}, points = {{36.0, -68.0}, {56.0, -68.0}}), Line(visible = true, origin = {-2.0, 49.0}, points = {{-83.0, -29.0}, {-63.0, -29.0}}), Line(visible = true, origin = {29.0, 52.0}, points = {{36.0, -32.0}, {56.0, -32.0}}), Line(visible = true, origin = {-2.0, 49.0}, points = {{-73.0, -9.0}, {-73.0, -29.0}}), Line(visible = true, origin = {29.0, 52.0}, points = {{46.0, -12.0}, {46.0, -32.0}}), Line(visible = true, origin = {-0.0, -47.5}, points = {{-75.0, 27.5}, {-75.0, -27.5}, {75.0, -27.5}, {75.0, 27.5}}), Rectangle(visible = true, origin = {13.5135, 76.9841}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-63.5135, -126.9841}, {36.4865, -26.9841}}, radius = 10.0), Rectangle(visible = true, origin = {13.5135, 76.9841}, lineColor = {64, 64, 64}, fillPattern = FillPattern.None, extent = {{-63.5135, -126.9841}, {36.4865, -26.9841}}, radius = 10.0), Rectangle(visible = true, origin = {-3.0, 73.07689999999999}, lineColor = {64, 64, 64}, fillColor = {192, 192, 192}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-87.0, -83.07689999999999}, {-47.0, -63.0769}}), Rectangle(visible = true, origin = {22.3077, 70.0}, lineColor = {64, 64, 64}, fillColor = {192, 192, 192}, fillPattern = FillPattern.HorizontalCylinder, extent = {{27.6923, -80.0}, {67.6923, -60.0}})}));
    end Rotational;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Rectangle(origin = {8.6, 63.3333}, lineColor = {64, 64, 64}, fillColor = {192, 192, 192}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-4.6, -93.33329999999999}, {41.4, -53.3333}}), Ellipse(origin = {9.0, 46.0}, extent = {{-90.0, -60.0}, {-80.0, -50.0}}), Line(origin = {9.0, 46.0}, points = {{-85.0, -55.0}, {-60.0, -21.0}}, thickness = 0.5), Ellipse(origin = {9.0, 46.0}, extent = {{-65.0, -26.0}, {-55.0, -16.0}}), Line(origin = {9.0, 46.0}, points = {{-60.0, -21.0}, {9.0, -55.0}}, thickness = 0.5), Ellipse(origin = {9.0, 46.0}, fillPattern = FillPattern.Solid, extent = {{4.0, -60.0}, {14.0, -50.0}}), Line(origin = {9.0, 46.0}, points = {{-10.0, -26.0}, {72.0, -26.0}, {72.0, -86.0}, {-10.0, -86.0}})}), Documentation(info = "<HTML>
     <p>
     This package contains components to model the movement
     of 1-dim. rotational, 1-dim. translational, and
     3-dim. <b>mechanical systems</b>.
     </p>

     <p>
     Note, all <b>dissipative</b> components of the Modelica.Mechanics library have
     an optional <b>heatPort</b> connector to which the
     dissipated energy is transported in form of heat. This connector is enabled
     via parameter \"useHeatPort\". If the heatPort connector is enabled,
     it must be connected, and if it is not enabled, it must not be connected.
     Independently, whether the heatPort is enabled or not,
     the dissipated power is available from variable \"<b>lossPower</b>\" (which is
     positive if heat is flowing out of the heatPort).
     </p>
     </html>"));
  end Mechanics;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  "Basic icon for mathematical function with y-axis on left side"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-80, 68}}, color = {192, 192, 192}), Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 80}, {-88, 80}}, color = {95, 95, 95}), Line(points = {{-80, -80}, {-88, -80}}, color = {95, 95, 95}), Line(points = {{-80, -90}, {-80, 84}}, color = {95, 95, 95}), Text(extent = {{-75, 104}, {-55, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{-80, 98}, {-86, 82}, {-74, 82}, {-80, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
        <p>
        Icon for a mathematical function, consisting of an y-axis on the left side.
        It is expected, that an x-axis is added and a plot of the function.
        </p>
        </html>")); end AxisLeft;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {0, 68}}, color = {192, 192, 192}), Polygon(points = {{0, 90}, {-8, 68}, {8, 68}, {0, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(graphics = {Line(points = {{0, 80}, {-8, 80}}, color = {95, 95, 95}), Line(points = {{0, -80}, {-8, -80}}, color = {95, 95, 95}), Line(points = {{0, -90}, {0, 84}}, color = {95, 95, 95}), Text(extent = {{5, 104}, {25, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{0, 98}, {-6, 82}, {6, 82}, {0, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
        <p>
        Icon for a mathematical function, consisting of an y-axis in the middle.
        It is expected, that an x-axis is added and a plot of the function.
        </p>
        </html>")); end AxisCenter;
    end Icons;

    package Vectors  "Library of functions operating on vectors"
      extends Modelica.Icons.Package;

      function length  "Return length of a vector (better as norm(), if further symbolic processing is performed)"
        extends Modelica.Icons.Function;
        input Real[:] v "Vector";
        output Real result "Length of vector v";
      algorithm
        result := sqrt(v * v);
        annotation(Inline = true, Documentation(info = "<html>
         <h4>Syntax</h4>
         <blockquote><pre>
         Vectors.<b>length</b>(v);
         </pre></blockquote>
         <h4>Description</h4>
         <p>
         The function call \"<code>Vectors.<b>length</b>(v)</code>\" returns the
         <b>Euclidean length</b> \"<code>sqrt(v*v)</code>\" of vector v.
         The function call is equivalent to Vectors.norm(v). The advantage of
         length(v) over norm(v)\"is that function length(..) is implemented
         in one statement and therefore the function is usually automatically
         inlined. Further symbolic processing is therefore possible, which is
         not the case with function norm(..).
         </p>
         <h4>Example</h4>
         <blockquote><pre>
           v = {2, -4, -2, -1};
           <b>length</b>(v);  // = 5
         </pre></blockquote>
         <h4>See also</h4>
         <p>
         <a href=\"modelica://Modelica.Math.Vectors.norm\">Vectors.norm</a>
         </p>
         </html>"));
      end length;

      function normalize  "Return normalized vector such that length = 1 and prevent zero-division for zero vector"
        extends Modelica.Icons.Function;
        input Real[:] v "Vector";
        input Real eps(min = 0.0) = 100 * Modelica.Constants.eps "if |v| < eps then result = v/eps";
        output Real[size(v, 1)] result "Input vector v normalized to length=1";
      algorithm
        result := smooth(0, noEvent(if length(v) >= eps then v / length(v) else v / eps));
        annotation(Inline = true, Documentation(info = "<html>
         <h4>Syntax</h4>
         <blockquote><pre>
         Vectors.<b>normalize</b>(v);
         Vectors.<b>normalize</b>(v,eps=100*Modelica.Constants.eps);
         </pre></blockquote>
         <h4>Description</h4>
         <p>
         The function call \"<code>Vectors.<b>normalize</b>(v)</code>\" returns the
         <b>unit vector</b> \"<code>v/length(v)</code>\" of vector v.
         If length(v) is close to zero (more precisely, if length(v) &lt; eps),
         v/eps is returned in order to avoid
         a division by zero. For many applications this is useful, because
         often the unit vector <b>e</b> = <b>v</b>/length(<b>v</b>) is used to compute
         a vector x*<b>e</b>, where the scalar x is in the order of length(<b>v</b>),
         i.e., x*<b>e</b> is small, when length(<b>v</b>) is small and then
         it is fine to replace <b>e</b> by <b>v</b> to avoid a division by zero.
         </p>
         <p>
         Since the function has the \"Inline\" annotation, it
         is usually inlined and symbolic processing is applied.
         </p>
         <h4>Example</h4>
         <blockquote><pre>
           <b>normalize</b>({1,2,3});  // = {0.267, 0.534, 0.802}
           <b>normalize</b>({0,0,0});  // = {0,0,0}
         </pre></blockquote>
         <h4>See also</h4>
         <p>
         <a href=\"modelica://Modelica.Math.Vectors.length\">Vectors.length</a>,
         <a href=\"modelica://Modelica.Math.Vectors.normalize\">Vectors.normalizeWithAssert</a>
         </p>
         </html>"));
      end normalize;

      function normalizeWithAssert  "Return normalized vector such that length = 1 (trigger an assert for zero vector)"
        extends Modelica.Icons.Function;
        input Real[:] v "Vector";
        output Real[size(v, 1)] result "Input vector v normalized to length=1";
      algorithm
        assert(.Modelica.Math.Vectors.length(v) > 0.0, "Vector v={0,0,0} shall be normalized (= v/sqrt(v*v)), but this results in a division by zero.\nProvide a non-zero vector!");
        result := v / .Modelica.Math.Vectors.length(v);
        annotation(Inline = true, Documentation(info = "<html>
         <h4>Syntax</h4>
         <blockquote><pre>
         Vectors.<b>normalizeWithAssert</b>(v);
         </pre></blockquote>
         <h4>Description</h4>
         <p>
         The function call \"<code>Vectors.<b>normalizeWithAssert</b>(v)</code>\" returns the
         <b>unit vector</b> \"<code>v/sqrt(v*v)</code>\" of vector v.
         If vector v is a zero vector, an assert is triggered.
         </p>
         <p>
         Since the function has the \"Inline\" annotation, it
         is usually inlined and symbolic processing is applied.
         </p>
         <h4>Example</h4>
         <blockquote><pre>
           <b>normalizeWithAssert</b>({1,2,3});  // = {0.267, 0.534, 0.802}
           <b>normalizeWithAssert</b>({0,0,0});  // error (an assert is triggered)
         </pre></blockquote>
         <h4>See also</h4>
         <p>
         <a href=\"modelica://Modelica.Math.Vectors.length\">Vectors.length</a>,
         <a href=\"modelica://Modelica.Math.Vectors.normalize\">Vectors.normalize</a>
         </p>
         </html>"));
      end normalizeWithAssert;
      annotation(preferredView = "info", Documentation(info = "<HTML>
       <h4>Library content</h4>
       <p>
       This library provides functions operating on vectors:
       </p>

       <ul>
       <li> <a href=\"modelica://Modelica.Math.Vectors.toString\">toString</a>(v)
            - returns the string representation of vector v.</li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.isEqual\">isEqual</a>(v1, v2)
            - returns true if vectors v1 and v2 have the same size and the same elements.</li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.norm\">norm</a>(v,p)
            - returns the p-norm of vector v.</li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.length\">length</a>(v)
            - returns the length of vector v (= norm(v,2), but inlined and therefore usable in
              symbolic manipulations)</li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.normalize\">normalize</a>(v)
            - returns vector in direction of v with lenght = 1 and prevents
              zero-division for zero vector.</li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.reverse\">reverse</a>(v)
            - reverses the vector elements of v. </li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.sort\">sort</a>(v)
            - sorts the elements of vector v in ascending or descending order.</li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.find\">find</a>(e, v)
            - returns the index of the first occurrence of scalar e in vector v.</li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.interpolate\">interpolate</a>(x, y, xi)
            - returns the interpolated value in (x,y) that corresponds to xi.</li>

       <li> <a href=\"modelica://Modelica.Math.Vectors.relNodePositions\">relNodePositions</a>(nNodes)
            - returns a vector of relative node positions (0..1).</li>
       </ul>

       <h4>See also</h4>
       <a href=\"modelica://Modelica.Math.Matrices\">Matrices</a>
       </HTML>"));
    end Vectors;

    function sin  "Sine"
      extends Modelica.Math.Icons.AxisLeft;
      input Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = sin(u);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.40000000000001}, {-49.4, 74.59999999999999}, {-43.8, 79.09999999999999}, {-38.2, 79.8}, {-32.6, 76.59999999999999}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.09999999999999}, {35, -78.40000000000001}, {40.6, -80}, {46.2, -77.59999999999999}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}), Text(extent = {{12, 84}, {84, 36}}, lineColor = {192, 192, 192}, textString = "sin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{100, 0}, {84, 6}, {84, -6}, {100, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.40000000000001}, {-49.4, 74.59999999999999}, {-43.8, 79.09999999999999}, {-38.2, 79.8}, {-32.6, 76.59999999999999}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.09999999999999}, {35, -78.40000000000001}, {40.6, -80}, {46.2, -77.59999999999999}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-105, 72}, {-85, 88}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{70, 25}, {90, 5}}, textString = "2*pi", lineColor = {0, 0, 255}), Text(extent = {{-103, -72}, {-83, -88}}, textString = "-1", lineColor = {0, 0, 255}), Text(extent = {{82, -6}, {102, -26}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{-80, 80}, {-28, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-80, -80}, {50, -80}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
       <p>
       This function returns y = sin(u), with -&infin; &lt; u &lt; &infin;:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/sin.png\">
       </p>
       </html>"));
    end sin;

    function cos  "Cosine"
      extends Modelica.Math.Icons.AxisLeft;
      input .Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = cos(u);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-74.40000000000001, 78.09999999999999}, {-68.7, 72.3}, {-63.1, 63}, {-56.7, 48.7}, {-48.6, 26.6}, {-29.3, -32.5}, {-22.1, -51.7}, {-15.7, -65.3}, {-10.1, -73.8}, {-4.42, -78.8}, {1.21, -79.90000000000001}, {6.83, -77.09999999999999}, {12.5, -70.59999999999999}, {18.1, -60.6}, {24.5, -45.7}, {32.6, -23}, {50.3, 31.3}, {57.5, 50.7}, {63.9, 64.59999999999999}, {69.5, 73.40000000000001}, {75.2, 78.59999999999999}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-36, 82}, {36, 34}}, lineColor = {192, 192, 192}, textString = "cos")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-103, 72}, {-83, 88}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{-103, -72}, {-83, -88}}, textString = "-1", lineColor = {0, 0, 255}), Text(extent = {{70, 25}, {90, 5}}, textString = "2*pi", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-74.40000000000001, 78.09999999999999}, {-68.7, 72.3}, {-63.1, 63}, {-56.7, 48.7}, {-48.6, 26.6}, {-29.3, -32.5}, {-22.1, -51.7}, {-15.7, -65.3}, {-10.1, -73.8}, {-4.42, -78.8}, {1.21, -79.90000000000001}, {6.83, -77.09999999999999}, {12.5, -70.59999999999999}, {18.1, -60.6}, {24.5, -45.7}, {32.6, -23}, {50.3, 31.3}, {57.5, 50.7}, {63.9, 64.59999999999999}, {69.5, 73.40000000000001}, {75.2, 78.59999999999999}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{78, -6}, {98, -26}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{-80, -80}, {18, -80}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
       <p>
       This function returns y = cos(u), with -&infin; &lt; u &lt; &infin;:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/cos.png\">
       </p>
       </html>"));
    end cos;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.59999999999999, -67.5}, {-73.59999999999999, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.59999999999999, 67.5}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.59999999999999, -67.5}, {-73.59999999999999, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.59999999999999, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
       <p>
       This function returns y = asin(u), with -1 &le; u &le; +1:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
       </p>
       </html>"));
    end asin;

    function atan2  "Four quadrant inverse tangent"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u1;
      input Real u2;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = atan2(u1, u2);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {8.93, -67.2}, {17.1, -59.3}, {27.3, -53.6}, {42.1, -49.4}, {69.90000000000001, -45.8}, {80, -45.1}}, color = {0, 0, 0}), Line(points = {{-80, -34.9}, {-46.1, -31.4}, {-29.4, -27.1}, {-18.3, -21.5}, {-10.3, -14.5}, {-2.03, -3.17}, {7.97, 11.6}, {15.5, 19.4}, {24.3, 25}, {39, 30}, {62.1, 33.5}, {80, 34.9}}, color = {0, 0, 0}), Line(points = {{-80, 45.1}, {-45.9, 48.7}, {-29.1, 52.9}, {-18.1, 58.6}, {-10.2, 65.8}, {-1.82, 77.2}, {0, 80}}, color = {0, 0, 0}), Text(extent = {{-90, -46}, {-18, -94}}, lineColor = {192, 192, 192}, textString = "atan2")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{96, 0}, {80, 6}, {80, -6}, {96, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {8.93, -67.2}, {17.1, -59.3}, {27.3, -53.6}, {42.1, -49.4}, {69.90000000000001, -45.8}, {80, -45.1}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-80, -34.9}, {-46.1, -31.4}, {-29.4, -27.1}, {-18.3, -21.5}, {-10.3, -14.5}, {-2.03, -3.17}, {7.97, 11.6}, {15.5, 19.4}, {24.3, 25}, {39, 30}, {62.1, 33.5}, {80, 34.9}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-80, 45.1}, {-45.9, 48.7}, {-29.1, 52.9}, {-18.1, 58.6}, {-10.2, 65.8}, {-1.82, 77.2}, {0, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-32, 89}, {-10, 74}}, textString = "pi", lineColor = {0, 0, 255}), Text(extent = {{-32, -72}, {-4, -88}}, textString = "-pi", lineColor = {0, 0, 255}), Text(extent = {{0, 55}, {20, 42}}, textString = "pi/2", lineColor = {0, 0, 255}), Line(points = {{0, 40}, {-8, 40}}, color = {192, 192, 192}), Line(points = {{0, -40}, {-8, -40}}, color = {192, 192, 192}), Text(extent = {{0, -23}, {20, -42}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{62, -4}, {94, -26}}, lineColor = {95, 95, 95}, textString = "u1, u2"), Line(points = {{-88, 40}, {86, 40}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-86, -40}, {86, -40}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<HTML>
       <p>
       This function returns y = atan2(u1,u2) such that tan(y) = u1/u2 and
       y is in the range -pi &lt; y &le; pi. u2 may be zero, provided
       u1 is not zero. Usually u1, u2 is provided in such a form that
       u1 = sin(y) and u2 = cos(y):
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/atan2.png\">
       </p>

       </html>"));
    end atan2;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u);
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.90000000000001}, {-6.03, -74}, {10.9, -68.40000000000001}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.09999999999999, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.90000000000001}, {-6.03, -74}, {10.9, -68.40000000000001}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.09999999999999, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
       <p>
       This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
       </p>

       <p>
       <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
       </p>
       </html>"));
    end exp;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.40000000000001}, {-49.4, 74.59999999999999}, {-43.8, 79.09999999999999}, {-38.2, 79.8}, {-32.6, 76.59999999999999}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.09999999999999}, {35, -78.40000000000001}, {40.6, -80}, {46.2, -77.59999999999999}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}), Documentation(info = "<HTML>
     <p>
     This package contains <b>basic mathematical functions</b> (such as sin(..)),
     as well as functions operating on
     <a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
     <a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
     <a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
     <a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
     </p>

     <dl>
     <dt><b>Main Authors:</b>
     <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
         Marcus Baur<br>
         Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
         Institut f&uuml;r Robotik und Mechatronik<br>
         Postfach 1116<br>
         D-82230 Wessling<br>
         Germany<br>
         email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
     </dl>

     <p>
     Copyright &copy; 1998-2013, Modelica Association and DLR.
     </p>
     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>
     </html>", revisions = "<html>
     <ul>
     <li><i>October 21, 2002</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
            and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
            Function tempInterpol2 added.</li>
     <li><i>Oct. 24, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Icons for icon and diagram level introduced.</li>
     <li><i>June 30, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Realized.</li>
     </ul>

     </html>"));
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
            parameter .Modelica.Mechanics.MultiBody.Types.ShapeType shapeType = "box" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
            input .Modelica.Mechanics.MultiBody.Frames.Orientation R = .Modelica.Mechanics.MultiBody.Frames.nullRotation() "Orientation object to rotate the world frame into the object frame" annotation();
            input .Modelica.SIunits.Position[3] r = {0, 0, 0} "Position vector from origin of world frame to origin of object frame, resolved in world frame" annotation();
            input .Modelica.SIunits.Position[3] r_shape = {0, 0, 0} "Position vector from origin of object frame to shape origin, resolved in object frame" annotation();
            input Real[3] lengthDirection(each final unit = "1") = {1, 0, 0} "Vector in length direction, resolved in object frame" annotation();
            input Real[3] widthDirection(each final unit = "1") = {0, 1, 0} "Vector in width direction, resolved in object frame" annotation();
            input .Modelica.SIunits.Length length = 0 "Length of visual object" annotation();
            input .Modelica.SIunits.Length width = 0 "Width of visual object" annotation();
            input .Modelica.SIunits.Length height = 0 "Height of visual object" annotation();
            input .Modelica.Mechanics.MultiBody.Types.ShapeExtra extra = 0.0 "Additional size data for some of the shape types" annotation();
            input Real[3] color = {255, 0, 0} "Color of shape" annotation(Dialog(colorSelector = true));
            input .Modelica.Mechanics.MultiBody.Types.SpecularCoefficient specularCoefficient = 0.7 "Reflection of ambient light (= 0: light is completely absorbed)" annotation();
            annotation(Documentation(info = "<html>

             <p>
             This model is documented at
             <a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>.
             </p>

             </html>"));
          end PartialShape;
        end Animation;
        annotation(Documentation(info = "<html>

         <p>
         This package contains interfaces of a set of functions and models used in the
         Modelica Standard Library that requires a <b>tool specific implementation</b>.
         There is an associated package called <b>ModelicaServices</b>. A tool vendor
         should provide a proper implementation of this library for the corresponding
         tool. The default implementation is \"do nothing\".
         In the Modelica Standard Library, the models and functions of ModelicaServices
         are used.
         </p>
         </html>"));
      end PartialModelicaServices;
    end Internal;
    annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {1.3835, -4.1418}, rotation = 45.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.0, 93.333}, {-15.0, 68.333}, {0.0, 58.333}, {15.0, 68.333}, {15.0, 93.333}, {20.0, 93.333}, {25.0, 83.333}, {25.0, 58.333}, {10.0, 43.333}, {10.0, -41.667}, {25.0, -56.667}, {25.0, -76.667}, {10.0, -91.667}, {0.0, -91.667}, {0.0, -81.667}, {5.0, -81.667}, {15.0, -71.667}, {15.0, -61.667}, {5.0, -51.667}, {-5.0, -51.667}, {-15.0, -61.667}, {-15.0, -71.667}, {-5.0, -81.667}, {0.0, -81.667}, {0.0, -91.667}, {-10.0, -91.667}, {-25.0, -76.667}, {-25.0, -56.667}, {-10.0, -41.667}, {-10.0, 43.333}, {-25.0, 58.333}, {-25.0, 83.333}, {-20.0, 93.333}}), Polygon(origin = {10.1018, 5.218}, rotation = -45.0, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-15.0, 87.273}, {15.0, 87.273}, {20.0, 82.273}, {20.0, 27.273}, {10.0, 17.273}, {10.0, 7.273}, {20.0, 2.273}, {20.0, -2.727}, {5.0, -2.727}, {5.0, -77.727}, {10.0, -87.727}, {5.0, -112.727}, {-5.0, -112.727}, {-10.0, -87.727}, {-5.0, -77.727}, {-5.0, -2.727}, {-20.0, -2.727}, {-20.0, 2.273}, {-10.0, 7.273}, {-10.0, 17.273}, {-20.0, 27.273}, {-20.0, 82.273}})}), Documentation(info = "<html>
     <p>
     This package contains Modelica <b>functions</b> that are
     especially suited for <b>scripting</b>. The functions might
     be used to work with strings, read data from file, write data
     to file or copy, move and remove files.
     </p>
     <p>
     For an introduction, have especially a look at:
     </p>
     <ul>
     <li> <a href=\"modelica://Modelica.Utilities.UsersGuide\">Modelica.Utilities.User's Guide</a>
          discusses the most important aspects of this library.</li>
     <li> <a href=\"modelica://Modelica.Utilities.Examples\">Modelica.Utilities.Examples</a>
          contains examples that demonstrate the usage of this library.</li>
     </ul>
     <p>
     The following main sublibraries are available:
     </p>
     <ul>
     <li> <a href=\"modelica://Modelica.Utilities.Files\">Files</a>
          provides functions to operate on files and directories, e.g.,
          to copy, move, remove files.</li>
     <li> <a href=\"modelica://Modelica.Utilities.Streams\">Streams</a>
          provides functions to read from files and write to files.</li>
     <li> <a href=\"modelica://Modelica.Utilities.Strings\">Strings</a>
          provides functions to operate on strings. E.g.
          substring, find, replace, sort, scanToken.</li>
     <li> <a href=\"modelica://Modelica.Utilities.System\">System</a>
          provides functions to interact with the environment.
          E.g., get or set the working directory or environment
          variables and to send a command to the default shell.</li>
     </ul>

     <p>
     Copyright &copy; 1998-2013, Modelica Association, DLR, and Dassault Syst&egrave;mes AB.
     </p>

     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>

     </html>"));
  end Utilities;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant Real inf = ModelicaServices.Machine.inf "Biggest Real number such that inf and -inf are representable on the machine";
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1e-007 "Magnetic constant";
    annotation(Documentation(info = "<html>
     <p>
     This package provides often needed constants from mathematics, machine
     dependent constants and constants from nature. The latter constants
     (name, value, description) are from the following source:
     </p>

     <dl>
     <dt>Peter J. Mohr and Barry N. Taylor (1999):</dt>
     <dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
         Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
         Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also <a href=
     \"http://physics.nist.gov/cuu/Constants/\">http://physics.nist.gov/cuu/Constants/</a></dd>
     </dl>

     <p>CODATA is the Committee on Data for Science and Technology.</p>

     <dl>
     <dt><b>Main Author:</b></dt>
     <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
         Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
         Oberpfaffenhofen<br>
         Postfach 11 16<br>
         D-82230 We&szlig;ling<br>
         email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
     </dl>

     <p>
     Copyright &copy; 1998-2013, Modelica Association and DLR.
     </p>
     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>
     </html>", revisions = "<html>
     <ul>
     <li><i>Nov 8, 2004</i>
            by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
            Constants updated according to 2002 CODATA values.</li>
     <li><i>Dec 9, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Constants updated according to 1998 CODATA values. Using names, values
            and description text from this source. Included magnetic and
            electric constant.</li>
     <li><i>Sep 18, 1999</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Constants eps, inf, small introduced.</li>
     <li><i>Nov 15, 1997</i>
            by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
            Realized.</li>
     </ul>
     </html>"), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-9.2597, 25.6673}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{48.017, 11.336}, {48.017, 11.336}, {10.766, 11.336}, {-25.684, 10.95}, {-34.944, -15.111}, {-34.944, -15.111}, {-32.298, -15.244}, {-32.298, -15.244}, {-22.112, 0.168}, {11.292, 0.234}, {48.267, -0.097}, {48.267, -0.097}}, smooth = Smooth.Bezier), Polygon(origin = {-19.9923, -8.3993}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{3.239, 37.343}, {3.305, 37.343}, {-0.399, 2.683}, {-16.936, -20.071}, {-7.808, -28.604}, {6.811, -22.519}, {9.986000000000001, 37.145}, {9.986000000000001, 37.145}}, smooth = Smooth.Bezier), Polygon(origin = {23.753, -11.5422}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.873, 41.478}, {-10.873, 41.478}, {-14.048, -4.162}, {-9.352, -24.8}, {7.912, -24.469}, {16.247, 0.27}, {16.247, 0.27}, {13.336, 0.07099999999999999}, {13.336, 0.07099999999999999}, {7.515, -9.983000000000001}, {-3.134, -7.271}, {-2.671, 41.214}, {-2.671, 41.214}}, smooth = Smooth.Bezier)}));
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package Package  "Icon for standard packages"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {248, 248, 248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Rectangle(lineColor = {128, 128, 128}, fillPattern = FillPattern.None, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0)}), Documentation(info = "<html>
      <p>Standard package icon.</p>
      </html>")); end Package;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {20.0, 0.0}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-10.0, 70.0}, {10.0, 70.0}, {40.0, 20.0}, {80.0, 20.0}, {80.0, -20.0}, {40.0, -20.0}, {10.0, -70.0}, {-10.0, -70.0}}), Polygon(fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-100.0, 20.0}, {-60.0, 20.0}, {-30.0, 70.0}, {-10.0, 70.0}, {-10.0, -70.0}, {-30.0, -70.0}, {-60.0, -20.0}, {-100.0, -20.0}})}), Documentation(info = "<html>
       <p>This icon indicates packages containing interfaces.</p>
       </html>"));
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {23.3333, 0.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-23.333, 30.0}, {46.667, 0.0}, {-23.333, -30.0}}), Rectangle(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-70, -4.5}, {0, 4.5}})}), Documentation(info = "<html>
       <p>This icon indicates a package which contains sources.</p>
       </html>"));
    end SourcesPackage;

    partial package TypesPackage  "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-12.167, -23}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{12.167, 65}, {14.167, 93}, {36.167, 89}, {24.167, 20}, {4.167, -30}, {14.167, -30}, {24.167, -30}, {24.167, -40}, {-5.833, -50}, {-15.833, -30}, {4.167, 20}, {12.167, 65}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Polygon(origin = {2.7403, 1.6673}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{49.2597, 22.3327}, {31.2597, 24.3327}, {7.2597, 18.3327}, {-26.7403, 10.3327}, {-46.7403, 14.3327}, {-48.7403, 6.3327}, {-32.7403, 0.3327}, {-6.7403, 4.3327}, {33.2597, 14.3327}, {49.2597, 14.3327}, {49.2597, 22.3327}}, smooth = Smooth.Bezier)}));
    end TypesPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}));
    end IconsPackage;

    partial package InternalPackage  "Icon for an internal package (indicating that the package should not be directly utilized by user)"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {215, 215, 215}, fillColor = {255, 255, 255}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100, -100}, {100, 100}}, radius = 25), Rectangle(lineColor = {215, 215, 215}, fillPattern = FillPattern.None, extent = {{-100, -100}, {100, 100}}, radius = 25), Ellipse(extent = {{-80, 80}, {80, -80}}, lineColor = {215, 215, 215}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-55, 55}, {55, -55}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-60, 14}, {60, -14}}, lineColor = {215, 215, 215}, fillColor = {215, 215, 215}, fillPattern = FillPattern.Solid, origin = {0, 0}, rotation = 45)}), Documentation(info = "<html>

      <p>
      This icon shall be used for a package that contains internal classes not to be
      directly utilized by a user.
      </p>
      </html>")); end InternalPackage;

    partial function Function  "Icon for functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 105}, {150, 145}}, textString = "%name"), Ellipse(lineColor = {108, 88, 49}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Text(lineColor = {108, 88, 49}, extent = {{-90.0, -90.0}, {90.0, 90.0}}, textString = "f")}), Documentation(info = "<html>
      <p>This icon indicates Modelica functions.</p>
      </html>")); end Function;

    partial record Record  "Icon for records"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 60}, {150, 100}}, textString = "%name"), Rectangle(origin = {0.0, -25.0}, lineColor = {64, 64, 64}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100.0, -75.0}, {100.0, 75.0}}, radius = 25.0), Line(points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -50.0}, points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -25.0}, points = {{0.0, 75.0}, {0.0, -75.0}}, color = {64, 64, 64})}), Documentation(info = "<html>
      <p>
      This icon is indicates a record.
      </p>
      </html>")); end Record;

    type TypeReal  "Icon for Real types"
      extends Real;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Text(lineColor = {255, 255, 255}, extent = {{-90.0, -50.0}, {90.0, 50.0}}, textString = "R")}), Documentation(info = "<html>
       <p>
       This icon is designed for a <b>Real</b> type.
       </p>
       </html>"));
    end TypeReal;

    type TypeInteger  "Icon for Integer types"
      extends Integer;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Text(lineColor = {255, 255, 255}, extent = {{-90.0, -50.0}, {90.0, 50.0}}, textString = "I")}), Documentation(info = "<html>
       <p>
       This icon is designed for an <b>Integer</b> type.
       </p>
       </html>"));
    end TypeInteger;

    type TypeString  "Icon for String types"
      extends String;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Text(lineColor = {255, 255, 255}, extent = {{-90.0, -50.0}, {90.0, 50.0}}, textString = "S")}), Documentation(info = "<html>
       <p>
       This icon is designed for a <b>String</b> type.
       </p>
       </html>"));
    end TypeString;
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}), Documentation(info = "<html>
     <p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer. </p>

     <h4>Main Authors:</h4>

     <dl>
     <dt><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dt>
         <dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd>
         <dd>Oberpfaffenhofen</dd>
         <dd>Postfach 1116</dd>
         <dd>D-82230 Wessling</dd>
         <dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
     <dt>Christian Kral</dt>
         <dd><a href=\"http://christiankral.net/\">Electric Machines, Drives and Systems</a></dd>
         <dd>1060 Vienna, Austria</dd>
         <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
     <dt>Johan Andreasson</dt>
         <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>
         <dd>Ideon Science Park</dd>
         <dd>22370 Lund, Sweden</dd>
         <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
     </dl>

     <p>Copyright &copy; 1998-2013, Modelica Association, DLR, AIT, and Modelon AB. </p>
     <p><i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified under the terms of the <b>Modelica license</b>, see the license conditions and the accompanying <b>disclaimer</b> in <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a>.</i> </p>
     </html>"));
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Icons  "Icons for SIunits"
      extends Modelica.Icons.IconsPackage;

      partial function Conversion  "Base icon for conversion functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {191, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-90, 0}, {30, 0}}, color = {191, 0, 0}), Polygon(points = {{90, 0}, {30, 20}, {30, -20}, {90, 0}}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-115, 155}, {115, 105}}, textString = "%name", lineColor = {0, 0, 255})})); end Conversion;
    end Icons;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
        annotation(Documentation(info = "<HTML>
         <p>
         This package provides predefined types, such as <b>Angle_deg</b> (angle in
         degree), <b>AngularVelocity_rpm</b> (angular velocity in revolutions per
         minute) or <b>Temperature_degF</b> (temperature in degree Fahrenheit),
         which are in common use but are not part of the international standard on
         units according to ISO 31-1992 \"General principles concerning quantities,
         units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
         the use of their multiples and of certain other units\".</p>
         <p>If possible, the types in this package should not be used. Use instead
         types of package Modelica.SIunits. For more information on units, see also
         the book of Francois Cardarelli <b>Scientific Unit Conversion - A
         Practical Guide to Metrication</b> (Springer 1997).</p>
         <p>Some units, such as <b>Temperature_degC/Temp_C</b> are both defined in
         Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
         definitions have been placed erroneously in Modelica.SIunits although they
         are not SIunits. For backward compatibility, these type definitions are
         still kept in Modelica.SIunits.</p>
         </html>"), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Text(origin = {15.0, 51.8518}, extent = {{-105.0, -86.8518}, {75.0, -16.8518}}, lineColor = {0, 0, 0}, textString = "[km/h]")}));
      end NonSIunits;

      function to_unit1  "Change the unit of a Real number to unit=\"1\""
        extends Modelica.SIunits.Icons.Conversion;
        input Real r "Real number";
        output Real result(unit = "1") "Real number r with unit=\"1\"";
      algorithm
        result := r;
        annotation(Inline = true, Documentation(info = "<HTML>
         <h4>Syntax</h4>
         <blockquote><pre>
         SIunits.Conversions.<b>to_unit1</b>(r);
         </pre></blockquote>
         <h4>Description</h4>
         <p>
         The function call \"<code>Conversions.<b>to_unit1</b>(r)</code>\" returns r with unit=\"1\".

         <h4>Example</h4>
         <blockquote><pre>
           Modelica.SIunits.Velocity v = {3,2,1};
           Real direction[3](unit=\"1\") = to_unit1(v);   // Automatically vectorized call of to_unit1
         </pre></blockquote>
         </HTML>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-90, 86}, {32, 50}}, lineColor = {0, 0, 0}, textString = "any", horizontalAlignment = TextAlignment.Left), Text(extent = {{-36, -52}, {86, -88}}, lineColor = {0, 0, 0}, horizontalAlignment = TextAlignment.Right, textString = "1")}));
      end to_unit1;
      annotation(Documentation(info = "<HTML>
       <p>This package provides conversion functions from the non SI Units
       defined in package Modelica.SIunits.Conversions.NonSIunits to the
       corresponding SI Units defined in package Modelica.SIunits and vice
       versa. It is recommended to use these functions in the following
       way (note, that all functions have one Real input and one Real output
       argument):</p>
       <pre>
         <b>import</b> SI = Modelica.SIunits;
         <b>import</b> Modelica.SIunits.Conversions.*;
            ...
         <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
         <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
         <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                             // to radian per seconds
       </pre>

       </html>"));
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Length = Real(final quantity = "Length", final unit = "m");
    type Position = Length;
    type Distance = Length(min = 0);
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
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-66, 78}, {-66, -40}}, color = {64, 64, 64}, smooth = Smooth.None), Ellipse(extent = {{12, 36}, {68, -38}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-74, 78}, {-66, -40}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-66, -4}, {-66, 6}, {-16, 56}, {-16, 46}, {-66, -4}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-46, 16}, {-40, 22}, {-2, -40}, {-10, -40}, {-46, 16}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Ellipse(extent = {{22, 26}, {58, -28}}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{68, 2}, {68, -46}, {64, -60}, {58, -68}, {48, -72}, {18, -72}, {18, -64}, {46, -64}, {54, -60}, {58, -54}, {60, -46}, {60, -26}, {64, -20}, {68, -6}, {68, 2}}, lineColor = {64, 64, 64}, smooth = Smooth.Bezier, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
     <p>This package provides predefined types, such as <i>Mass</i>,
     <i>Angle</i>, <i>Time</i>, based on the international standard
     on units, e.g.,
     </p>

     <pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                          <b>final</b> unit     = \"rad\",
                          displayUnit    = \"deg\");
     </pre>

     <p>
     as well as conversion functions from non SI-units to SI-units
     and vice versa in subpackage
     <a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
     </p>

     <p>
     For an introduction how units are used in the Modelica standard library
     with package SIunits, have a look at:
     <a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
     </p>

     <p>
     Copyright &copy; 1998-2013, Modelica Association and DLR.
     </p>
     <p>
     <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
     </p>
     </html>", revisions = "<html>
     <ul>
     <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added molar units for energy and enthalpy.</li>
     <li><i>Jan. 27, 2010</i> by Christian Kral:<br/>Added complex units.</li>
     <li><i>Dec. 14, 2005</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
     <li><i>October 21, 2002</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br/>Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
     <li><i>June 6, 2000</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
     <li><i>Oct. 27, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
     <li><i>Sept. 18, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
     <li><i>Aug 12, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
     <li><i>June 29, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
     <li><i>April 8, 1998</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
     <li><i>Nov. 15, 1997</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br/>Some chapters realized.</li>
     </ul>
     </html>"));
  end SIunits;
  annotation(preferredView = "info", version = "3.2.1", versionBuild = 4, versionDate = "2014-02-13", dateModified = "2013-08-23 19:30:00Z", revisionId = "$Id:: package.mo 7364 2014-03-01 16:14:56Z #$", uses(Complex(version = "3.2.1"), ModelicaServices(version = "3.2.1")), conversion(noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-6.9888, 20.048}, fillColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112, 10.3188}, {-93.0112, 10.3188}, {-73.011, 24.6}, {-63.011, 31.221}, {-51.219, 36.777}, {-39.842, 38.629}, {-31.376, 36.248}, {-25.819, 29.369}, {-24.232, 22.49}, {-23.703, 17.463}, {-15.501, 25.135}, {-6.24, 32.015}, {3.02, 36.777}, {15.191, 39.423}, {27.097, 37.306}, {32.653, 29.633}, {35.035, 20.108}, {43.501, 28.046}, {54.085, 35.19}, {65.991, 39.952}, {77.89700000000001, 39.688}, {87.422, 33.338}, {91.126, 21.696}, {90.068, 9.525}, {86.099, -1.058}, {79.749, -10.054}, {71.283, -21.431}, {62.816, -33.337}, {60.964, -32.808}, {70.489, -16.14}, {77.36799999999999, -2.381}, {81.072, 10.054}, {79.749, 19.05}, {72.605, 24.342}, {61.758, 23.019}, {49.587, 14.817}, {39.003, 4.763}, {29.214, -6.085}, {21.012, -16.669}, {13.339, -26.458}, {5.401, -36.777}, {-1.213, -46.037}, {-6.24, -53.446}, {-8.092000000000001, -52.387}, {-0.6840000000000001, -40.746}, {5.401, -30.692}, {12.81, -17.198}, {19.424, -3.969}, {23.658, 7.938}, {22.335, 18.785}, {16.514, 23.283}, {8.047000000000001, 23.019}, {-1.478, 19.05}, {-11.267, 11.113}, {-19.734, 2.381}, {-29.259, -8.202}, {-38.519, -19.579}, {-48.044, -31.221}, {-56.511, -43.392}, {-64.449, -55.298}, {-72.386, -66.93899999999999}, {-77.678, -74.61199999999999}, {-79.53, -74.083}, {-71.857, -61.383}, {-62.861, -46.037}, {-52.278, -28.046}, {-44.869, -15.346}, {-38.784, -2.117}, {-35.344, 8.731}, {-36.403, 19.844}, {-42.488, 23.813}, {-52.013, 22.49}, {-60.744, 16.933}, {-68.947, 10.054}, {-76.884, 2.646}, {-93.0112, -12.1707}, {-93.0112, -12.1707}}, smooth = Smooth.Bezier), Ellipse(origin = {40.8208, -37.7602}, fillColor = {161, 0, 4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562, -17.8563}, {17.8563, 17.8562}})}), Documentation(info = "<HTML>
   <p>
   Package <b>Modelica&reg;</b> is a <b>standardized</b> and <b>free</b> package
   that is developed together with the Modelica&reg; language from the
   Modelica Association, see
   <a href=\"https://www.Modelica.org\">https://www.Modelica.org</a>.
   It is also called <b>Modelica Standard Library</b>.
   It provides model components in many domains that are based on
   standardized interface definitions. Some typical examples are shown
   in the next figure:
   </p>

   <p>
   <img src=\"modelica://Modelica/Resources/Images/UsersGuide/ModelicaLibraries.png\">
   </p>

   <p>
   For an introduction, have especially a look at:
   </p>
   <ul>
   <li> <a href=\"modelica://Modelica.UsersGuide.Overview\">Overview</a>
     provides an overview of the Modelica Standard Library
     inside the <a href=\"modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
   <li><a href=\"modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
    summarizes the changes of new versions of this package.</li>
   <li> <a href=\"modelica://Modelica.UsersGuide.Contact\">Contact</a>
     lists the contributors of the Modelica Standard Library.</li>
   <li> The <b>Examples</b> packages in the various libraries, demonstrate
     how to use the components of the corresponding sublibrary.</li>
   </ul>

   <p>
   This version of the Modelica Standard Library consists of
   </p>
   <ul>
   <li><b>1360</b> models and blocks, and</li>
   <li><b>1280</b> functions</li>
   </ul>
   <p>
   that are directly usable (= number of public, non-partial classes). It is fully compliant
   to <a href=\"https://www.modelica.org/documents/ModelicaSpec32Revision2.pdf\">Modelica Specification Version 3.2 Revision 2</a>
   and it has been tested with Modelica tools from different vendors.
   </p>

   <p>
   <b>Licensed by the Modelica Association under the Modelica License 2</b><br>
   Copyright &copy; 1998-2013, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, Fraunhofer, A.&nbsp;Haumer, ITI, C.&nbsp;Kral, Modelon,
   TU Hamburg-Harburg, Politecnico di Milano, XRG Simulation.
   </p>

   <p>
   <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
   </p>

   <p>
   <b>Modelica&reg;</b> is a registered trademark of the Modelica Association.
   </p>
   </html>"));
end Modelica;


model InnerOuterSamePrefix
  B pendulum annotation(Placement(visible = true, transformation(origin = {-22.679, 7.56}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  model B
    inner Modelica.Mechanics.MultiBody.World world annotation(Placement(visible = true, transformation(origin = {-72.44499999999999, 5}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.MultiBody.Parts.BodyCylinder pendulum annotation(Placement(visible = true, transformation(origin = {0, 2.165}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Mechanics.MultiBody.Joints.Revolute revolute annotation(Placement(visible = true, transformation(origin = {-41.811, 5}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
    connect(revolute.frame_b, pendulum.frame_a) annotation(Line(visible = true, origin = {-16.959, 3.583}, points = {{-14.852, 1.417}, {3.946, 1.417}, {3.946, -1.417}, {6.959, -1.417}}));
    connect(world.frame_b, revolute.frame_a) annotation(Line(visible = true, origin = {-57.128, 5}, points = {{-5.317, 0}, {5.317, 0}}));
    annotation(Diagram(coordinateSystem(extent = {{-148.5, -105}, {148.5, 105}}, preserveAspectRatio = true, initialScale = 0.1, grid = {5, 5})));
  end B;
  annotation(Diagram(coordinateSystem(extent = {{-148.5, -105}, {148.5, 105}}, preserveAspectRatio = true, initialScale = 0.1, grid = {5, 5})));
end InnerOuterSamePrefix;// Result:


// Result:
// function Modelica.Math.Vectors.length "Inline before index reduction" "Return length of a vector (better as norm(), if further symbolic processing is performed)"
//   input Real[:] v "Vector";
//   output Real result "Length of vector v";
// algorithm
//   result := sqrt(v * v);
// end Modelica.Math.Vectors.length;
//
// function Modelica.Math.Vectors.normalize "Inline before index reduction" "Return normalized vector such that length = 1 and prevent zero-division for zero vector"
//   input Real[:] v "Vector";
//   input Real eps(min = 0.0) = 1e-13 "if |v| < eps then result = v/eps";
//   output Real[size(v, 1)] result "Input vector v normalized to length=1";
// algorithm
//   result := smooth(0, if noEvent(Modelica.Math.Vectors.length(v) >= eps) then v / Modelica.Math.Vectors.length(v) else v / eps);
// end Modelica.Math.Vectors.normalize;
//
// function Modelica.Math.Vectors.normalizeWithAssert "Inline before index reduction" "Return normalized vector such that length = 1 (trigger an assert for zero vector)"
//   input Real[:] v "Vector";
//   output Real[size(v, 1)] result "Input vector v normalized to length=1";
// algorithm
//   assert(Modelica.Math.Vectors.length(v) > 0.0, "Vector v={0,0,0} shall be normalized (= v/sqrt(v*v)), but this results in a division by zero.
//   Provide a non-zero vector!");
//   result := v / Modelica.Math.Vectors.length(v);
// end Modelica.Math.Vectors.normalizeWithAssert;
//
// function Modelica.Mechanics.MultiBody.Frames.Internal.resolve1_der "Inline before index reduction" "Derivative of function Frames.resolve1(..)"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v2 "Vector resolved in frame 2";
//   input Real[3] v2_der "= der(v2)";
//   output Real[3] v1_der "Derivative of vector v resolved in frame 1";
// algorithm
//   v1_der := Modelica.Mechanics.MultiBody.Frames.resolve1(R, {v2_der[1] + R.w[2] * v2[3] - R.w[3] * v2[2], v2_der[2] + R.w[3] * v2[1] - R.w[1] * v2[3], v2_der[3] + R.w[1] * v2[2] - R.w[2] * v2[1]});
// end Modelica.Mechanics.MultiBody.Frames.Internal.resolve1_der;
//
// function Modelica.Mechanics.MultiBody.Frames.Internal.resolve2_der "Inline before index reduction" "Derivative of function Frames.resolve2(..)"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v1 "Vector resolved in frame 1";
//   input Real[3] v1_der "= der(v1)";
//   output Real[3] v2_der "Derivative of vector v resolved in frame 2";
// algorithm
//   v2_der := Modelica.Mechanics.MultiBody.Frames.resolve2(R, {v1_der[1], v1_der[2], v1_der[3]}) - cross({R.w[1], R.w[2], R.w[3]}, Modelica.Mechanics.MultiBody.Frames.resolve2(R, {v1[1], v1[2], v1[3]}));
// end Modelica.Mechanics.MultiBody.Frames.Internal.resolve2_der;
//
// function Modelica.Mechanics.MultiBody.Frames.Orientation "Automatically generated record constructor for Modelica.Mechanics.MultiBody.Frames.Orientation"
//   input Real[3, 3] T;
//   input Real[3] w(quantity = "AngularVelocity", unit = "rad/s");
//   output Orientation res;
// end Modelica.Mechanics.MultiBody.Frames.Orientation;
//
// function Modelica.Mechanics.MultiBody.Frames.Orientation.equalityConstraint "Inline before index reduction" "Return the constraint residues to express that two frames have the same orientation"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R1 "Orientation object to rotate frame 0 into frame 1";
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R2 "Orientation object to rotate frame 0 into frame 2";
//   output Real[3] residue "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)";
// algorithm
//   residue := {atan2((R1.T[1,2] * R1.T[2,3] - R1.T[1,3] * R1.T[2,2]) * R2.T[2,1] + (R1.T[1,3] * R1.T[2,1] - R1.T[1,1] * R1.T[2,3]) * R2.T[2,2] + (R1.T[1,1] * R1.T[2,2] - R1.T[1,2] * R1.T[2,1]) * R2.T[2,3], R1.T[1,1] * R2.T[1,1] + R1.T[1,2] * R2.T[1,2] + R1.T[1,3] * R2.T[1,3]), atan2((R1.T[1,1] * R1.T[2,3] - R1.T[1,3] * R1.T[2,1]) * R2.T[1,2] - (R1.T[1,1] * R1.T[2,2] - R1.T[1,2] * R1.T[2,1]) * R2.T[1,3] - (R1.T[1,2] * R1.T[2,3] - R1.T[1,3] * R1.T[2,2]) * R2.T[1,1], R1.T[2,1] * R2.T[2,1] + R1.T[2,2] * R2.T[2,2] + R1.T[2,3] * R2.T[2,3]), atan2(R1.T[2,1] * R2.T[1,1] + R1.T[2,2] * R2.T[1,2] + R1.T[2,3] * R2.T[1,3], R1.T[3,1] * R2.T[3,1] + R1.T[3,2] * R2.T[3,2] + R1.T[3,3] * R2.T[3,3])};
// end Modelica.Mechanics.MultiBody.Frames.Orientation.equalityConstraint;
//
// function Modelica.Mechanics.MultiBody.Frames.Quaternions.angularVelocity2 "Inline before index reduction" "Compute angular velocity resolved in frame 2 from quaternions orientation object and its derivative"
//   input Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
//   input Real[4] der_Q(unit = "1/s") "Derivative of Q";
//   output Real[3] w(quantity = "AngularVelocity", unit = "rad/s") "Angular velocity of frame 2 with respect to frame 1 resolved in frame 2";
// algorithm
//   w := {Q[4] * 2.0 * der_Q[1] + Q[3] * 2.0 * der_Q[2] + (-Q[2]) * 2.0 * der_Q[3] + (-Q[1]) * 2.0 * der_Q[4], (-Q[3]) * 2.0 * der_Q[1] + Q[4] * 2.0 * der_Q[2] + Q[1] * 2.0 * der_Q[3] + (-Q[2]) * 2.0 * der_Q[4], Q[2] * 2.0 * der_Q[1] + (-Q[1]) * 2.0 * der_Q[2] + Q[4] * 2.0 * der_Q[3] + (-Q[3]) * 2.0 * der_Q[4]};
// end Modelica.Mechanics.MultiBody.Frames.Quaternions.angularVelocity2;
//
// function Modelica.Mechanics.MultiBody.Frames.Quaternions.from_T "Return quaternion orientation object Q from transformation matrix T"
//   input Real[3, 3] T "Transformation matrix to transform vector from frame 1 to frame 2 (v2=T*v1)";
//   input Real[4] Q_guess = {0.0, 0.0, 0.0, 1.0} "Guess value for Q (there are 2 solutions; the one close to Q_guess is used";
//   output Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2 (Q and -Q have same transformation matrix)";
//   protected Real paux;
//   protected Real paux4;
//   protected Real c1;
//   protected Real c2;
//   protected Real c3;
//   protected Real c4;
//   protected constant Real p4limit = 0.1;
//   protected constant Real c4limit = 0.04000000000000001;
// algorithm
//   c1 := 1.0 + T[1,1] + (-T[2,2]) - T[3,3];
//   c2 := 1.0 + T[2,2] + (-T[1,1]) - T[3,3];
//   c3 := 1.0 + T[3,3] + (-T[1,1]) - T[2,2];
//   c4 := 1.0 + T[1,1] + T[2,2] + T[3,3];
//   if c4 > 0.04000000000000001 or c4 > c1 and c4 > c2 and c4 > c3 then
//     paux := 0.5 * sqrt(c4);
//     paux4 := 4.0 * paux;
//     Q := {(T[2,3] - T[3,2]) / paux4, (T[3,1] - T[1,3]) / paux4, (T[1,2] - T[2,1]) / paux4, paux};
//   elseif c1 > c2 and c1 > c3 and c1 > c4 then
//     paux := 0.5 * sqrt(c1);
//     paux4 := 4.0 * paux;
//     Q := {paux, (T[1,2] + T[2,1]) / paux4, (T[1,3] + T[3,1]) / paux4, (T[2,3] - T[3,2]) / paux4};
//   elseif c2 > c1 and c2 > c3 and c2 > c4 then
//     paux := 0.5 * sqrt(c2);
//     paux4 := 4.0 * paux;
//     Q := {(T[1,2] + T[2,1]) / paux4, paux, (T[2,3] + T[3,2]) / paux4, (T[3,1] - T[1,3]) / paux4};
//   else
//     paux := 0.5 * sqrt(c3);
//     paux4 := 4.0 * paux;
//     Q := {(T[1,3] + T[3,1]) / paux4, (T[2,3] + T[3,2]) / paux4, paux, (T[1,2] - T[2,1]) / paux4};
//   end if;
//   if Q[1] * Q_guess[1] + Q[2] * Q_guess[2] + Q[3] * Q_guess[3] + Q[4] * Q_guess[4] < 0.0 then
//     Q := {-Q[1], -Q[2], -Q[3], -Q[4]};
//   end if;
// end Modelica.Mechanics.MultiBody.Frames.Quaternions.from_T;
//
// function Modelica.Mechanics.MultiBody.Frames.Quaternions.nullRotation "Inline before index reduction" "Return quaternion orientation object that does not rotate a frame"
//   output Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
// algorithm
//   Q := {0.0, 0.0, 0.0, 1.0};
// end Modelica.Mechanics.MultiBody.Frames.Quaternions.nullRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.Quaternions.orientationConstraint "Inline before index reduction" "Return residues of orientation constraints (shall be zero)"
//   input Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
//   output Real[1] residue "Residue constraint (shall be zero)";
// algorithm
//   residue := {-1.0 + Q[1] ^ 2.0 + Q[2] ^ 2.0 + Q[3] ^ 2.0 + Q[4] ^ 2.0};
// end Modelica.Mechanics.MultiBody.Frames.Quaternions.orientationConstraint;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.absoluteRotation "Inline before index reduction" "Return absolute orientation object from another absolute and a relative orientation object"
//   input Real[3, 3] T1 "Orientation object to rotate frame 0 into frame 1";
//   input Real[3, 3] T_rel "Orientation object to rotate frame 1 into frame 2";
//   output Real[3, 3] T2 "Orientation object to rotate frame 0 into frame 2";
// algorithm
//   T2 := {{T_rel[1,1] * T1[1,1] + T_rel[1,2] * T1[2,1] + T_rel[1,3] * T1[3,1], T_rel[1,1] * T1[1,2] + T_rel[1,2] * T1[2,2] + T_rel[1,3] * T1[3,2], T_rel[1,1] * T1[1,3] + T_rel[1,2] * T1[2,3] + T_rel[1,3] * T1[3,3]}, {T_rel[2,1] * T1[1,1] + T_rel[2,2] * T1[2,1] + T_rel[2,3] * T1[3,1], T_rel[2,1] * T1[1,2] + T_rel[2,2] * T1[2,2] + T_rel[2,3] * T1[3,2], T_rel[2,1] * T1[1,3] + T_rel[2,2] * T1[2,3] + T_rel[2,3] * T1[3,3]}, {T_rel[3,1] * T1[1,1] + T_rel[3,2] * T1[2,1] + T_rel[3,3] * T1[3,1], T_rel[3,1] * T1[1,2] + T_rel[3,2] * T1[2,2] + T_rel[3,3] * T1[3,2], T_rel[3,1] * T1[1,3] + T_rel[3,2] * T1[2,3] + T_rel[3,3] * T1[3,3]}};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.absoluteRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation "Inline before index reduction" "Return rotation object to rotate around one frame axis"
//   input Integer axis(min = 1, max = 3) "Rotate around 'axis' of frame 1";
//   input Real angle(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angle to rotate frame 1 into frame 2 along 'axis' of frame 1";
//   output Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   T := if axis == 1 then {{1.0, 0.0, 0.0}, {0.0, cos(angle), sin(angle)}, {0.0, -sin(angle), cos(angle)}} else if axis == 2 then {{cos(angle), 0.0, -sin(angle)}, {0.0, 1.0, 0.0}, {sin(angle), 0.0, cos(angle)}} else {{cos(angle), sin(angle), 0.0}, {-sin(angle), cos(angle), 0.0}, {0.0, 0.0, 1.0}};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.from_nxy "Return orientation object from n_x and n_y vectors"
//   input Real[3] n_x(unit = "1") "Vector in direction of x-axis of frame 2, resolved in frame 1";
//   input Real[3] n_y(unit = "1") "Vector in direction of y-axis of frame 2, resolved in frame 1";
//   output Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
//   protected Real abs_n_x = sqrt(n_x[1] ^ 2.0 + n_x[2] ^ 2.0 + n_x[3] ^ 2.0);
//   protected Real[3] e_x(unit = "1") = if abs_n_x < 1e-10 then {1.0, 0.0, 0.0} else {n_x[1] / abs_n_x, n_x[2] / abs_n_x, n_x[3] / abs_n_x};
//   protected Real[3] n_z_aux(unit = "1") = {e_x[2] * n_y[3] - e_x[3] * n_y[2], e_x[3] * n_y[1] - e_x[1] * n_y[3], e_x[1] * n_y[2] - e_x[2] * n_y[1]};
//   protected Real[3] n_y_aux(unit = "1") = if n_z_aux[1] ^ 2.0 + n_z_aux[2] ^ 2.0 + n_z_aux[3] ^ 2.0 > 1e-06 then {n_y[1], n_y[2], n_y[3]} else if abs(e_x[1]) > 1e-06 then {0.0, 1.0, 0.0} else {1.0, 0.0, 0.0};
//   protected Real[3] e_z_aux(unit = "1") = {e_x[2] * n_y_aux[3] - e_x[3] * n_y_aux[2], e_x[3] * n_y_aux[1] - e_x[1] * n_y_aux[3], e_x[1] * n_y_aux[2] - e_x[2] * n_y_aux[1]};
//   protected Real[3] e_z(unit = "1") = {e_z_aux[1] / sqrt(e_z_aux[1] ^ 2.0 + e_z_aux[2] ^ 2.0 + e_z_aux[3] ^ 2.0), e_z_aux[2] / sqrt(e_z_aux[1] ^ 2.0 + e_z_aux[2] ^ 2.0 + e_z_aux[3] ^ 2.0), e_z_aux[3] / sqrt(e_z_aux[1] ^ 2.0 + e_z_aux[2] ^ 2.0 + e_z_aux[3] ^ 2.0)};
// algorithm
//   T := {{e_x[1], e_x[2], e_x[3]}, {e_z[2] * e_x[3] - e_z[3] * e_x[2], e_z[3] * e_x[1] - e_z[1] * e_x[3], e_z[1] * e_x[2] - e_z[2] * e_x[1]}, {e_z[1], e_z[2], e_z[3]}};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.from_nxy;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.planarRotation "Inline before index reduction" "Return orientation object of a planar rotation"
//   input Real[3] e(unit = "1") "Normalized axis of rotation (must have length=1)";
//   input Real angle(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angle to rotate frame 1 into frame 2 along axis e";
//   output Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   T := {{e[1] ^ 2.0 + (1.0 - e[1] ^ 2.0) * cos(angle), (e[1] - e[1] * cos(angle)) * e[2] + e[3] * sin(angle), (e[1] - e[1] * cos(angle)) * e[3] - e[2] * sin(angle)}, {(e[2] - e[2] * cos(angle)) * e[1] - e[3] * sin(angle), e[2] ^ 2.0 + (1.0 - e[2] ^ 2.0) * cos(angle), (e[2] - e[2] * cos(angle)) * e[3] + e[1] * sin(angle)}, {(e[3] - e[3] * cos(angle)) * e[1] + e[2] * sin(angle), (e[3] - e[3] * cos(angle)) * e[2] - e[1] * sin(angle), e[3] ^ 2.0 + (1.0 - e[3] ^ 2.0) * cos(angle)}};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.planarRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1 "Inline before index reduction" "Transform vector from frame 2 to frame 1"
//   input Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v2 "Vector in frame 2";
//   output Real[3] v1 "Vector in frame 1";
// algorithm
//   v1 := {T[1,1] * v2[1] + T[2,1] * v2[2] + T[3,1] * v2[3], T[1,2] * v2[1] + T[2,2] * v2[2] + T[3,2] * v2[3], T[1,3] * v2[1] + T[2,3] * v2[2] + T[3,3] * v2[3]};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2 "Inline before index reduction" "Transform vector from frame 1 to frame 2"
//   input Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v1 "Vector in frame 1";
//   output Real[3] v2 "Vector in frame 2";
// algorithm
//   v2 := {T[1,1] * v1[1] + T[1,2] * v1[2] + T[1,3] * v1[3], T[2,1] * v1[1] + T[2,2] * v1[2] + T[2,3] * v1[3], T[3,1] * v1[1] + T[3,2] * v1[2] + T[3,3] * v1[3]};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2;
//
// function Modelica.Mechanics.MultiBody.Frames.absoluteRotation "Inline before index reduction" "Return absolute orientation object from another absolute and a relative orientation object"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R1 "Orientation object to rotate frame 0 into frame 1";
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R_rel "Orientation object to rotate frame 1 into frame 2";
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R2 "Orientation object to rotate frame 0 into frame 2";
// algorithm
//   R2 := Modelica.Mechanics.MultiBody.Frames.Orientation({{R_rel.T[1,1] * R1.T[1,1] + R_rel.T[1,2] * R1.T[2,1] + R_rel.T[1,3] * R1.T[3,1], R_rel.T[1,1] * R1.T[1,2] + R_rel.T[1,2] * R1.T[2,2] + R_rel.T[1,3] * R1.T[3,2], R_rel.T[1,1] * R1.T[1,3] + R_rel.T[1,2] * R1.T[2,3] + R_rel.T[1,3] * R1.T[3,3]}, {R_rel.T[2,1] * R1.T[1,1] + R_rel.T[2,2] * R1.T[2,1] + R_rel.T[2,3] * R1.T[3,1], R_rel.T[2,1] * R1.T[1,2] + R_rel.T[2,2] * R1.T[2,2] + R_rel.T[2,3] * R1.T[3,2], R_rel.T[2,1] * R1.T[1,3] + R_rel.T[2,2] * R1.T[2,3] + R_rel.T[2,3] * R1.T[3,3]}, {R_rel.T[3,1] * R1.T[1,1] + R_rel.T[3,2] * R1.T[2,1] + R_rel.T[3,3] * R1.T[3,1], R_rel.T[3,1] * R1.T[1,2] + R_rel.T[3,2] * R1.T[2,2] + R_rel.T[3,3] * R1.T[3,2], R_rel.T[3,1] * R1.T[1,3] + R_rel.T[3,2] * R1.T[2,3] + R_rel.T[3,3] * R1.T[3,3]}}, Modelica.Mechanics.MultiBody.Frames.resolve2(R_rel, {R1.w[1], R1.w[2], R1.w[3]}) + {R_rel.w[1], R_rel.w[2], R_rel.w[3]});
// end Modelica.Mechanics.MultiBody.Frames.absoluteRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.angularVelocity2 "Inline before index reduction" "Return angular velocity resolved in frame 2 from orientation object"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   output Real[3] w(quantity = "AngularVelocity", unit = "rad/s") "Angular velocity of frame 2 with respect to frame 1 resolved in frame 2";
// algorithm
//   w := {R.w[1], R.w[2], R.w[3]};
// end Modelica.Mechanics.MultiBody.Frames.angularVelocity2;
//
// function Modelica.Mechanics.MultiBody.Frames.axesRotations "Inline before index reduction" "Return fixed rotation object to rotate in sequence around fixed angles along 3 axes"
//   input Integer[3] sequence = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
//   input Real[3] angles(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angles around the axes defined in 'sequence'";
//   input Real[3] der_angles(quantity = "AngularVelocity", unit = "rad/s") "= der(angles)";
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   R := Modelica.Mechanics.MultiBody.Frames.Orientation(Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[3], angles[3]) * Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[2], angles[2]) * Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[1], angles[1]), Modelica.Mechanics.MultiBody.Frames.axis(sequence[3]) * der_angles[3] + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2(Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[3], angles[3]), Modelica.Mechanics.MultiBody.Frames.axis(sequence[2]) * der_angles[2]) + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2(Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[3], angles[3]) * Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[2], angles[2]), Modelica.Mechanics.MultiBody.Frames.axis(sequence[1]) * der_angles[1]));
// end Modelica.Mechanics.MultiBody.Frames.axesRotations;
//
// function Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles "Return the 3 angles to rotate in sequence around 3 axes to construct the given orientation object"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Integer[3] sequence = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
//   input Real guessAngle1(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Select angles[1] such that |angles[1] - guessAngle1| is a minimum";
//   output Real[3] angles(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angles around the axes defined in 'sequence' such that R=Frames.axesRotation(sequence,angles); -pi < angles[i] <= pi";
//   protected Real[3] e1_1(unit = "1") "First rotation axis, resolved in frame 1";
//   protected Real[3] e2_1a(unit = "1") "Second rotation axis, resolved in frame 1a";
//   protected Real[3] e3_1(unit = "1") "Third rotation axis, resolved in frame 1";
//   protected Real[3] e3_2(unit = "1") "Third rotation axis, resolved in frame 2";
//   protected Real A "Coefficient A in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
//   protected Real B "Coefficient B in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
//   protected Real angle_1a(quantity = "Angle", unit = "rad", displayUnit = "deg") "Solution 1 for angles[1]";
//   protected Real angle_1b(quantity = "Angle", unit = "rad", displayUnit = "deg") "Solution 2 for angles[1]";
//   protected Real[3, 3] T_1a "Orientation object to rotate frame 1 into frame 1a";
// algorithm
//   assert(sequence[1] <> sequence[2] and sequence[2] <> sequence[3], "input argument 'sequence[1:3]' is not valid");
//   e1_1 := if sequence[1] == 1 then {1.0, 0.0, 0.0} else if sequence[1] == 2 then {0.0, 1.0, 0.0} else {0.0, 0.0, 1.0};
//   e2_1a := if sequence[2] == 1 then {1.0, 0.0, 0.0} else if sequence[2] == 2 then {0.0, 1.0, 0.0} else {0.0, 0.0, 1.0};
//   e3_1 := {R.T[sequence[3],1], R.T[sequence[3],2], R.T[sequence[3],3]};
//   e3_2 := if sequence[3] == 1 then {1.0, 0.0, 0.0} else if sequence[3] == 2 then {0.0, 1.0, 0.0} else {0.0, 0.0, 1.0};
//   A := e2_1a[1] * e3_1[1] + e2_1a[2] * e3_1[2] + e2_1a[3] * e3_1[3];
//   B := (e1_1[2] * e2_1a[3] - e1_1[3] * e2_1a[2]) * e3_1[1] + (e1_1[3] * e2_1a[1] - e1_1[1] * e2_1a[3]) * e3_1[2] + (e1_1[1] * e2_1a[2] - e1_1[2] * e2_1a[1]) * e3_1[3];
//   if abs(A) <= 1e-12 and abs(B) <= 1e-12 then
//     angles[1] := guessAngle1;
//   else
//     angle_1a := atan2(A, -B);
//     angle_1b := atan2(-A, B);
//     angles[1] := if abs(angle_1a - guessAngle1) <= abs(angle_1b - guessAngle1) then angle_1a else angle_1b;
//   end if;
//   T_1a := Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.planarRotation({e1_1[1], e1_1[2], e1_1[3]}, angles[1]);
//   angles[2] := Modelica.Mechanics.MultiBody.Frames.planarRotationAngle({e2_1a[1], e2_1a[2], e2_1a[3]}, Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2({{T_1a[1,1], T_1a[1,2], T_1a[1,3]}, {T_1a[2,1], T_1a[2,2], T_1a[2,3]}, {T_1a[3,1], T_1a[3,2], T_1a[3,3]}}, {e3_1[1], e3_1[2], e3_1[3]}), {e3_2[1], e3_2[2], e3_2[3]});
//   angles[3] := Modelica.Mechanics.MultiBody.Frames.planarRotationAngle({e3_2[1], e3_2[2], e3_2[3]}, {e2_1a[1], e2_1a[2], e2_1a[3]}, Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2({{R.T[1,1], R.T[1,2], R.T[1,3]}, {R.T[2,1], R.T[2,2], R.T[2,3]}, {R.T[3,1], R.T[3,2], R.T[3,3]}}, Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{T_1a[1,1], T_1a[1,2], T_1a[1,3]}, {T_1a[2,1], T_1a[2,2], T_1a[2,3]}, {T_1a[3,1], T_1a[3,2], T_1a[3,3]}}, {e2_1a[1], e2_1a[2], e2_1a[3]})));
// end Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles;
//
// function Modelica.Mechanics.MultiBody.Frames.axis "Inline before index reduction" "Return unit vector for x-, y-, or z-axis"
//   input Integer axis(min = 1, max = 3) "Axis vector to be returned";
//   output Real[3] e(unit = "1") "Unit axis vector";
// algorithm
//   e := if axis == 1 then {1.0, 0.0, 0.0} else if axis == 2 then {0.0, 1.0, 0.0} else {0.0, 0.0, 1.0};
// end Modelica.Mechanics.MultiBody.Frames.axis;
//
// function Modelica.Mechanics.MultiBody.Frames.from_Q "Inline before index reduction" "Return orientation object R from quaternion orientation object Q"
//   input Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
//   input Real[3] w(quantity = "AngularVelocity", unit = "rad/s") "Angular velocity from frame 2 with respect to frame 1, resolved in frame 2";
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   R := Modelica.Mechanics.MultiBody.Frames.Orientation({{-1.0 + 2.0 * (Q[1] ^ 2.0 + Q[4] ^ 2.0), 2.0 * (Q[1] * Q[2] + Q[3] * Q[4]), 2.0 * (Q[1] * Q[3] - Q[2] * Q[4])}, {2.0 * (Q[2] * Q[1] - Q[3] * Q[4]), -1.0 + 2.0 * (Q[2] ^ 2.0 + Q[4] ^ 2.0), 2.0 * (Q[2] * Q[3] + Q[1] * Q[4])}, {2.0 * (Q[3] * Q[1] + Q[2] * Q[4]), 2.0 * (Q[3] * Q[2] - Q[1] * Q[4]), -1.0 + 2.0 * (Q[3] ^ 2.0 + Q[4] ^ 2.0)}}, {w[1], w[2], w[3]});
// end Modelica.Mechanics.MultiBody.Frames.from_Q;
//
// function Modelica.Mechanics.MultiBody.Frames.from_nxy "Return fixed orientation object from n_x and n_y vectors"
//   input Real[3] n_x(unit = "1") "Vector in direction of x-axis of frame 2, resolved in frame 1";
//   input Real[3] n_y(unit = "1") "Vector in direction of y-axis of frame 2, resolved in frame 1";
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   protected Real abs_n_x = sqrt(n_x[1] ^ 2.0 + n_x[2] ^ 2.0 + n_x[3] ^ 2.0);
//   protected Real[3] e_x(unit = "1") = if abs_n_x < 1e-10 then {1.0, 0.0, 0.0} else {n_x[1] / abs_n_x, n_x[2] / abs_n_x, n_x[3] / abs_n_x};
//   protected Real[3] n_z_aux(unit = "1") = {e_x[2] * n_y[3] - e_x[3] * n_y[2], e_x[3] * n_y[1] - e_x[1] * n_y[3], e_x[1] * n_y[2] - e_x[2] * n_y[1]};
//   protected Real[3] n_y_aux(unit = "1") = if n_z_aux[1] ^ 2.0 + n_z_aux[2] ^ 2.0 + n_z_aux[3] ^ 2.0 > 1e-06 then {n_y[1], n_y[2], n_y[3]} else if abs(e_x[1]) > 1e-06 then {0.0, 1.0, 0.0} else {1.0, 0.0, 0.0};
//   protected Real[3] e_z_aux(unit = "1") = {e_x[2] * n_y_aux[3] - e_x[3] * n_y_aux[2], e_x[3] * n_y_aux[1] - e_x[1] * n_y_aux[3], e_x[1] * n_y_aux[2] - e_x[2] * n_y_aux[1]};
//   protected Real[3] e_z(unit = "1") = {e_z_aux[1] / sqrt(e_z_aux[1] ^ 2.0 + e_z_aux[2] ^ 2.0 + e_z_aux[3] ^ 2.0), e_z_aux[2] / sqrt(e_z_aux[1] ^ 2.0 + e_z_aux[2] ^ 2.0 + e_z_aux[3] ^ 2.0), e_z_aux[3] / sqrt(e_z_aux[1] ^ 2.0 + e_z_aux[2] ^ 2.0 + e_z_aux[3] ^ 2.0)};
// algorithm
//   R := Modelica.Mechanics.MultiBody.Frames.Orientation({{e_x[1], e_x[2], e_x[3]}, {e_z[2] * e_x[3] - e_z[3] * e_x[2], e_z[3] * e_x[1] - e_z[1] * e_x[3], e_z[1] * e_x[2] - e_z[2] * e_x[1]}, {e_z[1], e_z[2], e_z[3]}}, {0.0, 0.0, 0.0});
// end Modelica.Mechanics.MultiBody.Frames.from_nxy;
//
// function Modelica.Mechanics.MultiBody.Frames.nullRotation "Inline before index reduction" "Return orientation object that does not rotate a frame"
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object such that frame 1 and frame 2 are identical";
// algorithm
//   R := Modelica.Mechanics.MultiBody.Frames.Orientation({{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}}, {0.0, 0.0, 0.0});
// end Modelica.Mechanics.MultiBody.Frames.nullRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.planarRotation "Inline before index reduction" "Return orientation object of a planar rotation"
//   input Real[3] e(unit = "1") "Normalized axis of rotation (must have length=1)";
//   input Real angle(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angle to rotate frame 1 into frame 2 along axis e";
//   input Real der_angle(quantity = "AngularVelocity", unit = "rad/s") "= der(angle)";
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   R := Modelica.Mechanics.MultiBody.Frames.Orientation({{e[1] ^ 2.0 + (1.0 - e[1] ^ 2.0) * cos(angle), (e[1] - e[1] * cos(angle)) * e[2] + e[3] * sin(angle), (e[1] - e[1] * cos(angle)) * e[3] - e[2] * sin(angle)}, {(e[2] - e[2] * cos(angle)) * e[1] - e[3] * sin(angle), e[2] ^ 2.0 + (1.0 - e[2] ^ 2.0) * cos(angle), (e[2] - e[2] * cos(angle)) * e[3] + e[1] * sin(angle)}, {(e[3] - e[3] * cos(angle)) * e[1] + e[2] * sin(angle), (e[3] - e[3] * cos(angle)) * e[2] - e[1] * sin(angle), e[3] ^ 2.0 + (1.0 - e[3] ^ 2.0) * cos(angle)}}, {e[1] * der_angle, e[2] * der_angle, e[3] * der_angle});
// end Modelica.Mechanics.MultiBody.Frames.planarRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.planarRotationAngle "Inline before index reduction" "Return angle of a planar rotation, given the rotation axis and the representations of a vector in frame 1 and frame 2"
//   input Real[3] e(unit = "1") "Normalized axis of rotation to rotate frame 1 around e into frame 2 (must have length=1)";
//   input Real[3] v1 "A vector v resolved in frame 1 (shall not be parallel to e)";
//   input Real[3] v2 "Vector v resolved in frame 2, i.e., v2 = resolve2(planarRotation(e,angle),v1)";
//   output Real angle(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angle to rotate frame 1 into frame 2 along axis e in the range: -pi <= angle <= pi";
// algorithm
//   angle := atan2((e[1] * v1[3] - e[3] * v1[1]) * v2[2] - (e[1] * v1[2] - e[2] * v1[1]) * v2[3] - (e[2] * v1[3] - e[3] * v1[2]) * v2[1], v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3] + ((-e[2]) * v2[2] - e[3] * v2[3] - e[1] * v2[1]) * (e[1] * v1[1] + e[2] * v1[2] + e[3] * v1[3]));
// end Modelica.Mechanics.MultiBody.Frames.planarRotationAngle;
//
// function Modelica.Mechanics.MultiBody.Frames.resolve1 "Inline after index reduction" "Transform vector from frame 2 to frame 1"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v2 "Vector in frame 2";
//   output Real[3] v1 "Vector in frame 1";
// algorithm
//   v1 := {R.T[1,1] * v2[1] + R.T[2,1] * v2[2] + R.T[3,1] * v2[3], R.T[1,2] * v2[1] + R.T[2,2] * v2[2] + R.T[3,2] * v2[3], R.T[1,3] * v2[1] + R.T[2,3] * v2[2] + R.T[3,3] * v2[3]};
// end Modelica.Mechanics.MultiBody.Frames.resolve1;
//
// function Modelica.Mechanics.MultiBody.Frames.resolve2 "Inline after index reduction" "Transform vector from frame 1 to frame 2"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v1 "Vector in frame 1";
//   output Real[3] v2 "Vector in frame 2";
// algorithm
//   v2 := {R.T[1,1] * v1[1] + R.T[1,2] * v1[2] + R.T[1,3] * v1[3], R.T[2,1] * v1[1] + R.T[2,2] * v1[2] + R.T[2,3] * v1[3], R.T[3,1] * v1[1] + R.T[3,2] * v1[2] + R.T[3,3] * v1[3]};
// end Modelica.Mechanics.MultiBody.Frames.resolve2;
//
// function Modelica.Mechanics.MultiBody.Frames.resolveDyade1 "Inline before index reduction" "Transform second order tensor from frame 2 to frame 1"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3, 3] D2 "Second order tensor resolved in frame 2";
//   output Real[3, 3] D1 "Second order tensor resolved in frame 1";
// algorithm
//   D1 := {{(R.T[1,1] * D2[1,1] + R.T[2,1] * D2[2,1] + R.T[3,1] * D2[3,1]) * R.T[1,1] + (R.T[1,1] * D2[1,2] + R.T[2,1] * D2[2,2] + R.T[3,1] * D2[3,2]) * R.T[2,1] + (R.T[1,1] * D2[1,3] + R.T[2,1] * D2[2,3] + R.T[3,1] * D2[3,3]) * R.T[3,1], (R.T[1,1] * D2[1,1] + R.T[2,1] * D2[2,1] + R.T[3,1] * D2[3,1]) * R.T[1,2] + (R.T[1,1] * D2[1,2] + R.T[2,1] * D2[2,2] + R.T[3,1] * D2[3,2]) * R.T[2,2] + (R.T[1,1] * D2[1,3] + R.T[2,1] * D2[2,3] + R.T[3,1] * D2[3,3]) * R.T[3,2], (R.T[1,1] * D2[1,1] + R.T[2,1] * D2[2,1] + R.T[3,1] * D2[3,1]) * R.T[1,3] + (R.T[1,1] * D2[1,2] + R.T[2,1] * D2[2,2] + R.T[3,1] * D2[3,2]) * R.T[2,3] + (R.T[1,1] * D2[1,3] + R.T[2,1] * D2[2,3] + R.T[3,1] * D2[3,3]) * R.T[3,3]}, {(R.T[1,2] * D2[1,1] + R.T[2,2] * D2[2,1] + R.T[3,2] * D2[3,1]) * R.T[1,1] + (R.T[1,2] * D2[1,2] + R.T[2,2] * D2[2,2] + R.T[3,2] * D2[3,2]) * R.T[2,1] + (R.T[1,2] * D2[1,3] + R.T[2,2] * D2[2,3] + R.T[3,2] * D2[3,3]) * R.T[3,1], (R.T[1,2] * D2[1,1] + R.T[2,2] * D2[2,1] + R.T[3,2] * D2[3,1]) * R.T[1,2] + (R.T[1,2] * D2[1,2] + R.T[2,2] * D2[2,2] + R.T[3,2] * D2[3,2]) * R.T[2,2] + (R.T[1,2] * D2[1,3] + R.T[2,2] * D2[2,3] + R.T[3,2] * D2[3,3]) * R.T[3,2], (R.T[1,2] * D2[1,1] + R.T[2,2] * D2[2,1] + R.T[3,2] * D2[3,1]) * R.T[1,3] + (R.T[1,2] * D2[1,2] + R.T[2,2] * D2[2,2] + R.T[3,2] * D2[3,2]) * R.T[2,3] + (R.T[1,2] * D2[1,3] + R.T[2,2] * D2[2,3] + R.T[3,2] * D2[3,3]) * R.T[3,3]}, {(R.T[1,3] * D2[1,1] + R.T[2,3] * D2[2,1] + R.T[3,3] * D2[3,1]) * R.T[1,1] + (R.T[1,3] * D2[1,2] + R.T[2,3] * D2[2,2] + R.T[3,3] * D2[3,2]) * R.T[2,1] + (R.T[1,3] * D2[1,3] + R.T[2,3] * D2[2,3] + R.T[3,3] * D2[3,3]) * R.T[3,1], (R.T[1,3] * D2[1,1] + R.T[2,3] * D2[2,1] + R.T[3,3] * D2[3,1]) * R.T[1,2] + (R.T[1,3] * D2[1,2] + R.T[2,3] * D2[2,2] + R.T[3,3] * D2[3,2]) * R.T[2,2] + (R.T[1,3] * D2[1,3] + R.T[2,3] * D2[2,3] + R.T[3,3] * D2[3,3]) * R.T[3,2], (R.T[1,3] * D2[1,1] + R.T[2,3] * D2[2,1] + R.T[3,3] * D2[3,1]) * R.T[1,3] + (R.T[1,3] * D2[1,2] + R.T[2,3] * D2[2,2] + R.T[3,3] * D2[3,2]) * R.T[2,3] + (R.T[1,3] * D2[1,3] + R.T[2,3] * D2[2,3] + R.T[3,3] * D2[3,3]) * R.T[3,3]}};
// end Modelica.Mechanics.MultiBody.Frames.resolveDyade1;
//
// function Modelica.Mechanics.MultiBody.Frames.to_Q "Inline before index reduction" "Return quaternion orientation object Q from orientation object R"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[4] Q_guess = {0.0, 0.0, 0.0, 1.0} "Guess value for output Q (there are 2 solutions; the one closer to Q_guess is used";
//   output Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
// algorithm
//   Q := Modelica.Mechanics.MultiBody.Frames.Quaternions.from_T({{R.T[1,1], R.T[1,2], R.T[1,3]}, {R.T[2,1], R.T[2,2], R.T[2,3]}, {R.T[3,1], R.T[3,2], R.T[3,3]}}, {Q_guess[1], Q_guess[2], Q_guess[3], Q_guess[4]});
// end Modelica.Mechanics.MultiBody.Frames.to_Q;
//
// function Modelica.Mechanics.MultiBody.World.gravityAcceleration "Inline before index reduction" "Gravity field acceleration depending on field type and position"
//   input Real[3] r(quantity = "Length", unit = "m") "Position vector from world frame to actual point, resolved in world frame";
//   input enumeration(NoGravity, UniformGravity, PointGravity) gravityType = gravityType "Type of gravity field";
//   input Real[3] g(quantity = "Acceleration", unit = "m/s2") = {0.0, -g, 0.0} "Constant gravity acceleration, resolved in world frame, if gravityType=1";
//   input Real mue(unit = "m3/s2") = mue "Field constant of point gravity field, if gravityType=2";
//   output Real[3] gravity(quantity = "Acceleration", unit = "m/s2") "Gravity acceleration at point r, resolved in world frame";
// algorithm
//   gravity := if gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity then {g[1], g[2], g[3]} else if gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.PointGravity then {(-r[1]) * mue / (r[1] ^ 2.0 + r[2] ^ 2.0 + r[3] ^ 2.0) / Modelica.Math.Vectors.length({r[1], r[2], r[3]}), (-r[2]) * mue / (r[1] ^ 2.0 + r[2] ^ 2.0 + r[3] ^ 2.0) / Modelica.Math.Vectors.length({r[1], r[2], r[3]}), (-r[3]) * mue / (r[1] ^ 2.0 + r[2] ^ 2.0 + r[3] ^ 2.0) / Modelica.Math.Vectors.length({r[1], r[2], r[3]})} else {0.0, 0.0, 0.0};
// end Modelica.Mechanics.MultiBody.World.gravityAcceleration;
//
// function Modelica.SIunits.Conversions.to_unit1 "Inline before index reduction" "Change the unit of a Real number to unit=\"1\""
//   input Real r "Real number";
//   output Real result(unit = "1") "Real number r with unit=\"1\"";
// algorithm
//   result := r;
// end Modelica.SIunits.Conversions.to_unit1;
//
// class InnerOuterSamePrefix
//   Real pendulum.world.frame_b.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.world.frame_b.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.world.frame_b.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.world.frame_b.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.world.frame_b.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.world.frame_b.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.world.frame_b.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.world.frame_b.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.world.frame_b.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.world.frame_b.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.world.frame_b.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.world.frame_b.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.world.frame_b.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   parameter Boolean pendulum.world.enableAnimation = true "= true, if animation of all components is enabled";
//   parameter Boolean pendulum.world.animateWorld = true "= true, if world coordinate system shall be visualized";
//   parameter Boolean pendulum.world.animateGravity = true "= true, if gravity field shall be visualized (acceleration vector or field center)";
//   parameter String pendulum.world.label1 = "x" "Label of horizontal axis in icon";
//   parameter String pendulum.world.label2 = "y" "Label of vertical axis in icon";
//   parameter enumeration(NoGravity, UniformGravity, PointGravity) pendulum.world.gravityType = Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity "Type of gravity field";
//   parameter Real pendulum.world.g(quantity = "Acceleration", unit = "m/s2") = 9.81 "Constant gravity acceleration";
//   parameter Real pendulum.world.n[1](unit = "1") = 0.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real pendulum.world.n[2](unit = "1") = -1.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real pendulum.world.n[3](unit = "1") = 0.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real pendulum.world.mue(unit = "m3/s2", min = 0.0) = 398600000000000.0 "Gravity field constant (default = field constant of earth)";
//   parameter Boolean pendulum.world.driveTrainMechanics3D = true "= true, if 3-dim. mechanical effects of Parts.Mounting1D/Rotor1D/BevelGear1D shall be taken into account";
//   parameter Real pendulum.world.axisLength(quantity = "Length", unit = "m", min = 0.0) = 0.5 * pendulum.world.nominalLength "Length of world axes arrows";
//   parameter Real pendulum.world.axisDiameter(quantity = "Length", unit = "m", min = 0.0) = pendulum.world.axisLength / pendulum.world.defaultFrameDiameterFraction "Diameter of world axes arrows";
//   parameter Boolean pendulum.world.axisShowLabels = true "= true, if labels shall be shown";
//   Integer pendulum.world.axisColor_x[1](min = 0, max = 255) "Color of x-arrow";
//   Integer pendulum.world.axisColor_x[2](min = 0, max = 255) "Color of x-arrow";
//   Integer pendulum.world.axisColor_x[3](min = 0, max = 255) "Color of x-arrow";
//   Integer pendulum.world.axisColor_y[1](min = 0, max = 255);
//   Integer pendulum.world.axisColor_y[2](min = 0, max = 255);
//   Integer pendulum.world.axisColor_y[3](min = 0, max = 255);
//   Integer pendulum.world.axisColor_z[1](min = 0, max = 255) "Color of z-arrow";
//   Integer pendulum.world.axisColor_z[2](min = 0, max = 255) "Color of z-arrow";
//   Integer pendulum.world.axisColor_z[3](min = 0, max = 255) "Color of z-arrow";
//   parameter Real pendulum.world.gravityArrowTail[1](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   parameter Real pendulum.world.gravityArrowTail[2](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   parameter Real pendulum.world.gravityArrowTail[3](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   parameter Real pendulum.world.gravityArrowLength(quantity = "Length", unit = "m") = 0.5 * pendulum.world.axisLength "Length of gravity arrow";
//   parameter Real pendulum.world.gravityArrowDiameter(quantity = "Length", unit = "m", min = 0.0) = pendulum.world.gravityArrowLength / pendulum.world.defaultWidthFraction "Diameter of gravity arrow";
//   Integer pendulum.world.gravityArrowColor[1](min = 0, max = 255) "Color of gravity arrow";
//   Integer pendulum.world.gravityArrowColor[2](min = 0, max = 255) "Color of gravity arrow";
//   Integer pendulum.world.gravityArrowColor[3](min = 0, max = 255) "Color of gravity arrow";
//   parameter Real pendulum.world.gravitySphereDiameter(quantity = "Length", unit = "m", min = 0.0) = 12742000.0 "Diameter of sphere representing gravity center (default = mean diameter of earth)";
//   Integer pendulum.world.gravitySphereColor[1](min = 0, max = 255) "Color of gravity sphere";
//   Integer pendulum.world.gravitySphereColor[2](min = 0, max = 255) "Color of gravity sphere";
//   Integer pendulum.world.gravitySphereColor[3](min = 0, max = 255) "Color of gravity sphere";
//   parameter Real pendulum.world.nominalLength(quantity = "Length", unit = "m") = 1.0 "\"Nominal\" length of multi-body system";
//   parameter Real pendulum.world.defaultAxisLength(quantity = "Length", unit = "m") = 0.2 * pendulum.world.nominalLength "Default for length of a frame axis (but not world frame)";
//   parameter Real pendulum.world.defaultJointLength(quantity = "Length", unit = "m") = 0.1 * pendulum.world.nominalLength "Default for the fixed length of a shape representing a joint";
//   parameter Real pendulum.world.defaultJointWidth(quantity = "Length", unit = "m") = 0.05 * pendulum.world.nominalLength "Default for the fixed width of a shape representing a joint";
//   parameter Real pendulum.world.defaultForceLength(quantity = "Length", unit = "m") = 0.1 * pendulum.world.nominalLength "Default for the fixed length of a shape representing a force (e.g., damper)";
//   parameter Real pendulum.world.defaultForceWidth(quantity = "Length", unit = "m") = 0.05 * pendulum.world.nominalLength "Default for the fixed width of a shape representing a force (e.g., spring, bushing)";
//   parameter Real pendulum.world.defaultBodyDiameter(quantity = "Length", unit = "m") = 0.1111111111111111 * pendulum.world.nominalLength "Default for diameter of sphere representing the center of mass of a body";
//   parameter Real pendulum.world.defaultWidthFraction = 20.0 "Default for shape width as a fraction of shape length (e.g., for Parts.FixedTranslation)";
//   parameter Real pendulum.world.defaultArrowDiameter(quantity = "Length", unit = "m") = 0.025 * pendulum.world.nominalLength "Default for arrow diameter (e.g., of forces, torques, sensors)";
//   parameter Real pendulum.world.defaultFrameDiameterFraction = 40.0 "Default for arrow diameter of a coordinate system as a fraction of axis length";
//   parameter Real pendulum.world.defaultSpecularCoefficient(min = 0.0) = 0.7 "Default reflection of ambient light (= 0: light is completely absorbed)";
//   parameter Real pendulum.world.defaultN_to_m(unit = "N/m", min = 0.0) = 1000.0 "Default scaling of force arrows (length = force/defaultN_to_m)";
//   parameter Real pendulum.world.defaultNm_to_m(unit = "N.m/m", min = 0.0) = 1000.0 "Default scaling of torque arrows (length = torque/defaultNm_to_m)";
//   protected parameter Integer pendulum.world.ndim = if pendulum.world.enableAnimation and pendulum.world.animateWorld then 1 else 0;
//   protected parameter Integer pendulum.world.ndim2 = if pendulum.world.enableAnimation and pendulum.world.animateWorld and pendulum.world.axisShowLabels then 1 else 0;
//   protected parameter Real pendulum.world.headLength(quantity = "Length", unit = "m") = min(pendulum.world.axisLength, 5.0 * pendulum.world.axisDiameter);
//   protected parameter Real pendulum.world.headWidth(quantity = "Length", unit = "m") = 3.0 * pendulum.world.axisDiameter;
//   protected parameter Real pendulum.world.lineLength(quantity = "Length", unit = "m") = max(0.0, pendulum.world.axisLength - pendulum.world.headLength);
//   protected parameter Real pendulum.world.lineWidth(quantity = "Length", unit = "m") = pendulum.world.axisDiameter;
//   protected parameter Real pendulum.world.scaledLabel(quantity = "Length", unit = "m") = 3.0 * pendulum.world.axisDiameter;
//   protected parameter Real pendulum.world.labelStart(quantity = "Length", unit = "m") = 1.05 * pendulum.world.axisLength;
//   protected parameter Real pendulum.world.gravityHeadLength(quantity = "Length", unit = "m") = min(pendulum.world.gravityArrowLength, 4.0 * pendulum.world.gravityArrowDiameter);
//   protected parameter Real pendulum.world.gravityHeadWidth(quantity = "Length", unit = "m") = 3.0 * pendulum.world.gravityArrowDiameter;
//   protected parameter Real pendulum.world.gravityLineLength(quantity = "Length", unit = "m") = max(0.0, pendulum.world.gravityArrowLength - pendulum.world.gravityHeadLength);
//   protected parameter Integer pendulum.world.ndim_pointGravity = if pendulum.world.enableAnimation and pendulum.world.animateGravity and pendulum.world.gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity then 1 else 0;
//   protected parameter String pendulum.world.x_arrowLine.shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.x_arrowLine.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowLine.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_arrowLine.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_arrowLine.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_arrowLine.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_arrowLine.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_arrowLine.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_arrowLine.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowLine.length(quantity = "Length", unit = "m") = pendulum.world.lineLength "Length of visual object";
//   protected Real pendulum.world.x_arrowLine.width(quantity = "Length", unit = "m") = pendulum.world.lineWidth "Width of visual object";
//   protected Real pendulum.world.x_arrowLine.height(quantity = "Length", unit = "m") = pendulum.world.lineWidth "Height of visual object";
//   protected Real pendulum.world.x_arrowLine.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.x_arrowLine.color[1] "Color of shape";
//   protected Real pendulum.world.x_arrowLine.color[2] "Color of shape";
//   protected Real pendulum.world.x_arrowLine.color[3] "Color of shape";
//   protected Real pendulum.world.x_arrowLine.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.x_arrowHead.shapeType = "cone" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.x_arrowHead.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_arrowHead.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_arrowHead.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_arrowHead.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_arrowHead.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_arrowHead.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_arrowHead.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_arrowHead.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_arrowHead.length(quantity = "Length", unit = "m") = pendulum.world.headLength "Length of visual object";
//   protected Real pendulum.world.x_arrowHead.width(quantity = "Length", unit = "m") = pendulum.world.headWidth "Width of visual object";
//   protected Real pendulum.world.x_arrowHead.height(quantity = "Length", unit = "m") = pendulum.world.headWidth "Height of visual object";
//   protected Real pendulum.world.x_arrowHead.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.x_arrowHead.color[1] "Color of shape";
//   protected Real pendulum.world.x_arrowHead.color[2] "Color of shape";
//   protected Real pendulum.world.x_arrowHead.color[3] "Color of shape";
//   protected Real pendulum.world.x_arrowHead.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected Real pendulum.world.x_label.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.r_lines[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.r_lines[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.r_lines[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.n_x[1](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.n_x[2](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.n_x[3](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.n_y[1](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.n_y[2](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.n_y[3](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.x_label.lines[1,1,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.x_label.lines[1,1,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.x_label.lines[1,2,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.x_label.lines[1,2,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.x_label.lines[2,1,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.x_label.lines[2,1,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.x_label.lines[2,2,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.x_label.lines[2,2,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.x_label.diameter(quantity = "Length", unit = "m", min = 0.0) = pendulum.world.axisDiameter "Diameter of the cylinders defined by lines";
//   protected Integer pendulum.world.x_label.color[1](min = 0, max = 255) "Color of cylinders";
//   protected Integer pendulum.world.x_label.color[2](min = 0, max = 255) "Color of cylinders";
//   protected Integer pendulum.world.x_label.color[3](min = 0, max = 255) "Color of cylinders";
//   protected Real pendulum.world.x_label.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter Integer pendulum.world.x_label.n = 2 "Number of cylinders";
//   protected Real pendulum.world.x_label.R_rel[1,1];
//   protected Real pendulum.world.x_label.R_rel[1,2];
//   protected Real pendulum.world.x_label.R_rel[1,3];
//   protected Real pendulum.world.x_label.R_rel[2,1];
//   protected Real pendulum.world.x_label.R_rel[2,2];
//   protected Real pendulum.world.x_label.R_rel[2,3];
//   protected Real pendulum.world.x_label.R_rel[3,1];
//   protected Real pendulum.world.x_label.R_rel[3,2];
//   protected Real pendulum.world.x_label.R_rel[3,3];
//   protected Real pendulum.world.x_label.R_lines[1,1];
//   protected Real pendulum.world.x_label.R_lines[1,2];
//   protected Real pendulum.world.x_label.R_lines[1,3];
//   protected Real pendulum.world.x_label.R_lines[2,1];
//   protected Real pendulum.world.x_label.R_lines[2,2];
//   protected Real pendulum.world.x_label.R_lines[2,3];
//   protected Real pendulum.world.x_label.R_lines[3,1];
//   protected Real pendulum.world.x_label.R_lines[3,2];
//   protected Real pendulum.world.x_label.R_lines[3,3];
//   protected Real pendulum.world.x_label.r_abs[1](quantity = "Length", unit = "m");
//   protected Real pendulum.world.x_label.r_abs[2](quantity = "Length", unit = "m");
//   protected Real pendulum.world.x_label.r_abs[3](quantity = "Length", unit = "m");
//   protected parameter String pendulum.world.x_label.cylinders[1].shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[1,1] = pendulum.world.x_label.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[1,2] = pendulum.world.x_label.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[1,3] = pendulum.world.x_label.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[2,1] = pendulum.world.x_label.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[2,2] = pendulum.world.x_label.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[2,3] = pendulum.world.x_label.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[3,1] = pendulum.world.x_label.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[3,2] = pendulum.world.x_label.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.T[3,3] = pendulum.world.x_label.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.x_label.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.x_label.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.cylinders[1].R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.x_label.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.cylinders[1].r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.cylinders[1].r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.cylinders[1].r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.cylinders[1].r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[1].length(quantity = "Length", unit = "m") = Modelica.Math.Vectors.length({pendulum.world.x_label.lines[1,2,1] - pendulum.world.x_label.lines[1,1,1], pendulum.world.x_label.lines[1,2,2] - pendulum.world.x_label.lines[1,1,2]}) "Length of visual object";
//   protected Real pendulum.world.x_label.cylinders[1].width(quantity = "Length", unit = "m") = pendulum.world.x_label.diameter "Width of visual object";
//   protected Real pendulum.world.x_label.cylinders[1].height(quantity = "Length", unit = "m") = pendulum.world.x_label.diameter "Height of visual object";
//   protected Real pendulum.world.x_label.cylinders[1].extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.x_label.cylinders[1].color[1] "Color of shape";
//   protected Real pendulum.world.x_label.cylinders[1].color[2] "Color of shape";
//   protected Real pendulum.world.x_label.cylinders[1].color[3] "Color of shape";
//   protected Real pendulum.world.x_label.cylinders[1].specularCoefficient(min = 0.0) = pendulum.world.x_label.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.x_label.cylinders[2].shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[1,1] = pendulum.world.x_label.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[1,2] = pendulum.world.x_label.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[1,3] = pendulum.world.x_label.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[2,1] = pendulum.world.x_label.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[2,2] = pendulum.world.x_label.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[2,3] = pendulum.world.x_label.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[3,1] = pendulum.world.x_label.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[3,2] = pendulum.world.x_label.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.T[3,3] = pendulum.world.x_label.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.x_label.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.x_label.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.cylinders[2].R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.x_label.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.x_label.cylinders[2].r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.cylinders[2].r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.cylinders[2].r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.x_label.cylinders[2].r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.x_label.cylinders[2].length(quantity = "Length", unit = "m") = Modelica.Math.Vectors.length({pendulum.world.x_label.lines[2,2,1] - pendulum.world.x_label.lines[2,1,1], pendulum.world.x_label.lines[2,2,2] - pendulum.world.x_label.lines[2,1,2]}) "Length of visual object";
//   protected Real pendulum.world.x_label.cylinders[2].width(quantity = "Length", unit = "m") = pendulum.world.x_label.diameter "Width of visual object";
//   protected Real pendulum.world.x_label.cylinders[2].height(quantity = "Length", unit = "m") = pendulum.world.x_label.diameter "Height of visual object";
//   protected Real pendulum.world.x_label.cylinders[2].extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.x_label.cylinders[2].color[1] "Color of shape";
//   protected Real pendulum.world.x_label.cylinders[2].color[2] "Color of shape";
//   protected Real pendulum.world.x_label.cylinders[2].color[3] "Color of shape";
//   protected Real pendulum.world.x_label.cylinders[2].specularCoefficient(min = 0.0) = pendulum.world.x_label.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.y_arrowLine.shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.y_arrowLine.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowLine.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_arrowLine.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_arrowLine.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_arrowLine.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_arrowLine.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_arrowLine.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_arrowLine.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowLine.length(quantity = "Length", unit = "m") = pendulum.world.lineLength "Length of visual object";
//   protected Real pendulum.world.y_arrowLine.width(quantity = "Length", unit = "m") = pendulum.world.lineWidth "Width of visual object";
//   protected Real pendulum.world.y_arrowLine.height(quantity = "Length", unit = "m") = pendulum.world.lineWidth "Height of visual object";
//   protected Real pendulum.world.y_arrowLine.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.y_arrowLine.color[1] "Color of shape";
//   protected Real pendulum.world.y_arrowLine.color[2] "Color of shape";
//   protected Real pendulum.world.y_arrowLine.color[3] "Color of shape";
//   protected Real pendulum.world.y_arrowLine.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.y_arrowHead.shapeType = "cone" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.y_arrowHead.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_arrowHead.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_arrowHead.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_arrowHead.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_arrowHead.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_arrowHead.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_arrowHead.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_arrowHead.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_arrowHead.length(quantity = "Length", unit = "m") = pendulum.world.headLength "Length of visual object";
//   protected Real pendulum.world.y_arrowHead.width(quantity = "Length", unit = "m") = pendulum.world.headWidth "Width of visual object";
//   protected Real pendulum.world.y_arrowHead.height(quantity = "Length", unit = "m") = pendulum.world.headWidth "Height of visual object";
//   protected Real pendulum.world.y_arrowHead.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.y_arrowHead.color[1] "Color of shape";
//   protected Real pendulum.world.y_arrowHead.color[2] "Color of shape";
//   protected Real pendulum.world.y_arrowHead.color[3] "Color of shape";
//   protected Real pendulum.world.y_arrowHead.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected Real pendulum.world.y_label.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.r_lines[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.r_lines[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.r_lines[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.n_x[1](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.n_x[2](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.n_x[3](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.n_y[1](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.n_y[2](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.n_y[3](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.y_label.lines[1,1,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.y_label.lines[1,1,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.y_label.lines[1,2,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.y_label.lines[1,2,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.y_label.lines[2,1,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.y_label.lines[2,1,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.y_label.lines[2,2,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.y_label.lines[2,2,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.y_label.diameter(quantity = "Length", unit = "m", min = 0.0) = pendulum.world.axisDiameter "Diameter of the cylinders defined by lines";
//   protected Integer pendulum.world.y_label.color[1](min = 0, max = 255) "Color of cylinders";
//   protected Integer pendulum.world.y_label.color[2](min = 0, max = 255) "Color of cylinders";
//   protected Integer pendulum.world.y_label.color[3](min = 0, max = 255) "Color of cylinders";
//   protected Real pendulum.world.y_label.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter Integer pendulum.world.y_label.n = 2 "Number of cylinders";
//   protected Real pendulum.world.y_label.R_rel[1,1];
//   protected Real pendulum.world.y_label.R_rel[1,2];
//   protected Real pendulum.world.y_label.R_rel[1,3];
//   protected Real pendulum.world.y_label.R_rel[2,1];
//   protected Real pendulum.world.y_label.R_rel[2,2];
//   protected Real pendulum.world.y_label.R_rel[2,3];
//   protected Real pendulum.world.y_label.R_rel[3,1];
//   protected Real pendulum.world.y_label.R_rel[3,2];
//   protected Real pendulum.world.y_label.R_rel[3,3];
//   protected Real pendulum.world.y_label.R_lines[1,1];
//   protected Real pendulum.world.y_label.R_lines[1,2];
//   protected Real pendulum.world.y_label.R_lines[1,3];
//   protected Real pendulum.world.y_label.R_lines[2,1];
//   protected Real pendulum.world.y_label.R_lines[2,2];
//   protected Real pendulum.world.y_label.R_lines[2,3];
//   protected Real pendulum.world.y_label.R_lines[3,1];
//   protected Real pendulum.world.y_label.R_lines[3,2];
//   protected Real pendulum.world.y_label.R_lines[3,3];
//   protected Real pendulum.world.y_label.r_abs[1](quantity = "Length", unit = "m");
//   protected Real pendulum.world.y_label.r_abs[2](quantity = "Length", unit = "m");
//   protected Real pendulum.world.y_label.r_abs[3](quantity = "Length", unit = "m");
//   protected parameter String pendulum.world.y_label.cylinders[1].shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[1,1] = pendulum.world.y_label.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[1,2] = pendulum.world.y_label.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[1,3] = pendulum.world.y_label.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[2,1] = pendulum.world.y_label.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[2,2] = pendulum.world.y_label.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[2,3] = pendulum.world.y_label.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[3,1] = pendulum.world.y_label.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[3,2] = pendulum.world.y_label.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.T[3,3] = pendulum.world.y_label.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.y_label.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.y_label.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.cylinders[1].R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.y_label.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.cylinders[1].r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.cylinders[1].r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.cylinders[1].r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.cylinders[1].r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[1].length(quantity = "Length", unit = "m") = Modelica.Math.Vectors.length({pendulum.world.y_label.lines[1,2,1] - pendulum.world.y_label.lines[1,1,1], pendulum.world.y_label.lines[1,2,2] - pendulum.world.y_label.lines[1,1,2]}) "Length of visual object";
//   protected Real pendulum.world.y_label.cylinders[1].width(quantity = "Length", unit = "m") = pendulum.world.y_label.diameter "Width of visual object";
//   protected Real pendulum.world.y_label.cylinders[1].height(quantity = "Length", unit = "m") = pendulum.world.y_label.diameter "Height of visual object";
//   protected Real pendulum.world.y_label.cylinders[1].extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.y_label.cylinders[1].color[1] "Color of shape";
//   protected Real pendulum.world.y_label.cylinders[1].color[2] "Color of shape";
//   protected Real pendulum.world.y_label.cylinders[1].color[3] "Color of shape";
//   protected Real pendulum.world.y_label.cylinders[1].specularCoefficient(min = 0.0) = pendulum.world.y_label.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.y_label.cylinders[2].shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[1,1] = pendulum.world.y_label.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[1,2] = pendulum.world.y_label.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[1,3] = pendulum.world.y_label.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[2,1] = pendulum.world.y_label.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[2,2] = pendulum.world.y_label.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[2,3] = pendulum.world.y_label.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[3,1] = pendulum.world.y_label.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[3,2] = pendulum.world.y_label.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.T[3,3] = pendulum.world.y_label.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.y_label.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.y_label.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.cylinders[2].R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.y_label.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.y_label.cylinders[2].r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.cylinders[2].r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.cylinders[2].r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.y_label.cylinders[2].r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.y_label.cylinders[2].length(quantity = "Length", unit = "m") = Modelica.Math.Vectors.length({pendulum.world.y_label.lines[2,2,1] - pendulum.world.y_label.lines[2,1,1], pendulum.world.y_label.lines[2,2,2] - pendulum.world.y_label.lines[2,1,2]}) "Length of visual object";
//   protected Real pendulum.world.y_label.cylinders[2].width(quantity = "Length", unit = "m") = pendulum.world.y_label.diameter "Width of visual object";
//   protected Real pendulum.world.y_label.cylinders[2].height(quantity = "Length", unit = "m") = pendulum.world.y_label.diameter "Height of visual object";
//   protected Real pendulum.world.y_label.cylinders[2].extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.y_label.cylinders[2].color[1] "Color of shape";
//   protected Real pendulum.world.y_label.cylinders[2].color[2] "Color of shape";
//   protected Real pendulum.world.y_label.cylinders[2].color[3] "Color of shape";
//   protected Real pendulum.world.y_label.cylinders[2].specularCoefficient(min = 0.0) = pendulum.world.y_label.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.z_arrowLine.shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.z_arrowLine.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowLine.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_arrowLine.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_arrowLine.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_arrowLine.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_arrowLine.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_arrowLine.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_arrowLine.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowLine.length(quantity = "Length", unit = "m") = pendulum.world.lineLength "Length of visual object";
//   protected Real pendulum.world.z_arrowLine.width(quantity = "Length", unit = "m") = pendulum.world.lineWidth "Width of visual object";
//   protected Real pendulum.world.z_arrowLine.height(quantity = "Length", unit = "m") = pendulum.world.lineWidth "Height of visual object";
//   protected Real pendulum.world.z_arrowLine.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.z_arrowLine.color[1] "Color of shape";
//   protected Real pendulum.world.z_arrowLine.color[2] "Color of shape";
//   protected Real pendulum.world.z_arrowLine.color[3] "Color of shape";
//   protected Real pendulum.world.z_arrowLine.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.z_arrowHead.shapeType = "cone" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.z_arrowHead.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_arrowHead.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_arrowHead.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_arrowHead.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_arrowHead.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_arrowHead.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_arrowHead.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_arrowHead.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_arrowHead.length(quantity = "Length", unit = "m") = pendulum.world.headLength "Length of visual object";
//   protected Real pendulum.world.z_arrowHead.width(quantity = "Length", unit = "m") = pendulum.world.headWidth "Width of visual object";
//   protected Real pendulum.world.z_arrowHead.height(quantity = "Length", unit = "m") = pendulum.world.headWidth "Height of visual object";
//   protected Real pendulum.world.z_arrowHead.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.z_arrowHead.color[1] "Color of shape";
//   protected Real pendulum.world.z_arrowHead.color[2] "Color of shape";
//   protected Real pendulum.world.z_arrowHead.color[3] "Color of shape";
//   protected Real pendulum.world.z_arrowHead.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected Real pendulum.world.z_label.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.r_lines[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.r_lines[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.r_lines[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to the origin of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.n_x[1](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.n_x[2](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.n_x[3](unit = "1") "Vector in direction of x-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.n_y[1](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.n_y[2](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.n_y[3](unit = "1") "Vector in direction of y-axis of 'lines' frame, resolved in object frame";
//   protected Real pendulum.world.z_label.lines[1,1,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[1,1,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[1,2,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[1,2,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[2,1,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[2,1,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[2,2,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[2,2,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[3,1,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[3,1,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[3,2,1](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.lines[3,2,2](quantity = "Length", unit = "m") "List of start and end points of cylinders resolved in an x-y frame defined by n_x, n_y, e.g., {[0,0;1,1], [0,1;1,0], [2,0; 3,1]}";
//   protected Real pendulum.world.z_label.diameter(quantity = "Length", unit = "m", min = 0.0) = pendulum.world.axisDiameter "Diameter of the cylinders defined by lines";
//   protected Integer pendulum.world.z_label.color[1](min = 0, max = 255) "Color of cylinders";
//   protected Integer pendulum.world.z_label.color[2](min = 0, max = 255) "Color of cylinders";
//   protected Integer pendulum.world.z_label.color[3](min = 0, max = 255) "Color of cylinders";
//   protected Real pendulum.world.z_label.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter Integer pendulum.world.z_label.n = 3 "Number of cylinders";
//   protected Real pendulum.world.z_label.R_rel[1,1];
//   protected Real pendulum.world.z_label.R_rel[1,2];
//   protected Real pendulum.world.z_label.R_rel[1,3];
//   protected Real pendulum.world.z_label.R_rel[2,1];
//   protected Real pendulum.world.z_label.R_rel[2,2];
//   protected Real pendulum.world.z_label.R_rel[2,3];
//   protected Real pendulum.world.z_label.R_rel[3,1];
//   protected Real pendulum.world.z_label.R_rel[3,2];
//   protected Real pendulum.world.z_label.R_rel[3,3];
//   protected Real pendulum.world.z_label.R_lines[1,1];
//   protected Real pendulum.world.z_label.R_lines[1,2];
//   protected Real pendulum.world.z_label.R_lines[1,3];
//   protected Real pendulum.world.z_label.R_lines[2,1];
//   protected Real pendulum.world.z_label.R_lines[2,2];
//   protected Real pendulum.world.z_label.R_lines[2,3];
//   protected Real pendulum.world.z_label.R_lines[3,1];
//   protected Real pendulum.world.z_label.R_lines[3,2];
//   protected Real pendulum.world.z_label.R_lines[3,3];
//   protected Real pendulum.world.z_label.r_abs[1](quantity = "Length", unit = "m");
//   protected Real pendulum.world.z_label.r_abs[2](quantity = "Length", unit = "m");
//   protected Real pendulum.world.z_label.r_abs[3](quantity = "Length", unit = "m");
//   protected parameter String pendulum.world.z_label.cylinders[1].shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[1,1] = pendulum.world.z_label.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[1,2] = pendulum.world.z_label.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[1,3] = pendulum.world.z_label.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[2,1] = pendulum.world.z_label.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[2,2] = pendulum.world.z_label.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[2,3] = pendulum.world.z_label.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[3,1] = pendulum.world.z_label.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[3,2] = pendulum.world.z_label.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.T[3,3] = pendulum.world.z_label.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[1].R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[1].r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[1].r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[1].r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[1].r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[1].length(quantity = "Length", unit = "m") = Modelica.Math.Vectors.length({pendulum.world.z_label.lines[1,2,1] - pendulum.world.z_label.lines[1,1,1], pendulum.world.z_label.lines[1,2,2] - pendulum.world.z_label.lines[1,1,2]}) "Length of visual object";
//   protected Real pendulum.world.z_label.cylinders[1].width(quantity = "Length", unit = "m") = pendulum.world.z_label.diameter "Width of visual object";
//   protected Real pendulum.world.z_label.cylinders[1].height(quantity = "Length", unit = "m") = pendulum.world.z_label.diameter "Height of visual object";
//   protected Real pendulum.world.z_label.cylinders[1].extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.z_label.cylinders[1].color[1] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[1].color[2] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[1].color[3] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[1].specularCoefficient(min = 0.0) = pendulum.world.z_label.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.z_label.cylinders[2].shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[1,1] = pendulum.world.z_label.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[1,2] = pendulum.world.z_label.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[1,3] = pendulum.world.z_label.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[2,1] = pendulum.world.z_label.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[2,2] = pendulum.world.z_label.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[2,3] = pendulum.world.z_label.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[3,1] = pendulum.world.z_label.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[3,2] = pendulum.world.z_label.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.T[3,3] = pendulum.world.z_label.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[2].R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[2].r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[2].r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[2].r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[2].r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[2].length(quantity = "Length", unit = "m") = Modelica.Math.Vectors.length({pendulum.world.z_label.lines[2,2,1] - pendulum.world.z_label.lines[2,1,1], pendulum.world.z_label.lines[2,2,2] - pendulum.world.z_label.lines[2,1,2]}) "Length of visual object";
//   protected Real pendulum.world.z_label.cylinders[2].width(quantity = "Length", unit = "m") = pendulum.world.z_label.diameter "Width of visual object";
//   protected Real pendulum.world.z_label.cylinders[2].height(quantity = "Length", unit = "m") = pendulum.world.z_label.diameter "Height of visual object";
//   protected Real pendulum.world.z_label.cylinders[2].extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.z_label.cylinders[2].color[1] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[2].color[2] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[2].color[3] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[2].specularCoefficient(min = 0.0) = pendulum.world.z_label.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.z_label.cylinders[3].shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[1,1] = pendulum.world.z_label.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[1,2] = pendulum.world.z_label.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[1,3] = pendulum.world.z_label.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[2,1] = pendulum.world.z_label.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[2,2] = pendulum.world.z_label.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[2,3] = pendulum.world.z_label.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[3,1] = pendulum.world.z_label.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[3,2] = pendulum.world.z_label.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.T[3,3] = pendulum.world.z_label.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[3].R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.world.z_label.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.z_label.cylinders[3].r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[3].r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[3].r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.z_label.cylinders[3].r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.z_label.cylinders[3].length(quantity = "Length", unit = "m") = Modelica.Math.Vectors.length({pendulum.world.z_label.lines[3,2,1] - pendulum.world.z_label.lines[3,1,1], pendulum.world.z_label.lines[3,2,2] - pendulum.world.z_label.lines[3,1,2]}) "Length of visual object";
//   protected Real pendulum.world.z_label.cylinders[3].width(quantity = "Length", unit = "m") = pendulum.world.z_label.diameter "Width of visual object";
//   protected Real pendulum.world.z_label.cylinders[3].height(quantity = "Length", unit = "m") = pendulum.world.z_label.diameter "Height of visual object";
//   protected Real pendulum.world.z_label.cylinders[3].extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.z_label.cylinders[3].color[1] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[3].color[2] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[3].color[3] "Color of shape";
//   protected Real pendulum.world.z_label.cylinders[3].specularCoefficient(min = 0.0) = pendulum.world.z_label.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.gravityArrowLine.shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.gravityArrowLine.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowLine.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.gravityArrowLine.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.gravityArrowLine.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.gravityArrowLine.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.gravityArrowLine.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.gravityArrowLine.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.gravityArrowLine.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowLine.length(quantity = "Length", unit = "m") = pendulum.world.gravityLineLength "Length of visual object";
//   protected Real pendulum.world.gravityArrowLine.width(quantity = "Length", unit = "m") = pendulum.world.gravityArrowDiameter "Width of visual object";
//   protected Real pendulum.world.gravityArrowLine.height(quantity = "Length", unit = "m") = pendulum.world.gravityArrowDiameter "Height of visual object";
//   protected Real pendulum.world.gravityArrowLine.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.gravityArrowLine.color[1] "Color of shape";
//   protected Real pendulum.world.gravityArrowLine.color[2] "Color of shape";
//   protected Real pendulum.world.gravityArrowLine.color[3] "Color of shape";
//   protected Real pendulum.world.gravityArrowLine.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.world.gravityArrowHead.shapeType = "cone" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.world.gravityArrowHead.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   protected Real pendulum.world.gravityArrowHead.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.gravityArrowHead.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.gravityArrowHead.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.world.gravityArrowHead.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.gravityArrowHead.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.gravityArrowHead.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.world.gravityArrowHead.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.world.gravityArrowHead.length(quantity = "Length", unit = "m") = pendulum.world.gravityHeadLength "Length of visual object";
//   protected Real pendulum.world.gravityArrowHead.width(quantity = "Length", unit = "m") = pendulum.world.gravityHeadWidth "Width of visual object";
//   protected Real pendulum.world.gravityArrowHead.height(quantity = "Length", unit = "m") = pendulum.world.gravityHeadWidth "Height of visual object";
//   protected Real pendulum.world.gravityArrowHead.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.world.gravityArrowHead.color[1] "Color of shape";
//   protected Real pendulum.world.gravityArrowHead.color[2] "Color of shape";
//   protected Real pendulum.world.gravityArrowHead.color[3] "Color of shape";
//   protected Real pendulum.world.gravityArrowHead.specularCoefficient(min = 0.0) = 0.0 "Reflection of ambient light (= 0: light is completely absorbed)";
//   Real pendulum.pendulum.frame_a.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frame_a.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frame_a.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frame_a.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_a.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frame_a.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frame_a.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frame_a.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frame_a.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frame_a.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frame_a.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frame_a.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frame_a.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frame_b.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frame_b.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frame_b.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frame_b.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frame_b.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frame_b.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frame_b.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frame_b.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frame_b.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frame_b.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frame_b.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frame_b.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frame_b.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   parameter Boolean pendulum.pendulum.animation = true "= true, if animation shall be enabled (show cylinder between frame_a and frame_b)";
//   parameter Real pendulum.pendulum.r[1](quantity = "Length", unit = "m", start = 0.1) "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.pendulum.r[2](quantity = "Length", unit = "m", start = 0.0) "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.pendulum.r[3](quantity = "Length", unit = "m", start = 0.0) "Vector from frame_a to frame_b, resolved in frame_a";
//   parameter Real pendulum.pendulum.r_shape[1](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to cylinder origin, resolved in frame_a";
//   parameter Real pendulum.pendulum.r_shape[2](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to cylinder origin, resolved in frame_a";
//   parameter Real pendulum.pendulum.r_shape[3](quantity = "Length", unit = "m") = 0.0 "Vector from frame_a to cylinder origin, resolved in frame_a";
//   parameter Real pendulum.pendulum.lengthDirection[1](unit = "1") = Modelica.SIunits.Conversions.to_unit1(pendulum.pendulum.r[1] - pendulum.pendulum.r_shape[1]) "Vector in length direction of cylinder, resolved in frame_a";
//   parameter Real pendulum.pendulum.lengthDirection[2](unit = "1") = Modelica.SIunits.Conversions.to_unit1(pendulum.pendulum.r[2] - pendulum.pendulum.r_shape[2]) "Vector in length direction of cylinder, resolved in frame_a";
//   parameter Real pendulum.pendulum.lengthDirection[3](unit = "1") = Modelica.SIunits.Conversions.to_unit1(pendulum.pendulum.r[3] - pendulum.pendulum.r_shape[3]) "Vector in length direction of cylinder, resolved in frame_a";
//   parameter Real pendulum.pendulum.length(quantity = "Length", unit = "m") = Modelica.Math.Vectors.length({pendulum.pendulum.r[1] - pendulum.pendulum.r_shape[1], pendulum.pendulum.r[2] - pendulum.pendulum.r_shape[2], pendulum.pendulum.r[3] - pendulum.pendulum.r_shape[3]}) "Length of cylinder";
//   parameter Real pendulum.pendulum.diameter(quantity = "Length", unit = "m", min = 0.0) = pendulum.pendulum.length / pendulum.world.defaultWidthFraction "Diameter of cylinder";
//   parameter Real pendulum.pendulum.innerDiameter(quantity = "Length", unit = "m", min = 0.0) = 0.0 "Inner diameter of cylinder (0 <= innerDiameter <= Diameter)";
//   parameter Real pendulum.pendulum.density(quantity = "Density", unit = "kg/m3", displayUnit = "g/cm3", min = 0.0) = 7700.0 "Density of cylinder (e.g., steel: 7700 .. 7900, wood : 400 .. 800)";
//   Integer pendulum.pendulum.color[1](min = 0, max = 255) "Color of cylinder";
//   Integer pendulum.pendulum.color[2](min = 0, max = 255) "Color of cylinder";
//   Integer pendulum.pendulum.color[3](min = 0, max = 255) "Color of cylinder";
//   Real pendulum.pendulum.specularCoefficient(min = 0.0) = pendulum.world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   Real pendulum.pendulum.r_0[1](quantity = "Length", unit = "m", start = 0.0, stateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real pendulum.pendulum.r_0[2](quantity = "Length", unit = "m", start = 0.0, stateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real pendulum.pendulum.r_0[3](quantity = "Length", unit = "m", start = 0.0, stateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real pendulum.pendulum.v_0[1](quantity = "Velocity", unit = "m/s", start = 0.0, stateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real pendulum.pendulum.v_0[2](quantity = "Velocity", unit = "m/s", start = 0.0, stateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real pendulum.pendulum.v_0[3](quantity = "Velocity", unit = "m/s", start = 0.0, stateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real pendulum.pendulum.a_0[1](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   Real pendulum.pendulum.a_0[2](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   Real pendulum.pendulum.a_0[3](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   parameter Boolean pendulum.pendulum.angles_fixed = false "= true, if angles_start are used as initial values, else as guess values";
//   parameter Real pendulum.pendulum.angles_start[1](quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Real pendulum.pendulum.angles_start[2](quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Real pendulum.pendulum.angles_start[3](quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Integer pendulum.pendulum.sequence_start[1](min = 1, max = 3) = 1 "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Integer pendulum.pendulum.sequence_start[2](min = 1, max = 3) = 2 "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Integer pendulum.pendulum.sequence_start[3](min = 1, max = 3) = 3 "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Boolean pendulum.pendulum.w_0_fixed = false "= true, if w_0_start are used as initial values, else as guess values";
//   parameter Real pendulum.pendulum.w_0_start[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Real pendulum.pendulum.w_0_start[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Real pendulum.pendulum.w_0_start[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Boolean pendulum.pendulum.z_0_fixed = false "= true, if z_0_start are used as initial values, else as guess values";
//   parameter Real pendulum.pendulum.z_0_start[1](quantity = "AngularAcceleration", unit = "rad/s2") = 0.0 "Initial values of angular acceleration z_0 = der(w_0)";
//   parameter Real pendulum.pendulum.z_0_start[2](quantity = "AngularAcceleration", unit = "rad/s2") = 0.0 "Initial values of angular acceleration z_0 = der(w_0)";
//   parameter Real pendulum.pendulum.z_0_start[3](quantity = "AngularAcceleration", unit = "rad/s2") = 0.0 "Initial values of angular acceleration z_0 = der(w_0)";
//   parameter Boolean pendulum.pendulum.enforceStates = false "= true, if absolute variables of body object shall be used as states (StateSelect.always)";
//   parameter Boolean pendulum.pendulum.useQuaternions = true "= true, if quaternions shall be used as potential states otherwise use 3 angles as potential states";
//   parameter Integer pendulum.pendulum.sequence_angleStates[1](min = 1, max = 3) = 1 "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   parameter Integer pendulum.pendulum.sequence_angleStates[2](min = 1, max = 3) = 2 "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   parameter Integer pendulum.pendulum.sequence_angleStates[3](min = 1, max = 3) = 3 "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   constant Real pendulum.pendulum.pi = 3.141592653589793;
//   final parameter Real pendulum.pendulum.radius(quantity = "Length", unit = "m", min = 0.0) = 0.5 * pendulum.pendulum.diameter "Radius of cylinder";
//   final parameter Real pendulum.pendulum.innerRadius(quantity = "Length", unit = "m", min = 0.0) = 0.5 * pendulum.pendulum.innerDiameter "Inner-Radius of cylinder";
//   final parameter Real pendulum.pendulum.mo(quantity = "Mass", unit = "kg", min = 0.0) = 3.141592653589793 * pendulum.pendulum.density * pendulum.pendulum.length * pendulum.pendulum.radius ^ 2.0 "Mass of cylinder without hole";
//   final parameter Real pendulum.pendulum.mi(quantity = "Mass", unit = "kg", min = 0.0) = 3.141592653589793 * pendulum.pendulum.density * pendulum.pendulum.length * pendulum.pendulum.innerRadius ^ 2.0 "Mass of hole of cylinder";
//   final parameter Real pendulum.pendulum.I22(quantity = "MomentOfInertia", unit = "kg.m2") = 0.08333333333333333 * (pendulum.pendulum.mo * (pendulum.pendulum.length ^ 2.0 + 3.0 * pendulum.pendulum.radius ^ 2.0) - pendulum.pendulum.mi * (pendulum.pendulum.length ^ 2.0 + 3.0 * pendulum.pendulum.innerRadius ^ 2.0)) "Inertia with respect to axis through center of mass, perpendicular to cylinder axis";
//   final parameter Real pendulum.pendulum.m(quantity = "Mass", unit = "kg", min = 0.0) = pendulum.pendulum.mo - pendulum.pendulum.mi "Mass of cylinder";
//   final parameter Real pendulum.pendulum.R.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   final parameter Real pendulum.pendulum.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   final parameter Real pendulum.pendulum.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   final parameter Real pendulum.pendulum.r_CM[1](quantity = "Length", unit = "m") = pendulum.pendulum.r_shape[1] + 0.5 * pendulum.pendulum.length "Position vector from frame_a to center of mass, resolved in frame_a";
//   final parameter Real pendulum.pendulum.r_CM[2](quantity = "Length", unit = "m") = pendulum.pendulum.r_shape[2] "Position vector from frame_a to center of mass, resolved in frame_a";
//   final parameter Real pendulum.pendulum.r_CM[3](quantity = "Length", unit = "m") = pendulum.pendulum.r_shape[3] "Position vector from frame_a to center of mass, resolved in frame_a";
//   final parameter Real pendulum.pendulum.I[1,1](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[1, 1] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   final parameter Real pendulum.pendulum.I[1,2](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[1, 2] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   final parameter Real pendulum.pendulum.I[1,3](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[1, 3] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   final parameter Real pendulum.pendulum.I[2,1](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[2, 1] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   final parameter Real pendulum.pendulum.I[2,2](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[2, 2] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   final parameter Real pendulum.pendulum.I[2,3](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[2, 3] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   final parameter Real pendulum.pendulum.I[3,1](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[3, 1] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   final parameter Real pendulum.pendulum.I[3,2](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[3, 2] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   final parameter Real pendulum.pendulum.I[3,3](quantity = "MomentOfInertia", unit = "kg.m2") = Modelica.Mechanics.MultiBody.Frames.resolveDyade1(pendulum.pendulum.R, {{4.724660826687776e-08, 0.0, 0.0}, {0.0, 1.262271884196751e-05, 0.0}, {0.0, 0.0, 1.262271884196751e-05}})[3, 3] "Inertia tensor of cylinder with respect to center of mass, resolved in frame parallel to frame_a";
//   Real pendulum.pendulum.body.frame_a.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.body.frame_a.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.body.frame_a.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.body.frame_a.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.body.frame_a.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.body.frame_a.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.body.frame_a.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.body.frame_a.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.body.frame_a.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.body.frame_a.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.body.frame_a.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.body.frame_a.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.body.frame_a.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   parameter Boolean pendulum.pendulum.body.animation = false "= true, if animation shall be enabled (show cylinder and sphere)";
//   parameter Real pendulum.pendulum.body.r_CM[1](quantity = "Length", unit = "m", start = 0.0) = pendulum.pendulum.r_CM[1] "Vector from frame_a to center of mass, resolved in frame_a";
//   parameter Real pendulum.pendulum.body.r_CM[2](quantity = "Length", unit = "m", start = 0.0) = pendulum.pendulum.r_CM[2] "Vector from frame_a to center of mass, resolved in frame_a";
//   parameter Real pendulum.pendulum.body.r_CM[3](quantity = "Length", unit = "m", start = 0.0) = pendulum.pendulum.r_CM[3] "Vector from frame_a to center of mass, resolved in frame_a";
//   parameter Real pendulum.pendulum.body.m(quantity = "Mass", unit = "kg", min = 0.0, start = 1.0) = pendulum.pendulum.m "Mass of rigid body";
//   parameter Real pendulum.pendulum.body.I_11(quantity = "MomentOfInertia", unit = "kg.m2", min = 0.0) = pendulum.pendulum.I[1,1] "(1,1) element of inertia tensor";
//   parameter Real pendulum.pendulum.body.I_22(quantity = "MomentOfInertia", unit = "kg.m2", min = 0.0) = pendulum.pendulum.I[2,2] "(2,2) element of inertia tensor";
//   parameter Real pendulum.pendulum.body.I_33(quantity = "MomentOfInertia", unit = "kg.m2", min = 0.0) = pendulum.pendulum.I[3,3] "(3,3) element of inertia tensor";
//   parameter Real pendulum.pendulum.body.I_21(quantity = "MomentOfInertia", unit = "kg.m2", min = -9.999999999999999e+59) = pendulum.pendulum.I[2,1] "(2,1) element of inertia tensor";
//   parameter Real pendulum.pendulum.body.I_31(quantity = "MomentOfInertia", unit = "kg.m2", min = -9.999999999999999e+59) = pendulum.pendulum.I[3,1] "(3,1) element of inertia tensor";
//   parameter Real pendulum.pendulum.body.I_32(quantity = "MomentOfInertia", unit = "kg.m2", min = -9.999999999999999e+59) = pendulum.pendulum.I[3,2] "(3,2) element of inertia tensor";
//   Real pendulum.pendulum.body.r_0[1](quantity = "Length", unit = "m", start = 0.0, stateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real pendulum.pendulum.body.r_0[2](quantity = "Length", unit = "m", start = 0.0, stateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real pendulum.pendulum.body.r_0[3](quantity = "Length", unit = "m", start = 0.0, stateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real pendulum.pendulum.body.v_0[1](quantity = "Velocity", unit = "m/s", start = 0.0, stateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real pendulum.pendulum.body.v_0[2](quantity = "Velocity", unit = "m/s", start = 0.0, stateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real pendulum.pendulum.body.v_0[3](quantity = "Velocity", unit = "m/s", start = 0.0, stateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real pendulum.pendulum.body.a_0[1](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   Real pendulum.pendulum.body.a_0[2](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   Real pendulum.pendulum.body.a_0[3](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   parameter Boolean pendulum.pendulum.body.angles_fixed = pendulum.pendulum.angles_fixed "= true, if angles_start are used as initial values, else as guess values";
//   parameter Real pendulum.pendulum.body.angles_start[1](quantity = "Angle", unit = "rad", displayUnit = "deg") = pendulum.pendulum.angles_start[1] "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Real pendulum.pendulum.body.angles_start[2](quantity = "Angle", unit = "rad", displayUnit = "deg") = pendulum.pendulum.angles_start[2] "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Real pendulum.pendulum.body.angles_start[3](quantity = "Angle", unit = "rad", displayUnit = "deg") = pendulum.pendulum.angles_start[3] "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Integer pendulum.pendulum.body.sequence_start[1](min = 1, max = 3) = pendulum.pendulum.sequence_start[1] "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Integer pendulum.pendulum.body.sequence_start[2](min = 1, max = 3) = pendulum.pendulum.sequence_start[2] "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Integer pendulum.pendulum.body.sequence_start[3](min = 1, max = 3) = pendulum.pendulum.sequence_start[3] "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Boolean pendulum.pendulum.body.w_0_fixed = pendulum.pendulum.w_0_fixed "= true, if w_0_start are used as initial values, else as guess values";
//   parameter Real pendulum.pendulum.body.w_0_start[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.pendulum.w_0_start[1] "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Real pendulum.pendulum.body.w_0_start[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.pendulum.w_0_start[2] "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Real pendulum.pendulum.body.w_0_start[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.pendulum.w_0_start[3] "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Boolean pendulum.pendulum.body.z_0_fixed = pendulum.pendulum.z_0_fixed "= true, if z_0_start are used as initial values, else as guess values";
//   parameter Real pendulum.pendulum.body.z_0_start[1](quantity = "AngularAcceleration", unit = "rad/s2") = pendulum.pendulum.z_0_start[1] "Initial values of angular acceleration z_0 = der(w_0)";
//   parameter Real pendulum.pendulum.body.z_0_start[2](quantity = "AngularAcceleration", unit = "rad/s2") = pendulum.pendulum.z_0_start[2] "Initial values of angular acceleration z_0 = der(w_0)";
//   parameter Real pendulum.pendulum.body.z_0_start[3](quantity = "AngularAcceleration", unit = "rad/s2") = pendulum.pendulum.z_0_start[3] "Initial values of angular acceleration z_0 = der(w_0)";
//   parameter Real pendulum.pendulum.body.sphereDiameter(quantity = "Length", unit = "m", min = 0.0) = pendulum.world.defaultBodyDiameter "Diameter of sphere";
//   Integer pendulum.pendulum.body.sphereColor[1](min = 0, max = 255) "Color of sphere";
//   Integer pendulum.pendulum.body.sphereColor[2](min = 0, max = 255) "Color of sphere";
//   Integer pendulum.pendulum.body.sphereColor[3](min = 0, max = 255) "Color of sphere";
//   parameter Real pendulum.pendulum.body.cylinderDiameter(quantity = "Length", unit = "m", min = 0.0) = 0.3333333333333333 * pendulum.pendulum.body.sphereDiameter "Diameter of cylinder";
//   Integer pendulum.pendulum.body.cylinderColor[1](min = 0, max = 255) "Color of cylinder";
//   Integer pendulum.pendulum.body.cylinderColor[2](min = 0, max = 255) "Color of cylinder";
//   Integer pendulum.pendulum.body.cylinderColor[3](min = 0, max = 255) "Color of cylinder";
//   Real pendulum.pendulum.body.specularCoefficient(min = 0.0) = pendulum.world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   parameter Boolean pendulum.pendulum.body.enforceStates = false "= true, if absolute variables of body object shall be used as states (StateSelect.always)";
//   parameter Boolean pendulum.pendulum.body.useQuaternions = pendulum.pendulum.useQuaternions "= true, if quaternions shall be used as potential states otherwise use 3 angles as potential states";
//   parameter Integer pendulum.pendulum.body.sequence_angleStates[1](min = 1, max = 3) = pendulum.pendulum.sequence_angleStates[1] "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   parameter Integer pendulum.pendulum.body.sequence_angleStates[2](min = 1, max = 3) = pendulum.pendulum.sequence_angleStates[2] "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   parameter Integer pendulum.pendulum.body.sequence_angleStates[3](min = 1, max = 3) = pendulum.pendulum.sequence_angleStates[3] "Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   final parameter Real pendulum.pendulum.body.I[1,1](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_11 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.I[1,2](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_21 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.I[1,3](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_31 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.I[2,1](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_21 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.I[2,2](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_22 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.I[2,3](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_32 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.I[3,1](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_31 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.I[3,2](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_32 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.I[3,3](quantity = "MomentOfInertia", unit = "kg.m2") = pendulum.pendulum.body.I_33 "inertia tensor";
//   final parameter Real pendulum.pendulum.body.R_start.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real pendulum.pendulum.body.R_start.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   final parameter Real pendulum.pendulum.body.R_start.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   final parameter Real pendulum.pendulum.body.R_start.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   final parameter Real pendulum.pendulum.body.z_a_start[1](quantity = "AngularAcceleration", unit = "rad/s2") = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.z_0_start[1], pendulum.pendulum.body.z_0_start[2], pendulum.pendulum.body.z_0_start[3]})[1] "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";
//   final parameter Real pendulum.pendulum.body.z_a_start[2](quantity = "AngularAcceleration", unit = "rad/s2") = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.z_0_start[1], pendulum.pendulum.body.z_0_start[2], pendulum.pendulum.body.z_0_start[3]})[2] "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";
//   final parameter Real pendulum.pendulum.body.z_a_start[3](quantity = "AngularAcceleration", unit = "rad/s2") = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.z_0_start[1], pendulum.pendulum.body.z_0_start[2], pendulum.pendulum.body.z_0_start[3]})[3] "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";
//   Real pendulum.pendulum.body.w_a[1](quantity = "AngularVelocity", unit = "rad/s", start = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.w_0_start[1], pendulum.pendulum.body.w_0_start[2], pendulum.pendulum.body.w_0_start[3]})[1], fixed = false, stateSelect = StateSelect.avoid) "Absolute angular velocity of frame_a resolved in frame_a";
//   Real pendulum.pendulum.body.w_a[2](quantity = "AngularVelocity", unit = "rad/s", start = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.w_0_start[1], pendulum.pendulum.body.w_0_start[2], pendulum.pendulum.body.w_0_start[3]})[2], fixed = false, stateSelect = StateSelect.avoid) "Absolute angular velocity of frame_a resolved in frame_a";
//   Real pendulum.pendulum.body.w_a[3](quantity = "AngularVelocity", unit = "rad/s", start = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.w_0_start[1], pendulum.pendulum.body.w_0_start[2], pendulum.pendulum.body.w_0_start[3]})[3], fixed = false, stateSelect = StateSelect.avoid) "Absolute angular velocity of frame_a resolved in frame_a";
//   Real pendulum.pendulum.body.z_a[1](quantity = "AngularAcceleration", unit = "rad/s2", start = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.z_0_start[1], pendulum.pendulum.body.z_0_start[2], pendulum.pendulum.body.z_0_start[3]})[1], fixed = false) "Absolute angular acceleration of frame_a resolved in frame_a";
//   Real pendulum.pendulum.body.z_a[2](quantity = "AngularAcceleration", unit = "rad/s2", start = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.z_0_start[1], pendulum.pendulum.body.z_0_start[2], pendulum.pendulum.body.z_0_start[3]})[2], fixed = false) "Absolute angular acceleration of frame_a resolved in frame_a";
//   Real pendulum.pendulum.body.z_a[3](quantity = "AngularAcceleration", unit = "rad/s2", start = Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.z_0_start[1], pendulum.pendulum.body.z_0_start[2], pendulum.pendulum.body.z_0_start[3]})[3], fixed = false) "Absolute angular acceleration of frame_a resolved in frame_a";
//   Real pendulum.pendulum.body.g_0[1](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration resolved in world frame";
//   Real pendulum.pendulum.body.g_0[2](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration resolved in world frame";
//   Real pendulum.pendulum.body.g_0[3](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration resolved in world frame";
//   protected parameter Real pendulum.pendulum.body.Q_start[1] = Modelica.Mechanics.MultiBody.Frames.to_Q(pendulum.pendulum.body.R_start, {0.0, 0.0, 0.0, 1.0})[1] "Quaternion orientation object from world frame to frame_a at initial time";
//   protected parameter Real pendulum.pendulum.body.Q_start[2] = Modelica.Mechanics.MultiBody.Frames.to_Q(pendulum.pendulum.body.R_start, {0.0, 0.0, 0.0, 1.0})[2] "Quaternion orientation object from world frame to frame_a at initial time";
//   protected parameter Real pendulum.pendulum.body.Q_start[3] = Modelica.Mechanics.MultiBody.Frames.to_Q(pendulum.pendulum.body.R_start, {0.0, 0.0, 0.0, 1.0})[3] "Quaternion orientation object from world frame to frame_a at initial time";
//   protected parameter Real pendulum.pendulum.body.Q_start[4] = Modelica.Mechanics.MultiBody.Frames.to_Q(pendulum.pendulum.body.R_start, {0.0, 0.0, 0.0, 1.0})[4] "Quaternion orientation object from world frame to frame_a at initial time";
//   protected Real pendulum.pendulum.body.Q[1](start = pendulum.pendulum.body.Q_start[1], stateSelect = StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
//   protected Real pendulum.pendulum.body.Q[2](start = pendulum.pendulum.body.Q_start[2], stateSelect = StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
//   protected Real pendulum.pendulum.body.Q[3](start = pendulum.pendulum.body.Q_start[3], stateSelect = StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
//   protected Real pendulum.pendulum.body.Q[4](start = pendulum.pendulum.body.Q_start[4], stateSelect = StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
//   protected parameter Real pendulum.pendulum.body.phi_start[1](quantity = "Angle", unit = "rad", displayUnit = "deg") = if pendulum.pendulum.body.sequence_start[1] == pendulum.pendulum.body.sequence_angleStates[1] and pendulum.pendulum.body.sequence_start[2] == pendulum.pendulum.body.sequence_angleStates[2] and pendulum.pendulum.body.sequence_start[3] == pendulum.pendulum.body.sequence_angleStates[3] then pendulum.pendulum.body.angles_start[1] else Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.sequence_angleStates[1], pendulum.pendulum.body.sequence_angleStates[2], pendulum.pendulum.body.sequence_angleStates[3]}, 0.0)[1] "Potential angle states at initial time";
//   protected parameter Real pendulum.pendulum.body.phi_start[2](quantity = "Angle", unit = "rad", displayUnit = "deg") = if pendulum.pendulum.body.sequence_start[1] == pendulum.pendulum.body.sequence_angleStates[1] and pendulum.pendulum.body.sequence_start[2] == pendulum.pendulum.body.sequence_angleStates[2] and pendulum.pendulum.body.sequence_start[3] == pendulum.pendulum.body.sequence_angleStates[3] then pendulum.pendulum.body.angles_start[2] else Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.sequence_angleStates[1], pendulum.pendulum.body.sequence_angleStates[2], pendulum.pendulum.body.sequence_angleStates[3]}, 0.0)[2] "Potential angle states at initial time";
//   protected parameter Real pendulum.pendulum.body.phi_start[3](quantity = "Angle", unit = "rad", displayUnit = "deg") = if pendulum.pendulum.body.sequence_start[1] == pendulum.pendulum.body.sequence_angleStates[1] and pendulum.pendulum.body.sequence_start[2] == pendulum.pendulum.body.sequence_angleStates[2] and pendulum.pendulum.body.sequence_start[3] == pendulum.pendulum.body.sequence_angleStates[3] then pendulum.pendulum.body.angles_start[3] else Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles(pendulum.pendulum.body.R_start, {pendulum.pendulum.body.sequence_angleStates[1], pendulum.pendulum.body.sequence_angleStates[2], pendulum.pendulum.body.sequence_angleStates[3]}, 0.0)[3] "Potential angle states at initial time";
//   protected Real pendulum.pendulum.body.phi[1](quantity = "Angle", unit = "rad", displayUnit = "deg", start = pendulum.pendulum.body.phi_start[1], stateSelect = StateSelect.avoid) "Dummy or 3 angles to rotate world frame into frame_a of body";
//   protected Real pendulum.pendulum.body.phi[2](quantity = "Angle", unit = "rad", displayUnit = "deg", start = pendulum.pendulum.body.phi_start[2], stateSelect = StateSelect.avoid) "Dummy or 3 angles to rotate world frame into frame_a of body";
//   protected Real pendulum.pendulum.body.phi[3](quantity = "Angle", unit = "rad", displayUnit = "deg", start = pendulum.pendulum.body.phi_start[3], stateSelect = StateSelect.avoid) "Dummy or 3 angles to rotate world frame into frame_a of body";
//   protected Real pendulum.pendulum.body.phi_d[1](quantity = "AngularVelocity", unit = "rad/s", stateSelect = StateSelect.avoid) "= der(phi)";
//   protected Real pendulum.pendulum.body.phi_d[2](quantity = "AngularVelocity", unit = "rad/s", stateSelect = StateSelect.avoid) "= der(phi)";
//   protected Real pendulum.pendulum.body.phi_d[3](quantity = "AngularVelocity", unit = "rad/s", stateSelect = StateSelect.avoid) "= der(phi)";
//   protected Real pendulum.pendulum.body.phi_dd[1](quantity = "AngularAcceleration", unit = "rad/s2") "= der(phi_d)";
//   protected Real pendulum.pendulum.body.phi_dd[2](quantity = "AngularAcceleration", unit = "rad/s2") "= der(phi_d)";
//   protected Real pendulum.pendulum.body.phi_dd[3](quantity = "AngularAcceleration", unit = "rad/s2") "= der(phi_d)";
//   Real pendulum.pendulum.frameTranslation.frame_a.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_a.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.pendulum.frameTranslation.frame_b.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   parameter Boolean pendulum.pendulum.frameTranslation.animation = pendulum.pendulum.animation "= true, if animation shall be enabled";
//   parameter Real pendulum.pendulum.frameTranslation.r[1](quantity = "Length", unit = "m", start = 0.0) = pendulum.pendulum.r[1] "Vector from frame_a to frame_b resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.r[2](quantity = "Length", unit = "m", start = 0.0) = pendulum.pendulum.r[2] "Vector from frame_a to frame_b resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.r[3](quantity = "Length", unit = "m", start = 0.0) = pendulum.pendulum.r[3] "Vector from frame_a to frame_b resolved in frame_a";
//   parameter String pendulum.pendulum.frameTranslation.shapeType = "pipecylinder" "Type of shape";
//   parameter Real pendulum.pendulum.frameTranslation.r_shape[1](quantity = "Length", unit = "m") = pendulum.pendulum.r_shape[1] "Vector from frame_a to shape origin, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.r_shape[2](quantity = "Length", unit = "m") = pendulum.pendulum.r_shape[2] "Vector from frame_a to shape origin, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.r_shape[3](quantity = "Length", unit = "m") = pendulum.pendulum.r_shape[3] "Vector from frame_a to shape origin, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.lengthDirection[1](unit = "1") = pendulum.pendulum.lengthDirection[1] "Vector in length direction of shape, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.lengthDirection[2](unit = "1") = pendulum.pendulum.lengthDirection[2] "Vector in length direction of shape, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.lengthDirection[3](unit = "1") = pendulum.pendulum.lengthDirection[3] "Vector in length direction of shape, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.widthDirection[1](unit = "1") = 0.0 "Vector in width direction of shape, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.widthDirection[2](unit = "1") = 1.0 "Vector in width direction of shape, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.widthDirection[3](unit = "1") = 0.0 "Vector in width direction of shape, resolved in frame_a";
//   parameter Real pendulum.pendulum.frameTranslation.length(quantity = "Length", unit = "m") = pendulum.pendulum.length "Length of shape";
//   parameter Real pendulum.pendulum.frameTranslation.width(quantity = "Length", unit = "m", min = 0.0) = pendulum.pendulum.diameter "Width of shape";
//   parameter Real pendulum.pendulum.frameTranslation.height(quantity = "Length", unit = "m", min = 0.0) = pendulum.pendulum.diameter "Height of shape";
//   parameter Real pendulum.pendulum.frameTranslation.extra = pendulum.pendulum.innerDiameter / pendulum.pendulum.diameter "Additional parameter depending on shapeType (see docu of Visualizers.Advanced.Shape)";
//   Integer pendulum.pendulum.frameTranslation.color[1](min = 0, max = 255) "Color of shape";
//   Integer pendulum.pendulum.frameTranslation.color[2](min = 0, max = 255) "Color of shape";
//   Integer pendulum.pendulum.frameTranslation.color[3](min = 0, max = 255) "Color of shape";
//   Real pendulum.pendulum.frameTranslation.specularCoefficient(min = 0.0) = pendulum.pendulum.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter String pendulum.pendulum.frameTranslation.shape.shapeType = pendulum.pendulum.frameTranslation.shapeType "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[1,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[1,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[1,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[2,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[2,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[2,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[3,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[3,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.T[3,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.pendulum.frameTranslation.frame_a.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.pendulum.frameTranslation.frame_a.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.pendulum.frameTranslation.frame_a.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.pendulum.frameTranslation.shape.length(quantity = "Length", unit = "m") = pendulum.pendulum.frameTranslation.length "Length of visual object";
//   protected Real pendulum.pendulum.frameTranslation.shape.width(quantity = "Length", unit = "m") = pendulum.pendulum.frameTranslation.width "Width of visual object";
//   protected Real pendulum.pendulum.frameTranslation.shape.height(quantity = "Length", unit = "m") = pendulum.pendulum.frameTranslation.height "Height of visual object";
//   protected Real pendulum.pendulum.frameTranslation.shape.extra = pendulum.pendulum.frameTranslation.extra "Additional size data for some of the shape types";
//   protected Real pendulum.pendulum.frameTranslation.shape.color[1] "Color of shape";
//   protected Real pendulum.pendulum.frameTranslation.shape.color[2] "Color of shape";
//   protected Real pendulum.pendulum.frameTranslation.shape.color[3] "Color of shape";
//   protected Real pendulum.pendulum.frameTranslation.shape.specularCoefficient(min = 0.0) = pendulum.pendulum.frameTranslation.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   Real pendulum.revolute.frame_a.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.revolute.frame_a.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.revolute.frame_a.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.revolute.frame_a.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_a.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.revolute.frame_a.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.revolute.frame_a.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.revolute.frame_a.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.revolute.frame_a.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.revolute.frame_a.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.revolute.frame_a.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.revolute.frame_a.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.revolute.frame_a.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.revolute.frame_b.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.revolute.frame_b.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.revolute.frame_b.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real pendulum.revolute.frame_b.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real pendulum.revolute.frame_b.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.revolute.frame_b.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.revolute.frame_b.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real pendulum.revolute.frame_b.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.revolute.frame_b.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.revolute.frame_b.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real pendulum.revolute.frame_b.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.revolute.frame_b.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real pendulum.revolute.frame_b.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   parameter Boolean pendulum.revolute.useAxisFlange = false "= true, if axis flange is enabled";
//   parameter Boolean pendulum.revolute.animation = true "= true, if animation shall be enabled (show axis as cylinder)";
//   parameter Real pendulum.revolute.n[1](unit = "1") = 0.0 "Axis of rotation resolved in frame_a (= same as in frame_b)";
//   parameter Real pendulum.revolute.n[2](unit = "1") = 0.0 "Axis of rotation resolved in frame_a (= same as in frame_b)";
//   parameter Real pendulum.revolute.n[3](unit = "1") = 1.0 "Axis of rotation resolved in frame_a (= same as in frame_b)";
//   constant Real pendulum.revolute.phi_offset(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Relative angle offset (angle = phi_offset + phi)";
//   parameter Real pendulum.revolute.cylinderLength(quantity = "Length", unit = "m", min = 0.0) = pendulum.world.defaultJointLength "Length of cylinder representing the joint axis";
//   parameter Real pendulum.revolute.cylinderDiameter(quantity = "Length", unit = "m", min = 0.0) = pendulum.world.defaultJointWidth "Diameter of cylinder representing the joint axis";
//   Integer pendulum.revolute.cylinderColor[1](min = 0, max = 255) "Color of cylinder representing the joint axis";
//   Integer pendulum.revolute.cylinderColor[2](min = 0, max = 255) "Color of cylinder representing the joint axis";
//   Integer pendulum.revolute.cylinderColor[3](min = 0, max = 255) "Color of cylinder representing the joint axis";
//   Real pendulum.revolute.specularCoefficient(min = 0.0) = pendulum.world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   parameter enumeration(never, avoid, default, prefer, always) pendulum.revolute.stateSelect = StateSelect.prefer "Priority to use joint angle phi and w=der(phi) as states";
//   Real pendulum.revolute.phi(quantity = "Angle", unit = "rad", displayUnit = "deg", start = 0.0, stateSelect = StateSelect.prefer) "Relative rotation angle from frame_a to frame_b";
//   Real pendulum.revolute.w(quantity = "AngularVelocity", unit = "rad/s", start = 0.0, stateSelect = StateSelect.prefer) "First derivative of angle phi (relative angular velocity)";
//   Real pendulum.revolute.a(quantity = "AngularAcceleration", unit = "rad/s2", start = 0.0) "Second derivative of angle phi (relative angular acceleration)";
//   Real pendulum.revolute.tau(quantity = "Torque", unit = "N.m") "Driving torque in direction of axis of rotation";
//   Real pendulum.revolute.angle(quantity = "Angle", unit = "rad", displayUnit = "deg") "= phi_offset + phi";
//   protected parameter Real pendulum.revolute.e[1](unit = "1") = 0.0 "Unit vector in direction of rotation axis, resolved in frame_a (= same as in frame_b)";
//   protected parameter Real pendulum.revolute.e[2](unit = "1") = 0.0 "Unit vector in direction of rotation axis, resolved in frame_a (= same as in frame_b)";
//   protected parameter Real pendulum.revolute.e[3](unit = "1") = 1.0 "Unit vector in direction of rotation axis, resolved in frame_a (= same as in frame_b)";
//   protected Real pendulum.revolute.R_rel.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.R_rel.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.revolute.R_rel.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.revolute.R_rel.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   protected parameter Real pendulum.revolute.fixed.phi0(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Fixed offset angle of housing";
//   protected Real pendulum.revolute.fixed.flange.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   protected Real pendulum.revolute.fixed.flange.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   protected Real pendulum.revolute.internalAxis.tau(quantity = "Torque", unit = "N.m") = pendulum.revolute.tau "External support torque (must be computed via torque balance in model where InternalSupport is used; = flange.tau)";
//   protected Real pendulum.revolute.internalAxis.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "External support angle (= flange.phi)";
//   protected Real pendulum.revolute.internalAxis.flange.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   protected Real pendulum.revolute.internalAxis.flange.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   protected parameter String pendulum.revolute.cylinder.shapeType = "cylinder" "Type of shape (box, sphere, cylinder, pipecylinder, cone, pipe, beam, gearwheel, spring, <external shape>)";
//   protected Real pendulum.revolute.cylinder.R.T[1,1] = pendulum.revolute.frame_a.R.T[1,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.T[1,2] = pendulum.revolute.frame_a.R.T[1,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.T[1,3] = pendulum.revolute.frame_a.R.T[1,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.T[2,1] = pendulum.revolute.frame_a.R.T[2,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.T[2,2] = pendulum.revolute.frame_a.R.T[2,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.T[2,3] = pendulum.revolute.frame_a.R.T[2,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.T[3,1] = pendulum.revolute.frame_a.R.T[3,1] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.T[3,2] = pendulum.revolute.frame_a.R.T[3,2] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.T[3,3] = pendulum.revolute.frame_a.R.T[3,3] "Transformation matrix from world frame to local frame";
//   protected Real pendulum.revolute.cylinder.R.w[1](quantity = "AngularVelocity", unit = "rad/s") = pendulum.revolute.frame_a.R.w[1] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.revolute.cylinder.R.w[2](quantity = "AngularVelocity", unit = "rad/s") = pendulum.revolute.frame_a.R.w[2] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.revolute.cylinder.R.w[3](quantity = "AngularVelocity", unit = "rad/s") = pendulum.revolute.frame_a.R.w[3] "Absolute angular velocity of local frame, resolved in local frame";
//   protected Real pendulum.revolute.cylinder.r[1](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.revolute.cylinder.r[2](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.revolute.cylinder.r[3](quantity = "Length", unit = "m") "Position vector from origin of world frame to origin of object frame, resolved in world frame";
//   protected Real pendulum.revolute.cylinder.r_shape[1](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.r_shape[2](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.r_shape[3](quantity = "Length", unit = "m") "Position vector from origin of object frame to shape origin, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.lengthDirection[1](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.lengthDirection[2](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.lengthDirection[3](unit = "1") "Vector in length direction, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.widthDirection[1](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.widthDirection[2](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.widthDirection[3](unit = "1") "Vector in width direction, resolved in object frame";
//   protected Real pendulum.revolute.cylinder.length(quantity = "Length", unit = "m") = pendulum.revolute.cylinderLength "Length of visual object";
//   protected Real pendulum.revolute.cylinder.width(quantity = "Length", unit = "m") = pendulum.revolute.cylinderDiameter "Width of visual object";
//   protected Real pendulum.revolute.cylinder.height(quantity = "Length", unit = "m") = pendulum.revolute.cylinderDiameter "Height of visual object";
//   protected Real pendulum.revolute.cylinder.extra = 0.0 "Additional size data for some of the shape types";
//   protected Real pendulum.revolute.cylinder.color[1] "Color of shape";
//   protected Real pendulum.revolute.cylinder.color[2] "Color of shape";
//   protected Real pendulum.revolute.cylinder.color[3] "Color of shape";
//   protected Real pendulum.revolute.cylinder.specularCoefficient(min = 0.0) = pendulum.revolute.specularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   protected parameter Boolean pendulum.revolute.constantTorque.useSupport = false "= true, if support flange enabled, otherwise implicitly grounded";
//   protected Real pendulum.revolute.constantTorque.flange.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute rotation angle of flange";
//   protected Real pendulum.revolute.constantTorque.flange.tau(quantity = "Torque", unit = "N.m") "Cut torque in the flange";
//   protected Real pendulum.revolute.constantTorque.phi_support(quantity = "Angle", unit = "rad", displayUnit = "deg") "Absolute angle of support flange";
//   protected Real pendulum.revolute.constantTorque.phi(quantity = "Angle", unit = "rad", displayUnit = "deg") "Angle of flange with respect to support (= flange.phi - support.phi)";
//   protected parameter Real pendulum.revolute.constantTorque.tau_constant(quantity = "Torque", unit = "N.m") = 0.0 "Constant torque (if negative, torque is acting as load)";
//   protected Real pendulum.revolute.constantTorque.tau(quantity = "Torque", unit = "N.m") "Accelerating torque acting at flange (= -flange.tau)";
// equation
//   pendulum.world.axisColor_x = {0, 0, 0};
//   pendulum.world.axisColor_y = {pendulum.world.axisColor_x[1], pendulum.world.axisColor_x[2], pendulum.world.axisColor_x[3]};
//   pendulum.world.axisColor_z = {pendulum.world.axisColor_x[1], pendulum.world.axisColor_x[2], pendulum.world.axisColor_x[3]};
//   pendulum.world.gravityArrowColor = {0, 230, 0};
//   pendulum.world.gravitySphereColor = {0, 230, 0};
//   pendulum.world.x_arrowLine.r = {0.0, 0.0, 0.0};
//   pendulum.world.x_arrowLine.r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.x_arrowLine.lengthDirection = {1.0, 0.0, 0.0};
//   pendulum.world.x_arrowLine.widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.x_arrowLine.color = {/*Real*/(pendulum.world.axisColor_x[1]), /*Real*/(pendulum.world.axisColor_x[2]), /*Real*/(pendulum.world.axisColor_x[3])};
//   pendulum.world.x_arrowHead.r = {pendulum.world.lineLength, 0.0, 0.0};
//   pendulum.world.x_arrowHead.r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.x_arrowHead.lengthDirection = {1.0, 0.0, 0.0};
//   pendulum.world.x_arrowHead.widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.x_arrowHead.color = {/*Real*/(pendulum.world.axisColor_x[1]), /*Real*/(pendulum.world.axisColor_x[2]), /*Real*/(pendulum.world.axisColor_x[3])};
//   pendulum.world.x_label.r = {0.0, 0.0, 0.0};
//   pendulum.world.x_label.r_lines = {pendulum.world.labelStart, 0.0, 0.0};
//   pendulum.world.x_label.n_x = {1.0, 0.0, 0.0};
//   pendulum.world.x_label.n_y = {0.0, 1.0, 0.0};
//   pendulum.world.x_label.lines = {{{0.0, 0.0}, {pendulum.world.scaledLabel, pendulum.world.scaledLabel}}, {{0.0, pendulum.world.scaledLabel}, {pendulum.world.scaledLabel, 0.0}}};
//   pendulum.world.x_label.color = {pendulum.world.axisColor_x[1], pendulum.world.axisColor_x[2], pendulum.world.axisColor_x[3]};
//   pendulum.world.x_label.R_rel = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.from_nxy({pendulum.world.x_label.n_x[1], pendulum.world.x_label.n_x[2], pendulum.world.x_label.n_x[3]}, {pendulum.world.x_label.n_y[1], pendulum.world.x_label.n_y[2], pendulum.world.x_label.n_y[3]});
//   pendulum.world.x_label.R_lines = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.absoluteRotation({{pendulum.world.x_label.R.T[1,1], pendulum.world.x_label.R.T[1,2], pendulum.world.x_label.R.T[1,3]}, {pendulum.world.x_label.R.T[2,1], pendulum.world.x_label.R.T[2,2], pendulum.world.x_label.R.T[2,3]}, {pendulum.world.x_label.R.T[3,1], pendulum.world.x_label.R.T[3,2], pendulum.world.x_label.R.T[3,3]}}, {{pendulum.world.x_label.R_rel[1,1], pendulum.world.x_label.R_rel[1,2], pendulum.world.x_label.R_rel[1,3]}, {pendulum.world.x_label.R_rel[2,1], pendulum.world.x_label.R_rel[2,2], pendulum.world.x_label.R_rel[2,3]}, {pendulum.world.x_label.R_rel[3,1], pendulum.world.x_label.R_rel[3,2], pendulum.world.x_label.R_rel[3,3]}});
//   pendulum.world.x_label.r_abs = {pendulum.world.x_label.r[1], pendulum.world.x_label.r[2], pendulum.world.x_label.r[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.x_label.R.T[1,1], pendulum.world.x_label.R.T[1,2], pendulum.world.x_label.R.T[1,3]}, {pendulum.world.x_label.R.T[2,1], pendulum.world.x_label.R.T[2,2], pendulum.world.x_label.R.T[2,3]}, {pendulum.world.x_label.R.T[3,1], pendulum.world.x_label.R.T[3,2], pendulum.world.x_label.R.T[3,3]}}, {pendulum.world.x_label.r_lines[1], pendulum.world.x_label.r_lines[2], pendulum.world.x_label.r_lines[3]});
//   pendulum.world.x_label.cylinders[1].r = {pendulum.world.x_label.r_abs[1], pendulum.world.x_label.r_abs[2], pendulum.world.x_label.r_abs[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.x_label.R_lines[1,1], pendulum.world.x_label.R_lines[1,2], pendulum.world.x_label.R_lines[1,3]}, {pendulum.world.x_label.R_lines[2,1], pendulum.world.x_label.R_lines[2,2], pendulum.world.x_label.R_lines[2,3]}, {pendulum.world.x_label.R_lines[3,1], pendulum.world.x_label.R_lines[3,2], pendulum.world.x_label.R_lines[3,3]}}, {pendulum.world.x_label.lines[1,1,1], pendulum.world.x_label.lines[1,1,2], 0.0});
//   pendulum.world.x_label.cylinders[1].r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.x_label.cylinders[1].lengthDirection = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.x_label.R_rel[1,1], pendulum.world.x_label.R_rel[1,2], pendulum.world.x_label.R_rel[1,3]}, {pendulum.world.x_label.R_rel[2,1], pendulum.world.x_label.R_rel[2,2], pendulum.world.x_label.R_rel[2,3]}, {pendulum.world.x_label.R_rel[3,1], pendulum.world.x_label.R_rel[3,2], pendulum.world.x_label.R_rel[3,3]}}, {pendulum.world.x_label.lines[1,2,1] - pendulum.world.x_label.lines[1,1,1], pendulum.world.x_label.lines[1,2,2] - pendulum.world.x_label.lines[1,1,2], 0.0});
//   pendulum.world.x_label.cylinders[1].widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.x_label.cylinders[1].color = {/*Real*/(pendulum.world.x_label.color[1]), /*Real*/(pendulum.world.x_label.color[2]), /*Real*/(pendulum.world.x_label.color[3])};
//   pendulum.world.x_label.cylinders[2].r = {pendulum.world.x_label.r_abs[1], pendulum.world.x_label.r_abs[2], pendulum.world.x_label.r_abs[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.x_label.R_lines[1,1], pendulum.world.x_label.R_lines[1,2], pendulum.world.x_label.R_lines[1,3]}, {pendulum.world.x_label.R_lines[2,1], pendulum.world.x_label.R_lines[2,2], pendulum.world.x_label.R_lines[2,3]}, {pendulum.world.x_label.R_lines[3,1], pendulum.world.x_label.R_lines[3,2], pendulum.world.x_label.R_lines[3,3]}}, {pendulum.world.x_label.lines[2,1,1], pendulum.world.x_label.lines[2,1,2], 0.0});
//   pendulum.world.x_label.cylinders[2].r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.x_label.cylinders[2].lengthDirection = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.x_label.R_rel[1,1], pendulum.world.x_label.R_rel[1,2], pendulum.world.x_label.R_rel[1,3]}, {pendulum.world.x_label.R_rel[2,1], pendulum.world.x_label.R_rel[2,2], pendulum.world.x_label.R_rel[2,3]}, {pendulum.world.x_label.R_rel[3,1], pendulum.world.x_label.R_rel[3,2], pendulum.world.x_label.R_rel[3,3]}}, {pendulum.world.x_label.lines[2,2,1] - pendulum.world.x_label.lines[2,1,1], pendulum.world.x_label.lines[2,2,2] - pendulum.world.x_label.lines[2,1,2], 0.0});
//   pendulum.world.x_label.cylinders[2].widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.x_label.cylinders[2].color = {/*Real*/(pendulum.world.x_label.color[1]), /*Real*/(pendulum.world.x_label.color[2]), /*Real*/(pendulum.world.x_label.color[3])};
//   pendulum.world.y_arrowLine.r = {0.0, 0.0, 0.0};
//   pendulum.world.y_arrowLine.r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.y_arrowLine.lengthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.y_arrowLine.widthDirection = {1.0, 0.0, 0.0};
//   pendulum.world.y_arrowLine.color = {/*Real*/(pendulum.world.axisColor_y[1]), /*Real*/(pendulum.world.axisColor_y[2]), /*Real*/(pendulum.world.axisColor_y[3])};
//   pendulum.world.y_arrowHead.r = {0.0, pendulum.world.lineLength, 0.0};
//   pendulum.world.y_arrowHead.r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.y_arrowHead.lengthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.y_arrowHead.widthDirection = {1.0, 0.0, 0.0};
//   pendulum.world.y_arrowHead.color = {/*Real*/(pendulum.world.axisColor_y[1]), /*Real*/(pendulum.world.axisColor_y[2]), /*Real*/(pendulum.world.axisColor_y[3])};
//   pendulum.world.y_label.r = {0.0, 0.0, 0.0};
//   pendulum.world.y_label.r_lines = {0.0, pendulum.world.labelStart, 0.0};
//   pendulum.world.y_label.n_x = {0.0, 1.0, 0.0};
//   pendulum.world.y_label.n_y = {-1.0, 0.0, 0.0};
//   pendulum.world.y_label.lines = {{{0.0, 0.0}, {pendulum.world.scaledLabel, 1.5 * pendulum.world.scaledLabel}}, {{0.0, 1.5 * pendulum.world.scaledLabel}, {0.5 * pendulum.world.scaledLabel, 0.75 * pendulum.world.scaledLabel}}};
//   pendulum.world.y_label.color = {pendulum.world.axisColor_y[1], pendulum.world.axisColor_y[2], pendulum.world.axisColor_y[3]};
//   pendulum.world.y_label.R_rel = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.from_nxy({pendulum.world.y_label.n_x[1], pendulum.world.y_label.n_x[2], pendulum.world.y_label.n_x[3]}, {pendulum.world.y_label.n_y[1], pendulum.world.y_label.n_y[2], pendulum.world.y_label.n_y[3]});
//   pendulum.world.y_label.R_lines = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.absoluteRotation({{pendulum.world.y_label.R.T[1,1], pendulum.world.y_label.R.T[1,2], pendulum.world.y_label.R.T[1,3]}, {pendulum.world.y_label.R.T[2,1], pendulum.world.y_label.R.T[2,2], pendulum.world.y_label.R.T[2,3]}, {pendulum.world.y_label.R.T[3,1], pendulum.world.y_label.R.T[3,2], pendulum.world.y_label.R.T[3,3]}}, {{pendulum.world.y_label.R_rel[1,1], pendulum.world.y_label.R_rel[1,2], pendulum.world.y_label.R_rel[1,3]}, {pendulum.world.y_label.R_rel[2,1], pendulum.world.y_label.R_rel[2,2], pendulum.world.y_label.R_rel[2,3]}, {pendulum.world.y_label.R_rel[3,1], pendulum.world.y_label.R_rel[3,2], pendulum.world.y_label.R_rel[3,3]}});
//   pendulum.world.y_label.r_abs = {pendulum.world.y_label.r[1], pendulum.world.y_label.r[2], pendulum.world.y_label.r[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.y_label.R.T[1,1], pendulum.world.y_label.R.T[1,2], pendulum.world.y_label.R.T[1,3]}, {pendulum.world.y_label.R.T[2,1], pendulum.world.y_label.R.T[2,2], pendulum.world.y_label.R.T[2,3]}, {pendulum.world.y_label.R.T[3,1], pendulum.world.y_label.R.T[3,2], pendulum.world.y_label.R.T[3,3]}}, {pendulum.world.y_label.r_lines[1], pendulum.world.y_label.r_lines[2], pendulum.world.y_label.r_lines[3]});
//   pendulum.world.y_label.cylinders[1].r = {pendulum.world.y_label.r_abs[1], pendulum.world.y_label.r_abs[2], pendulum.world.y_label.r_abs[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.y_label.R_lines[1,1], pendulum.world.y_label.R_lines[1,2], pendulum.world.y_label.R_lines[1,3]}, {pendulum.world.y_label.R_lines[2,1], pendulum.world.y_label.R_lines[2,2], pendulum.world.y_label.R_lines[2,3]}, {pendulum.world.y_label.R_lines[3,1], pendulum.world.y_label.R_lines[3,2], pendulum.world.y_label.R_lines[3,3]}}, {pendulum.world.y_label.lines[1,1,1], pendulum.world.y_label.lines[1,1,2], 0.0});
//   pendulum.world.y_label.cylinders[1].r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.y_label.cylinders[1].lengthDirection = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.y_label.R_rel[1,1], pendulum.world.y_label.R_rel[1,2], pendulum.world.y_label.R_rel[1,3]}, {pendulum.world.y_label.R_rel[2,1], pendulum.world.y_label.R_rel[2,2], pendulum.world.y_label.R_rel[2,3]}, {pendulum.world.y_label.R_rel[3,1], pendulum.world.y_label.R_rel[3,2], pendulum.world.y_label.R_rel[3,3]}}, {pendulum.world.y_label.lines[1,2,1] - pendulum.world.y_label.lines[1,1,1], pendulum.world.y_label.lines[1,2,2] - pendulum.world.y_label.lines[1,1,2], 0.0});
//   pendulum.world.y_label.cylinders[1].widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.y_label.cylinders[1].color = {/*Real*/(pendulum.world.y_label.color[1]), /*Real*/(pendulum.world.y_label.color[2]), /*Real*/(pendulum.world.y_label.color[3])};
//   pendulum.world.y_label.cylinders[2].r = {pendulum.world.y_label.r_abs[1], pendulum.world.y_label.r_abs[2], pendulum.world.y_label.r_abs[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.y_label.R_lines[1,1], pendulum.world.y_label.R_lines[1,2], pendulum.world.y_label.R_lines[1,3]}, {pendulum.world.y_label.R_lines[2,1], pendulum.world.y_label.R_lines[2,2], pendulum.world.y_label.R_lines[2,3]}, {pendulum.world.y_label.R_lines[3,1], pendulum.world.y_label.R_lines[3,2], pendulum.world.y_label.R_lines[3,3]}}, {pendulum.world.y_label.lines[2,1,1], pendulum.world.y_label.lines[2,1,2], 0.0});
//   pendulum.world.y_label.cylinders[2].r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.y_label.cylinders[2].lengthDirection = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.y_label.R_rel[1,1], pendulum.world.y_label.R_rel[1,2], pendulum.world.y_label.R_rel[1,3]}, {pendulum.world.y_label.R_rel[2,1], pendulum.world.y_label.R_rel[2,2], pendulum.world.y_label.R_rel[2,3]}, {pendulum.world.y_label.R_rel[3,1], pendulum.world.y_label.R_rel[3,2], pendulum.world.y_label.R_rel[3,3]}}, {pendulum.world.y_label.lines[2,2,1] - pendulum.world.y_label.lines[2,1,1], pendulum.world.y_label.lines[2,2,2] - pendulum.world.y_label.lines[2,1,2], 0.0});
//   pendulum.world.y_label.cylinders[2].widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.y_label.cylinders[2].color = {/*Real*/(pendulum.world.y_label.color[1]), /*Real*/(pendulum.world.y_label.color[2]), /*Real*/(pendulum.world.y_label.color[3])};
//   pendulum.world.z_arrowLine.r = {0.0, 0.0, 0.0};
//   pendulum.world.z_arrowLine.r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.z_arrowLine.lengthDirection = {0.0, 0.0, 1.0};
//   pendulum.world.z_arrowLine.widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.z_arrowLine.color = {/*Real*/(pendulum.world.axisColor_z[1]), /*Real*/(pendulum.world.axisColor_z[2]), /*Real*/(pendulum.world.axisColor_z[3])};
//   pendulum.world.z_arrowHead.r = {0.0, 0.0, pendulum.world.lineLength};
//   pendulum.world.z_arrowHead.r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.z_arrowHead.lengthDirection = {0.0, 0.0, 1.0};
//   pendulum.world.z_arrowHead.widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.z_arrowHead.color = {/*Real*/(pendulum.world.axisColor_z[1]), /*Real*/(pendulum.world.axisColor_z[2]), /*Real*/(pendulum.world.axisColor_z[3])};
//   pendulum.world.z_label.r = {0.0, 0.0, 0.0};
//   pendulum.world.z_label.r_lines = {0.0, 0.0, pendulum.world.labelStart};
//   pendulum.world.z_label.n_x = {0.0, 0.0, 1.0};
//   pendulum.world.z_label.n_y = {0.0, 1.0, 0.0};
//   pendulum.world.z_label.lines = {{{0.0, 0.0}, {pendulum.world.scaledLabel, 0.0}}, {{0.0, pendulum.world.scaledLabel}, {pendulum.world.scaledLabel, pendulum.world.scaledLabel}}, {{0.0, pendulum.world.scaledLabel}, {pendulum.world.scaledLabel, 0.0}}};
//   pendulum.world.z_label.color = {pendulum.world.axisColor_z[1], pendulum.world.axisColor_z[2], pendulum.world.axisColor_z[3]};
//   pendulum.world.z_label.R_rel = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.from_nxy({pendulum.world.z_label.n_x[1], pendulum.world.z_label.n_x[2], pendulum.world.z_label.n_x[3]}, {pendulum.world.z_label.n_y[1], pendulum.world.z_label.n_y[2], pendulum.world.z_label.n_y[3]});
//   pendulum.world.z_label.R_lines = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.absoluteRotation({{pendulum.world.z_label.R.T[1,1], pendulum.world.z_label.R.T[1,2], pendulum.world.z_label.R.T[1,3]}, {pendulum.world.z_label.R.T[2,1], pendulum.world.z_label.R.T[2,2], pendulum.world.z_label.R.T[2,3]}, {pendulum.world.z_label.R.T[3,1], pendulum.world.z_label.R.T[3,2], pendulum.world.z_label.R.T[3,3]}}, {{pendulum.world.z_label.R_rel[1,1], pendulum.world.z_label.R_rel[1,2], pendulum.world.z_label.R_rel[1,3]}, {pendulum.world.z_label.R_rel[2,1], pendulum.world.z_label.R_rel[2,2], pendulum.world.z_label.R_rel[2,3]}, {pendulum.world.z_label.R_rel[3,1], pendulum.world.z_label.R_rel[3,2], pendulum.world.z_label.R_rel[3,3]}});
//   pendulum.world.z_label.r_abs = {pendulum.world.z_label.r[1], pendulum.world.z_label.r[2], pendulum.world.z_label.r[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.z_label.R.T[1,1], pendulum.world.z_label.R.T[1,2], pendulum.world.z_label.R.T[1,3]}, {pendulum.world.z_label.R.T[2,1], pendulum.world.z_label.R.T[2,2], pendulum.world.z_label.R.T[2,3]}, {pendulum.world.z_label.R.T[3,1], pendulum.world.z_label.R.T[3,2], pendulum.world.z_label.R.T[3,3]}}, {pendulum.world.z_label.r_lines[1], pendulum.world.z_label.r_lines[2], pendulum.world.z_label.r_lines[3]});
//   pendulum.world.z_label.cylinders[1].r = {pendulum.world.z_label.r_abs[1], pendulum.world.z_label.r_abs[2], pendulum.world.z_label.r_abs[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.z_label.R_lines[1,1], pendulum.world.z_label.R_lines[1,2], pendulum.world.z_label.R_lines[1,3]}, {pendulum.world.z_label.R_lines[2,1], pendulum.world.z_label.R_lines[2,2], pendulum.world.z_label.R_lines[2,3]}, {pendulum.world.z_label.R_lines[3,1], pendulum.world.z_label.R_lines[3,2], pendulum.world.z_label.R_lines[3,3]}}, {pendulum.world.z_label.lines[1,1,1], pendulum.world.z_label.lines[1,1,2], 0.0});
//   pendulum.world.z_label.cylinders[1].r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.z_label.cylinders[1].lengthDirection = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.z_label.R_rel[1,1], pendulum.world.z_label.R_rel[1,2], pendulum.world.z_label.R_rel[1,3]}, {pendulum.world.z_label.R_rel[2,1], pendulum.world.z_label.R_rel[2,2], pendulum.world.z_label.R_rel[2,3]}, {pendulum.world.z_label.R_rel[3,1], pendulum.world.z_label.R_rel[3,2], pendulum.world.z_label.R_rel[3,3]}}, {pendulum.world.z_label.lines[1,2,1] - pendulum.world.z_label.lines[1,1,1], pendulum.world.z_label.lines[1,2,2] - pendulum.world.z_label.lines[1,1,2], 0.0});
//   pendulum.world.z_label.cylinders[1].widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.z_label.cylinders[1].color = {/*Real*/(pendulum.world.z_label.color[1]), /*Real*/(pendulum.world.z_label.color[2]), /*Real*/(pendulum.world.z_label.color[3])};
//   pendulum.world.z_label.cylinders[2].r = {pendulum.world.z_label.r_abs[1], pendulum.world.z_label.r_abs[2], pendulum.world.z_label.r_abs[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.z_label.R_lines[1,1], pendulum.world.z_label.R_lines[1,2], pendulum.world.z_label.R_lines[1,3]}, {pendulum.world.z_label.R_lines[2,1], pendulum.world.z_label.R_lines[2,2], pendulum.world.z_label.R_lines[2,3]}, {pendulum.world.z_label.R_lines[3,1], pendulum.world.z_label.R_lines[3,2], pendulum.world.z_label.R_lines[3,3]}}, {pendulum.world.z_label.lines[2,1,1], pendulum.world.z_label.lines[2,1,2], 0.0});
//   pendulum.world.z_label.cylinders[2].r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.z_label.cylinders[2].lengthDirection = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.z_label.R_rel[1,1], pendulum.world.z_label.R_rel[1,2], pendulum.world.z_label.R_rel[1,3]}, {pendulum.world.z_label.R_rel[2,1], pendulum.world.z_label.R_rel[2,2], pendulum.world.z_label.R_rel[2,3]}, {pendulum.world.z_label.R_rel[3,1], pendulum.world.z_label.R_rel[3,2], pendulum.world.z_label.R_rel[3,3]}}, {pendulum.world.z_label.lines[2,2,1] - pendulum.world.z_label.lines[2,1,1], pendulum.world.z_label.lines[2,2,2] - pendulum.world.z_label.lines[2,1,2], 0.0});
//   pendulum.world.z_label.cylinders[2].widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.z_label.cylinders[2].color = {/*Real*/(pendulum.world.z_label.color[1]), /*Real*/(pendulum.world.z_label.color[2]), /*Real*/(pendulum.world.z_label.color[3])};
//   pendulum.world.z_label.cylinders[3].r = {pendulum.world.z_label.r_abs[1], pendulum.world.z_label.r_abs[2], pendulum.world.z_label.r_abs[3]} + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.z_label.R_lines[1,1], pendulum.world.z_label.R_lines[1,2], pendulum.world.z_label.R_lines[1,3]}, {pendulum.world.z_label.R_lines[2,1], pendulum.world.z_label.R_lines[2,2], pendulum.world.z_label.R_lines[2,3]}, {pendulum.world.z_label.R_lines[3,1], pendulum.world.z_label.R_lines[3,2], pendulum.world.z_label.R_lines[3,3]}}, {pendulum.world.z_label.lines[3,1,1], pendulum.world.z_label.lines[3,1,2], 0.0});
//   pendulum.world.z_label.cylinders[3].r_shape = {0.0, 0.0, 0.0};
//   pendulum.world.z_label.cylinders[3].lengthDirection = Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{pendulum.world.z_label.R_rel[1,1], pendulum.world.z_label.R_rel[1,2], pendulum.world.z_label.R_rel[1,3]}, {pendulum.world.z_label.R_rel[2,1], pendulum.world.z_label.R_rel[2,2], pendulum.world.z_label.R_rel[2,3]}, {pendulum.world.z_label.R_rel[3,1], pendulum.world.z_label.R_rel[3,2], pendulum.world.z_label.R_rel[3,3]}}, {pendulum.world.z_label.lines[3,2,1] - pendulum.world.z_label.lines[3,1,1], pendulum.world.z_label.lines[3,2,2] - pendulum.world.z_label.lines[3,1,2], 0.0});
//   pendulum.world.z_label.cylinders[3].widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.z_label.cylinders[3].color = {/*Real*/(pendulum.world.z_label.color[1]), /*Real*/(pendulum.world.z_label.color[2]), /*Real*/(pendulum.world.z_label.color[3])};
//   pendulum.world.gravityArrowLine.r = {0.0, 0.0, 0.0};
//   pendulum.world.gravityArrowLine.r_shape = {pendulum.world.gravityArrowTail[1], pendulum.world.gravityArrowTail[2], pendulum.world.gravityArrowTail[3]};
//   pendulum.world.gravityArrowLine.lengthDirection = {pendulum.world.n[1], pendulum.world.n[2], pendulum.world.n[3]};
//   pendulum.world.gravityArrowLine.widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.gravityArrowLine.color = {/*Real*/(pendulum.world.gravityArrowColor[1]), /*Real*/(pendulum.world.gravityArrowColor[2]), /*Real*/(pendulum.world.gravityArrowColor[3])};
//   pendulum.world.gravityArrowHead.r = {0.0, 0.0, 0.0};
//   pendulum.world.gravityArrowHead.r_shape = {pendulum.world.gravityArrowTail[1], pendulum.world.gravityArrowTail[2] - pendulum.world.gravityLineLength, pendulum.world.gravityArrowTail[3]};
//   pendulum.world.gravityArrowHead.lengthDirection = {pendulum.world.n[1], pendulum.world.n[2], pendulum.world.n[3]};
//   pendulum.world.gravityArrowHead.widthDirection = {0.0, 1.0, 0.0};
//   pendulum.world.gravityArrowHead.color = {/*Real*/(pendulum.world.gravityArrowColor[1]), /*Real*/(pendulum.world.gravityArrowColor[2]), /*Real*/(pendulum.world.gravityArrowColor[3])};
//   assert(Modelica.Math.Vectors.length({pendulum.world.n[1], pendulum.world.n[2], pendulum.world.n[3]}) > 1e-10, "Parameter n of World object is wrong (length(n) > 0 required)");
//   pendulum.world.frame_b.r_0[1] = 0.0;
//   pendulum.world.frame_b.r_0[2] = 0.0;
//   pendulum.world.frame_b.r_0[3] = 0.0;
//   pendulum.world.frame_b.R.T[1,1] = 1.0;
//   pendulum.world.frame_b.R.T[1,2] = 0.0;
//   pendulum.world.frame_b.R.T[1,3] = 0.0;
//   pendulum.world.frame_b.R.T[2,1] = 0.0;
//   pendulum.world.frame_b.R.T[2,2] = 1.0;
//   pendulum.world.frame_b.R.T[2,3] = 0.0;
//   pendulum.world.frame_b.R.T[3,1] = 0.0;
//   pendulum.world.frame_b.R.T[3,2] = 0.0;
//   pendulum.world.frame_b.R.T[3,3] = 1.0;
//   pendulum.world.frame_b.R.w[1] = 0.0;
//   pendulum.world.frame_b.R.w[2] = 0.0;
//   pendulum.world.frame_b.R.w[3] = 0.0;
//   pendulum.pendulum.color = {0, 128, 255};
//   pendulum.pendulum.body.sphereColor = {0, 128, 255};
//   pendulum.pendulum.body.cylinderColor = {pendulum.pendulum.body.sphereColor[1], pendulum.pendulum.body.sphereColor[2], pendulum.pendulum.body.sphereColor[3]};
//   pendulum.pendulum.body.r_0[1] = pendulum.pendulum.body.frame_a.r_0[1];
//   pendulum.pendulum.body.r_0[2] = pendulum.pendulum.body.frame_a.r_0[2];
//   pendulum.pendulum.body.r_0[3] = pendulum.pendulum.body.frame_a.r_0[3];
//   pendulum.pendulum.body.Q[1] = 0.0;
//   pendulum.pendulum.body.Q[2] = 0.0;
//   pendulum.pendulum.body.Q[3] = 0.0;
//   pendulum.pendulum.body.Q[4] = 1.0;
//   pendulum.pendulum.body.phi[1] = 0.0;
//   pendulum.pendulum.body.phi[2] = 0.0;
//   pendulum.pendulum.body.phi[3] = 0.0;
//   pendulum.pendulum.body.phi_d[1] = 0.0;
//   pendulum.pendulum.body.phi_d[2] = 0.0;
//   pendulum.pendulum.body.phi_d[3] = 0.0;
//   pendulum.pendulum.body.phi_dd[1] = 0.0;
//   pendulum.pendulum.body.phi_dd[2] = 0.0;
//   pendulum.pendulum.body.phi_dd[3] = 0.0;
//   pendulum.pendulum.body.g_0 = Modelica.Mechanics.MultiBody.World.gravityAcceleration({pendulum.pendulum.body.frame_a.r_0[1], pendulum.pendulum.body.frame_a.r_0[2], pendulum.pendulum.body.frame_a.r_0[3]} + Modelica.Mechanics.MultiBody.Frames.resolve1(pendulum.pendulum.body.frame_a.R, {pendulum.pendulum.body.r_CM[1], pendulum.pendulum.body.r_CM[2], pendulum.pendulum.body.r_CM[3]}), Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity, {0.0, -9.81, 0.0}, 398600000000000.0);
//   pendulum.pendulum.body.v_0[1] = der(pendulum.pendulum.body.frame_a.r_0[1]);
//   pendulum.pendulum.body.v_0[2] = der(pendulum.pendulum.body.frame_a.r_0[2]);
//   pendulum.pendulum.body.v_0[3] = der(pendulum.pendulum.body.frame_a.r_0[3]);
//   pendulum.pendulum.body.a_0[1] = der(pendulum.pendulum.body.v_0[1]);
//   pendulum.pendulum.body.a_0[2] = der(pendulum.pendulum.body.v_0[2]);
//   pendulum.pendulum.body.a_0[3] = der(pendulum.pendulum.body.v_0[3]);
//   pendulum.pendulum.body.w_a = Modelica.Mechanics.MultiBody.Frames.angularVelocity2(pendulum.pendulum.body.frame_a.R);
//   pendulum.pendulum.body.z_a[1] = der(pendulum.pendulum.body.w_a[1]);
//   pendulum.pendulum.body.z_a[2] = der(pendulum.pendulum.body.w_a[2]);
//   pendulum.pendulum.body.z_a[3] = der(pendulum.pendulum.body.w_a[3]);
//   pendulum.pendulum.body.frame_a.f = (Modelica.Mechanics.MultiBody.Frames.resolve2(pendulum.pendulum.body.frame_a.R, {pendulum.pendulum.body.a_0[1] - pendulum.pendulum.body.g_0[1], pendulum.pendulum.body.a_0[2] - pendulum.pendulum.body.g_0[2], pendulum.pendulum.body.a_0[3] - pendulum.pendulum.body.g_0[3]}) + {pendulum.pendulum.body.z_a[2] * pendulum.pendulum.body.r_CM[3] - pendulum.pendulum.body.z_a[3] * pendulum.pendulum.body.r_CM[2], pendulum.pendulum.body.z_a[3] * pendulum.pendulum.body.r_CM[1] - pendulum.pendulum.body.z_a[1] * pendulum.pendulum.body.r_CM[3], pendulum.pendulum.body.z_a[1] * pendulum.pendulum.body.r_CM[2] - pendulum.pendulum.body.z_a[2] * pendulum.pendulum.body.r_CM[1]} + {pendulum.pendulum.body.w_a[2] * (pendulum.pendulum.body.w_a[1] * pendulum.pendulum.body.r_CM[2] - pendulum.pendulum.body.w_a[2] * pendulum.pendulum.body.r_CM[1]) - pendulum.pendulum.body.w_a[3] * (pendulum.pendulum.body.w_a[3] * pendulum.pendulum.body.r_CM[1] - pendulum.pendulum.body.w_a[1] * pendulum.pendulum.body.r_CM[3]), pendulum.pendulum.body.w_a[3] * (pendulum.pendulum.body.w_a[2] * pendulum.pendulum.body.r_CM[3] - pendulum.pendulum.body.w_a[3] * pendulum.pendulum.body.r_CM[2]) - pendulum.pendulum.body.w_a[1] * (pendulum.pendulum.body.w_a[1] * pendulum.pendulum.body.r_CM[2] - pendulum.pendulum.body.w_a[2] * pendulum.pendulum.body.r_CM[1]), pendulum.pendulum.body.w_a[1] * (pendulum.pendulum.body.w_a[3] * pendulum.pendulum.body.r_CM[1] - pendulum.pendulum.body.w_a[1] * pendulum.pendulum.body.r_CM[3]) - pendulum.pendulum.body.w_a[2] * (pendulum.pendulum.body.w_a[2] * pendulum.pendulum.body.r_CM[3] - pendulum.pendulum.body.w_a[3] * pendulum.pendulum.body.r_CM[2])}) * pendulum.pendulum.body.m;
//   pendulum.pendulum.body.frame_a.t[1] = pendulum.pendulum.body.I[1,1] * pendulum.pendulum.body.z_a[1] + pendulum.pendulum.body.I[1,2] * pendulum.pendulum.body.z_a[2] + pendulum.pendulum.body.I[1,3] * pendulum.pendulum.body.z_a[3] + pendulum.pendulum.body.w_a[2] * (pendulum.pendulum.body.I[3,1] * pendulum.pendulum.body.w_a[1] + pendulum.pendulum.body.I[3,2] * pendulum.pendulum.body.w_a[2] + pendulum.pendulum.body.I[3,3] * pendulum.pendulum.body.w_a[3]) - pendulum.pendulum.body.w_a[3] * (pendulum.pendulum.body.I[2,1] * pendulum.pendulum.body.w_a[1] + pendulum.pendulum.body.I[2,2] * pendulum.pendulum.body.w_a[2] + pendulum.pendulum.body.I[2,3] * pendulum.pendulum.body.w_a[3]) + pendulum.pendulum.body.r_CM[2] * pendulum.pendulum.body.frame_a.f[3] - pendulum.pendulum.body.r_CM[3] * pendulum.pendulum.body.frame_a.f[2];
//   pendulum.pendulum.body.frame_a.t[2] = pendulum.pendulum.body.I[2,1] * pendulum.pendulum.body.z_a[1] + pendulum.pendulum.body.I[2,2] * pendulum.pendulum.body.z_a[2] + pendulum.pendulum.body.I[2,3] * pendulum.pendulum.body.z_a[3] + pendulum.pendulum.body.w_a[3] * (pendulum.pendulum.body.I[1,1] * pendulum.pendulum.body.w_a[1] + pendulum.pendulum.body.I[1,2] * pendulum.pendulum.body.w_a[2] + pendulum.pendulum.body.I[1,3] * pendulum.pendulum.body.w_a[3]) - pendulum.pendulum.body.w_a[1] * (pendulum.pendulum.body.I[3,1] * pendulum.pendulum.body.w_a[1] + pendulum.pendulum.body.I[3,2] * pendulum.pendulum.body.w_a[2] + pendulum.pendulum.body.I[3,3] * pendulum.pendulum.body.w_a[3]) + pendulum.pendulum.body.r_CM[3] * pendulum.pendulum.body.frame_a.f[1] - pendulum.pendulum.body.r_CM[1] * pendulum.pendulum.body.frame_a.f[3];
//   pendulum.pendulum.body.frame_a.t[3] = pendulum.pendulum.body.I[3,1] * pendulum.pendulum.body.z_a[1] + pendulum.pendulum.body.I[3,2] * pendulum.pendulum.body.z_a[2] + pendulum.pendulum.body.I[3,3] * pendulum.pendulum.body.z_a[3] + pendulum.pendulum.body.w_a[1] * (pendulum.pendulum.body.I[2,1] * pendulum.pendulum.body.w_a[1] + pendulum.pendulum.body.I[2,2] * pendulum.pendulum.body.w_a[2] + pendulum.pendulum.body.I[2,3] * pendulum.pendulum.body.w_a[3]) - pendulum.pendulum.body.w_a[2] * (pendulum.pendulum.body.I[1,1] * pendulum.pendulum.body.w_a[1] + pendulum.pendulum.body.I[1,2] * pendulum.pendulum.body.w_a[2] + pendulum.pendulum.body.I[1,3] * pendulum.pendulum.body.w_a[3]) + pendulum.pendulum.body.r_CM[1] * pendulum.pendulum.body.frame_a.f[2] - pendulum.pendulum.body.r_CM[2] * pendulum.pendulum.body.frame_a.f[1];
//   pendulum.pendulum.frameTranslation.color = {pendulum.pendulum.color[1], pendulum.pendulum.color[2], pendulum.pendulum.color[3]};
//   pendulum.pendulum.frameTranslation.shape.r = {pendulum.pendulum.frameTranslation.frame_a.r_0[1], pendulum.pendulum.frameTranslation.frame_a.r_0[2], pendulum.pendulum.frameTranslation.frame_a.r_0[3]};
//   pendulum.pendulum.frameTranslation.shape.r_shape = {pendulum.pendulum.frameTranslation.r_shape[1], pendulum.pendulum.frameTranslation.r_shape[2], pendulum.pendulum.frameTranslation.r_shape[3]};
//   pendulum.pendulum.frameTranslation.shape.lengthDirection = {pendulum.pendulum.frameTranslation.lengthDirection[1], pendulum.pendulum.frameTranslation.lengthDirection[2], pendulum.pendulum.frameTranslation.lengthDirection[3]};
//   pendulum.pendulum.frameTranslation.shape.widthDirection = {pendulum.pendulum.frameTranslation.widthDirection[1], pendulum.pendulum.frameTranslation.widthDirection[2], pendulum.pendulum.frameTranslation.widthDirection[3]};
//   pendulum.pendulum.frameTranslation.shape.color = {/*Real*/(pendulum.pendulum.frameTranslation.color[1]), /*Real*/(pendulum.pendulum.frameTranslation.color[2]), /*Real*/(pendulum.pendulum.frameTranslation.color[3])};
//   pendulum.pendulum.frameTranslation.frame_b.r_0 = pendulum.pendulum.frameTranslation.frame_a.r_0 + Modelica.Mechanics.MultiBody.Frames.resolve1(pendulum.pendulum.frameTranslation.frame_a.R, {pendulum.pendulum.frameTranslation.r[1], pendulum.pendulum.frameTranslation.r[2], pendulum.pendulum.frameTranslation.r[3]});
//   pendulum.pendulum.frameTranslation.frame_b.R.T[1,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,1];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[1,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,2];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[1,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,3];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[2,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,1];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[2,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,2];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[2,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,3];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[3,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,1];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[3,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,2];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[3,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,3];
//   pendulum.pendulum.frameTranslation.frame_b.R.w[1] = pendulum.pendulum.frameTranslation.frame_a.R.w[1];
//   pendulum.pendulum.frameTranslation.frame_b.R.w[2] = pendulum.pendulum.frameTranslation.frame_a.R.w[2];
//   pendulum.pendulum.frameTranslation.frame_b.R.w[3] = pendulum.pendulum.frameTranslation.frame_a.R.w[3];
//   0.0 = pendulum.pendulum.frameTranslation.frame_a.f[1] + pendulum.pendulum.frameTranslation.frame_b.f[1];
//   0.0 = pendulum.pendulum.frameTranslation.frame_a.f[2] + pendulum.pendulum.frameTranslation.frame_b.f[2];
//   0.0 = pendulum.pendulum.frameTranslation.frame_a.f[3] + pendulum.pendulum.frameTranslation.frame_b.f[3];
//   0.0 = pendulum.pendulum.frameTranslation.frame_a.t[1] + pendulum.pendulum.frameTranslation.frame_b.t[1] + pendulum.pendulum.frameTranslation.r[2] * pendulum.pendulum.frameTranslation.frame_b.f[3] - pendulum.pendulum.frameTranslation.r[3] * pendulum.pendulum.frameTranslation.frame_b.f[2];
//   0.0 = pendulum.pendulum.frameTranslation.frame_a.t[2] + pendulum.pendulum.frameTranslation.frame_b.t[2] + pendulum.pendulum.frameTranslation.r[3] * pendulum.pendulum.frameTranslation.frame_b.f[1] - pendulum.pendulum.frameTranslation.r[1] * pendulum.pendulum.frameTranslation.frame_b.f[3];
//   0.0 = pendulum.pendulum.frameTranslation.frame_a.t[3] + pendulum.pendulum.frameTranslation.frame_b.t[3] + pendulum.pendulum.frameTranslation.r[1] * pendulum.pendulum.frameTranslation.frame_b.f[2] - pendulum.pendulum.frameTranslation.r[2] * pendulum.pendulum.frameTranslation.frame_b.f[1];
//   pendulum.pendulum.r_0[1] = pendulum.pendulum.frame_a.r_0[1];
//   pendulum.pendulum.r_0[2] = pendulum.pendulum.frame_a.r_0[2];
//   pendulum.pendulum.r_0[3] = pendulum.pendulum.frame_a.r_0[3];
//   pendulum.pendulum.v_0[1] = der(pendulum.pendulum.r_0[1]);
//   pendulum.pendulum.v_0[2] = der(pendulum.pendulum.r_0[2]);
//   pendulum.pendulum.v_0[3] = der(pendulum.pendulum.r_0[3]);
//   pendulum.pendulum.a_0[1] = der(pendulum.pendulum.v_0[1]);
//   pendulum.pendulum.a_0[2] = der(pendulum.pendulum.v_0[2]);
//   pendulum.pendulum.a_0[3] = der(pendulum.pendulum.v_0[3]);
//   assert(pendulum.pendulum.innerDiameter < pendulum.pendulum.diameter, "parameter innerDiameter is greater than parameter diameter");
//   pendulum.revolute.cylinderColor = {255, 0, 0};
//   pendulum.revolute.fixed.flange.phi = pendulum.revolute.fixed.phi0;
//   pendulum.revolute.internalAxis.flange.tau = pendulum.revolute.internalAxis.tau;
//   pendulum.revolute.internalAxis.flange.phi = pendulum.revolute.internalAxis.phi;
//   pendulum.revolute.cylinder.r = {pendulum.revolute.frame_a.r_0[1], pendulum.revolute.frame_a.r_0[2], pendulum.revolute.frame_a.r_0[3]};
//   pendulum.revolute.cylinder.r_shape = {(-0.5) * pendulum.revolute.e[1] * pendulum.revolute.cylinderLength, (-0.5) * pendulum.revolute.e[2] * pendulum.revolute.cylinderLength, (-0.5) * pendulum.revolute.e[3] * pendulum.revolute.cylinderLength};
//   pendulum.revolute.cylinder.lengthDirection = {pendulum.revolute.e[1], pendulum.revolute.e[2], pendulum.revolute.e[3]};
//   pendulum.revolute.cylinder.widthDirection = {0.0, 1.0, 0.0};
//   pendulum.revolute.cylinder.color = {/*Real*/(pendulum.revolute.cylinderColor[1]), /*Real*/(pendulum.revolute.cylinderColor[2]), /*Real*/(pendulum.revolute.cylinderColor[3])};
//   pendulum.revolute.constantTorque.tau = -pendulum.revolute.constantTorque.flange.tau;
//   pendulum.revolute.constantTorque.tau = pendulum.revolute.constantTorque.tau_constant;
//   pendulum.revolute.constantTorque.phi = pendulum.revolute.constantTorque.flange.phi - pendulum.revolute.constantTorque.phi_support;
//   pendulum.revolute.constantTorque.phi_support = 0.0;
//   pendulum.revolute.angle = pendulum.revolute.phi;
//   pendulum.revolute.w = der(pendulum.revolute.phi);
//   pendulum.revolute.a = der(pendulum.revolute.w);
//   pendulum.revolute.frame_b.r_0[1] = pendulum.revolute.frame_a.r_0[1];
//   pendulum.revolute.frame_b.r_0[2] = pendulum.revolute.frame_a.r_0[2];
//   pendulum.revolute.frame_b.r_0[3] = pendulum.revolute.frame_a.r_0[3];
//   pendulum.revolute.R_rel = Modelica.Mechanics.MultiBody.Frames.planarRotation({pendulum.revolute.e[1], pendulum.revolute.e[2], pendulum.revolute.e[3]}, pendulum.revolute.phi, pendulum.revolute.w);
//   pendulum.revolute.frame_b.R = Modelica.Mechanics.MultiBody.Frames.absoluteRotation(pendulum.revolute.frame_a.R, pendulum.revolute.R_rel);
//   pendulum.revolute.frame_a.f = -Modelica.Mechanics.MultiBody.Frames.resolve1(pendulum.revolute.R_rel, {pendulum.revolute.frame_b.f[1], pendulum.revolute.frame_b.f[2], pendulum.revolute.frame_b.f[3]});
//   pendulum.revolute.frame_a.t = -Modelica.Mechanics.MultiBody.Frames.resolve1(pendulum.revolute.R_rel, {pendulum.revolute.frame_b.t[1], pendulum.revolute.frame_b.t[2], pendulum.revolute.frame_b.t[3]});
//   pendulum.revolute.tau = (-pendulum.revolute.frame_b.t[3]) * pendulum.revolute.e[3] - pendulum.revolute.frame_b.t[1] * pendulum.revolute.e[1] - pendulum.revolute.frame_b.t[2] * pendulum.revolute.e[2];
//   pendulum.revolute.phi = pendulum.revolute.internalAxis.phi;
//   pendulum.world.frame_b.t[1] + pendulum.revolute.frame_a.t[1] = 0.0;
//   pendulum.world.frame_b.t[2] + pendulum.revolute.frame_a.t[2] = 0.0;
//   pendulum.world.frame_b.t[3] + pendulum.revolute.frame_a.t[3] = 0.0;
//   pendulum.world.frame_b.f[1] + pendulum.revolute.frame_a.f[1] = 0.0;
//   pendulum.world.frame_b.f[2] + pendulum.revolute.frame_a.f[2] = 0.0;
//   pendulum.world.frame_b.f[3] + pendulum.revolute.frame_a.f[3] = 0.0;
//   pendulum.pendulum.frame_a.t[1] + pendulum.revolute.frame_b.t[1] = 0.0;
//   pendulum.pendulum.frame_a.t[2] + pendulum.revolute.frame_b.t[2] = 0.0;
//   pendulum.pendulum.frame_a.t[3] + pendulum.revolute.frame_b.t[3] = 0.0;
//   pendulum.pendulum.frame_a.f[1] + pendulum.revolute.frame_b.f[1] = 0.0;
//   pendulum.pendulum.frame_a.f[2] + pendulum.revolute.frame_b.f[2] = 0.0;
//   pendulum.pendulum.frame_a.f[3] + pendulum.revolute.frame_b.f[3] = 0.0;
//   pendulum.pendulum.frame_b.t[1] = 0.0;
//   pendulum.pendulum.frame_b.t[2] = 0.0;
//   pendulum.pendulum.frame_b.t[3] = 0.0;
//   pendulum.pendulum.frame_b.f[1] = 0.0;
//   pendulum.pendulum.frame_b.f[2] = 0.0;
//   pendulum.pendulum.frame_b.f[3] = 0.0;
//   (-pendulum.pendulum.frame_a.t[1]) + pendulum.pendulum.frameTranslation.frame_a.t[1] + pendulum.pendulum.body.frame_a.t[1] = 0.0;
//   (-pendulum.pendulum.frame_a.t[2]) + pendulum.pendulum.frameTranslation.frame_a.t[2] + pendulum.pendulum.body.frame_a.t[2] = 0.0;
//   (-pendulum.pendulum.frame_a.t[3]) + pendulum.pendulum.frameTranslation.frame_a.t[3] + pendulum.pendulum.body.frame_a.t[3] = 0.0;
//   (-pendulum.pendulum.frame_a.f[1]) + pendulum.pendulum.frameTranslation.frame_a.f[1] + pendulum.pendulum.body.frame_a.f[1] = 0.0;
//   (-pendulum.pendulum.frame_a.f[2]) + pendulum.pendulum.frameTranslation.frame_a.f[2] + pendulum.pendulum.body.frame_a.f[2] = 0.0;
//   (-pendulum.pendulum.frame_a.f[3]) + pendulum.pendulum.frameTranslation.frame_a.f[3] + pendulum.pendulum.body.frame_a.f[3] = 0.0;
//   (-pendulum.pendulum.frame_b.t[1]) + pendulum.pendulum.frameTranslation.frame_b.t[1] = 0.0;
//   (-pendulum.pendulum.frame_b.t[2]) + pendulum.pendulum.frameTranslation.frame_b.t[2] = 0.0;
//   (-pendulum.pendulum.frame_b.t[3]) + pendulum.pendulum.frameTranslation.frame_b.t[3] = 0.0;
//   (-pendulum.pendulum.frame_b.f[1]) + pendulum.pendulum.frameTranslation.frame_b.f[1] = 0.0;
//   (-pendulum.pendulum.frame_b.f[2]) + pendulum.pendulum.frameTranslation.frame_b.f[2] = 0.0;
//   (-pendulum.pendulum.frame_b.f[3]) + pendulum.pendulum.frameTranslation.frame_b.f[3] = 0.0;
//   pendulum.pendulum.body.frame_a.R.T[1,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,1];
//   pendulum.pendulum.body.frame_a.R.T[1,1] = pendulum.pendulum.frame_a.R.T[1,1];
//   pendulum.pendulum.body.frame_a.R.T[1,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,2];
//   pendulum.pendulum.body.frame_a.R.T[1,2] = pendulum.pendulum.frame_a.R.T[1,2];
//   pendulum.pendulum.body.frame_a.R.T[1,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[1,3];
//   pendulum.pendulum.body.frame_a.R.T[1,3] = pendulum.pendulum.frame_a.R.T[1,3];
//   pendulum.pendulum.body.frame_a.R.T[2,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,1];
//   pendulum.pendulum.body.frame_a.R.T[2,1] = pendulum.pendulum.frame_a.R.T[2,1];
//   pendulum.pendulum.body.frame_a.R.T[2,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,2];
//   pendulum.pendulum.body.frame_a.R.T[2,2] = pendulum.pendulum.frame_a.R.T[2,2];
//   pendulum.pendulum.body.frame_a.R.T[2,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[2,3];
//   pendulum.pendulum.body.frame_a.R.T[2,3] = pendulum.pendulum.frame_a.R.T[2,3];
//   pendulum.pendulum.body.frame_a.R.T[3,1] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,1];
//   pendulum.pendulum.body.frame_a.R.T[3,1] = pendulum.pendulum.frame_a.R.T[3,1];
//   pendulum.pendulum.body.frame_a.R.T[3,2] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,2];
//   pendulum.pendulum.body.frame_a.R.T[3,2] = pendulum.pendulum.frame_a.R.T[3,2];
//   pendulum.pendulum.body.frame_a.R.T[3,3] = pendulum.pendulum.frameTranslation.frame_a.R.T[3,3];
//   pendulum.pendulum.body.frame_a.R.T[3,3] = pendulum.pendulum.frame_a.R.T[3,3];
//   pendulum.pendulum.body.frame_a.R.w[1] = pendulum.pendulum.frameTranslation.frame_a.R.w[1];
//   pendulum.pendulum.body.frame_a.R.w[1] = pendulum.pendulum.frame_a.R.w[1];
//   pendulum.pendulum.body.frame_a.R.w[2] = pendulum.pendulum.frameTranslation.frame_a.R.w[2];
//   pendulum.pendulum.body.frame_a.R.w[2] = pendulum.pendulum.frame_a.R.w[2];
//   pendulum.pendulum.body.frame_a.R.w[3] = pendulum.pendulum.frameTranslation.frame_a.R.w[3];
//   pendulum.pendulum.body.frame_a.R.w[3] = pendulum.pendulum.frame_a.R.w[3];
//   pendulum.pendulum.body.frame_a.r_0[1] = pendulum.pendulum.frameTranslation.frame_a.r_0[1];
//   pendulum.pendulum.body.frame_a.r_0[1] = pendulum.pendulum.frame_a.r_0[1];
//   pendulum.pendulum.body.frame_a.r_0[2] = pendulum.pendulum.frameTranslation.frame_a.r_0[2];
//   pendulum.pendulum.body.frame_a.r_0[2] = pendulum.pendulum.frame_a.r_0[2];
//   pendulum.pendulum.body.frame_a.r_0[3] = pendulum.pendulum.frameTranslation.frame_a.r_0[3];
//   pendulum.pendulum.body.frame_a.r_0[3] = pendulum.pendulum.frame_a.r_0[3];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[1,1] = pendulum.pendulum.frame_b.R.T[1,1];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[1,2] = pendulum.pendulum.frame_b.R.T[1,2];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[1,3] = pendulum.pendulum.frame_b.R.T[1,3];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[2,1] = pendulum.pendulum.frame_b.R.T[2,1];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[2,2] = pendulum.pendulum.frame_b.R.T[2,2];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[2,3] = pendulum.pendulum.frame_b.R.T[2,3];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[3,1] = pendulum.pendulum.frame_b.R.T[3,1];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[3,2] = pendulum.pendulum.frame_b.R.T[3,2];
//   pendulum.pendulum.frameTranslation.frame_b.R.T[3,3] = pendulum.pendulum.frame_b.R.T[3,3];
//   pendulum.pendulum.frameTranslation.frame_b.R.w[1] = pendulum.pendulum.frame_b.R.w[1];
//   pendulum.pendulum.frameTranslation.frame_b.R.w[2] = pendulum.pendulum.frame_b.R.w[2];
//   pendulum.pendulum.frameTranslation.frame_b.R.w[3] = pendulum.pendulum.frame_b.R.w[3];
//   pendulum.pendulum.frameTranslation.frame_b.r_0[1] = pendulum.pendulum.frame_b.r_0[1];
//   pendulum.pendulum.frameTranslation.frame_b.r_0[2] = pendulum.pendulum.frame_b.r_0[2];
//   pendulum.pendulum.frameTranslation.frame_b.r_0[3] = pendulum.pendulum.frame_b.r_0[3];
//   pendulum.revolute.fixed.flange.tau = 0.0;
//   pendulum.revolute.constantTorque.flange.tau + pendulum.revolute.internalAxis.flange.tau = 0.0;
//   pendulum.revolute.constantTorque.flange.phi = pendulum.revolute.internalAxis.flange.phi;
//   pendulum.pendulum.frame_a.R.T[1,1] = pendulum.revolute.frame_b.R.T[1,1];
//   pendulum.pendulum.frame_a.R.T[1,2] = pendulum.revolute.frame_b.R.T[1,2];
//   pendulum.pendulum.frame_a.R.T[1,3] = pendulum.revolute.frame_b.R.T[1,3];
//   pendulum.pendulum.frame_a.R.T[2,1] = pendulum.revolute.frame_b.R.T[2,1];
//   pendulum.pendulum.frame_a.R.T[2,2] = pendulum.revolute.frame_b.R.T[2,2];
//   pendulum.pendulum.frame_a.R.T[2,3] = pendulum.revolute.frame_b.R.T[2,3];
//   pendulum.pendulum.frame_a.R.T[3,1] = pendulum.revolute.frame_b.R.T[3,1];
//   pendulum.pendulum.frame_a.R.T[3,2] = pendulum.revolute.frame_b.R.T[3,2];
//   pendulum.pendulum.frame_a.R.T[3,3] = pendulum.revolute.frame_b.R.T[3,3];
//   pendulum.pendulum.frame_a.R.w[1] = pendulum.revolute.frame_b.R.w[1];
//   pendulum.pendulum.frame_a.R.w[2] = pendulum.revolute.frame_b.R.w[2];
//   pendulum.pendulum.frame_a.R.w[3] = pendulum.revolute.frame_b.R.w[3];
//   pendulum.pendulum.frame_a.r_0[1] = pendulum.revolute.frame_b.r_0[1];
//   pendulum.pendulum.frame_a.r_0[2] = pendulum.revolute.frame_b.r_0[2];
//   pendulum.pendulum.frame_a.r_0[3] = pendulum.revolute.frame_b.r_0[3];
//   pendulum.revolute.frame_a.R.T[1,1] = pendulum.world.frame_b.R.T[1,1];
//   pendulum.revolute.frame_a.R.T[1,2] = pendulum.world.frame_b.R.T[1,2];
//   pendulum.revolute.frame_a.R.T[1,3] = pendulum.world.frame_b.R.T[1,3];
//   pendulum.revolute.frame_a.R.T[2,1] = pendulum.world.frame_b.R.T[2,1];
//   pendulum.revolute.frame_a.R.T[2,2] = pendulum.world.frame_b.R.T[2,2];
//   pendulum.revolute.frame_a.R.T[2,3] = pendulum.world.frame_b.R.T[2,3];
//   pendulum.revolute.frame_a.R.T[3,1] = pendulum.world.frame_b.R.T[3,1];
//   pendulum.revolute.frame_a.R.T[3,2] = pendulum.world.frame_b.R.T[3,2];
//   pendulum.revolute.frame_a.R.T[3,3] = pendulum.world.frame_b.R.T[3,3];
//   pendulum.revolute.frame_a.R.w[1] = pendulum.world.frame_b.R.w[1];
//   pendulum.revolute.frame_a.R.w[2] = pendulum.world.frame_b.R.w[2];
//   pendulum.revolute.frame_a.R.w[3] = pendulum.world.frame_b.R.w[3];
//   pendulum.revolute.frame_a.r_0[1] = pendulum.world.frame_b.r_0[1];
//   pendulum.revolute.frame_a.r_0[2] = pendulum.world.frame_b.r_0[2];
//   pendulum.revolute.frame_a.r_0[3] = pendulum.world.frame_b.r_0[3];
// end InnerOuterSamePrefix;
// endResult

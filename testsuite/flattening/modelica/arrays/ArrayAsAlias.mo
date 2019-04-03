// name:     ArrayAsAlias
// keywords: testing that array as alias and enumeration functionality works properly
// status:   correct
//
// Array as alias checks, enumeration checks, etc.


package Modelica

package Icons
  type TypeReal "Icon for a Real type"
      extends Real;
      annotation(X=Y);
  end TypeReal;

  type TypeInteger "Icon for an Integer type"
      extends Integer;
  end TypeInteger;

  type TypeString = String;
end Icons;

package SIunits
  type Length = Real (final quantity="Length", final unit="m");
  type PathLength = Length;
  type Position = Length;
  type Distance = Length (min=0);
  type Diameter = Length(min=0);
  type AngularVelocity_rpm = Real (final quantity="AngularVelocity", final unit="1/min");
  type AngularVelocity = Real (final quantity="AngularVelocity", final unit="rad/s");
  type Force = Real (final quantity="Force", final unit="N");
  type Torque = Real (final quantity="Torque", final unit="N.m");
  type AngularAcceleration = Real (final quantity="AngularAcceleration", final unit="rad/s2");
  type Velocity = Real (final quantity="Velocity", final unit="m/s");
  type Acceleration = Real (final quantity="Acceleration", final unit="m/s2");
end SIunits;

package Mechanics
  package MultiBody

    package Types
      type Axis = Modelica.Icons.TypeReal[3](each final unit="1");
      type Color = Modelica.Icons.TypeInteger[3] (each min=0, each max=255);
      type AxisLabel = Modelica.Icons.TypeString;

      package Defaults
        // Color defaults
        constant Types.Color BodyColor={0,128,255}   "Default color for body shapes that have mass (light blue)";
        constant Types.Color RodColor={155,155,155}  "Default color for massless rod shapes (grey)";
        constant Types.Color JointColor={255,0,0}    "Default color for elementary joints (red)";
        constant Types.Color ForceColor={0,128,0}    "Default color for force arrow (dark green)";
        constant Types.Color TorqueColor={0,128,0}   "Default color for torque arrow (dark green)";
        constant Types.Color SpringColor={0,0,255}   "Default color for a spring (blue)";
        constant Types.Color SensorColor={255,255,0} "Default color for sensors (yellow)";
        constant Types.Color FrameColor={0,0,0}      "Default color for frame axes and labels (black)";
        constant Types.Color ArrowColor={0,0,255}    "Default color for arrows and double arrows (blue)";
        // Arrow and frame defaults
        constant Real FrameHeadLengthFraction=5.0 "Frame arrow head length / arrow diameter";
        constant Real FrameHeadWidthFraction=3.0 "Frame arrow head width / arrow diameter";
        constant Real FrameLabelHeightFraction=3.0 "Height of frame label / arrow diameter";
        constant Real ArrowHeadLengthFraction=4.0 "Arrow head length / arrow diameter";
        constant Real ArrowHeadWidthFraction=3.0 "Arrow head width / arrow diameter";
      end Defaults;
      type GravityTypes = enumeration(
                             NoGravity "No gravity field",
                             UniformGravity "Uniform gravity field",
                             PointGravity "Point gravity field")
                             "Enumeration defining the type of the gravity field";
    end Types;

  model World
    "World coordinate system + gravity field + default animation definition"

    import SI = Modelica.SIunits;
    import Modelica.Mechanics.MultiBody.Types.GravityTypes;
    import Modelica.Mechanics.MultiBody.Types;

    parameter Boolean enableAnimation=true
    "= true, if animation of all components is enabled";
    parameter Boolean animateWorld=true
    "= true, if world coordinate system shall be visualized" annotation(Dialog(enable=enableAnimation));
    parameter Boolean animateGravity=true
    "= true, if gravity field shall be visualized (acceleration vector or field center)"
                                                annotation(Dialog(enable=enableAnimation));
    parameter Types.AxisLabel label1="x" "Label of horizontal axis in icon";
    parameter Types.AxisLabel label2="y" "Label of vertical axis in icon";
    parameter Types.GravityTypes gravityType=GravityTypes.UniformGravity
    "Type of gravity field"                                                                                                     annotation (Evaluate=true);
    parameter SI.Acceleration g=9.81 "Constant gravity acceleration"
    annotation (Dialog(enable=gravityType == GravityTypes.UniformGravity));
    parameter Types.Axis n={0,-1,0}
    "Direction of gravity resolved in world frame (gravity = g*n/length(n))"
    annotation (Evaluate=true, Dialog(enable=gravityType == Modelica.Mechanics.
        MultiBody.Types.GravityTypes.UniformGravity));
    parameter Real mue(
    unit="m3/s2",
    min=0) = 3.986e14
    "Gravity field constant (default = field constant of earth)"
    annotation (Dialog(enable=gravityType == Types.GravityTypes.PointGravity));
    parameter Boolean driveTrainMechanics3D=true
    "= true, if 3-dim. mechanical effects of Parts.Mounting1D/Rotor1D/BevelGear1D shall be taken into account";

    parameter SI.Distance axisLength=nominalLength/2
    "Length of world axes arrows"
    annotation (Dialog(tab="Animation", group="if animateWorld = true", enable=enableAnimation and animateWorld));
    parameter SI.Distance axisDiameter=axisLength/defaultFrameDiameterFraction
    "Diameter of world axes arrows"
    annotation (Dialog(tab="Animation", group="if animateWorld = true", enable=enableAnimation and animateWorld));
    parameter Boolean axisShowLabels=true "= true, if labels shall be shown"
    annotation (Dialog(tab="Animation", group="if animateWorld = true", enable=enableAnimation and animateWorld));
    input Types.Color axisColor_x=Modelica.Mechanics.MultiBody.Types.Defaults.FrameColor
    "Color of x-arrow"
    annotation (Dialog(tab="Animation", group="if animateWorld = true", enable=enableAnimation and animateWorld));
    input Types.Color axisColor_y=axisColor_x
    annotation (Dialog(tab="Animation", group="if animateWorld = true", enable=enableAnimation and animateWorld));
    input Types.Color axisColor_z=axisColor_x "Color of z-arrow"
    annotation (Dialog(tab="Animation", group="if animateWorld = true", enable=enableAnimation and animateWorld));

    parameter SI.Position gravityArrowTail[3]={0,0,0}
    "Position vector from origin of world frame to arrow tail, resolved in world frame"
    annotation (Dialog(tab="Animation", group=
        "if animateGravity = true and gravityType = UniformGravity",
        enable=enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity));
    parameter SI.Length gravityArrowLength=axisLength/2 "Length of gravity arrow"
    annotation (Dialog(tab="Animation", group=
        "if animateGravity = true and gravityType = UniformGravity",
        enable=enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity));
    parameter SI.Diameter gravityArrowDiameter=gravityArrowLength/
      defaultWidthFraction "Diameter of gravity arrow" annotation (Dialog(tab=
        "Animation", group=
        "if animateGravity = true and gravityType = UniformGravity",
        enable=enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity));
    input Types.Color gravityArrowColor={0,230,0} "Color of gravity arrow"
    annotation (Dialog(tab="Animation", group=
        "if animateGravity = true and gravityType = UniformGravity",
        enable=enableAnimation and animateGravity and gravityType == GravityTypes.UniformGravity));
    parameter SI.Diameter gravitySphereDiameter=12742000
    "Diameter of sphere representing gravity center (default = mean diameter of earth)"
    annotation (Dialog(tab="Animation", group=
        "if animateGravity = true and gravityType = PointGravity",
        enable=enableAnimation and animateGravity and gravityType == GravityTypes.PointGravity));
    input Types.Color gravitySphereColor={0,230,0} "Color of gravity sphere"
    annotation (Dialog(tab="Animation", group=
        "if animateGravity = true and gravityType = PointGravity",
        enable=enableAnimation and animateGravity and gravityType == GravityTypes.PointGravity));

    parameter SI.Length nominalLength=1 "\"Nominal\" length of multi-body system"
    annotation (Dialog(tab="Defaults"));
    parameter SI.Length defaultAxisLength=nominalLength/5
    "Default for length of a frame axis (but not world frame)"
    annotation (Dialog(tab="Defaults"));
    parameter SI.Length defaultJointLength=nominalLength/10
    "Default for the fixed length of a shape representing a joint"
    annotation (Dialog(tab="Defaults"));
    parameter SI.Length defaultJointWidth=nominalLength/20
    "Default for the fixed width of a shape representing a joint"
    annotation (Dialog(tab="Defaults"));
    parameter SI.Length defaultForceLength=nominalLength/10
    "Default for the fixed length of a shape representing a force (e.g. damper)"
    annotation (Dialog(tab="Defaults"));
    parameter SI.Length defaultForceWidth=nominalLength/20
    "Default for the fixed width of a shape represening a force (e.g. spring, bushing)"
    annotation (Dialog(tab="Defaults"));
    parameter SI.Length defaultBodyDiameter=nominalLength/9
    "Default for diameter of sphere representing the center of mass of a body"
    annotation (Dialog(tab="Defaults"));
    parameter Real defaultWidthFraction=20
    "Default for shape width as a fraction of shape length (e.g., for Parts.FixedTranslation)"
    annotation (Dialog(tab="Defaults"));
    parameter SI.Length defaultArrowDiameter=nominalLength/40
    "Default for arrow diameter (e.g., of forces, torques, sensors)"
    annotation (Dialog(tab="Defaults"));
    parameter Real defaultFrameDiameterFraction=40
    "Default for arrow diameter of a coordinate system as a fraction of axis length"
    annotation (Dialog(tab="Defaults"));
    parameter Real defaultSpecularCoefficient(min=0) = 0.7
    "Default reflection of ambient light (= 0: light is completely absorbed)"
    annotation (Dialog(tab="Defaults"));
    parameter Real defaultN_to_m(unit="N/m", min=0) = 1000
    "Default scaling of force arrows (length = force/defaultN_to_m)"
    annotation (Dialog(tab="Defaults"));
    parameter Real defaultNm_to_m(unit="N.m/m", min=0) = 1000
    "Default scaling of torque arrows (length = torque/defaultNm_to_m)"
    annotation (Dialog(tab="Defaults"));
   end World;
 end MultiBody;
end Mechanics;

end Modelica;


model ArrayAsAlias
 Modelica.Mechanics.MultiBody.World w;
end ArrayAsAlias;


// Result:
// class ArrayAsAlias
//   parameter Boolean w.enableAnimation = true "= true, if animation of all components is enabled";
//   parameter Boolean w.animateWorld = true "= true, if world coordinate system shall be visualized";
//   parameter Boolean w.animateGravity = true "= true, if gravity field shall be visualized (acceleration vector or field center)";
//   parameter String w.label1 = "x" "Label of horizontal axis in icon";
//   parameter String w.label2 = "y" "Label of vertical axis in icon";
//   parameter enumeration(NoGravity, UniformGravity, PointGravity) w.gravityType = Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity "Type of gravity field";
//   parameter Real w.g(quantity = "Acceleration", unit = "m/s2") = 9.81 "Constant gravity acceleration";
//   parameter Real w.n[1](unit = "1") = 0.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real w.n[2](unit = "1") = -1.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real w.n[3](unit = "1") = 0.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real w.mue(unit = "m3/s2", min = 0.0) = 398600000000000.0 "Gravity field constant (default = field constant of earth)";
//   parameter Boolean w.driveTrainMechanics3D = true "= true, if 3-dim. mechanical effects of Parts.Mounting1D/Rotor1D/BevelGear1D shall be taken into account";
//   parameter Real w.axisLength(quantity = "Length", unit = "m", min = 0.0) = 0.5 * w.nominalLength "Length of world axes arrows";
//   parameter Real w.axisDiameter(quantity = "Length", unit = "m", min = 0.0) = w.axisLength / w.defaultFrameDiameterFraction "Diameter of world axes arrows";
//   parameter Boolean w.axisShowLabels = true "= true, if labels shall be shown";
//   Integer w.axisColor_x[1](min = 0, max = 255) "Color of x-arrow";
//   Integer w.axisColor_x[2](min = 0, max = 255) "Color of x-arrow";
//   Integer w.axisColor_x[3](min = 0, max = 255) "Color of x-arrow";
//   Integer w.axisColor_y[1](min = 0, max = 255);
//   Integer w.axisColor_y[2](min = 0, max = 255);
//   Integer w.axisColor_y[3](min = 0, max = 255);
//   Integer w.axisColor_z[1](min = 0, max = 255) "Color of z-arrow";
//   Integer w.axisColor_z[2](min = 0, max = 255) "Color of z-arrow";
//   Integer w.axisColor_z[3](min = 0, max = 255) "Color of z-arrow";
//   parameter Real w.gravityArrowTail[1](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   parameter Real w.gravityArrowTail[2](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   parameter Real w.gravityArrowTail[3](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   parameter Real w.gravityArrowLength(quantity = "Length", unit = "m") = 0.5 * w.axisLength "Length of gravity arrow";
//   parameter Real w.gravityArrowDiameter(quantity = "Length", unit = "m", min = 0.0) = w.gravityArrowLength / w.defaultWidthFraction "Diameter of gravity arrow";
//   Integer w.gravityArrowColor[1](min = 0, max = 255) "Color of gravity arrow";
//   Integer w.gravityArrowColor[2](min = 0, max = 255) "Color of gravity arrow";
//   Integer w.gravityArrowColor[3](min = 0, max = 255) "Color of gravity arrow";
//   parameter Real w.gravitySphereDiameter(quantity = "Length", unit = "m", min = 0.0) = 12742000.0 "Diameter of sphere representing gravity center (default = mean diameter of earth)";
//   Integer w.gravitySphereColor[1](min = 0, max = 255) "Color of gravity sphere";
//   Integer w.gravitySphereColor[2](min = 0, max = 255) "Color of gravity sphere";
//   Integer w.gravitySphereColor[3](min = 0, max = 255) "Color of gravity sphere";
//   parameter Real w.nominalLength(quantity = "Length", unit = "m") = 1.0 "\"Nominal\" length of multi-body system";
//   parameter Real w.defaultAxisLength(quantity = "Length", unit = "m") = 0.2 * w.nominalLength "Default for length of a frame axis (but not world frame)";
//   parameter Real w.defaultJointLength(quantity = "Length", unit = "m") = 0.1 * w.nominalLength "Default for the fixed length of a shape representing a joint";
//   parameter Real w.defaultJointWidth(quantity = "Length", unit = "m") = 0.05 * w.nominalLength "Default for the fixed width of a shape representing a joint";
//   parameter Real w.defaultForceLength(quantity = "Length", unit = "m") = 0.1 * w.nominalLength "Default for the fixed length of a shape representing a force (e.g. damper)";
//   parameter Real w.defaultForceWidth(quantity = "Length", unit = "m") = 0.05 * w.nominalLength "Default for the fixed width of a shape represening a force (e.g. spring, bushing)";
//   parameter Real w.defaultBodyDiameter(quantity = "Length", unit = "m") = 0.1111111111111111 * w.nominalLength "Default for diameter of sphere representing the center of mass of a body";
//   parameter Real w.defaultWidthFraction = 20.0 "Default for shape width as a fraction of shape length (e.g., for Parts.FixedTranslation)";
//   parameter Real w.defaultArrowDiameter(quantity = "Length", unit = "m") = 0.025 * w.nominalLength "Default for arrow diameter (e.g., of forces, torques, sensors)";
//   parameter Real w.defaultFrameDiameterFraction = 40.0 "Default for arrow diameter of a coordinate system as a fraction of axis length";
//   parameter Real w.defaultSpecularCoefficient(min = 0.0) = 0.7 "Default reflection of ambient light (= 0: light is completely absorbed)";
//   parameter Real w.defaultN_to_m(unit = "N/m", min = 0.0) = 1000.0 "Default scaling of force arrows (length = force/defaultN_to_m)";
//   parameter Real w.defaultNm_to_m(unit = "N.m/m", min = 0.0) = 1000.0 "Default scaling of torque arrows (length = torque/defaultNm_to_m)";
// equation
//   w.axisColor_x = {0, 0, 0};
//   w.axisColor_y = {w.axisColor_x[1], w.axisColor_x[2], w.axisColor_x[3]};
//   w.axisColor_z = {w.axisColor_x[1], w.axisColor_x[2], w.axisColor_x[3]};
//   w.gravityArrowColor = {0, 230, 0};
//   w.gravitySphereColor = {0, 230, 0};
// end ArrayAsAlias;
// endResult

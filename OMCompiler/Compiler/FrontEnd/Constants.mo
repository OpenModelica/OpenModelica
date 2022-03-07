/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Constants
" file:        Constants.mo
  package:     Constants
  description: definition of a set of constants


  Constants defined in here (Constants.mo) are used in Interactive.mo"

// ************************ Modelica 1.x Annotations! *********************** //
public constant String annotationsModelica_1_x = "

package GraphicalAnnotationsProgram____ end GraphicalAnnotationsProgram____;

// Not implemented yet!
";

// ************************ Modelica 2.x Annotations! *********************** //
public constant String annotationsModelica_2_x = "

package GraphicalAnnotationsProgram____  end GraphicalAnnotationsProgram____;

// Constants.diagramProgram:
record GraphicItem
  Boolean visible=true;
end GraphicItem;

record CoordinateSystem
  Real extent[2,2];
end CoordinateSystem;

record Diagram
  CoordinateSystem coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}});
end Diagram;

type LinePattern= enumeration(None, Solid, Dash, Dot, DashDot, DashDotDot );
type Arrow= enumeration(None, Open, Filled , Half );
type FillPattern= enumeration(None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere );
type BorderPattern= enumeration(None, Raised, Sunken, Engraved );
type TextStyle= enumeration(Bold, Italic, Underline );

record Line
  Boolean visible=true;
  Real points[:,2];
  Integer color[3]={0,0,0};
  LinePattern pattern=LinePattern.Solid;
  Real thickness=0.25;
  Arrow arrow[2]={Arrow.None,Arrow.None};
  Real arrowSize=3.0;
  Boolean smooth=false;
end Line;

record Polygon
  Boolean visible=true;
  Integer lineColor[3]={0,0,0};
  Integer fillColor[3]={0,0,0};
  LinePattern pattern=LinePattern.Solid;
  FillPattern fillPattern=FillPattern.None;
  Real lineThickness=0.25;
  Real points[:,2];
  Boolean smooth=false;
end Polygon;

record Rectangle
  Boolean visible=true;
  Integer lineColor[3]={0,0,0};
  Integer fillColor[3]={0,0,0};
  LinePattern pattern=LinePattern.Solid;
  FillPattern fillPattern=FillPattern.None;
  Real lineThickness=0.25;
  BorderPattern borderPattern=BorderPattern.None;
  Real extent[2,2];
  Real radius=0.0;
end Rectangle;

record Ellipse
  Boolean visible=true;
  Integer lineColor[3]={0,0,0};
  Integer fillColor[3]={0,0,0};
  LinePattern pattern=LinePattern.Solid;
  FillPattern fillPattern=FillPattern.None;
  Real lineThickness=0.25;
  Real extent[2,2];
end Ellipse;

record Text
  Boolean visible=true;
  Integer lineColor[3]={0,0,0};
  Integer fillColor[3]={0,0,0};
  LinePattern pattern=LinePattern.Solid;
  FillPattern fillPattern=FillPattern.None;
  Real lineThickness=0.25;
  Real extent[2,2];
  String textString;
  Real fontSize=0.0;
  String fontName=\"\";
  TextStyle textStyle[:];
end Text;

record Bitmap
  Boolean visible=true;
  Real extent[2,2];
  String fileName=\"\";
  String imageSource=\"\";
end Bitmap;

// Constants.iconProgram:
record Icon
  CoordinateSystem coordinateSystem(extent={{-10.0,-10.0},{10.0,10.0}});
end Icon;

// Constants.graphicsProgram
// ...
// Constants.lineProgram
// ...

// Constants.placementProgram:
record Transformation
  Real x=0.0;
  Real y=0.0;
  Real scale=1.0;
  Real aspectRatio=1.0;
  Boolean flipHorizontal=false;
  Boolean flipVertical=false;
  Real rotation=0.0;
end Transformation;

record Placement
  Boolean visible=true;
  Transformation transformation;
  Transformation iconTransformation;
end Placement;

";

// ************************ Modelica 3.x Annotations! *********************** //
public constant String annotationsModelica_3_x = "

package GraphicalAnnotationsProgram____ end     GraphicalAnnotationsProgram____;

// type DrawingUnit = Real/*(final unit=\"mm\")*/;
// type Point = DrawingUnit[2] \"{x, y}\";
// type Extent = Point[2] \"Defines a rectangular area {{x1, y1}, {x2, y2}}\";

//partial
record GraphicItem
  Boolean visible = true;
  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};
  Real rotation(quantity=\"angle\", unit=\"deg\")=0;
end GraphicItem;

record CoordinateSystem
  Real extent[2,2]/*(each final unit=\"mm\")*/;
  Boolean preserveAspectRatio;
  Real initialScale;
  Real grid[2]/*(each final unit=\"mm\")*/;
end CoordinateSystem;

// example
// CoordinateSystem(extent = {{-10, -10}, {10, 10}});
// i.e. a coordinate system with width 20 units and height 20 units.

record Icon \"Representation of the icon layer\"
  CoordinateSystem coordinateSystem;
  //GraphicItem[:] graphics;
end Icon;

record Diagram \"Representation of the diagram layer\"
  CoordinateSystem coordinateSystem;
  //GraphicItem[:] graphics;
end Diagram;

type Color = Integer[3](each min=0, each max=255) \"RGB representation\";
// constant Color Black = {0, 0, 0}; // zeros(3);
type LinePattern = enumeration(None, Solid, Dash, Dot, DashDot, DashDotDot);
type FillPattern = enumeration(None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere);
type BorderPattern = enumeration(None, Raised, Sunken, Engraved);
type Smooth = enumeration(None, Bezier);
type EllipseClosure = enumeration(None, Chord, Radial); // added in Modelica 3.4

type Arrow = enumeration(None, Open, Filled, Half);
type TextStyle = enumeration(Bold, Italic, UnderLine);
type TextAlignment = enumeration(Left, Center, Right);

// Filled shapes have the following attributes for the border and interior.
record FilledShape \"Style attributes for filled shapes\"
  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";
  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";
  LinePattern pattern = LinePattern.Solid \"Border line pattern\";
  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";
  Real lineThickness = 0.25 \"Line thickness\";
end FilledShape;

record Transformation
  Real origin[2]/*(each final unit=\"mm\")*/;
  Real extent[2,2]/*(each final unit=\"mm\")*/;
  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/;
end Transformation;

record Placement
  Boolean visible = true;
  Transformation transformation \"Placement in the dagram layer\";
  Transformation iconTransformation \"Placement in the icon layer\";
end Placement;

record IconMap
  Real extent[2,2]/*(each final unit=\"mm\")*/ = {{0, 0}, {0, 0}};
  Boolean primitivesVisible = true;
end IconMap;

record DiagramMap
  Real extent[2,2]/*(each final unit=\"mm\")*/ = {{0, 0}, {0, 0}};
  Boolean primitivesVisible = true;
end DiagramMap;

record Line
  //extends GraphicItem;
  Boolean visible = true;
  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};
  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/ = 0;
  // end GraphicItem

  Real points[:, 2]/*(each final unit=\"mm\")*/;
  Integer color[3] = {0, 0, 0};
  LinePattern pattern = LinePattern.Solid;
  Real thickness/*(final unit=\"mm\")*/ = 0.25;
  Arrow arrow[2] = {Arrow.None, Arrow.None} \"{start arrow, end arrow}\";
  Real arrowSize/*(final unit=\"mm\")*/ = 3;
  Smooth smooth = Smooth.None \"Spline\";
end Line;

record Polygon
  //extends GraphicItem;
  Boolean visible = true;
  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};
  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/ = 0;
  // end GraphicItem

  //extends FilledShape;
  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";
  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";
  LinePattern pattern = LinePattern.Solid \"Border line pattern\";
  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";
  Real lineThickness = 0.25 \"Line thickness\";
  // end FilledShape

  Real points[:,2]/*(each final unit=\"mm\")*/;
  Smooth smooth = Smooth.None \"Spline outline\";
end Polygon;

record Rectangle
  //extends GraphicItem;
  Boolean visible = true;
  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};
  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/ = 0;
  // end GraphicItem

  //extends FilledShape;
  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";
  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";
  LinePattern pattern = LinePattern.Solid \"Border line pattern\";
  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";
  Real lineThickness = 0.25 \"Line thickness\";
  // end FilledShape

  BorderPattern borderPattern = BorderPattern.None;
  Real extent[2,2]/*(each final unit=\"mm\")*/;
  Real radius/*(final unit=\"mm\")*/ = 0 \"Corner radius\";
end Rectangle;

record Ellipse
  //extends GraphicItem;
  Boolean visible = true;
  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};
  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/=0;
  // end GraphicItem

  //extends FilledShape;
  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";
  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";
  LinePattern pattern = LinePattern.Solid \"Border line pattern\";
  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";
  Real lineThickness = 0.25 \"Line thickness\";
  // end FilledShape

  Real extent[2,2]/*(each final unit=\"mm\")*/;
  Real startAngle/*(quantity=\"angle\", unit=\"deg\")*/ = 0;
  Real endAngle/*(quantity=\"angle\", unit=\"deg\")*/ = 360;
  EllipseClosure closure = if startAngle == 0 and endAngle == 360 then EllipseClosure.Chord else EllipseClosure.Radial; // added in Modelica 3.4
end Ellipse;

record Text
  //extends GraphicItem;
  Boolean visible = true;
  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};
  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/ = 0;
  // end GraphicItem

  //extends FilledShape;
  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";
  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";
  LinePattern pattern = LinePattern.Solid \"Border line pattern\";
  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";
  Real lineThickness = 0.25 \"Line thickness\";
  // end FilledShape

  Real extent[2,2]/*(each final unit=\"mm\")*/ = {{-10, -10}, {10, 10}};
  String textString = \"\";
  Real fontSize = 0 \"unit pt\";
  Integer textColor[3] = {-1, -1, -1} \"defaults to fillColor\";
  String fontName = \"\";
  TextStyle textStyle[:] = fill(TextStyle.Bold, 0);
  TextAlignment horizontalAlignment = TextAlignment.Center;
end Text;

record Bitmap
  //extends GraphicItem;
  Boolean visible = true;
  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};
  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/=0;
  // end GraphicItem

  Real extent[2,2]/*(each final unit=\"mm\")*/;
  String fileName = \"\" \"Name of bitmap file\";
  String imageSource =  \"\" \"Base64 representation of bitmap\";
end Bitmap;

// dynamic annotations
// annotation (
//   Icon(graphics={Rectangle(
//     extent=DynamicSelect({{0,0},{20,20}},{{0,0},{20,level}}),
//     fillColor=DynamicSelect({0,0,255},
//     if overflow then {255,0,0} else {0,0,255}))}
//   );

// events & interaction
record OnMouseDownSetBoolean
   Boolean variable \"Name of variable to change when mouse button pressed\";
   Boolean value \"Assigned value\";
end OnMouseDownSetBoolean;

// interaction={OnMouseDown(on, true), OnMouseUp(on, false)};
record OnMouseMoveXSetReal
   Real xVariable \"Name of variable to change when cursor moved in x direction\";
   Real minValue;
   Real maxValue;
end OnMouseMoveXSetReal;

//
record OnMouseMoveYSetReal
   Real yVariable \"Name of variable to change when cursor moved in y direction\";
   Real minValue;
   Real maxValue;
end OnMouseMoveYSetReal;

record OnMouseDownEditInteger
   Integer variable \"Name of variable to change\";
end OnMouseDownEditInteger;

record OnMouseDownEditReal
   Real variable \"Name of variable to change\";
end OnMouseDownEditReal;

//
record OnMouseDownEditString
   String variable \"Name of variable to change\";
end OnMouseDownEditString;

//
// annotation(defaultComponentName = \"name\")
// annotation(missingInnerMessage = \"message\")
//
// model World
//   annotation(defaultComponentName = \"world\",
//   defaultComponentPrefixes = \"inner replaceable\",
//   missingInnerMessage = \"The World object is missing\");
// ...
// end World;
//
// inner replaceable World world;
//
// annotation(unassignedMessage = \"message\");
//
// annotation(Dialog(enable = parameter-expression, tab = \"tab\", group = \"group\"));
//

record Dialog
   parameter String tab = \"General\";
   parameter String group = \"Parameters\";
   parameter Boolean enable = true;
   parameter Boolean showStartAttribute = false;
   parameter Boolean colorSelector = false;
   parameter Selector loadSelector;
   parameter Selector saveSelector;
   parameter String groupImage = \"\";
   parameter Boolean connectorSizing = false;
end Dialog;

record Selector
  parameter String filter;
  parameter String caption;
end Selector;

// Annotations for Version Handling
record Version
  String version \"The version number of the released library.\";
  String versionDate \"The date in UTC format (according to ISO 8601) when the library was released.\";
  Integer versionBuild \"The optional build number of the library.\";
  String dateModified \"The UTC date and time (according to ISO 8601) of the last modification of the package.\";
  String revisionId \"A tool specific revision identifier possibly generated by a source code management system (e.g. Subversion or CVS).\";
end Version;

//record uses \"A list of dependent classes.\"
//end uses;

// Annotations for Access Control to Protect Intellectual Property
type Access = enumeration(hide, icon, documentation, diagram, nonPackageText, nonPackageDuplicate, packageText, packageDuplicate);

record Protection \"Protection of class\"
  Access access \"Defines what parts of a class are visible.\";
  String features[:] = fill(\"\", 0) \"Required license features\";
  record License
    String libraryKey;
    String licenseFile = \"\" \"Optional, default mapping if empty\";
  end License;
end Protection;

record Authorization
  String licensor = \"\" \"Optional string to show information about the licensor\";
  String libraryKey \"Matching the key in the class. Must be encrypted and not visible\";
  License license[:] \"Definition of the license options and of the access rights\";
end Authorization;

record License
  String licensee = \"\" \"Optional string to show information about the licensee\";
  String id[:] \"Unique machine identifications, e.g. MAC addresses\";
  String features[:] = fill(\"\", 0) \"Activated library license features\";
  String startDate = \"\" \"Optional start date in UTCformat YYYY-MM-DD\";
  String expirationDate = \"\" \"Optional expiration date in UTCformat YYYY-MM-DD\";
  String operations[:] = fill(\"\",0) \"Library usage conditions\";
end License;

// TODO: Function Derivative Annotations

// Inverse Function Annotation
//record inverse
//end inverse;

record choices
  Boolean checkBox = false;
  Boolean __Dymola_checkBox = false;
  String choice[:] = fill(\"\", 0) \"the choices as string\";
end choices;

//
// connector Frame \"Frame of a mechanical system\"
//   ...
//   flow Modelica.SIunits.Force f[3] annotation(unassignedMessage =
//    \"All Forces cannot be uniquely calculated. The reason could be that the
//      mechanism contains a planar loop or that joints constrain the same motion.
//      For planar loops, use in one revolute joint per loop the option
//      PlanarCutJoint=true in the Advanced menu.\");
// end Frame;
//
// model BodyShape
//   ...
//   parameter Boolean animation = true;
//   parameter SI.Length length \"Length of shape\"
//   annotation(Dialog(enable = animation, tab = \"Animation\",
//   group = \"Shape definition\"));
//   ...
// end BodyShape;

record Documentation
  String info = \"\" \"Description of the class\";
  String revisions = \"\" \"Revision history\";
  // Spec 3.5 Figure[:] figures = {}; \"Simulation result figures\";
end Documentation;
"
;


annotation(__OpenModelica_Interface="frontend");
end Constants;

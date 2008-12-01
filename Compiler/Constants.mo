/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package Constants
" file:	       Constants.mo
  package:     Constants
  description: definition of a set of constants

  RCS: $Id$

  Constants defined in here (Constants.mo) are used in Interactive.mo"

// ************************ Modelica 1.x Annotations! *********************** //
public constant String annotationsModelica_1_x = "
Not implemented yet!
";

// ************************ Modelica 2.x Annotations! *********************** //
public constant String annotationsModelica_2_x = "

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

type LinePattern= enumeration(None, Solid, Dash, Dot, DashDot, DashDot , DashDotDot );
type Arrow= enumeration(None, Open, Filled, Filled , Half );
type FillPattern= enumeration(None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, VerticalCylinder , Sphere );
type BorderPattern= enumeration(None, Raised, Sunken, Sunken , Engraved );
type TextStyle= enumeration(Bold, Italic, Italic , Underline );
  
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
record CoordinateSystem
  Real extent[2,2];
end CoordinateSystem;

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

// type DrawingUnit = Real(final unit=\"mm\");
// type Point = DrawingUnit[2] \"{x, y}\";
// type Extent = Point[2] \"Defines a rectangular area {{x1, y1}, {x2, y2}}\";

//partial 
record GraphicItem
  Boolean visible = true;
  Real origin[2](final unit=\"mm\") = {0.0, 0.0};
  Real rotation(quantity=\"angle\", unit=\"deg\")=0;
end GraphicItem;

record CoordinateSystem
  Real extent[2,2](final unit=\"mm\");
  Boolean preserveAspectRatio=true;
  Real initialScale = 0.1;
  Real grid[2];
end CoordinateSystem;


// example 
// CoordinateSystem(extent = {{-10, -10}, {10, 10}});
// i.e. a coordinate system with width 20 units and height 20 units.

record Icon \"Representation of the icon layer\"
  CoordinateSystem coordinateSystem(extent = {{-100, -100}, {100, 100}});
  GraphicItem[:] graphics;
end Icon;

record Diagram \"Representation of the diagram layer\"
  CoordinateSystem coordinateSystem(extent = {{-100, -100}, {100, 100}});
  GraphicItem[:] graphics;
end Diagram;

type Color = Integer[3](min=0, max=255) \"RGB representation\";
// constant Color Black = {0, 0, 0}; // zeros(3);
type LinePattern = enumeration(None, Solid, Dash, Dot, DashDot, DashDotDot);
type FillPattern = enumeration(None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere);
type BorderPattern = enumeration(None, Raised, Sunken, Engraved);
type Smooth = enumeration(None, Bezier);

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
  Real origin[2](final unit=\"mm\") = {0.0, 0.0};
  Extent extent;
  Real rotation(quantity=\"angle\", unit=\"deg\")=0;
end Transformation;

record Placement
  Boolean visible = true;
  Transformation transformation \"Placement in the dagram layer\";
  Transformation iconTransformation \"Placement in the icon layer\";
end Placement;

record IconMap
  Real extent[2,2](final unit=\"mm\") = {{0, 0}, {0, 0}};
  Boolean primitivesVisible = true;
end IconMap;

record DiagramMap
  Real extent[2,2](final unit=\"mm\") = {{0, 0}, {0, 0}};
  Boolean primitivesVisible = true;
end DiagramMap;

record Line
  extends GraphicItem;
  Real points[2,:](final unit=\"mm\");
  Integer color[3] = {0, 0, 0};
  LinePattern pattern = LinePattern.Solid;
  Real thickness(final unit=\"mm\") = 0.25;
  Arrow arrow[2] = {Arrow.None, Arrow.None} \"{start arrow, end arrow}\";
  Real arrowSize(final unit=\"mm\")=3;
  Smooth smooth = Smooth.None \"Spline\";
end Line;

record Polygon
  extends GraphicItem;
  extends FilledShape;
  Real points[2,:](final unit=\"mm\");
  Smooth smooth = Smooth.None \"Spline outline\";
end Polygon;

record Ellipse
  extends GraphicItem;
  extends FilledShape;
  Real extent[2,2](final unit=\"mm\");
  Real startAngle(quantity=\"angle\", unit=\"deg\")=0;
  Real endAngle(quantity=\"angle\", unit=\"deg\")=360;
end Ellipse;

record Text
  extends GraphicItem;
  extends FilledShape;
  Real extent[2,2](final unit=\"mm\");
  String textString;
  Real fontSize = 0 \"unit pt\";
  String fontName;
  TextStyle textStyle[:];
  TextAlignment horizontalAlignment = TextAlignment.Center;
end Text;

record Bitmap
  extends GraphicItem;
  Real extent[2,2](final unit=\"mm\");
  String fileName \"Name of bitmap file\";
  String imageSource \"Base64 representation of bitmap\";
end Bitmap;

// dynamic annotations
// annotation (
//   Icon(graphics={Rectangle(
//     extent=DynamicSelect({{0,0},{20,20}},{{0,0},{20,level}}),
//     fillColor=DynamicSelect({0,0,255},
//     if overflow then {255,0,0} else {0,0,255}))}
//   );

// events & interaction
// record OnMouseDownSetBoolean
//   Boolean variable \"Name of variable to change when mouse button pressed\";
//   Boolean value \"Assigned value\";
// end OnMouseDown;
// interaction={OnMouseDown(on, true), OnMouseUp(on, false)};
// record OnMouseMoveXSetReal
//   Real xVariable \"Name of variable to change when cursor moved in x direction\";
//   Real minValue;
//   Real maxValue;
// end OnMouseMoveXSetReal;
// 
// record OnMouseMoveYSetReal
//   Real yVariable \"Name of variable to change when cursor moved in y direction\";
//   Real minValue;
//   Real maxValue;
// end OnMouseMoveYSetReal;
// 
// record OnMouseDownEditInteger
//   Integer variable \"Name of variable to change\";
// end OnMouseDownEditInteger;
// 
// record OnMouseDownEditReal
//   Real variable \"Name of variable to change\";
// end OnMouseDownEditReal;
// 
// record OnMouseDownEditString
//   String variable \"Name of variable to change\";
// end OnMouseDownEditString;
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
// record Dialog
//   parameter String tab = \"General\";
//   parameter String group = \"Parameters\";
//   parameter Boolean enable = true;
// end Dialog;
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
"
;

/*
partial record GraphicItem
  Boolean visible = true;
  Point origin = {0, 0};
  Real rotation(quantity="angle", unit="deg")=0;
end GraphicItem;

record CoordinateSystem
  Extent extent;
  Boolean preserveAspectRatio=true;
  Real initialScale = 0.1;
  DrawingUnit grid[2];
end CoordinateSystem;

// example 
// CoordinateSystem(extent = {{-10, -10}, {10, 10}});
// i.e. a coordinate system with width 20 units and height 20 units.

record Icon "Representation of the icon layer"
  CoordinateSystem coordinateSystem(extent = {{-100, -100}, {100, 100}});
  GraphicItem[:] graphics;
end Icon;

record Diagram "Representation of the diagram layer"
  CoordinateSystem coordinateSystem(extent = {{-100, -100}, {100, 100}});
  GraphicItem[:] graphics;
end Diagram;

type Color = Integer[3](min=0, max=255) "RGB representation";
constant Color Black = zeros(3);
type LinePattern = enumeration(None, Solid, Dash, Dot, DashDot, DashDotDot);
type FillPattern = enumeration(None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere);
type BorderPattern = enumeration(None, Raised, Sunken, Engraved);
type Smooth = enumeration(None, Bezier);

type Arrow = enumeration(None, Open, Filled, Half);
type TextStyle = enumeration(Bold, Italic, UnderLine);
type TextAlignment = enumeration(Left, Center, Right);

// Filled shapes have the following attributes for the border and interior.

record FilledShape "Style attributes for filled shapes"
  Color lineColor = Black "Color of border line";
  Color fillColor = Black "Interior fill color";
  LinePattern pattern = LinePattern.Solid "Border line pattern";
  FillPattern fillPattern = FillPattern.None "Interior fill pattern";
  DrawingUnit lineThickness = 0.25 "Line thickness";
end FilledShape;

record Transformation
  Point origin = {0, 0};
  Extent extent;
  Real rotation(quantity="angle", unit="deg")=0;
end Transformation;

record Placement
  Boolean visible = true;
  Transformation transformation "Placement in the dagram layer";
  Transformation iconTransformation "Placement in the icon layer";
end Placement;

record IconMap
  Extent extent = {{0, 0}, {0, 0}};
  Boolean primitivesVisible = true;
end IconMap;

record DiagramMap
  Extent extent = {{0, 0}, {0, 0}};
  Boolean primitivesVisible = true;
end DiagramMap;

record Line
  extends GraphicItem;
  Point points[:];
  Color color = Black;
  LinePattern pattern = LinePattern.Solid;
  DrawingUnit thickness = 0.25;
  Arrow arrow[2] = {Arrow.None, Arrow.None} "{start arrow, end arrow}";
  DrawingUnit arrowSize=3;
  Smooth smooth = Smooth.None "Spline";
end Line;

record Polygon
  extends GraphicItem;
  extends FilledShape;
  Point points[:];
  Smooth smooth = Smooth.None "Spline outline";
end Polygon;

record Ellipse
  extends GraphicItem;
  extends FilledShape;
  Extent extent;
  Real startAngle(quantity="angle", unit="deg")=0;
  Real endAngle(quantity="angle", unit="deg")=360;
end Ellipse;

record Text
  extends GraphicItem;
  extends FilledShape;
  Extent extent;
  String textString;
  Real fontSize = 0 "unit pt";
  String fontName;
  TextStyle textStyle[:];
  TextAlignment horizontalAlignment = TextAlignment.Center;
end Text;

record Bitmap
  extends GraphicItem;
  Extent extent;
  String fileName "Name of bitmap file";
  String imageSource "Base64 representation of bitmap";
end Bitmap;
*/

end Constants;

/*

import Absyn;

public constant Absyn.Program graphicsProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("LinePattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Dash",NONE),Absyn.ENUMLITERAL("Dot",NONE),
          Absyn.ENUMLITERAL("DashDot",NONE),Absyn.ENUMLITERAL("DashDot",NONE),
          Absyn.ENUMLITERAL("DashDotDot",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Arrow",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Open",NONE),Absyn.ENUMLITERAL("Filled",NONE),Absyn.ENUMLITERAL("Filled",NONE),
          Absyn.ENUMLITERAL("Half",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("FillPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Horizontal",NONE),
          Absyn.ENUMLITERAL("Vertical",NONE),Absyn.ENUMLITERAL("Cross",NONE),Absyn.ENUMLITERAL("Forward",NONE),
          Absyn.ENUMLITERAL("Backward",NONE),Absyn.ENUMLITERAL("CrossDiag",NONE),
          Absyn.ENUMLITERAL("HorizontalCylinder",NONE),Absyn.ENUMLITERAL("VerticalCylinder",NONE),
          Absyn.ENUMLITERAL("VerticalCylinder",NONE),Absyn.ENUMLITERAL("Sphere",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("BorderPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Raised",NONE),Absyn.ENUMLITERAL("Sunken",NONE),Absyn.ENUMLITERAL("Sunken",NONE),
          Absyn.ENUMLITERAL("Engraved",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("TextStyle",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("Bold",NONE),
          Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Underline",NONE)}),NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Line",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("color",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("thickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Arrow"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrow",{Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{})))}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrowSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(3.0))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,6,0,6,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Polygon",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,7,0,7,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Rectangle",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("BorderPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("borderPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("BorderPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("radius",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,8,0,8,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Ellipse",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,9,0,9,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Text",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textString",{},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("TextStyle"),NONE),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textStyle",{Absyn.NOSUB()},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,10,0,10,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("Bitmap",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("graphics.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fileName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("imageSource",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("graphics.mo",true,11,0,11,0),NONE))})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("graphics.mo",true,0,0,0,0))},Absyn.TOP()) "AST for the builtin graphical classes" ;

public constant Absyn.Program iconProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("GraphicItem",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("CoordinateSystem",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Icon",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("CoordinateSystem"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("coordinateSystem",{},
          SOME(
          Absyn.CLASSMOD(
          {
          Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.CREF_IDENT("extent",{}),
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.ARRAY(
          {Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(10.0)),
          Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(10.0))}),Absyn.ARRAY({Absyn.REAL(10.0),Absyn.REAL(10.0)})})))),NONE)},NONE))),NONE,NONE)}),Absyn.INFO("icon.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("LinePattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Dash",NONE),Absyn.ENUMLITERAL("Dot",NONE),
          Absyn.ENUMLITERAL("DashDot",NONE),Absyn.ENUMLITERAL("DashDot",NONE),
          Absyn.ENUMLITERAL("DashDotDot",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Arrow",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Open",NONE),Absyn.ENUMLITERAL("Filled",NONE),Absyn.ENUMLITERAL("Filled",NONE),
          Absyn.ENUMLITERAL("Half",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("FillPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Horizontal",NONE),
          Absyn.ENUMLITERAL("Vertical",NONE),Absyn.ENUMLITERAL("Cross",NONE),Absyn.ENUMLITERAL("Forward",NONE),
          Absyn.ENUMLITERAL("Backward",NONE),Absyn.ENUMLITERAL("CrossDiag",NONE),
          Absyn.ENUMLITERAL("HorizontalCylinder",NONE),Absyn.ENUMLITERAL("VerticalCylinder",NONE),
          Absyn.ENUMLITERAL("VerticalCylinder",NONE),Absyn.ENUMLITERAL("Sphere",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("BorderPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Raised",NONE),Absyn.ENUMLITERAL("Sunken",NONE),Absyn.ENUMLITERAL("Sunken",NONE),
          Absyn.ENUMLITERAL("Engraved",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("TextStyle",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("Bold",NONE),
          Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Underline",NONE)}),NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Line",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("color",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("thickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Arrow"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrow",{Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{})))}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrowSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(3.0))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,8,0,8,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Polygon",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,9,0,9,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Rectangle",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("BorderPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("borderPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("BorderPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("radius",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,10,0,10,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Ellipse",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,11,0,11,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Text",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textString",{},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("TextStyle"),NONE),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textStyle",{Absyn.NOSUB()},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,12,0,12,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("Bitmap",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("icon.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fileName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("imageSource",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("icon.mo",true,13,0,13,0),NONE))})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("icon.mo",true,0,0,0,0))},Absyn.TOP());

public constant Absyn.Program diagramProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("GraphicItem",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("CoordinateSystem",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Diagram",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("CoordinateSystem"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("coordinateSystem",{},
          SOME(
          Absyn.CLASSMOD(
          {
          Absyn.MODIFICATION(false,Absyn.NON_EACH(),Absyn.CREF_IDENT("extent",{}),
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.ARRAY(
          {Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(100.0)),
          Absyn.UNARY(Absyn.UMINUS(),Absyn.REAL(100.0))}),Absyn.ARRAY({Absyn.REAL(100.0),Absyn.REAL(100.0)})})))),NONE)},NONE))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("LinePattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Dash",NONE),Absyn.ENUMLITERAL("Dot",NONE),
          Absyn.ENUMLITERAL("DashDot",NONE),Absyn.ENUMLITERAL("DashDot",NONE),
          Absyn.ENUMLITERAL("DashDotDot",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Arrow",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Open",NONE),Absyn.ENUMLITERAL("Filled",NONE),Absyn.ENUMLITERAL("Filled",NONE),
          Absyn.ENUMLITERAL("Half",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("FillPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Horizontal",NONE),
          Absyn.ENUMLITERAL("Vertical",NONE),Absyn.ENUMLITERAL("Cross",NONE),Absyn.ENUMLITERAL("Forward",NONE),
          Absyn.ENUMLITERAL("Backward",NONE),Absyn.ENUMLITERAL("CrossDiag",NONE),
          Absyn.ENUMLITERAL("HorizontalCylinder",NONE),Absyn.ENUMLITERAL("VerticalCylinder",NONE),
          Absyn.ENUMLITERAL("VerticalCylinder",NONE),Absyn.ENUMLITERAL("Sphere",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("BorderPattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Raised",NONE),Absyn.ENUMLITERAL("Sunken",NONE),Absyn.ENUMLITERAL("Sunken",NONE),
          Absyn.ENUMLITERAL("Engraved",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("TextStyle",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("Bold",NONE),
          Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Italic",NONE),Absyn.ENUMLITERAL("Underline",NONE)}),NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Line",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("color",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("thickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Arrow"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrow",{Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{})))}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrowSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(3.0))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,8,0,8,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Polygon",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,9,0,9,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Rectangle",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("BorderPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("borderPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("BorderPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("radius",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,10,0,10,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Ellipse",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,11,0,11,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Text",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillColor",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("FillPattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fillPattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("FillPattern",{},Absyn.CREF_IDENT("None",{}))))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("lineThickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textString",{},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fontName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("TextStyle"),NONE),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("textStyle",{Absyn.NOSUB()},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,12,0,12,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("Bitmap",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("extent",
          {Absyn.SUBSCRIPT(Absyn.INTEGER(2)),
          Absyn.SUBSCRIPT(Absyn.INTEGER(2))},NONE),NONE,NONE)}),Absyn.INFO("diagram.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("fileName",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,13,0,13,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("String"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("imageSource",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.STRING(""))))),NONE,NONE)}),Absyn.INFO("diagram.mo",true,13,0,13,0),NONE))})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("diagram.mo",true,0,0,0,0))},Absyn.TOP());

public constant Absyn.Program lineProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("LinePattern",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Solid",NONE),Absyn.ENUMLITERAL("Dash",NONE),Absyn.ENUMLITERAL("Dot",NONE),
          Absyn.ENUMLITERAL("DashDot",NONE),Absyn.ENUMLITERAL("DashDot",NONE),
          Absyn.ENUMLITERAL("DashDotDot",NONE)}),NONE),Absyn.INFO("line.mo",true,0,0,0,0)),
          Absyn.CLASS("Arrow",false,false,false,Absyn.R_TYPE(),
          Absyn.ENUMERATION(
          Absyn.ENUMLITERALS(
          {Absyn.ENUMLITERAL("None",NONE),
          Absyn.ENUMLITERAL("Open",NONE),Absyn.ENUMLITERAL("Filled",NONE),Absyn.ENUMLITERAL("Filled",NONE),
          Absyn.ENUMLITERAL("Half",NONE)}),NONE),Absyn.INFO("line.mo",true,0,0,0,0)),
          Absyn.CLASS("Line",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("points",{Absyn.NOSUB(),Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          NONE),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Integer"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("color",{Absyn.SUBSCRIPT(Absyn.INTEGER(3))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY({Absyn.INTEGER(0),Absyn.INTEGER(0),Absyn.INTEGER(0)}))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("LinePattern"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("pattern",{},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.CREF(
          Absyn.CREF_QUAL("LinePattern",{},Absyn.CREF_IDENT("Solid",{}))))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("thickness",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.25))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Arrow"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrow",{Absyn.SUBSCRIPT(Absyn.INTEGER(2))},
          SOME(
          Absyn.CLASSMOD({},
          SOME(
          Absyn.ARRAY(
          {
          Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{}))),Absyn.CREF(Absyn.CREF_QUAL("Arrow",{},Absyn.CREF_IDENT("None",{})))}))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("arrowSize",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(3.0))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("smooth",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("line.mo",true,1,0,1,0),NONE))})},NONE),Absyn.INFO("line.mo",true,0,0,0,0)),
          Absyn.CLASS("test",false,false,false,Absyn.R_MODEL(),
          Absyn.PARTS({Absyn.PUBLIC({})},NONE),Absyn.INFO("line.mo",true,0,0,0,0))},Absyn.TOP());

public constant Absyn.Program placementProgram=Absyn.PROGRAM(
          {
          Absyn.CLASS("Transformation",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("x",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("y",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("scale",{},SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(1.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("aspectRatio",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(1.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("flipHorizontal",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("flipVertical",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(false))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Real"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("rotation",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.REAL(0.0))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE))})},NONE),Absyn.INFO("placement.mo",true,0,0,0,0)),
          Absyn.CLASS("Placement",false,false,false,Absyn.R_RECORD(),
          Absyn.PARTS(
          {
          Absyn.PUBLIC(
          {
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Boolean"),NONE),
          {
          Absyn.COMPONENTITEM(
          Absyn.COMPONENT("visible",{},
          SOME(Absyn.CLASSMOD({},SOME(Absyn.BOOL(true))))),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Transformation"),NONE),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("transformation",{},NONE),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE)),
          Absyn.ELEMENTITEM(
          Absyn.ELEMENT(false,NONE,Absyn.UNSPECIFIED(),"component",
          Absyn.COMPONENTS(Absyn.ATTR(false,false,Absyn.VAR(),Absyn.BIDIR(),{}),
          Absyn.TPATH(Absyn.IDENT("Transformation"),NONE),
          {
          Absyn.COMPONENTITEM(Absyn.COMPONENT("iconTransformation",{},NONE),NONE,NONE)}),Absyn.INFO("placement.mo",true,2,0,2,0),NONE))})},NONE),Absyn.INFO("placement.mo",true,0,0,0,0))},Absyn.TOP());
*/

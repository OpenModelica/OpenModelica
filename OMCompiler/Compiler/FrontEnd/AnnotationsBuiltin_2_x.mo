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

package GraphicalAnnotationsProgram____
end     GraphicalAnnotationsProgram____;

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
  String fontName="";
  TextStyle textStyle[:];
end Text;

record Bitmap
  Boolean visible=true;
  Real extent[2,2];
  String fileName="";
  String imageSource="";
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


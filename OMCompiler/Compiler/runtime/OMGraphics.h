/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * See the full OSMC Public License conditions for more details.
 */

/*
 * OMGraphics - a small, Qt-free C++ library that mirrors OMEdit's handling of
 * Modelica graphical (Icon/Diagram) annotations and renders them to SVG.
 *
 * It is meant to be shared by different OpenModelica tools (first user: the
 * FMI 3.0 FMU export, which needs an icon SVG and the terminalsAndIcons.xml
 * GraphicalRepresentation). The data model below intentionally mirrors the
 * ModelInstance::* graphic classes of OMEdit (OMEditLIB/Modeling/Model.h) but
 * with plain C++ types (no Qt). Two front-ends fill this model: one from the
 * getModelInstance(Reference) data, and (for testing) a hand-built model.
 */

#ifndef OMGRAPHICS_H
#define OMGRAPHICS_H

#include <string>
#include <vector>
#include <utility>

namespace OMGraphics {

/* An RGB colour, components 0..255. A negative component marks "no colour set"
   (Modelica uses {-1,-1,-1} as the default text colour = inherit/black). */
struct Color {
  int r = 0, g = 0, b = 0;
  bool isSet() const { return r >= 0 && g >= 0 && b >= 0; }
};

struct Point { double x = 0.0, y = 0.0; };

/* A Modelica extent {{x1,y1},{x2,y2}}. */
struct Extent { Point p1, p2; };

/* Enumerations following the Modelica graphical annotation standard. The integer
   values match the 1-based enumeration index used in the annotation data. */
enum class LinePattern  { None = 1, Solid, Dash, Dot, DashDot, DashDotDot };
enum class FillPattern  { None = 1, Solid, Horizontal, Vertical, Cross, Forward,
                          Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere };
enum class BorderPattern { None = 1, Raised, Sunken, Engraved };
enum class Smooth       { None = 1, Bezier };
enum class EllipseClosure { None = 1, Chord, Radial };
enum class TextAlignment  { Left = 1, Center, Right };
enum class Arrow        { None = 1, Open, Filled, Half };
enum class TextStyle    { Bold = 1, Italic, UnderLine };

enum class ShapeKind { Rectangle, Line, Polygon, Ellipse, Text, Bitmap };

/* One graphic primitive. A single struct holds all shapes (only the fields
   relevant to `kind` are meaningful) to keep the model and the JSON/MM walk
   simple. Mirrors the positional element layout of the annotation records. */
struct Shape {
  ShapeKind kind = ShapeKind::Rectangle;

  /* GraphicItem */
  bool visible = true;
  Point origin = {0.0, 0.0};
  double rotation = 0.0;

  /* FilledShape (Rectangle, Polygon, Ellipse, Text) */
  Color lineColor = {0, 0, 0};
  Color fillColor = {0, 0, 0};
  LinePattern linePattern = LinePattern::Solid;
  FillPattern fillPattern = FillPattern::None;
  double lineThickness = 0.25;

  /* Rectangle */
  BorderPattern borderPattern = BorderPattern::None;
  Extent extent;
  double radius = 0.0;

  /* Line / Polygon */
  std::vector<Point> points;
  Color color = {0, 0, 0};        /* Line has its own colour, not FilledShape */
  double thickness = 0.25;        /* Line */
  Arrow arrow[2] = {Arrow::None, Arrow::None};
  double arrowSize = 3.0;
  Smooth smooth = Smooth::None;

  /* Ellipse */
  double startAngle = 0.0, endAngle = 360.0;
  EllipseClosure closure = EllipseClosure::Chord;

  /* Text */
  std::string textString;
  double fontSize = 0.0;
  Color textColor = {-1, -1, -1};
  std::string fontName;
  std::vector<TextStyle> textStyles;
  TextAlignment horizontalAlignment = TextAlignment::Center;

  /* Bitmap */
  std::string fileName;
  std::string imageSource;        /* base64-encoded image data */
};

struct CoordinateSystem {
  Extent extent = {{-100.0, -100.0}, {100.0, 100.0}};
  bool preserveAspectRatio = true;
  double initialScale = 0.1;
};

struct Icon {
  CoordinateSystem coordinateSystem;
  std::vector<Shape> graphics;
};

/* Options for SVG rendering. */
struct SvgOptions {
  /* the value substituted for the Modelica "%name" placeholder in Text shapes
     (the model/instance name shown on the icon); empty leaves it as-is */
  std::string nameText;
  /* width/height (px) hint written into the <svg> element; 0 = derive from the
     coordinate system extent */
  double widthPx = 0.0;
  double heightPx = 0.0;
};

/* Render an icon to a standalone SVG document. The Modelica coordinate system
   (y up) is mapped to SVG (y down) via the root group transform. */
std::string renderIconSVG(const Icon &icon, const SvgOptions &opts = SvgOptions());

/* ------------------------------------------------------------------------- *
 * Generic JSON value.
 *
 * A minimal, order-preserving JSON tree used as the intermediate form between
 * the getModelInstanceAnnotation data and the Icon model. The list-form boxed
 * MetaModelica value of issue #15219 is walked into this (see OMGraphics_omc),
 * and a hand-built tree can be used to test the annotation parser without omc.
 * ------------------------------------------------------------------------- */
struct Json {
  enum class Kind { Null, Bool, Int, Double, String, Array, Object };
  Kind kind = Kind::Null;
  bool b = false;
  long long i = 0;
  double d = 0.0;
  std::string s;
  std::vector<Json> arr;
  std::vector<std::pair<std::string, Json>> obj; /* insertion order kept */

  bool isNull()   const { return kind == Kind::Null; }
  bool isArray()  const { return kind == Kind::Array; }
  bool isObject() const { return kind == Kind::Object; }
  double asNumber() const { return kind == Kind::Double ? d : (kind == Kind::Int ? (double) i : 0.0); }
  long long asInt() const { return kind == Kind::Int ? i : (kind == Kind::Double ? (long long) d : 0); }
  bool asBool() const { return kind == Kind::Bool ? b : false; }
  const std::string &asString() const { return s; }

  /* object lookup by key; null sentinel if absent */
  const Json &get(const std::string &key) const;
  /* array element by index; null sentinel if out of range */
  const Json &at(size_t idx) const;
  size_t size() const { return arr.size(); }
};

/* Parse a getModelInstanceAnnotation tree into an Icon. Accepts the full
   annotation root ({name, annotation:{Icon:{...}}}), a bare {Icon:{...}}, or a
   bare {coordinateSystem, graphics} object. Unknown shapes are skipped. */
Icon iconFromJson(const Json &root);

/* Emit the FMI 3.0 fmiTerminalsAndIcons <GraphicalRepresentation> element for an
   icon: a CoordinateSystem (the icon coordinate box plus a scaling factor to mm)
   and an Icon bounding box. Returns the element with no surrounding document, so
   it can be spliced into terminalsAndIcons.xml. */
std::string renderGraphicalRepresentationXML(const Icon &icon, double scaleToMm = 0.5);

} // namespace OMGraphics

#endif /* OMGRAPHICS_H */

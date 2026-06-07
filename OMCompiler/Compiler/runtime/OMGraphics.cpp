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
 *
 * See the full OSMC Public License conditions for more details.
 */

/*
 * OMGraphics SVG renderer. Converts the OMGraphics::Icon model to an SVG
 * document. The Modelica coordinate system has y pointing up; SVG has y down,
 * so the whole drawing is wrapped in a root group that flips y. Text and images
 * locally undo the flip so they are not mirrored.
 */

#include "OMGraphics.h"

#include <sstream>
#include <cmath>
#include <algorithm>

namespace OMGraphics {

namespace {

/* M_PI is not in standard C++ (absent on MSVC/MinGW without _USE_MATH_DEFINES),
   so use a local constant for portability. */
const double OMG_PI = 3.14159265358979323846;

/* format a double compactly (no trailing zeros, no locale issues) */
std::string num(double v)
{
  if (std::isnan(v) || std::isinf(v)) v = 0.0;
  if (v == 0.0) v = 0.0; /* normalise -0 */
  std::ostringstream os;
  os.precision(6);
  os << v;
  return os.str();
}

std::string colorStr(const Color &c)
{
  std::ostringstream os;
  int r = c.r < 0 ? 0 : c.r, g = c.g < 0 ? 0 : c.g, b = c.b < 0 ? 0 : c.b;
  os << "rgb(" << r << "," << g << "," << b << ")";
  return os.str();
}

std::string escapeXml(const std::string &s)
{
  std::string out;
  out.reserve(s.size());
  for (char ch : s) {
    switch (ch) {
      case '&': out += "&amp;"; break;
      case '<': out += "&lt;"; break;
      case '>': out += "&gt;"; break;
      case '"': out += "&quot;"; break;
      case '\'': out += "&apos;"; break;
      default: out += ch;
    }
  }
  return out;
}

/* a sensible stroke width: Modelica lineThickness is in mm; a thickness of 0
   means "default" (0.25 mm). We render it directly in coordinate units, which
   matches OMEdit closely enough for icon-sized drawings. */
double strokeWidth(double thickness)
{
  return thickness > 0.0 ? thickness : 0.25;
}

std::string dashArray(LinePattern p, double w)
{
  double u = strokeWidth(w);
  switch (p) {
    case LinePattern::Dash:       { std::ostringstream o; o << num(4*u) << "," << num(4*u); return o.str(); }
    case LinePattern::Dot:        { std::ostringstream o; o << num(u)   << "," << num(2*u); return o.str(); }
    case LinePattern::DashDot:    { std::ostringstream o; o << num(4*u) << "," << num(2*u) << "," << num(u) << "," << num(2*u); return o.str(); }
    case LinePattern::DashDotDot: { std::ostringstream o; o << num(4*u) << "," << num(2*u) << "," << num(u) << "," << num(2*u) << "," << num(u) << "," << num(2*u); return o.str(); }
    default: return "";
  }
}

/* stroke style for a shape outline (line pattern None -> no stroke) */
std::string strokeStyle(const Color &line, LinePattern pattern, double thickness)
{
  std::ostringstream os;
  if (pattern == LinePattern::None) {
    os << "stroke:none;";
  } else {
    os << "stroke:" << colorStr(line) << ";stroke-width:" << num(strokeWidth(thickness)) << ";";
    std::string da = dashArray(pattern, thickness);
    if (!da.empty()) os << "stroke-dasharray:" << da << ";";
  }
  return os.str();
}

/* fill style for a shape (fill pattern None -> no fill; non-solid patterns are
   approximated as solid for now, gradients/hatches come later) */
std::string fillStyle(const Color &fill, FillPattern pattern)
{
  std::ostringstream os;
  if (pattern == FillPattern::None) {
    os << "fill:none;";
  } else {
    os << "fill:" << colorStr(fill) << ";";
  }
  return os.str();
}

void openTransform(std::ostringstream &svg, const Shape &s)
{
  bool hasOrigin = (s.origin.x != 0.0 || s.origin.y != 0.0);
  bool hasRot = (s.rotation != 0.0);
  if (hasOrigin || hasRot) {
    svg << "  <g transform=\"";
    if (hasOrigin) svg << "translate(" << num(s.origin.x) << "," << num(s.origin.y) << ") ";
    if (hasRot)    svg << "rotate(" << num(s.rotation) << ")";
    svg << "\">\n";
  }
}
void closeTransform(std::ostringstream &svg, const Shape &s)
{
  if (s.origin.x != 0.0 || s.origin.y != 0.0 || s.rotation != 0.0) svg << "  </g>\n";
}

void emitRectangle(std::ostringstream &svg, const Shape &s)
{
  double x = std::min(s.extent.p1.x, s.extent.p2.x);
  double y = std::min(s.extent.p1.y, s.extent.p2.y);
  double w = std::fabs(s.extent.p2.x - s.extent.p1.x);
  double h = std::fabs(s.extent.p2.y - s.extent.p1.y);
  svg << "    <rect x=\"" << num(x) << "\" y=\"" << num(y) << "\" width=\"" << num(w)
      << "\" height=\"" << num(h) << "\"";
  if (s.radius > 0.0) svg << " rx=\"" << num(s.radius) << "\" ry=\"" << num(s.radius) << "\"";
  svg << " style=\"" << fillStyle(s.fillColor, s.fillPattern)
      << strokeStyle(s.lineColor, s.linePattern, s.lineThickness) << "\"/>\n";
}

void emitPoints(std::ostringstream &svg, const std::vector<Point> &pts)
{
  for (size_t i = 0; i < pts.size(); ++i) {
    if (i) svg << " ";
    svg << num(pts[i].x) << "," << num(pts[i].y);
  }
}

void emitLine(std::ostringstream &svg, const Shape &s)
{
  svg << "    <polyline points=\"";
  emitPoints(svg, s.points);
  svg << "\" style=\"fill:none;"
      << strokeStyle(s.color, s.linePattern, s.thickness)
      << "stroke-linecap:round;stroke-linejoin:round;\"/>\n";
}

void emitPolygon(std::ostringstream &svg, const Shape &s)
{
  svg << "    <polygon points=\"";
  emitPoints(svg, s.points);
  svg << "\" style=\"" << fillStyle(s.fillColor, s.fillPattern)
      << strokeStyle(s.lineColor, s.linePattern, s.lineThickness) << "\"/>\n";
}

void emitEllipse(std::ostringstream &svg, const Shape &s)
{
  double cx = (s.extent.p1.x + s.extent.p2.x) / 2.0;
  double cy = (s.extent.p1.y + s.extent.p2.y) / 2.0;
  double rx = std::fabs(s.extent.p2.x - s.extent.p1.x) / 2.0;
  double ry = std::fabs(s.extent.p2.y - s.extent.p1.y) / 2.0;
  bool full = (std::fabs(s.endAngle - s.startAngle) >= 359.999) ||
              (s.startAngle == 0.0 && s.endAngle == 0.0);
  if (full) {
    svg << "    <ellipse cx=\"" << num(cx) << "\" cy=\"" << num(cy) << "\" rx=\"" << num(rx)
        << "\" ry=\"" << num(ry) << "\" style=\"" << fillStyle(s.fillColor, s.fillPattern)
        << strokeStyle(s.lineColor, s.linePattern, s.lineThickness) << "\"/>\n";
  } else {
    /* elliptical arc */
    double a0 = s.startAngle * OMG_PI / 180.0;
    double a1 = s.endAngle * OMG_PI / 180.0;
    double x0 = cx + rx * std::cos(a0), y0 = cy + ry * std::sin(a0);
    double x1 = cx + rx * std::cos(a1), y1 = cy + ry * std::sin(a1);
    int large = (std::fabs(s.endAngle - s.startAngle) > 180.0) ? 1 : 0;
    svg << "    <path d=\"M " << num(cx) << " " << num(cy)
        << " L " << num(x0) << " " << num(y0)
        << " A " << num(rx) << " " << num(ry) << " 0 " << large << " 1 " << num(x1) << " " << num(y1)
        << " Z\" style=\"" << fillStyle(s.fillColor, s.fillPattern)
        << strokeStyle(s.lineColor, s.linePattern, s.lineThickness) << "\"/>\n";
  }
}

void emitText(std::ostringstream &svg, const Shape &s, const SvgOptions &opts)
{
  double cx = (s.extent.p1.x + s.extent.p2.x) / 2.0;
  double cy = (s.extent.p1.y + s.extent.p2.y) / 2.0;
  double h = std::fabs(s.extent.p2.y - s.extent.p1.y);
  double size = s.fontSize > 0.0 ? s.fontSize : (h > 0.0 ? h * 0.8 : 10.0);

  std::string txt = s.textString;
  if (!opts.nameText.empty()) {
    /* substitute the Modelica %name placeholder with the model/instance name */
    size_t pos;
    while ((pos = txt.find("%name")) != std::string::npos) txt.replace(pos, 5, opts.nameText);
  }

  Color col = s.textColor.isSet() ? s.textColor : s.lineColor;
  const char *anchor = s.horizontalAlignment == TextAlignment::Left ? "start"
                     : s.horizontalAlignment == TextAlignment::Right ? "end" : "middle";

  std::string weight, style, deco;
  for (TextStyle ts : s.textStyles) {
    if (ts == TextStyle::Bold) weight = "font-weight:bold;";
    else if (ts == TextStyle::Italic) style = "font-style:italic;";
    else if (ts == TextStyle::UnderLine) deco = "text-decoration:underline;";
  }

  /* undo the root y-flip locally so the text is upright */
  svg << "    <g transform=\"translate(" << num(cx) << "," << num(cy) << ") scale(1,-1)\">\n";
  svg << "      <text x=\"0\" y=\"0\" text-anchor=\"" << anchor
      << "\" dominant-baseline=\"central\" font-size=\"" << num(size) << "\"";
  if (!s.fontName.empty()) svg << " font-family=\"" << escapeXml(s.fontName) << "\"";
  svg << " style=\"fill:" << colorStr(col) << ";" << weight << style << deco << "\">"
      << escapeXml(txt) << "</text>\n";
  svg << "    </g>\n";
}

void emitBitmap(std::ostringstream &svg, const Shape &s)
{
  double x = std::min(s.extent.p1.x, s.extent.p2.x);
  double y = std::min(s.extent.p1.y, s.extent.p2.y);
  double w = std::fabs(s.extent.p2.x - s.extent.p1.x);
  double h = std::fabs(s.extent.p2.y - s.extent.p1.y);
  std::string href;
  if (!s.imageSource.empty()) href = "data:image/png;base64," + s.imageSource;
  else if (!s.fileName.empty()) href = escapeXml(s.fileName);
  else return;
  /* undo the y-flip so the image is not upside down */
  svg << "    <g transform=\"translate(" << num(x) << "," << num(y + h) << ") scale(1,-1)\">\n";
  svg << "      <image x=\"0\" y=\"0\" width=\"" << num(w) << "\" height=\"" << num(h)
      << "\" preserveAspectRatio=\"none\" xlink:href=\"" << href << "\"/>\n";
  svg << "    </g>\n";
}

void emitShape(std::ostringstream &svg, const Shape &s, const SvgOptions &opts)
{
  if (!s.visible) return;
  openTransform(svg, s);
  switch (s.kind) {
    case ShapeKind::Rectangle: emitRectangle(svg, s); break;
    case ShapeKind::Line:      emitLine(svg, s); break;
    case ShapeKind::Polygon:   emitPolygon(svg, s); break;
    case ShapeKind::Ellipse:   emitEllipse(svg, s); break;
    case ShapeKind::Text:      emitText(svg, s, opts); break;
    case ShapeKind::Bitmap:    emitBitmap(svg, s); break;
  }
  closeTransform(svg, s);
}

} // namespace

std::string renderIconSVG(const Icon &icon, const SvgOptions &opts)
{
  const Extent &e = icon.coordinateSystem.extent;
  double xmin = std::min(e.p1.x, e.p2.x);
  double xmax = std::max(e.p1.x, e.p2.x);
  double ymin = std::min(e.p1.y, e.p2.y);
  double ymax = std::max(e.p1.y, e.p2.y);
  double w = xmax - xmin, h = ymax - ymin;
  if (w <= 0.0) w = 200.0;
  if (h <= 0.0) h = 200.0;

  /* Shapes drawn on the coordinate-system boundary (e.g. an icon-sized frame
     rectangle) have their stroke centred on the path, so half of it falls
     outside the extent and would be clipped by the viewBox. Pad the viewBox by
     the widest stroke (and at least a hair of the size) so the full outline is
     visible; this only affects the rendered SVG, not the coordinate system. */
  double maxStroke = 0.0;
  for (const Shape &s : icon.graphics) {
    double tw = (s.kind == ShapeKind::Line) ? s.thickness : s.lineThickness;
    double sw = strokeWidth(tw);
    if (sw > maxStroke) maxStroke = sw;
  }
  double margin = std::max(maxStroke, 0.005 * std::max(w, h));
  double vbX = xmin - margin, vbY = ymin - margin;
  double vbW = w + 2.0 * margin, vbH = h + 2.0 * margin;

  double pxW = opts.widthPx > 0.0 ? opts.widthPx : vbW;
  double pxH = opts.heightPx > 0.0 ? opts.heightPx : vbH;

  std::ostringstream svg;
  svg << "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n";
  svg << "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" "
      << "version=\"1.1\" width=\"" << num(pxW) << "\" height=\"" << num(pxH) << "\" "
      << "viewBox=\"" << num(vbX) << " " << num(vbY) << " " << num(vbW) << " " << num(vbH) << "\">\n";
  /* map Modelica (y up) to SVG (y down): y' = (ymin+ymax) - y */
  svg << "  <g transform=\"matrix(1 0 0 -1 0 " << num(ymin + ymax) << ")\">\n";
  for (const Shape &s : icon.graphics) {
    emitShape(svg, s, opts);
  }
  svg << "  </g>\n";
  svg << "</svg>\n";
  return svg.str();
}

/* ------------------------------------------------------------------------- *
 * Generic JSON helpers + annotation parser
 * ------------------------------------------------------------------------- */

const Json &Json::get(const std::string &key) const
{
  static const Json nul;
  for (const auto &p : obj) {
    if (p.first == key) return p.second;
  }
  return nul;
}

const Json &Json::at(size_t idx) const
{
  static const Json nul;
  return idx < arr.size() ? arr[idx] : nul;
}

namespace {

Point parsePoint(const Json &j)
{
  Point p;
  if (j.isArray() && j.size() >= 2) {
    p.x = j.at(0).asNumber();
    p.y = j.at(1).asNumber();
  }
  return p;
}

Extent parseExtent(const Json &j)
{
  Extent e;
  if (j.isArray() && j.size() >= 2) {
    e.p1 = parsePoint(j.at(0));
    e.p2 = parsePoint(j.at(1));
  }
  return e;
}

std::vector<Point> parsePoints(const Json &j)
{
  std::vector<Point> pts;
  if (j.isArray()) {
    for (size_t i = 0; i < j.size(); ++i) pts.push_back(parsePoint(j.at(i)));
  }
  return pts;
}

Color parseColor(const Json &j)
{
  Color c;
  if (j.isArray() && j.size() >= 3) {
    c.r = (int) j.at(0).asInt();
    c.g = (int) j.at(1).asInt();
    c.b = (int) j.at(2).asInt();
  }
  return c;
}

/* annotation enums are objects {"$kind":"enum","name":...,"index":N}; the index
   is the 1-based Modelica enumeration value, which matches our enum classes */
int enumIndex(const Json &j, int dflt)
{
  if (j.isObject()) {
    const Json &idx = j.get("index");
    if (!idx.isNull()) return (int) idx.asInt();
  } else if (j.kind == Json::Kind::Int || j.kind == Json::Kind::Double) {
    return (int) j.asInt();
  }
  return dflt;
}

void parseGraphicItem(const Json &el, Shape &s)
{
  s.visible = el.at(0).asBool();
  s.origin = parsePoint(el.at(1));
  s.rotation = el.at(2).asNumber();
}

/* FilledShape occupies positional elements 3..7 (lineColor, fillColor,
   linePattern, fillPattern, lineThickness) for the filled shapes. */
void parseFilledShape(const Json &el, Shape &s)
{
  s.lineColor = parseColor(el.at(3));
  s.fillColor = parseColor(el.at(4));
  s.linePattern = (LinePattern) enumIndex(el.at(5), (int) LinePattern::Solid);
  s.fillPattern = (FillPattern) enumIndex(el.at(6), (int) FillPattern::None);
  s.lineThickness = el.at(7).asNumber();
}

bool parseShape(const std::string &name, const Json &el, Shape &s)
{
  if (name == "Rectangle") {
    s.kind = ShapeKind::Rectangle;
    parseGraphicItem(el, s);
    parseFilledShape(el, s);
    s.borderPattern = (BorderPattern) enumIndex(el.at(8), (int) BorderPattern::None);
    s.extent = parseExtent(el.at(9));
    s.radius = el.at(10).asNumber();
    return true;
  } else if (name == "Line") {
    s.kind = ShapeKind::Line;
    parseGraphicItem(el, s);
    s.points = parsePoints(el.at(3));
    s.color = parseColor(el.at(4));
    s.linePattern = (LinePattern) enumIndex(el.at(5), (int) LinePattern::Solid);
    s.thickness = el.at(6).asNumber();
    const Json &arrows = el.at(7);
    s.arrow[0] = (Arrow) enumIndex(arrows.at(0), (int) Arrow::None);
    s.arrow[1] = (Arrow) enumIndex(arrows.at(1), (int) Arrow::None);
    s.arrowSize = el.at(8).asNumber();
    s.smooth = (Smooth) enumIndex(el.at(9), (int) Smooth::None);
    return true;
  } else if (name == "Polygon") {
    s.kind = ShapeKind::Polygon;
    parseGraphicItem(el, s);
    parseFilledShape(el, s);
    s.points = parsePoints(el.at(8));
    s.smooth = (Smooth) enumIndex(el.at(9), (int) Smooth::None);
    return true;
  } else if (name == "Ellipse") {
    s.kind = ShapeKind::Ellipse;
    parseGraphicItem(el, s);
    parseFilledShape(el, s);
    s.extent = parseExtent(el.at(8));
    s.startAngle = el.at(9).asNumber();
    s.endAngle = el.at(10).asNumber();
    s.closure = (EllipseClosure) enumIndex(el.at(11), (int) EllipseClosure::Chord);
    return true;
  } else if (name == "Text") {
    s.kind = ShapeKind::Text;
    parseGraphicItem(el, s);
    parseFilledShape(el, s);
    s.extent = parseExtent(el.at(8));
    s.textString = el.at(9).asString();
    s.fontSize = el.at(10).asNumber();
    s.textColor = parseColor(el.at(11)); /* {-1,-1,-1} stays "not set" via Color::isSet */
    s.fontName = el.at(12).asString();
    const Json &styles = el.at(13);
    for (size_t i = 0; i < styles.size(); ++i) {
      s.textStyles.push_back((TextStyle) enumIndex(styles.at(i), (int) TextStyle::Bold));
    }
    s.horizontalAlignment = (TextAlignment) enumIndex(el.at(14), (int) TextAlignment::Center);
    return true;
  } else if (name == "Bitmap") {
    s.kind = ShapeKind::Bitmap;
    parseGraphicItem(el, s);
    s.extent = parseExtent(el.at(3));
    s.fileName = el.at(4).asString();
    s.imageSource = el.at(5).asString();
    return true;
  }
  return false;
}

/* find the Icon annotation object inside whatever was passed */
const Json *findIconObject(const Json &root)
{
  /* full annotation root: {name, restriction, annotation:{Icon:{...}}} */
  const Json &ann = root.get("annotation");
  if (ann.isObject()) {
    const Json &icon = ann.get("Icon");
    if (icon.isObject()) return &icon;
  }
  /* bare {Icon:{...}} */
  const Json &icon = root.get("Icon");
  if (icon.isObject()) return &icon;
  /* already the Icon object */
  if (root.get("graphics").isArray() || root.get("coordinateSystem").isObject()) {
    return &root;
  }
  return nullptr;
}

} // namespace

Icon iconFromJson(const Json &root)
{
  Icon icon;
  const Json *iconObj = findIconObject(root);
  if (!iconObj) return icon;

  const Json &cs = iconObj->get("coordinateSystem");
  if (cs.isObject()) {
    const Json &ext = cs.get("extent");
    if (ext.isArray() && ext.size() >= 2) icon.coordinateSystem.extent = parseExtent(ext);
    const Json &par = cs.get("preserveAspectRatio");
    if (par.kind == Json::Kind::Bool) icon.coordinateSystem.preserveAspectRatio = par.asBool();
    const Json &is = cs.get("initialScale");
    if (!is.isNull()) icon.coordinateSystem.initialScale = is.asNumber();
  }

  const Json &graphics = iconObj->get("graphics");
  if (graphics.isArray()) {
    for (size_t i = 0; i < graphics.size(); ++i) {
      const Json &g = graphics.at(i);
      const std::string &name = g.get("name").asString();
      const Json &elements = g.get("elements");
      if (name.empty() || !elements.isArray()) continue;
      Shape s;
      if (parseShape(name, elements, s)) icon.graphics.push_back(s);
    }
  }
  return icon;
}

std::string renderGraphicalRepresentationXML(const Icon &icon, double scaleToMm)
{
  const Extent &e = icon.coordinateSystem.extent;
  double x1 = std::min(e.p1.x, e.p2.x);
  double y1 = std::min(e.p1.y, e.p2.y);
  double x2 = std::max(e.p1.x, e.p2.x);
  double y2 = std::max(e.p1.y, e.p2.y);
  if (scaleToMm <= 0.0) scaleToMm = 0.5;

  std::ostringstream os;
  os << "  <GraphicalRepresentation>\n";
  os << "    <CoordinateSystem x1=\"" << num(x1) << "\" y1=\"" << num(y1)
     << "\" x2=\"" << num(x2) << "\" y2=\"" << num(y2)
     << "\" suggestedScalingFactorTo_mm=\"" << num(scaleToMm) << "\"/>\n";
  os << "    <Icon x1=\"" << num(x1) << "\" y1=\"" << num(y1)
     << "\" x2=\"" << num(x2) << "\" y2=\"" << num(y2) << "\"/>\n";
  os << "  </GraphicalRepresentation>\n";
  return os.str();
}

} // namespace OMGraphics

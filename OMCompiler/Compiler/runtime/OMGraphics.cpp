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
#include <cstdint>
#include <cstring>
#include <vector>
#include <zlib.h>

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
    /* partial ellipse: honour the closure (None = open arc, Chord = straight
       line between the arc endpoints, Radial = pie wedge through the centre) */
    double a0 = s.startAngle * OMG_PI / 180.0;
    double a1 = s.endAngle * OMG_PI / 180.0;
    double x0 = cx + rx * std::cos(a0), y0 = cy + ry * std::sin(a0);
    double x1 = cx + rx * std::cos(a1), y1 = cy + ry * std::sin(a1);
    int large = (std::fabs(s.endAngle - s.startAngle) > 180.0) ? 1 : 0;
    if (s.closure == EllipseClosure::None) {
      /* open arc: stroke only, no fill, no closing segment */
      svg << "    <path d=\"M " << num(x0) << " " << num(y0)
          << " A " << num(rx) << " " << num(ry) << " 0 " << large << " 1 " << num(x1) << " " << num(y1)
          << "\" style=\"fill:none;" << strokeStyle(s.lineColor, s.linePattern, s.lineThickness) << "\"/>\n";
    } else if (s.closure == EllipseClosure::Chord) {
      /* chord: arc closed by a straight line between its endpoints */
      svg << "    <path d=\"M " << num(x0) << " " << num(y0)
          << " A " << num(rx) << " " << num(ry) << " 0 " << large << " 1 " << num(x1) << " " << num(y1)
          << " Z\" style=\"" << fillStyle(s.fillColor, s.fillPattern)
          << strokeStyle(s.lineColor, s.linePattern, s.lineThickness) << "\"/>\n";
    } else {
      /* radial (pie): centre -> arc start -> arc -> close back to centre */
      svg << "    <path d=\"M " << num(cx) << " " << num(cy)
          << " L " << num(x0) << " " << num(y0)
          << " A " << num(rx) << " " << num(ry) << " 0 " << large << " 1 " << num(x1) << " " << num(y1)
          << " Z\" style=\"" << fillStyle(s.fillColor, s.fillPattern)
          << strokeStyle(s.lineColor, s.linePattern, s.lineThickness) << "\"/>\n";
    }
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
 * PNG rasteriser
 *
 * A small, dependency-light (zlib only) rasteriser that draws the icon shapes
 * into an RGBA pixel buffer and encodes it as a PNG. The FMI 3.0 standard
 * (section "Terminal Graphical Representation" and the FMU layout in section
 * "Distribution of FMUs") requires the icon image files referenced from
 * terminalsAndIcons.xml to be PNGs; an SVG is only an optional companion.
 *
 * Anti-aliasing is done by supersampling: the scene is drawn at SS x the target
 * resolution and box-downsampled. Filled shapes are drawn opaque over a
 * transparent background, so coverage at the edges comes out of the downsample.
 * ------------------------------------------------------------------------- */
namespace {

const int OMG_SS = 3;          /* supersampling factor (per axis) */
const int OMG_MAX_DIM = 512;   /* clamp for the final image size (px) */

/* RGBA8 raster, row-major, 4 bytes/pixel, transparent (0,0,0,0) background. */
struct Raster {
  int w = 0, h = 0;
  std::vector<unsigned char> px;
  Raster(int W, int H) : w(W), h(H), px((size_t) W * H * 4, 0) {}
  /* set a pixel opaque to (r,g,b) (src-over with full alpha == replace) */
  inline void set(int x, int y, int r, int g, int b) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    unsigned char *p = &px[((size_t) y * w + x) * 4];
    p[0] = (unsigned char) r; p[1] = (unsigned char) g; p[2] = (unsigned char) b; p[3] = 255;
  }
};

/* A vertex in device (pixel, supersampled) space. */
struct DPoint { double x, y; };

/* Affine map from icon coordinates to supersampled device pixels (y flipped). */
struct DeviceMap {
  double vbX, vbY, vbW, vbH;
  double sw, sh; /* supersampled image size */
  DPoint map(double x, double y) const {
    DPoint d;
    d.x = (x - vbX) / vbW * sw;
    d.y = ((vbY + vbH) - y) / vbH * sh; /* flip y (Modelica y up -> image y down) */
    return d;
  }
};

/* Apply a shape's local transform (rotate about origin, then translate by
   origin) to a point in shape-local icon coordinates -> icon coordinates,
   mirroring the SVG "translate(origin) rotate(rotation)" group. */
Point applyShapeTransform(const Shape &s, const Point &p)
{
  double a = s.rotation * OMG_PI / 180.0;
  double ca = std::cos(a), sa = std::sin(a);
  Point r;
  r.x = s.origin.x + (ca * p.x - sa * p.y);
  r.y = s.origin.y + (sa * p.x + ca * p.y);
  return r;
}

/* Fill a polygon (device-space vertices) with a solid colour using an even-odd
   scanline rule. Vertices are already in supersampled pixel space. */
void fillPolygon(Raster &r, const std::vector<DPoint> &pts, const Color &c)
{
  if (pts.size() < 3) return;
  double ymin = pts[0].y, ymax = pts[0].y;
  for (const DPoint &p : pts) { ymin = std::min(ymin, p.y); ymax = std::max(ymax, p.y); }
  int y0 = std::max(0, (int) std::floor(ymin));
  int y1 = std::min(r.h - 1, (int) std::ceil(ymax));
  std::vector<double> xs;
  for (int y = y0; y <= y1; ++y) {
    double yc = y + 0.5;
    xs.clear();
    size_t n = pts.size();
    for (size_t i = 0; i < n; ++i) {
      const DPoint &a = pts[i], &b = pts[(i + 1) % n];
      double ay = a.y, by = b.y;
      if ((ay <= yc && by > yc) || (by <= yc && ay > yc)) {
        double t = (yc - ay) / (by - ay);
        xs.push_back(a.x + t * (b.x - a.x));
      }
    }
    if (xs.size() < 2) continue;
    std::sort(xs.begin(), xs.end());
    for (size_t i = 0; i + 1 < xs.size(); i += 2) {
      int xa = std::max(0, (int) std::ceil(xs[i] - 0.5));
      int xb = std::min(r.w - 1, (int) std::floor(xs[i + 1] - 0.5));
      for (int x = xa; x <= xb; ++x) r.set(x, y, c.r < 0 ? 0 : c.r, c.g < 0 ? 0 : c.g, c.b < 0 ? 0 : c.b);
    }
  }
}

/* Draw a filled disk (used for round line caps/joins). */
void fillDisk(Raster &r, double cx, double cy, double rad, const Color &c)
{
  if (rad <= 0.0) return;
  int x0 = std::max(0, (int) std::floor(cx - rad));
  int x1 = std::min(r.w - 1, (int) std::ceil(cx + rad));
  int y0 = std::max(0, (int) std::floor(cy - rad));
  int y1 = std::min(r.h - 1, (int) std::ceil(cy + rad));
  double r2 = rad * rad;
  for (int y = y0; y <= y1; ++y)
    for (int x = x0; x <= x1; ++x) {
      double dx = x + 0.5 - cx, dy = y + 0.5 - cy;
      if (dx * dx + dy * dy <= r2) r.set(x, y, c.r < 0 ? 0 : c.r, c.g < 0 ? 0 : c.g, c.b < 0 ? 0 : c.b);
    }
}

/* Stroke a polyline (device space) with a given pixel width by filling a quad
   per segment plus a disk at every vertex for round joins/caps. */
void strokePolyline(Raster &r, const std::vector<DPoint> &pts, bool closed,
                    const Color &c, double widthPx)
{
  double hw = std::max(widthPx, 1.0) / 2.0;
  size_t n = pts.size();
  if (n < 2) { if (n == 1) fillDisk(r, pts[0].x, pts[0].y, hw, c); return; }
  size_t segs = closed ? n : n - 1;
  for (size_t i = 0; i < segs; ++i) {
    const DPoint &a = pts[i], &b = pts[(i + 1) % n];
    double dx = b.x - a.x, dy = b.y - a.y;
    double len = std::sqrt(dx * dx + dy * dy);
    if (len < 1e-9) continue;
    double nx = -dy / len * hw, ny = dx / len * hw;
    std::vector<DPoint> quad = {
      {a.x + nx, a.y + ny}, {b.x + nx, b.y + ny}, {b.x - nx, b.y - ny}, {a.x - nx, a.y - ny}
    };
    fillPolygon(r, quad, c);
  }
  for (size_t i = 0; i < n; ++i) fillDisk(r, pts[i].x, pts[i].y, hw, c);
}

/* Turn an ellipse shape into a closed (or pie/chord) outline of icon-space
   points, honouring start/end angle. */
std::vector<Point> ellipsePoints(const Shape &s)
{
  double cx = (s.extent.p1.x + s.extent.p2.x) / 2.0;
  double cy = (s.extent.p1.y + s.extent.p2.y) / 2.0;
  double rx = std::fabs(s.extent.p2.x - s.extent.p1.x) / 2.0;
  double ry = std::fabs(s.extent.p2.y - s.extent.p1.y) / 2.0;
  bool full = (std::fabs(s.endAngle - s.startAngle) >= 359.999) ||
              (s.startAngle == 0.0 && s.endAngle == 0.0);
  double a0 = s.startAngle * OMG_PI / 180.0;
  double a1 = (full ? 360.0 : s.endAngle) * OMG_PI / 180.0;
  if (full) { a0 = 0.0; a1 = 2.0 * OMG_PI; }
  const int N = 64;
  std::vector<Point> pts;
  if (!full && s.closure == EllipseClosure::Radial)
    pts.push_back({cx, cy}); /* pie centre only for a radial (wedge) arc */
  for (int i = 0; i <= N; ++i) {
    double a = a0 + (a1 - a0) * i / (double) N;
    pts.push_back({cx + rx * std::cos(a), cy + ry * std::sin(a)});
  }
  return pts;
}

/* Map a vector of icon-space points (after the shape transform) to device. */
std::vector<DPoint> toDevice(const DeviceMap &m, const Shape &s, const std::vector<Point> &in)
{
  std::vector<DPoint> out;
  out.reserve(in.size());
  for (const Point &p : in) {
    Point w = applyShapeTransform(s, p);
    out.push_back(m.map(w.x, w.y));
  }
  return out;
}

void rasterShape(Raster &r, const DeviceMap &m, const Shape &s, double ssScale)
{
  if (!s.visible) return;
  /* device-space stroke width: Modelica thickness in coord units * pixels/unit */
  double pxPerUnit = m.sw / m.vbW;
  switch (s.kind) {
    case ShapeKind::Rectangle: {
      double x0 = std::min(s.extent.p1.x, s.extent.p2.x), x1 = std::max(s.extent.p1.x, s.extent.p2.x);
      double y0 = std::min(s.extent.p1.y, s.extent.p2.y), y1 = std::max(s.extent.p1.y, s.extent.p2.y);
      std::vector<Point> corners = {{x0, y0}, {x1, y0}, {x1, y1}, {x0, y1}};
      std::vector<DPoint> dev = toDevice(m, s, corners);
      if (s.fillPattern != FillPattern::None) fillPolygon(r, dev, s.fillColor);
      if (s.linePattern != LinePattern::None)
        strokePolyline(r, dev, true, s.lineColor, strokeWidth(s.lineThickness) * pxPerUnit);
      break;
    }
    case ShapeKind::Polygon: {
      std::vector<DPoint> dev = toDevice(m, s, s.points);
      if (s.fillPattern != FillPattern::None) fillPolygon(r, dev, s.fillColor);
      if (s.linePattern != LinePattern::None)
        strokePolyline(r, dev, true, s.lineColor, strokeWidth(s.lineThickness) * pxPerUnit);
      break;
    }
    case ShapeKind::Ellipse: {
      std::vector<Point> pts = ellipsePoints(s);
      std::vector<DPoint> dev = toDevice(m, s, pts);
      // A full ellipse is always closed/filled; for a partial ellipse the
      // closure decides: None = open stroked arc (no fill), Chord/Radial = closed.
      bool full = (std::fabs(s.endAngle - s.startAngle) >= 359.999) ||
                  (s.startAngle == 0.0 && s.endAngle == 0.0);
      bool closed = full || (s.closure != EllipseClosure::None);
      if (closed && s.fillPattern != FillPattern::None) fillPolygon(r, dev, s.fillColor);
      if (s.linePattern != LinePattern::None)
        strokePolyline(r, dev, closed, s.lineColor, strokeWidth(s.lineThickness) * pxPerUnit);
      break;
    }
    case ShapeKind::Line: {
      std::vector<DPoint> dev = toDevice(m, s, s.points);
      if (s.linePattern != LinePattern::None)
        strokePolyline(r, dev, false, s.color, strokeWidth(s.thickness) * pxPerUnit);
      break;
    }
    case ShapeKind::Text:
    case ShapeKind::Bitmap:
      /* not rasterised (no font / image decoder in this Qt-free path) */
      break;
  }
  (void) ssScale;
}

/* Box-downsample the supersampled raster to the final resolution, averaging
   RGBA over each SS x SS block so edges become anti-aliased and partially
   transparent. */
Raster downsample(const Raster &hi, int factor)
{
  Raster lo(hi.w / factor, hi.h / factor);
  for (int y = 0; y < lo.h; ++y)
    for (int x = 0; x < lo.w; ++x) {
      long sr = 0, sg = 0, sb = 0, sa = 0;
      for (int dy = 0; dy < factor; ++dy)
        for (int dx = 0; dx < factor; ++dx) {
          const unsigned char *p = &hi.px[((size_t)(y * factor + dy) * hi.w + (x * factor + dx)) * 4];
          /* premultiply so transparent texels don't bleed black into edges */
          sr += (long) p[0] * p[3]; sg += (long) p[1] * p[3]; sb += (long) p[2] * p[3];
          sa += p[3];
        }
      unsigned char *o = &lo.px[((size_t) y * lo.w + x) * 4];
      if (sa > 0) { o[0] = (unsigned char)(sr / sa); o[1] = (unsigned char)(sg / sa); o[2] = (unsigned char)(sb / sa); }
      o[3] = (unsigned char)(sa / (factor * factor));
    }
  return lo;
}

/* Append a big-endian uint32. */
void putU32(std::string &s, uint32_t v)
{
  s.push_back((char)((v >> 24) & 0xFF)); s.push_back((char)((v >> 16) & 0xFF));
  s.push_back((char)((v >> 8) & 0xFF));  s.push_back((char)(v & 0xFF));
}

/* Append a PNG chunk (type + data + CRC over type+data). */
void putChunk(std::string &out, const char tag[4], const std::string &data)
{
  putU32(out, (uint32_t) data.size());
  size_t start = out.size();
  out.append(tag, 4);
  out.append(data);
  uLong crc = crc32(0L, Z_NULL, 0);
  crc = crc32(crc, (const Bytef *)(out.data() + start), (uInt)(4 + data.size()));
  putU32(out, (uint32_t) crc);
}

/* Encode an RGBA8 raster as a PNG byte string (color type 6, filter 0 per row). */
std::string encodePNG(const Raster &img)
{
  std::string ihdr;
  putU32(ihdr, (uint32_t) img.w); putU32(ihdr, (uint32_t) img.h);
  ihdr.push_back(8);   /* bit depth */
  ihdr.push_back(6);   /* color type RGBA */
  ihdr.push_back(0);   /* compression */
  ihdr.push_back(0);   /* filter */
  ihdr.push_back(0);   /* interlace */

  std::string raw;
  raw.reserve((size_t) img.h * (img.w * 4 + 1));
  for (int y = 0; y < img.h; ++y) {
    raw.push_back(0); /* filter type: none */
    raw.append((const char *) &img.px[(size_t) y * img.w * 4], (size_t) img.w * 4);
  }

  uLongf bound = compressBound((uLong) raw.size());
  std::vector<unsigned char> comp(bound);
  if (compress2(comp.data(), &bound, (const Bytef *) raw.data(), (uLong) raw.size(), Z_BEST_COMPRESSION) != Z_OK)
    return std::string();
  std::string idat((const char *) comp.data(), bound);

  std::string out;
  const unsigned char sig[8] = {0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A};
  out.append((const char *) sig, 8);
  putChunk(out, "IHDR", ihdr);
  putChunk(out, "IDAT", idat);
  putChunk(out, "IEND", std::string());
  return out;
}

} // namespace

std::string renderIconPNG(const Icon &icon, const SvgOptions &opts)
{
  if (icon.graphics.empty()) return std::string();
  const Extent &e = icon.coordinateSystem.extent;
  double xmin = std::min(e.p1.x, e.p2.x), xmax = std::max(e.p1.x, e.p2.x);
  double ymin = std::min(e.p1.y, e.p2.y), ymax = std::max(e.p1.y, e.p2.y);
  double w = xmax - xmin, h = ymax - ymin;
  if (w <= 0.0) w = 200.0;
  if (h <= 0.0) h = 200.0;

  /* match the SVG viewBox padding so the full outline of boundary shapes fits */
  double maxStroke = 0.0;
  for (const Shape &s : icon.graphics) {
    double tw = (s.kind == ShapeKind::Line) ? s.thickness : s.lineThickness;
    double sw = strokeWidth(tw);
    if (sw > maxStroke) maxStroke = sw;
  }
  double margin = std::max(maxStroke, 0.005 * std::max(w, h));
  double vbW = w + 2.0 * margin, vbH = h + 2.0 * margin;
  double vbX = xmin - margin, vbY = ymin - margin;

  /* final image size: ~1 px per coordinate unit, clamped, aspect preserved */
  double scale = 1.0;
  double maxc = std::max(vbW, vbH);
  if (maxc * scale > OMG_MAX_DIM) scale = OMG_MAX_DIM / maxc;
  int outW = std::max(1, (int) std::lround(vbW * scale));
  int outH = std::max(1, (int) std::lround(vbH * scale));

  Raster hi(outW * OMG_SS, outH * OMG_SS);
  DeviceMap m{vbX, vbY, vbW, vbH, (double) hi.w, (double) hi.h};
  for (const Shape &s : icon.graphics) rasterShape(hi, m, s, (double) OMG_SS);

  Raster lo = downsample(hi, OMG_SS);
  (void) opts;
  return encodePNG(lo);
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

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
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "Quick3DGeometry.h"

#include <cmath>

#include <QByteArray>
#include <QVector>
#include <QVector3D>

namespace {
// Interleaved (position, normal) triangle-list builder. Non-indexed: each face
// pushes its own vertices so normals stay per-facet/per-vertex exact.
class MeshBuilder
{
public:
  void tri(const QVector3D& a, const QVector3D& b, const QVector3D& c,
           const QVector3D& na, const QVector3D& nb, const QVector3D& nc)
  {
    vertex(a, na); vertex(b, nb); vertex(c, nc);
  }
  // Quad a-b-c-d with a single (flat) normal, split into two triangles.
  void quad(const QVector3D& a, const QVector3D& b, const QVector3D& c, const QVector3D& d, const QVector3D& n)
  {
    tri(a, b, c, n, n, n);
    tri(a, c, d, n, n, n);
  }
  // Quad with per-vertex (smooth) normals.
  void quadN(const QVector3D& a, const QVector3D& b, const QVector3D& c, const QVector3D& d,
             const QVector3D& na, const QVector3D& nb, const QVector3D& nc, const QVector3D& nd)
  {
    tri(a, b, c, na, nb, nc);
    tri(a, c, d, na, nc, nd);
  }
  int count() const { return mCount; }
  const QByteArray& bytes() const { return mBytes; }
  QVector3D min() const { return mMin; }
  QVector3D max() const { return mMax; }

private:
  void vertex(const QVector3D& p, const QVector3D& n)
  {
    const float v[6] = { p.x(), p.y(), p.z(), n.x(), n.y(), n.z() };
    mBytes.append(reinterpret_cast<const char*>(v), int(sizeof(v)));
    if (mCount == 0) {
      mMin = mMax = p;
    } else {
      mMin.setX(qMin(mMin.x(), p.x())); mMin.setY(qMin(mMin.y(), p.y())); mMin.setZ(qMin(mMin.z(), p.z()));
      mMax.setX(qMax(mMax.x(), p.x())); mMax.setY(qMax(mMax.y(), p.y())); mMax.setZ(qMax(mMax.z(), p.z()));
    }
    mCount++;
  }
  QByteArray mBytes;
  int mCount = 0;
  QVector3D mMin, mMax;
};

void commit(Quick3DGeometry* geom, const MeshBuilder& mb)
{
  geom->clear();
  geom->setStride(6 * sizeof(float));
  geom->setVertexData(mb.bytes());
  geom->addAttribute(QQuick3DGeometry::Attribute::PositionSemantic, 0, QQuick3DGeometry::Attribute::F32Type);
  geom->addAttribute(QQuick3DGeometry::Attribute::NormalSemantic, 3 * sizeof(float), QQuick3DGeometry::Attribute::F32Type);
  geom->setPrimitiveType(QQuick3DGeometry::PrimitiveType::Triangles);
  geom->setBounds(mb.min(), mb.max());
  geom->update();
}

// An arbitrary unit vector perpendicular to v (mirrors Spring::getNormal: pick
// the axis least aligned with v and cross with it).
QVector3D anyPerp(const QVector3D& v)
{
  const QVector3D n = v.normalized();
  const QVector3D axis = (std::abs(n.x()) <= std::abs(n.y()) && std::abs(n.x()) <= std::abs(n.z()))
                           ? QVector3D(1, 0, 0)
                           : (std::abs(n.y()) <= std::abs(n.z()) ? QVector3D(0, 1, 0) : QVector3D(0, 0, 1));
  return QVector3D::crossProduct(n, axis).normalized();
}
} // namespace

Quick3DGeometry::Quick3DGeometry(QObject* parent)
  : QQuick3DGeometry(nullptr)
{
  if (parent) {
    setParent(parent); // QObject ownership only (freed with the node), not a scene-graph child
  }
}

void Quick3DGeometry::buildPipe(float innerRadius, float outerRadius, float length)
{
  const int nEdges = 16;
  const float rI = innerRadius;
  const float rO = outerRadius;
  const float l = length;
  const double phi = 2.0 * M_PI / nEdges;
  MeshBuilder mb;
  for (int i = 0; i < nEdges; i++) {
    const double a = phi * i;
    const double b = phi * (i + 1);
    const double mid = phi * (i + 0.5);
    const QVector3D nOut(float(std::sin(mid)), float(std::cos(mid)), 0.0f);
    const QVector3D oi0(float(std::sin(a) * rO), float(std::cos(a) * rO), 0);
    const QVector3D oj0(float(std::sin(b) * rO), float(std::cos(b) * rO), 0);
    const QVector3D oi1(oi0.x(), oi0.y(), l);
    const QVector3D oj1(oj0.x(), oj0.y(), l);
    const QVector3D ii0(float(std::sin(a) * rI), float(std::cos(a) * rI), 0);
    const QVector3D ij0(float(std::sin(b) * rI), float(std::cos(b) * rI), 0);
    const QVector3D ii1(ii0.x(), ii0.y(), l);
    const QVector3D ij1(ij0.x(), ij0.y(), l);
    mb.quad(oi0, oj0, oj1, oi1, nOut);                     // outer wall
    mb.quad(ii0, ii1, ij1, ij0, -nOut);                    // inner wall
    mb.quad(ii0, ij0, oj0, oi0, QVector3D(0, 0, -1));       // base annulus
    mb.quad(ii1, oi1, oj1, ij1, QVector3D(0, 0, 1));        // top annulus
  }
  commit(this, mb);
}

void Quick3DGeometry::buildSpring(float coilRadius, float wireRadius, float windings, float length)
{
  const int elementsWinding = 10;
  const int elementsContour = 6;
  const float R = coilRadius;
  const float rWire = wireRadius;
  const float L = length;
  const int numSegments = int(elementsWinding * windings) + 1;
  if (numSegments < 2) {
    return;
  }

  // Helix centreline.
  QVector<QVector3D> center(numSegments);
  for (int s = 0; s < numSegments; s++) {
    const double t = 2.0 * M_PI / elementsWinding * s;
    center[s] = QVector3D(float(std::sin(t) * R), float(std::cos(t) * R), float(L / numSegments * s));
  }

  // A ring of contour points around each centreline point, in the plane normal
  // to the local tangent (mirrors Spring's rotateArbitraryAxis sweep).
  QVector<QVector<QVector3D>> rings(numSegments - 1);
  for (int i = 0; i < numSegments - 1; i++) {
    const QVector3D tangent = (center[i + 1] - center[i]).normalized();
    const QVector3D u = anyPerp(tangent);
    const QVector3D v = QVector3D::crossProduct(tangent, u).normalized();
    rings[i].resize(elementsContour);
    for (int c = 0; c < elementsContour; c++) {
      const double ang = 2.0 * M_PI / elementsContour * c;
      const QVector3D dir = (u * float(std::cos(ang)) + v * float(std::sin(ang)));
      rings[i][c] = center[i] + dir * rWire;
    }
  }

  MeshBuilder mb;
  for (int i = 0; i < numSegments - 2; i++) {
    for (int c = 0; c < elementsContour; c++) {
      const int c1 = (c + 1) % elementsContour;
      const QVector3D a = rings[i][c];
      const QVector3D b = rings[i][c1];
      const QVector3D d = rings[i + 1][c];
      const QVector3D e = rings[i + 1][c1];
      const QVector3D na = (a - center[i]).normalized();
      const QVector3D nb = (b - center[i]).normalized();
      const QVector3D nd = (d - center[i + 1]).normalized();
      const QVector3D ne = (e - center[i + 1]).normalized();
      mb.quadN(a, b, e, d, na, nb, ne, nd);
    }
  }
  commit(this, mb);
}

void Quick3DGeometry::buildArrow(float radius, float length, float headRadius, float headLength)
{
  const int nEdges = 16;
  const double phi = 2.0 * M_PI / nEdges;
  const float shaftLen = qMax(0.0f, length - headLength);
  MeshBuilder mb;
  for (int i = 0; i < nEdges; i++) {
    const double a = phi * i;
    const double b = phi * (i + 1);
    const double mid = phi * (i + 0.5);
    const QVector3D dirA(float(std::sin(a)), float(std::cos(a)), 0);
    const QVector3D dirB(float(std::sin(b)), float(std::cos(b)), 0);
    const QVector3D nOut(float(std::sin(mid)), float(std::cos(mid)), 0);

    // Shaft wall (0 .. shaftLen).
    const QVector3D s_a0 = dirA * radius;
    const QVector3D s_b0 = dirB * radius;
    const QVector3D s_a1 = s_a0 + QVector3D(0, 0, shaftLen);
    const QVector3D s_b1 = s_b0 + QVector3D(0, 0, shaftLen);
    mb.quad(s_a0, s_b0, s_b1, s_a1, nOut);
    // Shaft base cap (z=0, facing -Z).
    mb.tri(QVector3D(0, 0, 0), s_b0, s_a0, QVector3D(0, 0, -1), QVector3D(0, 0, -1), QVector3D(0, 0, -1));

    // Head: cone base ring at z=shaftLen (radius headRadius) up to apex at z=length.
    const QVector3D h_a = dirA * headRadius + QVector3D(0, 0, shaftLen);
    const QVector3D h_b = dirB * headRadius + QVector3D(0, 0, shaftLen);
    const QVector3D apex(0, 0, length);
    // Cone side normal: blend of radial and the slope toward the apex.
    const float slope = (headLength > 1e-6f) ? headRadius / headLength : 0.0f;
    const QVector3D coneN = QVector3D(nOut.x(), nOut.y(), slope).normalized();
    mb.tri(h_a, h_b, apex, coneN, coneN, coneN);
    // Head base cap (facing -Z).
    mb.tri(QVector3D(0, 0, shaftLen), h_b, h_a, QVector3D(0, 0, -1), QVector3D(0, 0, -1), QVector3D(0, 0, -1));
  }
  commit(this, mb);
}

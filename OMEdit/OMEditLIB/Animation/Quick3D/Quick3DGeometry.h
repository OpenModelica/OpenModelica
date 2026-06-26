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

#ifndef QUICK3DGEOMETRY_H
#define QUICK3DGEOMETRY_H

#include <QtQuick3D/QQuick3DGeometry>

/*
 * Procedural meshes for the shapes Qt Quick 3D has no built-in primitive for
 * (hollow pipe, coil spring, arrow) — public QQuick3DGeometry only, no private
 * headers. Geometry is emitted in the Modelica/OSG convention: along local +Z
 * from 0 to length, in real units, so the body transform alone places it (no
 * extra scale/rotate, unlike the centred Y-axis built-in primitives). Mirrors
 * the OSG builders in ExtraShapes.cpp (Pipecylinder/Spring). Lit with per-vertex
 * normals; the caller renders these double-sided so triangle winding is moot.
 */
class Quick3DGeometry : public QQuick3DGeometry
{
public:
  explicit Quick3DGeometry(QObject* parent = nullptr);

  void buildPipe(float innerRadius, float outerRadius, float length);
  void buildSpring(float coilRadius, float wireRadius, float windings, float length);
  void buildArrow(float radius, float length, float headRadius, float headLength);
};

#endif // QUICK3DGEOMETRY_H

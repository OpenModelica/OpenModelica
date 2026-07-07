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

#ifndef ANIMATIONMATH_H
#define ANIMATIONMATH_H

#include <cstring>

#include <QVector3D>

/*
 * Backend-neutral math types for the animation data model, replacing the
 * osg math types it used to carry (osg::Vec3f / osg::Matrix3 / osg::Matrix).
 * Conventions match the previous osg behavior exactly so the OSG renderer is
 * numerically unchanged: Vec3 == QVector3D; Mat3 is a row-major flat 3x3 whose
 * default is the zero matrix (as osg::Matrix3()); Mat4 is a 4x4 in osg's
 * row-vector convention (v' = v * M, translation in row 3) whose default is the
 * identity (as osg::Matrixd()). The renderer reconstructs its native matrix
 * type from Mat4::ptr() (row-major), so no rotation decomposition lives here.
 */

using Vec3 = QVector3D;

struct Mat3
{
  float m[9];
  Mat3() { std::memset(m, 0, sizeof(m)); }
  Mat3(float a00, float a01, float a02,
       float a10, float a11, float a12,
       float a20, float a21, float a22)
  {
    m[0] = a00; m[1] = a01; m[2] = a02;
    m[3] = a10; m[4] = a11; m[5] = a12;
    m[6] = a20; m[7] = a21; m[8] = a22;
  }
  float& operator[](int i) { return m[i]; }
  float operator[](int i) const { return m[i]; }
};

struct Mat4
{
  double m[16];
  Mat4() { std::memset(m, 0, sizeof(m)); m[0] = m[5] = m[10] = m[15] = 1.0; }
  double& operator()(int row, int col) { return m[row * 4 + col]; }
  double operator()(int row, int col) const { return m[row * 4 + col]; }
  Vec3 getTrans() const { return Vec3(float(m[12]), float(m[13]), float(m[14])); }
  const double* ptr() const { return m; }
};

#endif // ANIMATIONMATH_H

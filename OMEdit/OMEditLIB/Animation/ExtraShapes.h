/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
/*
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#ifndef EXTRASHAPES_H
#define EXTRASHAPES_H

#include "Visualization.h"

#include <QOpenGLContext> // must be included before OSG headers

#include <osg/Node>
#include <osg/Group>
#include <osg/Geode>
#include <osg/Geometry>
#include <osg/Shape>

#include <QTextStream>
#include <QFile>

#include <unordered_map>

// TODO: Support is missing for the following shape types:
//  - beam,
//  - gearwheel.
// They are currently replaced by a capsule.
// In addition, the extra parameter is not always considered, in particular for cone and cylinder shapes.
// See documentation of Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape model.
// Also, the spring shape is implemented but has an undesired torsion near the end of each winding,
// and it should be drawn with more facets for a nicer animation
// (moreover, it misses normals and texture coordinates).

class Pipecylinder : public osg::Geometry
{
public:
  Pipecylinder(float rI, float rO, float l);
  ~Pipecylinder() {};
};

class Spring : public osg::Geometry
{
public:
  Spring(float r, float rCoil, float nWindings,  float l);
  ~Spring() {};
private:
  osg::Vec3f getNormal(osg::Vec3f vec, float length = 1);
  osg::Vec3f rotateX(osg::Vec3f vec, float phi);
  osg::Vec3f rotateY(osg::Vec3f vec, float phi);
  osg::Vec3f rotateZ(osg::Vec3f vec, float phi);
  osg::Vec3f rotateArbitraryAxis_expensive(osg::Vec3f vec, osg::Vec3f axis, float phi);
  osg::Vec3f rotateArbitraryAxis(osg::Vec3f vec, osg::Vec3f axis, float phi);
  float angleBetweenVectors(osg::Vec3f vec1, osg::Vec3f vec2);

  osg::Vec3Array* mpOuterVertices;
  osg::Vec3Array* mpSplineVertices;
};

class DXF3dFace
{
public:
  DXF3dFace();
  ~DXF3dFace();
  void dumpDXF3DFace();
  QString fill3dFace(QTextStream* stream);
  osg::Vec3f calcNormal();

public:
  osg::Vec3 vec1;
  osg::Vec3 vec2;
  osg::Vec3 vec3;
  osg::Vec3 vec4;
  std::string layer;
  int colorCode;
  osg::Vec4f color;
};

class DXFile : public osg::Geometry
{
public:
  DXFile(std::string filename);
  ~DXFile() = default;

public:
  std::string fileName;
};

template<typename T>
struct std::hash<const osg::ref_ptr<T>> {
  std::size_t operator()(const osg::ref_ptr<T>& ref) const {
    return reinterpret_cast<std::uintptr_t>(ref.get());
  }
};

class CADFile : public osg::Group
{
public:
  CADFile(osg::Node* subgraph);
  ~CADFile() = default;
  void scaleVertices(osg::Geode& geode, bool scaling, float scaleX, float scaleY, float scaleZ);

private:
  std::unordered_map<const osg::ref_ptr<osg::Geometry>, osg::ref_ptr<osg::Vec3Array>> unscaledGeometryVertices;

  friend class CADVisitor;
};

class CADVisitor : public osg::NodeVisitor
{
public:
  CADVisitor(CADFile* cadFile);
  ~CADVisitor() {cadFile.release();}
  void apply(osg::Geode& geode) override;

private:
  osg::ref_ptr<CADFile> cadFile;
};

#endif //end EXTRASHAPES_H

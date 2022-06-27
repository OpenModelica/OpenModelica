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
#ifndef SHAPES_H
#define SHAPES_H

#include <iostream>

#include "util/read_matlab4.h"
#include "util/read_csv.h"
#include "rapidxml.hpp"
#include <osg/Vec3f>
#include <osg/Matrix>
#include <osg/Uniform>

#include <QColor>

class ShapeObjectAttribute
{
 public:
  ShapeObjectAttribute();
  ShapeObjectAttribute(float value);
  ~ShapeObjectAttribute() = default;
  std::string getValueString() const;
  void setConstValue(float e){exp=e, isConst=true;}
 public:
  bool isConst;
  float exp;
  std::string cref;
  unsigned int fmuValueRef;
};

enum class stateSetAction {update, modify};

class ShapeObject
{
 public:
  ShapeObject();
  ~ShapeObject() = default;
  ShapeObject(const ShapeObject&) = default;
  ShapeObject& operator=(const ShapeObject&) = default;
  void dumpVisAttributes() const;
  void setTransparency(float transp) {mTransparent = transp;}
  float getTransparency() {return mTransparent;}
  void setTextureImagePath(std::string imagePath) {mTextureImagePath = imagePath;}
  std::string getTextureImagePath() {return mTextureImagePath;}
  void setColor(QColor col) {_color[0].setConstValue(col.red());
                             _color[1].setConstValue(col.green());
                             _color[2].setConstValue(col.blue());}
  QColor getColor() {return QColor(_color[0].exp, _color[1].exp, _color[2].exp);}
  void setStateSetAction(stateSetAction action) {mStateSetAction = action;}
  stateSetAction getStateSetAction() {return mStateSetAction;}
 public:
  std::string _id;
  std::string _type;
  std::string _fileName;
  ShapeObjectAttribute _length;
  ShapeObjectAttribute _width;
  ShapeObjectAttribute _height;
  ShapeObjectAttribute _r[3];
  ShapeObjectAttribute _rShape[3];
  ShapeObjectAttribute _lDir[3];
  ShapeObjectAttribute _wDir[3];
  ShapeObjectAttribute _color[3];
  ShapeObjectAttribute _T[9];
  ShapeObjectAttribute _specCoeff;
  osg::Matrix _mat;
  ShapeObjectAttribute _extra;
private:
  float mTransparent;
  std::string mTextureImagePath;
  stateSetAction mStateSetAction;
};

struct rAndT
{
    rAndT()
            : _r(osg::Vec3f()),
              _T(osg::Matrix3())
    {
    }
    osg::Vec3f _r;
    osg::Matrix3 _T;
};

struct Directions
{
    Directions()
            : _lDir(osg::Vec3f()),
              _wDir(osg::Vec3f())
    {
    }
    osg::Vec3f _lDir;
    osg::Vec3f _wDir;
};

ShapeObjectAttribute getObjectAttributeForNode(const rapidxml::xml_node<>* node);
//double getShapeAttrFMU(const char* attr, rapidxml::xml_node<>* node, double time/*, fmi1_import_t* fmu*/);
unsigned int numShapes(rapidxml::xml_node<>* rootNode);



#endif

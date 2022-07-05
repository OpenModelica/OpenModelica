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

#ifndef ABSTRACTVISUALIZER_H
#define ABSTRACTVISUALIZER_H

#include <iostream>

#include "rapidxml.hpp"

#include <QOpenGLContext> // must be included before OSG headers

#include <osg/Vec3f>
#include <osg/Matrix>
#include <osg/Uniform>

#include <QColor>

enum class VisualizerType {shape, vector, surface};

enum class StateSetAction {update, modify};

std::string operator+(const std::string& st, const VisualizerType type);

std::ostream& operator<<(std::ostream& os, const VisualizerType type);

std::ostream& operator<<(std::ostream& os, const StateSetAction action);

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

class VisualizerAttribute
{
public:
  VisualizerAttribute();
  VisualizerAttribute(const float value);
  virtual ~VisualizerAttribute() = default;
  virtual std::string getValueString() const;
  virtual void setConstValue(const float value) {isConst = true, exp = value;}
public:
  bool isConst;
  float exp;
  std::string cref;
  unsigned int fmuValueRef;
};

class AbstractVisualizerObject
{
public:
  AbstractVisualizerObject(const VisualizerType type);
  virtual ~AbstractVisualizerObject() = 0;
  virtual void dumpVisualizerAttributes() const;
  virtual bool isShape() const final {return mVisualizerType == VisualizerType::shape;}
  virtual bool isVector() const final {return mVisualizerType == VisualizerType::vector;}
  virtual bool isSurface() const final {return mVisualizerType == VisualizerType::surface;}
  virtual VisualizerType getVisualizerType() const final {return mVisualizerType;}
  virtual StateSetAction getStateSetAction() const final {return mStateSetAction;}
  virtual void setStateSetAction(const StateSetAction action) final {mStateSetAction = action;}
  virtual std::string getTextureImagePath() const final {return mTextureImagePath;}
  virtual void setTextureImagePath(const std::string texture) final {mTextureImagePath = texture;}
  virtual float getTransparency() const final {return mTransparency;}
  virtual void setTransparency(const float transparency) final {mTransparency = transparency;}
  virtual QColor getColor() const {return QColor(_color[0].exp, _color[1].exp, _color[2].exp);}
  virtual void setColor(const QColor color) {_color[0].setConstValue(color.red()),
                                             _color[1].setConstValue(color.green()),
                                             _color[2].setConstValue(color.blue());}
private:
  VisualizerType mVisualizerType;
  StateSetAction mStateSetAction;
  std::string mTextureImagePath;
  float mTransparency;
public:
  std::string _id;
  osg::Matrix _mat;
  VisualizerAttribute _T[9];
  VisualizerAttribute _r[3];
  VisualizerAttribute _color[3];
  VisualizerAttribute _specCoeff;
};

VisualizerAttribute getVisualizerAttributeForNode(const rapidxml::xml_node<>* node);

#endif

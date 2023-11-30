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

#include <string>
#include <iostream>

#include <QOpenGLContext> // must be included before OSG headers
#include <QColor>

#include <osg/Vec3f>
#include <osg/Matrix>
#include <osg/Uniform>
#include <osg/Transform>

#include "rapidxml.hpp"

enum class VisualizerType {shape, vector, surface};

enum class StateSetAction {update, modify};

std::string operator+(const std::string& st, const VisualizerType type);

std::ostream& operator<<(std::ostream& os, const VisualizerType type);

std::ostream& operator<<(std::ostream& os, const StateSetAction action);

std::ostream& operator<<(std::ostream& os, const QColor color);

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

class AbstractVisualProperties;

template<typename type>
class VisualProperty
{
public:
  using Type = type;
  VisualProperty() {reset();}
  virtual ~VisualProperty() = default;
protected:
  virtual Type getProperty() const {return mProperty;}
public:
  virtual bool custom() const {return mCustom;}
  virtual Type get() const {return mCustom ? mProperty : getProperty();}
  virtual void set(const Type& rProperty) {mCustom = true, mProperty = rProperty;}
  virtual void reset() {mCustom = false, mProperty = Type();}
  virtual void parent(const AbstractVisualProperties* pParent) final {mpParent = pParent;}
protected:
  const AbstractVisualProperties* mpParent;
private:
  Type mProperty;
  bool mCustom;
};

class AbstractVisualProperties
{
public:
  using Color = VisualProperty<QColor>;
  using Specular = VisualProperty<float>;
  using Transparency = VisualProperty<float>;
  using TextureImagePath = VisualProperty<std::string>;
  AbstractVisualProperties() {}
  virtual ~AbstractVisualProperties() = default;
  virtual void resetVisualProperties() = 0;
  virtual Color& getColor() = 0;
  virtual Specular& getSpecular() = 0;
  virtual Transparency& getTransparency() = 0;
  virtual TextureImagePath& getTextureImagePath() = 0;
};

template<typename VisualizerObject>
class VisualProperties : public AbstractVisualProperties
{
private:
  class Color final : public AbstractVisualProperties::Color
  { protected: virtual Type getProperty() const override final; };
  class Specular final : public AbstractVisualProperties::Specular
  { protected: virtual Type getProperty() const override final; };
  class Transparency final : public AbstractVisualProperties::Transparency
  { protected: virtual Type getProperty() const override final; };
  class TextureImagePath final : public AbstractVisualProperties::TextureImagePath
  { protected: virtual Type getProperty() const override final; };
public:
  VisualProperties() noexcept
  {
    setParent();
  }
  VisualProperties(VisualProperties&& rProperties) noexcept
  {
    copyProperties(rProperties);
    setParent();
  }
  VisualProperties(const VisualProperties& rProperties) noexcept
  {
    copyProperties(rProperties);
    setParent();
  }
  VisualProperties& operator=(VisualProperties&& rProperties) noexcept
  {
    copyProperties(rProperties);
    setParent();
    return *this;
  }
  VisualProperties& operator=(const VisualProperties& rProperties) noexcept
  {
    copyProperties(rProperties);
    setParent();
    return *this;
  }
  virtual ~VisualProperties() = default;
private:
  virtual void copyProperties(const VisualProperties& rProperties) final
  {
    mColor = rProperties.mColor;
    mSpecular = rProperties.mSpecular;
    mTransparency = rProperties.mTransparency;
    mTextureImagePath = rProperties.mTextureImagePath;
  }
  virtual void setParent() final
  {
    mColor.parent(this);
    mSpecular.parent(this);
    mTransparency.parent(this);
    mTextureImagePath.parent(this);
  }
public:
  virtual void resetVisualProperties() override final
  {
    mColor.reset();
    mSpecular.reset();
    mTransparency.reset();
    mTextureImagePath.reset();
  }
  virtual Color& getColor() override final {return mColor;}
  virtual Specular& getSpecular() override final {return mSpecular;}
  virtual Transparency& getTransparency() override final {return mTransparency;}
  virtual TextureImagePath& getTextureImagePath() override final {return mTextureImagePath;}
protected:
  Color mColor;
  Specular mSpecular;
  Transparency mTransparency;
  TextureImagePath mTextureImagePath;
};

class ShapeObject;
class VectorObject;
typedef void SurfaceObject;

class AbstractVisualizerObject
{
public:
  AbstractVisualizerObject(const VisualizerType type);
  virtual ~AbstractVisualizerObject() = 0;
  virtual void dumpVisualizerAttributes();
  virtual AbstractVisualProperties* getVisualProperties() {return nullptr;}
  virtual ShapeObject* asShape() {return nullptr;}
  virtual VectorObject* asVector() {return nullptr;}
  virtual SurfaceObject* asSurface() {return nullptr;}
  virtual bool isShape() const final {return mVisualizerType == VisualizerType::shape;}
  virtual bool isVector() const final {return mVisualizerType == VisualizerType::vector;}
  virtual bool isSurface() const final {return mVisualizerType == VisualizerType::surface;}
  virtual VisualizerType getVisualizerType() const final {return mVisualizerType;}
  virtual StateSetAction getStateSetAction() const final {return mStateSetAction;}
  virtual void setStateSetAction(const StateSetAction action) final {mStateSetAction = action;}
  virtual osg::ref_ptr<osg::Transform> getTransformNode() const final {return mTransformNode;}
  virtual void setTransformNode(const osg::ref_ptr<osg::Transform> transform) final {mTransformNode = transform;}
private:
  VisualizerType mVisualizerType;
  StateSetAction mStateSetAction;
  osg::ref_ptr<osg::Transform> mTransformNode;
public:
  std::string _id;
  osg::Matrix _mat;
  VisualizerAttribute _T[9];
  VisualizerAttribute _r[3];
  VisualizerAttribute _color[3];
  VisualizerAttribute _specCoeff;
};

template<typename VisualizerObject>
class AbstractVisualizerObjectWithVisualProperties : public AbstractVisualizerObject, public VisualProperties<VisualizerObject>
{
public:
  AbstractVisualizerObjectWithVisualProperties(const VisualizerType type);
  virtual ~AbstractVisualizerObjectWithVisualProperties() = 0;
  virtual void dumpVisualizerAttributes() override;
  virtual AbstractVisualProperties* getVisualProperties() override final {return this;}
};

VisualizerAttribute getVisualizerAttributeForNode(const rapidxml::xml_node<>* node);

#endif

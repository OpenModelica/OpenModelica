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

#include "AbstractVisualizer.h"

std::string operator+(const std::string& st, const VisualizerType type)
{
  switch (type)
  {
    case VisualizerType::shape:
      return st + "Shape";
    case VisualizerType::vector:
      return st + "Vector";
    case VisualizerType::surface:
      return st + "Surface";
    default:
      return st;
  }
}

std::ostream& operator<<(std::ostream& os, const VisualizerType type)
{
  switch (type)
  {
    case VisualizerType::shape:
      return os << "shape";
    case VisualizerType::vector:
      return os << "vector";
    case VisualizerType::surface:
      return os << "surface";
    default:
      return os;
  }
}

std::ostream& operator<<(std::ostream& os, const StateSetAction action)
{
  switch (action)
  {
    case StateSetAction::update:
      return os << "update";
    case StateSetAction::modify:
      return os << "modify";
    default:
      return os;
  }
}

VisualizerAttribute::VisualizerAttribute()
    : isConst(true),
      exp(0.0),
      cref(""),
      fmuValueRef(0)
{
}

VisualizerAttribute::VisualizerAttribute(const float value)
    : isConst(true),
      exp(value),
      cref(""),
      fmuValueRef(0)
{
}

std::string VisualizerAttribute::getValueString() const
{
  return std::to_string(exp) + " (" + std::to_string(fmuValueRef) + ") " + std::to_string(isConst);
}

AbstractVisualizerObject::AbstractVisualizerObject(const VisualizerType type)
    : mVisualizerType(type),
      mStateSetAction(StateSetAction::update),
      mTransformNode(nullptr),
      mTextureImagePath(""),
      mTransparency(0.0),
      _id(""),
      _mat(osg::Matrix(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)),
      _specCoeff(VisualizerAttribute(0.7))
{
  _T[0] = VisualizerAttribute(0.0);
  _T[1] = VisualizerAttribute(0.0);
  _T[2] = VisualizerAttribute(1.0);
  _T[3] = VisualizerAttribute(1.0);
  _T[4] = VisualizerAttribute(0.0);
  _T[5] = VisualizerAttribute(0.0);
  _T[6] = VisualizerAttribute(0.0);
  _T[7] = VisualizerAttribute(1.0);
  _T[8] = VisualizerAttribute(0.0);
  _r[0] = VisualizerAttribute(0.1);
  _r[1] = VisualizerAttribute(0.1);
  _r[2] = VisualizerAttribute(0.1);
  _color[0] = VisualizerAttribute(255.0);
  _color[1] = VisualizerAttribute(255.0);
  _color[2] = VisualizerAttribute(255.0);
}

AbstractVisualizerObject::~AbstractVisualizerObject()
{
  /* A function body is required for a pure virtual destructor. */
}

void AbstractVisualizerObject::dumpVisualizerAttributes() const
{
  std::cout << "id " << _id << std::endl;
  std::cout << "visualizerType " << mVisualizerType << std::endl;
  std::cout << "stateSetAction " << mStateSetAction << std::endl;
  std::cout << "textureImagePath " << mTextureImagePath << std::endl;
  std::cout << "transparency " << mTransparency << std::endl;
  std::cout << "color " << _color[0].getValueString() << " , " << _color[1].getValueString() << " , " << _color[2].getValueString() << std::endl;
  std::cout << "specCoeff " << _specCoeff.getValueString() << std::endl;
  std::cout << "mat " << _mat(0, 0) << " , " << _mat(0, 1) << " , " << _mat(0, 2) << " , " << _mat(0, 3) << std::endl;
  std::cout << "    " << _mat(1, 0) << " , " << _mat(1, 1) << " , " << _mat(1, 2) << " , " << _mat(1, 3) << std::endl;
  std::cout << "    " << _mat(2, 0) << " , " << _mat(2, 1) << " , " << _mat(2, 2) << " , " << _mat(2, 3) << std::endl;
  std::cout << "    " << _mat(3, 0) << " , " << _mat(3, 1) << " , " << _mat(3, 2) << " , " << _mat(3, 3) << std::endl;
  std::cout << "T " << _T[0].getValueString() << " , " << _T[1].getValueString() << " , " << _T[2].getValueString() << std::endl;
  std::cout << "  " << _T[3].getValueString() << " , " << _T[4].getValueString() << " , " << _T[5].getValueString() << std::endl;
  std::cout << "  " << _T[6].getValueString() << " , " << _T[7].getValueString() << " , " << _T[8].getValueString() << std::endl;
  std::cout << "r " << _r[0].getValueString() << " , " << _r[1].getValueString() << " , " << _r[2].getValueString() << std::endl;
}

VisualizerAttribute getVisualizerAttributeForNode(const rapidxml::xml_node<>* node)
{
  VisualizerAttribute oa;
  if (strcmp("cref", node->name()) == 0) {
    oa.cref = std::string(node->value());
    oa.isConst = false;
  } else if (strcmp("bconst", node->name()) == 0) {
    oa.exp = (strcmp("true", node->value()) == 0);
    oa.isConst = true;
  } else if (strcmp("enum", node->name()) == 0) {
    oa.exp = std::strtol(node->value(), nullptr, 0);
    oa.isConst = true;
  } else if (strcmp("exp", node->name()) == 0) {
    oa.exp = std::strtof(node->value(), nullptr);
    oa.isConst = true;
  }
  return oa;
}

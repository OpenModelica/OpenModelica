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

#include "Shapes.h"

ShapeObjectAttribute::ShapeObjectAttribute()
    : isConst(true),
      exp(0.0),
      cref("NONE"),
      fmuValueRef(0)
{
}

ShapeObjectAttribute::ShapeObjectAttribute(float value)
    : isConst(true),
      exp(value),
      cref("NONE"),
      fmuValueRef(0)
{
}

std::string ShapeObjectAttribute::getValueString() const
{
  return std::to_string(exp) + "  (" + std::to_string(fmuValueRef) + ") " + std::to_string(isConst) + " ";
}


ShapeObject::ShapeObject()
    : _id("noID"),
      _type("box"),
      _fileName("noFile"),
      _length(ShapeObjectAttribute(0.1)),
      _width(ShapeObjectAttribute(0.1)),
      _height(ShapeObjectAttribute(0.1)),
      _specCoeff(ShapeObjectAttribute(0.7)),
          _mat(osg::Matrix(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)),
          _extra(ShapeObjectAttribute(0.0)),
      mTransparent(0.0),
      mTextureImagePath(""),
      mStateSetAction(stateSetAction::update)

{
  _r[0] = ShapeObjectAttribute(0.1);
  _r[1] = ShapeObjectAttribute(0.1);
  _r[2] = ShapeObjectAttribute(0.1);
  _rShape[0] = ShapeObjectAttribute(0.0);
  _rShape[1] = ShapeObjectAttribute(0.0);
  _rShape[2] = ShapeObjectAttribute(0.0);
  _lDir[0] = ShapeObjectAttribute(1.0);
  _lDir[1] = ShapeObjectAttribute(0.0);
  _lDir[2] = ShapeObjectAttribute(0.0);
  _wDir[0] = ShapeObjectAttribute(0.0);
  _wDir[1] = ShapeObjectAttribute(1.0);
  _wDir[2] = ShapeObjectAttribute(0.0);
  _color[0] = ShapeObjectAttribute(255.0);
  _color[1] = ShapeObjectAttribute(255.0);
  _color[2] = ShapeObjectAttribute(255.0);
  _T[0] = ShapeObjectAttribute(0.0);
  _T[1] = ShapeObjectAttribute(0.0);
  _T[2] = ShapeObjectAttribute(1.0);
  _T[3] = ShapeObjectAttribute(1.0);
  _T[4] = ShapeObjectAttribute(0.0);
  _T[5] = ShapeObjectAttribute(0.0);
  _T[6] = ShapeObjectAttribute(0.0);
  _T[7] = ShapeObjectAttribute(1.0);
  _T[8] = ShapeObjectAttribute(0.0);
}

void ShapeObject::dumpVisAttributes() const
{
  std::cout << "id " << _id << std::endl;
  std::cout << "type " << _type << std::endl;
  std::cout << "fileName " << _fileName << std::endl;
  std::cout << "length " << _length.getValueString() << std::endl;
  std::cout << "width " << _width.getValueString() << std::endl;
  std::cout << "height " << _height.getValueString() << std::endl;
  std::cout << "lDir " << _lDir[0].getValueString() << ", " << _lDir[1].getValueString() << ", " << _lDir[2].getValueString() << ", " << std::endl;
  std::cout << "wDir " << _wDir[0].getValueString() << ", " << _wDir[1].getValueString() << ", " << _wDir[2].getValueString() << ", " << std::endl;
  std::cout << "r " << _r[0].getValueString() << ", " << _r[1].getValueString() << ", " << _r[2].getValueString() << ", " << std::endl;
  std::cout << "r_shape " << _rShape[0].getValueString() << ", " << _rShape[1].getValueString() << ", " << _rShape[2].getValueString() << ", " << std::endl;
  std::cout << "T0 " << _T[0].getValueString() << ", " << _T[1].getValueString() << ", " << _T[2].getValueString() << ", " << std::endl;
  std::cout << "   " << _T[3].getValueString() << ", " << _T[4].getValueString() << ", " << _T[5].getValueString() << ", " << std::endl;
  std::cout << "   " << _T[6].getValueString() << ", " << _T[7].getValueString() << ", " << _T[8].getValueString() << ", " << std::endl;
  std::cout << "color " << _color[0].getValueString() << ", " << _color[1].getValueString() << ", " << _color[2].getValueString() << ", " << std::endl;
  std::cout << "mat " << _mat(0, 0) << ", " << _mat(0, 1) << ", " << _mat(0, 2) << ", " << _mat(0, 3) << std::endl;
  std::cout << "    " << _mat(1, 0) << ", " << _mat(1, 1) << ", " << _mat(1, 2) << ", " << _mat(1, 3) << std::endl;
  std::cout << "    " << _mat(2, 0) << ", " << _mat(2, 1) << ", " << _mat(2, 2) << ", " << _mat(2, 3) << std::endl;
  std::cout << "    " << _mat(3, 0) << ", " << _mat(3, 1) << ", " << _mat(3, 2) << ", " << _mat(3, 3) << std::endl;
  std::cout << "extra " << _extra.getValueString() << std::endl;
  std::cout << "transparency " << mTransparent << std::endl;

}

/*
double getShapeAttrFMU(const char* attr, rapidxml::xml_node<>* node, double time, fmi1_import_t* fmu)
{
    rapidxml::xml_node<>* expNode = node->first_node(attr)->first_node();
    return evaluateExpressionFMU(expNode, time, fmu);
}
*/
ShapeObjectAttribute getObjectAttributeForNode(const rapidxml::xml_node<>* node)
{
    ShapeObjectAttribute oa;
    if (strcmp("exp", node->name()) == 0)
    {
        oa.exp = std::strtod(node->value(), nullptr);
        oa.cref = "NONE";
        oa.isConst = true;
    }
    else if (strcmp("cref", node->name()) == 0)
    {
        char* cref = node->value();
        oa.cref = std::string(cref);
        oa.exp = -1.0;
        oa.isConst = false;
    }
    return oa;
}


unsigned int numShapes(rapidxml::xml_node<>* rootNode)
{
    unsigned int num = 0;

    if (NULL == rootNode->first_node("shape"))
        return num;
    else
        for (rapidxml::xml_node<>* shapeNode = rootNode->first_node("shape"); shapeNode; shapeNode = shapeNode->next_sibling())
            ++num;

    return num;
}


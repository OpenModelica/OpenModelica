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

#include "Shape.h"

ShapeObject::ShapeObject()
    : AbstractVisualizerObject(VisualizerType::shape),
      _type(""),
      _fileName(""),
      _length(VisualizerAttribute(0.1)),
      _width(VisualizerAttribute(0.1)),
      _height(VisualizerAttribute(0.1)),
      _extra(VisualizerAttribute(0.0))
{
  _rShape[0] = VisualizerAttribute(0.0);
  _rShape[1] = VisualizerAttribute(0.0);
  _rShape[2] = VisualizerAttribute(0.0);
  _lDir[0] = VisualizerAttribute(1.0);
  _lDir[1] = VisualizerAttribute(0.0);
  _lDir[2] = VisualizerAttribute(0.0);
  _wDir[0] = VisualizerAttribute(0.0);
  _wDir[1] = VisualizerAttribute(1.0);
  _wDir[2] = VisualizerAttribute(0.0);
}

void ShapeObject::dumpVisualizerAttributes() const
{
  AbstractVisualizerObject::dumpVisualizerAttributes();
  std::cout << "type " << _type << std::endl;
  std::cout << "fileName " << _fileName << std::endl;
  std::cout << "rShape " << _rShape[0].getValueString() << " , " << _rShape[1].getValueString() << " , " << _rShape[2].getValueString() << std::endl;
  std::cout << "lDir " << _lDir[0].getValueString() << " , " << _lDir[1].getValueString() << " , " << _lDir[2].getValueString() << std::endl;
  std::cout << "wDir " << _wDir[0].getValueString() << " , " << _wDir[1].getValueString() << " , " << _wDir[2].getValueString() << std::endl;
  std::cout << "length " << _length.getValueString() << std::endl;
  std::cout << "width " << _width.getValueString() << std::endl;
  std::cout << "height " << _height.getValueString() << std::endl;
  std::cout << "extra " << _extra.getValueString() << std::endl;
}

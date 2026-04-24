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

/*
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#ifndef SHAPE_H
#define SHAPE_H

#include "AbstractVisualizer.h"

class ShapeObject final : public AbstractVisualizerObjectWithVisualProperties<ShapeObject>
{
public:
  ShapeObject();
  ~ShapeObject() = default;
  ShapeObject(const ShapeObject&) = default;
  ShapeObject& operator=(const ShapeObject&) = default;
  ShapeObject* asShape() override final {return this;}
  void dumpVisualizerAttributes() override;
public:
  std::string _type;
  std::string _fileName;
  VisualizerAttribute _rShape[3];
  VisualizerAttribute _lDir[3];
  VisualizerAttribute _wDir[3];
  VisualizerAttribute _length;
  VisualizerAttribute _width;
  VisualizerAttribute _height;
  VisualizerAttribute _extra;
};

#endif

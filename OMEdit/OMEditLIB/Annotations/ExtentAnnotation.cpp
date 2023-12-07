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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
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
#include "ExtentAnnotation.h"

ExtentAnnotation::ExtentAnnotation()
{
  clear();
}

ExtentAnnotation::ExtentAnnotation(const QVector<QPointF> &value)
{
  mValue = value;
  setExp();
}

void ExtentAnnotation::clear()
{
  mValue.replace(0, QPointF(-100.0, -100.0));
  mValue.replace(1, QPointF(100.0, 100.0));
}

ExtentAnnotation& ExtentAnnotation::operator= (const QVector<QPointF> &value)
{
  mValue = value;
  setExp();
  return *this;
}

bool ExtentAnnotation::operator==(const ExtentAnnotation &extent) const
{
  return mValue.at(0) == extent.at(0) && mValue.at(1) == extent.at(1);
}

FlatModelica::Expression ExtentAnnotation::toExp() const
{
  std::vector<FlatModelica::Expression> elems;

  for (auto &p: mValue) {
    std::vector<FlatModelica::Expression> point;
    point.emplace_back(p.x());
    point.emplace_back(p.y());
    elems.emplace_back(std::move(point));
  }

  return FlatModelica::Expression(std::move(elems));
}

void ExtentAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isArray()) {
    auto &elems = exp.elements();

    for (size_t i = 0u; i < std::min(elems.size(), decltype(elems.size()){2}); ++i) {
      auto &point = elems[i].elements();

      if (point.size() >= 2) {
        mValue.replace(i, QPointF(
          point[0].isNumber() ? point[0].realValue() : 0.0,
          point[1].isNumber() ? point[1].realValue() : 0.0
        ));
      }
    }
  }
}

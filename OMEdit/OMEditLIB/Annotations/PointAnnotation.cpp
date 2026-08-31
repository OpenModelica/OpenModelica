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

#include "PointAnnotation.h"

PointAnnotation::PointAnnotation()
{
  clear();
}

void PointAnnotation::clear()
{
  mValue = QPointF(0.0, 0.0);
}

PointAnnotation& PointAnnotation::operator= (const QPointF &value)
{
  mValue = value;
  setExp();
  return *this;
}

bool PointAnnotation::operator== (const QPointF &c) const
{
  return mValue == c;
}

bool PointAnnotation::operator!= (const QPointF &c) const
{
  return mValue != c;
}

FlatModelica::Expression PointAnnotation::toExp() const
{
  std::vector<FlatModelica::Expression> elems;
  elems.emplace_back(mValue.x());
  elems.emplace_back(mValue.y());
  return FlatModelica::Expression(std::move(elems));
}

void PointAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isArray()) {
    auto &elems = exp.elements();

    if (elems.size() >= 2) {
      mValue.setX(elems[0].isNumber() ? elems[0].realValue() : 0.0);
      mValue.setY(elems[1].isNumber() ? elems[1].realValue() : 0.0);
    }
  }
}


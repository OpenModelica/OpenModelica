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

#include "ColorAnnotation.h"

ColorAnnotation::ColorAnnotation()
{
  clear();
}

void ColorAnnotation::clear()
{
  mValue.setRgb(0, 0, 0);
}

ColorAnnotation& ColorAnnotation::operator= (const QColor &value)
{
  mValue = value;
  setExp();
  return *this;
}

bool ColorAnnotation::operator== (const QColor &c) const
{
  return mValue == c;
}

bool ColorAnnotation::operator!= (const QColor &c) const
{
  return mValue != c;
}

FlatModelica::Expression ColorAnnotation::toExp() const
{
  std::vector<FlatModelica::Expression> elems;
  elems.reserve(3);
  elems.emplace_back(FlatModelica::Expression(mValue.red()));
  elems.emplace_back(FlatModelica::Expression(mValue.green()));
  elems.emplace_back(FlatModelica::Expression(mValue.blue()));
  return FlatModelica::Expression(std::move(elems));
}

void ColorAnnotation::fromExp(const FlatModelica::Expression &exp)
{
  if (exp.isArray()) {
    auto &elems = exp.elements();

    if (elems.size() == 3) {
      int c[3];

      for (int i = 0; i < 3; ++i) {
        c[i] = elems[i].isNumber() ? elems[i].intValue() : 0;
      }

      mValue.setRgb(c[0], c[1], c[2]);
    }
  }
}

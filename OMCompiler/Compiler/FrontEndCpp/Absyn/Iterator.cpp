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

#include <ostream>

#include "Iterator.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description Absyn_ForIterator_ITERATOR__desc;

Iterator::Iterator(MetaModelica::Record value)
  : _name{value[0].toString()},
    _range{value[2].mapOptional<Expression>()}
{

}

MetaModelica::Value Iterator::toAbsyn() const noexcept
{
  return MetaModelica::Record{0, Absyn_ForIterator_ITERATOR__desc, {
    MetaModelica::Value{_name},
    MetaModelica::Option{},
    MetaModelica::Option{_range, [](const auto &e) { return e.toAbsyn(); }}
  }};
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream& os, const Iterator &iterator)
{
  os << iterator._name;

  if (iterator._range) {
    os << " in " << *iterator._range;
  }

  return os;
}

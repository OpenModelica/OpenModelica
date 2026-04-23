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

#include "Util.h"
#include "Expression.h"
#include "Subscript.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

constexpr int NOSUB = 0;
constexpr int SUBSCRIPT = 1;

extern record_description Absyn_Subscript_NOSUB__desc;
extern record_description Absyn_Subscript_SUBSCRIPT__desc;

Subscript::Subscript(MetaModelica::Record value)
  : _subscript{value.index() == SUBSCRIPT ? std::make_optional<Expression>(value[0]) : std::nullopt}
{

}

Subscript::~Subscript() noexcept = default;

MetaModelica::Value Subscript::toAbsyn() const noexcept
{
  if (_subscript) {
    return MetaModelica::Record(SUBSCRIPT, Absyn_Subscript_SUBSCRIPT__desc, {_subscript->toAbsyn()});
  }

  return MetaModelica::Record(NOSUB, Absyn_Subscript_NOSUB__desc);
}

MetaModelica::Value Subscript::toAbsynList(const std::vector<Subscript> &subs) noexcept
{
  return MetaModelica::List(subs, [](const auto &s) { return s.toAbsyn(); });
}

const std::optional<Expression>& Subscript::expression() const noexcept
{
  return _subscript;
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream& os, const Subscript &subscript)
{
  auto &e = subscript.expression();

  if (e) {
    os << *e;
  } else {
    os << ':';
  }

  return os;
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream& os, const std::vector<Subscript> &subscripts)
{
  if (!subscripts.empty()) {
    os << '[' << Util::printList(subscripts) << ']';
  }

  return os;
}

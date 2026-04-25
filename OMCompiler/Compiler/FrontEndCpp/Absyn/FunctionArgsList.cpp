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
#include "FunctionArgsList.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description Absyn_FunctionArgs_FUNCTIONARGS__desc;

extern record_description Absyn_NamedArg_NAMEDARG__desc;

FunctionArgsList::FunctionArgsList(MetaModelica::Record value)
  : _args{value[0].mapVector<Expression>()},
    _namedArgs{value[1].mapVector([](MetaModelica::Record v) {
      return NamedArg(v[0].toString(), v[1]); })
    }
{

}

std::unique_ptr<FunctionArgs::Base> FunctionArgsList::clone() const noexcept
{
  return std::make_unique<FunctionArgsList>(*this);
}

MetaModelica::Value FunctionArgsList::toAbsyn() const noexcept
{
  return MetaModelica::Record(FunctionArgs::FUNCTIONARGS, Absyn_FunctionArgs_FUNCTIONARGS__desc, {
    MetaModelica::List(_args, [](const auto &arg) { return arg.toAbsyn(); }),
    MetaModelica::List(_namedArgs, [](const auto &arg) {
      return MetaModelica::Record(0, Absyn_NamedArg_NAMEDARG__desc, {
        MetaModelica::Value(arg.first),
        arg.second.toAbsyn()
      });
    })
  });
}

namespace OpenModelica::Absyn
{
  std::ostream& operator<< (std::ostream& os, const FunctionArgsList::NamedArg &arg) {
    os << arg.first << '=' << arg.second;
    return os;
  }
}

void FunctionArgsList::print(std::ostream &os) const noexcept
{
  os << Util::printList(_args);
  if (!_args.empty() && !_namedArgs.empty()) os << ", ";
  os << Util::printList(_namedArgs);
}


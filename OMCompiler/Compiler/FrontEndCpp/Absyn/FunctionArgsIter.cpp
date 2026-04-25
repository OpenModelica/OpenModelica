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

#include "Util.h"
#include "Iterator.h"
#include "FunctionArgsIter.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description Absyn_FunctionArgs_FOR__ITER__FARG__desc;

extern record_description Absyn_ReductionIterType_COMBINE__desc;

FunctionArgsIter::FunctionArgsIter(MetaModelica::Record value)
  : _exp{value[0]},
    _iterators{value[2].mapVector<Iterator>()}
{

}

FunctionArgsIter::~FunctionArgsIter() = default;

std::unique_ptr<FunctionArgs::Base> FunctionArgsIter::clone() const noexcept
{
  return std::make_unique<FunctionArgsIter>(*this);
}

MetaModelica::Value FunctionArgsIter::toAbsyn() const noexcept
{
  static const MetaModelica::Record combineIterType{0, Absyn_ReductionIterType_COMBINE__desc};

  return MetaModelica::Record(FunctionArgs::FOR_ITER_FARG, Absyn_FunctionArgs_FOR__ITER__FARG__desc, {
    _exp.toAbsyn(),
    combineIterType,
    MetaModelica::List(_iterators, [](const auto &i) { return i.toAbsyn(); })
  });
}

void FunctionArgsIter::print(std::ostream &os) const noexcept
{
  os << _exp << " for " << Util::printList(_iterators);
}

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

#include "FunctionArgsList.h"
#include "FunctionArgsIter.h"
#include "FunctionArgs.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

std::unique_ptr<FunctionArgs::Base> function_args_from_mm(MetaModelica::Record value)
{
  if (value.index() == 0) {
    return std::make_unique<FunctionArgsList>(value);
  } else {
    return std::make_unique<FunctionArgsIter>(value);
  }
}

FunctionArgs::FunctionArgs(MetaModelica::Record value)
  : _impl{function_args_from_mm(value)}
{

}

FunctionArgs::FunctionArgs(const FunctionArgs &other) noexcept
  : _impl{other._impl->clone()}
{

}

FunctionArgs& FunctionArgs::operator= (const FunctionArgs &other) noexcept
{
  _impl = other._impl->clone();
  return *this;
}

MetaModelica::Value FunctionArgs::toAbsyn() const noexcept
{
  return _impl->toAbsyn();
}

void FunctionArgs::print(std::ostream &os) const noexcept
{
  return _impl->print(os);
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const FunctionArgs &args) noexcept
{
  args.print(os);
  return os;
}

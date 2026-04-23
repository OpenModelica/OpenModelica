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

#include "ElementVisitor.h"
#include "DefineUnit.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Element_DEFINEUNIT__desc;

DefineUnit::DefineUnit(MetaModelica::Record value)
  : Element(SourceInfo(value[4])),
    _name{value[0].toString()},
    _visibility{value[1]},
    _exp{value[2].toOptional<std::string>()},
    _weight{value[3].toOptional<double>()}
{

}

void DefineUnit::apply(ElementVisitor &visitor)
{
  visitor.visit(*this);
}

MetaModelica::Value DefineUnit::toSCode() const noexcept
{
  return MetaModelica::Record{Element::DEFINEUNIT, SCode_Element_DEFINEUNIT__desc, {
    MetaModelica::Value{_name},
    _visibility.toSCode(),
    MetaModelica::Option(_exp),
    MetaModelica::Option(_weight),
    info()
  }};
}

std::unique_ptr<Element> DefineUnit::clone() const noexcept
{
  return std::make_unique<DefineUnit>(*this);
}

void DefineUnit::print(std::ostream &os, Each) const noexcept
{
  os << "defineunit " << _name;

  if (_exp || _weight) {
    os << '(';
    if (_exp) os << *_exp;
    if (_weight) os << *_weight;
    os << ')';
  }
}

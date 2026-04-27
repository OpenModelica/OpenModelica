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
#include "Expression.h"
#include "Component.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Element_COMPONENT__desc;

Component::Component(MetaModelica::Record value)
  : Element(SourceInfo{value[7]}),
    _name{value[0].toString()},
    _prefixes{value[1]},
    _attributes{value[2]},
    _typeSpec{value[3]},
    _modifier{value[4]},
    _comment{value[5]},
    _condition{value[6].mapOptional<Expression>()}
{

}

Component::~Component() = default;

void Component::apply(ElementVisitor &visitor)
{
  visitor.visit(*this);
}

MetaModelica::Value Component::toSCode() const noexcept
{
  return MetaModelica::Record{Element::COMPONENT, SCode_Element_COMPONENT__desc, {
    MetaModelica::Value{_name},
    _prefixes.toSCode(),
    _attributes.toSCode(),
    _typeSpec.toAbsyn(),
    _modifier.toSCode(),
    _comment.toSCode(),
    MetaModelica::Option{_condition, [](const auto &c) { return c.toAbsyn(); }},
    info()
  }};
}

const std::string& Component::name() const noexcept
{
  return _name;
}

const ElementPrefixes& Component::prefixes() const noexcept
{
  return _prefixes;
}


const ElementAttributes& Component::attributes() const noexcept
{
  return _attributes;
}

const Comment& Component::comment() const noexcept
{
  return _comment;
}

std::unique_ptr<Element> Component::clone() const noexcept
{
  return std::make_unique<Component>(*this);
}

void Component::print(std::ostream &os, Each each) const noexcept
{
  _prefixes.print(os, each);
  os << _attributes << _typeSpec << ' ' << _name << _attributes.arrayDims() << _modifier;

  if (_condition) {
    os << " if " << *_condition;
  }
}

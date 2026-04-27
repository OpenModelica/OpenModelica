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
#include "Extends.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Element_EXTENDS__desc;

Extends::Extends(MetaModelica::Record value)
  : Element(SourceInfo{value[4]}),
    _baseClassPath{value[0]},
    _visibility{value[1]},
    _modifier{value[2]},
    _annotation{value[3].mapOptionalOrDefault<Annotation>()}
{

}

void Extends::apply(ElementVisitor &visitor)
{
  visitor.visit(*this);
}

MetaModelica::Value Extends::toSCode() const noexcept
{
  return MetaModelica::Record{Element::EXTENDS, SCode_Element_EXTENDS__desc, {
    _baseClassPath.toAbsyn(),
    _visibility.toSCode(),
    _modifier.toSCode(),
    _annotation.toSCodeOpt(),
    info()
  }};
}

std::unique_ptr<Element> Extends::clone() const noexcept
{
  return std::make_unique<Extends>(*this);
}

void Extends::print(std::ostream &os, Each) const noexcept
{
  os << _visibility.unparse() << "extends " << _baseClassPath << _modifier << _annotation;
}

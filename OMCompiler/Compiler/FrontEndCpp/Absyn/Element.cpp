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

#include "Import.h"
#include "Extends.h"
#include "Class.h"
#include "Component.h"
#include "DefineUnit.h"
#include "Element.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

Element::Element(SourceInfo info)
  : _info{std::move(info)}
{

}

std::unique_ptr<Element> Element::fromSCode(MetaModelica::Record value)
{
  switch (value.index()) {
    case Element::IMPORT:     return std::make_unique<Absyn::Import>(value);
    case Element::EXTENDS:    return std::make_unique<Absyn::Extends>(value);
    case Element::CLASS:      return std::make_unique<Absyn::Class>(value);
    case Element::COMPONENT:  return std::make_unique<Absyn::Component>(value);
    case Element::DEFINEUNIT: return std::make_unique<Absyn::DefineUnit>(value);
  }

  throw std::runtime_error("Element::Element: invalid record index");
}

Element::~Element() = default;

namespace OpenModelica::Absyn
{
  void swap(Element &first, Element &second) noexcept
  {
    using std::swap;
    swap(first._info, second._info);
  }

  std::ostream& operator<< (std::ostream &os, const Element &element) noexcept
  {
    element.print(os);
    return os;
  }
}


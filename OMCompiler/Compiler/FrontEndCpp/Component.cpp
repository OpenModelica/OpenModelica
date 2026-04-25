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

#include "Absyn/Component.h"
#include "Component.h"

using namespace OpenModelica;

extern record_description NFComponent_COMPONENT__DEF__desc;
extern record_description NFComponent_COMPONENT__desc;
extern record_description NFComponent_ITERATOR__desc;
extern record_description NFComponent_ENUM__LITERAL__desc;
extern record_description NFComponent_TYPE__ATTRIBUTE__desc;
extern record_description NFComponent_INVALID_COMPONENT__desc;
extern record_description NFComponent_WILD__desc;

constexpr int COMPONENT_DEF = 0;
constexpr int COMPONENT = 1;
constexpr int ITERATOR = 2;
constexpr int ENUM_LITERAL = 3;
constexpr int TYPE_ATTRIBUTE = 4;
constexpr int INVALID_COMPONENT = 5;
constexpr int WILD = 6;

extern record_description NFModifier_Modifier_NOMOD__desc;

Component::Component(Absyn::Component *definition)
  : _definition{definition}
{

}

ComponentDef::ComponentDef(Absyn::Component *definition)
  : Component(definition)
{

}

MetaModelica::Value ComponentDef::toNF() const noexcept
{
  static const MetaModelica::Record emptyMod(2, NFModifier_Modifier_NOMOD__desc, {});

  return MetaModelica::Record{COMPONENT_DEF, NFComponent_COMPONENT__DEF__desc, {
    _definition->toSCode(),
    emptyMod
  }};
}

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
#include "InstNode.h"
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

constexpr int COMPONENT_DEF_DEFINITION = 0;
constexpr int COMPONENT_DEF_MODIFIER = 1;

constexpr int COMPONENT_CLASS_INST = 0;
constexpr int COMPONENT_TY = 1;
constexpr int COMPONENT_BINDING = 2;
constexpr int COMPONENT_CONDITION = 3;
constexpr int COMPONENT_ATTRIBUTES = 4;
constexpr int COMPONENT_COMMENT = 5;
constexpr int COMPONENT_STATE = 6;
constexpr int COMPONENT_INFO = 7;

extern record_description NFModifier_Modifier_NOMOD__desc;

Component::Component(Absyn::Component *definition)
  : _definition{definition}
{

}

Component::~Component() = default;

bool Component::isExpandableConnector() const noexcept
{
  return connectorType().isExpandable();
}

ComponentDef::ComponentDef(MetaModelica::Record value)
  : Component{nullptr}, // TODO: Implement
    _modifier{value[COMPONENT_DEF_MODIFIER]}
{

}

ComponentDef::ComponentDef(Absyn::Component *definition)
  : Component(definition)
{

}

std::unique_ptr<Component> ComponentDef::clone() const
{
  return std::make_unique<ComponentDef>(*this);
}

std::unique_ptr<Component> Component::fromMM(MetaModelica::Record value)
{
  switch (value.index()) {
    case COMPONENT_DEF: return std::make_unique<ComponentDef>(value);
    case COMPONENT:     return std::make_unique<NormalComponent>(value);
    default:            return std::make_unique<MMComponent>(value);
  }
}

MetaModelica::Value ComponentDef::toNF() const noexcept
{
  static const MetaModelica::Record emptyMod(2, NFModifier_Modifier_NOMOD__desc, {});

  return MetaModelica::Record{COMPONENT_DEF, NFComponent_COMPONENT__DEF__desc, {
    _definition->toSCode(),
    emptyMod
  }};
}

NormalComponent::NormalComponent(MetaModelica::Record value)
  : Component{nullptr}, // TODO: Implement
    _classInst{InstNode::getOwnedPtr(value[COMPONENT_CLASS_INST])},
    _ty{value[COMPONENT_TY]},
    _binding{value[COMPONENT_BINDING]},
    _condition{value[COMPONENT_CONDITION]},
    _attributes{value[COMPONENT_ATTRIBUTES]},
    _comment{nullptr}, //TODO: Implement
    _state{value[COMPONENT_STATE].toEnum<State>()},
    _info{value[COMPONENT_INFO]}
{

}

NormalComponent::NormalComponent(Absyn::Component *definition, std::unique_ptr<InstNode> classInst,
  Type ty, Binding binding, Binding condition, Attributes attributes, Absyn::Comment *comment, State state, SourceInfo info)
  : Component{definition},
    _classInst{std::move(classInst)},
    _ty{std::move(ty)},
    _binding{std::move(binding)},
    _condition{std::move(condition)},
    _attributes{std::move(attributes)},
    _comment{comment},
    _state{state},
    _info{info}
{

}

std::unique_ptr<Component> NormalComponent::clone() const
{
  return std::make_unique<NormalComponent>(_definition, _classInst->clone(), _ty, _binding, _condition, _attributes, _comment, _state, _info);
}

MetaModelica::Value NormalComponent::toNF() const noexcept
{
  return MetaModelica::Record{COMPONENT, NFComponent_COMPONENT__desc, {
    _classInst->toNF(),
    _ty,
    _binding.toNF(),
    _condition.toNF(),
    _attributes.toNF(),
    _comment ? _comment->toSCode() : Absyn::Comment::noCommentSCode(),
    MetaModelica::Value{_state},
    _info
  }};
}

const InstNode* NormalComponent::classInstance() const noexcept
{
  return _classInst.get();
}

InstNode* NormalComponent::classInstance() noexcept
{
  return _classInst.get();
}

const Type& NormalComponent::type() const noexcept
{
  if (_ty.isUnknown() && _classInst) {
    return _classInst->type();
  }

  return _ty;
}

ConnectorType NormalComponent::connectorType() const noexcept
{
  return _attributes.connectorType;
}

MMComponent::MMComponent(MetaModelica::Record value)
  : Component(nullptr), _value{value}
{

}

std::unique_ptr<Component> MMComponent::clone() const
{
  return std::make_unique<MMComponent>(_value);
}

MetaModelica::Value MMComponent::toNF() const noexcept
{
  return _value;
}

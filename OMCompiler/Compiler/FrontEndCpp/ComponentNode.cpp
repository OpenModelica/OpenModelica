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

#include <utility>

#include "Absyn/Component.h"
#include "Component.h"
#include "ComponentNode.h"

using namespace OpenModelica;

extern record_description NFInstNode_InstNode_COMPONENT__NODE__desc;

constexpr int NAME_INDEX = 0;
constexpr int DEFINITION_INDEX = 1;
constexpr int VISIBILITY_INDEX = 2;
constexpr int COMPONENT_INDEX = 3;
constexpr int PARENT_INDEX = 4;
constexpr int NODE_TYPE_INDEX = 5;

MMSharedCache<Component> ComponentNode::_cache;

ComponentNode::ComponentNode(MetaModelica::Record value)
  : _name{value[NAME_INDEX].toString()},
    _definition{nullptr},
    _visibility{value[VISIBILITY_INDEX]},
    // _component is initialized by initialize()
    _parent{InstNode::getReference(value[PARENT_INDEX])},
    // _nodeType is initialized by initialize()
    _mmCache{value}
{

}

ComponentNode::ComponentNode(Absyn::Component *definition, InstNode *parent)
  : ComponentNode(definition, parent, std::make_unique<NormalComponentType>())
{

}

ComponentNode::ComponentNode(Absyn::Component *definition, InstNode *parent,
  std::unique_ptr<InstNodeType> nodeType)
  : _name{definition ? definition->name() : ""},
    _definition{definition},
    _visibility{definition ? definition->prefixes().visibility() : Visibility::Public},
    _component{std::make_unique<ComponentDef>(definition)},
    _parent{parent},
    _nodeType{std::move(nodeType)}
{

}

ComponentNode::ComponentNode(std::string name, Absyn::Component *definition, Visibility visibility,
  std::unique_ptr<Component> _component, InstNode *parent, std::unique_ptr<InstNodeType> nodeType)
  : _name{name},
    _definition{definition},
    _visibility{visibility},
    _component{std::move(_component)},
    _parent{parent},
    _nodeType{std::move(nodeType)}
{

}

ComponentNode::~ComponentNode() = default;

std::unique_ptr<InstNode> ComponentNode::clone() const
{
  return std::make_unique<ComponentNode>(_name, _definition, _visibility,
    _component->clone(), _parent, _nodeType ? _nodeType->clone() : nullptr);
}

Path ComponentNode::scopePath() const
{
  if (_parent && !_parent->isRootClass()) {
    auto path = _parent->scopePath();
    path.pushBack(_name);
    return path;
  } else {
    return Path{_name};
  }
}

const Absyn::Element* ComponentNode::definition() const noexcept
{
  return _definition;
}

const InstNodeType* ComponentNode::nodeType() const noexcept
{
  return _nodeType.get();
}

void ComponentNode::setNodeType(std::unique_ptr<InstNodeType> nodeType) noexcept
{
  _nodeType = std::move(nodeType);
  _mmCache.reset();
}

void ComponentNode::setParent(InstNode *parent) noexcept
{
  _parent = parent;
}

const Class* ComponentNode::getClass() const noexcept
{
  if (_component) {
    auto cls_inst = _component->classInstance();
    if (cls_inst) return cls_inst->getClass();
  }

  return nullptr;
}

Class* ComponentNode::getClass() noexcept
{
  return const_cast<Class*>(std::as_const(*this).getClass());
}

const Type& ComponentNode::type() const noexcept
{
  return _component ? _component->type() : Type::UnknownType;
}

bool ComponentNode::isExpandableConnector() const noexcept
{
  return _component->isExpandableConnector();
}

MetaModelica::Value ComponentNode::toNF() const
{
  // Nodes need to be cached to deal with the cyclical dependencies between nodes.
  if (!_mmCache) {
    auto comp_ptr = MetaModelica::Pointer{};

    // Create a MetaModelica record for the node.
    auto rec = MetaModelica::Record{InstNode::COMPONENT_NODE, NFInstNode_InstNode_COMPONENT__NODE__desc, {
      MetaModelica::Value{_name},
      _definition->toSCode(),
      _visibility.toSCode(),
      comp_ptr,
      InstNode::emptyMMNode(),
      MetaModelica::Value{static_cast<int64_t>(0)}
    }};

    // Set the cache.
    _mmCache = rec;

    // Set any of the record members that might depend on this node now that we have a cached value.
    comp_ptr.update(_component->toNF());
    if (_parent) rec.set(PARENT_INDEX, _parent->toNF());
    rec.set(NODE_TYPE_INDEX, _nodeType->toNF());
  }

  return *_mmCache;
}

void ComponentNode::initialize()
{
  if (_mmCache) {
    auto value = *_mmCache;
    _component = _cache.getOwnedPtr(value[COMPONENT_INDEX].toPointer().access());

    if (!_component) {
      throw std::runtime_error("no component");
    }
    //_nodeType = InstNodeType::fromNF(value[NODE_TYPE_INDEX]);
  }
}

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

#include "Absyn/Class.h"
#include "Class.h"
#include "ClassNode.h"

using namespace OpenModelica;

extern record_description NFInstNode_InstNode_CLASS__NODE__desc;

extern record_description NFClass_NOT__INSTANTIATED__desc;

constexpr int NAME_INDEX = 0;
constexpr int DEFINITION_INDEX = 1;
constexpr int VISIBILITY_INDEX = 2;
constexpr int CLS_INDEX = 3;
constexpr int CACHES_INDEX = 4;
constexpr int PARENT_SCOPE_INDEX = 5;
constexpr int NODE_TYPE_INDEX = 6;

extern record_description NFInstNode_CachedData_NO__CACHE__desc;

ClassNode::ClassNode(Absyn::Class *cls, InstNode *parent)
  : ClassNode(cls, parent, std::make_unique<NormalClassType>())
{

}

ClassNode::ClassNode(Absyn::Class *cls, InstNode *parent, std::unique_ptr<InstNodeType> nodeType)
  : _name{cls ? cls->name() : ""},
    _definition{cls},
    _visibility{cls ? cls->prefixes().visibility() : Visibility::Public},
    _parentScope{parent},
    _nodeType{std::move(nodeType)}
{

}

ClassNode::~ClassNode() = default;

const InstNodeType* ClassNode::nodeType() const noexcept
{
  return _nodeType.get();
}

void ClassNode::setNodeType(std::unique_ptr<InstNodeType> nodeType) noexcept
{
  _nodeType = std::move(nodeType);
  _mmCache.reset();
}

void ClassNode::partialInst()
{
  if (_cls) return;
  _cls = Class::fromAbsyn(*_definition, this);
  _mmCache.reset();
}

void ClassNode::expand()
{

}

void ClassNode::instantiate()
{

}

MetaModelica::Value ClassNode::toMetaModelica() const
{
  static const MetaModelica::Value noClass = MetaModelica::Record(0, NFClass_NOT__INSTANTIATED__desc);
  static const MetaModelica::Value noCache = MetaModelica::Record(0, NFInstNode_CachedData_NO__CACHE__desc);

  // Nodes need to be cached to deal with the cyclical dependencies between nodes.
  if (!_mmCache) {
    auto cls_ptr = MetaModelica::Pointer();

    // Create a MetaModelica record for the node.
    auto rec = MetaModelica::Record(InstNode::CLASS_NODE, NFInstNode_InstNode_CLASS__NODE__desc, {
      MetaModelica::Value(_name),
      _definition->toSCode(),
      _visibility.toSCode(),
      cls_ptr,
      MetaModelica::Array{3, noCache},
      InstNode::emptyMMNode(),
      MetaModelica::Value(static_cast<int64_t>(0))
    });

    // Set the cache.
    _mmCache = rec;

    // Set any of the record members that might depend on this node now that we have a cached value.
    cls_ptr.update(_cls ? _cls->toMetaModelica() : noClass);
    if (_parentScope) rec.set(PARENT_SCOPE_INDEX, _parentScope->toMetaModelica());
    rec.set(NODE_TYPE_INDEX, _nodeType->toMetaModelica());
  }

  return *_mmCache;
}

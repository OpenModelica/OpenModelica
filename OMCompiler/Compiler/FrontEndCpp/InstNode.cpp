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

#include <stdexcept>
#include <string>

#include "ComponentNode.h"
#include "ClassNode.h"
#include "NameNode.h"
#include "InstNode.h"

using namespace OpenModelica;

extern record_description NFInstNode_InstNode_EMPTY__NODE__desc;

MMCache<InstNode> InstNode::_cache;

MetaModelica::Value InstNode::emptyMMNode()
{
  static auto val = MetaModelica::Record{InstNode::EMPTY_NODE, NFInstNode_InstNode_EMPTY__NODE__desc, {}};
  return val;
}

std::unique_ptr<InstNode> InstNode::fromMM(MetaModelica::Record value)
{
  switch (value.index()) {
    case InstNode::CLASS_NODE:       return std::make_unique<ClassNode>(value);
    case InstNode::COMPONENT_NODE:   return std::make_unique<ComponentNode>(value);
    case InstNode::INNER_OUTER_NODE: throw std::runtime_error("node_from_mm: unimplemented INNER_OUTER_NODE");
    case InstNode::REF_NODE:         throw std::runtime_error("node_from_mm: unimplemented REF_NODE");
    case InstNode::NAME_NODE:        return std::make_unique<NameNode>(value);
    case InstNode::IMPLICIT_SCOPE:   throw std::runtime_error("node_from_mm: unimplemented IMPLICIT_SCOPE");
    case InstNode::ITERATOR_NODE:    throw std::runtime_error("node_from_mm: unimplemented ITERATOR_NODE");
    case InstNode::VAR_NODE:         throw std::runtime_error("node_from_mm: unimplemented VAR_NODE");
    case InstNode::EMPTY_NODE:       return nullptr;
  }

  throw std::runtime_error("InstNode::fromMM: unimplemented record index " + std::to_string(value.index()));
}

bool InstNode::isRootClass() const noexcept
{
  auto node_ty = nodeType();
  return node_ty && node_ty->isRootClass();
}

Path InstNode::scopePath() const
{
  return Path{name()};
}

// Converts a MetaModelica value to an InstNode and returns ownership of it.
std::unique_ptr<InstNode> InstNode::getOwnedPtr(MetaModelica::Record value)
{
  return _cache.getOwnedPtr(value);
}

std::vector<std::unique_ptr<InstNode>> InstNode::getOwnedPtrs(MetaModelica::Value value)
{
  return _cache.getOwnedPtrs(value);
}

// Converts a MetaModelica value to an InstNode and returns an observing pointer to it.
InstNode* InstNode::getReference(MetaModelica::Record value)
{
  return _cache.getReference(value);
}

std::vector<InstNode*> InstNode::getReferences(MetaModelica::Value value)
{
  return _cache.getReferences(value);
}

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

#include <sstream>
#include <ostream>
#include <algorithm>
#include <cassert>

#include "Util.h"
#include "InstNode.h"
#include "ComponentRef.h"

using namespace OpenModelica;

constexpr int CREF = 0;
constexpr int EMPTY = 1;
constexpr int WILD = 2;

constexpr int NODE_INDEX = 0;
constexpr int SUBSCRIPTS_INDEX = 1;
constexpr int TY_INDEX = 2;
constexpr int ORIGIN_INDEX = 3;
constexpr int REST_CREF_INDEX = 4;

extern record_description NFComponentRef_CREF__desc;
extern record_description NFComponentRef_EMPTY__desc;
extern record_description NFComponentRef_WILD__desc;

ComponentRef::Part::Part(MetaModelica::Record value)
  : node{InstNode::getReference(value[NODE_INDEX])},
    subscripts{value[SUBSCRIPTS_INDEX].mapVector<Subscript>()},
    ty{value[TY_INDEX]},
    origin{value[ORIGIN_INDEX].toEnum<Origin>()}
{

}

const std::string& ComponentRef::Part::name() const
{
  return node ? node->name() : ComponentRef::Part::wildcard;
}

std::string ComponentRef::Part::str() const
{
  if (node) {
    std::ostringstream ss;
    ss << node->name() << subscripts;
    return ss.str();
  } else {
    return wildcard;
  }
}

ComponentRef::ComponentRef() = default;

ComponentRef::ComponentRef(std::vector<ComponentRef::Part> parts)
  : _parts{std::move(parts)}
{

}

ComponentRef::ComponentRef(MetaModelica::Record value)
{
  MetaModelica::Record v = value;

  while (v.index() == CREF) {
    _parts.emplace_back(v);
    v = v[REST_CREF_INDEX];
  }

  if (v.index() == WILD) {
    _parts.emplace_back(nullptr, std::vector<Subscript>(), Type::Unknown, Origin::Absyn);
  }

  std::reverse(_parts.begin(), _parts.end());
}

ComponentRef::~ComponentRef() = default;

MetaModelica::Value ComponentRef::toNF() const
{
  if (!_parts.empty() && !_parts[0].node) {
    return MetaModelica::Record{WILD, NFComponentRef_WILD__desc, {}};
  } else {
    MetaModelica::Value v = MetaModelica::Record{EMPTY, NFComponentRef_EMPTY__desc, {}};

    for (const auto &part: _parts) {
      v = MetaModelica::Record{CREF, NFComponentRef_CREF__desc, {
        part.node->toNF(),
        MetaModelica::List{part.subscripts},
        part.ty,
        MetaModelica::Value{part.origin},
        v
      }};
    }

    return v;
  }
}

void ComponentRef::pushBack(Part part)
{
  _parts.emplace_back(std::move(part));
}

void ComponentRef::emplaceBack(InstNode *node, std::vector<Subscript> subscripts, Type ty, Origin origin)
{
  _parts.emplace_back(node, std::move(subscripts), std::move(ty), origin);
}

void ComponentRef::popBack()
{
  assert(!_parts.empty());
  _parts.pop_back();
}

std::string ComponentRef::str() const
{
  std::ostringstream ss;
  ss << *this;
  return ss.str();
}

std::size_t ComponentRef::hash() const noexcept
{
  std::size_t hash = 0;

  for (const auto &part: _parts) {
    if (part.node) {
      Util::hashCombine(hash, part.node->name());
      for (const auto &sub: part.subscripts) {
        Util::hashCombine(hash, sub);
      }
    } else {
      hash = '_';
    }
  }

  return hash;
}

void OpenModelica::swap(ComponentRef::Part &part1, ComponentRef::Part &part2) noexcept
{
  using std::swap;
  swap(part1.node, part2.node);
  swap(part1.subscripts, part2.subscripts);
  swap(part1.ty, part2.ty);
  swap(part1.origin, part2.origin);
}

bool OpenModelica::operator== (const ComponentRef::Part &part1, const ComponentRef::Part &part2) noexcept
{
  return (part1.node == part2.node ||
          (part1.node && part2.node && part1.node->name() == part2.node->name())) &&
         std::equal(part1.subscripts.begin(), part1.subscripts.end(),
                    part2.subscripts.begin(), part2.subscripts.end());
}

bool OpenModelica::operator== (const ComponentRef &cref1, const ComponentRef &cref2) noexcept
{
  return std::equal(cref1.begin(), cref1.end(), cref2.begin(), cref2.end());
}

std::ostream& OpenModelica::operator<< (std::ostream &os, const ComponentRef::Part &part)
{
  if (!part.node) {
    os << "_";
  } else {
    os << part.node->name() << part.subscripts;
  }

  return os;
}

std::ostream& OpenModelica::operator<< (std::ostream &os, const ComponentRef &cref)
{
  os << Util::printList(cref.begin(), cref.end(), ".");
  return os;
}

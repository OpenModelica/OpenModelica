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

#include "Util.h"
#include "Subscript.h"
#include "ComponentRef.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

constexpr int CREF_FULLYQUALIFIED = 0;
constexpr int CREF_QUAL = 1;
constexpr int CREF_IDENT = 2;
constexpr int WILD = 3;
constexpr int ALLWILD = 4;

extern record_description Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc;
extern record_description Absyn_ComponentRef_CREF__QUAL__desc;
extern record_description Absyn_ComponentRef_CREF__IDENT__desc;
extern record_description Absyn_ComponentRef_WILD__desc;

ComponentRef::ComponentRef(std::vector<Part> parts, bool fullyQualified)
  : _parts{std::move(parts)}, _fullyQualified{fullyQualified}
{
}

ComponentRef::ComponentRef(MetaModelica::Record value)
  : _fullyQualified{value.index() == CREF_FULLYQUALIFIED}
{
  auto v = value;

  if (v.index() >= WILD) {
    return;
  }

  while (v.index() == CREF_FULLYQUALIFIED) {
    v = v[0];
  }

  while (v.index() == CREF_QUAL) {
    _parts.emplace_back(v[0].toString(), v[1].mapVector<Subscript>());
    v = v[2];
  }

  if (v.index() != CREF_IDENT) {
    throw std::runtime_error("ComponentRef::ComponentRef: invalid component reference");
  }

  _parts.emplace_back(v[0].toString(), v[1].mapVector<Subscript>());
}

ComponentRef::~ComponentRef() = default;

MetaModelica::Value ComponentRef::toAbsyn() const noexcept
{
  if (_parts.empty()) {
    return MetaModelica::Record{WILD, Absyn_ComponentRef_WILD__desc};
  }

  MetaModelica::Value res = MetaModelica::Record{CREF_IDENT, Absyn_ComponentRef_CREF__IDENT__desc, {
    MetaModelica::Value{_parts.back().first},
    Subscript::toAbsynList(_parts.back().second)
  }};

  for (auto it = ++_parts.rbegin(); it != _parts.rend(); ++it) {
    res = MetaModelica::Record{CREF_QUAL, Absyn_ComponentRef_CREF__QUAL__desc, {
      MetaModelica::Value{it->first},
      Subscript::toAbsynList(it->second),
      res
    }};
  }

  if (_fullyQualified) {
    res = MetaModelica::Record{CREF_FULLYQUALIFIED, Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc, {res}};
  }

  return res;
}

namespace OpenModelica::Absyn
{
  std::ostream& operator<< (std::ostream &os, const ComponentRef::Part &part)
  {
    os << part.first << part.second;
    return os;
  }

  std::ostream& operator<< (std::ostream &os, const ComponentRef &cref)
  {
    if (cref._fullyQualified) os << '.';
    os << Util::printList(cref._parts, ".");
    return os;
  }
}



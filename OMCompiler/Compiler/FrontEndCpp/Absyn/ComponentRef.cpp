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
    return MetaModelica::Record(WILD, Absyn_ComponentRef_WILD__desc);
  }

  MetaModelica::Value res = MetaModelica::Record(CREF_IDENT, Absyn_ComponentRef_CREF__IDENT__desc, {
    MetaModelica::Value(_parts.back().first),
    Subscript::toAbsynList(_parts.back().second)
  });

  for (auto it = ++_parts.rbegin(); it != _parts.rend(); ++it) {
    res = MetaModelica::Record(CREF_QUAL, Absyn_ComponentRef_CREF__QUAL__desc, {
      MetaModelica::Value(it->first),
      Subscript::toAbsynList(it->second),
      res
    });
  }

  if (_fullyQualified) {
    res = MetaModelica::Record(CREF_FULLYQUALIFIED, Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc, {res});
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



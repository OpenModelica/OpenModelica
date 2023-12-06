#include <ostream>

#include "TypeSpec.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

constexpr int TPATH = 0;
constexpr int TCOMPLEX = 1;

extern record_description Absyn_TypeSpec_TPATH__desc;
extern record_description Absyn_TypeSpec_TCOMPLEX__desc;

TypeSpec::TypeSpec(MetaModelica::Record value)
  : _path{value[0]}
{
  if (value.index() == TPATH) {
    if (value[1].toOption()) {
      _arrayDims = value[1].toOption()->mapVector<Subscript>();
    }
  } else {
    // MetaModelica extension, but polymorphic is used in ModelicaBuiltin.
    _typeSpecs = value[1].mapVector<TypeSpec>();

    if (value[2].toOption()) {
      _arrayDims = value[2].toOption()->mapVector<Subscript>();
    }
  }
}

MetaModelica::Value TypeSpec::toAbsyn() const noexcept
{
  if (_typeSpecs.empty()) {
    return MetaModelica::Record(TPATH, Absyn_TypeSpec_TPATH__desc, {
      _path.toAbsyn(),
      _arrayDims.empty() ?  MetaModelica::Option() : MetaModelica::Option(Subscript::toAbsynList(_arrayDims))
    });
  } else {
    return MetaModelica::Record(TCOMPLEX, Absyn_TypeSpec_TCOMPLEX__desc, {
      _path.toAbsyn(),
      MetaModelica::List(_typeSpecs, [](const auto &ty) { return ty.toAbsyn(); }),
      _arrayDims.empty() ?  MetaModelica::Option() : MetaModelica::Option(Subscript::toAbsynList(_arrayDims))
    });
  }
}

const Path& TypeSpec::path() const noexcept
{
  return _path;
}

const std::vector<Subscript>& TypeSpec::dimensions() const noexcept
{
  return _arrayDims;
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const TypeSpec &typeSpec) noexcept
{
  os << typeSpec.path() << typeSpec.dimensions();
  return os;
}

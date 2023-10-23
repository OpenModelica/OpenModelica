#include <ostream>

#include "TypeSpec.h"

constexpr int TPATH = 0;
constexpr int TCOMPLEX = 1;

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

TypeSpec::TypeSpec(MetaModelica::Record value)
  : _path{value[0]}
{
  if (value.index() == TPATH) {
    if (value[1].toOption()) {
      _arrayDims = value[1].toOption()->mapVector<Subscript>();
    }
  } else {
    // MetaModelica extension, but polymorphic is used in ModelicaBuiltin.
    if (value[2].toOption()) {
      _arrayDims = value[2].toOption()->mapVector<Subscript>();
    }
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

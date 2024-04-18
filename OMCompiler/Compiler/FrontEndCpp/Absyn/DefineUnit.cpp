#include <ostream>

#include "DefineUnit.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

DefineUnit::DefineUnit(MetaModelica::Record value)
  : Element::Base(SourceInfo(value[4])),
    _name{value[0].toString()},
    _visibility{value[1]},
    _exp{value[2].toOptional<std::string>()},
    _weight{value[3].toOptional<double>()}
{

}

MetaModelica::Value DefineUnit::toSCode() const noexcept
{
  return MetaModelica::Value(4);
}

std::unique_ptr<Element::Base> DefineUnit::clone() const noexcept
{
  return std::make_unique<DefineUnit>(*this);
}

void DefineUnit::print(std::ostream &os, Each) const noexcept
{
  os << "defineunit " << _name;

  if (_exp || _weight) {
    os << '(';
    if (_exp) os << *_exp;
    if (_weight) os << *_weight;
    os << ')';
  }
}

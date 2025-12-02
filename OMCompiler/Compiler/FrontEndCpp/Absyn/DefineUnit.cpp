#include <ostream>

#include "ElementVisitor.h"
#include "DefineUnit.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Element_DEFINEUNIT__desc;

DefineUnit::DefineUnit(MetaModelica::Record value)
  : Element(SourceInfo(value[4])),
    _name{value[0].toString()},
    _visibility{value[1]},
    _exp{value[2].toOptional<std::string>()},
    _weight{value[3].toOptional<double>()}
{

}

void DefineUnit::apply(ElementVisitor &visitor)
{
  visitor.visit(*this);
}

MetaModelica::Value DefineUnit::toSCode() const noexcept
{
  return MetaModelica::Record{Element::DEFINEUNIT, SCode_Element_DEFINEUNIT__desc, {
    MetaModelica::Value{_name},
    _visibility.toSCode(),
    MetaModelica::Option(_exp),
    MetaModelica::Option(_weight),
    info()
  }};
}

std::unique_ptr<Element> DefineUnit::clone() const noexcept
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

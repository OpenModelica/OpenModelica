#include <ostream>

#include "Expression.h"
#include "Component.h"

using namespace OpenModelica::Absyn;

Component::Component(MetaModelica::Record value)
  : Element::Base(SourceInfo{value[7]}),
    _name{value[0].toString()},
    _prefixes{value[1]},
    _attributes{value[2]},
    _typeSpec{value[3]},
    _modifier{value[4]},
    _comment{value[5]},
    _condition{value[6].mapOptional<Expression>()}
{

}

Component::~Component() = default;

const std::string& Component::name() const noexcept
{
  return _name;
}

const Comment& Component::comment() const noexcept
{
  return _comment;
}

std::unique_ptr<Element::Base> Component::clone() const noexcept
{
  return std::make_unique<Component>(*this);
}

void Component::print(std::ostream &os, Each each) const noexcept
{
  _prefixes.print(os, each);
  os << _attributes << _typeSpec << ' ' << _name << _attributes.arrayDims() << _modifier;

  if (_condition) {
    os << " if " << *_condition;
  }
}

#include <ostream>

#include "Class.h"

using namespace OpenModelica::Absyn;

Class::Class(MetaModelica::Record value)
  : Element::Base(SourceInfo{value[7]}),
    _name{value[0].toString()},
    _prefixes{value[1]},
    _encapsulated{value[2]},
    _partial{value[3]},
    _restriction{value[4]},
    _classDef{value[5]},
    _comment{value[6]}
{

}

const std::string& Class::name() const noexcept
{
  return _name;
}

const Comment& Class::comment() const noexcept
{
  return _comment;
}

std::unique_ptr<Element::Base> Class::clone() const noexcept
{
  return std::make_unique<Class>(*this);
}

void Class::print(std::ostream &os, Each each) const noexcept
{
  _prefixes.print(os, each);
  os << _encapsulated.unparse() << _partial.unparse() << _restriction << ' ';
  _classDef.print(os, *this);
}

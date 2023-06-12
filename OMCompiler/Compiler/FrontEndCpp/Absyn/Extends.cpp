#include <ostream>

#include "Extends.h"

using namespace OpenModelica::Absyn;

Extends::Extends(MetaModelica::Record value)
  : Element::Base(SourceInfo{value[4]}),
    _baseClassPath{value[0]},
    _visibility{value[1]},
    _modifier{value[2]},
    _annotation{value[3]}
{

}

std::unique_ptr<Element::Base> Extends::clone() const noexcept
{
  return std::make_unique<Extends>(*this);
}

void Extends::print(std::ostream &os, Each) const noexcept
{
  os << _visibility.unparse() << "extends " << _baseClassPath << _modifier << _annotation;
}

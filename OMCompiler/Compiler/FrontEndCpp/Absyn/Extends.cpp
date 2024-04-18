#include <ostream>

#include "Extends.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Element_EXTENDS__desc;

Extends::Extends(MetaModelica::Record value)
  : Element::Base(SourceInfo{value[4]}),
    _baseClassPath{value[0]},
    _visibility{value[1]},
    _modifier{value[2]},
    _annotation{value[3].mapOptionalOrDefault<Annotation>()}
{

}

MetaModelica::Value Extends::toSCode() const noexcept
{
  return MetaModelica::Record(Element::EXTENDS, SCode_Element_EXTENDS__desc, {
    _baseClassPath.toAbsyn(),
    _visibility.toSCode(),
    _modifier.toSCode(),
    _annotation.toSCodeOpt(),
    _info
  });
}

std::unique_ptr<Element::Base> Extends::clone() const noexcept
{
  return std::make_unique<Extends>(*this);
}

void Extends::print(std::ostream &os, Each) const noexcept
{
  os << _visibility.unparse() << "extends " << _baseClassPath << _modifier << _annotation;
}

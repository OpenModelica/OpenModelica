#include <ostream>

#include "Import.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Element_IMPORT__desc;

Import::Import(MetaModelica::Record value)
  : Element::Base(SourceInfo(value[2])),
    _path(value[0]),
    _visibility(value[1])
{

}

MetaModelica::Value Import::toSCode() const noexcept
{
  return MetaModelica::Record(Element::IMPORT, SCode_Element_IMPORT__desc, {
    _path.toAbsyn(),
    _visibility.toSCode(),
    _info
  });
}

std::unique_ptr<Element::Base> Import::clone() const noexcept
{
  return std::make_unique<Import>(*this);
}

void Import::print(std::ostream &os, Each) const noexcept
{
  os << _visibility.unparse() << "import " << _path;
}

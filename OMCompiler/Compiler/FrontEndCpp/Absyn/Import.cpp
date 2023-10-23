#include <ostream>

#include "Import.h"

using namespace OpenModelica::Absyn;

Import::Import(MetaModelica::Record value)
  : Element::Base(SourceInfo(value[2])),
    _path(value[0]),
    _visibility(value[1])
{

}

std::unique_ptr<Element::Base> Import::clone() const noexcept
{
  return std::make_unique<Import>(*this);
}

void Import::print(std::ostream &os, Each) const noexcept
{
  os << _visibility.unparse() << "import " << _path;
}

#include <ostream>

#include "Annotation.h"

using namespace OpenModelica::Absyn;

Annotation::Annotation(MetaModelica::Record value)
  : _modifier{value[0]}
{

}

void Annotation::print(std::ostream &os, std::string_view indent) const noexcept
{
  if (!_modifier.isEmpty()) {
    os << indent << "annotation" << _modifier;
  }
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const Annotation &annotation) noexcept
{
  annotation.print(os);
  return os;
}

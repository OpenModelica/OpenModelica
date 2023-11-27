#include <ostream>

#include "Annotation.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Annotation_ANNOTATION__desc;

Annotation::Annotation(MetaModelica::Record value)
  : _modifier{value[0]}
{

}

MetaModelica::Value Annotation::toSCode() const noexcept
{
  return MetaModelica::Record(0, SCode_Annotation_ANNOTATION__desc, { _modifier.toSCode() });
}

MetaModelica::Value Annotation::toSCodeOpt() const noexcept
{
  return _modifier.isEmpty() ? MetaModelica::Option() : MetaModelica::Option(toSCode());
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

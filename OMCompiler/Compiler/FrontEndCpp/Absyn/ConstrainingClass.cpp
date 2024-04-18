#include <ostream>

#include "ConstrainingClass.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_ConstrainClass_CONSTRAINCLASS__desc;

ConstrainingClass::ConstrainingClass(MetaModelica::Record value)
  : _path{value[0]},
    _modifier{value[1]},
    _comment{value[2]}
{

}

MetaModelica::Value ConstrainingClass::toSCode() const noexcept
{
  return MetaModelica::Record(0, SCode_ConstrainClass_CONSTRAINCLASS__desc, {
    _path.toAbsyn(),
    _modifier.toSCode(),
    _comment.toSCode()
  });
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const ConstrainingClass &cc) noexcept
{
  os << " constrainedby " << cc.path();
  return os;
}

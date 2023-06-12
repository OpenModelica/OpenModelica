#include <ostream>

#include "ConstrainingClass.h"

using namespace OpenModelica::Absyn;

ConstrainingClass::ConstrainingClass(MetaModelica::Record value)
  : _path{value[0]}
    //_modifier{value[1].toRecord()},
    //_comment{value[2].toRecord()}
{

}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const ConstrainingClass &cc) noexcept
{
  os << " constrainedby " << cc.path();
  return os;
}

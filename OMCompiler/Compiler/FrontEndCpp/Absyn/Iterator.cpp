#include <ostream>

#include "Iterator.h"

using namespace OpenModelica::Absyn;

Iterator::Iterator(MetaModelica::Record value)
  : _name{value[0].toString()},
    _range{value[2].mapOptional<Expression>()}
{

}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream& os, const Iterator &iterator)
{
  os << iterator._name;

  if (iterator._range) {
    os << " in " << *iterator._range;
  }

  return os;
}

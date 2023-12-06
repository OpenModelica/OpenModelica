#include <ostream>

#include "Iterator.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description Absyn_ForIterator_ITERATOR__desc;

Iterator::Iterator(MetaModelica::Record value)
  : _name{value[0].toString()},
    _range{value[2].mapOptional<Expression>()}
{

}

MetaModelica::Value Iterator::toAbsyn() const noexcept
{
  return MetaModelica::Record(0, Absyn_ForIterator_ITERATOR__desc, {
    MetaModelica::Value(_name),
    MetaModelica::Option(),
    MetaModelica::Option(_range, [](const auto &e) { return e.toAbsyn(); })
  });
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream& os, const Iterator &iterator)
{
  os << iterator._name;

  if (iterator._range) {
    os << " in " << *iterator._range;
  }

  return os;
}

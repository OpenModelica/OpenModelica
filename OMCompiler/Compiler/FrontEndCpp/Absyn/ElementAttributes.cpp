#include <ostream>

#include "ElementAttributes.h"

using namespace OpenModelica::Absyn;

ElementAttributes::ElementAttributes(MetaModelica::Record value)
  : _arrayDims{value[0].mapVector<Subscript>()},
    _connectorType{value[1]},
    _parallelism{value[2]},
    _variability{value[3]},
    _direction{value[4]},
    _field{value[5]}
{

}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const ElementAttributes &attrs) noexcept
{
  os << attrs.connectorType().unparse();
  os << attrs.parallelism().unparse();
  os << attrs.field().unparse();
  os << attrs.variability().unparse();
  os << attrs.direction().unparse();
  return os;
}

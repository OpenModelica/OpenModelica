#include <ostream>

#include "ElementAttributes.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Attributes_ATTR__desc;

ElementAttributes::ElementAttributes(MetaModelica::Record value)
  : _arrayDims{value[0].mapVector<Subscript>()},
    _connectorType{value[1]},
    _parallelism{value[2]},
    _variability{value[3]},
    _direction{value[4]},
    _field{value[5]}
{

}

MetaModelica::Value ElementAttributes::toSCode() const noexcept
{
  return MetaModelica::Record(0, SCode_Attributes_ATTR__desc, {
    Subscript::toAbsynList(_arrayDims),
    _connectorType.toSCode(),
    _parallelism.toSCode(),
    _variability.toSCode(),
    _direction.toAbsyn(),
    _field.toAbsyn()
  });
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

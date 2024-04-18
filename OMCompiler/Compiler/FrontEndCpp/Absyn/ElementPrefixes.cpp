#include <ostream>

#include "ElementPrefixes.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_Prefixes_PREFIXES__desc;

ElementPrefixes::ElementPrefixes(MetaModelica::Record value)
  : _visibility{value[0]},
    _redeclare{value[1]},
    _final{value[2]},
    _innerOuter{value[3]},
    _replaceable{value[4]}
{

}

MetaModelica::Value ElementPrefixes::toSCode() const noexcept
{
  return MetaModelica::Record{0, SCode_Prefixes_PREFIXES__desc, {
    _visibility.toSCode(),
    _redeclare.toSCode(),
    _final.toSCode(),
    _innerOuter.toAbsyn(),
    _replaceable.toSCode()
  }};
}

void ElementPrefixes::print(std::ostream &os, Each each) const noexcept
{
  os << _redeclare.unparse() << each.unparse() << _final.unparse() <<
        _innerOuter.unparse() << _replaceable.unparse();
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const ElementPrefixes &prefixes)
{
  prefixes.print(os);
  return os;
}

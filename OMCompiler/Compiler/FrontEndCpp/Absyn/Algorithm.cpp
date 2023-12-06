#include "Util.h"
#include "Algorithm.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_AlgorithmSection_ALGORITHM__desc;

Algorithm::Algorithm(MetaModelica::Record value)
  : _statements{value[0].mapVector<Statement>()}
{

}

MetaModelica::Value Algorithm::toSCode() const noexcept
{
  return MetaModelica::Record(0, SCode_AlgorithmSection_ALGORITHM__desc, { Statement::toSCodeList(_statements) });
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const Algorithm &algorithm)
{
  os << "algorithm\n";

  for (auto &s: algorithm.statements()) {
    s.print(os, "  ");
    os << ";\n";
  }

  return os;
}

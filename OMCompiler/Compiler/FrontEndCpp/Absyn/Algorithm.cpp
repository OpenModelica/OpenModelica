#include "Util.h"
#include "Algorithm.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

Algorithm::Algorithm(MetaModelica::Record value)
  : _statements{value[0].mapVector<Statement>()}
{

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

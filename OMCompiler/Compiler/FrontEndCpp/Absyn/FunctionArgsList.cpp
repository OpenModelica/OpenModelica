#include <ostream>

#include "Util.h"
#include "Expression.h"
#include "FunctionArgsList.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

FunctionArgsList::FunctionArgsList(MetaModelica::Record value)
{
  for (auto arg: value[0].toList()) {
    _args.emplace_back(arg);
  }

  for (auto namedArg: value[1].toList()) {
    auto arg = namedArg.toRecord();
    _namedArgs.emplace_back(arg[0].toString(), arg[1]);
  }
}

std::unique_ptr<FunctionArgs::Base> FunctionArgsList::clone() const noexcept
{
  return std::make_unique<FunctionArgsList>(*this);
}

namespace OpenModelica::Absyn
{
  std::ostream& operator<< (std::ostream& os, const FunctionArgsList::NamedArg &arg) {
    os << arg.first << '=' << arg.second;
    return os;
  }
}

void FunctionArgsList::print(std::ostream &os) const noexcept
{
  os << Util::printList(_args);
  if (!_args.empty() && !_namedArgs.empty()) os << ", ";
  os << Util::printList(_namedArgs);
}


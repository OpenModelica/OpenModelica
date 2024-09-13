#include <ostream>

#include "Util.h"
#include "Expression.h"
#include "FunctionArgsList.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description Absyn_FunctionArgs_FUNCTIONARGS__desc;

extern record_description Absyn_NamedArg_NAMEDARG__desc;

FunctionArgsList::FunctionArgsList(MetaModelica::Record value)
  : _args{value[0].mapVector<Expression>()},
    _namedArgs{value[1].mapVector([](MetaModelica::Record v) {
      return NamedArg(v[0].toString(), v[1]); })
    }
{

}

std::unique_ptr<FunctionArgs::Base> FunctionArgsList::clone() const noexcept
{
  return std::make_unique<FunctionArgsList>(*this);
}

MetaModelica::Value FunctionArgsList::toAbsyn() const noexcept
{
  return MetaModelica::Record(FunctionArgs::FUNCTIONARGS, Absyn_FunctionArgs_FUNCTIONARGS__desc, {
    MetaModelica::List(_args, [](const auto &arg) { return arg.toAbsyn(); }),
    MetaModelica::List(_namedArgs, [](const auto &arg) {
      return MetaModelica::Record(0, Absyn_NamedArg_NAMEDARG__desc, {
        MetaModelica::Value(arg.first),
        arg.second.toAbsyn()
      });
    })
  });
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


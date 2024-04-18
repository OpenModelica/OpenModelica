#include <ostream>

#include "FunctionArgsList.h"
#include "FunctionArgsIter.h"
#include "FunctionArgs.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

std::unique_ptr<FunctionArgs::Base> function_args_from_mm(MetaModelica::Record value)
{
  if (value.index() == 0) {
    return std::make_unique<FunctionArgsList>(value);
  } else {
    return std::make_unique<FunctionArgsIter>(value);
  }
}

FunctionArgs::FunctionArgs(MetaModelica::Record value)
  : _impl{function_args_from_mm(value)}
{

}

FunctionArgs::FunctionArgs(const FunctionArgs &other) noexcept
  : _impl{other._impl->clone()}
{

}

FunctionArgs& FunctionArgs::operator= (const FunctionArgs &other) noexcept
{
  _impl = other._impl->clone();
  return *this;
}

MetaModelica::Value FunctionArgs::toAbsyn() const noexcept
{
  return _impl->toAbsyn();
}

void FunctionArgs::print(std::ostream &os) const noexcept
{
  return _impl->print(os);
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const FunctionArgs &args) noexcept
{
  args.print(os);
  return os;
}

#include "Util.h"
#include "Iterator.h"
#include "FunctionArgsIter.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

FunctionArgsIter::FunctionArgsIter(MetaModelica::Record value)
  : _exp{value[0]},
    _iterators{value[2].mapVector<Iterator>()}
{

}

FunctionArgsIter::~FunctionArgsIter() = default;

std::unique_ptr<FunctionArgs::Base> FunctionArgsIter::clone() const noexcept
{
  return std::make_unique<FunctionArgsIter>(*this);
}

void FunctionArgsIter::print(std::ostream &os) const noexcept
{
  os << _exp << " for " << Util::printList(_iterators);
}

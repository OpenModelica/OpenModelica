#include "Util.h"
#include "Iterator.h"
#include "FunctionArgsIter.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description Absyn_FunctionArgs_FOR__ITER__FARG__desc;

extern record_description Absyn_ReductionIterType_COMBINE__desc;

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

MetaModelica::Value FunctionArgsIter::toAbsyn() const noexcept
{
  static const MetaModelica::Record combineIterType{0, Absyn_ReductionIterType_COMBINE__desc};

  return MetaModelica::Record(FunctionArgs::FOR_ITER_FARG, Absyn_FunctionArgs_FOR__ITER__FARG__desc, {
    _exp.toAbsyn(),
    combineIterType,
    MetaModelica::List(_iterators, [](const auto &i) { return i.toAbsyn(); })
  });
}

void FunctionArgsIter::print(std::ostream &os) const noexcept
{
  os << _exp << " for " << Util::printList(_iterators);
}

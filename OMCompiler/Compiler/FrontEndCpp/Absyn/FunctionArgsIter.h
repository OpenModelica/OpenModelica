#ifndef ABSYN_FUNCTIONARGSITER_H
#define ABSYN_FUNCTIONARGSITER_H

#include <vector>

#include "Expression.h"
#include "FunctionArgs.h"

namespace OpenModelica::Absyn
{
  class Iterator;

  class FunctionArgsIter : public FunctionArgs::Base
  {
    public:
      FunctionArgsIter(MetaModelica::Record value);
      ~FunctionArgsIter();

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _exp;
      std::vector<Iterator> _iterators;
  };
}

#endif /* ABSYN_FUNCTIONARGSITER_H */

#ifndef ABSYN_FUNCTIONARGSLIST_H
#define ABSYN_FUNCTIONARGSLIST_H

#include <string>
#include <vector>
#include <memory>
#include <utility>
#include <iosfwd>

#include "FunctionArgs.h"

namespace OpenModelica::Absyn
{
  class Expression;

  class FunctionArgsList : public FunctionArgs::Base
  {
    public:
      using Arg = Expression;
      using NamedArg = std::pair<std::string, Expression>;

    public:
      FunctionArgsList(MetaModelica::Record value);

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::vector<Arg> _args;
      std::vector<NamedArg> _namedArgs;
  };
}

#endif /* ABSYN_FUNCTIONARGSLIST_H */

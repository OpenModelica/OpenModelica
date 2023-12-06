#ifndef ABSYN_FUNCTIONARGS_H
#define ABSYN_FUNCTIONARGS_H

#include <memory>
#include <iosfwd>

#include "MetaModelica.h"

namespace OpenModelica::Absyn
{
  class Expression;

  class FunctionArgs
  {
    public:
      static constexpr int FUNCTIONARGS = 0;
      static constexpr int FOR_ITER_FARG = 1;

    public:
      class Base
      {
        public:
          virtual ~Base() = default;

          virtual std::unique_ptr<Base> clone() const noexcept = 0;
          virtual MetaModelica::Value toAbsyn() const noexcept = 0;
          virtual void print(std::ostream &os) const noexcept = 0;
      };

    public:
      FunctionArgs(MetaModelica::Record value);
      FunctionArgs(const FunctionArgs &other) noexcept;
      FunctionArgs(FunctionArgs &&other) = default;

      FunctionArgs& operator= (const FunctionArgs &other) noexcept;
      FunctionArgs& operator= (FunctionArgs &&other) = default;

      MetaModelica::Value toAbsyn() const noexcept;

      void print(std::ostream &os) const noexcept;

    private:
      std::unique_ptr<Base> _impl;
  };

  std::ostream& operator<< (std::ostream &os, const FunctionArgs &args) noexcept;
}

#endif /* ABSYN_FUNCTIONARGS_H */

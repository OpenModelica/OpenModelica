#ifndef ABSYN_SUBSCRIPT_H
#define ABSYN_SUBSCRIPT_H

#include <iosfwd>
#include <vector>
#include <memory>

#include "MetaModelica.h"
#include "Expression.h"

namespace OpenModelica::Absyn
{
  class Subscript
  {
    public:
      Subscript(MetaModelica::Record value);
      ~Subscript() noexcept;

      MetaModelica::Value toAbsyn() const noexcept;
      static MetaModelica::Value toAbsynList(const std::vector<Subscript> &subs) noexcept;

      const std::optional<Expression>& expression() const noexcept;

    private:
      std::optional<Expression> _subscript;
  };

  std::ostream& operator<< (std::ostream& os, const Subscript &subscript);
  std::ostream& operator<< (std::ostream& os, const std::vector<Subscript> &subscripts);
}

#endif /* ABSYN_SUBSCRIPT_H */

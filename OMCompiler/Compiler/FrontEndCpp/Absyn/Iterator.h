#ifndef ABSYN_ITERATOR_H
#define ABSYN_ITERATOR_H

#include <string>
#include <optional>

#include "MetaModelica.h"
#include "Expression.h"

namespace OpenModelica::Absyn
{
  class Iterator
  {
    public:
      Iterator(MetaModelica::Record value);

      MetaModelica::Value toAbsyn() const noexcept;

      friend std::ostream& operator<< (std::ostream& os, const Iterator &iterator);

    private:
      std::string _name;
      std::optional<Expression> _range;
  };

  std::ostream& operator<< (std::ostream& os, const Iterator &iterator);
}

#endif /* ABSYN_ITERATOR_H */

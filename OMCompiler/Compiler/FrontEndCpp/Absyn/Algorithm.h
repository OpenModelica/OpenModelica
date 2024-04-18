#ifndef ABSYN_ALGORITHM_H
#define ABSYN_ALGORITHM_H

#include "MetaModelica.h"
#include "Statement.h"

namespace OpenModelica::Absyn
{
  class Algorithm
  {
    public:
      Algorithm(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      const std::vector<Statement>& statements() const noexcept { return _statements; }

    private:
      std::vector<Statement> _statements;
  };

  std::ostream& operator<< (std::ostream &os, const Algorithm &algorithm);
};

#endif /* ABSYN_ALGORITHM_H */

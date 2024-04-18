#ifndef ABSYN_COMPONENTREF_H
#define ABSYN_COMPONENTREF_H

#include <string>
#include <utility>
#include <vector>
#include <iosfwd>

#include "MetaModelica.h"

namespace OpenModelica::Absyn
{
  class Subscript;

  class ComponentRef
  {
    public:
      using Part = std::pair<std::string, std::vector<Subscript>>;

    public:
      ComponentRef(std::vector<Part> parts, bool fullyQualified = false);
      explicit ComponentRef(MetaModelica::Record value);
      ~ComponentRef();

      MetaModelica::Value toAbsyn() const noexcept;

      void push_back(Part part) noexcept;

      bool isIdent() const noexcept;
      bool isQualified() const noexcept;
      bool isFullyQualified() const noexcept;
      bool isWild() const noexcept;

      const Part& first() const;
      ComponentRef rest() const;
      ComponentRef fullyQualify() const noexcept;
      ComponentRef unqualify() const noexcept;

      std::string str() const noexcept;

      friend std::ostream& operator<< (std::ostream &os, const ComponentRef &cref);

    private:
      std::vector<Part> _parts;
      bool _fullyQualified;
  };

  std::ostream& operator<< (std::ostream &os, const ComponentRef &cref);
}

#endif /* ABSYN_COMPONENTREF_H */

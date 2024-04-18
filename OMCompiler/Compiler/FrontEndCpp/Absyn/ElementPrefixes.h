#ifndef ABSYN_ELEMENTPREFIXES_H
#define ABSYN_ELEMENTPREFIXES_H

#include <iosfwd>

#include "Prefixes.h"
#include "ConstrainingClass.h"
#include "MetaModelica.h"

namespace OpenModelica::Absyn
{
  class ElementPrefixes
  {
    public:
      ElementPrefixes() = default;
      ElementPrefixes(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      Visibility visibility() const noexcept { return _visibility; }
      Redeclare redeclare() const noexcept { return _redeclare; }
      Final final() const noexcept { return _final; }
      InnerOuter innerOuter() const noexcept { return _innerOuter; }
      const Replaceable<ConstrainingClass>& replaceable() const noexcept { return _replaceable; }

      void print(std::ostream &os, Each each = Each()) const noexcept;

    private:
      Visibility _visibility;
      Redeclare _redeclare;
      Final _final;
      InnerOuter _innerOuter;
      Replaceable<ConstrainingClass> _replaceable;
  };

  std::ostream& operator<< (std::ostream& os, const ElementPrefixes &prefixes);
}

#endif /* ELEMENTPREFIXES_H */

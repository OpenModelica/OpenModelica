#ifndef ABSYN_ANNOTATION_H
#define ABSYN_ANNOTATION_H

#include <string_view>
#include <iosfwd>

#include "MetaModelica.h"
#include "Modifier.h"

namespace OpenModelica::Absyn
{
  class Annotation
  {
    public:
      Annotation() = default;
      Annotation(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;
      MetaModelica::Value toSCodeOpt() const noexcept;

      const Modifier& modifier() const noexcept { return _modifier; }

      void print(std::ostream &os, std::string_view indent = {}) const noexcept;

    private:
      Modifier _modifier;
  };

  std::ostream& operator<< (std::ostream &os, const Annotation &annotation) noexcept;
}

#endif /* ANNOTATION_H */

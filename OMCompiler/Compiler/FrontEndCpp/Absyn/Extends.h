#ifndef ABSYN_EXTENDS_H
#define ABSYN_EXTENDS_H

#include "MetaModelica.h"
#include "Element.h"
#include "Path.h"
#include "Prefixes.h"
#include "Modifier.h"
#include "Annotation.h"

namespace OpenModelica::Absyn
{
  class Extends : public Element::Base
  {
    public:
      Extends(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept override;

      std::unique_ptr<Element::Base> clone() const noexcept override;
      void print(std::ostream &os, Each each) const noexcept override;

    private:
      Path _baseClassPath;
      Visibility _visibility;
      Modifier _modifier;
      Annotation _annotation;
  };
}

#endif /* ABSYN_EXTENDS_H */

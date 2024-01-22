#ifndef ABSYN_DEFINEUNIT_H
#define ABSYN_DEFINEUNIT_H

#include "MetaModelica.h"
#include "Element.h"
#include "../Prefixes.h"

namespace OpenModelica::Absyn
{
  class DefineUnit : public Element
  {
    public:
      DefineUnit(MetaModelica::Record value);

      void apply(ElementVisitor &visitor) override;

      MetaModelica::Value toSCode() const noexcept override;

      std::unique_ptr<Element> clone() const noexcept override;
      void print(std::ostream &os, Each) const noexcept override;

    private:
      std::string _name;
      Visibility _visibility;
      std::optional<std::string> _exp;
      std::optional<double> _weight;
  };
}

#endif /* DEFINEUNIT_H */

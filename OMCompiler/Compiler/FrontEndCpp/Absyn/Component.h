#ifndef ABSYN_COMPONENT_H
#define ABSYN_COMPONENT_H

#include <string>
#include <optional>

#include "MetaModelica.h"
#include "Element.h"
#include "ElementPrefixes.h"
#include "ElementAttributes.h"
#include "TypeSpec.h"
#include "Comment.h"
#include "Expression.h"

namespace OpenModelica::Absyn
{
  class Component : public Element::Base
  {
    public:
      Component(MetaModelica::Record value);
      ~Component();

      MetaModelica::Value toSCode() const noexcept override;

      const std::string& name() const noexcept;
      const Comment& comment() const noexcept;

      std::unique_ptr<Element::Base> clone() const noexcept override;
      void print(std::ostream &os, Each each) const noexcept override;

    private:
      std::string _name;
      ElementPrefixes _prefixes;
      ElementAttributes _attributes;
      TypeSpec _typeSpec;
      Modifier _modifier;
      Comment _comment;
      std::optional<Expression> _condition;
  };
}

#endif /* ABSYN_COMPONENT_H */

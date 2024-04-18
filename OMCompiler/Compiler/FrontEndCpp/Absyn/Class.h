#ifndef ABSYN_CLASS_H
#define ABSYN_CLASS_H

#include <string>

#include "MetaModelica.h"
#include "Element.h"
#include "ElementPrefixes.h"
#include "Restriction.h"
#include "ClassDef.h"
#include "Comment.h"

namespace OpenModelica::Absyn
{
  class Class : public Element::Base
  {
    public:
      Class(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept override;

      const std::string& name() const noexcept;
      const Comment& comment() const noexcept;

      std::unique_ptr<Element::Base> clone() const noexcept override;
      void print(std::ostream &os, Each each) const noexcept override;

    private:
      std::string _name;
      ElementPrefixes _prefixes;
      Encapsulated _encapsulated;
      Partial _partial;
      Restriction _restriction;
      ClassDef _classDef;
      Comment _comment;
  };
}

#endif /* ABSYN_CLASS_H */

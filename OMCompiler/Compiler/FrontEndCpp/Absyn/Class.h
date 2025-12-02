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
  class Class : public Element
  {
    public:
      Class(MetaModelica::Record value);
      Class(std::string name, ElementPrefixes prefixes, Encapsulated enc, Partial partial, Restriction res, std::unique_ptr<ClassDef> cdef, Comment cmt = {}, SourceInfo info = SourceInfo::dummyInfo());
      Class(const Class &other);
      Class(Class &&other) = default;

      Class& operator= (Class other) noexcept;
      Class& operator= (Class &&other) = default;
      friend void swap(Class &first, Class &second) noexcept;

      void apply(ElementVisitor &visitor) override;

      MetaModelica::Value toSCode() const noexcept override;

      const std::string& name() const noexcept;
      const ElementPrefixes& prefixes() const noexcept;
      const Comment& comment() const noexcept;
      const ClassDef& definition() const noexcept;

      std::unique_ptr<Element> clone() const noexcept override;
      void print(std::ostream &os, Each each) const noexcept override;

    private:
      std::string _name;
      ElementPrefixes _prefixes;
      Encapsulated _encapsulated;
      Partial _partial;
      Restriction _restriction;
      std::unique_ptr<ClassDef> _classDef;
      Comment _comment;
  };
}

#endif /* ABSYN_CLASS_H */

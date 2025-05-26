#ifndef CLASS_H
#define CLASS_H

#include "Absyn/AbsynFwd.h"
#include "Absyn/ConstrainingClass.h"
#include "Prefixes.h"
#include "ClassTree.h"

namespace OpenModelica
{
  class InstNode;

  class Class
  {
    public:
      struct Prefixes
      {
        Encapsulated encapsulated;
        Partial partial;
        Final final;
        InnerOuter innerOuter;
        Replaceable<Absyn::ConstrainingClass> replaceable;
      };

    public:
      static std::unique_ptr<Class> fromAbsyn(const Absyn::Class &cls, InstNode *scope);
      virtual ~Class();

      virtual const ClassTree* classTree() const noexcept { return nullptr; }

      virtual MetaModelica::Value toMetaModelica() const = 0;
  };

  class PartialClass : public Class
  {
    public:
      PartialClass(const Absyn::ClassParts &definition, bool isClassExtends, InstNode *scope);

      const ClassTree* classTree() const noexcept override { return &_elements; }

      MetaModelica::Value toMetaModelica() const override;

    private:
      ClassTree _elements;
      // Modifier _modifier;
      // Modifier _ccMod;
      Prefixes _prefixes;
  };
};

#endif /* CLASS_H */

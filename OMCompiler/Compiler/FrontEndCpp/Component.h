#ifndef COMPONENT_H
#define COMPONENT_H

#include "Absyn/AbsynFwd.h"
#include "Prefixes.h"

namespace OpenModelica
{
  class InstNode;

  class Component
  {
    public:
      Component(Absyn::Component *definition);
      virtual ~Component();

      virtual MetaModelica::Value toNF() const noexcept = 0;

    protected:
      Absyn::Component *_definition;
  };

  class ComponentDef : public Component
  {
    public:
      ComponentDef(Absyn::Component *component);

      MetaModelica::Value toNF() const noexcept override;

    private:
      // Modifier _modifier;
  };

  class NormalComponent : public Component
  {
    public:
      enum class State
      {
        PartiallyInstantiated, // Component instance has been created.
        FullyInstantiated,     // All component expressions have been instantiated.
        Typed,                 // The component's type has been determined.
        TypeChecked            // The component's binding has been typed and type checked.
      };

    public:

      MetaModelica::Value toNF() const noexcept override;

    private:
      InstNode *_classInst;
      //Type ty;
      // Binding _binding;
      // Binding _condition;
      // Attributes _attributes;
      Absyn::Comment *_comment;
      State _state = State::PartiallyInstantiated;
  };
}

#endif /* COMPONENT_H */

#ifndef INSTNODE_H
#define INSTNODE_H

#include "Absyn/AbsynFwd.h"
#include "MetaModelica.h"
#include "InstNodeType.h"

#include <memory>

namespace OpenModelica
{
  class Class;

  class InstNode
  {
    public:
      static constexpr int CLASS_NODE = 0;
      static constexpr int COMPONENT_NODE = 1;
      static constexpr int INNER_OUTER_NODE = 2;
      static constexpr int REF_NODE = 3;
      static constexpr int NAME_NODE = 4;
      static constexpr int IMPLICIT_SCOPE = 5;
      static constexpr int ITERATOR_NODE = 6;
      static constexpr int VAR_NODE = 7;
      static constexpr int EMPTY_NODE = 8;

      static const MetaModelica::Value emptyMMNode;

    public:
      virtual ~InstNode() = default;

      bool isComponent() const noexcept { return false; }
      bool isClass() const noexcept { return false; }
      bool isRef() const noexcept { return false; }
      bool isRedeclare() const noexcept { return false; }

      virtual const std::string& name() const noexcept = 0;
      virtual Absyn::Element* definition() const noexcept = 0;
      int refIndex() const noexcept { return 0; }

      virtual const InstNodeType* nodeType() const noexcept { return nullptr; }
      virtual void setNodeType(std::unique_ptr<InstNodeType>) noexcept {};

      virtual const Class* getClass() const noexcept { return nullptr; }

      virtual void partialInst() {};
      virtual void expand() {};
      virtual void instantiate() {};

      virtual MetaModelica::Value toMetaModelica() const = 0;
  };


}

#endif /* INSTNODE_H */

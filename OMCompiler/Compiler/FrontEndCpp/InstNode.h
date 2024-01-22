#ifndef INSTNODE_H
#define INSTNODE_H

#include "Absyn/AbsynFwd.h"
#include "InstNodeType.h"

namespace OpenModelica
{
  class Class;

  class InstNode
  {
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
  };


}

#endif /* INSTNODE_H */

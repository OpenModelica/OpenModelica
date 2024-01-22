#ifndef CLASSNODE_H
#define CLASSNODE_H

#include "InstNode.h"

namespace OpenModelica
{
  class ClassNode : public InstNode
  {
    public:
      ClassNode(Absyn::Class *cls, InstNode *parent);
      ClassNode(Absyn::Class *cls, InstNode *parent, std::unique_ptr<InstNodeType> nodeType);
      ~ClassNode();

      //const Class* getClass() const noexcept override;

      const std::string& name() const noexcept override { return _name; }
      Absyn::Element* definition() const noexcept override { return _definition; }

      const InstNodeType* nodeType() const noexcept override;
      void setNodeType(std::unique_ptr<InstNodeType> nodeType) noexcept override;

      void partialInst() override;
      void expand() override;
      void instantiate() override;

    private:
      std::string _name;
      Absyn::Class *_definition;
      Visibility _visibility;
      std::unique_ptr<Class> _cls;
      // array<CachedData> caches;
      InstNode *_parentScope [[maybe_unused]];
      std::unique_ptr<InstNodeType> _nodeType;
  };
}

#endif /* CLASSNODE_H */

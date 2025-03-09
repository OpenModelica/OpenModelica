#ifndef COMPONENTNODE_H
#define COMPONENTNODE_H

#include "InstNode.h"

namespace OpenModelica
{
  class ComponentNode : public InstNode
  {
    public:
      ComponentNode(Absyn::Component *definition, InstNode *parent);
      ComponentNode(Absyn::Component *definition, InstNode *parent, std::unique_ptr<InstNodeType> nodeType);
      ~ComponentNode();

      const std::string& name() const noexcept override { return _name; }
      Absyn::Element* definition() const noexcept override { return _definition; }

      const InstNodeType* nodeType() const noexcept override;
      void setNodeType(std::unique_ptr<InstNodeType> nodeType) noexcept override;

      MetaModelica::Value toMetaModelica() const override;

    private:
      std::string _name;
      Absyn::Component *_definition;
      Visibility _visibility;
      std::unique_ptr<Component> _component;
      InstNode *_parent;
      std::unique_ptr<InstNodeType> _nodeType;

      mutable std::optional<MetaModelica::Value> _mmCache;
  };
}

#endif /* COMPONENTNODE_H */

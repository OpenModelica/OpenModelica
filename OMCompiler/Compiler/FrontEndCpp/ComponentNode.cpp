#include "Absyn/Component.h"
#include "Component.h"
#include "ComponentNode.h"

using namespace OpenModelica;

extern record_description NFInstNode_InstNode_COMPONENT__NODE__desc;

constexpr int NAME_INDEX = 0;
constexpr int DEFINITION_INDEX = 1;
constexpr int VISIBILITY_INDEX = 2;
constexpr int COMPONENT_INDEX = 3;
constexpr int PARENT_INDEX = 4;
constexpr int NODE_TYPE_INDEX = 5;

ComponentNode::ComponentNode(Absyn::Component *definition, InstNode *parent)
  : ComponentNode(definition, parent, std::make_unique<NormalComponentType>())
{

}

ComponentNode::ComponentNode(Absyn::Component *definition, InstNode *parent, std::unique_ptr<InstNodeType> nodeType)
  : _name{definition ? definition->name() : ""},
    _definition{definition},
    _visibility{definition ? definition->prefixes().visibility() : Visibility::Public},
    _component{std::make_unique<ComponentDef>(definition)},
    _parent{parent},
    _nodeType{std::move(nodeType)}
{

}

ComponentNode::~ComponentNode() = default;

const InstNodeType* ComponentNode::nodeType() const noexcept
{
  return _nodeType.get();
}

void ComponentNode::setNodeType(std::unique_ptr<InstNodeType> nodeType) noexcept
{
  _nodeType = std::move(nodeType);
  _mmCache.reset();
}

MetaModelica::Value ComponentNode::toMetaModelica() const
{
  // Nodes need to be cached to deal with the cyclical dependencies between nodes.
  if (!_mmCache) {
    auto comp_ptr = MetaModelica::Pointer();

    // Create a MetaModelica record for the node.
    auto rec = MetaModelica::Record{InstNode::COMPONENT_NODE, NFInstNode_InstNode_COMPONENT__NODE__desc, {
      MetaModelica::Value{_name},
      _definition->toSCode(),
      _visibility.toSCode(),
      comp_ptr,
      InstNode::emptyMMNode,
      MetaModelica::Value(static_cast<int64_t>(0))
    }};

    // Set the cache.
    _mmCache = rec;

    // Set any of the record members that might depend on this node now that we have a cached value.
    comp_ptr.update(_component->toNF());
    if (_parent) rec.set(PARENT_INDEX, _parent->toMetaModelica());
    rec.set(NODE_TYPE_INDEX, _nodeType->toMetaModelica());
  }

  return *_mmCache;
}

#include "Absyn/Class.h"
#include "Class.h"
#include "ClassNode.h"

using namespace OpenModelica;

ClassNode::ClassNode(Absyn::Class *cls, InstNode *parent)
  : ClassNode(cls, parent, std::make_unique<NormalClassType>())
{

}

ClassNode::ClassNode(Absyn::Class *cls, InstNode *parent, std::unique_ptr<InstNodeType> nodeType)
  : _name{cls ? cls->name() : ""},
    _definition{cls},
    _visibility{cls ? cls->prefixes().visibility() : Visibility::Public},
    _parentScope{parent},
    _nodeType{std::move(nodeType)}
{

}

ClassNode::~ClassNode() = default;

const InstNodeType* ClassNode::nodeType() const noexcept
{
  return _nodeType.get();
}

void ClassNode::setNodeType(std::unique_ptr<InstNodeType> nodeType) noexcept
{
  _nodeType = std::move(nodeType);
}

void ClassNode::partialInst()
{
  if (_cls) return;
  _cls = Class::fromAbsyn(*_definition, this);
}

void ClassNode::expand()
{

}

void ClassNode::instantiate()
{

}

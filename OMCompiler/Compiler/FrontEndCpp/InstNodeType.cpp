#include "Absyn/Element.h"
#include "Absyn/ElementVisitor.h"
#include "InstNode.h"
#include "InstNodeType.h"

using namespace OpenModelica;

//std::unique_ptr<InstNodeType> InstNodeType::fromAbsyn(Absyn::Element *element, InstNode *parent)
//{
//  if (element && element->isExtends()) {
//    return std::make_unique<BaseClassType>(parent, element);
//  }
//
//  return nullptr;
//}

bool BaseClassType::isBuiltin() const
{
  if (!_parent) return false;

  auto parent_ty = _parent->nodeType();
  return parent_ty ? parent_ty->isBuiltin() : false;
}

TopScopeType::TopScopeType(std::unique_ptr<InstNode> annotationScope)
  : _annotationScope(std::move(annotationScope))
{

}

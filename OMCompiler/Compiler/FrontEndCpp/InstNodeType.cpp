/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

extern "C" {
#include "meta/meta_modelica_builtin.h"
}

#include "MMUnorderedMap.h"
#include "Absyn/Element.h"
#include "Absyn/ElementVisitor.h"
#include "InstNode.h"
#include "InstNodeType.h"

using namespace OpenModelica;

extern record_description NFInstNode_InstNodeType_NORMAL__CLASS__desc;
extern record_description NFInstNode_InstNodeType_BASE__CLASS__desc;
extern record_description NFInstNode_InstNodeType_DERIVED__CLASS__desc;
extern record_description NFInstNode_InstNodeType_BUILTIN__CLASS__desc;
extern record_description NFInstNode_InstNodeType_TOP__SCOPE__desc;
extern record_description NFInstNode_InstNodeType_ROOT__CLASS__desc;
extern record_description NFInstNode_InstNodeType_NORMAL__COMP__desc;
extern record_description NFInstNode_InstNodeType_REDECLARED__COMP__desc;
extern record_description NFInstNode_InstNodeType_REDECLARED__CLASS__desc;
extern record_description NFInstNode_InstNodeType_GENERATED__INNER__desc;
extern record_description NFInstNode_InstNodeType_IMPLICIT__SCOPE__desc;

constexpr int NORMAL_CLASS = 0;
constexpr int BASE_CLASS = 1;
constexpr int DERIVED_CLASS = 2;
constexpr int BUILTIN_CLASS = 3;
constexpr int TOP_SCOPE = 4;
constexpr int ROOT_CLASS = 5;
constexpr int NORMAL_COMP = 6;
constexpr int REDECLARED_COMP = 7;
constexpr int REDECLARED_CLASS = 8;
constexpr int GENERATED_INNER = 9;
constexpr int IMPLICIT_SCOPE = 10;

extern record_description UnorderedMap_UNORDERED__MAP__desc;

//std::unique_ptr<InstNodeType> InstNodeType::fromAbsyn(Absyn::Element *element, InstNode *parent)
//{
//  if (element && element->isExtends()) {
//    return std::make_unique<BaseClassType>(parent, element);
//  }
//
//  return nullptr;
//}

std::unique_ptr<InstNodeType> InstNodeType::fromNF(MetaModelica::Record value)
{
  switch (value.index()) {
    case ROOT_CLASS: return std::make_unique<RootClassType>(value);
  }

  return nullptr;
}

std::unique_ptr<InstNodeType> NormalClassType::clone() const
{
  return std::make_unique<NormalClassType>(*this);
}

MetaModelica::Value NormalClassType::toNF() const
{
  return MetaModelica::Record{NORMAL_CLASS, NFInstNode_InstNodeType_NORMAL__CLASS__desc, {}};
}

std::unique_ptr<InstNodeType> BaseClassType::clone() const
{
  return std::make_unique<BaseClassType>(*this);
}

bool BaseClassType::isBuiltin() const
{
  if (!_parent) return false;

  auto parent_ty = _parent->nodeType();
  return parent_ty ? parent_ty->isBuiltin() : false;
}

MetaModelica::Value BaseClassType::toNF() const
{
  return MetaModelica::Record{BASE_CLASS, NFInstNode_InstNodeType_BASE__CLASS__desc, {
    _parent ? _parent->toNF() : InstNode::emptyMMNode(),
    _definition->toSCode(),
    // TODO: Use actual node type.
    NormalClassType().toNF()
  }};
}

std::unique_ptr<InstNodeType> DerivedClassType::clone() const
{
  return std::make_unique<DerivedClassType>(_ty->clone());
}

MetaModelica::Value DerivedClassType::toNF() const
{
  return MetaModelica::Record{DERIVED_CLASS, NFInstNode_InstNodeType_DERIVED__CLASS__desc, {
    _ty->toNF()
  }};
}

std::unique_ptr<InstNodeType> BuiltinClassType::clone() const
{
  return std::make_unique<BuiltinClassType>(*this);
}

MetaModelica::Value BuiltinClassType::toNF() const
{
  return MetaModelica::Record{BUILTIN_CLASS, NFInstNode_InstNodeType_BUILTIN__CLASS__desc, {}};
}

TopScopeType::TopScopeType(std::unique_ptr<InstNode> annotationScope)
  : _annotationScope(std::move(annotationScope))
{

}

std::unique_ptr<InstNodeType> TopScopeType::clone() const
{
  return std::make_unique<TopScopeType>(_annotationScope->clone());
}

MetaModelica::Value TopScopeType::toNF() const
{
  return MetaModelica::Record{TOP_SCOPE, NFInstNode_InstNodeType_TOP__SCOPE__desc, {
    _annotationScope->toNF(),
    MetaModelica::UnorderedMap<MetaModelica::Value, MetaModelica::Value>(boxvar_stringHashDjb2, boxvar_stringEq)
  }};
}

RootClassType::RootClassType(MetaModelica::Record value)
  : _parent{InstNode::getReference(value[0])}
{

}

std::unique_ptr<InstNodeType> RootClassType::clone() const
{
  return std::make_unique<RootClassType>(*this);
}

MetaModelica::Value RootClassType::toNF() const
{
  return MetaModelica::Record{ROOT_CLASS, NFInstNode_InstNodeType_ROOT__CLASS__desc, {
    _parent ? _parent->toNF() : InstNode::emptyMMNode()
  }};
}

std::unique_ptr<InstNodeType> NormalComponentType::clone() const
{
  return std::make_unique<NormalComponentType>(*this);
}

MetaModelica::Value NormalComponentType::toNF() const
{
  return MetaModelica::Record{NORMAL_COMP, NFInstNode_InstNodeType_NORMAL__COMP__desc, {}};
}

std::unique_ptr<InstNodeType> RedeclaredComponentType::clone() const
{
  return std::make_unique<RedeclaredComponentType>(*this);
}

MetaModelica::Value RedeclaredComponentType::toNF() const
{
  return MetaModelica::Record{REDECLARED_COMP, NFInstNode_InstNodeType_REDECLARED__COMP__desc, {
    _parent ? _parent->toNF() : InstNode::emptyMMNode()
  }};
}

std::unique_ptr<InstNodeType> RedeclaredClassType::clone() const
{
  return std::make_unique<RedeclaredClassType>(_parent, _ty->clone());
}

MetaModelica::Value RedeclaredClassType::toNF() const
{
  return MetaModelica::Record{REDECLARED_CLASS, NFInstNode_InstNodeType_REDECLARED__CLASS__desc, {
    _parent ? _parent->toNF() : InstNode::emptyMMNode()
  }};
}

std::unique_ptr<InstNodeType> GeneratedInnerType::clone() const
{
  return std::make_unique<GeneratedInnerType>(*this);
}

MetaModelica::Value GeneratedInnerType::toNF() const
{
  return MetaModelica::Record{GENERATED_INNER, NFInstNode_InstNodeType_GENERATED__INNER__desc};
}

std::unique_ptr<InstNodeType> ImplicitScopeType::clone() const
{
  return std::make_unique<ImplicitScopeType>(*this);
}

MetaModelica::Value ImplicitScopeType::toNF() const
{
  return MetaModelica::Record{IMPLICIT_SCOPE, NFInstNode_InstNodeType_IMPLICIT__SCOPE__desc};
}

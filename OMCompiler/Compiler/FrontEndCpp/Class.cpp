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

#include "Absyn/Class.h"
#include "Absyn/ClassDef.h"
#include "InstNode.h"
#include "Class.h"

using namespace OpenModelica;

constexpr int NOT_INSTANTIATED = 0;
constexpr int PARTIAL_CLASS = 1;
constexpr int PARTIAL_BUILTIN = 2;
constexpr int EXPANDED_CLASS = 3;
constexpr int EXPANDED_DERIVED = 4;
constexpr int INSTANCED_CLASS = 5;
constexpr int INSTANCED_BUILTIN = 6;
constexpr int TYPED_DERIVED = 7;
constexpr int DAE_TYPE = 8;

constexpr int PARTIAL_CLASS_ELEMENTS = 0;
constexpr int PARTIAL_CLASS_MODIFIER = 1;
constexpr int PARTIAL_CLASS_CC_MOD = 2;
constexpr int PARTIAL_CLASS_PREFIXES = 3;

constexpr int PARTIAL_BUILTIN_TY = 0;
constexpr int PARTIAL_BUILTIN_ELEMENTS = 1;
constexpr int PARTIAL_BUILTIN_MODIFIER = 2;
constexpr int PARTIAL_BUILTIN_PREFIXES = 3;
constexpr int PARTIAL_BUILTIN_RESTRICTION = 4;

constexpr int EXPANDED_CLASS_ELEMENTS = 0;
constexpr int EXPANDED_CLASS_MODIFIER = 1;
constexpr int EXPANDED_CLASS_CC_MOD = 2;
constexpr int EXPANDED_CLASS_PREFIXES = 3;
constexpr int EXPANDED_CLASS_RESTRICTION = 4;

constexpr int EXPANDED_DERIVED_BASE_CLASS = 0;
constexpr int EXPANDED_DERIVED_MODIFIER = 1;
constexpr int EXPANDED_DERIVED_CC_MOD = 2;
constexpr int EXPANDED_DERIVED_DIMS = 3;
constexpr int EXPANDED_DERIVED_PREFIXES = 4;
constexpr int EXPANDED_DERIVED_ATTRIBUTES = 5;
constexpr int EXPANDED_DERIVED_RESTRICTION = 6;

constexpr int INSTANCED_CLASS_TY = 0;
constexpr int INSTANCED_CLASS_ELEMENTS = 1;
constexpr int INSTANCED_CLASS_SECTIONS = 2;
constexpr int INSTANCED_CLASS_PREFIXES = 3;
constexpr int INSTANCED_CLASS_RESTRICTION = 4;

constexpr int INSTANCED_BUILTIN_TY = 0;
constexpr int INSTANCED_BUILTIN_ELEMENTS = 1;
constexpr int INSTANCED_BUILTIN_RESTRICTION = 2;

constexpr int TYPED_DERIVED_TY = 0;
constexpr int TYPED_DERIVED_BASE_CLASS = 1;
constexpr int TYPED_DERIVED_RESTRICTION = 2;

constexpr int DAE_TYPE_TY = 0;


extern record_description NFClass_PARTIAL__CLASS__desc;
extern record_description NFClass_PARTIAL__BUILTIN__desc;
extern record_description NFClass_EXPANDED__CLASS__desc;
extern record_description NFClass_EXPANDED__DERIVED__desc;
extern record_description NFClass_INSTANCED__CLASS__desc;
extern record_description NFClass_INSTANCED__BUILTIN__desc;
extern record_description NFClass_TYPED__DERIVED__desc;
extern record_description NFClass_DAE__TYPE__desc;

extern record_description NFClass_Prefixes_PREFIXES__desc;

Class::Prefixes::Prefixes(MetaModelica::Record value)
  : encapsulated{value[0]},
    partial{value[1]},
    final{value[2]},
    innerOuter{value[3]},
    replaceable{value[4]}
{

}

MetaModelica::Value Class::Prefixes::toNF() const noexcept
{
  return MetaModelica::Record{0, NFClass_Prefixes_PREFIXES__desc, {
    encapsulated.toSCode(),
    partial.toSCode(),
    final.toSCode(),
    innerOuter.toAbsyn(),
    replaceable.toSCode()
  }};
}

Class::Class(MetaModelica::Record value)
  : _mm_value{value}
{

}

std::unique_ptr<Class> Class::fromMM(MetaModelica::Record value)
{
  switch (value.index()) {
    case PARTIAL_CLASS:     return std::make_unique<PartialClass>(value);
    case PARTIAL_BUILTIN:   return std::make_unique<PartialBuiltin>(value);
    case EXPANDED_CLASS:    return std::make_unique<ExpandedClass>(value);
    case EXPANDED_DERIVED:  return std::make_unique<ExpandedDerived>(value);
    case INSTANCED_CLASS:   return std::make_unique<InstancedClass>(value);
    case INSTANCED_BUILTIN: return std::make_unique<InstancedBuiltin>(value);
    case TYPED_DERIVED:     return std::make_unique<TypedDerived>(value);
    case DAE_TYPE:          return std::make_unique<DAEType>(value);
  }

  return nullptr;
}

std::unique_ptr<Class> Class::fromAbsyn(const Absyn::Class &cls, InstNode *scope)
{
  struct Visitor : public Absyn::ClassDefVisitor
  {
    Visitor(InstNode *scope) : scope{scope} {}

    void visit(const Absyn::ClassParts &def)
    {
      cls = std::make_unique<PartialClass>(def, false, scope);
    }

    //void visit(Absyn::ClassExtends &def) {
    //  classDef = std::make_unique<ClassTree>(def.composition(), true, scope);
    //}

    //void visit(Absyn::Enumeration &def) {
    //  classDef = std::make_unique<ClassTree>(def);
    //}

    InstNode *scope;
    std::unique_ptr<Class> cls;
  };

  Visitor visitor{scope};
  cls.definition().apply(visitor);
  return std::move(visitor.cls);
}

Class::~Class() = default;

bool Class::add(std::unique_ptr<InstNode> node)
{
  auto cls_tree = classTree();
  return cls_tree && cls_tree->add(std::move(node));
}

PartialClass::PartialClass(MetaModelica::Record value)
  : Class(value),
   _elements{value[PARTIAL_CLASS_ELEMENTS]},
   _modifier{value[PARTIAL_CLASS_MODIFIER]},
   _ccMod{value[PARTIAL_CLASS_CC_MOD]},
   _prefixes{value[PARTIAL_CLASS_PREFIXES]}
{

}

PartialClass::PartialClass(const Absyn::ClassParts &definition, bool isClassExtends, InstNode *scope)
  : _elements{definition, isClassExtends, scope}
{

}

std::unique_ptr<Class> PartialClass::clone() const
{
  return std::make_unique<PartialClass>(*this);
}

MetaModelica::Value PartialClass::toNF() const
{
  return MetaModelica::Record{PARTIAL_CLASS, NFClass_PARTIAL__CLASS__desc, {
    _elements.toNF(),
    _modifier.toNF(),
    _ccMod.toNF(),
    _prefixes.toNF()
  }};
}

PartialBuiltin::PartialBuiltin(MetaModelica::Record value)
  : Class(value),
    _ty{value[PARTIAL_BUILTIN_TY]},
    _elements{value[PARTIAL_BUILTIN_ELEMENTS]},
    _modifier{value[PARTIAL_BUILTIN_MODIFIER]},
    _prefixes{value[PARTIAL_BUILTIN_PREFIXES]},
    _restriction{value[PARTIAL_BUILTIN_RESTRICTION]}
{

}

std::unique_ptr<Class> PartialBuiltin::clone() const
{
  return std::make_unique<PartialBuiltin>(*this);
}

MetaModelica::Value PartialBuiltin::toNF() const
{
  return MetaModelica::Record{PARTIAL_BUILTIN, NFClass_PARTIAL__BUILTIN__desc, {
    _ty,
    _elements.toNF(),
    _modifier.toNF(),
    _prefixes.toNF(),
    _restriction.toNF()
  }};
}

ExpandedClass::ExpandedClass(MetaModelica::Record value)
  : Class(value),
    _elements{value[EXPANDED_CLASS_ELEMENTS]},
    _modifier{value[EXPANDED_CLASS_MODIFIER]},
    _ccMod{value[EXPANDED_CLASS_CC_MOD]},
    _prefixes{value[EXPANDED_CLASS_PREFIXES]},
    _restriction{value[EXPANDED_CLASS_RESTRICTION]}
{

}

std::unique_ptr<Class> ExpandedClass::clone() const
{
  return std::make_unique<ExpandedClass>(*this);
}

MetaModelica::Value ExpandedClass::toNF() const
{
  return MetaModelica::Record{EXPANDED_CLASS, NFClass_EXPANDED__CLASS__desc, {
    _elements.toNF(),
    _modifier.toNF(),
    _ccMod.toNF(),
    _prefixes.toNF(),
    _restriction.toNF()
  }};
}

ExpandedDerived::ExpandedDerived(std::unique_ptr<InstNode> baseClass, Modifier modifier,
  Modifier ccMod, std::vector<Dimension> dims, Prefixes prefixes, Attributes attributes, Restriction restriction)
  : _baseClass{std::move(baseClass)},
    _modifier{std::move(modifier)},
    _ccMod{std::move(ccMod)},
    _dims{std::move(dims)},
    _prefixes{std::move(prefixes)},
    _attributes{std::move(attributes)},
    _restriction{restriction}
{

}

ExpandedDerived::ExpandedDerived(MetaModelica::Record value)
  : Class(value),
    _baseClass{InstNode::getOwnedPtr(value[EXPANDED_DERIVED_BASE_CLASS])},
    _modifier{value[EXPANDED_DERIVED_MODIFIER]},
    _ccMod{value[EXPANDED_DERIVED_CC_MOD]},
    _dims{value[EXPANDED_DERIVED_DIMS].mapVector<Dimension>()},
    _prefixes{value[EXPANDED_DERIVED_PREFIXES]},
    _attributes{value[EXPANDED_DERIVED_ATTRIBUTES]},
    _restriction{value[EXPANDED_DERIVED_PREFIXES]}
{

}

std::unique_ptr<Class> ExpandedDerived::clone() const
{
  return std::make_unique<ExpandedDerived>(_baseClass->clone(), _modifier, _ccMod, _dims, _prefixes, _attributes, _restriction);
}

const ClassTree* ExpandedDerived::classTree() const noexcept
{
  return _baseClass->getClass()->classTree();
}

ClassTree* ExpandedDerived::classTree() noexcept
{
  return _baseClass->getClass()->classTree();
}

MetaModelica::Value ExpandedDerived::toNF() const
{
  return MetaModelica::Record{EXPANDED_DERIVED, NFClass_EXPANDED__DERIVED__desc, {
    _baseClass->toNF(),
    _modifier.toNF(),
    _ccMod.toNF(),
    MetaModelica::List{_dims, [](auto &d) { return d.toNF(); }},
    _prefixes.toNF(),
    _attributes.toNF(),
    _restriction.toNF()
  }};
}

InstancedClass::InstancedClass(MetaModelica::Record value)
  : Class(value),
    _ty{value[INSTANCED_CLASS_TY]},
    _elements{value[INSTANCED_CLASS_ELEMENTS]},
    _sections{value[INSTANCED_CLASS_SECTIONS]},
    _prefixes{value[INSTANCED_CLASS_PREFIXES]},
    _restriction{value[INSTANCED_CLASS_RESTRICTION]}
{

}

std::unique_ptr<Class> InstancedClass::clone() const
{
  return std::make_unique<InstancedClass>(*this);
}

MetaModelica::Value InstancedClass::toNF() const
{
  return MetaModelica::Record{INSTANCED_CLASS, NFClass_INSTANCED__CLASS__desc, {
    _ty,
    _elements.toNF(),
    _sections,
    _prefixes.toNF(),
    _restriction.toNF()
  }};
}

InstancedBuiltin::InstancedBuiltin(MetaModelica::Record value)
  : Class(value),
    _ty{value[INSTANCED_BUILTIN_TY]},
    _elements{value[INSTANCED_BUILTIN_ELEMENTS]},
    _restriction{value[INSTANCED_BUILTIN_RESTRICTION]}
{

}

std::unique_ptr<Class> InstancedBuiltin::clone() const
{
  return std::make_unique<InstancedBuiltin>(*this);
}

MetaModelica::Value InstancedBuiltin::toNF() const
{
  return MetaModelica::Record{INSTANCED_BUILTIN, NFClass_INSTANCED__BUILTIN__desc, {
    _ty,
    _elements.toNF(),
    _restriction.toNF()
  }};
}

TypedDerived::TypedDerived(Type ty, std::unique_ptr<InstNode> baseClass, Restriction restriction)
  : _ty{ty}, _baseClass{std::move(baseClass)}, _restriction{restriction}
{

}

TypedDerived::TypedDerived(MetaModelica::Record value)
  : Class(value),
    _ty{value[TYPED_DERIVED_TY]},
    _baseClass{InstNode::getOwnedPtr(value[TYPED_DERIVED_BASE_CLASS])},
    _restriction{value[TYPED_DERIVED_RESTRICTION]}
{

}

std::unique_ptr<Class> TypedDerived::clone() const
{
  return std::make_unique<TypedDerived>(_ty, _baseClass->clone(), _restriction);
}

const ClassTree* TypedDerived::classTree() const noexcept
{
  return _baseClass->getClass()->classTree();
}

ClassTree* TypedDerived::classTree() noexcept
{
  return _baseClass->getClass()->classTree();
}

MetaModelica::Value TypedDerived::toNF() const
{
  return MetaModelica::Record{TYPED_DERIVED, NFClass_TYPED__DERIVED__desc, {
    _ty,
    _baseClass->toNF(),
    _restriction.toNF()
  }};
}

DAEType::DAEType(MetaModelica::Record value)
  : Class(value),
    _ty{value[DAE_TYPE_TY]}
{

}

std::unique_ptr<Class> DAEType::clone() const
{
  return std::make_unique<DAEType>(*this);
}

MetaModelica::Value DAEType::toNF() const
{
  return MetaModelica::Record{DAE_TYPE, NFClass_DAE__TYPE__desc, {
    _ty
  }};
}


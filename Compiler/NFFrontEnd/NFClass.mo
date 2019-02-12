/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFClass

import NFInstNode.InstNode;
import NFModifier.Modifier;
import NFStatement.Statement;
import SCode.Element;
import Type = NFType;
import NFComponent.Component;
import Dimension = NFDimension;
import NFClassTree.ClassTree;
import NFSections.Sections;
import Restriction = NFRestriction;
import Expression = NFExpression;

protected
import NFBinding.Binding;
import ComplexType = NFComplexType;
import System;

public

constant Class.Prefixes DEFAULT_PREFIXES = Class.Prefixes.PREFIXES(
  SCode.Encapsulated.NOT_ENCAPSULATED(),
  SCode.Partial.NOT_PARTIAL(),
  SCode.Final.NOT_FINAL(),
  Absyn.InnerOuter.NOT_INNER_OUTER(),
  SCode.Replaceable.NOT_REPLACEABLE()
);

uniontype Class
  uniontype Prefixes
    record PREFIXES
      SCode.Encapsulated encapsulatedPrefix;
      SCode.Partial partialPrefix;
      SCode.Final finalPrefix;
      Absyn.InnerOuter innerOuter;
      SCode.Replaceable replaceablePrefix;
    end PREFIXES;

    function isEqual
      input Prefixes prefs1;
      input Prefixes prefs2;
      output Boolean isEqual = valueEq(prefs1, prefs2);
    end isEqual;
  end Prefixes;

  record NOT_INSTANTIATED end NOT_INSTANTIATED;

  record PARTIAL_CLASS
    ClassTree elements;
    Modifier modifier;
    Class.Prefixes prefixes;
  end PARTIAL_CLASS;

  record PARTIAL_BUILTIN
    Type ty;
    ClassTree elements;
    Modifier modifier;
    Restriction restriction;
  end PARTIAL_BUILTIN;

  record EXPANDED_CLASS
    ClassTree elements;
    Modifier modifier;
    Class.Prefixes prefixes;
    Restriction restriction;
  end EXPANDED_CLASS;

  record EXPANDED_DERIVED
    InstNode baseClass;
    Modifier modifier;
    array<Dimension> dims;
    Class.Prefixes prefixes;
    Component.Attributes attributes;
    Restriction restriction;
  end EXPANDED_DERIVED;

  record INSTANCED_CLASS
    Type ty;
    ClassTree elements;
    Sections sections;
    Restriction restriction;
  end INSTANCED_CLASS;

  record INSTANCED_BUILTIN
    Type ty;
    ClassTree elements;
    Restriction restriction;
  end INSTANCED_BUILTIN;

  record TYPED_DERIVED
    Type ty;
    InstNode baseClass;
    Restriction restriction;
  end TYPED_DERIVED;

  record DAE_TYPE
    DAE.Type ty;
  end DAE_TYPE;

  function fromSCode
    input list<SCode.Element> elements;
    input Boolean isClassExtends;
    input InstNode scope;
    input Prefixes prefixes;
    output Class cls;
  protected
    ClassTree tree;
  algorithm
    tree := ClassTree.fromSCode(elements, isClassExtends, scope);
    cls := PARTIAL_CLASS(tree, Modifier.NOMOD(), prefixes);
  end fromSCode;

  function fromEnumeration
    input list<SCode.Enum> literals;
    input Type enumType;
    input InstNode enumClass;
    output Class cls;
  protected
    ClassTree tree;
  algorithm
    tree := ClassTree.fromEnumeration(literals, enumType, enumClass);
    cls := PARTIAL_BUILTIN(enumType, tree, Modifier.NOMOD(),
      Restriction.ENUMERATION());
  end fromEnumeration;

  function makeRecordConstructor
    input list<InstNode> inputs;
    input list<InstNode> locals;
    input InstNode out;
    output Class cls;
  protected
    ClassTree tree;
  algorithm
    tree := ClassTree.fromRecordConstructor(inputs, locals, out);
    cls := INSTANCED_CLASS(Type.UNKNOWN(), tree, Sections.EMPTY(), Restriction.RECORD_CONSTRUCTOR());
  end makeRecordConstructor;

  function initExpandedClass
    input output Class cls;
  algorithm
    cls := match cls
      case PARTIAL_CLASS()
        then EXPANDED_CLASS(cls.elements, cls.modifier, cls.prefixes, Restriction.UNKNOWN());
    end match;
  end initExpandedClass;

  function getSections
    input Class cls;
    output Sections sections;
  algorithm
    sections := match cls
      case INSTANCED_CLASS() then cls.sections;
      case TYPED_DERIVED() then getSections(InstNode.getClass(cls.baseClass));
      else Sections.EMPTY();
    end match;
  end getSections;

  function setSections
    input Sections sections;
    input output Class cls;
  algorithm
    cls := match cls
      case INSTANCED_CLASS()
        then INSTANCED_CLASS(cls.ty, cls.elements, sections, cls.restriction);
    end match;
  end setSections;

  function lookupElement
    input String name;
    input Class cls;
    output InstNode node;
    output Boolean isImport;
  algorithm
    (node, isImport) := ClassTree.lookupElement(name, classTree(cls));
  end lookupElement;

  function lookupComponentIndex
    input String name;
    input Class cls;
    output Integer index;
  algorithm
    index := ClassTree.lookupComponentIndex(name, classTree(cls));
  end lookupComponentIndex;

  function nthComponent
    input Integer index;
    input Class cls;
    output InstNode component;
  algorithm
    component := ClassTree.nthComponent(index, classTree(cls));
  end nthComponent;

  function lookupAttributeBinding
    input String name;
    input Class cls;
    output Binding binding;
  protected
    InstNode attr_node;
  algorithm
    try
      attr_node := ClassTree.lookupElement(name, classTree(cls));
      binding := Component.getBinding(InstNode.component(attr_node));
    else
      binding := NFBinding.EMPTY_BINDING;
    end try;
  end lookupAttributeBinding;

  function lookupAttributeValue
    input String name;
    input Class cls;
    output Option<Expression> value = Binding.typedExp(lookupAttributeBinding(name, cls));
  end lookupAttributeValue;

  function isBuiltin
    input Class cls;
    output Boolean isBuiltin;
  algorithm
    isBuiltin := match cls
      case PARTIAL_BUILTIN() then true;
      case INSTANCED_BUILTIN() then true;
      case EXPANDED_DERIVED() then isBuiltin(InstNode.getClass(cls.baseClass));
      case TYPED_DERIVED() then isBuiltin(InstNode.getClass(cls.baseClass));
      else false;
    end match;
  end isBuiltin;

  function classTree
    input Class cls;
    output ClassTree tree;
  algorithm
    tree := match cls
      case Class.PARTIAL_CLASS() then cls.elements;
      case Class.PARTIAL_BUILTIN() then cls.elements;
      case Class.EXPANDED_CLASS() then cls.elements;
      case Class.EXPANDED_DERIVED() then classTree(InstNode.getClass(cls.baseClass));
      case Class.INSTANCED_CLASS() then cls.elements;
      case Class.INSTANCED_BUILTIN() then cls.elements;
      case Class.TYPED_DERIVED() then classTree(InstNode.getClass(cls.baseClass));
    end match;
  end classTree;

  function setClassTree
    input ClassTree tree;
    input output Class cls;
  algorithm
    () := match cls
      case Class.PARTIAL_CLASS() algorithm cls.elements := tree; then ();
      case Class.EXPANDED_CLASS() algorithm cls.elements := tree; then ();
      case Class.PARTIAL_BUILTIN() algorithm cls.elements := tree; then ();
      case Class.INSTANCED_CLASS() algorithm cls.elements := tree; then ();
      case Class.INSTANCED_BUILTIN() algorithm cls.elements := tree; then ();
    end match;
  end setClassTree;

  function classTreeApply
    input output Class cls;
    input FuncType func;

    partial function FuncType
      input output ClassTree tree;
    end FuncType;
  algorithm
    () := match cls
      case Class.PARTIAL_CLASS()     algorithm cls.elements := func(cls.elements); then ();
      case Class.EXPANDED_CLASS()    algorithm cls.elements := func(cls.elements); then ();
      case Class.PARTIAL_BUILTIN()   algorithm cls.elements := func(cls.elements); then ();
      case Class.INSTANCED_CLASS()   algorithm cls.elements := func(cls.elements); then ();
      case Class.INSTANCED_BUILTIN() algorithm cls.elements := func(cls.elements); then ();
      else ();
    end match;
  end classTreeApply;

  function getModifier
    input Class cls;
    output Modifier modifier;
  algorithm
    modifier := match cls
      case PARTIAL_CLASS() then cls.modifier;
      case EXPANDED_CLASS() then cls.modifier;
      case EXPANDED_DERIVED() then cls.modifier;
      case PARTIAL_BUILTIN() then cls.modifier;
      else Modifier.NOMOD();
    end match;
  end getModifier;

  function setModifier
    input Modifier modifier;
    input output Class cls;
  algorithm
    () := match cls
      case PARTIAL_CLASS()
        algorithm
          cls.modifier := modifier;
        then
          ();
      case EXPANDED_CLASS()
        algorithm
          cls.modifier := modifier;
        then
          ();
      case EXPANDED_DERIVED()
        algorithm
          cls.modifier := modifier;
        then
          ();
      case PARTIAL_BUILTIN()
        algorithm
          cls.modifier := modifier;
        then
          ();
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got non-modifiable class", sourceInfo());
        then
          fail();
    end match;
  end setModifier;

  function mergeModifier
    input Modifier modifier;
    input output Class cls;
  algorithm
    () := match cls
      case PARTIAL_CLASS()
        algorithm
          cls.modifier := Modifier.merge(modifier, cls.modifier);
        then
          ();
      case EXPANDED_CLASS()
        algorithm
          cls.modifier := Modifier.merge(modifier, cls.modifier);
        then
          ();
      case EXPANDED_DERIVED()
        algorithm
          cls.modifier := Modifier.merge(modifier, cls.modifier);
        then
          ();
      case PARTIAL_BUILTIN()
        algorithm
          cls.modifier := Modifier.merge(modifier, cls.modifier);
        then
          ();
      else
        algorithm
          Error.assertion(false, getInstanceName() + " got non-modifiable class", sourceInfo());
        then
          fail();
    end match;
  end mergeModifier;

  function isIdentical
    input Class cls1;
    input Class cls2;
    output Boolean identical = false;
  algorithm
    if referenceEq(cls1, cls2) then
      identical := true;
    else
      identical := match (cls1, cls2)
        case (EXPANDED_CLASS(), EXPANDED_CLASS())
          then Prefixes.isEqual(cls1.prefixes, cls2.prefixes) and
               ClassTree.isIdentical(cls1.elements, cls2.elements);

        case (INSTANCED_BUILTIN(), INSTANCED_BUILTIN())
          algorithm
            if not Type.isEqual(cls1.ty, cls2.ty) then
              return;
            end if;
          then
            true;

        else true;
      end match;
    end if;
  end isIdentical;

  function getDimensions
    input Class cls;
    output list<Dimension> dims;
  algorithm
    dims := match cls
      case INSTANCED_CLASS() then Type.arrayDims(cls.ty);
      case INSTANCED_BUILTIN() then Type.arrayDims(cls.ty);
      case TYPED_DERIVED() then Type.arrayDims(cls.ty);
      else {};
    end match;
  end getDimensions;

  function getAttributes
    input Class cls;
    output Component.Attributes attr;
  algorithm
    attr := match cls
      case EXPANDED_DERIVED() then cls.attributes;
      else NFComponent.DEFAULT_ATTR;
    end match;
  end getAttributes;

  function getTypeAttributes
    input Class cls;
    output list<Modifier> attributes = {};
  protected
    array<InstNode> comps;
    Modifier mod;
  algorithm
    try
      comps := ClassTree.getComponents(classTree(cls));

      for c in comps loop
        mod := Component.getModifier(InstNode.component(c));

        if not Modifier.isEmpty(mod) then
          attributes := mod :: attributes;
        end if;
      end for;
    else
    end try;
  end getTypeAttributes;

  function getType
    input Class cls;
    input InstNode clsNode;
    output Type ty;
  algorithm
    ty := match cls
      case PARTIAL_BUILTIN() then cls.ty;
      case EXPANDED_DERIVED() then getType(InstNode.getClass(cls.baseClass), cls.baseClass);
      case INSTANCED_CLASS() then cls.ty;
      case INSTANCED_BUILTIN()
        then match cls.ty
          case Type.POLYMORPHIC("") then Type.POLYMORPHIC(InstNode.name(clsNode));
          else cls.ty;
        end match;
      case TYPED_DERIVED() then cls.ty;
      else Type.UNKNOWN();
    end match;
  end getType;

  function restriction
    input Class cls;
    output Restriction res;
  algorithm
    res := match cls
      case PARTIAL_BUILTIN() then cls.restriction;
      case EXPANDED_CLASS() then cls.restriction;
      case EXPANDED_DERIVED() then cls.restriction;
      case INSTANCED_CLASS() then cls.restriction;
      case INSTANCED_BUILTIN() then cls.restriction;
      case TYPED_DERIVED() then cls.restriction;
      else Restriction.UNKNOWN();
    end match;
  end restriction;

  function setRestriction
    input Restriction res;
    input output Class cls;
  algorithm
    () := match cls
      // PARTIAL_BUILTIN is only used for predefined builtin types and not needed here.
      case EXPANDED_CLASS()    algorithm cls.restriction := res; then ();
      case EXPANDED_DERIVED()  algorithm cls.restriction := res; then ();
      case INSTANCED_CLASS()   algorithm cls.restriction := res; then ();
      case INSTANCED_BUILTIN() algorithm cls.restriction := res; then ();
      case TYPED_DERIVED()     algorithm cls.restriction := res; then ();
    end match;
  end setRestriction;

  function isConnectorClass
    input Class cls;
    output Boolean isConnector = Restriction.isConnector(restriction(cls));
  end isConnectorClass;

  function isExpandableConnectorClass
    input Class cls;
    output Boolean isConnector = Restriction.isExpandableConnector(restriction(cls));
  end isExpandableConnectorClass;

  function isExternalObject
    input Class cls;
    output Boolean isExternalObject = Restriction.isExternalObject(restriction(cls));
  end isExternalObject;

  function isFunction
    input Class cls;
    output Boolean isFunction = Restriction.isFunction(restriction(cls));
  end isFunction;

  function isExternalFunction
    input Class cls;
    output Boolean isExtFunc;
  algorithm
    isExtFunc := match cls
      local
        String lang;

      case EXPANDED_DERIVED() then isExternalFunction(InstNode.getClass(cls.baseClass));
      case INSTANCED_CLASS(sections = Sections.EXTERNAL(language = lang)) then lang <> "builtin";
      case TYPED_DERIVED() then isExternalFunction(InstNode.getClass(cls.baseClass));
      else false;
    end match;
  end isExternalFunction;

  function isOverdetermined
    input Class cls;
    output Boolean isOverdetermined;
  algorithm
    try
      lookupElement("equalityConstraint", cls);
      // set the external flag that signals the presence of expandable connectors in the model
      System.setHasOverconstrainedConnectors(true);
      isOverdetermined := true;
    else
      isOverdetermined := false;
    end try;
  end isOverdetermined;

  function getPrefixes
    input Class cls;
    output Prefixes prefs;
  algorithm
    prefs := match cls
      case PARTIAL_CLASS() then cls.prefixes;
      case EXPANDED_CLASS() then cls.prefixes;
      case EXPANDED_DERIVED() then cls.prefixes;
    end match;
  end getPrefixes;

  function setPrefixes
    input Prefixes prefs;
    input output Class cls;
  algorithm
    () := match cls
      case EXPANDED_CLASS()
        algorithm
          cls.prefixes := prefs;
        then
          ();

      case EXPANDED_DERIVED()
        algorithm
          cls.prefixes := prefs;
        then
          ();

    end match;
  end setPrefixes;

  function isEncapsulated
    input Class cls;
    output Boolean isEncapsulated;
  algorithm
    isEncapsulated := match cls
      case PARTIAL_CLASS() then SCode.encapsulatedBool(cls.prefixes.encapsulatedPrefix);
      case EXPANDED_CLASS() then SCode.encapsulatedBool(cls.prefixes.encapsulatedPrefix);
      case EXPANDED_DERIVED() then SCode.encapsulatedBool(cls.prefixes.encapsulatedPrefix);
      else false;
    end match;
  end isEncapsulated;

  function lastBaseClass
    input output InstNode node;
  protected
    Class cls = InstNode.getClass(node);
  algorithm
    node := match cls
      case EXPANDED_DERIVED() then lastBaseClass(cls.baseClass);
      case TYPED_DERIVED() then lastBaseClass(cls.baseClass);
      else node;
    end match;
  end lastBaseClass;

  function getDerivedComments
    input Class cls;
    input output list<SCode.Comment> cmts;
  algorithm
    cmts := match cls
      case EXPANDED_DERIVED() then InstNode.getComments(cls.baseClass, cmts);
      case TYPED_DERIVED() then InstNode.getComments(cls.baseClass, cmts);
      else cmts;
    end match;
  end getDerivedComments;
end Class;

annotation(__OpenModelica_Interface="frontend");
end NFClass;

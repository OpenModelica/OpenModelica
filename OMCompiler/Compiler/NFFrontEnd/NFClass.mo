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

encapsulated uniontype NFClass

import Component = NFComponent;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFClassTree.ClassTree;
import NFInstNode.InstNode;
import NFModifier.Modifier;
import NFSections.Sections;
import NFStatement.Statement;
import Restriction = NFRestriction;
import SCode.Element;
import Type = NFType;

protected
import AbsynUtil;
import Binding = NFBinding;
import Class = NFClass;
import ComplexType = NFComplexType;
import IOStream;
import SCodeUtil;
import System;

public

constant Prefixes DEFAULT_PREFIXES = Prefixes.PREFIXES(
  SCode.Encapsulated.NOT_ENCAPSULATED(),
  SCode.Partial.NOT_PARTIAL(),
  SCode.Final.NOT_FINAL(),
  Absyn.InnerOuter.NOT_INNER_OUTER(),
  SCode.Replaceable.NOT_REPLACEABLE()
);

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

    function isPartial
      input Prefixes prefs;
      output Boolean isPartial = SCodeUtil.partialBool(prefs.partialPrefix);
    end isPartial;

    function isEncapsulated
      input Prefixes prefs;
      output Boolean isEncapsulated = SCodeUtil.encapsulatedBool(prefs.encapsulatedPrefix);
    end isEncapsulated;
  end Prefixes;

  record NOT_INSTANTIATED end NOT_INSTANTIATED;

  record PARTIAL_CLASS
    ClassTree elements;
    Modifier modifier;
    Modifier ccMod;
    Prefixes prefixes;
  end PARTIAL_CLASS;

  record PARTIAL_BUILTIN
    Type ty;
    ClassTree elements;
    Modifier modifier;
    Prefixes prefixes;
    Restriction restriction;
  end PARTIAL_BUILTIN;

  record EXPANDED_CLASS
    ClassTree elements;
    Modifier modifier;
    Modifier ccMod;
    Prefixes prefixes;
    Restriction restriction;
  end EXPANDED_CLASS;

  record EXPANDED_DERIVED
    InstNode baseClass;
    Modifier modifier;
    Modifier ccMod;
    array<Dimension> dims;
    Prefixes prefixes;
    Component.Attributes attributes;
    Restriction restriction;
  end EXPANDED_DERIVED;

  record INSTANCED_CLASS
    Type ty;
    ClassTree elements;
    Sections sections;
    Prefixes prefixes;
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
    cls := PARTIAL_CLASS(tree, Modifier.NOMOD(), Modifier.NOMOD(), prefixes);
  end fromSCode;

  function fromEnumeration
    input list<SCode.Enum> literals;
    input Type enumType;
    input Prefixes prefixes;
    input InstNode enumClass;
    output Class cls;
  protected
    ClassTree tree;
  algorithm
    tree := ClassTree.fromEnumeration(literals, enumType, enumClass);
    cls := PARTIAL_BUILTIN(enumType, tree, Modifier.NOMOD(), prefixes, Restriction.ENUMERATION());
  end fromEnumeration;

  function makeRecordConstructor
    input list<InstNode> fields;
    input InstNode out;
    output Class cls;
  protected
    ClassTree tree;
  algorithm
    tree := ClassTree.fromRecordConstructor(fields, out);
    cls := INSTANCED_CLASS(Type.UNKNOWN(), tree, Sections.EMPTY(),
      DEFAULT_PREFIXES, Restriction.RECORD_CONSTRUCTOR());
  end makeRecordConstructor;

  function initExpandedClass
    input output Class cls;
  algorithm
    cls := match cls
      case PARTIAL_CLASS()
        then EXPANDED_CLASS(cls.elements, cls.modifier, cls.ccMod, cls.prefixes, Restriction.UNKNOWN());
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
        then INSTANCED_CLASS(cls.ty, cls.elements, sections, cls.prefixes, cls.restriction);
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
      else ClassTree.EMPTY_TREE();
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

  function getCCModifier
    input Class cls;
    output Modifier modifier;
  algorithm
    modifier := match cls
      case PARTIAL_CLASS() then cls.ccMod;
      case EXPANDED_CLASS() then cls.ccMod;
      case EXPANDED_DERIVED() then cls.ccMod;
      else Modifier.NOMOD();
    end match;
  end getCCModifier;

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

  function hasDimensions
    input Class cls;
    output Boolean hasDims;
  algorithm
    hasDims := match cls
      case EXPANDED_DERIVED()
        then arrayLength(cls.dims) > 0 or hasDimensions(InstNode.getClass(cls.baseClass));
      case TYPED_DERIVED() then Type.isArray(cls.ty);
      else false;
    end match;
  end hasDimensions;

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

  function dimensionCount
    input Class cls;
    output Integer count;
  algorithm
    count := match cls
      case EXPANDED_DERIVED() then arrayLength(cls.dims);
      case INSTANCED_CLASS() then Type.dimensionCount(cls.ty);
      case INSTANCED_BUILTIN() then Type.dimensionCount(cls.ty);
      case TYPED_DERIVED() then Type.dimensionCount(cls.ty);
      else 0;
    end match;
  end dimensionCount;

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
      case INSTANCED_BUILTIN() then cls.ty;
      case TYPED_DERIVED() then cls.ty;
      else Type.UNKNOWN();
    end match;
  end getType;

  function setType
    input Type ty;
    input output Class cls;
  algorithm
    () := match cls
      case PARTIAL_BUILTIN()
        algorithm
          cls.ty := ty;
        then
          ();

      case EXPANDED_DERIVED()
        algorithm
          InstNode.classApply(cls.baseClass, setType, ty);
        then
          ();

      case INSTANCED_CLASS()
        algorithm
          cls.ty := ty;
        then
          ();

      case INSTANCED_BUILTIN()
        algorithm
          cls.ty := ty;
        then
          ();

      case TYPED_DERIVED()
        algorithm
          cls.ty := ty;
        then
          ();

      else ();
    end match;
  end setType;

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

  function isNonexpandableConnectorClass
    input Class cls;
    output Boolean isConnector = Restriction.isNonexpandableConnector(restriction(cls));
  end isNonexpandableConnectorClass;

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
      case PARTIAL_BUILTIN() then cls.prefixes;
      case EXPANDED_CLASS() then cls.prefixes;
      case EXPANDED_DERIVED() then cls.prefixes;
      case INSTANCED_CLASS() then cls.prefixes;
      case TYPED_DERIVED() then getPrefixes(InstNode.getClass(cls.baseClass));
      else DEFAULT_PREFIXES;
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
    output Boolean isEncapsulated = Prefixes.isEncapsulated(getPrefixes(cls));
  end isEncapsulated;

  function isPartial
    input Class cls;
    output Boolean isPartial = Prefixes.isPartial(getPrefixes(cls));
  end isPartial;

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

  function constrainingClassPath
    "Returns the path of the constraining class for a given class, either the
     declared constraining class or the path of the class itself if there's no
     declared constraining class."
    input InstNode clsNode;
    output Absyn.Path path;
  protected
    InstNode cls_node = lastBaseClass(clsNode);
    Prefixes prefs = getPrefixes(InstNode.getClass(cls_node));
  algorithm
    path := match prefs
      case Prefixes.PREFIXES(replaceablePrefix = SCode.Replaceable.REPLACEABLE(
        cc = SOME(SCode.ConstrainClass.CONSTRAINCLASS(constrainingClass = path)))) then path;
      else InstNode.enclosingScopePath(cls_node);
    end match;
  end constrainingClassPath;

  function hasOperator
    input String name;
    input Class cls;
    output Boolean hasOperator;
  protected
    InstNode op_node;
    Class op_cls;
  algorithm
    if Restriction.isOperatorRecord(restriction(cls)) then
      try
        op_node := lookupElement(name, cls);
        hasOperator := SCodeUtil.isOperator(InstNode.definition(op_node));
      else
        hasOperator := false;
      end try;
    else
      hasOperator := false;
    end if;
  end hasOperator;

  function makeRecordExp
    input InstNode clsNode;
    output Expression exp;
  protected
    Class cls;
    Type ty;
    InstNode ty_node;
    array<InstNode> fields;
    list<Expression> args;
  algorithm
    cls := InstNode.getClass(clsNode);
    ty as Type.COMPLEX(complexTy = ComplexType.RECORD(ty_node)) := getType(cls, clsNode);
    fields := ClassTree.getComponents(classTree(cls));
    args := list(Binding.getExp(Component.getImplicitBinding(InstNode.component(f))) for f in fields);
    exp := Expression.makeRecord(InstNode.scopePath(ty_node, includeRoot = true), ty, args);
  end makeRecordExp;

  function toFlatStream
    input Class cls;
    input InstNode clsNode;
    input output IOStream.IOStream s;
  protected
    String name;
  algorithm
    name := Util.makeQuotedIdentifier(AbsynUtil.pathString(InstNode.scopePath(clsNode)));

    s := match cls
      case INSTANCED_CLASS()
        algorithm
          s := IOStream.append(s, Restriction.toString(cls.restriction));
          s := IOStream.append(s, " ");
          s := IOStream.append(s, name);
          s := IOStream.append(s, "\n");

          for comp in ClassTree.getComponents(cls.elements) loop
            s := IOStream.append(s, "  ");
            s := IOStream.append(s, InstNode.toFlatString(comp));
            s := IOStream.append(s, ";\n");
          end for;

          s := IOStream.append(s, "end ");
          s := IOStream.append(s, name);
        then
          s;

      case INSTANCED_BUILTIN()
        algorithm
          s := IOStream.append(s, "INSTANCED_BUILTIN(");
          s := IOStream.append(s, name);
          s := IOStream.append(s, ")");
        then
          s;

      case TYPED_DERIVED()
        algorithm
          s := IOStream.append(s, Restriction.toString(cls.restriction));
          s := IOStream.append(s, " ");
          s := IOStream.append(s, name);
          s := IOStream.append(s, " = ");
          s := IOStream.append(s, Util.makeQuotedIdentifier(AbsynUtil.pathString(InstNode.scopePath(cls.baseClass))));
        then
          s;

      else IOStream.append(s, "UNKNOWN_CLASS(" + name + ")");
    end match;
  end toFlatStream;

  function toFlatString
    input Class cls;
    input InstNode clsNode;
    output String str;
  protected
    IOStream.IOStream s;
  algorithm
    s := IOStream.create(getInstanceName(), IOStream.IOStreamType.LIST());
    s := toFlatStream(cls, clsNode, s);
    str := IOStream.string(s);
    IOStream.delete(s);
  end toFlatString;

annotation(__OpenModelica_Interface="frontend");
end NFClass;

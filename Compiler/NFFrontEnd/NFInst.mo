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

encapsulated package NFInst
" file:        NFInst.mo
  package:     NFInst
  description: Instantiation

  New instantiation, enable with -d=newInst.
"

import Absyn;
import SCode;
import DAE;

import Builtin = NFBuiltin;
import NFBinding.Binding;
import NFComponent.Component;
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import Expression = NFExpression;
import NFClass.Class;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFModifier.Modifier;
import NFModifier.ModifierScope;
import Operator = NFOperator;
import Equation = NFEquation;
import Statement = NFStatement;
import Type = NFType;
import Subscript = NFSubscript;
import Connector = NFConnector;
import Connection = NFConnection;
import Algorithm = NFAlgorithm;
import ExpOrigin = NFTyping.ExpOrigin;

protected
import Array;
import Error;
import Flatten = NFFlatten;
import Global;
import InstUtil = NFInstUtil;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import Typing = NFTyping;
import ExecStat.{execStat,execStatReset};
import SCodeDump;
import SCodeUtil;
import System;
import NFCall.Call;
import Absyn.Path;
import NFClassTree.ClassTree;
import NFSections.Sections;
import NFInstNode.CachedData;
import NFInstNode.NodeTree;
import StringUtil;
import UnitCheck = NFUnitCheck;
import NFPrefixes.*;
import Prefixes = NFPrefixes;
import NFFlatten.FunctionTree;
import ConvertDAE = NFConvertDAE;
import Scalarize = NFScalarize;
import Restriction = NFRestriction;
import ComplexType = NFComplexType;
import Package = NFPackage;
import NFFunction.Function;
import FlatModel = NFFlatModel;
import ElementSource;
import SimplifyModel = NFSimplifyModel;
import Record = NFRecord;
import Variable = NFVariable;
import OperatorOverloading = NFOperatorOverloading;
import EvalConstants = NFEvalConstants;

public
function instClassInProgram
  "Instantiates a class given by its fully qualified path, with the result being
   a DAE."
  input Absyn.Path classPath;
  input SCode.Program program;
  output DAE.DAElist dae;
  output DAE.FunctionTree daeFuncs;
protected
  InstNode top, cls, inst_cls;
  String name;
  FlatModel flat_model;
  FunctionTree funcs;
algorithm
  // gather here all the flags to disable expansion
  // and scalarization if -d=-nfScalarize is on
  if not Flags.isSet(Flags.NF_SCALARIZE) then
    // make sure we don't expand anything
    Flags.set(Flags.NF_EXPAND_OPERATIONS, false);
    Flags.set(Flags.NF_EXPAND_FUNC_ARGS, false);
  end if;

  System.setUsesCardinality(false);

  // Create a root node from the given top-level classes.
  top := makeTopNode(program);
  name := Absyn.pathString(classPath);

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, Absyn.dummyInfo, checkAccessViolations = false);
  cls := InstNode.setNodeType(InstNodeType.ROOT_CLASS(), cls);

  // Initialize the storage for automatically generated inner elements.
  top := InstNode.setInnerOuterCache(top, CachedData.TOP_SCOPE(NodeTree.new(), cls));

  // Instantiate the class.
  inst_cls := instantiate(cls);
  insertGeneratedInners(inst_cls, top);
  execStat("NFInst.instantiate("+ name +")");

  // Instantiate expressions (i.e. anything that can contains crefs, like
  // bindings, dimensions, etc). This is done as a separate step after
  // instantiation to make sure that lookup is able to find the correct nodes.
  instExpressions(inst_cls);
  execStat("NFInst.instExpressions("+ name +")");

  // Mark structural parameters.
  updateImplicitVariability(inst_cls, Flags.isSet(Flags.EVAL_PARAM));
  execStat("NFInst.updateImplicitVariability");

  // Type the class.
  Typing.typeClass(inst_cls, name);

  // Flatten and simplify the model.
  flat_model := Flatten.flatten(inst_cls, name);
  flat_model := EvalConstants.evaluate(flat_model);
  flat_model := SimplifyModel.simplify(flat_model);
  funcs := Flatten.collectFunctions(flat_model, name);

  // Collect package constants that couldn't be substituted with their values
  // (e.g. because they where used with non-constant subscripts), and add them
  // to the model.
  flat_model := Package.collectConstants(flat_model, funcs);

  // Scalarize array components in the flat model.
  if Flags.isSet(Flags.NF_SCALARIZE) then
    flat_model := Scalarize.scalarize(flat_model, name);
  else
    // Remove empty arrays from variables
    flat_model.variables := List.filterOnFalse(flat_model.variables, Variable.isEmptyArray);
  end if;

  // Convert the flat model to a DAE.
  (dae, daeFuncs) := ConvertDAE.convert(flat_model, funcs, name, InstNode.info(inst_cls));

  // Do unit checking
  UnitCheck.checkUnits(dae, daeFuncs);
end instClassInProgram;

function instantiate
  input output InstNode node;
  input InstNode parent = InstNode.EMPTY_NODE();
algorithm
  node := partialInstClass(node);
  node := expandClass(node);
  node := instClass(node, Modifier.NOMOD(), NFComponent.DEFAULT_ATTR, true, parent);
end instantiate;

function expand
  input output InstNode node;
algorithm
  node := partialInstClass(node);
  node := expandClass(node);
end expand;

function makeTopNode
  "Creates an instance node from the given list of top-level classes."
  input list<SCode.Element> topClasses;
  output InstNode topNode;
protected
  SCode.Element cls_elem;
  Class cls;
  ClassTree elems;
algorithm
  // Create a fake SCode.Element for the top scope, so we don't have to make the
  // definition in InstNode an Option only because of this node.
  cls_elem := SCode.CLASS("<top>", SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(),
    SCode.NOT_PARTIAL(), SCode.R_PACKAGE(),
    SCode.PARTS(topClasses, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.COMMENT(NONE(), NONE()), Absyn.dummyInfo);

  // Make an InstNode for the top scope, to use as the parent of the top level elements.
  topNode := InstNode.newClass(cls_elem, InstNode.EMPTY_NODE(), InstNodeType.TOP_SCOPE());

  // Create a new class from the elements, and update the inst node with it.
  cls := Class.fromSCode(topClasses, false, topNode, NFClass.DEFAULT_PREFIXES);
  // The class needs to be expanded to allow lookup in it. The top scope will
  // only contain classes, so we can do this instead of the whole expandClass.
  cls := Class.initExpandedClass(cls);

  // Set the correct InstNodeType for classes with builtin annotation. This
  // could also be done when creating InstNodes, but only top-level classes
  // should have this annotation anyway.
  elems := Class.classTree(cls);
  ClassTree.mapClasses(elems, markBuiltinTypeNodes);
  cls := Class.setClassTree(elems, cls);

  topNode := InstNode.updateClass(cls, topNode);
end makeTopNode;

function markBuiltinTypeNodes
  input output InstNode node;
algorithm
  if SCode.hasBooleanNamedAnnotationInClass(InstNode.definition(node), "__OpenModelica_builtin") then
    node := InstNode.setNodeType(InstNodeType.BUILTIN_CLASS(), node);
  end if;
end markBuiltinTypeNodes;

function partialInstClass
  input output InstNode node;
protected
  Class c;
algorithm
  () := match InstNode.getClass(node)
    case Class.NOT_INSTANTIATED()
      algorithm
        c := partialInstClass2(InstNode.definition(node), node);
        node := InstNode.updateClass(c, node);
      then
        ();

    else ();
  end match;
end partialInstClass;

function partialInstClass2
  input SCode.Element definition;
  input InstNode scope;
  output Class cls;
protected
  SCode.ClassDef cdef, ce_cdef;
  Type ty;
  Class.Prefixes prefs;
algorithm
  Error.assertion(SCode.elementIsClass(definition), getInstanceName() + " got non-class element", sourceInfo());
  SCode.CLASS(classDef = cdef) := definition;
  prefs := instClassPrefixes(definition);

  cls := match cdef
    // A long class definition, add its elements to a new scope.
    case SCode.PARTS()
      then Class.fromSCode(cdef.elementLst, false, scope, prefs);

    // A class extends, add its elements to a new scope.
    case SCode.CLASS_EXTENDS(composition = ce_cdef as SCode.PARTS())
      algorithm
        // Give a warning if the class extends is not declared as a redeclare.
        // This was not clarified until Modelica 3.4, so for now we just treat
        // all class extends like redeclares and give a warning about it.
        if not SCode.isElementRedeclare(definition) then
          Error.addSourceMessage(Error.CLASS_EXTENDS_MISSING_REDECLARE,
            {SCode.elementName(definition)}, SCode.elementInfo(definition));
        end if;
      then
        Class.fromSCode(ce_cdef.elementLst, true, scope, prefs);

    // An enumeration definition, add the literals to a new scope.
    case SCode.ENUMERATION()
      algorithm
        ty := makeEnumerationType(cdef.enumLst, scope);
      then
        Class.fromEnumeration(cdef.enumLst, ty, scope);

    else Class.PARTIAL_CLASS(NFClassTree.EMPTY, Modifier.NOMOD(), prefs);
  end match;
end partialInstClass2;

function instClassPrefixes
  input SCode.Element cls;
  output Class.Prefixes prefixes;
protected
  SCode.Prefixes prefs;
algorithm
  prefixes := match cls
    case SCode.CLASS(
        encapsulatedPrefix = SCode.Encapsulated.NOT_ENCAPSULATED(),
        partialPrefix = SCode.Partial.NOT_PARTIAL(),
        prefixes = SCode.Prefixes.PREFIXES(
          finalPrefix = SCode.Final.NOT_FINAL(),
          innerOuter = Absyn.InnerOuter.NOT_INNER_OUTER(),
          replaceablePrefix = SCode.NOT_REPLACEABLE()))
      then NFClass.DEFAULT_PREFIXES;

    case SCode.CLASS(prefixes = prefs)
      then Class.Prefixes.PREFIXES(
        cls.encapsulatedPrefix,
        cls.partialPrefix,
        prefs.finalPrefix,
        prefs.innerOuter,
        prefs.replaceablePrefix);

  end match;
end instClassPrefixes;

function makeEnumerationType
  input list<SCode.Enum> literals;
  input InstNode scope;
  output Type ty;
protected
  list<String> lits;
  Absyn.Path path;
algorithm
  path := InstNode.scopePath(scope);
  lits := list(e.literal for e in literals);
  ty := Type.ENUMERATION(path, lits);
end makeEnumerationType;

function expandClass
  input output InstNode node;
algorithm
  node := match InstNode.getClass(node)
    case Class.PARTIAL_CLASS() then expandClass2(node);
    else node;
  end match;
end expandClass;

function expandClass2
  input output InstNode node;
protected
  SCode.Element def = InstNode.definition(node);
  SCode.ClassDef cdef;
  SourceInfo info;
algorithm
  SCode.CLASS(classDef = cdef, info = info) := def;

  node := match cdef
    case SCode.PARTS() then expandClassParts(def, node, info);
    case SCode.CLASS_EXTENDS() then expandClassParts(def, node, info);
    // A short class definition, e.g. class A = B.
    case SCode.DERIVED() then expandClassDerived(def, cdef, node, info);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown class:\n" + SCodeDump.unparseElementStr(def), sourceInfo());
      then
        fail();

  end match;
end expandClass2;

function expandClassParts
  input SCode.Element def;
  input output InstNode node;
  input SourceInfo info;
protected
  Class cls;
  ClassTree cls_tree;
  Modifier mod;
  InstNode builtin_ext;
  Class.Prefixes prefs;
  Restriction res;
algorithm
  cls := InstNode.getClass(node);
  // Change the class to an empty expanded class, to avoid instantiation loops.
  cls := Class.initExpandedClass(cls);
  node := InstNode.updateClass(cls, node);

  Class.EXPANDED_CLASS(elements = cls_tree, modifier = mod, prefixes = prefs) := cls;
  builtin_ext := ClassTree.mapFoldExtends(cls_tree, expandExtends, InstNode.EMPTY_NODE());

  if InstNode.name(builtin_ext) == "ExternalObject" then
    node := expandExternalObject(cls_tree, node);
  else
    if not InstNode.isEmpty(builtin_ext) then
      checkBuiltinTypeExtends(builtin_ext, cls_tree, node);
    end if;

    cls_tree := ClassTree.expand(cls_tree);
    res := Restriction.fromSCode(SCode.getClassRestriction(def));
    cls := Class.EXPANDED_CLASS(cls_tree, mod, prefs, res);
    node := InstNode.updateClass(cls, node);
  end if;
end expandClassParts;

function expandExtends
  input output InstNode ext;
  input output InstNode builtinExt = InstNode.EMPTY_NODE();
protected
  SCode.Element def;
  Absyn.Path base_path;
  list<InstNode> base_nodes;
  InstNode scope, base_node;
  SCode.Visibility vis;
  SCode.Mod smod;
  Option<SCode.Annotation> ann;
  SourceInfo info;
algorithm
  if InstNode.isEmpty(ext) then
    return;
  end if;

  def := InstNode.definition(ext);

  () := match def
    case SCode.Element.EXTENDS(base_path, vis, smod, ann, info)
      algorithm
        // Look up the base class and expand it.
        scope := InstNode.parent(ext);
        base_nodes as (base_node :: _) := Lookup.lookupBaseClassName(base_path, scope, info);
        checkExtendsLoop(base_node, base_path, info);
        checkReplaceableBaseClass(base_nodes, base_path, info);
        base_node := expand(base_node);

        ext := InstNode.setNodeType(InstNodeType.BASE_CLASS(scope, def), base_node);

        // If the extended class is a builtin class, like Real or any type derived
        // from Real, then return it so we can handle it properly in expandClass.
        // We don't care if builtinExt is already SOME, since that's not legal and
        // will be caught by expandBuiltinExtends.
        if InstNode.isBuiltin(base_node) or Class.isBuiltin(InstNode.getClass(base_node)) then
          builtinExt := ext;
        end if;
      then
        ();

    else ();
  end match;
end expandExtends;

function checkExtendsLoop
  "Gives an error if a base node is in the process of being expanded itself,
   since that means we have an extends loop in the model."
  input InstNode node;
  input Absyn.Path path;
  input SourceInfo info;
algorithm
  () := match InstNode.getClass(node)
    // expand begins by changing the class to an EXPANDED_CLASS, but keeps the
    // class tree. So finding a PARTIAL_TREE here means the class is in the
    // process of being expanded.
    case Class.EXPANDED_CLASS(elements = ClassTree.PARTIAL_TREE())
      algorithm
        Error.addSourceMessage(Error.EXTENDS_LOOP,
          {Absyn.pathString(path)}, info);
      then
        fail();

    else ();
  end match;
end checkExtendsLoop;

function checkReplaceableBaseClass
  "Checks that all parts of a name used as a base class are transitively
   non-replaceable."
  input list<InstNode> baseClasses;
  input Absyn.Path basePath;
  input SourceInfo info;
protected
  Integer i = 0, pos;
  String name;
  list<InstNode> rest;
algorithm
  for base in baseClasses loop
    i := i + 1;

    if SCode.isElementReplaceable(InstNode.definition(base)) then
      // The path might contain several classes with the same name, so mark the
      // class in the path string to make it clear which one we mean.
      if listLength(baseClasses) > 1 then
        rest := baseClasses;
        name := "";

        for j in 1:i-1 loop
          name := "." + InstNode.name(listHead(rest)) + name;
          rest := listRest(rest);
        end for;

        name := "<" + InstNode.name(listHead(rest)) + ">" + name;
        rest := listRest(rest);

        for n in rest loop
          name := InstNode.name(n) + "." + name;
        end for;
      else
        name := Absyn.pathString(basePath);
      end if;

      Error.addMultiSourceMessage(Error.REPLACEABLE_BASE_CLASS,
        {InstNode.name(base), name}, {InstNode.info(base), info});
      fail();
    end if;
  end for;
end checkReplaceableBaseClass;

function expandExternalObject
  input ClassTree clsTree;
  input output InstNode node;
protected
  ComplexType eo_ty;
  Class c;
algorithm
  // Construct the ComplexType for the external object.
  eo_ty := makeExternalObjectType(clsTree, node);
  // Construct the Class for the external object. We use an empty class
  // tree here, since the constructor and destructor is embedded in the
  // ComplexType instead. Using an empty class tree makes sure it's not
  // possible to call the constructor or destructor explicitly.
  c := Class.PARTIAL_BUILTIN(Type.COMPLEX(node, eo_ty), NFClassTree.EMPTY_FLAT,
    Modifier.NOMOD(), Restriction.EXTERNAL_OBJECT());
  node := InstNode.updateClass(c, node);
end expandExternalObject;

function checkBuiltinTypeExtends
  input InstNode builtinExtends;
  input ClassTree tree;
  input InstNode node;
algorithm
  // A class extending from a builtin type may not have other components or baseclasses.
  if ClassTree.componentCount(tree) > 0 or ClassTree.extendsCount(tree) > 1 then
    // ***TODO***: Find the invalid element and use its info to make the error
    //             message more accurate.
    Error.addSourceMessage(Error.BUILTIN_EXTENDS_INVALID_ELEMENTS,
      {InstNode.name(builtinExtends)}, InstNode.info(node));
    fail();
  end if;
end checkBuiltinTypeExtends;

function makeExternalObjectType
  "Constructs a ComplexType for an external object, and also checks that the
   external object declaration is valid."
  input ClassTree tree;
  input InstNode node;
  output ComplexType ty;
protected
  Absyn.Path base_path;
  InstNode constructor = InstNode.EMPTY_NODE(), destructor = InstNode.EMPTY_NODE();
algorithm
  ty := match tree
    case ClassTree.PARTIAL_TREE()
      algorithm
        // An external object may not contain components.
        for comp in tree.components loop
          if InstNode.isComponent(comp) then
            Error.addSourceMessage(Error.EXTERNAL_OBJECT_INVALID_ELEMENT,
              {InstNode.name(node), InstNode.name(comp)}, InstNode.info(comp));
            fail();
          end if;
        end for;

        // An external object may not contain extends other than the ExternalObject one.
        if arrayLength(tree.exts) > 1 then
          for ext in tree.exts loop
            if InstNode.name(ext) <> "ExternalObject" then
              InstNode.CLASS_NODE(nodeType = InstNodeType.BASE_CLASS(definition =
                SCode.EXTENDS(baseClassPath = base_path))) := ext;
              Error.addSourceMessage(Error.EXTERNAL_OBJECT_INVALID_ELEMENT,
                {InstNode.name(node), "extends " + Absyn.pathString(base_path)}, InstNode.info(ext));
              fail();
            end if;
          end for;
        end if;

        // An external object must have exactly two functions called constructor and
        // destructor.
        for cls in tree.classes loop
          () := match InstNode.name(cls)
            case "constructor" guard SCode.isFunction(InstNode.definition(cls))
              algorithm
                constructor := cls;
              then
                ();

            case "destructor" guard SCode.isFunction(InstNode.definition(cls))
              algorithm
                destructor := cls;
              then
                ();

            else
              algorithm
                // Found some other element => error.
                Error.addSourceMessage(Error.EXTERNAL_OBJECT_INVALID_ELEMENT,
                  {InstNode.name(node), InstNode.name(cls)}, InstNode.info(cls));
              then
                fail();

          end match;
        end for;

        if InstNode.isEmpty(constructor) then
          // The constructor is missing.
          Error.addSourceMessage(Error.EXTERNAL_OBJECT_MISSING_STRUCTOR,
            {InstNode.name(node), "constructor"}, InstNode.info(node));
          fail();
        end if;

        if InstNode.isEmpty(destructor) then
          // The destructor is missing.
          Error.addSourceMessage(Error.EXTERNAL_OBJECT_MISSING_STRUCTOR,
            {InstNode.name(node), "destructor"}, InstNode.info(node));
          fail();
        end if;
      then
        ComplexType.EXTERNAL_OBJECT(constructor, destructor);

  end match;
end makeExternalObjectType;

function expandClassDerived
  input SCode.Element element;
  input SCode.ClassDef definition;
  input output InstNode node;
  input SourceInfo info;
protected
  Absyn.TypeSpec ty;
  InstNode ext_node;
  Class cls;
  Class.Prefixes prefs;
  SCode.Attributes sattrs;
  Component.Attributes attrs;
  list<Dimension> dims;
  Modifier mod;
  Restriction res;
algorithm
  SCode.DERIVED(typeSpec = ty, attributes = sattrs) := definition;

  // Look up the class that's being derived from and expand it.
  ext_node :: _ := Lookup.lookupBaseClassName(Absyn.typeSpecPath(ty), InstNode.parent(node), info);

  // Check that the class isn't extending itself, i.e. class A = A.
  if referenceEq(ext_node, node) then
    Error.addSourceMessage(Error.RECURSIVE_SHORT_CLASS_DEFINITION,
      {InstNode.name(node), Dump.unparseTypeSpec(ty)}, info);
    fail();
  end if;

  ext_node := expand(ext_node);
  ext_node := InstNode.clone(ext_node);

  // Fetch the needed information from the class definition and construct a EXPANDED_DERIVED.
  cls := InstNode.getClass(node);
  prefs := Class.getPrefixes(cls);
  attrs := instDerivedAttributes(sattrs);
  dims := list(Dimension.RAW_DIM(d) for d in Absyn.typeSpecDimensions(ty));
  mod := Class.getModifier(cls);

  res := Restriction.fromSCode(SCode.getClassRestriction(element));
  cls := Class.EXPANDED_DERIVED(ext_node, mod, listArray(dims), prefs, attrs, res);
  node := InstNode.updateClass(cls, node);
  node := InstNode.setNodeType(InstNodeType.DERIVED_CLASS(InstNode.nodeType(node)), node);
end expandClassDerived;

function instDerivedAttributes
  input SCode.Attributes scodeAttr;
  output Component.Attributes attributes;
protected
  ConnectorType cty;
  Variability var;
  Direction dir;
algorithm
  attributes := match scodeAttr
    case SCode.Attributes.ATTR(
           connectorType = SCode.ConnectorType.POTENTIAL(),
           variability = SCode.Variability.VAR(),
           direction = Absyn.Direction.BIDIR())
      then NFComponent.DEFAULT_ATTR;

    else
      algorithm
        cty := Prefixes.connectorTypeFromSCode(scodeAttr.connectorType);
        var := Prefixes.variabilityFromSCode(scodeAttr.variability);
        dir := Prefixes.directionFromSCode(scodeAttr.direction);
      then
        Component.Attributes.ATTRIBUTES(cty, Parallelism.NON_PARALLEL,
          var, dir, InnerOuter.NOT_INNER_OUTER, false, false, Replaceable.NOT_REPLACEABLE());

  end match;
end instDerivedAttributes;

function instClass
  input output InstNode node;
  input Modifier modifier;
  input output Component.Attributes attributes = NFComponent.DEFAULT_ATTR;
  input Boolean useBinding;
  input InstNode parent = InstNode.EMPTY_NODE();
protected
  Class cls;
  Modifier outer_mod;
algorithm
  cls := InstNode.getClass(node);
  outer_mod := Class.getModifier(cls);

  // Give an error for modifiers such as (A = B), i.e. attempting to replace a
  // class without using redeclare.
  if Modifier.hasBinding(outer_mod) then
    Error.addSourceMessage(Error.MISSING_REDECLARE_IN_CLASS_MOD,
      {InstNode.name(node)}, Binding.getInfo(Modifier.binding(outer_mod)));
    fail();
  end if;

  (attributes, node) := instClassDef(cls, modifier, attributes, useBinding, node, parent);
end instClass;

function instClassDef
  input Class cls;
  input Modifier outerMod;
  input output Component.Attributes attributes;
  input Boolean useBinding;
  input output InstNode node;
  input InstNode parent;
protected
  InstNode par, base_node;
  Class inst_cls;
  ClassTree cls_tree;
  Modifier mod, outer_mod;
  Restriction res;
  Type ty;
algorithm
  () := match cls
    case Class.EXPANDED_CLASS()
      algorithm
        (node, par) := ClassTree.instantiate(node, parent);
        updateComponentType(parent, node);
        inst_cls as Class.EXPANDED_CLASS(elements = cls_tree) := InstNode.getClass(node);

        // Fetch modification on the class definition (for class extends).
        mod := Modifier.fromElement(InstNode.definition(node), {}, par);
        // Merge with any outer modifications.
        outer_mod := Modifier.merge(outerMod, cls.modifier);
        mod := Modifier.merge(outer_mod, mod);

        // Apply the modifiers of extends nodes.
        ClassTree.mapExtends(cls_tree, function modifyExtends(scope = par));

        // Apply the modifiers of this scope.
        applyModifier(mod, cls_tree, InstNode.name(node));

        // Apply element redeclares.
        ClassTree.mapRedeclareChains(cls_tree, redeclareElements);
        // Redeclare classes with redeclare modifiers. Redeclared components could
        // also be handled here, but since each component is only instantiated once
        // it's more efficient to apply the redeclare when instantiating them instead.
        redeclareClasses(cls_tree);

        // Instantiate the extends nodes.
        ClassTree.mapExtends(cls_tree,
          function instExtends(attributes = attributes, useBinding = useBinding,
                               visibility = ExtendsVisibility.PUBLIC));

        // Instantiate local components.
        ClassTree.applyLocalComponents(cls_tree,
          function instComponent(attributes = attributes, innerMod = Modifier.NOMOD(),
                                 useBinding = useBinding));

        // Remove duplicate elements.
        cls_tree := ClassTree.replaceDuplicates(cls_tree);
        ClassTree.checkDuplicates(cls_tree);
        InstNode.updateClass(Class.setClassTree(cls_tree, inst_cls), node);
      then
        ();

    case Class.EXPANDED_DERIVED()
      algorithm
        node := InstNode.replaceClass(cls, node);

        // Merge outer modifiers and attributes.
        mod := Modifier.fromElement(InstNode.definition(node), {node}, InstNode.parent(node));
        outer_mod := Modifier.merge(outerMod, Modifier.addParent(node, cls.modifier));
        mod := Modifier.merge(outer_mod, mod);
        attributes := mergeDerivedAttributes(attributes, cls.attributes, parent);

        // Mark the base class node as a base class.
        base_node := InstNode.setNodeType(
          InstNodeType.BASE_CLASS(node, InstNode.definition(cls.baseClass)), cls.baseClass);

        // Instantiate the base class and update the nodes.
        (base_node, attributes) := instClass(base_node, mod, attributes, useBinding, parent);
        cls.baseClass := base_node;
        cls.attributes := attributes;
        cls.dims := arrayCopy(cls.dims);

        // Update the parent's type with the new class instance.
        node := InstNode.updateClass(cls, node);
        updateComponentType(parent, node);
      then
        ();

    case Class.PARTIAL_BUILTIN(restriction = Restriction.EXTERNAL_OBJECT())
      algorithm
        inst_cls := Class.INSTANCED_BUILTIN(cls.ty, cls.elements, cls.restriction);
        node := InstNode.replaceClass(inst_cls, node);
        updateComponentType(parent, node);
        instExternalObjectStructors(cls.ty, parent);
      then
        ();

    case Class.PARTIAL_BUILTIN(ty = ty, restriction = res)
      algorithm
        (node, par) := ClassTree.instantiate(node, parent);
        updateComponentType(parent, node);
        cls_tree := Class.classTree(InstNode.getClass(node));

        mod := Modifier.fromElement(InstNode.definition(node), {node}, InstNode.parent(node));
        outer_mod := Modifier.merge(outerMod, Modifier.addParent(node, cls.modifier));
        mod := Modifier.merge(outer_mod, mod);
        applyModifier(mod, cls_tree, InstNode.name(node));

        inst_cls := Class.INSTANCED_BUILTIN(ty, cls_tree, res);
        node := InstNode.updateClass(inst_cls, node);
      then
        ();

    // If a class has an instance of a encapsulating class, then the encapsulating
    // class will have been fully instantiated to allow lookup in it. This is a
    // rather uncommon case hopefully, so in that case just reinstantiate the class.
    case Class.INSTANCED_CLASS()
      algorithm
        node := InstNode.replaceClass(Class.NOT_INSTANTIATED(), node);
        node := expand(node);
        node := instClass(node, outerMod, attributes, useBinding, parent);
        updateComponentType(parent, node);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown class.", sourceInfo());
      then
        ();

  end match;
end instClassDef;

function updateComponentType
  "Sets the class instance of a component node."
  input output InstNode component;
  input InstNode cls;
algorithm
  if InstNode.isComponent(component) then
    component := InstNode.componentApply(component, Component.setClassInstance, cls);
  end if;
end updateComponentType;

function instExternalObjectStructors
  "Instantiates the constructor and destructor for an ExternalObject class."
  input Type ty;
  input InstNode parent;
protected
  InstNode constructor, destructor, par;
algorithm
  // The constructor and destructor have function parameters that are instances
  // of the external object class, and we instantiate the structors when we
  // instantiate such instances. To break that loop we check that we're not
  // inside the external object class before instantiating the structors.
  par := InstNode.parent(InstNode.parent(parent));

  if not (InstNode.isClass(par) and Class.isExternalObject(InstNode.getClass(par))) then
    Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT(constructor, destructor)) := ty;
    Function.instFunctionNode(constructor);
    Function.instFunctionNode(destructor);
  end if;
end instExternalObjectStructors;

function instPackage
  "This function instantiates a package given a package node. If the package has
   already been instantiated, then the cached instance from the node is
   returned. Otherwise the node is fully instantiated, the instance is added to
   the node's cache, and the instantiated node is returned."
  input output InstNode node;
protected
  CachedData cache;
  InstNode inst;
algorithm
  cache := InstNode.getPackageCache(node);

  node := match cache
    case CachedData.PACKAGE() then cache.instance;

    case CachedData.NO_CACHE()
      algorithm
        // Cache the package node itself first, to avoid instantiation loops if
        // the package uses itself somehow.
        InstNode.setPackageCache(node, CachedData.PACKAGE(node));
        // Instantiate the node.
        inst := instantiate(node);
        // Cache the instantiated node and instantiate expressions in it too.
        InstNode.setPackageCache(node, CachedData.PACKAGE(inst));
        instExpressions(inst);
      then
        inst;

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got invalid instance cache", sourceInfo());
      then
        fail();

  end match;
end instPackage;

function modifyExtends
  input output InstNode extendsNode;
  input InstNode scope;
protected
  SCode.Element elem;
  Modifier ext_mod;
  InstNode ext_node;
  SourceInfo info;
  Class cls;
  ClassTree cls_tree;
algorithm
  cls := InstNode.getClass(extendsNode);
  cls_tree := Class.classTree(cls);

  // Create a modifier from the extends.
  InstNodeType.BASE_CLASS(definition = elem) := InstNode.nodeType(extendsNode);
  ext_mod := Modifier.fromElement(elem, {}, scope);
  ext_mod := Modifier.merge(InstNode.getModifier(extendsNode), ext_mod);

  if not Class.isBuiltin(cls) then
    ClassTree.mapExtends(cls_tree, function modifyExtends(scope = extendsNode));

    () := match elem
      case SCode.EXTENDS()
        algorithm
          // TODO: Lookup the base class and merge its modifier.
          ext_node :: _ := Lookup.lookupBaseClassName(elem.baseClassPath, scope, elem.info);

          // Finding a different element than before expanding extends
          // (probably an inherited element) is an error.
          if not referenceEq(InstNode.definition(extendsNode), InstNode.definition(ext_node)) then
            Error.addMultiSourceMessage(Error.FOUND_OTHER_BASECLASS,
              {Absyn.pathString(elem.baseClassPath)},
              {InstNode.info(extendsNode), InstNode.info(ext_node)});
            fail();
          end if;
        then
          ();

      // Class extends?
      case SCode.CLASS()
        then ();
    end match;
  end if;

  applyModifier(ext_mod, cls_tree, InstNode.name(extendsNode));
end modifyExtends;

type ExtendsVisibility = enumeration(PUBLIC, DERIVED_PROTECTED, PROTECTED);

function instExtends
  input output InstNode node;
  input Component.Attributes attributes;
  input Boolean useBinding;
  input ExtendsVisibility visibility;
protected
  Class cls, inst_cls;
  ClassTree cls_tree;
  ExtendsVisibility vis = visibility;
algorithm
  cls := InstNode.getClass(node);

  () := match cls
    case Class.EXPANDED_CLASS(elements = cls_tree as ClassTree.INSTANTIATED_TREE())
      algorithm
        if vis == ExtendsVisibility.PUBLIC and InstNode.isProtectedBaseClass(node) or
           vis == ExtendsVisibility.DERIVED_PROTECTED then
          vis := ExtendsVisibility.PROTECTED;
        end if;

        // Protect components and classes if the extends is protected, except
        // if they've already been protected by an extends higher up.
        if vis == ExtendsVisibility.PROTECTED and visibility <> ExtendsVisibility.PROTECTED then
          for c in cls_tree.classes loop
            Mutable.update(c, InstNode.protectClass(Mutable.access(c)));
          end for;

          for c in cls_tree.components loop
            Mutable.update(c, InstNode.protectComponent(Mutable.access(c)));
          end for;
        end if;

        ClassTree.mapExtends(cls_tree,
          function instExtends(attributes = attributes, useBinding = useBinding, visibility = vis));

        ClassTree.applyLocalComponents(cls_tree,
          function instComponent(attributes = attributes, innerMod = Modifier.NOMOD(), useBinding = useBinding));
      then
        ();

    case Class.EXPANDED_DERIVED()
      algorithm
        if vis == ExtendsVisibility.PUBLIC and InstNode.isProtectedBaseClass(node) then
          vis := ExtendsVisibility.DERIVED_PROTECTED;
        end if;

        cls.baseClass := instExtends(cls.baseClass, attributes, useBinding, vis);
        node := InstNode.updateClass(cls, node);
      then
        ();

    case Class.PARTIAL_BUILTIN()
      algorithm
        inst_cls := Class.INSTANCED_BUILTIN(cls.ty, cls.elements, cls.restriction);
        node := InstNode.updateClass(inst_cls, node);
      then
        ();

    else ();
  end match;
end instExtends;

function applyModifier
  "Applies a modifier in the given scope, by splitting the modifier and merging
   each part with the relevant element in the scope."
  input Modifier modifier;
  input output ClassTree cls;
  input String clsName;
protected
  list<Modifier> mods;
  list<Mutable<InstNode>> node_ptrs;
  InstNode node;
  Component comp;
algorithm
  // Split the modifier into a list of submodifiers.
  mods := Modifier.toList(modifier);

  if listEmpty(mods) then
    return;
  end if;

  () := match cls
    case ClassTree.FLAT_TREE()
      algorithm
        for mod in mods loop
          try
            node := ClassTree.lookupElement(Modifier.name(mod), cls);
          else
            Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
              {Modifier.name(mod), clsName}, Modifier.info(mod));
            fail();
          end try;

          InstNode.componentApply(node, Component.mergeModifier, mod);
        end for;
      then
        ();

    else
      algorithm
        for mod in mods loop
          // Look up the node(s) to modify. Might be several in case of duplicate inherited elements.
          try
            node_ptrs := ClassTree.lookupElementsPtr(Modifier.name(mod), cls);
          else
            Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
              {Modifier.name(mod), clsName}, Modifier.info(mod));
            fail();
          end try;

          // Apply the modifier to each found node.
          for node_ptr in node_ptrs loop
            node := InstNode.resolveOuter(Mutable.access(node_ptr));

            if InstNode.isComponent(node) then
              InstNode.componentApply(node, Component.mergeModifier, mod);
            else
              if InstNode.isOnlyOuter(node) then
                // Modifying an outer class is illegal. We can't check that in instClass
                // since we get the inner class there, so we check it here instead.
                Error.addSourceMessage(Error.OUTER_ELEMENT_MOD,
                  {Modifier.toString(mod, printName = false), Modifier.name(mod)},
                  Modifier.info(mod));
                fail();
              end if;

              partialInstClass(node);
              node := InstNode.replaceClass(Class.mergeModifier(mod, InstNode.getClass(node)), node);
              node := InstNode.clearPackageCache(node);
              Mutable.update(node_ptr, node);
            end if;
          end for;
        end for;
      then
        ();

  end match;
end applyModifier;

function redeclareClasses
  input output ClassTree tree;
protected
  InstNode cls_node, redecl_node;
  Class cls;
  Modifier mod;
algorithm
  () := match tree
    case ClassTree.INSTANTIATED_TREE()
      algorithm
        for cls_ptr in tree.classes loop
          cls_node := Mutable.access(cls_ptr);
          cls := InstNode.getClass(InstNode.resolveOuter(cls_node));
          mod := Class.getModifier(cls);

          if Modifier.isRedeclare(mod) then
            Modifier.REDECLARE(element = redecl_node, mod = mod) := mod;
            cls_node := redeclareClass(redecl_node, cls_node, mod);
            Mutable.update(cls_ptr, cls_node);
          end if;
        end for;
      then
        ();

    else ();
  end match;
end redeclareClasses;

function redeclareElements
  input list<Mutable<InstNode>> chain;
protected
  InstNode node;
  Mutable<InstNode> node_ptr;
algorithm
  node := Mutable.access(listHead(chain));

  if InstNode.isClass(node) then
    node_ptr := redeclareClassElement(cls_ptr for cls_ptr in chain);
    node := Mutable.access(node_ptr);
  else
    node_ptr := redeclareComponentElement(comp_ptr for comp_ptr in chain);
    node := Mutable.access(node_ptr);
  end if;

  for cls_ptr in chain loop
    Mutable.update(cls_ptr, node);
  end for;
end redeclareElements;

function redeclareClassElement
  input Mutable<InstNode> redeclareCls;
  input Mutable<InstNode> replaceableCls;
  output Mutable<InstNode> outCls;
protected
  InstNode rdcl_node, repl_node;
algorithm
  rdcl_node := Mutable.access(redeclareCls);
  repl_node := Mutable.access(replaceableCls);
  rdcl_node := redeclareClass(rdcl_node, repl_node, Modifier.NOMOD());
  outCls := Mutable.create(rdcl_node);
end redeclareClassElement;

function redeclareComponentElement
  input Mutable<InstNode> redeclareComp;
  input Mutable<InstNode> replaceableComp;
  output Mutable<InstNode> outComp;
protected
  InstNode rdcl_node, repl_node;
algorithm
  rdcl_node := Mutable.access(redeclareComp);
  repl_node := Mutable.access(replaceableComp);
  instComponent(repl_node, NFComponent.DEFAULT_ATTR, Modifier.NOMOD(), true);
  redeclareComponent(rdcl_node, repl_node, Modifier.NOMOD(), Modifier.NOMOD(), NFComponent.DEFAULT_ATTR, rdcl_node);
  outComp := Mutable.create(rdcl_node);
end redeclareComponentElement;

function redeclareClass
  input InstNode redeclareNode;
  input InstNode originalNode;
  input Modifier outerMod;
  output InstNode redeclaredNode;
protected
  InstNode orig_node;
  Class orig_cls, rdcl_cls, new_cls;
  Class.Prefixes prefs;
  InstNodeType node_ty;
algorithm
  // Check that the redeclare element is actually a class.
  if not InstNode.isClass(redeclareNode) then
    Error.addMultiSourceMessage(Error.INVALID_REDECLARE_AS,
      {InstNode.typeName(originalNode), InstNode.name(originalNode), InstNode.typeName(redeclareNode)},
      {InstNode.info(redeclareNode), InstNode.info(originalNode)});
    fail();
  end if;

  partialInstClass(originalNode);
  orig_cls := InstNode.getClass(originalNode);
  partialInstClass(redeclareNode);
  rdcl_cls := InstNode.getClass(redeclareNode);

  prefs := mergeRedeclaredClassPrefixes(Class.getPrefixes(orig_cls),
    Class.getPrefixes(rdcl_cls), redeclareNode);

  if SCode.isClassExtends(InstNode.definition(redeclareNode)) then
    orig_node := expand(originalNode);
    orig_cls := InstNode.getClass(orig_node);

    new_cls := match (orig_cls, rdcl_cls)
      // Class extends of a builtin type. Not very useful, but technically allowed
      // if the redeclaring class is empty.
      case (_, Class.PARTIAL_CLASS()) guard Class.isBuiltin(orig_cls)
        algorithm
          if not SCode.isEmptyClassDef(SCode.getClassDef(InstNode.definition(redeclareNode))) then
            // Class extends of a builtin type is only allowed if the extending class is empty,
            // otherwise it violates the rules of extending a builtin type.
            Error.addSourceMessage(Error.BUILTIN_EXTENDS_INVALID_ELEMENTS,
            {InstNode.name(redeclareNode)}, InstNode.info(redeclareNode));
            fail();
          end if;
        then
          Class.setPrefixes(prefs, orig_cls);

      // Class extends of a long class declaration.
      case (Class.EXPANDED_CLASS(), Class.PARTIAL_CLASS())
        algorithm
          node_ty := InstNodeType.BASE_CLASS(InstNode.parent(orig_node), InstNode.definition(orig_node));
          orig_node := InstNode.setNodeType(node_ty, orig_node);
          rdcl_cls.elements := ClassTree.setClassExtends(orig_node, rdcl_cls.elements);
          rdcl_cls.modifier := Modifier.merge(outerMod, rdcl_cls.modifier);
          rdcl_cls.prefixes := prefs;
        then
          rdcl_cls;

      // Class extends of a short class declaration.
      case (Class.EXPANDED_DERIVED(), Class.PARTIAL_CLASS())
        algorithm
          rdcl_cls.prefixes := prefs;
        then
          rdcl_cls;

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown classes", sourceInfo());
        then
          fail();
    end match;
  else
    new_cls := match rdcl_cls
      case Class.PARTIAL_CLASS()
        algorithm
          rdcl_cls.prefixes := prefs;
          rdcl_cls.modifier := Modifier.merge(outerMod, rdcl_cls.modifier);
        then
          rdcl_cls;

      else
        algorithm
          Error.assertion(false, getInstanceName() + " got unknown classes", sourceInfo());
        then
          fail();
    end match;
  end if;

  redeclaredNode := InstNode.replaceClass(new_cls, redeclareNode);
end redeclareClass;

function instComponent
  input InstNode node   "The component node to instantiate";
  input Component.Attributes attributes "Attributes to be propagated to the component.";
  input Modifier innerMod;
  input Boolean useBinding "Ignore the component's binding if false.";
protected
  Component comp;
  SCode.Element def;
  InstNode comp_node, rdcl_node;
  Modifier outer_mod, cc_mod = innerMod;
  SCode.Mod cc_smod;
  String name;
  InstNode parent;
algorithm
  comp_node := InstNode.resolveOuter(node);
  comp := InstNode.component(comp_node);
  parent := InstNode.parent(comp_node);

  // Skip already instantiated components.
  if not Component.isDefinition(comp) then
    return;
  end if;

  Component.COMPONENT_DEF(definition = def, modifier = outer_mod) := comp;

  if Modifier.isRedeclare(outer_mod) then
    checkOuterComponentMod(outer_mod, def, comp_node);
    instComponentDef(def, Modifier.NOMOD(), cc_mod, NFComponent.DEFAULT_ATTR, useBinding, comp_node, parent);

    Modifier.REDECLARE(element = rdcl_node, mod = outer_mod) := outer_mod;
    cc_smod := SCode.getConstrainingMod(def);
    if not SCode.isEmptyMod(cc_smod) then
      name := InstNode.name(node);
      cc_mod := Modifier.create(cc_smod, name, ModifierScope.COMPONENT(name), {}, parent);
    end if;

    outer_mod := Modifier.merge(InstNode.getModifier(rdcl_node), outer_mod);
    //outer_mod := Modifier.merge(outer_mod, cc_mod);
    InstNode.setModifier(outer_mod, rdcl_node);
    redeclareComponent(rdcl_node, node, Modifier.NOMOD(), cc_mod, attributes, node);
  else
    instComponentDef(def, outer_mod, cc_mod, attributes, useBinding, comp_node, parent);
  end if;
end instComponent;

function instComponentDef
  input SCode.Element component;
  input Modifier outerMod;
  input Modifier innerMod;
  input Component.Attributes attributes;
  input Boolean useBinding;
  input InstNode node;
  input InstNode parent;
algorithm
  () := match component
    local
      SourceInfo info;
      Modifier decl_mod, mod;
      list<Dimension> dims, ty_dims;
      Binding binding, condition;
      Component.Attributes attr, ty_attr;
      Component inst_comp;
      InstNode ty_node;
      Class ty;
      Boolean use_binding, in_function;

    case SCode.COMPONENT(info = info)
      algorithm
        decl_mod := Modifier.fromElement(component, {}, parent);
        mod := Modifier.merge(decl_mod, innerMod);
        mod := Modifier.merge(outerMod, mod);
        mod := Modifier.addParent(node, mod);
        checkOuterComponentMod(mod, component, node);

        dims := list(Dimension.RAW_DIM(d) for d in component.attributes.arrayDims);
        binding := if useBinding then Modifier.binding(mod) else NFBinding.EMPTY_BINDING;
        condition := Binding.fromAbsyn(component.condition, false, {node}, parent, info);

        // This is used to ignore the bindings of a component's children when the
        // component iself has a binding that overrides those. This is to ensure
        // that constant evaluation of e.g. a record field uses the correct binding.
        use_binding := useBinding and not Binding.isBound(binding);

        // Instantiate the component's attributes, and merge them with the
        // attributes of the component's parent (e.g. constant SomeComplexClass c).
        attr := instComponentAttributes(component.attributes, component.prefixes);
        attr := mergeComponentAttributes(attributes, attr, node,
          Class.isFunction(InstNode.getClass(parent)));

        // Create the untyped component and update the node with it. We need the
        // untyped component in instClass to make sure everything is scoped
        // correctly during lookup, but the class node the component should have
        // is created by instClass. To break the circle we leave the class node
        // empty here, and let instClass set it for us instead.
        inst_comp := Component.UNTYPED_COMPONENT(InstNode.EMPTY_NODE(), listArray(dims),
          binding, condition, attr, SOME(component.comment), false, info);
        InstNode.updateComponent(inst_comp, node);

        // Instantiate the type of the component.
        (ty_node, ty_attr) := instTypeSpec(component.typeSpec, mod, attr,
          useBinding and not Binding.isBound(binding), parent, node, info);
        ty := InstNode.getClass(ty_node);

        // Update the component's variability based on its type (e.g. Integer is discrete).
        ty_attr := updateComponentVariability(ty_attr, ty, ty_node);
        if not referenceEq(attr, ty_attr) then
          InstNode.componentApply(node, Component.setAttributes, ty_attr);
        end if;
      then
        ();
  end match;
end instComponentDef;

function redeclareComponent
  input InstNode redeclareNode;
  input InstNode originalNode;
  input Modifier outerMod;
  input Modifier constrainingMod;
  input Component.Attributes outerAttr;
  input InstNode redeclaredNode;
protected
  Component orig_comp, rdcl_comp, new_comp;
  Binding binding, condition;
  Component.Attributes attr;
  array<Dimension> dims;
  Option<SCode.Comment> cmt;
  InstNode rdcl_node;
  InstNodeType rdcl_type;
algorithm
  // Check that the redeclare element actually is a component.
  if not InstNode.isComponent(redeclareNode) then
    Error.addMultiSourceMessage(Error.INVALID_REDECLARE_AS,
      {InstNode.typeName(originalNode), InstNode.name(originalNode), InstNode.typeName(redeclareNode)},
      {InstNode.info(redeclareNode), InstNode.info(originalNode)});
    fail();
  end if;

  rdcl_type := InstNodeType.REDECLARED_COMP(InstNode.parent(originalNode));
  rdcl_node := InstNode.setNodeType(rdcl_type, redeclareNode);
  instComponent(rdcl_node, outerAttr, constrainingMod, true);
  orig_comp := InstNode.component(originalNode);
  rdcl_comp := InstNode.component(rdcl_node);

  new_comp := match (orig_comp, rdcl_comp)
    case (Component.UNTYPED_COMPONENT(), Component.UNTYPED_COMPONENT())
      algorithm
        // Take the binding from the outer modifier, the redeclare, or the
        // original component, in that order of priority.
        binding := Modifier.binding(outerMod);
        if Binding.isUnbound(binding) then
          binding := if Binding.isBound(rdcl_comp.binding) then rdcl_comp.binding else orig_comp.binding;
        end if;

        // A redeclare is not allowed to have a condition expression.
        if Binding.isBound(rdcl_comp.condition) then
          Error.addSourceMessage(Error.REDECLARE_CONDITION,
            {InstNode.name(redeclareNode)}, InstNode.info(redeclareNode));
          fail();
        end if;

        condition := orig_comp.condition;

        // Merge the attributes of the redeclare and the original element, and
        // then with any outer attributes applied to the scope.
        attr := mergeRedeclaredComponentAttributes(orig_comp.attributes, rdcl_comp.attributes, redeclareNode);
        //attr := mergeComponentAttributes(outerAttr, attr, redeclareNode);

        // Use the dimensions of the redeclare if any, otherwise take them from the original.
        dims := if arrayEmpty(rdcl_comp.dimensions) then orig_comp.dimensions else rdcl_comp.dimensions;

        // TODO: Use comment of redeclare if available?
        cmt := orig_comp.comment;
      then
        Component.UNTYPED_COMPONENT(rdcl_comp.classInst, dims, binding, condition, attr, cmt, false, rdcl_comp.info);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown components", sourceInfo());
      then
        fail();

  end match;

  InstNode.updateComponent(new_comp, redeclaredNode);
end redeclareComponent;

function checkOuterComponentMod
  "Prints an error message and fails if it gets an outer component and a
   non-empty modifier."
  input Modifier mod;
  input SCode.Element component;
  input InstNode node;
algorithm
  if not Modifier.isEmpty(mod) and
     Absyn.isOnlyOuter(SCode.prefixesInnerOuter(SCode.elementPrefixes(component))) then
    Error.addSourceMessage(Error.OUTER_ELEMENT_MOD,
      {Modifier.toString(mod, printName = false), InstNode.name(node)}, InstNode.info(node));
    fail();
  end if;
end checkOuterComponentMod;

function instComponentAttributes
  input SCode.Attributes compAttr;
  input SCode.Prefixes compPrefs;
  output Component.Attributes attributes;
protected
  ConnectorType cty;
  Parallelism par;
  Variability var;
  Direction dir;
  InnerOuter io;
  Boolean fin, redecl;
  Replaceable repl;
algorithm
  attributes := match (compAttr, compPrefs)
    case (SCode.Attributes.ATTR(
            connectorType = SCode.ConnectorType.POTENTIAL(),
            parallelism = SCode.Parallelism.NON_PARALLEL(),
            variability = SCode.Variability.VAR(),
            direction = Absyn.Direction.BIDIR()),
          SCode.Prefixes.PREFIXES(
            redeclarePrefix = SCode.Redeclare.NOT_REDECLARE(),
            finalPrefix = SCode.Final.NOT_FINAL(),
            innerOuter = Absyn.InnerOuter.NOT_INNER_OUTER(),
            replaceablePrefix = SCode.Replaceable.NOT_REPLACEABLE()))
      then NFComponent.DEFAULT_ATTR;

    else
      algorithm
        cty := Prefixes.connectorTypeFromSCode(compAttr.connectorType);
        par := Prefixes.parallelismFromSCode(compAttr.parallelism);
        var := Prefixes.variabilityFromSCode(compAttr.variability);
        dir := Prefixes.directionFromSCode(compAttr.direction);
        io  := Prefixes.innerOuterFromSCode(compPrefs.innerOuter);
        fin := SCode.finalBool(compPrefs.finalPrefix);
        redecl := SCode.redeclareBool(compPrefs.redeclarePrefix);
        repl := Replaceable.NOT_REPLACEABLE();
      then
        Component.Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl);
  end match;
end instComponentAttributes;

function mergeComponentAttributes
  input Component.Attributes outerAttr;
  input Component.Attributes innerAttr;
  input InstNode node;
  input Boolean inFunction;
  output Component.Attributes attr;
protected
  ConnectorType cty;
  Parallelism par;
  Variability var;
  Direction dir;
  Boolean fin, redecl;
  Replaceable repl;
algorithm
  if referenceEq(outerAttr, NFComponent.DEFAULT_ATTR) then
    attr := innerAttr;
  elseif referenceEq(innerAttr, NFComponent.DEFAULT_ATTR) then
    attr := outerAttr;
    attr.innerOuter := InnerOuter.NOT_INNER_OUTER;
  else
    cty := Prefixes.mergeConnectorType(outerAttr.connectorType, innerAttr.connectorType, node);
    par := Prefixes.mergeParallelism(outerAttr.parallelism, innerAttr.parallelism, node);
    var := Prefixes.variabilityMin(outerAttr.variability, innerAttr.variability);

    if inFunction then
      dir := innerAttr.direction;
    else
      dir := Prefixes.mergeDirection(outerAttr.direction, innerAttr.direction, node);
    end if;

    fin := outerAttr.isFinal or innerAttr.isFinal;
    redecl := innerAttr.isRedeclare;
    repl := innerAttr.isReplaceable;
    attr := Component.Attributes.ATTRIBUTES(cty, par, var, dir, innerAttr.innerOuter, fin, redecl, repl);
  end if;
end mergeComponentAttributes;

function mergeDerivedAttributes
  input Component.Attributes outerAttr;
  input Component.Attributes innerAttr;
  input InstNode node;
  output Component.Attributes attr;
protected
  ConnectorType cty;
  Parallelism par;
  Variability var;
  Direction dir;
  InnerOuter io;
  Boolean fin, redecl;
  Replaceable repl;
algorithm
  if referenceEq(innerAttr, NFComponent.DEFAULT_ATTR) then
    attr := outerAttr;
  elseif referenceEq(outerAttr, NFComponent.DEFAULT_ATTR) then
    attr := innerAttr;
  else
    Component.Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl) := outerAttr;
    cty := Prefixes.mergeConnectorType(cty, innerAttr.connectorType, node);
    var := Prefixes.variabilityMin(var, innerAttr.variability);
    dir := Prefixes.mergeDirection(dir, innerAttr.direction, node, allowSame = true);
    attr := Component.Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl);
  end if;
end mergeDerivedAttributes;

function mergeRedeclaredComponentAttributes
  input Component.Attributes origAttr;
  input Component.Attributes redeclAttr;
  input InstNode node;
  output Component.Attributes attr;
protected
  ConnectorType cty, rcty;
  Parallelism par, rpar;
  Variability var, rvar;
  Direction dir, rdir;
  InnerOuter io, rio;
  Boolean fin;
  Boolean redecl;
  Replaceable repl;
algorithm
  if referenceEq(origAttr, NFComponent.DEFAULT_ATTR) then
    attr := redeclAttr;
  elseif referenceEq(redeclAttr, NFComponent.DEFAULT_ATTR) then
    attr := origAttr;
  else
    Component.Attributes.ATTRIBUTES(cty, par, var, dir, io, _, _, _) := origAttr;
    Component.Attributes.ATTRIBUTES(rcty, rpar, rvar, rdir, rio, fin, redecl, repl) := redeclAttr;

    // If no prefix is given for one of these attributes in the redeclaration,
    // then the one from the original declaration is used. The redeclare is not
    // allowed to change an existing prefix on the original declaration, except
    // for the variability which can be lowered (e.g. parameter -> constant) and
    // final which is always taken from the redeclare (since redeclaring a final
    // element isn't allowed).

    if rcty <> ConnectorType.POTENTIAL then
      if cty <> ConnectorType.POTENTIAL and cty <> rcty then
        printRedeclarePrefixError(node, Prefixes.connectorTypeString(rcty), Prefixes.connectorTypeString(cty));
      end if;

      cty := rcty;
    end if;

    if rpar <> Parallelism.NON_PARALLEL then
      if par <> Parallelism.NON_PARALLEL and par <> rpar then
        printRedeclarePrefixError(node, Prefixes.parallelismString(rpar), Prefixes.parallelismString(par));
      end if;

      par := rpar;
    end if;

    if rvar <> Variability.CONTINUOUS then
      if rvar > var then
        printRedeclarePrefixError(node, Prefixes.variabilityString(rvar), Prefixes.variabilityString(var));
      end if;

      var := rvar;
    end if;

    if rdir <> Direction.NONE then
    if dir <> Direction.NONE and rdir <> dir then
        printRedeclarePrefixError(node, Prefixes.directionString(rdir), Prefixes.directionString(dir));
      end if;

      dir := rdir;
    end if;

    if rio <> InnerOuter.NOT_INNER_OUTER then
      if io <> InnerOuter.NOT_INNER_OUTER and rio <> io then
        printRedeclarePrefixError(node, Prefixes.innerOuterString(rio), Prefixes.innerOuterString(io));
      end if;

      io := rio;
    end if;

    attr := Component.Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl);
  end if;
end mergeRedeclaredComponentAttributes;

function mergeRedeclaredClassPrefixes
  input Class.Prefixes origPrefs;
  input Class.Prefixes redeclPrefs;
  input InstNode node;
  output Class.Prefixes prefs;
protected
  SCode.Encapsulated enc;
  SCode.Partial par;
  SCode.Final fin;
  Absyn.InnerOuter io, rio;
  SCode.Replaceable repl;
algorithm
  if referenceEq(origPrefs, NFClass.DEFAULT_PREFIXES) then
    prefs := redeclPrefs;
  else
    Class.Prefixes.PREFIXES(innerOuter = io) := origPrefs;
    Class.Prefixes.PREFIXES(enc, par, fin, rio, repl) := redeclPrefs;

    io := match (io, rio)
      case (Absyn.InnerOuter.NOT_INNER_OUTER(), _) then rio;
      case (_, Absyn.InnerOuter.NOT_INNER_OUTER()) then io;
      case (Absyn.InnerOuter.INNER(), Absyn.InnerOuter.INNER()) then io;
      case (Absyn.InnerOuter.OUTER(), Absyn.InnerOuter.OUTER()) then io;
      case (Absyn.InnerOuter.INNER_OUTER(), Absyn.InnerOuter.INNER_OUTER()) then io;
      else
        algorithm
          printRedeclarePrefixError(node,
            Prefixes.innerOuterString(Prefixes.innerOuterFromSCode(rio)),
            Prefixes.innerOuterString(Prefixes.innerOuterFromSCode(io)));
        then
          fail();
    end match;

    prefs := Class.Prefixes.PREFIXES(enc, par, fin, io, repl);
  end if;
end mergeRedeclaredClassPrefixes;

function printRedeclarePrefixError
  input InstNode node;
  input String prefix1;
  input String prefix2;
algorithm
  Error.addSourceMessageAndFail(Error.REDECLARE_MISMATCHED_PREFIX,
    {prefix1, InstNode.name(node), prefix2}, InstNode.info(node));
end printRedeclarePrefixError;

function updateComponentVariability
  input output Component.Attributes attr;
  input Class cls;
  input InstNode clsNode;
protected
  Variability var = attr.variability;
algorithm
  if referenceEq(attr, NFComponent.DEFAULT_ATTR) and
     Type.isDiscrete(Class.getType(cls, clsNode)) then
    attr := NFComponent.IMPL_DISCRETE_ATTR;
  elseif var == Variability.CONTINUOUS and
     Type.isDiscrete(Class.getType(cls, clsNode)) then
    attr.variability := Variability.IMPLICITLY_DISCRETE;
  end if;
end updateComponentVariability;

function instTypeSpec
  input Absyn.TypeSpec typeSpec;
  input Modifier modifier;
  input Component.Attributes attributes;
  input Boolean useBinding;
  input InstNode scope;
  input InstNode parent;
  input SourceInfo info;
  output InstNode node;
  output Component.Attributes outAttributes;
algorithm
  node := match typeSpec
    case Absyn.TPATH()
      algorithm
        node := Lookup.lookupClassName(typeSpec.path, scope, info);
        node := expand(node);
        (node, outAttributes) := instClass(node, modifier, attributes, useBinding, parent);
      then
        node;

    case Absyn.TCOMPLEX()
      algorithm
        print("NFInst.instTypeSpec: TCOMPLEX not implemented.\n");
      then
        fail();

  end match;
end instTypeSpec;

function instDimension
  input output Dimension dimension;
  input InstNode scope;
  input SourceInfo info;
algorithm
  dimension := match dimension
    local
      Absyn.Subscript dim;
      Expression exp;

    case Dimension.RAW_DIM(dim = dim)
      then
        match dim
          case Absyn.NOSUB() then Dimension.UNKNOWN();
          case Absyn.SUBSCRIPT()
            algorithm
              exp := instExp(dim.subscript, scope, info);
            then
              Dimension.UNTYPED(exp, false);
        end match;

    else dimension;
  end match;
end instDimension;

function instExpressions
  input InstNode node;
  input InstNode scope = node;
  input output Sections sections = Sections.EMPTY();
protected
  Class cls = InstNode.getClass(node), inst_cls;
  array<InstNode> local_comps, exts;
  ClassTree cls_tree;
  Restriction res;
  array<Dimension> dims;
  InstNode dim_scope;
  SourceInfo info;
  Type ty;
algorithm
  () := match cls
    // Long class declaration of a type.
    case Class.EXPANDED_CLASS(elements = cls_tree, restriction = Restriction.TYPE())
      algorithm
        // Instantiate expressions in the extends nodes.
        exts := ClassTree.getExtends(cls_tree);
        for ext in exts loop
          instExpressions(ext, ext, sections);
        end for;

        // A type must extend a basic type.
        if arrayLength(exts) == 1 then
          ty := Type.COMPLEX(node, ComplexType.EXTENDS_TYPE(exts[1]));
        elseif SCode.hasBooleanNamedAnnotationInClass(InstNode.definition(node), "__OpenModelica_builtinType") then
          ty := Type.COMPLEX(node, ComplexType.CLASS());
        else
          Error.addSourceMessage(Error.MISSING_TYPE_BASETYPE,
            {InstNode.name(node)}, InstNode.info(node));
          fail();
        end if;

        cls_tree := ClassTree.flatten(cls_tree);
        inst_cls := Class.INSTANCED_CLASS(ty, cls_tree, Sections.EMPTY(), cls.restriction);
        InstNode.updateClass(inst_cls, node);
      then
        ();

    case Class.EXPANDED_CLASS(elements = cls_tree)
      algorithm
        // Instantiate expressions in the extends nodes.
        for ext in ClassTree.getExtends(cls_tree) loop
          sections := instExpressions(ext, ext, sections);
        end for;

        // Instantiate expressions in the local components.
        ClassTree.applyLocalComponents(cls_tree, instComponentExpressions);

        // Flatten the class tree so we don't need to deal with extends anymore.
        cls.elements := ClassTree.flatten(cls_tree);
        InstNode.updateClass(cls, node);

        // Instantiate local equation/algorithm sections.
        sections := instSections(node, scope, sections, Restriction.isFunction(cls.restriction));

        ty := makeComplexType(cls.restriction, node, cls);
        inst_cls := Class.INSTANCED_CLASS(ty, cls.elements, sections, cls.restriction);
        InstNode.updateClass(inst_cls, node);

        instComplexType(ty);
      then
        ();

    case Class.EXPANDED_DERIVED(dims = dims)
      algorithm
        sections := instExpressions(cls.baseClass, scope, sections);

        dim_scope := InstNode.parent(node);
        info := InstNode.info(node);

        for i in 1:arrayLength(dims) loop
          dims[i] := instDimension(dims[i], dim_scope, info);
        end for;

        if Restriction.isRecord(cls.restriction) then
          instRecordConstructor(node);
        end if;
      then
        ();

    case Class.INSTANCED_BUILTIN(elements = ClassTree.FLAT_TREE(components = local_comps))
      algorithm
        for comp in local_comps loop
          instComponentExpressions(comp);
        end for;
      then
        ();

    case Class.INSTANCED_BUILTIN() then ();
    case Class.INSTANCED_CLASS() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got invalid class", sourceInfo());
      then
        fail();

  end match;
end instExpressions;

function makeComplexType
  input Restriction restriction;
  input InstNode node;
  input Class cls;
  output Type ty;
protected
  ComplexType cty;
algorithm
  cty := match restriction
    case Restriction.RECORD()
      then makeRecordComplexType(InstNode.classScope(InstNode.getDerivedNode(node)), cls);
    else ComplexType.CLASS();
  end match;

  ty := Type.COMPLEX(node, cty);
end makeComplexType;

function makeRecordComplexType
  input InstNode node;
  input Class cls;
  output ComplexType ty;
protected
  InstNode cls_node;
  list<String> inputs;
  list<String> fields;
algorithm
  cls_node := if SCode.isOperatorRecord(InstNode.definition(node))
    then InstNode.classScope(node) else InstNode.classScope(InstNode.getDerivedNode(node));
  fields := list(InstNode.name(c) for c in Record.collectRecordParams(cls_node));
  ty := ComplexType.RECORD(cls_node, fields);
end makeRecordComplexType;

function instComplexType
  input Type ty;
algorithm
  () := match ty
    local
      InstNode node;
      CachedData cache;

    case Type.COMPLEX(complexTy = ComplexType.RECORD(node))
      algorithm
        instRecordConstructor(node);
      then
        ();

    else ();
  end match;
end instComplexType;

function instRecordConstructor
  input InstNode node;
protected
  CachedData cache;
algorithm
  cache := InstNode.getFuncCache(node);

  () := match cache
    case CachedData.FUNCTION() then ();
    else
      algorithm
        InstNode.cacheInitFunc(node);

        if SCode.isOperatorRecord(InstNode.definition(node)) then
          OperatorOverloading.instConstructor(
            InstNode.scopePath(node, includeRoot = true), node, InstNode.info(node));
        else
          Record.instDefaultConstructor(
            InstNode.scopePath(node, includeRoot = true), node, InstNode.info(node));
        end if;
      then
        ();

  end match;
end instRecordConstructor;

function instBuiltinAttribute
  input output Modifier attribute;
  input InstNode node;
algorithm
  () := match attribute
    local
      Binding binding;

    case Modifier.MODIFIER(binding = Binding.UNBOUND()) then ();

    case Modifier.MODIFIER(binding = binding)
      algorithm
        binding := Binding.addParent(node, binding);
        attribute.binding := instBinding(binding);
      then
        ();

    // Redeclaration of builtin attributes is not allowed.
    case Modifier.REDECLARE()
      algorithm
        Error.addSourceMessage(Error.INVALID_REDECLARE_IN_BASIC_TYPE,
          {Modifier.name(attribute)}, Modifier.info(attribute));
      then
        fail();

  end match;
end instBuiltinAttribute;

function instComponentExpressions
  input InstNode component;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c = InstNode.component(node);
  array<Dimension> dims;
algorithm
  () := match c
    case Component.UNTYPED_COMPONENT(dimensions = dims, instantiated = false)
      algorithm
        c.binding := instBinding(c.binding);
        c.condition := instBinding(c.condition);
        instExpressions(c.classInst, node);

        for i in 1:arrayLength(dims) loop
          dims[i] := instDimension(dims[i], InstNode.parent(node), c.info);
        end for;

        // This is to avoid instantiating the same component multiple times,
        // which can otherwise happen with duplicate components at this stage.
        c.instantiated := true;

        InstNode.updateComponent(c, node);
      then
        ();

    case Component.UNTYPED_COMPONENT() then ();
    case Component.ENUM_LITERAL() then ();
    case Component.TYPE_ATTRIBUTE(modifier = Modifier.NOMOD()) then ();

    case Component.TYPE_ATTRIBUTE()
      algorithm
        c.modifier := instBuiltinAttribute(c.modifier, component);
        InstNode.updateComponent(c, node);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got invalid component", sourceInfo());
      then
        fail();

  end match;
end instComponentExpressions;

function instBinding
  input output Binding binding;
algorithm
  binding := match binding
    local
      Expression bind_exp;

    case Binding.RAW_BINDING()
      algorithm
        bind_exp := instExp(binding.bindingExp, binding.scope, binding.info);
      then
        Binding.UNTYPED_BINDING(bind_exp, false, binding.scope, binding.parents, binding.isEach, binding.info);

    else binding;
  end match;
end instBinding;

function instExpOpt
  input Option<Absyn.Exp> absynExp;
  input InstNode scope;
  input SourceInfo info;
  output Option<Expression> exp;
algorithm
  exp := match absynExp
    local
      Absyn.Exp aexp;

    case NONE() then NONE();
    case SOME(aexp) then SOME(instExp(aexp, scope, info));

  end match;
end instExpOpt;

function instExp
  input Absyn.Exp absynExp;
  input InstNode scope;
  input SourceInfo info;
  output Expression exp;
algorithm
  exp := match absynExp
    local
      Expression e1, e2, e3;
      Option<Expression> oe;
      Operator op;
      list<Expression> expl;
      list<list<Expression>> expll;

    case Absyn.Exp.INTEGER() then Expression.INTEGER(absynExp.value);
    case Absyn.Exp.REAL() then Expression.REAL(stringReal(absynExp.value));
    case Absyn.Exp.STRING() then Expression.STRING(System.unescapedString(absynExp.value));
    case Absyn.Exp.BOOL() then Expression.BOOLEAN(absynExp.value);

    case Absyn.Exp.CREF()
      then instCref(absynExp.componentRef, scope, info);

    case Absyn.Exp.ARRAY()
      algorithm
        expl := list(instExp(e, scope, info) for e in absynExp.arrayExp);
      then
        Expression.makeArray(Type.UNKNOWN(), expl);

    case Absyn.Exp.MATRIX()
      algorithm
        expll := list(list(instExp(e, scope, info) for e in el) for el in absynExp.matrix);
      then
        Expression.MATRIX(expll);

    case Absyn.Exp.RANGE()
      algorithm
        e1 := instExp(absynExp.start, scope, info);
        oe := instExpOpt(absynExp.step, scope, info);
        e3 := instExp(absynExp.stop, scope, info);
      then
        Expression.RANGE(Type.UNKNOWN(), e1, oe, e3);

    case Absyn.Exp.TUPLE()
      algorithm
        expl := list(instExp(e, scope, info) for e in absynExp.expressions);
      then
        Expression.TUPLE(Type.UNKNOWN(), expl);

    case Absyn.Exp.BINARY()
      algorithm
        e1 := instExp(absynExp.exp1, scope, info);
        e2 := instExp(absynExp.exp2, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.BINARY(e1, op, e2);

    case Absyn.Exp.UNARY()
      algorithm
        e1 := instExp(absynExp.exp, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.UNARY(op, e1);

    case Absyn.Exp.LBINARY()
      algorithm
        e1 := instExp(absynExp.exp1, scope, info);
        e2 := instExp(absynExp.exp2, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.LBINARY(e1, op, e2);

    case Absyn.Exp.LUNARY()
      algorithm
        e1 := instExp(absynExp.exp, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.LUNARY(op, e1);

    case Absyn.Exp.RELATION()
      algorithm
        e1 := instExp(absynExp.exp1, scope, info);
        e2 := instExp(absynExp.exp2, scope, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.RELATION(e1, op, e2);

    case Absyn.Exp.IFEXP()
      algorithm
        e3 := instExp(absynExp.elseBranch, scope, info);

        for branch in listReverse(absynExp.elseIfBranch) loop
          e1 := instExp(Util.tuple21(branch), scope, info);
          e2 := instExp(Util.tuple22(branch), scope, info);
          e3 := Expression.IF(e1, e2, e3);
        end for;

        e1 := instExp(absynExp.ifExp, scope, info);
        e2 := instExp(absynExp.trueBranch, scope, info);
      then
        Expression.IF(e1, e2, e3);

    case Absyn.Exp.CALL()
      then Call.instantiate(absynExp.function_, absynExp.functionArgs, scope, info);

    case Absyn.Exp.PARTEVALFUNCTION()
      then instPartEvalFunction(absynExp.function_, absynExp.functionArgs, scope, info);

    case Absyn.Exp.END() then Expression.END();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown expression: " + Dump.printExpStr(absynExp), sourceInfo());
      then
        fail();

  end match;
end instExp;

function instCref
  input Absyn.ComponentRef absynCref;
  input InstNode scope;
  input SourceInfo info;
  output Expression crefExp;
protected
  ComponentRef cref, prefixed_cref;
  InstNode found_scope;
  Type ty;
  Component comp;
algorithm
  (cref, found_scope) := match absynCref
    case Absyn.ComponentRef.WILD() then (ComponentRef.WILD(), scope);
    case Absyn.ComponentRef.ALLWILD() then (ComponentRef.WILD(), scope);
    else Lookup.lookupComponent(absynCref, scope, info);
  end match;

  cref := instCrefSubscripts(cref, scope, info);

  crefExp := match cref
    case ComponentRef.CREF()
      then
        match cref.node
          case InstNode.COMPONENT_NODE()
            then instCrefComponent(cref, cref.node, found_scope, info);
          case InstNode.CLASS_NODE()
            then if Class.isFunction(InstNode.getClass(cref.node)) then
                   instCrefFunction(cref, info)
                 else
                   instCrefTypename(cref, cref.node, info);
          else
            algorithm
              Error.assertion(false, getInstanceName() + " got invalid instance node", sourceInfo());
            then
              fail();
        end match;

    else Expression.CREF(Type.UNKNOWN(), cref);
  end match;
end instCref;

function instCrefComponent
  input ComponentRef cref;
  input InstNode node;
  input InstNode scope;
  input SourceInfo info;
  output Expression crefExp;
protected
  Component comp;
  ComponentRef prefixed_cref;
algorithm
  comp := InstNode.component(node);

  crefExp := match comp
    case Component.ITERATOR()
      algorithm
        checkUnsubscriptableCref(cref, info);
      then
        Expression.CREF(Type.UNKNOWN(), ComponentRef.makeIterator(node, comp.ty));

    case Component.ENUM_LITERAL()
      algorithm
        checkUnsubscriptableCref(cref, info);
      then
        comp.literal;

    case Component.TYPE_ATTRIBUTE()
      algorithm
        Error.addSourceMessage(Error.LOOKUP_VARIABLE_ERROR,
          {InstNode.name(node), InstNode.name(InstNode.parent(node))}, info);
      then
        fail();

    else
      algorithm
        prefixed_cref := ComponentRef.fromNodeList(InstNode.scopeList(scope));
        prefixed_cref := if ComponentRef.isEmpty(prefixed_cref) then
          cref else ComponentRef.append(cref, prefixed_cref);
      then
        Expression.CREF(Type.UNKNOWN(), prefixed_cref);

  end match;
end instCrefComponent;

function instCrefFunction
  input ComponentRef cref;
  input SourceInfo info;
  output Expression crefExp;
protected
  ComponentRef fn_ref;
algorithm
  fn_ref := Function.instFunctionRef(cref, info);
  crefExp := Expression.CREF(Type.UNKNOWN(), fn_ref);
end instCrefFunction;

function instCrefTypename
  input ComponentRef cref;
  input InstNode node;
  input SourceInfo info;
  output Expression crefExp;
protected
  Type ty;
algorithm
  checkUnsubscriptableCref(cref, info);
  ty := InstNode.getType(node);

  ty := match ty
    case Type.BOOLEAN() then Type.ARRAY(ty, {Dimension.BOOLEAN()});
    case Type.ENUMERATION() then Type.ARRAY(ty, {Dimension.ENUM(ty)});
    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown class node " +
         InstNode.name(node), sourceInfo());
      then
        fail();
  end match;

  crefExp := Expression.TYPENAME(ty);
end instCrefTypename;

function checkUnsubscriptableCref
  input ComponentRef cref;
  input SourceInfo info;
algorithm
  if ComponentRef.hasSubscripts(cref) then
    Error.addSourceMessage(Error.WRONG_NUMBER_OF_SUBSCRIPTS,
      {ComponentRef.toString(cref), String(listLength(ComponentRef.getSubscripts(cref))), "0"}, info);
    fail();
  end if;
end checkUnsubscriptableCref;

function instCrefSubscripts
  input output ComponentRef cref;
  input InstNode scope;
  input SourceInfo info;
algorithm
  () := match cref
    local
      ComponentRef rest_cr;

    case ComponentRef.CREF()
      algorithm
        if not listEmpty(cref.subscripts) then
          cref.subscripts := list(instSubscript(s, scope, info) for s in cref.subscripts);
        end if;

        rest_cr := instCrefSubscripts(cref.restCref, scope, info);
        if not referenceEq(rest_cr, cref.restCref) then
          cref.restCref := rest_cr;
        end if;
      then
        ();

    else ();
  end match;
end instCrefSubscripts;

function instSubscript
  input Subscript subscript;
  input InstNode scope;
  input SourceInfo info;
  output Subscript outSubscript;
protected
  Expression exp;
  Absyn.Subscript absynSub;
algorithm
  Subscript.RAW_SUBSCRIPT(subscript = absynSub) := subscript;

  outSubscript := match absynSub
    case Absyn.Subscript.NOSUB() then Subscript.WHOLE();
    case Absyn.Subscript.SUBSCRIPT()
      algorithm
        exp := instExp(absynSub.subscript, scope, info);
      then
        Subscript.fromExp(exp);
  end match;
end instSubscript;

function instPartEvalFunction
  input Absyn.ComponentRef func;
  input Absyn.FunctionArgs funcArgs;
  input InstNode scope;
  input SourceInfo info;
  output Expression outExp;
protected
  ComponentRef fn_ref;
  list<Absyn.NamedArg> nargs;
  list<Expression> args;
  list<String> arg_names;
algorithm
  Absyn.FunctionArgs.FUNCTIONARGS(argNames = nargs) := funcArgs;
  outExp := instCref(func, scope, info);

  if not listEmpty(nargs) then
    fn_ref := Expression.toCref(outExp);
    args := list(instExp(arg.argValue, scope, info) for arg in nargs);
    arg_names := list(arg.argName for arg in nargs);
    outExp := Expression.PARTIAL_FUNCTION_APPLICATION(fn_ref, args, arg_names, Type.UNKNOWN());
  end if;
end instPartEvalFunction;

function instSections
  input InstNode node;
  input InstNode scope;
  input output Sections sections;
  input Boolean isFunction;
protected
  SCode.Element el = InstNode.definition(node);
  SCode.ClassDef def;
algorithm
  sections := match el
    case SCode.CLASS(classDef = SCode.PARTS())
      then instSections2(el.classDef, scope, sections, isFunction);

    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = def as SCode.PARTS()))
      then instSections2(def, scope, sections, isFunction);

    else sections;
  end match;
end instSections;

function instSections2
  input SCode.ClassDef parts;
  input InstNode scope;
  input output Sections sections;
  input Boolean isFunction;
algorithm
  sections := match (parts, sections)
    local
      list<Equation> eq, ieq;
      list<Algorithm> alg, ialg;
      SCode.ExternalDecl ext_decl;
      ExpOrigin.Type origin, iorigin;

    case (_, Sections.EXTERNAL())
      algorithm
        Error.addSourceMessage(Error.MULTIPLE_SECTIONS_IN_FUNCTION,
          {InstNode.name(scope)}, InstNode.info(scope));
      then
        fail();

    case (SCode.PARTS(externalDecl = SOME(ext_decl)), _)
      then instExternalDecl(ext_decl, scope);

    case (SCode.PARTS(), _)
      algorithm
        origin := if isFunction then ExpOrigin.FUNCTION else ExpOrigin.CLASS;
        iorigin := ExpOrigin.setFlag(origin, ExpOrigin.INITIAL);

        eq := instEquations(parts.normalEquationLst, scope, origin);
        ieq := instEquations(parts.initialEquationLst, scope, iorigin);
        alg := instAlgorithmSections(parts.normalAlgorithmLst, scope, origin);
        ialg := instAlgorithmSections(parts.initialAlgorithmLst, scope, iorigin);
      then
        Sections.join(Sections.new(eq, ieq, alg, ialg), sections);

  end match;
end instSections2;

function instExternalDecl
  input SCode.ExternalDecl extDecl;
  input InstNode scope;
  output Sections sections;
algorithm
  sections := match extDecl
    local
      String name;
      String lang;
      list<Expression> args;
      ComponentRef ret_cref;
      SourceInfo info;

    case SCode.EXTERNALDECL()
      algorithm
        info := InstNode.info(scope);
        name := Util.getOptionOrDefault(extDecl.funcName, InstNode.name(scope));
        lang := Util.getOptionOrDefault(extDecl.lang, "C");
        checkExternalDeclLanguage(lang, info);
        args := list(instExp(arg, scope, info) for arg in extDecl.args);

        if isSome(extDecl.output_) then
          ret_cref := Lookup.lookupLocalComponent(Util.getOption(extDecl.output_), scope, info);
        else
          ret_cref := ComponentRef.EMPTY();
        end if;
      then
        Sections.EXTERNAL(name, args, ret_cref, lang, extDecl.annotation_, isSome(extDecl.funcName));

  end match;
end instExternalDecl;

function checkExternalDeclLanguage
  "Checks that the language declared for an external function is valid."
  input String language;
  input SourceInfo info;
algorithm
  () := match language
    // The specification also allows for C89, C99, and C11, but our code
    // generation only seems to support C.
    case "C" then ();
    case "FORTRAN 77" then ();
    // Not in the specification, but used by libraries and allowed by other tools.
    case "Fortran 77" then ();
    case "builtin" then ();
    else
      algorithm
        Error.addSourceMessage(Error.INVALID_EXTERNAL_LANGUAGE,
          {language}, info);
      then
        fail();
  end match;
end checkExternalDeclLanguage;

function instEquations
  input list<SCode.Equation> scodeEql;
  input InstNode scope;
  input ExpOrigin.Type origin;
  output list<Equation> instEql;
algorithm
  instEql := list(instEquation(eq, scope, origin) for eq in scodeEql);
end instEquations;

function instEquation
  input SCode.Equation scodeEq;
  input InstNode scope;
  input ExpOrigin.Type origin;
  output Equation instEq;
protected
  SCode.EEquation eq;
algorithm
  SCode.EQUATION(eEquation = eq) := scodeEq;
  instEq := instEEquation(eq, scope, origin);
end instEquation;

function instEEquations
  input list<SCode.EEquation> scodeEql;
  input InstNode scope;
  input ExpOrigin.Type origin;
  output list<Equation> instEql;
algorithm
  instEql := list(instEEquation(eq, scope, origin) for eq in scodeEql);
end instEEquations;

function instEEquation
  input SCode.EEquation scodeEq;
  input InstNode scope;
  input ExpOrigin.Type origin;
  output Equation instEq;
algorithm
  instEq := match scodeEq
    local
      Expression exp1, exp2, exp3;
      Option<Expression> oexp;
      list<Expression> expl;
      list<Equation> eql;
      list<Equation.Branch> branches;
      SourceInfo info;
      InstNode for_scope, iter;
      ComponentRef lhs_cr, rhs_cr;
      ExpOrigin.Type next_origin;

    case SCode.EEquation.EQ_EQUALS(info = info)
      algorithm
        exp1 := instExp(scodeEq.expLeft, scope, info);
        exp2 := instExp(scodeEq.expRight, scope, info);

        if ExpOrigin.flagSet(origin, ExpOrigin.WHEN) and not checkLhsInWhen(exp1) then
          Error.addSourceMessage(Error.WHEN_EQ_LHS, {Expression.toString(exp1)}, info);
          fail();
        end if;
      then
        Equation.EQUALITY(exp1, exp2, Type.UNKNOWN(), makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_CONNECT(info = info)
      algorithm
        if ExpOrigin.flagSet(origin, ExpOrigin.WHEN) then
          Error.addSourceMessage(Error.CONNECT_IN_WHEN,
            {Dump.printComponentRefStr(scodeEq.crefLeft),
             Dump.printComponentRefStr(scodeEq.crefRight)}, info);
          fail();
        end if;

        exp1 := instCref(scodeEq.crefLeft, scope, info);
        exp2 := instCref(scodeEq.crefRight, scope, info);
      then
        Equation.CONNECT(exp1, exp2, {}, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_FOR(info = info)
      algorithm
        oexp := instExpOpt(scodeEq.range, scope, info);
        (for_scope, iter) := addIteratorToScope(scodeEq.index, scope, scodeEq.info);
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.FOR);
        eql := instEEquations(scodeEq.eEquationLst, for_scope, next_origin);
      then
        Equation.FOR(iter, oexp, eql, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_IF(info = info)
      algorithm
        // Instantiate the conditions.
        expl := list(instExp(c, scope, info) for c in scodeEq.condition);

        // Instantiate each branch and pair it up with a condition.
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.IF);
        branches := {};
        for branch in scodeEq.thenBranch loop
          eql := instEEquations(branch, scope, next_origin);
          exp1 :: expl := expl;
          branches := Equation.makeBranch(exp1, eql) :: branches;
        end for;

        // Instantiate the else-branch, if there is one, and make it a branch
        // with condition true (so we only need a simple list of branches).
        if not listEmpty(scodeEq.elseBranch) then
          eql := instEEquations(scodeEq.elseBranch, scope, next_origin);
          branches := Equation.makeBranch(Expression.BOOLEAN(true), eql) :: branches;
        end if;
      then
        Equation.IF(listReverse(branches), makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_WHEN(info = info)
      algorithm
        if ExpOrigin.flagSet(origin, ExpOrigin.WHEN) then
          Error.addSourceMessageAndFail(Error.NESTED_WHEN, {}, info);
        elseif ExpOrigin.flagSet(origin, ExpOrigin.INITIAL) then
          Error.addSourceMessageAndFail(Error.INITIAL_WHEN, {}, info);
        end if;

        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.WHEN);
        exp1 := instExp(scodeEq.condition, scope, info);
        eql := instEEquations(scodeEq.eEquationLst, scope, next_origin);
        branches := {Equation.makeBranch(exp1, eql)};

        for branch in scodeEq.elseBranches loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          eql := instEEquations(Util.tuple22(branch), scope, next_origin);
          branches := Equation.makeBranch(exp1, eql) :: branches;
        end for;
      then
        Equation.WHEN(listReverse(branches), makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_ASSERT(info = info)
      algorithm
        exp1 := instExp(scodeEq.condition, scope, info);
        exp2 := instExp(scodeEq.message, scope, info);
        exp3 := instExp(scodeEq.level, scope, info);
      then
        Equation.ASSERT(exp1, exp2, exp3, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_TERMINATE(info = info)
      algorithm
        exp1 := instExp(scodeEq.message, scope, info);
      then
        Equation.TERMINATE(exp1, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_REINIT(info = info)
      algorithm
        if ExpOrigin.flagNotSet(origin, ExpOrigin.WHEN) then
          Error.addSourceMessage(Error.REINIT_NOT_IN_WHEN, {}, info);
          fail();
        end if;

        exp1 := instExp(scodeEq.cref, scope, info);
        exp2 := instExp(scodeEq.expReinit, scope, info);
      then
        Equation.REINIT(exp1, exp2, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_NORETCALL(info = info)
      algorithm
        exp1 := instExp(scodeEq.exp, scope, info);
      then
        Equation.NORETCALL(exp1, makeSource(scodeEq.comment, info));

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown equation", sourceInfo());
      then
        fail();

  end match;
end instEEquation;

function makeSource
  input SCode.Comment comment;
  input SourceInfo info;
  output DAE.ElementSource source;
algorithm
  source := DAE.ElementSource.SOURCE(info, {}, DAE.Prefix.NOCOMPPRE(), {}, {}, {}, {comment});
end makeSource;

function instAlgorithmSections
  input list<SCode.AlgorithmSection> algorithmSections;
  input InstNode scope;
  input ExpOrigin.Type origin;
  output list<Algorithm> algs;
algorithm
  algs := list(instAlgorithmSection(alg, scope, origin) for alg in algorithmSections);
end instAlgorithmSections;

function instAlgorithmSection
  input SCode.AlgorithmSection algorithmSection;
  input InstNode scope;
  input ExpOrigin.Type origin;
  output Algorithm alg;
algorithm
  alg := Algorithm.ALGORITHM(instStatements(algorithmSection.statements, scope, origin),
                             DAE.emptyElementSource);
end instAlgorithmSection;

function instStatements
  input list<SCode.Statement> scodeStmtl;
  input InstNode scope;
  input ExpOrigin.Type origin;
  output list<Statement> statements;
algorithm
  statements := list(instStatement(stmt, scope, origin) for stmt in scodeStmtl);
end instStatements;

function instStatement
  input SCode.Statement scodeStmt;
  input InstNode scope;
  input ExpOrigin.Type origin;
  output Statement statement;
algorithm
  statement := match scodeStmt
    local
      Expression exp1, exp2, exp3;
      Option<Expression> oexp;
      list<Statement> stmtl;
      list<tuple<Expression, list<Statement>>> branches;
      SourceInfo info;
      InstNode for_scope, iter;
      ExpOrigin.Type next_origin;

    case SCode.Statement.ALG_ASSIGN(info = info)
      algorithm
        exp1 := instExp(scodeStmt.assignComponent, scope, info);
        exp2 := instExp(scodeStmt.value, scope, info);
      then
        Statement.ASSIGNMENT(exp1, exp2, Type.UNKNOWN(), makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_FOR(info = info)
      algorithm
        oexp := instExpOpt(scodeStmt.range, scope, info);
        (for_scope, iter) := addIteratorToScope(scodeStmt.index, scope, info);
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.FOR);
        stmtl := instStatements(scodeStmt.forBody, for_scope, next_origin);
      then
        Statement.FOR(iter, oexp, stmtl, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_IF(info = info)
      algorithm
        branches := {};
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.FOR);

        for branch in (scodeStmt.boolExpr, scodeStmt.trueBranch) :: scodeStmt.elseIfBranch loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          stmtl := instStatements(Util.tuple22(branch), scope, next_origin);
          branches := (exp1, stmtl) :: branches;
        end for;

        if not listEmpty(scodeStmt.elseBranch) then
          stmtl := instStatements(scodeStmt.elseBranch, scope, next_origin);
          branches := (Expression.BOOLEAN(true), stmtl) :: branches;
        end if;
      then
        Statement.IF(listReverse(branches), makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_WHEN_A(info = info)
      algorithm
        if origin > 0 then
          if ExpOrigin.flagSet(origin, ExpOrigin.WHEN) then
            Error.addSourceMessageAndFail(Error.NESTED_WHEN, {}, info);
          elseif ExpOrigin.flagSet(origin, ExpOrigin.INITIAL) then
            Error.addSourceMessageAndFail(Error.INITIAL_WHEN, {}, info);
          else
            Error.addSourceMessageAndFail(Error.INVALID_WHEN_STATEMENT_CONTEXT, {}, info);
          end if;
        end if;

        branches := {};
        for branch in scodeStmt.branches loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          next_origin := ExpOrigin.setFlag(origin, ExpOrigin.WHEN);
          stmtl := instStatements(Util.tuple22(branch), scope, next_origin);
          branches := (exp1, stmtl) :: branches;
        end for;
      then
        Statement.WHEN(listReverse(branches), makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_ASSERT(info = info)
      algorithm
        exp1 := instExp(scodeStmt.condition, scope, info);
        exp2 := instExp(scodeStmt.message, scope, info);
        exp3 := instExp(scodeStmt.level, scope, info);
      then
        Statement.ASSERT(exp1, exp2, exp3, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_TERMINATE(info = info)
      algorithm
        exp1 := instExp(scodeStmt.message, scope, info);
      then
        Statement.TERMINATE(exp1, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_REINIT(info = info)
      algorithm
        Error.addSourceMessage(Error.REINIT_NOT_IN_WHEN, {}, info);
      then
        fail();

    case SCode.Statement.ALG_NORETCALL(info = info)
      algorithm
        exp1 := instExp(scodeStmt.exp, scope, info);
      then
        Statement.NORETCALL(exp1, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_WHILE(info = info)
      algorithm
        exp1 := instExp(scodeStmt.boolExpr, scope, info);
        next_origin := ExpOrigin.setFlag(origin, ExpOrigin.WHILE);
        stmtl := instStatements(scodeStmt.whileBody, scope, next_origin);
      then
        Statement.WHILE(exp1, stmtl, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_RETURN()
      then Statement.RETURN(makeSource(scodeStmt.comment, scodeStmt.info));

    case SCode.Statement.ALG_BREAK()
      then Statement.BREAK(makeSource(scodeStmt.comment, scodeStmt.info));

    case SCode.Statement.ALG_FAILURE()
      algorithm
        stmtl := instStatements(scodeStmt.stmts, scope, origin);
      then
        Statement.FAILURE(stmtl, makeSource(scodeStmt.comment, scodeStmt.info));

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown statement", sourceInfo());
      then
        fail();

  end match;
end instStatement;

function addIteratorToScope
  input String name;
  input output InstNode scope;
  input SourceInfo info;
  input Type iter_type = Type.UNKNOWN();
        output InstNode iterator;
protected
  Component iter_comp;
algorithm
  scope := InstNode.openImplicitScope(scope);
  iter_comp := Component.ITERATOR(iter_type, Variability.CONTINUOUS, info);
  iterator := InstNode.fromComponent(name, iter_comp, scope);
  scope := InstNode.addIterator(iterator, scope);
end addIteratorToScope;

function checkLhsInWhen
  input Expression exp;
  output Boolean isValid;
algorithm
  isValid := match exp
    case Expression.CREF() then true;
    case Expression.TUPLE()
      algorithm
        for e in exp.elements loop
          checkLhsInWhen(e);
        end for;
      then
        true;
    else false;
  end match;
end checkLhsInWhen;

function insertGeneratedInners
  "Inner elements can be generated automatically during instantiation if they're
   missing, and are stored in the cache of the top scope since that's easily
   accessible during lookup. This function copies any such inner elements into
   the class we're instantiating, so that they are typed and flattened properly."
  input InstNode node;
  input InstNode topScope;
protected
  NodeTree.Tree inner_tree;
  list<tuple<String, InstNode>> inner_nodes;
  list<Mutable<InstNode>> inner_comps;
  InstNode n;
  String name, str;
  Class cls;
  ClassTree cls_tree;
algorithm
  CachedData.TOP_SCOPE(addedInner = inner_tree) := InstNode.getInnerOuterCache(topScope);

  // Empty tree => nothing more to do.
  if NodeTree.isEmpty(inner_tree) then
    return;
  end if;

  inner_nodes := NodeTree.toList(inner_tree);
  inner_comps := {};

  for e in inner_nodes loop
    (name, n) := e;

    // Always print a warning that an inner element was automatically generated.
    Error.addSourceMessage(Error.MISSING_INNER_ADDED,
      {InstNode.typeName(n), name}, InstNode.info(n));

    // Only components needs to be added to the class, since classes are
    // not part of the flat class.
    if InstNode.isComponent(n) then
      // The components shouldn't have been instantiated yet, so do it here.
      instComponent(n, NFComponent.DEFAULT_ATTR, Modifier.NOMOD(), true);

      // If the component's class has a missingInnerMessage annotation, use it
      // to give a diagnostic message.
      try
        Absyn.STRING(str) := SCode.getElementNamedAnnotation(
          InstNode.definition(InstNode.classScope(n)), "missingInnerMessage");
        Error.addSourceMessage(Error.MISSING_INNER_MESSAGE, {System.unescapedString(str)}, InstNode.info(n));
      else
      end try;

      // Add the instantiated component to the list.
      inner_comps := Mutable.create(n) :: inner_comps;
    end if;
  end for;

  // If we found any components, add them to the component list of the class tree.
  if not listEmpty(inner_comps) then
    cls := InstNode.getClass(node);
    cls_tree := ClassTree.appendComponentsToInstTree(inner_comps, Class.classTree(cls));
    InstNode.updateClass(Class.setClassTree(cls_tree, cls), node);
  end if;
end insertGeneratedInners;

function updateImplicitVariability
  input InstNode node;
  input Boolean evalAllParams;
protected
  Class cls = InstNode.getClass(node);
  ClassTree cls_tree;
algorithm
  () := match cls
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          if not InstNode.isEmpty(c) then
          updateImplicitVariabilityComp(c, evalAllParams);
          end if;
        end for;

        Sections.apply(cls.sections,
          function updateImplicitVariabilityEq(inWhen = false),
          updateImplicitVariabilityAlg);
      then
        ();

    case Class.EXPANDED_DERIVED()
      algorithm
        for dim in cls.dims loop
          markStructuralParamsDim(dim);
        end for;

        updateImplicitVariability(cls.baseClass, evalAllParams);
      then
        ();

    case Class.INSTANCED_BUILTIN(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          updateImplicitVariabilityComp(c, evalAllParams);
        end for;
      then
        ();

    else ();
  end match;
end updateImplicitVariability;

function updateImplicitVariabilityComp
  input InstNode component;
  input Boolean evalAllParams;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c = InstNode.component(node);
algorithm
  () := match c
    local
      Binding binding, condition;

    case Component.UNTYPED_COMPONENT(binding = binding, condition = condition)
      algorithm
        // @adrpo: if Evaluate=true make the parameter a structural parameter
        // only make it a structural parameter if is not constant, duh!, 1071 regressions :)
        if c.attributes.variability == Variability.PARAMETER and
           (Component.getEvaluateAnnotation(c) or evalAllParams) then
          markStructuralParamsComp(c, node);
        end if;

        for dim in c.dimensions loop
          markStructuralParamsDim(dim);
        end for;

        if Binding.isBound(binding) then
          markStructuralParamsExpSize(Binding.getUntypedExp(binding));
        end if;

        if Binding.isBound(condition) then
          markStructuralParamsExp(Binding.getUntypedExp(condition));
        end if;

        updateImplicitVariability(c.classInst, evalAllParams);
      then
        ();

    case Component.TYPE_ATTRIBUTE()
      guard listMember(InstNode.name(component), {"fixed", "stateSelect"})
      algorithm
        binding := Modifier.binding(c.modifier);

        if Binding.isBound(binding) then
          markStructuralParamsExp(Binding.getUntypedExp(binding));
        end if;
      then
        ();

    else ();
  end match;
end updateImplicitVariabilityComp;

function markStructuralParamsDim
  input Dimension dimension;
algorithm
  () := match dimension
    case Dimension.UNTYPED()
      algorithm
        markStructuralParamsExp(dimension.dimension);
      then
        ();

    case Dimension.EXP()
      algorithm
        markStructuralParamsExp(dimension.exp);
      then
        ();

    else ();
  end match;
end markStructuralParamsDim;

function markStructuralParamsExp
  input Expression exp;
algorithm
  Expression.apply(exp, markStructuralParamsExp_traverser);
end markStructuralParamsExp;

function markStructuralParamsExp_traverser
  input Expression exp;
  import NFComponentRef.Origin;
algorithm
  () := match exp
    local
      InstNode node;
      Component comp;
      Option<Expression> binding;

    case Expression.CREF(cref = ComponentRef.CREF(node = node, origin = Origin.CREF))
      algorithm
        if InstNode.isComponent(node) then
          comp := InstNode.component(node);

          if Component.variability(comp) == Variability.PARAMETER then
            markStructuralParamsComp(comp, node);
          end if;
        end if;
      then
        ();

    else ();
  end match;
end markStructuralParamsExp_traverser;

function markStructuralParamsComp
  input Component component;
  input InstNode node;
protected
  Component comp;
  Option<Expression> binding;
algorithm
  comp := Component.setVariability(Variability.STRUCTURAL_PARAMETER, component);
  InstNode.updateComponent(comp, node);

  binding := Binding.untypedExp(Component.getBinding(comp));
  if isSome(binding) then
    markStructuralParamsExp(Util.getOption(binding));
  end if;
end markStructuralParamsComp;

function markStructuralParamsExpSize
  input Expression exp;
algorithm
  Expression.apply(exp, markStructuralParamsExpSize_traverser);
end markStructuralParamsExpSize;

function markStructuralParamsExpSize_traverser
  input Expression exp;
algorithm
  () := match exp
    local
      list<tuple<InstNode, Expression>> iters;

    case Expression.CALL(call = Call.UNTYPED_ARRAY_CONSTRUCTOR(iters = iters))
      algorithm
        for iter in iters loop
          markStructuralParamsExp(Util.tuple22(iter));
        end for;
      then
        ();

    else ();
  end match;
end markStructuralParamsExpSize_traverser;

function updateImplicitVariabilityEql
  input list<Equation> eql;
  input Boolean inWhen = false;
algorithm
  for eq in eql loop
    updateImplicitVariabilityEq(eq, inWhen);
  end for;
end updateImplicitVariabilityEql;

function updateImplicitVariabilityEq
  input Equation eq;
  input Boolean inWhen = false;
algorithm
  () := match eq
    local
      Expression exp;
      list<Equation> eql;
      Boolean all_params;

    case Equation.EQUALITY()
      algorithm
        if inWhen then
          markImplicitWhenExp(eq.lhs);
        end if;
      then
        ();

    case Equation.CONNECT()
      algorithm
        Expression.fold(eq.lhs, markStructuralParamsSubs, 0);
        Expression.fold(eq.rhs, markStructuralParamsSubs, 0);
      then
        ();

    case Equation.FOR()
      algorithm
        updateImplicitVariabilityEql(eq.body, inWhen);
      then
        ();

    case Equation.IF()
      algorithm
        all_params := true;

        for branch in eq.branches loop
          () := match branch
            case Equation.Branch.BRANCH()
              algorithm
                if all_params and Expression.variability(branch.condition) == Variability.PARAMETER then
                  markStructuralParamsExp(branch.condition);
                else
                  all_params := false;
                end if;

                updateImplicitVariabilityEql(branch.body, inWhen);
              then
                ();
          end match;
        end for;
      then
        ();

    case Equation.WHEN()
      algorithm
        for branch in eq.branches loop
          () := match branch
            case Equation.Branch.BRANCH()
              algorithm
                updateImplicitVariabilityEql(branch.body, inWhen = true);
              then
                ();
          end match;
        end for;
      then
        ();

    else ();
  end match;
end updateImplicitVariabilityEq;

function updateImplicitVariabilityAlg
  input Algorithm alg;
algorithm
  updateImplicitVariabilityStmts(alg.statements);
end updateImplicitVariabilityAlg;

function updateImplicitVariabilityStmts
  input list<Statement> stmtl;
  input Boolean inWhen = false;
algorithm
  for s in stmtl loop
    updateImplicitVariabilityStmt(s, inWhen);
  end for;
end updateImplicitVariabilityStmts;

function updateImplicitVariabilityStmt
  input Statement stmt;
  input Boolean inWhen;
algorithm
  () := match stmt
    case Statement.ASSIGNMENT()
      algorithm
        if inWhen then
          markImplicitWhenExp(stmt.lhs);
        end if;
      then
        ();

    case Statement.FOR()
      algorithm
        // 'when' is not allowed in 'for', so we only need to keep going if
        // we're already in a 'when'.
        if inWhen then
          updateImplicitVariabilityStmts(stmt.body, true);
        end if;
      then
        ();

    case Statement.IF()
      algorithm
        // 'when' is not allowed in 'if', so we only need to keep going if
        // we're already in a 'when.
        if inWhen then
          for branch in stmt.branches loop
            updateImplicitVariabilityStmts(Util.tuple22(branch), true);
          end for;
        end if;
      then
        ();

    case Statement.WHEN()
      algorithm
        for branch in stmt.branches loop
          updateImplicitVariabilityStmts(Util.tuple22(branch), true);
        end for;
      then
        ();

    case Statement.WHILE()
      algorithm
        // 'when' is not allowed in 'while', so we only need to keep going if
        // we're already in a 'when.
        if inWhen then
          updateImplicitVariabilityStmts(stmt.body, true);
        end if;
      then
        ();

    else ();
  end match;
end updateImplicitVariabilityStmt;

function markStructuralParamsSubs
  input Expression exp;
  input output Integer dummy;
algorithm
  () := match exp
    case Expression.CREF()
      algorithm
        ComponentRef.foldSubscripts(exp.cref, markStructuralParamsSub, 0);
      then
        ();

    else ();
  end match;
end markStructuralParamsSubs;

function markStructuralParamsSub
  input Subscript sub;
  input output Integer dummy = 0;
algorithm
  () := match sub
      case Subscript.UNTYPED() algorithm markStructuralParamsExp(sub.exp); then ();
      case Subscript.INDEX() algorithm markStructuralParamsExp(sub.index); then ();
      case Subscript.SLICE() algorithm markStructuralParamsExp(sub.slice); then ();
    else ();
  end match;
end markStructuralParamsSub;

function markImplicitWhenExp
  input Expression exp;
algorithm
  Expression.apply(exp, markImplicitWhenExp_traverser);
end markImplicitWhenExp;

function markImplicitWhenExp_traverser
  input Expression exp;
algorithm
  () := match exp
    local
      InstNode node;
      Component comp;

    case Expression.CREF(cref = ComponentRef.CREF(node = node))
      algorithm
        if InstNode.isComponent(node) then
          comp := InstNode.component(node);

          if Component.variability(comp) == Variability.CONTINUOUS then
            comp := Component.setVariability(Variability.IMPLICITLY_DISCRETE, comp);
            InstNode.updateComponent(comp, node);
          end if;
        end if;
      then
        ();

    else ();
  end match;
end markImplicitWhenExp_traverser;


annotation(__OpenModelica_Interface="frontend");
end NFInst;

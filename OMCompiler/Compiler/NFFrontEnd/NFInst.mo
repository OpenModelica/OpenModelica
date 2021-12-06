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
import AbsynUtil;
import SCode;
import DAE;

import Builtin = NFBuiltin;
import Binding = NFBinding;
import Component = NFComponent;
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import Expression = NFExpression;
import Class = NFClass;
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
import InstContext = NFInstContext;

protected
import Array;
import Error;
import FlagsUtil;
import Flatten = NFFlatten;
import InstUtil = NFInstUtil;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import Typing = NFTyping;
import ExecStat.{execStat,execStatReset};
import SCodeDump;
import SCodeUtil;
import System;
import Call = NFCall;
import Absyn.Path;
import NFClassTree.ClassTree;
import NFSections.Sections;
import NFInstNode.CachedData;
import NFInstNode.NodeTree;
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
import VerifyModel = NFVerifyModel;
import Structural = NFStructural;
import UnorderedMap;
import CheckModel = NFCheckModel;

public

function instClassInProgram
  "Instantiates a class given by its fully qualified path, with the result being
   a DAE."
  input Absyn.Path classPath;
  input SCode.Program program;
  input Boolean dumpFlat = false;
  output FlatModel flatModel;
  output FunctionTree functions;
  output String flatString "The flat model as a string if dumpFlat = true.";
protected
  InstNode top, cls, inst_cls;
  String name;
  InstContext.Type context;
  Integer var_count, eq_count;
algorithm
  // gather here all the flags to disable expansion
  // and scalarization if -d=-nfScalarize is on
  if not Flags.isSet(Flags.NF_SCALARIZE) then
    // make sure we don't expand anything
    FlagsUtil.set(Flags.NF_EXPAND_OPERATIONS, false);
    FlagsUtil.set(Flags.NF_EXPAND_FUNC_ARGS, false);
  end if;

  System.setUsesCardinality(false);
  System.setHasOverconstrainedConnectors(false);
  System.setHasStreamConnectors(false);

  context := if Flags.getConfigBool(Flags.CHECK_MODEL) or Flags.isSet(Flags.NF_API) then
    NFInstContext.RELAXED else NFInstContext.NO_CONTEXT;

  // Create a root node from the given top-level classes.
  top := makeTopNode(program);
  name := AbsynUtil.pathString(classPath);

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, NFInstContext.RELAXED,
           AbsynUtil.dummyInfo, checkAccessViolations = false);
  cls := InstNode.setNodeType(InstNodeType.ROOT_CLASS(InstNode.EMPTY_NODE()), cls);

  // Instantiate the class.
  inst_cls := instantiate(cls, context = context);
  checkPartialClass(cls, context);

  insertGeneratedInners(inst_cls, top, context);
  execStat("NFInst.instantiate(" + name + ")");

  // Instantiate expressions (i.e. anything that can contains crefs, like
  // bindings, dimensions, etc). This is done as a separate step after
  // instantiation to make sure that lookup is able to find the correct nodes.
  instExpressions(inst_cls, context = context);
  execStat("NFInst.instExpressions");

  // Mark structural parameters.
  updateImplicitVariability(inst_cls, Flags.isSet(Flags.EVAL_PARAM));
  execStat("NFInst.updateImplicitVariability");

  // Type the class.
  Typing.typeClass(inst_cls);

  // Flatten the model and evaluate constants in it.
  flatModel := Flatten.flatten(inst_cls, name);
  flatModel := EvalConstants.evaluate(flatModel);
  InstUtil.dumpFlatModelDebug("eval", flatModel);

  // Do unit checking
  flatModel := UnitCheck.checkUnits(flatModel);

  // Apply simplifications to the model.
  flatModel := SimplifyModel.simplify(flatModel);

  // Collect package constants that couldn't be substituted with their values
  // (e.g. because they where used with non-constant subscripts), and add them
  // to the model.
  flatModel := Package.collectConstants(flatModel);

  // Collect a tree of all functions that are still used in the flat model.
  functions := Flatten.collectFunctions(flatModel);

  // Dump the flat model to a string if dumpFlat = true.
  flatString := if dumpFlat then InstUtil.dumpFlatModel(flatModel, functions) else "";

  InstUtil.dumpFlatModelDebug("simplify", flatModel, functions);
  InstUtil.printStructuralParameters(flatModel);

  // Scalarize array components in the flat model.
  if Flags.isSet(Flags.NF_SCALARIZE) then
    flatModel := Scalarize.scalarize(flatModel);
  else
    // Remove empty arrays from variables
    flatModel.variables := List.filterOnFalse(flatModel.variables, Variable.isEmptyArray);
  end if;

  flatModel := InstUtil.replaceEmptyArrays(flatModel);
  InstUtil.dumpFlatModelDebug("scalarize", flatModel, functions);

  VerifyModel.verify(flatModel);
  flatModel := InstUtil.combineSubscripts(flatModel);

  //(var_count, eq_count) := CheckModel.checkModel(flatModel);
  //print(name + " has " + String(var_count) + " variable(s) and " + String(eq_count) + " equation(s).\n");
end instClassInProgram;

function instantiate
  input output InstNode node;
  input InstNode parent = InstNode.EMPTY_NODE();
  input InstContext.Type context;
  input Boolean instPartial = false "Whether to instantiate a partial class or not.";
algorithm
  node := expand(node);

  if instPartial or not InstNode.isPartial(node) or InstContext.inRelaxed(context) then
    node := instClass(node, Modifier.NOMOD(), NFComponent.DEFAULT_ATTR, true, 0, parent, context);
  end if;
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
  InstNodeType node_ty;
algorithm
  // Create a fake SCode.Element for the top scope, so we don't have to make the
  // definition in InstNode an Option only because of this node.
  cls_elem := SCode.CLASS("<top>", SCode.defaultPrefixes, SCode.NOT_ENCAPSULATED(),
    SCode.NOT_PARTIAL(), SCode.R_PACKAGE(),
    SCode.PARTS(topClasses, {}, {}, {}, {}, {}, {}, NONE()),
    SCode.COMMENT(NONE(), NONE()), AbsynUtil.dummyInfo);

  // Make an InstNode for the top scope, to use as the parent of the top level elements.
  node_ty := InstNodeType.TOP_SCOPE(UnorderedMap.new<InstNode>(System.stringHashDjb2Mod, stringEq));
  topNode := InstNode.newClass(cls_elem, InstNode.EMPTY_NODE(), node_ty);

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

  // ModelicaBuiltin has a dummy declaration of Clock to make sure no one can
  // declare another Clock class in the top scope, here we replace it with the
  // actual Clock node (which can't be defined in regular Modelica).
  ClassTree.replaceClass(NFBuiltin.CLOCK_NODE, elems);

  cls := Class.setClassTree(elems, cls);
  topNode := InstNode.updateClass(cls, topNode);
end makeTopNode;

function markBuiltinTypeNodes
  input output InstNode node;
algorithm
  if SCodeUtil.hasBooleanNamedAnnotationInClass(InstNode.definition(node), "__OpenModelica_builtin") then
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
  Error.assertion(SCodeUtil.elementIsClass(definition), getInstanceName() + " got non-class element", sourceInfo());
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
        if not SCodeUtil.isElementRedeclare(definition) then
          Error.addSourceMessage(Error.CLASS_EXTENDS_MISSING_REDECLARE,
            {SCodeUtil.elementName(definition)}, SCodeUtil.elementInfo(definition));
        end if;
      then
        Class.fromSCode(ce_cdef.elementLst, true, scope, prefs);

    // An enumeration definition, add the literals to a new scope.
    case SCode.ENUMERATION()
      algorithm
        ty := makeEnumerationType(cdef.enumLst, scope);
      then
        Class.fromEnumeration(cdef.enumLst, ty, prefs, scope);

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
    res := Restriction.fromSCode(SCodeUtil.getClassRestriction(def));
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
          {AbsynUtil.pathString(path)}, info);
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

    if SCodeUtil.isElementReplaceable(InstNode.definition(base)) then
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
        name := AbsynUtil.pathString(basePath);
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
    Modifier.NOMOD(), NFClass.DEFAULT_PREFIXES, Restriction.EXTERNAL_OBJECT());
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
            if InstNode.name(ext) <> "ExternalObject" and
               ClassTree.recursiveElementCount(Class.classTree(InstNode.getClass(ext))) <> 0 then
              InstNode.CLASS_NODE(nodeType = InstNodeType.BASE_CLASS(definition =
                SCode.EXTENDS(baseClassPath = base_path))) := ext;
              Error.addSourceMessage(Error.EXTERNAL_OBJECT_INVALID_ELEMENT,
                {InstNode.name(node), "extends " + AbsynUtil.pathString(base_path)}, InstNode.info(ext));
              fail();
            end if;
          end for;
        end if;

        // An external object must have exactly two functions called constructor and
        // destructor.
        for cls in tree.classes loop
          () := match InstNode.name(cls)
            case "constructor" guard SCodeUtil.isFunction(InstNode.definition(cls))
              algorithm
                constructor := cls;
              then
                ();

            case "destructor" guard SCodeUtil.isFunction(InstNode.definition(cls))
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
  ext_node :: _ := Lookup.lookupBaseClassName(AbsynUtil.typeSpecPath(ty), InstNode.parent(node), info);

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

  // A short class definition deriving from a partial class is itself partial.
  if not Class.Prefixes.isPartial(prefs) and InstNode.isPartial(ext_node) then
    prefs.partialPrefix := SCode.Partial.PARTIAL();
  end if;

  attrs := instDerivedAttributes(sattrs);
  dims := list(Dimension.RAW_DIM(d, InstNode.parent(node)) for d in AbsynUtil.typeSpecDimensions(ty));
  mod := Class.getModifier(cls);

  res := Restriction.fromSCode(SCodeUtil.getClassRestriction(element));
  cls := Class.EXPANDED_DERIVED(ext_node, mod, listArray(dims), prefs, attrs, res);
  node := InstNode.updateClass(cls, node);
end expandClassDerived;

function instDerivedAttributes
  input SCode.Attributes scodeAttr;
  output Component.Attributes attributes;
protected
  ConnectorType.Type cty;
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
        cty := ConnectorType.fromSCode(scodeAttr.connectorType);
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
  input Integer instLevel;
  input InstNode parent = InstNode.EMPTY_NODE();
  input InstContext.Type context;
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

  (attributes, node) := instClassDef(cls, modifier, attributes, useBinding, node, parent, instLevel, context);
end instClass;

function instClassDef
  input Class cls;
  input Modifier outerMod;
  input output Component.Attributes attributes;
  input Boolean useBinding;
  input output InstNode node;
  input InstNode parent;
  input Integer instLevel;
  input InstContext.Type context;
protected
  InstNode par, base_node;
  Class inst_cls;
  ClassTree cls_tree;
  Modifier mod, outer_mod;
  Restriction res;
  Type ty;
  Component.Attributes attrs;
  SCode.Element elem;
algorithm
  () := match cls
    case Class.EXPANDED_CLASS(restriction = res)
      algorithm
        // Skip instantiating the class tree if the class is a base class,
        // it has (hopefully) already been instantiated in that case.
        if InstNode.isBaseClass(node) then
          par := parent;
        else
          (node, par) := ClassTree.instantiate(node, parent);
        end if;

        updateComponentType(parent, node);
        attributes := updateClassConnectorType(res, attributes);
        inst_cls as Class.EXPANDED_CLASS(elements = cls_tree) := InstNode.getClass(node);

        // Fetch modification on the class definition (for class extends).
        mod := instElementModifier(InstNode.definition(node), node, par);
        mod := Modifier.propagate(mod, node, par);
        // Merge with any outer modifications.
        outer_mod := Modifier.propagate(cls.modifier, node, par);
        outer_mod := Modifier.merge(outerMod, outer_mod);
        mod := Modifier.merge(outer_mod, mod);

        // Apply the modifiers of extends nodes.
        ClassTree.mapExtends(cls_tree, function modifyExtends(scope = par));

        // Apply the modifiers of this scope.
        applyModifier(mod, cls_tree, InstNode.name(node));

        // Apply element redeclares.
        ClassTree.mapRedeclareChains(cls_tree,
          function redeclareElements(instLevel = instLevel, context = context));

        // Redeclare classes with redeclare modifiers. Redeclared components could
        // also be handled here, but since each component is only instantiated once
        // it's more efficient to apply the redeclare when instantiating them instead.
        redeclareClasses(cls_tree, par);

        // Instantiate the extends nodes.
        ClassTree.mapExtends(cls_tree,
          function instExtends(attributes = attributes, useBinding = useBinding,
                               visibility = ExtendsVisibility.PUBLIC,
                               instLevel = instLevel + 1, context = context));

        // Instantiate local components.
        ClassTree.applyLocalComponents(cls_tree,
          function instComponent(attributes = attributes, innerMod = Modifier.NOMOD(),
                                 originalAttr = NONE(), useBinding = useBinding,
                                 instLevel = instLevel + 1, context = context));

        // Remove duplicate elements.
        cls_tree := ClassTree.replaceDuplicates(cls_tree);
        ClassTree.checkDuplicates(cls_tree);
        InstNode.updateClass(Class.setClassTree(cls_tree, inst_cls), node);
      then
        ();

    case Class.EXPANDED_DERIVED()
      algorithm
        (node, par) := ClassTree.instantiate(node, parent);
        node := InstNode.setNodeType(InstNodeType.DERIVED_CLASS(InstNode.nodeType(node)), node);
        Class.EXPANDED_DERIVED(baseClass = base_node) := InstNode.getClass(node);

        // Merge outer modifiers and attributes.
        mod := instElementModifier(InstNode.definition(node), node, InstNode.rootParent(node));
        mod := Modifier.propagate(mod, node, par);
        outer_mod := Modifier.propagate(cls.modifier, node, par);
        outer_mod := Modifier.merge(outerMod, outer_mod);
        mod := Modifier.merge(outer_mod, mod);
        attrs := updateClassConnectorType(cls.restriction, cls.attributes);
        attributes := mergeDerivedAttributes(attrs, attributes, parent);

        // Instantiate the base class and update the nodes.
        (base_node, attributes) := instClass(base_node, mod, attributes, useBinding, instLevel, par, context);
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
        instExternalObjectStructors(cls.ty, parent, context);
      then
        ();

    case Class.PARTIAL_BUILTIN(ty = ty, restriction = res)
      algorithm
        (node, par) := ClassTree.instantiate(node, parent);
        updateComponentType(parent, node);
        cls_tree := Class.classTree(InstNode.getClass(node));

        mod := instElementModifier(InstNode.definition(node), node, InstNode.parent(node));
        outer_mod := Modifier.merge(outerMod, cls.modifier);
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
        node := InstNode.setNodeType(InstNodeType.NORMAL_CLASS(), node);
        node := expand(node);
        node := instClass(node, outerMod, attributes, useBinding, instLevel, parent, context);
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

function updateClassConnectorType
  input Restriction res;
  input output Component.Attributes attrs;
algorithm
  if Restriction.isExpandableConnector(res) then
    attrs.connectorType := ConnectorType.setExpandable(attrs.connectorType);
  elseif Restriction.isConnector(res) then
    attrs.connectorType := ConnectorType.setConnector(attrs.connectorType);
  end if;
end updateClassConnectorType;

function instExternalObjectStructors
  "Instantiates the constructor and destructor for an ExternalObject class."
  input Type ty;
  input InstNode parent;
  input InstContext.Type context;
protected
  InstNode constructor, destructor, par;
  SourceInfo info;
algorithm
  // The constructor and destructor have function parameters that are instances
  // of the external object class, and we instantiate the structors when we
  // instantiate such instances. To break that loop we check that we're not
  // inside the external object class before instantiating the structors.
  par := InstNode.parent(InstNode.parent(parent));

  if not (InstNode.isClass(par) and Class.isExternalObject(InstNode.getClass(par))) then
    Type.COMPLEX(complexTy = ComplexType.EXTERNAL_OBJECT(constructor, destructor)) := ty;
    info := InstNode.info(parent);
    Function.instFunctionNode(constructor, context, info);
    Function.instFunctionNode(destructor, context, info);
  end if;
end instExternalObjectStructors;

function instPackage
  "This function instantiates a package given a package node. If the package has
   already been instantiated, then the cached instance from the node is
   returned. Otherwise the node is fully instantiated, the instance is added to
   the node's cache, and the instantiated node is returned."
  input output InstNode node;
  input InstContext.Type context;
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
        inst := instantiate(node, context = context);

        // Cache the instantiated node and instantiate expressions in it too.
        if not InstNode.isPartial(inst) or InstContext.inRelaxed(context) then
          InstNode.setPackageCache(node, CachedData.PACKAGE(inst));
          instExpressions(inst, context = context);
        end if;
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
  ext_mod := Modifier.fromElement(elem, scope);
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
              {AbsynUtil.pathString(elem.baseClassPath)},
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
  input Integer instLevel;
  input InstContext.Type context;
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
          function instExtends(attributes = attributes, useBinding = useBinding,
                               visibility = vis, instLevel = instLevel, context = context));

        ClassTree.applyLocalComponents(cls_tree,
          function instComponent(attributes = attributes, innerMod = Modifier.NOMOD(),
            originalAttr = NONE(), useBinding = useBinding, instLevel = instLevel, context = context));
      then
        ();

    case Class.EXPANDED_DERIVED()
      algorithm
        if vis == ExtendsVisibility.PUBLIC and InstNode.isProtectedBaseClass(node) then
          vis := ExtendsVisibility.DERIVED_PROTECTED;
        end if;

        cls.baseClass := instExtends(cls.baseClass, attributes, useBinding, vis, instLevel, context);
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
  input InstNode parent;
protected
  InstNode cls_node, redecl_node;
  Class cls;
  Modifier mod, cc_mod;
algorithm
  () := match tree
    case ClassTree.INSTANTIATED_TREE()
      algorithm
        for cls_ptr in tree.classes loop
          cls_node := Mutable.access(cls_ptr);
          cls := InstNode.getClass(InstNode.resolveOuter(cls_node));
          mod := Class.getModifier(cls);

          if Modifier.isRedeclare(mod) then
            Modifier.REDECLARE(element = redecl_node, outerMod = mod, constrainingMod = cc_mod) := mod;
            cc_mod := getConstrainingMod(InstNode.definition(cls_node), parent, cc_mod);
            cls_node := redeclareClass(redecl_node, cls_node, mod, cc_mod);
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
  input Integer instLevel;
  input InstContext.Type context;
protected
  InstNode node;
  Mutable<InstNode> node_ptr;
algorithm
  node := Mutable.access(listHead(chain));
  node_ptr := listHead(chain);

  if InstNode.isClass(node) then
    for cls_ptr in listRest(chain) loop
      node_ptr := redeclareClassElement(cls_ptr, node_ptr);
    end for;
    node := Mutable.access(node_ptr);
  else
    for comp_ptr in listRest(chain) loop
      node_ptr := redeclareComponentElement(comp_ptr, node_ptr, instLevel, context);
    end for;
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
  rdcl_node := redeclareClass(rdcl_node, repl_node, Modifier.NOMOD(), Modifier.NOMOD());
  outCls := Mutable.create(rdcl_node);
end redeclareClassElement;

function redeclareComponentElement
  input Mutable<InstNode> redeclareComp;
  input Mutable<InstNode> replaceableComp;
  input Integer instLevel;
  input InstContext.Type context;
  output Mutable<InstNode> outComp;
protected
  InstNode rdcl_node, repl_node;
algorithm
  rdcl_node := Mutable.access(redeclareComp);
  repl_node := Mutable.access(replaceableComp);
  instComponent(repl_node, NFComponent.DEFAULT_ATTR, Modifier.NOMOD(), true, instLevel, NONE(), context);
  redeclareComponent(rdcl_node, repl_node, Modifier.NOMOD(), Modifier.NOMOD(), NFComponent.DEFAULT_ATTR, rdcl_node, instLevel, context);
  outComp := Mutable.create(rdcl_node);
end redeclareComponentElement;

function redeclareClass
  input InstNode redeclareNode;
  input InstNode originalNode;
  input Modifier outerMod;
  input Modifier constrainingMod;
  output InstNode redeclaredNode;
protected
  InstNode orig_node;
  Class orig_cls, rdcl_cls, new_cls;
  Class.Prefixes prefs;
  InstNodeType node_ty;
  Modifier mod;
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

  mod := Class.getModifier(rdcl_cls);
  mod := Modifier.merge(mod, constrainingMod);
  mod := Modifier.merge(outerMod, mod);

  prefs := mergeRedeclaredClassPrefixes(Class.getPrefixes(orig_cls),
    Class.getPrefixes(rdcl_cls), redeclareNode);

  if SCodeUtil.isClassExtends(InstNode.definition(redeclareNode)) then
    orig_node := expand(originalNode);
    orig_cls := InstNode.getClass(orig_node);

    new_cls := match (orig_cls, rdcl_cls)
      // Class extends of a builtin type. Not very useful, but technically allowed
      // if the redeclaring class is empty.
      case (_, Class.PARTIAL_CLASS()) guard Class.isBuiltin(orig_cls)
        algorithm
          if not SCodeUtil.isEmptyClassDef(SCodeUtil.getClassDef(InstNode.definition(redeclareNode))) then
            // Class extends of a builtin type is only allowed if the extending class is empty,
            // otherwise it violates the rules of extending a builtin type.
            Error.addSourceMessage(Error.BUILTIN_EXTENDS_INVALID_ELEMENTS,
            {InstNode.name(redeclareNode)}, InstNode.info(redeclareNode));
            fail();
          end if;
        then
          Class.setPrefixes(prefs, orig_cls);

      // Class extends of a normal class.
      case (_, Class.PARTIAL_CLASS())
        algorithm
          node_ty := InstNodeType.BASE_CLASS(InstNode.parent(orig_node), InstNode.definition(orig_node));
          orig_node := InstNode.setNodeType(node_ty, orig_node);
          rdcl_cls.elements := ClassTree.setClassExtends(orig_node, rdcl_cls.elements);
          rdcl_cls.modifier := mod;
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
    new_cls := match (orig_cls, rdcl_cls)
      case (Class.PARTIAL_BUILTIN(), _)
        then redeclareEnum(rdcl_cls, orig_cls, prefs, mod, redeclareNode, originalNode);

      case (_, Class.PARTIAL_CLASS())
        algorithm
          rdcl_cls.prefixes := prefs;
          rdcl_cls.modifier := mod;
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
  node_ty := InstNodeType.REDECLARED_CLASS(InstNode.parent(originalNode), InstNode.nodeType(originalNode));
  redeclaredNode := InstNode.setNodeType(node_ty, redeclaredNode);
end redeclareClass;

function redeclareEnum
  input Class redeclareClass;
  input Class originalClass;
  input Class.Prefixes prefixes;
  input Modifier outerMod;
  input InstNode redeclareNode;
  input InstNode originalNode;
  output Class redeclaredClass = redeclareClass;
algorithm
  redeclaredClass := match (redeclaredClass, originalClass)
    local
      list<String> lits1, lits2;

    case (Class.PARTIAL_BUILTIN(ty = Type.ENUMERATION(literals = lits1)),
          Class.PARTIAL_BUILTIN(ty = Type.ENUMERATION(literals = lits2)))
      algorithm
        if not (listEmpty(lits2) or List.isEqualOnTrue(lits1, lits2, stringEq)) then
          Error.addMultiSourceMessage(Error.REDECLARE_ENUM_NON_SUBTYPE,
            {InstNode.name(originalNode)}, {InstNode.info(redeclareNode), InstNode.info(originalNode)});
          fail();
        end if;

        redeclaredClass.prefixes := prefixes;
        redeclaredClass.modifier := Modifier.merge(outerMod, redeclaredClass.modifier);
      then
        redeclaredClass;

    else
      algorithm
        Error.addMultiSourceMessage(Error.REDECLARE_CLASS_NON_SUBTYPE,
          {Restriction.toString(Class.restriction(originalClass)), InstNode.name(originalNode)},
          {InstNode.info(redeclareNode), InstNode.info(originalNode)});
      then
        fail();

  end match;
end redeclareEnum;

function instComponent
  input InstNode node   "The component node to instantiate";
  input Component.Attributes attributes "Attributes to be propagated to the component.";
  input Modifier innerMod;
  input Boolean useBinding "Ignore the component's binding if false.";
  input Integer instLevel;
  input Option<Component.Attributes> originalAttr = NONE();
  input InstContext.Type context;
protected
  Component comp;
  SCode.Element def;
  InstNode comp_node, rdcl_node;
  Modifier outer_mod, inner_mod, cc_mod = innerMod, cc_def_mod;
  SCode.Mod cc_smod;
  String name;
  InstNode parent;
  InstContext.Type next_context;
algorithm
  comp_node := InstNode.resolveOuter(node);
  comp := InstNode.component(comp_node);
  parent := InstNode.parent(comp_node);

  // Skip already instantiated components.
  if not Component.isDefinition(comp) then
    // An already instantiated component might be due to an instantiation loop, check it.
    checkRecursiveDefinition(Component.classInstance(comp), comp_node, limitReached = false);
    return;
  end if;

  Component.COMPONENT_DEF(definition = def, modifier = outer_mod) := comp;

  if Modifier.isRedeclare(outer_mod) then
    checkOuterComponentMod(outer_mod, def, comp_node);

    Modifier.REDECLARE(element = rdcl_node, innerMod = inner_mod,
      outerMod = outer_mod, constrainingMod = cc_mod) := outer_mod;

    next_context := InstContext.set(context, NFInstContext.REDECLARED);
    instComponentDef(def, Modifier.NOMOD(), inner_mod, NFComponent.DEFAULT_ATTR,
      useBinding, comp_node, parent, instLevel, originalAttr, next_context);

    cc_mod := getConstrainingMod(def, parent, cc_mod);
    cc_mod := Modifier.merge(cc_mod, innerMod);

    outer_mod := Modifier.merge(InstNode.getModifier(rdcl_node), outer_mod);
    InstNode.setModifier(outer_mod, rdcl_node);
    redeclareComponent(rdcl_node, node, Modifier.NOMOD(), cc_mod, attributes, node, instLevel, context);
  else
    instComponentDef(def, outer_mod, innerMod, attributes, useBinding, comp_node, parent, instLevel, originalAttr, context);
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
  input Integer instLevel;
  input Option<Component.Attributes> originalAttr = NONE();
  input InstContext.Type context;
algorithm
  () := match component
    local
      SourceInfo info;
      Modifier decl_mod, mod, cc_mod;
      list<Dimension> dims, ty_dims;
      Binding binding, condition;
      Component.Attributes attr, ty_attr;
      Component inst_comp;
      InstNode ty_node;
      Class ty;
      Boolean in_function;
      Restriction parent_res, res;

    case SCode.COMPONENT(info = info)
      algorithm
        mod := instElementModifier(component, node, parent);
        mod := Modifier.merge(mod, innerMod);
        mod := Modifier.merge(outerMod, mod);
        checkOuterComponentMod(mod, component, node);

        dims := list(Dimension.RAW_DIM(d, parent) for d in component.attributes.arrayDims);
        binding := if useBinding then Modifier.binding(mod) else NFBinding.EMPTY_BINDING;
        condition := Binding.fromAbsyn(component.condition, false, false, parent, info);

        // Instantiate the component's attributes, and merge them with the
        // attributes of the component's parent (e.g. constant SomeComplexClass c).
        parent_res := Class.restriction(InstNode.getClass(parent));
        attr := instComponentAttributes(component.attributes, component.prefixes);
        attr := checkDeclaredComponentAttributes(attr, parent_res, node);
        attr := mergeComponentAttributes(attributes, attr, node, parent_res);

        if isSome(originalAttr) then
          attr := mergeRedeclaredComponentAttributes(Util.getOption(originalAttr), attr, node);
        end if;

        if not attr.isFinal and Modifier.isFinal(mod) then
          attr.isFinal := true;
        end if;

        // Create the untyped component and update the node with it. We need the
        // untyped component in instClass to make sure everything is scoped
        // correctly during lookup, but the class node the component should have
        // is created by instClass. To break the circle we leave the class node
        // empty here, and let instClass set it for us instead.
        inst_comp := Component.UNTYPED_COMPONENT(InstNode.EMPTY_NODE(), listArray(dims),
          binding, condition, attr, SOME(component.comment), false, info);
        InstNode.updateComponent(inst_comp, node);

        // Instantiate the type of the component.
        mod := Modifier.propagate(mod, node, node);
        (ty_node, ty_attr) := instTypeSpec(component.typeSpec, mod, attr,
          useBinding and not Binding.isBound(binding), parent, node, info, instLevel, context);
        ty := InstNode.getClass(ty_node);
        res := Class.restriction(ty);

        if not InstContext.inRedeclared(context) then
          checkPartialComponent(node, attr, ty_node, Class.isPartial(ty), res, context, info);
        end if;

        // Update the component's variability based on its type (e.g. Integer is discrete).
        ty_attr := updateComponentVariability(ty_attr, ty, ty_node);
        // Update the component's connector type now that we have its type.
        ty_attr := updateComponentConnectorType(ty_attr, res, context, node);

        if not referenceEq(attr, ty_attr) then
          InstNode.componentApply(node, Component.setAttributes, ty_attr);
        end if;
      then
        ();
  end match;
end instComponentDef;

function instElementModifier
  input SCode.Element element;
  input InstNode component;
  input InstNode parent;
  output Modifier mod;
protected
  Modifier cc_mod;
algorithm
  mod := Modifier.fromElement(element, parent);

  if InstNode.isRedeclared(component) then
    mod := propagateRedeclaredMod(mod, component);
  else
    cc_mod := instConstrainingMod(element, parent);
    mod := Modifier.merge(mod, cc_mod);
  end if;
end instElementModifier;

function instConstrainingMod
  input SCode.Element element;
  input InstNode parent;
  output Modifier ccMod;
algorithm
  ccMod := match element
    local
      SCode.Mod smod;

    case SCode.Element.CLASS(prefixes = SCode.Prefixes.PREFIXES(replaceablePrefix =
        SCode.Replaceable.REPLACEABLE(cc = SOME(SCode.ConstrainClass.CONSTRAINCLASS(modifier = smod)))))
      then Modifier.create(smod, element.name, ModifierScope.CLASS(element.name), parent);

    case SCode.Element.COMPONENT(prefixes = SCode.Prefixes.PREFIXES(replaceablePrefix =
        SCode.Replaceable.REPLACEABLE(cc = SOME(SCode.ConstrainClass.CONSTRAINCLASS(modifier = smod)))))
      then Modifier.create(smod, element.name, ModifierScope.COMPONENT(element.name), parent);

    else Modifier.NOMOD();
  end match;
end instConstrainingMod;

function getConstrainingMod
  input SCode.Element element;
  input InstNode parent;
  input Modifier outerMod;
  output Modifier ccMod;
protected
  String name;
  SCode.Mod cc_smod;
  ModifierScope mod_scope;
algorithm
  cc_smod := SCodeUtil.getConstrainingMod(element);

  if not SCodeUtil.isEmptyMod(cc_smod) then
    name := SCodeUtil.elementName(element);
    ccMod := Modifier.create(cc_smod, name, ModifierScope.fromElement(element), parent);
    ccMod := Modifier.merge(outerMod, ccMod);
  else
    ccMod := outerMod;
  end if;
end getConstrainingMod;

function propagateRedeclaredMod
  input Modifier mod;
  input InstNode component;
  output Modifier outMod;
protected
  InstNode parent;
algorithm
  outMod := match component
    case InstNode.COMPONENT_NODE(nodeType = InstNodeType.REDECLARED_COMP(parent = parent))
      algorithm
        parent := InstNode.getDerivedNode(parent);
        outMod := propagateRedeclaredMod(mod, parent);
      then
        Modifier.propagateBinding(outMod, parent, parent);

    else mod;
  end match;
end propagateRedeclaredMod;

function updateComponentConnectorType
  input output Component.Attributes attributes;
  input Restriction restriction;
  input InstContext.Type context;
  input InstNode component;
protected
  ConnectorType.Type cty = attributes.connectorType;
algorithm
  if ConnectorType.isConnectorType(cty) then
    if Restriction.isConnector(restriction) then
      if Restriction.isExpandableConnector(restriction) then
        cty := ConnectorType.setPresent(cty);
      else
        cty := intBitAnd(cty, intBitNot(ConnectorType.EXPANDABLE));
      end if;
    else
      // The connector type might have the connector or expandable bits set
      // because of a parent node, but they should be unset if the component
      // itself isn't a connector.
      cty := intBitAnd(cty,
        intBitNot(intBitOr(ConnectorType.CONNECTOR, ConnectorType.EXPANDABLE)));
    end if;

    // Connector elements that are not flow/stream are potentials.
    if not ConnectorType.isFlowOrStream(cty) then
      cty := ConnectorType.setPotential(cty);
    end if;

    if cty <> attributes.connectorType then
      attributes.connectorType := cty;
    end if;
  elseif ConnectorType.isFlowOrStream(cty) and not InstContext.inRedeclared(context) then
    // The Modelica specification forbids using stream outside connector
    // declarations, but has no such restriction for flow. To compromise we
    // print a warning for both flow and stream.
    Error.addStrictMessage(Error.CONNECTOR_PREFIX_OUTSIDE_CONNECTOR,
      {ConnectorType.toString(cty)}, InstNode.info(component));

    // Remove the erroneous flow/stream prefix and keep going.
    attributes.connectorType := ConnectorType.unsetFlowStream(cty);
  end if;
end updateComponentConnectorType;

function checkPartialComponent
  input InstNode compNode;
  input Component.Attributes compAttr;
  input InstNode clsNode;
  input Boolean isPartial;
  input Restriction res;
  input InstContext.Type context;
  input SourceInfo info;
algorithm
  if Restriction.isFunction(res) then
    if not isPartial and not InstContext.inRelaxed(context) then
      // The type of a function pointer must be a partial function.
      Error.addSourceMessage(Error.META_FUNCTION_TYPE_NO_PARTIAL_PREFIX,
        {AbsynUtil.pathString(InstNode.scopePath(clsNode))}, info);
      fail();
    end if;
  elseif isPartial and compAttr.innerOuter <> InnerOuter.OUTER and not InstContext.inRelaxed(context) then
    // The type of a component may not be a partial class.
    Error.addMultiSourceMessage(Error.PARTIAL_COMPONENT_TYPE,
      {AbsynUtil.pathString(InstNode.scopePath(compNode)), InstNode.name(clsNode)},
      {InstNode.info(clsNode), info});
    fail();
  end if;
end checkPartialComponent;

function redeclareComponent
  input InstNode redeclareNode;
  input InstNode originalNode;
  input Modifier outerMod;
  input Modifier constrainingMod;
  input Component.Attributes outerAttr;
  input InstNode redeclaredNode;
  input Integer instLevel;
  input InstContext.Type context;
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

  orig_comp := InstNode.component(originalNode);
  rdcl_type := InstNodeType.REDECLARED_COMP(InstNode.parent(originalNode));
  rdcl_node := InstNode.setNodeType(rdcl_type, redeclareNode);
  rdcl_node := InstNode.copyInstancePtr(originalNode, rdcl_node);
  rdcl_node := InstNode.updateComponent(InstNode.component(redeclareNode), rdcl_node);
  instComponent(rdcl_node, outerAttr, constrainingMod, true, instLevel, SOME(Component.getAttributes(orig_comp)), context);
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
        attr := rdcl_comp.attributes;

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
     AbsynUtil.isOnlyOuter(SCodeUtil.prefixesInnerOuter(SCodeUtil.elementPrefixes(component))) then
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
  ConnectorType.Type cty;
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
        cty := ConnectorType.fromSCode(compAttr.connectorType);
        par := Prefixes.parallelismFromSCode(compAttr.parallelism);
        var := Prefixes.variabilityFromSCode(compAttr.variability);
        dir := Prefixes.directionFromSCode(compAttr.direction);
        io  := Prefixes.innerOuterFromSCode(compPrefs.innerOuter);
        fin := SCodeUtil.finalBool(compPrefs.finalPrefix);
        redecl := SCodeUtil.redeclareBool(compPrefs.redeclarePrefix);
        repl := Replaceable.NOT_REPLACEABLE();
      then
        Component.Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl);
  end match;
end instComponentAttributes;

function mergeComponentAttributes
  input Component.Attributes outerAttr;
  input Component.Attributes innerAttr;
  input InstNode node;
  input Restriction parentRestriction;
  output Component.Attributes attr;
protected
  ConnectorType.Type cty;
  Parallelism par;
  Variability var;
  Direction dir;
  Boolean fin, redecl;
  Replaceable repl;
algorithm
  if referenceEq(outerAttr, NFComponent.DEFAULT_ATTR) and innerAttr.connectorType == 0 then
    attr := innerAttr;
  elseif referenceEq(innerAttr, NFComponent.DEFAULT_ATTR) then
    cty := ConnectorType.merge(outerAttr.connectorType, innerAttr.connectorType, node);
    attr := Component.Attributes.ATTRIBUTES(cty, outerAttr.parallelism,
      outerAttr.variability, outerAttr.direction, innerAttr.innerOuter, outerAttr.isFinal,
      innerAttr.isRedeclare, innerAttr.isReplaceable);
  else
    cty := ConnectorType.merge(outerAttr.connectorType, innerAttr.connectorType, node);
    par := Prefixes.mergeParallelism(outerAttr.parallelism, innerAttr.parallelism, node);
    var := Prefixes.variabilityMin(outerAttr.variability, innerAttr.variability);

    if Restriction.isFunction(parentRestriction) then
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

function checkDeclaredComponentAttributes
  input output Component.Attributes attr;
  input Restriction parentRestriction;
  input InstNode component;
algorithm
  () := match parentRestriction
    case Restriction.CONNECTOR()
      algorithm
        // Components of a connector may not have prefixes 'inner' or 'outer'.
        assertNotInnerOuter(attr.innerOuter, component, parentRestriction);

        if parentRestriction.isExpandable then
          // Components of an expandable connector may not have the prefix 'flow'.
          assertNotFlowStream(attr.connectorType, component, parentRestriction);

          // Mark components in expandable connectors as potentially present.
          attr.connectorType := intBitOr(attr.connectorType, ConnectorType.POTENTIALLY_PRESENT);
        end if;
      then
        ();

    case Restriction.RECORD()
      algorithm
        // Elements of a record may not have prefixes 'input', 'output', 'inner', 'outer', 'stream', or 'flow'.
        assertNotInputOutput(attr.direction, component, parentRestriction);
        assertNotInnerOuter(attr.innerOuter, component, parentRestriction);
        assertNotFlowStream(attr.connectorType, component, parentRestriction);
      then
        ();

    else ();
  end match;
end checkDeclaredComponentAttributes;

function invalidComponentPrefixError
  input String prefix;
  input InstNode node;
  input Restriction restriction;
algorithm
  Error.addSourceMessage(Error.INVALID_COMPONENT_PREFIX,
    {prefix, InstNode.name(node), Restriction.toString(restriction)}, InstNode.info(node));
end invalidComponentPrefixError;

function assertNotInputOutput
  input Direction dir;
  input InstNode node;
  input Restriction restriction;
algorithm
  if dir <> Direction.NONE then
    invalidComponentPrefixError(Prefixes.directionString(dir), node, restriction);
    fail();
  end if;
end assertNotInputOutput;

function assertNotInnerOuter
  input InnerOuter io;
  input InstNode node;
  input Restriction restriction;
algorithm
  if io <> InnerOuter.NOT_INNER_OUTER then
    invalidComponentPrefixError(Prefixes.innerOuterString(io), node, restriction);
    fail();
  end if;
end assertNotInnerOuter;

function assertNotFlowStream
  input ConnectorType.Type cty;
  input InstNode node;
  input Restriction restriction;
algorithm
  if ConnectorType.isFlowOrStream(cty) then
    invalidComponentPrefixError(ConnectorType.toString(cty), node, restriction);
    fail();
  end if;
end assertNotFlowStream;

function mergeDerivedAttributes
  input Component.Attributes outerAttr;
  input Component.Attributes innerAttr;
  input InstNode node;
  output Component.Attributes attr;
protected
  ConnectorType.Type cty;
  Parallelism par;
  Variability var;
  Direction dir;
  InnerOuter io;
  Boolean fin, redecl;
  Replaceable repl;
algorithm
  if referenceEq(innerAttr, NFComponent.DEFAULT_ATTR) and outerAttr.connectorType == 0 then
    attr := outerAttr;
  elseif referenceEq(outerAttr, NFComponent.DEFAULT_ATTR) and innerAttr.connectorType == 0 then
    attr := innerAttr;
  else
    Component.Attributes.ATTRIBUTES(cty, par, var, dir, io, fin, redecl, repl) := outerAttr;
    cty := ConnectorType.merge(cty, innerAttr.connectorType, node, isClass = true);
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
  ConnectorType.Type cty, rcty, cty_fs, rcty_fs;
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

    rcty_fs := intBitAnd(rcty, ConnectorType.FLOW_STREAM_MASK);
    cty_fs := intBitAnd(cty, ConnectorType.FLOW_STREAM_MASK);
    if rcty_fs > 0 then
      if cty_fs > 0 and rcty_fs <> cty_fs then
        printRedeclarePrefixError(node, ConnectorType.toString(rcty), ConnectorType.toString(cty));
      end if;
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

    attr := Component.Attributes.ATTRIBUTES(rcty, par, var, dir, io, fin, redecl, repl);
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
  if referenceEq(attr, NFComponent.DEFAULT_ATTR) and isDiscreteClass(clsNode) then
    attr := NFComponent.IMPL_DISCRETE_ATTR;
  elseif var == Variability.CONTINUOUS and isDiscreteClass(clsNode) then
    attr.variability := Variability.IMPLICITLY_DISCRETE;
  end if;
end updateComponentVariability;

function isDiscreteClass
  input InstNode clsNode;
  output Boolean isDiscrete;
protected
  InstNode base_node;
  Class cls;
  array<InstNode> exts;
algorithm
  base_node := Class.lastBaseClass(clsNode);
  cls := InstNode.getClass(base_node);

  isDiscrete := match cls
    case Class.EXPANDED_CLASS(restriction = Restriction.TYPE())
      algorithm
        exts := ClassTree.getExtends(cls.elements);
      then
        if arrayLength(exts) == 1 then isDiscreteClass(exts[1]) else false;

    else Type.isDiscrete(Class.getType(cls, base_node));
  end match;
end isDiscreteClass;

function instTypeSpec
  input Absyn.TypeSpec typeSpec;
  input Modifier modifier;
  input Component.Attributes attributes;
  input Boolean useBinding;
  input InstNode scope;
  input InstNode parent;
  input SourceInfo info;
  input Integer instLevel;
  input InstContext.Type context;
  output InstNode node;
  output Component.Attributes outAttributes;
algorithm
  node := match typeSpec
    case Absyn.TPATH()
      algorithm
        node := Lookup.lookupClassName(typeSpec.path, scope, context, info);

        if instLevel >= 100 then
          checkRecursiveDefinition(node, parent, limitReached = true);
        end if;

        node := expand(node);
        (node, outAttributes) := instClass(node, modifier, attributes, useBinding, instLevel, parent, context);
      then
        node;

    case Absyn.TCOMPLEX()
      algorithm
        print("NFInst.instTypeSpec: TCOMPLEX not implemented.\n");
      then
        fail();

  end match;
end instTypeSpec;

function checkRecursiveDefinition
  "Prints an error if a component causes a loop in the instance tree, for
   example because it has the same type as one of its parents. If the depth
   limit of the instance tree is reached, indicated by limitReached = true, then
   some error is always given. Otherwise an error is only given if an actual
   issue can be detected."
  input InstNode componentType;
  input InstNode component;
  input Boolean limitReached;
protected
  InstNode parent = InstNode.parent(component);
  InstNode parent_type;
algorithm
  // Functions can contain instances of a parent, e.g. in equalityConstraint
  // functions, so skip this check for functions.
  if not Class.isFunction(InstNode.getClass(parent)) then
    // Check whether any parent of the component has the same type as the component.
    while not InstNode.isEmpty(parent) loop
      parent_type := InstNode.classScope(parent);

      // Check equality by comparing the definitions, because comparing the
      // nodes or instances in the nodes is unreliable due to instantiation
      // creating new nodes.
      if referenceEq(InstNode.definition(componentType), InstNode.definition(parent_type)) then
        Error.addSourceMessage(Error.RECURSIVE_DEFINITION,
          {InstNode.name(component), InstNode.name(InstNode.classScope(InstNode.parent(component)))},
          InstNode.info(component));
        fail();
      end if;

      parent := InstNode.parent(parent);
    end while;
  end if;

  if limitReached then
    // If we couldn't determine the exact cause of the recursion, print a generic error.
    Error.addSourceMessage(Error.INST_RECURSION_LIMIT_REACHED,
      {AbsynUtil.pathString(InstNode.scopePath(component))}, InstNode.info(component));
    fail();
  end if;
end checkRecursiveDefinition;

function instDimension
  input output Dimension dimension;
  input InstContext.Type context;
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
              exp := instExp(dim.subscript, dimension.scope, context, info);
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
  input InstContext.Type context;
protected
  Class cls = InstNode.getClass(node), inst_cls;
  array<InstNode> local_comps, exts;
  ClassTree cls_tree;
  Restriction res;
  array<Dimension> dims;
  SourceInfo info;
  Type ty;
  InstContext.Type next_context;
algorithm
  () := match cls
    // Long class declaration of a type.
    case Class.EXPANDED_CLASS(elements = cls_tree, restriction = Restriction.TYPE())
      algorithm
        // Instantiate expressions in the extends nodes.
        exts := ClassTree.getExtends(cls_tree);
        for ext in exts loop
          instExpressions(ext, ext, sections, context);
        end for;

        // A type must extend a basic type.
        if arrayLength(exts) == 1 then
          ty := Type.COMPLEX(node, ComplexType.EXTENDS_TYPE(exts[1]));
        elseif SCodeUtil.hasBooleanNamedAnnotationInClass(InstNode.definition(node), "__OpenModelica_builtinType") then
          ty := Type.COMPLEX(node, ComplexType.CLASS());
        else
          Error.addSourceMessage(Error.MISSING_TYPE_BASETYPE,
            {InstNode.name(node)}, InstNode.info(node));
          fail();
        end if;

        cls_tree := ClassTree.flatten(cls_tree);
        inst_cls := Class.INSTANCED_CLASS(ty, cls_tree, Sections.EMPTY(), cls.prefixes, cls.restriction);
        InstNode.updateClass(inst_cls, node);
      then
        ();

    case Class.EXPANDED_CLASS(elements = cls_tree)
      algorithm
        // Instantiate expressions in the extends nodes.
        for ext in ClassTree.getExtends(cls_tree) loop
          sections := instExpressions(ext, ext, sections, context);
        end for;

        // Instantiate expressions in the local components.
        ClassTree.applyLocalComponents(cls_tree,
          function instComponentExpressions(context = context));

        // Flatten the class tree so we don't need to deal with extends anymore.
        cls.elements := ClassTree.flatten(cls_tree);
        InstNode.updateClass(cls, node);

        // Instantiate local equation/algorithm sections.
        next_context := if Restriction.isFunction(cls.restriction) then
          NFInstContext.FUNCTION else NFInstContext.CLASS;
        next_context := InstContext.set(context, next_context);
        sections := instSections(node, scope, next_context, sections);

        ty := makeComplexType(cls.restriction, node, cls);
        inst_cls := Class.INSTANCED_CLASS(ty, cls.elements, sections, cls.prefixes, cls.restriction);
        InstNode.updateClass(inst_cls, node);

        instComplexType(ty, context);
      then
        ();

    case Class.EXPANDED_DERIVED(dims = dims)
      algorithm
        sections := instExpressions(cls.baseClass, scope, sections, context);

        info := InstNode.info(node);

        for i in 1:arrayLength(dims) loop
          dims[i] := instDimension(dims[i], context, info);
        end for;

        if Restriction.isRecord(cls.restriction) then
          instRecordConstructor(node, context);
        end if;
      then
        ();

    case Class.INSTANCED_BUILTIN(elements = ClassTree.FLAT_TREE(components = local_comps))
      algorithm
        for comp in local_comps loop
          instComponentExpressions(comp, context);
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
  list<Record.Field> fields;
algorithm
  cls_node := if SCodeUtil.isOperatorRecord(InstNode.definition(node))
    then InstNode.classScope(node) else InstNode.classScope(InstNode.getDerivedNode(node));
  ty := ComplexType.RECORD(cls_node, {});
end makeRecordComplexType;

function instComplexType
  input Type ty;
  input InstContext.Type context;
algorithm
  () := match ty
    local
      InstNode node;
      CachedData cache;

    case Type.COMPLEX(complexTy = ComplexType.RECORD(node))
      // Make sure it's really a record, and not e.g. a record inherited by a model.
      // TODO: This check should really be InstNode.isRecord(node), but that
      //       causes issues with e.g. ComplexInput/ComplexOutput.
      guard not InstNode.isModel(node)
      algorithm
        instRecordConstructor(node, context);
      then
        ();

    else ();
  end match;
end instComplexType;

function instRecordConstructor
  input InstNode node;
  input InstContext.Type context;
protected
  CachedData cache;
algorithm
  cache := InstNode.getFuncCache(node);

  () := match cache
    case CachedData.FUNCTION() then ();
    else
      algorithm
        InstNode.cacheInitFunc(node);

        if SCodeUtil.isOperatorRecord(InstNode.definition(node)) then
          OperatorOverloading.instConstructor(
            InstNode.scopePath(node, includeRoot = true), node, context, InstNode.info(node));
        else
          Record.instDefaultConstructor(
            InstNode.scopePath(node, includeRoot = true), node, context, InstNode.info(node));
        end if;
      then
        ();

  end match;
end instRecordConstructor;

function instBuiltinAttribute
  input output Modifier attribute;
  input InstNode node;
  input InstContext.Type context;
algorithm
  () := match attribute
    local
      Binding binding;

    case Modifier.MODIFIER(binding = binding)
      algorithm
        attribute.binding := instBinding(binding, context);
      then
        ();

    // Redeclaration of builtin attributes is not allowed.
    case Modifier.REDECLARE()
      algorithm
        Error.addSourceMessage(Error.INVALID_REDECLARE_IN_BASIC_TYPE,
          {Modifier.name(attribute)}, Modifier.info(attribute));
      then
        fail();

    else ();
  end match;
end instBuiltinAttribute;

function instComponentExpressions
  input InstNode component;
  input InstContext.Type context;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c = InstNode.component(node);
  array<Dimension> dims;
algorithm
  () := match c
    case Component.UNTYPED_COMPONENT(dimensions = dims, instantiated = false)
      algorithm
        c.binding := instBinding(c.binding, context);
        c.condition := instBinding(c.condition, context);
        instExpressions(c.classInst, node, context = context);

        for i in 1:arrayLength(dims) loop
          dims[i] := instDimension(dims[i], context, c.info);
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
        c.modifier := instBuiltinAttribute(c.modifier, component, context);
        InstNode.updateComponent(c, node);
      then
        ();

    else
      algorithm
        if not InstContext.inRelaxed(context) then
          Error.assertion(false, getInstanceName() + " got invalid component", sourceInfo());
          fail();
        end if;
      then
        ();

  end match;
end instComponentExpressions;

function instBinding
  input output Binding binding;
  input InstContext.Type context;
algorithm
  binding := match binding
    local
      Expression bind_exp;

    case Binding.RAW_BINDING()
      algorithm
        bind_exp := instExp(binding.bindingExp, binding.scope, context, binding.info);

        if not listEmpty(binding.subs) then
          bind_exp := Expression.SUBSCRIPTED_EXP(bind_exp, binding.subs, Type.UNKNOWN(), true);
        end if;
      then
        Binding.UNTYPED_BINDING(bind_exp, false, binding.scope, binding.eachType, binding.source, binding.info);

    else binding;
  end match;
end instBinding;

function instExpOpt
  input Option<Absyn.Exp> absynExp;
  input InstNode scope;
  input InstContext.Type context;
  input SourceInfo info;
  output Option<Expression> exp;
algorithm
  exp := match absynExp
    local
      Absyn.Exp aexp;

    case NONE() then NONE();
    case SOME(aexp) then SOME(instExp(aexp, scope, context, info));

  end match;
end instExpOpt;

function instExp
  input Absyn.Exp absynExp;
  input InstNode scope;
  input InstContext.Type context;
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
      then instCref(absynExp.componentRef, scope, context, info);

    case Absyn.Exp.ARRAY()
      algorithm
        expl := list(instExp(e, scope, context, info) for e in absynExp.arrayExp);
      then
        Expression.makeArray(Type.UNKNOWN(), expl);

    case Absyn.Exp.MATRIX()
      algorithm
        expll := list(list(instExp(e, scope, context, info) for e in el) for el in absynExp.matrix);
      then
        Expression.MATRIX(expll);

    case Absyn.Exp.RANGE()
      algorithm
        e1 := instExp(absynExp.start, scope, context, info);
        oe := instExpOpt(absynExp.step, scope, context, info);
        e3 := instExp(absynExp.stop, scope, context, info);
      then
        Expression.RANGE(Type.UNKNOWN(), e1, oe, e3);

    case Absyn.Exp.TUPLE()
      algorithm
        expl := list(instExp(e, scope, context, info) for e in absynExp.expressions);
      then
        Expression.TUPLE(Type.UNKNOWN(), expl);

    case Absyn.Exp.BINARY()
      algorithm
        e1 := instExp(absynExp.exp1, scope, context, info);
        e2 := instExp(absynExp.exp2, scope, context, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.BINARY(e1, op, e2);

    case Absyn.Exp.UNARY()
      algorithm
        e1 := instExp(absynExp.exp, scope, context, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.UNARY(op, e1);

    case Absyn.Exp.LBINARY()
      algorithm
        e1 := instExp(absynExp.exp1, scope, context, info);
        e2 := instExp(absynExp.exp2, scope, context, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.LBINARY(e1, op, e2);

    case Absyn.Exp.LUNARY()
      algorithm
        e1 := instExp(absynExp.exp, scope, context, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.LUNARY(op, e1);

    case Absyn.Exp.RELATION()
      algorithm
        e1 := instExp(absynExp.exp1, scope, context, info);
        e2 := instExp(absynExp.exp2, scope, context, info);
        op := Operator.fromAbsyn(absynExp.op);
      then
        Expression.RELATION(e1, op, e2);

    case Absyn.Exp.IFEXP()
      algorithm
        e3 := instExp(absynExp.elseBranch, scope, context, info);

        for branch in listReverse(absynExp.elseIfBranch) loop
          e1 := instExp(Util.tuple21(branch), scope, context, info);
          e2 := instExp(Util.tuple22(branch), scope, context, info);
          e3 := Expression.IF(Type.UNKNOWN(), e1, e2, e3);
        end for;

        e1 := instExp(absynExp.ifExp, scope, context, info);
        e2 := instExp(absynExp.trueBranch, scope, context, info);
      then
        Expression.IF(Type.UNKNOWN(), e1, e2, e3);

    case Absyn.Exp.CALL()
      then Call.instantiate(absynExp.function_, absynExp.functionArgs, scope, context, info);

    case Absyn.Exp.PARTEVALFUNCTION()
      then instPartEvalFunction(absynExp.function_, absynExp.functionArgs, scope, context, info);

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
  input InstContext.Type context;
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
    else Lookup.lookupComponent(absynCref, scope, context, info);
  end match;

  cref := instCrefSubscripts(cref, scope, context, info);

  crefExp := match cref
    case ComponentRef.CREF()
      then
        match cref.node
          case InstNode.COMPONENT_NODE()
            then instCrefComponent(cref, cref.node, found_scope, info);
          case InstNode.CLASS_NODE()
            then if Class.isFunction(InstNode.getClass(cref.node)) then
                   instCrefFunction(cref, found_scope, context, info)
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
        prefixed_cref := ComponentRef.removeOuterCrefPrefix(prefixed_cref);
      then
        Expression.CREF(Type.UNKNOWN(), prefixed_cref);

  end match;
end instCrefComponent;

function instCrefFunction
  input ComponentRef cref;
  input InstNode scope;
  input InstContext.Type context;
  input SourceInfo info;
  output Expression crefExp;
protected
  ComponentRef fn_ref;
algorithm
  fn_ref := ComponentRef.fromNodeList(InstNode.scopeList(scope, includeRoot = true));
  fn_ref := ComponentRef.append(cref, fn_ref);
  fn_ref := Function.instFunctionRef(fn_ref, context, info);
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
  input InstContext.Type context;
  input SourceInfo info;
algorithm
  () := match cref
    local
      ComponentRef rest_cr;

    case ComponentRef.CREF()
      algorithm
        if not listEmpty(cref.subscripts) then
          cref.subscripts := list(instSubscript(s, scope, context, info) for s in cref.subscripts);
        end if;

        rest_cr := instCrefSubscripts(cref.restCref, scope, context, info);
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
  input InstContext.Type context;
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
        exp := instExp(absynSub.subscript, scope, context, info);
      then
        Subscript.fromExp(exp);
  end match;
end instSubscript;

function instPartEvalFunction
  input Absyn.ComponentRef func;
  input Absyn.FunctionArgs funcArgs;
  input InstNode scope;
  input InstContext.Type context;
  input SourceInfo info;
  output Expression outExp;
protected
  ComponentRef fn_ref;
  list<Absyn.NamedArg> nargs;
  list<Expression> args;
  list<String> arg_names;
algorithm
  Absyn.FunctionArgs.FUNCTIONARGS(argNames = nargs) := funcArgs;
  outExp := instCref(func, scope, context, info);

  if not listEmpty(nargs) then
    fn_ref := Expression.toCref(outExp);
    args := list(instExp(arg.argValue, scope, context, info) for arg in nargs);
    arg_names := list(arg.argName for arg in nargs);
    outExp := Expression.PARTIAL_FUNCTION_APPLICATION(fn_ref, args, arg_names, Type.UNKNOWN());
  end if;
end instPartEvalFunction;

function instSections
  input InstNode node;
  input InstNode scope;
  input InstContext.Type context;
  input output Sections sections;
protected
  SCode.Element el = InstNode.definition(node);
  SCode.ClassDef def;
algorithm
  sections := match el
    case SCode.CLASS(classDef = SCode.PARTS())
      then instSections2(el.classDef, scope, context, sections);

    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = def as SCode.PARTS()))
      then instSections2(def, scope, context, sections);

    else sections;
  end match;
end instSections;

function instSections2
  input SCode.ClassDef parts;
  input InstNode scope;
  input InstContext.Type context;
  input output Sections sections;
algorithm
  sections := match (parts, sections)
    local
      list<Equation> eq, ieq;
      list<Algorithm> alg, ialg;
      SCode.ExternalDecl ext_decl;
      InstContext.Type icontext;

    // allow non standard Modelica on a flag
    case(SCode.PARTS(externalDecl = SOME(ext_decl)), Sections.EXTERNAL())
      guard Flags.isConfigFlagSet(Flags.ALLOW_NON_STANDARD_MODELICA, "nonStdMultipleExternalDeclarations")
      then
        instExternalDecl(ext_decl, scope, context);

    case (_, Sections.EXTERNAL())
      guard SCodeUtil.classDefHasSections(parts, checkExternal = true)
      algorithm
        // Class with inherited external section that also contains other sections.
        Error.addMultiSourceMessage(Error.MULTIPLE_SECTIONS_IN_FUNCTION,
          {InstNode.name(scope)}, {sections.info, InstNode.info(scope)});
      then
        fail();

    case (SCode.PARTS(externalDecl = SOME(ext_decl)), _)
      algorithm
        if SCodeUtil.classDefHasSections(parts, checkExternal = false) then
          // Class with external section that also contains other sections.
          Error.addSourceMessage(Error.MULTIPLE_SECTIONS_IN_FUNCTION,
            {InstNode.name(scope)}, InstNode.info(scope));
          fail();
        end if;
      then
        instExternalDecl(ext_decl, scope, context);

    case (SCode.PARTS(), _)
      algorithm
        icontext := InstContext.set(context, NFInstContext.INITIAL);

        eq := instEquations(parts.normalEquationLst, scope, context);
        ieq := instEquations(parts.initialEquationLst, scope, icontext);
        alg := instAlgorithmSections(parts.normalAlgorithmLst, scope, context);
        ialg := instAlgorithmSections(parts.initialAlgorithmLst, scope, icontext);
      then
        Sections.join(Sections.new(eq, ieq, alg, ialg), sections);

  end match;
end instSections2;

function instExternalDecl
  input SCode.ExternalDecl extDecl;
  input InstNode scope;
  input InstContext.Type context;
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
        args := list(instExp(arg, scope, context, info) for arg in extDecl.args);

        if isSome(extDecl.output_) then
          ret_cref := Lookup.lookupLocalComponent(Util.getOption(extDecl.output_), scope, context, info);
        else
          ret_cref := ComponentRef.EMPTY();
        end if;
      then
        Sections.EXTERNAL(name, args, ret_cref, lang, extDecl.annotation_, isSome(extDecl.funcName), info);

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
  input InstContext.Type context;
  output list<Equation> instEql;
algorithm
  instEql := list(instEquation(eq, scope, context) for eq in scodeEql);
end instEquations;

function instEquation
  input SCode.Equation scodeEq;
  input InstNode scope;
  input InstContext.Type context;
  output Equation instEq;
protected
  SCode.EEquation eq;
algorithm
  SCode.EQUATION(eEquation = eq) := scodeEq;
  instEq := instEEquation(eq, scope, context);
end instEquation;

function instEEquations
  input list<SCode.EEquation> scodeEql;
  input InstNode scope;
  input InstContext.Type context;
  output list<Equation> instEql;
algorithm
  instEql := list(instEEquation(eq, scope, context) for eq in scodeEql);
end instEEquations;

function instEEquation
  input SCode.EEquation scodeEq;
  input InstNode scope;
  input InstContext.Type context;
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
      InstContext.Type next_origin;

    case SCode.EEquation.EQ_EQUALS(info = info)
      algorithm
        exp1 := instExp(scodeEq.expLeft, scope, context, info);
        exp2 := instExp(scodeEq.expRight, scope, context, info);
      then
        Equation.EQUALITY(exp1, exp2, Type.UNKNOWN(), makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_CONNECT(info = info)
      algorithm
        if InstContext.inWhen(context) then
          Error.addSourceMessage(Error.CONNECT_IN_WHEN,
            {Dump.printComponentRefStr(scodeEq.crefLeft),
             Dump.printComponentRefStr(scodeEq.crefRight)}, info);
          fail();
        end if;

        exp1 := instConnectorCref(scodeEq.crefLeft, scope, context, info);
        exp2 := instConnectorCref(scodeEq.crefRight, scope, context, info);
      then
        Equation.CONNECT(exp1, exp2, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_FOR(info = info)
      algorithm
        oexp := instExpOpt(scodeEq.range, scope, context, info);
        checkIteratorShadowing(scodeEq.index, scope, scodeEq.info);
        (for_scope, iter) := addIteratorToScope(scodeEq.index, scope, scodeEq.info);
        next_origin := InstContext.set(context, NFInstContext.FOR);
        eql := instEEquations(scodeEq.eEquationLst, for_scope, next_origin);
      then
        Equation.FOR(iter, oexp, eql, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_IF(info = info)
      algorithm
        // Instantiate the conditions.
        expl := list(instExp(c, scope, context, info) for c in scodeEq.condition);

        // Instantiate each branch and pair it up with a condition.
        next_origin := InstContext.set(context, NFInstContext.IF);
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
        if InstContext.inWhen(context) then
          Error.addSourceMessageAndFail(Error.NESTED_WHEN, {}, info);
        elseif InstContext.inInitial(context) then
          Error.addSourceMessageAndFail(Error.INITIAL_WHEN, {}, info);
        end if;

        next_origin := InstContext.set(context, NFInstContext.WHEN);
        exp1 := instExp(scodeEq.condition, scope, context, info);
        eql := instEEquations(scodeEq.eEquationLst, scope, next_origin);
        branches := {Equation.makeBranch(exp1, eql)};

        for branch in scodeEq.elseBranches loop
          exp1 := instExp(Util.tuple21(branch), scope, context, info);
          eql := instEEquations(Util.tuple22(branch), scope, next_origin);
          branches := Equation.makeBranch(exp1, eql) :: branches;
        end for;
      then
        Equation.WHEN(listReverse(branches), makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_ASSERT(info = info)
      algorithm
        exp1 := instExp(scodeEq.condition, scope, context, info);
        exp2 := instExp(scodeEq.message, scope, context, info);
        exp3 := instExp(scodeEq.level, scope, context, info);
      then
        Equation.ASSERT(exp1, exp2, exp3, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_TERMINATE(info = info)
      algorithm
        exp1 := instExp(scodeEq.message, scope, context, info);
      then
        Equation.TERMINATE(exp1, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_REINIT(info = info)
      algorithm
        if not InstContext.inWhen(context) then
          Error.addSourceMessage(Error.REINIT_NOT_IN_WHEN, {}, info);
          fail();
        end if;

        exp1 := instExp(scodeEq.cref, scope, context, info);
        exp2 := instExp(scodeEq.expReinit, scope, context, info);
      then
        Equation.REINIT(exp1, exp2, makeSource(scodeEq.comment, info));

    case SCode.EEquation.EQ_NORETCALL(info = info)
      algorithm
        exp1 := instExp(scodeEq.exp, scope, context, info);
      then
        Equation.NORETCALL(exp1, makeSource(scodeEq.comment, info));

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown equation", sourceInfo());
      then
        fail();

  end match;
end instEEquation;

function instConnectorCref
  input Absyn.ComponentRef absynCref;
  input InstNode scope;
  input InstContext.Type context;
  input SourceInfo info;
  output Expression outExp;
protected
  ComponentRef cref, prefix;
  InstNode found_scope;
algorithm
  (cref, found_scope) := Lookup.lookupConnector(absynCref, scope, context, info);
  cref := instCrefSubscripts(cref, scope, context, info);

  prefix := ComponentRef.fromNodeList(InstNode.scopeList(found_scope));
  if not ComponentRef.isEmpty(prefix) then
    cref := ComponentRef.append(cref, prefix);
  end if;

  outExp := Expression.CREF(Type.UNKNOWN(), cref);
end instConnectorCref;

function makeSource
  input SCode.Comment comment;
  input SourceInfo info;
  output DAE.ElementSource source;
algorithm
  source := DAE.ElementSource.SOURCE(info, {}, DAE.NOCOMPPRE(), {}, {}, {}, {comment});
end makeSource;

function instAlgorithmSections
  input list<SCode.AlgorithmSection> algorithmSections;
  input InstNode scope;
  input InstContext.Type context;
  output list<Algorithm> algs;
algorithm
  algs := list(instAlgorithmSection(alg, scope, context) for alg in algorithmSections);
end instAlgorithmSections;

function instAlgorithmSection
  input SCode.AlgorithmSection algorithmSection;
  input InstNode scope;
  input InstContext.Type context;
  output Algorithm alg;
algorithm
  alg := Algorithm.ALGORITHM(instStatements(algorithmSection.statements, scope, context),
                             DAE.emptyElementSource);
end instAlgorithmSection;

function instStatements
  input list<SCode.Statement> scodeStmtl;
  input InstNode scope;
  input InstContext.Type context;
  output list<Statement> statements;
algorithm
  statements := list(instStatement(stmt, scope, context) for stmt in scodeStmtl);
end instStatements;

function instStatement
  input SCode.Statement scodeStmt;
  input InstNode scope;
  input InstContext.Type context;
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
      InstContext.Type next_origin;

    case SCode.Statement.ALG_ASSIGN(info = info)
      algorithm
        exp1 := instExp(scodeStmt.assignComponent, scope, context, info);
        exp2 := instExp(scodeStmt.value, scope, context, info);
      then
        Statement.ASSIGNMENT(exp1, exp2, Type.UNKNOWN(), makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_FOR(info = info)
      algorithm
        oexp := instExpOpt(scodeStmt.range, scope, context, info);
        (for_scope, iter) := addIteratorToScope(scodeStmt.index, scope, info);
        next_origin := InstContext.set(context, NFInstContext.FOR);
        stmtl := instStatements(scodeStmt.forBody, for_scope, next_origin);
      then
        Statement.FOR(iter, oexp, stmtl, Statement.ForType.NORMAL(), makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_PARFOR(info = info)
      algorithm
        oexp := instExpOpt(scodeStmt.range, scope, context, info);
        (for_scope, iter) := addIteratorToScope(scodeStmt.index, scope, info);
        next_origin := InstContext.set(context, NFInstContext.FOR);
        stmtl := instStatements(scodeStmt.parforBody, for_scope, next_origin);
      then
        Statement.FOR(iter, oexp, stmtl, Statement.ForType.PARALLEL({}), makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_IF(info = info)
      algorithm
        branches := {};
        next_origin := InstContext.set(context, NFInstContext.FOR);

        for branch in (scodeStmt.boolExpr, scodeStmt.trueBranch) :: scodeStmt.elseIfBranch loop
          exp1 := instExp(Util.tuple21(branch), scope, context, info);
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
        if not InstContext.inValidWhenScope(context) then
          if InstContext.inWhen(context) then
            Error.addSourceMessageAndFail(Error.NESTED_WHEN, {}, info);
          elseif InstContext.inInitial(context) then
            Error.addSourceMessageAndFail(Error.INITIAL_WHEN, {}, info);
          else
            Error.addSourceMessageAndFail(Error.INVALID_WHEN_STATEMENT_CONTEXT, {}, info);
          end if;
        end if;

        branches := {};
        for branch in scodeStmt.branches loop
          exp1 := instExp(Util.tuple21(branch), scope, context, info);
          next_origin := InstContext.set(context, NFInstContext.WHEN);
          stmtl := instStatements(Util.tuple22(branch), scope, next_origin);
          branches := (exp1, stmtl) :: branches;
        end for;
      then
        Statement.WHEN(listReverse(branches), makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_ASSERT(info = info)
      algorithm
        exp1 := instExp(scodeStmt.condition, scope, context, info);
        exp2 := instExp(scodeStmt.message, scope, context, info);
        exp3 := instExp(scodeStmt.level, scope, context, info);
      then
        Statement.ASSERT(exp1, exp2, exp3, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_TERMINATE(info = info)
      algorithm
        exp1 := instExp(scodeStmt.message, scope, context, info);
      then
        Statement.TERMINATE(exp1, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_REINIT(info = info)
      algorithm
        Error.addSourceMessage(Error.REINIT_NOT_IN_WHEN, {}, info);
      then
        fail();

    case SCode.Statement.ALG_NORETCALL(info = info)
      algorithm
        exp1 := instExp(scodeStmt.exp, scope, context, info);
      then
        Statement.NORETCALL(exp1, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_WHILE(info = info)
      algorithm
        exp1 := instExp(scodeStmt.boolExpr, scope, context, info);
        next_origin := InstContext.set(context, NFInstContext.WHILE);
        stmtl := instStatements(scodeStmt.whileBody, scope, next_origin);
      then
        Statement.WHILE(exp1, stmtl, makeSource(scodeStmt.comment, info));

    case SCode.Statement.ALG_RETURN()
      algorithm
        if not InstContext.inFunction(context) then
          Error.addSourceMessage(Error.RETURN_OUTSIDE_FUNCTION, {}, scodeStmt.info);
          fail();
        end if;
      then
        Statement.RETURN(makeSource(scodeStmt.comment, scodeStmt.info));

    case SCode.Statement.ALG_BREAK()
      algorithm
        if not InstContext.inLoop(context) then
          Error.addSourceMessage(Error.BREAK_OUTSIDE_LOOP, {}, scodeStmt.info);
          fail();
        end if;
      then
        Statement.BREAK(makeSource(scodeStmt.comment, scodeStmt.info));

    case SCode.Statement.ALG_FAILURE()
      algorithm
        stmtl := instStatements(scodeStmt.stmts, scope, context);
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

function checkIteratorShadowing
  "Gives a warning if the given iterator name is already used in an outer
   implicit scope."
  input String name;
  input InstNode scope;
  input SourceInfo info;
algorithm
  () := match scope
    case InstNode.IMPLICIT_SCOPE()
      algorithm
        for iter in scope.locals loop
          if InstNode.name(iter) == name then
            Error.addMultiSourceMessage(Error.SHADOWED_ITERATOR,
              {name}, {InstNode.info(iter), info});
            return;
          end if;
        end for;
      then
        ();

    else ();
  end match;
end checkIteratorShadowing;

function insertGeneratedInners
  "Inner elements can be generated automatically during instantiation if they're
   missing, and are stored in the cache of the top scope since that's easily
   accessible during lookup. This function copies any such inner elements into
   the class we're instantiating, so that they are typed and flattened properly."
  input InstNode node;
  input InstNode topScope;
  input InstContext.Type context;
protected
  UnorderedMap<String, InstNode> generated_inners;
  list<Mutable<InstNode>> inner_comps;
  InstNode n, on;
  String name, str;
  Class cls;
  ClassTree cls_tree;
  InstNode base_node;
  Boolean name_defined;
algorithm
  InstNodeType.TOP_SCOPE(generatedInners = generated_inners) := InstNode.nodeType(topScope);

  // No inners => nothing more to do.
  if UnorderedMap.isEmpty(generated_inners) then
    return;
  end if;

  inner_comps := {};

  for n in UnorderedMap.valueArray(generated_inners) loop
    name := InstNode.name(n);
    checkTopLevelOuter(name, n, node, context);

    // Always print a warning that an inner element was automatically generated.
    Error.addSourceMessage(Error.MISSING_INNER_ADDED,
      {InstNode.typeName(n), name}, InstNode.info(n));

    // Only components needs to be added to the class, since classes are
    // not part of the flat class.
    if InstNode.isComponent(n) then
      // The component might have been instantiated during lookup, otherwise do
      // it here (instComponent will skip already instantiated components).
      instComponent(n, NFComponent.DEFAULT_ATTR, Modifier.NOMOD(), true, 0, NONE(), NFInstContext.CLASS);

      // If the component's class has a missingInnerMessage annotation, use it
      // to give a diagnostic message.
      try
        Absyn.STRING(str) := SCodeUtil.getElementNamedAnnotation(
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
    base_node := Class.lastBaseClass(node);
    cls := InstNode.getClass(base_node);
    cls_tree := ClassTree.appendComponentsToInstTree(inner_comps, Class.classTree(cls));
    InstNode.updateClass(Class.setClassTree(cls_tree, cls), base_node);
  end if;
end insertGeneratedInners;

function checkTopLevelOuter
  input String name;
  input InstNode outerNode;
  input InstNode scope;
  input InstContext.Type context;
protected
  InstNode node;
  Boolean is_error;
algorithm
  try
    node := Lookup.lookupSimpleName(name, scope);

    if InstNode.isInner(node) then
      is_error := not InstContext.inRelaxed(context);

      if is_error then
        Error.addSourceMessageAsError(Error.TOP_LEVEL_OUTER, {name}, InstNode.info(node));
      else
        Error.addSourceMessage(Error.TOP_LEVEL_OUTER, {name}, InstNode.info(node));
      end if;
    else
      Error.addMultiSourceMessage(Error.MISSING_INNER_NAME_CONFLICT,
        {name}, {InstNode.info(node), InstNode.info(outerNode)});
      is_error := true;
    end if;
  else
    is_error := false;
  end try;

  if is_error then
    fail();
  end if;
end checkTopLevelOuter;

function updateImplicitVariability
  input InstNode node;
  input Boolean parentEval;
protected
  Class cls = InstNode.getClass(node);
  ClassTree cls_tree;
algorithm
  () := match cls
    case Class.INSTANCED_CLASS(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          updateImplicitVariabilityComp(c, parentEval);
        end for;

        Sections.apply(cls.sections,
          function updateImplicitVariabilityEq(inWhen = false),
          updateImplicitVariabilityAlg);
      then
        ();

    case Class.EXPANDED_DERIVED()
      algorithm
        for dim in cls.dims loop
          Structural.markDimension(dim);
        end for;

        updateImplicitVariability(cls.baseClass, parentEval);
      then
        ();

    case Class.INSTANCED_BUILTIN(elements = cls_tree as ClassTree.FLAT_TREE())
      algorithm
        for c in cls_tree.components loop
          updateImplicitVariabilityComp(c, parentEval);
        end for;
      then
        ();

    else ();
  end match;
end updateImplicitVariability;

function updateImplicitVariabilityComp
  input InstNode component;
  input Boolean parentEval;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c = InstNode.component(node);
algorithm
  () := match c
    local
      Binding binding, condition;
      Boolean eval;

    case Component.UNTYPED_COMPONENT(binding = binding, condition = condition)
      algorithm
        eval := Component.getEvaluateAnnotation(c);

        if Structural.isStructuralComponent(c, c.attributes, binding, node, eval, parentEval) then
          Structural.markComponent(c, node);
        end if;

        // Parameters used in array dimensions are structural.
        for dim in c.dimensions loop
          Structural.markDimension(dim);
        end for;

        // Parameters that determine the size of a component binding are structural.
        if Binding.isBound(binding) then
          Structural.markExpSize(Binding.getUntypedExp(binding));
        end if;

        // Parameters used in a component condition are structural.
        if Binding.isBound(condition) then
          Structural.markExp(Binding.getUntypedExp(condition));
        end if;

        updateImplicitVariability(c.classInst, eval or parentEval);
      then
        ();

    case Component.TYPE_ATTRIBUTE()
      guard listMember(InstNode.name(component), {"fixed", "stateSelect"})
      algorithm
        binding := Modifier.binding(c.modifier);

        if Binding.isBound(binding) then
          Structural.markExp(Binding.getUntypedExp(binding));
        end if;
      then
        ();

    else ();
  end match;
end updateImplicitVariabilityComp;

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

    case Equation.EQUALITY()
      algorithm
        if inWhen then
          markImplicitWhenExp(eq.lhs);
        end if;
      then
        ();

    case Equation.CONNECT()
      algorithm
        Structural.markSubscriptsInExp(eq.lhs);
        Structural.markSubscriptsInExp(eq.rhs);
      then
        ();

    case Equation.FOR()
      algorithm
        updateImplicitVariabilityEql(eq.body, inWhen);
      then
        ();

    case Equation.IF()
      algorithm
        for branch in eq.branches loop
          () := match branch
            case Equation.Branch.BRANCH()
              algorithm
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

function checkPartialClass
  input InstNode node;
  input InstContext.Type context;
algorithm
  if InstNode.isPartial(node) and not InstContext.inRelaxed(context) then
    Error.addSourceMessage(Error.INST_PARTIAL_CLASS,
      {InstNode.name(node)}, InstNode.info(node));
    fail();
  end if;
end checkPartialClass;

annotation(__OpenModelica_Interface="frontend");
end NFInst;

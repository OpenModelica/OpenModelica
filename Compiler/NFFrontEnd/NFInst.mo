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
import Binding = NFBinding;
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

type EquationScope = enumeration(NORMAL, INITIAL, WHEN);

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
  Component top_comp;
  InstNode top_comp_node;
  String name;
  FlatModel flat_model;
  FunctionTree funcs;
algorithm
  // Create a root node from the given top-level classes.
  top := makeTopNode(program);
  name := Absyn.pathString(classPath);

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, Absyn.dummyInfo);
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

  // Type the class.
  Typing.typeClass(inst_cls, name);

  // Flatten and convert the class into a DAE.
  (flat_model, funcs) := Flatten.flatten(inst_cls, name);

  // Replace or collect package constants depending on the
  // replacePackageConstants debug flag.
  if Flags.isSet(Flags.REPLACE_PACKAGE_CONSTS) then
    (flat_model, funcs) := Package.replaceConstants(flat_model, funcs);
  else
    flat_model := Package.collectConstants(flat_model, funcs);
  end if;

  flat_model := Scalarize.scalarize(flat_model, name);
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
  node := instClass(node, Modifier.NOMOD(), NFComponent.DEFAULT_ATTR, parent);
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
  cls := Class.fromSCode(topClasses, false, topNode);
  // The class needs to be expanded to allow lookup in it. The top scope will
  // only contain classes, so we can do this instead of the whole expandClass.
  cls := Class.initExpandedClass(cls);
  topNode := InstNode.updateClass(cls, topNode);
end makeTopNode;

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
algorithm
  Error.assertion(SCode.elementIsClass(definition), getInstanceName() + " got non-class element", sourceInfo());
  SCode.CLASS(classDef = cdef) := definition;

  cls := match cdef
    // A long class definition, add its elements to a new scope.
    case SCode.PARTS()
      then Class.fromSCode(cdef.elementLst, false, scope);

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
        Class.fromSCode(ce_cdef.elementLst, true, scope);

    // An enumeration definition, add the literals to a new scope.
    case SCode.ENUMERATION()
      algorithm
        ty := makeEnumerationType(cdef.enumLst, scope);
      then
        Class.fromEnumeration(cdef.enumLst, ty, scope);

    else Class.PARTIAL_CLASS(NFClassTree.EMPTY, Modifier.NOMOD());
  end match;
end partialInstClass2;

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
  String name;
algorithm
  SCode.CLASS(name = name, classDef = cdef, info = info) := def;

  node := match cdef
    local
      Absyn.TypeSpec ty;
      SCode.Mod der_mod;
      SCode.Element ext;
      Class c;
      list<SCode.Element> exts;
      array<InstNode> comps;
      Modifier mod;
      list<InstNode> ext_nodes;
      Option<InstNode> builtin_ext;
      Class.Prefixes prefs;
      InstNode ext_node;
      list<Dimension> dims;
      ClassTree tree;
      Component.Attributes attr;
      Restriction res;

    case SCode.PARTS()
      algorithm
        c := InstNode.getClass(node);
        // Change the class to an empty expanded class, to avoid instantiation loops.
        c := Class.initExpandedClass(c);
        node := InstNode.updateClass(c, node);

        Class.EXPANDED_CLASS(elements = tree, modifier = mod) := c;
        builtin_ext := ClassTree.mapFoldExtends(tree, expandExtends, NONE());

        prefs := instClassPrefixes(def);

        if isSome(builtin_ext) then
          node := expandBuiltinExtends(builtin_ext, tree, prefs, node);
        else
          tree := ClassTree.expand(tree);
          res := Restriction.fromSCode(SCode.getClassRestriction(def));
          c := Class.EXPANDED_CLASS(tree, mod, prefs, res);
          node := InstNode.updateClass(c, node);
        end if;
      then
        node;

    // A short class definition, e.g. class A = B.
    case SCode.DERIVED(typeSpec = ty, modifications = _)
      algorithm
        // Look up the class that's being derived from and expand it.
        ext_node :: _ := Lookup.lookupBaseClassName(Absyn.typeSpecPath(ty), InstNode.parent(node), info);
        ext_node := expand(ext_node);

        // Fetch the needed information from the class definition and construct a DERIVED_CLASS.
        prefs := instClassPrefixes(def);
        attr := instDerivedAttributes(cdef.attributes);
        dims := list(Dimension.RAW_DIM(d) for d in Absyn.typeSpecDimensions(ty));
        mod := Class.getModifier(InstNode.getClass(node));

        res := Restriction.fromSCode(SCode.getClassRestriction(def));
        c := Class.DERIVED_CLASS(ext_node, mod, dims, prefs, attr, res);
        node := InstNode.updateClass(c, node);
      then
        node;

    case SCode.CLASS_EXTENDS()
      algorithm
        tree := Class.classTree(InstNode.getClass(InstNode.parent(node)));
        ext_node := ClassTree.getRedeclaredNode(name, tree);
        ext_node := expand(ext_node);
        ext_node := InstNode.setNodeType(InstNodeType.BASE_CLASS(node, def), ext_node);

        c := InstNode.getClass(node);
        c := Class.initExpandedClass(c);
        node := InstNode.updateClass(c, node);

        Class.EXPANDED_CLASS(elements = tree, modifier = mod) := c;
        builtin_ext := ClassTree.mapFoldExtends(tree, expandExtends, NONE());
        ClassTree.setClassExtends(ext_node, tree);
        prefs := instClassPrefixes(def);

        if isSome(builtin_ext) or Class.isBuiltin(InstNode.getClass(ext_node)) then
          // A class extending from a base class may not have other base
          // classes, and since this is a class extends it has at least one.
          node := Util.getOptionOrDefault(builtin_ext, ext_node);
          Error.addSourceMessage(Error.BUILTIN_EXTENDS_INVALID_ELEMENTS,
            {InstNode.name(node)}, InstNode.info(node));
          fail();
        else
          tree := ClassTree.expand(tree);
          res := Restriction.fromSCode(SCode.getClassRestriction(def));
          c := Class.EXPANDED_CLASS(tree, mod, prefs, res);
          node := InstNode.updateClass(c, node);
        end if;
      then
        node;

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown class", sourceInfo());
      then
        fail();

  end match;
end expandClass2;

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
          var, dir, InnerOuter.NOT_INNER_OUTER);

  end match;
end instDerivedAttributes;

function expandExtends
  input output InstNode ext;
  input output Option<InstNode> builtinExt = NONE();
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

  def as SCode.Element.EXTENDS(base_path, vis, smod, ann, info) := InstNode.definition(ext);

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
  if Class.isBuiltin(InstNode.getClass(base_node)) then
    builtinExt := SOME(ext);
  end if;
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

function expandBuiltinExtends
  "This function handles the case where a class extends from a builtin type,
   like Real or some type derived from Real."
  input Option<InstNode> builtinExtends;
  input ClassTree scope;
  input Class.Prefixes prefixes;
  input output InstNode node;
protected
  InstNode builtin_ext;
  Class c;
  ClassTree tree;
  ComplexType eo_ty;
algorithm
  // Fetch the class of the builtin type.
  SOME(builtin_ext) := builtinExtends;

  node := match InstNode.name(builtin_ext)
    case "ExternalObject"
      algorithm
        // Construct the ComplexType for the external object.
        eo_ty := makeExternalObjectType(scope, node);
        // Construct the Class for the external object. We use an empty class
        // tree here, since the constructor and destructor is embedded in the
        // ComplexType instead. Using an empty class tree makes sure it's not
        // possible to call the constructor or destructor explicitly.
        c := Class.PARTIAL_BUILTIN(Type.COMPLEX(node, eo_ty), NFClassTree.EMPTY_FLAT,
          Modifier.NOMOD(), Restriction.EXTERNAL_OBJECT());
        node := InstNode.updateClass(c, node);
      then
        node;

    else
      algorithm
        c := InstNode.getClass(builtin_ext);

        // A class extending from a builtin type may not have other components or baseclasses.
        if ClassTree.componentCount(scope) > 0 or ClassTree.extendsCount(scope) > 1 then
          // ***TODO***: Find the invalid element and use its info to make the error
          //             message more accurate.
          Error.addSourceMessage(Error.BUILTIN_EXTENDS_INVALID_ELEMENTS,
            {InstNode.name(builtin_ext)}, InstNode.info(node));
          fail();
        end if;

        // Replace the class we're expanding with the builtin type.
        node := InstNode.updateClass(c, node);
      then
        node;

  end match;
end expandBuiltinExtends;

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

function instClass
  input output InstNode node;
  input Modifier modifier;
  input output Component.Attributes attributes = NFComponent.DEFAULT_ATTR;
  input InstNode parent = InstNode.EMPTY_NODE();
protected
  InstNode par, redecl_node, base_node;
  Class cls, inst_cls;
  ClassTree cls_tree;
  Modifier cls_mod, mod;
  list<Modifier> type_attr;
  list<Dimension> dims;
algorithm
  cls := InstNode.getClass(node);
  cls_mod := Class.getModifier(cls);
  cls_mod := Modifier.merge(modifier, cls_mod);

  () := match (cls, cls_mod)
    case (_, Modifier.REDECLARE())
      algorithm
        if not InstNode.isClass(cls_mod.element) then
          Error.addMultiSourceMessage(Error.INVALID_REDECLARE_AS,
            {"class", InstNode.name(node), "component"},
            {InstNode.info(cls_mod.element), InstNode.info(node)});
        end if;

        redecl_node := expand(cls_mod.element);
        node := instClass(redecl_node, cls_mod.mod, attributes, parent);
      then
        ();

    case (Class.EXPANDED_CLASS(), _)
      algorithm
        (node, par) := ClassTree.instantiate(node, parent);
        updateComponentClass(parent, node);
        inst_cls as Class.EXPANDED_CLASS(elements = cls_tree) := InstNode.getClass(node);

        // Fetch modification on the class definition.
        mod := Modifier.fromElement(InstNode.definition(node), InstNode.level(parent), InstNode.parent(node));
        // Merge with any outer modifications.
        mod := Modifier.merge(cls_mod, mod);

        // Apply the modifiers of extends nodes.
        ClassTree.mapExtends(cls_tree, function modifyExtends(scope = par, parent = par));

        // Apply modifier in this scope.
        applyModifier(mod, cls_tree, InstNode.name(node));

        cls_tree := ClassTree.replaceDuplicates(cls_tree);
        ClassTree.checkDuplicates(cls_tree);
        InstNode.updateClass(Class.setClassTree(cls_tree, inst_cls), node);

        // Instantiate the extends nodes.
        ClassTree.mapExtends(cls_tree,
          function instExtends(attributes = attributes, parent = par, visibility = ExtendsVisibility.PUBLIC));

        // Instantiate local components.
        ClassTree.applyLocalComponents(cls_tree,
          function instComponent(attributes = attributes, parent = par, scope = node));
      then
        ();

    case (Class.DERIVED_CLASS(), _)
      algorithm
        mod := Modifier.fromElement(InstNode.definition(node), InstNode.level(parent), InstNode.parent(node));
        mod := Modifier.merge(cls_mod, mod);

        attributes := mergeDerivedAttributes(attributes, cls.attributes, node);
        (base_node, attributes) := instClass(cls.baseClass, mod, attributes, parent);
        cls.baseClass := base_node;
        cls.attributes := attributes;
        node := InstNode.replaceClass(cls, node);
        updateComponentClass(parent, node);
      then
        ();

    case (Class.PARTIAL_BUILTIN(restriction = Restriction.EXTERNAL_OBJECT()), _)
      algorithm
        inst_cls := Class.INSTANCED_BUILTIN(cls.ty, cls.elements, {}, cls.restriction);
        node := InstNode.replaceClass(inst_cls, node);
        updateComponentClass(parent, node);
        instExternalObjectStructors(cls.ty, parent);
      then
        ();

    case (Class.PARTIAL_BUILTIN(), _)
      algorithm
        mod := Modifier.fromElement(InstNode.definition(node), InstNode.level(parent), InstNode.parent(node));
        mod := Modifier.merge(cls_mod, mod);

        type_attr := Modifier.toList(mod);
        inst_cls := Class.INSTANCED_BUILTIN(cls.ty, cls.elements, type_attr, cls.restriction);

        node := InstNode.replaceClass(inst_cls, node);
        updateComponentClass(parent, node);
      then
        ();

    // If a class has an instance of a encapsulating class, then the encapsulating
    // class will have been fully instantiated to allow lookup in it. This is a
    // rather uncommon case hopefully, so in that case just reinstantiate the class.
    case (Class.INSTANCED_CLASS(), _)
      algorithm
        node := InstNode.replaceClass(Class.NOT_INSTANTIATED(), node);
        node := expand(node);
        node := instClass(node, modifier, attributes, parent);
        updateComponentClass(parent, node);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown class.", sourceInfo());
      then
        ();

  end match;
end instClass;

function updateComponentClass
  "Sets the class instance of a component node."
  input output InstNode component;
  input InstNode cls;
algorithm
  if InstNode.isComponent(component) then
    component := InstNode.componentApply(component, Component.setClassInstance, cls);
  end if;
end updateComponentClass;

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
    Function.instFuncNode(constructor);
    Function.instFuncNode(destructor);
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

function instImport
  input Absyn.Import imp;
  input InstNode scope;
  input SourceInfo info;
  input output list<InstNode> elements = {};
algorithm
  elements := match imp
    local
      InstNode node;
      ClassTree tree;

    case Absyn.NAMED_IMPORT()
      algorithm
        node := Lookup.lookupImport(imp.path, scope, info);
        node := InstNode.rename(imp.name, node);
      then
        node :: elements;

    case Absyn.QUAL_IMPORT()
      algorithm
        node := Lookup.lookupImport(imp.path, scope, info);
      then
        node :: elements;

    case Absyn.UNQUAL_IMPORT()
      algorithm
        node := Lookup.lookupImport(imp.path, scope, info);
        node := instPackage(node);
        tree := Class.classTree(InstNode.getClass(node));

        () := match tree
          case ClassTree.FLAT_TREE()
            algorithm
              elements := listAppend(arrayList(tree.classes), elements);
              elements := listAppend(arrayList(tree.components), elements);
            then
              ();

          else
            algorithm
              Error.assertion(false, getInstanceName() + " got invalid class tree", sourceInfo());
            then
              ();
        end match;
      then
        elements;

  end match;
end instImport;

function modifyExtends
  input output InstNode extendsNode;
  input InstNode scope;
  input InstNode parent;
protected
  SCode.Element elem;
  Absyn.Path basepath;
  SCode.Mod smod;
  Modifier ext_mod;
  InstNode ext_node;
  SourceInfo info;
  ClassTree cls_tree;
algorithm
  cls_tree := Class.classTree(InstNode.getClass(extendsNode));
  ClassTree.mapExtends(cls_tree, function modifyExtends(scope = extendsNode, parent = parent));

  // Replace the node in the node type with the given scope, so that crefs found
  // in this extends are prefixed correctly.
  InstNodeType.BASE_CLASS(definition = elem) := InstNode.nodeType(extendsNode);
  extendsNode := InstNode.setNodeType(InstNodeType.BASE_CLASS(parent, elem), extendsNode);

  // Create a modifier from the extends.
  ext_mod := Modifier.fromElement(elem, InstNode.level(scope) + 1, scope);

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

  applyModifier(ext_mod, cls_tree, InstNode.name(extendsNode));
end modifyExtends;

type ExtendsVisibility = enumeration(PUBLIC, DERIVED_PROTECTED, PROTECTED);

function instExtends
  input output InstNode node;
  input Component.Attributes attributes;
  input InstNode parent;
  input ExtendsVisibility visibility;
protected
  Class cls;
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
          function instExtends(attributes = attributes, parent = parent, visibility = vis));

        ClassTree.applyLocalComponents(cls_tree,
          function instComponent(attributes = attributes, parent = node, scope = node));
      then
        ();

    case Class.DERIVED_CLASS()
      algorithm
        if vis == ExtendsVisibility.PUBLIC and InstNode.isProtectedBaseClass(node) then
          vis := ExtendsVisibility.DERIVED_PROTECTED;
        end if;

        node := instExtends(cls.baseClass, attributes, parent, vis);
      then
        ();

    else ();
  end match;
end instExtends;

function applyModifier
  input Modifier modifier;
  input output ClassTree cls;
  input String clsName;
protected
  list<Modifier> mods;
  Mutable<InstNode> node_ptr;
  InstNode node;
  Component comp;
algorithm
  mods := Modifier.toList(modifier);

  if listEmpty(mods) then
    return;
  end if;

  for mod in mods loop
    try
      node_ptr := ClassTree.lookupElementPtr(Modifier.name(mod), cls);
    else
      Error.addSourceMessage(Error.MISSING_MODIFIED_ELEMENT,
        {Modifier.name(mod), clsName}, Modifier.info(mod));
      fail();
    end try;

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

  ClassTree.copyModifiersToDups(cls);
end applyModifier;

function instComponent
  input InstNode node   "The component node to instantiate";
  input Component.Attributes attributes "Attributes to be propagated to the component.";
  input InstNode parent "The parent node of the component";
  input InstNode scope  "The class scope containing the component";
protected
  Component comp, inst_comp;
  SCode.Element def;
  InstNode scp, cls_node, comp_node;
  Class cls;
  Modifier mod, comp_mod;
  Binding binding, condition;
  Component.Attributes attr, cls_attr;
  list<Dimension> dims;
  SourceInfo info;
algorithm
  comp_node := InstNode.resolveOuter(node);
  comp := InstNode.component(comp_node);
  mod := Component.getModifier(comp);

  () := match (mod, comp)
    case (Modifier.REDECLARE(), Component.COMPONENT_DEF(definition = def))
      algorithm
        if not InstNode.isComponent(mod.element) then
          Error.addMultiSourceMessage(Error.INVALID_REDECLARE_AS,
            {"component", InstNode.name(comp_node), "class"},
            {InstNode.info(mod.element), InstNode.info(comp_node)});
        end if;

        checkOuterComponentMod(mod, comp, comp_node);
        // Create a modifier from the original declaration.
        comp_mod := Modifier.fromElement(def, InstNode.level(node), parent);
        // Merge it with any modifier from the redeclare.
        comp_mod := Modifier.merge(comp_mod, mod.mod);
        inst_comp := InstNode.component(mod.element);
        inst_comp := Component.setModifier(comp_mod, inst_comp);
        InstNode.updateComponent(inst_comp, comp_node);
        instComponent(comp_node, attributes, parent, InstNode.parent(mod.element));
      then
        ();

    case (_, Component.COMPONENT_DEF(definition = def as SCode.COMPONENT(info = info)))
      algorithm
        comp_mod := Modifier.fromElement(def, InstNode.level(node), parent);
        comp_mod := Modifier.merge(comp.modifier, comp_mod);
        checkOuterComponentMod(comp_mod, comp, comp_node);

        dims := list(Dimension.RAW_DIM(d) for d in def.attributes.arrayDims);
        binding := Modifier.binding(comp_mod);
        condition := Binding.fromAbsyn(def.condition, false, InstNode.level(node), parent, info);

        // Instantiate attributes and create the untyped components.
        attr := instComponentAttributes(def.attributes, def.prefixes, attributes, comp_node);
        inst_comp := Component.UNTYPED_COMPONENT(InstNode.EMPTY_NODE(), listArray(dims),
          binding, condition, attr, def.info);
        InstNode.updateComponent(inst_comp, comp_node);

        // Instantiate the type of the component.
        (cls_node, cls_attr) := instTypeSpec(def.typeSpec, comp_mod, attr, scope, comp_node, def.info);
        cls := InstNode.getClass(cls_node);

        Modifier.checkEach(comp_mod, listEmpty(dims) and not Class.hasDimensions(cls), InstNode.name(comp_node));

        cls_attr := updateComponentVariability(cls_attr, cls, cls_node);
        if not referenceEq(attr, cls_attr) then
          comp_node := InstNode.componentApply(comp_node, Component.setAttributes, cls_attr);
        end if;
      then
        ();

    else ();
  end match;
end instComponent;

function checkOuterComponentMod
  "Prints an error message and fails if it gets an outer component and a
   non-empty modifier."
  input Modifier mod;
  input Component comp;
  input InstNode node;
algorithm
  if not Modifier.isEmpty(mod) and Component.isOnlyOuter(comp) then
    Error.addSourceMessage(Error.OUTER_ELEMENT_MOD,
      {Modifier.toString(mod, printName = false), InstNode.name(node)}, InstNode.info(node));
    fail();
  end if;
end checkOuterComponentMod;

function instComponentAttributes
  input SCode.Attributes compAttr;
  input SCode.Prefixes compPrefs;
  input Component.Attributes outerAttributes;
  input InstNode node;
  output Component.Attributes attributes;
protected
  ConnectorType cty;
  Parallelism par;
  Variability var;
  Direction dir;
  InnerOuter io;
algorithm
  attributes := match (compAttr, compPrefs)
    case (SCode.Attributes.ATTR(
            connectorType = SCode.ConnectorType.POTENTIAL(),
            parallelism = SCode.Parallelism.NON_PARALLEL(),
            variability = SCode.Variability.VAR(),
            direction = Absyn.Direction.BIDIR()),
          SCode.Prefixes.PREFIXES(
            innerOuter = Absyn.InnerOuter.NOT_INNER_OUTER()))
      then NFComponent.DEFAULT_ATTR;

    else
      algorithm
        cty := Prefixes.connectorTypeFromSCode(compAttr.connectorType);
        par := Prefixes.parallelismFromSCode(compAttr.parallelism);
        var := Prefixes.variabilityFromSCode(compAttr.variability);
        dir := Prefixes.directionFromSCode(compAttr.direction);
        io  := Prefixes.innerOuterFromSCode(compPrefs.innerOuter);
      then
        Component.Attributes.ATTRIBUTES(cty, par, var, dir, io);
  end match;

  attributes := mergeComponentAttributes(outerAttributes, attributes, node);
end instComponentAttributes;

function mergeComponentAttributes
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
    dir := Prefixes.mergeDirection(outerAttr.direction, innerAttr.direction, node);
    attr := Component.Attributes.ATTRIBUTES(cty, par, var, dir, innerAttr.innerOuter);
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
algorithm
  if referenceEq(innerAttr, NFComponent.DEFAULT_ATTR) then
    attr := outerAttr;
  elseif referenceEq(outerAttr, NFComponent.DEFAULT_ATTR) then
    attr := innerAttr;
  else
    Component.Attributes.ATTRIBUTES(cty, par, var, dir, io) := outerAttr;
    cty := Prefixes.mergeConnectorType(cty, innerAttr.connectorType, node);
    var := Prefixes.variabilityMin(var, innerAttr.variability);
    dir := Prefixes.mergeDirection(dir, innerAttr.direction, node);
    attr := Component.Attributes.ATTRIBUTES(cty, par, var, dir, io);
  end if;
end mergeDerivedAttributes;

function updateComponentVariability
  input output Component.Attributes attr;
  input Class cls;
  input InstNode clsNode;
protected
  Variability var = attr.variability;
algorithm
  if referenceEq(attr, NFComponent.DEFAULT_ATTR) and
     Type.isDiscrete(Class.getType(cls, clsNode)) then
    attr := NFComponent.DISCRETE_ATTR;
  elseif var == Variability.CONTINUOUS and
     Type.isDiscrete(Class.getType(cls, clsNode)) then
    attr.variability := Variability.DISCRETE;
  end if;
end updateComponentVariability;

function instTypeSpec
  input Absyn.TypeSpec typeSpec;
  input Modifier modifier;
  input Component.Attributes attributes;
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
        (node, outAttributes) := instClass(node, modifier, attributes, parent);
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
  array<InstNode> local_comps;
  ClassTree cls_tree;
  Restriction res;
algorithm
  () := match cls
    case Class.EXPANDED_CLASS(elements = cls_tree)
      algorithm
        // Instantiate expressions in the extends nodes.
        for ext in ClassTree.getExtends(cls_tree) loop
          sections := instExpressions(ext, ext, sections);
        end for;

        // Instantiate expressions in the local components.
        ClassTree.applyLocalComponents(cls_tree,
          function instComponentExpressions(scope = scope));

        // Flatten the class tree so we don't need to deal with extends anymore.
        cls.elements := ClassTree.flatten(cls_tree);
        InstNode.updateClass(cls, node);

        // Instantiate local equation/algorithm sections.
        sections := instSections(node, scope, sections);

        inst_cls := Class.INSTANCED_CLASS(cls.elements, sections,
          Type.COMPLEX(node, ComplexType.CLASS()), cls.restriction);
        InstNode.updateClass(inst_cls, node);
      then
        ();

    case Class.DERIVED_CLASS()
      algorithm
        sections := instExpressions(cls.baseClass, scope, sections);

        if not listEmpty(cls.dims) then
          cls.dims := list(instDimension(d, InstNode.parent(node), InstNode.info(node))
            for d in cls.dims);
          InstNode.updateClass(cls, node);
        end if;
      then
        ();

    case Class.INSTANCED_BUILTIN()
      algorithm
        cls.attributes := list(instBuiltinAttribute(a) for a in cls.attributes);
        InstNode.updateClass(cls, node);
      then
        ();

    case Class.INSTANCED_CLASS() then ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got invalid class", sourceInfo());
      then
        fail();

  end match;
end instExpressions;

function instBuiltinAttribute
  input output Modifier attribute;
algorithm
  () := match attribute
    case Modifier.MODIFIER()
      algorithm
        attribute.binding := instBinding(attribute.binding);
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
  input InstNode scope;
protected
  InstNode node = InstNode.resolveOuter(component);
  Component c = InstNode.component(node);
  array<Dimension> dims, all_dims;
  list<Dimension> cls_dims;
  Integer len;
algorithm
  () := match c
    case Component.UNTYPED_COMPONENT(dimensions = dims)
      algorithm
        c.binding := instBinding(c.binding);
        c.condition := instBinding(c.condition);
        instExpressions(c.classInst, node);

        cls_dims := Class.getDimensions(InstNode.getClass(c.classInst));
        len := arrayLength(dims);

        if listEmpty(cls_dims) then
          // If we have no type dimensions, simply instantiate the component's dimensions.
          for i in 1:len loop
            dims[i] := instDimension(dims[i], scope, c.info);
          end for;
        else
          // If we have type dimensions, allocate space for them and add them to
          // the component's dimensions.
          all_dims := Dangerous.arrayCreateNoInit(len + listLength(cls_dims), Dimension.UNKNOWN());

          // Instantiate the component's dimensions.
          for i in 1:len loop
            all_dims[i] := instDimension(dims[i], scope, c.info);
          end for;

          // Add the already instantiated dimensions from the type.
          len := len + 1;
          for e in cls_dims loop
            all_dims[len] := e;
            len := len + 1;
          end for;

          // Update the dimensions in the component.
          c.dimensions := all_dims;
        end if;

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
        Binding.UNTYPED_BINDING(bind_exp, false, binding.scope, binding.originLevel, binding.info);

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

    case Absyn.Exp.INTEGER() then Expression.INTEGER(absynExp.value);
    case Absyn.Exp.REAL() then Expression.REAL(stringReal(absynExp.value));
    case Absyn.Exp.STRING() then Expression.STRING(absynExp.value);
    case Absyn.Exp.BOOL() then Expression.BOOLEAN(absynExp.value);

    case Absyn.Exp.CREF()
      then instCref(absynExp.componentRef, scope, info);

    case Absyn.Exp.ARRAY()
      algorithm
        expl := list(instExp(e, scope, info) for e in absynExp.arrayExp);
      then
        Expression.ARRAY(Type.UNKNOWN(), expl);

    case Absyn.Exp.MATRIX()
      algorithm
        expl := list(Expression.ARRAY(
            Type.UNKNOWN(), list(instExp(e, scope, info) for e in el))
          for el in absynExp.matrix);
      then
        Expression.ARRAY(Type.UNKNOWN(), expl);

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

    case Absyn.Exp.END() then Expression.END();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown expression", sourceInfo());
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
      algorithm
        if InstNode.isComponent(cref.node) then
          comp := InstNode.component(cref.node);

          crefExp := match comp
            case Component.ITERATOR()
              algorithm
                checkUnsubscriptable(cref.subscripts, cref.node, info);
              then
                Expression.CREF(Type.UNKNOWN(), ComponentRef.makeIterator(cref.node, comp.ty));

            case Component.ENUM_LITERAL()
              algorithm
                checkUnsubscriptable(cref.subscripts, cref.node, info);
              then
                comp.literal;

            else
              algorithm
                prefixed_cref := ComponentRef.fromNodeList(InstNode.scopeList(found_scope));
                prefixed_cref := if ComponentRef.isEmpty(prefixed_cref) then
                  cref else ComponentRef.append(cref, prefixed_cref);
              then
                Expression.CREF(Type.UNKNOWN(), prefixed_cref);

          end match;
        else
          ty := InstNode.getType(cref.node);

          ty := match ty
            case Type.BOOLEAN() then Type.ARRAY(ty, {Dimension.BOOLEAN()});
            case Type.ENUMERATION() then Type.ARRAY(ty, {Dimension.ENUM(ty)});
            else
              algorithm
                // This should be caught by lookupComponent, only type name classes
                // are allowed to be used where a component is expected.
                Error.assertion(false, getInstanceName() + " got unknown class node", sourceInfo());
              then
                fail();
          end match;

          crefExp := Expression.TYPENAME(ty);
        end if;
      then
        crefExp;

    else Expression.CREF(Type.UNKNOWN(), cref);
  end match;
end instCref;

function checkUnsubscriptable
  input list<Subscript> subscripts;
  input InstNode node;
  input SourceInfo info;
algorithm
  if not listEmpty(subscripts) then
    Error.addSourceMessage(Error.WRONG_NUMBER_OF_SUBSCRIPTS,
      {InstNode.name(node) + Subscript.toStringList(subscripts),
       String(listLength(subscripts)), "0"}, info);
    fail();
  end if;
end checkUnsubscriptable;

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

function instSections
  input InstNode node;
  input InstNode scope;
  input output Sections sections;
protected
  SCode.Element el = InstNode.definition(node);
  SCode.ClassDef def;
algorithm
  sections := match el
    case SCode.CLASS(classDef = SCode.PARTS())
      then instSections2(el.classDef, scope, sections);

    case SCode.CLASS(classDef = SCode.CLASS_EXTENDS(composition = def as SCode.PARTS()))
      then instSections2(def, scope, sections);

    else sections;
  end match;
end instSections;

function instSections2
  input SCode.ClassDef parts;
  input InstNode scope;
  input output Sections sections;
algorithm
  sections := match (parts, sections)
    local
      list<Equation> eq, ieq;
      list<list<Statement>> alg, ialg;
      SCode.ExternalDecl ext_decl;

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
        eq := instEquations(parts.normalEquationLst, scope, EquationScope.NORMAL);
        ieq := instEquations(parts.initialEquationLst, scope, EquationScope.INITIAL);
        alg := instAlgorithmSections(parts.normalAlgorithmLst, scope);
        ialg := instAlgorithmSections(parts.initialAlgorithmLst, scope);
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
  input EquationScope eqScope;
  output list<Equation> instEql;
algorithm
  instEql := list(instEquation(eq, scope, eqScope) for eq in scodeEql);
end instEquations;

function instEquation
  input SCode.Equation scodeEq;
  input InstNode scope;
  input EquationScope eqScope;
  output Equation instEq;
protected
  SCode.EEquation eq;
algorithm
  SCode.EQUATION(eEquation = eq) := scodeEq;
  instEq := instEEquation(eq, scope, eqScope);
end instEquation;

function instEEquations
  input list<SCode.EEquation> scodeEql;
  input InstNode scope;
  input EquationScope eqScope;
  output list<Equation> instEql;
algorithm
  instEql := list(instEEquation(eq, scope, eqScope) for eq in scodeEql);
end instEEquations;

function instEEquation
  input SCode.EEquation scodeEq;
  input InstNode scope;
  input EquationScope eqScope;
  output Equation instEq;
algorithm
  instEq := match scodeEq
    local
      Expression exp1, exp2, exp3;
      Option<Expression> oexp;
      list<Expression> expl;
      list<Equation> eql;
      list<tuple<Expression, list<Equation>>> branches;
      SourceInfo info;
      Binding binding;
      InstNode for_scope, iter;
      ComponentRef lhs_cr, rhs_cr;

    case SCode.EEquation.EQ_EQUALS(info = info)
      algorithm
        exp1 := instExp(scodeEq.expLeft, scope, info);
        exp2 := instExp(scodeEq.expRight, scope, info);

        if eqScope == EquationScope.WHEN and not checkLhsInWhen(exp1) then
          Error.addSourceMessage(Error.WHEN_EQ_LHS, {Expression.toString(exp1)}, info);
          fail();
        end if;
      then
        Equation.EQUALITY(exp1, exp2, Type.UNKNOWN(), info);

    case SCode.EEquation.EQ_CONNECT(info = info)
      algorithm
        if eqScope == EquationScope.WHEN then
          Error.addSourceMessage(Error.CONNECT_IN_WHEN,
            {Dump.printComponentRefStr(scodeEq.crefLeft),
             Dump.printComponentRefStr(scodeEq.crefRight)}, info);
          fail();
        end if;

        exp1 := instCref(scodeEq.crefLeft, scope, info);
        exp2 := instCref(scodeEq.crefRight, scope, info);
      then
        Equation.CONNECT(exp1, exp2, info);

    case SCode.EEquation.EQ_FOR(info = info)
      algorithm
        binding := Binding.fromAbsyn(scodeEq.range, false, 0, scope, info);
        binding := instBinding(binding);

        (for_scope, iter) := addIteratorToScope(scodeEq.index, binding, info, scope);
        eql := instEEquations(scodeEq.eEquationLst, for_scope, eqScope);
      then
        Equation.FOR(iter, eql, info);

    case SCode.EEquation.EQ_IF(info = info)
      algorithm
        // Instantiate the conditions.
        expl := list(instExp(c, scope, info) for c in scodeEq.condition);

        // Instantiate each branch and pair it up with a condition.
        branches := {};
        for branch in scodeEq.thenBranch loop
          eql := instEEquations(branch, scope, eqScope);
          exp1 :: expl := expl;
          branches := (exp1, eql) :: branches;
        end for;

        // Instantiate the else-branch, if there is one, and make it a branch
        // with condition true (so we only need a simple list of branches).
        if not listEmpty(scodeEq.elseBranch) then
          eql := instEEquations(scodeEq.elseBranch, scope, eqScope);
          branches := (Expression.BOOLEAN(true), eql) :: branches;
        end if;
      then
        Equation.IF(listReverse(branches), info);

    case SCode.EEquation.EQ_WHEN(info = info)
      algorithm
        if eqScope == EquationScope.WHEN then
          Error.addSourceMessageAndFail(Error.NESTED_WHEN, {}, info);
        elseif eqScope == EquationScope.INITIAL then
          Error.addSourceMessageAndFail(Error.INITIAL_WHEN, {}, info);
        end if;

        exp1 := instExp(scodeEq.condition, scope, info);
        eql := instEEquations(scodeEq.eEquationLst, scope, EquationScope.WHEN);
        branches := {(exp1, eql)};

        for branch in scodeEq.elseBranches loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          eql := instEEquations(Util.tuple22(branch), scope, EquationScope.WHEN);
          branches := (exp1, eql) :: branches;
        end for;
      then
        Equation.WHEN(branches, info);

    case SCode.EEquation.EQ_ASSERT(info = info)
      algorithm
        exp1 := instExp(scodeEq.condition, scope, info);
        exp2 := instExp(scodeEq.message, scope, info);
        exp3 := instExp(scodeEq.level, scope, info);
      then
        Equation.ASSERT(exp1, exp2, exp3, info);

    case SCode.EEquation.EQ_TERMINATE(info = info)
      algorithm
        exp1 := instExp(scodeEq.message, scope, info);
      then
        Equation.TERMINATE(exp1, info);

    case SCode.EEquation.EQ_REINIT(info = info)
      algorithm
        if eqScope <> EquationScope.WHEN then
          Error.addSourceMessage(Error.REINIT_NOT_IN_WHEN, {}, info);
          fail();
        end if;

        exp1 := instExp(scodeEq.cref, scope, info);
        exp2 := instExp(scodeEq.expReinit, scope, info);
      then
        Equation.REINIT(exp1, exp2, info);

    case SCode.EEquation.EQ_NORETCALL(info = info)
      algorithm
        exp1 := instExp(scodeEq.exp, scope, info);
      then
        Equation.NORETCALL(exp1, info);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown equation", sourceInfo());
      then
        fail();

  end match;
end instEEquation;

function instAlgorithmSections
  input list<SCode.AlgorithmSection> algorithmSections;
  input InstNode scope;
  output list<list<Statement>> statements;
algorithm
  statements := list(instAlgorithmSection(alg, scope) for alg in algorithmSections);
end instAlgorithmSections;

function instAlgorithmSection
  input SCode.AlgorithmSection algorithmSection;
  input InstNode scope;
  output list<Statement> statements;
algorithm
  statements := instStatements(algorithmSection.statements, scope);
end instAlgorithmSection;

function instStatements
  input list<SCode.Statement> scodeStmtl;
  input InstNode scope;
  output list<Statement> statements;
algorithm
  statements := list(instStatement(stmt, scope) for stmt in scodeStmtl);
end instStatements;

function instStatement
  input SCode.Statement scodeStmt;
  input InstNode scope;
  output Statement statement;
algorithm
  statement := match scodeStmt
    local
      Expression exp1, exp2, exp3;
      Option<Expression> oexp;
      list<Statement> stmtl;
      list<tuple<Expression, list<Statement>>> branches;
      SourceInfo info;
      Binding binding;
      InstNode for_scope, iter;

    case SCode.Statement.ALG_ASSIGN(info = info)
      algorithm
        exp1 := instExp(scodeStmt.assignComponent, scope, info);
        exp2 := instExp(scodeStmt.value, scope, info);
      then
        Statement.ASSIGNMENT(exp1, exp2, info);

    case SCode.Statement.ALG_FOR(info = info)
      algorithm
        binding := Binding.fromAbsyn(scodeStmt.range, false, 0, scope, info);
        binding := instBinding(binding);

        (for_scope, iter) := addIteratorToScope(scodeStmt.index, binding, info, scope);
        stmtl := instStatements(scodeStmt.forBody, for_scope);
      then
        Statement.FOR(iter, stmtl, info);

    case SCode.Statement.ALG_IF(info = info)
      algorithm
        branches := {};
        for branch in (scodeStmt.boolExpr, scodeStmt.trueBranch) :: scodeStmt.elseIfBranch loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          stmtl := instStatements(Util.tuple22(branch), scope);
          branches := (exp1, stmtl) :: branches;
        end for;

        stmtl := instStatements(scodeStmt.elseBranch, scope);
        branches := listReverse((Expression.BOOLEAN(true), stmtl) :: branches);
      then
        Statement.IF(branches, info);

    case SCode.Statement.ALG_WHEN_A(info = info)
      algorithm
        branches := {};
        for branch in scodeStmt.branches loop
          exp1 := instExp(Util.tuple21(branch), scope, info);
          stmtl := instStatements(Util.tuple22(branch), scope);
          branches := (exp1, stmtl) :: branches;
        end for;
      then
        Statement.WHEN(listReverse(branches), info);

    case SCode.Statement.ALG_ASSERT(info = info)
      algorithm
        exp1 := instExp(scodeStmt.condition, scope, info);
        exp2 := instExp(scodeStmt.message, scope, info);
        exp3 := instExp(scodeStmt.level, scope, info);
      then
        Statement.ASSERT(exp1, exp2, exp3, info);

    case SCode.Statement.ALG_TERMINATE(info = info)
      algorithm
        exp1 := instExp(scodeStmt.message, scope, info);
      then
        Statement.TERMINATE(exp1, info);

    case SCode.Statement.ALG_REINIT(info = info)
      algorithm
        Error.addSourceMessage(Error.REINIT_NOT_IN_WHEN, {}, info);
      then
        fail();

    case SCode.Statement.ALG_NORETCALL(info = info)
      algorithm
        exp1 := instExp(scodeStmt.exp, scope, info);
      then
        Statement.NORETCALL(exp1, info);

    case SCode.Statement.ALG_WHILE(info = info)
      algorithm
        exp1 := instExp(scodeStmt.boolExpr, scope, info);
        stmtl := instStatements(scodeStmt.whileBody, scope);
      then
        Statement.WHILE(exp1, stmtl, info);

    case SCode.Statement.ALG_RETURN() then Statement.RETURN(scodeStmt.info);
    case SCode.Statement.ALG_BREAK() then Statement.BREAK(scodeStmt.info);

    case SCode.Statement.ALG_FAILURE()
      algorithm
        stmtl := instStatements(scodeStmt.stmts, scope);
      then
        Statement.FAILURE(stmtl, scodeStmt.info);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown statement", sourceInfo());
      then
        fail();

  end match;
end instStatement;

function addIteratorToScope
  input String name;
  input Binding binding;
  input SourceInfo info;
  input output InstNode scope;
        output InstNode iterator;
protected
  Component iter_comp;
algorithm
  scope := InstNode.openImplicitScope(scope);
  iter_comp := Component.ITERATOR(Type.UNKNOWN(), binding);
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
      instComponent(n, NFComponent.DEFAULT_ATTR, node, node);

      // If the component's class has a missingInnerMessage annotation, use it
      // to give a diagnostic message.
      try
        Absyn.STRING(str) := SCode.getElementNamedAnnotation(
          InstNode.definition(InstNode.classScope(n)), "missingInnerMessage");
        Error.addSourceMessage(Error.MISSING_INNER_MESSAGE, {str}, InstNode.info(n));
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

annotation(__OpenModelica_Interface="frontend");
end NFInst;

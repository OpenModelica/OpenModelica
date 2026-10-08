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

encapsulated package NFInstanceAPI
  "The model-instance API: instantiate a class and dump what it looks like as
   JSON (issue #15219). Split out of NFApi so that a tool needing only this —
   the documentation generator, which renders icons and member tables from a
   model instance — does not link the backend. NFApi keeps the scripting
   entry points and passes SymbolTable's program in."

import Absyn;
import AbsynUtil;
import SCode;
import DAE;
import NFModifier.Modifier;
import JSON;

protected

import NFInst;
import Inst = NFInst;
import NFCall.Call;
import NFInstContext;
import NFModifier;
import NFBinding.Binding;
import NFComponent.Component;
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import Expression = NFExpression;
import Import = NFImport;
import NFClass.Class;
import NFInstNode;
import MutableWeak;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import Equation = NFEquation;
import NFType.Type;
import Subscript = NFSubscript;
import InstContext = NFInstContext;

import Absyn.Path;
import AbsynToSCode;
import Config;
import Dump;
import Error;
import ErrorExt;
import Mutable;
import ExecStat.execStat;
import FBuiltin;
import Flags;
import Global;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import MetaModelica.Dangerous.listReverseInPlace;
import Ceval = NFCeval;
import NFClassTree.ClassTree;
import NFPrefixes.{Variability, Purity};
import NFSections.Sections;
import Parser;
import Restriction = NFRestriction;
import SimplifyExp = NFSimplifyExp;
import Settings;
import Typing = NFTyping;
import UnorderedMap;
import Util;
import SCodeUtil;
import SCodeDump;
import ElementSource;
import InstSettings = NFInst.InstSettings;

constant InstContext.Type ANNOTATION_CONTEXT = intBitOr(NFInstContext.RELAXED, NFInstContext.ANNOTATION);
constant InstContext.Type INST_API_ANNOTATION_CONTEXT = intBitOr(ANNOTATION_CONTEXT, NFInstContext.INSTANCE_API);

public

function annotationProgram
  "The graphical annotation definitions, parsed from lib/omc. A copy of
   InteractiveUtil.modelicaAnnotationProgram, which lives in the backend."
  input String annotationVersion "1.x or 2.x or 3.x";
  output Absyn.Program program;
protected
  String filename;
algorithm
  filename := Settings.getInstallationDirectoryPath() +
              "/lib/omc/AnnotationsBuiltin_" +
              Util.stringReplaceChar(annotationVersion, ".", "_") +
              ".mo";
  program := Parser.parse(filename, "UTF-8");
end annotationProgram;

public function mkTop
  "The `top` scope the instance API instantiates in. `scodeProgram` is the
   already translated form of `absynProgram` when the caller has one — the
   scripting API passes SymbolTable's, which saves retranslating the whole
   library on every call."
  input Absyn.Program absynProgram;
  input Option<SCode.Program> scodeProgram = NONE();
  input String name;
  output SCode.Program program;
  output InstNode top;
protected
  SCode.Program scode_builtin, graphicProgramSCode;
  Absyn.Program placementProgram;
  list<tuple<Absyn.Program, tuple<SCode.Program, InstNode>>> cache;
  Boolean reuse;
algorithm
  cache := getGlobalRoot(Global.instNFNodeCacheIndex);
  // if absyn is the same, all fine, reuse
  reuse := if listEmpty(cache) then false else referenceEq(absynProgram, Util.tuple21(listHead(cache)));
  if reuse then
    (program, top) := Util.tuple22(listHead(cache));
    InstNode.clearGeneratedInners(top);
    // Nodes made from here on belong to the cached tree, so they have to be
    // rooted there rather than in whatever run was last to build a top node.
    MutableWeak.useRoots(InstNode.scopeRoots(top));
  else
    if not listEmpty(cache) then
      setGlobalRoot(Global.instNFNodeCacheIndex, {});
    end if;
    (_, scode_builtin) := FBuiltin.getInitialFunctions();
    if isSome(scodeProgram) then
      SOME(program) := scodeProgram;
    else
      program := AbsynToSCode.translateAbsyn2SCode(absynProgram);
    end if;
    program := listAppend(scode_builtin, program);
    placementProgram := annotationProgram(Config.getAnnotationVersion());
    graphicProgramSCode := AbsynToSCode.translateAbsyn2SCode(placementProgram);

    Inst.resetGlobalFlags();

    // Create a root node from the given top-level classes.
    top := NFInst.makeTopNode(program, graphicProgramSCode);

    if Flags.isSet(Flags.EXEC_STAT) then
      execStat("NFInstanceAPI.mkTop("+ name +")");
    end if;

    setGlobalRoot(Global.instNFNodeCacheIndex, {(absynProgram, (program, top))});
  end if;
end mkTop;

protected

uniontype InstanceTree
  record COMPONENT
    InstNode node;
    Option<Binding> binding;
    InstanceTree cls;
  end COMPONENT;

  record CLASS
    InstNode node;
    list<InstanceTree> elements;
    Boolean isExtends;
  end CLASS;

  record BUILTIN_BASE_CLASS
    String name;
  end BUILTIN_BASE_CLASS;

  record EMPTY
  end EMPTY;
end InstanceTree;

constant InstanceTree ENUM_BASE = InstanceTree.BUILTIN_BASE_CLASS("enumeration");


public function buildModelInstanceJSON
  "Instantiates the given model and builds the JSON structure describing the
   model instance. Shared by getModelInstance and getModelInstanceReference."
  input Absyn.Program absynProgram;
  input Option<SCode.Program> scodeProgram;
  input Absyn.Path classPath;
  input Absyn.Path contextPath;
  input String modifier;
  output JSON json;
protected
  InstNode top, cls_node;
  InstContext.Type context;
  InstanceTree inst_tree;
  InstSettings inst_settings;
  Modifier mod;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  context := InstContext.set(context, NFInstContext.INSTANCE_API);
  inst_settings := InstSettings.SETTINGS(mergeExtendsSections = false, resizableArrays = false);

  (_, top) := mkTop(absynProgram, scodeProgram, AbsynUtil.pathString(classPath));
  mod := parseModifier(modifier, top);
  cls_node := Inst.lookupRootClass(classPath, top, context);

  if SCodeUtil.isFunction(InstNode.definition(cls_node)) then
    context := InstContext.unset(context, NFInstContext.CLASS);
    context := InstContext.set(context, NFInstContext.FUNCTION);
  end if;

  if AbsynUtil.pathFirstIdent(contextPath) <> "__NoContext" then
    cls_node := InstNode.setNodeType(InstNodeType.ROOT_CLASS(NFInstNode.NO_SCOPE, SOME(contextPath)), cls_node);
  end if;

  cls_node := Inst.instantiateRootClass(cls_node, context, mod);
  execStat("Inst.instantiateRootClass");
  inst_tree := buildInstanceTree(cls_node);
  execStat("NFInstanceAPI.buildInstanceTree");
  Inst.instExpressions(cls_node, context = context, settings = inst_settings);
  Inst.updateImplicitVariability(cls_node, Flags.isSet(Flags.EVAL_PARAM), context);
  execStat("Inst.instExpressions");

  Typing.typeClassType(cls_node, NFBinding.EMPTY_BINDING, context, cls_node);
  Typing.typeComponents(cls_node, context);
  execStat("Typing.typeComponents");
  Typing.typeBindings(cls_node, context);
  execStat("Typing.typeBinding");

  json := dumpJSONInstanceTree(inst_tree, cls_node);
  execStat("NFInstanceAPI.dumpJSONInstanceTree");
end buildModelInstanceJSON;

public function buildModelInstanceAnnotationJSON
  "Instantiates the given model and builds the JSON structure describing its
   annotation. Shared by getModelInstanceAnnotation and
   getModelInstanceAnnotationReference."
  input Absyn.Program absynProgram;
  input Option<SCode.Program> scodeProgram;
  input Absyn.Path classPath;
  input list<String> filter;
  output JSON json;
protected
  InstNode top, cls_node;
  InstContext.Type context;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  context := InstContext.set(context, NFInstContext.INSTANCE_API);

  (_, top) := mkTop(absynProgram, scodeProgram, AbsynUtil.pathString(classPath));
  cls_node := Inst.lookupRootClass(classPath, top, context);
  cls_node := InstNode.resolveInner(cls_node);

  json := dumpJSONInstanceAnnotation(cls_node, filter);
end buildModelInstanceAnnotationJSON;

public function buildModelInstanceIconJSON
  input Absyn.Program absynProgram;
  input Option<SCode.Program> scodeProgram;
  input Absyn.Path classPath;
  output JSON json;
protected
  InstNode top;
algorithm
  (_, top) := mkTop(absynProgram, scodeProgram, AbsynUtil.pathString(classPath));
  json := iconJSONFromTop(top, classPath);
end buildModelInstanceIconJSON;

public function diagramJSONFromTop
  "What a diagram is drawn from: the class' own Diagram layer with its extends
   chain, every component it shows — inherited ones included — with its
   Placement and its type's Icon, and the connect equations with their Line
   annotations. Nothing is typed, only looked up and expanded, so this costs
   about what the icon dump costs."
  input InstNode top;
  input Absyn.Path classPath;
  output JSON json;
protected
  InstNode cls_node;
  InstContext.Type context;
  JSON components = JSON.emptyArray(), connections = JSON.emptyArray();
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  context := InstContext.set(context, NFInstContext.INSTANCE_API);

  cls_node := Inst.lookupRootClass(classPath, top, context);
  cls_node := InstNode.resolveInner(cls_node);

  json := dumpJSONInstanceAnnotation(cls_node, {"Diagram"}, dumpDerivedBase = true);
  (components, connections) := dumpJSONDiagramParts(cls_node, context, components, connections, 0);
  json := JSON.addPair("components", components, json);
  json := JSON.addPair("connections", connections, json);
end diagramJSONFromTop;

function dumpJSONDiagramParts
  "A class' components and connections, base classes' first so a derived
   component is drawn over an inherited one."
  input InstNode node;
  input InstContext.Type context;
  input output JSON components;
  input output JSON connections;
  input Integer depth;
protected
  InstNode ty_node;
  JSON e;
  SCode.Element def;
  list<SCode.Equation> eqs;
algorithm
  if depth > 16 then
    return;
  end if;

  for ext in ClassTree.getExtends(Class.classTree(InstNode.getClass(node))) loop
    (components, connections) :=
      dumpJSONDiagramParts(ext, context, components, connections, depth + 1);
  end for;

  def := InstNode.definition(node);

  for el in SCodeUtil.getClassElements(def) loop
    () := match el
      case SCode.Element.COMPONENT()
        algorithm
          try
            ty_node := Lookup.lookupClassName(AbsynUtil.typeSpecPath(el.typeSpec), node, context, el.info);
            ty_node := Inst.expand(ty_node, context);
            e := JSON.addPair("$kind", JSON.STRING("component"), JSON.makeNull());
            e := JSON.addPair("name", JSON.makeString(el.name), e);
            e := dumpJSONAnnotationOpt(el.comment.annotation_, node, {"Placement"}, false, e);
            e := JSON.addPair("type", diagramComponentIcon(ty_node), e);
            components := JSON.addElement(e, components);
          else
          end try;
        then ();

      else ();
    end match;
  end for;

  eqs := match def
    case SCode.Element.CLASS(classDef = SCode.ClassDef.PARTS(normalEquationLst = eqs)) then eqs;
    else {};
  end match;

  for eq in eqs loop
    () := match eq
      case SCode.Equation.EQ_CONNECT()
        algorithm
          e := dumpJSONAnnotationOpt(eq.comment.annotation_, node, {"Line"}, false, JSON.makeNull());
          if not JSON.isNull(e) then
            connections := JSON.addElement(e, connections);
          end if;
        then ();

      else ();
    end match;
  end for;
end dumpJSONDiagramParts;

public function builtinSCode
  "The builtin classes every top scope needs, so a caller assembling a universe
   from separately translated libraries prepends them once."
  output SCode.Program program;
algorithm
  (_, program) := FBuiltin.getInitialFunctions();
end builtinSCode;

public function builtinAbsyn
  "The builtin classes as they were parsed, for a caller documenting the
   OpenModelica package the compiler defines rather than instantiating it."
  output Absyn.Program program;
algorithm
  (program, _) := FBuiltin.getInitialFunctions();
end builtinAbsyn;

public function programSCode
  "One program's SCode. translateAbsyn2SCode carries nothing between top-level
   classes, so a caller holding many libraries may translate each separately
   and concatenate the results."
  input Absyn.Program absynProgram;
  output SCode.Program program;
algorithm
  program := AbsynToSCode.translateAbsyn2SCode(absynProgram);
end programSCode;

public function topFromSCode
  "A fresh top scope over already translated SCode, bypassing mkTop's reuse
   cache. Fresh is the point: what a scope expands is released when it is
   dropped, so a batch caller makes a new one per library instead of sharing one
   and growing without bound."
  input SCode.Program program;
  output InstNode top;
protected
  SCode.Program graphicProgramSCode;
algorithm
  graphicProgramSCode :=
    AbsynToSCode.translateAbsyn2SCode(annotationProgram(Config.getAnnotationVersion()));
  Inst.resetGlobalFlags();
  top := NFInst.makeTopNode(program, graphicProgramSCode);
end topFromSCode;

function diagramComponentIcon
  "The icon dump of a class one of a diagram's components has. A library draws
   the same few dozen types across thousands of diagrams, and each dump can cost
   an instantiation, so they are kept for as long as the top scope they belong
   to.

   Keying by the class' full path is exact rather than approximate here: the
   node was reached by looking the type name up and expanding it, without the
   component's own modifications, so the dump depends on the class alone."
  input InstNode ty_node;
  output JSON json;
protected
  Option<UnorderedMap<String, JSON>> cached;
  UnorderedMap<String, JSON> cache;
  String key;
algorithm
  cached := getGlobalRoot(Global.nfDiagramIconCache);
  cache := match cached
    case SOME(cache) then cache;
    else
      algorithm
        cache := UnorderedMap.new<JSON>(stringHashDjb2, stringEq);
        setGlobalRoot(Global.nfDiagramIconCache, SOME(cache));
      then
        cache;
  end match;

  key := AbsynUtil.pathString(InstNode.fullPath(ty_node));
  json := match UnorderedMap.get(key, cache)
    case SOME(json) then json;
    else
      algorithm
        json := dumpJSONInstanceAnnotation(ty_node, {"Icon"}, dumpDerivedBase = true);
        UnorderedMap.add(key, json, cache);
      then
        json;
  end match;
end diagramComponentIcon;

public function resolveNamesFromTop
  "What the type references of one class denote, fully qualified, as pairs of
   the name as written and the name it resolves to: the `extends` clauses and
   the base of a short class definition in `bases`, the components' types in
   `componentTypes` keyed by component name.

   This is the frontend's own lookup -- enclosing scopes, then base classes,
   then imports, with redeclares applied -- rather than a documentation
   generator's approximation of it. Pairs rather than a bare list so the caller
   matches on the name instead of trusting two orderings to agree."
  input InstNode top;
  input Absyn.Path classPath;
  output list<tuple<String, String>> bases = {};
  output list<tuple<String, String>> componentTypes = {};
protected
  InstNode cls_node;
  InstContext.Type context;
  SCode.Element def;
  SCode.ClassDef cdef;
  Absyn.Path reference;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  context := InstContext.set(context, NFInstContext.INSTANCE_API);

  try
    cls_node := Inst.lookupRootClass(classPath, top, context);
    cls_node := InstNode.resolveInner(cls_node);
    cls_node := Inst.expand(cls_node, context);
    def := InstNode.definition(cls_node);
  else
    return;
  end try;

  // A short class definition names its base in the class definition itself
  // rather than in an extends element.
  cdef := SCodeUtil.getClassDef(def);
  () := match cdef
    case SCode.ClassDef.DERIVED()
      algorithm
        reference := AbsynUtil.typeSpecPath(cdef.typeSpec);
        bases := resolveOne(reference, cls_node, context, SCodeUtil.elementInfo(def)) :: bases;
      then ();
    else ();
  end match;

  for el in SCodeUtil.getClassElements(def) loop
    () := match el
      case SCode.Element.EXTENDS()
        algorithm
          bases := resolveOne(el.baseClassPath, cls_node, context, el.info) :: bases;
        then ();

      case SCode.Element.COMPONENT()
        algorithm
          reference := AbsynUtil.typeSpecPath(el.typeSpec);
          componentTypes :=
            (el.name, Util.tuple22(resolveOne(reference, cls_node, context, el.info)))
              :: componentTypes;
        then ();

      else ();
    end match;
  end for;

  bases := listReverseInPlace(bases);
  componentTypes := listReverseInPlace(componentTypes);
end resolveNamesFromTop;

function resolveOne
  "The name as written, and what it resolves to -- empty when it does not."
  input Absyn.Path reference;
  input InstNode scope;
  input InstContext.Type context;
  input SourceInfo info;
  output tuple<String, String> resolved;
protected
  InstNode node;
  String qualified;
algorithm
  try
    node := Lookup.lookupClassName(reference, scope, context, info);
    node := Inst.expand(node, context);
    qualified := AbsynUtil.pathString(InstNode.fullPath(node));
  else
    qualified := "";
  end try;
  resolved := (AbsynUtil.pathString(reference), qualified);
end resolveOne;

public function clearTopScopeCache
  "Drop everything the last instantiation owns, so a batch caller can release a
   library when it is done with it. NF nodes refer upwards weakly: what owns
   them is `nfTopScope` and MutableWeak's set of identity cells, and makeTopNode
   replaces those only at the next instantiation."
algorithm
  setGlobalRoot(Global.instNFNodeCacheIndex, {});
  setGlobalRoot(Global.nfTopScope, {});
  setGlobalRoot(Global.nfDiagramIconCache, NONE());
  MutableWeak.clearRoots();
end clearTopScopeCache;

public function iconJSONFromTop
  "The icon dump for one class of an already built top scope. A caller doing a
   whole library — the documentation generator — builds `top` once and keeps it,
   rather than depending on mkTop's referenceEq cache holding across calls, and
   drops it when the library is done."
  input InstNode top;
  input Absyn.Path classPath;
  output JSON json;
protected
  InstNode cls_node;
  InstContext.Type context;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  context := InstContext.set(context, NFInstContext.INSTANCE_API);

  cls_node := Inst.lookupRootClass(classPath, top, context);
  cls_node := InstNode.resolveInner(cls_node);

  json := dumpJSONInstanceAnnotation(cls_node, {"Icon"}, dumpConnectors = true, dumpDerivedBase = true);
end iconJSONFromTop;

public function storeModelInstanceReference
  "Stores a boxed JSON value and returns a 1-based handle (0 on failure)."
  input JSON json;
  output Integer handle;
  external "C" handle = ModelInstanceReference_store(json) annotation(Library = "omcruntime");
end storeModelInstanceReference;

public function releaseModelInstanceReferenceImpl
  input Integer handle;
  output Boolean success;
  external "C" success = ModelInstanceReference_release(handle) annotation(Library = "omcruntime");
end releaseModelInstanceReferenceImpl;

function parseModifier
  input String modifierValue;
  input InstNode scope;
  output Modifier outMod;
protected
  Absyn.Modification amod;
  SCode.Mod smod;
algorithm
  try
    // stringMod parses a single modifier ("x(start = 1) = 2"), but here we want
    // to parse just a class modifier ("(x = 1, y = 2)"). So we add a dummy name
    // to the string and then extract the modifier from the ElementArg.
    Absyn.ElementArg.MODIFICATION(modification = SOME(amod)) :=
      Parser.stringMod("dummy" + modifierValue);

    // Then translate the Absyn mod to a Modifier, using the given scope (it
    // doesn't matter much which scope it is, it just needs some scope or the
    // instantiation will fail later).
    smod := AbsynToSCode.translateMod(SOME(amod),
      SCode.Final.NOT_FINAL(), SCode.Each.NOT_EACH(), NONE(), Absyn.dummyInfo);
    outMod := Modifier.create(smod, "", NFModifier.ModifierScope.COMPONENT(""), scope, 0);
  else
    outMod := Modifier.NOMOD();
  end try;
end parseModifier;

function buildInstanceTree
  input InstNode node;
  input Boolean isDerived = false;
  output InstanceTree tree;
protected
  InstNode cls_node;
  Class cls;
  ClassTree cls_tree;
  list<InstanceTree> elems;
algorithm
  cls_node := InstNode.resolveInner(node);
  cls := InstNode.getClass(cls_node);

  if not isDerived and Class.isOnlyBuiltin(cls) and not Class.isEnumeration(cls) then
    tree := InstanceTree.EMPTY();
    return;
  end if;

  cls_tree := Class.classTree(cls);

  tree := match (cls, cls_tree)
    case (Class.EXPANDED_DERIVED(), _)
      algorithm
        elems := {buildInstanceTree(cls.baseClass, isDerived = true)};
      then
        InstanceTree.CLASS(node, elems, isDerived);

    case (_, ClassTree.INSTANTIATED_TREE())
      algorithm
        elems := buildInstanceTreeElements(InstNode.definition(cls_node), cls_tree);

        if InstNode.isRootClass(node) then
          elems := buildInstanceTreeGeneratedInners(cls_tree, elems);
        end if;
      then
        InstanceTree.CLASS(node, elems, isDerived);

    case (_, ClassTree.FLAT_TREE())
      then InstanceTree.CLASS(node, if InstNode.isEnumerationType(cls_node) then {ENUM_BASE} else {}, isDerived);

    else
      algorithm
        Error.terminate(getInstanceName() + " got unknown class tree", sourceInfo());
      then
        fail();
  end match;
end buildInstanceTree;

function buildInstanceTreeElements
  input SCode.Element classDefinition;
  input ClassTree classTree;
  output list<InstanceTree> elements = {};
protected
  list<SCode.Element> scode_elems;
  array<Mutable<InstNode>> clss, comps;
  array<InstNode> exts;
  Integer cls_index = 1, comp_index = 1, ext_index = 1;
  InstanceTree tree;
  list<Integer> local_comps;
  InstNode node;
algorithm
  ClassTree.INSTANTIATED_TREE(classes = clss, components = comps, exts = exts,
    localComponents = local_comps) := classTree;
  scode_elems := SCodeUtil.getClassElements(classDefinition);

  if not listEmpty(local_comps) then
    comp_index :: local_comps := local_comps;
  end if;

  for e in scode_elems loop
    elements := match e
      case SCode.Element.EXTENDS()
        algorithm
          tree := buildInstanceTree(exts[ext_index], isDerived = true);
          ext_index := ext_index + 1;
        then
          tree :: elements;

      case SCode.Element.CLASS()
        guard SCodeUtil.isElementReplaceable(e)
        algorithm
          while InstNode.name(Mutable.access(clss[cls_index])) <> e.name loop
            cls_index := cls_index + 1;
          end while;

          tree := InstanceTree.CLASS(Mutable.access(clss[cls_index]), {}, false);
          cls_index := cls_index + 1;
        then
          tree :: elements;

      case SCode.Element.COMPONENT()
        algorithm
          while true loop
            node := Mutable.access(comps[comp_index]);

            if InstNode.name(node) == e.name and not InstNode.isGeneratedInner(node) then
              break;
            end if;

            comp_index :: local_comps := local_comps;
          end while;
          //while InstNode.name(Mutable.access(comps[comp_index])) <> e.name loop
          //  comp_index :: local_comps := local_comps;
          //end while;

          tree := buildInstanceTreeComponent(node);
          elements := tree :: elements;

          if not listEmpty(local_comps) then
            comp_index :: local_comps := local_comps;
          end if;
        then
          elements;

      else elements;
    end match;
  end for;

  elements := listReverseInPlace(elements);
end buildInstanceTreeElements;

function buildInstanceTreeGeneratedInners
  input ClassTree classTree;
  input list<InstanceTree> elements;
  output list<InstanceTree> outElements;
protected
  array<Mutable<InstNode>> comps;
  list<InstanceTree> elems = {};
algorithm
  ClassTree.INSTANTIATED_TREE(components = comps) := classTree;

  for i in arrayLength(comps):-1:1 loop
    if InstNode.isGeneratedInner(Mutable.access(comps[i])) then
      elems := buildInstanceTreeComponent(Mutable.access(comps[i])) :: elems;
    else
      break;
    end if;
  end for;

  if listEmpty(elems) then
    outElements := elements;
  else
    outElements := listAppend(elements, elems);
  end if;
end buildInstanceTreeGeneratedInners;

function buildInstanceTreeComponent
  input InstNode node;
  output InstanceTree tree;
protected
  InstNode inner_node, cls_node;
  InstanceTree cls;
  Binding binding;
  Option<Binding> opt_binding;
algorithm
  inner_node := InstNode.resolveOuter(node);
  cls_node := InstNode.classScope(inner_node);

  if InstNode.isEmpty(cls_node) then
    cls := InstanceTree.EMPTY();
  else
    cls := buildInstanceTree(cls_node);
  end if;

  if InstNode.isComponent(inner_node) then
    binding := Component.getBinding(InstNode.component(inner_node));
    opt_binding := if Binding.isBound(binding) then SOME(binding) else NONE();
  else
    opt_binding := NONE();
  end if;

  tree := InstanceTree.COMPONENT(node, opt_binding, cls);
end buildInstanceTreeComponent;

function dumpJSONInstanceTree
  input InstanceTree tree;
  input InstNode scope;
  input Boolean root = true;
  input Boolean isDeleted = false;
  input Boolean isExtends = false;
  output JSON json = JSON.makeNull();
protected
  InstNode node;
  list<InstanceTree> elems;
  Sections sections;
  Option<SCode.Comment> cmt;
  SCode.Element def;
algorithm
  InstanceTree.CLASS(node = node, elements = elems) := tree;
  node := InstNode.resolveOuter(node);
  def := InstNode.definition(node);
  cmt := SCodeUtil.getElementComment(def);

  json := JSON.addPair("name", dumpJSONNodePath(node), json);

  json := JSON.addPairNotNull("dims", dumpJSONClassDims(node, def), json);
  json := JSON.addPair("restriction",
    JSON.makeString(SCodeDump.restrictionStringPP(SCodeUtil.getClassRestriction(def))), json);

  json := JSON.addPairNotNull("prefixes", dumpJSONClassPrefixes(def, InstNode.parent(node)), json);

  json := dumpJSONCommentOpt(cmt, scope, json);

  json := JSON.addPairNotNull("elements", dumpJSONElements(elems, node, isDeleted), json);

  if not isDeleted then
    json := dumpJSONImports(node, json);
    sections := Class.getSections(InstNode.getClass(node));
    json := dumpJSONEquations(sections, node, json);
  end if;

  json := JSON.addPair("source", JSON.dumpJSONSourceInfo(InstNode.info(node)), json);
end dumpJSONInstanceTree;

function dumpJSONInstanceAnnotation
  input InstNode node;
  input list<String> filter;
  input Boolean dumpConnectors = false "the class' own connector components";
  input Boolean dumpDerivedBase = false "a short class definition's base class";
  output JSON json = JSON.makeNull();
protected
  Option<SCode.Comment> cmt;
  SCode.Annotation ann;
  JSON j;
  InstNode scope = node;
  InstContext.Type context;
  Boolean annotation_is_literal = true;
  Boolean any_element = false;
  SCode.Element def;
  Class cls;
algorithm
  Inst.expand(node, NFInstContext.RELAXED);
  def := InstNode.definition(node);
  json := JSON.addPair("name", dumpJSONNodePath(node), json);

  json := JSON.addPair("restriction",
    JSON.makeString(Restriction.toString(InstNode.restriction(node))), json);

  json := JSON.addPairNotNull("prefixes", dumpJSONClassPrefixes(def, InstNode.parent(node)), json);

  cls := InstNode.getClass(node);
  j := JSON.emptyArray();

  // Class.classTree looks through a derived class, so its extends array is the
  // base's: listing both would count the base's chain twice.
  if dumpDerivedBase then
    () := match cls
      case Class.EXPANDED_DERIVED()
        algorithm
          j := JSON.addElement(dumpJSONInstanceAnnotationExtends(cls.baseClass, filter, true), j);
          any_element := true;
        then ();

      case Class.TYPED_DERIVED()
        algorithm
          j := JSON.addElement(dumpJSONInstanceAnnotationExtends(cls.baseClass, filter, true), j);
          any_element := true;
        then ();

      else ();
    end match;
  end if;

  if not any_element then
    for ext in ClassTree.getExtends(Class.classTree(cls)) loop
      j := JSON.addElement(dumpJSONInstanceAnnotationExtends(ext, filter, dumpDerivedBase), j);
      any_element := true;
    end for;
  end if;

  if dumpConnectors then
    (j, any_element) := dumpJSONInstanceAnnotationConnectors(node, j, any_element);
  end if;

  if any_element then
    json := JSON.addPair("elements", j, json);
  end if;

  cmt := SCodeUtil.getElementComment(InstNode.definition(node));

  cmt := match cmt
    case SOME(SCode.Comment.COMMENT(annotation_ = SOME(ann as SCode.Annotation.ANNOTATION())))
      algorithm
        if not listEmpty(filter) then
          ann.modification := SCodeUtil.filterSubMods(ann.modification,
            function SCodeUtil.filterGivenSubModNames(namesToKeep = filter));
        end if;

        annotation_is_literal := SCodeUtil.onlyLiteralsInMod(ann.modification);
      then
        if SCodeUtil.isEmptyMod(ann.modification) then NONE() else SOME(SCode.Comment.COMMENT(SOME(ann), NONE()));

    else NONE();
  end match;

  // Instantiate the scope if the annotation contains component references that
  // we need to be able to look up.
  if not annotation_is_literal then
    ErrorExt.setCheckpoint(getInstanceName());
    try
      context := InstContext.set(NFInstContext.CLASS, NFInstContext.RELAXED);
      scope := InstNode.makeRootClass(scope);
      scope := Inst.instantiate(scope, context = context, instPartial = true);
      Inst.insertGeneratedInners(scope, InstNode.topScope(scope), context);
      Inst.instExpressions(scope, context = context, settings = NFInst.DEFAULT_SETTINGS);
    else
    end try;
    ErrorExt.rollBack(getInstanceName());
  end if;

  json := dumpJSONCommentOpt(cmt, scope, json, failOnError = true);
end dumpJSONInstanceAnnotation;

function dumpJSONInstanceAnnotationConnectors
  "One element per locally declared connector component: name, Placement and
   the type's icon annotation. A model instance nests the inherited ones under
   the extends element, so only the class' own belong here."
  input InstNode node;
  input output JSON json;
  input output Boolean any;
protected
  InstContext.Type context = InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  InstNode ty_node;
  JSON e;
algorithm
  for el in SCodeUtil.getClassElements(InstNode.definition(node)) loop
    () := match el
      case SCode.Element.COMPONENT()
        algorithm
          try
            ty_node := Lookup.lookupClassName(AbsynUtil.typeSpecPath(el.typeSpec), node, context, el.info);

            if SCodeUtil.isConnector(SCodeUtil.getClassRestriction(InstNode.definition(ty_node))) then
              ty_node := Inst.expand(ty_node, context);
              e := JSON.addPair("$kind", JSON.STRING("component"), JSON.makeNull());
              e := JSON.addPair("name", JSON.makeString(el.name), e);
              e := dumpJSONAnnotationOpt(el.comment.annotation_, node, {"Placement"}, false, e);
              e := JSON.addPair("type",
                dumpJSONInstanceAnnotation(ty_node, {"Icon"}, dumpDerivedBase = true), e);
              json := JSON.addElement(e, json);
              any := true;
            end if;
          else
          end try;
        then ();

      else ();
    end match;
  end for;
end dumpJSONInstanceAnnotationConnectors;

function dumpJSONInstanceAnnotationExtends
  input InstNode ext;
  input list<String> filter;
  input Boolean dumpDerivedBase = false;
  output JSON json = JSON.makeNull();
algorithm
  json := JSON.addPair("$kind", JSON.STRING("extends"), json);
  json := JSON.addPair("baseClass",
    dumpJSONInstanceAnnotation(ext, filter, dumpDerivedBase = dumpDerivedBase), json);
end dumpJSONInstanceAnnotationExtends;

function dumpJSONNodePath
  input InstNode node;
  input Boolean ignoreBaseClass = false;
  output JSON json = dumpJSONPath(InstNode.enclosingScopePath(node, ignoreBaseClass = ignoreBaseClass));
end dumpJSONNodePath;

function dumpJSONNodeEnclosingPath
  input InstNode node;
  output JSON json = dumpJSONPath(InstNode.enclosingScopePath(node, ignoreRedeclare = true));
end dumpJSONNodeEnclosingPath;

function dumpJSONPath
  input Absyn.Path path;
  output JSON json = JSON.makeString(AbsynUtil.pathString(path));
end dumpJSONPath;

function dumpJSONElements
  input list<InstanceTree> elements;
  input InstNode scope;
  input Boolean isDeleted;
  output JSON json = JSON.makeNull();
protected
  JSON j;
algorithm
  if isDeleted then
    for e in elements loop
      j := match e
        case InstanceTree.CLASS(isExtends = true) then dumpJSONExtends(e, isDeleted);
        else JSON.makeNull();
      end match;

      json := JSON.addElementNotNull(j, json);
    end for;
  else
    for e in elements loop
      j := match e
        case InstanceTree.CLASS(isExtends = true) then dumpJSONExtends(e, isDeleted);
        case InstanceTree.CLASS() then dumpJSONReplaceableClass(e.node, scope);
        case InstanceTree.COMPONENT() then dumpJSONComponent(e.node, e.binding, e.cls);
        case InstanceTree.BUILTIN_BASE_CLASS() then dumpJSONBuiltinBaseClass(e.name);
        else JSON.makeNull();
      end match;

      json := JSON.addElementNotNull(j, json);
    end for;
  end if;
end dumpJSONElements;

function dumpJSONExtends
  input InstanceTree ext;
  input Boolean isDeleted;
  output JSON json = JSON.makeNull();
protected
  InstNode node;
  Class cls;
  SCode.Element cls_def, ext_def;
algorithm
  InstanceTree.CLASS(node = node) := ext;
  cls_def := InstNode.definition(node);
  SOME(ext_def) := InstNode.extendsDefinition(node);

  json := JSON.addPair("$kind", JSON.STRING("extends"), json);
  json := dumpJSONSCodeMod(getExtendsModifier(ext_def, node), node, json);
  json := dumpJSONCommentOpt(SCodeUtil.getElementComment(ext_def), node, json);

  cls := InstNode.getClass(node);
  if Class.isOnlyBuiltin(cls) and not Class.isEnumeration(cls) then
    json := JSON.addPair("baseClass", JSON.makeString(InstNode.name(node)), json);
  else
    json := JSON.addPair("baseClass", dumpJSONInstanceTree(ext, node, root = false, isDeleted = isDeleted, isExtends = true), json);
  end if;
end dumpJSONExtends;

function dumpJSONBuiltinBaseClass
  input String name;
  output JSON json = JSON.makeNull();
algorithm
  json := JSON.addPair("$kind", JSON.STRING("extends"), json);
  json := JSON.addPair("baseClass", JSON.makeString(name), json);
end dumpJSONBuiltinBaseClass;

function getExtendsModifier
  input SCode.Element definition;
  input InstNode node;
  output SCode.Mod mod;
algorithm
  mod := match definition
    case SCode.EXTENDS() then definition.modifications;
    case SCode.CLASS() then SCodeUtil.elementMod(InstNode.definition(InstNode.getDerivedNode(node, recursive = false)));
    else SCode.NOMOD();
  end match;
end getExtendsModifier;

function dumpJSONReplaceableClass
  input InstNode cls;
  input InstNode scope;
  output JSON json = JSON.makeNull();
protected
  SCode.Element elem;
  InstNode node;
algorithm
  node := InstNode.getRedeclaredNode(cls);
  elem := InstNode.definition(node);
  json := dumpJSONSCodeClass(elem, scope, node, true, json);
  json := JSON.addPair("source", JSON.dumpJSONSourceInfo(InstNode.info(node)), json);
end dumpJSONReplaceableClass;

function dumpJSONComponent
  input InstNode component;
  input Option<Binding> originalBinding;
  input InstanceTree cls;
  output JSON json = JSON.makeNull();
protected
  InstNode node, scope, ty_node;
  Component comp;
  SCode.Element elem;
  Boolean is_constant;
  Absyn.Path path;
algorithm
  node := InstNode.resolveOuter(component);
  comp := InstNode.component(node);
  elem := InstNode.definition(node);
  scope := InstNode.parent(node);

  json := JSON.addPair("$kind", JSON.STRING("component"), json);
  json := JSON.addPair("name", JSON.makeString(InstNode.name(node)), json);

  () := match (comp, elem)
    case (Component.COMPONENT(), SCode.Element.COMPONENT())
      guard Component.isDeleted(comp)
      algorithm
        json := JSON.addPair("type", dumpJSONComponentType(cls, node, comp.ty, isDeleted = true), json);
        json := dumpJSONSCodeMod(elem.modifications, scope, json);
        json := JSON.addPair("condition", JSON.makeBoolean(false), json);
        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes, scope), json);
        json := dumpJSONComment(elem.comment, scope, json);
      then
        ();

    case (Component.INVALID_COMPONENT(), SCode.Element.COMPONENT())
      algorithm
        json := JSON.addPair("type", dumpJSONComponentType(cls, node, Component.getType(comp)), json);
        json := dumpJSONSCodeMod(elem.modifications, scope, json);
        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes, scope), json);
        json := dumpJSONComment(elem.comment, scope, json);
        json := JSON.addPair("$error", JSON.makeString(comp.errors), json);
      then
        ();

    case (Component.COMPONENT(), SCode.Element.COMPONENT())
      algorithm
        json := JSON.addPair("type", dumpJSONComponentType(cls, node, comp.ty), json);

        if Type.isArray(comp.ty) then
          json := JSON.addPair("dims",
            dumpJSONDims(elem.attributes.arrayDims, Type.arrayDims(comp.ty)), json);
        end if;

        json := dumpJSONSCodeMod(elem.modifications, scope, json);

        is_constant := comp.attributes.variability <= Variability.PARAMETER and
                       Binding.purity(comp.binding) == Purity.PURE;
        if Binding.isExplicitlyBound(comp.binding) then
          json := JSON.addPair("value", dumpJSONBinding(comp.binding, originalBinding, evaluate = is_constant), json);
        end if;

        if Binding.isBound(comp.condition) then
          json := JSON.addPair("condition", dumpJSONBinding(comp.condition), json);
        end if;

        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes, scope), json);
        json := dumpJSONComment(comp.comment, scope, json);

        if InstNode.isGeneratedInner(node) then
          json := JSON.addPair("generated", JSON.makeBoolean(true), json);
        end if;
      then
        ();

    case (Component.COMPONENT_DEF(), SCode.Element.COMPONENT())
      guard AbsynUtil.isOnlyOuter(elem.prefixes.innerOuter)
      algorithm
        path := AbsynUtil.typeSpecPath(elem.typeSpec);

        try
          ty_node := Lookup.lookupName(path, scope, InstContext.set(NFInstContext.RELAXED, NFInstContext.FAST_LOOKUP),
            checkAccessViolations = false);
          json := JSON.addPair("type", dumpJSONSCodeClass(InstNode.definition(ty_node), ty_node, InstNode.resolveInner(component), isRedeclare = false), json);
        else
          json := JSON.addPair("type", dumpJSONPath(path), json);
        end try;

        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes, scope), json);
        json := dumpJSONComment(elem.comment, scope, json);
        //json := JSON.addPair("inner", dumpJSONPath(InstNode.scopePath(InstNode.resolveInner(component))), json);
      then
        ();

    else
      algorithm
        Error.terminate(getInstanceName() + " got unknown component " +
          InstNode.name(node), sourceInfo());
      then
        fail();
  end match;
end dumpJSONComponent;

function dumpJSONComponentType
  input InstanceTree cls;
  input InstNode node;
  input Type ty;
  input Boolean isDeleted = false;
  output JSON json;
algorithm
  json := match (cls, Type.arrayElementType(ty))
    case (_, Type.ENUMERATION()) then dumpJSONEnumType(cls, node);
    case (_, Type.UNKNOWN()) then dumpJSONSCodeElementType(InstNode.definition(node));
    case (InstanceTree.CLASS(), _) then dumpJSONInstanceTree(cls, node, isDeleted = isDeleted);
    else dumpJSONTypeName(ty);
  end match;
end dumpJSONComponentType;

function dumpJSONSCodeElementType
  input SCode.Element elem;
  output JSON json = JSON.makeNull();
algorithm
  () := match elem
    case SCode.Element.COMPONENT()
      algorithm
        json := JSON.addPair("name", dumpJSONPath(AbsynUtil.typeSpecPath(elem.typeSpec)), json);
        json := JSON.addPair("missing", JSON.makeBoolean(true), json);
      then
        ();

    else ();
  end match;
end dumpJSONSCodeElementType;

function dumpJSONEnumType
  input InstanceTree tree;
  input InstNode enumNode;
  output JSON json;
protected
  InstNode node = InstNode.resolveInner(InstNode.classScope(enumNode));
  SCode.Element def;
  array<InstNode> comps;
  JSON json_elems;
  list<InstanceTree> elems;
algorithm
  def := InstNode.definition(node);

  json := JSON.makeNull();
  json := JSON.addPair("name", dumpJSONNodePath(node), json);
  json := JSON.addPairNotNull("dims", dumpJSONClassDims(node, def), json);
  json := JSON.addPair("restriction",
    JSON.makeString(SCodeDump.restrictionStringPP(SCodeUtil.getClassRestriction(def))), json);
  json := dumpJSONCommentOpt(SCodeUtil.getElementComment(def), node, json);

  InstanceTree.CLASS(elements = elems) := tree;
  json_elems := dumpJSONElements(elems, node, false);

  comps := ClassTree.getComponents(Class.classTree(InstNode.getClass(node)));
  json_elems := dumpJSONEnumTypeLiterals(comps, InstNode.parent(node), json_elems);
  json := JSON.addPair("elements", json_elems, json);

  json := JSON.addPair("source", JSON.dumpJSONSourceInfo(InstNode.info(node)), json);
end dumpJSONEnumType;

function dumpJSONEnumTypeLiterals
  input array<InstNode> literals;
  input InstNode scope;
  input output JSON json = JSON.emptyArray();
algorithm
  for i in 6:arrayLength(literals) loop
    json := JSON.addElement(dumpJSONEnumTypeLiteral(literals[i], scope), json);
  end for;
end dumpJSONEnumTypeLiterals;

function dumpJSONEnumTypeLiteral
  input InstNode node;
  input InstNode scope;
  output JSON json = JSON.makeNull();
algorithm
  json := JSON.addPair("$kind", JSON.STRING("component"), json);
  json := JSON.addPair("name", JSON.makeString(InstNode.name(node)), json);
  json := dumpJSONComment(Component.comment(InstNode.component(node)), scope, json);
end dumpJSONEnumTypeLiteral;

function dumpJSONTypeName
  input Type ty;
  output JSON json;
algorithm
  json := JSON.makeString(Type.toString(Type.arrayElementType(ty)));
end dumpJSONTypeName;

function dumpJSONBinding
  input Binding binding;
  input Option<Binding> originalBinding = NONE();
  input Boolean evaluate = true;
  output JSON json = JSON.makeNull();
protected
  Expression exp;
  Binding bind = binding;
  InstContext.Type context;
algorithm
  // If the binding has been evaluated by the frontend, try to use the original
  // binding that we saved when building the instance tree instead.
  if isSome(originalBinding) and Binding.isEvaluated(binding) then
    try
      context := InstContext.set(NFInstContext.RELAXED, NFInstContext.INSTANCE_API);
      bind := Inst.instBinding(Util.getOption(originalBinding), context);
      bind := Typing.typeBinding(bind, context);
    else
    end try;
  end if;

  exp := Binding.getExp(bind);
  exp := Expression.map(exp, Expression.expandSplitIndices);
  json := JSON.addPair("binding", Expression.toJSON(exp), json);

  if evaluate and not Expression.isLiteral(exp) then
    ErrorExt.setCheckpoint(getInstanceName());
    try
      exp := Ceval.evalExp(exp, Ceval.EvalTarget.new(Absyn.dummyInfo, NFInstContext.INSTANCE_API));
      exp := Expression.map(exp, Expression.expandSplitIndices);
      json := JSON.addPair("value", Expression.toJSON(exp), json);
    else
    end try;
    ErrorExt.rollBack(getInstanceName());
  end if;
end dumpJSONBinding;

function dumpJSONClassDims
  input InstNode node;
  input SCode.Element element;
  output JSON json;
protected
  Type ty;
  list<Absyn.Subscript> absyn_dims;
algorithm
  ty := InstNode.getType(node);

  if Type.isArray(ty) then
    absyn_dims := match element
      case SCode.Element.CLASS(classDef = SCode.ClassDef.DERIVED(typeSpec =
          Absyn.TypeSpec.TPATH(arrayDim = SOME(absyn_dims))))
        then absyn_dims;

      else {};
    end match;

    json := dumpJSONDims(absyn_dims, Type.arrayDims(ty));
  else
    json := JSON.makeNull();
  end if;
end dumpJSONClassDims;

function dumpJSONDims
  input list<Absyn.Subscript> absynDims;
  input list<Dimension> typedDims;
  output JSON json = JSON.makeNull();
protected
  JSON ty_json;
algorithm
  json := JSON.addPairNotNull("absyn", dumpJSONAbsynDims(absynDims), json);

  ty_json := JSON.makeNull();
  for d in typedDims loop
    ty_json := JSON.addElement(JSON.makeString(Dimension.toString(d)), ty_json);
  end for;

  json := JSON.addPairNotNull("typed", ty_json, json);
end dumpJSONDims;

function dumpJSONAbsynDims
  input list<Absyn.Subscript> dims;
  output JSON json = JSON.makeNull();
algorithm
  for d in dims loop
    json := JSON.addElement(JSON.makeString(Dump.printSubscriptStr(d)), json);
  end for;
end dumpJSONAbsynDims;

function dumpJSONAttributes
  input SCode.Attributes attrs;
  input SCode.Prefixes prefs;
  input InstNode scope;
  output JSON json;
protected
  String s;
algorithm
  json := dumpJSONSCodePrefixes(prefs, scope);

  s := SCodeDump.connectorTypeStr(attrs.connectorType);
  if not stringEmpty(s) then
    json := JSON.addPair("connector", JSON.makeString(s), json);
  end if;

  s := SCodeDump.unparseVariability(attrs.variability);
  if not stringEmpty(s) then
    json := JSON.addPair("variability", JSON.makeString(s), json);
  end if;

  if AbsynUtil.isInput(attrs.direction) then
    json := JSON.addPair("direction", JSON.STRING("input"), json);
  elseif AbsynUtil.isOutput(attrs.direction) then
    json := JSON.addPair("direction", JSON.STRING("output"), json);
  end if;
end dumpJSONAttributes;

function dumpJSONSCodePrefixes
  input SCode.Prefixes prefixes;
  input InstNode scope;
  output JSON json = JSON.makeNull();
algorithm
  if not SCodeUtil.visibilityBool(prefixes.visibility) then
    json := JSON.addPair("public", JSON.makeBoolean(false), json);
  end if;

  if SCodeUtil.finalBool(prefixes.finalPrefix) then
    json := JSON.addPair("final", JSON.makeBoolean(true), json);
  end if;

  if AbsynUtil.isInner(prefixes.innerOuter) then
    json := JSON.addPair("inner", JSON.makeBoolean(true), json);
  end if;

  if AbsynUtil.isOuter(prefixes.innerOuter) then
    json := JSON.addPair("outer", JSON.makeBoolean(true), json);
  end if;

  json := JSON.addPairNotNull("replaceable",
    dumpJSONReplaceable(prefixes.replaceablePrefix, scope), json);

  if SCodeUtil.redeclareBool(prefixes.redeclarePrefix) then
    json := JSON.addPair("redeclare", JSON.makeBoolean(true), json);
  end if;
end dumpJSONSCodePrefixes;

function dumpJSONClassPrefixes
  input SCode.Element element;
  input InstNode scope;
  output JSON json;
protected
  SCode.ClassDef cdef;
algorithm
  json := match element
    case SCode.CLASS(classDef = cdef, prefixes = _)
      algorithm
        json := match cdef
          case SCode.ClassDef.DERIVED() then dumpJSONAttributes(cdef.attributes, element.prefixes, scope);
          else dumpJSONSCodePrefixes(element.prefixes, scope);
        end match;

        if SCodeUtil.partialBool(element.partialPrefix) then
          json := JSON.addPair("partial", JSON.makeBoolean(true), json);
        end if;

        if SCodeUtil.encapsulatedBool(element.encapsulatedPrefix) then
          json := JSON.addPair("encapsulated", JSON.makeBoolean(true), json);
        end if;
      then
        json;

    else JSON.makeNull();
  end match;
end dumpJSONClassPrefixes;

function dumpJSONReplaceable
  input SCode.Replaceable repl;
  input InstNode scope;
  output JSON json;
protected
  SCode.ConstrainClass cc;
algorithm
  json := match repl
    case SCode.Replaceable.REPLACEABLE(cc = SOME(cc))
      algorithm
        json := JSON.makeNull();
        json := JSON.addPair("constrainedby", dumpJSONPath(cc.constrainingClass), json);
        json := dumpJSONSCodeMod(cc.modifier, scope, json);
        json := dumpJSONCommentOpt(SOME(cc.comment), scope, json);
      then
        json;

    case SCode.Replaceable.REPLACEABLE() then JSON.makeBoolean(true);
    else JSON.makeNull();
  end match;
end dumpJSONReplaceable;

function dumpJSONCommentOpt
  input Option<SCode.Comment> cmtOpt;
  input InstNode scope;
  input output JSON json;
  input Boolean dumpComment = true;
  input Boolean dumpAnnotation = true;
  input Boolean failOnError = false;
algorithm
  if isSome(cmtOpt) then
    json := dumpJSONComment(Util.getOption(cmtOpt), scope, json, dumpComment, dumpAnnotation, failOnError);
  end if;
end dumpJSONCommentOpt;

function dumpJSONComment
  input SCode.Comment cmt;
  input InstNode scope;
  input output JSON json;
  input Boolean dumpComment = true;
  input Boolean dumpAnnotation = true;
  input Boolean failOnError = false;
algorithm
  if isSome(cmt.comment) and dumpComment then
    json := JSON.addPair("comment", JSON.makeString(Util.getOption(cmt.comment)), json);
  end if;

  if dumpAnnotation then
    json := dumpJSONAnnotationOpt(cmt.annotation_, scope, {}, failOnError, json);
  end if;
end dumpJSONComment;

function dumpJSONCommentAnnotation
  input Option<SCode.Comment> cmtOpt;
  input InstNode scope;
  input output JSON json;
  input list<String> filter = {};
  input Boolean failOnError = false;
protected
  SCode.Comment cmt;
algorithm
  if isSome(cmtOpt) then
    SOME(cmt) := cmtOpt;
    json := dumpJSONAnnotationOpt(cmt.annotation_, scope, filter, failOnError, json);
  end if;
end dumpJSONCommentAnnotation;

function dumpJSONAnnotationOpt
  input Option<SCode.Annotation> annOpt;
  input InstNode scope;
  input list<String> filter;
  input Boolean failOnError;
  input output JSON json;
protected
  SCode.Annotation ann;
algorithm
  if isSome(annOpt) then
    SOME(ann) := annOpt;
    json := JSON.addPair("annotation", dumpJSONAnnotationMod(ann.modification, scope, filter, failOnError), json);
  end if;
end dumpJSONAnnotationOpt;

function dumpJSONAnnotationMod
  input SCode.Mod mod;
  input InstNode scope;
  input list<String> filter;
  input Boolean failOnError;
  output JSON json;
algorithm
  json := match mod
    case SCode.Mod.MOD()
      then dumpJSONAnnotationSubMods(mod.subModLst, scope, filter, failOnError);

    else JSON.makeNull();
  end match;
end dumpJSONAnnotationMod;

function dumpJSONAnnotationSubMods
  input list<SCode.SubMod> subMods;
  input InstNode scope;
  input list<String> filter;
  input Boolean failOnError;
  output JSON json = JSON.makeNull();
algorithm
  for m in subMods loop
    if listEmpty(filter) or List.contains(filter, m.ident, stringEq) then
      json := dumpJSONAnnotationSubMod(m, scope, failOnError, json);
    end if;
  end for;
end dumpJSONAnnotationSubMods;

function dumpJSONAnnotationSubMod
  input SCode.SubMod subMod;
  input InstNode scope;
  input Boolean failOnError;
  input output JSON json;
protected
  String name;
  SCode.Mod mod;
  Absyn.Exp absyn_binding;
  JSON j;
algorithm
  SCode.SubMod.NAMEMOD(ident = name, mod = mod) := subMod;

  () := match (name, mod)
    case ("choices", SCode.Mod.MOD())
      algorithm
        j := dumpJSONChoicesAnnotation(mod.subModLst, scope, mod.info, failOnError);
        json := JSON.addPairNotNull(name, j, json);
      then
        ();

    case (_, SCode.Mod.MOD(binding = SOME(absyn_binding)))
      algorithm
        j := dumpJSONAnnotationExp(absyn_binding, scope, mod.info, failOnError);
        json := JSON.addPair(name, j, json);
      then
        ();

    case (_, SCode.Mod.MOD())
      algorithm
        json := JSON.addPair(name, dumpJSONAnnotationSubMods(mod.subModLst, scope, {}, failOnError), json);
      then
        ();

    case (_, SCode.Mod.NOMOD())
      algorithm
        json := JSON.addPair(name, JSON.emptyListObject(), json);
      then
        ();

    else ();
  end match;
end dumpJSONAnnotationSubMod;

function dumpJSONAnnotationExp
  input Absyn.Exp absynExp;
  input InstNode scope;
  input SourceInfo info;
  input Boolean failOnError;
  output JSON json;
protected
  JSON j;
algorithm
  json := match absynExp
    case Absyn.Exp.INTEGER() then JSON.makeInteger(absynExp.value);
    case Absyn.Exp.REAL() then JSON.makeNumber(stringReal(absynExp.value));
    case Absyn.Exp.STRING() then JSON.makeString(absynExp.value);
    case Absyn.Exp.BOOL() then JSON.makeBoolean(absynExp.value);

    // For non-literal arrays, dump each element separately to avoid
    // invalidating the whole array expression if any element contains invalid
    // expressions.
    case Absyn.Exp.ARRAY()
      guard not AbsynUtil.isLiteralExp(absynExp)
      algorithm
        json := JSON.emptyArray(listLength(absynExp.arrayExp));
        for e in absynExp.arrayExp loop
          j := dumpJSONAnnotationExp(e, scope, info, failOnError);
          json := JSON.addElement(j, json);
        end for;
      then
        json;

    else dumpJSONAnnotationExp2(absynExp, scope, info, failOnError);
  end match;
end dumpJSONAnnotationExp;

function dumpJSONAnnotationExp2
  input Absyn.Exp absynExp;
  input InstNode scope;
  input SourceInfo info;
  input Boolean failOnError;
  output JSON json;
protected
  Expression exp;
algorithm
  ErrorExt.setCheckpoint(getInstanceName());
  try
    exp := Inst.instExp(absynExp, scope, INST_API_ANNOTATION_CONTEXT, info);
    exp := Typing.typeExp(exp, INST_API_ANNOTATION_CONTEXT, info);
    exp := SimplifyExp.simplify(exp);
    json := Expression.toJSON(exp);
  else
    if failOnError then
      fail();
    end if;

    json := JSON.makeNull();
    json := JSON.addPair("$error", JSON.makeString(ErrorExt.printCheckpointMessagesStr()), json);
    json := JSON.addPair("value", dumpJSONAbsynExpression(absynExp), json);
  end try;
  ErrorExt.delCheckpoint(getInstanceName());
end dumpJSONAnnotationExp2;



function dumpJSONAbsynExpression
  input Absyn.Exp exp;
  output JSON json;
protected
  Integer i;
  String r;
algorithm
  json := match exp
    case Absyn.Exp.INTEGER() then JSON.makeInteger(exp.value);
    case Absyn.Exp.REAL() then JSON.makeNumber(stringReal(exp.value));
    case Absyn.Exp.CREF() then dumpJSONAbsynCref(exp.componentRef);
    case Absyn.Exp.STRING() then JSON.makeString(exp.value);
    case Absyn.Exp.BOOL() then JSON.makeBoolean(exp.value);

    case Absyn.Exp.UNARY(op = Absyn.Operator.UMINUS(), exp = Absyn.Exp.INTEGER(value = i))
      then JSON.makeInteger(-i);

    case Absyn.Exp.UNARY(op = Absyn.Operator.UMINUS(), exp = Absyn.Exp.REAL(value = r))
      then JSON.makeNumber(-stringReal(r));

    case Absyn.Exp.CALL()
      algorithm
        json := JSON.makeNull();
        json := JSON.addPair("$kind", JSON.STRING("call"), json);
        json := JSON.addPair("name", dumpJSONAbsynCref(exp.function_), json);
        json := dumpJSONAbsynFunctionArgs(exp.functionArgs, json);
      then
        json;

    case Absyn.Exp.ARRAY()
      algorithm
        json := JSON.emptyArray(listLength(exp.arrayExp));
        for e in exp.arrayExp loop
          json := JSON.addElement(dumpJSONAbsynExpression(e), json);
        end for;
      then
        json;

    else JSON.makeString(Dump.printExpStr(AbsynUtil.stripCommentExpressions(exp, true)));
  end match;
end dumpJSONAbsynExpression;

function dumpJSONAbsynCref
  input Absyn.ComponentRef cref;
  output JSON json;
algorithm
  json := JSON.makeString(Dump.printComponentRefStr(cref));
end dumpJSONAbsynCref;

function dumpJSONAbsynFunctionArgs
  input Absyn.FunctionArgs args;
  input output JSON json;
protected
  JSON json_args;
algorithm
  () := match args
    case Absyn.FunctionArgs.FUNCTIONARGS()
      algorithm
        if not listEmpty(args.args) then
          json_args := JSON.makeNull();
          for arg in args.args loop
            json_args := JSON.addElement(dumpJSONAbsynExpression(arg), json_args);
          end for;

         json := JSON.addPair("args", json_args, json);
        end if;

        if not listEmpty(args.argNames) then
          json_args := JSON.makeNull();
          for arg in args.argNames loop
            json_args := JSON.addPair(arg.argName, dumpJSONAbsynExpression(arg.argValue), json_args);
          end for;

          json := JSON.addPair("namedArgs", json_args, json);
        end if;
      then
        ();

    else ();
  end match;
end dumpJSONAbsynFunctionArgs;

function dumpJSONImports
  input InstNode node;
  input output JSON json;
protected
  InstNode n = node;
  array<Import> imps;
  list<Import> resolved_imps;
  JSON json_imp, json_imp_array;
algorithm
  json_imp_array := JSON.makeNull();

  while not InstNode.isEmpty(n) loop
    imps := ClassTree.getImports(Class.classTree(InstNode.getClass(n)));

    if not arrayEmpty(imps) then
      resolved_imps := Import.resolveList(imps);
      resolved_imps := listReverseInPlace(resolved_imps);

      for imp in resolved_imps loop
        () := match imp
          case Import.RESOLVED_IMPORT()
            algorithm
              json_imp := JSON.makeNull();
              json_imp := JSON.addPair("path", dumpJSONPath(InstNode.fullPath(InstNode.borrow(imp.node))), json_imp);

              if not stringEmpty(imp.shortName) then
                json_imp := JSON.addPair("shortName", JSON.makeString(imp.shortName), json_imp);
              end if;

              json_imp_array := JSON.addElement(json_imp, json_imp_array);
            then
              ();

          else ();
        end match;
      end for;
    end if;

    n := InstNode.parent(n);
  end while;

  json := JSON.addPairNotNull("imports", json_imp_array, json);
end dumpJSONImports;

function dumpJSONEquations
  input Sections sections;
  input InstNode scope;
  input output JSON json;
protected
  list<Equation> connections, transitions, initial_states;
  JSON j;
  InstContext.Type context;
algorithm
  (connections, transitions, initial_states) := sortEquations(Sections.equations(sections));
  context := InstContext.set(NFInstContext.CLASS, NFInstContext.RELAXED);
  transitions := list(Typing.typeEquation(e, context) for e in transitions);
  initial_states := list(Typing.typeEquation(e, context) for e in initial_states);

  j := dumpJSONConnections(connections, scope);
  json := JSON.addPairNotNull("connections", j, json);

  j := dumpJSONStateCalls(initial_states, scope);
  json := JSON.addPairNotNull("initialStates", j, json);

  j := dumpJSONStateCalls(transitions, scope);
  json := JSON.addPairNotNull("transitions", j, json);
end dumpJSONEquations;

function sortEquations
  input list<Equation> equations;
  input output list<Equation> connections = {};
  input output list<Equation> transitions = {};
  input output list<Equation> initialStates = {};
algorithm
  for eq in listReverse(equations) loop
    () := match eq
      case Equation.CONNECT()
        algorithm
          connections := eq :: connections;
        then
          ();

      case Equation.FOR()
        algorithm
          (connections, transitions, initialStates) :=
            sortEquations(eq.body, connections, transitions, initialStates);
        then
          ();

      case Equation.IF()
        algorithm
          for b in eq.branches loop
            () := match b
              case Equation.Branch.BRANCH()
                algorithm
                  (connections, transitions, initialStates) :=
                    sortEquations(b.body, connections, transitions, initialStates);
                then
                  ();

              else ();
            end match;
          end for;
        then
          ();

      case Equation.NORETCALL()
        algorithm
          if Expression.isCallNamed(eq.exp, "transition") then
            transitions := eq :: transitions;
          elseif Expression.isCallNamed(eq.exp, "initialState") then
            initialStates := eq :: initialStates;
          end if;
        then
          ();

      else ();
    end match;
  end for;
end sortEquations;

function dumpJSONConnections
  input list<Equation> connections;
  input InstNode scope;
  output JSON json = JSON.makeNull();
algorithm
  for conn in connections loop
    json := JSON.addElement(dumpJSONConnection(conn, scope), json);
  end for;
end dumpJSONConnections;

function dumpJSONConnection
  input Equation connEq;
  input InstNode scope;
  output JSON json = JSON.makeNull();
protected
  Expression lhs, rhs;
  DAE.ElementSource src;
algorithm
  Equation.CONNECT(lhs = lhs, rhs = rhs, source = src) := connEq;
  json := JSON.addPair("lhs", Expression.toJSON(lhs), json);
  json := JSON.addPair("rhs", Expression.toJSON(rhs), json);
  json := dumpJSONCommentAnnotation(ElementSource.getOptComment(src), scope, json);
end dumpJSONConnection;

function dumpJSONStateCalls
  input list<Equation> callEqs;
  input InstNode scope;
  output JSON json = JSON.makeNull();
algorithm
  for eq in callEqs loop
    json := JSON.addElement(dumpJSONStateCall(eq, scope), json);
  end for;
end dumpJSONStateCalls;

function dumpJSONStateCall
  input Equation callEq;
  input InstNode scope;
  output JSON json = JSON.makeNull();
protected
  Call call;
  list<Expression> args;
  DAE.ElementSource src;
  JSON j;
algorithm
  () := match callEq
    case Equation.NORETCALL(exp = Expression.CALL(call = call as Call.TYPED_CALL(arguments = args)), source = src)
      algorithm
        j := JSON.emptyArray(listLength(args));
        for arg in args loop
          j := JSON.addElement(Expression.toJSON(arg), j);
        end for;
        json := JSON.addPair("arguments", j, json);
        json := dumpJSONCommentAnnotation(ElementSource.getOptComment(src), scope, json);
      then
        ();

    else ();
  end match;
end dumpJSONStateCall;

function dumpJSONReplaceableElements
  input InstNode clsNode;
  output JSON json = JSON.makeNull();
protected
  ClassTree cls_tree;
  JSON j;
algorithm
  cls_tree := Class.classTree(InstNode.getClass(clsNode));

  for c in ClassTree.getComponents(cls_tree) loop
    if InstNode.isReplaceable(c) then
      j := JSON.makeNull();
      j := JSON.addPair("name", JSON.makeString(InstNode.name(c)), j);
      j := JSON.addPair("type", dumpJSONTypeName(InstNode.getType(c)), j);
      json := JSON.addElement(j, json);
    end if;
  end for;

  for c in ClassTree.getClasses(cls_tree) loop
    if InstNode.isReplaceable(c) then
      json := JSON.addElement(JSON.makeString(InstNode.name(c)), json);
    end if;
  end for;
end dumpJSONReplaceableElements;

function dumpJSONSCodeMod
  input SCode.Mod mod;
  input InstNode scope;
  input output JSON json;
protected
  JSON j;
algorithm
  j := dumpJSONSCodeMod_impl(mod, scope);
  json := JSON.addPairNotNull("modifiers", j, json);
end dumpJSONSCodeMod;

function dumpJSONSCodeMod_impl
  input SCode.Mod mod;
  input InstNode scope;
  input Boolean isChoices = false;
  output JSON json = JSON.makeNull();
protected
  JSON binding_json;
algorithm
  () := match mod
    case SCode.Mod.MOD()
      algorithm
        for m in mod.subModLst loop
          json := JSON.addPair(m.ident, dumpJSONSCodeMod_impl(m.mod, scope), json);
        end for;

        if SCodeUtil.finalBool(mod.finalPrefix) then
          json := JSON.addPair("final", JSON.makeBoolean(true), json);
        end if;

        if SCodeUtil.eachBool(mod.eachPrefix) then
          json := JSON.addPair("each", JSON.makeBoolean(true), json);
        end if;

        if isChoices and isSome(mod.comment) then
          json := JSON.addPair("comment", JSON.makeString(Util.getOption(mod.comment)), json);
        end if;

        if isSome(mod.binding) then
          binding_json := JSON.makeString(Dump.printExpStr(AbsynUtil.stripCommentExpressions(Util.getOption(mod.binding), true)));

          if JSON.isNull(json) then
            json := binding_json;
          else
            json := JSON.addPair("$value", binding_json, json);
          end if;
        end if;
      then
        ();

    case SCode.Mod.REDECL()
      algorithm
        if SCodeUtil.finalBool(mod.finalPrefix) then
          json := JSON.addPair("final", JSON.makeBoolean(true), json);
        end if;

        if SCodeUtil.eachBool(mod.eachPrefix) then
          json := JSON.addPair("each", JSON.makeBoolean(true), json);
        end if;

        json := JSON.addPair("$value", dumpJSONSCodeElement(mod.element, scope), json);
      then
        ();

    else ();
  end match;
end dumpJSONSCodeMod_impl;

function dumpJSONRedeclareType
  input SCode.Element element;
  input InstNode scope;
  input output JSON json;
protected
  Absyn.Path path;
  InstContext.Type context;
  InstNode cls;
algorithm
  () := matchcontinue element
    case SCode.Element.COMPONENT()
      algorithm
        path := AbsynUtil.typeSpecPath(element.typeSpec);
        context := InstContext.set(NFInstContext.RELAXED, NFInstContext.FAST_LOOKUP);
        cls := Lookup.lookupName(path, scope, context, checkAccessViolations = false);
        json := JSON.addPair("$type", dumpJSONNodePath(cls), json);
      then
        ();

    else ();
  end matchcontinue;
end dumpJSONRedeclareType;

function dumpJSONSCodeElement
  input SCode.Element element;
  input InstNode scope;
  input output JSON json = JSON.makeNull();
algorithm
  json := match element
    case SCode.Element.COMPONENT()
      algorithm
        json := JSON.addPair("$kind", JSON.STRING("component"), json);
        json := JSON.addPair("name", JSON.makeString(element.name), json);
        json := JSON.addPair("type", dumpJSONPath(AbsynUtil.typeSpecPath(element.typeSpec)), json);
        json := JSON.addPairNotNull("dims", dumpJSONDims(element.attributes.arrayDims, {}), json);
        json := dumpJSONSCodeMod(element.modifications, scope, json);
        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(element.attributes, element.prefixes, scope), json);

        if isSome(element.condition) then
          json := JSON.addPair("condition", dumpJSONAbsynExpression(Util.getOption(element.condition)), json);
        end if;

        json := dumpJSONComment(element.comment, scope, json);
      then
        json;

    case SCode.Element.CLASS()
      then dumpJSONSCodeClass(element, InstNode.EMPTY_NODE(), scope, false, json);

    else json;
  end match;
end dumpJSONSCodeElement;

function dumpJSONSCodeType
  input Absyn.Path path;
  input InstNode scope;
  input output JSON json;
protected
  InstNode ty_node;
algorithm
  try
    ty_node := Lookup.lookupName(path, scope, InstContext.set(NFInstContext.RELAXED, NFInstContext.FAST_LOOKUP),
      checkAccessViolations = false);
    json := JSON.addPair("type", dumpJSONSCodeClass(InstNode.definition(ty_node), ty_node, scope, isRedeclare = false), json);
  else
    json := JSON.addPair("type", dumpJSONPath(path), json);
  end try;
end dumpJSONSCodeType;

function dumpJSONSCodeClass
  input SCode.Element element;
  input InstNode node;
  input InstNode scope;
  input Boolean isRedeclare;
  input output JSON json = JSON.makeNull();
algorithm
  () := match element
    case SCode.CLASS()
      algorithm
        json := JSON.addPair("$kind", JSON.STRING("class"), json);

        if InstNode.isEmpty(node) or isRedeclare then
          json := JSON.addPair("name", JSON.makeString(element.name), json);
        else
          json := JSON.addPair("name", dumpJSONNodeEnclosingPath(node), json);
        end if;

        json := JSON.addPair("restriction",
          JSON.makeString(SCodeDump.restrictionStringPP(element.restriction)), json);
        json := JSON.addPairNotNull("prefixes", dumpJSONClassPrefixes(element, scope), json);
        json := dumpJSONSCodeClassDef(element.classDef, scope, isRedeclare, json);
        json := dumpJSONComment(element.cmt, scope, json, dumpAnnotation = not isRedeclare);

        if isRedeclare then
          json := dumpJSONCommentAnnotation(SOME(element.cmt), scope, json,
            {"Dialog", "choices", "choicesAllMatching"});
        end if;

        if not isRedeclare then
          json := dumpJSONSCodeTypeExtends(node, scope, json);
        end if;
      then
        ();
  end match;
end dumpJSONSCodeClass;

function dumpJSONSCodeTypeExtends
  input InstNode node;
  input InstNode scope;
  input output JSON json;
protected
  InstNode expanded_node;
  array<InstNode> exts;
  JSON json_elements, json_ext;
algorithm
  if InstNode.isEmpty(node) then
    return;
  end if;

  try
    expanded_node := Inst.expand(node, NFInstContext.RELAXED);
    exts := ClassTree.getExtends(Class.classTree(InstNode.getClass(expanded_node)));

    if not arrayEmpty(exts) then
      json_elements := JSON.makeNull();

      for ext in exts loop
        json_ext := JSON.makeNull();
        json_ext := JSON.addPair("$kind", JSON.STRING("extends"), json_ext);
        json_ext := JSON.addPair("baseClass", dumpJSONSCodeClass(InstNode.definition(ext), ext, scope, false), json_ext);
        json_elements := JSON.addElement(json_ext, json_elements);
      end for;

      json := JSON.addPair("elements", json_elements, json);
    end if;
  else
  end try;
end dumpJSONSCodeTypeExtends;

function dumpJSONSCodeClassDef
  input SCode.ClassDef classDef;
  input InstNode scope;
  input Boolean qualifyPath;
  input output JSON json;
protected
  Absyn.Path path;
  Option<list<Absyn.Subscript>> odims;
  InstNode derivedNode;
algorithm
  () := match classDef
    case SCode.ClassDef.DERIVED(typeSpec = Absyn.TypeSpec.TPATH(path = path, arrayDim = odims))
      algorithm
        if qualifyPath then
          try
            derivedNode := Lookup.lookupName(path, scope, NFInstContext.RELAXED, false);
            json := JSON.addPair("baseClass", dumpJSONNodeEnclosingPath(derivedNode), json);
          else
          end try;
        else
          json := JSON.addPair("baseClass", dumpJSONPath(path), json);
        end if;

        if isSome(odims) then
          json := JSON.addPairNotNull("dims", dumpJSONDims(Util.getOption(odims), {}), json);
        end if;

        json := dumpJSONSCodeMod(classDef.modifications, scope, json);
      then
        ();

    case SCode.ClassDef.CLASS_EXTENDS()
      algorithm
        json := dumpJSONSCodeMod(classDef.modifications, scope, json);
      then
        ();

    else ();
  end match;
end dumpJSONSCodeClassDef;

function dumpJSONChoicesAnnotation
  input list<SCode.SubMod> mods;
  input InstNode scope;
  input SourceInfo info;
  input Boolean failOnError;
  output JSON json = JSON.makeNull();
protected
  SCode.SubMod smod;
  list<SCode.SubMod> choices, others;
  JSON j;
algorithm
  choices := list(m for m guard m.ident == "choice" in mods);
  others := list(m for m guard m.ident <> "choice" in mods);

  if not listEmpty(choices) then
    j := JSON.emptyArray(listLength(choices));

    for m in choices loop
      m := match m.mod
        case SCode.Mod.MOD(binding = NONE(), subModLst = {smod}) then smod;
        else m;
      end match;

      j := JSON.addElement(dumpJSONSCodeMod_impl(m.mod, scope, isChoices = true), j);
    end for;

    json := JSON.addPair("choice", j, json);
  end if;

  for m in others loop
    json := dumpJSONAnnotationSubMod(m, scope, failOnError, json);
  end for;
end dumpJSONChoicesAnnotation;

public function modifierJSON
  input String modifier;
  output JSON json;
protected
  Absyn.Modification amod;
  SCode.Mod smod;
algorithm
  Absyn.ElementArg.MODIFICATION(modification = SOME(amod)) :=
    Parser.stringMod("dummy" + modifier);
  smod := AbsynToSCode.translateMod(SOME(amod),
    SCode.Final.NOT_FINAL(), SCode.Each.NOT_EACH(), NONE(), Absyn.dummyInfo);
  json := dumpJSONSCodeMod_impl(smod, InstNode.EMPTY_NODE());
end modifierJSON;

annotation(__OpenModelica_Interface="nf_api");
end NFInstanceAPI;

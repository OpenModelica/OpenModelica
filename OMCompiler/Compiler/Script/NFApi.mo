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

encapsulated package NFApi

import Absyn;
import AbsynUtil;
import SCode;
import DAE;
import NFModifier.Modifier;
import SimCode;
import Values;

protected

import Inst = NFInst;
import InstUtil = NFInstUtil;
import NFBinding.Binding;
import NFComponent.Component;
import ComponentRef = NFComponentRef;
import Dimension = NFDimension;
import Expression = NFExpression;
import Import = NFImport;
import NFClass.Class;
import NFInstNode.InstNode;
import NFInstNode.InstNodeType;
import NFModifier.ModifierScope;
import Equation = NFEquation;
import NFType.Type;
import Subscript = NFSubscript;
import Connection = NFConnection;
import InstContext = NFInstContext;

import Absyn.Path;
import AbsynToSCode;
import CevalScriptBackend;
import NFInstanceAPI;
import Config;
import ConvertDAE = NFConvertDAE;
import DAEUtil;
import Dump;
import EvalConstants = NFEvalConstants;
import ErrorExt;
import ExecStat.{execStat,execStatReset};
import Flags;
import FlagsUtil;
import FlatModel = NFFlatModel;
import Flatten = NFFlatten;
import Global;
import JSON;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import NFCall.Call;
import Ceval = NFCeval;
import NFClassTree.ClassTree;
import NFFlatten.FunctionTree;
import NFPrefixes.{Variability, Purity};
import NFSections.Sections;
import Package = NFPackage;
import Prefixes = NFPrefixes;
import Restriction = NFRestriction;
import Scalarize = NFScalarize;
import SimCodeMain;
import SimplifyExp = NFSimplifyExp;
import SimplifyModel = NFSimplifyModel;
import SymbolTable;
import Typing = NFTyping;
import UnitCheck = NFUnitCheck;
import Util;
import ValuesMake;
import Variable = NFVariable;
import VerifyModel = NFVerifyModel;
import SCodeUtil;
import InstSettings = NFInst.InstSettings;
import MetaModelica.Dangerous.listReverseInPlace;

constant InstContext.Type ANNOTATION_CONTEXT = intBitOr(NFInstContext.RELAXED, NFInstContext.ANNOTATION);
constant InstContext.Type INST_API_ANNOTATION_CONTEXT = intBitOr(ANNOTATION_CONTEXT, NFInstContext.INSTANCE_API);
constant InstContext.Type FAST_CONTEXT = intBitOr(NFInstContext.RELAXED, NFInstContext.FAST_LOOKUP);

public
function evaluateAnnotation
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input Absyn.Annotation inAnnotation;
  output String outString = "";
protected
  Boolean b, s;
algorithm
  b := FlagsUtil.set(Flags.SCODE_INST, true);
  s := FlagsUtil.set(Flags.NF_SCALARIZE, true); // #5689
  try
    outString := evaluateAnnotation_dispatch(absynProgram, classPath, inAnnotation);
    FlagsUtil.set(Flags.SCODE_INST, b);
    FlagsUtil.set(Flags.NF_SCALARIZE, s);
  else
    FlagsUtil.set(Flags.SCODE_INST, b);
    FlagsUtil.set(Flags.NF_SCALARIZE, s);
    fail();
  end try;
end evaluateAnnotation;

protected
function evaluateAnnotation_dispatch
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input Absyn.Annotation inAnnotation;
  input Boolean addAnnotationName = false;
  output String outString = "";
protected
  InstNode top, inst_cls, anncls, inst_anncls;
  String name, annName, str;
  SCode.Program program;
  list<Absyn.ElementArg> el = {};
  list<String> stringLst = {};
  Absyn.Exp absynExp;
  Expression exp, save;
  SourceInfo info;
  list<Absyn.ElementArg> mod, stripped_mod, graphics_mod;
  Absyn.EqMod eqmod;
  SCode.Mod smod;
  DAE.DAElist dae;
  Type ty;
  Variability var;
algorithm
  stringLst := {};
  Absyn.ANNOTATION(el) := inAnnotation;

  for e in listReverse(el) loop

    e := AbsynUtil.createChoiceArray(e);

    str := matchcontinue e
      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD({}, eqmod as Absyn.EQMOD(absynExp))),
          info = info)
        algorithm
          // no need for the class if there are no crefs
          if AbsynUtil.onlyLiteralsInEqMod(eqmod) then
            (program, top) := NFInstanceAPI.mkTop(absynProgram, scodeFor(absynProgram), annName);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          exp := NFInst.instExp(absynExp, inst_cls, ANNOTATION_CONTEXT, info);
          (exp, ty, var) := Typing.typeExp(exp, ANNOTATION_CONTEXT, info);
          // exp := NFCeval.evalExp(exp);
          exp := SimplifyExp.simplify(exp);
          str := Expression.toString(exp);
        then
          stringAppendList({annName, "=", str});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD(mod, Absyn.NOMOD())),
          info = info)
        algorithm
          // no need for the class if there are no crefs
          if AbsynUtil.onlyLiteralsInAnnotationMod(mod) then
            (program, top) := NFInstanceAPI.mkTop(absynProgram, scodeFor(absynProgram), annName);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          (stripped_mod, graphics_mod) := AbsynUtil.stripGraphicsAndInteractionModification(mod);

          smod := AbsynToSCode.translateMod(SOME(Absyn.CLASSMOD(stripped_mod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), info);
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, ANNOTATION_CONTEXT, Absyn.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls, ANNOTATION_CONTEXT);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), inst_cls, 0), NFAttributes.DEFAULT_ATTR, true, 0, 0, inst_cls, ANNOTATION_CONTEXT);
          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = ANNOTATION_CONTEXT, settings = NFInst.DEFAULT_SETTINGS);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM), ANNOTATION_CONTEXT);

          dae := frontEndBack(inst_anncls, annName, false);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));

          if (listMember(annName, {"Icon", "Diagram", "choices"})) and not listEmpty(graphics_mod) then
            try
              {Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp = absynExp))))} := graphics_mod;
              exp := NFInst.instExp(absynExp, inst_cls, ANNOTATION_CONTEXT, info);
              (exp, ty, var) := Typing.typeExp(exp, ANNOTATION_CONTEXT, info);
              save := exp;
              try
                exp := NFCeval.evalExp(save);
              else
                exp := EvalConstants.evaluateExp(save, info);
              end try;
              exp := SimplifyExp.simplify(exp);
              str := str + "," + Expression.toString(exp);
            else
              // just don't fail!
            end try;
          end if;
        then
          if addAnnotationName
          then stringAppendList({annName, "(", str, ")"})
          else str;

      case Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = NONE(), info = info)
        algorithm
          (program, top) := NFInstanceAPI.mkTop(absynProgram, scodeFor(absynProgram), annName);
          inst_cls := top;

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, ANNOTATION_CONTEXT, Absyn.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls, context = ANNOTATION_CONTEXT);
          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = ANNOTATION_CONTEXT, settings = NFInst.DEFAULT_SETTINGS);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM), ANNOTATION_CONTEXT);

          dae := frontEndBack(inst_anncls, annName, false);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          if addAnnotationName
          then stringAppendList({annName, "(", str, ")"})
          else str;

      case Absyn.MODIFICATION(path = Absyn.IDENT(annName), info = info)
        algorithm
          str := "error evaluating: annotation(" + Dump.unparseElementArgStr(e) + ")";
          str := Util.escapeQuotes(str);
        then
          stringAppendList({annName, "(\"", str, "\")"});

    end matchcontinue;

    stringLst := str :: stringLst;
  end for;

  outString := stringDelimitList(stringLst, ", ");

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.evaluateAnnotation_dispatch("+ AbsynUtil.pathString(classPath) + " annotation(" + stringDelimitList(List.map(el, Dump.unparseElementArgStr), ", ") + ")");
  end if;

end evaluateAnnotation_dispatch;

public
function evaluateAnnotations
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input list<Absyn.Element> inElements;
  output list<String> outStringLst = {};
protected
  Boolean b, s;
algorithm
  b := FlagsUtil.set(Flags.SCODE_INST, true);
  s := FlagsUtil.set(Flags.NF_SCALARIZE, true); // #5689
  try
    outStringLst := evaluateAnnotations_dispatch(absynProgram, classPath, inElements);
    FlagsUtil.set(Flags.SCODE_INST, b);
    FlagsUtil.set(Flags.NF_SCALARIZE, s);
  else
    FlagsUtil.set(Flags.SCODE_INST, b);
    FlagsUtil.set(Flags.NF_SCALARIZE, s);
    fail();
  end try;
end evaluateAnnotations;

protected
function evaluateAnnotations_dispatch
  "Instantiates the annotation class, gets the DAE and populates the annotation result"
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input list<Absyn.Element> inElements;
  output list<String> outStringLst = {};
protected
  String str;
  list<list<Absyn.ElementArg>> elArgs = {}, el = {};
  list<String> stringLst = {};
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
  list<Absyn.ElementArg> anns;
  Option<Absyn.Comment> cmt;
algorithm
  // handle the annotations
  for i in inElements loop
   elArgs := match i
      case Absyn.ELEMENT(specification = Absyn.COMPONENTS(components = items), constrainClass = cc)
        algorithm
          el := AbsynUtil.getAnnotationsFromItems(items, AbsynUtil.getAnnotationsFromConstraintClass(cc));
        then
          listAppend(el, elArgs);

      case Absyn.ELEMENT(specification = Absyn.COMPONENTS())
        then {}::elArgs;

      case Absyn.ELEMENT(specification = Absyn.CLASSDEF(
           class_ = Absyn.CLASS(body = Absyn.DERIVED(comment = cmt))),
           constrainClass = cc)
        algorithm
          anns := match cmt
            case SOME(Absyn.COMMENT(annotation_ = SOME(Absyn.ANNOTATION(anns))))
              then anns;
            else {};
          end match;
        then
          listAppend(anns, AbsynUtil.getAnnotationsFromConstraintClass(cc))::elArgs;

      case Absyn.ELEMENT(specification = Absyn.COMPONENTS())
        then {} :: elArgs;

      case Absyn.ELEMENT(specification = Absyn.CLASSDEF(class_ = Absyn.CLASS(body = Absyn.DERIVED())))
        then {} :: elArgs;


      else elArgs;
    end match;
  end for;

  for l in elArgs loop
    stringLst := {};

    for e in listReverse(l) loop
      str := evaluateAnnotation_dispatch(absynProgram, classPath, Absyn.ANNOTATION({e}), true);
      stringLst := str :: stringLst;
    end for;

    str := stringDelimitList(stringLst, ", ");
    outStringLst := stringAppendList({"{", str, "}"}) :: outStringLst;
  end for;

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.evaluateAnnotations_dispatch("+ AbsynUtil.pathString(classPath) + " annotation(" + stringDelimitList(List.map(List.flatten(elArgs), Dump.unparseElementArgStr), ", ") + ")");
  end if;
end evaluateAnnotations_dispatch;

public
function mkFullyQual
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  input Absyn.Path pathToQualify;
  input Boolean failOnError = false;
  output Absyn.Path qualPath = pathToQualify;
protected
  InstNode expanded_cls, cls;
  SCode.Program program;
  String name, id1, id2;
  Boolean b, s;
  InstContext.Type context;
algorithm
  // do some quick checks
  // classPath is already fully qualified
  // check if the paths start with the same id and the second path is qualified
  () := match (classPath, pathToQualify)
    case (Absyn.QUALIFIED(id1, _), Absyn.QUALIFIED(id2, _)) guard id1 == id2
      algorithm
        return;
      then ();
    else ();
  end match;

  // else, do the hard stuff!
  b := FlagsUtil.set(Flags.SCODE_INST, true);
  s := FlagsUtil.set(Flags.NF_SCALARIZE, true); // #5689
  try
    if not Flags.isSet(Flags.NF_API_NOISE) then
      ErrorExt.setCheckpoint("NFApi.mkFullyQual");
    end if;
    // run the front-end front
    (program, name, expanded_cls) := frontEndLookup(absynProgram, classPath);

    context := InstContext.set(NFInstContext.RELAXED, NFInstContext.FAST_LOOKUP);

    // if is derived qualify in the parent
    if InstNode.isDerivedClass(expanded_cls) then
      cls := Lookup.lookupClassName(pathToQualify, InstNode.classParent(expanded_cls), context, Absyn.dummyInfo, checkAccessViolations = false);
    else // qualify in the class
      cls := Lookup.lookupClassName(pathToQualify, expanded_cls, context, Absyn.dummyInfo, checkAccessViolations = false);
    end if;

    qualPath := InstNode.fullPath(cls);

    if not Flags.isSet(Flags.NF_API_NOISE) then
      ErrorExt.rollBack("NFApi.mkFullyQual");
    end if;

    FlagsUtil.set(Flags.SCODE_INST, b);
    FlagsUtil.set(Flags.NF_SCALARIZE, s);
  else
    if not Flags.isSet(Flags.NF_API_NOISE) then
      ErrorExt.rollBack("NFApi.mkFullyQual");
    end if;

    FlagsUtil.set(Flags.SCODE_INST, b);
    FlagsUtil.set(Flags.NF_SCALARIZE, s);

    if failOnError then
      fail();
    else
      // do not fail, just return the Absyn path
      qualPath := pathToQualify;
    end if;
  end try;

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.mkFullyQual(" + AbsynUtil.pathString(classPath) + ", " + AbsynUtil.pathString(pathToQualify) + ") -> " + AbsynUtil.pathString(qualPath));
  end if;
end mkFullyQual;

public function clearCache
  "Release every tree the instance API is holding. A session that has dropped
   its program otherwise keeps its last models instantiated until something
   instantiates again."
algorithm
  setGlobalRoot(Global.instNFInstCacheIndex, {});
  setGlobalRoot(Global.instNFLookupCacheIndex, {});
  NFInstanceAPI.clearTopScopeCache();
end clearCache;

protected
function frontEndFront
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode inst_cls;
protected
  list<tuple<tuple<Absyn.Program, Absyn.Path>, tuple<SCode.Program, String, InstNode>>> cache;
algorithm
  cache := getGlobalRoot(Global.instNFInstCacheIndex);
  if not listEmpty(cache) then
    for i in cache loop
      if referenceEq(absynProgram, Util.tuple21(Util.tuple21(i))) then
        if AbsynUtil.pathEqual(classPath, Util.tuple22(Util.tuple21(i))) then
          (program, name, inst_cls) := Util.tuple22(i);
          return;
        end if;

        // program changed, wipe the cache!
        cache := {};
        setGlobalRoot(Global.instNFInstCacheIndex, cache);

        break;
      else
        if AbsynUtil.pathEqual(classPath, Util.tuple22(Util.tuple21(i))) then
          // class reloaded, wipe the cache!
          cache := {};
          setGlobalRoot(Global.instNFInstCacheIndex, cache);

          break;
        end if;
      end if;
    end for;
  end if;

  (program, name, inst_cls) := frontEndFront_dispatch(absynProgram, classPath);

  if listLength(cache) > 100 then
    // trim it down, keep 10
    cache := List.firstN(cache, 10);
  end if;

  cache := ((absynProgram,classPath), (program, name, inst_cls))::cache;
  setGlobalRoot(Global.instNFInstCacheIndex, cache);
end frontEndFront;

protected
function frontEndFront_dispatch
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode inst_cls;
protected
  InstNode top, cls;
algorithm
  name := AbsynUtil.pathString(classPath);

  (program, top) := NFInstanceAPI.mkTop(absynProgram, scodeFor(absynProgram), name);

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, NFInstContext.RELAXED, Absyn.dummyInfo, checkAccessViolations = false);
  cls := InstNode.makeRootClass(cls);

  // Instantiate the class.
  inst_cls := NFInst.instantiate(cls, context = NFInstContext.RELAXED);

  NFInst.insertGeneratedInners(inst_cls, top, NFInstContext.RELAXED);

  // Instantiate expressions (i.e. anything that can contains crefs, like
  // bindings, dimensions, etc). This is done as a separate step after
  // instantiation to make sure that lookup is able to find the correct nodes.
  NFInst.instExpressions(inst_cls, context = NFInstContext.RELAXED, settings = NFInst.DEFAULT_SETTINGS);

  // Mark structural parameters.
  NFInst.updateImplicitVariability(inst_cls, Flags.isSet(Flags.EVAL_PARAM), NFInstContext.RELAXED);

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.frontEndFront_dispatch(" + name + ")");
  end if;

  Inst.clearCaches();
end frontEndFront_dispatch;

protected
function frontEndBack
  input InstNode inst_cls;
  input String name;
  input Boolean scalarize = true;
  output DAE.DAElist dae;
protected
  FlatModel flat_model;
  FunctionTree funcs;
  AvlTreePathFunction.Tree daeFuncs;
algorithm
  // Type the class.
  Typing.typeClass(inst_cls, NFInstContext.RELAXED);

  // Flatten and simplify the model.
  flat_model := Flatten.flatten(inst_cls, Absyn.Path.IDENT(name));
  flat_model := EvalConstants.evaluate(flat_model, NFInstContext.RELAXED);
  flat_model := UnitCheck.checkUnits(flat_model);
  flat_model := SimplifyModel.simplify(flat_model);
  flat_model := Package.collectConstants(flat_model);
  funcs := Flatten.collectFunctions(flat_model);

  // Scalarize array components in the flat model.
  if Flags.isSet(Flags.NF_SCALARIZE) /* and scalarize */ then
    flat_model := Scalarize.scalarize(flat_model);
  else
    // Remove empty arrays from variables
    flat_model.variables := List.filterOnFalse(flat_model.variables, Variable.isEmptyArray);
  end if;

  VerifyModel.verify(flat_model, InstNode.isPartial(inst_cls));

  // Convert the flat model to a DAE.
  (dae, daeFuncs) := ConvertDAE.convert(flat_model, funcs);

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.frontEndBack(" + AbsynUtil.pathString(InstNode.enclosingScopePath(inst_cls)) + ", name: " + name + ", scalarize: " + boolString(scalarize) + ")");
  end if;

end frontEndBack;

protected
function frontEndLookup
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode expanded_cls;
protected
  list<tuple<tuple<Absyn.Program, Absyn.Path>, tuple<SCode.Program, String, InstNode>>> cache;
algorithm
  cache := getGlobalRoot(Global.instNFLookupCacheIndex);
  if not listEmpty(cache) then
    for i in cache loop
      if referenceEq(absynProgram, Util.tuple21(Util.tuple21(i))) then
        if AbsynUtil.pathEqual(classPath, Util.tuple22(Util.tuple21(i))) then
          (program, name, expanded_cls) := Util.tuple22(i);
          return;
        end if;

        // program changed, wipe the cache!
        cache := {};
        setGlobalRoot(Global.instNFLookupCacheIndex, cache);

        break;
      else
        if AbsynUtil.pathEqual(classPath, Util.tuple22(Util.tuple21(i))) then
          // class reloaded, wipe the cache!
          cache := {};
          setGlobalRoot(Global.instNFLookupCacheIndex, cache);

          break;
        end if;
      end if;
    end for;
  end if;

  (program, name, expanded_cls) := frontEndLookup_dispatch(absynProgram, classPath);

  if listLength(cache) > 100 then
    // trim it down, keep 10
    cache := List.firstN(cache, 10);
  end if;

  cache := ((absynProgram,classPath), (program, name, expanded_cls))::cache;
  setGlobalRoot(Global.instNFLookupCacheIndex, cache);
end frontEndLookup;

protected
function frontEndLookup_dispatch
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode expanded_cls;
protected
  InstNode top, cls;
algorithm
  name := AbsynUtil.pathString(classPath);

  (program, top) := NFInstanceAPI.mkTop(absynProgram, scodeFor(absynProgram), name);

  if AbsynUtil.pathEqual(classPath, Absyn.IDENT("AllLoadedClasses")) then
    expanded_cls := top;
  else
    cls := Inst.lookupRootClass(classPath, top, FAST_CONTEXT);

    // Expand the class.
    expanded_cls := NFInst.expand(cls, FAST_CONTEXT);
  end if;

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.frontEndLookup_dispatch("+ name +")");
  end if;

  Inst.clearCaches();
end frontEndLookup_dispatch;

public
function getInheritedClasses
  input Absyn.Path classPath;
  input Absyn.Program program;
  output list<Absyn.Path> extendsPaths;
protected
  InstNode cls_node;
  Class cls;
  array<InstNode> exts;
  Integer start_idx;
algorithm
  if not Flags.isSet(Flags.SCODE_INST) then
    extendsPaths := {};
    return;
  end if;

  (_, _, cls_node) := frontEndLookup(program, classPath);

  if not InstNode.isClass(cls_node) then
    extendsPaths := {};
    return;
  end if;

  cls := InstNode.getClass(cls_node);

  extendsPaths := match cls
    case Class.EXPANDED_DERIVED() then {InstNode.fullPath(cls.baseClass, true)};
    else
      algorithm
        exts := ClassTree.getExtends(Class.classTree(cls));
        // Skip the first extends of a class extends since it would just return
        // the name of the class itself. That's technically correct, but not
        // very useful and a potential user trap when using the API recursively.
        start_idx := if SCodeUtil.isClassExtends(InstNode.definition(cls_node)) then 2 else 1;
      then
        list(InstNode.fullPath(exts[i], true) for i in start_idx:arrayLength(exts));
  end match;
end getInheritedClasses;

function getNthInheritedClass
  input Absyn.Path classPath;
  input Integer index;
  input Absyn.Program program;
  output Values.Value result;
protected
  InstNode cls_node;
  Class cls;
  array<InstNode> exts;
algorithm
  if not Flags.isSet(Flags.SCODE_INST) then
    result := ValuesMake.makeBoolean(false);
    return;
  end if;

  (_, _, cls_node) := frontEndLookup(program, classPath);

  if not InstNode.isClass(cls_node) then
    result := ValuesMake.makeBoolean(false);
    return;
  end if;

  cls := InstNode.getClass(cls_node);

  exts := match cls
    case Class.EXPANDED_DERIVED() then listArray({cls.baseClass});
    else ClassTree.getExtends(Class.classTree(cls));
  end match;

  if index < 1 or index > arrayLength(exts) then
    result := ValuesMake.makeBoolean(false);
    return;
  end if;

  result := ValuesMake.makeCodeTypeName(InstNode.fullPath(exts[index], true));
end getNthInheritedClass;

function getModelInstance
  input Absyn.Path classPath;
  input Absyn.Path contextPath;
  input String modifier;
  input Boolean prettyPrint;
  output Values.Value res;
protected
  JSON json;
algorithm
  try
    json := NFInstanceAPI.buildModelInstanceJSON(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), classPath, contextPath, modifier);
    res := Values.STRING(JSON.toString(json, prettyPrint));
    execStat("JSON.toString");
    Inst.clearCaches();
  else
    Inst.clearCaches();
    fail();
  end try;
end getModelInstance;

function getModelInstanceReference
  "Like getModelInstance, but instead of serializing the model instance to a
   JSON string it stores the (boxed) JSON structure in memory and returns an
   integer handle to it (see issue #15219). OMEdit, which links the compiler
   in-process, can then read the structure directly via the C function
   ModelInstanceReference_get, avoiding both JSON string generation here and
   JSON string parsing in OMEdit. The handle must be freed with
   releaseModelInstanceReference. A handle of 0 indicates failure."
  input Absyn.Path classPath;
  input Absyn.Path contextPath;
  input String modifier;
  output Values.Value res;
protected
  JSON json;
  Integer handle;
algorithm
  try
    json := NFInstanceAPI.buildModelInstanceJSON(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), classPath, contextPath, modifier);
    json := JSON.toListForm(json);
    execStat("NFApi.toListForm");
    handle := NFInstanceAPI.storeModelInstanceReference(json);
    res := Values.INTEGER(handle);
    Inst.clearCaches();
  else
    Inst.clearCaches();
    fail();
  end try;
end getModelInstanceReference;

function getModelInstanceIconReference
  "Like getModelInstanceReference, but stores only what an icon renderer reads:
   the class' Icon with its extends chain, and the locally declared connector
   components' Placement and type Icon. A lookup and an expand per class,
   against an instantiation and a dump of every component."
  input Absyn.Path classPath;
  output Values.Value res;
protected
  JSON json;
  Integer handle;
algorithm
  try
    json := NFInstanceAPI.buildModelInstanceIconJSON(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), classPath);
    json := JSON.toListForm(json);
    handle := NFInstanceAPI.storeModelInstanceReference(json);
    res := Values.INTEGER(handle);
    Inst.clearCaches();
  else
    Inst.clearCaches();
    fail();
  end try;
end getModelInstanceIconReference;

function getModelInstanceAnnotation
  input Absyn.Path classPath;
  input list<String> filter;
  input Boolean prettyPrint;
  output Values.Value res;
protected
  JSON json;
algorithm
  try
    json := NFInstanceAPI.buildModelInstanceAnnotationJSON(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), classPath, filter);
    res := Values.STRING(JSON.toString(json, prettyPrint));
    Inst.clearCaches();
  else
    Inst.clearCaches();
    fail();
  end try;
end getModelInstanceAnnotation;

function getModelInstanceAnnotationReference
  "Like getModelInstanceAnnotation, but returns an integer handle to an
   in-memory JSON structure instead of a JSON string (see
   getModelInstanceReference and issue #15219)."
  input Absyn.Path classPath;
  input list<String> filter;
  output Values.Value res;
protected
  JSON json;
  Integer handle;
algorithm
  try
    json := NFInstanceAPI.buildModelInstanceAnnotationJSON(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), classPath, filter);
    json := JSON.toListForm(json);
    handle := NFInstanceAPI.storeModelInstanceReference(json);
    res := Values.INTEGER(handle);
    Inst.clearCaches();
  else
    Inst.clearCaches();
    fail();
  end try;
end getModelInstanceAnnotationReference;

function releaseModelInstanceReference
  "Releases a handle previously returned by getModelInstanceReference or
   getModelInstanceAnnotationReference. Returns true on success."
  input Integer handle;
  output Values.Value res;
algorithm
  res := Values.BOOL(NFInstanceAPI.releaseModelInstanceReferenceImpl(handle));
end releaseModelInstanceReference;

function modifierToJSON
  input String modifier;
  input Boolean prettyPrint;
  output Values.Value jsonString;
algorithm
  jsonString := Values.STRING(JSON.toString(NFInstanceAPI.modifierJSON(modifier), prettyPrint));
end modifierToJSON;

function scodeFor
  "SymbolTable's already translated SCode, when `absynProgram` is its program.
   NFInstanceAPI retranslates the whole library without it."
  input Absyn.Program absynProgram;
  output Option<SCode.Program> scodeProgram =
    if referenceEq(absynProgram, SymbolTable.getAbsyn()) then SOME(SymbolTable.getSCode()) else NONE();
end scodeFor;

uniontype MoveEnv
  record MOVE_ENV
    InstNode scope;
    Absyn.Path destinationPath;
    InstNode destination;
  end MOVE_ENV;
end MoveEnv;

function updateMovedClassPaths
  "Updates all the paths inside of a class that is being moved such that the
   paths are still valid in the new location."
  input output Absyn.Class cls "The class definition";
  input Absyn.Path clsPath "The fully qualified path of the class";
  input Absyn.Within destination "The destination package (or top scope)";
protected
  InstNode top, src_node, dst_node = InstNode.EMPTY_NODE();
  MoveEnv env;
  Absyn.Path dst_path, p;
  Boolean found = false;
algorithm
  // Make a top node and look up the class in it.
  (_, top) := NFInstanceAPI.mkTop(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), AbsynUtil.pathString(clsPath));
  src_node := Inst.lookupRootClass(clsPath, top, FAST_CONTEXT);
  Inst.expand(src_node, FAST_CONTEXT);

  // Get the destination path including the class name.
  dst_path := match destination
    case Absyn.Within.WITHIN() then AbsynUtil.suffixPath(destination.path, InstNode.name(src_node));
    else Absyn.Path.IDENT(InstNode.name(src_node));
  end match;

  // Also look up the destination package, which is needed to resolve shadowing issues in some cases.
  // The destination package might not exist yet, but in that case there's nothing to look up in it anyway,
  // so the first existing enclosing scope also works.
  dst_node := top;
  p := dst_path;

  while not found and not AbsynUtil.pathIsIdent(p) loop
    try
      p := AbsynUtil.pathPrefix(p);
      dst_node := Lookup.lookupName(p, top, FAST_CONTEXT, false);
      Inst.expand(dst_node, FAST_CONTEXT);
      found := true;
    else
    end try;
  end while;

  env := MOVE_ENV(src_node, dst_path, dst_node);
  cls.body := updateMovedClassDef(cls.body, env);
end updateMovedClassPaths;

function updateMovedClass
  input output Absyn.Class cls;
  input MoveEnv env;
protected
  InstNode cls_node;
  MoveEnv cls_env;
algorithm
  if classHasScope(cls) then
    // Change the scope in the environment to this class, if the class has its
    // own scope (i.e. is a long class definition).
    cls_node := Lookup.lookupLocalSimpleName(cls.name, env.scope);
    Inst.expand(cls_node, FAST_CONTEXT);
    cls_env := MoveEnv.MOVE_ENV(cls_node, AbsynUtil.suffixPath(env.destinationPath, cls.name), env.destination);
  else
    cls_env := env;
  end if;

  cls.body := updateMovedClassDef(cls.body, cls_env);
end updateMovedClass;

function classHasScope
  input Absyn.Class cls;
  output Boolean hasScope;
algorithm
  hasScope := match cls.body
    case Absyn.ClassDef.PARTS() then true;
    case Absyn.ClassDef.CLASS_EXTENDS() then true;
    else false;
  end match;
end classHasScope;

function updateMovedClassDef
  input output Absyn.ClassDef cdef;
  input MoveEnv env;
algorithm
  () := match cdef
    case Absyn.ClassDef.PARTS()
      algorithm
        cdef.classParts := list(updateMovedClassPart(p, env) for p in cdef.classParts);
        cdef.ann := list(updateMovedAnnotation(a, env) for a in cdef.ann);
      then
        ();

    case Absyn.ClassDef.DERIVED()
      algorithm
        cdef.typeSpec := updateMovedTypeSpec(cdef.typeSpec, env);
        cdef.attributes := updateMovedElementAttributes(cdef.attributes, env);
        cdef.arguments := list(updateMovedElementArg(a, env) for a in cdef.arguments);
        cdef.comment := updateMovedCommentOpt(cdef.comment, env);
      then
        ();

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        cdef.modifications := list(updateMovedElementArg(a, env) for a in cdef.modifications);
        cdef.parts := list(updateMovedClassPart(p, env) for p in cdef.parts);
        cdef.ann := list(updateMovedAnnotation(a, env) for a in cdef.ann);
      then
        ();

    case Absyn.ClassDef.PDER()
      algorithm
        cdef.functionName := updateMovedPath(cdef.functionName, env);
        cdef.comment := updateMovedCommentOpt(cdef.comment, env);
      then
        ();

    else ();
  end match;
end updateMovedClassDef;

function updateMovedClassPart
  input output Absyn.ClassPart part;
  input MoveEnv env;
algorithm
  () := match part
    case Absyn.ClassPart.PUBLIC()
      algorithm
        part.contents := list(updateMovedElementItem(i, env) for i in part.contents);
      then
        ();

    case Absyn.ClassPart.PROTECTED()
      algorithm
        part.contents := list(updateMovedElementItem(i, env) for i in part.contents);
      then
        ();

    case Absyn.ClassPart.EQUATIONS()
      algorithm
        part.contents := updateMovedEquationItems(part.contents, env);
      then
        ();

    case Absyn.ClassPart.INITIALEQUATIONS()
      algorithm
        part.contents := updateMovedEquationItems(part.contents, env);
      then
        ();

    case Absyn.ClassPart.ALGORITHMS()
      algorithm
        part.contents := updateMovedAlgorithmItems(part.contents, env);
      then
        ();

    case Absyn.ClassPart.INITIALALGORITHMS()
      algorithm
        part.contents := updateMovedAlgorithmItems(part.contents, env);
      then
        ();

    case Absyn.ClassPart.EXTERNAL()
      algorithm
        part.annotation_ := updateMovedAnnotationOpt(part.annotation_, env);
      then
        ();

    else ();
  end match;
end updateMovedClassPart;

function updateMovedElementItem
  input output Absyn.ElementItem item;
  input MoveEnv env;
algorithm
  () := match item
    case Absyn.ElementItem.ELEMENTITEM()
      algorithm
        item.element := updateMovedElement(item.element, env);
      then
        ();

    else ();
  end match;
end updateMovedElementItem;

function updateMovedElement
  input output Absyn.Element element;
  input MoveEnv env;
algorithm
  () := match element
    case Absyn.Element.ELEMENT()
      algorithm
        element.specification := updateMovedElementSpec(element.specification, env);

        if isSome(element.constrainClass) then
          element.constrainClass :=
            SOME(updateMovedConstrainClass(Util.getOption(element.constrainClass), env));
        end if;
      then
        ();

    else ();
  end match;
end updateMovedElement;

function updateMovedConstrainClass
  input output Absyn.ConstrainClass cc;
  input MoveEnv env;
algorithm
  cc.elementSpec := updateMovedElementSpec(cc.elementSpec, env);
  cc.comment := updateMovedCommentOpt(cc.comment, env);
end updateMovedConstrainClass;

function updateMovedElementSpec
  input output Absyn.ElementSpec spec;
  input MoveEnv env;
algorithm
  () := match spec
    case Absyn.ElementSpec.CLASSDEF()
      algorithm
        spec.class_ := updateMovedClass(spec.class_, env);
      then
        ();

    case Absyn.ElementSpec.EXTENDS()
      algorithm
        spec.path := updateMovedPath(spec.path, env);
        spec.elementArg := list(updateMovedElementArg(a, env) for a in spec.elementArg);
        spec.annotationOpt := updateMovedAnnotationOpt(spec.annotationOpt, env);
      then
        ();

    case Absyn.ElementSpec.COMPONENTS()
      algorithm
        spec.attributes := updateMovedElementAttributes(spec.attributes, env);
        spec.typeSpec := updateMovedTypeSpec(spec.typeSpec, env);
        spec.components := list(updateMovedComponentItem(c, env) for c in spec.components);
      then
        ();

    else ();
  end match;
end updateMovedElementSpec;

function updateMovedElementAttributes
  input output Absyn.ElementAttributes attr;
  input MoveEnv env;
algorithm
  if not listEmpty(attr.arrayDim) then
    attr.arrayDim := list(updateMovedSubscript(s, env) for s in attr.arrayDim);
  end if;
end updateMovedElementAttributes;

function updateMovedElementArg
  input output Absyn.ElementArg arg;
  input MoveEnv env;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION()
      algorithm
        if isSome(arg.modification) then
          arg.modification := SOME(updateMovedModification(Util.getOption(arg.modification), env));
        end if;
      then
        ();

    case Absyn.ElementArg.REDECLARATION()
      algorithm
        arg.elementSpec := updateMovedElementSpec(arg.elementSpec, env);

        if isSome(arg.constrainClass) then
          arg.constrainClass := SOME(updateMovedConstrainClass(Util.getOption(arg.constrainClass), env));
        end if;
      then
        ();

    else ();
  end match;
end updateMovedElementArg;

function updateMovedModification
  input output Absyn.Modification mod;
  input MoveEnv env;
protected
  Absyn.EqMod eq_mod;
algorithm
  mod.elementArgLst := list(updateMovedElementArg(a, env) for a in mod.elementArgLst);

  eq_mod := mod.eqMod;
  () := match eq_mod
    case Absyn.EqMod.EQMOD()
      algorithm
        eq_mod.exp := updateMovedExp(eq_mod.exp, env);
        mod.eqMod := eq_mod;
      then
        ();

    else ();
  end match;
end updateMovedModification;

function updateMovedComponentItem
  input output Absyn.ComponentItem item;
  input MoveEnv env;
algorithm
  item.component := updateMovedComponent(item.component, env);

  if isSome(item.condition) then
    item.condition := SOME(updateMovedExp(Util.getOption(item.condition), env));
  end if;
end updateMovedComponentItem;

function updateMovedComponent
  input output Absyn.Component component;
  input MoveEnv env;
algorithm
  if not listEmpty(component.arrayDim) then
    component.arrayDim := list(updateMovedSubscript(d, env) for d in component.arrayDim);
  end if;

  if isSome(component.modification) then
    component.modification := SOME(updateMovedModification(Util.getOption(component.modification), env));
  end if;
end updateMovedComponent;

function updateMovedEquationItems
  input output list<Absyn.EquationItem> items;
  input MoveEnv env;
algorithm
  items := AbsynUtil.traverseEquationItemListBidir(items,
    updateMovedExp_traverser, AbsynUtil.dummyTraverseExp, env);
end updateMovedEquationItems;

function updateMovedAlgorithmItems
  input output list<Absyn.AlgorithmItem> items;
  input MoveEnv env;
algorithm
  items := AbsynUtil.traverseAlgorithmItemListBidir(items,
    updateMovedExp_traverser, AbsynUtil.dummyTraverseExp, env);
end updateMovedAlgorithmItems;

function updateMovedTypeSpec
  input output Absyn.TypeSpec ty;
  input MoveEnv env;
algorithm
  () := match ty
    case Absyn.TypeSpec.TPATH()
      algorithm
        ty.path := updateMovedPath(ty.path, env);

        if isSome(ty.arrayDim) then
          ty.arrayDim := SOME(list(updateMovedSubscript(s, env) for s in Util.getOption(ty.arrayDim)));
        end if;
      then
        ();

    case Absyn.TypeSpec.TCOMPLEX()
      algorithm
        ty.path := updateMovedPath(ty.path, env);

        if isSome(ty.arrayDim) then
          ty.arrayDim := SOME(list(updateMovedSubscript(s, env) for s in Util.getOption(ty.arrayDim)));
        end if;
      then
        ();

  end match;
end updateMovedTypeSpec;

function updateMovedPath
  input Absyn.Path path;
  input MoveEnv env;
  output Absyn.Path outPath = path;
protected
  Absyn.Path qualified_path, new_path;
  Option<Absyn.Path> opt_path;
  InstNode node;
algorithm
  // Try to look up the qualified path needed to be able to find the name in
  // this scope even if the root class that contains the scope is moved elsewhere.
  try
    qualified_path :=
      Lookup.lookupSimpleNameRootPath(AbsynUtil.pathFirstIdent(path), env.scope, FAST_CONTEXT);
  else
    // Lookup failed, leave the path unchanged.
    return;
  end try;

  // If the path we found is fully qualified it means it refers to an element
  // outside the class' scope, and the original path needs to be updated so it
  // can be found from the destination scope.
  if AbsynUtil.pathIsFullyQualified(qualified_path) then

    qualified_path := AbsynUtil.makeNotFullyQualified(qualified_path);

    if AbsynUtil.pathIsIdent(qualified_path) and
       AbsynUtil.pathFirstIdent(qualified_path) == AbsynUtil.pathFirstIdent(env.destinationPath) then
      // Special case, the path refers to the destination package, e.g. moving A.B.C into A.
      outPath := AbsynUtil.pathRest(path);
    else
      // Remove any part of the qualified path that's the same as the destination.
      opt_path := AbsynUtil.pathStripSamePrefix(qualified_path, env.destinationPath);

      // Replace the first identifier in the original path with the remaining qualified path.
      if isSome(opt_path) then
        SOME(new_path) := opt_path;
        outPath := AbsynUtil.pathReplaceFirst(path, new_path);
      end if;
    end if;

    // Make sure the new path still refers to the same element, and isn't shadowed by another
    // element with the same name in the destination scope or any of its enclosing scopes.
    try
      // Look up the new path from the destination scope.
      node := Lookup.lookupSimpleName(AbsynUtil.pathFirstIdent(outPath), env.destination, FAST_CONTEXT);
      false := AbsynUtil.pathPrefixOf(InstNode.fullPath(node), qualified_path);
      // If the wrong element was found, then return the fully qualified path instead.
      outPath := AbsynUtil.pathReplaceFirst(path, qualified_path);
      outPath := AbsynUtil.makeFullyQualified(outPath);
    else
    end try;
  end if;
end updateMovedPath;

function updateMovedCommentOpt
  input output Option<Absyn.Comment> cmt;
  input MoveEnv env;
algorithm
  if isSome(cmt) then
    cmt := SOME(updateMovedComment(Util.getOption(cmt), env));
  end if;
end updateMovedCommentOpt;

function updateMovedComment
  input output Absyn.Comment cmt;
  input MoveEnv env;
algorithm
  cmt.annotation_ := updateMovedAnnotationOpt(cmt.annotation_, env);
end updateMovedComment;

function updateMovedAnnotationOpt
  input output Option<Absyn.Annotation> ann;
  input MoveEnv env;
algorithm
  if isSome(ann) then
    ann := SOME(updateMovedAnnotation(Util.getOption(ann), env));
  end if;
end updateMovedAnnotationOpt;

function updateMovedAnnotation
  input output Absyn.Annotation ann;
  input MoveEnv env;
algorithm
  ann.elementArgs := list(updateMovedElementArg(a, env) for a in ann.elementArgs);
end updateMovedAnnotation;

function updateMovedSubscript
  input output Absyn.Subscript sub;
  input MoveEnv env;
algorithm
  () := match sub
    case Absyn.Subscript.SUBSCRIPT()
      algorithm
        sub.subscript := updateMovedExp(sub.subscript, env);
      then
        ();

    else ();
  end match;
end updateMovedSubscript;

function updateMovedExp
  input output Absyn.Exp exp;
  input MoveEnv env;
algorithm
  exp := AbsynUtil.traverseExp(exp, updateMovedExp_traverser, env);
end updateMovedExp;

function updateMovedExp_traverser
  input output Absyn.Exp exp;
  input output MoveEnv env;
algorithm
  () := match exp
    case Absyn.Exp.CREF()
      algorithm
        exp.componentRef := updateMovedCref(exp.componentRef, env);
      then
        ();

    case Absyn.Exp.CALL()
      algorithm
        exp.function_ := updateMovedCref(exp.function_, env);
      then
        ();

    else ();
  end match;
end updateMovedExp_traverser;

function updateMovedCref
  input output Absyn.ComponentRef cref;
  input MoveEnv env;
protected
  Absyn.Path qualified_path;
  Absyn.ComponentRef qualified_cref;
  Option<Absyn.Path> opt_path;
algorithm
  if AbsynUtil.crefIsFullyQualified(cref) or AbsynUtil.crefIsWild(cref) then
    return;
  end if;

  // Try to look up the qualified path needed to be able to find the name in
  // this scope even if the root class that contains the scope is moved elsewhere.
  try
    qualified_path :=
      Lookup.lookupSimpleNameRootPath(AbsynUtil.crefFirstIdent(cref), env.scope, FAST_CONTEXT);
  else
    // Lookup failed, leave the path unchanged.
    return;
  end try;

  // If the path we found is fully qualified it means we need to update the original cref.
  if AbsynUtil.pathIsFullyQualified(qualified_path) then
    qualified_path := AbsynUtil.makeNotFullyQualified(qualified_path);

    if AbsynUtil.pathIsIdent(qualified_path) and
       AbsynUtil.pathFirstIdent(qualified_path) == AbsynUtil.pathFirstIdent(env.destinationPath) then
      // Special case, the cref refers to the destination package, e.g. moving A.B.C into A.
      cref := AbsynUtil.crefStripFirst(cref);
    else
      // Remove any part of the qualified path that's the same as the destination.
      opt_path := AbsynUtil.pathStripSamePrefix(qualified_path, env.destinationPath);

      // Replace the first identifier in the original cref with the remaining qualified path.
      if isSome(opt_path) then
        SOME(qualified_path) := opt_path;
        qualified_cref := AbsynUtil.pathToCref(qualified_path);

        if AbsynUtil.crefIsQual(cref) then
          cref := AbsynUtil.joinCrefs(qualified_cref, AbsynUtil.crefStripFirst(cref));
        else
          cref := qualified_cref;
        end if;
      end if;
    end if;
  end if;
end updateMovedCref;

public
function translateResidualsDAE
  input Absyn.Path path;
  input String fileNamePrefix;
  output Boolean success = true;
protected
  Boolean disable_single_flow_eq;
  list<String> non_std_flags;
  FlatModel flat_model;
  Flatten.FunctionTree funcs;
  Option<SimCode.SimulationSettings> simSettings;
algorithm
  disable_single_flow_eq := FlagsUtil.set(Flags.DISABLE_SINGLE_FLOW_EQ, true);
  non_std_flags := FlagsUtil.appendConfigStringList(Flags.ALLOW_NON_STANDARD_MODELICA, "implicitParameterStartAttribute");

  try
    (flat_model, funcs) := CevalScriptBackend.runFrontEndNF(path);
    (flat_model, funcs) := InstUtil.createExtractorModel(flat_model, funcs);
    InstUtil.dumpFlatModelDebug("translateResidualsDAE", flat_model, funcs);

    simSettings := SOME(CevalScriptBackend.convertSimulationOptionsToSimCode(
      CevalScriptBackend.buildSimulationOptionsFromModelExperimentAnnotation(path, fileNamePrefix, NONE())));
    SimCodeMain.translateModelCallBackend(flat_model, funcs, path, fileNamePrefix, true, simSettings);
  else
  end try;

  FlagsUtil.setConfigStringList(Flags.ALLOW_NON_STANDARD_MODELICA, non_std_flags);
  FlagsUtil.set(Flags.DISABLE_SINGLE_FLOW_EQ, disable_single_flow_eq);
end translateResidualsDAE;

  annotation(__OpenModelica_Interface="backend_main");
end NFApi;

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
import Error;
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
import Pointer;
import Prefixes = NFPrefixes;
import ProgramUtil;
import Restriction = NFRestriction;
import Scalarize = NFScalarize;
import SimCodeMain;
import SimplifyExp = NFSimplifyExp;
import SimplifyModel = NFSimplifyModel;
import SymbolTable;
import System;
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

function evaluateAnnotationRecords
  "Evaluates the elements of an annotation as record constructor calls, e.g.
   the Line annotation of a connect equation. An element that cannot be
   evaluated is returned as name(error)."
  input Absyn.Program program;
  input Absyn.Path classPath;
  input list<Absyn.ElementArg> annotations;
  output list<String> strings = {};
protected
  Boolean b, s;
algorithm
  b := FlagsUtil.set(Flags.SCODE_INST, true);
  s := FlagsUtil.set(Flags.NF_SCALARIZE, true);

  for arg in annotations loop
    () := match arg
      case Absyn.ElementArg.MODIFICATION(path = Absyn.Path.IDENT())
        algorithm
          strings := evaluateAnnotationRecord(arg, program, classPath) :: strings;
        then
          ();

      else ();
    end match;
  end for;

  strings := listReverse(strings);
  FlagsUtil.set(Flags.SCODE_INST, b);
  FlagsUtil.set(Flags.NF_SCALARIZE, s);
end evaluateAnnotationRecords;

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

function evaluateAnnotationRecord
  input Absyn.ElementArg arg;
  input Absyn.Program program;
  input Absyn.Path classPath;
  output String str;
protected
  String name;
  Option<Absyn.Modification> opt_mod;
  list<Absyn.ElementArg> mod;
  SourceInfo info;
  InstNode cls;
  Expression exp;
algorithm
  Absyn.ElementArg.MODIFICATION(path = Absyn.Path.IDENT(name = name), modification = opt_mod, info = info) := arg;
  ErrorExt.setCheckpoint(getInstanceName());

  try
    SOME(Absyn.Modification.CLASSMOD(elementArgLst = mod)) := opt_mod;

    if AbsynUtil.onlyLiteralsInAnnotationMod(mod) then
      (_, cls) := NFInstanceAPI.mkTop(program, scodeFor(program), name);
    else
      (_, _, cls) := frontEndFront(program, classPath);
    end if;

    exp := NFInst.instExp(Absyn.Exp.CALL(Absyn.ComponentRef.CREF_IDENT(name, {}),
      AbsynUtil.createFuncargsFromElementargs(mod), {}), cls, ANNOTATION_CONTEXT, info);
    exp := Typing.typeExp(exp, ANNOTATION_CONTEXT, info);

    try
      exp := NFCeval.evalExp(exp);
    else
      exp := EvalConstants.evaluateExp(exp, info);
    end try;

    str := Expression.toString(SimplifyExp.simplify(exp));
  else
    str := name + "(error)";
  end try;

  if Flags.isSet(Flags.NF_API_NOISE) then
    ErrorExt.delCheckpoint(getInstanceName());
  else
    ErrorExt.rollBack(getInstanceName());
  end if;
end evaluateAnnotationRecord;

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
   instantiates again. Without releaseNodes the nodes stay until
   MutableWeak.clearRoots, see NFInstanceAPI.dropTopScopeCache."
  input Boolean releaseNodes = true;
algorithm
  setGlobalRoot(Global.instNFInstCacheIndex, {});
  setGlobalRoot(Global.instNFLookupCacheIndex, {});
  if releaseNodes then
    NFInstanceAPI.clearTopScopeCache();
  else
    NFInstanceAPI.dropTopScopeCache();
  end if;
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
  Typing.typeClass(inst_cls, ANNOTATION_CONTEXT);

  // Flatten and simplify the model.
  flat_model := Flatten.flatten(inst_cls, Absyn.Path.IDENT(name));
  flat_model := EvalConstants.evaluate(flat_model, ANNOTATION_CONTEXT);
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

function getBuiltinType
  "Returns the builtin type the class is derived from, or \"\" if there is none."
  input Absyn.Path classPath;
  input Absyn.Program program;
  output String name;
protected
  InstNode cls_node;
algorithm
  (_, _, cls_node) := frontEndLookup(program, classPath);
  name := builtinTypeName(cls_node);
end getBuiltinType;

function builtinTypeName
  input InstNode clsNode;
  output String name;
algorithm
  if not InstNode.isClass(clsNode) then
    name := "";
    return;
  end if;

  name := match InstNode.getClass(clsNode)
    local
      Class cls;
      Type ty;

    case cls as Class.EXPANDED_DERIVED() then builtinTypeName(cls.baseClass);
    case Class.PARTIAL_BUILTIN(ty = ty as Type.ENUMERATION())
      then "enumeration(" + stringDelimitList(ty.literals, ", ") + ")";
    case Class.PARTIAL_BUILTIN(ty = ty) guard Type.isBasic(ty) then Type.toString(ty);
    else "";
  end match;
end builtinTypeName;

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

function getInstanceDiagram
  "Returns the UML instance diagram of a model, see NFInstanceAPI.instanceDiagram,
   or writes it to a file and returns its name."
  input Absyn.Path classPath;
  input String fileName;
  input String format;
  input Integer depth;
  input list<String> exclude;
  input Boolean showConnections;
  input Boolean showProtected;
  input Boolean expandArrays;
  output Values.Value res;
protected
  String diagram;
algorithm
  if format <> "plantuml" and format <> "mermaid" and format <> "drawio" then
    Error.addCompilerError("getInstanceDiagram: unknown format " + format + ", expected plantuml, mermaid or drawio.");
    res := Values.STRING("");
    return;
  end if;

  try
    diagram := NFInstanceAPI.buildInstanceDiagram(SymbolTable.getAbsyn(), SOME(SymbolTable.getSCode()), classPath,
      NFInstanceAPI.InstanceDiagramOptions.INSTANCE_DIAGRAM_OPTIONS(format, depth, exclude, showConnections, showProtected, expandArrays));
    Inst.clearCaches();
  else
    Inst.clearCaches();
    diagram := "";
  end try;

  if not stringEmpty(fileName) and not stringEmpty(diagram) then
    System.writeFile(fileName, diagram);
    diagram := fileName;
  end if;

  res := Values.STRING(diagram);
end getInstanceDiagram;

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
  cls.body := updateNamesInClassDef(cls.body, NameEnv.MOVE(env));
end updateMovedClassPaths;

public
function renameClass
  "Renames a class and updates the references to it in the classes that are
   not read-only. Returns the new path of the class followed by the classes
   that were changed, or an empty list if the renaming failed."
  input Absyn.Path className;
  input Absyn.Path newName "A non-qualified name";
  input output Absyn.Program program;
        output list<Absyn.Path> changedClasses = {};
protected
  Absyn.Path old_path;
  Absyn.Class cls;
  InstNode top, node;
  RenameData data;
  Boolean load_missing;
algorithm
  old_path := AbsynUtil.makeNotFullyQualified(className);

  if not AbsynUtil.pathIsIdent(newName) then
    return;
  end if;

  try
    cls := ProgramUtil.getPathedClassInProgram(old_path, program);
  else
    return;
  end try;

  if cls.info.isReadOnly then
    return;
  end if;

  load_missing := Flags.getConfigBool(Flags.LOAD_MISSING_LIBRARIES);
  FlagsUtil.setConfigBool(Flags.LOAD_MISSING_LIBRARIES, false);
  ErrorExt.setCheckpoint(getInstanceName());

  try
    (_, top) := NFInstanceAPI.mkTop(program, scodeFor(program), AbsynUtil.pathString(old_path));
    node := lookupExpandedPath(AbsynUtil.makeFullyQualified(old_path), top);
    data := RenameData.RENAME_DATA(old_path, AbsynUtil.pathSetLastIdent(old_path, AbsynUtil.pathFirstIdent(newName)),
      AbsynUtil.pathLastIdent(old_path), AbsynUtil.pathFirstIdent(newName), false, InstNode.definition(node), top,
      Pointer.create(0), Pointer.create(false), Pointer.create({}));
    (program, changedClasses) := renameInProgram(program, data);
  else
  end try;

  ErrorExt.rollBack(getInstanceName());
  FlagsUtil.setConfigBool(Flags.LOAD_MISSING_LIBRARIES, load_missing);
end renameClass;

function renameComponent
  "Renames a component in a class and updates the references to it in the
   classes that are not read-only. Returns the class followed by the classes
   that were changed, or an empty list if the renaming failed."
  input Absyn.Path className;
  input String oldName;
  input String newName;
  input output Absyn.Program program;
        output list<Absyn.Path> changedClasses = {};
protected
  Absyn.Path path;
  Absyn.Class cls;
  InstNode top, node;
  RenameData data;
  Boolean load_missing;
algorithm
  path := AbsynUtil.makeNotFullyQualified(className);

  try
    cls := ProgramUtil.getPathedClassInProgram(path, program);
  else
    return;
  end try;

  if cls.info.isReadOnly then
    return;
  end if;

  load_missing := Flags.getConfigBool(Flags.LOAD_MISSING_LIBRARIES);
  FlagsUtil.setConfigBool(Flags.LOAD_MISSING_LIBRARIES, false);
  ErrorExt.setCheckpoint(getInstanceName());

  try
    (_, top) := NFInstanceAPI.mkTop(program, scodeFor(program), AbsynUtil.pathString(path));
    node := Inst.expand(lookupExpandedPath(AbsynUtil.makeFullyQualified(path), top), FAST_CONTEXT);
    data := RenameData.RENAME_DATA(path, path, oldName, newName, true, listHead(localComponents(oldName, node)), top,
      Pointer.create(0), Pointer.create(false), Pointer.create({}));
    (program, changedClasses) := renameInProgram(program, data);
  else
  end try;

  ErrorExt.rollBack(getInstanceName());
  FlagsUtil.setConfigBool(Flags.LOAD_MISSING_LIBRARIES, load_missing);
end renameComponent;

protected
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

  cls.body := updateNamesInClassDef(cls.body, NameEnv.MOVE(cls_env));
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

uniontype NameEnv
  "The environment of the updateNamesIn functions, which update the names in
   a class that is moved or in a class that refers to a renamed class."
  record MOVE
    MoveEnv env;
  end MOVE;

  record RENAME
    RenameEnv env;
  end RENAME;
end NameEnv;

uniontype RenameData
  record RENAME_DATA
    Absyn.Path oldPath;
    Absyn.Path newPath;
    String oldName;
    String newName;
    Boolean isComponent "The renamed element is a component, not a class";
    SCode.Element definition "The definition of the renamed element";
    InstNode top;
    Pointer<Integer> changes;
    Pointer<Boolean> renamed;
    Pointer<list<Absyn.Path>> changedClasses;
  end RENAME_DATA;
end RenameData;

uniontype RenameScope
  "A class scope that is only looked up and expanded when a name is looked up in it."
  record RENAME_SCOPE
    String name;
    Option<RenameScope> parent;
    Pointer<InstNode> node;
  end RENAME_SCOPE;
end RenameScope;

uniontype ModTarget
  "The class that a modifier modifies. It is only looked up for a
   redeclaration that has the name of the renamed class."
  record NO_TARGET
  end NO_TARGET;

  record SELF_TARGET
    "The class that an annotation belongs to, for its choices."
  end SELF_TARGET;

  record CLASS_TARGET
    Absyn.Path path;
  end CLASS_TARGET;

  record ELEMENT_TARGET
    ModTarget parent;
    Absyn.Path name;
  end ELEMENT_TARGET;

  record INHERITED_TARGET
    "The inherited class that a class extends modifies."
    String name;
  end INHERITED_TARGET;
end ModTarget;

uniontype RenameEnv
  record RENAME_ENV
    Absyn.Path path "The path of the class before the renaming";
    Absyn.Path newPath "The path of the class after the renaming";
    RenameScope scope;
    Pointer<Boolean> changed;
    ModTarget target;
    Boolean isRenamed "The class is the renamed class or a redeclaration of it";
    Boolean inGraphics;
    RenameData data;
  end RENAME_ENV;
end RenameEnv;

function updateNamesInClassDef
  input output Absyn.ClassDef cdef;
  input NameEnv env;
protected
  NameEnv mod_env;
algorithm
  () := match cdef
    case Absyn.ClassDef.PARTS()
      algorithm
        cdef.classParts := list(updateNamesInClassPart(p, env) for p in cdef.classParts);
        cdef.ann := list(updateNamesInAnnotation(a, env) for a in cdef.ann);
      then
        ();

    case Absyn.ClassDef.DERIVED()
      algorithm
        mod_env := withModTarget(env, typeSpecTarget(cdef.typeSpec));
        cdef.arguments := list(updateNamesInElementArg(a, mod_env) for a in cdef.arguments);
        cdef.typeSpec := updateNamesInTypeSpec(cdef.typeSpec, env);
        cdef.attributes := updateNamesInElementAttributes(cdef.attributes, env);
        cdef.comment := updateNamesInCommentOpt(cdef.comment, env);
      then
        ();

    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        mod_env := withModTarget(env, ModTarget.INHERITED_TARGET(cdef.baseClassName));
        cdef.modifications := list(updateNamesInElementArg(a, mod_env) for a in cdef.modifications);
        cdef.parts := list(updateNamesInClassPart(p, env) for p in cdef.parts);
        cdef.ann := list(updateNamesInAnnotation(a, env) for a in cdef.ann);
      then
        ();

    case Absyn.ClassDef.OVERLOAD()
      algorithm
        cdef.functionNames := list(updatePath(p, env) for p in cdef.functionNames);
        cdef.comment := updateNamesInCommentOpt(cdef.comment, env);
      then
        ();

    case Absyn.ClassDef.PDER()
      algorithm
        cdef.functionName := updatePath(cdef.functionName, env);
        cdef.comment := updateNamesInCommentOpt(cdef.comment, env);
      then
        ();

    else ();
  end match;
end updateNamesInClassDef;

function updateNamesInClassPart
  input output Absyn.ClassPart part;
  input NameEnv env;
algorithm
  () := match part
    case Absyn.ClassPart.PUBLIC()
      algorithm
        part.contents := list(updateNamesInElementItem(i, env) for i in part.contents);
      then
        ();

    case Absyn.ClassPart.PROTECTED()
      algorithm
        part.contents := list(updateNamesInElementItem(i, env) for i in part.contents);
      then
        ();

    case Absyn.ClassPart.EQUATIONS()
      algorithm
        part.contents := AbsynUtil.traverseEquationItemListBidir(part.contents,
          updateNamesInExp_traverser, AbsynUtil.dummyTraverseExp, env);
      then
        ();

    case Absyn.ClassPart.INITIALEQUATIONS()
      algorithm
        part.contents := AbsynUtil.traverseEquationItemListBidir(part.contents,
          updateNamesInExp_traverser, AbsynUtil.dummyTraverseExp, env);
      then
        ();

    case Absyn.ClassPart.ALGORITHMS()
      algorithm
        part.contents := AbsynUtil.traverseAlgorithmItemListBidir(part.contents,
          updateNamesInExp_traverser, AbsynUtil.dummyTraverseExp, env);
      then
        ();

    case Absyn.ClassPart.INITIALALGORITHMS()
      algorithm
        part.contents := AbsynUtil.traverseAlgorithmItemListBidir(part.contents,
          updateNamesInExp_traverser, AbsynUtil.dummyTraverseExp, env);
      then
        ();

    case Absyn.ClassPart.EXTERNAL()
      algorithm
        part.annotation_ := updateNamesInAnnotationOpt(part.annotation_, env);
      then
        ();

    else ();
  end match;
end updateNamesInClassPart;

function updateNamesInElementItem
  input output Absyn.ElementItem item;
  input NameEnv env;
algorithm
  () := match item
    case Absyn.ElementItem.ELEMENTITEM()
      algorithm
        item.element := updateNamesInElement(item.element, env);
      then
        ();

    else ();
  end match;
end updateNamesInElementItem;

type DeclarationKind = enumeration(
  LOCAL "An element of the class",
  REDECLARED "An element redeclaration in the class",
  MODIFIER "A redeclaration in a modifier"
);

function updateNamesInElement
  input output Absyn.Element element;
  input NameEnv env;
algorithm
  () := match element
    case Absyn.Element.ELEMENT()
      algorithm
        element.specification := updateNamesInElementSpec(element.specification, env,
          if isRedeclare(element.redeclareKeywords) then DeclarationKind.REDECLARED else DeclarationKind.LOCAL);

        if isSome(element.constrainClass) then
          element.constrainClass :=
            SOME(updateNamesInConstrainClass(Util.getOption(element.constrainClass), env));
        end if;
      then
        ();

    else ();
  end match;
end updateNamesInElement;

function isRedeclare
  input Option<Absyn.RedeclareKeywords> keywords;
  output Boolean res;
algorithm
  res := match keywords
    case SOME(Absyn.RedeclareKeywords.REDECLARE()) then true;
    case SOME(Absyn.RedeclareKeywords.REDECLARE_REPLACEABLE()) then true;
    else false;
  end match;
end isRedeclare;

function updateNamesInConstrainClass
  input output Absyn.ConstrainClass cc;
  input NameEnv env;
algorithm
  cc.elementSpec := updateNamesInElementSpec(cc.elementSpec, env);
  cc.comment := updateNamesInCommentOpt(cc.comment, env);
end updateNamesInConstrainClass;

function updateNamesInElementSpec
  input output Absyn.ElementSpec spec;
  input NameEnv env;
  input DeclarationKind kind = DeclarationKind.LOCAL;
protected
  NameEnv mod_env;
algorithm
  () := match spec
    case Absyn.ElementSpec.CLASSDEF()
      algorithm
        spec.class_ := updateNestedClass(spec.class_, kind == DeclarationKind.REDECLARED, env);
      then
        ();

    case Absyn.ElementSpec.EXTENDS()
      algorithm
        mod_env := withModTarget(env, ModTarget.CLASS_TARGET(spec.path));
        spec.elementArg := list(updateNamesInElementArg(a, mod_env) for a in spec.elementArg);
        spec.path := updatePath(spec.path, env);
        spec.annotationOpt := updateNamesInAnnotationOpt(spec.annotationOpt, env);
      then
        ();

    case Absyn.ElementSpec.IMPORT()
      algorithm
        spec.import_ := updateImport(spec.import_, env);
      then
        ();

    case Absyn.ElementSpec.COMPONENTS()
      algorithm
        mod_env := withModTarget(env, typeSpecTarget(spec.typeSpec));
        spec.components := list(updateNamesInComponentItem(c, kind, env, mod_env) for c in spec.components);
        spec.attributes := updateNamesInElementAttributes(spec.attributes, env);
        spec.typeSpec := updateNamesInTypeSpec(spec.typeSpec, env);
      then
        ();

    else ();
  end match;
end updateNamesInElementSpec;

function updateNamesInRedeclaredSpec
  input output Absyn.ElementSpec spec;
  input NameEnv env;
algorithm
  () := match spec
    case Absyn.ElementSpec.CLASSDEF()
      algorithm
        spec.class_ := updateRedeclaredClass(spec.class_, env);
      then
        ();

    else
      algorithm
        spec := updateNamesInElementSpec(spec, env, DeclarationKind.MODIFIER);
      then
        ();
  end match;
end updateNamesInRedeclaredSpec;

function updateNamesInElementAttributes
  input output Absyn.ElementAttributes attr;
  input NameEnv env;
algorithm
  if not listEmpty(attr.arrayDim) then
    attr.arrayDim := list(updateNamesInSubscript(s, env) for s in attr.arrayDim);
  end if;
end updateNamesInElementAttributes;

function updateNamesInElementArg
  input output Absyn.ElementArg arg;
  input NameEnv env;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION()
      algorithm
        if isSome(arg.modification) then
          arg.modification := SOME(updateNamesInModification(Util.getOption(arg.modification),
            withElementTarget(env, arg.path)));
        end if;

        arg.path := updateModifiedName(arg.path, env);
      then
        ();

    case Absyn.ElementArg.REDECLARATION()
      algorithm
        arg.elementSpec := updateNamesInRedeclaredSpec(arg.elementSpec, env);

        if isSome(arg.constrainClass) then
          arg.constrainClass := SOME(updateNamesInConstrainClass(Util.getOption(arg.constrainClass), env));
        end if;
      then
        ();

    else ();
  end match;
end updateNamesInElementArg;

function updateNamesInModification
  input output Absyn.Modification mod;
  input NameEnv env;
protected
  Absyn.EqMod eq_mod;
algorithm
  mod.elementArgLst := list(updateNamesInElementArg(a, env) for a in mod.elementArgLst);

  eq_mod := mod.eqMod;
  () := match eq_mod
    case Absyn.EqMod.EQMOD()
      algorithm
        eq_mod.exp := updateNamesInExp(eq_mod.exp, env);
        mod.eqMod := eq_mod;
      then
        ();

    else ();
  end match;
end updateNamesInModification;

function updateNamesInComponentItem
  input output Absyn.ComponentItem item;
  input DeclarationKind kind;
  input NameEnv env;
  input NameEnv modEnv "The environment for the modifier, which modifies the type of the component";
protected
  Absyn.Component comp;
  NameEnv cmt_env;
algorithm
  (item, cmt_env) := updateComponentName(item, kind, env);
  comp := item.component;

  if not listEmpty(comp.arrayDim) then
    comp.arrayDim := list(updateNamesInSubscript(s, env) for s in comp.arrayDim);
  end if;

  if isSome(comp.modification) then
    comp.modification := SOME(updateNamesInModification(Util.getOption(comp.modification), modEnv));
  end if;

  item.component := comp;

  if isSome(item.condition) then
    item.condition := SOME(updateNamesInExp(Util.getOption(item.condition), env));
  end if;

  item.comment := updateNamesInCommentOpt(item.comment, cmt_env);
end updateNamesInComponentItem;

function updateNamesInTypeSpec
  input output Absyn.TypeSpec ty;
  input NameEnv env;
algorithm
  () := match ty
    case Absyn.TypeSpec.TPATH()
      algorithm
        ty.path := updatePath(ty.path, env);

        if isSome(ty.arrayDim) then
          ty.arrayDim := SOME(list(updateNamesInSubscript(s, env) for s in Util.getOption(ty.arrayDim)));
        end if;
      then
        ();

    case Absyn.TypeSpec.TCOMPLEX()
      algorithm
        ty.path := updatePath(ty.path, env);
        ty.typeSpecs := list(updateNamesInTypeSpec(t, env) for t in ty.typeSpecs);

        if isSome(ty.arrayDim) then
          ty.arrayDim := SOME(list(updateNamesInSubscript(s, env) for s in Util.getOption(ty.arrayDim)));
        end if;
      then
        ();

  end match;
end updateNamesInTypeSpec;

function updateNamesInCommentOpt
  input output Option<Absyn.Comment> cmt;
  input NameEnv env;
protected
  Absyn.Comment c;
algorithm
  if isSome(cmt) then
    SOME(c) := cmt;
    c.annotation_ := updateNamesInAnnotationOpt(c.annotation_, env);
    cmt := SOME(c);
  end if;
end updateNamesInCommentOpt;

function updateNamesInAnnotationOpt
  input output Option<Absyn.Annotation> ann;
  input NameEnv env;
algorithm
  if isSome(ann) then
    ann := SOME(updateNamesInAnnotation(Util.getOption(ann), env));
  end if;
end updateNamesInAnnotationOpt;

function updateNamesInAnnotation
  input output Absyn.Annotation ann;
  input NameEnv env;
algorithm
  ann.elementArgs := list(updateNamesInAnnotationArg(a, env) for a in ann.elementArgs);
end updateNamesInAnnotation;

function updateNamesInAnnotationArg
  "The names in graphical annotations (e.g. Line) refer to the graphical
   primitives, also when a class with the same name is in scope."
  input output Absyn.ElementArg arg;
  input NameEnv env;
algorithm
  arg := match env
    case NameEnv.MOVE()
      then if isGraphicalAnnotation(arg) then arg else updateNamesInElementArg(arg, env);
    case NameEnv.RENAME() then renameInAnnotationArg(arg, env.env);
  end match;
end updateNamesInAnnotationArg;

function isGraphicalAnnotation
  input Absyn.ElementArg arg;
  output Boolean res;
protected
  String name;
algorithm
  res := match arg
    case Absyn.ElementArg.MODIFICATION(path = Absyn.Path.IDENT(name = name))
      then name == "Icon" or name == "Diagram";
    else false;
  end match;
end isGraphicalAnnotation;

function updateNamesInSubscript
  input output Absyn.Subscript sub;
  input NameEnv env;
algorithm
  () := match sub
    case Absyn.Subscript.SUBSCRIPT()
      algorithm
        sub.subscript := updateNamesInExp(sub.subscript, env);
      then
        ();

    else ();
  end match;
end updateNamesInSubscript;

function updateNamesInExp
  input output Absyn.Exp exp;
  input NameEnv env;
algorithm
  exp := AbsynUtil.traverseExp(exp, updateNamesInExp_traverser, env);
end updateNamesInExp;

function updateNamesInExp_traverser
  input output Absyn.Exp exp;
  input output NameEnv env;
protected
  Absyn.ComponentRef cref;
  Absyn.FunctionArgs args;
  String str;
algorithm
  () := match exp
    case Absyn.Exp.CREF()
      algorithm
        cref := updateCref(exp.componentRef, env);

        if not referenceEq(cref, exp.componentRef) then
          exp.componentRef := cref;
        end if;
      then
        ();

    case Absyn.Exp.CALL()
      algorithm
        args := updateCallArgs(exp.functionArgs, exp.function_, env);

        if not referenceEq(args, exp.functionArgs) then
          exp.functionArgs := args;
        end if;

        cref := updateFunctionName(exp.function_, env);

        if not referenceEq(cref, exp.function_) then
          exp.function_ := cref;
        end if;
      then
        ();

    case Absyn.Exp.PARTEVALFUNCTION()
      algorithm
        cref := updateFunctionName(exp.function_, env);

        if not referenceEq(cref, exp.function_) then
          exp.function_ := cref;
        end if;
      then
        ();

    case Absyn.Exp.STRING()
      algorithm
        str := updateString(exp.value, env);

        if not referenceEq(str, exp.value) then
          exp.value := str;
        end if;
      then
        ();

    else ();
  end match;
end updateNamesInExp_traverser;

function updatePath
  "Updates a class path. A renamed component cannot be part of one."
  input Absyn.Path path;
  input NameEnv env;
  output Absyn.Path outPath;
protected
  RenameEnv e;
algorithm
  outPath := match env
    case NameEnv.MOVE() then updateMovedPath(path, env.env);
    case NameEnv.RENAME(env = e)
      then if e.inGraphics or e.data.isComponent then path else renamePath(path, e);
  end match;
end updatePath;

function updateCref
  input Absyn.ComponentRef cref;
  input NameEnv env;
  output Absyn.ComponentRef outCref;
protected
  RenameEnv e;
algorithm
  outCref := match env
    case NameEnv.MOVE() then updateMovedCref(cref, env.env);
    case NameEnv.RENAME(env = e)
      then if e.data.isComponent then renameComponentCref(cref, e)
           elseif e.inGraphics then cref else renameCref(cref, e);
  end match;
end updateCref;

function updateFunctionName
  input Absyn.ComponentRef cref;
  input NameEnv env;
  output Absyn.ComponentRef outCref;
protected
  RenameEnv e;
algorithm
  outCref := match env
    case NameEnv.MOVE() then updateMovedCref(cref, env.env);
    case NameEnv.RENAME(env = e)
      then if e.inGraphics or e.data.isComponent then cref else renameCref(cref, e);
  end match;
end updateFunctionName;

function updateCallArgs
  input Absyn.FunctionArgs args;
  input Absyn.ComponentRef functionName;
  input NameEnv env;
  output Absyn.FunctionArgs outArgs;
protected
  RenameEnv e;
algorithm
  outArgs := match env
    case NameEnv.RENAME(env = e) guard e.data.isComponent then renameNamedArgs(args, functionName, e);
    else args;
  end match;
end updateCallArgs;

function updateModifiedName
  "Updates the name of a modified element, which is an element of the class
   that the modifier modifies."
  input Absyn.Path name;
  input NameEnv env;
  output Absyn.Path outName;
protected
  RenameEnv e;
algorithm
  outName := match env
    case NameEnv.RENAME(env = e) guard e.data.isComponent then renameModifiedName(name, e);
    else name;
  end match;
end updateModifiedName;

function updateComponentName
  "Renames a declared component if it is the renamed component or a
   redeclaration of it. Also returns the environment for its comment."
  input output Absyn.ComponentItem item;
  input DeclarationKind kind;
  input NameEnv env;
  output NameEnv commentEnv = env;
protected
  RenameEnv e;
algorithm
  () := match env
    case NameEnv.RENAME(env = e)
      guard e.data.isComponent and item.component.name == e.data.oldName
      algorithm
        if isRenamedComponentDeclaration(kind, e) then
          item := renameComponentItem(item, e.data.newName);
          markChanged(e);
          e.isRenamed := true;
          commentEnv := NameEnv.RENAME(e);
        end if;
      then
        ();

    else ();
  end match;
end updateComponentName;

function updateString
  input String str;
  input NameEnv env;
  output String outStr;
protected
  RenameEnv e;
algorithm
  outStr := match env
    case NameEnv.RENAME(env = e)
      then if not e.data.isComponent then renameURIs(str, e)
           elseif e.inGraphics then renameTextReferences(str, e) else str;
    else str;
  end match;
end updateString;

function updateImport
  "Import paths are fully qualified, so they only need to be updated for a renaming."
  input Absyn.Import imp;
  input NameEnv env;
  output Absyn.Import outImp;
protected
  RenameEnv e;
algorithm
  outImp := match env
    case NameEnv.RENAME(env = e)
      then if e.data.isComponent then renameComponentInImport(imp, e) else renameInImport(imp, e);
    else imp;
  end match;
end updateImport;

function updateNestedClass
  input output Absyn.Class cls;
  input Boolean redeclared;
  input NameEnv env;
protected
  RenameEnv e;
algorithm
  cls := match env
    case NameEnv.MOVE() then updateMovedClass(cls, env.env);
    case NameEnv.RENAME(env = e)
      then renameInClass(cls, redeclared, e.scope, SOME(e.path), SOME(e.newPath), e.data);
  end match;
end updateNestedClass;

function updateRedeclaredClass
  "A class in a redeclaration is not an element of the class with the
   modifier, so the names in it are looked up in the same scope."
  input output Absyn.Class cls;
  input NameEnv env;
algorithm
  cls := match env
    case NameEnv.MOVE()
      algorithm
        cls.body := updateNamesInClassDef(cls.body, env);
      then
        cls;

    case NameEnv.RENAME() then renameInRedeclaredClass(cls, env.env);
  end match;
end updateRedeclaredClass;

function withModTarget
  input NameEnv env;
  input ModTarget target;
  output NameEnv outEnv = env;
protected
  RenameEnv e;
algorithm
  () := match env
    case NameEnv.RENAME(env = e)
      algorithm
        e.target := target;
        outEnv := NameEnv.RENAME(e);
      then
        ();

    else ();
  end match;
end withModTarget;

function withElementTarget
  "Sets the target of a modifier to the class of the modified element."
  input NameEnv env;
  input Absyn.Path name;
  output NameEnv outEnv = env;
protected
  RenameEnv e;
algorithm
  () := match env
    case NameEnv.RENAME(env = e)
      algorithm
        e.target := match e.target
          case ModTarget.NO_TARGET() then e.target;
          case ModTarget.SELF_TARGET() then e.target;
          else ModTarget.ELEMENT_TARGET(e.target, name);
        end match;

        outEnv := NameEnv.RENAME(e);
      then
        ();

    else ();
  end match;
end withElementTarget;

function typeSpecTarget
  input Absyn.TypeSpec ty;
  output ModTarget target;
algorithm
  target := match ty
    case Absyn.TypeSpec.TPATH() then ModTarget.CLASS_TARGET(ty.path);
    else ModTarget.NO_TARGET();
  end match;
end typeSpecTarget;

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

function renameInClass
  input output Absyn.Class cls;
  input Boolean redeclared "The class is an element redeclaration";
  input RenameScope parentScope;
  input Option<Absyn.Path> parentPath;
  input Option<Absyn.Path> newParentPath;
  input RenameData data;
protected
  Absyn.Path path;
  Boolean is_target, renamed = false;
  RenameEnv env;
  RenameScope scope;
  Integer changes;
  Absyn.ClassDef body;
algorithm
  if cls.info.isReadOnly then
    return;
  end if;

  path := suffixOptPath(parentPath, cls.name);
  is_target := AbsynUtil.pathEqual(path, data.oldPath);

  if data.isComponent then
    renamed := false;
  elseif is_target then
    renamed := true;
  elseif cls.name == data.oldName and (redeclared or isClassExtends(cls)) then
    renamed := redeclaresRenamedClass(parentScope, data);
  end if;

  scope := if classHasScope(cls) then
    RenameScope.RENAME_SCOPE(cls.name, SOME(parentScope), Pointer.create(InstNode.EMPTY_NODE())) else parentScope;
  env := RenameEnv.RENAME_ENV(path, suffixOptPath(newParentPath, if renamed then data.newName else cls.name),
    scope, Pointer.create(false), ModTarget.NO_TARGET(), renamed, false, data);

  changes := Pointer.access(data.changes);
  body := updateNamesInClassDef(cls.body, NameEnv.RENAME(env));

  if renamed then
    cls.name := data.newName;
    body := setClassExtendsName(body, data.newName);
    Pointer.update(data.changes, Pointer.access(data.changes) + 1);
  end if;

  if is_target then
    if not data.isComponent then
      Pointer.update(data.renamed, true);
    end if;
  elseif renamed or Pointer.access(env.changed) then
    Pointer.update(data.changedClasses, env.newPath :: Pointer.access(data.changedClasses));
  end if;

  if changes <> Pointer.access(data.changes) then
    cls.body := body;
  end if;
end renameInClass;

function isClassExtends
  input Absyn.Class cls;
  output Boolean res;
algorithm
  res := match cls.body
    case Absyn.ClassDef.CLASS_EXTENDS() then true;
    else false;
  end match;
end isClassExtends;

function setClassExtendsName
  input output Absyn.ClassDef cdef;
  input String name;
algorithm
  () := match cdef
    case Absyn.ClassDef.CLASS_EXTENDS()
      algorithm
        cdef.baseClassName := name;
      then
        ();

    else ();
  end match;
end setClassExtendsName;

function renameInRedeclaredClass
  input output Absyn.Class cls;
  input RenameEnv env;
protected
  RenameEnv e = env;
algorithm
  if cls.name == env.data.oldName and not env.data.isComponent then
    e.isRenamed := modTargetHasRenamedElement(env);
  else
    e.isRenamed := false;
  end if;

  if e.isRenamed then
    cls.name := env.data.newName;
    markChanged(env);
  end if;

  e.target := ModTarget.NO_TARGET();
  cls.body := updateNamesInClassDef(cls.body, NameEnv.RENAME(e));
end renameInRedeclaredClass;

function renameInAnnotationArg
  input output Absyn.ElementArg arg;
  input RenameEnv env;
protected
  RenameEnv e = env;
algorithm
  if isGraphicalAnnotation(arg) then
    e.inGraphics := true;
    arg := updateNamesInElementArg(arg, NameEnv.RENAME(e));
  elseif isUsesAnnotation(arg) and not env.data.isComponent then
    arg := renameInUses(arg, env);
  else
    e.target := if env.isRenamed then ModTarget.SELF_TARGET() else ModTarget.NO_TARGET();
    arg := updateNamesInElementArg(arg, NameEnv.RENAME(e));
  end if;
end renameInAnnotationArg;

function isUsesAnnotation
  input Absyn.ElementArg arg;
  output Boolean res;
algorithm
  res := match arg
    case Absyn.ElementArg.MODIFICATION(path = Absyn.Path.IDENT(name = "uses")) then true;
    else false;
  end match;
end isUsesAnnotation;

function renameInUses
  "Renames the library in a uses annotation when a top-level class is renamed."
  input output Absyn.ElementArg arg;
  input RenameEnv env;
protected
  Absyn.Modification mod;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION(modification = SOME(mod))
      guard AbsynUtil.pathIsIdent(env.data.oldPath)
      algorithm
        mod.elementArgLst := list(renameUsedLibrary(a, env) for a in mod.elementArgLst);
        arg.modification := SOME(mod);
      then
        ();

    else ();
  end match;
end renameInUses;

function renameUsedLibrary
  input output Absyn.ElementArg arg;
  input RenameEnv env;
protected
  String name;
algorithm
  () := match arg
    case Absyn.ElementArg.MODIFICATION(path = Absyn.Path.IDENT(name = name))
      guard name == env.data.oldName
      algorithm
        arg.path := Absyn.Path.IDENT(env.data.newName);
        markChanged(env);
      then
        ();

    else ();
  end match;
end renameUsedLibrary;

function renameURIs
  "Updates the modelica:// URIs that refer to the renamed class or to a class in it."
  input output String str;
  input RenameEnv env;
protected
  String uri, new_uri, rest;
  list<String> parts = {};
  Integer i, next, len;
algorithm
  uri := "modelica://" + AbsynUtil.pathString(env.data.oldPath);
  i := System.stringFind(str, uri);

  if i < 0 then
    return;
  end if;

  new_uri := "modelica://" + AbsynUtil.pathString(env.data.newPath);
  rest := str;

  while i >= 0 loop
    if i > 0 then
      parts := substring(rest, 1, i) :: parts;
    end if;

    next := i + stringLength(uri) + 1;
    len := stringLength(rest);

    if next > len or not isIdentChar(stringGet(rest, next)) then
      parts := new_uri :: parts;
      markChanged(env);
    else
      parts := uri :: parts;
    end if;

    rest := if next > len then "" else substring(rest, next, len);
    i := System.stringFind(rest, uri);
  end while;

  str := stringAppendList(listReverse(rest :: parts));
end renameURIs;

function isIdentChar
  input Integer c;
  output Boolean res = (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95;
end isIdentChar;

function renameInImport
  input output Absyn.Import imp;
  input RenameEnv env;
algorithm
  () := match imp
    case Absyn.Import.NAMED_IMPORT()
      algorithm
        imp.path := renamePath(imp.path, env, isImport = true);
      then
        ();

    case Absyn.Import.QUAL_IMPORT()
      algorithm
        imp.path := renamePath(imp.path, env, isImport = true);
      then
        ();

    case Absyn.Import.UNQUAL_IMPORT()
      algorithm
        imp.path := renamePath(imp.path, env, isImport = true);
      then
        ();

    case Absyn.Import.GROUP_IMPORT()
      algorithm
        imp.groups := list(renameInGroupImport(g, imp.prefix, env) for g in imp.groups);
        imp.prefix := renamePath(imp.prefix, env, isImport = true);
      then
        ();

  end match;
end renameInImport;

function renameInGroupImport
  input output Absyn.GroupImport group;
  input Absyn.Path prefix;
  input RenameEnv env;
protected
  String name;
algorithm
  name := match group
    case Absyn.GroupImport.GROUP_IMPORT_NAME() then group.name;
    case Absyn.GroupImport.GROUP_IMPORT_RENAME() then group.name;
  end match;

  if name == env.data.oldName and
     refersToRenamedClass(AbsynUtil.makeFullyQualified(AbsynUtil.suffixPath(prefix, name)), env) then
    group := match group
      case Absyn.GroupImport.GROUP_IMPORT_NAME() then Absyn.GroupImport.GROUP_IMPORT_NAME(env.data.newName);
      case Absyn.GroupImport.GROUP_IMPORT_RENAME()
        then Absyn.GroupImport.GROUP_IMPORT_RENAME(group.rename, env.data.newName);
    end match;

    markChanged(env);
  end if;
end renameInGroupImport;

function renamePath
  input Absyn.Path path;
  input RenameEnv env;
  input Boolean isImport = false;
  output Absyn.Path outPath = path;
protected
  Absyn.ComponentRef cref, new_cref;
algorithm
  cref := AbsynUtil.pathToCref(path);
  new_cref := renameCref(cref, env, isImport);

  if not referenceEq(cref, new_cref) then
    outPath := AbsynUtil.crefToPath(new_cref);
  end if;
end renamePath;

function renameCref
  "Renames the identifier in the name that refers to the renamed class. The
   name is fully qualified if the new name would refer to another element."
  input output Absyn.ComponentRef cref;
  input RenameEnv env;
  input Boolean isImport = false;
protected
  Integer index;
  Absyn.ComponentRef qualified_cref;
algorithm
  index := renamedIdentIndex(cref, env, isImport);

  if index == 0 then
    return;
  end if;

  if index == 1 and not isImport and not AbsynUtil.crefIsFullyQualified(cref) and isShadowed(env) then
    qualified_cref := AbsynUtil.pathToCref(env.data.newPath);

    if AbsynUtil.crefIsQual(cref) then
      qualified_cref := AbsynUtil.joinCrefs(qualified_cref, AbsynUtil.crefStripFirst(cref));
    end if;

    cref := AbsynUtil.crefMakeFullyQualified(qualified_cref);
  else
    cref := setCrefIdent(cref, index, env.data.newName);
  end if;

  markChanged(env);
end renameCref;

function renamedIdentIndex
  "Returns the position of the identifier in the name that refers to the
   renamed class, or 0 if the name does not refer to it."
  input Absyn.ComponentRef cref;
  input RenameEnv env;
  input Boolean isImport;
  output Integer index = 0;
protected
  list<String> idents;
  Absyn.Path prefix;
  Integer i = 0;
algorithm
  idents := crefIdents(cref);

  if not listMember(env.data.oldName, idents) then
    return;
  end if;

  for id in idents loop
    i := i + 1;

    if id == env.data.oldName then
      prefix := AbsynUtil.stringListPath(List.firstN(idents, i));

      if isImport or AbsynUtil.crefIsFullyQualified(cref) then
        prefix := AbsynUtil.makeFullyQualified(prefix);
      end if;

      if refersToRenamedClass(prefix, env) then
        index := i;
        return;
      end if;
    end if;
  end for;
end renamedIdentIndex;

function crefIdents
  input Absyn.ComponentRef cref;
  output list<String> idents;
algorithm
  idents := match cref
    case Absyn.ComponentRef.CREF_FULLYQUALIFIED() then crefIdents(cref.componentRef);
    case Absyn.ComponentRef.CREF_QUAL() then cref.name :: crefIdents(cref.componentRef);
    case Absyn.ComponentRef.CREF_IDENT() then {cref.name};
    else {};
  end match;
end crefIdents;

function setCrefIdent
  input output Absyn.ComponentRef cref;
  input Integer index;
  input String name;
algorithm
  () := match cref
    case Absyn.ComponentRef.CREF_FULLYQUALIFIED()
      algorithm
        cref.componentRef := setCrefIdent(cref.componentRef, index, name);
      then
        ();

    case Absyn.ComponentRef.CREF_QUAL()
      algorithm
        if index == 1 then
          cref.name := name;
        else
          cref.componentRef := setCrefIdent(cref.componentRef, index - 1, name);
        end if;
      then
        ();

    case Absyn.ComponentRef.CREF_IDENT()
      algorithm
        cref.name := name;
      then
        ();

  end match;
end setCrefIdent;

function refersToRenamedClass
  input Absyn.Path path;
  input RenameEnv env;
  output Boolean res;
algorithm
  try
    res := isRenamedClassOrRedeclaration(lookupExpandedPath(path, lookupScope(path, env)), env.data);
  else
    res := false;
  end try;
end refersToRenamedClass;

function isShadowed
  "Returns true if the new name of the class already refers to an element in
   the scope of the environment."
  input RenameEnv env;
  output Boolean shadowed;
algorithm
  try
    lookupExpandedSimpleName(env.data.newName, getScope(env.scope));
    shadowed := true;
  else
    shadowed := false;
  end try;
end isShadowed;

function markChanged
  input RenameEnv env;
algorithm
  Pointer.update(env.changed, true);
  Pointer.update(env.data.changes, Pointer.access(env.data.changes) + 1);
end markChanged;

function renameInProgram
  input output Absyn.Program program;
  input RenameData data;
  output list<Absyn.Path> changedClasses = {};
protected
  RenameScope top_scope;
  list<Absyn.Class> classes;
algorithm
  top_scope := RenameScope.RENAME_SCOPE("", NONE(), Pointer.create(data.top));
  classes := list(renameInClass(c, false, top_scope, NONE(), NONE(), data) for c in program.classes);

  if Pointer.access(data.renamed) then
    program.classes := classes;
    changedClasses := (if data.isComponent then data.oldPath else data.newPath) ::
                      listReverse(Pointer.access(data.changedClasses));
  end if;
end renameInProgram;

uniontype NameElement
  record CLASS_ELEMENT
    InstNode node;
  end CLASS_ELEMENT;

  record COMPONENT_ELEMENT
    SCode.Element definition;
    InstNode scope "The class that declares the component";
  end COMPONENT_ELEMENT;
end NameElement;

function isRenamedComponentDeclaration
  input DeclarationKind kind;
  input RenameEnv env;
  output Boolean res;
algorithm
  res := match kind
    case DeclarationKind.LOCAL then AbsynUtil.pathEqual(env.path, env.data.oldPath);
    case DeclarationKind.REDECLARED then redeclaresRenamedComponent(env);
    case DeclarationKind.MODIFIER then modTargetHasRenamedElement(env);
  end match;

  if res and kind == DeclarationKind.LOCAL then
    Pointer.update(env.data.renamed, true);
  end if;
end isRenamedComponentDeclaration;

function redeclaresRenamedComponent
  "Returns true if the class inherits a component with the old name that is
   the renamed component or a redeclaration of it."
  input RenameEnv env;
  output Boolean res;
protected
  SCode.Element def;
  InstNode scope;
algorithm
  try
    (def, scope) := findComponentInBases(env.data.oldName, baseClasses(getScope(env.scope)));
    res := isRenamedComponent(def, scope, env.data);
  else
    res := false;
  end try;
end redeclaresRenamedComponent;

function isRenamedComponentElement
  input NameElement element;
  input RenameData data;
  output Boolean res;
algorithm
  res := match element
    case NameElement.COMPONENT_ELEMENT()
      guard SCodeUtil.getElementName(element.definition) == data.oldName
      then isRenamedComponent(element.definition, element.scope, data);
    else false;
  end match;
end isRenamedComponentElement;

function isRenamedComponent
  "Returns true if the component is the renamed component or a redeclaration of it."
  input SCode.Element definition;
  input InstNode scope "The class that declares the component";
  input RenameData data;
  output Boolean res;
protected
  SCode.Element def;
  InstNode base_scope;
algorithm
  if referenceEq(definition, data.definition) then
    res := true;
  elseif SCodeUtil.isElementRedeclare(definition) then
    try
      (def, base_scope) := findComponentInBases(SCodeUtil.getElementName(definition), baseClasses(scope));
      res := isRenamedComponent(def, base_scope, data);
    else
      res := false;
    end try;
  else
    res := false;
  end if;
end isRenamedComponent;

function renameComponentItem
  input output Absyn.ComponentItem item;
  input String name;
protected
  Absyn.Component comp = item.component;
algorithm
  comp.name := name;
  item.component := comp;
end renameComponentItem;

function renameComponentCref
  "Renames the identifiers in a component reference that refer to the renamed component."
  input output Absyn.ComponentRef cref;
  input RenameEnv env;
protected
  list<String> idents, rest;
  list<Integer> indices = {};
  String id;
algorithm
  idents := crefIdents(cref);

  if not listMember(env.data.oldName, idents) then
    return;
  end if;

  id :: rest := idents;

  try
    indices := renamedComponentIndices(rest,
      if AbsynUtil.crefIsFullyQualified(cref) then lookupElementInClass(id, env.data.top)
      else lookupNameElement(id, getScope(env.scope)), 1, env.data);
  else
  end try;

  for i in indices loop
    cref := setCrefIdent(cref, i, env.data.newName);
  end for;

  if not listEmpty(indices) then
    markChanged(env);
  end if;
end renameComponentCref;

function renameComponentPath
  "Renames the identifiers in a path that refer to the renamed component. The
   first identifier is an element of the given class."
  input output Absyn.Path path;
  input InstNode cls;
  input RenameEnv env;
protected
  list<String> idents;
  list<Integer> indices;
algorithm
  idents := AbsynUtil.pathToStringList(path);

  try
    indices := renamedComponentIndices(listRest(idents), lookupElementInClass(listHead(idents), cls), 1, env.data);
  else
    indices := {};
  end try;

  if not listEmpty(indices) then
    for i in indices loop
      idents := List.set(idents, i, env.data.newName);
    end for;

    path := AbsynUtil.stringListPath(idents);
    markChanged(env);
  end if;
end renameComponentPath;

function renamedComponentIndices
  "Returns the positions of the identifiers in a name that refer to the
   renamed component, given the element that the identifier at the position
   refers to and the identifiers after it."
  input list<String> idents;
  input NameElement element;
  input Integer index;
  input RenameData data;
  output list<Integer> indices;
protected
  String id;
  list<String> rest;
algorithm
  indices := if isRenamedComponentElement(element, data) then {index} else {};

  if listMember(data.oldName, idents) then
    id :: rest := idents;

    try
      indices := listAppend(renamedComponentIndices(rest, lookupInElement(id, element), index + 1, data), indices);
    else
    end try;
  end if;
end renamedComponentIndices;

function renameModifiedName
  input output Absyn.Path name;
  input RenameEnv env;
algorithm
  if not listMember(env.data.oldName, AbsynUtil.pathToStringList(name)) then
    return;
  end if;

  () := match env.target
    case ModTarget.NO_TARGET() then ();
    case ModTarget.SELF_TARGET() then ();
    else
      algorithm
        try
          name := renameComponentPath(name, resolveModTarget(env.target, env), env);
        else
        end try;
      then
        ();
  end match;
end renameModifiedName;

function renameComponentInImport
  "Renames an imported constant."
  input output Absyn.Import imp;
  input RenameEnv env;
algorithm
  () := match imp
    case Absyn.Import.NAMED_IMPORT()
      guard listMember(env.data.oldName, AbsynUtil.pathToStringList(imp.path))
      algorithm
        imp.path := renameComponentPath(imp.path, env.data.top, env);
      then
        ();

    case Absyn.Import.QUAL_IMPORT()
      guard listMember(env.data.oldName, AbsynUtil.pathToStringList(imp.path))
      algorithm
        imp.path := renameComponentPath(imp.path, env.data.top, env);
      then
        ();

    case Absyn.Import.GROUP_IMPORT()
      algorithm
        imp.groups := list(renameComponentInGroupImport(g, imp.prefix, env) for g in imp.groups);
      then
        ();

    else ();
  end match;
end renameComponentInImport;

function renameComponentInGroupImport
  input output Absyn.GroupImport group;
  input Absyn.Path prefix;
  input RenameEnv env;
protected
  Absyn.Path path;
algorithm
  () := match group
    case Absyn.GroupImport.GROUP_IMPORT_NAME() guard group.name == env.data.oldName
      algorithm
        path := renameComponentPath(AbsynUtil.suffixPath(prefix, group.name), env.data.top, env);
        group.name := AbsynUtil.pathLastIdent(path);
      then
        ();

    case Absyn.GroupImport.GROUP_IMPORT_RENAME() guard group.name == env.data.oldName
      algorithm
        path := renameComponentPath(AbsynUtil.suffixPath(prefix, group.name), env.data.top, env);
        group.name := AbsynUtil.pathLastIdent(path);
      then
        ();

    else ();
  end match;
end renameComponentInGroupImport;

function renameNamedArgs
  "Renames the named arguments of a call that refer to the renamed component,
   i.e. an input of a function or a field of a record."
  input output Absyn.FunctionArgs args;
  input Absyn.ComponentRef functionName;
  input RenameEnv env;
protected
  Absyn.Path path;
  InstNode cls;
algorithm
  () := match args
    case Absyn.FunctionArgs.FUNCTIONARGS()
      guard listMember(env.data.oldName, list(a.argName for a in args.argNames))
      algorithm
        try
          path := AbsynUtil.crefToPath(functionName);
          cls := Inst.expand(lookupExpandedPath(path, lookupScope(path, env)), FAST_CONTEXT);

          if isRenamedComponentElement(lookupElementInClass(env.data.oldName, cls), env.data) then
            args.argNames := list(renameNamedArg(a, env.data) for a in args.argNames);
            markChanged(env);
          end if;
        else
        end try;
      then
        ();

    else ();
  end match;
end renameNamedArgs;

function renameNamedArg
  input output Absyn.NamedArg arg;
  input RenameData data;
algorithm
  if arg.argName == data.oldName then
    arg.argName := data.newName;
  end if;
end renameNamedArg;

function renameTextReferences
  "Renames the references to the renamed component in a text of a graphical
   annotation, i.e. %name and %{name}."
  input output String str;
  input RenameEnv env;
protected
  String name = env.data.oldName;
  list<String> parts = {};
  Integer i = 1, start = 1, n, len;
  Boolean refers;
algorithm
  if System.stringFind(str, "%" + name) < 0 and System.stringFind(str, "%{" + name + "}") < 0 then
    return;
  end if;

  try
    refers := isRenamedComponentElement(lookupNameElement(name, getScope(env.scope)), env.data);
  else
    refers := false;
  end try;

  if not refers then
    return;
  end if;

  n := stringLength(str);

  while i < n loop
    if stringGet(str, i) <> 37 then
      i := i + 1;
    elseif stringGet(str, i + 1) == 37 then
      i := i + 2;
    else
      len := textReferenceLength(str, i + 1, name);

      if len > 0 then
        parts := (if stringGet(str, i + 1) == 123 then "{" + env.data.newName + "}" else env.data.newName) ::
                 substring(str, start, i) :: parts;
        start := i + 1 + len;
        i := start;
      else
        i := i + 1;
      end if;
    end if;
  end while;

  if not listEmpty(parts) then
    if start <= n then
      parts := substring(str, start, n) :: parts;
    end if;

    str := stringAppendList(listReverse(parts));
    markChanged(env);
  end if;
end renameTextReferences;

function textReferenceLength
  "Returns the length of name or {name} at the position in the string, or 0
   if neither is there."
  input String str;
  input Integer pos;
  input String name;
  output Integer len = 0;
protected
  Integer n = stringLength(str), name_len = stringLength(name);
algorithm
  if pos + name_len - 1 <= n then
    if substring(str, pos, pos + name_len - 1) == name then
      if pos + name_len > n then
        len := name_len;
      elseif not isIdentChar(stringGet(str, pos + name_len)) then
        len := name_len;
      end if;
    end if;
  end if;

  if len == 0 and pos + name_len + 1 <= n then
    if stringGet(str, pos) == 123 and stringGet(str, pos + name_len + 1) == 125 then
      if substring(str, pos + 1, pos + name_len) == name then
        len := name_len + 2;
      end if;
    end if;
  end if;
end textReferenceLength;

function lookupNameElement
  "Looks up a name in the scope and its enclosing scopes."
  input String name;
  input InstNode scope;
  output NameElement element;
algorithm
  try
    element := lookupElementInClass(name, scope);
  else
    false := InstNode.isEncapsulated(scope) or InstNode.isTopScope(scope);
    element := if name == InstNode.name(scope) then NameElement.CLASS_ELEMENT(scope) else
      lookupNameElement(name, InstNode.parentScope(scope));
  end try;
end lookupNameElement;

function lookupInElement
  "Looks up a name in a class, or in the type of a component."
  input String name;
  input NameElement element;
  output NameElement outElement;
protected
  InstNode cls;
algorithm
  cls := match element
    case NameElement.CLASS_ELEMENT()
      then if InstNode.isTopScope(element.node) then element.node else Inst.expand(element.node, FAST_CONTEXT);
    else componentType(element);
  end match;

  outElement := lookupElementInClass(name, cls);
end lookupInElement;

function lookupElementInClass
  "Looks up a local or inherited element of an expanded class."
  input String name;
  input InstNode cls;
  output NameElement element;
protected
  SCode.Element def;
  InstNode scope, node;
  Boolean is_comp;
algorithm
  try
    Class.lookupComponentIndex(name, InstNode.getClass(cls));
    is_comp := true;
  else
    is_comp := false;
  end try;

  if is_comp then
    (def, scope) := findComponent(name, cls);
    element := NameElement.COMPONENT_ELEMENT(def, scope);
  else
    node := lookupExpandedElement(name, cls);
    element := if InstNode.isClass(node) then NameElement.CLASS_ELEMENT(node) else
      NameElement.COMPONENT_ELEMENT(InstNode.definition(node), InstNode.parent(node));
  end if;
end lookupElementInClass;

function componentType
  input NameElement element;
  output InstNode cls;
protected
  SCode.Element def;
  InstNode scope;
  Absyn.Path ty;
algorithm
  NameElement.COMPONENT_ELEMENT(definition = def, scope = scope) := element;
  SCode.Element.COMPONENT(typeSpec = Absyn.TypeSpec.TPATH(path = ty)) := def;
  cls := Inst.expand(lookupExpandedPath(ty, scope), FAST_CONTEXT);
end componentType;

function localComponents
  input String name;
  input InstNode cls;
  output list<SCode.Element> comps;
algorithm
  comps := list(e for e guard SCodeUtil.isComponent(e) and SCodeUtil.getElementName(e) == name
                  in SCodeUtil.getClassElements(InstNode.definition(cls)));
end localComponents;

function baseClasses
  input InstNode cls;
  output list<InstNode> bases = arrayList(ClassTree.getExtends(Class.classTree(InstNode.getClass(cls))));
end baseClasses;

function isRenamedClassOrRedeclaration
  input InstNode node;
  input RenameData data;
  output Boolean res;
protected
  SCode.Element def;
algorithm
  def := InstNode.definition(node);

  if referenceEq(def, data.definition) then
    res := true;
  elseif SCodeUtil.isElementRedeclare(def) or SCodeUtil.isClassExtends(def) then
    try
      res := isRenamedClassOrRedeclaration(lookupInheritedClass(InstNode.name(node), InstNode.parent(node)), data);
    else
      res := false;
    end try;
  else
    res := false;
  end if;
end isRenamedClassOrRedeclaration;

function redeclaresRenamedClass
  "Returns true if the class in the scope inherits an element with the old
   name that is the renamed class or a redeclaration of it."
  input RenameScope scope;
  input RenameData data;
  output Boolean res;
algorithm
  try
    res := isRenamedClassOrRedeclaration(lookupInheritedClass(data.oldName, getScope(scope)), data);
  else
    res := false;
  end try;
end redeclaresRenamedClass;

function modTargetHasRenamedElement
  "Returns true if the class that the modifier modifies has an element with
   the old name that is the renamed element or a redeclaration of it."
  input RenameEnv env;
  output Boolean res = false;
protected
  InstNode cls, node;
algorithm
  () := match env.target
    case ModTarget.NO_TARGET() then ();

    case ModTarget.SELF_TARGET()
      algorithm
        res := true;
      then
        ();

    else
      algorithm
        try
          cls := resolveModTarget(env.target, env);

          if env.data.isComponent then
            res := isRenamedComponentElement(lookupElementInClass(env.data.oldName, cls), env.data);
          else
            node := lookupExpandedElement(env.data.oldName, cls);

            if InstNode.isClass(node) then
              res := isRenamedClassOrRedeclaration(node, env.data);
            end if;
          end if;
        else
        end try;
      then
        ();
  end match;
end modTargetHasRenamedElement;

function resolveModTarget
  input ModTarget target;
  input RenameEnv env;
  output InstNode cls;
protected
  RenameScope parent;
algorithm
  cls := match target
    case ModTarget.CLASS_TARGET() then lookupExpandedPath(target.path, lookupScope(target.path, env));
    case ModTarget.ELEMENT_TARGET() then componentClass(target.name, resolveModTarget(target.parent, env));
    case ModTarget.INHERITED_TARGET()
      algorithm
        SOME(parent) := env.scope.parent;
      then
        lookupInheritedClass(target.name, getScope(parent));
  end match;

  cls := Inst.expand(cls, FAST_CONTEXT);
end resolveModTarget;

function componentClass
  "Returns the class of the component with the given name in an expanded
   class, or of the component that a qualified name refers to."
  input Absyn.Path name;
  input InstNode cls;
  output InstNode node;
algorithm
  node := componentType(lookupElementInClass(AbsynUtil.pathFirstIdent(name), cls));

  if AbsynUtil.pathIsQual(name) then
    node := componentClass(AbsynUtil.pathRest(name), node);
  end if;
end componentClass;

function findComponent
  "Finds the declaration of a local or inherited component in an expanded
   class, and the class that declares it."
  input String name;
  input InstNode cls;
  output SCode.Element comp;
  output InstNode scope;
protected
  list<SCode.Element> comps;
  InstNode base;
algorithm
  comps := localComponents(name, cls);

  if listEmpty(comps) then
    (comp, scope) := match InstNode.getClass(cls)
      case Class.EXPANDED_DERIVED(baseClass = base) then findComponent(name, base);
      else findComponentInBases(name, baseClasses(cls));
    end match;
  else
    comp := listHead(comps);
    scope := cls;
  end if;
end findComponent;

function findComponentInBases
  input String name;
  input list<InstNode> bases;
  output SCode.Element comp;
  output InstNode scope;
protected
  InstNode base;
  list<InstNode> rest;
algorithm
  base :: rest := bases;

  try
    (comp, scope) := findComponent(name, base);
  else
    (comp, scope) := findComponentInBases(name, rest);
  end try;
end findComponentInBases;

function lookupScope
  input Absyn.Path path;
  input RenameEnv env;
  output InstNode scope = if AbsynUtil.pathIsFullyQualified(path) then env.data.top else getScope(env.scope);
end lookupScope;

function getScope
  input RenameScope scope;
  output InstNode node;
protected
  RenameScope parent;
algorithm
  node := Pointer.access(scope.node);

  if InstNode.isEmpty(node) then
    SOME(parent) := scope.parent;
    node := Lookup.lookupLocalSimpleName(scope.name, getScope(parent));
    node := Inst.expand(node, FAST_CONTEXT);
    Pointer.update(scope.node, node);
  end if;
end getScope;

function suffixOptPath
  input Option<Absyn.Path> path;
  input String name;
  output Absyn.Path outPath;
protected
  Absyn.Path p;
algorithm
  outPath := match path
    case SOME(p) then AbsynUtil.suffixPath(p, name);
    else Absyn.Path.IDENT(name);
  end match;
end suffixOptPath;

function lookupExpandedPath
  "Looks up a class like Lookup.lookupName, but only expands the classes it
   looks in instead of instantiating them."
  input Absyn.Path path;
  input InstNode scope;
  output InstNode node;
algorithm
  node := match path
    case Absyn.Path.IDENT() then lookupExpandedSimpleName(path.name, scope);
    case Absyn.Path.QUALIFIED()
      then lookupExpandedLocalPath(path.path, lookupExpandedSimpleName(path.name, scope));
    case Absyn.Path.FULLYQUALIFIED() then lookupExpandedLocalPath(path.path, InstNode.topScope(scope));
  end match;

  true := InstNode.isClass(node);
end lookupExpandedPath;

function lookupExpandedLocalPath
  input Absyn.Path path;
  input InstNode scope;
  output InstNode node;
algorithm
  true := InstNode.isClass(scope);
  node := if InstNode.isTopScope(scope) then scope else Inst.expand(scope, FAST_CONTEXT);
  node := lookupExpandedElement(AbsynUtil.pathFirstIdent(path), node);

  if AbsynUtil.pathIsQual(path) then
    node := lookupExpandedLocalPath(AbsynUtil.pathRest(path), node);
  end if;
end lookupExpandedLocalPath;

function lookupExpandedSimpleName
  "Looks up a name in the scope and its enclosing scopes like
   Lookup.lookupSimpleName, in classes that are expanded."
  input String name;
  input InstNode scope;
  output InstNode node;
algorithm
  try
    node := Lookup.lookupSimpleBuiltinName(name);
  else
    node := lookupExpandedNameInScope(name, scope);
  end try;
end lookupExpandedSimpleName;

function lookupExpandedNameInScope
  input String name;
  input InstNode scope;
  output InstNode node;
algorithm
  try
    node := lookupExpandedElement(name, scope);
  else
    false := InstNode.isEncapsulated(scope) or InstNode.isTopScope(scope);
    node := if name == InstNode.name(scope) then scope else
      lookupExpandedNameInScope(name, InstNode.parentScope(scope));
  end try;
end lookupExpandedNameInScope;

function lookupExpandedElement
  "Looks up a local or inherited element of an expanded class. Components and
   inherited classes cannot be resolved in an expanded class, so inherited
   classes are looked up in the base classes and a component is returned as
   an empty node."
  input String name;
  input InstNode cls;
  output InstNode node;
protected
  Class c = InstNode.getClass(cls);
algorithm
  try
    Class.lookupComponentIndex(name, c);
    node := InstNode.EMPTY_NODE();
  else
    try
      node := Class.lookupElement(name, c);
    else
      node := lookupInheritedClass(name, cls);
    end try;
  end try;
end lookupExpandedElement;

function lookupInheritedClass
  input String name;
  input InstNode cls;
  output InstNode node = lookupClassInBases(name, baseClasses(cls));
end lookupInheritedClass;

function lookupClassInBases
  input String name;
  input list<InstNode> bases;
  output InstNode node;
protected
  InstNode base;
  list<InstNode> rest;
algorithm
  base :: rest := bases;

  try
    node := lookupExpandedElement(name, base);
    true := InstNode.isClass(node);
  else
    node := lookupClassInBases(name, rest);
  end try;
end lookupClassInBases;

public
function translateResidualsDAE
  input Absyn.Path path;
  input String fileNamePrefix;
  output Boolean success = true;
protected
  Boolean disable_single_flow_eq;
  Boolean homotopy_in_residuals;
  Boolean nls_analytic_jac;
  list<String> non_std_flags;
  FlatModel flat_model;
  Flatten.FunctionTree funcs;
  Option<SimCode.SimulationSettings> simSettings;
algorithm
  disable_single_flow_eq := FlagsUtil.set(Flags.DISABLE_SINGLE_FLOW_EQ, true);
  // the initialization of the combined components runs the homotopy
  homotopy_in_residuals := FlagsUtil.set(Flags.HOMOTOPY_IN_RESIDUALS, true);
  // Components with bidirectional stream connectors keep unevaluated inStream()
  // calls (the connector inflow, resolved when the component is coupled). These
  // form small nonlinear systems whose symbolic Jacobian cannot be computed
  // (inStream is not differentiable here); the consumer builds its own Jacobian,
  // so disable analytic NLS Jacobians to avoid spurious internal errors.
  nls_analytic_jac := FlagsUtil.set(Flags.NLS_ANALYTIC_JACOBIAN, false);
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
  FlagsUtil.set(Flags.NLS_ANALYTIC_JACOBIAN, nls_analytic_jac);
  FlagsUtil.set(Flags.HOMOTOPY_IN_RESIDUALS, homotopy_in_residuals);
  FlagsUtil.set(Flags.DISABLE_SINGLE_FLOW_EQ, disable_single_flow_eq);
end translateResidualsDAE;

  annotation(__OpenModelica_Interface="backend_main");
end NFApi;

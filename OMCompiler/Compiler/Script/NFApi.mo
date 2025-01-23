/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
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

protected

import Inst = NFInst;
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
import Config;
import ConvertDAE = NFConvertDAE;
import DAEUtil;
import Dump;
import EvalConstants = NFEvalConstants;
import ErrorExt;
import ExecStat.{execStat,execStatReset};
import FBuiltin;
import Flags;
import FlagsUtil;
import FlatModel = NFFlatModel;
import Flatten = NFFlatten;
import Global;
import InteractiveUtil;
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
import Parser;
import Prefixes = NFPrefixes;
import Restriction = NFRestriction;
import Scalarize = NFScalarize;
import SimplifyExp = NFSimplifyExp;
import SimplifyModel = NFSimplifyModel;
import SymbolTable;
import Typing = NFTyping;
import UnitCheck = NFUnitCheck;
import Util;
import Variable = NFVariable;
import VerifyModel = NFVerifyModel;
import SCodeUtil;
import ElementSource;
import InstSettings = NFInst.InstSettings;
import Testsuite;
import MetaModelica.Dangerous.listReverseInPlace;

constant InstContext.Type ANNOTATION_CONTEXT = intBitOr(NFInstContext.RELAXED, NFInstContext.ANNOTATION);
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
  InstNode top, cls, inst_cls, anncls, inst_anncls;
  String name, clsName, annName, str;
  FlatModel flat_model;
  FunctionTree funcs;
  SCode.Program program;
  DAE.FunctionTree daeFuncs;
  Absyn.Path fullClassPath;
  list<Absyn.ElementArg> el = {};
  list<String> stringLst = {};
  Absyn.Exp absynExp;
  Expression exp, save;
  DAE.Exp dexp;
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
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
            (program, top) := mkTop(absynProgram, annName);
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
            (program, top) := mkTop(absynProgram, annName);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          (stripped_mod, graphics_mod) := AbsynUtil.stripGraphicsAndInteractionModification(mod);

          smod := AbsynToSCode.translateMod(SOME(Absyn.CLASSMOD(stripped_mod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), NONE(), info);
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, ANNOTATION_CONTEXT, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls, ANNOTATION_CONTEXT);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), inst_cls), NFAttributes.DEFAULT_ATTR, true, 0, inst_cls, ANNOTATION_CONTEXT);
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
          (program, top) := mkTop(absynProgram, annName);
          inst_cls := top;

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, ANNOTATION_CONTEXT, AbsynUtil.dummyInfo, checkAccessViolations = false);

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
  InstNode top, cls, inst_cls, anncls, inst_anncls;
  String name, clsName, annName, str;
  FlatModel flat_model;
  FunctionTree funcs;
  SCode.Program program;
  DAE.FunctionTree daeFuncs;
  Absyn.Path fullClassPath;
  list<list<Absyn.ElementArg>> elArgs = {}, el = {};
  list<String> stringLst = {};
  Absyn.Exp absynExp;
  Expression exp;
  DAE.Exp dexp;
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
  SourceInfo info;
  list<Absyn.ElementArg> mod, anns;
  Absyn.EqMod eqmod;
  SCode.Mod smod;
  DAE.DAElist dae;
  Type ty;
  Variability var;
  Option<Absyn.Comment> cmt;
algorithm
  // handle the annotations
  for i in inElements loop
   elArgs := matchcontinue i
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
    end matchcontinue;
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
  output Absyn.Path qualPath = pathToQualify;
protected
  InstNode top, expanded_cls, cls;
  SCode.Program program;
  String name, id1, id2;
  Boolean b, s;
  InstContext.Type context;
algorithm
  // do some quick checks
  // classPath is already fully qualified
  // check if the paths start with the same id and the second path is qualified
  _ := match (classPath, pathToQualify)
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
      cls := Lookup.lookupClassName(pathToQualify, InstNode.classParent(expanded_cls), context, AbsynUtil.dummyInfo, checkAccessViolations = false);
    else // qualify in the class
      cls := Lookup.lookupClassName(pathToQualify, expanded_cls, context, AbsynUtil.dummyInfo, checkAccessViolations = false);
    end if;

    qualPath := InstNode.fullPath(cls);

    if not Flags.isSet(Flags.NF_API_NOISE) then
      ErrorExt.rollBack("NFApi.mkFullyQual");
    end if;

    FlagsUtil.set(Flags.SCODE_INST, b);
    FlagsUtil.set(Flags.NF_SCALARIZE, s);
  else
    // do not fail, just return the Absyn path
    qualPath := pathToQualify;

    if not Flags.isSet(Flags.NF_API_NOISE) then
      ErrorExt.rollBack("NFApi.mkFullyQual");
    end if;

    FlagsUtil.set(Flags.SCODE_INST, b);
    FlagsUtil.set(Flags.NF_SCALARIZE, s);
  end try;

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.mkFullyQual(" + AbsynUtil.pathString(classPath) + ", " + AbsynUtil.pathString(pathToQualify) + ") -> " + AbsynUtil.pathString(qualPath));
  end if;
end mkFullyQual;

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
function mkTop
  input Absyn.Program absynProgram;
  input String name;
  output SCode.Program program;
  output InstNode top;
protected
  SCode.Program scode_builtin, graphicProgramSCode;
  Absyn.Program placementProgram;
  InstNode cls;
  list<tuple<Absyn.Program, tuple<SCode.Program, InstNode>>> cache;
  Boolean update = true;
algorithm
  cache := getGlobalRoot(Global.instNFNodeCacheIndex);
  if not listEmpty(cache) then
    // if absyn is the same, all fine, reuse
    if referenceEq(absynProgram, Util.tuple21(listHead(cache))) then
      (program, top) := Util.tuple22(listHead(cache));
      InstNode.clearGeneratedInners(top);
      update := false;
    else
      update := true;
      cache := {};
      setGlobalRoot(Global.instNFNodeCacheIndex, cache);
    end if;
  end if;

  if update then
    (_, scode_builtin) := FBuiltin.getInitialFunctions();
    program := AbsynToSCode.translateAbsyn2SCode(absynProgram);
    program := listAppend(scode_builtin, program);
    placementProgram := InteractiveUtil.modelicaAnnotationProgram(Config.getAnnotationVersion());
    graphicProgramSCode := AbsynToSCode.translateAbsyn2SCode(placementProgram);

    Inst.resetGlobalFlags();

    // Create a root node from the given top-level classes.
    top := NFInst.makeTopNode(program, graphicProgramSCode);

    if Flags.isSet(Flags.EXEC_STAT) then
      execStat("NFApi.mkTop("+ name +")");
    end if;

    cache := {(absynProgram, (program, top))};
    setGlobalRoot(Global.instNFNodeCacheIndex, cache);
  end if;
end mkTop;

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

  (program, top) := mkTop(absynProgram, name);

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, NFInstContext.RELAXED, AbsynUtil.dummyInfo, checkAccessViolations = false);
  cls := InstNode.setNodeType(InstNodeType.ROOT_CLASS(InstNode.EMPTY_NODE()), cls);

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
  InstNode top;
  String clsName, annName, str;
  FlatModel flat_model;
  FunctionTree funcs;
  SCode.Program scode_builtin, program, graphicProgramSCode;
  SCode.Element scls, sAnnCls;
  Absyn.Program placementProgram;
  DAE.FunctionTree daeFuncs;
  Absyn.Path fullClassPath;
  list<list<Absyn.ElementArg>> elArgs, el = {};
  list<String> stringLst = {};
  Absyn.Exp absynExp;
  Expression exp;
  DAE.Exp dexp;
  list<Absyn.ComponentItem> items;
  Option<Absyn.ConstrainClass> cc;
  SourceInfo info;
  list<Absyn.ElementArg> mod;
  SCode.Mod smod;
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

  VerifyModel.verify(flat_model);

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
  SCode.Program scode_builtin, graphicProgramSCode;
  Absyn.Program placementProgram;
  InstNode top, cls;
  list<tuple<Absyn.Program, tuple<SCode.Program, InstNode>>> cache;
  Boolean update = true;
algorithm
  name := AbsynUtil.pathString(classPath);

  (program, top) := mkTop(absynProgram, name);
  cls := Inst.lookupRootClass(classPath, top, FAST_CONTEXT);

  // Expand the class.
  expanded_cls := NFInst.expand(cls, FAST_CONTEXT);

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
    else list(InstNode.fullPath(e, true) for e in ClassTree.getExtends(Class.classTree(cls)));
  end match;
end getInheritedClasses;

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

function getModelInstance
  input Absyn.Path classPath;
  input String modifier;
  input Boolean prettyPrint;
  output Values.Value res;
protected
  InstNode top, cls_node;
  JSON json;
  InstContext.Type context;
  InstanceTree inst_tree;
  InstSettings inst_settings;
  String str;
  Modifier mod;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  context := InstContext.set(context, NFInstContext.INSTANCE_API);
  inst_settings := InstSettings.SETTINGS(mergeExtendsSections = false, resizableArrays = false);

  (_, top) := mkTop(SymbolTable.getAbsyn(), AbsynUtil.pathString(classPath));
  mod := parseModifier(modifier, top);
  cls_node := Inst.lookupRootClass(classPath, top, context);

  if SCodeUtil.isFunction(InstNode.definition(cls_node)) then
    context := InstContext.unset(context, NFInstContext.CLASS);
    context := InstContext.set(context, NFInstContext.FUNCTION);
  end if;

  cls_node := Inst.instantiateRootClass(cls_node, context, mod);
  execStat("Inst.instantiateRootClass");
  inst_tree := buildInstanceTree(cls_node);
  execStat("NFApi.buildInstanceTree");
  Inst.instExpressions(cls_node, context = context, settings = inst_settings);
  Inst.updateImplicitVariability(cls_node, Flags.isSet(Flags.EVAL_PARAM), context);
  execStat("Inst.instExpressions");

  Typing.typeClassType(cls_node, NFBinding.EMPTY_BINDING, context, cls_node);
  Typing.typeComponents(cls_node, context);
  execStat("Typing.typeComponents");
  Typing.typeBindings(cls_node, context);
  execStat("Typing.typeBinding");

  json := dumpJSONInstanceTree(inst_tree, cls_node);
  execStat("NFApi.dumpJSONInstanceTree");
  res := Values.STRING(JSON.toString(json, prettyPrint));
  execStat("JSON.toString");
  Inst.clearCaches();
end getModelInstance;

function getModelInstanceAnnotation
  input Absyn.Path classPath;
  input list<String> filter;
  input Boolean prettyPrint;
  output Values.Value res;
protected
  InstNode top, cls_node;
  InstContext.Type context;
  JSON json;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  context := InstContext.set(context, NFInstContext.INSTANCE_API);

  (_, top) := mkTop(SymbolTable.getAbsyn(), AbsynUtil.pathString(classPath));
  cls_node := Inst.lookupRootClass(classPath, top, context);
  cls_node := InstNode.resolveInner(cls_node);

  json := dumpJSONInstanceAnnotation(cls_node, filter);
  res := Values.STRING(JSON.toString(json, prettyPrint));
  Inst.clearCaches();
end getModelInstanceAnnotation;

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
      SCode.Final.NOT_FINAL(), SCode.Each.NOT_EACH(), NONE(), AbsynUtil.dummyInfo);
    outMod := Modifier.create(smod, "", NFModifier.ModifierScope.COMPONENT(""), scope);
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
      then
        InstanceTree.CLASS(node, elems, isDerived);

    case (_, ClassTree.FLAT_TREE())
      then InstanceTree.CLASS(node, if InstNode.isEnumerationType(cls_node) then {ENUM_BASE} else {}, isDerived);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown class tree", sourceInfo());
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
          while InstNode.name(Mutable.access(comps[comp_index])) <> e.name loop
            comp_index :: local_comps := local_comps;
          end while;

          if not AbsynUtil.isOnlyOuter(SCodeUtil.elementInnerOuter(e)) then
            tree := buildInstanceTreeComponent(comps[comp_index]);
            elements := tree :: elements;
          end if;
        then
          elements;

      else elements;
    end match;
  end for;

  elements := listReverseInPlace(elements);
end buildInstanceTreeElements;

function buildInstanceTreeComponent
  input Mutable<InstNode> compNode;
  output InstanceTree tree;
protected
  InstNode node, inner_node, cls_node;
  InstanceTree cls;
  Binding binding;
  Option<Binding> opt_binding;
algorithm
  node := Mutable.access(compNode);
  inner_node := InstNode.resolveInner(node);
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
  output JSON json = JSON.makeNull();
protected
  InstNode node;
  list<InstanceTree> elems;
  Sections sections;
  Option<SCode.Comment> cmt;
  JSON j;
  SCode.Element def;
algorithm
  InstanceTree.CLASS(node = node, elements = elems) := tree;
  node := InstNode.resolveInner(node);
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

  json := JSON.addPair("source", dumpJSONSourceInfo(InstNode.info(node)), json);
end dumpJSONInstanceTree;

function dumpJSONInstanceAnnotation
  input InstNode node;
  input list<String> filter;
  output JSON json = JSON.makeNull();
protected
  Option<SCode.Comment> cmt;
  SCode.Annotation ann;
  array<InstNode> exts;
  JSON j;
  InstNode scope = node;
  InstContext.Type context;
  Boolean annotation_is_literal = true;
  SCode.Element def;
algorithm
  Inst.expand(node, ANNOTATION_CONTEXT);
  def := InstNode.definition(node);
  json := JSON.addPair("name", dumpJSONNodePath(node), json);

  json := JSON.addPair("restriction",
    JSON.makeString(Restriction.toString(InstNode.restriction(node))), json);

  json := JSON.addPairNotNull("prefixes", dumpJSONClassPrefixes(def, InstNode.parent(node)), json);

  exts := ClassTree.getExtends(Class.classTree(InstNode.getClass(node)));

  if not arrayEmpty(exts) then
    j := JSON.emptyArray();

    for ext in exts loop
      j := JSON.addElement(dumpJSONInstanceAnnotationExtends(ext, filter), j);
    end for;

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
      scope := InstNode.setNodeType(InstNodeType.ROOT_CLASS(InstNode.EMPTY_NODE()), scope);
      scope := Inst.instantiate(scope, context = context, instPartial = true);
      Inst.insertGeneratedInners(scope, InstNode.topScope(scope), context);
      Inst.instExpressions(scope, context = context, settings = NFInst.DEFAULT_SETTINGS);
    else
    end try;
    ErrorExt.rollBack(getInstanceName());
  end if;

  json := dumpJSONCommentOpt(cmt, scope, json, failOnError = true);
end dumpJSONInstanceAnnotation;

function dumpJSONInstanceAnnotationExtends
  input InstNode ext;
  input list<String> filter;
  output JSON json = JSON.makeNull();
algorithm
  json := JSON.addPair("$kind", JSON.makeString("extends"), json);
  json := JSON.addPair("baseClass", dumpJSONInstanceAnnotation(ext, filter), json);
end dumpJSONInstanceAnnotationExtends;

function dumpJSONNodePath
  input InstNode node;
  output JSON json = dumpJSONPath(InstNode.fullPath(node, ignoreBaseClass = true));
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
  SCode.Mod mod;
algorithm
  InstanceTree.CLASS(node = node) := ext;
  cls_def := InstNode.definition(node);
  ext_def := InstNode.extendsDefinition(node);

  json := JSON.addPair("$kind", JSON.makeString("extends"), json);
  json := dumpJSONSCodeMod(getExtendsModifier(ext_def, node), node, json);
  json := dumpJSONCommentOpt(SCodeUtil.getElementComment(ext_def), node, json);

  cls := InstNode.getClass(node);
  if Class.isOnlyBuiltin(cls) and not Class.isEnumeration(cls) then
    json := JSON.addPair("baseClass", JSON.makeString(InstNode.name(node)), json);
  else
    json := JSON.addPair("baseClass", dumpJSONInstanceTree(ext, node, root = false, isDeleted = isDeleted), json);
  end if;
end dumpJSONExtends;

function dumpJSONBuiltinBaseClass
  input String name;
  output JSON json = JSON.makeNull();
algorithm
  json := JSON.addPair("$kind", JSON.makeString("extends"), json);
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
  SCode.ClassDef cdef;
  InstNode node, derivedNode;
  Absyn.Path path;
  Option<list<Absyn.Subscript>> odims;
  SCode.Comment cmt;
algorithm
  node := InstNode.getRedeclaredNode(cls);
  elem := InstNode.definition(node);
  json := dumpJSONSCodeClass(elem, scope, true, json);
  json := JSON.addPair("source", dumpJSONSourceInfo(InstNode.info(node)), json);
end dumpJSONReplaceableClass;

function dumpJSONComponent
  input InstNode component;
  input Option<Binding> originalBinding;
  input InstanceTree cls;
  output JSON json = JSON.makeNull();
protected
  InstNode node, scope;
  Component comp;
  SCode.Element elem;
  Boolean is_constant;
  SCode.Comment cmt;
  SCode.Annotation ann;
  JSON j;
algorithm
  node := InstNode.resolveInner(component);

  // Skip dumping inner elements that were added by the compiler itself.
  if InstNode.isGeneratedInner(node) then
    return;
  end if;

  comp := InstNode.component(node);
  elem := InstNode.definition(node);
  scope := InstNode.parent(node);

  () := match (comp, elem)
    case (Component.COMPONENT(), SCode.Element.COMPONENT())
      guard Component.isDeleted(comp)
      algorithm
        json := JSON.addPair("$kind", JSON.makeString("component"), json);
        json := JSON.addPair("name", JSON.makeString(InstNode.name(node)), json);
        json := JSON.addPair("type", dumpJSONComponentType(cls, node, comp.ty, isDeleted = true), json);
        json := dumpJSONSCodeMod(elem.modifications, scope, json);
        json := JSON.addPair("condition", JSON.makeBoolean(false), json);
        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes, scope), json);
        json := dumpJSONCommentOpt(SOME(elem.comment), scope, json);
      then
        ();

    case (Component.INVALID_COMPONENT(), SCode.Element.COMPONENT())
      algorithm
        json := JSON.addPair("$kind", JSON.makeString("component"), json);
        json := JSON.addPair("name", JSON.makeString(InstNode.name(node)), json);
        json := JSON.addPair("type", dumpJSONComponentType(cls, node, Component.getType(comp)), json);
        json := dumpJSONSCodeMod(elem.modifications, scope, json);
        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes, scope), json);
        json := dumpJSONCommentOpt(SOME(elem.comment), scope, json);
        json := JSON.addPair("$error", JSON.makeString(comp.errors), json);
      then
        ();

    case (Component.COMPONENT(), SCode.Element.COMPONENT())
      algorithm
        json := JSON.addPair("$kind", JSON.makeString("component"), json);
        json := JSON.addPair("name", JSON.makeString(InstNode.name(node)), json);
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
        json := dumpJSONCommentOpt(comp.comment, scope, json);
      then
        ();

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown component " +
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
  JSON json_elems, json_ext;
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

  json := JSON.addPair("source", dumpJSONSourceInfo(InstNode.info(node)), json);
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
  json := JSON.addPair("$kind", JSON.makeString("component"), json);
  json := JSON.addPair("name", JSON.makeString(InstNode.name(node)), json);
  json := dumpJSONCommentOpt(Component.comment(InstNode.component(node)), scope, json);
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
      exp := Ceval.evalExp(exp, Ceval.EvalTarget.new(AbsynUtil.dummyInfo, NFInstContext.INSTANCE_API));
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
  JSON ty_json, absyn_json;
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
    json := JSON.addPair("direction", JSON.makeString("input"), json);
  elseif AbsynUtil.isOutput(attrs.direction) then
    json := JSON.addPair("direction", JSON.makeString("output"), json);
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
  SCode.Prefixes prefs;
  SCode.ClassDef cdef;
algorithm
  json := match element
    case SCode.CLASS(classDef = cdef, prefixes = prefs)
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
protected
  SCode.Comment cmt;
algorithm
  if isSome(cmtOpt) then
    SOME(cmt) := cmtOpt;

    if isSome(cmt.comment) and dumpComment then
      json := JSON.addPair("comment", JSON.makeString(Util.getOption(cmt.comment)), json);
    end if;

    if dumpAnnotation then
      json := dumpJSONAnnotationOpt(cmt.annotation_, scope, {}, failOnError, json);
    end if;
  end if;
end dumpJSONCommentOpt;

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
  Expression binding_exp;
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
        json := JSON.addPair(name, JSON.emptyObject(), json);
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
    // For non-literal arrays, dump each element separately to avoid
    // invalidating the whole array expression if any element contains invalid
    // expressions.
    case Absyn.Exp.ARRAY()
      guard not AbsynUtil.isLiteralExp(absynExp)
      algorithm
        json := JSON.emptyArray(listLength(absynExp.arrayExp));
        for e in absynExp.arrayExp loop
          j := dumpJSONAnnotationExp2(e, scope, info, failOnError);
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
    exp := Inst.instExp(absynExp, scope, ANNOTATION_CONTEXT, info);
    exp := Typing.typeExp(exp, ANNOTATION_CONTEXT, info);
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

function dumpJSONSourceInfo
  input SourceInfo info;
  output JSON json = JSON.makeNull();
algorithm
  json := JSON.addPair("filename", JSON.makeString(Testsuite.friendly(info.fileName)), json);

  json := JSON.addPair("lineStart", JSON.makeInteger(info.lineNumberStart), json);
  json := JSON.addPair("columnStart", JSON.makeInteger(info.columnNumberStart), json);
  json := JSON.addPair("lineEnd", JSON.makeInteger(info.lineNumberEnd), json);
  json := JSON.addPair("columnEnd", JSON.makeInteger(info.columnNumberEnd), json);

  if info.isReadOnly then
    json := JSON.addPair("readonly", JSON.makeBoolean(true), json);
  end if;
end dumpJSONSourceInfo;

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
        json := JSON.addPair("$kind", JSON.makeString("call"), json);
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

    else JSON.makeString(Dump.printExpStr(AbsynUtil.stripCommentExpressions(exp)));
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
              json_imp := JSON.addPair("path", dumpJSONPath(InstNode.fullPath(imp.node)), json_imp);

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
          binding_json := JSON.makeString(Dump.printExpStr(AbsynUtil.stripCommentExpressions(Util.getOption(mod.binding))));

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
        json := JSON.addPair("$kind", JSON.makeString("component"), json);
        json := JSON.addPair("name", JSON.makeString(element.name), json);
        json := JSON.addPair("type", dumpJSONPath(AbsynUtil.typeSpecPath(element.typeSpec)), json);
        json := JSON.addPairNotNull("dims", dumpJSONDims(element.attributes.arrayDims, {}), json);
        json := dumpJSONSCodeMod(element.modifications, scope, json);
        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(element.attributes, element.prefixes, scope), json);

        if isSome(element.condition) then
          json := JSON.addPair("condition", dumpJSONAbsynExpression(Util.getOption(element.condition)), json);
        end if;

        json := dumpJSONCommentOpt(SOME(element.comment), scope, json);
      then
        json;

    case SCode.Element.CLASS()
      then dumpJSONSCodeClass(element, scope, false, json);

    else json;
  end match;
end dumpJSONSCodeElement;

function dumpJSONSCodeClass
  input SCode.Element element;
  input InstNode scope;
  input Boolean isRedeclare;
  input output JSON json = JSON.makeNull();
protected
  Option<list<Absyn.Subscript>> odims;
algorithm
  () := match element
    case SCode.CLASS()
      algorithm
        json := JSON.addPair("$kind", JSON.makeString("class"), json);
        json := JSON.addPair("name", JSON.makeString(element.name), json);
        json := JSON.addPair("restriction",
          JSON.makeString(SCodeDump.restrictionStringPP(element.restriction)), json);
        json := JSON.addPairNotNull("prefixes", dumpJSONClassPrefixes(element, scope), json);
        json := dumpJSONSCodeClassDef(element.classDef, scope, isRedeclare, json);
        json := dumpJSONCommentOpt(SOME(element.cmt), scope, json, dumpAnnotation = not isRedeclare);

        if isRedeclare then
          json := dumpJSONCommentAnnotation(SOME(element.cmt), scope, json,
            {"Dialog", "choices", "choicesAllMatching"});
        end if;
      then
        ();
  end match;
end dumpJSONSCodeClass;

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
  SCode.Mod choices_mod;
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

function modifierToJSON
  input String modifier;
  input Boolean prettyPrint;
  output Values.Value jsonString;
protected
  Absyn.Modification amod;
  SCode.Mod smod;
  JSON json;
algorithm
  Absyn.ElementArg.MODIFICATION(modification = SOME(amod)) :=
    Parser.stringMod("dummy" + modifier);
  smod := AbsynToSCode.translateMod(SOME(amod),
    SCode.Final.NOT_FINAL(), SCode.Each.NOT_EACH(), NONE(), AbsynUtil.dummyInfo);
  json := dumpJSONSCodeMod_impl(smod, InstNode.EMPTY_NODE());
  jsonString := Values.STRING(JSON.toString(json, prettyPrint));
end modifierToJSON;

uniontype MoveEnv
  record MOVE_ENV
    InstNode scope;
    Absyn.Path destinationPath;
  end MOVE_ENV;
end MoveEnv;

function updateMovedClassPaths
  "Updates all the paths inside of a class that is being moved such that the
   paths are still valid in the new location."
  input output Absyn.Class cls "The class definition";
  input Absyn.Path clsPath "The fully qualified path of the class";
  input Absyn.Within destination "The destination package (or top scope)";
protected
  InstContext.Type context;
  InstNode top, cls_node;
  MoveEnv env;
  Absyn.Path dest_path;
algorithm
  // Make a top node and look up the class in it.
  (_, top) := mkTop(SymbolTable.getAbsyn(), AbsynUtil.pathString(clsPath));
  cls_node := Inst.lookupRootClass(clsPath, top, FAST_CONTEXT);
  Inst.expand(cls_node, FAST_CONTEXT);

  // Get the destination path including the class name.
  dest_path := match destination
    case Absyn.Within.WITHIN() then AbsynUtil.suffixPath(destination.path, InstNode.name(cls_node));
    else Absyn.Path.IDENT(InstNode.name(cls_node));
  end match;

  env := MOVE_ENV(cls_node, dest_path);
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
    cls_env := MoveEnv.MOVE_ENV(cls_node, AbsynUtil.suffixPath(env.destinationPath, cls.name));
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
  input output Absyn.Path path;
  input MoveEnv env;
protected
  Absyn.Path qualified_path;
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

  // If the path we found is fully qualified it means we need to update the original path.
  if AbsynUtil.pathIsFullyQualified(qualified_path) then
    qualified_path := AbsynUtil.makeNotFullyQualified(qualified_path);

    if AbsynUtil.pathIsQual(qualified_path) then
      // If the path is qualified it needs to be joined with the original path,
      // but we remove any part of the path that's the same as the destination.
      qualified_path := AbsynUtil.pathStripSamePrefix(qualified_path, env.destinationPath);

      if AbsynUtil.pathIsQual(qualified_path) then
        path := AbsynUtil.joinPaths(AbsynUtil.pathPrefix(qualified_path), path);
      end if;
    elseif AbsynUtil.pathFirstIdent(qualified_path) == AbsynUtil.pathFirstIdent(env.destinationPath) then
      // Special case, the path refers to the destination package, e.g. moving path A.B.C into A.
      path := AbsynUtil.pathRest(path);
    end if;
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

    if AbsynUtil.pathIsQual(qualified_path) then
      // If the path is qualified it needs to be joined with the original cref,
      // but we remove any part of the path that's the same as the destination.
      qualified_path := AbsynUtil.pathStripSamePrefix(qualified_path, env.destinationPath);

      if AbsynUtil.pathIsQual(qualified_path) then
        cref := AbsynUtil.joinCrefs(AbsynUtil.pathToCref(AbsynUtil.pathPrefix(qualified_path)), cref);
      end if;
    elseif AbsynUtil.pathFirstIdent(qualified_path) == AbsynUtil.pathFirstIdent(env.destinationPath) then
      // Special case, the cref refers to the destination package, e.g. moving path A.B.C into A.
      cref := AbsynUtil.crefStripFirst(cref);
    end if;
  end if;
end updateMovedCref;

  annotation(__OpenModelica_Interface="backend");
end NFApi;

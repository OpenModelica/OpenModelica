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

protected

import Inst = NFInst;
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
import NFType.Type;
import Subscript = NFSubscript;
import Connector = NFConnector;
import Connection = NFConnection;
import Algorithm = NFAlgorithm;
import ExpOrigin = NFTyping.ExpOrigin;

import Absyn.Path;
import AbsynToSCode;
import Array;
import ComplexType = NFComplexType;
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
import InstUtil = NFInstUtil;
import Interactive;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import NFCall.Call;
import NFCeval;
import NFClassTree.ClassTree;
import NFFlatten.FunctionTree;
import NFFunction.Function;
import NFInst;
import NFInstNode.CachedData;
import NFInstNode.NodeTree;
import NFPrefixes.*;
import NFSections.Sections;
import OperatorOverloading = NFOperatorOverloading;
import Package = NFPackage;
import Prefixes = NFPrefixes;
import Record = NFRecord;
import Restriction = NFRestriction;
import Scalarize = NFScalarize;
import SimplifyExp = NFSimplifyExp;
import SimplifyModel = NFSimplifyModel;
import System;
import Typing = NFTyping;
import UnitCheck = NFUnitCheck;
import Util;
import Variable = NFVariable;
import VerifyModel = NFVerifyModel;


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
  Expression exp;
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
    str := matchcontinue e
      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD({}, eqmod as Absyn.EQMOD(absynExp))),
          info = info)
        algorithm
          // no need for the class if there are no crefs
          if AbsynUtil.onlyLiteralsInEqMod(eqmod) then
            (program, top) := mkTop(absynProgram);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          exp := NFInst.instExp(absynExp, inst_cls, info);
          (exp, ty, var) := Typing.typeExp(exp, ExpOrigin.CLASS, info);
          // exp := NFCeval.evalExp(exp);
          exp := SimplifyExp.simplify(Expression.stripBindingInfo(exp));
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
            (program, top) := mkTop(absynProgram);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          (stripped_mod, graphics_mod) := AbsynUtil.stripGraphicsAndInteractionModification(mod);

          smod := AbsynToSCode.translateMod(SOME(Absyn.CLASSMOD(stripped_mod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), {inst_cls, inst_anncls}, inst_cls), NFComponent.DEFAULT_ATTR, true, 0, inst_cls);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

          dae := frontEndBack(inst_anncls, annName);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));

          if (stringEq(annName, "Icon") or stringEq(annName, "Diagram")) and not listEmpty(graphics_mod) then
            try
              {Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp = absynExp))))} := graphics_mod;
              exp := NFInst.instExp(absynExp, inst_cls, info);
              (exp, ty, var) := Typing.typeExp(exp, ExpOrigin.CLASS, info);
              // exp := NFCeval.evalExp(exp);
              exp := SimplifyExp.simplify(Expression.stripBindingInfo(exp));
              str := str + ", " + Expression.toString(exp);
            else
              // just don't fail!
            end try;
          end if;
        then
          str;

      case Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = NONE(), info = info)
        algorithm
          (program, top) := mkTop(absynProgram);
          inst_cls := top;

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls, InstNode.EMPTY_NODE(), true);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

          dae := frontEndBack(inst_anncls, annName);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          str;

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
  list<Absyn.ElementArg> mod;
  Absyn.EqMod eqmod;
  SCode.Mod smod;
  DAE.DAElist dae;
  Type ty;
  Variability var;
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

      else elArgs;
    end matchcontinue;
  end for;

  for l in elArgs loop

  stringLst := {};

  for e in listReverse(l) loop
    str := matchcontinue e
      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD({}, eqmod as Absyn.EQMOD(absynExp))),
          info = info)
        algorithm
          // no need for the class if there are no crefs
          if AbsynUtil.onlyLiteralsInEqMod(eqmod) then
            (program, top) := mkTop(absynProgram);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          exp := NFInst.instExp(absynExp, inst_cls, info);
          (exp, ty, var) := Typing.typeExp(exp, ExpOrigin.CLASS, info);
          // exp := NFCeval.evalExp(exp);
          exp := SimplifyExp.simplify(Expression.stripBindingInfo(exp));
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
            (program, top) := mkTop(absynProgram);
            inst_cls := top;
          else
            // run the front-end front
            (program, name, top, inst_cls) := frontEndFront(absynProgram, classPath);
          end if;

          smod := AbsynToSCode.translateMod(SOME(Absyn.CLASSMOD(mod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), {inst_cls, inst_anncls}, inst_cls), NFComponent.DEFAULT_ATTR, true, 0, inst_cls);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

          dae := frontEndBack(inst_anncls, annName);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          stringAppendList({annName, "(", str, ")"});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD(_, Absyn.NOMOD())))
        then stringAppendList({annName, "(error)"});

      case Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = NONE(), info = info)
        algorithm
          (program, top) := mkTop(absynProgram);
          inst_cls := top;

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

          dae := frontEndBack(inst_anncls, annName);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          stringAppendList({annName, "(", str, ")"});

    end matchcontinue;

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
  output Absyn.Path qualPath;
protected
  InstNode top, expanded_cls, cls;
  SCode.Program program;
  String name;
  Boolean b, s;
algorithm
  b := FlagsUtil.set(Flags.SCODE_INST, true);
  s := FlagsUtil.set(Flags.NF_SCALARIZE, true); // #5689
  try
    if not Flags.isSet(Flags.NF_API_NOISE) then
      ErrorExt.setCheckpoint("NFApi.mkFullyQual");
    end if;
    // run the front-end front
    (program, name, top, expanded_cls) := frontEndLookup(absynProgram, classPath);
    // if is derived qualify in the parent
    if InstNode.isDerivedClass(expanded_cls) then
      cls := Lookup.lookupClassName(pathToQualify, InstNode.classParent(expanded_cls), AbsynUtil.dummyInfo, checkAccessViolations = false);
    else // qualify in the class
      cls := Lookup.lookupClassName(pathToQualify, expanded_cls, AbsynUtil.dummyInfo, checkAccessViolations = false);
    end if;

    qualPath := InstNode.scopePath(cls, true);

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
end mkFullyQual;

protected
function frontEndFront
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode top;
  output InstNode inst_cls;
protected
  list<tuple<tuple<Absyn.Program, Absyn.Path>, tuple<SCode.Program, String, InstNode, InstNode>>> cache;
algorithm
  cache := getGlobalRoot(Global.instNFInstCacheIndex);
  if not listEmpty(cache) then
    for i in cache loop
      if AbsynUtil.pathEqual(classPath, Util.tuple22(Util.tuple21(i))) then
        if referenceEq(absynProgram, Util.tuple21(Util.tuple21(i))) then
          (program, name, top, inst_cls) := Util.tuple22(i);
          return;
        end if;
        // program changed, wipe the cache!
        cache := {};
        break;
      end if;
    end for;
  end if;
  (program, name, top, inst_cls) := frontEndFront_dispatch(absynProgram, classPath);
  if listLength(cache) > 100 then
    // trim it down, keep 10
    cache := List.firstN(cache, 10);
  end if;

  cache := ((absynProgram,classPath),(program, name, top, inst_cls))::cache;
  setGlobalRoot(Global.instNFInstCacheIndex, cache);
end frontEndFront;

protected
function mkTop
  input Absyn.Program absynProgram;
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
      update := false;
    else
      update := true;
    end if;
  end if;

  if update then
    (_, scode_builtin) := FBuiltin.getInitialFunctions();
    program := AbsynToSCode.translateAbsyn2SCode(absynProgram);
    program := listAppend(scode_builtin, program);
    placementProgram := Interactive.modelicaAnnotationProgram(Config.getAnnotationVersion());
    graphicProgramSCode := AbsynToSCode.translateAbsyn2SCode(placementProgram);
    program := listAppend(graphicProgramSCode, program);

    // gather here all the flags to disable expansion
    // and scalarization if -d=-nfScalarize is on
    if not Flags.isSet(Flags.NF_SCALARIZE) then
      // make sure we don't expand anything
      FlagsUtil.set(Flags.NF_EXPAND_OPERATIONS, false);
      FlagsUtil.set(Flags.NF_EXPAND_FUNC_ARGS, false);
    end if;

    System.setUsesCardinality(false);

    // Create a root node from the given top-level classes.
    top := NFInst.makeTopNode(program);

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
  output InstNode top;
  output InstNode inst_cls;
protected
  SCode.Program scode_builtin, graphicProgramSCode;
  Absyn.Program placementProgram;
  InstNode cls;
  list<tuple<Absyn.Program, tuple<SCode.Program, InstNode>>> cache;
  Boolean update = true;
algorithm
  (program, top) := mkTop(absynProgram);

  name := AbsynUtil.pathString(classPath);
  execStat("NFApi.mkTop("+ name +")");

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, AbsynUtil.dummyInfo, checkAccessViolations = false);
  cls := InstNode.setNodeType(InstNodeType.ROOT_CLASS(InstNode.EMPTY_NODE()), cls);

  // Initialize the storage for automatically generated inner elements.
  top := InstNode.setInnerOuterCache(top, CachedData.TOP_SCOPE(NodeTree.new(), cls));

  // Instantiate the class.
  inst_cls := NFInst.instantiate(cls);
  NFInst.insertGeneratedInners(inst_cls, top);

  // Instantiate expressions (i.e. anything that can contains crefs, like
  // bindings, dimensions, etc). This is done as a separate step after
  // instantiation to make sure that lookup is able to find the correct nodes.
  NFInst.instExpressions(inst_cls);

  // Mark structural parameters.
  NFInst.updateImplicitVariability(inst_cls, Flags.isSet(Flags.EVAL_PARAM));
  execStat("NFApi.frontEndFront_dispatch");
end frontEndFront_dispatch;

protected
function frontEndBack
  input InstNode inst_cls;
  input String name;
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
  Typing.typeClass(inst_cls);

  // Flatten and simplify the model.
  flat_model := Flatten.flatten(inst_cls, name);
  flat_model := EvalConstants.evaluate(flat_model);
  flat_model := UnitCheck.checkUnits(flat_model);
  flat_model := SimplifyModel.simplify(flat_model);
  funcs := Flatten.collectFunctions(flat_model);

  // Collect package constants that couldn't be substituted with their values
  // (e.g. because they where used with non-constant subscripts), and add them
  // to the model.
  flat_model := Package.collectConstants(flat_model, funcs);

  // Scalarize array components in the flat model.
  if Flags.isSet(Flags.NF_SCALARIZE) then
    flat_model := Scalarize.scalarize(flat_model);
  else
    // Remove empty arrays from variables
    flat_model.variables := List.filterOnFalse(flat_model.variables, Variable.isEmptyArray);
  end if;

  VerifyModel.verify(flat_model);

  // Convert the flat model to a DAE.
  (dae, daeFuncs) := ConvertDAE.convert(flat_model, funcs);
end frontEndBack;

protected
function frontEndLookup
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode top;
  output InstNode expanded_cls;
protected
  list<tuple<tuple<Absyn.Program, Absyn.Path>, tuple<SCode.Program, String, InstNode, InstNode>>> cache;
algorithm
  cache := getGlobalRoot(Global.instNFLookupCacheIndex);
  if not listEmpty(cache) then
    for i in cache loop
      if AbsynUtil.pathEqual(classPath, Util.tuple22(Util.tuple21(i))) then
        if referenceEq(absynProgram, Util.tuple21(Util.tuple21(i))) then
          (program, name, top, expanded_cls) := Util.tuple22(i);
          return;
        end if;
        // program changed, wipe the cache!
        cache := {};
        break;
      end if;
    end for;
  end if;
  (program, name, top, expanded_cls) := frontEndLookup_dispatch(absynProgram, classPath);
  if listLength(cache) > 100 then
    // trim it down, keep 10
    cache := List.firstN(cache, 10);
  end if;

  cache := ((absynProgram,classPath),(program, name, top, expanded_cls))::cache;
  setGlobalRoot(Global.instNFLookupCacheIndex, cache);
end frontEndLookup;

protected
function frontEndLookup_dispatch
  input Absyn.Program absynProgram;
  input Absyn.Path classPath;
  output SCode.Program program;
  output String name;
  output InstNode top;
  output InstNode expanded_cls;
protected
  SCode.Program scode_builtin, graphicProgramSCode;
  Absyn.Program placementProgram;
  InstNode cls;
  list<tuple<Absyn.Program, tuple<SCode.Program, InstNode>>> cache;
  Boolean update = true;
algorithm
  (program, top) := mkTop(absynProgram);

  name := AbsynUtil.pathString(classPath);

  // Look up the class to instantiate and mark it as the root class.
  cls := Lookup.lookupClassName(classPath, top, AbsynUtil.dummyInfo, checkAccessViolations = false);
  cls := InstNode.setNodeType(InstNodeType.ROOT_CLASS(InstNode.EMPTY_NODE()), cls);

  // Initialize the storage for automatically generated inner elements.
  top := InstNode.setInnerOuterCache(top, CachedData.TOP_SCOPE(NodeTree.new(), cls));

  // Expand the class.
  expanded_cls := NFInst.expand(cls);
  NFInst.insertGeneratedInners(expanded_cls, top);
  execStat("NFApi.frontEndLookup_dispatch("+ name +")");

end frontEndLookup_dispatch;

  annotation(__OpenModelica_Interface="backend");
end NFApi;

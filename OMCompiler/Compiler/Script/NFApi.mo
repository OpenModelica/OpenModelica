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

import Attributes = NFAttributes;
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
import InstContext = NFInstContext;

import Absyn.Path;
import AbsynToSCode;
import Array;
import ComplexType = NFComplexType;
import Config;
import NFPrefixes.ConnectorType;
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
import Interactive;
import InteractiveUtil;
import JSON;
import List;
import Lookup = NFLookup;
import MetaModelica.Dangerous;
import NFCall.Call;
import Ceval = NFCeval;
import NFClassTree.ClassTree;
import NFFlatten.FunctionTree;
import NFFunction.Function;
import NFInst;
import NFInstNode.CachedData;
import NFInstNode.NodeTree;
import NFPrefixes.{Variability, Purity, Visibility};
import NFSections.Sections;
import OperatorOverloading = NFOperatorOverloading;
import Package = NFPackage;
import Prefixes = NFPrefixes;
import Record = NFRecord;
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
  InstContext.Type context;
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

          exp := NFInst.instExp(absynExp, inst_cls, NFInstContext.RELAXED, info);
          (exp, ty, var) := Typing.typeExp(exp, NFInstContext.CLASS, info);
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

          smod := AbsynToSCode.translateMod(SOME(Absyn.CLASSMOD(stripped_mod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, NFInstContext.RELAXED, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), inst_cls), NFAttributes.DEFAULT_ATTR, true, 0, inst_cls, NFInstContext.NO_CONTEXT);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = NFInstContext.RELAXED);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

          dae := frontEndBack(inst_anncls, annName, false);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));

          if (listMember(annName, {"Icon", "Diagram", "choices"})) and not listEmpty(graphics_mod) then
            try
              {Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp = absynExp))))} := graphics_mod;
              context := InstContext.set(NFInstContext.RELAXED, NFInstContext.GRAPHICAL_EXP);
              exp := NFInst.instExp(absynExp, inst_cls, context, info);
              (exp, ty, var) := Typing.typeExp(exp, NFInstContext.CLASS, info);
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

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, NFInstContext.RELAXED, AbsynUtil.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls, context = NFInstContext.RELAXED);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = NFInstContext.RELAXED);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

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

/* try to use evaluateAnnotation_dispatch instead

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

          exp := NFInst.instExp(absynExp, inst_cls, NFInstContext.RELAXED, info);
          (exp, ty, var) := Typing.typeExp(exp, NFInstContext.CLASS, info);
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

          smod := AbsynToSCode.translateMod(SOME(Absyn.CLASSMOD(mod, Absyn.NOMOD())), SCode.NOT_FINAL(), SCode.NOT_EACH(), info);
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, NFInstContext.RELAXED, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), inst_cls), NFComponent.DEFAULT_ATTR, true, 0, inst_cls, NFInstContext.NO_CONTEXT);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = NFInstContext.RELAXED);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

          dae := frontEndBack(inst_anncls, annName, false);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          stringAppendList({annName, "(", str, ")"});

      case Absyn.MODIFICATION(
          path = Absyn.IDENT(annName),
          modification = SOME(Absyn.CLASSMOD(_, _)))
        then stringAppendList({annName, "(error)"});

      case Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = NONE(), info = info)
        algorithm
          (program, top) := mkTop(absynProgram, annName);
          inst_cls := top;

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, NFInstContext.RELAXED, AbsynUtil.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls, context = NFInstContext.RELAXED);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = NFInstContext.RELAXED);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

          dae := frontEndBack(inst_anncls, annName, false);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));
        then
          stringAppendList({annName, "(", str, ")"});

      case Absyn.MODIFICATION(path = Absyn.IDENT(annName), modification = NONE(), info = info)
        then stringAppendList({annName, "(error)"});

    end matchcontinue;

*/

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

    // if is derived qualify in the parent
    if InstNode.isDerivedClass(expanded_cls) then
      cls := Lookup.lookupClassName(pathToQualify, InstNode.classParent(expanded_cls), NFInstContext.RELAXED, AbsynUtil.dummyInfo, checkAccessViolations = false);
    else // qualify in the class
      cls := Lookup.lookupClassName(pathToQualify, expanded_cls, NFInstContext.RELAXED, AbsynUtil.dummyInfo, checkAccessViolations = false);
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
    program := listAppend(graphicProgramSCode, program);

    Inst.resetGlobalFlags();

    // Create a root node from the given top-level classes.
    top := NFInst.makeTopNode(program);

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
  NFInst.instExpressions(inst_cls, context = NFInstContext.RELAXED);

  // Mark structural parameters.
  NFInst.updateImplicitVariability(inst_cls, Flags.isSet(Flags.EVAL_PARAM));

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.frontEndFront_dispatch(" + name + ")");
  end if;
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
  flat_model := Flatten.flatten(inst_cls, name);
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
  cls := Inst.lookupRootClass(classPath, top, NFInstContext.RELAXED);

  // Expand the class.
  expanded_cls := NFInst.expand(cls);

  if Flags.isSet(Flags.EXEC_STAT) then
    execStat("NFApi.frontEndLookup_dispatch("+ name +")");
  end if;

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
  (_, _, cls_node) := frontEndLookup(program, classPath);

  if not InstNode.isClass(cls_node) then
    extendsPaths := {};
    return;
  end if;

  cls := InstNode.getClass(cls_node);

  extendsPaths := match cls
    case Class.EXPANDED_DERIVED() then {InstNode.scopePath(cls.baseClass, true, true)};
    else list(InstNode.scopePath(e, true, true) for e in ClassTree.getExtends(Class.classTree(cls)));
  end match;
end getInheritedClasses;

uniontype InstanceTree
  record COMPONENT
    InstNode node;
  end COMPONENT;

  record CLASS
    InstNode node;
    list<InstanceTree> exts;
    list<InstanceTree> components;
  end CLASS;
end InstanceTree;

function getModelInstance
  input Absyn.Path classPath;
  input Boolean prettyPrint;
  output Values.Value res;
protected
  InstNode top, cls_node;
  JSON json;
  InstContext.Type context;
  InstanceTree inst_tree;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  (_, top) := mkTop(SymbolTable.getAbsyn(), AbsynUtil.pathString(classPath));
  cls_node := Inst.lookupRootClass(classPath, top, context);
  cls_node := Inst.instantiateRootClass(cls_node, context);
  inst_tree := buildInstanceTree(cls_node);
  Inst.instExpressions(cls_node, context = context);

  Typing.typeComponents(cls_node, context);
  Typing.typeBindings(cls_node, context);

  json := dumpJSONInstanceTree(inst_tree);
  res := Values.STRING(JSON.toString(json, prettyPrint));
end getModelInstance;

function buildInstanceTree
  input InstNode node;
  output InstanceTree tree;
protected
  ClassTree cls_tree;
  list<InstanceTree> exts, components;
  array<InstNode> ext_nodes;
algorithm
  cls_tree := Class.classTree(InstNode.getClass(node));

  tree := match cls_tree
    case ClassTree.INSTANTIATED_TREE(exts = ext_nodes)
      algorithm
        exts := list(buildInstanceTree(e) for e in ext_nodes);
        components := list(buildInstanceTreeComponent(arrayGet(cls_tree.components, i))
                           for i in cls_tree.localComponents);
      then
        InstanceTree.CLASS(node, exts, components);

    else
      algorithm
        Error.assertion(false, getInstanceName() + " got unknown class tree", sourceInfo());
      then
        fail();
  end match;
end buildInstanceTree;

function buildInstanceTreeComponent
  input Mutable<InstNode> compNode;
  output InstanceTree tree;
algorithm
  tree := InstanceTree.COMPONENT(Mutable.access(compNode));
end buildInstanceTreeComponent;

function dumpJSONInstanceTree
  input InstanceTree tree;
  input Boolean root = true;
  output JSON json = JSON.emptyObject();
protected
  InstNode node;
  list<InstanceTree> comps, exts;
  Sections sections;
algorithm
  InstanceTree.CLASS(node = node, exts = exts, components = comps) := tree;

  json := JSON.addPair("name", dumpJSONNodePath(node), json);

  if not listEmpty(exts) then
    json := JSON.addPair("extends", dumpJSONExtends(exts), json);
  end if;

  if not listEmpty(comps) then
    json := JSON.addPair("components", dumpJSONComponents(comps), json);
  end if;

  if root then
    sections := Class.getSections(InstNode.getClass(node));
    json := JSON.addPair("connections", dumpJSONConnections(sections), json);
    json := JSON.addPair("replaceable", dumpJSONReplaceableElements(node), json);
  end if;
end dumpJSONInstanceTree;

function dumpJSONNodePath
  input InstNode node;
  output JSON json = dumpJSONPath(InstNode.scopePath(node, ignoreBaseClass = true));
end dumpJSONNodePath;

function dumpJSONPath
  input Absyn.Path path;
  output JSON json = JSON.makeString(AbsynUtil.pathString(path));
end dumpJSONPath;

function dumpJSONExtends
  input list<InstanceTree> exts;
  output JSON json = JSON.emptyArray();
algorithm
  for ext in exts loop
    json := JSON.addElement(dumpJSONInstanceTree(ext, root = false), json);
  end for;
end dumpJSONExtends;

function dumpJSONComponents
  input list<InstanceTree> components;
  output JSON json = JSON.emptyObject();
protected
  InstNode node;
algorithm
  for comp in components loop
    InstanceTree.COMPONENT(node = node) := comp;
    json := JSON.addPair(InstNode.name(node), dumpJSONComponent(comp), json);
  end for;
end dumpJSONComponents;

function dumpJSONComponent
  input InstanceTree component;
  output JSON json = JSON.emptyObject();
protected
  InstNode node;
  Component comp;
  SCode.Element elem;
  Boolean is_constant;
  SCode.Comment cmt;
  SCode.Annotation ann;
algorithm
  InstanceTree.COMPONENT(node = node) := component;
  node := InstNode.resolveOuter(node);
  comp := InstNode.component(node);
  elem := InstNode.definition(node);

  () := match (comp, elem)
    case (Component.TYPED_COMPONENT(), SCode.Element.COMPONENT())
      algorithm
        json := JSON.addPair("type", dumpJSONTypeName(comp.ty), json);

        if Type.isArray(comp.ty) then
          json := JSON.addPair("dims",
            dumpJSONDims(elem.attributes.arrayDims, Type.arrayDims(comp.ty)), json);
        end if;

        json := JSON.addPair("modifier", JSON.makeString(SCodeDump.printModStr(elem.modifications)), json);

        //if not Type.isComplex(comp.ty) then
        //  json := dumpJSONBuiltinClassComponents(comp.classInst, elem.modifications, json);
        //end if;

        is_constant := comp.attributes.variability <= Variability.STRUCTURAL_PARAMETER;

        if Binding.isBound(comp.binding) then
          json := JSON.addPair("value", dumpJSONBinding(comp.binding, evaluate = is_constant), json);
        end if;

        if Binding.isBound(comp.condition) then
          json := JSON.addPair("condition", dumpJSONBinding(comp.condition), json);
        end if;

        json := JSON.addPair("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes), json);
        json := dumpJSONCommentOpt(comp.comment, json);
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

function dumpJSONTypeName
  input Type ty;
  output JSON json;
algorithm
  json := JSON.makeString(Type.toString(Type.arrayElementType(ty)));
end dumpJSONTypeName;

function dumpJSONBinding
  input Binding binding;
  input Boolean evaluate = true;
  output JSON json = JSON.emptyObject();
protected
  Expression exp;
algorithm
  exp := Binding.getExp(binding);
  exp := Expression.map(exp, Expression.expandSplitIndices);
  json := JSON.addPair("binding", JSON.makeString(Expression.toString(exp)), json);

  if evaluate and not Expression.isLiteral(exp) then
    ErrorExt.setCheckpoint(getInstanceName());
    try
      exp := Ceval.evalExp(exp);
      json := JSON.addPair("value", JSON.makeString(Expression.toString(exp)), json);
    else
    end try;
    ErrorExt.rollBack(getInstanceName());
  end if;
end dumpJSONBinding;

function dumpJSONBuiltinClassComponents
  input InstNode clsNode;
  input output JSON json;
protected
  Class cls;
  ClassTree cls_tree;
  Component comp;
  JSON attr_json = JSON.makeNull();
algorithm
  cls := InstNode.getClass(clsNode);
  cls_tree := Class.classTree(cls);

  for c in ClassTree.getComponents(cls_tree) loop
    comp := InstNode.component(c);

    () := match comp
      case Component.TYPE_ATTRIBUTE()
        guard Modifier.hasBinding(comp.modifier)
        algorithm
          attr_json := JSON.addPair(Modifier.name(comp.modifier),
            dumpJSONBinding(Modifier.binding(comp.modifier)), attr_json);
        then
          ();

      else ();
    end match;
  end for;

  if not JSON.isNull(attr_json) then
    json := JSON.addPair("attributes", attr_json, json);
  end if;
end dumpJSONBuiltinClassComponents;

function dumpJSONDims
  input list<Absyn.Subscript> absynDims;
  input list<Dimension> typedDims;
  output JSON json = JSON.emptyObject();
protected
  JSON ty_json, absyn_json;
algorithm
  absyn_json := JSON.emptyArray();
  for d in absynDims loop
    absyn_json := JSON.addElement(JSON.makeString(Dump.printSubscriptStr(d)), absyn_json);
  end for;

  json := JSON.addPair("absyn", absyn_json, json);

  ty_json := JSON.emptyArray();
  for d in typedDims loop
    ty_json := JSON.addElement(JSON.makeString(Dimension.toString(d)), ty_json);
  end for;

  json := JSON.addPair("typed", ty_json, json);
end dumpJSONDims;

function dumpJSONAttributes
  input SCode.Attributes attrs;
  input SCode.Prefixes prefs;
  output JSON json = JSON.emptyObject();
algorithm
  json := JSON.addPair("public", JSON.makeBoolean(SCodeUtil.visibilityBool(prefs.visibility)), json);
  json := JSON.addPair("final", JSON.makeBoolean(SCodeUtil.finalBool(prefs.finalPrefix)), json);
  json := JSON.addPair("inner", JSON.makeBoolean(AbsynUtil.isInner(prefs.innerOuter)), json);
  json := JSON.addPair("outer", JSON.makeBoolean(AbsynUtil.isOuter(prefs.innerOuter)), json);
  json := JSON.addPair("replaceable", JSON.makeBoolean(SCodeUtil.replaceableBool(prefs.replaceablePrefix)), json);
  json := JSON.addPair("redeclare", JSON.makeBoolean(SCodeUtil.redeclareBool(prefs.redeclarePrefix)), json);
  json := JSON.addPair("connector", JSON.makeString(SCodeDump.connectorTypeStr(attrs.connectorType)), json);
  json := JSON.addPair("variability", JSON.makeString(SCodeDump.unparseVariability(attrs.variability)), json);
  json := JSON.addPair("direction", JSON.makeString(Dump.unparseDirectionSymbolStr(attrs.direction)), json);
end dumpJSONAttributes;

function dumpJSONCommentOpt
  input Option<SCode.Comment> cmtOpt;
  input output JSON json;
  input Boolean dumpComment = true;
  input Boolean dumpAnnotation = true;
protected
  SCode.Comment cmt;
algorithm
  if isSome(cmtOpt) then
    SOME(cmt) := cmtOpt;

    if isSome(cmt.comment) and dumpComment then
      json := JSON.addPair("comment", JSON.makeString(Util.getOption(cmt.comment)), json);
    end if;

    if dumpAnnotation then
      json := dumpJSONAnnotationOpt(cmt.annotation_, json);
    end if;
  end if;
end dumpJSONCommentOpt;

function dumpJSONAnnotationOpt
  input Option<SCode.Annotation> annOpt;
  input output JSON json;
protected
  SCode.Annotation ann;
algorithm
  if isSome(annOpt) then
    SOME(ann) := annOpt;
    json := JSON.addPair("annotation",
      JSON.makeString(SCodeDump.printModStr(ann.modification)), json);
  end if;
end dumpJSONAnnotationOpt;

function dumpJSONConnections
  input Sections sections;
  output JSON json = JSON.emptyArray();
algorithm
  () := match sections
    case Sections.SECTIONS()
      algorithm
        for eq in sections.equations loop
          if Equation.isConnect(eq) then
            json := JSON.addElement(dumpJSONConnection(eq), json);
          end if;
        end for;
      then
        ();

    else ();
  end match;
end dumpJSONConnections;

function dumpJSONConnection
  input Equation connEq;
  output JSON json = JSON.emptyObject();
protected
  Expression lhs, rhs;
  DAE.ElementSource src;
algorithm
  Equation.CONNECT(lhs = lhs, rhs = rhs, source = src) := connEq;
  json := JSON.addPair("lhs", JSON.makeString(Expression.toString(lhs)), json);
  json := JSON.addPair("rhs", JSON.makeString(Expression.toString(rhs)), json);
  json := dumpJSONCommentOpt(ElementSource.getOptComment(src), json, dumpComment = false);
end dumpJSONConnection;

function dumpJSONReplaceableElements
  input InstNode clsNode;
  output JSON json = JSON.emptyArray();
protected
  ClassTree cls_tree;
  JSON j;
algorithm
  cls_tree := Class.classTree(InstNode.getClass(clsNode));

  for c in ClassTree.getComponents(cls_tree) loop
    if InstNode.isReplaceable(c) then
      j := JSON.emptyObject();
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

  annotation(__OpenModelica_Interface="backend");
end NFApi;

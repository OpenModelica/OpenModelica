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
import NFPrefixes.{Variability};
import NFSections.Sections;
import Package = NFPackage;
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
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.ANNOTATION);

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

          exp := NFInst.instExp(absynExp, inst_cls, context, info);
          (exp, ty, var) := Typing.typeExp(exp, context, info);
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
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, context, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), inst_cls), NFAttributes.DEFAULT_ATTR, true, 0, inst_cls, context);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = context);

          // Mark structural parameters.
          NFInst.updateImplicitVariability(inst_anncls, Flags.isSet(Flags.EVAL_PARAM));

          dae := frontEndBack(inst_anncls, annName, false);
          str := DAEUtil.getVariableBindingsStr(DAEUtil.daeElements(dae));

          if (listMember(annName, {"Icon", "Diagram", "choices"})) and not listEmpty(graphics_mod) then
            try
              {Absyn.MODIFICATION(modification = SOME(Absyn.CLASSMOD(eqMod = Absyn.EQMOD(exp = absynExp))))} := graphics_mod;
              exp := NFInst.instExp(absynExp, inst_cls, context, info);
              (exp, ty, var) := Typing.typeExp(exp, context, info);
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

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, context, AbsynUtil.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls, context = context);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = context);

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
  InstContext.Type context;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.ANNOTATION);

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

          exp := NFInst.instExp(absynExp, inst_cls, context, info);
          (exp, ty, var) := Typing.typeExp(exp, context, info);
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
          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, context, AbsynUtil.dummyInfo, checkAccessViolations = false);
          inst_anncls := NFInst.expand(anncls);
          inst_anncls := NFInst.instClass(inst_anncls, Modifier.create(smod, annName, ModifierScope.CLASS(annName), inst_cls), NFComponent.DEFAULT_ATTR, true, 0, inst_cls, context);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = context);

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

          anncls := Lookup.lookupClassName(Absyn.IDENT(annName), inst_cls, context, AbsynUtil.dummyInfo, checkAccessViolations = false);

          inst_anncls := NFInst.instantiate(anncls, context = context);

          // Instantiate expressions (i.e. anything that can contains crefs, like
          // bindings, dimensions, etc). This is done as a separate step after
          // instantiation to make sure that lookup is able to find the correct nodes.
          NFInst.instExpressions(inst_anncls, context = context);

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
    case Class.EXPANDED_DERIVED() then {InstNode.fullPath(cls.baseClass, true)};
    else list(InstNode.fullPath(e, true) for e in ClassTree.getExtends(Class.classTree(cls)));
  end match;
end getInheritedClasses;

function instAnnotation

end instAnnotation;

uniontype InstanceTree
  record COMPONENT
    InstNode node;
    InstanceTree cls;
  end COMPONENT;

  record CLASS
    InstNode node;
    list<InstanceTree> exts;
    list<InstanceTree> components;
  end CLASS;

  record EMPTY
  end EMPTY;
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
  InstSettings inst_settings;
algorithm
  context := InstContext.set(NFInstContext.RELAXED, NFInstContext.CLASS);
  context := InstContext.set(context, NFInstContext.INSTANCE_API);
  inst_settings := InstSettings.SETTINGS(mergeExtendsSections = false);

  (_, top) := mkTop(SymbolTable.getAbsyn(), AbsynUtil.pathString(classPath));
  cls_node := Inst.lookupRootClass(classPath, top, context);
  cls_node := Inst.instantiateRootClass(cls_node, context);
  inst_tree := buildInstanceTree(cls_node);
  Inst.instExpressions(cls_node, context = context, settings = inst_settings);
  Inst.updateImplicitVariability(cls_node, Flags.isSet(Flags.EVAL_PARAM));

  Typing.typeClassType(cls_node, NFBinding.EMPTY_BINDING, context, cls_node);
  Typing.typeComponents(cls_node, context);
  Typing.typeBindings(cls_node, context);

  json := dumpJSONInstanceTree(inst_tree);
  res := Values.STRING(JSON.toString(json, prettyPrint));
end getModelInstance;

function getModelInstanceIcon
  input Absyn.Path classPath;
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

  json := dumpJSONInstanceIcon(cls_node);
  res := Values.STRING(JSON.toString(json, prettyPrint));
end getModelInstanceIcon;

function buildInstanceTree
  input InstNode node;
  input Boolean isDerived = false;
  output InstanceTree tree;
protected
  Class cls;
  ClassTree cls_tree;
  list<InstanceTree> exts, components;
  array<InstNode> ext_nodes;
algorithm
  cls := InstNode.getClass(InstNode.resolveInner(node));

  if not isDerived and Class.isOnlyBuiltin(cls) then
    tree := InstanceTree.EMPTY();
    return;
  end if;

  cls_tree := Class.classTree(cls);

  tree := match (cls, cls_tree)
    case (Class.EXPANDED_DERIVED(), _)
      algorithm
        exts := {buildInstanceTree(cls.baseClass, isDerived = true)};
      then
        InstanceTree.CLASS(node, exts, {});

    case (_, ClassTree.INSTANTIATED_TREE(exts = ext_nodes))
      algorithm
        exts := list(buildInstanceTree(e) for e in ext_nodes);
        components := list(buildInstanceTreeComponent(arrayGet(cls_tree.components, i))
                           for i in cls_tree.localComponents);
      then
        InstanceTree.CLASS(node, exts, components);

    case (_, ClassTree.FLAT_TREE())
      then InstanceTree.CLASS(node, {}, {});

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
protected
  InstNode node;
  InstanceTree cls;
algorithm
  node := Mutable.access(compNode);
  cls := buildInstanceTree(InstNode.classScope(node));
  tree := InstanceTree.COMPONENT(node, cls);
end buildInstanceTreeComponent;

function dumpJSONInstanceTree
  input InstanceTree tree;
  input Boolean root = true;
  output JSON json = JSON.emptyObject();
protected
  InstNode node;
  list<InstanceTree> comps, exts;
  Sections sections;
  Option<SCode.Comment> cmt;
  JSON j;
  SCode.Element def;
algorithm
  InstanceTree.CLASS(node = node, exts = exts, components = comps) := tree;
  node := InstNode.resolveInner(node);
  def := InstNode.definition(node);
  cmt := SCodeUtil.getElementComment(def);

  json := JSON.addPair("name", dumpJSONNodePath(node), json);

  json := JSON.addPairNotNull("dims", dumpJSONClassDims(node, def), json);
  json := JSON.addPair("restriction",
    JSON.makeString(Restriction.toString(InstNode.restriction(node))), json);
  json := dumpJSONSCodeMod(SCodeUtil.elementMod(def), json);

  json := JSON.addPairNotNull("prefixes", dumpJSONClassPrefixes(def, node), json);

  if not listEmpty(exts) then
    json := JSON.addPair("extends", dumpJSONExtendsList(exts), json);
  end if;

  json := dumpJSONCommentOpt(cmt, node, json);

  if not listEmpty(comps) then
    json := JSON.addPair("components", dumpJSONComponents(comps), json);
  end if;

  sections := Class.getSections(InstNode.getClass(node));
  json := dumpJSONEquations(sections, node, json);

  if root then
    j := dumpJSONReplaceableElements(node);
    json := JSON.addPairNotNull("replaceable", j, json);
  end if;

  json := JSON.addPair("source", dumpJSONSourceInfo(InstNode.info(node)), json);
end dumpJSONInstanceTree;

function dumpJSONInstanceIcon
  input InstNode node;
  output JSON json = JSON.emptyObject();
protected
  Option<SCode.Comment> cmt;
  SCode.Annotation ann;
  array<InstNode> exts;
  JSON j;
algorithm
  Inst.expand(node);
  json := JSON.addPair("name", dumpJSONNodePath(node), json);

  exts := ClassTree.getExtends(Class.classTree(InstNode.getClass(node)));

  if not arrayEmpty(exts) then
    j := JSON.emptyArray();

    for ext in exts loop
      j := JSON.addElement(dumpJSONInstanceIconExtends(ext), j);
    end for;

    json := JSON.addPair("extends", j, json);
  end if;

  cmt := SCodeUtil.getElementComment(InstNode.definition(node));

  cmt := match cmt
    case SOME(SCode.Comment.COMMENT(annotation_ = SOME(ann as SCode.Annotation.ANNOTATION())))
      algorithm
        ann.modification := SCodeUtil.filterSubMods(ann.modification,
          function SCodeUtil.filterGivenSubModNames(namesToKeep = {"Icon", "IconMap"}));
      then
        if SCodeUtil.isEmptyMod(ann.modification) then NONE() else SOME(SCode.Comment.COMMENT(SOME(ann), NONE()));

    else NONE();
  end match;

  json := dumpJSONCommentOpt(cmt, node, json, failOnError = true);
end dumpJSONInstanceIcon;

function dumpJSONInstanceIconExtends
  input InstNode ext;
  output JSON json = JSON.emptyObject();
algorithm
  json := JSON.addPair("baseClass", dumpJSONInstanceIcon(ext), json);
end dumpJSONInstanceIconExtends;

function dumpJSONNodePath
  input InstNode node;
  output JSON json = dumpJSONPath(InstNode.scopePath(node, ignoreBaseClass = true));
end dumpJSONNodePath;

function dumpJSONPath
  input Absyn.Path path;
  output JSON json = JSON.makeString(AbsynUtil.pathString(path));
end dumpJSONPath;

function dumpJSONExtendsList
  input list<InstanceTree> exts;
  output JSON json = JSON.emptyArray();
algorithm
  for ext in exts loop
    json := JSON.addElement(dumpJSONExtends(ext), json);
  end for;
end dumpJSONExtendsList;

function dumpJSONExtends
  input InstanceTree ext;
  output JSON json = JSON.emptyObject();
protected
  InstNode node;
  SCode.Element cls_def, ext_def;
algorithm
  InstanceTree.CLASS(node = node) := ext;
  cls_def := InstNode.definition(node);
  ext_def := InstNode.extendsDefinition(node);

  json := dumpJSONSCodeMod(SCodeUtil.elementMod(ext_def), json);
  json := dumpJSONCommentOpt(SCodeUtil.getElementComment(ext_def), node, json);

  if Class.isOnlyBuiltin(InstNode.getClass(node)) then
    json := JSON.addPair("baseClass", JSON.makeString(InstNode.name(node)), json);
  else
    json := JSON.addPair("baseClass", dumpJSONInstanceTree(ext, root = false), json);
  end if;
end dumpJSONExtends;

function dumpJSONComponents
  input list<InstanceTree> components;
  output JSON json = JSON.emptyArray();
protected
  InstNode node;
  JSON j;
algorithm
  for comp in components loop
    InstanceTree.COMPONENT(node = node) := comp;
    j := dumpJSONComponent(comp);

    if not JSON.isNull(j) then
      json := JSON.addElement(j, json);
    end if;
  end for;
end dumpJSONComponents;

function dumpJSONComponent
  input InstanceTree component;
  output JSON json = JSON.makeNull();
protected
  InstNode node;
  Component comp;
  SCode.Element elem;
  Boolean is_constant;
  SCode.Comment cmt;
  SCode.Annotation ann;
  InstanceTree cls;
  JSON j;
algorithm
  InstanceTree.COMPONENT(node = node, cls = cls) := component;
  node := InstNode.resolveInner(node);

  // Skip dumping inner elements that were added by the compiler itself.
  if InstNode.isGeneratedInner(node) then
    return;
  end if;

  comp := InstNode.component(node);
  elem := InstNode.definition(node);

  () := match (comp, elem)
    case (_, SCode.Element.COMPONENT())
      guard Component.isDeleted(comp)
      algorithm
        json := JSON.addPair("name", JSON.makeString(InstNode.name(node)), json);
        json := dumpJSONSCodeMod(elem.modifications, json);
        json := JSON.addPair("condition", JSON.makeBoolean(false), json);
        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes, node), json);
        json := dumpJSONCommentOpt(SOME(elem.comment), InstNode.parent(node), json);
      then
        ();

    case (Component.TYPED_COMPONENT(), SCode.Element.COMPONENT())
      algorithm
        json := JSON.addPair("name", JSON.makeString(InstNode.name(node)), json);
        json := JSON.addPair("type", dumpJSONComponentType(cls, node, comp.ty), json);

        if Type.isArray(comp.ty) then
          json := JSON.addPair("dims",
            dumpJSONDims(elem.attributes.arrayDims, Type.arrayDims(comp.ty)), json);
        end if;

        json := dumpJSONSCodeMod(elem.modifications, json);

        //if not Type.isComplex(comp.ty) then
        //  json := dumpJSONBuiltinClassComponents(comp.classInst, elem.modifications, json);
        //end if;

        is_constant := comp.attributes.variability <= Variability.PARAMETER;

        if Binding.isBound(comp.binding) then
          json := JSON.addPair("value", dumpJSONBinding(comp.binding, evaluate = is_constant), json);
        end if;

        if Binding.isBound(comp.condition) then
          json := JSON.addPair("condition", dumpJSONBinding(comp.condition), json);
        end if;

        json := JSON.addPairNotNull("prefixes", dumpJSONAttributes(elem.attributes, elem.prefixes, node), json);
        json := dumpJSONCommentOpt(comp.comment, InstNode.parent(node), json);
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
  output JSON json;
algorithm
  json := match (cls, ty)
    case (_, Type.ENUMERATION()) then dumpJSONEnumType(node);
    case (InstanceTree.CLASS(), _) then dumpJSONInstanceTree(cls);
    else dumpJSONTypeName(ty);
  end match;
end dumpJSONComponentType;

function dumpJSONEnumType
  input InstNode enumNode;
  output JSON json;
protected
  InstNode node = InstNode.resolveInner(InstNode.classScope(enumNode));
  SCode.Element def;
  array<InstNode> comps;
algorithm
  def := InstNode.definition(node);

  json := JSON.emptyObject();
  json := JSON.addPair("name", dumpJSONNodePath(node), json);
  json := JSON.addPairNotNull("dims", dumpJSONClassDims(node, def), json);
  json := JSON.addPair("restriction", JSON.makeString("enumeration"), json);
  json := dumpJSONCommentOpt(SCodeUtil.getElementComment(def), node, json);

  comps := ClassTree.getComponents(Class.classTree(InstNode.getClass(node)));
  json := JSON.addPair("components", dumpJSONEnumTypeLiterals(comps, InstNode.parent(node)), json);

  json := JSON.addPair("source", dumpJSONSourceInfo(InstNode.info(node)), json);
end dumpJSONEnumType;

function dumpJSONEnumTypeLiterals
  input array<InstNode> literals;
  input InstNode scope;
  output JSON json = JSON.emptyArray();
algorithm
  for i in 6:arrayLength(literals) loop
    json := JSON.addElement(dumpJSONEnumTypeLiteral(literals[i], scope), json);
  end for;
end dumpJSONEnumTypeLiterals;

function dumpJSONEnumTypeLiteral
  input InstNode node;
  input InstNode scope;
  output JSON json = JSON.emptyObject();
algorithm
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
  input Boolean evaluate = true;
  output JSON json = JSON.emptyObject();
protected
  Expression exp;
algorithm
  exp := Binding.getExp(binding);
  exp := Expression.map(exp, Expression.expandSplitIndices);
  json := JSON.addPair("binding", Expression.toJSON(exp), json);

  if evaluate and not Expression.isLiteral(exp) then
    ErrorExt.setCheckpoint(getInstanceName());
    try
      exp := Ceval.evalExp(exp);
      json := JSON.addPair("value", Expression.toJSON(exp), json);
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

  json := JSON.addPairNotNull("attributes", attr_json, json);
end dumpJSONBuiltinClassComponents;

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
        json := JSON.emptyObject();
        json := JSON.addPair("constrainedby", dumpJSONPath(cc.constrainingClass), json);
        json := dumpJSONSCodeMod(cc.modifier, json);
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
      json := dumpJSONAnnotationOpt(cmt.annotation_, scope, failOnError, json);
    end if;
  end if;
end dumpJSONCommentOpt;

function dumpJSONAnnotationOpt
  input Option<SCode.Annotation> annOpt;
  input InstNode scope;
  input Boolean failOnError;
  input output JSON json;
protected
  SCode.Annotation ann;
algorithm
  if isSome(annOpt) then
    SOME(ann) := annOpt;
    json := JSON.addPair("annotation", dumpJSONAnnotationMod(ann.modification, scope, failOnError), json);
  end if;
end dumpJSONAnnotationOpt;

function dumpJSONAnnotationMod
  input SCode.Mod mod;
  input InstNode scope;
  input Boolean failOnError;
  output JSON json;
algorithm
  json := match mod
    case SCode.Mod.MOD()
      then dumpJSONAnnotationSubMods(mod.subModLst, scope, failOnError);

    else JSON.makeNull();
  end match;
end dumpJSONAnnotationMod;

function dumpJSONAnnotationSubMods
  input list<SCode.SubMod> subMods;
  input InstNode scope;
  input Boolean failOnError;
  output JSON json = JSON.makeNull();
algorithm
  for m in subMods loop
    json := dumpJSONAnnotationSubMod(m, scope, failOnError, json);
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
        ErrorExt.setCheckpoint(getInstanceName());

        try
          binding_exp := Inst.instExp(absyn_binding, scope, NFInstContext.ANNOTATION, mod.info);
          binding_exp := Typing.typeExp(binding_exp, NFInstContext.ANNOTATION, mod.info);
          binding_exp := SimplifyExp.simplify(binding_exp);
          json := JSON.addPair(name, Expression.toJSON(binding_exp), json);
        else
          if failOnError then
            fail();
          end if;

          j := JSON.emptyObject();
          j := JSON.addPair("$error", JSON.makeString(ErrorExt.printCheckpointMessagesStr()), j);
          j := JSON.addPair("value", dumpJSONAbsynExpression(absyn_binding), j);
          json := JSON.addPair(name, j, json);
        end try;

        ErrorExt.delCheckpoint(getInstanceName());
      then
        ();

    case (_, SCode.Mod.MOD())
      algorithm
        json := JSON.addPair(name, dumpJSONAnnotationSubMods(mod.subModLst, scope, failOnError), json);
      then
        ();

    else ();
  end match;
end dumpJSONAnnotationSubMod;

function dumpJSONSourceInfo
  input SourceInfo info;
  output JSON json = JSON.emptyObject();
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
        json := JSON.emptyObject();
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

    else JSON.makeString(Dump.printExpStr(exp));
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

function dumpJSONEquations
  input Sections sections;
  input InstNode scope;
  input output JSON json;
protected
  list<Equation> connections, transitions, initial_states;
  JSON j;
  InstContext.Type context;
algorithm
  (connections, transitions, initial_states) := sortEquations(sections);
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
  input Sections sections;
  output list<Equation> connections = {};
  output list<Equation> transitions = {};
  output list<Equation> initialStates = {};
  output list<Equation> others = {};
algorithm
  () := match sections
    case Sections.SECTIONS()
      algorithm
        for eq in listReverse(sections.equations) loop
          () := match eq
            case Equation.CONNECT()
              algorithm
                connections := eq :: connections;
              then
                ();

            case Equation.NORETCALL()
              algorithm
                if Expression.isCallNamed(eq.exp, "transition") then
                  transitions := eq :: transitions;
                elseif Expression.isCallNamed(eq.exp, "initialState") then
                  initialStates := eq :: initialStates;
                else
                  others := eq :: others;
                end if;
              then
                ();

            else
              algorithm
                others := eq :: others;
              then
                ();
          end match;
        end for;
      then
        ();

    else ();
  end match;
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
  output JSON json = JSON.emptyObject();
protected
  Expression lhs, rhs;
  DAE.ElementSource src;
algorithm
  Equation.CONNECT(lhs = lhs, rhs = rhs, source = src) := connEq;
  json := JSON.addPair("lhs", Expression.toJSON(lhs), json);
  json := JSON.addPair("rhs", Expression.toJSON(rhs), json);
  json := dumpJSONCommentOpt(ElementSource.getOptComment(src), scope, json, dumpComment = false);
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
  output JSON json = JSON.emptyObject();
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
        json := dumpJSONCommentOpt(ElementSource.getOptComment(src), scope, json, dumpComment = false);
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

function dumpJSONSCodeMod
  input SCode.Mod mod;
  input output JSON json;
protected
  JSON j;
algorithm
  j := dumpJSONSCodeMod_impl(mod);
  json := JSON.addPairNotNull("modifiers", j, json);
end dumpJSONSCodeMod;

function dumpJSONSCodeMod_impl
  input SCode.Mod mod;
  output JSON json = JSON.makeNull();
protected
  JSON binding_json;
algorithm
  () := match mod
    case SCode.Mod.MOD()
      algorithm
        for m in mod.subModLst loop
          json := JSON.addPair(m.ident, dumpJSONSCodeMod_impl(m.mod), json);
        end for;

        if SCodeUtil.finalBool(mod.finalPrefix) then
          json := JSON.addPair("final", JSON.makeBoolean(true), json);
        end if;

        if SCodeUtil.eachBool(mod.eachPrefix) then
          json := JSON.addPair("each", JSON.makeBoolean(true), json);
        end if;

        if isSome(mod.binding) then
          binding_json := JSON.makeString(Dump.printExpStr(Util.getOption(mod.binding)));

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

        binding_json := JSON.makeString(SCodeDump.unparseElementStr(mod.element));
        json := JSON.addPair("$value", binding_json, json);
      then
        ();

    else ();
  end match;
end dumpJSONSCodeMod_impl;

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

      j := JSON.addElement(dumpJSONSCodeMod_impl(m.mod), j);
    end for;

    json := JSON.addPair("choice", j, json);
  end if;

  for m in others loop
    json := dumpJSONAnnotationSubMod(m, scope, failOnError, json);
  end for;
end dumpJSONChoicesAnnotation;

  annotation(__OpenModelica_Interface="backend");
end NFApi;

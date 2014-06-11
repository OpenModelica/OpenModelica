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

encapsulated package BackendDAECreate
" file:        BackendDAECreate.mo
  package:     BackendDAECreate
  description: This file contains all functions for transforming the DAE structure to the BackendDAE.

  RCS: $Id$

"

public import Absyn;
public import BackendDAE;
public import DAE;
public import Env;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashTable;
protected import CheckModel;
protected import ComponentReference;
protected import Config;
protected import ClassInf;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import Global;
protected import GlobalScript;
protected import HashTableExpToExp;
protected import HashTableExpToIndex;
protected import HashTable;
protected import HashTableCrToExpSourceTpl;
protected import Inline;
protected import List;
protected import SCode;
protected import System;
protected import Types;
protected import Util;

protected type Functiontuple = tuple<Option<DAE.FunctionTree>,list<DAE.InlineType>>;

public function lower "This function translates a DAE, which is the result from instantiating a
  class, into a more precise form, called BackendDAE.BackendDAE defined in this module.
  The BackendDAE.BackendDAE representation splits the DAE into equations and variables
  and further divides variables into known and unknown variables and the
  equations into simple and nonsimple equations.
  The variables are inserted into a hash table. This gives a lookup cost of
  O(1) for finding a variable. The equations are put in an expandable
  array. Where adding a new equation can be done in O(1) time if space
  is available.
  inputs:  lst: DAE.DAElist, inCache: Env.Cache, inEnv: Env.Env
  outputs: BackendDAE.BackendDAE"
  input DAE.DAElist lst;
  input Env.Cache inCache;
  input Env.Env inEnv;
  input BackendDAE.ExtraInfo inExtraInfo;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.Variables vars, knvars, vars_1, extVars, aliasVars;
  list<BackendDAE.Equation> eqns, reqns, ieqns, algeqns, algeqns1, ialgeqns, multidimeqns, imultidimeqns, eqns_1, ceeqns, iceeqns;
  list<DAE.Constraint> constrs;
  list<DAE.ClassAttributes> clsAttrs;
  list<BackendDAE.WhenClause> whenclauses, whenclauses_1;
  BackendDAE.EquationArray eqnarr, reqnarr, ieqnarr;
  BackendDAE.ExternalObjectClasses extObjCls;
  BackendDAE.SymbolicJacobians symjacs;
  BackendDAE.EventInfo einfo;
  list<DAE.Element> elems, aliaseqns;
  list<BackendDAE.ZeroCrossing> zero_crossings;
  DAE.FunctionTree functionTree;
  list<BackendDAE.TimeEvent> timeEvents;
  String neqStr,nvarStr;
algorithm
  System.realtimeTick(GlobalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
  // reset dumped file sequence number
  System.tmpTickResetIndex(0, Global.backendDAE_fileSequence);
  Debug.execStat("Enter Backend", GlobalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
  functionTree := Env.getFunctionTree(inCache);
  (DAE.DAE(elems), functionTree, timeEvents) := processBuiltinExpressions(lst, functionTree);
  vars := BackendVariable.emptyVars();
  knvars := BackendVariable.emptyVars();
  extVars := BackendVariable.emptyVars();
  (vars, knvars, extVars, eqns, reqns, ieqns, constrs, clsAttrs, whenclauses, extObjCls, aliaseqns, _) :=
    lower2(listReverse(elems), functionTree, vars, knvars, extVars, {}, {}, {}, {}, {}, {}, {}, {}, HashTableExpToExp.emptyHashTable());
  whenclauses_1 := listReverse(whenclauses);
  aliasVars := BackendVariable.emptyVars();
  // handle alias equations
  (vars, knvars, extVars, aliasVars, eqns, reqns, ieqns, whenclauses_1) := handleAliasEquations(aliaseqns, vars, knvars, extVars, aliasVars, eqns, reqns, ieqns, whenclauses_1);
  vars_1 := detectImplicitDiscrete(vars, knvars, eqns);
  (vars_1, eqns) := addOptimizationVarsEqns(vars_1, eqns, Config.acceptOptimicaGrammar(), clsAttrs, constrs);
  eqnarr := BackendEquation.listEquation(eqns);
  reqnarr := BackendEquation.listEquation(reqns);
  ieqnarr := BackendEquation.listEquation(ieqns);
  einfo := BackendDAE.EVENT_INFO(timeEvents, whenclauses_1, {}, {}, {}, 0, 0);
  symjacs := {(NONE(), ({}, ({}, {})), {}), (NONE(), ({}, ({}, {})), {}), (NONE(), ({}, ({}, {})), {}), (NONE(), ({}, ({}, {})), {})};
  outBackendDAE := BackendDAE.DAE(BackendDAE.EQSYSTEM(vars_1,
                                                      eqnarr,
                                                      NONE(),
                                                      NONE(),
                                                      BackendDAE.NO_MATCHING(), {})::{},
                                  BackendDAE.SHARED(knvars,
                                                    extVars,
                                                    aliasVars,
                                                    ieqnarr,
                                                    reqnarr,
                                                    constrs,
                                                    clsAttrs,
                                                    inCache,
                                                    inEnv,
                                                    functionTree,
                                                    einfo,
                                                    extObjCls,
                                                    BackendDAE.SIMULATION(),
                                                    symjacs,inExtraInfo));
  BackendDAEUtil.checkBackendDAEWithErrorMsg(outBackendDAE);
  neqStr := intString(BackendDAEUtil.equationSize(eqnarr));
  nvarStr := intString(BackendVariable.varsSize(vars_1));
  Error.assertionOrAddSourceMessage(not Flags.isSet(Flags.DUMP_BACKENDDAE_INFO),Error.BACKENDDAEINFO_LOWER,{neqStr,nvarStr},Absyn.dummyInfo);
  Debug.execStat("generate Backend Data Structure", GlobalScript.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
end lower;

protected function lower2
  "Helper function to lower."
  input list<DAE.Element> inElements "input is in reverse order. this is faster than reversing all accumulators at the end";
  input DAE.FunctionTree functionTree;
  input BackendDAE.Variables inVars "The time depend Variables";
  input BackendDAE.Variables inKnVars "The time independend Variables";
  input BackendDAE.Variables inExVars "The external Variables";
  input list<BackendDAE.Equation> inEqnsLst "The dynamic Equations/Algoritms";
  input list<BackendDAE.Equation> inREqnsLst "The algebraic Equations";
  input list<BackendDAE.Equation> inIEqnsLst "The initial Equations";
  input list<DAE.Constraint> inConstraintLst;
  input list<DAE.ClassAttributes> inClassAttributeLst;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input BackendDAE.ExternalObjectClasses inExtObjClasses;
  input list<DAE.Element> iAliaseqns "List with all EqualityEquations";
  input HashTableExpToExp.HashTable iInlineHT "workaround to speed up inlining of array parameters";
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> oEqnsLst;
  output list<BackendDAE.Equation> oREqnsLst;
  output list<BackendDAE.Equation> oIEqnsLst;
  output list<DAE.Constraint> outConstraintLst;
  output list<DAE.ClassAttributes> outClassAttributeLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output BackendDAE.ExternalObjectClasses outExtObjClasses;
  output list<DAE.Element> oAliaseqns;
  output HashTableExpToExp.HashTable oinlineHT "workaround to speed up inlining of array parameters";
algorithm
  (outVariables, outKnownVariables, outExternalVariables, oEqnsLst, oREqnsLst, oIEqnsLst,
   outConstraintLst, outClassAttributeLst, outWhenClauseLst, outExtObjClasses, oAliaseqns, oinlineHT):=
   match (inElements, functionTree, inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, inIEqnsLst,
      inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT)
    local
      BackendDAE.Variables vars, knvars, extVars;
      list<BackendDAE.WhenClause> whenclauses;
      list<BackendDAE.Equation> eqns, reqns, ieqns;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      BackendDAE.ExternalObjectClasses extObjCls;
      DAE.Element daeEl;
      list<DAE.Element> daeLstRest, aliaseqns;
      HashTableExpToExp.HashTable inlineHT;
    // the empty case
    case ({}, _, _, _, _, _, _, _, _, _, _, _, _,_)
      then
        (inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, inIEqnsLst, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    case (daeEl::daeLstRest, _, _, _, _, _, _, _, _, _, _, _, _,_)
      equation
        (vars, knvars, extVars, eqns, reqns, ieqns, constrs, clsAttrs, whenclauses, extObjCls, aliaseqns, inlineHT) =
        lower3(daeEl, functionTree, inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, inIEqnsLst, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

        (vars, knvars, extVars, eqns, reqns, ieqns, constrs, clsAttrs, whenclauses, extObjCls, aliaseqns, inlineHT) =
        lower2(daeLstRest, functionTree, vars, knvars, extVars, eqns, reqns, ieqns, constrs, clsAttrs, whenclauses, extObjCls, aliaseqns, inlineHT);
      then
        (vars, knvars, extVars, eqns, reqns, ieqns, constrs, clsAttrs, whenclauses, extObjCls, aliaseqns, inlineHT);

  end match;
end lower2;

protected function lower3
  "Helper function to lower."
  input DAE.Element inElement "input is in reverse order. this is faster than reversing all accumulators at the end";
  input DAE.FunctionTree functionTree;
  input BackendDAE.Variables inVars "The time depend Variables";
  input BackendDAE.Variables inKnVars "The time independend Variables";
  input BackendDAE.Variables inExVars "The external Variables";
  input list<BackendDAE.Equation> inEqnsLst "The dynamic Equations/Algoritms";
  input list<BackendDAE.Equation> inREqnsLst "The algebraic Equations";
  input list<BackendDAE.Equation> inIEqnsLst "The initial Equations";
  input list<DAE.Constraint> inConstraintLst;
  input list<DAE.ClassAttributes> inClassAttributeLst;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input BackendDAE.ExternalObjectClasses inExtObjClasses;
  input list<DAE.Element> iAliaseqns "List with all EqualityEquations";
  input HashTableExpToExp.HashTable iInlineHT "workaround to speed up inlining of array parameters";
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> oEqnsLst;
  output list<BackendDAE.Equation> oREqnsLst;
  output list<BackendDAE.Equation> oIEqnsLst;
  output list<DAE.Constraint> outConstraintLst;
  output list<DAE.ClassAttributes> outClassAttributeLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output BackendDAE.ExternalObjectClasses outExtObjClasses;
  output list<DAE.Element> oAliaseqns;
  output HashTableExpToExp.HashTable oinlineHT "workaround to speed up inlining of array parameters";
algorithm
  (outVariables, outKnownVariables, outExternalVariables, oEqnsLst, oREqnsLst, oIEqnsLst,
   outConstraintLst, outClassAttributeLst, outWhenClauseLst, outExtObjClasses, oAliaseqns, oinlineHT):=
   match (inElement, functionTree, inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, inIEqnsLst,
      inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT)
    local
      list<DAE.Element> daeElts, aliaseqns;
      DAE.Constraint cons_1;
      list<DAE.Constraint> constrs;
      DAE.ClassAttributes clsattrs_1;
      list<DAE.ClassAttributes> clsAttrs;
      Absyn.Path path;
      BackendDAE.Variables vars, knvars, extVars;
      BackendDAE.ExternalObjectClasses extObjCls;
      BackendDAE.ExternalObjectClass extObjCl;
      list<BackendDAE.Equation> eqns, reqns, ieqns;
      list<BackendDAE.WhenClause> whenclauses;
      DAE.ElementSource source;
      HashTableExpToExp.HashTable inlineHT;
    // class for external object
    case (DAE.EXTOBJECTCLASS(path, source), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        extObjCl = BackendDAE.EXTOBJCLASS(path, source);
      then
        (inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, inIEqnsLst, inConstraintLst, inClassAttributeLst, inWhenClauseLst, extObjCl::inExtObjClasses, iAliaseqns, iInlineHT);

    // variables
    case (DAE.VAR(componentRef = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (vars, knvars, extVars, eqns, inlineHT) = lowerVar(inElement, functionTree, inVars, inKnVars, inExVars, inEqnsLst, iInlineHT);
      then
        (vars, knvars, extVars, eqns, inREqnsLst, inIEqnsLst, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, inlineHT);

    // scalar equations
    case (DAE.EQUATION(exp = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // initial equations
    case (DAE.INITIALEQUATION(exp1 = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // effort variable equality equations, seperated to generate alias variables
    case (DAE.EQUEQUATION(cr1 = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
        //eqns = inEqnsLst;
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, /*inElement::*/iAliaseqns, iInlineHT);

    // a solved equation
    case (DAE.DEFINE(componentRef = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // a initial solved equation
    case (DAE.INITIALDEFINE(componentRef = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // complex equations
    case (DAE.COMPLEX_EQUATION(lhs = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // complex initial equations
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // array equations
    case (DAE.ARRAY_EQUATION(exp = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // initial array equations
    case (DAE.INITIAL_ARRAY_EQUATION(exp = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // when equations
    case (DAE.WHEN_EQUATION(condition = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, whenclauses) = lowerWhenEqn(inElement, functionTree, inEqnsLst, inWhenClauseLst);
      then
        (inVars, inKnVars, inExVars, eqns, inREqnsLst, inIEqnsLst, inConstraintLst, inClassAttributeLst, whenclauses, inExtObjClasses, iAliaseqns, iInlineHT);

    // if equation
    case (DAE.IF_EQUATION(condition1 = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // initial if equation
    case (DAE.INITIAL_IF_EQUATION(condition1 = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerEqn(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst);
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // algorithm
    case (DAE.ALGORITHM(algorithm_ = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerAlgorithm(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst, DAE.EXPAND());
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // initial algorithm
    case (DAE.INITIALALGORITHM(algorithm_ = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (_,_, ieqns) = lowerAlgorithm(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst, DAE.EXPAND());
      then
        (inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // flat class / COMP
    case (DAE.COMP(dAElist = daeElts), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (vars, knvars, extVars, eqns, reqns, ieqns, constrs, clsAttrs, whenclauses, extObjCls, aliaseqns, inlineHT) = lower2(listReverse(daeElts), functionTree, inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, inIEqnsLst, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);
      then
        (vars, knvars, extVars, eqns, reqns, ieqns, constrs, clsAttrs, whenclauses, extObjCls, aliaseqns, inlineHT);

    // assert in equation section is converted to ALGORITHM
    case (DAE.ASSERT(condition = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerAlgorithm(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst, DAE.NOT_EXPAND());
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // terminate in equation section is converted to ALGORITHM
    case (DAE.TERMINATE(message = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerAlgorithm(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst, DAE.NOT_EXPAND());
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    case (DAE.NORETCALL(exp = _), _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        (eqns, reqns, ieqns) = lowerAlgorithm(inElement, functionTree, inEqnsLst, inREqnsLst, inIEqnsLst, DAE.NOT_EXPAND());
      then
        (inVars, inKnVars, inExVars, eqns, reqns, ieqns, inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    // constraint (Optimica) Just pass the constraints for now. Should anything more be done here?
    case (DAE.CONSTRAINT(constraints = cons_1), _, _, _, _, _, _, _, _, _, _, _, _, _)
      then
        (inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, inIEqnsLst, cons_1::inConstraintLst, inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    case (DAE.CLASS_ATTRIBUTES(classAttrs = clsattrs_1), _, _, _, _, _, _, _, _, _, _, _, _, _)
      then
        (inVars, inKnVars, inExVars, inEqnsLst, inREqnsLst, inIEqnsLst, inConstraintLst, clsattrs_1::inClassAttributeLst, inWhenClauseLst, inExtObjClasses, iAliaseqns, iInlineHT);

    case (_, _, _, _, _, _, _, _, _, _, _, _, _, _)
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.lower3 failed on: " +& DAEDump.dumpElementsStr({inElement}));
      then
        fail();
  end match;
end lower3;

// =============================================================================
// section for processing builtin expressions
//
// Insert a unique index (starting with 1) before the first arguments of some
// builtin calls. Equal calls will get the same index.
//   - delay(expr, delayTime, delayMax)
//       => delay(index, expr, delayTime, delayMax)
//   - sample(start, interval)
//       => sample(index, start, interval)
// =============================================================================

protected function processBuiltinExpressions "author: lochel
  Assign some builtin calls with a unique id argument."
  input DAE.DAElist inDAE;
  input DAE.FunctionTree functionTree;
  output DAE.DAElist outDAE;
  output DAE.FunctionTree outTree;
  output list<BackendDAE.TimeEvent> outTimeEvents;
protected
  HashTableExpToIndex.HashTable ht;
algorithm
  ht := HashTableExpToIndex.emptyHashTable();
  (outDAE, outTree, (ht, _, _, outTimeEvents)) := DAEUtil.traverseDAE(inDAE, functionTree, transformBuiltinExpressions, (ht, 0, 0, {}));
end processBuiltinExpressions;

protected function transformBuiltinExpressions "author: lochel
  Helper for processBuiltinExpressions"
  input tuple<DAE.Exp, tuple<HashTableExpToIndex.HashTable, Integer /*iDelay*/, Integer /*iSample*/, list<BackendDAE.TimeEvent>>> itpl;
  output tuple<DAE.Exp, tuple<HashTableExpToIndex.HashTable, Integer /*iDelay*/, Integer /*iSample*/, list<BackendDAE.TimeEvent>>> otpl;
protected
  DAE.Exp e;
  tuple<HashTableExpToIndex.HashTable, Integer, Integer, list<BackendDAE.TimeEvent>> i;
algorithm
  (e, i) := itpl;
  otpl := Expression.traverseExp(e, transformBuiltinExpression, i);
end transformBuiltinExpressions;

protected function transformBuiltinExpression "author: lochel
  Helper for transformBuiltinExpressions"
  input tuple<DAE.Exp, tuple<HashTableExpToIndex.HashTable, Integer /*iDelay*/, Integer /*iSample*/, list<BackendDAE.TimeEvent>>> inTuple;
  output tuple<DAE.Exp, tuple<HashTableExpToIndex.HashTable, Integer /*iDelay*/, Integer /*iSample*/, list<BackendDAE.TimeEvent>>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e, start, interval;
      list<DAE.Exp> es;
      HashTableExpToIndex.HashTable ht;
      Integer iDelay, iSample, i;
      list<BackendDAE.TimeEvent> timeEvents;
      DAE.CallAttributes attr;

    // delay [already in ht]
    case ((e as DAE.CALL(Absyn.IDENT("delay"), es, attr), (ht, iDelay, iSample, timeEvents))) equation
      i = BaseHashTable.get(e, ht);
    then ((DAE.CALL(Absyn.IDENT("delay"), DAE.ICONST(i)::es, attr), (ht, iDelay, iSample, timeEvents)));

    // delay [not yet in ht]
    case ((e as DAE.CALL(Absyn.IDENT("delay"), es, attr), (ht, iDelay, iSample, timeEvents))) equation
      ht = BaseHashTable.add((e, iDelay+1), ht);
    then ((DAE.CALL(Absyn.IDENT("delay"), DAE.ICONST(iDelay)::es, attr), (ht, iDelay+1, iSample, timeEvents)));

    // sample [already in ht]
    case ((e as DAE.CALL(Absyn.IDENT("sample"), es, attr), (ht, iDelay, iSample, timeEvents))) equation
      i = BaseHashTable.get(e, ht);
    then ((DAE.CALL(Absyn.IDENT("sample"), DAE.ICONST(i)::es, attr), (ht, iDelay, iSample, timeEvents)));

    // sample [not yet in ht]
    case ((e as DAE.CALL(Absyn.IDENT("sample"), es as {start, interval}, attr), (ht, iDelay, iSample, timeEvents))) equation
      iSample = iSample+1;
      timeEvents = listAppend(timeEvents, {BackendDAE.SAMPLE_TIME_EVENT(iSample, start, interval)});
      ht = BaseHashTable.add((e, iSample), ht);
    then ((DAE.CALL(Absyn.IDENT("sample"), DAE.ICONST(iSample)::es, attr), (ht, iDelay, iSample, timeEvents)));

    else inTuple;
  end matchcontinue;
end transformBuiltinExpression;

/*
 *  lower all variables
 */

public function lowerVars

  input list<DAE.Element> inElements;
  input DAE.FunctionTree functionTree;
  input BackendDAE.Variables inVars "The time depend Variables";
  input BackendDAE.Variables inKnVars "The time independend Variables";
  input BackendDAE.Variables inExVars "The external Variables";
  input list<BackendDAE.Equation> inEqnsLst "The dynamic Equations/Algoritms";
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> oEqnsLst;
algorithm
  (outVariables, outKnownVariables, outExternalVariables, oEqnsLst) :=
  matchcontinue (inElements, functionTree, inVars, inKnVars, inExVars, inEqnsLst)
    local
      list<DAE.Element> rest, newVars;
      DAE.Element elem,var;
      DAE.Type tp, arrtp;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs;
      BackendDAE.Variables vars, knvars, exvars;
      list<BackendDAE.Equation> eqns;
      String str;
      case ({}, _, _, _, _, _) then (inVars, inKnVars, inExVars, inEqnsLst);
      case ((var as DAE.VAR(componentRef = cref, ty = DAE.T_ARRAY(ty = arrtp)))::rest,  _, _, _, _, _)
        equation
          crefs = ComponentReference.expandCref(cref, false);
          elem = DAEUtil.replaceTypeInVar(arrtp, var);
          newVars = List.map1(crefs, DAEUtil.replaceCrefInVar, elem);
          (vars, knvars, exvars, eqns) = lowerVars(newVars, functionTree, inVars, inKnVars, inExVars, inEqnsLst);
          //(vars, knvars, exvars, eqns, _) = lowerVar(elem, functionTree, vars, knvars, exvars, eqns, HashTableExpToExp.emptyHashTable());
          (vars, knvars, exvars, eqns) = lowerVars(rest, functionTree, vars, knvars, exvars, eqns);
        then (vars, knvars, exvars, eqns);
      case ((elem as DAE.VAR(componentRef = _))::rest,  _, _, _, _, _)
        equation
          (vars, knvars, exvars, eqns, _) = lowerVar(elem, functionTree, inVars, inKnVars, inExVars, inEqnsLst, HashTableExpToExp.emptyHashTable());
          (vars, knvars, exvars, eqns) = lowerVars(rest, functionTree, vars, knvars, exvars, eqns);
        then (vars, knvars, exvars, eqns);
      case (elem::_,  _, _, _, _, _)
       equation
        str = "BackendDAECreate.lowerVars failed for " +& DAEDump.dumpElementsStr({elem});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();

  end matchcontinue;
end lowerVars;

protected function lowerVar
"Transforms a DAE variable to DAE variable.
  Includes changing the ComponentRef name to a simpler form
  \'a\'.\'b\'{2}\'c\'{5} becomes
  \'a.b{2}.c\' (as CREF_IDENT(\"a.b.c\", {2}) )
  inputs: (DAE.Element)
  outputs: Var"
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input BackendDAE.Variables inVars "The time depend Variables";
  input BackendDAE.Variables inKnVars "The time independend Variables";
  input BackendDAE.Variables inExVars "The external Variables";
  input list<BackendDAE.Equation> inEqnsLst "The dynamic Equations/Algoritms";
  input HashTableExpToExp.HashTable iInlineHT "workaround to speed up inlining of array parameters";
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> oEqnsLst;
  output HashTableExpToExp.HashTable oInlineHT "workaround to speed up inlining of array parameters";
algorithm
  (outVariables, outKnownVariables, outExternalVariables, oEqnsLst, oInlineHT) :=
  matchcontinue (inElement, functionTree, inVars, inKnVars, inExVars, inEqnsLst, iInlineHT)
    local
      String str;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      DAE.Exp e1, e2;
      BackendDAE.Var backendVar1;
      BackendDAE.Variables vars, knvars, extvars;
      HashTableExpToExp.HashTable inlineHT;
      list<BackendDAE.Equation> assrtEqs, eqLst;  // assrtEqs pop up when asserts are inlined
      list<DAE.Statement> assrtLst;
    // external object variables
    case (DAE.VAR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path=_))), _, _, _, _, _, _)
      equation
        backendVar1 = lowerExtObjVar(inElement, functionTree);
        extvars = BackendVariable.addVar(backendVar1, inExVars);
      then
        (inVars, inKnVars, extvars, inEqnsLst, iInlineHT);

    // variables: states and algebraic variables with binding equation
    case (DAE.VAR(componentRef = cr, binding=SOME(e2), source = source), _, _, _, _, _, _)
      equation
        // adrpo 2009-09-07 - according to MathCore
        // add the binding as an equation and remove the binding from variable!
        true = isStateOrAlgvar(inElement);
        (backendVar1) = lowerDynamicVar(inElement, functionTree);
        (e2, source, _,_) = Inline.inlineExp(e2, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        vars = BackendVariable.addVar(backendVar1, inVars);
        e1 = Expression.crefExp(cr);
      then
        (vars, inKnVars, inExVars, BackendDAE.EQUATION(e1, e2, source, false, BackendDAE.BINDING_EQUATION())::inEqnsLst, iInlineHT);

    // variables: states and algebraic variables with NO binding equation
    case (DAE.VAR(binding=NONE()), _, _, _, _, _, _)
      equation
        true = isStateOrAlgvar(inElement);
        (backendVar1) = lowerDynamicVar(inElement, functionTree);
        vars = BackendVariable.addVar(backendVar1, inVars);
      then
        (vars, inKnVars, inExVars, inEqnsLst, iInlineHT);

    // variables: states and algebraic variables with NO binding equation
    case (DAE.VAR(binding=NONE()), _, _, _, _, _, _)
      equation
        true = isStateOrAlgvar(inElement);
        (backendVar1) = lowerDynamicVar(inElement, functionTree);
        vars = BackendVariable.addVar(backendVar1, inVars);
      then
        (vars, inKnVars, inExVars, inEqnsLst, iInlineHT);

    // known variables: parameters and constants
    case (DAE.VAR(componentRef = _), _, _, _, _, _, _)
      equation
        (backendVar1, inlineHT,assrtEqs) = lowerKnownVar(inElement, functionTree, iInlineHT) "in previous rule, lower_var failed." ;
        knvars = BackendVariable.addVar(backendVar1, inKnVars);
        eqLst = listAppend(inEqnsLst,assrtEqs);
      then
        (inVars, knvars, inExVars, eqLst, inlineHT);  // CHANGE HERE TO EQLST

    else
      equation
        str = "BackendDAECreate.lowerVar failed for " +& DAEDump.dumpElementsStr({inElement});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();

  end matchcontinue;
end lowerVar;

protected function isStateOrAlgvar
  "@author adrpo
   check if this variable is a state or algebraic"
  input DAE.Element e;
  output Boolean out;
algorithm
  out := match (e)
    case (DAE.VAR(kind = DAE.VARIABLE())) then true;
    case (DAE.VAR(kind = DAE.DISCRETE())) then true;
    else false;
  end match;
end isStateOrAlgvar;

protected function lowerDynamicVar
"Transforms a DAE variable to DAE variable.
  Includes changing the ComponentRef name to a simpler form
  \'a\'.\'b\'{2}\'c\'{5} becomes
  \'a.b{2}.c\' (as CREF_IDENT(\"a.b.c\", {2}) )
  inputs: DAE.Element
  outputs: Var"
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  output BackendDAE.Var outVar;
algorithm
  (outVar) := match (inElement, functionTree)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      DAE.ConnectorType ct;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;
      DAE.VarVisibility protection;
      Boolean b;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  parallelism = prl,
                  protection = protection,
                  ty = t,
                  dims = dims,
                  connectorType = ct,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  comment = comment), _)
      equation
        (kind_1) = lowerVarkind(kind, t, name, dir, ct, dae_var_attr);
        tp = lowerType(t);
        b = DAEUtil.boolVarVisibility(protection);
        dae_var_attr = DAEUtil.setProtectedAttr(dae_var_attr, b);
        dae_var_attr = setMinMaxFromEnumeration(t, dae_var_attr);
        _ = BackendVariable.getMinMaxAsserts(dae_var_attr, name, source, kind_1, tp, {});
        _ = BackendVariable.getNominalAssert(dae_var_attr, name, source, kind_1, tp, {});
        (dae_var_attr, source, _) = Inline.inlineStartAttribute(dae_var_attr, source, (SOME(functionTree), {DAE.NORM_INLINE()}));
      then
        (BackendDAE.VAR(name, kind_1, dir, prl, tp, NONE(), NONE(), dims, source, dae_var_attr, comment, ct));
  end match;
end lowerDynamicVar;

protected function lowerKnownVar
"Helper function to lower2"
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input HashTableExpToExp.HashTable iInlineHT "workaround to speed up inlining of array parameters";
  output BackendDAE.Var outVar;
  output HashTableExpToExp.HashTable oInlineHT "workaround to speed up inlining of array parameters";
  output list<BackendDAE.Equation> assrtEqOut;
algorithm
  (outVar,oInlineHT,assrtEqOut) := matchcontinue (inElement, functionTree, iInlineHT)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind, bind1;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      DAE.ConnectorType ct;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;
      DAE.VarVisibility protection;
      Boolean b;
      String str;
      Functiontuple fnstpl;
      HashTableExpToExp.HashTable inlineHT;
      list<DAE.Statement> assrtLst;
      list<BackendDAE.Equation> eqLst;
    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  parallelism = prl,
                  protection = protection,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  connectorType = ct,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  comment = comment), _, _)
      equation
        kind_1 = lowerKnownVarkind(kind, name, dir, ct);
        // bind = fixParameterStartBinding(bind, t, dae_var_attr, kind_1);
        tp = lowerType(t);
        b = DAEUtil.boolVarVisibility(protection);
        dae_var_attr = DAEUtil.setProtectedAttr(dae_var_attr, b);
        dae_var_attr = setMinMaxFromEnumeration(t, dae_var_attr);
        _ = BackendVariable.getMinMaxAsserts(dae_var_attr, name, source, kind_1, tp, {});
        _ = BackendVariable.getNominalAssert(dae_var_attr, name, source, kind_1, tp, {});
        fnstpl = (SOME(functionTree), {DAE.NORM_INLINE()});
        // build algorithms for the inlined asserts
        (bind1, source, inlineHT,assrtLst) = inlineExpOpt(bind, fnstpl, source, iInlineHT);
        eqLst = buildAssertAlgorithms(assrtLst,source,{});
        // building an algorithm of the assert
        (dae_var_attr, source, _) = Inline.inlineStartAttribute(dae_var_attr, source, fnstpl);
      then
        (BackendDAE.VAR(name, kind_1, dir, prl, tp, bind1, NONE(), dims, source, dae_var_attr, comment, ct), inlineHT,eqLst);

    else
      equation
        str = "BackendDAECreate.lowerKnownVar failed for " +& DAEDump.dumpElementsStr({inElement});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end lowerKnownVar;


protected function buildAssertAlgorithms "builds BackendDAE.ALGORITHM out of the given assert statements
author:Waurich TUD 2013-10"
  input list<DAE.Statement> assrtIn;
  input DAE.ElementSource source;
  input list<BackendDAE.Equation> eqIn;
  output list<BackendDAE.Equation> eqOut;
algorithm
  eqOut := matchcontinue(assrtIn,source,eqIn)
  local
    BackendDAE.Equation eq;
    DAE.Statement assrt;
    list<DAE.Statement> rest;
    list<BackendDAE.Equation> eqLst;
  case({},_,_)
    then
      eqIn;
    case(assrt::rest,_,_)
      equation
      eq = BackendDAE.ALGORITHM(0,DAE.ALGORITHM_STMTS({assrt}),source,DAE.EXPAND(),BackendDAE.DYNAMIC_EQUATION());
      eqLst = buildAssertAlgorithms(rest,source,eq::eqIn);
    then
      eqLst;
    else
      equation
        print("buildAssertAlgorithm failed!\n");
      then
        fail();
  end matchcontinue;
end buildAssertAlgorithms;


protected function inlineExpOpt
"author Frenkel TUD 2013-02"
  input Option<DAE.Exp> iOptExp;
  input Functiontuple fnstpl;
  input DAE.ElementSource iSource;
  input HashTableExpToExp.HashTable iInlineHT "workaround to speed up inlining of array parameters";
  output Option<DAE.Exp> oOptExp;
  output DAE.ElementSource oSource;
  output HashTableExpToExp.HashTable oInlineHT "workaround to speed up inlining of array parameters";
  output list<DAE.Statement> assrtLstOut;
algorithm
  (oOptExp,oSource,oInlineHT,assrtLstOut) := match(iOptExp,fnstpl,iSource,iInlineHT)
    local
      DAE.Exp e;
      DAE.ElementSource source;
      HashTableExpToExp.HashTable inlineHT;
      list<DAE.Statement> assrtLst;
    case (NONE(),_,_,_) then (iOptExp,iSource,iInlineHT,{});
    case (SOME(e),_,_,_)
      equation
        (e, source, inlineHT,assrtLst) = inlineExpOpt1(e, fnstpl, iSource, iInlineHT);
      then (SOME(e),source,inlineHT,assrtLst);
  end match;
end inlineExpOpt;

protected function inlineExpOpt1
"author Frenkel TUD 2013-02"
  input DAE.Exp iExp;
  input Functiontuple fnstpl;
  input DAE.ElementSource iSource;
  input HashTableExpToExp.HashTable iInlineHT "workaround to speed up inlining of array parameters";
  output DAE.Exp oExp;
  output DAE.ElementSource oSource;
  output HashTableExpToExp.HashTable oInlineHT "workaround to speed up inlining of array parameters";
  output list<DAE.Statement> assrtLstOut;
algorithm
  (oExp,oSource,oInlineHT,assrtLstOut) := matchcontinue(iExp,fnstpl,iSource,iInlineHT)
    local
      DAE.Exp e,e1;
      list<DAE.Exp> elst;
      DAE.ElementSource source;
      HashTableExpToExp.HashTable inlineHT;
      Boolean inlined;
      list<DAE.Statement> assrtLst,assrtLst1,assrtLst2;
    case (DAE.CALL(path=_),_,_,_)
      equation
        e1 = BaseHashTable.get(iExp,iInlineHT);
        // print("use chache Inline\n" +& ExpressionDump.printExpStr(iExp) +& "\n");
        source = DAEUtil.addSymbolicTransformation(iSource,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(iExp),DAE.PARTIAL_EQUATION(e1)));
      then (e1,source,iInlineHT,{});
    case (DAE.CALL(path=_),_,_,_)
      equation
        // print("add chache Inline\n" +& ExpressionDump.printExpStr(iExp) +& "\n");
        (e1, source, inlined,_) = Inline.inlineExp(iExp, fnstpl, iSource);
        inlineHT = Debug.bcallret2(inlined, BaseHashTable.add, (iExp,e1), iInlineHT, iInlineHT);
      then (e1,source,inlineHT,{});
    case (DAE.ASUB(e,elst),_,_,_)
      equation
        e1 = BaseHashTable.get(e,iInlineHT);
        // print("use chache Inline\n" +& ExpressionDump.printExpStr(iExp) +& "\n");
        source = DAEUtil.addSymbolicTransformation(iSource,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(e),DAE.PARTIAL_EQUATION(e1)));
        (e, source, _,_) = Inline.inlineExp(DAE.ASUB(e1,elst), fnstpl, source);
      then (e,source,iInlineHT,{});
    case (DAE.ASUB(e,elst),_,_,_)
      equation
        // print("add chache Inline(1)\n" +& ExpressionDump.printExpStr(iExp) +& "\n");
        (e1, _, inlined,assrtLst1) = Inline.inlineExp(e, fnstpl, iSource);
        inlineHT = Debug.bcallret2(inlined, BaseHashTable.add, (e,e1), iInlineHT, iInlineHT);
        (e, source, _,assrtLst2) = Inline.inlineExp(DAE.ASUB(e1,elst), fnstpl, iSource);
        assrtLst = listAppend(assrtLst1,assrtLst2);
      then (e,source,inlineHT,assrtLst);
    case (_,_,_,_)
      equation
        // print("no chache Inline\n" +& ExpressionDump.printExpStr(iExp) +& "\n");
        (e, source, _,_) = Inline.inlineExp(iExp, fnstpl, iSource);
      then (e,source,iInlineHT,{});
  end matchcontinue;
end inlineExpOpt1;

protected function setMinMaxFromEnumeration
  input DAE.Type inType;
  input Option<DAE.VariableAttributes> inVarAttr;
  output Option<DAE.VariableAttributes> outVarAttr;
algorithm
  outVarAttr := matchcontinue (inType, inVarAttr)
    local
      Option<DAE.Exp> min, max;
      list<String> names;
      Absyn.Path path;
    case (DAE.T_ENUMERATION(path=path, names = names), _)
      equation
        (min, max) = DAEUtil.getMinMaxValues(inVarAttr);
      then
        setMinMaxFromEnumeration1(min, max, inVarAttr, path, names);
    else inVarAttr;
  end matchcontinue;
end setMinMaxFromEnumeration;

protected function setMinMaxFromEnumeration1
  input Option<DAE.Exp> inMin;
  input Option<DAE.Exp> inMax;
  input Option<DAE.VariableAttributes> inVarAttr;
  input Absyn.Path inPath;
  input list<String> inNames;
  output Option<DAE.VariableAttributes> outVarAttr;
algorithm
  outVarAttr := matchcontinue (inMin, inMax, inVarAttr, inPath, inNames)
    local
      Integer i;
      Absyn.Path namee1, nameen;
      String s1, sn;
      DAE.Exp e;
    case (NONE(), NONE(), _, _, _)
      equation
        i = listLength(inNames);
        s1 = listGet(inNames, 1);
        namee1 = Absyn.joinPaths(inPath, Absyn.IDENT(s1));
        sn = listGet(inNames, i);
        nameen = Absyn.joinPaths(inPath, Absyn.IDENT(sn));
      then
        DAEUtil.setMinMax(inVarAttr, SOME(DAE.ENUM_LITERAL(namee1, 1)), SOME(DAE.ENUM_LITERAL(nameen, i)));
    case (NONE(), SOME(e), _, _, _)
      equation
        _ = listLength(inNames);
        s1 = listGet(inNames, 1);
        namee1 = Absyn.joinPaths(inPath, Absyn.IDENT(s1));
      then
        DAEUtil.setMinMax(inVarAttr, SOME(DAE.ENUM_LITERAL(namee1, 1)), SOME(e));
    case (SOME(e), NONE(), _, _, _)
      equation
        i = listLength(inNames);
        sn = listGet(inNames, i);
        nameen = Absyn.joinPaths(inPath, Absyn.IDENT(sn));
      then
        DAEUtil.setMinMax(inVarAttr, SOME(e), SOME(DAE.ENUM_LITERAL(nameen, i)));
    else inVarAttr;
  end matchcontinue;
end setMinMaxFromEnumeration1;

// protected function fixParameterStartBinding
//   input Option<DAE.Exp> bind;
//   input DAE.Type ty;
//   input Option<DAE.VariableAttributes> attr;
//   input BackendDAE.VarKind kind;
//   output Option<DAE.Exp> outBind;
// algorithm
//   outBind := matchcontinue (bind, ty, attr, kind)
//     local
//       DAE.Exp exp;
//     case (NONE(), DAE.T_REAL(source=_), _, BackendDAE.PARAM())
//       equation
//         exp = DAEUtil.getStartAttr(attr);
//       then SOME(exp);
//     else bind;
//   end matchcontinue;
// end fixParameterStartBinding;

protected function lowerVarkind
"Helper function to lowerVar.
  inputs: (DAE.VarKind,
           Type,
           DAE.ComponentRef,
           DAE.VarDirection, /* input/output/bidir */
           DAE.ConnectorType)
  outputs  VarKind
  NOTE: Fails for not states that are not algebraic
        variables, e.g. parameters and constants"
  input DAE.VarKind inVarKind;
  input DAE.Type inType;
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
  input Option<DAE.VariableAttributes> daeAttr;
  output BackendDAE.VarKind outVarKind;
algorithm
  (outVarKind) := matchcontinue (inVarKind, inType, inComponentRef, inVarDirection, inConnectorType, daeAttr)
    // variable -> state if have stateSelect=StateSelect.always
    case (DAE.VARIABLE(), _, _, _, _, SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS()))))
      then (BackendDAE.STATE(1,NONE()));
    // variable -> state if have stateSelect=StateSelect.prefer
    case (DAE.VARIABLE(), _, _, _, _, SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.PREFER()))))
      then (BackendDAE.STATE(1,NONE()));

    case (DAE.VARIABLE(), DAE.T_BOOL(varLst = _), _, _, _, _)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType));
      then
        (BackendDAE.DISCRETE());

    case (DAE.DISCRETE(), DAE.T_BOOL(varLst = _), _, _, _, _)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType));
      then
        (BackendDAE.DISCRETE());

    case (DAE.VARIABLE(), DAE.T_INTEGER(varLst = _), _, _, _, _)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType));
      then
        (BackendDAE.DISCRETE());

    case (DAE.DISCRETE(), DAE.T_INTEGER(varLst = _), _, _, _, _)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType));
      then
        (BackendDAE.DISCRETE());

    case (DAE.VARIABLE(), DAE.T_ENUMERATION(names = _), _, _, _, _)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType));
      then
        (BackendDAE.DISCRETE());

    case (DAE.DISCRETE(), DAE.T_ENUMERATION(names = _), _, _, _, _)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType));
      then
        (BackendDAE.DISCRETE());

    case (DAE.VARIABLE(), _, _, _, _, _)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType));
      then
        (BackendDAE.VARIABLE());

    case (DAE.DISCRETE(), _, _, _, _, _)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType));
      then
        (BackendDAE.DISCRETE());
  end matchcontinue;
end lowerVarkind;

protected function lowerKnownVarkind
"Helper function to lowerKnownVar.
  NOTE: Fails for everything but parameters and constants and top level inputs"
  input DAE.VarKind inVarKind;
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.ConnectorType inConnectorType;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind := matchcontinue (inVarKind, inComponentRef, inVarDirection, inConnectorType)

    case (DAE.PARAM(), _, _, _) then BackendDAE.PARAM();
    case (DAE.CONST(), _, _, _) then BackendDAE.CONST();
    case (DAE.VARIABLE(), _, _, _)
      equation
        BackendVariable.topLevelInput(inComponentRef, inVarDirection, inConnectorType);
      then
        BackendDAE.VARIABLE();
    // adrpo: topLevelInput might fail!
    // case (DAE.VARIABLE(), cr, dir, flowPrefix)
    //  then
    //    BackendDAE.VARIABLE();
    case (_, _, _, _)
      equation
        print("lowerKnownVarkind failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVarkind;

protected function lowerType
"Transforms a DAE.Type to Type"
  input  DAE.Type inType;
  output BackendDAE.Type outType;
algorithm
  outType := matchcontinue(inType)
    local
    case (DAE.T_REAL(varLst = _)) then DAE.T_REAL_DEFAULT;
    case (DAE.T_INTEGER(varLst = _)) then DAE.T_INTEGER_DEFAULT;
    case (DAE.T_BOOL(varLst = _)) then DAE.T_BOOL_DEFAULT;
    case (DAE.T_STRING(varLst = _)) then DAE.T_STRING_DEFAULT;
    case (DAE.T_ENUMERATION(names = _)) then inType;
    case (DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path=_)))
      then inType;
    case (DAE.T_COMPLEX(complexClassType = ClassInf.RECORD(path=_)))
      then inType;
    case (DAE.T_ARRAY(ty = _))
      then inType;
    case (DAE.T_FUNCTION(funcResultType = _))
      then inType;
    else equation print("lowerType: " +& Types.printTypeStr(inType) +& " failed\n"); then fail();
  end matchcontinue;
end lowerType;

protected function lowerExtObjVar
" Helper function to lower2
  Fails for all variables except external object instances."
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  output BackendDAE.Var outVar;
algorithm
  outVar:=
  match (inElement, functionTree)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      DAE.ConnectorType ct;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  direction = dir,
                  parallelism = prl,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  connectorType = ct,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  comment = comment), _)
      equation
        kind_1 = lowerExtObjVarkind(t);
        tp = lowerType(t);
        (bind, source, _) = Inline.inlineExpOpt(bind, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (dae_var_attr, source, _) = Inline.inlineStartAttribute(dae_var_attr, source, (SOME(functionTree), {DAE.NORM_INLINE()}));
      then
        BackendDAE.VAR(name, kind_1, dir, prl, tp, bind, NONE(), dims, source, dae_var_attr, comment, ct);
  end match;
end lowerExtObjVar;

protected function lowerExtObjVarkind
" Helper function to lowerExtObjVar.
  NOTE: Fails for everything but External objects"
  input DAE.Type inType;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind :=
  match (inType)
    local Absyn.Path path;
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path=path)) then BackendDAE.EXTOBJ(path);
  end match;
end lowerExtObjVarkind;

/*
 *  lower all equation types
 */

protected function lowerEqn
"Helper function to lower2.
  Transforms a DAE.Element to Equation."
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Equation> inREquations;
  input list<BackendDAE.Equation> inIEquations;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outREquations;
  output list<BackendDAE.Equation> outIEquations;
algorithm
  (outEquations,outREquations,outIEquations) :=  match (inElement,functionTree,inEquations,inREquations,inIEquations)
    local
      DAE.Exp e1, e1_1, e2, e2_1, cond, msg, level;
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource source;
      Boolean b1;
      Integer size;
      DAE.Dimensions dims;
      list<DAE.Exp> explst, explst1;
      list<list<DAE.Element>> eqnslstlst;
      list<DAE.Element> eqnslst,daeElts;
      String s;
      list<BackendDAE.Equation> eqns,reqns,ieqns;
      Absyn.Path path;

    // tuple-tuple assignments are split into one equation for each tuple
    // element, i.e. (i1, i2) = (4, 6) => i1 = 4; i2 = 6;
    case (DAE.EQUATION(DAE.TUPLE(explst), DAE.TUPLE(explst1), source = source),_,_,_,_)
      equation
        eqns = lowerTupleAssignment(explst,explst1,source,functionTree,inEquations);
      then
        (eqns,inREquations,inIEquations);
    case (DAE.INITIALEQUATION(DAE.TUPLE(explst), DAE.TUPLE(explst1), source = source),_,_,_,_)
      equation
        eqns = lowerTupleAssignment(explst,explst1,source,functionTree,inIEquations);
      then
        (inEquations,inREquations,eqns);

    // Only succeds for tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c)

    case(DAE.EQUATION(DAE.TUPLE(explst),e2 as DAE.CALL(path =_),source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(_,e2_1), source) = Inline.simplifyAndForceInlineEquationExp(DAE.EQUALITY_EXPS(DAE.TUPLE(explst),e2), (SOME(functionTree), {DAE.NORM_INLINE(), DAE.NO_INLINE()}), source);
        eqns = lowerExtendedRecordEqn(DAE.TUPLE(explst),e2_1,source,BackendDAE.DYNAMIC_EQUATION(),functionTree,inEquations);
      then
        (eqns,inREquations,inIEquations);

    case(DAE.EQUATION(e2 as DAE.CALL(path =_),DAE.TUPLE(explst),source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2_1), source) = Inline.simplifyAndForceInlineEquationExp(DAE.EQUALITY_EXPS(DAE.TUPLE(explst),e2), (SOME(functionTree), {DAE.NORM_INLINE(), DAE.NO_INLINE()}), source);
        eqns = lowerExtendedRecordEqn(e1,e2_1,source,BackendDAE.DYNAMIC_EQUATION(),functionTree,inEquations);
      then
        (eqns,inREquations,inIEquations);

    // Only succeds for initial tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c)
    case(DAE.INITIALEQUATION(DAE.TUPLE(explst),e2 as DAE.CALL(path =_),source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2_1), source) = Inline.simplifyAndForceInlineEquationExp(DAE.EQUALITY_EXPS(DAE.TUPLE(explst),e2), (SOME(functionTree), {DAE.NORM_INLINE(), DAE.NO_INLINE()}), source);
        eqns = lowerExtendedRecordEqn(e1,e2_1,source,BackendDAE.INITIAL_EQUATION(),functionTree,inIEquations);
      then
        (inEquations,inREquations,eqns);

    case(DAE.INITIALEQUATION(e2 as DAE.CALL(path =_),DAE.TUPLE(explst),source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2_1), source) = Inline.simplifyAndForceInlineEquationExp(DAE.EQUALITY_EXPS(DAE.TUPLE(explst),e2), (SOME(functionTree), {DAE.NORM_INLINE(), DAE.NO_INLINE()}), source);
        eqns = lowerExtendedRecordEqn(e1,e2_1,source,BackendDAE.INITIAL_EQUATION(),functionTree,inIEquations);
      then
        (inEquations,inREquations,eqns);

    case (DAE.EQUATION(exp = e1,scalar = e2,source = source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
      then
        (BackendDAE.EQUATION(e1,e2,source,false,BackendDAE.DYNAMIC_EQUATION())::inEquations,inREquations,inIEquations);

    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2,source = source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
      then
        (inEquations,inREquations,BackendDAE.EQUATION(e1,e2,source,false,BackendDAE.INITIAL_EQUATION())::inIEquations);

    case (DAE.EQUEQUATION(cr1 = cr1, cr2 = cr2,source = source),_,_,_,_)
      equation
        e1 = Expression.crefExp(cr1);
        e2 = Expression.crefExp(cr2);
        eqns = lowerExtendedRecordEqn(e1,e2,source,BackendDAE.DYNAMIC_EQUATION(),functionTree,inEquations);
      then
       (eqns,inREquations,inIEquations);

    case (DAE.DEFINE(componentRef = cr1, exp = e2, source = source),_,_,_,_)
      equation
        e1 = Expression.crefExp(cr1);
        (DAE.EQUALITY_EXPS(e1,e2), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
      then
        (BackendDAE.EQUATION(e1,e2,source,false,BackendDAE.DYNAMIC_EQUATION())::inEquations,inREquations,inIEquations);

    case (DAE.INITIALDEFINE(componentRef = cr1, exp = e2, source = source),_,_,_,_)
      equation
        e1 = Expression.crefExp(cr1);
        (DAE.EQUALITY_EXPS(e1,e2), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
      then
        (inEquations,inREquations,BackendDAE.EQUATION(e1,e2,source,false,BackendDAE.DYNAMIC_EQUATION())::inIEquations);

    case (DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2), source) = Inline.simplifyAndForceInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE(), DAE.NO_INLINE()}), source);
        eqns = lowerExtendedRecordEqn(e1,e2,source,BackendDAE.DYNAMIC_EQUATION(),functionTree,inEquations);
      then
        (eqns,inREquations,inIEquations);

    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        size = Expression.sizeOf(Expression.typeof(e1));
      then
        (inEquations,inREquations,BackendDAE.COMPLEX_EQUATION(size,e1,e2,source,false,BackendDAE.DYNAMIC_EQUATION())::inIEquations);

    // equalityConstraint equations, moved to removed equations
    case (DAE.ARRAY_EQUATION(dimension=dims, exp = e1 as DAE.ARRAY(array={}),array = e2 as DAE.CALL(path=path),source = source),_,_,_,_)
      equation
        b1 = stringEq(Absyn.pathLastIdent(path),"equalityConstraint");
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        eqns = Util.if_(b1,inREquations,inEquations);
        eqns = lowerArrayEqn(dims,e1_1,e2_1,source,BackendDAE.DYNAMIC_EQUATION(),eqns);
        ((eqns,_)) = Util.if_(b1,(inEquations,eqns),(eqns,inREquations));
      then
        (eqns,inREquations,inIEquations);

    case (DAE.ARRAY_EQUATION(dimension=dims,exp = e1,array = e2,source = source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        eqns = lowerArrayEqn(dims,e1,e2,source,BackendDAE.DYNAMIC_EQUATION(),inEquations);
      then
        (eqns,inREquations,inIEquations);

    case (DAE.INITIAL_ARRAY_EQUATION(dimension=dims,exp = e1,array = e2,source = source),_,_,_,_)
      equation
        (DAE.EQUALITY_EXPS(e1,e2), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        eqns = lowerArrayEqn(dims,e1,e2,source,BackendDAE.DYNAMIC_EQUATION(),inIEquations);
      then
        (inEquations,inREquations,eqns);

   // if equation that cannot be translated to if expression but have initial() as condition
    case (DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))},equations2={eqnslst},equations3={}),_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerEqns(eqnslst,functionTree,{},{},{});
        ieqns = List.flatten({eqns,reqns,ieqns,inIEquations});
      then
        (inEquations,inREquations,ieqns);

    case (DAE.IF_EQUATION(condition1=explst,equations2=eqnslstlst,equations3=eqnslst,source = source),_,_,_,_)
      equation
        // move out assert, terminate, message stuff from if equation
        (eqnslstlst,eqnslst,daeElts) = lowerIfEquationAsserts(explst,eqnslstlst,eqnslst,{},{},{});
        (eqns,reqns,ieqns) = lowerEqns(daeElts,functionTree,inEquations,inREquations,inIEquations);
        eqns = lowerIfEquation(explst,eqnslstlst,eqnslst,{},{},source,functionTree,eqns);
      then
        (eqns,reqns,ieqns);

    case (DAE.INITIAL_IF_EQUATION(condition1=explst,equations2=eqnslstlst,equations3=eqnslst,source = source),_,_,_,_)
      equation
        eqns = lowerIfEquation(explst,eqnslstlst,eqnslst,{},{},source,functionTree,inIEquations);
      then
       (inEquations,inREquations,eqns);

    // algorithm
    case (DAE.ALGORITHM(algorithm_ = _),_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.EXPAND());
      then
        (eqns,reqns,ieqns);

    // initial algorithm
    case (DAE.INITIALALGORITHM(algorithm_ = _),_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.EXPAND());
      then
        (eqns,reqns,ieqns);

    case (DAE.ASSERT(condition=_,message=_),_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.NOT_EXPAND());
      then
        (eqns,reqns,ieqns);

    case (DAE.TERMINATE(message=msg,source=source),_,_,_,_)
      then
        (inEquations,inREquations,BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg,source)}), source, DAE.NOT_EXPAND(), BackendDAE.DYNAMIC_EQUATION())::inIEquations);

    case (DAE.NORETCALL(exp = _),_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.NOT_EXPAND());
      then
        (eqns,reqns,ieqns);

    case (_,_,_,_,_)
      equation
        s = "BackendDAECreate.lowerEqn failed for " +& DAEDump.dumpElementsStr({inElement});
        Error.addSourceMessage(Error.INTERNAL_ERROR, {s}, DAEUtil.getElementSourceFileInfo(DAEUtil.getElementSource(inElement)));
      then fail();

  end match;
end lowerEqn;

protected function lowerIfEquation
  input list<DAE.Exp> conditions;
  input list<list<DAE.Element>> theneqns;
  input list<DAE.Element> elseenqs;
  input list<DAE.Exp> conditions1;
  input list<list<DAE.Element>> theneqns1;
  input DAE.ElementSource inSource;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEquations;
  output list<BackendDAE.Equation> outEquations;
algorithm
  outEquations := matchcontinue(conditions,theneqns,elseenqs,conditions1,theneqns1,inSource,functionTree,inEquations)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      list<list<DAE.Element>> eqnslst;
      list<DAE.Element> eqns;
      DAE.ElementSource source;
      list<list<BackendDAE.Equation>> beqnslst;
      list<BackendDAE.Equation> beqns,breqns,bieqns;

    // no true case left with condition<>false
    case ({},{},_,{},{},_,_,_)
      equation
        (beqns,breqns,bieqns) = lowerEqns(elseenqs,functionTree,{},{},{});
        beqns = List.flatten({beqns,breqns,bieqns,inEquations});
      then
        beqns;

    // true case left with condition<>false
    case ({}, {}, _, _, _, _, _, _)
      equation
        explst = listReverse(conditions1);
        beqnslst = lowerEqnsLst(theneqns1,functionTree,{});
        (beqns,breqns,bieqns) = lowerEqns(elseenqs,functionTree,{},{},{});
        beqns = List.flatten({beqns,breqns,bieqns});
      then
        BackendDAE.IF_EQUATION(explst, beqnslst, beqns, inSource, BackendDAE.UNKNOWN_EQUATION_KIND())::inEquations;

    // all other cases
    case(e::explst, eqns::eqnslst, _, _, _, _, _, _)
      equation
        (DAE.PARTIAL_EQUATION(e), source) = Inline.simplifyAndInlineEquationExp(DAE.PARTIAL_EQUATION(e), (SOME(functionTree), {DAE.NORM_INLINE()}), inSource);
      then
        lowerIfEquation1(e,explst,eqns,eqnslst,elseenqs,conditions1,theneqns1,source,functionTree,inEquations);
  end matchcontinue;
end lowerIfEquation;

protected function lowerIfEquation1
  input DAE.Exp cond;
  input list<DAE.Exp> conditions;
  input list<DAE.Element> theneqn;
  input list<list<DAE.Element>> theneqns;
  input list<DAE.Element> elseenqs;
  input list<DAE.Exp> conditions1;
  input list<list<DAE.Element>> theneqns1;
  input DAE.ElementSource source;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(cond, conditions, theneqn, theneqns, elseenqs, conditions1, theneqns1, source, functionTree, inEqns)
    local
      list<DAE.Exp> explst;
      list<list<BackendDAE.Equation>> beqnslst;
      list<BackendDAE.Equation> beqns,breqns,bieqns;

    // if true use it if it is the first one
    case(DAE.BCONST(true), _, _, _, _, {}, {}, _, _, _)
      equation
        (beqns,breqns,bieqns) = lowerEqns(theneqn,functionTree,{},{},{});
        beqns = List.flatten({beqns,breqns,bieqns,inEqns});
      then
        beqns;

    // if true use it as new else if it is not the first one
    case(DAE.BCONST(true), _, _, _, _, {}, {}, _, _, _)
      equation
        explst = listReverse(conditions1);
        beqnslst = lowerEqnsLst(theneqns1,functionTree,{});
        (beqns,breqns,bieqns) = lowerEqns(theneqn,functionTree,{},{},{});
        beqns = List.flatten({beqns,breqns,bieqns});
      then
        BackendDAE.IF_EQUATION(explst, beqnslst, beqns, source, BackendDAE.UNKNOWN_EQUATION_KIND())::inEqns;

    // if false skip it
    case(DAE.BCONST(false), _, _, _, _, _, _, _, _, _)
      then
        lowerIfEquation(conditions, theneqns, elseenqs, conditions1, theneqns1, source, functionTree, inEqns);
    // all other cases
    case(_, _, _, _, _, _, _, _, _, _)
      then
        lowerIfEquation(conditions, theneqns, elseenqs, cond::conditions1, theneqn::theneqns1, source, functionTree, inEqns);
  end matchcontinue;
end lowerIfEquation1;

protected function lowerEqns "author: Frenkel TUD 2012-06"
  input list<DAE.Element> inElements;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Equation> inREquations;
  input list<BackendDAE.Equation> inIEquations;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outREquations;
  output list<BackendDAE.Equation> outIEquations;
algorithm
  (outEquations,outREquations,outIEquations) := match(inElements,functionTree,inEquations,inREquations,inIEquations)
    local
      DAE.Element element;
      list<DAE.Element> elements;
      list<BackendDAE.Equation> eqns,reqns,ieqns;
  case({},_,_,_,_) then (inEquations,inREquations,inIEquations);
  case(element::elements,_,_,_,_)
    equation
      (eqns,reqns,ieqns) = lowerEqn(element,functionTree,inEquations,inREquations,inIEquations);
      (eqns,reqns,ieqns) = lowerEqns(elements,functionTree,eqns,reqns,ieqns);
    then
      (eqns,reqns,ieqns);
  end match;
end lowerEqns;

protected function lowerEqnsLst "author: Frenkel TUD 2012-06"
  input list<list<DAE.Element>> inElements;
  input DAE.FunctionTree functionTree;
  input list<list<BackendDAE.Equation>> inEquations;
  output list<list<BackendDAE.Equation>> outEquations;
algorithm
  outEquations := match(inElements,functionTree,inEquations)
    local
      list<DAE.Element> element;
      list<list<DAE.Element>> elements;
      list<BackendDAE.Equation> eqns,reqns,ieqns;
  case({},_,_) then inEquations;
  case(element::elements,_,_)
    equation
      (eqns,reqns,ieqns) = lowerEqns(element,functionTree,{},{},{});
      eqns = List.flatten({eqns,reqns,ieqns});
    then
      lowerEqnsLst(elements,functionTree,eqns::inEquations);
  end match;
end lowerEqnsLst;

protected function lowerIfEquationAsserts "author: Frenkel TUD 2012-10
  lowar all asserts in if equations"
  input list<DAE.Exp> conditions;
  input list<list<DAE.Element>> theneqns;
  input list<DAE.Element> elseenqs;
  input list<DAE.Exp> conditions1;
  input list<list<DAE.Element>> theneqns1;
  input list<DAE.Element> inEqns;
  output list<list<DAE.Element>> otheneqns;
  output list<DAE.Element> oelseenqs;
  output list<DAE.Element> outEqns;
algorithm
  (otheneqns, oelseenqs, outEqns) := match(conditions, theneqns, elseenqs, conditions1, theneqns1, inEqns)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      list<DAE.Element> eqns, eqns1, beqns;
      list<list<DAE.Element>> eqnslst, eqnslst1;

    case (_, {}, _, _, _, _)
      equation
        (beqns, eqns) = lowerIfEquationAsserts1(elseenqs, NONE(), conditions1, {}, inEqns);
      then
        (listReverse(theneqns1), beqns, eqns);
    case (e::explst, eqns::eqnslst, _, _, _, _)
      equation
        (beqns, eqns) = lowerIfEquationAsserts1(eqns, SOME(e), conditions1, {}, inEqns);
        (eqnslst1, eqns1, eqns) = lowerIfEquationAsserts(explst, eqnslst, elseenqs, e::conditions1, beqns::theneqns1, eqns);
      then
        (eqnslst1, eqns1, eqns);
  end match;
end lowerIfEquationAsserts;

protected function lowerIfEquationAsserts1 "author: Frenkel TUD 2012-10
  helper for lowerIfEquationAsserts"
  input list<DAE.Element> brancheqns;
  input Option<DAE.Exp> condition;
  input list<DAE.Exp> conditions "reversed";
  input list<DAE.Element> brancheqns1;
  input list<DAE.Element> inEqns;
  output list<DAE.Element> obrancheqns;
  output list<DAE.Element> outEqns;
algorithm
  (obrancheqns, outEqns) := match(brancheqns, condition, conditions, brancheqns1, inEqns)
    local
      Absyn.Path functionName;
      DAE.Exp e, exp, cond, msg, level;
      list<DAE.Exp> explst;
      DAE.Element eqn;
      list<DAE.Element> eqns, beqns;
      DAE.ElementSource source;
    case ({}, _, _, _, _)
      then
        (listReverse(brancheqns1), inEqns);
    case (DAE.ASSERT(condition=cond, message=msg, level=level, source=source)::eqns, NONE(), _, _, _)
      equation
        e = List.fold(conditions, makeIfExp, cond);
        (beqns, eqns) =  lowerIfEquationAsserts1(eqns, condition, conditions, brancheqns1, DAE.ASSERT(e, msg, level, source)::inEqns);
      then
        (beqns, eqns);
    case (DAE.ASSERT(condition=cond, message=msg, level=level, source=source)::eqns, SOME(e), _, _, _)
      equation
        e = DAE.IFEXP(e, cond, DAE.BCONST(true));
        e = List.fold(conditions, makeIfExp, e);
        (beqns, eqns) = lowerIfEquationAsserts1(eqns, condition, conditions, brancheqns1, DAE.ASSERT(e, msg, level, source)::inEqns);
      then
        (beqns, eqns);
    case (DAE.TERMINATE(message=msg, source=source)::eqns, NONE(), _, _, _)
      equation
        e = List.fold(conditions, makeIfExp, DAE.BCONST(true));
        (beqns, eqns) =  lowerIfEquationAsserts1(eqns, condition, conditions, brancheqns1, DAE.ALGORITHM(DAE.ALGORITHM_STMTS({DAE.STMT_IF(e, {DAE.STMT_TERMINATE(msg, source)}, DAE.NOELSE(), source)}), source)::inEqns);
      then
        (beqns, eqns);
    case (DAE.TERMINATE(message=msg, source=source)::eqns, SOME(e), _, _, _)
      equation
        e = List.fold(conditions, makeIfExp, e);
        (beqns, eqns) = lowerIfEquationAsserts1(eqns, condition, conditions, brancheqns1, DAE.ALGORITHM(DAE.ALGORITHM_STMTS({DAE.STMT_IF(e, {DAE.STMT_TERMINATE(msg, source)}, DAE.NOELSE(), source)}), source)::inEqns);
      then
        (beqns, eqns);
    case (DAE.NORETCALL(exp=exp, source=source)::eqns, NONE(), _, _, _)
      equation
        _ = List.fold(conditions, makeIfExp, DAE.BCONST(true));
        (beqns, eqns) = lowerIfEquationAsserts1(eqns, condition, conditions, brancheqns1, DAE.ALGORITHM(DAE.ALGORITHM_STMTS({DAE.STMT_IF(exp, {DAE.STMT_NORETCALL(exp, source)}, DAE.NOELSE(), source)}), source)::inEqns);
      then
        (beqns, eqns);
    case (DAE.NORETCALL(exp=exp, source=source)::eqns, SOME(e), _, _, _)
      equation
        e = List.fold(conditions, makeIfExp, e);
        (beqns, eqns) = lowerIfEquationAsserts1(eqns, condition, conditions, brancheqns1, DAE.ALGORITHM(DAE.ALGORITHM_STMTS({DAE.STMT_IF(e, {DAE.STMT_NORETCALL(exp, source)}, DAE.NOELSE(), source)}), source)::inEqns);
      then
        (beqns, eqns);
    case (eqn::eqns, _, _, _, _)
      equation
        (beqns, eqns) = lowerIfEquationAsserts1(eqns, condition, conditions, eqn::brancheqns1, inEqns);
      then
        (beqns, eqns);
  end match;
end lowerIfEquationAsserts1;

protected function makeIfExp
  input DAE.Exp cond;
  input DAE.Exp else_;
  output DAE.Exp oExp;
algorithm
  oExp := DAE.IFEXP(cond, DAE.BCONST(true), else_);
end makeIfExp;

protected function lowerExtendedRecordEqns "author: Frenkel TUD 2012-06"
  input list<DAE.Exp> explst1;
  input list<DAE.Exp> explst2;
  input DAE.ElementSource source;
  input BackendDAE.EquationKind inEqKind;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := match(explst1, explst2, source, inEqKind, functionTree, inEqns)
    local
      DAE.Exp e1, e2;
      list<DAE.Exp> elst1, elst2;
      list<BackendDAE.Equation> eqns;
    case({}, {}, _, _, _, _) then inEqns;
    case(e1::elst1, e2::elst2, _, _, _, _)
      equation
        eqns = lowerExtendedRecordEqn(e1, e2, source, inEqKind, functionTree, inEqns);
      then
        lowerExtendedRecordEqns(elst1, elst2, source, inEqKind, functionTree, eqns);
  end match;
end lowerExtendedRecordEqns;

protected function lowerExtendedRecordEqn "author: Frenkel TUD 2012-06"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource source;
  input BackendDAE.EquationKind inEqKind;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(inExp1, inExp2, source, inEqKind, functionTree, inEqns)
    local
      DAE.Type tp;
      Integer size;
      DAE.Dimensions dims;
      list<DAE.Exp> explst1, explst2;
      Boolean b1, b2, b3;
      DAE.Exp exp;

    // a, Record(), CAST(Record())
    case (_, _, _, _, _, _)
      equation
        explst1 = Expression.splitRecord(inExp1, Expression.typeof(inExp1));
        explst2 = Expression.splitRecord(inExp2, Expression.typeof(inExp2));
      then
        lowerExtendedRecordEqns(explst1, explst2, source, inEqKind, functionTree, inEqns);

    // complex types to complex equations
    case (_, _, _, _, _, _)
      equation
        tp = Expression.typeof(inExp1);
        true = DAEUtil.expTypeComplex(tp);
        size = Expression.sizeOf(tp);
      then
        BackendDAE.COMPLEX_EQUATION(size, inExp1, inExp2, source, false, inEqKind)::inEqns;

    // array types to array equations
    case (_, _, _, _, _, _)
      equation
        tp = Expression.typeof(inExp1);
        true = DAEUtil.expTypeArray(tp);
        dims = Expression.arrayDimension(tp);
      then
        lowerArrayEqn(dims, inExp1, inExp2, source, inEqKind, inEqns);

    // tuple types to complex equations
    case (_, _, _, _, _, _)
      equation
        tp = Expression.typeof(inExp1);
        true = Types.isTuple(tp);
        size = Expression.sizeOf(tp);
      then
        BackendDAE.COMPLEX_EQUATION(size, inExp1, inExp2, source, false, inEqKind)::inEqns;

    // other types
    case (_, _, _, _, _, _)
      equation
        tp = Expression.typeof(inExp1);
        b1 = DAEUtil.expTypeComplex(tp);
        b2 = DAEUtil.expTypeArray(tp);
        b3 = Types.isTuple(tp);
        false = b1 or b2 or b3;
        //Error.assertionOrAddSourceMessage(not b1, Error.INTERNAL_ERROR, {str}, Absyn.dummyInfo);
      then
        BackendDAE.EQUATION(inExp1, inExp2, source, false, inEqKind)::inEqns;
    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.lowerExtendedRecordEqn failed on: " +& ExpressionDump.printExpStr(inExp1) +& " = " +& ExpressionDump.printExpStr(inExp2) +& "\n");
      then
        fail();
  end matchcontinue;
end lowerExtendedRecordEqn;

protected function lowerArrayEqn "author: Frenkel TUD 2012-06"
  input DAE.Dimensions dims;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input DAE.ElementSource source;
  input BackendDAE.EquationKind inEqKind;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> outEqsLst;
algorithm
  outEqsLst := matchcontinue (dims, e1, e2, source, inEqKind, iAcc)
    local
      list<DAE.Exp> ea1, ea2;
      list<Integer> ds;

    case (_, _, _, _, _, _)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);
      then generateEquations(ea1, ea2, source, inEqKind, iAcc);

    case (_, _, _, _, _, _)
      equation
        ds = Expression.dimensionsSizes(dims);
      then BackendDAE.ARRAY_EQUATION(ds, e1, e2, source, false, inEqKind)::iAcc;
  end matchcontinue;
end lowerArrayEqn;

protected function generateEquations "author: Frenkel TUD 2012-06"
  input list<DAE.Exp> iE1lst;
  input list<DAE.Exp> iE2lst;
  input DAE.ElementSource source;
  input BackendDAE.EquationKind inEqKind;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oEqns;
algorithm
  oEqns := match(iE1lst, iE2lst, source, inEqKind, iAcc)
    local
      DAE.Exp e1, e2;
      list<DAE.Exp> e1lst, e2lst;
    case ({}, {}, _, _, _) then iAcc;
    case (e1::e1lst, e2::e2lst, _, _, _)
      then generateEquations(e1lst, e2lst, source, inEqKind, BackendDAE.EQUATION(e1, e2, source, false, inEqKind)::iAcc);
  end match;
end generateEquations;


protected function lowerWhenEqn
"This function lowers a when clause. The condition expresion is put in the
  BackendDAE.WhenClause list and the equations inside are put in the equation list.
  For each equation in the clause a new entry in the BackendDAE.WhenClause list is generated
  and one extra for all the reinit statements.
  inputs:  (DAE.Element, int /* when-clause index */, BackendDAE.WhenClause list)
  outputs: (Equation list, BackendDAE.Variables, int /* when-clause index */, BackendDAE.WhenClause list)"
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEquationLst;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  (outEquationLst, outWhenClauseLst):=
  matchcontinue (inElement, functionTree, inEquationLst, inWhenClauseLst)
    local
      list<BackendDAE.Equation> res;
      list<BackendDAE.Equation> trueEqnLst, elseEqnLst;
      list<BackendDAE.WhenOperator> reinit;
      list<BackendDAE.WhenClause> whenClauseList;
      DAE.Exp cond;
      list<DAE.Element> eqnl;
      DAE.Element elsePart;
      String  str;
      DAE.ElementSource source;

    case (DAE.WHEN_EQUATION(condition = cond, equations = eqnl, elsewhen_ = NONE(), source=source), _, _, _)
      equation
        (DAE.PARTIAL_EQUATION(cond), source) = Inline.simplifyAndInlineEquationExp(DAE.PARTIAL_EQUATION(cond), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (res, reinit) = lowerWhenEqn2(listReverse(eqnl), cond, functionTree, inEquationLst, {});
        whenClauseList = makeWhenClauses(List.isNotEmpty(reinit), cond, reinit, inWhenClauseLst);
      then
        (res, whenClauseList);

    case (DAE.WHEN_EQUATION(condition = cond, equations = eqnl, elsewhen_ = SOME(elsePart), source=source), _, _, _)
      equation
        (elseEqnLst, whenClauseList) = lowerWhenEqn(elsePart, functionTree, {}, inWhenClauseLst);
        (DAE.PARTIAL_EQUATION(cond), source) = Inline.simplifyAndInlineEquationExp(DAE.PARTIAL_EQUATION(cond), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (trueEqnLst, reinit) = lowerWhenEqn2(listReverse(eqnl), cond, functionTree, {}, {});
        whenClauseList = makeWhenClauses(List.isNotEmpty(reinit), cond, reinit, whenClauseList);
        res = mergeClauses(trueEqnLst, elseEqnLst, inEquationLst);
      then
        (res, whenClauseList);

    case (DAE.WHEN_EQUATION(condition = _, source = source), _, _, _)
      equation
        str = "BackendDAECreate.lowerWhenEqn: equation not handled:\n" +&
              DAEDump.dumpElementsStr({inElement});
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, DAEUtil.getElementSourceFileInfo(source));
      then
        fail();
  end matchcontinue;
end lowerWhenEqn;

protected function lowerWhenEqn2
"Helper function to lowerWhenEqn. Lowers the equations inside a when clause"
  input list<DAE.Element> inDAEElementLst "The List of equations inside a when clause";
  input DAE.Exp inCond;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> iEquationLst;
  input list<BackendDAE.WhenOperator> iReinitStatementLst;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.WhenOperator> outReinitStatementLst;
algorithm
  (outEquationLst, outReinitStatementLst):=
  matchcontinue (inDAEElementLst, inCond, functionTree, iEquationLst, iReinitStatementLst)
    local
      Integer size;
      list<BackendDAE.Equation> eqnl;
      list<BackendDAE.WhenOperator> reinit;
      DAE.Exp cre, e, cond, level;
      DAE.ComponentRef cr, cr2;
      list<DAE.Element> xs, eqns;
      DAE.Element el;
      DAE.ElementSource source;
      DAE.Dimensions ds;
      list<DAE.Exp> expl;
      list<list<DAE.Element>> eqnslst;
      Absyn.Path functionName;
      HashTableCrToExpSourceTpl.HashTable ht;
      list<tuple<DAE.ComponentRef, tuple<DAE.Exp, DAE.ElementSource>>> crexplst;
      list<DAE.Statement> assrtLst;

    case ({}, _, _, _, _) then (iEquationLst, iReinitStatementLst);
    case (DAE.EQUEQUATION(cr1 = cr, cr2 = cr2, source = source)::xs, _, _, _, _)
      equation
        e = Expression.crefExp(cr2);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, BackendDAE.WHEN_EQUATION(1, BackendDAE.WHEN_EQ(inCond, cr, e, NONE()), source, BackendDAE.DYNAMIC_EQUATION())::iEquationLst, iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.DEFINE(componentRef = cr, exp = e, source = source)::xs, _, _, _, _)
      equation
        (DAE.PARTIAL_EQUATION(e), source) = Inline.simplifyAndInlineEquationExp(DAE.PARTIAL_EQUATION(e), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, BackendDAE.WHEN_EQUATION(1, BackendDAE.WHEN_EQ(inCond, cr, e, NONE()), source, BackendDAE.DYNAMIC_EQUATION())::iEquationLst, iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.EQUATION(exp = cre as DAE.TUPLE(PR=expl), scalar = e, source = source)::xs, _, _, _, _)
      equation
        (DAE.EQUALITY_EXPS(_,e), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(cre,e), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        eqnl = lowerWhenTupleEqn(expl, inCond, e, source, 1, iEquationLst);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.EQUATION(exp = (cre as DAE.CREF(componentRef = cr)), scalar = e, source = source)::xs, _, _, _, _)
      equation
        (DAE.EQUALITY_EXPS(_,e), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(cre,e), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, BackendDAE.WHEN_EQUATION(1, BackendDAE.WHEN_EQ(inCond, cr, e, NONE()), source, BackendDAE.DYNAMIC_EQUATION())::iEquationLst, iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.COMPLEX_EQUATION(lhs = (cre as DAE.CREF(componentRef = cr)), rhs = e, source = source)::xs, _, _, _, _)
      equation
        size = Expression.sizeOf(Expression.typeof(cre));
        (DAE.EQUALITY_EXPS(_,e), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(cre,e), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(inCond, cr, e, NONE()), source, BackendDAE.DYNAMIC_EQUATION())::iEquationLst, iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.COMPLEX_EQUATION(lhs = cre as DAE.TUPLE(PR=expl), rhs = e, source = source)::xs, _, _, _, _)
      equation
        (DAE.EQUALITY_EXPS(_,e), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(cre,e), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        eqnl = lowerWhenTupleEqn(expl, inCond, e, source, 1, iEquationLst);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iReinitStatementLst);
      then
        (eqnl, reinit);

    case ((DAE.IF_EQUATION(condition1=expl, equations2=eqnslst, equations3=eqns, source = source))::xs, _, _, _, _)
      equation
        (expl, source, _) = Inline.inlineExps(expl, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        // transform if eqution
        // if .. then a=.. elseif .. then a=... else a=.. end if;
        // to
        // a=if .. then .. else if .. then else ..;
        ht = HashTableCrToExpSourceTpl.emptyHashTable();
        ht = lowerWhenIfEqnsElse(eqns, functionTree, ht);
        ht = lowerWhenIfEqns(listReverse(expl), listReverse(eqnslst), functionTree, ht);
        crexplst = BaseHashTable.hashTableList(ht);
        eqnl = lowerWhenIfEqns2(crexplst, inCond, source, iEquationLst);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.ARRAY_EQUATION(dimension=ds, exp = (cre as DAE.CREF(componentRef = cr)), array = e, source = source)::xs, _, _, _, _)
      equation
        size = List.fold(Expression.dimensionsSizes(ds), intMul, 1);
        (DAE.EQUALITY_EXPS(_,e), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(cre,e), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(inCond, cr, e, NONE()), source, BackendDAE.DYNAMIC_EQUATION())::iEquationLst, iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.ARRAY_EQUATION(exp = cre as DAE.TUPLE(PR=expl), array = e, source = source)::xs, _, _, _, _)
      equation
        (DAE.EQUALITY_EXPS(_,e), source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(cre,e), (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        eqnl = lowerWhenTupleEqn(expl, inCond, e, source, 1, iEquationLst);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.ASSERT(condition=cond, message = e, level = level, source = source)::xs, _, _, _, _)
      equation
        (cond, source, _,_) = Inline.inlineExp(cond, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, BackendDAE.ASSERT(cond, e, level, source)::iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.REINIT(componentRef = cr, exp = e, source = source)::xs, _, _, _, _)
      equation
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, BackendDAE.REINIT(cr, e, source)::iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.TERMINATE(message = e, source = source)::xs, _, _, _, _)
      equation
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, BackendDAE.TERMINATE(e, source)::iReinitStatementLst);
      then
        (eqnl, reinit);

    case (DAE.NORETCALL(exp=e, source=source)::xs, _, _, _, _)
      equation
        (e, source, _, _) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, BackendDAE.NORETCALL(e, source)::iReinitStatementLst);
      then
        (eqnl, reinit);

    // failure
    case (el::_, _, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.lowerWhenEqn2 failed on:" +& DAEDump.dumpElementsStr({el}));
      then
        fail();

    // adrpo: 2010-09-26
    // allow to continue when checking the model
    // just ignore this equation.
    case (_::xs, _, _, _, _)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        (eqnl, reinit) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, iReinitStatementLst);
      then
        (eqnl, reinit);
  end matchcontinue;
end lowerWhenEqn2;

protected function lowerWhenTupleEqn
  input list<DAE.Exp> explst;
  input DAE.Exp inCond;
  input DAE.Exp e;
  input DAE.ElementSource source;
  input Integer i;
  input list<BackendDAE.Equation> iEquationLst;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := match(explst, inCond, e, source, i, iEquationLst)
    local
      DAE.ComponentRef cr;
      list<DAE.Exp> rest;
      Integer size;
      DAE.Type ty;
    case ({}, _, _, _, _, _) then iEquationLst;
    case (DAE.CREF(componentRef = cr, ty=ty)::rest, _, _, _, _, _)
      equation
        size = Expression.sizeOf(ty);
      then
        lowerWhenTupleEqn(rest, inCond, e, source, i+1, BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(inCond, cr, DAE.TSUB(e, i, ty), NONE()), source, BackendDAE.DYNAMIC_EQUATION()) ::iEquationLst);
  end match;
end lowerWhenTupleEqn;

protected function lowerWhenIfEqns2
"author: Frenkel TUD 2012-11
  helper for lowerWhen"
  input list<tuple<DAE.ComponentRef, tuple<DAE.Exp, DAE.ElementSource>>> crexplst;
  input DAE.Exp inCond;
  input DAE.ElementSource iSource;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := match(crexplst, inCond, iSource, inEqns)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      DAE.ElementSource source;
      list<tuple<DAE.ComponentRef, tuple<DAE.Exp, DAE.ElementSource>>> rest;
      Integer size;
    case ({}, _, _, _)
      then
        inEqns;
    case ((cr, (e, source))::rest, _, _, _)
      equation
        source = DAEUtil.mergeSources(iSource, source);
        size = Expression.sizeOf(Expression.typeof(e));
      then
       lowerWhenIfEqns2(rest, inCond, iSource, BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(inCond, cr, e, NONE()), source, BackendDAE.DYNAMIC_EQUATION())::inEqns);
  end match;
end lowerWhenIfEqns2;

protected function lowerWhenIfEqns
"author: Frenkel TUD 2012-11
  helper for lowerWhen"
  input list<DAE.Exp> conditions;
  input list<list<DAE.Element>> theneqns;
  input DAE.FunctionTree functionTree;
  input HashTableCrToExpSourceTpl.HashTable iHt;
  output HashTableCrToExpSourceTpl.HashTable oHt;
algorithm
  oHt := match(conditions, theneqns, functionTree, iHt)
    local
      HashTableCrToExpSourceTpl.HashTable ht;
      DAE.Exp c;
      list<DAE.Exp> explst;
      list<DAE.Element> eqns;
      list<list<DAE.Element>> rest;
    case ({}, {}, _, _)
      then
        iHt;
    case (c::explst, eqns::rest, _, _)
      equation
        ht = lowerWhenIfEqns1(c, eqns, functionTree, iHt);
      then
        lowerWhenIfEqns(explst, rest, functionTree, ht);
  end match;
end lowerWhenIfEqns;

protected function lowerWhenIfEqns1
"author: Frenkel TUD 2012-11
  helper for lowerWhenIfEqns"
  input DAE.Exp condition;
  input list<DAE.Element> brancheqns;
  input DAE.FunctionTree functionTree;
  input HashTableCrToExpSourceTpl.HashTable iHt;
  output HashTableCrToExpSourceTpl.HashTable oHt;
algorithm
  oHt := match(condition, brancheqns, functionTree, iHt)
    local
      DAE.ComponentRef cr, cr2;
      DAE.Exp e, exp;
      DAE.ElementSource source, source1;
      HashTableCrToExpSourceTpl.HashTable ht;
      list<DAE.Element> rest, eqns;
      list<list<DAE.Element>> eqnslst;
      list<DAE.Exp> expl;
      list<tuple<DAE.ComponentRef, tuple<DAE.Exp, DAE.ElementSource>>> crexplst;
      list<DAE.Statement> assrtLst;
    case (_, {}, _, _)
      then
        iHt;
    case (_, DAE.EQUEQUATION(cr1=cr, cr2=cr2, source=source)::rest, _, _)
      equation
        e = Expression.crefExp(cr2);
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = DAEUtil.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.DEFINE(componentRef=cr, exp=e, source=source)::rest, _, _)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = DAEUtil.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e, source=source)::rest, _, _)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = DAEUtil.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.COMPLEX_EQUATION(lhs=DAE.CREF(componentRef=cr), rhs=e, source=source)::rest, _, _)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = DAEUtil.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.ARRAY_EQUATION(exp=DAE.CREF(componentRef=cr), array=e, source=source)::rest, _, _)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = DAEUtil.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.IF_EQUATION(condition1=expl, equations2=eqnslst, equations3=eqns, source = source)::rest, _, _)
      equation
        (expl, source, _) = Inline.inlineExps(expl, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ht = HashTableCrToExpSourceTpl.emptyHashTable();
        ht = lowerWhenIfEqnsElse(eqns, functionTree, ht);
        ht = lowerWhenIfEqns(listReverse(expl), listReverse(eqnslst), functionTree, ht);
        crexplst = BaseHashTable.hashTableList(ht);
        ht = lowerWhenIfEqnsMergeNestedIf(crexplst, condition, source, iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
  end match;
end lowerWhenIfEqns1;

protected function lowerWhenIfEqnsMergeNestedIf
"author: Frenkel TUD 2012-11
  helper for lowerWhenIfEqns"
  input list<tuple<DAE.ComponentRef, tuple<DAE.Exp, DAE.ElementSource>>> crexplst;
  input DAE.Exp inCond;
  input DAE.ElementSource iSource;
  input HashTableCrToExpSourceTpl.HashTable iHt;
  output HashTableCrToExpSourceTpl.HashTable oHt;
algorithm
  oHt := match(crexplst, inCond, iSource, iHt)
    local
      DAE.ComponentRef cr;
      DAE.Exp e, exp;
      DAE.ElementSource source, source1;
      list<tuple<DAE.ComponentRef, tuple<DAE.Exp, DAE.ElementSource>>> rest;
      HashTableCrToExpSourceTpl.HashTable ht;
    case ({}, _, _, _)
      then
        iHt;
    case ((cr, (e, source))::rest, _, _, _)
      equation
        ((exp, _)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(inCond, e, exp);
        source = DAEUtil.mergeSources(iSource, source);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
       lowerWhenIfEqnsMergeNestedIf(rest, inCond, iSource, ht);
  end match;
end lowerWhenIfEqnsMergeNestedIf;

protected function lowerWhenIfEqnsElse
"author: Frenkel TUD 2012-11
  helper for lowerWhenIfEqns"
  input list<DAE.Element> elseenqs;
  input DAE.FunctionTree functionTree;
  input HashTableCrToExpSourceTpl.HashTable iHt;
  output HashTableCrToExpSourceTpl.HashTable oHt;
algorithm
  oHt := match(elseenqs, functionTree, iHt)
    local
      DAE.ComponentRef cr, cr2;
      DAE.Exp e;
      DAE.ElementSource source;
      HashTableCrToExpSourceTpl.HashTable ht;
      list<DAE.Element> rest, eqns;
      list<list<DAE.Element>> eqnslst;
      list<DAE.Exp> expl;
      list<DAE.Statement> assrtLst;
    case ({}, _, _)
      then
        iHt;
    case (DAE.EQUEQUATION(cr1=cr, cr2=cr2, source=source)::rest, _, _)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        e = Expression.crefExp(cr2);
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.DEFINE(componentRef=cr, exp=e, source=source)::rest, _, _)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e, source=source)::rest, _, _)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.COMPLEX_EQUATION(lhs=DAE.CREF(componentRef=cr), rhs=e, source=source)::rest, _, _)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.ARRAY_EQUATION(exp=DAE.CREF(componentRef=cr), array=e, source=source)::rest, _, _)
      equation
        failure( _ = BaseHashTable.get(cr, iHt));
        false = Expression.expHasCrefNoPreorDer(e, cr);
        (e, source, _,_) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.IF_EQUATION(condition1=expl, equations2=eqnslst, equations3=eqns, source = source)::rest, _, _)
      equation
        (expl, source, _) = Inline.inlineExps(expl, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        ht = lowerWhenIfEqnsElse(eqns, functionTree, iHt);
        ht = lowerWhenIfEqns(listReverse(expl), listReverse(eqnslst), functionTree, ht);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
  end match;
end lowerWhenIfEqnsElse;

protected function makeWhenClauses
"Constructs a list of identical BackendDAE.WhenClause elements
  Arg1: Number of elements to construct
  Arg2: condition expression of the when clause
  outputs: (WhenClause list)"
  input Boolean do;
  input DAE.Exp inCondition "the condition expression";
  input list<BackendDAE.WhenOperator> inReinitStatementLst;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  outWhenClauseLst:=
  match (do, inCondition, inReinitStatementLst, inWhenClauseLst)
    case (false, _, _, _) then inWhenClauseLst;
    case (true, _, _, _)
      then
        (BackendDAE.WHEN_CLAUSE(inCondition, inReinitStatementLst, NONE())::inWhenClauseLst);
  end match;
end makeWhenClauses;

protected function mergeClauses
" merges the true part end the elsewhen part of a set of when equations.
   For each equation in trueEqnList, find an equation in elseEqnList solving
   the same variable and put it in the else elseWhenPart of the first equation."
  input list<BackendDAE.Equation> trueEqnList "List of equations in the true part of the when clause.";
  input list<BackendDAE.Equation> elseEqnList "List of equations in the elsewhen part of the when clause.";
  input list<BackendDAE.Equation> inEquationLst;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (trueEqnList, elseEqnList, inEquationLst)
    local
      DAE.ComponentRef cr;
      DAE.Exp rightSide, cond;
      BackendDAE.Equation res;
      list<BackendDAE.Equation> trueEqns, elseEqnsRest;
      BackendDAE.WhenEquation foundEquation;
      DAE.ElementSource source;
      Integer size;
      BackendDAE.EquationKind eqKind;

    case (BackendDAE.WHEN_EQUATION(size=size, whenEquation=BackendDAE.WHEN_EQ(condition=cond, left=cr, right=rightSide), source=source, kind=eqKind)::trueEqns, _, _) equation
      (foundEquation, elseEqnsRest) = getWhenEquationFromVariable(cr, elseEqnList);
      res = BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(cond, cr, rightSide, SOME(foundEquation)), source, eqKind);
    then mergeClauses(trueEqns, elseEqnsRest, res::inEquationLst);

    case (BackendDAE.WHEN_EQUATION(size=size, whenEquation=BackendDAE.WHEN_EQ(condition=cond, left = cr, right=rightSide), source=source, kind=eqKind)::trueEqns, _, _) equation
      (foundEquation, elseEqnsRest) = getWhenEquationFromVariable(cr, elseEqnList);
      res = BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_EQ(cond, cr, rightSide, SOME(foundEquation)), source, eqKind);
    then mergeClauses(trueEqns, elseEqnsRest, res::inEquationLst);

    case ({}, {}, _)
    then inEquationLst;

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAECreate.mergeClauses: Error in mergeClauses."});
    then fail();
  end matchcontinue;
end mergeClauses;

protected function getWhenEquationFromVariable
"Finds the when equation solving the variable given by inCr among equations in inEquations
 the found equation is then taken out of the list."
  input DAE.ComponentRef inCr;
  input list<BackendDAE.Equation> inEquations;
  output BackendDAE.WhenEquation outEquation;
  output list<BackendDAE.Equation> outEquations;
algorithm
  (outEquation, outEquations) := match(inCr, inEquations)
    local
      DAE.ComponentRef cr1, cr2;
      BackendDAE.WhenEquation eq;
      list<BackendDAE.Equation> rest;

    case (cr1, BackendDAE.WHEN_EQUATION(whenEquation=eq as BackendDAE.WHEN_EQ(left=cr2))::rest)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr1, cr2);
      then (eq, rest);

    case (_, {})
      equation
        Error.addMessage(Error.DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN, {});
      then
        fail();
  end match;
end getWhenEquationFromVariable;


protected function lowerTupleAssignment
  "Used by lower2 to split a tuple-tuple assignment into one equation for each
  tuple-element"
  input list<DAE.Exp> target_expl;
  input list<DAE.Exp> source_expl;
  input DAE.ElementSource inEq_source;
  input DAE.FunctionTree funcs;
  input list<BackendDAE.Equation> iEqns;
  output list<BackendDAE.Equation> oEqns;
algorithm
  oEqns := match(target_expl, source_expl, inEq_source, funcs, iEqns)
    local
      DAE.Exp target, source;
      list<DAE.Exp> rest_targets, rest_sources;
      list<BackendDAE.Equation> eqns;
      DAE.ElementSource eq_source;
    case ({}, {}, _, _, _) then iEqns;
    // skip CREF(WILD())
    case (DAE.CREF(componentRef = DAE.WILD())::rest_targets, _::rest_sources, _, _, _)
      then
        lowerTupleAssignment(rest_targets, rest_sources, inEq_source, funcs, iEqns);
    // case for complex equations, array equations and equations
    case (target::rest_targets, source::rest_sources, _, _, _)
      equation
        (DAE.EQUALITY_EXPS(target,source), eq_source) = Inline.simplifyAndInlineEquationExp(DAE.EQUALITY_EXPS(target,source), (SOME(funcs), {DAE.NORM_INLINE()}), inEq_source);
        eqns = lowerExtendedRecordEqn(target, source, eq_source, BackendDAE.UNKNOWN_EQUATION_KIND(), funcs, iEqns);
      then
        lowerTupleAssignment(rest_targets, rest_sources, inEq_source, funcs, eqns);
  end match;
end lowerTupleAssignment;

/*
 *   lower algorithms
 */

protected function lowerAlgorithm
"Helper function to lower2.
  Transforms a DAE.Element to BackEnd.ALGORITHM.
NOTE: inCrefExpansionStrategy is needed if we translate equations to algorithms as
      we should not expand array crefs to full dimensions in that case because that
      is wrong. Expansion of array crefs to full dimensions SHOULD HAPPEN ONLY IN REAL FULL ALGORITHMS!"
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Equation> inREquations;
  input list<BackendDAE.Equation> inIEquations;
  input DAE.Expand inCrefExpansion "this is needed if we translate equations to algorithms as we should not expand array crefs to full dimensions in that case";
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outREquations;
  output list<BackendDAE.Equation> outIEquations;
algorithm
  (outEquations, outREquations, outIEquations) :=  matchcontinue (inElement, functionTree, inEquations, inREquations, inIEquations, inCrefExpansion)
    local
      DAE.Exp cond, msg, level,e;
      DAE.Algorithm alg;
      DAE.ElementSource source;
      Integer size;
      Boolean b1, b2;
      Absyn.Path functionName;
      list<DAE.Exp> functionArgs;
      list<DAE.ComponentRef> crefLst;
      String str;
      Absyn.Info info;
      list<BackendDAE.Equation> eqns, reqns;
      list<DAE.Statement> assrtLst;

    case (DAE.ALGORITHM(algorithm_=alg, source=source), _, _, _, _, _)
      equation
        // calculate the size of the algorithm by collecting the left hand sites of the statemens
        (alg, _) = Inline.inlineAlgorithm(alg, (SOME(functionTree), {DAE.NORM_INLINE()}));
        crefLst = CheckModel.algorithmOutputs(alg, inCrefExpansion);
        size = listLength(crefLst);
        (eqns, reqns) = List.consOnBool(intGt(size, 0), BackendDAE.ALGORITHM(size, alg, source, inCrefExpansion, BackendDAE.DYNAMIC_EQUATION()), inEquations, inREquations);
      then (eqns, reqns, inIEquations);

    case (DAE.INITIALALGORITHM(algorithm_=alg, source=source), _, _, _, _, _)
      equation
        // calculate the size of the algorithm by collecting the left hand sites of the statemens
        (alg, _) = Inline.inlineAlgorithm(alg, (SOME(functionTree), {DAE.NORM_INLINE()}));
        crefLst = CheckModel.algorithmOutputs(alg, inCrefExpansion);
        size = listLength(crefLst);
      then (inEquations, inREquations, BackendDAE.ALGORITHM(size, alg, source, inCrefExpansion, BackendDAE.INITIAL_EQUATION())::inIEquations);

    // skipp asserts with condition=true
    case (DAE.ASSERT(condition=DAE.BCONST(true)), _, _, _, _, _)
      then (inEquations, inREquations, inIEquations);

    case (DAE.ASSERT(condition=cond, message=msg, level=level, source=source), _, _, _, _, _)
      equation
        (cond, source, _,_) = Inline.inlineExp(cond, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (msg, source, _,_) = Inline.inlineExp(msg, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        (level, source, _,_) = Inline.inlineExp(level, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        BackendDAEUtil.checkAssertCondition(cond, msg, level, DAEUtil.getElementSourceFileInfo(source));
        alg = DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond, msg, level, source)});
      then (inEquations, BackendDAE.ALGORITHM(0, alg, source, inCrefExpansion, BackendDAE.DYNAMIC_EQUATION())::inREquations, inIEquations);

    case (DAE.TERMINATE(message=msg, source=source), _, _, _, _, _)
      then (inEquations, BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg, source)}), source, inCrefExpansion, BackendDAE.DYNAMIC_EQUATION())::inREquations, inIEquations);

    case (DAE.NORETCALL(exp=e, source=source), _, _, _, _, _)
      equation
        (e, source, _, _) = Inline.inlineExp(e, (SOME(functionTree), {DAE.NORM_INLINE()}), source);
        alg = DAE.ALGORITHM_STMTS({DAE.STMT_NORETCALL(e, source)});
      then (inEquations, BackendDAE.ALGORITHM(0, alg, source, inCrefExpansion, BackendDAE.DYNAMIC_EQUATION())::inREquations, inIEquations);

    case (_, _, _, _, _, _)
      equation
        // only report error if no other error is in the queue!
        0 = Error.getNumErrorMessages();
        str = "BackendDAECreate.lowerAlgorithm failed for:\n" +& DAEDump.dumpElementsStr({inElement});
        Error.addSourceMessage(
          Error.INTERNAL_ERROR,
          {str},
          DAEUtil.getElementSourceFileInfo(DAEUtil.getElementSource(inElement)));
      then fail();

  end matchcontinue;
end lowerAlgorithm;

/*
 *  alias Equations
 */

protected function handleAliasEquations
"author Frenkel TUD 2012-09"
  input list<DAE.Element> iAliasEqns;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input list<BackendDAE.Equation> iEqns;
  input list<BackendDAE.Equation> iREqns;
  input list<BackendDAE.Equation> iIEqns;
  input list<BackendDAE.WhenClause> iWhenclauses;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables oKnVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output list<BackendDAE.Equation> oEqns;
  output list<BackendDAE.Equation> oREqns;
  output list<BackendDAE.Equation> oIEqns;
  output list<BackendDAE.WhenClause> oWhenclauses;
algorithm
  (oVars, oKnVars, oExtVars, oAVars, oEqns, oREqns, oIEqns, oWhenclauses) :=
  match (iAliasEqns, iVars, iKnVars, iExtVars, iAVars, iEqns, iREqns, iIEqns, iWhenclauses)
    local
      BackendDAE.Variables vars, knvars, extvars, avars;
      list<BackendDAE.Equation> eqns, reqns, ieqns;
      list<BackendDAE.WhenClause> whenclauses;
    case ({}, _, _, _, _, _, _, _, _) then (iVars, iKnVars, iExtVars, iAVars, iEqns, iREqns, iIEqns, iWhenclauses);
    case (_, _, _, _, _, _, _, _, _)
      equation
        (vars, knvars, extvars, avars, eqns, reqns, ieqns, whenclauses) = handleAliasEquations1(iAliasEqns, iVars, iKnVars, iExtVars, iAVars, iEqns, iREqns, iIEqns, iWhenclauses);
      then
        (vars, knvars, extvars, avars, eqns, reqns, ieqns, whenclauses);
  end match;
end handleAliasEquations;

protected function handleAliasEquations1
"author Frenkel TUD 2012-09"
  input list<DAE.Element> iAliasEqns;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input list<BackendDAE.Equation> iEqns;
  input list<BackendDAE.Equation> iREqns;
  input list<BackendDAE.Equation> iIEqns;
  input list<BackendDAE.WhenClause> iWhenclauses;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables oKnVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output list<BackendDAE.Equation> oEqns;
  output list<BackendDAE.Equation> oREqns;
  output list<BackendDAE.Equation> oIEqns;
  output list<BackendDAE.WhenClause> oWhenclauses;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  // get alias vars and replacements
  (oVars, oKnVars, oExtVars, oAVars, repl, oEqns) := handleAliasEquations2(iAliasEqns, iVars, iKnVars, iExtVars, iAVars, repl, iEqns);
  // replace alias bindings
  (oAVars, _) := BackendVariable.traverseBackendDAEVarsWithUpdate(oAVars, replaceAliasVarTraverser, repl);
  // compress vars array
  oVars := BackendVariable.compressVariables(oVars);
  // perform replacements
  (oEqns, _) := BackendVarTransform.replaceEquations(oEqns, repl, NONE());
  (oREqns, _) := BackendVarTransform.replaceEquations(iREqns, repl, NONE());
  (oIEqns, _) := BackendVarTransform.replaceEquations(iIEqns, repl, NONE());
  (oWhenclauses, _) := BackendVarTransform.replaceWhenClauses(iWhenclauses, repl, NONE());
end handleAliasEquations1;

protected function replaceAliasVarTraverser
"author: Frenkel TUD 2011-03"
 input tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> inTpl;
 output tuple<BackendDAE.Var, BackendVarTransform.VariableReplacements> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v, v1;
      BackendVarTransform.VariableReplacements repl;
      DAE.Exp e, e1;
      Boolean b;
    case ((v as BackendDAE.VAR(bindExp=SOME(e)), repl))
      equation
        (e1, true) = BackendVarTransform.replaceExp(e, repl, NONE());
        b = Expression.isConst(e1);
        v1 = Debug.bcallret2(not b, BackendVariable.setBindExp, v, SOME(e1), v);
      then ((v1, repl));
    else inTpl;
  end matchcontinue;
end replaceAliasVarTraverser;

protected function handleAliasEquations2
"author Frenkel TUD 2012-09"
  input list<DAE.Element> iAliasEqns;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input BackendVarTransform.VariableReplacements iRepl;
  input list<BackendDAE.Equation> iEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables oKnVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output list<BackendDAE.Equation> oEqns;
algorithm
  (oVars, oKnVars, oExtVars, oAVars, oRepl, oEqns) := match (iAliasEqns, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns)
    local
      BackendDAE.Variables vars, knvars, extvars, avars;
      list<DAE.Element> aliaseqns;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource source;
      list<BackendDAE.Equation> eqns;
      DAE.Exp ecr1, ecr2;
    case ({}, _, _, _, _, _, _) then (iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
    case (DAE.EQUEQUATION(cr1=cr1, cr2=cr2, source=source)::aliaseqns, _, _, _, _, _, _)
      equation
        // perform replacements
        ecr1 = Expression.crefExp(cr1);
        (ecr1, _) = BackendVarTransform.replaceExp(ecr1, iRepl, NONE());
        ecr2 = Expression.crefExp(cr2);
        (ecr2, _) = BackendVarTransform.replaceExp(ecr2, iRepl, NONE());
        // select alias
        (vars, knvars, extvars, avars, repl, eqns) = selectAlias(ecr1, ecr2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
        // next
        (vars, knvars, extvars, avars, repl, eqns) = handleAliasEquations2(aliaseqns, vars, knvars, extvars, avars, repl, eqns);
      then
        (vars, knvars, extvars, avars, repl, eqns);
  end match;
end handleAliasEquations2;

protected function selectAlias
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input DAE.ElementSource source;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input BackendVarTransform.VariableReplacements iRepl;
  input list<BackendDAE.Equation> iEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables oKnVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output list<BackendDAE.Equation> oEqns;
algorithm
  (oVars, oKnVars, oExtVars, oAVars, oRepl, oEqns) := matchcontinue (exp1, exp2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns)
    local
      BackendDAE.Variables vars, knvars, extvars, avars;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Equation> eqns;
      DAE.ComponentRef cr1, cr2;
      list<DAE.Exp> explst1, explst2;
      list<list<DAE.Exp>> explstlst1, explstlst2;
      list<DAE.ComponentRef> crefs1, crefs2;
      DAE.Dimensions dims1, dims2;
      Integer arrayTyp1, arrayTyp2, i1, i2;
      BackendDAE.Var v1, v2;
    // array array case
    case (DAE.ARRAY(array=explst1), DAE.ARRAY(array=explst2), _, _, _, _, _, _, _)
      equation
        (vars, knvars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, knvars, extvars, avars, repl, eqns);
    // cref-array array case
    case (DAE.CREF(componentRef=cr1, ty=DAE.T_ARRAY(dims = dims1)), DAE.ARRAY(array=explst2), _, _, _, _, _, _, _)
      equation
        crefs1 = ComponentReference.expandArrayCref(cr1, dims1);
        explst1 = List.map(crefs1, Expression.crefExp);
        (vars, knvars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, knvars, extvars, avars, repl, eqns);
    // array cref-array case
    case (DAE.ARRAY(array=explst1), DAE.CREF(componentRef=cr2, ty=DAE.T_ARRAY(dims = dims2)), _, _, _, _, _, _, _)
      equation
        crefs2 = ComponentReference.expandArrayCref(cr2, dims2);
        explst2 = List.map(crefs2, Expression.crefExp);
        (vars, knvars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, knvars, extvars, avars, repl, eqns);
    // cref-array cref-array case
    case (DAE.CREF(componentRef=cr1, ty=DAE.T_ARRAY(dims = dims1)), DAE.CREF(componentRef=cr2, ty=DAE.T_ARRAY(dims = dims2)), _, _, _, _, _, _, _)
      equation
        crefs1 = ComponentReference.expandArrayCref(cr1, dims1);
        explst1 = List.map(crefs1, Expression.crefExp);
        crefs2 = ComponentReference.expandArrayCref(cr2, dims2);
        explst2 = List.map(crefs2, Expression.crefExp);
        (vars, knvars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, knvars, extvars, avars, repl, eqns);

    // matrix matrix case
    case (DAE.MATRIX(matrix=explstlst1), DAE.MATRIX(matrix=explstlst2), _, _, _, _, _, _, _)
      equation
        (vars, knvars, extvars, avars, repl, eqns) = selectAliasLst(List.flatten(explstlst1), List.flatten(explstlst2), source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, knvars, extvars, avars, repl, eqns);
    // scalar case
    case (DAE.CREF(componentRef=cr1),
          DAE.CREF(componentRef=cr2), _, _, _, _, _, _, _)
      equation
        (v1, i1, arrayTyp1) = getVar(cr1, iVars, iKnVars, iExtVars);
        (v2, i2, arrayTyp2) = getVar(cr2, iVars, iKnVars, iExtVars);
        (vars, knvars, extvars, avars, repl) = selectAliasVar(v1, i1, arrayTyp1, exp1, v2, i2, arrayTyp2, exp2, source, iVars, iKnVars, iExtVars, iAVars, iRepl);
      then
        (vars, knvars, extvars, avars, repl, iEqns);
    // complex
    case (_, _, _, _, _, _, _, _, _)
      equation
        // Create a list of crefs from names
        explst1 = Expression.splitRecord(exp1, Expression.typeof(exp1));
        explst2 = Expression.splitRecord(exp2, Expression.typeof(exp2));
        (vars, knvars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, knvars, extvars, avars, repl, eqns);
    // if no alias selectable add as equation
    case (_, _, _, _, _, _, _, _, _)
      then (iVars, iKnVars, iExtVars, iAVars, iRepl, BackendDAE.EQUATION(exp1, exp2, source, false, BackendDAE.DYNAMIC_EQUATION())::iEqns);
  end matchcontinue;
end selectAlias;

protected function getVar
  input DAE.ComponentRef cr;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.Variables iExtVars;
  output BackendDAE.Var oVar;
  output Integer index;
  output Integer varrArray;
algorithm
  (oVar, index, varrArray) := matchcontinue(cr, iVars, iKnVars, iExtVars)
    local
      BackendDAE.Var v;
      Integer i;
    case(_, _, _, _)
      equation
        (v::{}, i::{}) = BackendVariable.getVar(cr, iVars);
      then
        (v, i, 1);
    case(_, _, _, _)
      equation
        (v::{}, i::{}) = BackendVariable.getVar(cr, iKnVars);
      then
        (v, i, 2);
    case(_, _, _, _)
      equation
        (v::{}, i::{}) = BackendVariable.getVar(cr, iExtVars);
      then
        (v, i, 3);
  end matchcontinue;
end getVar;

protected function selectAliasLst
  input list<DAE.Exp> iexplst1;
  input list<DAE.Exp> iexplst2;
  input DAE.ElementSource source;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input BackendVarTransform.VariableReplacements iRepl;
  input list<BackendDAE.Equation> iEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables oKnVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output list<BackendDAE.Equation> oEqns;
algorithm
  (oVars, oKnVars, oExtVars, oAVars, oRepl, oEqns) := match (iexplst1, iexplst2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns)
    local
      BackendDAE.Variables vars, knvars, extvars, avars;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Equation> eqns;
      DAE.Exp e1, e2;
      list<DAE.Exp> explst1, explst2;
    case ({}, {}, _, _, _, _, _, _, _)
      then
        (iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
    case (e1::explst1, e2::explst2, _, _, _, _, _, _, _)
      equation
        // perform replacements
        (e1, _) = BackendVarTransform.replaceExp(e1, iRepl, NONE());
        (e2, _) = BackendVarTransform.replaceExp(e2, iRepl, NONE());
        // select alias
        (vars, knvars, extvars, avars, repl, eqns) = selectAlias(e1, e2, source, iVars, iKnVars, iExtVars, iAVars, iRepl, iEqns);
        // next
        (vars, knvars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, vars, knvars, extvars, avars, repl, eqns);
      then
        (vars, knvars, extvars, avars, repl, eqns);
  end match;
end selectAliasLst;

protected function selectAliasVar
  input BackendDAE.Var v1;
  input Integer index1;
  input Integer arrayIndx1;
  input DAE.Exp e1;
  input BackendDAE.Var v2;
  input Integer index2;
  input Integer arrayIndx2;
  input DAE.Exp e2;
  input DAE.ElementSource source;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables iKnVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables oKnVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (oVars, oKnVars, oExtVars, oAVars, oRepl) :=
   match (v1, index1, arrayIndx1, e1, v2, index2, arrayIndx2, e2, source, iVars, iKnVars, iExtVars, iAVars, iRepl)
    local
      BackendDAE.Variables vars, knvars, extvars, avars;
      BackendVarTransform.VariableReplacements repl;
      list<DAE.SymbolicOperation> ops;
      BackendDAE.Var var, avar;
      DAE.ComponentRef cr1, cr2, acr, cr;
      Integer w1, w2, aindx;
      Boolean b, b1, b2;
      DAE.Exp e, ae;
    // state variable
    case (BackendDAE.VAR(varKind=BackendDAE.STATE(index=_)), _, 1, _,
          BackendDAE.VAR(varName=cr2), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        false = BackendVariable.isStateVar(v2);
        replaceableAlias(v2);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v1, v2, false, iKnVars);
        // setAliasType
        ops = DAEUtil.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v2, DAE.SOLVED(cr2, e1)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e1));
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index2, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to vars
        vars = BackendVariable.addVar(var, vars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr2, e1, NONE());
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrExpStr, ("Alias Equation ", cr2, " = ", e1, " found (4).\n"));
      then
        (vars, iKnVars, iExtVars, avars, repl);
    // state variable
    case (BackendDAE.VAR(varName=cr1), _, 1, _,
          BackendDAE.VAR(varKind=BackendDAE.STATE(index=_)), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        false = BackendVariable.isStateVar(v1);
        replaceableAlias(v1);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v2, v1, false, iKnVars);
        // setAliasType
        ops = DAEUtil.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v1, DAE.SOLVED(cr1, e2)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e2));
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index1, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to vars
        vars = BackendVariable.addVar(var, vars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr1, e2, NONE());
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrExpStr, ("Alias Equation ", cr1, " = ", e2, " found (4).\n"));
      then
        (vars, iKnVars, iExtVars, avars, repl);
    // var var / state state
    case (BackendDAE.VAR(varName=cr1), _, 1, _,
          BackendDAE.VAR(varName=cr2), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        b1 = BackendVariable.isStateVar(v1);
        b2 = BackendVariable.isStateVar(v2);
        true = boolEq(b1, b2);
        replaceableAlias(v1);
        replaceableAlias(v2);
        // calc wights
        w1 = BackendVariable.calcAliasKey(v1);
        w2 = BackendVariable.calcAliasKey(v2);
        b = intGt(w2, w1);
        // select alias
        ((acr, avar, aindx, _, _, var, e)) = Util.if_(b, (cr2, v2, index2, e2, cr1, v1, e1), (cr1, v1, index1, e1, cr2, v2, e2));
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(var, avar, false, iKnVars);
        // setAliasType
        ops = DAEUtil.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(avar, DAE.SOLVED(acr, e)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e));
        avar = Debug.bcallret2(b1, BackendVariable.setVarKind, avar, BackendDAE.DUMMY_STATE(), avar);
        // remove from vars
        (vars, _) = BackendVariable.removeVar(aindx, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to vars
        vars = BackendVariable.addVar(var, vars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, acr, e, NONE());
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrExpStr, ("Alias Equation ", acr, " = ", e, " found (4).\n"));
      then
        (vars, iKnVars, iExtVars, avars, repl);
    // var/state parameter
    case (BackendDAE.VAR(varName=cr1), _, 1, _,
          BackendDAE.VAR(varName=_), _, 2, _, _, _, _, _, _, _)
      equation
        // check if replacable
        replaceableAlias(v1);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v2, v1, false, iKnVars);
        // setAliasType
        ops = DAEUtil.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v1, DAE.SOLVED(cr1, e2)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e2));
        avar = Debug.bcallret2(BackendVariable.isStateVar(v1), BackendVariable.setVarKind, avar, BackendDAE.DUMMY_STATE(), avar);
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index1, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to knvars
        knvars = BackendVariable.addVar(var, iKnVars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr1, e2, NONE());
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrExpStr, ("Alias Equation ", cr1, " = ", e2, " found (4).\n"));
      then
        (vars, knvars, iExtVars, avars, repl);
    // parameter var/state
    case (BackendDAE.VAR(varName=_), _, 2, _,
          BackendDAE.VAR(varName=cr2), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        replaceableAlias(v2);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v1, v2, false, iKnVars);
        // setAliasType
        ops = DAEUtil.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v2, DAE.SOLVED(cr2, e1)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e1));
        avar = Debug.bcallret2(BackendVariable.isStateVar(v2), BackendVariable.setVarKind, avar, BackendDAE.DUMMY_STATE(), avar);
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index2, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to knvars
        knvars = BackendVariable.addVar(var, iKnVars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr2, e1, NONE());
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrExpStr, ("Alias Equation ", cr2, " = ", e1, " found (4).\n"));
      then
        (vars, knvars, iExtVars, avars, repl);
    // var/state extvar
    case (BackendDAE.VAR(varName=cr1), _, 1, _,
          BackendDAE.VAR(varName=_), _, 3, _, _, _, _, _, _, _)
      equation
        // check if replacable
        replaceableAlias(v1);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v2, v1, false, iKnVars);
        // setAliasType
        ops = DAEUtil.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v1, DAE.SOLVED(cr1, e2)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e2));
        avar = Debug.bcallret2(BackendVariable.isStateVar(v1), BackendVariable.setVarKind, avar, BackendDAE.DUMMY_STATE(), avar);
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index1, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to extvars
        extvars = BackendVariable.addVar(var, iExtVars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr1, e2, NONE());
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrExpStr, ("Alias Equation ", cr1, " = ", e2, " found (4).\n"));
      then
        (vars, iKnVars, extvars, avars, repl);
    // extvar var/state
    case (BackendDAE.VAR(varName=_), _, 3, _,
          BackendDAE.VAR(varName=cr2), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        replaceableAlias(v2);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v1, v2, false, iKnVars);
        // setAliasType
        ops = DAEUtil.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v2, DAE.SOLVED(cr2, e1)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e1));
        avar = Debug.bcallret2(BackendVariable.isStateVar(v2), BackendVariable.setVarKind, avar, BackendDAE.DUMMY_STATE(), avar);
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index2, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to knvars
        extvars = BackendVariable.addVar(var, iExtVars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr2, e1, NONE());
        Debug.fcall(Flags.DEBUG_ALIAS, BackendDump.debugStrCrefStrExpStr, ("Alias Equation ", cr2, " = ", e1, " found (4).\n"));
      then
        (vars, iKnVars, extvars, avars, repl);
  end match;
end selectAliasVar;

protected function replaceableAlias
"author Frenkel TUD 2011-08
  check if the variable is a replaceable alias."
  input BackendDAE.Var var;
algorithm
  _ := match (var)
    case (_)
      equation
        false = BackendVariable.isVarOnTopLevelAndOutput(var);
        false = BackendVariable.isVarOnTopLevelAndInput(var);
        false = BackendVariable.varHasUncertainValueRefine(var);
      then
        ();
  end match;
end replaceableAlias;

/*
 *     other helping functions
 */

protected function detectImplicitDiscrete
"This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnVariables;
  input list<BackendDAE.Equation> inEquationLst;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := List.fold1(inEquationLst, detectImplicitDiscreteFold, inKnVariables, inVariables);
end detectImplicitDiscrete;

protected function detectImplicitDiscreteFold
"This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inKnVariables;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inEquation, inKnVariables, inVariables)
    local
      DAE.ComponentRef cr;
      list<BackendDAE.Var> vars;
      list<DAE.Statement> statementLst;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr)), _, _)
      equation
        (vars, _) = BackendVariable.getVar(cr, inVariables);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
      then BackendVariable.addVars(vars, inVariables);
    case (BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(statementLst = statementLst)), _, _)
      then detectImplicitDiscreteAlgsStatemens(inVariables, inKnVariables, statementLst, false);
    else inVariables;
  end matchcontinue;
end detectImplicitDiscreteFold;

protected function getVarsFromExp
"This function collects all variables from an expression-list."
  input list<DAE.Exp> inExpLst;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue(inExpLst, inVariables)
    local
      DAE.ComponentRef cref;
      list<DAE.Exp> expLst;
      BackendDAE.Variables variables;
      list<BackendDAE.Var> vars, varLst;
    case({}, _) then {};
    case(DAE.CREF(componentRef=cref)::expLst, variables) equation
      (vars, _) = BackendVariable.getVar(cref, variables);
      varLst = getVarsFromExp(expLst, variables);
    then listAppend(vars,varLst);
    case(_::expLst, variables) equation
      varLst = getVarsFromExp(expLst, variables);
    then varLst;
  end matchcontinue;
end getVarsFromExp;

protected function detectImplicitDiscreteAlgsStatemens
"This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnVariables;
  input list<DAE.Statement> inStatementLst;
  input Boolean insideWhen "true if its called from a when statement";
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables, inKnVariables, inStatementLst, insideWhen)
    local
      BackendDAE.Variables v, v_1, v_2, v_3, knv;
      DAE.ComponentRef cr;
      list<DAE.Statement> xs, statementLst;
      BackendDAE.Var var;
      list<BackendDAE.Var> vars;
      DAE.Statement statement;
      Boolean b;
      DAE.Type tp;
      DAE.Ident iteratorName;
      DAE.Exp e, iteratorExp;
      list<DAE.Exp> iteratorexps, expExpLst;
      list<DAE.Subscript> subs;

    case (v, _, {}, _) then v;
    case (v, knv, ((DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = cr)))::xs), true)
      equation
        ((var::_), _) = BackendVariable.getVar(cr, v);
        var = BackendVariable.setVarKind(var, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVar(var, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, true);
      then
        v_2;

    case (v, knv, ((DAE.STMT_ASSIGN(exp1 = DAE.ASUB(exp = DAE.CREF(componentRef = cr), sub= expExpLst)))::xs), true)
      equation
        subs = List.map(expExpLst, Expression.makeIndexSubscript);
        cr = ComponentReference.subscriptCref(cr, subs);
        (vars, _) = BackendVariable.getVar(cr, v);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVars(vars, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, true);
      then
        v_2;

      case(v, knv, (DAE.STMT_TUPLE_ASSIGN(expExpLst=expExpLst)::xs), true) equation
        vars = getVarsFromExp(expExpLst, v);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVars(vars, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, true);
      then v_2;

    case (v, knv, (DAE.STMT_ASSIGN_ARR(componentRef = cr)::xs), true)
      equation
        (vars, _) = BackendVariable.getVar(cr, v);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVars(vars, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, true);
      then
        v_2;
    case (v, knv, (DAE.STMT_IF(statementLst = statementLst)::xs), true)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, knv, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, true);
      then
        v_2;
    case (v, knv, (DAE.STMT_FOR(type_= tp, iter = iteratorName, range = e, statementLst = statementLst)::xs), true)
      equation
        /* use the range for the componentreferences */
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        iteratorExp = Expression.crefExp(cr);
        iteratorexps = extendRange(e, knv);
        v_1 = detectImplicitDiscreteAlgsStatemensFor(iteratorExp, iteratorexps, v, knv, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, true);
      then
        v_2;

/*
    case (v, knv, (DAE.STMT_PARFOR(type_= tp, iter = iteratorName, range = e, statementLst = statementLst, loopPrlVars=loopPrlVars)::xs), true)
      equation
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        iteratorExp = Expression.crefExp(cr);
        iteratorexps = extendRange(e, knv);
        v_1 = detectImplicitDiscreteAlgsStatemensFor(iteratorExp, iteratorexps, v, knv, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, true);
      then
        v_2;
*/

    case (v, knv, (DAE.STMT_WHEN(statementLst=statementLst, elseWhen=NONE())::xs), _)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, knv, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, false);
      then
        v_2;
    case (v, knv, (DAE.STMT_WHEN(statementLst=statementLst, elseWhen=SOME(statement))::xs), _)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, knv, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, {statement}, true);
        v_3 = detectImplicitDiscreteAlgsStatemens(v_2, knv, xs, false);
      then
        v_3;
    case (v, knv, (_::xs), b)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, knv, xs, b);
      then
        v_1;
  end matchcontinue;
end detectImplicitDiscreteAlgsStatemens;

protected function detectImplicitDiscreteAlgsStatemensFor
""
  input DAE.Exp inIteratorExp;
  input list<DAE.Exp> inExplst;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnVariables;
  input list<DAE.Statement> inStatementLst;
  input Boolean insideWhen "true if its called from a when statement";
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inIteratorExp, inExplst, inVariables, inKnVariables, inStatementLst, insideWhen)
    local
      BackendDAE.Variables v, v_1, v_2, knv;
      list<DAE.Statement> statementLst, statementLst1;
      Boolean b;
      DAE.Exp e, ie;
      list<DAE.Exp> rest;

    // case if the loop range can't extend, some vaiables
    case (_, {}, v, knv, _, _)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, knv, inStatementLst, true);
      then v_1;
    case (ie, e::{}, v, knv, statementLst, _)
      equation
        (statementLst1, _) = DAEUtil.traverseDAEEquationsStmts(statementLst, Expression.replaceExpTpl, ((ie, e)));
        v_1 = detectImplicitDiscreteAlgsStatemens(v, knv, statementLst1, true);
      then
        v_1;
    case (ie, e::rest, v, knv, statementLst, b)
      equation
        (statementLst1, _) = DAEUtil.traverseDAEEquationsStmts(statementLst, Expression.replaceExpTpl, ((ie, e)));
        v_1 = detectImplicitDiscreteAlgsStatemens(v, knv, statementLst1, true);
        v_2 = detectImplicitDiscreteAlgsStatemensFor(ie, rest, v_1, knv, statementLst, b);
      then
        v_2;
    case (ie, e::rest, v, knv, statementLst, b)
      equation
        (statementLst1, _) = DAEUtil.traverseDAEEquationsStmts(statementLst, Expression.replaceExpTpl, ((ie, e)));
        v_1 = detectImplicitDiscreteAlgsStatemens(v, knv, statementLst1, true);
        v_2 = detectImplicitDiscreteAlgsStatemensFor(ie, rest, v_1, knv, statementLst, b);
      then
        v_2;
    case (_, _, _, _, _, _)
      equation
        print("BackendDAECreate.detectImplicitDiscreteAlgsStatemensFor failed \n");
      then
        fail();
  end matchcontinue;
end detectImplicitDiscreteAlgsStatemensFor;

public function extendRange
  input DAE.Exp rangeExp;
  input BackendDAE.Variables inKnVariables;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (rangeExp, inKnVariables)
    local
      list<DAE.Exp> explst;
      DAE.Type tp;
      DAE.Exp startvalue, stopvalue, stepvalue;
      Option<DAE.Exp> stepvalueopt;
      BackendDAE.Variables knv;
      Integer istart, istop, istep;
      list<Integer> ilst;
    case (DAE.RANGE(ty=_, start=startvalue, step=stepvalueopt, stop=stopvalue), knv)
      equation
        stepvalue = Util.getOptionOrDefault(stepvalueopt, DAE.ICONST(1));
        istart = expInt(startvalue, knv);
        istep = expInt(stepvalue, knv);
        istop = expInt(stopvalue, knv);
        ilst = List.intRange3(istart, istep, istop);
        explst = List.map(ilst, Expression.makeIntegerExp);
      then
        explst;
    case (_, _)
      equation
        Debug.fprint(Flags.FAILTRACE, "BackendDAECreate.extendRange failed. Maybe some ZeroCrossing are not supported\n");
      then
        ({});
  end matchcontinue;
end extendRange;

public function expInt "returns the int value of an expression"
  input DAE.Exp exp;
  input BackendDAE.Variables inKnVariables;
  output Integer i;
algorithm
  i := match(exp, inKnVariables)
    local
      Integer i1, i2;
      DAE.ComponentRef cr;
      BackendDAE.Variables knv;
      DAE.Exp e, e1, e2;
    case (DAE.ICONST(integer = i2), _) then i2;
    case (DAE.ENUM_LITERAL(index = i2), _) then i2;
    case (DAE.CREF(componentRef=cr), knv)
      equation
        ((BackendDAE.VAR(bindExp=SOME(e)):: _), _) = BackendVariable.getVar(cr, knv);
        i2 = expInt(e, knv);
      then
        i2;
    case (DAE.BINARY(exp1 = e1, operator=DAE.ADD(DAE.T_INTEGER(varLst = _)), exp2 = e2), knv)
      equation
        i1 = expInt(e1, knv);
        i2 = expInt(e2, knv);
        i = i1 + i2;
      then i;
    case (DAE.BINARY(exp1 = e1, operator=DAE.SUB(DAE.T_INTEGER(varLst = _)), exp2 = e2), knv)
      equation
        i1 = expInt(e1, knv);
        i2 = expInt(e2, knv);
        i = i1 - i2;
      then i;
  end match;
end expInt;

protected function addOptimizationVarsEqns
"add objective function to DAE. Neeed for derivatives"
  input BackendDAE.Variables inVars;
  input list<BackendDAE.Equation> inEqns;
  input Boolean inOptimicaFlag;
  input list< .DAE.ClassAttributes> inClassAttr;
  input list< .DAE.Constraint> inConstraint;
  output BackendDAE.Variables outVars;
  output list<BackendDAE.Equation>  outEqns;
algorithm
  (outVars, outEqns) := match(inVars, inEqns, inOptimicaFlag, inClassAttr, inConstraint)
  local
      DAE.ComponentRef leftcref;
      list<BackendDAE.Equation> objectEqn;
      BackendDAE.Var dummyVar;
      Boolean b;
      BackendDAE.Variables v, knownVars;
      list<BackendDAE.Equation> e;
      Option<DAE.Exp> mayer, lagrange;
      list< .DAE.Exp> constraintLst;

    case (v, e, true, {DAE.OPTIMIZATION_ATTRS(objetiveE=mayer, objectiveIntegrandE=lagrange)}, _)
      equation
        leftcref = ComponentReference.makeCrefIdent("$TMP_mayerTerm", DAE.T_REAL_DEFAULT, {});
        dummyVar = BackendDAE.VAR(leftcref, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
        objectEqn = BackendEquation.generateSolvedEqnsfromOption(leftcref, mayer, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
        b = not List.isEmpty(objectEqn);

        v = Util.if_(b, BackendVariable.addNewVar(dummyVar, v), v);
        e = Util.if_(b, listAppend(e, objectEqn), e);

        leftcref = ComponentReference.makeCrefIdent("$TMP_lagrangeTerm", DAE.T_REAL_DEFAULT, {});
        dummyVar = BackendDAE.VAR(leftcref, BackendDAE.VARIABLE(), DAE.OUTPUT(), DAE.NON_PARALLEL(), DAE.T_REAL_DEFAULT, NONE(), NONE(), {}, DAE.emptyElementSource, NONE(), NONE(), DAE.NON_CONNECTOR());
        objectEqn = BackendEquation.generateSolvedEqnsfromOption(leftcref, lagrange, DAE.emptyElementSource, BackendDAE.UNKNOWN_EQUATION_KIND());
        b = not List.isEmpty(objectEqn);

        v = Util.if_(b, BackendVariable.addNewVar(dummyVar, v), v);
        e = Util.if_(b, listAppend(e, objectEqn), e);

        (v, e) = addOptimizationVarsEqns2(inConstraint, 1, v, e);

    then (v, e);
    else (inVars, inEqns);
  end match;
end addOptimizationVarsEqns;

protected function addOptimizationVarsEqns1
 input list<DAE.Exp> constraintLst;
 input Integer inI;
 input BackendDAE.Variables inVars;
 input list<BackendDAE.Equation> inEqns;
 output BackendDAE.Variables outVars;
 output list<BackendDAE.Equation>  outEqns;
algorithm
 (outVars, outEqns) := match(constraintLst, inI, inVars, inEqns)
 local
   list<DAE.Exp> conLst;
   DAE.Exp e;
   DAE.ComponentRef leftcref;
   BackendDAE.Var dummyVar;
   list<BackendDAE.Equation> conEqn;
   BackendDAE.Variables v;
   list<BackendDAE.Equation> eqns;

   case({}, _, _, _) then (inVars, inEqns);
   case(e::conLst, _, _, _) equation
    //print("con"+& intString(inI) +& " "+& ExpressionDump.printExpStr(e) +& "\n");
    (conEqn, dummyVar) = BackendEquation.generateResidualfromRealtion(inI, e, DAE.emptyElementSource);
    v = BackendVariable.addNewVar(dummyVar, inVars);
    eqns = listAppend(conEqn, inEqns);
    (v, eqns)= addOptimizationVarsEqns1(conLst, inI + 1, v, eqns);
   then (v, eqns);
   else (inVars, inEqns);
   end match;
end addOptimizationVarsEqns1;

public function addOptimizationVarsEqns2
 input list< .DAE.Constraint> inConstraint;
 input Integer inI;
 input BackendDAE.Variables inVars;
 input list<BackendDAE.Equation> inEqns;
 output BackendDAE.Variables outVars;
 output list<BackendDAE.Equation>  outEqns;
algorithm
  (outVars, outEqns) := match(inConstraint, inI, inVars, inEqns)
  local
   list<BackendDAE.Equation> e;
   BackendDAE.Variables v;
   list< .DAE.Exp> constraintLst;
    case({DAE.CONSTRAINT_EXPS(constraintLst = constraintLst)}, _, _, _) equation
      (v, e) = addOptimizationVarsEqns1(constraintLst, inI, inVars, inEqns);
      then (v, e);
  else (inVars, inEqns);
  end match;
end addOptimizationVarsEqns2;

end BackendDAECreate;


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


"

public import Absyn;
public import BackendDAE;
public import DAE;
public import FCore;

protected

import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import BackendVarTransform;
import BaseHashTable;
import CheckModel;
import ComponentReference;
import Config;
import ClassInf;
import DAEDump;
import DAEUtil;
import Debug;
import ElementSource;
import Error;
import ErrorExt;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import ExpressionSolve;
import Flags;
import Global;
import HashTableExpToExp;
import HashTableExpToIndex;
import HashTable;
import HashTableCrToExpSourceTpl;
import Inline;
import List;
import ExecStat.execStat;
import SCode;
import StackOverflow;
import System;
import Types;
import Util;
import VarTransform;
import Vectorization;
import ZeroCrossings;

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
  inputs:  lst: DAE.DAElist, inCache: FCore.Cache, inEnv: FCore.Graph
  outputs: BackendDAE.BackendDAE"
  input DAE.DAElist lst;
  input FCore.Cache inCache;
  input FCore.Graph inEnv;
  input BackendDAE.ExtraInfo inExtraInfo;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  list<BackendDAE.Var> varlst, globalKnownVarLst, extvarlst;
  BackendDAE.Variables vars, globalKnownVars, localKnownVars, vars_1, extVars, aliasVars, extAliasVars;
  list<BackendDAE.Equation> eqns, reqns, ieqns;
  list<DAE.Constraint> constrs;
  list<DAE.ClassAttributes> clsAttrs;
  BackendDAE.EquationArray eqnarr, reqnarr, ieqnarr;
  BackendDAE.ExternalObjectClasses extObjCls;
  BackendDAE.SymbolicJacobians symjacs;
  BackendDAE.EventInfo einfo;
  list<DAE.Element> elems, aliaseqns;
  DAE.FunctionTree functionTree;
  list<BackendDAE.TimeEvent> timeEvents;
  String neqStr, nvarStr;
  Integer varSize, eqnSize, numCheckpoints;
  BackendDAE.EqSystem syst;
algorithm
  numCheckpoints:=ErrorExt.getNumCheckpoints();
  try
  StackOverflow.clearStacktraceMessages();
  // reset dumped file sequence number
  System.tmpTickResetIndex(0, Global.backendDAE_fileSequence);
  System.tmpTickResetIndex(1, Global.backendDAE_cseIndex);
  System.tmpTickResetIndex(0, Global.strongComponent_index);
  functionTree := FCore.getFunctionTree(inCache);
  //deactivated because of some codegen errors: functionTree := renameFunctionParameter(functionTree);
  (DAE.DAE(elems), functionTree, timeEvents) := processBuiltinExpressions(lst, functionTree);
  (varlst, globalKnownVarLst, extvarlst, eqns, reqns, ieqns, constrs, clsAttrs, extObjCls, aliaseqns, _) :=
    lower2(listReverse(elems), functionTree, HashTableExpToExp.emptyHashTable());
  vars := BackendVariable.listVar(varlst);
  globalKnownVars := BackendVariable.listVar(globalKnownVarLst);
  localKnownVars := BackendVariable.emptyVars();
  extVars := BackendVariable.listVar(extvarlst);
  aliasVars := BackendVariable.emptyVars();
  if Flags.isSet(Flags.VECTORIZE) then
    (varlst,eqns) := Vectorization.collectForLoops(varlst,eqns);
    vars := BackendVariable.listVar(varlst);
  end if;
  // handle alias equations
  (vars, globalKnownVars, extVars, aliasVars, eqns, reqns, ieqns) := handleAliasEquations(aliaseqns, vars, globalKnownVars, extVars, aliasVars, eqns, reqns, ieqns);
  (ieqns, eqns, extAliasVars, extVars) := getExternalObjectAlias(ieqns, eqns, extVars);
  aliasVars := BackendVariable.addVariables(extAliasVars,aliasVars);

  vars_1 := detectImplicitDiscrete(vars, globalKnownVars, eqns);
  eqnarr := BackendEquation.listEquation(eqns);
  reqnarr := BackendEquation.listEquation(reqns);
  ieqnarr := BackendEquation.listEquation(ieqns);
  einfo := BackendDAE.EVENT_INFO(timeEvents, ZeroCrossings.new(), DoubleEndedList.fromList({}), ZeroCrossings.new(), 0);
  symjacs := {(NONE(), ({}, {}, ({}, {}), -1), {}), (NONE(), ({}, {}, ({}, {}), -1), {}), (NONE(), ({}, {}, ({}, {}), -1), {}), (NONE(), ({}, {}, ({}, {}), -1), {})};
  syst := BackendDAEUtil.createEqSystem(vars_1, eqnarr, {}, BackendDAE.UNKNOWN_PARTITION(), reqnarr);
  outBackendDAE := BackendDAE.DAE(syst::{},
                                  BackendDAE.SHARED(globalKnownVars,
                                                    localKnownVars,
                                                    extVars,
                                                    aliasVars,
                                                    ieqnarr,
                                                    BackendEquation.emptyEqns(),
                                                    constrs,
                                                    clsAttrs,
                                                    inCache,
                                                    inEnv,
                                                    functionTree,
                                                    einfo,
                                                    extObjCls,
                                                    BackendDAE.SIMULATION(),
                                                    symjacs,inExtraInfo,
                                                    BackendDAEUtil.emptyPartitionsInfo(),
                                                    BackendDAE.emptyDAEModeData,
                                                    NONE()
                                                    ));
  BackendDAEUtil.checkBackendDAEWithErrorMsg(outBackendDAE);
  BackendDAEUtil.checkIncidenceMatrixSolvability(syst, functionTree);

  if Flags.isSet(Flags.DUMP_BACKENDDAE_INFO) then
    Error.addSourceMessage(Error.BACKENDDAEINFO_LOWER,{String(BackendEquation.equationArraySize(syst.orderedEqs)), String(BackendVariable.varsSize(syst.orderedVars))},Absyn.dummyInfo);
  end if;
  execStat("Generate backend data structure");
  return;
  else
    setGlobalRoot(Global.stackoverFlowIndex, NONE());
    ErrorExt.rollbackNumCheckpoints(ErrorExt.getNumCheckpoints()-numCheckpoints);
    Error.addInternalError("Stack overflow in "+getInstanceName()+"...\n"+stringDelimitList(StackOverflow.readableStacktraceMessages(), "\n"), sourceInfo());
    /* Do not fail or we can loop too much */
    StackOverflow.clearStacktraceMessages();
  end try annotation(__OpenModelica_stackOverflowCheckpoint=true);
  fail();
end lower;

protected function getExternalObjectAlias "Checks equations if there is an alias equation for external objects.
If yes, assign alias var, replace equations, remove alias equation.
author: waurich TUD 2016-10"
  input list<BackendDAE.Equation> inInitEqs;
  input list<BackendDAE.Equation> inEqs;
  input BackendDAE.Variables extVars;
  output list<BackendDAE.Equation> oInitEqs;
  output list<BackendDAE.Equation> oEqs;
  output BackendDAE.Variables extAliasVars;
  output BackendDAE.Variables extVarsOut;
protected
  list<DAE.ComponentRef> extCrefs;
  list<BackendDAE.Equation> aliasEqs;
  list<BackendDAE.Var> aliasVarLst;
  BackendVarTransform.VariableReplacements repl;
algorithm
  //get the crefs of the external vars
  extCrefs := BackendVariable.getAllCrefFromVariables(extVars);

  // get alias equations for external objects
  (oEqs,aliasEqs) := List.fold1(inEqs,getExternalObjectAlias2,extCrefs,({},{}));
  (oInitEqs,aliasEqs) := List.fold1(inInitEqs,getExternalObjectAlias2,extCrefs,({},aliasEqs));

  if (not listEmpty(aliasEqs)) then
    Error.addCompilerWarning("Alias equations of external objects are not Modelica compliant as in:\n    "+stringDelimitList(List.map(aliasEqs,BackendDump.equationString),"\n    ")+"\n");
  end if;

  //assign aliasVariables and set new binding
  repl := BackendVarTransform.emptyReplacements();
  (aliasVarLst,repl) := List.fold1(aliasEqs,getExternalObjectAlias3,extVars,({},repl));
  extAliasVars := BackendVariable.listVar1(aliasVarLst);

  //remove alias from extVarArray
  extVarsOut := BackendVariable.deleteVars(extAliasVars,extVars);

  //replace in equations
  (oEqs,_) := BackendVarTransform.replaceEquations(oEqs,repl,NONE());
  (oInitEqs,_) := BackendVarTransform.replaceEquations(oInitEqs,repl,NONE());
  oEqs := listReverse(oEqs);
  oInitEqs := listReverse(oInitEqs);
end getExternalObjectAlias;

protected function getExternalObjectAlias3 "Gets the alias var and sim var for the given alias equation and adds a replacement rule
author: waurich TUD 2016-10"
  input BackendDAE.Equation eqIn;
  input BackendDAE.Variables extVars;
  input tuple<list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplIn;
  output tuple<list<BackendDAE.Var>,BackendVarTransform.VariableReplacements> tplOut;
protected
  BackendDAE.Equation eq;
  BackendDAE.Var v1,v2,simVar,aliasVar;
  list<DAE.ComponentRef> crefs;
  list<BackendDAE.Var> extAliasVars;
  BackendVarTransform.VariableReplacements repl;
algorithm
  (extAliasVars,repl) := tplIn;
  ({eq},_) := BackendVarTransform.replaceEquations({eqIn},repl,NONE());
  try
    //get alias and sim var
    crefs := BackendEquation.equationCrefs(eq);
    ({v1,v2},_) := BackendVariable.getVarLst(crefs,extVars);
    (simVar,aliasVar) := chooseExternalAlias(v1,v2);
    extAliasVars := aliasVar::extAliasVars;
    //build replacement rule
    repl := BackendVarTransform.addReplacement(repl,BackendVariable.varCref(aliasVar), Expression.crefExp(BackendVariable.varCref(simVar)), NONE());
    tplOut := (extAliasVars,repl);
  else
    Error.addMessage(Error.INTERNAL_ERROR,{"BackendDAECreate.getExternalObjectAlias3 failed for " + BackendDump.equationString(eqIn)});
  end try;
end getExternalObjectAlias3;

protected function chooseExternalAlias "Chooses a alias variable depending on which variable has a binding
author: waurich TUD 2016-10"
  input BackendDAE.Var var1;
  input BackendDAE.Var var2;
  output BackendDAE.Var simVar;
  output BackendDAE.Var aliasVar;
algorithm
  if BackendVariable.varHasBindExp(var1) and not BackendVariable.varHasBindExp(var2)then
    simVar := var1;
    aliasVar := BackendVariable.setBindExp(var2, SOME(Expression.crefExp(BackendVariable.varCref(simVar))));
  elseif BackendVariable.varHasBindExp(var2) and not BackendVariable.varHasBindExp(var1)then
    simVar := var2;
    aliasVar := BackendVariable.setBindExp(var1, SOME(Expression.crefExp(BackendVariable.varCref(simVar))));
  elseif BackendVariable.varHasBindExp(var2) and BackendVariable.varHasBindExp(var1) then
    if Expression.isCall(BackendVariable.varBindExp(var1)) then
      simVar := var1;
      aliasVar := BackendVariable.setBindExp(var2, SOME(Expression.crefExp(BackendVariable.varCref(simVar))));
    else
      simVar := var2;
      aliasVar := BackendVariable.setBindExp(var1, SOME(Expression.crefExp(BackendVariable.varCref(simVar))));
    end if;
  else
    simVar := var1;
    aliasVar := BackendVariable.setBindExp(var2, SOME(Expression.crefExp(BackendVariable.varCref(simVar))));
  end if;
end chooseExternalAlias;

protected function getExternalObjectAlias2 "Traverser for equations to check if an external alias assignment an be made
author: waurich TUD 2016-10"
  input BackendDAE.Equation eqIn;
  input list<DAE.ComponentRef> extCrefs;
  input tuple<list<BackendDAE.Equation>, list<BackendDAE.Equation>> eqTplIn; //nonAlias and aliasEqs
  output tuple<list<BackendDAE.Equation>, list<BackendDAE.Equation>> eqTplOut;
algorithm
  eqTplOut := matchcontinue(eqIn,extCrefs,eqTplIn)
    local
      list<BackendDAE.Equation> noAliasEqs, aliasEqs;
      DAE.ComponentRef cr1,cr2;
  case(BackendDAE.COMPLEX_EQUATION(left = DAE.CREF(componentRef=cr1), right = DAE.CREF(componentRef=cr2)),_,(noAliasEqs,aliasEqs))
    algorithm
      true := List.exist1(extCrefs,ComponentReference.crefEqual,cr1) and List.exist1(extCrefs,ComponentReference.crefEqual,cr2);
     then (noAliasEqs,eqIn::aliasEqs);

  case(BackendDAE.EQUATION(exp = DAE.CREF(componentRef= cr1, ty = DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ())),
                           scalar = DAE.CREF(componentRef= cr2, ty = DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ()))),_,(noAliasEqs,aliasEqs))
    algorithm
      true := List.exist1(extCrefs,ComponentReference.crefEqual,cr1) and List.exist1(extCrefs,ComponentReference.crefEqual,cr2);
     then (noAliasEqs,eqIn::aliasEqs);

  else
    algorithm
      (noAliasEqs,aliasEqs) := eqTplIn;
    then (eqIn::noAliasEqs,aliasEqs);
  end matchcontinue;
end getExternalObjectAlias2;

protected function lower2
  input list<DAE.Element> inElements;
  input DAE.FunctionTree inFunctions;
  input HashTableExpToExp.HashTable inInlineHT "Workaround to speed up inlining of array parameters.";
  input list<BackendDAE.Var> inVars = {};
  input list<BackendDAE.Var> inGlobalKnownVars = {};
  input list<BackendDAE.Var> inExVars = {};
  input list<BackendDAE.Equation> inEqns = {};
  input list<BackendDAE.Equation> inREqns = {};
  input list<BackendDAE.Equation> inIEqns = {};
  input list<DAE.Constraint> inConstraints = {};
  input list<DAE.ClassAttributes> inClassAttributes = {};
  input list<BackendDAE.ExternalObjectClass> inExtObjClasses = {};
  input list<DAE.Element> inAliasEqns = {};
  output list<BackendDAE.Var> outVars = inVars "Time dependent variables.";
  output list<BackendDAE.Var> outGlobalKnownVars = inGlobalKnownVars "Time independent variables.";
  output list<BackendDAE.Var> outExVars = inExVars "External variables.";
  output list<BackendDAE.Equation> outEqns  = inEqns "Dynamic equations/algorithms.";
  output list<BackendDAE.Equation> outREqns = inREqns "Algebraic equations.";
  output list<BackendDAE.Equation> outIEqns = inIEqns "Initial equations.";
  output list<DAE.Constraint> outConstraints = inConstraints;
  output list<DAE.ClassAttributes> outClassAttributes = inClassAttributes;
  output list<BackendDAE.ExternalObjectClass> outExtObjClasses = inExtObjClasses;
  output list<DAE.Element> outAliasEqns = inAliasEqns "List with all EqualityEquations.";
  output HashTableExpToExp.HashTable outInlineHT = inInlineHT;
protected
  Absyn.Path path;
  DAE.ElementSource src;
  list<DAE.Element> dae_elts;
  DAE.ClassAttributes class_attrs;
  DAE.Constraint constraints;
  DAE.Element el;
  BackendDAE.EquationAttributes eq_attrs;
  Integer whenClkCnt = 1;
  DAE.Exp e;
  list<BackendDAE.Equation> eqns, reqns;
algorithm
  for el in inElements loop
    _ := match(el)
      // class for external object
      case DAE.EXTOBJECTCLASS(path, src)
        algorithm
          outExtObjClasses := BackendDAE.EXTOBJCLASS(path, src) :: outExtObjClasses;
        then
          ();

      // variables
      case DAE.VAR()
        algorithm
          (outVars, outGlobalKnownVars, outExVars, outEqns, outREqns, outInlineHT) :=
            lowerVar(el, inFunctions, outVars, outGlobalKnownVars, outExVars, outEqns, outREqns, outInlineHT);
        then
          ();

      // scalar equations
      case DAE.EQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, false);
        then
          ();

      // initial equations
      case DAE.INITIALEQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, true);
        then
          ();

      // effort variable equality equations, separated to generate alias // variables
      case DAE.EQUEQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, false);
        then
          ();

      // a solved equation
      case DAE.DEFINE()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, false);
        then
          ();

      // a initial solved equation
      case DAE.INITIALDEFINE()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, true);
        then
          ();

      // complex equations
      case DAE.COMPLEX_EQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, false);
        then
          ();

      // complex initial equations
      case DAE.INITIAL_COMPLEX_EQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, true);
        then
          ();

      // array equations
      case DAE.ARRAY_EQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, false);
        then
          ();

      // for equation
      case DAE.FOR_EQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, false);
        then
          ();

      // initial array equations
      case DAE.INITIAL_ARRAY_EQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, true);
        then
          ();

      // when equations
      case DAE.WHEN_EQUATION(condition = e, equations = dae_elts)
        algorithm
          if Config.synchronousFeaturesAllowed() and Types.isClockOrSubTypeClock(Expression.typeof(e)) then

            (outEqns, outVars, eq_attrs) := createWhenClock(whenClkCnt, e, outEqns, outVars);
            whenClkCnt := whenClkCnt + 1;

            ( outVars, outGlobalKnownVars, outExVars, eqns, reqns, outIEqns, outConstraints, outClassAttributes,
              outExtObjClasses, outAliasEqns, outInlineHT ) :=
                  lower2( dae_elts, inFunctions, outInlineHT, outVars, outGlobalKnownVars, outExVars, {}, {}, outIEqns,
                          outConstraints, outClassAttributes, outExtObjClasses, outAliasEqns );

            outEqns := listAppend(List.map1(eqns, BackendEquation.setEquationAttributes, eq_attrs), outEqns);
            outREqns := listAppend(List.map1(reqns, BackendEquation.setEquationAttributes, eq_attrs), outREqns);
          else
            (eqns, reqns) := lowerWhenEqn(el, inFunctions, {}, {});
            outEqns := listAppend(outEqns, eqns);
            outREqns := listAppend(outREqns, reqns);
          end if;
        then
          ();

      // if equation
      case DAE.IF_EQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, false);
        then
          ();

      // initial if equation
      case DAE.INITIAL_IF_EQUATION()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerEqn(el, inFunctions, outEqns, outREqns, outIEqns, true);
        then
          ();

      // algorithm
      case DAE.ALGORITHM()
        algorithm
          (outEqns, outREqns, outIEqns) :=
            lowerAlgorithm(el, inFunctions, outEqns, outREqns, outIEqns, DAE.EXPAND(), false);
        then
          ();

      // initial algorithm
      case DAE.INITIALALGORITHM()
        algorithm
          (outEqns, outREqns, outIEqns) :=
            lowerAlgorithm(el, inFunctions, outEqns, outREqns, outIEqns, DAE.EXPAND(), true);
        then
          ();

      // flat class / COMP
      case DAE.COMP(dAElist = dae_elts)
        algorithm
          (outVars, outGlobalKnownVars, outExVars, outEqns, outREqns, outIEqns, outConstraints,
           outClassAttributes, outExtObjClasses, outAliasEqns, outInlineHT)
          := lower2(listReverse(dae_elts), inFunctions, outInlineHT, outVars,
            outGlobalKnownVars, outExVars, outEqns, outREqns, outIEqns, outConstraints,
            outClassAttributes, outExtObjClasses, outAliasEqns);
        then
          ();

      // assert in equation section is converted to ALGORITHM
      case DAE.ASSERT()
        algorithm
          (outEqns, outREqns, outIEqns) :=
           lowerAlgorithm(el, inFunctions, outEqns, outREqns, outIEqns, DAE.NOT_EXPAND(), false);
        then
          ();

      case DAE.INITIAL_ASSERT()
        algorithm
          (outEqns, outREqns, outIEqns) :=
           lowerAlgorithm(el, inFunctions, outEqns, outREqns, outIEqns, DAE.NOT_EXPAND(), true);
        then
          ();

      // terminate in equation section is converted to ALGORITHM
      case DAE.TERMINATE()
        algorithm
          (outEqns, outREqns, outIEqns) :=
           lowerAlgorithm(el, inFunctions, outEqns, outREqns, outIEqns, DAE.NOT_EXPAND(), false);
        then
          ();

      case DAE.INITIAL_TERMINATE()
        algorithm
          (outEqns, outREqns, outIEqns) := lowerAlgorithm(el, inFunctions, outEqns, outREqns, outIEqns, DAE.NOT_EXPAND(), true);
        then
          ();

      case DAE.NORETCALL()
        algorithm
          (outEqns, outREqns, outIEqns) :=
           lowerAlgorithm(el, inFunctions, outEqns, outREqns, outIEqns, DAE.NOT_EXPAND(), false);
        then
          ();

      // assert in equation section is converted to ALGORITHM
      case DAE.INITIAL_NORETCALL()
        algorithm
          (outEqns, outREqns, outIEqns) :=
           lowerAlgorithm(el, inFunctions, outEqns, outREqns, outIEqns, DAE.NOT_EXPAND(), true);
        then
          ();

      // constraint (Optimica). Just pass the constraints for now. Should
      // anything more be done here?
      case DAE.CONSTRAINT(constraints = constraints)
        algorithm
          outConstraints := constraints :: outConstraints;
        then
          ();

      case DAE.CLASS_ATTRIBUTES(classAttrs = class_attrs)
        algorithm
          outClassAttributes := class_attrs :: outClassAttributes;
        then
          ();

      else
        algorithm
          true := Flags.isSet(Flags.FAILTRACE);
          Debug.traceln("- BackendDAECreate.lower2 failed on: " + DAEDump.dumpElementsStr({el}));
        then
          fail();
    end match;
  end for;
end lower2;

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
  (outDAE, outTree, (_, (_, _, _, outTimeEvents))) := DAEUtil.traverseDAE(inDAE, functionTree, Expression.traverseSubexpressionsHelper, (transformBuiltinExpression, (ht, 0, 0, {})));
end processBuiltinExpressions;

protected function transformBuiltinExpression "author: lochel
  Helper for transformBuiltinExpressions"
  input DAE.Exp inExp;
  input tuple<HashTableExpToIndex.HashTable, Integer /*iDelay*/, Integer /*iSample*/, list<BackendDAE.TimeEvent>> inTuple;
  output DAE.Exp outExp;
  output tuple<HashTableExpToIndex.HashTable, Integer /*iDelay*/, Integer /*iSample*/, list<BackendDAE.TimeEvent>> outTuple;
algorithm
  (outExp,outTuple) := matchcontinue (inExp, inTuple)
    local
      DAE.Exp start, interval;
      list<DAE.Exp> es;
      HashTableExpToIndex.HashTable ht;
      Integer iDelay, iSample, i;
      list<BackendDAE.TimeEvent> timeEvents;
      DAE.CallAttributes attr;

    // delay [already in ht]
    case (DAE.CALL(Absyn.IDENT("delay"), es, attr), (ht, _, _, _)) equation
      i = BaseHashTable.get(inExp, ht);
    then (DAE.CALL(Absyn.IDENT("delay"), DAE.ICONST(i)::es, attr), inTuple);

    // delay [not yet in ht]
    case (DAE.CALL(Absyn.IDENT("delay"), es, attr), (ht, iDelay, iSample, timeEvents)) equation
      ht = BaseHashTable.add((inExp, iDelay+1), ht);
    then (DAE.CALL(Absyn.IDENT("delay"), DAE.ICONST(iDelay)::es, attr), (ht, iDelay+1, iSample, timeEvents));

    // sample [already in ht]
    case (DAE.CALL(Absyn.IDENT("sample"), es as {_, interval}, attr), (ht, _, _, _))
    guard (not Types.isClockOrSubTypeClock(Expression.typeof(interval))) equation
      i = BaseHashTable.get(inExp, ht);
    then (DAE.CALL(Absyn.IDENT("sample"), DAE.ICONST(i)::es, attr), inTuple);

    // sample [not yet in ht]
    case (DAE.CALL(Absyn.IDENT("sample"), es as {start, interval}, attr), (ht, iDelay, iSample, timeEvents))
    guard (not Types.isClockOrSubTypeClock(Expression.typeof(interval))) equation
      iSample = iSample+1;
      timeEvents = listAppend(timeEvents, {BackendDAE.SAMPLE_TIME_EVENT(iSample, start, interval)});
      ht = BaseHashTable.add((inExp, iSample), ht);
    then (DAE.CALL(Absyn.IDENT("sample"), DAE.ICONST(iSample)::es, attr), (ht, iDelay, iSample, timeEvents));

    else (inExp,inTuple);
  end matchcontinue;
end transformBuiltinExpression;

/*
 *  lower all variables
 */

public function lowerVars
  input list<DAE.Element> inElements;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Var> inVars = {} "The time depend Variables";
  input list<BackendDAE.Var> inGlobalKnownVars = {} "The time independend Variables";
  input list<BackendDAE.Var> inExVars = {} "The external Variables";
  input list<BackendDAE.Equation> inEqns = {} "The dynamic Equations/Algoritms";
  input list<BackendDAE.Equation> inREqns = {};
  output list<BackendDAE.Var> outVars = inVars;
  output list<BackendDAE.Var> outGlobalKnownVars = inGlobalKnownVars;
  output list<BackendDAE.Var> outExVars = inExVars;
  output list<BackendDAE.Equation> outEqns = inEqns;
  output list<BackendDAE.Equation> outREqns = inREqns;
protected
  DAE.ComponentRef cr;
  DAE.Type arr_ty;
  list<DAE.ComponentRef> crefs;
  list<DAE.Element> new_vars;
  HashTableExpToExp.HashTable inline_ht = HashTableExpToExp.emptyHashTable();
algorithm
  for el in inElements loop
    try
      DAE.VAR(componentRef = cr, ty = DAE.T_ARRAY(ty = arr_ty)) := el;
      crefs := ComponentReference.expandCref(cr, false);
      el := DAEUtil.replaceTypeInVar(arr_ty, el);
      new_vars := list(DAEUtil.replaceCrefInVar(c, el) for c in crefs);
      (outVars, outGlobalKnownVars, outExVars, outEqns, outREqns) :=
        lowerVars(new_vars, functionTree, outVars, outGlobalKnownVars, outExVars, outEqns, outREqns);
    else
      (outVars, outGlobalKnownVars, outExVars, outEqns, outREqns) := lowerVar(el, functionTree,
        outVars, outGlobalKnownVars, outExVars, outEqns, outREqns, inline_ht);
    end try;
  end for;
end lowerVars;

protected function lowerVar
  input DAE.Element inElement;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inVars;
  input list<BackendDAE.Var> inGlobalKnownVars;
  input list<BackendDAE.Var> inExVars;
  input list<BackendDAE.Equation> inEqns;
  input list<BackendDAE.Equation> inREqns;
  input HashTableExpToExp.HashTable inInlineHT;
  output list<BackendDAE.Var> outVars = inVars;
  output list<BackendDAE.Var> outGlobalKnownVars = inGlobalKnownVars;
  output list<BackendDAE.Var> outExVars = inExVars;
  output list<BackendDAE.Equation> outEqns = inEqns;
  output list<BackendDAE.Equation> outREqns = inREqns;
  output HashTableExpToExp.HashTable outInlineHT = inInlineHT;
algorithm
  _ := matchcontinue(inElement)
    local
      DAE.ComponentRef cr;
      DAE.ElementSource src;
      DAE.Exp e1, e2;
      DAE.Dimensions dims;
      BackendDAE.EquationAttributes attr;
      BackendDAE.Var var;
      list<BackendDAE.Equation> assert_eqs;

    // external object variables
    case DAE.VAR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ()))
      algorithm
        outExVars := lowerExtObjVar(inElement, inFunctions) :: outExVars;
      then
        ();

    // variables: states and algebraic variables with binding equation
    case DAE.VAR(componentRef = cr, binding = SOME(e2), source = src) guard(isStateOrAlgvar(inElement))
      algorithm
        // Add the binding as an equation and remove the binding from the variable.
        outVars := lowerDynamicVar(inElement, inFunctions) :: outVars;
        e1 := Expression.crefExp(cr);
        attr := BackendDAE.EQ_ATTR_DEFAULT_BINDING;
        (_, dims) := ComponentReference.crefTypeFull2(cr);
        if listEmpty(dims) then
          outEqns := BackendDAE.EQUATION(e1, e2, src, attr) :: outEqns;
        else
          outEqns := BackendDAE.ARRAY_EQUATION(Expression.dimensionsSizes(dims), e1, e2, src, attr) :: outEqns;
        end if;
      then
        ();

    // variables: states and algebraic variables without binding equation
    case DAE.VAR(binding = NONE()) guard(isStateOrAlgvar(inElement))
      algorithm
        outVars := lowerDynamicVar(inElement, inFunctions) :: outVars;
      then
        ();

    // known variables: parameters and constants
    case DAE.VAR()
      algorithm
        (var, outInlineHT, outREqns) :=
          lowerKnownVar(inElement, inFunctions, outInlineHT, outREqns);
        outGlobalKnownVars := var :: outGlobalKnownVars;
      then
        ();

    else
      algorithm
        Error.addMessage(Error.INTERNAL_ERROR,
          {"BackendDAECreate.lowerVar failed for " + DAEDump.dumpElementsStr({inElement})});
      then
        fail();

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
  (outVar) := match (inElement)
    local
      list<DAE.Dimension> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      DAE.ConnectorType ct;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      Option<SCode.Comment> comment;
      DAE.Type t;
      DAE.VarVisibility protection;
      Boolean b;
      Absyn.InnerOuter io;

    case DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  parallelism = prl,
                  protection = protection,
                  ty = t,
                  dims = dims,
                  connectorType = ct,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  comment = comment,
                  innerOuter = io)
      equation
        (kind_1) = lowerVarkind(kind, t, name, dir, ct, dae_var_attr);
        tp = lowerType(t);
        b = DAEUtil.boolVarVisibility(protection);
        dae_var_attr = DAEUtil.setProtectedAttr(dae_var_attr, b);
        dae_var_attr = setMinMaxFromEnumeration(t, dae_var_attr);
        ts = BackendDAEUtil.setTearingSelectAttribute(comment);
        hideResult = BackendDAEUtil.setHideResultAttribute(comment, b, name);
      then
        (BackendDAE.VAR(name, kind_1, dir, prl, tp, NONE(), NONE(), dims, source, dae_var_attr, ts, hideResult, comment, ct, DAEUtil.toDAEInnerOuter(io), false));
  end match;
end lowerDynamicVar;

protected function lowerKnownVar
"Helper function to lower2"
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input HashTableExpToExp.HashTable iInlineHT "workaround to speed up inlining of array parameters";
  input list<BackendDAE.Equation> assrtEqIn;
  output BackendDAE.Var outVar;
  output HashTableExpToExp.HashTable oInlineHT "workaround to speed up inlining of array parameters";
  output list<BackendDAE.Equation> assrtEqOut;
algorithm
  (outVar,oInlineHT,assrtEqOut) := matchcontinue (inElement)
    local
      list<DAE.Dimension> dims;
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
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      Option<SCode.Comment> comment;
      DAE.Type t;
      DAE.VarVisibility protection;
      Boolean b;
      String str;
      Functiontuple fnstpl;
      HashTableExpToExp.HashTable inlineHT;
      list<DAE.Statement> assrtLst;
      list<BackendDAE.Equation> eqLst;
      Absyn.InnerOuter io;
     case DAE.VAR(componentRef = name,
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
                  comment = comment,
                  innerOuter = io)
      equation
        kind_1 = lowerKnownVarkind(kind, name, dir, ct);
        // bind = fixParameterStartBinding(bind, t, dae_var_attr, kind_1);
        tp = lowerType(t);
        b = DAEUtil.boolVarVisibility(protection);
        dae_var_attr = DAEUtil.setProtectedAttr(dae_var_attr, b);
        dae_var_attr = setMinMaxFromEnumeration(t, dae_var_attr);
        // build algorithms for the inlined asserts
        eqLst = buildAssertAlgorithms({},source,assrtEqIn);
        // building an algorithm of the assert
        ts = NONE();
        hideResult = BackendDAEUtil.setHideResultAttribute(comment, b, name);
      then
        (BackendDAE.VAR(name, kind_1, dir, prl, tp, bind, NONE(), dims, source, dae_var_attr, ts, hideResult, comment, ct, DAEUtil.toDAEInnerOuter(io), false), iInlineHT, eqLst);

    else
      equation
        str = "BackendDAECreate.lowerKnownVar failed for " + DAEDump.dumpElementsStr({inElement});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end lowerKnownVar;


protected function buildAssertAlgorithms "builds BackendDAE.ALGORITHM out of the given assert statements
author:Waurich TUD 2013-10"
  input list<DAE.Statement> assrtIn;
  input DAE.ElementSource source;
  input list<BackendDAE.Equation> eqIn;
  output list<BackendDAE.Equation> eqOut = eqIn;
protected
  BackendDAE.Equation eq;
algorithm
  for assrt in assrtIn loop
    eqOut := BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({assrt}), source,
        DAE.EXPAND(), BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC) :: eqOut;
  end for;
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
    case (DAE.CALL(),_,_,_)
      equation
        e1 = BaseHashTable.get(iExp,iInlineHT);
        // print("use chache Inline\n" + ExpressionDump.printExpStr(iExp) + "\n");
        source = ElementSource.addSymbolicTransformation(iSource,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(iExp),DAE.PARTIAL_EQUATION(e1)));
      then (e1,source,iInlineHT,{});
    case (DAE.CALL(),_,_,_)
      equation
        // print("add chache Inline\n" + ExpressionDump.printExpStr(iExp) + "\n");
        (e1, source, inlined,_) = Inline.inlineExp(iExp, fnstpl, iSource);
        inlineHT = if inlined then BaseHashTable.add((iExp,e1), iInlineHT) else iInlineHT;
      then (e1,source,inlineHT,{});
    case (DAE.ASUB(e,elst),_,_,_)
      equation
        e1 = BaseHashTable.get(e,iInlineHT);
        // print("use chache Inline\n" + ExpressionDump.printExpStr(iExp) + "\n");
        source = ElementSource.addSymbolicTransformation(iSource,DAE.OP_INLINE(DAE.PARTIAL_EQUATION(e),DAE.PARTIAL_EQUATION(e1)));
        (e, source, _,_) = Inline.inlineExp(DAE.ASUB(e1,elst), fnstpl, source);
      then (e,source,iInlineHT,{});
    case (DAE.ASUB(e,elst),_,_,_)
      equation
        // print("add chache Inline(1)\n" + ExpressionDump.printExpStr(iExp) + "\n");
        (e1, _, inlined,assrtLst1) = Inline.inlineExp(e, fnstpl, iSource);
        inlineHT = if inlined then BaseHashTable.add((e,e1), iInlineHT) else iInlineHT;
        (e, source, _,assrtLst2) = Inline.inlineExp(DAE.ASUB(e1,elst), fnstpl, iSource);
        assrtLst = listAppend(assrtLst1,assrtLst2);
      then (e,source,inlineHT,assrtLst);
    case (_,_,_,_)
      equation
        // print("no chache Inline\n" + ExpressionDump.printExpStr(iExp) + "\n");
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
        s1 = listHead(inNames);
        namee1 = Absyn.joinPaths(inPath, Absyn.IDENT(s1));
        sn = listGet(inNames, i);
        nameen = Absyn.joinPaths(inPath, Absyn.IDENT(sn));
      then
        DAEUtil.setMinMax(inVarAttr, SOME(DAE.ENUM_LITERAL(namee1, 1)), SOME(DAE.ENUM_LITERAL(nameen, i)));
    case (NONE(), SOME(_), _, _, _)
      equation
        s1 = listHead(inNames);
        namee1 = Absyn.joinPaths(inPath, Absyn.IDENT(s1));
      then
        DAEUtil.setMinMax(inVarAttr, SOME(DAE.ENUM_LITERAL(namee1, 1)), inMax);
    case (SOME(_), NONE(), _, _, _)
      equation
        i = listLength(inNames);
        sn = listGet(inNames, i);
        nameen = Absyn.joinPaths(inPath, Absyn.IDENT(sn));
      then
        DAEUtil.setMinMax(inVarAttr, inMin, SOME(DAE.ENUM_LITERAL(nameen, i)));
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
  outVarKind := match(inVarKind, daeAttr)
    // variable -> state if have stateSelect = StateSelect.always
    case (DAE.VARIABLE(), SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS()))))
      then BackendDAE.STATE(1, NONE());

    // variable -> state if have stateSelect = StateSelect.prefer
    case (DAE.VARIABLE(), SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.PREFER()))))
      then BackendDAE.STATE(1, NONE());

    else
      algorithm
        false := DAEUtil.topLevelInput(inComponentRef, inVarDirection, inConnectorType);
      then
        match (inVarKind, inType)
          case (DAE.VARIABLE(), DAE.T_BOOL()) then BackendDAE.DISCRETE();
          case (DAE.VARIABLE(), DAE.T_INTEGER()) then BackendDAE.DISCRETE();
          case (DAE.VARIABLE(), DAE.T_ENUMERATION()) then BackendDAE.DISCRETE();
          case (DAE.VARIABLE(), _) then BackendDAE.VARIABLE();
          case (DAE.DISCRETE(), _) then BackendDAE.DISCRETE();
        end match;
  end match;
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
        true = DAEUtil.topLevelInput(inComponentRef, inVarDirection, inConnectorType);
      then
        BackendDAE.VARIABLE();
    // adrpo: topLevelInput might fail!
    // case (DAE.VARIABLE(), cr, dir, flowPrefix)
    //  then
    //    BackendDAE.VARIABLE();
    else
      equation
        Error.addInternalError("function lowerKnownVarkind failed", sourceInfo());
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
    case DAE.T_REAL() then DAE.T_REAL_DEFAULT;
    case DAE.T_INTEGER() then DAE.T_INTEGER_DEFAULT;
    case DAE.T_BOOL() then DAE.T_BOOL_DEFAULT;
    case DAE.T_STRING() then DAE.T_STRING_DEFAULT;
    case DAE.T_CLOCK() then DAE.T_CLOCK_DEFAULT;
    case DAE.T_ENUMERATION() then inType;
    case DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ()) then inType;
    case DAE.T_COMPLEX(complexClassType = ClassInf.RECORD()) then inType;
    case DAE.T_ARRAY() then inType;
    case DAE.T_FUNCTION() then inType;
    else equation print("lowerType: " + Types.printTypeStr(inType) + " failed\n"); then fail();
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
  match (inElement)
    local
      list<DAE.Dimension> dims;
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
      Option<BackendDAE.TearingSelect> ts;
      DAE.Exp hideResult;
      Option<SCode.Comment> comment;
      DAE.Type t;
      Absyn.InnerOuter io;

    case DAE.VAR(componentRef = name,
                  direction = dir,
                  parallelism = prl,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  connectorType = ct,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  comment = comment,
                  innerOuter=io)
      equation
        kind_1 = lowerExtObjVarkind(t);
        tp = lowerType(t);
        ts = NONE();
        hideResult = DAE.BCONST(false);
      then
        BackendDAE.VAR(name, kind_1, dir, prl, tp, bind, NONE(), dims, source, dae_var_attr, ts, hideResult, comment, ct, DAEUtil.toDAEInnerOuter(io), false);
  end match;
end lowerExtObjVar;

protected function lowerExtObjVarkind
" Helper function to lowerExtObjVar.
  NOTE: Fails for everything but External objects"
  input DAE.Type inType;
  output BackendDAE.VarKind outVarKind;
protected
  Absyn.Path path;
algorithm
  DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path = path)) := inType;
  outVarKind := BackendDAE.EXTOBJ(path);
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
  input Boolean inInitialization;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outREquations;
  output list<BackendDAE.Equation> outIEquations;
algorithm
  (outEquations,outREquations,outIEquations) :=  match inElement
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
    case DAE.EQUATION(DAE.TUPLE(explst), DAE.TUPLE(explst1), source = source)
      equation
        eqns = lowerTupleAssignment(explst,explst1,source,functionTree,inEquations);
      then
        (eqns,inREquations,inIEquations);
    case DAE.INITIALEQUATION(DAE.TUPLE(explst), DAE.TUPLE(explst1), source = source)
      equation
        eqns = lowerTupleAssignment(explst,explst1,source,functionTree,inIEquations);
      then
        (inEquations,inREquations,eqns);

    // Only succeds for tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c)

    case DAE.EQUATION(e1 as DAE.TUPLE(_),e2 as DAE.CALL(),source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
        eqns = lowerExtendedRecordEqn(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC,functionTree,inEquations);
      then
        (eqns,inREquations,inIEquations);

    case DAE.EQUATION(e2 as DAE.CALL(),e1 as DAE.TUPLE(_),source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
        eqns = lowerExtendedRecordEqn(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC,functionTree,inEquations);
      then
        (eqns,inREquations,inIEquations);

    // Only succeds for initial tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c)
    case DAE.INITIALEQUATION(e1 as DAE.TUPLE(_),e2 as DAE.CALL(),source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
        eqns = lowerExtendedRecordEqn(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_INITIAL,functionTree,inIEquations);
      then
        (inEquations,inREquations,eqns);

    case DAE.INITIALEQUATION(e2 as DAE.CALL(), e1 as DAE.TUPLE(_),source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
        eqns = lowerExtendedRecordEqn(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_INITIAL,functionTree,inIEquations);
      then
        (inEquations,inREquations,eqns);

    case DAE.EQUATION(exp = e1,scalar = e2,source = source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::inEquations,inREquations,inIEquations);

    case DAE.INITIALEQUATION(exp1 = e1,exp2 = e2,source = source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
      then
        (inEquations,inREquations,BackendDAE.EQUATION(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_INITIAL)::inIEquations);

    case DAE.EQUEQUATION(cr1 = cr1, cr2 = cr2,source = source)
      equation
        if Flags.isSet(Flags.NF_SCALARIZE) then
          e1 = Expression.crefExp(cr1);
          e2 = Expression.crefExp(cr2);
        else
          // consider array dimensions
          e1 = Expression.crefToExp(cr1);
          e2 = Expression.crefToExp(cr2);
        end if;
        eqns = lowerExtendedRecordEqn(e1,e2,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC,functionTree,inEquations);
      then
       (eqns,inREquations,inIEquations);

    case DAE.DEFINE(componentRef = cr1, exp = e2, source = source)
      equation
        e1 = Expression.crefExp(cr1);
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::inEquations,inREquations,inIEquations);

    case DAE.INITIALDEFINE(componentRef = cr1, exp = e2, source = source)
      equation
        e1 = Expression.crefExp(cr1);
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
      then
        (inEquations,inREquations,BackendDAE.EQUATION(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::inIEquations);

    case DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source)
      equation
         //TODO: remove inline
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = Inline.simplifyAndForceInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE(), DAE.DEFAULT_INLINE()}), source);
        eqns = lowerExtendedRecordEqn(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC,functionTree,inEquations);
      then
        (eqns,inREquations,inIEquations);

    case DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source)
      equation
         //TODO: remove inline
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = Inline.simplifyAndForceInlineEquationExp(DAE.EQUALITY_EXPS(e1,e2), (SOME(functionTree), {DAE.NORM_INLINE(), DAE.DEFAULT_INLINE()}), source);
        eqns = lowerExtendedRecordEqn(e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC,functionTree,inIEquations);
      then
        (inEquations,inREquations,eqns);

    // equalityConstraint equations, moved to removed equations
    case DAE.ARRAY_EQUATION(dimension=dims, exp = e1 as DAE.ARRAY(array={}),array = e2 as DAE.CALL(path=path),source = source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
        b1 = stringEq(Absyn.pathLastIdent(path),"equalityConstraint");
        eqns = if b1 then inREquations else inEquations;
        eqns = lowerArrayEqn(dims,e1_1, e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC,eqns);
        ((eqns,_)) = if b1 then (inEquations,eqns) else (eqns,inREquations);
      then
        (eqns,inREquations,inIEquations);

    case DAE.ARRAY_EQUATION(dimension=dims,exp = e1,array = e2,source = source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
        eqns = lowerArrayEqn(dims,e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC,inEquations);
      then
        (eqns,inREquations,inIEquations);

    case DAE.INITIAL_ARRAY_EQUATION(dimension=dims,exp = e1,array = e2,source = source)
      equation
        (DAE.EQUALITY_EXPS(e1_1,e2_1), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(e1,e2),source);
        eqns = lowerArrayEqn(dims,e1_1,e2_1,source,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC,inIEquations);
      then
        (inEquations,inREquations,eqns);

    case DAE.FOR_EQUATION(iter = s, range = e1, equations = eqnslst, source = source)
      equation
        // create one backend for-equation for each equation element in the loop
        (eqns, reqns, ieqns) = lowerEqns(eqnslst, functionTree, {}, {}, {}, inInitialization);
        eqns = listAppend(List.map2(eqns, lowerForEquation, s, e1), inEquations);
        reqns = listAppend(List.map2(reqns, lowerForEquation, s, e1), inREquations);
        ieqns = listAppend(List.map2(ieqns, lowerForEquation, s, e1), inIEquations);
      then
        (eqns, reqns, ieqns);

   // if equation that cannot be translated to if expression but have initial() as condition
    case DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))},equations2={eqnslst},equations3={})
      equation
        (eqns,reqns,ieqns) = lowerEqns(eqnslst,functionTree,{},{},{},inInitialization);
        ieqns = List.flatten({eqns,reqns,ieqns,inIEquations});
      then
        (inEquations,inREquations,ieqns);

    case DAE.IF_EQUATION(condition1=explst,equations2=eqnslstlst,equations3=eqnslst,source=source)
      equation
        // move out assert, terminate, message stuff from if equation
        (eqnslstlst,eqnslst,daeElts) = lowerIfEquationAsserts(explst,eqnslstlst,eqnslst,{},{},{});
        (eqns,reqns,ieqns) = lowerEqns(daeElts,functionTree,inEquations,inREquations,inIEquations,inInitialization);
        eqns = lowerIfEquation(explst,eqnslstlst,eqnslst,{},{},source,functionTree,eqns);
      then
        (eqns,reqns,ieqns);

    case DAE.INITIAL_IF_EQUATION(condition1=explst,equations2=eqnslstlst,equations3=eqnslst,source = source)
      equation
        eqns = lowerIfEquation(explst,eqnslstlst,eqnslst,{},{},source,functionTree,inIEquations);
      then
       (inEquations,inREquations,eqns);

    // algorithm
    case DAE.ALGORITHM()
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.EXPAND(), false);
      then
        (eqns,reqns,ieqns);

    // initial algorithm
    case DAE.INITIALALGORITHM()
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.EXPAND(), true);
      then
        (eqns,reqns,ieqns);


    case DAE.ASSERT()
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.NOT_EXPAND(), inInitialization);
      then
        (eqns,reqns,ieqns);

    case DAE.INITIAL_ASSERT()
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.NOT_EXPAND(), inInitialization);
      then
        (eqns,reqns,ieqns);

    case DAE.TERMINATE(message=msg,source=source)
      then
        (inEquations, BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg,source)}), source, DAE.NOT_EXPAND(), BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::inREquations, inIEquations);

    case DAE.INITIAL_TERMINATE(message=msg, source=source)
      then
        (inEquations, inREquations, BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg,source)}), source, DAE.NOT_EXPAND(), BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::inIEquations);

    case DAE.NORETCALL()
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.NOT_EXPAND(), false);
      then
        (eqns,reqns,ieqns);

    case DAE.INITIAL_NORETCALL()
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEquations,inREquations,inIEquations, DAE.NOT_EXPAND(), true);
      then
        (eqns,reqns,ieqns);

    else
      equation
        s = "BackendDAECreate.lowerEqn failed for " + DAEDump.dumpElementsStr({inElement});
        Error.addSourceMessage(Error.INTERNAL_ERROR, {s}, ElementSource.getElementSourceFileInfo(ElementSource.getElementSource(inElement)));
      then fail();

  end match;
end lowerEqn;

protected
function lowerForEquation
"Wrap one equation into a for-equation.
 author: rfranke"
  input BackendDAE.Equation eq;
  input DAE.Ident iter;
  input DAE.Exp range;
  output BackendDAE.Equation forEq;
protected
  DAE.Exp iterExp, start, stop;
  DAE.Type ty;
algorithm
  DAE.RANGE(ty=ty, start=start, stop=stop) := range;
  iterExp := DAE.CREF(DAE.CREF_IDENT(iter, ty, {}), ty);
  forEq := BackendDAE.FOR_EQUATION(iterExp, start, stop, eq,
                                   BackendEquation.equationSource(eq),
                                   BackendEquation.getEquationAttributes(eq));
end lowerForEquation;

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
        (beqns,breqns,bieqns) = lowerEqns(elseenqs,functionTree,{},{},{},false);
        beqns = List.flatten({beqns,breqns,bieqns,inEquations});
      then
        beqns;

    // true case left with condition<>false
    case ({}, {}, _, _, _, _, _, _)
      equation
        explst = listReverse(conditions1);
        beqnslst = lowerEqnsLst(theneqns1,functionTree,{},false);
        (beqns,breqns,bieqns) = lowerEqns(elseenqs,functionTree,{},{},{},false);
        beqns = List.flatten({beqns,breqns,bieqns});
      then
        BackendDAE.IF_EQUATION(explst, beqnslst, beqns, inSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)::inEquations;

    // all other cases
    case(e::explst, eqns::eqnslst, _, _, _, _, _, _)
      equation
        (DAE.PARTIAL_EQUATION(e), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(e),inSource);
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
        (beqns,breqns,bieqns) = lowerEqns(theneqn,functionTree,{},{},{},false);
        beqns = List.flatten({beqns,breqns,bieqns,inEqns});
      then
        beqns;

    // if true use it as new else if it is not the first one
    case(DAE.BCONST(true), _, _, _, _, {}, {}, _, _, _)
      equation
        explst = listReverse(conditions1);
        beqnslst = lowerEqnsLst(theneqns1,functionTree,{},false);
        (beqns,breqns,bieqns) = lowerEqns(theneqn,functionTree,{},{},{},false);
        beqns = List.flatten({beqns,breqns,bieqns});
      then
        BackendDAE.IF_EQUATION(explst, beqnslst, beqns, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)::inEqns;

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
  input Boolean inInitialization;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outREquations;
  output list<BackendDAE.Equation> outIEquations;
algorithm
  (outEquations,outREquations,outIEquations) := match inElements
    local
      DAE.Element element;
      list<DAE.Element> elements;
      list<BackendDAE.Equation> eqns,reqns,ieqns;
  case {} then (inEquations,inREquations,inIEquations);
  case element::elements
    equation
      (eqns,reqns,ieqns) = lowerEqn(element,functionTree,inEquations,inREquations,inIEquations, inInitialization);
      (eqns,reqns,ieqns) = lowerEqns(elements,functionTree,eqns,reqns,ieqns, inInitialization);
    then
      (eqns,reqns,ieqns);
  end match;
end lowerEqns;

protected function lowerEqnsLst "author: Frenkel TUD 2012-06"
  input list<list<DAE.Element>> inElements;
  input DAE.FunctionTree functionTree;
  input list<list<BackendDAE.Equation>> inEquations;
  input Boolean inInitialization;
  output list<list<BackendDAE.Equation>> outEquations;
algorithm
  outEquations := match inElements
    local
      list<DAE.Element> element;
      list<list<DAE.Element>> elements;
      list<BackendDAE.Equation> eqns,reqns,ieqns;
  case {} then inEquations;
  case element::elements
    equation
      (eqns,reqns,ieqns) = lowerEqns(element,functionTree,{},{},{},inInitialization);
      eqns = List.flatten({eqns,reqns,ieqns});
    then
      lowerEqnsLst(elements,functionTree,eqns::inEquations,inInitialization);
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
        // _ = List.fold(conditions, makeIfExp, DAE.BCONST(true)); // TODO: Does this do anything?
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
  input BackendDAE.EquationAttributes inEqAttributes;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := match(explst1, explst2, source, inEqAttributes, functionTree, inEqns)
    local
      DAE.Exp e1, e2;
      list<DAE.Exp> elst1, elst2;
      list<BackendDAE.Equation> eqns;
    case({}, {}, _, _, _, _) then inEqns;
    case(e1::elst1, e2::elst2, _, _, _, _)
      equation
        eqns = lowerExtendedRecordEqn(e1, e2, source, inEqAttributes, functionTree, inEqns);
      then
        lowerExtendedRecordEqns(elst1, elst2, source, inEqAttributes, functionTree, eqns);
  end match;
end lowerExtendedRecordEqns;

protected function lowerExtendedRecordEqn "author: Frenkel TUD 2012-06"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes inEqAttributes;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(inExp1, inExp2, source, inEqAttributes, functionTree, inEqns)
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
        lowerExtendedRecordEqns(explst1, explst2, source, inEqAttributes, functionTree, inEqns);

    // complex types to complex equations
    case (_, _, _, _, _, _)
      equation
        tp = Expression.typeof(inExp1);
        true = DAEUtil.expTypeComplex(tp);
        size = Expression.sizeOf(tp);
      then
        BackendDAE.COMPLEX_EQUATION(size, inExp1, inExp2, source, inEqAttributes)::inEqns;

    // array types to array equations
    case (_, _, _, _, _, _)
      equation
        tp = Expression.typeof(inExp1);
        true = DAEUtil.expTypeArray(tp);
        dims = Expression.arrayDimension(tp);
      then
        lowerArrayEqn(dims, inExp1, inExp2, source, inEqAttributes, inEqns);

    // tuple types to complex equations
    case (_, _, _, _, _, _)
      equation
        tp = Expression.typeof(inExp1);
        true = Types.isTuple(tp);
        size = Expression.sizeOf(tp);
      then
        BackendDAE.COMPLEX_EQUATION(size, inExp1, inExp2, source, inEqAttributes)::inEqns;

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
        BackendDAE.EQUATION(inExp1, inExp2, source, inEqAttributes)::inEqns;
    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.lowerExtendedRecordEqn failed on: " + ExpressionDump.printExpStr(inExp1) + " = " + ExpressionDump.printExpStr(inExp2) + "\n");
      then
        fail();
  end matchcontinue;
end lowerExtendedRecordEqn;

protected function lowerArrayEqn "author: Frenkel TUD 2012-06"
  input DAE.Dimensions dims;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes inEqAttributes;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> outEqsLst;
algorithm
  outEqsLst := matchcontinue (dims, e1, e2, source, inEqAttributes, iAcc)
    local
      list<DAE.Exp> ea1, ea2;
      list<Integer> ds;
      DAE.Type tp;
      Integer i;

    // array type with record
    case (_, _, _, _, _, _)
      equation
        tp = Expression.typeof(e1);
        tp = DAEUtil.expTypeElementType(tp);
        true = DAEUtil.expTypeComplex(tp);
        i = Expression.sizeOf(tp);
        ds = Expression.dimensionsSizes(dims);
        ds = List.map1(ds, intMul, i);
        //For COMPLEX_EQUATION
        //i = List.fold(ds, intMul, 1);
      then BackendDAE.ARRAY_EQUATION(ds, e1, e2, source, inEqAttributes)::iAcc;

    case (_, _, _, _, _, _)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);
      then generateEquations(ea1, ea2, source, inEqAttributes, iAcc);

    case (_, _, _, _, _, _)
      equation
        ds = Expression.dimensionsSizes(dims);
      then BackendDAE.ARRAY_EQUATION(ds, e1, e2, source, inEqAttributes)::iAcc;
  end matchcontinue;
end lowerArrayEqn;

protected function generateEquations "author: Frenkel TUD 2012-06"
  input list<DAE.Exp> iE1lst;
  input list<DAE.Exp> iE2lst;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes inEqAttributes;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oEqns;
algorithm
  oEqns := match(iE1lst, iE2lst, source, inEqAttributes, iAcc)
    local
      DAE.Exp e1, e2;
      list<DAE.Exp> e1lst, e2lst;
    case ({}, {}, _, _, _) then iAcc;
    case (e1::e1lst, e2::e2lst, _, _, _)
      then generateEquations(e1lst, e2lst, source, inEqAttributes, BackendDAE.EQUATION(e1, e2, source, inEqAttributes)::iAcc);
  end match;
end generateEquations;

protected function createWhenClock
  input Integer whenClkCnt;
  input DAE.Exp e;
  input list<BackendDAE.Equation> inEqs;
  input list<BackendDAE.Var> inVars;
  output list<BackendDAE.Equation> outEqs;
  output list<BackendDAE.Var> outVars;
  output BackendDAE.EquationAttributes outEqAttrs;
protected
  BackendDAE.EquationAttributes eqAttrs;
  DAE.ComponentRef cr;
  BackendDAE.Equation eq;
  BackendDAE.Var var;
algorithm
  cr := DAE.CREF_IDENT(BackendDAE.WHENCLK_PRREFIX + intString(whenClkCnt), DAE.T_CLOCK_DEFAULT, {});
  outVars := BackendDAE.VAR (
                  varName = cr, varKind = BackendDAE.VARIABLE(),
                  varDirection = DAE.BIDIR(), varParallelism = DAE.NON_PARALLEL(),
                  varType = DAE.T_CLOCK_DEFAULT, bindExp = NONE(), tplExp = NONE(),
                  arryDim = {}, source = DAE.emptyElementSource,
                  values = NONE(), tearingSelectOption = SOME(BackendDAE.DEFAULT()), hideResult = DAE.BCONST(false),
                  comment = NONE(), connectorType = DAE.NON_CONNECTOR(),
                  innerOuter = DAE.NOT_INNER_OUTER(), unreplaceable = true ) :: inVars;
  outEqs := BackendDAE.EQUATION( exp = DAE.CREF(componentRef = cr, ty = DAE.T_CLOCK_DEFAULT),
                                scalar = e,  source = DAE.emptyElementSource,
                                attr = BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC ) :: inEqs;
  outEqAttrs := BackendEquation.defaultClockedEqAttr(whenClkCnt);
end createWhenClock;


protected function lowerWhenEqn
"This function lowers a when eqn."
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEquationLst;
  input list<BackendDAE.Equation> inREquationLst;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.Equation> outREquationLst;
protected
  //Inline.Functiontuple fns = (SOME(functionTree), {DAE.NORM_INLINE()});
algorithm
  (outEquationLst, outREquationLst):= matchcontinue inElement
    local
      list<BackendDAE.Equation> res, rEqns;
      list<BackendDAE.Equation> trueEqnLst, elseEqnLst;
      list<BackendDAE.Equation> trueREqns, elseREqnLst;
      DAE.Exp cond;
      list<DAE.Element> eqnl;
      DAE.Element elsePart;
      String  str;
      DAE.ElementSource source;

    case DAE.WHEN_EQUATION(condition = cond, equations = eqnl, elsewhen_ = NONE(), source = source)
      equation
        (DAE.PARTIAL_EQUATION(cond), _) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(cond),source);
        (res, rEqns) = lowerWhenEqn2(listReverse(eqnl), cond, functionTree, {}, {});
        res = mergeWhenEqns(inEquationLst, res, {});
        rEqns = mergeWhenEqns(inREquationLst, rEqns, {});
      then
        (res, rEqns);


    case DAE.WHEN_EQUATION(condition = cond, equations = eqnl, elsewhen_ = SOME(elsePart), source = source)
      equation
        (DAE.PARTIAL_EQUATION(cond), _) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(cond),source);
        (trueEqnLst, trueREqns) = lowerWhenEqn2(listReverse(eqnl), cond, functionTree, {}, {});
        res = mergeWhenEqns(inEquationLst, trueEqnLst, {});
        rEqns = mergeWhenEqns(inREquationLst, trueREqns, {});
        (res, rEqns) = lowerWhenEqn(elsePart, functionTree, res, rEqns);
      then
        (res, rEqns);

    else
      equation
        source = ElementSource.getElementSource(inElement);
        str = "BackendDAECreate.lowerWhenEqn: equation not handled:\n" +
              DAEDump.dumpElementsStr({inElement});
        Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, ElementSource.getElementSourceFileInfo(source));
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
  input list<BackendDAE.Equation> iREquationLst;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.Equation> outREquationLst;
protected
  //Inline.Functiontuple fns = (SOME(functionTree), {DAE.NORM_INLINE()});
algorithm
  (outEquationLst, outREquationLst) := matchcontinue inDAEElementLst
    local
      Integer size;
      list<BackendDAE.Equation> eqnl;
      list<BackendDAE.Equation> reqnl;
      DAE.Exp cre, e, lhs, cond, level;
      DAE.ComponentRef cr, cr2;
      list<DAE.Element> xs, eqns;
      DAE.Element el;
      DAE.ElementSource source;
      DAE.Dimensions ds;
      DAE.Statement stmt;
      DAE.Type ty;
      list<DAE.Exp> expl;
      list<list<DAE.Element>> eqnslst;
      Absyn.Path functionName;
      HashTableCrToExpSourceTpl.HashTable ht;
      list<tuple<DAE.ComponentRef, tuple<DAE.Exp, DAE.ElementSource>>> crexplst;
      list<DAE.Statement> assrtLst;
      BackendDAE.Equation eq;
      BackendDAE.WhenEquation whenEq;
      BackendDAE.WhenOperator whenOp;

    case {} then (iEquationLst, iREquationLst);
    case DAE.EQUEQUATION(cr1 = cr, cr2 = cr2, source = source)::xs
      equation
        e = Expression.crefExp(cr2);
        whenOp = BackendDAE.ASSIGN(Expression.crefExp(cr), e, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
        eq = BackendDAE.WHEN_EQUATION(1, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eq::iEquationLst, iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.DEFINE(componentRef = cr, exp = e, source = source)::xs
      equation
        (e, _) = ExpressionSolve.solve(Expression.crefExp(cr), e, Expression.crefExp(cr));
        (DAE.PARTIAL_EQUATION(e), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(e),source);
        whenOp = BackendDAE.ASSIGN(Expression.crefExp(cr), e, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
        eq = BackendDAE.WHEN_EQUATION(1, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eq::iEquationLst, iREquationLst);
      then
        (eqnl, reqnl);

    // if a function call includes external functions, it is not allowed to expand the left hand side since the call will be evaluated multiple times. That's an unintended behaviour.
    case DAE.EQUATION(exp = lhs as DAE.TUPLE(), scalar = e as DAE.CALL(_), source = source)::xs
      equation
        //print("Do not lower equations with function calls that solve tuples "+DAEDump.dumpEquationStr(listHead(inDAEElementLst))+"\n");
        ty = Expression.typeof(lhs);
        size = Expression.sizeOf(ty);
        eq = BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_STMTS(inCond, {BackendDAE.ASSIGN(lhs, e, source)},NONE()), source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        eqnl = eq::iEquationLst;
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.EQUATION(exp = DAE.TUPLE(PR=expl), scalar = e, source = source)::xs
      equation
        eqnl = lowerWhenTupleEqn(expl, inCond, e, source, 1, iEquationLst);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iREquationLst);
      then
        (eqnl, reqnl);

    case (el as DAE.EQUATION(exp = (cre as DAE.CREF()), scalar = e, source = source))::xs algorithm
      try
        e := ExpressionSolve.solve(cre, e, cre);
      else
        Error.addCompilerError("Failed to solve " + DAEDump.dumpElementsStr({el}));
        fail();
      end try;
      (DAE.PARTIAL_EQUATION(e), source) := ExpressionSimplify.simplifyAddSymbolicOperation(DAE.PARTIAL_EQUATION(e),source);
      whenOp := BackendDAE.ASSIGN(cre, e, source);
      whenEq := BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
      eq := BackendDAE.WHEN_EQUATION(1, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
      (eqnl, reqnl) := lowerWhenEqn2(xs, inCond, functionTree, eq::iEquationLst, iREquationLst);
    then (eqnl, reqnl);

    case DAE.COMPLEX_EQUATION(lhs = (cre as DAE.CREF()), rhs = e, source = source)::xs
      equation
        (DAE.EQUALITY_EXPS(_,e), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(cre,e),source);
        size = Expression.sizeOf(Expression.typeof(cre));
        whenOp = BackendDAE.ASSIGN(cre, e, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
        eq = BackendDAE.WHEN_EQUATION(size, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eq::iEquationLst, iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.COMPLEX_EQUATION(lhs = cre as DAE.TUPLE(PR=expl), rhs = e, source = source)::xs
      equation
        (DAE.EQUALITY_EXPS(_,e), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(cre,e),source);
        eqnl = lowerWhenTupleEqn(expl, inCond, e, source, 1, iEquationLst);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.IF_EQUATION(condition1=expl, equations2=eqnslst, equations3=eqns, source = source)::xs
      equation
        //(expl, source, _) = Inline.inlineExps(expl, fns, source);
        // transform if eqution
        // if .. then a=.. elseif .. then a=... else a=.. end if;
        // to
        // a=if .. then .. else if .. then else ..;
        ht = HashTableCrToExpSourceTpl.emptyHashTable();
        ht = lowerWhenIfEqnsElse(eqns, functionTree, ht);
        ht = lowerWhenIfEqns(listReverse(expl), listReverse(eqnslst), functionTree, ht);
        crexplst = BaseHashTable.hashTableList(ht);
        eqnl = lowerWhenIfEqns2(crexplst, inCond, source, iEquationLst);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.ARRAY_EQUATION(dimension=ds, exp = (cre as DAE.CREF()), array = e, source = source)::xs
      equation
        (DAE.EQUALITY_EXPS(_,e), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(cre,e),source);
        size = List.fold(Expression.dimensionsSizes(ds), intMul, 1);
        whenOp = BackendDAE.ASSIGN(cre, e, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
        eq = BackendDAE.WHEN_EQUATION(size, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eq::iEquationLst, iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.ARRAY_EQUATION(exp = cre as DAE.TUPLE(PR=expl), array = e, source = source)::xs
      equation
        (DAE.EQUALITY_EXPS(_,e), source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(cre,e),source);
        eqnl = lowerWhenTupleEqn(expl, inCond, e, source, 1, iEquationLst);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, eqnl, iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.ASSERT(condition=cond, message = e, level = level, source = source)::xs
      equation
        whenOp = BackendDAE.ASSERT(cond, e, level, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
        eq = BackendDAE.WHEN_EQUATION(0, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, eq::iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.REINIT(componentRef = cr, exp = e, source = source)::xs
      equation
        whenOp = BackendDAE.REINIT(cr, e, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
        eq = BackendDAE.WHEN_EQUATION(0, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, eq::iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.TERMINATE(message = e, source = source)::xs
      equation
        whenOp = BackendDAE.TERMINATE(e, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
        eq = BackendDAE.WHEN_EQUATION(0, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, eq::iREquationLst);
      then
        (eqnl, reqnl);

    case DAE.NORETCALL(exp=e, source=source)::xs
      equation
        whenOp = BackendDAE.NORETCALL(e, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
        eq = BackendDAE.WHEN_EQUATION(0, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, eq::iREquationLst);
      then
        (eqnl, reqnl);

    // failure
    case el::_
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.lowerWhenEqn2 failed on:" + DAEDump.dumpElementsStr({el}));
      then
        fail();

    // adrpo: 2010-09-26
    // allow to continue when checking the model
    // just ignore this equation.
    case _::xs
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        (eqnl, reqnl) = lowerWhenEqn2(xs, inCond, functionTree, iEquationLst, iREquationLst);
      then
        (eqnl, reqnl);
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
      BackendDAE.WhenEquation whenEq;
      BackendDAE.WhenOperator whenOp;

    case ({}, _, _, _, _, _) then iEquationLst;
    case (DAE.CREF(componentRef = cr, ty=ty)::rest, _, _, _, _, _)
      equation
        size = Expression.sizeOf(ty);
        whenOp = BackendDAE.ASSIGN(Expression.crefExp(cr), DAE.TSUB(e, i, ty), source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
      then
        lowerWhenTupleEqn(rest, inCond, e, source, i+1, BackendDAE.WHEN_EQUATION(size, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC) ::iEquationLst);
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
      BackendDAE.WhenEquation whenEq;
      BackendDAE.WhenOperator whenOp;

    case ({}, _, _, _)
      then
        inEqns;
    case ((cr, (e, source))::rest, _, _, _)
      equation
        source = ElementSource.mergeSources(iSource, source);
        size = Expression.sizeOf(Expression.typeof(e));
        whenOp = BackendDAE.ASSIGN(Expression.crefExp(cr), e, source);
        whenEq = BackendDAE.WHEN_STMTS(inCond, {whenOp}, NONE());
      then
       lowerWhenIfEqns2(rest, inCond, iSource, BackendDAE.WHEN_EQUATION(size, whenEq, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::inEqns);
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
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = ElementSource.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.DEFINE(componentRef=cr, exp=e, source=source)::rest, _, _)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = ElementSource.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e, source=source)::rest, _, _)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = ElementSource.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.COMPLEX_EQUATION(lhs=DAE.CREF(componentRef=cr), rhs=e, source=source)::rest, _, _)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = ElementSource.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.ARRAY_EQUATION(exp=DAE.CREF(componentRef=cr), array=e, source=source)::rest, _, _)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ((exp, source1)) = BaseHashTable.get(cr, iHt);
        exp = DAE.IFEXP(condition, e, exp);
        source = ElementSource.mergeSources(source, source1);
        ht = BaseHashTable.add((cr, (exp, source)), iHt);
      then
        lowerWhenIfEqns1(condition, rest, functionTree, ht);
    case (_, DAE.IF_EQUATION(condition1=expl, equations2=eqnslst, equations3=eqns, source = source)::rest, _, _)
      equation
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
        source = ElementSource.mergeSources(iSource, source);
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
    case (DAE.EQUEQUATION(cr1=cr, cr2=cr2, source=source)::rest, _, _) guard not BaseHashTable.hasKey(cr, iHt)
      equation
        e = Expression.crefExp(cr2);
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.DEFINE(componentRef=cr, exp=e, source=source)::rest, _, _) guard not BaseHashTable.hasKey(cr, iHt)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.EQUATION(exp=DAE.CREF(componentRef=cr), scalar=e, source=source)::rest, _, _) guard not BaseHashTable.hasKey(cr, iHt)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.COMPLEX_EQUATION(lhs=DAE.CREF(componentRef=cr), rhs=e, source=source)::rest, _, _) guard not BaseHashTable.hasKey(cr, iHt)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.ARRAY_EQUATION(exp=DAE.CREF(componentRef=cr), array=e, source=source)::rest, _, _) guard not BaseHashTable.hasKey(cr, iHt)
      equation
        false = Expression.expHasCrefNoPreorDer(e, cr);
        ht = BaseHashTable.add((cr, (e, source)), iHt);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
    case (DAE.IF_EQUATION(condition1=expl, equations2=eqnslst, equations3=eqns)::rest, _, _)
      equation
        ht = lowerWhenIfEqnsElse(eqns, functionTree, iHt);
        ht = lowerWhenIfEqns(listReverse(expl), listReverse(eqnslst), functionTree, ht);
      then
        lowerWhenIfEqnsElse(rest, functionTree, ht);
  end match;
end lowerWhenIfEqnsElse;

protected function mergeWhenEqns
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
      DAE.Exp cond;
      BackendDAE.Equation res, inEqn;
      list<BackendDAE.Equation> trueEqns, elseEqnsRest, result;
      DAE.ElementSource source;
      Integer size;
      BackendDAE.EquationAttributes attr;
      list<BackendDAE.WhenOperator> whenStmtLst;
      BackendDAE.WhenEquation whenEq, whenEqRes;
      Option<BackendDAE.WhenEquation> whenElsePart;
      Boolean added;

    case ({}, {}, _)
    then inEquationLst;

    case (_, {}, {})
    then trueEqnList;

    case ({}, _, {})
    then elseEqnList;

    case ({}, _, _)
    then listAppend(inEquationLst, elseEqnList);

    case (_, {}, _)
    then listAppend(inEquationLst, trueEqnList);

    case ((inEqn as BackendDAE.WHEN_EQUATION(size=size, whenEquation=(whenEq as BackendDAE.WHEN_STMTS(condition=cond, whenStmtLst = whenStmtLst, elsewhenPart=whenElsePart)), source=source, attr=attr))::trueEqns, _, _)
      algorithm
        //print(" Start mergeWhen: \n" + BackendDump.equationString(inEqn) + "\n");
        result := inEquationLst;
        elseEqnsRest := {};
        added := false;
        for eqn in elseEqnList loop
          //print(" check when equation: \n" + BackendDump.equationString(eqn) + "\n");
          _ := match eqn
            local
              BackendDAE.WhenEquation eq;
              list<BackendDAE.WhenOperator> whenStmtLst2;
            case BackendDAE.WHEN_EQUATION(whenEquation=eq as BackendDAE.WHEN_STMTS(whenStmtLst=whenStmtLst2) ) algorithm
              for elem in whenStmtLst loop
                _ := match elem
                  local
                    DAE.ComponentRef crleft;
                    DAE.Exp eleft;
                  case BackendDAE.ASSIGN(left=eleft) algorithm
                    for stmt in whenStmtLst2 loop
                      _ := matchcontinue stmt
                        local
                          DAE.Exp eleft2;
                        case BackendDAE.ASSIGN(left=eleft2) equation
                          true = Expression.expEqual(eleft, eleft2);
                          //print(" added when else case: \n" + BackendDump.whenEquationString(eq, true) + "\n");
                          whenEqRes = BackendEquation.setWhenElsePart(whenEq, eq);
                          res = BackendDAE.WHEN_EQUATION(size, whenEqRes, source, attr);
                          result = res::result;
                          added = true;
                        then ();
                        else equation
                          elseEqnsRest = eqn::elseEqnsRest;
                        then ();
                      end matchcontinue;
                    end for;
                  then ();
                  case BackendDAE.REINIT(stateVar=crleft) algorithm
                    for stmt in whenStmtLst2 loop
                      _ := matchcontinue stmt
                        local
                          DAE.ComponentRef crleft2;
                        case BackendDAE.REINIT(stateVar=crleft2) equation
                          true = ComponentReference.crefEqualNoStringCompare(crleft, crleft2);
                          //print(" added when else case: \n" + BackendDump.whenEquationString(eq, true) + "\n");
                          whenEqRes = BackendEquation.setWhenElsePart(whenEq, eq);
                          res = BackendDAE.WHEN_EQUATION(size, whenEqRes, source, attr);
                          result = res::result;
                          added = true;
                        then ();
                        else equation
                          elseEqnsRest = eqn::elseEqnsRest;
                        then ();
                      end matchcontinue;
                    end for;
                  then ();
                  else equation
                    whenEqRes = BackendEquation.setWhenElsePart(whenEq, eq);
                    res = BackendDAE.WHEN_EQUATION(size, whenEqRes, source, attr);
                    result = res::result;
                    added = true;
                  then ();
                end match;
              end for;
            then ();
            else equation
              res = BackendDAE.WHEN_EQUATION(size, BackendDAE.WHEN_STMTS(cond, whenStmtLst, whenElsePart), source, attr);
              result = res::result;
            then ();
          end match;
        end for;
        if not added then
          result := inEqn::result;
        end if;
        //print("Result: :\n");
        //BackendDump.printEquationList(result);
        result := mergeWhenEqns(trueEqns, elseEqnsRest, result);
      then result;

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAECreate.mergeWhenEqns: Error in mergeWhenEqns."});
    then fail();
  end matchcontinue;
end mergeWhenEqns;

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
        (DAE.EQUALITY_EXPS(target,source), eq_source) = ExpressionSimplify.simplifyAddSymbolicOperation(DAE.EQUALITY_EXPS(target,source),inEq_source);
        eqns = lowerExtendedRecordEqn(target, source, inEq_source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN, funcs, iEqns);
      then
        lowerTupleAssignment(rest_targets, rest_sources, eq_source, funcs, eqns);
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
  input Boolean inInitialization;
  output list<BackendDAE.Equation> outEquations;
  output list<BackendDAE.Equation> outREquations;
  output list<BackendDAE.Equation> outIEquations;
algorithm
  (outEquations, outREquations, outIEquations) :=  matchcontinue (inElement)
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
      list<BackendDAE.Equation> eqns, reqns, ieqns;
      list<DAE.Statement> assrtLst;
      BackendDAE.EquationAttributes eqAttributes = if inInitialization then BackendDAE.EQ_ATTR_DEFAULT_INITIAL else BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC;

    // skip empty algorithms
    case DAE.ALGORITHM(algorithm_=DAE.ALGORITHM_STMTS(statementLst={}))
    then (inEquations, inREquations, inIEquations);

    // skip empty initial algorithms
    case DAE.INITIALALGORITHM(algorithm_=DAE.ALGORITHM_STMTS(statementLst={}))
    then (inEquations, inREquations, inIEquations);

    case DAE.ALGORITHM(algorithm_=alg, source=source) equation
      // calculate the size of the algorithm by collecting the left hand sites of the statemens
      crefLst = CheckModel.checkAndGetAlgorithmOutputs(alg, source, inCrefExpansion);
      size = listLength(crefLst);
      if inInitialization then
        ieqns = BackendDAE.ALGORITHM(size, alg, source, inCrefExpansion, eqAttributes) :: inIEquations;
        eqns = inEquations;
        reqns = inREquations;
      else
        (eqns, reqns) = List.consOnBool(intGt(size, 0), BackendDAE.ALGORITHM(size, alg, source, inCrefExpansion, eqAttributes), inEquations, inREquations);
        ieqns = inIEquations;
      end if;
    then (eqns, reqns, ieqns);

    case DAE.INITIALALGORITHM(algorithm_=alg, source=source) equation
      // calculate the size of the algorithm by collecting the left hand sites of the statemens
      crefLst = CheckModel.checkAndGetAlgorithmOutputs(alg, source, inCrefExpansion);
      size = listLength(crefLst);
    then (inEquations, inREquations, BackendDAE.ALGORITHM(size, alg, source, inCrefExpansion, eqAttributes)::inIEquations);

    // skip asserts with condition=true
    case DAE.ASSERT(condition=DAE.BCONST(true))
    then (inEquations, inREquations, inIEquations);

    case DAE.INITIAL_ASSERT(condition=DAE.BCONST(true))
    then (inEquations, inREquations, inIEquations);

    case DAE.ASSERT(condition=cond, message=msg, level=level, source=source) equation
      BackendDAEUtil.checkAssertCondition(cond, msg, level, ElementSource.getElementSourceFileInfo(source));
      alg = DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond, msg, level, source)});
      if inInitialization then
        reqns = inREquations;
        ieqns = BackendDAE.ALGORITHM(0, alg, source, inCrefExpansion, eqAttributes)::inIEquations;
      else
        reqns = BackendDAE.ALGORITHM(0, alg, source, inCrefExpansion, eqAttributes)::inREquations;
        ieqns = inIEquations;
      end if;
    then (inEquations, reqns, ieqns);

    case DAE.INITIAL_ASSERT(condition=cond, message=msg, level=level, source=source) equation
      BackendDAEUtil.checkAssertCondition(cond, msg, level, ElementSource.getElementSourceFileInfo(source));
      alg = DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond, msg, level, source)});
    then (inEquations, inREquations, BackendDAE.ALGORITHM(0, alg, source, inCrefExpansion, BackendDAE.EQ_ATTR_DEFAULT_INITIAL)::inIEquations);

    case DAE.TERMINATE(message=msg, source=source)
    then (inEquations, BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg, source)}), source, inCrefExpansion, eqAttributes)::inREquations, inIEquations);

    case DAE.INITIAL_TERMINATE(message=msg, source=source)
    then (inEquations, inREquations, BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg, source)}), source, inCrefExpansion, eqAttributes)::inIEquations);

    case DAE.NORETCALL(exp=e, source=source) equation
      alg = DAE.ALGORITHM_STMTS({DAE.STMT_NORETCALL(e, source)});
    then (inEquations, BackendDAE.ALGORITHM(0, alg, source, inCrefExpansion, eqAttributes)::inREquations, inIEquations);

    case DAE.INITIAL_NORETCALL(exp=e, source=source) equation
      alg = DAE.ALGORITHM_STMTS({DAE.STMT_NORETCALL(e, source)});
    then (inEquations, inREquations, BackendDAE.ALGORITHM(0, alg, source, inCrefExpansion, eqAttributes)::inIEquations);

    else equation
      // only report error if no other error is in the queue!
      0 = Error.getNumErrorMessages();
      str = "BackendDAECreate.lowerAlgorithm failed for:\n" + DAEDump.dumpElementsStr({inElement});
      Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, ElementSource.getElementSourceFileInfo(ElementSource.getElementSource(inElement)));
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
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input list<BackendDAE.Equation> iEqns;
  input list<BackendDAE.Equation> iREqns;
  input list<BackendDAE.Equation> iIEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables outGlobalKnownVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output list<BackendDAE.Equation> oEqns;
  output list<BackendDAE.Equation> oREqns;
  output list<BackendDAE.Equation> oIEqns;
algorithm
  (oVars, outGlobalKnownVars, oExtVars, oAVars, oEqns, oREqns, oIEqns) :=
  match (iAliasEqns, iVars, inGlobalKnownVars, iExtVars, iAVars, iEqns, iREqns, iIEqns)
    local
      BackendDAE.Variables vars, globalKnownVars, extvars, avars;
      list<BackendDAE.Equation> eqns, reqns, ieqns;
    case ({}, _, _, _, _, _, _, _) then (iVars, inGlobalKnownVars, iExtVars, iAVars, iEqns, iREqns, iIEqns);
    case (_, _, _, _, _, _, _, _)
      equation
        (vars, globalKnownVars, extvars, avars, eqns, reqns, ieqns) = handleAliasEquations1(iAliasEqns, iVars, inGlobalKnownVars, iExtVars, iAVars, iEqns, iREqns, iIEqns);
      then
        (vars, globalKnownVars, extvars, avars, eqns, reqns, ieqns);
  end match;
end handleAliasEquations;

protected function handleAliasEquations1
"author Frenkel TUD 2012-09"
  input list<DAE.Element> iAliasEqns;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input list<BackendDAE.Equation> iEqns;
  input list<BackendDAE.Equation> iREqns;
  input list<BackendDAE.Equation> iIEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables outGlobalKnownVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output list<BackendDAE.Equation> oEqns;
  output list<BackendDAE.Equation> oREqns;
  output list<BackendDAE.Equation> oIEqns;
protected
  BackendVarTransform.VariableReplacements repl;
algorithm
  repl := BackendVarTransform.emptyReplacements();
  // get alias vars and replacements
  (oVars, outGlobalKnownVars, oExtVars, oAVars, repl, oEqns) := handleAliasEquations2(iAliasEqns, iVars, inGlobalKnownVars, iExtVars, iAVars, repl, iEqns);
  // replace alias bindings
  (oAVars, _) := BackendVariable.traverseBackendDAEVarsWithUpdate(oAVars, replaceAliasVarTraverser, repl);
  // compress vars array
  oVars := BackendVariable.rehashVariables(oVars);
  // perform replacements
  (oEqns, _) := BackendVarTransform.replaceEquations(oEqns, repl, NONE());
  (oREqns, _) := BackendVarTransform.replaceEquations(iREqns, repl, NONE());
  (oIEqns, _) := BackendVarTransform.replaceEquations(iIEqns, repl, NONE());
end handleAliasEquations1;

protected function replaceAliasVarTraverser
  input BackendDAE.Var inVar;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendDAE.Var outVar;
  output BackendVarTransform.VariableReplacements repl;
algorithm
  (outVar,repl) := matchcontinue (inVar,inRepl)
    local
      BackendDAE.Var v, v1;
      DAE.Exp e, e1;
      Boolean b;
    case (v as BackendDAE.VAR(bindExp=SOME(e)), repl)
      equation
        (e1, true) = BackendVarTransform.replaceExp(e, repl, NONE());
        b = Expression.isConst(e1);
        v1 = if not b then BackendVariable.setBindExp(v, SOME(e1)) else v;
      then (v1, repl);
    else (inVar,inRepl);
  end matchcontinue;
end replaceAliasVarTraverser;

protected function handleAliasEquations2
"author Frenkel TUD 2012-09"
  input list<DAE.Element> iAliasEqns;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input BackendVarTransform.VariableReplacements iRepl;
  input list<BackendDAE.Equation> iEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables outGlobalKnownVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output list<BackendDAE.Equation> oEqns;
algorithm
  (oVars, outGlobalKnownVars, oExtVars, oAVars, oRepl, oEqns) := match (iAliasEqns, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns)
    local
      BackendDAE.Variables vars, globalKnownVars, extvars, avars;
      list<DAE.Element> aliaseqns;
      BackendVarTransform.VariableReplacements repl;
      DAE.ComponentRef cr1, cr2;
      DAE.ElementSource source;
      list<BackendDAE.Equation> eqns;
      DAE.Exp ecr1, ecr2;
    case ({}, _, _, _, _, _, _) then (iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
    case (DAE.EQUEQUATION(cr1=cr1, cr2=cr2, source=source)::aliaseqns, _, _, _, _, _, _)
      equation
        // perform replacements
        ecr1 = Expression.crefExp(cr1);
        (ecr1, _) = BackendVarTransform.replaceExp(ecr1, iRepl, NONE());
        ecr2 = Expression.crefExp(cr2);
        (ecr2, _) = BackendVarTransform.replaceExp(ecr2, iRepl, NONE());
        // select alias
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAlias(ecr1, ecr2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
        // next
        (vars, globalKnownVars, extvars, avars, repl, eqns) = handleAliasEquations2(aliaseqns, vars, globalKnownVars, extvars, avars, repl, eqns);
      then
        (vars, globalKnownVars, extvars, avars, repl, eqns);
  end match;
end handleAliasEquations2;

protected function selectAlias
  input DAE.Exp exp1;
  input DAE.Exp exp2;
  input DAE.ElementSource source;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input BackendVarTransform.VariableReplacements iRepl;
  input list<BackendDAE.Equation> iEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables outGlobalKnownVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output list<BackendDAE.Equation> oEqns;
algorithm
  (oVars, outGlobalKnownVars, oExtVars, oAVars, oRepl, oEqns) := matchcontinue (exp1, exp2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns)
    local
      BackendDAE.Variables vars, globalKnownVars, extvars, avars;
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
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, globalKnownVars, extvars, avars, repl, eqns);
    // cref-array array case
    case (DAE.CREF(componentRef=cr1, ty=DAE.T_ARRAY(dims = dims1)), DAE.ARRAY(array=explst2), _, _, _, _, _, _, _)
      equation
        crefs1 = ComponentReference.expandArrayCref(cr1, dims1);
        explst1 = List.map(crefs1, Expression.crefExp);
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, globalKnownVars, extvars, avars, repl, eqns);
    // array cref-array case
    case (DAE.ARRAY(array=explst1), DAE.CREF(componentRef=cr2, ty=DAE.T_ARRAY(dims = dims2)), _, _, _, _, _, _, _)
      equation
        crefs2 = ComponentReference.expandArrayCref(cr2, dims2);
        explst2 = List.map(crefs2, Expression.crefExp);
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, globalKnownVars, extvars, avars, repl, eqns);
    // cref-array cref-array case
    case (DAE.CREF(componentRef=cr1, ty=DAE.T_ARRAY(dims = dims1)), DAE.CREF(componentRef=cr2, ty=DAE.T_ARRAY(dims = dims2)), _, _, _, _, _, _, _)
      equation
        crefs1 = ComponentReference.expandArrayCref(cr1, dims1);
        explst1 = List.map(crefs1, Expression.crefExp);
        crefs2 = ComponentReference.expandArrayCref(cr2, dims2);
        explst2 = List.map(crefs2, Expression.crefExp);
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, globalKnownVars, extvars, avars, repl, eqns);

    // matrix matrix case
    case (DAE.MATRIX(matrix=explstlst1), DAE.MATRIX(matrix=explstlst2), _, _, _, _, _, _, _)
      equation
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAliasLst(List.flatten(explstlst1), List.flatten(explstlst2), source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, globalKnownVars, extvars, avars, repl, eqns);
    // scalar case
    case (DAE.CREF(componentRef=cr1),
          DAE.CREF(componentRef=cr2), _, _, _, _, _, _, _)
      equation
        (v1, i1, arrayTyp1) = getVar(cr1, iVars, inGlobalKnownVars, iExtVars);
        (v2, i2, arrayTyp2) = getVar(cr2, iVars, inGlobalKnownVars, iExtVars);
        (vars, globalKnownVars, extvars, avars, repl) = selectAliasVar(v1, i1, arrayTyp1, exp1, v2, i2, arrayTyp2, exp2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl);
      then
        (vars, globalKnownVars, extvars, avars, repl, iEqns);
    // complex
    case (_, _, _, _, _, _, _, _, _)
      equation
        // Create a list of crefs from names
        explst1 = Expression.splitRecord(exp1, Expression.typeof(exp1));
        explst2 = Expression.splitRecord(exp2, Expression.typeof(exp2));
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
      then
        (vars, globalKnownVars, extvars, avars, repl, eqns);
    // if no alias selectable add as equation
    case (_, _, _, _, _, _, _, _, _)
      then (iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, BackendDAE.EQUATION(exp1, exp2, source, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC)::iEqns);
  end matchcontinue;
end selectAlias;

protected function getVar
  input DAE.ComponentRef cr;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.Variables iExtVars;
  output BackendDAE.Var oVar;
  output Integer index;
  output Integer varrArray;
algorithm
  (oVar, index, varrArray) := matchcontinue(cr, iVars, inGlobalKnownVars, iExtVars)
    local
      BackendDAE.Var v;
      Integer i;
    case(_, _, _, _)
      equation
        (v, i) = BackendVariable.getVarSingle(cr, iVars);
      then
        (v, i, 1);
    case(_, _, _, _)
      equation
        (v, i) = BackendVariable.getVarSingle(cr, inGlobalKnownVars);
      then
        (v, i, 2);
    case(_, _, _, _)
      equation
        (v, i) = BackendVariable.getVarSingle(cr, iExtVars);
      then
        (v, i, 3);
  end matchcontinue;
end getVar;

protected function selectAliasLst
  input list<DAE.Exp> iexplst1;
  input list<DAE.Exp> iexplst2;
  input DAE.ElementSource source;
  input BackendDAE.Variables iVars;
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input BackendVarTransform.VariableReplacements iRepl;
  input list<BackendDAE.Equation> iEqns;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables outGlobalKnownVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output BackendVarTransform.VariableReplacements oRepl;
  output list<BackendDAE.Equation> oEqns;
algorithm
  (oVars, outGlobalKnownVars, oExtVars, oAVars, oRepl, oEqns) := match (iexplst1, iexplst2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns)
    local
      BackendDAE.Variables vars, globalKnownVars, extvars, avars;
      BackendVarTransform.VariableReplacements repl;
      list<BackendDAE.Equation> eqns;
      DAE.Exp e1, e2;
      list<DAE.Exp> explst1, explst2;
    case ({}, {}, _, _, _, _, _, _, _)
      then
        (iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
    case (e1::explst1, e2::explst2, _, _, _, _, _, _, _)
      equation
        // perform replacements
        (e1, _) = BackendVarTransform.replaceExp(e1, iRepl, NONE());
        (e2, _) = BackendVarTransform.replaceExp(e2, iRepl, NONE());
        // select alias
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAlias(e1, e2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl, iEqns);
        // next
        (vars, globalKnownVars, extvars, avars, repl, eqns) = selectAliasLst(explst1, explst2, source, vars, globalKnownVars, extvars, avars, repl, eqns);
      then
        (vars, globalKnownVars, extvars, avars, repl, eqns);
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
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.Variables iExtVars;
  input BackendDAE.Variables iAVars;
  input BackendVarTransform.VariableReplacements iRepl;
  output BackendDAE.Variables oVars;
  output BackendDAE.Variables outGlobalKnownVars;
  output BackendDAE.Variables oExtVars;
  output BackendDAE.Variables oAVars;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (oVars, outGlobalKnownVars, oExtVars, oAVars, oRepl) :=
   match (v1, index1, arrayIndx1, e1, v2, index2, arrayIndx2, e2, source, iVars, inGlobalKnownVars, iExtVars, iAVars, iRepl)
    local
      BackendDAE.Variables vars, globalKnownVars, extvars, avars;
      BackendVarTransform.VariableReplacements repl;
      list<DAE.SymbolicOperation> ops;
      BackendDAE.Var var, avar;
      DAE.ComponentRef cr1, cr2, acr, cr;
      Integer w1, w2, aindx;
      Boolean b, b1, b2;
      DAE.Exp e, ae;
    // state variable
    case (BackendDAE.VAR(varKind=BackendDAE.STATE()), _, 1, _,
          BackendDAE.VAR(varName=cr2), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        false = BackendVariable.isStateVar(v2);
        replaceableAlias(v2);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v1, v2, false, inGlobalKnownVars);
        // setAliasType
        ops = ElementSource.getSymbolicTransformations(source);
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
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Alias Equation ", cr2, " = ", e1, " found (4).\n");
        end if;
      then
        (vars, inGlobalKnownVars, iExtVars, avars, repl);
    // state variable
    case (BackendDAE.VAR(varName=cr1), _, 1, _,
          BackendDAE.VAR(varKind=BackendDAE.STATE()), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        false = BackendVariable.isStateVar(v1);
        replaceableAlias(v1);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v2, v1, false, inGlobalKnownVars);
        // setAliasType
        ops = ElementSource.getSymbolicTransformations(source);
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
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Alias Equation ", cr1, " = ", e2, " found (4).\n");
        end if;
      then
        (vars, inGlobalKnownVars, iExtVars, avars, repl);
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
        ((acr, avar, aindx, _, _, var, e)) = if b then (cr2, v2, index2, e2, cr1, v1, e1) else (cr1, v1, index1, e1, cr2, v2, e2);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(var, avar, false, inGlobalKnownVars);
        // setAliasType
        ops = ElementSource.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(avar, DAE.SOLVED(acr, e)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e));
        avar = if b1 then BackendVariable.setVarKind(avar, BackendDAE.DUMMY_STATE()) else avar;
        // remove from vars
        (vars, _) = BackendVariable.removeVar(aindx, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to vars
        vars = BackendVariable.addVar(var, vars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, acr, e, NONE());
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Alias Equation ", acr, " = ", e, " found (4).\n");
        end if;
      then
        (vars, inGlobalKnownVars, iExtVars, avars, repl);
    // var/state parameter
    case (BackendDAE.VAR(varName=cr1), _, 1, _,
          BackendDAE.VAR(), _, 2, _, _, _, _, _, _, _)
      equation
        // check if replacable
        replaceableAlias(v1);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v2, v1, false, inGlobalKnownVars);
        // setAliasType
        ops = ElementSource.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v1, DAE.SOLVED(cr1, e2)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e2));
        avar = if BackendVariable.isStateVar(v1) then BackendVariable.setVarKind(avar, BackendDAE.DUMMY_STATE()) else avar;
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index1, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to globalKnownVars
        globalKnownVars = BackendVariable.addVar(var, inGlobalKnownVars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr1, e2, NONE());
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Alias Equation ", cr1, " = ", e2, " found (4).\n");
        end if;
      then
        (vars, globalKnownVars, iExtVars, avars, repl);
    // parameter var/state
    case (BackendDAE.VAR(), _, 2, _,
          BackendDAE.VAR(varName=cr2), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        replaceableAlias(v2);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v1, v2, false, inGlobalKnownVars);
        // setAliasType
        ops = ElementSource.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v2, DAE.SOLVED(cr2, e1)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e1));
        avar = if BackendVariable.isStateVar(v2) then BackendVariable.setVarKind(avar, BackendDAE.DUMMY_STATE()) else avar;
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index2, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to globalKnownVars
        globalKnownVars = BackendVariable.addVar(var, inGlobalKnownVars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr2, e1, NONE());
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Alias Equation ", cr2, " = ", e1, " found (4).\n");
        end if;
      then
        (vars, globalKnownVars, iExtVars, avars, repl);
    // var/state extvar
    case (BackendDAE.VAR(varName=cr1), _, 1, _,
          BackendDAE.VAR(), _, 3, _, _, _, _, _, _, _)
      equation
        // check if replacable
        replaceableAlias(v1);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v2, v1, false, inGlobalKnownVars);
        // setAliasType
        ops = ElementSource.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v1, DAE.SOLVED(cr1, e2)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e2));
        avar = if BackendVariable.isStateVar(v1) then BackendVariable.setVarKind(avar, BackendDAE.DUMMY_STATE()) else avar;
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index1, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to extvars
        extvars = BackendVariable.addVar(var, iExtVars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr1, e2, NONE());
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Alias Equation ", cr1, " = ", e2, " found (4).\n");
        end if;
      then
        (vars, inGlobalKnownVars, extvars, avars, repl);
    // extvar var/state
    case (BackendDAE.VAR(), _, 3, _,
          BackendDAE.VAR(varName=cr2), _, 1, _, _, _, _, _, _, _)
      equation
        // check if replacable
        replaceableAlias(v2);
        // merge fixed, start, nominal
        var = BackendVariable.mergeAliasVars(v1, v2, false, inGlobalKnownVars);
        // setAliasType
        ops = ElementSource.getSymbolicTransformations(source);
        avar = BackendVariable.mergeVariableOperations(v2, DAE.SOLVED(cr2, e1)::ops);
        avar = BackendVariable.setBindExp(avar, SOME(e1));
        avar = if BackendVariable.isStateVar(v2) then BackendVariable.setVarKind(avar, BackendDAE.DUMMY_STATE()) else avar;
        // remove from vars
        (vars, _) = BackendVariable.removeVar(index2, iVars);
        // add to alias
        avars = BackendVariable.addVar(avar, iAVars);
        // add to globalKnownVars
        extvars = BackendVariable.addVar(var, iExtVars);
        // add replacement
        repl = BackendVarTransform.addReplacement(iRepl, cr2, e1, NONE());
        if Flags.isSet(Flags.DEBUG_ALIAS) then
          BackendDump.debugStrCrefStrExpStr("Alias Equation ", cr2, " = ", e1, " found (4).\n");
        end if;
      then
        (vars, inGlobalKnownVars, extvars, avars, repl);
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
  input BackendDAE.Variables inGlobalKnownVars;
  input list<BackendDAE.Equation> inEquationLst;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := List.fold1(inEquationLst, detectImplicitDiscreteFold, inGlobalKnownVars, inVariables);
end detectImplicitDiscrete;

protected function detectImplicitDiscreteFold
"This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inGlobalKnownVars;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inEquation, inGlobalKnownVars, inVariables)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;
      DAE.Exp e;
      list<BackendDAE.Var> vars;
      list<DAE.Statement> statementLst;
      list<BackendDAE.WhenOperator> whenStmts;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_STMTS(whenStmtLst = {BackendDAE.ASSIGN(left=DAE.CREF(componentRef=cr))})), _, _)
      equation
        (vars, _) = BackendVariable.getVar(cr, inVariables);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
      then BackendVariable.addVars(vars, inVariables);
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_STMTS(whenStmtLst = {BackendDAE.ASSIGN(left=e)})), _, _)
      equation
        crefs = Expression.getAllCrefs(e);
        crefs = List.flatten(List.map1(crefs,ComponentReference.expandCref,true));
        (vars, _) = BackendVariable.getVarLst(crefs, inVariables);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
      then BackendVariable.addVars(vars, inVariables);
    case (BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(statementLst = statementLst)), _, _)
      then detectImplicitDiscreteAlgsStatemens(inVariables, inGlobalKnownVars, statementLst, false);
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
  input BackendDAE.Variables inGlobalKnownVars;
  input list<DAE.Statement> inStatementLst;
  input Boolean insideWhen "true if its called from a when statement";
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables, inGlobalKnownVars, inStatementLst, insideWhen)
    local
      BackendDAE.Variables v, v_1, v_2, v_3, globalKnownVars;
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
    case (v, globalKnownVars, ((DAE.STMT_ASSIGN(exp1 = DAE.CREF(componentRef = cr)))::xs), true)
      equation
        ((var::_), _) = BackendVariable.getVar(cr, v);
        var = BackendVariable.setVarKind(var, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVar(var, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, xs, true);
      then
        v_2;

    case (v, globalKnownVars, ((DAE.STMT_ASSIGN(exp1 = DAE.ASUB(exp = DAE.CREF(componentRef = cr), sub= expExpLst)))::xs), true)
      equation
        subs = List.map(expExpLst, Expression.makeIndexSubscript);
        cr = ComponentReference.subscriptCref(cr, subs);
        (vars, _) = BackendVariable.getVar(cr, v);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVars(vars, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, xs, true);
      then
        v_2;

      case(v, globalKnownVars, (DAE.STMT_TUPLE_ASSIGN(expExpLst=expExpLst)::xs), true) equation
        vars = getVarsFromExp(expExpLst, v);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVars(vars, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, xs, true);
      then v_2;

    case (v, globalKnownVars, (DAE.STMT_ASSIGN_ARR(lhs = DAE.CREF(componentRef=cr))::xs), true)
      equation
        (vars, _) = BackendVariable.getVar(cr, v);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVars(vars, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, xs, true);
      then
        v_2;
    case (v, globalKnownVars, (DAE.STMT_IF(statementLst = statementLst)::xs), true)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, globalKnownVars, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, xs, true);
      then
        v_2;
    case (v, globalKnownVars, (DAE.STMT_FOR(type_= tp, iter = iteratorName, range = e, statementLst = statementLst)::xs), true)
      equation
        /* use the range for the componentreferences */
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        iteratorExp = Expression.crefExp(cr);
        iteratorexps = BackendDAEUtil.extendRange(e, globalKnownVars);
        v_1 = detectImplicitDiscreteAlgsStatemensFor(iteratorExp, iteratorexps, v, globalKnownVars, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, xs, true);
      then
        v_2;

/*
    case (v, globalKnownVars, (DAE.STMT_PARFOR(type_= tp, iter = iteratorName, range = e, statementLst = statementLst, loopPrlVars=loopPrlVars)::xs), true)
      equation
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        iteratorExp = Expression.crefExp(cr);
        iteratorexps = BackendDAEUtil.extendRange(e, globalKnownVars);
        v_1 = detectImplicitDiscreteAlgsStatemensFor(iteratorExp, iteratorexps, v, globalKnownVars, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, xs, true);
      then
        v_2;
*/

    case (v, globalKnownVars, (DAE.STMT_WHEN(statementLst=statementLst, elseWhen=NONE())::xs), _)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, globalKnownVars, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, xs, false);
      then
        v_2;
    case (v, globalKnownVars, (DAE.STMT_WHEN(statementLst=statementLst, elseWhen=SOME(statement))::xs), _)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, globalKnownVars, statementLst, true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, globalKnownVars, {statement}, true);
        v_3 = detectImplicitDiscreteAlgsStatemens(v_2, globalKnownVars, xs, false);
      then
        v_3;
    case (v, globalKnownVars, (_::xs), b)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, globalKnownVars, xs, b);
      then
        v_1;
  end matchcontinue;
end detectImplicitDiscreteAlgsStatemens;

protected function detectImplicitDiscreteAlgsStatemensFor
  input DAE.Exp inIteratorExp;
  input list<DAE.Exp> inExplst;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inGlobalKnownVars;
  input list<DAE.Statement> inStatementLst;
  input Boolean insideWhen "true if its called from a when statement";
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inIteratorExp, inExplst, inVariables, inGlobalKnownVars, inStatementLst, insideWhen)
    local
      BackendDAE.Variables v, v_1, v_2, globalKnownVars;
      list<DAE.Statement> statementLst, statementLst1;
      Boolean b;
      DAE.Exp e, ie;
      list<DAE.Exp> rest;

    // case if the loop range can't extend, some vaiables
    case (_, {}, v, globalKnownVars, _, _)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v, globalKnownVars, inStatementLst, true);
      then v_1;
    case (ie, e::{}, v, globalKnownVars, statementLst, _)
      equation
        (statementLst1, _) = DAEUtil.traverseDAEEquationsStmts(statementLst, Expression.replaceExpTpl, ((ie, e)));
        v_1 = detectImplicitDiscreteAlgsStatemens(v, globalKnownVars, statementLst1, true);
      then
        v_1;
    case (ie, e::rest, v, globalKnownVars, statementLst, b)
      equation
        (statementLst1, _) = DAEUtil.traverseDAEEquationsStmts(statementLst, Expression.replaceExpTpl, ((ie, e)));
        v_1 = detectImplicitDiscreteAlgsStatemens(v, globalKnownVars, statementLst1, true);
        v_2 = detectImplicitDiscreteAlgsStatemensFor(ie, rest, v_1, globalKnownVars, statementLst, b);
      then
        v_2;
    case (ie, e::rest, v, globalKnownVars, statementLst, b)
      equation
        (statementLst1, _) = DAEUtil.traverseDAEEquationsStmts(statementLst, Expression.replaceExpTpl, ((ie, e)));
        v_1 = detectImplicitDiscreteAlgsStatemens(v, globalKnownVars, statementLst1, true);
        v_2 = detectImplicitDiscreteAlgsStatemensFor(ie, rest, v_1, globalKnownVars, statementLst, b);
      then
        v_2;
    case (_, _, _, _, _, _)
      equation
        print("BackendDAECreate.detectImplicitDiscreteAlgsStatemensFor failed \n");
      then
        fail();
  end matchcontinue;
end detectImplicitDiscreteAlgsStatemensFor;

protected function renameFunctionParameter"renames the parameters in function calls. the function path is prepended to the parameter cref.
This is used for the Cpp runtime for initializing parameters in function calls. The names have to be unique in case there are equally named parameters in different functions.
author:Waurich TUD 2014-10"
  input DAE.FunctionTree fTreeIn;
  output DAE.FunctionTree fTreeOut;
algorithm
  fTreeOut := matchcontinue(fTreeIn)
    local
      list<tuple<DAE.AvlTreePathFunction.Key,DAE.AvlTreePathFunction.Value>> funcLst;
      DAE.FunctionTree funcs;
  case(_)
    equation
      true = (stringEq(Flags.getConfigString(Flags.SIMCODE_TARGET),"Cpp") or stringEq(Flags.getConfigString(Flags.SIMCODE_TARGET),"omsicpp"));
      funcLst = DAE.AvlTreePathFunction.toList(fTreeIn);
      funcLst = List.map(funcLst,renameFunctionParameter1);
      funcs = DAE.AvlTreePathFunction.addList(DAE.AvlTreePathFunction.new(), funcLst);
    then funcs;
  else
    then fTreeIn;
  end matchcontinue;
end renameFunctionParameter;

protected function renameFunctionParameter1"
author:Waurich TUD 2014-10"
  input tuple<DAE.AvlTreePathFunction.Key,DAE.AvlTreePathFunction.Value> funcIn;
  output tuple<DAE.AvlTreePathFunction.Key,DAE.AvlTreePathFunction.Value> funcOut;
algorithm
  funcOut := matchcontinue(funcIn)
    local
      Boolean pPref;
      Boolean isImpure;
      String pathName;
      Absyn.Path path;
      DAE.AvlTreePathFunction.Key key;
      DAE.ElementSource source;
      DAE.Function func;
      DAE.InlineType iType;
      DAE.Type type_;
      SCode.Visibility vis;
      list<DAE.FunctionDefinition> functions;
      Option<SCode.Comment> comment;
  case((key,SOME(DAE.FUNCTION(path=path,functions=functions,type_=type_,visibility=vis,partialPrefix=pPref,isImpure=isImpure,inlineType=iType,source=source,comment=comment))))
    equation
      pathName = Absyn.pathString(path);
      pathName = Util.stringReplaceChar(pathName,".","_")+"_";
      functions = List.map1(functions,renameFunctionParameter2,pathName);
  then((key,SOME(DAE.FUNCTION(path,functions,type_,vis,pPref,isImpure,iType,source,comment))));
  else
    then funcIn;
  end matchcontinue;
end renameFunctionParameter1;

protected function renameFunctionParameter2"
author:Waurich TUD 2014-10"
  input DAE.FunctionDefinition funcIn;
  input String pathName;
  output DAE.FunctionDefinition funcOut;
algorithm
  funcOut := matchcontinue(funcIn,pathName)
    local
      list<DAE.Element> body, params;
      list<DAE.ComponentRef> crefs, crefs_new;
      list<DAE.Exp> params_new;
      VarTransform.VariableReplacements repl;
   case(DAE.FUNCTION_DEF(body=body),_)
     equation
       params = List.filterOnTrue(body,DAEUtil.isParameter);
       false = listEmpty(params);
       crefs = List.map(params,DAEUtil.varCref);
       crefs_new = List.map1r(crefs,ComponentReference.prependStringCref,pathName);
       params_new = List.map(crefs_new,Expression.crefExp);
       repl = VarTransform.emptyReplacements();
       repl =  VarTransform.addReplacementLst(repl,crefs,params_new);
       (body,_) = DAEUtil.traverseDAEElementList(body,replaceParameters,repl);
     then DAE.FUNCTION_DEF(body);
   else
     then funcIn;
  end matchcontinue;
end renameFunctionParameter2;

protected function replaceParameters"
author:Waurich TUD 2014-10"
  input DAE.Exp inExp;
  input VarTransform.VariableReplacements replIn;
  output DAE.Exp outExp;
  output VarTransform.VariableReplacements replOut;
algorithm
  replOut := replIn;
  (outExp,_) := VarTransform.replaceExp(inExp,replIn,NONE());
end replaceParameters;

annotation(__OpenModelica_Interface="backend");
end BackendDAECreate;

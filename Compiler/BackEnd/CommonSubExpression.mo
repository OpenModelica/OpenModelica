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

encapsulated package CommonSubExpression
" file:        CommonSubExpression.mo
  package:     CommonSubExpression
  description: This package contains functions for the optimization module
               CommonSubExpression."


public import BackendDAE;
public import DAE;

protected import Array;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendDAEOptimize;
protected import BackendVarTransform;
protected import BackendVariable;
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEDump;
protected import DAEUtil;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import Global;
protected import HashTableExpToExp;
protected import HashTableExpToIndex;
protected import HpcOmEqSystems;
protected import HpcOmTaskGraph;
protected import List;
protected import Print;
protected import ResolveLoops;
protected import SynchronousFeatures;
protected import Types;


constant Boolean experimentalB = false; //Experimaental boolean for statistic hashtable
constant Boolean debug = false;


public function wrapFunctionCalls "authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)
main function: is called by postOpt and SymbolicJacobian"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystem syst;
  list<BackendDAE.EqSystem> eqs = {};
  BackendDAE.EquationArray orderedEqs;
  BackendDAE.Shared shared;
  BackendDAE.Variables orderedVars;
  DAE.FunctionTree functionTree;
  HashTableExpToExp.HashTable HT;
  HashTableExpToIndex.HashTable HT2;
  Integer index=System.tmpTickIndex(Global.backendDAE_cseIndex);
  list<BackendDAE.Equation> eqList;
  list<BackendDAE.Var> varList;
  Boolean matchingBoolean = false;
algorithm
  if debug then
    print("\npost-optimization module wrapFunctionCalls (" + BackendDump.printBackendDAEType2String(inDAE.shared.backendDAEType) + "):\n\n");
  end if;

  shared := inDAE.shared;
  BackendDAE.SHARED(functionTree=functionTree) := shared;

  for syst in inDAE.eqs loop
    HT := HashTableExpToExp.emptyHashTableSized(49999);  //2053    4013    25343   536870879
    HT2 := HashTableExpToIndex.emptyHashTableSized(49999);  //2053    4013    25343   536870879
    orderedVars := syst.orderedVars;
    orderedEqs := syst.orderedEqs;

    // dump the EqSystem before the module works (debug dump +d=dumpCSE_verbose)
    if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
      BackendDump.dumpEqSystem(syst, "################EQSYSTEM:###################");
    end if;

    // the module traverses the EqSystem twice
    // the first time the module notices the equations CREF = CALL or CALL = CREF; and creates a statistic if the experimentalB is true
    (orderedEqs, (HT, HT2)) := BackendEquation.traverseEquationArray_WithUpdate(orderedEqs, createStats, (HT, HT2));
    // the second time the module looks for calls and substitutes with cse-variables or with the CREF of the first iteration
    (orderedEqs, (HT, index, eqList, varList, _, matchingBoolean)) := BackendEquation.traverseEquationArray_WithUpdate(orderedEqs, wrapFunctionCalls2, (HT, index, {}, {}, functionTree, matchingBoolean));

    // dump of the hashtable(s) (debug)
    if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
      print("\n");
      BaseHashTable.dumpHashTable(HT);
      if experimentalB then
        print("\n");
        BaseHashTable.dumpHashTable(HT2);
      end if;
    end if;

    // the module has to build a new matching
    if matchingBoolean then
      syst.orderedEqs := BackendEquation.addEquations(eqList, orderedEqs);
      syst.orderedVars := BackendVariable.addVars(varList, orderedVars);
      syst.m := NONE();
      syst.mT := NONE();
      syst.matching := BackendDAE.NO_MATCHING();

      // dump the equations & variables after the module (debug dump +d=dumpCSE or +d=dumpCSE_verbose)
      if Flags.isSet(Flags.DUMP_CSE) or Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        BackendDump.dumpVariables(syst.orderedVars, "########### Updated Variable List (" + BackendDump.printBackendDAEType2String(inDAE.shared.backendDAEType) + ") ###########");
        BackendDump.dumpEquationArray(syst.orderedEqs, "########### Updated Equation List (" + BackendDump.printBackendDAEType2String(inDAE.shared.backendDAEType) + ") ###########");
      end if;
    end if;

    eqs := syst::eqs;
    matchingBoolean := false;
  end for;

  eqs := MetaModelica.Dangerous.listReverseInPlace(eqs);
  System.tmpTickSetIndex(index, Global.backendDAE_cseIndex);
  outDAE := BackendDAE.DAE(eqs, shared);
end wrapFunctionCalls;


protected function wrapFunctionCalls2 "helper function for wrapFunctionCalls; it traverses all equation of the EqSystem"
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean> outTuple;
algorithm
  (outEq, outTuple) := match(inEq)
    local
      Absyn.Path path, path2;
      BackendDAE.Equation eq;
      Boolean b_left, b_right, matchingBoolean;
      DAE.ElementSource source;
      DAE.Exp left, right, exp, scalar;
      DAE.FunctionTree functionTree;
      HashTableExpToExp.HashTable HT;
      Integer index;
      list<BackendDAE.Equation> eqList;
      list<BackendDAE.Var> varList;
      list<DAE.Exp> expLst1, expLst2;
      tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean> tpl;

    //special case for records or tuples of complex-equation
    case BackendDAE.COMPLEX_EQUATION(left=left, right=right) equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("\ntraverse " + BackendDump.equationString(inEq) + " complex\n");
      end if;

      if Expression.isPureCall(left) and Expression.isPureCall(right) then
        (_, _, _ , _, functionTree, _) = inTuple;
        DAE.CALL(path, _, _) = left;
        DAE.CALL(path2, _, _) = right;
        b_left = DAEUtil.funcIsRecord(DAEUtil.getNamedFunction(path, functionTree));
        b_right = DAEUtil.funcIsRecord(DAEUtil.getNamedFunction(path2, functionTree));
        if b_left and b_right then                // RECORD = RECORD
          eq = inEq;
          tpl = inTuple;
        elseif b_left and not b_right then        // RECORD = CALL
          source = BackendEquation.equationSource(inEq);
          (right, (tpl, source)) = wrapFunctionCalls3(right, (inTuple, source));
          eq = BackendEquation.generateEquation(left, right, source, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
        elseif not b_left and b_right then        // CALL = RECORD
          source = BackendEquation.equationSource(inEq);
          (left, (tpl, source)) = wrapFunctionCalls3(left, (inTuple, source));
          eq = BackendEquation.generateEquation(left, right, source, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
        elseif not b_left and not b_right then    // CALL = CALL
          eq = inEq;
          tpl = inTuple;
        end if;

      elseif isRecordExp(left) or isRecordExp(right) then
        source = BackendEquation.equationSource(inEq);
        (left, (tpl, source)) = wrapFunctionCalls3(left, (inTuple, source));
        (right, (tpl, source)) = wrapFunctionCalls3(right, (tpl, source));
        eq = BackendEquation.generateEquation(left, right, source, BackendDAE.EQ_ATTR_DEFAULT_BINDING);

      elseif Expression.isTuple(left) or Expression.isTuple(right) then
        source = BackendEquation.equationSource(inEq);
        (left, (tpl, source)) = wrapFunctionCalls3(left, (inTuple, source));
        (right, (tpl, source)) = wrapFunctionCalls3(right, (tpl, source));
        (HT, index, eqList, varList, functionTree, matchingBoolean) = tpl;
        DAE.TUPLE(expLst1) = left;
        DAE.TUPLE(expLst2) = right;
        eqList = expand(expLst1, expLst2, eqList);
        eq::eqList = eqList;
        matchingBoolean = true;
        tpl = (HT, index, eqList, varList, functionTree, matchingBoolean);
      else
        eq = inEq;
        tpl = inTuple;
      end if;
    then (eq, tpl);

    // case for 'normal' equations
    case BackendDAE.EQUATION(exp=exp, scalar=scalar) equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
         print("\ntraverse " + BackendDump.equationString(inEq) + " normal\n");
      end if;
      (eq, tpl) = wrapFunctionCalls_advanced(exp, scalar, inEq, inTuple);
    then (eq, tpl);

    // case for all other equation: WHEN, IF ...
    else equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("\ntraverse " + BackendDump.equationString(inEq) + " else\n");
      end if;
    then (inEq, inTuple);

  end match;
end wrapFunctionCalls2;


protected function wrapFunctionCalls_advanced "helper function for 'normal' equation"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean> outTuple;
algorithm
  (outEq, outTuple) := matchcontinue(inExp1, inExp2)
  local
    DAE.Exp key, value;
    BackendDAE.Equation eq;
    tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean> tpl;
    Integer index;
    list<BackendDAE.Equation> eqList;
    list<BackendDAE.Var> varList;
    DAE.FunctionTree functionTree;
    HashTableExpToExp.HashTable HT;

    case (DAE.RCONST(0.0), DAE.CALL()) then (inEq, inTuple);
    case (DAE.CALL(), DAE.RCONST(0.0)) then (inEq, inTuple);
    case (_, DAE.CALL(path=Absyn.IDENT("smooth"))) then (inEq, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("smooth")), _) then (inEq, inTuple);
    case (DAE.CREF(), DAE.CALL()) then (inEq, inTuple);
    case (DAE.CALL(), DAE.CREF()) then (inEq, inTuple);
    else equation
      (eq, (tpl, _)) = BackendEquation.traverseExpsOfEquation(inEq, wrapFunctionCalls3, (inTuple, BackendEquation.equationSource(inEq)));
    then (eq, tpl);

  end matchcontinue;
end wrapFunctionCalls_advanced;


protected function wrapFunctionCalls3 "helper function: traverses all Expressions of the equation"
  input DAE.Exp inExp;
  input tuple<tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean>, DAE.ElementSource> inTuple;
  output DAE.Exp outExp;
  output tuple<tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean>, DAE.ElementSource> outTuple;
algorithm
  if Expression.isExpIfExp(inExp) or isSkipCase(inExp) or containsAnySmoothandIfCall(inExp) then //skip IfExp or other cases
    outExp  := inExp;
    outTuple := inTuple;
  else
    (outExp, outTuple) := Expression.traverseExpBottomUp(inExp, wrapFunctionCalls_main, inTuple);
  end if;
end wrapFunctionCalls3;


public function containsAnySmoothandIfCall
  input DAE.Exp inExp;
  output Boolean outContainsCall;
algorithm
  (_, outContainsCall) := Expression.traverseExpTopDown(inExp, containsAnySmoothandIfCall_traverser, false);
end containsAnySmoothandIfCall;


protected function containsAnySmoothandIfCall_traverser
  input DAE.Exp inExp;
  input Boolean inContainsCall;
  output DAE.Exp outExp = inExp;
  output Boolean outContinue;
  output Boolean outContainsCall;
algorithm
  outContainsCall := match inExp
    case DAE.CALL(path=Absyn.IDENT(name="smooth")) then true;
    case DAE.IFEXP() then true;
    else inContainsCall;
  end match;

  outContinue := not outContainsCall;
end containsAnySmoothandIfCall_traverser;


protected function wrapFunctionCalls_main "helper function: traverses all Expressions from Buttom Up"
  input DAE.Exp inExp;
  input tuple<tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean>, DAE.ElementSource> inTuple;
  output DAE.Exp outExp;
  output tuple<tuple<HashTableExpToExp.HashTable, Integer, list<BackendDAE.Equation>, list<BackendDAE.Var>, DAE.FunctionTree, Boolean>, DAE.ElementSource> outTuple;
algorithm
  (outExp, outTuple) := matchcontinue(inExp, inTuple)
    local
      list<BackendDAE.Var> varList;
      list<BackendDAE.Equation> eqList;
      HashTableExpToExp.HashTable HT;
      Integer index;
      DAE.Exp key, value;
      DAE.Type ty;
      BackendDAE.Equation eq;
      DAE.ElementSource source;
      DAE.FunctionTree functionTree;
      Boolean matchingBoolean;

    case (key as DAE.CALL(attr=DAE.CALL_ATTR(ty=ty)), ((HT, index, eqList, varList, functionTree, matchingBoolean), source)) equation
      if isSkipCase(key) then
        value = key;
      else
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
            print("Exp: " + ExpressionDump.dumpExpStr(key, 0) + "\n");
        end if;
        if not BaseHashTable.hasKey(key, HT) then
            (value, index) = createReturnExp(ty, index);
            HT = BaseHashTable.add((key, value), HT);
            varList = createVarsForExp(value, varList);
            eq = BackendEquation.generateEquation(value, key, source, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
            eqList = eq::eqList;
            matchingBoolean = true;
        else
            value = BaseHashTable.get(key, HT);
        end if;
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
            print("  Exp_sub: " + ExpressionDump.printExpStr(value) + "\n");
        end if;
      end if;
    then (value, ((HT, index, eqList, varList, functionTree, matchingBoolean), source));

    else (inExp, inTuple);
  end matchcontinue;
end wrapFunctionCalls_main;


protected function isSkipCase "outline all skip cases"
  input DAE.Exp inCall;
  output Boolean outB;
algorithm
  outB := match(inCall)
    case DAE.CALL(path=Absyn.IDENT("$getPart")) then true;
    case DAE.CALL(path=Absyn.IDENT("pre")) then true;
    case DAE.CALL(path=Absyn.IDENT("previous")) then true;
    case DAE.CALL(path=Absyn.IDENT("change")) then true;
    case DAE.CALL(path=Absyn.IDENT("delay")) then true;
    case DAE.CALL(path=Absyn.IDENT("edge")) then true;
    case DAE.CALL(path=Absyn.IDENT("$_start")) then true;
    case DAE.CALL(path=Absyn.IDENT("$_initialGuess"))  then true;
    case DAE.CALL(path=Absyn.IDENT("initial")) then true;
    case DAE.CALL(path=Absyn.IDENT("$_round")) then true;
    case DAE.CALL(path=Absyn.IDENT("$_old")) then true;
    case DAE.CALL(path=Absyn.IDENT("der")) then true;
    case DAE.CALL(path=Absyn.IDENT("smooth")) then true;
    case DAE.CALL(path=Absyn.IDENT("noEvent")) then true;
    case DAE.CALL(path=Absyn.IDENT("semiLinear")) then true;
    case DAE.CALL(path=Absyn.IDENT("homotopy")) then true;
    case DAE.CALL(path=Absyn.IDENT("reinit")) then true;
    case DAE.CALL(path=Absyn.IDENT("String")) then true;
    case DAE.CALL(path=Absyn.IDENT("interval")) then true;
    case DAE.CALL(path=Absyn.IDENT("Clock")) then true;
    case DAE.CALL(path=Absyn.IDENT("sample")) then true;
    case DAE.CALL(path=Absyn.IDENT("hold")) then true;
    case DAE.CALL(path=Absyn.IDENT("subSample")) then true;
    case DAE.CALL(path=Absyn.IDENT("superSample")) then true;
    case DAE.CALL(path=Absyn.IDENT("shiftSample")) then true;
    case DAE.CALL(path=Absyn.IDENT("backSample")) then true;
    case DAE.CALL(path=Absyn.IDENT("noClock")) then true;
    case DAE.CALL(path=Absyn.IDENT("sign")) then true;
    case _ guard(Expression.isImpureCall(inCall)) then true;
    else false;
  end match;
end isSkipCase;


protected function isRecordExp "helper function for records in complex-equation"
  input DAE.Exp inExp;
  output Boolean outRecord;
algorithm
  outRecord := match inExp
    case DAE.RECORD() then true;
    case DAE.CREF() then ComponentReference.isRecord(inExp.componentRef);
    else false;
  end match;
end isRecordExp;


protected function isCallEqualCref "helper function for creates statistics"
  input DAE.Exp inExp;
  input DAE.Exp inExp2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inExp,inExp2)
    case (DAE.CREF(),DAE.CALL(path=Absyn.IDENT("der"))) then false;
    case (DAE.CALL(path=Absyn.IDENT("der")),DAE.CREF()) then false;
    case (DAE.CREF(),DAE.CALL(path=Absyn.IDENT("smooth"))) then false;
    case (DAE.CALL(path=Absyn.IDENT("smooth")),DAE.CREF()) then false;
    case (DAE.CREF(),DAE.CALL()) then true;
    case (DAE.CALL(),DAE.CREF()) then true;
    else false;
  end matchcontinue;
end isCallEqualCref;


protected function expand
  input list<DAE.Exp> inExpLst1;
  input list<DAE.Exp> inExpLst2;
  input list<BackendDAE.Equation> inEqList;
  output list<BackendDAE.Equation> outEqList;
algorithm
  outEqList := match(inExpLst1, inExpLst2)
    local
      DAE.Exp left, right;
      list<DAE.Exp> expLst1, expLst2;
      BackendDAE.Equation eq;
      list<BackendDAE.Equation> eqList;

      case ((left as DAE.CREF(componentRef=DAE.WILD()))::{}, right::{})
      then inEqList;

      case (left::{}, (right as DAE.CREF(componentRef=DAE.WILD()))::{})
      then inEqList;

      case (left::{}, right::{}) equation
        eq = BackendEquation.generateEquation(left, right, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        eqList = eq::inEqList;
      then eqList;

      case ((left as DAE.CREF(componentRef=DAE.WILD()))::expLst1, right::expLst2) equation
        eqList = expand(expLst1, expLst2, inEqList);
      then eqList;

      case (left::expLst1, (right as DAE.CREF(componentRef=DAE.WILD()))::expLst2) equation
        eqList = expand(expLst1, expLst2, inEqList);
      then eqList;

      case (left::expLst1, right::expLst2) equation
        eq = BackendEquation.generateEquation(left, right, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);
        eqList = eq::inEqList;
        eqList = expand(expLst1, expLst2, eqList);
      then eqList;
  end match;
end expand;


protected function createStats
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable> outTuple;
algorithm
  (outEq, outTuple) := match(inEq)
    local
      DAE.Exp exp, scalar;
      HashTableExpToExp.HashTable HT;
      HashTableExpToIndex.HashTable HT2;

      case BackendDAE.EQUATION(exp=exp, scalar=scalar) equation
        (HT, HT2) = inTuple;
        if isCallEqualCref(exp, scalar) then
          if Expression.isCall(exp) then
            HT = BaseHashTable.add((exp, scalar), HT);
          else
            HT = BaseHashTable.add((scalar, exp), HT);
          end if;
        end if;
        if experimentalB and not isCallEqualCref(exp, scalar) then
          (outEq, outTuple) = BackendEquation.traverseExpsOfEquation(inEq, createStats2, (HT, HT2));
        else
          outEq = inEq;
          outTuple = (HT, HT2);
        end if;
      then (outEq, outTuple);

      else equation
          outEq = inEq;
          outTuple = inTuple;
      then (outEq, outTuple);
  end match;
end createStats;


protected function createStats2 "experimental function for create statistics"
  input DAE.Exp inExp;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable> inTuple;
  output DAE.Exp outExp;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable> outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpBottomUp(inExp, createStats3, inTuple);
end createStats2;


protected function createStats3 "experimental function for create statistics"
  input DAE.Exp inExp;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable> inTuple;
  output DAE.Exp outExp;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable> outTuple;
algorithm
  (outExp, outTuple) := match(inExp, inTuple)
  local
    DAE.Exp key, value;
    Integer counter;
    HashTableExpToExp.HashTable HT;
    HashTableExpToIndex.HashTable HT2;

    case (key, (HT,HT2)) equation
      if BaseHashTable.hasKey(key, HT2) then
        counter = BaseHashTable.get(key, HT2);
        counter = counter + 1;
        BaseHashTable.update((key, counter), HT2);
      else
        counter = 1;
        HT2 = BaseHashTable.add((key, counter), HT2);
      end if;
    then (inExp, (HT,HT2));

  end match;
end createStats3;


protected function createReturnExp
  input DAE.Type inType;
  input Integer inIndex;
  input String inPrefix = "$cse";
  output DAE.Exp outExp;
  output Integer outIndex;
algorithm
  (outExp, outIndex) := match(inType)
    local
      Integer i;
      String str;
      DAE.Exp value;
      DAE.ComponentRef cr;
      list<DAE.Type> typeLst;
      list<DAE.Exp> expLst;
      list<DAE.ComponentRef> crefs;
      Absyn.Path path;
      list<DAE.Var> varLst;
      list<String> varNames;

    case DAE.T_REAL() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_REAL_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_INTEGER() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_INTEGER_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_INTEGER_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_STRING() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_STRING_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_STRING_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_BOOL() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_BOOL_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_BOOL_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_CLOCK() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_CLOCK_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_CLOCK_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_TUPLE(types=typeLst) equation
      (expLst, i) = List.mapFold(typeLst, function createReturnExp(inPrefix=inPrefix), inIndex);
      value = DAE.TUPLE(expLst);
    then (value, i);

    // Expanding
    case DAE.T_ARRAY() equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, inType, {});
      // crefs = ComponentReference.expandCref(cr, false);
      // expLst = List.map(crefs, Expression.crefExp);
      // value = DAE.ARRAY(inType, true, expLst);
          value = DAE.CREF(cr, inType);
    then (value, inIndex + 1);

    // record types
    case DAE.T_COMPLEX(varLst=varLst, complexClassType=ClassInf.RECORD(path)) equation
      str = inPrefix + intString(inIndex);
      cr = DAE.CREF_IDENT(str, inType, {});       //inType?
      // crefs = ComponentReference.expandCref(cr, true);
      // expLst = List.map(crefs, Expression.crefExp);
      // varNames = List.map(varLst, Expression.varName);
      // value = DAE.RECORD(path, expLst, varNames, inType);
      // print("   DAE.T_COMPLEX \n");
          value = DAE.CREF(cr, inType);
    then (value, inIndex + 1);

    else equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("  - createReturnExp failed for " + Types.printTypeStr(inType) + "\n");
      end if;
    then fail();
  end match;
end createReturnExp;


protected function createVarsForExp     //cse in varList
  input DAE.Exp inExp;
  input list<BackendDAE.Var> inAccumVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  (outVarLst) := match (inExp)
    local
      DAE.ComponentRef cr, cr_;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expLst;
      BackendDAE.Var var;
      DAE.Type ty;
      DAE.InstDims arrayDim;
/*
    case DAE.CREF(componentRef=cr) guard(not Expression.isArrayType(Expression.typeof(inExp))
                                         and not Expression.isRecordType(Expression.typeof(inExp))) equation
      // use the correct type when creating var. The cref might have subs.
      var = BackendVariable.createCSEVar(cr, Expression.typeof(inExp));
    then var::inAccumVarLst;
*/
    case DAE.CREF(componentRef=cr, ty = DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_))) algorithm
      // use the correct type when creating var. The cref might have subs.
      crefs := ComponentReference.expandCref(cr, true /*the way it is now we won't get records here. but if we do somehow expand them*/);

      /* Create SimVars from the list of expanded crefs.*/
      /* Mark the first element as an arrayCref i.e. we have 'SOME(arraycref)' since this is how the C template
         detects first elements of arrays to generate VARNAME_indexed(..) macros for accessing the array
         with variable indexes.*/
      outVarLst := inAccumVarLst;
      for cr_ in crefs loop
        arrayDim := ComponentReference.crefDims(cr_);
        outVarLst := BackendVariable.createCSEArrayVar(cr_, ComponentReference.crefTypeFull(cr_), arrayDim)::outVarLst;
      end for;
    then outVarLst;

    case DAE.CREF(componentRef=cr) guard(Expression.isArrayType(Expression.typeof(inExp))) algorithm
      // use the correct type when creating var. The cref might have subs.
      crefs := ComponentReference.expandCref(cr, true);

      outVarLst := inAccumVarLst;
      ty := DAEUtil.expTypeElementType(Expression.typeof(inExp));
      for cr_ in crefs loop
        arrayDim := ComponentReference.crefDims(cr_);
        //expLst := DAE.CREF(cr_, ComponentReference.crefType(cr_))::expLst;
        outVarLst := BackendVariable.createCSEArrayVar(cr_, ty, arrayDim)::outVarLst;
      end for;
      //expLst = list(DAE.CREF(cr_, ComponentReference.crefType(cr_)) for cr_ in crefs);
    then outVarLst;

    case DAE.CREF(componentRef=cr) equation
      // use the correct type when creating var. The cref might have subs.
      var = BackendVariable.createCSEVar(cr, Expression.typeof(inExp));
    then var::inAccumVarLst;

    case DAE.TUPLE(expLst) equation
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    case DAE.ARRAY(array=expLst) equation
      print("This should never appear\n");
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    case DAE.RECORD(exps=expLst) equation
      print("This should never appear\n");
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    // all other are failing cases
    else fail();
  end match;
end createVarsForExp;


public function cseBinary "authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)
  This module eliminates common subexpressions in an acausal environment.
  NOTE: This is currently just an experimental prototype to demonstrate interesting effects."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystemAndFold(inDAE, CSE1, 1);
end cseBinary;

protected function CSE1
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input Integer inIndex;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared = inShared;
  output Integer outIndex;
algorithm
  (outSystem, outIndex) := matchcontinue(inSystem)
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EqSystem syst;
      list<BackendDAE.Var> varList;
      list<BackendDAE.Equation> eqList;
      HashTableExpToExp.HashTable HT;
      HashTableExpToIndex.HashTable HT2, HT3;
      Integer index = inIndex;

    case (syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)) equation
    //if Flags.isSet(Flags.DUMP_CSE) then
    //  BackendDump.dumpVariables(orderedVars, "########### Updated Variable List ###########");
    //  BackendDump.dumpEquationArray(orderedEqs, "########### Updated Equation List ###########");
    //end if;
        HT = HashTableExpToExp.emptyHashTableSized(49999);  //2053    4013    25343   536870879
        HT2 = HashTableExpToIndex.emptyHashTableSized(49999);
        HT3 = HashTableExpToIndex.emptyHashTableSized(49999);
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          print("collect statistics\n========================================\n");
        end if;
        (HT, HT2, index) = BackendEquation.traverseEquationArray(orderedEqs, createStatistics, (HT, HT2, index));
    //BaseHashTable.dumpHashTable(HT);
    //BaseHashTable.dumpHashTable(HT2);
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          print("\nstart substitution\n========================================\n");
        end if;
        (orderedEqs, (HT, HT2, _, eqList, varList)) = BackendEquation.traverseEquationArray_WithUpdate (orderedEqs, substituteCSE, (HT, HT2, HT3, {}, {}));
        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          print("\n");
        end if;
      syst.orderedEqs = BackendEquation.addEquations(eqList, orderedEqs);
      syst.orderedVars = BackendVariable.addVars(varList, orderedVars);
      if Flags.isSet(Flags.DUMP_CSE) then
        BackendDump.dumpVariables(syst.orderedVars, "########### Updated Variable List ###########");
        BackendDump.dumpEquationArray(syst.orderedEqs, "########### Updated Equation List ###########");
      end if;
    then (BackendDAEUtil.clearEqSyst(syst), index);

    else (inSystem, inIndex);
  end matchcontinue;
end CSE1;

protected function substituteCSE
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>> outTuple;
algorithm
  (outEq, outTuple) := match(inEq)
    local
      BackendDAE.Equation eq;
      tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>> tpl;

    case BackendDAE.ALGORITHM() then (inEq, inTuple);
    case BackendDAE.WHEN_EQUATION() then (inEq, inTuple);  // not necessary
    //case BackendDAE.COMPLEX_EQUATION() then (inEq, inTuple);
    //case BackendDAE.ARRAY_EQUATION() then (inEq, inTuple);
    case BackendDAE.IF_EQUATION() then (inEq, inTuple);

    else equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("traverse " + BackendDump.equationString(inEq) + "\n");
      end if;
      (eq, (tpl, _)) = BackendEquation.traverseExpsOfEquation(inEq, substituteCSE1, (inTuple, BackendEquation.equationSource(inEq)));
    then (eq, tpl);
  end match;
end substituteCSE;

protected function substituteCSE1
  input DAE.Exp inExp;
  input tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>>, DAE.ElementSource> inTuple;
  output DAE.Exp outExp;
  output tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>>, DAE.ElementSource> outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpTopDown(inExp, substituteCSE_main, inTuple);
end substituteCSE1;

protected function substituteCSE_main
  input DAE.Exp inExp;
  input tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>>, DAE.ElementSource> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>>, DAE.ElementSource> outTuple;
algorithm
  (outExp, cont, outTuple) := matchcontinue(inExp, inTuple)
    local
      DAE.Exp exp1, value;
      Absyn.Path path;
      DAE.CallAttributes attr;
      HashTableExpToExp.HashTable HT;
      HashTableExpToIndex.HashTable HT2;
      HashTableExpToIndex.HashTable HT3;
      list<BackendDAE.Equation> eqLst, eqLst1;
      list<BackendDAE.Var> varLst, varLst1;
      Integer counter;
      BackendDAE.Equation eq;
      DAE.Exp expReplaced;
      list<DAE.Exp> expLst;
      DAE.ElementSource source;

    case (DAE.BINARY(), ((HT, HT2, HT3, eqLst, varLst), source)) equation
      value = BaseHashTable.get(inExp, HT);
      counter = BaseHashTable.get(value, HT2);
      true = intGt(counter, 1);

      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("  - substitute cse binary: " + ExpressionDump.printExpStr(inExp) + " (counter: " + intString(counter) + ", id: " + ExpressionDump.printExpStr(value) + ")\n");
      end if;

      if not BaseHashTable.hasKey(value, HT3) then
        HT3 = BaseHashTable.add((value, 1), HT3);
        varLst = createVarsForExp(value, varLst);
        eq = BackendEquation.generateEquation(value, inExp, source /* TODO: Add CSE? */, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
        eqLst = eq::eqLst;
      end if;
    then (value, true, ((HT, HT2, HT3, eqLst, varLst), source));

    else (inExp, true, inTuple);
  end matchcontinue;
end substituteCSE_main;

protected function createStatistics
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> outTuple;
algorithm
  (outEq, outTuple) := match(inEq)
    local
      BackendDAE.Equation eq;
      tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> tpl;

    case BackendDAE.ALGORITHM() then (inEq, inTuple);
    case BackendDAE.WHEN_EQUATION() then (inEq, inTuple);  // not necessary
    //case BackendDAE.COMPLEX_EQUATION() then (inEq, inTuple);
    //case BackendDAE.ARRAY_EQUATION() then (inEq, inTuple);
    case BackendDAE.IF_EQUATION() then (inEq, inTuple);

    else equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("traverse " + BackendDump.equationString(inEq) + "\n");
      end if;
      (eq, tpl) = BackendEquation.traverseExpsOfEquation(inEq, createStatistics1, inTuple);
    then (eq, tpl);
  end match;
end createStatistics;

protected function createStatistics1
  input DAE.Exp inExp;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> inTuple;
  output DAE.Exp outExp;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpTopDown(inExp, createStatistics_main, inTuple);
end createStatistics1;

protected function createStatistics_main
  input DAE.Exp inExp;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer> outTuple;
algorithm
  (outExp, cont, outTuple) := matchcontinue(inExp, inTuple)
    local
      DAE.Exp exp1, exp2, value;
      list<DAE.Exp> expLst;
      DAE.Operator op;
      Absyn.Path path;
      HashTableExpToExp.HashTable HT;
      HashTableExpToIndex.HashTable HT2;
      list<BackendDAE.Equation> eqList;
      list<BackendDAE.Var> varList;
      Integer i, counter;
      String str;
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      BackendDAE.Equation eq;
      DAE.Type tp;

    case (DAE.BINARY(exp1, op, exp2), (HT, HT2, i)) equation
      if checkOp(op) then
        if BaseHashTable.hasKey(inExp, HT) then
          value = BaseHashTable.get(inExp, HT);
          counter = BaseHashTable.get(value, HT2) + 1;
          BaseHashTable.update((value, counter), HT2);

          if isCommutative(op) then
            value = BaseHashTable.get(DAE.BINARY(exp2, op, exp1), HT);
            BaseHashTable.update((value, counter), HT2);
          end if;
        else
          (value, i) = createReturnExp(Expression.typeof(inExp), i, "$cseb");
          counter = 1;
          HT = BaseHashTable.add((inExp, value), HT);
          HT2 = BaseHashTable.add((value, counter), HT2);
          if isCommutative(op) then
            HT = BaseHashTable.add((DAE.BINARY(exp2, op, exp1), value), HT);
          end if;
        end if;

        if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
          print("  - cse binary expression: " + ExpressionDump.printExpStr(inExp) + " (counter: " + intString(counter) + ", id: " + ExpressionDump.printExpStr(value) + ")\n");
        end if;
      end if;
    then (inExp, true, (HT, HT2, i));

    // skip some kinds of expressions
    case (DAE.IFEXP(), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("der")), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("smooth")), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("noEvent")), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("semiLinear")), _)
    then (inExp, false, inTuple);
    case (DAE.CALL(path=Absyn.IDENT("homotopy")), _)
    then (inExp, false, inTuple);

    else (inExp, true, inTuple);
  end matchcontinue;
end createStatistics_main;

protected function isCommutative
  input DAE.Operator inOp;
  output Boolean outCommutative;
algorithm
  outCommutative := match(inOp)
    case DAE.MUL() then true;
    case DAE.ADD() then true;
    else false;
  end match;
end isCommutative;

protected function checkOp
  input DAE.Operator inOp;
  output Boolean outB;
algorithm
  outB := match(inOp)
    case DAE.ADD() then true;
    case DAE.SUB() then true;
    case DAE.MUL() then true;
    case DAE.DIV() then true;
    case DAE.POW() then true;
    case DAE.UMINUS() then true;
    else false;
  end match;
end checkOp;


protected function prepareExpForReplace
  input DAE.Exp inExp;
  output DAE.Exp outExp;
algorithm
  (outExp) := match (inExp)
    local
      DAE.ComponentRef cr;
      DAE.Exp e;
      list<DAE.Exp> expLst;
      DAE.Type ty;
      Boolean scalar;

    case DAE.TUPLE(PR=expLst) equation
      expLst = List.map(expLst, prepareExpForReplace);
    then DAE.TUPLE(expLst);

    case DAE.ARRAY(array=e::_, ty=ty) equation
      cr = Expression.expCref(e);
      cr = ComponentReference.crefStripLastSubs(cr);
      cr = ComponentReference.crefSetType(cr, ty);
      e = Expression.crefExp(cr);
    then e;

    case DAE.RECORD(exps=e::_) equation
      cr = Expression.expCref(e);
      cr = ComponentReference.crefStripLastIdent(cr);
      e = Expression.crefExp(cr);
    then e;

    else inExp;
  end match;
end prepareExpForReplace;

// =============================================================================
// Common Sub Expressions
//
// =============================================================================

protected
uniontype CommonSubExp
  record ASSIGNMENT_CSE
    list<Integer> eqIdcs;
    list<Integer> sharedVars;
    list<Integer> aliasVars;
  end ASSIGNMENT_CSE;
end CommonSubExp;

public function commonSubExpressionReplacement"detects common sub expressions and introduces alias variables for them.
REMARK: this is just a basic prototype. feel free to extend.
author:Waurich TUD 2014-11"
  input BackendDAE.BackendDAE daeIn;
  output BackendDAE.BackendDAE daeOut;
algorithm
  //print("SYSTEM IN\n");
  //BackendDump.printBackendDAE(daeIn);
  daeOut := BackendDAEUtil.mapEqSystem(daeIn, commonSubExpression);
  //print("SYSTEM OUT\n");
  //BackendDump.printBackendDAE(daeOut);
end commonSubExpressionReplacement;

protected function commonSubExpression
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared sharedIn;
  output BackendDAE.EqSystem sysOut;
  output BackendDAE.Shared sharedOut;
algorithm
  (sysOut, sharedOut) := matchcontinue(sysIn, sharedIn)
    local
    DAE.FunctionTree functionTree;
    BackendDAE.Variables vars;
    BackendDAE.EquationArray eqs;
    BackendDAE.Shared shared;
    BackendDAE.EqSystem syst;
    BackendDAE.IncidenceMatrix m, mT;
    list<Integer> eqIdcs;
    list<CommonSubExp> cseLst;
  case(BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs), BackendDAE.SHARED(functionTree=functionTree))
    equation
      (_, m, mT) = BackendDAEUtil.getIncidenceMatrix(sysIn, BackendDAE.ABSOLUTE(), SOME(functionTree));
          //print("start this eqSystem\n");
          //BackendDump.dumpEqSystem(sysIn, "eqSystem input");
          //BackendDump.dumpIncidenceMatrix(m);
          //BackendDump.dumpIncidenceMatrixT(mT);
      cseLst = commonSubExpressionFind(m, mT, vars, eqs);
          //if not listEmpty(cseLst) then print("update "+stringDelimitList(List.map(cseLst, printCSE), "\n")+"\n");end if;
      syst = commonSubExpressionUpdate(cseLst, m, mT, sysIn);
          //print("done this eqSystem\n");
          //BackendDump.dumpEqSystem(syst, "eqSystem");
      then (syst, sharedIn);
    else (sysIn, sharedIn);
  end matchcontinue;
end commonSubExpression;

protected function commonSubExpressionFind
  input BackendDAE.IncidenceMatrix mIn;
  input BackendDAE.IncidenceMatrix mTIn;
  input BackendDAE.Variables varsIn;
  input BackendDAE.EquationArray eqsIn;
  output list<CommonSubExp> cseOut;
protected
  list<Integer> eqIdcs, varIdcs, lengthLst, range;
  list<list<Integer>> arrLst;
  list<list<Integer>> partitions;
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqs;
  BackendDAE.EqSystem eqSys;
  BackendDAE.IncidenceMatrix m, mT;
  list<BackendDAE.Equation> eqLst;
  list<BackendDAE.Var> varLst;
  list<CommonSubExp> cseLst2, cseLst3;
  list<tuple<Boolean, String>> varAtts, eqAtts;
algorithm
  try
    range := List.intRange(arrayLength(mIn));
    arrLst := arrayList(mIn);
    lengthLst := List.map(arrLst, listLength);

    // check for CSE of length 1
    //print("CHECK FOR CSE 2\n");
    (_, eqIdcs) := List.filter1OnTrueSync(lengthLst, intEq, 2, range);
    (eqLst, eqIdcs) := List.filterOnTrueSync(BackendEquation.getEqns(eqIdcs, eqsIn),BackendEquation.isNotAlgorithm,eqIdcs); // no algorithms
    eqs := BackendEquation.listEquation(eqLst);
    varIdcs := List.unique(List.flatten(List.map1(eqIdcs, Array.getIndexFirst, mIn)));
    varLst := List.map1(varIdcs, BackendVariable.getVarAtIndexFirst, varsIn);
    //(varLst,varIdcs) := List.filterOnTrueSync(varLst,BackendVariable.isVarNonDiscrete,varIdcs);// no discrete vars
    vars := BackendVariable.listVar1(varLst);
    eqSys := BackendDAEUtil.createEqSystem(vars, eqs);
    (_, m, mT) := BackendDAEUtil.getIncidenceMatrix(eqSys, BackendDAE.ABSOLUTE(), NONE());
        //BackendDump.dumpEqSystem(eqSys, "reduced system for CSE 2");
        //BackendDump.dumpIncidenceMatrix(m);
        //BackendDump.dumpIncidenceMatrix(mT);
        //varAtts := List.threadMap(List.fill(false, listLength(varIdcs)), List.fill("", listLength(varIdcs)), Util.makeTuple);
        //eqAtts := List.threadMap(List.fill(false, listLength(eqIdcs)), List.fill("", listLength(eqIdcs)), Util.makeTuple);
        //BackendDump.dumpBipartiteGraphStrongComponent2(vars, eqs, m, varAtts, eqAtts, "CSE2");
    partitions := arrayList(ResolveLoops.partitionBipartiteGraph(m, mT));
        //print("the partitions for system  : \n"+stringDelimitList(List.map(partitions, HpcOmTaskGraph.intLstString), "\n")+"\n");
    cseLst2 := List.fold(partitions, function getCSE2(m=m, mT=mT, vars=vars, eqs=eqs, eqMap=eqIdcs, varMap=varIdcs), {});

    // check for CSE of length 2
    //print("CHECK FOR CSE 3\n");
    (_, eqIdcs) := List.filter1OnTrueSync(lengthLst, intEq, 3, range);
    (eqLst, eqIdcs) := List.filterOnTrueSync(BackendEquation.getEqns(eqIdcs, eqsIn),BackendEquation.isNotAlgorithm,eqIdcs); // no algorithms
    eqs := BackendEquation.listEquation(eqLst);
    varIdcs := List.unique(List.flatten(List.map1(eqIdcs, Array.getIndexFirst, mIn)));
    varLst := List.map1(varIdcs, BackendVariable.getVarAtIndexFirst, varsIn);
    //(varLst,varIdcs) := List.filterOnTrueSync(varLst,BackendVariable.isVarNonDiscrete,varIdcs);// no discrete vars
    vars := BackendVariable.listVar1(varLst);
    eqSys := BackendDAEUtil.createEqSystem(vars, eqs);
    (_, m, mT) := BackendDAEUtil.getIncidenceMatrix(eqSys, BackendDAE.ABSOLUTE(), NONE());
        //BackendDump.dumpEqSystem(eqSys, "reduced system for CSE 3");
        //BackendDump.dumpIncidenceMatrix(m);
        //BackendDump.dumpIncidenceMatrix(mT);
        //varAtts := List.threadMap(List.fill(false, listLength(varIdcs)), List.fill("", listLength(varIdcs)), Util.makeTuple);
        //eqAtts := List.threadMap(List.fill(false, listLength(eqIdcs)), List.fill("", listLength(eqIdcs)), Util.makeTuple);
        //BackendDump.dumpBipartiteGraphStrongComponent2(vars, eqs, m, varAtts, eqAtts, "CSE3");
    partitions := arrayList(ResolveLoops.partitionBipartiteGraph(m, mT));
        //print("the partitions for system  : \n"+stringDelimitList(List.map(partitions, HpcOmTaskGraph.intLstString), "\n")+"\n");
    cseLst3 := List.fold(partitions, function getCSE3(m=m, mT=mT, vars=vars, eqs=eqs, eqMap=eqIdcs, varMap=varIdcs), {});
    cseOut := listAppend(cseLst2, cseLst3);
        //print("the cses : \n"+stringDelimitList(List.map(cseOut, printCSE), "\n")+"\n");
  else
    cseOut := {};
  end try;
end commonSubExpressionFind;

protected function getCSE2"traverses the partitions and checks for CSE2 i.e a=b+const. ; c = b+const. --> a=c
author:Waurich TUD 2014-11"
  input list<Integer> partition;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input BackendDAE.Variables vars;  // for partition
  input BackendDAE.EquationArray eqs;  // for partition
  input list<Integer> eqMap;
  input list<Integer> varMap;
  input list<CommonSubExp> cseIn;
  output list<CommonSubExp> cseOut;
algorithm
  cseOut := matchcontinue(partition, m, mT, vars, eqs, eqMap, varMap, cseIn)
  local
    Integer sharedVarIdx, eqIdx1, eqIdx2, varIdx1, varIdx2;
    list<Integer> varIdcs1, varIdcs2, sharedVarIdcs, eqIdcs;
    BackendDAE.Equation eq1, eq2;
    BackendDAE.Var sharedVar, var1, var2;
    DAE.Exp varExp1, varExp2, lhs, rhs1, rhs2;
  case({eqIdx1, eqIdx2}, _, _, _, _, _, _, _)
    equation
        //print("partition "+stringDelimitList(List.map(partition, intString), ", ")+"\n");
      // the partition consists of 2 equations
      varIdcs1 = arrayGet(m, eqIdx1);
      varIdcs2 = arrayGet(m, eqIdx2);
      (sharedVarIdcs, varIdcs1, varIdcs2) = List.intersection1OnTrue(varIdcs1, varIdcs2, intEq);
        //print("sharedVarIdcs "+stringDelimitList(List.map(sharedVarIdcs, intString), ", ")+"\n");
      {varIdx1} = varIdcs1;
      {varIdx2} = varIdcs2;
      {sharedVarIdx} = sharedVarIdcs;
      {eq1, eq2} = BackendEquation.getEqns(partition, eqs);
      _ = BackendVariable.getVarAt(vars, sharedVarIdx);
      var1 = BackendVariable.getVarAt(vars, varIdx1);
      var2 = BackendVariable.getVarAt(vars, varIdx2);

      // compare the actual equations
      varExp1 = BackendVariable.varExp(var1);
      varExp2 = BackendVariable.varExp(var2);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs1) = eq1;
      (rhs1, _) = ExpressionSolve.solve(lhs, rhs1, varExp1);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs2) = eq2;
      (rhs2, _) = ExpressionSolve.solve(lhs, rhs2, varExp2);
      true = Expression.expEqual(rhs1, rhs2);
         //print("rhs1 " +ExpressionDump.printExpStr(rhs1)+"\n");
         //print("rhs2 " +ExpressionDump.printExpStr(rhs2)+"\n");
         //print("is equal\n");
      // build CSE
      sharedVarIdcs = List.map1(sharedVarIdcs, List.getIndexFirst, varMap);
      varIdcs1 = listAppend(varIdcs1, varIdcs2);
      varIdcs1 = List.map1(varIdcs1, List.getIndexFirst, varMap);
      eqIdcs = List.map1(partition, List.getIndexFirst, eqMap);
    then ASSIGNMENT_CSE(eqIdcs, sharedVarIdcs, varIdcs1)::cseIn;
  else cseIn;
  end matchcontinue;
end getCSE2;

protected function getCSE3"traverses the partitions and checks for CSE3 i.e a=b+c+const. ; d = b+c+const. --> a=d
author:Waurich TUD 2014-11"
  input list<Integer> partition;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input BackendDAE.Variables vars;  // for partition
  input BackendDAE.EquationArray eqs;  // for partition
  input list<Integer> eqMap;
  input list<Integer> varMap;
  input list<CommonSubExp> cseIn;
  output list<CommonSubExp> cseOut;
algorithm
  cseOut := matchcontinue(partition, m, mT, vars, eqs, eqMap, varMap, cseIn)
  local
    Integer sharedVarIdx, eqIdx1, eqIdx2, varIdx1, varIdx2;
    list<Integer> varIdcs1, varIdcs2, sharedVarIdcs, eqIdcs;
    list<Integer> loop1;
    BackendDAE.Equation eq1, eq2;
    BackendDAE.Var var1, var2;
    DAE.Exp varExp1, varExp2, lhs, rhs1, rhs2;
  case(_, _, _, _, _, _, _, _)
    equation
          //print("partition "+stringDelimitList(List.map(partition, intString), ", ")+"\n");
      // partition has only one loop
      ({loop1}, _, _) = ResolveLoops.resolveLoops_findLoops({partition}, m, mT);
          //print("loop1 "+stringDelimitList(List.map(loop1, intString), ", ")+"\n");
      {eqIdx1, eqIdx2} = loop1;
      varIdcs1 = arrayGet(m, eqIdx1);
      varIdcs2 = arrayGet(m, eqIdx2);
      (sharedVarIdcs, varIdcs1, varIdcs2) = List.intersection1OnTrue(varIdcs1, varIdcs2, intEq);
        //print("sharedVarIdcs "+stringDelimitList(List.map(sharedVarIdcs, intString), ", ")+"\n");
        //print("varIdcs1 "+stringDelimitList(List.map(varIdcs1, intString), ", ")+"\n");
        //print("varIdcs2 "+stringDelimitList(List.map(varIdcs2, intString), ", ")+"\n");
      {varIdx1} = varIdcs1;
      {varIdx2} = varIdcs2;
      {eq1, eq2} = BackendEquation.getEqns(loop1, eqs);
      var1 = BackendVariable.getVarAt(vars, varIdx1);
      var2 = BackendVariable.getVarAt(vars, varIdx2);

      // compare the actual equations
      varExp1 = BackendVariable.varExp(var1);
      varExp2 = BackendVariable.varExp(var2);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs1) = eq1;
      (rhs1, _) = ExpressionSolve.solve(lhs, rhs1, varExp1);
      BackendDAE.EQUATION(exp=lhs, scalar=rhs2) = eq2;
      (rhs2, _) = ExpressionSolve.solve(lhs, rhs2, varExp2);
      true = Expression.expEqual(rhs1, rhs2);
         //print("rhs1 " +ExpressionDump.printExpStr(rhs1)+"\n");
         //print("rhs2 " +ExpressionDump.printExpStr(rhs2)+"\n");
         //print("is equal\n");
      // build CSE
      sharedVarIdcs = List.map1(sharedVarIdcs, List.getIndexFirst, varMap);
      varIdcs1 = listAppend(varIdcs1, varIdcs2);
      varIdcs1 = List.map1(varIdcs1, List.getIndexFirst, varMap);
      eqIdcs = List.map1(loop1, List.getIndexFirst, eqMap);
    then ASSIGNMENT_CSE(eqIdcs, sharedVarIdcs, varIdcs1)::cseIn;
  else cseIn;
  end matchcontinue;
end getCSE3;


protected function commonSubExpressionUpdate"updates the eqSystem.
remark: the vars are not explicitly declared as alias and an equation is not removed since there are cases where alias-replacements are invalid like :
x[1]=x[2];
for i in 1:2 loop x[i] =i*time; end for;
Thats why one original equation is replaced by an alias equation.
author:Waurich TUD 2014-11"
  input list<CommonSubExp> tplsIn;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input BackendDAE.EqSystem sysIn;
  output BackendDAE.EqSystem sysOut;
algorithm
  sysOut := matchcontinue (tplsIn, m, mT, sysIn)
    local
      Integer sharedVar, eqIdx1, eqIdx2, varIdx1, varIdx2, varIdx_remain, varIdxAlias, eqIdxDel, eqIdxLeft;
      list<Integer> eqIdcs, eqs1, eqs2, vars1, vars2, aliasVars;
      list<CommonSubExp> rest;
      BackendDAE.Var var1, var2, var_remain, var_alias;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqs;
      BackendDAE.EqSystem syst;
      DAE.Exp varExp_remain, varExp_alias;
      DAE.ComponentRef cref;
      list<BackendDAE.Equation> eqLst;
  case({}, _, _, syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs))
    equation
    then (BackendDAEUtil.clearEqSyst(syst));

  case ( ASSIGNMENT_CSE(eqIdcs={eqIdx1, eqIdx2}, aliasVars={varIdx1, varIdx2})::rest, _, _,
         syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs))
    equation
     // update the equations
     repl = BackendVarTransform.emptyReplacements();
     eqs1 = arrayGet(mT, varIdx1);
     eqs2 = arrayGet(mT, varIdx2);
           //print("eqs1 "+stringDelimitList(List.map(eqs1, intString), ", ")+"\n");
           //print("eqs2 "+stringDelimitList(List.map(eqs2, intString), ", ")+"\n");

     var1 = BackendVariable.getVarAt(vars, varIdx1);
     var2 = BackendVariable.getVarAt(vars, varIdx2);

     //choose alias variable
     if BackendVariable.isStateVar(var1) then varIdxAlias = varIdx2; varIdx_remain = varIdx1;
     elseif BackendVariable.isStateVar(var2) then varIdx_remain = varIdx2; varIdxAlias = varIdx1;
     else
       if intLe(listLength(eqs2), listLength(eqs1)) then varIdxAlias = varIdx2; varIdx_remain = varIdx1; else varIdxAlias = varIdx1; varIdx_remain = varIdx2; end if;
     end if;

     if intLe(listLength(eqs2), listLength(eqs1)) then eqIdxDel = eqIdx2; _ = eqIdx1; else eqIdxDel = eqIdx1; _ = eqIdx2; end if;

     var_remain = BackendVariable.getVarAt(vars, varIdx_remain);
     var_alias = BackendVariable.getVarAt(vars, varIdxAlias);
     cref = BackendVariable.varCref(var_alias);
     varExp_remain = BackendVariable.varExp(var_remain);
     varExp_alias = BackendVariable.varExp(var_alias);
     repl = BackendVarTransform.addReplacement(repl, cref, varExp_remain, NONE());
         //BackendVarTransform.dumpReplacements(repl);

     //replace in equations
     eqIdcs = arrayGet(mT, varIdxAlias);
     eqLst = BackendEquation.getEqns(eqIdcs, eqs);
     //(eqLst, _) = BackendVarTransform.replaceEquations(eqLst, repl, NONE());
     eqs = List.threadFold(eqIdcs, eqLst, BackendEquation.setAtIndexFirst, eqs);

     //replace original equation
     BackendEquation.setAtIndex(eqs,eqIdxDel,BackendDAE.EQUATION(varExp_remain,varExp_alias,DAE.emptyElementSource,BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC));
    then commonSubExpressionUpdate(rest, m, mT, syst);
 case (_::rest, _, _, _)
  then commonSubExpressionUpdate(rest, m, mT, sysIn);
  end matchcontinue;
end commonSubExpressionUpdate;

protected function printCSE"prints a CSE tuple string.
author:Waurich TUD 2014-11"
  input CommonSubExp cse;
  output String s;
algorithm
  s := match(cse)
local
  list<Integer> eqIdcs;
  list<Integer> sharedVars;
  list<Integer> aliasVars;
    case(ASSIGNMENT_CSE(eqIdcs=eqIdcs, sharedVars=sharedVars, aliasVars=aliasVars))
  then "ASSIGN_CSE: eqs{"+stringDelimitList(List.map(eqIdcs, intString), ", ")+"}"+"   sharedVars{"+stringDelimitList(List.map(sharedVars, intString), ", ")+"}"+"   aliasVars{"+stringDelimitList(List.map(aliasVars, intString), ", ")+"}";
    end match;
end printCSE;
annotation(__OpenModelica_Interface="backend");

end CommonSubExpression;

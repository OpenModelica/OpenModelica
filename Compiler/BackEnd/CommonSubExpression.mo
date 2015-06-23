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
               CommonSubExpression.

  RCS: $Id: CommonSubExpression.mo 23264 2014-11-07 07:01:20Z sjoelund.se $"

public import BackendDAE;
public import DAE;

protected import Array;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVarTransform;
protected import BackendVariable;
protected import BaseHashSet;
protected import BaseHashTable;
protected import ComponentReference;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import HashTableExpToExp;
protected import HashTableExpToIndex;
protected import HpcOmEqSystems;
protected import HpcOmTaskGraph;
protected import List;
protected import ResolveLoops;
protected import Types;

public function CSE "authors: Jan Hagemann and Lennart Ochel (FH Bielefeld, Germany)
  This module eliminates common subexpressions in an acausal environment. Different options are available:
    - CSE_CALL: consider duplicate call expressions
    - CSE_EACHCALL: consider each call expressions
    - CSE_BINARY: consider duplicate binary expressions
  NOTE: This is currently just an experimental prototype to demonstrate interesting effects."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
protected
  Boolean bCSE_CALL = Flags.getConfigBool(Flags.CSE_CALL);
  Boolean bCSE_EACHCALL = Flags.getConfigBool(Flags.CSE_EACHCALL);
  Boolean bCSE_BINARY = Flags.getConfigBool(Flags.CSE_BINARY);
algorithm
  if bCSE_CALL or bCSE_EACHCALL or bCSE_BINARY then
    outDAE := BackendDAEUtil.mapEqSystemAndFold(inDAE, CSE1, (1, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY));
  end if;
end CSE;

public function CSE_EachCall
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE = inDAE;
algorithm
  outDAE := BackendDAEUtil.mapEqSystemAndFold(inDAE, CSE1, (1, false, true, false));
end CSE_EachCall;

protected function CSE1
  input BackendDAE.EqSystem inSystem;
  input BackendDAE.Shared inShared;
  input tuple<Integer, Boolean, Boolean, Boolean> inTpl;
  output BackendDAE.EqSystem outSystem;
  output BackendDAE.Shared outShared = inShared;
  output tuple<Integer, Boolean, Boolean, Boolean> outTpl;
algorithm
  (outSystem, outTpl) := matchcontinue(inSystem, inTpl)
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;
      list<BackendDAE.Var> varList;
      list<BackendDAE.Equation> eqList;
      HashTableExpToExp.HashTable HT;
      HashTableExpToIndex.HashTable HT2, HT3;
      Integer index;
      Boolean bCSE_CALL;
      Boolean bCSE_EACHCALL;
      Boolean bCSE_BINARY;

    case (BackendDAE.EQSYSTEM(orderedVars, orderedEqs, _, _, _, stateSets, partitionKind), (index, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY)) equation
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
      (HT, HT2, index, _, _, _) = BackendEquation.traverseEquationArray(orderedEqs, createStatistics, (HT, HT2, index, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY));
    //BaseHashTable.dumpHashTable(HT);
    //BaseHashTable.dumpHashTable(HT2);
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("\nstart substitution\n========================================\n");
      end if;
      (orderedEqs, (HT, HT2, _, eqList, varList, _, _, _)) = BackendEquation.traverseEquationArray_WithUpdate(orderedEqs, substituteCSE, (HT, HT2, HT3, {}, {}, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY));
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("\n");
      end if;
      orderedEqs = BackendEquation.addEquations(eqList, orderedEqs);
      orderedVars = BackendVariable.addVars(varList, orderedVars);
      if Flags.isSet(Flags.DUMP_CSE) then
        BackendDump.dumpVariables(orderedVars, "########### Updated Variable List ###########");
        BackendDump.dumpEquationArray(orderedEqs, "########### Updated Equation List ###########");
      end if;
    then (BackendDAEUtil.createEqSystem(orderedVars, orderedEqs, stateSets, partitionKind), (index, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY));

    else (inSystem, inTpl);
  end matchcontinue;
end CSE1;

protected function substituteCSE
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>, Boolean, Boolean, Boolean> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>, Boolean, Boolean, Boolean> outTuple;
algorithm
  (outEq, outTuple) := match(inEq)
    local
      BackendDAE.Equation eq;
      tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>, Boolean, Boolean, Boolean> tpl;

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
  input tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>, Boolean, Boolean, Boolean>, DAE.ElementSource> inTuple;
  output DAE.Exp outExp;
  output tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>, Boolean, Boolean, Boolean>, DAE.ElementSource> outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpTopDown(inExp, substituteCSE_main, inTuple);
end substituteCSE1;

protected function substituteCSE_main
  input DAE.Exp inExp;
  input tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>, Boolean, Boolean, Boolean>, DAE.ElementSource> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, HashTableExpToIndex.HashTable, list<BackendDAE.Equation>, list<BackendDAE.Var>, Boolean, Boolean, Boolean>, DAE.ElementSource> outTuple;
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
      Boolean bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY;

    case (DAE.BINARY(), ((HT, HT2, HT3, eqLst, varLst, bCSE_CALL, bCSE_EACHCALL, true), source)) equation
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
    then (value, true, ((HT, HT2, HT3, eqLst, varLst, bCSE_CALL, bCSE_EACHCALL, true), source));

    case (DAE.CALL(path, expLst, attr), ((HT, HT2, HT3, eqLst, varLst, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY), source)) equation
      true = bCSE_CALL or bCSE_EACHCALL;

      value = BaseHashTable.get(inExp, HT);
      counter = BaseHashTable.get(value, HT2);

      if not bCSE_EACHCALL then
        true = intGt(counter, 1);
      end if;

      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("  - substitute cse call: " + ExpressionDump.printExpStr(inExp) + " (counter: " + intString(counter) + ", id: " + ExpressionDump.printExpStr(value) + ")\n");
      end if;

      if not BaseHashTable.hasKey(value, HT3) then
        // generate all variables, since this function might fail
        // this need to run before any HashTable is updated
        varLst = createVarsForExp(value, varLst);

        // generate the proper replacement for arrays and records
        // this need to run before any HashTable is updated
        expReplaced = prepareExpForReplace(value);

        // traverse all arguments of the function
        (expLst, ((HT, HT2, HT3, eqLst1, varLst1, _, _, _), source)) = Expression.traverseExpList(expLst, substituteCSE1, ((HT, HT2, HT3, {}, {}, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY), source));
        exp1 = DAE.CALL(path, expLst, attr);
        varLst = listAppend(varLst1, varLst);
        eqLst = listAppend(eqLst1, eqLst);

        // debug
        //if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        //  print("create equation from:\n  LHS: " + ExpressionDump.printExpStr(value) + " \n");
        //  print("  RHS: " + ExpressionDump.printExpStr(inExp) + " \n");
        //end if;

        // generate equation
        eq = BackendEquation.generateEquation(expReplaced, exp1, source /* TODO: Add CSE? */, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
        eqLst = eq::eqLst;

        // update HashTable by value
        HT3 = BaseHashTable.add((value, 1), HT3);

        // use replaced expression
        value = expReplaced;

        // debug
        //if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        //  print("Replaced CSE Expression: " + ExpressionDump.printExpStr(inExp) + " \n");
        //  print("by equation:\n" + BackendDump.equationString(eq) + "\n");
        //end if;
      else
        // use replaced expression
        value = prepareExpForReplace(value);
      end if;
    then (value, false, ((HT, HT2, HT3, eqLst, varLst, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY), source));

    else (inExp, true, inTuple);
  end matchcontinue;
end substituteCSE_main;

protected function createStatistics
  input BackendDAE.Equation inEq;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer, Boolean, Boolean, Boolean> inTuple;
  output BackendDAE.Equation outEq;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer, Boolean, Boolean, Boolean> outTuple;
algorithm
  (outEq, outTuple) := match(inEq)
    local
      BackendDAE.Equation eq;
      tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer, Boolean, Boolean, Boolean> tpl;

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
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer, Boolean, Boolean, Boolean> inTuple;
  output DAE.Exp outExp;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer, Boolean, Boolean, Boolean> outTuple;
algorithm
  (outExp, outTuple) := Expression.traverseExpTopDown(inExp, createStatistics_main, inTuple);
end createStatistics1;

protected function createStatistics_main
  input DAE.Exp inExp;
  input tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer, Boolean, Boolean, Boolean> inTuple;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<HashTableExpToExp.HashTable, HashTableExpToIndex.HashTable, Integer, Boolean, Boolean, Boolean> outTuple;
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
      Boolean bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY;

    case (DAE.BINARY(exp1, op, exp2), (HT, HT2, i, bCSE_CALL, bCSE_EACHCALL, true)) equation
      if checkOp(op) then
        if BaseHashTable.hasKey(inExp, HT) then
          value = BaseHashTable.get(inExp, HT);
          counter = BaseHashTable.get(value, HT2) + 1;
          HT2 = BaseHashTable.update((value, counter), HT2);

          if isCommutative(op) then
            value = BaseHashTable.get(DAE.BINARY(exp2, op, exp1), HT);
            HT2 = BaseHashTable.update((value, counter), HT2);
          end if;
        else
          (value, i) = createReturnExp(Expression.typeof(inExp), i);
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
    then (inExp, true, (HT, HT2, i, bCSE_CALL, bCSE_EACHCALL, true));

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

    case (DAE.CALL(attr=DAE.CALL_ATTR(ty=tp)), (HT, HT2, i, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY)) equation
      true = bCSE_CALL or bCSE_EACHCALL;
      if BaseHashTable.hasKey(inExp, HT) then
        value = BaseHashTable.get(inExp, HT);
        counter = BaseHashTable.get(value, HT2) + 1;
        HT2 = BaseHashTable.update((value, counter), HT2);
      else
        (value, i) = createReturnExp(tp, i);
        counter = 1;
        HT = BaseHashTable.add((inExp, value), HT);
        HT2 = BaseHashTable.add((value, counter), HT2);
      end if;

      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("  - cse call expression: " + ExpressionDump.printExpStr(inExp) + " (counter: " + intString(counter) + ", id: " + ExpressionDump.printExpStr(value) + ")\n");
      end if;
    then (inExp, true, (HT, HT2, i, bCSE_CALL, bCSE_EACHCALL, bCSE_BINARY));

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

protected function createReturnExp
  input DAE.Type inType;
  input Integer inIndex;
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
      str = "$cse" + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_REAL_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_REAL_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_INTEGER() equation
      str = "$cse" + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_INTEGER_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_INTEGER_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_STRING() equation
      str = "$cse" + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_STRING_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_STRING_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_BOOL() equation
      str = "$cse" + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_BOOL_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_BOOL_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_CLOCK() equation
      str = "$cse" + intString(inIndex);
      cr = DAE.CREF_IDENT(str, DAE.T_CLOCK_DEFAULT, {});
      value = DAE.CREF(cr, DAE.T_CLOCK_DEFAULT);
    then (value, inIndex + 1);

    case DAE.T_TUPLE(types=typeLst) equation
      (expLst, i) = List.mapFold(typeLst, createReturnExp, inIndex);
      value = DAE.TUPLE(expLst);
    then (value, i+1);

    // Expanding
    case DAE.T_ARRAY() equation
      str = "$cse" + intString(inIndex);
      cr = DAE.CREF_IDENT(str, inType, {});
      crefs = ComponentReference.expandCref(cr, false);
      expLst = List.map(crefs, Expression.crefExp);
      value = DAE.ARRAY(inType, true, expLst);
    then (value, inIndex + 1);

    // record types
    case DAE.T_COMPLEX(varLst=varLst, complexClassType=ClassInf.RECORD(path)) equation
      str = "$cse" + intString(inIndex);
      cr = DAE.CREF_IDENT(str, inType, {});
      crefs = ComponentReference.expandCref(cr, true);
      expLst = List.map(crefs, Expression.crefExp);
      varNames = List.map(varLst, Expression.varName);
      value = DAE.RECORD(path, expLst, varNames, inType);
    then (value, inIndex + 1);

    else equation
      if Flags.isSet(Flags.DUMP_CSE_VERBOSE) then
        print("  - createReturnExp failed for " + Types.printTypeStr(inType) + "\n");
      end if;
    then fail();
  end match;
end createReturnExp;

protected function createVarsForExp
  input DAE.Exp inExp;
  input list<BackendDAE.Var> inAccumVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  (outVarLst) := match (inExp)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expLst;
      BackendDAE.Var var;

    case DAE.CREF(componentRef=cr) guard(not Expression.isArrayType(Expression.typeof(inExp))
                                          and not Expression.isRecordType(Expression.typeof(inExp)))
    equation
      // use the correct type when creating var. The cref might have subs.
      var = BackendVariable.createCSEVar(cr, Expression.typeof(inExp));
    then var::inAccumVarLst;

    /* consider also array and record crefs */
    /* TODO: Acivate that case, now it produces wrong types
             in the created variables, it seems that expandCref
             has an issue.
    */
    /*
    case DAE.CREF(componentRef=cr) equation
      crefs = ComponentReference.expandCref(cr, true);
      false = valueEq({cr}, crefs); // Not an expanded element
      expLst = List.map(crefs, Expression.crefExp);
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;
    */

    case DAE.TUPLE(expLst) equation
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    case DAE.ARRAY(array=expLst) equation
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    case DAE.RECORD(exps=expLst) equation
      outVarLst = List.fold(expLst, createVarsForExp, inAccumVarLst);
    then outVarLst;

    // all other are failing cases
    else fail();
  end match;
end createVarsForExp;

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
protected
  BackendDAE.EqSystems eqs;
  BackendDAE.Shared shared;
algorithm
    //print("SYSTEM IN\n");
    //BackendDump.printBackendDAE(daeIn);
    if Flags.isSet(Flags.DISABLE_COMSUBEXP) then
      daeOut := daeIn;
    else
      daeOut := BackendDAEUtil.mapEqSystem(daeIn, commonSubExpression);
    end if;
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
      //if not listEmpty(cseLst) then print("update "+stringDelimitList(List.map(cseLst, printCSE), "")+"\n");end if;
      (syst, shared) = commonSubExpressionUpdate(cseLst, m, mT, sysIn, sharedIn, {}, {});
          //print("done this eqSystem\n");
          //BackendDump.dumpEqSystem(syst, "eqSystem");
          //BackendDump.printShared(shared);
      then (syst, shared);
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
    varIdcs := List.unique(List.flatten(List.map1(eqIdcs, Array.getIndexFirst, mIn)));
    vars := BackendVariable.listVar1(List.map1(varIdcs, BackendVariable.getVarAtIndexFirst, varsIn));
    eqs := BackendEquation.listEquation(BackendEquation.getEqns(eqIdcs, eqsIn));
    eqSys := BackendDAEUtil.createEqSystem(vars, eqs);
    (_, m, mT) := BackendDAEUtil.getIncidenceMatrix(eqSys, BackendDAE.ABSOLUTE(), NONE());
        //BackendDump.dumpEqSystem(eqSys, "reduced system for CSE 2");
        //BackendDump.dumpIncidenceMatrix(m);
        //BackendDump.dumpIncidenceMatrix(mT);
        //varAtts := List.threadMap(List.fill(false, listLength(varIdcs)), List.fill("", listLength(varIdcs)), Util.makeTuple);
        //eqAtts := List.threadMap(List.fill(false, listLength(eqIdcs)), List.fill("", listLength(eqIdcs)), Util.makeTuple);
        //HpcOmEqSystems.dumpEquationSystemBipartiteGraph2(vars, eqs, m, varAtts, eqAtts, "CSE2");
    partitions := arrayList(ResolveLoops.partitionBipartiteGraph(m, mT));
        //print("the partitions for system  : \n"+stringDelimitList(List.map(partitions, HpcOmTaskGraph.intLstString), "\n")+"\n");
    cseLst2 := List.fold(partitions, function getCSE2(m=m, mT=mT, vars=vars, eqs=eqs, eqMap=eqIdcs, varMap=varIdcs), {});

    // check for CSE of length 2
    //print("CHECK FOR CSE 3\n");
    (_, eqIdcs) := List.filter1OnTrueSync(lengthLst, intEq, 3, range);
    varIdcs := List.unique(List.flatten(List.map1(eqIdcs, Array.getIndexFirst, mIn)));
    vars := BackendVariable.listVar1(List.map1(varIdcs, BackendVariable.getVarAtIndexFirst, varsIn));
    eqs := BackendEquation.listEquation(BackendEquation.getEqns(eqIdcs, eqsIn));
    eqSys := BackendDAEUtil.createEqSystem(vars, eqs);
    (_, m, mT) := BackendDAEUtil.getIncidenceMatrix(eqSys, BackendDAE.ABSOLUTE(), NONE());
        //BackendDump.dumpEqSystem(eqSys, "reduced system for CSE 3");
        //BackendDump.dumpIncidenceMatrix(m);
        //BackendDump.dumpIncidenceMatrix(mT);
        //varAtts := List.threadMap(List.fill(false, listLength(varIdcs)), List.fill("", listLength(varIdcs)), Util.makeTuple);
        //eqAtts := List.threadMap(List.fill(false, listLength(eqIdcs)), List.fill("", listLength(eqIdcs)), Util.makeTuple);
        //HpcOmEqSystems.dumpEquationSystemBipartiteGraph2(vars, eqs, m, varAtts, eqAtts, "CSE3");
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
      ({loop1}, _, _) = ResolveLoops.resolveLoops_findLoops({partition}, m, mT, {}, {}, {});
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


protected function commonSubExpressionUpdate"updates the eqSystem and shared according to the cse.
author:Waurich TUD 2014-11"
  input list<CommonSubExp> tplsIn;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input BackendDAE.EqSystem sysIn;
  input BackendDAE.Shared sharedIn;
  input list<Integer> deleteEqLstIn;
  input list<DAE.ComponentRef> deleteCrefsIn;
  output BackendDAE.EqSystem sysOut;
  output BackendDAE.Shared sharedOut;
algorithm
  (sysOut, sharedOut) := matchcontinue(tplsIn, m, mT, sysIn, sharedIn, deleteEqLstIn, deleteCrefsIn)
    local
      Integer sharedVar, eqIdx1, eqIdx2, varIdx1, varIdx2, varIdxRepl, varIdxAlias, eqIdxDel, eqIdxLeft;
      list<Integer> eqIdcs, eqs1, eqs2, vars1, vars2, aliasVars;
      list<CommonSubExp> rest;
      BackendDAE.Var var1, var2;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.StateSets stateSets;
      BackendDAE.BaseClockPartitionKind partitionKind;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqs;
      BackendDAE.EqSystem eqSys;
      BackendDAE.Shared shared;
      DAE.Exp varExp;
      DAE.ComponentRef cref;
      list<BackendDAE.Equation> eqLst;
  case({}, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs, stateSets=stateSets, partitionKind=partitionKind), _, _, _)
    equation
      // remove superfluous equations
    eqLst = BackendEquation.equationList(eqs);
    eqLst = List.deletePositions(eqLst, List.map1(deleteEqLstIn, intSub, 1));
    eqs = BackendEquation.listEquation(eqLst);

    // remove alias from vars
    vars = BackendVariable.deleteCrefs(deleteCrefsIn, vars);
    eqSys = BackendDAEUtil.createEqSystem(vars, eqs, stateSets, partitionKind);
    then (eqSys, sharedIn);
  case ( ASSIGNMENT_CSE(eqIdcs={eqIdx1, eqIdx2}, aliasVars={varIdx1, varIdx2})::rest, _, _,
         BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqs, stateSets=stateSets, partitionKind=partitionKind),
         _, _, _ )
    equation
     // update the equations
     repl = BackendVarTransform.emptyReplacements();
     eqs1 = arrayGet(mT, varIdx1);
     eqs2 = arrayGet(mT, varIdx2);
           //print("eqs1 "+stringDelimitList(List.map(eqs1, intString), ", ")+"\n");
           //print("eqs2 "+stringDelimitList(List.map(eqs2, intString), ", ")+"\n");
     //true = intEq(listLength(eqs1), 1) or intEq(listLength(eqs2), 1);  // choose the variable to be removed, that does not influence the causalization
     if intLe(listLength(eqs2), listLength(eqs1)) then varIdxAlias = varIdx2; varIdxRepl = varIdx1; else varIdxAlias = varIdx1; varIdxRepl = varIdx2; end if;
     if intLe(listLength(eqs2), listLength(eqs1)) then eqIdxDel = eqIdx2; _ = eqIdx1; else eqIdxDel = eqIdx1; _ = eqIdx2; end if;

     var1 = BackendVariable.getVarAt(vars, varIdxAlias);
     var2 = BackendVariable.getVarAt(vars, varIdxRepl);
     false = BackendVariable.isStateVar(var1) or BackendDAEUtil.isVarDiscrete(var1);

     cref = BackendVariable.varCref(var2);
     varExp = BackendVariable.varExp(var1);
     repl = BackendVarTransform.addReplacement(repl, cref, varExp, NONE());
         //BackendVarTransform.dumpReplacements(repl);
     eqIdcs = arrayGet(mT, varIdxRepl);
     eqLst = BackendEquation.getEqns(eqIdcs, eqs);
     (eqLst, _) = BackendVarTransform.replaceEquations(eqLst, repl, NONE());
     eqs = List.threadFold(eqIdcs, eqLst, BackendEquation.setAtIndexFirst, eqs);

     // transfer initial value
     if BackendVariable.varHasStartValue(var2) and not BackendVariable.varHasStartValue(var1) then var1 = BackendVariable.setVarStartValue(var1, BackendVariable.varStartValue(var2));
        var1 = BackendVariable.setVarFixed(var1, BackendVariable.varFixed(var2)) ; end if;
     vars = BackendVariable.setVarAt(vars, varIdxAlias, var1);

     // add alias to shared
     var2 = BackendVariable.setBindExp(var2, SOME(varExp));
     shared = updateAllAliasVars(sharedIn, repl);
     shared = BackendVariable.addAliasVarDAE(var2, shared);
     eqSys = BackendDAEUtil.createEqSystem(vars, eqs, stateSets, partitionKind);
    then commonSubExpressionUpdate(rest, m, mT, eqSys, shared, eqIdxDel::deleteEqLstIn, cref::deleteCrefsIn);
 case(_::rest, _, _, _, _, _, _)
  then commonSubExpressionUpdate(rest, m, mT, sysIn, sharedIn, deleteEqLstIn, deleteCrefsIn);
  end matchcontinue;
end commonSubExpressionUpdate;


protected function updateAllAliasVars"replaces all bindingExps in the aliasVars.
author:Waurich TUD 2014-11"
  input BackendDAE.Shared sharedIn;
  input BackendVarTransform.VariableReplacements repl;
  output BackendDAE.Shared sharedOut;
protected
  BackendDAE.Variables aliasVars;
algorithm
  BackendDAE.SHARED(aliasVars=aliasVars) := sharedIn;
  (aliasVars, _) := BackendVariable.traverseBackendDAEVarsWithUpdate(aliasVars, replaceBindings, repl);
  sharedOut := BackendDAEUtil.setSharedAliasVars(sharedIn, aliasVars);
end updateAllAliasVars;

protected function replaceBindings"traversal function to replace bidning exps.
author:Waurich TUD 2014-11"
  input BackendDAE.Var inVar;
  input BackendVarTransform.VariableReplacements replIn;
  output BackendDAE.Var outVar;
  output BackendVarTransform.VariableReplacements replOut;
algorithm
  outVar := BackendVarTransform.replaceBindingExp(inVar, replIn);
  replOut := replIn;
end replaceBindings;

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

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

encapsulated package FindZeroCrossings
" file:        FindZeroCrossings.mo
  package:     FindZeroCrossings
  description: This package contains all the functions to find zero crossings
               inside BackendDAE.

"

import Absyn;
import BackendDAE;
import DAE;

protected
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import CheckModel;
import ComponentReference;
import DAEDump;
import DAEUtil;
import DoubleEndedList;
import Error;
import Expression;
import ExpressionDump;
import Flags;
import HashTableExpToIndex;
import List;
import MetaModelica.Dangerous;
import SCode;
import SynchronousFeatures;
import Util;
import ZeroCrossings;

type ZCArgType  = tuple<tuple<BackendDAE.ZeroCrossingSet, DoubleEndedList<BackendDAE.ZeroCrossing>, BackendDAE.ZeroCrossingSet, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>;
type ForArgType = tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<BackendDAE.ZeroCrossingSet, DoubleEndedList<BackendDAE.ZeroCrossing>, BackendDAE.ZeroCrossingSet, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>;
// =============================================================================
// section for preOptModule >>encapsulateWhenConditions<<
//
// This module encapsulates each when-condition in a boolean-variable
// $whenConditionsN and generates to each of these variables an equation
// $whenConditions = whenConditions
// =============================================================================

public function encapsulateWhenConditions "author: lochel"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystems systs;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
  Integer index;
  HashTableExpToIndex.HashTable ht "is used to avoid redundant condition-variables";
  DoubleEndedList<BackendDAE.Var> vars;
  DoubleEndedList<BackendDAE.Equation> eqns;
  BackendDAE.Variables vars_;
  BackendDAE.EquationArray eqns_, removedEqs;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;

  ht := HashTableExpToIndex.emptyHashTable();
  (systs, index, ht) := List.mapFold2(systs, encapsulateWhenConditions_EqSystem, 1, ht);

  // shared removedEqns
  ((removedEqs, vars, eqns, index, _)) :=
      BackendEquation.traverseEquationArray(shared.removedEqs, encapsulateWhenConditions_Equation,
                                             (BackendEquation.emptyEqnsSized(BackendEquation.getNumberOfEquations(shared.removedEqs)), DoubleEndedList.fromList({}), DoubleEndedList.fromList({}), index, ht) );
  shared.removedEqs := removedEqs;
  eqns_ := BackendEquation.listEquation(DoubleEndedList.toListNoCopyNoClear(eqns));
  vars_ := BackendVariable.listVar(DoubleEndedList.toListNoCopyNoClear(vars));
  syst := BackendDAEUtil.createEqSystem(vars_, eqns_, {}, BackendDAE.UNSPECIFIED_PARTITION(), BackendEquation.emptyEqns());
  systs := listAppend(systs, {syst});

  outDAE := BackendDAE.DAE(systs, shared);
  if index > 1 then
    outDAE := SynchronousFeatures.contPartitioning(outDAE);
  end if;

  if Flags.isSet(Flags.DUMP_ENCAPSULATECONDITIONS) then
    BackendDump.dumpBackendDAE(outDAE, "DAE after PreOptModule >>encapsulateWhenConditions<<");
  end if;
end encapsulateWhenConditions;

protected function encapsulateWhenConditions_EqSystem "author: lochel"
  input BackendDAE.EqSystem inEqSystem;
  input Integer inIndex;
  input HashTableExpToIndex.HashTable inHT;
  output BackendDAE.EqSystem outEqSystem;
  output Integer outIndex;
  output HashTableExpToIndex.HashTable outHT;
algorithm
  outEqSystem := match inEqSystem
    local
      BackendDAE.Variables orderedVars;
      BackendDAE.EquationArray orderedEqs, removedEqs;
      BackendDAE.EqSystem syst;
      DoubleEndedList<BackendDAE.Var> varLst;
      DoubleEndedList<BackendDAE.Equation> eqnLst;
    case syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)
      algorithm
        ((orderedEqs, varLst, eqnLst, outIndex, outHT)) :=
            BackendEquation.traverseEquationArray( orderedEqs, encapsulateWhenConditions_Equation,
                                                   (BackendEquation.emptyEqnsSized(BackendEquation.getNumberOfEquations(orderedEqs)), DoubleEndedList.fromList({}), DoubleEndedList.fromList({}), inIndex, inHT) );

        // removed equations
        ((removedEqs, varLst, eqnLst, outIndex, outHT)) :=
            BackendEquation.traverseEquationArray( syst.removedEqs, encapsulateWhenConditions_Equation,
                                                   (BackendEquation.emptyEqnsSized(BackendEquation.getNumberOfEquations(syst.removedEqs)), varLst, eqnLst, outIndex, outHT) );
        syst.removedEqs := removedEqs;

        syst.orderedVars := BackendVariable.addVars(DoubleEndedList.toListNoCopyNoClear(varLst), orderedVars);
        syst.orderedEqs := BackendEquation.addList(DoubleEndedList.toListNoCopyNoClear(eqnLst), orderedEqs);
      then BackendDAEUtil.clearEqSyst(syst);
  end match;
end encapsulateWhenConditions_EqSystem;

protected function encapsulateWhenConditions_Equation "author: lochel"
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.EquationArray, DoubleEndedList<BackendDAE.Var>, DoubleEndedList<BackendDAE.Equation>, Integer, HashTableExpToIndex.HashTable> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendDAE.EquationArray, DoubleEndedList<BackendDAE.Var>, DoubleEndedList<BackendDAE.Equation>, Integer, HashTableExpToIndex.HashTable> outTpl;
algorithm
  (outEq,outTpl) := match (inEq,inTpl)
    local
      BackendDAE.Equation eqn, eqn2;
      DoubleEndedList<BackendDAE.Var> vars;
      DoubleEndedList<BackendDAE.Equation> eqns;
      list<BackendDAE.Var> vars1;
      list<BackendDAE.Equation> eqns1;
      BackendDAE.WhenEquation whenEquation;
      DAE.ElementSource source;
      Integer index, indexOrig, size, sizePre;
      BackendDAE.EquationArray equationArray;
      DAE.Algorithm alg_;
      list<DAE.Statement> stmts, preStmts, allPreStmts, allStmts;
      HashTableExpToIndex.HashTable ht;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes attr;

    // when equation
    case (BackendDAE.WHEN_EQUATION(size=size, whenEquation=whenEquation, source=source, attr=attr), (equationArray, vars, eqns, index, ht)) equation
      (whenEquation, vars1, eqns1, index, ht) = encapsulateWhenConditions_Equations(whenEquation, source, index, ht);
      DoubleEndedList.push_list_back(vars, vars1);
      DoubleEndedList.push_list_back(eqns, eqns1);
      eqn = BackendDAE.WHEN_EQUATION(size, whenEquation, source, attr);
      equationArray = BackendEquation.add(eqn, equationArray);
    then (eqn, (equationArray, vars, eqns, index, ht));

    // removed algorithm
    case (BackendDAE.ALGORITHM(size=0, alg=alg_, source=source, expand=crefExpand, attr=attr), (equationArray, vars, eqns, index, ht)) algorithm
      DAE.ALGORITHM_STMTS(statementLst=stmts) := alg_;
      size := -index;
      allPreStmts := {};
      allStmts := {};
      for stmt in stmts loop
        (stmts, preStmts, index) := encapsulateWhenConditions_Algorithms({stmt}, vars, index);
        allPreStmts := listAppend(preStmts,allPreStmts);
        allStmts := listAppend(stmts,allStmts);
      end for;
      stmts := listReverse(allStmts);
      sizePre := listLength(allPreStmts);
      size := size+index-sizePre;

      alg_ := DAE.ALGORITHM_STMTS(stmts);
      eqn := BackendDAE.ALGORITHM(size, alg_, source, crefExpand, attr);
      equationArray := BackendEquation.add(eqn, equationArray);

      if sizePre > 0 then
        alg_ := DAE.ALGORITHM_STMTS(allPreStmts);
        eqn2 := BackendDAE.ALGORITHM(sizePre, alg_, source, crefExpand, attr);
        DoubleEndedList.push_front(eqns, eqn2);
      end if;
    then (eqn, (equationArray, vars, eqns, index, ht));

    // algorithm
    case (BackendDAE.ALGORITHM(size=size, alg=alg_, source=source, expand=crefExpand, attr=attr), (equationArray, vars, eqns, index, ht)) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg_;
      size = size-index;
      (stmts, preStmts, index) = encapsulateWhenConditions_Algorithms(stmts, vars, index);
      size = size+index;

      stmts = listAppend(preStmts, stmts);

      alg_ = DAE.ALGORITHM_STMTS(stmts);
      eqn = BackendDAE.ALGORITHM(size, alg_, source, crefExpand, attr);
      equationArray = BackendEquation.add(eqn, equationArray);
    then (eqn, (equationArray, vars, eqns, index, ht));

    case (_, (equationArray, vars, eqns, index, ht)) equation
      equationArray = BackendEquation.add(inEq, equationArray);
    then (inEq, (equationArray, vars, eqns, index, ht));
  end match;
end encapsulateWhenConditions_Equation;

protected function encapsulateWhenConditions_Equations "author: lochel"
  input BackendDAE.WhenEquation inWhenEquation;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  input HashTableExpToIndex.HashTable inHT;
  output BackendDAE.WhenEquation outWhenEquation;
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outEqns;
  output Integer outIndex;
  output HashTableExpToIndex.HashTable outHT;
algorithm
  (outWhenEquation, outVars, outEqns, outIndex, outHT) := match (inWhenEquation)
    local
      Integer index;
      BackendDAE.WhenEquation elsewhenPart, whenEquation;
      list<BackendDAE.Var> vars, vars1;
      list<BackendDAE.Equation> eqns, eqns1;

      DAE.Exp condition;
      DAE.ComponentRef left;
      DAE.Exp right;

      HashTableExpToIndex.HashTable ht;

      list<BackendDAE.WhenOperator> whenStmtLst;

    // when - stmts
    case BackendDAE.WHEN_STMTS(condition=condition, whenStmtLst=whenStmtLst, elsewhenPart=NONE()) equation
      (condition, vars, eqns, index, ht) = encapsulateWhenConditions_Equations1(condition, inSource, inIndex, inHT);
      whenEquation = BackendDAE.WHEN_STMTS(condition, whenStmtLst, NONE());
    then (whenEquation, vars, eqns, index, ht);

    // when - stmts - elsewhen
    case BackendDAE.WHEN_STMTS(condition=condition, whenStmtLst=whenStmtLst, elsewhenPart=SOME(elsewhenPart)) equation
      (elsewhenPart, vars1, eqns1, index, ht) = encapsulateWhenConditions_Equations(elsewhenPart, inSource, inIndex, inHT);
      (condition, vars, eqns, index, ht) = encapsulateWhenConditions_Equations1(condition, inSource, index, ht);
      whenEquation = BackendDAE.WHEN_STMTS(condition, whenStmtLst, SOME(elsewhenPart));
      vars = listAppend(vars, vars1);
      eqns = listAppend(eqns, eqns1);
    then (whenEquation, vars, eqns, index, ht);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_Equations failed"});
    then fail();
  end match;
end encapsulateWhenConditions_Equations;

protected function encapsulateWhenConditions_Equations1 "author: lochel"
  input DAE.Exp inCondition;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  input HashTableExpToIndex.HashTable inHT;
  output DAE.Exp outCondition;
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outEqns;
  output Integer outIndex;
  output HashTableExpToIndex.HashTable outHT;
algorithm
  (outCondition, outVars, outEqns, outIndex, outHT) := match(inCondition)
    local
      Integer index, localIndex;
      BackendDAE.Var var;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> vars;
      list<BackendDAE.Equation> eqns;
      String crStr;
      DAE.Exp crefPreExp;

      DAE.Exp condition;
      list<DAE.Exp> array;

      DAE.Type ty;
      Boolean scalar "scalar for codegen" ;

      HashTableExpToIndex.HashTable ht;

    // we do not replace initial()
    case DAE.CALL(path=Absyn.IDENT(name="initial"))
      then (inCondition, {}, {}, inIndex, inHT);

    // we do not replace constant expressions
    case _
      guard Expression.isConst(inCondition)
      then (inCondition, {}, {}, inIndex, inHT);

    // array-condition
    case DAE.ARRAY(ty=ty, scalar=scalar, array=array)
      equation
        (array, vars, eqns, index, ht) = encapsulateWhenConditions_EquationsWithArrayConditions(array, inSource, inIndex, inHT);
      then (DAE.ARRAY(ty, scalar, array), vars, eqns, index, ht);

    // simple condition [already in ht]
    case _
      guard BaseHashTable.hasKey(inCondition, inHT)
      equation
        localIndex = BaseHashTable.get(inCondition, inHT);
        crStr = "$whenCondition" + intString(localIndex);
        condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
      then (condition, {}, {}, inIndex, inHT);

    // simple condition [not yet in ht]
    else
      algorithm
        ht := BaseHashTable.add((inCondition, inIndex), inHT);
        crStr := "$whenCondition" + intString(inIndex);

        var := BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, DAEUtil.setProtectedAttr(SOME(DAE.emptyVarAttrBool), true), NONE(), DAE.BCONST(true), SOME(SCode.COMMENT(NONE(), SOME(ExpressionDump.printExpStr(inCondition)))), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
        var := BackendVariable.setVarFixed(var, true);
        eqn := BackendDAE.EQUATION(DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT), inCondition, inSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);

        condition := DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
      then (condition, {var}, {eqn}, inIndex+1, ht);

  end match;
end encapsulateWhenConditions_Equations1;

protected function encapsulateWhenConditions_EquationsWithArrayConditions "author: lochel"
  input list<DAE.Exp> inConditionList;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  input HashTableExpToIndex.HashTable inHT;
  output list<DAE.Exp> outConditionList = {};
  output list<BackendDAE.Var> outVars = {};
  output list<BackendDAE.Equation> outEqns = {};
  output Integer outIndex = inIndex;
  output HashTableExpToIndex.HashTable outHT = inHT;
protected
  list<BackendDAE.Var> vars1;
  list<BackendDAE.Equation> eqns1;
algorithm
  for condition in inConditionList loop
    (condition, vars1, eqns1, outIndex, outHT) := encapsulateWhenConditions_Equations1(condition, inSource, outIndex, outHT);
    outVars := List.append_reverse(vars1,outVars);
    outEqns := List.append_reverse(eqns1,outEqns);
    outConditionList := condition::outConditionList;
  end for;
  outVars := listReverse(outVars);
  outEqns := listReverse(outEqns);
  outConditionList := listReverse(outConditionList);
end encapsulateWhenConditions_EquationsWithArrayConditions;

protected function encapsulateWhenConditions_Algorithms "author: lochel"
  input list<DAE.Statement> inStmts;
  input DoubleEndedList<BackendDAE.Var> vars;
  input Integer inIndex;
  output list<DAE.Statement> outStmts;
  output list<DAE.Statement> outPreStmts; // these are additional statements that should be inserted directly before a STMT_WHEN
  output Integer outIndex;
algorithm
  (outStmts, outPreStmts, outIndex) := match inStmts
    local
      DAE.Exp condition;
      DAE.Statement stmt, stmt2, elseWhen;
      list<DAE.Statement> stmts, rest, stmts1, stmts_, preStmts, preStmts2, elseWhenList;
      Integer index;
      DAE.ElementSource source;
      list<BackendDAE.Var> vars1;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case {} then ({}, {}, inIndex);

    // when statement
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=NONE(), source=source)::rest equation
      (condition, vars1, preStmts, index) = encapsulateWhenConditions_Algorithms1(condition, source, inIndex);
      (conditions, initialCall) = BackendDAEUtil.getConditionList(condition);
      DoubleEndedList.push_list_front(vars, vars1);

      if listEmpty(CheckModel.algorithmStatementListOutputs(stmts1, DAE.EXPAND())) then
        // without outputs
        (stmts, preStmts2, index) = encapsulateWhenConditions_Algorithms(rest, vars, index);
        preStmts = listAppend(preStmts, preStmts2);
        stmts_ = DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, NONE(), source)::stmts;
      else
        (stmts, stmts_, index) = encapsulateWhenConditions_Algorithms(rest, vars, index);
        stmts_ = DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, NONE(), source)::stmts_;
        stmts_ = listAppend(stmts_, stmts);
      end if;
    then (stmts_, preStmts, index);

    // when - elsewhen statement
    case (stmt as DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=SOME(elseWhen), source=source))::rest equation
      (condition, vars1, preStmts, index) = encapsulateWhenConditions_Algorithms1(condition, source, inIndex);
      (conditions, initialCall) = BackendDAEUtil.getConditionList(condition);
      DoubleEndedList.push_list_front(vars, vars1);

      (elseWhenList, preStmts2, index) = encapsulateWhenConditions_Algorithms({elseWhen}, vars, index);

      if listEmpty(elseWhenList) then
        (stmts, preStmts, index) = encapsulateWhenConditions_Algorithms(rest, vars, inIndex);
        stmts_ = stmt::listAppend(preStmts, stmts);
      else
        elseWhen = List.last(elseWhenList);
        stmt2 = DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, SOME(elseWhen), source);
        if listEmpty(CheckModel.algorithmStatementListOutputs({stmt2}, DAE.EXPAND())) then
          // without outputs
          preStmts2 = List.stripLast(elseWhenList);
          preStmts = listAppend(preStmts, preStmts2);
          (stmts, preStmts2, index) = encapsulateWhenConditions_Algorithms(rest, vars, index);
          preStmts = listAppend(preStmts, preStmts2);
          stmts_ = stmt2::stmts;
        elseif listLength(elseWhenList)==1 then
          preStmts = listAppend(preStmts, preStmts2);
          (stmts, stmts_, index) = encapsulateWhenConditions_Algorithms(rest, vars, index);
          stmts_ = stmt2::listAppend(stmts_, stmts);
        else
          (stmts, preStmts, index) = encapsulateWhenConditions_Algorithms(rest, vars, inIndex);
          stmts_ = listAppend(preStmts, stmts);
        end if;
      end if;
    then (stmts_, preStmts, index);

    // no when statement
    case stmt::rest equation
      (stmts, preStmts, index) = encapsulateWhenConditions_Algorithms(rest, vars, inIndex);
      stmts = listAppend(preStmts, stmts);
    then (stmt::stmts, {}, index);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_Algorithms failed"});
    then fail();
  end match;
end encapsulateWhenConditions_Algorithms;

protected function encapsulateWhenConditions_Algorithms1 "author: lochel"
  input DAE.Exp inCondition;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  output DAE.Exp outCondition;
  output list<BackendDAE.Var> outVars;
  output list<DAE.Statement> outStmts;
  output Integer outIndex;
algorithm
  (outCondition, outVars, outStmts, outIndex) := match inCondition
    local
      Integer index;
      BackendDAE.Var var;
      DAE.Statement stmt;
      list<BackendDAE.Var> vars;
      list<DAE.Statement> stmts;
      String crStr;
      DAE.Exp crefPreExp;

      DAE.Exp condition;
      list<DAE.Exp> array;

      DAE.Type ty;
      Boolean scalar "scalar for codegen" ;

    // we do not replace initial()
    case (DAE.CALL(path=Absyn.IDENT(name="initial")))
    then (inCondition, {}, {}, inIndex);

    // we do not replace constant expressions
    case _ guard(Expression.isConst(inCondition)) equation
    then (inCondition, {}, {}, inIndex);

    // array-condition
    case (DAE.ARRAY(array={condition})) equation
      crStr = "$whenCondition" + intString(inIndex);

      var = BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, DAEUtil.setProtectedAttr(SOME(DAE.emptyVarAttrBool), true), NONE(), DAE.BCONST(true), SOME(SCode.COMMENT(NONE(), SOME(ExpressionDump.printExpStr(inCondition)))), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
      var = BackendVariable.setVarFixed(var, true);
      stmt = DAE.STMT_ASSIGN(DAE.T_BOOL_DEFAULT, DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT), condition, inSource);

      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
    then (condition, {var}, {stmt}, inIndex+1);

    // array-condition
    case (DAE.ARRAY(ty=ty, scalar=scalar, array=array)) equation
      (array, vars, stmts, index) = encapsulateWhenConditions_AlgorithmsWithArrayConditions(array, inSource, inIndex);
    then (DAE.ARRAY(ty, scalar, array), vars, stmts, index);

    // simple condition
    case _ equation
      crStr = "$whenCondition" + intString(inIndex);

      var = BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, DAEUtil.setProtectedAttr(SOME(DAE.emptyVarAttrBool), true), NONE(), DAE.BCONST(true), SOME(SCode.COMMENT(NONE(), SOME(ExpressionDump.printExpStr(inCondition)))), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
      var = BackendVariable.setVarFixed(var, true);
      stmt = DAE.STMT_ASSIGN(DAE.T_BOOL_DEFAULT, DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT), inCondition, inSource);

      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
    then (condition, {var}, {stmt}, inIndex+1);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_Algorithms1 failed"});
    then fail();
  end match;
end encapsulateWhenConditions_Algorithms1;

protected function encapsulateWhenConditions_AlgorithmsWithArrayConditions "author: lochel"
  input list<DAE.Exp> inConditionList;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  output list<DAE.Exp> outConditionList = {};
  output list<BackendDAE.Var> outVars = {};
  output list<DAE.Statement> outStmts = {};
  output Integer outIndex = inIndex;
protected
  list<BackendDAE.Var> vars1;
  list<DAE.Statement> stmt1;
algorithm
  for condition in inConditionList loop
    (condition, vars1, stmt1, outIndex) := encapsulateWhenConditions_Algorithms1(condition, inSource, outIndex);
    outVars := List.append_reverse(vars1,outVars);
    outStmts := List.append_reverse(stmt1,outStmts);
    outConditionList := condition::outConditionList;
  end for;
  outVars := listReverse(outVars);
  outStmts := listReverse(outStmts);
  outConditionList := listReverse(outConditionList);
end encapsulateWhenConditions_AlgorithmsWithArrayConditions;


// =============================================================================
// section for zero crossings
//
// This section contains all the functions to find zero crossings inside
// BackendDAE.
// =============================================================================

public function findZeroCrossings "This function finds all zero crossings in the list of equations and
  the list of when clauses."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
algorithm
  //BackendDump.dumpBackendDAE(inDAE, "findZeroCrossings: inDAE");
  outDAE := BackendDAEUtil.mapEqSystem(inDAE, findZeroCrossings1);
  //BackendDump.dumpBackendDAE(outDAE, "findZeroCrossings: outDAE");
end findZeroCrossings;

protected function findZeroCrossings1 "
  This function finds all zero-crossings in the list of equations and the list of when clauses."
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSyst = inSyst;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.StrongComponents comps;
  array<Integer> ass1, ass2;
  BackendDAE.Matching matching;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, matching=matching ) := inSyst;
  (outSyst, outShared) := match BackendDAEUtil.getSubClock(inSyst, inShared)
    local
      BackendDAE.Variables globalKnownVars;
      BackendDAE.EquationArray eqns1;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.Equation> eqs_lst, eqs_lst1;
      list<BackendDAE.TimeEvent> timeEvents;
      BackendDAE.ZeroCrossingSet zero_crossings, sampleLst;
      DoubleEndedList<BackendDAE.ZeroCrossing> relations;
      Integer countMathFunctions;
      Option<String> solver;
    //No zero crossing for clocked discrete partitions;
    case SOME(BackendDAE.SUBCLOCK(solver = solver))
      guard BackendDump.optionString(solver) <> "External"
      then (inSyst, inShared);
    else
      algorithm
        BackendDAE.SHARED( globalKnownVars=globalKnownVars, eventInfo=einfo) := inShared;
        BackendDAE.EVENT_INFO( timeEvents=timeEvents, zeroCrossings=zero_crossings,
                               samples=sampleLst, relations=relations,
                               numberMathEvents=countMathFunctions ) := einfo;
        eqs_lst := BackendEquation.equationList(eqns);
        (zero_crossings, eqs_lst1, countMathFunctions, relations, sampleLst) :=
        findZeroCrossings2( vars, globalKnownVars, eqs_lst, 0,
                            countMathFunctions, zero_crossings, relations, sampleLst, {});
        eqs_lst1 := listReverse(eqs_lst1);
        eqns1 := BackendEquation.listEquation(eqs_lst1);
        if Flags.isSet(Flags.RELIDX) then
          print("findZeroCrossings1 number of relations: " + intString(DoubleEndedList.length(relations)) + "\n");
          print("findZeroCrossings1 sample index: " + intString(ZeroCrossings.length(sampleLst)) + "\n");
        end if;
        // replace zerocrossing expressions also in jacobian matrices
        try
          BackendDAE.MATCHING(comps=comps, ass1=ass1, ass2=ass2) := matching;
          comps := findZeroCrossingsinJacobians(comps, zero_crossings, relations, sampleLst, vars, globalKnownVars);
          outSyst.orderedEqs := eqns1;
          outSyst.matching := BackendDAE.MATCHING(ass1, ass2, comps);
        else
        end try;
        einfo := BackendDAE.EVENT_INFO( timeEvents, zero_crossings, relations, sampleLst,
                                           countMathFunctions );
      then (outSyst, BackendDAEUtil.setSharedEventInfo(inShared, einfo));
  end match;
end findZeroCrossings1;

protected function findZeroCrossings2
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables globalKnownVars;
  input list<BackendDAE.Equation> inEquationLst2;
  input Integer inEqnCount;
  input Integer inNumberOfMathFunctions;
  input BackendDAE.ZeroCrossingSet inZeroCrossingLst;
  input DoubleEndedList<BackendDAE.ZeroCrossing> inRelationsLst;
  input BackendDAE.ZeroCrossingSet inSamplesLst;
  input list<BackendDAE.Equation> inEquationLstAccum;
  output BackendDAE.ZeroCrossingSet outZeroCrossingLst;
  output list<BackendDAE.Equation> outEquationLst;
  output Integer outNumberOfMathFunctions;
  output DoubleEndedList<BackendDAE.ZeroCrossing> outRelationsLst;
  output BackendDAE.ZeroCrossingSet outSamplesLst;
algorithm
  (outZeroCrossingLst, outEquationLst, outNumberOfMathFunctions, outRelationsLst, outSamplesLst) := match (inEquationLst2)
    local
      BackendDAE.ZeroCrossingSet zcs, zcs1, res, res1, sampleLst;
      DoubleEndedList<BackendDAE.ZeroCrossing> relationsLst;
      Integer size, eq_count_1, eq_count, countMathFunctions;
      BackendDAE.Equation e;
      list<BackendDAE.Equation> xs, el, eq_reslst, eqnsAccum;
      DAE.Exp daeExp, e1, e2, eres1, eres2;
      DAE.ElementSource source, source_;
      list<DAE.Statement> stmts, stmts_1;
      DAE.ComponentRef cref;
      list<BackendDAE.WhenOperator> whenOperations;
      Option<Integer> elseClause_;
      list<Integer> dimsize;
      BackendDAE.WhenEquation weqn;
      Boolean diffed;
      DAE.Expand expand;
      BackendDAE.EquationAttributes eqAttr;

    case ({})
    then (inZeroCrossingLst, inEquationLstAccum, inNumberOfMathFunctions, inRelationsLst, inSamplesLst);

    // all algorithm stmts are processed firstly
    case (BackendDAE.ALGORITHM(size=size, alg=DAE.ALGORITHM_STMTS(stmts), source=source_, expand=expand, attr=eqAttr)::xs) equation
      eq_count = inEqnCount + 1;
      (stmts_1, (_, _, _, (res, relationsLst, sampleLst, countMathFunctions), _)) = traverseStmtsExps(stmts, (DAE.RCONST(0.0), {}, DAE.RCONST(0.0), (inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfMathFunctions), (eq_count, inVariables1, globalKnownVars)), globalKnownVars);
      eqnsAccum = BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(stmts_1), source_, expand, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, eq_count, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);

    // check when equation condition
    case ((BackendDAE.WHEN_EQUATION(size=size, whenEquation=weqn, source=source_, attr=eqAttr))::xs) equation
      eq_count = inEqnCount + 1;
      (weqn, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossingsWhenEqns(weqn, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
      eqnsAccum = BackendDAE.WHEN_EQUATION(size, weqn, source_, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, eq_count, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);

    // after all algorithms and when clauses are processed, all equations are processed
    case ((BackendDAE.EQUATION(exp=e1, scalar=e2, source=source_, attr=eqAttr))::xs) equation
      eq_count = inEqnCount + 1;
      (eres1, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
      (eres2, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
       eqnsAccum = BackendDAE.EQUATION(eres1, eres2, source_, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, eq_count, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);

    case ((BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=source, attr=eqAttr))::xs) equation
      eq_count = inEqnCount + 1;
      (eres1, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
      (eres2, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
      eqnsAccum = BackendDAE.COMPLEX_EQUATION(size, eres1, eres2, source, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, eq_count, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);

    case ((BackendDAE.ARRAY_EQUATION(dimSize=dimsize, left=e1, right=e2, source=source, attr=eqAttr))::xs) equation
      eq_count = inEqnCount + 1;
      (eres1, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
      (eres2, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
      eqnsAccum = BackendDAE.ARRAY_EQUATION(dimsize, eres1, eres2, source, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, eq_count, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);

    case ((BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=e1, source=source_, attr=eqAttr))::xs) equation
      (eres1, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfMathFunctions, inEqnCount, -1, inVariables1, globalKnownVars);
      eqnsAccum = BackendDAE.SOLVED_EQUATION(cref, eres1, source_, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, inEqnCount, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);

    case ((BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source_, attr=eqAttr))::xs) equation
      eq_count = inEqnCount + 1;
      (eres1, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
      eqnsAccum = BackendDAE.RESIDUAL_EQUATION(eres1, source_, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, eq_count, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);

    case ((e as BackendDAE.IF_EQUATION())::xs) equation
      eq_count = inEqnCount + 1;
      (e, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossingsIfEqns(e, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfMathFunctions, eq_count, -1, inVariables1, globalKnownVars);
      eqnsAccum = e::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, eq_count, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);

    // let when equation pass they are discrete and can't contain ZeroCrossings
    case (e::xs) equation
      eq_count = inEqnCount + 1;
      eqnsAccum = e::inEquationLstAccum;
      (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, globalKnownVars, xs, eq_count, inNumberOfMathFunctions, inZeroCrossingLst, inRelationsLst, inSamplesLst, eqnsAccum);
    then (res1, eq_reslst, countMathFunctions, relationsLst, sampleLst);
  end match;
end findZeroCrossings2;

protected function findZeroCrossingsWhenEqns
  input BackendDAE.WhenEquation inWhenEqn;
  input BackendDAE.ZeroCrossingSet inZeroCrossings;
  input DoubleEndedList<BackendDAE.ZeroCrossing> inrelationsinZC;
  input BackendDAE.ZeroCrossingSet inSamplesLst;
  input Integer incountMathFunctions;
  input Integer counteq;
  input Integer countwc;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.WhenEquation oWhenEqn;
  output Integer outCountMathFunctions;
  output BackendDAE.ZeroCrossingSet outZeroCrossings;
  output DoubleEndedList<BackendDAE.ZeroCrossing> outrelationsinZC;
  output BackendDAE.ZeroCrossingSet outSamplesLst;
algorithm
  (oWhenEqn, outCountMathFunctions, outZeroCrossings, outrelationsinZC, outSamplesLst) := match(inWhenEqn)
    local
      DAE.Exp cond, e;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we;
      BackendDAE.ZeroCrossingSet zc, samples;
      DoubleEndedList<BackendDAE.ZeroCrossing> relations;
      Integer countMathFunctions;
      list<BackendDAE.WhenOperator> whenStmtLst;
      Option<BackendDAE.WhenEquation> oweelse;

    case BackendDAE.WHEN_STMTS(condition=cond, whenStmtLst = whenStmtLst, elsewhenPart=oweelse) equation
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.debugStrExpStr("processed when condition: ", cond, "\n");
      end if;
      (cond, countMathFunctions, zc, relations, samples) = findZeroCrossings3(cond, inZeroCrossings, inrelationsinZC, inSamplesLst, incountMathFunctions, counteq, countwc, vars, globalKnownVars);
      if isSome(oweelse) then
        SOME(we) = oweelse;
        (we, countMathFunctions, zc, relations, samples) = findZeroCrossingsWhenEqns(we, zc, relations, samples, countMathFunctions, counteq, countwc, vars, globalKnownVars);
        oweelse = SOME(we);
      else
        oweelse = NONE();
      end if;
    then (BackendDAE.WHEN_STMTS(cond, whenStmtLst, oweelse), countMathFunctions, zc, relations, samples);
  end match;
end findZeroCrossingsWhenEqns;

protected function findZeroCrossingsIfEqns
  input BackendDAE.Equation inIfEqn;
  input BackendDAE.ZeroCrossingSet inZeroCrossings;
  input DoubleEndedList<BackendDAE.ZeroCrossing> inrelationsinZC;
  input BackendDAE.ZeroCrossingSet inSamplesLst;
  input Integer incountMathFunctions;
  input Integer counteq;
  input Integer countwc;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.Equation outIfEqn;
  output Integer outCountMathFunctions;
  output BackendDAE.ZeroCrossingSet outZeroCrossings;
  output DoubleEndedList<BackendDAE.ZeroCrossing> outrelationsinZC;
  output BackendDAE.ZeroCrossingSet outSamplesLst;
algorithm
  (outIfEqn, outCountMathFunctions, outZeroCrossings, outrelationsinZC, outSamplesLst) := match(inIfEqn)
    local
      DAE.Exp condition;
      list<DAE.Exp> conditions, restconditions;
      BackendDAE.Equation ifeqn;
      list<BackendDAE.Equation> eqnstrue, elseeqns, eqnsAccum;
      list<list<BackendDAE.Equation>> eqnsTrueLst, resteqns;
      BackendDAE.ZeroCrossingSet zc, samples;
      DoubleEndedList<BackendDAE.ZeroCrossing> relations;
      Integer countMathFunctions;
      DAE.ElementSource source_;
      BackendDAE.EquationAttributes eqAttr;

    case BackendDAE.IF_EQUATION(conditions={}, eqnstrue={}, eqnsfalse=elseeqns, source=source_, attr=eqAttr) equation
      (zc, elseeqns, countMathFunctions, relations, samples) = findZeroCrossings2(vars, globalKnownVars, elseeqns, counteq, incountMathFunctions, inZeroCrossings, inrelationsinZC, inSamplesLst, {});
      elseeqns = listReverse(elseeqns);
    then (BackendDAE.IF_EQUATION({}, {}, elseeqns, source_, eqAttr), countMathFunctions, zc, relations, samples);

    case BackendDAE.IF_EQUATION(conditions=condition::restconditions, eqnstrue=eqnstrue::resteqns, eqnsfalse=elseeqns, source=source_, attr=eqAttr) equation
      (condition, countMathFunctions, zc, relations, samples) = findZeroCrossings3(condition, inZeroCrossings, inrelationsinZC, inSamplesLst, incountMathFunctions, counteq, countwc, vars, globalKnownVars);
      (zc, eqnstrue, countMathFunctions, relations, samples) = findZeroCrossings2(vars, globalKnownVars, eqnstrue, counteq, countMathFunctions, zc, relations, samples, {});
      eqnstrue = listReverse(eqnstrue);
      ifeqn = BackendDAE.IF_EQUATION(restconditions, resteqns, elseeqns, source_, eqAttr);
      (BackendDAE.IF_EQUATION(conditions=conditions, eqnstrue=eqnsTrueLst, eqnsfalse=elseeqns, source=source_), countMathFunctions, zc, relations, samples) = findZeroCrossingsIfEqns(ifeqn, zc, relations, samples, countMathFunctions, counteq, countwc, vars, globalKnownVars);
      conditions = condition::conditions;
      eqnsTrueLst = eqnstrue::eqnsTrueLst;
    then (BackendDAE.IF_EQUATION(conditions, eqnsTrueLst, elseeqns, source_, eqAttr), countMathFunctions, zc, relations, samples);
  end match;
end findZeroCrossingsIfEqns;

protected function findZeroCrossingsinJacobians
  input BackendDAE.StrongComponents inStrongComponents;
  input BackendDAE.ZeroCrossingSet zeroCrossingLst;
  input DoubleEndedList<BackendDAE.ZeroCrossing> relationsLst;
  input BackendDAE.ZeroCrossingSet samplesLst;
  input BackendDAE.Variables allVariables;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.StrongComponents strongComponents = {};
protected
  BackendDAE.StrongComponent outComponent;
algorithm
  for component in inStrongComponents loop
    outComponent := matchcontinue (component)
      local
        BackendDAE.StrongComponent comp;
        BackendDAE.Jacobian jacobian;
        BackendDAE.FullJacobian fullJacobian;
        BackendDAE.SymbolicJacobian symJacobian;
        BackendDAE.SparsePattern sparsePattern;
        BackendDAE.SparseColoring coloring;
        BackendDAE.TearingSet tearingSet;
      case comp as BackendDAE.EQUATIONSYSTEM(jac=BackendDAE.FULL_JACOBIAN(jacobian=fullJacobian))
        equation
          fullJacobian = replaceZCExpinFullJacobian(fullJacobian, zeroCrossingLst, relationsLst, samplesLst, allVariables, globalKnownVars);
          comp.jac = BackendDAE.FULL_JACOBIAN(jacobian=fullJacobian);
        then comp;
      case comp as BackendDAE.EQUATIONSYSTEM(jac=jacobian as BackendDAE.GENERIC_JACOBIAN(jacobian=SOME(symJacobian),sparsePattern=sparsePattern, coloring=coloring))
        equation
          symJacobian = replaceZCExpinSymJacobian(symJacobian, zeroCrossingLst, relationsLst, samplesLst, allVariables, globalKnownVars);
          comp.jac = BackendDAE.GENERIC_JACOBIAN(jacobian=SOME(symJacobian),sparsePattern=sparsePattern,coloring=coloring);
        then comp;
      case comp as BackendDAE.TORNSYSTEM(strictTearingSet=tearingSet as BackendDAE.TEARINGSET(jac=jacobian as BackendDAE.GENERIC_JACOBIAN(jacobian=SOME(symJacobian),sparsePattern=sparsePattern, coloring=coloring)))
        equation
          symJacobian = replaceZCExpinSymJacobian(symJacobian, zeroCrossingLst, relationsLst, samplesLst, allVariables, globalKnownVars);
          tearingSet.jac = BackendDAE.GENERIC_JACOBIAN(jacobian=SOME(symJacobian),sparsePattern=sparsePattern,coloring=coloring);
          comp.strictTearingSet = tearingSet;
        then comp;
      else then component;
    end matchcontinue;
    strongComponents := outComponent::strongComponents;
  end for;
  strongComponents := listReverse(strongComponents);
end findZeroCrossingsinJacobians;

protected function replaceZCExpinFullJacobian
  input BackendDAE.FullJacobian fullJac;
  input BackendDAE.ZeroCrossingSet zeroCrossingLst;
  input DoubleEndedList<BackendDAE.ZeroCrossing> relationsLst;
  input BackendDAE.ZeroCrossingSet samplesLst;
  input BackendDAE.Variables allVariables;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.FullJacobian outFullJac;
protected
  list<tuple<Integer, Integer, BackendDAE.Equation>> jac, outJac = {};
  Integer i,j;
  BackendDAE.Equation eqn;
  tuple<Integer, Integer, BackendDAE.Equation> element;
algorithm
  jac := Util.getOption(fullJac);
  for element in jac loop
    (i,j,eqn) := element;
    (_, {eqn}, _, _, _) :=
        findZeroCrossings2( allVariables, globalKnownVars, {eqn}, 0,
                            0, zeroCrossingLst, relationsLst, samplesLst, {});
    outJac := (i,j,eqn)::outJac;
  end for;
  outJac := listReverse(outJac);
  outFullJac := SOME(outJac);
end replaceZCExpinFullJacobian;

protected function replaceZCExpinSymJacobian
  input BackendDAE.SymbolicJacobian symJac;
  input BackendDAE.ZeroCrossingSet zeroCrossingLst;
  input DoubleEndedList<BackendDAE.ZeroCrossing> relationsLst;
  input BackendDAE.ZeroCrossingSet samplesLst;
  input BackendDAE.Variables allVariables;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.SymbolicJacobian outSymJac;
protected
  BackendDAE.BackendDAE jacBDAE;
  String name;
  list<BackendDAE.Var> seedVars, tmpVars, resultVars;
  list<DAE.ComponentRef> depCrefs;
algorithm
  (jacBDAE, name, seedVars, tmpVars, resultVars, depCrefs) := symJac;
  jacBDAE := replaceZeroCrossingsJacBackend(jacBDAE, zeroCrossingLst, relationsLst, samplesLst, allVariables, globalKnownVars);
  outSymJac := (jacBDAE, name, seedVars, tmpVars, resultVars, depCrefs);
end replaceZCExpinSymJacobian;

protected function replaceZeroCrossingsJacBackend
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.ZeroCrossingSet zeroCrossingLst;
  input DoubleEndedList<BackendDAE.ZeroCrossing> relationsLst;
  input BackendDAE.ZeroCrossingSet samplesLst;
  input BackendDAE.Variables allVariables;
  input BackendDAE.Variables globalKnownVars;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.EqSystems eqs, outEqs = {};
  list<BackendDAE.Equation> eqs_lst;
  BackendDAE.Shared shared;
  BackendDAE.StrongComponents comps;
  array<Integer> ass1, ass2;
  BackendDAE.Matching matching;
algorithm
  BackendDAE.DAE(eqs, shared) := inBackendDAE;
  for system in eqs loop
    eqs_lst := BackendEquation.equationList(system.orderedEqs);
    (_, eqs_lst, _, _, _) :=
       findZeroCrossings2(allVariables, globalKnownVars, eqs_lst, 0, 0, zeroCrossingLst, relationsLst, samplesLst, {});
     eqns := BackendEquation.listEquation(listReverse(eqs_lst));
     system.orderedEqs := eqns;
     // componenents of the jacobian
     BackendDAE.MATCHING(comps=comps, ass1=ass1, ass2=ass2) := system.matching;
     comps := findZeroCrossingsinJacobians(comps, zeroCrossingLst, relationsLst, samplesLst, allVariables, globalKnownVars);
     matching := BackendDAE.MATCHING(comps=comps, ass1=ass1, ass2=ass2);
     system.matching := matching;
     outEqs := system::outEqs;
  end for;
  outEqs := listReverse(outEqs);
  outBackendDAE := BackendDAE.DAE(outEqs, shared);
end replaceZeroCrossingsJacBackend;

protected function findZeroCrossings3
  input DAE.Exp e;
  input BackendDAE.ZeroCrossingSet inZeroCrossings;
  input DoubleEndedList<BackendDAE.ZeroCrossing> inrelationsinZC;
  input BackendDAE.ZeroCrossingSet inSamplesLst;
  input Integer incountMathFunctions;
  input Integer counteq;
  input Integer countwc;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables globalKnownVars;
  output DAE.Exp eres;
  output Integer outCountMathFunctions;
  output BackendDAE.ZeroCrossingSet outZeroCrossings;
  output DoubleEndedList<BackendDAE.ZeroCrossing> outrelationsinZC;
  output BackendDAE.ZeroCrossingSet outSamplesLst;
algorithm
  if Flags.isSet(Flags.RELIDX) then
    BackendDump.debugStrExpStr("start: ", e, "\n");
  end if;
  (eres, ((outZeroCrossings, outrelationsinZC, outSamplesLst, outCountMathFunctions), _)) := Expression.traverseExpTopDown(e, collectZC, ((inZeroCrossings, inrelationsinZC, inSamplesLst, incountMathFunctions), (counteq, vars, globalKnownVars)));
end findZeroCrossings3;

protected function collectZC
  "Collects zero crossings in equations"
  input DAE.Exp inExp;
  input ZCArgType inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output ZCArgType outTpl;
algorithm
  (outExp,cont,outTpl) := match (inExp, inTpl)
    local
      DAE.Exp e, e1, e2, e_1, e_2, eres, eres1;
      BackendDAE.Variables vars, globalKnownVars;
      BackendDAE.ZeroCrossingSet zeroCrossings, zc_lst, samples;
      DoubleEndedList<BackendDAE.ZeroCrossing> relations;
      DAE.Operator op;
      Integer eq_count, itmp, numMathFunctions, oldNumRelations;
      BackendDAE.ZeroCrossing zc;
      DAE.CallAttributes attr;
      DAE.Type ty;
      tuple<Integer, BackendDAE.Variables, BackendDAE.Variables> tp1;
      ZCArgType tpl;
      Boolean empty;

    case (DAE.CALL(path=Absyn.IDENT(name="noEvent")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="smooth")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="sample")), ((_, _, samples, _), (eq_count, _, _))) equation
      zc = createZeroCrossing(inExp, {eq_count});
      mergeZeroCrossings(zc, samples);
      //itmp = (listLength(zc_lst)-listLength(zeroCrossings));
      //indx = indx + (listLength(zc_lst) - listLength(zeroCrossings));
      if Flags.isSet(Flags.RELIDX) then
        print("sample index: " + intString(ZeroCrossings.length(samples)) + "\n");
      end if;
    then (inExp, true, inTpl);

    // function with discrete expressions generate no zerocrossing
    case (DAE.LUNARY(exp=e1), ((_, relations, _, _), (_, vars, globalKnownVars)))
      guard not BackendDAEUtil.hasExpContinuousParts(e1, vars, globalKnownVars)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("discrete LUNARY: " + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, inTpl);

    case (DAE.LBINARY(exp1=e1, exp2=e2), ((_, relations, _, _), (_, vars, globalKnownVars)))
      guard not (BackendDAEUtil.hasExpContinuousParts(e1, vars, globalKnownVars) or BackendDAEUtil.hasExpContinuousParts(e2, vars, globalKnownVars))
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("discrete LBINARY: " + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, inTpl);

    // coditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), ((zeroCrossings, relations, _, _), _)) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY: " + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
      (e1, tpl as ((_, _, _, _), (eq_count, _, _))) = Expression.traverseExpTopDown(e1, collectZC, inTpl);
      e_1 = DAE.LUNARY(op, e1);
      zc = createZeroCrossing(e_1, {eq_count});
      empty = not ZeroCrossings.contains(zeroCrossings, zc);
      if empty then
        ZeroCrossings.add(zeroCrossings, zc);
      end if;
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, if empty then tpl else inTpl);

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), ((zeroCrossings, relations, samples, numMathFunctions), tp1)) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LBINARY: " + String(DoubleEndedList.length(relations)) + "\n");
        BackendDump.debugExpStr(inExp, "\n");
      end if;
      oldNumRelations = DoubleEndedList.length(relations);
      (e_1, ((_, relations, samples, numMathFunctions), tp1)) = Expression.traverseExpTopDown(e1, collectZC, ((ZeroCrossings.new(), relations, samples, numMathFunctions), tp1));
      (e_2, ((_, relations, samples, numMathFunctions), tp1 as (eq_count, _, _))) = Expression.traverseExpTopDown(e2, collectZC, ((ZeroCrossings.new(), relations, samples, numMathFunctions), tp1));
      if intGt(DoubleEndedList.length(relations), oldNumRelations) then
        e_1 = DAE.LBINARY(e_1, op, e_2);
        zc = createZeroCrossing(e_1, {eq_count});
        empty = not ZeroCrossings.contains(zeroCrossings, zc);
        cont = false;
        if empty then
          ZeroCrossings.add(zeroCrossings, zc);
        end if;
        if Flags.isSet(Flags.RELIDX) then
          BackendDump.dumpZeroCrossingList(ZeroCrossings.toList(zeroCrossings), "LBINARY");
        end if;
      else
        empty = true;
        cont = true;
      end if;
    then (if cont then inExp else e_1, cont, if not cont and empty then ((zeroCrossings, relations, samples, numMathFunctions), tp1) else inTpl);

    // function with discrete expressions generate no zerocrossing
    case (DAE.RELATION(exp1=e1, exp2=e2), ((_, relations, _, _), (_, vars, globalKnownVars)))
      guard not (BackendDAEUtil.hasExpContinuousParts(e1, vars, globalKnownVars) or BackendDAEUtil.hasExpContinuousParts(e2, vars, globalKnownVars))
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("discrete RELATION: " + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
    then (inExp, true, inTpl);

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), ((zeroCrossings, relations, samples, numMathFunctions), tp1 as (eq_count, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC (2): " + ExpressionDump.printExpStr(inExp) + " numRelations: " +intString(DoubleEndedList.length(relations)) + "\n");
      end if;
      e_1 = DAE.RELATION(e1, op, e2, DoubleEndedList.length(relations), NONE());
      zc = createZeroCrossing(e_1, {eq_count});
      (eres, relations) = zcIndexRelation(e_1, relations, DoubleEndedList.length(relations), zc);
      zc = createZeroCrossing(eres, {eq_count});
      (DAE.RELATION(index=itmp), zeroCrossings, _) = zcIndex(eres, zeroCrossings, DoubleEndedList.length(relations), zc);
      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + " index: " + intString(itmp) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numMathFunctions), tp1));

    // math function that triggering events
    case (DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numMathFunctions), tp1 as (eq_count, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("integer"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numMathFunctions), tp1));

    case (DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numMathFunctions), tp1 as (eq_count, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("floor"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numMathFunctions), tp1));

    case (DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numMathFunctions), tp1 as (eq_count, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("ceil"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numMathFunctions), tp1));

    case (DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2}, attr=attr), ((zeroCrossings, relations, samples, numMathFunctions), tp1 as (eq_count, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numMathFunctions), tp1));

    case (DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR()), ((zeroCrossings, relations, samples, numMathFunctions), tp1 as (eq_count, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("mod"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numMathFunctions), tp1));

    // rem is rewritten to div(x/y)*y - x
    case (DAE.CALL(path=Absyn.IDENT("rem"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty=ty)), ((zeroCrossings, relations, samples, numMathFunctions), tp1 as (eq_count, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);
      e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (e_2, true, ((zeroCrossings, relations, samples, numMathFunctions), tp1));

    else (inExp, true, inTpl);
  end match;
end collectZC;

protected function collectZCAlgsFor
  "Collects zero crossings in for loops"
  input DAE.Exp inExp;
  input ForArgType inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output ForArgType outTpl;
algorithm
  (outExp,cont,outTpl) := match (inExp, inTpl)
    local
      DAE.Exp e, e1, e2, e_1, e_2, eres, iterator, range, range2;
      list<DAE.Exp> inExpLst, explst;
      BackendDAE.Variables vars, globalKnownVars;
      BackendDAE.ZeroCrossingSet zeroCrossings, samples;
      DoubleEndedList<BackendDAE.ZeroCrossing> relations;
      list<BackendDAE.ZeroCrossing> zcLstNew, zc_lst;
      DAE.Operator op;
      Integer numEqual, alg_indx, itmp, numMathFunctions, oldNumRelations;
      list<Integer> eqs;
      DAE.Exp startvalue, stepvalue;
      Option<DAE.Exp> stepvalueopt;
      Integer istart, istep;
      BackendDAE.ZeroCrossing zc;
      DAE.CallAttributes attr;
      DAE.Type ty;
      list<DAE.Exp> le;
      tuple<Integer, BackendDAE.Variables, BackendDAE.Variables> tp1;
      ForArgType tpl;
      tuple<BackendDAE.ZeroCrossingSet, DoubleEndedList<BackendDAE.ZeroCrossing>, BackendDAE.ZeroCrossingSet, Integer> tp2;

    case (DAE.CALL(path=Absyn.IDENT(name="noEvent")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="smooth")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="sample")), (_, _, _, (_, _, samples, _), (alg_indx, _, _))) equation
      eqs = {alg_indx};
      zc = createZeroCrossing(inExp, eqs);
      ZeroCrossings.add(samples, zc);
      if Flags.isSet(Flags.RELIDX) then
        print("sample index algotihm: " + intString(alg_indx) + "\n");
      end if;
    then (inExp, true, inTpl);

    case (DAE.LUNARY(exp=e1), (_, _, _, _, (_, vars, globalKnownVars)))
      guard not BackendDAEUtil.hasExpContinuousParts(e1, vars, globalKnownVars)
      then (inExp, true, inTpl);

    // conditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), (iterator, _, DAE.RANGE(), (zeroCrossings, relations, _, _), _))
      guard Expression.expContains(inExp, iterator)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY with Iterator: " + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
      (e1, tpl as (iterator, inExpLst, _, (_, relations, _, _), (alg_indx, _, _))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, inTpl);
      e_1 = DAE.LUNARY(op, e1);
      (explst,_) = replaceIteratorWithStaticValues(e_1, iterator, inExpLst, DoubleEndedList.length(relations));
      zc_lst = createZeroCrossings(explst, {alg_indx});
      ZeroCrossings.add_list(zeroCrossings, zc_lst);
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor LUNARY with Iterator result zc: ");
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, tpl);

    // coditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), (_, _, _, (zeroCrossings, relations, _, _), _)) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY: " + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
      (e1, tpl as (_, _, _, (_, _, _, _), (alg_indx, _, _))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, inTpl);
      e_1 = DAE.LUNARY(op, e1);
      zc = createZeroCrossing(e_1, {alg_indx});
      ZeroCrossings.add(zeroCrossings, zc);
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor LUNARY result zc: ");
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, tpl);

    case (DAE.LBINARY(exp1=e1, exp2=e2), (_, _, _, _, (_, vars, globalKnownVars)))
      guard not (BackendDAEUtil.hasExpContinuousParts(e1, vars, globalKnownVars) or BackendDAEUtil.hasExpContinuousParts(e2, vars, globalKnownVars))
      then (inExp, true, inTpl);

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numMathFunctions), tp1))
      algorithm
      if Flags.isSet(Flags.RELIDX) then
        print("continues LBINARY: " + intString(DoubleEndedList.length(relations)) + "\n");
        BackendDump.debugExpStr(inExp, "\n");
      end if;
      oldNumRelations := DoubleEndedList.length(relations);
      (e_1, (_, inExpLst, range, tp2, tp1)) := Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (ZeroCrossings.new(), relations, samples, numMathFunctions), tp1));
      (e_2, (_, inExpLst, range, (_, relations, samples, numMathFunctions), tp1 as (alg_indx, _, _))) := Expression.traverseExpTopDown(e2, collectZCAlgsFor, (iterator, inExpLst, range, tp2, tp1));
      if intGt(DoubleEndedList.length(relations), oldNumRelations) then
        e_1 := DAE.LBINARY(e_1, op, e_2);
        if Expression.expContains(e1, iterator) or Expression.expContains(e2, iterator) then
          (explst,_) := replaceIteratorWithStaticValues(e_1, iterator, inExpLst, DoubleEndedList.length(relations));
          zc_lst := createZeroCrossings(explst, {alg_indx});
          ZeroCrossings.add_list(zeroCrossings, zc_lst);
          if Flags.isSet(Flags.RELIDX) then
            BackendDump.dumpZeroCrossingList(ZeroCrossings.toList(zeroCrossings), "collectZCAlgsFor LBINARY1 result zc");
          end if;
        else
          zc := createZeroCrossing(e_1, {alg_indx});
          if not ZeroCrossings.contains(zeroCrossings, zc) then
            ZeroCrossings.add(zeroCrossings, zc);
          end if;
          if Flags.isSet(Flags.RELIDX) then
            BackendDump.dumpZeroCrossingList(ZeroCrossings.toList(zeroCrossings), "collectZCAlgsFor LBINARY2 result zc");
          end if;
        end if;
        cont := false;
        tpl := (iterator, inExpLst, range, (zeroCrossings, relations, samples, numMathFunctions), tp1);
      else
        e_1 := inExp;
        cont := true;
        tpl := inTpl;
      end if;
    then (e_1, cont, tpl);

    // function with discrete expressions generate no zerocrossing.
    case (DAE.RELATION(exp1=e1, exp2=e2), (_, _, _, _, (_, vars, globalKnownVars)))
      guard not (BackendDAEUtil.hasExpContinuousParts(e1, vars, globalKnownVars) or BackendDAEUtil.hasExpContinuousParts(e2, vars, globalKnownVars))
      then (inExp, true, inTpl);

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range as DAE.RANGE(start=startvalue, step=stepvalueopt), (zeroCrossings, relations, samples, numMathFunctions), tp1 as (alg_indx, _, globalKnownVars)))
      guard if Flags.isSet(Flags.EVENTS) then (if Expression.expContains(e1, iterator) then true else Expression.expContains(e2, iterator)) else false
      equation
      if Flags.isSet(Flags.RELIDX) then
        print(" number of relations: " + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
      stepvalue = Util.getOptionOrDefault(stepvalueopt, DAE.ICONST(1));
      istart = BackendDAEUtil.expInt(startvalue, globalKnownVars);
      istep = BackendDAEUtil.expInt(stepvalue, globalKnownVars);
      eres = DAE.RELATION(e1, op, e2, DoubleEndedList.length(relations), SOME((iterator, istart, istep)));
      (explst, itmp) = replaceIteratorWithStaticValues(inExp, iterator, inExpLst, DoubleEndedList.length(relations));
      if Flags.isSet(Flags.RELIDX) then
        print(" number of new zc (1): " + intString(listLength(explst)) + "\n");
      end if;
      zcLstNew = createZeroCrossings(explst, {alg_indx});
      DoubleEndedList.push_list_back(relations, zcLstNew);
      if Flags.isSet(Flags.RELIDX) then
        print(" number of new zc (2): " + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
      itmp = listLength(zcLstNew);
      if Flags.isSet(Flags.RELIDX) then
        print(" itmp: " + intString(itmp) + "\n");
      end if;
      ZeroCrossings.add_list(zeroCrossings, zcLstNew);
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor result zc: " + ExpressionDump.printExpStr(eres)+ " index:" + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
    then (eres, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numMathFunctions), tp1));

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numMathFunctions), tp1 as (alg_indx, _, _)))
      guard Flags.isSet(Flags.EVENTS) // and (not Expression.expContains(e1, iterator) or Expression.expContains(e2, iterator))
      equation
      eres = DAE.RELATION(e1, op, e2, DoubleEndedList.length(relations), NONE());
      zc = createZeroCrossing(eres, {alg_indx});
      DoubleEndedList.push_back(relations, zc);
      ZeroCrossings.add(zeroCrossings, zc);
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor result zc: " + ExpressionDump.printExpStr(eres)+ " index:" + intString(DoubleEndedList.length(relations)) + "\n");
      end if;
    then (eres, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numMathFunctions), tp1));

    // math function that triggering events
    case (DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1 as (alg_indx, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("integer"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1));

    case (DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1 as (alg_indx, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("floor"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1));

    case (DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1 as (alg_indx, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("ceil"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1));

    case (DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1 as (alg_indx, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1));

    case (DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR()), (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1 as (alg_indx, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("mod"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1));

    // rem is rewritten to div(x/y)*y - x
    case (DAE.CALL(path=Absyn.IDENT("rem"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1 as (alg_indx, _, _)))
      guard Flags.isSet(Flags.EVENTS)
      equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, zeroCrossings, numMathFunctions, zc);
      e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (e_2, true, (iterator, le, range, (zeroCrossings, relations, samples, numMathFunctions), tp1));

    else (inExp, true, inTpl);
  end match;
end collectZCAlgsFor;

protected function replaceIteratorWithStaticValues
  input DAE.Exp inExp;
  input DAE.Exp inIterator;
  input list<DAE.Exp> inExpLst;
  input Integer inIndex;
  output list<DAE.Exp> outZeroCrossings;
  output Integer outIndex;
algorithm
  (outZeroCrossings, outIndex) := match(inExp, inExpLst)
    local
      DAE.Exp e, e1, e2, res1, e_1;
      DAE.Operator op;
      list<DAE.Exp> rest, res2;
      Integer index;

    case (_, {})
    then ({}, inIndex);

    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), e::rest) equation
      e_1 = DAE.RELATION(e1, op, e2, inIndex, NONE());
      (res1, _) = Expression.replaceExpTpl(e_1, (inIterator, e));
      (res2, index) = replaceIteratorWithStaticValues(inExp, inIterator, rest, inIndex+1);
      res2 = res1::res2;
    then (res2, index);

    case (DAE.LUNARY(exp=e1, operator=op), e::rest) equation
      e_1 = DAE.LUNARY(op, e1);
      (res1, _) = Expression.replaceExpTpl(e_1, (inIterator, e));
      (res2, index) = replaceIteratorWithStaticValues(inExp, inIterator, rest, inIndex+1);
      res2 = res1 :: res2;
    then (res2, index);

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), e::rest) equation
      e_1 = DAE.LBINARY(e1, op, e2);
      (res1, _) = Expression.replaceExpTpl(e_1, (inIterator, e));
      (res2, index) = replaceIteratorWithStaticValues(inExp, inIterator, rest, inIndex+1);
      res2 = res1 :: res2;
    then (res2, index);

    else equation
      Error.addInternalError("function replaceIteratorWithStaticValues failed", sourceInfo());
    then fail();
  end match;
end replaceIteratorWithStaticValues;

protected function zcIndex
  input output DAE.Exp relation;
  input output BackendDAE.ZeroCrossingSet zeroCrossings;
  input output Integer index;
  input BackendDAE.ZeroCrossing zc;
protected
  list<BackendDAE.ZeroCrossing> duplicate;
algorithm
  if ZeroCrossings.contains(zeroCrossings, zc) then
    BackendDAE.ZERO_CROSSING(relation_=relation) := ZeroCrossings.get(zeroCrossings, zc);
    return;
  end if;
  (relation, index) := match relation
    local
      DAE.Exp rel;
      DAE.Operator op;
      BackendDAE.ZeroCrossing newZeroCrossing;
      list<BackendDAE.ZeroCrossing> zcLst;

    case DAE.RELATION()
      algorithm
        ZeroCrossings.add(zeroCrossings, zc);
      then (relation, index+1);

    // math function with one argument and index
    case DAE.CALL(expLst={_, _})
      algorithm
        ZeroCrossings.add(zeroCrossings, zc);
      then (relation, index+1);

    // math function with two arguments and index
    case DAE.CALL(expLst={_, _, _})
      algorithm
        ZeroCrossings.add(zeroCrossings, zc);
      then (relation, index+2);

    else equation
      Error.addInternalError("function zcIndex failed for: " + ExpressionDump.printExpStr(relation), sourceInfo());
    then fail();
  end match;
end zcIndex;

protected function zcIndexRelation
  input output DAE.Exp relation;
  input output DoubleEndedList<BackendDAE.ZeroCrossing> zeroCrossings;
  input output Integer index;
  input BackendDAE.ZeroCrossing zc;
protected
  list<BackendDAE.ZeroCrossing> duplicate;
algorithm
  duplicate := List.select1(DoubleEndedList.toListNoCopyNoClear(zeroCrossings), ZeroCrossings.equals, zc);
  (relation, index) := match (relation, duplicate)
    local
      DAE.Exp rel;
      DAE.Operator op;
      BackendDAE.ZeroCrossing newZeroCrossing;
      list<BackendDAE.ZeroCrossing> zcLst;

    case (DAE.RELATION(), {})
      algorithm
        DoubleEndedList.push_back(zeroCrossings, zc);
      then (relation, index+1);

    // math function with one argument and index
    case (DAE.CALL(expLst={_, _}), {})
      algorithm
        DoubleEndedList.push_back(zeroCrossings, zc);
      then (relation, index+1);

    // math function with two arguments and index
    case (DAE.CALL(expLst={_, _, _}), {})
      algorithm
        DoubleEndedList.push_back(zeroCrossings, zc);
      then (relation, index+2);

    case (_, BackendDAE.ZERO_CROSSING(relation_=rel)::_)
      then (rel, index);

    else equation
      Error.addInternalError("function zcIndex failed for: " + ExpressionDump.printExpStr(relation), sourceInfo());
    then fail();
  end match;
end zcIndexRelation;

protected function mergeZeroCrossings "
  Takes a list of zero crossings and if more than one have identical
  function expressions they are merged into one zerocrossing.
  In the resulting list all zerocrossing have uniq function expressions."
  input BackendDAE.ZeroCrossing newZc;
  input BackendDAE.ZeroCrossingSet zcs;
protected
  Integer matches;
  list<BackendDAE.ZeroCrossing> samezc, diff;
  BackendDAE.ZeroCrossing zc1, same_1;
algorithm
  if not ZeroCrossings.contains(zcs, newZc) then
    ZeroCrossings.add(zcs, newZc);
  else
    DoubleEndedList.mapNoCopy_1(zcs.zc, mergeZeroCrossingIfEqual, newZc);
  end if;
end mergeZeroCrossings;

protected function mergeZeroCrossingIfEqual
  input BackendDAE.ZeroCrossing zc1;
  input BackendDAE.ZeroCrossing zc2;
  output BackendDAE.ZeroCrossing zc;
algorithm
  zc := if ZeroCrossings.equals(zc1, zc2) then mergeZeroCrossing(zc1,zc2) else zc1;
end mergeZeroCrossingIfEqual;

protected function mergeZeroCrossing "
  Merges two zero crossings into one by makeing the union of the lists of
  equations and when clauses they appear in."
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output BackendDAE.ZeroCrossing outZeroCrossing;
protected
  list<Integer> eq, eq1, eq2;
  DAE.Exp e1, e2, res;
algorithm
  BackendDAE.ZERO_CROSSING(relation_=e1, occurEquLst=eq1) := inZeroCrossing1;
  BackendDAE.ZERO_CROSSING(relation_=e2, occurEquLst=eq2) := inZeroCrossing2;
  res := getMinZeroCrossings(e1, e2);
  eq := List.union(eq1, eq2);
  outZeroCrossing := BackendDAE.ZERO_CROSSING(res, eq);
end mergeZeroCrossing;

protected function getMinZeroCrossings "
  Return the expression with lower index in relation of zero-crossings."
  input DAE.Exp inZCexp1;
  input DAE.Exp inZCexp2;
  output DAE.Exp outMinZC;
algorithm
  outMinZC := match (inZCexp1, inZCexp2)
    local
      DAE.Exp e1, e2, e3, e4, res, res2;
      DAE.Operator op;
      Integer index1, index2;

    case (DAE.RELATION(index=index1), DAE.RELATION(index=index2)) equation
      res = if index1<index2 then inZCexp1 else inZCexp2;
    then res;

    case (DAE.LUNARY(operator=op, exp=e1), DAE.LUNARY(exp=e2)) equation
      res = getMinZeroCrossings(e1, e2);
    then DAE.LUNARY(op, res);

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), DAE.LBINARY(exp1=e3, exp2=e4)) equation
      res = getMinZeroCrossings(e1, e2);
      res2 = getMinZeroCrossings(e3, e4);
    then DAE.LBINARY(res, op, res2);

    case (DAE.CALL(path=Absyn.IDENT("sample"), expLst={_, _, _}), _)
    then inZCexp1;

    case (_, DAE.CALL(path=Absyn.IDENT("sample"), expLst={_, _, _}))
    then inZCexp2;

    else equation
      Error.addInternalError("function getMinZeroCrossings failed for {" + ExpressionDump.printExpStr(inZCexp1) + "} and {" + ExpressionDump.printExpStr(inZCexp2) + "}", sourceInfo());
    then fail();
  end match;
end getMinZeroCrossings;

protected function traverseStmtsExps "Handles the traversing of list<DAE.Statement>.
  Works with the help of Expression.traverseExpTopDown to find
  ZeroCrossings in algorithm statements
  modified: 2011-01 by wbraun"
  input list<DAE.Statement> inStmts;
  input ForArgType inExtraArg;
  input BackendDAE.Variables inKnvars "this is needed to extend ranges" ;
  output list<DAE.Statement> slist;
  output ForArgType outTplStmtTypeA;
algorithm
  (slist, outTplStmtTypeA) := match(inStmts)
    local
      DAE.Exp e_1, e_2, e, e2, iteratorExp;
      Integer ix;
      list<DAE.Exp> expl1, expl2, iteratorexps;
      DAE.ComponentRef cr_1, cr;
      list<DAE.Statement> xs_1, xs, stmts, stmts2;
      DAE.Type tp;
      DAE.Statement x, ew, ew_1;
      Boolean b1;
      String id1;
      DAE.ElementSource source;
      DAE.Else algElse;
      ForArgType extraArg;
      list<tuple<DAE.ComponentRef, SourceInfo>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case {}
    then ({}, inExtraArg);

    case DAE.STMT_ASSIGN(type_=tp, exp1=e2, exp=e, source=source)::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (e_2, extraArg) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, extraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_ASSIGN(tp, e_2, e_1, source)::xs_1, extraArg);

    case DAE.STMT_TUPLE_ASSIGN(type_=tp, expExpLst=expl1, exp=e, source=source)::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (expl2, extraArg) = Expression.traverseExpListTopDown(expl1, collectZCAlgsFor, extraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_TUPLE_ASSIGN(tp, expl2, e_1, source)::xs_1, extraArg);

    case DAE.STMT_ASSIGN_ARR(type_=tp, lhs=e2, exp=e, source=source)::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (e_2, _, extraArg) = collectZCAlgsFor(e2, extraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_ASSIGN_ARR(tp, e_2, e_1, source)::xs_1, extraArg);

    case (x as DAE.STMT_ASSIGN_ARR(type_=tp, lhs=e2, exp=e, source=source))::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      failure((e_2, _, _) = collectZCAlgsFor(e2, extraArg));
      true = Flags.isSet(Flags.FAILTRACE);
      print(DAEDump.ppStatementStr(x));
      print("Warning, not allowed to set the componentRef to a expression in FindZeroCrossings.traverseStmtsExps for ZeroCrosssing\n");
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_ASSIGN_ARR(tp, e_2, e_1, source)::xs_1, extraArg);

    case (DAE.STMT_IF(exp=e, statementLst=stmts, else_=algElse, source=source))::xs equation
      (algElse, extraArg) = traverseStmtsElseExps(algElse, inExtraArg, inKnvars);
      (stmts2, extraArg) = traverseStmtsExps(stmts, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_IF(e_1, stmts2, algElse, source)::xs_1, extraArg);

    case (DAE.STMT_FOR(type_=tp, iterIsArray=b1, iter=id1, index=ix, range=e, statementLst=stmts, source=source))::xs equation
      cr = ComponentReference.makeCrefIdent(id1, tp, {});
      iteratorExp = Expression.crefExp(cr);
      iteratorexps = BackendDAEUtil.extendRange(e, inKnvars);
      (stmts2, extraArg) = traverseStmtsForExps(iteratorExp, iteratorexps, e, stmts, inKnvars, inExtraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_FOR(tp, b1, id1, ix, e, stmts2, source)::xs_1, extraArg);

    case (DAE.STMT_PARFOR(type_=tp, iterIsArray=b1, iter=id1, index=ix, range=e, statementLst=stmts, loopPrlVars= loopPrlVars, source=source))::xs equation
      cr = ComponentReference.makeCrefIdent(id1, tp, {});
      iteratorExp = Expression.crefExp(cr);
      iteratorexps = BackendDAEUtil.extendRange(e, inKnvars);
      (stmts2, extraArg) = traverseStmtsForExps(iteratorExp, iteratorexps, e, stmts, inKnvars, inExtraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_PARFOR(tp, b1, id1, ix, e, stmts2, loopPrlVars, source)::xs_1, extraArg);

    case (DAE.STMT_WHILE(exp=e, statementLst=stmts, source=source))::xs equation
      (stmts2, extraArg) = traverseStmtsExps(stmts, inExtraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_WHILE(e_1, stmts2, source)::xs_1, extraArg);

    case (DAE.STMT_WHEN(exp=e, conditions=conditions, initialCall=initialCall, statementLst=stmts, elseWhen=NONE(), source=source))::xs equation
      // wbraun: statemenents inside when equations can't contain zero-crossings
      // (stmts2, extraArg) = traverseStmtsExps(stmts, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_WHEN(e_1, conditions, initialCall, stmts, NONE(), source)::xs_1, extraArg);

    case (DAE.STMT_WHEN(exp=e, conditions=conditions, initialCall=initialCall, statementLst=stmts, elseWhen=SOME(ew), source=source))::xs equation
      ({ew_1}, extraArg) = traverseStmtsExps({ew}, inExtraArg, inKnvars);
      // wbraun: statemenents inside when equations can't contain zero-crossings
      // (stmts2, extraArg) = traverseStmtsExps(stmts, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_WHEN(e_1, conditions, initialCall, stmts, SOME(ew_1), source)::xs_1, extraArg);

    case (x as DAE.STMT_ASSERT())::xs equation
      (xs_1, extraArg) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then (x::xs_1, extraArg);

    case (x as DAE.STMT_TERMINATE())::xs equation
      (xs_1, extraArg) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then (x::xs_1, extraArg);

    case (x as DAE.STMT_REINIT())::xs equation
      (xs_1, extraArg) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then (x::xs_1, extraArg);

    case (DAE.STMT_NORETCALL(exp=e, source=source))::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_NORETCALL(e_1, source)::xs_1, extraArg);

    case (x as DAE.STMT_RETURN())::xs equation
      (xs_1, extraArg) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then (x::xs_1, extraArg);

    case (x as DAE.STMT_BREAK())::xs equation
      (xs_1, extraArg) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then (x::xs_1, extraArg);

    // MetaModelica extension. KS
    case DAE.STMT_FAILURE(body=stmts, source=source)::xs equation
      (stmts2, extraArg) = traverseStmtsExps(stmts, inExtraArg, inKnvars);
      (xs_1, extraArg) = traverseStmtsExps(xs, extraArg, inKnvars);
    then (DAE.STMT_FAILURE(stmts2, source)::xs_1, extraArg);

    case x::_ equation
      Error.addInternalError("function traverseStmtsExps failed: " + DAEDump.ppStatementStr(x), sourceInfo());
    then fail();
  end match;
end traverseStmtsExps;

protected function traverseStmtsElseExps "author: BZ, 2008-12
  modified: 2011-01 by wbraun
  Helper function for traverseStmtsExps to find ZeroCrosssings in algorithm
  else statements."
  input DAE.Else inElse;
  input ForArgType inExtraArg;
  input BackendDAE.Variables inKnvars;
  output DAE.Else outElse;
  output ForArgType outTplStmtTypeA;
algorithm
  (outElse, outTplStmtTypeA) := match(inElse)
    local
      DAE.Exp e, e_1;
      list<DAE.Statement> st, st_1;
      DAE.Else el, el_1;
      ForArgType extraArg;

    case DAE.NOELSE()
    then (DAE.NOELSE(), inExtraArg);

    case DAE.ELSEIF(e, st, el) equation
      (el_1, extraArg) = traverseStmtsElseExps(el, inExtraArg, inKnvars);
      (st_1, extraArg) = traverseStmtsExps(st, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
    then (DAE.ELSEIF(e_1, st_1, el_1), extraArg);

    case DAE.ELSE(st) equation
      (st_1, extraArg) = traverseStmtsExps(st, inExtraArg, inKnvars);
    then (DAE.ELSE(st_1), extraArg);
  end match;
end traverseStmtsElseExps;

protected function traverseStmtsForExps "modified: 2011-01 by wbraun
  Helper function for traverseStmtsExps to processed for loops to search
  zero crosssings."
  input DAE.Exp inIteratorExp;
  input list<DAE.Exp> inExplst;
  input DAE.Exp inRange;
  input list<DAE.Statement> inStmts;
  input BackendDAE.Variables inKnvars;
  input ForArgType inExtraArg;
  output list<DAE.Statement> outStatements;
  output ForArgType outTpl;
algorithm
  (outStatements, outTpl) := match (inExplst, inExtraArg)
    local
      list<DAE.Statement> statementLst;
      tuple<BackendDAE.ZeroCrossingSet, DoubleEndedList<BackendDAE.ZeroCrossing>, BackendDAE.ZeroCrossingSet, Integer> tpl2;
      tuple<Integer, BackendDAE.Variables, BackendDAE.Variables> tpl3;
      ForArgType extraArg;

    case ({}, _)
    then (inStmts, inExtraArg);

    case (_, (_, _, _, tpl2, tpl3)) equation
      (statementLst, extraArg) = traverseStmtsExps(inStmts, (inIteratorExp, inExplst, inRange, tpl2, tpl3), inKnvars);
    then (statementLst, extraArg);

    else equation
      Error.addInternalError("function traverseStmtsForExps failed", sourceInfo());
    then fail();
  end match;
end traverseStmtsForExps;

protected function createZeroCrossings "
  Constructs a list of zero crossings from a list of relations. Each zero
  crossing gets the same equation indices and when clause indices."
  input list<DAE.Exp> inExpExpLst1;
  input list<Integer> inOccurEquLst;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst := List.map1(inExpExpLst1, createZeroCrossing, inOccurEquLst);
end createZeroCrossings;

protected function createZeroCrossing
  input DAE.Exp inRelation;
  input list<Integer> inOccurEquLst;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := match(inOccurEquLst)
    case ({-1})
    then BackendDAE.ZERO_CROSSING(inRelation, {});

    else BackendDAE.ZERO_CROSSING(inRelation, inOccurEquLst);
  end match;
end createZeroCrossing;

annotation(__OpenModelica_Interface="backend");
end FindZeroCrossings;

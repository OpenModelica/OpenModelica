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

  RCS: $Id$
"

public import Absyn;
public import BackendDAE;
public import DAE;
public import FCore;

protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import CheckModel;
protected import ComponentReference;
protected import DAEDump;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
protected import HashTableExpToIndex;
protected import List;
protected import Util;

// =============================================================================
// section for some public util functions
//
// =============================================================================

public function getZeroCrossings
  input BackendDAE.BackendDAE inBackendDAE;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingList;
algorithm
  BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(zeroCrossingLst=outZeroCrossingList))) := inBackendDAE;
end getZeroCrossings;

public function getRelations
  input BackendDAE.BackendDAE inBackendDAE;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingList;
algorithm
  BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(relationsLst=outZeroCrossingList))) := inBackendDAE;
end getRelations;

public function getSamples "deprecated - use EVENT_INFO.timeEvents instead"
  input BackendDAE.BackendDAE inBackendDAE;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingList;
algorithm
  BackendDAE.DAE(shared=BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(sampleLst=outZeroCrossingList))) := inBackendDAE;
end getSamples;


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
  BackendDAE.Shared shared;
  BackendDAE.Variables knownVars;
  BackendDAE.Variables externalObjects;
  BackendDAE.Variables aliasVars;
  BackendDAE.EquationArray initialEqs;
  BackendDAE.EquationArray removedEqs;
  list<DAE.Constraint> constraints;
  list<DAE.ClassAttributes> classAttrs;
  FCore.Cache cache;
  FCore.Graph graph;
  DAE.FunctionTree functionTree;
  BackendDAE.EventInfo eventInfo;
  BackendDAE.ExternalObjectClasses extObjClasses;
  BackendDAE.BackendDAEType backendDAEType;
  BackendDAE.SymbolicJacobians symjacs;

  list<BackendDAE.TimeEvent> timeEvents;
  list<BackendDAE.WhenClause> whenClauseLst;
  list<BackendDAE.ZeroCrossing> zeroCrossingLst;
  list<BackendDAE.ZeroCrossing> sampleLst;
  list<BackendDAE.ZeroCrossing> relationsLst;
  Integer numberMathEvents;

  Integer index;
  HashTableExpToIndex.HashTable ht "is used to avoid redundant condition-variables";
  list<BackendDAE.Var> vars;
  list<BackendDAE.Equation> eqns;
  BackendDAE.Variables vars_;
  BackendDAE.EquationArray eqns_;
  BackendDAE.ExtraInfo info;
  array<DAE.ClockKind> clocks;
algorithm
  BackendDAE.DAE(systs, shared) := inDAE;
  BackendDAE.SHARED(knownVars=knownVars,
                    externalObjects=externalObjects,
                    aliasVars=aliasVars,
                    initialEqs=initialEqs,
                    removedEqs=removedEqs,
                    constraints=constraints,
                    classAttrs=classAttrs,
                    cache=cache,
                    graph=graph,
                    functionTree=functionTree,
                    eventInfo=eventInfo,
                    extObjClasses=extObjClasses,
                    backendDAEType=backendDAEType,
                    symjacs=symjacs,
                    info=info) := shared;
  BackendDAE.EVENT_INFO(timeEvents=timeEvents,
                        whenClauseLst=whenClauseLst,
                        zeroCrossingLst=zeroCrossingLst,
                        sampleLst=sampleLst,
                        relationsLst=relationsLst,
                        numberMathEvents=numberMathEvents,
                        clocks=clocks) := eventInfo;

  ht := HashTableExpToIndex.emptyHashTable();

  // equation system
  (systs, index, ht) := List.mapFold2(systs, encapsulateWhenConditions_EqSystem, 1, ht);

  // when clauses
  (whenClauseLst, vars, eqns, ht, index) := encapsulateWhenConditions_WhenClause(whenClauseLst, {}, {}, {}, ht, index);

  // removed equations
  ((removedEqs, vars, eqns, index, ht)) := BackendEquation.traverseEquationArray(removedEqs, encapsulateWhenConditions_Equation, (BackendEquation.emptyEqns(), vars, eqns, index, ht));
  vars_ := BackendVariable.listVar(vars);
  eqns_ := BackendEquation.listEquation(eqns);
  systs := listAppend(systs, {BackendDAEUtil.createEqSystem(vars_, eqns_)});

  eventInfo := BackendDAE.EVENT_INFO(timeEvents,
                                     whenClauseLst,
                                     zeroCrossingLst,
                                     sampleLst,
                                     relationsLst,
                                     numberMathEvents,
                                     clocks);
  shared := BackendDAE.SHARED(knownVars,
                              externalObjects,
                              aliasVars,
                              initialEqs,
                              removedEqs,
                              constraints,
                              classAttrs,
                              cache,
                              graph,
                              functionTree,
                              eventInfo,
                              extObjClasses,
                              backendDAEType,
                              symjacs,
                              info);
  outDAE := if intGt(index, 1) then BackendDAE.DAE(systs, shared) else inDAE;
  if Flags.isSet(Flags.DUMP_ENCAPSULATECONDITIONS) then
    BackendDump.dumpBackendDAE(outDAE, "DAE after PreOptModule >>encapsulateWhenConditions<<");
  end if;
end encapsulateWhenConditions;

protected function encapsulateWhenConditions_WhenClause "author: lochel"
  input list<BackendDAE.WhenClause> inWhenClause;
  input list<BackendDAE.WhenClause> inWhenClause_done;
  input list<BackendDAE.Var> inVars;
  input list<BackendDAE.Equation> inEqns;
  input HashTableExpToIndex.HashTable inHT;
  input Integer inIndex;
  output list<BackendDAE.WhenClause> outWhenClause;
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outEqns;
  output HashTableExpToIndex.HashTable outHT;
  output Integer outIndex;
algorithm
  (outWhenClause, outVars, outEqns, outHT, outIndex) := match(inWhenClause)
    local
      HashTableExpToIndex.HashTable ht;
      Integer index;
      DAE.Exp condition;
      list<BackendDAE.WhenOperator> reinitStmtLst;
      Option<Integer> elseClause;

      list<BackendDAE.Var> vars;
      list<BackendDAE.Equation> eqns;
      list<BackendDAE.WhenClause> rest, whenClause_done;

    case {}
    then (inWhenClause_done, inVars, inEqns, inHT, inIndex);

    case BackendDAE.WHEN_CLAUSE(condition, reinitStmtLst, elseClause)::rest equation
      (condition, vars, eqns, index, ht) = encapsulateWhenConditions_Equations1(condition, DAE.emptyElementSource, inIndex, inHT);
      vars = listAppend(vars, inVars);
      eqns = listAppend(eqns, inEqns);
      whenClause_done = listAppend({BackendDAE.WHEN_CLAUSE(condition, reinitStmtLst, elseClause)}, inWhenClause_done);

      (whenClause_done, vars, eqns, ht, index) = encapsulateWhenConditions_WhenClause(rest, whenClause_done, vars, eqns, ht, index);
    then (whenClause_done, vars, eqns, ht, index);
  end match;
end encapsulateWhenConditions_WhenClause;

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
      BackendDAE.EquationArray orderedEqs;
      BackendDAE.EqSystem syst;
      list<BackendDAE.Var> varLst;
      list<BackendDAE.Equation> eqnLst;
    case syst as BackendDAE.EQSYSTEM(orderedVars=orderedVars, orderedEqs=orderedEqs)
      algorithm
        ((orderedEqs, varLst, eqnLst, outIndex, outHT)) :=
            BackendEquation.traverseEquationArray( orderedEqs, encapsulateWhenConditions_Equation,
                                                   (BackendEquation.emptyEqns(), {}, {}, inIndex, inHT) );
        syst.orderedVars := BackendVariable.addVars(varLst, orderedVars);
        syst.orderedEqs := BackendEquation.addEquations(eqnLst, orderedEqs);
      then BackendDAEUtil.clearEqSyst(syst);
  end match;
end encapsulateWhenConditions_EqSystem;

protected function encapsulateWhenConditions_Equation "author: lochel"
  input BackendDAE.Equation inEq;
  input tuple<BackendDAE.EquationArray, list<BackendDAE.Var>, list<BackendDAE.Equation>, Integer, HashTableExpToIndex.HashTable> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<BackendDAE.EquationArray, list<BackendDAE.Var>, list<BackendDAE.Equation>, Integer, HashTableExpToIndex.HashTable> outTpl;
algorithm
  (outEq,outTpl) := match (inEq,inTpl)
    local
      BackendDAE.Equation eqn, eqn2;
      list<BackendDAE.Var> vars, vars1;
      list<BackendDAE.Equation> eqns, eqns1;
      BackendDAE.WhenEquation whenEquation;
      DAE.ElementSource source;
      Integer index, size, sizePre;
      BackendDAE.EquationArray equationArray;
      DAE.Algorithm alg_;
      list<DAE.Statement> stmts, preStmts;
      HashTableExpToIndex.HashTable ht;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes attr;

    // when equation
    case (BackendDAE.WHEN_EQUATION(size=size, whenEquation=whenEquation, source=source, attr=attr), (equationArray, vars, eqns, index, ht)) equation
      (whenEquation, vars1, eqns1, index, ht) = encapsulateWhenConditions_Equations(whenEquation, source, index, ht);
      vars = listAppend(vars, vars1);
      eqns = listAppend(eqns, eqns1);
      eqn = BackendDAE.WHEN_EQUATION(size, whenEquation, source, attr);
      equationArray = BackendEquation.addEquation(eqn, equationArray);
    then (eqn, (equationArray, vars, eqns, index, ht));

    // removed algorithm
    case (BackendDAE.ALGORITHM(size=0, alg=alg_, source=source, expand=crefExpand, attr=attr), (equationArray, vars, eqns, index, ht)) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg_;
      size = -index;
      (stmts, preStmts, vars1, index) = encapsulateWhenConditions_Algorithms(stmts, vars, index);
      sizePre = listLength(preStmts);
      size = size+index-sizePre;

      alg_ = DAE.ALGORITHM_STMTS(stmts);
      eqn = BackendDAE.ALGORITHM(size, alg_, source, crefExpand, attr);
      equationArray = BackendEquation.addEquation(eqn, equationArray);

      if sizePre > 0 then
        alg_ = DAE.ALGORITHM_STMTS(preStmts);
        eqn2 = BackendDAE.ALGORITHM(sizePre, alg_, source, crefExpand, attr);
        eqns = eqn2::eqns;
      end if;
    then (eqn, (equationArray, vars1, eqns, index, ht));

    // algorithm
    case (BackendDAE.ALGORITHM(size=size, alg=alg_, source=source, expand=crefExpand, attr=attr), (equationArray, vars, eqns, index, ht)) equation
      DAE.ALGORITHM_STMTS(statementLst=stmts) = alg_;
      size = size-index;
      (stmts, preStmts, vars1, index) = encapsulateWhenConditions_Algorithms(stmts, vars, index);
      size = size+index;

      stmts = listAppend(preStmts, stmts);

      alg_ = DAE.ALGORITHM_STMTS(stmts);
      eqn = BackendDAE.ALGORITHM(size, alg_, source, crefExpand, attr);
      equationArray = BackendEquation.addEquation(eqn, equationArray);
    then (eqn, (equationArray, vars1, eqns, index, ht));

    case (_, (equationArray, vars, eqns, index, ht)) equation
      equationArray = BackendEquation.addEquation(inEq, equationArray);
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
  (outWhenEquation, outVars, outEqns, outIndex, outHT) := matchcontinue(inWhenEquation)
    local
      Integer index;
      BackendDAE.WhenEquation elsewhenPart, whenEquation;
      list<BackendDAE.Var> vars, vars1;
      list<BackendDAE.Equation> eqns, eqns1;

      DAE.Exp condition;
      DAE.ComponentRef left;
      DAE.Exp right;

      HashTableExpToIndex.HashTable ht;

    // when
    case BackendDAE.WHEN_EQ(condition=condition, left=left, right=right, elsewhenPart=NONE()) equation
      (condition, vars, eqns, index, ht) = encapsulateWhenConditions_Equations1(condition, inSource, inIndex, inHT);
      whenEquation = BackendDAE.WHEN_EQ(condition, left, right, NONE());
    then (whenEquation, vars, eqns, index, ht);

    // when - elsewhen
    case BackendDAE.WHEN_EQ(condition=condition, left=left, right=right, elsewhenPart=SOME(elsewhenPart)) equation
      (elsewhenPart, vars1, eqns1, index, ht) = encapsulateWhenConditions_Equations(elsewhenPart, inSource, inIndex, inHT);
      (condition, vars, eqns, index, ht) = encapsulateWhenConditions_Equations1(condition, inSource, index, ht);
      whenEquation = BackendDAE.WHEN_EQ(condition, left, right, SOME(elsewhenPart));
      vars = listAppend(vars, vars1);
      eqns = listAppend(eqns, eqns1);
    then (whenEquation, vars, eqns, index, ht);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_Equations failed"});
    then fail();
  end matchcontinue;
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
  (outCondition, outVars, outEqns, outIndex, outHT) := matchcontinue(inCondition)
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

    // array-condition
    case DAE.ARRAY(ty=ty, scalar=scalar, array=array) equation
      (array, vars, eqns, index, ht) = encapsulateWhenConditions_EquationsWithArrayConditions(array, inSource, inIndex, inHT);
    then (DAE.ARRAY(ty, scalar, array), vars, eqns, index, ht);

    // simple condition [already in ht]
    case _ equation
      localIndex = BaseHashTable.get(inCondition, inHT);
      crStr = "$whenCondition" + intString(localIndex);
      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
    then (condition, {}, {}, inIndex, inHT);

    // simple condition [not yet in ht]
    case _ equation
      ht = BaseHashTable.add((inCondition, inIndex), inHT);
      crStr = "$whenCondition" + intString(inIndex);

      var = BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
      var = BackendVariable.setVarFixed(var, true);
      eqn = BackendDAE.EQUATION(DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT), inCondition, inSource, BackendDAE.EQ_ATTR_DEFAULT_DYNAMIC);

      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
    then (condition, {var}, {eqn}, inIndex+1, ht);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_Equations1 failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditions_Equations1;

protected function encapsulateWhenConditions_EquationsWithArrayConditions "author: lochel"
  input list<DAE.Exp> inConditionList;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  input HashTableExpToIndex.HashTable inHT;
  output list<DAE.Exp> outConditionList;
  output list<BackendDAE.Var> outVars;
  output list<BackendDAE.Equation> outEqns;
  output Integer outIndex;
  output HashTableExpToIndex.HashTable outHT;
algorithm
  (outConditionList, outVars, outEqns, outIndex, outHT) := matchcontinue(inConditionList)
    local
      Integer index;
      list<BackendDAE.Var> vars1, vars2;
      list<BackendDAE.Equation> eqns1, eqns2;

      DAE.Exp condition;
      list<DAE.Exp> conditionList;

      HashTableExpToIndex.HashTable ht;

    case {} equation
    then ({}, {}, {}, inIndex, inHT);

    case condition::conditionList equation
      (condition, vars1, eqns1, index, ht) = encapsulateWhenConditions_Equations1(condition, inSource, inIndex, inHT);
      (conditionList, vars2, eqns2, index, ht) = encapsulateWhenConditions_EquationsWithArrayConditions(conditionList, inSource, index, ht);
      vars1 = listAppend(vars1, vars2);
      eqns1 = listAppend(eqns1, eqns2);
    then (condition::conditionList, vars1, eqns1, index, ht);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_EquationsWithArrayConditions failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditions_EquationsWithArrayConditions;

protected function encapsulateWhenConditions_Algorithms "author: lochel"
  input list<DAE.Statement> inStmts;
  input list<BackendDAE.Var> inVars;
  input Integer inIndex;
  output list<DAE.Statement> outStmts;
  output list<DAE.Statement> outPreStmts; // these are additional statements that should be inserted directly before a STMT_WHEN
  output list<BackendDAE.Var> outVars;
  output Integer outIndex;
algorithm
  (outStmts, outPreStmts, outVars, outIndex) := matchcontinue(inStmts)
    local
      DAE.Exp condition;
      DAE.Statement stmt, elseWhen;
      list<DAE.Statement> stmts, rest, stmts1, stmts_, preStmts, preStmts2, elseWhenList;
      Integer index;
      DAE.ElementSource source;
      list<BackendDAE.Var> vars;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case {}
    then ({}, {}, inVars, inIndex);

    // when statement (without outputs)
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=NONE(), source=source)::rest equation
      (condition, vars, preStmts, index) = encapsulateWhenConditions_Algorithms1(condition, source, inIndex);
      (conditions, initialCall) = BackendDAEUtil.getConditionList(condition);
      vars = listAppend(vars, inVars);

      {} = CheckModel.algorithmStatementListOutputs({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, NONE(), source)}, DAE.EXPAND());

      (stmts, preStmts2, vars, index) = encapsulateWhenConditions_Algorithms(rest, vars, index);
      preStmts = listAppend(preStmts, preStmts2);
      stmts_ = listAppend({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, NONE(), source)}, stmts);
    then (stmts_, preStmts, vars, index);

    // when statement
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=NONE(), source=source)::rest equation
      (condition, vars, preStmts, index) = encapsulateWhenConditions_Algorithms1(condition, source, inIndex);
      (conditions, initialCall) = BackendDAEUtil.getConditionList(condition);
      vars = listAppend(vars, inVars);

      (stmts, stmts_, vars, index) = encapsulateWhenConditions_Algorithms(rest, vars, index);
      stmts_ = listAppend({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, NONE(), source)}, stmts_);
      stmts_ = listAppend(stmts_, stmts);
    then (stmts_, preStmts, vars, index);

    // when - elsewhen statement (without outputs)
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=SOME(elseWhen), source=source)::rest equation
      (condition, vars, preStmts, index) = encapsulateWhenConditions_Algorithms1(condition, source, inIndex);
      (conditions, initialCall) = BackendDAEUtil.getConditionList(condition);
      vars = listAppend(vars, inVars);

      (elseWhenList, _, vars, index) = encapsulateWhenConditions_Algorithms({elseWhen}, vars, index);
      elseWhen = List.last(elseWhenList);
      preStmts2 = List.stripLast(elseWhenList);
      preStmts = listAppend(preStmts, preStmts2);

      {} = CheckModel.algorithmStatementListOutputs({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, SOME(elseWhen), source)}, DAE.EXPAND());

      (stmts, preStmts2, vars, index) = encapsulateWhenConditions_Algorithms(rest, vars, index);
      preStmts = listAppend(preStmts, preStmts2);
      stmts_ = listAppend({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, SOME(elseWhen), source)}, stmts);
    then (stmts_, preStmts, vars, index);

    // when - elsewhen statement
    case DAE.STMT_WHEN(exp=condition, statementLst=stmts1, elseWhen=SOME(elseWhen), source=source)::rest equation
      (condition, vars, preStmts, index) = encapsulateWhenConditions_Algorithms1(condition, source, inIndex);
      (conditions, initialCall) = BackendDAEUtil.getConditionList(condition);
      vars = listAppend(vars, inVars);

      ({elseWhen}, preStmts2, vars, index) = encapsulateWhenConditions_Algorithms({elseWhen}, vars, index);
      preStmts = listAppend(preStmts, preStmts2);

      (stmts, stmts_, vars, index) = encapsulateWhenConditions_Algorithms(rest, vars, index);
      stmts_ = listAppend({DAE.STMT_WHEN(condition, conditions, initialCall, stmts1, SOME(elseWhen), source)}, stmts_);
      stmts_ = listAppend(stmts_, stmts);
    then (stmts_, preStmts, vars, index);

    // no when statement
    case stmt::rest equation
      (stmts, preStmts, vars, index) = encapsulateWhenConditions_Algorithms(rest, inVars, inIndex);
      stmts = listAppend(preStmts, stmts);
    then (stmt::stmts, {}, vars, index);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_Algorithms failed"});
    then fail();
  end matchcontinue;
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
  (outCondition, outVars, outStmts, outIndex) := matchcontinue(inCondition)
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

    // array-condition
    case (DAE.ARRAY(array={condition})) equation
      crStr = "$whenCondition" + intString(inIndex);

      var = BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
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

      var = BackendDAE.VAR(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), BackendDAE.DISCRETE(), DAE.BIDIR(), DAE.NON_PARALLEL(), DAE.T_BOOL_DEFAULT, NONE(), NONE(), {}, inSource, NONE(), NONE(), NONE(), DAE.NON_CONNECTOR(), DAE.NOT_INNER_OUTER(), true);
      var = BackendVariable.setVarFixed(var, true);
      stmt = DAE.STMT_ASSIGN(DAE.T_BOOL_DEFAULT, DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT), inCondition, inSource);

      condition = DAE.CREF(DAE.CREF_IDENT(crStr, DAE.T_BOOL_DEFAULT, {}), DAE.T_BOOL_DEFAULT);
    then (condition, {var}, {stmt}, inIndex+1);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_Algorithms1 failed"});
    then fail();
  end matchcontinue;
end encapsulateWhenConditions_Algorithms1;

protected function encapsulateWhenConditions_AlgorithmsWithArrayConditions "author: lochel"
  input list<DAE.Exp> inConditionList;
  input DAE.ElementSource inSource;
  input Integer inIndex;
  output list<DAE.Exp> outConditionList;
  output list<BackendDAE.Var> outVars;
  output list<DAE.Statement> outStmts;
  output Integer outIndex;
algorithm
  (outConditionList, outVars, outStmts, outIndex) := matchcontinue(inConditionList)
    local
      Integer index;
      list<BackendDAE.Var> vars1, vars2;
      list<DAE.Statement> stmt1, stmt2;

      DAE.Exp condition;
      list<DAE.Exp> conditionList;

    case {} equation
    then ({}, {}, {}, inIndex);

    case condition::conditionList equation
      (condition, vars1, stmt1, index) = encapsulateWhenConditions_Algorithms1(condition, inSource, inIndex);
      (conditionList, vars2, stmt2, index) = encapsulateWhenConditions_AlgorithmsWithArrayConditions(conditionList, inSource, index);
      vars1 = listAppend(vars1, vars2);
      stmt1 = listAppend(stmt1, stmt2);
    then (condition::conditionList, vars1, stmt1, index);

    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/FindZeroCrossings.mo: function encapsulateWhenConditions_AlgorithmsWithArrayConditions failed"});
    then fail();
  end matchcontinue;
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
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, partitionKind=partitionKind) := inSyst;
  (outSyst, outShared) := match partitionKind
    local
      BackendDAE.Variables knvars;
      BackendDAE.EquationArray eqns1;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> whenclauses;
      list<BackendDAE.Equation> eqs_lst, eqs_lst1;
      list<BackendDAE.TimeEvent> timeEvents;
      list<BackendDAE.ZeroCrossing> zero_crossings;
      list<BackendDAE.ZeroCrossing> relations, sampleLst;
      Integer countMathFunctions;
      array<DAE.ClockKind> clocks;
    //No zero crossing for clocked discrete partitions;
    case BackendDAE.CLOCKED_PARTITION(subClock=BackendDAE.SUBCLOCK(solver=NONE()))
      then (inSyst, inShared);
    else
      algorithm
        BackendDAE.SHARED( knownVars=knvars, eventInfo=einfo) := inShared;
        BackendDAE.EVENT_INFO( timeEvents=timeEvents, zeroCrossingLst=zero_crossings, clocks=clocks,
                               sampleLst=sampleLst, whenClauseLst=whenclauses, relationsLst=relations,
                               numberMathEvents=countMathFunctions ) := einfo;
        eqs_lst := BackendEquation.equationList(eqns);
        (zero_crossings, eqs_lst1, _, _, countMathFunctions, relations, sampleLst) :=
        findZeroCrossings2( vars, knvars, eqs_lst, 0, {}, 0, listLength(relations),
                            countMathFunctions, zero_crossings, relations, sampleLst, {}, {} );
        eqs_lst1 := listReverse(eqs_lst1);
        if Flags.isSet(Flags.RELIDX) then
          print("findZeroCrossings1 number of relations: " + intString(listLength(relations)) + "\n");
          print("findZeroCrossings1 sample index: " + intString(listLength(sampleLst)) + "\n");
        end if;
        eqns1 := BackendEquation.listEquation(eqs_lst1);
        einfo := BackendDAE.EVENT_INFO( timeEvents, whenclauses, zero_crossings, sampleLst, relations,
                                           countMathFunctions, clocks );
      then (BackendDAEUtil.setEqSystEqs(inSyst, eqns1), BackendDAEUtil.setSharedEventInfo(inShared, einfo));
  end match;
end findZeroCrossings1;

protected function findZeroCrossings2
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> inEquationLst2;
  input Integer inEqnCount;
  input list<BackendDAE.WhenClause> inWhenClauseLst4;
  input Integer inWhenClauseCount;

  input Integer inNumberOfRelations;
  input Integer inNumberOfMathFunctions;
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst;
  input list<BackendDAE.ZeroCrossing> inRelationsLst;
  input list<BackendDAE.ZeroCrossing> inSamplesLst;
  input list<BackendDAE.Equation> inEquationLstAccum;
  input list<BackendDAE.WhenClause> inWhenClauseAccum;

  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output Integer outNumberOfRelations;
  output Integer outNumberOfMathFunctions;
  output list<BackendDAE.ZeroCrossing> outRelationsLst;
  output list<BackendDAE.ZeroCrossing> outSamplesLst;
algorithm
  (outZeroCrossingLst, outEquationLst, outWhenClauseLst, outNumberOfRelations, outNumberOfMathFunctions, outRelationsLst, outSamplesLst) := match (inEquationLst2, inWhenClauseLst4)
    local
      list<BackendDAE.ZeroCrossing> zcs, zcs1, res, res1, relationsLst, sampleLst;
      Integer size, countRelations, eq_count_1, eq_count, wc_count, countMathFunctions;
      BackendDAE.Equation e;
      list<BackendDAE.Equation> xs, el, eq_reslst, eqnsAccum;
      DAE.Exp daeExp, e1, e2, eres1, eres2;
      BackendDAE.WhenClause wc;
      list<BackendDAE.WhenClause> xsWhen, wc_reslst;
      DAE.ElementSource source, source_;
      list<DAE.Statement> stmts, stmts_1;
      DAE.ComponentRef cref;
      list<BackendDAE.WhenOperator> whenOperations;
      list<BackendDAE.WhenClause> whenClauseAccum;
      Option<Integer> elseClause_;
      list<Integer> dimsize;
      BackendDAE.WhenEquation weqn;
      Boolean diffed;
      DAE.Expand expand;
      BackendDAE.EquationAttributes eqAttr;

    case ({}, {})
    then (inZeroCrossingLst, inEquationLstAccum, inWhenClauseAccum, inNumberOfRelations, inNumberOfMathFunctions, inRelationsLst, inSamplesLst);

    // all algorithm stmts are processed firstly
    case (BackendDAE.ALGORITHM(size=size, alg=DAE.ALGORITHM_STMTS(stmts), source=source_, expand=expand, attr=eqAttr)::xs, {}) equation
      eq_count = inEqnCount + 1;
      ((stmts_1, (_, _, _, (res, relationsLst, sampleLst, countRelations, countMathFunctions), (_, _, _)))) = traverseStmtsExps(stmts, (DAE.RCONST(0.0), {}, DAE.RCONST(0.0), (inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions), (eq_count, inVariables1, knvars)), knvars);
      eqnsAccum = BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(stmts_1), source_, expand, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // then all when clauses are processed
    case (el, (BackendDAE.WHEN_CLAUSE(condition=daeExp, reinitStmtLst=whenOperations , elseClause=elseClause_ ))::xsWhen) equation
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.debugStrExpStr("processed when clause: ", daeExp, "\n");
      end if;
      wc_count = inWhenClauseCount + 1;
      (eres1, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(daeExp, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions, -1, wc_count, inVariables1, knvars);
      whenClauseAccum = BackendDAE.WHEN_CLAUSE(eres1, whenOperations, elseClause_)::inWhenClauseAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, el, inEqnCount, xsWhen, wc_count, countRelations, countMathFunctions, res, relationsLst, sampleLst, inEquationLstAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // check when equation condition
    case ((BackendDAE.WHEN_EQUATION(size=size, whenEquation=weqn, source=source_, attr=eqAttr))::xs, {}) equation
      eq_count = inEqnCount + 1;
      (weqn, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossingsWhenEqns(weqn, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions, eq_count, -1, inVariables1, knvars);
      eqnsAccum = BackendDAE.WHEN_EQUATION(size, weqn, source_, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // after all algorithms and when clauses are processed, all equations are processed
    case ((BackendDAE.EQUATION(exp=e1, scalar=e2, source=source_, attr=eqAttr))::xs, {}) equation
      eq_count = inEqnCount + 1;
      (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions, eq_count, -1, inVariables1, knvars);
      (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, inVariables1, knvars);
       eqnsAccum = BackendDAE.EQUATION(eres1, eres2, source_, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case ((BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=source, attr=eqAttr))::xs, {}) equation
      eq_count = inEqnCount + 1;
      (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions, eq_count, -1, inVariables1, knvars);
      (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, inVariables1, knvars);
       eqnsAccum = BackendDAE.COMPLEX_EQUATION(size, eres1, eres2, source, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case ((BackendDAE.ARRAY_EQUATION(dimSize=dimsize, left=e1, right=e2, source=source, attr=eqAttr))::xs, {}) equation
      eq_count = inEqnCount + 1;
      (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions, eq_count, -1, inVariables1, knvars);
      (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, inVariables1, knvars);
       eqnsAccum = BackendDAE.ARRAY_EQUATION(dimsize, eres1, eres2, source, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case ((BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=e1, source=source_, attr=eqAttr))::xs, {}) equation
      (eres1, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions, inEqnCount, -1, inVariables1, knvars);
       eqnsAccum = BackendDAE.SOLVED_EQUATION(cref, eres1, source_, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, inEqnCount, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case ((BackendDAE.RESIDUAL_EQUATION(exp=e1, source=source_, attr=eqAttr))::xs, {}) equation
      eq_count = inEqnCount + 1;
      (eres1, countRelations, countMathFunctions, relationsLst, res, sampleLst) = findZeroCrossings3(e1, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions, eq_count, -1, inVariables1, knvars);
       eqnsAccum = BackendDAE.RESIDUAL_EQUATION(eres1, source_, eqAttr)::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case ((e as BackendDAE.IF_EQUATION())::xs, {}) equation
      eq_count = inEqnCount + 1;
      (e, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossingsIfEqns(e, inZeroCrossingLst, inRelationsLst, inSamplesLst, inNumberOfRelations, inNumberOfMathFunctions, eq_count, -1, inVariables1, knvars);
      eqnsAccum = e::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // let when equation pass they are discrete and can't contain ZeroCrossings
    case (e::xs, {}) equation
      eq_count = inEqnCount + 1;
      eqnsAccum = e::inEquationLstAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(inVariables1, knvars, xs, eq_count, {}, 0, inNumberOfRelations, inNumberOfMathFunctions, inZeroCrossingLst, inRelationsLst, inSamplesLst, eqnsAccum, inWhenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);
  end match;
end findZeroCrossings2;

protected function findZeroCrossingsWhenEqns
  input BackendDAE.WhenEquation inWhenEqn;
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  input list<BackendDAE.ZeroCrossing> inrelationsinZC;
  input list<BackendDAE.ZeroCrossing> inSamplesLst;
  input Integer incountRelations;
  input Integer incountMathFunctions;
  input Integer counteq;
  input Integer countwc;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output BackendDAE.WhenEquation oWhenEqn;
  output Integer outCountRelations;
  output Integer outCountMathFunctions;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
  output list<BackendDAE.ZeroCrossing> outrelationsinZC;
  output list<BackendDAE.ZeroCrossing> outSamplesLst;
algorithm
  (oWhenEqn, outCountRelations, outCountMathFunctions, outZeroCrossings, outrelationsinZC, outSamplesLst) := match(inWhenEqn)
    local
      DAE.Exp cond, e;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we;
      list<BackendDAE.ZeroCrossing> zc, relations, samples;
      Integer countRelations, countMathFunctions;

    case BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e, elsewhenPart=NONE()) equation
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.debugStrExpStr("processed when condition: ", cond, "\n");
      end if;
      (cond, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossings3(cond, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars);
    then (BackendDAE.WHEN_EQ(cond, cr, e, NONE()), countRelations, countMathFunctions, zc, relations, samples);

    case BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e, elsewhenPart=SOME(we)) equation
      (we, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossingsWhenEqns(we, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars);
      (cond, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossings3(cond, zc, relations, samples, countRelations, countMathFunctions, counteq, countwc, vars, knvars);
    then (BackendDAE.WHEN_EQ(cond, cr, e, SOME(we)), countRelations, countMathFunctions, zc, relations, samples);
  end match;
end findZeroCrossingsWhenEqns;

protected function findZeroCrossingsIfEqns
  input BackendDAE.Equation inIfEqn;
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  input list<BackendDAE.ZeroCrossing> inrelationsinZC;
  input list<BackendDAE.ZeroCrossing> inSamplesLst;
  input Integer incountRelations;
  input Integer incountMathFunctions;
  input Integer counteq;
  input Integer countwc;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;

  output BackendDAE.Equation outIfEqn;
  output Integer outCountRelations;
  output Integer outCountMathFunctions;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
  output list<BackendDAE.ZeroCrossing> outrelationsinZC;
  output list<BackendDAE.ZeroCrossing> outSamplesLst;
algorithm
  (outIfEqn, outCountRelations, outCountMathFunctions, outZeroCrossings, outrelationsinZC, outSamplesLst) := match(inIfEqn)
    local
      DAE.Exp condition;
      list<DAE.Exp> conditions, restconditions;
      BackendDAE.Equation ifeqn;
      list<BackendDAE.Equation> eqnstrue, elseeqns, eqnsAccum;
      list<BackendDAE.WhenClause> whenClauseAccum;
      list<list<BackendDAE.Equation>> eqnsTrueLst, resteqns;
      list<BackendDAE.ZeroCrossing> zc, relations, samples;
      Integer countRelations, countMathFunctions;
      DAE.ElementSource source_;
      BackendDAE.EquationAttributes eqAttr;

    case BackendDAE.IF_EQUATION(conditions={}, eqnstrue={}, eqnsfalse=elseeqns, source=source_, attr=eqAttr) equation
      (zc, elseeqns, _, countRelations, countMathFunctions, relations, samples) = findZeroCrossings2(vars, knvars, elseeqns, counteq, {}, countwc, incountRelations, incountMathFunctions, inZeroCrossings, inrelationsinZC, inSamplesLst, {}, {});
      elseeqns = listReverse(elseeqns);
    then (BackendDAE.IF_EQUATION({}, {}, elseeqns, source_, eqAttr), countRelations, countMathFunctions, zc, relations, samples);

    case BackendDAE.IF_EQUATION(conditions=condition::restconditions, eqnstrue=eqnstrue::resteqns, eqnsfalse=elseeqns, source=source_, attr=eqAttr) equation
      (condition, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossings3(condition, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars);
      (zc, eqnstrue, _, countRelations, countMathFunctions, relations, samples) = findZeroCrossings2(vars, knvars, eqnstrue, counteq, {}, countwc, countRelations, countMathFunctions, zc, relations, samples, {}, {});
      eqnstrue = listReverse(eqnstrue);
      ifeqn = BackendDAE.IF_EQUATION(restconditions, resteqns, elseeqns, source_, eqAttr);
      (BackendDAE.IF_EQUATION(conditions=conditions, eqnstrue=eqnsTrueLst, eqnsfalse=elseeqns, source=source_), countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossingsIfEqns(ifeqn, zc, relations, samples, countRelations, countMathFunctions, counteq, countwc, vars, knvars);
      conditions = condition::conditions;
      eqnsTrueLst = eqnstrue::eqnsTrueLst;
    then (BackendDAE.IF_EQUATION(conditions, eqnsTrueLst, elseeqns, source_, eqAttr), countRelations, countMathFunctions, zc, relations, samples);
  end match;
end findZeroCrossingsIfEqns;

protected function findZeroCrossings3
  input DAE.Exp e;
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  input list<BackendDAE.ZeroCrossing> inrelationsinZC;
  input list<BackendDAE.ZeroCrossing> inSamplesLst;
  input Integer incountRelations;
  input Integer incountMathFunctions;
  input Integer counteq;
  input Integer countwc;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output DAE.Exp eres;
  output Integer outCountRelations;
  output Integer outCountMathFunctions;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
  output list<BackendDAE.ZeroCrossing> outrelationsinZC;
  output list<BackendDAE.ZeroCrossing> outSamplesLst;
algorithm
  if Flags.isSet(Flags.RELIDX) then
    BackendDump.debugStrExpStr("start: ", e, "\n");
  end if;
  (eres, ((outZeroCrossings, outrelationsinZC, outSamplesLst, outCountRelations, outCountMathFunctions), _)) := Expression.traverseExpTopDown(e, collectZC, ((inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions), (counteq, countwc, vars, knvars)));
end findZeroCrossings3;

protected function collectZC
  "Collects zero crossings in equations"
  input DAE.Exp inExp;
  input tuple<tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, Integer, BackendDAE.Variables, BackendDAE.Variables>> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, Integer, BackendDAE.Variables, BackendDAE.Variables>> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp, inTpl)
    local
      DAE.Exp e, e1, e2, e_1, e_2, eres, eres1;
      BackendDAE.Variables vars, knvars;
      list<BackendDAE.ZeroCrossing> zeroCrossings, zc_lst, relations, samples;
      DAE.Operator op;
      Integer eq_count, wc_count, itmp, numRelations, numRelations1, numMathFunctions;
      BackendDAE.ZeroCrossing zc;
      DAE.CallAttributes attr;
      DAE.Type ty;

    case (DAE.CALL(path=Absyn.IDENT(name="noEvent")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="smooth")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="sample")), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      zc = createZeroCrossing(inExp, {eq_count}, {wc_count});
      samples = listAppend(samples, {zc});
      samples = mergeZeroCrossings(samples, {});
      //itmp = (listLength(zc_lst)-listLength(zeroCrossings));
      //indx = indx + (listLength(zc_lst) - listLength(zeroCrossings));
      if Flags.isSet(Flags.RELIDX) then
        print("sample index: " + intString(listLength(samples)) + "\n");
      end if;
    then (inExp, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // function with discrete expressions generate no zerocrossing
    case (DAE.LUNARY(exp=e1), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      if Flags.isSet(Flags.RELIDX) then
        print("discrete LUNARY: " + intString(numRelations) + "\n");
      end if;
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, exp2=e2), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
      if Flags.isSet(Flags.RELIDX) then
        print("discrete LBINARY: " + intString(numRelations) + "\n");
      end if;
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // coditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY: " + intString(numRelations) + "\n");
      end if;
      (e1, ((_, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZC, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));
      e_1 = DAE.LUNARY(op, e1);
      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      zc_lst = List.select1(zeroCrossings, zcEqual, zc);
      zeroCrossings = if listEmpty(zc_lst) then listAppend(zeroCrossings, {zc}) else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LBINARY: " + intString(numRelations) + "\n");
        BackendDump.debugExpStr(inExp, "\n");
      end if;
      (e_1, ((_, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZC, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));
      (e_2, ((_, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars))) = Expression.traverseExpTopDown(e2, collectZC, ((zeroCrossings, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars)));
      true = intGt(numRelations1, numRelations);
      e_1 = DAE.LBINARY(e_1, op, e_2);
      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      zc_lst = List.select1(zeroCrossings, zcEqual, zc);
      zeroCrossings = if listEmpty(zc_lst) then listAppend(zeroCrossings, {zc}) else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.dumpZeroCrossingList(zeroCrossings, "");
      end if;
    then (e_1, false, ((zeroCrossings, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // function with discrete expressions generate no zerocrossing
    case (DAE.RELATION(exp1=e1, exp2=e2), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
      if Flags.isSet(Flags.RELIDX) then
        print("discrete RELATION: " + intString(numRelations) + "\n");
      end if;
    then (inExp, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numRelations: " +intString(numRelations) + "\n");
      end if;
      e_1 = DAE.RELATION(e1, op, e2, numRelations, NONE());
      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      (eres, relations, numRelations) = zcIndex(e_1, numRelations, relations, zc);
      zc = createZeroCrossing(eres, {eq_count}, {wc_count});
      (DAE.RELATION(index=itmp), zeroCrossings, _) = zcIndex(eres, numRelations, zeroCrossings, zc);
      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + " index: " + intString(itmp) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // math function that triggering events
    case (DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("integer"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("floor"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("ceil"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2}, attr=attr), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // mod is rewritten to x-floor(x/y)*y
    case (DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty=ty)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("floor"), {DAE.BINARY(e1, DAE.DIV(ty), e2), DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);
      e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (e_2, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // rem is rewritten to div(x/y)*y - x
    case (DAE.CALL(path=Absyn.IDENT("rem"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty=ty)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);
      e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (e_2, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    else (inExp, true, inTpl);
  end matchcontinue;
end collectZC;

protected function collectZCAlgsFor
  "Collects zero crossings in for loops"
  input DAE.Exp inExp;
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> inTpl;
  output DAE.Exp outExp;
  output Boolean cont;
  output tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> outTpl;
algorithm
  (outExp,cont,outTpl) := matchcontinue (inExp, inTpl)
    local
      DAE.Exp e, e1, e2, e_1, e_2, eres, iterator, range, range2;
      list<DAE.Exp> inExpLst, explst;
      BackendDAE.Variables vars, knvars;
      list<BackendDAE.ZeroCrossing> zeroCrossings, zc_lst, zcLstNew, relations, samples;
      DAE.Operator op;
      Integer numRelations, alg_indx, itmp, numRelations1, numMathFunctions;
      list<Integer> eqs;
      Boolean b1, b2;
      DAE.Exp startvalue, stepvalue;
      Option<DAE.Exp> stepvalueopt;
      Integer istart, istep;
      BackendDAE.ZeroCrossing zc;
      DAE.CallAttributes attr;
      DAE.Type ty;
      list<DAE.Exp> le;

    case (DAE.CALL(path=Absyn.IDENT(name="noEvent")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="smooth")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="sample")), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      eqs = {alg_indx};
      zc = createZeroCrossing(inExp, eqs, {});
      samples = listAppend(samples, {zc});
      // lochel: don't merge zero crossings in algorithms (see #3358)
      // samples = mergeZeroCrossings(samples, {});
      if Flags.isSet(Flags.RELIDX) then
        print("sample index algotihm: " + intString(alg_indx) + "\n");
      end if;
    then (inExp, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.LUNARY(exp=e1), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      //fcall(Flags.RELIDX, print, "discrete LUNARY: " + intString(indx) + "\n");
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // coditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), (iterator, inExpLst, range as DAE.RANGE(), (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Expression.expContains(inExp, iterator);
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY with Iterator: " + intString(numRelations) + "\n");
      end if;
      (e1, (iterator, inExpLst, range2, (_, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
      e_1 = DAE.LUNARY(op, e1);
      (explst, itmp) = replaceIteratorWithStaticValues(e_1, iterator, inExpLst, numRelations);
      zc_lst = createZeroCrossings(explst, {alg_indx}, {});
      zc_lst = listAppend(zeroCrossings, zc_lst);
      // lochel: don't merge zero crossings in algorithms (see #3358)
      // zc_lst = mergeZeroCrossings(zc_lst, {});
      itmp = (listLength(zc_lst)-listLength(zeroCrossings));
      zeroCrossings = if itmp>0 then zc_lst else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor LUNARY with Iterator result zc: ");
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, (iterator, inExpLst, range2, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // coditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY: " + intString(numRelations) + "\n");
      end if;
      (e1, (iterator, inExpLst, range, (_, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
      e_1 = DAE.LUNARY(op, e1);
      zc = createZeroCrossing(e_1, {alg_indx}, {});
      zc_lst = List.select1(zeroCrossings, zcEqual, zc);
      zeroCrossings = if listEmpty(zc_lst) then listAppend(zeroCrossings, {zc}) else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor LUNARY result zc: ");
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
      //fcall(Flags.RELIDX, print, "discrete LBINARY: " + intString(numRelations) + "\n");
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LBINARY: " + intString(numRelations) + "\n");
        BackendDump.debugExpStr(inExp, "\n");
      end if;
      b1 = Expression.expContains(e1, iterator);
      b2 = Expression.expContains(e2, iterator);
      true = Util.boolOrList({b1, b2});
      (e_1, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
      (e_2, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));
      true = intGt(numRelations1, numRelations);
      e_1 = DAE.LBINARY(e_1, op, e_2);
      (explst, itmp) = replaceIteratorWithStaticValues(e_1, iterator, inExpLst, numRelations1);
      zc_lst = createZeroCrossings(explst, {alg_indx}, {});
      zc_lst = listAppend(zeroCrossings, zc_lst);
      // lochel: don't merge zero crossings in algorithms (see #3358)
      // zc_lst = mergeZeroCrossings(zc_lst, {});
      itmp = (listLength(zc_lst)-listLength(zeroCrossings));
      zeroCrossings = if itmp>0 then zc_lst else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.dumpZeroCrossingList(zeroCrossings, "collectZCAlgsFor LBINARY1 result zc");
      end if;
    then (e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LBINARY: " + intString(numRelations) + "\n");
        BackendDump.debugExpStr(inExp, "\n");
      end if;
      (e_1, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
      (e_2, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));
      true = intGt(numRelations1, numRelations);
      e_1 = DAE.LBINARY(e_1, op, e_2);
      zc = createZeroCrossing(e_1, {alg_indx}, {});
      zc_lst = List.select1(zeroCrossings, zcEqual, zc);
      zeroCrossings = if listEmpty(zc_lst) then listAppend(zeroCrossings, {zc}) else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.dumpZeroCrossingList(zeroCrossings, "collectZCAlgsFor LBINARY2 result zc");
      end if;
    then (e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));

    // function with discrete expressions generate no zerocrossing.
    case (DAE.RELATION(exp1=e1, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
    then (inExp, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range as DAE.RANGE(start=startvalue, step=stepvalueopt), (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      b1 = Expression.expContains(e1, iterator);
      b2 = Expression.expContains(e2, iterator);
      true = Util.boolOrList({b1, b2});
      if Flags.isSet(Flags.RELIDX) then
        print(" number of relations: " + intString(numRelations) + "\n");
      end if;
      stepvalue = Util.getOptionOrDefault(stepvalueopt, DAE.ICONST(1));
      istart = BackendDAEUtil.expInt(startvalue, knvars);
      istep = BackendDAEUtil.expInt(stepvalue, knvars);
      eres = DAE.RELATION(e1, op, e2, numRelations, SOME((iterator, istart, istep)));
      (explst, itmp) = replaceIteratorWithStaticValues(inExp, iterator, inExpLst, numRelations);
      if Flags.isSet(Flags.RELIDX) then
        print(" number of new zc: " + intString(listLength(explst)) + "\n");
      end if;
      zcLstNew = createZeroCrossings(explst, {alg_indx}, {});
      zc_lst = listAppend(relations, zcLstNew);
      // lochel: don't merge zero crossings in algorithms (see #3358)
      // zc_lst = mergeZeroCrossings(zc_lst, {});
      if Flags.isSet(Flags.RELIDX) then
        print(" number of new zc: " + intString(listLength(zc_lst)) + "\n");
      end if;
      itmp = (listLength(zc_lst)-listLength(relations));
      if Flags.isSet(Flags.RELIDX) then
        print(" itmp: " + intString(itmp) + "\n");
      end if;
      numRelations = intAdd(itmp, numRelations);
      zeroCrossings = listAppend(zeroCrossings, zcLstNew);
      // lochel: don't merge zero crossings in algorithms (see #3358)
      // zeroCrossings = mergeZeroCrossings(zeroCrossings, {});
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor result zc: " + ExpressionDump.printExpStr(eres)+ " index:" + intString(numRelations) + "\n");
      end if;
    then (eres, true, (iterator, inExpLst, range, (zeroCrossings, zc_lst, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      b1 = Expression.expContains(e1, iterator);
      b2 = Expression.expContains(e2, iterator);
      false = Util.boolOrList({b1, b2});
      eres = DAE.RELATION(e1, op, e2, numRelations, NONE());
      zc = createZeroCrossing(eres, {alg_indx}, {});
      zc_lst = listAppend(relations, {zc});
      // lochel: don't merge zero crossings in algorithms (see #3358)
      // zc_lst = mergeZeroCrossings(zc_lst, {});
      itmp = (listLength(zc_lst)-listLength(relations));
      numRelations = numRelations + itmp;
      zeroCrossings = listAppend(zeroCrossings, {zc});
      // lochel: don't merge zero crossings in algorithms (see #3358)
      // zeroCrossings = mergeZeroCrossings(zeroCrossings, {});
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor result zc: " + ExpressionDump.printExpStr(eres)+ " index:" + intString(numRelations) + "\n");
      end if;
    then (eres, true, (iterator, inExpLst, range, (zeroCrossings, zc_lst, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // math function that triggering events
    case (DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("integer"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("floor"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("ceil"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // mod is rewritten to x-floor(x/y)*y
    case (DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("floor"), {DAE.BINARY(e1, DAE.DIV(ty), e2), DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);
      e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (e_2, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // rem is rewritten to div(x/y)*y - x
    case (DAE.CALL(path=Absyn.IDENT("rem"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Flags.isSet(Flags.EVENTS);
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC: " + ExpressionDump.printExpStr(inExp) + " numMathFunctions: " +intString(numMathFunctions) + "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);
      e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc: " + ExpressionDump.printExpStr(eres) + "\n");
      end if;
    then (e_2, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    else (inExp, true, inTpl);
  end matchcontinue;
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
  input DAE.Exp inRelation;
  input Integer inIndex;
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  input BackendDAE.ZeroCrossing inZeroCrossing;
  output DAE.Exp outRelation;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
  output Integer outIndex;
algorithm
  (outRelation, outZeroCrossings, outIndex) := matchcontinue (inRelation)
    local
      DAE.Exp relation, e1, e2;
      DAE.Operator op;
      BackendDAE.ZeroCrossing newZeroCrossing;
      list<BackendDAE.ZeroCrossing> zcLst;

    case DAE.RELATION() equation
      {} = List.select1(inZeroCrossings, zcEqual, inZeroCrossing);
      zcLst = listAppend(inZeroCrossings, {inZeroCrossing});
    then (inRelation, zcLst, inIndex+1);

    // math function with one argument and index
    case DAE.CALL(expLst={_, _}) equation
      {} = List.select1(inZeroCrossings, zcEqual, inZeroCrossing);
      zcLst = listAppend(inZeroCrossings, {inZeroCrossing});
    then (inRelation, zcLst, inIndex+1);

    // math function with two arguments and index
    case DAE.CALL(expLst={_, _, _}) equation
      {} = List.select1(inZeroCrossings, zcEqual, inZeroCrossing);
      zcLst = listAppend(inZeroCrossings, {inZeroCrossing});
    then (inRelation, zcLst, inIndex+2);

    case _ equation
      BackendDAE.ZERO_CROSSING(relation_=relation)::_ = List.select1(inZeroCrossings, zcEqual, inZeroCrossing);
    then ((relation, inZeroCrossings, inIndex));

    else equation
      Error.addInternalError("function zcIndex failed for: " + ExpressionDump.printExpStr(inRelation), sourceInfo());
    then fail();
  end matchcontinue;
end zcIndex;

protected function mergeZeroCrossings "
  Takes a list of zero crossings and if more than one have identical
  function expressions they are merged into one zerocrossing.
  In the resulting list all zerocrossing have uniq function expressions."
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst;
  input list<BackendDAE.ZeroCrossing> inAccum;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  //BackendDump.dumpZeroCrossingList(inZeroCrossingLst, "mergeZeroCrossings input:");
  outZeroCrossingLst := match (inZeroCrossingLst)
    local
      BackendDAE.ZeroCrossing zc, same_1;
      list<BackendDAE.ZeroCrossing> samezc, diff, res, xs;

    case {}
    then listReverse(inAccum);

    case zc::xs equation
      (samezc, diff) = List.split1OnTrue(xs, zcEqual, zc);
      same_1 = List.fold(samezc, mergeZeroCrossing, zc);
      res = mergeZeroCrossings(diff, same_1::inAccum);
    then res;
  end match;
end mergeZeroCrossings;

protected function mergeZeroCrossing "
  Merges two zero crossings into one by makeing the union of the lists of
  equations and when clauses they appear in."
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output BackendDAE.ZeroCrossing outZeroCrossing;
protected
  list<Integer> eq, wc, eq1, wc1, eq2, wc2;
  DAE.Exp e1, e2, res;
algorithm
  BackendDAE.ZERO_CROSSING(relation_=e1, occurEquLst=eq1, occurWhenLst=wc1) := inZeroCrossing1;
  BackendDAE.ZERO_CROSSING(relation_=e2, occurEquLst=eq2, occurWhenLst=wc2) := inZeroCrossing2;
  res := getMinZeroCrossings(e1, e2);
  eq := List.union(eq1, eq2);
  wc := List.union(wc1, wc2);
  outZeroCrossing := BackendDAE.ZERO_CROSSING(res, eq, wc);
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

protected function zcEqual "
  Returns true if both zero crossings have the same function expression"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inZeroCrossing1, inZeroCrossing2)
    local
      Boolean res, res2;
      DAE.Exp e1, e2, e3, e4;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("sample"), expLst={e1, _, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("sample"), expLst={e2, _, _}))) equation
      res = Expression.expEqual(e1, e2);
    then res;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("integer"), expLst={e2, _}))) equation
      res = Expression.expEqual(e1, e2);
    then res;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("floor"), expLst={e2, _}))) equation
      res = Expression.expEqual(e1, e2);
    then res;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e2, _}))) equation
      res = Expression.expEqual(e1, e2);
    then res;

    case (BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2, _})), BackendDAE.ZERO_CROSSING(relation_=DAE.CALL(path=Absyn.IDENT("div"), expLst={e3, e4, _}))) equation
      res = Expression.expEqual(e1, e3);
      res2 = Expression.expEqual(e2, e4);
    then (res and res2);

    case (BackendDAE.ZERO_CROSSING(relation_=e1), BackendDAE.ZERO_CROSSING(relation_=e2)) equation
      res = Expression.expEqual(e1, e2);
    then res;
  end match;
end zcEqual;

protected function traverseStmtsExps "Handles the traversing of list<DAE.Statement>.
  Works with the help of Expression.traverseExpTopDown to find
  ZeroCrossings in algorithm statements
  modified: 2011-01 by wbraun"
  input list<DAE.Statement> inStmts;
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> inExtraArg;
  input BackendDAE.Variables inKnvars "this is needed to extend ranges" ;
  output tuple<list<DAE.Statement>, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplStmtTypeA;
algorithm
  outTplStmtTypeA := match(inStmts)
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
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> extraArg;
      list<tuple<DAE.ComponentRef, SourceInfo>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case {}
    then (({}, inExtraArg));

    case DAE.STMT_ASSIGN(type_=tp, exp1=e2, exp=e, source=source)::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (e_2, extraArg) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_ASSIGN(tp, e_2, e_1, source)::xs_1, extraArg));

    case DAE.STMT_TUPLE_ASSIGN(type_=tp, expExpLst=expl1, exp=e, source=source)::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (expl2, extraArg) = Expression.traverseExpListTopDown(expl1, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_TUPLE_ASSIGN(tp, expl2, e_1, source)::xs_1, extraArg));

    case DAE.STMT_ASSIGN_ARR(type_=tp, lhs=e2, exp=e, source=source)::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (e_2, _, extraArg) = collectZCAlgsFor(e2, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_ASSIGN_ARR(tp, e_2, e_1, source)::xs_1, extraArg));

    case (x as DAE.STMT_ASSIGN_ARR(type_=tp, lhs=e2, exp=e, source=source))::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      failure((e_2, _, _) = collectZCAlgsFor(e2, extraArg));
      true = Flags.isSet(Flags.FAILTRACE);
      print(DAEDump.ppStatementStr(x));
      print("Warning, not allowed to set the componentRef to a expression in FindZeroCrossings.traverseStmtsExps for ZeroCrosssing\n");
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_ASSIGN_ARR(tp, e_2, e_1, source)::xs_1, extraArg));

    case (DAE.STMT_IF(exp=e, statementLst=stmts, else_=algElse, source=source))::xs equation
      ((algElse, extraArg)) = traverseStmtsElseExps(algElse, inExtraArg, inKnvars);
      ((stmts2, extraArg)) = traverseStmtsExps(stmts, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_IF(e_1, stmts2, algElse, source)::xs_1, extraArg));

    case (DAE.STMT_FOR(type_=tp, iterIsArray=b1, iter=id1, index=ix, range=e, statementLst=stmts, source=source))::xs equation
      cr = ComponentReference.makeCrefIdent(id1, tp, {});
      iteratorExp = Expression.crefExp(cr);
      iteratorexps = BackendDAEUtil.extendRange(e, inKnvars);
      (stmts2, extraArg) = traverseStmtsForExps(iteratorExp, iteratorexps, e, stmts, inKnvars, inExtraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_FOR(tp, b1, id1, ix, e, stmts2, source)::xs_1, extraArg));

    case (DAE.STMT_PARFOR(type_=tp, iterIsArray=b1, iter=id1, index=ix, range=e, statementLst=stmts, loopPrlVars= loopPrlVars, source=source))::xs equation
      cr = ComponentReference.makeCrefIdent(id1, tp, {});
      iteratorExp = Expression.crefExp(cr);
      iteratorexps = BackendDAEUtil.extendRange(e, inKnvars);
      (stmts2, extraArg) = traverseStmtsForExps(iteratorExp, iteratorexps, e, stmts, inKnvars, inExtraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_PARFOR(tp, b1, id1, ix, e, stmts2, loopPrlVars, source)::xs_1, extraArg));

    case (DAE.STMT_WHILE(exp=e, statementLst=stmts, source=source))::xs equation
      ((stmts2, extraArg)) = traverseStmtsExps(stmts, inExtraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_WHILE(e_1, stmts2, source)::xs_1, extraArg));

    case (DAE.STMT_WHEN(exp=e, conditions=conditions, initialCall=initialCall, statementLst=stmts, elseWhen=NONE(), source=source))::xs equation
      // wbraun: statemenents inside when equations can't contain zero-crossings
      // ((stmts2, extraArg)) = traverseStmtsExps(stmts, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_WHEN(e_1, conditions, initialCall, stmts, NONE(), source)::xs_1, extraArg));

    case (DAE.STMT_WHEN(exp=e, conditions=conditions, initialCall=initialCall, statementLst=stmts, elseWhen=SOME(ew), source=source))::xs equation
      (({ew_1}, extraArg)) = traverseStmtsExps({ew}, inExtraArg, inKnvars);
      // wbraun: statemenents inside when equations can't contain zero-crossings
      // ((stmts2, extraArg)) = traverseStmtsExps(stmts, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_WHEN(e_1, conditions, initialCall, stmts, SOME(ew_1), source)::xs_1, extraArg));

    case (x as DAE.STMT_ASSERT())::xs equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    case (x as DAE.STMT_TERMINATE())::xs equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    case (x as DAE.STMT_REINIT())::xs equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    case (DAE.STMT_NORETCALL(exp=e, source=source))::xs equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_NORETCALL(e_1, source)::xs_1, extraArg));

    case (x as DAE.STMT_RETURN())::xs equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    case (x as DAE.STMT_BREAK())::xs equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    // MetaModelica extension. KS
    case DAE.STMT_FAILURE(body=stmts, source=source)::xs equation
      ((stmts2, extraArg)) = traverseStmtsExps(stmts, inExtraArg, inKnvars);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_FAILURE(stmts2, source)::xs_1, extraArg));

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
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> inExtraArg;
  input BackendDAE.Variables inKnvars;
  output tuple<DAE.Else, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplStmtTypeA;
algorithm
  outTplStmtTypeA := match(inElse)
    local
      DAE.Exp e, e_1;
      list<DAE.Statement> st, st_1;
      DAE.Else el, el_1;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> extraArg;

    case DAE.NOELSE()
    then ((DAE.NOELSE(), inExtraArg));

    case DAE.ELSEIF(e, st, el) equation
      ((el_1, extraArg)) = traverseStmtsElseExps(el, inExtraArg, inKnvars);
      ((st_1, extraArg)) = traverseStmtsExps(st, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
    then ((DAE.ELSEIF(e_1, st_1, el_1), extraArg));

    case DAE.ELSE(st) equation
      ((st_1, extraArg)) = traverseStmtsExps(st, inExtraArg, inKnvars);
    then ((DAE.ELSE(st_1), extraArg));
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
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> inExtraArg;
  output list<DAE.Statement> outStatements;
  output tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> outTpl;
algorithm
  (outStatements, outTpl) := matchcontinue (inExplst, inExtraArg)
    local
      list<DAE.Statement> statementLst;
      tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer> tpl2;
      tuple<Integer, BackendDAE.Variables, BackendDAE.Variables> tpl3;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> extraArg;

    case ({}, _)
    then (inStmts, inExtraArg);

    case (_, (_, _, _, tpl2, tpl3)) equation
      ((statementLst, extraArg)) = traverseStmtsExps(inStmts, (inIteratorExp, inExplst, inRange, tpl2, tpl3), inKnvars);
    then (statementLst, extraArg);

    else equation
      Error.addInternalError("function traverseStmtsForExps failed", sourceInfo());
    then fail();
  end matchcontinue;
end traverseStmtsForExps;

protected function createZeroCrossings "
  Constructs a list of zero crossings from a list of relations. Each zero
  crossing gets the same equation indices and when clause indices."
  input list<DAE.Exp> inExpExpLst1;
  input list<Integer> inOccurEquLst;
  input list<Integer> inOccurWhenLst;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst := List.map2(inExpExpLst1, createZeroCrossing, inOccurEquLst, inOccurWhenLst);
end createZeroCrossings;

protected function createZeroCrossing
  input DAE.Exp inRelation;
  input list<Integer> inOccurEquLst;
  input list<Integer> inOccurWhenLst;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := match(inOccurEquLst, inOccurWhenLst)
    case ({-1}, _)
    then BackendDAE.ZERO_CROSSING(inRelation, {}, inOccurWhenLst);

    case (_, {-1})
    then BackendDAE.ZERO_CROSSING(inRelation, inOccurEquLst, {});

    else BackendDAE.ZERO_CROSSING(inRelation, inOccurEquLst, inOccurWhenLst);
  end match;
end createZeroCrossing;

annotation(__OpenModelica_Interface="backend");
end FindZeroCrossings;

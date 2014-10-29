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

protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import DAEDump;
protected import Debug;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import Flags;
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

protected function findZeroCrossings1 "This function finds all zerocrossings in the list of equations and
  the list of when clauses."
  input BackendDAE.EqSystem inSyst;
  input BackendDAE.Shared inShared;
  output BackendDAE.EqSystem outSyst;
  output BackendDAE.Shared outShared;
protected
  BackendDAE.Variables vars, knvars, exobj, av;
  BackendDAE.EquationArray eqns, remeqns, inieqns, eqns1;
  list<DAE.Constraint> constrs;
  list<DAE.ClassAttributes> clsAttrs;
  BackendDAE.EventInfo einfo, einfo1;
  BackendDAE.ExternalObjectClasses eoc;
  list<BackendDAE.WhenClause> whenclauses;
  list<BackendDAE.Equation> eqs_lst, eqs_lst1;
  list<BackendDAE.TimeEvent> timeEvents;
  list<BackendDAE.ZeroCrossing> zero_crossings;
  list<BackendDAE.ZeroCrossing> relations, sampleLst;
  Integer countRelations;
  Integer countMathFunctions;
  Option<BackendDAE.IncidenceMatrix> m, mT;
  BackendDAE.BackendDAEType btp;
  BackendDAE.Matching matching;
  DAE.FunctionTree funcs;
  BackendDAE.SymbolicJacobians symjacs;
  FCore.Cache cache;
  FCore.Graph graph;
  BackendDAE.StateSets stateSets;
  BackendDAE.ExtraInfo ei;
  BackendDAE.BaseClockPartitionKind partitionKind;
algorithm
  BackendDAE.EQSYSTEM(vars, eqns, m, mT, matching, stateSets, partitionKind) := inSyst;
  BackendDAE.SHARED(knvars, exobj, av, inieqns, remeqns, constrs, clsAttrs,
    cache, graph, funcs, einfo as BackendDAE.EVENT_INFO(timeEvents=timeEvents, zeroCrossingLst=zero_crossings,
    sampleLst=sampleLst, whenClauseLst=whenclauses, relationsLst=relations,
    relationsNumber=countRelations, numberMathEvents=countMathFunctions),
    eoc, btp, symjacs, ei) := inShared;

  eqs_lst := BackendEquation.equationList(eqns);
  (zero_crossings, eqs_lst1, _, countRelations, countMathFunctions, relations, sampleLst) := findZeroCrossings2(vars, knvars, eqs_lst, 0, {}, 0, countRelations, countMathFunctions, zero_crossings, relations, sampleLst, {}, {});
  eqs_lst1 := listReverse(eqs_lst1);
  if Flags.isSet(Flags.RELIDX) then
    print("findZeroCrossings1 number of relations : " +& intString(countRelations) +& "\n");
    print("findZeroCrossings1 sample index: " +& intString(listLength(sampleLst)) +& "\n");
  end if;
  eqns1 := BackendEquation.listEquation(eqs_lst1);
  einfo1 := BackendDAE.EVENT_INFO(timeEvents, whenclauses, zero_crossings, sampleLst, relations, countRelations, countMathFunctions);
  outSyst := BackendDAE.EQSYSTEM(vars, eqns1, m, mT, matching, stateSets, partitionKind);
  outShared := BackendDAE.SHARED(knvars, exobj, av, inieqns, remeqns, constrs, clsAttrs, cache, graph, funcs, einfo1, eoc, btp, symjacs, ei);
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
  (outZeroCrossingLst, outEquationLst, outWhenClauseLst, outNumberOfRelations, outNumberOfMathFunctions, outRelationsLst, outSamplesLst) :=
  match (inVariables1, knvars, inEquationLst2, inEqnCount, inWhenClauseLst4, inWhenClauseCount, inNumberOfRelations, inNumberOfMathFunctions, inZeroCrossingLst, inRelationsLst, inSamplesLst, inEquationLstAccum, inWhenClauseAccum)
    local
      BackendDAE.Variables v;
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

    case (_, _, {}, _, {}, _, countRelations, countMathFunctions, res, relationsLst, sampleLst, _, _)
    then (res, inEquationLstAccum, inWhenClauseAccum, countRelations, countMathFunctions, relationsLst, sampleLst);

    // all algorithm stmts are processed firstly
   case (v, _, ((BackendDAE.ALGORITHM(size=size, alg=DAE.ALGORITHM_STMTS(stmts), source= source_, expand=expand, attr=eqAttr))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      eq_count = eq_count + 1;
      ((stmts_1, (_, _, _, (res, relationsLst, sampleLst, countRelations, countMathFunctions), (_, _, _)))) = traverseStmtsExps(stmts, (DAE.RCONST(0.0), {}, DAE.RCONST(0.0), (zcs, relationsLst, sampleLst, countRelations, countMathFunctions), (eq_count, v, knvars)), knvars);
      eqnsAccum = BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(stmts_1), source_, expand, eqAttr)::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // then all when clauses are processed
    case (v, _, el, eq_count, ((BackendDAE.WHEN_CLAUSE(condition = daeExp, reinitStmtLst=whenOperations , elseClause = elseClause_ ))::xsWhen), wc_count, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.debugStrExpStr("processed when clause: ", daeExp, "\n");
      end if;
      wc_count = wc_count + 1;
      (eres1, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(daeExp, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, -1, wc_count, v, knvars);
      whenClauseAccum = BackendDAE.WHEN_CLAUSE(eres1, whenOperations, elseClause_)::whenClauseAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, el, eq_count, xsWhen, wc_count, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // check when equation condition
    case (v, _, ((BackendDAE.WHEN_EQUATION(size=size, whenEquation=weqn, source= source_, attr=eqAttr))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      eq_count = eq_count + 1;
      (weqn, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossingsWhenEqns(weqn, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
      eqnsAccum = BackendDAE.WHEN_EQUATION(size, weqn, source_, eqAttr)::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // after all algorithms and when clauses are processed, all equations are processed
    case (v, _, ((BackendDAE.EQUATION(exp = e1, scalar = e2, source= source_, attr=eqAttr))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      eq_count = eq_count + 1;
      (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
      (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
       eqnsAccum = BackendDAE.EQUATION(eres1, eres2, source_, eqAttr)::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case (v, _, ((BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=source, attr=eqAttr))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      eq_count = eq_count + 1;
      (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
      (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
       eqnsAccum = BackendDAE.COMPLEX_EQUATION(size, eres1, eres2, source, eqAttr)::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case (v, _, ((BackendDAE.ARRAY_EQUATION(dimSize=dimsize, left=e1, right=e2, source=source, attr=eqAttr))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      eq_count = eq_count + 1;
      (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
      (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
       eqnsAccum = BackendDAE.ARRAY_EQUATION(dimsize, eres1, eres2, source, eqAttr)::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case (v, _, ((BackendDAE.SOLVED_EQUATION(componentRef = cref, exp = e1, source= source_, attr=eqAttr))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      (eres1, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
       eqnsAccum = BackendDAE.SOLVED_EQUATION(cref, eres1, source_, eqAttr)::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case (v, _, ((BackendDAE.RESIDUAL_EQUATION(exp = e1, source= source_, attr=eqAttr))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      eq_count = eq_count + 1;
      (eres1, countRelations, countMathFunctions, relationsLst, res, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
       eqnsAccum = BackendDAE.RESIDUAL_EQUATION(eres1, source_, eqAttr)::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case (v, _, ((e as BackendDAE.IF_EQUATION(conditions=_))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      eq_count = eq_count + 1;
      (e, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossingsIfEqns(e, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
      eqnsAccum = e::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
    then (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // let when equation pass they are discrete and can't contain ZeroCrossings
    case (v, _, (e::xs), eq_count, {}, _, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum) equation
      eq_count = eq_count + 1;
      eqnsAccum = e::eqnsAccum;
      (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
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
  output Integer outcountRelations;
  output Integer outcountMathFunctions;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
  output list<BackendDAE.ZeroCrossing> outrelationsinZC;
  output list<BackendDAE.ZeroCrossing> outSamplesLst;
algorithm
  (oWhenEqn, outcountRelations, outcountMathFunctions, outZeroCrossings, outrelationsinZC, outSamplesLst) :=
  match(inWhenEqn, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars)
    local
      DAE.Exp cond, e;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation we;
      list<BackendDAE.ZeroCrossing> zc, relations, samples;
      Integer countRelations, countMathFunctions;

    case (BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e, elsewhenPart=NONE()), _, _, _, _, _, _, _, _, _) equation
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.debugStrExpStr("processed when condition: ", cond, "\n");
      end if;
      (cond, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossings3(cond, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars);
    then (BackendDAE.WHEN_EQ(cond, cr, e, NONE()), countRelations, countMathFunctions, zc, relations, samples);

    case (BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e, elsewhenPart=SOME(we)), _, _, _, _, _, _, _, _, _) equation
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

  output BackendDAE.Equation oIfEqn;
  output Integer outcountRelations;
  output Integer outcountMathFunctions;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
  output list<BackendDAE.ZeroCrossing> outrelationsinZC;
  output list<BackendDAE.ZeroCrossing> outSamplesLst;
algorithm
  (oIfEqn, outcountRelations, outcountMathFunctions, outZeroCrossings, outrelationsinZC, outSamplesLst) :=
  match(inIfEqn, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars)
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

    case (BackendDAE.IF_EQUATION(conditions={}, eqnstrue={}, eqnsfalse=elseeqns, source=source_, attr=eqAttr), _, _, _, _, _, _, _, _, _) equation
      (zc, elseeqns, _, countRelations, countMathFunctions, relations, samples) = findZeroCrossings2(vars, knvars, elseeqns, counteq, {}, countwc, incountRelations, incountMathFunctions, inZeroCrossings, inrelationsinZC, inSamplesLst, {}, {});
      elseeqns = listReverse(elseeqns);
    then (BackendDAE.IF_EQUATION({}, {}, elseeqns, source_, eqAttr), countRelations, countMathFunctions, zc, relations, samples);

    case (BackendDAE.IF_EQUATION(conditions=condition::restconditions, eqnstrue=eqnstrue::resteqns, eqnsfalse=elseeqns, source=source_, attr=eqAttr), _, _, _, _, _, _, _, _, _) equation
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
  output Integer outcountRelations;
  output Integer outcountMathFunctions;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
  output list<BackendDAE.ZeroCrossing> outrelationsinZC;
  output list<BackendDAE.ZeroCrossing> outSamplesLst;
algorithm
  if Flags.isSet(Flags.RELIDX) then
    BackendDump.debugStrExpStr("start: ", e, "\n");
  end if;
  (eres, ((outZeroCrossings, outrelationsinZC, outSamplesLst, outcountRelations, outcountMathFunctions), _)) := Expression.traverseExpTopDown(e, collectZC, ((inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions), (counteq, countwc, vars, knvars)));
end findZeroCrossings3;

protected function collectZC "author: unknown
  modified: 2011-01 by wbraun
  Collects zero crossings in equations"
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

    case (DAE.CALL(path=Absyn.IDENT(name = "noEvent")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path = Absyn.IDENT(name = "smooth")), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name = "sample")), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      zc = createZeroCrossing(inExp, {eq_count}, {wc_count});
      samples = listAppend(samples, {zc});
      samples = mergeZeroCrossings(samples, {});
      //itmp = (listLength(zc_lst)-listLength(zeroCrossings));
      //indx = indx + (listLength(zc_lst) - listLength(zeroCrossings));
      if Flags.isSet(Flags.RELIDX) then
        print("sample index: " +& intString(listLength(samples)) +& "\n");
      end if;
    then (inExp, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // function with discrete expressions generate no zerocrossing
    case (DAE.LUNARY(exp=e1), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      if Flags.isSet(Flags.RELIDX) then
        print("discrete LUNARY: " +& intString(numRelations) +& "\n");
      end if;
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, exp2=e2), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
      if Flags.isSet(Flags.RELIDX) then
        print("discrete LBINARY: " +& intString(numRelations) +& "\n");
      end if;
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // coditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY: " +& intString(numRelations) +& "\n");
      end if;
      (e1, ((_, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZC, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));
      e_1 = DAE.LUNARY(op, e1);
      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      zc_lst = List.select1(zeroCrossings, zcEqual, zc);
      zeroCrossings = if List.isEmpty(zc_lst) then listAppend(zeroCrossings, {zc}) else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LBINARY: " +& intString(numRelations) +& "\n");
        BackendDump.debugExpStr(inExp, "\n");
      end if;
      (e_1, ((_, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZC, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));
      (e_2, ((_, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars))) = Expression.traverseExpTopDown(e2, collectZC, ((zeroCrossings, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars)));
      true = intGt(numRelations1, numRelations);
      e_1 = DAE.LBINARY(e_1, op, e_2);
      zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
      zc_lst = List.select1(zeroCrossings, zcEqual, zc);
      zeroCrossings = if List.isEmpty(zc_lst) then listAppend(zeroCrossings, {zc}) else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        BackendDump.zeroCrossingListString(zeroCrossings);
      end if;
    then (e_1, false, ((zeroCrossings, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // function with discrete expressions generate no zerocrossing
    case (DAE.RELATION(exp1=e1, exp2=e2), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
      if Flags.isSet(Flags.RELIDX) then
        print("discrete RELATION: " +& intString(numRelations) +& "\n");
      end if;
    then (inExp, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
       if Flags.isSet(Flags.RELIDX) then
         print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numRelations: " +& intString(numRelations) +& "\n");
       end if;
       e_1 = DAE.RELATION(e1, op, e2, numRelations, NONE());
       zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
       (eres, relations, numRelations) = zcIndex(e_1, numRelations, relations, zc);
       zc = createZeroCrossing(eres, {eq_count}, {wc_count});
       (DAE.RELATION(index=itmp), zeroCrossings, _) = zcIndex(eres, numRelations, zeroCrossings, zc);
       if Flags.isSet(Flags.RELIDX) then
         print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& " index: " +& intString(itmp) +& "\n");
       end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    // math function that triggering events
    case (DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
       if Flags.isSet(Flags.RELIDX) then
         print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
       end if;

       e_1 = DAE.CALL(Absyn.IDENT("integer"), {e1, DAE.ICONST(numMathFunctions)}, attr);

       zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
       (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

       if Flags.isSet(Flags.RELIDX) then
         print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
       end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
       if Flags.isSet(Flags.RELIDX) then
         print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
       end if;

       e_1 = DAE.CALL(Absyn.IDENT("floor"), {e1, DAE.ICONST(numMathFunctions)}, attr);

       zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
       (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

       if Flags.isSet(Flags.RELIDX) then
         print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
       end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1}, attr=attr), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
       if Flags.isSet(Flags.RELIDX) then
         print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
       end if;

       e_1 = DAE.CALL(Absyn.IDENT("ceil"), {e1, DAE.ICONST(numMathFunctions)}, attr);

       zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
       (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

       if Flags.isSet(Flags.RELIDX) then
         print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
       end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2}, attr=attr), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
       if Flags.isSet(Flags.RELIDX) then
         print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
       end if;

       e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

       zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
       (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

       if Flags.isSet(Flags.RELIDX) then
         print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
       end if;
    then (eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    /* mod is rewritten to x-floor(x/y)*y */
    case (DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty=ty)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
       if Flags.isSet(Flags.RELIDX) then
         print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
       end if;

       e_1 = DAE.CALL(Absyn.IDENT("floor"), {DAE.BINARY(e1, DAE.DIV(ty), e2), DAE.ICONST(numMathFunctions)}, attr);

       zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
       (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);
       e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

       if Flags.isSet(Flags.RELIDX) then
         print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
       end if;
    then (e_2, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    /* rem is rewritten to div(x/y)*y - x */
    case (DAE.CALL(path=Absyn.IDENT("rem"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty=ty)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))) equation
       if Flags.isSet(Flags.RELIDX) then
         print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
       end if;

       e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

       zc = createZeroCrossing(e_1, {eq_count}, {wc_count});
       (eres, zeroCrossings, numMathFunctions) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);
       e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

       if Flags.isSet(Flags.RELIDX) then
         print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
       end if;
    then (e_2, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));

    else (inExp, true, inTpl);
  end matchcontinue;
end collectZC;

/* TODO: implement math functions support here */
protected function collectZCAlgsFor "Collects zero crossings in for loops
  added: 2011-01 by wbraun
  lochel: merged this with function collectZCAlgs"
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

    case (DAE.CALL(path=Absyn.IDENT(name="smooth"))), _)
    then (inExp, false, inTpl);

    case (DAE.CALL(path=Absyn.IDENT(name="sample")), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      eqs = {alg_indx};
      zc = createZeroCrossing(e, eqs, {});
      samples = listAppend(samples, {zc});
      samples = mergeZeroCrossings(samples, {});
      if Flags.isSet(Flags.RELIDX) then
        print("sample index algotihm: " +& intString(alg_indx) +& "\n");
      end if;
    then (inExp, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.LUNARY(exp=e1), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      //fcall(Flags.RELIDX, print, "discrete LUNARY: " +& intString(indx) +& "\n");
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // coditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), (iterator, inExpLst, range as DAE.RANGE(start=_), (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = Expression.expContains(inExp, iterator);
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY with Iterator: " +& intString(numRelations) +& "\n");
      end if;
      (e1, (iterator, inExpLst, range2, (_, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
      e_1 = DAE.LUNARY(op, e1);
      (explst, itmp) = replaceIteratorwithStaticValues(e_1, iterator, inExpLst, numRelations);
      zc_lst = createZeroCrossings(explst, {alg_indx}, {});
      zc_lst = listAppend(zeroCrossings, zc_lst);
      zc_lst = mergeZeroCrossings(zc_lst, {});
      itmp = (listLength(zc_lst)-listLength(zeroCrossings));
      zeroCrossings = if itmp>0 then zc_lst else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor LUNARY with Iterator result zc : ");
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, (iterator, inExpLst, range2, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // coditions that are zerocrossings.
    case (DAE.LUNARY(exp=e1, operator=op), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LUNARY: " +& intString(numRelations) +& "\n");
      end if;
      (e1, (iterator, inExpLst, range, (_, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
      e_1 = DAE.LUNARY(op, e1);
      zc = createZeroCrossing(e_1, {alg_indx}, {});
      zc_lst = List.select1(zeroCrossings, zcEqual, zc);
      zeroCrossings = if List.isEmpty(zc_lst) then listAppend(zeroCrossings, {zc}) else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor LUNARY result zc : ");
        BackendDump.debugExpStr(e_1, "\n");
      end if;
    then (e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
      //fcall(Flags.RELIDX, print, "discrete LBINARY: " +& intString(numRelations) +& "\n");
      //fcall(Flags.RELIDX, BackendDump.debugExpStr, (inExp, "\n"));
    then (inExp, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LBINARY: " +& intString(numRelations) +& "\n");
        BackendDump.debugExpStr(inExp, "\n");
      end if;
      b1 = Expression.expContains(e1, iterator);
      b2 = Expression.expContains(e2, iterator);
      true = Util.boolOrList({b1, b2});
      (e_1, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
      (e_2, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));
      true = intGt(numRelations1, numRelations);
      e_1 = DAE.LBINARY(e_1, op, e_2);
      (explst, itmp) = replaceIteratorwithStaticValues(e_1, iterator, inExpLst, numRelations1);
      zc_lst = createZeroCrossings(explst, {alg_indx}, {});
      zc_lst = listAppend(zeroCrossings, zc_lst);
      zc_lst = mergeZeroCrossings(zc_lst, {});
      itmp = (listLength(zc_lst)-listLength(zeroCrossings));
      zeroCrossings = if itmp>0 then zc_lst else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor LBINARY1 result zc : ");
        print(BackendDump.zeroCrossingListString(zeroCrossings));
      end if;
    then (e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("continues LBINARY: " +& intString(numRelations) +& "\n");
        BackendDump.debugExpStr(inExp, "\n");
      end if;
      (e_1, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
      (e_2, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));
      true = intGt(numRelations1, numRelations);
      e_1 = DAE.LBINARY(e_1, op, e_2);
      zc = createZeroCrossing(e_1, {alg_indx}, {});
      zc_lst = List.select1(zeroCrossings, zcEqual, zc);
      zeroCrossings = if List.isEmpty(zc_lst) then listAppend(zeroCrossings, {zc}) else zeroCrossings;
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor LBINARY2 result zc : ");
        print(BackendDump.zeroCrossingListString(zeroCrossings));
      end if;
    then (e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));

    // function with discrete expressions generate no zerocrossing.
    case (DAE.RELATION(exp1=e1, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
      true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
    then (inExp, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range as DAE.RANGE(start=startvalue, step=stepvalueopt), (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      b1 = Expression.expContains(e1, iterator);
      b2 = Expression.expContains(e2, iterator);
      true = Util.boolOrList({b1, b2});
      if Flags.isSet(Flags.RELIDX) then
        print(" number of relations : " +& intString(numRelations) +& "\n");
      end if;
      stepvalue = Util.getOptionOrDefault(stepvalueopt, DAE.ICONST(1));
      istart = BackendDAECreate.expInt(startvalue, knvars);
      istep = BackendDAECreate.expInt(stepvalue, knvars);
      e_1 = DAE.RELATION(e1, op, e2, numRelations, SOME((iterator, istart, istep)));
      (explst, itmp) = replaceIteratorwithStaticValues(inExp, iterator, inExpLst, numRelations);
      if Flags.isSet(Flags.RELIDX) then
        print(" number of new zc : " +& intString(listLength(explst)) +& "\n");
      end if;
      zcLstNew = createZeroCrossings(explst, {alg_indx}, {});
      zc_lst = listAppend(relations, zcLstNew);
      zc_lst = mergeZeroCrossings(zc_lst, {});
      if Flags.isSet(Flags.RELIDX) then
        print(" number of new zc : " +& intString(listLength(zc_lst)) +& "\n");
      end if;
      itmp = (listLength(zc_lst)-listLength(relations));
      if Flags.isSet(Flags.RELIDX) then
        print(" itmp : " +& intString(itmp) +& "\n");
      end if;
      numRelations = intAdd(itmp, numRelations);
      eres = if itmp>0 then e_1 else inExp;
      zeroCrossings = listAppend(zeroCrossings, zcLstNew);
      zeroCrossings = mergeZeroCrossings(zeroCrossings, {});
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor result zc : "  +& ExpressionDump.printExpStr(eres)+& " index:"  +& intString(numRelations) +& "\n");
      end if;
    then (eres, true, (iterator, inExpLst, range, (zeroCrossings, zc_lst, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // All other functions generate zerocrossing.
    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      b1 = Expression.expContains(e1, iterator);
      b2 = Expression.expContains(e2, iterator);
      false = Util.boolOrList({b1, b2});
      e_1 = DAE.RELATION(e1, op, e2, numRelations, NONE());
      zc = createZeroCrossing(e_1, {alg_indx}, {});
      zc_lst = listAppend(relations, {zc});
      zc_lst = mergeZeroCrossings(zc_lst, {});
      itmp = (listLength(zc_lst)-listLength(relations));
      numRelations = numRelations + itmp;
      eres = if itmp>0 then e_1 else inExp;
      zeroCrossings = listAppend(zeroCrossings, {zc});
      zeroCrossings = mergeZeroCrossings(zeroCrossings, {});
      if Flags.isSet(Flags.RELIDX) then
        print("collectZCAlgsFor result zc : "  +& ExpressionDump.printExpStr(eres)+& " index:"  +& intString(numRelations) +& "\n");
      end if;
    then (eres, true, (iterator, inExpLst, range, (zeroCrossings, zc_lst, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // math function that triggering events
    case (DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("integer"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("floor"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("ceil"), {e1, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    case (DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2}, attr=attr), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      end if;
    then (eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // mod is rewritten to x-floor(x/y)*y
    case (DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("floor"), {DAE.BINARY(e1, DAE.DIV(ty), e2), DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);
      e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      end if;
    then (e_2, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    // rem is rewritten to div(x/y)*y - x
    case (DAE.CALL(path=Absyn.IDENT("rem"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))) equation
      if Flags.isSet(Flags.RELIDX) then
        print("start collectZC : "  +& ExpressionDump.printExpStr(inExp) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");
      end if;

      e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

      zc = createZeroCrossing(e_1, {alg_indx}, {});
      ((eres, zeroCrossings, numMathFunctions)) = zcIndex(e_1, numMathFunctions, zeroCrossings, zc);
      e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

      if Flags.isSet(Flags.RELIDX) then
        print("collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      end if;
    then (e_2, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));

    else (inExp, true, inTpl);
  end matchcontinue;
end collectZCAlgsFor;

protected function replaceIteratorwithStaticValues "
  Helper function for collectZCAlgFor "
  input DAE.Exp inExp;
  input DAE.Exp inIterator;
  input list<DAE.Exp> inExpLst;
  input Integer inIndex;
  output list<DAE.Exp> outZeroCrossings;
  output Integer outIndex;
algorithm
  (outZeroCrossings, outIndex) := matchcontinue(inExp, inIterator, inExpLst, inIndex)
    local
      DAE.Exp e, e1, e2, res1, e_1;
      DAE.Operator op;
      list<DAE.Exp> rest, res2;
      Integer index;

    case (_, _, {}, _)
    then ({}, inIndex);

    case (DAE.RELATION(exp1=e1, operator=op, exp2=e2), _, e::rest, _) equation
      e_1 = DAE.RELATION(e1, op, e2, inIndex, NONE());
      (res1, _) = Expression.replaceExpTpl(e_1, (inIterator, e));
      (res2, index) = replaceIteratorwithStaticValues(inExp, inIterator, rest, inIndex+1);
      res2 = res1::res2;
    then (res2, index);

    case (DAE.LUNARY(exp=e1, operator=op), _, e::rest, _) equation
      e_1 = DAE.LUNARY(op, e1);
      (res1, _) = Expression.replaceExpTpl(e_1, (inIterator, e));
      (res2, index) = replaceIteratorwithStaticValues(inExp, inIterator, rest, inIndex+1);
      res2 = res1 :: res2;
    then (res2, index);

    case (DAE.LBINARY(exp1=e1, operator=op, exp2=e2), _, e::rest, _) equation
      e_1 = DAE.LBINARY(e1, op, e2);
      (res1, _) = Expression.replaceExpTpl(e_1, (inIterator, e));
      (res2, index) = replaceIteratorwithStaticValues(inExp, inIterator, rest, inIndex+1);
      res2 = res1 :: res2;
    then (res2, index);

    case (_, _, _, _) equation
      print("FindZeroCrossings.replaceIteratorwithStaticValues failed \n");
    then fail();
  end matchcontinue;
end replaceIteratorwithStaticValues;

protected function zcIndex "
  "
  input DAE.Exp inRelation;
  input Integer inIndex;
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  input BackendDAE.ZeroCrossing inZeroCrossing;
  output DAE.Exp outRelation;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
  output Integer outIndex;
algorithm
  (outRelation, outZeroCrossings, outIndex) := matchcontinue (inRelation, inIndex, inZeroCrossings, inZeroCrossing)
    local
      DAE.Exp relation, e1, e2;
      DAE.Operator op;
      BackendDAE.ZeroCrossing newZeroCrossing;
      list<BackendDAE.ZeroCrossing> zcLst;

    case (DAE.RELATION(exp1=_), _, _, _) equation
      {} = List.select1(inZeroCrossings, zcEqual, inZeroCrossing);
      zcLst = listAppend(inZeroCrossings, {inZeroCrossing});
    then (inRelation, zcLst, inIndex+1);

    // math function with one argument and index
    case (DAE.CALL(expLst={_, _}), _, _, _) equation
      {} = List.select1(inZeroCrossings, zcEqual, inZeroCrossing);
      zcLst = listAppend(inZeroCrossings, {inZeroCrossing});
    then (inRelation, zcLst, inIndex+1);

    // math function with two arguments and index
    case (DAE.CALL(expLst={_, _, _}), _, _, _) equation
      {} = List.select1(inZeroCrossings, zcEqual, inZeroCrossing);
      zcLst = listAppend(inZeroCrossings, {inZeroCrossing});
    then (inRelation, zcLst, inIndex+2);

    case (_, _, _, _) equation
      BackendDAE.ZERO_CROSSING(relation_=relation)::_ = List.select1(inZeroCrossings, zcEqual, inZeroCrossing);
    then ((relation, inZeroCrossings, inIndex));

    else equation
      Error.addInternalError("./Compiler/BackEnd/FindZeroCrossings.mo: function zcIndex failed for: "  +& ExpressionDump.printExpStr(inRelation));
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
  outZeroCrossingLst := matchcontinue (inZeroCrossingLst, inAccum)
    local
      BackendDAE.ZeroCrossing zc, same_1;
      list<BackendDAE.ZeroCrossing> samezc, diff, res, xs;

    case ({}, _)
    then listReverse(inAccum);

    case (zc::xs, _) equation
      (samezc, diff) = List.split1OnTrue(xs, zcEqual, zc);
      same_1 = List.fold(samezc, mergeZeroCrossing, zc);
      res = mergeZeroCrossings(diff, same_1::inAccum);
    then res;

    else equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("- FindZeroCrossings.mergeZeroCrossings failed!");
    then fail();
  end matchcontinue;
end mergeZeroCrossings;

protected function mergeZeroCrossing "
  Merges two zero crossings into one by makeing the union of the lists of
  equaions and when clauses they appear in.
  modified: 2011-01 by wbraun
  merge to ZeroCrosssing with the lowest index"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := matchcontinue (inZeroCrossing1, inZeroCrossing2)
    local
      list<Integer> eq, wc, eq1, wc1, eq2, wc2;
      DAE.Exp e1, e2, res;

    case (BackendDAE.ZERO_CROSSING(relation_ = e1, occurEquLst = eq1, occurWhenLst = wc1), BackendDAE.ZERO_CROSSING(relation_ = e2, occurEquLst = eq2, occurWhenLst = wc2)) equation
      res = getMinZeroCrossings(e1, e2);
      eq = List.union(eq1, eq2);
      wc = List.union(wc1, wc2);
    then BackendDAE.ZERO_CROSSING(res, eq, wc);

    case (BackendDAE.ZERO_CROSSING(relation_ = e1, occurEquLst = _, occurWhenLst = _), BackendDAE.ZERO_CROSSING(relation_ = e2, occurEquLst = _, occurWhenLst = _)) equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("- FindZeroCrossings.mergeZeroCrossing failed for " +& ExpressionDump.printExpStr(e1) +& " and "  +& ExpressionDump.printExpStr(e2) +& "\n");
    then fail();
  end matchcontinue;
end mergeZeroCrossing;

protected function getMinZeroCrossings "
  Return the expression with lower index in relation of zero-crossings."
  input DAE.Exp inZCexp1;
  input DAE.Exp inZCexp2;
  output DAE.Exp outMinZC;
algorithm
  outMinZC :=
  matchcontinue (inZCexp1, inZCexp2)
    local
      DAE.Exp e1, e2, e3, e4, res, res2;
      DAE.Operator op;
      Integer index1, index2;
      Boolean b;

    case (e1 as DAE.RELATION(index=index1), e2 as DAE.RELATION(index=index2)) equation
      b = intLe(index1, index2);
      res = if b then e1 else e2;
    then res;

    case (DAE.LUNARY(operator = op, exp = e1), DAE.LUNARY(exp = e2)) equation
      res = getMinZeroCrossings(e1, e2);
    then DAE.LUNARY(op, res);

    case (DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2), DAE.LBINARY(exp1 = e3, exp2 = e4)) equation
      res = getMinZeroCrossings(e1, e2);
      res2 = getMinZeroCrossings(e3, e4);
    then DAE.LBINARY(res, op, res2);

    case (e1, e2) equation
      true = Flags.isSet(Flags.FAILTRACE);
      Debug.traceln("- FindZeroCrossings.getMinZeroCrossings failed for " +& ExpressionDump.printExpStr(e1) +& " and "  +& ExpressionDump.printExpStr(e2) +& "\n");
    then fail();
  end matchcontinue;
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
  input BackendDAE.Variables inKnvars;
  output tuple<list<DAE.Statement>, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplStmtTypeA;
algorithm
  (outTplStmtTypeA) := match(inStmts, inExtraArg, inKnvars)
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
      list<tuple<DAE.ComponentRef, Absyn.Info>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case ({}, _, _)
    then (({}, inExtraArg));

    case ((DAE.STMT_ASSIGN(type_=tp, exp1=e2, exp=e, source=source)::xs), _, _) equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (e_2, extraArg) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_ASSIGN(tp, e_2, e_1, source)::xs_1, extraArg));

    case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp, expExpLst = expl1, exp = e, source = source)::xs), _, _) equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (expl2, extraArg) = Expression.traverseExpListTopDown(expl1, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_TUPLE_ASSIGN(tp, expl2, e_1, source)::xs_1, extraArg));

    case ((DAE.STMT_ASSIGN_ARR(type_ = tp, componentRef = cr, exp = e, source = source)::xs), _, _) equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      (DAE.CREF(cr_1, _), _, extraArg) = collectZCAlgsFor(Expression.crefExp(cr), extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_ASSIGN_ARR(tp, cr_1, e_1, source)::xs_1, extraArg));

    case (((x as DAE.STMT_ASSIGN_ARR(type_ = tp, componentRef = cr, exp = e, source = source))::xs), _, _) equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      failure((DAE.CREF(_, _), _, _) = collectZCAlgsFor(Expression.crefExp(cr), extraArg));
      true = Flags.isSet(Flags.FAILTRACE);
      print(DAEDump.ppStatementStr(x));
      print("Warning, not allowed to set the componentRef to a expression in FindZeroCrossings.traverseStmtsExps for ZeroCrosssing\n");
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_ASSIGN_ARR(tp, cr, e_1, source)::xs_1, extraArg));

    case (((DAE.STMT_IF(exp=e, statementLst=stmts, else_ = algElse, source = source))::xs), _, _) equation
      ((algElse, extraArg)) = traverseStmtsElseExps(algElse, inExtraArg, inKnvars);
      ((stmts2, extraArg)) = traverseStmtsExps(stmts, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_IF(e_1, stmts2, algElse, source)::xs_1, extraArg));

    case (((DAE.STMT_FOR(type_=tp, iterIsArray=b1, iter=id1, index=ix, range=e, statementLst=stmts, source = source))::xs), _, _) equation
      cr = ComponentReference.makeCrefIdent(id1, tp, {});
      iteratorExp = Expression.crefExp(cr);
      iteratorexps = BackendDAECreate.extendRange(e, inKnvars);
      (stmts2, extraArg) = traverseStmtsForExps(iteratorExp, iteratorexps, e, stmts, inKnvars, inExtraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_FOR(tp, b1, id1, ix, e, stmts2, source)::xs_1, extraArg));

    case (((DAE.STMT_PARFOR(type_=tp, iterIsArray=b1, iter=id1, index=ix, range=e, statementLst=stmts, loopPrlVars= loopPrlVars, source = source))::xs), _, _) equation
      cr = ComponentReference.makeCrefIdent(id1, tp, {});
      iteratorExp = Expression.crefExp(cr);
      iteratorexps = BackendDAECreate.extendRange(e, inKnvars);
      (stmts2, extraArg) = traverseStmtsForExps(iteratorExp, iteratorexps, e, stmts, inKnvars, inExtraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_PARFOR(tp, b1, id1, ix, e, stmts2, loopPrlVars, source)::xs_1, extraArg));

    case (((DAE.STMT_WHILE(exp = e, statementLst=stmts, source = source))::xs), _, _) equation
      ((stmts2, extraArg)) = traverseStmtsExps(stmts, inExtraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_WHILE(e_1, stmts2, source)::xs_1, extraArg));

    case (((DAE.STMT_WHEN(exp=e, conditions=conditions, initialCall=initialCall, statementLst=stmts, elseWhen=NONE(), source = source))::xs), _, _) equation
      /* wbraun: statemenents inside when equations can't contain zero-crossings*/
      /*((stmts2, extraArg)) = traverseStmtsExps(stmts, extraArg, inKnvars);*/
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_WHEN(e_1, conditions, initialCall, stmts, NONE(), source)::xs_1, extraArg));

    case (((DAE.STMT_WHEN(exp=e, conditions=conditions, initialCall=initialCall, statementLst=stmts, elseWhen=SOME(ew), source = source))::xs), _, _) equation
      (({ew_1}, extraArg)) = traverseStmtsExps({ew}, inExtraArg, inKnvars);
      /* wbraun: statemenents inside when equations can't contain zero-crossings*/
      /*((stmts2, extraArg)) = traverseStmtsExps(stmts, extraArg, inKnvars);*/
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_WHEN(e_1, conditions, initialCall, stmts, SOME(ew_1), source)::xs_1, extraArg));

    case (((x as DAE.STMT_ASSERT(cond=_))::xs), _, _) equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    case (((x as DAE.STMT_TERMINATE(msg=_))::xs), _, _) equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    case (((x as DAE.STMT_REINIT(var=_))::xs), _, _) equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    case (((DAE.STMT_NORETCALL(exp=e, source=source))::xs), _, _) equation
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, inExtraArg);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_NORETCALL(e_1, source)::xs_1, extraArg));

    case ((x as DAE.STMT_RETURN(source=_))::xs, _, _) equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    case ((x as DAE.STMT_BREAK(source=_))::xs, _, _) equation
      ((xs_1, extraArg)) = traverseStmtsExps(xs, inExtraArg, inKnvars);
    then ((x::xs_1, extraArg));

    // MetaModelica extension. KS
    case ((DAE.STMT_FAILURE(body=stmts, source = source))::xs, _, _) equation
      ((stmts2, extraArg)) = traverseStmtsExps(stmts, inExtraArg, inKnvars);
      ((xs_1, extraArg)) = traverseStmtsExps(xs, extraArg, inKnvars);
    then ((DAE.STMT_FAILURE(stmts2, source)::xs_1, extraArg));

    case (x::_, _, _) equation
      Error.addInternalError("./Compiler/BackEnd/FindZeroCrossings.mo: function traverseStmtsExps failed: " +& DAEDump.ppStatementStr(x));
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
  outTplStmtTypeA := match(inElse, inExtraArg, inKnvars)
    local
      DAE.Exp e, e_1;
      list<DAE.Statement> st, st_1;
      DAE.Else el, el_1;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> extraArg;

    case(DAE.NOELSE(), _, _)
    then ((DAE.NOELSE(), inExtraArg));

    case(DAE.ELSEIF(e, st, el), _, _) equation
      ((el_1, extraArg)) = traverseStmtsElseExps(el, inExtraArg, inKnvars);
      ((st_1, extraArg)) = traverseStmtsExps(st, extraArg, inKnvars);
      (e_1, extraArg) = Expression.traverseExpTopDown(e, collectZCAlgsFor, extraArg);
    then ((DAE.ELSEIF(e_1, st_1, el_1), extraArg));

    case(DAE.ELSE(st), _, _) equation
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
  (outStatements, outTpl) := matchcontinue (inIteratorExp, inExplst, inRange, inStmts, inKnvars, inExtraArg)
    local
      list<DAE.Statement> statementLst;
      tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer> tpl2;
      tuple<Integer, BackendDAE.Variables, BackendDAE.Variables> tpl3;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> extraArg;

    case (_, {}, _, _, _, _)
    then (inStmts, inExtraArg);

    case (_, _, _, _, _, (_, _, _, tpl2, tpl3)) equation
      ((statementLst, extraArg)) = traverseStmtsExps(inStmts, (inIteratorExp, inExplst, inRange, tpl2, tpl3), inKnvars);
    then (statementLst, extraArg);

    else equation
      Error.addInternalError("./Compiler/BackEnd/FindZeroCrossings.mo: function traverseStmtsForExps failed");
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
  outZeroCrossing := match(inRelation, inOccurEquLst, inOccurWhenLst)
    case (_, {-1}, _)
    then BackendDAE.ZERO_CROSSING(inRelation, {}, inOccurWhenLst);

    case (_, _, {-1})
    then BackendDAE.ZERO_CROSSING(inRelation, inOccurEquLst, {});

    else BackendDAE.ZERO_CROSSING(inRelation, inOccurEquLst, inOccurWhenLst);
  end match;
end createZeroCrossing;

annotation(__OpenModelica_Interface="backend");
end FindZeroCrossings;

/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
public import Env;

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
protected
  BackendDAE.BackendDAE dae;
  list<BackendDAE.Var> vars;
algorithm
  (dae, vars) := BackendDAEUtil.mapEqSystemAndFold(inDAE, findZeroCrossings1, {});
  outDAE := findZeroCrossingsShared(dae, vars);
end findZeroCrossings;

protected function findZeroCrossingsShared "This function finds all zerocrossings in the shared part of the DAE."
  input BackendDAE.BackendDAE inDAE;
  input list<BackendDAE.Var> allvars;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.Variables vars, knvars, exobj, av;
  BackendDAE.EquationArray remeqns, inieqns;
  list<DAE.Constraint> constrs;
  list<DAE.ClassAttributes> clsAttrs;
  BackendDAE.EventInfo einfo, einfo1;
  BackendDAE.ExternalObjectClasses eoc;
  list<BackendDAE.TimeEvent> timeEvents;
  list<BackendDAE.WhenClause> whenclauses;
  list<BackendDAE.Equation> eqs_lst, eqs_lst1;
  list<BackendDAE.ZeroCrossing> zero_crossings;
  list<BackendDAE.ZeroCrossing> relationsLst, sampleLst;
  Integer countRelations, countMathFunctions;
  BackendDAE.BackendDAEType btp;
  DAE.FunctionTree funcs;
  BackendDAE.SymbolicJacobians symjacs;
  Env.Cache cache;
  Env.Env env;
  BackendDAE.EqSystems systs;
  BackendDAE.ExtraInfo ei;
algorithm
  BackendDAE.DAE(systs, BackendDAE.SHARED(knvars, exobj, av, inieqns, remeqns, constrs, clsAttrs, 
    cache, env, funcs, einfo as BackendDAE.EVENT_INFO(timeEvents=timeEvents, zeroCrossingLst=zero_crossings, relationsLst=relationsLst, 
    sampleLst=sampleLst, whenClauseLst=whenclauses, relationsNumber=countRelations, 
    numberMathEvents=countMathFunctions), eoc, btp, symjacs, ei)) := inDAE;
          
  vars := BackendVariable.listVar1(allvars);
  eqs_lst := BackendEquation.equationList(remeqns);
  (zero_crossings, eqs_lst1, whenclauses, countRelations, countMathFunctions, relationsLst, sampleLst) := findZeroCrossings2(vars, knvars, eqs_lst, 0, whenclauses, 0, countRelations, countMathFunctions, zero_crossings, relationsLst, sampleLst, {}, {});
  eqs_lst1 := listReverse(eqs_lst1);
  remeqns := BackendEquation.listEquation(eqs_lst1);
  eqs_lst := BackendEquation.equationList(inieqns);
  (zero_crossings, eqs_lst1, _, countRelations, countMathFunctions, relationsLst, sampleLst) := findZeroCrossings2(vars, knvars, eqs_lst, 0, {}, 0, countRelations, countMathFunctions, zero_crossings, relationsLst, sampleLst, {}, {});
  eqs_lst1 := listReverse(eqs_lst1);
  inieqns := BackendEquation.listEquation(eqs_lst1);
  Debug.fcall(Flags.RELIDX, print, "findZeroCrossings1 sample index: " +& intString(listLength(sampleLst)) +& "\n");
  einfo1 := BackendDAE.EVENT_INFO(timeEvents, whenclauses, zero_crossings, sampleLst, relationsLst, countRelations, countMathFunctions);
  outDAE := BackendDAE.DAE(systs, BackendDAE.SHARED(knvars, exobj, av, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo1, eoc, btp, symjacs, ei));
end findZeroCrossingsShared;

protected function findZeroCrossings1 "This function finds all zerocrossings in the list of equations and
  the list of when clauses."
  input BackendDAE.EqSystem syst;
  input tuple<BackendDAE.Shared, list<BackendDAE.Var>> shared;
  output BackendDAE.EqSystem osyst;
  output tuple<BackendDAE.Shared, list<BackendDAE.Var>> oshared;
protected
  list<BackendDAE.Var> allvars;
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
  Env.Cache cache;
  Env.Env env;
  BackendDAE.StateSets stateSets;
  BackendDAE.ExtraInfo ei;
algorithm
  BackendDAE.EQSYSTEM(vars, eqns, m, mT, matching, stateSets) := syst;
  (BackendDAE.SHARED(knvars, exobj, av, inieqns, remeqns, constrs, clsAttrs, 
    cache, env, funcs, einfo as BackendDAE.EVENT_INFO(timeEvents=timeEvents, zeroCrossingLst=zero_crossings, 
    sampleLst=sampleLst, whenClauseLst=whenclauses, relationsLst=relations, 
    relationsNumber=countRelations, numberMathEvents=countMathFunctions), 
    eoc, btp, symjacs, ei), allvars) := shared;
          
  eqs_lst := BackendEquation.equationList(eqns);
  (zero_crossings, eqs_lst1, _, countRelations, countMathFunctions, relations, sampleLst) := findZeroCrossings2(vars, knvars, eqs_lst, 0, {}, 0, countRelations, countMathFunctions, zero_crossings, relations, sampleLst, {}, {});
  eqs_lst1 := listReverse(eqs_lst1);
  Debug.fcall(Flags.RELIDX, print, "findZeroCrossings1 number of relations : " +& intString(countRelations) +& "\n");
  Debug.fcall(Flags.RELIDX, print, "findZeroCrossings1 sample index: " +& intString(listLength(sampleLst)) +& "\n");
  eqns1 := BackendEquation.listEquation(eqs_lst1);
  einfo1 := BackendDAE.EVENT_INFO(timeEvents, whenclauses, zero_crossings, sampleLst, relations, countRelations, countMathFunctions);
  allvars := listAppend(allvars, BackendVariable.varList(vars));
  osyst := BackendDAE.EQSYSTEM(vars, eqns1, m, mT, matching, stateSets);
  oshared := (BackendDAE.SHARED(knvars, exobj, av, inieqns, remeqns, constrs, clsAttrs, cache, env, funcs, einfo1, eoc, btp, symjacs, ei), allvars);
end findZeroCrossings1;

protected function findZeroCrossings2 "
  Helper function to find_zero_crossing.
  modified: 2011-01 by wbraun
"
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

    case (_, _, {}, _, {}, _, countRelations, countMathFunctions, res, relationsLst, sampleLst, _, _) then (res, inEquationLstAccum, inWhenClauseAccum, countRelations, countMathFunctions, relationsLst, sampleLst);

    // all algorithm stmts are processed firstly
   case (v, _, ((BackendDAE.ALGORITHM(size=size, alg=DAE.ALGORITHM_STMTS(stmts), source= source_, expand=expand))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        eq_count = eq_count + 1;
        ((stmts_1, (_, _, _, (res, relationsLst, sampleLst, countRelations, countMathFunctions), (_, _, _)))) = traverseStmtsExps(stmts, collectZCAlgs, (DAE.RCONST(0.0), {}, DAE.RCONST(0.0), (zcs, relationsLst, sampleLst, countRelations, countMathFunctions), (eq_count, v, knvars)), knvars);
        eqnsAccum = listAppend({BackendDAE.ALGORITHM(size, DAE.ALGORITHM_STMTS(stmts_1), source_, expand)}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // then all when clauses are processed
    case (v, _, el, eq_count, ((BackendDAE.WHEN_CLAUSE(condition = daeExp, reinitStmtLst=whenOperations , elseClause = elseClause_ ))::xsWhen), wc_count, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        Debug.fcall(Flags.RELIDX, BackendDump.debugStrExpStr, ("processed when clause: ", daeExp, "\n"));
        wc_count = wc_count + 1;
        (eres1, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(daeExp, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, -1, wc_count, v, knvars);
        whenClauseAccum = listAppend({BackendDAE.WHEN_CLAUSE(eres1, whenOperations, elseClause_)}, whenClauseAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, el, eq_count, xsWhen, wc_count, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // check when equation condition
    case (v, _, ((BackendDAE.WHEN_EQUATION(size=size, whenEquation=weqn, source= source_))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        eq_count = eq_count + 1;
        (weqn, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossingsWhenEqns(weqn, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
        eqnsAccum = listAppend({BackendDAE.WHEN_EQUATION(size, weqn, source_)}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    // after all algorithms and when clauses are processed, all equations are processed
    case (v, _, ((BackendDAE.EQUATION(exp = e1, scalar = e2, source= source_, differentiated=diffed))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        eq_count = eq_count + 1;
        (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
        (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
         eqnsAccum = listAppend({BackendDAE.EQUATION(eres1, eres2, source_, diffed)}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case (v, _, ((BackendDAE.COMPLEX_EQUATION(size=size, left=e1, right=e2, source=source, differentiated=diffed))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        eq_count = eq_count + 1;
        (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
        (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
         eqnsAccum = listAppend({BackendDAE.COMPLEX_EQUATION(size, eres1, eres2, source, diffed)}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

    case (v, _, ((BackendDAE.ARRAY_EQUATION(dimSize=dimsize, left=e1, right=e2, source=source, differentiated=diffed))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        eq_count = eq_count + 1;
        (eres1, countRelations, countMathFunctions, zcs1, relationsLst, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
        (eres2, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e2, zcs1, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
         eqnsAccum = listAppend({BackendDAE.ARRAY_EQUATION(dimsize, eres1, eres2, source, diffed)}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

        
    case (v, _, ((BackendDAE.SOLVED_EQUATION(componentRef = cref, exp = e1, source= source_, differentiated=diffed))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        (eres1, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
         eqnsAccum = listAppend({BackendDAE.SOLVED_EQUATION(cref, eres1, source_, diffed)}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);

        
    case (v, _, ((BackendDAE.RESIDUAL_EQUATION(exp = e1, source= source_, differentiated=diffed))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        eq_count = eq_count + 1;
        (eres1, countRelations, countMathFunctions, relationsLst, res, sampleLst) = findZeroCrossings3(e1, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
         eqnsAccum = listAppend({BackendDAE.RESIDUAL_EQUATION(eres1, source_, diffed)}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);


    case (v, _, ((e as BackendDAE.IF_EQUATION(conditions=_))::xs), eq_count, {}, _, countRelations, countMathFunctions, zcs, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        eq_count = eq_count + 1;
        (e, countRelations, countMathFunctions, res, relationsLst, sampleLst) = findZeroCrossingsIfEqns(e, zcs, relationsLst, sampleLst, countRelations, countMathFunctions, eq_count, -1, v, knvars);
        eqnsAccum = listAppend({e}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);


    // let when equation pass they are discrete and can't contain ZeroCrossings
    case (v, _, (e::xs), eq_count, {}, _, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum)
      equation
        eq_count = eq_count + 1;
        eqnsAccum = listAppend({e}, eqnsAccum);
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst) = findZeroCrossings2(v, knvars, xs, eq_count, {}, 0, countRelations, countMathFunctions, res, relationsLst, sampleLst, eqnsAccum, whenClauseAccum);
      then
        (res1, eq_reslst, wc_reslst, countRelations, countMathFunctions, relationsLst, sampleLst);
   end match;
end findZeroCrossings2;

protected function findZeroCrossingsWhenEqns
"Helper function to findZeroCrossing."
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
    case (BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e, elsewhenPart=NONE()), _, _, _, _, _, _, _, _, _)
      equation
        Debug.fcall(Flags.RELIDX, BackendDump.debugStrExpStr, ("processed when condition: ", cond, "\n"));
        (cond, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossings3(cond, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars);
      then
        (BackendDAE.WHEN_EQ(cond, cr, e, NONE()), countRelations, countMathFunctions, zc, relations, samples);
    case (BackendDAE.WHEN_EQ(condition=cond, left=cr, right=e, elsewhenPart=SOME(we)), _, _, _, _, _, _, _, _, _)
      equation
        (we, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossingsWhenEqns(we, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars);
        (cond, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossings3(cond, zc, relations, samples, countRelations, countMathFunctions, counteq, countwc, vars, knvars);
      then
        (BackendDAE.WHEN_EQ(cond, cr, e, SOME(we)), countRelations, countMathFunctions, zc, relations, samples);
  end match;
end findZeroCrossingsWhenEqns;

protected function findZeroCrossingsIfEqns
"Helper function to findZeroCrossing."
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
    case (BackendDAE.IF_EQUATION(conditions={}, eqnstrue={}, eqnsfalse=elseeqns, source=source_), _, _, _, _, _, _, _, _, _)
      equation
        (zc, elseeqns, _, countRelations, countMathFunctions, relations, samples) = findZeroCrossings2(vars, knvars, elseeqns, counteq, {}, countwc, incountRelations, incountMathFunctions, inZeroCrossings, inrelationsinZC, inSamplesLst, {}, {});
        elseeqns = listReverse(elseeqns);
      then
        (BackendDAE.IF_EQUATION({}, {}, elseeqns, source_), countRelations, countMathFunctions, zc, relations, samples);
    case (BackendDAE.IF_EQUATION(conditions=condition::restconditions, eqnstrue=eqnstrue::resteqns, eqnsfalse=elseeqns, source=source_), _, _, _, _, _, _, _, _, _)
      equation
        (condition, countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossings3(condition, inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions, counteq, countwc, vars, knvars);
        (zc, eqnstrue, _, countRelations, countMathFunctions, relations, samples) = findZeroCrossings2(vars, knvars, eqnstrue, counteq, {}, countwc, countRelations, countMathFunctions, zc, relations, samples, {}, {});
        eqnstrue = listReverse(eqnstrue);
        ifeqn = BackendDAE.IF_EQUATION(restconditions, resteqns, elseeqns, source_);
        (BackendDAE.IF_EQUATION(conditions=conditions, eqnstrue=eqnsTrueLst, eqnsfalse=elseeqns, source=source_), countRelations, countMathFunctions, zc, relations, samples) = findZeroCrossingsIfEqns(ifeqn, zc, relations, samples, countRelations, countMathFunctions, counteq, countwc, vars, knvars);
        conditions = listAppend({condition}, conditions);
        eqnsTrueLst = listAppend({eqnstrue}, eqnsTrueLst);
      then
        (BackendDAE.IF_EQUATION(conditions, eqnsTrueLst, elseeqns, source_), countRelations, countMathFunctions, zc, relations, samples);
  end match;
end findZeroCrossingsIfEqns;

protected function findZeroCrossings3
"Helper function to findZeroCrossing."
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
  Debug.fcall(Flags.RELIDX, BackendDump.debugStrExpStr, ("start: ", e, "\n"));
  ((eres, ((outZeroCrossings, outrelationsinZC, outSamplesLst, outcountRelations, outcountMathFunctions), (_, _, _, _))))
   := Expression.traverseExpTopDown(e, collectZC, ((inZeroCrossings, inrelationsinZC, inSamplesLst, incountRelations, incountMathFunctions), (counteq, countwc, vars, knvars)));
end findZeroCrossings3;

protected function collectZC "author: unknown
  modified: 2011-01 by wbraun
  Collects zero crossings in equations"
  input tuple<DAE.Exp, tuple<tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, Integer, BackendDAE.Variables, BackendDAE.Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, Boolean, tuple<tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      DAE.Exp e, e1, e2, e_1, e_2, eres, eres1;
      BackendDAE.Variables vars, knvars;
      list<BackendDAE.ZeroCrossing> zeroCrossings, zc_lst, relations, samples;
      DAE.Operator op;
      Integer eq_count, wc_count, itmp, numRelations, numRelations1, numMathFunctions;
      BackendDAE.ZeroCrossing zc;
      DAE.CallAttributes attr;
      DAE.Type ty;

    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
    then ((e, false, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "smooth"))), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
    then ((e, false, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
        zc_lst = makeZeroCrossings({e}, {eq_count}, {wc_count});
        samples = listAppend(samples, zc_lst);
        samples = mergeZeroCrossings(samples);
        //itmp = (listLength(zc_lst)-listLength(zeroCrossings));
        //indx = indx + (listLength(zc_lst) - listLength(zeroCrossings));
        Debug.fcall(Flags.RELIDX, print, "sample index: " +& intString(listLength(samples)) +& "\n");
      then ((e, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    // function with discrete expressions generate no zerocrossing
    case (((e as DAE.LUNARY(operator = _, exp = e1)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        Debug.fcall(Flags.RELIDX, print, "discrete LUNARY: " +& intString(numRelations) +& "\n");
        //Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
      then
        ((e, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    case (((e as DAE.LBINARY(exp1 = e1, operator = _, exp2 = e2)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
        Debug.fcall(Flags.RELIDX, print, "discrete LBINARY: " +& intString(numRelations) +& "\n");
        //Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
      then
        ((e, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    // coditions that are zerocrossings.
    case (((e as DAE.LUNARY(exp = e1, operator = op)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
        Debug.fcall(Flags.RELIDX, print, "continues LUNARY: " +& intString(numRelations) +& "\n");
        ((e1, ((_, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)))) = Expression.traverseExpTopDown(e1, collectZC, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));
        e_1 = DAE.LUNARY(op, e1);
        {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
        zc_lst = List.select1(zeroCrossings, sameZeroCrossing, zc);
        zeroCrossings = Util.if_(List.isEmpty(zc_lst), listAppend(zeroCrossings, {zc}), zeroCrossings);
        Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e_1, "\n"));
      then
        ((e, false, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    case (((e as DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
        Debug.fcall(Flags.RELIDX, print, "continues LBINARY: " +& intString(numRelations) +& "\n");
        Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
        ((e_1, ((_, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars)))) = Expression.traverseExpTopDown(e1, collectZC, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)));
        ((e_2, ((_, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars)))) = Expression.traverseExpTopDown(e2, collectZC, ((zeroCrossings, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars)));
        true = intGt(numRelations1, numRelations);
        e_1 = DAE.LBINARY(e_1, op, e_2);
        {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
        zc_lst = List.select1(zeroCrossings, sameZeroCrossing, zc);
        zeroCrossings = Util.if_(List.isEmpty(zc_lst), listAppend(zeroCrossings, {zc}), zeroCrossings);
        print(Debug.fcallret1(Flags.RELIDX, BackendDump.zeroCrossingListString, zeroCrossings, ""));
      then
        ((e_1, false, ((zeroCrossings, relations, samples, numRelations1, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    // function with discrete expressions generate no zerocrossing
    case (((e as DAE.RELATION(exp1 = e1, operator = _, exp2 = e2)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
        Debug.fcall(Flags.RELIDX, print, "discrete RELATION: " +& intString(numRelations) +& "\n");
      then
        ((e, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    // All other functions generate zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1, operator = op, exp2 = e2)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numRelations: " +& intString(numRelations) +& "\n");
         e_1 = DAE.RELATION(e1, op, e2, numRelations, NONE());
         {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
         ((eres, relations, numRelations)) = zerocrossingindex(e_1, numRelations, relations, zc);
         {zc} = makeZeroCrossings({eres}, {eq_count}, {wc_count});
         ((DAE.RELATION(index=itmp), zeroCrossings, _)) = zerocrossingindex(eres, numRelations, zeroCrossings, zc);
         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& " index: " +& intString(itmp) +& "\n");
      then ((eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    // math function that triggering events
    case (((e as DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1}, attr=attr)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("integer"), {e1, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    case (((e as DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1}, attr=attr)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("floor"), {e1, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    case (((e as DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1}, attr=attr)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("ceil"), {e1, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    case (((e as DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2}, attr=attr)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((eres, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    /* mod is rewritten to x-floor(x/y)*y */
    case ((e as DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("floor"), {DAE.BINARY(e1, DAE.DIV(ty), e2), DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);
         e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((e_2, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    /* rem is rewritten to div(x/y)*y - x */
    case ((e as DAE.CALL(path=Absyn.IDENT("rem"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);
         e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((e_2, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
    case ((e, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars)))) then ((e, true, ((zeroCrossings, relations, samples, numRelations, numMathFunctions), (eq_count, wc_count, vars, knvars))));
  end matchcontinue;
end collectZC;

protected function collectZCAlgs "
  Collects zero crossings in algorithms stamts, beside for loops those are
  processed by collectZCAlgsFor

  modified: 2011-01 by wbraun
"
  input tuple<DAE.Exp, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      DAE.Exp e, e1, e2, e_1, e_2, eres, eres1, iterator, range;
      list<DAE.Exp> le;
      BackendDAE.Variables vars, knvars;
      list<BackendDAE.ZeroCrossing> zeroCrossings, zc_lst, relations, samples;
      DAE.Operator op;
      Integer numRelations, alg_indx, itmp, numRelations1, numMathFunctions, i;
      BackendDAE.ZeroCrossing zc;
      DAE.CallAttributes attr;
      DAE.Type ty;

    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
    then ((e, false, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "smooth"))), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
    then ((e, false, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        zc_lst = makeZeroCrossings({e}, {alg_indx}, {});
        samples = listAppend(samples, zc_lst);
        samples = mergeZeroCrossings(samples);
       // Debug.fcall(Flags.RELIDX, print, "sample index algotihm: " +& intString(indx) +& "\n");
      then ((e, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.LUNARY(operator = _, exp = e1)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        //Debug.fcall(Flags.RELIDX, print, "discrete LUNARY: " +& intString(indx) +& "\n");
        //Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
      then
        ((e, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.LBINARY(exp1 = e1, operator = _, exp2 = e2)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
        //Debug.fcall(Flags.RELIDX, print, "discrete LBINARY: " +& intString(numRelations) +& "\n");
        //Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
      then
        ((e, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    // coditions that are zerocrossings.
    case (((e as DAE.LUNARY(exp = e1, operator = op)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        Debug.fcall(Flags.RELIDX, print, "continues LUNARY: " +& intString(numRelations) +& "\n");
        ((e1, (iterator, le, range, (_, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e1, collectZCAlgs, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
        e_1 = DAE.LUNARY(op, e1);
        {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
        zc_lst = List.select1(zeroCrossings, sameZeroCrossing, zc);
        zeroCrossings = Util.if_(List.isEmpty(zc_lst), listAppend(zeroCrossings, {zc}), zeroCrossings);
        Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e_1, "\n"));
      then
        ((e, false, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        Debug.fcall(Flags.RELIDX, print, "continues LBINARY: " +& intString(numRelations) +& "\n");
        Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
        ((e_1, (iterator, le, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e1, collectZCAlgs, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
        ((e_2, (iterator, le, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e2, collectZCAlgs, (iterator, le, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));
        true = intGt(numRelations1, numRelations);
        e_1 = DAE.LBINARY(e_1, op, e_2);
        {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
        zc_lst = List.select1(zeroCrossings, sameZeroCrossing, zc);
        zeroCrossings = Util.if_(List.isEmpty(zc_lst), listAppend(zeroCrossings, {zc}), zeroCrossings);
        print(Debug.fcallret1(Flags.RELIDX, BackendDump.zeroCrossingListString, zeroCrossings, ""));
      then
        ((e_1, false, (iterator, le, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))));
    // function with discrete expressions generate no zerocrossing
    case (((e as DAE.RELATION(exp1 = e1, operator = _, exp2 = e2)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
      then ((e, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    // All other functions generate zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1, operator = op, exp2 = e2)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
       Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numRelations: " +& intString(numRelations) +& "\n");
       e_1 = DAE.RELATION(e1, op, e2, numRelations, NONE());
       {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
       ((eres, relations, numRelations)) = zerocrossingindex(e_1, numRelations, relations, zc);
       {zc} = makeZeroCrossings({eres}, {alg_indx}, {});
       ((DAE.RELATION(index=_), zeroCrossings, _)) = zerocrossingindex(eres, numRelations, zeroCrossings, zc);
       Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& " index: " +& intString(numRelations) +& "\n");
      then ((eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    // math function that triggering events
    case (((e as DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1}, attr=attr)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("integer"), {e1, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1}, attr=attr)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("floor"), {e1, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1}, attr=attr)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("ceil"), {e1, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2}, attr=attr)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((eres, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    /* mod is rewritten to x-floor(x/y)*y */
    case ((e as DAE.CALL(path=Absyn.IDENT("mod"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("floor"), {DAE.BINARY(e1, DAE.DIV(ty), e2), DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);
         e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((e_2, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    /* rem is rewritten to div(x/y)*y - x */
    case ((e as DAE.CALL(path=Absyn.IDENT("rem"), expLst={e1, e2}, attr=attr as DAE.CALL_ATTR(ty = ty)), (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
         Debug.fcall(Flags.RELIDX, print, "start collectZC : "  +& ExpressionDump.printExpStr(e) +& " numMathFunctions: " +& intString(numMathFunctions) +& "\n");

         e_1 = DAE.CALL(Absyn.IDENT("div"), {e1, e2, DAE.ICONST(numMathFunctions)}, attr);

         {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
         ((eres, zeroCrossings, numMathFunctions)) = zerocrossingindex(e_1, numMathFunctions, zeroCrossings, zc);
         e_2 = DAE.BINARY(e1, DAE.SUB(ty), DAE.BINARY(eres, DAE.MUL(ty), e2));

         Debug.fcall(Flags.RELIDX, print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres) +& "\n");
      then ((e_2, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case ((e, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      then ((e, true, (iterator, le, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
  end matchcontinue;
end collectZCAlgs;

/* TODO: implement math functions support here */
protected function collectZCAlgsFor "Collects zero crossings in for loops
  added: 2011-01 by wbraun"
  input tuple<DAE.Exp, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
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

    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
    then ((e, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "smooth"))), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
    then ((e, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        eqs = {alg_indx};
        zc_lst = makeZeroCrossings({e}, eqs, {});
        samples = listAppend(samples, zc_lst);
        samples = mergeZeroCrossings(samples);
        Debug.fcall(Flags.RELIDX, print, "collectZCAlgsFor sample" +& "\n");
      then ((e, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.LUNARY(operator = _, exp = e1)), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        //Debug.fcall(Flags.RELIDX, print, "discrete LUNARY: " +& intString(indx) +& "\n");
        //Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
      then
        ((e, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.LBINARY(exp1 = e1, operator = _, exp2 = e2)), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
        //Debug.fcall(Flags.RELIDX, print, "discrete LBINARY: " +& intString(numRelations) +& "\n");
        //Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
      then
        ((e, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    // coditions that are zerocrossings.
    case (((e as DAE.LUNARY(exp = e1, operator = op)), (iterator, inExpLst, range as DAE.RANGE(start=_, step=_), (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        Debug.fcall(Flags.RELIDX, print, "continues LUNARY: " +& intString(numRelations) +& "\n");
        true = Expression.expContains(e, iterator);
        ((e1, (iterator, inExpLst, range2, (_, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
        e_1 = DAE.LUNARY(op, e1);
        (explst, itmp) = replaceIteratorwithStaticValues(e_1, iterator, inExpLst, numRelations);
        zc_lst = makeZeroCrossings(explst, {alg_indx}, {});
        zc_lst = listAppend(zeroCrossings, zc_lst);
        zc_lst = mergeZeroCrossings(zc_lst);
        itmp = (listLength(zc_lst)-listLength(zeroCrossings));
        zeroCrossings = Util.if_(itmp>0, zc_lst, zeroCrossings);
        Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e_1, "\n"));
      then
        ((e_1, false, (iterator, inExpLst, range2, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    // coditions that are zerocrossings.
    case (((DAE.LUNARY(exp = e1, operator = op)), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        Debug.fcall(Flags.RELIDX, print, "continues LUNARY: " +& intString(numRelations) +& "\n");
        ((e1, (iterator, inExpLst, range, (_, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
        e_1 = DAE.LUNARY(op, e1);
        {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
        zc_lst = List.select1(zeroCrossings, sameZeroCrossing, zc);
        zeroCrossings = Util.if_(List.isEmpty(zc_lst), listAppend(zeroCrossings, {zc}), zeroCrossings);
        Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e_1, "\n"));
      then
        ((e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2)), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        Debug.fcall(Flags.RELIDX, print, "continues LBINARY: " +& intString(numRelations) +& "\n");
        Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
        b1 = Expression.expContains(e1, iterator);
        b2 = Expression.expContains(e2, iterator);
        true = Util.boolOrList({b1, b2});
        ((e_1, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
        ((e_2, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));
        true = intGt(numRelations1, numRelations);
        e_1 = DAE.LBINARY(e_1, op, e_2);
        (explst, itmp) = replaceIteratorwithStaticValues(e_1, iterator, inExpLst, numRelations1);
        zc_lst = makeZeroCrossings(explst, {alg_indx}, {});
        zc_lst = listAppend(zeroCrossings, zc_lst);
        zc_lst = mergeZeroCrossings(zc_lst);
        itmp = (listLength(zc_lst)-listLength(zeroCrossings));
        zeroCrossings = Util.if_(itmp>0, zc_lst, zeroCrossings);
        print(Debug.fcallret1(Flags.RELIDX, BackendDump.zeroCrossingListString, zeroCrossings, ""));
      then
        ((e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))));
    case (((e as DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2)), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        Debug.fcall(Flags.RELIDX, print, "continues LBINARY: " +& intString(numRelations) +& "\n");
        Debug.fcall(Flags.RELIDX, BackendDump.debugExpStr, (e, "\n"));
        ((e_1, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e1, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars)));
        ((e_2, (iterator, inExpLst, range, (_, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)))) = Expression.traverseExpTopDown(e2, collectZCAlgsFor, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars)));
        true = intGt(numRelations1, numRelations);
        e_1 = DAE.LBINARY(e_1, op, e_2);
        {zc} = makeZeroCrossings({e_1}, {alg_indx}, {});
        zc_lst = List.select1(zeroCrossings, sameZeroCrossing, zc);
        zeroCrossings = Util.if_(List.isEmpty(zc_lst), listAppend(zeroCrossings, {zc}), zeroCrossings);
        print(Debug.fcallret1(Flags.RELIDX, BackendDump.zeroCrossingListString, zeroCrossings, ""));
      then
        ((e_1, false, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations1, numMathFunctions), (alg_indx, vars, knvars))));
    // function with discrete expressions generate no zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1, operator = _, exp2 = e2)), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars, knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars, knvars);
      then ((e, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    // All other functions generate zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1, operator = op, exp2 = e2)), (iterator, inExpLst, range as DAE.RANGE(start=startvalue, step=stepvalueopt), (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        b1 = Expression.expContains(e1, iterator);
        b2 = Expression.expContains(e2, iterator);
        true = Util.boolOrList({b1, b2});
        Debug.fcall(Flags.RELIDX, print, " number of relations : " +& intString(numRelations) +& "\n");
        stepvalue = Util.getOptionOrDefault(stepvalueopt, DAE.ICONST(1));
        istart = BackendDAECreate.expInt(startvalue, knvars);
        istep = BackendDAECreate.expInt(stepvalue, knvars);
        e_1 = DAE.RELATION(e1, op, e2, numRelations, SOME((iterator, istart, istep)));
        (explst, itmp) = replaceIteratorwithStaticValues(e, iterator, inExpLst, numRelations);
        Debug.fcall(Flags.RELIDX, print, " number of new zc : " +& intString(listLength(explst)) +& "\n");
        zcLstNew = makeZeroCrossings(explst, {alg_indx}, {});
        zc_lst = listAppend(relations, zcLstNew);
        zc_lst = mergeZeroCrossings(zc_lst);
        Debug.fcall(Flags.RELIDX, print, " number of new zc : " +& intString(listLength(zc_lst)) +& "\n");
        itmp = (listLength(zc_lst)-listLength(relations));
        Debug.fcall(Flags.RELIDX, print, " itmp : " +& intString(itmp) +& "\n");
        numRelations = intAdd(itmp, numRelations);
        eres = Util.if_((itmp>0), e_1, e);
        zeroCrossings = listAppend(zeroCrossings, zcLstNew);
        zeroCrossings = mergeZeroCrossings(zeroCrossings);
        Debug.fcall(Flags.RELIDX, print, "collectZCAlgsFor result zc : "  +& ExpressionDump.printExpStr(eres)+& " index:"  +& intString(numRelations) +& "\n");
      then ((eres, true, (iterator, inExpLst, range, (zeroCrossings, zc_lst, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    // All other functions generate zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1, operator = op, exp2 = e2)), (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      equation
        b1 = Expression.expContains(e1, iterator);
        b2 = Expression.expContains(e2, iterator);
        false = Util.boolOrList({b1, b2});
        e_1 = DAE.RELATION(e1, op, e2, numRelations, NONE());
        zcLstNew = makeZeroCrossings({e_1}, {alg_indx}, {});
        zc_lst = listAppend(relations, zcLstNew);
        zc_lst = mergeZeroCrossings(zc_lst);
        itmp = (listLength(zc_lst)-listLength(relations));
        numRelations = numRelations + itmp;
        eres = Util.if_((itmp>0), e_1, e);
        zeroCrossings = listAppend(zeroCrossings, zcLstNew);
        zeroCrossings = mergeZeroCrossings(zeroCrossings);
        Debug.fcall(Flags.RELIDX, print, "collectZCAlgsFor result zc : "  +& ExpressionDump.printExpStr(eres)+& " index:"  +& intString(numRelations) +& "\n");
      then ((eres, true, (iterator, inExpLst, range, (zeroCrossings, zc_lst, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
    case ((e, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))))
      then ((e, true, (iterator, inExpLst, range, (zeroCrossings, relations, samples, numRelations, numMathFunctions), (alg_indx, vars, knvars))));
  end matchcontinue;
end collectZCAlgsFor;

protected function replaceIteratorwithStaticValues
" Helper function for collectZCAlgFor "
  input DAE.Exp inExp;
  input DAE.Exp inIterator;
  input list<DAE.Exp> inExpLst;
  input Integer inIndex;
  output list<DAE.Exp> outZeroCrossings;
  output Integer outIndex;
algorithm
  (outZeroCrossings, outIndex) := matchcontinue(inExp, inIterator, inExpLst, inIndex)
    local
      DAE.Exp e, e1, e2, i, exp, res1, e_1;
      DAE.Operator op;
      list<DAE.Exp> rest, res2;
      Integer index;
    case (_, _, {}, _) then ({}, inIndex);
    case (exp as DAE.RELATION(exp1 = e1, operator = op, exp2 = e2), i, e::rest, index)
      equation
        e_1 = DAE.RELATION(e1, op, e2, index, NONE());
        ((res1, (_, _))) = Expression.replaceExpTpl((e_1, (i, e)));
        (res2, index) = replaceIteratorwithStaticValues(exp, i, rest, index+1);
        res2 = listAppend({res1}, res2);
      then (res2, index);
    case (exp as DAE.LUNARY(exp = e1, operator = op), i, e::rest, index)
      equation
        e_1 = DAE.LUNARY(op, e1);
        ((res1, (_, _))) = Expression.replaceExpTpl((e_1, (i, e)));
        (res2, index) = replaceIteratorwithStaticValues(exp, i, rest, index+1);
        res2 = listAppend({res1}, res2);
      then (res2, index);
    case (exp as DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2), i, e::rest, index)
      equation
        e_1 = DAE.LBINARY(e1, op, e2);
        ((res1, (_, _))) = Expression.replaceExpTpl((e_1, (i, e)));
        (res2, index) = replaceIteratorwithStaticValues(exp, i, rest, index+1);
        res2 = listAppend({res1}, res2);
      then (res2, index);
    case (_, _, _, _)
      equation
        print("FindZeroCrossings.replaceIteratorwithStaticValues failed \n");
      then
        fail();
  end matchcontinue;
end replaceIteratorwithStaticValues;

protected function zerocrossingindex
  input DAE.Exp exp;
  input Integer index;
  input list<BackendDAE.ZeroCrossing> zeroCrossings;
  input BackendDAE.ZeroCrossing zc;
  output tuple<DAE.Exp, list<BackendDAE.ZeroCrossing>, Integer> out_exp;
algorithm
  out_exp := matchcontinue (exp, index, zeroCrossings, /*inputzeroinfo, */zc)
    local
      DAE.Exp e_1, e1, e2;
      DAE.Operator op;
      list<BackendDAE.ZeroCrossing> newzero, zc_lst;
      BackendDAE.ZeroCrossing z_c;
      String str;
    case ((DAE.RELATION(exp1 = _, operator = _, exp2 = _)), _, _, z_c)
      equation
        {} = List.select1(zeroCrossings, sameZeroCrossing, z_c/*zc1*/);
        zc_lst = listAppend(zeroCrossings, {z_c});
        //Debug.fcall(Flags.RELIDX, print, " zerocrossingindex 1 : "  +& ExpressionDump.printExpStr(exp) +& " index: " +& intString(index) +& "\n");
      then
         ((exp, zc_lst, index+1));
    case ((DAE.RELATION(exp1 = _, operator = _, exp2 = _)), _, _, z_c)
      equation
        newzero = List.select1(zeroCrossings, sameZeroCrossing, z_c);
        BackendDAE.ZERO_CROSSING(e_1, _, _)=List.first(newzero);
        //length=listLength(newzero);
        //Debug.fcall(Flags.RELIDX, print, " zerocrossingindex 2: results "  +& ExpressionDump.printExpStr(e_1)+& "index: " +& intString(indx) +& " lenght: " +& intString(length) +& "\n");
      then
        ((e_1, zeroCrossings, index));
    /* math function with one argument and index */
    case ((e_1 as DAE.CALL(path=_, expLst={_, _})), _, _, z_c)
      equation
        {} = List.select1(zeroCrossings, sameZeroCrossing, z_c/*zc1*/);
        zc_lst = listAppend(zeroCrossings, {z_c});
      then
        ((e_1, zc_lst, index+1));
    case (DAE.CALL(path=_, expLst={_, _}), _, _, z_c)
      equation
        newzero = List.select1(zeroCrossings, sameZeroCrossing, z_c);
        BackendDAE.ZERO_CROSSING(e_1, _, _)=List.first(newzero);
      then
        ((e_1, zeroCrossings, index));
    /* math function with two arguments and index */
    case ((e_1 as DAE.CALL(path=_, expLst={_, _, _})), _, _, z_c)
      equation
        {} = List.select1(zeroCrossings, sameZeroCrossing, z_c/*zc1*/);
        zc_lst = listAppend(zeroCrossings, {z_c});
      then
        ((e_1, zc_lst, index+2));
    case (DAE.CALL(path=_, expLst={_, _, _}), _, _, z_c)
      equation
        newzero = List.select1(zeroCrossings, sameZeroCrossing, z_c);
        BackendDAE.ZERO_CROSSING(e_1, _, _)=List.first(newzero);
      then
        ((e_1, zeroCrossings, index));
    else
      equation
        str = " failure in zerocrossingindex for: "  +& ExpressionDump.printExpStr(exp);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();

   end matchcontinue;
end zerocrossingindex;

protected function mergeZeroCrossings
"Takes a list of zero crossings and if more than one have identical
  function expressions they are merged into one zerocrossing.
  In the resulting list all zerocrossing have uniq function expressions."
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst:=
  matchcontinue (inZeroCrossingLst)
    local
      BackendDAE.ZeroCrossing zc, same_1;
      list<BackendDAE.ZeroCrossing> samezc, diff, diff_1, xs;
    case {} then {};
    case {zc} then {zc};
    case (zc::xs)
      equation
        (samezc, diff) = List.split1OnTrue(xs, sameZeroCrossing, zc);
        diff_1 = mergeZeroCrossings(diff);
        same_1 = List.fold(samezc, mergeZeroCrossing, zc);
      then
        (same_1::diff_1);
  end matchcontinue;
end mergeZeroCrossings;

protected function mergeZeroCrossing "
  Merges two zero crossings into one by makeing the union of the lists of
  equaions and when clauses they appear in.
  modified: 2011-01 by wbraun
  merge to ZeroCrosssing with the lowest index
"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing:=
  matchcontinue (inZeroCrossing1, inZeroCrossing2)
    local
      list<Integer> eq, wc, eq1, wc1, eq2, wc2;
      DAE.Exp e1, e2;
      Integer index1, index2;
    case (BackendDAE.ZERO_CROSSING(relation_ = e1 as DAE.RELATION(index=index1), occurEquLst = eq1, occurWhenLst = wc1), BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(index=index2), occurEquLst = eq2, occurWhenLst = wc2))
      equation
        true = intLt(index1, index2);
        eq = List.union(eq1, eq2);
        wc = List.union(wc1, wc2);
      then
        BackendDAE.ZERO_CROSSING(e1, eq, wc);
    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(index=_), occurEquLst = eq1, occurWhenLst = wc1), BackendDAE.ZERO_CROSSING(relation_ = e2 as DAE.RELATION(index=_), occurEquLst = eq2, occurWhenLst = wc2))
      equation
        eq = List.union(eq1, eq2);
        wc = List.union(wc1, wc2);
      then BackendDAE.ZERO_CROSSING(e2, eq, wc);
    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(index=_), occurEquLst = _, occurWhenLst = _), BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(index=_), occurEquLst = _, occurWhenLst = _))
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- FindZeroCrossings.mergeZeroCrossing failed!");
      then
        fail();
  end matchcontinue;
end mergeZeroCrossing;

protected function sameZeroCrossing "
  Returns true if both zero crossings have the same function expression
"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inZeroCrossing1, inZeroCrossing2)
    local
      Boolean res, res2;
      DAE.Exp e1, e2, e3, e4;
    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path=Absyn.IDENT("integer"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path=Absyn.IDENT("integer"), expLst={e2, _})))
      equation
        res = Expression.expEqual(e1, e2);
      then res;
    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path=Absyn.IDENT("floor"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path=Absyn.IDENT("floor"), expLst={e2, _})))
      equation
        res = Expression.expEqual(e1, e2);
      then res;
    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e1, _})), BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path=Absyn.IDENT("ceil"), expLst={e2, _})))
      equation
        res = Expression.expEqual(e1, e2);
      then res;
    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path=Absyn.IDENT("div"), expLst={e1, e2, _})), BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path=Absyn.IDENT("div"), expLst={e3, e4, _})))
      equation
        res = Expression.expEqual(e1, e3);
        res2 = Expression.expEqual(e2, e4);
      then (res and res2);
    case (BackendDAE.ZERO_CROSSING(relation_ = e1), BackendDAE.ZERO_CROSSING(relation_ = e2))
      equation
        res = Expression.expEqual(e1, e2);
      then res;
  end match;
end sameZeroCrossing;

protected function traverseStmtsExps "Handles the traversing of list<DAE.Statement>.
  Works with the help of Expression.traverseExpTopDown to find
  ZeroCrossings in algorithm statements
  modified: 2011-01 by wbraun"
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> iextraArg;
  input BackendDAE.Variables knvars;
  output tuple<list<DAE.Statement>, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplStmtTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> arg;
    output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> oarg;
  end FuncExpType;
algorithm
  (outTplStmtTypeA) := match(inStmts, func, iextraArg, knvars)
    local
      DAE.Exp e_1, e_2, e, e2, iteratorExp;
      Integer ix;
      list<DAE.Exp> expl1, expl2, iteratorexps;
      DAE.ComponentRef cr_1, cr;
      list<DAE.Statement> xs_1, xs, stmts, stmts2;
      DAE.Type tp;
      DAE.Statement x, ew, ew_1;
      Boolean b1;
      String id1, str;
      DAE.ElementSource source;
      DAE.Else algElse;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> extraArg;
      list<tuple<DAE.ComponentRef, Absyn.Info>> loopPrlVars "list of parallel variables used/referenced in the parfor loop";
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;

    case ({}, _, extraArg, _) then (({}, extraArg));

    case ((DAE.STMT_ASSIGN(type_ = tp, exp1 = e2, exp = e, source = source)::xs), _, extraArg, _)
      equation
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((e_2, extraArg)) = Expression.traverseExpTopDown(e2, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_ASSIGN(tp, e_2, e_1, source)::xs_1, extraArg));

    case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp, expExpLst = expl1, exp = e, source = source)::xs), _, extraArg, _)
      equation
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((expl2, extraArg)) = Expression.traverseExpListTopDown(expl1, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_TUPLE_ASSIGN(tp, expl2, e_1, source)::xs_1, extraArg));

    case ((DAE.STMT_ASSIGN_ARR(type_ = tp, componentRef = cr, exp = e, source = source)::xs), _, extraArg, _)
      equation
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((DAE.CREF(cr_1, _), _, extraArg)) = func((Expression.crefExp(cr), extraArg));
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_ASSIGN_ARR(tp, cr_1, e_1, source)::xs_1, extraArg));

    case (((x as DAE.STMT_ASSIGN_ARR(type_ = tp, componentRef = cr, exp = e, source = source))::xs), _, extraArg, _)
      equation
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        failure(((DAE.CREF(_, _), _, _)) = func((Expression.crefExp(cr), extraArg)));
        true = Flags.isSet(Flags.FAILTRACE);
        print(DAEDump.ppStatementStr(x));
        print("Warning, not allowed to set the componentRef to a expression in FindZeroCrossings.traverseStmtsExps for ZeroCrosssing\n");
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_ASSIGN_ARR(tp, cr, e_1, source)::xs_1, extraArg));

    case (((DAE.STMT_IF(exp=e, statementLst=stmts, else_ = algElse, source = source))::xs), _, extraArg, _)
      equation
        ((algElse, extraArg)) = traverseStmtsElseExps(algElse, func, extraArg, knvars);
        ((stmts2, extraArg)) = traverseStmtsExps(stmts, func, extraArg, knvars);
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_IF(e_1, stmts2, algElse, source)::xs_1, extraArg));

    case (((DAE.STMT_FOR(type_=tp, iterIsArray=b1, iter=id1, index=ix, range=e, statementLst=stmts, source = source))::xs), _, extraArg, _)
      equation
        cr = ComponentReference.makeCrefIdent(id1, tp, {});
        iteratorExp = Expression.crefExp(cr);
        iteratorexps = BackendDAECreate.extendRange(e, knvars);
        ((stmts2, extraArg)) = traverseStmtsForExps(iteratorExp, iteratorexps, e, stmts, knvars, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_FOR(tp, b1, id1, ix, e, stmts2, source)::xs_1, extraArg));

    case (((DAE.STMT_PARFOR(type_=tp, iterIsArray=b1, iter=id1, index=ix, range=e, statementLst=stmts, loopPrlVars= loopPrlVars, source = source))::xs), _, extraArg, _)
      equation
        cr = ComponentReference.makeCrefIdent(id1, tp, {});
        iteratorExp = Expression.crefExp(cr);
        iteratorexps = BackendDAECreate.extendRange(e, knvars);
        ((stmts2, extraArg)) = traverseStmtsForExps(iteratorExp, iteratorexps, e, stmts, knvars, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_PARFOR(tp, b1, id1, ix, e, stmts2, loopPrlVars, source)::xs_1, extraArg));

    case (((DAE.STMT_WHILE(exp = e, statementLst=stmts, source = source))::xs), _, extraArg, _)
      equation
        ((stmts2, extraArg)) = traverseStmtsExps(stmts, func, extraArg, knvars);
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_WHILE(e_1, stmts2, source)::xs_1, extraArg));

    case (((DAE.STMT_WHEN(exp=e, conditions=conditions, initialCall=initialCall, statementLst=stmts, elseWhen=NONE(), source = source))::xs), _, extraArg, _)
      equation
        /* wbraun: statemenents inside when equations can't contain zero-crossings*/
        /*((stmts2, extraArg)) = traverseStmtsExps(stmts, func, extraArg, knvars);*/
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_WHEN(e_1, conditions, initialCall, stmts, NONE(), source)::xs_1, extraArg));

    case (((DAE.STMT_WHEN(exp=e, conditions=conditions, initialCall=initialCall, statementLst=stmts, elseWhen=SOME(ew), source = source))::xs), _, extraArg, _)
      equation
        (({ew_1}, extraArg)) = traverseStmtsExps({ew}, func, extraArg, knvars);
        /* wbraun: statemenents inside when equations can't contain zero-crossings*/
        /*((stmts2, extraArg)) = traverseStmtsExps(stmts, func, extraArg, knvars);*/
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_WHEN(e_1, conditions, initialCall, stmts, SOME(ew_1), source)::xs_1, extraArg));

    case (((x as DAE.STMT_ASSERT(cond = _, msg=_, source = source))::xs), _, extraArg, _)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x::xs_1, extraArg));

    case (((x as DAE.STMT_TERMINATE(msg = _, source = source))::xs), _, extraArg, _)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x::xs_1, extraArg));

    case (((x as DAE.STMT_REINIT(var = _, value=_, source = source))::xs), _, extraArg, _)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x::xs_1, extraArg));

    case (((DAE.STMT_NORETCALL(exp = e, source = source))::xs), _, extraArg, _)
      equation
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_NORETCALL(e_1, source)::xs_1, extraArg));

    case (((x as DAE.STMT_RETURN(source = source))::xs), _, extraArg, _)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x::xs_1, extraArg));

    case (((x as DAE.STMT_BREAK(source = source))::xs), _, extraArg, _)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x::xs_1, extraArg));

        // MetaModelica extension. KS
    case (((DAE.STMT_FAILURE(body=stmts, source = source))::xs), _, extraArg, _)
      equation
        ((stmts2, extraArg)) = traverseStmtsExps(stmts, func, extraArg, knvars);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_FAILURE(stmts2, source)::xs_1, extraArg));

    case ((x::_), _, _, _)
      equation
        str = DAEDump.ppStatementStr(x);
        str = "Algorithm.traverseStmtsExps not implemented correctly: " +& str;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end traverseStmtsExps;

protected function traverseStmtsElseExps "author: BZ, 2008-12
  modified: 2011-01 by wbraun
  Helper function for traverseStmtsExps to find ZeroCrosssings in algorithm 
  else statements."
  input DAE.Else inElse;
  input FuncExpType func;
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> iextraArg;
  input BackendDAE.Variables knvars;
  output tuple<DAE.Else, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplStmtTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> arg;
    output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> oarg;
  end FuncExpType;
algorithm
  outTplStmtTypeA := match(inElse, func, iextraArg, knvars)
    local
      DAE.Exp e, e_1;
      list<DAE.Statement> st, st_1;
      DAE.Else el, el_1;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> extraArg;

    case(DAE.NOELSE(), _, extraArg, _) then ((DAE.NOELSE(), extraArg));
    case(DAE.ELSEIF(e, st, el), _, extraArg, _)
      equation
        ((el_1, extraArg)) = traverseStmtsElseExps(el, func, extraArg, knvars);
        ((st_1, extraArg)) = traverseStmtsExps(st, func, extraArg, knvars);
        ((e_1, extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
      then ((DAE.ELSEIF(e_1, st_1, el_1), extraArg));
    case(DAE.ELSE(st), _, extraArg, _)
      equation
        ((st_1, extraArg)) = traverseStmtsExps(st, func, extraArg, knvars);
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
  input BackendDAE.Variables knvars;
  input FuncExpType func;
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> iextraArg;
  output tuple<list<DAE.Statement>, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> outTplStmtTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> arg;
    output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>>> oarg;
  end FuncExpType;
algorithm
  outTplStmtTypeA := matchcontinue (inIteratorExp, inExplst, inRange, inStmts, knvars, func, iextraArg)
    local
      list<DAE.Statement> statementLst;
      DAE.Exp ie, range;
      BackendDAE.Variables v, kn;
      list<BackendDAE.ZeroCrossing> zcs, rels, samples;
      Integer idx, idx2, alg_idx;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, list<BackendDAE.ZeroCrossing>, Integer, Integer>, tuple<Integer, BackendDAE.Variables, BackendDAE.Variables>> extraArg;

    case (_, {}, _, statementLst, _, _, extraArg) then ((statementLst, extraArg));
    case (ie, _, range, statementLst, _, _, (_, _, _, (zcs, rels, samples, idx, idx2), (alg_idx, v, kn)))
      equation
        ((statementLst, extraArg )) = traverseStmtsExps(statementLst, collectZCAlgsFor, (ie, inExplst, range, (zcs, rels, samples, idx, idx2), (alg_idx, v, kn)), knvars);
      then
        ((statementLst , extraArg));
    case (_, _, _, _, _, _, _)
      equation
        print("FindZeroCrossings.traverseAlgStmtsFor failed \n");
      then
        fail();
  end matchcontinue;
end traverseStmtsForExps;

protected function makeZeroCrossings "
  Constructs a list of ZeroCrossings from a list expressions and lists of 
  equation indices and when clause indices. Each Zerocrossing gets the same 
  lists of indicies."
  input list<DAE.Exp> inExpExpLst1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst := match(inExpExpLst1, inIntegerLst2, inIntegerLst3)
    local
      BackendDAE.ZeroCrossing res;
      list<BackendDAE.ZeroCrossing> resx;
      DAE.Exp e;
      list<DAE.Exp> xs;
      list<Integer> eq_ind, wc_ind;
      
    case ({}, _, _)
    then {};
    
    case ((e::xs), {-1}, wc_ind) equation
      resx = makeZeroCrossings(xs, {}, wc_ind);
      res = BackendDAE.ZERO_CROSSING(e, {}, wc_ind);
    then (res::resx);
      
    case ((e::xs), eq_ind, {-1}) equation
      resx = makeZeroCrossings(xs, eq_ind, {});
      res = BackendDAE.ZERO_CROSSING(e, eq_ind, {});
    then (res::resx);
    
    case ((e::xs), eq_ind, wc_ind) equation
      resx = makeZeroCrossings(xs, eq_ind, wc_ind);
      res = BackendDAE.ZERO_CROSSING(e, eq_ind, wc_ind);
    then (res::resx);
  end match;
end makeZeroCrossings;

end FindZeroCrossings;


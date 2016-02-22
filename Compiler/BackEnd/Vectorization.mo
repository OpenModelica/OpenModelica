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

encapsulated package Vectorization
" file:        Vectorization.mo
  package:     Vectorization
  description: Vectorization

"
public import BackendDAE;
public import DAE;

protected import Absyn;
protected import Algorithm;
protected import BackendDump;
protected import BackendEquation;
protected import BackendVariable;
protected import BackendVarTransform;
protected import ComponentReference;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import List;
protected import Util;


//--------------------------------
// collect for-loops
//--------------------------------
public function collectForLoops"takes a list of equations and a list of vars, searches for iterated equations and array variables and constructs for-equations and ranged array vars.
author: Waurich TUD 2015-03"
  input list<BackendDAE.Var> varsIn;
  input list<BackendDAE.Equation> eqsIn;
  output list<BackendDAE.Var> varsOut;
  output list<BackendDAE.Equation> eqsOut;
protected
  Boolean cont, perfectMatching;
  Integer idx, numEqs, numVars;
  array<Integer> ass1,ass2;
  list<Integer> idxs;
  BackendDAE.EqSystem eqSys;
  BackendDAE.Shared shared;
  BackendVarTransform.VariableReplacements repl1;
  DAE.ComponentRef cref;
  DAE.Exp exp;
  list<DAE.ComponentRef> scalarCrefs,scalarCrefs1,scalarCrefs2, allScalarCrefs, stateCrefs;
  list<DAE.Exp> scalarCrefExps;
  list<BackendDAE.Equation> loopEqs;
  list<BackendDAE.Var> arrVars;
  list<Absyn.Exp> loopIds;
  list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> arrayCrefs; //headCref, range, tailcrefs
  list<BackendDAE.Var> varLst, arrayVars;
  list<BackendDAE.Equation> forEqs,mixEqs,nonArrEqs;
algorithm
    //BackendDump.dumpEquationList(eqsIn,"eqsIn");
    //BackendDump.dumpVarList(varsIn,"varsIn");
  //-------------------------------------------
  //dispatch vars and equals to different lists
  //-------------------------------------------
  //split vars in array vars and non array vars
  (varLst, arrayVars) := List.fold(varsIn, getArrayVars,({},{}));

  // get the arrayCrefs
  (arrayCrefs,_) := List.fold(arrayVars,getArrayVarCrefs,({},{}));

  // dispatch the equations in for-quations, mixedequations, non-array equations
  ((forEqs,mixEqs,nonArrEqs)) := List.fold1(eqsIn, dispatchLoopEquations,List.map(arrayCrefs,Util.tuple31),({},{},{}));
      //BackendDump.dumpEquationList(forEqs,"forEqs1");
      //BackendDump.dumpEquationList(mixEqs,"mixEqs1");
      //BackendDump.dumpEquationList(nonArrEqs,"nonArrEqs1");

  //build for equations for repeated equations
  forEqs := buildBackendDAEForEquations(forEqs,{});

  //find accumulated equations in mixEqs and insert SUM-Exp
  mixEqs := listReverse(List.fold(mixEqs,buildAccumExpInEquations,{}));
      //BackendDump.dumpEquationList(forEqs,"forEqs2");
      //BackendDump.dumpEquationList(mixEqs,"mixEqs2");
      //BackendDump.dumpEquationList(nonArrEqs,"nonArrEqs2");

  // build non-expanded arrays
  arrayVars := unexpandArrayVariables(arrayVars,{});

  eqsOut := listAppend(forEqs,listAppend(mixEqs, nonArrEqs));
  varsOut := listAppend(arrayVars,varLst);
end collectForLoops;


protected function unexpandArrayVariables"build non-expanded var arrays"
  input list<BackendDAE.Var> varsIn;
  input list<BackendDAE.Var> foldIn;
  output list<BackendDAE.Var> foldOut;
algorithm
  foldOut := matchcontinue(varsIn,foldIn)
    local
      BackendDAE.Var var;
      DAE.ComponentRef cref;
      list<DAE.BackendDAE.Var> rest, scalars;
  case({},_)
    then foldIn;
  case(var::rest,_)
    equation
      cref = BackendVariable.varCref(var);
      true = ComponentReference.crefHaveSubs(cref);
      (scalars,rest) = List.split1OnTrue(rest,varIsEqualCrefWithoutSubs,cref);
      cref = replaceFirstSubsInCref(cref,{DAE.INDEX(DAE.RANGE(BackendVariable.varType(var),DAE.ICONST(1),NONE(),DAE.ICONST(listLength(scalars)+1)))});
      var = BackendVariable.copyVarNewName(cref,var);
    then unexpandArrayVariables(rest,var::foldIn);
  case(var::rest,_)
    then unexpandArrayVariables(rest,var::foldIn);
  end matchcontinue;
end unexpandArrayVariables;

protected function varIsEqualCrefWithoutSubs"checks if a var is equal to the cref without considering the subscripts"
  input BackendDAE.Var varIn;
  input DAE.ComponentRef crefIn;
  output Boolean b;
protected
  DAE.ComponentRef cref;
algorithm
  cref := BackendVariable.varCref(varIn);
  b := ComponentReference.crefEqualWithoutSubs(cref,crefIn);
end varIsEqualCrefWithoutSubs;

protected function buildAccumExpInEquations"if there is an accumulation of array variables in an equation, check whether we can summarize these to an accumulated expression"
  input BackendDAE.Equation mixEq;
  input list<BackendDAE.Equation> foldIn;
  output list<BackendDAE.Equation> foldOut;
algorithm
  foldOut := matchcontinue(mixEq,foldIn)
    local
      DAE.Exp rhs, lhs;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
      list<DAE.Exp> allTerms;
      list<tuple<DAE.Exp,Integer,Integer>> minmaxTerms;
  case(BackendDAE.EQUATION(exp=rhs,scalar=lhs,source=source,attr=attr),_)
    algorithm
      //handle left hand side
      allTerms := Expression.allTerms(lhs);
      minmaxTerms := List.fold(allTerms,buildAccumExpInEquations1,{});
      {lhs} := buildAccumExpInEquations2(listReverse(minmaxTerms),{});

      //handle right hand side
      allTerms := Expression.allTerms(rhs);
      minmaxTerms := List.fold(allTerms,buildAccumExpInEquations1,{});
      {rhs} := buildAccumExpInEquations2(listReverse(minmaxTerms),{});
    then BackendDAE.EQUATION(rhs,lhs,source,attr)::foldIn;
  else
    then mixEq::foldIn;
  end matchcontinue;
end buildAccumExpInEquations;

protected function buildAccumExpInEquations1"checks if a term occurs multiple times among all terms, if so update min max"
  input DAE.Exp termIn;
  input list<tuple<DAE.Exp,Integer,Integer>> minmaxTermsIn;
  output list<tuple<DAE.Exp,Integer,Integer>> minmaxTermsOut;
protected
  Integer pos, idx, min, max;
  DAE.ComponentRef cref;
  DAE.Exp term;
  list<DAE.Exp> terms;
algorithm
  try
    {cref} := Expression.extractCrefsFromExp(termIn);
    true := ComponentReference.crefHaveSubs(cref);
    pos := List.position1OnTrue(minmaxTermsIn,minmaxTermEqual,termIn);
    if intEq(pos,-1) then
      // not yet collected array cref term
      {DAE.INDEX(DAE.ICONST(idx))} := ComponentReference.crefSubs(cref);
      minmaxTermsOut := (termIn,idx,idx)::minmaxTermsIn;
    else
    // an already collected array cref term
    (term,min,max) := listGet(minmaxTermsIn,pos);
    {DAE.INDEX(DAE.ICONST(idx))} := ComponentReference.crefSubs(cref);
    minmaxTermsOut := List.replaceAt((term,intMin(idx,min),intMax(idx,max)),pos,minmaxTermsIn);
    end if;
  else
    minmaxTermsOut := (termIn,-1,-1)::minmaxTermsIn;
  end try;
end buildAccumExpInEquations1;


protected function buildAccumExpInEquations2"sums up the terms and build accumulated expresssions if necessary"
  input list<tuple<DAE.Exp,Integer,Integer>> minmaxTerm;
  input list<DAE.Exp> foldIn;
  output list<DAE.Exp> foldOut;
algorithm
  foldOut := matchcontinue(minmaxTerm,foldIn)
    local
      Integer min, max;
      DAE.Exp exp0, exp1, iter;
      list<DAE.Exp> resExp;
      list<tuple<DAE.Exp,Integer,Integer>> rest;
  case({},{exp1})
    equation
    then {exp1};
  case((exp1,min,max)::rest,{})
    equation
    // build a sigma operator exp and start with the first term
    true = intNe(min,max);
    (_,rest) = List.split1OnTrue(rest,minmaxTermEqual,exp1);  // remove other instances of the term
    iter = DAE.CREF(DAE.CREF_IDENT("i",DAE.T_INTEGER_DEFAULT,{}),DAE.T_INTEGER_DEFAULT);
    (exp1,_) = Expression.traverseExpBottomUp(exp1,replaceSubscriptInCrefExp,{DAE.INDEX(iter)});
    exp1 = DAE.SUM(Expression.typeof(exp1),iter,DAE.ICONST(min),DAE.ICONST(max),exp1);
    resExp = buildAccumExpInEquations2(rest,{exp1});
    then resExp;
  case((exp1,min,max)::rest,{exp0})
    equation
    // build a sigma operator exp and add to folding expression
    true = intNe(min,max);
    (_,rest) = List.split1OnTrue(rest,minmaxTermEqual,exp1);  // remove other instances of the term
    iter = DAE.CREF(DAE.CREF_IDENT("i",DAE.T_INTEGER_DEFAULT,{}),DAE.T_INTEGER_DEFAULT);
    (exp1,_) = Expression.traverseExpBottomUp(exp1,replaceSubscriptInCrefExp,{DAE.INDEX(iter)});
    exp1 = DAE.SUM(Expression.typeof(exp1),iter,DAE.ICONST(min),DAE.ICONST(max),exp1);
    resExp = buildAccumExpInEquations2(rest,{DAE.BINARY(exp0,DAE.ADD(Expression.typeof(exp0)),exp1)});
    then resExp;
  case((exp1,_,_)::rest,{})
    equation
      // the first exp is a non-array cref
    resExp = buildAccumExpInEquations2(rest,{exp1});
    then resExp;
  case((exp1,_,_)::rest,{exp0})
    equation
      //add this non-array cref
      resExp = buildAccumExpInEquations2(rest,{DAE.BINARY(exp0,DAE.ADD(Expression.typeof(exp0)),exp1)});
    then resExp;
  end matchcontinue;
end buildAccumExpInEquations2;


public function replaceSubscriptInCrefExp"exp-traverse-function to replace the first occuring subscripts in a cref"
  input DAE.Exp expIn;
  input list<DAE.Subscript> subsIn;
  output DAE.Exp expOut;
  output list<DAE.Subscript> subsOut;
algorithm
  (expOut,subsOut) := matchcontinue(expIn,subsIn)
    local
      DAE.ComponentRef cref;
      DAE.Type ty;
  case(DAE.CREF(componentRef=cref, ty=ty),_)
    equation
      cref =  replaceFirstSubsInCref(cref,subsIn);
    then (DAE.CREF(cref,ty),subsIn);
  else
    then(expIn,subsIn);
  end matchcontinue;
end replaceSubscriptInCrefExp;



protected function minmaxTermEqual"checks if a term is equal to the minmaxTerm without considering the subscripts"
  input tuple<DAE.Exp,Integer,Integer> minmaxTerm;
  input DAE.Exp term;
  output Boolean b;
protected
  DAE.Exp term0;
algorithm
  (term0,_,_) := minmaxTerm;
  b := expEqualNoCrefSubs(term0, term);
end minmaxTermEqual;

public function equationEqualNoCrefSubs "
  Returns true if two equations are equal without considering subscripts"
  input BackendDAE.Equation e1;
  input BackendDAE.Equation e2;
  output Boolean res;
algorithm
  res := matchcontinue (e1, e2)
    local
      DAE.Exp e11, e12, e21, e22, exp1, exp2;
      DAE.ComponentRef cr1, cr2;
      DAE.Algorithm alg1, alg2;
      list<DAE.Exp> explst1, explst2, terms1,terms2,commTerms;
      list<DAE.ComponentRef> crefs1,crefs2,commCrefs;
    case (_, _) equation
      true = referenceEq(e1, e2);
    then true;
    case (BackendDAE.EQUATION(exp=e11, scalar=e12), BackendDAE.EQUATION(exp=e21, scalar=e22)) equation
      if boolAnd(expEqualNoCrefSubs(e11, e21), expEqualNoCrefSubs(e12, e22)) then
        //its completely identical
        res=true;
      else
        // at least the crefs should be equal
        crefs1 = BackendEquation.equationCrefs(e1);
        crefs2 = BackendEquation.equationCrefs(e2);
        commCrefs = List.intersectionOnTrue(crefs1,crefs2,ComponentReference.crefEqualWithoutSubs);
        if intEq(listLength(crefs1),listLength(commCrefs)) and intEq(listLength(crefs2),listLength(commCrefs)) then
          //compare terms
          terms1 = listAppend(Expression.allTerms(e11),Expression.allTerms(e12));
          terms2 = listAppend(Expression.allTerms(e21),Expression.allTerms(e22));
            //print("We have to check the terms:\n");
            //print("terms1: "+stringDelimitList(List.map(terms1,ExpressionDump.printExpStr),"| ")+"\n");
            //print("terms2: "+stringDelimitList(List.map(terms2,ExpressionDump.printExpStr),"| ")+"\n");
          (commTerms,terms1,terms2) = List.intersection1OnTrue(terms1,terms2,expEqualNoCrefSubs);
          res =  listEmpty(terms1) and listEmpty(terms2);
            //print("is it the same: "+boolString(res)+"\n");
        else
          res = false;
        end if;
      end if;
    then res;
    case (BackendDAE.ARRAY_EQUATION(left=e11, right=e12), BackendDAE.ARRAY_EQUATION(left=e21, right=e22)) equation
      res = boolAnd(expEqualNoCrefSubs(e11, e21), expEqualNoCrefSubs(e12, e22));
    then res;
    case (BackendDAE.COMPLEX_EQUATION(left=e11, right=e12), BackendDAE.COMPLEX_EQUATION(left=e21, right=e22)) equation
      res = boolAnd(expEqualNoCrefSubs(e11, e21), expEqualNoCrefSubs(e12, e22));
    then res;
    case (BackendDAE.SOLVED_EQUATION(componentRef=cr1, exp=exp1), BackendDAE.SOLVED_EQUATION(componentRef=cr2, exp=exp2)) equation
      res = boolAnd(ComponentReference.crefEqualWithoutSubs(cr1, cr2), expEqualNoCrefSubs(exp1, exp2));
    then res;
    case (BackendDAE.RESIDUAL_EQUATION(exp=exp1), BackendDAE.RESIDUAL_EQUATION(exp=exp2)) equation
      res = expEqualNoCrefSubs(exp1, exp2);
    then res;
    case (BackendDAE.ALGORITHM(alg=alg1), BackendDAE.ALGORITHM(alg=alg2)) equation
      explst1 = Algorithm.getAllExps(alg1);
      explst2 = Algorithm.getAllExps(alg2);
      res = List.isEqualOnTrue(explst1, explst2, expEqualNoCrefSubs);
    then res;
    else false;
  end matchcontinue;
end equationEqualNoCrefSubs;


public function expEqualNoCrefSubs
  "Returns true if the two expressions are equal, otherwise false."
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  output Boolean outEqual;
algorithm
  // Return true if the references are the same.
  if referenceEq(inExp1, inExp2) then
    outEqual := true;
    return;
  end if;

  // Return false if the expressions are not of the same type.
  if valueConstructor(inExp1) <> valueConstructor(inExp2) then
    outEqual := false;
    return;
  end if;

  // Otherwise, check if the expressions are equal or not.
  // Since the expressions have already been verified to be of the same type
  // above we can match on only one of them to allow the pattern matching to
  // optimize this to jump directly to the correct case.
  outEqual := match(inExp1)
    local
      Integer i;
      Real r;
      String s;
      Boolean b;
      Absyn.Path p;
      DAE.Exp e, e1, e2;
      Option<DAE.Exp> oe;
      list<DAE.Exp> expl;
      list<list<DAE.Exp>> mexpl;
      DAE.Operator op;
      DAE.ComponentRef cr;
      DAE.Type ty;

    case DAE.ICONST()
      algorithm
        DAE.ICONST(integer = i) := inExp2;
      then
        inExp1.integer == i;

    case DAE.RCONST()
      algorithm
        DAE.RCONST(real = r) := inExp2;
      then
        inExp1.real == r;

    case DAE.SCONST()
      algorithm
        DAE.SCONST(string = s) := inExp2;
      then
        inExp1.string == s;

    case DAE.BCONST()
      algorithm
        DAE.BCONST(bool = b) := inExp2;
      then
        inExp1.bool == b;

    case DAE.ENUM_LITERAL()
      algorithm
        DAE.ENUM_LITERAL(name = p) := inExp2;
      then
        Absyn.pathEqual(inExp1.name, p);

    case DAE.CREF()
      algorithm
        DAE.CREF(componentRef = cr) := inExp2;
      then
        ComponentReference.crefEqualWithoutSubs(inExp1.componentRef, cr);

    case DAE.ARRAY()
      algorithm
        DAE.ARRAY(ty = ty, array = expl) := inExp2;
      then
        valueEq(inExp1.ty, ty) and expEqualNoCrefSubsList(inExp1.array, expl);

    case DAE.MATRIX()
      algorithm
        DAE.MATRIX(ty = ty, matrix = mexpl) := inExp2;
      then
        valueEq(inExp1.ty, ty) and expEqualNoCrefSubsListList(inExp1.matrix, mexpl);

    case DAE.BINARY()
      algorithm
        DAE.BINARY(exp1 = e1, operator = op, exp2 = e2) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp1, e1) and
        expEqualNoCrefSubs(inExp1.exp2, e2);

    case DAE.LBINARY()
      algorithm
        DAE.LBINARY(exp1 = e1, operator = op, exp2 = e2) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp1, e1) and
        expEqualNoCrefSubs(inExp1.exp2, e2);

    case DAE.UNARY()
      algorithm
        DAE.UNARY(exp = e, operator = op) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.LUNARY()
      algorithm
        DAE.LUNARY(exp = e, operator = op) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.RELATION()
      algorithm
        DAE.RELATION(exp1 = e1, operator = op, exp2 = e2) := inExp2;
      then
        Expression.operatorEqual(inExp1.operator, op) and
        expEqualNoCrefSubs(inExp1.exp1, e1) and
        expEqualNoCrefSubs(inExp1.exp2, e2);

    case DAE.IFEXP()
      algorithm
        DAE.IFEXP(expCond = e, expThen = e1, expElse = e2) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.expCond, e) and
        expEqualNoCrefSubs(inExp1.expThen, e1) and
        expEqualNoCrefSubs(inExp1.expElse, e2);

    case DAE.CALL()
      algorithm
        DAE.CALL(path = p, expLst = expl) := inExp2;
      then
        Absyn.pathEqual(inExp1.path, p) and
        expEqualNoCrefSubsList(inExp1.expLst, expl);

    case DAE.RECORD()
      algorithm
        DAE.RECORD(path = p, exps = expl) := inExp2;
      then
        Absyn.pathEqual(inExp1.path, p) and
        expEqualNoCrefSubsList(inExp1.exps, expl);

    case DAE.PARTEVALFUNCTION()
      algorithm
        DAE.PARTEVALFUNCTION(path = p, expList = expl) := inExp2;
      then
        Absyn.pathEqual(inExp1.path, p) and
        expEqualNoCrefSubsList(inExp1.expList, expl);

    case DAE.RANGE()
      algorithm
        DAE.RANGE(start = e1, step = oe, stop = e2) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.start, e1) and
        expEqualNoCrefSubs(inExp1.stop, e2) and
        expEqualNoCrefSubsOpt(inExp1.step, oe);

    case DAE.TUPLE()
      algorithm
        DAE.TUPLE(PR = expl) := inExp2;
      then
        expEqualNoCrefSubsList(inExp1.PR, expl);

    case DAE.CAST()
      algorithm
        DAE.CAST(ty = ty, exp = e) := inExp2;
      then
        valueEq(inExp1.ty, ty) and expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.ASUB()
      algorithm
        DAE.ASUB(exp = e, sub = expl) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.exp, e) and expEqualNoCrefSubsList(inExp1.sub, expl);

    case DAE.SIZE()
      algorithm
        DAE.SIZE(exp = e, sz = oe) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.exp, e) and expEqualNoCrefSubsOpt(inExp1.sz, oe);

    case DAE.REDUCTION()
      // Reductions contain too much information to compare in a sane manner.
      then valueEq(inExp1, inExp2);

    case DAE.LIST()
      algorithm
        DAE.LIST(valList = expl) := inExp2;
      then
        expEqualNoCrefSubsList(inExp1.valList, expl);

    case DAE.CONS()
      algorithm
        DAE.CONS(car = e1, cdr = e2) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.car, e1) and expEqualNoCrefSubs(inExp1.cdr, e2);

    case DAE.META_TUPLE()
      algorithm
        DAE.META_TUPLE(listExp = expl) := inExp2;
      then
        expEqualNoCrefSubsList(inExp1.listExp, expl);

    case DAE.META_OPTION()
      algorithm
        DAE.META_OPTION(exp = oe) := inExp2;
      then
        expEqualNoCrefSubsOpt(inExp1.exp, oe);

    case DAE.METARECORDCALL()
      algorithm
        DAE.METARECORDCALL(path = p, args = expl) := inExp2;
      then
        Absyn.pathEqual(inExp1.path, p) and expEqualNoCrefSubsList(inExp1.args, expl);

    case DAE.MATCHEXPRESSION()
      then valueEq(inExp1, inExp2);

    case DAE.BOX()
      algorithm
        DAE.BOX(exp = e) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.UNBOX()
      algorithm
        DAE.UNBOX(exp = e) := inExp2;
      then
        expEqualNoCrefSubs(inExp1.exp, e);

    case DAE.SHARED_LITERAL()
      algorithm
        DAE.SHARED_LITERAL(index = i) := inExp2;
      then
        inExp1.index == i;

    else false;
  end match;
end expEqualNoCrefSubs;


protected function expEqualNoCrefSubsOpt
  input Option<DAE.Exp> inExp1;
  input Option<DAE.Exp> inExp2;
  output Boolean outEqual;
protected
  DAE.Exp e1, e2;
algorithm
  outEqual := match(inExp1, inExp2)
    case (NONE(), NONE()) then true;
    case (SOME(e1), SOME(e2)) then expEqualNoCrefSubs(e1, e2);
    else false;
  end match;
end expEqualNoCrefSubsOpt;


protected function expEqualNoCrefSubsList
  input list<DAE.Exp> inExpl1;
  input list<DAE.Exp> inExpl2;
  output Boolean outEqual;
protected
  DAE.Exp e2;
  list<DAE.Exp> rest_expl2 = inExpl2;
algorithm
  // Check that the lists have the same length, otherwise they can't be equal.
  if listLength(inExpl1) <> listLength(inExpl2) then
    outEqual := false;
    return;
  end if;

  for e1 in inExpl1 loop
    e2 :: rest_expl2 := rest_expl2;

    // Return false if the expressions are not equal.
    if not expEqualNoCrefSubs(e1, e2) then
      outEqual := false;
      return;
    end if;
  end for;

  outEqual := true;
end expEqualNoCrefSubsList;

protected function expEqualNoCrefSubsListList
  input list<list<DAE.Exp>> inExpl1;
  input list<list<DAE.Exp>> inExpl2;
  output Boolean outEqual;
protected
  list<DAE.Exp> expl2;
  list<list<DAE.Exp>> rest_expl2 = inExpl2;
algorithm
  // Check that the lists have the same length, otherwise they can't be equal.
  if listLength(inExpl1) <> listLength(inExpl2) then
    outEqual := false;
    return;
  end if;

  for expl1 in inExpl1 loop
    expl2 :: rest_expl2 := rest_expl2;

    // Return false if the expression lists are not equal.
    if not expEqualNoCrefSubsList(expl1, expl2) then
      outEqual := false;
      return;
    end if;
  end for;

  outEqual := true;
end expEqualNoCrefSubsListList;


protected function buildBackendDAEForEquations"creates BackendDAE.FOR_EQUATION for similar equations"
  input list<BackendDAE.Equation> classEqs;
  input list<BackendDAE.Equation> foldIn;
  output list<BackendDAE.Equation> foldOut;
algorithm
  foldOut := matchcontinue(classEqs, foldIn)
    local
      Integer min, max, numCrefs;
      BackendDAE.Equation eq;
      DAE.ComponentRef cref1,cref2;
      DAE.Exp lhs,rhs, iterator;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes attr;
      list<BackendDAE.Equation> similarEqs, rest, foldEqs;
      list<DAE.ComponentRef> crefs, crefs2;
      list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMax;
  case({},_)
    algorithm
      then foldIn;

case(eq::rest,_)
    algorithm
      //special case for a[i] = a[x]
      BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=attr) := eq;
      true := ComponentReference.crefEqualWithoutSubs(Expression.expCref(lhs),Expression.expCref(rhs));
            //print("found constant array-var\n");
      //get similar equations
      (similarEqs,rest) := List.separate1OnTrue(classEqs,equationEqualNoCrefSubs,eq);
        //BackendDump.dumpEquationList(similarEqs,"simEqs");
      cref1 := Expression.expCref(lhs);
      cref2 := Expression.expCref(rhs);
      // update crefs in equation
      iterator := DAE.CREF(DAE.CREF_IDENT("i",DAE.T_INTEGER_DEFAULT,{}),DAE.T_INTEGER_DEFAULT);
      //lhs := BackendArrayVarTransform.replaceSubExp(Expression.crefExp(cref1),DAE.INDEX(iterator));
      //rhs := BackendArrayVarTransform.replaceSubExp(Expression.crefExp(cref1),DAE.INDEX(DAE.ICONST(listLength(similarEqs)+1)));
      eq := BackendDAE.FOR_EQUATION(iterator,DAE.ICONST(1),DAE.ICONST(listLength(similarEqs)),lhs,rhs,source,attr);
        //BackendDump.dumpEquationList({eq},"got eq assignment");
      foldEqs := buildBackendDAEForEquations(rest,(eq::foldIn));
    then
      foldEqs;

  case(eq::rest,_)
    algorithm
      BackendDAE.EQUATION(exp=lhs,scalar=rhs,source=source,attr=attr) := eq;
      //get similar equations
      (similarEqs,rest) := List.separate1OnTrue(classEqs,equationEqualNoCrefSubs,eq);
        //BackendDump.dumpEquationList(similarEqs,"simEqs");
      crefs := BackendEquation.equationCrefs(eq);
      //filter array-vars that appear in every equation
      crefs2 := BackendEquation.equationCrefs(listGet(similarEqs,1));
      (crefs2,crefs,_) := List.intersection1OnTrue(crefs,crefs2,ComponentReference.crefEqual);
        //print("varCrefs: "+stringDelimitList(List.map(crefs,ComponentReference.printComponentRefStr),",")+"\n");
        //print("consCrefs: "+stringDelimitList(List.map(crefs2,ComponentReference.printComponentRefStr),",")+"\n");
      numCrefs := listLength(crefs);
      // all crefs and their minimum as well as their max iterator
      crefMinMax := List.thread3Map(listReverse(crefs),List.fill(999999999,numCrefs),List.fill(0,numCrefs),Util.make3Tuple);
      crefMinMax :=  List.fold1(similarEqs,getCrefIdcsForEquation,crefs2,crefMinMax);
      //((min,max)) := List.fold1(crefMinMax,getIterationRangesForCrefs,listLength(similarEqs),(-1,-1));
      min := 1;
      max := listLength(similarEqs);
      //print("min "+intString(min)+" max "+intString(max)+"\n");
      // update crefs in equation
      iterator := DAE.CREF(DAE.CREF_IDENT("i",DAE.T_INTEGER_DEFAULT,{}),DAE.T_INTEGER_DEFAULT);
      (BackendDAE.EQUATION(exp=lhs,scalar=rhs),_) := BackendEquation.traverseExpsOfEquation(eq,setIteratorSubscriptCrefinEquation,(crefMinMax,iterator,crefs2));
      eq := BackendDAE.FOR_EQUATION(iterator,DAE.ICONST(min),DAE.ICONST(max),lhs,rhs,source,attr);
        //BackendDump.dumpEquationList({eq},"got eq");
      foldEqs := buildBackendDAEForEquations(rest,(eq::foldIn));
    then
      foldEqs;
  else
    then foldIn;
  end matchcontinue;
end buildBackendDAEForEquations;


protected function getCrefIdcsForEquation"gets all crefs of the equation and dispatches the information about min and max subscript to crefMinMax"
  input BackendDAE.Equation eq;
  input list<DAE.ComponentRef> constCrefs;
  input list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMaxIn;
  output list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMaxOut;
algorithm
  crefMinMaxOut := matchcontinue(eq,constCrefs,crefMinMaxIn)
    local
      Integer pos,max,min,sub;
      DAE.ComponentRef cref, refCref;
      tuple<DAE.ComponentRef,Integer,Integer> refCrefMinMax;
      list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMax;
      list<DAE.ComponentRef> eqCrefs, crefs;
  case(BackendDAE.EQUATION(_),_,crefMinMax)
    algorithm
      eqCrefs := BackendEquation.equationCrefs(eq);
      //traverse all crefs of the equation
      eqCrefs := List.filter1OnTrue(eqCrefs,ComponentReference.crefNotInLst,constCrefs);
      for cref in eqCrefs loop
        {DAE.INDEX(DAE.ICONST(sub))} := ComponentReference.crefSubs(cref);
        pos := 1;
        for refCrefMinMax in crefMinMax loop
          (refCref,min,max) := refCrefMinMax;
          // if the cref fits the refCref, update min max
          if ComponentReference.crefEqualWithoutSubs(refCref,cref) then
            max := intMax(max,sub);
            min := intMin(min,sub);
            crefMinMax := List.replaceAt((refCref,min,max),pos,crefMinMax);
          end if;
          pos := pos+1;
        end for;
      end for;
    then crefMinMax;
  else
    then crefMinMaxIn;
  end matchcontinue;
end getCrefIdcsForEquation;


protected function setIteratorSubscriptCrefinEquation"traverse function that replaces crefs in the exp according to the iterated crefMinMax"
  input DAE.Exp inExp;
  input tuple<list<tuple<DAE.ComponentRef,Integer,Integer>>,DAE.Exp,list<DAE.ComponentRef>> tplIn; //creMinMax,iterator,constCrefs
  output DAE.Exp outExp;
  output tuple<list<tuple<DAE.ComponentRef,Integer,Integer>>,DAE.Exp,list<DAE.ComponentRef>> tplOut;
algorithm
  (outExp,tplOut) := matchcontinue(inExp,tplIn)
    local
      Integer min, max;
      Absyn.Path path;
      DAE.CallAttributes attr;
      DAE.ComponentRef cref, refCref;
      DAE.Exp exp1, exp2,iterator, iterator1;
      DAE.Operator op;
      DAE.Type ty;
      list<DAE.Exp> eLst;
      list<DAE.ComponentRef> constCrefs;
      tuple<DAE.ComponentRef,Integer,Integer> refCrefMinMax;
      list<tuple<DAE.ComponentRef,Integer,Integer>> crefMinMax0, crefMinMax1;

  case(DAE.CREF(componentRef=cref,ty=ty),(crefMinMax0,iterator,constCrefs))
    algorithm
      true := not List.exist1(constCrefs,ComponentReference.crefEqual,cref);//dont substitute array-vars which are constant in the for-equations
      crefMinMax1 := {};
      for refCrefMinMax in crefMinMax0 loop
        (refCref,min,max) := refCrefMinMax;
         // if the cref fits the refCref, update the iterator
        if ComponentReference.crefEqualWithoutSubs(refCref,cref) then
          iterator1 := ExpressionSimplify.simplify(DAE.BINARY(iterator,DAE.ADD(DAE.T_INTEGER_DEFAULT),DAE.ICONST(min-1)));
          cref := replaceFirstSubsInCref(cref,{DAE.INDEX(iterator1)});
        else
          // add the non used crefs to the fold list
          crefMinMax1 := refCrefMinMax::crefMinMax1;
        end if;
      end for;
    then (DAE.CREF(cref,ty),(crefMinMax1,iterator,constCrefs));

  case(DAE.BINARY(exp1=exp1,operator=op,exp2=exp2),(crefMinMax0,iterator,constCrefs))
    algorithm
      // continue traversing
      (exp1,(crefMinMax0,iterator,constCrefs))  := setIteratorSubscriptCrefinEquation(exp1,tplIn);
      (exp2,(crefMinMax0,iterator,constCrefs))  := setIteratorSubscriptCrefinEquation(exp2,(crefMinMax0,iterator,constCrefs));
    then (DAE.BINARY(exp1,op,exp2),(crefMinMax0,iterator,constCrefs));

  case(DAE.UNARY(operator=op,exp=exp1),(crefMinMax0,iterator,constCrefs))
    algorithm
      // continue traversing
      (exp1,(crefMinMax0,iterator,constCrefs))  := setIteratorSubscriptCrefinEquation(exp1,tplIn);
    then (DAE.UNARY(op,exp1),(crefMinMax0,iterator,constCrefs));

  case(DAE.CALL(path=path,expLst=eLst,attr=attr),(crefMinMax0,iterator,constCrefs))
    algorithm
      // continue traversing
      (eLst,(crefMinMax0,iterator,constCrefs))  := List.mapFold(eLst,setIteratorSubscriptCrefinEquation,tplIn);
    then (DAE.CALL(path,eLst,attr),(crefMinMax0,iterator,constCrefs));

  else
    then (inExp,tplIn);
  end matchcontinue;
end setIteratorSubscriptCrefinEquation;


protected function getArrayVarCrefs"gets the array-cref and its dimension from a var."
  input BackendDAE.Var varIn;
  input tuple<list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>>,list<BackendDAE.Var>> tplIn; //{headCref,range,tailcrefs},arrVarlst
  output tuple<list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>>,list<BackendDAE.Var>> tplOut;
algorithm
  tplOut := matchcontinue(varIn,tplIn)
    local
      Integer idx;
      list<Integer> ranges;
      list<BackendDAE.Var> arrVars;
      DAE.ComponentRef cref, crefHead, crefTail;
      Option<DAE.ComponentRef> crefTailOpt;
      list<DAE.ComponentRef> crefLst;
      list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> tplLst;
      tuple<list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>>,list<BackendDAE.Var>> tpl;
  case(BackendDAE.VAR(varName=cref),(tplLst,arrVars))
    equation
    true = ComponentReference.isArrayElement(cref);
    (crefHead,idx,crefTailOpt) = ComponentReference.stripArrayCref(cref);
    if Util.isSome(crefTailOpt) then
      crefLst = {Util.getOption(crefTailOpt)};
    else
      crefLst = {};
    end if;
    (tplLst,arrVars) = addToArrayCrefLst(tplLst,varIn,(crefHead,idx,crefLst),{},arrVars);
    tpl = (tplLst,arrVars);
  then tpl;
  else
    then tplIn;
  end matchcontinue;
end getArrayVarCrefs;


protected function addToArrayCrefLst"checks if the tplRef-cref is already in the list, if not append, if yes update index"
  input list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> tplLstIn;
  input BackendDAE.Var varIn;
  input tuple<DAE.ComponentRef, Integer,list<DAE.ComponentRef>> tplRef;
  input list<tuple<DAE.ComponentRef, Integer,list<DAE.ComponentRef>>> tplLstFoldIn;
  input list<BackendDAE.Var> varLstIn;
  output list<tuple<DAE.ComponentRef, Integer,list<DAE.ComponentRef>>> tplLstFoldOut;
  output list<BackendDAE.Var> varLstOut;
algorithm
  (tplLstFoldOut,varLstOut) := matchcontinue(tplLstIn,varIn,tplRef,tplLstFoldIn,varLstIn)
    local
      Integer idx0,idx1;
      list<BackendDAE.Var> varLst;
      DAE.ComponentRef cref0,cref1,crefTailRef;
      list<tuple<DAE.ComponentRef,Integer,list<DAE.ComponentRef>>> rest, tplLst;
      list<DAE.ComponentRef> tailCrefs0, tailCrefs1;
  case((cref0,idx0,tailCrefs0)::rest,_,(cref1,idx1,{crefTailRef}),_,_)
    equation
    // this cref already exist, update idx, append tailCrefs if necessary
    true = ComponentReference.crefEqual(cref0,cref1);
    if List.notMember(crefTailRef,tailCrefs0) then
      tailCrefs0 = crefTailRef::tailCrefs0;
      //append var with new tail
      varLst =varIn::varLstIn;
    else
      varLst = varLstIn;
    end if;
    tplLst = (cref0,intMax(idx0,idx1),tailCrefs0)::rest;
    tplLst = List.append_reverse(tplLst,tplLstFoldIn);
  then (tplLst,varLst);

  case((cref0,idx0,tailCrefs0)::rest,_,(cref1,idx1,tailCrefs1),_,_)
    equation
      // this cref is not the same, continue
    false = ComponentReference.crefEqual(cref0,cref1);
    (tplLst,varLst) = addToArrayCrefLst(rest,varIn,tplRef,(cref0,idx0,tailCrefs0)::tplLstFoldIn,varLstIn);
  then (tplLst,varLst);

  case({},_,(cref1,idx1,tailCrefs1),_,_)
    equation
      // this cref is new, append
    tplLst = (cref1,idx1,tailCrefs1)::tplLstFoldIn;
  then (tplLst,varIn::varLstIn);

  end matchcontinue;
end addToArrayCrefLst;


protected function getArrayVars
  input BackendDAE.Var varIn;
  input tuple<list<BackendDAE.Var>,list<BackendDAE.Var>> tplIn; //non-array vars,arrayVars
  output tuple<list<BackendDAE.Var>,list<BackendDAE.Var>> tplOut;
algorithm
  tplOut := matchcontinue(varIn,tplIn)
    local
      DAE.ComponentRef cref;
      list<BackendDAE.Var> varLstIn, arrVarLstIn;
  case(BackendDAE.VAR(varName=cref),(varLstIn, arrVarLstIn))
    equation
    true = ComponentReference.isArrayElement(cref);
  then(varLstIn, varIn::arrVarLstIn);
  case(_,(varLstIn, arrVarLstIn))
    equation
  then(varIn::varLstIn, arrVarLstIn);
  end matchcontinue;
end getArrayVars;

protected function dispatchLoopEquations
  input BackendDAE.Equation eqIn;
  input list<DAE.ComponentRef> arrayCrefs; //headCrefs
  input tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,list<BackendDAE.Equation>> tplIn; //classEqs,mixEqs,nonArrEqs
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,list<BackendDAE.Equation>> tplOut;//classEqs,mixEqs,nonArrEqs
algorithm
  tplOut := matchcontinue(eqIn,arrayCrefs,tplIn)
    local
      list<BackendDAE.Equation> classEqs,mixEqs,nonArrEqs;
      list<DAE.ComponentRef> crefs, arrCrefs, nonArrCrefs;
      tuple<list<BackendDAE.Equation>,list<BackendDAE.Equation>,list<BackendDAE.Equation>> tpl;
    case(_,_,(classEqs,mixEqs,nonArrEqs))
      equation
        crefs = BackendEquation.equationCrefs(eqIn);
        (arrCrefs,nonArrCrefs) = List.separate1OnTrue(crefs,crefPartlyEqualToCrefs,arrayCrefs);
        if listEmpty(nonArrCrefs) then
          classEqs = eqIn::classEqs;
        elseif listEmpty(arrCrefs) then
          nonArrEqs = eqIn::nonArrEqs;
        else
          mixEqs = eqIn::mixEqs;
        end if;
      then (classEqs,mixEqs,nonArrEqs);
  end matchcontinue;
end dispatchLoopEquations;


protected function crefPartlyEqualToCrefs
  input DAE.ComponentRef cref0;
  input list<DAE.ComponentRef> crefLst;
  output Boolean b;
algorithm
  b := List.exist1(crefLst,crefPartlyEqual,cref0);
end crefPartlyEqualToCrefs;

protected function crefPartlyEqual
  input DAE.ComponentRef cref0;
  input DAE.ComponentRef cref1;
  output Boolean partlyEq;
algorithm
  partlyEq := matchcontinue(cref0,cref1)
    local
      Boolean b;
      DAE.ComponentRef cref01, cref11;
  case(DAE.CREF_IDENT(), DAE.CREF_IDENT())
      then cref0.ident ==cref1.ident;
  case(DAE.CREF_QUAL(componentRef=cref01), DAE.CREF_QUAL(componentRef=cref11))
    equation
      if cref0.ident ==cref1.ident then b = crefPartlyEqual(cref01,cref11);
      else  b = false;
      end if;
    then b;
  case(DAE.CREF_QUAL(), DAE.CREF_IDENT())
      then cref0.ident ==cref1.ident;
  case(DAE.CREF_IDENT(), DAE.CREF_QUAL())
      then cref0.ident ==cref1.ident;
  else
    then false;
  end matchcontinue;
end crefPartlyEqual;

public function reduceLoopExpressions "strip the higher indexes in accumulated iterations"
  input DAE.Exp expIn;
  input Integer maxSub;
  output DAE.Exp expOut;
  output Boolean notRemoved;
algorithm
  (expOut,notRemoved) := matchcontinue(expIn,maxSub)
    local
      Boolean b, b1, b2;
      DAE.ComponentRef cref;
      DAE.Exp exp, exp1, exp2;
      DAE.Type ty;
      DAE.Operator op;
  case(DAE.CREF(componentRef=cref),_)
    equation
      b = intLe(getIndexSubScript(listHead(ComponentReference.crefSubs(cref))),maxSub);
        //print("crerfsub: "+intString(getIndexSubScript(listHead(ComponentReference.crefSubs(cref))))+" <> "+intString(maxSub)+"\n");
        //print("reduce cref: "+ComponentReference.crefStr(cref)+" is higher sub: "+boolString(b)+"\n");
  then (expIn,b);

  case(DAE.BINARY(exp1=exp1, operator=op, exp2=exp2),_)
    equation
      (exp1,b1) = reduceLoopExpressions(exp1,maxSub);
      (exp2,b2) = reduceLoopExpressions(exp2,maxSub);
        //print("exp: "+ExpressionDump.printExpStr(expIn)+" b1: "+boolString(b1)+" b2: "+boolString(b2)+"\n");
      if b1 and not b2 then
        exp = exp1;
      elseif b2 and not b1 then
        exp = exp2;
      else
        exp = DAE.BINARY(exp1,op,exp2);
      end if;
        //print("expOut: "+ExpressionDump.printExpStr(exp)+"\n");
  then (exp,boolOr(b1,b2));

  case(DAE.UNARY(operator=op, exp=exp),_)
    equation
      (exp,b) = reduceLoopExpressions(exp,maxSub);
  then (exp,b);
   else
     equation
         //print("else: "+ExpressionDump.dumpExpStr(expIn,0)+"\n");
     then (expIn,true);
  end matchcontinue;
end reduceLoopExpressions;

public function insertSUMexp "exp traversal function for insertSUMexp"
  input DAE.Exp expIn;
  input tuple<DAE.ComponentRef, DAE.Exp> tplIn; //<to be replaced, replace with>
  output DAE.Exp expOut;
  output tuple<DAE.ComponentRef, DAE.Exp> tplOut;
algorithm
  (expOut,tplOut) := matchcontinue(expIn,tplIn)
    local
      DAE.ComponentRef cref0,cref1;
      DAE.Exp repl, exp1, exp2;
      DAE.Operator op;
   case(DAE.BINARY(exp1=exp1, operator=op,exp2=exp2),(cref0,repl))
     equation
       (exp1,_) = insertSUMexp(exp1,tplIn);
       (exp2,_) = insertSUMexp(exp2,tplIn);
     then(DAE.BINARY(exp1,op,exp2),tplIn);
   case(DAE.UNARY(operator=op,exp=exp1),(cref0,repl))
     equation
       (exp1,_) = insertSUMexp(exp1,tplIn);
     then(DAE.UNARY(op,exp1),tplIn);
   case(DAE.CREF(componentRef=cref1),(cref0,repl))
     equation
       true = crefPartlyEqual(cref0,cref1);
     then(repl,tplIn);
   else
     then (expIn,tplIn);
   end matchcontinue;
end insertSUMexp;

protected function getIndexSubScript
  input DAE.Subscript sub;
  output Integer int;
algorithm
  DAE.INDEX(DAE.ICONST(int)) := sub;
end getIndexSubScript;

public function replaceFirstSubsInCref"replaces the first occuring subscript in the cref"
  input DAE.ComponentRef crefIn;
  input list<DAE.Subscript> subs;
  output DAE.ComponentRef crefOut;
algorithm
  crefOut := matchcontinue(crefIn,subs)
    local
      DAE.Ident ident;
      DAE.Type identType;
      list<DAE.Subscript> subscriptLst;
      DAE.ComponentRef cref;
  case(DAE.CREF_QUAL(ident=ident, identType=identType, subscriptLst=subscriptLst, componentRef=cref),_)
    equation
      if List.hasOneElement(subscriptLst) then  subscriptLst = subs; end if;
      cref = replaceFirstSubsInCref(cref,subs);
    then DAE.CREF_QUAL(ident, identType, subscriptLst, cref);
  case(DAE.CREF_IDENT(ident=ident, identType=identType, subscriptLst=subscriptLst),_)
    equation
      if List.hasOneElement(subscriptLst) then  subscriptLst = subs; end if;
    then DAE.CREF_IDENT(ident, identType, subscriptLst);
  else
    then crefIn;
  end matchcontinue;
end replaceFirstSubsInCref;

annotation(__OpenModelica_Interface="backend");
end Vectorization;

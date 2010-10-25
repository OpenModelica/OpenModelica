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

package BackendDAETransform
" file:         BackendDAETransform.mo
  package:     BackendDAETransform
  description:  This file contains all functions for transforming the DAE structure 
                to the BackendDAE. 
"

public import Absyn;
public import BackendDAE;
public import ComponentReference;
public import DAE;
public import DAELow;
public import SCode;
public import Values;


protected import Algorithm;
protected import BackendDump;
protected import BackendVarTransform;
protected import ClassInf;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Env;
protected import Error;
protected import Exp;
protected import OptManager;
protected import RTOpts;
protected import Util;
protected import DAEDump;
protected import Inline;
protected import BackendDAEUtil;


public function lower
"function: lower
  This function translates a DAE, which is the result from instantiating a
  class, into a more precise form, called BackendDAE.DAELow defined in this module.
  The BackendDAE.DAELow representation splits the DAE into equations and variables
  and further divides variables into known and unknown variables and the
  equations into simple and nonsimple equations.
  The variables are inserted into a hash table. This gives a lookup cost of
  O(1) for finding a variable. The equations are put in an expandable
  array. Where adding a new equation can be done in O(1) time if space
  is available.
  inputs:  daeList: DAE.DAElist, simplify: bool)
  outputs: BackendDAE.DAELow"
  input DAE.DAElist lst;
  input DAE.FunctionTree functionTree;
  input Boolean addDummyDerivativeIfNeeded;
  input Boolean simplify;
//  input Boolean removeTrivEqs "temporal input, for legacy purposes; doesn't add trivial equations to removed equations";
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue(lst, functionTree, addDummyDerivativeIfNeeded, simplify)
    local
      BackendDAE.BinTree s;
      BackendDAE.Variables vars,knvars,vars_1,extVars;
      BackendDAE.AliasVariables aliasVars "hash table with alias vars' replacements (a=b or a=-b)";
      list<BackendDAE.Equation> eqns,reqns,ieqns,algeqns,multidimeqns,imultidimeqns,eqns_1;
      list<BackendDAE.MultiDimEquation> aeqns,aeqns1,iaeqns;
      list<DAE.Algorithm> algs,algs_1;
      list<BackendDAE.WhenClause> whenclauses,whenclauses_1;
      list<BackendDAE.ZeroCrossing> zero_crossings;
      BackendDAE.EquationArray eqnarr,reqnarr,ieqnarr;
      array<BackendDAE.MultiDimEquation> arr_md_eqns;
      array<DAE.Algorithm> algarr;
      BackendDAE.ExternalObjectClasses extObjCls;
      Boolean daeContainsNoStates, shouldAddDummyDerivative;
      BackendDAE.EventInfo einfo;
      DAE.FunctionTree funcs;
      list<DAE.Element> elems;

    case(lst, functionTree, addDummyDerivativeIfNeeded, true) // simplify by default
      equation
        (DAE.DAE(elems),functionTree) = processDelayExpressions(lst,functionTree);
        s = BackendDAEUtil.states(elems, BackendDAE.emptyBintree);
        vars = BackendDAEUtil.emptyVars();
        knvars = BackendDAEUtil.emptyVars();
        extVars = BackendDAEUtil.emptyVars();
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses,extObjCls,s) = lower2(elems, functionTree, s, vars, knvars, extVars, {});

        daeContainsNoStates = hasNoStates(s); // check if the DAE has states
        // adrpo: add the dummy derivative state ONLY IF the DAE contains
        //        no states AND ONLY if addDummyDerivative is set to true!
        shouldAddDummyDerivative =  boolAnd(addDummyDerivativeIfNeeded, daeContainsNoStates);
        (vars,eqns) = addDummyState(vars, eqns, shouldAddDummyDerivative);

        whenclauses_1 = listReverse(whenclauses);
        algeqns = lowerAlgorithms(vars, algs);
        (multidimeqns,imultidimeqns) = lowerMultidimeqns(vars, aeqns, iaeqns);
        eqns = listAppend(algeqns, eqns);
        eqns = listAppend(multidimeqns, eqns);
        ieqns = listAppend(imultidimeqns, ieqns);
        aeqns = listAppend(aeqns,iaeqns);
        (vars,knvars,eqns,reqns,ieqns,aeqns1,algs_1,aliasVars) = DAELow.removeSimpleEquations(vars, knvars, eqns, reqns, ieqns, aeqns, algs, s);
        vars_1 = detectImplicitDiscrete(vars, eqns);
        eqns_1 = sortEqn(eqns);
        (eqns_1,ieqns,aeqns1,algs,vars_1) = expandDerOperator(vars_1,eqns_1,ieqns,aeqns1,algs_1,functionTree);
        (zero_crossings) = findZeroCrossings(vars_1,knvars,eqns_1,aeqns1,whenclauses_1,algs);
        eqnarr = BackendDAEUtil.listEquation(eqns_1);
        reqnarr = BackendDAEUtil.listEquation(reqns);
        ieqnarr = BackendDAEUtil.listEquation(ieqns);
        arr_md_eqns = listArray(aeqns1);
        algarr = listArray(algs);
        einfo = Inline.inlineEventInfo(BackendDAE.EVENT_INFO(whenclauses_1,zero_crossings),(SOME(functionTree),{DAE.NORM_INLINE()}));
        BackendDAEUtil.checkDEALowWithErrorMsg(BackendDAE.DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls));
      then BackendDAE.DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls);

    case(lst, functionTree, addDummyDerivativeIfNeeded, false) // do not simplify
      equation
        (DAE.DAE(elems),functionTree)  = processDelayExpressions(lst,functionTree);
        s = BackendDAEUtil.states(elems, BackendDAE.emptyBintree);
        vars = BackendDAEUtil.emptyVars();
        knvars = BackendDAEUtil.emptyVars();
        extVars = BackendDAEUtil.emptyVars();
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses,extObjCls,s) = lower2(elems, functionTree, s, vars, knvars, extVars, {});

        daeContainsNoStates = hasNoStates(s); // check if the DAE has states
        // adrpo: add the dummy derivative state ONLY IF the DAE contains
        //        no states AND ONLY if addDummyDerivative is set to true!
        shouldAddDummyDerivative =  boolAnd(addDummyDerivativeIfNeeded, daeContainsNoStates);
        (vars,eqns) = addDummyState(vars, eqns, shouldAddDummyDerivative);

        whenclauses_1 = listReverse(whenclauses);
        algeqns = lowerAlgorithms(vars, algs);
       (multidimeqns,imultidimeqns) = lowerMultidimeqns(vars, aeqns, iaeqns);
        eqns = listAppend(algeqns, eqns);
        eqns = listAppend(multidimeqns, eqns);
        ieqns = listAppend(imultidimeqns, ieqns);
        // no simplify (vars,knvars,eqns,reqns,ieqns,aeqns1) = DAELow.removeSimpleEquations(vars, knvars, eqns, reqns, ieqns, aeqns, s);
        aliasVars = BackendDAEUtil.emptyAliasVariables();
        vars_1 = detectImplicitDiscrete(vars, eqns);
        eqns_1 = sortEqn(eqns);
        // no simplify (eqns_1,ieqns,aeqns1,algs,vars_1) = expandDerOperator(vars_1,eqns_1,ieqns,aeqns1,algs);
        (zero_crossings) = findZeroCrossings(vars_1,knvars,eqns_1,aeqns,whenclauses_1,algs);
        eqnarr = BackendDAEUtil.listEquation(eqns_1);
        reqnarr = BackendDAEUtil.listEquation(reqns);
        ieqnarr = BackendDAEUtil.listEquation(ieqns);
        arr_md_eqns = listArray(aeqns);
        algarr = listArray(algs);
        einfo = Inline.inlineEventInfo(BackendDAE.EVENT_INFO(whenclauses_1,zero_crossings),(SOME(functionTree),{DAE.NORM_INLINE()}));        
        BackendDAEUtil.checkDEALowWithErrorMsg(BackendDAE.DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls));        
      then BackendDAE.DAELOW(vars_1,knvars,extVars,aliasVars,eqnarr,reqnarr,ieqnarr,arr_md_eqns,algarr,einfo,extObjCls);
  end matchcontinue;
end lower;

protected function lower2
"function: lower2
  Helper function to lower.
  inputs:  (DAE.DAElist,BinTree /* states */,BackendDAE.Variables,BackendDAE.Variables,BackendDAE.Variables,WhenClause list)
  outputs: (Variables,BackendDAE.Variables,BackendDAE.Variables,Equation list,Equation list,Equation list,MultiDimEquation list,DAE.Algorithm list,WhenClause list)"
  input list<DAE.Element> inElements;
  input DAE.FunctionTree functionTree;
  input BackendDAE.BinTree inStatesBinTree;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnownVariables;
  input BackendDAE.Variables inExternalVariables;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> outEquationLst3;
  output list<BackendDAE.Equation> outEquationLst4;
  output list<BackendDAE.Equation> outEquationLst5;
  output list<BackendDAE.MultiDimEquation> outMultiDimEquationLst6;
  output list<BackendDAE.MultiDimEquation> outMultiDimEquationLst7;
  output list<DAE.Algorithm> outAlgorithmAlgorithmLst8;
  output list<BackendDAE.WhenClause> outWhenClauseLst9;
  output BackendDAE.ExternalObjectClasses outExtObjClasses;
  output BackendDAE.BinTree outStatesBinTree;
algorithm
  (outVariables,outKnownVariables,outExternalVariables,outEquationLst3,outEquationLst4,outEquationLst5,
   outMultiDimEquationLst6,outMultiDimEquationLst7,outAlgorithmAlgorithmLst8,outWhenClauseLst9,outExtObjClasses,outStatesBinTree):=
   matchcontinue (inElements,functionTree,inStatesBinTree,inVariables,inKnownVariables,inExternalVariables,inWhenClauseLst)
    local
      BackendDAE.Variables v1,v2,v3,vars,knvars,extVars,extVars1,extVars2,vars_1,knvars_1,vars1,vars2,knvars1,knvars2,kv;
      list<BackendDAE.WhenClause> whenclauses,whenclauses_1,whenclauses_2;
      list<BackendDAE.Equation> eqns,reqns,ieqns,eqns1,eqns2,reqns1,ieqns1,reqns2,ieqns2,re,ie,eqsComplex;
      list<BackendDAE.MultiDimEquation> aeqns,aeqns1,aeqns2,ae,iaeqns,iaeqns1,iaeqns2,iae;
      list<DAE.Algorithm> algs,algs1,algs2,al;
      BackendDAE.ExternalObjectClasses extObjCls,extObjCls1,extObjCls2;
      BackendDAE.ExternalObjectClass extObjCl;
      BackendDAE.Var v_1,v_2;
      DAE.Element v,e;
      list<DAE.Element> xs;
      BackendDAE.BinTree states;
      BackendDAE.Equation e_1, e_2;
      DAE.Exp e1,e2,c;
      list<BackendDAE.Value> ds;
      BackendDAE.Value count,count_1;
      DAE.Algorithm a,a1,a2;
      DAE.DAElist dae;
      DAE.ExpType ty;
      DAE.ComponentRef cr;
      Absyn.InnerOuter io;
      DAE.ElementSource source "the element source";
      DAE.FunctionTree funcs;
      list<DAE.Element> daeElts;
      Absyn.Info info;
    
    // the empty case 
    case ({},functionTree,states,v1,v2,v3,whenclauses)
      then
        (v1,v2,v3,{},{},{},{},{},{},whenclauses,{},states);

    // adrpo: should we ignore OUTER vars?!
    //case (((v as DAE.VAR(innerOuter=io)) :: xs),states,vars,knvars,extVars,whenclauses)
    //  equation
    //    DAEUtil.isOuterVar(v);
    //    (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) =
    //    lower2(xs, states, vars, knvars, extVars, whenclauses);
    //  then
    //    (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls);
    
    // external object variables
    case ((v as DAE.VAR(componentRef = _)) :: xs,functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        v_1 = lowerExtObjVar(v);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
        extVars2 = DAELow.addVar(v_2, extVars);
      then
        (vars,knvars,extVars2,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);

    // class for external object
    case (((v as DAE.EXTOBJECTCLASS(path,constr,destr,source)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local
        Absyn.Path path;
        DAE.Function constr,destr;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        {extObjCl} = Inline.inlineExtObjClasses({BackendDAE.EXTOBJCLASS(path,constr,destr,source)},(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,
        extObjCl::extObjCls,states);
    
    // variables: states and algebraic variables with binding equation
    case (((v as DAE.VAR(componentRef = cr, source = source)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        // adrpo 2009-09-07 - according to MathCore
        // add the binding as an equation and remove the binding from variable!
        true = isStateOrAlgvar(v);
        (v_1,SOME(e1),states) = lowerVar(v, states);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
        e2 = Inline.inlineExp(e1,(SOME(functionTree),{DAE.NORM_INLINE()}));
        vars_1 = DAELow.addVar(v_2, vars);
      then
        (vars_1,knvars,extVars,BackendDAE.EQUATION(DAE.CREF(cr, DAE.ET_OTHER()), e2, source)::eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // variables: states and algebraic variables with NO binding equation
    case (((v as DAE.VAR(componentRef = cr, source = source)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states) =
        lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        true = isStateOrAlgvar(v);
        (v_1,NONE(),states) = lowerVar(v, states);
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
        vars_1 = DAELow.addVar(v_2, vars);
      then
        (vars_1,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // known variables: parameters and constants
    case (((v as DAE.VAR(componentRef = _)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        v_1 = lowerKnownVar(v) "in previous rule, lower_var failed." ;
        SOME(v_2) = Inline.inlineVarOpt(SOME(v_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
        knvars_1 = DAELow.addVar(v_2, knvars);
      then
        (vars,knvars_1,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // tuple equations are rewritten to algorihm tuple assign.
    case (((e as DAE.EQUATION(exp = e1,scalar = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        a = lowerTupleEquation(e);
        a1 = Inline.inlineAlgorithm(a,(SOME(functionTree),{DAE.NORM_INLINE()}));
        a2 = extendAlgorithm(a1,SOME(functionTree));
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
          = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,a2::algs,whenclauses_1,extObjCls,states);
    
    // tuple-tuple assignments are split into one equation for each tuple
    // element, i.e. (i1, i2) = (4, 6) => i1 = 4; i2 = 6; 
    case ((DAE.EQUATION(DAE.TUPLE(targets), DAE.TUPLE(sources), source = eq_source) :: xs),
        functionTree,states,vars,knvars,extVars,whenclauses)
      local
        list<DAE.Exp> targets;
        list<DAE.Exp> sources;
        DAE.ElementSource eq_source;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
          = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        eqns2 = lowerTupleAssignment(targets, sources, eq_source, functionTree);
        eqns = listAppend(eqns2, eqns);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // scalar equations
    case (((e as DAE.EQUATION(exp = e1,scalar = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,(e_2 :: eqns),reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // effort variable equality equations
    case (((e as DAE.EQUEQUATION(cr1 = _)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,(e_2 :: eqns),reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // a solved equation 
    case (((e as DAE.DEFINE(componentRef = _)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,e_2 :: eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // complex equations
    case (((e as DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        (eqsComplex,aeqns1) = lowerComplexEqn(e, functionTree);
        eqns = listAppend(eqsComplex, eqns);
        aeqns2 = listAppend(aeqns, aeqns1);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns2,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // complex initial equations
    case (((e as DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        (eqsComplex,iaeqns1) = lowerComplexEqn(e, functionTree);
        ieqns = listAppend(eqsComplex, ieqns);
        iaeqns2 = listAppend(iaeqns, iaeqns1);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns2,algs,whenclauses_1,extObjCls,states);
    
    // array equations
    case (((e as DAE.ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local 
        DAE.Exp e_11,e_21;
        list<DAE.Exp> ea1,ea2;
        list<tuple<DAE.Exp,DAE.Exp>> ealst;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        BackendDAE.MULTIDIM_EQUATION(left=e_11 as DAE.ARRAY(scalar=true,array=ea1),
                          right=e_21 as DAE.ARRAY(scalar=true,array=ea2),source=source)
          = lowerArrEqn(e,functionTree);
        ealst = Util.listThreadTuple(ea1,ea2);
        re = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        eqns = listAppend(re, eqns);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // array equations
    case (((e as DAE.ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local 
        BackendDAE.MultiDimEquation e_1;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerArrEqn(e,functionTree);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,(e_1 :: aeqns),iaeqns,algs,whenclauses_1,extObjCls,states);
        
    // initial array equations 
    case (((e as DAE.INITIAL_ARRAY_EQUATION(dimension = ds,exp = e1,array = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local 
        DAE.Exp e_11,e_21;
        list<DAE.Exp> ea1,ea2;
        list<tuple<DAE.Exp,DAE.Exp>> ealst;
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        BackendDAE.MULTIDIM_EQUATION(left=e_11 as DAE.ARRAY(scalar=true,array=ea1),
                          right=e_21 as DAE.ARRAY(scalar=true,array=ea2),source=source)
          = lowerArrEqn(e,functionTree);
        ealst = Util.listThreadTuple(ea1,ea2);
        re = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        ieqns = listAppend(re, ieqns);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);    
    
    // initial array equations
    case (((e as DAE.INITIAL_ARRAY_EQUATION(dimension = ds, exp = e1, array = e2)) :: xs), 
        functionTree, states, vars, knvars, extVars, whenclauses)
      local 
        BackendDAE.MultiDimEquation e_1;
      equation
        (vars, knvars, extVars, eqns, reqns, ieqns, aeqns,iaeqns, algs, whenclauses_1, extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerArrEqn(e,functionTree);
      then
        (vars, knvars, extVars, eqns, reqns, ieqns, aeqns,(e_1 :: iaeqns), algs, whenclauses_1, extObjCls,states);
    
    // when equations
    case (((e as DAE.WHEN_EQUATION(condition = c,equations = eqns)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local list<Option<BackendDAE.Equation>> opteqlst;
      equation
        (vars1,knvars,extVars,eqns1,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        count = listLength(whenclauses_1);
        (eqns2,vars2,count_1,whenclauses_2) = lowerWhenEqn(e, count, whenclauses_1);
        vars = mergeVars(vars1, vars2);
        opteqlst = Util.listMap(eqns2,Util.makeOption);
        opteqlst = Util.listMap1(opteqlst,Inline.inlineEqOpt,(SOME(functionTree),{DAE.NORM_INLINE()}));
        eqns2 = Util.listMap(opteqlst,Util.getOption);
        eqns = listAppend(eqns1, eqns2);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_2,extObjCls,states);
    
    // initial equations
    case (((e as DAE.INITIALEQUATION(exp1 = e1,exp2 = e2)) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        e_1 = lowerEqn(e);
        SOME(e_2) = Inline.inlineEqOpt(SOME(e_1),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,knvars,extVars,eqns,reqns,(e_2 :: ieqns),aeqns,iaeqns,algs,whenclauses_1,extObjCls,states);
    
    // algorithm
    case ((DAE.ALGORITHM(algorithm_ = a) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_1,extObjCls,states)
        = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
       a1 = Inline.inlineAlgorithm(a,(SOME(functionTree),{DAE.NORM_INLINE()})); 
       a2 = extendAlgorithm(a1,SOME(functionTree));
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,(a2 :: algs),whenclauses_1,extObjCls,states);
    
    // flat class / COMP
    case ((DAE.COMP(dAElist = daeElts) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        (vars1,knvars1,extVars1,eqns1,reqns1,ieqns1,aeqns1,iaeqns1,algs1,whenclauses_1,extObjCls1,states) = lower2(daeElts, functionTree, states, vars, knvars, extVars, whenclauses);
        (vars2,knvars2,extVars2,eqns2,reqns2,ieqns2,aeqns2,iaeqns2,algs2,whenclauses_2,extObjCls2,states) = lower2(xs, functionTree, states, vars1, knvars1, extVars1, whenclauses_1);
        vars = vars2; // vars = mergeVars(vars1, vars2);
        knvars = knvars2; // knvars = mergeVars(knvars1, knvars2);
        extVars = extVars2; // extVars = mergeVars(extVars1,extVars2);
        eqns = listAppend(eqns1, eqns2);
        ieqns = listAppend(ieqns1, ieqns2);
        reqns = listAppend(reqns1, reqns2);
        aeqns = listAppend(aeqns1, aeqns2);
        iaeqns = listAppend(iaeqns1, iaeqns2);
        algs = listAppend(algs1, algs2);
        extObjCls = listAppend(extObjCls1,extObjCls2);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,iaeqns,algs,whenclauses_2,extObjCls,states);
    
    // assert in equation section is converted to ALGORITHM
    case ((DAE.ASSERT(cond,msg,source) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local
        BackendDAE.Variables v;
        list<BackendDAE.Equation> e;
        DAE.Exp cond,msg;
        DAE.Algorithm alg;
      equation
        checkAssertCondition(cond,msg);
        (v,kv,extVars,e,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(xs,functionTree,states,vars,knvars,extVars,whenclauses);
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,source)}),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (v,kv,extVars,e,re,ie,ae,iae,a::al,whenclauses_1,extObjCls,states);
    
    // terminate in equation section is converted to ALGORITHM
    case ((DAE.TERMINATE(message = msg, source = source) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local
        BackendDAE.Variables v;
        list<BackendDAE.Equation> e;
        DAE.Exp cond,msg;
      equation
        (v,kv,extVars,e,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(xs, functionTree, states, vars,knvars,extVars, whenclauses) ;
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg,source)}),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (v,kv,extVars,e,re,ie,ae,iae,a::al,whenclauses_1,extObjCls,states);
    
    case ((DAE.NORETCALL(functionName = func_name, functionArgs = args, source = source) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local
        Absyn.Path func_name;
        list<DAE.Exp> args;
        DAE.Statement s;
        Boolean b1, b2, b;
      equation
        // make sure is not constrain as we don't support it, see below.
        b1 = boolNot(Util.isEqual(func_name, Absyn.IDENT("constrain")));
        // constrain is fine when we do check model!
        b2 = OptManager.getOption("checkModel");
        true = boolOr(b1, b2);
        
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses_1,extObjCls,states) = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
        s = DAE.STMT_NORETCALL(DAE.CALL(func_name, args, false, false, DAE.ET_NORETCALL(), DAE.NORM_INLINE()),source);
        a = Inline.inlineAlgorithm(DAE.ALGORITHM_STMTS({s}),(SOME(functionTree),{DAE.NORM_INLINE()}));
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,a :: al,whenclauses_1,extObjCls,states);

    // when running checkModel ignore some of the unsupported features as we only want to see nr eqs/vars
    // if equation that cannot be translated to if expression but have initial() as condition
    case (((e as DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))}, source = DAE.SOURCE(info = info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        true = OptManager.getOption("checkModel");
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states) = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);        
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states);
    
    // when running checkModel ignore some of the unsupported features as we only want to see nr eqs/vars
    // initial if equation that cannot be translated to if expression 
    case (((e as DAE.INITIAL_IF_EQUATION(condition1 = _, source = DAE.SOURCE(info = info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        true = OptManager.getOption("checkModel");
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states) = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);        
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states);
    
    // when running checkModel ignore some of the unsupported features as we only want to see nr eqs/vars
    // initial algorithm
    case (((e as DAE.INITIALALGORITHM(algorithm_ = _, source = DAE.SOURCE(info=info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      equation
        true = OptManager.getOption("checkModel");
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states) = lower2(xs, functionTree, states, vars, knvars, extVars, whenclauses);
      then
        (vars,kv,extVars,eqns,re,ie,ae,iae,al,whenclauses,extObjCls,states);

    // error reporting from now on
     
    // if equation that cannot be translated to if expression
    case ((e as DAE.IF_EQUATION(condition1 = _, source = DAE.SOURCE(info = info))) :: xs,functionTree,states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite equations using if-expressions: ",str);
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"if-equations",str}, info);
      then
        fail();
    
    // initial if equation that cannot be translated to if expression 
    case ((e as DAE.INITIAL_IF_EQUATION(condition1 = _, source = DAE.SOURCE(info = info))) :: xs,functionTree,states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite equations using if-expressions: ",str);
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"if-equations",str}, info);
      then
        fail();
    
    // initial algorithm
    case (((e as DAE.INITIALALGORITHM(algorithm_ = _, source = DAE.SOURCE(info=info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite initial algorithms to initial equations",str);        
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"initial algorithm",str}, info);
      then
        fail();
      
    // constrain is not a standard Modelica function, but used in old libraries such as the old Multibody library.
    // The OpenModelica backend does not support constrain, but the frontend does (Mathcore needs it for their backend).
    // To get a meaningful error message when constrain is used we catch it here, instead of silently failing. 
    // User-defined functions should have fully qualified names here, so Absyn.IDENT should only match the builtin constrain function.        
    case (((e as DAE.NORETCALL(functionName = Absyn.IDENT(name = "constrain"), source = DAE.SOURCE(info=info))) :: xs),functionTree,states,vars,knvars,extVars,whenclauses)
      local String str;
      equation
        str = DAEDump.dumpElementsStr({e});
        str = stringAppend("rewrite code without using constrain",str);        
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"constrain function",str}, info);
      then
        fail();
        
    case (ddl::xs,functionTree,_,vars,knvars,extVars,_)
      local DAE.Element ddl; String s3;
      equation
        // show only on failtrace!
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- DAELow.lower2 failed on: " +& DAEDump.dumpElementsStr({ddl}));
      then
        fail();
  end matchcontinue;
end lower2;


/*
 *  lower all variables
 */

protected function lowerVar
"function: lowerVar
  Transforms a DAE variable to DAELOW variable.
  Includes changing the ComponentRef name to a simpler form
  \'a\'.\'b\'{2}\'c\'{5} becomes
  \'a.b{2}.c\' (as CREF_IDENT(\"a.b.c\",{2}) )
  inputs: (DAE.Element, BackendDAE.BinTree /* states */)
  outputs: Var"
  input DAE.Element inElement;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.Var outVar;
  output Option<DAE.Exp> outBinding;
  output BackendDAE.BinTree outBinTree;
algorithm
  (outVar,outBinding,outBinTree) := matchcontinue (inElement,inBinTree)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      BackendDAE.BinTree states;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment),states)
      equation
        (kind_1,states) = lowerVarkind(kind, t, name, dir, flowPrefix, streamPrefix, states, dae_var_attr);
        tp = lowerType(t);
      then
        (BackendDAE.VAR(name,kind_1,dir,tp,NONE(),NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix), bind, states);
  end matchcontinue;
end lowerVar;

protected function lowerKnownVar
"function: lowerKnownVar
  Helper function to lower2"
  input DAE.Element inElement;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inElement)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment))
      equation
        kind_1 = lowerKnownVarkind(kind, name, dir, flowPrefix);
        tp = lowerType(t);
      then
        BackendDAE.VAR(name,kind_1,dir,tp,bind,NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix);

    case (_)
      equation
        print("-DAELow.lowerKnownVar failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVar;


protected function lowerVarkind
"function: lowerVarkind
  Helper function to lowerVar.
  inputs: (DAE.VarKind,
           Type,
           DAE.ComponentRef,
           DAE.VarDirection, /* input/output/bidir */
           DAE.Flow,
           DAE.Stream,
           BackendDAE.BinTree /* states */)
  outputs  VarKind
  NOTE: Fails for not states that are not algebraic
        variables, e.g. parameters and constants"
  input DAE.VarKind inVarKind;
  input DAE.Type inType;
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
  input DAE.Stream inStream;
  input BackendDAE.BinTree inBinTree;
  input option<DAE.VariableAttributes> daeAttr;
  output BackendDAE.VarKind outVarKind;
  output BackendDAE.BinTree outBinTree;
algorithm
  (outVarKind,outBinTree) := matchcontinue (inVarKind,inType,inComponentRef,inVarDirection,inFlow,inStream,inBinTree,daeAttr)
    local
      DAE.ComponentRef v,cr;
      BackendDAE.BinTree states;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    // States appear differentiated among equations
    case (DAE.VARIABLE(),_,v,_,_,_,states,daeAttr)
      equation
        _ = DAELow.treeGet(states, v);
      then
        (BackendDAE.STATE(),states);
    // Or states have StateSelect.always
    case (DAE.VARIABLE(),_,v,_,_,_,states,SOME(DAE.VAR_ATTR_REAL(_,_,_,_,_,_,_,SOME(DAE.ALWAYS()),_,_,_)))
      equation
      states = DAELow.treeAdd(states, v, 0);  
    then (BackendDAE.STATE(),states);

    case (DAE.VARIABLE(),(DAE.T_BOOL(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(DAELow.topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);

    case (DAE.DISCRETE(),(DAE.T_BOOL(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(DAELow.topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);

    case (DAE.VARIABLE(),(DAE.T_INTEGER(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(DAELow.topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);

    case (DAE.DISCRETE(),(DAE.T_INTEGER(_),_),cr,dir,flowPrefix,_,states,_)
      equation
        failure(DAELow.topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);

    case (DAE.VARIABLE(),_,cr,dir,flowPrefix,_,states,_)
      equation
        failure(DAELow.topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.VARIABLE(),states);

    case (DAE.DISCRETE(),_,cr,dir,flowPrefix,_,states,_)
      equation
        failure(DAELow.topLevelInput(cr, dir, flowPrefix));
      then
        (BackendDAE.DISCRETE(),states);
  end matchcontinue;
end lowerVarkind;

protected function lowerKnownVarkind
"function: lowerKnownVarkind
  Helper function to lowerKnownVar.
  NOTE: Fails for everything but parameters and constants and top level inputs"
  input DAE.VarKind inVarKind;
  input DAE.ComponentRef inComponentRef;
  input DAE.VarDirection inVarDirection;
  input DAE.Flow inFlow;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind := matchcontinue (inVarKind,inComponentRef,inVarDirection,inFlow)
    local
      DAE.ComponentRef cr;
      DAE.VarDirection dir;
      DAE.Flow flowPrefix;
    case (DAE.PARAM(),_,_,_) then BackendDAE.PARAM();
    case (DAE.CONST(),_,_,_) then BackendDAE.CONST();
    case (DAE.VARIABLE(),cr,dir,flowPrefix)
      equation
        DAELow.topLevelInput(cr, dir, flowPrefix);
      then
        BackendDAE.VARIABLE();
    // adrpo: topLevelInput might fail!
    // case (DAE.VARIABLE(),cr,dir,flowPrefix)
    //  then
    //    BackendDAE.VARIABLE();
    case (_,_,_,_)
      equation
        print("lower_known_varkind failed\n");
      then
        fail();
  end matchcontinue;
end lowerKnownVarkind;

protected function lowerType
"Transforms a DAE.Type to Type
"
  input  DAE.Type inType;
  output BackendDAE.Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
      Absyn.Path path;
    case ((DAE.T_REAL(_),_)) then BackendDAE.REAL();
    case ((DAE.T_INTEGER(_),_)) then BackendDAE.INT();
    case ((DAE.T_BOOL(_),_)) then BackendDAE.BOOL();
    case ((DAE.T_STRING(_),_)) then BackendDAE.STRING();
    case ((DAE.T_ENUMERATION(names = strLst),_)) then BackendDAE.ENUMERATION(strLst);
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path)),_)) then BackendDAE.EXT_OBJECT(path);
  end matchcontinue;
end lowerType;


protected function lowerExtObjVar
" Helper function to lower2
  Fails for all variables except external object instances."
  input DAE.Element inElement;
  output BackendDAE.Var outVar;
algorithm
  outVar:=
  matchcontinue (inElement)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  ty = t,
                  binding = bind,
                  dims = dims,
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment))
      equation
        kind_1 = lowerExtObjVarkind(t);
        tp = lowerType(t);
      then
        BackendDAE.VAR(name,kind_1,dir,tp,bind,NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix);
  end matchcontinue;
end lowerExtObjVar;

protected function lowerExtObjVarkind
" Helper function to lowerExtObjVar.
  NOTE: Fails for everything but External objects"
  input DAE.Type inType;
  output BackendDAE.VarKind outVarKind;
algorithm
  outVarKind:=
  matchcontinue (inType)
    local Absyn.Path path;
    case ((DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path)),_)) then BackendDAE.EXTOBJ(path);
  end matchcontinue;
end lowerExtObjVarkind;


/*
 *  lower all equation types
 */

protected function lowerEqn
"function: lowerEqn
  Helper function to lower2.
  Transforms a DAE.Element to Equation."
  input DAE.Element inElement;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation :=  matchcontinue (inElement)
    local DAE.Exp e1,e2;
          DAE.ComponentRef cr1,cr2;
          DAE.ElementSource source "the element source";

    case (DAE.EQUATION(exp = e1,scalar = e2,source = source))
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
      then
        BackendDAE.EQUATION(e1,e2,source);

    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2,source = source))
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
      then
        BackendDAE.EQUATION(e1,e2,source);

    case (DAE.EQUEQUATION(cr1 = cr1, cr2 = cr2,source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(DAE.CREF(cr2, DAE.ET_OTHER()));
      then
        BackendDAE.EQUATION(e1,e2,source);

    case (DAE.DEFINE(componentRef = cr1, exp = e2, source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(e2);
      then
        BackendDAE.EQUATION(e1,e2,source);

    case (DAE.INITIALDEFINE(componentRef = cr1, exp = e2, source = source))
      equation
        e1 = Exp.simplify(DAE.CREF(cr1, DAE.ET_OTHER()));
        e2 = Exp.simplify(e2);
      then
        BackendDAE.EQUATION(e1,e2,source);
  end matchcontinue;
end lowerEqn;

protected function lowerArrEqn
"function: lowerArrEqn
  Helper function to lower2.
  Transform a DAE.Element to MultiDimEquation."
  input DAE.Element inElement;
  input DAE.FunctionTree funcs;
  output BackendDAE.MultiDimEquation outMultiDimEquation;
algorithm
  outMultiDimEquation := matchcontinue (inElement,funcs)
    local
      DAE.Exp e1,e2,e1_1,e2_1,e1_2,e2_2,e1_3,e2_3;
      list<BackendDAE.Value> ds;
      DAE.ElementSource source;

    case (DAE.ARRAY_EQUATION(dimension = ds, exp = e1, array = e2, source = source),funcs)
      equation
        e1_1 = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(SOME(funcs),{DAE.NORM_INLINE()}));
        (e1_2,_) = DAELow.extendArrExp(e1_1,SOME(funcs));
        (e2_2,_) = DAELow.extendArrExp(e2_1,SOME(funcs));
        e1_3 = Exp.simplify(e1_2);
        e2_3 = Exp.simplify(e2_2);
      then
        BackendDAE.MULTIDIM_EQUATION(ds,e1_3,e2_3,source);

    case (DAE.INITIAL_ARRAY_EQUATION(dimension = ds, exp = e1, array = e2, source = source),funcs)
      equation
        e1_1 = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(SOME(funcs),{DAE.NORM_INLINE()}));
        (e1_2,_) = DAELow.extendArrExp(e1_1,SOME(funcs));
        (e2_2,_) = DAELow.extendArrExp(e2_1,SOME(funcs));
        e1_3 = Exp.simplify(e1_2);
        e2_3 = Exp.simplify(e2_2);
      then
        BackendDAE.MULTIDIM_EQUATION(ds,e1_3,e2_3,source);
  end matchcontinue;
end lowerArrEqn;

protected function lowerComplexEqn
"function: lowerComplexEqn
  Helper function to lower2.
  Transform a DAE.Element to ComplexEquation."
  input DAE.Element inElement;
  input DAE.FunctionTree funcs;
  output list<BackendDAE.Equation> outComplexEquations;
  output list<BackendDAE.MultiDimEquation> outMultiDimEquations;  
algorithm
  (outComplexEquations,outMultiDimEquations) := matchcontinue (inElement, funcs)
    local
      DAE.Exp e1,e2,e1_1,e2_1;
      DAE.ExpType ty;
      list<DAE.ExpVar> varLst;
      Integer i;
      list<BackendDAE.Equation> complexEqs;
      list<BackendDAE.MultiDimEquation> arreqns;
      DAE.ElementSource source "the element source";

    // normal first try to inline function calls and extend the equations
    case (DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        // inline 
        e1_1 = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(SOME(funcs),{DAE.NORM_INLINE()}));
        // extend      
        ((complexEqs,arreqns)) = extendRecordEqns(BackendDAE.COMPLEX_EQUATION(-1,e1_1,e2_1,source),funcs);
      then
        (complexEqs,arreqns);
    case (DAE.COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        // create as many equations as the dimension of the record
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        complexEqs = Util.listFill(BackendDAE.COMPLEX_EQUATION(-1,e1,e2,source), i);
      then
        (complexEqs,{});
    // initial first try to inline function calls and extend the equations
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        // inline 
        e1_1 = Inline.inlineExp(e1,(SOME(funcs),{DAE.NORM_INLINE()}));
        e2_1 = Inline.inlineExp(e2,(SOME(funcs),{DAE.NORM_INLINE()}));
        // extend      
        ((complexEqs,arreqns)) = extendRecordEqns(BackendDAE.COMPLEX_EQUATION(-1,e1_1,e2_1,source),funcs);
      then
        (complexEqs,arreqns);
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1, rhs = e2,source = source),funcs)
      equation
        e1 = Exp.simplify(e1);
        e2 = Exp.simplify(e2);
        // create as many equations as the dimension of the record
        ty = Exp.typeof(e1);
        i = Exp.sizeOf(ty);
        complexEqs = Util.listFill(BackendDAE.COMPLEX_EQUATION(-1,e1,e2,source), i);
      then
        (complexEqs,{});
    case (_,_)
      equation
        print("- DAELow.lowerComplexEqn failed!\n");
      then ({},{});
  end matchcontinue;
end lowerComplexEqn;

protected function lowerWhenEqn
"function lowerWhenEqn
  This function lowers a when clause. The condition expresion is put in the
  BackendDAE.WhenClause list and the equations inside are put in the equation list.
  For each equation in the clause a new entry in the BackendDAE.WhenClause list is generated
  and one extra for all the reinit statements.
  inputs:  (DAE.Element, int /* when-clause index */, BackendDAE.WhenClause list)
  outputs: (Equation list, BackendDAE.Variables, int /* when-clause index */, BackendDAE.WhenClause list)"
  input DAE.Element inElement;
  input Integer inWhenClauseIndex;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  output list<BackendDAE.Equation> outEquationLst;
  output BackendDAE.Variables outVariables;
  output Integer outWhenClauseIndex;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  (outEquationLst,outVariables,outWhenClauseIndex,outWhenClauseLst):=
  matchcontinue (inElement,inWhenClauseIndex,inWhenClauseLst)
    local
      BackendDAE.Variables vars;
      BackendDAE.Variables elseVars;
      list<BackendDAE.Equation> res, res1;
      list<BackendDAE.Equation> trueEqnLst, elseEqnLst;
      list<BackendDAE.ReinitStatement> reinit;
      Integer equation_count,reinit_count,extra,tot_count,i_1,i,nextWhenIndex;
      Boolean hasReinit;
      list<BackendDAE.WhenClause> whenClauseList1,whenClauseList2,whenClauseList3,whenClauseList4,whenList,elseClauseList;
      DAE.Exp cond;
      list<DAE.Element> eqnl;
      DAE.Element elsePart;

    case (DAE.WHEN_EQUATION(condition = cond,equations = eqnl,elsewhen_ = NONE()),i,whenList)
      equation
        vars = BackendDAEUtil.emptyVars();
        (res,reinit) = lowerWhenEqn2(eqnl, i);
        equation_count = listLength(res);
        reinit_count = listLength(reinit);
        hasReinit = (reinit_count > 0);
        extra = Util.if_(hasReinit, 1, 0);
        tot_count = equation_count + extra;
        i_1 = i + tot_count;
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        whenClauseList3 = listAppend(whenClauseList2, whenClauseList1);
        whenClauseList4 = listAppend(whenClauseList3, whenList);
      then
        (res,vars,i_1,whenClauseList4);

    case (DAE.WHEN_EQUATION(condition = cond,equations = eqnl,elsewhen_ = SOME(elsePart)),i,whenList)
      equation
        vars = BackendDAEUtil.emptyVars();
        (elseEqnLst,_,nextWhenIndex,elseClauseList) = lowerWhenEqn(elsePart,i,whenList);
        (trueEqnLst,reinit) = lowerWhenEqn2(eqnl, nextWhenIndex);
        equation_count = listLength(trueEqnLst);
        reinit_count = listLength(reinit);
        hasReinit = (reinit_count > 0);
        extra = Util.if_(hasReinit, 1, 0);
        tot_count = equation_count + extra;
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        whenClauseList3 = listAppend(whenClauseList2, whenClauseList1);
        (res1,i_1,whenClauseList4) = mergeClauses(trueEqnLst,elseEqnLst,whenClauseList3,
          elseClauseList,nextWhenIndex + tot_count);
      then
        (res1,vars,i_1,whenClauseList4);

    case (DAE.WHEN_EQUATION(condition = cond),_,_)
      local String scond;
      equation
        scond = Exp.printExpStr(cond);
        print("- DAELow.lowerWhenEqn: Error in lowerWhenEqn. \n when ");
        print(scond);
        print(" ... \n");
      then fail();
  end matchcontinue;
end lowerWhenEqn;

protected function lowerWhenEqn2
"function lowerWhenEqn2
  Helper function to lowerWhenEqn. Lowers the equations inside a when clause"
  input list<DAE.Element> inDAEElementLst "The List of equations inside a when clause";
  input Integer inWhenClauseIndex;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.ReinitStatement> outReinitStatementLst;
algorithm
  (outEquationLst,outReinitStatementLst):=
  matchcontinue (inDAEElementLst,inWhenClauseIndex)
    local
      BackendDAE.Value i;
      list<BackendDAE.Equation> eqnl;
      list<BackendDAE.ReinitStatement> reinit;
      DAE.Exp e_2,cre,e;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Element> xs;
      DAE.Element el;
      DAE.ElementSource source "the element source";

    case ({},_) then ({},{});
    case ((DAE.EQUATION(exp = (cre as DAE.CREF(componentRef = cr)),scalar = e, source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        ((BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: eqnl),reinit);

    case ((DAE.COMPLEX_EQUATION(lhs = (cre as DAE.CREF(componentRef = cr)),rhs = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        ((BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: eqnl),reinit);

    case ((DAE.REINIT(componentRef = cr,exp = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i);
      then
        (eqnl,(BackendDAE.REINIT(cr,e,source) :: reinit));

    case ((DAE.TERMINATE(message = e,source = source) :: xs),i)
      local DAE.ComponentRef cref_;
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i);
        e_2 = Exp.simplify(e); // Exp.stringifyCrefs(Exp.simplify(e));
        cref_ = ComponentReference.makeCrefIdent("_", DAE.ET_OTHER(), {});
      then
        ((BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cref_,e_2,NONE()),source) :: eqnl),reinit);
    
    case ((DAE.ARRAY_EQUATION(exp = (cre as DAE.CREF(componentRef = cr)),array = e,source = source) :: xs),i)
      equation
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        ((BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: eqnl),reinit);    
    
    // failure  
    case ((el::xs), i)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "- DAELow.lowerWhenEqn2 failed on:" +& DAEDump.dumpElementsStr({el}));
      then 
        fail();
    
    // adrpo: 2010-09-26
    // allow to continue when checking the model
    // just ignore this equation.
    case ((el::xs), i)
      equation
        true = OptManager.getOption("checkModel");
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1);
      then
        (eqnl, reinit);
  end matchcontinue;
end lowerWhenEqn2;


protected function lowerTupleAssignment
  "Used by lower2 to split a tuple-tuple assignment into one equation for each
  tuple-element"
  input list<DAE.Exp> target_expl;
  input list<DAE.Exp> source_expl;
  input DAE.ElementSource eq_source;
  input DAE.FunctionTree funcs;
  output list<BackendDAE.Equation> eqns;
algorithm
  eqns := matchcontinue(target_expl, source_expl, eq_source,funcs)
    local
      DAE.Exp target, source;
      list<DAE.Exp> rest_targets, rest_sources;
      DAE.Element e;
      BackendDAE.Equation eq,eq1;
      list<BackendDAE.Equation> new_eqns;
    case ({}, {}, _, funcs) then {};
    case (target :: rest_targets, source :: rest_sources, _, funcs)
      equation
        new_eqns = lowerTupleAssignment(rest_targets, rest_sources, eq_source, funcs);
        e = DAE.EQUATION(target, source, eq_source);
        eq = lowerEqn(e);
        SOME(eq1) = Inline.inlineEqOpt(SOME(eq),(SOME(funcs),{DAE.NORM_INLINE()}));
      then eq :: new_eqns;
  end matchcontinue;
end lowerTupleAssignment;

protected function lowerTupleEquation
"Lowers a tuple equation, e.g. (a,b) = foo(x,y)
 by transforming it to an algorithm (TUPLE_ASSIGN), e.g. (a,b) := foo(x,y);
 author: PA"
  input DAE.Element eqn;
  output DAE.Algorithm alg;
algorithm
  alg := matchcontinue(eqn)
    local
      DAE.ElementSource source;
      DAE.Exp e1,e2;
      list<DAE.Exp> expl;
      /* Only succeds for tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c) */
    case(DAE.EQUATION(DAE.TUPLE(expl),e2 as DAE.CALL(path =_),source))
    then DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.ET_OTHER(),expl,e2,source)});

    case(DAE.EQUATION(e2 as DAE.CALL(path =_),DAE.TUPLE(expl),source))
    then DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.ET_OTHER(),expl,e2,source)});
  end matchcontinue;
end lowerTupleEquation;

protected function lowerMultidimeqns
"function: lowerMultidimeqns
  author: PA

  Lowers MultiDimEquations by creating ARRAY_EQUATION nodes that points
  to the array equation, stored in a BackendDAE.MultiDimEquation array.
  each BackendDAE.MultiDimEquation has as many ARRAY_EQUATION nodes as it has array
  elements. This to ensure correct sorting using BLT.
  inputs:  (Variables, /* vars */
              BackendDAE.MultiDimEquation list)
  outputs: BackendDAE.Equation list"
  input BackendDAE.Variables vars;
  input list<BackendDAE.MultiDimEquation> algs;
  input list<BackendDAE.MultiDimEquation> ialgs;
  output list<BackendDAE.Equation> eqns;
  output list<BackendDAE.Equation> ieqns;
protected
  Integer indx;  
algorithm
  (eqns,indx) := lowerMultidimeqns2(vars, algs, 0);
  (ieqns,_) := lowerMultidimeqns2(vars, ialgs, indx);
end lowerMultidimeqns;

protected function lowerMultidimeqns2
"function: lowerMultidimeqns2
  Helper function to lower_multidimeqns. To handle indexes in BackendDAE.Equation nodes
  for multidimensional equations to indentify the corresponding
  MultiDimEquation
  inputs:  (Variables, /* vars */
              BackendDAE.MultiDimEquation list,
              int /* index */)
  outputs: (Equation list,
      int) /* updated index */"
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.MultiDimEquation> inMultiDimEquationLst;
  input Integer inInteger;
  output list<BackendDAE.Equation> outEquationLst;
  output Integer outInteger;
algorithm
  (outEquationLst,outInteger) := matchcontinue (inVariables,inMultiDimEquationLst,inInteger)
    local
      BackendDAE.Variables vars;
      BackendDAE.Value aindx;
      list<BackendDAE.Equation> eqns,eqns2,res;
      BackendDAE.MultiDimEquation a;
      list<BackendDAE.MultiDimEquation> algs;
      DAE.Exp e1,e2;
      list<DAE.Exp> a1,a2,a1_1,an;
      list<tuple<DAE.Exp,DAE.Exp>> ealst;
      list<list<tuple<DAE.Exp, Boolean>>> al1,al2;
      list<tuple<DAE.Exp, Boolean>> ebl1,ebl2;
      DAE.ElementSource source;      
    case (vars,{},aindx) then ({},aindx);
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.ARRAY(array=a1),right=DAE.ARRAY(array=a2),source=source)) :: algs),aindx)
      equation
        ealst = Util.listThreadTuple(a1,a2);
        eqns = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.UNARY(exp=DAE.ARRAY(array=a1)),right=DAE.ARRAY(array=a2),source=source)) :: algs),aindx)
      equation
        an = Util.listMap(a1,Exp.negate);
        ealst = Util.listThreadTuple(an,a2);
        eqns = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.ARRAY(array=a1),right=DAE.UNARY(exp=DAE.ARRAY(array=a2)),source=source)) :: algs),aindx)
      equation
        an = Util.listMap(a2,Exp.negate);
        ealst = Util.listThreadTuple(a1,an);
        eqns = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.MATRIX(scalar=al1),right=DAE.MATRIX(scalar=al2),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);
        ealst = Util.listThreadTuple(a1,a2);
        eqns = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);  
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.UNARY(exp=DAE.MATRIX(scalar=al1)),right=DAE.MATRIX(scalar=al2),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);        
        an = Util.listMap(a1,Exp.negate);
        ealst = Util.listThreadTuple(an,a2);
        eqns = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=DAE.MATRIX(scalar=al1),right=DAE.UNARY(exp=DAE.MATRIX(scalar=al2)),source=source)) :: algs),aindx)
      equation
        ebl1 = Util.listFlatten(al1);
        ebl2 = Util.listFlatten(al2);
        a1 = Util.listMap(ebl1,Util.tuple21);
        a2 = Util.listMap(ebl2,Util.tuple21);        
        an = Util.listMap(a2,Exp.negate);
        ealst = Util.listThreadTuple(a1,an);
        eqns = Util.listMap1(ealst,DAELow.generateEQUATION,source);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);              
    case (vars,((a as BackendDAE.MULTIDIM_EQUATION(left=e1,right=e2,source=source)) :: algs),aindx)
      equation
        eqns = lowerMultidimeqn(vars, a, aindx);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerMultidimeqns2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
  end matchcontinue;
end lowerMultidimeqns2;

protected function lowerMultidimeqn
"function: lowerMultidimeqn
  Lowers a BackendDAE.MultiDimEquation by creating an equation for each array
  index, such that BLT can be run correctly.
  inputs:  (Variables, /* vars */
              MultiDimEquation,
              int) /* indx */
  outputs:  BackendDAE.Equation list"
  input BackendDAE.Variables inVariables;
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  input Integer inInteger;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inVariables,inMultiDimEquation,inInteger)
    local
      list<DAE.Exp> expl1,expl2,expl;
      BackendDAE.Value numnodes,aindx;
      list<BackendDAE.Equation> lst;
      BackendDAE.Variables vars;
      list<BackendDAE.Value> ds;
      DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";

    case (vars,BackendDAE.MULTIDIM_EQUATION(dimSize = ds,left = e1,right = e2,source = source),aindx)
      equation
        expl1 = BackendDAEUtil.statesAndVarsExp(e1, vars);
        expl2 = BackendDAEUtil.statesAndVarsExp(e2, vars);
        expl = listAppend(expl1, expl2);
        numnodes = Util.listReduce(ds, int_mul);
        lst = lowerMultidimeqn2(expl, numnodes, aindx, source);
      then
        lst;
  end matchcontinue;
end lowerMultidimeqn;

protected function lowerMultidimeqn2
"function: lower_multidimeqns2
  Helper function to lower_multidimeqns
  Creates numnodes BackendDAE.Equation nodes so BLT can be run correctly.
  inputs:  (DAE.Exp list, int /* numnodes */, int /* indx */)
  outputs: BackendDAE.Equation list ="
  input list<DAE.Exp> inExpExpLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input DAE.ElementSource source "the element source";
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inExpExpLst1,inInteger2,inInteger3,source)
    local
      list<DAE.Exp> expl;
      BackendDAE.Value numnodes_1,numnodes,indx;
      list<BackendDAE.Equation> res;
    case (expl,0,_,_) then {};
    case (expl,numnodes,indx,source)
      equation
        numnodes_1 = numnodes - 1;
        res = lowerMultidimeqn2(expl, numnodes_1, indx, source);
      then
        (BackendDAE.ARRAY_EQUATION(indx,expl,source) :: res);
  end matchcontinue;
end lowerMultidimeqn2;

/*
 *   lower algorithms
 */


protected function lowerAlgorithms
"function: lowerAlgorithms
  This function lowers algorithm sections by generating a list
  of ALGORITHMS nodes for the BLT sorting, which are put in
  the equation list.
  An algorithm that calculates n variables will get n  ALGORITHM nodes
  such that the BLT sorting can be done correctly.
  inputs:  (Variables /* vars */, DAE.Algorithm list)
  outputs: BackendDAE.Equation list"
  input BackendDAE.Variables vars;
  input list<DAE.Algorithm> algs;
  output list<BackendDAE.Equation> eqns;
algorithm
  (eqns,_) := lowerAlgorithms2(vars, algs, 0);
end lowerAlgorithms;

protected function lowerAlgorithms2
"function: lowerAlgorithms2
  Helper function to lowerAlgorithms. To handle indexes in BackendDAE.Equation nodes
  for algorithms to indentify the corresponding algorithm.
  inputs:  (Variables /* vars */, DAE.Algorithm list, int /* algindex*/ )
  outputs: (Equation list, int /* updated algindex */ ) ="
  input BackendDAE.Variables inVariables;
  input list<DAE.Algorithm> inAlgorithmAlgorithmLst;
  input Integer inInteger;
  output list<BackendDAE.Equation> outEquationLst;
  output Integer outInteger;
algorithm
  (outEquationLst,outInteger) := matchcontinue (inVariables,inAlgorithmAlgorithmLst,inInteger)
    local
      BackendDAE.Variables vars;
      BackendDAE.Value aindx;
      list<BackendDAE.Equation> eqns,eqns2,res;
      DAE.Algorithm a;
      list<DAE.Algorithm> algs;
    case (vars,{},aindx) then ({},aindx);
    case (vars,(a :: algs),aindx)
      equation
        eqns = lowerAlgorithm(vars, a, aindx);
        aindx = aindx + 1;
        (eqns2,aindx) = lowerAlgorithms2(vars, algs, aindx);
        res = listAppend(eqns, eqns2);
      then
        (res,aindx);
  end matchcontinue;
end lowerAlgorithms2;

protected function lowerAlgorithm
"function: lowerAlgorithm
  Lowers a single algorithm. Creates n ALGORITHM nodes for blt sorting.
  inputs:  (Variables, /* vars */
              DAE.Algorithm,
              int /* algindx */)
  outputs: BackendDAE.Equation list"
  input BackendDAE.Variables vars;
  input DAE.Algorithm a;
  input Integer aindx;
  output list<BackendDAE.Equation> lst;
  list<DAE.Exp> inputs,outputs;
  BackendDAE.Value numnodes;
algorithm
  ((inputs,outputs)) := lowerAlgorithmInputsOutputs(vars, a);
  numnodes := listLength(outputs);
  lst := lowerAlgorithm2(inputs, outputs, numnodes, aindx);
end lowerAlgorithm;

protected function lowerAlgorithm2
"function: lowerAlgorithm2
  Helper function to lower_algorithm
  inputs:  (DAE.Exp list /* inputs   */,
              DAE.Exp list /* outputs  */,
              int          /* numnodes */,
              int          /* aindx    */)
  outputs:  (Equation list)"
  input list<DAE.Exp> inExpExpLst1;
  input list<DAE.Exp> inExpExpLst2;
  input Integer inInteger3;
  input Integer inInteger4;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst := matchcontinue (inExpExpLst1,inExpExpLst2,inInteger3,inInteger4)
    local
      BackendDAE.Value numnodes_1,numnodes,aindx;
      list<BackendDAE.Equation> res;
      list<DAE.Exp> inputs,outputs;
    case (_,_,0,_) then {};
    case (inputs,outputs,numnodes,aindx)
      equation
        numnodes_1 = numnodes - 1;
        res = lowerAlgorithm2(inputs, outputs, numnodes_1, aindx);
      then
        (BackendDAE.ALGORITHM(aindx,inputs,outputs,DAE.emptyElementSource) :: res);
  end matchcontinue;
end lowerAlgorithm2;

public function lowerAlgorithmInputsOutputs
"function: lowerAlgorithmInputsOutputs
  This function finds the inputs and the outputs of an algorithm.
  An input is all values that are reffered on the right hand side of any
  statement in the algorithm and an output is a variables belonging to the
  variables that are assigned a value in the algorithm."
  input BackendDAE.Variables inVariables;
  input DAE.Algorithm inAlgorithm;
  output tuple<list<DAE.Exp>,list<DAE.Exp>> outTplExpExpLst;
algorithm
  outTplExpExpLst := matchcontinue (inVariables,inAlgorithm)
    local
      list<DAE.Exp> inputs1,outputs1,inputs2,outputs2,inputs,outputs;
      BackendDAE.Variables vars;
      Algorithm.Statement s;
      list<Algorithm.Statement> ss;
    case (_,DAE.ALGORITHM_STMTS(statementLst = {})) then (({},{}));
    case (vars,DAE.ALGORITHM_STMTS(statementLst = (s :: ss)))
      equation
        (inputs1,outputs1) = lowerStatementInputsOutputs(vars, s);
        ((inputs2,outputs2)) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(ss));
        inputs = Util.listUnionOnTrue(inputs1, inputs2, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then
        ((inputs,outputs));
  end matchcontinue;
end lowerAlgorithmInputsOutputs;

protected function lowerStatementInputsOutputs
"function: lowerStatementInputsOutputs
  Helper relatoin to lowerAlgorithmInputsOutputs
  Investigates single statements. Returns DAE.Exp list
  instead of DAE.ComponentRef list because derivatives must
  be handled as well.
  inputs:  (Variables, /* vars */
              Algorithm.Statement)
  outputs: (DAE.Exp list, /* inputs, CREF or der(CREF)  */
              DAE.Exp list  /* outputs, CREF or der(CREF) */)"
  input BackendDAE.Variables inVariables;
  input Algorithm.Statement inStatement;
  output list<DAE.Exp> outExpExpLst1;
  output list<DAE.Exp> outExpExpLst2;
algorithm
  (outExpExpLst1,outExpExpLst2) := matchcontinue (inVariables,inStatement)
    local
      BackendDAE.Variables vars;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      DAE.Exp e, e2;
      list<Algorithm.Statement> statements;
      Algorithm.Statement stmt;
      list<DAE.Exp> expl;
      list<Algorithm.Statement> stmts;
      Algorithm.Else elsebranch;
      list<DAE.Exp> inputs,inputs1,inputs2,inputs3,outputs,outputs1,outputs2;
      list<DAE.ComponentRef> crefs;
      DAE.Exp exp1;
      list<DAE.Dimension> ad;
      list<list<DAE.Subscript>> subslst,subslst1;
      // a := expr;
    case (vars,DAE.STMT_ASSIGN(type_ = tp,exp1 = exp1,exp = e))
      equation
        inputs = BackendDAEUtil.statesAndVarsExp(e, vars);
      then
        (inputs,{exp1});
    case (vars,DAE.STMT_WHEN(exp = e,statementLst = statements,elseWhen = NONE()))
      equation
        ((inputs,outputs)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(statements));
        inputs2 = list_append(BackendDAEUtil.statesAndVarsExp(e, vars),inputs);
      then
        (inputs2,outputs);
    case (vars,DAE.STMT_WHEN(exp = e,statementLst = statements,elseWhen = SOME(stmt)))
      equation
        (inputs1, outputs1) = lowerStatementInputsOutputs(vars,stmt);
        ((inputs,outputs)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(statements));
        inputs2 = list_append(BackendDAEUtil.statesAndVarsExp(e, vars),inputs);
        outputs2 = list_append(outputs, outputs1);
      then
        (inputs2,outputs2);
      // (a,b,c) := foo(...)
    case (vars,DAE.STMT_TUPLE_ASSIGN(type_ = tp, expExpLst = expl, exp = e))
      equation
        inputs = BackendDAEUtil.statesAndVarsExp(e,vars);
        crefs = Util.listFlatten(Util.listMap(expl,Exp.getCrefFromExp));
        outputs =  Util.listMap1(crefs,Exp.makeCrefExp,DAE.ET_OTHER());
      then
        (inputs,outputs);

    // v := expr   where v is array.
    case (vars,DAE.STMT_ASSIGN_ARR(type_ = DAE.ET_ARRAY(ty=tp,arrayDimensions=ad), componentRef = cr, exp = e))
      equation
        inputs = BackendDAEUtil.statesAndVarsExp(e,vars);  
        subslst = DAELow.dimensionsToRange(ad);
        subslst1 = DAELow.rangesToSubscripts(subslst);
        crefs = Util.listMap1r(subslst1,Exp.subscriptCref,cr);
        expl = Util.listMap1(crefs,Exp.makeCrefExp,tp);             
      then (inputs,expl);

    case(vars,DAE.STMT_IF(exp = e, statementLst = stmts, else_ = elsebranch))
      equation
        ((inputs1,outputs1)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
        (inputs2,outputs2) = lowerElseAlgorithmInputsOutputs(vars,elsebranch);
        inputs3 = BackendDAEUtil.statesAndVarsExp(e,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2,inputs3}, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then (inputs,outputs);

    case(vars,DAE.STMT_ASSERT(cond = e1,msg=e2))
      local DAE.Exp e1,e2;
      equation
        inputs1 = BackendDAEUtil.statesAndVarsExp(e1,vars);
        inputs2 = BackendDAEUtil.statesAndVarsExp(e1,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2}, Exp.expEqual);
     then (inputs,{});

    case(vars, DAE.STMT_FOR(ident = iteratorName, exp = e, statementLst = stmts))
      local
        DAE.Ident iteratorName;
        DAE.Exp iteratorExp;
        list<DAE.Exp> arrayVars, nonArrayVars;
        list<list<DAE.Exp>> arrayElements;
        list<DAE.Exp> flattenedElements;
        DAE.ComponentRef cref_;
      equation
        ((inputs1,outputs1)) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(stmts));
        inputs2 = BackendDAEUtil.statesAndVarsExp(e, vars);
        // Split the output variables into variables that depend on the loop
        // variable and variables that don't.
        cref_ = ComponentReference.makeCrefIdent(iteratorName, DAE.ET_INT(), {});
        iteratorExp = DAE.CREF(cref_, DAE.ET_INT());
        (arrayVars, nonArrayVars) = Util.listSplitOnTrue1(outputs1, BackendDAEUtil.isLoopDependent, iteratorExp);
        arrayVars = Util.listMap(arrayVars, BackendDAEUtil.devectorizeArrayVar);
        // Explode array variables into their array elements.
        // I.e. var[i] => var[1], var[2], var[3] etc.
        arrayElements = Util.listMap3(arrayVars, BackendDAEUtil.explodeArrayVars, iteratorExp, e, vars);
        flattenedElements = Util.listFlatten(arrayElements);
        inputs = Util.listUnion(inputs1, inputs2);
        outputs = Util.listUnion(nonArrayVars, flattenedElements);
      then (inputs, outputs);
        
    case(vars, DAE.STMT_WHILE(exp = e, statementLst = stmts))
      equation
        ((inputs1,outputs)) = lowerAlgorithmInputsOutputs(vars, DAE.ALGORITHM_STMTS(stmts));
        inputs2 = BackendDAEUtil.statesAndVarsExp(e, vars);
        inputs = Util.listUnion(inputs1, inputs2);
      then (inputs, outputs);
        
    case(vars, DAE.STMT_NORETCALL(exp = e))
      equation
        inputs = BackendDAEUtil.statesAndVarsExp(e, vars);
      then
        (inputs, {});
    
    case(vars, DAE.STMT_REINIT(var = e as DAE.CREF(componentRef = _), value = e2))
      equation
        inputs = BackendDAEUtil.statesAndVarsExp(e2, vars);
      then
        (e :: inputs, {});
        
    case(_, _)
      equation
        Debug.fprintln("failtrace", "- DAELow.lowerStatementInputsOutputs failed\n");
      then 
        fail();
  end matchcontinue;
end lowerStatementInputsOutputs;

protected function lowerElseAlgorithmInputsOutputs
"Helper function to lowerStatementInputsOutputs"
  input BackendDAE.Variables vars;
  input Algorithm.Else elseBranch;
  output list<DAE.Exp> inputs;
  output list<DAE.Exp> outputs;
algorithm
  (inputs,outputs) := matchcontinue (vars,elseBranch)
    local
      list<Algorithm.Statement> stmts;
      list<DAE.Exp> inputs1,inputs2,inputs3,outputs1,outputs2;
      DAE.Exp e;

    case(vars,DAE.NOELSE()) then ({},{});

    case(vars,DAE.ELSEIF(e,stmts,elseBranch))
      equation
        (inputs1, outputs1) = lowerElseAlgorithmInputsOutputs(vars,elseBranch);
        ((inputs2, outputs2)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
        inputs3 = BackendDAEUtil.statesAndVarsExp(e,vars);
        inputs = Util.listListUnionOnTrue({inputs1, inputs2, inputs3}, Exp.expEqual);
        outputs = Util.listUnionOnTrue(outputs1, outputs2, Exp.expEqual);
      then (inputs,outputs);

    case(vars,DAE.ELSE(stmts))
      equation
        ((inputs, outputs)) = lowerAlgorithmInputsOutputs(vars,DAE.ALGORITHM_STMTS(stmts));
      then (inputs,outputs);
  end matchcontinue;
end lowerElseAlgorithmInputsOutputs;

/*
 *     other helping functions
 */

protected function processDelayExpressions
"Assign each call to delay() with a unique id argument"
  input DAE.DAElist inDAE;
  input DAE.FunctionTree functionTree;
  output DAE.DAElist outDAE;
  output DAE.FunctionTree outTree;
algorithm
  (outDAE,outTree) := matchcontinue(inDAE,functionTree)
    local
      DAE.DAElist dae, dae2;
    case (dae,functionTree)
      equation
        (dae,functionTree,_) = DAEUtil.traverseDAE(dae, functionTree, transformDelayExpressions, 0);
      then
        (dae,functionTree);
  end matchcontinue;
end processDelayExpressions;

protected function transformDelayExpressions
"Helper for processDelayExpressions()"
  input DAE.Exp inExp;
  input Integer inInteger;
  output DAE.Exp outExp;
  output Integer outInteger;
algorithm
  ((outExp, outInteger)) := Exp.traverseExp(inExp, transformDelayExpression, inInteger);
end transformDelayExpressions;

protected function transformDelayExpression
"Insert a unique index into the arguments of a delay() expression.
Repeat delay as maxDelay if not present."
  input tuple<DAE.Exp, Integer> inTuple;
  output tuple<DAE.Exp, Integer> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e, e1, e2, e3;
      Integer i;
      list<DAE.Exp> l;
      Boolean t, b;
      DAE.ExpType ty;
      DAE.InlineType it;
    case ((DAE.CALL(Absyn.IDENT("delay"), {e1, e2}, t, b, ty, it), i))
      then ((DAE.CALL(Absyn.IDENT("delay"), {DAE.ICONST(i), e1, e2, e2}, t, b, ty, it), i + 1));
    case ((DAE.CALL(Absyn.IDENT("delay"), {e1, e2, e3}, t, b, ty, it), i))
      then ((DAE.CALL(Absyn.IDENT("delay"), {DAE.ICONST(i), e1, e2, e3}, t, b, ty, it), i + 1));
    case ((e, i)) then ((e, i));
  end matchcontinue;
end transformDelayExpression;

protected function hasNoStates
"@author: adrpo
 this function tells if there are NO states in the binary tree"
  input BackendDAE.BinTree states;
  output Boolean out;
algorithm
  out := matchcontinue (states)
    // if the tree is empty then there are no states
    case (BackendDAE.TREENODE(NONE(),NONE(),NONE())) then true;
    case (_) then false;
  end matchcontinue;
end hasNoStates;

protected function addDummyState
"function: addDummyState
  In order for the solver to work correctly at least one state variable
  must exist in the equation system. This function therefore adds a
  dummy state variable and an equation for that variable.
  inputs:  (vars: Variables, eqns: BackendDAE.Equation list, bool)
  outputs: (Variables, BackendDAE.Equation list)"
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Equation> inEquationLst;
  input Boolean inBoolean;
  output BackendDAE.Variables outVariables;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  (outVariables,outEquationLst):=
  matchcontinue (inVariables,inEquationLst,inBoolean)
    local
      BackendDAE.Variables v,vars_1,vars;
      list<BackendDAE.Equation> e,eqns;
      DAE.ComponentRef cref_;
    case (v,e,false) then (v,e);
    case (vars,eqns,true) /* TODO::The dummy variable must be fixed */
      equation
        cref_ = ComponentReference.makeCrefIdent("$dummy",DAE.ET_REAL(),{});
        vars_1 = DAELow.addVar(BackendDAE.VAR(cref_, BackendDAE.STATE(),DAE.BIDIR(),BackendDAE.REAL(),NONE(),NONE(),{},-1,
                            DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(true)),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM()), vars);
      then
        /*
         * Add equation der(dummy) = sin(time*6628.318530717). This so the solver has something to solve
         * if the model does not contain states. To prevent the solver from taking larger and larger steps
         * (which would happen if der(dymmy) = 0) when using automatic, we have a osciallating derivative.
        (vars_1,(BackendDAE.EQUATION(
          DAE.CALL(Absyn.IDENT("der"),
          {DAE.CREF(cref_},false,true,DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sin"),{DAE.BINARY(
          	DAE.CREF(ComponentReference.makeCrefIdent("time",{}),DAE.ET_REAL()),
          	DAE.MUL(DAE.ET_REAL()),
          	DAE.RCONST(628.318530717))},false,true,DAE.ET_REAL()))  :: eqns)); */
        /*
         *
         * adrpo: after a bit of talk with Francesco Casella & Peter Aronsson we will add der($dummy) = 0;
         */
        (vars_1,(BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),
                          {DAE.CREF(cref_,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()),
                          DAE.RCONST(0.0), DAE.emptyElementSource)  :: eqns));

  end matchcontinue;
end addDummyState;

protected function detectImplicitDiscrete
"function: detectImplicitDiscrete
  This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Variables inVariables;
  input list<BackendDAE.Equation> inEquationLst;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables,inEquationLst)
    local
      BackendDAE.Variables v,v_1,v_2;
      DAE.ComponentRef cr,orig;
      DAE.VarDirection dir;
      BackendDAE.Type vartype;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dims;
      BackendDAE.Value ind;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Equation> xs;
    case (v,{}) then v;
    case (v,(BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr)) :: xs))
      equation
        ((BackendDAE.VAR(cr,_,dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix) :: _),_) = DAELow.getVar(cr, v);
        v_1 = DAELow.addVar(BackendDAE.VAR(cr,BackendDAE.DISCRETE(),dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix), v);
        v_2 = detectImplicitDiscrete(v_1, xs);
      then
        v_2;
        /* TODO: should also check when-algorithms */
    case (v,(_ :: xs))
      equation
        v_1 = detectImplicitDiscrete(v, xs);
      then
        v_1;
  end matchcontinue;
end detectImplicitDiscrete;

protected function sortEqn
"function: sortEqn
  This function sorts the equation. It puts first the algebraic eqns
  and last the differentiated eqns"
  input list<BackendDAE.Equation> inEquationLst;
  output list<BackendDAE.Equation> outEquationLst;
algorithm
  outEquationLst:=
  matchcontinue (inEquationLst)
    local list<BackendDAE.Equation> algEqns,diffEqns,res,eqns,resArrayEqns;
    case (eqns)
      equation
        (algEqns,diffEqns,resArrayEqns) = extractAlgebraicAndDifferentialEqn(eqns);
        res = Util.listFlatten({algEqns, diffEqns,resArrayEqns});
      then
        res;
    case (eqns)
      equation
        print("sort_eqn failed \n");
      then
        fail();
  end matchcontinue;
end sortEqn;

protected function extractAlgebraicAndDifferentialEqn
"function: extractAlgebraicAndDifferentialEqn

  Splits the equation list into two lists. One that only contain differential
  equations and one that only contain algebraic equations."
  input list<BackendDAE.Equation> inEquationLst;
  output list<BackendDAE.Equation> outEquationLst1;
  output list<BackendDAE.Equation> outEquationLst2;
  output list<BackendDAE.Equation> outEquationLst3;
algorithm
  (outEquationLst1,outEquationLst2,outEquationLst3):= matchcontinue (inEquationLst)
    local
      list<BackendDAE.Equation> resAlgEqn,resDiffEqn,rest,resArrayEqns;
      BackendDAE.Equation eqn,alg;
      DAE.Exp exp1,exp2;
      list<Boolean> bool_lst;
      BackendDAE.Value indx;
      list<DAE.Exp> expl;
    case ({}) then ({},{},{});  /* algebraic equations differential equations */
    case (((eqn as BackendDAE.EQUATION(exp = exp1,scalar = exp2)) :: rest)) /* scalar equation */
      equation
        true = isAlgebraic(exp1);
        true = isAlgebraic(exp2);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        ((eqn :: resAlgEqn),resDiffEqn,resArrayEqns);
    case (((eqn as BackendDAE.COMPLEX_EQUATION(lhs = exp1,rhs = exp2)) :: rest)) /* complex equation */
      equation
        true = isAlgebraic(exp1);
        true = isAlgebraic(exp2);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        ((eqn :: resAlgEqn),resDiffEqn,resArrayEqns);
    case (((eqn as BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl)) :: rest)) /* array equation */
      equation
        bool_lst = Util.listMap(expl, isAlgebraic);
        true = Util.boolAndList(bool_lst);
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,resDiffEqn,(eqn :: resArrayEqns));
    case (((eqn as BackendDAE.EQUATION(exp = exp1,scalar = exp2)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case (((eqn as BackendDAE.COMPLEX_EQUATION(lhs = exp1,rhs = exp2)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case (((eqn as BackendDAE.ARRAY_EQUATION(index = _)) :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest);
      then
        (resAlgEqn,(eqn :: resDiffEqn),resArrayEqns);
    case ((alg :: rest))
      equation
        (resAlgEqn,resDiffEqn,resArrayEqns) = extractAlgebraicAndDifferentialEqn(rest) "Put algorithms in algebraic equations" ;
      then
        ((alg :: resAlgEqn),resDiffEqn,resArrayEqns);
  end matchcontinue;
end extractAlgebraicAndDifferentialEqn;

protected function isAlgebraic "function: isAlgebraic
  author: PA

  This function returns true if an expression is purely algebraic, i.e. not
  containing any derivatives
  Otherwise it returns false.
"
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inExp)
    local
      BackendDAE.Value x,ival;
      String s,id;
      DAE.ComponentRef c;
      DAE.Exp e1,e2,e21,e22,e,t,f,stop,start,step,cr,dim,exp,iterexp;
      DAE.Operator op;
      DAE.ExpType ty,ty2,REAL;
      list<DAE.Exp> args,es,sub;
      Absyn.Path fcn;
    case (DAE.END()) then true;
    case (DAE.ICONST(integer = x)) then true;
    case (DAE.RCONST(real = x))
      local Real x;
      then
        true;
    case (DAE.SCONST(string = s)) then true;
    case (DAE.BCONST(bool = false)) then true;
    case (DAE.BCONST(bool = true)) then true;
    case (DAE.ENUM_LITERAL(name = _)) then true;

    case (DAE.CREF(componentRef = c)) then true;
    case (DAE.BINARY(exp1 = e1,operator = (op as DAE.SUB(ty = ty)),exp2 = (e2 as DAE.BINARY(exp1 = e21,operator = DAE.SUB(ty = ty2),exp2 = e22))))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.BINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.UNARY(operator = op,exp = e))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.LBINARY(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.LUNARY(operator = op,exp = e))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.RELATION(exp1 = e1,operator = op,exp2 = e2))
      equation
        true = isAlgebraic(e1);
        true = isAlgebraic(e2);
      then
        true;
    case (DAE.IFEXP(expCond = c,expThen = t,expElse = f))
      local DAE.Exp c;
      equation
        true = isAlgebraic(c);
        true = isAlgebraic(t);
        true = isAlgebraic(f);
      then
        true;
    case (DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = args)) then false;
    case (DAE.CALL(path = fcn,expLst = args)) then true;
    case (DAE.ARRAY(array = es)) then true;
    case (DAE.TUPLE(PR = es)) then true;
    case (DAE.MATRIX(scalar = es))
      local list<list<tuple<DAE.Exp, Boolean>>> es;
      then
        true;
    case (DAE.RANGE(exp = start,expOption = NONE(),range = stop))
      equation
        true = isAlgebraic(start);
        true = isAlgebraic(stop);
      then
        true;
    case (DAE.RANGE(exp = start,expOption = SOME(step),range = stop))
      equation
        true = isAlgebraic(start);
        true = isAlgebraic(step);
        true = isAlgebraic(stop);
      then
        true;
    case (DAE.CAST(ty = DAE.ET_REAL(),exp = e)) then true;
    case (DAE.ASUB(exp = e,sub = sub))
      equation
        true = isAlgebraic(e);
      then
        true;
    case (DAE.SIZE(exp = cr)) then true;
    case (DAE.REDUCTION(path = fcn,expr = exp,ident = id,range = iterexp)) then true;
    case (_) then true;
  end matchcontinue;
end isAlgebraic;

protected function expandDerOperator
"function expandDerOperator
  expands der(expr) using Derive.differentiteExpTime.
  This can not be done in Static, since we need all time-
  dependent variables, which is only available in DAELow."
  input BackendDAE.Variables vars;
  input list<BackendDAE.Equation> eqns;
  input list<BackendDAE.Equation> ieqns;
  input list<BackendDAE.MultiDimEquation> aeqns;
  input list<DAE.Algorithm> algs;
  input DAE.FunctionTree functions;

  output list<BackendDAE.Equation> outEqns;
  output list<BackendDAE.Equation> outIeqns;
  output list<BackendDAE.MultiDimEquation> outAeqns;
  output list<DAE.Algorithm> outAlgs;
  output BackendDAE.Variables outVars;
algorithm
  (outEqns, outIeqns,outAeqns,outAlgs,outVars) :=
  matchcontinue(vars,eqns,ieqns,aeqns,algs,functions)
    case(vars,eqns,ieqns,aeqns,algs,functions) equation
      (eqns,(vars,_)) = expandDerOperatorEqns(eqns,(vars,functions));
      (ieqns,(vars,_)) = expandDerOperatorEqns(ieqns,(vars,functions));
      (aeqns,(vars,_)) = expandDerOperatorArrEqns(aeqns,(vars,functions));
      (algs,(vars,_)) = expandDerOperatorAlgs(algs,(vars,functions));
    then(eqns,ieqns,aeqns,algs,vars);
  end matchcontinue;
end expandDerOperator;

protected function expandDerOperatorEqns
"Help function to expandDerOperator"
  input list<BackendDAE.Equation> eqns;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<BackendDAE.Equation> outEqns;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqns,outVars) := matchcontinue(eqns,vars)
  local BackendDAE.Equation e;
    case({},vars) then ({},vars);
    case(e::eqns,vars) equation
      (e,vars) = expandDerOperatorEqn(e,vars);
      (eqns,vars)  = expandDerOperatorEqns(eqns,vars);
    then (e::eqns,vars);
    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorEqns failed\n");
      then fail();
    end matchcontinue;
end expandDerOperatorEqns;

protected function expandDerOperatorEqn
"Help function to expandDerOperator, handles Equations"
  input BackendDAE.Equation eqn;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output BackendDAE.Equation outEqn;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqn,outVars) := matchcontinue(eqn,vars)
    local
      DAE.Exp e1,e2; list<DAE.Exp> expl; Integer i;
      DAE.ComponentRef cr; BackendDAE.WhenEquation wheneq;
      DAE.ElementSource source "the element source";

    case(BackendDAE.EQUATION(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (BackendDAE.EQUATION(e1,e2,source),vars);
    case(BackendDAE.COMPLEX_EQUATION(i,e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (BackendDAE.COMPLEX_EQUATION(i,e1,e2,source),vars);
    case  (BackendDAE.ARRAY_EQUATION(i,expl,source),vars)
    then (BackendDAE.ARRAY_EQUATION(i,expl,source),vars);
    case (BackendDAE.SOLVED_EQUATION(cr,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (BackendDAE.SOLVED_EQUATION(cr,e1,source),vars);
    case(BackendDAE.RESIDUAL_EQUATION(e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (BackendDAE.RESIDUAL_EQUATION(e1,source),vars);
    case (eqn as BackendDAE.ALGORITHM(index = _),vars) then (eqn,vars);
    case (BackendDAE.WHEN_EQUATION(wheneq,source),vars) equation
      (wheneq,vars) = expandDerOperatorWhenEqn(wheneq,vars);
    then (BackendDAE.WHEN_EQUATION(wheneq,source),vars);
    case (eqn ,vars) equation
      true = RTOpts.debugFlag("failtrace");
      Debug.fprint("failtrace", "- DAELow.expandDerOperatorEqn, eqn =");
      Debug.fprint("failtrace", BackendDump.equationStr(eqn));
      Debug.fprint("failtrace", " failed\n");
    then fail();
  end matchcontinue;
end expandDerOperatorEqn;

protected function expandDerOperatorWhenEqn
"Helper function to expandDerOperatorWhenEqn"
  input BackendDAE.WhenEquation wheneq;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output BackendDAE.WhenEquation outWheneq;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outWheneq, outVars) := matchcontinue(wheneq,vars)
    local DAE.ComponentRef cr; DAE.Exp e1; Integer indx; BackendDAE.WhenEquation elsewheneq;
    case(BackendDAE.WHEN_EQ(indx,cr,e1,SOME(elsewheneq)),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (elsewheneq,vars) = expandDerOperatorWhenEqn(elsewheneq,vars);
    then (BackendDAE.WHEN_EQ(indx,cr,e1,SOME(elsewheneq)),vars);

    case(BackendDAE.WHEN_EQ(indx,cr,e1,NONE()),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (BackendDAE.WHEN_EQ(indx,cr,e1,NONE()),vars);
  end matchcontinue;
end expandDerOperatorWhenEqn;

protected function expandDerOperatorAlgs
"Help function to expandDerOperator"
  input list<DAE.Algorithm> algs;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<DAE.Algorithm> outAlgs;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outAlgs,outVars) := matchcontinue(algs,vars)
  local DAE.Algorithm a;
    case({},vars) then ({},vars);
    case(a::algs,vars) equation
      (a,vars) = expandDerOperatorAlg(a,vars);
      (algs,vars)  = expandDerOperatorAlgs(algs,vars);
    then (a::algs,vars);

    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorAlgs failed\n");
      then fail();

  end matchcontinue;
end expandDerOperatorAlgs;

protected function expandDerOperatorAlg
"Help function to to expandDerOperator, handles Algorithms"
  input DAE.Algorithm alg;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output DAE.Algorithm outAlg;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outAlg,outVars) := matchcontinue(alg,vars)
  local list<Algorithm.Statement> stmts;
    case(DAE.ALGORITHM_STMTS(stmts),vars) equation
      (stmts,vars)  = expandDerOperatorStmts(stmts,vars);
    then (DAE.ALGORITHM_STMTS(stmts),vars);
  end matchcontinue;
end expandDerOperatorAlg;

protected function expandDerOperatorStmts
"Help function to expandDerOperatorAlg"
  input list<Algorithm.Statement> stmts;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<Algorithm.Statement> outStmts;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outStmts,outVars) := matchcontinue(stmts,vars)
  local Algorithm.Statement s;
    case({},vars) then ({},vars);
    case(s::stmts,vars) equation
      (s,vars) = expandDerOperatorStmt(s,vars);
      (stmts,vars)  = expandDerOperatorStmts(stmts,vars);
      then (s::stmts,vars);
  end matchcontinue;
end expandDerOperatorStmts;

protected function expandDerOperatorStmt
"Help function to expandDerOperatorAlg."
  input Algorithm.Statement stmt;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output Algorithm.Statement outStmt;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outStmt,outVars) := matchcontinue(stmt,vars)
    local DAE.ExpType tp; DAE.ComponentRef cr;
      list<DAE.Exp> expl;
      Algorithm.Ident id; Boolean b;
      list<Algorithm.Statement> stmts;
      list<Integer> hv;
      Algorithm.Statement stmt;
      DAE.Exp e1,e2;
      Algorithm.Else elseB;
      DAE.ElementSource source;

    case(DAE.STMT_ASSIGN(tp,e2,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_ASSIGN(tp,e2,e1,source),vars);

    case(DAE.STMT_TUPLE_ASSIGN(tp,expl,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (expl,vars) = expandDerExps(expl,vars);
    then (DAE.STMT_TUPLE_ASSIGN(tp,expl,e1,source),vars);

    case(DAE.STMT_ASSIGN_ARR(tp,cr,e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_ASSIGN_ARR(tp,cr,e1,source),vars);

    case(DAE.STMT_IF(e1,stmts,elseB,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (elseB,vars) = expandDerOperatorElseBranch(elseB,vars);
    then (DAE.STMT_IF(e1,stmts,elseB,source),vars);

    case(DAE.STMT_FOR(tp,b,id,e1,stmts,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_FOR(tp,b,id,e1,stmts,source),vars);

    case(DAE.STMT_WHILE(e1,stmts,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHILE(e1,stmts,source),vars);

    case(DAE.STMT_WHEN(e1,stmts,SOME(stmt),hv,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (stmt,vars) = expandDerOperatorStmt(stmt,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHEN(e1,stmts,SOME(stmt),hv,source),vars);

    case(DAE.STMT_WHEN(e1,stmts,NONE(),hv,source),vars) equation
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_WHEN(e1,stmts,NONE(),hv,source),vars);

    case(DAE.STMT_ASSERT(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_ASSERT(e1,e2,source),vars);

    case(DAE.STMT_TERMINATE(e1,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
    then (DAE.STMT_TERMINATE(e1,source),vars);

    case(DAE.STMT_REINIT(e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e1,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (DAE.STMT_REINIT(e1,e2,source),vars);

    case(stmt,vars)      then (stmt,vars);

  end matchcontinue;
end  expandDerOperatorStmt;

protected function expandDerOperatorElseBranch
"Help function to expandDerOperatorStmt, for else branches in if statements"
  input Algorithm.Else elseB;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output Algorithm.Else outElseB;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outElseB,outVars) := matchcontinue(elseB,vars)
    local DAE.Exp e1;
      list<Algorithm.Statement> stmts;
      Algorithm.Else elseB;

    case(DAE.NOELSE(),vars) then (DAE.NOELSE(),vars);

    case(DAE.ELSEIF(e1,stmts,elseB),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      (stmts,vars) = expandDerOperatorStmts(stmts,vars);
      (elseB,vars) = expandDerOperatorElseBranch(elseB,vars);
    then (DAE.ELSEIF(e1,stmts,elseB),vars);
  end matchcontinue;
end expandDerOperatorElseBranch;

protected function expandDerOperatorArrEqns
"Help function to expandDerOperator"
  input list<BackendDAE.MultiDimEquation> eqns;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<BackendDAE.MultiDimEquation> outEqns;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outEqns,outVars) := matchcontinue(eqns,vars)
  local BackendDAE.MultiDimEquation e;
    case({},vars) then ({},vars);
    case(e::eqns,vars) equation
      (e,vars) = expandDerOperatorArrEqn(e,vars);
      (eqns,vars)  = expandDerOperatorArrEqns(eqns,vars);
    then (e::eqns,vars);

    case(_,_) equation
      Debug.fprint("failtrace", "-DAELow.expandDerOperatorArrEqns failed\n");
    then fail();
  end matchcontinue;
end expandDerOperatorArrEqns;

protected function expandDerOperatorArrEqn
"Help function to to expandDerOperator, handles Array equations"
  input BackendDAE.MultiDimEquation arrEqn;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output BackendDAE.MultiDimEquation outArrEqn;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outArrEqn,outVars) := matchcontinue(arrEqn,vars)
    local
      list<Integer> dims; DAE.Exp e1,e2;
      DAE.ElementSource source "the element source";

    case(BackendDAE.MULTIDIM_EQUATION(dims,e1,e2,source),vars) equation
      ((e1,vars)) = Exp.traverseExp(e1,expandDerExp,vars);
      ((e2,vars)) = Exp.traverseExp(e2,expandDerExp,vars);
    then (BackendDAE.MULTIDIM_EQUATION(dims,e1,e2,source),vars);
  end matchcontinue;
end expandDerOperatorArrEqn;

protected function expandDerExps
"Help function to e.g. expandDerOperatorEqn"
  input list<DAE.Exp> expl;
  input tuple<BackendDAE.Variables,DAE.FunctionTree> vars;
  output list<DAE.Exp> outExpl;
  output tuple<BackendDAE.Variables,DAE.FunctionTree> outVars;
algorithm
  (outExpl,outVars) := matchcontinue(expl,vars)
    local DAE.Exp e;
    case({},vars) then ({},vars);
    case(e::expl,vars) equation
      ((e,vars)) = expandDerExp((e,vars));
      (expl,vars) = expandDerExps(expl,vars);
    then (e::expl,vars);
  end matchcontinue;
end expandDerExps;

protected function expandDerExp
"Help function to e.g. expandDerOperatorEqn"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,DAE.FunctionTree>> tpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,DAE.FunctionTree>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local DAE.Exp inExp;
      BackendDAE.Variables vars;
      BackendDAE.BinTree bt;
      DAE.FunctionTree funcs;
      DAE.Exp e1;
      list<DAE.ComponentRef> newStates;
    case((DAE.CALL(Absyn.IDENT(name = "der"),{e1},tuple_ = false,builtin = true),(vars,funcs))) equation
      e1 = Derive.differentiateExpTime(e1,(vars,funcs));
      e1 = Exp.simplify(e1);
      bt = BackendDAEUtil.statesExp(e1,BackendDAE.emptyBintree);
      (newStates,_) = BackendDAEUtil.bintreeToList(bt);
      vars = updateStatesVars(vars,newStates);
    then ((e1,(vars,funcs)));
    case((e1,(vars,funcs))) then ((e1,(vars,funcs)));
  end matchcontinue;
end expandDerExp;

protected function updateStatesVars
"Help function to expandDerExp"
  input BackendDAE.Variables vars;
  input list<DAE.ComponentRef> newStates;
  output BackendDAE.Variables outVars;
algorithm
  outVars := matchcontinue(vars,newStates)
    local
      DAE.ComponentRef cr1;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type vartype;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dims;
      BackendDAE.Value ind;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ComponentRef cr;

    case(vars,{}) then vars;
    case(vars,cr::newStates)
      equation
        ((BackendDAE.VAR(cr1,kind,dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix) :: _),_) = DAELow.getVar(cr, vars);
        vars = DAELow.addVar(BackendDAE.VAR(cr1,BackendDAE.STATE(),dir,vartype,bind,value,dims,ind,source,attr,comment,flowPrefix,streamPrefix), vars);
        vars = updateStatesVars(vars,newStates);
      then vars;
    case(vars,cr::newStates)
      equation
        print("Internal error, variable ");print(Exp.printComponentRefStr(cr));print("not found in variables.\n");
        vars = updateStatesVars(vars,newStates);
      then vars;
  end matchcontinue;
end updateStatesVars;


protected function zeroCrossingEquations
"Returns the list of equations (indices) from a ZeroCrossing"
  input BackendDAE.ZeroCrossing zc;
  output list<Integer> lst;
algorithm
  lst := matchcontinue(zc)
    case(BackendDAE.ZERO_CROSSING(_,lst,_)) then lst;
  end matchcontinue;
end zeroCrossingEquations;

protected function mergeZeroCrossings
"function: mergeZeroCrossings
  Takes a list of zero crossings and if more than one have identical
  function expressions they are merged into one zerocrossing.
  In the resulting list all zerocrossing have uniq function expressions."
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst:=
  matchcontinue (inZeroCrossingLst)
    local
      BackendDAE.ZeroCrossing zc,same_1;
      list<BackendDAE.ZeroCrossing> samezc,diff,diff_1,xs;
    case {} then {};
    case {zc} then {zc};
    case (zc :: xs)
      equation
        samezc = Util.listSelect1(xs, zc, sameZeroCrossing);
        diff = Util.listSelect1(xs, zc, differentZeroCrossing);
        diff_1 = mergeZeroCrossings(diff);
        same_1 = Util.listFold(samezc, mergeZeroCrossing, zc);
      then
        (same_1 :: diff_1);
  end matchcontinue;
end mergeZeroCrossings;

protected function mergeZeroCrossing "function: mergeZeroCrossing

  Merges two zero crossings into one by makeing the union of the lists of
  equaions and when clauses they appear in.
"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing:=
  matchcontinue (inZeroCrossing1,inZeroCrossing2)
    local
      list<BackendDAE.Value> eq,zc,eq1,wc1,eq2,wc2;
      DAE.Exp e1,e2;
    case (BackendDAE.ZERO_CROSSING(relation_ = e1,occurEquLst = eq1,occurWhenLst = wc1),BackendDAE.ZERO_CROSSING(relation_ = e2,occurEquLst = eq2,occurWhenLst = wc2))
      equation
        eq = Util.listUnion(eq1, eq2);
        zc = Util.listUnion(wc1, wc2);
      then
        BackendDAE.ZERO_CROSSING(e1,eq,zc);
  end matchcontinue;
end mergeZeroCrossing;

protected function sameZeroCrossing "function: sameZeroCrossing

  Returns true if both zero crossings have the same function expression
"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inZeroCrossing1,inZeroCrossing2)
    local
      Boolean res;
      DAE.Exp e1,e2;
    case (BackendDAE.ZERO_CROSSING(relation_ = e1),BackendDAE.ZERO_CROSSING(relation_ = e2))
      equation
        res = Exp.expEqual(e1, e2);
      then
        res;
  end matchcontinue;
end sameZeroCrossing;

protected function differentZeroCrossing "function: differentZeroCrossing

  Return true if the realation expressions differ.
"
  input BackendDAE.ZeroCrossing zc1;
  input BackendDAE.ZeroCrossing zc2;
  output Boolean res_1;
  Boolean res,res_1;
algorithm
  res := sameZeroCrossing(zc1, zc2);
  res_1 := boolNot(res);
end differentZeroCrossing;

public function findZeroCrossings "function: findZeroCrossings

  This function finds all zerocrossings in the list of equations and
  the list of when clauses. Used in lower2.
"
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> eq;
  input list<BackendDAE.MultiDimEquation> multiDimEqs;
  input list<BackendDAE.WhenClause> wc;
  input list<DAE.Algorithm> algs;
  output list<BackendDAE.ZeroCrossing> res_1;
  list<BackendDAE.ZeroCrossing> res,res_1;
algorithm
  res := findZeroCrossings2(vars, knvars,eq,multiDimEqs,1, wc, 1, algs);
  res_1 := mergeZeroCrossings(res);
end findZeroCrossings;

protected function findZeroCrossings2 "function: findZeroCrossings2

  Helper function to find_zero_crossing.
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> inEquationLst2;
  input list<BackendDAE.MultiDimEquation> inMultiDimEqs;
  input Integer inInteger3;
  input list<BackendDAE.WhenClause> inWhenClauseLst4;
  input Integer inInteger5;
  input list<DAE.Algorithm> algs;

  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst:=
  matchcontinue (inVariables1,knvars,inEquationLst2,inMultiDimEqs,inInteger3,inWhenClauseLst4,inInteger5,algs)
    local
      BackendDAE.Variables v;
      list<DAE.Exp> rellst1,rellst2,rel;
      list<BackendDAE.ZeroCrossing> zc1,zc2,zc3,zc4,res,res1,res2;
      list<BackendDAE.MultiDimEquation> mdeqs;
      BackendDAE.Value eq_count_1,eq_count,wc_count_1,wc_count;
      BackendDAE.Equation e;
      DAE.Exp e1,e2;
      list<BackendDAE.Equation> xs,el;
      BackendDAE.WhenClause wc;
      Integer ind;
      DAE.ElementSource source "the element source";

    case (v,knvars,{},_,_,{},_,_) then {};
    case (v,knvars,((e as BackendDAE.EQUATION(exp = e1,scalar = e2)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        rellst2 = findZeroCrossings3(e2, v,knvars);
        zc2 = makeZeroCrossings(rellst2, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        zc4 = listAppend(zc1, zc2);
        res = listAppend(zc3, zc4);
      then
        res;
    case (v,knvars,((e as BackendDAE.COMPLEX_EQUATION(lhs = e1,rhs = e2)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        rellst2 = findZeroCrossings3(e2, v,knvars);
        zc2 = makeZeroCrossings(rellst2, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        zc4 = listAppend(zc1, zc2);
        res = listAppend(zc3, zc4);
      then
        res;
    case (v,knvars,((e as BackendDAE.ARRAY_EQUATION(index = ind)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        // Find the correct multidim equation from the index
        BackendDAE.MULTIDIM_EQUATION(left=e1,right=e2,source=source) = listNth(mdeqs,ind);
        e = BackendDAE.EQUATION(e1,e2,source);
        res = findZeroCrossings2(v,knvars,e::xs,mdeqs,eq_count,{},0,algs);
      then
        res;
    case (v,knvars,((e as BackendDAE.SOLVED_EQUATION(exp = e1)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1, v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        res = listAppend(zc3, zc1);
      then
        res;
    case (v,knvars,((e as BackendDAE.RESIDUAL_EQUATION(exp = e1)) :: xs),mdeqs,eq_count,{},_,algs)
      equation
        rellst1 = findZeroCrossings3(e1,v,knvars);
        zc1 = makeZeroCrossings(rellst1, {eq_count}, {});
        eq_count_1 = eq_count + 1;
        zc3 = findZeroCrossings2(v, knvars,xs,mdeqs,eq_count_1, {}, 0,algs);
        res = listAppend(zc3, zc1);
      then
        res;
    case (v,knvars,((e as BackendDAE.ALGORITHM(index = ind)) :: xs),mdeqs,eq_count,{},_,algs)
      local
        list<Algorithm.Statement> stmts;
      equation
        eq_count_1 = eq_count + 1;
        zc1 = findZeroCrossings2(v,knvars,xs,mdeqs,eq_count_1,{},0,algs);
        DAE.ALGORITHM_STMTS(stmts) = listNth(algs,ind);
        rel = Algorithm.getAllExpsStmts(stmts);
        rellst1 = Util.listFlatten(Util.listMap2(rel,findZeroCrossings3,v,knvars));
        zc2 = makeZeroCrossings(rellst1, {eq_count}, {});
        res = listAppend(zc2, zc1);
      then
        res;
    case (v,knvars,(e :: xs),mdeqs,eq_count,{},_,algs)
      equation
        eq_count_1 = eq_count + 1;
        (res) = findZeroCrossings2(v,knvars, xs,mdeqs,eq_count_1, {}, 0,algs);
      then
        res;
    case (v,knvars,el,mdeqs,eq_count,((wc as BackendDAE.WHEN_CLAUSE(condition = e)) :: xs),wc_count,algs)
      local
        DAE.Exp e;
        list<BackendDAE.WhenClause> xs;
      equation
        wc_count_1 = wc_count + 1;
        (res1) = findZeroCrossings2(v, knvars,el,mdeqs,eq_count, xs, wc_count_1,algs);
        rel = findZeroCrossings3(e, v,knvars);
        res2 = makeZeroCrossings(rel, {}, {wc_count});
        res = listAppend(res1, res2);
      then
        res;
  end matchcontinue;
end findZeroCrossings2;

protected function findZeroCrossings3
"function: findZeroCrossings3
  Helper function to findZeroCrossing."
  input DAE.Exp e;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output list<DAE.Exp> zeroCrossings;
algorithm
  ((_,(zeroCrossings,_))) := Exp.traverseExp(e, collectZeroCrossings, ({},(vars,knvars)));
end findZeroCrossings3;

public function zeroCrossingsEquations
"Returns a list of all equations (by their index) that contain a zero crossing
 Used e.g. to find out which discrete equations are not part of a zero crossing"
  input BackendDAE.DAELow dae;
  output list<Integer> eqns;
algorithm
  eqns := matchcontinue(dae)
    case (BackendDAE.DAELOW(eventInfo=BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst),orderedEqs=eqnArr)) local
      list<BackendDAE.ZeroCrossing> zcLst;
      list<list<Integer>> zcEqns;
      list<Integer> wcEqns;
      BackendDAE.EquationArray eqnArr;
      equation
        zcEqns = Util.listMap(zcLst,zeroCrossingEquations);
        wcEqns = whenEquationsIndices(eqnArr);
        eqns = Util.listListUnion(listAppend(zcEqns,{wcEqns}));
      then eqns;
  end matchcontinue;
end zeroCrossingsEquations;


protected function collectZeroCrossings "function: collectZeroCrossings

  Collects zero crossings
"
  input tuple<DAE.Exp, tuple<list<DAE.Exp>, tuple<BackendDAE.Variables,BackendDAE.Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, tuple<list<DAE.Exp>, tuple<BackendDAE.Variables,BackendDAE.Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      DAE.Exp e,e1,e2,e_1;
      BackendDAE.Variables vars,knvars;
      list<DAE.Exp> zeroCrossings,zeroCrossings_1,zeroCrossings_2,zeroCrossings_3,el;
      DAE.Operator op;
      DAE.ExpType tp;
      Boolean scalar;
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))),(zeroCrossings,(vars,knvars)))) then ((e,({},(vars,knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))),(zeroCrossings,(vars,knvars)))) then ((e,((e :: zeroCrossings),(vars,knvars))));

    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(zeroCrossings,(vars,knvars)))) /* function with discrete expressions generate no zerocrossing */
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars,knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars,knvars);
      then
        ((e,(zeroCrossings,(vars,knvars))));
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(zeroCrossings,(vars,knvars))))
      equation
      then ((e,((e :: zeroCrossings),(vars,knvars))));  /* All other functions generate zerocrossing. */
    case (((e as DAE.ARRAY(array = {})),(zeroCrossings,(vars,knvars))))
      equation
      then ((e,(zeroCrossings,(vars,knvars))));
    case ((e1 as DAE.ARRAY(ty = tp,scalar = scalar,array = (e :: el)),(zeroCrossings,(vars,knvars))))
      equation
        ((_,(zeroCrossings_1,(vars,knvars)))) = Exp.traverseExp(e, collectZeroCrossings, (zeroCrossings,(vars,knvars)));
        ((e_1,(zeroCrossings_2,(vars,knvars)))) = collectZeroCrossings((DAE.ARRAY(tp,scalar,el),(zeroCrossings,(vars,knvars))));
        zeroCrossings_3 = listAppend(zeroCrossings_1, zeroCrossings_2);
      then
        ((e1,(zeroCrossings_3,(vars,knvars))));
    case ((e,(zeroCrossings,(vars,knvars))))
      equation
      then ((e,(zeroCrossings,(vars,knvars))));
  end matchcontinue;
end collectZeroCrossings;

protected function makeZeroCrossing
"function: makeZeroCrossing
  Constructs a BackendDAE.ZeroCrossing from an expression and lists of equation indices
  and when clause indices."
  input DAE.Exp inExp1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := matchcontinue (inExp1,inIntegerLst2,inIntegerLst3)
    local
      DAE.Exp e;
      list<BackendDAE.Value> eq_ind,wc_ind;
    case (e,eq_ind,wc_ind) then BackendDAE.ZERO_CROSSING(e,eq_ind,wc_ind);
  end matchcontinue;
end makeZeroCrossing;

protected function makeZeroCrossings
"function: makeZeroCrossings
  Constructs a list of ZeroCrossings from a list expressions
  and lists of equation indices and when clause indices.
  Each Zerocrossing gets the same lists of indicies."
  input list<DAE.Exp> inExpExpLst1;
  input list<Integer> inIntegerLst2;
  input list<Integer> inIntegerLst3;
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
algorithm
  outZeroCrossingLst := matchcontinue (inExpExpLst1,inIntegerLst2,inIntegerLst3)
    local
      BackendDAE.ZeroCrossing res;
      list<BackendDAE.ZeroCrossing> resx;
      DAE.Exp e;
      list<DAE.Exp> xs;
      list<BackendDAE.Value> eq_ind,wc_ind;
    case ({},_,_) then {};
    case ((e :: xs),eq_ind,wc_ind)
      equation
        res = makeZeroCrossing(e, eq_ind, wc_ind);
        resx = makeZeroCrossings(xs, eq_ind, wc_ind);
      then
        (res :: resx);
  end matchcontinue;
end makeZeroCrossings;

protected function makeWhenClauses
"function: makeWhenClauses
  Constructs a list of identical BackendDAE.WhenClause elements
  Arg1: Number of elements to construct
  Arg2: condition expression of the when clause
  outputs: (WhenClause list)"
  input Integer n           "Number of copies to make.";
  input DAE.Exp inCondition "the condition expression";
  input list<BackendDAE.ReinitStatement> inReinitStatementLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  outWhenClauseLst:=
  matchcontinue (n,inCondition,inReinitStatementLst)
    local
      BackendDAE.Value i_1,i;
      list<BackendDAE.WhenClause> res;
      DAE.Exp cond;
      list<BackendDAE.ReinitStatement> reinit;

    case (0,_,_) then {};
    case (i,cond,reinit)
      equation
        i_1 = i - 1;
        res = makeWhenClauses(i_1, cond, reinit);
      then
        (BackendDAE.WHEN_CLAUSE(cond,reinit,NONE()) :: res);
  end matchcontinue;
end makeWhenClauses;

protected function mergeClauses
"function mergeClauses
   merges the true part end the elsewhen part of a set of when equations.
   For each equation in trueEqnList, find an equation in elseEqnList solving
   the same variable and put it in the else elseWhenPart of the first equation."
  input list<BackendDAE.Equation> trueEqnList "List of equations in the true part of the when clause.";
  input list<BackendDAE.Equation> elseEqnList "List of equations in the elsewhen part of the when clause.";
  input list<BackendDAE.WhenClause> trueClauses "List of when clauses from the true part.";
  input list<BackendDAE.WhenClause> elseClauses "List of when clauses from the elsewhen part.";
  input Integer nextWhenClauseIndex  "Next available when clause index.";
  output list<BackendDAE.Equation> outEquationLst;
  output Integer outWhenClauseIndex;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  (outEquationLst,outWhenClauseIndex,outWhenClauseLst) :=
  matchcontinue (trueEqnList, elseEqnList, trueClauses, elseClauses, nextWhenClauseIndex)
    local
      DAE.ComponentRef cr;
      DAE.Exp rightSide;
      Integer ind;
      BackendDAE.Equation res;
      list<BackendDAE.Equation> trueEqns;
      list<BackendDAE.Equation> elseEqns;
      list<BackendDAE.WhenClause> trueCls;
      list<BackendDAE.WhenClause> elseCls;
      Integer nextInd;
      list<BackendDAE.Equation> resRest;
      Integer outNextIndex;
      list<BackendDAE.WhenClause> outClauseList;
      BackendDAE.WhenEquation foundEquation;
      list<BackendDAE.Equation> elseEqnsRest;
      DAE.ElementSource source "the element source";

    case (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(index = ind,left = cr,right=rightSide),source)::trueEqns, elseEqns,trueCls,elseCls,nextInd)
      equation
        (foundEquation, elseEqnsRest) = getWhenEquationFromVariable(cr,elseEqns);
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(ind,cr,rightSide,SOME(foundEquation)),source);
        (resRest, outNextIndex, outClauseList) = mergeClauses(trueEqns,elseEqnsRest,trueCls, elseCls,nextInd);
      then (res::resRest, outNextIndex, outClauseList);

    case ({},{},trueCls,elseCls,nextInd) then ({},nextInd,listAppend(trueCls,elseCls));

    case (_,_,_,_,_)
      equation
        print("- DAELow.mergeClauses: Error in mergeClauses.\n");
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
  (outEquation, outEquations) := matchcontinue(inCr,inEquations)
    local
      DAE.ComponentRef cr1,cr2;
      BackendDAE.WhenEquation eq;
      BackendDAE.Equation eq2;
      list<BackendDAE.Equation> rest, rest2;

    case (cr1,BackendDAE.WHEN_EQUATION(eq as BackendDAE.WHEN_EQ(left=cr2),_)::rest)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr1,cr2);
      then (eq, rest);

    case (cr1,(eq2 as BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(left=cr2),_))::rest)
      equation
        false = ComponentReference.crefEqualNoStringCompare(cr1,cr2);
        (eq,rest2) = getWhenEquationFromVariable(cr1,rest);
      then (eq, eq2::rest2);

    case (_,{})
      equation
        Error.addMessage(Error.DIFFERENT_VARIABLES_SOLVED_IN_ELSEWHEN, {});
      then
        fail();
  end matchcontinue;
end getWhenEquationFromVariable;

protected function extendRecordEqns "
Author: Frenkel TUD 2010-05"
  input BackendDAE.Equation inEqn;
  input DAE.FunctionTree inFuncs;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.MultiDimEquation>> outTuplEqnLst;
algorithm 
  outTuplEqnLst := matchcontinue(inEqn,inFuncs)
  local
    DAE.FunctionTree funcs;
    BackendDAE.Equation eqn;
    DAE.ComponentRef cr1,cr2;
    DAE.Exp e1,e2;
    list<DAE.Exp> e1lst,e2lst;
    list<DAE.ExpVar> varLst;
    Integer i;
    list<tuple<list<BackendDAE.Equation>,list<BackendDAE.MultiDimEquation>>> compmultilistlst,compmultilistlst1;
    list<list<BackendDAE.MultiDimEquation>> multiEqsLst,multiEqsLst1;
    list<list<BackendDAE.Equation>> complexEqsLst,complexEqsLst1;
    list<BackendDAE.MultiDimEquation> multiEqs,multiEqs1,multiEqs2;  
    list<BackendDAE.Equation> complexEqs,complexEqs1;  
    DAE.ElementSource source;  
    Absyn.Path path,fname;
    list<DAE.Exp> expLst;
    list<tuple<DAE.Exp,DAE.Exp>> exptpllst;
  // a=b
  case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1 as DAE.CREF(componentRef=cr1), rhs = e2  as DAE.CREF(componentRef=cr2),source = source),funcs)
    equation
      // create as many equations as the dimension of the record
      DAE.ET_COMPLEX(varLst=varLst) = Exp.crefLastType(cr1);
      e1lst = Util.listMap1(varLst,DAELow.generateCrefsExpFromType,e1);
      e2lst = Util.listMap1(varLst,DAELow.generateCrefsExpFromType,e2);
      exptpllst = Util.listThreadTuple(e1lst,e2lst);
      compmultilistlst = Util.listMap2(exptpllst,DAELow.generateextendedRecordEqn,source,funcs);
      complexEqsLst = Util.listMap(compmultilistlst,Util.tuple21);
      multiEqsLst = Util.listMap(compmultilistlst,Util.tuple22);
      complexEqs = Util.listFlatten(complexEqsLst);
      multiEqs = Util.listFlatten(multiEqsLst);
      // nested Records
      compmultilistlst1 = Util.listMap1(complexEqs,extendRecordEqns,funcs);
      complexEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple21);
      multiEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple22);
      complexEqs1 = Util.listFlatten(complexEqsLst1);
      multiEqs1 = Util.listFlatten(multiEqsLst1);
      multiEqs2 = listAppend(multiEqs,multiEqs1);
    then
      ((complexEqs1,multiEqs2)); 
  // a=Record()
  case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1 as DAE.CREF(componentRef=cr1), rhs = e2  as DAE.CALL(path=path,expLst=expLst),source = source),funcs)
    equation
      SOME(DAE.RECORD_CONSTRUCTOR(path=fname)) = DAEUtil.avlTreeGet(funcs,path);
      // create as many equations as the dimension of the record
      DAE.ET_COMPLEX(varLst=varLst) = Exp.crefLastType(cr1);
      e1lst = Util.listMap1(varLst,DAELow.generateCrefsExpFromType,e1);
      exptpllst = Util.listThreadTuple(e1lst,expLst);
      compmultilistlst = Util.listMap2(exptpllst,DAELow.generateextendedRecordEqn,source,funcs);
      complexEqsLst = Util.listMap(compmultilistlst,Util.tuple21);
      multiEqsLst = Util.listMap(compmultilistlst,Util.tuple22);
      complexEqs = Util.listFlatten(complexEqsLst);
      multiEqs = Util.listFlatten(multiEqsLst);
      // nested Records
      compmultilistlst1 = Util.listMap1(complexEqs,extendRecordEqns,funcs);
      complexEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple21);
      multiEqsLst1 = Util.listMap(compmultilistlst1,Util.tuple22);
      complexEqs1 = Util.listFlatten(complexEqsLst1);
      multiEqs1 = Util.listFlatten(multiEqsLst1);
      multiEqs2 = listAppend(multiEqs,multiEqs1);
    then
      ((complexEqs1,multiEqs2)); 
  case(eqn,_) then (({eqn},{}));      
end matchcontinue;
end extendRecordEqns;

protected function isStateOrAlgvar
  "@author adrpo
   check if this variable is a state or algebraic"
  input DAE.Element e;
  output Boolean out;
algorithm
  out := matchcontinue(e)
    case (DAE.VAR(kind = DAE.VARIABLE())) then true;
    case (DAE.VAR(kind = DAE.DISCRETE())) then true;
    case (_) then false;
  end matchcontinue;
end isStateOrAlgvar;

protected function extendAlgorithm "
Author: Frenkel TUD 2010-07"
  input DAE.Algorithm inAlg;
  input Option<DAE.FunctionTree> funcs;  
  output DAE.Algorithm outAlg;
algorithm 
  outAlg := matchcontinue(inAlg,funcs)
    local list<DAE.Statement> statementLst;
    case(DAE.ALGORITHM_STMTS(statementLst=statementLst),funcs)
      equation
        (statementLst,_) = DAEUtil.traverseDAEEquationsStmts(statementLst, DAELow.extendArrExp, funcs);
      then
        DAE.ALGORITHM_STMTS(statementLst);
    case(inAlg,funcs) then inAlg;        
  end matchcontinue;
end extendAlgorithm;

protected function mergeVars
"function: mergeVars
  author: PA
  Takes two sets of BackendDAE.Variables and merges them. The variables of the
  first argument takes precedence over the second set, i.e. if a
  variable name exists in both sets, the variable definition from
  the first set is used."
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables inVariables2;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables1,inVariables2)
    local
      list<BackendDAE.Var> varlst;
      BackendDAE.Variables vars1_1,vars1,vars2;
    case (vars1,vars2)
      equation
        varlst = BackendDAEUtil.varList(vars2);
        vars1_1 = Util.listFold(varlst, DAELow.addVar, vars1);
      then
        vars1_1;
    case (_,_)
      equation
        print("-merge_vars failed\n");
      then
        fail();
  end matchcontinue;
end mergeVars;

protected function checkAssertCondition "Succeds if condition of assert is not constant false"
  input DAE.Exp cond;
  input DAE.Exp message;
algorithm
  _ := matchcontinue(cond,message)
    case(_, _)
      equation
        // Don't check assertions when checking models
        true = OptManager.getOption("checkModel");
      then ();
    case(cond,message) equation
      false = Exp.isConstFalse(cond);
      then ();
    case(cond,message)
      local String messageStr;
      equation
        true = Exp.isConstFalse(cond);
        messageStr = Exp.printExpStr(message);
        Error.addMessage(Error.ASSERT_CONSTANT_FALSE_ERROR,{messageStr});
      then fail();
  end matchcontinue;
end checkAssertCondition;

protected function whenEquationsIndices "Returns all equation-indices that contain a when clause"
  input BackendDAE.EquationArray eqns;
  output list<Integer> res;
algorithm
   res := matchcontinue(eqns)
     case(eqns) equation
         res=whenEquationsIndices2(1,BackendDAEUtil.equationSize(eqns),eqns);
       then res;
   end matchcontinue;
end whenEquationsIndices;

protected function whenEquationsIndices2
"Help function"
  input Integer i;
  input Integer size;
  input BackendDAE.EquationArray eqns;
  output list<Integer> eqnLst;
algorithm
  eqnLst := matchcontinue(i,size,eqns)
    case(i,size,eqns) equation
      true = (i > size );
    then {};
    case(i,size,eqns)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation = _) = BackendDAEUtil.equationNth(eqns,i-1);
        eqnLst = whenEquationsIndices2(i+1,size,eqns);
    then i::eqnLst;
    case(i,size,eqns)
      equation
        eqnLst=whenEquationsIndices2(i+1,size,eqns);
      then eqnLst;
  end matchcontinue;
end whenEquationsIndices2;


end BackendDAETransform;

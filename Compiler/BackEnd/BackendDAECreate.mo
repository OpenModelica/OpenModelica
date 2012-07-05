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

encapsulated package BackendDAECreate
" file:        BackendDAECreate.mo
  package:     BackendDAECreate
  description: This file contains all functions for transforming the DAE structure to the BackendDAE. 
  
  RCS: $Id$

"

public import Absyn;
public import Algorithm;
public import BackendDAE;
public import DAE;
public import Env;

protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import BaseHashTable;
protected import CheckModel;
protected import ComponentReference;
protected import ClassInf;
protected import DAEDump;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Error;
protected import Expression;
protected import ExpressionSimplify;
protected import ExpressionDump;
protected import Flags;
protected import HashTableExpToIndex;
protected import HashTable;
protected import Inline;
protected import List;
protected import SCode;
protected import System;
protected import Util;


public function lower
"function: lower
  This function translates a DAE, which is the result from instantiating a
  class, into a more precise form, called BackendDAE.BackendDAE defined in this module.
  The BackendDAE.BackendDAE representation splits the DAE into equations and variables
  and further divides variables into known and unknown variables and the
  equations into simple and nonsimple equations.
  The variables are inserted into a hash table. This gives a lookup cost of
  O(1) for finding a variable. The equations are put in an expandable
  array. Where adding a new equation can be done in O(1) time if space
  is available.
  inputs:  daeList: DAE.DAElist, simplify: bool)
  outputs: BackendDAE.BackendDAE"
  input DAE.DAElist lst;
  input Env.Cache inCache;
  input Env.Env inEnv;  
  input Boolean addDummyDerivativeIfNeeded;
  output BackendDAE.BackendDAE outBackendDAE;
protected
  BackendDAE.BinTree s;
  BackendDAE.Variables vars,knvars,vars_1,extVars;
  BackendDAE.AliasVariables aliasVars "hash table with alias vars' replacements (a=b or a=-b)";
  list<BackendDAE.Equation> eqns,reqns,ieqns,algeqns,algeqns1,ialgeqns,multidimeqns,imultidimeqns,eqns_1,ceeqns,iceeqns;
  list<DAE.Constraint> constrs;
  list<BackendDAE.WhenClause> whenclauses,whenclauses_1;
  BackendDAE.EquationArray eqnarr,reqnarr,ieqnarr;
  array<DAE.Constraint> constrarra;
  BackendDAE.ExternalObjectClasses extObjCls;
  BackendDAE.SymbolicJacobians symjacs;
  Boolean daeContainsNoStates, shouldAddDummyDerivative;
  BackendDAE.EventInfo einfo;
  list<DAE.Element> elems;
  list<BackendDAE.ZeroCrossing> zero_crossings;
  DAE.FunctionTree functionTree;
algorithm
  System.realtimeTick(BackendDAE.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
  functionTree := Env.getFunctionTree(inCache);
  (DAE.DAE(elems),functionTree) := processDelayExpressions(lst,functionTree);
  s := states(elems, BackendDAE.emptyBintree);
  vars := BackendDAEUtil.emptyVars();
  knvars := BackendDAEUtil.emptyVars();
  extVars := BackendDAEUtil.emptyVars();
  (vars,knvars,extVars,eqns,reqns,ieqns,constrs,whenclauses,extObjCls,s) := lower2(listReverse(elems), functionTree, vars, knvars, extVars, {}, {}, {}, {}, {}, {}, s);
  daeContainsNoStates := hasNoStates(s); // check if the DAE has states
  // adrpo: add the dummy derivative state ONLY IF the DAE contains
  //        no states AND ONLY if addDummyDerivative is set to true!
  shouldAddDummyDerivative :=  boolAnd(addDummyDerivativeIfNeeded, daeContainsNoStates);
  (vars,eqns) := addDummyState(vars, eqns, shouldAddDummyDerivative);
  whenclauses_1 := listReverse(whenclauses);
  vars_1 := detectImplicitDiscrete(vars,knvars,eqns);
  eqnarr := BackendDAEUtil.listEquation(eqns);
  reqnarr := BackendDAEUtil.listEquation(reqns);
  ieqnarr := BackendDAEUtil.listEquation(ieqns);
  constrarra := listArray(constrs);
  einfo := BackendDAE.EVENT_INFO(whenclauses_1,{});
  aliasVars := BackendDAEUtil.emptyAliasVariables();
  outBackendDAE := BackendDAE.DAE(BackendDAE.EQSYSTEM(vars_1,eqnarr,NONE(),NONE(),BackendDAE.NO_MATCHING())::{},BackendDAE.SHARED(knvars,extVars,aliasVars,ieqnarr,reqnarr,constrarra,inCache,inEnv,functionTree,einfo,extObjCls,BackendDAE.SIMULATION(),{}));
  BackendDAEUtil.checkBackendDAEWithErrorMsg(outBackendDAE);
  Debug.fcall(Flags.DUMP_BACKENDDAE_INFO,print,"No. of Equations: " +& intString(BackendDAEUtil.equationSize(eqnarr)) +& "\nNo. of Variables: " +& intString(BackendVariable.varsSize(vars_1)) +& "\n");
  Debug.execStat("generate Backend Data Structur",BackendDAE.RT_CLOCK_EXECSTAT_BACKEND_MODULES);
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
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input BackendDAE.ExternalObjectClasses inExtObjClasses;
  input BackendDAE.BinTree inStates;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> oEqnsLst;
  output list<BackendDAE.Equation> oREqnsLst;
  output list<BackendDAE.Equation> oIEqnsLst;
  output list<DAE.Constraint> outConstraintLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output BackendDAE.ExternalObjectClasses outExtObjClasses;
  output BackendDAE.BinTree outStatesBinTree;
algorithm
  (outVariables,outKnownVariables,outExternalVariables,oEqnsLst,oREqnsLst,oIEqnsLst,
   outConstraintLst,outWhenClauseLst,outExtObjClasses,outStatesBinTree):=
   match (inElements,functionTree,inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,inIEqnsLst,
      inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates)
    local
      BackendDAE.Variables vars,knvars,extVars;
      list<BackendDAE.WhenClause> whenclauses;
      list<BackendDAE.Equation> eqns,reqns,ieqns;
      list<DAE.Constraint> constrs;
      BackendDAE.ExternalObjectClasses extObjCls;
      DAE.Element daeEl;
      list<DAE.Element> daeLstRest;
      BackendDAE.BinTree states;
      
    // the empty case 
    case ({},_,_,_,_,_,_,_,_,_,_,_)
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

    case (daeEl::daeLstRest,_,_,_,_,_,_,_,_,_,_,_)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,constrs,whenclauses,extObjCls,states) =
        lower3(daeEl,functionTree,inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

        (vars,knvars,extVars,eqns,reqns,ieqns,constrs,whenclauses,extObjCls,states) =
        lower2(daeLstRest,functionTree,vars,knvars,extVars,eqns,reqns,ieqns,constrs,whenclauses,extObjCls,states);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,constrs,whenclauses,extObjCls,states);
               
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
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input BackendDAE.ExternalObjectClasses inExtObjClasses;
  input BackendDAE.BinTree inStates;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> oEqnsLst;
  output list<BackendDAE.Equation> oREqnsLst;
  output list<BackendDAE.Equation> oIEqnsLst;
  output list<DAE.Constraint> outConstraintLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output BackendDAE.ExternalObjectClasses outExtObjClasses;
  output BackendDAE.BinTree outStatesBinTree;
algorithm
  (outVariables,outKnownVariables,outExternalVariables,oEqnsLst,oREqnsLst,oIEqnsLst,
   outConstraintLst,outWhenClauseLst,outExtObjClasses,outStatesBinTree):=
   match (inElement,functionTree,inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,inIEqnsLst,
      inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates)
    local
      list<DAE.Element> daeElts;
      DAE.Constraint cons_1;
      list<DAE.Constraint> constrs;
      Absyn.Info info;
      Absyn.Path path;
      BackendDAE.Variables vars,knvars,extVars;
      BackendDAE.ExternalObjectClasses extObjCls;
      BackendDAE.ExternalObjectClass extObjCl;
      list<BackendDAE.Equation> eqns,reqns,ieqns;
      list<BackendDAE.WhenClause> whenclauses;
      BackendDAE.BinTree states;
      DAE.ElementSource source;
      Integer count;
      list<DAE.Exp> explst;
      DAE.Exp e2;
                        
    // adrpo: should we ignore OUTER vars?!
    //case (((v as DAE.VAR(innerOuter=io)) :: xs),states,vars,knvars,extVars,whenclauses)
    //  equation
    //    DAEUtil.isOuterVar(v);
    //    (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls) =
    //    lower2(xs, states, vars, knvars, extVars, whenclauses);
    //  then
    //    (vars,knvars,extVars,eqns,reqns,ieqns,aeqns,algs,whenclauses_1,extObjCls);

    // class for external object
    case (DAE.EXTOBJECTCLASS(path,source),_,_,_,_,_,_,_,_,_,_,_)
      equation
        extObjCl = BackendDAE.EXTOBJCLASS(path,source);
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,extObjCl::inExtObjClasses,inStates);

    // variables
    case (DAE.VAR(componentRef = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        (vars,knvars,extVars,eqns,states) = lowerVar(inElement,functionTree,inVars,inKnVars,inExVars,inEqnsLst,inStates);
      then
        (vars,knvars,extVars,eqns,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,states);
    
      /* Only succeds for tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c) */
    case(DAE.EQUATION(DAE.TUPLE(explst),e2 as DAE.CALL(path =_),source),_,_,_,_,_,_,_,_,_,_,_)
      equation
       (eqns,reqns,ieqns) = lowerAlgorithm(DAE.ALGORITHM(DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.T_UNKNOWN_DEFAULT,explst,e2,source)}),source),functionTree,inEqnsLst,inREqnsLst,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,reqns,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
    case(DAE.EQUATION(e2 as DAE.CALL(path =_),DAE.TUPLE(explst),source),_,_,_,_,_,_,_,_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(DAE.ALGORITHM(DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.T_UNKNOWN_DEFAULT,explst,e2,source)}),source),functionTree,inEqnsLst,inREqnsLst,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,reqns,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
        
    // scalar equations
    case (DAE.EQUATION(exp = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        eqns = lowerEqn(inElement,functionTree,inEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
    
    // initial equations
    case (DAE.INITIALEQUATION(exp1 = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        ieqns = lowerEqn(inElement,functionTree,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

    // effort variable equality equations
    case (DAE.EQUEQUATION(cr1 = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        eqns = lowerEqn(inElement,functionTree,inEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
    
    // a solved equation 
    case (DAE.DEFINE(componentRef = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        eqns = lowerEqn(inElement,functionTree,inEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

    // complex equations
    case (DAE.COMPLEX_EQUATION(lhs = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        eqns = lowerEqn(inElement,functionTree,inEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
 
    // complex initial equations
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        ieqns = lowerEqn(inElement,functionTree,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

    // array equations
    case (DAE.ARRAY_EQUATION(exp = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        eqns = lowerEqn(inElement,functionTree,inEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
       
    // initial array equations
    case (DAE.INITIAL_ARRAY_EQUATION(exp = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        ieqns = lowerEqn(inElement,functionTree,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
       
    // when equations
    case (DAE.WHEN_EQUATION(condition = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        count = listLength(inWhenClauseLst);
        (eqns,_,whenclauses) = lowerWhenEqn(inElement,count,functionTree,inWhenClauseLst);
        eqns = listAppend(inEqnsLst, eqns);
      then
        (inVars,inKnVars,inExVars,eqns,inREqnsLst,inIEqnsLst,inConstraintLst,whenclauses,inExtObjClasses,inStates);

    // if equation that cannot be translated to if expression but have initial() as condition
    case (DAE.IF_EQUATION(condition1 = {DAE.CALL(path=Absyn.IDENT("initial"))}, source = DAE.SOURCE(info = info)),_,_,_,_,_,_,_,_,_,_,_)
      equation
        ieqns = lowerEqn(inElement,functionTree,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

    // if equation
    case (DAE.IF_EQUATION(condition1 = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        eqns = lowerEqn(inElement,functionTree,inEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

    // initial if equation
    case (DAE.INITIAL_IF_EQUATION(condition1 = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        ieqns = lowerEqn(inElement,functionTree,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

    // algorithm
    case (DAE.ALGORITHM(algorithm_ = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEqnsLst,inREqnsLst,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,reqns,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);

    // initial algorithm
    case (DAE.INITIALALGORITHM(algorithm_ = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEqnsLst,inREqnsLst,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
   
    // flat class / COMP
    case (DAE.COMP(dAElist = daeElts),_,_,_,_,_,_,_,_,_,_,_)
      equation
        (vars,knvars,extVars,eqns,reqns,ieqns,constrs,whenclauses,extObjCls,states) = lower2(listReverse(daeElts),functionTree,inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,inIEqnsLst,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
      then
        (vars,knvars,extVars,eqns,reqns,ieqns,constrs,whenclauses,extObjCls,states);
    
    // assert in equation section is converted to ALGORITHM
    case (DAE.ASSERT(condition = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEqnsLst,inREqnsLst,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,reqns,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
 
    // terminate in equation section is converted to ALGORITHM
    case (DAE.TERMINATE(message = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEqnsLst,inREqnsLst,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,reqns,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
    
    case (DAE.NORETCALL(functionName = _),_,_,_,_,_,_,_,_,_,_,_)
      equation
        (eqns,reqns,ieqns) = lowerAlgorithm(inElement,functionTree,inEqnsLst,inREqnsLst,inIEqnsLst);
      then
        (inVars,inKnVars,inExVars,eqns,reqns,ieqns,inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
 
    // constraint (Optimica) Just pass the constraints for now. Should anything more be done here?
    case (DAE.CONSTRAINT(constraints = cons_1),_,_,_,_,_,_,_,_,_,_,_)
      then
        (inVars,inKnVars,inExVars,inEqnsLst,inREqnsLst,inIEqnsLst,cons_1::inConstraintLst,inWhenClauseLst,inExtObjClasses,inStates);
    
    case (_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.lower3 failed on: " +& DAEDump.dumpElementsStr({inElement}));
      then
        fail();
  end match;
end lower3;

/*
 *  lower all variables
 */

protected function lowerVar
"function: lowerVar
  Transforms a DAE variable to DAE variable.
  Includes changing the ComponentRef name to a simpler form
  \'a\'.\'b\'{2}\'c\'{5} becomes
  \'a.b{2}.c\' (as CREF_IDENT(\"a.b.c\",{2}) )
  inputs: (DAE.Element, BackendDAE.BinTree /* states */)
  outputs: Var"
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input BackendDAE.Variables inVars "The time depend Variables";
  input BackendDAE.Variables inKnVars "The time independend Variables";
  input BackendDAE.Variables inExVars "The external Variables";
  input list<BackendDAE.Equation> inEqnsLst "The dynamic Equations/Algoritms";
  input BackendDAE.BinTree inStates;
  output BackendDAE.Variables outVariables;
  output BackendDAE.Variables outKnownVariables;
  output BackendDAE.Variables outExternalVariables;
  output list<BackendDAE.Equation> oEqnsLst;
  output BackendDAE.BinTree outStates;
algorithm
  (outVariables,outKnownVariables,outExternalVariables,oEqnsLst,outStates) := 
  matchcontinue (inElement,functionTree,inVars,inKnVars,inExVars,inEqnsLst,inStates)
    local
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      BackendDAE.Var backendVar1,backendVar2;
      DAE.Exp e1,e2;
      BackendDAE.BinTree states;
      BackendDAE.Variables vars,knvars,extvars;
      String str;

    // external object variables
    case (DAE.VAR(ty = DAE.T_COMPLEX(complexClassType = ClassInf.EXTERNAL_OBJ(path=_))),_,_,_,_,_,_)
      equation
        backendVar1 = lowerExtObjVar(inElement);
        backendVar2 = Inline.inlineVar(backendVar1,(SOME(functionTree),{DAE.NORM_INLINE()}));
        extvars = BackendVariable.addVar(backendVar2, inExVars);
      then
        (inVars,inKnVars,extvars,inEqnsLst,inStates);

    // variables: states and algebraic variables with binding equation
    case (DAE.VAR(componentRef = cr,binding=SOME(e2), source = source),_,_,_,_,_,_)
      equation
        // adrpo 2009-09-07 - according to MathCore
        // add the binding as an equation and remove the binding from variable!
        true = isStateOrAlgvar(inElement);
        (backendVar1,states) = lowerDynamicVar(inElement, inStates);
        backendVar2 = Inline.inlineVar(backendVar1,(SOME(functionTree),{DAE.NORM_INLINE()}));
        (e2,source) = Inline.inlineExp(e2,(SOME(functionTree),{DAE.NORM_INLINE()}),source);
        vars = BackendVariable.addVar(backendVar2, inVars);
        e1 = Expression.crefExp(cr);
      then
        (vars,inKnVars,inExVars,BackendDAE.EQUATION(e1, e2, source)::inEqnsLst,states);
        
    // variables: states and algebraic variables with NO binding equation
    case (DAE.VAR(binding=NONE(), source = source),_,_,_,_,_,_)
      equation
        true = isStateOrAlgvar(inElement);
        (backendVar1,states) = lowerDynamicVar(inElement, inStates);
        backendVar2 = Inline.inlineVar(backendVar1,(SOME(functionTree),{DAE.NORM_INLINE()}));
        vars = BackendVariable.addVar(backendVar2, inVars);
      then
        (vars,inKnVars,inExVars,inEqnsLst,states);
   
    // known variables: parameters and constants
    case (DAE.VAR(componentRef = _),_,_,_,_,_,_)
      equation
        backendVar1 = lowerKnownVar(inElement) "in previous rule, lower_var failed." ;
        backendVar2 = Inline.inlineVar(backendVar1,(SOME(functionTree),{DAE.NORM_INLINE()}));
        knvars = BackendVariable.addVar(backendVar2, inKnVars);
      then
        (inVars,knvars,inExVars,inEqnsLst,inStates);

    case (_,_,_,_,_,_,_)
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
"function: lowerDynamicVar
  Transforms a DAE variable to DAE variable.
  Includes changing the ComponentRef name to a simpler form
  \'a\'.\'b\'{2}\'c\'{5} becomes
  \'a.b{2}.c\' (as CREF_IDENT(\"a.b.c\",{2}) )
  inputs: (DAE.Element, BackendDAE.BinTree /* states */)
  outputs: Var"
  input DAE.Element inElement;
  input BackendDAE.BinTree istates;
  output BackendDAE.Var outVar;
  output BackendDAE.BinTree ostates;
algorithm
  (outVar,ostates) := match (inElement,istates)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      BackendDAE.BinTree states;
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
                  flowPrefix = flowPrefix,
                  streamPrefix = streamPrefix,
                  source = source,
                  variableAttributesOption = dae_var_attr,
                  absynCommentOption = comment),_)
      equation
        (kind_1,states) = lowerVarkind(kind, t, name, dir, flowPrefix, streamPrefix, istates, dae_var_attr);
        tp = lowerType(t);
        b = DAEUtil.boolVarVisibility(protection);
        dae_var_attr = DAEUtil.setProtectedAttr(dae_var_attr,b);
        dae_var_attr = setMinMaxFromEnumeration(t,dae_var_attr);
        _ = BackendVariable.getMinMaxAsserts(dae_var_attr,name,source,kind_1,tp);
        _ = BackendVariable.getNominalAssert(dae_var_attr,name,source,kind_1,tp);       
      then
        (BackendDAE.VAR(name,kind_1,dir,prl,tp,NONE(),NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix), states);
  end match;
end lowerDynamicVar;

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
      DAE.VarParallelism prl;
      BackendDAE.Type tp;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Type t;
      DAE.VarVisibility protection;
      Boolean b;  
      String str;    

    case (DAE.VAR(componentRef = name,
                  kind = kind,
                  direction = dir,
                  parallelism = prl,
                  protection = protection,
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
        bind = fixParameterStartBinding(bind,dae_var_attr,kind_1);
        tp = lowerType(t);
        b = DAEUtil.boolVarVisibility(protection);
        dae_var_attr = DAEUtil.setProtectedAttr(dae_var_attr,b);
        dae_var_attr = setMinMaxFromEnumeration(t,dae_var_attr);
        _ = BackendVariable.getMinMaxAsserts(dae_var_attr,name,source,kind_1,tp);
        _ = BackendVariable.getNominalAssert(dae_var_attr,name,source,kind_1,tp);
      then
        BackendDAE.VAR(name,kind_1,dir,prl,tp,bind,NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix);

    case (_)
      equation
        str = "BackendDAECreate.lowerKnownVar failed for " +& DAEDump.dumpElementsStr({inElement});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();        
  end matchcontinue;
end lowerKnownVar;

protected function setMinMaxFromEnumeration
  input DAE.Type inType;
  input Option<DAE.VariableAttributes> inVarAttr;
  output Option<DAE.VariableAttributes> outVarAttr;
algorithm
  outVarAttr := matchcontinue (inType,inVarAttr)
    local
      Option<DAE.Exp> min,max;
      list<String> names;
      Absyn.Path path;
    case (DAE.T_ENUMERATION(path=path,names = names),_)
      equation
        (min,max) = DAEUtil.getMinMaxValues(inVarAttr);
      then
        setMinMaxFromEnumeration1(min,max,inVarAttr,path,names);
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
  outVarAttr := matchcontinue (inMin,inMax,inVarAttr,inPath,inNames)
    local
      Integer i;
      Absyn.Path namee1,nameen;
      String s1,sn;
      DAE.Exp e;
    case (NONE(),NONE(),_,_,_)
      equation
        i = listLength(inNames);
        s1 = listNth(inNames,0);
        namee1 = Absyn.joinPaths(inPath,Absyn.IDENT(s1));
        sn = listNth(inNames,i-1);
        nameen = Absyn.joinPaths(inPath,Absyn.IDENT(sn));
      then
        DAEUtil.setMinMax(inVarAttr,(SOME(DAE.ENUM_LITERAL(namee1,1)),SOME(DAE.ENUM_LITERAL(nameen,i))));
    case (NONE(),SOME(e),_,_,_)
      equation
        i = listLength(inNames);
        s1 = listNth(inNames,0);
        namee1 = Absyn.joinPaths(inPath,Absyn.IDENT(s1));
      then 
        DAEUtil.setMinMax(inVarAttr,(SOME(DAE.ENUM_LITERAL(namee1,1)),SOME(e)));        
    case (SOME(e),NONE(),_,_,_)
      equation
        i = listLength(inNames);
        sn = listNth(inNames,i-1);
        nameen = Absyn.joinPaths(inPath,Absyn.IDENT(sn));
      then
        DAEUtil.setMinMax(inVarAttr,(SOME(e),SOME(DAE.ENUM_LITERAL(nameen,i))));             
    else inVarAttr;
  end matchcontinue;    
end setMinMaxFromEnumeration1;

protected function fixParameterStartBinding
  input Option<DAE.Exp> bind;
  input Option<DAE.VariableAttributes> attr;
  input BackendDAE.VarKind kind;
  output Option<DAE.Exp> outBind;
algorithm
  outBind := matchcontinue (bind,attr,kind)
    local
      DAE.Exp exp;
    case (NONE(),_,BackendDAE.PARAM())
      equation
        exp = DAEUtil.getStartAttr(attr);
      then SOME(exp);
    else bind;
  end matchcontinue;
end fixParameterStartBinding;

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
  input BackendDAE.BinTree inStates;
  input Option<DAE.VariableAttributes> daeAttr;
  output BackendDAE.VarKind outVarKind;
  output BackendDAE.BinTree outBinTree;
algorithm
  (outVarKind,outBinTree) := matchcontinue (inVarKind,inType,inComponentRef,inVarDirection,inFlow,inStream,inStates,daeAttr)
    local
      BackendDAE.BinTree states;
    // States appear differentiated among equations
    case (DAE.VARIABLE(),_,_,_,_,_,_,_)
      equation
        _ = BackendDAEUtil.treeGet(inStates, inComponentRef);
      then
        (BackendDAE.STATE(),inStates);
    // Or states have StateSelect.always
    case (DAE.VARIABLE(),_,_,_,_,_,_,SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.ALWAYS()))))
      equation
      states = BackendDAEUtil.treeAdd(inStates, inComponentRef, 0);
    then (BackendDAE.STATE(),states);
    // Or states have StateSelect.prefer
    case (DAE.VARIABLE(),_,_,_,_,_,_,SOME(DAE.VAR_ATTR_REAL(stateSelectOption = SOME(DAE.PREFER()))))
      equation
      states = BackendDAEUtil.treeAdd(inStates, inComponentRef, 0);
    then (BackendDAE.STATE(),states);

    case (DAE.VARIABLE(),DAE.T_BOOL(varLst = _),_,_,_,_,_,_)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inFlow));
      then
        (BackendDAE.DISCRETE(),inStates);

    case (DAE.DISCRETE(),DAE.T_BOOL(varLst = _),_,_,_,_,_,_)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inFlow));
      then
        (BackendDAE.DISCRETE(),inStates);

    case (DAE.VARIABLE(),DAE.T_INTEGER(varLst = _),_,_,_,_,_,_)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inFlow));
      then
        (BackendDAE.DISCRETE(),inStates);

    case (DAE.DISCRETE(),DAE.T_INTEGER(varLst = _),_,_,_,_,_,_)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inFlow));
      then
        (BackendDAE.DISCRETE(),inStates);
        
    case (DAE.VARIABLE(),DAE.T_ENUMERATION(names = _),_,_,_,_,_,_)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inFlow));
      then
        (BackendDAE.DISCRETE(),inStates);

    case (DAE.DISCRETE(),DAE.T_ENUMERATION(names = _),_,_,_,_,_,_)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inFlow));
      then
        (BackendDAE.DISCRETE(),inStates);        

    case (DAE.VARIABLE(),_,_,_,_,_,_,_)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inFlow));
      then
        (BackendDAE.VARIABLE(),inStates);

    case (DAE.DISCRETE(),_,_,_,_,_,_,_)
      equation
        failure(BackendVariable.topLevelInput(inComponentRef, inVarDirection, inFlow));
      then
        (BackendDAE.DISCRETE(),inStates);
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

    case (DAE.PARAM(),_,_,_) then BackendDAE.PARAM();
    case (DAE.CONST(),_,_,_) then BackendDAE.CONST();
    case (DAE.VARIABLE(),_,_,_)
      equation
        BackendVariable.topLevelInput(inComponentRef,inVarDirection,inFlow);
      then
        BackendDAE.VARIABLE();
    // adrpo: topLevelInput might fail!
    // case (DAE.VARIABLE(),cr,dir,flowPrefix)
    //  then
    //    BackendDAE.VARIABLE();
    case (_,_,_,_)
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
    else equation print("lowerType failed\n"); then fail();
  end matchcontinue;
end lowerType;

protected function lowerExtObjVar
" Helper function to lower2
  Fails for all variables except external object instances."
  input DAE.Element inElement;
  output BackendDAE.Var outVar;
algorithm
  outVar:=
  match (inElement)
    local
      list<DAE.Subscript> dims;
      DAE.ComponentRef name;
      BackendDAE.VarKind kind_1;
      Option<DAE.Exp> bind;
      DAE.VarKind kind;
      DAE.VarDirection dir;
      DAE.VarParallelism prl;
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
                  parallelism = prl,
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
        BackendDAE.VAR(name,kind_1,dir,prl,tp,bind,NONE(),dims,-1,source,dae_var_attr,comment,flowPrefix,streamPrefix);
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
"function: lowerEqn
  Helper function to lower2.
  Transforms a DAE.Element to Equation."
  input DAE.Element inElement;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;  
  output list<BackendDAE.Equation> outEqns; 
algorithm
  outEqns :=  match (inElement,functionTree,inEqns)
    local
      DAE.Exp e1,e2,e1_1,e2_1;
      DAE.ComponentRef cr1,cr2;
      DAE.ElementSource source;
      Boolean b1,b2;
      Integer size;
      DAE.Dimensions dims;
      list<DAE.Exp> explst,explst1,expvarlst,expvarlst1;
      list<list<DAE.Element>> eqnslstlst;
      list<DAE.Element> eqnslst;      
      list<list<BackendDAE.Equation>> beqnslstlst;
      list<BackendDAE.Equation> beqnslst; 
      list<Boolean> blst; 
      list<DAE.Var> varLst;   
      Absyn.Path path,fname,path1;  
      String s; 
      
    // tuple-tuple assignments are split into one equation for each tuple
    // element, i.e. (i1, i2) = (4, 6) => i1 = 4; i2 = 6;
    case (DAE.EQUATION(DAE.TUPLE(explst), DAE.TUPLE(explst1), source = source),_,_)
      then
        lowerTupleAssignment(explst,explst1,source,functionTree,inEqns);
      
    case (DAE.EQUATION(exp = e1,scalar = e2,source = source),_,_)
      equation
        (e1,source) = Inline.inlineExp(e1, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (e2,source) = Inline.inlineExp(e2, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
      then
        BackendDAE.EQUATION(e1,e2,source)::inEqns;

    case (DAE.INITIALEQUATION(exp1 = e1,exp2 = e2,source = source),_,_)
      equation
        (e1,source) = Inline.inlineExp(e1, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (e2,source) = Inline.inlineExp(e2, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
      then
        BackendDAE.EQUATION(e1,e2,source)::inEqns;

    case (DAE.EQUEQUATION(cr1 = cr1, cr2 = cr2,source = source),_,_)
      equation
        e1 = Expression.crefExp(cr1);
        e2 = Expression.crefExp(cr2);
      then
        BackendDAE.EQUATION(e1,e2,source)::inEqns;

    case (DAE.DEFINE(componentRef = cr1, exp = e2, source = source),_,_)
      equation
        (e2,source) = Inline.inlineExp(e2, (SOME(functionTree),{DAE.NORM_INLINE()}), source);        
        e1 = Expression.crefExp(cr1);
      then
        BackendDAE.EQUATION(e1,e2,source)::inEqns;

    case (DAE.INITIALDEFINE(componentRef = cr1, exp = e2, source = source),_,_)
      equation
        e1 = Expression.crefExp(cr1);
        (e2,source) = Inline.inlineExp(e2, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
      then
        BackendDAE.EQUATION(e1,e2,source)::inEqns;

    case (DAE.COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source),_,_)
      equation
        //(e1,source) = Inline.inlineExp(e1, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        //(e2,source) = Inline.inlineExp(e2, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (e1,source,_) = Inline.forceInlineExp(e1,(SOME(functionTree),{DAE.NORM_INLINE(),DAE.NO_INLINE()}),source);
        (e2,source,_) = Inline.forceInlineExp(e2,(SOME(functionTree),{DAE.NORM_INLINE(),DAE.NO_INLINE()}),source);        
      then
        lowerextendedRecordEqn(e1,e2,source,functionTree,inEqns);
        
    case (DAE.INITIAL_COMPLEX_EQUATION(lhs = e1,rhs = e2,source = source),_,_)
      equation
        (e1,source) = Inline.inlineExp(e1, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (e2,source) = Inline.inlineExp(e2, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        size = Expression.sizeOf(Expression.typeof(e1));
      then
        BackendDAE.COMPLEX_EQUATION(size,e1,e2,source)::inEqns;

    case (DAE.ARRAY_EQUATION(dimension=dims,exp = e1,array = e2,source = source),_,_)
      equation
        (e1,source) = Inline.inlineExp(e1, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (e2,source) = Inline.inlineExp(e2, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
      then
        lowerArrayEqn(dims,e1,e2,source,inEqns);
      
    case (DAE.INITIAL_ARRAY_EQUATION(dimension=dims,exp = e1,array = e2,source = source),_,_)
      equation
        (e1,source) = Inline.inlineExp(e1, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (e2,source) = Inline.inlineExp(e2, (SOME(functionTree),{DAE.NORM_INLINE()}), source);    
      then
        lowerArrayEqn(dims,e1,e2,source,inEqns); 
         
    case (DAE.IF_EQUATION(condition1=explst,equations2=eqnslstlst,equations3=eqnslst,source = source),_,_)
      equation
        b1 = not Flags.getConfigBool(Flags.CHECK_MODEL);
        s = Debug.bcallret1(b1, DAEDump.dumpElementsStr, {inElement}, "");
        Debug.bcall3(b1,Error.addSourceMessage,Error.IF_EQUATION_WARNING, {s}, DAEUtil.getElementSourceFileInfo(source));
        (explst,source) = Inline.inlineExps(explst, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (explst1,blst) = ExpressionSimplify.simplifyList1(explst,{},{});
        source = DAEUtil.addSymbolicTransformationSimplifyLst(blst,source,explst,explst1);
      then
        lowerIfEquation(explst1,eqnslstlst,eqnslst,{},{},source,functionTree,inEqns);

    case (DAE.INITIAL_IF_EQUATION(condition1=explst,equations2=eqnslstlst,equations3=eqnslst,source = source),_,_)
      equation
        b1 = not Flags.getConfigBool(Flags.CHECK_MODEL);
        s = Debug.bcallret1(b1, DAEDump.dumpElementsStr, {inElement}, "");
        Debug.bcall3(b1,Error.addSourceMessage,Error.IF_EQUATION_WARNING, {s}, DAEUtil.getElementSourceFileInfo(source));
        (explst,source) = Inline.inlineExps(explst, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (explst1,blst) = ExpressionSimplify.simplifyList1(explst,{},{});
        source = DAEUtil.addSymbolicTransformationSimplifyLst(blst,source,explst,explst1);
      then
        lowerIfEquation(explst1,eqnslstlst,eqnslst,{},{},source,functionTree,inEqns);
          
    case (_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s = "BackendDAECreate.lowerEqn failed for " +& DAEDump.dumpElementsStr({inElement});
        Error.addMessage(Error.INTERNAL_ERROR, {s});
      then fail();          
                         
  end match;
end lowerEqn;

protected function lowerIfEquation
  input list<DAE.Exp> conditions;
  input list<list<DAE.Element>> theneqns;
  input list<DAE.Element> elseenqs;
  input list<DAE.Exp> conditions1;
  input list<list<DAE.Element>> theneqns1;
  input DAE.ElementSource source;
  input DAE.FunctionTree functionTree;  
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := matchcontinue(conditions,theneqns,elseenqs,conditions1,theneqns1,source,functionTree,inEqns)
    local
      DAE.Exp e;
      list<DAE.Exp> explst;
      list<list<DAE.Element>> eqnslst;
      list<DAE.Element> eqns; 

      list<list<BackendDAE.Equation>> beqnslst;
      list<BackendDAE.Equation> beqns; 
      
    // no true case left with condition<>false
    case ({},{},_,{},{},_,_,_) 
      equation
        beqns = List.fold1(elseenqs,lowerEqn,functionTree,inEqns);
      then 
        beqns;   
    // true case left with condition<>false
    case ({},{},_,_,_,_,_,_)
      equation 
        explst = listReverse(conditions1);  
        eqnslst = listReverse(theneqns1);  
        beqnslst = List.map2(eqnslst,lowerEqns,functionTree,{});
        beqns = List.fold1(elseenqs,lowerEqn,functionTree,{});        
      then 
        BackendDAE.IF_EQUATION(explst, beqnslst, beqns,source)::inEqns;
    // if true use it
    case(DAE.BCONST(true)::_,eqns::_,_,_,_,_,_,_)
      equation
        beqns = List.fold1(eqns,lowerEqn,functionTree,inEqns);
      then 
        beqns; 
    // if false skip it
    case(DAE.BCONST(false)::explst,_::eqnslst,_,_,_,_,_,_)
      then
        lowerIfEquation(explst,eqnslst,elseenqs,conditions1,theneqns1,source,functionTree,inEqns);
    // all other cases
    case(e::explst,eqns::eqnslst,_,_,_,_,_,_)
      then
        lowerIfEquation(explst,eqnslst,elseenqs,e::conditions1,eqns::theneqns1,source,functionTree,inEqns);
  end matchcontinue;
end lowerIfEquation;

protected function lowerEqns
"Author: Frenkel TUD 2012-06"
  input list<DAE.Element> inElements;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;  
  output list<BackendDAE.Equation> outEqns;
algorithm
  outEqns := List.fold1(inElements,lowerEqn,functionTree,inEqns);
end lowerEqns;

protected function lowerextendedRecordEqns
"Author: Frenkel TUD 2012-06"
  input list<DAE.Exp> explst1;
  input list<DAE.Exp> explst2;
  input DAE.ElementSource source;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;  
  output list<BackendDAE.Equation> outEqns; 
algorithm
  outEqns := match(explst1,explst2,source,functionTree,inEqns)
    local 
      DAE.Exp e1,e2;
      list<DAE.Exp> elst1,elst2;
      list<BackendDAE.Equation> eqns;
    case({},{},_,_,_) then inEqns;
    case(e1::elst1,e2::elst2,_,_,_)
      equation
        eqns = lowerextendedRecordEqn(e1,e2,source,functionTree,inEqns);
      then
        lowerextendedRecordEqns(elst1,elst2,source,functionTree,eqns);
  end match;
end lowerextendedRecordEqns;

protected function lowerextendedRecordEqn "
Author: Frenkel TUD 2012-06"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input DAE.ElementSource isource;
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.Equation> inEqns;  
  output list<BackendDAE.Equation> outEqns; 
algorithm 
  outEqns := matchcontinue(inExp1,inExp2,isource,functionTree,inEqns)
    local
      DAE.Exp e1,e2;
      DAE.ElementSource source;
      DAE.ComponentRef cr1,cr2;
      Expression.Type tp;
      Integer size;
      list<DAE.Exp> expvarlst,expvarlst1,explst;
      Boolean b1,b2;
      list<DAE.Var> varLst; 
      Absyn.Path path,fname,path1;
      DAE.Dimensions dims;
      
    // a=b
    case (DAE.CREF(componentRef=cr1,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),DAE.CREF(componentRef=cr2),source,_,_)
      equation
        // create as many equations as the dimension of the record
        expvarlst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr1);
        expvarlst1 = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr2);
      then
        lowerextendedRecordEqns(expvarlst,expvarlst1,source,functionTree,inEqns);

    // a=Record()
    case (DAE.CREF(componentRef=cr1,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),DAE.CALL(path=path,expLst=explst),source,_,_)
      equation
        SOME(DAE.RECORD_CONSTRUCTOR(path=fname)) = DAEUtil.avlTreeGet(functionTree,path);
        // create as many equations as the dimension of the record
        expvarlst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr1);
      then
        lowerextendedRecordEqns(expvarlst,explst,source,functionTree,inEqns);

    // Record()=a
    case (DAE.CALL(path=path,expLst=explst),DAE.CREF(componentRef=cr1,ty= DAE.T_COMPLEX(varLst=varLst,complexClassType=ClassInf.RECORD(_))),source,_,_)
      equation
        SOME(DAE.RECORD_CONSTRUCTOR(path=fname)) = DAEUtil.avlTreeGet(functionTree,path);
        // create as many equations as the dimension of the record
        expvarlst = List.map1(varLst,Expression.generateCrefsExpFromExpVar,cr1);
      then
        lowerextendedRecordEqns(expvarlst,explst,source,functionTree,inEqns);

    // Record()=Record()
    case (DAE.CALL(path=path,expLst=expvarlst,attr=DAE.CALL_ATTR(ty= DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))),DAE.CALL(path=path1,expLst=explst),source,_,_)
      equation
        SOME(DAE.RECORD_CONSTRUCTOR(path=fname)) = DAEUtil.avlTreeGet(functionTree,path);
      then
        lowerextendedRecordEqns(expvarlst,explst,source,functionTree,inEqns);      

    // complex types to complex equations  
    case (e1,e2,source,_,_)
      equation 
        tp = Expression.typeof(e1);
        true = DAEUtil.expTypeComplex(tp);
        size = Expression.sizeOf(tp);
      then
        BackendDAE.COMPLEX_EQUATION(size,e1,e2,source)::inEqns;
      
    // array types to array equations  
    case (e1,e2,source,_,_)
      equation 
        tp = Expression.typeof(e1);
        true = DAEUtil.expTypeArray(tp);
        dims = Expression.arrayDimension(tp);
      then
        lowerArrayEqn(dims,e1,e2,source,inEqns);
    // other types  
    case (e1,e2,source,_,_)
      equation
        tp = Expression.typeof(e1);
        b1 = DAEUtil.expTypeComplex(tp);
        b2 = DAEUtil.expTypeArray(tp);
        false = b1 or b2;
        //Error.assertionOrAddSourceMessage(not b1,Error.INTERNAL_ERROR,{str}, Absyn.dummyInfo);
      then
        BackendDAE.EQUATION(e1,e2,source)::inEqns;
    else
      equation
        // show only on failtrace!
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.lowerextendedRecordEqn failed on: " +& ExpressionDump.printExpStr(inExp1) +& " = " +& ExpressionDump.printExpStr(inExp2) +& "\n");
      then
        fail();      
  end matchcontinue;
end lowerextendedRecordEqn;

protected function lowerArrayEqn"
Author: Frenkel TUD 2012-06"
  input DAE.Dimensions dims;
  input DAE.Exp e1;
  input DAE.Exp e2;
  input DAE.ElementSource source;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> outEqsLst;
algorithm
  outEqsLst := 
  matchcontinue (dims,e1,e2,source,iAcc)
    local
      DAE.Exp e1,e2,e1_1,e2_1;
      list<DAE.Exp> ea1,ea2;
      list<Integer> ds;
    case (_,_,_,_,_)
      equation
        true = Expression.isArray(e1) or Expression.isMatrix(e1);
        true = Expression.isArray(e2) or Expression.isMatrix(e2);
        ea1 = Expression.flattenArrayExpToList(e1);
        ea2 = Expression.flattenArrayExpToList(e2);        
      then
        generateEquations(ea1,ea2,source,iAcc);
    case (_,_,_,_,_)
      equation
        ds = Expression.dimensionsSizes(dims);
      then 
        BackendDAE.ARRAY_EQUATION(ds,e1,e2,source)::iAcc;
  end matchcontinue;
end lowerArrayEqn;

protected function generateEquations"
Author: Frenkel TUD 2012-06"
  input list<DAE.Exp> iE1lst;
  input list<DAE.Exp> iE2lst;
  input DAE.ElementSource source;
  input list<BackendDAE.Equation> iAcc;
  output list<BackendDAE.Equation> oEqns;
algorithm
  oEqns := match(iE1lst,iE2lst,source,iAcc)
    local
      DAE.Exp e1,e2;
      list<DAE.Exp> e1lst,e2lst;
    case ({},{},_,_) then iAcc;
    case (e1::e1lst,e2::e2lst,_,_)
      then
        generateEquations(e1lst,e2lst,source,BackendDAE.EQUATION(e1,e2,source)::iAcc);
  end match;
end generateEquations;


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
  input DAE.FunctionTree functionTree;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  output list<BackendDAE.Equation> outEquationLst;
  output Integer outWhenClauseIndex;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  (outEquationLst,outWhenClauseIndex,outWhenClauseLst):=
  matchcontinue (inElement,inWhenClauseIndex,functionTree,inWhenClauseLst)
    local
      list<BackendDAE.Equation> res, res1;
      list<BackendDAE.Equation> trueEqnLst, elseEqnLst;
      list<BackendDAE.WhenOperator> reinit;
      Integer equation_count,reinit_count,extra,tot_count,i_1,i,nextWhenIndex;
      Boolean hasReinit;
      list<BackendDAE.WhenClause> whenClauseList1,whenClauseList2,whenClauseList3,whenClauseList4,whenList,elseClauseList;
      DAE.Exp cond;
      list<DAE.Element> eqnl;
      DAE.Element elsePart;
      String scond;
      DAE.ElementSource source;

    case (DAE.WHEN_EQUATION(condition = cond,equations = eqnl,elsewhen_ = NONE(),source=source),i,_,whenList)
      equation
        (res,reinit) = lowerWhenEqn2(listReverse(eqnl), i, functionTree, {}, {});
        equation_count = listLength(res);
        reinit_count = listLength(reinit);
        hasReinit = (reinit_count > 0);
        extra = Util.if_(hasReinit, 1, 0);
        tot_count = equation_count + extra;
        i_1 = i + tot_count;
        (cond,source) = Inline.inlineExp(cond, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        whenClauseList3 = listAppend(whenClauseList2, whenClauseList1);
        whenClauseList4 = listAppend(whenClauseList3, whenList);
      then
        (res,i_1,whenClauseList4);

    case (DAE.WHEN_EQUATION(condition = cond,equations = eqnl,elsewhen_ = SOME(elsePart),source=source),i,_,whenList)
      equation
        (elseEqnLst,nextWhenIndex,elseClauseList) = lowerWhenEqn(elsePart,i,functionTree,whenList);
        (trueEqnLst,reinit) = lowerWhenEqn2(listReverse(eqnl), nextWhenIndex, functionTree, {}, {});
        equation_count = listLength(trueEqnLst);
        reinit_count = listLength(reinit);
        hasReinit = (reinit_count > 0);
        extra = Util.if_(hasReinit, 1, 0);
        tot_count = equation_count + extra;
        (cond,source) = Inline.inlineExp(cond, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        whenClauseList1 = makeWhenClauses(equation_count, cond, {});
        whenClauseList2 = makeWhenClauses(extra, cond, reinit);
        whenClauseList3 = listAppend(whenClauseList2, whenClauseList1);
        (res1,i_1,whenClauseList4) = mergeClauses(trueEqnLst,elseEqnLst,whenClauseList3,
          elseClauseList,nextWhenIndex + tot_count);
      then
        (res1,i_1,whenClauseList4);

    case (DAE.WHEN_EQUATION(condition = cond),_,_,_)
      equation
        scond = ExpressionDump.printExpStr(cond);
        print("- BackendDAECreate.lowerWhenEqn: Error in lowerWhenEqn. \n when ");
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
  input DAE.FunctionTree functionTree; 
  input list<BackendDAE.Equation> iEquationLst;
  input list<BackendDAE.WhenOperator> iReinitStatementLst;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.WhenOperator> outReinitStatementLst;
algorithm
  (outEquationLst,outReinitStatementLst):=
  matchcontinue (inDAEElementLst,inWhenClauseIndex,functionTree,iEquationLst,iReinitStatementLst)
    local
      BackendDAE.Value i;
      list<BackendDAE.Equation> eqnl;
      list<BackendDAE.WhenOperator> reinit;
      DAE.Exp cre,e,cond;
      DAE.ComponentRef cr;
      list<DAE.Element> xs;
      DAE.Element el;
      DAE.ElementSource source;

    case ({},_,_,_,_) then (iEquationLst,iReinitStatementLst);
    case ((DAE.EQUATION(exp = (cre as DAE.CREF(componentRef = cr)),scalar = e, source = source) :: xs),i,_,_,_)
      equation
        (e,source) = Inline.inlineExp(e, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1, functionTree, BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: iEquationLst, iReinitStatementLst);
      then
        (eqnl,reinit);

    case ((DAE.COMPLEX_EQUATION(lhs = (cre as DAE.CREF(componentRef = cr)),rhs = e,source = source) :: xs),i,_,_,_)
      equation
        (e,source) = Inline.inlineExp(e, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1, functionTree, BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: iEquationLst, iReinitStatementLst);
      then
        (eqnl,reinit);

    case ((DAE.ARRAY_EQUATION(exp = (cre as DAE.CREF(componentRef = cr)),array = e,source = source) :: xs),i,_,_,_)
      equation
        (e,source) = Inline.inlineExp(e, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1, functionTree, BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e,NONE()),source) :: iEquationLst, iReinitStatementLst);
      then
        (eqnl,reinit);

    case ((DAE.ASSERT(condition=cond,message = e,source = source) :: xs),i,_,_,_)
      equation
        (cond,source) = Inline.inlineExp(cond, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (e,source) = Inline.inlineExp(e, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (eqnl,reinit) = lowerWhenEqn2(xs, i, functionTree, iEquationLst, BackendDAE.ASSERT(cond,e,source) :: iReinitStatementLst);
      then
        (eqnl,reinit);

    case ((DAE.REINIT(componentRef = cr,exp = e,source = source) :: xs),i,_,_,_)
      equation
        (e,source) = Inline.inlineExp(e, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (eqnl,reinit) = lowerWhenEqn2(xs, i, functionTree, iEquationLst, BackendDAE.REINIT(cr,e,source) :: iReinitStatementLst);
      then
        (eqnl,reinit);

    case ((DAE.TERMINATE(message = e,source = source) :: xs),i,_,_,_)
      equation
        (e,source) = Inline.inlineExp(e, (SOME(functionTree),{DAE.NORM_INLINE()}), source);
        (eqnl,reinit) = lowerWhenEqn2(xs, i, functionTree, iEquationLst, BackendDAE.TERMINATE(e,source) :: iReinitStatementLst);
      then
        (eqnl,reinit);
        
    // failure  
    case ((el::xs), i,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.lowerWhenEqn2 failed on:" +& DAEDump.dumpElementsStr({el}));
      then 
        fail();
    
    // adrpo: 2010-09-26
    // allow to continue when checking the model
    // just ignore this equation.
    case ((el::xs), i,_,_,_)
      equation
        true = Flags.getConfigBool(Flags.CHECK_MODEL);
        (eqnl,reinit) = lowerWhenEqn2(xs, i + 1, functionTree,iEquationLst,iReinitStatementLst);
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
  input list<BackendDAE.Equation> iEqns;
  output list<BackendDAE.Equation> oEqns;
algorithm
  oEqns := match(target_expl,source_expl,eq_source,funcs,iEqns)
    local
      DAE.Exp target, source;
      list<DAE.Exp> rest_targets, rest_sources;
      DAE.Element e;
      BackendDAE.Equation eq,eq1;
      list<BackendDAE.Equation> eqns;
    case ({}, {}, _, _,_) then iEqns;
    case (target :: rest_targets, source :: rest_sources, _, _, _)
      equation
        e = DAE.EQUATION(target, source, eq_source);
        eqns = lowerEqn(DAE.EQUATION(target, source, eq_source),funcs,iEqns);
     then
        lowerTupleAssignment(rest_targets, rest_sources, eq_source, funcs, eqns);
  end match;
end lowerTupleAssignment;

protected function lowerTupleEquation
"Lowers a tuple equation, e.g. (a,b) = foo(x,y)
 by transforming it to an algorithm (TUPLE_ASSIGN), e.g. (a,b) := foo(x,y);
 author: PA"
  input DAE.Element eqn;
  output DAE.Algorithm alg;
algorithm
  alg := match(eqn)
    local
      DAE.ElementSource source;
      DAE.Exp e2;
      list<DAE.Exp> expl;
      /* Only succeds for tuple equations, i.e. (a,b,c) = foo(x,y,z) or foo(x,y,z) = (a,b,c) */
    case(DAE.EQUATION(DAE.TUPLE(expl),e2 as DAE.CALL(path =_),source))
    then DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.T_UNKNOWN_DEFAULT,expl,e2,source)});

    case(DAE.EQUATION(e2 as DAE.CALL(path =_),DAE.TUPLE(expl),source))
    then DAE.ALGORITHM_STMTS({DAE.STMT_TUPLE_ASSIGN(DAE.T_UNKNOWN_DEFAULT,expl,e2,source)});
  end match;
end lowerTupleEquation;

/*
 *   lower algorithms
 */

protected function lowerAlgorithm
"function: lowerAlgorithm
  Helper function to lower2.
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
  (outEquations,outREquations,outIEquations) :=  matchcontinue (inElement,functionTree,inEquations,inREquations,inIEquations)
    local
      DAE.Exp cond,msg;
      DAE.Algorithm alg;
      DAE.ElementSource source;
      Integer size;
      Boolean b1,b2;
      Absyn.Path functionName;
      list<DAE.Exp> functionArgs;
      list<DAE.ComponentRef> crefLst;
      String str;
      Absyn.Info info;
      list<BackendDAE.Equation> eqns,reqns,ieqns;
    
    case (DAE.ALGORITHM(algorithm_=alg, source=source),_,_,_,_)
      equation
        // calculate the size of the algorithm by collecting the left hand sites of the statemens 
        alg = Inline.inlineAlgorithm(alg,(SOME(functionTree),{DAE.NORM_INLINE()}));
        crefLst = CheckModel.algorithmOutputs(alg);
        size = listLength(crefLst); 
        (eqns,reqns) = List.consOnBool(intGt(size,0), BackendDAE.ALGORITHM(size, alg, source),inEquations,inREquations);
      then
        (eqns,reqns,inIEquations);
        
    case (DAE.INITIALALGORITHM(algorithm_=alg, source=source),_,_,_,_)
      equation
        // calculate the size of the algorithm by collecting the left hand sites of the statemens 
        alg = Inline.inlineAlgorithm(alg,(SOME(functionTree),{DAE.NORM_INLINE()}));
        crefLst = CheckModel.algorithmOutputs(alg);
        size = listLength(crefLst);        
      then
        (inEquations,inREquations,BackendDAE.ALGORITHM(size, alg, source)::inIEquations);        
        
    case (DAE.ASSERT(condition=cond,message=msg,source=source),_,_,_,_)
      equation
        (cond,source) = Inline.inlineExp(cond,(SOME(functionTree),{DAE.NORM_INLINE()}),source);
        BackendDAEUtil.checkAssertCondition(cond,msg);
        alg = DAE.ALGORITHM_STMTS({DAE.STMT_ASSERT(cond,msg,source)});
      then
        (inEquations,BackendDAE.ALGORITHM(0,alg,source)::inREquations,inIEquations);  

    case (DAE.TERMINATE(message=msg,source=source),_,_,_,_)
      then
        (inEquations,BackendDAE.ALGORITHM(0, DAE.ALGORITHM_STMTS({DAE.STMT_TERMINATE(msg,source)}), source)::inREquations,inIEquations);

    case (DAE.NORETCALL(functionName = functionName,functionArgs=functionArgs,source=source),_,_,_,_)
      equation
        // make sure is not constrain as we don't support it, see below.
        b1 = boolNot(Util.isEqual(functionName, Absyn.IDENT("constrain")));
        // constrain is fine when we do check model!
        b2 = Flags.getConfigBool(Flags.CHECK_MODEL);
        true = boolOr(b1, b2);
        (functionArgs,source) = Inline.inlineExps(functionArgs,(SOME(functionTree),{DAE.NORM_INLINE()}),source);
        alg = DAE.ALGORITHM_STMTS({DAE.STMT_NORETCALL(DAE.CALL(functionName,functionArgs,DAE.CALL_ATTR(DAE.T_NORETCALL_DEFAULT, false, false, DAE.NORM_INLINE(), DAE.NO_TAIL())),source)});
      then
        (inEquations,BackendDAE.ALGORITHM(0,alg,source)::inREquations,inIEquations);        
 
     // constrain is not a standard Modelica function, but used in old libraries such as the old Multibody library.
    // The OpenModelica backend does not support constrain, but the frontend does (Mathcore needs it for their backend).
    // To get a meaningful error message when constrain is used we catch it here, instead of silently failing. 
    // User-defined functions should have fully qualified names here, so Absyn.IDENT should only match the builtin constrain function.        
    case (DAE.NORETCALL(functionName = Absyn.IDENT(name = "constrain"), source = DAE.SOURCE(info=info)),_,_,_,_)
      equation
        str = DAEDump.dumpElementsStr({inElement});
        str = stringAppend("rewrite code without using constrain",str);
        Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE,{"constrain function",str}, info);
      then
        fail(); 
        
    case (_,_,_,_,_)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        str = "BackendDAECreate.lowerAlgorithm failed for " +& DAEDump.dumpElementsStr({inElement});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail(); 
                
  end matchcontinue;
end lowerAlgorithm;


/*
 *     other helping functions
 */

protected function states
"function: states
  Returns a BackendDAE.BinTree of all states in the DAE.
  This function is used by the lower function."
  input list<DAE.Element> inElems;
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.BinTree outBinTree;
algorithm
  outBinTree:=
  matchcontinue (inElems,inBinTree)
    local
      BackendDAE.BinTree bt;

    case (inElems,bt)
      equation
        (_,bt) = DAEUtil.traverseDAE2(inElems,statesExp, bt);
      then
        bt;
    case (_,bt) then bt;
  end matchcontinue;
end states;

protected function statesExp
"function: statesExp
  Helper function to states."
  input tuple<DAE.Exp,BackendDAE.BinTree> itpl;
  output tuple<DAE.Exp,BackendDAE.BinTree> otpl;
protected
  DAE.Exp e;
  BackendDAE.BinTree bt;
algorithm
  (e,bt) := itpl;
  otpl := Expression.traverseExp(e,traversingstatesExpFinder,bt);
end statesExp;

protected function traversingstatesExpFinder "
helper for statesExp
"
  input tuple<DAE.Exp, BackendDAE.BinTree > inExp;
  output tuple<DAE.Exp, BackendDAE.BinTree > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    DAE.ComponentRef cr;
    BackendDAE.BinTree bt;
    DAE.Exp e;
  case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),bt))
    equation
      bt = BackendDAEUtil.treeAdd(bt, cr, 0);
    then
      ((e,bt));
  case(inExp) then inExp;
end matchcontinue;
end traversingstatesExpFinder;

protected function processDelayExpressions
"Assign each call to delay() with a unique id argument"
  input DAE.DAElist inDAE;
  input DAE.FunctionTree functionTree;
  output DAE.DAElist outDAE;
  output DAE.FunctionTree outTree;
protected
  HashTableExpToIndex.HashTable ht;
algorithm
  ht := HashTableExpToIndex.emptyHashTableSized(100);
 (outDAE,outTree,_) := DAEUtil.traverseDAE(inDAE, functionTree, transformDelayExpressions, (ht,0));
end processDelayExpressions;

protected function transformDelayExpressions
"Helper for processDelayExpressions()"
  input tuple<DAE.Exp,tuple<HashTableExpToIndex.HashTable,Integer>> itpl;
  output tuple<DAE.Exp,tuple<HashTableExpToIndex.HashTable,Integer>> otpl;
protected
  DAE.Exp e;
  tuple<HashTableExpToIndex.HashTable,Integer> i;
algorithm
  (e,i) := itpl;
  otpl := Expression.traverseExp(e, transformDelayExpression, i);
end transformDelayExpressions;

protected function transformDelayExpression
"Insert a unique index into the arguments of a delay() expression.
Repeat delay as maxDelay if not present."
  input tuple<DAE.Exp, tuple<HashTableExpToIndex.HashTable,Integer>> inTuple;
  output tuple<DAE.Exp, tuple<HashTableExpToIndex.HashTable,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e, e1, e2, e3;
      list<DAE.Exp> es;
      HashTableExpToIndex.HashTable ht;
      Integer i;
      Boolean t, b;
      DAE.Type ty;
      DAE.InlineType it;
      DAE.CallAttributes attr;
    case ((e as DAE.CALL(Absyn.IDENT("delay"), es, attr), (ht,_)))
      equation
        i = BaseHashTable.get(e,ht);
      then ((DAE.CALL(Absyn.IDENT("delay"), DAE.ICONST(i)::es, attr), (ht,i)));

    case ((e as DAE.CALL(Absyn.IDENT("delay"), es, attr), (ht,i)))
      equation
        ht = BaseHashTable.add((e,i),ht);
      then ((DAE.CALL(Absyn.IDENT("delay"), DAE.ICONST(i)::es, attr), (ht,i+1)));

    else inTuple;
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
  match (inVariables,inEquationLst,inBoolean)
    local
      BackendDAE.Variables v,vars_1,vars;
      list<BackendDAE.Equation> e,eqns;
      DAE.ComponentRef cref_;
      DAE.Exp exp;
      
    case (v,e,false) then (v,e);
    case (vars,eqns,true) /* TODO::The dummy variable must be fixed */
      equation
        cref_ = ComponentReference.makeCrefIdent("$dummy",DAE.T_REAL_DEFAULT,{});
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cref_, BackendDAE.STATE(),DAE.BIDIR(),DAE.NON_PARALLEL(),DAE.T_REAL_DEFAULT,NONE(),NONE(),{},-1,
                            DAE.emptyElementSource,
                            SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),SOME(DAE.BCONST(true)),NONE(),NONE(),NONE(),NONE(),NONE(),NONE(),NONE())),
                            NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM()), vars);
        exp = Expression.crefExp(cref_);
      then
        /*
         * adrpo: after a bit of talk with Francesco Casella & Peter Aronsson we will add der($dummy) = 0;
         */
        (vars_1,(BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),{exp},DAE.callAttrBuiltinReal),
                          DAE.RCONST(0.0), DAE.emptyElementSource)  :: eqns));

  end match;
end addDummyState;

protected function detectImplicitDiscrete
"function: detectImplicitDiscrete
  This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnVariables;
  input list<BackendDAE.Equation> inEquationLst;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := List.fold1(inEquationLst,detectImplicitDiscreteFold,inKnVariables,inVariables);
end detectImplicitDiscrete;

protected function detectImplicitDiscreteFold
"function: detectImplicitDiscrete
  This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inKnVariables;
  input BackendDAE.Variables inVariables;
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inEquation,inKnVariables,inVariables)
    local
      DAE.ComponentRef cr;
      BackendDAE.Var var;
      list<DAE.Statement> statementLst;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr)),_,_)
      equation
        ((var :: _),_) = BackendVariable.getVar(cr, inVariables);
        var = BackendVariable.setVarKind(var,BackendDAE.DISCRETE());
      then BackendVariable.addVar(var, inVariables);
    case (BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(statementLst = statementLst)),_,_)
      then detectImplicitDiscreteAlgsStatemens(inVariables,inKnVariables,statementLst,false);
    else inVariables;
  end matchcontinue;
end detectImplicitDiscreteFold;

protected function getVarsFromExp
"function: getVarsFromExp
  This function collects all variables from an expression-list."
  input list<DAE.Exp> inExpLst;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst := matchcontinue(inExpLst, inVariables)
    local
      DAE.ComponentRef cref;
      list<DAE.Exp> expLst;
      BackendDAE.Variables variables;
      BackendDAE.Var var;
      list<BackendDAE.Var> varLst;
    case({}, _) then {};
    case(DAE.CREF(componentRef=cref)::expLst, variables) equation
      ((var::_), _) = BackendVariable.getVar(cref, variables);
      varLst = getVarsFromExp(expLst, variables);
    then var::varLst;
    case(_::expLst, variables) equation
      varLst = getVarsFromExp(expLst, variables);
    then varLst;
  end matchcontinue;
end getVarsFromExp;

protected function detectImplicitDiscreteAlgsStatemens
"function: detectImplicitDiscreteAlgsStatemens
  This function updates the variable kind to discrete
  for variables set in when equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnVariables;
  input list<DAE.Statement> inStatementLst;
  input Boolean insideWhen "true if its called from a when statement";
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inVariables,inKnVariables,inStatementLst,insideWhen)
    local
      BackendDAE.Variables v,v_1,v_2,v_3,knv;
      DAE.ComponentRef cr;
      list<DAE.Statement> xs,statementLst;
      BackendDAE.Var var;
      list<BackendDAE.Var> vars;
      DAE.Statement statement;
      Boolean b;
      DAE.Type tp;
      DAE.Ident iteratorName;
      DAE.Exp e,iteratorExp;
      list<DAE.Exp> iteratorexps, expExpLst;
    case (v,_,{},_) then v;
    case (v,knv,(DAE.STMT_ASSIGN(exp1 =DAE.CREF(componentRef = cr)) :: xs),true)
      equation
        ((var :: _),_) = BackendVariable.getVar(cr, v);
        var = BackendVariable.setVarKind(var,BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVar(var, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1,knv, xs,true);
      then
        v_2;
        
      case(v, knv, (DAE.STMT_TUPLE_ASSIGN(expExpLst=expExpLst)::xs), true) equation
        vars = getVarsFromExp(expExpLst, v);
        vars = List.map1(vars, BackendVariable.setVarKind, BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVars(vars, v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1, knv, xs, true);
      then v_2;
        
    case (v,knv,(DAE.STMT_ASSIGN_ARR(componentRef = cr) :: xs),true)
      equation
        (vars,_) = BackendVariable.getVar(cr, v);
        vars = List.map1(vars,BackendVariable.setVarKind,BackendDAE.DISCRETE());
        v_1 = BackendVariable.addVars(vars,v);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1,knv, xs,true);
      then
        v_2;
    case (v,knv,(DAE.STMT_IF(statementLst = statementLst) :: xs),true)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v,knv,statementLst,true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1,knv, xs,true);
      then
        v_2;
    case (v,knv,(DAE.STMT_FOR(type_= tp, iter = iteratorName, range = e,statementLst = statementLst) :: xs),true)
      equation
        /* use the range for the componentreferences */
        cr = ComponentReference.makeCrefIdent(iteratorName, tp, {});
        iteratorExp = Expression.crefExp(cr);
        iteratorexps = extendRange(e,knv);
        v_1 = detectImplicitDiscreteAlgsStatemensFor(iteratorExp,iteratorexps,v,knv,statementLst,true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1,knv, xs,true);
      then
        v_2;
    case (v,knv,(DAE.STMT_WHEN(statementLst = statementLst,elseWhen = NONE()) :: xs),_)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v,knv,statementLst,true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1,knv, xs,false);
      then
        v_2;
    case (v,knv,(DAE.STMT_WHEN(statementLst = statementLst,elseWhen = SOME(statement)) :: xs),_)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v,knv,statementLst,true);
        v_2 = detectImplicitDiscreteAlgsStatemens(v_1,knv,{statement},true);
        v_3 = detectImplicitDiscreteAlgsStatemens(v_2,knv, xs,false);
      then
        v_3;
    case (v,knv,(_ :: xs),b)
      equation
        v_1 = detectImplicitDiscreteAlgsStatemens(v,knv, xs,b);
      then
        v_1;
  end matchcontinue;
end detectImplicitDiscreteAlgsStatemens;

protected function detectImplicitDiscreteAlgsStatemensFor
"function: detectImplicitDiscreteAlgsStatemensFor
  "
  input DAE.Exp inIteratorExp;
  input list<DAE.Exp> inExplst;
  input BackendDAE.Variables inVariables;
  input BackendDAE.Variables inKnVariables;
  input list<DAE.Statement> inStatementLst;
  input Boolean insideWhen "true if its called from a when statement";
  output BackendDAE.Variables outVariables;
algorithm
  outVariables := matchcontinue (inIteratorExp,inExplst,inVariables,inKnVariables,inStatementLst,insideWhen)
    local
      BackendDAE.Variables v,v_1,v_2,knv;
      list<DAE.Statement> statementLst,statementLst1;
      Boolean b;
      DAE.Exp e,ie;
      list<DAE.Exp> rest;
    case (_,{},v,_,_,_) then v;
    case (ie,e::rest,v,knv,statementLst,b)
      equation
        (statementLst1,_) = DAEUtil.traverseDAEEquationsStmts(statementLst,replaceExp,((ie,e)));
        v_1 = detectImplicitDiscreteAlgsStatemens(v,knv,statementLst1,true);
        v_2 = detectImplicitDiscreteAlgsStatemensFor(ie,rest,v_1,knv,statementLst,b);
      then
        v_2;
    case (_,_,_,_,_,_)
      equation
        print("BackendDAECreate.detectImplicitDiscreteAlgsStatemensFor failed \n");
      then
        fail();
  end matchcontinue;
end detectImplicitDiscreteAlgsStatemensFor;

protected function replaceExp
"Help function to e.g. detectImplicitDiscreteAlgsStatemensFor"
  input tuple<DAE.Exp,tuple<DAE.Exp,DAE.Exp>> tpl;
  output tuple<DAE.Exp,tuple<DAE.Exp,DAE.Exp>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      DAE.Exp e,e1,s,t;
    case((e,(s,t))) equation
      ((e1,_)) = Expression.replaceExp(e,s,t);
    then ((e1,(s,t)));
    case tpl then tpl;
  end matchcontinue;
end replaceExp;

protected function extendRange
"function: extendRange
  "
  input DAE.Exp rangeExp;
  input BackendDAE.Variables inKnVariables;
  output list<DAE.Exp> outExpLst;
algorithm
  outExpLst:=
  matchcontinue (rangeExp,inKnVariables)
    local 
      list<DAE.Exp> explst;
      DAE.Type tp;
      DAE.Exp startvalue,stopvalue,stepvalue;
      Option<DAE.Exp> stepvalueopt;
      BackendDAE.Variables knv;
      Integer istart,istop,istep;
      list<Integer> ilst;
    case (DAE.RANGE(ty=tp,start=startvalue,step=stepvalueopt,stop=stopvalue),knv)
      equation
        stepvalue = Util.getOptionOrDefault(stepvalueopt,DAE.ICONST(1));
        istart = expInt(startvalue,knv);
        istep = expInt(stepvalue,knv);
        istop = expInt(stopvalue,knv);
        ilst = List.intRange3(istart,istep,istop);
        explst = List.map(ilst,Expression.makeIntegerExp);
      then
        explst;
    case (_,_)
      equation
        Debug.fprint(Flags.FAILTRACE,"BackendDAECreate.extendRange failed. Maybe some ZeroCrossing are not supported\n");
      then
        ({});
  end matchcontinue;
end extendRange;

protected function expInt "returns the int value of an expression"
  input DAE.Exp exp;
  input BackendDAE.Variables inKnVariables;
  output Integer i;
algorithm
  i := match(exp,inKnVariables)
    local 
      Integer i,i1,i2;
      DAE.ComponentRef cr;
      BackendDAE.Variables knv;
      DAE.Exp e,e1,e2;
    case (DAE.ICONST(integer = i2),_) then i2;
    case (DAE.ENUM_LITERAL(index = i2),_) then i2;
    case (DAE.CREF(componentRef=cr),knv)
      equation
        ((BackendDAE.VAR(bindExp=SOME(e)):: _),_) = BackendVariable.getVar(cr, knv);
        i2 = expInt(e,knv);
      then
        i2;
    case (DAE.BINARY(exp1 = e1,operator=DAE.ADD(DAE.T_INTEGER(varLst = _)),exp2 = e2),knv)
      equation
        i1 = expInt(e1,knv);
        i2 = expInt(e1,knv);
        i = i1 + i2;
      then i;
    case (DAE.BINARY(exp1 = e1,operator=DAE.SUB(DAE.T_INTEGER(varLst = _)),exp2 = e2),knv)
      equation
        i1 = expInt(e1,knv);
        i2 = expInt(e2,knv);
        i = i1 - i2;
      then i;
  end match;
end expInt;



public function expandDerOperator
"function expandDerOperator
  expands der(expr) using Derive.differentiteExpTime.
  This can not be done in Static, since we need all time-
  dependent variables, which is only available in BackendDAE."
  input BackendDAE.BackendDAE dae;
  output BackendDAE.BackendDAE odae;
algorithm
  odae := BackendDAEUtil.mapEqSystem(dae,expandDerOperatorWork);
end expandDerOperator;

protected function expandDerOperatorWork
"function expandDerOperator
  expands der(expr) using Derive.differentiteExpTime.
  This can not be done in Static, since we need all time-
  dependent variables, which is only available in BackendDAE."
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := match (syst,shared)
    local
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.Variables vars,knvars,exobj,vars1,vars2,vars3,vars4,vars5;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1,inieqns1;
      array<DAE.Constraint> constrs;
      BackendDAE.EventInfo einfo;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
      DAE.FunctionTree funcs;
      BackendDAE.SymbolicJacobians symjacs;
      Env.Cache cache;
      Env.Env env;      
    case (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),shared as BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs))
      equation
        (eqns1,(vars1,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(eqns,traverserexpandDerEquation,(vars,shared));
        (inieqns1,(vars2,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(inieqns,traverserexpandDerEquation,(vars1,shared));
      then
        (BackendDAE.EQSYSTEM(vars2,eqns1,m,mT,matching),BackendDAE.SHARED(knvars,exobj,av,inieqns1,remeqns,constrs,cache,env,funcs,einfo,eoc,btp,symjacs));
  end match;
end expandDerOperatorWork;

protected function traverserexpandDerEquation
  "Help function to e.g. traverserexpandDerEquation"
  input tuple<BackendDAE.Equation,tuple<BackendDAE.Variables,BackendDAE.Shared>> tpl;
  output tuple<BackendDAE.Equation,tuple<BackendDAE.Variables,BackendDAE.Shared>> outTpl;
protected
   BackendDAE.Equation e,e1;
   tuple<BackendDAE.Variables,DAE.FunctionTree> ext_arg, ext_art1;
   BackendDAE.Variables vars;
   DAE.FunctionTree funcs;
   Boolean b;
   list<DAE.SymbolicOperation> ops;
   BackendDAE.Shared shared;
algorithm
  (e,(vars,shared)) := tpl;
  (e1,(vars,shared,ops)) := BackendEquation.traverseBackendDAEExpsEqn(e,traverserexpandDerExp,(vars,shared,{}));
  e1 := List.foldr(ops,BackendEquation.addOperation,e1);
  outTpl := ((e1,(vars,shared)));
end traverserexpandDerEquation;

protected function traverserexpandDerExp
  "Help function to e.g. traverserexpandDerExp"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.Shared,list<DAE.SymbolicOperation>>> tpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.Shared,list<DAE.SymbolicOperation>>> outTpl;
protected
  DAE.Exp e,e1;
  tuple<BackendDAE.Variables,BackendDAE.Shared,Boolean> ext_arg;
  BackendDAE.Variables vars;
  list<DAE.SymbolicOperation> ops;
  DAE.FunctionTree funcs;
  Boolean b;
  BackendDAE.Shared shared;
algorithm
  (e,(vars,shared,ops)) := tpl;
  ext_arg := (vars,shared,false);
  ((e1,ext_arg)) := Expression.traverseExp(e,expandDerExp,ext_arg);
  (vars,shared,b) := ext_arg;
  ops := List.consOnTrue(b,DAE.OP_DERIVE(DAE.crefTime,e,e1),ops);
  outTpl := (e1,(vars,shared,ops));
end traverserexpandDerExp;

protected function expandDerExp
"Help function to e.g. expandDerOperatorEqn"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.Shared,Boolean>> tpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.Shared,Boolean>> outTpl;
algorithm
  outTpl := matchcontinue(tpl)
    local
      BackendDAE.Variables vars;
      DAE.Exp e1,e2;
      DAE.ComponentRef cr;
      String str;
      list<DAE.SymbolicOperation> ops;
      BackendDAE.Shared shared;
      list<BackendDAE.Var> varlst;
    case((DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={e1 as DAE.CREF(componentRef=cr)})}),(vars,_,_)))
      equation
        str = ComponentReference.crefStr(cr);
        str = stringAppendList({"The model includes derivatives of order > 1 for: ",str,". That is not supported. Real d", str, " = der(", str, ") *might* result in a solvable model"});
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();      
    case((e1 as DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={DAE.CREF(componentRef=cr)}),(vars,shared,_)))
      equation
        (varlst,_) = BackendVariable.getVar(cr, vars);
        vars = updateStatesVars(vars,varlst,false);       
      then ((e1,(vars,shared,true)));
    case((DAE.CALL(path=Absyn.IDENT(name = "der"),expLst={e1}),(vars,shared,_)))
      equation
        e2 = Derive.differentiateExpTime(e1,(vars,shared));
        (e2,_) = ExpressionSimplify.simplify(e2);
        ((_,vars)) = Expression.traverseExp(e2,derCrefsExp,vars);
      then ((e2,(vars,shared,true)));
    case tpl then tpl;
  end matchcontinue;
end expandDerExp;

protected function derCrefsExp "
helper for statesExp
"
  input tuple<DAE.Exp, BackendDAE.Variables > inExp;
  output tuple<DAE.Exp, BackendDAE.Variables > outExp;
algorithm outExp := matchcontinue(inExp)
  local
    DAE.ComponentRef cr;
    BackendDAE.Variables vars;
    list<BackendDAE.Var> varlst;
    DAE.Exp e;
  case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
    equation
      (varlst,_) = BackendVariable.getVar(cr, vars);
      vars = updateStatesVars(vars,varlst,false);
    then
      ((e,vars));
  case(inExp) then inExp;
end matchcontinue;
end derCrefsExp;


protected function updateStatesVars
"Help function to expandDerExp"
  input BackendDAE.Variables inVars;
  input list<BackendDAE.Var> inNewStates;
  input Boolean noStateFound;
  output BackendDAE.Variables outVars;
algorithm
  outVars := matchcontinue(inVars,inNewStates,noStateFound)
    local
      BackendDAE.Var var;
      list<BackendDAE.Var> newStates;
      BackendDAE.Variables vars;
      //DAE.ComponentRef cr;
      //String str;

    case(_,{},true) then inVars;
    case(_,var::newStates,_)
      equation
        false = BackendVariable.isStateVar(var);
        var = BackendVariable.setVarKind(var,BackendDAE.STATE());
        vars = BackendVariable.addVar(var, inVars);
        vars = updateStatesVars(vars,newStates,true);
      then vars;
    case(_,_::newStates,_)
      equation
        /* Might be part of a different equation-system...
        str = "BackendDAECreate.updateStatesVars failed for: " +& ComponentReference.printComponentRefStr(cr);
        Error.addMessage(Error.INTERNAL_ERROR,{str});
        */
        vars = updateStatesVars(inVars,newStates,noStateFound);
      then vars;
  end matchcontinue;
end updateStatesVars;


protected function zeroCrossingEquations
"Returns the list of equations (indices) from a ZeroCrossing"
  input BackendDAE.ZeroCrossing zc;
  output list<Integer> lst;
algorithm
  lst := match (zc)
    case(BackendDAE.ZERO_CROSSING(_,lst,_)) then lst;
  end match;
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
        samezc = List.select1(xs, sameZeroCrossing, zc);
        diff = List.select1(xs, differentZeroCrossing, zc);
        diff_1 = mergeZeroCrossings(diff);
        same_1 = List.fold(samezc, mergeZeroCrossing, zc);
      then
        (same_1 :: diff_1);
  end matchcontinue;
end mergeZeroCrossings;

protected function mergeZeroCrossing "function: mergeZeroCrossing

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
  matchcontinue (inZeroCrossing1,inZeroCrossing2)
    local
      list<BackendDAE.Value> eq,wc,eq1,wc1,eq2,wc2;
      DAE.Exp e1,e2;
      Integer index1,index2;
      String s1,s2;
    case (BackendDAE.ZERO_CROSSING(relation_ = e1 as DAE.RELATION(index=index1),occurEquLst = eq1,occurWhenLst = wc1),BackendDAE.ZERO_CROSSING(relation_ = e2 as DAE.RELATION(index=index2),occurEquLst = eq2,occurWhenLst = wc2))
      equation
        true = intLt(index1,index2);
        eq = List.union(eq1, eq2);
        wc = List.union(wc1, wc2);
      then
        BackendDAE.ZERO_CROSSING(e1,eq,wc);
    case (BackendDAE.ZERO_CROSSING(relation_ = e1 as DAE.RELATION(index=index1),occurEquLst = eq1,occurWhenLst = wc1),BackendDAE.ZERO_CROSSING(relation_ = e2 as DAE.RELATION(index=index2),occurEquLst = eq2,occurWhenLst = wc2))
      equation
        eq = List.union(eq1, eq2);
        wc = List.union(wc1, wc2);
      then BackendDAE.ZERO_CROSSING(e2,eq,wc);
    case (BackendDAE.ZERO_CROSSING(relation_ = e1 as DAE.RELATION(index=index1),occurEquLst = eq1,occurWhenLst = wc1),BackendDAE.ZERO_CROSSING(relation_ = e2 as DAE.RELATION(index=index2),occurEquLst = eq2,occurWhenLst = wc2))
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.traceln("- BackendDAECreate.mergeZeroCrossing failed!");
      then
        fail();
  end matchcontinue;
end mergeZeroCrossing;

protected function sameZeroCrossing "function: sameZeroCrossing

  Returns true if both zero crossings have the same function expression
"
  input BackendDAE.ZeroCrossing inZeroCrossing1;
  input BackendDAE.ZeroCrossing inZeroCrossing2;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inZeroCrossing1,inZeroCrossing2)
    local
      Boolean res;
      DAE.Exp e1,e2;
    case (BackendDAE.ZERO_CROSSING(relation_ = e1),BackendDAE.ZERO_CROSSING(relation_ = e2))
      equation
        res = Expression.expEqual(e1, e2);
      then res;
  end match;
end sameZeroCrossing;

protected function differentZeroCrossing "function: differentZeroCrossing

  Return true if the realation expressions differ.
"
  input BackendDAE.ZeroCrossing zc1;
  input BackendDAE.ZeroCrossing zc2;
  output Boolean res_1;
protected
  Boolean res;
algorithm
  res := sameZeroCrossing(zc1, zc2);
  res_1 := boolNot(res);
end differentZeroCrossing;

public function findZeroCrossings "function: findZeroCrossings
  This function finds all zerocrossings in the list of equations and
  the list of when clauses."
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  list<BackendDAE.EqSystem> systs;
  BackendDAE.Shared shared;
algorithm
  outDAE := BackendDAEUtil.mapEqSystem(inDAE,findZeroCrossings1);
end findZeroCrossings;

protected function findZeroCrossings1 "function: findZeroCrossings
  This function finds all zerocrossings in the list of equations and
  the list of when clauses."
    input BackendDAE.EqSystem syst;
    input BackendDAE.Shared shared;
    output BackendDAE.EqSystem osyst;
    output BackendDAE.Shared oshared;
algorithm
  (osyst,oshared) := match (syst,shared)
    local
      BackendDAE.Variables vars,knvars,exobj;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,remeqns,inieqns,eqns1;
      array<DAE.Constraint> constrs;
      BackendDAE.EventInfo einfo,einfo1;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.WhenClause> whenclauses,whenclauses1;
      list<BackendDAE.Equation> eqs_lst,eqs_lst1;
      list<BackendDAE.ZeroCrossing> zero_crossings;
      BackendDAE.EqSystems eqs;
      Option<BackendDAE.IncidenceMatrix> m,mT;
      BackendDAE.BackendDAEType btp;
      BackendDAE.Matching matching;
      DAE.FunctionTree funcs;
      BackendDAE.SymbolicJacobians symjacs;
      Env.Cache cache;
      Env.Env env;      
    case (BackendDAE.EQSYSTEM(vars,eqns,m,mT,matching),BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo as BackendDAE.EVENT_INFO(zeroCrossingLst=zero_crossings,whenClauseLst=whenclauses),eoc,btp,symjacs))
      equation
        eqs_lst = BackendDAEUtil.equationList(eqns);
        (zero_crossings,eqs_lst1,whenclauses1) = findZeroCrossings2(vars, knvars,eqs_lst,0, whenclauses, 0,0,zero_crossings);
        eqns1 = BackendDAEUtil.listEquation(eqs_lst1);
        einfo1 = BackendDAE.EVENT_INFO(whenclauses1,zero_crossings);
      then
        (BackendDAE.EQSYSTEM(vars,eqns1,m,mT,matching),BackendDAE.SHARED(knvars,exobj,av,inieqns,remeqns,constrs,cache,env,funcs,einfo1,eoc,btp,symjacs));
  end match;
end findZeroCrossings1;

protected function findZeroCrossings2 "function: findZeroCrossings2

  Helper function to find_zero_crossing.
  modified: 2011-01 by wbraun
"
  input BackendDAE.Variables inVariables1;
  input BackendDAE.Variables knvars;
  input list<BackendDAE.Equation> inEquationLst2;
  input Integer inInteger3;
  input list<BackendDAE.WhenClause> inWhenClauseLst4;
  input Integer inInteger5;
  input Integer inIndex;
  input list<BackendDAE.ZeroCrossing> inZeroCrossingLst;
  
  output list<BackendDAE.ZeroCrossing> outZeroCrossingLst;
  output list<BackendDAE.Equation> outEquationLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  (outZeroCrossingLst, outEquationLst, outWhenClauseLst) :=
  matchcontinue (inVariables1,knvars,inEquationLst2,inInteger3,inWhenClauseLst4,inInteger5,inIndex,inZeroCrossingLst)
    local
      BackendDAE.Variables v;
      list<DAE.Exp> rellst1,rellst2,rel;
      list<BackendDAE.ZeroCrossing> zcs,zcs1,res,res1;
      Integer index_,size,countZC,ind,eq_count_1,eq_count,wc_count_1,wc_count;
      BackendDAE.Equation e,eq_res1,eq_res2;
      list<BackendDAE.Equation> xs,el,eq_reslst;
      DAE.Exp daeExp,e1,e2, eres1, eres2;
      BackendDAE.WhenClause wc;
      list<BackendDAE.WhenClause> xsWhen,wc_reslst;
      DAE.ElementSource source,source_;
      list<DAE.Statement> stmts,stmts_1;
      DAE.ComponentRef cref;
      list<BackendDAE.WhenOperator> whenOperations;
      list<DAE.Algorithm> algs,algs_res;
      Option<Integer> elseClause_;
      list<Integer> dimsize;
      
    case (_,_,{},_,{},_,_,res) then (res,{},{});
    
    // all algorithm stmts are processed firstly
   case (v,knvars,((e as BackendDAE.ALGORITHM(size=size,alg=DAE.ALGORITHM_STMTS(stmts), source= source_)) :: xs),eq_count,{},_,countZC,zcs)
      equation
        eq_count = eq_count + 1;
        ((stmts_1,(_,_,_,(res,countZC),(_,_,_)))) = traverseStmtsExps(stmts, collectZCAlgs, (DAE.RCONST(0.0),{},DAE.RCONST(0.0),(zcs,countZC),(eq_count,v,knvars)),knvars);
        (res1,eq_reslst,wc_reslst) = findZeroCrossings2(v, knvars,xs,eq_count, {}, 0,countZC,res);
      then
        (res1,BackendDAE.ALGORITHM(size,DAE.ALGORITHM_STMTS(stmts_1),source_)::eq_reslst,wc_reslst);

    
    // then all when clauses are processed 
    case (v,knvars,el,eq_count,((wc as BackendDAE.WHEN_CLAUSE(condition = daeExp,reinitStmtLst=whenOperations , elseClause = elseClause_ )) :: xsWhen),wc_count,countZC,zcs)
      equation
        wc_count = wc_count + 1;
        (eres1,countZC,res) = findZeroCrossings3(daeExp,zcs,countZC,-1,wc_count,v,knvars);
        (res1,eq_reslst,wc_reslst) = findZeroCrossings2(v, knvars,el,eq_count, xsWhen, wc_count,countZC,res);
      then
        (res1,eq_reslst,BackendDAE.WHEN_CLAUSE(eres1,whenOperations,elseClause_)::wc_reslst);
      
    // after all algorithms and when clauses are processed, all equations are processed 
    case (v,knvars,((e as BackendDAE.EQUATION(exp = e1,scalar = e2, source= source_)) :: xs),eq_count,{},_,countZC,zcs)
      equation
        eq_count = eq_count + 1;
        (eres1,countZC,zcs1) = findZeroCrossings3(e1,zcs,countZC,eq_count,-1,v,knvars);
        (eres2,countZC,res) = findZeroCrossings3(e2,zcs1,countZC,eq_count,-1,v,knvars);
        (res1,eq_reslst,wc_reslst) = findZeroCrossings2(v, knvars,xs,eq_count, {}, 0,countZC,res);
      then
        (res1,BackendDAE.EQUATION(eres1,eres2,source_)::eq_reslst,wc_reslst);
    case (v,knvars,((e as BackendDAE.COMPLEX_EQUATION(size=size,left=e1,right=e2,source=source)) :: xs),eq_count,{},_,countZC,zcs)
      equation
        eq_count = eq_count + 1;
        (eres1,countZC,zcs1) = findZeroCrossings3(e1,zcs,countZC,eq_count,-1,v,knvars);
        (eres2,countZC,res) = findZeroCrossings3(e2,zcs1,countZC,eq_count,-1,v,knvars);
        (res1,eq_reslst,wc_reslst) = findZeroCrossings2(v, knvars,xs,eq_count, {}, 0,countZC,res);
      then
        (res1,BackendDAE.COMPLEX_EQUATION(size,eres1,eres2,source)::eq_reslst,wc_reslst);
    case (v,knvars,((e as BackendDAE.ARRAY_EQUATION(dimSize=dimsize,left=e1,right=e2,source=source)) :: xs),eq_count,{},_,countZC,zcs)
      equation
        eq_count = eq_count + 1;
        (eres1,countZC,zcs1) = findZeroCrossings3(e1,zcs,countZC,eq_count,-1,v,knvars);
        (eres2,countZC,res) = findZeroCrossings3(e2,zcs1,countZC,eq_count,-1,v,knvars);
        (res1,eq_reslst,wc_reslst) = findZeroCrossings2(v, knvars,xs,eq_count, {}, 0,countZC,res);
      then
        (res1,BackendDAE.ARRAY_EQUATION(dimsize,eres1,eres2,source)::eq_reslst,wc_reslst);
    case (v,knvars,((e as BackendDAE.SOLVED_EQUATION(componentRef = cref,exp = e1,source= source_)) :: xs),eq_count,{},_,countZC,zcs)
      equation
        eq_count_1 = eq_count + 1;
        (eres1,countZC,res) = findZeroCrossings3(e1,zcs,countZC,eq_count,-1,v,knvars);
        (res1,eq_reslst,wc_reslst) = findZeroCrossings2(v, knvars,xs,eq_count, {}, 0,countZC,res);
      then
        (res1,BackendDAE.SOLVED_EQUATION(cref,eres1,source_)::eq_reslst,wc_reslst);
    case (v,knvars,((e as BackendDAE.RESIDUAL_EQUATION(exp = e1,source= source_)) :: xs),eq_count,{},_,countZC,zcs)
      equation
        eq_count = eq_count + 1;
        (eres1,countZC,res) = findZeroCrossings3(e1,zcs,countZC,eq_count,-1,v,knvars);
        (res1,eq_reslst,wc_reslst) = findZeroCrossings2(v, knvars,xs,eq_count, {}, 0,countZC,res);
      then
        (res1,BackendDAE.RESIDUAL_EQUATION(eres1,source_)::eq_reslst,wc_reslst);
        
    // let when equation pass they are discrete and can't contain ZeroCrossings 
    case (v,knvars,(e :: xs),eq_count,{},_,countZC,res)
      equation
        eq_count = eq_count + 1;
        (res1,eq_reslst,wc_reslst) = findZeroCrossings2(v, knvars,xs,eq_count, {}, 0,countZC,res);
      then
        (res1,e::eq_reslst,wc_reslst);
   end matchcontinue;
end findZeroCrossings2;

protected function findZeroCrossings3
"function: findZeroCrossings3
  Helper function to findZeroCrossing."
  input DAE.Exp e;
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  input Integer incountZC;
  input Integer counteq;
  input Integer countwc;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output DAE.Exp eres;
  output Integer outcountZC;
  output list<BackendDAE.ZeroCrossing> outZeroCrossings;
algorithm
  ((eres,((outZeroCrossings,outcountZC),(_,_,_,_)))) := Expression.traverseExpTopDown(e, collectZC, ((inZeroCrossings,incountZC),(counteq,countwc,vars,knvars)));
end findZeroCrossings3;

protected function collectZC "function: collectZeroCrossings

  Collects zero crossings in equations
  modified: 2011-01 by wbraun
"
  input tuple<DAE.Exp, tuple<tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,Integer,BackendDAE.Variables,BackendDAE.Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp,  Boolean, tuple<tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,Integer,BackendDAE.Variables,BackendDAE.Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      DAE.Exp e,e1,e2,e_1,eres;
      BackendDAE.Variables vars,knvars;
      list<BackendDAE.ZeroCrossing> zeroCrossings,zc_lst;
      DAE.Operator op;
      Integer indx,eq_count,wc_count,itmp,new_idx;
      list<Integer> eqs;
      String s1;
      BackendDAE.ZeroCrossing zc;
      
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))),((zeroCrossings,indx),(eq_count,wc_count,vars,knvars))))
    then ((e,false,((zeroCrossings,indx),(eq_count,wc_count,vars,knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))),((zeroCrossings,indx),(eq_count,wc_count,vars,knvars))))
      equation
    
        zc_lst = makeZeroCrossings({e}, {eq_count}, {wc_count});
        zc_lst = listAppend(zeroCrossings, zc_lst);
        zc_lst = mergeZeroCrossings(zc_lst);
        itmp = (listLength(zc_lst)-listLength(zeroCrossings));
         indx = indx + (listLength(zc_lst) - listLength(zeroCrossings));
      // Debug.fcall(Flags.RELIDX,print, "sample index: " +& intString(indx) +& "\n");  
      then ((e,true,((zc_lst,indx),(eq_count,wc_count,vars,knvars))));
    // function with discrete expressions generate no zerocrossing
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),((zeroCrossings,indx),(eq_count,wc_count,vars,knvars)))) 
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars,knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars,knvars);
      then
        ((e,true,((zeroCrossings,indx),(eq_count,wc_count,vars,knvars))));
    // All other functions generate zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),((zeroCrossings,indx),(eq_count,wc_count,vars,knvars))))
      equation
         new_idx=listLength(zeroCrossings);
        e_1 = DAE.RELATION(e1,op,e2,new_idx,NONE());
         {zc} = makeZeroCrossings({e_1}, {eq_count}, {wc_count});
        ((eres,zc_lst,indx))=zerocrossingindex(e_1,indx,zeroCrossings,zc);
     //Debug.fcall(Flags.RELIDX,print, "collectZC result zc : "  +& ExpressionDump.printExpStr(eres)+& "index: " +& intString(indx) +& "\n");
      then ((eres,true,((zc_lst,indx),(eq_count,wc_count,vars,knvars))));  
    case ((e,((zeroCrossings,indx),(eq_count,wc_count,vars,knvars)))) then ((e,true,((zeroCrossings,indx),(eq_count,wc_count,vars,knvars))));
  end matchcontinue;
end collectZC;


protected function collectZCAlgs "function: collectZeroCrossings

  Collects zero crossings in algorithms stamts, beside for loops those are
  processed by collectZCAlgsFor

  modified: 2011-01 by wbraun 
"
  input tuple<DAE.Exp, tuple<DAE.Exp, list<DAE.Exp>,DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      DAE.Exp e,e1,e2,e_1,eres,iterator,range;
      list<DAE.Exp> le;
      list<DAE.Statement> stmts;
      BackendDAE.Variables vars,knvars;
      list<BackendDAE.ZeroCrossing> zeroCrossings,zc_lst;
      DAE.Operator op;
      Integer indx,alg_indx,itmp,new_idx;
      list<Integer> eqs;
      String s1;
       BackendDAE.ZeroCrossing zc;
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))),(iterator,le,range,(zeroCrossings,indx),(alg_indx,vars,knvars))))
    then ((e,false,(iterator,le,range,(zeroCrossings,indx),(alg_indx,vars,knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))),(iterator,le,range,(zeroCrossings,indx),(alg_indx,vars,knvars))))
      equation
        eqs = {alg_indx};
        zc_lst = makeZeroCrossings({e}, eqs, {});
        zc_lst = listAppend(zeroCrossings, zc_lst);
        zc_lst = mergeZeroCrossings(zc_lst);
        indx = indx + (listLength(zc_lst) - listLength(zeroCrossings));
       // Debug.fcall(Flags.RELIDX,print, "sample index algotihm: " +& intString(indx) +& "\n");  
      then ((e,true,(iterator,le,range,(zc_lst,indx),(alg_indx,vars,knvars))));
    // function with discrete expressions generate no zerocrossing
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(iterator,le,range,(zeroCrossings,indx),(alg_indx,vars,knvars)))) 
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars,knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars,knvars);
      then ((e,true,(iterator,le,range,(zeroCrossings,indx),(alg_indx,vars,knvars))));
    // All other functions generate zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(iterator,le,range,(zeroCrossings,indx),(alg_indx,vars,knvars))))
      equation
       // e_1 = DAE.RELATION(e1,op,e2,indx,NONE());
        eqs = {alg_indx};
        new_idx=listLength(zeroCrossings);
        e_1 = DAE.RELATION(e1,op,e2,new_idx,NONE());
       {zc} = makeZeroCrossings({e_1}, eqs, {});
      ((eres,zc_lst,indx))=zerocrossingindex(e_1,indx,zeroCrossings,zc);
      // Debug.fcall(Flags.RELIDX,print, "collectZCAlgs result zc : "  +& ExpressionDump.printExpStr(eres)+& "index:"  +& intString(indx) +& "\n");
      then ((eres,true,(iterator,le,range,(zc_lst,indx),(alg_indx,vars,knvars))));
    case ((e,(iterator,le,range,(zeroCrossings,indx),(alg_indx,vars,knvars)))) then ((e,true,(iterator,le,range,(zeroCrossings,indx),(alg_indx,vars,knvars))));
  end matchcontinue;
end collectZCAlgs;



protected function zerocrossingindex
  input DAE.Exp exp;
  input Integer index;
  input list<BackendDAE.ZeroCrossing> zeroCrossings;
  input BackendDAE.ZeroCrossing zc;
  output tuple<DAE.Exp,list<BackendDAE.ZeroCrossing>,Integer> out_exp;
algorithm
  out_exp := matchcontinue (exp,index,zeroCrossings,/*inputzeroinfo,*/zc)
    local
      DAE.Exp exp,e_1,e1,e2;
      DAE.Operator op;
      list<BackendDAE.ZeroCrossing> newzero,existzero,zc_lst;
      BackendDAE.ZeroCrossing z_c,zc1;
      Integer indx,length,eq_count,wc_count/*, new_idx*/;
      BackendDAE.Variables vars,knvars;
      String str;
    case ((exp as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),index,zeroCrossings,z_c)
      equation
        {} = List.select1(zeroCrossings, sameZeroCrossing,z_c/*zc1*/);
        zc_lst = listAppend(zeroCrossings, {z_c});
        //Debug.fcall(Flags.RELIDX,print, " zerocrossingindex 1 : "  +& ExpressionDump.printExpStr(exp) +& " index: " +& intString(index) +& "\n");
      then 
         ((exp,zc_lst,index));
    case ((exp as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),index,zeroCrossings,z_c)
      equation
        newzero= List.select1(zeroCrossings, sameZeroCrossing,z_c);
        length=listLength(newzero);
        BackendDAE.ZERO_CROSSING((e_1 as DAE.RELATION(_,_,_,indx,_)),_,_)=List.first(newzero);
        //Debug.fcall(Flags.RELIDX,print, " zerocrossingindex 2: results "  +& ExpressionDump.printExpStr(e_1)+& "index: " +& intString(indx) +& " lenght: " +& intString(length) +& "\n");
      then 
        ((e_1,zeroCrossings,indx));
    case (exp ,_,_,_)
      equation
        str = " failure in zerocrossingindex for: "  +& ExpressionDump.printExpStr(exp);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();

   end matchcontinue;
end zerocrossingindex;



protected function traverseStmtsExps "function: traverseStmtExps
  Handles the traversing of list<DAE.Statement>.
  Works with the help of Expression.traverseExpTopDown to find 
  ZeroCrossings in algorithm statements
  modified: 2011-01 by wbraun"
  input list<DAE.Statement> inStmts;
  input FuncExpType func;
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>> iextraArg;
  input BackendDAE.Variables knvars;
  output tuple<list<DAE.Statement>, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> outTplStmtTypeA;
  partial function FuncExpType 
    input tuple<DAE.Exp,tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> arg;
    output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> oarg;
  end FuncExpType;
algorithm
  (outTplStmtTypeA) := match(inStmts,func,iextraArg,knvars)
    local
      DAE.Exp e_1,e_2,e,e2,iteratorExp;
      Integer le,ix;
      list<DAE.Exp> expl1,expl2,iteratorexps;
      DAE.ComponentRef cr_1,cr;
      list<DAE.Statement> xs_1,xs,stmts,stmts2;
      DAE.Type tp,tt;
      DAE.Statement x,ew,ew_1;
      Boolean b1;
      String id1,str;
      list<Integer> li;
      DAE.ElementSource source;
      Algorithm.Else algElse;
      Absyn.Path fnName;
      Absyn.MatchType matchType;
      DAE.Pattern pattern;
      BackendDAE.Variables vars;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>> extraArg;
      
    case ({},_,extraArg,knvars) then (({},extraArg));
      
    case ((DAE.STMT_ASSIGN(type_ = tp,exp1 = e2,exp = e, source = source) :: xs),func, extraArg, knvars)
      equation
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((e_2,extraArg)) = Expression.traverseExpTopDown(e2, func, extraArg);
        ((xs_1,extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_ASSIGN(tp,e_2,e_1,source) :: xs_1,extraArg));
        
    case ((DAE.STMT_TUPLE_ASSIGN(type_ = tp,expExpLst = expl1, exp = e, source = source) :: xs),func, extraArg, knvars)
      equation
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((expl2, extraArg)) = Expression.traverseExpListTopDown(expl1,func,extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_TUPLE_ASSIGN(tp,expl2,e_1,source) :: xs_1,extraArg));
        
    case ((DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source) :: xs),func, extraArg, knvars)
      equation
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((e_2 as DAE.CREF(cr_1,_),_, extraArg)) = func((Expression.crefExp(cr), extraArg));
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_ASSIGN_ARR(tp,cr_1,e_1,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_ASSIGN_ARR(type_ = tp,componentRef = cr, exp = e, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        failure(((DAE.CREF(_,_),_,_)) = func((Expression.crefExp(cr), extraArg)));
        true = Flags.isSet(Flags.FAILTRACE);
        print(DAEDump.ppStatementStr(x));
        print("Warning, not allowed to set the componentRef to a expression in BackendDAECreate.traverseStmtsExps for ZeroCrosssing\n");
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_ASSIGN_ARR(tp,cr,e_1,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_IF(exp=e,statementLst=stmts,else_ = algElse, source = source)) :: xs), func, extraArg, knvars)
      equation
        ((algElse,extraArg)) = traverseStmtsElseExps(algElse, func, extraArg, knvars);
        ((stmts2,extraArg)) = traverseStmtsExps(stmts, func, extraArg, knvars);
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1,extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_IF(e_1,stmts2,algElse,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_FOR(type_=tp,iterIsArray=b1,iter=id1,index=ix,range=e,statementLst=stmts, source = source)) :: xs),func, extraArg, knvars)
      equation
        cr = ComponentReference.makeCrefIdent(id1, tp, {});
        iteratorExp = Expression.crefExp(cr);
        iteratorexps = extendRange(e,knvars);
        ((stmts2, extraArg)) = traverseStmtsForExps(iteratorExp, iteratorexps,e, stmts, knvars, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_FOR(tp,b1,id1,ix,e,stmts2,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_WHILE(exp = e,statementLst=stmts, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((stmts2, extraArg)) = traverseStmtsExps(stmts,func, extraArg, knvars);
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_WHILE(e_1,stmts2,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=NONE(),helpVarIndices=li, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((stmts2, extraArg)) = traverseStmtsExps(stmts,func, extraArg, knvars);
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_WHEN(e_1,stmts2,NONE(),li,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_WHEN(exp = e,statementLst=stmts,elseWhen=SOME(ew),helpVarIndices=li, source = source)) :: xs),func, extraArg, knvars)
      equation
        (({ew_1}, extraArg)) = traverseStmtsExps({ew},func, extraArg, knvars);
        ((stmts2, extraArg)) = traverseStmtsExps(stmts,func, extraArg, knvars);
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_WHEN(e_1,stmts2,SOME(ew),li,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_ASSERT(cond = e, msg=e2, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x :: xs_1,extraArg));
        
    case (((x as DAE.STMT_TERMINATE(msg = e, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x :: xs_1,extraArg));
        
    case (((x as DAE.STMT_REINIT(var = e,value=e2, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x :: xs_1,extraArg));
        
    case (((x as DAE.STMT_NORETCALL(exp = e, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_NORETCALL(e_1,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_RETURN(source = source)) :: xs),func, extraArg, knvars)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x :: xs_1,extraArg));
        
    case (((x as DAE.STMT_BREAK(source = source)) :: xs),func, extraArg, knvars)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x :: xs_1,extraArg));
        
        // MetaModelica extension. KS
    case (((x as DAE.STMT_FAILURE(body=stmts, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((stmts2, extraArg)) = traverseStmtsExps(stmts,func, extraArg, knvars);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_FAILURE(stmts2,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_TRY(tryBody=stmts, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((stmts2, extraArg)) = traverseStmtsExps(stmts,func, extraArg, knvars);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_TRY(stmts2,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_CATCH(catchBody=stmts, source = source)) :: xs),func, extraArg, knvars)
      equation
        ((stmts2, extraArg)) = traverseStmtsExps(stmts,func, extraArg, knvars);
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((DAE.STMT_CATCH(stmts2,source) :: xs_1,extraArg));
        
    case (((x as DAE.STMT_THROW(source = source)) :: xs),func, extraArg, knvars)
      equation
        ((xs_1, extraArg)) = traverseStmtsExps(xs, func, extraArg, knvars);
      then ((x :: xs_1,extraArg));
        
    case ((x :: xs),func, extraArg, knvars)
      equation
        str = DAEDump.ppStatementStr(x);
        str = "Algorithm.traverseStmtsExps not implemented correctly: " +& str;
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end match;
end traverseStmtsExps;

protected function traverseStmtsElseExps "
Author: BZ, 2008-12
Helper function for traverseStmtsExps
to find ZeroCrosssings in algorithm Else statements
modified: 2011-01 by wbraun"
  input Algorithm.Else inElse;
  input FuncExpType func;
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>> iextraArg;
  input BackendDAE.Variables knvars;
  output tuple<Algorithm.Else, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> outTplStmtTypeA;
  partial function FuncExpType 
    input tuple<DAE.Exp,tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> arg;
    output tuple<DAE.Exp,Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> oarg;
  end FuncExpType;
algorithm
  outTplStmtTypeA := matchcontinue(inElse,func,iextraArg,knvars)
    local
      DAE.Exp e,e_1;
      list<DAE.Statement> st,st_1;
      Algorithm.Else el,el_1;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>> extraArg;
      
    case(DAE.NOELSE(),_,extraArg,knvars) then ((DAE.NOELSE(),extraArg));
    case(DAE.ELSEIF(e,st,el),func,extraArg,knvars)
      equation
        ((el_1,extraArg)) = traverseStmtsElseExps(el,func,extraArg,knvars);
        ((st_1,extraArg)) = traverseStmtsExps(st,func,extraArg,knvars);
        ((e_1,extraArg)) = Expression.traverseExpTopDown(e, func, extraArg);
      then ((DAE.ELSEIF(e_1,st_1,el_1),extraArg));
    case(DAE.ELSE(st),func,extraArg,knvars)
      equation
        ((st_1,extraArg)) = traverseStmtsExps(st,func,extraArg,knvars);
      then ((DAE.ELSE(st_1),extraArg));
  end matchcontinue;
end traverseStmtsElseExps;


protected function collectZCAlgsFor "function: collectZeroCrossings
  Collects zero crossings in for loops  
  added: 2011-01 by wbraun"
  input tuple<DAE.Exp, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> inTplExpExpTplExpExpLstVariables;
  output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> outTplExpExpTplExpExpLstVariables;
algorithm
  outTplExpExpTplExpExpLstVariables:=
  matchcontinue (inTplExpExpTplExpExpLstVariables)
    local
      DAE.Exp e,e1,e2,e_1,eres, iterator, iterator1, range;
      list<DAE.Exp> inExpLst,explst;
      BackendDAE.Variables vars,knvars;
      list<BackendDAE.ZeroCrossing> zeroCrossings,zc;
      DAE.Operator op;
      Integer indx,alg_indx,itmp;
      list<Integer> eqs;
      list<DAE.Statement> stmts;
      Boolean b1,b2;
      String s1;
      DAE.Exp startvalue,stepvalue;
      Option<DAE.Exp> stepvalueopt;
      Integer istart,istep;
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "noEvent"))),(iterator,inExpLst,range,(zeroCrossings,indx),(alg_indx,vars,knvars))))
    then ((e,false,(iterator,inExpLst,range,(zeroCrossings,indx),(alg_indx,vars,knvars))));
    case (((e as DAE.CALL(path = Absyn.IDENT(name = "sample"))),(iterator,inExpLst,range,(zeroCrossings,indx),(alg_indx,vars,knvars))))
      equation
        eqs = {alg_indx};
        zc = makeZeroCrossings({e}, eqs, {});
        zc = listAppend(zeroCrossings, zc);
        zc = mergeZeroCrossings(zc);
        indx = indx + (listLength(zc) - listLength(zeroCrossings));
        Debug.fcall(Flags.RELIDX,print, "collectZCAlgsFor sample" +& "\n");
      then ((e,true,(iterator,inExpLst,range,(zc,indx),(alg_indx,vars,knvars))));
    // function with discrete expressions generate no zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(iterator,inExpLst,range,(zeroCrossings,indx),(alg_indx,vars,knvars)))) 
      equation
        true = BackendDAEUtil.isDiscreteExp(e1, vars,knvars);
        true = BackendDAEUtil.isDiscreteExp(e2, vars,knvars);
      then ((e,true,(iterator,inExpLst,range,(zeroCrossings,indx),(alg_indx,vars,knvars))));
    // All other functions generate zerocrossing.
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(iterator,inExpLst,range as DAE.RANGE(start=startvalue,step=stepvalueopt),(zeroCrossings,indx),(alg_indx,vars,knvars))))
      equation
        b1 = Expression.expContains(e1,iterator);
        b2 = Expression.expContains(e2,iterator);
        true = Util.boolOrList({b1,b2});
        stepvalue = Util.getOptionOrDefault(stepvalueopt,DAE.ICONST(1));
        istart = expInt(startvalue,knvars);
        istep = expInt(stepvalue,knvars);
        e_1 = DAE.RELATION(e1,op,e2,indx,SOME((iterator,istart,istep)));
        (explst,indx) = replaceIteratorwithStaticValues(e,iterator,inExpLst,indx);
        eqs = {alg_indx};
        zc = makeZeroCrossings(explst, eqs, {});
        zc = listAppend(zeroCrossings, zc);
        zc = mergeZeroCrossings(zc);
        itmp = (listLength(zc)-listLength(zeroCrossings));
        eres = Util.if_((itmp>0),e_1,e);
        Debug.fcall(Flags.RELIDX,print, "collectZCAlgsFor result zc : "  +& ExpressionDump.printExpStr(eres)+& "index:"  +& intString(indx) +& "\n");
      then ((eres,true,(iterator,inExpLst,range,(zc,indx),(alg_indx,vars,knvars))));
    // All other functions generate zerocrossing.  
    case (((e as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2)),(iterator,inExpLst,range,(zeroCrossings,indx),(alg_indx,vars,knvars))))
      equation
        b1 = Expression.expContains(e1,iterator);
        b2 = Expression.expContains(e2,iterator);
        false = Util.boolOrList({b1,b2});
        e_1 = DAE.RELATION(e1,op,e2,indx,NONE());
        eqs = {alg_indx};
        zc = makeZeroCrossings({e_1}, eqs, {});
        zc = listAppend(zeroCrossings, zc);
        zc = mergeZeroCrossings(zc);
        itmp = (listLength(zc)-listLength(zeroCrossings));
        indx = indx + itmp;
        eres = Util.if_((itmp>0),e_1,e);
        Debug.fcall(Flags.RELIDX,print, "collectZCAlgsFor result zc : "  +& ExpressionDump.printExpStr(eres)+& "index:"  +& intString(indx) +& "\n");
      then ((eres,true,(iterator,inExpLst,range,(zc,indx),(alg_indx,vars,knvars))));
    case ((e,(iterator,inExpLst,range,(zeroCrossings,indx),(alg_indx,vars,knvars)))) then ((e,true,(iterator,inExpLst,range,(zeroCrossings,indx),(alg_indx,vars,knvars))));
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
  (outZeroCrossings,outIndex) := matchcontinue(inExp,inIterator,inExpLst,inIndex)
    local
      DAE.Exp e,e1,e2,i,exp,res1,e_1;
      DAE.Operator op;
      list<DAE.Exp> rest,res2;
      Integer index;
    case (_,_,{},inIndex) then ({},inIndex);
    case (exp as DAE.RELATION(exp1 = e1,operator = op,exp2 = e2),i,e::rest,index) 
      equation
        e_1 = DAE.RELATION(e1,op,e2,index,NONE());
        ((res1,(_,_))) = replaceExp((e_1,(i,e)));
        (res2,index) = replaceIteratorwithStaticValues(exp,i,rest,index+1);
        res2 = listAppend({res1},res2);
      then (res2,index);
    case (_,_,_,_)
      equation
        print("BackendDAECreate.replaceIteratorwithStaticValues failed \n");
      then
        fail();
  end matchcontinue;
end replaceIteratorwithStaticValues;


protected function traverseStmtsForExps
"Helper function for traverseStmtsExps
 to processed for loops to search ZeroCrosssings 
 modified: 2011-01 by wbraun"
  input DAE.Exp inIteratorExp;
  input list<DAE.Exp> inExplst;
  input DAE.Exp inRange;
  input list<DAE.Statement> inStmts;
  input BackendDAE.Variables knvars;
  input FuncExpType func;
  input tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp,tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>> iextraArg;
  output tuple<list<DAE.Statement>, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp, tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> outTplStmtTypeA;
  partial function FuncExpType 
    input tuple<DAE.Exp, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp,tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> arg;
    output tuple<DAE.Exp, Boolean, tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp,tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>>> oarg;
  end FuncExpType;
algorithm
  outTplStmtTypeA := matchcontinue (inIteratorExp,inExplst,inRange,inStmts,knvars,func,iextraArg)
    local
      list<DAE.Statement> statementLst,statementLst1,statementLst2,statementLst3,statementLst4;
      DAE.Exp e,ie,range;
      Integer le;
      list<DAE.Exp> inExplst;
      BackendDAE.Variables v,kn;
      list<BackendDAE.Equation> eq,eqn;
      list<BackendDAE.ZeroCrossing> zcl,zcs;
      Integer idx,alg_idx;
      String s1;
      tuple<DAE.Exp, list<DAE.Exp>, DAE.Exp,tuple<list<BackendDAE.ZeroCrossing>,Integer>, tuple<Integer,BackendDAE.Variables,BackendDAE.Variables>> extraArg;
      
    case (_,{},_,statementLst,knvars,_,extraArg) then ((statementLst,extraArg));
    case (ie,inExplst,range,statementLst,knvars,func,(_,_,_,(zcs,idx),(alg_idx,v,kn)))
      equation
        ((statementLst, extraArg )) = traverseStmtsExps(statementLst, collectZCAlgsFor, (ie,inExplst,range,(zcs,idx),(alg_idx,v,kn)), knvars);
      then
        ((statementLst ,extraArg));
    case (_,_,_,_,_,_,_)
      equation
        print("BackendDAECreate.traverseAlgStmtsFor failed \n");
      then
        fail();
  end matchcontinue;
end traverseStmtsForExps;


public function zeroCrossingsEquations
"Returns a list of all equations (by their index) that contain a zero crossing
 Used e.g. to find out which discrete equations are not part of a zero crossing"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output list<Integer> eqns;
algorithm
  eqns := match (syst,shared)
    local
      list<BackendDAE.ZeroCrossing> zcLst;
      list<list<Integer>> zcEqns;
      list<Integer> wcEqns;
      BackendDAE.EquationArray eqnArr;
    case (BackendDAE.EQSYSTEM(orderedEqs=eqnArr),BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(zeroCrossingLst = zcLst))) 
      equation
        zcEqns = List.map(zcLst,zeroCrossingEquations);
        wcEqns = whenEquationsIndices(eqnArr);
        eqns = List.unionList(listAppend(zcEqns,{wcEqns}));
      then eqns;
  end match;
end zeroCrossingsEquations;

protected function makeZeroCrossing
"function: makeZeroCrossing
  Constructs a BackendDAE.ZeroCrossing from an expression and lists of equation indices
  and when clause indices."
  input DAE.Exp inExp1;
  input list<Integer> eq_ind;
  input list<Integer> wc_ind;
  output BackendDAE.ZeroCrossing outZeroCrossing;
algorithm
  outZeroCrossing := BackendDAE.ZERO_CROSSING(inExp1,eq_ind,wc_ind);
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
  outZeroCrossingLst := match (inExpExpLst1,inIntegerLst2,inIntegerLst3)
    local
      BackendDAE.ZeroCrossing res;
      list<BackendDAE.ZeroCrossing> resx;
      DAE.Exp e;
      list<DAE.Exp> xs;
      list<BackendDAE.Value> eq_ind,wc_ind;
      String s1;
    case ({},_,_) then {};
    case ((e :: xs),{-1},wc_ind)
      equation
        resx = makeZeroCrossings(xs, {}, wc_ind);
        res = makeZeroCrossing(e, {}, wc_ind);
      then
        (res :: resx);
    case ((e :: xs),eq_ind,{-1})
      equation
        resx = makeZeroCrossings(xs, eq_ind, {});
        res = makeZeroCrossing(e, eq_ind, {});
      then
        (res :: resx);
    case ((e :: xs),eq_ind,wc_ind)
      equation
        resx = makeZeroCrossings(xs, eq_ind, wc_ind);
        res = makeZeroCrossing(e, eq_ind, wc_ind);
      then
        (res :: resx);
  end match;
end makeZeroCrossings;

protected function makeWhenClauses
"function: makeWhenClauses
  Constructs a list of identical BackendDAE.WhenClause elements
  Arg1: Number of elements to construct
  Arg2: condition expression of the when clause
  outputs: (WhenClause list)"
  input Integer n           "Number of copies to make.";
  input DAE.Exp inCondition "the condition expression";
  input list<BackendDAE.WhenOperator> inReinitStatementLst;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
algorithm
  outWhenClauseLst:=
  matchcontinue (n,inCondition,inReinitStatementLst)
    local
      BackendDAE.Value i_1,i;
      list<BackendDAE.WhenClause> res;
      DAE.Exp cond;
      list<BackendDAE.WhenOperator> reinit;

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

    else
      equation
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

protected function whenEquationsIndices "Returns all equation-indices that contain a when clause"
  input BackendDAE.EquationArray eqns;
  output list<Integer> res;
algorithm
   res := match (eqns)
     case(eqns) equation
         res=whenEquationsIndices2(1,BackendDAEUtil.equationArraySize(eqns),eqns);
       then res;
   end match;
end whenEquationsIndices;

protected function whenEquationsIndices2
"Help function"
  input Integer i;
  input Integer size;
  input BackendDAE.EquationArray eqns;
  output list<Integer> eqnLst;
algorithm
  eqnLst := matchcontinue(i,size,eqns)
    case(i,size,eqns)
      equation
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

end BackendDAECreate;

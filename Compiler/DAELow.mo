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

package DAELow
" file:         DAELow.mo
  package:     DAELow
  description: BackendDAE.DAELow a lower form of DAE including sparse matrises for
               BLT decomposition, etc.

  RCS: $Id$

  This module is a lowered form of a DAE including equations
  and simple equations in
  two separate lists. The variables are split into known variables
  parameters and constants, and unknown variables,
  states and algebraic variables.
  The module includes the BLT sorting algorithm which sorts the
  equations into blocks, and the index reduction algorithm using
  dummy derivatives for solving higher index problems.
  It also includes the tarjan algorithm to detect strong components
  in the BLT sorting."

public import Absyn;
public import BackendDAE;
public import Builtin;
public import DAE;
public import SCode;
public import Values;

protected import Algorithm;
protected import BackendDump;
protected import BackendDAECreate;
protected import BackendDAEUtil;
protected import BackendDAEOptimize;
protected import BackendVarTransform;
protected import BackendVariable;
protected import Ceval;
protected import ClassInf;
protected import ComponentReference;
protected import DAEEXT;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Env;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSolve;
protected import ExpressionSimplify;
protected import OptManager;
protected import RTOpts;
protected import System;
protected import Util;
protected import VarTransform;

public constant String derivativeNamePrefix="$DER";

public function matchingAlgorithm
"function: matchingAlgorithm
  author: PA
  This function performs the matching algorithm, which is the first
  part of sorting the equations into BLT (Block Lower Triangular) form.
  The matching algorithm finds a variable that is solved in each equation.
  But to also find out which equations forms a block of equations, the
  the second algorithm of the BLT sorting: strong components
  algorithm is run.
  This function returns the updated DAE in case of index reduction has
  added equations and variables, and the incidence matrix. The variable
  assignments is returned as a vector of variable indices, as well as its
  inverse, i.e. which equation a variable is solved in as a vector of
  equation indices.
  BackendDAE.MatchingOptions contain options given to the algorithm.
    - if index reduction should be used or not.
    - if the equation system is allowed to be under constrained or not
      which is used when generating code for initial equations.

  inputs:  (DAELow,IncidenceMatrix, BackendDAE.IncidenceMatrixT, MatchingOptions)
  outputs: (int vector /* vector of equation indices */ ,
              int vector /* vector of variable indices */,
              DAELow,IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input DAE.FunctionTree inFunctions;
  output array<Integer> outIntegerArray1;
  output array<Integer> outIntegerArray2;
  output BackendDAE.DAELow outDAELow3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
algorithm
  (outIntegerArray1,outIntegerArray2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5) :=
  matchcontinue (inDAELow,inIncidenceMatrix,inIncidenceMatrixT,inMatchingOptions,inFunctions)
    local
      BackendDAE.Value nvars,neqns,memsize;
      String ns,ne;
      BackendDAE.Assignments assign1,assign2,ass1,ass2;
      BackendDAE.DAELow dae,dae_1,dae_2;
      BackendDAE.Variables v,kv,v_1,kv_1,vars,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,re,ie,e_1,re_1,ie_1,eqns;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev,einfo;
      array<list<BackendDAE.Value>> m,mt,m_1,mt_1;
      BackendDAE.BinTree s;
      list<BackendDAE.Equation> e_lst,re_lst,ie_lst,e_lst_1,re_lst_1,ie_lst_1;
      list<BackendDAE.MultiDimEquation> ae_lst,ae_lst1;
      array<BackendDAE.Value> vec1,vec2;
      BackendDAE.MatchingOptions match_opts;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.BinTree s;
      list<BackendDAE.WhenClause> whenclauses;
      list<BackendDAE.ZeroCrossing> zero_crossings;
      list<DAE.Algorithm> algs;
    /* fail case if daelow is empty */
    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,match_opts,inFunctions)
      equation
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        (nvars == 0) = true;
        (neqns == 0) = true;
        vec1 = listArray({});
        vec2 = listArray({});
      then
        (vec1,vec2,dae,m,mt);
    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,BackendDAE.REMOVE_SIMPLE_EQN())),inFunctions)
      equation
        DAEEXT.clearDifferentiated();
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,(dae as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc)),m,mt,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts,inFunctions,{},{});
        /* NOTE: Here it could be possible to run removeSimpleEquations again, since algebraic equations
        could potentially be removed after a index reduction has been done. However, removing equations here
        also require that e.g. zero crossings, array equations, etc. must be recalculated. */       
        s = BackendDAEUtil.statesDaelow(dae);
        e_lst = BackendDAEUtil.equationList(e);
        re_lst = BackendDAEUtil.equationList(re);
        ie_lst = BackendDAEUtil.equationList(ie);
        ae_lst = arrayList(ae);
        algs = arrayList(al);
        (v,kv,e_lst,re_lst,ie_lst,ae_lst,algs,av) = BackendDAEOptimize.removeSimpleEquations(v,kv, e_lst, re_lst, ie_lst, ae_lst, algs, s); 
         BackendDAE.EVENT_INFO(whenClauseLst=whenclauses) = ev;
        (zero_crossings) = BackendDAECreate.findZeroCrossings(v,kv,e_lst,ae_lst,whenclauses,algs);
        e = BackendDAEUtil.listEquation(e_lst);
        re = BackendDAEUtil.listEquation(re_lst);
        ie = BackendDAEUtil.listEquation(ie_lst);
        ae = listArray(ae_lst);    
        einfo = BackendDAE.EVENT_INFO(whenclauses,zero_crossings); 
        dae_1 = BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,einfo,eoc);   
        m_1 = BackendDAEUtil.incidenceMatrix(dae_1) "Rerun matching to get updated assignments and incidence matrices
                                    TODO: instead of rerunning: find out which equations are removed
                                    and remove those from assignments and incidence matrix." ;
        mt_1 = BackendDAEUtil.transposeMatrix(m_1);
        nvars = arrayLength(m_1);
        neqns = arrayLength(mt_1);
        memsize = nvars + nvars;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae_2,m,mt,_,_) = matchingAlgorithm2(dae_1, m_1, mt_1, nvars, neqns, 1, assign1, assign2, match_opts, inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae_2,m,mt);

    case ((dae as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,BackendDAE.KEEP_SIMPLE_EQN())),inFunctions)
      equation
        checkMatching(dae, match_opts);
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        ns = intString(nvars);
        ne = intString(neqns);
        (nvars > 0) = true;
        (neqns > 0) = true;
        memsize = nvars + nvars "Worst case, all eqns are differentiated once. Create nvars2 assignment elements" ;
        assign1 = assignmentsCreate(nvars, memsize, 0);
        assign2 = assignmentsCreate(nvars, memsize, 0);
        (ass1,ass2,dae,m,mt,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts, inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae,m,mt);
    case (_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "- DAELow.MatchingAlgorithm failed\n");
      then
        fail();        
  end matchcontinue;
end matchingAlgorithm;

public function checkMatching
"function: checkMatching
  author: PA

  Checks that the matching is correct, i.e. that the number of variables
  is the same as the number of equations. If not, the function fails and
  prints an error message.
  If matching options indicate that underconstrained systems are ok, no
  check is performed."
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.MatchingOptions inMatchingOptions;
algorithm
  _ := matchcontinue (inDAELow,inMatchingOptions)
    local
      BackendDAE.Value esize,vars_size;
      BackendDAE.EquationArray eqns;
      String esize_str,vsize_str;
    case (_,(_,BackendDAE.ALLOW_UNDERCONSTRAINED(),_)) then ();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = BackendDAEUtil.equationSize(eqns);
        (esize == vars_size) = true;
      then
        ();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = BackendDAEUtil.equationSize(eqns);
        (esize < vars_size) = true;
        esize = esize - 1;
        vars_size = vars_size - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.UNDERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (BackendDAE.DAELOW(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = BackendDAEUtil.equationSize(eqns);
        (esize > vars_size) = true;
        esize = esize - 1;
        vars_size = vars_size - 1 "remove dummy var" ;
        esize_str = intString(esize) "remove dummy var" ;
        vsize_str = intString(vars_size);
        Error.addMessage(Error.OVERDET_EQN_SYSTEM, {esize_str,vsize_str});
      then
        fail();
    case (_,_)
      equation
        Debug.fprint("failtrace", "- DAELow.checkMatching failed\n");
      then
        fail();
  end matchcontinue;
end checkMatching;

public function assignmentsVector
"function: assignmentsVector
  author: PA
  Converts BackendDAE.Assignments to vector of int elements"
  input BackendDAE.Assignments inAssignments;
  output array<Integer> outIntegerArray;
algorithm
  outIntegerArray := matchcontinue (inAssignments)
    local
      array<BackendDAE.Value> newarr,newarr_1,arr;
      array<BackendDAE.Value> vec;
      BackendDAE.Value size;
    case (BackendDAE.ASSIGNMENTS(actualSize = size,arrOfIndices = arr))
      equation
        newarr = arrayCreate(size, 0);
        newarr_1 = Util.arrayNCopy(arr, newarr, size);
        vec = array_copy(newarr_1);
      then
        vec;
    case (_)
      equation
        print("- DAELow.assignmentsVector failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsVector;

public function assignmentsCreate
"function: assignmentsCreate
  author: PA
  Creates an assignment array of n elements, filled with value v
  inputs:  (int /* size */, int /* memsize */, int)
  outputs: => Assignments"
  input Integer n;
  input Integer memsize;
  input Integer v;
  output BackendDAE.Assignments outAssignments;
  list<BackendDAE.Value> lst;
  array<BackendDAE.Value> arr;
algorithm
  lst := Util.listFill(0, memsize);
  arr := listArray(lst) "  array_create(memsize,v) => arr &" ;
  outAssignments := BackendDAE.ASSIGNMENTS(n,memsize,arr);
end assignmentsCreate;

protected function assignmentsSetnth
"function: assignmentsSetnth
  author: PA
  Sets the n:nt assignment Value.
  inputs:  (Assignments, int /* n */, int /* value */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments1;
  input Integer inInteger2;
  input Integer inInteger3;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments1,inInteger2,inInteger3)
    local
      array<BackendDAE.Value> arr;
      BackendDAE.Value s,ms,n,v;
    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),n,v)
      equation
        arr = arrayUpdate(arr, n + 1, v);
      then
        BackendDAE.ASSIGNMENTS(s,ms,arr);
    case (_,_,_)
      equation
        print("-assignments_setnth failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsSetnth;

protected function assignmentsExpand
"function: assignmentsExpand
  author: PA
  Expands the assignments array with n values, initialized with zero.
  inputs:  (Assignments, int /* n */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments;
  input Integer inInteger;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments,inInteger)
    local
      BackendDAE.Assignments ass,ass_1,ass_2;
      BackendDAE.Value n_1,n;
    case (ass,0) then ass;
    case (ass,n)
      equation
        true = n > 0;
        ass_1 = assignmentsAdd(ass, 0);
        n_1 = n - 1;
        ass_2 = assignmentsExpand(ass_1, n_1);
      then
        ass_2;
    case (ass,_)
      equation
        print("DAELow.assignmentsExpand: n should not be negative!");
      then
        fail();
  end matchcontinue;
end assignmentsExpand;

protected function assignmentsAdd
"function: assignmentsAdd
  author: PA
  Adds a value to the end of the assignments array. If memsize = actual size
  this means copying the whole array, expanding it size to fit the value
  Expansion is made by a factor 1.4. Otherwise, the element is inserted taking O(1) in
  insertion cost.
  inputs:  (Assignments, int /* value */)
  outputs:  Assignments"
  input BackendDAE.Assignments inAssignments;
  input Integer inInteger;
  output BackendDAE.Assignments outAssignments;
algorithm
  outAssignments := matchcontinue (inAssignments,inInteger)
    local
      Real msr,msr_1;
      BackendDAE.Value ms_1,s_1,ms_2,s,ms,v;
      array<BackendDAE.Value> arr_1,arr_2,arr;

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        (s == ms) = true "Out of bounds, increase and copy." ;
        msr = intReal(ms);
        msr_1 = msr *. 0.4;
        ms_1 = realInt(msr_1);
        s_1 = s + 1;
        ms_2 = ms_1 + ms;
        arr_1 = Util.arrayExpand(ms_1, arr, 0);
        arr_2 = arrayUpdate(arr_1, s + 1, v);
      then
        BackendDAE.ASSIGNMENTS(s_1,ms_2,arr_2);

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        arr_1 = arrayUpdate(arr, s + 1, v) "space available, increase size and insert element." ;
        s_1 = s + 1;
      then
        BackendDAE.ASSIGNMENTS(s_1,ms,arr_1);

    case (BackendDAE.ASSIGNMENTS(actualSize = s,allocatedSize = ms,arrOfIndices = arr),v)
      equation
        print("-assignments_add failed\n");
      then
        fail();
  end matchcontinue;
end assignmentsAdd;

public function matchingAlgorithm2
"function: matchingAlgorithm2
  author: PA
  This is the outer loop of the matching algorithm
  The find_path algorithm is called for each equation/variable.
  inputs:  (DAELow,IncidenceMatrix, IncidenceMatrixT
             ,int /* number of vars */
             ,int /* number of eqns */
             ,int /* current var */
             ,Assignments  /* assignments, array of eqn indices */
             ,Assignments /* assignments, array of var indices */
             ,MatchingOptions) /* options for matching alg. */
  outputs: (Assignments, /* assignments, array of equation indices */
              Assignments, /* assignments, list of variable indices */
              DAELow, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input BackendDAE.Assignments inAssignments7;
  input BackendDAE.Assignments inAssignments8;
  input BackendDAE.MatchingOptions inMatchingOptions9;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;  
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
  output BackendDAE.DAELow outDAELow3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;  
algorithm
  (outAssignments1,outAssignments2,outDAELow3,outIncidenceMatrix4,outIncidenceMatrixT5,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inAssignments7,inAssignments8,inMatchingOptions9,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2,ass1_2,ass2_2;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,i,i_1,nv_1,nkv,nf_1,nvd;
      BackendDAE.MatchingOptions match_opts;
      BackendDAE.EquationArray eqns;
      BackendDAE.EquationConstraints eq_cons;
      BackendDAE.EquationReduction r_simple;
      list<BackendDAE.Value> eqn_lst,var_lst;
      String eqn_str,var_str;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1,derivedAlgs2;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1,derivedMultiEqn2;      

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,derivedAlgs,derivedMultiEqn)
      equation
        (nv == i) = true;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false; eMark(i)=vMark(i)=false exit loop";
      then
        (ass1_1,ass2_1,dae,m,mt,derivedAlgs,derivedMultiEqn);

    case (dae,m,mt,nv,nf,i,ass1,ass2,match_opts,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        i_1 = i + 1;
        DAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false" ;
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1) = matchingAlgorithm2(dae, m, mt, nv, nf, i_1, ass1_1, ass2_1, match_opts, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,ass1,ass2,(BackendDAE.INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        ((dae as BackendDAE.DAELOW(BackendDAE.VARIABLES(_,_,_,_,nv_1),BackendDAE.VARIABLES(_,_,_,_,nkv),_,_,eqns,_,_,_,_,_,_)),m,mt,derivedAlgs1,derivedMultiEqn1) = reduceIndexDummyDer(dae, m, mt, nv, nf, i, inFunctions,derivedAlgs,derivedMultiEqn) 
        "path_found failed, Try index reduction using dummy derivatives.
         When a constraint exist between states and index reduction is needed
         the dummy derivative will select one of the states as a dummy state
         (and the derivative of that state as a dummy derivative).
         For instance, u1=u2 is a constraint between states. Choose u1 as dummy state
         and der(u1) as dummy derivative, named der_u1. The differentiated function
         then becomes: der_u1 = der(u2).
         In the dummy derivative method this equation is added and the original equation
         u1=u2 is kept. This is not the case for the original pantilides algorithm, where
         the original equation is removed from the system." ;
        nf_1 = BackendDAEUtil.equationSize(eqns) "and try again, restarting. This could be optimized later. It should not
                                   be necessary to restart the matching, according to Bernard Bachmann. Instead one
                                   could continue the matching as usual. This was tested (2004-11-22) and it does not
                                   work to continue without restarting.
                                   For instance the Influenca model \"../testsuite/mofiles/Influenca.mo\" does not work if
                                   not restarting.
                                   2004-12-29 PA. This was a bug, assignment lists needed to be expanded with the size
                                   of the system in order to work. SO: Matching is not needed to be restarted from
                                   scratch." ;
        nvd = nv_1 - nv;
        ass1_1 = assignmentsExpand(ass1, nvd);
        ass2_1 = assignmentsExpand(ass2, nvd);
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2) = matchingAlgorithm2(dae, m, mt, nv_1, nf_1, i, ass1_1, ass2_1, (BackendDAE.INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs1,derivedMultiEqn1);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2);

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,_,_)
      equation
        eqn_lst = DAEEXT.getMarkedEqns() "When index reduction also fails, the model is structurally singular." ;
        var_lst = DAEEXT.getMarkedVariables();
        eqn_str = BackendDump.dumpMarkedEqns(dae, eqn_lst);
        var_str = BackendDump.dumpMarkedVars(dae, var_lst);
        Error.addMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str});
        //print("structurally singular. IM:");
        //dumpIncidenceMatrix(m);
        //print("daelow:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end matchingAlgorithm2;

protected function reduceIndexDummyDer
"function: reduceIndexDummyDer
  author: PA
  When matching fails, this function is called to try to
  reduce the index by differentiating the marked equations and
  replacing one of the variable with a dummy derivative, i.e. making
  it algebraic.
  The new BackendDAE.DAELow is returned along with an updated incidence matrix.

  inputs: (DAELow, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT,
             int /* number of vars */, int /* number of eqns */, int /* i */)
  outputs: (DAELow, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;  
  output BackendDAE.DAELow outDAELow;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;  
algorithm
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      list<BackendDAE.Value> eqns,diff_eqns,eqns_1,stateindx,deqns,reqns,changedeqns;
      list<BackendDAE.Key> states;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,stateno,i;
      DAE.ComponentRef state,dummy_der;
      list<String> es;
      String es_1;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;      

    case (dae,m,mt,nv,nf,i,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        eqns = DAEEXT.getMarkedEqns();
        // print("marked equations:");print(Util.stringDelimitList(Util.listMap(eqns,intString),","));
        // print("\n");
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        // print("differentiating equations:");print(Util.stringDelimitList(Util.listMap(eqns_1,intString),","));
        // print("\n");

        // Collect the states in the equations that are singular, i.e. composing a constraint between states.
        // Note that states are collected from -all- marked equations, not only the differentiated ones.
        (states,stateindx) = statesInEqns(eqns, dae, m, mt) "" ;
        (dae,m,mt,nv,nf,deqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(dae, m, mt, nv, nf, eqns_1,inFunctions,derivedAlgs,derivedMultiEqn);
        (state,stateno) = selectDummyState(states, stateindx, dae, m, mt);
        //  print("Selected ");print(ComponentReference.printComponentRefStr(state));print(" as dummy state\n");
        //  print(" From candidates:");print(Util.stringDelimitList(Util.listMap(states,ComponentReference.printComponentRefStr),", "));print("\n");
        dae = propagateDummyFixedAttribute(dae, eqns_1, state, stateno);
        (dummy_der,dae) = newDummyVar(state, dae)  ;
        // print("Chosen dummy: ");print(ComponentReference.printComponentRefStr(dummy_der));print("\n");
        reqns = BackendDAEUtil.eqnsForVarWithStates(mt, stateno);
        changedeqns = Util.listUnionOnTrue(deqns, reqns, int_eq);
        (dae,m,mt) = replaceDummyDer(state, dummy_der, dae, m, mt, changedeqns)
        "We need to change variables in the differentiated equations and in the equations having the dummy derivative" ;
        dae = makeAlgebraic(dae, state);
        (m,mt) = BackendDAEUtil.updateIncidenceMatrix(dae, m, mt, changedeqns);
        // print("new DAE:");
        // dump(dae);
        // print("new IM:");
        // dumpIncidenceMatrix(m);
      then
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,_,_,_)
      equation
        eqns = DAEEXT.getMarkedEqns();
        diff_eqns = DAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        es = Util.listMap(eqns_1, intString);
        es_1 = Util.stringDelimitList(es, ", ");
        print("eqns =");print(es_1);print("\n");
        ({},_) = statesInEqns(eqns_1, dae, m, mt);
        print("no states found in equations:");
        BackendDump.printEquations(eqns_1, dae);
        print("differentiated equations:");
        BackendDump.printEquations(diff_eqns,dae);
        print("Variables :");
        print(Util.stringDelimitList(Util.listMap(DAEEXT.getMarkedVariables(),intString),", "));
        print("\n");
      then
        fail();

    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-reduce_index_dummy_der failed\n");
      then
        fail();

  end matchcontinue;
end reduceIndexDummyDer;

protected function propagateDummyFixedAttribute
"function: propagateDummyFixedAttribute
  author: PA
  This function takes a list of equations that are differentiated
  and the chosen dummy state.
  The fixed attribute of the selected dummy state is propagated to
  the other state. This must be done since the dummy state becomes
  an algebraic state which has fixed = false by default.
  For example consider the equations:
  s1 = b;
  b=2c;
  c = s2;
  if s2 is selected as dummy derivative and s2 has an initial equation
  i.e. fixed should be false for the state s2 (which is set by the user),
  this fixed value has to be propagated to s1 when s2 becomes a dummy
  state."
  input BackendDAE.DAELow inDAELow;
  input list<Integer> inIntegerLst;
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow,inIntegerLst,inComponentRef,inInteger)
    local
      list<BackendDAE.Value> eqns_1,eqns;
      list<BackendDAE.Equation> eqns_lst;
      list<BackendDAE.Key> crefs;
      DAE.ComponentRef state,dummy;
      BackendDAE.Var v,v_1,v_2;
      BackendDAE.Value indx,indx_1,dummy_no;
      Boolean dummy_fixed;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;      
      BackendDAE.DAELow dae;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ei;
      BackendDAE.ExternalObjectClasses eoc;

   /* eqns dummy state */
    case ((dae as BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_1 = Util.listMap1(eqns, int_sub, 1);
        eqns_lst = Util.listMap1r(eqns_1, BackendDAEUtil.equationNth, e);
        crefs = equationsCrefs(eqns_lst);
        crefs = Util.listDeleteMemberOnTrue(crefs, dummy, ComponentReference.crefEqualNoStringCompare);
        state = findState(vars, crefs);
        ({v},{indx}) = BackendVariable.getVar(dummy, vars);
        (dummy_fixed as false) = BackendVariable.varFixed(v);
        ({v_1},{indx_1}) = BackendVariable.getVar(state, vars);
        v_2 = BackendVariable.setVarFixed(v_1, dummy_fixed);
        vars_1 = BackendVariable.addVar(v_2, vars);
      then
        BackendDAE.DAELOW(vars_1,kv,ev,av,e,se,ie,ae,al,ei,eoc);

    // Never propagate fixed=true
    case ((dae as BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_1 = Util.listMap1(eqns, int_sub, 1);
        eqns_lst = Util.listMap1r(eqns_1, BackendDAEUtil.equationNth, e);
        crefs = equationsCrefs(eqns_lst);
        crefs = Util.listDeleteMemberOnTrue(crefs, dummy, ComponentReference.crefEqualNoStringCompare);
        state = findState(vars, crefs);
        ({v},{indx}) = BackendVariable.getVar(dummy, vars);
        true = BackendVariable.varFixed(v);
      then dae;

    case (dae,_,_,_)
      equation
        Debug.fprint("failtrace", "propagate_dummy_initial_equations failed\n");
      then
        dae;

  end matchcontinue;
end propagateDummyFixedAttribute;

protected function findState
"function: findState
  author: PA
  Returns the first state from a list of component references."
  input BackendDAE.Variables inVariables;
  input list<DAE.ComponentRef> inExpComponentRefLst;
  output DAE.ComponentRef outComponentRef;
algorithm
  outComponentRef:=
  matchcontinue (inVariables,inExpComponentRefLst)
    local
      BackendDAE.Var v;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
      list<BackendDAE.Key> crs;

    case (vars,(cr :: crs))
      equation
        ((v :: _),_) = BackendVariable.getVar(cr, vars);
        BackendDAE.STATE() = BackendVariable.varKind(v);
      then
        cr;

    case (vars,(cr :: crs))
      equation
        cr = findState(vars, crs);
      then
        cr;

  end matchcontinue;
end findState;

public function equationsCrefs
"function: equationsCrefs
  author: PA
  From a list of equations return all
  occuring variables/component references."
  input list<BackendDAE.Equation> inEquationLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
algorithm
  outExpComponentRefLst:=
  matchcontinue (inEquationLst)
    local
      list<BackendDAE.Key> crs1,crs2,crs3,crs,crs2_1,crs3_1;
      DAE.Exp e1,e2,e;
      list<BackendDAE.Equation> es;
      DAE.ComponentRef cr;
      BackendDAE.Value indx;
      list<DAE.Exp> expl,expl1,expl2;
      BackendDAE.WhenEquation weq;
      DAE.ElementSource source "the element source";

    case ({}) then {};

    case ((BackendDAE.EQUATION(exp = e1,scalar = e2) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Expression.extractCrefsFromExp(e1);
        crs3 = Expression.extractCrefsFromExp(e2);
        crs = Util.listFlatten({crs1,crs2,crs3});
      then
        crs;

    case ((BackendDAE.RESIDUAL_EQUATION(exp = e1) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Expression.extractCrefsFromExp(e1);
        crs = listAppend(crs1, crs2);
      then
        crs;

    case ((BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e1) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Expression.extractCrefsFromExp(e1);
        crs = listAppend(crs1, crs2);
      then
        (cr :: crs);

    case ((BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: es))
      local list<list<DAE.ComponentRef>> crs2;
      equation
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl, Expression.extractCrefsFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs = listAppend(crs1, crs2_1);
      then
        crs;

    case ((BackendDAE.ALGORITHM(index = indx,in_ = expl1,out = expl2) :: es))
      local list<list<DAE.ComponentRef>> crs2,crs3;
      equation
        crs1 = equationsCrefs(es);
        crs2 = Util.listMap(expl1, Expression.extractCrefsFromExp);
        crs3 = Util.listMap(expl2, Expression.extractCrefsFromExp);
        crs2_1 = Util.listFlatten(crs2);
        crs3_1 = Util.listFlatten(crs3);
        crs = Util.listFlatten({crs1,crs2_1,crs3_1});
      then
        crs;

    case ((BackendDAE.WHEN_EQUATION(whenEquation =
           BackendDAE.WHEN_EQ(index = indx,left = cr,right = e,elsewhenPart=SOME(weq)),source = source) :: es))
      equation
        crs1 = equationsCrefs(es);
        crs2 = Expression.extractCrefsFromExp(e);
        crs3 = equationsCrefs({BackendDAE.WHEN_EQUATION(weq,source)});
        crs = listAppend(crs1, listAppend(crs2, crs3));
      then
        (cr :: crs);
  end matchcontinue;
end equationsCrefs;

public function makeAllStatesAlgebraic
"function: makeAllStatesAlgebraic
  author: PA
  This function makes all states of a BackendDAE.DAELow algebraic.
  Is used when solving an initial value problem, since
  states are just an algebraic variable in that case."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> var_lst,var_lst_1;
      BackendDAE.Variables vars_1,vars,knvar,evar;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
    case (BackendDAE.DAELOW(vars,knvar,evar,av,eqns,reqns,ieqns,ae,al,ev,eoc))
      equation
        var_lst = BackendDAEUtil.varList(vars);
        var_lst_1 = makeAllStatesAlgebraic2(var_lst);
        vars_1 = BackendDAEUtil.listVar(var_lst_1);
      then
        BackendDAE.DAELOW(vars_1,knvar,evar,av,eqns,reqns,ieqns,ae,al,ev,eoc);
  end matchcontinue;
end makeAllStatesAlgebraic;

protected function makeAllStatesAlgebraic2
"function: makeAllStatesAlgebraic2
  author: PA
  Helper function to makeAllStatesAlgebraic"
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarLst)
    local
      list<BackendDAE.Var> vs_1,vs;
      DAE.ComponentRef cr;
      DAE.VarDirection d;
      BackendDAE.Type t;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      BackendDAE.Value idx;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Var v;

    case ({}) then {};

    case ((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = d,
               varType = t,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               index = idx,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        vs_1 = makeAllStatesAlgebraic2(vs);
      then
        (BackendDAE.VAR(cr,BackendDAE.VARIABLE(),d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: vs_1);

    case ((v :: vs))
      equation
        vs_1 = makeAllStatesAlgebraic2(vs);
      then
        (v :: vs_1);
  end matchcontinue;
end makeAllStatesAlgebraic2;

protected function makeAlgebraic
"function: makeAlgebraic
  author: PA
  Make the variable a dummy derivative, i.e.
  change varkind from STATE to DUMMY_STATE.
  inputs:  (DAELow, DAE.ComponentRef /* state */)
  outputs: (DAELow) = "
  input BackendDAE.DAELow inDAELow;
  input DAE.ComponentRef inComponentRef;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow,inComponentRef)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection d;
      BackendDAE.Type t;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      BackendDAE.Value idx;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<BackendDAE.Value> indx;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.DAELow daelow, daelow_1;

    case (BackendDAE.DAELOW(vars,kv,ev,av,e,se,ie,ae,al,wc,eoc),cr)
      equation
        ((BackendDAE.VAR(cr,kind,d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),indx) = BackendVariable.getVar(cr, vars);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix), vars);        
      then
        BackendDAE.DAELOW(vars_1,kv,ev,av,e,se,ie,ae,al,wc,eoc);

    case (_,_)
      equation
        print("DAELow.makeAlgebraic failed\n");
      then
        fail();

  end matchcontinue;
end makeAlgebraic;

protected function replaceDummyDer
"function: replaceDummyDer
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with the variable dummy der.
  inputs:   (DAE.ComponentRef, /* state */
             DAE.ComponentRef, /* dummy der name */
             DAELow,
             IncidenceMatrix,
             IncidenceMatrixT,
             int list /* equations */)
  outputs:  (DAELow,
             IncidenceMatrix,
             IncidenceMatrixT)"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input BackendDAE.DAELow inDAELow3;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix4;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT5;
  input list<Integer> inIntegerLst6;
  output BackendDAE.DAELow outDAELow;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outDAELow,outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inComponentRef1,inComponentRef2,inDAELow3,inIncidenceMatrix4,inIncidenceMatrixT5,inIntegerLst6)
    local
      DAE.ComponentRef state,dummy,dummyder;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.Variables v_1,v,kv,ev;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie,ie1;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2,ae3;
      array<DAE.Algorithm> al,al1,al2,al3;
      BackendDAE.EventInfo wc;
      list<BackendDAE.Value> rest;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> ieLst1,ieLst;

    case (state,dummy,dae,m,mt,{}) then (dae,m,mt);

    case (state,dummyder,BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc),m,mt,(e :: rest))
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        ieLst = BackendDAEUtil.equationList(ie);
        (eqn_1,al1,ae1) = replaceDummyDer2(state, dummyder, eqn, al, ae);
        (ieLst1,al2,ae2) = replaceDummyDerEqns(ieLst,state,dummyder, al1,ae1);
        ie1 = BackendDAEUtil.listEquation(ieLst1);
        (eqn_1,v_1,al3,ae3) = replaceDummyDerOthers(eqn_1, v,al2,ae2);
        eqns_1 = equationSetnth(eqns, e_1, eqn_1)
         "incidence_row(v\'\',eqn\') => row\' &
          Util.list_replaceat(row\',e\',m) => m\' &
          transpose_matrix(m\') => mt\' &" ;
        (dae,m,mt) = replaceDummyDer(state, dummyder, BackendDAE.DAELOW(v_1,kv,ev,av,eqns_1,seqns,ie1,ae3,al3,wc,eoc), m, mt, rest);
      then
        (dae,m,mt);

    case (_,_,_,_,_,_)
      equation
        print("-replace_dummy_der failed\n");
      then
        fail();

  end matchcontinue;
end replaceDummyDer;

protected function replaceDummyDer2
"function: replaceDummyDer2
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with dummyDer variable in equation"
  input DAE.ComponentRef inComponentRef1;
  input DAE.ComponentRef inComponentRef2;
  input BackendDAE.Equation inEquation3;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  output BackendDAE.Equation outEquation;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEquation,outAlgs,outMultiDimEquationArray) := matchcontinue (inComponentRef1,inComponentRef2,inEquation3,inAlgs,inMultiDimEquationArray)
    local
      DAE.Exp dercall,e1_1,e2_1,e1,e2;
      DAE.ComponentRef st,dummyder,cr;
      BackendDAE.Value ds,indx,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      BackendDAE.Equation res;
      BackendDAE.WhenEquation elsepartRes;
      BackendDAE.WhenEquation elsepart;
      DAE.ElementSource source,source1;
      array<DAE.Algorithm> algs;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<Integer> dimSize;
    case (st,dummyder,BackendDAE.EQUATION(exp = e1,scalar = e2,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()) "scalar equation" ;
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Expression.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source),inAlgs,ae);
    case (st,dummyder,BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (expl1,_) = Expression.replaceListExp(expl, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        i = ds+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Expression.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));    
        ae1 = arrayUpdate(ae,i,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (BackendDAE.ARRAY_EQUATION(ds,expl1,source),inAlgs,ae1);  /* array equation */
    case (st,dummyder,BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (in_1,_) = Expression.replaceListExp(in_, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));        
        (out1,_) = Expression.replaceListExp(out, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));  
        algs = replaceDummyDerAlgs(indx,inAlgs,dercall, DAE.CREF(dummyder,DAE.ET_REAL()));     
      then (BackendDAE.ALGORITHM(indx,in_1,out1,source),algs,ae);  /* Algorithms */
    case (st,dummyder,BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=NONE()),source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e1_1,NONE()),source);
      then
        (res,inAlgs,ae);

    case (st,dummyder,BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=SOME(elsepart)),source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE());
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (BackendDAE.WHEN_EQUATION(elsepartRes,source),algs,ae1) = replaceDummyDer2(st,dummyder, BackendDAE.WHEN_EQUATION(elsepart,source),inAlgs,ae);
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e1_1,SOME(elsepartRes)),source);
      then
        (res,algs,ae1);
    case (st,dummyder,BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),inAlgs,ae)
      equation
        dercall = DAE.CALL(Absyn.IDENT("der"),{DAE.CREF(st,DAE.ET_REAL())},false,true,DAE.ET_REAL(),DAE.NO_INLINE()) "scalar equation" ;
        (e1_1,_) = Expression.replaceExp(e1, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
        (e2_1,_) = Expression.replaceExp(e2, dercall, DAE.CREF(dummyder,DAE.ET_REAL()));
      then
        (BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source),inAlgs,ae);
     case (_,_,_,_,_)
      equation
        print("-DAELow.replaceDummyDer2 failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDer2;

protected function replaceDummyDerAlgs
  input Integer inIndex;
  input array<DAE.Algorithm> inAlgs;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output array<DAE.Algorithm> outAlgs;  
algorithm
  outAlgs:=
  matchcontinue (inIndex,inAlgs,inExp2,inExp3)
    local  
      array<DAE.Algorithm> algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
  case (inIndex,inAlgs,inExp2,inExp3)
    equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];  
        statementLst1 = replaceDummyDerAlgs1(statementLst,inExp2,inExp3); 
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));   
    then
      algs;
  end matchcontinue;      
end replaceDummyDerAlgs;

protected function replaceDummyDerAlgs1
  input list<DAE.Statement> inStatementLst;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output list<DAE.Statement> outStatementLst;  
algorithm
  outStatementLst:=
  matchcontinue (inStatementLst,inExp2,inExp3)
    local  
      list<DAE.Statement> rest,st,stlst,stlst1;
      DAE.Statement s,s1;
      DAE.Exp e,e1,e_1,e1_1;
      list<DAE.Exp> elst,elst1,inputExps;
      DAE.ExpType t;
      DAE.ComponentRef cr,cr1;
      DAE.Else else_,else_1;
      DAE.ElementSource source;
      Absyn.MatchType matchType;
  case ({},_,_) then {};
  case (DAE.STMT_ASSIGN(type_=t,exp1=e1,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Expression.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSIGN(t,e1,e_1,source)::st);
  case (DAE.STMT_TUPLE_ASSIGN(type_=t,expExpLst=elst,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (elst1,_) = Expression.replaceListExp(elst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TUPLE_ASSIGN(t,elst1,e1,source)::st);
  case (DAE.STMT_ASSIGN_ARR(type_=t,componentRef=cr,exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (DAE.CREF(componentRef = cr1),_) = Expression.replaceExp(DAE.CREF(cr,DAE.ET_REAL()),inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSIGN_ARR(t,cr1,e1,source)::st);
  case (DAE.STMT_IF(exp=e,statementLst=stlst,else_=else_,source=source)::rest,inExp2,inExp3)
    equation
       (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
       stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
       else_1 = replaceDummyDerAlgs2(else_,inExp2,inExp3);
       st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_IF(e1,stlst1,else_1,source)::st);
  case (DAE.STMT_FOR(type_=t,iterIsArray=b,ident=id,exp=e,statementLst=stlst,source=source)::rest,inExp2,inExp3)
    local 
      Boolean b;
      DAE.Ident id;
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_FOR(t,b,id,e1,stlst1,source)::st);
  case (DAE.STMT_WHILE(exp=e,statementLst=stlst,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHILE(e1,stlst1,source)::st);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=SOME(s),helpVarIndices=helpVarIndices,source=source)::rest,inExp2,inExp3)
    local list<Integer> helpVarIndices;
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        {s1} = replaceDummyDerAlgs1({s},inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHEN(e1,stlst1,SOME(s1),helpVarIndices,source)::st);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::rest,inExp2,inExp3)
    local list<Integer> helpVarIndices;
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_WHEN(e1,stlst1,NONE(),helpVarIndices,source)::st);
  case (DAE.STMT_ASSERT(cond=e1,msg=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Expression.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_ASSERT(e1,e_1,source)::st);
  case (DAE.STMT_TERMINATE(msg=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TERMINATE(e1,source)::st);
  case (DAE.STMT_REINIT(var=e1,value=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        (e_1,_) = Expression.replaceExp(e1,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_REINIT(e1,e_1,source)::st);
  case (DAE.STMT_NORETCALL(exp=e,source=source)::rest,inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_NORETCALL(e1,source)::st);
  case (DAE.STMT_RETURN(source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_RETURN(source)::st);
  case (DAE.STMT_BREAK(source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_BREAK(source)::st);
  case (DAE.STMT_FAILURE(body=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_FAILURE(stlst1,source)::st);
  case (DAE.STMT_TRY(tryBody=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_TRY(stlst1,source)::st);
  case (DAE.STMT_CATCH(catchBody=stlst,source=source)::rest,inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_CATCH(stlst1,source)::st);
  case (DAE.STMT_THROW(source=source)::rest,inExp2,inExp3)
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_THROW(source)::st);
  case (DAE.STMT_GOTO(labelName=labelName,source=source)::rest,inExp2,inExp3)
    local String labelName;
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_GOTO(labelName,source)::st);
  case (DAE.STMT_LABEL(labelName=labelName,source=source)::rest,inExp2,inExp3)
    local String labelName;
    equation
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_LABEL(labelName,source)::st);
  case (DAE.STMT_MATCHCASES(matchType=matchType,inputExps=inputExps,caseStmt=elst,source=source)::rest,inExp2,inExp3)
    equation
        (elst1,_) = Expression.replaceListExp(elst,inExp2,inExp3);
        st = replaceDummyDerAlgs1(rest,inExp2,inExp3);
    then
      (DAE.STMT_MATCHCASES(matchType,inputExps,elst1,source)::st);
  case (_,_,_)
    equation
      print("-DAELow.replaceDummyDerAlgs1 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerAlgs1;

protected function replaceDummyDerAlgs2
  input DAE.Else inElse;  
  input DAE.Exp inExp2;
  input DAE.Exp inExp3;  
  output DAE.Else outElse;  
algorithm
  outElse:=
  matchcontinue (inElse,inExp2,inExp3)
    local  
      DAE.Exp e,e1;
      list<DAE.Statement> stlst,stlst1;
      DAE.Else else_,else_1;
  case (DAE.NOELSE(),_,_) then DAE.NOELSE();
  case (DAE.ELSEIF(exp=e,statementLst=stlst,else_=else_),inExp2,inExp3)
    equation
        (e1,_) = Expression.replaceExp(e,inExp2,inExp3);
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
        else_1 = replaceDummyDerAlgs2(else_,inExp2,inExp3);
    then
      DAE.ELSEIF(e1,stlst1,else_1);
  case (DAE.ELSE(statementLst=stlst),inExp2,inExp3)
    equation
        stlst1 = replaceDummyDerAlgs1(stlst,inExp2,inExp3);
    then
      DAE.ELSE(stlst1);
  case (_,_,_)
    equation
      print("-DAELow.replaceDummyDerAlgs2 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerAlgs2;

protected function replaceDummyDerEqns
"function replaceDummyDerEqns
  author: PA
  Helper function to reduceIndexDummy<der
  replaces der(state) with dummy_der variable in list of equations."
  input list<BackendDAE.Equation> eqns;
  input DAE.ComponentRef st;
  input DAE.ComponentRef dummyder;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  output list<BackendDAE.Equation> outEqns;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEqns,outAlgs,outMultiDimEquationArray):=
  matchcontinue (eqns,st,dummyder,inAlgs,inMultiDimEquationArray)
    local
      DAE.ComponentRef st,dummyder;
      list<BackendDAE.Equation> eqns1,eqns;
      BackendDAE.Equation e,e1;
      array<DAE.Algorithm> algs,algs1;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2;
    case ({},st,dummyder,inAlgs,ae) then ({},inAlgs,ae);
    case (e::eqns,st,dummyder,inAlgs,ae)
      equation
         (e1,algs,ae1) = replaceDummyDer2(st,dummyder,e,inAlgs,ae);
         (eqns1,algs1,ae2) = replaceDummyDerEqns(eqns,st,dummyder,algs,ae1);
      then
        (e1::eqns1,algs1,ae2);
  end matchcontinue;
end replaceDummyDerEqns;

protected function replaceDummyDerOthers
"function: replaceDummyDerOthers
  author: PA
  Helper function to reduceIndexDummyDer.
  This function replaces
  1. der(der_s)  with der2_s (Where der_s is a dummy state)
  2. der(der(v)) with der2_v (where v is a state)
  3. der(v)  for alg. var v with der_v
  in the BackendDAE.Equation given as arguments. To do this it needs the Variables
  also passed as argument to the function to e.g. determine if a variable
  is a dummy variable, etc."
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;  
  output BackendDAE.Equation outEquation;
  output BackendDAE.Variables outVariables;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
algorithm
  (outEquation,outVariables,outAlgs,outMultiDimEquationArray):=
  matchcontinue (inEquation,inVariables,inAlgs,inMultiDimEquationArray)
    local
      DAE.Exp e1_1,e2_1,e1,e2;
      BackendDAE.Variables vars_1,vars_2,vars_3,vars;
      BackendDAE.Value ds,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      DAE.ComponentRef cr;
      BackendDAE.WhenEquation elsePartRes;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source,source1;
      Integer indx;
      array<DAE.Algorithm> al;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<Integer> dimSize;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source),vars,inAlgs,ae)
      equation
        ((e1_1,vars_1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars) "scalar equation" ;
        ((e2_1,vars_2)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars_1);
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source),vars_2,inAlgs,ae);

    case (BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),vars,inAlgs,ae) 
      equation
        (expl1,vars_1) = replaceDummyDerOthersExpLst(expl,vars);
        i = ds+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        ((e1_1,vars_2)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars_1);
        ((e2_1,vars_3)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars_2);       
        ae1 = arrayUpdate(ae,i,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (BackendDAE.ARRAY_EQUATION(ds,expl1,source),vars_3,inAlgs,ae1);  /* array equation */

    case (BackendDAE.WHEN_EQUATION(whenEquation =
            BackendDAE.WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=NONE()),source = source),vars,inAlgs,ae)
      equation
        ((e2_1,vars_1)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars);
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e2_1,NONE()),source),vars_1,inAlgs,ae);

    case (BackendDAE.WHEN_EQUATION(whenEquation =
            BackendDAE.WHEN_EQ(index = i,left = cr,right = e2,elsewhenPart=SOME(elsePart)),source = source),vars,inAlgs,ae)
      equation
        ((e2_1,vars_1)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars);
        (BackendDAE.WHEN_EQUATION(elsePartRes,source), vars_2,al,ae1) = replaceDummyDerOthers(BackendDAE.WHEN_EQUATION(elsePart,source),vars_1,inAlgs,ae);
      then
        (BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e2_1,SOME(elsePartRes)),source),vars_2,al,ae1);

    case (BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out,source = source),vars,inAlgs,ae)
      equation
        (in_1,vars_1) = replaceDummyDerOthersExpLst(in_, vars);
        (out1,vars_2) = replaceDummyDerOthersExpLst(out, vars_1);
        (vars_2,al) = replaceDummyDerOthersAlgs(indx,vars_1,inAlgs);     
      then (BackendDAE.ALGORITHM(indx,in_1,out1,source),vars_2,al,ae);

   case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),vars,inAlgs,ae)      
      equation
        ((e1_1,vars_1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars) "scalar equation" ;
        ((e2_1,vars_2)) = Expression.traverseExp(e2,replaceDummyDerOthersExp,vars_1);
      then
        (BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source),vars_2,inAlgs,ae);

    case (_,_,_,_)
      equation
        print("-DAELow.replaceDummyDerOthers failed\n");
      then
        fail();
  end matchcontinue;
end replaceDummyDerOthers;

protected function replaceDummyDerOthersAlgs
  input Integer inIndex;
  input BackendDAE.Variables inVariables;
  input array<DAE.Algorithm> inAlgs;
  output BackendDAE.Variables outVariables;
  output array<DAE.Algorithm> outAlgs;
algorithm
  (outVariables,outAlgs):=
  matchcontinue (inIndex,inVariables,inAlgs)
    local
      array<DAE.Algorithm> algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
      BackendDAE.Variables vars;
      case(inIndex,inVariables,inAlgs)
        equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];  
        (statementLst1,vars) = replaceDummyDerOthersAlgs1(statementLst,inVariables); 
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));           
      then
       (vars,algs); 
  end matchcontinue;        
end replaceDummyDerOthersAlgs;

protected function replaceDummyDerOthersAlgs1
  input list<DAE.Statement> inStatementLst;  
  input BackendDAE.Variables inVariables;
  output list<DAE.Statement> outStatementLst;  
  output BackendDAE.Variables outVariables;
algorithm
  (outStatementLst,outVariables) :=
  matchcontinue (inStatementLst,inVariables)
    local  
      list<DAE.Statement> rest,st,stlst,stlst1;
      DAE.Statement s,s1;
      DAE.Exp e,e1,e_1,e1_1;
      list<DAE.Exp> elst,elst1,inputExps;
      DAE.ExpType t;
      DAE.ComponentRef cr,cr1;
      DAE.Else else_,else_1;
      BackendDAE.Variables vars,vars1,vars2,vars3;
      DAE.ElementSource source;
      Absyn.MatchType matchType;
  case ({},inVariables) then ({},inVariables);
  case (DAE.STMT_ASSIGN(type_=t,exp1=e1,exp=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSIGN(t,e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_TUPLE_ASSIGN(type_=t,expExpLst=elst,exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (elst1,vars1) = replaceDummyDerOthersExpLst(elst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_TUPLE_ASSIGN(t,elst1,e1,source)::st,vars2);
  case (DAE.STMT_ASSIGN_ARR(type_=t,componentRef=cr,exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((DAE.CREF(componentRef = cr1),vars1)) = Expression.traverseExp(DAE.CREF(cr,DAE.ET_REAL()),replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSIGN_ARR(t,cr1,e1,source)::st,vars2);
  case (DAE.STMT_IF(exp=e,statementLst=stlst,else_=else_,source=source)::rest,inVariables)
    equation
       ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
       (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
       (else_1,vars2) = replaceDummyDerOthersAlgs2(else_,vars1);
       (st,vars3) = replaceDummyDerOthersAlgs1(rest,vars2);
    then
      (DAE.STMT_IF(e1,stlst1,else_1,source)::st,vars3);
  case (DAE.STMT_FOR(type_=t,iterIsArray=b,ident=id,exp=e,statementLst=stlst,source=source)::rest,inVariables)
    local 
      Boolean b;
      DAE.Ident id;
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_FOR(t,b,id,e1,stlst1,source)::st,vars2);
  case (DAE.STMT_WHILE(exp=e,statementLst=stlst,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_WHILE(e1,stlst1,source)::st,vars2);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=SOME(s),helpVarIndices=helpVarIndices,source=source)::rest,inVariables)
    local list<Integer> helpVarIndices;
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        ({s1},vars2) = replaceDummyDerOthersAlgs1({s},vars1);
        (st,vars3) = replaceDummyDerOthersAlgs1(rest,vars2);
    then
      (DAE.STMT_WHEN(e1,stlst1,SOME(s1),helpVarIndices,source)::st,vars3);
  case (DAE.STMT_WHEN(exp=e,statementLst=stlst,elseWhen=NONE(),helpVarIndices=helpVarIndices,source=source)::rest,inVariables)
    local list<Integer> helpVarIndices;
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_WHEN(e1,stlst1,NONE(),helpVarIndices,source)::st,vars2);
  case (DAE.STMT_ASSERT(cond=e1,msg=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_ASSERT(e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_TERMINATE(msg=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_TERMINATE(e1,source)::st,vars1);
  case (DAE.STMT_REINIT(var=e1,value=e,source=source)::rest,inVariables)
    equation
        ((e_1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        ((e1_1,vars1)) = Expression.traverseExp(e1,replaceDummyDerOthersExp,vars);
        (st,vars2) = replaceDummyDerOthersAlgs1(rest,vars1);
    then
      (DAE.STMT_REINIT(e_1,e1_1,source)::st,vars2);
  case (DAE.STMT_NORETCALL(exp=e,source=source)::rest,inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_NORETCALL(e1,source)::st,vars1);
  case (DAE.STMT_RETURN(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_RETURN(source)::st,vars);
  case (DAE.STMT_BREAK(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_BREAK(source)::st,vars);
  case (DAE.STMT_FAILURE(body=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_FAILURE(stlst1,source)::st,vars1);
  case (DAE.STMT_TRY(tryBody=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_TRY(stlst1,source)::st,vars1);
  case (DAE.STMT_CATCH(catchBody=stlst,source=source)::rest,inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_CATCH(stlst1,source)::st,vars1);
  case (DAE.STMT_THROW(source=source)::rest,inVariables)
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_THROW(source)::st,vars);
  case (DAE.STMT_GOTO(labelName=labelName,source=source)::rest,inVariables)
    local String labelName;
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_GOTO(labelName,source)::st,vars);
  case (DAE.STMT_LABEL(labelName=labelName,source=source)::rest,inVariables)
    local String labelName;
    equation
        (st,vars) = replaceDummyDerOthersAlgs1(rest,inVariables);
    then
      (DAE.STMT_LABEL(labelName,source)::st,vars);
  case (DAE.STMT_MATCHCASES(matchType=matchType,inputExps=inputExps,caseStmt=elst,source=source)::rest,inVariables)
    equation
        (elst1,vars) = replaceDummyDerOthersExpLst(elst,inVariables);
        (st,vars1) = replaceDummyDerOthersAlgs1(rest,vars);
    then
      (DAE.STMT_MATCHCASES(matchType,inputExps,elst1,source)::st,vars1);
  case (_,_)
    equation
      print("-DAELow.replaceDummyDerOthersAlgs1 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerOthersAlgs1;

protected function replaceDummyDerOthersAlgs2
  input DAE.Else inElse;  
  input BackendDAE.Variables inVariables;
  output DAE.Else outElse; 
  output BackendDAE.Variables outVariables; 
algorithm
  (outElse,outVariables):=
  matchcontinue (inElse,inVariables)
    local  
      DAE.Exp e,e1;
      list<DAE.Statement> stlst,stlst1;
      DAE.Else else_,else_1;
      BackendDAE.Variables vars,vars1,vars2;
  case (DAE.NOELSE(),inVariables) then (DAE.NOELSE(),inVariables);
  case (DAE.ELSEIF(exp=e,statementLst=stlst,else_=else_),inVariables)
    equation
        ((e1,vars)) = Expression.traverseExp(e,replaceDummyDerOthersExp,inVariables);
        (stlst1,vars1) = replaceDummyDerOthersAlgs1(stlst,vars);
        (else_1,vars2) = replaceDummyDerOthersAlgs2(else_,vars1);
    then
      (DAE.ELSEIF(e1,stlst1,else_1),vars2);
  case (DAE.ELSE(statementLst=stlst),inVariables)
    equation
        (stlst1,vars) = replaceDummyDerOthersAlgs1(stlst,inVariables);
    then
      (DAE.ELSE(stlst1),vars);
  case (_,_)
    equation
      print("-DAELow.replaceDummyDerOthersAlgs2 failed\n");
    then
      fail();    
  end matchcontinue;      
end replaceDummyDerOthersAlgs2;

protected function replaceDummyDerOthersExpLst
"function: replaceDummyDerOthersExp
  author: PA
  Helper function for replaceDummyDer_others"
  input list<DAE.Exp> inExpLst;
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpLst;
  output BackendDAE.Variables outVariables;
algorithm
  (outExpLst,outVariables) := matchcontinue (inExpLst,inVariables)
  local 
    list<DAE.Exp> rest,elst;
    DAE.Exp e,e1;
    BackendDAE.Variables vars,vars1,vars2;
    case ({},vars) then ({},vars); 
    case (e::rest,vars)
      equation
        ((e1,vars1)) = Expression.traverseExp(e,replaceDummyDerOthersExp,vars);
        (elst,vars2) = replaceDummyDerOthersExpLst(rest,vars1);
      then
       (e1::elst,vars2); 
  end matchcontinue;       
end replaceDummyDerOthersExpLst;

protected function replaceDummyDerOthersExp
"function: replaceDummyDerOthersExp
  author: PA
  Helper function for replaceDummyDer_others"
  input tuple<DAE.Exp,BackendDAE.Variables> inExp;
  output tuple<DAE.Exp,BackendDAE.Variables> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e;
      BackendDAE.Variables vars,vars_1;
      DAE.VarDirection a;
      BackendDAE.Type b;
      Option<DAE.Exp> c;
      Option<Values.Value> d;
      BackendDAE.Value g;
      DAE.ComponentRef dummyder,dummyder_1,cr;
      DAE.ElementSource source "the source of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.STATE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        dummyder = crefPrefixDer(cr);
        dummyder = crefPrefixDer(dummyder);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(der_s)) der_s is dummy var => der_der_s" ;
        dummyder = crefPrefixDer(cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      local list<DAE.Subscript> e;
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        dummyder = crefPrefixDer(cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b,NONE(), NONE(), e, 0, source, dae_var_attr, comment, flowPrefix, streamPrefix), vars);
      then
        ((DAE.CREF(dummyder,DAE.ET_REAL()),vars_1));

    case ((e,vars)) then ((e,vars));

  end matchcontinue;
end replaceDummyDerOthersExp;

public function equationEqual "Returns true if two equations are equal"
  input BackendDAE.Equation e1;
  input BackendDAE.Equation e2;
  output Boolean res;
algorithm
  res := matchcontinue(e1,e2)
    local
      DAE.Exp e11,e12,e21,e22,exp1,exp2;
      Integer i1,i2;
      DAE.ComponentRef cr1,cr2;
    case (BackendDAE.EQUATION(exp = e11,scalar = e12),
          BackendDAE.EQUATION(exp = e21, scalar = e22))
      equation
        res = boolAnd(Expression.expEqual(e11,e21),Expression.expEqual(e12,e22));
      then res;

    case(BackendDAE.ARRAY_EQUATION(index = i1),
         BackendDAE.ARRAY_EQUATION(index = i2))
      equation
        res = intEq(i1,i2);
      then res;

    case(BackendDAE.SOLVED_EQUATION(componentRef = cr1,exp = exp1),
         BackendDAE.SOLVED_EQUATION(componentRef = cr2,exp = exp2))
      equation
        res = boolAnd(ComponentReference.crefEqualNoStringCompare(cr1,cr2),Expression.expEqual(exp1,exp2));
      then res;

    case(BackendDAE.RESIDUAL_EQUATION(exp = exp1),
         BackendDAE.RESIDUAL_EQUATION(exp = exp2))
      equation
        res = Expression.expEqual(exp1,exp2);
      then res;

    case(BackendDAE.ALGORITHM(index = i1),
         BackendDAE.ALGORITHM(index = i2))
      equation
        res = intEq(i1,i2);
      then res;

    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i1)),
          BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(index = i2)))
      equation
        res = intEq(i1,i2);
      then res;

    case(_,_) then false;

  end matchcontinue;
end equationEqual;

protected function newDummyVar
"function: newDummyVar
  author: PA
  This function creates a new variable named
  der+<varname> and adds it to the dae."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.DAELow inDAELow;
  output DAE.ComponentRef outComponentRef;
  output BackendDAE.DAELow outDAELow;
algorithm
  (outComponentRef,outDAELow):=
  matchcontinue (inComponentRef,inDAELow)
    local
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> bind;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      BackendDAE.Value idx;
      DAE.ComponentRef name,dummyvar_cr,var;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;      
      BackendDAE.EquationArray eqns,seqns,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      BackendDAE.Var dummyvar;

    case (var,BackendDAE.DAELOW(vars, kv, ev, av, eqns, seqns, ie, ae, al, wc,eoc))
      equation
        ((BackendDAE.VAR(name,kind,dir,tp,bind,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(var, vars);
        dummyvar_cr = crefPrefixDer(var);
        dummyvar = BackendDAE.VAR(dummyvar_cr,BackendDAE.DUMMY_DER(),dir,tp,NONE(),NONE(),dim,0,source,dae_var_attr,comment,flowPrefix,streamPrefix);
        /* Dummy variables are algebraic variables, hence fixed = false */
        dummyvar = BackendVariable.setVarFixed(dummyvar,false);
        vars_1 = BackendVariable.addVar(dummyvar, vars);
      then
        (dummyvar_cr,BackendDAE.DAELOW(vars_1,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc));

    case (_,_)
      equation
        print("-DAELow.newDummyVar failed!\n");
      then
        fail();
  end matchcontinue;
end newDummyVar;

protected function selectDummyState
"function: selectDummyState
  author: PA
  This function is the heuristic to select among the states which one
  will be transformed into  an algebraic variable, a so called dummy state
 (dummy derivative). It should in the future consider initial values, etc.
  inputs:  (DAE.ComponentRef list, /* variable names */
            int list, /* variable numbers */
            DAELow,
            IncidenceMatrix,
            IncidenceMatrixT)
  outputs: (DAE.ComponentRef, int)"
  input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef;
  output Integer outInteger;
algorithm
  (outComponentRef,outInteger):=
  matchcontinue (varCrefs,varIndices,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef s;
      BackendDAE.Value sn;
      BackendDAE.Variables vars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EquationArray eqns;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;

    case (varCrefs,varIndices,BackendDAE.DAELOW(orderedVars=vars,orderedEqs = eqns),m,mt)
      equation
        prioTuples = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
        //print("priorities:");print(Util.stringDelimitList(Util.listMap(prioTuples,printPrioTuplesStr),","));print("\n");
        (s,sn) = selectMinPrio(prioTuples);
      then (s,sn);

    case ({},_,dae,_,_)
      local BackendDAE.DAELow dae;
      equation
        print("Error, no state to select\nDAE:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end selectDummyState;

protected function selectMinPrio
"Selects the state with lowest priority. This will become a dummy state"
  input list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
  output DAE.ComponentRef s;
  output Integer sn;
algorithm
  (s,sn) := matchcontinue(tuples)
    case(tuples)
      equation
        ((s,sn,_)) = Util.listReduce(tuples,ssPrioTupleMin);
      then (s,sn);
  end matchcontinue;
end selectMinPrio;

protected function ssPrioTupleMin
"Select the minimum tuple of two tuples"
  input tuple<DAE.ComponentRef,Integer,Real> tuple1;
  input tuple<DAE.ComponentRef,Integer,Real> tuple2;
  output tuple<DAE.ComponentRef,Integer,Real> tuple3;
algorithm
  tuple3 := matchcontinue(tuple1,tuple2)
    local DAE.ComponentRef cr1,cr2;
      Integer ns1,ns2;
      Real rs1,rs2;
    case((cr1,ns1,rs1),(cr2,ns2,rs2))
      equation
        true = (rs1 <. rs2);
      then ((cr1,ns1,rs1));

    case ((cr1,ns1,rs1),(cr2,ns2,rs2))
      equation
        true = (rs2 <. rs1);
      then ((cr2,ns2,rs2));

    //exactly equal, choose first one.
    case ((cr1,ns1,rs1),(cr2,ns2,rs2)) then ((cr1,ns1,rs1));

  end matchcontinue;
end ssPrioTupleMin;

protected function calculateVarPriorities
"Calculates state selection priorities"
  input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := matchcontinue(varCrefs,varIndices,vars,eqns,m,mt)
  local DAE.ComponentRef varCref;
    Integer varIndx;
    BackendDAE.Var v;
    Real prio,prio1,prio2;
    list<tuple<DAE.ComponentRef,Integer,Real>> prios;
    case({},{},_,_,_,_) then {};
    case (varCref::varCrefs,varIndx::varIndices,vars,eqns,m,mt) equation
      prios = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
      (v::_,_) = BackendVariable.getVar(varCref,vars);
      prio1 = varStateSelectPrio(v);
      prio2 = varStateSelectHeuristicPrio(v,vars,eqns,m,mt);
      prio = prio1 +. prio2;
    then ((varCref,varIndx,prio)::prios);
  end matchcontinue;
end calculateVarPriorities;

protected function varStateSelectHeuristicPrio
"function varStateSelectHeuristicPrio
  author: PA
  A heuristic for selecting states when no stateSelect information is available.
  This heuristic is based on.
  1. If a state variable s has an equation on the form s = expr(s1,s2,...,sn) where s1..sn are states
     it should be a candiate for dummy state. Like for instance phi_rel = J1.phi-J2.phi will make phi_rel
     a candidate for dummy state whereas J1.phi and J2.phi would be candidates for states.

  2. If a state variable komponent_x.s has been selected as a dummy state then komponent_x.s2 could also
     be a dummy_state. Rationale: This will increase probability that all states belong to the same component
     which is more likely what a user expects.

  3. A priority based on the number of selectable states with the same name.
     For example if the state candidates are: m1.s, m1.v, m2.s, m2.v sd.s_rel (Two translational masses and a springdamper)
     then sd.s_rel should have lower priority than the others."
  input BackendDAE.Var v;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output Real prio;
protected
  list<Integer> vEqns;
  DAE.ComponentRef vCr;
  Integer vindx;
  Real prio1,prio2,prio3;
algorithm
  (_,vindx::_) := BackendVariable.getVar(BackendVariable.varCref(v),vars); // Variable index not stored in var itself => lookup required
  vEqns := BackendDAEUtil.eqnsForVarWithStates(mt,vindx);
  vCr := BackendVariable.varCref(v);
  prio1 := varStateSelectHeuristicPrio1(vCr,vEqns,vars,eqns);
  prio2 := varStateSelectHeuristicPrio2(vCr,vars);
  prio3 := varStateSelectHeuristicPrio3(vCr,vars);
  prio:= prio1 +. prio2 +. prio3;
end varStateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio3
"function varStateSelectHeuristicPrio3
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(cr,vars)
    local list<BackendDAE.Var> varLst,sameIdentVarLst; Real c,prio;
    case(cr,vars)
      equation
        varLst = BackendDAEUtil.varList(vars);
        sameIdentVarLst = Util.listSelect1(varLst,cr,varHasSameLastIdent);
        c = intReal(listLength(sameIdentVarLst));
        prio = c *. 0.01;
      then prio;
  end matchcontinue;
end varStateSelectHeuristicPrio3;

protected function varHasSameLastIdent
"function varHasSameLastIdent
  Helper funciton to varStateSelectHeuristicPrio3.
  Returns true if the variable has the same name (the last identifier)
  as the variable name given as second argument."
  input BackendDAE.Var v;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(v,cr)
    local DAE.ComponentRef cr2; DAE.Ident id1,id2;
    case(BackendDAE.VAR(varName=cr2 ),cr )
      equation
        true = ComponentReference.crefLastIdentEqual(cr,cr2);
      then true;
    case(_,_) then false;
  end matchcontinue;
end varHasSameLastIdent;

protected function varStateSelectHeuristicPrio2
"function varStateSelectHeuristicPrio2
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := matchcontinue(cr,vars)
    local
      list<BackendDAE.Var> varLst,sameCompVarLst;
    case(cr,vars)
      equation
        varLst = BackendDAEUtil.varList(vars);
        sameCompVarLst = Util.listSelect1(varLst,cr,varInSameComponent);
        _::_ = Util.listSelect(sameCompVarLst,BackendVariable.isDummyStateVar);
      then -1.0;
    case(cr,vars) then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio2;

protected function varInSameComponent
"function varInSameComponent
  Helper funciton to varStateSelectHeuristicPrio2.
  Returns true if the variable is defined in the same sub
  component as the variable name given as second argument."
  input BackendDAE.Var v;
  input DAE.ComponentRef cr;
  output Boolean b;
algorithm
  b := matchcontinue(v,cr)
    local DAE.ComponentRef cr2; DAE.Ident id1,id2;
    case(BackendDAE.VAR(varName=cr2 ),cr )
      equation
        true = ComponentReference.crefEqualNoStringCompare(ComponentReference.crefStripLastIdent(cr2),ComponentReference.crefStripLastIdent(cr));
      then true;
    case(_,_) then false;
  end matchcontinue;
end varInSameComponent;

protected function varStateSelectHeuristicPrio1
"function varStateSelectHeuristicPrio1
  author:  PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input list<Integer> eqnLst;
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  output Real prio;
algorithm
  prio := matchcontinue(cr,eqnLst,vars,eqns)
    local Integer e; BackendDAE.Equation eqn;
    case(cr,{},_,_) then 0.0;
    case(cr,e::eqnLst,vars,eqns)
      equation
        eqn = BackendDAEUtil.equationNth(eqns,e-1);
        true = isStateConstraintEquation(cr,eqn,vars);
      then -1.0;
    case(cr,_::eqnLst,vars,eqns) then varStateSelectHeuristicPrio1(cr,eqnLst,vars,eqns);
 end matchcontinue;
end varStateSelectHeuristicPrio1;

protected function isStateConstraintEquation
"function isStateConstraintEquation
  author: PA
  Help function to varStateSelectHeuristicPrio2
  Returns true if an equation is on the form cr = expr(s1,s2...sn) for states cr, s1,s2..,sn"
  input DAE.ComponentRef cr;
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  output Boolean res;
algorithm
  res := matchcontinue(cr,eqn,vars)
    local
      DAE.ComponentRef cr2;
      list<DAE.ComponentRef> crs;
      list<list<BackendDAE.Var>> crVars;
      list<Boolean> blst;
      DAE.Exp e2;

    // s = expr(s1,..,sn)  where s1 .. sn are states
    case(cr,BackendDAE.EQUATION(exp = DAE.CREF(cr2,_), scalar = e2),vars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Expression.terms(e2);
        crs = Expression.extractCrefsFromExp(e2);
        (crVars,_) = Util.listMap12(crs,BackendVariable.getVar,vars);
        blst = Util.listMap(Util.listFlatten(crVars),BackendVariable.isStateVar);
        res = Util.boolAndList(blst);
      then res;

    case(cr,BackendDAE.EQUATION(exp = e2, scalar = DAE.CREF(cr2,_)),vars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Expression.terms(e2);
        crs = Expression.extractCrefsFromExp(e2);
        (crVars,_) = Util.listMap12(crs,BackendVariable.getVar,vars);
        blst = Util.listMap(Util.listFlatten(crVars),BackendVariable.isStateVar);
        res = Util.boolAndList(blst);
      then res;

    case(cr,eqn,vars) then false;
  end matchcontinue;
end isStateConstraintEquation;

protected function varStateSelectPrio
"function varStateSelectPrio
  Helper function to calculateVarPriorities.
  Calculates a priority contribution bases on the stateSelect attribute."
  input BackendDAE.Var v;
  output Real prio;
  protected
  DAE.StateSelect ss;
algorithm
  ss := BackendVariable.varStateSelect(v);
  prio := varStateSelectPrio2(ss);
end varStateSelectPrio;

protected function varStateSelectPrio2
"helper function to varStateSelectPrio"
  input DAE.StateSelect ss;
  output Real prio;
algorithm
  prio := matchcontinue(ss)
    case (DAE.NEVER()) then -10.0;
    case (DAE.AVOID()) then 0.0;
    case (DAE.DEFAULT()) then 10.0;
    case (DAE.PREFER()) then 50.0;
    case (DAE.ALWAYS()) then 100.0;
  end matchcontinue;
end varStateSelectPrio2;

protected function calculateDummyStatePriorities
"function: calculateDummyStatePriority
  Calculates a priority for dummy state candidates.
  The state with lowest priority number is selected as a dummy variable.
  Heuristic parameters:
   1. States that has an initial condition is given pentalty 10.
   2. BackendDAE.Equation s1= p  s2 with states s1 and s2 gives penalty 1 for state s1.
  The heuristic parameters are summed to get the priority number."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input list<Integer> inIntegerLst;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<tuple<DAE.ComponentRef, Integer, Integer>> outTplExpComponentRefIntegerIntegerLst;
algorithm
  outTplExpComponentRefIntegerIntegerLst:=
  matchcontinue (inExpComponentRefLst,inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      BackendDAE.Value indx,prio;
      list<tuple<BackendDAE.Key, BackendDAE.Value, BackendDAE.Value>> res;
      list<BackendDAE.Key> crs;
      list<BackendDAE.Value> indxs;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
    case ({},{},_,_,_) then {};
    case ((cr :: crs),(indx :: indxs),dae,m,mt)
      equation
        (cr,indx,prio) = calculateDummyStatePriority(cr, indx, dae, m, mt);
        res = calculateDummyStatePriorities(crs, indxs, dae, m, mt);
      then
        ((cr,indx,prio) :: res);
  end matchcontinue;
end calculateDummyStatePriorities;

protected function calculateDummyStatePriority
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef1;
  output Integer outInteger2;
  output Integer outInteger3;
algorithm
  (outComponentRef1,outInteger2,outInteger3):=
  matchcontinue (inComponentRef,inInteger,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      BackendDAE.Value indx;
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
    case (cr,indx,dae,m,mt) then (cr,indx,0);
  end matchcontinue;
end calculateDummyStatePriority;

protected function statesInEqns
"function: statesInEqns
  author: PA
  Helper function to reduce_index_dummy_der.
  Returns all states in the equations given as equation index list.
  inputs:  (int list /* eqns */,
              DAELow,
              IncidenceMatrix,
              IncidenceMatrixT)
  outputs: (DAE.ComponentRef list, /* name for each state */
              int list)  /* number for each state */"
  input list<Integer> inIntegerLst;
  input BackendDAE.DAELow inDAELow;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inIntegerLst,inDAELow,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<BackendDAE.Key> res1,res11,res1_1;
      list<BackendDAE.Value> res2,vars2,res22,res2_1,rest;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn;
      list<BackendDAE.Var> varlst;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.DAELow daelow;
    case ({},_,_,_) then ({},{});
    case ((e :: rest),daelow as BackendDAE.DAELOW(orderedVars = vars,orderedEqs = eqns),m,mt)
      equation
        (res1,res2) = statesInEqns(rest, daelow, m, mt);
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        vars2 = statesInEqn(eqn, vars);
        varlst = BackendDAEUtil.varList(vars);
        (res11,res22) = statesInVars(varlst, vars2);
        res1_1 = listAppend(res11, res1);
        res2_1 = listAppend(res22, res2);
      then
        (res1_1,res2_1);
    case ((e :: rest),_,_,_)
      local String se;
      equation
        se = intString(e);
        print("-DAELow.statesInEqns failed for eqn: ");
        print(se);
        print("\n");
      then
        fail();
  end matchcontinue;
end statesInEqns;

protected function statesInVars "function: statesInVars
  author: PA

  Helper function to states_in_eqns

  inputs:  (Var list, int list)
  outputs: (DAE.ComponentRef list, /* names of the states */
              int list /* number for each state */)
"
  input list<BackendDAE.Var> inVarLst;
  input list<Integer> inIntegerLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inVarLst,inIntegerLst)
    local
      list<BackendDAE.Var> vars;
      BackendDAE.Value v_1,v;
      DAE.ComponentRef cr;
      DAE.Flow flowPrefix;
      list<BackendDAE.Key> res1;
      list<BackendDAE.Value> res2,rest;
    case (vars,{}) then ({},{});
    case (vars,(v :: rest))
      equation
        v_1 = v - 1;
        BackendDAE.VAR(varName = cr, flowPrefix = flowPrefix) = listNth(vars, v_1);
        (res1,res2) = statesInVars(vars, rest);
      then
        ((cr :: res1),(v :: res2));
    case (vars,(v :: rest))
      equation
        (res1,res2) = statesInVars(vars, rest);
      then
        (res1,res2);
  end matchcontinue;
end statesInVars;

protected function differentiateEqns
"function: differentiateEqns
  author: PA
  This function takes a dae, its incidence matrices and the number of
  equations an variables and a list of equation indices to
  differentiate. This is used in the index reduction algorithm
  using dummy derivatives, when all marked equations are differentiated.
  The function updates the dae, the incidence matrix and returns
  a list of indices of the differentiated equations, they are added last in
  the dae.
  inputs:  (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list) /* equations */
  outputs: (DAELow,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list /* differentiated equations */)"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input list<Integer> inIntegerLst6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output BackendDAE.DAELow outDAELow1;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix2;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT3;
  output Integer outInteger4;
  output Integer outInteger5;
  output list<Integer> outIntegerLst6;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
algorithm
  (outDAELow1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5,outIntegerLst6,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,e_1,leneqns,e;
      BackendDAE.Equation eqn,eqn_1;
      String str;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie;
      list<BackendDAE.Value> reqns,es;
      BackendDAE.Variables v,kv,ev;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
    case (dae,m,mt,nv,nf,{},_,inDerivedAlgs,inDerivedMultiEqn) then (dae,m,mt,nv,nf,{},inDerivedAlgs,inDerivedMultiEqn);
    case ((dae as BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,true) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        str = BackendDump.equationStr(eqn);
        //print( "differentiated equation ") ;
        Debug.fprint("bltdump", str)  ;
        //print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        //print(" to ");
        str = BackendDump.equationStr(eqn_1);
        //print(str);
        //print("\n");
        Debug.fprint("bltdump", str) "  print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        eqns_1 = equationAdd(eqns, eqn_1);
        leneqns = BackendDAEUtil.equationSize(eqns_1);
        DAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAELOW(v,kv,ev,av,eqns_1,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(leneqns :: (e :: reqns)),derivedAlgs1,derivedMultiEqn1);
    case ((dae as BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,false) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        str = BackendDump.equationStr(eqn);
        //print( "differentiated equation ") ;
        Debug.fprint("bltdump", str)  ;
        //print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        //print(" to ");
        str = BackendDump.equationStr(eqn_1);
        //print(str);
        //print("\n");
        Debug.fprint("bltdump", str) "  print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        leneqns = BackendDAEUtil.equationSize(eqns);
        DAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAELOW(v,kv,ev,av,eqns,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(e :: reqns),derivedAlgs1,derivedMultiEqn1);        
    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-differentiate_eqns failed\n");
      then
        fail();
  end matchcontinue;
end differentiateEqns;

public function equationAdd "function: equationAdd
  author: PA

  Adds an equation to an EquationArray.
"
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray:=
  matchcontinue (inEquationArray,inEquation)
    local
      BackendDAE.Value n_1,n,size,expandsize,expandsize_1,newsize;
      array<Option<BackendDAE.Equation>> arr_1,arr,arr_2;
      BackendDAE.Equation e;
      Real rsize,rexpandsize;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e)
      equation
        (n < size) = true "Have space to add array elt." ;
        n_1 = n + 1;
        arr_1 = arrayUpdate(arr, n + 1, SOME(e));
      then
        BackendDAE.EQUATION_ARRAY(n_1,size,arr_1);
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e) /* Do NOT Have space to add array elt. Expand array 1.4 times */
      equation
        (n < size) = false;
        rsize = intReal(size);
        rexpandsize = rsize *. 0.4;
        expandsize = realInt(rexpandsize);
        expandsize_1 = intMax(expandsize, 1);
        newsize = expandsize_1 + size;
        arr_1 = Util.arrayExpand(expandsize_1, arr,NONE());
        n_1 = n + 1;
        arr_2 = arrayUpdate(arr_1, n + 1, SOME(e));
      then
        BackendDAE.EQUATION_ARRAY(n_1,newsize,arr_2);
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),e)
      equation
        print("-equation_add failed\n");
      then
        fail();
  end matchcontinue;
end equationAdd;

public function equationSetnth "function: equationSetnth
  author: PA

  Sets the nth array element of an EquationArray.
"
  input BackendDAE.EquationArray inEquationArray;
  input Integer inInteger;
  input BackendDAE.Equation inEquation;
  output BackendDAE.EquationArray outEquationArray;
algorithm
  outEquationArray:=
  matchcontinue (inEquationArray,inInteger,inEquation)
    local
      array<Option<BackendDAE.Equation>> arr_1,arr;
      BackendDAE.Value n,size,pos;
      BackendDAE.Equation eqn;
    case (BackendDAE.EQUATION_ARRAY(numberOfElement = n,arrSize = size,equOptArr = arr),pos,eqn)
      equation
        arr_1 = arrayUpdate(arr, pos + 1, SOME(eqn));
      then
        BackendDAE.EQUATION_ARRAY(n,size,arr_1);
  end matchcontinue;
end equationSetnth;

protected function addMarkedVars "function: addMarkedVars
  author: PA

  This function is part of the matching algorithm.

  inputs:  (DAELow,
              IncidenceMatrix,
              IncidenceMatrixT,
              int, /* number of vars */
              int, /* number of eqns */
              int list /* marked vars */)
  outputs: (DAELow,
              IncidenceMatrix,
              IncidenceMatrixT,
              int, /* number of vars */
              int  /* number of eqns */)
"
  input BackendDAE.DAELow inDAELow1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input list<Integer> inIntegerLst6;
  output BackendDAE.DAELow outDAELow1;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix2;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT3;
  output Integer outInteger4;
  output Integer outInteger5;
algorithm
  (outDAELow1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5):=
  matchcontinue (inDAELow1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6)
    local
      BackendDAE.DAELow dae;
      array<list<BackendDAE.Value>> m,mt,nt;
      BackendDAE.Value nv,nf,nv_1,v;
      list<BackendDAE.Value> vs;
    case (dae,m,mt,nv,nf,{}) then (dae,m,mt,nv,nf);
    case (dae,m,nt,nv,nf,(v :: vs))
      equation
        nv_1 = nv + 1 "TODO remove variable from dae and m,mt and add der{variable} instead" ;
        DAEEXT.setV(v, nv_1);
        (dae,m,mt,nv,nf) = addMarkedVars(dae, m, nt, nv_1, nf, vs);
      then
        (dae,m,mt,nv,nf);
  end matchcontinue;
end addMarkedVars;

protected function pathFound "function: pathFound
  author: PA

  This function is part of the matching algorithm.
  It tries to find a matching for the equation index given as
  third argument, i.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int /* equation */,
               Assignments, Assignments)
  outputs: (Assignments, Assignments)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        DAEEXT.eMark(i) "Side effect" ;
        (ass1_1,ass2_1) = assignOneInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (m,mt,i,ass1,ass2)
      equation
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqn(m, mt, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end pathFound;

protected function assignOneInEqn "function: assignOneInEqn
  author: PA

  Helper function to path_found.
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      list<BackendDAE.Value> vars;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        vars = BackendDAEUtil.varsInEqn(m, i);
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vars, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignOneInEqn;

protected function statesInEqn "function: statesInEqn
  author: PA
  Helper function to states_in_eqns
"
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  output list<Integer> res;
  BackendDAE.Variables vars_1;
algorithm
  vars_1 := statesAsAlgebraicVars(vars);
  res := BackendDAEUtil.incidenceRow(vars_1, eqn,{});
end statesInEqn;

protected function statesAsAlgebraicVars "function: statesAsAlgebraicVars
  author: PA

  Return the subset of variables consisting of all states, but changed
  varkind to variable.
"
  input BackendDAE.Variables vars;
  output BackendDAE.Variables v1_1;
  list<BackendDAE.Var> varlst,varlst_1;
  BackendDAE.Variables v1,v1_1;
algorithm
  varlst := BackendDAEUtil.varList(vars) "Creates a new set of BackendDAE.Variables from a BackendDAE.Var list" ;
  varlst_1 := statesAsAlgebraicVars2(varlst);
  v1 := BackendDAEUtil.emptyVars();
  v1_1 := BackendVariable.addVars(varlst_1, v1);
end statesAsAlgebraicVars;

protected function statesAsAlgebraicVars2 "function: statesAsAlgebraicVars2
  author: PA

  helper function to states_as_algebraic_vars
"
  input list<BackendDAE.Var> inVarLst;
  output list<BackendDAE.Var> outVarLst;
algorithm
  outVarLst:=
  matchcontinue (inVarLst)
    local
      list<BackendDAE.Var> res,vs;
      DAE.ComponentRef cr;
      DAE.VarDirection a;
      BackendDAE.Type b;
      Option<DAE.Exp> c,f;
      Option<Values.Value> d;
      list<DAE.Subscript> e;
      BackendDAE.Value g;
      list<Absyn.Path> i;
      DAE.ElementSource source "the element source";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;

    case {} then {};
    case ((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = a,
               varType = b,
               bindExp = c,
               bindValue = d,
               arryDim = e,
               index = g,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        res = statesAsAlgebraicVars2(vs) "states treated as algebraic variables" ;
      then
        (BackendDAE.VAR(cr,BackendDAE.VARIABLE(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: res);

    case ((BackendDAE.VAR(varName = cr,
               varDirection = a,
               varType = b,
               bindExp = c,
               bindValue = d,
               arryDim = e,
               index = g,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix) :: vs))
      equation
        res = statesAsAlgebraicVars2(vs) "other variables treated as known" ;
      then
        (BackendDAE.VAR(cr,BackendDAE.CONST(),a,b,c,d,e,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: res);

    case ((_ :: vs))
      equation
        res = statesAsAlgebraicVars2(vs);
      then
        res;
  end matchcontinue;
end statesAsAlgebraicVars2;

protected function assignFirstUnassigned
"function: assignFirstUnassigned
  author: PA
  This function assigns the first unassign variable to the equation
  given as first argument. It is part of the matching algorithm.
  inputs:  (int /* equation */,
            int list /* variables */,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments,  /* ass1 */
            Assignments)  /* ass2 */"
  input Integer inInteger1;
  input list<Integer> inIntegerLst2;
  input BackendDAE.Assignments inAssignments3;
  input BackendDAE.Assignments inAssignments4;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inInteger1,inIntegerLst2,inAssignments3,inAssignments4)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      BackendDAE.Value i,v;
      list<BackendDAE.Value> vs;
    case (i,(v :: vs),ass1,ass2)
      equation
        0 = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = assign(v, i, ass1, ass2);
      then
        (ass1_1,ass2_1);
    case (i,(v :: vs),ass1,ass2)
      equation
        (ass1_1,ass2_1) = assignFirstUnassigned(i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assignFirstUnassigned;

protected function getAssigned
"function: getAssigned
  author: PA
  returns the assigned equation for a variable.
  inputs:  (int    /* variable */,
            Assignments,  /* ass1 */
            Assignments)  /* ass2 */
  outputs:  int /* equation */"
  input Integer inInteger1;
  input BackendDAE.Assignments inAssignments2;
  input BackendDAE.Assignments inAssignments3;
  output Integer outInteger;
algorithm
  outInteger:=
  matchcontinue (inInteger1,inAssignments2,inAssignments3)
    local
      BackendDAE.Value v;
      array<BackendDAE.Value> m;
    case (v,BackendDAE.ASSIGNMENTS(arrOfIndices = m),_) then m[v];
  end matchcontinue;
end getAssigned;

protected function assign
"function: assign
  author: PA
  Assign a variable to an equation, updating both assignment lists.
  inputs: (int, /* variable */
           int, /* equation */
           Assignments, /* ass1 */
           Assignments) /* ass2 */
  outputs: (Assignments,  /* updated ass1 */
            Assignments)  /* updated ass2 */"
  input Integer inInteger1;
  input Integer inInteger2;
  input BackendDAE.Assignments inAssignments3;
  input BackendDAE.Assignments inAssignments4;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inInteger1,inInteger2,inAssignments3,inAssignments4)
    local
      BackendDAE.Value v_1,e_1,v,e;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
    case (v,e,ass1,ass2)
      equation
        v_1 = v - 1 "print \"assign \" & intString v => vs & intString e => es & print vs & print \" to eqn \" & print es & print \"\\n\" &" ;
        e_1 = e - 1;
        ass1_1 = assignmentsSetnth(ass1, v_1, e);
        ass2_1 = assignmentsSetnth(ass2, e_1, v);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end assign;

protected function forallUnmarkedVarsInEqn
"function: forallUnmarkedVarsInEqn
  author: PA
  This function is part of the matching algorithm.
  It loops over all umarked variables in an equation.
  inputs:  (IncidenceMatrix,
            IncidenceMatrixT,
            int,
            BackendDAE.Assignments /* ass1 */,
            BackendDAE.Assignments /* ass2 */)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input BackendDAE.Assignments inAssignments4;
  input BackendDAE.Assignments inAssignments5;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
    local
      list<BackendDAE.Value> vars,vars_1;
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value i;
    case (m,mt,i,ass1,ass2)
      equation
        vars = BackendDAEUtil.varsInEqn(m, i);
        vars_1 = Util.listFilter(vars, isNotVMarked);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vars_1, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqn;

protected function isNotVMarked
"function: isNotVMarked
  author: PA
  This function succeds for variables that are not marked."
  input Integer i;
algorithm
  false := DAEEXT.getVMark(i);
end isNotVMarked;

protected function forallUnmarkedVarsInEqnBody
"function: forallUnmarkedVarsInEqnBody
  author: PA
  This function is part of the matching algorithm.
  It is the body of the loop over all unmarked variables.
  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT,
            int,
            int list /* var list */
            Assignments
            Assignments)
  outputs: (Assignments, Assignments)"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input Integer inInteger3;
  input list<Integer> inIntegerLst4;
  input BackendDAE.Assignments inAssignments5;
  input BackendDAE.Assignments inAssignments6;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inIntegerLst4,inAssignments5,inAssignments6)
    local
      BackendDAE.Value assarg,i,v;
      BackendDAE.Assignments ass1_1,ass2_1,ass1_2,ass2_2,ass1,ass2;
      array<list<BackendDAE.Value>> m,mt;
      list<BackendDAE.Value> vars,vs;
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        DAEEXT.vMark(v);
        assarg = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = pathFound(m, mt, assarg, ass1, ass2);
        (ass1_2,ass2_2) = assign(v, i, ass1_1, ass2_1);
      then
        (ass1_2,ass2_2);
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        DAEEXT.vMark(v);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqnBody;

public function strongComponents "function: strongComponents
  author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector)
  outputs: (int list list /* list of components */ )
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4)
    local
      BackendDAE.Value n,i;
      list<BackendDAE.Value> stack;
      list<list<BackendDAE.Value>> comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> ass1,ass2;
    case (m,mt,ass1,ass2)
      equation
        n = arrayLength(m);
        DAEEXT.initLowLink(n);
        DAEEXT.initNumber(n);
        (i,stack,comps) = strongConnectMain(m, mt, ass1, ass2, n, 0, 1, {}, {});
      then
        comps;
    case (_,_,_,_)
      equation
        Debug.fprint("failtrace", "strong_components failed\n");
        Error.addMessage(Error.INTERNAL_ERROR,
          {"sorting equations(strong components failed)"});
      then
        fail();
  end matchcontinue;
end strongComponents;

protected function strongConnectMain "function: strongConnectMain
  author: PA

  Helper function to strong_components

  inputs:  (IncidenceMatrix,
              IncidenceMatrixT,
              int vector, /* Assignment */
              int vector, /* Assignment */
              int, /* n - number of equations */
              int, /* i */
              int, /* w */
              int list, /* stack */
              int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input Integer inInteger7;
  input list<Integer> inIntegerLst8;
  input list<list<Integer>> inIntegerLstLst9;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inInteger7,inIntegerLst8,inIntegerLstLst9)
    local
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Value n,i,w,w_1,num;
      list<BackendDAE.Value> stack,stack_1,stack_2;
      list<list<BackendDAE.Value>> comp,comps;
    case (m,mt,a1,a2,n,i,w,stack,comp)
      equation
        (w > n) = true;
      then
        (i,stack,comp);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      local list<list<Integer>> comps2;

      equation
        0 = DAEEXT.getNumber(w);
        (i,stack_1,comps) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        w_1 = w + 1;
        (i,stack_2,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack_1, comps);
      then
        (i,stack_2,comps);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      equation
        num = DAEEXT.getNumber(w);
        (num == 0) = false;
        w_1 = w + 1;
        (i,stack_1,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack, comps);
      then
        (i,stack_1,comps);
  end matchcontinue;
end strongConnectMain;

protected function strongConnect "function: strongConnect
  author: PA

  Helper function to strong_connect_main

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */ )
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  input list<list<Integer>> inIntegerLstLst8;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7,inIntegerLstLst8)
    local
      BackendDAE.Value i_1,i,v;
      list<BackendDAE.Value> stack_1,eqns,stack_2,stack_3,comp,stack;
      list<list<BackendDAE.Value>> comps_1,comps_2,comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,stack,comps)
      equation
        i_1 = i + 1;
        DAEEXT.setNumber(v, i_1)  ;
        DAEEXT.setLowLink(v, i_1);
        stack_1 = (v :: stack);
        eqns = reachableNodes(v, m, mt, a1, a2);
        (i_1,stack_2,comps_1) = iterateReachableNodes(eqns, m, mt, a1, a2, i_1, v, stack_1, comps);
        (i_1,stack_3,comp) = checkRoot(m, mt, a1, a2, i_1, v, stack_2);
        comps_2 = consIfNonempty(comp, comps_1);
      then
        (i_1,stack_3,comps_2);
    case (_,_,_,_,_,_,_,_)
      equation
        Debug.fprint("failtrace", "-strong_connect failed\n");
      then
        fail();
  end matchcontinue;
end strongConnect;

protected function consIfNonempty "function: consIfNonempty
  author: PA

  Small helper function to avoid empty sublists.
  Consider moving to Util?
"
  input list<Integer> inIntegerLst;
  input list<list<Integer>> inIntegerLstLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  outIntegerLstLst:=
  matchcontinue (inIntegerLst,inIntegerLstLst)
    local
      list<list<BackendDAE.Value>> lst;
      list<BackendDAE.Value> e;
    case ({},lst) then lst;
    case (e,lst) then (e :: lst);
  end matchcontinue;
end consIfNonempty;

public function reachableNodes "function: reachableNodes
  author: PA

  Helper function to strong_connect.
  Returns a list of reachable nodes (equations), corresponding
  to those equations that uses the solved variable of this equation.
  The edges of the graph that identifies strong components/blocks are
  dependencies between blocks. A directed edge e = (n1,n2) means
  that n1 solves for a variable (e.g. \'a\') that is used in the equation
  of n2, i.e. the equation of n1 must be solved before the equation of n2.
"
  input Integer inInteger1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5)
    local
      BackendDAE.Value eqn_1,var,var_1,pos,eqn;
      list<BackendDAE.Value> reachable,reachable_1,reachable_2;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      String eqnstr;
    case (eqn,m,mt,a1,a2)
      equation
        eqn_1 = eqn - 1;
        var = a2[eqn_1 + 1];
        var_1 = var - 1;
        reachable = mt[var_1 + 1] "Got the variable that is solved in the equation" ;
        reachable_1 = BackendDAEUtil.removeNegative(reachable) "in which other equations is this variable present ?" ;
        pos = Util.listPosition(eqn, reachable_1) ".. except this one" ;
        reachable_2 = listDelete(reachable_1, pos);
      then
        reachable_2;
    case (eqn,_,_,_,_)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-reachable_nodes failed, eqn: ");
        eqnstr = intString(eqn);
        Debug.fprint("failtrace", eqnstr);
        Debug.fprint("failtrace", "\n");
      then
        fail();
  end matchcontinue;
end reachableNodes;

protected function iterateReachableNodes "function: iterateReachableNodes
  author: PA

  Helper function to strong_connect.

  inputs:  (int list, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list list /* components */)
  outputs: (int /* i */, int list /* stack */, int list list /* components */)
"
  input list<Integer> inIntegerLst1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input array<Integer> inIntegerArray4;
  input array<Integer> inIntegerArray5;
  input Integer inInteger6;
  input Integer inInteger7;
  input list<Integer> inIntegerLst8;
  input list<list<Integer>> inIntegerLstLst9;
  output Integer outInteger;
  output list<Integer> outIntegerLst;
  output list<list<Integer>> outIntegerLstLst;
algorithm
  (outInteger,outIntegerLst,outIntegerLstLst):=
  matchcontinue (inIntegerLst1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerArray4,inIntegerArray5,inInteger6,inInteger7,inIntegerLst8,inIntegerLstLst9)
    local
      BackendDAE.Value i,lv,lw,minv,w,v,nw,nv,lowlinkv;
      list<BackendDAE.Value> stack,ws;
      list<list<BackendDAE.Value>> comps_1,comps_2,comps;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        0 = DAEEXT.getNumber(w);
        (i,stack,comps_1) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        lv = DAEEXT.getLowLink(v);
        lw = DAEEXT.getLowLink(w);
        minv = intMin(lv, lw);
        DAEEXT.setLowLink(v, minv);
        (i,stack,comps_2) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps_1);
      then
        (i,stack,comps_2);
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        nw = DAEEXT.getNumber(w);
        nv = DAEEXT.getNumber(v);
        (nw < nv) = true;
        true = listMember(w, stack);
        lowlinkv = DAEEXT.getLowLink(v);
        minv = intMin(nw, lowlinkv);
        DAEEXT.setLowLink(v, minv);
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);

    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);
    case ({},m,mt,a1,a2,i,v,stack,comps) then (i,stack,comps);
  end matchcontinue;
end iterateReachableNodes;

protected function checkRoot "function: checkRoot
  author: PA

  Helper function to strong_connect.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */)
  outputs: (int /* i */, int list /* stack */, int list /* comps */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  output Integer outInteger1;
  output list<Integer> outIntegerLst2;
  output list<Integer> outIntegerLst3;
algorithm
  (outInteger1,outIntegerLst2,outIntegerLst3):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7)
    local
      BackendDAE.Value lv,nv,i,v;
      list<BackendDAE.Value> stack_1,comps,stack;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,stack)
      equation
        lv = DAEEXT.getLowLink(v);
        nv = DAEEXT.getNumber(v);
        (lv == nv) = true;
        (i,stack_1,comps) = checkStack(m, mt, a1, a2, i, v, stack, {});
      then
        (i,stack_1,comps);
    case (m,mt,a1,a2,i,v,stack) then (i,stack,{});
  end matchcontinue;
end checkRoot;

protected function checkStack "function: checkStack
  author: PA

  Helper function to check_root.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector,
              int /* i */, int /* v */, int list /* stack */, int list /* component list */)
  outputs: (int /* i */, int list /* stack */, int list /* comps */)
"
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  input Integer inInteger5;
  input Integer inInteger6;
  input list<Integer> inIntegerLst7;
  input list<Integer> inIntegerLst8;
  output Integer outInteger1;
  output list<Integer> outIntegerLst2;
  output list<Integer> outIntegerLst3;
algorithm
  (outInteger1,outIntegerLst2,outIntegerLst3):=
  matchcontinue (inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4,inInteger5,inInteger6,inIntegerLst7,inIntegerLst8)
    local
      BackendDAE.Value topn,vn,i,v,top;
      list<BackendDAE.Value> stack_1,comp_1,rest,comp,stack;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
    case (m,mt,a1,a2,i,v,(top :: rest),comp)
      equation
        topn = DAEEXT.getNumber(top);
        vn = DAEEXT.getNumber(v);
        (topn >= vn) = true;
        (i,stack_1,comp_1) = checkStack(m, mt, a1, a2, i, v, rest, comp);
      then
        (i,stack_1,(top :: comp_1));
    case (m,mt,a1,a2,i,v,stack,comp) then (i,stack,comp);
  end matchcontinue;
end checkStack;

public function translateDae "function: translateDae
  author: PA

  Translates the dae so variables are indexed into different arrays:
  - xd for derivatives
  - x for states
  - dummy_der for dummy derivatives
  - dummy for dummy states
  - y for algebraic variables
  - p for parameters
"
  input BackendDAE.DAELow inDAELow;
  input Option<String> dummy;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow:=
  matchcontinue (inDAELow,dummy)
    local
      list<BackendDAE.Var> varlst,knvarlst,extvarlst;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      list<BackendDAE.WhenClause> wc;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.Variables vars, knvars, extVars;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,seqns,ieqns;
      BackendDAE.DAELow trans_dae;
      BackendDAE.ExternalObjectClasses extObjCls;
    case (BackendDAE.DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,al,BackendDAE.EVENT_INFO(whenClauseLst = wc,zeroCrossingLst = zc),extObjCls),_)
      equation
        varlst = BackendDAEUtil.varList(vars);
        knvarlst = BackendDAEUtil.varList(knvars);
        extvarlst = BackendDAEUtil.varList(extVars);
        varlst = listReverse(varlst);
        knvarlst = listReverse(knvarlst);
        extvarlst = listReverse(extvarlst);
        (varlst,knvarlst,extvarlst) = calculateIndexes(varlst, knvarlst,extvarlst);
        vars = BackendVariable.addVars(varlst, vars);
        knvars = BackendVariable.addVars(knvarlst, knvars);
        extVars = BackendVariable.addVars(extvarlst, extVars);
        trans_dae = BackendDAE.DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,al,
          BackendDAE.EVENT_INFO(wc,zc),extObjCls);
        Debug.fcall("dumpindxdae", BackendDump.dump, trans_dae);
      then
        trans_dae;
  end matchcontinue;
end translateDae;

public function analyzeJacobian "function: analyzeJacobian
  author: PA

  Analyze the jacobian to find out if the jacobian of system of equations
  can be solved at compiletime or runtime or if it is a nonlinear system
  of equations.
"
  input BackendDAE.DAELow inDAELow;
  input Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> inTplIntegerIntegerEquationLstOption;
  output BackendDAE.JacobianType outJacobianType;
algorithm
  outJacobianType:=
  matchcontinue (inDAELow,inTplIntegerIntegerEquationLstOption)
    local
      BackendDAE.DAELow daelow;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> jac;
    case (daelow,SOME(jac))
      equation
        true = jacobianConstant(jac);
        true = rhsConstant(daelow);
      then
        BackendDAE.JAC_CONSTANT();
    case (daelow,SOME(jac))
      equation
        true = jacobianNonlinear(daelow, jac);
      then
        BackendDAE.JAC_NONLINEAR();
    case (daelow,SOME(jac)) then BackendDAE.JAC_TIME_VARYING();
    case (daelow,NONE()) then BackendDAE.JAC_NO_ANALYTIC();
  end matchcontinue;
end analyzeJacobian;

protected function rhsConstant "function: rhsConstant
  author: PA

  Determines if the right hand sides of an equation system,
  represented as a DAELow, is constant.
"
  input BackendDAE.DAELow inDAELow;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inDAELow)
    local
      list<BackendDAE.Equation> eqn_lst;
      Boolean res;
      BackendDAE.DAELow dae;
      BackendDAE.Variables vars,knvars;
      BackendDAE.EquationArray eqns;
    case ((dae as BackendDAE.DAELOW(orderedVars = vars,knownVars = knvars,orderedEqs = eqns)))
      equation
        eqn_lst = BackendDAEUtil.equationList(eqns);
        res = rhsConstant2(eqn_lst, dae);
      then
        res;
  end matchcontinue;
end rhsConstant;

public function getEqnsysRhsExp "function: getEqnsysRhsExp
  author: PA

  Retrieve the right hand side expression of an equation
  in an equation system, given a set of variables.

  inputs:  (DAE.Exp, BackendDAE.Variables /* variables of the eqn sys. */)
  outputs:  DAE.Exp =
"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output DAE.Exp outExp;
algorithm
  outExp:=
  matchcontinue (inExp,inVariables)
    local
      list<DAE.Exp> term_lst,rhs_lst,rhs_lst2;
      DAE.Exp new_exp,res,exp;
      BackendDAE.Variables vars;
    case (exp,vars)
      equation
        term_lst = Expression.allTerms(exp);
        rhs_lst = Util.listSelect1(term_lst, vars, freeFromAnyVar);
        /* A term can contain if-expressions that has branches that are on rhs and other branches that
        are on lhs*/
        rhs_lst2 = ifBranchesFreeFromVar(term_lst,vars);
        new_exp = Expression.makeSum(listAppend(rhs_lst,rhs_lst2));
        res = ExpressionSimplify.simplify(new_exp);
      then
        res;
    case (_,_)
      equation
        Debug.fprint("failtrace", "-get_eqnsys_rhs_exp failed\n");
      then
        fail();
  end matchcontinue;
end getEqnsysRhsExp;

public function ifBranchesFreeFromVar "Retrieves if-branches free from any of the variables passed as argument.

This is done by replacing the variables with zero."
  input list<DAE.Exp> expl;
  input BackendDAE.Variables vars;
  output list<DAE.Exp> outExpl;
algorithm
  outExpl := matchcontinue(expl,vars)
    local DAE.Exp cond,t,f,e1,e2;
      VarTransform.VariableReplacements repl;
      DAE.Operator op;
      Absyn.Path path;
      list<DAE.Exp> expl2;
      Boolean tpl ;
      Boolean b;
      DAE.InlineType i;
      DAE.ExpType ty;
    case({},vars) then {};
    case(DAE.IFEXP(cond,t,f)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      t = ifBranchesFreeFromVar2(t,repl);
      f = ifBranchesFreeFromVar2(f,repl);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.IFEXP(cond,t,f)::expl);
    case(DAE.BINARY(e1,op,e2)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      {e1} = ifBranchesFreeFromVar({e1},vars);
      {e2} = ifBranchesFreeFromVar({e2},vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.BINARY(e1,op,e2)::expl);

    case(DAE.UNARY(op,e1)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      {e1} = ifBranchesFreeFromVar({e1},vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.UNARY(op,e1)::expl);

    case(DAE.CALL(path,expl2,tpl,b,ty,i)::expl,vars) equation
      repl = makeZeroReplacements(vars);
      (expl2 as _::_) = ifBranchesFreeFromVar(expl2,vars);
      expl = ifBranchesFreeFromVar(expl,vars);
    then (DAE.CALL(path,expl2,tpl,b,ty,i)::expl);

  case(_::expl,vars) equation
      expl = ifBranchesFreeFromVar(expl,vars);
  then expl;
  end matchcontinue;
end ifBranchesFreeFromVar;

protected function ifBranchesFreeFromVar2 "Help function to ifBranchesFreeFromVar,
replaces variables in if branches (not conditions) recursively (to include elseifs)"
  input DAE.Exp ifBranch;
  input VarTransform.VariableReplacements repl;
  output DAE.Exp outIfBranch;
algorithm
  outIfBranch := matchcontinue(ifBranch,repl)
  local DAE.Exp cond,t,f,e;
    case(DAE.IFEXP(cond,t,f),repl) equation
      t = ifBranchesFreeFromVar2(t,repl);
      f = ifBranchesFreeFromVar2(f,repl);
    then DAE.IFEXP(cond,t,f);
    case(e,repl) equation
      e = VarTransform.replaceExp(e,repl,NONE());
    then e;
  end matchcontinue;
end ifBranchesFreeFromVar2;

protected function makeZeroReplacements "Help function to ifBranchesFreeFromVar, creates replacement rules
v -> 0, for all variables"
  input BackendDAE.Variables vars;
  output VarTransform.VariableReplacements repl;
  protected list<BackendDAE.Var> varLst;
algorithm
  varLst := BackendDAEUtil.varList(vars);
  repl := Util.listFold(varLst,makeZeroReplacement,VarTransform.emptyReplacements());
end makeZeroReplacements;

protected function makeZeroReplacement "helper function to makeZeroReplacements.
Creates replacement Var-> 0"
  input BackendDAE.Var var;
  input VarTransform.VariableReplacements repl;
  output VarTransform.VariableReplacements outRepl;
  protected
  DAE.ComponentRef cr;
algorithm
  cr :=  BackendVariable.varCref(var);
  outRepl := VarTransform.addReplacement(repl,cr,DAE.RCONST(0.0));
end makeZeroReplacement;

public function getEquationBlock "function: getEquationBlock
  author: PA

  Returns the block the equation belongs to.
"
  input Integer inInteger;
  input list<list<Integer>> inIntegerLstLst;
  output list<Integer> outIntegerLst;
algorithm
  outIntegerLst:=
  matchcontinue (inInteger,inIntegerLstLst)
    local
      BackendDAE.Value e;
      list<BackendDAE.Value> block_,res;
      list<list<BackendDAE.Value>> blocks;
    case (e,(block_ :: blocks))
      equation
        true = listMember(e, block_);
      then
        block_;
    case (e,(block_ :: blocks))
      equation
        res = getEquationBlock(e, blocks);
      then
        res;
  end matchcontinue;
end getEquationBlock;

protected function rhsConstant2 "function: rhsConstant2
  author: PA
  Helper function to rhsConstant, traverses equation list."
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.DAELow inDAELow;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inEquationLst,inDAELow)
    local
      DAE.ExpType tp;
      DAE.Exp new_exp,rhs_exp,e1,e2,e;
      Boolean res;
      list<BackendDAE.Equation> rest;
      BackendDAE.DAELow dae;
      BackendDAE.Variables vars;
      BackendDAE.Value indx_1,indx;
      list<BackendDAE.Value> ds;
      list<DAE.Exp> expl;
      array<BackendDAE.MultiDimEquation> arreqn;

    case ({},_) then true;
    // check rhs for for EQUATION nodes.
    case ((BackendDAE.EQUATION(exp = e1,scalar = e2) :: rest),(dae as BackendDAE.DAELOW(orderedVars = vars)))
      equation
        tp = Expression.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        true = Expression.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;
    // check rhs for for ARRAY_EQUATION nodes. check rhs for for RESIDUAL_EQUATION nodes.
    case ((BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl) :: rest),(dae as BackendDAE.DAELOW(orderedVars = vars,arrayEqs = arreqn)))
      equation
        indx_1 = indx - 1;
        BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,_) = arreqn[indx + 1];
        tp = Expression.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(tp),e2);
        rhs_exp = getEqnsysRhsExp(new_exp, vars);
        true = Expression.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;

    case ((BackendDAE.RESIDUAL_EQUATION(exp = e) :: rest),(dae as BackendDAE.DAELOW(orderedVars = vars))) /* check rhs for for RESIDUAL_EQUATION nodes. */
      equation
        rhs_exp = getEqnsysRhsExp(e, vars);
        true = Expression.isConst(rhs_exp);
        res = rhsConstant2(rest, dae);
      then
        res;
    case (_,_) then false;
  end matchcontinue;
end rhsConstant2;

protected function freeFromAnyVar "function: freeFromAnyVar
  author: PA
  Helper function to rhsConstant2
  returns true if expression does not contain
  anyof the variables passed as argument."
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExp,inVariables)
    local
      DAE.Exp e;
      list<BackendDAE.Key> crefs;
      list<Boolean> b_lst;
      Boolean res,res_1;
      BackendDAE.Variables vars;

    case (e,_)
      equation
        {} = Expression.extractCrefsFromExp(e) "Special case for expressions with no variables" ;
      then
        true;
    case (e,vars)
      equation
        crefs = Expression.extractCrefsFromExp(e);
        b_lst = Util.listMap1(crefs, BackendVariable.existsVar, vars);
        res = Util.boolOrList(b_lst);
        res_1 = boolNot(res);
      then
        res_1;
    case (_,_) then true;
  end matchcontinue;
end freeFromAnyVar;

public function jacobianTypeStr "function: jacobianTypeStr
  author: PA
  Returns the jacobian type as a string, used for debugging."
  input BackendDAE.JacobianType inJacobianType;
  output String outString;
algorithm
  outString := matchcontinue (inJacobianType)
    case BackendDAE.JAC_CONSTANT() then "Jacobian Constant";
    case BackendDAE.JAC_TIME_VARYING() then "Jacobian Time varying";
    case BackendDAE.JAC_NONLINEAR() then "Jacobian Nonlinear";
    case BackendDAE.JAC_NO_ANALYTIC() then "No analythic jacobian";
  end matchcontinue;
end jacobianTypeStr;

protected function jacobianConstant "function: jacobianConstant
  author: PA
  Checks if jacobian is constant, i.e. all expressions in each equation are constant."
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inTplIntegerIntegerEquationLst)
    local
      DAE.Exp e1,e2,e;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
    case ({}) then true;
    case (((_,_,BackendDAE.EQUATION(exp = e1,scalar = e2)) :: eqns)) /* TODO: Algorithms and ArrayEquations */
      equation
        true = Expression.isConst(e1);
        true = Expression.isConst(e2);
        true = jacobianConstant(eqns);
      then
        true;
    case (((_,_,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: eqns))
      equation
        true = Expression.isConst(e);
        true = jacobianConstant(eqns);
      then
        true;
    case (((_,_,BackendDAE.SOLVED_EQUATION(exp = e)) :: eqns))
      equation
        true = Expression.isConst(e);
        true = jacobianConstant(eqns);
      then
        true;
    case (_) then false;
  end matchcontinue;
end jacobianConstant;

protected function jacobianNonlinear "function: jacobianNonlinear
  author: PA
  Check if jacobian indicates a nonlinear system.
  TODO: Algorithms and Array equations"
  input BackendDAE.DAELow inDAELow;
  input list<tuple<Integer, Integer, BackendDAE.Equation>> inTplIntegerIntegerEquationLst;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inDAELow,inTplIntegerIntegerEquationLst)
    local
      BackendDAE.DAELow daelow;
      DAE.Exp e1,e2,e;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> xs;

    case (daelow,((_,_,BackendDAE.EQUATION(exp = e1,scalar = e2)) :: xs))
      equation
        false = jacobianNonlinearExp(daelow, e1);
        false = jacobianNonlinearExp(daelow, e2);
        false = jacobianNonlinear(daelow, xs);
      then
        false;
    case (daelow,((_,_,BackendDAE.RESIDUAL_EQUATION(exp = e)) :: xs))
      equation
        false = jacobianNonlinearExp(daelow, e);
        false = jacobianNonlinear(daelow, xs);
      then
        false;
    case (_,{}) then false;
    case (_,_) then true;
  end matchcontinue;
end jacobianNonlinear;

protected function jacobianNonlinearExp "function: jacobianNonlinearExp
  author: PA
  Checks wheter the jacobian indicates a nonlinear system.
  This is true if the jacobian contains any of the variables
  that is solved for."
  input BackendDAE.DAELow inDAELow;
  input DAE.Exp inExp;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inDAELow,inExp)
    local
      list<BackendDAE.Key> crefs;
      Boolean res;
      BackendDAE.Variables vars;
      DAE.Exp e;
    case (BackendDAE.DAELOW(orderedVars = vars),e)
      equation
        crefs = Expression.extractCrefsFromExp(e);
        res = containAnyVar(crefs, vars);
      then
        res;
  end matchcontinue;
end jacobianNonlinearExp;

protected function containAnyVar "function: containAnyVar
  author: PA
  Returns true if any of the variables given
  as ComponentRef list is among the Variables."
  input list<DAE.ComponentRef> inExpComponentRefLst;
  input BackendDAE.Variables inVariables;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue (inExpComponentRefLst,inVariables)
    local
      DAE.ComponentRef cr;
      list<BackendDAE.Key> crefs;
      BackendDAE.Variables vars;
      Boolean res;
    case ({},_) then false;
    case ((cr :: crefs),vars)
      equation
        (_,_) = BackendVariable.getVar(cr, vars);
      then
        true;
    case ((_ :: crefs),vars)
      equation
        res = containAnyVar(crefs, vars);
      then
        res;
  end matchcontinue;
end containAnyVar;

public function calculateJacobian "function: calculateJacobian
  This function takes an array of equations and the variables of the equation
  and calculates the jacobian of the equations."
  input BackendDAE.Variables inVariables;
  input BackendDAE.EquationArray inEquationArray;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm
  outTplIntegerIntegerEquationLstOption:=
  matchcontinue (inVariables,inEquationArray,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,differentiateIfExp)
    local
      list<BackendDAE.Equation> eqn_lst,eqn_lst_1;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> jac;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
    case (vars,eqns,ae,m,mt,differentiateIfExp)
      equation
        eqn_lst = BackendDAEUtil.equationList(eqns);
        eqn_lst_1 = Util.listMap(eqn_lst, equationToResidualForm);
        SOME(jac) = calculateJacobianRows(eqn_lst_1, vars, ae, m, mt,differentiateIfExp);
      then
        SOME(jac);
    case (_,_,_,_,_,_) then NONE();  /* no analythic jacobian available */
  end matchcontinue;
end calculateJacobian;

protected function calculateJacobianRows "function: calculateJacobianRows
  author: PA
  This function takes a list of Equations and a set of variables and
  calculates the jacobian expression for each variable over each equations,
  returned in a sparse matrix representation.
  For example, the equation on index e1: 3ax+5yz+ zz  given the
  variables {x,y,z} on index x1,y1,z1 gives
  {(e1,x1,3a), (e1,y1,5z), (e1,z1,5y+2z)}"
  input list<BackendDAE.Equation> eqns;
  input BackendDAE.Variables vars;
  input array<BackendDAE.MultiDimEquation> ae;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> res;
algorithm
  (res,_) := calculateJacobianRows2(eqns, vars, ae, m, mt, 1,differentiateIfExp, {});
end calculateJacobianRows;

protected function calculateJacobianRows2 "function: calculateJacobianRows2
  author: PA
  Helper function to calculateJacobianRows"
  input list<BackendDAE.Equation> inEquationLst;
  input BackendDAE.Variables inVariables;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (outTplIntegerIntegerEquationLstOption,outEntrylst):=
  matchcontinue (inEquationLst,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger,differentiateIfExp,inEntrylst)
    local
      BackendDAE.Value eqn_indx_1,eqn_indx;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> l1,l2,res;
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      BackendDAE.Variables vars;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1,entrylst2; 
    case ({},_,_,_,_,_,_,inEntrylst) then (SOME({}),inEntrylst);
    case ((eqn :: eqns),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        eqn_indx_1 = eqn_indx + 1;
        (SOME(l1),entrylst1) = calculateJacobianRows2(eqns, vars, ae, m, mt, eqn_indx_1,differentiateIfExp,inEntrylst);
        (SOME(l2),entrylst2) = calculateJacobianRow(eqn, vars, ae, m, mt, eqn_indx,differentiateIfExp,entrylst1);
        res = listAppend(l1, l2);
      then
        (SOME(res),entrylst2);
  end matchcontinue;
end calculateJacobianRows2;

protected function calculateJacobianRow "function: calculateJacobianRow
  author: PA
  Calculates the jacobian for one equation. See calculateJacobianRows.
  inputs:  (Equation,
              Variables,
              BackendDAE.MultiDimEquation array,
              IncidenceMatrix,
              IncidenceMatrixT,
              int /* eqn index */)
  outputs: ((int  int  Equation) list option)"
  input BackendDAE.Equation inEquation;
  input BackendDAE.Variables inVariables;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input Integer inInteger;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inEntrylst;
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outEntrylst;
algorithm
  (outTplIntegerIntegerEquationLstOption,outEntrylst):=
  matchcontinue (inEquation,inVariables,inMultiDimEquationArray,inIncidenceMatrix,inIncidenceMatrixT,inInteger,differentiateIfExp,inEntrylst)
    local
      list<BackendDAE.Value> var_indxs,var_indxs_1,ds;
      list<Option<Integer>> ad;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> eqns;
      DAE.Exp e,e1,e2,new_exp;
      BackendDAE.Variables vars;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value eqn_indx,indx;
      list<DAE.Exp> in_,out,expl;
      Expression.Type t;
      list<DAE.Subscript> subs;   
      list<tuple<Integer,list<list<DAE.Subscript>>>> entrylst1;   
    // residual equations
    case (BackendDAE.RESIDUAL_EQUATION(exp = e),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        var_indxs = BackendDAEUtil.varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, int_eq) "Remove duplicates and get in correct order: ascending index" ;
        SOME(eqns) = calculateJacobianRow2(e, vars, eqn_indx, var_indxs_1,differentiateIfExp);
      then
        (SOME(eqns),inEntrylst);
    // algorithms give no jacobian
    case (BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst) then (NONE(),inEntrylst);
    // array equations
    case (BackendDAE.ARRAY_EQUATION(index = indx,crefOrDerCref = expl),vars,ae,m,mt,eqn_indx,differentiateIfExp,inEntrylst)
      equation
        BackendDAE.MULTIDIM_EQUATION(ds,e1,e2,_) = ae[indx + 1];
        t = Expression.typeof(e1);
        new_exp = DAE.BINARY(e1,DAE.SUB_ARR(t),e2);
        ad = Util.listMap(ds,Util.makeOption);
        (subs,entrylst1) = getArrayEquationSub(indx,ad,inEntrylst);
        new_exp = Expression.applyExpSubscripts(new_exp,subs); 
        var_indxs = BackendDAEUtil.varsInEqn(m, eqn_indx);
        var_indxs_1 = Util.listUnionOnTrue(var_indxs, {}, int_eq) "Remove duplicates and get in correct order: acsending index";
        SOME(eqns) = calculateJacobianRow2(new_exp, vars, eqn_indx, var_indxs_1,differentiateIfExp);
      then
        (SOME(eqns),entrylst1);
  end matchcontinue;
end calculateJacobianRow;

public function getArrayEquationSub"function: getArrayEquationSub
  author: Frenkel TUD
  helper for calculateJacobianRow and SimCode.dlowEqToExp"
  input Integer Index;
  input list<Option<Integer>> inAD;
  input list<tuple<Integer,list<list<DAE.Subscript>>>> inList;
  output list<DAE.Subscript> outSubs;
  output list<tuple<Integer,list<list<DAE.Subscript>>>> outList;
algorithm
  (outSubs,outList) := 
  matchcontinue (Index,inAD,inList)
    local
      Integer i,ie;
      list<Option<Integer>> ad;
      list<DAE.Subscript> subs,subs1;
      list<list<DAE.Subscript>> subslst,subslst1;
      list<tuple<Integer,list<list<DAE.Subscript>>>> rest,entrylst;
      tuple<Integer,list<list<DAE.Subscript>>> entry;
    // new entry  
    case (i,ad,{})
      equation
        subslst = arrayDimensionsToRange(ad);
        (subs::subslst1) = BackendDAEUtil.rangesToSubscripts(subslst);
      then
        (subs,{(i,subslst1)});
    // found last entry
    case (i,ad,(entry as (ie,{subs}))::rest)
      equation
        true = intEq(i,ie);
      then   
        (subs,rest);         
    // found entry
    case (i,ad,(entry as (ie,subs::subslst))::rest)
      equation
        true = intEq(i,ie);
      then   
        (subs,(ie,subslst)::rest); 
    // next entry  
    case (i,ad,(entry as (ie,subslst))::rest)
      equation
        false = intEq(i,ie);
        (subs1,entrylst) = getArrayEquationSub(i,ad,rest);
      then   
        (subs1,entry::entrylst); 
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.getArrayEquationSub failed");
      then
        fail();          
  end matchcontinue;      
end getArrayEquationSub;

protected function makeResidualEqn "function: makeResidualEqn
  author: PA
  Transforms an expression into a residual equation"
  input DAE.Exp inExp;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inExp)
    local DAE.Exp e;
    case (e) then BackendDAE.RESIDUAL_EQUATION(e,DAE.emptyElementSource);
  end matchcontinue;
end makeResidualEqn;

protected function calculateJacobianRow2 "function: calculateJacobianRow2
  author: PA
  Helper function to calculateJacobianRow
  Differentiates expression for each variable cref.
  inputs: (DAE.Exp,
             Variables,
             int, /* equation index */
             int list) /* var indexes */
  outputs: ((int int Equation) list option)"
  input DAE.Exp inExp;
  input BackendDAE.Variables inVariables;
  input Integer inInteger;
  input list<Integer> inIntegerLst;
  input Boolean differentiateIfExp "If true, allow differentiation of if-expressions";
  output Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> outTplIntegerIntegerEquationLstOption;
algorithm
  outTplIntegerIntegerEquationLstOption := matchcontinue (inExp,inVariables,inInteger,inIntegerLst,differentiateIfExp)
    local
      DAE.Exp e,e_1,e_2;
      BackendDAE.Var v;
      DAE.ComponentRef cr;
      list<tuple<BackendDAE.Value, BackendDAE.Value, BackendDAE.Equation>> es;
      BackendDAE.Variables vars;
      BackendDAE.Value eqn_indx,vindx;
      list<BackendDAE.Value> vindxs;

    case (e,_,_,{},_) then SOME({});
    case (e,vars,eqn_indx,(vindx :: vindxs),differentiateIfExp)
      equation
        v = BackendVariable.getVarAt(vars, vindx);
        cr = BackendVariable.varCref(v);
        e_1 = Derive.differentiateExp(e, cr, differentiateIfExp);
        e_2 = ExpressionSimplify.simplify(e_1);
        SOME(es) = calculateJacobianRow2(e, vars, eqn_indx, vindxs, differentiateIfExp);
      then
        SOME(((eqn_indx,vindx,BackendDAE.RESIDUAL_EQUATION(e_2,DAE.emptyElementSource)) :: es));
  end matchcontinue;
end calculateJacobianRow2;

public function residualExp "function: residualExp
  author: PA
  This function extracts the residual expression from a residual equation"
  input BackendDAE.Equation inEquation;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue (inEquation)
    local DAE.Exp e;
    case (BackendDAE.RESIDUAL_EQUATION(exp = e)) then e;
  end matchcontinue;
end residualExp;

public function toResidualForm "function: toResidualForm
  author: PA
  This function transforms a daelow to residualform on the equations."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow)
    local
      list<BackendDAE.Equation> eqn_lst,eqn_lst2;
      BackendDAE.EquationArray eqns2,eqns,seqns,ieqns;
      BackendDAE.Variables vars,knvars,extVars;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> ialg;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses extobjcls;

    case (BackendDAE.DAELOW(vars,knvars,extVars,av,eqns,seqns,ieqns,ae,ialg,wc,extobjcls))
      equation
        eqn_lst = BackendDAEUtil.equationList(eqns);
        eqn_lst2 = Util.listMap(eqn_lst, equationToResidualForm);
        eqns2 = BackendDAEUtil.listEquation(eqn_lst2);
      then
        BackendDAE.DAELOW(vars,knvars,extVars,av,eqns2,seqns,ieqns,ae,ialg,wc,extobjcls);
  end matchcontinue;
end toResidualForm;

public function equationToResidualForm "function: equationToResidualForm
  author: PA
  This function transforms an equation to its residual form.
  For instance, a=b is transformed to a-b=0"
  input BackendDAE.Equation inEquation;
  output BackendDAE.Equation outEquation;
algorithm
  outEquation := matchcontinue (inEquation)
    local
      DAE.Exp e,e1,e2,exp;
      DAE.ComponentRef cr;
      DAE.ExpType tp;
      DAE.ElementSource source "origin of the element";
      DAE.Operator op;
      Boolean b;

    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source))
      equation
         //ExpressionDump.dumpExpWithTitle("equationToResidualForm 1\n",e2);
        tp = Expression.typeof(e2);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));
        e = ExpressionSimplify.simplify(DAE.BINARY(e1,op,e2));
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = exp,source = source))
      equation
         //ExpressionDump.dumpExpWithTitle("equationToResidualForm 2\n",exp);
        tp = Expression.typeof(exp);
        b = DAEUtil.expTypeArray(tp);
        op = Util.if_(b,DAE.SUB_ARR(tp),DAE.SUB(tp));        
        e = ExpressionSimplify.simplify(DAE.BINARY(DAE.CREF(cr,tp),op,exp));
      then
        BackendDAE.RESIDUAL_EQUATION(e,source);
    case ((e as BackendDAE.RESIDUAL_EQUATION(exp = _,source = source)))
      local BackendDAE.Equation e;
      then
        e;
    case ((e as BackendDAE.ALGORITHM(index = _)))
      local BackendDAE.Equation e;
      then
        e;
    case ((e as BackendDAE.ARRAY_EQUATION(index = _)))
      local BackendDAE.Equation e;
      then
        e;
    case ((e as BackendDAE.WHEN_EQUATION(whenEquation = _)))
      local BackendDAE.Equation e;
      then
        e;
    case (e)
      local BackendDAE.Equation e;
      equation
        Debug.fprintln("failtrace", "- DAELow.equationToResidualForm failed");
      then
        fail();
  end matchcontinue;
end equationToResidualForm;

public function calculateSizes "function: calculateSizes
  author: PA
  Calculates the number of state variables, nx,
  the number of algebraic variables, ny
  and the number of parameters/constants, np.
  inputs:  DAELow
  outputs: (int, /* nx */
            int, /* ny */
            int, /* np */
            int  /* ng */
            int) next"
  input BackendDAE.DAELow inDAELow;
  output Integer outnx        "number of states";
  output Integer outny        "number of alg. vars";
  output Integer outnp        "number of parameters";
  output Integer outng        "number of zerocrossings";
  output Integer outng_sample "number of zerocrossings that are samples";
  output Integer outnext      "number of external objects";
  // nx cannot be strings
  output Integer outny_string "number of alg.vars which are strings";
  output Integer outnp_string "number of parameters which are strings";
  // nx cannot be int
  output Integer outny_int    "number of alg.vars which are ints";
  output Integer outnp_int    "number of parameters which are ints";
  // nx cannot be int
  output Integer outny_bool   "number of alg.vars which are bools";
  output Integer outnp_bool   "number of parameters which are bools";    
algorithm
  (outnx,outny,outnp,outng,outng_sample,outnext, outny_string, outnp_string, outny_int, outnp_int, outny_bool, outnp_bool):=
  matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> varlst,knvarlst,extvarlst;
      BackendDAE.Value np,ng,nsam,nx,ny,nx_1,ny_1,next,ny_string,np_string,ny_1_string,np_int,np_bool,ny_int,ny_1_int,ny_bool,ny_1_bool;
      String np_str;
      BackendDAE.Variables vars,knvars,extvars;
      list<BackendDAE.WhenClause> wc;
      list<BackendDAE.ZeroCrossing> zc;
    
    case (BackendDAE.DAELOW(orderedVars = vars,knownVars = knvars, externalObjects = extvars,
                 eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc,
                                        zeroCrossingLst = zc)))
      equation
        varlst = BackendDAEUtil.varList(vars) "input variables are put in the known var list, but they should be counted by the ny counter.";
        extvarlst = BackendDAEUtil.varList(extvars);
        next = listLength(extvarlst);
        knvarlst = BackendDAEUtil.varList(knvars);
        (np,np_string,np_int, np_bool) = calculateParamSizes(knvarlst);
        np_str = intString(np);
        (ng,nsam) = calculateNumberZeroCrossings(zc, 0, 0);
        (nx,ny,ny_string,ny_int, ny_bool) = calculateVarSizes(varlst, 0, 0, 0, 0, 0);
        (nx_1,ny_1,ny_1_string,ny_1_int, ny_1_bool) = calculateVarSizes(knvarlst, nx, ny, ny_string, ny_int, ny_bool);
      then
        (nx_1,ny_1,np,ng,nsam,next,ny_1_string, np_string, ny_1_int, np_int, ny_1_bool, np_bool);
  end matchcontinue;
end calculateSizes;

protected function calculateNumberZeroCrossings
  input list<BackendDAE.ZeroCrossing> zcLst;
  input Integer zc_index;
  input Integer sample_index;
  output Integer zc;
  output Integer sample;
algorithm
  (zc,sample) := matchcontinue (zcLst,zc_index,sample_index)
    local
      list<BackendDAE.ZeroCrossing> xs;
    
    case ({},zc_index,sample_index) then (zc_index,sample_index);

    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.CALL(path = Absyn.IDENT(name = "sample"))) :: xs,zc_index,sample_index)
      equation
        sample_index = sample_index + 1;
        zc_index = zc_index + 1;
        (zc,sample) = calculateNumberZeroCrossings(xs,zc_index,sample_index);
      then (zc,sample);

    case (BackendDAE.ZERO_CROSSING(relation_ = DAE.RELATION(operator = _), occurEquLst = _) :: xs,zc_index,sample_index)
      equation
        zc_index = zc_index + 1;
        (zc,sample) = calculateNumberZeroCrossings(xs,zc_index,sample_index);
      then (zc,sample);

    case (_,_,_)
      equation
        print("- DAELow.calculateNumberZeroCrossings failed\n");
      then
        fail();

  end matchcontinue;
end calculateNumberZeroCrossings;

protected function calculateParamSizes "function: calculateParamSizes
  author: PA
  Helper function to calculateSizes"
  input list<BackendDAE.Var> inVarLst;
  output Integer outInteger;
  output Integer outInteger2;
  output Integer outInteger3;
  output Integer outInteger4;
algorithm
  (outInteger,outInteger2,outInteger3, outInteger4):=
  matchcontinue (inVarLst)
    local
      BackendDAE.Value s1,s2,s3, s4;
      BackendDAE.Var var;
      list<BackendDAE.Var> vs;
    case ({}) then (0,0,0,0);
    case ((var :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
        true = BackendVariable.isBoolParam(var);
      then
        (s1,s2,s3,s4 + 1);  
    case ((var :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
        true = BackendVariable.isIntParam(var);
      then
        (s1,s2,s3 + 1,s4);
    case ((var :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
        true = BackendVariable.isStringParam(var);
      then
        (s1,s2 + 1,s3,s4);
    case ((var :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
        true = BackendVariable.isParam(var);
      then
        (s1 + 1,s2,s3,s4);
    case ((_ :: vs))
      equation
        (s1,s2,s3,s4) = calculateParamSizes(vs);
      then
        (s1,s2,s3,s4);
    case (_)
      equation
        print("- DAELow.calculateParamSizes failed\n");
      then
        fail();        
  end matchcontinue;
end calculateParamSizes;

protected function calculateVarSizes "function: calculateVarSizes
  author: PA
  Helper function to calculateSizes"
  input list<BackendDAE.Var> inVarLst1;
  input Integer inInteger2;
  input Integer inInteger3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;

  output Integer outInteger1;
  output Integer outInteger2;
  output Integer outInteger3;
  output Integer outInteger4;
  output Integer outInteger5;

algorithm
  (outInteger1,outInteger2,outInteger3, outInteger4,outInteger5):=
  matchcontinue (inVarLst1,inInteger2,inInteger3,inInteger4,inInteger5,inInteger6)
    local
      BackendDAE.Value nx,ny,ny_1,nx_2,ny_2,nx_1,nx_string,ny_string,ny_1_string,ny_2_string;
      BackendDAE.Value ny_int, ny_1_int, ny_2_int, ny_bool, ny_1_bool, ny_2_bool;
      DAE.Flow flowPrefix;
      list<BackendDAE.Var> vs;
    
    case ({},nx,ny,ny_string, ny_int, ny_bool) then (nx,ny,ny_string,ny_int, ny_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_1_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_int = ny_int + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_1_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);    

    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_bool = ny_bool + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_int, ny_1_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);    

    case ((BackendDAE.VAR(varKind = BackendDAE.VARIABLE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny_1, ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool); 
    
     case ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_1_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
        
     case ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1_int = ny_int + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_1_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
     
     case ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_bool = ny_bool + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_int, ny_1_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);     
                 
     case ((BackendDAE.VAR(varKind = BackendDAE.DISCRETE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny_1, ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.STATE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        nx_1 = nx + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx_1, ny, ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool) /* A dummy state is an algebraic variable */
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_1_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
        
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.INT(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool) /* A dummy state is an algebraic variable */
      equation
        ny_1_int = ny_int + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_1_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
    
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_bool = ny_bool + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_int, ny_1_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);   
        
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool) /* A dummy state is an algebraic variable */
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny_1,ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);

    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.STRING(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1_string = ny_string + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny,ny_1_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
        
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.INT(),flowPrefix = flowPrefix) :: vs),nx, ny, ny_string, ny_int, ny_bool)
      equation
         ny_1_int = ny_int + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_1_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);
    
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),varType=BackendDAE.BOOL(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int,ny_bool)
      equation
        ny_1_bool = ny_bool + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny, ny_string, ny_int, ny_1_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool);  
        
    case ((BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(),flowPrefix = flowPrefix) :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        ny_1 = ny + 1;
        (nx_2,ny_2,ny_2_string, ny_2_int, ny_2_bool) = calculateVarSizes(vs, nx, ny_1,ny_string, ny_int, ny_bool);
      then
        (nx_2,ny_2,ny_2_string, ny_2_int,ny_2_bool); 

    case ((_ :: vs),nx,ny,ny_string, ny_int, ny_bool)
      equation
        (nx_1,ny_1,ny_1_string, ny_1_int, ny_1_bool) = calculateVarSizes(vs, nx, ny,ny_string,ny_int, ny_bool);
      then
        (nx_1,ny_1,ny_1_string, ny_1_int, ny_1_bool);
        
    case (_,_,_,_,_,_)
      equation
        print("- DAELow.calculateVarSizes failed\n");
      then
        fail();
  end matchcontinue;
end calculateVarSizes;

public function calculateValues "function: calculateValues
  author: PA
  This function calculates the values from the parameter binding expressions."
  input BackendDAE.DAELow inDAELow;
  output BackendDAE.DAELow outDAELow;
algorithm
  outDAELow := matchcontinue (inDAELow)
    local
      list<BackendDAE.Var> knvarlst;
      BackendDAE.Variables knvars,vars,extVars;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns,seqns,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses extObjCls;
    case (BackendDAE.DAELOW(orderedVars = vars,knownVars = knvars,externalObjects=extVars,aliasVars = av,orderedEqs = eqns,
                 removedEqs = seqns,initialEqs = ie,arrayEqs = ae,algorithms = al,eventInfo = wc,extObjClasses=extObjCls))
      equation
        knvarlst = BackendDAEUtil.varList(knvars);
        knvarlst = Util.listMap1(knvarlst, calculateValue, knvars);
        knvars = BackendDAEUtil.listVar(knvarlst);
      then
        BackendDAE.DAELOW(vars,knvars,extVars,av,eqns,seqns,ie,ae,al,wc,extObjCls);
  end matchcontinue;
end calculateValues;

protected function calculateValue
  input BackendDAE.Var inVar;
  input BackendDAE.Variables vars;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue(inVar, vars)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind vk;
      DAE.VarDirection vd;
      BackendDAE.Type ty;
      DAE.Exp e, e2;
      DAE.InstDims dims;
      Integer idx;
      DAE.ElementSource src;
      Option<DAE.VariableAttributes> va;
      Option<SCode.Comment> c;
      DAE.Flow fp;
      DAE.Stream sp;
      Values.Value v;
    case (BackendDAE.VAR(varName = cr, varKind = vk, varDirection = vd, varType = ty,
          bindExp = SOME(e), arryDim = dims, index = idx, source = src, 
          values = va, comment = c, flowPrefix = fp, streamPrefix = sp), _)
      equation
        ((e2, _)) = Expression.traverseExp(e, replaceCrefsWithValues, vars);
        (_, v, _) = Ceval.ceval(Env.emptyCache(), Env.emptyEnv, e2, false,NONE(), NONE(), Ceval.MSG());
      then
        BackendDAE.VAR(cr, vk, vd, ty, SOME(e), SOME(v), dims, idx, src, va, c, fp, sp);
    case (_, _) then inVar;
  end matchcontinue;
end calculateValue;

protected function replaceCrefsWithValues
  input tuple<DAE.Exp, BackendDAE.Variables> inTuple;
  output tuple<DAE.Exp, BackendDAE.Variables> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      BackendDAE.Variables vars;
      DAE.ComponentRef cr;
    case ((DAE.CREF(cr, _), vars))
      equation
         ({BackendDAE.VAR(bindExp = SOME(e))}, _) = BackendVariable.getVar(cr, vars);
         ((e, _)) = Expression.traverseExp(e, replaceCrefsWithValues, vars);
      then
        ((e, vars));
    case (_) then inTuple;
  end matchcontinue;
end replaceCrefsWithValues;
  
protected function getIndex "function: getIndex
  author: PA
  Helper function to derivativeReplacements"
  input DAE.ComponentRef inComponentRef;
  input list<BackendDAE.Var> inVarLst;
  output Integer outInteger;
algorithm
  outInteger := matchcontinue (inComponentRef,inVarLst)
    local
      DAE.ComponentRef cr1,cr2;
      BackendDAE.Value indx;
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      list<BackendDAE.Var> vs;
    case (cr1,(BackendDAE.VAR(varName = cr2,index = indx,values = dae_var_attr,comment = comment,flowPrefix = flowPrefix) :: _))
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr1, cr2);
      then
        indx;
    case (cr1,(_ :: vs))
      equation
        indx = getIndex(cr1, vs);
      then
        indx;
  end matchcontinue;
end getIndex;

protected function calculateIndexes "function: calculateIndexes
  author: PA modified by Frenkel TUD

  Helper function to translate_dae. Calculates the indexes for each variable
  in one of the arrays. x, xd, y and extobjs.
  To ensure that arrays(matrix,vector) are in a continuous memory block
  the indexes from vars, knvars and extvars has to be calculate at the same time.
  To seperate them after that they are stored in a list with
  the information about the type(vars=0,knvars=1,extvars=2) and the place at the
  original list."
  input list<BackendDAE.Var> inVarLst1;
  input list<BackendDAE.Var> inVarLst2;
  input list<BackendDAE.Var> inVarLst3;

  output list<BackendDAE.Var> outVarLst1;
  output list<BackendDAE.Var> outVarLst2;
  output list<BackendDAE.Var> outVarLst3;
algorithm
  (outVarLst1,outVarLst2,outVarLst3) := matchcontinue (inVarLst1,inVarLst2,inVarLst3)
    local
      list<BackendDAE.Var> vars_2,knvars_2,extvars_2,extvars,vars,knvars;
      list< tuple<BackendDAE.Var,Integer> > vars_1,knvars_1,extvars_1;
      list< tuple<BackendDAE.Var,Integer,Integer> > vars_map,knvars_map,extvars_map,all_map,all_map1,noScalar_map,noScalar_map1,scalar_map,all_map2,mergedvar_map,sort_map,sort_map1;
      BackendDAE.Value x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType;
    case (vars,knvars,extvars)
      equation
        // store vars,knvars,extvars in the list
        vars_map = fillListConst(vars,0,0);
        knvars_map = fillListConst(knvars,1,0);
        extvars_map = fillListConst(extvars,2,0);
        // connect the lists
        all_map = listAppend(vars_map,knvars_map);
        all_map1 = listAppend(all_map,extvars_map);
        // seperate scalars and non scalars
        (noScalar_map,scalar_map) = getNoScalarVars(all_map1);

        noScalar_map1 = getAllElements(noScalar_map);
        sort_map = sortNoScalarList(noScalar_map1);
        //print("\nsort_map:\n");
        //dumpSortMap(sort_map);
        // connect scalars and sortet non scalars
        mergedvar_map = listAppend(scalar_map,sort_map);
        // calculate indexes
        (all_map2,x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) = calculateIndexes2(mergedvar_map, 0, 0, 0, 0, 0,0,0,0,0,0,0);
        // seperate vars,knvars,extvas
        vars_1 = getListConst(all_map2,0);
        knvars_1 = getListConst(all_map2,1);
        extvars_1 =  getListConst(all_map2,2);
        // arrange lists in original order
        vars_2 = sortList(vars_1,0);
        knvars_2 = sortList(knvars_1,0);
        extvars_2 =  sortList(extvars_1,0);
      then
        (vars_2,knvars_2,extvars_2);
    case (_,_,_)
      equation
        print("-calculate_indexes failed\n");
      then
        fail();
  end matchcontinue;
end calculateIndexes;

protected function fillListConst
"function: fillListConst
author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list, a type value an a start place and store all elements
  of the list in a list of tuples (element,type,place)"
  input list<Type_a> inTypeALst;
  input Integer inType;
  input Integer inPlace;
  output list< tuple<Type_a,Integer,Integer> > outlist;
  replaceable type Type_a subtypeof Any;
algorithm
  outlist := matchcontinue (inTypeALst,inType,inPlace)
    local
      list<Type_a> rest;
      Type_a item;
      Integer value,place;
      list< tuple<Type_a,Integer,Integer> > out_lst,val_lst;
    case ({},value,place) then {};
    case (item::rest,value,place)
      equation
        /* recursive */
        val_lst = fillListConst(rest,value,place+1);
        /* fill  */
        out_lst = listAppend({(item,value,place)},val_lst);
      then
        out_lst;
  end matchcontinue;
end fillListConst;

protected function getListConst
"function: getListConst
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list of tuples (element,type,place) and a type value
  and pitch on all elements with the same type value.
  The output is a list of tuples (element,place)."
  input list< tuple<Type_a,Integer,Integer> > inTypeALst;
  input Integer inValue;
  output list<tuple<Type_a,Integer>> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst :=
  matchcontinue (inTypeALst,inValue)
    local
      list<tuple<Type_a,Integer,Integer>> rest;
      Type_a item;
      Integer value, itemvalue,place;
      list<tuple<Type_a,Integer>> out_lst,val_lst,val_lst1;
    case ({},value) then {};
    case ((item,itemvalue,place)::rest,value)
      equation
        /* recursive */
        val_lst = getListConst(rest,value);
        /* fill  */
        val_lst1 = Util.if_(itemvalue == value,{(item,place)},{});
        out_lst = listAppend(val_lst1,val_lst);
      then
        out_lst;
  end matchcontinue;
end getListConst;

protected function sortList
"function: sortList
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a list of tuples (element,place)and generate a
  list of elements with the order given by the place value."
  input list< tuple<Type_a,Integer> > inTypeALst;
  input Integer inPlace;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst := matchcontinue (inTypeALst,inPlace)
    local
      list<tuple<Type_a,Integer>> itemlst,rest;
      Type_a item,outitem;
      Integer place,itemplace;
      list<Type_a> out_lst,val_lst;
    case ({},place) then {};
    case (itemlst,place)
      equation
        /* get item */
        (outitem,rest) = sortList1(itemlst,place);
        /* recursive */
        val_lst = sortList(rest,place+1);
        /* append  */
        out_lst = listAppend({outitem},val_lst);
      then
        out_lst;
  end matchcontinue;
end sortList;

protected function sortList1
"function: sortList1
  author: Frenkel TUD
  Helper function for sortList"
  input list< tuple<Type_a,Integer> > inTypeALst;
  input Integer inPlace;
  output Type_a outType;
  output list< tuple<Type_a,Integer> > outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  (outType,outTypeALst) :=
  matchcontinue (inTypeALst,inPlace)
    local
      list<tuple<Type_a,Integer>> rest,out_itemlst;
      Type_a item;
      Integer place,itemplace;
      Type_a out_item;
    case ({},_)
      equation
        print("-sortList1 failed\n");
      then
        fail();
    case ((item,itemplace)::rest,place)
      equation
        /* compare */
        (place == itemplace) = true;
        /* ok */
        then
          (item,rest);
    case ((item,itemplace)::rest,place)
      equation
        /* recursive */
        (out_item,out_itemlst) = sortList1(rest,place);
      then
        (out_item,(item,itemplace)::out_itemlst);
  end matchcontinue;
end sortList1;

protected function getNoScalarVars
"function: getNoScalarVars
  author: Frenkel TUD
  Helper function for calculateIndexes.
  Get a List of variables and seperate them
  in two lists. One for scalars and one for non scalars"
  input list< tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outnoScalarlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outScalarlist;
algorithm
  (outnoScalarlist,outScalarlist) := matchcontinue (inlist)
    local
      list< tuple<BackendDAE.Var,Integer,Integer> > noScalarlst,scalarlst,rest,noScalarlst1,scalarlst1,noScalarlst2,scalarlst2;
      BackendDAE.Var var,var1;
      Integer typ,place;
    case {} then ({},{});
    case ((var,typ,place) :: rest)
      equation
        /* recursive */
        (noScalarlst,scalarlst) = getNoScalarVars(rest);
        /* check  */
        (noScalarlst1,scalarlst1) = checkVarisNoScalar(var,typ,place);
        noScalarlst2 = listAppend(noScalarlst1,noScalarlst);
        scalarlst2 = listAppend(scalarlst1,scalarlst);
      then
        (noScalarlst2,scalarlst2);
    case (_)
      equation
        print("getNoScalarVars fails\n");
      then
        fail();
  end matchcontinue;
end getNoScalarVars;

protected function checkVarisNoScalar
"function: checkVarisNoScalar
  author: Frenkel TUD
  Helper function for getNoScalarVars.
  Take a variable and push them in a list
  for scalars ore non scalars"
  input BackendDAE.Var invar;
  input Integer inTyp;
  input Integer inPlace;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist1;
algorithm
  (outlist,outlist1) :=
  matchcontinue (invar,inTyp,inPlace)
    local
      DAE.InstDims dimlist;
      BackendDAE.Var var;
      Integer typ,place;
    case (var as (BackendDAE.VAR(arryDim = {})),typ,place) then ({},{(var,typ,place)});
    case (var as (BackendDAE.VAR(arryDim = dimlist)),typ,place) then ({(var,typ,place)},{});
  end matchcontinue;
end checkVarisNoScalar;

protected function getAllElements
"function: getAllElements
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
algorithm
  outlist:=
  matchcontinue (inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2,out_lst;
      BackendDAE.Var var,var1;
      Boolean ins;
      Integer typ,place;
    case {} then {};
    case ((var,typ,place) :: rest)
      equation
        (var_lst,var_lst1) = getAllElements1((var,typ,place),rest);
        var_lst2 = getAllElements(var_lst1);
        out_lst = listAppend(var_lst,var_lst2);
      then
        out_lst;
  end matchcontinue;
end getAllElements;

protected function getAllElements1
"function: getAllElements1
  author: Frenkel TUD
  Helper function for getAllElements."
  input tuple<BackendDAE.Var,Integer,Integer>  inVar;
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist1;
algorithm
  (outlist,outlist1) := matchcontinue (inVar,inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2,var_lst3,out_lst;
      DAE.ComponentRef varName1, varName2,c2,c1;
      BackendDAE.Var var1,var2;
      Boolean ins;
      Integer typ1,typ2,place1,place2;
    case ((var1,typ1,place1),{}) then ({(var1,typ1,place1)},{});
    case ((var1 as BackendDAE.VAR(varName = varName1), typ1, place1), (var2 as BackendDAE.VAR(varName = varName2), typ2, place2) :: rest)
      equation
        (var_lst, var_lst1) = getAllElements1((var1, typ1, place1), rest);
        c1 = ComponentReference.crefStripLastSubs(varName1);
        c2 = ComponentReference.crefStripLastSubs(varName2);        
        ins = ComponentReference.crefEqualNoStringCompare(c1, c2); 
        var_lst2 = listAppendTyp(ins, (var2, typ2, place2), var_lst);
        var_lst3 = listAppendTyp(boolNot(ins), (var2, typ2, place2), var_lst1);
      then
        (var_lst2, var_lst3);
  end matchcontinue;
end getAllElements1;

protected function sortNoScalarList
"function: sortNoScalarList
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
algorithm
  outlist:=
  matchcontinue (inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,out_lst;
      BackendDAE.Var var,var1;
      Boolean ins;
      Integer typ,place;
    case {} then {};
    case ((var,typ,place) :: rest)
      equation
        var_lst = sortNoScalarList(rest);
        (var_lst1,ins) = sortNoScalarList1((var,typ,place),var_lst);
        out_lst = listAppendTyp(boolNot(ins),(var,typ,place),var_lst1);
      then
        out_lst;
  end matchcontinue;
end sortNoScalarList;

protected function listAppendTyp
"function: listAppendTyp
  author: Frenkel TUD
  Takes a list of unsortet noScalarVars
  and returns a sorted list"
  input Boolean append;
  input Type_a  invar;
  input list<Type_a > inlist;
  output list<Type_a > outlist;
  replaceable type Type_a subtypeof Any;
algorithm
  (outlist):=
  matchcontinue (append,invar,inlist)
    local
      list<Type_a > var_lst;
      Type_a var;
    case (false,_,var_lst) then var_lst;
    case (true,var,var_lst)
      local
       list<Type_a > out_lst;
      equation
        out_lst = var::var_lst;
      then
        out_lst;
  end matchcontinue;
end listAppendTyp;

protected function sortNoScalarList1
"function: sortNoScalarList1
  author: Frenkel TUD
  Helper function for sortNoScalarList"
  input tuple<BackendDAE.Var,Integer,Integer>  invar;
  input list<tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list<tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output Boolean insert;
algorithm
  (outlist,insert):=
  matchcontinue (invar,inlist)
    local
      list<tuple<BackendDAE.Var,Integer,Integer>> rest,var_lst,var_lst1,var_lst2;
      BackendDAE.Var var,var1;
      Boolean ins,ins1,ins2;
      Integer typ,typ1,place,place1;
    case (_,{}) then ({},false);
    case ((var,typ,place),(var1,typ1,place1)::rest)
      equation
        (var_lst,ins) = sortNoScalarList1((var,typ,place),rest);
        (var_lst1,ins1) = sortNoScalarList2(ins,(var,typ,place),(var1,typ1,place1),var_lst);
      then
        (var_lst1,ins1);
  end matchcontinue;
end sortNoScalarList1;

protected function sortNoScalarList2
"function: sortNoScalarList2
  author: Frenkel TUD
  Helper function for sortNoScalarList
  Takes a list of unsortet noScalarVars
  and returns a sorte list"
  input Boolean ininsert;
  input tuple<BackendDAE.Var,Integer,Integer>  invar;
  input tuple<BackendDAE.Var,Integer,Integer>  invar1;
  input list< tuple<BackendDAE.Var,Integer,Integer> > inlist;
  output list< tuple<BackendDAE.Var,Integer,Integer> > outlist;
  output Boolean outinsert;
algorithm
  (outlist,outinsert):=
  matchcontinue (ininsert,invar,invar1,inlist)
    local
      list< tuple<BackendDAE.Var,Integer,Integer> > var_lst,var_lst1,var_lst2,out_lst;
      BackendDAE.Var var,var1;
      Integer typ,typ1,place,place1;
      Boolean ins;
    case (false,(var,typ,place),(var1,typ1,place1),var_lst)
      equation
        ins = comparingNonScalars(var,var1);
        var_lst1 = Util.if_(ins,{(var1,typ1,place1),(var,typ,place)},{(var1,typ1,place1)});
        var_lst2 = listAppend(var_lst1,var_lst);
      then
        (var_lst2,ins);
    case (true,(var,typ,place),(var1,typ1,place1),var_lst)
      equation
        var_lst1 = listAppend({(var1,typ1,place1)},var_lst);
      then
        (var_lst1,true);
  end matchcontinue;
end sortNoScalarList2;

protected function comparingNonScalars
"function: comparingNonScalars
  author: Frenkel TUD
  Helper function for sortNoScalarList2
  Takes two NonScalars an returns
  it in right order
  Example1:  A[2,2],A[1,1] -> {A[1,1],A[2,2]}
  Example2:  A[2,2],B[1,1] -> {A[2,2],B[1,1]}"
  input BackendDAE.Var invar1;
  input BackendDAE.Var invar2;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (invar1,invar2)
    local
      DAE.Ident origName1,origName2;
      DAE.ComponentRef varName1, varName2,c1,c2;
      list<DAE.Subscript> arryDim, arryDim1;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
      Boolean out_val;
    case (BackendDAE.VAR(varName = varName1,arryDim = arryDim),BackendDAE.VAR(varName = varName2,arryDim = arryDim1))
      equation
        c1 = ComponentReference.crefStripLastSubs(varName1);
        c2 = ComponentReference.crefStripLastSubs(varName2);
        true = ComponentReference.crefEqualNoStringCompare(c1, c2); 
        subscriptLst = ComponentReference.crefLastSubs(varName1);
        subscriptLst1 = ComponentReference.crefLastSubs(varName2);
        out_val = comparingNonScalars1(subscriptLst,subscriptLst1,arryDim,arryDim1);
      then
        out_val;        
    case (_,_) then false;
  end matchcontinue;
end comparingNonScalars;

protected function comparingNonScalars1
"function: comparingNonScalars1
  author: Frenkel TUD
  Helper function for comparingNonScalars.
  Check if a element of a non scalar has his place
  before or after another element in a one
  dimensional array."
  input list<DAE.Subscript> inlist;
  input list<DAE.Subscript> inlist1;
  input list<DAE.Subscript> inarryDim;
  input list<DAE.Subscript> inarryDim1;
  output Boolean outval;
algorithm
  outval:=
  matchcontinue (inlist, inlist1, inarryDim, inarryDim1)
    local
      list<DAE.Subscript> arryDim, arryDim1;
      list<DAE.Subscript> subscriptLst, subscriptLst1;
      list<Integer> dim_lst,dim_lst1,dim_lst_1,dim_lst1_1;
      list<Integer> index,index1;
      Integer val1,val2;
    case (subscriptLst,subscriptLst1,arryDim,arryDim1)
      equation
        dim_lst = getArrayDim(arryDim);
        dim_lst1 = getArrayDim(arryDim1);
        index = getArrayDim(subscriptLst);
        index1 = getArrayDim(subscriptLst1);
        dim_lst_1 = Util.listStripFirst(dim_lst);
        dim_lst1_1 = Util.listStripFirst(dim_lst1);
        val1 = calcPlace(index,dim_lst_1);
        val2 = calcPlace(index1,dim_lst1_1);
        (val1 > val2) = true;
      then
       true;
    case (_,_,_,_) then false;
  end matchcontinue;
end comparingNonScalars1;

protected function calcPlace
"function: calcPlace
  author: Frenkel TUD
  Helper function for comparingNonScalars1.
  Calculate based on the dimensions and the
  indexes the place of the element in a one
  dimensional array."
  input list<Integer> inindex;
  input list<Integer> dimlist;
  output Integer value;
algorithm
  value:=
  matchcontinue (inindex,dimlist)
    local
      list<Integer> index_lst,dim_lst;
      Integer value,value1,index,dim;
    case ({},{}) then 0;
    case (index::{},_) then index;
    case (index::index_lst,dim::dim_lst)
      equation
        value = calcPlace(index_lst,dim_lst);
        value1 = value + (index*dim);
      then
        value1;
     case (_,_)
      equation
        print("-calcPlace failed\n");
      then
        fail();
  end matchcontinue;
end calcPlace;

protected function getArrayDim
"function: getArrayDim
  author: Frenkel TUD
  Helper function for comparingNonScalars1.
  Return the dimension of an array in a list."
  input list<DAE.Subscript> inarryDim;
  output list<Integer> dimlist;
algorithm
  dimlist:=
  matchcontinue (inarryDim)
    local
      list<DAE.Subscript> arryDim_lst,rest;
      DAE.Subscript arryDim;
      list<Integer> dim_lst,dim_lst1;
      Integer dim;
    case {} then {};
    case ((arryDim as DAE.INDEX(DAE.ICONST(dim)))::rest)
      equation
        dim_lst = getArrayDim(rest);
        dim_lst1 = dim::dim_lst;
      then
        dim_lst1;       
  end matchcontinue;
end getArrayDim;

protected function calculateIndexes2
"function: calculateIndexes2
  author: PA
  Helper function to calculateIndexes"
  input list< tuple<BackendDAE.Var,Integer,Integer> > inVarLst1;
  input Integer inInteger2; //X
  input Integer inInteger3; //xd
  input Integer inInteger4; //y
  input Integer inInteger5; //p
  input Integer inInteger6; //dummy
  input Integer inInteger7; //ext

  input Integer inInteger8; //X_str
  input Integer inInteger9; //xd_str
  input Integer inInteger10; //y_str
  input Integer inInteger11; //p_str
  input Integer inInteger12; //dummy_str

  output list<tuple<BackendDAE.Var,Integer,Integer> > outVarLst1;
  output Integer outInteger2;
  output Integer outInteger3;
  output Integer outInteger4;
  output Integer outInteger5;
  output Integer outInteger6;
  output Integer outInteger7;

  output Integer outInteger8; //x_str
  output Integer outInteger9; //xd_str
  output Integer outInteger10; //y_str
  output Integer outInteger11; //p_str
  output Integer outInteger12; //dummy_str
algorithm
  (outVarLst1,outInteger2,outInteger3,outInteger4,outInteger5,outInteger6,outInteger7,outInteger8,outInteger9,outInteger10,outInteger11,outInteger12):=
  matchcontinue (inVarLst1,inInteger2,inInteger3,inInteger4,inInteger5,inInteger6,inInteger7,inInteger8,inInteger9,inInteger10,inInteger11,inInteger12)
    local
      BackendDAE.Value x,xd,y,p,dummy,y_1,x1,xd1,y1,p1,dummy1,x_1,p_1,ext,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType,y_1_strType,x_1_strType,p_1_strType;
      BackendDAE.Value x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1;
      list< tuple<BackendDAE.Var,Integer,Integer> > vars_1,vs;
      DAE.ComponentRef cr,name;
      DAE.VarDirection d;
      BackendDAE.Type tp;
      Option<DAE.Exp> b;
      Option<Values.Value> value;
      list<DAE.Subscript> dim;
      DAE.ElementSource source "origin of equation";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      Integer typ,place;
    
    case ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      then ({},x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.VARIABLE(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.VARIABLE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.VARIABLE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.VARIABLE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        x_1_strType = x_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_1_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.STATE(),d,tp,b,value,dim,x_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.STATE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        x_1 = x + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x_1, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.STATE(),d,tp,b,value,dim,x,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_DER(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1 "Dummy derivatives become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DUMMY_DER(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_DER(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1 "Dummy derivatives become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DUMMY_DER(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_STATE(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1 "Dummy state become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DUMMY_STATE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1 "Dummy state become algebraic variables" ;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DISCRETE(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1_strType = y_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_1_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DISCRETE(),d,tp,b,value,dim,y_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.DISCRETE(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        y_1 = y + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y_1, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.DISCRETE(),d,tp,b,value,dim,y,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.PARAM(),
               varDirection = d,
               varType = tp as BackendDAE.STRING(),
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        p_1_strType = p_strType + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_1_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.PARAM(),d,tp,b,value,dim,p_strType,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.PARAM(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
        p_1 = p + 1;
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p_1, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.PARAM(),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.CONST(),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      equation
         //IS THIS A BUG??
         // THE INDEX FOR const IS SET TO p (=last parameter index)
        (vars_1,x1,xd1,y1,p1,dummy1,ext,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.CONST(),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy1,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType);

    case (((BackendDAE.VAR(varName = cr,
               varKind = BackendDAE.EXTOBJ(path),
               varDirection = d,
               varType = tp,
               bindExp = b,
               bindValue = value,
               arryDim = dim,
               source = source,
               values = dae_var_attr,
               comment = comment,
               flowPrefix = flowPrefix,
               streamPrefix = streamPrefix),typ,place) :: vs),x,xd,y,p,dummy,ext,x_strType,xd_strType,y_strType,p_strType,dummy_strType)
      local Absyn.Path path;
      equation
        ext_1 = ext+1;
        (vars_1,x1,xd1,y1,p1,dummy,ext_1,x_strType1,xd_strType1,y_strType1,p_strType1,dummy_strType1) =
           calculateIndexes2(vs, x, xd, y, p, dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
      then
        (((BackendDAE.VAR(cr,BackendDAE.EXTOBJ(path),d,tp,b,value,dim,p,source,dae_var_attr,comment,flowPrefix,streamPrefix),typ,place) :: vars_1),
          x1,xd1,y1,p1,dummy,ext_1,x_strType,xd_strType,y_strType,p_strType,dummy_strType);
  end matchcontinue;
end calculateIndexes2;

public function getAllExps "function: getAllExps
  author: PA

  This function goes through the BackendDAE.DAELow structure and finds all the
  expressions and returns them in a list
"
  input BackendDAE.DAELow inDAELow;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inDAELow)
    local
      list<DAE.Exp> exps1,exps2,exps3,exps4,exps5,exps6,exps;
      list<DAE.Algorithm> alglst;
      list<list<DAE.Exp>> explist6,explist;
      BackendDAE.Variables vars1,vars2;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algs;
    case (BackendDAE.DAELOW(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,initialEqs = ieqns,arrayEqs = ae,algorithms = algs))
      equation
        exps1 = getAllExpsVars(vars1);
        exps2 = getAllExpsVars(vars2);
        exps3 = getAllExpsEqns(eqns);
        exps4 = getAllExpsEqns(reqns);
        exps5 = getAllExpsEqns(ieqns);
        exps6 = getAllExpsArrayEqns(ae);
        alglst = arrayList(algs);
        explist6 = Util.listMap(alglst, Algorithm.getAllExps);
        explist = listAppend({exps1,exps2,exps3,exps4,exps5,exps6}, explist6);
        exps = Util.listFlatten(explist);
      then
        exps;
  end matchcontinue;
end getAllExps;

protected function getAllExpsArrayEqns "function: getAllExpsArrayEqns
  author: PA

  Returns all expressions in array equations
"
  input array<BackendDAE.MultiDimEquation> arr;
  output list<DAE.Exp> res;
  list<BackendDAE.MultiDimEquation> lst;
  list<list<DAE.Exp>> llst;
algorithm
  lst := arrayList(arr);
  llst := Util.listMap(lst, getAllExpsArrayEqn);
  res := Util.listFlatten(llst);
end getAllExpsArrayEqns;

protected function getAllExpsArrayEqn "function: getAllExpsArrayEqn
  author: PA

  Helper function to get_all_exps_array_eqns
"
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inMultiDimEquation)
    local DAE.Exp e1,e2;
    case (BackendDAE.MULTIDIM_EQUATION(left = e1,right = e2)) then {e1,e2};
  end matchcontinue;
end getAllExpsArrayEqn;

protected function getAllExpsVars "function: getAllExpsVars
  author: PA

  Helper to get_all_exps. Goes through the BackendDAE.Variables type
"
  input BackendDAE.Variables inVariables;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inVariables)
    local
      list<BackendDAE.Var> vars;
      list<DAE.Exp> exps;
      array<list<BackendDAE.CrefIndex>> crefindex;
      array<list<BackendDAE.StringIndex>> oldcrefindex;
      BackendDAE.VariableArray vararray;
      BackendDAE.Value bsize,nvars;
    case BackendDAE.VARIABLES(crefIdxLstArr = crefindex,strIdxLstArr = oldcrefindex,varArr = vararray,bucketSize = bsize,numberOfVars = nvars)
      equation
        vars = BackendDAEUtil.vararrayList(vararray) "We can ignore crefs, they don\'t contain real expressions" ;
        exps = Util.listMap(vars, getAllExpsVar);
        exps = Util.listFlatten(exps);
      then
        exps;
  end matchcontinue;
end getAllExpsVars;

protected function getAllExpsVar "function: getAllExpsVar
  author: PA
  Helper to get_all_exps_vars. Get all exps from a  Var.
  DAE.ET_OTHER is used as type for componentref. Not important here.
  We only use the exp list for finding function calls"
  input BackendDAE.Var inVar;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inVar)
    local
      list<DAE.Exp> e1,e2,e3,exps;
      DAE.ComponentRef cref;
      Option<DAE.Exp> bndexp;
      list<DAE.Subscript> instdims;
    case BackendDAE.VAR(varName = cref,
             bindExp = bndexp,
             arryDim = instdims
             )
      equation
        e1 = Util.optionToList(bndexp);
        e3 = Util.listMap(instdims, getAllExpsSubscript);
        e3 = Util.listFlatten(e3);
        exps = Util.listFlatten({e1,e3,{DAE.CREF(cref,DAE.ET_OTHER())}});
      then
        exps;
  end matchcontinue;
end getAllExpsVar;

protected function getAllExpsSubscript "function: getAllExpsSubscript
  author: PA
  Get all exps from a Subscript"
  input DAE.Subscript inSubscript;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inSubscript)
    local DAE.Exp e;
    case DAE.WHOLEDIM() then {};
    case DAE.SLICE(exp = e) then {e};
    case DAE.INDEX(exp = e) then {e};
  end matchcontinue;
end getAllExpsSubscript;

protected function getAllExpsEqns "function: getAllExpsEqns
  author: PA

  Helper to get_all_exps. Goes through the BackendDAE.EquationArray type
"
  input BackendDAE.EquationArray inEquationArray;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst:=
  matchcontinue (inEquationArray)
    local
      list<BackendDAE.Equation> eqns;
      list<DAE.Exp> exps;
      BackendDAE.EquationArray eqnarray;
    case ((eqnarray as BackendDAE.EQUATION_ARRAY(numberOfElement = _)))
      equation
        eqns = BackendDAEUtil.equationList(eqnarray);
        exps = Util.listMap(eqns, getAllExpsEqn);
        exps = Util.listFlatten(exps);
      then
        exps;
  end matchcontinue;
end getAllExpsEqns;

protected function getAllExpsEqn "function: getAllExpsEqn
  author: PA
  Helper to get_all_exps_eqns. Get all exps from an Equation."
  input BackendDAE.Equation inEquation;
  output list<DAE.Exp> outExpExpLst;
algorithm
  outExpExpLst :=  matchcontinue (inEquation)
    local
      DAE.Exp e1,e2,e;
      list<DAE.Exp> expl,exps;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      BackendDAE.Value ind;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source;

    case BackendDAE.EQUATION(exp = e1,scalar = e2) then {e1,e2};
    case BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl) then expl;
    case BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e)
      equation
        tp = Expression.typeof(e);
      then
        {DAE.CREF(cr,tp),e};
    case BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr,right = e,elsewhenPart=NONE()))
      equation
        tp = Expression.typeof(e);
      then
        {DAE.CREF(cr,tp),e};
    case BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(_,cr,e,SOME(elsePart)),source = source)
      equation
        tp = Expression.typeof(e);
        expl = getAllExpsEqn(BackendDAE.WHEN_EQUATION(elsePart,source));
        exps = listAppend({DAE.CREF(cr,tp),e},expl);
      then
        exps;
    case BackendDAE.ALGORITHM(index = ind,in_ = e1,out = e2)
      local list<DAE.Exp> e1,e2;
      equation
        exps = listAppend(e1, e2);
      then
        exps;
  end matchcontinue;
end getAllExpsEqn;

public function traverseDAELowExps "function: traverseDAELowExps
  author: Frenkel TUD

  This function goes through the BackendDAE.DAELow structure and finds all the
  expressions and performs the function on them in a list 
  an extra argument passed through the function.
"
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;  
  input BackendDAE.DAELow inDAELow;
  input Boolean traverseAlgorithms "true if traverse also algorithms";
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeB;
  end FuncExpType;
algorithm
  outTypeBLst:=
  matchcontinue (inDAELow,traverseAlgorithms,func,inTypeA)
    local
      list<Type_b> exps1,exps2,exps3,exps4,exps5,exps6,exps7,exps;
      list<DAE.Algorithm> alglst;
      BackendDAE.Variables vars1,vars2;
      BackendDAE.EquationArray eqns,reqns,ieqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> algs;
    case (BackendDAE.DAELOW(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,
          initialEqs = ieqns,arrayEqs = ae,algorithms = algs),true,func,inTypeA)
      equation
        exps1 = traverseDAELowExpsVars(vars1,func,inTypeA);
        exps2 = traverseDAELowExpsVars(vars2,func,inTypeA);
        exps3 = traverseDAELowExpsEqns(eqns,func,inTypeA);
        exps4 = traverseDAELowExpsEqns(reqns,func,inTypeA);
        exps5 = traverseDAELowExpsEqns(ieqns,func,inTypeA);
        exps6 = traverseDAELowExpsArrayEqns(ae,func,inTypeA);
        alglst = arrayList(algs);
        exps7 = Util.listMapFlat2(alglst, Algorithm.traverseExps,func,inTypeA);
        exps = Util.listFlatten({exps1,exps2,exps3,exps4,exps5,exps6,exps7});
      then
        exps;
    case (BackendDAE.DAELOW(orderedVars = vars1,knownVars = vars2,orderedEqs = eqns,removedEqs = reqns,
          initialEqs = ieqns,arrayEqs = ae,algorithms = algs),false,func,inTypeA)
      equation
        exps1 = traverseDAELowExpsVars(vars1,func,inTypeA);
        exps2 = traverseDAELowExpsVars(vars2,func,inTypeA);
        exps3 = traverseDAELowExpsEqns(eqns,func,inTypeA);
        exps4 = traverseDAELowExpsEqns(reqns,func,inTypeA);
        exps5 = traverseDAELowExpsEqns(ieqns,func,inTypeA);
        exps6 = traverseDAELowExpsArrayEqns(ae,func,inTypeA);
        exps = Util.listFlatten({exps1,exps2,exps3,exps4,exps5,exps6});
      then
        exps;        
    case (_,_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.traverseDAELowExps failed");
      then
        fail();         
  end matchcontinue;
end traverseDAELowExps;

protected function traverseDAELowExpsVars "function: traverseDAELowExpsVars
  author: Frenkel TUD

  Helper for traverseDAELowExps
"
  input BackendDAE.Variables inVariables;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any; 
algorithm
  outTypeBLst:=
  matchcontinue (inVariables,func,inTypeA)
    local
      list<BackendDAE.Var> vars;
      list<Type_b> talst;
      array<list<BackendDAE.CrefIndex>> crefindex;
      array<list<BackendDAE.StringIndex>> oldcrefindex;
      BackendDAE.VariableArray vararray;
      BackendDAE.Value bsize,nvars;
    case (BackendDAE.VARIABLES(crefIdxLstArr = crefindex,strIdxLstArr = oldcrefindex,varArr = vararray,bucketSize = bsize,numberOfVars = nvars),func,inTypeA)
      equation
        vars = BackendDAEUtil.vararrayList(vararray) "We can ignore crefs, they don\'t contain real expressions" ;
        talst = Util.listMapFlat2(vars, traverseDAELowExpsVar,func,inTypeA);
      then
        talst;
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.traverseDAELowExpsVars failed");
      then
        fail();        
  end matchcontinue;
end traverseDAELowExpsVars;

protected function traverseDAELowExpsVar "function: traverseDAELowExpsVar
  author: Frenkel TUD
  Helper traverseDAELowExpsVar. Get all exps from a  Var.
  DAE.ET_OTHER is used as type for componentref. Not important here.
  We only use the exp list for finding function calls"
  input BackendDAE.Var inVar;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=
  matchcontinue (inVar,func,inTypeA)
    local
      list<DAE.Exp> e1;
      Type_a ta;
      list<Type_b> talst,talst1,talst2,talst3,talst4;
      DAE.ComponentRef cref;
      Option<DAE.Exp> bndexp;
      list<DAE.Subscript> instdims;
    case (BackendDAE.VAR(varName = cref,
             bindExp = bndexp,
             arryDim = instdims
             ),func,inTypeA)
      equation
        e1 = Util.optionToList(bndexp);
        talst = Util.listMapFlat1(e1,func,inTypeA);
        talst1 = Util.listMapFlat2(instdims, traverseDAELowExpsSubscript,func,inTypeA);
        talst2 = listAppend(talst,talst1);
        talst3 = func(DAE.CREF(cref,DAE.ET_OTHER()),inTypeA);
        talst4 = listAppend(talst2,talst3);
      then
        talst4;
    case (_,_,_)
      equation
        Debug.fprintln("failtrace", "- DAELow.traverseDAELowExpsVar failed");
      then
        fail();          
  end matchcontinue;
end traverseDAELowExpsVar;

protected function traverseDAELowExpsSubscript "function: traverseDAELowExpsSubscript
  author: Frenkel TUD
  helper for traverseDAELowExpsSubscript"
  input DAE.Subscript inSubscript;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=
  matchcontinue (inSubscript,func,inTypeA)
    local
      DAE.Exp e;
      list<Type_b> talst;      
    case (DAE.WHOLEDIM(),_,inTypeA) then {};
    case (DAE.SLICE(exp = e),func,inTypeA)
      equation
        talst = func(e,inTypeA);  
      then talst;
    case (DAE.INDEX(exp = e),func,inTypeA)
      equation
        talst = func(e,inTypeA);  
      then talst;
  end matchcontinue;
end traverseDAELowExpsSubscript;

protected function traverseDAELowExpsEqns "function: traverseDAELowExpsEqns
  author: Frenkel TUD

  Helper for traverseDAELowExpsEqns
"
  input BackendDAE.EquationArray inEquationArray;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=
  matchcontinue (inEquationArray,func,inTypeA)
    local
      list<BackendDAE.Equation> eqns;
      list<Type_b> talst;
      BackendDAE.EquationArray eqnarray;
    case ((eqnarray as BackendDAE.EQUATION_ARRAY(numberOfElement = _)),func,inTypeA)
      equation
        eqns = BackendDAEUtil.equationList(eqnarray);
        talst = Util.listMapFlat2(eqns, traverseDAELowExpsEqn,func,inTypeA);
      then
        talst;
  end matchcontinue;
end traverseDAELowExpsEqns;

protected function traverseDAELowExpsEqn "function: traverseDAELowExpsEqn
  author: PA
  Helper for traverseDAELowExpsEqn."
  input BackendDAE.Equation inEquation;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=  matchcontinue (inEquation,func,inTypeA)
    local
      DAE.Exp e1,e2,e;
      list<DAE.Exp> expl,exps;
      DAE.ExpType tp;
      DAE.ComponentRef cr;
      BackendDAE.Value ind;
      BackendDAE.WhenEquation elsePart;
      DAE.ElementSource source;
      list<Type_b> talst,talst1,talst2,talst3,talst4;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2),func,inTypeA)
      equation
        talst = func(e1,inTypeA);
        talst1 = func(e2,inTypeA); 
        talst2 = listAppend(talst,talst1);
      then
        talst2;
    case (BackendDAE.ARRAY_EQUATION(crefOrDerCref = expl),func,inTypeA)
      equation
        talst = Util.listMapFlat1(expl,func,inTypeA);
      then
        talst;
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e),func,inTypeA)
      equation
        tp = Expression.typeof(e);
        talst = func(DAE.CREF(cr,tp),inTypeA);
        talst1 = func(e,inTypeA); 
        talst2 = listAppend(talst,talst1);
      then
        talst2;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(left = cr,right = e,elsewhenPart=NONE())),func,inTypeA)
      equation
        tp = Expression.typeof(e);
        talst = func(DAE.CREF(cr,tp),inTypeA);
        talst1 = func(e,inTypeA); 
        talst2 = listAppend(talst,talst1);
      then
        talst2;
    case (BackendDAE.WHEN_EQUATION(whenEquation = BackendDAE.WHEN_EQ(_,cr,e,SOME(elsePart)),source = source),func,inTypeA)
      equation
        tp = Expression.typeof(e);
        talst = func(DAE.CREF(cr,tp),inTypeA);
        talst1 = func(e,inTypeA); 
        talst2 = listAppend(talst,talst1);  
        talst3 = traverseDAELowExpsEqn(BackendDAE.WHEN_EQUATION(elsePart,source),func,inTypeA);
        talst4 = listAppend(talst2,talst3);  
      then
        talst4;
    case (BackendDAE.ALGORITHM(index = ind,in_ = e1,out = e2),func,inTypeA)
      local list<DAE.Exp> e1,e2;
      equation
        expl = listAppend(e1, e2);
        talst = Util.listMapFlat1(expl,func,inTypeA);
      then
        talst;
    case (BackendDAE.COMPLEX_EQUATION(index = ind, lhs = e1, rhs = e2),func,inTypeA)
      equation
        talst = func(e1, inTypeA);
        talst1 = func(e2, inTypeA);
        talst2 = listAppend(talst, talst1);
      then
        talst2;
  end matchcontinue;
end traverseDAELowExpsEqn;

protected function traverseDAELowExpsArrayEqns "function: traverseDAELowExpsArrayEqns
  author: Frenkel TUD

  helper for traverseDAELowExps
"
  input array<BackendDAE.MultiDimEquation> arr;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
  list<BackendDAE.MultiDimEquation> lst;
algorithm
  lst := arrayList(arr);
  outTypeBLst := Util.listMapFlat2(lst, traverseDAELowExpsArrayEqn,func,inTypeA);
end traverseDAELowExpsArrayEqns;

protected function traverseDAELowExpsArrayEqn "function: traverseDAELowExpsArrayEqn
  author: Frenkel TUD

  Helper function to traverseDAELowExpsArrayEqns
"
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  input FuncExpType func;  
  input Type_a inTypeA;
  output list<Type_b> outTypeBLst;
  partial function FuncExpType
    input DAE.Exp inExp;
    input Type_a inTypeA;
    output list<Type_b> outTypeb;
    replaceable type Type_a subtypeof Any;
    replaceable type Type_b subtypeof Any;
  end FuncExpType;
  replaceable type Type_a subtypeof Any;  
  replaceable type Type_b subtypeof Any;
algorithm
  outTypeBLst:=
  matchcontinue (inMultiDimEquation,func,inTypeA)
    local 
      DAE.Exp e1,e2;
      list<Type_b> talst,talst1,talst2;
    case (BackendDAE.MULTIDIM_EQUATION(left = e1,right = e2),func,inTypeA)
      equation
        talst = func(e1,inTypeA);
        talst1 = func(e2,inTypeA); 
        talst2 = listAppend(talst,talst1);
      then
        talst2;
  end matchcontinue;
end traverseDAELowExpsArrayEqn;

public function makeExpType
"Transforms a BackendDAE.Type to DAE.ExpType
"
  input BackendDAE.Type inType;
  output DAE.ExpType outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
    case BackendDAE.REAL() then DAE.ET_REAL();
    case BackendDAE.INT() then DAE.ET_INT();
    case BackendDAE.BOOL() then DAE.ET_BOOL();
    case BackendDAE.STRING() then DAE.ET_STRING();
    case BackendDAE.ENUMERATION(strLst) then DAE.ET_ENUMERATION(Absyn.IDENT(""),strLst,{});
    case BackendDAE.EXT_OBJECT(_) then DAE.ET_OTHER();
  end matchcontinue;
end makeExpType;

protected function generateDaeType
"Transforms a BackendDAE.Type to DAE.Type
"
  input BackendDAE.Type inType;
  output DAE.Type outType;
algorithm
  outType := matchcontinue(inType)
    local
      list<String> strLst;
      Absyn.Path path;
    case BackendDAE.REAL() then DAE.T_REAL_DEFAULT;
    case BackendDAE.INT() then DAE.T_INTEGER_DEFAULT;
    case BackendDAE.BOOL() then DAE.T_BOOL_DEFAULT;
    case BackendDAE.STRING() then DAE.T_STRING_DEFAULT;
    case BackendDAE.ENUMERATION(strLst) then ((DAE.T_ENUMERATION(NONE(),Absyn.IDENT(""),strLst,{},{}),NONE()));
    case BackendDAE.EXT_OBJECT(path) then ((DAE.T_COMPLEX(ClassInf.EXTERNAL_OBJ(path),{},NONE(),NONE()),NONE()));
  end matchcontinue;
end generateDaeType;

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

protected function transformDelayExpressions
"Helper for processDelayExpressions()"
  input DAE.Exp inExp;
  input Integer inInteger;
  output DAE.Exp outExp;
  output Integer outInteger;
algorithm
  ((outExp, outInteger)) := Expression.traverseExp(inExp, transformDelayExpression, inInteger);
end transformDelayExpressions;

public function processDelayExpressions
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

protected function collectDelayExpressions
"Put expression into a list if it is a call to delay().
Useable as a function parameter for Expression.traverseExpression."
  input tuple<DAE.Exp, list<DAE.Exp>> inTuple;
  output tuple<DAE.Exp, list<DAE.Exp>> outTuple;
algorithm
  outTuple := matchcontinue(inTuple)
    local
      DAE.Exp e;
      list<DAE.Exp> l;
    case ((e as DAE.CALL(path = Absyn.IDENT("delay")), l))
      then ((e, e :: l));
    case ((e, l)) then ((e, l));
  end matchcontinue;
end collectDelayExpressions;

public function findDelaySubExpressions
"Return all subexpressions of inExp that are calls to delay()"
  input DAE.Exp inExp;
  input list<Integer> inDummy "this is a dummy for traverseDAELowExps";
  output list<DAE.Exp> outExps;
algorithm
  ((_, outExps)) := Expression.traverseExp(inExp, collectDelayExpressions, {});
end findDelaySubExpressions;

public function addDivExpErrorMsgtoExp "
Author: Frenkel TUD 2010-02, Adds the error msg to Expression.Div.
"
  input DAE.Exp inExp;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inDlowMode;
  output DAE.Exp outExp;
  output list<DAE.Exp> outDivLst;
algorithm 
  (outExp,outDivLst) := matchcontinue(inExp,inDlowMode)
  case(inExp,inDlowMode as (vars,varlst,dzer))
    local 
      DAE.Exp exp; 
      BackendDAE.DAELow dlow;
      BackendDAE.DivZeroExpReplace dzer;
      list<DAE.Exp> divlst;
      BackendDAE.Variables vars;
      list<BackendDAE.Var> varlst;
    equation
      ((exp,(_,_,_,divlst))) = Expression.traverseExp(inExp, traversingDivExpFinder, (vars,varlst,dzer,{}));
      then
        (exp,divlst);
  end matchcontinue;
end addDivExpErrorMsgtoExp;

protected function traversingDivExpFinder "
Author: Frenkel TUD 2010-02"
  input tuple<DAE.Exp, tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> > inExp;
  output tuple<DAE.Exp, tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> > outExp;
algorithm
outExp := matchcontinue(inExp)
  local
    BackendDAE.Variables vars;
    list<BackendDAE.Var> varlst;
    BackendDAE.DivZeroExpReplace dzer;
    list<DAE.Exp> divLst;
    tuple<BackendDAE.Variables,BackendDAE.DivZeroExpReplace,list<DAE.Exp>> dlowmode;
    DAE.Exp e,e1,e2;
    Expression.Type ty;
    String se;
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2),(vars,varlst,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (vars,varlst,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
/*
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARR(ty),exp2 = e2), dlowmode as (dlow,_)))
    then ((e, dlowmode ));
*/    
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (vars,varlst,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_ARRAY_SCALAR(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION_ARRAY_SCALAR"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,true) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {e1,e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE()), (vars,varlst,dzer,divLst) ));
  case( (e as DAE.BINARY(exp1 = e1, operator = DAE.DIV_SCALAR_ARRAY(ty),exp2 = e2), (vars,varlst,dzer,divLst)))
    equation
      (se,false) = traversingDivExpFinder1(e,e2,(vars,varlst,dzer));
    then ((e, (vars,varlst,dzer,DAE.CALL(Absyn.IDENT("DIVISION_SCALAR_ARRAY"), {DAE.RCONST(1.0),e2,DAE.SCONST(se)}, false, true, ty, DAE.NO_INLINE())::divLst) ));
  case(inExp) then (inExp);
end matchcontinue;
end traversingDivExpFinder;

protected function traversingDivExpFinder1 "
Author: Frenkel TUD 2010-02 
  helper for traversingDivExpFinder"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input tuple<BackendDAE.Variables,list<BackendDAE.Var>,BackendDAE.DivZeroExpReplace> inMode;
  output String outString;
  output Boolean outBool;
algorithm
  (outString,outBool) := matchcontinue(inExp1,inExp2,inMode)
  local
    BackendDAE.Variables vars;
    DAE.Exp e,e2;
    String se;
    list<DAE.ComponentRef> crlst;
    BackendDAE.Variables vars;
    list<BackendDAE.Var> varlst;
    list<Boolean> boollst;
    Boolean bres;
  case( e , e2, (vars,varlst,BackendDAE.ALL()) )
    equation
      /* generade modelica strings */
      se = generadeDivExpErrorMsg(e,e2,vars);
    then (se,false);    
  case( e , e2, (vars,varlst,BackendDAE.ONLY_VARIABLES()) )
    equation
      /* generade modelica strings */
      se = generadeDivExpErrorMsg(e,e2,vars);
      /* check if expression contains variables */
      crlst = Expression.extractCrefsFromExp(e2);
      boollst = Util.listMap1r(crlst,BackendVariable.isVarKnown,varlst);
      bres = Util.boolOrList(boollst);
    then (se,bres);
end matchcontinue;
end traversingDivExpFinder1;

protected  function generadeDivExpErrorMsg "
Author: Frenkel TUD 2010-02. varOrigCref
"
input DAE.Exp inExp;
input DAE.Exp inDivisor;
input BackendDAE.Variables inVars;
output String outString;
protected String se,se2,s,s1;
algorithm
  se := ExpressionDump.printExp2Str(inExp,"\"",SOME((BackendDump.printComponentRefStrDIVISION,inVars)), SOME(BackendDump.printCallFunction2StrDIVISION));
  se2 := ExpressionDump.printExp2Str(inDivisor,"\"",SOME((BackendDump.printComponentRefStrDIVISION,inVars)), SOME(BackendDump.printCallFunction2StrDIVISION));
  s := stringAppend(se," because ");
  s1 := stringAppend(s,se2);
  outString := stringAppend(s1," == 0");
end generadeDivExpErrorMsg;

public function generateCrefsExpFromType "
Author: Frenkel TUD 2010-05"
  input DAE.ExpVar inVar;
  input DAE.Exp inExp;
  output DAE.Exp outCrefExp;
algorithm outCrefExp := matchcontinue(inVar,inExp)
  local
    String name;
    DAE.ExpType tp;
    DAE.ComponentRef cr,cr1;
    DAE.Exp e;
  case (DAE.COMPLEX_VAR(name=name,tp=tp),DAE.CREF(componentRef=cr))
  equation
    cr1 = ComponentReference.crefPrependIdent(cr,name,{},tp);
    e = Expression.makeCrefExp(cr1, tp);
  then
    e;
 end matchcontinue;
end generateCrefsExpFromType;

public function generateextendedRecordEqn "
Author: Frenkel TUD 2010-05"
  input tuple<DAE.Exp,DAE.Exp> inExp;
  input DAE.ElementSource Source;
  input DAE.FunctionTree inFuncs;
  output tuple<list<BackendDAE.Equation>,list<BackendDAE.MultiDimEquation>> outTuplEqnLst;
algorithm 
  outTuplEqnLst := matchcontinue(inExp,Source,inFuncs)
  local
    DAE.Exp e1,e2,e1_1,e2_1,e2_2;
    list<DAE.Exp> e1lst, e2lst;
    DAE.ElementSource source;
    DAE.ComponentRef cr1,cr2;
    list<DAE.ComponentRef> crlst1,crlst2;
    BackendDAE.Equation eqn;
    list<BackendDAE.Equation> eqnlst;
    list<tuple<DAE.Exp,DAE.Exp>> exptplst;
    list<list<DAE.Subscript>> subslst,subslst1;
    Expression.Type tp;
    list<DAE.Dimension> ad;
    list<Integer> ds;
  // array types to array equations  
  case ((e1 as DAE.CREF(componentRef=cr1,ty=DAE.ET_ARRAY(arrayDimensions=ad)),e2),source,inFuncs)
  equation 
    (e1_1,_) = BackendDAEUtil.extendArrExp(e1,SOME(inFuncs));
    (e2_1,_) = BackendDAEUtil.extendArrExp(e2,SOME(inFuncs));
    e2_2 = ExpressionSimplify.simplify(e2_1);
    ds = Util.listMap(ad, Expression.dimensionSize);
  then
    (({},{BackendDAE.MULTIDIM_EQUATION(ds,e1_1,e2_2,source)}));
  // other types  
  case ((e1 as DAE.CREF(componentRef=cr1),e2),source,inFuncs)
  equation 
    tp = Expression.typeof(e1);
    false = DAEUtil.expTypeComplex(tp);
    (e1_1,_) = BackendDAEUtil.extendArrExp(e1,SOME(inFuncs));
    (e2_1,_) = BackendDAEUtil.extendArrExp(e2,SOME(inFuncs));
    e2_2 = ExpressionSimplify.simplify(e2_1);
    eqn = generateEQUATION((e1_1,e2_2),source);
  then
    (({eqn},{}));    
  // complex type
  case ((e1,e2),source,inFuncs)
  equation 
    tp = Expression.typeof(e1);
    true = DAEUtil.expTypeComplex(tp);
  then
    (({BackendDAE.COMPLEX_EQUATION(-1,e1,e2,source)},{}));    
 end matchcontinue;
end generateextendedRecordEqn;

public function arrayDimensionsToRange "
Author: Frenkel TUD 2010-05"
  input list<Option<Integer>> dims;
  output list<list<DAE.Subscript>> outRangelist;
algorithm
  outRangelist := matchcontinue(dims)
  local 
    Integer i;
    list<list<DAE.Subscript>> rangelist;
    list<Integer> range;
    list<DAE.Subscript> subs;
    case({}) then {};
    case(NONE()::dims) equation
      rangelist = arrayDimensionsToRange(dims);
    then {}::rangelist;
    case(SOME(i)::dims) equation
      range = Util.listIntRange(i);
      subs = BackendDAEUtil.rangesToSubscript(range);
      rangelist = arrayDimensionsToRange(dims);
    then subs::rangelist;
  end matchcontinue;
end arrayDimensionsToRange;

public function generateEQUATION "
Author: Frenkel TUD 2010-05"
  input tuple<DAE.Exp,DAE.Exp> inTpl;
  input DAE.ElementSource Source;
  output BackendDAE.Equation outEqn;
algorithm outEqn := matchcontinue(inTpl,Source)
  local
    DAE.Exp e1,e2;
    DAE.ElementSource source;
  case ((e1,e2),source) then BackendDAE.EQUATION(e1,e2,source);
 end matchcontinue;
end generateEQUATION;

public function crefPrefixDer
  "Appends $DER to a cref, so a => $DER.a"
  input DAE.ComponentRef inCref;
  output DAE.ComponentRef outCref;
algorithm
  outCref := ComponentReference.makeCrefQual(derivativeNamePrefix,DAE.ET_REAL(),{}, inCref);
end crefPrefixDer;

public function equationSource "Retrieve the source from a BackendDAE.DAELow equation"
  input BackendDAE.Equation eq;
  output DAE.ElementSource source;
algorithm
  source := matchcontinue eq
    case BackendDAE.EQUATION(source=source) then source;
    case BackendDAE.ARRAY_EQUATION(source=source) then source;
    case BackendDAE.SOLVED_EQUATION(source=source) then source;
    case BackendDAE.RESIDUAL_EQUATION(source=source) then source;
    case BackendDAE.WHEN_EQUATION(source=source) then source;
    case BackendDAE.ALGORITHM(source=source) then source;
    case BackendDAE.COMPLEX_EQUATION(source=source) then source;
  end matchcontinue;
end equationSource;

public function equationInfo "Retrieve the line number information from a BackendDAE.DAELow equation"
  input BackendDAE.Equation eq;
  output Absyn.Info info;
algorithm
  info := DAEUtil.getElementSourceFileInfo(equationSource(eq));
end equationInfo;


public function generateLinearMatrix
  // function: generateLinearMatrix
  // author: wbraun
  input BackendDAE.DAELow inDAELow;
  input DAE.FunctionTree functionTree;
  input list<DAE.ComponentRef> inComRef1; // eqnvars
  input list<DAE.ComponentRef> inComRef2; // vars to differentiate 
  input list<BackendDAE.Var> inAllVar;
  output BackendDAE.DAELow outJacobian;
  output array<Integer> outV1;
  output array<Integer> outV2;
  output list<list<Integer>> outComps1;
algorithm 
  (outJacobian,outV1,outV2,outComps1) :=
    matchcontinue (inDAELow,functionTree,inComRef1,inComRef2,inAllVar)
    local
      DAE.DAElist dae;
      BackendDAE.DAELow dlow;
      
      list<DAE.ComponentRef> eqvars,diffvars;
      list<BackendDAE.Var> varlst;
      array<Integer> v1,v2,v4,v31;
      list<Integer> v3;
      list<list<Integer>> comps1,comps2;
      list<BackendDAE.Var> derivedVariables;
      list<BackendDAE.Var> derivedVars;
      BackendDAE.BinTree jacElements;
      list<tuple<String,Integer>> varTuple;
      array<list<Integer>> m,mT;
      
      BackendDAE.Variables v,kv,exv;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray e,re,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ev;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.Equation> e_lst,re_lst,ie_lst;
      list<DAE.Algorithm> algs;
      list<BackendDAE.MultiDimEquation> ae_lst;
      
      list<String> s;
      String str;
      
      case(dlow as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),_,{},_,_)
        equation
      v = BackendDAEUtil.listVar({});    
      then (BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),listArray({}),listArray({}),{});
      case(dlow as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),_,_,{},_)
        equation
      v = BackendDAEUtil.listVar({});    
      then (BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),listArray({}),listArray({}),{});
      case(dlow as BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc),functionTree,eqvars,diffvars,varlst)
        equation

        // prepare index for Matrix and variables for simpleEquations
        derivedVariables = BackendDAEUtil.varList(v);
        (varTuple) = determineIndices(eqvars, diffvars, 0, varlst);
        BackendDump.printTuple(varTuple);
        jacElements = BackendDAE.emptyBintree;
        (derivedVariables,jacElements) = changeIndices(derivedVariables, varTuple, jacElements);
        v = BackendDAEUtil.listVar(derivedVariables);
        
        // Remove simple Equtaion and 
        e_lst = BackendDAEUtil.equationList(e);
        re_lst = BackendDAEUtil.equationList(re);
        ie_lst = BackendDAEUtil.equationList(ie);
        ae_lst = arrayList(ae);
        algs = arrayList(al);
        (v,kv,e_lst,re_lst,ie_lst,ae_lst,algs,av) = BackendDAEOptimize.removeSimpleEquations(v,kv, e_lst, re_lst, ie_lst, ae_lst, algs, jacElements); 
        e = BackendDAEUtil.listEquation(e_lst);
        re = BackendDAEUtil.listEquation(re_lst);
        ie = BackendDAEUtil.listEquation(ie_lst);
        ae = listArray(ae_lst);
        al = listArray(algs);
        dlow = BackendDAE.DAELOW(v,kv,exv,av,e,re,ie,ae,al,ev,eoc);
     
        // figure out new matching and the strong components  
        m = BackendDAEUtil.incidenceMatrix(dlow);
        mT = BackendDAEUtil.transposeMatrix(m);
        (v1,v2,dlow,m,mT) = matchingAlgorithm(dlow, m, mT, (BackendDAE.NO_INDEX_REDUCTION(), BackendDAE.EXACT(), BackendDAE.KEEP_SIMPLE_EQN()),functionTree);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrix, m);
        Debug.fcall("jacdump2", BackendDump.dumpIncidenceMatrixT, mT);
        Debug.fcall("jacdump2", BackendDump.dump, dlow);
        Debug.fcall("jacdump2", BackendDump.dumpMatching, v1);
        (comps1) = strongComponents(m, mT, v1, v2);
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);

        // figure out wich comps are needed to evaluate all derivedVariables  
        derivedVariables = BackendDAEUtil.varList(v);
        (derivedVars,_) = Util.listSplitOnTrue(derivedVariables,checkIndex);
        v3 = getVarIndex(derivedVars,derivedVariables);
        v31 = Util.arraySelect(v1,v3);
        v3 = arrayList(v31);
        s = Util.listMap(v3,intString);
        str = Util.stringDelimitList(s,",");
        Debug.fcall("markblocks",print,"Vars Indecies : " +& str +& "\n");
        v4 = fill(0,listLength(comps1));
        v4 = MarkArray(v3,comps1,v4);
        (comps1,_) = splitBlocks2(comps1,v4,1);
        
        Debug.fcall("jacdump2", BackendDump.dumpComponents, comps1);
        
        then (dlow,v1,v2,comps1);
    case(_, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.generateLinearMatrix failed"});
    then fail();          
   end matchcontinue;
end generateLinearMatrix;         

protected function splitBlocks2 
//function: splitBlocks2
//author: wbraun 
  input list<list<Integer>> inIntegerLstLst;
  input Integer[:] inIntegerArray;
  input Integer inPos;
  output list<list<Integer>> outIntegerLstLst1;
  output list<list<Integer>> outIntegerLstLst2;
algorithm
  (outIntegerLstLst1,outIntegerLstLst2):=
  matchcontinue (inIntegerLstLst,inIntegerArray,inPos)
    local
      list<list<BackendDAE.Value>> states,output_,blocks;
      list<BackendDAE.Value> block_;
      array<BackendDAE.Value> arr;
      BackendDAE.Value i;
    case ({},_,_) then ({},{});
    case ((block_ :: blocks),arr,i)
      equation
        1 = arr[i];
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        ((block_ :: states),output_);
    case ((block_ :: blocks),arr,i)
      equation
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        (states,(block_ :: output_));
    case ((block_ :: blocks),arr,i)
      equation
        (states,output_) = splitBlocks2(blocks, arr,i+1);
      then
        (states,(block_ :: output_));        
  end matchcontinue;
end splitBlocks2;

protected function MarkArray
  // function : MarkArray
  // author : wbraun
  input list<Integer> inVars1;
  input list<list<Integer>> inVars2;
  input Integer[:] inInt;
  output Integer[:] outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1,inVars2,inInt)
    local
      list<Integer> rest;
      list<list<Integer>> vars;
      Integer var;
      list<Integer> intlst,ilst2;
      Integer i;
      Integer[:] arr,arr1;
      list<String> s,s1;
      String str;
    case({},_,arr) then arr;      
    case(var::rest,vars,arr)
      equation
        i = Util.listlistPosition(var,vars);
        Debug.fcall("markblocks",print,"Var " +& intString(var) +& " at pos : " +& intString(i) +& "\n");
        arr1 = fill(1,i+1);
        arr = Util.arrayCopy(arr1,arr);
        arr = MarkArray(rest,vars,arr);
        s = Util.listMap(arrayList(arr),intString);
        str = Util.stringAppendList(s);
        Debug.fcall("markblocks",print,str);
        Debug.fcall("markblocks",print,"\n");
      then arr;        
     case(_,_,_)
       equation
        Debug.fcall("failtrace",print,"DAELow.MarkArray failed\n");
       then fail();
  end matchcontinue;
end MarkArray; 

protected function getVarIndex
  // function : getVarIndex
  // author : wbraun
  input list<BackendDAE.Var> inVars1;
  input list<BackendDAE.Var> inVars2;
  output list<Integer> outJacobian;
algorithm
  outJacobian := matchcontinue(inVars1, inVars2)
    local
      list<BackendDAE.Var> vars,rest;
      BackendDAE.Var var;
      list<Integer> intlst;
      Integer i;
    case({},_) then {};      
    case(var::rest,vars)
      equation
        i = Util.listPosition(var,vars)+1;
        intlst = getVarIndex(rest,vars);
      then (i::intlst);
    case(var::rest,_)
      equation
        Debug.fcall("failtrace",print,"DAELow.BackendVariable.getVarIndex failed\n");
      then fail();
  end matchcontinue;
end getVarIndex;  

protected function checkIndex "function: checkIndex
  author: wbraun

  check if the index is greater 0
"
  input BackendDAE.Var inVar;
  output Boolean outBoolean;
algorithm
  outBoolean:=
  matchcontinue (inVar)
    local BackendDAE.Value i;
    case (BackendDAE.VAR(index = i)) then i >= 0;
  end matchcontinue;
end checkIndex;

public function generateSymbolicJacobian
  // function: generateSymbolicJacobian
  // author: lochel
  input BackendDAE.DAELow inDAELow;
  input DAE.FunctionTree functions;
  input list<DAE.ComponentRef> inVars;
  input list<BackendDAE.Var> stateVars;
  input list<BackendDAE.Var> inputVars;
  input list<BackendDAE.Var> paramVars;
  output BackendDAE.DAELow outJacobian;
algorithm
  outJacobian := matchcontinue(inDAELow, functions, inVars, stateVars, inputVars, paramVars)
    local
      BackendDAE.DAELow daeLow;
      DAE.DAElist daeList;
      list<DAE.ComponentRef> vars;
      BackendDAE.DAELow jacobian;
      
      // DAELOW
      BackendDAE.Variables orderedVars, jacOrderedVars;
      BackendDAE.Variables knownVars, jacKnownVars;
      BackendDAE.Variables externalObjects, jacExternalObjects;
      BackendDAE.AliasVariables aliasVars, jacAliasVars;
      BackendDAE.EquationArray orderedEqs, jacOrderedEqs;
      BackendDAE.EquationArray removedEqs, jacRemovedEqs;
      BackendDAE.EquationArray initialEqs, jacInitialEqs;
      array<BackendDAE.MultiDimEquation> arrayEqs, jacArrayEqs;
      array<DAE.Algorithm> algorithms, jacAlgorithms;
      BackendDAE.EventInfo eventInfo, jacEventInfo;
      BackendDAE.ExternalObjectClasses extObjClasses, jacExtObjClasses;
      // end DAELOW
      
      list<BackendDAE.Var> allVars, inputVars, paramVars, stateVars, derivedVariables;
      list<BackendDAE.Equation> solvedEquations, derivedEquations, derivedEquations2;
      list<DAE.Algorithm> derivedAlgorithms;
      list<tuple<Integer, DAE.ComponentRef>> derivedAlgorithmsLookUp;
      
    case(_, _, {}, _, _,_) equation
      jacOrderedVars = BackendDAEUtil.emptyVars();
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation({});
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray({});
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAELOW(jacOrderedVars, jacKnownVars, jacExternalObjects, jacAliasVars, jacOrderedEqs, jacRemovedEqs, jacInitialEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses);
    then jacobian;
      
    case(daeLow as BackendDAE.DAELOW(orderedVars=orderedVars, knownVars=knownVars, externalObjects=externalObjects, aliasVars=aliasVars, orderedEqs=orderedEqs, removedEqs=removedEqs, initialEqs=initialEqs, arrayEqs=arrayEqs, algorithms=algorithms, eventInfo=eventInfo, extObjClasses=extObjClasses), functions, vars, stateVars, inputVars, paramVars) equation
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump:    input +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, daeLow);
      Debug.fcall("jacdump", print, "##################### daeLow-dump:    input #####################\n\n");
      
      allVars = listAppend(listAppend(stateVars, inputVars), paramVars);
      
      derivedVariables = generateJacobianVars(BackendDAEUtil.varList(orderedVars), vars, stateVars);
      (derivedAlgorithms, derivedAlgorithmsLookUp) = deriveAllAlg(arrayList(algorithms), vars, functions, 0);
      derivedEquations = deriveAll(BackendDAEUtil.equationList(orderedEqs), vars, functions, inputVars, paramVars, stateVars, derivedAlgorithmsLookUp);
      
      jacOrderedVars = BackendDAEUtil.listVar(derivedVariables);
      jacKnownVars = BackendDAEUtil.emptyVars();
      jacExternalObjects = BackendDAEUtil.emptyVars();
      jacAliasVars =  BackendDAEUtil.emptyAliasVariables();
      jacOrderedEqs = BackendDAEUtil.listEquation(derivedEquations);
      jacRemovedEqs = BackendDAEUtil.listEquation({});
      jacInitialEqs = BackendDAEUtil.listEquation({});
      jacArrayEqs = listArray({});
      jacAlgorithms = listArray(derivedAlgorithms);
      jacEventInfo = BackendDAE.EVENT_INFO({},{});
      jacExtObjClasses = {};
      
      jacobian = BackendDAE.DAELOW(jacOrderedVars, jacKnownVars, jacExternalObjects, jacAliasVars, jacOrderedEqs, jacRemovedEqs, jacInitialEqs, jacArrayEqs, jacAlgorithms, jacEventInfo, jacExtObjClasses);
      
      Debug.fcall("jacdump", print, "\n+++++++++++++++++++++ daeLow-dump: jacobian +++++++++++++++++++++\n");
      Debug.fcall("jacdump", BackendDump.dump, jacobian);
      Debug.fcall("jacdump", print, "##################### daeLow-dump: jacobian #####################\n");
    then jacobian;  
      
    case(_, _, _, _, _,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.generateSymbolicJacobian failed"});
    then fail();
  end matchcontinue;
end generateSymbolicJacobian;

protected function deriveAllAlg
  // function: deriveAllAlg
  // author: lochel
  input list<DAE.Algorithm> inAlgorithms;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input Integer inAlgIndex; // 0
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := matchcontinue(inAlgorithms, inVars, inFunctions, inAlgIndex)
    case({}, _, _, _)
    then ({}, {});
      
    case(currAlg::restAlgs, vars, functions, algIndex) local
      DAE.Algorithm currAlg;
      list<DAE.Algorithm> restAlgs;
      list<DAE.ComponentRef> vars;
      DAE.FunctionTree functions;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    equation
      (rAlgs1, rLookUp1) = deriveOneAlg(currAlg, vars, functions, algIndex);
      (rAlgs2, rLookUp2) = deriveAllAlg(restAlgs, vars, functions, algIndex+1);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end matchcontinue;
end deriveAllAlg;

protected function deriveOneAlg
  // function: deriveOneAlg
  // author: lochel
  input DAE.Algorithm inAlgorithm;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input Integer inAlgIndex;
  output list<DAE.Algorithm> outDerivedAlgorithms;
  output list<tuple<Integer, DAE.ComponentRef>> outDerivedAlgorithmsLookUp;
algorithm
  (outDerivedAlgorithms, outDerivedAlgorithmsLookUp) := matchcontinue(inAlgorithm, inVars, inFunctions, inAlgIndex)
    case(_, {}, _, _)
    then ({}, {});
      
    case(currAlg as DAE.ALGORITHM_STMTS(statementLst=statementLst), currVar::restVars, functions, algIndex) local
      DAE.Algorithm currAlg;
      list<DAE.Statement> statementLst, derivedStatementLst;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      DAE.FunctionTree functions;
      Integer algIndex;
      list<DAE.Algorithm> rAlgs1, rAlgs2;
      list<tuple<Integer, DAE.ComponentRef>> rLookUp1, rLookUp2;
    equation
      derivedStatementLst = differentiateAlgorithmStatements(statementLst, currVar, functions);
      rAlgs1 = {DAE.ALGORITHM_STMTS(derivedStatementLst)};
      rLookUp1 = {(algIndex, currVar)};
      (rAlgs2, rLookUp2) = deriveOneAlg(currAlg, restVars, functions, algIndex);
      rAlgs1 = listAppend(rAlgs1, rAlgs2);
      rLookUp1 = listAppend(rLookUp1, rLookUp2);
    then (rAlgs1, rLookUp1);
  end matchcontinue;
end deriveOneAlg;

protected function generateJacobianVars
  // function: generateJacobianVars
  // author: lochel
  input list<BackendDAE.Var> inVars1;
  input list<DAE.ComponentRef> inVars2;
  input list<BackendDAE.Var> inStateVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVars1, inVars2, inStateVars)
  local
    BackendDAE.Var currVar;
    list<BackendDAE.Var> restVar, r1, r2, r, stateVars;
    list<DAE.ComponentRef> vars2;
    
    case({}, _, _)
    then {}; 
      
    case(currVar::restVar, vars2, stateVars) equation
      r1 = generateJacobianVars2(currVar, vars2, stateVars);
      r2 = generateJacobianVars(restVar, vars2, stateVars);
      r = listAppend(r1, r2);
    then r;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.generateJacobianVars failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars;

protected function generateJacobianVars2
  // function: generateJacobianVars2
  // author: lochel
  input BackendDAE.Var inVar1;
  input list<DAE.ComponentRef> inVars2;
  input list<BackendDAE.Var> inStateVars;
  output list<BackendDAE.Var> outVars;
algorithm
  outVars := matchcontinue(inVar1, inVars2, inStateVars)
  local
    BackendDAE.Var var, r1;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<DAE.ComponentRef> restVar;
    list<BackendDAE.Var> r2;
    list<BackendDAE.Var> stateVars;
    
    case(_, {}, _)
    then {};
    
    case(var as BackendDAE.VAR(varName=cref), currVar::restVar, stateVars) equation
      derivedCref = differentiateVarWithRespectToX(cref, currVar, stateVars);
      r1 = BackendDAE.VAR(derivedCref, BackendDAE.VARIABLE(), DAE.BIDIR(), BackendDAE.REAL(), NONE(), NONE(), {}, -1,  DAE.emptyElementSource, NONE(), NONE(), DAE.FLOW(), DAE.STREAM());
      r2 = generateJacobianVars2(var, restVar, stateVars);
    then r1::r2;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.generateJacobianVars2 failed"});
    then fail();
  end matchcontinue;
end generateJacobianVars2;

protected function deriveAll
  // function: deriveAll
  // author: lochel
  input list<BackendDAE.Equation> inEquations;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquations, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<BackendDAE.Equation> restEquations;
      DAE.FunctionTree functions;
      list<DAE.ComponentRef> vars;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
    case({}, _, _, _, _, _, _) then {};
      
    case(currEquation::restEquations, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp) equation
      Debug.fcall("jacdumptime", BackendDump.dumpEqns, {currEquation});
      currDerivedEquations = deriveOne(currEquation, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      restDerivedEquations = deriveAll(restEquations, vars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.deriveAll failed"});
    then fail();
  end matchcontinue;
end deriveAll;

protected function deriveOne
  // function: deriveOne
  // author: lochel
  input BackendDAE.Equation inEquation;
  input list<DAE.ComponentRef> inVars;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVars, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<DAE.Algorithm> algorithms;
      DAE.FunctionTree functions;
      DAE.ComponentRef currVar;
      list<DAE.ComponentRef> restVars;
      Integer algNum;
      
      list<BackendDAE.Var> currDerivedVariables, restDerivedVariables, derivedVariables;
      list<BackendDAE.Equation> currDerivedEquations, restDerivedEquations, derivedEquations;
      list<DAE.Algorithm> currDerivedAlgorithms, restDerivedAlgorithms, derivedAlgorithms;
      
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer i; 
    case(_, {}, _, _, _, _, _) then {};
      
    case(currEquation, currVar::restVars, functions, inputVars, paramVars, stateVars, algorithmsLookUp) equation
      currDerivedEquations = derive(currEquation, currVar, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      restDerivedEquations = deriveOne(currEquation, restVars, functions, inputVars, paramVars, stateVars, algorithmsLookUp);
      
      derivedEquations = listAppend(currDerivedEquations, restDerivedEquations);
    then derivedEquations;
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.deriveOne failed"});
    then fail();
  end matchcontinue;
end deriveOne;

protected function derive
  // function: derive
  // author: lochel
  input BackendDAE.Equation inEquation;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  input list<tuple<Integer, DAE.ComponentRef>> inAlgorithmsLookUp;
  output list<BackendDAE.Equation> outDerivedEquations;
algorithm
  outDerivedEquations := matchcontinue(inEquation, inVar, inFunctions, inInputVars, inParamVars, inStateVars, inAlgorithmsLookUp)
    local
      BackendDAE.Equation currEquation;
      list<DAE.Algorithm> algorithms;
      DAE.FunctionTree functions;
      DAE.ComponentRef var, cref, cref_;
      
      BackendDAE.Var currDerivedVariable;
      BackendDAE.Equation currDerivedEquation;
      DAE.Algorithm currDerivedAlgorithm;
      
      DAE.Exp lhs, rhs, lhs_, rhs_, exp, exp_;
      DAE.ElementSource source;
      
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      
    case(currEquation as BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      lhs_ = differentiateWithRespectToX(lhs, var, functions, inputVars, paramVars, stateVars);
      rhs_ = differentiateWithRespectToX(rhs, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.EQUATION(lhs_, rhs_, source)};
      
    case(currEquation as BackendDAE.ARRAY_EQUATION(_, _, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.derive failed: ARRAY_EQUATION-case"});
    then fail();
      
    case(currEquation as BackendDAE.SOLVED_EQUATION(componentRef=cref, exp=exp, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      cref_ = differentiateVarWithRespectToX(cref, var, stateVars);
      exp_ = differentiateWithRespectToX(exp, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.SOLVED_EQUATION(cref_, exp_, source)};
      
    case(currEquation as BackendDAE.RESIDUAL_EQUATION(exp=exp, source=source), var, functions, inputVars, paramVars, stateVars, _) equation
      exp_ = differentiateWithRespectToX(exp, var, functions, inputVars, paramVars, stateVars);
    then {BackendDAE.RESIDUAL_EQUATION(exp_, source)};
      
    case(currEquation as BackendDAE.ALGORITHM(index=index, in_=in_, out=out, source=source), var, functions, inputVars, paramVars, stateVars, algorithmsLookUp) local
      Integer index;
      list<DAE.Exp> in_, derivedIn_;
      list<DAE.Exp> out, derivedOut;
      DAE.ElementSource source;
      DAE.Algorithm singleAlgorithm, derivedAlgorithm;
      list<tuple<Integer, DAE.ComponentRef>> algorithmsLookUp;
      Integer newAlgIndex;
    equation
      derivedIn_ = Util.listMap5(in_, differentiateWithRespectToX, var, functions, {}, {}, {});
      derivedIn_ = listAppend(in_, derivedIn_);
      derivedOut = Util.listMap5(out, differentiateWithRespectToX, var, functions, {}, {}, {});
        
      newAlgIndex = Util.listPosition((index, var), algorithmsLookUp);
    then {BackendDAE.ALGORITHM(newAlgIndex, derivedIn_, derivedOut, source)};
        
    case(currEquation as BackendDAE.WHEN_EQUATION(_, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Debug.fcall("jacdump",print,"DAELow.derive: WHEN_EQUATION has been removed");
    then {};
      
    case(currEquation as BackendDAE.COMPLEX_EQUATION(_, _, _, _), var, functions, inputVars, paramVars, stateVars, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.derive failed: COMPLEX_EQUATION-case"});
    then fail();
      
    case(_, _, _, _, _, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.derive failed"});
    then fail();
  end matchcontinue;
end derive;

protected function differentiateVarWithRespectToX
  // function: differentiateVarWithRespectToX
  // author: lochel
  input DAE.ComponentRef inCref;
  input DAE.ComponentRef inX;
  input list<BackendDAE.Var> inStateVars;
  output DAE.ComponentRef outCref;
algorithm
  outCref := matchcontinue(inCref, inX, inStateVars)
    local
      DAE.ComponentRef cref, x;
      String id;
      DAE.ExpType idType;
      list<DAE.Subscript> sLst;
      list<BackendDAE.Var> stateVars;
      BackendDAE.Var v1;
    
    // d(state)/d(x)
    case(cref, x, stateVars) equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      true = BackendVariable.isStateVar(v1);
      cref = crefPrefixDer(cref);
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$pL");
      id = Util.stringReplaceChar(id, "]", "$pR");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
    
    // d(no state)/d(x)
    case(cref, x, _) equation
      id = ComponentReference.printComponentRefStr(cref) +& BackendDAE.partialDerivativeNamePrefix +& ComponentReference.printComponentRefStr(x);
      id = Util.stringReplaceChar(id, ".", "$P");
      id = Util.stringReplaceChar(id, "[", "$pL");
      id = Util.stringReplaceChar(id, "]", "$pR");
    then ComponentReference.makeCrefIdent(id, DAE.ET_REAL(), {});
      
    case(cref, _, _) local
      String str; 
      equation
        str = "DAELow.differentiateVarWithRespectToX failed: " +&  ComponentReference.printComponentRefStr(cref);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then fail();
  end matchcontinue;
end differentiateVarWithRespectToX;

protected function differentiateWithRespectToX
  // function: differentiateWithRespectToX
  // author: lochel
  
  input DAE.Exp inExp;
  input DAE.ComponentRef inX;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(inExp, inX, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x, cref, cref_;
      DAE.FunctionTree functions;
      DAE.Exp e1, e1_, e2, e2_, e;
      DAE.ExpType et;
      DAE.Operator op;
      
      
      list<DAE.ComponentRef> diff_crefs;
      Absyn.Path fname;
      
      list<DAE.Exp> expList1, expList2;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
      
    case(DAE.ICONST(_), _, _, _, _, _)
    then DAE.ICONST(0);
      
    case(DAE.RCONST(_), _, _, _, _, _)
    then DAE.RCONST(0.0);
      
    case (DAE.CAST(ty=et, exp=e1), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.CAST(et, e1_);
      
    // d(x)/d(x)
    case(DAE.CREF(componentRef=cref), x, functions, inputVars, paramVars, stateVars) equation
      true = ComponentReference.crefEqual(cref, x);
    then DAE.RCONST(1.0);
      
    // d(time)/d(x)
    case(DAE.CREF(componentRef=(cref as DAE.CREF_IDENT(ident = "time",subscriptLst = {}))), x, functions, inputVars, paramVars, stateVars)
    then DAE.RCONST(0.0);
    
    // d(state1)/d(state2) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1, v2; equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(stateVars));
    then DAE.RCONST(0.0);
      
    // d(state)/d(input) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1, v2; equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(stateVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(inputVars));
    then DAE.RCONST(0.0);
      
    // d(input)/d(state) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1, v2; equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(inputVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(stateVars));
    then DAE.RCONST(0.0);
      
    // d(parameter1)/d(parameter2) != 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1, v2; equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(paramVars));
      ({v2}, _) = BackendVariable.getVar(x, BackendDAEUtil.listVar(paramVars));
      cref_ = differentiateVarWithRespectToX(cref, x, stateVars);
    then DAE.CREF(cref_, et);
      
    // d(parameter)/d(no parameter) = 0
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) local BackendDAE.Var v1; equation
      ({v1}, _) = BackendVariable.getVar(cref, BackendDAEUtil.listVar(paramVars));
    then DAE.RCONST(0.0);
      
    case(DAE.CREF(componentRef=cref, ty=et), x, functions, inputVars, paramVars, stateVars) equation
      cref_ = differentiateVarWithRespectToX(cref, x, stateVars);
    then DAE.CREF(cref_, et);
      
    // a + b
    case(DAE.BINARY(exp1=e1, operator=DAE.ADD(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.ADD(et), e2_);
      
    // a - b
    case(DAE.BINARY(exp1=e1, operator=DAE.SUB(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.SUB(et), e2_);
      
    // a * b
    case(DAE.BINARY(exp1=e1, operator=DAE.MUL(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(DAE.BINARY(e1_, DAE.MUL(et), e2), DAE.ADD(et), DAE.BINARY(e1, DAE.MUL(et), e2_));
      e = ExpressionSimplify.simplify(e);
    then e;
      
    // a / b
    case(DAE.BINARY(exp1=e1, operator=DAE.DIV(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(DAE.BINARY(DAE.BINARY(e1_, DAE.MUL(et), e2), DAE.SUB(et), DAE.BINARY(e1, DAE.MUL(et), e2_)), DAE.DIV(et), DAE.BINARY(e2, DAE.MUL(et), e2));
      e = ExpressionSimplify.simplify(e);
    then e;
    
    // a(x)^b
    case(e as DAE.BINARY(exp1=e1, operator=DAE.POW(ty=et), exp2=e2), x, functions, inputVars, paramVars, stateVars) equation
      true = Expression.isConst(e2);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e = DAE.BINARY(e1_, DAE.MUL(et), DAE.BINARY(e2, DAE.MUL(et), DAE.BINARY(e1, DAE.POW(et), DAE.BINARY(e2, DAE.SUB(et), DAE.RCONST(1.0)))));
    then e;
    
    // der(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars)
      local
        String str;
        DAE.ComponentRef cref; 
      equation
      Builtin.isDer(fname);
      cref = Expression.expCref(e1);
      cref = crefPrefixDer(cref);
      //str = derivativeNamePrefix +& ExpressionDump.printExpStr(e1);
      //cref = ComponentReference.makeCrefIdent(str, DAE.ET_REAL(),{});
      e1_ = differentiateWithRespectToX(Expression.crefExp(cref), x, functions, inputVars, paramVars, stateVars);
    then e1_;
    
    // -exp
    case(DAE.UNARY(operator=op, exp=e1), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.UNARY(op, e1_);
      
    // sin(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isSin(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("cos"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));

    // cos(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isCos(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()), DAE.BINARY(e1_,DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("sin"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

    // ln(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isLog(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.DIV(DAE.ET_REAL()), e1);

    // log10(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isLog10(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_, DAE.DIV(DAE.ET_REAL()), DAE.BINARY(e1, DAE.MUL(DAE.ET_REAL()), DAE.CALL(Absyn.IDENT("log"),{DAE.RCONST(10.0)},false,true,DAE.ET_REAL(),DAE.NO_INLINE())));

    // exp(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isExp(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.BINARY(e1_,DAE.MUL(DAE.ET_REAL()), DAE.CALL(fname,{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()));
  
    // sqrt(x)
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars)
      equation
        Builtin.isSqrt(fname) "sqrt(x) => 1(2  sqrt(x))  der(x)" ;
        e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      then
        DAE.BINARY(
          DAE.BINARY(DAE.RCONST(1.0),DAE.DIV(DAE.ET_REAL()),
          DAE.BINARY(DAE.RCONST(2.0),DAE.MUL(DAE.ET_REAL()),
          DAE.CALL(Absyn.IDENT("sqrt"),{e1},false,true,DAE.ET_REAL(),DAE.NO_INLINE()))),DAE.MUL(DAE.ET_REAL()),e1_);
        
    // abs(x)          
    case (DAE.CALL(path=fname, expLst={e1}), x, functions, inputVars, paramVars, stateVars) equation
      Builtin.isAbs(fname);
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
    then DAE.IFEXP(DAE.RELATION(e1_,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(0.0)), e1_, DAE.UNARY(DAE.UMINUS(DAE.ET_REAL()),e1_));
      
      // differentiate if-expressions
    case (DAE.IFEXP(expCond=e, expThen=e1, expElse=e2), x, functions, inputVars, paramVars, stateVars) equation
      e1_ = differentiateWithRespectToX(e1, x, functions, inputVars, paramVars, stateVars);
      e2_ = differentiateWithRespectToX(e2, x, functions, inputVars, paramVars, stateVars);
    then DAE.IFEXP(e, e1_, e2_);

    // extern functions (analytical)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, functions, inputVars, paramVars, stateVars)
    local
        list<DAE.Exp> expList2;
        list<tuple<Integer,DAE.derivativeCond>> conditions;
        Absyn.Path derFname;
        DAE.Type tp;
        Integer nArgs;
    equation
        nArgs = listLength(expList1);
        (DAE.FUNCTION_DER_MAPPER(derivativeFunction=derFname,conditionRefs=conditions), tp) = Derive.getFunctionMapper(fname, functions);
        expList2 = deriveExpListwrtstate(expList1, nArgs, conditions, x, functions, inputVars, paramVars, stateVars);
        e1 = partialAnalyticalDifferentiation(expList1, expList2, e, derFname, listLength(expList2));  
    then e1;

    // extern functions (numeric)
    case (e as DAE.CALL(path=fname, expLst=expList1, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), x, functions, inputVars, paramVars, stateVars)
    local
        list<DAE.Exp> expList2;
        Integer nArgs;
    equation
        nArgs = listLength(expList1);
        expList2 = deriveExpListwrtstate2(expList1, nArgs, x, functions, inputVars, paramVars, stateVars);
        e1 = partialNumericalDifferentiation(expList1, expList2, x, e);  
    then e1;
           
    case(e, x, _, _, _, _)
      local String str;
      equation
        str = "differentiateWithRespectToX failed: " +& ExpressionDump.printExpStr(e) +& " | " +& ComponentReference.printComponentRefStr(x);
        Error.addMessage(Error.INTERNAL_ERROR, {str});
      then
        fail();
  end matchcontinue;
end differentiateWithRespectToX;

protected function deriveExpListwrtstate
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input list<tuple<Integer,DAE.derivativeCond>> inConditios;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inConditios, inState, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<tuple<Integer,DAE.derivativeCond>> conditions;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;
    case ({},_,_,_,_,_,_,_) then ({});
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      true = checkcondition(conditions,argnum); 
      r1 = differentiateWithRespectToX(curr, x, functions, inputVars, paramVars, stateVars); 
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars);
    then (r1::r2);
    case (curr::rest, LengthExpList, conditions, x, functions,inputVars, paramVars, stateVars) equation
      r2 = deriveExpListwrtstate(rest,LengthExpList,conditions, x, functions,inputVars, paramVars, stateVars);
    then r2;  
  end matchcontinue;
end deriveExpListwrtstate;

protected function deriveExpListwrtstate2
  input list<DAE.Exp> inExpList;
  input Integer inLengthExpList;
  input DAE.ComponentRef inState;
  input DAE.FunctionTree inFunctions;
  input list<BackendDAE.Var> inInputVars;
  input list<BackendDAE.Var> inParamVars;
  input list<BackendDAE.Var> inStateVars;
  output list<DAE.Exp> outExpList;
algorithm
  outExpList := matchcontinue(inExpList, inLengthExpList, inState, inFunctions, inInputVars, inParamVars, inStateVars)
    local
      DAE.ComponentRef x;
      DAE.Exp curr,r1;
      list<DAE.Exp> rest, r2;
      DAE.FunctionTree functions;
      Integer LengthExpList,n, argnum;
      list<BackendDAE.Var> inputVars, paramVars, stateVars;    
    case ({}, _, _, _, _, _, _) then ({});
    case (curr::rest, LengthExpList, x, functions, inputVars, paramVars, stateVars) equation
      n = listLength(rest);
      argnum = LengthExpList - n;
      r1 = differentiateWithRespectToX(curr, x, functions, inputVars, paramVars, stateVars); 
      r2 = deriveExpListwrtstate2(rest,LengthExpList, x, functions, inputVars, paramVars, stateVars);
    then (r1::r2);
  end matchcontinue;
end deriveExpListwrtstate2;

protected function checkcondition
  input list<tuple<Integer,DAE.derivativeCond>> inConditions;
  input Integer inArgs;
  output Boolean outBool;
algorithm
  outBool := matchcontinue(inConditions, inArgs)
    local
      list<tuple<Integer,DAE.derivativeCond>> rest;
      Integer i,nArgs;
      DAE.derivativeCond cond;
      Boolean res;
    case ({},_) then true;
    case((i,cond)::rest,nArgs) 
      equation
        equality(i = nArgs);
        cond = DAE.ZERO_DERIVATIVE();
      then false;
      case((i,cond)::rest,nArgs) 
        local
          DAE.Exp e1;
         equation
         equality(i = nArgs);
         DAE.NO_DERIVATIVE(_) = cond;
         then false;
    case((i,cond)::rest,nArgs) 
      equation
        res = checkcondition(rest,nArgs);
      then res;           
  end matchcontinue;
end checkcondition;

protected function partialAnalyticalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.Exp functionCall;
  input Absyn.Path derFname;
  input Integer nDerArgs;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(varExpList, derVarExpList, functionCall, derFname, nDerArgs)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpList1Added, varExpListTotal;
      DAE.ExpType et;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      DAE.FunctionTree functions;
    case ( _, {}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, functionCall as DAE.CALL(expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType), derFname, nDerArgs)
      local
        Integer nArgs1, nArgs2;
      equation
        e = partialAnalyticalDifferentiation(restVar, restDerVar, functionCall, derFname, nDerArgs);
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restDerVar);
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(0.0),nArgs1 + nDerArgs - 1, varExpListTotal ,DAE.RCONST(0.0));
        varExpList1Added = Util.listReplaceAtWithFill(DAE.RCONST(1.0),nArgs1 + nDerArgs - nArgs2 + 1, varExpList1Added,DAE.RCONST(0.0));
        derFun = DAE.CALL(derFname, varExpList1Added, tuple_, builtin, et, inlineType);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end matchcontinue;
end partialAnalyticalDifferentiation;

protected function partialNumericalDifferentiation
  input list<DAE.Exp> varExpList;
  input list<DAE.Exp> derVarExpList;
  input DAE.ComponentRef inState;
  input DAE.Exp functionCall;
  output DAE.Exp outExp;
algorithm
  outExp := matchcontinue(varExpList, derVarExpList, inState, functionCall)
    local
      DAE.Exp e, currVar, currDerVar, derFun, delta, absCurr;
      list<DAE.Exp> restVar, restDerVar, varExpListHAdded, varExpListTotal;
      DAE.ExpType et;
      Absyn.Path fname;
      Boolean tuple_, builtin;
      DAE.InlineType inlineType;
      DAE.FunctionTree functions;
    case ({}, _, _, _) then (DAE.RCONST(0.0));
    case (currVar::restVar, currDerVar::restDerVar, inState, functionCall as DAE.CALL(path=fname, expLst=varExpListTotal, tuple_=tuple_, builtin=builtin, ty=et, inlineType=inlineType))
      local
        Integer nArgs1, nArgs2;
      equation
        e = partialNumericalDifferentiation(restVar, restDerVar, inState, functionCall);
        absCurr = DAE.LBINARY(DAE.RELATION(currVar,DAE.GREATER(DAE.ET_REAL()),DAE.RCONST(1e-8)),DAE.OR(),DAE.RELATION(currVar,DAE.LESS(DAE.ET_REAL()),DAE.RCONST(-1e-8)));
        delta = DAE.IFEXP( absCurr, DAE.BINARY(currVar,DAE.MUL(DAE.ET_REAL()),DAE.RCONST(1e-8)), DAE.RCONST(1e-8));
        nArgs1 = listLength(varExpListTotal);
        nArgs2 = listLength(restVar);
        varExpListHAdded = Util.listReplaceAtWithFill(DAE.BINARY(currVar, DAE.ADD(DAE.ET_REAL()),delta),nArgs1-nArgs2+1, varExpListTotal,DAE.RCONST(0.0));
        derFun = DAE.BINARY(DAE.BINARY(DAE.CALL(fname, varExpListHAdded, tuple_, builtin, et, inlineType), DAE.SUB(DAE.ET_REAL()), DAE.CALL(fname, varExpListTotal, tuple_, builtin, et, inlineType)), DAE.DIV(DAE.ET_REAL()), delta);
      then DAE.BINARY(e, DAE.ADD(DAE.ET_REAL()), DAE.BINARY(derFun, DAE.MUL(DAE.ET_REAL()), currDerVar)); 
  end matchcontinue;
end partialNumericalDifferentiation;

protected function differentiateAlgorithmStatements
  // function: differentiateAlgorithmStatements
  // author: lochel
  input list<DAE.Statement> inStatements;
  input DAE.ComponentRef inVar;
  input DAE.FunctionTree inFunctions;
  output list<DAE.Statement> outStatements;
algorithm
  outStatements := matchcontinue(inStatements, inVar, inFunctions)
    local
      list<DAE.Statement> restStatements;
      DAE.ComponentRef var;
      list<DAE.ComponentRef> dependentVars;
      DAE.FunctionTree functions;
      
      DAE.Exp e1, e2;
      DAE.ExpType type_;
      
      DAE.Exp lhsExps;
      DAE.Exp rhsExps;
      
      DAE.Statement currStmt;
      list<DAE.Statement> derivedStatements1;
      list<DAE.Statement> derivedStatements2;
      
      list<DAE.Exp> eLst;
      
      list<DAE.ComponentRef> vars1, vars2;
      list<DAE.Exp> exps1, exps2;
      DAE.FunctionTree functions;
      list<DAE.Algorithm> algorithms;
      DAE.ElementSource elemSrc;
      
    case({}, _, _) then {};
      
    case((currStmt as DAE.STMT_ASSIGN(type_=type_, exp1=e1, exp=e2))::restStatements, var, functions) equation
      lhsExps = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      rhsExps = differentiateWithRespectToX(e2, var, functions, {}, {}, {});
      derivedStatements1 = {DAE.STMT_ASSIGN(type_, lhsExps, rhsExps, DAE.emptyElementSource), currStmt};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_TUPLE_ASSIGN(exp=e2)::restStatements, var, functions) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.differentiateAlgorithmStatements failed: DAE.STMT_TUPLE_ASSIGN"});
    then fail();
      
    case(DAE.STMT_ASSIGN_ARR(exp=e2)::restStatements, var, functions) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.differentiateAlgorithmStatements failed: DAE.STMT_ASSIGN_ARR"});
    then fail();
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.NOELSE(), source=source)::restStatements, var, functions) local
      DAE.Exp exp;
      list<DAE.Statement> statementLst;
      DAE.ElementSource source;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.NOELSE, source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSEIF(exp=elseif_exp, statementLst=elseif_statementLst, else_=elseif_else_), source=source)::restStatements, var, functions) local
      DAE.Exp exp;
      list<DAE.Statement> statementLst;
      DAE.Exp elseif_exp;
      list<DAE.Statement> elseif_statementLst;
      DAE.Else elseif_else_;
      DAE.ElementSource source;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements2 = differentiateAlgorithmStatements({DAE.STMT_IF(elseif_exp, elseif_statementLst, elseif_else_, source)}, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_IF(exp=exp, statementLst=statementLst, else_=DAE.ELSE(statementLst=else_statementLst), source=source)::restStatements, var, functions) local
      DAE.Exp exp;
      list<DAE.Statement> statementLst;
      list<DAE.Statement> else_statementLst;
      DAE.ElementSource source;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements2 = differentiateAlgorithmStatements(else_statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_IF(exp, derivedStatements1, DAE.ELSE(derivedStatements2), source)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_FOR(type_=type_, iterIsArray=iterIsArray, ident=ident, exp=exp, statementLst=statementLst, source=elemSrc)::restStatements, var, functions) local
      DAE.ExpType type_;
      Boolean iterIsArray;
      DAE.Ident ident;
      DAE.Exp exp, exp2;
      list<DAE.Statement> statementLst;
      DAE.ComponentRef cref;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      
      /*cref = ComponentReference.makeCrefIdent(ident, DAE.ET_INT(), {});
      cref = differentiateVarWithRespectToX(cref, var, {});
      exp2 = DAE.CREF(cref, DAE.ET_INT());
      
      derivedStatements2 = {DAE.STMT_ASSIGN(DAE.ET_INT(), exp2, DAE.ICONST(StateVar);0), DAE.emptyElementSource)};
      derivedStatements1 = listAppend(derivedStatements2, derivedStatements1);*/
      
      derivedStatements1 = {DAE.STMT_FOR(type_, iterIsArray, ident, exp, derivedStatements1, elemSrc)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
        
    case(DAE.STMT_WHILE(exp=e1, statementLst=statementLst, source=elemSrc)::restStatements, var, functions) local
      list<DAE.Statement> statementLst;
    equation
      derivedStatements1 = differentiateAlgorithmStatements(statementLst, var, functions);
      derivedStatements1 = {DAE.STMT_WHILE(e1, derivedStatements1, elemSrc)};
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend(derivedStatements1, derivedStatements2);
    then derivedStatements1;
      
    case(DAE.STMT_WHEN(exp=e2)::restStatements, var, functions) equation
      derivedStatements1 = differentiateAlgorithmStatements(restStatements, var, functions);
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_ASSERT(cond=e2))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_TERMINATE(msg=e2))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case(DAE.STMT_REINIT(value=e2)::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
    then derivedStatements2;
      
    case(DAE.STMT_NORETCALL(exp=e1, source=elemSrc)::restStatements, var, functions) equation
      e2 = differentiateWithRespectToX(e1, var, functions, {}, {}, {});
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = listAppend({DAE.STMT_NORETCALL(e2, elemSrc)}, derivedStatements2);
    then fail();
      
    case((currStmt as DAE.STMT_RETURN(source=elemSrc))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case((currStmt as DAE.STMT_BREAK(source=elemSrc))::restStatements, var, functions) equation
      derivedStatements2 = differentiateAlgorithmStatements(restStatements, var, functions);
      derivedStatements1 = currStmt::derivedStatements2;
    then derivedStatements1;
      
    case(_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.differentiateAlgorithmStatements failed"});
    then fail();
  end matchcontinue;
end differentiateAlgorithmStatements;

public function determineIndices
  // function: determineIndices
  // using column major order
  input list<DAE.ComponentRef> inStates;
  input list<DAE.ComponentRef> inStates2;
  input Integer inActInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<String,Integer>> outTuple;
algorithm
  outTuple := matchcontinue(inStates, inStates2, inActInd,inAllVars)
    local
      list<tuple<String,Integer>> str;
      list<tuple<String,Integer>> erg;
      list<DAE.ComponentRef> rest, states;
      DAE.ComponentRef curr;
      Boolean searchForStates;
      Integer actInd;
      list<BackendDAE.Var> allVars;
      
    case ({}, states, _, _) then {};
    case (curr::rest, states, actInd, allVars) equation
      (str, actInd) = determineIndices2(curr, states, actInd, allVars);
      erg = determineIndices(rest, states, actInd, allVars);
      str = listAppend(str, erg);
    then str;
  end matchcontinue;
end determineIndices;

protected function determineIndices2
  // function: determineIndices2
  input DAE.ComponentRef inDStates;
  input list<DAE.ComponentRef> inStates;
  input Integer actInd;
  input list<BackendDAE.Var> inAllVars;
  output list<tuple<String,Integer>> outTuple;
  output Integer outActInd;
algorithm
  (outTuple,outActInd) := matchcontinue(inDStates, inStates, actInd, inAllVars)
    local
      tuple<String,Integer> str;
      list<tuple<String,Integer>> erg;
      list<DAE.ComponentRef> rest;
      DAE.ComponentRef new, curr, dState;
      list<BackendDAE.Var> allVars;
      //String debug1;Integer debug2;
    case (dState, {}, actInd, allVars) then ({}, actInd);
    case (dState,curr::rest, actInd, allVars) equation
      new = differentiateVarWithRespectToX(dState,curr,allVars);
      str = (ComponentReference.printComponentRefStr(new) ,actInd);
      actInd = actInd+1;      
      (erg, actInd) = determineIndices2(dState, rest, actInd, allVars);
    then (str::erg, actInd);
    case (_,_, _, _) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.determineIndices2() failed"});
    then fail();
  end matchcontinue;
end determineIndices2;

public function changeIndices
  input list<BackendDAE.Var> derivedVariables;
  input list<tuple<String,Integer>> outTuple;
  input BackendDAE.BinTree inBinTree;
  output list<BackendDAE.Var> derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
  (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariables,outTuple,inBinTree)
    local
      list<BackendDAE.Var> rest,changedVariables;
      BackendDAE.Var derivedVariable;
      list<tuple<String,Integer>> restTuple;
      BackendDAE.BinTree bt;
    case ({},_,bt) then ({},bt);
    case (derivedVariable::rest,restTuple,bt) equation
      (derivedVariable,bt) = changeIndices2(derivedVariable,restTuple,bt);
      (changedVariables,bt) = changeIndices(rest,restTuple,bt);
    then (derivedVariable::changedVariables,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.changeIndices() failed"});
    then fail();      
  end matchcontinue;
end changeIndices;

protected function changeIndices2
  input BackendDAE.Var derivedVariable;
  input list<tuple<String,Integer>> varIndex; 
  input BackendDAE.BinTree inBinTree;
  output BackendDAE.Var derivedVariablesChanged;
  output BackendDAE.BinTree outBinTree;
algorithm
 (derivedVariablesChanged,outBinTree) := matchcontinue(derivedVariable, varIndex,inBinTree)
    local
      BackendDAE.Var curr, changedVar;
      DAE.ComponentRef currCREF;
      list<tuple<String,Integer>> restTuple;
      String currVar;
      Integer currInd;
      BackendDAE.BinTree bt;
      list<Integer> varInt;
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      true = stringEqual(currVar,ComponentReference.printComponentRefStr(currCREF));
      changedVar = BackendVariable.setVarIndex(curr,currInd);
      Debug.fcall("varIndex2",print, currVar +& " " +& intString(currInd)+&"\n");
      bt = BackendDAEUtil.treeAddList(bt,{currCREF});
    then (changedVar,bt);
    case (curr  as BackendDAE.VAR(varName=currCREF),{},bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currCREF) +& " -1\n");
    then (changedVar,bt);      
    case (curr  as BackendDAE.VAR(varName=currCREF),(currVar,currInd)::restTuple,bt) equation
      changedVar = BackendVariable.setVarIndex(curr,-1);
      Debug.fcall("varIndex2",print, ComponentReference.printComponentRefStr(currCREF) +& " -1\n");
      (changedVar,bt) = changeIndices2(changedVar,restTuple,bt);
    then (changedVar,bt);
    case (_,_,_) equation
      Error.addMessage(Error.INTERNAL_ERROR, {"DAELow.changeIndices2() failed"});
    then fail();      
  end matchcontinue;
end changeIndices2;

end DAELow;

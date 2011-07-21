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

encapsulated package BackendDAETransform
" file:         BackendDAETransform.mo
  package:     BackendDAETransform
  description: BackendDAETransform contains functions that are needed to perform 
               a transformation to a Block-Lower-Triangular-DAE.
               - matchingAlgorithm
               - strongComponents
               - reduceIndexDummyDer

  
  RCS: $Id$
"

public import Absyn;
public import BackendDAE;
public import DAE;
public import HashTable3;
public import HashTableCG;

protected import BackendDAEEXT;
protected import BackendDAEUtil;
protected import BackendDump;
protected import BackendEquation;
protected import BackendDAEOptimize;
protected import BackendVariable;
protected import BackendVarTransform;
protected import BaseHashTable;
protected import ComponentReference;
protected import DAEUtil;
protected import Debug;
protected import Derive;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import Inline;
protected import RTOpts;
protected import SCode;
protected import Util;
protected import Values;


/******************************************
 matchingAlgorithm and stuff
 *****************************************/

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
  
  inputs:  (BackendDAE,IncidenceMatrix, BackendDAE.IncidenceMatrixT, MatchingOptions)
  outputs: (int vector /* vector of equation indices */ ,
              int vector /* vector of variable indices */,
              BackendDAE,IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.MatchingOptions inMatchingOptions;
  input daeHandlerFunc daeHandler;
  input DAE.FunctionTree inFunctions;
  output array<Integer> outIntegerArray1;
  output array<Integer> outIntegerArray2;
  output BackendDAE.BackendDAE outBackendDAE3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
  partial function daeHandlerFunc
    input BackendDAE.DAEHandlerJop inJop;
    input BackendDAE.BackendDAE inBackendDAE;
    input BackendDAE.IncidenceMatrix inIncidenceMatrix;
    input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
    input DAE.FunctionTree inFunctions;
    input BackendDAE.Assignments inAssignments1;
    input BackendDAE.Assignments inAssignments2;    
    input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
    input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
    input BackendDAE.DAEHandlerArg inArg;
    output BackendDAE.BackendDAE outBackendDAE;
    output BackendDAE.IncidenceMatrix outIncidenceMatrix;
    output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
    output BackendDAE.Assignments outAssignments1;
    output BackendDAE.Assignments outAssignments2;      
    output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
    output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
    output BackendDAE.DAEHandlerArg outArg;
  end daeHandlerFunc; 
algorithm
  (outIntegerArray1,outIntegerArray2,outBackendDAE3,outIncidenceMatrix4,outIncidenceMatrixT5) :=
  matchcontinue (inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inMatchingOptions,daeHandler,inFunctions)
    local
      BackendDAE.Value nvars,neqns,memsize;
      String ns,ne;
      BackendDAE.Assignments assign1,assign2,ass1,ass2;
      BackendDAE.BackendDAE dae;
      BackendDAE.IncidenceMatrix m,m_1;
      BackendDAE.IncidenceMatrixT mt,mt_1;      
      array<BackendDAE.Value> vec1,vec2;
      BackendDAE.MatchingOptions match_opts;
      BackendDAE.DAEHandlerArg arg,arg1,arg2;

    /* fail case if daelow is empty */
    case (dae,m,mt,_,_,_)
      equation
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        (nvars == 0) = true;
        (neqns == 0) = true;
        vec1 = listArray({});
        vec2 = listArray({});
      then
        (vec1,vec2,dae,m,mt);
    case (dae,m,mt,match_opts,daeHandler,inFunctions)
      equation
        BackendDAEEXT.clearDifferentiated();
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
        arg = emptyDAEHandlerArg();
        (dae,m,mt, assign1, assign2,_,_,arg1) = daeHandler(BackendDAE.STARTSTEP(),dae, m, mt,inFunctions, assign1, assign2,{},{},arg);
        (ass1,ass2,dae,m_1,mt_1,_,_,arg2) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts, daeHandler, arg1, inFunctions, {}, {});
        (dae,m_1,mt_1,ass1,ass2,_,_,_) = daeHandler(BackendDAE.ENDSTEP(),dae, m_1, mt_1,inFunctions,ass1,ass2,{},{},arg2);
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae,m_1,mt_1);

    else
      equation
        Debug.fprint("failtrace", "- BackendDAE.MatchingAlgorithm failed\n");
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
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.MatchingOptions inMatchingOptions;
algorithm
  _ := matchcontinue (inBackendDAE,inMatchingOptions)
    local
      BackendDAE.Value esize,vars_size;
      BackendDAE.EquationArray eqns;
      String esize_str,vsize_str;
    case (_,(_,BackendDAE.ALLOW_UNDERCONSTRAINED())) then ();
    case (BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
      equation
        esize = BackendDAEUtil.equationSize(eqns);
        ((esize) == vars_size) = true;
      then
        ();
    case (BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
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
    case (BackendDAE.DAE(orderedVars = BackendDAE.VARIABLES(numberOfVars = vars_size),orderedEqs = eqns),_)
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
    else
      equation
        Debug.fprint("failtrace", "- BackendDAE.checkMatching failed\n");
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
        vec = arrayCopy(newarr_1);
      then
        vec;
    case (_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.assignmentsVector failed!"});
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
  arr := arrayCreate(memsize, 0);
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
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.assignments_setnth failed!"});
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
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.assignmentsExpand: n should not be negative!"});
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
        Error.addMessage(Error.INTERNAL_ERROR, {"-BackendDAETranfrom.assignmentsAdd failed!"});
      then
        fail();
  end matchcontinue;
end assignmentsAdd;

public function matchingAlgorithm2
"function: matchingAlgorithm2
  author: PA
  This is the outer loop of the matching algorithm
  The find_path algorithm is called for each equation/variable.
  inputs:  (BackendDAE,IncidenceMatrix, IncidenceMatrixT
             ,int /* number of vars */
             ,int /* number of eqns */
             ,int /* current var */
             ,Assignments  /* assignments, array of eqn indices */
             ,Assignments /* assignments, array of var indices */
             ,MatchingOptions) /* options for matching alg. */
  outputs: (Assignments, /* assignments, array of equation indices */
              Assignments, /* assignments, list of variable indices */
              BackendDAE, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.BackendDAE inBackendDAE1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input Integer inInteger6;
  input BackendDAE.Assignments inAssignments7;
  input BackendDAE.Assignments inAssignments8;
  input BackendDAE.MatchingOptions inMatchingOptions9;
  input daeHandlerFunc daeHandler;
  input BackendDAE.DAEHandlerArg inArg;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
  output BackendDAE.BackendDAE outBackendDAE3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
  output BackendDAE.DAEHandlerArg outArg;
  partial function daeHandlerFunc
    input BackendDAE.DAEHandlerJop inJop;
    input BackendDAE.BackendDAE inBackendDAE;
    input BackendDAE.IncidenceMatrix inIncidenceMatrix;
    input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
    input DAE.FunctionTree inFunctions;
    input BackendDAE.Assignments inAssignments1;
    input BackendDAE.Assignments inAssignments2;    
    input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
    input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
    input BackendDAE.DAEHandlerArg inArg;
    output BackendDAE.BackendDAE outBackendDAE;
    output BackendDAE.IncidenceMatrix outIncidenceMatrix;
    output BackendDAE.IncidenceMatrixT outIncidenceMatrixT; 
    output BackendDAE.Assignments outAssignments1;
    output BackendDAE.Assignments outAssignments2; 
    output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
    output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
    output BackendDAE.DAEHandlerArg outArg;
  end daeHandlerFunc;
algorithm
  (outAssignments1,outAssignments2,outBackendDAE3,outIncidenceMatrix4,outIncidenceMatrixT5,outDerivedAlgs,outDerivedMultiEqn,outArg):=
  matchcontinue (inBackendDAE1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inAssignments7,inAssignments8,inMatchingOptions9,daeHandler,inArg,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2,ass1_2,ass2_2;
      BackendDAE.BackendDAE dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,i,i_1,nv_1,nkv,nf_1,nvd;
      BackendDAE.MatchingOptions match_opts;
      BackendDAE.EquationArray eqns;
      BackendDAE.EquationConstraints eq_cons;
      list<BackendDAE.Value> eqn_lst,var_lst;
      String eqn_str,var_str;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1,derivedAlgs2;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1,derivedMultiEqn2;
      BackendDAE.DAEHandlerArg arg,arg1;
      DAE.ElementSource source;
      Absyn.Info info;

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,inArg,_,derivedAlgs,derivedMultiEqn)
      equation
        (nv == i) = true;
        BackendDAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false; eMark(i)=vMark(i)=false exit loop";
      then
        (ass1_1,ass2_1,dae,m,mt,derivedAlgs,derivedMultiEqn,inArg);

    case (dae,m,mt,nv,nf,i,ass1,ass2,match_opts,daeHandler,inArg,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        i_1 = i + 1;
        BackendDAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false" ;
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1,arg) = matchingAlgorithm2(dae, m, mt, nv, nf, i_1, ass1_1, ass2_1, match_opts, daeHandler, inArg, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1,arg);

    case (dae,m,mt,nv,nf,i,ass1,ass2,match_opts as (BackendDAE.INDEX_REDUCTION(),eq_cons),daeHandler,inArg,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        (dae,m,mt,ass1,ass2,derivedAlgs1,derivedMultiEqn1,arg) = daeHandler(BackendDAE.REDUCE_INDEX(),dae,m,mt,inFunctions,ass1,ass2,derivedAlgs,derivedMultiEqn,inArg) 
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
        eqns = BackendEquation.daeEqns(dae);
        nf_1 = BackendDAEUtil.equationSize(eqns) "and try again, restarting. This could be optimized later. It should not
                                   be necessary to restart the matching, according to Bernard Bachmann. Instead one
                                   could continue the matching as usual. This was tested (2004-11-22) and it does not
                                   work to continue without restarting.
                                   For instance the Influenca model \"../testsuite/mofiles/Influenca.mo\" does not work if
                                   not restarting.
                                   2004-12-29 PA. This was a bug, assignment lists needed to be expanded with the size
                                   of the system in order to work. SO: Matching is not needed to be restarted from
                                   scratch." ;
        nv_1 = BackendVariable.varsSize(BackendVariable.daeVars(dae));
        nvd = nv_1 - nv;
        ass1_1 = assignmentsExpand(ass1, nvd);
        ass2_1 = assignmentsExpand(ass2, nvd);
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2,arg1) = matchingAlgorithm2(dae,m,mt,nv_1,nf_1,i,ass1_1,ass2_1,match_opts,daeHandler,arg,inFunctions,derivedAlgs1,derivedMultiEqn1);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2,arg1);

    case (dae,_,_,_,_,_,_,_,_,_,_,_,_,_)
      equation
        eqn_lst = BackendDAEEXT.getMarkedEqns() "When index reduction also fails, the model is structurally singular." ;
        var_lst = BackendDAEEXT.getMarkedVariables();
        eqn_str = BackendDump.dumpMarkedEqns(dae, eqn_lst);
        var_str = BackendDump.dumpMarkedVars(dae, var_lst);
        i::_ = eqn_lst;
        source = BackendEquation.markedEquationSource(dae, i);
        info = DAEUtil.getElementSourceFileInfo(source);
        Error.addSourceMessage(Error.STRUCT_SINGULAR_SYSTEM, {eqn_str,var_str}, info);
        //print("structurally singular. IM:");
        //dumpIncidenceMatrix(m);
        //print("daelow:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end matchingAlgorithm2;

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
        BackendDAEEXT.eMark(i) "Side effect" ;
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
  match (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
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
  end match;
end assignOneInEqn;

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
  match (inInteger1,inAssignments2,inAssignments3)
    local
      BackendDAE.Value v;
      array<BackendDAE.Value> m;
    case (v,BackendDAE.ASSIGNMENTS(arrOfIndices = m),_) then m[v];
  end match;
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
  match (inInteger1,inInteger2,inAssignments3,inAssignments4)
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
  end match;
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
  match (inIncidenceMatrix1,inIncidenceMatrixT2,inInteger3,inAssignments4,inAssignments5)
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
  end match;
end forallUnmarkedVarsInEqn;

protected function isNotVMarked
"function: isNotVMarked
  author: PA
  This function succeds for variables that are not marked."
  input Integer i;
algorithm
  false := BackendDAEEXT.getVMark(i);
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
        BackendDAEEXT.vMark(v);
        assarg = getAssigned(v, ass1, ass2);
        (ass1_1,ass2_1) = pathFound(m, mt, assarg, ass1, ass2);
        (ass1_2,ass2_2) = assign(v, i, ass1_1, ass2_1);
      then
        (ass1_2,ass2_2);
    case (m,mt,i,(vars as (v :: vs)),ass1,ass2)
      equation
        BackendDAEEXT.vMark(v);
        (ass1_1,ass2_1) = forallUnmarkedVarsInEqnBody(m, mt, i, vs, ass1, ass2);
      then
        (ass1_1,ass2_1);
  end matchcontinue;
end forallUnmarkedVarsInEqnBody;

/******************************************
 strongComponents and stuff
 *****************************************/

public function strongComponents "function: strongComponents
  author: PA

  This is the second part of the BLT sorting. It takes the variable
  assignments and the incidence matrix as input and identifies strong
  components, i.e. subsystems of equations.

  inputs:  (IncidenceMatrix, BackendDAE.IncidenceMatrixT, int vector, int vector)
  outputs: (int list list /* list of components */ )
"
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix1;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT2;
  input array<Integer> inIntegerArray3;
  input array<Integer> inIntegerArray4;
  output BackendDAE.StrongComponents outComps;
algorithm
  (outComps) :=
  matchcontinue (inDAE,inIncidenceMatrix1,inIncidenceMatrixT2,inIntegerArray3,inIntegerArray4)
    local
      BackendDAE.Value n,i;
      list<BackendDAE.Value> stack;
      list<list<BackendDAE.Value>> comps;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<BackendDAE.Value> ass1,ass2;
      BackendDAE.StrongComponents comps1;
    case (inDAE,m,mt,ass1,ass2)
      equation
        n = arrayLength(m);
        BackendDAEEXT.initLowLink(n);
        BackendDAEEXT.initNumber(n);
        (i,stack,comps) = strongConnectMain(m, mt, ass1, ass2, n, 0, 1, {}, {});
        comps1 = analyseStrongComponents(comps,inDAE,m,mt,ass1,ass2);
      then
        (comps1);
    else
      equation
        Debug.fprint("failtrace", "strong_components failed\n");
        Error.addMessage(Error.INTERNAL_ERROR,
          {"sorting equations(strong components failed)"});
      then
        fail();
  end matchcontinue;
end strongComponents;

protected function analyseStrongComponents"function: analyseStrongComponents
  author: Frenkel TUD 2011-05
  analyse the type of the strong connect components and
  calculate the jacobian."
  input list<list<BackendDAE.Value>> inComps;
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;  
  input array<Integer> inAss1;
  input array<Integer> inAss2;  
  output BackendDAE.StrongComponents outComps;
algorithm
  outComps:=
  match (inComps,inDAE,inIncidenceMatrix,inIncidenceMatrixT,inAss1,inAss2)
    local
      list<BackendDAE.Value> comp;
      list<list<BackendDAE.Value>> comps;
      BackendDAE.StrongComponents acomps;
      BackendDAE.StrongComponent acomp;
      array<Integer> ass1,ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
    case ({},_,_,_,_,_) then ({});
    case (comp::comps,inDAE,m,mt,ass1,ass2)
      equation
        acomps = analyseStrongComponents(comps,inDAE,m,mt,ass1,ass2);
        acomp = analyseStrongComponent(comp,inDAE,m,mt,ass1,ass2);
      then
        (acomp::acomps);
    else
      equation
        print("- BackendDAETransform.analyseStrongComponents failed\n");
      then
        fail();        
  end match;  
end analyseStrongComponents;

protected function analyseStrongComponent"function: analyseStrongComponent
  author: Frenkel TUD 2011-05 
  helper for analyseStrongComponents."
  input list<BackendDAE.Value> inComp;
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;   
  input array<Integer> inAss1;
  input array<Integer> inAss2;  
  output BackendDAE.StrongComponent outComp;
algorithm
  outComp:=
  match (inComp,inDAE,inIncidenceMatrix,inIncidenceMatrixT,inAss1,inAss2)
    local
      BackendDAE.Value compelem,v;
      list<BackendDAE.Value> comp;
      list<tuple<BackendDAE.Var,BackendDAE.Value>> var_varindx_lst;
      array<Integer> ass1,ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.Variables vars;
      list<BackendDAE.Equation> eqn_lst;
      BackendDAE.EquationArray eqns;
      BackendDAE.StrongComponent compX;
    case (compelem::{},_,_,_,_,ass2)
      equation
        v = ass2[compelem];  
      then BackendDAE.SINGLEEQUATION(compelem,v);
    case (comp,inDAE as BackendDAE.DAE(orderedVars=vars,orderedEqs=eqns),m,mt,ass1,ass2)
      equation
        (eqn_lst,var_varindx_lst) = Util.listMap32(comp, getEquationAndSolvedVar_Internal, eqns, vars, ass2);
        compX = analyseStrongComponentBlock(comp,eqn_lst,var_varindx_lst,inDAE,m,mt,ass1,ass2);   
      then
        compX;
    else
      equation
        print("- BackendDAETransform.analyseStrongComponent failed\n");
      then
        fail();          
  end match;  
end analyseStrongComponent;

protected function analyseStrongComponentBlock"function: analyseStrongComponentBlock
  author: Frenkel TUD 2011-05 
  helper for analyseStrongComponent."
  input list<BackendDAE.Value> inComp;  
  input list<BackendDAE.Equation> inEqnLst;
  input list<tuple<BackendDAE.Var,BackendDAE.Value>> inVarVarindxLst; 
  input BackendDAE.BackendDAE inDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;   
  input array<Integer> inAss1;
  input array<Integer> inAss2;  
  output BackendDAE.StrongComponent outComp;
algorithm
  outComp:=
  matchcontinue (inComp,inEqnLst,inVarVarindxLst,inDAE,inIncidenceMatrix,inIncidenceMatrixT,inAss1,inAss2)
    local
      Integer i;
      list<BackendDAE.Value> comp,varindxs;
      list<tuple<BackendDAE.Var,BackendDAE.Value>> var_varindx_lst,var_varindx_lst_cond;
      array<Integer> ass1,ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
      BackendDAE.Variables vars,evars,vars_1;
      list<BackendDAE.Equation> eqn_lst,cont_eqn,disc_eqn;
      list<BackendDAE.Var> var_lst,var_lst_1,cont_var,disc_var;
      list<Integer> indxcont_var,indxdisc_var,indxcont_eqn,indxdisc_eqn;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns_1,eqns,eeqns;
      BackendDAE.BackendDAE subsystem_dae;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
      BackendDAE.StrongComponent sc;
    case (comp,eqn_lst,var_varindx_lst,inDAE,m,mt,ass1,ass2)
      equation
        SOME(i) = singleAlgorithmEquation(eqn_lst,NONE());
        varindxs = Util.listMap(var_varindx_lst,Util.tuple22);        
      then
        BackendDAE.SINGLEALGORITHM(i,comp,varindxs);
    case (comp,eqn_lst,var_varindx_lst,inDAE,m,mt,ass1,ass2)
      equation
        SOME(i) = singleArrayEquation(eqn_lst,NONE());
        varindxs = Util.listMap(var_varindx_lst,Util.tuple22);        
      then
        BackendDAE.SINGLEARRAY(i,comp,varindxs);
    case (comp,eqn_lst,var_varindx_lst,inDAE as BackendDAE.DAE(orderedVars=vars,orderedEqs=eqns,arrayEqs=ae,algorithms=al),m,mt,ass1,ass2)
      equation
        var_lst = Util.listMap(var_varindx_lst,Util.tuple21);
        true = BackendVariable.hasDiscreteVar(var_lst);
        true = BackendVariable.hasContinousVar(var_lst);
        varindxs = Util.listMap(var_varindx_lst,Util.tuple22);
        (cont_eqn,cont_var,disc_eqn,disc_var,indxcont_eqn,indxcont_var,indxdisc_eqn,indxdisc_var) = splitMixedEquations(eqn_lst, comp, var_lst, varindxs);
        var_varindx_lst_cond = Util.makeTupleList(cont_var,indxcont_var);
        sc = analyseStrongComponentBlock(indxcont_eqn,cont_eqn,var_varindx_lst_cond,inDAE,m,mt,ass1,ass2);
      then
        BackendDAE.MIXEDEQUATIONSYSTEM(sc,indxdisc_eqn,indxdisc_var);        
    case (comp,eqn_lst,var_varindx_lst,inDAE as BackendDAE.DAE(orderedVars=vars,orderedEqs=eqns,arrayEqs=ae,algorithms=al),m,mt,ass1,ass2)
      equation
        var_lst = Util.listMap(var_varindx_lst,Util.tuple21);
        varindxs = Util.listMap(var_varindx_lst,Util.tuple22);
        eqn_lst = replaceDerOpInEquationList(eqn_lst);
        ae1 = Util.arrayMap(ae,replaceDerOpMultiDimEquations);
        // States are solved for der(x) not x.
        var_lst_1 = Util.listMap(var_lst, transformXToXd);
        vars_1 = BackendDAEUtil.listVar(var_lst_1);
        // because listVar orders the elements not like listEquation the pairs of (var is solved in equation)
        // is  twisted, simple reverse one list
        eqn_lst = listReverse(eqn_lst);
        eqns_1 = BackendDAEUtil.listEquation(eqn_lst);
        av = BackendDAEUtil.emptyAliasVariables();
        eeqns = BackendDAEUtil.listEquation({});
        evars = BackendDAEUtil.listVar({});
        subsystem_dae = BackendDAE.DAE(vars_1,evars,evars,av,eqns_1,eeqns,eeqns,ae1,al,BackendDAE.EVENT_INFO({},{}),{});
        (m,mt) = BackendDAEUtil.incidenceMatrix(subsystem_dae, BackendDAE.ABSOLUTE());
        //mt = BackendDAEUtil.transposeMatrix(m);
        // calculate jacobian. If constant, linear system of equations. Otherwise nonlinear
        jac = BackendDAEUtil.calculateJacobian(vars_1, eqns_1, ae1, m, mt,true);
        // Jacobian of a Linear System is always linear 
        jac_tp = BackendDAEUtil.analyzeJacobian(subsystem_dae, jac);
      then
        BackendDAE.EQUATIONSYSTEM(comp,varindxs,jac,jac_tp);
    else
      equation
        print("- BackendDAETransform.analyseStrongComponentBlock failed\n");
      then
        fail();          
  end matchcontinue;  
end analyseStrongComponentBlock;

protected function singleAlgorithmEquation
  input list<BackendDAE.Equation> inEqnLst;
  input Option<Integer> inIndx;
  output Option<Integer> outIndx;
algorithm
  outIndx:=
  matchcontinue (inEqnLst,inIndx)
    local 
      list<BackendDAE.Equation> eqnlst;
      Integer i,i1;
      Option<Integer> oi;
    case ({},SOME(i)) then SOME(i);
    case (BackendDAE.ALGORITHM(index = i)::eqnlst,NONE())
      equation
        oi = singleAlgorithmEquation(eqnlst,SOME(i));
    then oi;
    case (BackendDAE.ALGORITHM(index = i)::eqnlst,SOME(i1))
      equation
        true = intEq(i,i1);
        oi = singleAlgorithmEquation(eqnlst,SOME(i));
    then oi;
      else NONE();
  end matchcontinue;
end singleAlgorithmEquation;

protected function singleArrayEquation
  input list<BackendDAE.Equation> inEqnLst;
  input Option<Integer> inIndx;
  output Option<Integer> outIndx;
algorithm
  outIndx:=
  matchcontinue (inEqnLst,inIndx)
    local 
      list<BackendDAE.Equation> eqnlst;
      Integer i,i1;
      Option<Integer> oi;
    case ({},SOME(i)) then SOME(i);
    case (BackendDAE.ARRAY_EQUATION(index = i)::eqnlst,NONE())
      equation
        oi = singleArrayEquation(eqnlst,SOME(i));
    then oi;
    case (BackendDAE.ARRAY_EQUATION(index = i)::eqnlst,SOME(i1))
      equation
        true = intEq(i,i1);
        oi = singleArrayEquation(eqnlst,SOME(i));
    then oi;
      else NONE();
  end matchcontinue;
end singleArrayEquation;

protected function transformXToXd "function transformXToXd
  author: PA
  this function transforms x variables (in the state vector)
  to corresponding xd variable (in the derivatives vector)"
  input BackendDAE.Var inVar;
  output BackendDAE.Var outVar;
algorithm
  outVar := matchcontinue (inVar)
    local
      Expression.ComponentRef cr;
      DAE.VarDirection dir;
      BackendDAE.Type tp;
      Option<DAE.Exp> exp;
      Option<Values.Value> v;
      list<Expression.Subscript> dim;
      Integer index;
      Option<DAE.VariableAttributes> attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      DAE.ElementSource source "the origin of the element";
      BackendDAE.Var backendVar;
      
    case (BackendDAE.VAR(varName = cr,
      varKind = BackendDAE.STATE(),
      varDirection = dir,
      varType = tp,
      bindExp = exp,
      bindValue = v,
      arryDim = dim,
      index = index,
      source = source,
      values = attr,
      comment = comment,
      flowPrefix = flowPrefix,
      streamPrefix = streamPrefix))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
      then
        BackendDAE.VAR(cr,BackendDAE.STATE_DER(),dir,tp,exp,v,dim,index,source,attr,comment,flowPrefix,streamPrefix);
        
    case (backendVar)
    then
      backendVar;
  end matchcontinue;
end transformXToXd;

protected function replaceDerOpMultiDimEquations
"Replaces all der(cref) with $DER.cref in an multidimequation."
  input BackendDAE.MultiDimEquation inMultiDimEquation;
  output BackendDAE.MultiDimEquation outMultiDimEquation;
algorithm
  outMultiDimEquation := matchcontinue(inMultiDimEquation)
    local
      list<Integer> ilst;
      DAE.Exp e1,e1_1,e2,e2_1;
      DAE.ElementSource source;
      
    case(BackendDAE.MULTIDIM_EQUATION(ilst,e1,e2,source))
      equation
        ((e1_1,_)) = replaceDerOpInExp((e1,0));
        ((e2_1,_)) = replaceDerOpInExp((e2,0));
      then
        BackendDAE.MULTIDIM_EQUATION(ilst,e1_1,e2_1,source);
    case(inMultiDimEquation) then inMultiDimEquation;
  end matchcontinue;
end replaceDerOpMultiDimEquations;

protected function replaceDerOpInEquationList
  "Replaces all der(cref) with $DER.cref in a list of equations."
  input list<BackendDAE.Equation> inEqns;
  output list<BackendDAE.Equation> outEqns;
algorithm
  (outEqns,_) := BackendEquation.traverseBackendDAEExpsEqnList(inEqns, replaceDerOpInExp,0);
end replaceDerOpInEquationList;

protected function replaceDerOpInExp
  "Replaces all der(cref) with $DER.cref in an expression."
    input tuple<DAE.Exp, Integer> inTpl;
    output tuple<DAE.Exp, Integer> outTpl;
protected
  DAE.Exp exp,exp1;
  Integer i;
algorithm
  (exp,i) := inTpl;
  ((exp1, _)) := Expression.traverseExp(exp, replaceDerOpInExpTraverser, NONE());
  outTpl := ((exp1,i));
end replaceDerOpInExp;

protected function replaceDerOpInExpTraverser
  "Used with Expression.traverseExp to traverse an expression an replace calls to
  der(cref) with a component reference $DER.cref. If an optional component
  reference is supplied, then only that component reference is replaced.
  Otherwise all calls to der are replaced.
  
  This is done since some parts of the compiler can't handle der-calls, such as
  Derive.differentiateExpression. Ideally these parts should be fixed so that they can
  handle der-calls, but until that happens we just replace the der-calls with
  crefs."
  input tuple<DAE.Exp, Option<DAE.ComponentRef>> inExp;
  output tuple<DAE.Exp, Option<DAE.ComponentRef>> outExp;
algorithm
  outExp := matchcontinue(inExp)
    local
      DAE.ComponentRef cr, der_cr;
      DAE.Exp cref_exp;
      DAE.ComponentRef cref;
      
    case ((DAE.CALL(path = Absyn.IDENT("der"),expLst = {DAE.CREF(componentRef = cr)}),
        SOME(cref)))
      equation
        der_cr = ComponentReference.crefPrefixDer(cr);
        true = ComponentReference.crefEqualNoStringCompare(der_cr, cref);
        cref_exp = Expression.crefExp(der_cr);
      then
        ((cref_exp, SOME(cref)));
        
    case ((DAE.CALL(path = Absyn.IDENT("der"),expLst = {DAE.CREF(componentRef = cr)}),
        NONE()))
      equation
        cr = ComponentReference.crefPrefixDer(cr);
        cref_exp = Expression.crefExp(cr);
      then
        ((cref_exp, NONE()));
    case (_) then inExp;
  end matchcontinue;
end replaceDerOpInExpTraverser;

public function getEquationAndSolvedVar
"function: getEquationAndSolvedVar
  author: PA
  Retrieves the equation and the variable solved in that equation
  given an equation number and the variable assignments2"
  input BackendDAE.StrongComponent inComp;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Variables inVariables;
  output list<BackendDAE.Equation> outEquation;
  output list<BackendDAE.Var> outVar;
  output Integer outIndex;
algorithm
  (outEquation,outVar,outIndex):=
  matchcontinue (inComp,inEquationArray,inVariables)
    local
      Integer e_1,v,e;
      list<Integer> elst,vlst;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
      list<BackendDAE.Equation> eqnlst,eqnlst1;
      list<BackendDAE.Var> varlst,varlst1;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      BackendDAE.StrongComponent comp;
    case (BackendDAE.SINGLEEQUATION(eqn=e,var=v),eqns,vars) 
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        var = BackendVariable.getVarAt(vars, v);
      then
        ({eqn},{var},e);
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=elst,disc_vars=vlst),eqns,vars) 
      equation
        eqnlst1 = BackendEquation.getEqns(elst,eqns);   
        varlst1 = Util.listMap1r(vlst, BackendVariable.getVarAt, vars);
        e = Util.listFirst(elst);        
        (eqnlst,varlst,_) = getEquationAndSolvedVar(comp,eqns,vars);
        eqnlst = listAppend(eqnlst,eqnlst1);
        varlst = listAppend(varlst,varlst1);
      then
        (eqnlst,varlst,e);          
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst,vars=vlst),eqns,vars) 
      equation
        eqnlst = BackendEquation.getEqns(elst,eqns);        
        varlst = Util.listMap1r(vlst, BackendVariable.getVarAt, vars);
        e = Util.listFirst(elst);        
      then
        (eqnlst,varlst,e);        
    case (BackendDAE.SINGLEARRAY(eqns=elst,vars=vlst),eqns,vars) 
      equation
        eqnlst = BackendEquation.getEqns(elst,eqns);      
        varlst = Util.listMap1r(vlst, BackendVariable.getVarAt, vars);        
        e = Util.listFirst(elst);        
      then
        (eqnlst,varlst,e);  
    case (BackendDAE.SINGLEALGORITHM(eqns=elst,vars=vlst),eqns,vars)
      equation
        eqnlst = BackendEquation.getEqns(elst,eqns);  
        varlst = Util.listMap1r(vlst, BackendVariable.getVarAt, vars);        
        e = Util.listFirst(elst);        
      then
        (eqnlst,varlst,e);         
    case (inComp,eqns,vars)
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "BackendDAETransform.getEquationAndSolvedVar failed!");
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVar;

protected function getEquationAndSolvedVar_Internal
"function: getEquationAndSolvedVar_Internal
  author: PA
  Retrieves the equation and the variable solved in that equation
  given an equation number and the variable assignments2"
  input Integer inInteger;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Variables inVariables;
  input array<Integer> inIntegerArray;
  output BackendDAE.Equation outEquation;
  output tuple<BackendDAE.Var,Integer> outVar;
algorithm
  (outEquation,outVar):=
  matchcontinue (inInteger,inEquationArray,inVariables,inIntegerArray)
    local
      Integer e_1,v,e;
      BackendDAE.Equation eqn;
      BackendDAE.Var var;
      BackendDAE.EquationArray eqns;
      BackendDAE.Variables vars;
      array<Integer> ass2;
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        v = ass2[e];
        var = BackendVariable.getVarAt(vars, v);
      then
        (eqn,(var,v));
    case (e,eqns,vars,ass2) /* equation no. assignments2 */
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "BackendDAETransform.getEquationAndSolvedVar_Internal failed at index: " +& intString(e));
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVar_Internal;

public function getEquationAndSolvedVarIndxes
"function: getEquationAndSolvedVarIndxes
  author: Frenkel TUD
  Retrieves the equation and the variable indexes solved in that equation
  given an equation number and the variable assignments2"
  input BackendDAE.StrongComponent inComp;
  output list<Integer> outEquation;
  output list<Integer> outVar;
algorithm
  (outEquation,outVar):=
  matchcontinue(inComp)
    local
      Integer e_1,v,e;
      list<Integer> elst,vlst,elst1,vlst1;
      BackendDAE.StrongComponent comp;
    case (BackendDAE.SINGLEEQUATION(eqn=e,var=v)) 
      then
        ({e},{v});
    case (BackendDAE.MIXEDEQUATIONSYSTEM(condSystem=comp,disc_eqns=elst,disc_vars=vlst))
      equation       
        (elst1,vlst1) = getEquationAndSolvedVarIndxes(comp);
        elst = listAppend(elst1,elst);
        vlst = listAppend(vlst1,vlst);
      then
        (elst,vlst);          
    case (BackendDAE.EQUATIONSYSTEM(eqns=elst,vars=vlst))      
      then
        (elst,vlst);        
    case (BackendDAE.SINGLEARRAY(eqns=elst,vars=vlst))     
      then
        (elst,vlst);  
    case (BackendDAE.SINGLEALGORITHM(eqns=elst,vars=vlst))     
      then
        (elst,vlst);         
    else
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprintln("failtrace", "BackendDAETransform.getEquationAndSolvedVarIndxes failed!");
      then
        fail();
  end matchcontinue;
end getEquationAndSolvedVarIndxes;

public function splitMixedEquations "function: splitMixedEquations
  author: PA

  Splits the equation of a mixed equation system into its continuous and
  discrete parts.

  Even though the matching algorithm might say that a discrete variable is solved in a specific equation
  (when part of a mixed system) this is not always correct. It might be impossible to solve the discrete
  variable from that equation, for instance solving v from equation x = v < 0; This happens for e.g. the Gear model.
  Instead, to split the equations and variables the following scheme is used:

  1. Split the variables into continuous and discrete.
  2. For each discrete variable v, select among the equations where it is present
   for an equation v = expr. (This could be done
   by looking at incidence matrix but for now we look through all equations. This is sufficiently
   efficient for small systems of mixed equations < 100)
  3. The equations not selected in step 2 are continuous equations.
"
  input list<BackendDAE.Equation> eqnLst;
  input list<Integer> indxEqnLst;
  input list<BackendDAE.Var> varLst;
  input list<Integer> indxVarLst;
  output list<BackendDAE.Equation> contEqnLst;
  output list<BackendDAE.Var> contVarLst;
  output list<BackendDAE.Equation> discEqnLst;
  output list<BackendDAE.Var> discVarLst;
  output list<Integer> indxcontEqnLst;
  output list<Integer> indxcontVarLst;
  output list<Integer> indxdiscEqnLst;
  output list<Integer> indxdiscVarLst;
algorithm
  (contEqnLst,contVarLst,discEqnLst,discVarLst,indxcontEqnLst,indxcontVarLst,indxdiscEqnLst,indxdiscVarLst):=
  match (eqnLst,indxEqnLst,varLst,indxVarLst)
    local list<tuple<BackendDAE.Equation,Integer>> eqnindxlst;
    case (eqnLst,indxEqnLst,varLst,indxVarLst) equation
      (discVarLst,contVarLst,indxdiscVarLst,indxcontVarLst) = splitVars(varLst,indxVarLst,BackendDAEUtil.isVarDiscrete,{},{},{},{});
      eqnindxlst = Util.listMap1(discVarLst,findDiscreteEquation,(eqnLst,indxEqnLst));
      discEqnLst = Util.listMap(eqnindxlst,Util.tuple21);
      indxdiscEqnLst = Util.listMap(eqnindxlst,Util.tuple22);
      contEqnLst = Util.listSetDifferenceOnTrue(eqnLst,discEqnLst,BackendEquation.equationEqual);
      indxcontEqnLst = Util.listSetDifferenceOnTrue(indxEqnLst,indxdiscEqnLst,intEq);
    then (contEqnLst,contVarLst,discEqnLst,discVarLst,indxcontEqnLst,indxcontVarLst,indxdiscEqnLst,indxdiscVarLst);
  end match;
end splitMixedEquations;

public function splitVars
  "Helper function to splitMixedEquations."
  input list<Type_a> inList;
  input list<Type_b> inListb;
  input PredicateFunc inFunc;
  input list<Type_a> inTrueList;
  input list<Type_a> inFalseList;
  input list<Type_b> inTrueListb;
  input list<Type_b> inFalseListb;
  output list<Type_a> outTrueList;
  output list<Type_a> outFalseList;
  output list<Type_b> outTrueListb;
  output list<Type_b> outFalseListb;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;

  partial function PredicateFunc
    input Type_a inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList,outTrueListb, outFalseListb) := 
  match(inList, inListb, inFunc, inTrueList, inFalseList, inTrueListb, inFalseListb)
    local
      Type_a e;
      Type_b eb;
      list<Type_a> rest_e, tl, fl;
      list<Type_b> rest_eb, tlb, flb;
      Boolean pred;

    case ({}, {}, _, tl, fl, tlb, flb) 
      then (listReverse(tl), listReverse(fl),listReverse(tlb), listReverse(flb));

    case (e :: rest_e,eb :: rest_eb, _, tl, fl, tlb, flb)
      equation
        pred = inFunc(e);
        (tl, fl,tlb, flb) = splitVars1(e, rest_e,eb, rest_eb, pred, inFunc, tl, fl, tlb, flb);
      then
        (tl, fl,tlb, flb);
  end match;
end splitVars;

public function splitVars1
  "Helper function to splitVars."
  input Type_a inHead;
  input list<Type_a> inRest;
  input Type_b inHeadb;
  input list<Type_b> inRestb;
  input Boolean inPred;
  input PredicateFunc inFunc;
  input list<Type_a> inTrueList;
  input list<Type_a> inFalseList;
  input list<Type_b> inTrueListb;
  input list<Type_b> inFalseListb;
  output list<Type_a> outTrueList;
  output list<Type_a> outFalseList;
  output list<Type_b> outTrueListb;
  output list<Type_b> outFalseListb;

  replaceable type Type_a subtypeof Any;
  replaceable type Type_b subtypeof Any;

  partial function PredicateFunc
    input Type_a inElement;
    output Boolean outResult;
  end PredicateFunc;
algorithm
  (outTrueList, outFalseList,outTrueListb, outFalseListb) := 
  match(inHead, inRest,inHeadb, inRestb, inPred, inFunc, inTrueList, inFalseList,inTrueListb, inFalseListb)
    local
      Boolean pred;
      Type_a e;
      Type_b eb;
      list<Type_a> rl, tl, fl;
      list<Type_b> rlb, tlb, flb;

    case (_, _, _, _, true, _, tl, fl, tlb, flb)
      equation
        tl = inHead :: tl;
        tlb = inHeadb :: tlb;
        (tl, fl, tlb, flb) = splitVars(inRest, inRestb, inFunc, tl, fl, tlb, flb);
      then
        (tl, fl, tlb, flb);

    case (_, _, _, _, false, _, tl, fl, tlb, flb)
      equation
        fl = inHead :: fl;
        flb = inHeadb :: flb;
        (tl, fl, tlb, flb) = splitVars(inRest, inRestb, inFunc, tl, fl, tlb, flb);
      then
        (tl, fl, tlb, flb);
  end match;
end splitVars1;

protected function findDiscreteEquation "help function to splitMixedEquations, finds the discrete equation
on the form v = expr for solving variable v"
  input BackendDAE.Var v;
  input tuple<list<BackendDAE.Equation>,list<Integer>> eqnIndxLst;
  output tuple<BackendDAE.Equation,Integer> eqnindx;
algorithm
  eqnindx := matchcontinue(v,eqnIndxLst)
    local Expression.ComponentRef cr1,cr;
      DAE.Exp e2;
      Integer i;
      BackendDAE.Equation eqn;
      list<Integer> ilst;
      list<BackendDAE.Equation> eqnLst;
    case (v,(((eqn as BackendDAE.EQUATION(DAE.CREF(cr,_),e2,_))::_),i::_)) equation
      cr1=BackendVariable.varCref(v);
      true = ComponentReference.crefEqualNoStringCompare(cr1,cr);
    then ((eqn,i));
    case(v,(((eqn as BackendDAE.EQUATION(e2,DAE.CREF(cr,_),_))::_),i::_)) equation
      cr1=BackendVariable.varCref(v);
      true = ComponentReference.crefEqualNoStringCompare(cr1,cr);
    then ((eqn,i));
    case(v,(_::eqnLst,_::ilst)) equation
      ((eqn,i)) = findDiscreteEquation(v,(eqnLst,ilst));
    then ((eqn,i));
    case(v,_) equation
      print("findDiscreteEquation failed, searching for ");
      print(ComponentReference.printComponentRefStr(BackendVariable.varCref(v)));
      print("\n");
    then fail();
  end matchcontinue;
end findDiscreteEquation;

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
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Value n,i,w,w_1,num;
      list<BackendDAE.Value> stack,stack_1,stack_2;
      list<list<BackendDAE.Value>> comp, comps;
      
    case (m,mt,a1,a2,n,i,w,stack,comp)
      equation
        (w > n) = true;
      then
        (i,stack,comp);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      equation
        0 = BackendDAEEXT.getNumber(w);
        (i,stack_1,comps) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        w_1 = w + 1;
        (i,stack_2,comps) = strongConnectMain(m, mt, a1, a2, n, i, w_1, stack_1, comps);
      then
        (i,stack_2,comps);
    case (m,mt,a1,a2,n,i,w,stack,comps)
      equation
        num = BackendDAEEXT.getNumber(w);
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
        BackendDAEEXT.setNumber(v, i_1)  ;
        BackendDAEEXT.setLowLink(v, i_1);
        stack_1 = (v :: stack);
        eqns = reachableNodes(v, m, mt, a1, a2);
        (i_1,stack_2,comps_1) = iterateReachableNodes(eqns, m, mt, a1, a2, i_1, v, stack_1, comps);
        (i_1,stack_3,comp) = checkRoot(m, mt, a1, a2, i_1, v, stack_2);
        comps_2 = consIfNonempty(comp, comps_1);
      then
        (i_1,stack_3,comps_2);
    else
      equation
        Debug.fprint("failtrace", "- BackendDAETransform.strongConnect failed for eqn " +& intString(inInteger5) +& "\n");
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
      BackendDAE.Value var,pos,eqn;
      list<BackendDAE.Value> reachable,reachable_1,reachable_2;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      String eqnstr;
    case (eqn,m,mt,a1,a2)
      equation
        var = a2[eqn];
        reachable = mt[var] "Got the variable that is solved in the equation" ;
        reachable_1 = BackendDAEUtil.removeNegative(reachable) "in which other equations is this variable present ?" ;
        pos = Util.listPosition(eqn, reachable_1) ".. except this one" ;
        reachable_2 = listDelete(reachable_1, pos);
      then
        reachable_2;
    else
      equation
        true = RTOpts.debugFlag("failtrace");
        Debug.fprint("failtrace", "-reachable_nodes failed, eqn: ");
        eqnstr = intString(inInteger1);
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
    
    // empty case
    case ({},m,mt,a1,a2,i,v,stack,comps) then (i,stack,comps);    
    
    // nw is 0
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        0 = BackendDAEEXT.getNumber(w);
        (i,stack,comps_1) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        lv = BackendDAEEXT.getLowLink(v);
        lw = BackendDAEEXT.getLowLink(w);
        minv = intMin(lv, lw);
        BackendDAEEXT.setLowLink(v, minv);
        (i,stack,comps_2) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps_1);
      then
        (i,stack,comps_2);
    
    // nw 
    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        nw = BackendDAEEXT.getNumber(w);
        nv = BackendDAEEXT.getNumber(v);
        (nw < nv) = true;
        true = listMember(w, stack);
        lowlinkv = BackendDAEEXT.getLowLink(v);
        minv = intMin(nw, lowlinkv);
        BackendDAEEXT.setLowLink(v, minv);
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);

    case ((w :: ws),m,mt,a1,a2,i,v,stack,comps)
      equation
        (i,stack,comps_1) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps);
      then
        (i,stack,comps_1);
    
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
        lv = BackendDAEEXT.getLowLink(v);
        nv = BackendDAEEXT.getNumber(v);
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
        topn = BackendDAEEXT.getNumber(top);
        vn = BackendDAEEXT.getNumber(v);
        (topn >= vn) = true;
        (i,stack_1,comp_1) = checkStack(m, mt, a1, a2, i, v, rest, comp);
      then
        (i,stack_1,(top :: comp_1));
    case (m,mt,a1,a2,i,v,stack,comp) then (i,stack,comp);
  end matchcontinue;
end checkStack;

/******************************************
 DAEHandler stuff
 *****************************************/
 
protected function emptyDAEHandlerArg
  output BackendDAE.DAEHandlerArg arg;
protected
  HashTableCG.HashTable ht;
  HashTable3.HashTable dht; 
algorithm
  ht := HashTableCG.emptyHashTable();
  dht := HashTable3.emptyHashTable();
  arg := (BackendDAE.STATEORDER(ht,dht),{});
end emptyDAEHandlerArg;

protected function addStateOrder
  input DAE.ComponentRef cr;
  input DAE.ComponentRef dcr;
  input BackendDAE.StateOrder inStateOrder;
  output BackendDAE.StateOrder outStateOrder;
algorithm
 outStateOrder :=
  matchcontinue (cr,dcr,inStateOrder)
    local
        HashTableCG.HashTable ht,ht1;
        HashTable3.HashTable dht,dht1;   
        DAE.ComponentRef dcr;
        list<DAE.ComponentRef> crlst;
    case (cr,dcr,inStateOrder as BackendDAE.STATEORDER(ht,dht))
      equation
        ht1 = BaseHashTable.add((cr, dcr),ht);
        failure(_ = getDerStateOrder(dcr,inStateOrder));
        dht1 = BaseHashTable.add((dcr, {cr}),dht); 
      then
       BackendDAE.STATEORDER(ht1,dht1);
    case (cr,dcr,inStateOrder as BackendDAE.STATEORDER(ht,dht))
      equation
        ht1 = BaseHashTable.add((cr, dcr),ht);
        crlst = getDerStateOrder(dcr,inStateOrder);
        dht1 = BaseHashTable.add((dcr, cr::crlst),dht); 
      then
       BackendDAE.STATEORDER(ht1,dht1);
  end matchcontinue;    
end addStateOrder;

protected function deleteStateOrder
  input DAE.ComponentRef cr;
  input BackendDAE.StateOrder inStateOrder;
  output BackendDAE.StateOrder outStateOrder;
  output Option<DAE.ComponentRef> outdcr;
algorithm
  (outStateOrder,outdcr) :=
  matchcontinue (cr,inStateOrder)
    local
        HashTableCG.HashTable ht,ht1;
        HashTable3.HashTable dht,dht1;  
        DAE.ComponentRef dcr,cr1;
        list<DAE.ComponentRef> crlst;
        list<tuple<DAE.ComponentRef,DAE.ComponentRef>> tplLst;
    case (cr,inStateOrder as BackendDAE.STATEORDER(ht,dht))
      equation
        dcr = getStateOrder(cr,inStateOrder);
        cr1::{} = getDerStateOrder(dcr,inStateOrder);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("deleteStateOrder ",cr," and ",dcr,"\n")));
        ht1 = BaseHashTable.delete(cr,ht); 
        dht1 = BaseHashTable.delete(dcr,dht); 
      then
       (BackendDAE.STATEORDER(ht1,dht1),SOME(dcr));
    case (cr,inStateOrder as BackendDAE.STATEORDER(ht,dht))
      equation
        dcr = getStateOrder(cr,inStateOrder);
        crlst = getDerStateOrder(dcr,inStateOrder);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("deleteStateOrder ",cr," and update ",dcr,"\n")));
        crlst = Util.listRemoveOnTrue(cr,ComponentReference.crefEqualNoStringCompare,crlst);
        ht1 = BaseHashTable.delete(cr,ht); 
        dht1 = BaseHashTable.add((dcr, crlst),dht); 
      then
       (BackendDAE.STATEORDER(ht1,dht1),SOME(dcr));       
    case (cr,inStateOrder as BackendDAE.STATEORDER(ht,dht))
      equation
        dcr = getStateOrder(cr,inStateOrder);
        failure(_ = getDerStateOrder(dcr,inStateOrder));
        Debug.fcall("bltdump", BackendDump.debugStrCrefStr, (("deleteStateOrder ",cr,"\n")));
        ht1 = BaseHashTable.delete(cr,ht); 
      then
       (BackendDAE.STATEORDER(ht1,dht),SOME(dcr));       
    case (cr,inStateOrder)
      equation
        Debug.fcall("bltdump", BackendDump.debugStrCrefStr, (("deleteStateOrder ",cr," has noting delaited\n")));
      then
        (inStateOrder,NONE());     
  end matchcontinue;  
end deleteStateOrder;

protected function getStateOrder
  input DAE.ComponentRef cr;
  input BackendDAE.StateOrder inStateOrder;
  output DAE.ComponentRef dcr;
protected
  HashTableCG.HashTable ht;
  HashTable3.HashTable dht;  
algorithm
  BackendDAE.STATEORDER(ht,dht) := inStateOrder;
  dcr := BaseHashTable.get(cr,ht);
end getStateOrder;

protected function getDerStateOrder
  input DAE.ComponentRef dcr;
  input BackendDAE.StateOrder inStateOrder;
  output list<DAE.ComponentRef> crlst;
protected
  HashTableCG.HashTable ht;
  HashTable3.HashTable dht;  
algorithm
  BackendDAE.STATEORDER(ht,dht) := inStateOrder;
  crlst := BaseHashTable.get(dcr,dht);
end getDerStateOrder;

protected function addOrgEqn
  input BackendDAE.ConstraintEquations inOrgEqns;
  input Integer e;
  input BackendDAE.Equation inEqn;
  input Boolean b;
  output BackendDAE.ConstraintEquations outOrgEqns;
algorithm
  outOrgEqns :=
  matchcontinue (inOrgEqns,e,inEqn,b)
    local
      list<tuple<BackendDAE.Equation,Boolean>> orgeqns;
      Integer e1;
      Boolean b1;
      BackendDAE.ConstraintEquations rest,orgeqnslst;
    
    case ({},e,inEqn,b) then {(e,{(inEqn,b)})};
    case ((e1,orgeqns)::rest,e,inEqn,b)
      equation
        true = intGt(e1,e);
      then
        (e,{(inEqn,b)})::((e1,orgeqns)::rest);
    case ((e1,orgeqns)::rest,e,inEqn,b)
      equation
        true = intEq(e1,e);
      then
        (e1,(inEqn,b)::orgeqns)::rest;     
    case ((e1,orgeqns)::rest,e,inEqn,b)
      equation
        orgeqnslst = addOrgEqn(rest,e,inEqn,b);
      then
        (e1,orgeqns)::orgeqnslst;            
  end matchcontinue;
end addOrgEqn;

protected function getOrgEqn
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqns;
  input list<tuple<Integer,Integer,Integer>> inOrgEqnLevel;
  output list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> outOrgEqns;
  output list<tuple<Integer,Integer,Integer>> outOrgEqnLevel;
algorithm
  (outOrgEqns,outOrgEqnLevel) :=
  matchcontinue (inOrgEqns,inOrgEqnLevel)
    local
      list<tuple<Integer,Integer,Boolean>> orgeqn;
      Integer e,ep,l;
      Boolean b;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> rest,orgeqns;
      list<tuple<Integer,Integer,Integer>> orgEqnLevel;
    
    case ({},inOrgEqnLevel) then ({},inOrgEqnLevel);
    case ((e,(ep,l,false)::{})::rest,inOrgEqnLevel)
      equation
        (orgeqns,orgEqnLevel) = getOrgEqn(rest,(e,ep,l)::inOrgEqnLevel);
      then
        (orgeqns,orgEqnLevel);      
    case ((e,(ep,l,true)::{})::rest,inOrgEqnLevel)
      equation
        (orgeqns,orgEqnLevel) = getOrgEqn(rest,inOrgEqnLevel);
      then
        (orgeqns,orgEqnLevel);      
    case ((e,(ep,l,false)::orgeqn)::rest,inOrgEqnLevel)
      equation
        (orgeqns,orgEqnLevel) = getOrgEqn(rest,(e,ep,l)::inOrgEqnLevel);
      then
        ((e,orgeqn)::orgeqns,orgEqnLevel);
    case ((e,(ep,l,true)::orgeqn)::rest,inOrgEqnLevel)
      equation
        (orgeqns,orgEqnLevel) = getOrgEqn(rest,inOrgEqnLevel);
      then
        ((e,orgeqn)::orgeqns,orgEqnLevel);
  end matchcontinue;
end getOrgEqn;

protected function getVarsOfOrgEqn
  input BackendDAE.ConstraintEquations inOrgEqns;
  input BackendDAE.Variables inVars;
  output BackendDAE.Variables outVars;
algorithm
  outVars :=
  matchcontinue (inOrgEqns,inVars)
    local
      BackendDAE.Equation eqn;
      list<BackendDAE.Equation> eqns;
      list<BackendDAE.Equation> orgeqn;
      list<tuple<BackendDAE.Equation,Boolean>> orgeqntpl;
      BackendDAE.ConstraintEquations rest;
      BackendDAE.Variables vars,v,vars1;
    
    case ({},_) then BackendDAEUtil.emptyVars();
    case ((_,orgeqntpl)::rest,v)
      equation
        orgeqn = Util.listMap(orgeqntpl,Util.tuple21);
        vars = getVarsOfOrgEqn(rest,v);
        vars1 = BackendEquation.equationsLstVars(orgeqn,v,vars);
      then
        vars1;
  end matchcontinue;
end getVarsOfOrgEqn;

protected function dumpStateOrder
"function: dumpStateOrder
  Prints the state order"
  input BackendDAE.StateOrder inStateOrder;
algorithm
  _:=
  match (inStateOrder)
    local
      String str,len_str;
      Integer len;
      HashTableCG.HashTable ht;
      HashTable3.HashTable dht;
      list<tuple<DAE.ComponentRef,DAE.ComponentRef>> tplLst;
    case (BackendDAE.STATEORDER(ht,dht))
      equation
        print("State Order: (");
        (tplLst) = BaseHashTable.hashTableList(ht);
        str = Util.stringDelimitList(Util.listMap(tplLst,printStateOrderStr),"\n");
        len = listLength(tplLst);
        len_str = intString(len);
        print(len_str);
        print(")\n");
        print("=============\n");
        print(str);
        print("\n");
      then
        ();
  end match;
end dumpStateOrder;

protected function printStateOrderStr "help function to dumpStateOrder"
  input tuple<DAE.ComponentRef,DAE.ComponentRef> tpl;
  output String str;
algorithm
  str := ComponentReference.printComponentRefStr(Util.tuple21(tpl)) +& " -> " +& ComponentReference.printComponentRefStr(Util.tuple22(tpl));
end printStateOrderStr;

protected function replaceStateOrder
"function: replaceState
  author: Frenkel TUD 2011-05"
  input list<Integer> inIntegerLst;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.StateOrder inStateOrd;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE :=
  matchcontinue (inIntegerLst,inBackendDAE,inStateOrd)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie;
      list<BackendDAE.Value> es;
      BackendDAE.Variables v,kv,ev;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      BackendDAE.EventInfo wc;
      BackendDAE.ExternalObjectClasses eoc;
      list<BackendDAE.WhenClause> wclst,wclst1;
      list<BackendDAE.ZeroCrossing> zc;
    case ({},dae,inStateOrd) then (dae);
    case ((e :: es),(dae as BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zc),eoc)),inStateOrd)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        (eqn_1,al1,ae1,wclst1,_) = traverseBackendDAEExpsEqn(eqn, al, ae, wclst, replaceStateOrderExp,(inStateOrd,v));
        eqns_1 = BackendEquation.equationSetnth(eqns,e_1,eqn_1);
        dae = replaceStateOrder(es,BackendDAE.DAE(v,kv,ev,av,eqns_1,seqns,ie,ae1,al1,BackendDAE.EVENT_INFO(wclst1,zc),eoc),inStateOrd);
      then
        (dae);
    case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"-BackendDAETranfrom.replaceStateOrder failed!"}); 
      then
        fail();
  end matchcontinue;
end replaceStateOrder;

protected function replaceStateOrderExp
"function: replaceStateExp
  author: Frenkel TUD 2011-05
 "
  input tuple<DAE.Exp,tuple<BackendDAE.StateOrder,BackendDAE.Variables>> inTpl;
  output tuple<DAE.Exp,tuple<BackendDAE.StateOrder,BackendDAE.Variables>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.StateOrder,BackendDAE.Variables> so;
algorithm
  (e,so) := inTpl;
  outTpl := Expression.traverseExp(e,replaceStateOrderExpFinder,so);
end replaceStateOrderExp;

protected function replaceStateOrderExpFinder
"function: replaceStateOrderExpFinder
  author: Frenkel TUD 2011-05
 "
  input tuple<DAE.Exp,tuple<BackendDAE.StateOrder,BackendDAE.Variables>> inExp;
  output tuple<DAE.Exp,tuple<BackendDAE.StateOrder,BackendDAE.Variables>> outExp;
algorithm
  (outExp) := matchcontinue (inExp)
    local
      DAE.Exp e;
      BackendDAE.StateOrder so;
      DAE.ComponentRef dcr,cr;
      BackendDAE.Variables v;
      
    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(so,v)))
      equation
        dcr = getStateOrder(cr,so);
        e = Expression.crefExp(dcr);
      then
        ((e, (so,v)));    
    case (inExp) then (inExp);

  end matchcontinue;
end replaceStateOrderExpFinder;


/*****************************************
 reduceIndexDynamicStateSelection and stuff
 *****************************************/

public function reduceIndexDynamicStateSelection
"function: reduceIndexDynamicStateSelection
  author: Frenkel TUD"
  input BackendDAE.DAEHandlerJop inJop;
  input BackendDAE.BackendDAE inBackendDAE1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  input BackendDAE.DAEHandlerArg inArg;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2; 
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
  output BackendDAE.DAEHandlerArg outArg;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outAssignments1,outAssignments2,outDerivedAlgs,outDerivedMultiEqn,outArg):=
  matchcontinue (inJop,inBackendDAE1,inIncidenceMatrix2,inIncidenceMatrixT3,inFunctions,inAssignments1,inAssignments2,inDerivedAlgs,inDerivedMultiEqn,inArg)
    local
      list<BackendDAE.Value> eqns,diff_eqns,eqns_1,deqns,reqns,changedeqns,eqnsindxs;
      BackendDAE.BackendDAE dae;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Value nv,nf,stateno,newDummyVar,delta;
      DAE.ComponentRef state,dummy_der;
      list<String> es;
      String es_1;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
      BackendDAE.StateOrder so,so1;
      BackendDAE.ConstraintEquations orgEqnsLst,orgEqnsLst1,orgEqnsLst2;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> orgEqnsLst_1;
      BackendDAE.EquationArray eqnsarr_1,eqnsarr,seqns,ie;
      BackendDAE.Variables v,kv,ev;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      list<BackendDAE.WhenClause> wclst,wclst1;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.ExternalObjectClasses eoc;   
      list<tuple<DAE.ComponentRef,Integer>> states;  
      BackendDAE.Assignments ass1,ass2; 
      array<BackendDAE.Value> vec1,vec2;
      String smeqs;
    case (BackendDAE.REDUCE_INDEX(),dae as BackendDAE.DAE(arrayEqs=ae),m,mt,inFunctions,ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst))
      equation
        eqns = BackendDAEEXT.getMarkedEqns();
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        true = intEq(listLength(eqns_1),0);
        Debug.fcall("bltdump", print, "Reduce Index\n");
        Debug.fcall("bltdump", print, "diff equations: ");
        Debug.fcall("bltdump", BackendDump.debuglst, (diff_eqns,intString));
        Debug.fcall("bltdump", print, "\n");
        Debug.fcall("bltdump", print, "marked equations: ");
        Debug.fcall("bltdump", BackendDump.debuglst, (eqns,intString));
        Debug.fcall("bltdump", BackendDump.dump, dae);
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
        Debug.fcall("bltdump", BackendDump.dumpMatching, vec1);
        Debug.fcall("bltdump", BackendDump.dumpMatching, vec2);   
        BackendDump.dumpIncidenceMatrix(m);
        BackendDump.dumpIncidenceMatrixT(mt);
       Debug.fcall("bltdump", dumpEqnsX, (orgEqnsLst,ae));
      then
        fail();      
    case (BackendDAE.REDUCE_INDEX(),dae,m,mt,inFunctions,ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst))
      equation
        eqns = BackendDAEEXT.getMarkedEqns();
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        Debug.fcall("bltdump", print, "Reduce Index\n");
        Debug.fcall("bltdump", print, "marked equations: ");
        Debug.fcall("bltdump", BackendDump.debuglst, (eqns_1,intString));
        Debug.fcall("bltdump", print, "\n");
        Debug.fcall("bltdump", print, "diff equations: ");
        Debug.fcall("bltdump", BackendDump.debuglst, (diff_eqns,intString));
        Debug.fcall("bltdump", print, "\n");
        smeqs = BackendDump.dumpMarkedEqns(dae, eqns_1);
        Debug.fcall("bltdump", print, smeqs);
        true = intGt(listLength(eqns),0);
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst2) = differentiateEqnsDynamicState(dae,eqns_1,inFunctions,derivedAlgs,derivedMultiEqn,so,m,mt,orgEqnsLst);
      then
        (dae,m,mt,ass1,ass2,derivedAlgs1,derivedMultiEqn1,(so1,orgEqnsLst2));

    case (BackendDAE.STARTSTEP(),dae,m,mt,inFunctions,ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst))
      equation
        Debug.fcall("bltdump", print, "Reduce Index Startstep\n");
        ((so,_)) = BackendEquation.traverseBackendDAEEqns(BackendEquation.daeEqns(dae),traverseStateOrderFinder,(so,BackendVariable.daeVars(dae)));
        Debug.fcall("bltdump", dumpStateOrder, so); 
      then (dae,m,mt,ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst));

    case (BackendDAE.ENDSTEP(),dae as BackendDAE.DAE(arrayEqs=ae),m,mt,inFunctions,ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst))
      equation
         vec1 = assignmentsVector(ass1);
         vec2 = assignmentsVector(ass2);
         Debug.fcall("bltdump", print, "Reduce Index Endstep\n");
         Debug.fcall("bltdump", BackendDump.dumpMatching, vec1);
         Debug.fcall("bltdump", BackendDump.dumpMatching, vec2);   
         Debug.fcall("bltdump", dumpEqnsX, (orgEqnsLst,ae));
         Debug.fcall("bltdump", dumpStateOrder, so);        
         Debug.fcall("bltdump", BackendDump.bltdump, ("reduced ODE:",dae,m,mt,vec1,vec2,{}));
        (dae,m,mt,orgEqnsLst_1) = addOrgEqntoDAE(orgEqnsLst,dae,m,mt,so,inFunctions); 
        (dae,m,mt) = replaceScalarArrayEqns(orgEqnsLst_1,dae,m,mt,inFunctions); 
        (dae,m,mt,ass1,ass2,so,orgEqnsLst_1) = prozessAlliasStates(orgEqnsLst_1,dae,m,mt,ass1,ass2,so,{});         
         Debug.fcall("bltdump", BackendDump.bltdump, ("reduced full ODE",dae,m,mt,vec1,vec2,{}));
         Debug.fcall("bltdump", dumpEqns1X, (orgEqnsLst_1,dae));
         Debug.fcall("bltdump", dumpStateOrder, so);        
         Debug.fcall("bltdump", print, "Select State Candidates\n");
        states = statesCandidates(dae,so,orgEqnsLst);
         Debug.fcall("bltdump", print, "\nCandidates (" +& intString(listLength(states)) +& "): " +& Util.stringDelimitList(Util.listMap(states,dumpStates)," : ") +& "\n");        
         Debug.fcall("bltdump", print, "Select dummy States\n");
        (dae,m,mt,states,ass1,ass2) = selectDummyStates(orgEqnsLst_1,so,dae,m,mt,inFunctions,states,ass1,ass2);  
         vec1 = assignmentsVector(ass1);
         vec2 = assignmentsVector(ass2);
         Debug.fcall("bltdump", BackendDump.bltdump, ("new DAE:",dae,m,mt,vec1,vec2,{}));
     then (dae,m,mt,ass1,ass2,derivedAlgs,derivedMultiEqn,(so,orgEqnsLst));

    case (BackendDAE.REDUCE_INDEX(),dae,m,mt,_,_,_,_,_,_)
      equation
        eqns = BackendDAEEXT.getMarkedEqns();
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
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
        print(Util.stringDelimitList(Util.listMap(BackendDAEEXT.getMarkedVariables(),intString),", "));
        print("\n");
      then
        fail();

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.reduceIndexDummyDerX failed!"});
      then
        fail();

  end matchcontinue;
end reduceIndexDynamicStateSelection;

protected function replaceScalarArrayEqns
"function: replaceScalarArrayEqns
  author: Frenkel TUD"
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqns;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input DAE.FunctionTree inFunctions;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;  
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inOrgEqns,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inFunctions)
    local
      BackendDAE.BackendDAE dae,dae1;
      BackendDAE.IncidenceMatrix m,m1;
      BackendDAE.IncidenceMatrixT mt,mt1; 
      array<list<BackendDAE.Equation>> arrayListeqns;  
      array<BackendDAE.MultiDimEquation> ae; 
      list<Integer> updateeqns;  
    case ({},dae,m,mt,_)
       then (dae,m,mt);
    case (inOrgEqns,dae as BackendDAE.DAE(arrayEqs=ae),m,mt,inFunctions)
      equation
        arrayListeqns = arrayCreate(arrayLength(ae), {});
        arrayListeqns = getScalarArrayEqns(inOrgEqns,dae,arrayListeqns);
        // replace them
        (dae1,updateeqns,_) = BackendDAEOptimize.doReplaceScalarArrayEqns(arrayListeqns,dae);
        // update Incidence matrix
        (m1,mt1) = BackendDAEUtil.updateIncidenceMatrix(dae,m,mt,updateeqns);        
      then
        (dae1,m1,mt1);
  end matchcontinue;
end replaceScalarArrayEqns; 

protected function getScalarArrayEqns
"function: addOrgEqntoDAE
  author: Frenkel TUD"
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqns;
  input BackendDAE.BackendDAE inBackendDAE;
  input array<list<BackendDAE.Equation>> inArrayListeqns;
  output array<list<BackendDAE.Equation>> outArrayListeqns;
algorithm
  outArrayListeqns:=
  matchcontinue (inOrgEqns,inBackendDAE,inArrayListeqns)
    local
      list<tuple<Integer,Integer,Boolean>> eqns;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> rest;
      BackendDAE.BackendDAE dae;
      array<list<BackendDAE.Equation>> arrayListeqns;     
    case ({},dae,arrayListeqns)
       then arrayListeqns;
    case ((_,eqns)::rest,dae,arrayListeqns)
      equation
        arrayListeqns = getScalarArrayEqns1(eqns,dae,arrayListeqns);
        arrayListeqns =  getScalarArrayEqns(rest,dae,arrayListeqns);
      then
        arrayListeqns;
  end matchcontinue;
end getScalarArrayEqns;         
         
protected function getScalarArrayEqns1
"function: addOrgEqntoDAE
  author: Frenkel TUD"
  input list<tuple<Integer,Integer,Boolean>> inOrgEqns;
  input BackendDAE.BackendDAE inBackendDAE;
  input array<list<BackendDAE.Equation>> inArrayListeqns;
  output array<list<BackendDAE.Equation>> outArrayListeqns;
algorithm
  outArrayListeqns:=
  matchcontinue (inOrgEqns,inBackendDAE,inArrayListeqns)
    local
      Integer e,i,e_1;
      BackendDAE.BackendDAE dae;
      list<tuple<Integer,Integer,Boolean>> rest;
      BackendDAE.EquationArray eqnsarr;
      array<BackendDAE.MultiDimEquation> ae;
      array<list<BackendDAE.Equation>> arrayListeqns;
      BackendDAE.MultiDimEquation meqn;
      list<BackendDAE.Equation> eqns;
    case ({},inBackendDAE,arrayListeqns) 
      then arrayListeqns;
    case ((e,_,_)::rest,dae as BackendDAE.DAE(orderedEqs=eqnsarr,arrayEqs=ae),arrayListeqns)
      equation
        e_1 = e - 1;
        BackendDAE.ARRAY_EQUATION(index=i) = BackendDAEUtil.equationNth(eqnsarr, e_1);
        {} = arrayListeqns[i+1];
        meqn = ae[i+1];
        eqns = BackendDAEOptimize.getScalarArrayEqns(meqn);
        arrayListeqns = arrayUpdate(arrayListeqns,i+1,eqns);
        arrayListeqns = getScalarArrayEqns1(rest,dae,arrayListeqns);
      then
        arrayListeqns;
    case ((_,_,_)::rest,dae,arrayListeqns)
      equation
        arrayListeqns = getScalarArrayEqns1(rest,dae,arrayListeqns);
      then
        arrayListeqns;       
  end matchcontinue;
end getScalarArrayEqns1;   

protected function traverseStateOrderFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Equation, tuple<BackendDAE.StateOrder,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Equation, tuple<BackendDAE.StateOrder,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Equation e;
      BackendDAE.StateOrder so,so1;
      BackendDAE.Variables v;
      DAE.ComponentRef cr,dcr;
    case ((e,(so,v)))
      equation
        (cr,dcr,_,_,false) = BackendEquation.derivativeEquation(e);
        true = BackendVariable.isState(cr,v);
        so1 = addStateOrder(cr,dcr,so);
      then ((e,(so1,v)));
    case inTpl then inTpl;
  end matchcontinue;
end traverseStateOrderFinder;

protected function differentiateEqnsDynamicState
"function: differentiateEqnsDynamicState
  author: Frenkel TUD"
  input BackendDAE.BackendDAE inBackendDAE1;
  input list<Integer> inIntegerLst6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  input BackendDAE.ConstraintEquations inOrgEqnsLst;
  output BackendDAE.BackendDAE outBackendDAE1;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
  output BackendDAE.StateOrder outStateOrd;
  output BackendDAE.ConstraintEquations outOrgEqnsLst;
algorithm
  (outBackendDAE1,outM,outMT,outDerivedAlgs,outDerivedMultiEqn,outStateOrd,outOrgEqnsLst):=
  matchcontinue (inBackendDAE1,inIntegerLst6,inFunctions,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,inM,inMT,inOrgEqnsLst)
    local
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.Value e_1,e,e1,i,l,newvar,stateno,assarg,i1,sl,eqnss,eqnss1;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.EquationArray eqns_1,eqns,seqns,ie;
      list<BackendDAE.Value> es,lst,slst,ilst,eqnslst;
      BackendDAE.Variables v,kv,ev,v1;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      array<DAE.Algorithm> al,al1;
      BackendDAE.EventInfo einfo;
      list<BackendDAE.WhenClause> wclst,wclst1;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.ExternalObjectClasses eoc;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
      BackendDAE.StateOrder so,so1;
      DAE.ComponentRef cr,dcr,cr1;
      BackendDAE.ConstraintEquations orgEqnsLst;
      list<BackendDAE.Var> vlst;
      list<DAE.ComponentRef> crlst;
      list<tuple<DAE.ComponentRef,Integer>> states;
      list<DAE.Exp> jac,jac1;
      DAE.Exp exp1,exp2;
      Boolean negate;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrix mt;
    case (dae,{},_,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,m,mt,inOrgEqnsLst) then (dae,m,mt,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,inOrgEqnsLst);
    case ((dae as BackendDAE.DAE(orderedVars=v,orderedEqs=eqns)),(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,m,mt,inOrgEqnsLst)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        // derivative Eqn?
        (cr,dcr,_,_,false) = BackendEquation.derivativeEquation(eqn);
        true = BackendVariable.isState(cr,v);
        //true = BackendVariable.isState(dcr,v);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("Add State Order "),cr," : ",dcr,"\n"));
        so = addStateOrder(cr,dcr,inStateOrd);
        BackendDAEEXT.markDifferentiated(e);
        orgEqnsLst = addOrgEqn(inOrgEqnsLst,e,eqn,true);
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst) = differentiateEqnsDynamicState(dae,  es, inFunctions,inDerivedAlgs,inDerivedMultiEqn,so,m,mt,orgEqnsLst);
      then
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst);
    case ((dae as BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zc),eoc)),(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn,inStateOrd,m,mt,inOrgEqnsLst)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,_) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        (eqn_1,al1,ae1,wclst,(so,_)) = traverseBackendDAEExpsEqn(eqn_1, al1, ae1, wclst, replaceStateOrderExp,(inStateOrd,v));
        eqnss = BackendDAEUtil.equationSize(eqns);
        (eqn_1,al1,ae1,wclst1,(v1,eqns,so,ilst)) = traverseBackendDAEExpsEqn(eqn_1,al1,ae1,wclst,replaceDummyDerOthersExpDynamicState,(v,eqns,so,{}));
        eqnss1 = BackendDAEUtil.equationSize(eqns);
        eqnslst = Util.listIntRange2(eqnss,eqnss1);
        so = checkDerivativeEqn(eqn_1,v1,so);
        so = checkAliasStateEqn(eqn_1,v1,so);
        Debug.fcall("bltdump", debugdifferentiateEqns,(eqn,eqn_1)); 
        eqns_1 = BackendEquation.equationSetnth(eqns,e_1,eqn_1);
        dae1 = BackendDAE.DAE(v1,kv,ev,av,eqns_1,seqns,ie,ae1,al1,BackendDAE.EVENT_INFO(wclst1,zc),eoc);
        Debug.fcall("bltdump", print, "Update Incidence Matrix: ");
        Debug.fcall("bltdump", BackendDump.debuglst,(e::eqnslst,intString));
        Debug.fcall("bltdump", print, "\n");        
        (m,mt) = BackendDAEUtil.updateIncidenceMatrix(dae1, m, mt, e::eqnslst);
        (dae2,m,mt) = updateDummyStateIncidenceMatrix(ilst,dae1,m,mt);
        orgEqnsLst = addOrgEqn(inOrgEqnsLst,e,eqn,false);
        (dae2,m,mt,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst) = differentiateEqnsDynamicState(dae2, es, inFunctions,derivedAlgs,derivedMultiEqn,so,m,mt,orgEqnsLst);
      then
        (dae2,m,mt,derivedAlgs1,derivedMultiEqn1,so1,orgEqnsLst);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"-BackendDAETranfrom.differentiateEqnsDynamicState failed!"}); 
      then
        fail();
  end matchcontinue;
end differentiateEqnsDynamicState;

public function replaceDummyDerOthersExpDynamicState
"function: replaceDummyDerOthersExpDynamicState
  author: Frenkel TUD"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>>> inTpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>> vars;
algorithm
  (e,vars) := inTpl;
  outTpl := Expression.traverseExp(e,replaceDummyDerOthersExpDynamicStateFinder,vars);
end replaceDummyDerOthersExpDynamicState;

protected function replaceDummyDerOthersExpDynamicStateFinder
"function: replaceDummyDerOthersExpDynamicStateFinder
  author: Frenkel TUD"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>>> inExp;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,BackendDAE.EquationArray,BackendDAE.StateOrder,list<Integer>>> outExp;
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
      DAE.ComponentRef dummyder,cr;
      DAE.ElementSource source "the source of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAE.Subscript> lstSubs;
      Integer i;
      list<Integer> ilst;
      Option<DAE.Exp> quantity,unit,displayUnit;
      tuple<Option<DAE.Exp>, Option<DAE.Exp>> min;
      Option<DAE.Exp> initial_,fixed,nominal,equationBound;
      Option<Boolean> isProtected;
     Option<Boolean> finalPrefix;    
     BackendDAE.EquationArray eqns,eqns_1;  
     BackendDAE.StateOrder so,so1;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.STATE(),a,b,c,d,lstSubs,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_::_) = BackendVariable.getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        //dummyder = ComponentReference.crefPrefixDer(cr);
        dummyder = ComponentReference.makeCrefQual("$_DER",DAE.ET_REAL(),{},cr);
        (eqns_1,so1) = addDummyStateEqn(vars,eqns,cr,dummyder,so);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.STATE(), a, b, NONE(), NONE(), lstSubs, 0, source, SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),SOME(DAE.NEVER()),NONE(),NONE(),NONE())), comment, flowPrefix, streamPrefix), vars);
        e = Expression.makeCrefExp(dummyder,DAE.ET_REAL());
        i = BackendVariable.varsSize(vars_1);
      then
        ((DAE.CALL(Absyn.IDENT("der"),{e},DAE.callAttrBuiltinReal), (vars_1,eqns_1,so1,i::ilst)));

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,initial_,fixed,nominal,_,equationBound,isProtected,finalPrefix)),comment,flowPrefix,streamPrefix) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.STATE(),a,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,initial_,fixed,nominal,SOME(DAE.NEVER()),equationBound,isProtected,finalPrefix)),comment,flowPrefix,streamPrefix), vars);
      then
        ((e, (vars_1,eqns,so,i::ilst)));
    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,b,c,d,lstSubs,g,source,NONE(),comment,flowPrefix,streamPrefix) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.STATE(),a,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),SOME(DAE.NEVER()),NONE(),NONE(),NONE())),comment,flowPrefix,streamPrefix), vars);
      then
        ((e, (vars_1,eqns,so,i::ilst)));        

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,initial_,fixed,nominal,_,equationBound,isProtected,finalPrefix)),comment,flowPrefix,streamPrefix) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.STATE(),a,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(quantity,unit,displayUnit,min,initial_,fixed,nominal,SOME(DAE.NEVER()),equationBound,isProtected,finalPrefix)),comment,flowPrefix,streamPrefix), vars);
      then
        ((e, (vars_1,eqns,so,i::ilst)));

    case ((e as DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,eqns,so,ilst)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,b,c,d,lstSubs,g,source,NONE(),comment,flowPrefix,streamPrefix) :: _),i::_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.STATE(),a,b,c,d,lstSubs,g,source,SOME(DAE.VAR_ATTR_REAL(NONE(),NONE(),NONE(),(NONE(),NONE()),NONE(),NONE(),NONE(),SOME(DAE.NEVER()),NONE(),NONE(),NONE())),comment,flowPrefix,streamPrefix), vars);
      then
        ((e, (vars_1,eqns,so,i::ilst)));

    case inExp then inExp;

  end matchcontinue;
end replaceDummyDerOthersExpDynamicStateFinder;

protected function addDummyStateEqn "function: addDummyStateEqn
  author: Frenkel TUD 2011-05"
  input BackendDAE.Variables inVars;
  input BackendDAE.EquationArray inEqns;
  input DAE.ComponentRef inCr;
  input DAE.ComponentRef inDCr;
  input BackendDAE.StateOrder inSo;
  output BackendDAE.EquationArray outEqns;
  output BackendDAE.StateOrder outSo;
algorithm
  (outEqns,outSo) := matchcontinue (inVars,inEqns,inCr,inDCr,inSo)
    local
      BackendDAE.EquationArray eqns1;
      DAE.Exp ecr,edcr,c;
      BackendDAE.StateOrder so;
    case (inVars,inEqns,inCr,inDCr,inSo)
      equation
        (_::_,_::_) = BackendVariable.getVar(inDCr, inVars);
      then 
        (inEqns,inSo);
    case (inVars,inEqns,inCr,inDCr,inSo)
      equation
        ecr = Expression.makeCrefExp(inCr,DAE.ET_REAL());
        edcr = Expression.makeCrefExp(inDCr,DAE.ET_REAL());
        c = DAE.CALL(Absyn.IDENT("der"),{ecr},DAE.callAttrBuiltinReal);
        eqns1 = BackendEquation.equationAdd(BackendDAE.EQUATION(edcr,c,DAE.emptyElementSource),inEqns);
        so = addStateOrder(inCr,inDCr,inSo);
      then 
        (eqns1,so);
  end matchcontinue;
end addDummyStateEqn;

protected function updateDummyStateIncidenceMatrix "function: updateDummyStateIncidenceMatrix
  author: Frenkel TUD 2011-05"
  input list<Integer> inILst;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inM;
  input BackendDAE.IncidenceMatrixT inMT;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outM;
  output BackendDAE.IncidenceMatrixT outMT;  
algorithm
  (outBackendDAE,outM,outMT) := matchcontinue (inILst,inBackendDAE,inM,inMT)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      Integer i;
      list<Integer> rest,eqns; 
    case ({},dae,m,mt)
      then 
        (dae,m,mt);
    case (i::rest,dae,m,mt)
      equation
        eqns = mt[i];
        Debug.fcall("bltdump", print, "Update Incidence Matrix: ");
        Debug.fcall("bltdump", BackendDump.debuglst,(eqns,intString));
        Debug.fcall("bltdump", print, "\n");
        (m,mt) = BackendDAEUtil.updateIncidenceMatrix(dae, m, mt, eqns);    
        (dae,m,mt) = updateDummyStateIncidenceMatrix(rest,dae,m,mt);  
      then 
        (dae,m,mt);
  end matchcontinue;
end updateDummyStateIncidenceMatrix;

protected function checkDerivativeEqn
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables v;
  input BackendDAE.StateOrder inStateOrd;
  output BackendDAE.StateOrder outStateOrd;
algorithm
  outStateOrd := matchcontinue (eqn,v,inStateOrd)
    local  
      BackendDAE.StateOrder so;
      DAE.ComponentRef cr,dcr;
    case (eqn,v,inStateOrd)
      equation
        // derivative Eqn?
        (cr,dcr,_,_,false) = BackendEquation.derivativeEquation(eqn);
        true = BackendVariable.isState(cr,v);
        //true = BackendVariable.isState(dcr,v);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("Add State Order "),cr," : ",dcr,"\n"));
        so = addStateOrder(cr,dcr,inStateOrd);
      then
        so;
    case (eqn,v,inStateOrd)
      then
        inStateOrd;        
  end matchcontinue;        
end checkDerivativeEqn;

protected function checkAliasStateEqn
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables v;
  input BackendDAE.StateOrder inStateOrd;
  output BackendDAE.StateOrder outStateOrd;
algorithm
  outStateOrd := matchcontinue (eqn,v,inStateOrd)
    local  
      BackendDAE.StateOrder so;
      DAE.ComponentRef cr,dcr;
    case (eqn,v,inStateOrd)
      equation
        // derivative Eqn?
        (cr,dcr,_,_,false) = BackendEquation.derivativeEquation(eqn);
        true = BackendVariable.isState(cr,v);
        //true = BackendVariable.isState(dcr,v);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("Add State Order "),cr," : ",dcr,"\n"));
        so = addStateOrder(cr,dcr,inStateOrd);
      then
        so;
    case (eqn,v,inStateOrd)
      then
        inStateOrd;        
  end matchcontinue;        
end checkAliasStateEqn;

protected function statesCandidates
"function: statesCandidates
  author: Frenkel TUD 2011-05"
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.ConstraintEquations orgEqnsLst;
  output list<tuple<DAE.ComponentRef,Integer>> outStates;
algorithm
  outStates := match (inBackendDAE,inStateOrd,orgEqnsLst)
    local
      list<tuple<DAE.ComponentRef,Integer>> cr_lst;
      BackendDAE.Variables v,v1;
    case (BackendDAE.DAE(orderedVars = v),inStateOrd,orgEqnsLst)
      equation
        v1 = getVarsOfOrgEqn(orgEqnsLst,v);
        ((cr_lst,_,_,_,_)) = BackendVariable.traverseBackendDAEVars(v,traversingisStateVarCrefFinder,({},1,inStateOrd,v,v1));        
     then
        cr_lst;
  end match;
end statesCandidates;

protected function traversingisStateVarCrefFinder
"autor: Frenkel TUD 2010-11"
 input tuple<BackendDAE.Var, tuple<list<tuple<DAE.ComponentRef,Integer>>,Integer,BackendDAE.StateOrder,BackendDAE.Variables,BackendDAE.Variables>> inTpl;
 output tuple<BackendDAE.Var, tuple<list<tuple<DAE.ComponentRef,Integer>>,Integer,BackendDAE.StateOrder,BackendDAE.Variables,BackendDAE.Variables>> outTpl;
algorithm
  outTpl:=
  matchcontinue (inTpl)
    local
      BackendDAE.Var v;
      list<tuple<DAE.ComponentRef,Integer>> cr_lst;
      DAE.ComponentRef cr,dcr;
      BackendDAE.StateOrder so;
      BackendDAE.Variables vars,vars1;
      Integer i,j,k;
    case ((v,(cr_lst,i,so,vars,vars1)))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        failure(_ =  getStateOrder(cr,so));
        (_::_,k::_) = BackendVariable.getVar(cr,vars);
      then ((v,((cr,k)::cr_lst,i+1,so,vars,vars1)));
    case ((v,(cr_lst,i,so,vars,vars1)))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        dcr =  getStateOrder(cr,so);
        failure( (_,_) = BackendVariable.getVar(dcr,vars1));
        (_::_,k::_) = BackendVariable.getVar(cr,vars);
      then ((v,((cr,k)::cr_lst,i+1,so,vars,vars1)));        
    case ((v,(cr_lst,i,so,vars,vars1)))
      equation
        true = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        dcr =  getStateOrder(cr,so);
        false = BackendVariable.isState(dcr,vars);
        failure(_ =  getStateOrder(dcr,so));
        (_::_,k::_) = BackendVariable.getVar(cr,vars);
      then ((v,((cr,k)::cr_lst,i+1,so,vars,vars1)));   
    case ((v,(cr_lst,i,so,vars,vars1)))
      equation
        false = BackendVariable.isStateVar(v);
        cr = BackendVariable.varCref(v);
        dcr =  getStateOrder(cr,so);
        failure(_ =  getStateOrder(dcr,so));
        (_::_,k::_) = BackendVariable.getVar(cr,vars);
      then ((v,((cr,k)::cr_lst,i+1,so,vars,vars1)));             
    case ((v,(cr_lst,i,so,vars,vars1))) then ((v,(cr_lst,i+1,so,vars,vars1)));
  end matchcontinue;
end traversingisStateVarCrefFinder;

protected function removeNonStatesFromCandidates
"function: removeNonStatesFromCandidates
  author: Frenkel TUD 2011-05"
  input tuple<DAE.ComponentRef,Integer> inTpl;
  input BackendDAE.Variables inVars;
  output Boolean outB;
algorithm
  outB := matchcontinue (inTpl,inVars)
    local
      DAE.ComponentRef cr;
      Integer i;
      BackendDAE.Variables v;
      Boolean b;
    case ((cr,i),v)
      equation
        b = BackendVariable.isState(cr,v);
      then
        b;
  end matchcontinue;
end removeNonStatesFromCandidates;

protected function selectDummyStates
"function: selectDummyStates
  author: Frenkel TUD"
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqns;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input DAE.FunctionTree inFunctionTree;
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;  
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output list<tuple<DAE.ComponentRef,Integer>> outStates; 
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;  
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outStates,outAssignments1,outAssignments2):=
  matchcontinue (inOrgEqns,inStateOrd,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inFunctionTree,inStates,inAssignments1,inAssignments2)
    local
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> orgEqns,orgEqns1;
      list<tuple<Integer,Integer,Integer>> orgEqnLevel;

      BackendDAE.BackendDAE dae,dae1,dae2;
      list<tuple<DAE.ComponentRef,Integer>> states,states1,states2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Assignments ass1,ass2;
      array<BackendDAE.MultiDimEquation> ae;
      list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> dummystates;
      list<list<tuple<Integer,Option<DAE.Exp>>>> sysjac;
      array<list<tuple<Integer,Option<DAE.Exp>>>> arraysysjac;
    case ({},_,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inFunctionTree,inStates,ass1,ass2) then (inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inStates,ass1,ass2);
    case (orgEqns,inStateOrd,dae as BackendDAE.DAE(arrayEqs=ae),m,mt,inFunctionTree,inStates,ass1,ass2)
      equation
        Debug.fcall("bltdump", print, "Get OrgEqn Level\n");
        (orgEqns1,orgEqnLevel) = getOrgEqn(orgEqns,{});
        Debug.fcall("bltdump", print, "remove NonStates From Candidates\n");
        states1 = Util.listSelect1(inStates,BackendVariable.daeVars(dae),removeNonStatesFromCandidates);
        states1 = sortDummyState(states1,dae,m,mt);
        Debug.fcall("bltdump", print, "\nCandidates (" +& intString(listLength(states1)) +& "): " +& Util.stringDelimitList(Util.listMap(states1,dumpStates)," : ") +& "\n"); 
        Debug.fcall("bltdump", print, "select Dummy States for Level\n");
        (sysjac,orgEqnLevel) = calculateJacobianSystem(orgEqnLevel,dae,states1);
        (dae1,m,mt,ass1,ass2) = prozessEqnsLevel(orgEqnLevel,sysjac,inStateOrd,dae,m,mt,ass1,ass2,inFunctionTree,states1);
        Debug.fcall("bltdump", print, "update State Candidates\n");
        states = updateStateCandidates1(inStates,inStateOrd,BackendVariable.daeVars(dae));
        Debug.fcall("bltdump", print, "selectDummyStates next\n");
        (dae2,m,mt,states2,ass1,ass2) = selectDummyStates(orgEqns1,inStateOrd,dae1,m,mt,inFunctionTree,states,ass1,ass2);
      then
        (dae2,m,mt,states2,ass1,ass2);
  end matchcontinue;
end selectDummyStates;

protected function sortDummyState
"function: sortDummyState
  author: Frenkel TUD"
  input list<tuple<DAE.ComponentRef,Integer>> inStates;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<tuple<DAE.ComponentRef,Integer>> outStates;
algorithm
  outStates:=
  matchcontinue (inStates,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<DAE.ComponentRef> varCrefs;
      list<Integer> varIndices;
      DAE.ComponentRef s;
      BackendDAE.Value sn;
      BackendDAE.Variables vars,knvars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EquationArray eqns;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;
      BackendDAE.BackendDAE dae;
      list<tuple<DAE.ComponentRef,Integer>> states;

    case (inStates,BackendDAE.DAE(orderedVars=vars,knownVars=knvars,orderedEqs = eqns),m,mt)
      equation
        varCrefs = Util.listMap(inStates,Util.tuple21);
        varIndices = Util.listMap(inStates,Util.tuple22);
        prioTuples = calculateVarPriorities(varCrefs,varIndices,vars,knvars,eqns,m,mt);
        prioTuples = Util.sort(prioTuples,sortprioTuples);
        states = Util.listMap(prioTuples,Util.tuple312);
      then states;

    case ({},dae,_,_)
      equation
        print("Error, sortDummyStateDAE:");
        //dump(dae);
      then
        fail();

  end matchcontinue;
end sortDummyState;

protected function sortprioTuples
  input tuple<DAE.ComponentRef,Integer,Real> inTpl1;
  input tuple<DAE.ComponentRef,Integer,Real> inTpl2;
  output Boolean b;
algorithm
  b:= realGt(Util.tuple33(inTpl1),Util.tuple33(inTpl2));
/*  match (inTpl1,inTpl2)
    local
      Real l,l1;
    case ((_,_,l),(_,_,l1))
      then
        realGt(l,l1); 
  end match;
*/end sortprioTuples;

protected function sortOrgEqnLevel
  input tuple<tuple<Integer,Integer,Integer>,list<tuple<Integer,Option<DAE.Exp>>>> inOrgEqnLevel;
  input tuple<tuple<Integer,Integer,Integer>,list<tuple<Integer,Option<DAE.Exp>>>> inOrgEqnLevel1;
  output Boolean b;
algorithm
  b:=
  match (inOrgEqnLevel,inOrgEqnLevel1)
    local
      Integer l,l1,i,i1,i_1,i1_1;
      list<tuple<Integer,Option<DAE.Exp>>> eqnjac,eqnjac1;
    case (((_,_,l),eqnjac),((_,_,l1),eqnjac1))
      equation
        (i,i1) = analyseEqnJac(eqnjac);       
        (i_1,i1_1) = analyseEqnJac(eqnjac1);       
      then
        sortOrgEqnLevel1(i,i1,i_1,i1_1); 
  end match;
end sortOrgEqnLevel;

protected function sortOrgEqnLevel1
  input Integer inInt1;
  input Integer inInt2;
  input Integer inInt3;
  input Integer inInt4;
  output Boolean b;
algorithm
  b:=
  matchcontinue (inInt1,inInt2,inInt3,inInt4)
    local
      Integer i,i1;
    case (i,0,i1,0)
      then
        intGt(i,i1); 
    case (_,0,_,i)
      equation
        true = intGt(i,0);
      then
        true; 
    case (_,i,_,0)
      equation
        true = intGt(i,0);
      then
        false;
    case (_,i,_,i1)
      then
        intGt(i,i1);
  end matchcontinue;
end sortOrgEqnLevel1;

protected function analyseEqnJac
  input list<tuple<Integer,Option<DAE.Exp>>> inEqnJac;
  output Integer outInt1;
  output Integer outInt2;
algorithm
  (outInt1,outInt2):=
  match (inEqnJac)
    local
      list<tuple<Integer,Option<DAE.Exp>>> rest;
      Integer i,i1;
    case ({}) then (0,0);
    case ((_,NONE())::rest)
      equation
        (i,i1) = analyseEqnJac(rest);
      then
        (i+1,i1); 
    case ((_,SOME(_))::rest)
      equation
        (i,i1) = analyseEqnJac(rest);
      then
        (i,i1+1); 
  end match;
end analyseEqnJac;
         
protected function addOrgEqntoDAE
"function: addOrgEqntoDAE
  author: Frenkel TUD"
  input BackendDAE.ConstraintEquations inOrgEqns;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.StateOrder inStateOrd; 
  input DAE.FunctionTree inFunctions;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;  
  output list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> outOrgEqns;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outOrgEqns):=
  matchcontinue (inOrgEqns,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inStateOrd,inFunctions)
    local
      list<tuple<BackendDAE.Equation,Boolean>> eqns;
      BackendDAE.ConstraintEquations rest;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m,m1,m2;
      BackendDAE.IncidenceMatrixT mt,mt1,mt2;      
      Integer e;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> orgeqns;
      list<tuple<Integer,Integer,Boolean>> eqns_1;
      BackendDAE.StateOrder so;
    case ({},dae,m,mt,_,_)
       then (dae,m,mt,{});
    case ((e,eqns)::rest,dae,m,mt,so,inFunctions)
      equation
        (dae1,m1,mt1,eqns_1) = addOrgEqntoDAE1(eqns,dae,m,mt,so,inFunctions,e);
        (dae2,m2,mt2,orgeqns) =  addOrgEqntoDAE(rest,dae1,m1,mt1,so,inFunctions);
      then
        (dae2,m2,mt2,(e,eqns_1)::orgeqns);
  end matchcontinue;
end addOrgEqntoDAE;         
         
protected function addOrgEqntoDAE1
"function: addOrgEqntoDAE
  author: Frenkel TUD"
  input list<tuple<BackendDAE.Equation,Boolean>> inOrgEqns;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;  
  input BackendDAE.StateOrder inStateOrd;  
  input DAE.FunctionTree inFunctions;
  input Integer e;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;  
  output list<tuple<Integer,Integer,Boolean>> outOrgEqns;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outOrgEqns):=
  matchcontinue (inOrgEqns,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inStateOrd,inFunctions,e)
    local
      Integer ep,l;
      BackendDAE.Equation orgeqn;
      list<tuple<BackendDAE.Equation,Boolean>> rest;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m,m1,m2;
      BackendDAE.IncidenceMatrixT mt,mt1,mt2;
      list<tuple<Integer,Integer,Boolean>> orgEqnslst;
      list<DAE.ComponentRef> states;
      BackendDAE.StateOrder so;
      BackendDAE.EquationArray eqnsarr,seqns,ie;
      BackendDAE.Variables v,kv,ev;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      list<BackendDAE.WhenClause> wclst;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.ExternalObjectClasses eoc;      
    case ({},inBackendDAE,m,mt,_,_,_) 
      then (inBackendDAE,m,mt,{});
    case ((orgeqn,false)::rest,dae as BackendDAE.DAE(v,kv,ev,av,eqnsarr,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zc),eoc),m,mt,so,inFunctions,e)
      equation
        (orgeqn,al,ae,wclst,(so,_)) = traverseBackendDAEExpsEqn(orgeqn, al, ae, wclst, replaceStateOrderExp,(so,v));
        // add the equations     
        (eqnsarr,ae) = addOrgEqntoDAE2(orgeqn,eqnsarr,ae,inFunctions); 
        ep = arrayLength(m)+1;
        dae1 = BackendDAE.DAE(v,kv,ev,av,eqnsarr,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zc),eoc);
        (m1,mt1) = BackendDAEUtil.updateIncidenceMatrix(dae1, m, mt, {ep});
        states = BackendEquation.equationsStates({orgeqn},BackendVariable.daeVars(dae));
        l = listLength(states);
        // next 
        (dae2,m2,mt2,orgEqnslst) = addOrgEqntoDAE1(rest,dae1,m1,mt1,so,inFunctions,e);
      then
        (dae2,m2,mt2,(ep,l,false)::orgEqnslst);
    case ((orgeqn,true)::rest,dae,m,mt,so,inFunctions,e)
      equation
        // next 
        (dae2,m2,mt2,orgEqnslst) = addOrgEqntoDAE1(rest,dae,m,mt,so,inFunctions,e);
      then
        (dae2,m2,mt2,(e,0,true)::orgEqnslst);

  end matchcontinue;
end addOrgEqntoDAE1;         

protected function addOrgEqntoDAE2
"function: addOrgEqntoDAE
  author: Frenkel TUD"
  input BackendDAE.Equation inOrgEqn;
  input BackendDAE.EquationArray inEqnsarr;
  input array<BackendDAE.MultiDimEquation> inAE;
  input DAE.FunctionTree inFunctions;
  output BackendDAE.EquationArray outEqnsarr;
  output array<BackendDAE.MultiDimEquation> outAE;
algorithm
  (outEqnsarr,outAE):=
  matchcontinue (inOrgEqn,inEqnsarr,inAE,inFunctions)
    local
      Integer i;
      BackendDAE.Equation orgeqn;
      BackendDAE.EquationArray eqnsarr;
      array<BackendDAE.MultiDimEquation> ae;
      BackendDAE.MultiDimEquation me;
    case (orgeqn as BackendDAE.ARRAY_EQUATION(index=i),eqnsarr,ae,inFunctions)
      equation
        SOME(orgeqn) = Inline.inlineEqOpt(SOME(orgeqn),(SOME(inFunctions),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}));
        SOME(orgeqn) = Inline.inlineEqOpt(SOME(orgeqn),(SOME(inFunctions),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}));
        me = ae[i+1];
        me = Inline.inlineMultiDimEqs(me,(SOME(inFunctions),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}));
        ae = arrayUpdate(ae,i+1,me);
        eqnsarr = BackendEquation.equationAdd(orgeqn,eqnsarr);
      then
        (eqnsarr,ae);
    case (orgeqn,eqnsarr,ae,inFunctions)
      equation
        SOME(orgeqn) = Inline.inlineEqOpt(SOME(orgeqn),(SOME(inFunctions),{DAE.NORM_INLINE(),DAE.AFTER_INDEX_RED_INLINE()}));
        eqnsarr = BackendEquation.equationAdd(orgeqn,eqnsarr);
      then
        (eqnsarr,ae);
  end matchcontinue;
end addOrgEqntoDAE2;   

protected function prozessAlliasStates
"function: prozessAlliasStates
  author: Frenkel TUD"
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqns;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT; 
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;  
  input BackendDAE.StateOrder inStateOrd; 
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqns1;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;  
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;  
  output BackendDAE.StateOrder outStateOrd; 
  output list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> outOrgEqns;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outAssignments1,outAssignments2,outStateOrd,outOrgEqns):=
  matchcontinue (inOrgEqns,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2,inStateOrd,inOrgEqns1)
    local
      list<tuple<Integer,Integer,Boolean>> eqns,eqns_1;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> rest,orgeqns,orgeqns1,orgeqns1_1;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m,m1,m2;
      BackendDAE.IncidenceMatrixT mt,mt1,mt2;      
      Integer e;
      BackendDAE.StateOrder so,so1,so2;
      BackendDAE.Assignments ass1,ass2;
    case ({},dae,m,mt,ass1,ass2,so,orgeqns1) then (dae,m,mt,ass1,ass2,so,orgeqns1);
    case ((e,eqns)::rest,dae,m,mt,ass1,ass2,so,orgeqns)
      equation
        (dae1,m1,mt1,ass1,ass2,so1,eqns_1,rest,orgeqns) = prozessAlliasStates1(eqns,dae,m,mt,ass1,ass2,so,{},rest,orgeqns);
        eqns_1 = listReverse(eqns_1);
        orgeqns1 = Util.listConsOnTrue(intGt(listLength(eqns_1),0),(e,eqns_1),orgeqns);
        (dae2,m2,mt2,ass1,ass2,so2,orgeqns1_1) =  prozessAlliasStates(rest,dae1,m1,mt1,ass1,ass2,so1,orgeqns1);
      then
        (dae2,m2,mt2,ass1,ass2,so2,orgeqns1_1);
      else
      equation
        print("prozessAlliasStates failed!\n");
      then 
        fail();         
  end matchcontinue;
end prozessAlliasStates;   

protected function prozessAlliasStates1
"function: prozessAlliasStates1
  author: Frenkel TUD"
  input list<tuple<Integer,Integer,Boolean>> inOrgEqns;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;  
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;  
  input BackendDAE.StateOrder inStateOrd;  
  input list<tuple<Integer,Integer,Boolean>> inOrgEqns1;
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqnsLst1;
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqnsLst2;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;  
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;   
  output BackendDAE.StateOrder outStateOrd;
  output list<tuple<Integer,Integer,Boolean>> outOrgEqns;
  output list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> outOrgEqnsLst1;
  output list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> outOrgEqnsLst2;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outAssignments1,outAssignments2,outStateOrd,outOrgEqns,outOrgEqnsLst1,outOrgEqnsLst2):=
  matchcontinue (inOrgEqns,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2,inStateOrd,inOrgEqns1,inOrgEqnsLst1,inOrgEqnsLst2)
    local
      Integer ep,l,stateno,ev,ast,e_1;
      Boolean b;
      BackendDAE.Equation orgeqn;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m,m1,m2;
      BackendDAE.IncidenceMatrixT mt,mt1,mt2;
      list<tuple<Integer,Integer,Boolean>> rest,orgEqnslst;
      DAE.ComponentRef cr,dcr,cr1,scr;
      Option<DAE.ComponentRef> ocr;
      list<BackendDAE.Var> vlst;
      list<DAE.ComponentRef> crlst,states;      
      BackendDAE.StateOrder so,so1,so2;
      BackendDAE.Variables v;
      BackendDAE.EquationArray eqns;
      DAE.Exp exp1,exp2,exp;
      Boolean negate;
      list<BackendDAE.Value> slst;
      BackendDAE.Assignments ass1,ass2;
      BackendVarTransform.VariableReplacements repl;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> oe,oe1;
    case ({},inBackendDAE,m,mt,ass1,ass2,so,orgEqnslst,inOrgEqnsLst1,inOrgEqnsLst2) 
      then (inBackendDAE,m,mt,ass1,ass2,so,orgEqnslst,inOrgEqnsLst1,inOrgEqnsLst2);
    case ((ep,l,false)::rest,dae as BackendDAE.DAE(orderedVars=v,orderedEqs=eqns),m,mt,ass1,ass2,so,orgEqnslst,inOrgEqnsLst1,inOrgEqnsLst2)
      equation
        e_1 = ep - 1;
        orgeqn = BackendDAEUtil.equationNth(eqns, e_1);
        (cr,cr1,exp1,exp2,negate) = BackendEquation.aliasEquation(orgeqn);
        true = BackendVariable.isState(cr,v);
        true = BackendVariable.isState(cr1,v);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("Remove Alias State "),cr," or ",cr1,"\n"));
        slst = Util.listSelect1(m[ep],0,intLt);
        slst = Util.listMap(slst,intAbs);
        vlst = Util.listMap1r(slst,BackendVariable.getVarAt,v);
        crlst = Util.listMap(vlst,BackendVariable.varCref);         
        (dcr,stateno) = selectDummyState(crlst, slst, dae, m, mt);
        (_,dae1,m,mt) = makeDummyState(dcr,stateno,dae,m,mt);
        (so1,ocr) = deleteStateOrder(dcr,so);
        ev = BackendVariable.varsSize(BackendVariable.daeVars(dae1));
        ast =  getAssigned(stateno,ass1,ass2);
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",stateno," ",ep,"\n"));
        (ass1,ass2) = assignWithExpand(stateno, ep, ass1, ass2);         
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",ev," ",ast,"\n"));
        (ass1,ass2) = assignWithExpand(ev, ast, ass1, ass2);         
        // replace dummy state in eqns
        scr = Util.if_(ComponentReference.crefEqualNoStringCompare(dcr, cr),cr1,cr);
        so = addOptStateOrder(scr,ocr,so);
        so = addOptStateOrder1(scr,dcr,so);
        exp = Expression.crefExp(scr);
        exp = Util.if_(negate,Expression.negate(exp),exp);
        repl = BackendVarTransform.emptyReplacements();
        repl = BackendVarTransform.addReplacement(repl, dcr, exp);
        (dae1,oe) = replaceDummyStateInOrgEqns(inOrgEqnsLst1,repl,dae1);
        (dae1,oe1) = replaceDummyStateInOrgEqns(inOrgEqnsLst2,repl,dae1);
        (dae1,rest) = replaceDummyStateInOrgEqns1(rest,repl,dae1);
        (dae1,orgEqnslst) = replaceDummyStateInOrgEqns1(orgEqnslst,repl,dae1);
        slst = mt[stateno];
        (m,mt) = BackendDAEUtil.updateIncidenceMatrix(dae1, m, mt, slst);
        // next 
        (dae2,m2,mt2,ass1,ass2,so2,orgEqnslst,oe,oe1) = prozessAlliasStates1(rest,dae1,m,mt,ass1,ass2,so1,(ep,l,true)::orgEqnslst,oe,oe1);
      then
        (dae2,m2,mt2,ass1,ass2,so2,orgEqnslst,oe,oe1);
    case ((ep,l,b)::rest,dae as BackendDAE.DAE(orderedVars=v,orderedEqs=eqns),m,mt,ass1,ass2,so,orgEqnslst,inOrgEqnsLst1,inOrgEqnsLst2)
      equation
        e_1 = ep - 1;
        orgeqn = BackendDAEUtil.equationNth(eqns, e_1);  
        states = BackendEquation.equationsStates({orgeqn},v);
        l = listLength(states);
        // next 
        (dae2,m2,mt2,ass1,ass2,so1,orgEqnslst,oe,oe1) = prozessAlliasStates1(rest,dae,m,mt,ass1,ass2,so,(ep,l,b)::orgEqnslst,inOrgEqnsLst1,inOrgEqnsLst2);
      then
        (dae2,m2,mt2,ass1,ass2,so1,orgEqnslst,oe,oe1); 
    else
      equation
        print("  prozessAlliasStates1 failed!\n");
      then 
        fail();     
  end matchcontinue;
end prozessAlliasStates1;     

protected function prozessEqnsLevel
"function: prozessEqnsLevel
  author: Frenkel TUD"
  input list<tuple<Integer,Integer,Integer>> inOrgEqns;
  input list<list<tuple<Integer,Option<DAE.Exp>>>> inSysjac;  
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;   
  input DAE.FunctionTree inFunctionTree;  
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;     
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outAssignments1,outAssignments2):=
  matchcontinue (inOrgEqns,inSysjac,inStateOrd,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2,inFunctionTree,inStates)
    local
      Integer e,ep,i,stateno,ast,ev,l;
      list<tuple<Integer,Integer,Integer>> rest,orgeqns;
      list<list<tuple<Integer,Option<DAE.Exp>>>> sysjac,sysjac1;
      list<tuple<Integer,Option<DAE.Exp>>> eqnjac;
      BackendDAE.BackendDAE dae,dae1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Assignments ass1,ass2;
      list<tuple<DAE.ComponentRef,Integer>> states,states1;
      DAE.ComponentRef cr;
      list<Integer> rs;
      list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> dummystates;
      list<tuple<tuple<Integer,Integer,Integer>,list<tuple<Integer,Option<DAE.Exp>>>>> orgeqnssysjac;
    case ({},inSysjac,inStateOrd,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2,inFunctionTree,inStates)
      then (inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2);
    case (inOrgEqns,inSysjac,inStateOrd,inBackendDAE,m,mt,ass1,ass2,inFunctionTree,inStates)
      equation
        (orgeqns,sysjac,dae,m,mt,ass1,ass2,states1,rs) = prozessOneStateEqns(inOrgEqns,inSysjac,inStateOrd,inBackendDAE,m,mt,ass1,ass2,inFunctionTree,inStates);
        true = intGt(listLength(rs),0);
        (sysjac1,orgeqns) = removeVarsfromSysJac(rs,sysjac,orgeqns);
        (dae1,m,mt,ass1,ass2) = prozessEqnsLevel(orgeqns,sysjac1,inStateOrd,dae,m,mt,ass1,ass2,inFunctionTree,states1);
      then
        (dae1,m,mt,ass1,ass2);   
     case (inOrgEqns,inSysjac,inStateOrd,inBackendDAE,m,mt,ass1,ass2,inFunctionTree,inStates)
      equation
        Debug.fcall("bltdump", print, "Sort OrgEqn Level\n");
        orgeqnssysjac = Util.makeTuple(inOrgEqns,inSysjac);
        orgeqnssysjac = Util.sort(orgeqnssysjac,sortOrgEqnLevel);
        orgeqns = Util.listMap(orgeqnssysjac,Util.tuple21);
        dummystates = selectDummyStates1(orgeqns,inStateOrd,inBackendDAE,m,mt,inFunctionTree,inStates,{});
        Debug.fcall("bltdump", print, "add dummy derivatives\n");
        (dae1,m,mt,ass1,ass2) = makeDummyStates(dummystates,inBackendDAE,m,mt,ass1,ass2);        
      then
        (dae1,m,mt,ass1,ass2); 
  end matchcontinue;
end prozessEqnsLevel;

protected function prozessOneStateEqns
"function: prozessOneStateEqns
  author: Frenkel TUD"
  input list<tuple<Integer,Integer,Integer>> inOrgEqns;
  input list<list<tuple<Integer,Option<DAE.Exp>>>> inSysjac;  
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;   
  input DAE.FunctionTree inFunctionTree;  
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  output list<tuple<Integer,Integer,Integer>> outOrgEqns;
  output list<list<tuple<Integer,Option<DAE.Exp>>>> outSysjac;  
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;     
  output list<tuple<DAE.ComponentRef,Integer>> outStates; 
  output list<Integer> removedStates;
algorithm
  (outOrgEqns,outSysjac,outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outAssignments1,outAssignments2,outStates,removedStates):=
  matchcontinue (inOrgEqns,inSysjac,inStateOrd,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2,inFunctionTree,inStates)
    local
      Integer e,ep,stateno,ast,ev,l;
      list<tuple<Integer,Integer,Integer>> rest,orgeqns;
      list<list<tuple<Integer,Option<DAE.Exp>>>> sysjac,sysjac1;
      list<tuple<Integer,Option<DAE.Exp>>> eqnjac;
      BackendDAE.BackendDAE dae,dae1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Assignments ass1,ass2;
      BackendDAE.Variables v;
      list<tuple<DAE.ComponentRef,Integer>> states,states1;
      DAE.ComponentRef cr;
      list<Integer> rs;
      BackendDAE.Var var;
    case ({},inSysjac,inStateOrd,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2,inFunctionTree,inStates)
      then ({},inSysjac,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2,inStates,{});
    case ((e,ep,l)::rest,((stateno,_)::{})::sysjac,inStateOrd,dae as BackendDAE.DAE(orderedVars=v),m,mt,ass1,ass2,inFunctionTree,inStates)
      equation
        var = BackendVariable.getVarAt(v,stateno);
        cr = BackendVariable.varCref(var);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrIntStr, (("Remove State "),cr," from Eqn ",e,"\n"));
        (_,dae1,m,mt) = makeDummyState(cr,stateno,dae,m,mt);
        ev = BackendVariable.varsSize(BackendVariable.daeVars(dae1));
        ast =  getAssigned(stateno,ass1,ass2);
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",stateno," ",ep,"\n"));
        (ass1,ass2) = assignWithExpand(stateno, ep, ass1, ass2);         
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",ev," ",ast,"\n"));
        (ass1,ass2) = assignWithExpand(ev, ast, ass1, ass2);   
        // next 
        (orgeqns,sysjac1,dae1,m,mt,ass1,ass2,states,rs) = prozessOneStateEqns(rest,sysjac,inStateOrd,dae1,m,mt,ass1,ass2,inFunctionTree,inStates);
        states1 = updateStateCandidates(stateno,states,inStateOrd,BackendVariable.daeVars(dae1));      
      then
        (orgeqns,sysjac1,dae1,m,mt,ass1,ass2,states1,stateno::rs);   
     case ((e,ep,l)::rest,eqnjac::sysjac,inStateOrd,dae,m,mt,ass1,ass2,inFunctionTree,inStates)
      equation
        (orgeqns,sysjac1,dae1,m,mt,ass1,ass2,states,rs) = prozessOneStateEqns(rest,sysjac,inStateOrd,dae,m,mt,ass1,ass2,inFunctionTree,inStates);
      then
        ((e,ep,l)::orgeqns,eqnjac::sysjac1,dae1,m,mt,ass1,ass2,states,rs); 
  end matchcontinue;
end prozessOneStateEqns;

protected function removeVarsfromSysJac
"function: removeVarsfromSysJac
  author: Frenkel TUD"
  input list<Integer> removedStates;
  input list<list<tuple<Integer,Option<DAE.Exp>>>> inSysjac;
  input list<tuple<Integer,Integer,Integer>> inOrgEqns;  
  output list<list<tuple<Integer,Option<DAE.Exp>>>> outSysjac;
  output list<tuple<Integer,Integer,Integer>> outOrgEqns;  
algorithm
  (outSysjac,outOrgEqns):=
  matchcontinue (removedStates,inSysjac,inOrgEqns)
    local
      Integer i,e,ep,l,l1;
      list<list<tuple<Integer,Option<DAE.Exp>>>> sysjac,sysjac1;
      list<tuple<Integer,Option<DAE.Exp>>> eqnjac,eqnjac1;
      list<Integer> rs;
      list<tuple<Integer,Integer,Integer>> rest,orgeqns;
    case (_,{},{})
      then ({},{});
    case (rs,((i,_)::{})::sysjac,(e,ep,l)::rest)
      equation
        true = listMember(i,rs);
        (sysjac1,orgeqns) = removeVarsfromSysJac(rs,sysjac,rest);
      then
        (sysjac1,orgeqns);   
     case (rs,eqnjac::sysjac,(e,ep,l)::rest)
      equation
        eqnjac1 = removeVarsfromSysJac1(rs,eqnjac);
        l1 = listLength(eqnjac1);
        (sysjac1,orgeqns) = removeVarsfromSysJac(rs,sysjac,rest);
      then
        (eqnjac1::sysjac1,(e,ep,l)::orgeqns); 
  end matchcontinue;
end removeVarsfromSysJac;

protected function removeVarsfromSysJac1
"function: removeVarsfromSysJac
  author: Frenkel TUD"
  input list<Integer> removedStates;
  input list<tuple<Integer,Option<DAE.Exp>>> inSysjac;  
  output list<tuple<Integer,Option<DAE.Exp>>> outSysjac;  
algorithm
  outSysjac:=
  matchcontinue (removedStates,inSysjac)
    local
      Integer i;
      list<tuple<Integer,Option<DAE.Exp>>> sysjac,sysjac1;
      Option<DAE.Exp> oe;
      list<Integer> rs;
    case (_,{})
      then {};
    case (rs,(i,_)::sysjac)
      equation
        true = listMember(i,rs);
        sysjac1 = removeVarsfromSysJac1(rs,sysjac);
      then
        sysjac1;   
    case (rs,(i,oe)::sysjac)
      equation
        sysjac1 = removeVarsfromSysJac1(rs,sysjac);
      then
        (i,oe)::sysjac1;  
  end matchcontinue;
end removeVarsfromSysJac1;

protected function addOptStateOrder
  input DAE.ComponentRef cr;
  input Option<DAE.ComponentRef> ocr;
  input BackendDAE.StateOrder inStateOrder;
  output BackendDAE.StateOrder outStateOrder;
algorithm
  outStateOrder :=
  matchcontinue (cr,ocr,inStateOrder)
    local
        DAE.ComponentRef dcr,dcr1,ddcr;
        BackendDAE.StateOrder so;
    case (cr,NONE(),inStateOrder)
      then
       inStateOrder;
    case (cr,SOME(dcr),inStateOrder)
      equation
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("check  addOptStateOrder "),cr," -> ",dcr,"\n"));
        dcr1 = getStateOrder(cr,inStateOrder);
        ddcr = getStateOrder(dcr,inStateOrder);
        so = addOptStateOrder(dcr1,SOME(ddcr),inStateOrder);
      then
       so;        
    case (cr,SOME(dcr),inStateOrder)
      equation
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("check  addOptStateOrder "),cr," -> ",dcr,"\n"));
        dcr1 = getStateOrder(cr,inStateOrder);
        failure(_ = getStateOrder(dcr,inStateOrder));
      then
        inStateOrder;
    case (cr,SOME(dcr),inStateOrder)
      equation
        failure(_ = getStateOrder(cr,inStateOrder));
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("addStateOrder "),cr," -> ",dcr,"\n"));
        so = addStateOrder(cr,dcr,inStateOrder);
      then
       so;
  end matchcontinue;  
end addOptStateOrder;

protected function addOptStateOrder1
  input DAE.ComponentRef cr;
  input DAE.ComponentRef dcr;
  input BackendDAE.StateOrder inStateOrder;
  output BackendDAE.StateOrder outStateOrder;
algorithm
  outStateOrder :=
  matchcontinue (cr,dcr,inStateOrder)
    local
        BackendDAE.StateOrder so;
        list<DAE.ComponentRef> crlst;
    case (cr,dcr,inStateOrder)
      equation
        crlst = getDerStateOrder(dcr,inStateOrder);
        so = addOptStateOrder2(crlst,cr,inStateOrder);        
      then
       so;
    case (cr,dcr,inStateOrder)
      equation
        failure(_ = getDerStateOrder(dcr,inStateOrder));
      then
       inStateOrder;
  end matchcontinue;  
end addOptStateOrder1;

protected function addOptStateOrder2
  input list<DAE.ComponentRef> inCrLst;
  input DAE.ComponentRef cr;
  input BackendDAE.StateOrder inStateOrder;
  output BackendDAE.StateOrder outStateOrder;
algorithm
  outStateOrder :=
  matchcontinue (inCrLst,cr,inStateOrder)
    local
        DAE.ComponentRef cr1;
        BackendDAE.StateOrder so;
        list<DAE.ComponentRef> crlst;
    case ({},cr,inStateOrder)
      then
       inStateOrder;
    case (cr1::crlst,cr,inStateOrder)
      equation
        Debug.fcall("bltdump", BackendDump.debugStrCrefStrCrefStr, (("addStateOrder "),cr1," -> ",cr,"\n"));
        so = addStateOrder(cr1,cr,inStateOrder);  
        so = addOptStateOrder2(crlst,cr,so);      
      then
       so;
  end matchcontinue;  
end addOptStateOrder2;

protected function replaceDummyStateInOrgEqns
"function: replaceDummyStateInOrgEqns
  author: Frenkel TUD"
  input list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> inOrgEqns;
  input BackendVarTransform.VariableReplacements repl;
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> outOrgEqns;
algorithm
  (outBackendDAE,outOrgEqns):=
  matchcontinue (inOrgEqns,repl,inBackendDAE)
    local
      list<tuple<Integer,Integer,Boolean>> eqns,eqns_1;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> rest,orgeqns;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m,m1,m2;
      BackendDAE.IncidenceMatrixT mt,mt1,mt2;      
      Integer e;
      BackendDAE.StateOrder so;
      BackendDAE.Assignments ass1,ass2;
    case ({},_,dae) then (dae,{});
    case ((e,eqns)::rest,repl,inBackendDAE)
      equation
        (dae,eqns_1) = replaceDummyStateInOrgEqns1(eqns,repl,inBackendDAE);
        (dae2,orgeqns) =  replaceDummyStateInOrgEqns(rest,repl,dae);
      then
        (dae2,(e,eqns_1)::orgeqns);
  end matchcontinue;
end replaceDummyStateInOrgEqns;   

protected function replaceDummyStateInOrgEqns1
"function: replaceDummyStateInOrgEqns1
  author: Frenkel TUD"
  input list<tuple<Integer,Integer,Boolean>> inOrgEqns;
  input BackendVarTransform.VariableReplacements repl;
  input BackendDAE.BackendDAE inBackendDAE;
  output BackendDAE.BackendDAE outBackendDAE;
  output list<tuple<Integer,Integer,Boolean>> outOrgEqns;
algorithm
  (outBackendDAE,outOrgEqns):=
  matchcontinue (inOrgEqns,repl,inBackendDAE)
    local
      Integer ep,l,i,e_1;
      Boolean b;
      BackendDAE.Equation orgeqn;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m,m1,m2;
      BackendDAE.IncidenceMatrixT mt,mt1,mt2;
      list<tuple<Integer,Integer,Boolean>> rest,orgEqnslst;
      DAE.ComponentRef cr,dcr,cr1,scr;
      list<BackendDAE.Var> vlst;
      list<DAE.ComponentRef> crlst;      
      BackendDAE.StateOrder so;
      BackendDAE.EquationArray eqnsarr,seqns,ie;
      BackendDAE.Variables v,kv,ev;
      BackendDAE.AliasVariables av;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      list<BackendDAE.WhenClause> wclst;
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.ExternalObjectClasses eoc;    
      DAE.Exp exp1,exp2;
      Boolean negate;
      list<BackendDAE.Value> slst;
      list<Integer> dims;
      DAE.ElementSource source;      
    case ({},_,inBackendDAE) 
      then (inBackendDAE,{});
    case ((ep,l,b)::rest,repl,BackendDAE.DAE(v,kv,ev,av,eqnsarr,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zc),eoc))
      equation
        e_1 = ep - 1;
        (orgeqn as BackendDAE.ARRAY_EQUATION(index=i)) = BackendDAEUtil.equationNth(eqnsarr, e_1);        
        BackendDAE.MULTIDIM_EQUATION(dims,exp1,exp2,source) = ae[i+1];
        (exp1,_) = BackendVarTransform.replaceExp(exp1, repl,NONE());
        (exp2,_) = BackendVarTransform.replaceExp(exp2, repl,NONE());   
        ae = arrayUpdate(ae,i+1,BackendDAE.MULTIDIM_EQUATION(dims,exp1,exp2,source));   
        {orgeqn} = BackendVarTransform.replaceEquations({orgeqn},repl);
        eqnsarr = BackendEquation.equationSetnth(eqnsarr,e_1,orgeqn);
        // next 
        dae1 = BackendDAE.DAE(v,kv,ev,av,eqnsarr,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zc),eoc);
        (dae2,orgEqnslst) = replaceDummyStateInOrgEqns1(rest,repl,dae1);
      then
        (dae2,(ep,l,b)::orgEqnslst);        
    case ((ep,l,b)::rest,repl,dae as BackendDAE.DAE(orderedEqs=eqnsarr))
      equation
        e_1 = ep - 1;
        orgeqn = BackendDAEUtil.equationNth(eqnsarr, e_1);        
        {orgeqn} = BackendVarTransform.replaceEquations({orgeqn},repl);
        dae1 = BackendEquation.equationSetnthDAE(e_1,orgeqn,dae);
        // next 
        (dae2,orgEqnslst) = replaceDummyStateInOrgEqns1(rest,repl,dae1);
      then
        (dae2,(ep,l,b)::orgEqnslst);
  end matchcontinue;
end replaceDummyStateInOrgEqns1;  

protected function calculateJacobianSystem
"function: calculateJacobianSystem
  author: Frenkel TUD"
  input list<tuple<Integer,Integer,Integer>> inOrgEqns;
  input BackendDAE.BackendDAE inBackendDAE;
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  output list<list<tuple<Integer,Option<DAE.Exp>>>> outJac; 
  output list<tuple<Integer,Integer,Integer>> outOrgEqns;
algorithm
  (outJac,outOrgEqns):=
  matchcontinue (inOrgEqns,inBackendDAE,inStates)
    local
      Integer e,ep,e_1,l;
      list<tuple<Integer,Integer,Integer>> rest,orgeqns;
      BackendDAE.BackendDAE dae,dae1;
      BackendDAE.Equation eqn,orgeqn;
      BackendDAE.Variables knvars;
      BackendDAE.EquationArray eqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      String str;  
      list<tuple<DAE.ComponentRef,Integer>> states,states1;
      list<DAE.Exp> jac;
      list<tuple<Integer,Option<DAE.Exp>>> eqnjac;
      list<list<tuple<Integer,Option<DAE.Exp>>>> jacsys;
    case ({},inBackendDAE,inStates)
      then ({},{});
    case ((e,ep,_)::rest,dae as BackendDAE.DAE(knownVars=knvars,orderedEqs=eqns,arrayEqs=ae,algorithms=al),inStates)
      equation
        e_1 = ep - 1;
        orgeqn = BackendDAEUtil.equationNth(eqns, e_1); 
        Debug.fcall("bltdump", print, " Calculate Jacobian for eqn:\n"); 
        Debug.fcall("bltdump",  print ,BackendDump.equationStr(orgeqn));
        // get Jacobian
        jac = calculateJacobian(orgeqn,ae,al,inStates);
        // analyse jac 
        (eqnjac,l) = analyseJac1(jac,inStates,knvars,1);
        Debug.fcall("bltdump",  print ,"\n");
        Debug.fcall("bltdump",  BackendDump.debuglst ,(eqnjac,dumpEqnJac));
        Debug.fcall("bltdump",  print ,"\n");
        // next 
        (jacsys,orgeqns) = calculateJacobianSystem(rest,dae,inStates);
      then
        (eqnjac::jacsys,(e,ep,l)::orgeqns);       
  end matchcontinue;
end calculateJacobianSystem;

protected function dumpEqnJac
"function: dumpStates
  author: Frenkel TUD"
  input tuple<Integer,Option<DAE.Exp>> inJac;
  output String outStr;
algorithm
  outStr := 
  matchcontinue (inJac)
    local
      Integer i;
      DAE.Exp e;
      String s;
    case ((i,NONE()))
      equation
        s = " " +& intString(i);
      then s;
    case ((i,SOME(e)))
      equation
        s = " " +& intString(i) +& " " +& ExpressionDump.printExpStr(e);
      then s;
  end matchcontinue;
end dumpEqnJac;

protected function selectDummyStates1
"function: selectDummyStates1
  author: Frenkel TUD"
  input list<tuple<Integer,Integer,Integer>> inOrgEqns;
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input DAE.FunctionTree inFunctionTree;  
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  input list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> inDummyStates; 
  output list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> outDummyStates; 
algorithm
  outDummyStates:=
  matchcontinue (inOrgEqns,inStateOrd,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inFunctionTree,inStates,inDummyStates)
    local
      Integer e,ep,e_1;
      list<tuple<Integer,Integer,Integer>> rest;
      BackendDAE.BackendDAE dae,dae1;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.Equation eqn,orgeqn;
      BackendDAE.Variables knvars;
      BackendDAE.EquationArray eqns;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      String str;  
      list<tuple<DAE.ComponentRef,Integer>> states,states1;
      list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> dummydercand,dyndummydercand;
      list<DAE.Exp> jac;
      list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> dummystates,dummystates1;
    case ({},inStateOrd,inBackendDAE,m,mt,inFunctionTree,inStates,dummystates)
      then dummystates;
    case ((e,ep,_)::rest,inStateOrd,dae as BackendDAE.DAE(knownVars=knvars,orderedEqs=eqns,arrayEqs=ae,algorithms=al),m,mt,inFunctionTree,inStates,dummystates)
      equation
        e_1 = ep - 1;
        orgeqn = BackendDAEUtil.equationNth(eqns, e_1); 
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Select Dummy State from Eqn ",e,"  ",ep,"  ")); 
        Debug.fcall("bltdump",  print ,BackendDump.equationStr(orgeqn));
        // get candidates
        str = Util.stringDelimitList(Util.listMap(inStates,dumpStates)," : "); 
        Debug.fcall("bltdump", print, "\nCandidates (" +& intString(listLength(inStates)) +& "): " +& str +& "\n"); 
        // get Jacobian
        jac = calculateJacobian(orgeqn,ae,al,inStates);
        str = Util.stringDelimitList(Util.listMap(jac,ExpressionDump.printExpStr)," : "); 
        Debug.fcall("bltdump", print, "Jac: " +& str +& "\n"); 
        // analyse jac -> get dummy derivative candidate
        (dummydercand,dyndummydercand) = analyseJac(jac,inStates,knvars);
        str = Util.stringDelimitList(Util.listMap(dummydercand,dumpStates1)," : "); 
        Debug.fcall("bltdump", print, "Dummy DerCandidates: " +& str +& "\n");
        str = Util.stringDelimitList(Util.listMap(dyndummydercand,dumpStates1)," : "); 
        Debug.fcall("bltdump", print, "Dynamic DummyDer Candidates: " +& str +& "\n");
        // select dummy derivatives 
        dummystates1 = selectDummyDerivatives(dummydercand,dyndummydercand,dae,m,mt,inFunctionTree,inStates,inStateOrd,rest,dummystates,ep);
      then
        dummystates1;       
  end matchcontinue;
end selectDummyStates1;

protected function selectDummyDerivatives "function: selectDummyDerivatives
  author: Frenkel TUD 20-11"
  input list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> inDummyDer;
  input list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> inDynDummyDer;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT; 
  input DAE.FunctionTree inFunctionTree;   
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  input BackendDAE.StateOrder inStateOrd;
  input list<tuple<Integer,Integer,Integer>> inOrgEqns;
  input list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> inDummyStates;
  input Integer ep;
  output list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> outDummyStates;  
algorithm
   outDummyStates := 
   matchcontinue (inDummyDer,inDynDummyDer,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inFunctionTree,inStates,inStateOrd,inOrgEqns,inDummyStates,ep)
    local
      list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> dummyder,dyndummyder;
      list<DAE.ComponentRef> dummystates;
      list<tuple<DAE.ComponentRef,Integer>> states;
      list<Integer> stateindx,changedeqns,slst;
      DAE.ComponentRef dummystate,dummystate1,dsxy,derdummystate,derdummystate1,dsxycont;
      DAE.Exp dse1,dse2,ds1,ds2,dxdye,dds1,dds2,cont,cont1,dxdyecont,icont;
      Integer stateno,stateno1,ep1,ep2,ep3,ast,ast1;
      BackendDAE.Equation eq,deq,eqcont;
      BackendDAE.Var dsxyvar,dsxyvarcont,dummyvar;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;  
      list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> accdummystates;
      list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>> accdummystate;
      list<BackendDAE.Var> vlst;
      list<list<tuple<DAE.ComponentRef,Integer,DAE.Exp>>> dummydercomps;
    case (dummyder as (_::_),dyndummyder,dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep)
      equation
        dummystates = Util.listMap(dummyder,Util.tuple31);
        stateindx = Util.listMap(dummyder,Util.tuple32);
        (states,dummystate,stateno) = selectDummyDerivative(dummystates,stateindx,dae,m,mt,states,inStateOrd);
        ((_,_,dse1)) = Util.listGetMemberOnTrue(stateno,dummyder,getDummyExp);
        accdummystate = {(dummystate,dse1,stateno,ep)};
        accdummystates = selectDummyDerivatives2({(dummystate,stateno)},accdummystate,dummyder,dyndummyder,dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep);
      then
        (accdummystates);
    case ({},dyndummyder as (_::{}),dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep)
      equation
        dummystates = Util.listMap(dyndummyder,Util.tuple31);
        stateindx = Util.listMap(dyndummyder,Util.tuple32);
        (states,dummystate,stateno) = selectDummyDerivative(dummystates,stateindx,dae,m,mt,states,inStateOrd);
        ((_,_,dse1)) = Util.listGetMemberOnTrue(stateno,dyndummyder,getDummyExp);
        accdummystate = {(dummystate,dse1,stateno,ep)};
        accdummystates = selectDummyDerivatives2({(dummystate,stateno)},accdummystate,{},{},dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep);
      then
        (accdummystates);       
    case ({},dyndummyder as (_::_::_),dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep)
      equation
        dummydercomps = alldummyCompinations(dyndummyder,dyndummyder);
        accdummystates = selectDummyDerivatives3(dummydercomps,dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep);
      then
        (accdummystates);
    case ({},{},_,_,_,_,_,_,_,_,_)
      equation
         Debug.fcall("bltdump",print,"no states found in equation\n");
      then fail();
  end matchcontinue;
end selectDummyDerivatives;

protected function selectDummyDerivatives3 "function: selectDummyDerivatives3
  author: Frenkel TUD 20-11"
  input list<list<tuple<DAE.ComponentRef,Integer,DAE.Exp>>> inDynDummyDer;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT; 
  input DAE.FunctionTree inFunctionTree;   
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  input BackendDAE.StateOrder inStateOrd;
  input list<tuple<Integer,Integer,Integer>> inOrgEqns;
  input list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> inDummyStates;
  input Integer ep;
  output list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> outDummyStates;  
algorithm
   outDummyStates := 
   matchcontinue (inDynDummyDer,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inFunctionTree,inStates,inStateOrd,inOrgEqns,inDummyStates,ep)
    local
      list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> dyndummyder;
      list<DAE.ComponentRef> dummystates;
      list<tuple<DAE.ComponentRef,Integer>> states;
      list<Integer> stateindx,changedeqns,slst;
      DAE.ComponentRef dummystate,dummystate1,dsxy,derdummystate,derdummystate1,dsxycont;
      DAE.Exp dse1,dse2,ds1,ds2,dxdye,dds1,dds2,cont,cont1,dxdyecont,icont;
      Integer stateno,stateno1,ep,ep1,ep2,ep3,ast,ast1;
      BackendDAE.Equation eq,deq,eqcont;
      BackendDAE.Var dsxyvar,dsxyvarcont,dummyvar;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;  
      list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> accdummystates;
      list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>> accdummystate;
      list<list<tuple<DAE.ComponentRef,Integer,DAE.Exp>>> rest;
    case ((dyndummyder as (_::{}))::rest,dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep)
      equation
        dummystates = Util.listMap(dyndummyder,Util.tuple31);
        stateindx = Util.listMap(dyndummyder,Util.tuple32);
        (states,dummystate,stateno) = selectDummyDerivative(dummystates,stateindx,dae,m,mt,states,inStateOrd);
        ((_,_,dse1)) = Util.listGetMemberOnTrue(stateno,dyndummyder,getDummyExp);
        accdummystate = {(dummystate,dse1,stateno,ep)};
        accdummystates = selectDummyStates1(inOrgEqns,inStateOrd,dae,m,mt,inFunctionTree,states,inDummyStates);
      then
        (accdummystate::accdummystates);           
    case ((dyndummyder as (_::_::_))::rest,dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep)
      equation
        // select dummy
        dummystates = Util.listMap(dyndummyder,Util.tuple31);
        stateindx = Util.listMap(dyndummyder,Util.tuple32);
        (states,dummystate,stateno) = selectDummyDerivative(dummystates,stateindx,dae,m,mt,states,inStateOrd);
        ((_,_,dse1)) = Util.listGetMemberOnTrue(stateno,dyndummyder,getDummyExp);
        dummystates = Util.listRemoveOnTrue(dummystate,ComponentReference.crefEqualNoStringCompare,dummystates);
        stateindx = Util.listRemoveOnTrue(stateno,intEq,stateindx);
        (states,dummystate1,stateno1) = selectDummyDerivative(dummystates,stateindx,dae,m,mt,states,inStateOrd);
        ((_,_,dse2)) = Util.listGetMemberOnTrue(stateno1,dyndummyder,getDummyExp);
        accdummystate = {(dummystate,dse1,stateno,ep),(dummystate1,dse2,stateno1,ep)};
        accdummystates = selectDummyStates1(inOrgEqns,inStateOrd,dae,m,mt,inFunctionTree,states,inDummyStates);
      then
        (accdummystate::accdummystates);  
   case (dyndummyder::rest,dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep)
      equation
        accdummystates = selectDummyDerivatives3(rest,dae,m,mt,inFunctionTree,states,inStateOrd,inOrgEqns,inDummyStates,ep);
      then
        accdummystates;
  end matchcontinue;
end selectDummyDerivatives3;

protected function alldummyCompinations
  input list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> inDummyDerLst;
  input list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> inDummyDerLst1;
  output list<list<tuple<DAE.ComponentRef,Integer,DAE.Exp>>> outDummyDerComps;
algorithm
  outDummyDerComps :=
  matchcontinue(inDummyDerLst,inDummyDerLst1)
      local
        tuple<DAE.ComponentRef,Integer,DAE.Exp> tpl;
        list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> rest,ddlst;
        list<list<tuple<DAE.ComponentRef,Integer,DAE.Exp>>> dummydercomps,dummydercomps1,dummydercomps2;
      case({},ddlst)
        equation
          dummydercomps = Util.listMap(ddlst,listMake); 
        then dummydercomps;
      case (tpl::rest,ddlst)
        equation
         dummydercomps = Util.listMap1r(rest,Util.listMake2,tpl);
         dummydercomps1 = alldummyCompinations(rest,ddlst);
         dummydercomps2 = listAppend(dummydercomps,dummydercomps1);
        then
         dummydercomps2; 
  end matchcontinue;
end alldummyCompinations; 

protected function listMake "function listMake
  Takes one arguments and returns a list containing the one."
  input Type_a inTypeA;
  output list<Type_a> outTypeALst;
  replaceable type Type_a subtypeof Any;
algorithm
  outTypeALst := {inTypeA};
end listMake;

protected function selectDummyDerivatives2 "function: selectDummyDerivatives
  author: Frenkel TUD 20-11"
  input list<tuple<DAE.ComponentRef,Integer>> stateNo;
  input list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>> accdummystate;
  input list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> inDummyDer;
  input list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> inDynDummyDer;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;  
  input DAE.FunctionTree inFunctionTree;  
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  input BackendDAE.StateOrder inStateOrd;
  input list<tuple<Integer,Integer,Integer>> inOrgEqns;
  input list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> inDummyStates;
  input Integer ep;
  output list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> outDummyStates;  
algorithm
  outDummyStates := 
   matchcontinue (stateNo,accdummystate,inDummyDer,inDynDummyDer,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inFunctionTree,inStates,inStateOrd,inOrgEqns,inDummyStates,ep)
    local
      list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> dummydercand,dyndummydercand;
      list<Integer> stateno;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;  
      list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> dummystates;
      list<tuple<DAE.ComponentRef,Integer>> states,states1;
      String str;

    case (stateNo,accdummystate,dummydercand,dyndummydercand,inBackendDAE,m,mt,inFunctionTree,inStates,inStateOrd,inOrgEqns,inDummyStates,ep)
      equation
        dummystates = selectDummyStates1(inOrgEqns,inStateOrd,inBackendDAE,m,mt,inFunctionTree,inStates,inDummyStates);
      then
        (accdummystate::dummystates);
    case (stateNo,accdummystate,dummydercand,dyndummydercand,inBackendDAE,m,mt,inFunctionTree,inStates,inStateOrd,inOrgEqns,inDummyStates,ep)
      equation
        Debug.fcall("bltdump", print, "removeDummyStateCandidate in eqn " +& intString(ep) +& " from list try next\n"); 
        str = Util.stringDelimitList(Util.listMap(dummydercand,dumpStates1)," : "); 
        Debug.fcall("bltdump", print, "Dummy DerCandidates: " +& str +& "\n");        
        str = Util.stringDelimitList(Util.listMap(dyndummydercand,dumpStates1)," : "); 
        Debug.fcall("bltdump", print, "Dummy Dynamic DerCandidates: " +& str +& "\n");        
        (dummydercand,dyndummydercand,states) = removeDummyStateCandidate(stateNo,dummydercand,dyndummydercand);
        states1 = listAppend(states,inStates);
        dummystates = selectDummyDerivatives(dummydercand,dyndummydercand,inBackendDAE,m,mt,inFunctionTree,states1,inStateOrd,inOrgEqns,inDummyStates,ep);
      then
        dummystates;
  end matchcontinue;
end selectDummyDerivatives2;

protected function removeDummyStateCandidate
  input list<tuple<DAE.ComponentRef,Integer>> stateNo;
  input list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> inDummyDer;
  input list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> inDynDummyDer;
  output list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> outDummyDer;
  output list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> outDynDummyDer;
  output list<tuple<DAE.ComponentRef,Integer>> outstateNo;
algorithm
  (outDummyDer,outDynDummyDer,outstateNo):=
  match (stateNo,inDummyDer,inDynDummyDer)
    local
      Integer n;
      DAE.ComponentRef cr;
      list<tuple<DAE.ComponentRef,Integer>> rest,so;
      list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> dummydercand,dyndummydercand;
    case ({},inDummyDer,inDynDummyDer) then (inDummyDer,inDynDummyDer,{});
    case ((cr,n)::rest,inDummyDer,inDynDummyDer)
      equation
        Debug.fcall("bltdump", print, "removeDummyStateCandidate " +& intString(n) +& "\n");
        dummydercand = Util.listRemoveOnTrue(n,getDummyExp,inDummyDer);
        dyndummydercand = Util.listRemoveOnTrue(n,getDummyExp,inDynDummyDer); 
        (dummydercand,dyndummydercand,so) = removeDummyStateCandidate({},dummydercand,dyndummydercand);       
      then
        (dummydercand,dyndummydercand,{(cr,n)}); 
  end match;
end removeDummyStateCandidate;

protected function assignWithExpand "function: assignWithExpand
  author: Frenkel TUD 20-11"
  input Integer inInteger1;
  input Integer inInteger2;
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outAssignments1,outAssignments2) := matchcontinue (inInteger1,inInteger2,inAssignments1,inAssignments2)
    local
      BackendDAE.Value s,n,v,d,d1,d2;
      BackendDAE.Assignments ass1,ass2;
    case (n,v,ass1 as BackendDAE.ASSIGNMENTS(actualSize = s),ass2)
      equation
        true = intLt(n,s); 
        true = intLt(v,s);
        (ass1,ass2) = assign(n, v, ass1, ass2); 
      then
        (ass1,ass2);
    case (n,v,ass1 as BackendDAE.ASSIGNMENTS(actualSize = s),ass2)
      equation
        d1 = n - s;
        d2 = v - s;
        d = intMax(d1,d2);
        ass1 = assignmentsExpand(ass1,d);
        ass2 = assignmentsExpand(ass2,d);
        (ass1,ass2) = assign(n, v, ass1, ass2); 
      then
        (ass1,ass2);
  end matchcontinue;
end assignWithExpand;

protected function makeDummyStates "function: makeDummyStates
  author: Frenkel TUD 20-11"
  input list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> inDummyDers;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;  
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;  
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outAssignments1,outAssignments2) := 
   matchcontinue (inDummyDers,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inAssignments1,inAssignments2)
    local
      list<list<tuple<DAE.ComponentRef,DAE.Exp,Integer,Integer>>> rest;
      list<Integer> changedeqns;
      DAE.ComponentRef dummystate,dummystate1,dsxy,derdummystate,derdummystate1,dsxycont;
      DAE.Exp dse1,dse2,ds1,ds2,dxdye,dds1,dds2,cont,cont1,dxdyecont,icont;
      Integer stateno,stateno1,ep,ep1,ep2,ep3,ev,ast,ast1;
      BackendDAE.Equation eq,deq,eqcont;
      BackendDAE.Var dsxyvar,dsxyvarcont,dummyvar;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;  
      BackendDAE.Assignments ass1,ass2; 
      BackendDAE.WhenClause wc,wc1;

    case ({},dae,m,mt,ass1,ass2) 
      then 
       (dae,m,mt,ass1,ass2);
    case (((dummystate,dse1,stateno,ep)::{})::rest,dae,m,mt,ass1,ass2)
      equation
        (_,dae1,m,mt) = makeDummyState(dummystate,stateno,dae,m,mt);
        ev = BackendVariable.varsSize(BackendVariable.daeVars(dae1));
        ast =  getAssigned(stateno,ass1,ass2);
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",stateno," ",ep,"\n"));
        (ass1,ass2) = assignWithExpand(stateno, ep, ass1, ass2);         
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",ev," ",ast,"\n"));
        (ass1,ass2) = assignWithExpand(ev, ast, ass1, ass2);  
        (dae2,m,mt,ass1,ass2) =  makeDummyStates(rest,dae1,m,mt,ass1,ass2);  
      then
        (dae2,m,mt,ass1,ass2);
    case (((dummystate,dse1,stateno,ep)::((dummystate1,dse2,stateno1,_)::{}))::rest,dae,m,mt,ass1,ass2)
      equation
        (derdummystate,dae,m,mt) = makeDummyState(dummystate,stateno,dae,m,mt);
        (derdummystate1,dae,m,mt) = makeDummyState(dummystate1,stateno1,dae,m,mt);
        dsxy = ComponentReference.joinCrefs(dummystate,dummystate1);
        dsxyvar = BackendDAE.VAR(dsxy,BackendDAE.STATE(),DAE.BIDIR(),BackendDAE.REAL(),NONE(),NONE(),{},0,DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
        dsxyvar = BackendVariable.setVarFixed(dsxyvar,false);
        dummyvar = BackendVariable.getVarAt(BackendVariable.daeVars(dae),stateno1);
        dsxyvar = BackendVariable.setVarStartValue(dsxyvar,BackendVariable.varStartValue(dummyvar));
        dsxycont = ComponentReference.joinCrefs(dsxy,ComponentReference.makeCrefIdent("cont",DAE.ET_BOOL(),{}));
        dsxyvarcont = BackendDAE.VAR(dsxycont,BackendDAE.DISCRETE(),DAE.BIDIR(),BackendDAE.BOOL(),NONE(),NONE(),{},0,DAE.emptyElementSource,NONE(),NONE(),DAE.NON_CONNECTOR(),DAE.NON_STREAM_CONNECTOR());
        ev = BackendVariable.varsSize(BackendVariable.daeVars(dae))-1;
        dae = BackendVariable.addVarDAE(dsxyvar,dae);
        dae = BackendVariable.addVarDAE(dsxyvarcont,dae);
        dxdye = Expression.crefExp(dsxy);
        dxdyecont = Expression.crefExp(dsxycont);
        ds1 = Expression.crefExp(dummystate);
        ds2 = Expression.crefExp(dummystate1);
        dds1 = Expression.crefExp(derdummystate);
        dds2 = Expression.crefExp(derdummystate1);
        cont1 = DAE.RELATION(DAE.CALL(Absyn.IDENT("abs"),{dse2},DAE.callAttrBuiltinReal),DAE.LESS(DAE.ET_REAL()),DAE.CALL(Absyn.IDENT("abs"),{dse1},DAE.callAttrBuiltinReal),0,NONE());
        ((cont,_)) = Expression.traverseExp(dxdyecont, traversingComponentRefToPre, 0);
        icont = DAE.LBINARY(DAE.CALL(Absyn.IDENT("initial"),{},DAE.callAttrBuiltinBool),DAE.OR(DAE.ET_BOOL()),cont);
        eq = BackendDAE.EQUATION(dxdye,DAE.IFEXP(icont,ds2,ds1),DAE.emptyElementSource);
        dae = BackendEquation.equationAddDAE(eq,dae); 
        deq = BackendDAE.EQUATION(DAE.CALL(Absyn.IDENT("der"),{dxdye},DAE.callAttrBuiltinReal),DAE.IFEXP(icont,dds2,dds1),DAE.emptyElementSource);
        ep1 = BackendDAEUtil.systemSize(dae);
        dae = BackendEquation.equationAddDAE(deq,dae); 
        
        wc = BackendDAE.WHEN_CLAUSE(dxdyecont,{BackendDAE.REINIT(dsxy,ds2,DAE.emptyElementSource)},NONE());
        wc1 = BackendDAE.WHEN_CLAUSE(DAE.LUNARY(DAE.NOT(DAE.ET_BOOL()),dxdyecont),{BackendDAE.REINIT(dsxy,ds1,DAE.emptyElementSource)},NONE());
        dae = BackendDAEUtil.whenClauseAddDAE({wc,wc1},dae);
        eqcont = BackendDAE.EQUATION(dxdyecont,DAE.IFEXP(DAE.CALL(Absyn.IDENT("initial"),{},DAE.callAttrBuiltinBool),DAE.BCONST(true),cont1),DAE.emptyElementSource);
        dae = BackendEquation.equationAddDAE(eqcont,dae);
        ep2 = ep1+1;
        ep3 = ep1+2;
        Debug.fcall("bltdump", print, "Update Incidence Matrix: ");
        Debug.fcall("bltdump", BackendDump.debuglst,({ep1,ep2,ep3},intString));
        Debug.fcall("bltdump", print, "\n");
        (m,mt) = BackendDAEUtil.updateIncidenceMatrix(dae, m, mt, {ep1,ep2,ep3});
        ast =  getAssigned(stateno,ass1,ass2);
        ast1 =  getAssigned(stateno1,ass1,ass2);
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",stateno," ",ep,"\n"));
        (ass1,ass2) = assignWithExpand(stateno, ep, ass1, ass2);        
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",stateno1," ",ep1,"\n"));
        (ass1,ass2) = assignWithExpand(stateno1, ep1, ass1, ass2);
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",ev," ",ast,"\n"));
        (ass1,ass2) = assignWithExpand(ev, ast, ass1, ass2);        
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",ev+1," ",ast1,"\n"));
        (ass1,ass2) = assignWithExpand(ev+1, ast1, ass1, ass2);        
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",ev+2," ",ep2,"\n"));
        (ass1,ass2) = assignWithExpand(ev+2, ep2, ass1, ass2);        
        Debug.fcall("bltdump", BackendDump.debugStrIntStrIntStr, ("Assign: ",ev+3," ",ep3,"\n"));
        (ass1,ass2) = assignWithExpand(ev+3, ep3, ass1, ass2);        
        (dae,m,mt,ass1,ass2) =  makeDummyStates(rest,dae,m,mt,ass1,ass2);
      then
        (dae,m,mt,ass1,ass2);
    else
      equation
         print("BackendDAETransform.makeDummyStates failed!\n");
      then fail();
  end matchcontinue;
end makeDummyStates;

protected function traversingComponentRefToPre "
Author: Frenkel TUD 2011-05."
  input tuple<DAE.Exp, Integer> inExp;
  output tuple<DAE.Exp, Integer> outExp;
algorithm 
  outExp := matchcontinue(inExp)
    local
      Integer i;
      DAE.Exp e;
    
    case((e as DAE.CREF(_,_), i))
      then
        ((DAE.CALL(Absyn.IDENT("pre"),{e},DAE.callAttrBuiltinReal), i ));
    
    case(inExp) then inExp;
    
  end matchcontinue;
end traversingComponentRefToPre;

protected function getDummyExp "
 author: Frenkel TUD 20-11"
 input Integer stateno;
 input tuple<DAE.ComponentRef,Integer,DAE.Exp> inTpl;
 output Boolean b;
algorithm
  b := match (stateno,inTpl)
    local
      DAE.ComponentRef cr;
      Integer i,j;
      DAE.Exp e;
    case (i,(cr,j,e)) then intEq(i,j);
  end match;  
end getDummyExp;

protected function selectDummyDerivative "function: selectDummyDerivative
  author: Frenkel TUD 20-11"
  input list<DAE.ComponentRef> dummystates;
  input list<Integer> stateindx;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;  
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  input BackendDAE.StateOrder inStateOrd;
  output list<tuple<DAE.ComponentRef,Integer>> outStates;   
  output DAE.ComponentRef outDummyState;
  output Integer outStateNo;
algorithm
  (outStates,outDummyState,outStateNo) := 
   matchcontinue (dummystates,stateindx,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inStates,inStateOrd)
    local
      list<DAE.ComponentRef> dummystates;
      list<tuple<DAE.ComponentRef,Integer>> states;
      DAE.ComponentRef state;
      Integer stateno;
      BackendDAE.BackendDAE dae;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      

    case (dummystates,stateindx,dae,m,mt,states,inStateOrd)
      equation
        (state,stateno) = selectDummyState(dummystates, stateindx, dae, m, mt);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStr, ("Selected ",state," as dummy state\n"));
        Debug.fcall("bltdump", print ," From candidates:");
        Debug.fcall("bltdump", BackendDump.debuglst ,(dummystates,ComponentReference.printComponentRefStr));
        Debug.fcall("bltdump", print ,"\n");
        // update statecandidates
        states = updateStateCandidates(stateno,states,inStateOrd,BackendVariable.daeVars(dae));
      then
        (states,state,stateno);
    else
      equation
         print("selectDummyDerivative failed\n");
      then fail();
  end matchcontinue;
end selectDummyDerivative;

protected function makeDummyState "function: makeDummyState
  author: Frenkel TUD 20-11"
  input DAE.ComponentRef dummystate;
  input Integer stateindx;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT; 
  output DAE.ComponentRef outDerDummyState;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outDerDummyState,outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT) := 
   matchcontinue (dummystate,stateindx,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<DAE.ComponentRef> dummystates;
      list<tuple<DAE.ComponentRef,Integer>> states;
      list<Integer> changedeqns;
      DAE.ComponentRef dummy_der;
      DAE.Exp stateexp,stateexpcall,dummyderexp;
      DAE.ExpType tp;
      BackendDAE.BackendDAE dae,dae1,dae2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;      

    case (dummystate,stateindx,dae,m,mt)
      equation
        (dummy_der,dae) = newDummyVar(dummystate, dae, DAE.NEW_DUMMY_DER(dummystate,{}));
        Debug.fcall("bltdump", BackendDump.debugStrCrefStr, ("Chosen dummy: ",dummy_der," as dummy state\n"));
        changedeqns = BackendDAEUtil.eqnsForVarWithStates(mt, stateindx);
        stateexp = Expression.crefExp(dummystate);
        stateexpcall = DAE.CALL(Absyn.IDENT("der"),{stateexp},DAE.callAttrBuiltinReal);
        dummyderexp = Expression.crefExp(dummy_der);
        (dae,m,mt) = replaceDummyDer(stateexpcall, dummyderexp, dae, m, mt, changedeqns)
        "We need to change variables in the differentiated equations and in the equations having the dummy derivative" ;
        dae = makeAlgebraic(dae, dummystate);
        Debug.fcall("bltdump", print ,"Update Incidence Matrix: ");
        Debug.fcall("bltdump", BackendDump.debuglst, (changedeqns,intString));
        Debug.fcall("bltdump", print ,"\n");
        (m,mt) = BackendDAEUtil.updateIncidenceMatrix(dae, m, mt, changedeqns);
      then
        (dummy_der,dae,m,mt);
    else
      equation
         print("BackendDAETransform.makeDummyState failed\n");
      then fail();
  end matchcontinue;
end makeDummyState;

protected function updateStateCandidates "function: updateStateCandidates
  author: Frenkel TUD 20-11"
  input Integer stateno;
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.Variables vars;
  output list<tuple<DAE.ComponentRef,Integer>> outStates;   
algorithm
  outStates := matchcontinue (stateno,inStates,inStateOrd,vars)
    local
      DAE.ComponentRef cr;
      Integer i,j;
      tuple<DAE.ComponentRef,Integer> tpl;
      list<tuple<DAE.ComponentRef,Integer>> crlst,states;

    case (_,{},_,_) then {};
    case (j,(cr,i)::crlst,inStateOrd,vars)
      equation
        true = intEq(j,i);
      then
        (crlst);        
    case (j,tpl::crlst,inStateOrd,vars)
      equation
        states = updateStateCandidates(j,crlst,inStateOrd,vars);
      then
        (tpl::states);
  end matchcontinue;
end updateStateCandidates;

protected function updateStateCandidates1 "function: updateStateCandidates1
  author: Frenkel TUD 20-11"
  input list<tuple<DAE.ComponentRef,Integer>> inStates; 
  input BackendDAE.StateOrder inStateOrd;
  input BackendDAE.Variables vars;
  output list<tuple<DAE.ComponentRef,Integer>> outStates;   
algorithm
  outStates := matchcontinue (inStates,inStateOrd,vars)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crs;
      list<tuple<DAE.ComponentRef,Integer>> crlst,states,states1;

    case ({},_,_) then {};
    case ((cr,_)::crlst,inStateOrd,vars)
      equation
        crs = getDerStateOrder(cr,inStateOrd);
        Debug.fcall("bltdump", BackendDump.debugStrCrefStr, ("updateStateCandidates: ",cr,"\n"));
        states = updateStateCandidates1(crlst,inStateOrd,vars);
        states1 = updateStateCandidates2(crs,vars);
        states = Util.listUnion(states1,states);
      then
        states;
    case ((cr,_)::crlst,inStateOrd,vars)
      equation
        failure(_ = getDerStateOrder(cr,inStateOrd));
        Debug.fcall("bltdump", BackendDump.debugStrCrefStr, ("remove stateCandidate: ",cr,"\n"));
        states = updateStateCandidates1(crlst,inStateOrd,vars);
      then
        states;
  end matchcontinue;
end updateStateCandidates1;

protected function updateStateCandidates2 "function: updateStateCandidates2
  author: Frenkel TUD 20-11"
  input list<DAE.ComponentRef> inCrLst;
  input BackendDAE.Variables vars;
  output list<tuple<DAE.ComponentRef,Integer>> outStates;   
algorithm
  outStates := matchcontinue (inCrLst,vars)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> crlst;
      Integer j;
      list<tuple<DAE.ComponentRef,Integer>> states;

    case ({},_) then {};
    case (cr::crlst,vars)
      equation
        (_::_,j::_) = BackendVariable.getVar(cr,vars);
        states = updateStateCandidates2(crlst,vars);
      then
        ((cr,j)::states);
    case (cr::crlst,vars)
      equation
        failure((_,_) = BackendVariable.getVar(cr,vars));
        states = updateStateCandidates2(crlst,vars);
      then
        states;
  end matchcontinue;
end updateStateCandidates2;

protected function analyseJac "function: analyseJac
  author: Frenkel TUD 20-11"
  input list<DAE.Exp> inJac;
  input list<tuple<DAE.ComponentRef,Integer>> inStates;
  input BackendDAE.Variables knvars;
  output list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> outDummyDer;
  output list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> outDynDummyDer;
algorithm
  (outDummyDer,outDynDummyDer) := matchcontinue (inJac,inStates,knvars)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      Integer i;
      list<tuple<DAE.ComponentRef,Integer>> crlst,crlst1;
      list<tuple<DAE.ComponentRef,Integer,DAE.Exp>> dummyder,dyndummyder;
      list<DAE.Exp> jac;
      list<DAE.ComponentRef> crs;

    case ({},{},_) then ({},{});
    case (e::jac,(cr,i)::crlst,knvars)
      equation
        false = Expression.isZero(e);
        true = Expression.isConst(e);
        (dummyder,dyndummyder) = analyseJac(jac,crlst,knvars);
      then
        ((cr,i,e)::dummyder,dyndummyder);
    case (e::jac,(cr,i)::crlst,knvars)
      equation
        false = Expression.isZero(e);
        crs = Expression.extractCrefsFromExp(e);
        crlst1 = updateStateCandidates2(crs,knvars);
        true = intEq(listLength(crs),listLength(crlst1));
        (dummyder,dyndummyder) = analyseJac(jac,crlst,knvars);
      then
        ((cr,i,e)::dummyder,dyndummyder);        
    case (e::jac,(cr,i)::crlst,knvars)
      equation
        false = Expression.isZero(e);
        (dummyder,dyndummyder) = analyseJac(jac,crlst,knvars);
      then
        (dummyder,(cr,i,e)::dyndummyder);
    case (_::jac,_::crlst,knvars)
      equation
        (dummyder,dyndummyder) = analyseJac(jac,crlst,knvars);
      then
        (dummyder,dyndummyder);
  end matchcontinue;
end analyseJac;

protected function analyseJac1 "function: analyseJac1
  author: Frenkel TUD 20-11"
  input list<DAE.Exp> inJac;
  input list<tuple<DAE.ComponentRef,Integer>> inStates;
  input BackendDAE.Variables knvars;
  input Integer inInteger;
  output list<tuple<Integer,Option<DAE.Exp>>> outJac;
  output Integer outInteger;
algorithm
  (outJac,outInteger) := matchcontinue (inJac,inStates,knvars,inInteger)
    local
      DAE.Exp e;
      DAE.ComponentRef cr;
      Integer i,k,l;
      list<tuple<DAE.ComponentRef,Integer>> crlst,crlst1;
      list<tuple<Integer,Option<DAE.Exp>>> jac1;
      list<DAE.Exp> jac;
      list<DAE.ComponentRef> crs;

    case ({},{},_,_) then ({},0);
    case (e::jac,(cr,i)::crlst,knvars,k)
      equation
        false = Expression.isZero(e);
        true = Expression.isConst(e);
        (jac1,l) = analyseJac1(jac,crlst,knvars,k+1);
      then
        ((i,NONE())::jac1,l+1);
    case (e::jac,(cr,i)::crlst,knvars,k)
      equation
        false = Expression.isZero(e);
        crs = Expression.extractCrefsFromExp(e);
        crlst1 = updateStateCandidates2(crs,knvars);
        true = intEq(listLength(crs),listLength(crlst1));
        (jac1,l) = analyseJac1(jac,crlst,knvars,k+1);
      then
        ((i,NONE())::jac1,l+1);        
    case (e::jac,(cr,i)::crlst,knvars,k)
      equation
        false = Expression.isZero(e);
        (jac1,l) = analyseJac1(jac,crlst,knvars,k+1);
      then
        ((i,SOME(e))::jac1,l+1);
    case (_::jac,_::crlst,knvars,k)
      equation
        //true = Expression.isZero(e);
        (jac1,l) = analyseJac1(jac,crlst,knvars,k+1);
      then
        (jac1,l);
  end matchcontinue;
end analyseJac1;

protected function calculateJacobian "function: calculateJacobian
  author: Frenkel TUD 20-11"
  input BackendDAE.Equation inEqn;
  input array<BackendDAE.MultiDimEquation> ae;
  input array<DAE.Algorithm> al;
  input list<tuple<DAE.ComponentRef,Integer>> inStates;
  output list<DAE.Exp> outJac;
algorithm
  outJac := matchcontinue (inEqn,ae,al,inStates)
    local
      BackendDAE.Equation eqn;
      DAE.Exp e,e1,e2,e_1,e_2;
      DAE.ComponentRef cr;
      list<tuple<DAE.ComponentRef,Integer>> crlst;
      list<DAE.Exp> jac,elst;
      Integer i;
      Boolean b;
      list<Boolean> blst;

    case (eqn,_,_,{}) then {};
    case (eqn as BackendDAE.EQUATION(exp = e1,scalar = e2),ae,al,(cr,_)::crlst)
      equation
        e = Expression.expSub(e1,e2);
        e_1 = Derive.differentiateExp(e, cr, true);
        (e_2,_) = ExpressionSimplify.simplify(e_1);
        jac = calculateJacobian(eqn,ae,al,crlst);
      then
        (e_2::jac);
    case (eqn as BackendDAE.ARRAY_EQUATION(index=i,crefOrDerCref=elst),ae,al,(cr,_)::crlst)
      equation
        BackendDAE.MULTIDIM_EQUATION(left=e1,right=e2) = ae[i+1]; 
        e = Expression.expSub(e1,e2);
        e_1 = Derive.differentiateExp(e, cr, true);
        (e_2,_) = ExpressionSimplify.simplify(e_1);
        jac = calculateJacobian(eqn,ae,al,crlst);
      then
        (e_2::jac); 
    case (eqn as BackendDAE.ALGORITHM(index=i,out=elst),ae,al,(cr,_)::crlst)
      equation
        blst = Util.listMap1(elst,Expression.expHasCref,cr);
        b = Util.boolOrList(blst);
        e_1 = Util.if_(b,DAE.RCONST(1.0),DAE.RCONST(0.0));
        jac = calculateJacobian(eqn,ae,al,crlst);
      then
        (e_1::jac);   
    case (eqn,ae,al,(cr,_)::crlst)
      equation
        jac = calculateJacobian(eqn,ae,al,crlst);
      then
        (DAE.RCONST(0.0)::jac);   
  end matchcontinue;
end calculateJacobian;

protected function dumpEqnsX
"function: dumpEqnsX
  author: Frenkel TUD"
  input tuple<BackendDAE.ConstraintEquations,array<BackendDAE.MultiDimEquation>> orgEqns;
algorithm
  _:=
  matchcontinue (orgEqns)
    local
      list<tuple<BackendDAE.Equation,Boolean>> orgeqns;
      BackendDAE.ConstraintEquations rest;
      Integer i;
      array<BackendDAE.MultiDimEquation> ae;
    case (({},_)) then ();
    case (((i,orgeqns)::rest,ae))
      equation
        print("OrgEqns: "); print(intString(i)); print("\n");
        dumpEqnsX1(orgeqns,ae);
        dumpEqnsX((rest,ae));
      then
        ();
  end matchcontinue;
end dumpEqnsX;

protected function dumpEqnsX1
"function: dumpEqnsX
  author: Frenkel TUD"
  input list<tuple<BackendDAE.Equation,Boolean>> orgEqns;
  input array<BackendDAE.MultiDimEquation> inMEqn;
algorithm
  _:=
  matchcontinue (orgEqns,inMEqn)
    local
      BackendDAE.Equation orgeqn;
      list<tuple<BackendDAE.Equation,Boolean>> rest;
      array<BackendDAE.MultiDimEquation> ae;
      DAE.Exp exp1,exp2;
      Integer i;
    case ({},_) then ();
    case (((orgeqn as BackendDAE.ARRAY_EQUATION(index=i)),_)::rest,ae)
      equation
        BackendDAE.MULTIDIM_EQUATION(left=exp1,right=exp2) = ae[i+1];
        print("  "); print(BackendDump.equationStr(orgeqn)); print("\n");         
        print("  "); print(ExpressionDump.printExpStr(exp1)); print(" = "); print(ExpressionDump.printExpStr(exp2)); print("\n");
        dumpEqnsX1(rest,ae);
      then
        ();
    case ((orgeqn,_)::rest,ae)
      equation
        print("  "); print(BackendDump.equationStr(orgeqn)); print("\n");         
        dumpEqnsX1(rest,ae);
      then
        ();
  end matchcontinue;
end dumpEqnsX1;

protected function dumpEqns1X
"function: dumpEqnsX
  author: Frenkel TUD"
  input tuple<list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>>,BackendDAE.BackendDAE> orgEqns;
algorithm
  _:=
  matchcontinue (orgEqns)
    local
      list<tuple<Integer,Integer,Boolean>> orgeqns;
      list<tuple<Integer,list<tuple<Integer,Integer,Boolean>>>> rest;
      Integer i;
      BackendDAE.BackendDAE dae;
    case (({},_)) then ();
    case (((i,orgeqns)::rest,dae))
      equation
        print("OrgEqns: "); print(intString(i)); print("\n");
        dumpEqns1X1(orgeqns,dae);
        dumpEqns1X((rest,dae));
      then
        ();
  end matchcontinue;
end dumpEqns1X;

protected function dumpEqns1X1
"function: dumpEqnsX
  author: Frenkel TUD"
  input list<tuple<Integer,Integer,Boolean>> orgEqns;
  input BackendDAE.BackendDAE dae;
algorithm
  _:=
  matchcontinue (orgEqns,dae)
    local
      BackendDAE.Equation orgeqn;
      list<tuple<Integer,Integer,Boolean>> rest;
      BackendDAE.EquationArray eqns;
      array<BackendDAE.MultiDimEquation> ae;
      DAE.Exp exp1,exp2;
      Integer i,e,l,e_1;
    case ({},_) then ();
    case ((e,l,_)::rest,dae as BackendDAE.DAE(orderedEqs=eqns,arrayEqs=ae))
      equation
        e_1 = e - 1;
        (orgeqn as BackendDAE.ARRAY_EQUATION(index=i)) = BackendDAEUtil.equationNth(eqns, e_1); 
        BackendDAE.MULTIDIM_EQUATION(left=exp1,right=exp2) = ae[i+1];
        print("  "); print(intString(l)); print("  ");  print(BackendDump.equationStr(orgeqn)); print("\n");         
        print("  "); print(ExpressionDump.printExpStr(exp1)); print(" = "); print(ExpressionDump.printExpStr(exp2)); print("\n");
        dumpEqns1X1(rest,dae);
      then
        ();
    case ((e,l,_)::rest,dae as BackendDAE.DAE(orderedEqs=eqns))
      equation
        e_1 = e - 1;
        orgeqn = BackendDAEUtil.equationNth(eqns, e_1); 
        print("  "); print(intString(l)); print("  ");  print(BackendDump.equationStr(orgeqn)); print("\n");         
        dumpEqns1X1(rest,dae);
      then
        ();
  end matchcontinue;
end dumpEqns1X1;



protected function dumpStates
"function: dumpStates
  author: Frenkel TUD"
  input tuple<DAE.ComponentRef,Integer> state;
  output String outStr;
algorithm
  outStr := intString(Util.tuple22(state)) +& " " +& ComponentReference.printComponentRefStr(Util.tuple21(state));
end dumpStates;

protected function dumpStates1
"function: dumpStates
  author: Frenkel TUD"
  input tuple<DAE.ComponentRef,Integer,DAE.Exp> state;
  output String outStr;
algorithm
  outStr := intString(Util.tuple32(state)) +& " " +& ComponentReference.printComponentRefStr(Util.tuple31(state)) +& " " +& ExpressionDump.printExpStr(Util.tuple33(state));
end dumpStates1;

/******************************************
 reduceIndexDummyDer and stuff
 *****************************************/

public function reduceIndexDummyDer
"function: reduceIndexDummyDer
  author: PA
  When matching fails, this function is called to try to
  reduce the index by differentiating the marked equations and
  replacing one of the variable with a dummy derivative, i.e. making
  it algebraic.
  The new BackendDAE.BackendDAE is returned along with an updated incidence matrix.

  inputs: (BackendDAE, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT,
             int /* number of vars */, int /* number of eqns */, int /* i */)
  outputs: (BackendDAE, BackendDAE.IncidenceMatrix, IncidenceMatrixT)"
  input BackendDAE.DAEHandlerJop inJop;
  input BackendDAE.BackendDAE inBackendDAE1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input DAE.FunctionTree inFunctions;
  input BackendDAE.Assignments inAssignments1;
  input BackendDAE.Assignments inAssignments2;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  input BackendDAE.DAEHandlerArg inArg;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output BackendDAE.Assignments outAssignments1;
  output BackendDAE.Assignments outAssignments2; 
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
  output BackendDAE.DAEHandlerArg outArg;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outAssignments1,outAssignments2,outDerivedAlgs,outDerivedMultiEqn,outArg):=
  matchcontinue (inJop,inBackendDAE1,inIncidenceMatrix2,inIncidenceMatrixT3,inFunctions,inAssignments1,inAssignments2,inDerivedAlgs,inDerivedMultiEqn,inArg)
    local
      list<BackendDAE.Value> eqns,diff_eqns,eqns_1,stateindx,deqns,reqns,changedeqns;
      list<BackendDAE.Key> states;
      BackendDAE.BackendDAE dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,stateno;
      DAE.ComponentRef state,dummy_der;
      list<String> es;
      String es_1;
      list<tuple<Integer,Integer,Integer>> derivedAlgs,derivedAlgs1;
      list<tuple<Integer,Integer,Integer>> derivedMultiEqn,derivedMultiEqn1;
      DAE.Exp stateexp,stateexpcall,dummyderexp;
      DAE.ExpType tp;
      BackendDAE.Assignments ass1,ass2;

    case (BackendDAE.REDUCE_INDEX(),dae,m,mt,inFunctions,ass1,ass2,derivedAlgs,derivedMultiEqn,inArg)
      equation
        eqns = BackendDAEEXT.getMarkedEqns();
        // print("marked equations:");print(Util.stringDelimitList(Util.listMap(eqns,intString),","));
        // print("\n");
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        // print("differentiating equations: ");print(Util.stringDelimitList(Util.listMap(eqns_1,intString),","));
        // print("\n");
        // print(BackendDump.dumpMarkedEqns(dae, eqns_1));

        // Collect the states in the equations that are singular, i.e. composing a constraint between states.
        // Note that states are collected from -all- marked equations, not only the differentiated ones.
        (states,stateindx) = statesInEqns(eqns, dae, m, mt);
        (dae,m,mt,deqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(dae, m, mt, eqns_1,inFunctions,derivedAlgs,derivedMultiEqn);
        (state,stateno) = selectDummyState(states, stateindx, dae, m, mt);
        // print("Selected ");print(ComponentReference.printComponentRefStr(state));print(" as dummy state\n");
        // print(" From candidates: ");print(Util.stringDelimitList(Util.listMap(states,ComponentReference.printComponentRefStr),", "));print("\n");
        // dae = propagateDummyFixedAttribute(dae, eqns_1, state, stateno);
        (dummy_der,dae) = newDummyVar(state, dae, DAE.NEW_DUMMY_DER(state,states));
        // print("Chosen dummy: ");print(ComponentReference.printComponentRefStr(dummy_der));print("\n");
        reqns = BackendDAEUtil.eqnsForVarWithStates(mt, stateno);
        changedeqns = Util.listUnionOnTrue(deqns, reqns, intEq);
        stateexp = Expression.crefExp(state);
        stateexpcall = DAE.CALL(Absyn.IDENT("der"),{stateexp},DAE.callAttrBuiltinReal);
        dummyderexp = Expression.crefExp(dummy_der);
        (dae,m,mt) = replaceDummyDer(stateexpcall, dummyderexp, dae, m, mt, changedeqns)
        "We need to change variables in the differentiated equations and in the equations having the dummy derivative" ;
        dae = makeAlgebraic(dae, state);
        (m,mt) = BackendDAEUtil.updateIncidenceMatrix(dae, m, mt, changedeqns);
        // print("new DAE:");
        // BackendDump.dump(dae);
        // print("new IM:");
        // BackendDump.dumpIncidenceMatrix(m);
        // BackendDump.dumpStateVariables(BackendVariable.daeVars(dae));
      then
        (dae,m,mt,ass1,ass2,derivedAlgs1,derivedMultiEqn1,inArg);

    case (BackendDAE.STARTSTEP(),dae,m,mt,inFunctions,ass1,ass2,derivedAlgs,derivedMultiEqn,inArg)
      then (dae,m,mt,ass1,ass2,derivedAlgs,derivedMultiEqn,inArg);

    case (BackendDAE.ENDSTEP(),dae,m,mt,inFunctions,ass1,ass2,derivedAlgs,derivedMultiEqn,inArg)
      then (dae,m,mt,ass1,ass2,derivedAlgs,derivedMultiEqn,inArg);

    case (BackendDAE.REDUCE_INDEX(),dae,m,mt,_,_,_,_,_,_)
      equation
        eqns = BackendDAEEXT.getMarkedEqns();
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
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
        print(Util.stringDelimitList(Util.listMap(BackendDAEEXT.getMarkedVariables(),intString),", "));
        print("\n");
      then
        fail();

    case (_,_,_,_,_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.reduceIndexDummyDer failed!"});
      then
        fail();

  end matchcontinue;
end reduceIndexDummyDer;

protected function makeAlgebraic
"function: makeAlgebraic
  author: PA
  Make the variable a dummy derivative, i.e.
  change varkind from STATE to DUMMY_STATE.
  inputs:  (BackendDAE, DAE.ComponentRef /* state */)
  outputs: (BackendDAE) = "
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.ComponentRef inComponentRef;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE:=
  matchcontinue (inBackendDAE,inComponentRef)
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

    case (BackendDAE.DAE(vars,kv,ev,av,e,se,ie,ae,al,wc,eoc),cr)
      equation
        ((BackendDAE.VAR(cr,kind,d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),indx) = BackendVariable.getVar(cr, vars);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(cr,BackendDAE.DUMMY_STATE(),d,t,b,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix), vars);
      then
        BackendDAE.DAE(vars_1,kv,ev,av,e,se,ie,ae,al,wc,eoc);

    case (_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.makeAlgebraic failed!"});
      then
        fail();

  end matchcontinue;
end makeAlgebraic;

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
  input BackendDAE.BackendDAE inBackendDAE;
  input list<Integer> inIntegerLst;
  input DAE.ComponentRef inComponentRef;
  input Integer inInteger;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  outBackendDAE := matchcontinue (inBackendDAE,inIntegerLst,inComponentRef,inInteger)
    local
      list<BackendDAE.Value> eqns;
      list<BackendDAE.Equation> eqns_lst;
      list<BackendDAE.Key> crefs;
      DAE.ComponentRef state,dummy;
      BackendDAE.Var v,v_1,v_2;
      BackendDAE.Value indx,indx_1,dummy_no;
      Boolean dummy_fixed;
      BackendDAE.Variables vars_1,vars,kv,ev;
      BackendDAE.AliasVariables av;
      BackendDAE.BackendDAE dae;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> al;
      BackendDAE.EventInfo ei;
      BackendDAE.ExternalObjectClasses eoc;

   /* eqns dummy state */
    case ((dae as BackendDAE.DAE(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_lst = BackendEquation.getEqns(eqns,e);
        crefs = BackendEquation.equationsCrefs(eqns_lst);
        (crefs, _) = Util.listDeleteMemberOnTrue(dummy, crefs, ComponentReference.crefEqualNoStringCompare);
        state = findState(vars, crefs);
        ({v},{indx}) = BackendVariable.getVar(dummy, vars);
        (dummy_fixed as false) = BackendVariable.varFixed(v);
        ({v_1},{indx_1}) = BackendVariable.getVar(state, vars);
        v_2 = BackendVariable.setVarFixed(v_1, dummy_fixed);
        vars_1 = BackendVariable.addVar(v_2, vars);
      then
        BackendDAE.DAE(vars_1,kv,ev,av,e,se,ie,ae,al,ei,eoc);

    // Never propagate fixed=true
    case ((dae as BackendDAE.DAE(vars,kv,ev,av,e,se,ie,ae,al,ei,eoc)),eqns,dummy,dummy_no)
      equation
        eqns_lst = BackendEquation.getEqns(eqns,e);
        crefs = BackendEquation.equationsCrefs(eqns_lst);
        (crefs, _) = Util.listDeleteMemberOnTrue(dummy, crefs, ComponentReference.crefEqualNoStringCompare);
        state = findState(vars, crefs);
        ({v},{indx}) = BackendVariable.getVar(dummy, vars);
        true = BackendVariable.varFixed(v);
      then dae;

    case (dae,_,_,_)
      equation
        Debug.fprint("failtrace", "propagate_dummy_initial_equations failed!");
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

protected function replaceDummyDer
"function: replaceDummyDer
  author: PA
  Helper function to reduceIndexDummyDer
  replaces der(state) with the variable dummy der.
  inputs:   (DAE.ComponentRef, /* state */
             DAE.ComponentRef, /* dummy der name */
             BackendDAE,
             IncidenceMatrix,
             IncidenceMatrixT,
             int list /* equations */)
  outputs:  (BackendDAE,
             IncidenceMatrix,
             IncidenceMatrixT)"
  input DAE.Exp inExp1;
  input DAE.Exp inExp2;
  input BackendDAE.BackendDAE inBackendDAE3;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix4;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT5;
  input list<Integer> inIntegerLst6;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT):=
  matchcontinue (inExp1,inExp2,inBackendDAE3,inIncidenceMatrix4,inIncidenceMatrixT5,inIntegerLst6)
    local
      BackendDAE.BackendDAE dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value e_1,e;
      BackendDAE.Equation eqn,eqn_1;
      BackendDAE.Variables v_1,v,kv,ev,aliasVars;
      BackendDAE.AliasVariables av;
      BackendDAE.EquationArray eqns_1,eqns,seqns,seqns1,ie,ie1;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2;
      array<DAE.Algorithm> al,al1,al2;
      list<BackendDAE.WhenClause> wclst,wclst1,wclst2;
      list<BackendDAE.ZeroCrossing> zeroCrossingLst;
      list<BackendDAE.Value> rest;
      BackendDAE.ExternalObjectClasses eoc;
      DAE.Exp stateexpcall,dummyderexp;

    case (stateexpcall,dummyderexp,BackendDAE.DAE(v,kv,ev,av as BackendDAE.ALIASVARS(aliasVars = aliasVars),eqns,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zeroCrossingLst),eoc),m,mt,{})
      equation
        ((_, _, av)) = BackendVariable.traverseBackendDAEVars(aliasVars,traverseReplaceAliasVarsBindExp,(stateexpcall, dummyderexp, av));
        (ie1,(al1,ae1,wclst1,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(ie,traversereplaceDummyDer,(al, ae, wclst, replaceDummyDer2Exp,(stateexpcall,dummyderexp)));
        (ie1,(al1,ae1,wclst1,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(ie,traversereplaceDummyDer,(al, ae, wclst, replaceDummyDer2Exp,(stateexpcall,dummyderexp)));
        (seqns1,(al2,ae2,wclst2,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(seqns,traversereplaceDummyDer,(al1, ae1, wclst1, replaceDummyDer2Exp,(stateexpcall,dummyderexp)));
       then (BackendDAE.DAE(v,kv,ev,av,eqns,seqns1,ie1,ae2,al2,BackendDAE.EVENT_INFO(wclst2,zeroCrossingLst),eoc),m,mt);

    case (stateexpcall,dummyderexp,BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zeroCrossingLst),eoc),m,mt,(e :: rest))
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        (eqn_1,al1,ae1,wclst1,_) = traverseBackendDAEExpsEqn(eqn, al, ae, wclst, replaceDummyDer2Exp,(stateexpcall,dummyderexp));
        (eqn_1,al2,ae2,wclst2,(v_1,_)) = traverseBackendDAEExpsEqn(eqn_1,al1,ae1,wclst1,replaceDummyDerOthersExp,(v,0));
        eqns_1 = BackendEquation.equationSetnth(eqns, e_1, eqn_1)
         "incidence_row(v\'\',eqn\') => row\' &
          Util.list_replaceat(row\',e\',m) => m\' &
          transpose_matrix(m\') => mt\' &" ;
        (dae,m,mt) = replaceDummyDer(stateexpcall, dummyderexp, BackendDAE.DAE(v_1,kv,ev,av,eqns_1,seqns,ie,ae2,al2,BackendDAE.EVENT_INFO(wclst2,zeroCrossingLst),eoc), m, mt, rest);
      then
        (dae,m,mt);

    case (_,_,_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.replaceDummyDer failed!"});
      then
        fail();

  end matchcontinue;
end replaceDummyDer;

protected function traversereplaceDummyDer
"function traversereplaceDummyDer
  author: Frenkel TUD 2010-11."
  replaceable type Type_a subtypeof Any;
  input tuple<BackendDAE.Equation,tuple<array<DAE.Algorithm>,array<BackendDAE.MultiDimEquation>,list<BackendDAE.WhenClause>,FuncExpType,Type_a>> inTpl;
  output tuple<BackendDAE.Equation,tuple<array<DAE.Algorithm>,array<BackendDAE.MultiDimEquation>,list<BackendDAE.WhenClause>,FuncExpType,Type_a>> outTpl;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inExpTypeA;
    output tuple<DAE.Exp, Type_a> outExpTypeA;
  end FuncExpType;
algorithm
  outTpl :=
  matchcontinue inTpl
    local 
      BackendDAE.Equation e,e1;
      array<DAE.Algorithm> algs,algs1;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<BackendDAE.WhenClause> wclst,wclst1;
      Type_a ext_arg,ext_arg_1;
      FuncExpType func;
    case ((e,(algs,ae,wclst,func,ext_arg)))
      equation
         (e1,algs1,ae1,wclst1,ext_arg_1) = traverseBackendDAEExpsEqn(e,algs,ae,wclst,func,ext_arg);
      then
        ((e1,(algs1,ae1,wclst1,func,ext_arg_1)));
    case inTpl then inTpl;
  end matchcontinue;
end traversereplaceDummyDer;

public function traverseBackendDAEExpsEqn
"function: traverseBackendDAEExpsEqn
  author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outAlgs,outMultiDimEquationArray,outWhenClauseLst,(_,outTypeA)) := traverseBackendDAEExpsEqnWithSymbolicOperation(inEquation,inAlgs,inMultiDimEquationArray,inWhenClauseLst,traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper,(func,inTypeA));
end traverseBackendDAEExpsEqn;

protected function traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper
  replaceable type Type_a subtypeof Any;
  input tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,tuple<FuncExpType,Type_a>>> inTpl;
  output tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,tuple<FuncExpType,Type_a>>> outTpl;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
protected
  FuncExpType func;
  Type_a arg;
  list<DAE.SymbolicOperation> ops;
  DAE.Exp exp;
algorithm
  (exp,(ops,(func,arg))) := inTpl;
  ((exp,arg)) := func((exp,arg));
  outTpl := (exp,(ops,(func,arg)));
end traverseBackendDAEExpsEqnWithoutSymbolicOperationHelper;

public function traverseBackendDAEExpsEqnWithSymbolicOperation
"Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input BackendDAE.Equation inEquation;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output BackendDAE.Equation outEquation;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,Type_a>> inTpl;
    output tuple<DAE.Exp, tuple<list<DAE.SymbolicOperation>,Type_a>> outTpl;
  end FuncExpType;
algorithm
  (outEquation,outAlgs,outMultiDimEquationArray,outWhenClauseLst,outTypeA) := matchcontinue (inEquation,inAlgs,inMultiDimEquationArray,inWhenClauseLst,func,inTypeA)
    local
      DAE.Exp e1_1,e2_1,e1,e2;
      DAE.ComponentRef cr,cr1;
      BackendDAE.Value ds,indx,i;
      list<DAE.Exp> expl,expl1,in_,in_1,out,out1;
      BackendDAE.Equation res;
      BackendDAE.WhenEquation elsepartRes;
      BackendDAE.WhenEquation elsepart;
      DAE.ElementSource source,source1;
      array<DAE.Algorithm> algs;
      array<BackendDAE.MultiDimEquation> ae,ae1;
      list<BackendDAE.WhenClause> wclst,wclst1,wclst2;
      list<Integer> dimSize;
      list<DAE.SymbolicOperation> ops;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((e2_1,(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        source = Util.listFoldR(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source),inAlgs,ae,wclst,ext_arg_2);
    case (BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        (expl1,(ops,ext_arg_1)) = BackendEquation.traverseBackendDAEExpList(expl,func,({},inTypeA));
        i = ds+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        ((e1_1,(ops,ext_arg_2))) = func((e1,(ops,ext_arg_1)));
        ((e2_1,(ops,ext_arg_3))) = func((e2,(ops,ext_arg_2)));
        source = Util.listFoldR(ops, DAEUtil.addSymbolicTransformation, source);
        ae1 = arrayUpdate(ae,i,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (BackendDAE.ARRAY_EQUATION(ds,expl1,source),inAlgs,ae1,wclst,ext_arg_3);  /* array equation */
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source),inAlgs,ae,wclst,func,inTypeA)
      equation
        e1 = Expression.crefExp(cr);
        ((DAE.CREF(cr1,_),(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((e2_1,(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        source = Util.listFoldR(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e2_1,source),inAlgs,ae,wclst,ext_arg_1);
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source),inAlgs,ae,wclst,func,inTypeA)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        source = Util.listFoldR(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.RESIDUAL_EQUATION(e1_1,source),inAlgs,ae,wclst,ext_arg_1);
    case (BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out,source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        (in_1,(ops,ext_arg_1)) = BackendEquation.traverseBackendDAEExpList(in_,func,({},inTypeA));
        (out1,(ops,ext_arg_2)) = BackendEquation.traverseBackendDAEExpList(out,func,(ops,ext_arg_1));
        (algs,(ops,ext_arg_3)) = traverseBackendDAEExpsEqnAlgs(indx,inAlgs,func,(ops,ext_arg_2));
        source = Util.listFoldR(ops, DAEUtil.addSymbolicTransformation, source);
      then (BackendDAE.ALGORITHM(indx,in_1,out1,source),algs,ae,wclst,ext_arg_3);  /* Algorithms */
    case (BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=NONE()),source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        e2 = Expression.crefExp(cr);
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((DAE.CREF(cr1,_),(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        source = Util.listFoldR(ops, DAEUtil.addSymbolicTransformation, source);
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr1,e1_1,NONE()),source);
        (wclst1,(_,ext_arg_3)) = traverseBackendDAEExpsWhenClause(SOME(i),wclst,func,({} /*TODO: Save me?*/,ext_arg_2));
      then
        (res,inAlgs,ae,wclst1,ext_arg_3);

    case (BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=SOME(elsepart)),source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        source = Util.listFoldR(ops, DAEUtil.addSymbolicTransformation, source);
        (BackendDAE.WHEN_EQUATION(elsepartRes,source),algs,ae1,wclst1,ext_arg_2) = traverseBackendDAEExpsEqnWithSymbolicOperation(BackendDAE.WHEN_EQUATION(elsepart,source),inAlgs,ae,wclst,func,ext_arg_1);
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e1_1,SOME(elsepartRes)),source);
        (wclst2,(_,ext_arg_3)) = traverseBackendDAEExpsWhenClause(SOME(i),wclst1,func,({} /* TODO: Save me?*/,ext_arg_2));
      then
        (res,algs,ae1,wclst2,ext_arg_3);
    case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        ((e1_1,(ops,ext_arg_1))) = func((e1,({},inTypeA)));
        ((e2_1,(ops,ext_arg_2))) = func((e2,(ops,ext_arg_1)));
        source = Util.listFoldR(ops, DAEUtil.addSymbolicTransformation, source);
      then
        (BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source),inAlgs,ae,wclst,ext_arg_2);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.traverseBackendDAEExpsEqnWithSymbolicOperation failed!"});
      then
        fail();
  end matchcontinue;
end traverseBackendDAEExpsEqnWithSymbolicOperation;

protected function traverseBackendDAEExpsWhenClause
"function: traverseBackendDAEExpsWhenClause
  author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input Option<Integer> inInteger;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outWhenClauseLst,outTypeA) := matchcontinue (inInteger,inWhenClauseLst,func,inTypeA)
    local
      Integer indx;
      Option<Integer> elsindx;
      list<BackendDAE.WhenOperator> reinitStmtLst,reinitStmtLst1;
      DAE.Exp cond,cond1;
      list<BackendDAE.WhenClause> wclst,wclst1,wclst2;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;

    case (NONE(),wclst,func,inTypeA) then (wclst,inTypeA);

    case (SOME(indx),wclst,func,inTypeA)
      equation
        BackendDAE.WHEN_CLAUSE(cond,reinitStmtLst,elsindx) = listNth(wclst,indx);
        (wclst1,ext_arg_1) =  traverseBackendDAEExpsWhenClause(elsindx,wclst,func,inTypeA);
        ((cond1,ext_arg_2)) = func((cond,ext_arg_1));
        (reinitStmtLst1,ext_arg_3) = traverseBackendDAEExpsWhenOperator(reinitStmtLst,func,ext_arg_2);
        wclst2 = Util.listReplaceAt(BackendDAE.WHEN_CLAUSE(cond,reinitStmtLst1,elsindx),indx,wclst1);
      then
        (wclst2,ext_arg_3);
     case (_,_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.traverseBackendDAEExpsWhenClause failed!"});
      then
        fail();
  end matchcontinue;
end traverseBackendDAEExpsWhenClause;

protected function traverseBackendDAEExpsWhenOperator
"function: traverseBackendDAEExpsWhenOperator
  author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.WhenOperator> inReinitStmtLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.WhenOperator> outReinitStmtLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outReinitStmtLst,outTypeA) := matchcontinue (inReinitStmtLst,func,inTypeA)
    local
      list<BackendDAE.WhenOperator> res,res1;
      BackendDAE.WhenOperator wop;
      DAE.Exp cond,cond1,msg;
      DAE.ComponentRef cr;
      DAE.ElementSource source;
      Type_a ext_arg_1,ext_arg_2;

    case ({},func,inTypeA) then ({},inTypeA);

    case (BackendDAE.REINIT(stateVar=cr,value=cond,source=source)::res,func,inTypeA)
      equation
        (res1,ext_arg_1) =  traverseBackendDAEExpsWhenOperator(res,func,inTypeA);
        ((cond1,ext_arg_2)) = func((cond,ext_arg_1));
      then
        (BackendDAE.REINIT(cr,cond1,source)::res1,ext_arg_2);

    case (BackendDAE.ASSERT(condition=cond,message=msg,source=source)::res,func,inTypeA)
      equation
        (res1,ext_arg_1) =  traverseBackendDAEExpsWhenOperator(res,func,inTypeA);
        ((cond1,ext_arg_2)) = func((cond,ext_arg_1));
      then
        (BackendDAE.ASSERT(cond1,msg,source)::res1,ext_arg_2);

    case (wop::res,func,inTypeA)
      equation
        (res1,ext_arg_1) =  traverseBackendDAEExpsWhenOperator(res,func,inTypeA);
      then
        (wop::res1,ext_arg_1);
     case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.traverseBackendDAEExpsWhenOperator failed!"});
      then
        fail();
  end matchcontinue;
end traverseBackendDAEExpsWhenOperator;

public function traverseBackendDAEExpsWhenClauseLst
"function: traverseBackendDAEExpsWhenClauseLst
  author: Frenkel TUD 2010-11
  Traverse all expressions of a when clause list. It is possible to change the expressions"
  replaceable type Type_a subtypeof Any; 
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;  
algorithm
  (outWhenClauseLst,outTypeA) := matchcontinue (inWhenClauseLst,func,inTypeA)
    local
      Option<Integer> elsindx;
      list<BackendDAE.WhenOperator> reinitStmtLst,reinitStmtLst1;
      DAE.Exp cond,cond1;
      list<BackendDAE.WhenClause> wclst,wclst1;
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;

    case ({},func,inTypeA) then ({},inTypeA);

    case (BackendDAE.WHEN_CLAUSE(cond,reinitStmtLst,elsindx)::wclst,func,inTypeA)
      equation
        ((cond1,ext_arg_1)) = func((cond,inTypeA));
        (reinitStmtLst1,ext_arg_2) = traverseBackendDAEExpsWhenOperator(reinitStmtLst,func,ext_arg_1);
        (wclst1,ext_arg_3) = traverseBackendDAEExpsWhenClauseLst(wclst,func,ext_arg_2);
      then
        (BackendDAE.WHEN_CLAUSE(cond1,reinitStmtLst1,elsindx)::wclst1,ext_arg_3);
     case (_,_,_)
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"- BackendDAETransform.traverseBackendDAEExpsWhenClauseLst failed!"});
      then
        fail();
  end matchcontinue;
end traverseBackendDAEExpsWhenClauseLst;

protected function traverseBackendDAEExpsEqnAlgs
  replaceable type Type_a subtypeof Any;
  input Integer inIndex;
  input array<DAE.Algorithm> inAlgs;
  input FuncExpType func;
  input Type_a inTypeA;
  output array<DAE.Algorithm> outAlgs;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outAlgs,outTypeA):=
  match (inIndex,inAlgs,func,inTypeA)
    local  
      array<DAE.Algorithm> algs;
      list<DAE.Statement> statementLst,statementLst1;
      Integer i_1;
      Type_a ext_arg_1;
  case (inIndex,inAlgs,func,inTypeA)
    equation
        // get Allgorithm
        i_1 = inIndex+1;
        DAE.ALGORITHM_STMTS(statementLst= statementLst) = inAlgs[i_1];
        (statementLst1,ext_arg_1) = DAEUtil.traverseDAEEquationsStmts(statementLst,func,inTypeA);
        algs = arrayUpdate(inAlgs,i_1,DAE.ALGORITHM_STMTS(statementLst1));
    then
      (algs,ext_arg_1);
  end match;
end traverseBackendDAEExpsEqnAlgs;

protected function traverseBackendDAEExpsEqnList
"function traverseBackendDAEExpsEqnList
  author: Frenkel TUD 2010-11
  Traverse all expressions of a list of Equations. It is possible to change the equations
  and the multidim equations and the algorithms."
  replaceable type Type_a subtypeof Any;
  input list<BackendDAE.Equation> inEquations;
  input array<DAE.Algorithm> inAlgs;
  input array<BackendDAE.MultiDimEquation> inMultiDimEquationArray;
  input list<BackendDAE.WhenClause> inWhenClauseLst;
  input FuncExpType func;
  input Type_a inTypeA;
  output list<BackendDAE.Equation> outEquations;
  output array<DAE.Algorithm> outAlgs;
  output array<BackendDAE.MultiDimEquation> outMultiDimEquationArray;
  output list<BackendDAE.WhenClause> outWhenClauseLst;
  output Type_a outTypeA;
  partial function FuncExpType
    input tuple<DAE.Exp, Type_a> inTpl;
    output tuple<DAE.Exp, Type_a> outTpl;
  end FuncExpType;
algorithm
  (outEquations,outAlgs,outMultiDimEquationArray,outWhenClauseLst,outTypeA):=
  matchcontinue (inEquations,inAlgs,inMultiDimEquationArray,inWhenClauseLst,func,inTypeA)
    local
      list<BackendDAE.Equation> eqns1,eqns;
      BackendDAE.Equation e,e1;
      array<DAE.Algorithm> algs,algs1;
      array<BackendDAE.MultiDimEquation> ae,ae1,ae2;
      list<BackendDAE.WhenClause> wclst,wclst1,wclst2;
      Type_a ext_arg_1,ext_arg_2;
    case ({},inAlgs,ae,wclst,func,inTypeA) then ({},inAlgs,ae,wclst,inTypeA);
    case (e::eqns,inAlgs,ae,wclst,func,inTypeA)
      equation
         (e1,algs,ae1,wclst1,ext_arg_1) = traverseBackendDAEExpsEqn(e,inAlgs,ae,wclst,func,inTypeA);
         (eqns1,algs1,ae2,wclst2,ext_arg_2) = traverseBackendDAEExpsEqnList(eqns,algs,ae1,wclst1,func,ext_arg_1);
      then
        (e1::eqns1,algs1,ae2,wclst2,ext_arg_2);
  end matchcontinue;
end traverseBackendDAEExpsEqnList;

public function replaceDummyDer2Exp
"function: replaceDummyDer2Exp
  author: Frenkel TUD 2010-11
  "
  input tuple<DAE.Exp,tuple<DAE.Exp,DAE.Exp>> inTpl;
  output tuple<DAE.Exp,tuple<DAE.Exp,DAE.Exp>> outTpl;
protected
  DAE.Exp e,e_1,e1,e2;
algorithm
  (e,(e1,e2)) := inTpl;
  ((e_1,_)) := Expression.replaceExp(e,e1,e2);
  outTpl := ((e_1,(e1,e2)));
end replaceDummyDer2Exp;

public function replaceDummyDerOthersExp
"function: equationsCrefs
  author: PA
  This function replaces
  1. der(der_s)  with der2_s (Where der_s is a dummy state)
  2. der(der(v)) with der2_v (where v is a state)
  3. der(v)  for alg. var v with der_v
  in the BackendDAE.Equation given as arguments. To do this it needs the Variables
  also passed as argument to the function to e.g. determine if a variable
  is a dummy variable, etc.  "
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,Integer>> inTpl;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,Integer>> outTpl;
protected
  DAE.Exp e;
  tuple<BackendDAE.Variables,Integer> vars;
algorithm
  (e,vars) := inTpl;
  outTpl := Expression.traverseExp(e,replaceDummyDerOthersExpFinder,vars);
end replaceDummyDerOthersExp;

protected function traverseReplaceAliasVarsBindExp
"function traverseReplaceAliasVarsBindExp
  Helper function to replaceDummyDer.
  Replaces all variable bindings of the alias variables."
 input tuple<BackendDAE.Var, tuple<DAE.Exp,DAE.Exp,BackendDAE.AliasVariables>> inTpl;
 output tuple<BackendDAE.Var, tuple<DAE.Exp,DAE.Exp,BackendDAE.AliasVariables>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local
      Integer i;
      DAE.Exp e,en,e1,e2;
      BackendDAE.Var v;
      BackendDAE.AliasVariables av;
    case((v,(e1,e2,av)))
      equation
        e = BackendVariable.varBindExp(v);
        ((en,i)) = Expression.replaceExp(e,e1,e2);
        v = BackendVariable.setBindExp(v,en);
        v = BackendVariable.mergeVariableOperations(v,Util.if_(i>0,{DAE.SUBSTITUTION({en},e)},{}));
        av = BackendDAEUtil.addAliasVariables({v},av);
      then ((v,(e1,e2,av)));
    case inTpl then inTpl;
  end matchcontinue;
end traverseReplaceAliasVarsBindExp;

protected function replaceDummyDerOthersExpFinder
"function: replaceDummyDerOthersExpFinder
  author: PA
  Helper function for replaceDummyDerOthersExp"
  input tuple<DAE.Exp,tuple<BackendDAE.Variables,Integer>> inExp;
  output tuple<DAE.Exp,tuple<BackendDAE.Variables,Integer>> outExp;
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
      DAE.ComponentRef dummyder,cr;
      DAE.ElementSource source "the source of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAE.Subscript> lstSubs;
      Integer i;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),(vars,i)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.STATE(),a,b,c,d,lstSubs,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        dummyder = ComponentReference.crefPrefixDer(dummyder);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b, NONE(), NONE(), lstSubs, 0, source, NONE(), comment, flowPrefix, streamPrefix), vars);
        e = Expression.makeCrefExp(dummyder,DAE.ET_REAL());
      then
        ((e, (vars_1,i+1)));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,i)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,b,c,d,lstSubs,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(der_s)) der_s is dummy var => der_der_s" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b, NONE(), NONE(), lstSubs, 0, source, NONE(), comment, flowPrefix, streamPrefix), vars);
        e = Expression.makeCrefExp(dummyder,DAE.ET_REAL());
      then
        ((e, (vars_1,i+1)));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),(vars,i)))
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,b,c,d,lstSubs,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b, NONE(), NONE(), lstSubs, 0, source, NONE(), comment, flowPrefix, streamPrefix), vars);
        e = Expression.makeCrefExp(dummyder,DAE.ET_REAL());
      then
        ((e, (vars_1,i+1)));

    case inExp then inExp;

  end matchcontinue;
end replaceDummyDerOthersExpFinder;

protected function newDummyVar
"function: newDummyVar
  author: PA
  This function creates a new variable named
  der+<varname> and adds it to the dae."
  input DAE.ComponentRef inComponentRef;
  input BackendDAE.BackendDAE inBackendDAE;
  input DAE.SymbolicOperation op;
  output DAE.ComponentRef outComponentRef;
  output BackendDAE.BackendDAE outBackendDAE;
algorithm
  (outComponentRef,outBackendDAE):=
  matchcontinue (inComponentRef,inBackendDAE,op)
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

    case (var,BackendDAE.DAE(vars, kv, ev, av, eqns, seqns, ie, ae, al, wc,eoc),op)
      equation
        ((BackendDAE.VAR(name,kind,dir,tp,bind,value,dim,idx,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(var, vars);
        dummyvar_cr = ComponentReference.crefPrefixDer(name);
        /* start value is not the same */
        source = DAEUtil.addSymbolicTransformation(source,op);
        dummyvar = BackendDAE.VAR(dummyvar_cr,BackendDAE.DUMMY_DER(),dir,tp,NONE(),NONE(),dim,0,source,NONE(),comment,flowPrefix,streamPrefix);
        /* Dummy variables are algebraic variables, hence fixed = false */
        dummyvar = BackendVariable.setVarFixed(dummyvar,false);
        vars_1 = BackendVariable.addVar(dummyvar, vars);
      then
        (dummyvar_cr,BackendDAE.DAE(vars_1,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc));

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"BackendDAE.newDummyVar failed!"});
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
            BackendDAE,
            IncidenceMatrix,
            IncidenceMatrixT)
  outputs: (DAE.ComponentRef, int)"
  input list<DAE.ComponentRef> varCrefs;
  input list<Integer> varIndices;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef;
  output Integer outInteger;
algorithm
  (outComponentRef,outInteger):=
  matchcontinue (varCrefs,varIndices,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef s;
      BackendDAE.Value sn;
      BackendDAE.Variables vars,knvars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EquationArray eqns;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;
      BackendDAE.BackendDAE dae;

    case (varCrefs,varIndices,BackendDAE.DAE(orderedVars=vars,knownVars=knvars,orderedEqs = eqns),m,mt)
      equation
        prioTuples = calculateVarPriorities(varCrefs,varIndices,vars,knvars,eqns,m,mt);
        //print("priorities:");print(Util.stringDelimitList(Util.listMap(prioTuples,printPrioTuplesStr),","));print("\n");
        (s,sn) = selectMinPrio(prioTuples);
      then (s,sn);

    case ({},_,dae,_,_)
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
  (s,sn) := match(tuples)
    case(tuples)
      equation
        ((s,sn,_)) = Util.listReduce(tuples,ssPrioTupleMin);
      then (s,sn);
  end match;
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
  input BackendDAE.Variables knvars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := match(varCrefs,varIndices,vars,knvars,eqns,m,mt)
  local DAE.ComponentRef varCref;
    Integer varIndx;
    BackendDAE.Var v;
    Real prio,prio1,prio2;
    list<tuple<DAE.ComponentRef,Integer,Real>> prios;
    case({},{},_,_,_,_,_) then {};
    case (varCref::varCrefs,varIndx::varIndices,vars,knvars,eqns,m,mt) equation
      prios = calculateVarPriorities(varCrefs,varIndices,vars,knvars,eqns,m,mt);
      v = BackendVariable.getVarAt(vars,varIndx);
      prio1 = varStateSelectPrio(v);
      prio2 = varStateSelectHeuristicPrio(v,varIndx,vars,knvars,eqns,m,mt);
      prio = prio1 +. prio2;
      Debug.fcall("dummyselect",BackendDump.debugStrCrefStrRealStrRealStrRealStr,("Calc Prio for ",varCref,"\n Prio StateSelect : ",prio1,"\n Prio Heuristik : ",prio2,"\n ### Prio Result : ",prio,"\n"));
    then ((varCref,varIndx,prio)::prios);
  end match;
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
  input Integer vindx;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output Real prio;
protected
  list<Integer> vEqns;
  DAE.ComponentRef vCr;
//  Integer vindx;
  Real prio1,prio2,prio3,prio4,prio5;
algorithm
//  (_,vindx::_) := BackendVariable.getVar(BackendVariable.varCref(v),vars); // Variable index not stored in var itself => lookup required
  vEqns := BackendDAEUtil.eqnsForVarWithStates(mt,vindx);
  vCr := BackendVariable.varCref(v);
  prio1 := varStateSelectHeuristicPrio1(vCr,vEqns,vars,knvars,eqns);
  prio2 := varStateSelectHeuristicPrio2(vCr,vars);
  prio3 := varStateSelectHeuristicPrio3(vCr,vars);
 // prio4 := varStateSelectHeuristicPrio4(v);
  prio5 := varStateSelectHeuristicPrio5(v);
  Debug.fcall("dummyselect",BackendDump.debugStrRealStrRealStrRealStrRealStr,(" Prio 1 : ",prio1,"\n Prio 2 : ",prio2,"\n Prio 3 : ",prio3,"\n Prio 5 : ",prio5,"\n"));
  prio:= prio1 +. prio2 +. prio3 +. prio5;// +. prio4;
end varStateSelectHeuristicPrio;

protected function varStateSelectHeuristicPrio5
"function varStateSelectHeuristicPrio5
  author: Frenkel TUD 2011-05
  Helper function to varStateSelectHeuristicPrio.
  added prio for variables with fixed = true "
  input BackendDAE.Var v;
  output Real prio;
algorithm
  prio := matchcontinue(v)
    local Integer i; Real c;
    case(v)
      equation
        true = BackendVariable.varFixed(v);
      then 1.0;
    case (_) then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio5;

protected function varStateSelectHeuristicPrio4
"function varStateSelectHeuristicPrio4
  author: wbraun
  Helper function to varStateSelectHeuristicPrio.
  added prio for variables with a start value "
  input BackendDAE.Var v;
  output Real prio;
algorithm
  prio := matchcontinue(v)
    local Integer i; Real c;
    case(v)
      equation
        _ = BackendVariable.varStartValueFail(v);
      then 1.0;
    case (_) then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio4;


protected function varStateSelectHeuristicPrio3
"function varStateSelectHeuristicPrio3
  author: PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input BackendDAE.Variables vars;
  output Real prio;
algorithm
  prio := match(cr,vars)
    local Integer i; Real c;
    case(cr,vars)
      equation
        ((_,i)) = BackendVariable.traverseBackendDAEVars(vars,varHasSameLastIdent,(cr,0));
        c = intReal(i);
        prio = c *. 0.01;
      then prio;
  end match;
end varStateSelectHeuristicPrio3;

protected function varHasSameLastIdent
"function varHasSameLastIdent
  Helper funciton to varStateSelectHeuristicPrio3.
  Returns true if the variable has the same name (the last identifier)
  as the variable name given as second argument."
 input tuple<BackendDAE.Var, tuple<DAE.ComponentRef,Integer>> inTpl;
 output tuple<BackendDAE.Var, tuple<DAE.ComponentRef,Integer>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local 
      DAE.ComponentRef cr,cr2;
      BackendDAE.Var v;
      Integer i;
    case((v,(cr,i)))
      equation
        cr2 = BackendVariable.varCref(v);
        true = ComponentReference.crefLastIdentEqual(cr,cr2);
      then ((v,(cr,i+1)));
    case inTpl then inTpl;
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
    case(cr,vars)
      equation
        ((_,true)) = BackendVariable.traverseBackendDAEVars(vars,varInSameComponent,(cr,false));
      then -1.0;
    case(cr,vars) then 0.0;
  end matchcontinue;
end varStateSelectHeuristicPrio2;

protected function varInSameComponent
"function varInSameComponent
  Helper funciton to varStateSelectHeuristicPrio2.
  Returns true if the variable is defined in the same sub
  component as the variable name given as second argument."
 input tuple<BackendDAE.Var, tuple<DAE.ComponentRef,Boolean>> inTpl;
 output tuple<BackendDAE.Var, tuple<DAE.ComponentRef,Boolean>> outTpl;
algorithm
  outTpl := matchcontinue(inTpl)
    local 
      DAE.ComponentRef cr,cr2;
      BackendDAE.Var v;
    case((v,(cr,true))) then ((v,(cr,true)));
    case((v,(cr,_)))
      equation
        cr2 = BackendVariable.varCref(v);
        true = BackendVariable.isDummyStateVar(v);
        true = ComponentReference.crefEqualNoStringCompare(ComponentReference.crefStripLastIdent(cr2),ComponentReference.crefStripLastIdent(cr));
      then ((v,(cr,true)));
    case inTpl then inTpl;
  end matchcontinue;
end varInSameComponent;

protected function varStateSelectHeuristicPrio1
"function varStateSelectHeuristicPrio1
  author:  PA
  Helper function to varStateSelectHeuristicPrio"
  input DAE.ComponentRef cr;
  input list<Integer> eqnLst;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  input BackendDAE.EquationArray eqns;
  output Real prio;
algorithm
  prio := matchcontinue(cr,eqnLst,vars,knvars,eqns)
    local Integer e; BackendDAE.Equation eqn;
    case(cr,{},_,_,_) then 0.0;
    case(cr,e::eqnLst,vars,_,eqns)
      equation
        eqn = BackendDAEUtil.equationNth(eqns,e-1);
        true = isStateConstraintEquation(cr,eqn,vars);
      then -1.0;
    case(cr,e::eqnLst,vars,knvars,eqns)
      equation
        eqn = BackendDAEUtil.equationNth(eqns,e-1);
        true = isStateAssignEquation(cr,eqn,vars,knvars);
      then -0.5;
    case(cr,_::eqnLst,vars,knvars,eqns) then varStateSelectHeuristicPrio1(cr,eqnLst,vars,knvars,eqns);
 end matchcontinue;
end varStateSelectHeuristicPrio1;

protected function isStateConstraintEquation
"function isStateConstraintEquation
  author: PA
  Help function to varStateSelectHeuristicPrio1
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
      DAE.Exp e2;

    // s = expr(s1,..,sn)  where s1 .. sn are states
    case(cr,BackendDAE.EQUATION(exp = DAE.CREF(cr2,_), scalar = e2),vars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Expression.terms(e2);
        crs = Expression.extractCrefsFromExp(e2);
        (crVars,_) = Util.listMap12(crs,BackendVariable.getVar,vars);
        // fails if not all mapped calls return true
      then Util.listMapAllValue(Util.listFlatten(crVars),BackendVariable.isStateVar,true);

    case(cr,BackendDAE.EQUATION(exp = e2, scalar = DAE.CREF(cr2,_)),vars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Expression.terms(e2);
        crs = Expression.extractCrefsFromExp(e2);
        (crVars,_) = Util.listMap12(crs,BackendVariable.getVar,vars);
        // fails if not all mapped calls return true
      then Util.listMapAllValue(Util.listFlatten(crVars),BackendVariable.isStateVar,true);

    else false;
  end matchcontinue;
end isStateConstraintEquation;

protected function isStateAssignEquation
"function isStateAssignEquation
  author: Frenkel TUD 2011-04
  Help function to varStateSelectHeuristicPrio1
  Returns true if an equation is on the form cr = expr(s1,s2...sn,pv1,...,pvn) for states cr, s1,s2..,sn, and parameters pv1,...,pvn "
  input DAE.ComponentRef cr;
  input BackendDAE.Equation eqn;
  input BackendDAE.Variables vars;
  input BackendDAE.Variables knvars;
  output Boolean res;
algorithm
  res := matchcontinue(cr,eqn,vars,knvars)
    local
      DAE.ComponentRef cr2;
      list<DAE.ComponentRef> crs;
      list<list<BackendDAE.Var>> crVars,prVars;
      DAE.Exp e2;
      Boolean b1,b2,b;

    case(cr,BackendDAE.EQUATION(exp = DAE.CREF(cr2,_), scalar = e2),vars,knvars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Expression.terms(e2);
      then true;

    case(cr,BackendDAE.EQUATION(exp = e2, scalar = DAE.CREF(cr2,_)),vars,knvars)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cr2);
        _::_::_ = Expression.terms(e2);
      then true;

    else false;
  end matchcontinue;
end isStateAssignEquation;

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
  prio := match(ss)
    case (DAE.NEVER()) then -10.0;
    case (DAE.AVOID()) then 0.0;
    case (DAE.DEFAULT()) then 10.0;
    case (DAE.PREFER()) then 50.0;
    case (DAE.ALWAYS()) then 100.0;
  end match;
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
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<tuple<DAE.ComponentRef, Integer, Integer>> outTplExpComponentRefIntegerIntegerLst;
algorithm
  outTplExpComponentRefIntegerIntegerLst:=
  matchcontinue (inExpComponentRefLst,inIntegerLst,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      BackendDAE.Value indx,prio;
      list<tuple<BackendDAE.Key, BackendDAE.Value, BackendDAE.Value>> res;
      list<BackendDAE.Key> crs;
      list<BackendDAE.Value> indxs;
      BackendDAE.BackendDAE dae;
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
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output DAE.ComponentRef outComponentRef1;
  output Integer outInteger2;
  output Integer outInteger3;
algorithm
  (outComponentRef1,outInteger2,outInteger3):=
  matchcontinue (inComponentRef,inInteger,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT)
    local
      DAE.ComponentRef cr;
      BackendDAE.Value indx;
      BackendDAE.BackendDAE dae;
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
              BackendDAE,
              IncidenceMatrix,
              IncidenceMatrixT)
  outputs: (DAE.ComponentRef list, /* name for each state */
              int list)  /* number for each state */"
  input list<Integer> inIntegerLst;
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (inIntegerLst,inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT)
    local
      list<BackendDAE.Key> res1,res11,res1_1;
      list<BackendDAE.Value> res2,vars2,res22,res2_1,rest;
      BackendDAE.Value e;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.BackendDAE daelow;
      String se;
      Integer e_1;
      DAE.ElementSource source;
      
    case ({},_,_,_) then ({},{});
    case ((e :: rest),daelow as BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns),m,mt)
      equation
        (res1,res2) = statesInEqns(rest, daelow, m, mt);
        vars2 = Util.listSelect(m[e], Util.intNegative);
        vars2 = Util.listMap(vars2,intAbs);
        (res11,res22) = statesInVars(vars, vars2);
        res1_1 = listAppend(res11, res1);
        res2_1 = listAppend(res22, res2);
      then
        (res1_1,res2_1);
    case ((e :: rest),BackendDAE.DAE(orderedEqs = eqns),_,_)
      equation
        se = intString(e);
        se = stringAppendList({"-BackendDAETransform.statesInEqns failed for eqn: ",se,"\n"});
        e_1 = e - 1;
        source = BackendEquation.equationSource(BackendDAEUtil.equationNth(eqns,e_1));
        Error.addSourceMessage(Error.INTERNAL_ERROR, {se}, DAEUtil.getElementSourceFileInfo(source));        
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
  input BackendDAE.Variables vars;
  input list<Integer> inIntegerLst;
  output list<DAE.ComponentRef> outExpComponentRefLst;
  output list<Integer> outIntegerLst;
algorithm
  (outExpComponentRefLst,outIntegerLst):=
  matchcontinue (vars,inIntegerLst)
    local
      BackendDAE.Value v;
      DAE.ComponentRef cr;
      list<BackendDAE.Key> res1;
      list<BackendDAE.Value> res2,rest;
    case (vars,{}) then ({},{});
    case (vars,(v :: rest))
      equation
        BackendDAE.VAR(varName = cr) = BackendVariable.getVarAt(vars,v);
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
  inputs:  (BackendDAE,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list) /* equations */
  outputs: (BackendDAE,
            IncidenceMatrix,
            IncidenceMatrixT,
            int, /* number of vars */
            int, /* number of eqns */
            int list /* differentiated equations */)"
  input BackendDAE.BackendDAE inBackendDAE1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input list<Integer> inIntegerLst6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output BackendDAE.BackendDAE outBackendDAE1;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix2;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT3;
  output list<Integer> outIntegerLst6;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
algorithm
  (outBackendDAE1,outIncidenceMatrix2,outIncidenceMatrixT3,outIntegerLst6,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inBackendDAE1,inIncidenceMatrix2,inIncidenceMatrixT3,inIntegerLst6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.BackendDAE dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value e_1,leneqns,e;
      BackendDAE.Equation eqn,eqn_1;
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
    case (dae,m,mt,{},_,inDerivedAlgs,inDerivedMultiEqn) then (dae,m,mt,{},inDerivedAlgs,inDerivedMultiEqn);
    case ((dae as BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,true) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        // str = BackendDump.equationStr(eqn);
        // print( "differentiated equation ") ;
        // print(str); print("\n");
        // print(" to ");
        // str = BackendDump.equationStr(eqn_1);
        // print(str);
        // print("\n");
        Debug.fcall("bltdump", debugdifferentiateEqns,(eqn,eqn_1));
        eqns_1 = BackendEquation.equationAdd(eqn_1,eqns);
        leneqns = BackendDAEUtil.equationSize(eqns_1);
        BackendDAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAE(v,kv,ev,av,eqns_1,seqns,ie,ae1,al1,wc,eoc), m, mt, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,(leneqns :: (e :: reqns)),derivedAlgs1,derivedMultiEqn1);
    case ((dae as BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,false) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        // str = BackendDump.equationStr(eqn);
        // print( "differentiated equation ") ;
        // print(str); print("\n");
        // print(" to ");
        // str = BackendDump.equationStr(eqn_1);
        // print(str);
        // print("\n");
        Debug.fcall("bltdump", debugdifferentiateEqns,(eqn,eqn_1));
        BackendDAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae1,al1,wc,eoc), m, mt, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,(e :: reqns),derivedAlgs1,derivedMultiEqn1);
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"-BackendDAETranfrom.differentiateEqns failed!"}); 
      then
        fail();
  end matchcontinue;
end differentiateEqns;

protected function debugdifferentiateEqns
  input tuple<BackendDAE.Equation,BackendDAE.Equation> inTpl;
protected
  BackendDAE.Equation a,b;
algorithm
  (a,b) := inTpl;
  print("High index problem, differentiated equation:\n" +& BackendDump.equationStr(a) +& "\nto\n" +& BackendDump.equationStr(b) +& "\n");
end debugdifferentiateEqns;

end BackendDAETransform;

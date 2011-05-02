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


protected import BackendDump;
protected import BackendDAEUtil;
protected import BackendEquation;
protected import BackendVariable;
protected import ComponentReference;
protected import BackendDAEEXT;
protected import DAEUtil;
protected import Debug;
protected import Expression;
protected import Derive;
protected import Error;
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
  input DAE.FunctionTree inFunctions;
  output array<Integer> outIntegerArray1;
  output array<Integer> outIntegerArray2;
  output BackendDAE.BackendDAE outBackendDAE3;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix4;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT5;
algorithm
  (outIntegerArray1,outIntegerArray2,outBackendDAE3,outIncidenceMatrix4,outIncidenceMatrixT5) :=
  matchcontinue (inBackendDAE,inIncidenceMatrix,inIncidenceMatrixT,inMatchingOptions,inFunctions)
    local
      BackendDAE.Value nvars,neqns,memsize;
      String ns,ne;
      BackendDAE.Assignments assign1,assign2,ass1,ass2;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      array<list<BackendDAE.Value>> m,mt,m_1,mt_1;
      array<BackendDAE.Value> vec1,vec2;
      BackendDAE.MatchingOptions match_opts;
    /* fail case if daelow is empty */
    case ((dae as BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns)),m,mt,match_opts,inFunctions)
      equation
        nvars = arrayLength(m);
        neqns = arrayLength(mt);
        (nvars == 0) = true;
        (neqns == 0) = true;
        vec1 = listArray({});
        vec2 = listArray({});
      then
        (vec1,vec2,dae,m,mt);
    case ((dae as BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,BackendDAE.REMOVE_SIMPLE_EQN())),inFunctions)
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
        (ass1,ass2,dae,m_1,mt_1,_,_) = matchingAlgorithm2(dae, m, mt, nvars, neqns, 1, assign1, assign2, match_opts,inFunctions,{},{});
        vec1 = assignmentsVector(ass1);
        vec2 = assignmentsVector(ass2);
      then
        (vec1,vec2,dae,m_1,mt_1);

    case ((dae as BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns)),m,mt,(match_opts as (_,_,BackendDAE.KEEP_SIMPLE_EQN())),inFunctions)
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
    case (_,(_,BackendDAE.ALLOW_UNDERCONSTRAINED(),_)) then ();
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
    case (_,_)
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
        print("- BackendDAE.assignmentsVector failed\n");
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
        print("BackendDAE.assignmentsExpand: n should not be negative!");
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
algorithm
  (outAssignments1,outAssignments2,outBackendDAE3,outIncidenceMatrix4,outIncidenceMatrixT5,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inBackendDAE1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inInteger6,inAssignments7,inAssignments8,inMatchingOptions9,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.Assignments ass1_1,ass2_1,ass1,ass2,ass1_2,ass2_2;
      BackendDAE.BackendDAE dae;
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
        BackendDAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false; eMark(i)=vMark(i)=false exit loop";
      then
        (ass1_1,ass2_1,dae,m,mt,derivedAlgs,derivedMultiEqn);

    case (dae,m,mt,nv,nf,i,ass1,ass2,match_opts,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        i_1 = i + 1;
        BackendDAEEXT.initMarks(nv, nf);
        (ass1_1,ass2_1) = pathFound(m, mt, i, ass1, ass2) "eMark(i)=vMark(i)=false" ;
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1) = matchingAlgorithm2(dae, m, mt, nv, nf, i_1, ass1_1, ass2_1, match_opts, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,i,ass1,ass2,(BackendDAE.INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1) = reduceIndexDummyDer(dae, m, mt, nv, nf, inFunctions,derivedAlgs,derivedMultiEqn) 
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
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2) = matchingAlgorithm2(dae, m, mt, nv_1, nf_1, i, ass1_1, ass2_1, (BackendDAE.INDEX_REDUCTION(),eq_cons,r_simple),inFunctions,derivedAlgs1,derivedMultiEqn1);
      then
        (ass1_2,ass2_2,dae,m,mt,derivedAlgs2,derivedMultiEqn2);

    case (dae,m,mt,nv,nf,i,ass1,ass2,_,_,_,_)
      equation
        eqn_lst = BackendDAEEXT.getMarkedEqns() "When index reduction also fails, the model is structurally singular." ;
        var_lst = BackendDAEEXT.getMarkedVariables();
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
        BackendDAEEXT.initLowLink(n);
        BackendDAEEXT.initNumber(n);
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
        0 = BackendDAEEXT.getNumber(w);
        (i,stack,comps_1) = strongConnect(m, mt, a1, a2, i, w, stack, comps);
        lv = BackendDAEEXT.getLowLink(v);
        lw = BackendDAEEXT.getLowLink(w);
        minv = intMin(lv, lw);
        BackendDAEEXT.setLowLink(v, minv);
        (i,stack,comps_2) = iterateReachableNodes(ws, m, mt, a1, a2, i, v, stack, comps_1);
      then
        (i,stack,comps_2);
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
 reduceIndexDummyDer and stuff
 *****************************************/

protected function reduceIndexDummyDer
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
  input BackendDAE.BackendDAE inBackendDAE1;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix2;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT3;
  input Integer inInteger4;
  input Integer inInteger5;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output BackendDAE.BackendDAE outBackendDAE;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
algorithm
  (outBackendDAE,outIncidenceMatrix,outIncidenceMatrixT,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inBackendDAE1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
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

    case (dae,m,mt,nv,nf,inFunctions,derivedAlgs,derivedMultiEqn)
      equation
        eqns = BackendDAEEXT.getMarkedEqns();
        // print("marked equations:");print(Util.stringDelimitList(Util.listMap(eqns,intString),","));
        // print("\n");
        diff_eqns = BackendDAEEXT.getDifferentiatedEqns();
        eqns_1 = Util.listSetDifferenceOnTrue(eqns, diff_eqns, intEq);
        // print("differentiating equations:");print(Util.stringDelimitList(Util.listMap(eqns_1,intString),","));
        // print("\n");
        // print(BackendDump.dumpMarkedEqns(dae, eqns_1));

        // Collect the states in the equations that are singular, i.e. composing a constraint between states.
        // Note that states are collected from -all- marked equations, not only the differentiated ones.
        (states,stateindx) = statesInEqns(eqns, dae, m, mt);
        (dae,m,mt,nv,nf,deqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(dae, m, mt, nv, nf, eqns_1,inFunctions,derivedAlgs,derivedMultiEqn);
        (state,stateno) = selectDummyState(states, stateindx, dae, m, mt);
        // print("Selected ");print(ComponentReference.printComponentRefStr(state));print(" as dummy state\n");
        // print(" From candidates:");print(Util.stringDelimitList(Util.listMap(states,ComponentReference.printComponentRefStr),", "));print("\n");
        // dae = propagateDummyFixedAttribute(dae, eqns_1, state, stateno);
        (dummy_der,dae) = newDummyVar(state, dae, DAE.NEW_DUMMY_DER(state,states));
        // print("Chosen dummy: ");print(ComponentReference.printComponentRefStr(dummy_der));print("\n");
        reqns = BackendDAEUtil.eqnsForVarWithStates(mt, stateno);
        changedeqns = Util.listUnionOnTrue(deqns, reqns, intEq);
        stateexp = Expression.crefExp(state);
        tp = Expression.typeof(stateexp);
        stateexpcall = DAE.CALL(Absyn.IDENT("der"),{stateexp},false,true,tp,DAE.NO_INLINE());
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
        (dae,m,mt,derivedAlgs1,derivedMultiEqn1);

    case (dae,m,mt,nv,nf,_,_,_)
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

    case (_,_,_,_,_,_,_,_)
      equation
        print("-reduce_index_dummy_der failed\n");
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
        print("BackendDAE.makeAlgebraic failed\n");
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
      list<BackendDAE.Value> eqns_1,eqns;
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
        eqns_1 = Util.listMap1(eqns, intSub, 1);
        eqns_lst = Util.listMap1r(eqns_1, BackendDAEUtil.equationNth, e);
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
        eqns_1 = Util.listMap1(eqns, intSub, 1);
        eqns_lst = Util.listMap1r(eqns_1, BackendDAEUtil.equationNth, e);
        crefs = BackendEquation.equationsCrefs(eqns_lst);
        (crefs, _) = Util.listDeleteMemberOnTrue(dummy, crefs, ComponentReference.crefEqualNoStringCompare);
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
        ((_, _, av)) = BackendVariable.traverseBackendDAEVars(aliasVars,traverereplaceAliasVarsBindExp,(stateexpcall, dummyderexp, av));
        (ie1,(al1,ae1,wclst1,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(ie,traversereplaceDummyDer,(al, ae, wclst, replaceDummyDer2Exp,(stateexpcall,dummyderexp)));
        (ie1,(al1,ae1,wclst1,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(ie,traversereplaceDummyDer,(al, ae, wclst, replaceDummyDer2Exp,(stateexpcall,dummyderexp)));
        (seqns1,(al2,ae2,wclst2,_,_)) = BackendEquation.traverseBackendDAEEqnsWithUpdate(seqns,traversereplaceDummyDer,(al1, ae1, wclst1, replaceDummyDer2Exp,(stateexpcall,dummyderexp)));
       then (BackendDAE.DAE(v,kv,ev,av,eqns,seqns1,ie1,ae2,al2,BackendDAE.EVENT_INFO(wclst2,zeroCrossingLst),eoc),m,mt);

    case (stateexpcall,dummyderexp,BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae,al,BackendDAE.EVENT_INFO(wclst,zeroCrossingLst),eoc),m,mt,(e :: rest))
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);
        (eqn_1,al1,ae1,wclst1,_) = traverseBackendDAEExpsEqn(eqn, al, ae, wclst, replaceDummyDer2Exp,(stateexpcall,dummyderexp));
        (eqn_1,al2,ae2,wclst2,v_1) = traverseBackendDAEExpsEqn(eqn_1,al1,ae1,wclst1,replaceDummyDerOthersExp,v);
        eqns_1 = BackendEquation.equationSetnth(eqns, e_1, eqn_1)
         "incidence_row(v\'\',eqn\') => row\' &
          Util.list_replaceat(row\',e\',m) => m\' &
          transpose_matrix(m\') => mt\' &" ;
        (dae,m,mt) = replaceDummyDer(stateexpcall, dummyderexp, BackendDAE.DAE(v_1,kv,ev,av,eqns_1,seqns,ie,ae2,al2,BackendDAE.EVENT_INFO(wclst2,zeroCrossingLst),eoc), m, mt, rest);
      then
        (dae,m,mt);

    case (_,_,_,_,_,_)
      equation
        print("-replace_dummy_der failed\n");
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
      Type_a ext_arg_1,ext_arg_2,ext_arg_3;
    case (BackendDAE.EQUATION(exp = e1,scalar = e2,source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        ((e1_1,ext_arg_1)) = func((e1,inTypeA));
        ((e2_1,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.EQUATION(e1_1,e2_1,source),inAlgs,ae,wclst,ext_arg_2);
    case (BackendDAE.ARRAY_EQUATION(index = ds,crefOrDerCref = expl,source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        (expl1,ext_arg_1) = BackendEquation.traverseBackendDAEExpList(expl,func,inTypeA);
        i = ds+1;
        BackendDAE.MULTIDIM_EQUATION(dimSize=dimSize,left=e1,right = e2,source=source1) = ae[i];
        ((e1_1,ext_arg_2)) = func((e1,ext_arg_1));
        ((e2_1,ext_arg_3)) = func((e2,ext_arg_2));
        ae1 = arrayUpdate(ae,i,BackendDAE.MULTIDIM_EQUATION(dimSize,e1_1,e2_1,source1));
      then (BackendDAE.ARRAY_EQUATION(ds,expl1,source),inAlgs,ae1,wclst,ext_arg_3);  /* array equation */
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr,exp = e2,source=source),inAlgs,ae,wclst,func,inTypeA)
      equation
        e1 = Expression.crefExp(cr);
        ((DAE.CREF(cr1,_),ext_arg_1)) = func((e1,inTypeA));
        ((e2_1,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.SOLVED_EQUATION(cr1,e2_1,source),inAlgs,ae,wclst,ext_arg_1);
    case (BackendDAE.RESIDUAL_EQUATION(exp = e1,source=source),inAlgs,ae,wclst,func,inTypeA)
      equation
        ((e1_1,ext_arg_1)) = func((e1,inTypeA));
      then
        (BackendDAE.RESIDUAL_EQUATION(e1_1,source),inAlgs,ae,wclst,ext_arg_1);
    case (BackendDAE.ALGORITHM(index = indx,in_ = in_,out = out,source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        (in_1,ext_arg_1) = BackendEquation.traverseBackendDAEExpList(in_,func,inTypeA);
        (out1,ext_arg_2) = BackendEquation.traverseBackendDAEExpList(out,func,ext_arg_1);
        (algs,ext_arg_3) = traverseBackendDAEExpsEqnAlgs(indx,inAlgs,func,ext_arg_2);
      then (BackendDAE.ALGORITHM(indx,in_1,out1,source),algs,ae,wclst,ext_arg_3);  /* Algorithms */
    case (BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=NONE()),source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        e2 = Expression.crefExp(cr);
        ((e1_1,ext_arg_1)) = func((e1,inTypeA));
        ((DAE.CREF(cr1,_),ext_arg_2)) = func((e2,ext_arg_1));
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr1,e1_1,NONE()),source);
        (wclst1,ext_arg_3) = traverseBackendDAEExpsWhenClause(SOME(i),wclst,func,ext_arg_2);
      then
        (res,inAlgs,ae,wclst1,ext_arg_3);

    case (BackendDAE.WHEN_EQUATION(whenEquation =
          BackendDAE.WHEN_EQ(index = i,left = cr,right = e1,elsewhenPart=SOME(elsepart)),source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        ((e1_1,ext_arg_1)) = func((e1,inTypeA));
        (BackendDAE.WHEN_EQUATION(elsepartRes,source),algs,ae1,wclst1,ext_arg_2) = traverseBackendDAEExpsEqn(BackendDAE.WHEN_EQUATION(elsepart,source),inAlgs,ae,wclst,func,ext_arg_1);
        res = BackendDAE.WHEN_EQUATION(BackendDAE.WHEN_EQ(i,cr,e1_1,SOME(elsepartRes)),source);
        (wclst2,ext_arg_3) = traverseBackendDAEExpsWhenClause(SOME(i),wclst1,func,ext_arg_2);
      then
        (res,algs,ae1,wclst2,ext_arg_3);
    case (BackendDAE.COMPLEX_EQUATION(index=i,lhs = e1,rhs = e2,source = source),inAlgs,ae,wclst,func,inTypeA)
      equation
        ((e1_1,ext_arg_1)) = func((e1,inTypeA));
        ((e2_1,ext_arg_2)) = func((e2,ext_arg_1));
      then
        (BackendDAE.COMPLEX_EQUATION(i,e1_1,e2_1,source),inAlgs,ae,wclst,ext_arg_2);
     case (_,_,_,_,_,_)
      equation
        print("-BackendDAETransform.traverseBackendDAEExpsEqn failed\n");
      then
        fail();
  end matchcontinue;
end traverseBackendDAEExpsEqn;

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
        print("-BackendDAETransform.traverseBackendDAEExpsWhenClause failed\n");
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
        print("-BackendDAETransform.traverseBackendDAEExpsWhenOperator failed\n");
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
        print("-BackendDAETransform.traverseBackendDAEExpsWhenClauseLst failed\n");
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
  input tuple<DAE.Exp,BackendDAE.Variables> inTpl;
  output tuple<DAE.Exp,BackendDAE.Variables> outTpl;
protected
  DAE.Exp e;
  BackendDAE.Variables vars;
algorithm
  (e,vars) := inTpl;
  outTpl := Expression.traverseExp(e,replaceDummyDerOthersExpFinder,vars);
end replaceDummyDerOthersExp;

protected function traverereplaceAliasVarsBindExp
"function traverereplaceAliasVarsBindExp
  Helper funciton to replaceDummyDer.
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
end traverereplaceAliasVarsBindExp;

protected function replaceDummyDerOthersExpFinder
"function: replaceDummyDerOthersExpFinder
  author: PA
  Helper function for replaceDummyDerOthersExp"
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
      DAE.ComponentRef dummyder,cr;
      DAE.ElementSource source "the source of the element";
      Option<DAE.VariableAttributes> dae_var_attr;
      Option<SCode.Comment> comment;
      DAE.Flow flowPrefix;
      DAE.Stream streamPrefix;
      list<DAE.Subscript> lstSubs;

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)})}),vars))
      equation
        ((BackendDAE.VAR(_,BackendDAE.STATE(),a,b,c,d,lstSubs,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(der(s)) s is state => der_der_s" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        dummyder = ComponentReference.crefPrefixDer(dummyder);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b, NONE(), NONE(), lstSubs, 0, source, NONE(), comment, flowPrefix, streamPrefix), vars);
        e = Expression.makeCrefExp(dummyder,DAE.ET_REAL());
      then
        ((e, vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      equation
        ((BackendDAE.VAR(_,BackendDAE.DUMMY_DER(),a,b,c,d,lstSubs,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(der_s)) der_s is dummy var => der_der_s" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b, NONE(), NONE(), lstSubs, 0, source, NONE(), comment, flowPrefix, streamPrefix), vars);
        e = Expression.makeCrefExp(dummyder,DAE.ET_REAL());
      then
        ((e, vars_1));

    case ((DAE.CALL(path = Absyn.IDENT(name = "der"),expLst = {DAE.CREF(componentRef = cr)}),vars))
      equation
        ((BackendDAE.VAR(_,BackendDAE.VARIABLE(),a,b,c,d,lstSubs,g,source,dae_var_attr,comment,flowPrefix,streamPrefix) :: _),_) = BackendVariable.getVar(cr, vars) "der(v) v is alg var => der_v" ;
        dummyder = ComponentReference.crefPrefixDer(cr);
        vars_1 = BackendVariable.addVar(BackendDAE.VAR(dummyder, BackendDAE.DUMMY_DER(), a, b, NONE(), NONE(), lstSubs, 0, source, NONE(), comment, flowPrefix, streamPrefix), vars);
        e = Expression.makeCrefExp(dummyder,DAE.ET_REAL());
      then
        ((e, vars_1));

    case ((e,vars)) then ((e,vars));

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
      BackendDAE.Variables vars;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      BackendDAE.EquationArray eqns;
      list<tuple<DAE.ComponentRef,Integer,Real>> prioTuples;
      BackendDAE.BackendDAE dae;

    case (varCrefs,varIndices,BackendDAE.DAE(orderedVars=vars,orderedEqs = eqns),m,mt)
      equation
        prioTuples = calculateVarPriorities(varCrefs,varIndices,vars,eqns,m,mt);
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
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output list<tuple<DAE.ComponentRef,Integer,Real>> tuples;
algorithm
  tuples := match(varCrefs,varIndices,vars,eqns,m,mt)
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
  input BackendDAE.Variables vars;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  output Real prio;
protected
  list<Integer> vEqns;
  DAE.ComponentRef vCr;
  Integer vindx;
  Real prio1,prio2,prio3,prio4,prio5;
algorithm
  (_,vindx::_) := BackendVariable.getVar(BackendVariable.varCref(v),vars); // Variable index not stored in var itself => lookup required
  vEqns := BackendDAEUtil.eqnsForVarWithStates(mt,vindx);
  vCr := BackendVariable.varCref(v);
  prio1 := varStateSelectHeuristicPrio1(vCr,vEqns,vars,eqns);
  Debug.fcall("dummyselect",print," Prio 1 : " +& realString(prio1) +& "\n");
  prio2 := varStateSelectHeuristicPrio2(vCr,vars);
  Debug.fcall("dummyselect",print," Prio 2 : " +& realString(prio2) +& "\n");
  prio3 := varStateSelectHeuristicPrio3(vCr,vars);
  Debug.fcall("dummyselect",print," Prio 3 : " +& realString(prio3) +& "\n");
 // prio4 := varStateSelectHeuristicPrio4(v);
  //Debug.fcall("dummyselect",print," Prio 4 : " +& realString(prio4) +& "\n");
  prio5 := varStateSelectHeuristicPrio5(v);
  Debug.fcall("dummyselect",print," Prio 5 : " +& realString(prio5) +& "\n");
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
    case ((e :: rest),_,_,_)
      equation
        se = intString(e);
        print("-BackendDAETransform.statesInEqns failed for eqn: ");
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
      DAE.Flow flowPrefix;
      list<BackendDAE.Key> res1;
      list<BackendDAE.Value> res2,rest;
    case (vars,{}) then ({},{});
    case (vars,(v :: rest))
      equation
        BackendDAE.VAR(varName = cr, flowPrefix = flowPrefix) = BackendVariable.getVarAt(vars,v);
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
  input Integer inInteger4;
  input Integer inInteger5;
  input list<Integer> inIntegerLst6;
  input DAE.FunctionTree inFunctions;
  input list<tuple<Integer,Integer,Integer>> inDerivedAlgs;
  input list<tuple<Integer,Integer,Integer>> inDerivedMultiEqn;
  output BackendDAE.BackendDAE outBackendDAE1;
  output BackendDAE.IncidenceMatrix outIncidenceMatrix2;
  output BackendDAE.IncidenceMatrixT outIncidenceMatrixT3;
  output Integer outInteger4;
  output Integer outInteger5;
  output list<Integer> outIntegerLst6;
  output list<tuple<Integer,Integer,Integer>> outDerivedAlgs;
  output list<tuple<Integer,Integer,Integer>> outDerivedMultiEqn;
algorithm
  (outBackendDAE1,outIncidenceMatrix2,outIncidenceMatrixT3,outInteger4,outInteger5,outIntegerLst6,outDerivedAlgs,outDerivedMultiEqn):=
  matchcontinue (inBackendDAE1,inIncidenceMatrix2,inIncidenceMatrixT3,inInteger4,inInteger5,inIntegerLst6,inFunctions,inDerivedAlgs,inDerivedMultiEqn)
    local
      BackendDAE.BackendDAE dae;
      array<list<BackendDAE.Value>> m,mt;
      BackendDAE.Value nv,nf,e_1,leneqns,e;
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
    case (dae,m,mt,nv,nf,{},_,inDerivedAlgs,inDerivedMultiEqn) then (dae,m,mt,nv,nf,{},inDerivedAlgs,inDerivedMultiEqn);
    case ((dae as BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,true) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        // str = BackendDump.equationStr(eqn);
        // print( "differentiated equation ") ;
        Debug.fprint("bltdump", BackendDump.equationStr(eqn));
        // print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        // print(" to ");
        // str = BackendDump.equationStr(eqn_1);
        // print(str);
        // print("\n");
        Debug.fprint("bltdump", BackendDump.equationStr(eqn_1)) "  print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        eqns_1 = BackendEquation.equationAdd(eqn_1,eqns);
        leneqns = BackendDAEUtil.equationSize(eqns_1);
        BackendDAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAE(v,kv,ev,av,eqns_1,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(leneqns :: (e :: reqns)),derivedAlgs1,derivedMultiEqn1);
    case ((dae as BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae,al,wc,eoc)),m,mt,nv,nf,(e :: es),inFunctions,inDerivedAlgs,inDerivedMultiEqn)
      equation
        e_1 = e - 1;
        eqn = BackendDAEUtil.equationNth(eqns, e_1);

        (eqn_1,al1,derivedAlgs,ae1,derivedMultiEqn,false) = Derive.differentiateEquationTime(eqn, v, inFunctions, al,inDerivedAlgs,ae,inDerivedMultiEqn);
        Debug.fprint("bltdump", "High index problem, differentiated equation: ") "update equation row in IncidenceMatrix" ;
        // str = BackendDump.equationStr(eqn);
        // print( "differentiated equation ") ;
        Debug.fprint("bltdump", BackendDump.equationStr(eqn));
        // print(str); print("\n");
        Debug.fprint("bltdump", " to ");
        // print(" to ");
        // str = BackendDump.equationStr(eqn_1);
        // print(str);
        // print("\n");
        Debug.fprint("bltdump", BackendDump.equationStr(eqn_1)) "  print \" to \" & print str &  print \"\\n\" &" ;
        Debug.fprint("bltdump", "\n");
        leneqns = BackendDAEUtil.equationSize(eqns);
        BackendDAEEXT.markDifferentiated(e) "length gives index of new equation Mark equation as differentiated so it won\'t be differentiated again" ;
        (dae,m,mt,nv,nf,reqns,derivedAlgs1,derivedMultiEqn1) = differentiateEqns(BackendDAE.DAE(v,kv,ev,av,eqns,seqns,ie,ae1,al1,wc,eoc), m, mt, nv, nf, es, inFunctions,derivedAlgs,derivedMultiEqn);
      then
        (dae,m,mt,nv,nf,(e :: reqns),derivedAlgs1,derivedMultiEqn1);
    case (_,_,_,_,_,_,_,_,_)
      equation
        print("-differentiate_eqns failed\n");
      then
        fail();
  end matchcontinue;
end differentiateEqns;

public function dummyDerivative
  input BackendDAE.BackendDAE inDAE;
  input DAE.FunctionTree inFunctionTree;
  output BackendDAE.BackendDAE outDAE;
algorithm
  outDAE := inDAE;
end dummyDerivative;

end BackendDAETransform;

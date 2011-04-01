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

encapsulated package BackendQSS
" file:         BackendQSS.mo
  package:     BackendQSS
  description: BackendQSS contains the datatypes used by the backend for QSS solver.
  authors: xfloros, fbergero
"

public import BackendDAE;
public import BackendDAEUtil;
public import DAE;
public import BackendDump;

protected import BackendVariable;
protected import Debug;
protected import Util;
protected import ComponentReference;


public
uniontype QSSinfo "- equation indices in static blocks and DEVS structure"
  record QSSINFO
    list<list<list<Integer>>> BLTblocks "BLT blocks in static functions";  
    array<list<list<Integer>>> outVars "output variables for each DEVS block";  
    array<list<list<Integer>>> inVars "input variables for each DEVS block";   
  end QSSINFO;
end QSSinfo;

public function generateStructureCodeQSS 
  input BackendDAE.BackendDAE inBackendDAE;
  input array<Integer> equationIndices;
  input array<Integer> variableIndices;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input list<list<Integer>> strongComponents;
  
  output QSSinfo QSSinfo_out;
algorithm
  QSSinfo_out :=
  matchcontinue (inBackendDAE, equationIndices, variableIndices, inIncidenceMatrix, inIncidenceMatrixT, strongComponents)
    local
       BackendDAE.BackendDAE dlow;
       list<list<Integer>> comps;
       array<Integer> ass1, ass2;
       BackendDAE.IncidenceMatrix m, mt;
       
       list<list<Integer>> blt_states,blt_no_states, stateEq_flat;
       list<list<list<Integer>>> stateEq_blt;
       
       array<list<list<Integer>>> outVars_temp, inVars_temp;      
       
       Integer nStatic;
                  
    case (dlow, ass1, ass2, m, mt, comps)
      equation
        
        (blt_states, blt_no_states) = BackendDAEUtil.generateStatePartition(comps, dlow, ass1, ass2, m, mt);
        
        
        
        
        // STEP 1      
        // EXTRACT THE INDICES OF NEEDED EQUATIONS FOR EACH STATE VARIABLE         
                
        stateEq_flat = splitStateEqSet(comps, dlow, ass1, ass2, m, mt) "Extract equations for each state derivative"; 
        stateEq_blt = mapStateEqInBlocks( stateEq_flat, blt_states, {}) "Map equations back in BLT blocks";
        
        nStatic = listLength(stateEq_blt);     
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
                
        // PRINT INFO
                
        Debug.fcall("QSS-stuff",print,"---------- State Blocks ----------\n");
        //Util.listMap0(stateEq_blt, printListOfLists);
        //Debug.fcall("QSS-stuff",Util.listMap02, (stateEq_blt, BackendDump.dumpComponentsAdvanced, ass2, dlow));        
        Debug.fcall("QSS-stuff",print,"---------- State Blocks ----------\n");    
        
       
        outVars_temp = listArray({{{1,2,3},{4,5},{6}}});
        inVars_temp = listArray({{{1,2,3},{4,5},{6}}});
                
        
        //dumpMyDEVSstructs(outVars_temp, " CALCULATED DEVS structure IN LINKS \n");
        
      then
        QSSINFO(stateEq_blt, outVars_temp, inVars_temp);
  
  end matchcontinue;

end generateStructureCodeQSS;


public function splitStateEqSet
"function: splitStateEqSet
  author: florosx
  Finds for each state derivative the equations that are needed in order to compute it.
  It is based on the traversal done in BackendDAEUtil.generateStatePartition().
"
  input list<list<Integer>> inIntegerLstLst1;
  input BackendDAE.BackendDAE inBackendDAE;
  input array<BackendDAE.Value> inIntegerArray1;
  input array<BackendDAE.Value> inIntegerArray2;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<list<Integer>> sortedEquationsIndices;
 
algorithm
  (sortedEquationsIndices):=
  matchcontinue (inIntegerLstLst1,inBackendDAE,inIntegerArray1,inIntegerArray2,inIncidenceMatrix,inIncidenceMatrixT)
    local
      BackendDAE.BackendDAE dae;
      BackendDAE.Value size;
      BackendDAE.Variables v;
      array<BackendDAE.Value> arr;
      array<list<Integer>> arr_1;
      list<list<BackendDAE.Value>> blt_states,blt_no_states;
      array<BackendDAE.Value> ass1,ass2;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      list<list<Integer>> arrList, comps;      
      
    case (comps,(dae as BackendDAE.DAE(orderedVars = v)),ass1,ass2,m,mt)
      equation
        size = arrayLength(ass1) "equation_size(e) => size &" ;
        arr = arrayCreate(size, 0);
        arr_1 = fill({}, size);
        arr_1 = markStateEquations(dae, arr, arr_1, m, mt, ass1, ass2);
        arrList = arrayList(arr_1); 
        arrList = sortEquationsBLT(arrList,comps,{});        
        //The arrList includes also empty elements for the non-states - remove them
        arrList = removeEmptyElements(arrList,{});       
      then
        (arrList);
    case (_,_,_,_,_,_)
      equation
        print("- BackendDAEUtil.generateStatePartition failed\n");
      then
        fail();
  end matchcontinue;
end splitStateEqSet;


////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - SELECTING EQUATIONS FOR EACH STATE VARIABLE (slight modifications from BackendDAEUtil
////////////////////////////////////////////////////////////////////////////////////////////////////

public function markStateEquations "function: markStateEquations
  This function goes through all equations and marks the ones that
  calculates a state, or is needed in order to calculate a state,
  with a non-zero value in the array passed as argument.
  This is done by traversing the directed graph of nodes where
  a node is an equation/solved variable and following the edges in the
  backward direction.
  inputs: (daeLow: BackendDAE,
             marks: int array,
    incidenceMatrix: IncidenceMatrix,
    incidenceMatrixT: IncidenceMatrixT,
    assignments1: int vector,
    assignments2: int vector)
  outputs: marks: int array"
  input BackendDAE.BackendDAE inBackendDAE1;
  input array<Integer> inIntegerArray2;
  input array<list<Integer>> inEqNumArray3;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix3;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT4;
  input array<Integer> inIntegerArray5;
  input array<Integer> inIntegerArray6;
  output array<list<Integer>> outIntegerArray; //modification
algorithm
  outIntegerArray:=
  matchcontinue (inBackendDAE1,inIntegerArray2,inEqNumArray3,inIncidenceMatrix3,inIncidenceMatrixT4,inIntegerArray5,inIntegerArray6)
    local
      list<BackendDAE.Var> statevar_lst;
      BackendDAE.BackendDAE dae;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> alg;
      array<list<Integer>> arr_2;
    
    case ((dae as BackendDAE.DAE(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = alg)),arr_1,arr_2,m,mt,a1,a2)
      equation
        statevar_lst = BackendVariable.getAllStateVarFromVariables(v);
        ((dae,arr_1,arr_2,m,mt,a1,a2)) = Util.listFold(statevar_lst, markStateEquation, (dae,arr_1,arr_2,m,mt,a1,a2));
      then
        arr_2;
    case (_,_,_,_,_,_,_)
      equation
        print("- BackendQSS.markStateEquations failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquations;
     
protected function markStateEquation
"function: markStateEquation
  This function is a helper function to mark_state_equations
  It performs marking for one equation and its transitive closure by
  following edges in backward direction.
  inputs and outputs are tuples so we can use Util.list_fold"
  input BackendDAE.Var inVar;
  input tuple<BackendDAE.BackendDAE, array<Integer>, array<list<Integer>>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> inTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<BackendDAE.BackendDAE, array<Integer>, array<list<Integer>>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>> outTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inVar,inTplBackendDAEIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      list<BackendDAE.Value> v_indxs,v_indxs_1,eqns;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      DAE.ComponentRef cr;
      BackendDAE.BackendDAE dae;
      BackendDAE.Variables vars;
      String s,str;
      BackendDAE.Value v_indx,v_indx_1;
      array<list<Integer>> arr_2;
      Integer firstInd;
      
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr_1,arr_2,m,mt,a1,a2))
      equation
        (_,v_indxs) = BackendVariable.getVar(cr, vars);
        firstInd = Util.listFirst(v_indxs); //modification
        v_indxs_1 = Util.listMap1(v_indxs, intSub, 1);
        eqns = Util.listMap1r(v_indxs_1, arrayNth, a1);
        ((arr_1,arr_2,m,mt,a1,a2,_)) = markStateEquation2(eqns, (arr_1,arr_2,m,mt,a1,a2,firstInd));
      then
        ((dae,arr_1,arr_2,m,mt,a1,a2));
    
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr,_,m,mt,a1,a2))
      equation
        failure((_,_) = BackendVariable.getVar(cr, vars));
        print("- BackendQSS.markStateEquation var ");
        s = ComponentReference.printComponentRefStr(cr);
        print(s);
        print("not found\n");
      then
        fail();
    
    case (BackendDAE.VAR(varName = cr),((dae as BackendDAE.DAE(orderedVars = vars)),arr,_,m,mt,a1,a2))
      equation
        (_,{v_indx}) = BackendVariable.getVar(cr, vars);
        v_indx_1 = v_indx - 1;
        failure(_ = a1[v_indx_1 + 1]);
        print("-  BackendQSS.markStateEquation index = ");
        str = intString(v_indx);
        print(str);
        print(", failed\n");
      then
        fail();
  end matchcontinue;
end markStateEquation;

protected function markStateEquation2
"function: markStateEquation2
  Helper function to mark_state_equation
  Does the job by looking at variable indexes and incidencematrices.
  inputs: (eqns: int list,
             marks: (int array  BackendDAE.IncidenceMatrix  BackendDAE.IncidenceMatrixT  int vector  int vector))
  outputs: ((marks: int array  BackendDAE.IncidenceMatrix  IncidenceMatrixT
        int vector  int vector))"
  input list<Integer> inIntegerLst;
  input tuple<array<Integer>, array<list<Integer>>,BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>, Integer> inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
  output tuple<array<Integer>, array<list<Integer>>, BackendDAE.IncidenceMatrix, BackendDAE.IncidenceMatrixT, array<Integer>, array<Integer>, Integer> outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray;
algorithm
  outTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray:=
  matchcontinue (inIntegerLst,inTplIntegerArrayIncidenceMatrixIncidenceMatrixTIntegerArrayIntegerArray)
    local
      array<BackendDAE.Value> marks,marks_1,marks_2,marks_3;
      array<list<BackendDAE.Value>> m,mt,m_1,mt_1;
      array<BackendDAE.Value> a1,a2,a1_1,a2_1;
      BackendDAE.Value eqn_1,eqn,mark_value,len;
      list<BackendDAE.Value> inv_reachable,inv_reachable_1,eqns;
      list<list<BackendDAE.Value>> inv_reachable_2;
      String eqnstr,lens,ms;
      array<list<Integer>> marksEq;
      
      list<Integer> lst;
      array<list<Integer>> marksEq_1,marksEq_2,marksEq_3;
      Integer stateVarIndex;
        
    case ({},(marks,marksEq,m,mt,a1,a2,stateVarIndex)) then ((marks,marksEq,m,mt,a1,a2,stateVarIndex));
    
    case ((eqn :: eqns),(marks,marksEq,m,mt,a1,a2,stateVarIndex))
      equation
        eqn_1 = eqn - 1 "Mark an unmarked node/equation" ;
        0 = marks[eqn_1 + 1];
        marks_1 = arrayUpdate(marks, eqn_1 + 1, 1);
        
        lst = marksEq[stateVarIndex];
        lst = listAppend(lst,{eqn});
        marksEq_1 = arrayUpdate(marksEq,stateVarIndex,lst);
        
        inv_reachable = BackendDAEUtil.invReachableNodes(eqn, m, mt, a1, a2);
        inv_reachable_1 = BackendDAEUtil.removeNegative(inv_reachable);
        inv_reachable_2 = Util.listMap(inv_reachable_1, Util.listCreate);
        ((marks_2,marksEq_2,m,mt,a1,a2,stateVarIndex)) = Util.listFold(inv_reachable_2, markStateEquation2, (marks_1,marksEq_1,m,mt,a1,a2,stateVarIndex));
        ((marks_3,marksEq_3,m_1,mt_1,a1_1,a2_1,stateVarIndex)) = markStateEquation2(eqns, (marks_2,marksEq_2,m,mt,a1,a2,stateVarIndex));
      then
        ((marks_3,marksEq_3,m_1,mt_1,a1_1,a2_1,stateVarIndex));
    
    case ((eqn :: eqns),(marks,marksEq,m,mt,a1,a2,stateVarIndex))
      equation
        eqn_1 = eqn - 1 "Node already marked." ;
        mark_value = marks[eqn_1 + 1];
        (mark_value <> 0) = true;
        ((marks_1,marksEq_1,m_1,mt_1,a1_1,a2_1,stateVarIndex)) = markStateEquation2(eqns, (marks,marksEq,m,mt,a1,a2,stateVarIndex));
      then
        ((marks_1,marksEq_1,m_1,mt_1,a1_1,a2_1,stateVarIndex));
    
    case ((eqn :: _),(marks,marksEq,m,mt,a1,a2,stateVarIndex))
      equation
        print("- BackendQSS.markStateEquation2 failed, eqn: ");
        eqnstr = intString(eqn);
        print(eqnstr);
        print("array length = ");
        len = arrayLength(marks);
        lens = intString(len);
        print(lens);
        print("\n");
        eqn_1 = eqn - 1;
        mark_value = marks[eqn_1 + 1];
        ms = intString(mark_value);
        print("mark_value: ");
        print(ms);
        print("\n");
      then
        fail();
  end matchcontinue;
end markStateEquation2;

function sortEquationsBLT 
"function: sortEquationsBLT
  author: florosx
  Sorts equations according to their order in the BLT blocks
"
  input list<list<Integer>> inList;
  input list<list<Integer>> inComps;
  input list<list<Integer>> inListAcc;  
  output list<list<Integer>> outList; 
algorithm
  (outList) :=
  matchcontinue (inList,inComps,inListAcc)
    local
      Integer[:] ass1,ass2;
      list<list<Integer>> localAccList;
      list<list<Integer>> restList;
      list<list<Integer>> comps;  
      list<Integer> comps2,elem,firstList;
    case ({},_,localAccList) then localAccList;
    case (firstList :: restList,comps,localAccList)      
      equation 
        comps2 = Util.listFlatten(comps);
        elem = Util.listIntersectionOnTrue(comps2,firstList,intEq);
        localAccList = listAppend(localAccList,{elem});
        localAccList = sortEquationsBLT(restList,comps,localAccList);  
      then localAccList;
    case (_,_,_)
      equation
        print("- BackendQSS.sortEquationsBLT failed\n");
      then
        fail(); 
  end matchcontinue; 
end sortEquationsBLT;

public function mapStateEqInBlocks
"function: mapStateEqInBlocks
  author: florosx
  Maps Equations into BLT blocks
"   
   input list<list<Integer>> inIntegerLstLst1, inIntegerLstLst2;
   input list<list<list<Integer>>> inIntegerLstLstLst1;
   
   output list<list<list<Integer>>> state_blocks_ind;
   
algorithm 
  state_blocks_ind :=
  matchcontinue (inIntegerLstLst1, inIntegerLstLst2, inIntegerLstLstLst1)    
    local
      list<list<Integer>> sorted_indices, blt_states;
      list<list<list<Integer>>> state_blocks, current_state_blocks;
      
      list<Integer> cur_state;
      list<list<Integer>> rest_states, cur_state_blocks;
      
    case ({}, blt_states, state_blocks)
      equation
      then(state_blocks);
    case (cur_state :: rest_states, blt_states, state_blocks)
      equation                     
        cur_state_blocks = mapStateEqInBlocks2(cur_state, blt_states, {});       
        current_state_blocks = listAppend(state_blocks, {cur_state_blocks});  
        state_blocks = mapStateEqInBlocks(rest_states, blt_states, current_state_blocks);
     then
       (state_blocks);
    case (_,_,_)
      equation
        print("- BackendQSS.mapStateEqInBlocks failed\n");
      then
        fail();       
  end matchcontinue;
end mapStateEqInBlocks;

public function mapStateEqInBlocks2
"function: mapStateEqInBlocks2
  author: florosx
  Helper function for mapStateEqInBlocks2
"    
   input list<Integer> inIntegerLst1;
   input list<list<Integer>> inIntegerLstLst1, inIntegerLstLst2;
   
   output list<list<Integer>> cur_state_blocks;
   
algorithm 
  cur_state_blocks :=
  matchcontinue (inIntegerLst1, inIntegerLstLst1, inIntegerLstLst2)    
    local
      list<list<Integer>> sorted_indices, blt_states;
      
      list<Integer> state_equations, cur_block, remain_state_equations, cur_state_blocks, rest_eq;
      list<list<Integer>> rest_blocks, state_blocks, current_state_blocks;     
      
      Integer cur_eq;  
      
   case (_ , {} , state_blocks)
      equation
      then(state_blocks);
   case ({} , _ , state_blocks)
      equation
      then(state_blocks);
                     
    case (cur_eq :: rest_eq , cur_block :: rest_blocks , state_blocks)
      equation
        true = listMember(cur_eq, cur_block);
        current_state_blocks = listAppend(state_blocks, {cur_block});
        remain_state_equations = removeRedundantEquations(rest_eq, cur_block, {});
        state_blocks = mapStateEqInBlocks2(remain_state_equations, rest_blocks, current_state_blocks);
      then
        (state_blocks);
    case (cur_eq :: rest_eq , cur_block :: rest_blocks , state_blocks)
      equation
        false = listMember(cur_eq, cur_block);
        state_equations = cons(cur_eq, rest_eq);
        state_blocks = mapStateEqInBlocks2(state_equations, rest_blocks, state_blocks);
      then
        (state_blocks);
    case (_,_,_)
      equation
        print("- BackendQSS.mapStateEqInBlocks2 failed\n");
      then
        fail();   
   end matchcontinue;
end mapStateEqInBlocks2;

public function removeRedundantEquations
"function: removeRedundantEquations
  author: florosx
"    
   input list<Integer> inIntegerLst1, inIntegerLst2, inIntegerLst3;  
   output list<Integer> remaining_equations;
   
algorithm 
  remaining_equations :=
  matchcontinue (inIntegerLst1, inIntegerLst2, inIntegerLst3)    
    local  
      list<Integer> rest_eq, cur_block, non_redundant_eq;
      Integer cur_eq;
   case ({},_,non_redundant_eq)
      equation
      then(non_redundant_eq);        
    case (cur_eq :: rest_eq , cur_block, non_redundant_eq)
      equation
        true = listMember(cur_eq, cur_block);
        non_redundant_eq = removeRedundantEquations(rest_eq, cur_block, non_redundant_eq); 
      then
         (non_redundant_eq); 
    case (cur_eq :: rest_eq , cur_block, non_redundant_eq)
      equation
        false = listMember(cur_eq, cur_block);
        non_redundant_eq = listAppend(non_redundant_eq, {cur_eq});
        non_redundant_eq = removeRedundantEquations(rest_eq, cur_block, non_redundant_eq); 
      then
         (non_redundant_eq); 
   case (_,_,_)
      equation
        print("- BackendQSS.removeRedundantEquations failed\n");
      then
        fail();   
     end matchcontinue;
end removeRedundantEquations;





////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - UTIL FUNCTIONS
////////////////////////////////////////////////////////////////////////////////////////////////////

public function removeEmptyElements
"function: removeEmptyElements
  author: florosx
  Removes empty elements from a list
"
   
   input list<list<Integer>> arrList;
   input list<list<Integer>> arrList1;
   
   output list<list<Integer>> reducedList;
   
algorithm 
  reducedList:=
  matchcontinue (arrList, arrList1)   
    local
      list<list<Integer>> rest_list, cur_list;
      list<Integer> head;
    
    case ({}, cur_list)
      equation
        //END OF RECURSION
     then
       (cur_list);
    case (head::rest_list, cur_list)
      equation
        true = Util.isListNotEmpty(head);
        cur_list = listAppend(cur_list, {head});
        reducedList = removeEmptyElements(rest_list, cur_list);
     then
       (reducedList);
    case (head::rest_list, cur_list)      
      equation
        false = Util.isListNotEmpty(head);
        reducedList = removeEmptyElements(rest_list, cur_list);
     then
       (reducedList);
   end matchcontinue;
end removeEmptyElements;

public function printList
"function: printList
  author: florosx
  Prints the elements of a list of integers
"   
   input list<Integer> arrList;  
algorithm 
  _:=
  matchcontinue (arrList)     
    local 
      list<Integer> restList;
      Integer elem;
    case ({})
      equation
      then();
    case (elem::restList)
      equation 
        print(" ");      
        print(intString(elem));
        print(",");
        printList(restList);
     then
       ();      
       end matchcontinue;
end printList;

public function printListOfLists
"function: printListOfLists
  author: florosx
  Prints the elements of a list of lists of integers
"     
   input list<list<Integer>> arrList;
   
algorithm 
  _:=
  matchcontinue (arrList)
    local
       list<list<Integer>> restList;
       list<Integer> elem;
    case ({})
      equation
          print("\n");
      then();
    case (elem::restList)
      equation    
        printList(elem);
        print("--");
        printListOfLists(restList);
     then
       ();      
       end matchcontinue;
end printListOfLists;


end BackendQSS;

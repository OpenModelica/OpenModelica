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
" file:        BackendQSS.mo
  package:     BackendQSS
  description: BackendQSS contains the datatypes used by the backend for QSS solver.
  authors: xfloros, fbergero

  $Id$
"

public import SimCode;
public import BackendDAE;
public import DAE;
public import Absyn;
public import Util;
public import ExpressionDump;
public import Expression;
public import BackendDAEUtil;
public import BackendDump;


protected import BackendVariable;
protected import Debug;
protected import ComponentReference;

public
uniontype DevsStruct "DEVS structure"
  record DEVS_STRUCT  
    array<list<list<Integer>>> outLinks "output connections for each DEVS block";
    array<list<list<Integer>>> outVars "output variables for each DEVS block";
    array<list<list<Integer>>> inLinks "input connections for each DEVS block";
    array<list<list<Integer>>> inVars "input variables for each DEVS block";
  end DEVS_STRUCT;
end DevsStruct;

public
uniontype QSSinfo "- equation indices in static blocks and DEVS structure"
  record QSSINFO
    list<list<list<Integer>>> BLTblocks "BLT blocks in static functions";
    DevsStruct DEVSstructure "DEVS structure of the model";
    list<list<SimCode.SimEqSystem>> eqs;
    list<BackendDAE.Var> outVarLst;
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
       array<Integer> ass1, ass2;
       
       list<BackendDAE.Var> allVarsList, stateVarsList;
       BackendDAE.Variables orderedVars;
       list<BackendDAE.Var> varlst;
       BackendDAE.IncidenceMatrix m, mt, globalIncidenceMat, zeroCrossIncidenceMat, whenReinitIncidenceMat, whenEqIncidenceMat;
       list<BackendDAE.ZeroCrossing> zeroCrossList, samplesList; 
       list<BackendDAE.WhenClause> whenClausesList;
       list<list<SimCode.SimEqSystem>> eqs;
       
       list<Integer> whenEqClausesInd, whenReinitClausesInd, whenEqInd, varsSolvedInEqsList, whenReinitOutVars;       
       Integer nStatic, nIntegr, nBlocks, nZeroCross, nCrossDetect, nEquations, nWhens, ind_whenBlocks_start;
       list<Integer> variableIndicesList,ass1List, ass2List, stateIndices, zcSamplesInd;
       list<list<Integer>> blt_states,blt_no_states, stateEq_flat, globalIncidenceList, comps, mappedEquations, whenEqIncidenceMatList, whenReinitIncidenceMatList, mappedEqReinitMatList;
       list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars, zc_inVars, conns, whenEq_flat;
       list<list<list<Integer>>> stateEq_blt;
       array<list<Integer>> mappedEquationsMat, mappedEquationsMatT;
       list<String> ss;
       String s;
              
       // structure variables
       DevsStruct DEVS_structure;
       array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
 
    case (dlow, ass1, ass2, m, mt, comps)
      equation
        //BackendDump.bltdump(("BackendQss",dlow, m, mt, ass1, ass2, comps));
        
        print("\n ----------------------------\n");
        print("BackEndQSS analysis initialized");
        print("\n ----------------------------\n");
        
         // STEP 1      
        // EXTRACT THE INDICES OF NEEDED EQUATIONS FOR EACH STATE VARIABLE         
        
        (blt_states, blt_no_states) = BackendDAEUtil.generateStatePartition(comps, dlow, ass1, ass2, m, mt);
                 
        stateEq_flat = splitStateEqSet(comps, dlow, ass1, ass2, m, mt) "Extract equations for each state derivative";
        
        stateEq_flat = removeEmptyElements(stateEq_flat, {}) "extract possible empty elements in the list";
        
        // STEP 2      
        // Generate various Info and Structures needed in the following steps     
         
        (allVarsList, stateVarsList) = getAllVars(dlow);
        stateIndices = getStateIndices(allVarsList, {}, 1); 
        variableIndicesList = arrayList(ass2);
        
        varsSolvedInEqsList = arrayList(ass2);
        
        orderedVars = BackendVariable.daeVars(dlow);
        varlst = BackendDAEUtil.varList(orderedVars);
        
        // ZERO-CROSSES
        (zeroCrossList, zc_inVars, samplesList, zcSamplesInd) = getListofZeroCrossings(dlow);
        
        // WHEN-CLAUSES, EQUATIONS AND REINITS
        (whenClausesList, whenEqClausesInd, whenEqInd, whenEqIncidenceMatList) = getWhenEqClausesInfo(dlow);

        print("# when clauses \n");
        print(intString(listLength(whenClausesList)));
        print("\n");
        print("\nwhen eq clauses ind:\n");
        printList(whenEqClausesInd, "start");
        print("\nwhen eq ind:\n");
        printList(whenEqInd, "start");
        print("\nwhen eq incidenceMatList\n");
        printListOfLists(whenEqIncidenceMatList);

        
        // Find the equations that correspond to when-clauses and remove them from the STATE static blocks.
        stateEq_flat = removeListFromListsOfLists(whenEqInd, stateEq_flat, {});
        
        // Provide the equations in the When-Blocks.
        // Note: Currently we are having one when-block for each when-clause. But in the future we "ll group them.
        
        whenEq_flat = Util.listMap(whenEqInd, createListFromElement);
        
        // STEP 3      
        // Map state equations back to BLT blocks     
        
        stateEq_blt = mapStateEqInBlocks( stateEq_flat, blt_states, {}) "Map equations back in BLT blocks";
        
        // More info and variablesk
        
        ind_whenBlocks_start = listLength(stateIndices) + listLength(stateEq_blt) + 2*listLength(zeroCrossList);
        (whenReinitClausesInd, whenReinitIncidenceMatList, mappedEqReinitMatList, whenReinitOutVars) = 
                  getWhenReinitClausesInfo(0, ind_whenBlocks_start, whenClausesList , orderedVars, {}, {}, {}, {});
                
        print("\n when Reinit clauses ind:\n");
        printList(whenReinitClausesInd, "start");
        print("\nwhenReinitIncidenceMatList\n");
        printListOfLists(whenReinitIncidenceMatList);
        print("\nmappedEqReinitMatList\n");
        printListOfLists(mappedEqReinitMatList);
        
        
        
        
        
        
        
        eqs = Util.listMap3(stateEq_blt, generateEqFromBlt,dlow,ass1,ass2);
        nEquations = arrayLength(m);
        nStatic = listLength(stateEq_blt);
        nIntegr = listLength(stateIndices);
        nZeroCross = listLength(zeroCrossList);
        nCrossDetect = nZeroCross;
        nBlocks = nStatic+nIntegr+nZeroCross+nCrossDetect;     
        
        // Map equations to DEVS blocks
        mappedEquations = constructEmptyList({}, nEquations);
        mappedEquations = mapStateEquationsInDEVSblocks(stateEq_blt, mappedEquations, nIntegr+1);
        mappedEquationsMat = listArray(mappedEquations);
        
        
        
        
        
        // STEP 3      
        // GENERALISED INCIDENCE MATRICES
        
        //globalIncidenceList = arrayList(m);
        //globalIncidenceMat = makeIncidenceRightHandNeg(m, variableIndicesList, 1); 
        //zeroCrossIncidenceMat = listArray(fillZeroCrossIncidenceMat(zeroCrossList, dlow, {}));
        //print("\Zero Crossings Incidence Mat\n");
        //BackendDump.dumpIncidenceMatrix(zeroCrossIncidenceMat);
        //globalIncidenceMat = Util.arrayAppend(m, zeroCrossIncidenceMat);
        
        whenReinitIncidenceMat = listArray(whenReinitIncidenceMatList);
        whenEqIncidenceMat = listArray(whenEqIncidenceMatList);
        
        print("\nwhen Eq Incidence Mat\n");
        BackendDump.dumpIncidenceMatrix(whenEqIncidenceMat);
        print("\nwhen ReInit Incidence Mat\n");
        BackendDump.dumpIncidenceMatrix(whenReinitIncidenceMat);
        
        globalIncidenceMat = Util.arrayAppend(m, whenReinitIncidenceMat);
        BackendDump.dumpIncidenceMatrix(globalIncidenceMat);
        
        // This is the extended ass2 variable
        varsSolvedInEqsList = listAppend(varsSolvedInEqsList, whenReinitOutVars);
        
        print("Vars Solved in which eqs: ");
        printList(varsSolvedInEqsList, "start");
        
        // STEP 3      
        // GENERATE THE DEVS STRUCTURES    
        
        DEVS_structure = generateEmptyDEVSstruct(nBlocks, ({},{},{},{}));    
        (DEVS_blocks_outVars, DEVS_blocks_inVars) = getBlocksInOutVars(stateEq_blt, stateIndices, m, ass2);
        DEVS_blocks_inVars = listAppend(DEVS_blocks_inVars, zc_inVars);
        
        print("DEVS_blocks_outVars :\n");
        printListOfLists(DEVS_blocks_outVars);
        print("DEVS_blocks_inVars :\n");
        printListOfLists(DEVS_blocks_inVars);
        
        
        DEVS_structure = generateDEVSstruct(stateIndices, zeroCrossList, nStatic, 
                           DEVS_blocks_outVars, DEVS_blocks_inVars, mappedEquationsMat, DEVS_structure); 
        
        
        // PRINT VARIOUS INFO
        
        print("---------- State equations BLT blocks ----------\n");
        Util.listMap0(stateEq_blt, printListOfLists);
        print("---------- State equations BLT blocks ----------\n");
        
        print("Zero Crossings :\n");
        print("===============\n");
        ss = Util.listMap(zeroCrossList, BackendDump.dumpZcStr);
        s = Util.stringDelimitList(ss, ",\n");
        print(s);
        print("\n");
                      
        dumpDEVSstructs(DEVS_structure);       
        
        //conns = generateConnections(QSSINFO(stateEq_blt, DEVS_structure,eqs,varlst));
        //print("CONNECTIONS\n");
        //printListOfLists(conns);        
        conns = generateConnections(QSSINFO(stateEq_blt, DEVS_structure,eqs,varlst));
        print("CONNECTIONS");
        printListOfLists(conns);        
        //print("\n");
        
      then
        QSSINFO(stateEq_blt, DEVS_structure,eqs,varlst);
        
   case (_,_,_,_,_,_)
      equation
        print("- Main function BackendQSS.generateStructureCodeQSS failed\n");
      then
        fail();          
  end matchcontinue;
end generateStructureCodeQSS;









////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - WHEN CLAUSES AND ZERO CROSSINGS INFO
////////////////////////////////////////////////////////////////////////////////////////////////////

protected function fillZeroCrossIncidenceMat
"function: fillZeroCrossIncidenceMat 
 generates an Incidence Matrix only for the zero-crossing equations.
 author: XF
"
  input list<BackendDAE.ZeroCrossing> zc1;
  input BackendDAE.BackendDAE inDAELow1;
  input list<list<Integer>> temp_output1;
  output list<list<Integer>> zeroCross_IncidenceList;
  
algorithm
  (zeroCross_IncidenceList):=
  matchcontinue (zc1, inDAELow1, temp_output1)
    local
      BackendDAE.Variables allVars;
      list<list<Integer>> temp_output;
      list<BackendDAE.ZeroCrossing> restZeroCross;
      BackendDAE.ZeroCrossing curZeroCross;
      DAE.Exp e;
      list<Integer> eq,wc;
      list<Integer> lst1;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.WhenClause> wc1;
             
    case({}, _, temp_output)
      equation
         // END OF ZERO CROSSINGS
      then (temp_output);
      
    case (BackendDAE.ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)::restZeroCross, 
             BackendDAE.DAE(orderedVars = vars,orderedEqs = eqns, eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc1)), temp_output)
      equation
        lst1 = BackendDAEUtil.incidenceRowExp(e, vars, {});
        temp_output = listAppend(temp_output, {lst1});
        (temp_output) = fillZeroCrossIncidenceMat(restZeroCross, inDAELow1, temp_output) ;
      then
        (temp_output);
  end matchcontinue;
end fillZeroCrossIncidenceMat;




public function getWhenReinitClausesInfo
"function: getListOfWhenClauses 
 extracts the list of when-clauses in the model (equivalently the number of when blocks in the 
 DEVS structure.
 author: XF
"
  input Integer loopIndex;
  input Integer ind_whenBlocks_start;
  input list<BackendDAE.WhenClause> wcIn;
  input BackendDAE.Variables vars;
  input list<Integer> tempOutListWhens;
  input list<list<Integer>> tempOutIncidenceMat;
  input list<list<Integer>> tempOutMapped;
  input list<Integer> tempOutVars;
  
  output list<Integer> whenReinitClausesInd;
  output list<list<Integer>> whenReinitIncidenceMatList;
  output list<list<Integer>> mappedEqReinitMatList;
  output list<Integer> whenReinitOutVars;
  
algorithm
  (whenReinitClausesInd, whenReinitIncidenceMatList, mappedEqReinitMatList, whenReinitOutVars) :=
  matchcontinue (loopIndex, ind_whenBlocks_start, wcIn, vars, tempOutListWhens, tempOutIncidenceMat, tempOutMapped,tempOutVars)
    local
      
      list<BackendDAE.WhenOperator> cur_list;
      list<BackendDAE.WhenClause> rest_clauses;  
      list<BackendDAE.WhenClause> wc;
      list<Integer> row;
      list<list<Integer>> tempList, tempList2;
    
    case (loopIndex, ind_whenBlocks_start, {}, vars, tempOutListWhens, tempOutIncidenceMat, tempOutMapped, tempOutVars) 
      equation
      then
        (tempOutListWhens, tempOutIncidenceMat, tempOutMapped, tempOutVars);   
    
    // WHEN YOU FIND A REINIT  
    case (loopIndex, ind_whenBlocks_start, BackendDAE.WHEN_CLAUSE(reinitStmtLst=cur_list)::rest_clauses, vars, tempOutListWhens, tempOutIncidenceMat, tempOutMapped,tempOutVars) 
      equation
        true = Util.isListNotEmpty(cur_list);
        tempOutListWhens = listAppend(tempOutListWhens, {loopIndex});
        
        (tempOutIncidenceMat, tempOutMapped, tempOutVars) = getWhenReinitClausesInfo2(loopIndex+ind_whenBlocks_start, cur_list, vars, tempOutIncidenceMat, tempOutMapped, tempOutVars);
        
        (tempOutListWhens, tempOutIncidenceMat, tempOutMapped, tempOutVars) = 
                getWhenReinitClausesInfo(loopIndex+1, ind_whenBlocks_start, rest_clauses, vars, tempOutListWhens, tempOutIncidenceMat, tempOutMapped, tempOutVars);
      then
        (tempOutListWhens, tempOutIncidenceMat, tempOutMapped,tempOutVars);
   
   // WHEN YOU DONT FIND A REINIT
    case (loopIndex, ind_whenBlocks_start, BackendDAE.WHEN_CLAUSE(reinitStmtLst=cur_list)::rest_clauses, vars, tempOutListWhens, tempOutIncidenceMat, tempOutMapped,tempOutVars) 
      equation
        false = Util.isListNotEmpty(cur_list);
        (tempOutListWhens, tempOutIncidenceMat, tempOutMapped, tempOutVars) = 
                getWhenReinitClausesInfo(loopIndex+1, ind_whenBlocks_start, rest_clauses, vars, tempOutListWhens, tempOutIncidenceMat, tempOutMapped,tempOutVars);
      then
        (tempOutListWhens, tempOutIncidenceMat, tempOutMapped, tempOutVars);
    case (_,_,_,_,_,_,_,_)
      equation
        print("- BackendQSS.getWhenReinitClausesInfo failed\n");
      then
        fail();            
  end matchcontinue;
end getWhenReinitClausesInfo;

public function getWhenReinitClausesInfo2
"function: getListOfWhenClauses 
 extracts the list of when-clauses in the model (equivalently the number of when blocks in the 
 DEVS structure.
 author: XF
"
  input Integer whenIndex;
  input list<BackendDAE.WhenOperator> cur_ReinitList;
  input BackendDAE.Variables vars;
  input list<list<Integer>> tempOutIncidenceMat;
  input list<list<Integer>> tempOutMapped;
  input list<Integer> tempOutVars;
  
  output list<list<Integer>> whenReinitIncidenceMatList;
  output list<list<Integer>> mappedEqReinitMatList;
  output list<Integer> whenReinitOutVars;
  
algorithm
  (whenReinitIncidenceMatList, mappedEqReinitMatList,whenReinitOutVars) :=
  matchcontinue (whenIndex, cur_ReinitList, vars, tempOutIncidenceMat, tempOutMapped, tempOutVars)
    local   
      list<BackendDAE.WhenOperator> rest_reinits;
      DAE.ComponentRef leftHand;  
      DAE.Exp rightHand;
      list<Integer> row, lst1, lst2;
    case (whenIndex, {}, vars, tempOutIncidenceMat, tempOutMapped, tempOutVars) 
      equation
      then
        (tempOutIncidenceMat, tempOutMapped, tempOutVars);   
    
    case (whenIndex, BackendDAE.REINIT(stateVar = leftHand, value = rightHand)::rest_reinits, vars, tempOutIncidenceMat, tempOutMapped, tempOutVars) 
      equation
        
        lst1 = BackendDAEUtil.incidenceRowExp(DAE.CREF(leftHand,DAE.ET_REAL()), vars, {});
        lst2 = BackendDAEUtil.incidenceRowExp(rightHand, vars, {});
        //lst2 = filterDiscreteVars(lst2,vars);
        //lst2 = makeListNegative(lst2, {});
        row = listAppend(lst1, lst2);
        tempOutVars = listAppend(tempOutVars, lst1);
        tempOutIncidenceMat = listAppend(tempOutIncidenceMat, {row});
        tempOutMapped = listAppend(tempOutMapped, {{whenIndex}});
        
        (tempOutIncidenceMat, tempOutMapped, tempOutVars) = getWhenReinitClausesInfo2(whenIndex, rest_reinits, vars, tempOutIncidenceMat, tempOutMapped, tempOutVars);
    
      then
        (tempOutIncidenceMat, tempOutMapped, tempOutVars);
     
    case (_,_,_,_,_,_)
      equation
        print("- BackendQSS.getWhenReinitClausesInfo2 failed\n");
      then
        fail();    
       
  end matchcontinue;
end getWhenReinitClausesInfo2;






public function getWhenEqClausesInfo 
"function: getWhenClausesInfo
 returns the indices of equations inside whens (when-clauses), the corresponding indices 
 of the when-clauses and the modified incidenceMat for the when-clauses.
 author: XF
"
  input BackendDAE.BackendDAE dlow;
  output list<BackendDAE.WhenClause> whenClauses_list;
  output list<Integer> whenEqClausesInd;
  output list<Integer> whenEqInd;
  output list<list<Integer>> whenEqIncidenceMatList;
  
algorithm
  (whenClauses_list, whenEqClausesInd, whenEqInd, whenEqIncidenceMatList) := 
  matchcontinue(dlow)
    local
      BackendDAE.EquationArray eqnArr;
      list<BackendDAE.WhenClause> wc;
      BackendDAE.Variables vars;
      
    case (BackendDAE.DAE(orderedVars = vars, orderedEqs=eqnArr, eventInfo = BackendDAE.EVENT_INFO(whenClauseLst = wc)))
      equation
        (whenEqInd, whenEqClausesInd,whenEqIncidenceMatList) = whenEquationsIndices(eqnArr, vars);
      then (wc, whenEqClausesInd, whenEqInd, whenEqIncidenceMatList);
  end matchcontinue;
end getWhenEqClausesInfo;

public function whenEquationsIndices 
"function: whenEquationsIndices
 author: XF
"
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Variables vars; 
  output list<Integer> eqInd, whenClauseInd;
  output list<list<Integer>> whenIncidenceMatList; 
algorithm
   (eqInd, whenClauseInd,whenIncidenceMatList) :=
    matchcontinue(eqns, vars)
     case(eqns,vars)
       equation
         (eqInd, whenClauseInd, whenIncidenceMatList) = whenEquationsIndices2(1,BackendDAEUtil.equationSize(eqns),eqns, vars,{});
       then (eqInd, whenClauseInd, whenIncidenceMatList);
   end matchcontinue;
end whenEquationsIndices;

protected function whenEquationsIndices2 
"function: whenEquationsIndices2 - HELP function
 author: XF
"
  input Integer i;
  input Integer size;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Variables vars; 
  input list<list<Integer>> whenIncidenceMatList_temp1;
  output list<Integer> eqnLst, whenClausesList;
  output list<list<Integer>> whenIncidenceMatList; 
algorithm
  (eqnLst, whenClausesList, whenIncidenceMatList) := 
  matchcontinue(i,size,eqns,vars,whenIncidenceMatList_temp1)
    local
      BackendDAE.WhenEquation whenEq;
      Integer tempInd;
      list<Integer> row;
      list<list<Integer>> whenIncidenceMatList_temp;
  
    case(i,size,eqns, vars, whenIncidenceMatList_temp) equation
      true = (i > size );
    then ({},{},whenIncidenceMatList_temp);
  
    case(i,size,eqns, vars, whenIncidenceMatList_temp)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation = whenEq) = BackendDAEUtil.equationNth(eqns,i-1);
        BackendDAE.WHEN_EQ(index = tempInd) = whenEq;
       
        row = getRowWhenIncidenceMat(whenEq, vars);
            
        whenIncidenceMatList_temp = listAppend(whenIncidenceMatList_temp, {row});
        (eqnLst, whenClausesList, whenIncidenceMatList_temp) = whenEquationsIndices2(i+1,size,eqns,vars, whenIncidenceMatList_temp);
    then (i::eqnLst, tempInd::whenClausesList, whenIncidenceMatList_temp);
    
    case(i,size,eqns,vars,whenIncidenceMatList_temp)
      equation
        (eqnLst, whenClausesList,whenIncidenceMatList_temp) = whenEquationsIndices2(i+1,size,eqns,vars,whenIncidenceMatList_temp);
      then (eqnLst, whenClausesList,whenIncidenceMatList_temp);
  
  end matchcontinue;
end whenEquationsIndices2;


protected function getRowWhenIncidenceMat
"function: whenEquationsIndices2 - HELP function
 author: XF
"
  input BackendDAE.WhenEquation whenEq1;
  input BackendDAE.Variables vars; 
  output list<Integer> rowIncidenceMat;
   
algorithm
  (rowIncidenceMat) := 
  matchcontinue(whenEq1, vars)
    local
      BackendDAE.WhenEquation whenEq;
      DAE.ComponentRef outRef;  
      DAE.Exp inExpr;    
     
      Integer tempInd;
      list<Integer> row, lst1, lst2;
      list<list<Integer>> whenIncidenceMatList_temp;
      String temp;
      
    case(BackendDAE.WHEN_EQ(left = outRef, right = inExpr), vars)
      equation
        
        lst1 = BackendDAEUtil.incidenceRowExp(DAE.CREF(outRef,DAE.ET_REAL()), vars, {});
        lst2 = BackendDAEUtil.incidenceRowExp(inExpr, vars, {});
        lst2 = makeListNegative(lst2, {});
        row = listAppend(lst1, lst2);
    then (row);
  end matchcontinue;
end getRowWhenIncidenceMat;


////////////////////////////////////////////////////////////////////////////////////////////////////











public function getListofZeroCrossings 
"function: getListofZeroCrossings
  Takes as input the DAE and extracts the zero-crossings as well as the zero crosses that are 
  connected to sample statements.
  author: florosx
"
  input BackendDAE.BackendDAE dae;
  output list<BackendDAE.ZeroCrossing> zcOnly;
  output list<list<Integer>> zc_inVars;
  output list<BackendDAE.ZeroCrossing> zcSamples;
  output list<Integer> zcSamplesInd;

algorithm
  (zcOnly, zc_inVars, zcSamples, zcSamplesInd):=
  matchcontinue (dae)
    local
      list<BackendDAE.ZeroCrossing> zc;
      BackendDAE.Variables vars;
    case (BackendDAE.DAE(orderedVars=vars, eventInfo = BackendDAE.EVENT_INFO(zeroCrossingLst = zc)))
      equation
        (zcOnly, zc_inVars, zcSamples, zcSamplesInd) = getListofZeroCrossings2(1, zc, vars, {}, {}, {}, {});
      then
        (zcOnly, zc_inVars, zcSamples, zcSamplesInd);
    case (_)
      equation
        print("- BackendQSS.getListofZeroCrossings failed\n");
      then
        fail();        
  end matchcontinue;
end getListofZeroCrossings;

public function getListofZeroCrossings2 
"function: getListofZeroCrossings
  Helper function for getListofZeroCrossings
  author: florosx
"
  input Integer loopIndex;
  input list<BackendDAE.ZeroCrossing> zc;
  input BackendDAE.Variables vars;
  input list<list<Integer>> zc_inVarsTemp;
  input list<BackendDAE.ZeroCrossing> zcOnlyTemp;
  input list<BackendDAE.ZeroCrossing> zcSamplesTemp;
  input list<Integer> zcSamplesIndTemp;
  
  output list<BackendDAE.ZeroCrossing> zcOnly;
  output list<list<Integer>> zc_inVars;
  output list<BackendDAE.ZeroCrossing> zcSamples;
  output list<Integer> zcSamplesInd;
  
algorithm
  (zcOnly, zc_inVars, zcSamples, zcSamplesInd):=
  matchcontinue (loopIndex, zc, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp, zcSamplesIndTemp)
    local
      list<BackendDAE.Value> tempInVars;
      BackendDAE.ZeroCrossing cur_zc;
      list<BackendDAE.ZeroCrossing> rest_zeroCrossings;
      DAE.Exp e;
    
    case (loopIndex, {}, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp,zcSamplesIndTemp)
      equation
      then
        (zcOnlyTemp, zc_inVarsTemp, zcSamplesTemp,zcSamplesIndTemp);  
      
    case (loopIndex, (cur_zc as BackendDAE.ZERO_CROSSING(relation_ = e))::rest_zeroCrossings, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp, zcSamplesIndTemp)
      equation
        true = checkIfExpressionIsSample(e);
        zcSamplesTemp = listAppend(zcSamplesTemp, {cur_zc});
        zcSamplesIndTemp = listAppend(zcSamplesIndTemp, {loopIndex});
        (zcOnlyTemp, zc_inVarsTemp, zcSamplesTemp, zcSamplesIndTemp) = getListofZeroCrossings2(loopIndex+1, rest_zeroCrossings, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp,zcSamplesIndTemp);
      then
        (zcOnlyTemp, zc_inVarsTemp, zcSamplesTemp,zcSamplesIndTemp);
    case (loopIndex, (cur_zc as BackendDAE.ZERO_CROSSING(relation_ = e))::rest_zeroCrossings, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp, zcSamplesIndTemp)
      equation
        false = checkIfExpressionIsSample(e);
        tempInVars = BackendDAEUtil.incidenceRowExp(e, vars, {});
        zc_inVarsTemp = listAppend(zc_inVarsTemp, {tempInVars});
        zcOnlyTemp = listAppend(zcOnlyTemp, {cur_zc});
        (zcOnlyTemp, zc_inVarsTemp, zcSamplesTemp, zcSamplesIndTemp) = getListofZeroCrossings2(loopIndex+1, rest_zeroCrossings, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp,zcSamplesIndTemp);
      then
        (zcOnlyTemp, zc_inVarsTemp, zcSamplesTemp,zcSamplesIndTemp);
    case (_,_,_,_,_,_,_)
      equation
        print("- BackendQSS.getListofZeroCrossings2 failed\n");
      then
        fail();  
  end matchcontinue;
end getListofZeroCrossings2;

public function checkIfExpressionIsSample
"function: getListofZeroCrossings
  Checks if a given expression is a sample
  author: florosx
"
  input DAE.Exp e;
  output Boolean isSample;
algorithm
  (isSample):=
  matchcontinue (e)
    local
      DAE.Exp e;
    case (DAE.CALL(path = Absyn.IDENT(name = "sample")))
      equation
        // It's a sample
      then
        (true);
    case (_)
      equation
      then
        (false);
  end matchcontinue;
end checkIfExpressionIsSample;










////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - INCIDENCE MATRICES
////////////////////////////////////////////////////////////////////////////////////////////////////

protected function makeIncidenceRightHandNeg
"function: makeIncidenceRightHandNeg
  author: florosx
  Takes the incidence matrix and adds negative signs to the variables that are on the right
  hand side in each equation and with a positive sign the variable that is solved there.
"
  input BackendDAE.IncidenceMatrix globalIncidenceMatIn;
  input list<Integer> ass2_list;
  input Integer curInd;
  
  output BackendDAE.IncidenceMatrix globalIncidenceMatOut;

algorithm
  (globalIncidenceMatOut):=
  matchcontinue (globalIncidenceMatIn, ass2_list, curInd)
    local
      
      Integer cur_var, curInd, tempInd;
      list<Integer> rest_vars, cur_eq;
      BackendDAE.IncidenceMatrix globalIncidenceMat_temp;       
      
    case(globalIncidenceMat_temp, {}, curInd)
      equation
      then (globalIncidenceMat_temp);
    
    //cur_var is the variable that current equation solves
    case (globalIncidenceMat_temp, cur_var::rest_vars, curInd)
      equation
        // Make everything negative except from the variable that is solved for.
        cur_eq = globalIncidenceMat_temp[curInd];
        tempInd = findElementInList(0, listLength(cur_eq), cur_eq, cur_var);
        cur_eq = makeListNegative(cur_eq, {});
        cur_eq = Util.listReplaceAt(cur_var, tempInd, cur_eq);
        globalIncidenceMat_temp = arrayUpdate(globalIncidenceMat_temp, curInd, cur_eq);
        globalIncidenceMat_temp = makeIncidenceRightHandNeg(globalIncidenceMat_temp, rest_vars, curInd+1);
      then
        (globalIncidenceMat_temp);
     case (_,_,_)
      equation
        print("- BackendQSS.makeIncidenceRightHandNeg failed\n");
      then
        fail();
  end matchcontinue;
end makeIncidenceRightHandNeg;


////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - GENERATE DEVS STRUCTURES
////////////////////////////////////////////////////////////////////////////////////////////////////

protected function generateEmptyDEVSstruct
"function: generateEmptyDEVSstruct
  Generates an empty DEVS struct for the given number of blocks
  author: florosx
"
  input Integer nBlocks;
  input tuple< list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>> > DEVS_struct_lists_temp;
  output DevsStruct DEVS_structureOut;
  
algorithm
  (DEVS_structureOut):=
  matchcontinue (nBlocks, DEVS_struct_lists_temp)
    local
      list<list<list<Integer>>> DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      
    case (0, (DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList) )
      equation      
        DEVS_struct_outLinks = listArray(DEVS_struct_outLinksList);
        DEVS_struct_inLinks = listArray(DEVS_struct_inLinksList);
        DEVS_struct_outVars = listArray(DEVS_struct_outVarsList);
        DEVS_struct_inVars = listArray(DEVS_struct_inVarsList);       
      then
        (DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars));
      
    case (nBlocks, (DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList))
      equation
        DEVS_struct_outLinksList = listAppend(DEVS_struct_outLinksList, {{}});
        DEVS_struct_outVarsList = listAppend(DEVS_struct_outVarsList, {{}});
        DEVS_struct_inLinksList = listAppend(DEVS_struct_inLinksList, {{}});
        DEVS_struct_inVarsList = listAppend(DEVS_struct_inVarsList, {{}});
      then
        (generateEmptyDEVSstruct(nBlocks-1, (DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList)) );
    case (_,_)
      equation
        print("- BackendQSS.EmptyDEVSstruct failed\n");
      then
        fail();
  end matchcontinue;
end generateEmptyDEVSstruct;

protected function getBlocksInOutVars
"function: getBlocksInOutVars
  For the DEVS blocks extract input/output variables
  author: florosx
"
  input list<list<list<Integer>>> stateEq_blt;
  input list<Integer> stateIndices;
  input BackendDAE.IncidenceMatrix incidenceMat;
  input array<Integer> ass2;
  output list<list<Integer>> DEVS_blocks_outVarsOut;
  output list<list<Integer>> DEVS_blocks_inVarsOut;
 
algorithm
  (DEVS_blocks_outVarsOut, DEVS_blocks_inVarsOut):=
  matchcontinue (stateEq_blt, stateIndices, incidenceMat, ass2)
    local
     
      list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars;
      tuple< list<list<Integer>>, list<list<Integer>> > DEVS_blocks_inOutVars_temp;
     
    case (stateEq_blt, stateIndices, incidenceMat, ass2)
      equation        
        
        (DEVS_blocks_inOutVars_temp) = qssIntegratorsInOutVars(stateIndices,({},{}));
        ((DEVS_blocks_outVars, DEVS_blocks_inVars)) = incidenceMatInOutVars(stateEq_blt, incidenceMat, ass2, DEVS_blocks_inOutVars_temp);
        
      then
        (DEVS_blocks_outVars, DEVS_blocks_inVars);
    case (_,_,_,_)
      equation
        print("- BackendQSS.getBlocksInOutVars failed\n");
      then
        fail();
  end matchcontinue;
end getBlocksInOutVars;

protected function generateDEVSstruct
"function: generateDEVSstruct
  author: florosx
  Right now it is not needed. But kept like that for future additions.
"
  input list<Integer> stateIndices;
  input list<BackendDAE.ZeroCrossing> zeroCrossList;
  input Integer nStatic;
  input list<list<Integer>> DEVS_blocks_outVars;
  input list<list<Integer>> DEVS_blocks_inVars;
  input array<list<Integer>> mappedEquationsMat;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (stateIndices, zeroCrossList, nStatic, DEVS_blocks_outVars, DEVS_blocks_inVars, mappedEquationsMat, DEVS_structureIn)
    local
      Integer nStatic, nIntegr, nBlocks, nZeroCross, nCrossDetect, startCrossDetectInd, startZeroCrossInd; 
      DevsStruct DEVS_structure_temp;
      
    case (stateIndices, zeroCrossList, nStatic, DEVS_blocks_outVars, DEVS_blocks_inVars, mappedEquationsMat, DEVS_structure_temp)
      equation
        nIntegr = listLength(stateIndices);
        nZeroCross = listLength(zeroCrossList);
        nBlocks = nIntegr + nStatic + 2*nZeroCross;
        startZeroCrossInd = nStatic + nIntegr + 1;
        startCrossDetectInd = nStatic + nIntegr + nZeroCross + 1;
        
        //Resolve dependencies between inputs/outputs excluding events      
        (DEVS_structure_temp) = generateStructFromInOutVars(1,stateIndices,DEVS_blocks_outVars, DEVS_blocks_inVars, DEVS_structure_temp);
        //Add the connections between zero-crossings and cross-detectors
        (DEVS_structure_temp) = addZeroCrossOut_CrossDetectIn(startZeroCrossInd, startCrossDetectInd, zeroCrossList, DEVS_structure_temp);
        //Add the cross-detector blocks outputs
        (DEVS_structure_temp) = addCrossDetectBlocksOut(startCrossDetectInd, zeroCrossList, mappedEquationsMat, DEVS_structure_temp);
        
        // Resolve dependencies for EVENTS
        // Already we should have resolved the dependencies between DEVS blocks concerning the variables.
        DEVS_structure_temp = updateEventsAsInputs(startCrossDetectInd, nBlocks, DEVS_structure_temp);  
      then
        (DEVS_structure_temp);
    case (_,_,_,_,_,_,_)
      equation
        print("- BackendQSS.generateDEVSstruct failed\n");
      then
        fail();
  end matchcontinue;
end generateDEVSstruct;

protected function updateEventsAsInputs
"function: updateEventsAsInputs
  
  author: florosx
" 
  input Integer startBlockInd;
  input Integer endBlockInd;
  input DevsStruct DEVS_structureIn;
  
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (startBlockInd, endBlockInd, DEVS_structureIn)
    local
      list<list<Integer>> curBlock_outLinks, curBlock_outVars, curBlock_inLinks, curBlock_inVars;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      DevsStruct DEVS_structure_temp;
      list<Integer> curBlock_outLinks_flat;
      
    case (startBlockInd, endBlockInd, DEVS_structure_temp)
      equation
        true = startBlockInd > endBlockInd;
      then
        (DEVS_structure_temp);
      
    case (startBlockInd, endBlockInd, DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation
       // Find to which blocks the events go and add them as inputs to the last port
       curBlock_outLinks = DEVS_struct_outLinks[startBlockInd];
       curBlock_outLinks_flat = Util.listFlatten(curBlock_outLinks);
       (DEVS_struct_inLinks, DEVS_struct_inVars) = updateEventsAsInputs2(startBlockInd, curBlock_outLinks_flat, DEVS_struct_inLinks, DEVS_struct_inVars);
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
       DEVS_structure_temp = updateEventsAsInputs(startBlockInd+1, endBlockInd, DEVS_structure_temp);
      then
        (DEVS_structure_temp);
    case (_,_,_)
      equation
        print("- BackendQSS.updateEventsAsInputs failed\n");
      then
        fail();
  end matchcontinue;
end updateEventsAsInputs;

protected function updateEventsAsInputs2
"function: updateEventsAsInputs
  
  author: florosx
" 
  input Integer eventBlockInd;
  input list<Integer> inBlocksInd;
  input array<list<list<Integer>>> DEVS_struct_inLinks;
  input array<list<list<Integer>>> DEVS_struct_inVars;
  output array<list<list<Integer>>> DEVS_struct_inLinksOut;
  output array<list<list<Integer>>> DEVS_struct_inVarsOut;

 
algorithm
  (DEVS_struct_inLinksOut, DEVS_struct_inVarsOut):=
  matchcontinue (eventBlockInd, inBlocksInd, DEVS_struct_inLinks, DEVS_struct_inVars )
    local
      list<list<Integer>> curBlock_inLinks, curBlock_inVars;
      list<Integer> tempList, restBlocks;
      Integer curBlockIn, portIn;
      
    case (eventBlockInd, {}, DEVS_struct_inLinks, DEVS_struct_inVars)
      equation
      then
        (DEVS_struct_inLinks, DEVS_struct_inVars);
      
    case (eventBlockInd, curBlockIn::restBlocks, DEVS_struct_inLinks, DEVS_struct_inVars)
      equation
       curBlock_inLinks = DEVS_struct_inLinks[curBlockIn];
       curBlock_inVars = DEVS_struct_inVars[curBlockIn];
       portIn = findInputPort(0, curBlock_inVars, 0);
       //Check if the curBlockIn has already an event port. If yes, add the startBlockInd, otherwise create an event port.
       true = portIn == -1 ; // If there exists no event port 
       curBlock_inVars = listAppend(curBlock_inVars, {{0}});
       curBlock_inLinks = listAppend(curBlock_inLinks, {{eventBlockInd}});
       DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, curBlockIn, curBlock_inLinks);
       DEVS_struct_inVars = arrayUpdate(DEVS_struct_inVars, curBlockIn, curBlock_inVars);
       (DEVS_struct_inLinks, DEVS_struct_inVars) = updateEventsAsInputs2(eventBlockInd, restBlocks, DEVS_struct_inLinks, DEVS_struct_inVars);
       then
        (DEVS_struct_inLinks, DEVS_struct_inVars);
        
    case (eventBlockInd, curBlockIn::restBlocks, DEVS_struct_inLinks, DEVS_struct_inVars)
      equation
       curBlock_inLinks = DEVS_struct_inLinks[curBlockIn];
       curBlock_inVars = DEVS_struct_inVars[curBlockIn];
       portIn = findInputPort(0, curBlock_inVars, 0);
       //Check if the curBlockIn has already an event port. If yes, add the startBlockInd, otherwise create an event port.
       false = portIn == -1 ;// If there already exists an event port 
       tempList = listNth(curBlock_inLinks, portIn);
       tempList = listAppend(tempList, {eventBlockInd});
       curBlock_inLinks = Util.listReplaceAt(tempList, portIn, curBlock_inLinks);
       DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, curBlockIn, curBlock_inLinks);
       (DEVS_struct_inLinks, DEVS_struct_inVars) = updateEventsAsInputs2(eventBlockInd, restBlocks, DEVS_struct_inLinks, DEVS_struct_inVars);
       then
        (DEVS_struct_inLinks, DEVS_struct_inVars);
      
    case (_,_,_,_)
      equation
        print("- BackendQSS.updateEventsAsInputs2 failed\n");
      then
        fail();
  end matchcontinue;
end updateEventsAsInputs2;







protected function addZeroCrossOut_CrossDetectIn
"function: addZeroCrossOut_CrossDetectIn
  Adds the Outputs of the Zero-Crossing Blocks (to the cross-detectors) and the respective inputs to the cross-detectors.
  author: florosx
" 
  input Integer zeroCrossBlockInd;
  input Integer crossDetectBlockInd;
  input list<BackendDAE.ZeroCrossing> zeroCrossList;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (zeroCrossBlockInd, crossDetectBlockInd, zeroCrossList, DEVS_structureIn)
    local
      list<list<Integer>> curBlock_outLinks, curBlock_outVars, curBlock_inLinks, curBlock_inVars;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      DevsStruct DEVS_structure_temp;
      list<BackendDAE.ZeroCrossing> restZC;
      BackendDAE.ZeroCrossing curZC;
      
    case (zeroCrossBlockInd, crossDetectBlockInd, {}, DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);
      
    case (zeroCrossBlockInd, crossDetectBlockInd, curZC::restZC, DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation
       DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, zeroCrossBlockInd, {{crossDetectBlockInd}});
       DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, zeroCrossBlockInd, {{0}});
       DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, crossDetectBlockInd, {{zeroCrossBlockInd}});
       DEVS_struct_inVars = arrayUpdate(DEVS_struct_inVars, crossDetectBlockInd, {{0}});
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);      
       DEVS_structure_temp = addZeroCrossOut_CrossDetectIn(zeroCrossBlockInd+1, crossDetectBlockInd+1, restZC, DEVS_structure_temp);
      then
        (DEVS_structure_temp);
    case (_,_,_,_)
      equation
        print("- BackendQSS.addZeroCrossBlocksOut failed\n");
      then
        fail();
  end matchcontinue;
end addZeroCrossOut_CrossDetectIn;

protected function addCrossDetectBlocksOut
"function: addCrossDetectBlocks
  Adds the cross-detector blocks in the DEVS structure.
  author: florosx
" 
  input Integer startBlockInd;
  input list<BackendDAE.ZeroCrossing> zeroCrossList;
  input array<list<Integer>> mappedEquationsMat;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (startBlockInd, zeroCrossList, mappedEquationsMat, DEVS_structureIn)
    local
      list<list<Integer>> curBlock_outLinks, curBlock_outVars, curBlock_inLinks, curBlock_inVars;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      DevsStruct DEVS_structure_temp;
      list<BackendDAE.ZeroCrossing> restZC;
      BackendDAE.ZeroCrossing curZC;
      list<Integer> eq,wc, curDevsBlocks;
      DAE.Exp e;
      
    case (startBlockInd, {}, mappedEquationsMat, DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);
      
    case (startBlockInd, BackendDAE.ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)::restZC, mappedEquationsMat, 
                   DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation
       
       curDevsBlocks = findEqInBlocks(eq, mappedEquationsMat,{});
       curBlock_outVars = {{0}};
       curBlock_outLinks = {curDevsBlocks};
       
       /*
       eq = SimCodegenQSS_Utils.makeListNegative(eq, {});
       cur_state_DEVS_blocks = get_curState_DEVS_blocks(eq, mappedEquationsMat, {});
       cur_state_DEVS_blocks = SimCodegenQSS_Utils.removeRedundantElements(cur_state_DEVS_blocks, {});
       
        wc = Util.listMap1(wc,intAdd,ind_whenBlocks_start);
        cur_state_DEVS_blocks = listAppend(cur_state_DEVS_blocks, wc);
        */
        
       DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, startBlockInd, curBlock_outLinks);
       DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, startBlockInd, curBlock_outVars);
      
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
       
       DEVS_structure_temp = addCrossDetectBlocksOut(startBlockInd+1, restZC, mappedEquationsMat, DEVS_structure_temp);
      then
        (DEVS_structure_temp);
    case (_,_,_,_)
      equation
        print("- BackendQSS.addCrossDetectBlocksOut failed\n");
      then
        fail();
  end matchcontinue;
end addCrossDetectBlocksOut;




protected function findEqInBlocks
"function: findEqInBlocks
  Adds the cross-detector blocks in the DEVS structure.
  author: florosx
" 
  input list<Integer> eqInd;
  input array<list<Integer>> mappedEquationsMat;
  input list<Integer> blocksInd_temp;
  output list<Integer> blocksInd_out;
 
algorithm
  (blocksInd_out):=
  matchcontinue (eqInd, mappedEquationsMat, blocksInd_temp)
    local
      Integer curEq;
      list<Integer> restEq, curBlocks;
      
    case ({}, mappedEquationsMat, blocksInd_temp)
      equation
      then
        (blocksInd_temp);
      
    case (curEq::restEq, mappedEquationsMat, blocksInd_temp)
      equation
       curBlocks = mappedEquationsMat[curEq];
       blocksInd_temp = listAppend(blocksInd_temp, curBlocks);
       blocksInd_temp = findEqInBlocks(restEq, mappedEquationsMat, blocksInd_temp);
      then
        (blocksInd_temp);
    case (_,_,_)
      equation
        print("- BackendQSS.findEqInBlocks failed\n");
      then
        fail();
  end matchcontinue;
end findEqInBlocks;











protected function generateStructFromInOutVars
"function: generateStructFromInOutVars
  Takes as input the inputs/outputs of each block and generates the DEVS structures resolving the dependencies.
  author: florosx
"
  input Integer curBlockIndex;
  input list<Integer> stateIndices;
  input list<list<Integer>> DEVS_blocks_outVars;
  input list<list<Integer>> DEVS_blocks_inVars;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (curBlockIndex,stateIndices, DEVS_blocks_outVars, DEVS_blocks_inVars, DEVS_structureIn)
    local
      tuple< list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>> > DEVS_struct_lists_temp;
   
      list<list<list<Integer>>> DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      
      list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars, rest_blocks_outVars;
      list<Integer> curBlock_outVars;
      
      tuple< list<list<Integer>>, list<list<Integer>> > DEVS_blocks_inOutVars_temp;
      
      DevsStruct DEVS_structure_temp;
   
    case (curBlockIndex, stateIndices, {}, _ , DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);
      
    case (curBlockIndex, stateIndices, curBlock_outVars::rest_blocks_outVars, DEVS_blocks_inVars, DEVS_structure_temp )
      equation
        
       DEVS_structure_temp = findOutVarsInAllInputs(curBlockIndex, stateIndices, curBlock_outVars, DEVS_blocks_inVars, DEVS_structure_temp);
       
      then
        (generateStructFromInOutVars(curBlockIndex+1, stateIndices, rest_blocks_outVars, DEVS_blocks_inVars, DEVS_structure_temp));
    case (_,_,_,_,_)
      equation
        print("- BackendQSS.generateStructFromInOutVars failed\n");
      then
        fail();
  end matchcontinue;
end generateStructFromInOutVars;

// NOTE: THIS FUNCTION HAS TO BE REDESIGNED
protected function findOutVarsInAllInputs
"function: findOutVarsInAllInputs
  Checks for the current DEVS block all output variables if are needed anywhere else and if yes in which blocks.
  author: florosx
"
  input Integer outBlockIndex;
  input list<Integer> stateIndices;
  input list<Integer> curBlock_outVars;
  input list<list<Integer>> DEVS_blocks_inVars;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (outBlockIndex, stateIndices, curBlock_outVars, DEVS_blocks_inVars, DEVS_structureIn)
    local
      tuple< list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>> > DEVS_struct_lists_temp;
   
      list<list<list<Integer>>> DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      
      list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars, rest_blocks_outVars, DEVS_blocks_inVars_reduced;
      list<list<Integer>> restBlocks_inVars, curOutBlock_outLinks, curOutBlock_outVars, curInBlock_inLinks, curInBlock_inVars;
      
      tuple< list<list<Integer>>, list<list<Integer>> > DEVS_blocks_inOutVars_temp;
      
      Integer curOutVar;
      list<Integer> restOutVars, curOutVarLinks, blocksToBeChecked, tempOutVars;
      DevsStruct DEVS_structure_temp;
    //END OF RECURSION
    case (outBlockIndex, stateIndices, {}, _ , DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);

    case (outBlockIndex, stateIndices, curOutVar::restOutVars, DEVS_blocks_inVars, 
             DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars) )
      equation
        blocksToBeChecked = findOutVarsInAllInputsHelper(curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex);          
       
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars) = 
                   findWhereOutVarIsNeeded(curOutVar, outBlockIndex, blocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars,{});
        true = Util.isListNotEmpty(curOutVarLinks) "If the current output var is needed somewhere";
        
        curOutBlock_outVars = DEVS_struct_outVars[outBlockIndex];
        curOutBlock_outLinks = DEVS_struct_outLinks[outBlockIndex];
        curOutBlock_outLinks = listAppend(curOutBlock_outLinks, {curOutVarLinks});
        curOutBlock_outVars = listAppend(curOutBlock_outVars, {{curOutVar}}); 
                
        DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, outBlockIndex, curOutBlock_outLinks);
        DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, outBlockIndex, curOutBlock_outVars);
        DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
        DEVS_structure_temp = findOutVarsInAllInputs(outBlockIndex, stateIndices, restOutVars, DEVS_blocks_inVars, DEVS_structure_temp); 
      then
        (DEVS_structure_temp);
        
     // If the current output var is NOT needed somewhere
     case (outBlockIndex, stateIndices, curOutVar::restOutVars, DEVS_blocks_inVars,  DEVS_structure_temp )
      equation
      then
        (findOutVarsInAllInputs(outBlockIndex, stateIndices, restOutVars, DEVS_blocks_inVars, DEVS_structure_temp));
    
    case (_,_,_,_,_)
      equation
        
        print("- BackendQSS.findOutVarsInAllInputs failed\n");
      then
        fail();
  end matchcontinue;
end findOutVarsInAllInputs;

protected function findOutVarsInAllInputsHelper
"function: findOutVarsInAllInputsHelper
  For a current output variable checks in which blocks it is needed as input.
  For example for algebraic variables we need to exlude the current block from checking. 
  author: florosx
"
  input Integer curOutVar;
  input list<Integer> stateIndices;
  input list<list<Integer>> DEVS_blocks_inVars;
  input Integer outBlockIndex;
  output list<Integer> blocksToBeCheckedOut;
 
algorithm
  (blocksToBeCheckedOut):=
  matchcontinue (curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex)
    local
      list<Integer> blocksToBeChecked;
   
    // If CURRENT OUTPUT IS STATE    
    case (curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex)
      equation
        true = Util.listContains(-curOutVar, stateIndices);
        blocksToBeChecked = createListIncreasingIndices(1,listLength(DEVS_blocks_inVars),{});          
      then
        (blocksToBeChecked);
    // If CURRENT OUTPUT IS DERIVATIVE OF STATE
    // This case is of interest if we have coupled states where we dont want the output derivatives to loop
    // back to the same block as inputs.
    case (curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex) 
      equation
        true = Util.listContains(curOutVar, stateIndices);
        blocksToBeChecked = createListIncreasingIndices(1,listLength(DEVS_blocks_inVars),{});  
        blocksToBeChecked = Util.listRemoveNth(blocksToBeChecked, outBlockIndex); // If state derivative remove the current block from the input search.  
      then
        (blocksToBeChecked);
   // If CURRENT OUTPUT IS ALGEBRAIC
    case (curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex) 
      equation
        false = Util.listContains(curOutVar, stateIndices);
        blocksToBeChecked = createListIncreasingIndices(1,listLength(DEVS_blocks_inVars),{});  
        blocksToBeChecked = Util.listRemoveNth(blocksToBeChecked, outBlockIndex); // If algebraic remove the current block from the input search.  
      then
        (blocksToBeChecked);
    case (_,_,_,_)
      equation
        print("- BackendQSS.findOutVarsInAllInputsHelper failed\n");
      then
        fail();
  end matchcontinue;
end findOutVarsInAllInputsHelper;


protected function findWhereOutVarIsNeeded
"function: findWhereOutVarIsNeeded
  For a current output variable checks in which blocks it is needed as input.
  author: florosx  
"
  input Integer curOutVar;
  input Integer outBlockIndex;
  input list<Integer> blocksToBeChecked;
  input list<list<Integer>> DEVS_blocks_inVars;
  input array<list<list<Integer>>> DEVS_struct_inLinks;
  input array<list<list<Integer>>> DEVS_struct_inVars;
  input list<Integer> curOutVarLinks;
  output list<Integer> outLinks;
  output array<list<list<Integer>>> DEVS_struct_inLinksOut;
  output array<list<list<Integer>>> DEVS_struct_inVarsOut;
  
 
algorithm
  (outLinks, DEVS_struct_inLinksOut, DEVS_struct_inVarsOut):=
  matchcontinue (curOutVar, outBlockIndex, blocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars,curOutVarLinks)
    local
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      Integer curOutVar, inBlockIndex;
      list<Integer> restOutVars, curBlock_inVars, restBlocksToBeChecked;
      list<list<Integer>> restBlocks_inVars, curOutBlock_outLinks, curOutBlock_outVars, curInBlock_inLinks, curInBlock_inVars;
      DevsStruct DEVS_structure_temp;   

    case (curOutVar, outBlockIndex, {}, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks)
      equation
      then
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars);
     
    case (curOutVar, outBlockIndex, inBlockIndex::restBlocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks)
      equation
        // If the current outVariable is NOT needed in the current In block
        curBlock_inVars = listNth(DEVS_blocks_inVars, inBlockIndex-1);
        false = Util.listContains(curOutVar, curBlock_inVars);
        /*print("\nCurBlock InVars : ");
        printList(curBlock_inVars, "start"); 
        print("\nNOT Found as input in block: ");
        print(intString(inBlockIndex));
        print("\n");
        print("restBlocksToBeChecked : ");
        printList(restBlocksToBeChecked, "start");
        print("\n");       
        */
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars) = 
           findWhereOutVarIsNeeded(curOutVar, outBlockIndex, restBlocksToBeChecked, DEVS_blocks_inVars,DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks);
      then
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars);

    case (curOutVar, outBlockIndex, inBlockIndex::restBlocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks)
      equation
        // If the current outVariable is needed in the current In block
        curBlock_inVars = listNth(DEVS_blocks_inVars, inBlockIndex-1);
        true = Util.listContains(curOutVar, curBlock_inVars);
        
        /*print("\nCurBlock InVars : ");
        printList(curBlock_inVars, "start");
        print("\nFound as input in block: ");
        print(intString(inBlockIndex));
        print("\n");
        print("restBlocksToBeChecked : ");
        printList(restBlocksToBeChecked, "start");
        print("\n");
        */
        curOutVarLinks = listAppend(curOutVarLinks, {inBlockIndex});
        
        curInBlock_inLinks = DEVS_struct_inLinks[inBlockIndex];
        curInBlock_inLinks = listAppend(curInBlock_inLinks, {{outBlockIndex}});        
        curInBlock_inVars = DEVS_struct_inVars[inBlockIndex];
        curInBlock_inVars = listAppend(curInBlock_inVars, {{curOutVar}});
        DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, inBlockIndex, curInBlock_inLinks);
        DEVS_struct_inVars = arrayUpdate(DEVS_struct_inVars, inBlockIndex, curInBlock_inVars);
        
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars) = 
           findWhereOutVarIsNeeded(curOutVar, outBlockIndex, restBlocksToBeChecked, DEVS_blocks_inVars,DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks);
      then
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars);
    case (_,_,_,_,_,_,_)
      equation
      then
        fail();
  end matchcontinue;
end findWhereOutVarIsNeeded;


protected function qssIntegratorsInOutVars
"function: qssIntegratorsInOutVars
  author: florosx
  generates the input/output variable names for the qss integrator blocks. 
"
  input list<Integer> stateIndices;
  input tuple<list<list<Integer>>,list<list<Integer>>> structsIn;
  output tuple<list<list<Integer>>,list<list<Integer>>> structsOut;
   
algorithm
  (structsOut):=
  matchcontinue (stateIndices, structsIn)
    local
      list<list<list<Integer>>> DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList;
      tuple< list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>> > DEVS_lists_temp;
      Integer cur_state_neg, cur_state;    
      list<Integer> rest_states;
      list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars;
      
    case ({},(DEVS_blocks_outVars, DEVS_blocks_inVars))
      equation       
      then
        ((DEVS_blocks_outVars, DEVS_blocks_inVars));
        
    case (cur_state::rest_states, (DEVS_blocks_outVars, DEVS_blocks_inVars))
      equation
        cur_state_neg = -cur_state;
        DEVS_blocks_outVars = listAppend(DEVS_blocks_outVars, {{cur_state_neg}});
        DEVS_blocks_inVars = listAppend(DEVS_blocks_inVars, {{cur_state}});
       
       ((DEVS_blocks_outVars, DEVS_blocks_inVars)) = qssIntegratorsInOutVars(rest_states, (DEVS_blocks_outVars, DEVS_blocks_inVars));
      then
        ((DEVS_blocks_outVars, DEVS_blocks_inVars));
    case (_,_)
      equation
        print("- BackendQSS.qssIntegratorsInOutVars failed\n");
      then
        fail();
  end matchcontinue;
end qssIntegratorsInOutVars;

protected function incidenceMatInOutVars
"function: incidenceMatInOutVars
  author: florosx
"
  input list<list<list<Integer>>> stateEq_blt;
  input BackendDAE.IncidenceMatrix incidenceMat;
  input array<Integer> ass2;
  input tuple<list<list<Integer>>,list<list<Integer>>> structsIn;
  output tuple<list<list<Integer>>,list<list<Integer>>> structsOut;
  
algorithm
  (structsOut):=
  matchcontinue (stateEq_blt, incidenceMat, ass2, structsIn)
    local
      list<Integer> curBlock_flatEq;
      list<list<Integer>> curBlock_eq; 
      list<list<list<Integer>>> restBlocks_eq, DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList;
      DevsStruct DEVS_structure_temp;
      
      list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars;
      list<Integer> varIndicesIn_temp, varIndicesOut_temp; 
      
    case ( {}, incidenceMat, ass2, structsIn)
      equation
        // end of recursion
      then
        (structsIn);
                  
    case (curBlock_eq::restBlocks_eq, incidenceMat, ass2, (DEVS_blocks_outVars, DEVS_blocks_inVars) )
      equation
        curBlock_flatEq = Util.listFlatten(curBlock_eq);            
        (varIndicesIn_temp, varIndicesOut_temp) = selectVarsInOut(curBlock_flatEq, incidenceMat, ass2, {},{});
        varIndicesIn_temp = findUniqueVars(varIndicesIn_temp,{});        
        DEVS_blocks_outVars = listAppend(DEVS_blocks_outVars, {varIndicesOut_temp}) "select OUT variables";
        DEVS_blocks_inVars = listAppend(DEVS_blocks_inVars, {varIndicesIn_temp}) "select IN variables";      
        ((DEVS_blocks_outVars, DEVS_blocks_inVars)) = incidenceMatInOutVars(restBlocks_eq, incidenceMat, ass2, (DEVS_blocks_outVars,DEVS_blocks_inVars));
      then
        ((DEVS_blocks_outVars, DEVS_blocks_inVars));
    case (_,_,_,_)
      equation
        print("- BackendQSS.incidenceMatInOutVars failed\n");
      then
        fail();
  end matchcontinue;
end incidenceMatInOutVars;

public function findUniqueVars
"function: findUniqueVars
  Finds unique variables in a list.
  author: florosx
"
  
  input list<Integer> inList1;
  input list<Integer> inList2;  
  output list<Integer> outList; 
  
algorithm
  (outList):=
  matchcontinue (inList1, inList2)
    local
      list<Integer> rest_list, inList_temp;
      Integer head;            
    case({} , inList_temp)
      equation
      then (inList_temp);
    
    case(head::rest_list, inList_temp)
      equation
        true = Util.listContains(head, rest_list);
        inList_temp = findUniqueVars(rest_list, inList_temp);
      then
         (inList_temp);
         
     case(head::rest_list, inList_temp)
      equation
        false = Util.listContains(head, rest_list);
        inList_temp = listAppend(inList_temp, {head});
        inList_temp = findUniqueVars(rest_list, inList_temp);
      then
         (inList_temp);        
    case (_,_)
      equation
        print("- BackendQSS.findUniqueVars\n");
      then
        fail(); 
  end matchcontinue;
end findUniqueVars;

protected function selectVarsInOut
"function: selectVarsInOut
  Function that selects output/input block variables based on the equations in the block.
  author: florosx
"
  input list<Integer> curBlock_flatEq;
  input BackendDAE.IncidenceMatrix incidenceMat;
  input array<Integer> ass2;
  input list<Integer> varIndicesIn_temp;
  input list<Integer> varIndicesOut_temp;
  output list<Integer> varIndicesIn;
  output list<Integer> varIndicesOut;
  
algorithm
  (varIndicesIn, varIndicesOut):=
  matchcontinue (curBlock_flatEq, incidenceMat, ass2, varIndicesIn_temp, varIndicesOut_temp)
    local     
      Integer curEq, curOutVar, ind;
      list<Integer> restEq, curInVars, curRow;      
    case ( {}, incidenceMat, ass2, varIndicesIn_temp, varIndicesOut_temp)
      equation
      then
        (varIndicesIn_temp, varIndicesOut_temp);         
    case (curEq::restEq, incidenceMat, ass2, varIndicesIn_temp, varIndicesOut_temp)
      equation      
        curRow = incidenceMat[curEq];     
        curOutVar = ass2[curEq];
        (ind, curInVars) = findAndRemoveElementInList(0,curRow,curOutVar);        
        varIndicesOut_temp = listAppend(varIndicesOut_temp, {curOutVar});        
        varIndicesIn_temp = listAppend(varIndicesIn_temp, curInVars);       
        (varIndicesOut_temp, varIndicesIn_temp) = selectVarsInOut(restEq, incidenceMat, ass2, varIndicesIn_temp, varIndicesOut_temp);        
      then
        (varIndicesOut_temp, varIndicesIn_temp);
    case (_,_,_,_,_)
      equation
        print("- BackendQSS.selectVarsInOut failed\n");
      then
        fail();
  end matchcontinue;
end selectVarsInOut;


////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - GENERATE CODE
////////////////////////////////////////////////////////////////////////////////////////////////////

public function replaceCondWhens
" author: fbergero
  merge when clauses depending on the same conditions"
  input list<SimCode.SimWhenClause> whenClauses;
  input list<SimCode.HelpVarInfo> helpVars;
  input list<BackendDAE.ZeroCrossing> zeroCrossings;
  output list<SimCode.SimWhenClause> replacedWhenClauses;
algorithm
  replacedWhenClauses := 
    match (whenClauses,helpVars,zeroCrossings)
    local
      list<SimCode.SimWhenClause> rest,r;
      SimCode.SimWhenClause clause;
      list<tuple<DAE.Exp, Integer>> cond; // condition, help var index
      list<DAE.ComponentRef> condVars;
      list<BackendDAE.WhenOperator> res;
      Option<BackendDAE.WhenEquation> whEq;
    case ({},helpVars,zeroCrossings) 
      then {};
    case ((SimCode.SIM_WHEN_CLAUSE(conditions=cond, conditionVars=condVars, reinits=res, whenEq=whEq)::rest),helpVars,zeroCrossings)
    equation
      r = replaceCondWhens(rest,helpVars,zeroCrossings);
      cond = replaceConds(cond,zeroCrossings);
      then (SimCode.SIM_WHEN_CLAUSE(condVars,res,whEq,cond)::r);
    end match;
end replaceCondWhens;

protected function replaceConds
  input list<tuple<DAE.Exp, Integer>> conditions; // condition, help var index
  input list<BackendDAE.ZeroCrossing> zeroCrossings;
  output list<tuple<DAE.Exp, Integer>> conditionsOut; // condition, help var index
algorithm
  conditionsOut :=
    match (conditions,zeroCrossings)
    local 
      list<tuple<DAE.Exp, Integer>> rest;
      tuple<DAE.Exp, Integer> cond;
    case ({},_) 
      then {};
    case (cond::rest,_)
    equation
      cond=replaceCond(cond,zeroCrossings);
      rest = replaceConds(rest,zeroCrossings);
      then (cond::rest);
    end match;
end replaceConds;

protected function replaceCond
  input tuple<DAE.Exp, Integer> cond;
  input list<BackendDAE.ZeroCrossing> zeroCrossings;
  output tuple<DAE.Exp, Integer> condOut;
algorithm
  condOut :=
    matchcontinue (cond,zeroCrossings)
    local
      Integer i,index;
      DAE.Exp e;
      tuple<DAE.Exp, Integer> result;
      list<DAE.Exp> zce;
      list<DAE.Exp> expLst,expLst2;
      Boolean tuple_ "tuple" ;
      Boolean builtin "builtin Function call" ;
      DAE.ExpType ty "The type of the return value, if several return values this is undefined";
      DAE.InlineType inlineType;
    case ((e as (DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst=expLst,tuple_=tuple_,builtin=builtin, ty=ty,inlineType=inlineType)),i),_) 
    equation
      zce = Util.listMap(zeroCrossings,extractExpresionFromZeroCrossing);
      // Remove extra argument to sample since in the zce list there is none
      expLst2 = Util.listFirst(Util.listPartition(expLst,2));
      e = DAE.CALL(Absyn.IDENT("sample"), expLst2,tuple_,builtin,ty,inlineType);
      index = listExpPos(zce,e,0);
      result = ((DAE.CALL(Absyn.IDENT("samplecondition"), {DAE.ICONST(index)}, false, true, DAE.ET_BOOL(), DAE.NO_INLINE()),i));
      then result;
    case ((e as DAE.RELATION(_,_,_,_,_),i),_) 
    equation
      zce = Util.listMap(zeroCrossings,extractExpresionFromZeroCrossing);
      index = listExpPos(zce,e,0);
      then ((DAE.CALL(Absyn.IDENT("condition"), {DAE.ICONST(index)}, false, true, DAE.ET_BOOL(), DAE.NO_INLINE()),i));
    case ((e as DAE.CREF(_,_),i),_)
      then ((e,i));
    case ((e as DAE.BCONST(_),i),_)
      then ((e,i));
    case ((e,_),_)
    equation
      print("Unhandle match in replaceCond\n");
      print(ExpressionDump.dumpExpStr(e,0));
      then ((DAE.ICONST(1),1));
    end matchcontinue;
end replaceCond;

protected function listExpPos
  input list<DAE.Exp> zce;
  input DAE.Exp e;
  input Integer i;
  output Integer o;
algorithm
  o := 
    matchcontinue (zce,e,i)
      local list<DAE.Exp> rest;
      DAE.Exp e1;
      case ((e1::rest),_,i)
      equation
        true = Expression.expEqual(e1,e);
        then i;
      case ((e1::rest),_,i)
        then listExpPos(rest,e,i+1);
      case ({},_,_) 
      equation
        print("Fail in listExpPos\n");
        then fail();
    end matchcontinue;
end listExpPos;

protected function extractExpresionFromZeroCrossing
"Takes a ZeroCrossing and returns the associated Expression
author:  FB"
  input BackendDAE.ZeroCrossing zc1;
  output DAE.Exp o;
algorithm
  o := 
    matchcontinue (zc1)
      local 
        DAE.Exp o1;
      case (BackendDAE.ZERO_CROSSING(relation_= o1)) 
        then o1;
    end matchcontinue;
end extractExpresionFromZeroCrossing;

protected function replaceZCStatement
  input list<DAE.Statement> inSt;
  input list<BackendDAE.ZeroCrossing> zc;
  output list<DAE.Statement> outSt;
algorithm
  outSt := 
    match (inSt,zc)
    local 
      DAE.Statement st;
      list<DAE.Statement> rest;
      DAE.ExpType type_;
      DAE.Exp exp1;
      DAE.Exp exp;
      list<DAE.Exp> zce;
      DAE.ElementSource source "the origin of the component/equation/algorithm";
    case ({},_)
      then {};
    case ((st as DAE.STMT_ASSIGN(type_=type_,exp1=exp1,exp=exp,source=source))::rest,zc)
    equation
      rest = replaceZCStatement(rest,zc);
      zce = Util.listMap(zc,extractExpresionFromZeroCrossing);
      exp = replaceCrossingLstOnExp(exp,zce,0);
      exp1 = replaceCrossingLstOnExp(exp1,zce,0);
      st = DAE.STMT_ASSIGN(type_,exp1,exp,source);
      then (st::rest);
    case ((st::rest),zc)
    equation
      rest = replaceZCStatement(rest,zc);
      then (st::rest);
    end match;
end replaceZCStatement;


public function replaceZC
  input SimCode.SimEqSystem i;
  input list<BackendDAE.ZeroCrossing> zc;
  output SimCode.SimEqSystem o;
algorithm
  o := matchcontinue (i,zc)
  local
    DAE.ComponentRef cref;
    DAE.Exp exp;
    list<DAE.Exp> zce;
    list<DAE.Statement> st;
    DAE.ElementSource source;
    Integer index;
    SimCode.SimEqSystem cont;
    list<SimCode.SimVar> discVars;
    list<SimCode.SimEqSystem> discEqs;
    list<Integer> values;
    list<Integer> value_dims;
  case (SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp,source=source),_)
  equation
    zce = Util.listMap(zc,extractExpresionFromZeroCrossing);
    exp = replaceCrossingLstOnExp(exp,zce,0);
    then (SimCode.SES_SIMPLE_ASSIGN(cref,exp,source));
  case (SimCode.SES_ALGORITHM(statements=st),_)
  equation
    st = replaceZCStatement(st,zc);
    then (SimCode.SES_ALGORITHM(st));
  case (SimCode.SES_MIXED(index=index,cont=cont,discVars=discVars,discEqs=discEqs,values=values,value_dims=value_dims),_)
  equation
    discEqs = Util.listMap1(discEqs,replaceZC,zc);
    then (SimCode.SES_MIXED(index,cont,discVars,discEqs,values,value_dims));
  case (_,_) 
    then i;
  end matchcontinue;
end replaceZC;

protected function replaceCrossExpHelper1
  "Helper function used to traverse  the expression replacing the zero crossings
  FB"
  input tuple<DAE.Exp, tuple<DAE.Exp,Integer>> inp;
  output tuple<DAE.Exp, tuple<DAE.Exp,Integer>> out;
algorithm
  out := matchcontinue inp
         local 
           DAE.Exp e;
           DAE.Exp zce;
           Integer index;
         case ((e,(zce,index)))
          equation
            true = Expression.expEqual(e , zce);
          then ((DAE.CALL(Absyn.IDENT("condition"), {DAE.ICONST(index)}, false, true, DAE.ET_BOOL(), DAE.NO_INLINE()), (zce,index)));
         case ((e,(zce,index)))
          equation
            then ((e,(zce,index)));
        end matchcontinue;
end replaceCrossExpHelper1;

protected function replaceExpOnEq
  "function replaceExpOnEq takse an Expresion eq and an zero corssing expression and
  traverses the expresion eq replacing zc for CROSSINGCONDITION(inp)
  FB"
  input DAE.Exp eq;
  input DAE.Exp zc;
  input Integer inp;
  output DAE.Exp eqout;
  DAE.Exp temp;
algorithm
  /*
  print("\nReplacing:\n\t");
  print(Exp.printExpStr(zc));
  print("\non:\n\t");
  print(Exp.printExpStr(eq));
  print("\nwith result:\n\t");
  */
  ((temp,_)) := Expression.traverseExp(eq,replaceCrossExpHelper1,(zc,inp));
  /*
  print(Exp.printExpStr(temp));
  print("\n");
  */
  ((eqout,_)) := Expression.traverseExp(eq,replaceCrossExpHelper1,(zc,inp));
end replaceExpOnEq;

protected function replaceCrossingLstOnExp
  "Replace all zero crossing conditions zce1 in equation exp1 for CROSSINGCONDITION(index1)
  FB"
  input DAE.Exp exp1;
  input list<DAE.Exp> zce1;
  input Integer index1;
  output DAE.Exp expOut;
  DAE.Exp e1,e2;
algorithm
  expOut := matchcontinue (exp1,zce1,index1)
            local DAE.Exp exp,e1;
                  list<DAE.Exp> rest,l1,l2;
                  Integer index;
             case (exp,{},_) then exp;
             case (exp,(e1 :: rest),index)
             equation
              exp = replaceExpOnEq(exp,e1,index);
              exp = replaceCrossingLstOnExp(exp,rest,index+1);
             then 
              exp;
  end matchcontinue;
end replaceCrossingLstOnExp;
 

////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - SELECTING EQUATIONS FOR EACH STATE VARIABLE (slight modifications from BackendDAEUtil
////////////////////////////////////////////////////////////////////////////////////////////////////

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
        arr_1 = arrayCreate(size, {});
        arr_1 = markStateEquations(dae, arr, arr_1, m, mt, ass1, ass2);
        arrList = arrayList(arr_1);
        arrList = sortEquationsBLT(arrList,comps,{});
        //The arrList includes also empty elements for the non-states - remove them
        arrList = removeEmptyElements(arrList,{});
      then
        (arrList);
    case (_,_,_,_,_,_)
      equation
        print("- BackendQSS.splitStateEqSet failed\n");
      then
        fail();
  end matchcontinue;
end splitStateEqSet;

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
      array<Integer> ass1,ass2;
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
   input String start;  
algorithm 
  _:=
  matchcontinue (arrList,start)     
    local 
      list<Integer> restList;
      Integer elem;
    case ({},"start")
      equation
        print("{ }");
    
      then();
    case (restList,"start")
      equation
        print("{");
        printList(restList,"continue");
      then();
    case ({elem},_)
      equation
        print(intString(elem));
        print("}");
      then();
    case (elem::restList,_)
      equation 
        //print(" ");      
        print(intString(elem));
        print(",");
        printList(restList,"continue");
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
    case ({elem})
      equation    
        printList(elem,"start");
        print("\n");
     then
       ();
    case (elem::restList)
      equation    
        printList(elem,"start");
        print("__");
        printListOfLists(restList);
     then
       ();
  end matchcontinue;
end printListOfLists;


public function dumpDEVSstructs 
"function: dumpDEVSstructs
  author: florosx
  Dumps all 4 DEVS structures: outLinks, outNames, inLinks, inNames
"
  input DevsStruct Devs_structure;

algorithm
  _ := matchcontinue (Devs_structure)
    local
      array<list<list<Integer>>> outLinks1, outVars1, inLinks1, inVars1;
    case (DEVS_STRUCT(outLinks=outLinks1, outVars=outVars1, inLinks=inLinks1, inVars=inVars1))
      equation
        print("---------- DEVS STRUCTURE ----------\n");
        print("DEVS structure Incidence Matrices (row == DEVS block)\n");
        dumpDEVSstruct(outLinks1, "OUT LINKS\n");
        dumpDEVSstruct(outVars1, "OUT VARNAMES\n");
        dumpDEVSstruct(inLinks1, "IN LINKS\n");
        dumpDEVSstruct(inVars1, "IN VARNAMES\n");
        print("---------- DEVS STRUCTURE ----------\n");
    then ();
  end matchcontinue;
end dumpDEVSstructs;

public function dumpDEVSstruct 
"function: Based on DAELow.dumpIncidenceMatrix
  author: florosx
  Dumps the incidence matrix for a DEVS structure
"
  input array<list<list<Integer>>> m;
  input String text;
  list<list<list<Integer>>> m_1;
algorithm
  print("====================================\n");
  print(text);
  m_1 := arrayList(m);
  dumpDEVSstruct2(m_1,1);
end dumpDEVSstruct;

protected function dumpDEVSstruct2 
"function: dumpMyDEVSstruct2
  author: florosx
  Helper function for dympMyDEVSstruct
"
  input list<list<list<Integer>>> inList;
  input Integer rowIndex;
algorithm
  _ := matchcontinue (inList,rowIndex)
    local
      list<list<Integer>> row;
      list<list<list<Integer>>> rows;
    case ({},_) then ();
    case ((row :: rows),rowIndex)
      equation
        print("Block #");
        print(intString(rowIndex));print(":");
        //dumpIncidenceRow(row);
        printListOfLists(row);
        dumpDEVSstruct2(rows,rowIndex+1);
      then
        ();
  end matchcontinue;
end dumpDEVSstruct2;

protected function dumpIncidenceRow 
"function: dumpIncidenceRow
  author: florosx
  Helper function for dympMyDEVSstruct
"
  input list<list<Integer>> inList;
algorithm
  _ := matchcontinue (inList)
    local
      String s;
      list<Integer> x;
      list<list<Integer>> xs;
    case ({})
      equation
        print("\n");
      then
        ();
    case ((x :: xs))
      equation
        printList(x,"start");
        print("__");
        dumpIncidenceRow(xs);
      then
        ();
  end matchcontinue;
end dumpIncidenceRow;

public function makeListNegative 
"function: dump
  This function dumps the DAELow representaton to stdout."
  input list<Integer> listIn1;
  input list<Integer> listIn2;
  output list<Integer> listOut;
algorithm
  listOut:=
  matchcontinue (listIn1, listIn2)
    local
      list<Integer> curList, rest_list;
      Integer cur_el;
    case ({}, curList)
      equation     
      then 
        (curList);
    case (cur_el::rest_list, curList)
      equation
        true = cur_el > 0;
        cur_el = -cur_el;
        curList = listAppend(curList, {cur_el});
        curList = makeListNegative(rest_list, curList);
      then
        (curList);
    case (cur_el::rest_list, curList)
      equation
        true = cur_el < 0;
        curList = listAppend(curList, {cur_el});
        curList = makeListNegative(rest_list, curList);
      then
        (curList);
   end matchcontinue;
end makeListNegative;

public function findElementInList
"function: 
  author: XF
"
  input Integer loopIndex1;
  input Integer nElements;
  input list<Integer> inList1;
  input Integer element1;
  
  output Integer indexFound;
  
algorithm
  (indexFound):=
  matchcontinue (loopIndex1, nElements, inList1, element1)
    local
      list<Integer> inList_temp, rest_list;
      Integer cur_elem, temp, element, loopIndex;
      
    case(loopIndex, nElements, cur_elem::rest_list , element)
      equation
        true = cur_elem == element;
        // END OF RECURSION
      then (loopIndex);
    case(loopIndex, 0, {} , element)
      equation
        // IF ELEMENT NOT FOUND RETURN -1
      then (-1);
        
     case(loopIndex, nElements, cur_elem::rest_list , element)
      equation
        temp = findElementInList(loopIndex+1, nElements-1, rest_list, element);
      then
         (temp);
  end matchcontinue;
end findElementInList;

public function findAndRemoveElementInList
"function: 
  author: XF
"
  input Integer loopIndex1;
  input list<Integer> inList1;
  input Integer element1;
  
  output Integer indexFound;
  output list<Integer> outList;
  
algorithm
  (indexFound, outList):=
  matchcontinue (loopIndex1, inList1, element1)
    local
      list<Integer> rest_list, tempList;
      Integer cur_elem, temp, element, loopIndex;
    
    case(loopIndex, {}, element)
      equation
      then (-1, {});
          
    case(loopIndex, cur_elem::rest_list , element)
      equation
        true = intEq(cur_elem,element);
      then (loopIndex, rest_list);
        
     case(loopIndex, cur_elem::rest_list , element)
      equation
        false = intEq(cur_elem,element);
        (temp, tempList) = findAndRemoveElementInList(loopIndex+1, rest_list, element);
      then
         (temp, cur_elem::tempList);
  end matchcontinue;
end findAndRemoveElementInList;

public function getAllVars
"function: getAllVars 
 outputs a list with all variables and the subset of state variables contained in DAELow
 author: XF
"
  input BackendDAE.BackendDAE inDAELow1;
  output list<BackendDAE.Var> allVarsList; 
  output list<BackendDAE.Var> stateVarsList; 
   
algorithm 
  (allVarsList, stateVarsList):=
  matchcontinue (inDAELow1)
    local
      list<BackendDAE.Var> orderedVarsList, knownVarsList, allVarsList;
      BackendDAE.BackendDAE dae;
      array<BackendDAE.Value> arr_1,arr;
      array<list<BackendDAE.Value>> m,mt;
      array<BackendDAE.Value> a1,a2;
      BackendDAE.Variables v,kn;
      BackendDAE.EquationArray e,se,ie;
      array<BackendDAE.MultiDimEquation> ae;
      array<DAE.Algorithm> alg;
  case (dae as BackendDAE.DAE(orderedVars = v,knownVars = kn,orderedEqs = e,removedEqs = se,initialEqs = ie,arrayEqs = ae,algorithms = alg))
    equation
      orderedVarsList = BackendDAEUtil.varList(v);
      knownVarsList = BackendDAEUtil.varList(kn);
      allVarsList = listAppend(orderedVarsList, knownVarsList);
      stateVarsList = BackendVariable.getAllStateVarFromVariables(v);
  then
     (allVarsList, stateVarsList) ;
  end matchcontinue;     
end getAllVars;

public function getStateIndices 
"function: getStateIndices 
 finds the indices of the state indices inside a list with variables.
 author: XF
"

  input list<BackendDAE.Var> allVars;
  input list<Integer> stateIndices1;
  input Integer loopIndex1;
  
  output list<Integer> stateIndices;

algorithm
  stateIndices:=
  matchcontinue (allVars, stateIndices1, loopIndex1)
    local
      
      list<Integer> stateIndices2;
      Integer loopIndex;
      list<BackendDAE.Var> rest;
      BackendDAE.Var var1; 
    
    case ({}, stateIndices2, loopIndex)
      equation             
      then
        stateIndices2;
        
    case (var1::rest, stateIndices2, loopIndex)
      equation     
        false = BackendVariable.isStateVar(var1);
        stateIndices = getStateIndices(rest, stateIndices2, loopIndex+1);  
      then
        stateIndices;
    case (var1::rest, stateIndices2, loopIndex)
      equation     
        true = BackendVariable.isStateVar(var1);
        stateIndices2 = listAppend(stateIndices2, {loopIndex});
        stateIndices2 = getStateIndices(rest, stateIndices2, loopIndex+1);  
      then
        stateIndices2;
  end matchcontinue;
end getStateIndices;

public function removeRedundantElements
"function: removeRedundantElements removes redundant elements from a list
  author: XF
"
  
  input list<Integer> inList1;
  input list<Integer> inList2;
  
  output list<Integer> outList; 
  
algorithm
  (outList):=
  matchcontinue (inList1, inList2)
    local
      list<Integer> inList_temp, rest_list;
      Integer head;
      
    case({} , inList_temp)
      equation
        // END OF RECURSION
      then (inList_temp);
      
     case(head::rest_list, inList_temp)
      equation
        true = Util.listContains(head, rest_list);
        inList_temp = removeRedundantElements(rest_list, inList_temp);
      then
         (inList_temp);
     
     case(head::rest_list, inList_temp)
      equation
        false = Util.listContains(head, rest_list);
        inList_temp = listAppend(inList_temp, {head});
        inList_temp = removeRedundantElements(rest_list, inList_temp);
      then
         (inList_temp);
  
  end matchcontinue;
end removeRedundantElements;

public function createListIncreasingIndices
"function: removeRedundantElements removes redundant elements from a list
  author: XF
"
  
  input Integer indexStart;
  input Integer indexEnd;
  input list<Integer> inList1;
  output list<Integer> outList; 
  
algorithm
  (outList):=
  matchcontinue (indexStart, indexEnd, inList1)
    local
      list<Integer> inList_temp, rest_list;
      Integer head;
      
    case(indexStart , indexEnd, inList_temp)
      equation
        true = indexStart > indexEnd;
        // END OF RECURSION
      then (inList_temp);
      
     case(indexStart, indexEnd, inList_temp)
      equation
        inList_temp = listAppend(inList_temp, {indexStart});
        inList_temp = createListIncreasingIndices(indexStart+1, indexEnd, inList_temp);
      then
         (inList_temp);
  end matchcontinue;

end createListIncreasingIndices;

public function constructTrivialList 
"function: constructTrivialList constructs a list of a given size with repetitions of element
  author: XF
"
  input list<Integer> tempList1;
  input Integer element1;
  input Integer nEquations1; 
  
  output list<Integer> emptyListofLists; 
  
algorithm
  (emptyListofLists):=
  matchcontinue(tempList1, element1, nEquations1)
     local
       Integer nEquations, element;
       list<Integer> tempList;
              
       case(tempList, element, 0)
         equation
           //END OF RECURSION
       then (tempList);
        
       case (tempList, element, nEquations)
         equation

            tempList = listAppend(tempList, {element});           
            emptyListofLists = constructTrivialList(tempList, element, nEquations-1);
         then
            (emptyListofLists);  
  end matchcontinue;
end constructTrivialList;


////////////////////////////////////////////////////////////////////////////////////////////////////
/////  EQUATION GENERATION 
////////////////////////////////////////////////////////////////////////////////////////////////////

protected function generateEqFromBlt
  input list<list<Integer>> blt;
  input BackendDAE.BackendDAE dlow;
  input array<Integer> ass1, ass2;
  output list<SimCode.SimEqSystem> out;
algorithm
  out := 
    match (blt,dlow,ass1,ass2)
      local
        list<SimCode.SimEqSystem> out2;
      case (_,_,_,_)
      equation
        out2 = SimCode.createEquations(false, false, false, false, false, dlow, ass1, ass2, blt, {});
        then out2;
    end match;
end generateEqFromBlt;

protected function isPositive
  input Integer i;
algorithm
  _ := 
    match i
      local 
      case _
        equation
          true = i > 0;
          then ();
      case _
        then fail();
    end match;
end isPositive;

public function getInputs
  input DevsStruct st;
  input Integer index;
  output list<Integer> vars;
algorithm
  vars :=
    match (st,index)
      local
        array<list<list<Integer>>> inVars "input variables for each DEVS block";
        list<Integer> vars; 
      case (DEVS_STRUCT(inVars=inVars),_)
      equation
        vars = Util.listMap(Util.listFlatten(inVars[index]),intAbs);
        vars = Util.listFilter(vars,isPositive);
        then vars;
    end match;
end getInputs;

public function getOutputs
  input DevsStruct st;
  input Integer index;
  output list<Integer> vars;
algorithm
  vars := 
    match (st,index)
     local
       array<list<list<Integer>>> outVars "output variables for each DEVS block";
       list<Integer> vars; 
     case (DEVS_STRUCT(outVars=outVars),_)
     equation
        vars = Util.listMap(Util.listFlatten(outVars[index]),intAbs);
        then vars;
    end match;
end getOutputs;

public function derPrefix
  input BackendDAE.Var var;
  output String prefix;
algorithm
  prefix :=
    matchcontinue (var)
      case (_)
      equation
        true = BackendVariable.isStateVar(var);
        then "$P$DER";
      case (_)
        then "";
  end matchcontinue;
end derPrefix;

public function numInputs
  input QSSinfo qssInfo;
  input Integer numBlock;
  output Integer inputs;
algorithm
  inputs := 
    matchcontinue (qssInfo,numBlock)
    local
      array<list<list<Integer>>> inLinks "input connections for each DEVS block";
      list<Integer> l;
    case (QSSINFO(DEVSstructure=DEVS_STRUCT(inLinks=inLinks)),_)
    equation 
      l = (Util.listFlatten(inLinks[numBlock]));
      _ = Util.listGetMember(0,l);
      then listLength(l);
    case (QSSINFO(DEVSstructure=DEVS_STRUCT(inLinks=inLinks)),_)
    equation 
      l = (Util.listFlatten(inLinks[numBlock]));
      then listLength(l)+1;
    end matchcontinue;
end numInputs;

public function numOutputs
  input QSSinfo qssInfo;
  input Integer numBlock;
  output Integer outputs;
algorithm
  outputs := 
    match (qssInfo,numBlock)
      local
        array<list<list<Integer>>> outLinks "output connections for each DEVS block";
      case (QSSINFO(DEVSstructure=DEVS_STRUCT(outLinks=outLinks)),_)
        then listLength(outLinks[numBlock]);
    end match;
end numOutputs;

public  function getStates
  input QSSinfo qssInfo;
  output list<BackendDAE.Var> states;
algorithm
  states := 
    match qssInfo
      local
        list<BackendDAE.Var> outVarLst;
      case QSSINFO(outVarLst=outVarLst)
      then Util.listFilterBoolean(outVarLst,BackendVariable.isStateVar);
    end match;
end getStates;

public  function generateConnections
  input QSSinfo qssInfo;
  output list<list<Integer>> conns;
algorithm
  conns := 
    match (qssInfo)
      local        
        array<list<list<Integer>>> outLinks, outVars, inLinks, inVars;
        Integer nBlocks;
        
      case (QSSINFO(DEVSstructure=DEVS_STRUCT(outLinks=outLinks, outVars=outVars, inLinks=inLinks, inVars = inVars)))
        equation 
          nBlocks = arrayLength(outLinks);
          conns = generateConnections2((outLinks, outVars, inLinks, inVars), 1, nBlocks, {});  
        then conns; 
      case (_)
        equation
         print("- BackendQSS.generateConnections\n");
       then
         fail();
    end match;
end generateConnections;

public  function generateConnections2
  input tuple< array<list<list<Integer>>>, array<list<list<Integer>>>, array<list<list<Integer>>>, array<list<list<Integer>>> > DEVSstructureMatsIn; 
  input Integer blockIndex;
  input Integer nBlocks;
  input list<list<Integer>> conns_temp;
  output list<list<Integer>> connsOut;
algorithm
  connsOut := 
    match (DEVSstructureMatsIn, blockIndex, nBlocks, conns_temp)
      local        
        array<list<list<Integer>>> outLinks, outVars, inLinks, inVars;
        list<list<Integer>> curBlock_conns, curBlock_outEdges, curBlock_outVars;
        
      case (_, _, 0, conns_temp)
        equation 
        then conns_temp;
      // Find the out-connections for the current block indexed by blockIndex    
      case ((outLinks, outVars, inLinks, inVars), blockIndex, nBlocks, conns_temp)
        equation          
          curBlock_outEdges = arrayGet(outLinks, blockIndex);
          curBlock_outVars = arrayGet(outVars, blockIndex);        
          curBlock_conns =  getDEVSblock_conns(blockIndex, curBlock_outEdges, curBlock_outVars, inVars, 1, {});
          conns_temp = listAppend(conns_temp, curBlock_conns);
          conns_temp = generateConnections2((outLinks, outVars, inLinks, inVars), blockIndex+1, nBlocks-1, conns_temp);            
        then conns_temp;
      case (_,_,_,_)
        equation
         print("- BackendQSS.generateConnections2\n");
       then
         fail();
      case (_,_,_,_)
        equation
          print("Fail in generateConnections2\n");
          then
            fail();
    end match;
end generateConnections2;

protected function getDEVSblock_conns
"function: getDEVSblock_conns is a helper function for generateConnections
 which produces the outgoing edges given in row of a specific block indexed by blockIndex
  author: XF
"
  input Integer blockIndex; 
  input list<list<Integer>> curBlock_outEdges;
  input list<list<Integer>> curBlock_outVars;
  input array<list<list<Integer>>> inVars;
  input Integer loopIndex;
  input list<list<Integer>> curBlock_conns_temp;
  output list<list<Integer>> curBlock_conns_out;
  
algorithm
  (curBlock_conns_out):=
  matchcontinue (blockIndex, curBlock_outEdges, curBlock_outVars, inVars, loopIndex, curBlock_conns_temp)
    local 
      Integer blockOut, portOut, curOutVar;
      list<Integer> cur_out_edges, cur_out_names, in_edges, blocksIn;
      list<list<Integer>> rest_out_edges, rest_out_names, curOutVarConnections;
            
    case(blockIndex, {}, {}, inVars, loopIndex, curBlock_conns_temp)
      equation
      then (curBlock_conns_temp);
      
    case (blockIndex, cur_out_edges::rest_out_edges, cur_out_names::rest_out_names, inVars, loopIndex, curBlock_conns_temp)
      equation
        blockOut =  blockIndex-1 "Current block index"; 
        portOut = loopIndex-1 "Current output port index"; 
        curOutVar = listNth(cur_out_names,0);
        blocksIn = cur_out_edges;
        curOutVarConnections = getDEVSblock_conns2(curOutVar, blockOut, portOut, blocksIn, inVars, {});      
        curBlock_conns_temp = listAppend(curBlock_conns_temp, curOutVarConnections);
        curBlock_conns_temp = getDEVSblock_conns(blockIndex, rest_out_edges, rest_out_names, inVars, loopIndex+1, curBlock_conns_temp);
      then
        (curBlock_conns_temp);
     
      case (_,_,_,_,_,_)
        equation
         print("- BackendQSS.getDEVSblock_conns failed\n");
       then
         fail();
  end matchcontinue;
end getDEVSblock_conns;

protected function getDEVSblock_conns2
"function: getDEVSblock_conns
 and produces the outgoing edges given in row of a specific block indexed by blockIndex
  author: XF
" 
  input Integer curOutVar; 
  input Integer blockOut; 
  input Integer portOut;
  input list<Integer> blocksIn;
  input array<list<list<Integer>>> inVars;
  input list<list<Integer>> curOutVar_conns_temp;
  output list<list<Integer>> curOutVar_conns_out; 
  
algorithm
  (curOutVar_conns_out):=
  matchcontinue (curOutVar, blockOut, portOut, blocksIn, inVars, curOutVar_conns_temp)
    local     
      Integer portIn, curBlockIn;       
      array<Integer> row;
      list<Integer> out_edges, out_edges_names, restOutVars,restBlocksIn, unique_inputNames, inNames;
      Integer curOutVar, nInputs;
      list<list<Integer>> column;
    
    // If the current output variable is an EVENT (0)
    //case(0, _, _, _, _, curOutVar_conns_temp)
    //  equation
    //  then (curOutVar_conns_temp);
            
    case(curOutVar, blockOut, portOut, {}, inVars, curOutVar_conns_temp)
      equation
      then (curOutVar_conns_temp);
              
    case (curOutVar, blockOut, portOut, curBlockIn::restBlocksIn, inVars, curOutVar_conns_temp)
      equation
        // Find in which port curOutVar is inputed in the current blockIn
        column = arrayGet(inVars, curBlockIn);
        portIn = findInputPort(0, column, curOutVar);
        curBlockIn = curBlockIn - 1;
        curOutVar_conns_temp = listAppend(curOutVar_conns_temp, {{blockOut, portOut, curBlockIn, portIn}});      
        curOutVar_conns_temp = getDEVSblock_conns2(curOutVar, blockOut, portOut, restBlocksIn, inVars, curOutVar_conns_temp);
      then
        (curOutVar_conns_temp);
     
    case (_,_,_,_,_,_)
      equation
        print("- BackendQSS.getDEVSblock_conns2 failed\n");
      then
        fail();
  end matchcontinue;
end getDEVSblock_conns2;

protected function findInputPort
"function: findInputPort takes as input a list of lists with input variables and looks
 for a specific one in order to identify the input port.
  author: XF
" 
  input Integer loopIndex;
  input list<list<Integer>> inputsRow; 
  input Integer inVar; 
  
  output Integer portIn; 
  
algorithm
  (portIn):=
  matchcontinue (loopIndex, inputsRow, inVar)
    local
      list<Integer> cur_port_inputs;
      list<list<Integer>> rest_inputs;
    
    // IF you don't find the inVar return -1 by default
    case(loopIndex, {}, inVar)
      equation 
      then (-1);
    
    case(loopIndex, cur_port_inputs::rest_inputs, inVar)
      equation
       true = Util.listContains(inVar, cur_port_inputs); 
      then (loopIndex);
    
    case(loopIndex, cur_port_inputs::rest_inputs, inVar)
      equation
       false = Util.listContains(inVar, cur_port_inputs); 
       portIn = findInputPort(loopIndex+1, rest_inputs, inVar);
      then (portIn);
    case (_,_,_)
      equation
        print("- BackendQSS.findInputPort failed\n");
      then
        fail();
  end matchcontinue;
end findInputPort;

protected function mapStateEquationsInDEVSblocks
"function: mapEquationInDEVSblocks is the function that maps the equation indices in dlow into the corresponding
           DEVS blocks that contain them.
  author: XF
  date: 25-6-2010 
" 
  input list<list<list<Integer>>> state_DEVSblocks1;
  input list<list<Integer>> mappedEquations1;
  input Integer blockIndex1;
  
  output list<list<Integer>> mappedEquations; 
  
algorithm
  (mappedEquations):=
  matchcontinue(state_DEVSblocks1, mappedEquations1, blockIndex1)
     local
       
       list<list<Integer>> cur_state_blocks;
       list<list<list<Integer>>> rest_blocks;
       list<Integer> cur_state_flat;
       list<list<Integer>> mappedEquations_intermed;
       Integer blockIndex;
       
       case({}, mappedEquations_intermed, blockIndex)
         equation
           //END OF RECURSION
       then (mappedEquations_intermed);
        
       case (cur_state_blocks :: rest_blocks, mappedEquations_intermed, blockIndex)
         equation
            cur_state_flat = Util.listFlatten(cur_state_blocks);
            mappedEquations_intermed = mapEquationInDEVSblocks1(mappedEquations_intermed, cur_state_flat, blockIndex);
            mappedEquations = mapStateEquationsInDEVSblocks(rest_blocks, mappedEquations_intermed, blockIndex+1);
         then
            (mappedEquations);  
  end matchcontinue;
end mapStateEquationsInDEVSblocks;


protected function mapEquationInDEVSblocks1 
"function: Helper function for mapEquationInDEVSblocks
  author: XF
  date: 25-6-2010
"
  input  list<list<Integer>> mappedEquations1;
  input list<Integer> cur_state_flat1;
  input Integer blockIndex1;
  
  output  list<list<Integer>> mappedEquations; 
  
algorithm
  (mappedEquations):=
  matchcontinue(mappedEquations1, cur_state_flat1, blockIndex1)
     local
       
       
       list<list<Integer>> mappedEquations_intermed;
       Integer cur_eq, blockIndex;
       list<Integer> rest_eq, temp_list;      
       
       case(mappedEquations_intermed, {}, blockIndex)
         equation
           //END OF RECURSION
       then (mappedEquations_intermed);
        
       case (mappedEquations_intermed, cur_eq :: rest_eq , blockIndex)
         equation
            temp_list = listNth(mappedEquations_intermed, cur_eq-1);
            temp_list = listAppend(temp_list,{blockIndex});
            mappedEquations_intermed = Util.listReplaceAt(temp_list, cur_eq-1, mappedEquations_intermed); 
            mappedEquations = mapEquationInDEVSblocks1(mappedEquations_intermed, rest_eq, blockIndex);
         then
            (mappedEquations);  
  end matchcontinue;
end mapEquationInDEVSblocks1;

public function constructEmptyList 
"function: generateSwitchBlocks for the quantum_values function
  author: XF
"
  input list<list<Integer>> tempList1;
  input Integer nEquations1; 
  
  output list<list<Integer>> emptyListofLists; 
  
algorithm
  (emptyListofLists):=
  matchcontinue(tempList1, nEquations1)
     local
       Integer nEquations;
       list<list<Integer>> tempList;
              
       case(tempList, 0)
         equation
           //END OF RECURSION
       then (tempList);
        
       case (tempList, nEquations)
         equation

            tempList = listAppend(tempList, {{}});           
            emptyListofLists = constructEmptyList(tempList, nEquations-1);
         then
            (emptyListofLists);  
  end matchcontinue;
end constructEmptyList;

public function filterDiscreteVars "Removes the discrete vars from the list
  author: FB"
  input list<Integer> list1;
  input BackendDAE.Variables vars1;
  output list<Integer> listOut;
algorithm
  listOut := matchcontinue (list1,vars1)
             local 
             list<Integer> listVar;
             Integer v;
             list<BackendDAE.Var> varsList;
             BackendDAE.Variables vars;
             case ({},_) then {};
             case ((v::listVar),vars) 
             equation
                varsList = BackendDAEUtil.varList(vars);
                true = BackendVariable.isVarDiscrete(listNth(varsList,v-1));
                listVar = filterDiscreteVars(listVar,vars);
             then listVar;
             case ((v::listVar),vars) 
             equation
                varsList = BackendDAEUtil.varList(vars);
                false = BackendVariable.isVarDiscrete(listNth(varsList,v-1));
                listVar = listAppend({v} ,filterDiscreteVars(listVar,vars));
             then listVar;
             end matchcontinue;
end filterDiscreteVars;

public function removeListFromListsOfLists 
  input list<Integer> toRemove1;
  input list<list<Integer>> inList1;
  input list<list<Integer>> outList1;
  output list<list<Integer>> outList;
algorithm
  outList := matchcontinue(toRemove1, inList1, outList1)
    local
      list<Integer> toRemove, head,temp;
      list<list<Integer>> rest, outListTemp;
      list<Integer> wcEqns;
    
    case (_, {}, outListTemp)
      equation
      then outListTemp;

    case (toRemove, head::rest, outListTemp)
      equation
        temp = Util.listSetDifferenceOnTrue(head,toRemove,intEq);
        outListTemp = listAppend(outListTemp, {temp});
        outListTemp = removeListFromListsOfLists(toRemove, rest, outListTemp);
      then outListTemp;
  end matchcontinue;
end removeListFromListsOfLists;

public function createListFromElement
  input Type_a elem;
  output list<Type_a> outList;
  replaceable type Type_a subtypeof Any;
  
algorithm
  outList := 
  matchcontinue(elem)
    local
    case (elem)
      equation
      then ({elem});
  end matchcontinue;
end createListFromElement;


////////////////////////////////////////////////////////////////////////////////////////////////////
/////  END OF PACKAGE
////////////////////////////////////////////////////////////////////////////////////////////////////
end BackendQSS;

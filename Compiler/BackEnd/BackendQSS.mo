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
  authors: florosx, fbergero

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
protected import BackendDAETransform;
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
    list<Integer> zcSamplesInd;
  end QSSINFO;
end QSSinfo;

public function generateStructureCodeQSS 
  input BackendDAE.BackendDAE inBackendDAE;
  input array<Integer> equationIndices;
  input array<Integer> variableIndices;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  input BackendDAE.StrongComponents strongComponents;
  
  output QSSinfo QSSinfo_out;
algorithm
  QSSinfo_out :=
  matchcontinue (inBackendDAE, equationIndices, variableIndices, inIncidenceMatrix, inIncidenceMatrixT, strongComponents)
    local
       QSSinfo qssInfo;
       BackendDAE.BackendDAE dlow;
       array<Integer> ass1, ass2, globalAss2;
       
       list<BackendDAE.Var> allVarsList, stateVarsList;
       BackendDAE.Variables orderedVars;
       list<BackendDAE.Var> varlst;
       BackendDAE.IncidenceMatrix m, mt, globalIncidenceMat, zeroCrossIncidenceMat, whenReinitIncidenceMat, whenEqIncidenceMat;
       list<BackendDAE.ZeroCrossing> zeroCrossList, samplesList; 
       list<BackendDAE.WhenClause> whenClausesList;
       list<list<SimCode.SimEqSystem>> eqs;
       
       Integer nStatic, nIntegr, nBlocks, nZeroCross, nCrossDetect, nEquations, nWhens, ind_whenBlocks_start, nReinits, nSamples;
       list<Integer> whenEqClausesInd, whenReinitClausesInd, whenEqInd, reinitVarsOut, varsSolvedInEqsList, whenClausesInBlocks, tempIndList;       
       list<Integer> variableIndicesList,ass1List, ass2List, stateVarIndices, discreteVarIndices, zcSamplesInd, reinitsInBlocks;
       list<Integer> nBlocksList;
       BackendDAE.StrongComponents comps,blt_states,blt_no_states;
       list<list<Integer>> stateEq_flat, globalIncidenceList, mappedEquations, whenEqIncidenceMatList; 
       list<list<Integer>> whenReinitIncidenceMatList, mappedEqReinitMatList, reinitVarsIn;
       list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars, zc_inVars, conns, whenEq_flat, tempListList, whenClausesBlocks;
       list<list<Integer>> when_blocks_outVars, when_blocks_inVars, reinit_blocks_outVars, reinit_blocks_inVars;
       list<list<list<Integer>>> stateEq_blt, whenEq_blt, whenEqInBlocks;
       list<BackendDAE.StrongComponents> stateEq_bltX,whenEq_bltX;
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
        
        // -------------------------------------------------------------------------
        // STEP 0            
        // Generate various Info and Structures needed in the following steps     
        
        (allVarsList, stateVarsList) = getAllVars(dlow);
        stateVarIndices = getStateIndices(allVarsList, {}, 1); 
        discreteVarIndices = getDiscreteIndices(allVarsList, {}, 1);
        variableIndicesList = arrayList(ass2);
        
        varsSolvedInEqsList = arrayList(ass2);
        
        orderedVars = BackendVariable.daeVars(dlow);
        varlst = BackendDAEUtil.varList(orderedVars);
        
        // ZERO-CROSSES
        (zeroCrossList, zc_inVars, samplesList, zcSamplesInd) = getListofZeroCrossings(dlow);
        
        // WHEN-CLAUSES, EQUATIONS AND REINITS
        (whenClausesList, whenEqClausesInd, whenEqInd, whenEqIncidenceMatList) = getWhenEqClausesInfo(dlow);
        (whenReinitClausesInd, reinitVarsIn, reinitVarsOut) = getReinitInfo(0, whenClausesList , orderedVars, {}, {}, {});
        
        // CHECK getWhenEqClausesInfo 3 and 4
        
        // -------------------------------------------------------------------------
        // STEP 1      
        // EXTRACT THE INDICES OF NEEDED EQUATIONS FOR EACH STATE VARIABLE         
        
        (blt_states, blt_no_states) = BackendDAEUtil.generateStatePartition(comps, dlow, ass1, ass2, m, mt);                 
        stateEq_flat = splitStateEqSet(comps, dlow, ass1, ass2, m, mt) "Extract equations for each state derivative";
        stateEq_flat = removeEmptyElements(stateEq_flat, {}) "extract possible empty elements in the list";
        
        // Remove the equations that correspond to when-clauses from the STATE static blocks.
        stateEq_flat = removeListFromListsOfLists(whenEqInd, stateEq_flat, {});
        
        // Provide the equations in the When-Blocks.
        // Note: Currently we are having one when-block for each when-clause. But in the future we "ll group them.
        whenEq_flat = Util.listMap(whenEqInd, createListFromElement);
        
        // -------------------------------------------------------------------------
        // STEP 2      
        // MAP STATE EQUATIONS BACK TO BLT BLOCKS        
        
        stateEq_bltX = Util.listMap2(stateEq_flat, mapEquationsInBLTBlocks_tail, blt_states, {}) "Map state equations back in BLT blocks";
        whenEq_bltX = Util.listMap2(whenEq_flat, mapEquationsInBLTBlocks_tail, blt_states, {}) "Map when equations back in BLT blocks";
        stateEq_blt = Util.listListMap(stateEq_bltX,getEqnIndxFromComp);
        
        // More info, variables and parameters
        eqs = Util.listMap3(stateEq_bltX, generateEqFromBlt,dlow,ass1,ass2);
        nEquations = arrayLength(m);
        nStatic = listLength(stateEq_blt);
        nIntegr = listLength(stateVarIndices);
        nZeroCross = listLength(zeroCrossList);
        nCrossDetect = nZeroCross;
       
        // -------------------------------------------------------------------------
        // STEP 3      
        // MAP WHEN-CLAUSES TO WHEN-BLOCKS        
 
        // Right now we generate a when DEVS block for each when-clause. The following list contains the indices of the
        // blocks where each clause is contained. - TO BE CHANGED IN THE FUTURE
        whenEqInBlocks = Util.listMap(Util.listMap(whenEqInd, createListFromElement), createListFromElement);
        whenClausesInBlocks = whenEqClausesInd; 
        reinitsInBlocks = whenReinitClausesInd;
        whenClausesInBlocks = Util.listMap1(whenClausesInBlocks, intAdd, nStatic+nIntegr+2*nZeroCross+1);
        reinitsInBlocks = Util.listMap1(reinitsInBlocks, intAdd, nStatic+nIntegr+2*nZeroCross+1);
        
        nWhens = listLength(whenClausesInBlocks);
        nReinits = listLength(reinitsInBlocks);
        nSamples = listLength(samplesList);
        nBlocks = nStatic + nIntegr + nZeroCross + nCrossDetect + nWhens + nReinits + nSamples;     
        nBlocksList = {nBlocks, nStatic, nIntegr, nZeroCross, nCrossDetect, nWhens, nReinits, nSamples};
        
        // -------------------------------------------------------------------------
        // STEP 4      
        // MAP EQUATIONS TO DEVS BLOCKS        
 
        
        // Map equations to DEVS blocks
        mappedEquations = constructEmptyList(nEquations, {});
        mappedEquations = mapStateEquationsInDEVSblocks(stateEq_bltX, mappedEquations, nIntegr+1);
        mappedEquationsMat = listArray(mappedEquations);
 
        // -------------------------------------------------------------------------
        // STEP 5      
        // GENERALISED INCIDENCE MATRICES
        
        //whenReinitIncidenceMat = listArray(whenReinitIncidenceMatList);
        whenEqIncidenceMat = listArray(whenEqIncidenceMatList);
        
        // Global Incidence Mat contains the original equations and in the end concatenated the reinits
        //globalIncidenceMat = Util.arrayAppend(m, whenReinitIncidenceMat);
        globalIncidenceMat = m;
        
        // Build from the beginning the incidence rows for the when equations to exlude the conditions
        globalIncidenceMat = replaceRowsArray(globalIncidenceMat, whenEqInd, whenEqIncidenceMatList);        
        
        // This is the extended ass2 variable
        varsSolvedInEqsList = listAppend(varsSolvedInEqsList, reinitVarsOut);
        globalAss2 = listArray(varsSolvedInEqsList);
        
 
        // -------------------------------------------------------------------------
        // STEP 6      
        // GENERATE THE INPUTS/OUTPUTS OF DEVS BLOCKS
        
        // Add IN/OUT VARS of qss integrators
        ((DEVS_blocks_outVars, DEVS_blocks_inVars)) = qssIntegratorsInOutVars(stateVarIndices,({},{}));
        // Add IN/OUT VARS of static blocks
        (DEVS_blocks_outVars, DEVS_blocks_inVars) = getBlocksInOutVars(stateEq_blt, globalIncidenceMat, globalAss2, DEVS_blocks_outVars, DEVS_blocks_inVars) "add states blocks";
        // Add IN/OUT VARS of zero crossings
        DEVS_blocks_inVars = listAppend(DEVS_blocks_inVars, zc_inVars);
        tempListList = constructEmptyList(nZeroCross, {});
        DEVS_blocks_outVars = listAppend(DEVS_blocks_outVars, tempListList);
        // Add IN/OUT VARS of cross detectors
        tempListList = constructEmptyList(nCrossDetect, {});
        DEVS_blocks_outVars = listAppend(DEVS_blocks_outVars, tempListList);
        DEVS_blocks_inVars = listAppend(DEVS_blocks_inVars, tempListList);
        // Add IN/OUT VARS of when blocks and reinit blocks
        (when_blocks_outVars, when_blocks_inVars) = getBlocksInOutVars(whenEqInBlocks, globalIncidenceMat, globalAss2, {}, {});
        reinit_blocks_inVars = reinitVarsIn;
        reinit_blocks_outVars = constructEmptyList(nReinits, {}); 
        tempIndList = createListIncreasingIndices(1,nWhens + nReinits,{});
        tempIndList = Util.listMap1(tempIndList, intAdd, nStatic + nIntegr + nZeroCross + nCrossDetect);
       
        (when_blocks_outVars) = mergeListsLists(tempIndList, whenClausesInBlocks, when_blocks_outVars, reinitsInBlocks, reinit_blocks_outVars,{});
        (when_blocks_inVars) = mergeListsLists(tempIndList, whenClausesInBlocks, when_blocks_inVars, reinitsInBlocks, reinit_blocks_inVars,{});
        
        DEVS_blocks_outVars = listAppend(DEVS_blocks_outVars, when_blocks_outVars);
        DEVS_blocks_inVars = listAppend(DEVS_blocks_inVars, when_blocks_inVars);
     
        print("DEVS_blocks_outVars :\n");
        printListOfLists(DEVS_blocks_outVars);
        print("DEVS_blocks_inVars :\n");
        printListOfLists(DEVS_blocks_inVars);

        // -------------------------------------------------------------------------
        // STEP 7      
        // GENERATE THE DEVS STRUCTURE
        
        DEVS_structure = generateDEVSstruct(nBlocksList, stateVarIndices, discreteVarIndices, zeroCrossList, samplesList, 
                           whenClausesInBlocks, reinitsInBlocks, reinitVarsOut, DEVS_blocks_outVars, DEVS_blocks_inVars, mappedEquationsMat); 
        
        
        // -------------------------------------------------------------------------
        // PRINT VARIOUS INFO
        
        print("---------- When Equations in DEVS Blocks ----------\n");
        Util.listMap0(whenEqInBlocks, printListOfLists);
        print("---------- When Equations in DEVS Blocks ----------\n");
        print("---------- When Clauses in DEVS Blocks ----------\n");
        printList(whenClausesInBlocks, "start"); print("\n");
        print("---------- When Clauses in DEVS Blocks ----------\n");
        print("---------- Reinit in DEVS Blocks ----------\n");
        printList(reinitsInBlocks, "start"); print("\n");
        print("---------- When Clauses in DEVS Blocks ----------\n");
        
        
       
        
        print("# when clauses \n");
        print(intString(listLength(whenClausesList)));
        print("\n");
        print("\nwhen eq clauses ind:\n");
        printList(whenEqClausesInd, "start");
        print("\nwhen eq ind:\n");
        printList(whenEqInd, "start");
        print("\nwhen eq incidenceMatList\n");
        printListOfLists(whenEqIncidenceMatList);
               
        print("Vars Solved in which eqs: ");
        printList(varsSolvedInEqsList, "start");
        print("\n");
         
        BackendDump.dumpIncidenceMatrix(globalIncidenceMat);
        
                
        
        
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
       
        
        qssInfo = QSSINFO(stateEq_blt, DEVS_structure,eqs,varlst,zcSamplesInd);
        conns = generateConnections(qssInfo);
        print("CONNECTIONS");
        printListOfLists(conns);        
        print("\n");
        
      then
        qssInfo; 
    else
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




public function getReinitInfo
"function: getReinitInfo
 extracts info about the reinit clauses in the model
 author: florosx - May 2011
"
  input Integer loopIndex;
  input list<BackendDAE.WhenClause> wcIn;
  input BackendDAE.Variables vars;
  input list<Integer> tempOutListWhens;
  input list<list<Integer>> tempOutIncidenceMat;
  input list<Integer> tempOutVars;
  
  output list<Integer> whenReinitClausesInd;
  output list<list<Integer>> whenReinitIncidenceMatList;
  output list<Integer> whenReinitOutVars;
  
algorithm
  (whenReinitClausesInd, whenReinitIncidenceMatList, whenReinitOutVars) :=
  matchcontinue (loopIndex, wcIn, vars, tempOutListWhens, tempOutIncidenceMat, tempOutVars)
    local
      
      list<BackendDAE.WhenOperator> cur_list;
      list<BackendDAE.WhenClause> rest_clauses;  
      list<BackendDAE.WhenClause> wc;
      list<Integer> row;
      list<list<Integer>> tempList, tempList2;
    
    case (loopIndex, {}, vars, tempOutListWhens, tempOutIncidenceMat, tempOutVars) then (listReverse(tempOutListWhens), tempOutIncidenceMat, tempOutVars);   
    
    // WHEN YOU FIND A REINIT  
    case (loopIndex, BackendDAE.WHEN_CLAUSE(reinitStmtLst=cur_list)::rest_clauses, vars, tempOutListWhens, tempOutIncidenceMat, tempOutVars) 
      equation
        true = Util.isListNotEmpty(cur_list);
        tempOutListWhens = loopIndex::tempOutListWhens;
        (tempOutIncidenceMat, tempOutVars) = getReinitInfo2(cur_list, vars, tempOutIncidenceMat, tempOutVars);
        (tempOutListWhens, tempOutIncidenceMat, tempOutVars) = 
                getReinitInfo(loopIndex+1, rest_clauses, vars, tempOutListWhens, tempOutIncidenceMat, tempOutVars);
      then
        (tempOutListWhens, tempOutIncidenceMat, tempOutVars);
   
   // WHEN YOU DONT FIND A REINIT
   case (loopIndex, BackendDAE.WHEN_CLAUSE(reinitStmtLst=cur_list)::rest_clauses, vars, tempOutListWhens, tempOutIncidenceMat, tempOutVars) 
      equation
        false = Util.isListNotEmpty(cur_list);
        (tempOutListWhens, tempOutIncidenceMat, tempOutVars) = 
                getReinitInfo(loopIndex+1, rest_clauses, vars, tempOutListWhens, tempOutIncidenceMat, tempOutVars);
      then
        (tempOutListWhens, tempOutIncidenceMat, tempOutVars);
   case (_,_,_,_,_,_)
      equation
        print("- BackendQSS.getReinitInfo failed\n");
      then
        fail();            
  end matchcontinue;
end getReinitInfo;

public function getReinitInfo2
"function: getReinitInfo2 
 Helper function for getReinitInfo
 author: florox - May 2011
"
  input list<BackendDAE.WhenOperator> cur_ReinitList;
  input BackendDAE.Variables vars;
  input list<list<Integer>> tempOutIncidenceMat;
  input list<Integer> tempOutVars;
  
  output list<list<Integer>> whenReinitIncidenceMatList;
  output list<Integer> whenReinitOutVars;
  
algorithm
  (whenReinitIncidenceMatList,whenReinitOutVars) :=
  matchcontinue (cur_ReinitList, vars, tempOutIncidenceMat, tempOutVars)
    local   
      list<BackendDAE.WhenOperator> rest_reinits;
      DAE.ComponentRef leftHand;  
      DAE.Exp rightHand;
      list<Integer> row, lst1, lst2;
      Integer elem;
    case ({}, vars, tempOutIncidenceMat, tempOutVars) then (listReverse(tempOutIncidenceMat), listReverse(tempOutVars));   
    
    case (BackendDAE.REINIT(stateVar = leftHand, value = rightHand)::rest_reinits, vars, tempOutIncidenceMat, tempOutVars) 
      equation  
        lst1 = BackendDAEUtil.incidenceRowExp(DAE.CREF(leftHand,DAE.ET_REAL()), vars, {});
        lst2 = BackendDAEUtil.incidenceRowExp(rightHand, vars, {});
        row = lst2;
        elem = listNth(lst1, 0);
        tempOutVars = elem::tempOutVars;
        tempOutIncidenceMat = row::tempOutIncidenceMat;            
        (tempOutIncidenceMat, tempOutVars) = getReinitInfo2(rest_reinits, vars, tempOutIncidenceMat, tempOutVars);  
      then
        (tempOutIncidenceMat, tempOutVars);     
    case (_,_,_,_)
      equation
        print("- BackendQSS.getReinitInfo2 failed\n");
      then
        fail();        
  end matchcontinue;
end getReinitInfo2;

public function getWhenEqClausesInfo 
"function: getWhenClausesInfo
 returns the indices of equations inside whens (when-clauses), the corresponding indices 
 of the when-clauses and the modified incidenceMat for the when-clauses.
 author: florox - May 2011
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
        (whenEqInd, whenEqClausesInd,whenEqIncidenceMatList) = getWhenEqClausesInfo2(eqnArr, vars);
      then (wc, whenEqClausesInd, whenEqInd, whenEqIncidenceMatList);
    
    case (_)
      equation
        print("- BackendQSS.getWhenEqClausesInfo failed\n");
      then
        fail();      
  end matchcontinue;
end getWhenEqClausesInfo;

public function getWhenEqClausesInfo2
"function: getWhenEqClausesInfo2
 Helper function for getWhenEqClausesInfo
 author: florox - May 2011
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
        (eqInd, whenClauseInd, whenIncidenceMatList) = getWhenEqClausesInfo3(1,BackendDAEUtil.equationSize(eqns),eqns, vars,{},{},{});
       then (eqInd, whenClauseInd, whenIncidenceMatList);
     
     case (_,_)
      equation
        print("- BackendQSS.getWhenEqClausesInfo2 failed\n");
      then
        fail();          
   end matchcontinue;
end getWhenEqClausesInfo2;

protected function getWhenEqClausesInfo3
"function: getWhenEqClausesInfo3
 Helper function for getWhenEqClausesInfo2
 author: florox - May 2011
"
  input Integer i;
  input Integer size;
  input BackendDAE.EquationArray eqns;
  input BackendDAE.Variables vars; 
  input list<Integer> eqnList_temp;
  input list<Integer> whenClausesList_temp;
  input list<list<Integer>> whenIncidenceMatList_temp;
  
  output list<Integer> eqnLst;
  output list<Integer> whenClausesList;
  output list<list<Integer>> whenIncidenceMatList;
   
algorithm
  (eqnLst, whenClausesList, whenIncidenceMatList) := 
  matchcontinue(i,size,eqns,vars, eqnList_temp, whenClausesList_temp, whenIncidenceMatList_temp)
    local
      BackendDAE.WhenEquation whenEq;
      Integer tempInd;
      list<Integer> row;
      
    case(i,size,eqns, vars, eqnList_temp, whenClausesList_temp, whenIncidenceMatList_temp) 
      equation
        true = (i > size );
      then (listReverse(eqnList_temp),listReverse(whenClausesList_temp), listReverse(whenIncidenceMatList_temp));
  
    case(i,size,eqns, vars, eqnList_temp, whenClausesList_temp, whenIncidenceMatList_temp)
      equation
        BackendDAE.WHEN_EQUATION(whenEquation = whenEq) = BackendDAEUtil.equationNth(eqns,i-1);
        BackendDAE.WHEN_EQ(index = tempInd) = whenEq;       
        row = getRowWhenIncidenceMat(whenEq, vars);
        whenIncidenceMatList_temp = row::whenIncidenceMatList_temp;
        eqnList_temp = i::eqnList_temp;
        whenClausesList_temp =  tempInd::whenClausesList_temp;
        (eqnList_temp, whenClausesList_temp, whenIncidenceMatList_temp) = getWhenEqClausesInfo3(i+1,size,eqns,vars, eqnList_temp, whenClausesList_temp, whenIncidenceMatList_temp);
    then (eqnList_temp, whenClausesList_temp, whenIncidenceMatList_temp);
    
    case(i,size,eqns,vars, eqnList_temp, whenClausesList_temp, whenIncidenceMatList_temp)
      equation
        (eqnList_temp, whenClausesList_temp,whenIncidenceMatList_temp) = getWhenEqClausesInfo3(i+1,size,eqns,vars,eqnList_temp, whenClausesList_temp, whenIncidenceMatList_temp);
      then (eqnList_temp, whenClausesList_temp,whenIncidenceMatList_temp);
    
    case (_,_,_,_,_,_,_)
      equation
        print("- BackendQSS.getWhenEqClausesInfo3 failed\n");
      then
        fail();          
  
  end matchcontinue;
end getWhenEqClausesInfo3;

protected function getRowWhenIncidenceMat
"function: getRowWhenIncidenceMat
 Helper function for getWhenEqClausesInfo3
 author: florox - May 2011
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
        //lst2 = makeListNegative(lst2, {});
        row = listAppend(lst1, lst2);
    then (row);
    
    case (_,_)
      equation
        print("- BackendQSS.getRowWhenIncidenceMat failed\n");
      then
        fail();         
  end matchcontinue;
end getRowWhenIncidenceMat;

////////////////////////////////////////////////////////////////////////////////////////////////////

public function getListofZeroCrossings 
"function: getListofZeroCrossings
  Takes as input the DAE and extracts the zero-crossings as well as the zero crosses that are 
  connected to sample statements.
  author: florosx - May 2011
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
  author: florosx - May 2011
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
        (listReverse(zcOnlyTemp), listReverse(zc_inVarsTemp), listReverse(zcSamplesTemp),listReverse(zcSamplesIndTemp));  
      
    case (loopIndex, (cur_zc as BackendDAE.ZERO_CROSSING(relation_ = e))::rest_zeroCrossings, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp, zcSamplesIndTemp)
      equation
        // IF IT IS A SAMPLE
        true = checkIfExpressionIsSample(e);
        zcSamplesTemp = cur_zc::zcSamplesTemp;
        zcSamplesIndTemp = loopIndex::zcSamplesIndTemp;
        (zcOnlyTemp, zc_inVarsTemp, zcSamplesTemp, zcSamplesIndTemp) = getListofZeroCrossings2(loopIndex+1, rest_zeroCrossings, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp,zcSamplesIndTemp);
      then
        (zcOnlyTemp, zc_inVarsTemp, zcSamplesTemp,zcSamplesIndTemp);
    case (loopIndex, (cur_zc as BackendDAE.ZERO_CROSSING(relation_ = e))::rest_zeroCrossings, vars, zc_inVarsTemp, zcOnlyTemp, zcSamplesTemp, zcSamplesIndTemp)
      equation
        false = checkIfExpressionIsSample(e);
        tempInVars = BackendDAEUtil.incidenceRowExp(e, vars, {});
        zc_inVarsTemp = tempInVars::zc_inVarsTemp;
        zcOnlyTemp = cur_zc::zcOnlyTemp;
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
  author: florosx - May 2011
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
  output DevsStruct DEVS_structureOut;

algorithm 
  (DEVS_structureOut):=
  matchcontinue (nBlocks)
    local
      list<list<list<Integer>>> DEVS_struct_outLinksList;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
  
   case (nBlocks)
      equation
        DEVS_struct_outLinksList = constructEmptyListList(nBlocks, {});
        DEVS_struct_outLinks = listArray(DEVS_struct_outLinksList); 
        DEVS_struct_outVars = listArray(DEVS_struct_outLinksList);
        DEVS_struct_inVars = listArray(DEVS_struct_outLinksList);
        DEVS_struct_inLinks = listArray(DEVS_struct_outLinksList);
      then
        (DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars));
    case (_)
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
  input list<list<list<Integer>>> equations_blt;
  input BackendDAE.IncidenceMatrix incidenceMat;
  input array<Integer> ass2;
  input list<list<Integer>> DEVS_blocks_outVarsIn;
  input list<list<Integer>> DEVS_blocks_inVarsIn;
  output list<list<Integer>> DEVS_blocks_outVarsOut;
  output list<list<Integer>> DEVS_blocks_inVarsOut;
 
algorithm
  (DEVS_blocks_outVarsOut, DEVS_blocks_inVarsOut):=
  matchcontinue (equations_blt, incidenceMat, ass2, DEVS_blocks_outVarsIn, DEVS_blocks_inVarsIn)
    local
     
      list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars;
     
    case (equations_blt, incidenceMat, ass2, DEVS_blocks_outVarsIn, DEVS_blocks_inVarsIn)
      equation        
        ((DEVS_blocks_outVars, DEVS_blocks_inVars)) = incidenceMatInOutVars(equations_blt, incidenceMat, ass2, (DEVS_blocks_outVarsIn, DEVS_blocks_inVarsIn));
      then
        (DEVS_blocks_outVars, DEVS_blocks_inVars);
    case (_,_,_,_,_)
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
  input list<Integer> nBlocksList;
  input list<Integer> stateIndices;
  input list<Integer> discreteVarIndices;
  input list<BackendDAE.ZeroCrossing> zeroCrossList;
  input list<BackendDAE.ZeroCrossing> samplesList;
  input list<Integer> whenClausesInBlocks;
  input list<Integer> reinitsInBlocks;
  input list<Integer> reinitVarsOut;
  input list<list<Integer>> DEVS_blocks_outVars;
  input list<list<Integer>> DEVS_blocks_inVars;
  input array<list<Integer>> mappedEquationsMat;

  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (nBlocksList, stateIndices, discreteVarIndices, zeroCrossList, samplesList, whenClausesInBlocks, reinitsInBlocks, reinitVarsOut, DEVS_blocks_outVars, DEVS_blocks_inVars, mappedEquationsMat)
    local
      Integer nStatic, nIntegr, nBlocks, nZeroCross, nCrossDetect, startCrossDetectInd, startZeroCrossInd, startWhenInd, startSampleInd, nWhens, nReinits; 
      DevsStruct DEVS_structure_temp;
      list<Integer> whensReinitsInBlocks;
      
    case (nBlocksList, stateIndices, discreteVarIndices, zeroCrossList, samplesList, whenClausesInBlocks, reinitsInBlocks, reinitVarsOut, DEVS_blocks_outVars, DEVS_blocks_inVars, mappedEquationsMat)
      equation
        nBlocks = listNth(nBlocksList, 0);
        nStatic = listNth(nBlocksList, 1);
        nIntegr = listNth(nBlocksList, 2);
        nZeroCross = listNth(nBlocksList, 3);
        nCrossDetect = listNth(nBlocksList, 4);
        nWhens = listNth(nBlocksList, 5);
        nReinits = listNth(nBlocksList, 6);
        
        startZeroCrossInd = nStatic + nIntegr + 1;
        startCrossDetectInd = nStatic + nIntegr + nZeroCross + 1;
        startWhenInd = startCrossDetectInd + nCrossDetect;
        startSampleInd = startWhenInd + nWhens + nReinits;
        
        DEVS_structure_temp = generateEmptyDEVSstruct(nBlocks);  
                
        //Resolve dependencies between inputs/outputs excluding events      
        (DEVS_structure_temp) = generateStructFromInOutVars(1,stateIndices,discreteVarIndices, DEVS_blocks_outVars, DEVS_blocks_inVars, DEVS_structure_temp);
           
        //Add the connections between zero-crossings and cross-detectors
        (DEVS_structure_temp) = addZeroCrossOut_CrossDetectIn(startZeroCrossInd, startCrossDetectInd, zeroCrossList, DEVS_structure_temp);
        //Add the cross-detector blocks outputs
        whensReinitsInBlocks = listAppend(whenClausesInBlocks, reinitsInBlocks);
        (DEVS_structure_temp) = addCrossDetectBlocksOut(startCrossDetectInd, zeroCrossList, whensReinitsInBlocks, mappedEquationsMat, DEVS_structure_temp);
        
        //Add the outputs of the reinits to the respective integrators
        (DEVS_structure_temp) = addReinitBlocksOut(startWhenInd, reinitsInBlocks, reinitVarsOut, stateIndices, DEVS_structure_temp);
             
        //Add the outputs of the sample blocks to the respective when clauses
        (DEVS_structure_temp) = addSampleBlocksOut(startSampleInd, startWhenInd, samplesList, DEVS_structure_temp);
        
        print("DEVS_structure FLAG 4\n");
        dumpDEVSstructs(DEVS_structure_temp);
      
        // Check where the event input port is not in the end and push it to the end
        (DEVS_structure_temp) = fixEventInputPort(DEVS_structure_temp);
        
        print("DEVS_structure FLAG 5\n");
        dumpDEVSstructs(DEVS_structure_temp);
        
        // Resolve dependencies for EVENTS
        // Already we should have resolved the dependencies between DEVS blocks concerning the variables.
        DEVS_structure_temp = updateEventsAsInputs(startCrossDetectInd, nBlocks, DEVS_structure_temp);  
      then
        (DEVS_structure_temp);
    case (_,_,_,_,_,_,_,_,_,_,_)
      equation
        print("- BackendQSS.generateDEVSstruct failed\n");
      then
        fail();
  end matchcontinue;
end generateDEVSstruct;

protected function addSampleBlocksOut
"function: addReinitBlocksOut
  Adds the outputs of the reinits to the integrators.
  author: florosx
" 
  input Integer startBlockInd;
  input Integer startWhenInd;
  input list<BackendDAE.ZeroCrossing> samplesList;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (startBlockInd, startWhenInd, samplesList, DEVS_structureIn)
    local
      list<list<Integer>> curBlock_outLinks, curBlock_outVars, integrVarsIn, integrLinksIn;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      DevsStruct DEVS_structure_temp;
      list<BackendDAE.ZeroCrossing> restSamples;
      BackendDAE.ZeroCrossing curSample;
      DAE.Exp e;
      list<Integer> eq,wc;
      
    case (startBlockInd, startWhenInd, {}, DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);
      
    case (startBlockInd, startWhenInd, BackendDAE.ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)::restSamples, 
                     DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation
       curBlock_outVars = {{0}};  
       // TEMPORARY SOLUTION: IN THE FUTURE MAYBE WE DONT HAVE THE WHEN CLAUSES IN THE ORDER THEY ARE NOW AND ONE IN EACH BLOCK
       wc = Util.listMap1(wc, intAdd, startWhenInd-1);
       curBlock_outLinks = {wc};  
       DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, startBlockInd, curBlock_outLinks);
       DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, startBlockInd, curBlock_outVars);
       
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
       DEVS_structure_temp = addSampleBlocksOut(startBlockInd+1, startWhenInd, restSamples, DEVS_structure_temp);
      then
        (DEVS_structure_temp);
 
    case (_,_,_,_)
      equation
        print("- BackendQSS.addSampleBlocksOut failed\n");
      then
        fail();
  end matchcontinue;
end addSampleBlocksOut;









protected function addReinitBlocksOut
"function: addReinitBlocksOut
  Adds the outputs of the reinits to the integrators.
  author: florosx
" 
  input Integer startBlockInd;
  input list<Integer> reinitsInBlocks;
  input list<Integer> reinitVarsOut;
  input list<Integer> stateIndices;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (startBlockInd, reinitsInBlocks, reinitVarsOut, stateIndices, DEVS_structureIn)
    local
      list<list<Integer>> curBlock_outLinks, curBlock_outVars, integrVarsIn, integrLinksIn;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      DevsStruct DEVS_structure_temp;
      Integer curReinit, curVarOut, integrInd;
      list<Integer> restReinits, restVarsOut;
      
    case (startBlockInd, {}, {}, stateIndices, DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);
      
    case (startBlockInd, curReinit::restReinits, curVarOut::restVarsOut, stateIndices, 
                   DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation   
       curBlock_outVars = {{0}};            
       integrInd = findElementInList(1, listLength(stateIndices), stateIndices, intAbs(curVarOut));
       curBlock_outLinks = {{integrInd}};
       integrVarsIn = DEVS_struct_inVars[integrInd];
       integrLinksIn = DEVS_struct_inLinks[integrInd];
       integrVarsIn = listAppend(integrVarsIn, {{curVarOut}});
       integrLinksIn = listAppend(integrLinksIn, {{startBlockInd}});
       DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, curReinit, curBlock_outLinks);
       DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, curReinit, curBlock_outVars);
       DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, integrInd, integrLinksIn);
       DEVS_struct_inVars = arrayUpdate(DEVS_struct_inVars, integrInd, integrVarsIn);
       
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
       DEVS_structure_temp = addReinitBlocksOut(startBlockInd, restReinits, restVarsOut, stateIndices, DEVS_structure_temp);
      then
        (DEVS_structure_temp);
 
    case (_,_,_,_,_)
      equation
        print("- BackendQSS.addReinitBlocksOut failed\n");
      then
        fail();
  end matchcontinue;
end addReinitBlocksOut;







protected function addCrossDetectBlocksOut
"function: addCrossDetectBlocks
  Adds the cross-detector blocks in the DEVS structure.
  author: florosx
" 
  input Integer startBlockInd;
  input list<BackendDAE.ZeroCrossing> zeroCrossList;
  input list<Integer> whenClausesInBlocks;
  input array<list<Integer>> mappedEquationsMat;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (startBlockInd, zeroCrossList, whenClausesInBlocks, mappedEquationsMat, DEVS_structureIn)
    local
      list<list<Integer>> curBlock_outLinks, curBlock_outVars, curBlock_inLinks, curBlock_inVars;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      DevsStruct DEVS_structure_temp;
      list<BackendDAE.ZeroCrossing> restZC;
      BackendDAE.ZeroCrossing curZC;
      list<Integer> eq,wc, curIfDevsBlocksOut, curWhenDevsBlocksOut;
      DAE.Exp e;
      
    case (startBlockInd, {}, whenClausesInBlocks, mappedEquationsMat, DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);
      
    case (startBlockInd, BackendDAE.ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)::restZC, whenClausesInBlocks, mappedEquationsMat, 
                   DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation
       // When there are both connections to IFS and WHEN 
       // Connections for the if-part  
       curIfDevsBlocksOut = findEqInBlocks(eq, mappedEquationsMat,{});
       curBlock_outVars = {{0}};
       // Connections for the when-part
       wc = Util.listMap1(wc, intAdd, -1);
       curWhenDevsBlocksOut = Util.listMap1r(wc, listNth, whenClausesInBlocks);  
       true = Util.isListNotEmpty(curIfDevsBlocksOut);
       true = Util.isListNotEmpty(curWhenDevsBlocksOut);
       curIfDevsBlocksOut = listAppend(curIfDevsBlocksOut, curWhenDevsBlocksOut);
       curBlock_outLinks = {curIfDevsBlocksOut};
       printListOfLists(curBlock_outLinks);
       DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, startBlockInd, curBlock_outLinks);
       DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, startBlockInd, curBlock_outVars);
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
       DEVS_structure_temp = addCrossDetectBlocksOut(startBlockInd+1, restZC, whenClausesInBlocks, mappedEquationsMat, DEVS_structure_temp);
      then
        (DEVS_structure_temp);
   
    case (startBlockInd, BackendDAE.ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)::restZC, whenClausesInBlocks, mappedEquationsMat, 
                   DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation
       // When there are connections to IFS but not to WHEN
       // Connections for the if-part  
       curIfDevsBlocksOut = findEqInBlocks(eq, mappedEquationsMat,{});
       curBlock_outVars = {{0}};
       // Connections for the when-part
       wc = Util.listMap1(wc, intAdd, -1);
       curWhenDevsBlocksOut = Util.listMap1r(wc, listNth, whenClausesInBlocks);  
       true = Util.isListNotEmpty(curIfDevsBlocksOut);
       false = Util.isListNotEmpty(curWhenDevsBlocksOut);
       curBlock_outLinks = {curIfDevsBlocksOut};
       DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, startBlockInd, curBlock_outLinks);
       DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, startBlockInd, curBlock_outVars);
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
       DEVS_structure_temp = addCrossDetectBlocksOut(startBlockInd+1, restZC, whenClausesInBlocks, mappedEquationsMat, DEVS_structure_temp);
      then
        (DEVS_structure_temp); 
   
   case (startBlockInd, BackendDAE.ZERO_CROSSING(relation_ = e,occurEquLst = eq,occurWhenLst = wc)::restZC, whenClausesInBlocks, mappedEquationsMat, 
                   DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation
       // When there are connections to WHENS but not to IFS
       // Connections for the if-part  
       curIfDevsBlocksOut = findEqInBlocks(eq, mappedEquationsMat,{});
       curBlock_outVars = {{0}};
       // Connections for the when-part
       wc = Util.listMap1(wc, intAdd, -1);
       curWhenDevsBlocksOut = Util.listMap1r(wc, listNth, whenClausesInBlocks);  
       false = Util.isListNotEmpty(curIfDevsBlocksOut);
       true = Util.isListNotEmpty(curWhenDevsBlocksOut);
       curBlock_outLinks = {curWhenDevsBlocksOut};
       DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, startBlockInd, curBlock_outLinks);
       DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, startBlockInd, curBlock_outVars);
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
       DEVS_structure_temp = addCrossDetectBlocksOut(startBlockInd+1, restZC, whenClausesInBlocks, mappedEquationsMat, DEVS_structure_temp);
      then
        (DEVS_structure_temp);    
    case (_,_,_,_,_)
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
















protected function fixEventInputPort
"function: fixEventInputPort
  author: florosx
" 
  
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (DEVS_structureIn)
    local
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      DevsStruct DEVS_structure_temp;
      Integer nBlocks;

    case (DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars))
      equation
        nBlocks = arrayLength(DEVS_struct_inLinks);
       (DEVS_struct_inLinks, DEVS_struct_inVars) = fixEventInputPort_helper(1, nBlocks, DEVS_struct_inLinks, DEVS_struct_inVars);
       (DEVS_struct_outLinks, DEVS_struct_outVars) = fixEventInputPort_helper(1, nBlocks, DEVS_struct_outLinks, DEVS_struct_outVars);
       DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);  
      then
        (DEVS_structure_temp);
    case (_)
      equation
        print("- BackendQSS.fixEventInputPort failed\n");
      then
        fail();
  end matchcontinue;
end fixEventInputPort;

protected function fixEventInputPort_helper
"function: fixEventInputPort_helper takes as input a 
  author: florosx
" 
  input Integer blockInd; 
  input Integer nBlocks;
  input array<list<list<Integer>>> DEVS_struct_inLinks;
  input array<list<list<Integer>>> DEVS_struct_inVars;
  output array<list<list<Integer>>> DEVS_struct_inLinksOut;
  output array<list<list<Integer>>> DEVS_struct_inVarsOut;
  
  
algorithm
  (DEVS_struct_inLinksOut, DEVS_struct_inVarsOut):=
  matchcontinue (blockInd, nBlocks, DEVS_struct_inLinks, DEVS_struct_inVars)
    local
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      DevsStruct DEVS_structure_temp;
      list<list<Integer>> curBlock_inLinks, curBlock_inVars;
      Integer endPort, eventPort;
      list<Integer> eventPortInLinks, eventPortInVars, endPortInLinks, endPortInVars;
      
    case (blockInd, nBlocks, DEVS_struct_inLinks, DEVS_struct_inVars)   
      equation
       true = blockInd > nBlocks;
      then
        (DEVS_struct_inLinks, DEVS_struct_inVars);
    
    case (blockInd, nBlocks, DEVS_struct_inLinks, DEVS_struct_inVars)
      equation
       curBlock_inLinks = DEVS_struct_inLinks[blockInd];
       curBlock_inVars = DEVS_struct_inVars[blockInd];
       eventPort = findInputPort(0, curBlock_inVars, 0);
       true = eventPort == -1 ; // If there exists no event port go to the next block
       (DEVS_struct_inLinks, DEVS_struct_inVars) = fixEventInputPort_helper(blockInd+1, nBlocks, DEVS_struct_inLinks, DEVS_struct_inVars);
      then
        (DEVS_struct_inLinks, DEVS_struct_inVars);
    
    case (blockInd, nBlocks, DEVS_struct_inLinks, DEVS_struct_inVars)
      equation
       curBlock_inLinks = DEVS_struct_inLinks[blockInd];
       curBlock_inVars = DEVS_struct_inVars[blockInd];
       eventPort = findInputPort(0, curBlock_inVars, 0);
       false = eventPort == -1 ; // If there exists an event port put it to the end
       endPort = listLength(curBlock_inLinks)-1;
       eventPortInLinks = listNth(curBlock_inLinks, eventPort);
       eventPortInVars = listNth(curBlock_inVars, eventPort);
       endPortInLinks = listNth(curBlock_inLinks, endPort);
       endPortInVars = listNth(curBlock_inVars, endPort);
       curBlock_inLinks = Util.listReplaceAt(endPortInLinks, eventPort, curBlock_inLinks);
       curBlock_inVars = Util.listReplaceAt(endPortInVars, eventPort, curBlock_inVars);
       curBlock_inLinks = Util.listReplaceAt(eventPortInLinks, endPort, curBlock_inLinks);
       curBlock_inVars = Util.listReplaceAt(eventPortInVars, endPort, curBlock_inVars);
       DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, blockInd, curBlock_inLinks);
       DEVS_struct_inVars = arrayUpdate(DEVS_struct_inVars, blockInd, curBlock_inVars);
       (DEVS_struct_inLinks, DEVS_struct_inVars) = fixEventInputPort_helper(blockInd+1, nBlocks, DEVS_struct_inLinks, DEVS_struct_inVars);
      then
        (DEVS_struct_inLinks, DEVS_struct_inVars);
    
    case (_,_,_,_)
      equation
        print("- BackendQSS.fixEventInputPort_helper failed\n");
      then
        fail();
  end matchcontinue;
end fixEventInputPort_helper;


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
       print("TRUE1\n");
       portIn = findInputPort(0, curBlock_inVars, 0);
       //Check if the curBlockIn has already an event port. If yes, add the startBlockInd, otherwise create an event port.
       true = portIn == -1 ; // If there exists no event port 
       print("TRUE2\n");
       curBlock_inVars = listAppend(curBlock_inVars, {{0}});
       curBlock_inLinks = listAppend(curBlock_inLinks, {{eventBlockInd}});
       print("TRUE3\n");
       DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, curBlockIn, curBlock_inLinks);
       print("TRUE4\n");
       DEVS_struct_inVars = arrayUpdate(DEVS_struct_inVars, curBlockIn, curBlock_inVars);
       print("TRUE5\n");
       (DEVS_struct_inLinks, DEVS_struct_inVars) = updateEventsAsInputs2(eventBlockInd, restBlocks, DEVS_struct_inLinks, DEVS_struct_inVars);
       then
        (DEVS_struct_inLinks, DEVS_struct_inVars);
        
    case (eventBlockInd, curBlockIn::restBlocks, DEVS_struct_inLinks, DEVS_struct_inVars)
      equation
        print("FALSE1\n");
       curBlock_inLinks = DEVS_struct_inLinks[curBlockIn];
       curBlock_inVars = DEVS_struct_inVars[curBlockIn];
       portIn = findInputPort(0, curBlock_inVars, 0);
       //Check if the curBlockIn has already an event port. If yes, add the startBlockInd, otherwise create an event port.
       false = portIn == -1 ;// If there already exists an event port 
       print("FALSE2\n");
       tempList = listNth(curBlock_inLinks, portIn);
       tempList = listAppend(tempList, {eventBlockInd});
       print("FALSE3\n");
       curBlock_inLinks = Util.listReplaceAt(tempList, portIn, curBlock_inLinks);
       DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, curBlockIn, curBlock_inLinks);
       print("FALSE4\n");
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




protected function generateStructFromInOutVars
"function: generateStructFromInOutVars
  Takes as input the inputs/outputs of each block and generates the DEVS structures resolving the dependencies.
  author: florosx
"
  input Integer curBlockIndex;
  input list<Integer> stateIndices;
  input list<Integer> discreteVarIndices;
  input list<list<Integer>> DEVS_blocks_outVars;
  input list<list<Integer>> DEVS_blocks_inVars;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (curBlockIndex, stateIndices, discreteVarIndices, DEVS_blocks_outVars, DEVS_blocks_inVars, DEVS_structureIn)
    local
      tuple< list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>>, list<list<list<Integer>>> > DEVS_struct_lists_temp;
   
      list<list<list<Integer>>> DEVS_struct_outLinksList, DEVS_struct_outVarsList, DEVS_struct_inLinksList, DEVS_struct_inVarsList;
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      
      list<list<Integer>> DEVS_blocks_outVars, DEVS_blocks_inVars, rest_blocks_outVars;
      list<Integer> curBlock_outVars;
      
      tuple< list<list<Integer>>, list<list<Integer>> > DEVS_blocks_inOutVars_temp;
      
      DevsStruct DEVS_structure_temp;
   
    case (curBlockIndex, stateIndices, discreteVarIndices, {}, _ , DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);
      
    case (curBlockIndex, stateIndices, discreteVarIndices, curBlock_outVars::rest_blocks_outVars, DEVS_blocks_inVars, DEVS_structure_temp )
      equation
        
       DEVS_structure_temp = findOutVarsInAllInputs(curBlockIndex, stateIndices, discreteVarIndices, curBlock_outVars, DEVS_blocks_inVars, DEVS_structure_temp);
       
      then
        (generateStructFromInOutVars(curBlockIndex+1, stateIndices, discreteVarIndices, rest_blocks_outVars, DEVS_blocks_inVars, DEVS_structure_temp));
    case (_,_,_,_,_,_)
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
  input list<Integer> discreteVarIndices;
  input list<Integer> curBlock_outVars;
  input list<list<Integer>> DEVS_blocks_inVars;
  input DevsStruct DEVS_structureIn;
  output DevsStruct DEVS_structureOut;
 
algorithm
  (DEVS_structureOut):=
  matchcontinue (outBlockIndex, stateIndices, discreteVarIndices, curBlock_outVars, DEVS_blocks_inVars, DEVS_structureIn)
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
    case (outBlockIndex, stateIndices, discreteVarIndices, {}, _ , DEVS_structure_temp)
      equation
      then
        (DEVS_structure_temp);

    case (outBlockIndex, stateIndices, discreteVarIndices, curOutVar::restOutVars, DEVS_blocks_inVars, 
             DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars) )
      equation
        blocksToBeChecked = findOutVarsInAllInputsHelper(curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex);          
       
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars) = 
                   findWhereOutVarIsNeeded(curOutVar, discreteVarIndices, outBlockIndex, blocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars,{});
        true = Util.isListNotEmpty(curOutVarLinks) "If the current output var is needed somewhere";
        false = listMember(curOutVar, discreteVarIndices) "Check if the out variable is discrete";
        // If it is not discrete proceed as normal
        curOutBlock_outVars = DEVS_struct_outVars[outBlockIndex];
        curOutBlock_outLinks = DEVS_struct_outLinks[outBlockIndex];
        curOutBlock_outLinks = listAppend(curOutBlock_outLinks, {curOutVarLinks});
        curOutBlock_outVars = listAppend(curOutBlock_outVars, {{curOutVar}}); 
                
        DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, outBlockIndex, curOutBlock_outLinks);
        DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, outBlockIndex, curOutBlock_outVars);
        DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
        DEVS_structure_temp = findOutVarsInAllInputs(outBlockIndex, stateIndices, discreteVarIndices, restOutVars, DEVS_blocks_inVars, DEVS_structure_temp); 
      then
        (DEVS_structure_temp);
     
     case (outBlockIndex, stateIndices, discreteVarIndices, curOutVar::restOutVars, DEVS_blocks_inVars, 
             DEVS_STRUCT(outLinks=DEVS_struct_outLinks, outVars=DEVS_struct_outVars, inLinks=DEVS_struct_inLinks, inVars=DEVS_struct_inVars) )
      equation
        blocksToBeChecked = findOutVarsInAllInputsHelper(curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex);          
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars) = 
                   findWhereOutVarIsNeeded(curOutVar, discreteVarIndices, outBlockIndex, blocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars,{});
        true = Util.isListNotEmpty(curOutVarLinks) "If the current output var is needed somewhere";
        true = listMember(curOutVar, discreteVarIndices) "Check if the out variable is discrete";
        // If it is discrete add an event as output of the when-block and not the variable itself
        curOutBlock_outVars = DEVS_struct_outVars[outBlockIndex];
        curOutBlock_outLinks = DEVS_struct_outLinks[outBlockIndex];
        curOutBlock_outLinks = listAppend(curOutBlock_outLinks, {curOutVarLinks});
        curOutBlock_outVars = listAppend(curOutBlock_outVars, {{0}}); 

        DEVS_struct_outLinks = arrayUpdate(DEVS_struct_outLinks, outBlockIndex, curOutBlock_outLinks);
        DEVS_struct_outVars = arrayUpdate(DEVS_struct_outVars, outBlockIndex, curOutBlock_outVars);
        DEVS_structure_temp = DEVS_STRUCT(DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars);
        DEVS_structure_temp = findOutVarsInAllInputs(outBlockIndex, stateIndices, discreteVarIndices, restOutVars, DEVS_blocks_inVars, DEVS_structure_temp); 
      then
        (DEVS_structure_temp);
        
     // If the current output var is NOT needed somewhere
     case (outBlockIndex, stateIndices, discreteVarIndices, curOutVar::restOutVars, DEVS_blocks_inVars,  DEVS_structure_temp )
      equation
      then
        (findOutVarsInAllInputs(outBlockIndex, stateIndices, discreteVarIndices, restOutVars, DEVS_blocks_inVars, DEVS_structure_temp));
    
    case (_,_,_,_,_,_)
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
        true = listMember(-curOutVar, stateIndices);
        blocksToBeChecked = createListIncreasingIndices(1,listLength(DEVS_blocks_inVars),{});          
      then
        (blocksToBeChecked);
    // If CURRENT OUTPUT IS DERIVATIVE OF STATE
    // This case is of interest if we have coupled states where we dont want the output derivatives to loop
    // back to the same block as inputs.
    case (curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex) 
      equation
        true = listMember(curOutVar, stateIndices);
        blocksToBeChecked = createListIncreasingIndices(1,listLength(DEVS_blocks_inVars),{});  
        blocksToBeChecked = Util.listRemoveNth(blocksToBeChecked, outBlockIndex); // If state derivative remove the current block from the input search.  
      then
        (blocksToBeChecked);
   // If CURRENT OUTPUT IS ALGEBRAIC
    case (curOutVar, stateIndices,DEVS_blocks_inVars,outBlockIndex) 
      equation
        false = listMember(curOutVar, stateIndices);
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
  input list<Integer> discreteVarIndices;
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
  matchcontinue (curOutVar, discreteVarIndices, outBlockIndex, blocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars,curOutVarLinks)
    local
      array<list<list<Integer>>> DEVS_struct_outLinks, DEVS_struct_outVars, DEVS_struct_inLinks, DEVS_struct_inVars;
      Integer curOutVar, inBlockIndex;
      list<Integer> restOutVars, curBlock_inVars, restBlocksToBeChecked;
      list<list<Integer>> restBlocks_inVars, curOutBlock_outLinks, curOutBlock_outVars, curInBlock_inLinks, curInBlock_inVars;
      DevsStruct DEVS_structure_temp;   

    case (curOutVar, discreteVarIndices, outBlockIndex, {}, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks)
      equation
      then
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars);
     
    case (curOutVar, discreteVarIndices, outBlockIndex, inBlockIndex::restBlocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks)
      equation
        // If the current outVariable is NOT needed in the current In block
        curBlock_inVars = listNth(DEVS_blocks_inVars, inBlockIndex-1);
        false = listMember(curOutVar, curBlock_inVars);
        
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars) = 
           findWhereOutVarIsNeeded(curOutVar, discreteVarIndices, outBlockIndex, restBlocksToBeChecked, DEVS_blocks_inVars,DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks);
      then
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars);

    case (curOutVar, discreteVarIndices, outBlockIndex, inBlockIndex::restBlocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks)
      equation
        // If the current outVariable is needed in the current In block
        curBlock_inVars = listNth(DEVS_blocks_inVars, inBlockIndex-1);
        true = listMember(curOutVar, curBlock_inVars);
        false = listMember(curOutVar, discreteVarIndices) "Check if the out variable is discrete";
        // If it is not discrete proceed as normal
        curOutVarLinks = listAppend(curOutVarLinks, {inBlockIndex});
        
        curInBlock_inLinks = DEVS_struct_inLinks[inBlockIndex];
        curInBlock_inLinks = listAppend(curInBlock_inLinks, {{outBlockIndex}});        
        curInBlock_inVars = DEVS_struct_inVars[inBlockIndex];
        curInBlock_inVars = listAppend(curInBlock_inVars, {{curOutVar}});
        DEVS_struct_inLinks = arrayUpdate(DEVS_struct_inLinks, inBlockIndex, curInBlock_inLinks);
        DEVS_struct_inVars = arrayUpdate(DEVS_struct_inVars, inBlockIndex, curInBlock_inVars);
        
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars) = 
           findWhereOutVarIsNeeded(curOutVar, discreteVarIndices, outBlockIndex, restBlocksToBeChecked, DEVS_blocks_inVars,DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks);
      then
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars);
    
    case (curOutVar, discreteVarIndices, outBlockIndex, inBlockIndex::restBlocksToBeChecked, DEVS_blocks_inVars, DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks)
      equation
        // If the current outVariable is needed in the current In block
        curBlock_inVars = listNth(DEVS_blocks_inVars, inBlockIndex-1);
        true = listMember(curOutVar, curBlock_inVars);
        true = listMember(curOutVar, discreteVarIndices) "Check if the out variable is discrete";
        // If it is discrete add an event as output of the when-block and not the variable itself
        curOutVarLinks = listAppend(curOutVarLinks, {inBlockIndex});
        (DEVS_struct_inLinks, DEVS_struct_inVars) = updateEventsAsInputs2
                    (outBlockIndex, {inBlockIndex},DEVS_struct_inLinks, DEVS_struct_inVars); 
        
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars) = 
           findWhereOutVarIsNeeded(curOutVar, discreteVarIndices, outBlockIndex, restBlocksToBeChecked, DEVS_blocks_inVars,DEVS_struct_inLinks, DEVS_struct_inVars, curOutVarLinks);
      then
        (curOutVarLinks, DEVS_struct_inLinks, DEVS_struct_inVars);
    case (_,_,_,_,_,_,_,_)
      equation
        print("- BackendQSS.findWhereOutVarsIsNeeded failed\n");
      then
        fail();
  end matchcontinue;
end findWhereOutVarIsNeeded;


protected function qssIntegratorsInOutVars
"function: qssIntegratorsInOutVars
  generates the input/output variable names for the qss integrator blocks.
  author: florosx 
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
      
    case ({},(DEVS_blocks_outVars, DEVS_blocks_inVars)) then ((listReverse(DEVS_blocks_outVars), listReverse(DEVS_blocks_inVars)));
        
    case (cur_state::rest_states, (DEVS_blocks_outVars, DEVS_blocks_inVars))
      equation
        cur_state_neg = -cur_state;
        DEVS_blocks_outVars = {cur_state_neg}::DEVS_blocks_outVars;
        DEVS_blocks_inVars = {cur_state}::DEVS_blocks_inVars;
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
      
    case ( {}, incidenceMat, ass2, (DEVS_blocks_outVars, DEVS_blocks_inVars)) then ((listReverse(DEVS_blocks_outVars), listReverse(DEVS_blocks_inVars)));
                  
    case (curBlock_eq::restBlocks_eq, incidenceMat, ass2, (DEVS_blocks_outVars, DEVS_blocks_inVars) )
      equation
        curBlock_flatEq = Util.listFlatten(curBlock_eq);            
        (varIndicesIn_temp, varIndicesOut_temp) = selectVarsInOut(curBlock_flatEq, incidenceMat, ass2, {},{});
        varIndicesIn_temp = findUniqueVars(varIndicesIn_temp,{});        
        DEVS_blocks_outVars = varIndicesOut_temp::DEVS_blocks_outVars "select OUT variables";
        DEVS_blocks_inVars = varIndicesIn_temp::DEVS_blocks_inVars "select IN variables";      
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
      
    case({} , inList_temp) then listReverse(inList_temp);
    
    case(head::rest_list, inList_temp)
      equation
        true = listMember(head, rest_list);
        inList_temp = findUniqueVars(rest_list, inList_temp);
      then
         (inList_temp);
         
     case(head::rest_list, inList_temp)
      equation
        false = listMember(head, rest_list);
        inList_temp = head::inList_temp;
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
    case ( {}, incidenceMat, ass2, varIndicesIn_temp, varIndicesOut_temp) then (listReverse(varIndicesIn_temp), listReverse(varIndicesOut_temp));
               
    case (curEq::restEq, incidenceMat, ass2, varIndicesIn_temp, varIndicesOut_temp)
      equation      
        curRow = incidenceMat[curEq];     
        curOutVar = ass2[curEq];
        (ind, curInVars) = findAndRemoveElementInList(0,curRow,curOutVar);        
        varIndicesOut_temp = curOutVar::varIndicesOut_temp;        
        varIndicesIn_temp = listAppend(curInVars, varIndicesIn_temp);       
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
      DAE.CallAttributes attr;
    case ((e as (DAE.CALL(path = Absyn.IDENT(name = "sample"), expLst=expLst, attr=attr)),i),_) 
    equation
      zce = Util.listMap(zeroCrossings,extractExpresionFromZeroCrossing);
      // Remove extra argument to sample since in the zce list there is none
      expLst2 = Util.listFirst(Util.listPartition(expLst,2));
      e = DAE.CALL(Absyn.IDENT("sample"),expLst2,attr);
      index = listExpPos(zce,e,0);
      result = ((DAE.CALL(Absyn.IDENT("samplecondition"), {DAE.ICONST(index)}, DAE.callAttrBuiltinBool),i));
      then result;
    case ((e as DAE.RELATION(_,_,_,_,_),i),_) 
    equation
      zce = Util.listMap(zeroCrossings,extractExpresionFromZeroCrossing);
      index = listExpPos(zce,e,0);
      then ((DAE.CALL(Absyn.IDENT("condition"), {DAE.ICONST(index)}, DAE.callAttrBuiltinBool),i));
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
          then ((DAE.CALL(Absyn.IDENT("condition"), {DAE.ICONST(index)}, DAE.callAttrBuiltinBool), (zce,index)));
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
  Finds for each state derivative the equations that are needed in order to compute it.
  It is based on the traversal done in BackendDAEUtil.generateStatePartition().
  author: florosx - May 2011
"
  input BackendDAE.StrongComponents inComps;
  input BackendDAE.BackendDAE inBackendDAE;
  input array<BackendDAE.Value> inIntegerArray1;
  input array<BackendDAE.Value> inIntegerArray2;
  input BackendDAE.IncidenceMatrix inIncidenceMatrix;
  input BackendDAE.IncidenceMatrixT inIncidenceMatrixT;
  output list<list<Integer>> sortedEquationsIndices;
 
algorithm
  (sortedEquationsIndices):=
  matchcontinue (inComps,inBackendDAE,inIntegerArray1,inIntegerArray2,inIncidenceMatrix,inIncidenceMatrixT)
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
      BackendDAE.StrongComponents comps;
      list<list<Integer>> arrList;
      
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
  input BackendDAE.StrongComponents inComps;
  input list<list<Integer>> inListAcc;
  output list<list<Integer>> outList;
algorithm
  (outList) :=
  matchcontinue (inList,inComps,inListAcc)
    local
      array<Integer> ass1,ass2;
      list<list<Integer>> localAccList;
      list<list<Integer>> restList;
      BackendDAE.StrongComponents comps;
      list<Integer> comps2,elem,firstList;
    case ({},_,localAccList) then localAccList;
    case (firstList :: restList,comps,localAccList)      
      equation 
        comps2 = getStrongComponentsEqnFlat(comps,{});
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

protected function getStrongComponentsEqnFlat
"function: getStrongComponentsEqnFlat
  author: Frenkel TUD"
  input BackendDAE.StrongComponents inComp;
  input list<Integer> accCompsFlat;
  output list<Integer> compsFlat;
algorithm
  compsFlat:=
  matchcontinue (inComp,accCompsFlat)
    local
      BackendDAE.StrongComponents comps;
      BackendDAE.StrongComponent comp;
      list<Integer> eqns,elst,elst1,l;
    case ({},elst) then elst;
    case (comp::comps,elst) 
      equation
        (eqns,_) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);
        elst1 = listAppend(elst, eqns);
        l = getStrongComponentsEqnFlat(comps,elst1);
      then
        l;        
    else
      equation
         print("- BackendQSS.getStrongComponentsEqnFlat failed\n");
      then
        fail();
  end matchcontinue;
end getStrongComponentsEqnFlat;

public function mapEquationsInBLTBlocks_tail
"function: mapEquationsInBLTBlocks_tail
  author: florosx
"    
   input list<Integer> inIntegerLst1;
   input BackendDAE.StrongComponents inIntegerLstLst1;
   input BackendDAE.StrongComponents inIntegerLstLst2;
   output BackendDAE.StrongComponents cur_state_blocks;
   
algorithm 
  cur_state_blocks :=
  matchcontinue (inIntegerLst1, inIntegerLstLst1, inIntegerLstLst2)    
    local
      list<list<Integer>> sorted_indices;   
      list<Integer> state_equations, rest_eq, remain_state_equations;
      BackendDAE.StrongComponent cur_block;
      BackendDAE.StrongComponents rest_blocks, state_blocks; 
      Integer cur_eq;
      
    case (_, {}, state_blocks) then listReverse(state_blocks);
    case ({}, _, state_blocks) then listReverse(state_blocks);
                       
    case (cur_eq :: rest_eq , cur_block :: rest_blocks , state_blocks)
      equation
        true = eqnInComp(cur_eq, cur_block);
        state_blocks = cur_block::state_blocks;
        remain_state_equations = removeRedundantEquations(rest_eq, cur_block, {});
        state_blocks = mapEquationsInBLTBlocks_tail(remain_state_equations, rest_blocks, state_blocks);
      then
        (state_blocks);
    case (cur_eq :: rest_eq , cur_block :: rest_blocks , state_blocks)
      equation
        false = eqnInComp(cur_eq, cur_block);
        state_equations = cur_eq::rest_eq;
        state_blocks = mapEquationsInBLTBlocks_tail(state_equations, rest_blocks, state_blocks);
      then
        (state_blocks);
    else
      equation
        print("- BackendQSS.mapEquationsInBLTBlocks_tail failed\n");
      then
        fail();
   end matchcontinue;
end mapEquationsInBLTBlocks_tail;

protected function eqnInComp
"function: eqnInComp
  author: Frenkel TUD"
  input Integer inInteger;
  input BackendDAE.StrongComponent inComp;
  output Boolean outBool;
algorithm
  outBool:=
  matchcontinue (inInteger,inComp)
    local
      Integer e,i;
      list<Integer> elst;
      Boolean b;
    case (i,BackendDAE.SINGLEEQUATION(eqn=e))
      equation
         b = intEq(i,e);
      then
        b;
    case (i,inComp)
      equation
        (elst,_) = BackendDAETransform.getEquationAndSolvedVarIndxes(inComp);
        b = listMember(i,elst);        
      then
        b;   
    else
      then
        false;
  end matchcontinue;
end eqnInComp;

public function removeRedundantEquations
"function: removeRedundantEquations
  author: florosx
"    
   input list<Integer> inIntegerLst1;
   input BackendDAE.StrongComponent inIntegerLst2;
   input list<Integer> inIntegerLst3;
   output list<Integer> remaining_equations;
   
algorithm 
  remaining_equations :=
  matchcontinue (inIntegerLst1, inIntegerLst2, inIntegerLst3)    
    local  
      BackendDAE.StrongComponent cur_block;
      list<Integer> rest_eq, non_redundant_eq;
      Integer cur_eq;
   case ({},_,non_redundant_eq)
      equation
      then(non_redundant_eq);
    case (cur_eq :: rest_eq , cur_block, non_redundant_eq)
      equation
        true = eqnInComp(cur_eq, cur_block);
        non_redundant_eq = removeRedundantEquations(rest_eq, cur_block, non_redundant_eq);
      then
         (non_redundant_eq);
    case (cur_eq :: rest_eq , cur_block, non_redundant_eq)
      equation
        false = eqnInComp(cur_eq, cur_block);
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

protected function getEqnIndxFromComp
"function: getEqnIndxFromComp
  author: Frenkel TUD"
  input BackendDAE.StrongComponent inComp;
  output list<Integer> outEqnIndexLst;
algorithm
  (outEqnIndexLst,_):= BackendDAETransform.getEquationAndSolvedVarIndxes(inComp);
end getEqnIndxFromComp;

////////////////////////////////////////////////////////////////////////////////////////////////////
/////  PART - UTIL FUNCTIONS
////////////////////////////////////////////////////////////////////////////////////////////////////

public function removeEmptyElements
"function: removeEmptyElements
  Removes empty elements from a list
  author: florosx - May 2011
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
    
    case ({}, cur_list) then listReverse(cur_list);
      
    case (head::rest_list, cur_list)
      equation
        true = Util.isListNotEmpty(head);
        cur_list = head::cur_list;
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
  Prints the elements of a list of integers
  author: florosx
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
  Prints the elements of a list of lists of integers
  author: florosx
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
  Dumps all 4 DEVS structures: outLinks, outNames, inLinks, inNames
  author: florosx
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
  Dumps the incidence matrix for a DEVS structure
  author: florosx
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
  Helper function for dympMyDEVSstruct
  author: florosx
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

public function getDiscreteIndices 
"function: getDiscreteIndices 
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
        false = BackendVariable.isVarDiscrete(var1);
        stateIndices = getDiscreteIndices(rest, stateIndices2, loopIndex+1);  
      then
        stateIndices;
    case (var1::rest, stateIndices2, loopIndex)
      equation     
        true = BackendVariable.isVarDiscrete(var1);
        stateIndices2 = listAppend(stateIndices2, {loopIndex});
        stateIndices2 = getDiscreteIndices(rest, stateIndices2, loopIndex+1);  
      then
        stateIndices2;
  end matchcontinue;
end getDiscreteIndices;



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
        true = listMember(head, rest_list);
        inList_temp = removeRedundantElements(rest_list, inList_temp);
      then
         (inList_temp);
     
     case(head::rest_list, inList_temp)
      equation
        false = listMember(head, rest_list);
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
  input BackendDAE.StrongComponents comps;
  input BackendDAE.BackendDAE dlow;
  input array<Integer> ass1, ass2;
  output list<SimCode.SimEqSystem> out;
algorithm
  out := 
    match (comps,dlow,ass1,ass2)
      local
        list<SimCode.SimEqSystem> out2;
      case (_,_,_,_)
      equation
        out2 = SimCode.createEquations(false, false, false, false, false, dlow, ass1, ass2, comps, {});
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
       true = listMember(inVar, cur_port_inputs); 
      then (loopIndex);
    
    case(loopIndex, cur_port_inputs::rest_inputs, inVar)
      equation
       false = listMember(inVar, cur_port_inputs); 
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
  input list<BackendDAE.StrongComponents> state_DEVSblocks1;
  input list<list<Integer>> mappedEquations1;
  input Integer blockIndex1;
  
  output list<list<Integer>> mappedEquations; 
algorithm
  (mappedEquations):=
  matchcontinue(state_DEVSblocks1, mappedEquations1, blockIndex1)
     local
       
       BackendDAE.StrongComponents cur_state_blocks;
       list<BackendDAE.StrongComponents>rest_blocks;
       list<Integer> cur_state_flat;
       list<list<Integer>> mappedEquations_intermed;
       Integer blockIndex;
       
       case({}, mappedEquations_intermed, blockIndex)
         equation
           //END OF RECURSION
       then (mappedEquations_intermed);
        
       case (cur_state_blocks :: rest_blocks, mappedEquations_intermed, blockIndex)
         equation
            cur_state_flat = getStrongComponentsEqnFlat(cur_state_blocks,{});
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
"function: constructs an empty list of lists
  author: florosx
"
  input Integer nEquations; 
  input list<list<Integer>> tempList;
  
  output list<list<Integer>> emptyListofLists; 
  
algorithm
  (emptyListofLists):=
  matchcontinue(nEquations, tempList)
       
     case(0, tempList) then listReverse(tempList);
         
     case (nEquations, tempList)
       equation
          tempList = {}::tempList;           
          emptyListofLists = constructEmptyList(nEquations-1, tempList);
       then
          (emptyListofLists);  
  end matchcontinue;
end constructEmptyList;

public function constructEmptyListList 
"function: constructs an empty list of lists
  author: florosx
"
  input Integer nEquations; 
  input list<list<list<Integer>>> tempList;
  
  output list<list<list<Integer>>> emptyListofLists; 
  
algorithm
  (emptyListofLists):=
  matchcontinue(nEquations, tempList)
       
     case(0, tempList) then listReverse(tempList);
         
     case (nEquations, tempList)
       equation
          tempList = {}::tempList;           
          emptyListofLists = constructEmptyListList(nEquations-1, tempList);
       then
          (emptyListofLists);  
  end matchcontinue;
end constructEmptyListList;



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
    
    case (_, {}, outListTemp) then listReverse(outListTemp);

    case (toRemove, head::rest, outListTemp)
      equation
        temp = Util.listSetDifferenceOnTrue(head,toRemove,intEq);
        outListTemp = temp::outListTemp;
        outListTemp = removeListFromListsOfLists(toRemove, rest, outListTemp);
      then outListTemp;
  end matchcontinue;
end removeListFromListsOfLists;

public function createIncreasingList
  input Integer startElement;
  input Integer nElements;
  input list<Integer> tempList;
  output list<Integer> outList;
  
algorithm
  outList := 
  matchcontinue(startElement, nElements, tempList)
    local
    case (startElement, 0, tempList)
      equation
      then (tempList);
      
    case (startElement, nElements, tempList)
      equation
        tempList = listAppend(tempList, {startElement});
        tempList = createIncreasingList(startElement+1, nElements-1, tempList);
      then (tempList);
  end matchcontinue;
end createIncreasingList;

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

public function getAllInputs
"function: getAllInputs
  Returns the list of invars of a DEVS structure per block as a expanded list
  where {0,1,0,2,1,5} means block 0 inputs var 1 and 2 and block 1 inputs var 5
  author: FB"
  input QSSinfo qssInfo;
  output list<Integer> vars_tuple;
algorithm
  vars_tuple :=
    match (qssInfo)
      local
        array<list<list<Integer>>> inVars "input connections for each DEVS block";
      case QSSINFO(DEVSstructure=DEVS_STRUCT(inVars=inVars))
      then convertArrayToFlatList(inVars,1,{});
    end match;
end getAllInputs;

protected function listPair
"function: listPair
  This function takes a list of Int and an Int an returs the list with the integer before every element
  Example: ({1,2,3},4) -> {4,1,4,2,4,3}
  author: FB"
  input list<Integer> l;
  input Integer i;
  output list<Integer> o;
algorithm
  o :=
    match (l,i)
      local list<Integer> rest;
            Integer h;
      case ((h::rest),i)
        equation
          rest = listPair(rest,i);
          rest = listAppend({i,h},rest);
        then rest; 
      case ({},_)
        then {};
    end match;
end listPair;
         
          
protected function convertArrayToFlatList
"function: convertArrayToFlatList
  This function converts the array<list<list<Integer>>> to a flat Int list
  author: FB"
  input array<list<list<Integer>>> vars;
  input Integer index;
  input list<Integer> res;
  output list<Integer> vars_tuple;
algorithm
  vars_tuple := 
    matchcontinue (vars,index,res)
      local list<list<Integer>> v;
            list<Integer> vf;
    case (_,_,_)
      equation
        true = (index <= arrayLength(vars));
        v = vars[index];
        vf = Util.listMap(Util.listFlatten(v),intAbs);
        vf = Util.listFilter(vf,isPositive);
        vf = Util.listMap1(vf,intSub,1);
        vf = listPair(vf,index-1);
        vf = listAppend(res,convertArrayToFlatList(vars,index+1,vf));
        then vf;
    case (_,_,_)
      equation
        false = (index <= arrayLength(vars));
        then res;
    end matchcontinue;
end convertArrayToFlatList;


public function getAllOutputs
"function: getAllOutputs
  Returns the list of outvars of a DEVS structure per block as a expanded list
  where {0,1,0,2,1,5} means block 0 outputs var 1 and 2 and block 1 outputs var 5
  author: FB"
  input QSSinfo qssInfo;
  output list<Integer> vars_tuple;
algorithm
  vars_tuple :=
    match (qssInfo)
      local
        array<list<list<Integer>>> outVars "output connections for each DEVS block";
      case QSSINFO(DEVSstructure=DEVS_STRUCT(outVars=outVars))
      then convertArrayToFlatList(outVars,1,{});
    end match;
end getAllOutputs;

protected function replaceRowsArray
"function: getListofZeroCrossings
  Takes as input the DAE and extracts the zero-crossings as well as the zero crosses that are 
  connected to sample statements.
  author: florosx
"
  input BackendDAE.IncidenceMatrix incidenceMat;
  input list<Integer> rowsInd;
  input list<list<Integer>> newRows;
  output BackendDAE.IncidenceMatrix incidenceMatOut;

algorithm
  incidenceMatOut := matchcontinue (incidenceMat, rowsInd, newRows)
    local
      Integer cur_ind;
      list<Integer> rest_ind, cur_row;
      list<list<Integer>> rest_rows;
             
    case(incidenceMat,{},{})
      equation
         // END OF ZERO CROSSINGS
      then (incidenceMat);
      
    case (incidenceMat, cur_ind::rest_ind, cur_row::rest_rows )
      equation
        incidenceMat = arrayUpdate(incidenceMat, cur_ind, cur_row); 
        incidenceMat = replaceRowsArray(incidenceMat, rest_ind, rest_rows);
      then
        (incidenceMat);
    case (_,_,_)
      equation
        print("- BackendQSS.replaceRowsArray failed\n");
      then
        fail();   
  end matchcontinue;
end replaceRowsArray;

protected function mergeListsLists
"function: mergeListsLists
  Merges two lists of lists according to the indices supplied
  author: florosx
" 
  input list<Integer> allInds; 
  input list<Integer> indList1;
  input list<list<Integer>> inList1;
  input list<Integer> indList2;
  input list<list<Integer>> inList2;
  input list<list<Integer>> outListIn;
  output list<list<Integer>> outList;
 
algorithm
  (outList):=
  matchcontinue (allInds, indList1, inList1, indList2, inList2, outListIn)
    local
      Integer curInd, foundInd;
      list<Integer> restInds, curList;
      
    
    case ({},_, _, _, _, outListIn)
      equation        
      then
        (outListIn);
    case (curInd::restInds, indList1, inList1, indList2, inList2, outListIn)
      equation        
        foundInd = findElementInList(0, listLength(indList1), indList1, curInd);
        false = intEq(foundInd,-1)"If the current element is from the first list";
        curList = listNth(inList1, foundInd);
        outListIn = listAppend(outListIn, {curList});
        outListIn = mergeListsLists(restInds, indList1, inList1, indList2, inList2, outListIn);
    then
       (outListIn);
    case (curInd::restInds, indList1, inList1, indList2, inList2, outListIn)
      equation        
        foundInd = findElementInList(0, listLength(indList2), indList2, curInd);
        false = intEq(foundInd,-1)"If the current element is from the first list";
        curList = listNth(inList2, foundInd);
        outListIn = listAppend(outListIn, {curList});
        outListIn = mergeListsLists(restInds, indList1, inList1, indList2, inList2, outListIn);
    then
       (outListIn);   
    case (_,_,_,_,_,_)
      equation
        print("- BackendQSS.mergeListsLists failed\n");
      then
        fail();
  end matchcontinue;
end mergeListsLists;


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

////////////////////////////////////////////////////////////////////////////////////////////////////
/////  END OF PACKAGE
////////////////////////////////////////////////////////////////////////////////////////////////////
end BackendQSS;

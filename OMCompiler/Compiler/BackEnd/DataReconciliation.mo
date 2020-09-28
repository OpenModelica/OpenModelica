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

encapsulated package DataReconciliation
" file:        dataReconciliation.mo
  package:     dataReconciliation
  description: performs the extractionAlgorithm for dataReconciliation Problem"


public import BackendDAE;
public import DAE;
public import SymbolicJacobian;
public import BackendDump;
public import ExpressionDump;

protected
import BackendDAEUtil;
import BackendEquation;
import BackendVariable;
import ComponentReference;
import Expression;
import Error;
import Flags;
import DAEDump;
import Sorting;
import List;
import Matching;
import Util;
import System;

protected type ExtAdjacencyMatrixRow = tuple<Integer,list<Integer>>;
protected type ExtAdjacencyMatrix = list<ExtAdjacencyMatrixRow>;

public constant String UNDERLINE = "==========================================================================";

public function extractionAlgorithm
  "runs the extraction Algorithm for dataReconciliation
  Which return two sets of equations namely SET-C and SET-S"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystem currentSystem;
  BackendDAE.EquationArray newOrderedEquationArray, outOtherEqns, outResidualEqns;
  list<BackendDAE.Equation> newEqnsLst, setC_Eq, setS_Eq, residualEquations;
  BackendDAE.AdjacencyMatrix adjacencyMatrix, newAdjacencyMatrix;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn, match1, match2;
  list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  Integer varCount, eqCount, setEBLTRank, eqIndex;
  list<Integer> matchedEqsLst, unMatchedEqsLst, unMatchedEqsLstCorrectIndex, approximatedEquations, constantEquations, tempSetC, setC, tempSetS, setS, boundaryConditionEquations;
  list<list<Integer>> s_BLTBlocks, e_BLTBlocks, allBlocks, tmpAdjacencyMatrix;
  list<list<String>> allBlocksStatusVarInfo;
  list<tuple<Integer, BackendDAE.Equation>> e_BLT_EquationsWithIndex;
  ExtAdjacencyMatrix eBltAdjacencyMatrix, sBltAdjacencyMatrix, setS_BLTAdjacencyMatrix;
  list<tuple<Integer, Integer>> e_BLTSolvedEqsAndVars;
  list<tuple<list<Integer>, Integer>> e_BLTBlockRanks, s_BLTBlockRanks;
  list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>, list<tuple<list<String>, Integer>>>> s_BLTBlockTargetInfo;
  list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>, list<tuple<list<String>, Integer>>, list<Integer>, list<Integer>, list<Integer>>> predecessorBlockTargetInfo;
  list<BackendDAE.Var> paramVars, setSVars, residualVars;
  list<DAE.ComponentRef> cr_lst;
  BackendDAE.Jacobian simCodeJacobian;
  BackendDAE.Shared shared;
  String str, modelicaOutput, modelicaFileName;

  list<Integer> allVarsList, knowns, unknowns, boundaryConditionVars, exactEquationVars, extractedVarsfromSetS, constantVars, knownVariablesWithEquationBinding, boundaryConditionTaggedEquationSolvedVars, unknownVarsInSetC;
  BackendDAE.Variables inputVars, outDiffVars, outOtherVars, outResidualVars;

  Boolean debug = false;

algorithm

  if Flags.isSet(Flags.DUMP_DATARECONCILIATION) then
    debug := true;
  end if ;

  {currentSystem} := inDAE.eqs;
  shared := inDAE.shared;

  print("\nModelInfo: " + shared.info.fileNamePrefix + "\n" + UNDERLINE + "\n\n");
  BackendDump.dumpVariables(currentSystem.orderedVars, "OrderedVariables");
  BackendDump.dumpEquationArray(currentSystem.orderedEqs, "OrderedEquation");
  //BackendDump.dumpVariables(shared.globalKnownVars, "GlobalKnownVars");

  (currentSystem, shared) := setBoundaryConditionEquationsAndVars(currentSystem, inDAE.shared, debug);

  if debug then
    BackendDump.dumpVariables(currentSystem.orderedVars, "Updated-OrderedVariables-withBoundaryConditionVars");
    BackendDump.dumpEquationArray(currentSystem.orderedEqs, "Updated-OrderedVariables-withBoundaryConditionEqs");
    BackendDump.dumpVariables(shared.globalKnownVars, "Updated-GlobalKnownVars-withBoundaryConditionVarsRemoved");
  end if;

  allVarsList := List.intRange(BackendVariable.varsSize(currentSystem.orderedVars));
  // get the adjacency matrix of the Current System Square System
  (adjacencyMatrix, _, _, _) := BackendDAEUtil.adjacencyMatrixScalar(currentSystem, BackendDAE.NORMAL(), NONE(), BackendDAEUtil.isInitializationDAE(shared));

  // extract knowns, BoundaryConditions and exactEquationVars
  (knowns, boundaryConditionVars, exactEquationVars) := getVariablesBlockCategories(currentSystem.orderedVars, allVarsList);

  if debug then
    print("\nVariablesCategories\n=============================");
    print("\nknownVars                    :" + dumplistInteger(knowns));
    print("\nboundaryConditionVars        :" + dumplistInteger(boundaryConditionVars));
    print("\nexactEquationVars            :" + dumplistInteger(exactEquationVars));
    print("\nadjacencyMatrix              :" + anyString(adjacencyMatrix));
    print("\n");
  end if;

  allVarsList := List.intRange(BackendVariable.varsSize(currentSystem.orderedVars));
  // getEquations with known bindings
  knownVariablesWithEquationBinding := getUncertainRefineVariablesBindedEquations(adjacencyMatrix, knowns);

  if debug then
    print("\nEquations with KnownBindings:\n===================================");
    print("\nAdjacency Matrix                     :" + anyString(adjacencyMatrix));
    print("\nLength of Adjacency Matrix           :" + intString(arrayLength(adjacencyMatrix)));
    print("\nList of known equation with bindings :" + anyString(knownVariablesWithEquationBinding));
    print("\n");
  end if;

  // inverse the Modelica Model by introducing new set of equations
  newEqnsLst := inverseModelicaModel(currentSystem.orderedVars, knownVariablesWithEquationBinding);

  // add the new equations to the equation system to make the system overdetermined
  currentSystem.orderedEqs := BackendEquation.merge(currentSystem.orderedEqs, BackendEquation.listEquation(newEqnsLst));
  BackendDump.dumpEquationArray(currentSystem.orderedEqs, "OverDetermined-System-Equations");

  // get the adjacency matrix for the overdetermined equation system
  (adjacencyMatrix, _, mapEqnIncRow, mapIncRowEqn) := BackendDAEUtil.adjacencyMatrixScalar(currentSystem, BackendDAE.NORMAL(), NONE(), BackendDAEUtil.isInitializationDAE(shared));
  varCount := currentSystem.orderedVars.numberOfVars;
  eqCount := BackendEquation.equationArraySize(currentSystem.orderedEqs);

  if debug then
    print("\nOverDetermined-Systems-Information : \n====================================\n");
    print("\nAdjacency Matrix     :" + anyString(adjacencyMatrix));
    print("\nNumber of Vars       :" + intString(varCount));
    print("\nNumber of Equations  :" + intString(eqCount));
    print("\n\n");
  end if;

  // Perform limited matching on the overdermined System to get subset of equations which are not matched to form the E-BLT
  (match1, match2) := Matching.RegularMatching(adjacencyMatrix, varCount, eqCount);

  BackendDump.dumpMatching(match1);

  // get list of solved Vars and equations
  (solvedEqsAndVarsInfo, matchedEqsLst) := getSolvedEquationAndVarsInfo(match1);
  // Find the list of equations which are not matched (i.e) Equations which forms the E-BLT
  unMatchedEqsLst := List.setDifference(List.intRange(eqCount), matchedEqsLst);
  //unMatchedEqsLst := {105, 138, 143, 144, 147, 148};
  // get the actual index of the Equation
  unMatchedEqsLstCorrectIndex := List.unique(List.map1r(unMatchedEqsLst, listGet, arrayList(mapIncRowEqn)));

  if debug then
    print("\nFinding unmatched subset of equations : \n=========================================\n");
    print("\nSolvedEqsAndVarsInfo                   :" + anyString(solvedEqsAndVarsInfo));
    print("\nList of Equations                      :" + intString(BackendEquation.getNumberOfEquations(currentSystem.orderedEqs)));
    print("\nMatchedEquationsLst                    :" + anyString(List.sort(matchedEqsLst, intGt)));
    print("\nSizeofMatchedEquationLST               :" + intString(listLength(matchedEqsLst)));
    print("\nUnMatchedSubSetOfEquations             :" + anyString(unMatchedEqsLst));
    print("\nUnMatchedSubSetOfEquationsMappedIndex  :" + anyString(unMatchedEqsLstCorrectIndex));
    print("\n");
  end if;

  //unMatchedEquations := BackendEquation.getList(unMatchedEqsLstCorrectIndex, currentSystem.orderedEqs);

  // Construct the E-BLT equations with index and rank from the unmatchedEquation List
  (e_BLT_EquationsWithIndex, eBltAdjacencyMatrix, e_BLTSolvedEqsAndVars, e_BLTBlocks, e_BLTBlockRanks) := setEBLTEquationsWithIndexAndRank(unMatchedEqsLst, unMatchedEqsLstCorrectIndex, currentSystem.orderedEqs, adjacencyMatrix);

  BackendDump.dumpEquationList(List.map1r(unMatchedEqsLstCorrectIndex, BackendEquation.get, currentSystem.orderedEqs), "E-BLT-Equations " + dumplistInteger(unMatchedEqsLst));

  if debug then
    print("\nE-BLT Information \n================");
    print("\nE-BLT-Blocks   :" + anyString(e_BLTBlocks));
    print("\nE-BLT-Blocks-with ranks   :" + anyString(e_BLTBlockRanks));
    print("\nE-BLT-Adjacency-Matrix    :" + anyString(eBltAdjacencyMatrix));
    print("\nE_BLTSolvedEqsAndVars     :" + anyString(e_BLTSolvedEqsAndVars));
    print("\n");
  end if;

  /* Prepare the S-BLT System */
  // delete the unmatched equations from the current system
  currentSystem := deleteEquationsFromEqSyst(currentSystem, unMatchedEqsLstCorrectIndex);
  varCount := currentSystem.orderedVars.numberOfVars;
  eqCount  := BackendEquation.equationArraySize(currentSystem.orderedEqs);

  //BackendDump.dumpEquationList({BackendEquation.get(newOrderedEquationArray, 3)}, "Test get equation 3");
  BackendDump.dumpEquationArray(currentSystem.orderedEqs, "reOrdered-Equations-after-removal");
  BackendDump.dumpVariables(currentSystem.orderedVars,"reOrderedVariables");

  // get the new adjacency matrix with new-reordered equations(square system) after removing the equations
  (adjacencyMatrix, _, mapEqnIncRow, mapIncRowEqn) := BackendDAEUtil.adjacencyMatrixScalar(currentSystem, BackendDAE.NORMAL(), NONE(), BackendDAEUtil.isInitializationDAE(shared));

  // Perform the matching on the new Square-System of equations
  (match1, match2) := Matching.RegularMatching(adjacencyMatrix, varCount, eqCount);
  BackendDump.dumpMatching(match1);

  s_BLTBlocks := Sorting.Tarjan(adjacencyMatrix, match1);  // run the tarjan algorithm to create the S-BLT on the Square-System
  sBltAdjacencyMatrix := getSBLTAdjacencyMatrix(adjacencyMatrix);  // get adjacency matrix with equations and list of variables present
  (solvedEqsAndVarsInfo, _) := getSolvedEquationAndVarsInfo(match1);     // get the solved Equations and Vars information from the new matching
  s_BLTBlockRanks := List.toListWithPositions(s_BLTBlocks);

  if debug then
    print("\nS-BLT-Information\n================");
    print("\nS-BLT Number of Vars       :" + intString(varCount));
    print("\nS-BLT Number of Equations  :" + intString(eqCount));
    print("\nS-BLT-Blocks               :" + anyString(s_BLTBlocks));
    print("\nS-BLT-Blocks-with ranks    :" + anyString(s_BLTBlockRanks));
    print("\nS-BLT Adjacency Matrix     :" + anyString(sBltAdjacencyMatrix));
    print("\nS_BLTSolvedEqsAndVars      :" + anyString(solvedEqsAndVarsInfo));
    print("\n\n");
  end if;

  /* Merge E-BLT blocks with S-BLT */
  s_BLTBlocks := listAppend(s_BLTBlocks, e_BLTBlocks) annotation(__OpenModelica_DisableListAppendWarning=true);  // append the E-BLT blocks to the end with S-BLT
  s_BLTBlockRanks := listAppend(s_BLTBlockRanks, e_BLTBlockRanks) annotation(__OpenModelica_DisableListAppendWarning=true); // append E-BLT block ranks with S-BLT block ranks
  sBltAdjacencyMatrix := listAppend(sBltAdjacencyMatrix, eBltAdjacencyMatrix) annotation(__OpenModelica_DisableListAppendWarning=true);  // append the E-BLT Adjacency matrix with S-BLT Adjacency matrix
  solvedEqsAndVarsInfo := listAppend(solvedEqsAndVarsInfo, e_BLTSolvedEqsAndVars) annotation(__OpenModelica_DisableListAppendWarning=true);  // append the E-BLT Solved Equations and Vars to S-BLT vars


  if debug then
    print("\nCombined S-BLT and E-BLT Information \n================================");
    print("\nCombined S-BLT-Blocks and E-BLT-Blocks                :" + anyString(s_BLTBlocks));
    print("\nCombined S-BLT-Blocks and E-BLT-Blocks with Ranks     :" + anyString(s_BLTBlockRanks));
    print("\nCombined Adjacency Matrix with S-BLT and E-BLT        :" + anyString(sBltAdjacencyMatrix));
    print("\nCombined SolvedEquationsVarsInfo with S-BLT and E-BLT :" + anyString(solvedEqsAndVarsInfo));
    print("\n");
  end if;

  // dump BLT BLOCKS
  dumpListList(s_BLTBlocks,"BLT_BLOCKS");

  // Extract equations tagged as annotation(__OpenModelica_BoundaryCondition = true) and annotation(__OpenModelica_ApproximatedEquation = true)
  (approximatedEquations, boundaryConditionEquations) := getEquationsTaggedApproximatedOrBoundaryCondition(BackendEquation.equationList(currentSystem.orderedEqs), 1);

  if debug then
    BackendDump.dumpEquationList(List.map1r(approximatedEquations, BackendEquation.get, currentSystem.orderedEqs), "ApproximatedEquations");
    BackendDump.dumpEquationList(List.map1r(boundaryConditionEquations, BackendEquation.get, currentSystem.orderedEqs), "boundaryConditionEquations");
  end if;

  // get the Index mapping for approximated and constant equations
  approximatedEquations := List.flatten(List.map1r(approximatedEquations, listGet, arrayList(mapEqnIncRow)));
  boundaryConditionEquations := List.flatten(List.map1r(boundaryConditionEquations, listGet, arrayList(mapEqnIncRow)));

  if debug then
    print("\nApproximated and BoundaryCondition Equation Indexes :\n===========================================");
    print("\nApproximatedEquationIndexes      :" + dumplistInteger(approximatedEquations));
    print("\nBoundayConditionEquationIndexes  :" + dumplistInteger(boundaryConditionEquations));
    print("\n");
  end if;

  // extract the constant variables
  // constantVars := getExactConstantVariables(constantEquations, solvedEqsAndVarsInfo);

  // extract boundaryConditionVariables
  boundaryConditionTaggedEquationSolvedVars := getBoundaryConditionVariables(boundaryConditionEquations, solvedEqsAndVarsInfo);

  // dump BoundaryCondition Equation Vars
  if debug then
    BackendDump.dumpVarList(List.map1r(listReverse(boundaryConditionTaggedEquationSolvedVars), BackendVariable.getVarAt, currentSystem.orderedVars),"boundaryConditionTaggedEquationSolvedVars");
  end if;

  // update the unknown variables without constantVars
  //unknowns := List.setDifferenceOnTrue(unknowns, constantVars, intEq);

  // update the exactEquation vars
  exactEquationVars := List.setDifferenceOnTrue(exactEquationVars, boundaryConditionTaggedEquationSolvedVars, intEq);
  // update the boundaryCondtions vars
  boundaryConditionVars := listAppend(boundaryConditionVars, boundaryConditionTaggedEquationSolvedVars) annotation(__OpenModelica_DisableListAppendWarning=true);

  if debug then
    print("\nUpdatedVariablesCategories\n=============================");
    print("\nknownVars                    :" + dumplistInteger(knowns));
    print("\nboundaryConditionVars        :" + dumplistInteger(boundaryConditionVars));
    print("\nexactEquationVars            :" + dumplistInteger(exactEquationVars));
    print("\n");
  end if;

  (allBlocks, allBlocksStatusVarInfo) := traverseBLTAndUpdateBlockStatus(s_BLTBlocks, knowns, boundaryConditionVars, exactEquationVars, solvedEqsAndVarsInfo);

  if debug then
    dumpBlockStatus(allBlocks, allBlocksStatusVarInfo);
  end if;

  // find the block targets for blocks in S-BLT, as EBLT block targets are not useful for extraction algorithm
  s_BLTBlockTargetInfo := findBlockTargets(allBlocks, allBlocksStatusVarInfo, solvedEqsAndVarsInfo, sBltAdjacencyMatrix, s_BLTBlockRanks, debug);

  if debug then
    dumpBlockTargets(s_BLTBlockTargetInfo);
  end if;

  // find predeccsorblocks
  predecessorBlockTargetInfo := findPredecessorBlocks(s_BLTBlockTargetInfo);
  dumpPredecessorBlocks(predecessorBlockTargetInfo);

  // extract Set-C and Set-S equations using setOperation formula
  (tempSetC, tempSetS) := ExtractEquationsUsingSetOperations(predecessorBlockTargetInfo, e_BLTBlockRanks, approximatedEquations, debug);

  print("\nFINAL SET OF EQUATIONS After Reconciliation \n" + UNDERLINE + "\n" +"SET_C: "+dumplistInteger(tempSetC)+"\n" +"SET_S: "+ dumplistInteger(tempSetS)+ "\n\n" );
  if debug then
    dumpSetSVarsSolvedInfo(tempSetS, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars);
  end if;

  //extractedVarsfromSetS := getVariablesAfterExtraction({}, tempSetS, sBltAdjacencyMatrix);
  //extractedVarsfromSetS := List.setDifferenceOnTrue(extractedVarsfromSetS, knowns, intEq);

  setC := List.unique(getAbsoluteIndexHelper(tempSetC, mapIncRowEqn));
  setS := List.unique(getAbsoluteIndexHelper(tempSetS, mapIncRowEqn));

  setC_Eq := getEquationsFromSBLTAndEBLT(setC, currentSystem.orderedEqs, e_BLT_EquationsWithIndex);
  setS_Eq := getEquationsFromSBLTAndEBLT(setS, currentSystem.orderedEqs, e_BLT_EquationsWithIndex);

  //BackendDump.dumpEquationList(setC_Eq,"SET_C");
  //BackendDump.dumpEquationList(setS_Eq,"SET_S");
  BackendDump.dumpEquationArray(BackendEquation.listEquation(setC_Eq), "SET_C");
  BackendDump.dumpEquationArray(BackendEquation.listEquation(setS_Eq), "SET_S");

  unknownVarsInSetC := getVariablesAfterExtraction(tempSetC, {}, sBltAdjacencyMatrix);
  unknownVarsInSetC := listReverse(List.setDifferenceOnTrue(unknownVarsInSetC, knowns, intEq));

  // get the blt adjacencyMatrix asscoiated with extracted SET-S
  setS_BLTAdjacencyMatrix := getSetSAdjacencyMatrix(sBltAdjacencyMatrix, tempSetS);

  if debug then
    print("\nStart of Extract Minimal Set-S Algorithm\n" + UNDERLINE + "\n");
    print("\nSet-S Adjacency MAtrix : " +  intString(listLength(setS_BLTAdjacencyMatrix)) + "\n" + UNDERLINE + "\n" + anyString(setS_BLTAdjacencyMatrix));
    print("\nS'        : {}");
    print("\nV_C       :" +  dumplistInteger(unknownVarsInSetC) + "\n");
  end if;

  // run the minimal SET-S extraction algorithm
  (_, tempSetS) := extractMinimalSetS(unknownVarsInSetC, setS_BLTAdjacencyMatrix, knowns, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, {}, debug);

  if debug then
    print("\n****End of Minimal extraction Algorithm****\n");
    print("\nSet-S after running minimal extraction algorithm \n" + UNDERLINE + "\n" +"SET_S: "+dumplistInteger(tempSetS)+ "\n\n");
  end if;

  extractedVarsfromSetS := getVariablesAfterExtraction({}, tempSetS, sBltAdjacencyMatrix);
  extractedVarsfromSetS := List.setDifferenceOnTrue(extractedVarsfromSetS, knowns, intEq);

  setC := List.unique(getAbsoluteIndexHelper(tempSetC, mapIncRowEqn));
  setS := List.unique(getAbsoluteIndexHelper(tempSetS, mapIncRowEqn));

  //print("\nFINAL SET OF EQUATIONS After Mapping \n" + UNDERLINE + "\n" +"SET_C: "+dumplistInteger(setC)+"\n" +"SET_S: "+ dumplistInteger(setS)+ "\n\n" );

  setC_Eq := getEquationsFromSBLTAndEBLT(setC, currentSystem.orderedEqs, e_BLT_EquationsWithIndex);
  setS_Eq := getEquationsFromSBLTAndEBLT(setS, currentSystem.orderedEqs, e_BLT_EquationsWithIndex);

  // dump minimal SET-S equations
  BackendDump.dumpEquationArray(BackendEquation.listEquation(setS_Eq), "SET_S_After_Minimal_Extraction");

  // prepare outdiff vars (i.e) variables of interest
  outDiffVars := BackendVariable.listVar(List.map1r(knowns, BackendVariable.getVarAt, currentSystem.orderedVars));
  // set uncertain variables unreplaceable attributes to be true
  outDiffVars := BackendVariable.listVar(List.map1(BackendVariable.varList(outDiffVars), BackendVariable.setVarUnreplaceable, true));

  // prepare set-c residual equations and residual vars
  (_, residualEquations) := BackendEquation.traverseEquationArray(BackendEquation.listEquation(setC_Eq), BackendEquation.traverseEquationToScalarResidualForm, (shared.functionTree, {}));
  (residualEquations, residualVars) := BackendEquation.convertResidualsIntoSolvedEquations(listReverse(residualEquations), "$res_F_", BackendVariable.makeVar(DAE.emptyCref), 1);
  outResidualVars := BackendVariable.listVar(listReverse(residualVars));
  outResidualEqns := BackendEquation.listEquation(residualEquations);

  // prepare set-s other equations
  outOtherEqns := BackendEquation.listEquation(setS_Eq);
  // extract parameters from set-s equations
  paramVars := BackendEquation.equationsVars(outOtherEqns, shared.globalKnownVars);
  //setSVars  := BackendEquation.equationsVars(outOtherEqns, currentSystem.orderedVars);

  // prepare variables stucture from list of extracted equations
  outOtherVars := BackendVariable.listVar(List.map1r(extractedVarsfromSetS, BackendVariable.getVarAt, currentSystem.orderedVars));

  dumpSetSVars(outOtherVars, "Unknown variables in SET_S ");
  //BackendDump.dumpVariables(BackendVariable.listVar(setSVars),"Unknown variables in SET_S_checks ");
  BackendDump.dumpVariables(BackendVariable.listVar(paramVars),"Parameters in SET_S");

  VerifyDataReconciliation(tempSetC, tempSetS, knowns, boundaryConditionVars, sBltAdjacencyMatrix, solvedEqsAndVarsInfo, exactEquationVars, approximatedEquations, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, outOtherVars, setS_Eq);

  if debug then
    BackendDump.dumpVariables(outDiffVars, "Jacobian_knownVariables");
    BackendDump.dumpVariables(outResidualVars, "Jacobian_outResidualVars");
    BackendDump.dumpVariables(outOtherVars, "Jacobian_outOtherVars");
    BackendDump.dumpEquationArray(outResidualEqns, "Jacobian_ResidualEquation");
    BackendDump.dumpEquationArray(outOtherEqns, "Jacobian_other_Equation");
  end if;

  // generate symbolicJacobian matrix F
  (simCodeJacobian, shared) := SymbolicJacobian.getSymbolicJacobian(outDiffVars, outResidualEqns, outResidualVars, outOtherEqns, outOtherVars, shared, outOtherVars, "F", false);

  // put the jacobian also into shared object
  shared.dataReconciliationData := SOME(BackendDAE.DATA_RECON(symbolicJacobian=simCodeJacobian, setcVars=outResidualVars, datareconinputs=outDiffVars));

  // Prepare the final DAE System with Set-C equations as residual equations
  currentSystem := BackendDAEUtil.setEqSystVars(currentSystem, BackendVariable.mergeVariables(outResidualVars, outOtherVars));
  currentSystem := BackendDAEUtil.setEqSystEqs(currentSystem, BackendEquation.merge(outResidualEqns, outOtherEqns));

  inputVars := BackendVariable.listVar(List.map1(BackendVariable.varList(outDiffVars), BackendVariable.setVarDirection, DAE.INPUT()));
  shared := BackendDAEUtil.setSharedGlobalKnownVars(shared, BackendVariable.mergeVariables(shared.globalKnownVars, inputVars));

  // write the list of known variables to the csv file with the headers
  if not System.regularFileExists(inDAE.shared.info.fileNamePrefix + "_Inputs.csv") then
    str := "Variable Names,Measured Value-x,HalfWidthConfidenceInterval,xi,xk,rx_ik\n";
    str := dumpToCsv(str, BackendVariable.varList(outDiffVars));
    System.writeFile(shared.info.fileNamePrefix + "_Inputs.csv", str);
  end if;

  // write the new Reconciled vars and equations to .mo File
  modelicaFileName := "Reconciled_"+ System.stringReplace(shared.info.fileNamePrefix, ".","_");
  modelicaOutput := "/* This is not Complete ThermoSysPro variables and functions needs to be corrected manually */\n";
  modelicaOutput := modelicaOutput + "model " + modelicaFileName ;
  // Variables Declaration section
  modelicaOutput := dumpExtractedVars(modelicaOutput, BackendVariable.varList(outDiffVars), "Variables of Interest");
  modelicaOutput := dumpExtractedVars(modelicaOutput, paramVars, "parameters in SET-S");
  modelicaOutput := dumpResidualVars(modelicaOutput, BackendVariable.varList(outResidualVars), "residualVars");
  modelicaOutput := dumpExtractedVars(modelicaOutput, BackendVariable.varList(outOtherVars), "remaining variables in setS");
  // Equation Declaration section
  modelicaOutput := modelicaOutput + "\nequation";
  modelicaOutput := dumpExtractedEquations(modelicaOutput, outResidualEqns, "set-C Canonical form");
  modelicaOutput := dumpExtractedEquations(modelicaOutput, outOtherEqns, "remaining equations in Set-S");
  modelicaOutput := modelicaOutput + "\nend " + modelicaFileName + ";";
  System.writeFile(modelicaFileName + ".mo", modelicaOutput);

  // update the DAE with new system of equations and vars computed by the dataReconciliation extraction algorithm
  outDAE := BackendDAE.DAE({currentSystem}, shared);
end extractionAlgorithm;

protected function getSetSAdjacencyMatrix
 "return the adjacency matrix associated with set-S"
  input ExtAdjacencyMatrix sBltAdjacencyMatrix;
  input list<Integer> setS;
  output ExtAdjacencyMatrix setS_BltAdjacencyMatrix = {};
protected
  Integer eq;
algorithm
  for i in sBltAdjacencyMatrix loop
    (eq, _) := i;
     if listMember(eq, setS) then
       setS_BltAdjacencyMatrix := i :: setS_BltAdjacencyMatrix;
     end if;
   end for;
end getSetSAdjacencyMatrix;

protected function extractMinimalSetS
  "construct a minimal set-S using recursive algorithm, which are needed to solve intermediate
  variables in set-c and also avoid complication when calculating jacobians"
  input output list<Integer> unknownsInSetC;
  input ExtAdjacencyMatrix sBltAdjacencyMatrix;
  input list<Integer> knownVars;
  input BackendDAE.Variables orderedVars;
  input BackendDAE.EquationArray orderedEqs;
  input array<Integer> mapIncRowEqn;
  input output list<Integer> minimalSetS = {};
  input Boolean debug;
protected
  Integer firstMatchedEquation, mappedEq;
  BackendDAE.Var var;
  BackendDAE.Equation tmpEq;
  list<Integer> rest, vars, intermediateVars = {}, V_EQ;
algorithm
  for varIndex in unknownsInSetC loop
    // break the recursion loop
    if listEmpty(unknownsInSetC) then
      break;
    end if;
    if debug then
      print("\nIntermediate varList : " + dumplistInteger(unknownsInSetC) + "\n" + UNDERLINE + "\n");
    end if;
    _ :: rest := unknownsInSetC;
    (firstMatchedEquation, vars) := getVariableFirstOccurrenceInEquation(sBltAdjacencyMatrix, varIndex, minimalSetS);
    var := BackendVariable.getVarAt(orderedVars, varIndex);

    if not intEq(firstMatchedEquation, 0) then // equation exists
      minimalSetS := firstMatchedEquation :: minimalSetS; // insert the equation into S'
      minimalSetS := List.unique(minimalSetS);
      intermediateVars := List.setDifferenceOnTrue(vars, knownVars, intEq); // get intermediate vars in matched equations
      V_EQ := List.unique(listAppend(intermediateVars, rest));
      if debug then
        dumpMininimalExtraction(varIndex, var, firstMatchedEquation, mapIncRowEqn, orderedEqs, minimalSetS, intermediateVars, rest, V_EQ, false);
      end if;
      // V_EQ exist, recursive call
      (unknownsInSetC, minimalSetS) := extractMinimalSetS(V_EQ, sBltAdjacencyMatrix, knownVars, orderedVars, orderedEqs, mapIncRowEqn, minimalSetS, debug);
    else // equation not exist
      if debug then
        dumpMininimalExtraction(varIndex, var, 0, mapIncRowEqn, orderedEqs, {}, {}, rest, {}, true);
      end if;
      unknownsInSetC := rest; // update the list with the remaining Vars
    end if;
  end for;
end extractMinimalSetS;

protected function dumpMininimalExtraction
  "dumps the minimal set-S extraction algorithm"
  input Integer varIndex;
  input BackendDAE.Var var;
  input Integer firstMatchedEquation;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.EquationArray orderedEqs;
  input list<Integer> minimalSetS;
  input list<Integer> intermediateVars;
  input list<Integer> rest;
  input list<Integer> V_EQ;
  input Boolean falseBlock;
protected
  Integer mappedEq;
  BackendDAE.Equation tmpEq;
algorithm
  if falseBlock then
    print("\nVarIndex           : " + intString(varIndex));
    print("\nVariable Name      : " + ComponentReference.printComponentRefStr(var.varName));
    print("\nEquation Not Exist : " + "NIL");
    print("\nRemainingVars      : " + dumplistInteger(rest) + "\n");
  else
    mappedEq := listGet(arrayList(mapIncRowEqn), firstMatchedEquation);
    tmpEq := BackendEquation.get(orderedEqs, mappedEq);
    //print("\n" + "   ("  + intString(mappedEq) + "/"  + intString(firstMatchedEquation)  + "): " + BackendDump.equationString(tmpEq) + "\n");
    print("\nVarIndex                     : " + intString(varIndex));
    print("\nVariable Name                : " + ComponentReference.printComponentRefStr(var.varName));
    print("\nEquation Exist               : " + intString(firstMatchedEquation));
    print("\nmappedEquation               : " + intString(mappedEq));
    print("\nMatched Equation             : " + BackendDump.equationString(tmpEq));
    print("\nS'                           : " + dumplistInteger(minimalSetS));
    print("\nUnknowns in matchedEquation  : " + dumplistInteger(intermediateVars));
    print("\nRemaining Vars               : " + dumplistInteger(rest));
    print("\nV_EQ                         : " + dumplistInteger(V_EQ) + "\n");
  end if;
end dumpMininimalExtraction;

protected function getVariableFirstOccurrenceInEquation
  "returns the first equation that contains the variable index (e.g)
   var index = 6
   BLT = {(1, {26, 5}), (2, {25, 6}, (3, {1, 2, 6})}
   result = (2,{25, 6})"
  input ExtAdjacencyMatrix m;
  input Integer varIndex;
  input list<Integer> minimalSetS;
  output tuple<Integer, list<Integer>> matchedEquation = (0, {}) "default value 0 means equation does not exist";
protected
  list<Integer> ret, vars, matchedeq;
  Integer eq, eqnum, varnum;
algorithm
  for i in m loop
    (eq, vars) := i;
    //print("\nVarcheck : " + intString(varIndex) + "=>" + anyString(eq) + " => " + anyString(vars));
    if eq > 0 then
      if not listMember(eq, minimalSetS) then
        if listMember(varIndex, vars) then
          //print("\n Found the first equation : " + anyString(i));
          matchedEquation := i;
          break;
        end if;
      end if;
    end if;
  end for;
end getVariableFirstOccurrenceInEquation;

protected function dumpResidualVars
  "returns the variables of interest in modelica format"
  input String instring;
  input list<BackendDAE.Var> invar;
  input String comment;
  output String outstring="";
protected
  DAE.ComponentRef cr;
algorithm
  outstring := "\n  //" + comment;
  for var in invar loop
    cr := BackendVariable.varCref(var);
    outstring := outstring + "\n  " + DAEDump.daeTypeStr(var.varType) + " " + System.stringReplace(ComponentReference.crefStr(cr), ".", "_") + ";";
    outstring := System.stringReplace(outstring, "$", "");
  end for;
  outstring := instring+outstring;
end dumpResidualVars;

protected function dumpExtractedVars
  "returns the variables and parameters in set-S in modelica format"
  input String instring;
  input list<BackendDAE.Var> invar;
  input String comment;
  output String outstring="";
protected
  DAE.ComponentRef cr;
algorithm
  outstring := "\n  //"+ comment;
  for var in invar loop
    cr := BackendVariable.varCref(var);
    if BackendVariable.varHasUncertainValueRefine(var) then
      outstring := outstring + "\n  parameter "  + DAEDump.daeTypeStr(var.varType) + " " + System.stringReplace(ComponentReference.crefStr(cr), ".", "_") + ";";
    elseif BackendVariable.isParam(var) then
      outstring := outstring + "\n  parameter "  + DAEDump.daeTypeStr(var.varType) + " " + System.stringReplace(ComponentReference.crefStr(cr), ".", "_") + " = " + ExpressionDump.printOptExpStr(var.bindExp) +";";
    else
      outstring := outstring + "\n  "  + DAEDump.daeTypeStr(var.varType) + " " + System.stringReplace(ComponentReference.crefStr(cr), ".", "_") + ";";
    end if;
  end for;
  outstring := instring+outstring;
end dumpExtractedVars;

protected function dumpExtractedEquations
  "returns the Equation in modelica format"
  input String instring;
  input BackendDAE.EquationArray eqs;
  input String comment;
  output String outstring="";
algorithm
  outstring := "\n  //"+ comment;
  for eq in BackendEquation.equationList(eqs) loop
    outstring := outstring + "\n  " + dumpEquationString(eq) + ";";
  end for;
  outstring := instring+outstring;
end dumpExtractedEquations;

public function setBoundaryConditionEquationsAndVars
  "Function which iterates shared.globalKnownVars Real parameters and
   check for boundaryCondition vars declared as
   (e.g) parameter Real x = 1  annotation(__OpenModelica_BoundaryCondition = true);
   and add it to the orderedEqs and orederedVars"
  input output BackendDAE.EqSystem currentSystem;
  input output BackendDAE.Shared shared;
  input Boolean debug;
protected
  list<BackendDAE.Equation> eqnLst={};
  list<BackendDAE.Var> daeVarsLst = {};
  list<BackendDAE.Var> updatedGlobalKnownVarsLst = {};
  DAE.Exp lhs, rhs;
  BackendDAE.Equation eqn;
algorithm
  for var in BackendVariable.varList(shared.globalKnownVars) loop
    // check for param Vars, as we are only interested in causality = calculatedParameters
    if BackendVariable.isRealParam(var) and BackendVariable.hasOpenModelicaBoundaryConditionAnnotation(var) then
      //print("\n knownsVars :" + anyString(var.bindExp));
      lhs := BackendVariable.varExp(var);
      rhs := BackendVariable.varBindExp(var);
      eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
      eqnLst := eqn :: eqnLst;
      var := BackendVariable.setVarKind(var, BackendDAE.VARIABLE());
      var := BackendVariable.setBindExp(var, NONE());
      daeVarsLst := var :: daeVarsLst;
    elseif (BackendVariable.isIntParam(var) or BackendVariable.isBoolParam(var)) and BackendVariable.hasOpenModelicaBoundaryConditionAnnotation(var) then
      Error.addMessage(Error.INTERNAL_ERROR, {": Boundary Condition cannot be set on Integer or Boolean parameters: " + ComponentReference.printComponentRefStr(var.varName)  + " must be Real, The extraction algorithm will fail"});
      fail();
    else
      updatedGlobalKnownVarsLst := var :: updatedGlobalKnownVarsLst;
      //inDAE.shared := BackendVariable.addGlobalKnownVarDAE(var, inDAE.shared);
    end if;
  end for;

  if debug then
    BackendDump.dumpVarList(daeVarsLst, "boundaryConditionVarsTaggedAsParmeters");
  end if;

  // update the EqSyst with new boundary Conditions vars and equations
  currentSystem := BackendVariable.addVarsDAE(daeVarsLst, currentSystem);
  currentSystem.orderedEqs := BackendEquation.merge(currentSystem.orderedEqs, BackendEquation.listEquation(eqnLst));
  shared := BackendDAEUtil.setSharedGlobalKnownVars(shared, BackendVariable.listVar(updatedGlobalKnownVarsLst));
end setBoundaryConditionEquationsAndVars;

protected function deleteEquationsFromEqSyst
  "deletes the umatched equations from Matching algorithm, the removed equations are part of E_BLT blocks"
  input output BackendDAE.EqSystem currentSystem;
  input list<Integer> eqIndex;
protected
  BackendDAE.EquationArray newEqArray, newOrderedEquationArray;
algorithm
  currentSystem.orderedEqs := BackendEquation.deleteList(currentSystem.orderedEqs, eqIndex);
  //currentSystem.orderedEqs :=BackendEquation.addList(unMatchedEquations, BackendEquation.deleteList(currentSystem.orderedEqs, unMatchedEqsLst));

  // add the new set of equations
  newOrderedEquationArray := BackendEquation.emptyEqns();
  // add the new set of equations to have continuous  indices after deleting the equations
  BackendEquation.addList(BackendEquation.equationList(currentSystem.orderedEqs), newOrderedEquationArray);

  //BackendDump.dumpEquationArray(newOrderedEquationArray, "After new update of equations");
  currentSystem := BackendDAEUtil.setEqSystEqs(currentSystem, newOrderedEquationArray);
end deleteEquationsFromEqSyst;

protected function getBoundaryConditionsEquationIndex
  "returns the boundary condition variables equation indexes
  eg: Real q0 = 100 annotation(__OpenModelica_BoundaryCondition = true)"
  input BackendDAE.AdjacencyMatrix adjacencyMatrix;
  input list<Integer> boundaryConditions;
  output list<Integer> boundaryConditionsEquationIndexes = {};
protected
  Integer count = 1;
algorithm
  /* get equation index which have annotation __OpenModelica_BoundaryCondition=true*/
  for i in arrayList(adjacencyMatrix) loop
    for j in boundaryConditions loop
      if valueEq(i, {j}) then
        boundaryConditionsEquationIndexes := count :: boundaryConditionsEquationIndexes;
        break;
      end if;
    end for;
    count := count + 1;
  end for;
end getBoundaryConditionsEquationIndex;

protected function getUncertainRefineVariablesBindedEquations
  "returns if the uncertainRefine variables is already binded with equation
  eg: Real q1(uncertain=Uncertainty.refine) = 1; "
  input BackendDAE.AdjacencyMatrix adjacencyMatrix;
  input list<Integer> knowns;
  output list<Integer> knownsWithBindedEquations = {};
algorithm
  /* check already binded equations for variables of interest*/
  for i in arrayList(adjacencyMatrix) loop
    for j in knowns loop
      if valueEq(i, {j}) then
        knownsWithBindedEquations := j :: knownsWithBindedEquations;
      end if;
    end for;
  end for;
end getUncertainRefineVariablesBindedEquations;

protected function getExactConstantVariables
  "return the solved variables for equations that are tagged as annotation( __OpenModelica_ExactConstantEquation = true)"
  input list<Integer> constantEquations;
  input list<tuple<Integer, Integer>> solvedEqsVarInfo;
  output list<Integer> constantVariables = {};
protected
  Integer varNumber;
algorithm
  for eq in constantEquations loop
    (_, varNumber) := getSolvedVariableNumber(eq, solvedEqsVarInfo);
    constantVariables := varNumber :: constantVariables;
  end for;
end getExactConstantVariables;

protected function getBoundaryConditionVariables
  "return the solved variables for equations that are tagged as annotation(__OpenModelica_BoundaryCondition = true)"
  input list<Integer> boundaryConditionEquations;
  input list<tuple<Integer, Integer>> solvedEqsVarInfo;
  output list<Integer> boundaryConditionVariables = {};
protected
  Integer varNumber;
algorithm
  for eq in boundaryConditionEquations loop
    (_, varNumber) := getSolvedVariableNumber(eq, solvedEqsVarInfo);
    boundaryConditionVariables := varNumber :: boundaryConditionVariables;
  end for;
end getBoundaryConditionVariables;

protected function getEquationsFromSBLTAndEBLT
  "function which returns the List of Equations from S-BLT and E-BLT"
  input list<Integer> inList;
  input BackendDAE.EquationArray sBLT_Equations;
  input list<tuple<Integer, BackendDAE.Equation>> eBLT_Equations;
  output list<BackendDAE.Equation> outEquationsList = {};
algorithm
  for eqIndex in inList loop
    if eqIndex > 0 then // S-BLT equations
      outEquationsList := BackendEquation.get(sBLT_Equations, eqIndex) :: outEquationsList;
    else
      // negative index, eqs in E-BLT blocks
      outEquationsList := getEquationsFromEBLT(eqIndex, eBLT_Equations) :: outEquationsList;
    end if;
  end for;
  outEquationsList := listReverse(outEquationsList);
end getEquationsFromSBLTAndEBLT;

protected function getEquationsFromEBLT
  "returns the equations from EBLT blocks which has negative index"
  input Integer eBLTIndex;
  input list<tuple<Integer, BackendDAE.Equation>> eBLT_Equations;
  output BackendDAE.Equation outEquations;
protected
  Integer index;
  BackendDAE.Equation eq;
algorithm
  for eqs in eBLT_Equations loop
    (index, eq) := eqs;
    if intEq(eBLTIndex, index) then
      outEquations := eq;
      break;
    end if;
  end for;
end getEquationsFromEBLT;

protected function getAbsoluteIndexHelper
  "returns the absolute index of equations, For equations in E-BLT, negative index is returned"
  input list<Integer> inList;
  input array<Integer> mapIncRowEqn;
  output list<Integer> outList = {};
algorithm
  for i in inList loop
    if i > 0 then
      outList := listGet(arrayList(mapIncRowEqn), i) :: outList;
    else
      // equations in E-BLT, have negativeindex
      outList := i :: outList;
    end if;
  end for;
  outList := listReverse(outList);
end getAbsoluteIndexHelper;

protected function dumpSetSVarsSolvedInfo
  "dumps set-S equations solved var info along with equations"
  input list<Integer> tempSetS;
  input list<tuple<Integer, Integer>> solvedEqsVarInfo;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.EquationArray orderedEqs;
  input BackendDAE.Variables orderedVars;
protected
  Integer count = 1, varNumber, mappedEq;
  BackendDAE.Var var;
  BackendDAE.Equation tmpEq;
algorithm
  print("\nSet-S Solved-Variables Information :" + "(" + intString(listLength(tempSetS))  + ")" + "\n==========================================\n");
  for eq in tempSetS loop
    (_, varNumber) := getSolvedVariableNumber(eq, solvedEqsVarInfo);
    var := BackendVariable.getVarAt(orderedVars, varNumber);
    mappedEq := listGet(arrayList(mapIncRowEqn), eq);
    tmpEq := BackendEquation.get(orderedEqs, mappedEq);
    print("\n" + intString(count) + ": "  + "eqn " + intString(eq)  + " solves var " + intString(varNumber) + " => " + ComponentReference.printComponentRefStr(var.varName));
    print("\n" + "   ("  + intString(mappedEq) + "/"  + intString(eq)  + "): " + BackendDump.equationString(tmpEq) + "\n");
    count := count + 1;
  end for;
  print("\n\n");
end dumpSetSVarsSolvedInfo;

protected function dumpSetSVars
  "dumps variables involved in set-S equations except parameters and constants"
  input BackendDAE.Variables setSVars;
  input String heading;
protected
  Integer count = 1, varNumber;
  BackendDAE.Var var;
algorithm
  print("\n" + heading + " (" + intString(BackendVariable.varsSize(setSVars)) + ")\n" + "========================================" + "\n");
  for var in BackendVariable.varList(setSVars) loop
    print("\n" + intString(count) + ": "  + ComponentReference.printComponentRefStr(var.varName) + " type: " + DAEDump.daeTypeStr(var.varType));
    count := count + 1;
  end for;
  print("\n\n");
end dumpSetSVars;

protected function dumpBlockStatus
  "dumps the blt block status with the varInfo (i.e) knowns, unkowns and constants"
  input list<list<Integer>> allBlocks;
  input list<list<String>> allBlocksStatusVarInfo;
protected
  Integer count = 1;
algorithm
  print("\nBLT-BLOCK_STATUS\n=================\n");
  for blocks in allBlocks loop
    print ("\nBlock :" + dumplistInteger(blocks) + " || blockStatusVarInfo :" + anyString(listGet(allBlocksStatusVarInfo, count)));
    count := count + 1;
  end for;
  print("\n");
end dumpBlockStatus;

protected function dumpBlockTargets
  "dumps block targets of all blocks in BLT "
  input list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>,list<tuple<list<String>, Integer>>>> s_BLTBlockTargetInfo;
protected
  list<Integer> mainBlock;
  list<tuple<list<Integer>, Integer>> targetBlocks;
  list<tuple<list<String>, Integer>> targetBlocksStatusVarInfo;
algorithm
  print("\nS-BLTBlocks-TargetInfo\n=======================\n");
  for blocks in s_BLTBlockTargetInfo loop
    (mainBlock, targetBlocks, targetBlocksStatusVarInfo) := blocks;
    print ("\nBlock :" + dumplistInteger(mainBlock) +  " || blockTargetsInfo :" + anyString(targetBlocks)  + " || blockStatusVarInfo :" + anyString(targetBlocksStatusVarInfo));
  end for;
  print("\n");
end dumpBlockTargets;

protected function dumpPredecessorBlocks
  "dumps predecessorBlocks information"
  input list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>, list<tuple<list<String>, Integer>>, list<Integer>, list<Integer>, list<Integer>>> predecessorBlockInfo;
protected
  list<Integer> knownBlocks, constantBlocks;
  list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>, list<tuple<list<String>, Integer>>, list<Integer>, list<Integer>, list<Integer>>> blueBlocksTargets = {}, redBlocksTargets = {}, constantBlocksTargets = {};
algorithm
  print("\nTargets of blocks without predecessors:\n========================================");
  for blocks in predecessorBlockInfo loop
    (_, _, _, knownBlocks, constantBlocks, _) := blocks;
    if not listEmpty(knownBlocks) then
      blueBlocksTargets := blocks :: blueBlocksTargets;
    elseif not listEmpty(constantBlocks) then
      constantBlocksTargets := blocks :: constantBlocksTargets;
    else
      redBlocksTargets := blocks :: redBlocksTargets;
    end if;
    //print ("\nBlock :" + dumplistInteger(mainBlock) +  " || blockTargetsInfo :" + anyString(targetBlocks)  + " || KnownBlocks :" + dumplistInteger(knownBlocks) + " || constantBlocks :" + dumplistInteger(constantBlocks));
  end for;
  print("\n");
  dumpPredecessorBlocksHelper(blueBlocksTargets, "knowns", "Targets of Blue blocks");
  dumpPredecessorBlocksHelper(redBlocksTargets, "unknowns", "Targets of Red blocks");
  dumpPredecessorBlocksHelper(constantBlocksTargets, "constant", "Targets of Brown blocks");
end dumpPredecessorBlocks;

protected function dumpPredecessorBlocksHelper
  "helper function which dumps predecessor blocks into different categories
  namely B
  Blue - known Blocks
  Red  - BoundaryCondition Blocks
  Brown - All remaining Blocks which are not known or Boundary Conditions Blocks"
  input list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>, list<tuple<list<String>, Integer>>, list<Integer>, list<Integer>, list<Integer>>> predecessorBlockInfo;
  input String blockInfo;
  input String header;
protected
  list<Integer> mainBlock;
  list<tuple<list<Integer>, Integer>> targetBlocks;
  list<Integer> knownBlocks, constantBlocks;
algorithm
  print("\n" + header + " (" + intString(listLength(predecessorBlockInfo)) + ")" +"\n==============================\n");
  for blocks in listReverse(predecessorBlockInfo) loop
    (mainBlock, targetBlocks, _, knownBlocks, constantBlocks, _) := blocks;
    print ("\nBlock :" + dumplistInteger(mainBlock) +  " || blockTargetsInfo :" + anyString(targetBlocks)  + " || KnownBlocks :" + dumplistInteger(knownBlocks) + " || constantBlocks :" + dumplistInteger(constantBlocks));
  end for;
  print("\n\n");
end dumpPredecessorBlocksHelper;

public function ExtractEquationsUsingSetOperations
  "Extraction the equations from predecessor Blocks and group them
  into two categories namely set-C and Set-S using setOperation formula"
  input list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>, list<tuple<list<String>, Integer>>, list<Integer>, list<Integer>, list<Integer>>> predecessorBlockInfo;
  input list<tuple<list<Integer>, Integer>> e_BLTBlockRanks;
  input list<Integer> approximatedEquations;
  input Boolean debug;
  output list<Integer> setC;
  output list<Integer> setS;
protected
  list<Integer> mainBlock, tmpSetC_1, tmpSetC_2, tmpSetS_1, tmpSetS_2, z1, z2;
  list<tuple<list<Integer>, Integer>> targetBlocks;
  list<Integer> knownBlocks, constantBlocks, e_BLTBlockRanksWithoutRanks = {}, targetBlocksWithKnowns = {}, targetBlocksWithUnknowns = {}, targetBlocksWithConstants = {};
algorithm
  for blocks in predecessorBlockInfo loop
    (mainBlock, targetBlocks, _, knownBlocks, constantBlocks, _) := blocks;
    if not listEmpty(knownBlocks) then // known Blocks
      targetBlocksWithKnowns := filterTargetBlocksWithoutRanks(List.rest(targetBlocks), targetBlocksWithKnowns);
    elseif not listEmpty(constantBlocks) then // constant Blocks
      targetBlocksWithConstants := filterTargetBlocksWithoutRanks(targetBlocks, targetBlocksWithConstants);
    else // unknown Blocks
      targetBlocksWithUnknowns := filterTargetBlocksWithoutRanks(targetBlocks, targetBlocksWithUnknowns);
    end if;
  end for;

  targetBlocksWithKnowns := List.unique(targetBlocksWithKnowns);
  targetBlocksWithUnknowns := List.unique(targetBlocksWithUnknowns);
  targetBlocksWithConstants := List.unique(targetBlocksWithConstants);

  // collect all E-BLT blocks
  e_BLTBlockRanksWithoutRanks := filterTargetBlocksWithoutRanks(e_BLTBlockRanks, e_BLTBlockRanksWithoutRanks);

  if debug then
    print("\nUnion of Blue, Red and Yellow and E-BLT-Blocks\n=====================================================");
    print("\nUnion-E-BLT-blocks                                     :" + dumplistInteger(e_BLTBlockRanksWithoutRanks));
    print("\nUnion-Blue-TargetBlockInfo (blocks with Knowns)        :" + dumplistInteger(targetBlocksWithKnowns));
    print("\nUnion-Red-TargetBlockInfo  (blocks with UnKnowns)      :" + dumplistInteger(targetBlocksWithUnknowns));
    print("\nUnion-Brown-TargetBlockInfo  (blocks with Exact eqns)  :" + dumplistInteger(targetBlocksWithConstants));
  end if;

  /*
  Extract Set-C equation
  SetC =  (targetBlocksWithKnowns) intersection (e_BLTBlockRanksWithoutRanks) - (targetBlocksWithUnknowns) intersection (e_BLTBlockRanksWithoutRanks)
  */
  tmpSetC_1 := List.intersectionOnTrue(targetBlocksWithKnowns, e_BLTBlockRanksWithoutRanks, intEq);
  tmpSetC_2 := List.intersectionOnTrue(targetBlocksWithUnknowns, e_BLTBlockRanksWithoutRanks, intEq);
  setC := List.setDifferenceOnTrue(tmpSetC_1, tmpSetC_2, intEq);

  // remove approximated equation from setC if present
  setC:= List.setDifferenceOnTrue(setC, approximatedEquations, intEq);

  if debug then
    print("\n\nSetC-Operations\n====================");
    print("\n(BlocksWithKnowns) intersection (e_BLTBlocks)   :" + dumplistInteger(tmpSetC_1));
    print("\n(BlocksWithUnknowns) intersection (e_BLTBlocks) :" + dumplistInteger(tmpSetC_2));
    print("\nSetC                                            :" + dumplistInteger(setC));
    print("\n");
  end if;

  /*
  Extract Set-S equation
  SetS = [((targetBlocksWithKnowns - targetBlocksWithUnknowns) - e_BLTBlockRanksWithoutRanks)) U (targetBlocksWithConstants))] - e_BLTBlockRanksWithoutRanks
  */
  tmpSetS_1 := List.setDifferenceOnTrue(targetBlocksWithKnowns, targetBlocksWithUnknowns, intEq);
  tmpSetS_2 := List.setDifferenceOnTrue(tmpSetS_1, e_BLTBlockRanksWithoutRanks, intEq);
  z1 := List.setDifferenceOnTrue(targetBlocksWithConstants, targetBlocksWithUnknowns, intEq);
  z2 := List.setDifferenceOnTrue(z1, e_BLTBlockRanksWithoutRanks, intEq);
  setS := List.unique(List.union(tmpSetS_2, z2));
  //setS := List.setDifferenceOnTrue(List.union(tmpSetS_2, targetBlocksWithConstants), e_BLTBlockRanksWithoutRanks, intEq);

  // remove approximated equation from setS if present
  setS := List.setDifferenceOnTrue(setS, approximatedEquations, intEq);

  if debug then
    print("\nSetS-Operations\n==================");
    print("\n(BlocksWithKnowns - BlocksWithUnknowns)                  :" + dumplistInteger(tmpSetS_1));
    print("\n((BlocksWithKnowns - BlocksWithUnknowns) - e_BLTBlocks)) :" + dumplistInteger(tmpSetS_2));
    print("\nz1(B) => (ConstantBlocks - UnknownsBlocks)               :" + dumplistInteger(z1));
    print("\nz2(B) => (z1(B) - e_BLTBlocks)                           :" + dumplistInteger(z2));
    print("\nSetS                                                     :" + dumplistInteger(setS));
    print("\n");
  end if;
end ExtractEquationsUsingSetOperations;

public function filterTargetBlocksWithoutRanks
  input list<tuple<list<Integer>, Integer>> targetBlocks;
  input list<Integer> inBlocks;
  output list<Integer> outBlocks;
protected
  list<Integer> mainBlocks = {};
algorithm
  for blocks in targetBlocks loop
    mainBlocks := List.append_reverse(Util.tuple21(blocks), mainBlocks);
  end for;
  outBlocks := listAppend(inBlocks, listReverse(mainBlocks));
end filterTargetBlocksWithoutRanks;

public function setEBLTEquationsWithIndexAndRank
  " Prepare EBLT-Blocks with
   eBLT_Equation_WithIndex = {(index, {equations})}
   e_BLTAdjacencyMatrix = {(index, {list of vars present in equation})} // (e.g.) {(-1,{4,3}), (-2,{5,6})}
   e_BLTSolvedEqsAndVars = {(index, solvedvars)} // (e.g.) (-1, 4) means eq -1 solves variable 4
   index = negative integers to easily identify the EBLT BLocks
   "
  input list<Integer> unMatchedEqList;
  input list<Integer> unMatchedEqsLstCorrectIndex;
  input BackendDAE.EquationArray inEqArray;
  input BackendDAE.AdjacencyMatrix adjacencyMatrix;
  output list<tuple<Integer, BackendDAE.Equation>> eBLT_Equation_WithIndex = {};
  output ExtAdjacencyMatrix e_BLTAdjacencyMatrix = {};
  output list<tuple<Integer, Integer>> e_BLTSolvedEqsAndVars ={};
  output list<list<Integer>> e_BLTBlocks = {};
  output list<tuple<list<Integer>, Integer>> e_BLTBlockRanks = {};
protected
  Integer count = 1, actualIndex, index = -1; // use negative index for identifying equations in EBLT block
  list<Integer> varsInfoList;
algorithm
  for i in unMatchedEqList loop
    actualIndex := listGet(unMatchedEqsLstCorrectIndex, count);
    eBLT_Equation_WithIndex := (index, BackendEquation.get(inEqArray, actualIndex)) :: eBLT_Equation_WithIndex;
    varsInfoList := arrayGet(adjacencyMatrix, i);
    e_BLTAdjacencyMatrix := (index, varsInfoList) :: e_BLTAdjacencyMatrix;
    // get vars with the highest index, which should be solved for E-BLT equations as they appear in the end of BLT
    e_BLTSolvedEqsAndVars := (index, listGet(List.sort(varsInfoList, intLt), 1)) :: e_BLTSolvedEqsAndVars;
    e_BLTBlocks := {index} :: e_BLTBlocks;
    e_BLTBlockRanks := ({index}, index) :: e_BLTBlockRanks;
    index := index - 1;
    count := count + 1;
  end for;
  eBLT_Equation_WithIndex := listReverse(eBLT_Equation_WithIndex);
  e_BLTAdjacencyMatrix := listReverse(e_BLTAdjacencyMatrix);
  e_BLTSolvedEqsAndVars := listReverse(e_BLTSolvedEqsAndVars);
  e_BLTBlocks := listReverse(e_BLTBlocks);
  e_BLTBlockRanks := listReverse(e_BLTBlockRanks);
end setEBLTEquationsWithIndexAndRank;

public function inverseModelicaModel
  /* Inverse the model by adding new binding equations to the variables of interest (tagged with attribute uncertain=Uncertainty.refine)
     (e.g) if Q1 and Q2 are variables of interest add new binding equations like, if no binding exists
     Q1=0 and Q2=0 to existing set of equations to make the system overdetermined
  */
  input BackendDAE.Variables inVar;
  input list<Integer> knownVariablesWithEquationBinding "variables with already binded equations";
  output list<BackendDAE.Equation> eqnlst={};
protected
  list<BackendDAE.Var> variablesOfInterest;
  list<Integer> variablesOfInterestIndexes;
  BackendDAE.Equation eq;
algorithm
  variablesOfInterest := List.filterOnTrue(BackendVariable.varList(inVar), BackendVariable.varHasUncertainValueRefine); // filter the variables of interest
  for var in variablesOfInterest loop
    // get the index of uncertianty.Refine
    variablesOfInterestIndexes := BackendVariable.getVarIndexFromVars({var}, inVar);
    //print("\ninverse Modelica Model :" + anyString(var.varName) + "==>" + anyString(variablesOfInterestIndexes) + "===>" + anyString(knownVariablesWithEquationBinding) + "====>" + anyString(List.intersectionOnTrue(variablesOfInterestIndexes, knownVariablesWithEquationBinding, intEq)));
    // add equations only for variables which do not have bindings
    if listEmpty(List.intersectionOnTrue(variablesOfInterestIndexes, knownVariablesWithEquationBinding, intEq)) then
      // TODO constant expression for other dataTypes
      eq := BackendDAE.EQUATION(Expression.crefExp(var.varName), DAE.RCONST(0.0), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      eqnlst := eq :: eqnlst;
    end if;
  end for;
end inverseModelicaModel;

public function dumplistInteger
  input list<Integer> inlist;
  output String outstring;
protected
  list<String> s;
algorithm
  s := List.map(inlist, intString);
  outstring := stringDelimitList(s, ", ");
  outstring := stringAppendList({"{",outstring,"}"});
end dumplistInteger;

public function traverseBLTAndUpdateBlockStatus
  "function which traverse all BLT Blocks
  and return list of all bltblocks with solved variables
  information.
  (e.g) : {1, 2, 4} ==> {knowns, boundaryConditionsVars, exactEquationVars}"
  input list<list<Integer>> inlist;
  input list<Integer> knowns;
  input list<Integer> boundaryConditionVars;
  input list<Integer> exactEquationVars;
  input list<tuple<Integer,Integer>> solvedVariables;
  output list<list<Integer>> outlist = {} "list of blocks, (i.e) list of equations";
  output list<list<String>> outstringlist = {} "list of blocks info (i.e) known, unknown or constant variables are solved for each equations";
protected
  list<Integer> blocks;
  list<String> blockinfo;
algorithm
  for i in inlist loop
    (blocks, blockinfo) := checkBlueOrRedOrBrownBlocks(i, knowns, boundaryConditionVars, exactEquationVars, solvedVariables);
    outlist := blocks :: outlist;
    outstringlist := blockinfo :: outstringlist;
  end for;
  outlist := listReverse(outlist);
  outstringlist := listReverse(outstringlist);
end traverseBLTAndUpdateBlockStatus;

public function checkBlueOrRedOrBrownBlocks
  "function which returns which variables are solved for each equations in BLT blocks
  variables types: knowns, unknowns and constants
  (e.g): outIntegerList =  BLT Blocks = {1,2}
         outStringList  =  solvedVars = {knowns, unknowns}
   knownVars - BlueBlocks
   unknowns  - RedBlocks
   constant  - BrownBlocks
  "
  input list<Integer> inlist;
  input list<Integer> knowns;
  input list<Integer> boundaryConditionVars;
  input list<Integer> exactEquationVars;
  input list<tuple<Integer,Integer>> solvedVar;
  output list<Integer> outIntegerList = {};
  output list<String> outStringList = {};
protected
  Integer eqNumber, varNumber;
algorithm
  for i in inlist loop
    (eqNumber, varNumber) := getSolvedVariableNumber(i, solvedVar);
    // knownVars are named as knowns and belong to Blue Blocks
    if listMember(varNumber, knowns) then
      outStringList := "knowns" :: outStringList;
      outIntegerList := i :: outIntegerList;
    // exactEquationVars are named as constants and belong to Brown Blocks
    elseif listMember(varNumber, exactEquationVars) then
      outStringList := "constants" :: outStringList;
      outIntegerList := i :: outIntegerList;
    // boundaryCondtionVars are named as unknowns  and belong to Red Blocks
    else
      outStringList := "unknowns" :: outStringList;
      outIntegerList := i :: outIntegerList;
    end if;
  end for;
  outIntegerList := listReverse(outIntegerList);
  outStringList := listReverse(outStringList);
end checkBlueOrRedOrBrownBlocks;

public function getSolvedVariableNumber
  "returns solvedvars based on the equation "
  input Integer eqnumber;
  input list<tuple<Integer, Integer>> inlist;
  output tuple<Integer, Integer> mappedEqVar;
protected
  Integer eq, solvedvar;
algorithm
  for var in inlist loop
    (eq, solvedvar):=var;
    if intEq(eqnumber, eq) then
      mappedEqVar := (eqnumber, solvedvar);
      return;
    end if;
  end for;
end getSolvedVariableNumber;

public function getSolvedEquationNumber
  "returns solvedeqs based on the variables "
  input Integer varnumber;
  input list<tuple<Integer, Integer>> inlist;
  output tuple<Integer, Integer> mappedEqVar;
protected
  Integer eq, solvedvar;
algorithm
  for var in inlist loop
    (eq, solvedvar) := var;
    if intEq(varnumber, solvedvar) then
      mappedEqVar := (eq, solvedvar);
      return;
    end if;
  end for;
end getSolvedEquationNumber;

public function getSolvedEquationAndVarsInfo
  "returns the solvedEquationsandVarsInfo from the matching algorithm
  eg:{(1,3),(2,4)}"
  input array<Integer> v;
  output list<tuple<Integer,Integer>> eqvarlist={};
  output list<Integer> solvedEqLst ={};
protected
  list<Integer> var;
  Integer count=1;
algorithm
  var:=arrayList(v);
  for i in var loop
    eqvarlist:=(i,count)::eqvarlist;
    solvedEqLst := i :: solvedEqLst;
    count:=count+1;
  end for;
end getSolvedEquationAndVarsInfo;

protected function getVariablesBlockCategories
  "Returns a list with the indexes of all variables in variableIndexList
   knowns = uncertain attribute set to Real Q1(uncertain=Uncertainty.refine);
   boundaryConditionVars = Real q0 = 100 annotation(__OpenModelica_BoundaryCondition = true);
   exactEquationVars = remanining variables and annotation(__OpenModelica_BoundaryCondition = false) "
  input BackendDAE.Variables allVariables;
  input list<Integer> variableIndexList;
  output list<Integer> knowns = {};
  output list<Integer> boundaryConditionVars = {};
  output list<Integer> exactEquationVars = {};
protected
  BackendDAE.Var var;
algorithm
  for index in variableIndexList loop
    var := BackendVariable.getVarAt(allVariables, index);
    //print("\n name :" +  ComponentReference.printComponentRefStr(var.varName) + " => " + anyString(var.comment));
    if BackendVariable.varHasUncertainValueRefine(BackendVariable.getVarAt(allVariables, index)) then
      knowns := index :: knowns;
    elseif BackendVariable.hasOpenModelicaBoundaryConditionAnnotation(var) then
      boundaryConditionVars := index :: boundaryConditionVars;
    else
      exactEquationVars := index :: exactEquationVars;
    end if;
  end for;
end getVariablesBlockCategories;

protected function getUncertainRefineAndUnknownVariableIndexes
  "Returns a list with the indexes of all variables in variableIndexList
   knowns = uncertain attribute set to Uncertainty.Refine
   unknowns = remanining variables"
  input BackendDAE.Variables allVariables;
  input list<Integer> variableIndexList;
  output list<Integer> knowns = {};
  output list<Integer> unknowns = {};
algorithm
  for index in variableIndexList loop
    if BackendVariable.varHasUncertainValueRefine(BackendVariable.getVarAt(allVariables, index)) then
      knowns := index :: knowns;
    else
      unknowns := index :: unknowns;
    end if;
  end for;
end getUncertainRefineAndUnknownVariableIndexes;

public function dumpListList
  input list<list<Integer>> lstLst;
  input String heading;
algorithm
  print("\n" + heading + ":\n" + UNDERLINE + "\n" +"{"+stringDelimitList(List.map(lstLst,dumplistInteger),",") + "}" +"\n\n");
end dumpListList;

public function getEquationsTaggedApproximatedOrBoundaryCondition
  "return equations indexes which are tagged approximated = true or boundaryConditions = true"
  input list<BackendDAE.Equation> eqs;
  input Integer index;
  output list<Integer> approximatedEquations = {};
  output list<Integer> boundaryConditionEquations = {};
protected
  Boolean isApproximateEquations, isConstantEquations;
  Integer i;
algorithm
  i := index;
  for eq in eqs loop
    (isApproximateEquations, isConstantEquations) := isEquationTaggedApproximatedOrBoundaryCondition(eq);
    if isApproximateEquations then
      approximatedEquations := i :: approximatedEquations;
    elseif isConstantEquations then
      boundaryConditionEquations := i :: boundaryConditionEquations;
    end if;
    i := i +1;
  end for;
end getEquationsTaggedApproximatedOrBoundaryCondition;

protected function isEquationTaggedApproximatedOrBoundaryCondition
  input BackendDAE.Equation eqn;
  output Boolean approximatedEquations;
  output Boolean boundaryConditionEquations;
algorithm
  (approximatedEquations, boundaryConditionEquations) := match(eqn)
    local
      list<SCode.Comment> comment;
      Boolean isApproximatedEquation, isboundaryConditionEquations;
    case(BackendDAE.EQUATION(source=DAE.SOURCE(comment=comment)))
      equation
        (isApproximatedEquation, isboundaryConditionEquations) = isEquationTaggedApproximatedOrBoundaryConditionHelper(comment);
      then
        (isApproximatedEquation, isboundaryConditionEquations);
    case(_) then (false, false);
  end match;
end isEquationTaggedApproximatedOrBoundaryCondition;

protected function isEquationTaggedApproximatedOrBoundaryConditionHelper
  input list<SCode.Comment> commentIn;
  output Boolean approximatedEquations;
  output Boolean boundaryConditionEquations;
algorithm
  (approximatedEquations, boundaryConditionEquations) := matchcontinue(commentIn)
    local
      SCode.Comment h;
      list<SCode.Comment> t;
      Boolean isApproximatedEquation, isboundaryConditionEquation;
      list<SCode.SubMod> subModLst;
    case({}) then (false, false);
    case(SCode.COMMENT(annotation_=SOME(SCode.ANNOTATION(SCode.MOD(subModLst=subModLst))))::t)
      equation
        isApproximatedEquation = List.exist(subModLst, isEquationTaggedApproximated) or isEquationTaggedApproximatedOrBoundaryConditionHelper(t);
        isboundaryConditionEquation = List.exist(subModLst, isEquationTaggedBoundaryCondition) or isEquationTaggedApproximatedOrBoundaryConditionHelper(t);
      then
        (isApproximatedEquation, isboundaryConditionEquation);
    case(_::t)
      equation
        (isApproximatedEquation, isboundaryConditionEquation) = isEquationTaggedApproximatedOrBoundaryConditionHelper(t);
      then
        (isApproximatedEquation, isboundaryConditionEquation);
  end matchcontinue;
end isEquationTaggedApproximatedOrBoundaryConditionHelper;

protected function isEquationTaggedApproximated
  "return true if __OpenModelica_ApproximatedEquation = true else false "
  input SCode.SubMod m;
  output Boolean approximatedEquations;
algorithm
  approximatedEquations := match(m)
    case(SCode.NAMEMOD("__OpenModelica_ApproximatedEquation", SCode.MOD(binding = SOME(Absyn.BOOL(true))))) then true;
    else false;
  end match;
end isEquationTaggedApproximated;

protected function isEquationTaggedBoundaryCondition
  "return true if __OpenModelica_BoundaryCondition = true else false "
  input SCode.SubMod m;
  output Boolean boundaryCondition;
algorithm
  boundaryCondition := match(m)
    case(SCode.NAMEMOD("__OpenModelica_BoundaryCondition", SCode.MOD(binding = SOME(Absyn.BOOL(true))))) then true;
    else false;
  end match;
end isEquationTaggedBoundaryCondition;

protected function isEquationTaggedConstant
  "return true if __OpenModelica_ExactConstantEquation = true else false "
  input SCode.SubMod m;
  output Boolean constantEquations;
algorithm
  constantEquations := match(m)
    case(SCode.NAMEMOD("__OpenModelica_ExactConstantEquation", SCode.MOD(binding = SOME(Absyn.BOOL(true))))) then true;
    else false;
  end match;
end isEquationTaggedConstant;

public function getSBLTAdjacencyMatrix
  input BackendDAE.AdjacencyMatrix adjacencyMatrix;
  output ExtAdjacencyMatrix extAdjacencyMatrix = {};
protected
  Integer count = 1;
algorithm
  for vars in adjacencyMatrix loop
    extAdjacencyMatrix := (count, vars) :: extAdjacencyMatrix;
    count := count + 1;
  end for;
  extAdjacencyMatrix := listReverse(extAdjacencyMatrix);
end getSBLTAdjacencyMatrix;

/*
 Block Target Alogrithm
*/
public function findBlockTargets
  /* Function which finds the Target blocks for each BLT blocks */
  input list<list<Integer>> inlist1;
  input list<list<String>> inlist2;
  input list<tuple<Integer,Integer>> solvedvariables;
  input ExtAdjacencyMatrix mxt;
  input list<tuple<list<Integer>,Integer>> blockranks;
  input Boolean debug = false;
  output list<tuple<list<Integer>,list<tuple<list<Integer>,Integer>>,list<tuple<list<String>,Integer>>>> outlist={};
protected
  list<list<Integer>> targetblocks, eBLTBlocks;
  list<tuple<list<String>,Integer>> targetvarlist;
  list<String> blockvarlst;
  list<Integer> ranklist, blocks1;
  Integer rank;
  list<tuple<list<Integer>,Integer>> updatedblocks;
algorithm

  if debug then
    print ("\nDetailed BlockTarget Dependency tree: \n========================================\n");
  end if;

  for i in inlist1 loop
    if listGet(i, 1) > 0 then // find blocks target for only S-BLT
      if debug then
        print("\nFIND Blocks target of :" + anyString(i) + "\n========================");
      end if;
      (targetblocks, eBLTBlocks) := findBlockTargetsHelper({i}, inlist2, solvedvariables, mxt, inlist1, debug);
      targetblocks := listAppend(i :: targetblocks, eBLTBlocks); // append the EBLT blocks to end
      //print("\n Final Target Blocks before :" + anyString(targetblocks) + "==>EBLT "+ anyString(eBLTBlocks) +"\n **************\n");
      (updatedblocks, ranklist) := findBlocksRanks(blockranks, targetblocks);
      updatedblocks := sortBlocks(ranklist, updatedblocks);

      if debug then
        print("\nFinal-Target-Blocks : " + anyString(updatedblocks) + " || rankList" + anyString(ranklist)  + "\n\n");
      end if;

      targetvarlist := {};
      for blocks in updatedblocks loop
        (blocks1, rank) := blocks;
        blockvarlst := getBlockVarList(blocks1, inlist1, inlist2);
        targetvarlist := (blockvarlst, rank)::targetvarlist;
      end for;

      outlist := (i, updatedblocks, listReverse(targetvarlist)) :: outlist;
    end if;
  end for;
  outlist := listReverse(outlist);
end findBlockTargets;

public function findBlockTargetsHelper
  /* Recursive Function which finds the Target blocks for each BLT blocks */
  input list<list<Integer>> inlist1;
  input list<list<String>> inlist2;
  input list<tuple<Integer,Integer>> solvedvariables;
  input ExtAdjacencyMatrix mxt;
  input list<list<Integer>> actualblocks;
  input Boolean debug = false;
  output list<list<Integer>> outSBLT = {};
  output list<list<Integer>> outEBLT = {};
algorithm
  (outSBLT, outEBLT) := match(inlist1, inlist2, solvedvariables, mxt, actualblocks, debug)
   local
     list<Integer> first, dependencyequation, targetblockslist;
     list<list<Integer>> rest, targetblocks, targetblocks1, originalblocks, eBLTList1, eBLTList2;
     list<list<String>> restitem;
     list<String> firstitem;
     list<tuple<Integer,Integer>> solvar;
     ExtAdjacencyMatrix mxt1;
     Boolean b;
   case(first::rest, firstitem::restitem, solvar, mxt1, originalblocks, b)
     equation
       (dependencyequation, eBLTList1) = findBlockTargetsHelper1((first::rest), solvar, mxt1);
       if debug then
         print("\nTargetBlocks :" + anyString(dependencyequation) + " || EBLT_Block" + anyString(eBLTList1) + "\n");
       end if;
       targetblocks = getActualBlocks(dependencyequation, originalblocks, first);
       (targetblocks1, eBLTList2) = findBlockTargetsHelper(targetblocks, firstitem::restitem, solvar, mxt1, originalblocks, b);
     then
       (List.unique(listAppend(targetblocks,targetblocks1)), List.unique(listAppend(eBLTList1,eBLTList2)));
   case(_, _, _, _, _, _) then ({}, {});
   end match;
end findBlockTargetsHelper;

public function findBlockTargetsHelper1
  input list<list<Integer>>  inlist;
  input list<tuple<Integer,Integer>> solvedvariables;
  input ExtAdjacencyMatrix mxt;
  output list<Integer> outSBLT = {};
  output list<list<Integer>> outEBLT = {};
protected
  list<Integer> tmpSBLT, tmpEBLT;
algorithm
  //print("\n Debug block target Helper : " + anyString(inlist));
  for i in inlist loop
    (tmpSBLT, tmpEBLT) := getDependencyequation(i, {}, solvedvariables, mxt);
    //print("\n Dependencyequations:" + anyString(i) + "=====>" + anyString(tmpSBLT) + "===> EBLT" + anyString(tmpEBLT) + "\n");
    outSBLT := listAppend(outSBLT, tmpSBLT) annotation(__OpenModelica_DisableListAppendWarning=true);
    outEBLT := List.appendElt(tmpEBLT, outEBLT);
    /*for v in listReverse(dependencyequations) loop
      outlist:=v::outlist;
    end for;*/
  end for;
  //print("\n Debug block target Helper end :" + anyString(inlist) + "====>" + anyString(outSBLT) + "===> EBLT" + anyString(outEBLT) + "\n");
end findBlockTargetsHelper1;

public function getDependencyequation
  "returns the dependencies list of the equation"
  input list<Integer> inlist;
  input list<Integer> inlist1;
  input list<tuple<Integer,Integer>> solvedvariables;
  input ExtAdjacencyMatrix m;
  output list<Integer> outSBLT;
  output list<Integer> outEBLT;
protected
  list<Integer> t={}, nonsq, e_BltList;
  Integer eqnumber, varnumber;
algorithm
  for i in inlist loop
    (eqnumber,varnumber) := getSolvedVariableNumber(i, solvedvariables);
    (nonsq, outEBLT) := getdirectOccurrencesinEquation(m, eqnumber, varnumber);
    //print(anyString(nonsq));
    for lst in nonsq loop
      if not listMember(lst,inlist) then
        t:=lst::t;
      end if;
    end for;
  end for;
  outSBLT := listAppend(t,inlist1);
  //print("\n getDependencyequation_function_check:" + anyString(outSBLT) + "====>EBLT:" + anyString(outEBLT));
end getDependencyequation;

public function getdirectOccurrencesinEquation
  "returns the dependencies of equations in associated with Block target"
  input ExtAdjacencyMatrix m;
  input Integer eqnumber;
  input Integer varnumber;
  output list<Integer> outSBLT = {};
  output list<Integer> outEBLT = {};
protected
  list<Integer> ret,vars,matchedeq;
  Integer eq,eqnum,varnum;
algorithm
  for i in m loop
    (eq, vars) := i;
    if not intEq(eq, eqnumber) then
      if listMember(varnumber, vars) then
        //print("\n check matched eq block:" + anyString(eq));
        if eq > 0 then // equations in S-BLT
          outSBLT := eq :: outSBLT;
        else
          // break the loop when hitting the first E-BLT Blocks, (i.e) first equation with negative index
          outEBLT := eq :: outEBLT;
          break;
        end if;
      end if;
    end if;
  end for;
  outSBLT := listReverse(outSBLT);
  outEBLT := listReverse(outEBLT);
end getdirectOccurrencesinEquation;

public function findBlocksRanks
  "returns the block ranks for the targetBlocks"
  input list<tuple<list<Integer>,Integer>> inlist1;
  input list<list<Integer>>  inlist2;
  output list<tuple<list<Integer>,Integer>> outlist = {};
  output list<Integer> ranklist={};
protected
  list<Integer> blocks, s_BLTRanks = {}, e_BLTRanks ={};
  Integer rank;
algorithm
  for i in inlist2 loop
    for j in inlist1 loop
      (blocks, rank):=j;
      if valueEq(i, blocks) then
        outlist := (i, rank)::outlist;
        if rank > 0 then // S-BLT
          s_BLTRanks := rank :: s_BLTRanks;
        else
          e_BLTRanks := rank :: e_BLTRanks; // E-BLT
        end if;
      end if;
    end for;
  end for;
  outlist := listReverse(outlist);
  // append the EBLT Blocks ranks always to last
  ranklist := listAppend(List.sort(s_BLTRanks, intGt), listReverse(e_BLTRanks));
end findBlocksRanks;

public function sortBlocks
  "sort the targetBlocks according to the ranks in ascending order"
  input list<Integer> sortedranklist;
  input list<tuple<list<Integer>,Integer>> inlist2;
  output list<tuple<list<Integer>,Integer>> outlist={};
protected
  Integer e1, e2;
  list<Integer> blocks;
algorithm
  for i in sortedranklist loop
    for j in inlist2 loop
      (blocks, e1) := j;
      if valueEq(i, e1) then
        outlist := (blocks, e1) :: outlist;
      end if;
    end for;
  end for;
  outlist:=listReverse(outlist);
end sortBlocks;

public function getBlockVarList
  "returns the block Status of the searched block
  which is basically (e.g) {1, 2} ==> {knowns, unknowns}"
  input list<Integer> blocktofind;
  input list<list<Integer>> inlist1;
  input list<list<String>> inlist2;
  output list<String> outstringlist={};
protected
  Integer count = 1;
  Boolean blockFound;
algorithm
  for i in inlist1 loop
    blockFound := List.setEqualOnTrue(i, blocktofind, intEq);
    if blockFound then
      outstringlist := listGet(inlist2, count);
    end if;
  count := count+1;
  end for;
end getBlockVarList;

public function getActualBlocks
  "returns the mapped Blocks with the searchBlock"
  input list<Integer> searchblock;
  input list<list<Integer>> inlist1;
  input list<Integer> inlist2;
  output list<list<Integer>> outlist={};
algorithm
  for i in inlist1 loop
    if not listEmpty(List.intersectionOnTrue(searchblock, i, intEq)) then
      outlist := i :: outlist;
    end if;
  end for;
  //outlist:=listReverse(listAppend(outlist,{inlist2}));
  outlist:=listReverse(outlist);
end getActualBlocks;

/* ### End of Block-target Algorithm functions ### */

/*
  finding PredecessorBlocks Algorithm
*/
public function findPredecessorBlocks
  "Traverse all blocks and find the Predecessor Blocks
  Predecessor Blocks are the blocks which do not appear on any other
  target Blocks. (e.g)
  Predeccsors Block {1}: Block Target: {({1}, {4}, {5}, {-1}}
  Predeccsors Block {2}: Block Target: {({2}, {-1}}
  Predeccsors Block {3}: Block Target: {({3}, {-2}}
  Here we can see, block {1},{2},{3} are predecessors Blocks and they do not appear on other blocks target
  "
  input list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>, list<tuple<list<String>, Integer>>>> blockinfo;
  output list<tuple<list<Integer>, list<tuple<list<Integer>, Integer>>, list<tuple<list<String>, Integer>>, list<Integer>, list<Integer>, list<Integer>>> outblockinfo={};
protected
  list<Integer> dependencyequation, constantEquations;
  list<tuple<list<Integer>, Integer>> blockstoupdate, targetblocks, tmptargetblocks;
  list<tuple<list<String>,Integer>> targetblocksvar;
  list<Integer> blockitem, blockitems1, blockitems2, foundblockranks;
  list<String> blockvarlst, blockvarlst1, blockvarlst2;
  Integer foundblock, count=1, foundblockrank, tmpcount;
  Boolean visited, square, status, checkknowns, finalsquarestauts, exist, exist1, targetexist;
  list<tuple<list<Integer>, list<String>, Boolean, Integer>> outlist1={};
algorithm
  //print("Targets of blocks without predecessors\n" + "=====================================\n");
  for blocks in blockinfo loop
    (blockitems1, targetblocks, targetblocksvar) := blocks;
    tmpcount := 1;
    targetexist := false;
    // iterate over other blocks target and check block exists
    for tmpblocks in blockinfo loop
      (_, tmptargetblocks, _) := tmpblocks;
      if not intEq(count,tmpcount) then
        if listMember(List.first(targetblocks), tmptargetblocks) then
          targetexist := true;
        end if;
      end if;
      tmpcount := tmpcount+1;
    end for;

    //check Block does not exists on any other targets
    if not targetexist then
      //print("Predeccsors Block Found:" + anyString(targetblocks) + "\n");
      (exist, dependencyequation, constantEquations, foundblockranks) := findSquareAndNonSquareBlocksHelper1(targetblocks,targetblocksvar);
      //print("Predeccsors Block Found_ Target*:" + anyString(targetblocks) + " dependency equation:" + anyString(dependencyequation) +"\n");
      outblockinfo := (blockitems1, targetblocks, targetblocksvar, dependencyequation, constantEquations, foundblockranks)::outblockinfo;
    end if;
    count:=count+1;
  end for;
  outblockinfo:=listReverse(outblockinfo);
end findPredecessorBlocks;

public function findSquareAndNonSquareBlocksHelper1
  input list<tuple<list<Integer>,Integer>> inlist1;
  input list<tuple<list<String>,Integer>> inlist2;
  output Boolean exists=false;
  output list<Integer> foundknownblocks = {};
  output list<Integer> constantBlocks = {};
  output list<Integer> blockranks = {};
protected
  list<String> blocksvarlist;
  Integer count = 1, rank;
  list<Integer> targetblocks;
algorithm
  for i in inlist2 loop
    (blocksvarlist, rank) := i;
    if rank > 0 and count == 1 then // check for only blocks in S-BLT
      (targetblocks, _) := listGet(inlist1, count);
      // known Blocks
      if listMember("knowns", blocksvarlist) then
        exists := true;
        blockranks := rank :: blockranks;
        foundknownblocks := getKnownOrExactEquationBlocksHelper(blocksvarlist, targetblocks, "knowns");
      // exactEquations Blocks
      elseif listMember("constants", blocksvarlist) then
        exists := true;
        blockranks := rank :: blockranks;
        constantBlocks := getKnownOrExactEquationBlocksHelper(blocksvarlist, targetblocks, "constants");
      end if;
    end if;
    count := count+1;
  end for;
  foundknownblocks := listReverse(foundknownblocks);
  blockranks := listReverse(blockranks);
end findSquareAndNonSquareBlocksHelper1;

protected function getKnownOrExactEquationBlocksHelper
  "returns the blocks with knowns or constants"
  input list<String> blocksVarList;
  input list<Integer> targetBlocks;
  input String knownOrConstant;
  output list<Integer> outBlocks = {};
protected
  Integer count = 1;
algorithm
  for j in blocksVarList loop
    if valueEq(j, knownOrConstant) then
      outBlocks := listGet(targetBlocks, count) :: outBlocks;
      return;
    end if;
    count := count+1;
  end for;
end getKnownOrExactEquationBlocksHelper;
/* end of finding PredecessorBlocks Algorithm */

public function getVariablesAfterExtraction
  "returns all the Variables found in SET-C and SET-S which are part of BLT
   Note: This list will not contains parameters and record Constructors"
  input list<Integer> setc;
  input list<Integer> sets;
  input ExtAdjacencyMatrix mext;
  output list<Integer> finalvars={};
protected
  list<Integer> fulleqs, vars;
  Integer eq;
algorithm
  fulleqs := listAppend(setc,sets);
  for i in fulleqs loop
    for j in mext loop
      (eq, vars) := j;
      if intEq(i,eq) then
        for k in vars loop
          finalvars := k:: finalvars;
        end for;
      end if;
    end for;
  end for;
  finalvars := List.unique(finalvars);
  //print("\n check extraction =>:" + anyString(finalvars) + "length is:"+ anyString(listLength(finalvars)));
end getVariablesAfterExtraction;

public function VerifyDataReconciliation
  input list<Integer> setc;
  input list<Integer> sets;
  input list<Integer> knowns;
  input list<Integer> unknowns;
  input ExtAdjacencyMatrix mExt;
  input list<tuple<Integer,Integer>> solvedvar;
  input list<Integer> constantvars;
  input list<Integer> approximatedEquations;
  input BackendDAE.Variables allVars;
  input BackendDAE.EquationArray allEqs;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.Variables outsetS_vars;
  input list<BackendDAE.Equation> outsetS_eq;
protected
  list<Integer> matchedeq, matchedknownssetc, matchedunknownssetc, matchedknownssets, matchedunknownssets;
  list<Integer> tmpunknowns, tmpknowns, tmplist1, tmplist2, tmplist3, tmplist1sets, setstmp;
  list<Integer> tmplistvar1, tmplistvar2, tmplistvar3, sets_eqs, sets_vars, extractedeqs;
  Integer eqnumber, varnumber;
  list<tuple<Integer,list<Integer>>> var_dependencytree, eq_dependencytree;
  String str, resstr;
  list<BackendDAE.Var> var, convar;
algorithm

  print("\n\nAutomatic Verification Steps of DataReconciliation Algorithm"+ "\n" + UNDERLINE + "\n");

  var := List.map1r(listReverse(knowns), BackendVariable.getVarAt, allVars);
  BackendDump.dumpVarList(var, "knownVariables:"+ dumplistInteger(listReverse(knowns)));
  print("-SET_C:"+ dumplistInteger(setc)+ "\n" + "-SET_S:" + dumplistInteger(sets) +"\n\n");

  //Condition-1
  matchedeq := List.intersectionOnTrue(setc, sets, intEq);
  print("Condition-1 " + "\"SET_C and SET_S must not have no equations in common\"" + "\n" + UNDERLINE + "\n");
  if listEmpty(matchedeq) then
    print("-Passed\n\n");
  else
    print("-Failed\n");
    BackendDump.dumpEquationList(List.map1r(matchedeq, BackendEquation.get, allEqs),"-Equations Found in SET_C and SET_S:" + dumplistInteger(matchedeq));
    Error.addMessage(Error.INTERNAL_ERROR, {": Condition 1- Failed : The system is ill-posed."});
    fail();
  end if;

  (matchedknownssetc, matchedunknownssetc) := getVariableOccurence(setc, mExt, knowns);
  (matchedknownssets, matchedunknownssets) := getVariableOccurence(sets, mExt, knowns);

  // Condition -2
  print("Condition-2 " + "\"All variables of interest must be involved in SET_C or SET_S\"" + "\n" +UNDERLINE  +"\n");
  (tmplist1, tmplist2, tmplist3) := List.intersection1OnTrue(matchedknownssetc, knowns, intEq);

  if listEmpty(tmplist3) then
    print("-Passed \n");
    BackendDump.dumpVarList(List.map1r(tmplist1, BackendVariable.getVarAt, allVars), "-SET_C has all known variables:" + dumplistInteger(tmplist1));
   // check in sets
  elseif not listEmpty(tmplist3) then
    (tmplist1sets, tmplist2, _) := List.intersection1OnTrue(tmplist3, matchedknownssets, intEq);
    if not listEmpty(tmplist2) then
      str := dumplistInteger(tmplist2);
      print("-Failed\n");
      BackendDump.dumpVarList(List.map1r(tmplist2, BackendVariable.getVarAt, allVars), "knownVariables not Found:" + dumplistInteger(tmplist2));
      Error.addMessage(Error.INTERNAL_ERROR, {": Condition 2- Failed : The system is ill-posed."});
      fail();
    end if;
    print("-Passed \n");
    BackendDump.dumpVarList(List.map1r(tmplist1, BackendVariable.getVarAt, allVars), "-SET_C has known variables:" + dumplistInteger(tmplist1));
    BackendDump.dumpVarList(List.map1r(tmplist1sets, BackendVariable.getVarAt, allVars), "-SET_S has known variables:" + dumplistInteger(tmplist1sets));
  end if;

  //Condition-3
  print("Condition-3 " +"\"SET_C equations must be strictly less than Variable of Interest\"" + "\n" + UNDERLINE +"\n");
  if (listLength(setc) < listLength(knowns) and not listEmpty(setc)) then
    print("-Passed"+ "\n" + "-SET_C contains:" + intString(listLength(setc)) + " equations < " + intString(listLength(knowns))+" known variables \n\n");
  else
    resstr:="-Failed"+ "\n" + "-SET_C contains:" + intString(listLength(setc)) + " equations  > " + intString(listLength(knowns)) +" known variables \n\n";
    print(resstr);
    Error.addMessage(Error.INTERNAL_ERROR, {": Condition 3-Failed : The system is ill-posed."});
    fail();
  end if;

  //Condition-4
  print("Condition-4 " +"\"SET_S should contain all intermediate variables involved in SET_C\"" + "\n" + UNDERLINE +"\n");
  (tmplistvar1, tmplistvar2, tmplistvar3) := List.intersection1OnTrue(matchedunknownssetc, matchedunknownssets, intEq);

  if listEmpty(matchedunknownssetc) then
    print("-Passed"+"\n"+"-SET_C contains No Intermediate Variables \n\n");
    return;
  else
    BackendDump.dumpVarList(List.map1r(matchedunknownssetc, BackendVariable.getVarAt, allVars), "-SET_C has intermediate variables:" + dumplistInteger(matchedunknownssetc));

    if listEmpty(tmplistvar2) then
      BackendDump.dumpVarList(List.map1r(tmplistvar1, BackendVariable.getVarAt, allVars), "-SET_S has intermediate variables involved in SET_C:" + dumplistInteger(tmplistvar1));
      print("-Passed\n\n");
    else
      BackendDump.dumpVarList(List.map1r(tmplistvar2, BackendVariable.getVarAt, allVars), "-SET_S does not have intermediate variables involved in SET_C:" + dumplistInteger(tmplistvar2));
      Error.addMessage(Error.INTERNAL_ERROR, {": Condition 4-Failed : The system is ill-posed."});
      fail();
    end if;
  end if;

  //Condition-5
  print("Condition-5 " +"\"SET_S should be square \"" + "\n" + UNDERLINE +"\n");
  if(listEmpty(sets)) then
    print("-Passed"+"\n"+"-SET_S contains 0 intermediate variables and 0 equations \n\n");
    return;
  else
    if(listLength(sets)==listLength(BackendVariable.varList(outsetS_vars))) then
      print("-Passed" + "\n "+ "Set_S has " + intString(listLength(sets)) + " equations and " + intString(listLength(BackendVariable.varList(outsetS_vars))) + " variables\n\n");
    else
      print("-Failed" + "\n "+ "Set_S has " + intString(listLength(sets)) + " equations and " + intString(listLength(BackendVariable.varList(outsetS_vars))) + " variables\n\n");
      Error.addMessage(Error.INTERNAL_ERROR, {": Condition 5-Failed Set_S is not square: The system is ill-posed."});
      fail();
    end if;
  end if;
end VerifyDataReconciliation;

public function getVariableOccurence
  "return list of knowns and unknowns variables from set-C or Set-S"
  input list<Integer> setCOrSetS;
  input ExtAdjacencyMatrix mext;
  input list<Integer> knowns;
  output list<Integer> knownvariables={};
  output list<Integer> unknownvariables={};
protected
  list<Integer> vars;
  Integer eq;
algorithm
  for i in setCOrSetS loop
    for j in mext loop
      (eq, vars) := j;
      if intEq(i, eq) then
         /*print("\n Equations matched=>");
         print(anyString(eq));
         print("=>");
         print(anyString(vars));*/
        for var in vars loop
          if listMember(var, knowns) then
            knownvariables := var :: knownvariables;
          else
            unknownvariables := var :: unknownvariables;
          end if;
        end for;
      end if;
    end for;
  end for;
  knownvariables := List.unique(knownvariables);
  unknownvariables := List.unique(unknownvariables);
end getVariableOccurence;

/* function which dumps the variable names to csv file */
public function dumpToCsv
  input String instring;
  input list<BackendDAE.Var> invar;
  output String outstring="";
protected
  DAE.ComponentRef cr;
algorithm
  for i in invar loop
    cr := BackendVariable.varCref(i);
    outstring := outstring + ComponentReference.crefStr(cr) + "\n";
  end for;
  outstring := instring+outstring;
end dumpToCsv;

protected function dumpEquationString "Helper function to e.g. dump equations"
  input BackendDAE.Equation inEquation;
  output String outString;
algorithm
  outString := match (inEquation)
    local
      String s1, s2, s3, s4, res;
      DAE.Exp e1, e2, e, cond, start, stop, iter;
      list<DAE.Exp> expl;
      DAE.ComponentRef cr;
      BackendDAE.Equation eqn;
      BackendDAE.WhenEquation weqn;
      BackendDAE.EquationAttributes attr;
      DAE.Algorithm alg;
      DAE.ElementSource source;
      list<list<BackendDAE.Equation>> eqnstrue;
      list<BackendDAE.Equation> eqnsfalse, eqns;
      list<BackendDAE.WhenOperator> whenStmtLst;
    case (BackendDAE.EQUATION(exp = e1, scalar = e2))
      equation
        s1 = ExpressionDump.printExp2Str(e1, "", NONE(), NONE());
        s2 = ExpressionDump.printExp2Str(e2, "", NONE(), NONE());
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.COMPLEX_EQUATION(left = e1, right = e2))
      equation
        s1 = ExpressionDump.printExp2Str(e1, "", NONE(), NONE());
        s2 = ExpressionDump.printExpStr(e2);
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.ARRAY_EQUATION(left = e1, right = e2))
      equation
        s1 = ExpressionDump.printExp2Str(e1, "", NONE(), NONE());
        s2 = ExpressionDump.printExp2Str(e2, "", NONE(), NONE());
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.SOLVED_EQUATION(componentRef = cr, exp = e2))
      equation
        s1 = ComponentReference.printComponentRefStr(cr);
        s1 = System.stringReplace(s1, ".", "_");
        s1 = System.stringReplace(s1, "$", "");
        s2 = ExpressionDump.printExp2Str(e2, "", NONE(), NONE());
        res = stringAppendList({s1," = ",s2});
      then
        res;
    case (BackendDAE.WHEN_EQUATION(whenEquation = weqn))
      equation
        res = BackendDump.whenEquationString(weqn, true);
      then
        res;
    case (BackendDAE.RESIDUAL_EQUATION(exp = e))
      equation
        s1 = ExpressionDump.printExp2Str(e, "", NONE(), NONE());
        res = stringAppendList({s1, "= 0"});
      then
        res;
    case (BackendDAE.ALGORITHM(alg = alg, source = source))
      equation
        res = DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg, source)});
      then
        res;
    case (BackendDAE.IF_EQUATION(conditions=e1::expl, eqnstrue=eqns::eqnstrue, eqnsfalse=eqnsfalse))
      equation
        s1 = ExpressionDump.printExp2Str(e1, "", NONE(), NONE());
        s2 = stringDelimitList(List.map(eqns, dumpEquationString),"\n  ");
        s3 = stringAppendList({"if ",s1," then\n  ",s2});
        res = BackendDump.ifequationString(expl, eqnstrue, eqnsfalse, s3);
      then
        res;
    case BackendDAE.FOR_EQUATION(iter = iter, start = start, stop = stop, body = eqn)
      equation
        s1 = ExpressionDump.printExp2Str(iter, "", NONE(), NONE()) + " in " + ExpressionDump.printExp2Str(start, "", NONE(), NONE()) + " : " + ExpressionDump.printExp2Str(stop, "", NONE(), NONE());
        s2 = dumpEquationString(eqn);
        res = stringAppendList({"for ", s1, " loop \n    ", s2, "; end for; "});
      then
        res;
  end match;
end dumpEquationString;

annotation(__OpenModelica_Interface="backend");
end DataReconciliation;

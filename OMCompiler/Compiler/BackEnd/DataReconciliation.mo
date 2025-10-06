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
import Settings;

protected type ExtAdjacencyMatrixRow = tuple<Integer,list<Integer>>;
protected type ExtAdjacencyMatrix = list<ExtAdjacencyMatrixRow>;

public constant String UNDERLINE = "==========================================================================";

public function newExtractionAlgorithm
  "runs the new simplified version of the extraction algorithm for D.1
  which returns SET-C and SET-S "
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystem currentSystem;
  BackendDAE.EquationArray newOrderedEquationArray, outOtherEqns, outResidualEqns;
  list<BackendDAE.Equation> newEqnsLst, setC_Eq, setS_Eq, residualEquations, complexEquationList, swappedEquationList;
  BackendDAE.AdjacencyMatrix adjacencyMatrix;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn, match1, match2;
  list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  Integer varCount, eqCount;
  list<Integer> ebltEqsLst, matchedEqsLst, approximatedEquations, constantEquations, tempSetC, setC, tempSetS, setS, boundaryConditionEquations, bindingEquations;
  ExtAdjacencyMatrix sBltAdjacencyMatrix;
  list<BackendDAE.Var> paramVars, setSVars, residualVars, unMeasuredVariables;
  list<DAE.ComponentRef> cr_lst;
  BackendDAE.Jacobian simCodeJacobian, simCodeJacobianH;
  BackendDAE.Shared shared;
  String str, modelicaOutput, modelicaFileName, auxillaryConditionsFilename, auxillaryEquations, intermediateEquationsFilename, intermediateEquations;
  list<tuple<Integer, list<Integer>>> mappedEbltSetS;
  list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations;

  list<Integer> allVarsList, knowns, unknowns, boundaryConditionVars, exactEquationVars, extractedVarsfromSetS, constantVars, knownVariablesWithEquationBinding, boundaryConditionTaggedEquationSolvedVars, unknownVarsInSetC, unMeasuredVariablesOfInterest;
  BackendDAE.Variables inputVars, outDiffVars, outOtherVars, outResidualVars;
  Integer procedureCount;
  Boolean debug = false, status = false;

algorithm

  if Flags.isSet(Flags.DUMP_DATARECONCILIATION) then
    debug := true;
  end if ;

  {currentSystem} := inDAE.eqs;
  shared := inDAE.shared;

  print("\nModelInfo: " + shared.info.fileNamePrefix + "\n" + UNDERLINE + "\n\n");

  (currentSystem, shared) := setBoundaryConditionEquationsAndVars(currentSystem, inDAE.shared, debug);

  // run the recursive procedure until status = true
  procedureCount := 1;
  setBFailedBoundaryConditionEquations := {};
  while (not status) loop
    BackendDump.dumpVariables(currentSystem.orderedVars, "OrderedVariables");
    BackendDump.dumpEquationArray(currentSystem.orderedEqs, "OrderedEquation");
    //BackendDump.dumpVariables(shared.globalKnownVars, "GlobalKnownVars");

    allVarsList := List.intRange(BackendVariable.varsSize(currentSystem.orderedVars));
    varCount := currentSystem.orderedVars.numberOfVars;
    eqCount := BackendEquation.equationArraySize(currentSystem.orderedEqs);

    // get the adjacency matrix with the current square system
    (adjacencyMatrix, _, mapEqnIncRow, mapIncRowEqn) := BackendDAEUtil.adjacencyMatrixScalar(currentSystem, BackendDAE.NORMAL(), NONE(), BackendDAEUtil.isInitializationDAE(shared));

    // get adjacency matrix with equations and list of variables present (e.g) {(1,{2,3,4}),(2,{4,5,6})}
    sBltAdjacencyMatrix := getSBLTAdjacencyMatrix(adjacencyMatrix);

    // Perform standard matching on the square system
    (match1, match2, _, _, _) := Matching.RegularMatching(adjacencyMatrix, varCount, eqCount);

    BackendDump.dumpMatching(match1);

    // get list of solved Vars and equations
    (solvedEqsAndVarsInfo, matchedEqsLst) := getSolvedEquationAndVarsInfo(match1);

    // get the binding equation list and vars
    bindingEquations := getBindingEquation(currentSystem, mapIncRowEqn);
    bindingEquations := List.flatten(List.map1r(bindingEquations, listGet, arrayList(mapEqnIncRow)));

    // Extract equations tagged as annotation(__OpenModelica_BoundaryCondition = true) and annotation(__OpenModelica_ApproximatedEquation = true)
    (approximatedEquations, boundaryConditionEquations) := getEquationsTaggedApproximatedOrBoundaryCondition(BackendEquation.equationList(currentSystem.orderedEqs), 1);

    if debug then
      BackendDump.dumpEquationList(List.map1r(approximatedEquations, BackendEquation.get, currentSystem.orderedEqs), "ApproximatedEquations");
      BackendDump.dumpEquationList(List.map1r(boundaryConditionEquations, BackendEquation.get, currentSystem.orderedEqs), "boundaryConditionEquations");
    end if;

    // get the Index mapping for approximated and constant equations
    approximatedEquations := List.flatten(List.map1r(approximatedEquations, listGet, arrayList(mapEqnIncRow)));
    boundaryConditionEquations := List.flatten(List.map1r(boundaryConditionEquations, listGet, arrayList(mapEqnIncRow)));

    // extract boundaryConditionTaggedEquations Variables
    boundaryConditionTaggedEquationSolvedVars := getBoundaryConditionVariables(boundaryConditionEquations, solvedEqsAndVarsInfo);

    if debug then
      print("\nApproximated and BoundaryCondition Equation Indexes :\n===========================================");
      print("\nApproximatedEquationIndexes      :" + dumplistInteger(approximatedEquations));
      print("\nBoundayConditionEquationIndexes  :" + dumplistInteger(boundaryConditionEquations));
      print("\n");
    end if;


    // extract knowns, BoundaryConditions and exactEquationVars
    (knowns, boundaryConditionVars, exactEquationVars, unMeasuredVariablesOfInterest) := getVariablesBlockCategories(currentSystem.orderedVars, allVarsList);
    // update the boundaryCondtions vars
    boundaryConditionVars := listAppend(boundaryConditionVars, boundaryConditionTaggedEquationSolvedVars) annotation(__OpenModelica_DisableListAppendWarning=true);

    if debug then
      print("\nVariablesCategories\n=============================");
      print("\nknownVars                    :" + dumplistInteger(knowns));
      print("\nboundaryConditionVars        :" + dumplistInteger(boundaryConditionVars));
      print("\nexactEquationVars            :" + dumplistInteger(exactEquationVars));
      print("\nadjacencyMatrix              :" + anyString(adjacencyMatrix) + "\n");
    end if;

    // dump the information
    dumpSetSVarsSolvedInfo(matchedEqsLst, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Standard BLT of the original model");
    BackendDump.dumpVarList(List.map1r(listReverse(knowns), BackendVariable.getVarAt, currentSystem.orderedVars),"Variables of interest");
    BackendDump.dumpVarList(List.map1r(listReverse(boundaryConditionVars), BackendVariable.getVarAt, currentSystem.orderedVars),"Boundary conditions");
    dumpSetSVarsSolvedInfo(bindingEquations, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Binding equations");
    BackendDump.dumpEquationList(List.map1r(approximatedEquations, BackendEquation.get, currentSystem.orderedEqs), "Approximated equations");
    BackendDump.dumpEquationList(List.map1r(boundaryConditionEquations, BackendEquation.get, currentSystem.orderedEqs), "boundary condition equations");

    // get E-BLT Blocks
    ebltEqsLst := getEBLTEquations(knowns, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem);
    // remove binding equations from E-BLT
    ebltEqsLst := List.setDifferenceOnTrue(ebltEqsLst, bindingEquations, intEq);

    // dump EBLT Equations which computes variables of interest
    dumpSetSVarsSolvedInfo(ebltEqsLst, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "E-BLT: equations that compute the variables of interest");

    (currentSystem, tempSetS, mappedEbltSetS, status, setBFailedBoundaryConditionEquations) := traverseEBLTAndExtractSetCAndSetS(currentSystem, ebltEqsLst, sBltAdjacencyMatrix, knowns, boundaryConditionVars, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, solvedEqsAndVarsInfo, debug, setBFailedBoundaryConditionEquations, bindingEquations);

    if not status then
      print("\nExtraction procedure failed for iteration count: " + intString(procedureCount) + ", re-running with modified model\n" + UNDERLINE + "\n");
    end if;

    procedureCount := procedureCount + 1;

  end while;

  print("\nExtraction procedure is successfully completed in iteration count: " + intString(procedureCount-1) + "\n" + UNDERLINE + "\n");

  // remove approximated equations from Set-C and Set-S
  ebltEqsLst := List.setDifferenceOnTrue(ebltEqsLst, approximatedEquations, intEq);
  tempSetS := List.setDifferenceOnTrue(tempSetS, approximatedEquations, intEq);

  // temporary work around for condition-1 failing, basically complex equations or array equations should not be present in Set-C and should be swaped another equation Set-S
  (ebltEqsLst, tempSetS, complexEquationList, swappedEquationList) := swapComplexEquationsInSetC(ebltEqsLst, tempSetS, mappedEbltSetS, currentSystem, mapIncRowEqn);

  if debug then
    dumpSetSVarsSolvedInfo(tempSetS, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Set-S Solved-Variables Information");
  end if;

  //print("\nUnmapped set of equations after extraction algorithm\n" + UNDERLINE + "\n" +"SET_C: "+dumplistInteger(ebltEqsLst)+"\n" +"SET_S: "+ dumplistInteger(tempSetS)+ "\n\n" );
  extractedVarsfromSetS := getVariablesAfterExtraction({}, tempSetS, sBltAdjacencyMatrix);
  extractedVarsfromSetS := List.setDifferenceOnTrue(extractedVarsfromSetS, knowns, intEq);

  setC := List.unique(getAbsoluteIndexHelper(ebltEqsLst, mapIncRowEqn));
  setS := List.unique(getAbsoluteIndexHelper(tempSetS, mapIncRowEqn));
  //setC := List.setDifferenceOnTrue(setC, setS, intEq);

  setC_Eq := getEquationsFromSBLTAndEBLT(setC, currentSystem.orderedEqs, {});
  setS_Eq := getEquationsFromSBLTAndEBLT(setS, currentSystem.orderedEqs, {});

  print("\nFinal set of equations after extraction algorithm\n" + UNDERLINE + "\n" +"SET_C: "+dumplistInteger(setC)+"\n" +"SET_S: "+ dumplistInteger(setS)+ "\n\n" );

  BackendDump.dumpEquationArray(BackendEquation.listEquation(setC_Eq), "SET_C");
  BackendDump.dumpEquationArray(BackendEquation.listEquation(setS_Eq), "SET_S");

  // get unmeasured variables
  unMeasuredVariables := List.map1r(listReverse(unMeasuredVariablesOfInterest), BackendVariable.getVarAt, currentSystem.orderedVars);

  // prepare outdiff vars (i.e) variables of interest
  outDiffVars := BackendVariable.listVar(List.map1r(knowns, BackendVariable.getVarAt, currentSystem.orderedVars));
  // set uncertain variables unreplaceable attributes to be true
  outDiffVars := BackendVariable.listVar(List.map1(BackendVariable.varList(outDiffVars), BackendVariable.setVarUnreplaceable, true));

  // prepare set-c residual equations and residual vars
  (_, residualEquations) := BackendEquation.traverseEquationArray(BackendEquation.listEquation(setC_Eq), BackendEquation.traverseEquationToScalarResidualForm, (shared.functionTree, {}));
  (residualEquations, residualVars) := BackendEquation.convertResidualsIntoSolvedEquations(listReverse(residualEquations), "$res_F_", 1);
  outResidualVars := BackendVariable.listVar(listReverse(residualVars));
  outResidualEqns := BackendEquation.listEquation(residualEquations);

  // prepare set-s other equations
  outOtherEqns := BackendEquation.listEquation(setS_Eq);
  // extract parameters from set-s equations
  paramVars := BackendEquation.equationsVars(outOtherEqns, shared.globalKnownVars);
  //setSVars  := BackendEquation.equationsVars(outOtherEqns, currentSystem.orderedVars);

  // prepare variables stucture from list of extracted equations
  outOtherVars := BackendVariable.listVar(List.map1r(extractedVarsfromSetS, BackendVariable.getVarAt, currentSystem.orderedVars));

  dumpSetSVars(outOtherVars, "Unknown variables in SET_S");
  //BackendDump.dumpVariables(BackendVariable.listVar(setSVars),"Unknown variables in SET_S_checks ");
  BackendDump.dumpVariables(BackendVariable.listVar(paramVars),"Parameters in SET_S");

  // write set-C equation to HTML file
  auxillaryConditionsFilename := shared.info.fileNamePrefix + "_AuxiliaryConditions.html";
  auxillaryEquations := dumpExtractedEquationsToHTML(BackendEquation.listEquation(setC_Eq), "Auxiliary conditions" + " (" + intString(BackendEquation.getNumberOfEquations(BackendEquation.listEquation(setC_Eq))) + ", " + intString(BackendEquation.equationArraySize(BackendEquation.listEquation(setC_Eq))) + ")");
  System.writeFile(auxillaryConditionsFilename, auxillaryEquations);

  // write set-S equation to HTML file
  intermediateEquationsFilename := shared.info.fileNamePrefix + "_IntermediateEquations.html";

  intermediateEquations := dumpExtractedEquationsToHTML(BackendEquation.listEquation(setS_Eq), "Intermediate equations for measured variables" + " (" + intString(BackendEquation.getNumberOfEquations(BackendEquation.listEquation(setS_Eq))) + ", " + intString(BackendEquation.equationArraySize(BackendEquation.listEquation(setS_Eq))) + ")");
  System.writeFile(intermediateEquationsFilename, intermediateEquations);

  // write relatedBoundaryConditions equations to a file
  dumpRelatedBoundaryConditionsEquations(setBFailedBoundaryConditionEquations, shared.info.fileNamePrefix);

  VerifyDataReconciliation(ebltEqsLst, tempSetS, knowns, boundaryConditionVars, sBltAdjacencyMatrix, solvedEqsAndVarsInfo, exactEquationVars, approximatedEquations, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, outOtherVars, setS_Eq, shared, setC, setS, listLength(unMeasuredVariablesOfInterest));

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
  shared.dataReconciliationData := SOME(BackendDAE.DATA_RECON(symbolicJacobian=simCodeJacobian, setcVars=outResidualVars, datareconinputs=outDiffVars, setBVars=SOME(BackendVariable.listVar(unMeasuredVariables)), symbolicJacobianH=NONE(), relatedBoundaryConditions = listLength(setBFailedBoundaryConditionEquations)));

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

end newExtractionAlgorithm;

protected function dumpRelatedBoundaryConditionsEquations
  input list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations;
  input String fileNamePrefix;
protected
  BackendDAE.Equation eq;
  String str;
  Integer count;
algorithm
  count := 1;
  str :="";
  str := "<html>\n<body>\n<h2> Related boundary conditions" + " (" + intString(listLength(setBFailedBoundaryConditionEquations)) + ") " +"</h2>\n<ol>";
  if listEmpty(setBFailedBoundaryConditionEquations) then
    str := "The set of Related boundary conditions are empty.";
  else
    for i in setBFailedBoundaryConditionEquations loop
      (_, eq, _) := i;
      //str := str + intString(count) + ": "  + BackendDump.equationString(eq) + "\n";
      str := str + "\n" + "  <li>" + "(" +  intString(BackendEquation.equationSize(eq)) + "): " + BackendDump.equationString(eq) + " </li>";
      //count := count + 1;
    end for;
    str := str + "\n</ol>\n</body>\n</html>";
  end if;
  System.writeFile(fileNamePrefix + "_relatedBoundaryConditionsEquations.html", str);
end dumpRelatedBoundaryConditionsEquations;

public function extractBoundaryCondition
  "runs the new simplified version of the extraction algorithm for D.2
  which returns SET-B and SET-S'"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystem currentSystem;
  BackendDAE.EquationArray newOrderedEquationArray, outOtherEqns, outResidualEqns, outBoundaryConditionEquations;
  list<BackendDAE.Equation> newEqnsLst, setC_Eq, setS_Eq, residualEquations, complexEquationList, swappedEquationList, failedboundaryConditionEquations;
  BackendDAE.AdjacencyMatrix adjacencyMatrix;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn, match1, match2;
  list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  Integer varCount, eqCount;
  list<Integer> ebltEqsLst, matchedEqsLst, approximatedEquations, constantEquations, tempSetC, setC, tempSetS, setS, boundaryConditionEquations, bindingEquations, setSPrime;
  ExtAdjacencyMatrix sBltAdjacencyMatrix;
  list<BackendDAE.Var> paramVars, setSVars, tempSetSVars, residualVars, residualVarsSetS, knownVars, failedboundaryConditionVars, extraVarsinSetSPrime, unMeasuredVariables;
  list<DAE.ComponentRef> cr_lst;
  BackendDAE.Jacobian simCodeJacobian;
  BackendDAE.Shared shared;
  String str, modelicaOutput, modelicaFileName, auxillaryConditionsFilename, auxillaryEquations, intermediateEquationsFilename, intermediateEquations;
  list<tuple<Integer, list<Integer>>> mappedEbltSetS;
  list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations;

  list<Integer> allVarsList, knowns, unknowns, boundaryConditionVars, exactEquationVars, extractedVarsfromSetS, constantVars, knownVariablesWithEquationBinding, boundaryConditionTaggedEquationSolvedVars, unknownVarsInSetC, unMeasuredVariablesOfInterest;
  BackendDAE.Variables inputVars, outDiffVars, outOtherVars, outResidualVars, outBoundaryConditionVars;
  Integer procedureCount;
  Boolean debug = false, status = false;

algorithm

  if Flags.isSet(Flags.DUMP_DATARECONCILIATION) then
    debug := true;
  end if ;

  {currentSystem} := inDAE.eqs;
  shared := inDAE.shared;

  print("\nModelInfo: " + shared.info.fileNamePrefix + "\n" + UNDERLINE + "\n\n");

  (currentSystem, shared) := setBoundaryConditionEquationsAndVars(currentSystem, inDAE.shared, debug);

  // run the recursive procedure until status = true
  procedureCount := 1;
  setBFailedBoundaryConditionEquations := {};
  while (not status) loop
    BackendDump.dumpVariables(currentSystem.orderedVars, "OrderedVariables");
    BackendDump.dumpEquationArray(currentSystem.orderedEqs, "OrderedEquation");
    //BackendDump.dumpVariables(shared.globalKnownVars, "GlobalKnownVars");

    allVarsList := List.intRange(BackendVariable.varsSize(currentSystem.orderedVars));
    varCount := currentSystem.orderedVars.numberOfVars;
    eqCount := BackendEquation.equationArraySize(currentSystem.orderedEqs);

    // get the adjacency matrix with the current square system
    (adjacencyMatrix, _, mapEqnIncRow, mapIncRowEqn) := BackendDAEUtil.adjacencyMatrixScalar(currentSystem, BackendDAE.NORMAL(), NONE(), BackendDAEUtil.isInitializationDAE(shared));

    // get adjacency matrix with equations and list of variables present (e.g) {(1,{2,3,4}),(2,{4,5,6})}
    sBltAdjacencyMatrix := getSBLTAdjacencyMatrix(adjacencyMatrix);

    // Perform standard matching on the square system
    (match1, match2, _, _, _) := Matching.RegularMatching(adjacencyMatrix, varCount, eqCount);

    BackendDump.dumpMatching(match1);

    // get list of solved Vars and equations
    (solvedEqsAndVarsInfo, matchedEqsLst) := getSolvedEquationAndVarsInfo(match1);

    // get the binding equation list and vars
    bindingEquations := getBindingEquation(currentSystem, mapIncRowEqn);
    bindingEquations := List.flatten(List.map1r(bindingEquations, listGet, arrayList(mapEqnIncRow)));

    // Extract equations tagged as annotation(__OpenModelica_BoundaryCondition = true) and annotation(__OpenModelica_ApproximatedEquation = true)
    (approximatedEquations, boundaryConditionEquations) := getEquationsTaggedApproximatedOrBoundaryCondition(BackendEquation.equationList(currentSystem.orderedEqs), 1);

    if debug then
      BackendDump.dumpEquationList(List.map1r(approximatedEquations, BackendEquation.get, currentSystem.orderedEqs), "ApproximatedEquations");
      BackendDump.dumpEquationList(List.map1r(boundaryConditionEquations, BackendEquation.get, currentSystem.orderedEqs), "boundaryConditionEquations");
    end if;

    // get the Index mapping for approximated and constant equations
    approximatedEquations := List.flatten(List.map1r(approximatedEquations, listGet, arrayList(mapEqnIncRow)));
    boundaryConditionEquations := List.flatten(List.map1r(boundaryConditionEquations, listGet, arrayList(mapEqnIncRow)));

    // extract boundaryConditionTaggedEquations Variables
    boundaryConditionTaggedEquationSolvedVars := getBoundaryConditionVariables(boundaryConditionEquations, solvedEqsAndVarsInfo);

    if debug then
      print("\nApproximated and BoundaryCondition Equation Indexes :\n===========================================");
      print("\nApproximatedEquationIndexes      :" + dumplistInteger(approximatedEquations));
      print("\nBoundayConditionEquationIndexes  :" + dumplistInteger(boundaryConditionEquations));
      print("\n");
    end if;


    // extract knowns, BoundaryConditions and exactEquationVars
    (knowns, boundaryConditionVars, exactEquationVars, unMeasuredVariablesOfInterest) := getVariablesBlockCategories(currentSystem.orderedVars, allVarsList);
    // update the boundaryCondtions vars
    boundaryConditionVars := listAppend(boundaryConditionVars, boundaryConditionTaggedEquationSolvedVars) annotation(__OpenModelica_DisableListAppendWarning=true);

    if debug then
      print("\nVariablesCategories\n=============================");
      print("\nknownVars                    :" + dumplistInteger(knowns));
      print("\nboundaryConditionVars        :" + dumplistInteger(boundaryConditionVars));
      print("\nexactEquationVars            :" + dumplistInteger(exactEquationVars));
      print("\nadjacencyMatrix              :" + anyString(adjacencyMatrix) + "\n");
    end if;

    // dump the information
    dumpSetSVarsSolvedInfo(matchedEqsLst, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Standard BLT of the original model");
    BackendDump.dumpVarList(List.map1r(listReverse(knowns), BackendVariable.getVarAt, currentSystem.orderedVars),"Variables of interest");
    BackendDump.dumpVarList(List.map1r(listReverse(boundaryConditionVars), BackendVariable.getVarAt, currentSystem.orderedVars),"Boundary conditions");
    dumpSetSVarsSolvedInfo(bindingEquations, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Binding equations");
    BackendDump.dumpEquationList(List.map1r(approximatedEquations, BackendEquation.get, currentSystem.orderedEqs), "Approximated equations");
    BackendDump.dumpEquationList(List.map1r(boundaryConditionEquations, BackendEquation.get, currentSystem.orderedEqs), "boundary condition equations");

    // get E-BLT Blocks
    ebltEqsLst := getEBLTEquations(knowns, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem);
    // remove binding equations from E-BLT
    ebltEqsLst := List.setDifferenceOnTrue(ebltEqsLst, bindingEquations, intEq);

    // dump EBLT Equations which computes variables of interest
    dumpSetSVarsSolvedInfo(ebltEqsLst, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "E-BLT: equations that compute the variables of interest");

    (currentSystem, tempSetS, mappedEbltSetS, status, setBFailedBoundaryConditionEquations) := traverseEBLTAndExtractSetCAndSetS(currentSystem, ebltEqsLst, sBltAdjacencyMatrix, knowns, boundaryConditionVars, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, solvedEqsAndVarsInfo, debug, setBFailedBoundaryConditionEquations, bindingEquations);

    if not status then
      print("\nExtraction procedure failed for iteration count: " + intString(procedureCount) + ", re-running with modified model\n" + UNDERLINE + "\n");
    end if;

    procedureCount := procedureCount + 1;

  end while;

  print("\nExtraction procedure is successfully completed in iteration count: " + intString(procedureCount-1) + "\n" + UNDERLINE + "\n");

  dumpFailedBoundaryConditionEquationAndVars(setBFailedBoundaryConditionEquations, currentSystem.orderedVars);

  (_, setSPrime, failedboundaryConditionEquations, failedboundaryConditionVars, status) := ExtractSetSPrime(currentSystem, setBFailedBoundaryConditionEquations, sBltAdjacencyMatrix, knowns, boundaryConditionVars, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, solvedEqsAndVarsInfo, bindingEquations, debug);

  // remove approximated equations from Set-S_Prime
  setSPrime := List.setDifferenceOnTrue(setSPrime, approximatedEquations, intEq);

  if debug then
    dumpSetSVarsSolvedInfo(setSPrime, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Set-S Solved-Variables Information");
  end if;

  setS := List.unique(getAbsoluteIndexHelper(setSPrime, mapIncRowEqn));

  setS_Eq := getEquationsFromSBLTAndEBLT(setS, currentSystem.orderedEqs, {});
  //setS_Eq := listAppend(failedboundaryConditionEquations, setS_Eq);

  print("\nFinal set of equations after extraction algorithm\n" + UNDERLINE + "\n");
  BackendDump.dumpEquationArray(BackendEquation.listEquation(failedboundaryConditionEquations), "SET_B");
  BackendDump.dumpEquationArray(BackendEquation.listEquation(setS_Eq), "SET_S'");

  paramVars := BackendEquation.equationsVars(BackendEquation.listEquation(listAppend(failedboundaryConditionEquations, setS_Eq)), shared.globalKnownVars);
  setSVars  := BackendEquation.equationsVars(BackendEquation.listEquation(listAppend(failedboundaryConditionEquations, setS_Eq)), currentSystem.orderedVars);
  (knownVars, setSVars) := List.extractOnTrue(setSVars, BackendVariable.varHasUncertainValueRefine); // filter the variables of iterest and intermediate Vars

  (_, setSVars) := List.extract1OnTrue(setSVars, isBoundaryConditionVars, failedboundaryConditionVars); // filter the variables of iterest and intermediate Vars

  (extraVarsinSetSPrime, _) := List.extract1OnTrue(setSVars, isBoundaryConditionVars, List.map1r(listReverse(boundaryConditionVars), BackendVariable.getVarAt, currentSystem.orderedVars)); // filter the overdetermined variables in set-S'

  BackendDump.dumpVarList(failedboundaryConditionVars, "Boundary condition Vars'");
  BackendDump.dumpVarList(setSVars, "Intermediate vars in set-S'");
  BackendDump.dumpVarList(knownVars, "Known vars in set-S'");
  BackendDump.dumpVarList(paramVars, "Param vars in set-S'");
  //BackendDump.dumpVarList(extraVarsinSetSPrime, "extra vars in set-S'");

  // get unmeasured variables
  unMeasuredVariables := List.map1r(listReverse(unMeasuredVariablesOfInterest), BackendVariable.getVarAt, currentSystem.orderedVars);

  // prepare outdiff vars (i.e) variables of interest
  outDiffVars := BackendVariable.listVar(List.map1r(knowns, BackendVariable.getVarAt, currentSystem.orderedVars));

  // set uncertain variables unreplaceable attributes to be true
  outDiffVars := BackendVariable.listVar(List.map1(BackendVariable.varList(outDiffVars), BackendVariable.setVarUnreplaceable, true));

  // set boundaryConditionsVars unreplaceable attributes to be true
  outBoundaryConditionVars := BackendVariable.listVar(List.map1(listReverse(failedboundaryConditionVars), BackendVariable.setVarUnreplaceable, true));

  // boundary condition equations
  outBoundaryConditionEquations := BackendEquation.listEquation(failedboundaryConditionEquations);

  // prepare set-s other equations
  outOtherEqns := BackendEquation.listEquation(setS_Eq);

  // prepare variables stucture from list of extracted equations
  outOtherVars := BackendVariable.listVar(setSVars);

  //dumpSetSVars(outOtherVars, "Unknown variables in SET_S'");

  // write set-B equation to HTML file
  auxillaryConditionsFilename := shared.info.fileNamePrefix + "_BoundaryConditionsEquations.html";
  auxillaryEquations := dumpExtractedEquationsToHTML(outBoundaryConditionEquations, "Boundary conditions" + " (" + intString(BackendEquation.getNumberOfEquations(outBoundaryConditionEquations)) + ", " + intString(BackendEquation.equationArraySize(outBoundaryConditionEquations)) + ")");
  System.writeFile(auxillaryConditionsFilename, auxillaryEquations);

  // write set-S' equation to HTML file
  intermediateEquationsFilename := shared.info.fileNamePrefix + "_BoundaryConditionIntermediateEquations.html";
  intermediateEquations := dumpExtractedEquationsToHTML(outOtherEqns, "Intermediate equations" + " (" + intString(BackendEquation.getNumberOfEquations(outOtherEqns)) + ", " + intString(BackendEquation.equationArraySize(outOtherEqns)) + ")");
  System.writeFile(intermediateEquationsFilename, intermediateEquations);

  VerifySetSPrime(outBoundaryConditionVars, outOtherVars, outDiffVars, extraVarsinSetSPrime, outBoundaryConditionEquations, outOtherEqns, shared, listLength(ebltEqsLst), listLength(setBFailedBoundaryConditionEquations), false);

  if debug then
    BackendDump.dumpVariables(outDiffVars, "Jacobian_knownVariables");
    BackendDump.dumpEquationArray(outBoundaryConditionEquations, "Jacobian_ResidualEquation");
    BackendDump.dumpVariables(outBoundaryConditionVars, "Jacobian_outResidualVars");
    BackendDump.dumpEquationArray(outOtherEqns, "Jacobian_outOtherEquations");
    BackendDump.dumpVariables(outOtherVars, "Jacobian_outOtherVars");
  end if;

  // generate symbolicJacobian matrix F
  (simCodeJacobian, shared) := SymbolicJacobian.getSymbolicJacobian(outDiffVars, outBoundaryConditionEquations, outBoundaryConditionVars, outOtherEqns, outOtherVars, shared, outOtherVars, "F", false);

  // put the jacobian also into shared object
  shared.dataReconciliationData := SOME(BackendDAE.DATA_RECON(symbolicJacobian=simCodeJacobian, setcVars=outBoundaryConditionVars, datareconinputs=outDiffVars, setBVars=SOME(BackendVariable.listVar(unMeasuredVariables)), symbolicJacobianH=NONE(), relatedBoundaryConditions = listLength(setBFailedBoundaryConditionEquations)));

  // Prepare the final DAE System with Set-B and Set-S' equations
  currentSystem := BackendDAEUtil.setEqSystEqs(currentSystem, BackendEquation.merge(outBoundaryConditionEquations, outOtherEqns));
  currentSystem := BackendDAEUtil.setEqSystVars(currentSystem, BackendVariable.mergeVariables(outBoundaryConditionVars, outOtherVars));

  inputVars := BackendVariable.listVar(List.map1(BackendVariable.varList(outDiffVars), BackendVariable.setVarDirection, DAE.INPUT()));
  shared := BackendDAEUtil.setSharedGlobalKnownVars(shared, BackendVariable.mergeVariables(shared.globalKnownVars, inputVars));

  // BackendDump.dumpVariables(currentSystem.orderedVars, "FinalOrderedVariables");
  // BackendDump.dumpEquationArray(currentSystem.orderedEqs, "FinalOrderedEquation");
  // BackendDump.dumpVariables(shared.globalKnownVars, "FinalGlobalKnownVars");

  // write the list of boundary condition variables to txt file "XXX_BoundaryConditionVars.txt"
  str := dumpToCsv("", BackendVariable.varList(outBoundaryConditionVars));
  System.writeFile(shared.info.fileNamePrefix + "_BoundaryConditionVars.txt", str);


  // write the new Reconciled vars and equations to .mo File
  modelicaFileName := "Reconciled_"+ System.stringReplace(shared.info.fileNamePrefix, ".","_");
  modelicaOutput := "/* This is not Complete ThermoSysPro variables and functions needs to be corrected manually */\n";
  modelicaOutput := modelicaOutput + "model " + modelicaFileName ;
  // Variables Declaration section
  modelicaOutput := dumpExtractedVars(modelicaOutput, BackendVariable.varList(outDiffVars), "Variables of Interest");
  modelicaOutput := dumpExtractedVars(modelicaOutput, paramVars, "parameters in SET-S");
  modelicaOutput := dumpExtractedVars(modelicaOutput, failedboundaryConditionVars, "boundary condition Vars");
  //modelicaOutput := dumpResidualVars(modelicaOutput, BackendVariable.varList(outResidualVars), "residualVars");
  modelicaOutput := dumpExtractedVars(modelicaOutput, BackendVariable.varList(outOtherVars), "remaining variables in setS");
  // Equation Declaration section
  modelicaOutput := modelicaOutput + "\nequation";
  modelicaOutput := dumpExtractedEquations(modelicaOutput, BackendEquation.listEquation(failedboundaryConditionEquations), "boundary condition equations");
  modelicaOutput := dumpExtractedEquations(modelicaOutput, outOtherEqns, "remaining equations in Set-S'");
  modelicaOutput := modelicaOutput + "\nend " + modelicaFileName + ";";
  System.writeFile(modelicaFileName + ".mo", modelicaOutput);

  // update the DAE with new system of equations and vars computed by the dataReconciliation extraction algorithm
  outDAE := BackendDAE.DAE({currentSystem}, shared);
end extractBoundaryCondition;


public function stateEstimation
  "runs the stateEstimation extraction algorithm
  which returns SET-C, SET-S and SET-S'"
  input BackendDAE.BackendDAE inDAE;
  output BackendDAE.BackendDAE outDAE;
protected
  BackendDAE.EqSystem currentSystem;
  BackendDAE.EquationArray newOrderedEquationArray, outOtherEqns, outOtherEqnsSetSPrime, outResidualEqns, outBoundaryConditionEquations;
  list<BackendDAE.Equation> newEqnsLst, setC_Eq, setS_Eq, setSPrime_Eq, residualEquations, complexEquationList, swappedEquationList, failedboundaryConditionEquations, allDaeEqs;
  BackendDAE.AdjacencyMatrix adjacencyMatrix;
  array<list<Integer>> mapEqnIncRow;
  array<Integer> mapIncRowEqn, match1, match2;
  list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  Integer varCount, eqCount;
  list<Integer> ebltEqsLst, matchedEqsLst, approximatedEquations, constantEquations, tempSetC, setC, tempSetS, setS, setSPrime_, boundaryConditionEquations, bindingEquations, setSPrime, unMeasuredEqsLst;
  ExtAdjacencyMatrix sBltAdjacencyMatrix;
  list<BackendDAE.Var> paramVars, setSVars, setCVars, tempSetSVars, residualVars, residualVarsSetS, knownVars, failedboundaryConditionVars, extraVarsinSetSPrime, unMeasuredVariables;
  list<DAE.ComponentRef> cr_lst;
  BackendDAE.Jacobian simCodeJacobian, simCodeJacobianH;
  BackendDAE.Shared shared;
  String str, modelicaOutput, modelicaFileName, auxillaryConditionsFilename, auxillaryEquations, intermediateEquationsFilename, intermediateEquations;
  list<tuple<Integer, list<Integer>>> mappedEbltSetS;
  list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations;

  list<Integer> allVarsList, knowns, unknowns, unMeasuredVariablesOfInterest, failedboundaryConditionEquationIndex, boundaryConditionVars, exactEquationVars, extractedVarsfromSetS, constantVars, knownVariablesWithEquationBinding, boundaryConditionTaggedEquationSolvedVars, unknownVarsInSetC;
  BackendDAE.Variables inputVars, outDiffVars, outOtherVars, outResidualVars, outBoundaryConditionVars, outOtherVarsSetSPrime;
  Integer procedureCount, numRelatedBoundaryConditions;
  Boolean debug = false, status = false;

algorithm

  if Flags.isSet(Flags.DUMP_DATARECONCILIATION) then
    debug := true;
  end if ;

  {currentSystem} := inDAE.eqs;
  shared := inDAE.shared;

  print("\nModelInfo: " + shared.info.fileNamePrefix + "\n" + UNDERLINE + "\n\n");

  (currentSystem, shared) := setBoundaryConditionEquationsAndVars(currentSystem, inDAE.shared, debug);

  // run the recursive procedure until status = true
  procedureCount := 1;
  setBFailedBoundaryConditionEquations := {};
  while (not status) loop
    BackendDump.dumpVariables(currentSystem.orderedVars, "OrderedVariables");
    BackendDump.dumpEquationArray(currentSystem.orderedEqs, "OrderedEquation");
    //BackendDump.dumpVariables(shared.globalKnownVars, "GlobalKnownVars");

    allVarsList := List.intRange(BackendVariable.varsSize(currentSystem.orderedVars));
    varCount := currentSystem.orderedVars.numberOfVars;
    eqCount := BackendEquation.equationArraySize(currentSystem.orderedEqs);

    // get the adjacency matrix with the current square system
    (adjacencyMatrix, _, mapEqnIncRow, mapIncRowEqn) := BackendDAEUtil.adjacencyMatrixScalar(currentSystem, BackendDAE.NORMAL(), NONE(), BackendDAEUtil.isInitializationDAE(shared));

    // get adjacency matrix with equations and list of variables present (e.g) {(1,{2,3,4}),(2,{4,5,6})}
    sBltAdjacencyMatrix := getSBLTAdjacencyMatrix(adjacencyMatrix);

    // Perform standard matching on the square system
    (match1, match2, _, _, _) := Matching.RegularMatching(adjacencyMatrix, varCount, eqCount);

    BackendDump.dumpMatching(match1);

    // get list of solved Vars and equations
    (solvedEqsAndVarsInfo, matchedEqsLst) := getSolvedEquationAndVarsInfo(match1);

    // get the binding equation list and vars
    bindingEquations := getBindingEquation(currentSystem, mapIncRowEqn);
    bindingEquations := List.flatten(List.map1r(bindingEquations, listGet, arrayList(mapEqnIncRow)));

    // Extract equations tagged as annotation(__OpenModelica_BoundaryCondition = true) and annotation(__OpenModelica_ApproximatedEquation = true)
    (approximatedEquations, boundaryConditionEquations) := getEquationsTaggedApproximatedOrBoundaryCondition(BackendEquation.equationList(currentSystem.orderedEqs), 1);

    if debug then
      BackendDump.dumpEquationList(List.map1r(approximatedEquations, BackendEquation.get, currentSystem.orderedEqs), "ApproximatedEquations");
      BackendDump.dumpEquationList(List.map1r(boundaryConditionEquations, BackendEquation.get, currentSystem.orderedEqs), "boundaryConditionEquations");
    end if;

    // get the Index mapping for approximated and constant equations
    approximatedEquations := List.flatten(List.map1r(approximatedEquations, listGet, arrayList(mapEqnIncRow)));
    boundaryConditionEquations := List.flatten(List.map1r(boundaryConditionEquations, listGet, arrayList(mapEqnIncRow)));

    // extract boundaryConditionTaggedEquations Variables
    boundaryConditionTaggedEquationSolvedVars := getBoundaryConditionVariables(boundaryConditionEquations, solvedEqsAndVarsInfo);

    if debug then
      print("\nApproximated and BoundaryCondition Equation Indexes :\n===========================================");
      print("\nApproximatedEquationIndexes      :" + dumplistInteger(approximatedEquations));
      print("\nBoundayConditionEquationIndexes  :" + dumplistInteger(boundaryConditionEquations));
      print("\n");
    end if;


    // extract knowns, BoundaryConditions and exactEquationVars
    (knowns, boundaryConditionVars, exactEquationVars, unMeasuredVariablesOfInterest) := getVariablesBlockCategories(currentSystem.orderedVars, allVarsList);
    // update the boundaryCondtions vars
    boundaryConditionVars := listAppend(boundaryConditionVars, boundaryConditionTaggedEquationSolvedVars) annotation(__OpenModelica_DisableListAppendWarning=true);

    if debug then
      print("\nVariablesCategories\n=============================");
      print("\nknownVars                    :" + dumplistInteger(knowns));
      print("\nunMeasuredVars               :" + dumplistInteger(unMeasuredVariablesOfInterest));
      print("\nboundaryConditionVars        :" + dumplistInteger(boundaryConditionVars));
      print("\nexactEquationVars            :" + dumplistInteger(exactEquationVars));
      print("\nadjacencyMatrix              :" + anyString(adjacencyMatrix) + "\n");
    end if;

    // dump the information
    dumpSetSVarsSolvedInfo(matchedEqsLst, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Standard BLT of the original model");
    BackendDump.dumpVarList(List.map1r(listReverse(knowns), BackendVariable.getVarAt, currentSystem.orderedVars),"Variables of interest");
    BackendDump.dumpVarList(List.map1r(listReverse(unMeasuredVariablesOfInterest), BackendVariable.getVarAt, currentSystem.orderedVars),"unMeasured Variables of interest");
    BackendDump.dumpVarList(List.map1r(listReverse(boundaryConditionVars), BackendVariable.getVarAt, currentSystem.orderedVars),"Boundary conditions");
    dumpSetSVarsSolvedInfo(bindingEquations, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Binding equations");
    BackendDump.dumpEquationList(List.map1r(approximatedEquations, BackendEquation.get, currentSystem.orderedEqs), "Approximated equations");
    BackendDump.dumpEquationList(List.map1r(boundaryConditionEquations, BackendEquation.get, currentSystem.orderedEqs), "boundary condition equations");

    // get E-BLT Blocks
    ebltEqsLst := getEBLTEquations(knowns, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem);
    // remove binding equations from E-BLT
    ebltEqsLst := List.setDifferenceOnTrue(ebltEqsLst, bindingEquations, intEq);

    // dump EBLT Equations which computes variables of interest
    dumpSetSVarsSolvedInfo(ebltEqsLst, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "E-BLT: equations that compute the variables of interest");

    (currentSystem, tempSetS, mappedEbltSetS, status, setBFailedBoundaryConditionEquations) := traverseEBLTAndExtractSetCAndSetS(currentSystem, ebltEqsLst, sBltAdjacencyMatrix, knowns, boundaryConditionVars, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, solvedEqsAndVarsInfo, debug, setBFailedBoundaryConditionEquations, bindingEquations);

    if not status then
      print("\nExtraction procedure failed for iteration count: " + intString(procedureCount) + ", re-running with modified model\n" + UNDERLINE + "\n");
    end if;

    procedureCount := procedureCount + 1;

  end while;

  print("\nExtraction procedure is successfully completed in iteration count: " + intString(procedureCount-1) + "\n" + UNDERLINE + "\n");

  // remove approximated equations from Set-C and Set-S
  ebltEqsLst := List.setDifferenceOnTrue(ebltEqsLst, approximatedEquations, intEq);
  tempSetS := List.setDifferenceOnTrue(tempSetS, approximatedEquations, intEq);

  extractedVarsfromSetS := getVariablesAfterExtraction({}, tempSetS, sBltAdjacencyMatrix);
  extractedVarsfromSetS := List.setDifferenceOnTrue(extractedVarsfromSetS, knowns, intEq);

  setC := List.unique(getAbsoluteIndexHelper(ebltEqsLst, mapIncRowEqn));
  setS := List.unique(getAbsoluteIndexHelper(tempSetS, mapIncRowEqn));
  //setC := List.setDifferenceOnTrue(setC, setS, intEq);

  setC_Eq := getEquationsFromSBLTAndEBLT(setC, currentSystem.orderedEqs, {});
  setS_Eq := getEquationsFromSBLTAndEBLT(setS, currentSystem.orderedEqs, {});

  print("\nFinal set of equations after extraction algorithm\n" + UNDERLINE + "\n" +"SET_C: "+dumplistInteger(setC)+"\n" +"SET_S: "+ dumplistInteger(setS)+ "\n\n" );

  BackendDump.dumpEquationArray(BackendEquation.listEquation(setC_Eq), "SET_C");
  BackendDump.dumpEquationArray(BackendEquation.listEquation(setS_Eq), "SET_S");

  // prepare outdiff vars (i.e) variables of interest
  outDiffVars := BackendVariable.listVar(List.map1r(knowns, BackendVariable.getVarAt, currentSystem.orderedVars));
  // set uncertain variables unreplaceable attributes to be true
  outDiffVars := BackendVariable.listVar(List.map1(BackendVariable.varList(outDiffVars), BackendVariable.setVarUnreplaceable, true));

  // prepare set-c residual equations and residual vars
  (_, residualEquations) := BackendEquation.traverseEquationArray(BackendEquation.listEquation(setC_Eq), BackendEquation.traverseEquationToScalarResidualForm, (shared.functionTree, {}));
  (residualEquations, residualVars) := BackendEquation.convertResidualsIntoSolvedEquations(listReverse(residualEquations), "$res_F_", 1);
  outResidualVars := BackendVariable.listVar(listReverse(residualVars));
  outResidualEqns := BackendEquation.listEquation(residualEquations);

  // prepare set-s other equations
  outOtherEqns := BackendEquation.listEquation(setS_Eq);
  // extract parameters from set-s equations
  paramVars := BackendEquation.equationsVars(outOtherEqns, shared.globalKnownVars);
  //setSVars  := BackendEquation.equationsVars(outOtherEqns, currentSystem.orderedVars);

  // prepare variables stucture from list of extracted equations
  outOtherVars := BackendVariable.listVar(List.map1r(extractedVarsfromSetS, BackendVariable.getVarAt, currentSystem.orderedVars));

  dumpSetSVars(outOtherVars, "Unknown variables in SET_S");
  //BackendDump.dumpVariables(BackendVariable.listVar(setSVars),"Unknown variables in SET_S_checks ");
  BackendDump.dumpVariables(BackendVariable.listVar(paramVars),"Parameters in SET_S");

  // write set-C equation to HTML file
  auxillaryConditionsFilename := shared.info.fileNamePrefix + "_AuxiliaryConditions.html";
  auxillaryEquations := dumpExtractedEquationsToHTML(BackendEquation.listEquation(setC_Eq), "Auxiliary conditions" + " (" + intString(BackendEquation.getNumberOfEquations(BackendEquation.listEquation(setC_Eq))) + ", " + intString(BackendEquation.equationArraySize(BackendEquation.listEquation(setC_Eq))) + ")");
  System.writeFile(auxillaryConditionsFilename, auxillaryEquations);

  // write set-S equation to HTML file
  intermediateEquationsFilename := shared.info.fileNamePrefix + "_IntermediateEquations.html";

  intermediateEquations := dumpExtractedEquationsToHTML(BackendEquation.listEquation(setS_Eq), "Intermediate equations for measured variables" + " (" + intString(BackendEquation.getNumberOfEquations(BackendEquation.listEquation(setS_Eq))) + ", " + intString(BackendEquation.equationArraySize(BackendEquation.listEquation(setS_Eq))) + ")");
  System.writeFile(intermediateEquationsFilename, intermediateEquations);

  // write relatedBoundaryConditions equations to a file
  dumpRelatedBoundaryConditionsEquations(setBFailedBoundaryConditionEquations, shared.info.fileNamePrefix);

  /* count the number of failed boundary conditions, as unmeasured variables of interest will be added to the list
   * when computing extraction algorithm for setSPrime
   */
  numRelatedBoundaryConditions := listLength(setBFailedBoundaryConditionEquations);

  VerifyDataReconciliation(ebltEqsLst, tempSetS, knowns, boundaryConditionVars, sBltAdjacencyMatrix, solvedEqsAndVarsInfo, exactEquationVars, approximatedEquations, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, outOtherVars, setS_Eq, shared, setC, setS, listLength(unMeasuredVariablesOfInterest));

  /*
   * Compute the boundary conditions algorithm for unmeasured variables of interest
  */

  // get equations that computes unmeasured variables Of interest
  unMeasuredEqsLst := getEBLTEquations(unMeasuredVariablesOfInterest, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem);
  // remove binding equations from E-BLT
  unMeasuredEqsLst := List.setDifferenceOnTrue(unMeasuredEqsLst, bindingEquations, intEq);

  unMeasuredVariables := List.map1r(listReverse(unMeasuredVariablesOfInterest), BackendVariable.getVarAt, currentSystem.orderedVars);

  dumpFailedBoundaryConditionEquationAndVars(setBFailedBoundaryConditionEquations, currentSystem.orderedVars, unMeasuredVariables, true);

  // prepare unmeasured equation list, along with boundary condition equations that failed the extraction of set-C and set-S
  (setBFailedBoundaryConditionEquations, failedboundaryConditionEquationIndex) := prepareUnmeasuredVariablesEquations(unMeasuredEqsLst, sBltAdjacencyMatrix, knowns, solvedEqsAndVarsInfo, currentSystem.orderedEqs, currentSystem.orderedVars, mapIncRowEqn, setBFailedBoundaryConditionEquations);

  dumpSetSVarsSolvedInfo(unMeasuredEqsLst, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "E-BLT: equations in the BLT that compute the unmeasured variables of interest");

  (_, setSPrime, failedboundaryConditionEquations, failedboundaryConditionVars, status) := ExtractSetSPrime(currentSystem, setBFailedBoundaryConditionEquations, sBltAdjacencyMatrix, knowns, boundaryConditionVars, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, solvedEqsAndVarsInfo, bindingEquations, debug);

  setSPrime := List.unique(listAppend(failedboundaryConditionEquationIndex, setSPrime));
  // remove approximated equations from Set-S_Prime
  setSPrime := List.setDifferenceOnTrue(setSPrime, approximatedEquations, intEq);
  setSPrime := List.setDifferenceOnTrue(setSPrime, unMeasuredEqsLst, intEq);

  if debug then
    dumpSetSVarsSolvedInfo(setSPrime, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Set-SPrime Solved-Variables Information");
  end if;

  setSPrime := List.unique(getAbsoluteIndexHelper(setSPrime, mapIncRowEqn));

  setSPrime_Eq := getEquationsFromSBLTAndEBLT(setSPrime, currentSystem.orderedEqs, {});
  // combine set-S Prime with setB
  //setSPrime_Eq := List.unique(listAppend(setSPrime_Eq, failedboundaryConditionEquations));

  BackendDump.dumpEquationArray(BackendEquation.listEquation(failedboundaryConditionEquations), "SET_B");
  BackendDump.dumpEquationArray(BackendEquation.listEquation(setSPrime_Eq), "SET_SPrime");

  paramVars := BackendEquation.equationsVars(BackendEquation.listEquation(setSPrime_Eq), shared.globalKnownVars);
  setSVars  := BackendEquation.equationsVars(BackendEquation.listEquation(setSPrime_Eq), currentSystem.orderedVars);
  (knownVars, setSVars) := List.extractOnTrue(setSVars, BackendVariable.varHasUncertainValueRefine); // filter the variables of iterest and intermediate Vars

  (_, setSVars) := List.extract1OnTrue(setSVars, isBoundaryConditionVars, failedboundaryConditionVars); // filter the variables of iterest and intermediate Vars

  (extraVarsinSetSPrime, _) := List.extract1OnTrue(setSVars, isBoundaryConditionVars, List.map1r(listReverse(boundaryConditionVars), BackendVariable.getVarAt, currentSystem.orderedVars)); // filter the overdetermined variables in set-S'

  if debug then
    //failedboundaryConditionVars := listAppend(setSVars, failedboundaryConditionVars);
    BackendDump.dumpVarList(unMeasuredVariables, "unmeasured variables");
    BackendDump.dumpVarList(setSVars, "Intermediate vars in set-S'");
    BackendDump.dumpVarList(knownVars, "Known vars in set-S'");
    BackendDump.dumpVarList(paramVars, "Param vars in set-S'");
    BackendDump.dumpVarList(extraVarsinSetSPrime, "extra vars in set-S'");
  end if;

  // set unmeasured variables unreplaceable attributes to be true
  outBoundaryConditionVars := BackendVariable.listVar(List.map1(listReverse(unMeasuredVariables), BackendVariable.setVarUnreplaceable, true));

  // boundary condition equations
  outBoundaryConditionEquations := BackendEquation.listEquation(failedboundaryConditionEquations);

  // prepare variables stucture from list of extracted equations for boundary conditions
  outOtherEqnsSetSPrime := BackendEquation.listEquation(setSPrime_Eq);

  // prepare intermediate vars in SET-SPRime
  outOtherVarsSetSPrime := BackendVariable.listVar(setSVars);

  dumpSetSVars(outOtherVarsSetSPrime, "Unknown variables in SET_SPrime");

  // write set-B equation to HTML file
  auxillaryConditionsFilename := shared.info.fileNamePrefix + "_BoundaryConditionsEquations.html";
  auxillaryEquations := dumpExtractedEquationsToHTML(outBoundaryConditionEquations, "Boundary conditions" + " (" + intString(BackendEquation.getNumberOfEquations(outBoundaryConditionEquations)) + ", " + intString(BackendEquation.equationArraySize(outBoundaryConditionEquations)) + ")");
  System.writeFile(auxillaryConditionsFilename, auxillaryEquations);

  // write set-S' combine set-B and Set-S' equation to HTML file
  intermediateEquationsFilename := shared.info.fileNamePrefix + "_BoundaryConditionIntermediateEquations.html";
  intermediateEquations := dumpExtractedEquationsToHTML(BackendEquation.listEquation(listAppend(failedboundaryConditionEquations, setSPrime_Eq)), "Intermediate equations for unmeasured variables " + " (" + intString(BackendEquation.getNumberOfEquations(BackendEquation.listEquation(listAppend(failedboundaryConditionEquations, setSPrime_Eq)))) + ", " + intString(BackendEquation.equationArraySize(BackendEquation.listEquation(listAppend(failedboundaryConditionEquations, setSPrime_Eq)))) + ")");
  System.writeFile(intermediateEquationsFilename, intermediateEquations);

  VerifySetSPrime(outBoundaryConditionVars, outOtherVarsSetSPrime, outDiffVars, extraVarsinSetSPrime, outBoundaryConditionEquations, outOtherEqnsSetSPrime, shared, listLength(setC), numRelatedBoundaryConditions, true);

  // Data Reconciliation jacobian
  if debug then
    BackendDump.dumpVariables(outDiffVars, "Jacobian_knownVariables");
    BackendDump.dumpVariables(outResidualVars, "Jacobian_outResidualVars");
    BackendDump.dumpVariables(outOtherVars, "Jacobian_outOtherVars");
    BackendDump.dumpEquationArray(outResidualEqns, "Jacobian_ResidualEquation");
    BackendDump.dumpEquationArray(outOtherEqns, "Jacobian_other_Equation");
  end if;

  // Boundary condition jacobian
  if debug then
    BackendDump.dumpVariables(outDiffVars, "Jacobian_knownVariables");
    BackendDump.dumpEquationArray(outBoundaryConditionEquations, "Jacobian_ResidualEquation");
    BackendDump.dumpVariables(outBoundaryConditionVars, "Jacobian_outResidualVars");
    BackendDump.dumpEquationArray(outOtherEqnsSetSPrime, "Jacobian_outOtherEquations");
    BackendDump.dumpVariables(outOtherVarsSetSPrime, "Jacobian_outOtherVars");
  end if;

  /*
    For state Estimation problem, we need to generate two jacobians for Data Reconciliation setC w.r.to setS
    and Boundary condition setB w.r.to setSPrime
  */
  // generate symbolicJacobian matrix F for Data Reconciliation
  (simCodeJacobian, shared) := SymbolicJacobian.getSymbolicJacobian(outDiffVars, outResidualEqns, outResidualVars, outOtherEqns, outOtherVars, shared, outOtherVars, "F", false);

  // generate symbolicJacobian matrix H for boundary conditions
  (simCodeJacobianH, shared) := SymbolicJacobian.getSymbolicJacobian(outDiffVars, outBoundaryConditionEquations, outBoundaryConditionVars, outOtherEqnsSetSPrime, outOtherVarsSetSPrime, shared, outOtherVarsSetSPrime, "H", false);

  // put the jacobian also into shared object
  shared.dataReconciliationData := SOME(BackendDAE.DATA_RECON(symbolicJacobian=simCodeJacobian, setcVars=outResidualVars, datareconinputs=outDiffVars, setBVars= SOME(outBoundaryConditionVars), symbolicJacobianH=SOME(simCodeJacobianH), relatedBoundaryConditions = numRelatedBoundaryConditions));

  // Prepare the final DAE System with Set-C, Set-S, Set-B and Set-S' equations

  // combine set-S and set-SPrime
  setSPrime_Eq := List.unique(listAppend(setSPrime_Eq, failedboundaryConditionEquations));
  setSPrime_Eq := List.unique(listAppend(setSPrime_Eq, setS_Eq));

  // combine set-SPrime with set-C
  allDaeEqs := List.unique(listAppend(setSPrime_Eq, residualEquations));


  //BackendDump.dumpEquationArray(BackendEquation.listEquation(setSPrime_Eq), "SET_SPrime_Updated");
  BackendDump.dumpEquationArray(BackendEquation.listEquation(allDaeEqs), "Final DAE with set-c, set-S and set-SPrime combined");

  paramVars := BackendEquation.equationsVars(BackendEquation.listEquation(allDaeEqs), shared.globalKnownVars);
  setSVars  := BackendEquation.equationsVars(BackendEquation.listEquation(allDaeEqs), currentSystem.orderedVars);
  // combine residual Vars with setSVars
  //setSVars := listAppend(residualVars, setSVars);

  // filter the variables of iterest and intermediate Vars
  (knownVars, setSVars) := List.extractOnTrue(setSVars, BackendVariable.varHasUncertainValueRefine);
  // filter the unmeasured variables and intermediate Vars
  (_, setSVars) := List.extractOnTrue(setSVars, BackendVariable.varHasUncertainValuePropagate);

  // combine unmeasured variables with attribute unreplaceable = true
  setSVars := listAppend(BackendVariable.varList(outBoundaryConditionVars), setSVars);

  BackendDump.dumpVarList(listAppend(setSVars, residualVars), "Intermediate vars in final DAE updated'");
  BackendDump.dumpVarList(paramVars, "parameters in final DAE updated");

  currentSystem := BackendDAEUtil.setEqSystEqs(currentSystem, BackendEquation.listEquation(allDaeEqs));
  currentSystem := BackendDAEUtil.setEqSystVars(currentSystem, BackendVariable.listVar(listAppend(setSVars, residualVars)));

  inputVars := BackendVariable.listVar(List.map1(BackendVariable.varList(outDiffVars), BackendVariable.setVarDirection, DAE.INPUT()));
  shared := BackendDAEUtil.setSharedGlobalKnownVars(shared, BackendVariable.mergeVariables(shared.globalKnownVars, inputVars));

  if debug then
    BackendDump.dumpVariables(currentSystem.orderedVars, "FinalOrderedVariables");
    BackendDump.dumpEquationArray(currentSystem.orderedEqs, "FinalOrderedEquation");
    BackendDump.dumpVariables(shared.globalKnownVars, "FinalGlobalKnownVars");
  end if;

  // write the list of known variables + unmeasured variables of interest to the csv file with the headers
  if not System.regularFileExists(inDAE.shared.info.fileNamePrefix + "_Inputs.csv") then
    str := "Variable Names,Measured Value-x,HalfWidthConfidenceInterval\n";
    str := dumpToCsv(str, BackendVariable.varList(outDiffVars));
    str := dumpToCsv(str, BackendVariable.varList(outBoundaryConditionVars));
    System.writeFile(shared.info.fileNamePrefix + "_Inputs.csv", str);
  end if;

  // write the list of unmeasured variables variables to txt file "XXX_BoundaryConditionVars.txt"
  str := dumpToCsv("", BackendVariable.varList(outBoundaryConditionVars));
  System.writeFile(shared.info.fileNamePrefix + "_BoundaryConditionVars.txt", str);

  // write the new Reconciled vars and equations to .mo File
  modelicaFileName := "Reconciled_"+ System.stringReplace(shared.info.fileNamePrefix, ".","_");
  modelicaOutput := "/* This is not Complete ThermoSysPro variables and functions needs to be corrected manually */\n";
  modelicaOutput := modelicaOutput + "model " + modelicaFileName ;
  // Variables Declaration section
  modelicaOutput := dumpExtractedVars(modelicaOutput, BackendVariable.varList(outDiffVars), "Variables of Interest");
  modelicaOutput := dumpExtractedVars(modelicaOutput, paramVars, "parameters");
  modelicaOutput := dumpResidualVars(modelicaOutput, BackendVariable.varList(outResidualVars), "residualVars");
  modelicaOutput := dumpExtractedVars(modelicaOutput, setSVars, "intermediate variables");

  // Equation Declaration section
  modelicaOutput := modelicaOutput + "\nequation";
  modelicaOutput := dumpExtractedEquations(modelicaOutput, currentSystem.orderedEqs, "extracted equations");
  modelicaOutput := modelicaOutput + "\nend " + modelicaFileName + ";";
  System.writeFile(modelicaFileName + ".mo", modelicaOutput);

  // update the DAE with new system of equations and vars computed by the dataReconciliation extraction algorithm
  outDAE := BackendDAE.DAE({currentSystem}, shared);
end stateEstimation;

protected function isBoundaryConditionVars
  input BackendDAE.Var setSVars;
  input list<BackendDAE.Var> boundaryConditionsVars;
  output Boolean result = false;
algorithm
  //for var in setSVars loop
    if listMember(setSVars, boundaryConditionsVars) then
      result := true;
    end if;
  //end for;
end isBoundaryConditionVars;

protected function dumpFailedBoundaryConditionEquationAndVars
  input list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations;
  input BackendDAE.Variables orderedVars;
  input list<BackendDAE.Var> unmeasuredVariables = {};
  input Boolean stateEstimation = false;
protected
  BackendDAE.Equation failedboundaryConditionEquation;
  Integer count, varIndex;
  BackendDAE.Var var;
  list<BackendDAE.Var> varlist;
algorithm
  if stateEstimation then
    print("\nStart of extraction procedure for unmeasured variables of interest\nSet of equations that failed the extraction of set S and that contain an unmeasured variable of interest: ("+ intString(listLength(setBFailedBoundaryConditionEquations)) + ")\n" + UNDERLINE);
  else
    print("\nStart of extraction procedure for boundary conditions\nSet of boundary conditions equations that failed the extraction of set S: ("+ intString(listLength(setBFailedBoundaryConditionEquations)) + ")\n" + UNDERLINE);
  end if;

  count := 1;
  varlist := {};
  for item in listReverse(setBFailedBoundaryConditionEquations) loop
    (varIndex, failedboundaryConditionEquation, _) := item;
    //var := BackendVariable.getVarAt(orderedVars, varIndex);
    varlist := BackendVariable.getVarAt(orderedVars, varIndex) :: varlist;
    print("\n" + intString(count) + ": "  + BackendDump.equationString(failedboundaryConditionEquation));
    count := count + 1;
  end for;
  print("\n");
  if stateEstimation then
    BackendDump.dumpVarList(unmeasuredVariables, "umeasured variables to be computed");
  else
    BackendDump.dumpVarList(listReverse(varlist), "Boundary conditions to be computed");
  end if;
end dumpFailedBoundaryConditionEquationAndVars;

protected function prepareUnmeasuredVariablesEquations
  input list<Integer> unMeasuredEqsLst;
  input ExtAdjacencyMatrix sBltAdjacencyMatrix;
  input list<Integer> knownVars;
  input list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  // input list<Integer> boundaryConditionVars;
  input BackendDAE.EquationArray orderedEqs;
  input BackendDAE.Variables orderedVars;
  input array<Integer> mapIncRowEqn;
  input output list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations = {};
  output list<Integer> failedboundaryConditionEquationIndex = {};
protected
  Integer varIndex, eqIndex;
  list<Integer> intermediateVars;
  BackendDAE.Equation unmeasuredEq;
  list<tuple<Integer, BackendDAE.Equation, list<Integer>>> unMeasuredVariablesAndEquations;
algorithm
  for eq in unMeasuredEqsLst loop
    varIndex := getSolvedVariableNumber(eq, solvedEqsAndVarsInfo);
    intermediateVars := getVariablesAfterExtraction({eq}, {}, sBltAdjacencyMatrix);
    intermediateVars := listReverse(List.setDifferenceOnTrue(intermediateVars, knownVars, intEq));
    //print("\n equation No: " + anyString(eq) + "==>" + anyString(varIndex));
    unmeasuredEq := BackendEquation.get(orderedEqs, mapIncRowEqn[eq]);
    setBFailedBoundaryConditionEquations := (varIndex, unmeasuredEq, intermediateVars) :: setBFailedBoundaryConditionEquations;
  end for;
  unMeasuredVariablesAndEquations := {};
  // filter only unmeasured variables of interest and equation
  for item in setBFailedBoundaryConditionEquations loop
    (varIndex, _, _) := item;
    if BackendVariable.varHasUncertainValuePropagate(BackendVariable.getVarAt(orderedVars, varIndex)) then
      unMeasuredVariablesAndEquations := item :: unMeasuredVariablesAndEquations;
    end if;
  end for;
  setBFailedBoundaryConditionEquations := List.unique(unMeasuredVariablesAndEquations);
end prepareUnmeasuredVariablesEquations;


protected function addUnmeasuredEquationtoBoundaryConditionEquationAndVars
  input output list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations = {};
  input BackendDAE.Variables orderedVars;
  input list<Integer> unMeasuredEqsLst;
protected
  BackendDAE.Equation failedboundaryConditionEquation;
  Integer count, varIndex;
  BackendDAE.Var var;
  list<BackendDAE.Var> varlist;
algorithm
  print("\nStart of extraction procedure for boundary conditions\nSet of boundary conditions equations that failed the extraction of set S: ("+ intString(listLength(setBFailedBoundaryConditionEquations)) + ")\n" + UNDERLINE);
  count := 1;
  varlist := {};
  for item in listReverse(setBFailedBoundaryConditionEquations) loop
    (varIndex, failedboundaryConditionEquation, _) := item;
    //var := BackendVariable.getVarAt(orderedVars, varIndex);
    varlist := BackendVariable.getVarAt(orderedVars, varIndex) :: varlist;
    //print("\n" + intString(count) + ": "  + BackendDump.equationString(failedboundaryConditionEquation));
    //count := count + 1;
  end for;
  print("\n");
  //BackendDump.dumpVarList(listReverse(varlist), "Boundary conditions to be computed");
end addUnmeasuredEquationtoBoundaryConditionEquationAndVars;

protected function getEBLTEquations
  "returns the E-BLT equations which is basically set-C for the new extraction algorithm"
  input list<Integer> knowns;
  input list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.EqSystem currentSystem;
  output list<Integer> ebltequations = {};
protected
  Integer eq, var;
algorithm
  for v in solvedEqsAndVarsInfo loop
    (eq, var) := v;
    if listMember(var, knowns) then
      ebltequations := eq :: ebltequations;
    end if;
  end for;
end getEBLTEquations;

protected function getBindingEquation
  "returns the binding equations"
  input BackendDAE.EqSystem currentSystem;
  input array<Integer> mapIncRowEqn;
  output list<Integer> bindingEquations = {};
protected
  Integer index = 1;
algorithm
  for eq in BackendEquation.equationList(currentSystem.orderedEqs) loop
    if (BackendEquation.isBindingEquation(eq)) then
      bindingEquations := index :: bindingEquations;
    end if;
    index := index + 1;
  end for;
end getBindingEquation;

protected function swapComplexEquationsInSetC
  "work around for condition-1 failed, because complex equations are detected
  in Set-C and it should be swapped with any simple equation in Set-S with procedure = success"
  input output list<Integer> ebltEqsLst;
  input output list<Integer> tempSetS;
  input list<tuple<Integer, list<Integer>>> mappedEbltSetS;
  input BackendDAE.EqSystem currentSystem;
  input array<Integer> mapIncRowEqn;
  output list<BackendDAE.Equation> complexEquationList;
  output list<BackendDAE.Equation> swappedEquationList;
protected
  Integer eqIndex;
  list<Integer> matchedEqsLst;
  BackendDAE.Equation eq, swapEq;
algorithm
  complexEquationList := {};
  swappedEquationList := {};
  for item in mappedEbltSetS loop
    (eqIndex, matchedEqsLst) := item;
    eq := BackendEquation.get(currentSystem.orderedEqs, mapIncRowEqn[eqIndex]);
    if BackendEquation.isComplexEquation(eq) then
      complexEquationList := eq :: complexEquationList;
      // swap complex equation in Set-C with simple equation in Set-S with procedure succeeded
      for index in matchedEqsLst loop
        swapEq := BackendEquation.get(currentSystem.orderedEqs, mapIncRowEqn[index]);
        if not BackendEquation.isComplexEquation(swapEq) then
          ebltEqsLst := List.removeOnTrue(eqIndex, intEq, ebltEqsLst); // remove the complex equation from set-C
          tempSetS := List.removeOnTrue(index, intEq, tempSetS); // remove the simple equation from set-S
          // swap the equations
          tempSetS := eqIndex :: tempSetS; // add the complex equation to set-S
          ebltEqsLst := index :: ebltEqsLst; // add the simple equation to set-C
          swappedEquationList := swapEq :: swappedEquationList;
          break;
        end if;
      end for;
    end if;
  end for;

  if not listEmpty(complexEquationList) then
    BackendDump.dumpEquationArray(BackendEquation.listEquation(listReverse(complexEquationList)), "Warning complex equation detected in Set-C");
    BackendDump.dumpEquationArray(BackendEquation.listEquation(listReverse(swappedEquationList)), "Swapping Equations from Set-S");
  end if;
end swapComplexEquationsInSetC;

protected function traverseEBLTAndExtractSetCAndSetS
  input output BackendDAE.EqSystem currentSystem;
  input list<Integer> ebltEquations;
  input ExtAdjacencyMatrix sBltAdjacencyMatrix;
  input list<Integer> knownVars;
  input list<Integer> boundaryConditionVars;
  input BackendDAE.Variables orderedVars;
  input BackendDAE.EquationArray orderedEqs;
  input array<Integer> mapIncRowEqn;
  input list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  input Boolean debug;
  output list<Integer> finalSetS;
  output list<tuple<Integer, list<Integer>>> mappedEbltSetS "eg. {(set-C eq, {Set-S equations})}";
  output Boolean outStatus = false;
  input output list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations "eg: {(varIndex, eq, intemediateVarsInEquation)}";
  input list<Integer> bindingEquations;
  //output list<tuple<Integer, Integer, list<Integer>>> setB;
protected
  list<Integer> intermediateVars, minimalSetS, visitedVars, eqlistToRemove, intermediateVarsInBoundaryConditionEquation;
  Boolean status;
  list<tuple<Integer, Integer>> setB;
  Integer varnumber, eqnumber, boundaryConditionVarIndex;
  BackendDAE.Var var;
  DAE.Exp lhs, rhs;
  BackendDAE.Equation eqn, failedboundaryConditionEquation;
  list<BackendDAE.Equation> newEqnLst;
algorithm
  print("\nExtracting SET-C and SET-S from E-BLT\nProcedure is applied on each equation in the E-BLT\n" + UNDERLINE);
  setB := {};
  eqlistToRemove := {};
  finalSetS := {};
  mappedEbltSetS := {};
  for eq in ebltEquations loop
    intermediateVars := getVariablesAfterExtraction({eq}, {}, sBltAdjacencyMatrix);
    intermediateVars := listReverse(List.setDifferenceOnTrue(intermediateVars, knownVars, intEq));
    dumpSetSTargetEquations(eq, solvedEqsAndVarsInfo, mapIncRowEqn, orderedEqs, orderedVars, ">>>");
    minimalSetS := {};
    visitedVars := {};
    status := true;
    (_, minimalSetS, visitedVars, status, boundaryConditionVarIndex) := extractNewMinimalSetS(intermediateVars, sBltAdjacencyMatrix, knownVars, boundaryConditionVars, orderedVars, orderedEqs, mapIncRowEqn, minimalSetS, visitedVars, solvedEqsAndVarsInfo, status, bindingEquations, true, debug);
    print("\nProcedure " + boolSuccessOrFailed(status) + "\n");
    // mapped Set-S equations for each individual E-BLt Blocks (e.g) {(1, {2, 3, 4})}
    mappedEbltSetS := (eq, listReverse(minimalSetS)) :: mappedEbltSetS;

    // add the equations to final Set-S
    for index in minimalSetS loop
      if not listMember(index, finalSetS) then
        finalSetS := index :: finalSetS;
      end if;
    end for;

    // if status == false, prepare setB = {(var, equation to be removed)}
    if not status then
      varnumber := getSolvedVariableNumber(eq, solvedEqsAndVarsInfo);
      if listEmpty(minimalSetS) then
        minimalSetS := {eq}; // first equation is detected as boundary condition equation
      end if;
      if not listMember(listHead(minimalSetS), eqlistToRemove) then
        eqlistToRemove := listHead(minimalSetS) :: eqlistToRemove;
        setB := (varnumber, listHead(minimalSetS)) :: setB;
        // store the failed boundary conditions equation for D.2 as they will be removed during extraction of set-C and set-S
        if not boundaryConditionVarExist(setBFailedBoundaryConditionEquations, boundaryConditionVarIndex) then
          intermediateVarsInBoundaryConditionEquation := getVariablesAfterExtraction({listHead(minimalSetS)}, {}, sBltAdjacencyMatrix);
          intermediateVarsInBoundaryConditionEquation := listReverse(List.setDifferenceOnTrue(intermediateVarsInBoundaryConditionEquation, knownVars, intEq));
          failedboundaryConditionEquation := BackendEquation.get(orderedEqs, mapIncRowEqn[listHead(minimalSetS)]);
          setBFailedBoundaryConditionEquations := (boundaryConditionVarIndex, failedboundaryConditionEquation, intermediateVarsInBoundaryConditionEquation) :: setBFailedBoundaryConditionEquations;
        end if;
      end if;
    end if;
  end for;

  if not listEmpty(setB) then
    newEqnLst := {};
    for item in listReverse(setB) loop
      (varnumber, eqnumber) := item;
      var := BackendVariable.getVarAt(orderedVars, varnumber);
      lhs := BackendVariable.varExp(var);
      rhs := DAE.Exp.RCONST(real = 0);
      eqn := BackendDAE.EQUATION(lhs, rhs, DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_BINDING);
      newEqnLst := eqn :: newEqnLst;
    end for;

    if debug then
      print("\nGenerate Modified Model, For each failed procedure, the equation involving the boundary condition that failed the procedure is replaced by x = 0 where x is the variable of interest of the procedure.\n");
      dumpSetSVarsSolvedInfo(eqlistToRemove, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Equations to remove");
      BackendDump.dumpEquationList(newEqnLst, "Equations to add");
    end if;

    eqlistToRemove := List.unique(List.map1r(eqlistToRemove, listGet, arrayList(mapIncRowEqn)));
    currentSystem := deleteEquationsFromEqSyst(currentSystem, eqlistToRemove);
    currentSystem.orderedEqs := BackendEquation.merge(currentSystem.orderedEqs, BackendEquation.listEquation(listReverse(newEqnLst)));
  else
    outStatus := true;
    finalSetS := listReverse(finalSetS);
    mappedEbltSetS := listReverse(mappedEbltSetS);
  end if;

end traverseEBLTAndExtractSetCAndSetS;

protected function ExtractSetSPrime
  input output BackendDAE.EqSystem currentSystem;
  input list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations "eg: {(varIndex, eq, intemediateVarsInEquation)}";
  input ExtAdjacencyMatrix sBltAdjacencyMatrix;
  input list<Integer> knownVars;
  input list<Integer> boundaryConditionVars;
  input BackendDAE.Variables orderedVars;
  input BackendDAE.EquationArray orderedEqs;
  input array<Integer> mapIncRowEqn;
  input list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  input list<Integer> bindingEquations;
  input Boolean debug;
  output list<Integer> finalSetS;
  output list<BackendDAE.Equation> failedboundaryConditionEquations;
  output list<BackendDAE.Var> failedboundaryConditionVars;
  output Boolean outStatus = false;
  //output list<tuple<Integer, Integer, list<Integer>>> setB;
protected
  list<Integer> intermediateVars, minimalSetS, visitedVars, intermediateVarsInBoundaryConditionEquation;
  Boolean status;
  Integer varnumber, eqnumber, boundaryConditionVarIndex;
  BackendDAE.Var var;
  DAE.Exp lhs, rhs;
  BackendDAE.Equation eq;
  list<BackendDAE.Equation> newEqnLst;
algorithm
  print("\nExtract set-S' to compute the boundary conditions\nProcedure is applied on each equation in the failed boundary conditions\n" + UNDERLINE);
  finalSetS := {};
  failedboundaryConditionEquations := {};
  failedboundaryConditionVars := {};
  for items in listReverse(setBFailedBoundaryConditionEquations) loop
    //intermediateVars := getVariablesAfterExtraction({eq}, {}, sBltAdjacencyMatrix);
    (boundaryConditionVarIndex, eq, intermediateVars) := items;
    failedboundaryConditionEquations := eq :: failedboundaryConditionEquations;
    failedboundaryConditionVars := BackendVariable.getVarAt(orderedVars, boundaryConditionVarIndex) :: failedboundaryConditionVars;
    intermediateVars := listReverse(List.setDifferenceOnTrue(intermediateVars, knownVars, intEq));
    //dumpSetSTargetEquations(eq, solvedEqsAndVarsInfo, mapIncRowEqn, orderedEqs, orderedVars, ">>>");
    print("\n" + ">>>" + BackendDump.equationString(eq));
    minimalSetS := {};
    visitedVars := {};
    status := true;
    (_, minimalSetS, visitedVars, status, _) := extractNewMinimalSetS(intermediateVars, sBltAdjacencyMatrix, knownVars, boundaryConditionVars, orderedVars, orderedEqs, mapIncRowEqn, minimalSetS, visitedVars, solvedEqsAndVarsInfo, status, bindingEquations, false, debug);
    print("\nProcedure " + boolSuccessOrFailed(status) + "\n");

    // add the equations to final Set-S
    for index in minimalSetS loop
      if not listMember(index, finalSetS) then
        finalSetS := index :: finalSetS;
      end if;
    end for;

  end for;

  failedboundaryConditionEquations := listReverse(failedboundaryConditionEquations);
  failedboundaryConditionVars := listReverse(failedboundaryConditionVars);

end ExtractSetSPrime;

protected function boundaryConditionVarExist
  input list<tuple<Integer, BackendDAE.Equation, list<Integer>>> setBFailedBoundaryConditionEquations "eg: {(varIndex, eq, intemediateVarsInEquation)}";
  input Integer boundaryConditionVarIndex;
  output Boolean status = false;
protected
  Integer varIndex;
algorithm
  for item in setBFailedBoundaryConditionEquations loop
    (varIndex, _, _) := item;
    if intEq(varIndex, boundaryConditionVarIndex) then
      status:= true;
      break;
    end if;
  end for;
end boundaryConditionVarExist;

protected function boolSuccessOrFailed
  "return success or failed"
  input Boolean status;
  output String outString;
algorithm
  outString := if status then "success" else "failed";
end boolSuccessOrFailed;

protected function extractNewMinimalSetS
  "construct a minimal set-S using recursive algorithm, which are needed to solve intermediate
  variables in set-c and also avoid complication when calculating jacobians"
  input output list<Integer> unknownsInSetC;
  input ExtAdjacencyMatrix sBltAdjacencyMatrix;
  input list<Integer> knownVars;
  input list<Integer> boundaryConditionVars;
  input BackendDAE.Variables orderedVars;
  input BackendDAE.EquationArray orderedEqs;
  input array<Integer> mapIncRowEqn;
  input output list<Integer> minimalSetS;
  input output list<Integer> visitedVars;
  input list<tuple<Integer,Integer>> solvedEqsAndVarsInfo;
  input output Boolean status;
  input list<Integer> bindingEquations;
  input Boolean extractSetCAndSetS;
  input Boolean debug;
  output Integer boundaryConditionVarIndex = -1;
protected
  Integer firstMatchedEquation, mappedEq, varIndex;
  BackendDAE.Var var;
  BackendDAE.Equation tmpEq;
  list<Integer> rest, vars, intermediateVars, V_EQ, intermediateVarsInMatchedEquation;
algorithm
  while not listEmpty(unknownsInSetC) loop
    varIndex :: rest := unknownsInSetC;
    visitedVars := varIndex :: visitedVars;
    var := BackendVariable.getVarAt(orderedVars, varIndex);

    // break the loop, when boundary condition detected only for D.1 when extracting setC and setS
    if listMember(varIndex, boundaryConditionVars) and extractSetCAndSetS then
      print("\n"+ ComponentReference.printComponentRefStr(var.varName) + " is a boundary condition ---> exit procedure");
      status := false;
      boundaryConditionVarIndex := varIndex;
      break;
    end if;

    mappedEq := getSolvedEquationNumber(varIndex, solvedEqsAndVarsInfo);

    if not listMember(mappedEq, bindingEquations) then
      minimalSetS := mappedEq :: minimalSetS;
      dumpSetSTargetEquations(mappedEq, solvedEqsAndVarsInfo, mapIncRowEqn, orderedEqs, orderedVars, "");
    end if;

    // get intermediate vars in matched equations
    vars := getVariablesAfterExtraction({mappedEq}, {}, sBltAdjacencyMatrix);

    // remove knownVars, already visited vars from intermediate var list
    intermediateVarsInMatchedEquation := List.setDifferenceOnTrue(vars, knownVars, intEq);
    intermediateVars := List.setDifferenceOnTrue(intermediateVarsInMatchedEquation, {varIndex}, intEq);
    intermediateVars := List.setDifferenceOnTrue(intermediateVars, visitedVars, intEq);

    rest := List.setDifferenceOnTrue(rest, visitedVars, intEq);

    // update the intermediate varlist in the loop
    unknownsInSetC := List.unique(listAppend(intermediateVars, rest));

    if debug then
      dumpMininimalExtraction(varIndex, var, mappedEq, mapIncRowEqn, orderedEqs, minimalSetS, intermediateVarsInMatchedEquation, rest, unknownsInSetC, false, visitedVars=visitedVars);
    end if;

  end while;
end extractNewMinimalSetS;

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
  String str, modelicaOutput, modelicaFileName, auxillaryConditionsFilename, auxillaryEquations, intermediateEquationsFilename, intermediateEquations;

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
    print("\nOverDetermined-Systems-Information :\n====================================\n");
    print("\nAdjacency Matrix     :" + anyString(adjacencyMatrix));
    print("\nNumber of Vars       :" + intString(varCount));
    print("\nNumber of Equations  :" + intString(eqCount));
    print("\n\n");
  end if;

  // Perform limited matching on the overdermined System to get subset of equations which are not matched to form the E-BLT
  (match1, match2, _, _, _) := Matching.RegularMatching(adjacencyMatrix, varCount, eqCount);

  BackendDump.dumpMatching(match1);

  // get list of solved Vars and equations
  (solvedEqsAndVarsInfo, matchedEqsLst) := getSolvedEquationAndVarsInfo(match1);
  // Find the list of equations which are not matched (i.e) Equations which forms the E-BLT
  unMatchedEqsLst := List.setDifference(List.intRange(eqCount), matchedEqsLst);
  //unMatchedEqsLst := {105, 138, 143, 144, 147, 148};
  // get the actual index of the Equation
  unMatchedEqsLstCorrectIndex := List.unique(List.map1r(unMatchedEqsLst, listGet, arrayList(mapIncRowEqn)));

  if debug then
    print("\nFinding unmatched subset of equations :\n=========================================\n");
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
    print("\nE-BLT Information\n================");
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
  (match1, match2, _, _, _) := Matching.RegularMatching(adjacencyMatrix, varCount, eqCount);
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
    print("\nCombined S-BLT and E-BLT Information\n================================");
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

  print("\nFINAL SET OF EQUATIONS After Reconciliation\n" + UNDERLINE + "\n" +"SET_C: "+dumplistInteger(tempSetC)+"\n" +"SET_S: "+ dumplistInteger(tempSetS)+ "\n\n" );
  if debug then
    dumpSetSVarsSolvedInfo(tempSetS, solvedEqsAndVarsInfo, mapIncRowEqn, currentSystem.orderedEqs, currentSystem.orderedVars, "Set-S Solved-Variables Information");
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
    print("\nSet-S after running minimal extraction algorithm\n" + UNDERLINE + "\n" +"SET_S: "+dumplistInteger(tempSetS)+ "\n\n");
  end if;

  extractedVarsfromSetS := getVariablesAfterExtraction({}, tempSetS, sBltAdjacencyMatrix);
  extractedVarsfromSetS := List.setDifferenceOnTrue(extractedVarsfromSetS, knowns, intEq);

  setC := List.unique(getAbsoluteIndexHelper(tempSetC, mapIncRowEqn));
  setS := List.unique(getAbsoluteIndexHelper(tempSetS, mapIncRowEqn));

  //print("\nFINAL SET OF EQUATIONS After Mapping\n" + UNDERLINE + "\n" +"SET_C: "+dumplistInteger(setC)+"\n" +"SET_S: "+ dumplistInteger(setS)+ "\n\n" );

  setC_Eq := getEquationsFromSBLTAndEBLT(setC, currentSystem.orderedEqs, e_BLT_EquationsWithIndex);
  setS_Eq := getEquationsFromSBLTAndEBLT(setS, currentSystem.orderedEqs, e_BLT_EquationsWithIndex);

  // dump minimal SET-S equations
  if not listEmpty(tempSetS) then
    BackendDump.dumpEquationArray(BackendEquation.listEquation(setS_Eq), "SET_S_After_Minimal_Extraction");
  else
    print("\nSET_S_After_Minimal_Extraction (0, 0)\n" + UNDERLINE +"\n\n");
  end if;

  // prepare outdiff vars (i.e) variables of interest
  outDiffVars := BackendVariable.listVar(List.map1r(knowns, BackendVariable.getVarAt, currentSystem.orderedVars));
  // set uncertain variables unreplaceable attributes to be true
  outDiffVars := BackendVariable.listVar(List.map1(BackendVariable.varList(outDiffVars), BackendVariable.setVarUnreplaceable, true));

  // prepare set-c residual equations and residual vars
  (_, residualEquations) := BackendEquation.traverseEquationArray(BackendEquation.listEquation(setC_Eq), BackendEquation.traverseEquationToScalarResidualForm, (shared.functionTree, {}));
  (residualEquations, residualVars) := BackendEquation.convertResidualsIntoSolvedEquations(listReverse(residualEquations), "$res_F_", 1);
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

  // write set-C equation to HTML file
  auxillaryConditionsFilename := shared.info.fileNamePrefix + "_AuxiliaryConditions.html";
  auxillaryEquations := dumpExtractedEquationsToHTML(BackendEquation.listEquation(setC_Eq), "Auxiliary conditions");
  System.writeFile(auxillaryConditionsFilename, auxillaryEquations);

  // write set-S equation to HTML file
  intermediateEquationsFilename := shared.info.fileNamePrefix + "_IntermediateEquations.html";
  intermediateEquations := dumpExtractedEquationsToHTML(BackendEquation.listEquation(setS_Eq), "Intermediate equations");
  System.writeFile(intermediateEquationsFilename, intermediateEquations);

  VerifyDataReconciliation(tempSetC, tempSetS, knowns, boundaryConditionVars, sBltAdjacencyMatrix, solvedEqsAndVarsInfo, exactEquationVars, approximatedEquations, currentSystem.orderedVars, currentSystem.orderedEqs, mapIncRowEqn, outOtherVars, setS_Eq, shared, setC, setS);

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
  shared.dataReconciliationData := SOME(BackendDAE.DATA_RECON(symbolicJacobian=simCodeJacobian, setcVars=outResidualVars, datareconinputs=outDiffVars, setBVars=NONE(), symbolicJacobianH=NONE(), relatedBoundaryConditions=0));

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
  input list<Integer> visitedVars = {};
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
    mappedEq := mapIncRowEqn[firstMatchedEquation];
    tmpEq := BackendEquation.get(orderedEqs, mappedEq);
    //print("\n" + "   ("  + intString(mappedEq) + "/"  + intString(firstMatchedEquation)  + "): " + BackendDump.equationString(tmpEq) + "\n");
    print("\nVarIndex                     : " + intString(varIndex));
    print("\nVariable Name                : " + ComponentReference.printComponentRefStr(var.varName));
    print("\nEquation Exist               : " + intString(firstMatchedEquation));
    print("\nmappedEquation               : " + intString(mappedEq));
    print("\nMatched Equation             : " + BackendDump.equationString(tmpEq));
    print("\nS'                           : " + dumplistInteger(minimalSetS));
    print("\nUnknowns in matchedEquation  : " + dumplistInteger(intermediateVars));
    print("\nVisited vars                 : " + dumplistInteger(visitedVars));
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

protected function dumpExtractedEquationsToHTML
  "returns the list of set-c equations in html file"
  input BackendDAE.EquationArray eqs;
  input String comment;
  output String outstring="";
algorithm
  if listEmpty(BackendEquation.equationList(eqs)) then
    outstring := "The set of " + comment + " is empty.";
  else
    outstring := "<html>\n<body>\n<h2>" + comment + "</h2>\n<ol>";
    for eq in BackendEquation.equationList(eqs) loop
      outstring := outstring + "\n" + "  <li>" + "(" +  intString(BackendEquation.equationSize(eq)) + "): " + BackendDump.equationString(eq) + " </li>";
    end for;
    outstring := outstring + "\n</ol>\n</body>\n</html>";
  end if;
end dumpExtractedEquationsToHTML;

public function setBoundaryConditionEquationsAndVars
  "Function which iterates shared.globalKnownVars Real parameters and
   check for boundaryCondition vars declared as
   (e.g) parameter Real x = 1  annotation(__OpenModelica_BoundaryCondition = true);
   and add it to the orderedEqs and orderedVars"
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
    if BackendVariable.isRealParam(var) and (BackendVariable.hasOpenModelicaBoundaryConditionAnnotation(var) or BackendVariable.varHasUncertainValueRefine(var) or BackendVariable.varHasUncertainValuePropagate(var)) then
      //print("\n knownsVars :" + anyString(var.bindExp));
      lhs := BackendVariable.varExp(var);
      rhs := BackendVariable.varBindExpStartValueNoFail(var);
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
  for i in adjacencyMatrix loop
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
  for i in adjacencyMatrix loop
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
    varNumber := getSolvedVariableNumber(eq, solvedEqsVarInfo);
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
    varNumber := getSolvedVariableNumber(eq, solvedEqsVarInfo);
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
      outList := mapIncRowEqn[i] :: outList;
    else
      // equations in E-BLT, have negativeindex
      outList := i :: outList;
    end if;
  end for;
  outList := listReverse(outList);
end getAbsoluteIndexHelper;

protected function dumpSetSTargetEquations
  "dumps set-S equations solved var info along with equations"
  input Integer eq;
  input list<tuple<Integer, Integer>> solvedEqsVarInfo;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.EquationArray orderedEqs;
  input BackendDAE.Variables orderedVars;
  input String heading;
protected
  Integer count = 1, varNumber, mappedEq;
  BackendDAE.Var var;
  BackendDAE.Equation tmpEq;
algorithm
  varNumber := getSolvedVariableNumber(eq, solvedEqsVarInfo);
  var := BackendVariable.getVarAt(orderedVars, varNumber);
  mappedEq := mapIncRowEqn[eq];
  tmpEq := BackendEquation.get(orderedEqs, mappedEq);
  print("\n" + heading + intString(varNumber) + ": "  + ComponentReference.printComponentRefStr(var.varName) + ": " + "("  + intString(mappedEq) + "/"  + intString(eq)  + "): " + "(" +  intString(BackendEquation.equationSize(tmpEq)) + "): " + BackendDump.equationString(tmpEq));
  count := count + 1;
end dumpSetSTargetEquations;

protected function dumpSetSVarsSolvedInfo
  "dumps set-S equations solved var info along with equations"
  input list<Integer> tempSetS;
  input list<tuple<Integer, Integer>> solvedEqsVarInfo;
  input array<Integer> mapIncRowEqn;
  input BackendDAE.EquationArray orderedEqs;
  input BackendDAE.Variables orderedVars;
  input String heading;
protected
  Integer count = 1, varNumber, mappedEq;
  BackendDAE.Var var;
  BackendDAE.Equation tmpEq;
algorithm
  if not stringEmpty(heading) then
    print("\n" + heading + ":" + "(" + intString(listLength(tempSetS))  + ")" + "\n============================================================\n");
  end if;
  for eq in tempSetS loop
    varNumber := getSolvedVariableNumber(eq, solvedEqsVarInfo);
    var := BackendVariable.getVarAt(orderedVars, varNumber);
    mappedEq := mapIncRowEqn[eq];
    tmpEq := BackendEquation.get(orderedEqs, mappedEq);
    print("\n" + intString(varNumber) + ": "  + ComponentReference.printComponentRefStr(var.varName) + ": " + "("  + intString(mappedEq) + "/"  + intString(eq)  + "): " + "(" +  intString(BackendEquation.equationSize(tmpEq)) + "): "  + BackendDump.equationString(tmpEq));
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
      targetBlocksWithKnowns := filterTargetBlocksWithoutRanks(listRest(targetBlocks), targetBlocksWithKnowns);
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
  Integer varNumber;
algorithm
  for i in inlist loop
    varNumber := getSolvedVariableNumber(i, solvedVar);
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
  output Integer solvedvar;
protected
  Integer solvedeq;
algorithm
  for var in inlist loop
    (solvedeq, solvedvar):=var;
    if intEq(eqnumber, solvedeq) then
      return;
    end if;
  end for;
end getSolvedVariableNumber;

public function getSolvedEquationNumber
  "returns solvedeqs based on the variables "
  input Integer varnumber;
  input list<tuple<Integer, Integer>> inlist;
  output Integer solvedeq;
protected
  Integer solvedvar;
algorithm
  for var in inlist loop
    (solvedeq, solvedvar) := var;
    if intEq(varnumber, solvedvar) then
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
  Integer count=1;
algorithm
  for i in v loop
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
  output list<Integer> unMeasuredVariablesOfInterest = {};
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
    // check for uncertain = uncertanity.propagate, as variable can be both boundary condition and unmeasured variables of interest
    if BackendVariable.varHasUncertainValuePropagate(BackendVariable.getVarAt(allVariables, index)) then
      unMeasuredVariablesOfInterest := index :: unMeasuredVariablesOfInterest;
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
        isApproximatedEquation = List.any(subModLst, isEquationTaggedApproximated) or isEquationTaggedApproximatedOrBoundaryConditionHelper(t);
        isboundaryConditionEquation = List.any(subModLst, isEquationTaggedBoundaryCondition) or isEquationTaggedApproximatedOrBoundaryConditionHelper(t);
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
    print ("\nDetailed BlockTarget Dependency tree:\n========================================\n");
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
  for eqnumber in inlist loop
    varnumber := getSolvedVariableNumber(eqnumber, solvedvariables);
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
        if listMember(listHead(targetblocks), tmptargetblocks) then
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
  fulleqs := listAppend(setc, sets);
  for i in fulleqs loop
    for j in mext loop
      (eq, vars) := j;
      if intEq(i, eq) then
        for k in vars loop
          finalvars := k:: finalvars;
        end for;
      end if;
    end for;
  end for;
  finalvars := List.unique(finalvars);
  //print("\n check extraction =>:" + anyString(finalvars) + "length is:"+ anyString(listLength(finalvars)));
end getVariablesAfterExtraction;

protected function VerifySetSPrime
  input BackendDAE.Variables boundaryConditionsVars;
  input BackendDAE.Variables intermediateVars;
  input BackendDAE.Variables knownVars;
  input list<BackendDAE.Var> extraVarsinSetSPrime;
  input BackendDAE.EquationArray boundaryConditionsEquations;
  input BackendDAE.EquationArray intermediateEquations;
  input BackendDAE.Shared shared;
  input Integer auxillaryEquations;
  input Integer numRelatedBoundaryConditions;
  input Boolean stateEstimation;
protected
  Integer eqSize, varSize, count, extraVarLength;
  String condition5, msg;
algorithm
  eqSize := intAdd(BackendEquation.equationArraySize(boundaryConditionsEquations), BackendEquation.equationArraySize(intermediateEquations));
  varSize := intAdd(listLength(BackendVariable.varList(boundaryConditionsVars)), listLength(BackendVariable.varList(intermediateVars)));
  if not intEq(eqSize, varSize) then
    condition5 := "Set-S' has " + intString(eqSize) + " equations and " + intString(varSize) + " variables";
    msg := "Boundary condition(s) ";
    for var in BackendVariable.varList(boundaryConditionsVars) loop
      msg := msg + BackendDump.varStringShort(var) + ",";
    end for;
    msg := msg + " cannot be computed from the variables of interest only. They must be computed also from boundary conditions(s) ";
    extraVarLength := listLength(extraVarsinSetSPrime);
    count := 1;
    for var in extraVarsinSetSPrime loop
      if intEq(count, extraVarLength) then
        msg := msg + BackendDump.varStringShort(var) + ".";
      else
        msg := msg + BackendDump.varStringShort(var) + ",";
      end if;
      count := count + 1;
    end for;
    Error.addMessage(Error.INTERNAL_ERROR, {": " + msg + " Therefore, the problem is ill-posed regarding the computation of boundary conditions from the variables of interest only."});
    if stateEstimation then
      generateCompileTimeHtmlReport(shared, "", intString(BackendEquation.equationArraySize(boundaryConditionsEquations)), intString(listLength(BackendVariable.varList(knownVars))), condition5 = msg + " Therefore, the problem is ill-posed regarding the computation of unmeasured variables of interest from the variables of interest only.", boundaryCondition = false, stateEstimation = true, setC= auxillaryEquations, numRelatedBoundaryConditions = numRelatedBoundaryConditions);
    else
      generateCompileTimeHtmlReport(shared, "", intString(BackendEquation.equationArraySize(boundaryConditionsEquations)), intString(listLength(BackendVariable.varList(knownVars))), condition5 = msg + " Therefore, the problem is ill-posed regarding the computation of boundary conditions from the variables of interest only.", boundaryCondition = true, stateEstimation = false, setC= auxillaryEquations, numRelatedBoundaryConditions = numRelatedBoundaryConditions);
    end if;
    fail();
  end if;
end VerifySetSPrime;

protected function VerifyDataReconciliation
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
  input BackendDAE.Shared shared;
  input list<Integer> mappedSetC = {};
  input list<Integer> mappedSetS = {};
  input Integer unMeasuredVariablesOfInterest = 0;
protected
  list<Integer> matchedeq, matchedknownssetc, matchedunknownssetc, matchedknownssets, matchedunknownssets;
  list<Integer> tmpunknowns, tmpknowns, tmplist1, tmplist2, tmplist3, tmplist1sets, setstmp;
  list<Integer> tmplistvar1, tmplistvar2, tmplistvar3, sets_eqs, sets_vars, extractedeqs;
  Integer eqnumber, varnumber;
  list<tuple<Integer,list<Integer>>> var_dependencytree, eq_dependencytree;
  String str, resstr, condition1, condition2, condition3, condition4, condition5, auxilliaryConditions, varsToReconcile;
  list<BackendDAE.Var> var, convar;
  Boolean rule2 = true;
  list<BackendDAE.Equation> condition1_eqs;
algorithm

  print("\n\nAutomatic Verification Steps of DataReconciliation Algorithm"+ "\n" + UNDERLINE + "\n");

  var := List.map1r(listReverse(knowns), BackendVariable.getVarAt, allVars);
  BackendDump.dumpVarList(var, "knownVariables:"+ dumplistInteger(listReverse(knowns)));
  print("-SET_C:"+ dumplistInteger(mappedSetC)+ "\n" + "-SET_S:" + dumplistInteger(mappedSetS) +"\n\n");

  auxilliaryConditions := intString(listLength(mappedSetC));
  varsToReconcile := intString(listLength(knowns));

  //Condition-1
  condition1 := "Condition-1 \"SET_C and SET_S must not have no equations in common\"";
  print(condition1 + "\n" + UNDERLINE + "\n");
  matchedeq := List.intersectionOnTrue(mappedSetC, mappedSetS, intEq);

  if listEmpty(matchedeq) then
    print("-Passed\n\n");
  else
    print("-Failed\n");
    condition1_eqs := List.map1r(matchedeq, BackendEquation.get, allEqs);
    BackendDump.dumpEquationList(condition1_eqs, "Sets C and S have equations in common" + dumplistInteger(matchedeq));
    Error.addMessage(Error.INTERNAL_ERROR, {": Condition 1-Failed: SET_C and SET_S must not have no equations in common: The data reconciliation problem is ill-posed"});
    generateCompileTimeHtmlReport(shared, "Internal Error: Condition 1-Failed: \"SET_C and SET_S must not have no equations in common\": The data reconciliation problem is ill-posed", auxilliaryConditions, varsToReconcile, condition1=("Sets C and S have equations in common", condition1_eqs), unMeasuredVariables = unMeasuredVariablesOfInterest);
    fail();
  end if;

  (matchedknownssetc, matchedunknownssetc) := getVariableOccurence(setc, mExt, knowns);
  (matchedknownssets, matchedunknownssets) := getVariableOccurence(sets, mExt, knowns);

  // Condition -2
  condition2 := "Condition-2 \"All variables of interest must be involved in SET_C or SET_S\"";
  print(condition2 +  "\n" + UNDERLINE + "\n");
  (tmplist1, tmplist2, tmplist3) := List.intersection1OnTrue(matchedknownssetc, knowns, intEq);

  if listEmpty(tmplist3) then
    print("-Passed\n");
    BackendDump.dumpVarList(List.map1r(tmplist1, BackendVariable.getVarAt, allVars), "-SET_C has all known variables:" + dumplistInteger(tmplist1));
   // check in sets
  elseif not listEmpty(tmplist3) then
    (tmplist1sets, tmplist2, _) := List.intersection1OnTrue(tmplist3, matchedknownssets, intEq);
    if not listEmpty(tmplist2) then
      str := dumplistInteger(tmplist2);
      print("-Failed\n");
      BackendDump.dumpVarList(List.map1r(tmplist2, BackendVariable.getVarAt, allVars), "knownVariables not Found:" + dumplistInteger(tmplist2));
      Error.addMessage(Error.INTERNAL_ERROR, {": Condition 2-Failed: All variables of interest must be involved in Set-C or Set-S: The data reconciliation problem is ill-posed"});
      rule2 := false;
      str := dumpToCsv("", List.map1r(tmplist2, BackendVariable.getVarAt, allVars));
      System.writeFile(shared.info.fileNamePrefix + "_NonReconcilcedVars.txt", str);
      //generateCompileTimeHtmlReport(shared, "Condition 2-Failed: \"All variables of interest must be involved in SET_C or SET_S\": The data reconciliation problem is ill-posed", condition2 = ("Sets C and S does not have the following known variables", List.map1r(tmplist2, BackendVariable.getVarAt, allVars)));
      //fail();
    end if;
    if (rule2) then
      print("-Passed\n");
    end if;
    BackendDump.dumpVarList(List.map1r(tmplist1, BackendVariable.getVarAt, allVars), "-SET_C has known variables:" + dumplistInteger(tmplist1));
    BackendDump.dumpVarList(List.map1r(tmplist1sets, BackendVariable.getVarAt, allVars), "-SET_S has known variables:" + dumplistInteger(tmplist1sets));
  end if;

  //Condition-3
  condition3 := "Condition-3 \"SET_C equations must be strictly less than Variable of Interest\"";
  print(condition3 + "\n" + UNDERLINE + "\n");

  if (listLength(setc) < listLength(knowns) and not listEmpty(setc)) then
    print("-Passed"+ "\n" + "-SET_C contains:" + intString(listLength(setc)) + " equations < " + intString(listLength(knowns))+" known variables\n\n");
  else
    condition3 := "Set-C has " + intString(listLength(setc)) + " equations and " + intString(listLength(knowns)) + " variables to be reconciled";
    resstr := "-Failed" + "\n" + "-" + condition3 + "\n\n";
    print(resstr);
    Error.addMessage(Error.INTERNAL_ERROR, {": Condition 3-Failed: The number of auxiliary conditions must be strictly less than the number of variables to be reconciled. The data reconciliation problem is ill-posed"});
    if listEmpty(setc) then
      condition3 := "<b>User Error:</b> Condition 7 failed: \"The set of auxiliary conditions is empty.\" The data reconciliation problem is ill-posed";
      generateCompileTimeHtmlReport(shared, "", auxilliaryConditions, varsToReconcile, condition3 = condition3, unMeasuredVariables = unMeasuredVariablesOfInterest);
    else
      generateCompileTimeHtmlReport(shared, "<b>User Error:</b> Condition 3-Failed: \"The number of auxiliary conditions must be strictly less than the number of variables to be reconciled.\": The data reconciliation problem is ill-posed",auxilliaryConditions, varsToReconcile, condition3 = condition3, unMeasuredVariables = unMeasuredVariablesOfInterest);
    end if;
    fail();
  end if;

  //Condition-4
  condition4 := "Condition-4 \"SET_S should contain all intermediate variables involved in SET_C\"";
  print(condition4 + "\n" + UNDERLINE + "\n");
  (tmplistvar1, tmplistvar2, tmplistvar3) := List.intersection1OnTrue(matchedunknownssetc, matchedunknownssets, intEq);

  if listEmpty(matchedunknownssetc) then
    print("-Passed"+"\n"+"-SET_C contains No Intermediate Variables\n\n");
    return;
  else
    BackendDump.dumpVarList(List.map1r(matchedunknownssetc, BackendVariable.getVarAt, allVars), "-SET_C has intermediate variables:" + dumplistInteger(matchedunknownssetc));

    if listEmpty(tmplistvar2) then
      BackendDump.dumpVarList(List.map1r(tmplistvar1, BackendVariable.getVarAt, allVars), "-SET_S has intermediate variables involved in SET_C:" + dumplistInteger(tmplistvar1));
      print("-Passed\n\n");
    else
      BackendDump.dumpVarList(List.map1r(tmplistvar2, BackendVariable.getVarAt, allVars), "-SET_S does not have intermediate variables involved in SET_C:" + dumplistInteger(tmplistvar2));
      Error.addMessage(Error.INTERNAL_ERROR, {": Condition 4-Failed: SET_S should contain all intermediate variables involved in SET_C: The data reconciliation problem is ill-posed"});
      generateCompileTimeHtmlReport(shared, "<b>Internal Error:</b> Condition 4-Failed: \"SET_S should contain all intermediate variables involved in SET_C\": The data reconciliation problem is ill-posed", auxilliaryConditions, varsToReconcile, condition4 = ("Set-S does not have intermediate variables involved in Set-C", List.map1r(tmplistvar2, BackendVariable.getVarAt, allVars)), unMeasuredVariables = unMeasuredVariablesOfInterest);
      fail();
    end if;
  end if;

  //Condition-5
  condition5 := "Condition-5 \"SET_S should be square\"";
  print(condition5 + "\n" + UNDERLINE + "\n");

  if(listEmpty(outsetS_eq)) then
    print("-Passed"+"\n"+"-SET_S contains 0 intermediate variables and 0 equations\n\n");
    return;
  else
    //BackendEquation.equationArraySize(inEqns)
    //BackendEquation.equationArraySize(BackendEquation.listEquation(outsetS_eq));
    if(BackendEquation.equationArraySize(BackendEquation.listEquation(outsetS_eq)) == listLength(BackendVariable.varList(outsetS_vars))) then
      print("-Passed" + "\n "+ "Set_S has " + intString(listLength(sets)) + " equations and " + intString(listLength(BackendVariable.varList(outsetS_vars))) + " variables\n\n");
    else
      condition5 := "Set-S has " + intString(BackendEquation.equationArraySize(BackendEquation.listEquation(outsetS_eq))) + " equations and " + intString(listLength(BackendVariable.varList(outsetS_vars))) + " variables";
      print("-Failed" + "\n "+ condition5 + "\n\n");
      Error.addMessage(Error.INTERNAL_ERROR, {": Condition 5-Failed: Set_S should be square: The data reconciliation problem is ill-posed"});
      generateCompileTimeHtmlReport(shared, "<b>Internal Error:</b> Condition 5-Failed: \"Set_S should be square\": The data reconciliation problem is ill-posed", auxilliaryConditions, varsToReconcile, condition5 = condition5, unMeasuredVariables = unMeasuredVariablesOfInterest);
      fail();
    end if;
  end if;
end VerifyDataReconciliation;

protected function generateCompileTimeHtmlReport
  "generate html report for internal errors reported during verification of extraction algorithm"
  input BackendDAE.Shared shared;
  input String conditions;
  input String auxilliaryConditions;
  input String varsToReconcile;
  input tuple<String, list<BackendDAE.Equation>> condition1 = ("", {});
  input tuple<String, list<BackendDAE.Var>> condition2 = ("", {});
  input String condition3 = "";
  input tuple<String, list<BackendDAE.Var>> condition4 = ("", {});
  input String condition5 = "";
  input Boolean boundaryCondition = false;
  input Boolean stateEstimation = false;
  input Integer setC = 0;
  input Integer numRelatedBoundaryConditions = 0;
  input Integer unMeasuredVariables = 0;
protected
  String data, condition1_msg, condition2_msg, condition4_msg;
  list<BackendDAE.Equation> condition1_eqs;
  list<BackendDAE.Var> condition2_vars, condition4_vars;
algorithm
    if boundaryCondition then
      data := "<html> \n <head> <h1> Boundary Condition Report</h1></head> \n <body> \n <h2> Overview: </h2> \n";
    else
      data := "<html> \n <head> <h1> Data Reconciliation Report</h1></head> \n <body> \n <h2> Overview: </h2> \n";
    end if;
    data := data + "<table> \n <tr> \n <th align=right> Model file: </th> \n";
    data := data + "<td>"+ shared.info.fileNamePrefix + ".mo" + "</td>\n</tr>\n";
    data := data + " <tr> \n <th align=right> Model name: </th>\n";
    data := data + "<td>" + shared.info.fileNamePrefix + "</td>\n</tr>\n";
    data := data + "<tr> \n <th align=right> Generated: </th>\n";
    data := data + "<td>" + System.getCurrentTimeStr() + "<b> by OpenModelica " + Settings.getVersionNr() + "</b>" + "</td>\n</tr>\n <table>\n";
    data := data + "<h2> Analysis: </h2>\n<table>";
    if boundaryCondition then
      data := data + "<tr>\n <th align=right> Number of boundary conditions: </th> \n <td>" + auxilliaryConditions + "</td>\n</tr>\n";
      data := data + "<tr>\n <th align=right> Number of measured variables: </th> \n <td>" + varsToReconcile + "</td>\n</tr>\n</table>";
    else
      // stateEstimation and data Reconciliation
      data := data + "<tr>\n <th align=right> Number of auxiliary conditions: </th> \n <td>" + intString(setC) + "</td>\n</tr>\n";
      data := data + "<tr>\n <th align=right> Number of measured variables: </th> \n <td>" + varsToReconcile + "</td>\n</tr>\n";
      data := data + "<tr>\n <th align=right> Number of unmeasured variables: </th> \n <td>" + intString(unMeasuredVariables) + "</td>\n</tr>\n";
      data := data + "<tr>\n <th align=right> Number of related boundary conditions: </th> \n <td>" + intString(numRelatedBoundaryConditions) + "</td>\n</tr>\n</table>";
    end if;

    if boundaryCondition then
      data := data + "<h3> <a href=" + shared.info.fileNamePrefix + "_BoundaryConditionsEquations.html target=_blank> Boundary conditions </a> </h3>";
      data := data + "<h3> <a href=" + shared.info.fileNamePrefix + "_BoundaryConditionIntermediateEquations.html target=_blank> Intermediate equations </a> </h3>";
    else
      // stateEstimation and data Reconciliation
      //data := data + "<h3> <a href=" + shared.info.fileNamePrefix + "_AuxiliaryConditions.html target=_blank> Auxiliary conditions </a> </h3>";
      data := data + "<h3> <a href=" + shared.info.fileNamePrefix + "_IntermediateEquations.html target=_blank> Intermediate equations for measured variables </a> </h3>";
      if (numRelatedBoundaryConditions > 0) then
        data := data + "<h3> <a href=" + shared.info.fileNamePrefix + "_BoundaryConditionsEquations.html target=_blank> Boundary conditions </a> </h3>";
        data := data + "<h3> <a href=" + shared.info.fileNamePrefix + "_BoundaryConditionIntermediateEquations.html target=_blank> Intermediate equations for unmeasured variables </a> </h3>";
      end if;
    end if;
    data := data + "<h3> Errors: </h3> " + "\n <p>" + conditions + "</p>" + "\n";

    // condition-1
    (condition1_msg, condition1_eqs) := condition1;
    if not listEmpty(condition1_eqs) then
      data := data + "<p>" + condition1_msg + "\n <ol>";
      for eq in condition1_eqs loop
        data := data + "\n" + "  <li>" + BackendDump.equationString(eq) + " </li>";
      end for;
      data := data + "\n</ol> \n</p>";
    end if;

    //// condition-2
    // (condition2_msg, condition2_vars) := condition2;
    // if not listEmpty(condition2_vars) then
    //   data := data + "<p>" + condition2_msg + "\n <ol>";
    //   for var in condition2_vars loop
    //     data := data + "\n <li>" + BackendDump.varStringShort(var) + "</li>";
    //   end for;
    //   data := data + "\n</ol>";
    // end if;

    // condition-3
    if not stringEmpty(condition3) then
      data := data + "<p>" + condition3 + "</p>";
    end if;

    //condition-4
    (condition4_msg, condition4_vars) := condition4;
    if not listEmpty(condition4_vars) then
      data := data + "<p>" + condition4_msg + "\n <ol>";
      for var in condition4_vars loop
        data := data + "\n <li>" + BackendDump.varStringShort(var) + "</li>";
      end for;
      data := data + "\n</ol>";
    end if;

    // condition-5
    if not stringEmpty(condition5) then
      data := data + "<p>" + condition5 + "</p>";
    end if;

    data := data + "\n</html>";
    if boundaryCondition then
      System.writeFile(shared.info.fileNamePrefix + "_BoundaryConditions.html", data);
    else
      System.writeFile(shared.info.fileNamePrefix + ".html", data);
    end if;
end generateCompileTimeHtmlReport;

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

/* function which dumps non reconciledVars failing for condition -2 to a log file*/
public function dumpNonReconciledVars
  input list<BackendDAE.Var> invar;
  output String outstring="";
protected
  DAE.ComponentRef cr;
algorithm
  for i in invar loop
    cr := BackendVariable.varCref(i);
    outstring := outstring + ComponentReference.crefStr(cr) + "\n";
  end for;
end dumpNonReconciledVars;

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
        res = stringAppendList({"for ", s1, " loop\n    ", s2, "; end for; "});
      then
        res;
  end match;
end dumpEquationString;

annotation(__OpenModelica_Interface="backend");
end DataReconciliation;

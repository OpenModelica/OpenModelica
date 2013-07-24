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

encapsulated package HpcOmSimCode
" file:        HpcOmSimCode.mo
  package:     HpcOmSimCode
  description: HpcOmSimCode contains the logic to create a parallelized simcode.

  RCS: $Id: HpcOmSimCode.mo 15486 2013-05-24 11:12:35Z marcusw $
"
// public imports
public import Absyn;
public import BackendDAE;
public import DAE;
public import HashTableExpToIndex;
public import SimCode;

// protected imports
protected import BackendDAEOptimize;
protected import BackendDAEUtil;
protected import Config;
protected import Error;
protected import HpcOmTaskGraph;
protected import Initialization;
protected import InlineSolver;
protected import List;
protected import SimCodeUtil;
protected import Util;

public function createSimCode "function createSimCode
  entry point to create SimCode from BackendDAE."
  input BackendDAE.BackendDAE inBackendDAE;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inString11;
  input list<SimCode.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input list<SimCode.RecordDeclaration> recordDecls;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  input Absyn.FunctionArgs args;
  output SimCode.SimCode simCode;
algorithm
  simCode := matchcontinue (inBackendDAE, inClassName, filenamePrefix, inString11, functions, externalFunctionIncludes, includeDirs, libs, simSettingsOpt, recordDecls, literals, args)
    local
      String fileDir, cname;
      Integer lastEqMappingIdx, maxDelayedExpIndex, uniqueEqIndex, numberofEqns, numberOfInitialEquations, numberOfInitialAlgorithms, numStateSets;
      Integer numberofLinearSys, numberofNonLinearSys, numberofMixedSys;
      BackendDAE.BackendDAE dlow, dlow2;
      Option<BackendDAE.BackendDAE> initDAE;
      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symJacs;
      Absyn.Path class_;
      
      // new variables
      SimCode.ModelInfo modelInfo;
      list<SimCode.SimEqSystem> allEquations;
      list<list<SimCode.SimEqSystem>> odeEquations;         // --> functionODE
      list<list<SimCode.SimEqSystem>> algebraicEquations;   // --> functionAlgebraics
      list<SimCode.SimEqSystem> residuals;                  // --> initial_residual
      Boolean useSymbolicInitialization;                    // true if a system to solve the initial problem symbolically is generated, otherwise false
      Boolean useHomotopy;                                  // true if homotopy(...) is used during initialization
      list<SimCode.SimEqSystem> initialEquations;           // --> initial_equations
      list<SimCode.SimEqSystem> startValueEquations;        // --> updateBoundStartValues
      list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
      list<SimCode.SimEqSystem> inlineEquations;            // --> inline solver
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttributes;
      list<BackendDAE.ZeroCrossing> zeroCrossings, sampleZC, relations;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> delayedExps;
      BackendDAE.Variables knownVars;
      list<BackendDAE.Var> varlst;

      list<SimCode.JacobianMatrix> LinearMatrices, SymbolicJacs, SymbolicJacsTemp, SymbolicJacsStateSelect;
      SimCode.HashTableCrefToSimVar crefToSimVarHT;
      Boolean ifcpp;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      BackendDAE.EquationArray removedEqs;
      array<DAE.Constraint> constrsarr;
      array<DAE.ClassAttributes> clsattrsarra;

      list<DAE.Exp> lits;
      list<SimCode.SimVar> tempvars;
      
      SimCode.JacobianMatrix jacG;
      Option<BackendDAE.BackendDAE> inlineDAE;
      list<SimCode.StateSet> stateSets;
      array<Integer> systemIndexMap;
      list<tuple<Integer,Integer>> equationSccMapping; //Maps each simEq to the scc
      array<list<Integer>> sccSimEqMapping; //Maps each scc to a list of simEqs
      array<Integer> simEqSccMapping; //Maps each simEq to the scc
      BackendDAE.SampleLookup sampleLookup;
      BackendDAE.StrongComponents allComps;
      
      HpcOmTaskGraph.TaskGraph taskGraph;  
      HpcOmTaskGraph.TaskGraph taskGraphOde;
      HpcOmTaskGraph.TaskGraph taskGraph1;  
      HpcOmTaskGraph.TaskGraphMeta taskGraphData;
      HpcOmTaskGraph.TaskGraphMeta taskGraphDataOde;
      String fileName;
      HpcOmTaskGraph.TaskGraphMeta taskGraphData1;
      list<list<Integer>> parallelSets;
      
    case (dlow, class_, _, fileDir, _, _, _, _, _, _, _, _) equation
      uniqueEqIndex = 1;

      //Create mapping to SimEq
      (equationSccMapping,lastEqMappingIdx) = createSimEqToSccMapping(inBackendDAE);
      (allComps,_) = HpcOmTaskGraph.getSystemComponents(inBackendDAE);
      //print("createSimCode with " +& intString(listLength(allComps)) +& " Components\n");
      sccSimEqMapping = convertToSccSimEqMapping(equationSccMapping, listLength(allComps));
      simEqSccMapping = convertToSimEqSccMapping(equationSccMapping, lastEqMappingIdx);

      //dumpSccSimEqMapping(sccSimEqMapping);
      
      //Create TaskGraph
      (taskGraph,taskGraphData) = HpcOmTaskGraph.createTaskGraph(inBackendDAE,filenamePrefix);
      //Append the costs to the taskGraphMeta
      taskGraphData = HpcOmTaskGraph.createCosts(inBackendDAE, filenamePrefix +& "_prof.xml" , simEqSccMapping, taskGraphData);
      //HpcOmTaskGraph.printTaskGraph(taskGraph);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphData);  
      fileName = ("taskGraph"+&filenamePrefix+&".graphml");    
      HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraph, taskGraphData, fileName);
     
      
      // get the task graph for the ODEsystem
      taskGraphOde = arrayCopy(taskGraph);
      taskGraphDataOde = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphData);
      (taskGraphOde,taskGraphDataOde) = HpcOmTaskGraph.getOdeSystem(taskGraphOde,taskGraphDataOde,inBackendDAE,filenamePrefix);
      //print("ODE-TASKGRAPH\n");
      //HpcOmTaskGraph.printTaskGraph(taskGraphOde);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataOde); 

      //fileName = ("taskGraph"+&filenamePrefix+&"ODE.graphml");       
      //HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOde, taskGraphDataOde, fileName);
     
      //assign levels(as an node property in the .graphml) to the nodes in the taskGraph. all nodes in one level can be computed in parallel
      //HpcOmTaskGraph.arrangeGraphInLevels(taskGraphOde,taskGraphDataOde);
            
      
      // filter to merge simple nodes (i.e. nodes with only 1 predecessor and 1 successor)
      taskGraph1 = arrayCopy(taskGraphOde);
      taskGraphData1 = HpcOmTaskGraph.copyTaskGraphMeta(taskGraphDataOde);
      (taskGraph,taskGraphData) = HpcOmTaskGraph.mergeSimpleNodes(taskGraph1,taskGraphData1,inBackendDAE,filenamePrefix);
      //print("MERGED GRAPH\n");
      //HpcOmTaskGraph.printTaskGraph(taskGraph);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphData);  
      //HpcOmTaskGraph.printTaskGraph(taskGraphOde);
      //HpcOmTaskGraph.printTaskGraphMeta(taskGraphDataOde);  
      //fileName = ("taskGraph"+&filenamePrefix+&"ODE.graphml");       
      //HpcOmTaskGraph.dumpAsGraphMLSccLevel(taskGraphOde, taskGraphDataOde, fileName);
      
      uniqueEqIndex = 1;
      ifcpp = stringEqual(Config.simCodeTarget(), "Cpp");
      // Debug.fcall(Flags.FAILTRACE, print, "is that Cpp? : " +& Dump.printBoolStr(ifcpp) +& "\n");
      cname = Absyn.pathStringNoQual(class_);
      
      // generate initDAE before replacing pre(alias)!
      (initDAE, useHomotopy) = Initialization.solveInitialSystem(dlow);
      // replace pre(alias) in time-equations
      dlow = BackendDAEOptimize.simplifyTimeIndepFuncCalls(dlow);

      // generate system for inline solver
      (inlineDAE, _) = InlineSolver.generateDAE(dlow);

      // check if the Sytems has states
      dlow = BackendDAEUtil.addDummyStateIfNeeded(dlow);
      BackendDAE.DAE(systs, shared as BackendDAE.SHARED(removedEqs=removedEqs, 
                                                        constraints=constrsarr, 
                                                        classAttrs=clsattrsarra, 
                                                        functionTree=functionTree, 
                                                        symjacs=symJacs,
                                                        eventInfo=BackendDAE.EVENT_INFO(sampleLookup=sampleLookup))) = dlow;
      
      extObjInfo = SimCodeUtil.createExtObjInfo(shared);

      //whenClauses = SimCodeUtil.createSimWhenClauses(dlow);
      //zeroCrossings = Util.if_(ifcpp, getRelations(dlow), getZeroCrossings(dlow));
      //relations = SimCodeUtil.getRelations(dlow);
      //sampleZC = SimCodeUtil.getSamples(dlow);
      //zeroCrossings = Util.if_(ifcpp, listAppend(zeroCrossings, sampleZC), zeroCrossings);

      // state set stuff
      tempvars = {};
      (dlow, stateSets, uniqueEqIndex, tempvars, numStateSets) = SimCodeUtil.createStateSets(dlow, {}, uniqueEqIndex, tempvars);

      // inline solver stuff
      (inlineEquations, uniqueEqIndex, tempvars) = SimCodeUtil.createInlineSolverEqns(inlineDAE, uniqueEqIndex, tempvars);

      // initialization stuff
      (residuals, initialEquations, numberOfInitialEquations, numberOfInitialAlgorithms, uniqueEqIndex, tempvars, useSymbolicInitialization) = SimCodeUtil.createInitialResiduals(dlow, initDAE, uniqueEqIndex, tempvars);
      (jacG, uniqueEqIndex) = SimCodeUtil.createInitialMatrices(dlow, uniqueEqIndex);

      // addInitialStmtsToAlgorithms
      dlow = BackendDAEOptimize.addInitialStmtsToAlgorithms(dlow);
      
      BackendDAE.DAE(systs, shared as BackendDAE.SHARED(removedEqs=removedEqs, 
                                                        constraints=constrsarr, 
                                                        classAttrs=clsattrsarra, 
                                                        functionTree=functionTree, 
                                                        symjacs=symJacs)) = dlow;

      // Add model info
      //modelInfo = createModelInfo(class_, dlow, functions, {}, numberOfInitialEquations, numberOfInitialAlgorithms, numStateSets, fileDir, ifcpp);

      // equation generation for euler, dassl2, rungekutta
      (uniqueEqIndex, odeEquations, algebraicEquations, allEquations, tempvars, _) = SimCodeUtil.createEquationsForSystems(systs, shared, uniqueEqIndex, {}, {}, {}, tempvars, 1, {});
      
      HpcOmTaskGraph.checkOdeSystemSize(taskGraphOde,odeEquations);
//      modelInfo = SimCodeUtil.addTempVars(tempvars, modelInfo);
//
//      // Assertions and crap
//      // create parameter equations
//      ((uniqueEqIndex, startValueEquations)) = BackendDAEUtil.foldEqSystem(dlow2, SimCodeUtil.createStartValueEquations, (uniqueEqIndex, {}));
//      ((uniqueEqIndex, parameterEquations)) = BackendDAEUtil.foldEqSystem(dlow2, SimCodeUtil.createVarNominalAssertFromVars, (uniqueEqIndex, {}));
//      (uniqueEqIndex, parameterEquations) = SimCodeUtil.createParameterEquations(shared, uniqueEqIndex, parameterEquations, useSymbolicInitialization);
//      ((uniqueEqIndex, removedEquations)) = BackendEquation.traverseBackendDAEEqns(removedEqs, SimCodeUtil.traversedlowEqToSimEqSystem, (uniqueEqIndex, {}));
//
//      ((uniqueEqIndex, algorithmAndEquationAsserts)) = BackendDAEUtil.foldEqSystem(dlow2, SimCodeUtil.createAlgorithmAndEquationAsserts, (uniqueEqIndex, {}));
//      discreteModelVars = BackendDAEUtil.foldEqSystem(dlow2, SimCodeUtil.extractDiscreteModelVars, {});
//      makefileParams = SimCodeUtil.createMakefileParams(includeDirs, libs);
//      (delayedExps, maxDelayedExpIndex) = SimCodeUtil.extractDelayedExpressions(dlow2);
//
//      //append removed equation to all equations, since these are actually
//      //just the algorithms without outputs
//      algebraicEquations = listAppend(algebraicEquations, removedEquations::{});
//      allEquations = listAppend(allEquations, removedEquations);
//
//      // update indexNonLinear in SES_NONLINEAR and count
//      SymbolicJacs = {};
//      (initialEquations, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, SymbolicJacsTemp) = SimCodeUtil.countandIndexAlgebraicLoops(initialEquations, 0, 0, 0, {});
//      SymbolicJacs = listAppend(SymbolicJacsTemp, SymbolicJacs);
//      (inlineEquations, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, SymbolicJacsTemp) = SimCodeUtil.countandIndexAlgebraicLoops(inlineEquations, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, {});
//      SymbolicJacs = listAppend(SymbolicJacsTemp, SymbolicJacs);
//      (parameterEquations, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, SymbolicJacsTemp) = SimCodeUtil.countandIndexAlgebraicLoops(parameterEquations, numberofLinearSys, numberofNonLinearSys, numberofMixedSys,  {});
//      SymbolicJacs = listAppend(SymbolicJacsTemp, SymbolicJacs);
//      (allEquations, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, SymbolicJacsTemp) = SimCodeUtil.countandIndexAlgebraicLoops(allEquations, numberofLinearSys, numberofNonLinearSys, numberofMixedSys,  {});
//      SymbolicJacs = listAppend(SymbolicJacsTemp, SymbolicJacs);
//
//      SymbolicJacsStateSelect = SimCodeUtil.indexStateSets(stateSets, {});
//      (_, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, SymbolicJacsStateSelect) = SimCodeUtil.countandIndexAlgebraicLoops({}, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, SymbolicJacsStateSelect);
//      SymbolicJacs = listAppend(SymbolicJacsStateSelect, SymbolicJacs);
//
//      // generate jacobian or linear model matrices
//      LinearMatrices = SimCodeUtil.createJacobianLinearCode(symJacs, modelInfo, uniqueEqIndex);
//      LinearMatrices = jacG::LinearMatrices;
//
//      (_, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, LinearMatrices) = SimCodeUtil.countandIndexAlgebraicLoops({}, numberofLinearSys, numberofNonLinearSys, numberofMixedSys, LinearMatrices);
//
//
//      SymbolicJacs = listAppend(SymbolicJacs, LinearMatrices);
//
//       // map index also odeEquations and algebraicEquations
//      systemIndexMap = List.fold(allEquations, SimCodeUtil.getSystemIndexMap, arrayCreate(uniqueEqIndex, -1));
//      odeEquations = List.mapList1_1(odeEquations, SimCodeUtil.setSystemIndexMap, systemIndexMap);
//      algebraicEquations = List.mapList1_1(algebraicEquations, SimCodeUtil.setSystemIndexMap, systemIndexMap);
//      numberofEqns = uniqueEqIndex; /* This is a *much* better estimate than the guessed number of equations */
//
//      modelInfo = SimCodeUtil.addNumEqnsandNumofSystems(modelInfo, numberofEqns, numberofLinearSys, numberofNonLinearSys, numberofMixedSys);
//
//      // replace div operator with div operator with check of Division by zero
//      allEquations = List.map(allEquations, SimCodeUtil.addDivExpErrorMsgtoSimEqSystem);
//      odeEquations = List.mapList(odeEquations, SimCodeUtil.addDivExpErrorMsgtoSimEqSystem);
//      algebraicEquations = List.mapList(algebraicEquations, SimCodeUtil.addDivExpErrorMsgtoSimEqSystem);
//      residuals = List.map(residuals, SimCodeUtil.addDivExpErrorMsgtoSimEqSystem);
//      startValueEquations = List.map(startValueEquations, SimCodeUtil.addDivExpErrorMsgtoSimEqSystem);
//      parameterEquations = List.map(parameterEquations, SimCodeUtil.addDivExpErrorMsgtoSimEqSystem);
//      removedEquations = List.map(removedEquations, SimCodeUtil.addDivExpErrorMsgtoSimEqSystem);
//      initialEquations = List.map(initialEquations, SimCodeUtil.addDivExpErrorMsgtoSimEqSystem);
//
//      odeEquations = SimCodeUtil.makeEqualLengthLists(odeEquations, Config.noProc());
//      algebraicEquations = SimCodeUtil.makeEqualLengthLists(algebraicEquations, Config.noProc());
//      /* Filter out empty systems to improve code generation */
//      odeEquations = List.filterOnTrue(odeEquations, List.isNotEmpty);
//      algebraicEquations = List.filterOnTrue(algebraicEquations, List.isNotEmpty);
//
//      Debug.fcall(Flags.EXEC_HASH, print, "*** SimCode -> generate cref2simVar hastable: " +& realString(clock()) +& "\n");
//      crefToSimVarHT = SimCodeUtil.createCrefToSimVarHT(modelInfo);
//      Debug.fcall(Flags.EXEC_HASH, print, "*** SimCode -> generate cref2simVar hastable done!: " +& realString(clock()) +& "\n");
//
//      constraints = arrayList(constrsarr);
//      classAttributes = arrayList(clsattrsarra);
//      simCode = SimCode.SIMCODE(modelInfo,
//                                {}, // Set by the traversal below...
//                                recordDecls,
//                                externalFunctionIncludes,
//                                allEquations,
//                                odeEquations,
//                                algebraicEquations,
//                                residuals,
//                                useSymbolicInitialization,
//                                initialEquations,
//                                startValueEquations,
//                                parameterEquations,
//                                inlineEquations,
//                                removedEquations,
//                                algorithmAndEquationAsserts,
//                                stateSets,
//                                constraints,
//                                classAttributes,
//                                zeroCrossings,
//                                relations,
//                                sampleLookup,
//                                whenClauses,
//                                discreteModelVars,
//                                extObjInfo,
//                                makefileParams,
//                                SimCode.DELAYED_EXPRESSIONS(delayedExps, maxDelayedExpIndex),
//                                SymbolicJacs,
//                                simSettingsOpt,
//                                filenamePrefix,
//                                crefToSimVarHT);
//      (simCode, (_, _, lits)) = SimCodeUtil.traverseExpsSimCode(simCode, SimCodeUtil.findLiteralsHelper, literals);
//      simCode = SimCodeUtil.setSimCodeLiterals(simCode, listReverse(lits));
//      Debug.fcall(Flags.EXEC_FILES, print, "*** SimCode -> collect all files started: " +& realString(clock()) +& "\n" );
//      // adrpo: collect all the files from Absyn.Info and DAE.ElementSource
//      // simCode = collectAllFiles(simCode);
//      Debug.fcall(Flags.EXEC_FILES, print, "*** SimCode -> collect all files done!: " +& realString(clock()) +& "\n" );
//
//      then simCode;
      print("HpcOm is still under construction.\n");
    then fail();
    else equation
      Error.addMessage(Error.INTERNAL_ERROR, {"./Compiler/BackEnd/SimCodeUtil.mo: function createSimCode failed [Transformation from optimised DAE to simulation code structure failed]"});
    then fail();
  end matchcontinue;
end createSimCode;


protected function createSimEqToSccMapping
  input BackendDAE.BackendDAE inBackendDAE;
  output list<tuple<Integer,Integer>> oMapping;
  output Integer lastIndex;
algorithm
  (oMapping,lastIndex) := matchcontinue (inBackendDAE)
    local
      Integer  maxDelayedExpIndex, uniqueEqIndex, numberofEqns, numberOfInitialEquations, numberOfInitialAlgorithms, numStateSets;

      DAE.FunctionTree functionTree;
      BackendDAE.SymbolicJacobians symJacs;
      
      // new variables
      list<SimCode.SimEqSystem> initialEquations;           // --> initial_equations
      list<SimCode.SimEqSystem> startValueEquations;        // --> updateBoundStartValues
      list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
      list<SimCode.SimEqSystem> inlineEquations;            // --> inline solver
      list<SimCode.SimEqSystem> removedEquations;
      list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<DAE.ClassAttributes> classAttributes;
      list<SimCode.SimWhenClause> whenClauses;
      list<DAE.ComponentRef> discreteModelVars;
      SimCode.ExtObjInfo extObjInfo;
      SimCode.MakefileParams makefileParams;
      list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> delayedExps;
      BackendDAE.Variables knownVars;
      list<BackendDAE.Var> varlst;

      BackendDAE.BackendDAE dlow;
      Option<BackendDAE.BackendDAE> initDAE;
      Option<BackendDAE.BackendDAE> inlineDAE;
      BackendDAE.EquationArray removedEqs;    
      list<DAE.Constraint> constraints;
      list<SimCode.SimVar> tempvars;
      BackendDAE.EqSystems systs;
      BackendDAE.Shared shared;
      list<tuple<Integer,Integer>> equationSccMapping;
      array<DAE.Constraint> constrsarr;
      array<DAE.ClassAttributes> clsattrsarra;
      SimCode.JacobianMatrix jacG;
      
    case (dlow) equation
      uniqueEqIndex = 1;
      
      // generate initDAE before replacing pre(alias)!
      (initDAE, _) = Initialization.solveInitialSystem(dlow);

      // replace pre(alias) in time-equations
      dlow = BackendDAEOptimize.simplifyTimeIndepFuncCalls(dlow);

      // generate system for inline solver
      (inlineDAE, _) = InlineSolver.generateDAE(dlow);

      // check if the Sytems has states
      dlow = BackendDAEUtil.addDummyStateIfNeeded(dlow);

      BackendDAE.DAE(systs, shared as BackendDAE.SHARED(removedEqs=removedEqs, 
                                                        constraints=constrsarr, 
                                                        classAttrs=clsattrsarra, 
                                                        functionTree=functionTree, 
                                                        symjacs=symJacs)) = dlow;
      
      //extObjInfo = createExtObjInfo(shared);

      //whenClauses = createSimWhenClauses(dlow);
      //zeroCrossings = Util.if_(ifcpp, getRelations(dlow), getZeroCrossings(dlow));
      //relations = getRelations(dlow);
      //sampleZC = getSamples(dlow);
      //zeroCrossings = Util.if_(ifcpp, listAppend(zeroCrossings, sampleZC), zeroCrossings);

      // state set stuff
      tempvars = {};
      (dlow, _, uniqueEqIndex, tempvars, numStateSets) = SimCodeUtil.createStateSets(dlow, {}, uniqueEqIndex, tempvars);

      // inline solver stuff
      (inlineEquations, uniqueEqIndex, tempvars) = SimCodeUtil.createInlineSolverEqns(inlineDAE, uniqueEqIndex, tempvars);

      // initialization stuff
      (_, initialEquations, numberOfInitialEquations, numberOfInitialAlgorithms, uniqueEqIndex, tempvars, _) = SimCodeUtil.createInitialResiduals(dlow, initDAE, uniqueEqIndex, tempvars);
      (jacG, uniqueEqIndex) = SimCodeUtil.createInitialMatrices(dlow, uniqueEqIndex);

      // addInitialStmtsToAlgorithms
      dlow = BackendDAEOptimize.addInitialStmtsToAlgorithms(dlow);
      
      BackendDAE.DAE(systs, shared as BackendDAE.SHARED(removedEqs=removedEqs, 
                                                        constraints=constrsarr, 
                                                        classAttrs=clsattrsarra, 
                                                        functionTree=functionTree, 
                                                        symjacs=symJacs)) = inBackendDAE; //dlow

      // equation generation for euler, dassl2, rungekutta
      (uniqueEqIndex, _, _, _, tempvars, equationSccMapping) = SimCodeUtil.createEquationsForSystems(systs, shared, uniqueEqIndex, {}, {}, {}, tempvars, 1, {});    
      then (equationSccMapping,uniqueEqIndex);
    else then fail();
  end matchcontinue;

end createSimEqToSccMapping;

protected function convertToSccSimEqMapping
  input list<tuple<Integer,Integer>> iMapping;
  input Integer numOfSccs;
  output array<list<Integer>> oMapping;
  
protected
  array<list<Integer>> tmpMapping;

algorithm
  tmpMapping := arrayCreate(numOfSccs,{});
  //print("convertToSccSimEqMapping with " +& intString(numOfSccs) +& " sccs.\n");
  _ := List.fold(iMapping, convertToSccSimEqMapping1, tmpMapping);
  oMapping := tmpMapping;
  
end convertToSccSimEqMapping;

protected function convertToSccSimEqMapping1
  input tuple<Integer,Integer> iMapping;
  input array<list<Integer>> iSccMapping;
  output array<list<Integer>> oSccMapping;
  
protected
  Integer i1,i2;
  List<Integer> tmpList;
  
algorithm
  (i1,i2) := iMapping;
  //print("convertToSccSimEqMapping1 accessing index " +& intString(i2) +& ".\n");
  tmpList := arrayGet(iSccMapping,i2);
  tmpList := i1 :: tmpList;
  oSccMapping := arrayUpdate(iSccMapping,i2,tmpList);
  
end convertToSccSimEqMapping1;

protected function convertToSimEqSccMapping
  input list<tuple<Integer,Integer>> iMapping; //<simEqIdx,sccIdx>
  input Integer numOfSimEqs;
  output array<Integer> oMapping; //maps each simEq to the scc
  
protected
  array<Integer> tmpMapping;
  
algorithm
  //tmpMapping := arrayCreate(listLength(iMapping), -1);
  tmpMapping := arrayCreate(numOfSimEqs, -1);
  oMapping := List.fold(iMapping, convertToSimEqSccMapping1, tmpMapping);
end convertToSimEqSccMapping;

protected function convertToSimEqSccMapping1
  input tuple<Integer,Integer> iSimEqTuple;
  input array<Integer> iMapping;
  output array<Integer> oMapping;
 
protected
  Integer simEqIdx,sccIdx;
  
algorithm
  (simEqIdx,sccIdx) := iSimEqTuple;
  //print("convertToSimEqSccMapping1 " +& intString(simEqIdx) +& " .. " +& intString(sccIdx) +& " iMapping_len: " +& intString(arrayLength(iMapping)) +& "\n");
  oMapping := arrayUpdate(iMapping,simEqIdx,sccIdx);
end convertToSimEqSccMapping1;

protected function dumpSccSimEqMapping
  input array<list<Integer>> iSccMapping;
 
protected
  String text;
  
algorithm
  text := "SccToSimEqMapping";
  ((_,text)) := Util.arrayFold(iSccMapping, dumpSccSimEqMapping1, (1,text));
  print(text +& "\n");
end dumpSccSimEqMapping;

protected function dumpSccSimEqMapping1
  input list<Integer> iMapping;
  input tuple<Integer,String> iIndexText;
  output tuple<Integer,String> oIndexText;

protected
  Integer iIndex;
  String text, iText;
  
algorithm
  (iIndex,iText) := iIndexText;
  text := List.fold(iMapping, dumpSccSimEqMapping2, " ");
  text := iText +& "\nSCC " +& intString(iIndex) +& ": {" +& text +& "}";
  oIndexText := (iIndex+1,text);
end dumpSccSimEqMapping1;

protected function dumpSccSimEqMapping2
  input Integer iIndex;
  input String iText;
  output String oText;
  
algorithm
  oText := iText +& intString(iIndex) +& " ";
   
end dumpSccSimEqMapping2;

end HpcOmSimCode;
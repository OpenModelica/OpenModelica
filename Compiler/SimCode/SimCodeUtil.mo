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

encapsulated package SimCodeUtil
" file:        SimCodeUtil.mo
  package:     SimCodeUtil
  description: Code generation using Susan templates

  The entry points to this module are the functions createSimCode and
  createFunctions."


// public imports
import Absyn;
import BackendDAE;
import Ceval;
import DAE;
import FCore;
import FGraph;
import HashTable;
import HashTableCrIListArray;
import HashTableCrILst;
import HashTableExpToIndex;
import SCode;
import SimCode;
import SimCodeVar;
import Tpl;
import Types;
import Unit;
import Values;

// protected imports
protected
import Array;
import AvlSetString;
import BackendDAEOptimize;
import BackendDAETransform;
import BackendDAEUtil;
import BackendDump;
import BackendEquation;
import BackendVariable;
import BackendVarTransform;
import BaseHashSet;
import BaseHashTable;
import Builtin;
import CheckModel;
import ClassInf;
import CommonSubExpression.isCSECref;
import ComponentReference;
import Config;
import DAEDump;
import DAEUtil;
import Debug;
import Differentiate;
import DoubleEndedList;
import ElementSource;
import Error;
import ExecStat.execStat;
import Expression;
import ExpressionDump;
import ExpressionSimplify;
import ExpressionSolve;
import Flags;
import FMI;
import GC;
import Global;
import Graph;
import HashSet;
import HashSetExp;
import HashTableCrefSimVar;
import HashTableSimCodeEqCache;
import HpcOmSimCode;
import Inline;
import List;
import Matching;
import MetaModelica.Dangerous;
import Mutable;
import PriorityQueue;
import SimCodeDump;
import SimCodeFunctionUtil;
import SimCodeFunctionUtil.varName;
import SymbolicJacobian;
import System;
import Util;
import ValuesUtil;
import VisualXML;
import ZeroCrossings;
import ReduceDAE;
protected constant String UNDERLINE = "========================================";

protected function compareEqSystems
  input SimCode.SimEqSystem eq1;
  input SimCode.SimEqSystem eq2;
  output Boolean b;
algorithm
  b := simEqSystemIndex(eq1) > simEqSystemIndex(eq2);
end compareEqSystems;

public function sortEqSystems
  input list<SimCode.SimEqSystem> eqs;
  output list<SimCode.SimEqSystem> outEqs;
algorithm
  outEqs := List.sort(eqs,compareEqSystems);
end sortEqSystems;

protected function simulationFindLiterals
  "Finds all literal expressions in functionsa"
  input list<DAE.Function> fns;
  output list<DAE.Function> ofns;
  output tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
algorithm
  (ofns, literals) := DAEUtil.traverseDAEFunctions(
    fns, SimCodeFunctionUtil.findLiteralsHelper,
    (0, HashTableExpToIndex.emptyHashTableSized(BaseHashTable.bigBucketSize), {}));
  // Broke things :(
  // ((i, ht, literals)) := BackendDAEUtil.traverseBackendDAEExpsNoCopyWithUpdate(dae, findLiteralsHelper, (i, ht, literals));
end simulationFindLiterals;

public function hashEqSystemMod
  input SimCode.SimEqSystem eq;
  input Integer mod;
  output Integer hash;
algorithm
  hash := match eq
    local
      DAE.Statement stmt;
    case SimCode.SES_RESIDUAL() then Expression.hashExpMod(eq.exp, mod);
    case SimCode.SES_SIMPLE_ASSIGN() then intMod(ComponentReference.hashComponentRefMod(eq.cref,mod)+7*Expression.hashExpMod(eq.exp, mod), mod);
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS() then intMod(ComponentReference.hashComponentRefMod(eq.cref,mod)+7*Expression.hashExpMod(eq.exp, mod), mod);
    case SimCode.SES_ARRAY_CALL_ASSIGN() then intMod(Expression.hashExpMod(eq.lhs, mod)+7*Expression.hashExpMod(eq.exp, mod), mod);
    case SimCode.SES_ALGORITHM(statements={stmt as DAE.STMT_ASSERT()}) then intMod(Expression.hashExpMod(stmt.cond, mod)+7*Expression.hashExpMod(stmt.msg, mod)+49*Expression.hashExpMod(stmt.level, mod), mod);
    // Whatever; we're not caching these values anyway
    else intMod(valueConstructor(eq), mod);
  end match;
end hashEqSystemMod;

public function compareEqSystemsEquality "Is true if the equations are the same except the index. If false they might still be the same."
  input SimCode.SimEqSystem eq1;
  input SimCode.SimEqSystem eq2;
  output Boolean b;
algorithm
  b := match (eq1,eq2)
    local
      DAE.Statement stmt1,stmt2;
    case (SimCode.SES_SIMPLE_ASSIGN(),SimCode.SES_SIMPLE_ASSIGN())
      then if 0==ComponentReference.crefCompareGeneric(eq1.cref, eq2.cref) then Expression.expEqual(eq1.exp, eq2.exp) else false;
    case (SimCode.SES_ARRAY_CALL_ASSIGN(),SimCode.SES_ARRAY_CALL_ASSIGN())
      then if Expression.expEqual(eq1.lhs, eq2.lhs) then Expression.expEqual(eq1.exp, eq2.exp) else false;
    case (SimCode.SES_ALGORITHM(statements={stmt1 as DAE.STMT_ASSERT()}),SimCode.SES_ALGORITHM(statements={stmt2 as DAE.STMT_ASSERT()}))
      then if Expression.expEqual(stmt1.cond, stmt2.cond) then (if Expression.expEqual(stmt1.msg, stmt2.msg) then Expression.expEqual(stmt1.level, stmt2.level) else false) else false;
    else false;
  end match;
end compareEqSystemsEquality;

// =============================================================================
// section to create SimCode from BackendDAE
//
// =============================================================================

public function createSimCode "entry point to create SimCode from BackendDAE."
  input BackendDAE.BackendDAE inBackendDAE;
  input BackendDAE.BackendDAE inInitDAE;
  input Option<BackendDAE.BackendDAE> inInitDAE_lambda0;
  input Option<BackendDAE.InlineData> inInlineData;
  input list<BackendDAE.Equation> inRemovedInitialEquationLst;
  input Absyn.Path inClassName;
  input String filenamePrefix;
  input String inFileDir;
  input list<SimCodeFunction.Function> functions;
  input list<String> externalFunctionIncludes;
  input list<String> includeDirs;
  input list<String> libs;
  input list<String> libPaths;
  input Absyn.Program program;
  input Option<SimCode.SimulationSettings> simSettingsOpt;
  input list<SimCodeFunction.RecordDeclaration> recordDecls;
  input tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
  input Absyn.FunctionArgs args;
  input Boolean isFMU=false;
  input String FMUVersion="";
  input String fmuTargetName="";
  input BackendDAE.SymbolicJacobians inFMIDer = {};
  output SimCode.SimCode simCode;
  output tuple<Integer, list<tuple<Integer, Integer>>> outMapping "the highest simEqIndex in the mapping and the mapping simEq-Index -> scc-Index itself";
protected
  BackendDAE.BackendDAE dlow, initDAE_lambda0;
  BackendDAE.EquationArray removedEqs;
  BackendDAE.EventInfo eventInfo;
  BackendDAE.Shared shared;
  BackendDAE.SymbolicJacobians symJacs;
  BackendDAE.Variables globalKnownVars;
  Boolean ifcpp;
  HashTableCrIListArray.HashTable varToArrayIndexMapping "maps each array-variable to a array of positions";
  HashTableCrILst.HashTable varToIndexMapping "maps each variable to an array position";
  Integer maxDelayedExpIndex, uniqueEqIndex, numberofEqns, numStateSets, numberOfJacobians, sccOffset;
  Integer numberofLinearSys, numberofNonLinearSys, numberofMixedSys, numberofFixedParameters, reasonableSize;
  Option<SimCode.FmiModelStructure> modelStructure = NONE();
  SimCode.BackendMapping backendMapping;
  SimCode.ExtObjInfo extObjInfo;
  SimCode.HashTableCrefToSimVar crefToSimVarHT;
  SimCodeFunction.MakefileParams makefileParams;
  SimCode.ModelInfo modelInfo;
  HashTable.HashTable crefToClockIndexHT;
  array<Integer> systemIndexMap;
  list<BackendDAE.EqSystem> clockedSysts, contSysts;
  //list<BackendDAE.Equation> paramAsserts, remEqLst;
  list<BackendDAE.Equation> removedInitialEquationLst;
  list<BackendDAE.TimeEvent> timeEvents;
  BackendDAE.ZeroCrossingSet zeroCrossingsSet, sampleZCSet;
  DoubleEndedList<BackendDAE.ZeroCrossing> de_relations;
  list<BackendDAE.ZeroCrossing> zeroCrossings, sampleZC, relations;
  list<DAE.ClassAttributes> classAttributes;
  list<DAE.ComponentRef> discreteModelVars;
  list<DAE.Constraint> constraints;
  list<DAE.Exp> lits;
  list<SimCode.ClockedPartition> clockedPartitions;
  list<SimCode.JacobianMatrix> LinearMatrices, SymbolicJacs, SymbolicJacsTemp, SymbolicJacsStateSelect, SymbolicJacsStateSelectInternal, SymbolicJacsNLS, SymbolicJacsFMI={};
  list<SimCode.SimEqSystem> algorithmAndEquationAsserts;
  list<SimCode.SimEqSystem> localKnownVars;
  list<SimCode.SimEqSystem> allEquations;
  list<SimCode.SimEqSystem> equationsForZeroCrossings;
  list<SimCode.SimEqSystem> initialEquations;           // --> initial_equations
  list<SimCode.SimEqSystem> initialEquations_lambda0;   // --> initial_equations_lambda0
  list<SimCode.SimEqSystem> jacobianEquations;
  list<SimCode.SimEqSystem> maxValueEquations;          // --> updateBoundMaxValues
  list<SimCode.SimEqSystem> minValueEquations;          // --> updateBoundMinValues
  list<SimCode.SimEqSystem> nominalValueEquations;      // --> updateBoundNominalValues
  //list<SimCode.SimEqSystem> paramAssertSimEqs;
  list<SimCode.SimEqSystem> parameterEquations;         // --> updateBoundParameters
  list<SimCode.SimEqSystem> removedEquations;
  list<SimCode.SimEqSystem> removedInitialEquations;    // -->
  list<SimCode.SimEqSystem> startValueEquations;        // --> updateBoundStartValues
  list<SimCode.StateSet> stateSets;
  list<SimCodeVar.SimVar> tempvars, jacobianSimvars, seedVars;
  list<list<SimCode.SimEqSystem>> algebraicEquations;   // --> functionAlgebraics
  list<list<SimCode.SimEqSystem>> odeEquations;         // --> functionODE
  list<list<SimCode.SimEqSystem>> inlineEquationsTemp;  // --> symbolicInlineSystemTemp
  list<SimCode.SimEqSystem> inlineEquations;            // --> symbolicInlineSystem
  SimCodeVar.SimVars tmpSimVars;
  SimCode.VarInfo varInfo;
  list<SimCodeVar.SimVar> sensitivityVars;
  Integer countSenParams;
  list<tuple<Integer, Integer>> equationSccMapping, eqBackendSimCodeMapping;
  list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> delayedExps;
  BackendDAE.InlineData inlineData;
  list<SimCodeVar.SimVar> inlineSimKnVars;
  BackendDAE.Variables emptyVars;
  Integer SymEuler_help = 0;
  SimCodeVar.SimVar dtSimVar;
  BackendDAE.Var dtVar;
  HashTableSimCodeEqCache.HashTable eqCache;
  BackendDAE.Jacobian dataReconJac;
  BackendDAE.Variables setcVars;
  list<SimCodeVar.SimVar> tmpsetcVars;
  SimCode.JacobianMatrix dataReconSimJac;
  String fullPathPrefix;

  SimCode.OMSIFunction omsiInitEquations, omsiSimEquations;
  Option<SimCode.OMSIData> omsiOptData;

  constant Boolean debug = false;
algorithm
  try
    execStat("Backend phase and start with SimCode phase");
    dlow := inBackendDAE;

    System.tmpTickReset(0);
    uniqueEqIndex := 1;
    ifcpp := (stringEqual(Config.simCodeTarget(), "Cpp") or stringEqual(Config.simCodeTarget(), "omsicpp"));

    backendMapping := setUpBackendMapping(inBackendDAE);
    if Flags.isSet(Flags.VISUAL_XML) then
      dlow := VisualXML.visualizationInfoXML(dlow, filenamePrefix, program);
    end if;

    if Flags.isSet(Flags.ITERATION_VARS) then
      BackendDAEOptimize.listAllIterationVariables(dlow);
    end if;

    // initialization stuff
    // ********************

    if not (Config.simCodeTarget() == "omsic" or
            Config.simCodeTarget() == "omsicpp")
    then
      // generate equations for initDAE
      (initialEquations, uniqueEqIndex, tempvars) := createInitialEquations(inInitDAE, uniqueEqIndex, {});

      // generate equations for initDAE_lambda0
      if isSome(inInitDAE_lambda0) then
        SOME(initDAE_lambda0) := inInitDAE_lambda0;
        (initialEquations_lambda0, uniqueEqIndex, tempvars) := createInitialEquations_lambda0(initDAE_lambda0, uniqueEqIndex, tempvars);
      else
        initialEquations_lambda0 := {};
      end if;

      // generate equations for removed initial equations
      (removedInitialEquations, uniqueEqIndex, tempvars) := createNonlinearResidualEquations(inRemovedInitialEquationLst, uniqueEqIndex, tempvars, dlow.shared.functionTree);

      execStat("simCode: created initialization part");
    else
       initialEquations_lambda0 :={};
       initialEquations := {};
       removedInitialEquations := {};
       tempvars := {};

       // TODO: check createInitialEquations to create additional equations for knownVars, alias, etc.
       (omsiInitEquations, uniqueEqIndex) :=
           createAllEquationOMSI(inInitDAE.eqs, dlow.shared, {}, uniqueEqIndex);
    end if;

    shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars,
                                constraints=constraints,
                                classAttrs=classAttributes,
                                symjacs=symJacs,
                                eventInfo=eventInfo) := dlow.shared;

    removedEqs := BackendDAEUtil.collapseRemovedEqs(dlow);

    // created event suff e.g. zeroCrossings, samples, ...
    timeEvents := eventInfo.timeEvents;
    (zeroCrossings,relations,sampleZC) := match eventInfo
      case BackendDAE.EVENT_INFO(zeroCrossings=zeroCrossingsSet, relations=de_relations, samples=sampleZCSet)
      then (ZeroCrossings.toList(zeroCrossingsSet), DoubleEndedList.toListNoCopyNoClear(de_relations), ZeroCrossings.toList(sampleZCSet));
    end match;
    if ifcpp then
      zeroCrossings := listAppend(relations, sampleZC);
    end if;

    (clockedSysts, contSysts) := List.splitOnTrue(dlow.eqs, BackendDAEUtil.isClockedSyst);
    execStat("simCode: created event and clocks part");

    // ToDo: fix this ugly flag switchting
    if (Flags.getConfigEnum(Flags.SYM_SOLVER) > 0) then
      SymEuler_help := Flags.getConfigEnum(Flags.SYM_SOLVER);
      Flags.setConfigEnum(Flags.SYM_SOLVER, 0);
    end if;

    if not (Config.simCodeTarget() == "omsic" or
            Config.simCodeTarget() == "omsicpp")
    then
      (uniqueEqIndex, odeEquations, algebraicEquations, localKnownVars, allEquations, equationsForZeroCrossings, tempvars,
        equationSccMapping, eqBackendSimCodeMapping, backendMapping, sccOffset) :=
           createEquationsForSystems(contSysts, shared, uniqueEqIndex, zeroCrossings, tempvars, 1, backendMapping, true);
      omsiOptData := NONE();
      if debug then execStat("simCode: createEquationsForSystems"); end if;
    else
      odeEquations :={};
      algebraicEquations := {};
      localKnownVars := {};
      allEquations := {};
      equationsForZeroCrossings := {};
      equationSccMapping := {};
      eqBackendSimCodeMapping := {};
      sccOffset := 0;
      (omsiSimEquations, uniqueEqIndex) :=
          createAllEquationOMSI(contSysts, shared, zeroCrossings, uniqueEqIndex);

      // Add removed equations (e.g. reinit)
      ((uniqueEqIndex, removedEquations)) := BackendEquation.traverseEquationArray(removedEqs, traversedlowEqToSimEqSystem, (uniqueEqIndex, {}));
      omsiSimEquations.equations := listAppend(omsiSimEquations.equations, removedEquations);

      omsiOptData := SOME(SimCode.OMSI_DATA(simulation=omsiSimEquations, initialization=omsiInitEquations));

      // debug print
      if debug then
        _ := match omsiOptData
          local
            SimCode.OMSIData omsiData;
          case SOME(omsiData as SimCode.OMSI_DATA(__))
            algorithm
              dumpOMSIData(omsiData, "Dump OMSI Data");
            then ();
        end match;
      end if;
    end if;


    if (SymEuler_help > 0) then
      Flags.setConfigEnum(Flags.SYM_SOLVER, SymEuler_help);
    end if;

    //List.map1_0(inlineEquations, dumpSimEqSystemLst,"\n");
    if debug then execStat("simCode: createEquationsForSystems for inline module"); end if;

    outMapping := (uniqueEqIndex /* highestSimEqIndex */, equationSccMapping);
    execStat("simCode: created simulation system equations");

    //(remEqLst, paramAsserts) := List.fold1(BackendEquation.equationList(removedEqs), getParamAsserts, globalKnownVars,({},{}));
    //((uniqueEqIndex, removedEquations)) := BackendEquation.traverseEquationArray(BackendEquation.listEquation(remEqLst), traversedlowEqToSimEqSystem, (uniqueEqIndex, {}));
    ((uniqueEqIndex, removedEquations)) := BackendEquation.traverseEquationArray(removedEqs, traversedlowEqToSimEqSystem, (uniqueEqIndex, {}));
    if debug then execStat("simCode: traversedlowEqToSimEqSystem"); end if;

    (clockedPartitions, uniqueEqIndex, backendMapping, equationSccMapping, eqBackendSimCodeMapping, tempvars) :=
          translateClockedEquations(clockedSysts, dlow.shared, sccOffset, uniqueEqIndex,
                                    backendMapping, equationSccMapping, eqBackendSimCodeMapping, tempvars);
    if debug then execStat("simCode: translateClockedEquations"); end if;

    // Assertions and crap
    // create parameter equations
    ((uniqueEqIndex, startValueEquations, _)) := BackendDAEUtil.foldEqSystem(dlow, createStartValueEquations, (uniqueEqIndex, {}, globalKnownVars));
    if debug then execStat("simCode: createStartValueEquations"); end if;
    ((uniqueEqIndex, nominalValueEquations)) := BackendDAEUtil.foldEqSystem(dlow, createNominalValueEquations, (uniqueEqIndex, {}));
    if debug then execStat("simCode: createNominalValueEquations"); end if;
    ((uniqueEqIndex, minValueEquations)) := BackendDAEUtil.foldEqSystem(dlow, createMinValueEquations, (uniqueEqIndex, {}));
    if debug then execStat("simCode: createMinValueEquations"); end if;
    ((uniqueEqIndex, maxValueEquations)) := BackendDAEUtil.foldEqSystem(dlow, createMaxValueEquations, (uniqueEqIndex, {}));
    if debug then execStat("simCode: createMaxValueEquations"); end if;
    ((uniqueEqIndex, parameterEquations)) := BackendDAEUtil.foldEqSystem(dlow, createVarNominalAssertFromVars, (uniqueEqIndex, {}));
    if debug then execStat("simCode: createVarNominalAssertFromVars"); end if;
    (uniqueEqIndex, parameterEquations, numberofFixedParameters) := createParameterEquations(uniqueEqIndex, parameterEquations, globalKnownVars);
    if debug then execStat("simCode: createParameterEquations"); end if;
    //((uniqueEqIndex, paramAssertSimEqs)) := BackendEquation.traverseEquationArray(BackendEquation.listEquation(paramAsserts), traversedlowEqToSimEqSystem, (uniqueEqIndex, {}));
    //parameterEquations := listAppend(parameterEquations, paramAssertSimEqs);

    ((uniqueEqIndex, algorithmAndEquationAsserts)) := BackendDAEUtil.foldEqSystem(dlow, createAlgorithmAndEquationAsserts, (uniqueEqIndex, {}));
    if debug then execStat("simCode: createAlgorithmAndEquationAsserts"); end if;
    discreteModelVars := BackendDAEUtil.foldEqSystem(dlow, extractDiscreteModelVars, {});
    if debug then execStat("simCode: extractDiscreteModelVars"); end if;
    makefileParams := SimCodeFunctionUtil.createMakefileParams(includeDirs, libs, libPaths, false, isFMU);
    (delayedExps, maxDelayedExpIndex) := extractDelayedExpressions(dlow);
    execStat("simCode: created of all other equations (e.g. parameter, nominal, assert, etc)");

    // append removed equation to all equations, since these are actually
    // just the algorithms without outputs
    algebraicEquations := listAppend(algebraicEquations, removedEquations::{});
    allEquations := List.append_reverse(allEquations, removedEquations);

    // create inline equations if present
    if isSome(inInlineData) then
      SOME(inlineData) := inInlineData;
      (uniqueEqIndex, inlineEquationsTemp, _, _, , _, tempvars, _, _, _, _) :=
            createEquationsForSystems(inlineData.inlineSystems,
                                      shared, uniqueEqIndex, {}, tempvars, uniqueEqIndex,
                                      SimCode.NO_MAPPING(), false);
      inlineEquations := List.flatten(inlineEquationsTemp);
    else
      inlineEquations := {};
    end if;

    // state set stuff
    (dlow, stateSets, uniqueEqIndex, tempvars, numStateSets) := createStateSets(dlow, {}, uniqueEqIndex, tempvars);
    if debug then execStat("simCode: createStateSets"); end if;

    // create model info
    modelInfo := createModelInfo(inClassName, program, dlow, inInitDAE, functions, {}, numStateSets, inFileDir, listLength(clockedSysts), tempvars);
    if debug then execStat("simCode: createModelInfo and variables"); end if;

    //build labels
    if(boolAnd(ifcpp,Flags.getConfigBool(Flags.LABELED_REDUCTION))) then
      Flags.setConfigBool(Flags.GENERATE_LABELED_SIMCODE,true);
    end if;

    if(ifcpp) then
      if Flags.getConfigBool(Flags.GENERATE_LABELED_SIMCODE) then
        (allEquations,modelInfo) := ReduceDAE.buildLabels(allEquations,modelInfo,{},args);
        //Flags.set(Flags.REDUCE_DAE,true);
        if debug then execStat("ReduceDAE: buildLabels"); end if;
      end if;
    end if;

    tmpSimVars := modelInfo.vars;

    //reduce terms
    if(ifcpp) then
      if Flags.getConfigBool(Flags.REDUCE_TERMS) then
        (allEquations,modelInfo) := ReduceDAE.reduceTerms(allEquations,modelInfo,args);
        Flags.setConfigBool(Flags.REDUCE_TERMS, false);
        Flags.disableDebug(Flags.REDUCE_DAE);
        if debug then execStat("ReduceDAE: reduceTerms"); end if;
      end if;
    end if;
    // external objects
    extObjInfo := createExtObjInfo(shared);

    // update index of zero-Crossings after equations are created
    zeroCrossings := updateZeroCrossEqnIndex(zeroCrossings, eqBackendSimCodeMapping, BackendDAEUtil.equationArraySizeBDAE(dlow));
    if debug then execStat("simCode: update zero crossing index"); end if;

    // collect all LinearSystem and NonlinearSystem algebraic system in modelInfo and update
    // the corresponding index (indexNonLinear, indexLinear) in SES_NONLINEAR and SES_LINEAR
    // Also collect all jacobians
    SymbolicJacsNLS := {};
    (initialEquations, modelInfo, SymbolicJacsTemp) := addAlgebraicLoopsModelInfo(initialEquations, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
    (initialEquations_lambda0, modelInfo, SymbolicJacsTemp) := addAlgebraicLoopsModelInfo(initialEquations_lambda0, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
    (parameterEquations, modelInfo, SymbolicJacsTemp) := addAlgebraicLoopsModelInfo(parameterEquations, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
    (allEquations, modelInfo, SymbolicJacsTemp) := addAlgebraicLoopsModelInfo(allEquations, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
    (clockedPartitions, modelInfo, SymbolicJacsTemp) := addAlgebraicLoopsClockPartitions(clockedPartitions, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
    (inlineEquations, modelInfo, SymbolicJacsTemp) := addAlgebraicLoopsModelInfo(inlineEquations, modelInfo);
    SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);

    // Generate jacobian code for DataReconciliation
    //if Flags.isSet(Flags.UNCERTAINTIES) then
      if Util.isSome(shared.dataReconciliationData) then
        BackendDAE.DATA_RECON(dataReconJac,setcVars) := Util.getOption(shared.dataReconciliationData);
        (SOME(dataReconSimJac), uniqueEqIndex, tempvars) := createSymbolicSimulationJacobian(dataReconJac, uniqueEqIndex, tempvars);
        ({dataReconSimJac}, modelInfo, SymbolicJacsTemp) := addAlgebraicLoopsModelInfoSymJacs({dataReconSimJac}, modelInfo);
        SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
       SymbolicJacsNLS := dataReconSimJac::SymbolicJacsNLS;
      end if;
    //end if;

    // collect symbolic jacobians from state selection
    (stateSets, modelInfo, SymbolicJacsStateSelect, SymbolicJacsStateSelectInternal) :=  addAlgebraicLoopsModelInfoStateSets(stateSets, modelInfo);
    if debug then execStat("simCode: collect and index LS/NLS in modelInfo"); end if;

    // collect fmi partial derivative
    if FMI.isFMIVersion20(FMUVersion) or Config.simCodeTarget() ==  "omsicpp"  then
      (SymbolicJacsFMI, modelStructure, modelInfo, SymbolicJacsTemp, uniqueEqIndex) := createFMIModelStructure(inFMIDer, modelInfo, uniqueEqIndex);
      SymbolicJacsNLS := listAppend(SymbolicJacsTemp, SymbolicJacsNLS);
      if debug then execStat("simCode: create FMI model structure"); end if;
    end if;
    // collect symbolic jacobians in linear loops of the overall jacobians
    (LinearMatrices, uniqueEqIndex) := createJacobianLinearCode(symJacs, modelInfo, uniqueEqIndex, shared);
    (SymbolicJacs, modelInfo, SymbolicJacsTemp) := addAlgebraicLoopsModelInfoSymJacs(LinearMatrices, modelInfo);
    SymbolicJacs := listAppend(SymbolicJacsFMI, SymbolicJacs);
    SymbolicJacs := listAppend(SymbolicJacs, SymbolicJacsStateSelect);
    // collect jacobian equation only for equantion info file
    jacobianEquations := collectAllJacobianEquations(SymbolicJacs);
    if debug then execStat("simCode: create Jacobian linear code"); end if;

    SymbolicJacs := listAppend(listReverse(SymbolicJacsNLS), SymbolicJacs);
    SymbolicJacs := listAppend(SymbolicJacs, SymbolicJacsTemp);
    SymbolicJacs := listAppend(SymbolicJacs, SymbolicJacsStateSelectInternal);
    jacobianSimvars := collectAllJacobianVars(SymbolicJacs);
    modelInfo := setJacobianVars(jacobianSimvars, modelInfo);
    seedVars := collectAllSeedVars(SymbolicJacs);
    modelInfo := setSeedVars(seedVars, modelInfo);
    execStat("simCode: created linear, non-linear and system jacobian parts");

    // map index also odeEquations and algebraicEquations
    systemIndexMap := List.fold(allEquations, getSystemIndexMap, arrayCreate(uniqueEqIndex, -1));
    odeEquations := List.mapList1_1(odeEquations, setSystemIndexMap, systemIndexMap);
    algebraicEquations := List.mapList1_1(algebraicEquations, setSystemIndexMap, systemIndexMap);
    modelInfo := addNumEqns(modelInfo, uniqueEqIndex /* This is a *much* better estimate than the guessed number of equations */ );

    odeEquations := makeEqualLengthLists(odeEquations, Config.noProc());
    algebraicEquations := makeEqualLengthLists(algebraicEquations, Config.noProc());

    // Filter out empty systems to improve code generation
    odeEquations := List.filterOnFalse(odeEquations, listEmpty);
    algebraicEquations := List.filterOnFalse(algebraicEquations, listEmpty);

    if Flags.isSet(Flags.EXEC_HASH) then
      print("*** SimCode -> generate cref2simVar hashtable: " + realString(clock()) + "\n");
    end if;
    // generate cref2simVar hash table
    crefToSimVarHT := createCrefToSimVarHT(modelInfo);

    if Flags.isSet(Flags.EXEC_HASH) then
      print("*** SimCode -> generate cref2simVar hashtable done!: " + realString(clock()) + "\n");
    end if;
    // add known inline vars to simVarHT
    if (Flags.getConfigEnum(Flags.SYM_SOLVER) > 0) then
      SOME(inlineData) := inInlineData;
      emptyVars := BackendVariable.emptyVars();
      inlineSimKnVars := adjustStatesForInlineSolver(modelInfo.vars.stateVars);
      // omc dt
      ({dtVar},_) := BackendVariable.getVar(ComponentReference.makeCrefIdent(BackendDAE.symSolverDT, DAE.T_REAL_DEFAULT, {}), inlineData.knownVariables);
      dtSimVar := dlowvarToSimvar(dtVar, NONE(), emptyVars);
      dtSimVar.index := listLength(inlineSimKnVars);
      inlineSimKnVars := dtSimVar::inlineSimKnVars;
      crefToSimVarHT := List.fold(inlineSimKnVars,HashTableCrefSimVar.addSimVarToHashTable,crefToSimVarHT);
    end if;

    if Flags.getConfigBool(Flags.CALCULATE_SENSITIVITIES) then
      tmpSimVars := modelInfo.vars;
      (sensitivityVars, countSenParams) := createSimVarsForSensitivities(tmpSimVars.stateVars, tmpSimVars.paramVars, numberofFixedParameters);
      sensitivityVars := rewriteIndex(sensitivityVars, 0);
      tmpSimVars.sensitivityVars := sensitivityVars;
      modelInfo.vars := tmpSimVars;
      // set varInfo nSensitivities
      varInfo := modelInfo.varInfo;
      varInfo.numSensitivityParameters := countSenParams;
      modelInfo.varInfo := varInfo;
    end if;
    // Generates c code for setC-results which calculates c(x,y) for dataReconciliation
    if Util.isSome(shared.dataReconciliationData) then
        tmpSimVars := modelInfo.vars;
        //BackendDAE.DATA_RECON(dataReconJac,setcVars) := Util.getOption(shared.dataReconciliationData);
       ((tmpsetcVars, _)) :=  BackendVariable.traverseBackendDAEVars(setcVars, traversingdlowvarToSimvar, ({}, emptyVars));
        tmpsetcVars := rewriteIndex(tmpsetcVars, 0);
        tmpSimVars.dataReconSetcVars := tmpsetcVars;
        modelInfo.vars := tmpSimVars;
        // set varInfo nsetcvars
        varInfo := modelInfo.varInfo;
        varInfo.numSetcVars := listLength(tmpsetcVars);
        modelInfo.varInfo := varInfo;
        //print("\n simcode gen setc:*****"+anyString(tmpsetcVars) + "\n lenght of vars :" +anyString(listLength(tmpsetcVars)));
    end if;
    //print("\n created model_info:"+ anyString(modelInfo.varInfo.numSetcVars)+ "\n setcvars" + anyString(modelInfo.vars.dataReconSetcVars));
    backendMapping := setBackendVarMapping(inBackendDAE, crefToSimVarHT, modelInfo, backendMapping);
    //dumpBackendMapping(backendMapping);

    (varToArrayIndexMapping, varToIndexMapping) := createVarToArrayIndexMapping(modelInfo);
    //print("HASHTABLE MAPPING\n\n");
    //BaseHashTable.dumpHashTable(varToArrayIndexMapping);
    //print("END MAPPING\n\n");

    (crefToClockIndexHT, _) := List.fold(listReverse(inBackendDAE.eqs), collectClockedVars, (HashTable.emptyHashTable(), 1));

    execStat("simCode: some other stuff during SimCode phase");


     if ((Config.simCodeTarget() <> "Cpp") and (Config.simCodeTarget()<>"omsicpp"))then
      reasonableSize := Util.nextPrime(10+integer(1.4*(BackendDAEUtil.equationArraySizeBDAE(inBackendDAE)+BackendDAEUtil.equationArraySizeBDAE(inInitDAE)+listLength(parameterEquations))));
      eqCache := HashTableSimCodeEqCache.emptyHashTableSized(reasonableSize);


      // Alias equations to other equations.
      // The C++ codegen does things differently and will not handle this
      (allEquations, eqCache) := aliasSimEqs(allEquations, eqCache);
      (odeEquations, eqCache) := aliasSimEqSystems(odeEquations, eqCache);
      (algebraicEquations, eqCache) := aliasSimEqSystems(algebraicEquations, eqCache);
      (initialEquations, eqCache) := aliasSimEqs(initialEquations, eqCache);
      (initialEquations_lambda0, eqCache) := aliasSimEqs(initialEquations_lambda0, eqCache);
      (removedEquations, eqCache) := aliasSimEqs(removedEquations, eqCache);
      (removedInitialEquations, eqCache) := aliasSimEqs(removedInitialEquations, eqCache);
      (algorithmAndEquationAsserts, eqCache) := aliasSimEqs(algorithmAndEquationAsserts, eqCache);
      (jacobianEquations, eqCache) := aliasSimEqs(jacobianEquations, eqCache);
      (parameterEquations, eqCache) := aliasSimEqs(parameterEquations, eqCache);
      execStat("simCode: alias equations");
    end if;

    // Set fullPathPrefix for FMUs
    if isFMU then
      if Config.simCodeTarget()=="omsic" then
        fullPathPrefix := filenamePrefix+".fmutmp";
      elseif Config.simCodeTarget()=="omsicpp" then
        fullPathPrefix := inFileDir;
      else
        fullPathPrefix := filenamePrefix+".fmutmp/sources/";
      end if;
    else
      fullPathPrefix := "";
    end if;

    simCode := SimCode.SIMCODE(modelInfo,
                              {}, // Set by the traversal below...
                              recordDecls,
                              externalFunctionIncludes,
                              localKnownVars,
                              allEquations,
                              odeEquations,
                              algebraicEquations,
                              clockedPartitions,
                              initialEquations,
                              initialEquations_lambda0,
                              removedInitialEquations,
                              startValueEquations,
                              nominalValueEquations,
                              minValueEquations,
                              maxValueEquations,
                              parameterEquations,
                              removedEquations,
                              algorithmAndEquationAsserts,
                              equationsForZeroCrossings,
                              jacobianEquations,
                              stateSets,
                              constraints,
                              classAttributes,
                              zeroCrossings,
                              relations,
                              timeEvents,
                              discreteModelVars,
                              extObjInfo,
                              makefileParams,
                              SimCode.DELAYED_EXPRESSIONS(delayedExps, maxDelayedExpIndex),
                              SymbolicJacs,
                              simSettingsOpt,
                              filenamePrefix,
                              fullPathPrefix,
                              fmuTargetName,
                              HpcOmSimCode.emptyHpcomData,
                              if isFMU then getValueReferenceMapping(modelInfo) else AvlTreeCRToInt.EMPTY(),
                              varToArrayIndexMapping,
                              varToIndexMapping,
                              crefToSimVarHT,
                              crefToClockIndexHT,
                              SOME(backendMapping),
                              modelStructure,
                              SimCode.emptyPartitionData,
                              NONE(),
                              inlineEquations,
                              omsiOptData
                              );

    (simCode, (_, _, lits)) := traverseExpsSimCode(simCode, SimCodeFunctionUtil.findLiteralsHelper, literals);

    simCode := setSimCodeLiterals(simCode, listReverse(lits));

    // dumpCrefToSimVarHashTable(crefToSimVarHT);
    // print("*** SimCode -> collect all files started: " + realString(clock()) + "\n");
    // adrpo: collect all the files from SourceInfo and DAE.ElementSource
    // simCode := collectAllFiles(simCode);
    // print("*** SimCode -> collect all files done!: " + realString(clock()) + "\n");
    execStat("simCode: all other stuff during SimCode phase");

    if Flags.isSet(Flags.DUMP_SIMCODE) then
      dumpSimCodeDebug(simCode);
    end if;
  else
    Error.addInternalError("function createSimCode failed [Transformation from optimised DAE to simulation code structure failed]", sourceInfo());
    fail();
  end try;
end createSimCode;

public function createFunctions
  input Absyn.Program inProgram;
  input DAE.FunctionTree functionTree;
  output list<String> outLibs;
  output list<String> outLibPaths;
  output list<String> outIncludes;
  output list<String> outIncludeDirs;
  output list<SimCodeFunction.RecordDeclaration> outRecordDecls;
  output list<SimCodeFunction.Function> outFunctions;
  output tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> outLiterals;
protected
  list<DAE.Function> funcelems;
  list<DAE.Exp> lits;
algorithm
  try
    // get all the used functions from the function tree
    funcelems := DAEUtil.getFunctionList(functionTree);
    funcelems := Inline.inlineCallsInFunctions(funcelems, (NONE(), {DAE.NORM_INLINE(), DAE.AFTER_INDEX_RED_INLINE()}), {});
    (funcelems, outLiterals as (_, _, lits)) := simulationFindLiterals(funcelems);
    (outFunctions, outRecordDecls, outIncludes, outIncludeDirs, outLibs, outLibPaths) := SimCodeFunctionUtil.elaborateFunctions(inProgram, funcelems, {}, lits, {}); // Do we need metarecords here as well?
  else
    Error.addInternalError("Creation of Modelica functions failed.", sourceInfo());
    fail();
  end try;
end createFunctions;

protected function getParamAsserts"splits the equationArray in variable-dependent and parameter-dependent equations.
author: Waurich  TUD-2015-04"
  input BackendDAE.Equation eqIn;
  input BackendDAE.Variables vars;
  input tuple<list<BackendDAE.Equation>, list<BackendDAE.Equation>> tplIn; //<var-dependent, param-dependent>
  output tuple<list<BackendDAE.Equation>, list<BackendDAE.Equation>> tplOut;
algorithm
  tplOut := matchcontinue(eqIn,vars,tplIn)
    local
      list<DAE.Statement> stmts;
      list<DAE.ComponentRef> crefs;
      list<BackendDAE.Var> varLst;
      list<list<BackendDAE.Var>> varLstLst;
      list<BackendDAE.Equation> varDep,paramDep;
  case(BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(statementLst=stmts)),_,(varDep,paramDep))
    algorithm
      crefs := List.fold(stmts,DAEUtil.getAssertConditionCrefs,{});
      (varLstLst,_) := List.map1_2(crefs,BackendVariable.getVar,vars);
      varLst := List.flatten(varLstLst);
      true := List.exist(varLst,BackendVariable.isParam);
  then ((varDep,eqIn::paramDep));
  else
    algorithm
     (varDep,paramDep) := tplIn;
    then ((eqIn::varDep,paramDep));
  end matchcontinue;
end getParamAsserts;

protected function translateClockedEquations
  input BackendDAE.EqSystems inSysts;
  input BackendDAE.Shared inShared;
  input Integer iSccOffset;
  input Integer iuniqueEqIndex;
  input SimCode.BackendMapping iBackendMapping;
  input list<tuple<Integer,Integer>> ieqSccMapping;
  input list<tuple<Integer,Integer>> ieqBackendSimCodeMapping;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.ClockedPartition> outPartitions = {};
  output Integer ouniqueEqIndex = iuniqueEqIndex;
  output SimCode.BackendMapping oBackendMapping = iBackendMapping;
  output list<tuple<Integer,Integer>> oeqSccMapping = ieqSccMapping;
  output list<tuple<Integer,Integer>> oeqBackendSimCodeMapping = ieqBackendSimCodeMapping;
  output list<SimCodeVar.SimVar> otempvars = itempvars;
protected
  Integer baseIdx, subPartIdx, cnt;
  BackendDAE.SubClock subClk;
  list<SimCode.SimEqSystem> removedEquations, equations, preEquations;
  SimCode.SubPartition simSubPartition;
  Boolean holdEvents;
  array<Integer> ass1, stateeqnsmark, zceqnsmarks;
  DAE.FunctionTree funcs;
  BackendDAE.StrongComponents comps;
  Integer sccOffset = iSccOffset;
  list<Integer> varIxs;
  DAE.Type ty;
  BackendDAE.Var var;
  BackendDAE.Equation eq;
  SimCodeVar.SimVar simVar;
  DAE.ComponentRef cr;
  list<SimCodeVar.SimVar> clockedVars;
  list<tuple<SimCodeVar.SimVar, Boolean>> prevClockedVars;
  array<Option<SimCode.SubPartition>> simSubPartitions;
  BackendDAE.SubPartition subPartition;
  BackendDAE.Var var;
  array<Boolean> isPrevVar;
  SimCode.SimEqSystem simEq;
algorithm
  simSubPartitions := arrayCreate(arrayLength(inShared.partitionsInfo.subPartitions), NONE());
  funcs := BackendDAEUtil.getFunctions(inShared);
  for syst in inSysts loop
    //syst := preCalculateStartValues(syst, inShared.globalKnownVars, funcs);

    BackendDAE.CLOCKED_PARTITION(subPartIdx) := syst.partitionKind;
    BackendDAE.MATCHING(ass1=ass1, comps=comps) := syst.matching;
    subPartition := inShared.partitionsInfo.subPartitions[subPartIdx];

    (syst, _, _) := BackendDAEUtil.getIncidenceMatrixfromOption(syst, BackendDAE.ABSOLUTE(), SOME(funcs));
    stateeqnsmark := arrayCreate(BackendDAEUtil.equationArraySizeDAE(syst), 0);
    stateeqnsmark := BackendDAEUtil.markStateEquations(syst, stateeqnsmark, ass1);
    zceqnsmarks := arrayCreate(BackendDAEUtil.equationArraySizeDAE(syst), 0);

    //FIXME: Add continuous clocked systems support
    (_, _, equations, _, ouniqueEqIndex, clockedVars, oeqSccMapping, oeqBackendSimCodeMapping, oBackendMapping) :=
        createEquationsForSystem(stateeqnsmark, zceqnsmarks, syst, inShared, comps, ouniqueEqIndex, {},
                                 sccOffset, oeqSccMapping, oeqBackendSimCodeMapping, oBackendMapping, true);
    sccOffset := listLength(comps) + sccOffset;
    //otempvars := listAppend(clockedVars, otempvars);
    GC.free(stateeqnsmark);
    GC.free(zceqnsmarks);

    (ouniqueEqIndex, removedEquations) := BackendEquation.traverseEquationArray(syst.removedEqs, traversedlowEqToSimEqSystem, (ouniqueEqIndex, {}));

    prevClockedVars := {};
    isPrevVar := arrayCreate(BackendVariable.varsSize(syst.orderedVars), false);

    for cr in subPartition.prevVars loop
      (_, varIxs) := BackendVariable.getVar(cr, syst.orderedVars);
      for i in varIxs loop
        arrayUpdate(isPrevVar, i, true);
      end for;
    end for;
    for i in 1:BackendVariable.varsSize(syst.orderedVars) loop
      var := BackendVariable.getVarAt(syst.orderedVars, i);
      simVar := dlowvarToSimvar(var, SOME(inShared.aliasVars), inShared.globalKnownVars);
      prevClockedVars := (simVar, isPrevVar[i])::prevClockedVars;
      clockedVars := simVar::clockedVars;
      if isPrevVar[i] then
        cr := simVar.name;
        simVar.name := ComponentReference.crefPrefixPrevious(cr);
        clockedVars := simVar::clockedVars;
        simEq := SimCode.SES_SIMPLE_ASSIGN(ouniqueEqIndex, simVar.name, DAE.CREF(cr, simVar.type_), DAE.emptyElementSource, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
         equations := simEq::equations;
        ouniqueEqIndex := ouniqueEqIndex + 1;
      end if;
    end for;
    GC.free(isPrevVar);

    //otempvars := listAppend(clockedVars, otempvars);
    simSubPartition := SimCode.SUBPARTITION(prevClockedVars,  equations, removedEquations, subPartition.clock, subPartition.holdEvents);

    assert(isNone(simSubPartitions[subPartIdx]), "SimCodeUtil.translateClockedEquations failed");
    arrayUpdate(simSubPartitions, subPartIdx, SOME(simSubPartition));

  end for;
  outPartitions := createClockedSimPartitions(inShared.partitionsInfo.basePartitions, simSubPartitions);
  GC.free(simSubPartitions);
end translateClockedEquations;

protected function createClockedSimPartitions
  input array<BackendDAE.BasePartition> basePartitions;
  input array<Option<SimCode.SubPartition>> subPartitions;
  output list<SimCode.ClockedPartition> clockedPartitions = {};
protected
  Integer off = 1;
  BackendDAE.BasePartition basePartition;
  list<SimCode.SubPartition> simSubPartitions;
algorithm
  for i in 1:arrayLength(basePartitions) loop
    basePartition := basePartitions[i];
    if basePartition.nSubClocks > 0 then
      simSubPartitions := List.map(Array.getRange(off, off + basePartition.nSubClocks - 1, subPartitions), Util.getOption);
      simSubPartitions := listReverse(simSubPartitions);
    else
      simSubPartitions := {};
    end if;
    off := off + basePartition.nSubClocks;
    clockedPartitions := SimCode.CLOCKED_PARTITION(basePartition.clock, simSubPartitions)::clockedPartitions;
  end for;
    clockedPartitions := listReverse(clockedPartitions); // in order to keep the correct indexes for the correct clkfire-calls
end createClockedSimPartitions;

protected function collectClockedVars "author: rfranke
  This function collects clocked variables along with their clockIndex"
  input BackendDAE.EqSystem inEqSystem;
  input tuple<HashTable.HashTable, Integer> inTpl;
  output tuple<HashTable.HashTable, Integer> outTpl;
protected
  HashTable.HashTable inHT, outHT;
  Integer clockIndex;
algorithm
  (inHT, clockIndex) := inTpl;
  outTpl := match inEqSystem
    case BackendDAE.EQSYSTEM(partitionKind = BackendDAE.CLOCKED_PARTITION(_)) equation
      (outHT, _) = BackendVariable.traverseBackendDAEVars(inEqSystem.orderedVars, collectClockedVars1, (inHT, clockIndex));
    then (outHT, clockIndex + 1);
    else inTpl;
  end match;
end collectClockedVars;

protected function collectClockedVars1 "author: rfranke
  Helper to collectClockedVars"
  input BackendDAE.Var inVar;
  input tuple<HashTable.HashTable, Integer> inTpl;
  output BackendDAE.Var outVar;
  output tuple<HashTable.HashTable, Integer> outTpl;
protected
  HashTable.HashTable clkHT;
  Integer clockIndex;
  DAE.ComponentRef cref;
algorithm
  (clkHT, clockIndex) := inTpl;
  (outVar, outTpl) := match inVar
    case BackendDAE.VAR(varName=cref) equation
      clkHT = BaseHashTable.add((cref, clockIndex), clkHT);
      clkHT = BaseHashTable.add((ComponentReference.crefPrefixPrevious(cref), clockIndex), clkHT);
    then (inVar, (clkHT, clockIndex));
    else (inVar, inTpl);
  end match;
end collectClockedVars1;

public function getClockIndex "author: rfranke
  Returns the index of the clock of a variable or zero non-clocked variables"
  input SimCodeVar.SimVar simVar;
  input SimCode.SimCode simCode;
  output Option<Integer> clockIndex;
protected
  DAE.ComponentRef cref;
  HashTable.HashTable clkHT;
algorithm
  cref := getSimVarCompRef(simVar);
  clockIndex := match simCode
    case SimCode.SIMCODE(crefToClockIndexHT=clkHT) then
      if BaseHashTable.hasKey(cref, clkHT)
      then SOME(BaseHashTable.get(cref, clkHT))
      else NONE();
  end match;
end getClockIndex;

protected function getSimVarCompRef
  input SimCodeVar.SimVar inVar;
  output DAE.ComponentRef outComp;
algorithm
  outComp := inVar.name;
end getSimVarCompRef;

public function getSubPartitions
  input list<SimCode.ClockedPartition> inPartitions;
  output list<SimCode.SubPartition> outSubPartitions;
algorithm
  outSubPartitions := List.flatten(List.map(inPartitions, getSubPartition));
end getSubPartitions;

public function getSubPartition
  input SimCode.ClockedPartition inPartition;
  output list<SimCode.SubPartition> outSubPartitions;
algorithm
  outSubPartitions := inPartition.subPartitions;
end getSubPartition;

public function getClockedEquations
  input list<SimCode.SubPartition> inSubPartitions;
  output list<SimCode.SimEqSystem> outEqs = {};
algorithm
  for part in inSubPartitions loop
    outEqs := listAppend(part.equations, outEqs);
    outEqs := listAppend(part.removedEquations, outEqs);
  end for;
end getClockedEquations;

protected function addTempVars
  input array<list<SimCodeVar.SimVar>> simVars;
  input list<SimCodeVar.SimVar> tempVars;
protected
  Integer ix;
algorithm
  for e in tempVars loop
    ix := match e.type_
    case DAE.T_INTEGER() then Integer(SimVarsIndex.intAlg);
    case DAE.T_ENUMERATION() then Integer(SimVarsIndex.intAlg);
    case DAE.T_BOOL() then Integer(SimVarsIndex.boolAlg);
    case DAE.T_STRING() then Integer(SimVarsIndex.stringAlg);
    else Integer(SimVarsIndex.alg);
    end match;
    arrayUpdate(simVars, ix, e::simVars[ix]);
  end for;
end addTempVars;

public function setJacobianVars "author: unknown
  Set the given jacobian vars in the given model info. The old jacobian variables will be replaced."
  input list<SimCodeVar.SimVar> iJacobianVars;
  input SimCode.ModelInfo iModelInfo;
  output SimCode.ModelInfo oModelInfo = iModelInfo;
protected
  SimCodeVar.SimVars vars;
algorithm
  if not listEmpty(iJacobianVars) then
    vars := oModelInfo.vars;
    vars.jacobianVars := iJacobianVars;
    oModelInfo.vars := vars;
  end if;
end setJacobianVars;

public function setSeedVars
  "Set the given seed vars in the given model info, replacing old seed vars.
   author: rfranke"
  input list<SimCodeVar.SimVar> seedVars;
  input output SimCode.ModelInfo modelInfo;
protected
  SimCodeVar.SimVars vars;
algorithm
  vars := modelInfo.vars;
  vars.seedVars := seedVars;
  modelInfo.vars := vars;
end setSeedVars;

public function addNumEqns
  input SimCode.ModelInfo modelInfo;
  input Integer numEqns;
  output SimCode.ModelInfo omodelInfo = modelInfo;
protected
  SimCode.VarInfo varInfo;
algorithm
  varInfo := omodelInfo.varInfo;
  varInfo.numEquations := numEqns;
  omodelInfo.varInfo := varInfo;
end addNumEqns;

protected function getSystemIndexMap
  input SimCode.SimEqSystem inEqn;
  input array<Integer> inSysIndexMap;
  output array<Integer> outSysIndexMap;
algorithm
  outSysIndexMap := match(inEqn, inSysIndexMap)
    local
      Integer index, systemIndex, index2, systemIndex2;
      array<Integer> sysIndexMap;
      SimCode.SimEqSystem cont;
      list<SimCode.SimEqSystem> eqs, eqs2;

    // no dynamic tearing
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=index, indexLinearSystem=systemIndex), NONE()), _) equation
      sysIndexMap = arrayUpdate(inSysIndexMap, index, systemIndex);
    then sysIndexMap;

    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=index, eqs=eqs, indexNonLinearSystem=systemIndex), NONE()), _) equation
      sysIndexMap = List.fold(eqs, getSystemIndexMap, inSysIndexMap);
      sysIndexMap = arrayUpdate(sysIndexMap, index, systemIndex);
    then sysIndexMap;

    // dynamic tearing
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=index, indexLinearSystem=systemIndex), SOME(SimCode.LINEARSYSTEM(index=index2, indexLinearSystem=systemIndex2))), _) equation
      _ = arrayUpdate(inSysIndexMap, index, systemIndex);
      sysIndexMap = arrayUpdate(inSysIndexMap, index2, systemIndex2);
    then sysIndexMap;

    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=index, eqs=eqs, indexNonLinearSystem=systemIndex) , SOME(SimCode.NONLINEARSYSTEM(index=index2, eqs=eqs2, indexNonLinearSystem=systemIndex2))), _) equation
      sysIndexMap = List.fold(eqs, getSystemIndexMap, inSysIndexMap);
      sysIndexMap = arrayUpdate(sysIndexMap, index, systemIndex);
      sysIndexMap = List.fold(eqs2, getSystemIndexMap, inSysIndexMap);
      sysIndexMap = arrayUpdate(sysIndexMap, index2, systemIndex2);
    then sysIndexMap;

    case(SimCode.SES_MIXED(cont=cont, index=index, indexMixedSystem=systemIndex), _) equation
      getSystemIndexMap(cont, inSysIndexMap);
      sysIndexMap = arrayUpdate(inSysIndexMap, index, systemIndex);
    then sysIndexMap;

    else inSysIndexMap;
  end match;
end getSystemIndexMap;

protected function setSystemIndexMap "
  updates index of strong components systems"
  input SimCode.SimEqSystem inEqn;
  input array<Integer> inSysIndexMap;
  output SimCode.SimEqSystem outEqn;
algorithm
  outEqn := match(inEqn)
    local
      Integer index, sysIndex;
      SimCode.LinearSystem lSystem;
      SimCode.NonlinearSystem nlSystem;
      Option<SimCode.LinearSystem> alternativeTearingL;
      Option<SimCode.NonlinearSystem> alternativeTearingNL;
      SimCode.SimEqSystem simEq;
      SimCode.SimEqSystem cont;

    case (simEq as SimCode.SES_LINEAR(lSystem=lSystem, alternativeTearing=alternativeTearingL)) equation
      sysIndex = inSysIndexMap[lSystem.index];
      lSystem.indexLinearSystem = sysIndex;
      simEq.lSystem = lSystem;
      // dynamic tearing
      if isSome(alternativeTearingL) then
        lSystem = Util.getOption(alternativeTearingL);
        sysIndex = inSysIndexMap[lSystem.index];
        lSystem.indexLinearSystem = sysIndex;
        alternativeTearingL = SOME(lSystem);
        simEq.alternativeTearing = alternativeTearingL;
      end if;
    then simEq;

    case (simEq as SimCode.SES_NONLINEAR(nlSystem=nlSystem, alternativeTearing=alternativeTearingNL)) equation
      sysIndex = inSysIndexMap[nlSystem.index];
      nlSystem.indexNonLinearSystem = sysIndex;
      simEq.nlSystem = nlSystem;
      // dynamic tearing
      if isSome(alternativeTearingNL) then
        nlSystem = Util.getOption(alternativeTearingNL);
        sysIndex = inSysIndexMap[nlSystem.index];
        nlSystem.indexNonLinearSystem = sysIndex;
        alternativeTearingNL = SOME(nlSystem);
        simEq.alternativeTearing = alternativeTearingNL;
      end if;
    then simEq;

    case (simEq as SimCode.SES_MIXED(cont=cont)) equation
      sysIndex = inSysIndexMap[simEq.index];
      cont = setSystemIndexMap(cont, inSysIndexMap);
      simEq.cont = cont;
      simEq.indexMixedSystem = sysIndex;
    then simEq;

    else
    then inEqn;
  end match;
end setSystemIndexMap;

public function addAlgebraicLoopsModelInfo "
Adds algebraic loops from list of SimEqSystem into ModelInfo
and SimEqSystem equation algebraic system index."
  input output list<SimCode.SimEqSystem> eqns;
  input output SimCode.ModelInfo modelInfo;
  output list<SimCode.JacobianMatrix> symJacs = {};
protected
  list<SimCode.SimEqSystem> resEqns = {};
algorithm
  for eqn in eqns loop
    eqn := match(eqn)
      local
        SimCode.NonlinearSystem nlSyst, altNlSyst;
        Option<SimCode.NonlinearSystem> optNlSyst;
        SimCode.LinearSystem linearSyst, altLinearSyst;
        Option<SimCode.LinearSystem> optLinearSyst;
        SimCode.JacobianMatrix tmpSymJac;
        list<SimCode.JacobianMatrix> tmpSymJacs, tmpAdditionalSymJacs;
        list<SimCode.SimEqSystem> eqs;
        SimCode.SimEqSystem system;
        BackendDAE.EquationAttributes eqAttr;

      // nonlinear case
      case SimCode.SES_NONLINEAR(nlSystem=nlSyst as SimCode.NONLINEARSYSTEM(), alternativeTearing=optNlSyst, eqAttr=eqAttr) equation

        (nlSyst, modelInfo, symJacs) = updateNonLinearSyst(nlSyst, modelInfo, symJacs);

        // process the alternative system
        if isSome(optNlSyst) then
          altNlSyst = Util.getOption(optNlSyst);
          (altNlSyst, modelInfo, symJacs) = updateNonLinearSyst(altNlSyst, modelInfo, symJacs);
          optNlSyst = SOME(altNlSyst);
        end if;
        system = SimCode.SES_NONLINEAR(nlSyst, optNlSyst, eqAttr);
        modelInfo.nonLinearSystems = system::modelInfo.nonLinearSystems;
      then system;

      // linear case
      case SimCode.SES_LINEAR(lSystem=linearSyst as SimCode.LINEARSYSTEM(), alternativeTearing=optLinearSyst, eqAttr=eqAttr) equation

        (linearSyst, modelInfo, symJacs) = updateLinearSyst(linearSyst, modelInfo, symJacs);

        // process the alternative system
        if isSome(optLinearSyst) then
          altLinearSyst = Util.getOption(optLinearSyst);
          (altLinearSyst, modelInfo, symJacs) = updateLinearSyst(altLinearSyst, modelInfo, symJacs);
          optLinearSyst = SOME(altLinearSyst);
        end if;
        system = SimCode.SES_LINEAR(linearSyst, optLinearSyst, eqAttr);
        modelInfo.linearSystems = system::modelInfo.linearSystems;
      then system;

      else eqn;
    end match;
    resEqns := eqn::resEqns;
  end for;
  eqns := listReverse(resEqns);
end addAlgebraicLoopsModelInfo;

protected function updateNonLinearSyst
"Helper function of addAlgebraicLoopsModelInfo
 Updates nonlinear system indexes"
  input output SimCode.NonlinearSystem inSyst = inSyst;
  input output SimCode.ModelInfo modelInfo = modelInfo;
  input output list<SimCode.JacobianMatrix> allSymJacs = allSymJacs;
protected
  SimCode.VarInfo varInfo = modelInfo.varInfo;
  list<SimCode.SimEqSystem> eqs;
  SimCode.JacobianMatrix tmpSymJac;
  list<SimCode.JacobianMatrix> tmpSymJacs;
  constant Boolean debug = false;
algorithm

  // set system index and count
  inSyst.indexNonLinearSystem := varInfo.numNonLinearSystems;
  varInfo.numNonLinearSystems := varInfo.numNonLinearSystems+1;
  modelInfo.varInfo := varInfo;

  // collect the jacobian
  if isSome(inSyst.jacobianMatrix) then
    tmpSymJac := Util.getOption(inSyst.jacobianMatrix);
    // add only if the directional derivativ is available and
    // not just the sparsty pattern
    if not listEmpty(tmpSymJac.columns) then
      ({tmpSymJac}, modelInfo, tmpSymJacs) := addAlgebraicLoopsModelInfoSymJacs({tmpSymJac}, modelInfo);
      inSyst.jacobianMatrix := SOME(tmpSymJac);
      allSymJacs := listAppend(tmpSymJacs, allSymJacs);
      allSymJacs := tmpSymJac::allSymJacs;
    end if;
  end if;

  // proceed inSyst.eqs
  (eqs, modelInfo, tmpSymJacs) := addAlgebraicLoopsModelInfo(inSyst.eqs, modelInfo);
  inSyst.eqs := eqs;
  allSymJacs := listAppend(tmpSymJacs, allSymJacs);

  if debug then
    print("Update nonlinear system " + intString(inSyst.indexNonLinearSystem) +
          " collected Jacobians: " + intString(listLength(allSymJacs)) + "\n");
  end if;
end updateNonLinearSyst;

protected function updateLinearSyst
"Helper function of addAlgebraicLoopsModelInfo
 Updates linear system indexes"
  input output SimCode.LinearSystem inSyst = inSyst;
  input output SimCode.ModelInfo modelInfo = modelInfo;
  input output list<SimCode.JacobianMatrix> allSymJacs = allSymJacs;
protected
  SimCode.VarInfo varInfo = modelInfo.varInfo;
  list<SimCode.SimEqSystem> eqs;
  SimCode.JacobianMatrix tmpSymJac;
  list<SimCode.JacobianMatrix> tmpSymJacs;
  constant Boolean debug = false;
algorithm

  // set system index and count
  inSyst.indexLinearSystem := varInfo.numLinearSystems;
  varInfo.numLinearSystems := varInfo.numLinearSystems+1;
  modelInfo.varInfo := varInfo;

  // collect the jacobian
  if isSome(inSyst.jacobianMatrix) then
    tmpSymJac := Util.getOption(inSyst.jacobianMatrix);
    // add only if the directional derivativ is available and
    // not just the sparsty pattern
    if not listEmpty(tmpSymJac.columns) then
      ({tmpSymJac}, modelInfo, tmpSymJacs) := addAlgebraicLoopsModelInfoSymJacs({tmpSymJac}, modelInfo);
      inSyst.jacobianMatrix := SOME(tmpSymJac);
      allSymJacs := listAppend(tmpSymJacs, allSymJacs);
      allSymJacs := tmpSymJac::allSymJacs;
    end if;
  end if;

  // proceed inSyst.eqs
  (eqs, modelInfo, tmpSymJacs) := addAlgebraicLoopsModelInfo(inSyst.residual, modelInfo);
  inSyst.residual := eqs;
  allSymJacs := listAppend(tmpSymJacs, allSymJacs);

  if debug then
    print("Update linear system " + intString(inSyst.indexLinearSystem) +
          " collected Jacobians: " + intString(listLength(allSymJacs)) + "\n");
  end if;
end updateLinearSyst;

public function addAlgebraicLoopsModelInfoSymJacs "
Adds algebraic loops from list of SimEqSystem into ModelInfo
and SimEqSystem equation algebraic system index."
  input output list<SimCode.JacobianMatrix> symjacs;
  input output SimCode.ModelInfo modelInfo;
  output list<SimCode.JacobianMatrix> outSymJacsInSymJacs = {};
protected
  SimCode.JacobianColumn column;
  list<SimCode.SimEqSystem> eqs;
  SimCode.VarInfo varInfo;
  list<SimCode.JacobianMatrix> tmpSymJacs;
  list<SimCode.JacobianMatrix> outSymJacs = {};
  constant Boolean debug = false;
algorithm
  for symjac in symjacs loop
    varInfo := modelInfo.varInfo;
    symjac.jacobianIndex := varInfo.numJacobians;
    varInfo.numJacobians := varInfo.numJacobians + 1;
    modelInfo.varInfo := varInfo;
    if debug then
      print("Collect Jacobian " + symjac.matrixName + " and set index to: " + intString(symjac.jacobianIndex) + "\n");
    end if;
  try
    column::{} := symjac.columns;
    (eqs, modelInfo, tmpSymJacs) := addAlgebraicLoopsModelInfo(column.columnEqns, modelInfo);
    // set partition index to number of clocks (max index) for now.
    // TODO: use actual clock index to support multirate systems
    tmpSymJacs := list(rewriteJacPartIdx(a, modelInfo.nSubClocks) for a in tmpSymJacs);
    outSymJacsInSymJacs := listAppend(tmpSymJacs, outSymJacsInSymJacs);
    column.columnEqns := eqs;
    symjac.columns := {column};
    outSymJacs := symjac::outSymJacs;
  else
    outSymJacs := symjac::outSymJacs;
  end try;
  end for;
  symjacs := listReverse(outSymJacs);
  outSymJacsInSymJacs := listReverse(outSymJacsInSymJacs);
end addAlgebraicLoopsModelInfoSymJacs;

public function addAlgebraicLoopsModelInfoStateSets
" function to collect jacobians for statesets"
  input list<SimCode.StateSet> inSets;
  input SimCode.ModelInfo inModelInfo;
  output list<SimCode.StateSet> outSets = {};
  output SimCode.ModelInfo modelInfo = inModelInfo;
  output list<SimCode.JacobianMatrix> outSymJacs = {};
  output list<SimCode.JacobianMatrix> outSymJacsInternal = {};
protected
  SimCode.JacobianMatrix symJac;
  list<SimCode.JacobianMatrix> tmpSymJacs;
algorithm
  for set in inSets loop
    ({symJac}, modelInfo, tmpSymJacs) := addAlgebraicLoopsModelInfoSymJacs({set.jacobianMatrix}, modelInfo);
    outSymJacsInternal := listAppend(tmpSymJacs, outSymJacsInternal);
    set.jacobianMatrix := symJac;
    outSymJacs := symJac::outSymJacs;
    outSets := set::outSets;
  end for;
  outSets := listReverse(outSets);
  outSymJacs := listReverse(outSymJacs);
  outSymJacsInternal := listReverse(outSymJacsInternal);
end addAlgebraicLoopsModelInfoStateSets;

protected function addAlgebraicLoopsClockPartitions "
  function to process clockPartitions for symbolic jacobians"
  input list<SimCode.ClockedPartition> inColockPartition;
  input SimCode.ModelInfo inModelInfo;
  output list<SimCode.ClockedPartition> outColockPartition = {};
  output SimCode.ModelInfo modelInfo = inModelInfo;
  output list<SimCode.JacobianMatrix> outSymJacs = {};
protected
  SimCode.SubPartition subPartitionTmp;
  SimCode.ClockedPartition clockPartitionTmp;
  list<SimCode.SubPartition> subPartitionsTmp;
  list<SimCode.SimEqSystem> equations;
  list<SimCode.JacobianMatrix> tmpJacs;
  Integer clockIndex = 0;
algorithm
  for clockPartion in inColockPartition loop
    subPartitionsTmp := {};
    for subPartion in clockPartion.subPartitions loop
      clockIndex := clockIndex + 1;
      (equations, modelInfo, tmpJacs) := addAlgebraicLoopsModelInfo(subPartion.equations, modelInfo);
      tmpJacs := list(rewriteJacPartIdx(a,clockIndex) for a in tmpJacs);
      outSymJacs := listAppend(tmpJacs, outSymJacs);
      subPartitionTmp := SimCode.SUBPARTITION(
        subPartion.vars,
        equations,
        subPartion.removedEquations,
        subPartion.subClock,
        subPartion.holdEvents);
      subPartitionsTmp := subPartitionTmp::subPartitionsTmp;
    end for;
    clockPartitionTmp := SimCode.CLOCKED_PARTITION(clockPartion.baseClock, listReverse(subPartitionsTmp));
    outColockPartition := clockPartitionTmp::outColockPartition;
  end for;
  outColockPartition := listReverse(outColockPartition);
end addAlgebraicLoopsClockPartitions;

protected function rewriteJacPartIdx
  input SimCode.JacobianMatrix inJac;
  input Integer index;
  output SimCode.JacobianMatrix outJac = inJac;
algorithm
  outJac.partitionIndex := index;
end rewriteJacPartIdx;

// =============================================================================
// section to create SimCode.Equations from BackendDAE.Equation
//
// =============================================================================


protected type CreateEquationsForSystemsFold =
tuple<Integer /*uniqueEqIndex*/,
      list<list<SimCode.SimEqSystem>> /*odeEquations*/,
      list<list<SimCode.SimEqSystem>> /*algebraicEquations*/,
      list<SimCode.SimEqSystem> /*allEquations*/,
      list<SimCode.SimEqSystem> /*equationsForZeroCrossings*/,
      list<SimCodeVar.SimVar> /*tempvars*/,
      list<tuple<Integer,Integer>> /*eqSccMapping*/,
      list<tuple<Integer,Integer>> /*eqBackendSimCodeMapping*/,
      SimCode.BackendMapping  /*backendSimCodeMapping*/,
      Integer  /*sccOffset*/>;
protected type CreateEquationsForSystemsArg = tuple<BackendDAE.Shared, list<BackendDAE.ZeroCrossing>, Boolean>;

protected function createEquationsForSystems "Some kind of comments would be very helpful!"
  input BackendDAE.EqSystems inSysts;
  input BackendDAE.Shared shared;
  input Integer iuniqueEqIndex;
  input list<BackendDAE.ZeroCrossing> inAllZeroCrossings;
  input list<SimCodeVar.SimVar> itempvars;
  input Integer iSccOffset; //to map the generated equations to the old strongcomponents, they are numbered from (1+offset) to (n+offset)
  input SimCode.BackendMapping iBackendMapping;
  input Boolean createAlgebraicEquations;
  output Integer ouniqueEqIndex;
  output list<list<SimCode.SimEqSystem>> oodeEquations;
  output list<list<SimCode.SimEqSystem>> oalgebraicEquations;
  output list<SimCode.SimEqSystem> olocalKnownVars;
  output list<SimCode.SimEqSystem> oallEquations;
  output list<SimCode.SimEqSystem> oequationsForZeroCrossings;
  output list<SimCodeVar.SimVar> otempvars;
  output list<tuple<Integer,Integer>> oeqSccMapping;
  output list<tuple<Integer,Integer>> oeqBackendSimCodeMapping;
  output SimCode.BackendMapping obackendMapping;
  output Integer oSccOffset;
protected
  CreateEquationsForSystemsFold foldArg;
  CreateEquationsForSystemsArg arg;
algorithm
  try
    arg := (shared, inAllZeroCrossings, createAlgebraicEquations);
    foldArg := (iuniqueEqIndex, {}, {}, {}, {}, itempvars, {}, {}, iBackendMapping, iSccOffset);
    (ouniqueEqIndex, oodeEquations, oalgebraicEquations, oallEquations, oequationsForZeroCrossings, otempvars,
    oeqSccMapping, oeqBackendSimCodeMapping, obackendMapping, oSccOffset) := List.fold1(inSysts, createEquationsForSystems1, arg, foldArg);
    oequationsForZeroCrossings := Dangerous.listReverseInPlace(oequationsForZeroCrossings);
    ((ouniqueEqIndex, olocalKnownVars)) := BackendVariable.traverseBackendDAEVars(shared.localKnownVars, traverseKnVarsToSimEqSystem, (ouniqueEqIndex, {}));
  else
    Error.addInternalError("createEquationsForSystems failed", sourceInfo());
    fail();
  end try;
end createEquationsForSystems;

protected function createEquationsForSystems1
  input BackendDAE.EqSystem inSyst;
  input CreateEquationsForSystemsArg inArg;
  input CreateEquationsForSystemsFold inFold;
  output CreateEquationsForSystemsFold outFold;
algorithm
  outFold := match inSyst.matching
    local
      list<SimCode.SimEqSystem> odeEquations1, algebraicEquations1, allEquations1;
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      list<list<SimCode.SimEqSystem>> odeEquations, algebraicEquations;
      list<SimCode.SimEqSystem> allEquations;
      list<SimCode.SimEqSystem> equationsForZeroCrossings, equationsForZeroCrossings1;
      Integer uniqueEqIndex, sccOffset;
      array<Integer> ass1, stateeqnsmark, zceqnsmarks;
      BackendDAE.Variables vars;
      list<SimCodeVar.SimVar> tempvars;
      DAE.FunctionTree funcs;
      list<tuple<Integer,Integer>> eqSccMapping, eqBackendSimCodeMapping;
      SimCode.BackendMapping backendMapping;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      BackendDAE.Shared shared;
      Boolean createAlgebraicEquations;
    case BackendDAE.MATCHING(ass1=ass1, comps=comps)
      equation
        if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
          BackendDump.dumpEqSystemBLTmatrixHTML(inSyst);
        end if;

        (shared, zeroCrossings, createAlgebraicEquations) = inArg;
        (uniqueEqIndex, odeEquations, algebraicEquations, allEquations, equationsForZeroCrossings, tempvars,
         eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccOffset) = inFold;

        funcs = BackendDAEUtil.getFunctions(shared);
        (syst, _, _) = BackendDAEUtil.getIncidenceMatrixfromOption(inSyst, BackendDAE.ABSOLUTE(), SOME(funcs));

        stateeqnsmark = arrayCreate(BackendDAEUtil.equationArraySizeDAE(syst), 0);
        zceqnsmarks = arrayCreate(BackendDAEUtil.equationArraySizeDAE(syst), 0);
        stateeqnsmark = BackendDAEUtil.markStateEquations(syst, stateeqnsmark, ass1);
        zceqnsmarks = BackendDAEUtil.markZeroCrossingEquations(syst, zeroCrossings, zceqnsmarks, ass1);

        (odeEquations1, algebraicEquations1, allEquations1, equationsForZeroCrossings1, uniqueEqIndex,
         tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping) =
            createEquationsForSystem(
                stateeqnsmark, zceqnsmarks, syst, shared, comps, uniqueEqIndex, tempvars,
                sccOffset, eqSccMapping, eqBackendSimCodeMapping, backendMapping,createAlgebraicEquations);
        GC.free(stateeqnsmark);
        GC.free(zceqnsmarks);

        odeEquations = List.consOnTrue(not listEmpty(odeEquations1), odeEquations1, odeEquations);
        algebraicEquations = List.consOnTrue(not listEmpty(algebraicEquations1), algebraicEquations1, algebraicEquations);
        allEquations = List.append_reverse(allEquations1, allEquations);
        equationsForZeroCrossings = List.append_reverse(equationsForZeroCrossings1, equationsForZeroCrossings);

      then ( uniqueEqIndex, odeEquations, algebraicEquations, allEquations, equationsForZeroCrossings, tempvars,
             eqSccMapping, eqBackendSimCodeMapping, backendMapping, listLength(comps) + sccOffset );

    else inFold;
  end match;
end createEquationsForSystems1;

protected type CreateEquationsForSystemFold =
tuple<Integer /*uniqueEqIndex*/,
      list<list<SimCode.SimEqSystem>> /*odeEquations*/,
      list<list<SimCode.SimEqSystem>> /*algebraicEquations*/,
      list<list<SimCode.SimEqSystem>> /*allEquations*/,
      list<list<SimCode.SimEqSystem>> /*equationsForZeroCrossings*/,
      list<SimCodeVar.SimVar> /*tempvars*/,
      list<tuple<Integer,Integer>> /*eqSccMapping*/,
      list<tuple<Integer,Integer>> /*eqBackendSimCodeMapping*/,
      SimCode.BackendMapping /*backendSimCodeMapping*/,
      Integer /*sccOffset*/>;
protected type CreateEquationsForSystemArg =
tuple<array<Integer> /*stateeqnsmark*/, array<Integer> /*zceqnsmark*/,
      BackendDAE.EqSystem /*syst*/, BackendDAE.Shared /*shared*/, Boolean>;

protected function createEquationsForSystem
  input array<Integer> stateeqnsmark;
  input array<Integer> zceqnsmark;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.StrongComponents comps;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input Integer iSccIndex;
  input list<tuple<Integer,Integer>> ieqSccMapping;
  input list<tuple<Integer,Integer>> ieqBackendSimCodeMapping;
  input SimCode.BackendMapping iBackendMapping;
  input Boolean createAlgebraicEquations;
  output list<SimCode.SimEqSystem> outOdeEquations;
  output list<SimCode.SimEqSystem> outAlgebraicEquations;
  output list<SimCode.SimEqSystem> outAllEquations;
  output list<SimCode.SimEqSystem> outEquationsforZeroCrossings;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
  output list<tuple<Integer,Integer>> oeqSccMapping;
  output list<tuple<Integer,Integer>> oeqBackendSimCodeMapping;
  output SimCode.BackendMapping oBackendMapping;
protected
  CreateEquationsForSystemFold foldArg;
  CreateEquationsForSystemArg arg;
  list<list<SimCode.SimEqSystem>> odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings;
algorithm
  arg := (stateeqnsmark, zceqnsmark, syst, shared, createAlgebraicEquations);
  foldArg := (iuniqueEqIndex, {}, {}, {}, {}, itempvars, ieqSccMapping, ieqBackendSimCodeMapping, iBackendMapping, iSccIndex);
  foldArg := List.fold1(comps, createEquationsForSystem1, arg, foldArg);
  (ouniqueEqIndex, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
   otempvars, oeqSccMapping, oeqBackendSimCodeMapping, oBackendMapping, _) := foldArg;
  outOdeEquations := List.flattenReverse(odeEquations);
  outAlgebraicEquations := List.flattenReverse(algebraicEquations);
  outAllEquations := List.flattenReverse(allEquations);
  outEquationsforZeroCrossings := List.flattenReverse(equationsforZeroCrossings);
end createEquationsForSystem;

protected function addEquationsToLists
  input list<SimCode.SimEqSystem> inEq;
  input array<Integer> stateeqnsmark;
  input array<Integer> zceqnsmark;
  input list<Integer> eqsIdx;
  input list<list<SimCode.SimEqSystem>> inOdeEquations;
  input list<list<SimCode.SimEqSystem>> inAlgebraicEquations;
  input list<list<SimCode.SimEqSystem>> inAllEquations;
  input list<list<SimCode.SimEqSystem>> inEquationsforZeroCrossings;
  output list<list<SimCode.SimEqSystem>> outOdeEquations;
  output list<list<SimCode.SimEqSystem>> outAlgebraicEquations;
  output list<list<SimCode.SimEqSystem>> outAllEquations;
  output list<list<SimCode.SimEqSystem>> outEquationsforZeroCrossings;
protected
  Boolean bdynamic "block is dynamic, belongs to dynamic section";
  Boolean bzceqns "block needs to evaluate zeroCrossings";
algorithm
  bdynamic := BackendDAEUtil.blockIsDynamic(eqsIdx, stateeqnsmark);
  bzceqns := BackendDAEUtil.blockIsDynamic(eqsIdx, zceqnsmark);
  outOdeEquations := if bdynamic then inEq::inOdeEquations else inOdeEquations;
  outAlgebraicEquations := if not bdynamic then inEq::inAlgebraicEquations else inAlgebraicEquations;
  outAllEquations := inEq::inAllEquations;
  outEquationsforZeroCrossings := if bzceqns then inEq::inEquationsforZeroCrossings else inEquationsforZeroCrossings;
end addEquationsToLists;

protected function createEquationsForSystem1
  input BackendDAE.StrongComponent comp;
  input CreateEquationsForSystemArg inArg;
  input CreateEquationsForSystemFold inFold;
  output CreateEquationsForSystemFold outFold;
protected
  array<Integer> stateeqnsmark;
  array<Integer> zceqnsmark;
  BackendDAE.EqSystem syst;
  BackendDAE.Shared shared;
  Integer uniqueEqIndex, sccIndex;
  list<SimCodeVar.SimVar> tempvars;
  list<tuple<Integer,Integer>> eqSccMapping, eqBackendSimCodeMapping;
  SimCode.BackendMapping backendMapping;
  list<list<SimCode.SimEqSystem>> odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings;
  list<Integer> eqsIdx,varIdx;
  list<BackendDAE.Var> varlst;
  list<BackendDAE.Equation> eqnlst;
  Boolean createAlgebraicEquations, bdynamic, skip;
  Boolean debug = false;
algorithm
  (stateeqnsmark, zceqnsmark, syst, shared, createAlgebraicEquations) := inArg;
  (uniqueEqIndex, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
  tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex) := inFold;
  (varlst,varIdx,eqnlst,eqsIdx) := BackendDAEUtil.getStrongComponentVarsAndEquations(comp, syst.orderedVars, syst.orderedEqs);
  bdynamic := BackendDAEUtil.blockIsDynamic(eqsIdx, stateeqnsmark);

  skip := false;

  if debug then
    print("Proceed component: " + BackendDump.strongComponentString(comp) + "\n");
    BackendDump.dumpEquationList(eqnlst,"Equations:");
    BackendDump.dumpVarList(varlst,"Variables:");
  end if;
  // skip is when equations
  skip := List.mapBoolAnd(eqnlst, BackendEquation.isWhenEquation);
  // skip is discrete
  skip := skip or List.mapBoolAnd(varlst, BackendVariable.isVarDiscrete);

  outFold := match comp
    local
      Integer e, index, vindex, firstEqIndex, uniqueEqIndex1;
      BackendDAE.Var v;
      BackendDAE.Equation eqn;
      SimCode.SimEqSystem firstSES;

      list<Integer> eqnslst;
      list<SimCode.SimEqSystem> equations1, noDiscEquations1;
      String message;

    case _ guard not (createAlgebraicEquations or bdynamic) or skip and not createAlgebraicEquations
    then (uniqueEqIndex, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
            tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex);

    case BackendDAE.SINGLEEQUATION(eqn=index, var=vindex)
      equation
        (equations1, uniqueEqIndex1, tempvars) = createEquation(index, vindex, syst, shared, false, uniqueEqIndex, tempvars, {});
        if not listEmpty(equations1) then
          firstSES = listHead(equations1);  // check if the all equations occur with this index in the c file
          firstEqIndex = if isSimEqSys(firstSES) then uniqueEqIndex1-1 else uniqueEqIndex;
          eqSccMapping = appendSccIdxRange(firstEqIndex, uniqueEqIndex1 - 1, sccIndex, eqSccMapping);
          eqBackendSimCodeMapping = appendSccIdxRange(firstEqIndex, uniqueEqIndex1 - 1, index, eqBackendSimCodeMapping);
          backendMapping = setEqMapping(List.intRange2(firstEqIndex, uniqueEqIndex1 - 1), {index}, backendMapping);
        end if;
        if BackendEquation.isWhenEquation(BackendEquation.get(syst.orderedEqs, index)) then
          allEquations = equations1::allEquations;
        else
          (odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings) =
              addEquationsToLists(equations1, stateeqnsmark, zceqnsmark, {index}, odeEquations,
                             algebraicEquations, allEquations, equationsforZeroCrossings);
        end if;
      then (uniqueEqIndex1, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
            tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex + 1);

    // A single array equation
    case BackendDAE.SINGLEARRAY(eqn=e)
      equation
        (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, syst.orderedEqs, syst.orderedVars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1,_, uniqueEqIndex1, tempvars) = createSingleArrayEqnCode(true, eqnlst, varlst, uniqueEqIndex, tempvars, shared);

        eqSccMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, sccIndex, eqSccMapping);
        eqBackendSimCodeMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, e, eqBackendSimCodeMapping);

        (odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings) =
            addEquationsToLists(equations1, stateeqnsmark, zceqnsmark, {e}, odeEquations,
                           algebraicEquations, allEquations, equationsforZeroCrossings);
      then
        (uniqueEqIndex1, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
         tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex + 1);

    // A single algorithm section for several variables.
    case BackendDAE.SINGLEALGORITHM(eqn=e)
      equation
        (eqnlst, varlst, _) = BackendDAETransform.getEquationAndSolvedVar(comp, syst.orderedEqs, syst.orderedVars);
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, uniqueEqIndex1) = createSingleAlgorithmCode(eqnlst, varlst, false, uniqueEqIndex);

        eqSccMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, sccIndex, eqSccMapping);
        eqBackendSimCodeMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, e, eqBackendSimCodeMapping);

        (odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings) =
            addEquationsToLists(equations1, stateeqnsmark, zceqnsmark, {e}, odeEquations,
                           algebraicEquations, allEquations, equationsforZeroCrossings);
      then
        (uniqueEqIndex1, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
         tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex + 1);

    // A single complex equation
    case BackendDAE.SINGLECOMPLEXEQUATION(eqn=e)
      equation
        (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, syst.orderedEqs, syst.orderedVars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, uniqueEqIndex1, tempvars) = createSingleComplexEqnCode(listHead(eqnlst), varlst, uniqueEqIndex, tempvars, shared.info, true, shared.functionTree);

        eqSccMapping = appendSccIdx(uniqueEqIndex1-1, sccIndex, eqSccMapping);
        eqBackendSimCodeMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, e, eqBackendSimCodeMapping);

        (odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings) =
            addEquationsToLists(equations1, stateeqnsmark, zceqnsmark, {e}, odeEquations,
                           algebraicEquations, allEquations, equationsforZeroCrossings);
      then
        (uniqueEqIndex1, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
         tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex + 1);

    // A single when equation
    case BackendDAE.SINGLEWHENEQUATION()
      equation
        (eqnlst, varlst, index) = BackendDAETransform.getEquationAndSolvedVar(comp, syst.orderedEqs, syst.orderedVars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, uniqueEqIndex1, tempvars) = createSingleWhenEqnCode(listHead(eqnlst), varlst, shared, uniqueEqIndex, tempvars);

        eqSccMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, sccIndex, eqSccMapping);
        eqBackendSimCodeMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, index, eqBackendSimCodeMapping);

        allEquations = equations1::allEquations;
      then
        (uniqueEqIndex1, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
         tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex + 1);

    // A single if equation
    case BackendDAE.SINGLEIFEQUATION(eqn=e)
      equation

        (eqnlst, varlst, index) = BackendDAETransform.getEquationAndSolvedVar(comp, syst.orderedEqs, syst.orderedVars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, uniqueEqIndex1, tempvars) = createSingleIfEqnCode(listHead(eqnlst), varlst, shared, true, uniqueEqIndex, tempvars);

        eqSccMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, sccIndex, eqSccMapping);
        eqBackendSimCodeMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, index, eqBackendSimCodeMapping);

        (odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings) =
            addEquationsToLists(equations1, stateeqnsmark, zceqnsmark, {e}, odeEquations,
                           algebraicEquations, allEquations, equationsforZeroCrossings);
      then
        (uniqueEqIndex1, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings,
         tempvars, eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex + 1);

    // EQUATIONSYSTEM size 1 -> single equation
    case BackendDAE.EQUATIONSYSTEM(eqns={index}, vars={vindex})
      equation
        (equations1, uniqueEqIndex1, tempvars) = createEquation(index, vindex, syst, shared, false, uniqueEqIndex, tempvars, {});
        if not listEmpty(equations1) then
          firstSES = listHead(equations1);  // check if the all equations occur with this index in the c file
          firstEqIndex = if isSimEqSys(firstSES) then uniqueEqIndex1-1 else uniqueEqIndex;
          eqSccMapping = appendSccIdxRange(firstEqIndex, uniqueEqIndex1 - 1, sccIndex, eqSccMapping);
          eqBackendSimCodeMapping = appendSccIdxRange(firstEqIndex, uniqueEqIndex1 - 1, index, eqBackendSimCodeMapping);
          backendMapping = setEqMapping(List.intRange2(firstEqIndex, uniqueEqIndex1 - 1),{index}, backendMapping);
        end if;
        if BackendEquation.isWhenEquation(BackendEquation.get(syst.orderedEqs, index)) then
          allEquations = equations1::allEquations;
        else
          (odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings) =
              addEquationsToLists(equations1, stateeqnsmark, zceqnsmark, {index}, odeEquations,
                             algebraicEquations, allEquations, equationsforZeroCrossings);
        end if;
      then
        (uniqueEqIndex1, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings, tempvars,
         eqSccMapping, eqBackendSimCodeMapping,backendMapping, sccIndex + 1);

    // a system of equations
    case _
      equation
        // block is dynamic, belong in dynamic section
        (eqnslst, _) = BackendDAETransform.getEquationAndSolvedVarIndxes(comp);

        (_, noDiscEquations1, uniqueEqIndex1, tempvars, eqSccMapping, backendMapping) =
          createOdeSystem(true and createAlgebraicEquations, false, syst, shared, comp, uniqueEqIndex, tempvars, sccIndex, eqSccMapping, backendMapping);
        //eqSccMapping = appendSccIdxRange(uniqueEqIndex, uniqueEqIndex1 - 1, sccIndex, eqSccMapping);

        (odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings) =
            addEquationsToLists(noDiscEquations1, stateeqnsmark, zceqnsmark, eqnslst, odeEquations,
                           algebraicEquations, allEquations, equationsforZeroCrossings);
      then
        (uniqueEqIndex1, odeEquations, algebraicEquations, allEquations, equationsforZeroCrossings, tempvars,
         eqSccMapping, eqBackendSimCodeMapping, backendMapping, sccIndex + 1);

    // detailed error message
    else
      equation
        message = "function createEquationsForSystem1 failed for component " + BackendDump.strongComponentString(comp);
        Error.addInternalError(message, sourceInfo());
      then fail();
  end match;
end createEquationsForSystem1;

protected function appendSccIdx
  input Integer iCurrentIdx;
  input Integer iSccIdx;
  input list<tuple<Integer,Integer>> iSccIdc;
  output list<tuple<Integer,Integer>> oSccIdc;
algorithm
  oSccIdc := ((iCurrentIdx,iSccIdx))::iSccIdc;
end appendSccIdx;

protected function appendSccIdxRange
  input Integer iCurrentIdxStart;
  input Integer iCurrentIdxStop;
  input Integer iSccIdx;
  input list<tuple<Integer,Integer>> iSccIdc;
  output list<tuple<Integer,Integer>> oSccIdc = iSccIdc;
algorithm
    for i in iCurrentIdxStop:-1:iCurrentIdxStart loop
      oSccIdc := ((i,iSccIdx))::iSccIdc;
    end for;
end appendSccIdxRange;

protected function createEquations
  input Boolean includeWhen;
  input Boolean skipDiscInZc;
  input Boolean genDiscrete;
  input Boolean skipDiscInAlgorithm;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.StrongComponents comps;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations;
  output list<SimCode.SimEqSystem> noDiscEquations;
  output Integer ouniqueEqIndex = iuniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars = itempvars;
protected
  list<list<SimCode.SimEqSystem>> accEquations = {};
  list<list<SimCode.SimEqSystem>> accNoDiscEquations = {};
algorithm
  for comp in comps loop
    (equations, noDiscEquations, ouniqueEqIndex, otempvars) := createEquationsWork(includeWhen, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, syst, shared, comp, ouniqueEqIndex, otempvars, {});
    accEquations := equations::accEquations;
    accNoDiscEquations := noDiscEquations::accNoDiscEquations;
  end for;
  equations := List.flattenReverse(accEquations);
  noDiscEquations := List.flattenReverse(accNoDiscEquations);
end createEquations;

protected function createEquationsWork
  input Boolean includeWhen;
  input Boolean skipDiscInZc;
  input Boolean genDiscrete;
  input Boolean skipDiscInAlgorithm;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input BackendDAE.StrongComponent comp;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input BackendDAE.Constraints cons;
  output list<SimCode.SimEqSystem> equations;
  output list<SimCode.SimEqSystem> noDiscEquations;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (equations, noDiscEquations, ouniqueEqIndex, otempvars) := match(includeWhen, skipDiscInZc, genDiscrete, syst, shared, comp)
    local
      Integer index, vindex, uniqueEqIndex;
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      list<BackendDAE.Equation> eqnlst;
      list<BackendDAE.Var> varlst;
      list<SimCode.SimEqSystem> equations1, noDiscEquations1;
      list<SimCodeVar.SimVar> tempvars;
      BackendDAE.ExtraInfo ei;

      // ignore when equations if we should not generate them
    case (false, _, _, BackendDAE.EQSYSTEM(orderedEqs=eqns), _, BackendDAE.SINGLEEQUATION(eqn=index))
      guard(BackendEquation.isWhenEquation(BackendEquation.get(eqns, index)))
     then ({}, {}, iuniqueEqIndex, itempvars);

    case (false, _, _, BackendDAE.EQSYSTEM(), _, BackendDAE.SINGLEWHENEQUATION())
      then ({}, {}, iuniqueEqIndex, itempvars);

        // ignore discrete if we should not generate them
    case (_, _, false, BackendDAE.EQSYSTEM(orderedVars=vars), _, BackendDAE.SINGLEEQUATION(var=index))
      guard(BackendVariable.isVarDiscrete(BackendVariable.getVarAt(vars, index)))
     then ({}, {}, iuniqueEqIndex, itempvars);

    case (_, _, false, BackendDAE.EQSYSTEM(), _, BackendDAE.SINGLEWHENEQUATION())
      then ({}, {}, iuniqueEqIndex, itempvars);

        // ignore discrete in zero crossing if we should not generate them
    case (_, true, _, BackendDAE.EQSYSTEM(orderedVars=vars), _, BackendDAE.SINGLEEQUATION(eqn=index, var=vindex))
      guard(BackendVariable.isVarDiscrete(BackendVariable.getVarAt(vars, vindex)) and listMember(index, zeroCrossingsEquations(syst, shared)))
     then ({}, {}, iuniqueEqIndex, itempvars);

        // single equation
    case (_, _, _, _, _, BackendDAE.SINGLEEQUATION(eqn=index, var=vindex))
      equation
        if (Flags.isSet(Flags.TEARING_DUMP) or Flags.isSet(Flags.TEARING_DUMPVERBOSE)) and not listEmpty(cons) then
          print("Single Equation with constraint:\n" + BackendDump.equationString(BackendEquation.get(syst.orderedEqs, index)) + "\n");
          print("Constraints:" + ExpressionDump.constraintDTlistToString(cons,"\n") + "\n\n");
        end if;
        (equations1, uniqueEqIndex, tempvars) = createEquation(index, vindex, syst, shared, skipDiscInAlgorithm, iuniqueEqIndex, itempvars, cons);
      then (equations1, equations1, uniqueEqIndex, tempvars);

      // A single array equation
    case (_, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _, BackendDAE.SINGLEARRAY())
      equation
        (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, eqns, vars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, noDiscEquations1, uniqueEqIndex, tempvars) = createSingleArrayEqnCode(genDiscrete, eqnlst, varlst, iuniqueEqIndex, itempvars, shared);
      then (equations1, noDiscEquations1, uniqueEqIndex, tempvars);

        // A single algorithm section for several variables.
    case (_, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _, BackendDAE.SINGLEALGORITHM())
      equation
        (eqnlst, varlst, _) = BackendDAETransform.getEquationAndSolvedVar(comp, eqns, vars);
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, uniqueEqIndex) = createSingleAlgorithmCode(eqnlst, varlst, skipDiscInAlgorithm, iuniqueEqIndex);
      then (equations1, equations1, uniqueEqIndex, itempvars);

      // A single complex equation
    case (_, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), BackendDAE.SHARED(info = ei), BackendDAE.SINGLECOMPLEXEQUATION())
      equation
        (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, eqns, vars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, uniqueEqIndex, tempvars) = createSingleComplexEqnCode(listHead(eqnlst), varlst, iuniqueEqIndex, itempvars, ei, genDiscrete, shared.functionTree);
      then (equations1, equations1, uniqueEqIndex, tempvars);

    // A single when equation
    case (_, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _, BackendDAE.SINGLEWHENEQUATION())
      equation
        (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, eqns, vars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, uniqueEqIndex, tempvars) = createSingleWhenEqnCode(listHead(eqnlst), varlst, shared, iuniqueEqIndex, itempvars);
      then (equations1, equations1, uniqueEqIndex, tempvars);

    // A single if equation
    case (_, _, _, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _, BackendDAE.SINGLEIFEQUATION())
      equation
        (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, eqns, vars);
        // States are solved for der(x) not x.
        varlst = List.map(varlst, BackendVariable.transformXToXd);
        (equations1, uniqueEqIndex, tempvars) = createSingleIfEqnCode(listHead(eqnlst), varlst, shared, genDiscrete, iuniqueEqIndex, itempvars);
      then (equations1, equations1, uniqueEqIndex, tempvars);

    // a system of equations
    case (_, _, _, _, _, _)
      equation
        (equations1, noDiscEquations1, uniqueEqIndex, tempvars, _, _) = createOdeSystem(genDiscrete, skipDiscInAlgorithm, syst, shared, comp, iuniqueEqIndex, itempvars, 1, {}, SimCode.NO_MAPPING());
      then (equations1, noDiscEquations1, uniqueEqIndex, tempvars);

    // failure
    else
      equation
        Error.addInternalError("createEquation failed", sourceInfo());
     then fail();
  end match;
end createEquationsWork;

public function getSimCodeDAEModeDataEqns
  input Option<SimCode.DaeModeData> inOptDaeMode;
  output list<list<SimCode.SimEqSystem>> daeEquations;
protected
  SimCode.DaeModeData daeModeData;
algorithm
  if isSome(inOptDaeMode) then
    daeModeData := Util.getOption(inOptDaeMode);
    daeEquations := daeModeData.daeEquations;
  else
    daeEquations := {};
  end if;
end getSimCodeDAEModeDataEqns;

public function sortSimVarsAndWriteIndex
  input list<SimCodeVar.SimVar> inSimVar;
  input SimCode.HashTableCrefToSimVar crefToSimVarHT;
  output list<SimCodeVar.SimVar> outSimVar;
protected
  list<DAE.ComponentRef> crefs;
  list<SimCodeVar.SimVar> sorted;
algorithm
  crefs := List.map(inSimVar, getSimVarCompRef);
  sorted := getSimVars2Crefs(crefs, crefToSimVarHT);
  sorted := List.sort(sorted, compareVarIndexGt);
  outSimVar := rewriteIndex(sorted, 0);
end sortSimVarsAndWriteIndex;

// =============================================================================
// section for zeroCrossingsEquations
//
// =============================================================================

protected function zeroCrossingsEquations "
  Returns a list of all equations (by their index) that contain a zero crossing
  Used e.g. to find out which discrete equations are not part of a zero crossing"
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output list<Integer> eqns;
protected
  BackendDAE.ZeroCrossingSet zeroCrossingLst;
  list<list<Integer>> zcEqns;
  list<Integer> wcEqns;
  BackendDAE.EquationArray orderedEqs;
algorithm
  BackendDAE.EQSYSTEM(orderedEqs=orderedEqs) := syst;
  BackendDAE.SHARED(eventInfo=BackendDAE.EVENT_INFO(zeroCrossings=zeroCrossingLst)) := shared;
  zcEqns := List.map(ZeroCrossings.toList(zeroCrossingLst), zeroCrossingEquations);
  wcEqns := whenEquationsIndices(orderedEqs);
  eqns := List.unionList(listAppend(zcEqns, {wcEqns}));
end zeroCrossingsEquations;

protected function zeroCrossingEquations "
  Returns the list of equations (indices) from a ZeroCrossing"
  input BackendDAE.ZeroCrossing inZC;
  output list<Integer> outLst;
algorithm
  BackendDAE.ZERO_CROSSING(_, outLst) := inZC;
end zeroCrossingEquations;

protected function whenEquationsIndices "
  Returns all equation-indices that contain a when clause"
  input BackendDAE.EquationArray eqns;
  output list<Integer> res;
protected
  Boolean b;
  Integer i = 1;
  Integer size;
algorithm
  size := BackendEquation.getNumberOfEquations(eqns);
  res := {};
  while i <= size loop
    b:= match BackendEquation.get(eqns, i)
      case BackendDAE.WHEN_EQUATION() then true;
      else false;
    end match;
    res := if b then i::res else res;
    i := i+1;
  end while;
end whenEquationsIndices;

protected function updateZeroCrossEqnIndex
  input list<BackendDAE.ZeroCrossing> izeroCrossings;
  input list<tuple<Integer, Integer>> eqBackendSimCodeMapping;
  input Integer numEqnsinArray;
  output list<BackendDAE.ZeroCrossing> ozeroCrossings;
protected
  array<Integer> mappingArray;
algorithm
  mappingArray := convertListMappingToArray(eqBackendSimCodeMapping, numEqnsinArray);
  ozeroCrossings := updateZeroCrossEqnIndexHelp(izeroCrossings, mappingArray, {});
end updateZeroCrossEqnIndex;

protected function updateZeroCrossEqnIndexHelp
  input list<BackendDAE.ZeroCrossing> izeroCrossings;
  input array<Integer> eqBackendSimCodeMappingArray;
  input list<BackendDAE.ZeroCrossing> iAccum;
  output list<BackendDAE.ZeroCrossing> ozeroCrossings;
algorithm
 ozeroCrossings := match(izeroCrossings, eqBackendSimCodeMappingArray, iAccum)
 local
    DAE.Exp exp;
    list<Integer> occurEquLst;
    list<BackendDAE.ZeroCrossing> rest;

   case ({}, _, _) then Dangerous.listReverseInPlace(iAccum);

   case (BackendDAE.ZERO_CROSSING(relation_=exp, occurEquLst=occurEquLst)::rest, _, _)
     equation
       occurEquLst = convertListIndx(occurEquLst, eqBackendSimCodeMappingArray);
       ozeroCrossings = updateZeroCrossEqnIndexHelp(rest, eqBackendSimCodeMappingArray, BackendDAE.ZERO_CROSSING(exp, occurEquLst)::iAccum);
     then
       ozeroCrossings;

  end match;
end updateZeroCrossEqnIndexHelp;

protected function convertListMappingToArray
  input list<tuple<Integer,Integer>> iMapping; //<simEqIdx,BackendEqnIndx>
  input Integer numOfBackendEqs;
  output array<Integer> outMapping;
algorithm
  outMapping := arrayCreate(numOfBackendEqs, -1);
  outMapping := List.fold(iMapping, convertListMappingToArray1, outMapping);
end convertListMappingToArray;

protected function convertListMappingToArray1
  input tuple<Integer,Integer> iMapping; //<simEqIdx,BackendEqnIndx>
  input array<Integer> iMappingArray;
  output array<Integer> outMappingArray;
protected
  Integer simEqIdx,BackendEqnIdx;
algorithm
  (simEqIdx,BackendEqnIdx) := iMapping;
  outMappingArray := arrayUpdate(iMappingArray,BackendEqnIdx,simEqIdx);
end convertListMappingToArray1;

protected function convertListIndx
  input list<Integer> iIntList;
  input array<Integer> iMappingArray;
  output list<Integer> oIntList;
algorithm
  oIntList := List.map1r(iIntList, arrayGet, iMappingArray);
end convertListIndx;

protected function addAssertEqn
  input list<DAE.Statement> asserts;
  input list<SimCode.SimEqSystem> iequations;
  input Integer iuniqueEqIndex;
  output list<SimCode.SimEqSystem> oequations;
  output Integer ouniqueEqIndex;
algorithm
  (oequations, ouniqueEqIndex) := match(asserts)
    case {}
    then (iequations, iuniqueEqIndex);

    else
    then (SimCode.SES_ALGORITHM(iuniqueEqIndex, asserts, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)::iequations, iuniqueEqIndex+1);
  end match;
end addAssertEqn;

protected function createEquation
  input Integer eqNum;
  input Integer varNum;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input Boolean skipDiscInAlgorithm;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input BackendDAE.Constraints cons;
  output list<SimCode.SimEqSystem> equation_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
protected
  BackendDAE.Variables vars;
  BackendDAE.EquationArray eqns;
  BackendDAE.Equation eqn;
  BackendDAE.Var v;
algorithm
  BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns) := syst;
  eqn := BackendEquation.get(eqns, eqNum);
  _ := match eqn
    case BackendDAE.WHEN_EQUATION() then ();
    else
      algorithm
        v := BackendVariable.getVarAt(vars, varNum);
      then ();
  end match;

  (equation_, ouniqueEqIndex, otempvars) := match eqn
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      Option<DAE.VariableAttributes> values;
      Integer uniqueEqIndex1, uniqueEqIndex;
      list<DAE.Statement> algStatements;
      list<DAE.ComponentRef> conditions, solveCr;
      list<SimCode.SimEqSystem> resEqs;
      DAE.ComponentRef left, varOutput;
      DAE.Exp e1, e2, varexp, exp_, start, cond, prevarexp;
      DAE.Ident iter;
      BackendDAE.WhenEquation whenEquation, elseWhen;
      Option<BackendDAE.WhenEquation> oelseWhen;
      String algStr, message, eqStr;
      DAE.ElementSource source;
      list<DAE.Statement> asserts;
      SimCode.SimEqSystem elseWhenEquation, simEqSys;
      DAE.Algorithm alg;
      list<SimCodeVar.SimVar> tempvars;
      Boolean initialCall;
      DAE.Expand crefExpand;
      Boolean homotopySupport;
      DAE.FunctionTree funcs;
      list<BackendDAE.Equation> solveEqns;
      list<SimCode.SimEqSystem> eqSystlst;
      list<BackendDAE.WhenOperator> whenStmtLst;
      Option<SimCode.SimEqSystem> oelseWhenSimEq;
      BackendDAE.EquationAttributes eqAttr;
      Boolean b;

    // array equation that may result from -d=-nfScalarize and is assumed solved
    case BackendDAE.ARRAY_EQUATION(left = DAE.CREF(componentRef = cr), right = e2, source = source, attr = eqAttr)
      then
        ({SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex, cr, e2, source, eqAttr)}, iuniqueEqIndex + 1, itempvars);

    // for equation that may result from -d=-nfScalarize
    case BackendDAE.FOR_EQUATION(iter = varexp, start = start, stop = cond, source = source, attr = eqAttr)
      algorithm
        (e1, e2) := match eqn.body
          case BackendDAE.EQUATION(exp = e1, scalar = e2) then
            (e1, e2);
          case BackendDAE.ARRAY_EQUATION(left = e1, right = e2) then
            (e1, e2);
          else algorithm
            Error.addInternalError("Unsupported FOR_EQUATION: " + BackendDump.equationString(eqn)  + " ToDo: generalize SimEqSystem.SES_FOR_LOOP with embedded SimEqSystem.", sourceInfo());
          then fail();
        end match;
        DAE.CREF(componentRef = DAE.CREF_IDENT(ident = iter)) := varexp;
        cr := ComponentReference.crefApplySubs(v.varName, {DAE.INDEX(DAE.CREF(DAE.CREF_IDENT(iter, DAE.T_INTEGER_DEFAULT, {}), DAE.T_INTEGER_DEFAULT))});
        BackendDAE.SHARED(functionTree = funcs) := shared;
        try
          (exp_, asserts, solveEqns, solveCr) := ExpressionSolve.solve2(e1, e2, Expression.crefExp(cr), SOME(funcs), SOME(iuniqueEqIndex), true, BackendDAEUtil.isSimulationDAE(shared));
        else
          Error.addInternalError("solving FOR_EQUATION body: " + BackendDump.equationString(eqn.body)  + "\nfor variable: " + ComponentReference.printComponentRefStr(cr) + ".", sourceInfo());
          fail();
        end try;
      then
        ({SimCode.SES_FOR_LOOP(iuniqueEqIndex, varexp, start, cond, cr, exp_, source, eqAttr)}, iuniqueEqIndex + 1, itempvars);

    // solved equation
    case BackendDAE.SOLVED_EQUATION(exp=e2, source=source, attr=eqAttr)
      algorithm
        cr := v.varName;
        varexp := Expression.crefExp(cr);
        varexp := if BackendVariable.isStateVar(v) then Expression.expDer(varexp) else varexp;
      then
        ({SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex, cr, e2, source, eqAttr)}, iuniqueEqIndex+1, itempvars);

    // when eq
    case BackendDAE.WHEN_EQUATION(whenEquation=whenEquation, source=source, attr=eqAttr)
      equation
        BackendDAE.WHEN_STMTS(cond, whenStmtLst, oelseWhen) = whenEquation;
        if isSome(oelseWhen) then
          SOME(elseWhen) = oelseWhen;
          (elseWhenEquation,uniqueEqIndex) = createElseWhenEquation(elseWhen, {}, iuniqueEqIndex+1, source, eqAttr);
          oelseWhenSimEq = SOME(elseWhenEquation);
        else
          uniqueEqIndex = iuniqueEqIndex+1;
          oelseWhenSimEq = NONE();
        end if;
        (conditions, initialCall) = BackendDAEUtil.getConditionList(cond);
      then
        ({SimCode.SES_WHEN(iuniqueEqIndex, conditions, initialCall, whenStmtLst, oelseWhenSimEq, source, eqAttr)}, uniqueEqIndex+1, itempvars);

    // single equation
    case BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr)
      algorithm
        cr := v.varName;
        varexp := Expression.crefExp(cr);
        varexp := if BackendVariable.isStateVar(v) then Expression.expDer(varexp) else varexp;
        BackendDAE.SHARED(functionTree = funcs) := shared;
        b := true;
        try
          (exp_, asserts, solveEqns, solveCr) := ExpressionSolve.solve2(e1, e2, varexp, SOME(funcs), SOME(iuniqueEqIndex), true, BackendDAEUtil.isSimulationDAE(shared));
        else
          b := false;
        end try;
        if b then
          solveEqns := listReverse(solveEqns);
          solveCr := listReverse(solveCr);
          cr := if BackendVariable.isStateVar(v) then ComponentReference.crefPrefixDer(cr) else cr;
          source := ElementSource.addSymbolicTransformationSolve(true, source, cr, e1, e2, exp_, asserts);
          (eqSystlst, uniqueEqIndex1) := List.mapFold(solveEqns, makeSolved_SES_SIMPLE_ASSIGN, iuniqueEqIndex);
          if listEmpty(cons) then
            (resEqs, uniqueEqIndex) := addAssertEqn(asserts, {SimCode.SES_SIMPLE_ASSIGN(uniqueEqIndex1, cr, exp_, source, eqAttr)}, uniqueEqIndex1+1);
          else
            (resEqs, uniqueEqIndex) := addAssertEqn(asserts, {SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(uniqueEqIndex1, cr, exp_, source, cons, eqAttr)}, uniqueEqIndex1+1);
          end if;
          eqSystlst := listAppend(eqSystlst,resEqs);
          tempvars := createTempVarsforCrefs(List.map(solveCr, Expression.crefExp),itempvars);
        else
          if match (e1,e2) case (DAE.RCONST(),DAE.IFEXP()) then true; else false; end match then
            try
              // single equation from if-equation -> 0.0 = if .. then bla else lbu and var is not in all branches
              // change branches without variable to var - pre(var)
              prevarexp := Expression.makePureBuiltinCall("pre", {varexp}, Expression.typeof(varexp));
              prevarexp := Expression.expSub(varexp, prevarexp);
              (e2, _) := Expression.traverseExpBottomUp(e2, replaceIFBrancheswithoutVar, (varexp, prevarexp));
              eqn := BackendDAE.EQUATION(e1, e2, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
              (resEqs, uniqueEqIndex, tempvars) := createNonlinearResidualEquations({eqn}, iuniqueEqIndex, itempvars, shared.functionTree);
              cr := if BackendVariable.isStateVar(v) then ComponentReference.crefPrefixDer(cr) else cr;
              (_, homotopySupport) := BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);
              eqSystlst := {SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(uniqueEqIndex, resEqs, {cr}, 0, 1, NONE(), homotopySupport, false, false), NONE(), eqAttr)};
              uniqueEqIndex := uniqueEqIndex + 1;
            else
              b := false;
            end try;
          else
            b := false;
          end if;
          if not b then
            // non-linear
            (resEqs, uniqueEqIndex, tempvars) := createNonlinearResidualEquations({eqn}, iuniqueEqIndex, itempvars, shared.functionTree);
            cr := if BackendVariable.isStateVar(v) then ComponentReference.crefPrefixDer(cr) else cr;
            (_, homotopySupport) := BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);
            eqSystlst := {SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(uniqueEqIndex, resEqs, {cr}, 0, 1, NONE(), homotopySupport, false, false), NONE(), eqAttr)};
            uniqueEqIndex := uniqueEqIndex+1;
          end if;
        end if;
      then (eqSystlst, uniqueEqIndex,tempvars);

    // Algorithm for single variable.
    case BackendDAE.ALGORITHM(alg=alg, source=source, expand=crefExpand, attr=eqAttr)
      algorithm
        varOutput::{} := CheckModel.checkAndGetAlgorithmOutputs(alg, source, crefExpand);
        // The output variable of the algorithm must be the variable solved
        // for, otherwise we need to solve an inverse problem of an algorithm
        // section.
        DAE.ALGORITHM_STMTS(algStatements) := BackendDAEUtil.collateAlgorithm(alg, NONE());
        if ComponentReference.crefEqualNoStringCompare(BackendVariable.varCref(v), varOutput) then
          if skipDiscInAlgorithm then
            algStatements := BackendDAEUtil.removeDiscreteAssignments(algStatements, vars);
          end if;
        else
          try
            algStatements := solveAlgorithmInverse(algStatements, {v});
          else
            algStr :=  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg, source)});
            message := ComponentReference.printComponentRefStr(BackendVariable.varCref(v));
            message := stringAppendList({"Inverse Algorithm needs to be solved for ", message, " in \n", algStr, "This has not been implemented yet.\n"});
            Error.addInternalError(message, sourceInfo());
            fail();
          end try;
        end if;
      then
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex, algStatements, eqAttr)}, iuniqueEqIndex+1, itempvars);

  end match;
end createEquation;

protected function replaceIFBrancheswithoutVar
  input DAE.Exp inExp;
  input tuple<DAE.Exp, DAE.Exp> inTpl;
  output DAE.Exp outExp;
  output tuple<DAE.Exp, DAE.Exp> outTpl;
algorithm
  (outExp,outTpl) := match (inExp,inTpl)
    local
      DAE.Exp exp, crexp, cond, e1, e2;
      Boolean b1, b2;
    case (DAE.IFEXP(cond, e1, e2), (crexp, exp))
      equation
        b1 = Expression.expContains(e1, crexp);
        e1 = if b1 then e1 else exp;
        b2 = Expression.expContains(e2, crexp);
        e2 = if b2 then e2 else exp;
      then (if b1 and b2 then inExp else DAE.IFEXP(cond, e1, e2), inTpl);
    else (inExp,inTpl);
  end match;
end replaceIFBrancheswithoutVar;

protected function solveAlgorithmInverse "author: jfrenkel
  This function solves symbolically a algorithm inverse for a few special cases."
  input list<DAE.Statement> inStmts;
  input list<BackendDAE.Var> inSolveFor;
  output list<DAE.Statement> outStmts;
algorithm
  outStmts := match (inStmts, inSolveFor)
    local
      DAE.ComponentRef cr1;
      DAE.Exp e11, e12, varexp1, solvedExp1;
      DAE.ElementSource source1;
      DAE.Type tp1;
      BackendDAE.Var v1;

      DAE.ComponentRef cr2;
      DAE.Exp e21, e22, varexp2, solvedExp2;
      DAE.ElementSource source2;
      DAE.Type tp2;
      BackendDAE.Var v2;

      list<DAE.Statement> asserts;

    // Algorithm for single variable
    // a := exp1(b); => b := exp1_(a);
    case (DAE.STMT_ASSIGN(exp1=e11, exp=e12, source=source1)::{}, (v1 as BackendDAE.VAR(varName=cr1))::{}) equation
      varexp1 = Expression.crefExp(cr1);
      varexp1 = if BackendVariable.isStateVar(v1) then Expression.expDer(varexp1) else varexp1;
      (solvedExp1, asserts) = ExpressionSolve.solve(e11, e12, varexp1);
      cr1 = if BackendVariable.isStateVar(v1) then ComponentReference.crefPrefixDer(cr1) else cr1;
      source1 = ElementSource.addSymbolicTransformationSolve(true, source1, cr1, e11, e12, solvedExp1, asserts);
      tp1 = Expression.typeof(varexp1);
    then {DAE.STMT_ASSIGN(tp1, varexp1, solvedExp1, source1)};

    // a := exp1(b); c := exp2(d); => b := exp1_(a); d := exp2_(c);
    case (DAE.STMT_ASSIGN(exp1=e11, exp=e12, source=source1)::DAE.STMT_ASSIGN(exp1=e21, exp=e22, source=source2)::{}, (v1 as BackendDAE.VAR(varName=cr1))::(v2 as BackendDAE.VAR(varName=cr2))::{}) equation
      // check for cross-over dependencies
      false = Expression.expHasCref(e12, cr2);
      false = Expression.expHasCref(e22, cr1);

      varexp1 = Expression.crefExp(cr1);
      varexp1 = if BackendVariable.isStateVar(v1) then Expression.expDer(varexp1) else varexp1;
      (solvedExp1, asserts) = ExpressionSolve.solve(e11, e12, varexp1);
      cr1 = if BackendVariable.isStateVar(v1) then ComponentReference.crefPrefixDer(cr1) else cr1;
      source1 = ElementSource.addSymbolicTransformationSolve(true, source1, cr1, e11, e12, solvedExp1, asserts);
      tp1 = Expression.typeof(varexp1);

      varexp2 = Expression.crefExp(cr2);
      varexp2 = if BackendVariable.isStateVar(v2) then Expression.expDer(varexp2) else varexp2;
      (solvedExp2, asserts) = ExpressionSolve.solve(e21, e22, varexp2);
      cr2 = if BackendVariable.isStateVar(v2) then ComponentReference.crefPrefixDer(cr2) else cr2;
      source2 = ElementSource.addSymbolicTransformationSolve(true, source2, cr2, e21, e22, solvedExp2, asserts);
      tp2 = Expression.typeof(varexp2);
    then {DAE.STMT_ASSIGN(tp1, varexp1, solvedExp1, source1), DAE.STMT_ASSIGN(tp2, varexp2, solvedExp2, source2)};
  end match;
end solveAlgorithmInverse;

// =============================================================================
// Section for handling complex equations
//
// =============================================================================

protected function createNonlinearResidualEquationsComplex
  input DAE.Exp inExp;
  input DAE.Exp inExp1;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes eqAttr;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (equations_, ouniqueEqIndex, otempvars) := matchcontinue (inExp, inExp1)
    local
      DAE.ComponentRef cr, crtmp;
      list<DAE.ComponentRef> crlst;
      list<list<DAE.ComponentRef>> crlstlst;
      DAE.Exp e1, e2, e1_1, e2_1, etmp;
      DAE.Statement stms;
      DAE.Type tp;
      list<DAE.Exp> expl, crexplst, lhsExpLstRes, rhsExpLstRes, lhsExpLstAss, rhsExpLstAss;
      list<DAE.Var> varLst;
      list<DAE.Exp> e1lst, e2lst;
      SimCode.SimEqSystem simeqn_complex;
      list<SimCode.SimEqSystem> eqSystlst, eqSystlst_simpAss;
      list<tuple<DAE.Exp, DAE.Exp>> exptl;
      Integer uniqueEqIndex;
      Absyn.Path path, rpath;
      String ident, s, s1, s2;
      list<SimCodeVar.SimVar> tempvars;

    /* casts */
    case (DAE.CAST(_, e1), _) equation
      (equations_, ouniqueEqIndex, otempvars) = createNonlinearResidualEquationsComplex(e1, inExp1, source, eqAttr, iuniqueEqIndex, itempvars);
    then (equations_, ouniqueEqIndex, otempvars);

    /* casts */
    case (_, DAE.CAST(_, e2)) equation
      (equations_, ouniqueEqIndex, otempvars) = createNonlinearResidualEquationsComplex(inExp, e2, source, eqAttr, iuniqueEqIndex, itempvars);
    then (equations_, ouniqueEqIndex, otempvars);

    /* a = f() */
    case (DAE.CREF(componentRef=cr), _) equation
      // ((e1_1, _)) = Expression.extendArrExp((inExp, false));
      (e2_1, _) = Expression.extendArrExp(inExp1, false);
      // true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      (tp as DAE.T_COMPLEX(varLst=varLst, complexClassType=ClassInf.RECORD(path)))  = Expression.typeof(inExp);
      // tmp
      ident = Absyn.pathStringUnquoteReplaceDot(path, "_");
      crtmp = ComponentReference.makeCrefIdent("$TMP_" + ident + intString(iuniqueEqIndex), tp, {});
      tempvars = createTempVars(varLst, crtmp, itempvars);
      // 0 = a - tmp
      e1lst = List.map1(varLst, Expression.generateCrefsExpFromExpVar, cr);
      e2lst = List.map1(varLst, Expression.generateCrefsExpFromExpVar, crtmp);
      exptl = List.threadTuple(e1lst, e2lst);
      (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_RESIDUAL1, source, eqAttr, iuniqueEqIndex);
      // tmp = f(x, y)
      etmp = Expression.crefExp(crtmp);
      stms = DAE.STMT_ASSIGN(tp, etmp, e2_1, source);
      eqSystlst = SimCode.SES_ALGORITHM(uniqueEqIndex, {stms}, eqAttr)::eqSystlst;
    then (eqSystlst, uniqueEqIndex+1, tempvars);

    /* f() = a */
    case (_, DAE.CREF(componentRef=cr)) equation
      // true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      (e1_1, _) = Expression.extendArrExp(inExp, false);
      // ((e2_1, _)) = Expression.extendArrExp((inExp1, false));
      (tp as DAE.T_COMPLEX(varLst=varLst, complexClassType=ClassInf.RECORD(path)))  = Expression.typeof(inExp1);
      // tmp
      ident = Absyn.pathStringUnquoteReplaceDot(path, "_");
      crtmp = ComponentReference.makeCrefIdent("$TMP_" + ident + intString(iuniqueEqIndex), tp, {});
      tempvars = createTempVars(varLst, crtmp, itempvars);
      // 0 = a - tmp
      e1lst = List.map1(varLst, Expression.generateCrefsExpFromExpVar, cr);
      e2lst = List.map1(varLst, Expression.generateCrefsExpFromExpVar, crtmp);
      exptl = List.threadTuple(e1lst, e2lst);
      (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_RESIDUAL1, source, eqAttr, iuniqueEqIndex);
      // tmp = f(x, y)
      etmp = Expression.crefExp(crtmp);
      stms = DAE.STMT_ASSIGN(tp, etmp, e1_1, source);
      eqSystlst = SimCode.SES_ALGORITHM(uniqueEqIndex, {stms}, eqAttr)::eqSystlst;
    then (eqSystlst, uniqueEqIndex+1, tempvars);

    /* Record() = f() */
    case (DAE.CALL(path=path, expLst=e2lst, attr=DAE.CALL_ATTR(ty= tp as DAE.T_COMPLEX(varLst=varLst, complexClassType=ClassInf.RECORD(rpath)))), _) equation
      true = Absyn.pathEqual(path, rpath);
      (e2_1, _) = Expression.extendArrExp(inExp1, false);
      // true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      // tmp = f()
      ident = Absyn.pathStringUnquoteReplaceDot(path, "_");
      cr = ComponentReference.makeCrefIdent("$TMP_" + ident + intString(iuniqueEqIndex), tp, {});
      e1_1 = Expression.crefToExp(cr);
      stms = DAE.STMT_ASSIGN(tp, e1_1, e2_1, source);
      simeqn_complex = SimCode.SES_ALGORITHM(iuniqueEqIndex, {stms}, eqAttr);
      uniqueEqIndex = iuniqueEqIndex + 1;

      // Record()-tmp = 0
      /* Expand the tmp record and any arrays */
      e1lst = Expression.expandExpression(e1_1, expandRecord = true);
      /* Expand the varLst. Each var might be an array or record. */
      e2lst = List.mapFlat(e2lst, function Expression.expandExpression(expandRecord = true));
      /* pair each of the expanded expressions to coressponding one*/
      exptl = List.threadTuple(e1lst, e2lst);
      /* Create residual equations for each pair*/
      (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_RESIDUAL1, source, eqAttr, uniqueEqIndex);
      eqSystlst = simeqn_complex::eqSystlst;

      tempvars = createTempVars(varLst, cr, itempvars);
    then (eqSystlst, uniqueEqIndex, tempvars);

    /* f() = Record() */
    case (_, DAE.CALL(path=path, expLst=e2lst, attr=DAE.CALL_ATTR(ty=tp as DAE.T_COMPLEX(varLst=varLst, complexClassType=ClassInf.RECORD(rpath))))) equation
      true = Absyn.pathEqual(path, rpath);
      (e1_1, _) = Expression.extendArrExp(inExp1, false);
      // true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      // tmp = f()
      ident = Absyn.pathStringUnquoteReplaceDot(path, "_");
      cr = ComponentReference.makeCrefIdent("$TMP_" + ident + intString(iuniqueEqIndex), tp, {});
      e2_1 = Expression.crefExp(cr);
      stms = DAE.STMT_ASSIGN(tp, e2_1, e1_1, source);
      simeqn_complex = SimCode.SES_ALGORITHM(iuniqueEqIndex, {stms}, eqAttr);
      uniqueEqIndex = iuniqueEqIndex + 1;
      // Record()-tmp = 0
      e1lst = List.map1(varLst, Expression.generateCrefsExpFromExpVar, cr);
      exptl = List.threadTuple(e1lst, e2lst);
      (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_RESIDUAL1, source, eqAttr, uniqueEqIndex);
      eqSystlst = simeqn_complex::eqSystlst;
      tempvars = createTempVars(varLst, cr, itempvars);
    then (eqSystlst, uniqueEqIndex, tempvars);

    /* Tuple() = f()  */
    case (DAE.TUPLE(PR=expl), DAE.CALL(path=path)) equation
      // true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
      // tmp = f()
      tp = Expression.typeof(inExp);
      ident = Absyn.pathStringUnquoteReplaceDot(path, "_");
      cr = ComponentReference.makeCrefIdent("$TMP_" + ident + intString(iuniqueEqIndex), tp, {});
      crexplst = List.map1(expl, Expression.generateCrefsExpFromExp, cr);
      stms = DAE.STMT_TUPLE_ASSIGN(tp, crexplst, inExp1, source);
      simeqn_complex = SimCode.SES_ALGORITHM(iuniqueEqIndex, {stms}, eqAttr);
      uniqueEqIndex = iuniqueEqIndex + 1;

      // for creating makeSES_RESIDUAL1 all crefs needs to expanded
      // and all WILD() crefs are filtered
      expl = List.filterOnTrue(expl, Expression.isNotWild);
      expl = List.flatten(List.map1(expl, Expression.generateCrefsExpLstFromExp, NONE()));
      crexplst = List.flatten(List.map1(expl, Expression.generateCrefsExpLstFromExp, SOME(cr)));
      crlst = List.map(crexplst, Expression.expCref);
      crlstlst = List.map1(crlst, ComponentReference.expandCref, true);
      crlst = List.flatten(crlstlst);
      crexplst = List.map(crlst, Expression.crefExp);

      crlst = List.map(expl, Expression.expCref);
      crlstlst = List.map1(crlst, ComponentReference.expandCref, true);
      crlst = List.flatten(crlstlst);
      expl = List.map(crlst, Expression.crefExp);

      // Tuple() - tmp = 0
      exptl = List.threadTuple(expl, crexplst);
      (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_RESIDUAL1, source, eqAttr, uniqueEqIndex);
      eqSystlst = simeqn_complex::eqSystlst;

      tempvars = createTempVarsforCrefs(listReverse(crexplst), itempvars);
    then (eqSystlst, uniqueEqIndex, tempvars);

    // failure
    else equation
      s1 = ExpressionDump.printExpStr(inExp);
      s2 = ExpressionDump.printExpStr(inExp1);
      s = stringAppendList({"function createNonlinearResidualEquationsComplex failed for: ", s1, " = " , s2 });
      Error.addInternalError(s, sourceInfo());
    then fail();
  end matchcontinue;
end createNonlinearResidualEquationsComplex;

protected function createNonlinearResidualEquationsSingleComplex
  input DAE.Exp inExp;
  input DAE.Exp inExp1;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes eqAttr;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
  input output list<DAE.ComponentRef> eqCrefs = {};
algorithm
  (equations_, ouniqueEqIndex, otempvars) := match (inExp, inExp1)
    local
      DAE.ComponentRef cr;
      list<DAE.ComponentRef> callCrefs;
      DAE.Statement stms;
      DAE.Type tp;
      list<DAE.Exp> expl, callExps, crexplst, lhsExpLstRes, rhsExpLstRes, lhsExpLstAss, rhsExpLstAss;
      SimCode.SimEqSystem simeqn_complex;
      list<SimCode.SimEqSystem> eqSystlst, eqSystlst_simpAss;
      list<tuple<DAE.Exp, DAE.Exp>> exptl;
      Integer uniqueEqIndex;
      Absyn.Path path;
      String ident;
      list<SimCodeVar.SimVar> tempvars;

    /* Tuple() = f()  */
    case (DAE.TUPLE(PR=expl), DAE.CALL(path=path, expLst=callExps)) equation
      // Get all crefs in the call arguments
      (_, callCrefs) = Expression.traverseExpList(callExps, Expression.traversingComponentRefFinder, {});

      // Prepare cref prefix for temporary variables
      tp = Expression.typeof(inExp);
      ident = Absyn.pathStringUnquoteReplaceDot(path, "_");
      cr = ComponentReference.makeCrefIdent("$TMP_" + ident + intString(iuniqueEqIndex), tp, {});

      // Create temporary variables and residual equations for variables not solved in this equation
      (eqCrefs, crexplst, lhsExpLstRes, rhsExpLstRes, lhsExpLstAss, rhsExpLstAss) = createTmpCrefExpsForComplexEqnSys(expl, cr, eqCrefs, callCrefs);

      // Create algorithm equation from complex equation with temporary variables
      stms = DAE.STMT_TUPLE_ASSIGN(tp, crexplst, inExp1, source);
      simeqn_complex = SimCode.SES_ALGORITHM(iuniqueEqIndex, {stms}, eqAttr);
      uniqueEqIndex = iuniqueEqIndex + 1;

      // Make simple assignments
      // var := tmp_var
      exptl = List.threadTuple(lhsExpLstAss, rhsExpLstAss);
      (eqSystlst_simpAss, uniqueEqIndex) = List.map2Fold(exptl, makeSES_SIMPLE_ASSIGN, source, eqAttr, uniqueEqIndex);

      // Make residual equations
      // tmp_var - var = 0
      exptl = List.threadTuple(rhsExpLstRes, lhsExpLstRes);
      (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_RESIDUAL1, source, eqAttr, uniqueEqIndex);

      // Add simEqns to eqSystlst and temporary variables to tempvars
      eqSystlst = simeqn_complex :: listAppend(eqSystlst_simpAss, eqSystlst);
      tempvars = createTempVarsforCrefs(listReverse(rhsExpLstAss), itempvars);
      tempvars = createTempVarsforCrefs(listReverse(lhsExpLstRes), tempvars);
    then (eqSystlst, uniqueEqIndex, tempvars);

    /* To-Do: Add other cases
       - a = f()
       - f() = a
       - Record() = f()
       - f() = Record()
    */
  end match;
end createNonlinearResidualEquationsSingleComplex;

protected function createTmpCrefExpsForComplexEqnSys
  "This function creates tmp cref expressions for crefs that are not solved in the current complex equation or occur on rhs and lhs.
   It also returns lists of expressions to create inner equations and residual equations from.
   author: ptaeuber 06-2017"
  input list<DAE.Exp> inExpLst;
  input DAE.ComponentRef crPrefix;
  input output list<DAE.ComponentRef> eqCrefs;
  input list<DAE.ComponentRef> callCrefs;
  output list<DAE.Exp> outExpList = {};
  input output list<DAE.Exp> lhsExpLstRes = {};
  input output list<DAE.Exp> rhsExpLstRes = {};
  input output list<DAE.Exp> lhsExpLstAss = {};
  input output list<DAE.Exp> rhsExpLstAss = {};
protected
  DAE.Exp newExp;
algorithm
  for e in inExpLst loop
    (eqCrefs, newExp, lhsExpLstRes, rhsExpLstRes, lhsExpLstAss, rhsExpLstAss) := createTmpCrefExpsForComplexEqnSys_work(e, crPrefix, eqCrefs, callCrefs, lhsExpLstRes, rhsExpLstRes, lhsExpLstAss, rhsExpLstAss);
    outExpList := newExp::outExpList;
  end for;
  outExpList := List.listReverseInPlace(outExpList);
end createTmpCrefExpsForComplexEqnSys;

protected function createTmpCrefExpsForComplexEqnSys_work
  "This function gets a crefExp and decides if a tmp_crefExp is needed. If yes, tmp_crefExp is created and returned.
   It also returns lists of expressions to create inner equations and residual equations from.
   author: ptaeuber 06-2017"
  input DAE.Exp inExp;
  input DAE.ComponentRef inCrefPrefix;
  input output list<DAE.ComponentRef> eqCrefs;
  input list<DAE.ComponentRef> callCrefs;
  output DAE.Exp outCrefExp;
  input output list<DAE.Exp> lhsExpLstRes;
  input output list<DAE.Exp> rhsExpLstRes;
  input output list<DAE.Exp> lhsExpLstAss;
  input output list<DAE.Exp> rhsExpLstAss;
algorithm
  outCrefExp := match inExp
    local
      String name;
      DAE.Type ty;
      DAE.ComponentRef cr, c1;
      list<DAE.ComponentRef> crlist;
      DAE.Exp e, exp, tmp_exp;
      list<DAE.Exp> tmp_lhsExpLstRes = {}, tmp_rhsExpLstRes = {}, tmp_lhsExpLstAss = {}, tmp_rhsExpLstAss = {};
      Boolean isEqCref, createTmpVar = false;

    // Wild cref
    case DAE.CREF(componentRef=DAE.WILD()) then inExp;

    // Array cref
    case DAE.CREF(componentRef=cr) guard Expression.isArrayType(ComponentReference.crefTypeFull(cr))
      algorithm
        crlist := ComponentReference.expandCref(cr, true);

        // Loop array crefs to find out if at least one cref is not in cref list
        // (means not a variable solved in the current equation)
        for c in crlist loop
          // Prepare temporary crefExp
          name := ComponentReference.crefModelicaStr(c);
          ty := ComponentReference.crefTypeFull(c);
          c1 := ComponentReference.crefPrependIdent(inCrefPrefix,name,ComponentReference.crefSubs(c),ty);
          tmp_exp := Expression.makeCrefExp(c1, ty);
          exp := Expression.makeCrefExp(c, ty);

          isEqCref := List.isMemberOnTrue(c, eqCrefs, ComponentReference.crefEqual);
          if isEqCref then
            // Add cref to temporary assignment lists
            tmp_lhsExpLstAss := exp :: tmp_lhsExpLstAss;
            tmp_rhsExpLstAss := tmp_exp :: tmp_rhsExpLstAss;

            // Delete that cref because it is not an iteration variable!
            eqCrefs := List.deleteMemberOnTrue(c, eqCrefs, ComponentReference.crefEqual);
          else
            // Add cref to temporary residual lists
            tmp_lhsExpLstRes := tmp_exp :: tmp_lhsExpLstRes;
            tmp_rhsExpLstRes := exp :: tmp_rhsExpLstRes;
          end if;

          createTmpVar := createTmpVar or not isEqCref;
        end for;

        // If at least one cref is not in cref list create new tmp crefExp (variable) to add to the system
        if createTmpVar then
          // Prepare temporary crefExp
          name := ComponentReference.crefModelicaStr(cr);
          ty := ComponentReference.crefTypeFull(cr);
          cr := ComponentReference.crefPrependIdent(inCrefPrefix,name,ComponentReference.crefSubs(cr),ty);
          e := Expression.makeCrefExp(cr, ty);

          // Add temporary residual and assignment list to global lists
          lhsExpLstAss := listAppend(tmp_lhsExpLstAss, lhsExpLstAss);
          rhsExpLstAss := listAppend(tmp_rhsExpLstAss, rhsExpLstAss);
          lhsExpLstRes := listAppend(tmp_lhsExpLstRes, lhsExpLstRes);
          rhsExpLstRes := listAppend(tmp_rhsExpLstRes, rhsExpLstRes);
        else
          // All the crefs are to be solved in the current equation, so no tmp var is needed
          e := inExp;
        end if;
      then e;

    // Normal cref
    case DAE.CREF(componentRef=cr)
      algorithm
        // If cref is not in cref list (means not a variable solved in the current equation)
        // create new tmp crefExp (variable) to add to the system
        // Also do this if cref occurs in lhs and rhs
        if not List.isMemberOnTrue(cr, eqCrefs, ComponentReference.crefEqual) or List.isMemberOnTrue(cr, callCrefs, ComponentReference.crefEqual) then
          // Prepare temporary crefExp
          name := ComponentReference.crefModelicaStr(cr);
          ty := ComponentReference.crefTypeFull(cr);
          cr := ComponentReference.crefPrependIdent(inCrefPrefix,name,ComponentReference.crefSubs(cr),ty);
          e := Expression.makeCrefExp(cr, ty);

          // Add expressions to residual lists
          lhsExpLstRes := e :: lhsExpLstRes;
          rhsExpLstRes := inExp :: rhsExpLstRes;
        else
          // Cref is to be solved in the current equation on the lhs, so no tmp var is needed
          e := inExp;
          // Delete that cref because it is not an iteration variable!
          eqCrefs := List.deleteMemberOnTrue(cr, eqCrefs, ComponentReference.crefEqual);
        end if;
      then e;

    else
      equation
        print("SimCodeUtil.createTmpCrefExpsForComplexEqnSys_work: fail for" + ExpressionDump.printExpStr(inExp) + "\n");
      then fail();
  end match;
end createTmpCrefExpsForComplexEqnSys_work;

protected function createArrayTempVar
  input DAE.ComponentRef name;
  input list<Integer> dims;
  input list<DAE.Exp> inTmpCrefsLst;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  otempvars := match(inTmpCrefsLst)
    local
      list<DAE.Exp> rest;
      list<SimCodeVar.SimVar> tempvars;
      DAE.Type ty;
      DAE.ComponentRef cr;
      SimCodeVar.SimVar var;
      list<String> slst;

    case({}) then itempvars;

    case(DAE.CREF(cr, ty)::rest) equation
      slst = List.map(dims, intString);
      var = SimCodeVar.SIMVAR(cr, BackendDAE.VARIABLE(), "", "", "", 0, NONE(), NONE(), NONE(), NONE(), false, ty, false, SOME(name), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SimCodeVar.NONECAUS(), NONE(), slst, false, true, true, NONE(), NONE());
      tempvars = createTempVarsforCrefs(rest, {var});
    then List.append_reverse(tempvars, itempvars);
  end match;
end createArrayTempVar;

protected function createTempVarsforCrefs
  input list<DAE.Exp> inTmpCrefsLst;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  otempvars := match(inTmpCrefsLst)
    local
      list<DAE.Exp> rest, expl;
      DAE.Type ty;
      DAE.ComponentRef cr;
      SimCodeVar.SimVar var;
      Option<DAE.ComponentRef> arrayCref;
      list<SimCodeVar.SimVar> tempvars;
      list<String> numArrayElement;
      list<DAE.Dimension> inst_dims;

    case({}) then itempvars;

    case(DAE.ARRAY(array=expl)::rest) equation
      tempvars = createTempVarsforCrefs(expl, itempvars);
    then createTempVarsforCrefs(rest, tempvars);

    case(DAE.TUPLE(PR=expl)::rest) equation
      tempvars = createTempVarsforCrefs(expl, itempvars);
    then createTempVarsforCrefs(rest, tempvars);

    case(DAE.CREF(cr, ty)::rest) equation
      arrayCref = ComponentReference.getArrayCref(cr);
      inst_dims = ComponentReference.crefDims(cr);
      numArrayElement = List.map(inst_dims, ExpressionDump.dimensionString);
      var = SimCodeVar.SIMVAR(cr, BackendDAE.VARIABLE(), "", "", "", 0, NONE(), NONE(), NONE(), NONE(), false, ty, false, arrayCref, SimCodeVar.NOALIAS(), DAE.emptyElementSource, SimCodeVar.NONECAUS(), NONE(), numArrayElement, false, true, true, NONE(), NONE());
    then createTempVarsforCrefs(rest, var::itempvars);
  end match;
end createTempVarsforCrefs;

protected function createTempVars
  input list<DAE.Var> varLst;
  input DAE.ComponentRef inCrefPrefix;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  otempvars := match(varLst)
    local
      list<DAE.Var> rest;
      list<SimCodeVar.SimVar> ttmpvars;
      DAE.Ident name;
      DAE.Type ty;
      DAE.ComponentRef cr, arraycref;
      list<DAE.ComponentRef> crlst;
      SimCodeVar.SimVar var;

    case {}
    then itempvars;

    case DAE.TYPES_VAR(name=name, ty=ty as DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(_)))::rest equation
      cr = ComponentReference.crefPrependIdent(inCrefPrefix, name, {}, ty);
    then createTempVars(rest, cr, itempvars);

    case DAE.TYPES_VAR(name=name, ty=ty)::rest
      algorithm
        /* Prepend the tmp ident.*/
        cr := ComponentReference.crefPrependIdent(inCrefPrefix, name, {}, ty);
        /* Expand the resulting cref.*/
        cr::crlst := ComponentReference.expandCref(cr, true /*the way it is now we won't get records here. but if we do somehow expand them*/);

        /* Create SimVars from the list of expanded crefs.*/

        /* Mark the first element as an arrayCref i.e. we have 'SOME(arraycref)' since this is how the C template
          detects first elements of arrays to generate VARNAME_indexed(..) macros for accessing the array
          with variable indexes.*/
        arraycref := ComponentReference.crefStripSubs(cr);
        ty := ComponentReference.crefTypeFull(cr);
        var := SimCodeVar.SIMVAR(cr, BackendDAE.VARIABLE(), "", "", "", 0, NONE(), NONE(), NONE(), NONE(), false,
              ty, false, SOME(arraycref), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SimCodeVar.NONECAUS(), NONE(), {}, false, true, true, NONE(), NONE());

        /* The rest don't need to be marked i.e. we have 'NONE()'. Just create simvars. */
        ttmpvars := {var};
        for cr in crlst loop
          ty := ComponentReference.crefTypeFull(cr);
          var := SimCodeVar.SIMVAR(cr, BackendDAE.VARIABLE(), "", "", "", 0, NONE(), NONE(), NONE(), NONE(), false, ty, false, NONE(), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SimCodeVar.NONECAUS(), NONE(), {}, false, true, true, NONE(), NONE());
          ttmpvars := var::ttmpvars;
        end for;
        ttmpvars := Dangerous.listReverseInPlace(ttmpvars);
        ttmpvars := listAppend(itempvars,ttmpvars);
      then createTempVars(rest, inCrefPrefix, ttmpvars);

  end match;
end createTempVars;

public function createNonlinearResidualEquations
  input list<BackendDAE.Equation> eqs;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input DAE.FunctionTree funcTree;
  output list<SimCode.SimEqSystem> eqSystems = {};
  output Integer ouniqueEqIndex = iuniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars = itempvars;
algorithm
  try
    for eq in listReverse(eqs) loop
      eqSystems := match (eq, ouniqueEqIndex)
        local
          DAE.Exp res_exp, e1, e2, e, lhse;
          list<DAE.Exp> explst, explst1;
          list<SimCode.SimEqSystem> eqSystlst;
          list<Integer> ds;
          DAE.ComponentRef left;
          list<DAE.Statement> algStatements;
          DAE.ElementSource source;
          list<tuple<DAE.Exp, DAE.Exp>> exptl;
          list<DAE.ComponentRef> crefs, crefstmp;
          BackendVarTransform.VariableReplacements repl;
          DAE.Type ty;
          DAE.Expand crefExpand;
          Integer uniqueEqIndex;
          BackendDAE.EquationAttributes eqAttr;
          BackendDAE.Equation ifEq;
          list<BackendDAE.Equation> resEqs;

        case (BackendDAE.EQUATION(exp=e1, scalar=e2, source=source, attr=eqAttr), uniqueEqIndex) equation
          res_exp = Expression.createResidualExp(e1, e2);
          res_exp = Expression.replaceDerOpInExp(res_exp);
          ouniqueEqIndex = uniqueEqIndex + 1;
        then SimCode.SES_RESIDUAL(uniqueEqIndex, res_exp, source, eqAttr)::eqSystems;

        case (BackendDAE.RESIDUAL_EQUATION(exp=e, source=source, attr=eqAttr), uniqueEqIndex) equation
          (res_exp, _) = ExpressionSimplify.simplify(e);
          res_exp = Expression.replaceDerOpInExp(res_exp);
          ouniqueEqIndex = uniqueEqIndex + 1;
        then SimCode.SES_RESIDUAL(uniqueEqIndex, res_exp, source, eqAttr) :: eqSystems;
        // if equations
        case (ifEq as BackendDAE.IF_EQUATION(), uniqueEqIndex) equation
          resEqs = BackendEquation.equationToScalarResidualForm(ifEq, funcTree);
          (eqSystlst,ouniqueEqIndex,otempvars) = createNonlinearResidualEquations(resEqs, uniqueEqIndex-1, otempvars, funcTree);
        then eqSystlst;

        // An array equation
        case (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1, right=e2, source=source, attr=eqAttr), uniqueEqIndex) equation
          ty = Expression.typeof(e1);
          left = ComponentReference.makeCrefIdent("$TMP_" + intString(uniqueEqIndex), ty, {});
          lhse = DAE.CREF(left,ty);

          res_exp = Expression.createResidualExp(e1, e2);
          res_exp = Expression.replaceDerOpInExp(res_exp);
          crefstmp = ComponentReference.expandCref(left, false);
          explst1 = List.map(crefstmp, Expression.crefExp);
          (eqSystlst, uniqueEqIndex) = List.map2Fold(explst1, makeSES_RESIDUAL, source, eqAttr, uniqueEqIndex);
          eqSystlst = SimCode.SES_ARRAY_CALL_ASSIGN(uniqueEqIndex, lhse, res_exp, source, eqAttr)::eqSystlst;
          otempvars = createArrayTempVar(left, ds, explst1, otempvars);
          ouniqueEqIndex = uniqueEqIndex + 1;
        then listAppend(eqSystlst, eqSystems);

        // A complex equation
        case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, attr=eqAttr), uniqueEqIndex) equation
          (e1, _) = ExpressionSimplify.simplify(e1);
          e1 = Expression.replaceDerOpInExp(e1);
          (e2, _) = ExpressionSimplify.simplify(e2);
          e2 = Expression.replaceDerOpInExp(e2);
          (eqSystlst, ouniqueEqIndex, otempvars) = createNonlinearResidualEquationsComplex(e1, e2, source, eqAttr, uniqueEqIndex, otempvars);
        then listAppend(eqSystlst, eqSystems);

        case (BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_STMTS(), attr=eqAttr), _) equation
          // This following does not work. It does not take index or elseWhen into account.
          // The generated code for the when-equation also does not solve a linear system; it uses the variables directly.
          /*
           tp = Expression.typeof(e2);
           e1 = Expression.makeCrefExp(left, tp);
           res_exp = DAE.BINARY(e1, DAE.SUB(tp), e2);
           res_exp = ExpressionSimplify.simplify(res_exp);
           res_exp = Expression.replaceDerOpInExp(res_exp);
           (eqSystemsRest) = createNonlinearResidualEquations(rest, repl, uniqueEqIndex );
           then
           (SimCode.SES_RESIDUAL(0, res_exp) :: eqSystemsRest, entrylst1);
           */
          Error.addSourceMessage(Error.UNSUPPORTED_LANGUAGE_FEATURE, {"non-linear equations within when-equations", "Perform non-linear operations outside the when-equation (this is slower, but works)"}, BackendEquation.equationInfo(eq));
        then fail();

        case (BackendDAE.ALGORITHM(alg=DAE.ALGORITHM_STMTS(algStatements), source=source, expand=crefExpand, attr=eqAttr), uniqueEqIndex) equation
          crefs = CheckModel.checkAndGetAlgorithmOutputs(DAE.ALGORITHM_STMTS(algStatements), source, crefExpand);
          // BackendDump.debugStrCrefLstStr(("Crefs : ", crefs, ", ", "\n"));
          (crefstmp, repl) = createTmpCrefs(crefs, uniqueEqIndex, {}, BackendVarTransform.emptyReplacements());
          // BackendDump.debugStrCrefLstStr(("Crefs : ", crefstmp, ", ", "\n"));
          explst = List.map(crefs, Expression.crefExp);
          explst = List.map(explst, Expression.replaceDerOpInExp);

          // BackendDump.dumpAlgorithms({DAE.ALGORITHM_STMTS(algStatements)}, 0);
          (algStatements, _) = BackendVarTransform.replaceStatementLst(algStatements, repl, SOME(BackendVarTransform.skipPreOperator), {}, false);
          // BackendDump.dumpAlgorithms({DAE.ALGORITHM_STMTS(algStatements)}, 0);

          explst1 = List.map(crefstmp, Expression.crefExp);
          explst1 = List.map(explst1, Expression.replaceDerOpInExp);
          otempvars = createTempVarsforCrefs(explst1, otempvars);

          // 0 = a - tmp
          exptl = List.threadTuple(explst, explst1);
          (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_RESIDUAL1, source, eqAttr, uniqueEqIndex);

          eqSystlst = SimCode.SES_ALGORITHM(uniqueEqIndex, algStatements, eqAttr)::eqSystlst;
          // Tpl.tplPrint(SimCodeDump.dumpEqs, eqSystlst);

          ouniqueEqIndex = uniqueEqIndex + 1;
        then listAppend(eqSystlst, eqSystems);
      end match;
    end for;
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"function createNonlinearResidualEquations failed"});
    fail();
  end try;
end createNonlinearResidualEquations;

public function dimsToAllIndexes
  input DAE.Dimensions inDims;
  output list<list<Integer>> outIndexes;
protected
  list<Integer> ilst;
  list<list<Integer>> lstlst;
algorithm
  ilst := Expression.dimensionsSizes(inDims);
  lstlst := List.map(ilst, List.intRange);
  outIndexes := dimsToAllIndexes1(lstlst);
end dimsToAllIndexes;

protected function dimsToAllIndexes1
  input list<list<Integer>> inDims;
  output list<list<Integer>> oAllIndex;
algorithm
  oAllIndex := match(inDims)
    local
      list<Integer> dims;
      list<list<Integer>> rest, indxes;
    case (dims::{})
      equation
        indxes = List.map(dims, List.create);
      then
        indxes;
    case (dims::rest)
      equation
        indxes = dimsToAllIndexes1(rest);
        // cons for each element in dims
        indxes = List.fold1(dims, dimsToAllIndexes2, indxes, {});
      then
        indxes;
  end match;
end dimsToAllIndexes1;

protected function dimsToAllIndexes2
  input Integer i;
  input list<list<Integer>> iIndex;
  input list<list<Integer>> iAllIndex;
  output list<list<Integer>> oAllIndex;
algorithm
  oAllIndex := List.map1(iIndex, List.consr, i);
  oAllIndex := listAppend(iAllIndex, oAllIndex);
end dimsToAllIndexes2;

protected function createTmpCrefs
  input list<DAE.ComponentRef> inCrefs;
  input Integer iuniqueEqIndex;
  input list<DAE.ComponentRef> inCrefsAcc;
  input BackendVarTransform.VariableReplacements iRepl;
  output list<DAE.ComponentRef> outCrefs;
  output BackendVarTransform.VariableReplacements oRepl;
algorithm
  (outCrefs, oRepl) := match(inCrefs)
    local
      DAE.ComponentRef cref, crtmp;
      list<DAE.ComponentRef> rest, result;
      DAE.Type tp;
      String ident;
      BackendVarTransform.VariableReplacements repl;

    case({})
    then (listReverse(inCrefsAcc), iRepl);

    case(cref::rest) equation
      ident = ComponentReference.printComponentRefStr(cref);
      ident = System.unquoteIdentifier(ident);
      ident = System.stringReplace(ident, ".", "$P");
      ident = System.stringReplace(ident, ",", "$c");
      ident = System.stringReplace(ident, "[", "$rB");
      ident = System.stringReplace(ident, "]", "$lB");
      tp = Types.arrayElementType(ComponentReference.crefLastType(cref));
      crtmp = ComponentReference.makeCrefIdent("$TMP_" + ident + "_" + intString(iuniqueEqIndex), tp, {});
      repl = BackendVarTransform.addReplacement(iRepl, cref, DAE.CREF(crtmp, tp), SOME(BackendVarTransform.skipPreOperator));
      (result, repl) = createTmpCrefs(rest, iuniqueEqIndex, crtmp::inCrefsAcc, repl);
    then (result, repl);
  end match;
end createTmpCrefs;

protected function makeSES_RESIDUAL
  input DAE.Exp inExp;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes eqAttr;
  input Integer uniqueEqIndex;
  output SimCode.SimEqSystem outSimEqn;
  output Integer ouniqueEqIndex;
  annotation(__OpenModelica_EarlyInline = true);
algorithm
  outSimEqn := SimCode.SES_RESIDUAL(uniqueEqIndex, inExp, source, eqAttr);
  ouniqueEqIndex := uniqueEqIndex+1;
end makeSES_RESIDUAL;

protected function makeSES_RESIDUAL1
  input tuple<DAE.Exp, DAE.Exp> inTpl;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes eqAttr;
  input Integer uniqueEqIndex;
  output SimCode.SimEqSystem outSimEqn;
  output Integer ouniqueEqIndex;
protected
  DAE.Exp e1, e2, e;
algorithm
  (e1, e2) := inTpl;
  e := Expression.createResidualExp(e1, e2);
  outSimEqn := SimCode.SES_RESIDUAL(uniqueEqIndex, e, source, eqAttr);
  ouniqueEqIndex := uniqueEqIndex +1;
end makeSES_RESIDUAL1;

protected function makeSES_SIMPLE_ASSIGN
  input tuple<DAE.Exp, DAE.Exp> inTpl;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes eqAttr;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem outSimEqn;
  output Integer ouniqueEqIndex;
protected
  DAE.Exp e;
  DAE.ComponentRef cr;
  String msg;
algorithm
  (cr, e) := match(inTpl)
    case((DAE.CREF(cr, _), e))
      then (cr,e);
    case((DAE.UNARY(DAE.UMINUS(_), DAE.CREF(cr, _)), e))
      algorithm
        e := Expression.negate(e);
      then (cr,Expression.negate(e));
    else
      algorithm
        msg := "SimCodeUtil.makeSES_SIMPLE_ASSIGN failed for: " + ExpressionDump.printExpStr(Util.tuple21(inTpl))+" = "+ExpressionDump.printExpStr(Util.tuple22(inTpl))+"\n";
        Error.addCompilerWarning(msg);
      then fail();
  end match;
  outSimEqn := SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex, cr, e, source, eqAttr);
  ouniqueEqIndex := iuniqueEqIndex+1;
end makeSES_SIMPLE_ASSIGN;

protected function makeSolved_SES_SIMPLE_ASSIGN
  input BackendDAE.Equation inEqn;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem outSimEqn;
  output Integer ouniqueEqIndex;
protected
  DAE.Exp e;
  DAE.ComponentRef cr;
  DAE.ElementSource source;
  BackendDAE.EquationAttributes eqAttr;
algorithm
  BackendDAE.SOLVED_EQUATION(componentRef= cr, exp=e, source=source, attr=eqAttr) := inEqn;
  outSimEqn := SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex, cr, e, source, eqAttr);
  ouniqueEqIndex := iuniqueEqIndex+1;
end makeSolved_SES_SIMPLE_ASSIGN;

protected function createOdeSystem
  input Boolean genDiscrete "if true generate discrete equations";
  input Boolean skipDiscInAlgorithm "if true skip discrete algorithm vars";
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input BackendDAE.StrongComponent inComp;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input Integer isccIndex; //just to create the simEq to scc mapping. If you don't need this, set the parameter to 1
  input list<tuple<Integer,Integer>> ieqSccMapping;
  input SimCode.BackendMapping iBackendMapping;
  output list<SimCode.SimEqSystem> equations_;
  output list<SimCode.SimEqSystem> noDiscequations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
  output list<tuple<Integer,Integer>> oeqSccMapping;
  output SimCode.BackendMapping oBackendMapping;
algorithm
  (equations_, noDiscequations_, ouniqueEqIndex, otempvars, oeqSccMapping, oBackendMapping) := matchcontinue (isyst, ishared, inComp)
    local
      list<BackendDAE.Equation> eqn_lst,  disc_eqn;
      list<BackendDAE.Var> var_lst,  disc_var, var_lst_1;
      BackendDAE.Variables vars_1, vars, globalKnownVars, exvars;
      BackendDAE.EquationArray eqns_1, eqns;
      Option<list<tuple<Integer, Integer, BackendDAE.Equation>>> jac;
      BackendDAE.JacobianType jac_tp;
      list<DAE.Constraint> constrs;
      list<DAE.ClassAttributes> clsAttrs;
      FCore.Cache cache;
      FCore.Graph graph;
      DAE.FunctionTree funcs;
      BackendDAE.EventInfo ev;
      list<Integer> ieqns, ivars, disc_eqns, disc_vars, eqIdcs;
      BackendDAE.ExternalObjectClasses eoc;
      list<SimCodeVar.SimVar> simVarsDisc;
      list<SimCode.SimEqSystem> discEqs;
      list<Integer>    rf, tf;
      SimCode.SimEqSystem equation_;
      BackendDAE.IncidenceMatrix  m;
      BackendDAE.IncidenceMatrixT  mt;
      BackendDAE.StrongComponent comp, comp1;
      Integer index, uniqueEqIndex, uniqueEqIndexMapping;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      String msg;
      list<SimCodeVar.SimVar> tempvars;
      list<tuple<Integer, list<Integer>>> eqnvartpllst;
      Boolean b;
      list<tuple<Integer,Integer>> tmpEqSccMapping;
      BackendDAE.ExtraInfo ei;
      BackendDAE.Jacobian jacobian;
      SimCode.BackendMapping tmpBackendMapping;
      Boolean mixedSystem;
      BackendDAE.TearingSet strictTearingSet;
      Option<BackendDAE.TearingSet> casualTearingSet;
      Boolean partOfJac;

    // EQUATIONSYSTEM: continuous system of equations
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns),
          BackendDAE.SHARED(globalKnownVars=globalKnownVars, functionTree=funcs, info = ei),
          comp as BackendDAE.EQUATIONSYSTEM(eqns=eqIdcs,jac=jacobian,jacType=jac_tp, mixedSystem=mixedSystem))
      equation
        if Flags.isSet(Flags.FAILTRACE) then
          Debug.trace("function createOdeSystem create continuous system.\n");
        end if;
        if Flags.isSet(Flags.GRAPHML) then
          BackendDump.dumpBipartiteGraphStrongComponent1(inComp,BackendEquation.equationList(eqns),BackendVariable.varList(vars), SOME(BackendDAEUtil.getFunctions(ishared)),"BIPARITEGRPAH_LS_"+intString(iuniqueEqIndex));
        end if;

        // print("\ncreateOdeSystem -> Cont sys: ...\n");
        // extract the variables and equations of the block.
        (eqn_lst, var_lst,_) = BackendDAETransform.getEquationAndSolvedVar(comp, eqns, vars);
        // BackendDump.printEquationList(eqn_lst);
        // BackendDump.dumpVarList(var_lst, "var_lst");
        eqn_lst = BackendEquation.replaceDerOpInEquationList(eqn_lst);
        // States are solved for der(x) not x.
        var_lst_1 = List.map(var_lst, BackendVariable.transformXToXd);
        vars_1 = BackendVariable.listVar1(var_lst_1);
        eqns_1 = BackendEquation.listEquation(eqn_lst);
        partOfJac = BackendDAEUtil.isJacobianDAE(ishared);
        (equations_, uniqueEqIndex, tempvars) = createOdeSystem2(false, vars_1, globalKnownVars, eqns_1, jacobian, jac_tp, funcs, vars, iuniqueEqIndex, ei, mixedSystem, partOfJac, itempvars);
        uniqueEqIndexMapping = uniqueEqIndex-1; //a system with this index is created that contains all the equations with the indeces from iuniqueEqIndex to uniqueEqIndex-2
        //tmpEqSccMapping = appendSccIdxRange(iuniqueEqIndex, uniqueEqIndex - 1, isccIndex, ieqSccMapping);
        tmpEqSccMapping = appendSccIdxRange(uniqueEqIndexMapping, uniqueEqIndex - 1, isccIndex, ieqSccMapping);
        tmpBackendMapping = setEqMapping(List.intRange2(uniqueEqIndexMapping, uniqueEqIndex - 1),eqIdcs,iBackendMapping);
      then (equations_, equations_, uniqueEqIndex, tempvars, tmpEqSccMapping, tmpBackendMapping);

    // TORNSYSTEM
    case (BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _, BackendDAE.TORNSYSTEM(strictTearingSet, casualTearingSet, linear=b, mixedSystem=mixedSystem))
      equation
        if Flags.isSet(Flags.GRAPHML) then
          BackendDump.dumpBipartiteGraphStrongComponent1(inComp,BackendEquation.equationList(eqns),BackendVariable.varList(vars), SOME(BackendDAEUtil.getFunctions(ishared)),"BIPARITEGRPAH_TS_"+intString(iuniqueEqIndex));
        end if;

        (equations_, uniqueEqIndex, tempvars) = createTornSystem(b, skipDiscInAlgorithm, genDiscrete, strictTearingSet, casualTearingSet, isyst, ishared, iuniqueEqIndex, mixedSystem, itempvars);
        tmpEqSccMapping = appendSccIdx(uniqueEqIndex-1, isccIndex, ieqSccMapping);
        tmpBackendMapping = iBackendMapping;
      then (equations_, equations_, uniqueEqIndex, tempvars, tmpEqSccMapping, tmpBackendMapping);

    else
      equation
        msg = "function createOdeSystem failed for component " + BackendDump.strongComponentString(inComp);
        Error.addInternalError(msg, sourceInfo());
      then fail();
  end matchcontinue;
end createOdeSystem;

protected function createOdeSystem2
  input Boolean mixedEvent "true if generating the mixed system event code";
  input BackendDAE.Variables inVars;
  input BackendDAE.Variables inKnVars;
  input BackendDAE.EquationArray inEquationArray;
  input BackendDAE.Jacobian inJacobian;
  input BackendDAE.JacobianType inJacobianType;
  input DAE.FunctionTree inFuncs;
  input BackendDAE.Variables inAllVars;
  input Integer iuniqueEqIndex;
  input BackendDAE.ExtraInfo iei;
  input Boolean mixedSystem;
  input Boolean partOfJac;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (equations_, ouniqueEqIndex, otempvars) := matchcontinue (inJacobian, inJacobianType)
    local
      Integer uniqueEqIndex;
      list<BackendDAE.Equation> eqn_lst;
      list<DAE.ComponentRef> crefs;
      list<SimCode.SimEqSystem> resEqs;
      list<SimCodeVar.SimVar> simVars;
      list<DAE.Exp> beqs;
      list<tuple<Integer, Integer, BackendDAE.Equation>> jac;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      Integer linInfo;
      list<list<Real>> jacVals;
      list<Real> rhsVals, solvedVals;
      list<DAE.ElementSource> sources;
      list<DAE.ComponentRef> names;
      list<SimCodeVar.SimVar> tempvars;
      String str;
      Option<SimCode.JacobianMatrix> jacobianMatrix;
      Boolean homotopySupport;

    // constant jacobians. Linear system of equations (A x = b) where
    // A and b are constants. TODO: implement symbolic gaussian elimination
    // here. Currently uses dgesv as for next case
    case (BackendDAE.FULL_JACOBIAN(SOME(jac)), BackendDAE.JAC_CONSTANT()) equation
      if Flags.isSet(Flags.FAILTRACE) then
        Debug.trace("function createOdeSystem2 create linear system(const jacobian).\n");
      end if;
      ((simVars, _)) = BackendVariable.traverseBackendDAEVars(inVars, traversingdlowvarToSimvar, ({}, inKnVars));
      simVars = listReverse(simVars);
      (beqs, sources) = BackendDAEUtil.getEqnSysRhs(inEquationArray, inVars, SOME(inFuncs));
      beqs = listReverse(beqs);
      rhsVals = ValuesUtil.valueReals(List.map(beqs, Ceval.cevalSimple));
      jacVals = SymbolicJacobian.evaluateConstantJacobian(listLength(simVars), jac);
      (solvedVals, linInfo) = System.dgesv(jacVals, rhsVals);
      names = List.map(simVars, varName);
      checkLinearSystem(linInfo, names, jacVals, rhsVals);
      // TODO: Move these to known vars :/ This is done in the wrong phase of the compiler... Also, if done as an optimization module, we can optimize more!
      sources = List.map1(sources, ElementSource.addSymbolicTransformation, DAE.LINEAR_SOLVED(names, jacVals, rhsVals, solvedVals));
      (equations_, uniqueEqIndex) = List.thread3MapFold(simVars, solvedVals, sources, generateSolvedEquation, iuniqueEqIndex);
    then (equations_, uniqueEqIndex, itempvars);

    // Time varying linear jacobian. Linear system of equations that needs to be solved during runtime.
    case (BackendDAE.FULL_JACOBIAN(SOME(jac)), BackendDAE.JAC_LINEAR()) equation
      if Flags.isSet(Flags.FAILTRACE) then
        Debug.trace("function createOdeSystem2 create linear system with jacobian.\n");
      end if;
      ((simVars, _)) = BackendVariable.traverseBackendDAEVars(inVars, traversingdlowvarToSimvar, ({}, inKnVars));
      simVars = listReverse(simVars);
      (beqs, sources) = BackendDAEUtil.getEqnSysRhs(inEquationArray, inVars, SOME(inFuncs));
      beqs = listReverse(beqs);
      simJac = List.map1(jac, jacToSimjac, inVars);
      if (Config.simCodeTarget() == "Cpp" or Config.simCodeTarget() == "omsicpp") then
        simJac = List.sort(simJac,simJacCSRToCSC);
      end if;

    then ({SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(iuniqueEqIndex, mixedEvent, false, simVars, beqs, simJac, {}, NONE(), sources, 0, inVars.numberOfVars, partOfJac), NONE(), BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, iuniqueEqIndex+1, itempvars);

    // Time varying nonlinear jacobian. Non-linear system of equations.
    case (_, BackendDAE.JAC_GENERIC()) equation
      if Flags.isSet(Flags.FAILTRACE) then
        Debug.trace("function createOdeSystem2 create non-linear system with jacobian.");
      end if;
      eqn_lst = BackendEquation.equationList(inEquationArray);
      crefs = BackendVariable.getAllCrefFromVariables(inVars);

      (resEqs, uniqueEqIndex, tempvars) = createNonlinearResidualEquations(eqn_lst, iuniqueEqIndex, itempvars, inFuncs);
      // create symbolic jacobian for simulation
      (jacobianMatrix, uniqueEqIndex, tempvars) = createSymbolicSimulationJacobian(inJacobian, uniqueEqIndex, tempvars);
      (_, homotopySupport) = BackendEquation.traverseExpsOfEquationList(eqn_lst, BackendDAEUtil.containsHomotopyCall, false);
    then ({SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(uniqueEqIndex, resEqs, crefs, 0, inVars.numberOfVars+listLength(tempvars)-listLength(itempvars), jacobianMatrix, homotopySupport, mixedSystem, false), NONE(), BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, uniqueEqIndex+1, tempvars);

    // No analytic jacobian available. Generate non-linear system.
    case (_, _) equation
      if Flags.isSet(Flags.FAILTRACE) then
        Debug.trace("function createOdeSystem2 create non-linear system without jacobian.");
      end if;
      eqn_lst = BackendEquation.equationList(inEquationArray);
      crefs = BackendVariable.getAllCrefFromVariables(inVars);
      (resEqs, uniqueEqIndex, tempvars) = createNonlinearResidualEquations(eqn_lst, iuniqueEqIndex, itempvars, inFuncs);
      (_, homotopySupport) = BackendEquation.traverseExpsOfEquationList(eqn_lst, BackendDAEUtil.containsHomotopyCall, false);
    then ({SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(uniqueEqIndex, resEqs, crefs, 0, inVars.numberOfVars+listLength(tempvars)-listLength(itempvars), NONE(), homotopySupport, mixedSystem, false), NONE(), BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, uniqueEqIndex+1, tempvars);

    // failure
    else equation
      str = BackendDump.jacobianTypeStr(inJacobianType);
      str = stringAppendList({"createOdeSystem2 failed for ", str});
      Error.addInternalError(str, sourceInfo());
    then fail();
  end matchcontinue;
end createOdeSystem2;

protected function checkLinearSystem
  input Integer info;
  input list<DAE.ComponentRef> vars;
  input list<list<Real>> jac;
  input list<Real> rhs;
algorithm
  _ := matchcontinue (info, vars, jac, rhs)
    local
      String infoStr, syst, varnames, varname, rhsStr, jacStr;
    case (0, _, _, _) then ();
    case (_, _, _, _)
      equation
        true = info > 0;
        varname = ComponentReference.printComponentRefStr(listGet(vars, info));
        infoStr = intString(info);
        varnames = stringDelimitList(List.map(vars, ComponentReference.printComponentRefStr), " ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString), " ;\n  ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac, realString), stringDelimitList, " , "), " ;\n  ");
        syst = stringAppendList({"\n[\n  ", jacStr, "\n]\n  *\n[\n  ", varnames, "\n]\n  =\n[\n  ", rhsStr, "\n]"});
        Error.addMessage(Error.LINEAR_SYSTEM_SINGULAR, {syst, infoStr, varname});
      then fail();
    case (_, _, _, _)
      equation
        true = info < 0;
        varnames = stringDelimitList(List.map(vars, ComponentReference.printComponentRefStr), " ;\n  ");
        rhsStr = stringDelimitList(List.map(rhs, realString), " ; ");
        jacStr = stringDelimitList(List.map1(List.mapList(jac, realString), stringDelimitList, " , "), " ; ");
        syst = stringAppendList({"[", jacStr, "] * [", varnames, "] = [", rhsStr, "]"});
        Error.addMessage(Error.LINEAR_SYSTEM_INVALID, {"LAPACK/dgesv", syst});
      then fail();
  end matchcontinue;
end checkLinearSystem;

protected function generateSolvedEquation
  input SimCodeVar.SimVar var;
  input Real val;
  input DAE.ElementSource source;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem eq;
  output Integer ouniqueEqIndex;
protected
  DAE.ComponentRef name;
algorithm
  SimCodeVar.SIMVAR(name=name) := var;
  eq := SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex, name, DAE.RCONST(val), source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
  ouniqueEqIndex := iuniqueEqIndex+1;
end generateSolvedEquation;

protected function createTornSystem
  input Boolean linear;
  input Boolean skipDiscInAlgorithm "if true skip discrete algorithm vars";
  input Boolean genDiscrete;
  input BackendDAE.TearingSet strictTearingSet;
  input Option<BackendDAE.TearingSet> casualTearingSet;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer iuniqueEqIndex;
  input Boolean mixedSystem;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
   (equations_, ouniqueEqIndex, otempvars) := match(linear, isyst, ishared)
     local
       list<BackendDAE.Var> tvars;
       list<BackendDAE.Equation> reqns;
       BackendDAE.Variables vars, globalKnownVars;
       BackendDAE.EquationArray eqns;
       list<SimCodeVar.SimVar> tempvars, tempvars2, simVars;
       list<SimCode.SimEqSystem> simequations, resEqs;
       Integer uniqueEqIndex, nInnerVars;
       list<DAE.ComponentRef> tcrs;
       Option<SimCode.JacobianMatrix> jacobianMatrix;
       list<Integer> tearingVars, residualEqns;
       Boolean homotopySupport;
       BackendDAE.InnerEquations innerEquations;
       BackendDAE.Jacobian inJacobian;
       SimCode.LinearSystem lSystem;
       SimCode.NonlinearSystem nlSystem;
       Option<SimCode.LinearSystem> alternativeTearingL;
       Option<SimCode.NonlinearSystem> alternativeTearingNl;
       BackendDAE.BackendDAEType backendDAEType;
       Boolean partOfJac;

     // CASE: linear
     case(true, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), BackendDAE.SHARED(globalKnownVars=globalKnownVars)) equation
       BackendDAE.TEARINGSET(tearingvars=tearingVars, residualequations=residualEqns, innerEquations=innerEquations, jac=inJacobian) = strictTearingSet;

       if not SymbolicJacobian.isJacobianGeneric(inJacobian) then
         Error.addMessage(Error.NO_JACONIAN_TORNLINEAR_SYSTEM, {});
         fail();
       end if;

       // get tearing vars
       tvars = List.map1r(tearingVars, BackendVariable.getVarAt, vars);
       tvars = List.map(tvars, BackendVariable.transformXToXd);
       ((simVars, _)) = List.fold(tvars, traversingdlowvarToSimvarFold, ({}, globalKnownVars));
       simVars = listReverse(simVars);

       // get residual eqns
       reqns = BackendEquation.getList(residualEqns, eqns);
       reqns = BackendEquation.replaceDerOpInEquationList(reqns);
       // generate other equations
       (simequations, uniqueEqIndex, tempvars, nInnerVars, _) = createTornSystemInnerEqns(innerEquations, skipDiscInAlgorithm, genDiscrete, isyst, ishared, iuniqueEqIndex, itempvars, {});
       (resEqs, uniqueEqIndex, tempvars) = createNonlinearResidualEquations(reqns, uniqueEqIndex, tempvars, ishared.functionTree);
       simequations = listAppend(simequations, resEqs);

       (jacobianMatrix, uniqueEqIndex, tempvars) = createSymbolicSimulationJacobian(inJacobian, uniqueEqIndex, tempvars);
       partOfJac = BackendDAEUtil.isJacobianDAE(ishared);
       lSystem = SimCode.LINEARSYSTEM(uniqueEqIndex, false, true, simVars, {}, {}, simequations, jacobianMatrix, {}, 0, listLength(tvars)+nInnerVars+listLength(tempvars)-listLength(itempvars), partOfJac);
       tempvars2 = tempvars;

       // Do if dynamic tearing is activated
       if Util.isSome(casualTearingSet) then
         SOME(BackendDAE.TEARINGSET(tearingvars=tearingVars, residualequations=residualEqns, innerEquations=innerEquations, jac=inJacobian)) = casualTearingSet;
         // get tearing vars
         tvars = List.map1r(tearingVars, BackendVariable.getVarAt, vars);
         tvars = List.map(tvars, BackendVariable.transformXToXd);
         ((simVars, _)) = List.fold(tvars, traversingdlowvarToSimvarFold, ({}, globalKnownVars));
         simVars = listReverse(simVars);

         // get residual eqns
         reqns = BackendEquation.getList(residualEqns, eqns);
         reqns = BackendEquation.replaceDerOpInEquationList(reqns);
         // generate other equations
         (simequations, uniqueEqIndex, tempvars2, nInnerVars, _) = createTornSystemInnerEqns(innerEquations, skipDiscInAlgorithm, genDiscrete, isyst, ishared, uniqueEqIndex+1, tempvars, {});
         (resEqs, uniqueEqIndex, tempvars2) = createNonlinearResidualEquations(reqns, uniqueEqIndex, tempvars2, ishared.functionTree);
         simequations = listAppend(simequations, resEqs);

         (jacobianMatrix, uniqueEqIndex, tempvars2) = createSymbolicSimulationJacobian(inJacobian, uniqueEqIndex, tempvars2);
         alternativeTearingL = SOME(SimCode.LINEARSYSTEM(uniqueEqIndex, false, true, simVars, {}, {}, simequations, jacobianMatrix, {}, 0, listLength(tvars)+nInnerVars+listLength(tempvars2)-listLength(tempvars), partOfJac));

       else
         alternativeTearingL = NONE();
       end if;
     then ({SimCode.SES_LINEAR(lSystem, alternativeTearingL, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, uniqueEqIndex+1, tempvars2);

     // CASE: nonlinear
     case(false, BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns), _) equation
       BackendDAE.TEARINGSET(tearingvars=tearingVars, residualequations=residualEqns, innerEquations=innerEquations, jac=inJacobian) = strictTearingSet;
       // get tearing vars
       tvars = List.map1r(tearingVars, BackendVariable.getVarAt, vars);
       tvars = List.map(tvars, BackendVariable.transformXToXd);

       // get residual eqns
       reqns = BackendEquation.getList(residualEqns, eqns);
       reqns = BackendEquation.replaceDerOpInEquationList(reqns);
       // generate residual replacements
       tcrs = List.map(tvars, BackendVariable.varCref);
       // generate other equations
       (simequations, uniqueEqIndex, tempvars, nInnerVars, homotopySupport) = createTornSystemInnerEqns(innerEquations, skipDiscInAlgorithm, genDiscrete, isyst, ishared, iuniqueEqIndex, itempvars, {});
       (resEqs, uniqueEqIndex, tempvars) = createNonlinearResidualEquations(reqns, uniqueEqIndex, tempvars, ishared.functionTree);
       simequations = listAppend(simequations, resEqs);

       (jacobianMatrix, uniqueEqIndex, tempvars) = createSymbolicSimulationJacobian(inJacobian, uniqueEqIndex, tempvars);
       if not homotopySupport then
         (_, homotopySupport) = BackendEquation.traverseExpsOfEquationList(reqns, BackendDAEUtil.containsHomotopyCall, false);
       end if;

       nlSystem = SimCode.NONLINEARSYSTEM(uniqueEqIndex, simequations, tcrs, 0, listLength(tvars)+nInnerVars+listLength(tempvars)-listLength(itempvars), jacobianMatrix, homotopySupport, mixedSystem, true);
       tempvars2 = tempvars;

       // Do if dynamic tearing is activated
       if Util.isSome(casualTearingSet) then
         SOME(BackendDAE.TEARINGSET(tearingvars=tearingVars, residualequations=residualEqns, innerEquations=innerEquations, jac=inJacobian)) = casualTearingSet;
         // get tearing vars
         tvars = List.map1r(tearingVars, BackendVariable.getVarAt, vars);
         tvars = List.map(tvars, BackendVariable.transformXToXd);

         // get residual eqns
         reqns = BackendEquation.getList(residualEqns, eqns);
         reqns = BackendEquation.replaceDerOpInEquationList(reqns);
         // generate residual replacements
         tcrs = List.map(tvars, BackendVariable.varCref);
         // generate other equations
         (simequations, uniqueEqIndex, tempvars2, nInnerVars, homotopySupport) = createTornSystemInnerEqns(innerEquations, skipDiscInAlgorithm, genDiscrete, isyst, ishared, uniqueEqIndex+1, tempvars, {});
         (resEqs, uniqueEqIndex, tempvars2) = createNonlinearResidualEquations(reqns, uniqueEqIndex, tempvars2, ishared.functionTree);
         simequations = listAppend(simequations, resEqs);

         (jacobianMatrix, uniqueEqIndex, tempvars2) = createSymbolicSimulationJacobian(inJacobian, uniqueEqIndex, tempvars2);
         if not homotopySupport then
           (_, homotopySupport) = BackendEquation.traverseExpsOfEquationList(reqns, BackendDAEUtil.containsHomotopyCall, false);
         end if;

         alternativeTearingNl = SOME(SimCode.NONLINEARSYSTEM(uniqueEqIndex, simequations, tcrs, 0, listLength(tvars)+nInnerVars+listLength(tempvars2)-listLength(tempvars), jacobianMatrix, homotopySupport, mixedSystem, true));
       else
         alternativeTearingNl = NONE();
       end if;
     then ({SimCode.SES_NONLINEAR(nlSystem, alternativeTearingNl, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)}, uniqueEqIndex+1, tempvars2);
   end match;
end createTornSystem;

protected function solveInnerEquations "author: Frenkel TUD 2011-05
  try to solve the equations"
  input BackendDAE.InnerEquations innerEquations;
  input BackendDAE.EquationArray inEqns;
  input BackendDAE.Variables inVars;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  outRepl := match (innerEquations, inEqns, inVars, ishared, inRepl)
    local
      BackendDAE.InnerEquations rest;
      Integer v, e;
      DAE.Exp e1, e2, varexp, expr;
      DAE.ComponentRef cr, dcr;
      DAE.ElementSource source;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Var var;
      list<BackendDAE.Var> otherVars, varlst;
      list<Integer> ds, vlst;
      list<DAE.Exp> explst1, explst2;
      BackendDAE.Equation eqn;
      list<list<DAE.Subscript>> subslst;
      DAE.FunctionTree funcs;

    case ({}, _, _, _, _) then inRepl;
    case (BackendDAE.INNEREQUATION(eqn=e, vars={v})::rest, _, _, _, _)
      equation
        (BackendDAE.EQUATION(exp=e1, scalar=e2)) = BackendEquation.get(inEqns, e);
        (var as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(inVars, v);
        varexp = Expression.crefExp(cr);
        varexp = if BackendVariable.isStateVar(var) then Expression.expDer(varexp) else varexp;
        BackendDAE.SHARED(functionTree = funcs) = ishared;
        (expr, {}, {}, {}) = ExpressionSolve.solve2(e1, e2, varexp, SOME(funcs), NONE(), true, BackendDAEUtil.isSimulationDAE(ishared));
        dcr = if BackendVariable.isStateVar(var) then ComponentReference.crefPrefixDer(cr) else cr;
        repl = BackendVarTransform.addReplacement(inRepl, dcr, expr, SOME(BackendVarTransform.skipPreOperator));
        repl = if BackendVariable.isStateVar(var) then BackendVarTransform.addDerConstRepl(cr, expr, repl) else repl;
        // BackendDump.debugStrCrefStrExpStr(("", cr, " := ", expr, "\n"));
      then
        solveInnerEquations(rest, inEqns, inVars, ishared, repl);
    case (BackendDAE.INNEREQUATION(eqn=e, vars=vlst)::rest, _, _, _, _)
      equation
        (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1, right=e2)) = BackendEquation.get(inEqns, e);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
        subslst = Expression.dimensionSizesSubscripts(ds);
        subslst = Expression.rangesToSubscripts(subslst);
        explst1 = List.map1r(subslst, Expression.applyExpSubscripts, e1);
        explst1 = ExpressionSimplify.simplifyList(explst1);
        explst2 = List.map1r(subslst, Expression.applyExpSubscripts, e2);
        explst2 = ExpressionSimplify.simplifyList(explst2);
        repl = solveInnerEquations1(explst1, explst2, varlst, inVars, ishared, inRepl);
      then
        solveInnerEquations(rest, inEqns, inVars, ishared, repl);
     case (BackendDAE.INNEREQUATIONCONSTRAINTS(eqn=e, vars={v})::rest, _, _, _, _)
      equation
        (BackendDAE.EQUATION(exp=e1, scalar=e2)) = BackendEquation.get(inEqns, e);
        (var as BackendDAE.VAR(varName=cr)) = BackendVariable.getVarAt(inVars, v);
        varexp = Expression.crefExp(cr);
        varexp = if BackendVariable.isStateVar(var) then Expression.expDer(varexp) else varexp;
        BackendDAE.SHARED(functionTree = funcs) = ishared;
        (expr, {}, {}, {}) = ExpressionSolve.solve2(e1, e2, varexp, SOME(funcs), NONE(), true, BackendDAEUtil.isSimulationDAE(ishared));
        dcr = if BackendVariable.isStateVar(var) then ComponentReference.crefPrefixDer(cr) else cr;
        repl = BackendVarTransform.addReplacement(inRepl, dcr, expr, SOME(BackendVarTransform.skipPreOperator));
        repl = if BackendVariable.isStateVar(var) then BackendVarTransform.addDerConstRepl(cr, expr, repl) else repl;
        // BackendDump.debugStrCrefStrExpStr(("", cr, " := ", expr, "\n"));
      then
        solveInnerEquations(rest, inEqns, inVars, ishared, repl);
     case (BackendDAE.INNEREQUATIONCONSTRAINTS(eqn=e, vars=vlst)::rest, _, _, _, _)
      equation
        (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1, right=e2)) = BackendEquation.get(inEqns, e);
        varlst = List.map1r(vlst, BackendVariable.getVarAt, inVars);
        subslst = Expression.dimensionSizesSubscripts(ds);
        subslst = Expression.rangesToSubscripts(subslst);
        explst1 = List.map1r(subslst, Expression.applyExpSubscripts, e1);
        explst1 = ExpressionSimplify.simplifyList(explst1);
        explst2 = List.map1r(subslst, Expression.applyExpSubscripts, e2);
        explst2 = ExpressionSimplify.simplifyList(explst2);
        repl = solveInnerEquations1(explst1, explst2, varlst, inVars, ishared, inRepl);
      then
        solveInnerEquations(rest, inEqns, inVars, ishared, repl);
  end match;
end solveInnerEquations;

protected function solveInnerEquations1 "author: Frenkel TUD 2011-05
  try to solve the equations"
  input list<DAE.Exp> iExps1;
  input list<DAE.Exp> iExps2;
  input list<BackendDAE.Var> iVars;
  input BackendDAE.Variables inVars;
  input BackendDAE.Shared ishared;
  input BackendVarTransform.VariableReplacements inRepl;
  output BackendVarTransform.VariableReplacements outRepl;
algorithm
  outRepl :=
  match (iExps1, iExps2, iVars, inVars, ishared, inRepl)
    local
      DAE.Exp e1, e2, varexp, expr;
      DAE.ComponentRef cr, dcr;
      BackendVarTransform.VariableReplacements repl;
      BackendDAE.Var var;
      list<BackendDAE.Var> otherVars, rest;
      list<DAE.Exp> explst1, explst2;
      DAE.FunctionTree funcs;
    case ({}, _, _, _, _, _) then inRepl;
    case (e1::explst1, e2::explst2, (var as BackendDAE.VAR(varName=cr))::rest, _, _, _)
      equation
        varexp = Expression.crefExp(cr);
        varexp = if BackendVariable.isStateVar(var) then Expression.expDer(varexp) else varexp;
        BackendDAE.SHARED(functionTree = funcs) = ishared;
        (expr, {}, {}, {}) = ExpressionSolve.solve2(e1, e2, varexp, SOME(funcs), NONE(), true, BackendDAEUtil.isSimulationDAE(ishared));
        dcr = if BackendVariable.isStateVar(var) then ComponentReference.crefPrefixDer(cr) else cr;
        repl = BackendVarTransform.addReplacement(inRepl, dcr, expr, SOME(BackendVarTransform.skipPreOperator));
        repl = if BackendVariable.isStateVar(var) then BackendVarTransform.addDerConstRepl(cr, expr, repl) else repl;
        // BackendDump.debugStrCrefStrExpStr(("", cr, " := ", expr, "\n"));
      then
        solveInnerEquations1(explst1, explst2, rest, inVars, ishared, repl);
  end match;
end solveInnerEquations1;

protected function createTornSystemInnerEqns
  input BackendDAE.InnerEquations innerEquations;
  input Boolean skipDiscInAlgorithm "if true skip discrete algorithm vars";
  input Boolean genDiscrete;
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared ishared;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input list<SimCode.SimEqSystem> isimequations;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex = iuniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars = itempvars;
  output Integer nVars = 0;
  output Boolean homotopySupport = false;
protected
  BackendDAE.EquationArray eqns;
  Integer eqnindx;
  list<Integer> vars;
  BackendDAE.Equation eqn;
  BackendDAE.StrongComponent comp;
  list<SimCode.SimEqSystem> simequations;
  DoubleEndedList<SimCode.SimEqSystem> equations;
  BackendDAE.Constraints cons;
algorithm
  if listEmpty(innerEquations) then
    equations_ := isimequations;
    return;
  end if;

  BackendDAE.EQSYSTEM(orderedEqs = eqns) := isyst;
  equations := DoubleEndedList.fromList(isimequations);

  for eq in innerEquations loop
    // get Eqn
    (eqnindx, vars, cons) := BackendDAEUtil.getEqnAndVarsFromInnerEquation(eq);
    nVars := nVars + listLength(vars);
    eqn := BackendEquation.get(eqns, eqnindx);
    if not homotopySupport then
      (_, homotopySupport) := BackendEquation.traverseExpsOfEquation(eqn, BackendDAEUtil.containsHomotopyCall, false);
    end if;
    // generate comp
    comp := createTornSystemInnerEqns1(eqn, eqnindx, vars);
    (simequations, _, ouniqueEqIndex, otempvars) := createEquationsWork(genDiscrete, false, genDiscrete, skipDiscInAlgorithm, isyst, ishared, comp, ouniqueEqIndex, otempvars, cons);
    DoubleEndedList.push_list_back(equations, simequations);
  end for;

  equations_ := DoubleEndedList.toListAndClear(equations);
end createTornSystemInnerEqns;

protected function createTornSystemInnerEqns1
  input BackendDAE.Equation eqn;
  input Integer eqnindx;
  input list<Integer> varindx;
  output BackendDAE.StrongComponent ocomp;
algorithm
  ocomp := match(eqn, eqnindx, varindx)
    local
      Integer v;
    case (BackendDAE.EQUATION(), _, v::{})
      then
        BackendDAE.SINGLEEQUATION(eqnindx, v);

    case (BackendDAE.RESIDUAL_EQUATION(), _, v::{})
      then
        BackendDAE.SINGLEEQUATION(eqnindx, v);

    case (BackendDAE.SOLVED_EQUATION(), _, v::{})
      then
        BackendDAE.SINGLEEQUATION(eqnindx, v);

    case (BackendDAE.ARRAY_EQUATION(), _, _)
      then
        BackendDAE.SINGLEARRAY(eqnindx, varindx);

    case (BackendDAE.IF_EQUATION(), _, _)
      then
        BackendDAE.SINGLEIFEQUATION(eqnindx, varindx);

    case (BackendDAE.ALGORITHM(), _, _)
      then
        BackendDAE.SINGLEALGORITHM(eqnindx, varindx);

    case (BackendDAE.COMPLEX_EQUATION(), _, _)
      then
        BackendDAE.SINGLECOMPLEXEQUATION(eqnindx, varindx);

    case (BackendDAE.WHEN_EQUATION(), _, _)
      then
        BackendDAE.SINGLEWHENEQUATION(eqnindx, varindx);

    else
      equation
        print("SimCodeUtil.createTornSystemInnerEqns1 failed for\n");
        BackendDump.printEquationList({eqn});
        print("Eqn: " + intString(eqnindx) + " Vars: " + stringDelimitList(List.map(varindx, intString), ", ") + "\n");
      then
        fail();
  end match;
end createTornSystemInnerEqns1;

// =============================================================================
// section to create equations for omsi functions
//
// =============================================================================

protected function createAllEquationOMSI
  "fills SimCode.OMSIFunction with equations and variables"
  input BackendDAE.EqSystems constSysts;
  input BackendDAE.Shared shared;
  input list<BackendDAE.ZeroCrossing> inZeroCrossings;
  output SimCode.OMSIFunction omsiAllEquations = SimCode.emptyOMSIFunction;
  input output Integer uniqueEqIndex;
protected
  BackendDAE.StrongComponents components;
  list<BackendDAE.Equation> eqnlst;
  list<BackendDAE.Var> varlst;
  BackendDAE.Equation eqn;
  BackendDAE.Var var;

  SimCode.OMSIFunction newAllEquations;
algorithm
  // Add empty hash table to omsiAllEquations
  omsiAllEquations.context := SimCodeFunction.OMSI_CONTEXT(SOME(HashTableCrefSimVar.emptyHashTableSized(1013)));

  for constSyst in constSysts loop
    try
      BackendDAE.MATCHING(comps=components) := constSyst.matching;
    else
      Error.addInternalError("The matching information is missing in function createAllEquationOMSI!", sourceInfo());
      fail();
    end try;

    (newAllEquations, uniqueEqIndex) := generateEquationsForComponents(components, constSyst, shared, uniqueEqIndex);

    // Update omsiAllEquations
    omsiAllEquations := appendOMSIFunction(omsiAllEquations, newAllEquations);
  end for;

end createAllEquationOMSI;


function generateEquationsForComponents
  "generates equations and variables for independent system of equations for
  SimCode.OMSIFunction"
  input BackendDAE.StrongComponents components;
  input BackendDAE.EqSystem constSyst;
  input BackendDAE.Shared shared;
  output SimCode.OMSIFunction omsiFuncEquations;
  input output Integer uniqueEqIndex;
protected
  list<SimCode.SimEqSystem> equations = {};
  list<SimCodeVar.SimVar> inputVars = {};
  list<SimCodeVar.SimVar> outputVars = {};
  list<SimCodeVar.SimVar> innerVars = {};
  HashTableCrefSimVar.HashTable hashTable;
  list<SimCode.SimEqSystem> tmpEqns = {};
  list<SimCodeVar.SimVar> tmpInputVars = {}, tmpOutputVars = {}, tmpInnerVars = {};
  list<SimCodeVar.SimVar> tempVars;
  Integer nAlgebraicSystems = 0;
  Integer index, nAllVars = 0;
  Boolean debug=false;
algorithm
  for component in components loop
    tmpEqns := {};
    tmpInputVars := {}; tmpOutputVars := {}; tmpInnerVars := {};
    () := match(component)
    local
      BackendDAE.Equation eqn;
      BackendDAE.Var var;

      BackendDAE.Jacobian jacobian;
      BackendDAE.JacobianType jacobianType;
      BackendDAE.InnerEquations innerEquations;
      list<Integer> tearingVars, residualEqns;
      list<BackendDAE.Var> tvars, varlst;
      list<SimCodeVar.SimVar> loopIterationVars, loopSolvedVars;
      list<BackendDAE.Equation> reqns, eqnlst;
      SimCode.SimEqSystem algSystem;
      list<SimCode.SimEqSystem> resEqs, simequations;
      SimCode.OMSIFunction omsiFunction;
      Boolean linear, mixedSystem;
      Option<SimCode.DerivativeMatrix> derivativeMatrix;
      Integer algEqIndex;

      list<Integer> eqns;
      list<Integer> variables;

    // case for singele equations
    case BackendDAE.SINGLEEQUATION() equation
      ({eqn}, {var}, _) = BackendDAETransform.getEquationAndSolvedVar(component, constSyst.orderedEqs, constSyst.orderedVars);
      (tmpEqns, tmpInputVars, tmpOutputVars, tmpInnerVars, uniqueEqIndex) =
        generateSingleEquation(eqn, var, shared.functionTree, uniqueEqIndex);
    then ();

    // case for singe when equations
    case BackendDAE.SINGLEWHENEQUATION() equation
      (eqnlst, varlst, _) = BackendDAETransform.getEquationAndSolvedVar(component, constSyst.orderedEqs, constSyst.orderedVars);
      (tmpEqns, tmpInputVars, tmpOutputVars, tmpInnerVars, uniqueEqIndex) =
        generateSingleEquation(listHead(eqnlst), listHead(varlst), shared.functionTree, uniqueEqIndex);
    then();

    // case for single comlpex equation
    case BackendDAE.SINGLECOMPLEXEQUATION() equation
      (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(component, constSyst.orderedEqs, constSyst.orderedVars);
      // States are solved for der(x) not x.
      varlst = List.map(varlst, BackendVariable.transformXToXd);
      (tmpEqns, uniqueEqIndex, _) = createSingleComplexEqnCode(listHead(eqnlst), varlst, uniqueEqIndex, {}, shared.info, true, shared.functionTree);
    then();

    // case for single algorithm equation
    case BackendDAE.SINGLEALGORITHM() equation
      (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(component, constSyst.orderedEqs, constSyst.orderedVars);
      varlst = List.map(varlst, BackendVariable.transformXToXd);
      (tmpEqns, uniqueEqIndex) = createSingleAlgorithmCode(eqnlst, varlst, false, uniqueEqIndex);
    then();

    // case for single algorithm equation
    case BackendDAE.SINGLEARRAY() equation
      (eqnlst, varlst,_) = BackendDAETransform.getEquationAndSolvedVar(component, constSyst.orderedEqs, constSyst.orderedVars);
      varlst = List.map(varlst, BackendVariable.transformXToXd);
      (tmpEqns, _, uniqueEqIndex, _) = createSingleArrayEqnCode(true, eqnlst, varlst, uniqueEqIndex, {}, shared);
    then();

    // case for torn systems of equations
    case BackendDAE.TORNSYSTEM(strictTearingSet =
           BackendDAE.TEARINGSET(tearingvars=tearingVars, residualequations=residualEqns, innerEquations=innerEquations, jac=jacobian),
           linear = linear, mixedSystem = mixedSystem)
    algorithm
      if not SymbolicJacobian.isJacobianGeneric(jacobian) and linear then
        Error.addMessage(Error.NO_JACONIAN_TORNLINEAR_SYSTEM, {});
        fail();
      end if;
      algEqIndex := uniqueEqIndex;
      uniqueEqIndex := uniqueEqIndex+1;
      // get tearing vars
      tvars := List.map1r(tearingVars, BackendVariable.getVarAt, constSyst.orderedVars);
      tvars := List.map(tvars, BackendVariable.transformXToXd);
      tvars := BackendVariable.setVarsKind(tvars, BackendDAE.LOOP_ITERATION());
      ((loopIterationVars, _)) := List.fold(tvars, traversingdlowvarToSimvarFold, ({}, BackendVariable.emptyVars(0)));
      loopIterationVars := listReverse(loopIterationVars);

      // generate other equations
      (simequations, loopSolvedVars, uniqueEqIndex) := generateInnerEqns(innerEquations, constSyst, shared, uniqueEqIndex);

      // get residual eqns
      reqns := BackendEquation.getList(residualEqns, constSyst.orderedEqs);
      reqns := BackendEquation.replaceDerOpInEquationList(reqns);
      (resEqs, uniqueEqIndex, tempVars) := createNonlinearResidualEquations(reqns, uniqueEqIndex, {}, shared.functionTree);

      simequations := listAppend(simequations, resEqs);

      //set index
      (loopIterationVars, index) := rewriteIndex(loopIterationVars, 0);
      (loopSolvedVars, index) := rewriteIndex(loopSolvedVars, index);

      // create hash table with local index
      nAllVars := listLength(loopIterationVars)+listLength(loopSolvedVars)+listLength(tempVars);
      hashTable := fillLocalHashTable({loopIterationVars, loopSolvedVars, tempVars}, nAllVars);

      // inputs empty, since we haven't check for inputs yet
      if debug then
        print("Function SimCodeUtil.generateEquationsForComponentsAlgSystem:\n");
        dumpVarLst(loopIterationVars, "AlgSystem loopIterationVars");
        dumpVarLst(loopSolvedVars, "AlgSystem loopSolvedVars");
      end if;

      tmpOutputVars := listAppend(loopIterationVars, loopSolvedVars);
      omsiFunction := SimCode.OMSI_FUNCTION(equations = simequations,
                                            inputVars = {},
                                            outputVars = tmpOutputVars,
                                            innerVars = tempVars,
                                            nAllVars = nAllVars,
                                            context = SimCodeFunction.OMSI_CONTEXT(SOME(hashTable)),
                                            nAlgebraicSystems = 0);

      // fill SES_ALGEBRAIC_SYSTEM
      (derivativeMatrix, uniqueEqIndex) := createDerivativeMatrix(jacobian, uniqueEqIndex);
      algSystem := SimCode.SES_ALGEBRAIC_SYSTEM(index = algEqIndex,
                                                algSysIndex = nAlgebraicSystems,
                                                dim_n = listLength(tvars),
                                                partOfMixed = mixedSystem,
                                                tornSystem = true,
                                                linearSystem = linear,
                                                residual = omsiFunction,
                                                matrix = derivativeMatrix,
                                                zeroCrossingConditions = {},
                                                sources = {},
                                                eqAttr = BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
      nAlgebraicSystems := nAlgebraicSystems+1;
      tmpEqns := {algSystem};
    then ();

    // case for non-teared systems of equations
    case BackendDAE.EQUATIONSYSTEM(eqns = eqns,
                                   vars = variables,
                                   jac = jacobian,
                                   jacType = jacobianType,
                                   mixedSystem = mixedSystem)
      algorithm

      /*
      if not SymbolicJacobian.isJacobianGeneric(jacobian) then
        Error.addMessage(Error.NO_JACONIAN_TORNLINEAR_SYSTEM, {});    // ToDo: edit error message
        fail();
      end if;
      */

      algEqIndex := uniqueEqIndex;
      uniqueEqIndex := uniqueEqIndex+1;

      // get variables
      tvars := List.map1r(variables, BackendVariable.getVarAt, constSyst.orderedVars);
      tvars := List.map(tvars, BackendVariable.transformXToXd);
      //tvars := BackendVariable.setVarsKind(tvars, BackendDAE.LOOP_SOLVED());
      ((loopSolvedVars, _)) := List.fold(tvars, traversingdlowvarToSimvarFold, ({}, BackendVariable.emptyVars(0)));
      loopSolvedVars := listReverse(loopSolvedVars);

      // get residual equations
      reqns := BackendEquation.getList(eqns, constSyst.orderedEqs);
      reqns := BackendEquation.replaceDerOpInEquationList(reqns);
      (resEqs, uniqueEqIndex, tempVars) := createNonlinearResidualEquations(reqns, uniqueEqIndex, {}, shared.functionTree);

      //set index
      (loopSolvedVars, index) := rewriteIndex(loopSolvedVars, 0);

      // create hash table with local index
      nAllVars := listLength(loopSolvedVars)+listLength(tempVars);
      hashTable := fillLocalHashTable({loopSolvedVars, tempVars}, nAllVars);

      // fill OMSI_FUNCTION
      omsiFunction := SimCode.OMSI_FUNCTION(equations = resEqs,
                                            inputVars = {},
                                            outputVars = loopSolvedVars,
                                            innerVars = tempVars,
                                            nAllVars = nAllVars,
                                            context = SimCodeFunction.OMSI_CONTEXT(SOME(hashTable)),
                                            nAlgebraicSystems = 0);

      // fill SES_ALGEBRAIC_SYSTEM
      (derivativeMatrix, uniqueEqIndex) := createDerivativeMatrix(jacobian, uniqueEqIndex);
      algSystem := SimCode.SES_ALGEBRAIC_SYSTEM(index = algEqIndex,
                                                algSysIndex = nAlgebraicSystems,
                                                dim_n = listLength(tvars),
                                                partOfMixed = mixedSystem,
                                                tornSystem = false,
                                                linearSystem = false,             // ToDo: check if system is linear
                                                residual = omsiFunction,
                                                matrix = derivativeMatrix,
                                                zeroCrossingConditions = {},
                                                sources = {},
                                                eqAttr = BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);

      nAlgebraicSystems := nAlgebraicSystems+1;
      tmpEqns := {algSystem};

      if debug then
        dumpOMSIFunc(omsiFunction, "\nEquation system omsiFunction");
      end if;
    then();

    // error case
    else algorithm
      Error.addInternalError(" - case for component "+ BackendDump.printComponent(component) + " not implemented in SimCodeUtil.createAllEquationOMSI", sourceInfo());
      fail();
      then();
    end match;

    // append OMSI_FUNCTION data
    equations := listAppend(tmpEqns, equations);
    inputVars := listAppend(tmpInputVars, inputVars);
    outputVars := listAppend(tmpOutputVars, outputVars);
    innerVars := listAppend(tmpInnerVars, innerVars);
  end for;

  //set index
  (inputVars, index) := rewriteIndex(inputVars, 0);
  (innerVars, index) := rewriteIndex(innerVars, index);
  (outputVars, index) := rewriteIndex(outputVars, index);

  omsiFuncEquations := SimCode.OMSI_FUNCTION(equations =  listReverse(equations),
                                            inputVars = inputVars,
                                            outputVars = outputVars,
                                            innerVars =  innerVars,
                                            nAllVars = nAllVars,
                                            context = SimCodeFunction.OMSI_CONTEXT(NONE()),  // hash table with global index will be set in createAllEquationOMSI
                                            nAlgebraicSystems = nAlgebraicSystems);
  if debug then
    print("Function SimCodeUtil.generateEquationsForComponentsAlgSystem:\n");
    dumpVarLst(inputVars, "InputVars");
    dumpVarLst(innerVars, "InnerVars");
    dumpVarLst(outputVars, "OutputVars");
    end if;
end generateEquationsForComponents;


function generateSingleEquation
  "generates single equation from BackendDAE equations"
  input BackendDAE.Equation eqn;
  input BackendDAE.Var var;
  input DAE.FunctionTree funcTree;
  output list<SimCode.SimEqSystem> equations = {};
  output list<SimCodeVar.SimVar> inputVars = {};
  output list<SimCodeVar.SimVar> outputVars = {};
  output list<SimCodeVar.SimVar> innerVars = {};
  input output Integer uniqueEqIndex;
protected
  constant Boolean debug = false;
algorithm
  _ := match (eqn)
    local
      DAE.Exp lhs, rhs, resolvedExp, varExp;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes eqAttr;
      BackendDAE.WhenEquation whenEquation;
      DAE.Exp cond;
      list<BackendDAE.WhenOperator> whenStmtLst;
      Option<BackendDAE.WhenEquation> oelseWhen;

      list<SimCode.SimEqSystem> tmpSimEqLst;
      SimCodeVar.SimVar newSimVar;
      list<BackendDAE.Equation> solveEqns;
      list<DAE.Statement> asserts;
      list<DAE.ComponentRef> solveCr, conditions;
      DAE.ComponentRef cr;

      String str;
      Boolean initialCall;

    // single equation
    case BackendDAE.EQUATION(exp=lhs, scalar=rhs, source=source, attr=eqAttr)
      algorithm
        cr := var.varName;
        varExp := Expression.crefToExp(cr);

        if BackendVariable.isStateVar(var) then
          // exp -> der(exp)
          varExp := Expression.expDer(varExp);
          cr := ComponentReference.crefPrefixDer(cr);
        end if;

        try
          //solve equation lhs=rhs with respect to varible varExp
          (resolvedExp, asserts, solveEqns, solveCr) := ExpressionSolve.solve2(lhs, rhs, varExp, SOME(funcTree), SOME(uniqueEqIndex), true, true);

          (equations, uniqueEqIndex) := List.mapFold(listReverse(solveEqns), makeSolved_SES_SIMPLE_ASSIGN, uniqueEqIndex);
          innerVars := createTempVarsforCrefs(List.map(listReverse(solveCr), Expression.crefExp), {});

          source := ElementSource.addSymbolicTransformationSolve(true, source, cr, lhs, rhs, resolvedExp, asserts);
          (tmpSimEqLst, uniqueEqIndex) := addAssertEqn(asserts, {SimCode.SES_SIMPLE_ASSIGN(uniqueEqIndex, cr, resolvedExp, source, eqAttr)}, uniqueEqIndex+1);

          equations := listAppend(equations, tmpSimEqLst);

          //TODO: fix dlowvarToSimvar by romving Variables, they are not needed any more
          newSimVar := dlowvarToSimvar(var, NONE(), BackendVariable.emptyVars(0));
          if debug then
            print("generateSingleEquation:\n");
            dumpSimEqSystemLst(tmpSimEqLst, "\n");
            dumpVarLst({newSimVar},"newSimVar");
          end if;

          // add der(newSimVar) to outputVars if newSimVar is state
          if BackendVariable.isStateVar(var) then
            outputVars := listAppend({derVarFromStateVar(newSimVar)}, outputVars);
            inputVars := listAppend({newSimVar}, inputVars);
          else
            outputVars := listAppend({newSimVar}, outputVars);
          end if;

        else
          Error.addInternalError("- " + BackendDump.equationString(eqn)+ " could not resolved for "
            +  ComponentReference.printComponentRefStr(cr) + " in SimCodeUtil.generateSingleEquation", sourceInfo());
          fail();
        end try;
    then ();

    // when equation
    case BackendDAE.WHEN_EQUATION(whenEquation=whenEquation, source=source, attr=eqAttr) algorithm
      BackendDAE.WHEN_STMTS(cond, whenStmtLst, oelseWhen) := whenEquation;
      if isSome(oelseWhen) then /* else when not suported */
        Error.addInternalError("Else when equation not implemented in SimCodeUtil.generateSingleEquation", sourceInfo());
        fail();
      end if;

      (conditions, initialCall) := BackendDAEUtil.getConditionList(cond);

      tmpSimEqLst := {SimCode.SES_WHEN(uniqueEqIndex, conditions, initialCall,
                                    whenStmtLst, NONE(), source, eqAttr)};
      uniqueEqIndex := uniqueEqIndex+1;
      newSimVar := dlowvarToSimvar(var, NONE(), BackendVariable.emptyVars(0));

      if debug then
        print("generateWhenEquation:\n");
        dumpSimEqSystemLst(tmpSimEqLst, "\n");
        dumpVarLst({newSimVar},"newSimVar");
      end if;

      equations := listAppend(equations, tmpSimEqLst);
      outputVars := listAppend({newSimVar}, outputVars);
    then();

    // no matched equation
    else equation
      str = BackendDump.equationString(eqn);
      Error.addInternalError("- " + str + " not implemented SimCodeUtil.generateSingleEquation", sourceInfo());
      fail();
    then ();
  end match;
end generateSingleEquation;

protected function generateInnerEqns
"generates inner equations for equation systems in one SimCode.OMSIFunction"
  input BackendDAE.InnerEquations innerEquations;
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  output list<SimCode.SimEqSystem> equations = {};
  output list<SimCodeVar.SimVar> outputVars = {};
  input output Integer uniqueEqIndex;
protected
  Integer eqnindx;
  list<Integer> vars;
  list<SimCodeVar.SimVar> tmpOutputVars;
  list<BackendDAE.Var> tmpVars;
  BackendDAE.Equation eqn;
  BackendDAE.StrongComponent comp;
  list<SimCode.SimEqSystem> simequations;
  DoubleEndedList<SimCode.SimEqSystem> dblLstEqns;
  SimCode.OMSIFunction omsiFuncEquations;
algorithm
  dblLstEqns := DoubleEndedList.fromList(equations);

  for eq in innerEquations loop
    // get Eqn
    (eqnindx, vars, _) := BackendDAEUtil.getEqnAndVarsFromInnerEquation(eq);
    tmpVars := List.map1r(vars, BackendVariable.getVarAt, syst.orderedVars);
    tmpVars := BackendVariable.setVarsKind(tmpVars, BackendDAE.LOOP_SOLVED());
    ((tmpOutputVars, _)) := List.fold(tmpVars, traversingdlowvarToSimvarFold, ({}, BackendVariable.emptyVars(0)));
    outputVars := listAppend(outputVars,tmpOutputVars);
    eqn := BackendEquation.get(syst.orderedEqs, eqnindx);

    // generate comp
    comp := createTornSystemInnerEqns1(eqn, eqnindx, vars);
    (omsiFuncEquations, uniqueEqIndex) := generateEquationsForComponents({comp}, syst, shared, uniqueEqIndex);
    DoubleEndedList.push_list_back(dblLstEqns, omsiFuncEquations.equations);
  end for;

  equations := DoubleEndedList.toListAndClear(dblLstEqns);
end generateInnerEqns;


protected function appendOMSIFunction
"Append omsiFunction_2 to omsiFunction_1 and return omsiFunction_1."
  input output SimCode.OMSIFunction omsiFunction_1;
  input SimCode.OMSIFunction omsiFunction_2;
algorithm
    omsiFunction_1.equations := listAppend(omsiFunction_1.equations, omsiFunction_2.equations);

    omsiFunction_1.inputVars := listAppend(omsiFunction_1.inputVars, omsiFunction_2.inputVars);
    omsiFunction_1.outputVars := listAppend(omsiFunction_1.outputVars, omsiFunction_2.outputVars);
    omsiFunction_1.innerVars := listAppend(omsiFunction_1.innerVars, omsiFunction_2.innerVars);
    omsiFunction_1.nAllVars := omsiFunction_1.nAllVars + omsiFunction_2.nAllVars;

    // Update hashTable
    omsiFunction_1.context := match omsiFunction_1.context
      local
        HashTableCrefSimVar.HashTable hashTable;
      case SimCodeFunction.OMSI_CONTEXT(SOME(hashTable))
        algorithm
          hashTable := List.fold(omsiFunction_2.inputVars, HashTableCrefSimVar.addSimVarToHashTable, hashTable);
        for simVar in omsiFunction_2.outputVars loop
          hashTable := HashTableCrefSimVar.addSimVarToHashTable(simVar, hashTable);
        end for;
        for simVar in omsiFunction_2.innerVars loop
          hashTable := HashTableCrefSimVar.addSimVarToHashTable(simVar, hashTable);
        end for;
        then SimCodeFunction.OMSI_CONTEXT(SOME(hashTable));
    end match;

    omsiFunction_1.nAlgebraicSystems := omsiFunction_1.nAlgebraicSystems + omsiFunction_2.nAlgebraicSystems;
end appendOMSIFunction;

protected function fillLocalHashTable
"Generates new hashTable filled with all SimVars from input lists."
  input list<list<SimCodeVar.SimVar>> varListList;
  input Integer numberOfElements "number of all elemtens of VarListList";
  output HashTableCrefSimVar.HashTable hashTable;
protected
  Integer sizeHT;
algorithm
  // generate empty hashTable
  sizeHT := max(1013, Util.nextPrime(numberOfElements*2));   // chose big enough prime for hash table
  hashTable := HashTableCrefSimVar.emptyHashTableSized(sizeHT);

  // fill hashTable
  for simVarList in varListList loop
    hashTable := List.fold(simVarList, HashTableCrefSimVar.addSimVarToHashTable, hashTable);
  end for;
end fillLocalHashTable;


// =============================================================================
// section to create state set equations
//
// =============================================================================

public function createStateSets "author: Frenkel TUD 2012
  This function handle states sets for code generation."
  input BackendDAE.BackendDAE inDAE;
  input list<SimCode.StateSet> iEquations;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output BackendDAE.BackendDAE outDAE;
  output list<SimCode.StateSet> oEquations;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
  output Integer numStateSets;
protected
  Boolean flag;
algorithm
  if Flags.getConfigString(Flags.INDEX_REDUCTION_METHOD) == "dummyDerivatives" then
    outDAE := inDAE;
    oEquations := iEquations;
    ouniqueEqIndex := iuniqueEqIndex;
    otempvars := itempvars;
    numStateSets := 0;
  else
  (outDAE, (oEquations, ouniqueEqIndex, otempvars, numStateSets)) :=
    BackendDAEUtil.mapEqSystemAndFold(inDAE, createStateSetsSystem, (iEquations, iuniqueEqIndex, itempvars, 0));
  end if;
  // BackendDump.printBackendDAE(outDAE);
end createStateSets;

protected function createStateSetsSystem "author: Frenkel TUD 2012-12
  traverse an Equationsystem to handle states sets"
  input BackendDAE.EqSystem isyst;
  input BackendDAE.Shared inShared;
  input tuple<list<SimCode.StateSet>, Integer, list<SimCodeVar.SimVar>, Integer> inTpl;
  output BackendDAE.EqSystem osyst;
  output BackendDAE.Shared outShared = inShared;
  output tuple<list<SimCode.StateSet>, Integer, list<SimCodeVar.SimVar>, Integer> outTpl;
algorithm
  (osyst, outTpl):= match (isyst, inTpl)
    local
      BackendDAE.Variables vars;
      BackendDAE.EquationArray eqns;
      BackendDAE.StateSets stateSets;
      BackendDAE.EqSystem syst;
      list<SimCode.StateSet> equations;
      Integer uniqueEqIndex, numStateSets;
      list<SimCodeVar.SimVar> tempvars;
      BackendDAE.StrongComponents comps;
    // no stateSet
    case (BackendDAE.EQSYSTEM(stateSets={}), _) then (isyst, inTpl);
    // sets
    case (syst as BackendDAE.EQSYSTEM(orderedVars=vars, orderedEqs=eqns, matching=BackendDAE.MATCHING(comps=comps), stateSets=stateSets),
         (equations, uniqueEqIndex, tempvars, numStateSets))
      equation
        (equations, uniqueEqIndex, tempvars, numStateSets) =
            createStateSetsSets(stateSets, vars, eqns, comps, equations, uniqueEqIndex, tempvars, numStateSets);
      then
        (syst,(equations, uniqueEqIndex, tempvars, numStateSets));
  end match;
end createStateSetsSystem;

protected function createStateSetsSets
  input BackendDAE.StateSets iStateSets;
  input BackendDAE.Variables iVars;
  input BackendDAE.EquationArray iEqns;
  input BackendDAE.StrongComponents comps;
  input list<SimCode.StateSet> iEquations;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input Integer iNumStateSets;
  output list<SimCode.StateSet> oEquations;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
  output Integer oNumStateSets;
algorithm
  (oEquations, ouniqueEqIndex, otempvars, oNumStateSets) :=
  matchcontinue(iStateSets, iVars, iEqns, comps, iEquations, iuniqueEqIndex, itempvars, iNumStateSets)
    local
      DAE.FunctionTree functree;
      BackendDAE.StateSets sets;
      Integer rang, numStateSets, nCandidates;
      list<DAE.ComponentRef> crset;
      DAE.ComponentRef crA, crJ;
      BackendDAE.Variables vars, knVars;
      list<BackendDAE.Var> aVars, statevars, dstatesvars, varJ, compvars;
      list<BackendDAE.Equation> ceqns, oeqns, compeqns;
      list<DAE.ComponentRef> crstates;
      SimCode.JacobianMatrix jacobianMatrix;
      list<SimCode.StateSet> simequations;
      list<SimCodeVar.SimVar> tempvars, simCodeAVars;
      Integer uniqueEqIndex;
      HashSet.HashSet hs;
      array<Boolean> marked;
      BackendDAE.ExtraInfo ei;
      BackendDAE.Jacobian jacobian;
      String errorMessage;

    case({}, _, _, _, _, _, _, _) then (iEquations, iuniqueEqIndex, itempvars, iNumStateSets);

    case(BackendDAE.STATESET(rang=rang, state=crset, crA=crA, varA=aVars, statescandidates=statevars,   jacobian=jacobian)::sets, _, _,
         _, _, _, _, _)
      equation
        // get state names
        crstates = List.map(statevars, BackendVariable.varCref);

        // create vars for A
        simCodeAVars = List.map2(aVars, dlowvarToSimvar, NONE(), iVars);

        // get first a element for varinfo
        crA = ComponentReference.subscriptCrefWithInt(crA, 1);
        crA = if intGt(listLength(crset), 1) then ComponentReference.subscriptCrefWithInt(crA, 1) else crA;

        // number of states
        nCandidates = listLength(statevars);

        // create symbolic jacobian for simulation
        (SOME(jacobianMatrix), uniqueEqIndex, tempvars) = createSymbolicSimulationJacobian(jacobian, iuniqueEqIndex, listAppend(itempvars,simCodeAVars));

        // next set
        (simequations, uniqueEqIndex, tempvars, numStateSets) = createStateSetsSets(sets, iVars, iEqns, comps, SimCode.SES_STATESET(iuniqueEqIndex, nCandidates, rang, crset, crstates, crA, jacobianMatrix)::iEquations, uniqueEqIndex, tempvars, iNumStateSets+1);
      then
        (simequations, uniqueEqIndex, tempvars, numStateSets);
    else
      equation
        errorMessage = "function createStateSetsSets failed.";
        Error.addInternalError(errorMessage, sourceInfo());
      then
        fail();
  end matchcontinue;
end createStateSetsSets;

// =============================================================================
// section to create SimCode symbolic jacobian from BackendDAE.Equations
//
// =============================================================================

protected function createSymbolicSimulationJacobian "function createSymbolicSimulationJacobian
  author: wbraun
  function creates a symbolic jacobian column for
  non-linear systems and tearing systems."
  input BackendDAE.Jacobian inJacobian;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output Option<SimCode.JacobianMatrix> res;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (res, ouniqueEqIndex, otempvars) := matchcontinue(inJacobian, iuniqueEqIndex, itempvars)
  local

    BackendDAE.Variables emptyVars, dependentVars, independentVars, globalKnownVars, allvars, residualVars, systvars;
    BackendDAE.EquationArray emptyEqns, eqns;
    list<BackendDAE.Var> knvarLst, seedVarLst, independentVarsLst, dependentVarsLst, residualVarsLst, allVars;
    list<DAE.ComponentRef> independentComRefs, dependentVarsComRefs;

    DAE.ComponentRef x;
    BackendDAE.SparsePattern pattern;
    BackendDAE.SparseColoring sparseColoring;
    list<list<Integer>> coloring;
    list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> sparsepatternComRefs, sparsepatternComRefsT;
    list<tuple<Integer, list<Integer>>> sparseInts, sparseIntsT;

    BackendDAE.EqSystem syst;
    BackendDAE.Shared shared;
    BackendDAE.StrongComponents comps;

    list<SimCodeVar.SimVar> tempvars;
    String name, dummyVar;
    Integer maxColor, uniqueEqIndex, nonZeroElements, nRows;

    list<SimCode.SimEqSystem> columnEquations;
    list<SimCodeVar.SimVar> columnVars;
    list<SimCodeVar.SimVar> varsSeedIndex, seedVars, indexVars;

    String errorMessage;

    DAE.FunctionTree funcs;

    HashTableCrefSimVar.HashTable crefToSimVarHTJacobian;

    case (BackendDAE.EMPTY_JACOBIAN(), _, _) then (NONE(), iuniqueEqIndex, itempvars);

    case (BackendDAE.FULL_JACOBIAN(_), _, _) then (NONE(), iuniqueEqIndex, itempvars);

    case (BackendDAE.GENERIC_JACOBIAN(NONE(),pattern as (sparsepatternComRefs, sparsepatternComRefsT,
                                             (independentComRefs, dependentVarsComRefs), _),
                                             sparseColoring), _, _)
      equation
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("create sparse pattern for algebraic loop time: " + realString(clock()) + "\n");
          BackendDump.dumpSparsityPattern(pattern, "---+++ SparsePattern +++---");
        end if;
        seedVars = list(makeTmpRealSimCodeVar(cr, BackendDAE.SEED_VAR()) for cr in independentComRefs);
        indexVars = list(makeTmpRealSimCodeVar(cr, BackendDAE.VARIABLE()) for cr in dependentVarsComRefs);

        seedVars = rewriteIndex(seedVars, 0);
        indexVars = rewriteIndex(indexVars, 0);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("\n---+++ seedVars variables +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, seedVars));
          print("\n---+++ indexVars variables +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, indexVars));
        end if;
        //sort sparse pattern
        varsSeedIndex = listAppend(seedVars, indexVars);
        //sort sparse pattern
        sparseInts = sortSparsePattern(varsSeedIndex, sparsepatternComRefs, false);
        sparseIntsT = sortSparsePattern(varsSeedIndex, sparsepatternComRefsT, false);

        // set sparse pattern
        coloring = sortColoring(seedVars, sparseColoring);
        maxColor = listLength(sparseColoring);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("created sparse pattern for algebraic loop time: " + realString(clock()) + "\n");
        end if;

      then (SOME(SimCode.JAC_MATRIX({}, {}, "", sparseInts, sparseIntsT, coloring, maxColor, -1, 0, NONE())), iuniqueEqIndex, itempvars);

    case (BackendDAE.GENERIC_JACOBIAN(SOME((BackendDAE.DAE(eqs={syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))},
                                    shared=shared), name,
                                    independentVarsLst, residualVarsLst, dependentVarsLst)),
                                      (sparsepatternComRefs, sparsepatternComRefsT, (_, _), _),
                                      sparseColoring), _, _)
      equation
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> creating SimCode equations for Matrix " + name + " time: " + realString(clock()) + "\n");
        end if;
        // generate also discrete equations, they might be introduced by wrapFunctionCalls
        (columnEquations, _, uniqueEqIndex, tempvars) = createEquations(false, false, true, false, syst, shared, comps, iuniqueEqIndex, itempvars);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> created all SimCode equations for Matrix " + name +  " time: " + realString(clock()) + "\n");
        end if;

        // create SimCodeVar.SimVars from jacobian vars
        dummyVar = ("dummyVar" + name);
        x = DAE.CREF_IDENT(dummyVar, DAE.T_REAL_DEFAULT, {});
        emptyVars =  BackendVariable.emptyVars();

        residualVars = BackendVariable.listVar1(residualVarsLst);
        independentVars = BackendVariable.listVar1(independentVarsLst);

        // get cse and other aux vars > columnVars
        ((allVars, _)) = BackendVariable.traverseBackendDAEVars(syst.orderedVars, getFurtherVars , ({}, x));
        systvars = BackendVariable.listVar1(allVars);
        ((columnVars, _)) =  BackendVariable.traverseBackendDAEVars(systvars, traversingdlowvarToSimvar, ({}, emptyVars));
        columnVars = List.map1(columnVars, setSimVarKind, BackendDAE.JAC_DIFF_VAR());
        columnVars = List.map1(columnVars, setSimVarMatrixName, SOME(name));
        columnVars = rewriteIndex(columnVars, 0);

        columnVars = createAllDiffedSimVars(dependentVarsLst, x, residualVars, 0, listLength(columnVars), name, columnVars);
        columnVars = listReverse(columnVars);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("\n---+++ all column variables +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, columnVars));
          print("analytical Jacobians -> create all SimCode vars for Matrix " + name + " time: " + realString(clock()) + "\n");
        end if;

        ((seedVars, _)) =  BackendVariable.traverseBackendDAEVars(independentVars, traversingdlowvarToSimvar, ({}, emptyVars));
        ((indexVars, _)) =  BackendVariable.traverseBackendDAEVars(residualVars, traversingdlowvarToSimvar, ({}, emptyVars));
        seedVars = rewriteIndex(listReverse(seedVars), 0);
        indexVars = rewriteIndex(listReverse(indexVars), 0);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("\n---+++ seedVars variables +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, seedVars));
          print("\n---+++ indexVars variables +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, indexVars));
        end if;
        //sort sparse pattern
        varsSeedIndex = listAppend(seedVars, indexVars);
        sparseInts = sortSparsePattern(varsSeedIndex, sparsepatternComRefs, false);
        sparseIntsT = sortSparsePattern(varsSeedIndex, sparsepatternComRefsT, false);

        // set sparse pattern
        coloring = sortColoring(varsSeedIndex, sparseColoring);
        maxColor = listLength(sparseColoring);
        nRows = listLength(residualVarsLst);

        // create seed vars
        seedVars = replaceSeedVarsName(seedVars, name);
        seedVars = List.map1(seedVars, setSimVarKind, BackendDAE.SEED_VAR());
        seedVars = List.map1(seedVars, setSimVarMatrixName, SOME(name));

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> transformed to SimCode for Matrix " + name + " time: " + realString(clock()) + "\n");
        end if;

        crefToSimVarHTJacobian = HashTableCrefSimVar.emptyHashTableSized(listLength(seedVars)+ listLength(columnVars));
        crefToSimVarHTJacobian = List.fold(seedVars, HashTableCrefSimVar.addSimVarToHashTable, crefToSimVarHTJacobian);
        crefToSimVarHTJacobian = List.fold(columnVars, HashTableCrefSimVar.addSimVarToHashTable, crefToSimVarHTJacobian);

      then (SOME(SimCode.JAC_MATRIX({SimCode.JAC_COLUMN(columnEquations, columnVars, nRows)}, seedVars, name, sparseInts, sparseIntsT, coloring, maxColor, -1, 0, SOME(crefToSimVarHTJacobian))), uniqueEqIndex, tempvars);

    else
      equation
        if Flags.isSet(Flags.JAC_DUMP) then
          errorMessage = "function createSymbolicSimulationJacobian failed.";
          Error.addInternalError(errorMessage, sourceInfo());
        end if;
      then (NONE(), iuniqueEqIndex, itempvars);

  end matchcontinue;
end createSymbolicSimulationJacobian;

protected function getFurtherVars
  input BackendDAE.Var v;
  input tuple<list<BackendDAE.Var>, DAE.ComponentRef> inTpl;
  output BackendDAE.Var outVar = v;
  output tuple<list<BackendDAE.Var>, DAE.ComponentRef> outTpl = inTpl;
protected
  DAE.ComponentRef diffCref;
  list<BackendDAE.Var> vars;
  Boolean b;
algorithm
  (vars, diffCref) := inTpl;
  b := ComponentReference.crefLastIdentEqual(BackendVariable.varCref(v), diffCref);
  if not b then
    vars := v::vars;
    outTpl := (vars, diffCref);
  end if;
end getFurtherVars;

public function createJacobianLinearCode
  input BackendDAE.SymbolicJacobians inSymjacs;
  input SimCode.ModelInfo inModelInfo;
  input Integer iuniqueEqIndex;
  input BackendDAE.Shared shared;
  output list<SimCode.JacobianMatrix> res = {};
  output Integer ouniqueEqIndex;
algorithm
  (res,ouniqueEqIndex) := match (inSymjacs, inModelInfo, iuniqueEqIndex)
    local
      SimCode.HashTableCrefToSimVar crefSimVarHT;
      SimCode.JacobianMatrix tmpJac;
      list<String> matrixnames;
    case (_, _, _)
      equation
        // b = Flags.disableDebug(Flags.EXEC_STAT);
        crefSimVarHT = createCrefToSimVarHT(inModelInfo);
        // The jacobian code requires single systems;
        // I did not rewrite it to take advantage of any parallelism in the code

        // This is used to set the matrixnames for Linearization and DataReconciliation procedure
        // For dataReconciliation F is set in earlier order which cause index problem for linearization matrix and hence identify if
        // dataReconciliation is involved and pass the matrix names
        if Util.isSome(shared.dataReconciliationData) then
           matrixnames={"A", "B", "C", "D"};
        else
           matrixnames={"A", "B", "C", "D", "F"};
        end if;
        (res, ouniqueEqIndex) = createSymbolicJacobianssSimCode(inSymjacs, crefSimVarHT, iuniqueEqIndex, matrixnames, {});
        // _ = Flags.set(Flags.EXEC_STAT, b);
      then (res,ouniqueEqIndex);
  end match;
end createJacobianLinearCode;

protected function checkForEmptyBDAE
  input Option<BackendDAE.SymbolicJacobian> inBDAE;
  output Boolean result;
algorithm
  result := match(inBDAE)
    case (NONE())
      then true;
    case (SOME((_,_,{},{},{})))
      equation
      then true;
    else
      false;
   end match;
end checkForEmptyBDAE;

public function createSymbolicJacobianssSimCode
"function creates the linear model matrices column-wise
 author: wbraun"
  input BackendDAE.SymbolicJacobians inSymJacobians;
  input SimCode.HashTableCrefToSimVar inSimVarHT;
  input Integer iuniqueEqIndex;
  input list<String> inNames;
  input list<SimCode.JacobianMatrix> inJacobianMatrixes;
  output list<SimCode.JacobianMatrix> outJacobianMatrixes;
  output Integer ouniqueEqIndex;
algorithm
  (outJacobianMatrixes, ouniqueEqIndex) :=
  matchcontinue (inSymJacobians, inSimVarHT, iuniqueEqIndex, inNames)
    local
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      BackendDAE.StrongComponents comps;
      BackendDAE.Variables vars, globalKnownVars, empty, systvars, emptyVars;

      DAE.ComponentRef x;
      list<BackendDAE.Var>  diffVars, diffedVars, alldiffedVars, seedVarLst, allVars;
      list<DAE.ComponentRef> diffCompRefs, diffedCompRefs, allCrefs;

      Integer uniqueEqIndex, nRows;

      list<String> restnames;
      String name, dummyVar;

      SimCodeVar.SimVars simvars;
      list<SimCode.SimEqSystem> columnEquations;
      list<SimCodeVar.SimVar> columnVars, otherColumnVars;
      list<SimCodeVar.SimVar> columnVarsKn;
      list<SimCodeVar.SimVar> seedVars, indexVars, seedIndexVars;

      list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> sparsepattern, sparsepatternT;
      list<list<DAE.ComponentRef>> colsColors;
      Integer maxColor;

      BackendDAE.SymbolicJacobians rest;
      list<SimCode.JacobianMatrix> linearModelMatrices;
      list<tuple<Integer, list<Integer>>> sparseInts, sparseIntsT;
      list<list<Integer>> coloring;
      Option<BackendDAE.SymbolicJacobian> optionBDAE;

      SimCode.JacobianMatrix tmpJac;
      HashTableCrefSimVar.HashTable crefToSimVarHTJacobian;

    case (_, _, _, {}) then (inJacobianMatrixes, iuniqueEqIndex);

    // if nothing is generated
    case ({}, _, _, name::restnames)
      equation
        tmpJac = SimCode.emptyJacobian;
        tmpJac.matrixName = name;
        linearModelMatrices = tmpJac::inJacobianMatrixes;
        (linearModelMatrices, uniqueEqIndex) = createSymbolicJacobianssSimCode({}, inSimVarHT, iuniqueEqIndex, restnames, linearModelMatrices);
     then
        (linearModelMatrices, uniqueEqIndex);

    // if nothing is generated
    case (((NONE(), ({}, {}, ({}, {}), _), {}))::rest, _, _, name::restnames)
      equation
        tmpJac = SimCode.emptyJacobian;
        tmpJac.matrixName = name;
        linearModelMatrices = tmpJac::inJacobianMatrixes;
        (linearModelMatrices, uniqueEqIndex) = createSymbolicJacobianssSimCode(rest, inSimVarHT, iuniqueEqIndex, restnames, linearModelMatrices);
     then
        (linearModelMatrices, uniqueEqIndex);

    // if only sparsity pattern is generated
    case (((optionBDAE, (sparsepattern, sparsepatternT, (diffCompRefs, diffedCompRefs), _), colsColors))::rest, _, _, name::restnames)
      guard  checkForEmptyBDAE(optionBDAE)
      equation
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("Start sparse pattern without analytical Jacobians\n");
        end if;

        seedVars = getSimVars2Crefs(diffCompRefs, inSimVarHT);
        seedVars = List.sort(seedVars, compareVarIndexGt);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("diffCrefs: " + ComponentReference.printComponentRefListStr(diffCompRefs) + "\n");
          print("\n---+++  seedVars +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, seedVars));
        end if;

        indexVars = getSimVars2Crefs(diffedCompRefs, inSimVarHT);
        indexVars = List.sort(indexVars, compareVarIndexGt);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("diffedCrefs: " + ComponentReference.printComponentRefListStr(diffedCompRefs) + "\n");
          print("\n---+++  indexVars +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, indexVars));
          print("\n---+++  sparse pattern vars +++---\n");
          dumpSparsePattern(sparsepattern);
          print("\n---+++  sparse pattern transpose +++---\n");
          dumpSparsePattern(sparsepatternT);
        end if;
        seedVars = rewriteIndex(seedVars, 0);
        indexVars = rewriteIndex(indexVars, 0);
        seedIndexVars = listAppend(seedVars, indexVars);

        sparseInts = sortSparsePattern(seedIndexVars, sparsepattern, false);
        sparseIntsT = sortSparsePattern(seedIndexVars, sparsepatternT, false);

        maxColor = listLength(colsColors);
        nRows = listLength(diffedCompRefs);
        coloring = sortColoring(seedVars, colsColors);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> transformed to SimCode for Matrix " + name + " time: " + realString(clock()) + "\n");
          print("\n---+++  sparse pattern vars +++---\n");
          dumpSparsePatternInt(sparseInts);
          print("\n---+++  sparse pattern transpose +++---\n");
          dumpSparsePatternInt(sparseIntsT);
        end if;

        // create seed vars
        seedVars = replaceSeedVarsName(seedVars, name);
        seedVars = List.map1(seedVars, setSimVarKind, BackendDAE.SEED_VAR());
        seedVars = List.map1(seedVars, setSimVarMatrixName, SOME(name));

        tmpJac = SimCode.JAC_MATRIX({SimCode.JAC_COLUMN({},{},nRows)}, seedVars, name, sparseInts, sparseIntsT, coloring, maxColor, -1, 0, NONE());
        linearModelMatrices = tmpJac::inJacobianMatrixes;
        (linearModelMatrices, uniqueEqIndex) = createSymbolicJacobianssSimCode(rest, inSimVarHT, iuniqueEqIndex, restnames, linearModelMatrices);

        then
        (linearModelMatrices, uniqueEqIndex);

    case (((SOME((BackendDAE.DAE(eqs={syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))},
                                    shared=shared), name,
                                    _, diffedVars, alldiffedVars)), (sparsepattern, sparsepatternT, (diffCompRefs, diffedCompRefs), _), colsColors))::rest,
                                    _, _, _::restnames)
      equation
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> creating SimCode equations for Matrix " + name + " time: " + realString(clock()) + "\n");
        end if;
        // generate also discrete equations, they might be introduced by wrapFunctionCalls
        (columnEquations, _, uniqueEqIndex, _) = createEquations(false, false, true, false, syst, shared, comps, iuniqueEqIndex, {});
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> created all SimCode equations for Matrix " + name +  " time: " + realString(clock()) + "\n");
        end if;

        // create SimCodeVar.SimVars from jacobian vars
        dummyVar = ("dummyVar" + name);
        x = DAE.CREF_IDENT(dummyVar, DAE.T_REAL_DEFAULT, {});

        // get cse and other aux vars > columnVars
        emptyVars =  BackendVariable.emptyVars();
        ((allVars, _)) = BackendVariable.traverseBackendDAEVars(syst.orderedVars, getFurtherVars , ({}, x));
        systvars = BackendVariable.listVar1(allVars);
        ((otherColumnVars, _)) =  BackendVariable.traverseBackendDAEVars(systvars, traversingdlowvarToSimvar, ({}, emptyVars));
        otherColumnVars = List.map1(otherColumnVars, setSimVarKind, BackendDAE.JAC_DIFF_VAR());
        otherColumnVars = List.map1(otherColumnVars, setSimVarMatrixName, SOME(name));
        otherColumnVars = rewriteIndex(otherColumnVars, 0);

        //sort variable for index
        empty = BackendVariable.listVar1(alldiffedVars);
        allCrefs = List.map(alldiffedVars, BackendVariable.varCref);
        columnVars = getSimVars2Crefs(allCrefs, inSimVarHT);
        columnVars = List.sort(columnVars, compareVarIndexGt);
        (_, (_, alldiffedVars)) = List.mapFoldTuple(columnVars, sortBackVarWithSimVarsOrder, (empty, {}));
        alldiffedVars = listReverse(alldiffedVars);
        vars = BackendVariable.listVar1(diffedVars);

        columnVars = createAllDiffedSimVars(alldiffedVars, x, vars, 0, listLength(otherColumnVars), name, otherColumnVars);
        if Flags.isSet(Flags.JAC_DUMP2) then
          print("\n---+++ second columnVars +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, columnVars));
          print("analytical Jacobians -> create column variables for matrix " + name + " time: " + realString(clock()) + "\n");
        end if;

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> create all SimCode vars for Matrix " + name + " time: " + realString(clock()) + "\n");
          print("\n---+++  columnVars +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, columnVars));
        end if;

        seedVars = getSimVars2Crefs(diffCompRefs, inSimVarHT);
        seedVars = List.sort(seedVars, compareVarIndexGt);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("diffCrefs: " + ComponentReference.printComponentRefListStr(diffCompRefs) + "\n");
          print("\n---+++  seedVars +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, seedVars));
        end if;

        indexVars = getSimVars2Crefs(diffedCompRefs, inSimVarHT);
        indexVars = List.sort(indexVars, compareVarIndexGt);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("diffedCrefs: " + ComponentReference.printComponentRefListStr(diffedCompRefs) + "\n");
          print("\n---+++  indexVars +++---\n");
          print(Tpl.tplString(SimCodeDump.dumpVarsShort, indexVars));

          print("\n---+++  sparse pattern vars +++---\n");
          dumpSparsePattern(sparsepattern);
          print("\n---+++  sparse pattern transpose +++---\n");
          dumpSparsePattern(sparsepatternT);
        end if;
        seedVars = rewriteIndex(seedVars, 0);
        indexVars = rewriteIndex(indexVars, 0);
        seedIndexVars = listAppend(seedVars, indexVars);
        sparseInts = sortSparsePattern(seedIndexVars, sparsepattern, false);
        sparseIntsT = sortSparsePattern(seedIndexVars, sparsepatternT, false);

        maxColor = listLength(colsColors);
        nRows =  listLength(diffedVars);
        coloring = sortColoring(seedVars, colsColors);

        if Flags.isSet(Flags.JAC_DUMP2) then
          print("analytical Jacobians -> transformed to SimCode for Matrix " + name + " time: " + realString(clock()) + "\n");
          print("\n---+++  sparse pattern vars +++---\n");
          dumpSparsePatternInt(sparseInts);
          print("\n---+++  sparse pattern transpose +++---\n");
          dumpSparsePatternInt(sparseIntsT);
        end if;

        // create seed vars
        seedVars = replaceSeedVarsName(seedVars, name);
        seedVars = List.map1(seedVars, setSimVarKind, BackendDAE.SEED_VAR());
        seedVars = List.map1(seedVars, setSimVarMatrixName, SOME(name));

        // create hash table for this jacobians
        crefToSimVarHTJacobian = HashTableCrefSimVar.emptyHashTableSized(listLength(seedVars)+ listLength(columnVars));
        crefToSimVarHTJacobian = List.fold(seedVars, HashTableCrefSimVar.addSimVarToHashTable, crefToSimVarHTJacobian);
        crefToSimVarHTJacobian = List.fold(columnVars, HashTableCrefSimVar.addSimVarToHashTable, crefToSimVarHTJacobian);

        tmpJac = SimCode.JAC_MATRIX({SimCode.JAC_COLUMN(columnEquations, columnVars, nRows)}, seedVars, name, sparseInts, sparseIntsT, coloring, maxColor, -1, 0, SOME(crefToSimVarHTJacobian));
        linearModelMatrices = tmpJac::inJacobianMatrixes;
        (linearModelMatrices, uniqueEqIndex) = createSymbolicJacobianssSimCode(rest, inSimVarHT, uniqueEqIndex, restnames, linearModelMatrices);
     then
        (linearModelMatrices, uniqueEqIndex);
    else
      equation
        Error.addInternalError("Generation of symbolic matrix SimCode (SimCode.createSymbolicJacobianssSimCode) failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end createSymbolicJacobianssSimCode;

public function getSimVars2Crefs
  input list<DAE.ComponentRef> inCrefs;
  input SimCode.HashTableCrefToSimVar inSimVarHT;
  output list<SimCodeVar.SimVar> outSimVars = {};
algorithm
  for cref in inCrefs loop
    try
      outSimVars := BaseHashTable.get(cref, inSimVarHT)::outSimVars;
    else
    end try;
  end for;
end getSimVars2Crefs;

protected function replaceSeedVarsName
  input list<SimCodeVar.SimVar> inVars;
  input String inMatrixName;
  output list<SimCodeVar.SimVar> outSimVars = {};
protected
  DAE.ComponentRef newCref, oldCref;
algorithm
  for v in inVars loop
      oldCref := varName(v);
      newCref := Differentiate.createSeedCrefName(oldCref, inMatrixName);
      outSimVars := replaceSimVarName(newCref, v)::outSimVars;
  end for;
  outSimVars := Dangerous.listReverseInPlace(outSimVars);
end replaceSeedVarsName;

protected function sortBackVarWithSimVarsOrder
  input tuple<SimCodeVar.SimVar, tuple<BackendDAE.Variables, list<BackendDAE.Var>>> inTuple;
  output tuple<SimCodeVar.SimVar, tuple<BackendDAE.Variables, list<BackendDAE.Var>>> outTuple;
protected
  SimCodeVar.SimVar var;
  BackendDAE.Variables vars;
  list<BackendDAE.Var> varLst, resvars;
  BackendDAE.Var v;
  DAE.ComponentRef cref;
algorithm
  ((var, (vars, varLst))) := inTuple;
  SimCodeVar.SIMVAR(name=cref) := var;
  (v,_) := BackendVariable.getVarSingle(cref, vars);
  outTuple := ((var, (vars, v::varLst)));
end sortBackVarWithSimVarsOrder;

protected function createJacSimVarsColumn "author: wbraun"
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input Integer inResIndex;
  input Integer inTmpIndex;
  input String inMatrixName;
  input output list<SimCodeVar.SimVar> tmpVars;
  input output list<SimCodeVar.SimVar> resVars;
algorithm
  (tmpVars, resVars) := match(inVars)
  local
    BackendDAE.Var v, v1;
    SimCodeVar.SimVar simVar;
    DAE.ComponentRef currVar, cref, derivedCref;
    list<BackendDAE.Var> restVar;
    Option<DAE.VariableAttributes> dae_var_attr;
    Boolean isProtected;
    Boolean hideResult = false;
    Integer resIndex=inResIndex, tmpIndex=inTmpIndex;
    BackendDAE.VarKind varkind;

    case ({}) then (listReverse(tmpVars), listReverse(resVars));

    case((v as BackendDAE.VAR(varName=currVar, varKind=varkind, values = dae_var_attr))::restVar) algorithm
      try
        BackendVariable.getVarSingle(currVar, inAllVars);
        currVar := match (varkind)
          case BackendDAE.STATE() then ComponentReference.crefPrefixDer(currVar);
          else currVar;
        end match;
        derivedCref := ComponentReference.createDifferentiatedCrefName(currVar, inCref, inMatrixName);
        v1 := BackendVariable.copyVarNewName(derivedCref, v);
        v1 := BackendVariable.setVarKind(v1, BackendDAE.JAC_VAR());
        simVar := dlowvarToSimvar(v1, NONE(), inAllVars);
        simVar.index := inResIndex;
        resIndex := inResIndex + 1;
        simVar.matrixName := SOME(inMatrixName);
        resVars := simVar::resVars;
      else
        currVar := match (varkind)
          case BackendDAE.STATE() then ComponentReference.crefPrefixDer(currVar);
          else currVar;
        end match;
        derivedCref := ComponentReference.createDifferentiatedCrefName(currVar, inCref, inMatrixName);
        v1 := BackendVariable.copyVarNewName(derivedCref, v);
        v1 := BackendVariable.setVarKind(v1, BackendDAE.JAC_DIFF_VAR());
        simVar := dlowvarToSimvar(v1, NONE(), inAllVars);
        simVar.index := inTmpIndex;
        simVar.matrixName := SOME(inMatrixName);
        tmpIndex := inTmpIndex + 1;
        tmpVars := simVar::tmpVars;
      end try;
     then
       createJacSimVarsColumn(restVar, inCref, inAllVars, resIndex, tmpIndex, inMatrixName, tmpVars, resVars);

    else
     equation
      Error.addInternalError("function createAllDiffedSimVars failed", sourceInfo());
    then fail();
  end match;
end createJacSimVarsColumn;

protected function createAllDiffedSimVars "author: wbraun"
  input list<BackendDAE.Var> inVars;
  input DAE.ComponentRef inCref;
  input BackendDAE.Variables inAllVars;
  input Integer inResIndex;
  input Integer inTmpIndex;
  input String inMatrixName;
  input list<SimCodeVar.SimVar> iVars;
  output list<SimCodeVar.SimVar> outVars;
protected
  list<SimCodeVar.SimVar> lst1;
algorithm
  (outVars, lst1) := createJacSimVarsColumn(inVars, inCref, inAllVars, inResIndex, inTmpIndex, inMatrixName, iVars, {});
  outVars := listAppend(lst1, outVars);
end createAllDiffedSimVars;

public function collectAllJacobianEquations
  input list<SimCode.JacobianMatrix> inJacobianMatrix;
  output list<SimCode.SimEqSystem> outEqn = {};
protected
  list<SimCode.JacobianColumn> column;
  list<SimCode.SimEqSystem> tmp;
algorithm
  for m in inJacobianMatrix loop
    SimCode.JAC_MATRIX(columns=column) := m;
    for c in column loop
      SimCode.JAC_COLUMN(columnEqns=tmp) := c;
      outEqn := listAppend(tmp, outEqn);
    end for;
  end for;
end collectAllJacobianEquations;

public function collectAllJacobianVars
  input list<SimCode.JacobianMatrix> inJacobianMatrix;
  output list<SimCodeVar.SimVar> outVars = {};
protected
  list<SimCode.JacobianColumn> column;
  list<SimCodeVar.SimVar> tmp;
algorithm
  for m in inJacobianMatrix loop
    SimCode.JAC_MATRIX(columns=column) := m;
    for c in column loop
      SimCode.JAC_COLUMN(columnVars=tmp) := c;
      outVars := listAppend(tmp, outVars);
    end for;
  end for;
end collectAllJacobianVars;

public function collectAllSeedVars
 "Collect seed vars of Jacobian matrices. author: rfranke"
  input list<SimCode.JacobianMatrix> inJacobianMatrices;
  output list<SimCodeVar.SimVar> outVars = {};
protected
  list<SimCodeVar.SimVar> seedVars;
algorithm
  for m in inJacobianMatrices loop
    SimCode.JAC_MATRIX(seedVars=seedVars) := m;
    outVars := listAppend(seedVars, outVars);
  end for;
  outVars := List.map1(outVars, setSimVarKind, BackendDAE.SEED_VAR());
end collectAllSeedVars;

protected function setSimVarKind
  input output SimCodeVar.SimVar simVar;
  input BackendDAE.VarKind varKind;
algorithm
  simVar.varKind := varKind;
end setSimVarKind;

protected function setSimVarMatrixName
  input output SimCodeVar.SimVar simVar;
  input Option<String> optName;
algorithm
  simVar.matrixName := optName;
end setSimVarMatrixName;

protected function makeTmpRealSimCodeVar
  input DAE.ComponentRef inName;
  input BackendDAE.VarKind inVarKind;
  output SimCodeVar.SimVar outSimVar;
algorithm
  outSimVar := SimCodeVar.SIMVAR(inName, inVarKind, "", "", "", -1 /* use -1 to get an error in simulation if something failed */,
        NONE(), NONE(), NONE(), NONE(), false, DAE.T_REAL_DEFAULT,
        false, NONE(), SimCodeVar.NOALIAS(), DAE.emptyElementSource,
        SimCodeVar.NONECAUS(), NONE(), {}, false, false, false, NONE(), NONE());
end makeTmpRealSimCodeVar;

protected function sortSparsePattern
  input list<SimCodeVar.SimVar> inSimVars;
  input list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> inSparsePattern;
  input Boolean useFMIIndex;
  output list<tuple<Integer, list<Integer>>> outSparse = {};
protected
  HashTable.HashTable ht;
  DAE.ComponentRef cref;
  Integer size, i, j;
  list<Integer> intLst;
  array<Integer> intArr;
  list<DAE.ComponentRef> crefs;
algorithm
  //create HT
  size := listLength(inSimVars);
  if size>0 then
    ht := HashTable.emptyHashTableSized(size);
    for var in inSimVars loop
      if not useFMIIndex then
        SimCodeVar.SIMVAR(name = cref, index=i) := var;
      else
        SimCodeVar.SIMVAR(name = cref) := var;
        i := getVariableIndex(var);
      end if;
      //print("Setup HashTable with cref: " + ComponentReference.printComponentRefStr(cref) + " index: "+ intString(i) + "\n");
      ht := BaseHashTable.add((cref, i), ht);
    end for;

    //translate
    for tpl in inSparsePattern loop
       (cref, crefs) := tpl;
       i := BaseHashTable.get(cref, ht);
       intLst := {};
       for cr in crefs loop
         j := BaseHashTable.get(cr, ht);
         intLst := j :: intLst;
       end for;
       intArr := listArray(intLst);
       Array.heapSort(intArr);
       intLst := arrayList(intArr);
       outSparse := (i, intLst) :: outSparse;
    end for;
    outSparse := List.sort(outSparse, Util.compareTupleIntGt);
  end if;
end sortSparsePattern;

protected function sortColoring
  input list<SimCodeVar.SimVar> inSimVars;
  input list<list<DAE.ComponentRef>> inColoring;
  output list<list<Integer>> outColoring = {};
protected
  HashTable.HashTable ht;
  Integer size, i, j;
  list<Integer> intLst;
  DAE.ComponentRef cref;
algorithm
  //create HT
  size := listLength(inSimVars);
  if size>0 then
  ht := HashTable.emptyHashTableSized(size);
  for var in inSimVars loop
    SimCodeVar.SIMVAR(name = cref, index=i) := var;
    //print("Setup HashTable with cref: " + ComponentReference.printComponentRefStr(cref) + " index: "+ intString(i) + "\n");
    ht := BaseHashTable.add((cref, i), ht);
  end for;

  //translate
  for crefs in inColoring loop
     intLst := {};
     for cr in crefs loop
       j := BaseHashTable.get(cr, ht);
       intLst := j :: intLst;
     end for;
     outColoring := intLst :: outColoring;
  end for;
  end if;
end sortColoring;

protected function dumpSparsePatternInt
  input list<tuple<Integer, list<Integer>>> sparsePattern;
protected
  Integer i;
  list<Integer> lst;
algorithm
  for tpl in sparsePattern loop
    (i, lst) := tpl;
    print("Row   " + intString(i) + "\n");
    print("Cols: " + stringDelimitList(List.map(lst, intString)," ") + "\n");
  end for;
end dumpSparsePatternInt;

protected function dumpSparsePattern
  input list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> sparsePattern;
protected
  DAE.ComponentRef cr;
  list<DAE.ComponentRef> crefs;
algorithm
  for tpl in sparsePattern loop
    (cr, crefs) := tpl;
    print("Row   " + ComponentReference.printComponentRefStr(cr) + "\n");
    print("Cols: " + stringDelimitList(List.map(crefs, ComponentReference.printComponentRefStr)," ") + "\n");
  end for;
end dumpSparsePattern;


protected function createDerivativeMatrix
"translates BackendDAE.SymbolicJacobian to SimCode.DerivativeMatrix."
  input BackendDAE.Jacobian inJacobian;
  input Integer iuniqueEqIndex;
  output Option<SimCode.DerivativeMatrix> res;
  output Integer ouniqueEqIndex;
protected
  Boolean debug = false;
algorithm
  (res, ouniqueEqIndex) := matchcontinue(inJacobian, iuniqueEqIndex)
  local

    BackendDAE.Variables emptyVars, dependentVars, independentVars, globalKnownVars, allvars, residualVars, systvars;
    BackendDAE.EquationArray emptyEqns, eqns;
    list<BackendDAE.Var> knvarLst, seedVarLst, independentVarsLst, dependentVarsLst, residualVarsLst, allVars;
    list<DAE.ComponentRef> independentComRefs, dependentVarsComRefs;

    DAE.ComponentRef x;
    BackendDAE.SparsePattern pattern;
    BackendDAE.SparseColoring sparseColoring;
    list<list<Integer>> coloring;
    list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> sparsepatternComRefs, sparsepatternComRefsT;
    list<tuple<Integer, list<Integer>>> sparseInts, sparseIntsT;

    BackendDAE.EqSystem syst;
    BackendDAE.Shared shared;
    BackendDAE.StrongComponents comps;

    list<SimCodeVar.SimVar> tempvars;
    String name, dummyVar;
    Integer maxColor, uniqueEqIndex, nonZeroElements, nRows, index, nAllVars;

    list<SimCode.SimEqSystem> columnEquations;
    list<SimCodeVar.SimVar> columnVars, innerVars, residualSimVars;
    list<SimCodeVar.SimVar> varsSeedIndex, seedVars, indexVars;

    String errorMessage;

    DAE.FunctionTree funcs;

    SimCode.HashTableCrefToSimVar crefSimVarHT;
    HashTableCrefSimVar.HashTable hashTable;

    Option<SimCode.DerivativeMatrix> outRes;
    SimCode.OMSIFunction omsiJacFunction;

  case (BackendDAE.EMPTY_JACOBIAN(), _) then (NONE(), iuniqueEqIndex);

  case (BackendDAE.FULL_JACOBIAN(_), _) then (NONE(), iuniqueEqIndex);

  // translate only sparcity pattern
  case (BackendDAE.GENERIC_JACOBIAN(NONE(),pattern as (sparsepatternComRefs, sparsepatternComRefsT,
                                           (independentComRefs, dependentVarsComRefs), _),
                                           sparseColoring), _)
    equation
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("create sparse pattern for algebraic loop time: " + realString(clock()) + "\n");
        BackendDump.dumpSparsityPattern(pattern, "---+++ SparsePattern +++---");
      end if;
      seedVars = list(makeTmpRealSimCodeVar(cr, BackendDAE.SEED_VAR()) for cr in independentComRefs);
      indexVars = list(makeTmpRealSimCodeVar(cr, BackendDAE.VARIABLE()) for cr in dependentVarsComRefs);

      (seedVars, index) = rewriteIndex(seedVars, 0);   // ToDo: why start twice at zero?
      //indexVars = rewriteIndex(indexVars, 0);
      (indexVars, index) = rewriteIndex(indexVars, index);
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("\n---+++ seedVars variables +++---\n");
        print(Tpl.tplString(SimCodeDump.dumpVarsShort, seedVars));
        print("\n---+++ indexVars variables +++---\n");
        print(Tpl.tplString(SimCodeDump.dumpVarsShort, indexVars));
      end if;
      //sort sparse pattern
      varsSeedIndex = listAppend(seedVars, indexVars);
      //sort sparse pattern
      sparseInts = sortSparsePattern(varsSeedIndex, sparsepatternComRefs, false);
      sparseIntsT = sortSparsePattern(varsSeedIndex, sparsepatternComRefsT, false);

      // set sparse pattern
      coloring = sortColoring(seedVars, sparseColoring);
      maxColor = listLength(sparseColoring);

      if Flags.isSet(Flags.JAC_DUMP2) then
        print("created sparse pattern for algebraic loop time: " + realString(clock()) + "\n");
      end if;

    then (SOME(SimCode.DERIVATIVE_MATRIX({}, "", sparseInts, sparseIntsT, coloring, maxColor)), iuniqueEqIndex);

  // translate omsi_function and sparsity pattern
  case (BackendDAE.GENERIC_JACOBIAN(SOME((BackendDAE.DAE(eqs={syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))},
                                  shared=shared), name,
                                  independentVarsLst, residualVarsLst, dependentVarsLst)),
                                    (sparsepatternComRefs, sparsepatternComRefsT, (_, _), _),
                                    sparseColoring), _)
    equation
      if Flags.isSet(Flags.JAC_DUMP2) then
        print("analytical Jacobians -> creating SimCode equations for Matrix " + name + " time: " + realString(clock()) + "\n");
      end if;
      // generate also discrete equations, they might be introduced by wrapFunctionCalls

      (omsiJacFunction, uniqueEqIndex) = generateEquationsForComponents(comps, syst, shared, iuniqueEqIndex);

      if Flags.isSet(Flags.JAC_DUMP2) then
        print("analytical Jacobians -> created all SimCode equations for Matrix " + name +  " time: " + realString(clock()) + "\n");
      end if;

      // create SimCodeVar.SimVars from jacobian vars
      dummyVar = ("dummyVar" + name);
      x = DAE.CREF_IDENT(dummyVar, DAE.T_REAL_DEFAULT, {});
      emptyVars =  BackendVariable.emptyVars();

      residualVars = BackendVariable.listVar1(residualVarsLst);
      independentVars = BackendVariable.listVar1(independentVarsLst);

      // get cse and other aux vars > columnVars
      ((allVars, _)) = BackendVariable.traverseBackendDAEVars(syst.orderedVars, getFurtherVars , ({}, x));
      systvars = BackendVariable.listVar1(allVars);
      ((columnVars, _)) =  BackendVariable.traverseBackendDAEVars(systvars, traversingdlowvarToSimvar, ({}, emptyVars));
      columnVars = List.map1(columnVars, setSimVarKind, BackendDAE.JAC_DIFF_VAR());
      columnVars = List.map1(columnVars, setSimVarMatrixName, SOME(name));
      innerVars = rewriteIndex(columnVars, 0);

      (innerVars, columnVars) = createJacSimVarsColumn(dependentVarsLst, x, residualVars, 0, listLength(innerVars), name, innerVars, {});

      if Flags.isSet(Flags.JAC_DUMP2) then
        print("\n---+++ all column variables +++---\n");
        print(Tpl.tplString(SimCodeDump.dumpVarsShort, columnVars));
        print("analytical Jacobians -> create all SimCode vars for Matrix " + name + " time: " + realString(clock()) + "\n");
      end if;

      ((seedVars, _)) =  BackendVariable.traverseBackendDAEVars(independentVars, traversingdlowvarToSimvar, ({}, emptyVars));
      ((indexVars, _)) =  BackendVariable.traverseBackendDAEVars(residualVars, traversingdlowvarToSimvar, ({}, emptyVars));
      seedVars = rewriteIndex(listReverse(seedVars), 0);
      indexVars = rewriteIndex(listReverse(indexVars), 0);

      if Flags.isSet(Flags.JAC_DUMP2) then
        print("\n---+++ seedVars variables +++---\n");
        print(Tpl.tplString(SimCodeDump.dumpVarsShort, seedVars));
        print("\n---+++ indexVars variables +++---\n");
        print(Tpl.tplString(SimCodeDump.dumpVarsShort, indexVars));
      end if;
      //sort sparse pattern
      varsSeedIndex = listAppend(seedVars, indexVars);
      sparseInts = sortSparsePattern(varsSeedIndex, sparsepatternComRefs, false);
      sparseIntsT = sortSparsePattern(varsSeedIndex, sparsepatternComRefsT, false);

      // set sparse pattern
      coloring = sortColoring(varsSeedIndex, sparseColoring);
      maxColor = listLength(sparseColoring);

      // create seed vars
      seedVars = replaceSeedVarsName(seedVars, name);
      seedVars = List.map1(seedVars, setSimVarKind, BackendDAE.SEED_VAR());
      seedVars = List.map1(seedVars, setSimVarMatrixName, SOME(name));

      if Flags.isSet(Flags.JAC_DUMP2) then
        print("analytical Jacobians -> transformed to SimCode for Matrix " + name + " time: " + realString(clock()) + "\n");
      end if;

      //rewrite index
      (columnVars, index) = rewriteIndex(columnVars, 0);
      (innerVars, index) = rewriteIndex(innerVars, index);
      (seedVars, index) = rewriteIndex(seedVars, index);    // count local inputVars always last

      // create hash table
      nAllVars = (listLength(seedVars)+listLength(innerVars)+listLength(indexVars));
      hashTable = fillLocalHashTable({seedVars, innerVars, columnVars}, nAllVars);

      // rewrite omsiJacFunction variables
      omsiJacFunction.inputVars = seedVars;
      omsiJacFunction.innerVars = innerVars;
      omsiJacFunction.outputVars = columnVars;
      omsiJacFunction.nAllVars = nAllVars;
      omsiJacFunction.context = SimCodeFunction.JACOBIAN_CONTEXT(SOME(hashTable));

      if debug then
        dumpOMSIFunc(omsiJacFunction, "\nJacobian OMSIFunction");
        print("\nLocal jacobian hash table:\n");
        BaseHashTable.dumpHashTableStatistics(hashTable);
      end if;

      outRes = SOME(SimCode.DERIVATIVE_MATRIX(
        columns = {omsiJacFunction},
        matrixName = name,
        sparsity = sparseInts,
        sparsityT = sparseIntsT,
        coloredCols = coloring,
        maxColorCols = maxColor));

      then (outRes, uniqueEqIndex);

  else
    equation
      if Flags.isSet(Flags.JAC_DUMP) then
        errorMessage = "function createSymbolicSimulationJacobian failed.";
        Error.addInternalError(errorMessage, sourceInfo());
      end if;
    then (NONE(), iuniqueEqIndex);

  end matchcontinue;
end createDerivativeMatrix;


// =============================================================================
// section with unsorted function
//
// TODO: clean up this section ;)
// =============================================================================

protected function isSimEqSys  "checks if the given SES needs an additional equationsystem for the simulation and therefore skips an simEqIdx in the c-file.
this is used to get the right simCode-eq-mapping for hpcm.
add more cases here if you know for which cases this happens.
author: Waurich TUD 2013-11 "
  input SimCode.SimEqSystem simEqSysIn;
  output Boolean isEqSys;
algorithm
  isEqSys := match(simEqSysIn)
  case(SimCode.SES_NONLINEAR())
    then true;
  else
    then false;
  end match;
end isSimEqSys;

protected function collectDelayExpressions
"Put expression into a list if it is a call to delay().
Useable as a function parameter for Expression.traverseExpression."
  input DAE.Exp e;
  input list<DAE.Exp> acc;
  output DAE.Exp outExp;
  output list<DAE.Exp> outAcc;
algorithm
  (outExp,outAcc) := match (e,acc)
    case (DAE.CALL(path = Absyn.IDENT("delay")), _)
      then (e, e :: acc);
    else (e,acc);
  end match;
end collectDelayExpressions;

public function extractDelayedExpressions
  input BackendDAE.BackendDAE dlow;
  output list<tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>>> delayedExps;
  output Integer maxDelayedExpIndex;
algorithm
  (delayedExps, maxDelayedExpIndex) := matchcontinue(dlow)
    local
      list<DAE.Exp> exps;
    case _
      equation
        ((_,exps)) = BackendDAEUtil.traverseBackendDAEExps(dlow, Expression.traverseSubexpressionsHelper, (collectDelayExpressions, {}));
        delayedExps = List.map(exps, extractIdAndExpFromDelayExp);
        maxDelayedExpIndex = List.applyAndFold(delayedExps, intMax, Util.tuple21, -1);
      then
        (delayedExps, maxDelayedExpIndex+1);
    else
      equation
        Error.addInternalError("function extractDelayedExpressions failed", sourceInfo());
      then
        fail();
  end matchcontinue;
end extractDelayedExpressions;

function extractIdAndExpFromDelayExp
  input DAE.Exp delayCallExp;
  output tuple<Integer, tuple<DAE.Exp, DAE.Exp, DAE.Exp>> delayedExp;
algorithm
  delayedExp :=
  match (delayCallExp)
    local
      DAE.Exp  e, delay, delayMax;
      Integer i;
    case (DAE.CALL(path=Absyn.IDENT("delay"), expLst={DAE.ICONST(i), e, delay, delayMax}))
    then ((i, (e, delay, delayMax)));
  end match;
end extractIdAndExpFromDelayExp;

public function createExtObjInfo
  input BackendDAE.Shared shared;
  output SimCode.ExtObjInfo extObjInfo;
protected
  BackendDAE.Variables evars;
  list<BackendDAE.Var> evarLst;
  list<SimCode.ExtAlias> aliases;
  list<SimCodeVar.SimVar> simvars;
algorithm
  BackendDAE.SHARED(externalObjects=evars) := shared;
  evarLst := BackendVariable.varList(evars);
  evarLst := orderExtVars(evarLst);
  //evarLst := listReverse(evarLst);
  (simvars, aliases) := extractExtObjInfo2(evarLst, evars);
  extObjInfo := SimCode.EXTOBJINFO(simvars, aliases);
end createExtObjInfo;

protected function orderExtVars"External Variables have to be ordered.
It might occure that their binding expressions are dependent on other external variables and therefore, these vars and their binding exps have to be causalized.
author: waurich TUD 08.2015"
  input list<BackendDAE.Var> varLstIn;
  output list<BackendDAE.Var> varLstOut;
protected
  Integer nVars,nEqs;
  list<Integer> order;
  array<Integer> ass1,ass2;
  BackendDAE.IncidenceMatrix m,  mT;
  list<list<Integer>> comps;
  list<BackendDAE.Var> varsWithBind, varsWithoutBind;
  list<DAE.Exp> bindExps;
  list<BackendDAE.Equation> eqs;
algorithm
  try
    (varsWithBind,varsWithoutBind) := List.separateOnTrue(varLstIn,BackendVariable.varHasBindExp);
    (comps,ass1,ass2) := BackendDAEUtil.causalizeVarBindSystem(varsWithBind);
    order := List.map1(List.flatten(comps),Array.getIndexFirst,ass1);
    varsWithBind := List.map1(order,List.getIndexFirst,varsWithBind);
    varLstOut := listAppend(varsWithoutBind,varsWithBind);
  else
    varLstOut := varLstIn;
  end try;
end orderExtVars;

protected function extractExtObjInfo2
  input list<BackendDAE.Var> varLst;
  input BackendDAE.Variables evars;
  output list<SimCodeVar.SimVar> vars = {};
  output list<SimCode.ExtAlias> aliases = {};
algorithm
  for bv in varLst loop
    _ := match bv
      local
        DAE.ComponentRef cr, name;
        SimCodeVar.SimVar sv;
      case BackendDAE.VAR(varName=name, bindExp=SOME(DAE.CREF(cr, _)), varKind=BackendDAE.EXTOBJ(_))
        equation
          aliases = (name, cr)::aliases;
        then ();
      else
        equation
          sv = dlowvarToSimvar(bv, NONE(), evars);
          vars = sv::vars;
        then ();
      end match;
  end for;
  vars := Dangerous.listReverseInPlace(vars);
  aliases := Dangerous.listReverseInPlace(aliases);
end extractExtObjInfo2;

protected function createAlgorithmAndEquationAsserts
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer, list<SimCode.SimEqSystem>> acc;
  output tuple<Integer, list<SimCode.SimEqSystem>> algorithmAndEquationAsserts;
algorithm
  algorithmAndEquationAsserts := matchcontinue (syst, shared, acc)
    local
      list<SimCode.SimEqSystem> simeqns;
      list<DAE.Algorithm> res;
      BackendDAE.EquationArray eqns, reqns;
      BackendDAE.Variables vars;
      list<SimCode.SimEqSystem> result;
      Integer uniqueEqIndex;

    case (BackendDAE.EQSYSTEM(orderedVars = vars), BackendDAE.SHARED(), (uniqueEqIndex, simeqns))
      equation
        // get minmax and nominal asserts
        res = BackendVariable.traverseBackendDAEVars(vars, BackendVariable.getMinMaxAsserts, {});
        (result, uniqueEqIndex) = List.mapFold(res, dlowAlgToSimEqSystem, uniqueEqIndex);
        result = listAppend(result, simeqns);
      then ((uniqueEqIndex, result));
    else
      equation
        Error.addInternalError("function createAlgorithmAndEquationAsserts failed", sourceInfo());
      then fail();
  end matchcontinue;
end createAlgorithmAndEquationAsserts;

public function traversedlowEqToSimEqSystem
  input BackendDAE.Equation inEq;
  input tuple<Integer, list<SimCode.SimEqSystem>> inTpl;
  output BackendDAE.Equation outEq;
  output tuple<Integer, list<SimCode.SimEqSystem>> outTpl;
algorithm
  (outEq,outTpl) := matchcontinue (inEq,inTpl)
    local
      BackendDAE.Equation e;
      SimCode.SimEqSystem se;
      list<SimCode.SimEqSystem> seqnlst;
      Integer uniqueEqIndex;
    case (e, (uniqueEqIndex, seqnlst))
      equation
        (se, uniqueEqIndex) = dlowEqToSimEqSystem(e, uniqueEqIndex);
      then (e, (uniqueEqIndex, se::seqnlst));
    else (inEq,inTpl);
  end matchcontinue;
end traversedlowEqToSimEqSystem;

public function extractDiscreteModelVars
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input list<DAE.ComponentRef> acc;
  output list<DAE.ComponentRef> discreteModelVars;
algorithm
  discreteModelVars := matchcontinue (syst, shared, acc)
    local
      BackendDAE.Variables v;
      BackendDAE.EquationArray e;
      list<DAE.ComponentRef> vLst2;

    case (BackendDAE.EQSYSTEM(orderedVars=v), _, _)
      equation
        // select all discrete vars.
        // remove those vars that are solved in when equations
        // replace var with cref
        vLst2 = BackendVariable.traverseBackendDAEVars(v, traversingisVarDiscreteCrefFinder, acc);
        // vLst2 = List.unionOnTrue(vLst2, vLst1, ComponentReference.crefEqual);
      then vLst2;
    else
      equation
        Error.addInternalError("function extractDiscreteModelVars failed", sourceInfo());
      then fail();
  end matchcontinue;
end extractDiscreteModelVars;

protected function traversingisVarDiscreteCrefFinder
  input BackendDAE.Var inVar;
  input list<DAE.ComponentRef> inTpl;
  output BackendDAE.Var outVar;
  output list<DAE.ComponentRef> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      list<DAE.ComponentRef> cr_lst;
      DAE.ComponentRef cr;
    case (v, cr_lst)
      equation
        true = BackendVariable.isVarDiscrete(v);
        cr = BackendVariable.varCref(v);
      then (v, cr::cr_lst);
    else (inVar,inTpl);
  end matchcontinue;
end traversingisVarDiscreteCrefFinder;

protected function jacToSimjac
  input tuple<Integer, Integer, BackendDAE.Equation> jac;
  input BackendDAE.Variables v;
  output tuple<Integer, Integer, SimCode.SimEqSystem> simJac;
algorithm
  simJac := match (jac, v)
    local
      Integer row;
      Integer col;
      DAE.Exp e;
      DAE.ElementSource source;
      BackendDAE.EquationAttributes eqAttr;

    case ((row, col, BackendDAE.RESIDUAL_EQUATION(exp=e, source=source, attr=eqAttr)), _)
      equation
        // rhs_exp = BackendDAEUtil.getEqnsysRhsExp(e, v, NONE());
        // rhs_exp_1 = ExpressionSimplify.simplify(rhs_exp);
        // then ((row - 1, col - 1, SimCode.SES_RESIDUAL(rhs_exp_1)));
      then
        ((row - 1, col - 1, SimCode.SES_RESIDUAL(0, e, source, eqAttr)));
  end match;
end jacToSimjac;

protected function simJacCSRToCSC"outputs true if a simjac entry of type <row,col> is before another in the sense of a compressed sparse column format"
  input tuple<Integer,Integer,SimCode.SimEqSystem> e1; //<row,col>
  input tuple<Integer,Integer,SimCode.SimEqSystem> e2;
  output Boolean isGt;
protected
  Integer r1,r2,c1,c2;
algorithm
  (r1,c1,_) := e1;
  (r2,c2,_) := e2;
  if intNe(c1,c2) then
    isGt := intGt(c1,c2);
  else
    isGt := intGt(r1,r2);
  end if;
end simJacCSRToCSC;

protected function createSingleWhenEqnCode
  input BackendDAE.Equation inEquation;
  input list<BackendDAE.Var> inVars;
  input BackendDAE.Shared shared;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (equations_, ouniqueEqIndex, otempvars) := matchcontinue(inEquation, inVars, shared, iuniqueEqIndex, itempvars)
    local
      DAE.Exp cond, e;
      DAE.ComponentRef left;
      DAE.ElementSource source;
      list<DAE.ComponentRef> crefs;
      BackendDAE.WhenEquation elseWhen;
      list<DAE.ComponentRef> conditions;
      SimCode.SimEqSystem elseWhenEquation;
      Boolean initialCall;
      list<BackendDAE.WhenOperator> whenStmtLst;
      Integer uniqueEqIndex;
      Option<BackendDAE.WhenEquation> oelseWhen;
      SimCode.SimEqSystem simElseWhenEq;
      Option<SimCode.SimEqSystem> osimElseWhenEq;
      BackendDAE.EquationAttributes eqAttr;


    // when eq without else
    case (BackendDAE.WHEN_EQUATION(whenEquation=BackendDAE.WHEN_STMTS(condition=cond, whenStmtLst=whenStmtLst, elsewhenPart = oelseWhen), source=source, attr=eqAttr), _, _, _, _)
      algorithm
        for stmt in whenStmtLst loop
          _ :=  match stmt
            case BackendDAE.ASSIGN(left = DAE.CREF(componentRef = left)) equation
              crefs = List.map(inVars, BackendVariable.varCref);
              List.map1rAllValue(crefs, ComponentReference.crefPrefixOf, true, left);
            then ();
            else ();
          end match;
        end for;
        if isSome(oelseWhen) then
          SOME(elseWhen) := oelseWhen;
          (simElseWhenEq, uniqueEqIndex) := createElseWhenEquation(elseWhen, inVars, iuniqueEqIndex+1, source, eqAttr);
          osimElseWhenEq := SOME(simElseWhenEq);
        else
          uniqueEqIndex := iuniqueEqIndex+1;
          osimElseWhenEq := NONE();
        end if;
        (conditions, initialCall) := BackendDAEUtil.getConditionList(cond);
      then ({SimCode.SES_WHEN(iuniqueEqIndex, conditions, initialCall, whenStmtLst, osimElseWhenEq, source, eqAttr)}, uniqueEqIndex, itempvars);

    // failure
    else
      equation
        Error.addInternalError("function createSingleWhenEqnCode failed. When equations currently only supported on form v = ...", sourceInfo());
      then fail();
  end matchcontinue;
end createSingleWhenEqnCode;

protected function createElseWhenEquation
  input BackendDAE.WhenEquation inElseWhenEquation;
  input list<BackendDAE.Var> inVars;
  input Integer iuniqueEqIndex;
  input DAE.ElementSource inElementSource;
  input BackendDAE.EquationAttributes inEqAttr;
  output SimCode.SimEqSystem outSimEqSystem;
  output Integer ouniqueEqIndex;
algorithm
  (outSimEqSystem, ouniqueEqIndex) := match (inElseWhenEquation, inElementSource)
    local
      DAE.ComponentRef left;
      DAE.Exp right, cond;
      BackendDAE.WhenEquation elseWhenEquation;
      Option<BackendDAE.WhenEquation> oelseWhenEquation;
      SimCode.SimEqSystem simElseWhenEq;
      Option<SimCode.SimEqSystem> osimElseWhenEq;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;
      list<BackendDAE.WhenOperator> whenStmtLst;
      Integer uniqueEqIndex;
      list<DAE.ComponentRef> crefs;

      // when eq with else
    case (BackendDAE.WHEN_STMTS(condition=cond, whenStmtLst=whenStmtLst, elsewhenPart = oelseWhenEquation), _) algorithm
      for stmt in whenStmtLst loop
        _ :=  match stmt
          case BackendDAE.ASSIGN(left = DAE.CREF(componentRef = left)) equation
            crefs = List.map(inVars, BackendVariable.varCref);
            List.map1rAllValue(crefs, ComponentReference.crefPrefixOf, true, left);
          then ();
          else ();
        end match;
      end for;
      if isSome(oelseWhenEquation) then
        SOME(elseWhenEquation) := oelseWhenEquation;
        (simElseWhenEq, uniqueEqIndex) := createElseWhenEquation(elseWhenEquation, inVars, iuniqueEqIndex+1, inElementSource, inEqAttr);
        osimElseWhenEq := SOME(simElseWhenEq);
      else
        uniqueEqIndex := iuniqueEqIndex+1;
        osimElseWhenEq := NONE();
      end if;
      (conditions, initialCall) := BackendDAEUtil.getConditionList(cond);
    then (SimCode.SES_WHEN(iuniqueEqIndex, conditions, initialCall, whenStmtLst, osimElseWhenEq, inElementSource, inEqAttr), uniqueEqIndex);
  end match;
end createElseWhenEquation;

protected function createSingleIfEqnCode
  input BackendDAE.Equation inEquation;
  input list<BackendDAE.Var> inVars;
  input BackendDAE.Shared shared;
  input Boolean genDiscrete;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (equations_, ouniqueEqIndex, otempvars) := matchcontinue(inEquation, inVars, shared, genDiscrete, iuniqueEqIndex, itempvars)
    local
      list<DAE.Exp> conditions;
      Integer uniqueEqIndex;

      list<SimCodeVar.SimVar> tempvars;
      list<list<BackendDAE.Equation>> eqnsLst;
      list<BackendDAE.Equation> elseqns;
      list<tuple<DAE.Exp, list<SimCode.SimEqSystem>>> ifbranches;
      DAE.ElementSource source_;
      BackendDAE.ExtraInfo ei;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.IF_EQUATION(conditions=conditions, eqnstrue=eqnsLst, eqnsfalse=elseqns, source=source_, attr=eqAttr), _,
          BackendDAE.SHARED(info = ei), _, _, _) equation
      (ifbranches, uniqueEqIndex, tempvars) = createEquationsIfBranch(conditions, eqnsLst, inVars, shared, genDiscrete, iuniqueEqIndex, itempvars);
      (equations_, uniqueEqIndex, tempvars) = createEquationsfromList(elseqns, inVars, uniqueEqIndex, tempvars, ei, genDiscrete);
    then ({SimCode.SES_IFEQUATION(uniqueEqIndex, ifbranches, equations_, source_, eqAttr)}, uniqueEqIndex+1, tempvars);

    else equation
      Error.addInternalError("SimCodeUtil.createSingleIfEqnCode failed.", sourceInfo());
    then fail();
  end matchcontinue;
end createSingleIfEqnCode;

protected function createEquationsIfBranch
  input list<DAE.Exp> inConditions;
  input list<list<BackendDAE.Equation>> inEquationsLst;
  input list<BackendDAE.Var> inVars;
  input BackendDAE.Shared shared;
  input Boolean genDiscrete;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output list<tuple<DAE.Exp, list<SimCode.SimEqSystem>>> outEquations;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (outEquations, ouniqueEqIndex, otempvars) := matchcontinue(inConditions, inEquationsLst, inVars, shared, genDiscrete, iuniqueEqIndex, itempvars)
    local
      list<BackendDAE.Equation> eqns;
      list<list<BackendDAE.Equation>> eqnsLst;
      DAE.Exp  condition;
      list<DAE.Exp>  conditionList;
      list<SimCodeVar.SimVar> tempvars;
      Integer uniqueEqIndex;
      list<SimCode.SimEqSystem> equations_;
      tuple<DAE.Exp, list<SimCode.SimEqSystem>> ifbranch;
      list<tuple<DAE.Exp, list<SimCode.SimEqSystem>>> ifbranches;
      BackendDAE.ExtraInfo ei;

    case ({}, {}, _, _, _, _, _)
    then ({}, iuniqueEqIndex, itempvars);

    case (condition::conditionList, eqns::eqnsLst, _,
          BackendDAE.SHARED(info = ei), _, _, _) equation
      (equations_, uniqueEqIndex, tempvars) = createEquationsfromList(eqns, inVars, iuniqueEqIndex, itempvars, ei, genDiscrete);
      ifbranch = ((condition, equations_));
      (ifbranches, uniqueEqIndex, tempvars) = createEquationsIfBranch(conditionList, eqnsLst, inVars, shared, genDiscrete, uniqueEqIndex, tempvars);
      ifbranches = ifbranch::ifbranches;
    then (ifbranches, uniqueEqIndex, tempvars);

    else equation
      Error.addInternalError("SimCodeUtil.createEquationfromList failed.", sourceInfo());
    then fail();
  end matchcontinue;
end createEquationsIfBranch;

public function createEquationsfromBackendDAE
  input BackendDAE.BackendDAE inBDAE;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input Boolean genDiscrete = false;
  input Boolean includeWhen = false;
  input Boolean skipDiscInZc = false;
  input Boolean skipDiscInAlgorithm = false;
  output list<list<SimCode.SimEqSystem>> outEquations = {};
  output Integer uniqueEqIndex = iuniqueEqIndex;
  output list<SimCodeVar.SimVar> tempvars = itempvars;
protected
  BackendDAE.StrongComponents comps;
  list<SimCode.SimEqSystem> simEqs, zeroVarEquations;
algorithm
  for syst in inBDAE.eqs loop
    // get components
    comps := BackendDAEUtil.getCompsOfMatching(syst.matching);

    // create SimCode equatinos
    (simEqs, _, uniqueEqIndex, tempvars) := createEquations(includeWhen, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, syst, inBDAE.shared, comps, uniqueEqIndex, tempvars);

    // process also the zeroVariable equations
    (uniqueEqIndex, zeroVarEquations) := BackendEquation.traverseEquationArray(syst.removedEqs, SimCodeUtil.traversedlowEqToSimEqSystem, (uniqueEqIndex, {}));

    // add the zero variable equations
    simEqs := listAppend(simEqs, zeroVarEquations);

    // add equations
    outEquations := listAppend(outEquations, {simEqs});
  end for;
end createEquationsfromBackendDAE;

public function createEquationsfromList
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Var> inVars;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input BackendDAE.ExtraInfo iextra;
  input Boolean genDiscrete = false;
  input Boolean includeWhen = false;
  input Boolean skipDiscInZc = false;
  input Boolean skipDiscInAlgorithm = false;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (equations_, ouniqueEqIndex, otempvars) := matchcontinue inEquations
    local
      BackendDAE.Variables vars1;
      BackendDAE.EquationArray eqns_1;
      BackendDAE.BackendDAE subsystem_dae;
      BackendDAE.StrongComponents comps;
      BackendDAE.EqSystem syst;
      BackendDAE.Shared shared;
      Integer uniqueEqIndex;
      list<SimCodeVar.SimVar> tempvars;

    case {}
    then ({}, iuniqueEqIndex, itempvars);

    case _ equation
      eqns_1 = BackendEquation.listEquation(inEquations);
      vars1 = BackendVariable.listVar1(inVars);
      syst = BackendDAEUtil.createEqSystem(vars1, eqns_1);
      shared = BackendDAEUtil.createEmptyShared(BackendDAE.ARRAYSYSTEM(), iextra, FCore.emptyCache(), FGraph.empty());
      subsystem_dae = BackendDAE.DAE({syst}, shared);
      (BackendDAE.DAE({syst as BackendDAE.EQSYSTEM(matching=BackendDAE.MATCHING(comps=comps))}, shared)) =
          BackendDAEUtil.transformBackendDAE( subsystem_dae, SOME((BackendDAE.NO_INDEX_REDUCTION(),
                                              BackendDAE.ALLOW_UNDERCONSTRAINED())), NONE(), NONE() );
      (equations_, _, uniqueEqIndex, tempvars) = createEquations(includeWhen, skipDiscInZc, genDiscrete, skipDiscInAlgorithm, syst, shared, comps, iuniqueEqIndex, itempvars);
    then (equations_, uniqueEqIndex, tempvars);

    else equation
      Error.addInternalError("SimCodeUtil.createEquationfromList failed.", sourceInfo());
    then fail();

  end matchcontinue;
end createEquationsfromList;

protected function createSingleComplexEqnCode
  input BackendDAE.Equation inEquation;
  input list<BackendDAE.Var> inVars;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input BackendDAE.ExtraInfo iextra;
  input Boolean genDiscrete;
  input DAE.FunctionTree funcTree;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (equations_, ouniqueEqIndex, otempvars) := matchcontinue(inEquation, inVars, iuniqueEqIndex, itempvars)
    local
      Integer uniqueEqIndex;
      DAE.Exp e1, e2;
      DAE.ElementSource source;
      list<DAE.ComponentRef> crefs;
      list<SimCode.SimEqSystem> resEqs;
      list<SimCodeVar.SimVar> tempvars;
      String s, s1, s2, s3;
      Boolean homotopySupport;
      BackendDAE.EquationAttributes eqAttr;

    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, attr=eqAttr), _, _, _) equation
      crefs = List.map(inVars, BackendVariable.varCref);
      e1 = Expression.replaceDerOpInExp(e1);
      e2 = Expression.replaceDerOpInExp(e2);
      (equations_, uniqueEqIndex, tempvars) = createSingleComplexEqnCode2(crefs, e1, e2, iuniqueEqIndex, itempvars, source, eqAttr, iextra, genDiscrete, inVars);
    then (equations_, uniqueEqIndex, tempvars);

    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2, source=source, attr=eqAttr), _, _, _) equation
      crefs = List.map(inVars, BackendVariable.varCref);

      // Check that all crefs are of Type Real
      // otherwise we can't solve that with one Non-linear equation
      true = List.mapMapBoolAnd(crefs, ComponentReference.crefLastType, Types.isRealOrSubTypeReal);

      // Simplify
      (e1, _) = ExpressionSimplify.simplify(e1);
      e1 = Expression.replaceDerOpInExp(e1);
      (e2, _) = ExpressionSimplify.simplify(e2);
      e2 = Expression.replaceDerOpInExp(e2);

      // Create nonlinear equation system from complex function
      (resEqs, uniqueEqIndex, tempvars, crefs) = createNonlinearResidualEquationsSingleComplex(e1, e2, source, eqAttr, iuniqueEqIndex, itempvars, crefs);
      (_, homotopySupport) = BackendEquation.traverseExpsOfEquation(inEquation, BackendDAEUtil.containsHomotopyCall, false);
    then ({SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(uniqueEqIndex, resEqs, crefs, 0, listLength(inVars)+listLength(tempvars)-listLength(itempvars), NONE(), homotopySupport, false, false), NONE(), eqAttr)}, uniqueEqIndex+1, tempvars);

    case (BackendDAE.COMPLEX_EQUATION(attr=eqAttr), _, _, _) equation
      crefs = List.map(inVars, BackendVariable.varCref);

      // check that all crefs are of Type Real
      // otherwise we can't solve that with one Non-linear equation
      true = List.mapMapBoolAnd(crefs, ComponentReference.crefLastType, Types.isRealOrSubTypeReal);

      // wbraun:
      // TODO: Fix createNonlinearResidualEquations support cases where
      //       solved variables are on rhs and also lhs. This is not
      //       considered yet there.
      (resEqs, uniqueEqIndex, tempvars) = createNonlinearResidualEquations({inEquation}, iuniqueEqIndex, itempvars, funcTree);
      (_, homotopySupport) = BackendEquation.traverseExpsOfEquation(inEquation, BackendDAEUtil.containsHomotopyCall, false);
    then ({SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(uniqueEqIndex, resEqs, crefs, 0, listLength(inVars)+listLength(tempvars)-listLength(itempvars), NONE(), homotopySupport, false, false), NONE(), eqAttr)}, uniqueEqIndex+1, tempvars);

    // failure
    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2), _, _, _) equation
      crefs = List.map(inVars, BackendVariable.varCref);

      // check that all crefs are of Type Real
      // otherwise we can't solve that with one Non-linear equation
      false = List.mapMapBoolAnd(crefs, ComponentReference.crefLastType, Types.isRealOrSubTypeReal);

      s1 = ExpressionDump.printExpStr(e1);
      s2 = ExpressionDump.printExpStr(e2);
      s3 = ComponentReference.printComponentRefListStr(crefs);
      s = stringAppendList({"No support of solving not real variables with a non-linear solver. Equation:\n", s1, " = " , s2, " solve for ", s3 });
      Error.addInternalError(s, sourceInfo());
    then fail();

    // failure
    case (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2), _, _, _) equation
      crefs = List.map(inVars, BackendVariable.varCref);

      // check that all crefs are of Type Real
      // otherwise we can't solve that with one Non-linear equation
      true = List.mapMapBoolAnd(crefs, ComponentReference.crefLastType, Types.isRealOrSubTypeReal);

      s1 = ExpressionDump.printExpStr(e1);
      s2 = ExpressionDump.printExpStr(e2);
      s3 = ComponentReference.printComponentRefListStr(crefs);
      s = stringAppendList({"complex equations currently only supported on form v = functioncall(...). Equation: ", s1, " = " , s2, " solve for ", s3 });
      Error.addInternalError(s, sourceInfo());
    then fail();
  end matchcontinue;
end createSingleComplexEqnCode;

// TODO: are the cases really correct?
protected function createSingleComplexEqnCode2
  input list<DAE.ComponentRef> crefs;
  input DAE.Exp inExp3;
  input DAE.Exp inExp4;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input DAE.ElementSource source;
  input BackendDAE.EquationAttributes eqKind;
  input BackendDAE.ExtraInfo iextra;
  input Boolean genDiscrete;
  input list<BackendDAE.Var> inVars;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
algorithm
  (equations_, ouniqueEqIndex, otempvars) := matchcontinue (crefs, inExp3, inExp4, iuniqueEqIndex, itempvars, source)
    local
      DAE.ComponentRef cr1, cr2;
      DAE.Exp e1, e2, e1_1, e2_1;
      list<DAE.Exp> expl, expl1;
      DAE.Statement stms;
      DAE.Type tp;
      DAE.CallAttributes attr;
      Absyn.Path path, rpath;
      list<DAE.Exp> expLst, crexplst ,e1lst, e2lst;
      DAE.Ident ident;
      list<tuple<DAE.Exp, DAE.Exp>> exptl;
      SimCode.SimEqSystem simeqn_complex;
      list<SimCode.SimEqSystem> eqSystlst;
      list<SimCodeVar.SimVar> tempvars;
      Integer uniqueEqIndex;
      list<DAE.Var> varLst;
      HashSet.HashSet ht;
      list<Integer> positions;
      String s, s1, s2, s3;
      list<BackendDAE.Equation> eqnLst;

    case (_, DAE.CAST(exp = e1), _, _, _, _)
      equation
        (equations_, ouniqueEqIndex, otempvars) =
          createSingleComplexEqnCode2(crefs, e1, inExp4, iuniqueEqIndex, itempvars, source, eqKind, iextra, genDiscrete, inVars);
      then
        (equations_, ouniqueEqIndex, otempvars);

    case (_, _, DAE.CAST(exp = e1), _, _, _)
      equation
        (equations_, ouniqueEqIndex, otempvars) =
          createSingleComplexEqnCode2(crefs, inExp3, e1, iuniqueEqIndex, itempvars, source, eqKind, iextra, genDiscrete, inVars);
      then
        (equations_, ouniqueEqIndex, otempvars);

    case (_, e1 as DAE.CREF(componentRef = cr2), e2, _, _, _)
      equation
        List.map1rAllValue(crefs, ComponentReference.crefPrefixOf, true, cr2);
        // ((e1_1, _)) = Expression.extendArrExp((e1, false));
        (e2_1, _) = Expression.extendArrExp(e2, false);
        // true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        tp = Expression.typeof(e1);
        stms = DAE.STMT_ASSIGN(tp, e1, e2_1, source);
      then
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex, {stms}, eqKind)}, iuniqueEqIndex+1, itempvars);

    case (_, e1, e2 as DAE.CREF(componentRef = cr2), _, _, _)
      equation
        List.map1rAllValue(crefs, ComponentReference.crefPrefixOf, true, cr2);
        // true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        (e1_1, _) = Expression.extendArrExp(e1, false);
        // ((e2_1, _)) = Expression.extendArrExp((e2, false));
        tp = Expression.typeof(e2);
        stms = DAE.STMT_ASSIGN(tp, e2, e1_1, source);
      then
        ({SimCode.SES_ALGORITHM(iuniqueEqIndex, {stms}, eqKind)}, iuniqueEqIndex+1, itempvars);

    /* Record() = f()  */
    case (_, DAE.CALL(path=path, expLst=expLst, attr=DAE.CALL_ATTR(ty= tp as DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path=rpath), varLst=varLst))), e2, _, _, _)
      equation

        true = Absyn.pathEqual(path, rpath);
        // check all crefs are on the lhs
        ht = HashSet.emptyHashSet();
        ht = List.fold(crefs, BaseHashSet.add, ht);
        expLst = Expression.traverseExpList(expLst, Expression.expandCrefs, 0) "The routines generate bad code for arrays inside the record unless we expand them";
        List.foldAllValue(expLst, createSingleComplexEqnCode3, true, ht);
        (e2_1, _) = Expression.extendArrExp(e2, false);

        // tmp = somexp
        ident = Absyn.pathStringUnquoteReplaceDot(path, "_");
        cr1 = ComponentReference.makeCrefIdent("$TMP_" + ident + intString(iuniqueEqIndex), tp, {});
        e1_1 = Expression.crefToExp(cr1);
        stms = DAE.STMT_ASSIGN(tp, e1_1, e2_1, source);
        simeqn_complex = SimCode.SES_ALGORITHM(iuniqueEqIndex, {stms}, eqKind);
        uniqueEqIndex = iuniqueEqIndex + 1;

        /* Expand the varLst. Each var might be an array or record. */
        crexplst = List.map1(varLst, Expression.generateCrefsExpFromExpVar, cr1);
        /* pair each of the expanded expressions to coressponding one*/
        exptl = List.threadTuple(expLst, crexplst);
        /* Create residual equations for each pair*/
        (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_SIMPLE_ASSIGN, source, eqKind, uniqueEqIndex);
        eqSystlst = simeqn_complex::eqSystlst;

        tempvars = createTempVars(varLst, cr1, itempvars);
      then
        (eqSystlst, uniqueEqIndex, tempvars);

    /* f() = Record()  */
    case (_, e1, DAE.CALL(path=path, expLst=expLst, attr=DAE.CALL_ATTR(ty= tp as DAE.T_COMPLEX(complexClassType=ClassInf.RECORD(path=rpath), varLst=varLst))), _, _, _)
      equation
        true = Absyn.pathEqual(path, rpath);
        // check all crefs are on the rhs => turn
        ht = HashSet.emptyHashSet();
        ht = List.fold(crefs, BaseHashSet.add, ht);
        expLst = Expression.traverseExpList(expLst, Expression.expandCrefs, 0) "The routines generate bad code for arrays inside the record unless we expand them";
        List.foldAllValue(expLst, createSingleComplexEqnCode3, true, ht);
        (e1_1, _) = Expression.extendArrExp(e1, false);
        // true = ComponentReference.crefEqualNoStringCompare(cr, cr2);
        // tmp = f()
        ident = Absyn.pathStringUnquoteReplaceDot(path, "_");
        cr1 = ComponentReference.makeCrefIdent("$TMP_" + ident + intString(iuniqueEqIndex), tp, {});
        e2_1 = Expression.crefExp(cr1);
        stms = DAE.STMT_ASSIGN(tp, e2_1, e1_1, source);
        simeqn_complex = SimCode.SES_ALGORITHM(iuniqueEqIndex, {stms}, eqKind);
        uniqueEqIndex = iuniqueEqIndex + 1;
        // Record()=tmp
        crexplst = List.map1(varLst, Expression.generateCrefsExpFromExpVar, cr1);
        exptl = List.threadTuple(expLst, crexplst);
        (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_SIMPLE_ASSIGN, source, eqKind, uniqueEqIndex);
        eqSystlst = simeqn_complex::eqSystlst;
        tempvars = createTempVars(varLst, cr1, itempvars);
      then
        (eqSystlst, uniqueEqIndex, tempvars);

    /* Tuple() = f()  */
    case (_, e1 as DAE.TUPLE(expl), e2 as DAE.CALL(), _, _, _)
      equation
        // debug
        // print("Tuple crefs Strings: "+ ComponentReference.printComponentRefListStr(crefs) + "\n");
        // print(" = ExpList : " + ExpressionDump.printExpListStr(expl) + "\n");
        tp = Expression.typeof(e1);

        //check that solved vars are on lhs
        ht = HashSet.emptyHashSet();
        ht = List.fold(crefs, BaseHashSet.add, ht);
        // check lhs depend on rhs
        false = Expression.expHasCrefsNoPreOrStart(e2,crefs);
        List.foldAllValue(expl, createSingleComplexEqnCode3, true, ht);

        eqSystlst = {SimCode.SES_ALGORITHM(iuniqueEqIndex, {DAE.STMT_TUPLE_ASSIGN(tp, expl, e2, source)}, eqKind)};
        uniqueEqIndex = iuniqueEqIndex + 1;
      then
        (eqSystlst, uniqueEqIndex, itempvars);

    // Tuple(crefs) = Tuple(expl)
    case (_, DAE.TUPLE(expl), DAE.TUPLE(expl1), _, _, _)
      equation
        // debug
        // print("Tuple crefs Strings: "+ ComponentReference.printComponentRefListStr(crefs) + "\n");
        // print(" = ExpList : " + ExpressionDump.printExpListStr(expl1) + "\n");

        //check that all crefs are on lhs
        ht = HashSet.emptyHashSet();
        ht = List.fold(crefs, BaseHashSet.add, ht);
        List.foldAllValue(expl, createSingleComplexEqnCode3, true, ht);

        // create all equations
        eqnLst = List.threadMap2(expl, expl1, BackendEquation.generateEquation, source, eqKind);

        // generate SimCode equations therefore
        (eqSystlst, uniqueEqIndex, tempvars) = createEquationsfromList(eqnLst, inVars, iuniqueEqIndex, itempvars, iextra, genDiscrete);
      then
        (eqSystlst, uniqueEqIndex, tempvars);

    // Tuple(expl) = Tuple(crefs)
    case (_, DAE.TUPLE(expl1), DAE.TUPLE(expl), _, _, _)
      equation
        // debug
        // print("Tuple crefs Strings: "+ ComponentReference.printComponentRefListStr(crefs) + "\n");
        // print(" = ExpList : " + ExpressionDump.printExpListStr(expl1) + "\n");

        //check that all crefs are on rhs
        ht = HashSet.emptyHashSet();
        ht = List.fold(crefs, BaseHashSet.add, ht);
        List.foldAllValue(expl, createSingleComplexEqnCode3, true, ht);

        // create all equations
        eqnLst = List.threadMap2(expl, expl1, BackendEquation.generateEquation, source, eqKind);

        // generate SimCode equations therefore
        (eqSystlst, uniqueEqIndex,_) = createEquationsfromList(eqnLst, inVars, iuniqueEqIndex, itempvars, iextra, genDiscrete);
      then
        (eqSystlst, uniqueEqIndex, itempvars);


    // failure
    case (_, e1, e2, _, _, _)
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        s1 = ExpressionDump.printExpStr(e1);
        s2 = ExpressionDump.printExpStr(e2);
        s3 = ComponentReference.printComponentRefListStr(crefs);
        s = stringAppendList({"function createSingleComplexEqnCode2 failed for: ", s1, " = " , s2, " solve for ", s3 });
        Debug.traceln(s);
    then
      fail();
  end matchcontinue;
end createSingleComplexEqnCode2;

protected function createSingleComplexEqnCode3
  input DAE.Exp inExp;
  input HashSet.HashSet iht;
  output Boolean outB;
  output HashSet.HashSet oht;
algorithm
  (outB, oht) := matchcontinue(inExp, iht)
    local
      DAE.ComponentRef cr;
      HashSet.HashSet ht;
      list<DAE.ComponentRef> crefs;
      list<DAE.Exp> expLst;

    case (DAE.CREF(componentRef=cr), _) guard BaseHashSet.has(cr, iht)
      equation
        ht = BaseHashSet.delete(cr, iht);
      then
        (true, ht);
    /* consider also array and record crefs */
    case (DAE.CREF(componentRef=cr), _)
      equation
        crefs = ComponentReference.expandCref(cr, true);
        false = valueEq({cr},crefs); // Not an expanded element
        expLst = List.map(crefs, Expression.crefExp);
        List.foldAllValue(expLst, createSingleComplexEqnCode3, true, iht);
      then (true, iht);
    case (DAE.RCONST(_), _) then (true, iht);
    case (DAE.ICONST(_), _) then (true, iht);
    case (DAE.BCONST(_), _) then (true, iht);
    case (DAE.CREF(componentRef=DAE.WILD()), _) then (true, iht);
    /* Consider also record constructor */
    case (DAE.CALL(expLst=expLst),_) equation
      List.foldAllValue(expLst, createSingleComplexEqnCode3, true, iht);
    then (true, iht);
    /* consider also array type */
    case (DAE.ARRAY(array=expLst),_) equation
      List.foldAllValue(expLst, createSingleComplexEqnCode3, true, iht);
    then (true, iht);
    else
      (false, iht);
  end matchcontinue;
end createSingleComplexEqnCode3;

protected function createSingleArrayEqnCode
  input Boolean genDiscrete;
  input list<BackendDAE.Equation> inEquations;
  input list<BackendDAE.Var> inVars;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  input BackendDAE.Shared shared;
  output list<SimCode.SimEqSystem> equations_;
  output list<SimCode.SimEqSystem> noDiscequations;
  output Integer ouniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars;
protected
  BackendDAE.Equation inEquation;
algorithm
  // first replace der() to match them as cref $DER. below
  inEquation := match listHead(inEquations)
    case inEquation as BackendDAE.ARRAY_EQUATION(_)
    algorithm
      inEquation.left := Expression.replaceDerOpInExp(inEquation.left);
      inEquation.right := Expression.replaceDerOpInExp(inEquation.right);
    then inEquation;
    end match;
  (equations_, noDiscequations, ouniqueEqIndex, otempvars) := matchcontinue(genDiscrete, inEquation, inVars)
    local
      list<Integer> ds;
      DAE.Exp e1, e2, lhse, rhse;
      list<DAE.Exp> ea1, ea2, expLst, expLstTmp;
      list<BackendDAE.Equation> re;
      list<BackendDAE.Var> vars;
      DAE.ComponentRef cr, cr_1, left;
      BackendDAE.Variables evars, vars1;
      DAE.FunctionTree funcs;
      DAE.ElementSource source;
      SimCode.SimEqSystem equation_;
      list<SimCode.SimEqSystem> eqSystlst;
      Integer uniqueEqIndex;
      String str;
      list<DAE.Dimension> dims;
      list<SimCodeVar.SimVar> tempvars;
      BackendDAE.EquationAttributes eqAttr;
      list<DAE.ComponentRef> crefstmp;
      DAE.Type ty,basety;
      list<tuple<DAE.Exp, DAE.Exp>> exptl;

    // An array equation
    // {z1,z2,..} = rhsexp -> solved for {z1,z2,..}
    // => tmp = rhsexp;
    // z1 = tmp[1]; z2 = tmp[2] ....
    case (_, (BackendDAE.ARRAY_EQUATION(dimSize=ds, left=e1, right=e2, source=source, attr=eqAttr)), _)
    guard Expression.isMatrix(e1) or Expression.isArray(e1)
    equation
      // Flattne multi-dimensional ARRAY{ARRAY} expressions
      expLst = Expression.flattenArrayExpToList(e1);
      // create the lhs tmp var
      ty = Expression.typeof(e1);
      (basety,dims) = Types.flattenArrayType(ty);
      ty = DAE.T_ARRAY(basety, dims);
      left = ComponentReference.makeCrefIdent("$TMP_" + intString(iuniqueEqIndex), ty, {});

      lhse = DAE.CREF(left,ty);
      // Expand the tmp cref and create the list of rhs vars
      // to update the original lhs vars
      crefstmp = ComponentReference.expandCref(left, false);
      expLstTmp = List.map(crefstmp, Expression.crefExp);
      tempvars = createArrayTempVar(left, ds, expLstTmp, itempvars);
      // Create the simple assignments for the lhs vars from the tmp rhs's
      exptl = List.threadTuple(expLst, expLstTmp);
      (eqSystlst, uniqueEqIndex) = List.map2Fold(exptl, makeSES_SIMPLE_ASSIGN, source, eqAttr, iuniqueEqIndex);
      // Create the array equation with the tmp var as lhs
      eqSystlst = SimCode.SES_ARRAY_CALL_ASSIGN(uniqueEqIndex, lhse, e2, source, eqAttr)::eqSystlst;
    then (eqSystlst, eqSystlst, uniqueEqIndex+1, tempvars);

    // An array equation
    // cref = rhsexp
    case (_, (BackendDAE.ARRAY_EQUATION(left=e1 as DAE.CREF(cr_1, _), right=e2, source=source, attr=eqAttr)), BackendDAE.VAR(varName=cr)::_)
    guard ComponentReference.crefEqual(cr_1, ComponentReference.crefStripLastSubs(cr))
    equation
      (e1, _) = BackendDAEUtil.collateArrExp(e1, NONE());
      (e2, _) = BackendDAEUtil.collateArrExp(e2, NONE());
      equation_ = SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex, e1, e2, source, eqAttr);
      uniqueEqIndex = iuniqueEqIndex + 1;
    then ({equation_}, {equation_}, uniqueEqIndex, itempvars);

    // An array equation
    // lhsexp = cref
    case (_, (BackendDAE.ARRAY_EQUATION(left=e1, right=e2 as DAE.CREF(cr_1, _), source=source, attr=eqAttr)), BackendDAE.VAR(varName=cr)::_)
    guard ComponentReference.crefEqual(cr_1, ComponentReference.crefStripLastSubs(cr))
    equation
      (e1, _) = BackendDAEUtil.collateArrExp(e1, NONE());
      (e2, _) = BackendDAEUtil.collateArrExp(e2, NONE());
      equation_ = SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex, e2, e1, source, eqAttr);
      uniqueEqIndex = iuniqueEqIndex + 1;
    then ({equation_}, {equation_}, uniqueEqIndex, itempvars);

    // An array equation
    // lhsexp = rhsexp
    case (_, (BackendDAE.ARRAY_EQUATION(left=lhse, right=rhse, source=source, attr=eqAttr)), BackendDAE.VAR(varName=cr)::_)
    equation
      (lhse, _) = BackendDAEUtil.collateArrExp(lhse, NONE());
      (rhse, _) = BackendDAEUtil.collateArrExp(rhse, NONE());
      BackendDAE.SHARED(functionTree = funcs) = shared;
      e1 = Expression.crefExp(cr);
      e2 = ExpressionSolve.solve2(lhse, rhse, e1, SOME(funcs), SOME(iuniqueEqIndex), true, BackendDAEUtil.isSimulationDAE(shared));
      equation_ = SimCode.SES_ARRAY_CALL_ASSIGN(iuniqueEqIndex, e1, e2, source, eqAttr);
      uniqueEqIndex = iuniqueEqIndex + 1;
    then ({equation_}, {equation_}, uniqueEqIndex, itempvars);

    // failure
    else equation
      BackendDAE.VAR(varName = cr)::_ = inVars;
      str = BackendDump.dumpEqnsStr(inEquations);
      str = "solving array equation: " + str + "\nfor variable: " + ComponentReference.printComponentRefStr(cr) + ".";
      Error.addInternalError(str, sourceInfo());
    then fail();
  end matchcontinue;
end createSingleArrayEqnCode;

protected function createSingleAlgorithmCode
  input list<BackendDAE.Equation> eqns;
  input list<BackendDAE.Var> vars;
  input Boolean skipDiscinAlgorithm;
  input Integer iuniqueEqIndex;
  output list<SimCode.SimEqSystem> equations_;
  output Integer ouniqueEqIndex;
algorithm
  (equations_, ouniqueEqIndex) := matchcontinue (eqns, skipDiscinAlgorithm)
    local
      DAE.Algorithm alg;
      list<DAE.ComponentRef> solvedVars, algOutVars, knownOutputCrefs;
      String crefsStr, algStr;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source;
      DAE.Expand crefExpand;
      BackendDAE.EquationAttributes eqAttr;
      list<SimCode.SimEqSystem> result;
      list<DAE.Exp> discreteVarsExp;
      constant Boolean debug = false;

    // normal call
    case (BackendDAE.ALGORITHM(alg=alg, source = source, expand=crefExpand, attr=eqAttr)::_, false) equation
      solvedVars = List.map(vars, BackendVariable.varCref);
      true = CheckModel.isCrefListAlgorithmOutput(solvedVars, alg, source, crefExpand);
      DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
    then ({SimCode.SES_ALGORITHM(iuniqueEqIndex, algStatements, eqAttr)}, iuniqueEqIndex+1);

    // remove discrete Vars
    case (BackendDAE.ALGORITHM(alg=alg, source=source, expand=crefExpand, attr=eqAttr)::_, true) equation
      solvedVars = List.map(vars, BackendVariable.varCref);
      true = CheckModel.isCrefListAlgorithmOutput(solvedVars, alg, source, crefExpand);
      DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      algStatements = BackendDAEUtil.removeDiscreteAssignments(algStatements, BackendVariable.listVar1(vars));
    then ({SimCode.SES_ALGORITHM(iuniqueEqIndex, algStatements, eqAttr)}, iuniqueEqIndex+1);

    // inverse Algorithm for single variable.
    case (BackendDAE.ALGORITHM(alg=alg, source=source, expand=crefExpand, attr=eqAttr)::_, false) equation
      // We need to solve an inverse problem of an algorithm section.
      DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
      algStatements = solveAlgorithmInverse(algStatements, vars);
    then ({SimCode.SES_ALGORITHM(iuniqueEqIndex, algStatements, eqAttr)}, iuniqueEqIndex+1);

    // inverse algorithms
    case (BackendDAE.ALGORITHM(alg=alg as DAE.ALGORITHM_STMTS(algStatements), source=source, expand=crefExpand, attr=eqAttr)::_, _) equation
      if debug then
        print("createSingleAlgorithmCode -> \n");
        BackendDump.dumpAlgorithms({DAE.ALGORITHM_STMTS(algStatements)}, 0);
      end if;

      // get and expand the searched variables
      solvedVars = List.map(vars, BackendVariable.varCref);
      solvedVars = List.unionList(List.map1(solvedVars, ComponentReference.expandCref, true));
      if debug then BackendDump.debugStrCrefLstStr("solvedVars : ", solvedVars, ", ", "\n"); end if;

      // get and expand all other variables
      algOutVars = CheckModel.checkAndGetAlgorithmOutputs(alg, source, crefExpand);
      algOutVars = List.unionList(List.map1(algOutVars, ComponentReference.expandCref, true));

      // the remaining quantity of all out vars to the solved vars
      knownOutputCrefs = List.setDifference(algOutVars, solvedVars);

      // filter since are not solvable with non-linear solver
      solvedVars = List.map(List.filterOnTrue(vars, BackendVariable.isVarNonDiscrete), BackendVariable.varCref);

      // discrete vars are added with there start value and by
      // event iteration we ensure that all variable are consistent
      discreteVarsExp = list(Expression.crefToExp(BackendVariable.varCref(v)) for v in List.filterOnTrue(vars, BackendVariable.isVarDiscrete));
      algStatements = BackendDAEOptimize.expandAlgorithmStmts(algStatements, discreteVarsExp, BackendVariable.listVar(vars), true);

      if debug then
        BackendDump.debugStrCrefLstStr("algOutVars : ", algOutVars, ", ", "\n");
        BackendDump.debugStrCrefLstStr("filtered solvedVars: ", solvedVars, ", ", "\n");
        BackendDump.debugStrCrefLstStr("knownOutputCrefs : ", knownOutputCrefs, ", ", "\n");
      end if;

      //Why should we have the same amount of solved vars and know vars?
      //true = intEq(listLength(solvedVars), listLength(knownOutputCrefs));

      alg = DAE.ALGORITHM_STMTS(algStatements);
      DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());

      if not listEmpty(solvedVars) then
        result = {SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(iuniqueEqIndex+1,
                      {SimCode.SES_INVERSE_ALGORITHM(iuniqueEqIndex, algStatements, knownOutputCrefs, true, eqAttr)},
                   solvedVars, 0, listLength(vars), NONE(), false, false, false), NONE(), eqAttr)};
        ouniqueEqIndex = iuniqueEqIndex+2;
      else
        result = {SimCode.SES_INVERSE_ALGORITHM(iuniqueEqIndex, algStatements, knownOutputCrefs, false, eqAttr)};
        ouniqueEqIndex = iuniqueEqIndex+1;
      end if;

    then (result, ouniqueEqIndex);

    // Error message, inverse algorithms cannot be solved for discrete variables
    case (BackendDAE.ALGORITHM(alg=alg, source=source, expand=crefExpand, attr=eqAttr)::_, _) equation
      solvedVars = List.map(vars, BackendVariable.varCref);
      false = CheckModel.isCrefListAlgorithmOutput(solvedVars, alg, source, crefExpand);

      crefsStr = ComponentReference.printComponentRefListStr(solvedVars);
      algStr =  DAEDump.dumpAlgorithmsStr({DAE.ALGORITHM(alg, source)});
      Error.addInternalError("Inverse Algorithm needs to be solved for " + crefsStr + " in\n" + algStr + "Discrete variables are not supported yet.", sourceInfo());
    then fail();

    // failure
    else equation
      Error.addInternalError("function createSingleAlgorithmCode failed", sourceInfo());
    then fail();
  end matchcontinue;
end createSingleAlgorithmCode;

public function createInitialEquations "author: lochel"
  input BackendDAE.BackendDAE inInitDAE;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> outInitialEqns = {};
  output Integer ouniqueEqIndex = iuniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars = itempvars;
protected
  BackendDAE.EquationArray  removedEqs;
  list<SimCodeVar.SimVar> tempvars;
  Integer uniqueEqIndex;
  list<SimCode.SimEqSystem> allEquations, knownVarEquations, solvedEquations, removedEquations, aliasEquations;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  BackendDAE.Variables globalKnownVars, aliasVars;
algorithm
  BackendDAE.DAE(systs, shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars, aliasVars=aliasVars)) := inInitDAE;
  removedEqs := BackendDAEUtil.collapseRemovedEqs(inInitDAE);
  // generate equations from the known unfixed variables
  ((uniqueEqIndex, knownVarEquations)) := BackendVariable.traverseBackendDAEVars(globalKnownVars, traverseKnVarsToSimEqSystem, (iuniqueEqIndex, {}));
  // generate equations from the solved systems
  (uniqueEqIndex, _, _, _, solvedEquations, _, tempvars, _, _, _, _) :=
      createEquationsForSystems(systs, shared, uniqueEqIndex, {}, itempvars, 0, SimCode.NO_MAPPING(), true);
  // generate equations from the removed equations
  ((uniqueEqIndex, removedEquations)) := BackendEquation.traverseEquationArray(removedEqs, traversedlowEqToSimEqSystem, (uniqueEqIndex, {}));
  // generate equations from the alias variables
  ((uniqueEqIndex, aliasEquations)) := BackendVariable.traverseBackendDAEVars(aliasVars, traverseAliasVarsToSimEqSystem, (uniqueEqIndex, {}));

  allEquations := Dangerous.listReverseInPlace(aliasEquations);
  allEquations := listAppend(removedEquations, allEquations);
  allEquations := List.append_reverse(solvedEquations, allEquations);
  allEquations := listAppend(knownVarEquations, allEquations);

  // output
  outInitialEqns := allEquations;
  ouniqueEqIndex := uniqueEqIndex;
  otempvars := tempvars;
end createInitialEquations;

public function createInitialEquations_lambda0 "author: lochel"
  input BackendDAE.BackendDAE inInitDAE;
  input Integer iuniqueEqIndex;
  input list<SimCodeVar.SimVar> itempvars;
  output list<SimCode.SimEqSystem> outInitialEqns = {};
  output Integer ouniqueEqIndex = iuniqueEqIndex;
  output list<SimCodeVar.SimVar> otempvars = itempvars;
protected
  list<SimCodeVar.SimVar> tempvars;
  Integer uniqueEqIndex;
  list<SimCode.SimEqSystem> allEquations, knownEquations, solvedEquations, aliasEquations;
  BackendDAE.EqSystems systs;
  BackendDAE.Shared shared;
  BackendDAE.Variables globalKnownVars, aliasVars;
algorithm
  BackendDAE.DAE(systs, shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars, aliasVars=aliasVars)) := inInitDAE;

  // generate equations from the known unfixed variables
  ((uniqueEqIndex, knownEquations)) := BackendVariable.traverseBackendDAEVars(globalKnownVars, traverseKnVarsToSimEqSystem, (iuniqueEqIndex, {}));
  // generate equations from the solved systems
  (uniqueEqIndex, _, _, _, solvedEquations, _, tempvars, _, _, _, _) :=
      createEquationsForSystems(systs, shared, uniqueEqIndex, {}, itempvars, 0, SimCode.NO_MAPPING(), true);
  // generate equations from the alias variables
  ((uniqueEqIndex, aliasEquations)) := BackendVariable.traverseBackendDAEVars(aliasVars, traverseAliasVarsToSimEqSystem, (uniqueEqIndex, {}));
  allEquations := List.append_reverse(solvedEquations, aliasEquations);
  allEquations := listAppend(knownEquations, allEquations);

  // output
  outInitialEqns := allEquations;
  ouniqueEqIndex := uniqueEqIndex;
  otempvars := tempvars;
end createInitialEquations_lambda0;

protected function traverseKnVarsToSimEqSystem
  "author: Frenkel TUD 2012-10"
   input BackendDAE.Var inVar;
   input tuple<Integer, list<SimCode.SimEqSystem>> inTpl;
   output BackendDAE.Var outVar;
   output tuple<Integer, list<SimCode.SimEqSystem>> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var v;
      Integer uniqueEqIndex;
      list<SimCode.SimEqSystem> eqns;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      DAE.ElementSource source;
    case (v as BackendDAE.VAR(varName = cr, bindExp=SOME(exp), source=source), (uniqueEqIndex, eqns))
      equation
        //false = BackendVariable.varFixed(v);
        false = BackendVariable.isVarOnTopLevelAndInput(v);
      then
        (v, (uniqueEqIndex+1, SimCode.SES_SIMPLE_ASSIGN(uniqueEqIndex, cr, exp, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)::eqns));
    else (inVar,inTpl);
  end matchcontinue;
end traverseKnVarsToSimEqSystem;

protected function traverseAliasVarsToSimEqSystem
  "author: Frenkel TUD 2012-10"
   input BackendDAE.Var inVar;
   input tuple<Integer, list<SimCode.SimEqSystem>> inTpl;
   output BackendDAE.Var outVar;
   output tuple<Integer, list<SimCode.SimEqSystem>> outTpl;
algorithm
  (outVar,outTpl) := match (inVar,inTpl)
    local
      BackendDAE.Var v;
      Integer uniqueEqIndex;
      list<SimCode.SimEqSystem> eqns;
      DAE.ComponentRef cr;
      DAE.Exp exp;
      DAE.ElementSource source;
    case (v as BackendDAE.VAR(varName = cr, bindExp=SOME(exp), source=source), (uniqueEqIndex, eqns))
      then
        (v, (uniqueEqIndex+1, SimCode.SES_SIMPLE_ASSIGN(uniqueEqIndex, cr, exp, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN)::eqns));
  end match;
end traverseAliasVarsToSimEqSystem;

protected function dlowEqToSimEqSystem
  input BackendDAE.Equation inEquation;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem outEquation;
  output Integer ouniqueEqIndex;
algorithm
  (outEquation, ouniqueEqIndex) := match (inEquation)
    local
      DAE.ComponentRef cr;
      DAE.Exp exp_, cond;
      DAE.Algorithm alg;
      list<DAE.Statement> algStatements;
      DAE.ElementSource source;
      BackendDAE.WhenEquation whenEquation, elseWhen;
      list<BackendDAE.WhenOperator> whenStmtLst;
      Option<BackendDAE.WhenEquation> oelseWhen;
      list<DAE.ComponentRef> conditions;
      Boolean initialCall;
      SimCode.SimEqSystem elseWhenEquation;
      Option<SimCode.SimEqSystem> oelseWhenSimEq;
      Integer uniqueEqIndex;
      BackendDAE.EquationAttributes eqAttr;

    case BackendDAE.SOLVED_EQUATION(componentRef=cr, exp=exp_, source=source, attr=eqAttr)
    then (SimCode.SES_SIMPLE_ASSIGN(iuniqueEqIndex, cr, exp_, source, eqAttr), iuniqueEqIndex+1);

    case BackendDAE.RESIDUAL_EQUATION(exp=exp_, source=source, attr=eqAttr)
    then (SimCode.SES_RESIDUAL(iuniqueEqIndex, exp_, source, eqAttr), iuniqueEqIndex+1);

    case BackendDAE.ALGORITHM(alg=alg, attr=eqAttr) equation
      DAE.ALGORITHM_STMTS(algStatements) = BackendDAEUtil.collateAlgorithm(alg, NONE());
    then (SimCode.SES_ALGORITHM(iuniqueEqIndex, algStatements, eqAttr), iuniqueEqIndex+1);

    // when eq
    case BackendDAE.WHEN_EQUATION(whenEquation=whenEquation, source=source, attr=eqAttr) equation
      BackendDAE.WHEN_STMTS(cond, whenStmtLst, oelseWhen) = whenEquation;
      if isSome(oelseWhen) then
        SOME(elseWhen) = oelseWhen;
        (elseWhenEquation,uniqueEqIndex)  = createElseWhenEquation(elseWhen, {}, iuniqueEqIndex+1, source, eqAttr);
        oelseWhenSimEq = SOME(elseWhenEquation);
      else
        uniqueEqIndex = iuniqueEqIndex+1;
        oelseWhenSimEq = NONE();
      end if;
      (conditions, initialCall) = BackendDAEUtil.getConditionList(cond);
    then
      (SimCode.SES_WHEN(iuniqueEqIndex, conditions, initialCall, whenStmtLst, oelseWhenSimEq, source, eqAttr), uniqueEqIndex);

    else equation
      if Flags.isSet(Flags.FAILTRACE) then
        Error.addInternalError("function dlowEqToSimEqSystem failed.", sourceInfo());
      end if;
    then fail();
  end match;
end dlowEqToSimEqSystem;

protected function dlowAlgToSimEqSystem
  input DAE.Algorithm inAlg;
  input Integer iuniqueEqIndex;
  output SimCode.SimEqSystem outEquation;
  output Integer ouniqueEqIndex;
protected
  list<DAE.Statement> algStatements;
algorithm
  DAE.ALGORITHM_STMTS(algStatements) := BackendDAEUtil.collateAlgorithm(inAlg, NONE());
  outEquation := SimCode.SES_ALGORITHM(iuniqueEqIndex, algStatements, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
  ouniqueEqIndex := iuniqueEqIndex+1;
end dlowAlgToSimEqSystem;

public function createVarNominalAssertFromVars
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer, list<SimCode.SimEqSystem>> acc;
  output tuple<Integer, list<SimCode.SimEqSystem>> nominalAsserts;
algorithm
  nominalAsserts := match (syst, shared, acc)
    local
      list<DAE.Algorithm> asserts1;
      list<SimCode.SimEqSystem> asserts2;
      BackendDAE.Variables vars;
      Integer uniqueEqIndex;
      list<SimCode.SimEqSystem> simeqns;
    case (BackendDAE.EQSYSTEM(orderedVars=vars), _, (uniqueEqIndex, simeqns))
      equation
        asserts1 = BackendVariable.traverseBackendDAEVars(vars, BackendVariable.getNominalAssert, {});
        (asserts2, uniqueEqIndex) = List.mapFold(asserts1, dlowAlgToSimEqSystem, uniqueEqIndex);
      then ((uniqueEqIndex, listAppend(asserts2, simeqns)));
  end match;
end createVarNominalAssertFromVars;

public function createStartValueEquations
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer, list<SimCode.SimEqSystem>, BackendDAE.Variables > acc;
  output tuple<Integer, list<SimCode.SimEqSystem>, BackendDAE.Variables> startValueEquations;
algorithm
  startValueEquations := matchcontinue (syst, shared, acc)
    local
      BackendDAE.Variables vars, av;
      list<BackendDAE.Equation>  startValueEquationsTmp2;
      list<SimCode.SimEqSystem> simeqns, simeqns1;
      Integer uniqueEqIndex;
      BackendDAE.Variables globalKnownVars;

    case (BackendDAE.EQSYSTEM(orderedVars=vars), BackendDAE.SHARED(aliasVars=av), (uniqueEqIndex, simeqns, globalKnownVars)) equation
      // vars
      ((startValueEquationsTmp2, _, _)) = BackendVariable.traverseBackendDAEVars(vars, createInitialAssignmentsFromStart, ({}, av, globalKnownVars));
      startValueEquationsTmp2 = listReverse(startValueEquationsTmp2);
      // kvars
      // ((startValueEquationsTmp, _)) = BackendVariable.traverseBackendDAEVars(globalKnownVars, createInitialAssignmentsFromStart, ({}, av));
      // startValueEquationsTmp = listReverse(startValueEquationsTmp);
      // startValueEquationsTmp2 = listAppend(startValueEquationsTmp2, startValueEquationsTmp);

      (simeqns1, uniqueEqIndex) = List.mapFold(startValueEquationsTmp2, dlowEqToSimEqSystem, uniqueEqIndex);
    then ((uniqueEqIndex, listAppend(simeqns1, simeqns), globalKnownVars));

    else equation
      Error.addInternalError("function createStartValueEquations failed", sourceInfo());
    then fail();
  end matchcontinue;
end createStartValueEquations;

public function createNominalValueEquations
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer, list<SimCode.SimEqSystem>> acc;
  output tuple<Integer, list<SimCode.SimEqSystem>> nominalValueEquations;
algorithm
  nominalValueEquations := matchcontinue (syst, shared, acc)
    local
      BackendDAE.Variables vars, av;
      list<BackendDAE.Equation> nominalValueEquationsTmp2;
      list<SimCode.SimEqSystem> simeqns, simeqns1;
      Integer uniqueEqIndex;

    case (BackendDAE.EQSYSTEM(orderedVars=vars), BackendDAE.SHARED(aliasVars=av), (uniqueEqIndex, simeqns)) equation
      // vars
      ((nominalValueEquationsTmp2, _)) = BackendVariable.traverseBackendDAEVars(vars, createInitialAssignmentsFromNominal, ({}, av));
      nominalValueEquationsTmp2 = listReverse(nominalValueEquationsTmp2);

      // kvars -> see createStartValueEquations

      (simeqns1, uniqueEqIndex) = List.mapFold(nominalValueEquationsTmp2, dlowEqToSimEqSystem, uniqueEqIndex);
    then ((uniqueEqIndex, listAppend(simeqns1, simeqns)));

    else equation
      Error.addInternalError("function createNominalValueEquations failed", sourceInfo());
    then fail();
  end matchcontinue;
end createNominalValueEquations;

public function createMinValueEquations
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer, list<SimCode.SimEqSystem>> acc;
  output tuple<Integer, list<SimCode.SimEqSystem>> minValueEquations;
algorithm
  minValueEquations := matchcontinue (syst, shared, acc)
    local
      BackendDAE.Variables vars, av;
      list<BackendDAE.Equation> minValueEquationsTmp2;
      list<SimCode.SimEqSystem> simeqns, simeqns1;
      Integer uniqueEqIndex;

    case (BackendDAE.EQSYSTEM(orderedVars=vars), BackendDAE.SHARED(aliasVars=av), (uniqueEqIndex, simeqns)) equation
      // vars
      ((minValueEquationsTmp2, _)) = BackendVariable.traverseBackendDAEVars(vars, createInitialAssignmentsFromMin, ({}, av));
      minValueEquationsTmp2 = listReverse(minValueEquationsTmp2);

      // kvars -> see createStartValueEquations

      (simeqns1, uniqueEqIndex) = List.mapFold(minValueEquationsTmp2, dlowEqToSimEqSystem, uniqueEqIndex);
    then ((uniqueEqIndex, listAppend(simeqns1, simeqns)));

    else equation
      Error.addInternalError("function createMinValueEquations failed", sourceInfo());
    then fail();
  end matchcontinue;
end createMinValueEquations;

public function createMaxValueEquations
  input BackendDAE.EqSystem syst;
  input BackendDAE.Shared shared;
  input tuple<Integer, list<SimCode.SimEqSystem>> acc;
  output tuple<Integer, list<SimCode.SimEqSystem>> maxValueEquations;
algorithm
  maxValueEquations := matchcontinue (syst, shared, acc)
    local
      BackendDAE.Variables vars, av;
      list<BackendDAE.Equation> maxValueEquationsTmp2;
      list<SimCode.SimEqSystem> simeqns, simeqns1;
      Integer uniqueEqIndex;

    case (BackendDAE.EQSYSTEM(orderedVars=vars), BackendDAE.SHARED(aliasVars=av), (uniqueEqIndex, simeqns)) equation
      // vars
      ((maxValueEquationsTmp2, _)) = BackendVariable.traverseBackendDAEVars(vars, createInitialAssignmentsFromMax, ({}, av));
      maxValueEquationsTmp2 = listReverse(maxValueEquationsTmp2);

      // kvars -> see createStartValueEquationseqAttr

      (simeqns1, uniqueEqIndex) = List.mapFold(maxValueEquationsTmp2, dlowEqToSimEqSystem, uniqueEqIndex);
    then ((uniqueEqIndex, listAppend(simeqns1, simeqns)));

    else equation
      Error.addInternalError("function createMaxValueEquations failed", sourceInfo());
    then fail();
  end matchcontinue;
end createMaxValueEquations;

protected function makeSolved_SES_SIMPLE_ASSIGN_fromStartValue
  input BackendDAE.Var inVar;
  input Integer inUniqueEqIndex;
  output SimCode.SimEqSystem outSimEqn;
  output Integer outUniqueEqIndex;
protected
  DAE.Exp e;
  DAE.ComponentRef cr;
  DAE.ElementSource source;
algorithm
  cr := BackendVariable.varCref(inVar);
  e := BackendVariable.varBindExpStartValueNoFail(inVar);
  source := BackendVariable.getVarSource(inVar);
  outSimEqn := SimCode.SES_SIMPLE_ASSIGN(inUniqueEqIndex, cr, e, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
  outUniqueEqIndex := inUniqueEqIndex+1;
end makeSolved_SES_SIMPLE_ASSIGN_fromStartValue;

public function createParameterEquations
"Traverses the globalKnownVars and creates simEqns for the variable if necessary."
  input Integer inUniqueEqIndex;
  input list<SimCode.SimEqSystem> acc;
  input BackendDAE.Variables globalKnownVars;
  output Integer outUniqueEqIndex = inUniqueEqIndex;
  output list<SimCode.SimEqSystem> outParameterEquations = {};
  output Integer nFixedParameters;
protected
  list<SimCode.SimEqSystem> simvarasserts;
  list<DAE.Algorithm> varasserts;
  list<DAE.Algorithm> varasserts2;
  BackendDAE.Var p;
  SimCode.SimEqSystem simEq;
algorithm
  (outUniqueEqIndex, outParameterEquations, varasserts, nFixedParameters, _) := BackendVariable.traverseBackendDAEVars(globalKnownVars, createSimEqsForGlobalKnownVars, (outUniqueEqIndex, outParameterEquations, {}, 0, HashSetExp.emptyHashSetSized(Util.nextPrime(globalKnownVars.numberOfVars))));

  if Flags.isSet(Flags.PARAM_DLOW_DUMP) then
    print("\nparameters in order (" + intString(listLength(outParameterEquations)) + ")\n" + UNDERLINE + "\n");
    dumpSimEqSystemLst(listReverse(outParameterEquations), "\n");
    print("\n");
  end if;

  varasserts := MetaModelica.Dangerous.listReverseInPlace(varasserts);
  (simvarasserts, outUniqueEqIndex) := List.mapFold(varasserts, dlowAlgToSimEqSystem, outUniqueEqIndex);

  outParameterEquations := List.append_reverse(simvarasserts, outParameterEquations);
  outParameterEquations := List.append_reverse(acc, outParameterEquations);
  outParameterEquations := listReverse(outParameterEquations);
end createParameterEquations;


protected function createSimEqsForGlobalKnownVars
"Decides if a simEq is generated from the globalKnownVar and creates it.
 author: ptaeuber"
  input output BackendDAE.Var globalKnownVar;
  input tuple<Integer, list<SimCode.SimEqSystem>, list<DAE.Algorithm>, Integer, HashSetExp.HashSet> inTuple;
  output tuple<Integer, list<SimCode.SimEqSystem>, list<DAE.Algorithm>, Integer, HashSetExp.HashSet> outTuple;
protected
  Integer uniqueEqIndex, nFixedParameters;
  SimCode.SimEqSystem simEq;
  list<SimCode.SimEqSystem> parameterEquations;
  list<DAE.Algorithm> varasserts, varasserts2;
  HashSetExp.HashSet tplExpHT;
algorithm
  (uniqueEqIndex, parameterEquations, varasserts, nFixedParameters, tplExpHT) := inTuple;

  // Get min/max and nominal asserts for fixed parameters
  if BackendVariable.isParam(globalKnownVar) and BackendVariable.varFixed(globalKnownVar) then
    varasserts2 := createVarAsserts(globalKnownVar);
    varasserts := List.append_reverse(varasserts2, varasserts);
    nFixedParameters := nFixedParameters + 1;
  end if;

  // Create SimCode Equation for special globalKnownVars
  if (BackendVariable.isParam(globalKnownVar) and BackendVariable.varFixed(globalKnownVar) and (BackendVariable.isFinalOrProtectedVar(globalKnownVar) or BackendVariable.varHasNonConstantBindExpOrStartValue(globalKnownVar)))
    or (BackendVariable.isVarAlg(globalKnownVar) and not BackendVariable.isInput(globalKnownVar)) and BackendVariable.varFixed(globalKnownVar)
    or (BackendVariable.isExtObj(globalKnownVar) and BackendVariable.varHasBindExp(globalKnownVar) and BackendVariable.varFixed(globalKnownVar))
   then

    _ := match(globalKnownVar)
      local
        DAE.Exp call, tplExp, rec;
        DAE.ElementSource source;
        list<DAE.Exp> expl;
        DAE.Type tp;

      // tuple_cse = call
      case BackendDAE.VAR(tplExp = SOME(tplExp as DAE.TUPLE(expl)))
        algorithm
          if BaseHashSet.has(tplExp, tplExpHT) then
            outTuple := (uniqueEqIndex, parameterEquations, varasserts, nFixedParameters, tplExpHT);
            return;
          else
            tp := Expression.typeof(tplExp);
            SOME(call) := globalKnownVar.bindExp;
            source := BackendVariable.getVarSource(globalKnownVar);
            simEq := SimCode.SES_ALGORITHM(uniqueEqIndex, {DAE.STMT_TUPLE_ASSIGN(tp, expl, call, source)}, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
            uniqueEqIndex := uniqueEqIndex+1;
            tplExpHT := BaseHashSet.add(tplExp, tplExpHT);
          end if;
       then ();

      // record_cse = call
      case BackendDAE.VAR(tplExp = SOME(rec))
        algorithm
          if BaseHashSet.has(rec, tplExpHT) then
            outTuple := (uniqueEqIndex, parameterEquations, varasserts, nFixedParameters, tplExpHT);
            return;
          else
            tp := Expression.typeof(rec);
            SOME(call) := globalKnownVar.bindExp;
            source := BackendVariable.getVarSource(globalKnownVar);
            simEq := SimCode.SES_ALGORITHM(uniqueEqIndex, {DAE.STMT_ASSIGN(tp, rec, call, source)}, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
            uniqueEqIndex := uniqueEqIndex+1;
            tplExpHT := BaseHashSet.add(rec, tplExpHT);
          end if;
       then ();

      // 'normal' globalKnownVars
      else
        algorithm
          (simEq, uniqueEqIndex) := makeSolved_SES_SIMPLE_ASSIGN_fromStartValue(globalKnownVar, uniqueEqIndex);
       then ();
      end match;

    parameterEquations := simEq::parameterEquations;
  end if;

  outTuple := (uniqueEqIndex, parameterEquations, varasserts, nFixedParameters, tplExpHT);
end createSimEqsForGlobalKnownVars;


protected function createInitialAssignmentsFromStart
  input BackendDAE.Var inVar;
  input tuple<list<BackendDAE.Equation>, BackendDAE.Variables, BackendDAE.Variables> inTpl;
  output BackendDAE.Var outVar;
  output tuple<list<BackendDAE.Equation>, BackendDAE.Variables, BackendDAE.Variables> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var var;
      BackendDAE.Equation initialEquation;
      list<BackendDAE.Equation> eqns;
      DAE.ComponentRef cref;
      DAE.Exp startExp;
      DAE.ElementSource source;
      BackendDAE.Variables av;
      BackendDAE.Variables globalKnownVars;
      list<DAE.ComponentRef> parameters;

      // also add an assignment for variables that have non-constant
      // expressions, e.g. parameter values, as start.  NOTE: such start
      // attributes can then not be changed in the text file, since the initial
      // calc. will override those entries!
    case (var as BackendDAE.VAR(varName=cref, source=source), (eqns, av, globalKnownVars))
      equation
        startExp = BackendVariable.varStartValueFail(var);
        parameters = Expression.getAllCrefs(startExp);
        true = BackendVariable.areAllCrefsPrimaryParameters(parameters, globalKnownVars) "add equations if the start value depends only on primary parameters";
        false = Expression.isConst(startExp) "don't add equations for constant start values";
        SimCodeVar.NOALIAS() = getAliasVar(var, SOME(av));
        initialEquation = BackendDAE.SOLVED_EQUATION(ComponentReference.crefPrefixStart(cref), startExp, source, BackendDAE.EQ_ATTR_DEFAULT_INITIAL);
      then (var, (initialEquation :: eqns, av, globalKnownVars));

    else (inVar,inTpl);
  end matchcontinue;
end createInitialAssignmentsFromStart;

protected function createInitialAssignmentsFromNominal "see also createInitialAssignmentsFromStart"
  input BackendDAE.Var inVar;
  input tuple<list<BackendDAE.Equation>, BackendDAE.Variables> inTpl;
  output BackendDAE.Var outVar;
  output tuple<list<BackendDAE.Equation>, BackendDAE.Variables> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var var;
      BackendDAE.Equation initialEquation;
      list<BackendDAE.Equation> eqns;
      DAE.ComponentRef name;
      DAE.Exp nominalv;
      DAE.ElementSource source;
      BackendDAE.Variables av;

    case (var as BackendDAE.VAR(varName=name, source=source), (eqns, av)) equation
      nominalv = BackendVariable.varNominalValueFail(var);
      false = Expression.isConst(nominalv);
      SimCodeVar.NOALIAS() = getAliasVar(var, SOME(av));
      initialEquation = BackendDAE.SOLVED_EQUATION(name, nominalv, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    then (var, (initialEquation :: eqns, av));

    else (inVar,inTpl);
  end matchcontinue;
end createInitialAssignmentsFromNominal;

protected function createInitialAssignmentsFromMin "see also createInitialAssignmentsFromStart"
  input BackendDAE.Var inVar;
  input tuple<list<BackendDAE.Equation>, BackendDAE.Variables> inTpl;
  output BackendDAE.Var outVar;
  output tuple<list<BackendDAE.Equation>, BackendDAE.Variables> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var var;
      BackendDAE.Equation initialEquation;
      list<BackendDAE.Equation> eqns;
      DAE.ComponentRef name;
      DAE.Exp minv;
      DAE.ElementSource source;
      BackendDAE.Variables av;

    case (var as BackendDAE.VAR(varName=name, source=source), (eqns, av)) equation
      minv = BackendVariable.varMinValueFail(var);
      false = Expression.isConst(minv);
      SimCodeVar.NOALIAS() = getAliasVar(var, SOME(av));
      initialEquation = BackendDAE.SOLVED_EQUATION(name, minv, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    then (var, (initialEquation :: eqns, av));

    else (inVar,inTpl);
  end matchcontinue;
end createInitialAssignmentsFromMin;

protected function createInitialAssignmentsFromMax "see also createInitialAssignmentsFromStart"
  input BackendDAE.Var inVar;
  input tuple<list<BackendDAE.Equation>, BackendDAE.Variables> inTpl;
  output BackendDAE.Var outVar;
  output tuple<list<BackendDAE.Equation>, BackendDAE.Variables> outTpl;
algorithm
  (outVar,outTpl) := matchcontinue (inVar,inTpl)
    local
      BackendDAE.Var var;
      BackendDAE.Equation initialEquation;
      list<BackendDAE.Equation> eqns;
      DAE.ComponentRef name;
      DAE.Exp maxv;
      DAE.ElementSource source;
      BackendDAE.Variables av;

    case (var as BackendDAE.VAR(varName=name, source=source), (eqns, av)) equation
      maxv = BackendVariable.varMaxValueFail(var);
      false = Expression.isConst(maxv);
      SimCodeVar.NOALIAS() = getAliasVar(var, SOME(av));
      initialEquation = BackendDAE.SOLVED_EQUATION(name, maxv, source, BackendDAE.EQ_ATTR_DEFAULT_UNKNOWN);
    then (var, (initialEquation :: eqns, av));

    else (inVar,inTpl);
  end matchcontinue;
end createInitialAssignmentsFromMax;

protected function createVarAsserts
  input BackendDAE.Var inVar;
  output list<DAE.Algorithm> outAlgs;
algorithm
  (_, outAlgs) := BackendVariable.getMinMaxAsserts(inVar, {});
  (_, outAlgs) := BackendVariable.getNominalAssert(inVar, outAlgs);
end createVarAsserts;

public function createModelInfo
  input Absyn.Path class_;
  input Absyn.Program program;
  input BackendDAE.BackendDAE dlow "simulation";
  input BackendDAE.BackendDAE inInitDAE "initialization";
  input list<SimCodeFunction.Function> functions;
  input list<String> labels;
  input Integer numStateSets;
  input String fileDir;
  input Integer nSubClock;
  input list<SimCodeVar.SimVar> tempVars;
  output SimCode.ModelInfo modelInfo;
protected
  String description, directory;
  SimCode.VarInfo varInfo;
  SimCodeVar.SimVars vars;
  Integer nx, ny, ndy, np, na, next, numOutVars, numInVars, ny_int, np_int, na_int, ny_bool, np_bool, dim_1, dim_2, numOptimizeConstraints, numOptimizeFinalConstraints;
  Integer na_bool, ny_string, np_string, na_string;
  list<SimCodeVar.SimVar> states1, states_lst, states_lst2, der_states_lst;
  list<SimCodeVar.SimVar> states_2, derivatives_2;
  Boolean hasLargeEqSystems;
  constant Boolean debug = false;
algorithm
  try
    // name = Absyn.pathStringNoQual(class_);
    directory := System.trim(fileDir, "\"");
    vars := createVars(dlow, inInitDAE, tempVars);
    if debug then execStat("simCode: createVars"); end if;
    BackendDAE.DAE(shared=BackendDAE.SHARED(info=BackendDAE.EXTRA_INFO(description=description))) := dlow;
    nx := getNumScalars(vars.stateVars);
    ny := getNumScalars(vars.algVars);
    ndy := getNumScalars(vars.discreteAlgVars);
    ny_int := getNumScalars(vars.intAlgVars);
    ny_bool := getNumScalars(vars.boolAlgVars);
    numOutVars := getNumScalars(vars.outputVars);
    numInVars := getNumScalars(vars.inputVars);
    na := getNumScalars(vars.aliasVars);
    na_int := getNumScalars(vars.intAliasVars);
    na_bool := getNumScalars(vars.boolAliasVars);
    np := getNumScalars(vars.paramVars);
    np_int := getNumScalars(vars.intParamVars);
    np_bool := getNumScalars(vars.boolParamVars);
    ny_string := getNumScalars(vars.stringAlgVars);
    np_string := getNumScalars(vars.stringParamVars);
    na_string := getNumScalars(vars.stringAliasVars);
    next := getNumScalars(vars.extObjVars);
    numOptimizeConstraints := getNumScalars(vars.realOptimizeConstraintsVars);
    numOptimizeFinalConstraints := getNumScalars(vars.realOptimizeFinalConstraintsVars);
    if debug then execStat("simCode: get lengths"); end if;
    varInfo := createVarInfo(dlow, nx, ny, ndy, np, na, next, numOutVars, numInVars,
                             ny_int, np_int, na_int, ny_bool, np_bool, na_bool, ny_string, np_string, na_string,
                             numStateSets, numOptimizeConstraints, numOptimizeFinalConstraints);
    if debug then execStat("simCode: createVarInfo"); end if;
    hasLargeEqSystems := hasLargeEquationSystems(dlow, inInitDAE);
    if debug then execStat("simCode: hasLargeEquationSystems"); end if;
    modelInfo := SimCode.MODELINFO(class_, dlow.shared.info.description, directory, varInfo, vars, functions,
                                   labels,
                                   if Flags.getConfigBool(Flags.BUILDING_FMU) then getResources(program.classes, dlow, inInitDAE) else {},
                                   List.sort(program.classes, Absyn.classNameGreater),
                                   arrayLength(dlow.shared.partitionsInfo.basePartitions),
                                   arrayLength(dlow.shared.partitionsInfo.subPartitions),
                                   hasLargeEqSystems, {}, {});
  else
    Error.addInternalError("createModelInfo failed", sourceInfo());
    fail();
  end try;
end createModelInfo;

protected function createVarInfo
  input BackendDAE.BackendDAE dlow;
  input Integer nx;
  input Integer ny;
  input Integer ndy;
  input Integer np;
  input Integer na;
  input Integer next;
  input Integer numOutVars;
  input Integer numInVars;
  input Integer ny_int;
  input Integer np_int;
  input Integer na_int;
  input Integer ny_bool;
  input Integer np_bool;
  input Integer na_bool;
  input Integer ny_string;
  input Integer np_string;
  input Integer na_string;
  input Integer numStateSets;
  input Integer numOptimizeConstraints;
  input Integer numOptimizeFinalConstraints;
  output SimCode.VarInfo varInfo;
protected
  Integer numZeroCrossings, numTimeEvents, numRelations, numMathEventFunctions;
algorithm
  (numZeroCrossings, numTimeEvents, numRelations, numMathEventFunctions) := BackendDAEUtil.numberOfZeroCrossings(dlow);
  numZeroCrossings := numZeroCrossings;
  numTimeEvents := numTimeEvents;
  numRelations := numRelations;
  varInfo := SimCode.VARINFO(numZeroCrossings, numTimeEvents, numRelations, numMathEventFunctions, nx, ny, ndy, ny_int, ny_bool, na, na_int, na_bool, np, np_int, np_bool, numOutVars, numInVars,
          next, ny_string, np_string, na_string, 0, 0, 0, 0, numStateSets,0,numOptimizeConstraints, numOptimizeFinalConstraints, 0,0);
end createVarInfo;

protected function evaluateStartValues"evaluates functions in the start values in the variableAttributes"
  input BackendDAE.Var inVar;
  input BackendDAE.Shared inShared;
  output BackendDAE.Var outVar;
  output BackendDAE.Shared outShared;
algorithm
  (outVar,outShared) := matchcontinue(inVar,inShared)
    local
      Option<DAE.Exp> o1;
      Option<DAE.VariableAttributes> o2;
      DAE.Exp startValue, startValue_;
      list<DAE.Exp> exps;
      DAE.VariableAttributes attr, attr_;
      Values.Value value;
      FCore.Cache cache;
      FCore.Graph graph;

  case(BackendDAE.VAR(bindExp = o1, values = o2), BackendDAE.SHARED(cache=cache, graph=graph))
    equation
      if isSome(o1) then
        startValue = Util.getOption(o1);

        // If call with constant arguments then evaluate
        startValue_ = match(startValue)
          local DAE.Exp startValue1;
          case(DAE.CALL(expLst=exps)) guard Expression.isConstWorkList(exps)
            equation
             (_,value) = Ceval.ceval(cache, graph, startValue, false, Absyn.NO_MSG(),0);
             startValue1 = ValuesUtil.valueExp(value);
           then startValue1;
          case(DAE.ASUB(DAE.CALL(expLst=exps),_)) guard Expression.isConstWorkList(exps)
            equation
             (_,value) = Ceval.ceval(cache, graph, startValue, false, Absyn.NO_MSG(),0);
             startValue1 = ValuesUtil.valueExp(value);
           then startValue1;
          else startValue;
        end match;

        if not referenceEq(startValue, startValue_) then
          inVar.bindExp = SOME(startValue_);
        end if;
      end if;

      if isSome(o2) then
        attr = Util.getOption(o2);
        attr_ = evaluateVariableAttributes(attr, inShared);
        if not referenceEq(attr, attr_) then
          inVar.values = SOME(attr_);
        end if;
      end if;
    then (inVar,inShared);

    else
      then (inVar,inShared);
  end matchcontinue;
end evaluateStartValues;

protected function evaluateVariableAttributes"evaluates functions in the start values, if necessary"
  input DAE.VariableAttributes attrIn;
  input BackendDAE.Shared shared;
  output DAE.VariableAttributes attrOut;
algorithm
  attrOut := matchcontinue(attrIn, shared)
    local
      DAE.Exp exp, exp_;
      list<DAE.Exp> exps;
      Values.Value value;
      FCore.Cache cache;
      FCore.Graph graph;

  case(DAE.VAR_ATTR_REAL(start=SOME(exp)), BackendDAE.SHARED(cache=cache, graph=graph))
    equation
      // If call with constant arguments then evaluate
      exp_ = match(exp)
        local DAE.Exp exp1;
        case(DAE.CALL(expLst=exps)) guard Expression.isConstWorkList(exps)
          equation
           (_,value) = Ceval.ceval(cache, graph, exp, false, Absyn.NO_MSG(),0);
           exp1 = ValuesUtil.valueExp(value);
         then exp1;
        case(DAE.ASUB(DAE.CALL(expLst=exps),_)) guard Expression.isConstWorkList(exps)
          equation
           (_,value) = Ceval.ceval(cache, graph, exp, false, Absyn.NO_MSG(),0);
           exp1 = ValuesUtil.valueExp(value);
         then exp1;
        else exp;
      end match;

      if not referenceEq(exp, exp_) then
        attrIn.start = SOME(exp);
      end if;
    then attrIn;
  else
  then attrIn;
  end matchcontinue;
end evaluateVariableAttributes;

protected function preCalculateStartValues"calculates start values of variables which have none. The calculation is based on the start values of the vars in the assigned equation.
This is a possible solution to equip vars with proper start values (would be computed anyway).
In initial systems are nonlinear systems that use function calls that fail if the input has no proper start value.
If the var is a torn var, there is no way to compute the proper start value before evaluating these function calls. The tearing method could consider this.
author:Waurich TUD 2015-01"
  input BackendDAE.EqSystem systIn;
  input BackendDAE.Variables globalKnownVars;
  input BackendDAE.Shared shared;
  output BackendDAE.EqSystem systOut;
protected
  list<Integer> varMap;
  array<Integer> varMapArr;
  BackendDAE.Variables vars, allVars, vars1;
  BackendDAE.EquationArray eqs;
  BackendDAE.Matching matching;
  BackendDAE.IncidenceMatrix mStart;
  BackendDAE.IncidenceMatrixT mTStart;
  BackendDAE.StrongComponents comps;
  BackendDAE.EqSystem syst;
  list<BackendDAE.Equation> eqLst;
  list<BackendDAE.Var> varLst, noStartVarLst;

  list<tuple<Integer,BackendDAE.VarKind>> stateInfo;
  list<Integer> stateIdcs;
  list<BackendDAE.VarKind> stateKinds;
algorithm
  vars := systIn.orderedVars;
  // set the varkInd for states to variable, reverse this later with the help of the stateinfo
  stateInfo := List.fold1(List.intRange(BackendVariable.varsSize(vars)),getStateInfo,vars,{});// which var is a state and save the kind
  (vars,_) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars,setVarKindForStates,BackendDAE.VARIABLE());

  // replace every var or param by its startvalue or binding, make a system of variables withput startvalues

  varLst := BackendVariable.varList(vars);
  varMap := List.intRange(BackendVariable.varsSize(vars));
  (noStartVarLst,varMap) := List.filterOnTrueSync(varLst, BackendVariable.varHasNoStartValue, varMap);

  // insert start values for crefs and build incidence matrix
    //BackendDump.dumpVariables(vars,"VAR BEFORE");
    //BackendDump.dumpEquationList(eqLst,"EQS BEFORE");
  eqs := BackendEquation.copyEquationArray(systIn.orderedEqs);
  _ := BackendDAEUtil.traverseBackendDAEExpsEqns(eqs,replaceCrefWithStartValue,globalKnownVars);
  _ := BackendDAEUtil.traverseBackendDAEExpsEqns(eqs,replaceCrefWithStartValue,vars);
    //BackendDump.dumpEquationList(eqLst,"EQS AFTER");
  vars1 := BackendVariable.listVar1(noStartVarLst);
  syst := BackendDAEUtil.createEqSystem(vars1, eqs);
  (syst, mStart, mTStart) := BackendDAEUtil.getIncidenceMatrix(syst,BackendDAE.NORMAL(),NONE());
    //BackendDump.dumpIncidenceMatrix(mStart);
    //BackendDump.dumpIncidenceMatrixT(mTStart);
  // solve equations for new start values and assign start values to variables
  varMapArr := listArray(varMap);
  vars := preCalculateStartValues1(List.intRange(arrayLength(mStart)), mStart, mTStart, varMapArr, eqs, vars);

  // reset the varKinds for the states
  stateIdcs := List.map(stateInfo, Util.tuple21);
  stateKinds := List.map(stateInfo, Util.tuple22);
  vars := List.threadFold(stateIdcs, stateKinds,BackendVariable.setVarKindForVar, vars);

  //evaluate function calls in variable attributes (start-value)
  (vars,_) := BackendVariable.traverseBackendDAEVarsWithUpdate(vars,evaluateStartValues,shared);
    //BackendDump.dumpVariables(vars,"VAR AFTER");
  systOut := BackendDAEUtil.setEqSystVars(systIn, vars);
end preCalculateStartValues;

protected function preCalculateStartValues1"try to solve the start equation for a var and set the resulting start value for it."
  input list<Integer> eqIndexes; // to be analyzed
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrix mT;
  input array<Integer> varMap;
  input BackendDAE.EquationArray eqs;
  input BackendDAE.Variables varsIn;
  output BackendDAE.Variables varArr = varsIn;
protected
  Integer eqIdx, varIdx, varIdx0;
  list<Integer> rest, newEqIdcs, workList={};
  list<list<Integer>> mEntries;
  BackendDAE.Equation eq;
  BackendDAE.EquationArray eqArr;
  BackendDAE.Var var;
  list<BackendDAE.Equation> eqLst;
  DAE.ComponentRef cref;
  DAE.Exp lhs,rhs;
algorithm
  // Implement a FIFO queue using two lists:
  // 'rest' contains the elements in the correct order while 'workList'
  // contains the rest of the elements in reverse order (in order to
  // easier add new elements to the queue)
  rest := eqIndexes;
  while not listEmpty(rest) or not listEmpty(workList) loop
    if listEmpty(rest) then
      rest := Dangerous.listReverseInPlace(workList);
      workList := {};
    end if;
    eqIdx::rest := rest;
    try
      {varIdx0} := arrayGet(m,eqIdx);
      varIdx := arrayGet(varMap,intAbs(varIdx0));
      var := BackendVariable.getVarAt(varArr,varIdx);
      cref := BackendVariable.varCref(var);
      eq := BackendEquation.get(eqs,eqIdx);
      //print("solve eq("+intString(eqIdx)+"): ");
      //BackendDump.printEquationList({eq});
      //print(" for var("+intString(varIdx0)+"): "+ComponentReference.printComponentRefStr(cref)+"\n");
      rhs := BackendEquation.getEquationRHS(eq);
      lhs := BackendEquation.getEquationLHS(eq);
      (rhs, {}) := ExpressionSolve.solve(lhs,rhs,Expression.crefExp(cref));
      true := Expression.isScalarConst(rhs); // if this equation solves a variable, set this as a start value
      var := BackendVariable.setVarStartValue(var,rhs);
      // Side-effect here. What if the rest fails?
      varArr := BackendVariable.setVarAt(varArr,varIdx,var);

      //check these equations again
      newEqIdcs := arrayGet(mT,varIdx0);
      newEqIdcs := List.deleteMember(newEqIdcs,eqIdx);
      workList := List.append_reverse(newEqIdcs,workList);
      //print("check these equations again: "+stringDelimitList(List.map(newEqIdcs,intString),", ")+"\n");
      // replace the var with the new start value in these equations
      eqLst := List.map1r(newEqIdcs,BackendEquation.get,eqs);
      (eqLst,_) := BackendEquation.traverseExpsOfEquationList(eqLst,replaceCrefWithStartValue,varArr);
      eqArr := List.threadFold(newEqIdcs,eqLst,BackendEquation.setAtIndexFirst,eqs);
      // update the incidenceMatrix m and remove the idcs for the calculated var
      mEntries := List.map1(newEqIdcs,Array.getIndexFirst,m);
      mEntries := List.map1(mEntries,List.deleteMember,varIdx0);
      List.threadMap1_0(newEqIdcs,mEntries,Array.updateIndexFirst,m);
    else
    end try;
  end while;

end preCalculateStartValues1;

protected function artificialVarKind "an artificial var is introduced during compilation and has a start-value that does not come from the model"
  input BackendDAE.VarKind inVarKind;
  output Boolean isVar;
algorithm
  isVar := match (inVarKind)
    case BackendDAE.VARIABLE() then false;
    case BackendDAE.PARAM() then false;
    case BackendDAE.CONST() then false;
    case BackendDAE.DISCRETE() then false;
    case BackendDAE.STATE() then false;
    case BackendDAE.ALG_STATE() then false;
    case BackendDAE.DUMMY_STATE() then false;
    else true;
  end match;
end artificialVarKind;

protected function replaceCrefWithStartValue "replaces a cref with its constant start value. Only if the BackendDAE.Varkind is not artificial in order to avoid guess-start values
Waurich 2015-01"
  input DAE.Exp expIn;
  input BackendDAE.Variables varsIn;
  output DAE.Exp expOut;
  output BackendDAE.Variables varsOut;
algorithm
  (expOut,varsOut) := matchcontinue(expIn,varsIn)
   local
     Integer idx;
     Real r;
     Option<tuple<DAE.Exp,Integer,Integer>> optionExpisASUB;
     BackendDAE.Var var;
     DAE.ComponentRef cref;
     DAE.Exp exp, exp1, exp2, exp3, startTime, exp1_, exp2_, exp3_;
     DAE.Operator op;
     list<DAE.Exp> expLst;

   case(DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")),_)
     equation
     then (DAE.RCONST(0.0),varsIn);

   case(DAE.CREF(componentRef=cref),_)
     equation
       (var,_) = BackendVariable.getVarSingle(cref,varsIn);
       true =  not artificialVarKind(BackendVariable.varKind(var));// if its not of kind variable(), it is something artificial (DUMMY_DER,...) and the start value is not model based in that case
      // print("VAR: "+BackendDump.varString(var)+" -->");
       if BackendVariable.varHasBindExp(var) /*and Expression.isConst(BackendVariable.varBindExp(var))*/ then
         exp = BackendVariable.varBindExp(var);
         if 0 <> Expression.compare(exp, expIn) then
           // Or should this be an error? Replacing the start-value by itself...
           exp = replaceCrefWithStartValue(exp,varsIn);
         end if;
       elseif BackendVariable.varHasStartValue(var) then
         exp = BackendVariable.varStartValue(var);
       else
         exp = expIn;
       end if;
       //print(" has START:"+ ExpressionDump.printExpStr(exp)+"\n");
       exp = if Expression.isConst(exp) then exp else expIn;
     then (exp,varsIn);

   case(DAE.CALL(path=Absyn.IDENT("sample"), expLst=expLst),_)
       equation
       startTime = listGet(expLst,2);
       startTime = replaceCrefWithStartValue(startTime,varsIn);
       if Expression.isZero(startTime) then
         exp = DAE.BCONST(true);
       else
         exp = expIn;
       end if;
     then (exp,varsIn);

   case(DAE.BINARY(exp1=exp1,operator=op,exp2=exp2),_)
     equation
       exp1_ = replaceCrefWithStartValue(exp1,varsIn);
       exp2_ = replaceCrefWithStartValue(exp2,varsIn);
       if referenceEq(exp1, exp1_) and referenceEq(exp2,exp2_) then
         exp = expIn;
       else
         exp = DAE.BINARY(exp1_,op,exp2_);
       end if;
     then (exp,varsIn);

     case(DAE.LBINARY(exp1=exp1,operator=op,exp2=exp2),_)
     equation
       exp1_ = replaceCrefWithStartValue(exp1,varsIn);
       exp2_ = replaceCrefWithStartValue(exp2,varsIn);
       if referenceEq(exp1, exp1_) and referenceEq(exp2,exp2_) then
         exp = expIn;
       else
         exp = DAE.LBINARY(exp1_,op,exp2_);
       end if;
     then (exp,varsIn);

     // time > -1.0 or similar
    case(DAE.RELATION(exp1=DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")),operator=DAE.GREATER(),exp2=DAE.RCONST(real=r)),_)
     equation
       true = realLe(r,0.0);
     then (expIn,varsIn);

     // time >= -1.0 or similar
    case(DAE.RELATION(exp1=DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time")),operator=DAE.GREATEREQ(),exp2=DAE.RCONST(real=r)),_)
     equation
       true = realLe(r,0.0);
     then (expIn,varsIn);

    // -1.0 < time or similar
    case(DAE.RELATION(exp1=DAE.RCONST(real=r),operator=DAE.LESS(),exp2=DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))),_)
     equation
       true = realLe(r,0.0);
     then (expIn,varsIn);

     // -1.0 <= time or similar
    case(DAE.RELATION(exp1=DAE.RCONST(real=r),operator=DAE.LESSEQ(),exp2=DAE.CREF(componentRef=DAE.CREF_IDENT(ident="time"))),_)
     equation
       true = realLe(r,0.0);
     then (expIn,varsIn);

    case(DAE.RELATION(exp1=exp1,operator=op,exp2=exp2,index=idx,optionExpisASUB=optionExpisASUB),_)
     equation
       exp1_ = replaceCrefWithStartValue(exp1,varsIn);
       exp2_ = replaceCrefWithStartValue(exp2,varsIn);
       if referenceEq(exp1, exp1_) and referenceEq(exp2,exp2_) then
         exp = expIn;
       else
         exp = DAE.RELATION(exp1_,op,exp2_,idx,optionExpisASUB);
       end if;
     then (exp,varsIn);

    case(DAE.IFEXP(expCond=exp1,expThen=exp2,expElse=exp3),_)
     equation
       //print("IFEXP: "+ExpressionDump.dumpExpStr(expIn,0)+"\n");
       exp1_ = replaceCrefWithStartValue(exp1,varsIn);
       exp2_ = replaceCrefWithStartValue(exp2,varsIn);
       exp3_ = replaceCrefWithStartValue(exp3,varsIn);
       if referenceEq(exp1, exp1_) and referenceEq(exp2,exp2_) and referenceEq(exp3,exp3_) then
         exp = expIn;
       else
         exp = DAE.IFEXP(exp1_,exp2_,exp3_);
       end if;
     then (exp,varsIn);

   else
     equation
       //print("Without START:"+ ExpressionDump.printExpStr(expIn)+"\n");
     then (expIn,varsIn);

  end matchcontinue;
end replaceCrefWithStartValue;

protected function setVarKindForStates
    input BackendDAE.Var inVar;
    input BackendDAE.VarKind kindIn;
    output BackendDAE.Var outVar;
    output BackendDAE.VarKind kindOut;
algorithm
  (outVar,kindOut) := match(inVar,kindIn)
    local
      BackendDAE.Var var;
  case(BackendDAE.VAR(varKind=BackendDAE.STATE(index=1)),_)
    equation
      var = BackendVariable.setVarKind(inVar,kindIn);
    then (var,kindIn);
  else
    then
      (inVar,kindIn);
  end match;
end setVarKindForStates;

protected function getStateInfo
  input Integer idx;
  input BackendDAE.Variables vars;
  input list<tuple<Integer,BackendDAE.VarKind>> stateInfoIn;
  output list<tuple<Integer,BackendDAE.VarKind>> stateInfoOut;
algorithm
  stateInfoOut := matchcontinue(idx,vars,stateInfoIn)
    local
      BackendDAE.Var var;
      BackendDAE.VarKind kind;
    case(_,_,_)
      equation
        var = BackendVariable.getVarAt(vars,idx);
        true = BackendVariable.isStateVar(var);
        kind = BackendVariable.varKind(var);
      then ((idx,kind)::stateInfoIn);
    else
      then (stateInfoIn);
  end matchcontinue;
end getStateInfo;

protected type SimVarsIndex = enumeration(
  // In special order for fmi: real => intger => boolean => string => external
  state,
  derivative,
  alg,
  discreteAlg,
  realOptimizeConstraints,
  realOptimizeFinalConstraints,

  param,
  alias,

  intAlg,
  intParam,
  intAlias,

  boolAlg,
  boolParam,
  boolAlias,

  stringAlg,
  stringParam,
  stringAlias,

  extObj,

  inputs,
  outputs,

  const,
  intConst,
  boolConst,
  stringConst,

  sensitivity,
  setcvars,
  jacobian,
  seed
);

protected function createVars
  input BackendDAE.BackendDAE inSimDAE "simulation";
  input BackendDAE.BackendDAE inInitDAE "initialization";
  input list<SimCodeVar.SimVar> tempvars;
  output SimCodeVar.SimVars outVars;
protected
  BackendDAE.Variables globalKnownVars1, globalKnownVars2;
  BackendDAE.Variables localKnownVars1, localKnownVars2;
  BackendDAE.Variables extvars1, extvars2;
  BackendDAE.Variables aliasVars1, aliasVars2;
  BackendDAE.EqSystems systs1, systs2;
  BackendDAE.Shared shared;
  Mutable<HashSet.HashSet> hs;
  array<list<SimCodeVar.SimVar>> simVars = arrayCreate(size(SimVarsIndex,1), {});
  Integer primeSize;

  constant Boolean debug = false;
algorithm
  BackendDAE.DAE(eqs=systs1, shared=shared as BackendDAE.SHARED(globalKnownVars=globalKnownVars1, localKnownVars=localKnownVars1, externalObjects=extvars1, aliasVars=aliasVars1)) := inSimDAE;
  BackendDAE.DAE(eqs=systs2, shared=BackendDAE.SHARED(globalKnownVars=globalKnownVars2, localKnownVars=localKnownVars2, externalObjects=extvars2, aliasVars=aliasVars2)) := inInitDAE;

  primeSize := Util.nextPrime(
    integer(1.4*(
    BackendVariable.varsSize(globalKnownVars1)+BackendVariable.varsSize(globalKnownVars2)+
    BackendVariable.varsSize(localKnownVars1)+BackendVariable.varsSize(localKnownVars2)+
    BackendVariable.varsSize(aliasVars1)+BackendVariable.varsSize(aliasVars2)+
    BackendVariable.varsSize(extvars1)+BackendVariable.varsSize(extvars2)+
    BackendDAEUtil.daeSize(inSimDAE)+BackendDAEUtil.daeSize(inInitDAE)
  )));
  hs := Mutable.create(HashSet.emptyHashSetSized(primeSize));

  if not Flags.isSet(Flags.NO_START_CALC) then
    (systs1) := List.map2(systs1, preCalculateStartValues, globalKnownVars1, shared);
    (globalKnownVars1, _) := BackendVariable.traverseBackendDAEVarsWithUpdate(globalKnownVars1, evaluateStartValues, shared);
    //systs2 := List.map1(systs2, preCalculateStartValues, globalKnownVars2);
    if debug then execStat("createVars: evaluateStartValues"); end if;
  end if;

  // ### simulation ###
  // Extract from variable list
  simVars := List.fold1(list(BackendVariable.daeVars(syst) for syst in systs1), BackendVariable.traverseBackendDAEVars, function extractVarsFromList(aliasVars=aliasVars1, vars=globalKnownVars1, hs=hs), simVars);
  if debug then execStat("createVars: variable list"); end if;

  // Extract from known variable list
  simVars := BackendVariable.traverseBackendDAEVars(globalKnownVars1, function extractVarsFromList(aliasVars=aliasVars1, vars=globalKnownVars1, hs=hs), simVars);
  if debug then execStat("createVars: known variable list"); end if;

  // Extract from localKnownVars variable list
  simVars := BackendVariable.traverseBackendDAEVars(localKnownVars1, function extractVarsFromList(aliasVars=aliasVars1, vars=globalKnownVars1, hs=hs), simVars);
  if debug then execStat("createVars: local known variables list"); end if;

  // Extract from removed variable list
  simVars := BackendVariable.traverseBackendDAEVars(aliasVars1, function extractVarsFromList(aliasVars=aliasVars1, vars=globalKnownVars1, hs=hs), simVars);
  if debug then execStat("createVars: removed variables list"); end if;

  // Extract from external object list
  simVars := BackendVariable.traverseBackendDAEVars(extvars1, function extractVarsFromList(aliasVars=aliasVars1, vars=globalKnownVars1, hs=hs), simVars);
  if debug then execStat("createVars: external object list"); end if;


  // ### initialization ###
  // Extract from variable list
  simVars := List.fold1(list(BackendVariable.daeVars(syst) for syst in systs2), BackendVariable.traverseBackendDAEVars, function extractVarsFromList(aliasVars=aliasVars2, vars=globalKnownVars2, hs=hs), simVars);
  if debug then execStat("createVars: variable list (init)"); end if;

  // Extract from known variable list
  simVars := BackendVariable.traverseBackendDAEVars(globalKnownVars2, function extractVarsFromList(aliasVars=aliasVars2, vars=globalKnownVars2, hs=hs), simVars);
  if debug then execStat("createVars: known variable list (init)"); end if;

  // Extract from localKnownVars variable list
  simVars := BackendVariable.traverseBackendDAEVars(localKnownVars2, function extractVarsFromList(aliasVars=aliasVars2, vars=globalKnownVars2, hs=hs), simVars);
  if debug then execStat("createVars: local known variables list (init)"); end if;

  // Extract from removed variable list
  simVars := BackendVariable.traverseBackendDAEVars(aliasVars2, function extractVarsFromList(aliasVars=aliasVars2, vars=globalKnownVars2, hs=hs), simVars);
  if debug then execStat("createVars: removed variables list (init)"); end if;

  // Extract from external object list
  simVars := BackendVariable.traverseBackendDAEVars(extvars2, function extractVarsFromList(aliasVars=aliasVars2, vars=globalKnownVars2, hs=hs), simVars);
  if debug then execStat("createVars: external object list (init)"); end if;

  addTempVars(simVars, tempvars);
  if debug then execStat("createVars: addTempVars"); end if;
  //BaseHashSet.printHashSet(hs);

  // sort variables on index
  sortSimvars(simVars);
  if debug then execStat("createVars: sortSimVars"); end if;

   if (stringEqual(Config.simCodeTarget(), "Cpp") or (Config.simCodeTarget()=="omsicpp")) then
    extendIncompleteArray(simVars);
    if debug then execStat("createVars: Cpp, extendIncompleteArray"); end if;
  end if;

  // Index of algebraic and parameters need to fix due to separation of integer variables
  fixIndex(simVars);
  setVariableIndex(simVars);
  if debug then execStat("createVars: fix and set index"); end if;

  outVars := SimCodeVar.SIMVARS(
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.state)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.derivative)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.alg)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.discreteAlg)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.intAlg)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.boolAlg)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.inputs)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.outputs)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.alias)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.intAlias)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.boolAlias)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.param)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.intParam)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.boolParam)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.stringAlg)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.stringParam)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.stringAlias)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.extObj)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.const)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.intConst)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.boolConst)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.stringConst)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.jacobian)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.seed)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.realOptimizeConstraints)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.realOptimizeFinalConstraints)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.sensitivity)),
    Dangerous.arrayGetNoBoundsChecking(simVars, Integer(SimVarsIndex.setcvars))
  );
  GC.free(simVars);
end createVars;

protected function extractVarsFromList
  input output BackendDAE.Var var;
  input output array<list<SimCodeVar.SimVar>> simVars;
  input BackendDAE.Variables aliasVars, vars;
  input Mutable<HashSet.HashSet> hs;
algorithm
  if if ComponentReference.isPreCref(var.varName) or ComponentReference.isStartCref(var.varName) then false else not BaseHashSet.has(var.varName, Mutable.access(hs)) then
    /* ignore variable, since they are treated by kind in the codegen */
    if not BackendVariable.isAlgebraicOldState(var) then
      extractVarFromVar(var, aliasVars, vars, simVars, hs);
    end if;
  //  print("Added  " + ComponentReference.printComponentRefStr(inVar.varName) + "\n");
  //else
  //  print("Skiped " + ComponentReference.printComponentRefStr(inVar.varName) + "\n");
  end if;
end extractVarsFromList;

// one dlow var can result in multiple simvars: input and output are a subset
// of algvars for example
protected function extractVarFromVar
  input BackendDAE.Var dlowVar;
  input BackendDAE.Variables inAliasVars;
  input BackendDAE.Variables inVars;
  input array<list<SimCodeVar.SimVar>> simVars;
  input Mutable<HashSet.HashSet> hs "all processed crefs";
protected
  SimCodeVar.SimVar simVar;
  SimCodeVar.SimVar derivSimvar;
  Boolean isalias, isAlg, isParam, isConst;
  DAE.ComponentRef name;
  Integer len;
algorithm
  // extract the sim var
  simVar := dlowvarToSimvar(dlowVar, SOME(inAliasVars), inVars);
  isalias := isAliasVar(simVar);


  // update HashSet
  Mutable.update(hs, BaseHashSet.add(simVar.name, Mutable.access(hs)));
  if (not isalias) and (BackendVariable.isStateVar(dlowVar) or BackendVariable.isAlgState(dlowVar)) then
    derivSimvar := derVarFromStateVar(simVar);
    Mutable.update(hs, BaseHashSet.add(derivSimvar.name, Mutable.access(hs)));
  else
    derivSimvar := simVar; // Just in case
  end if;

  // If it is an input variable, we give it an index
  if (not isalias) and BackendVariable.isVarOnTopLevelAndInputNoDerInput(dlowVar) then
    simVar := match simVar
      case SimCodeVar.SIMVAR()
        algorithm
          simVar.inputIndex := SOME(arrayCreate(1,-2));
        then simVar;
      else
        algorithm
          Error.addInternalError("Failed to SimCodeUtil.extractVarFromVar of input variable", sourceInfo());
        then fail();
    end match;
  end if;

  // figure out in which lists to put it
  isAlg := BackendVariable.isVarAlg(dlowVar);
  isParam := BackendVariable.isParam(dlowVar);
  isConst := BackendVariable.isConst(dlowVar);

  // for inputs and outputs we have additional lists
  if BackendVariable.isVarOnTopLevelAndInputNoDerInput(dlowVar) then
    addSimVar(simVar, SimVarsIndex.inputs, simVars);
  end if;
  if BackendVariable.isVarOnTopLevelAndOutput(dlowVar) then
    addSimVar(simVar, SimVarsIndex.outputs, simVars);
  end if;
  // check if alias
  if isalias then
    if Types.isReal(dlowVar.varType) then
      addSimVar(simVar, SimVarsIndex.alias, simVars);
    elseif Types.isInteger(dlowVar.varType) or  Types.isEnumeration(dlowVar.varType) then
      addSimVar(simVar, SimVarsIndex.intAlias, simVars);
    elseif Types.isBoolean(dlowVar.varType) then
      addSimVar(simVar, SimVarsIndex.boolAlias, simVars);
    elseif Types.isString(dlowVar.varType) then
      addSimVar(simVar, SimVarsIndex.stringAlias, simVars);
    end if;
  // check for states
  elseif BackendVariable.isStateVar(dlowVar) or BackendVariable.isAlgState(dlowVar) then
    addSimVar(simVar, SimVarsIndex.state, simVars);
    addSimVar(derivSimvar, SimVarsIndex.derivative, simVars);
  // check for algebraic varibales
  elseif isAlg or isParam or isConst then
    // Real vars
    if Types.isReal(dlowVar.varType) then
      if isAlg then
        if BackendVariable.isVarDiscrete(dlowVar) then
          addSimVar(simVar, SimVarsIndex.discreteAlg, simVars);
        else
          addSimVar(simVar, SimVarsIndex.alg, simVars);
        end if;
      elseif isParam then
        addSimVar(simVar, SimVarsIndex.param, simVars);
      elseif isConst then
        addSimVar(simVar, SimVarsIndex.const, simVars);
      end if;
    // Integer vars
    elseif Types.isInteger(dlowVar.varType) or  Types.isEnumeration(dlowVar.varType) then
      if isAlg then
        addSimVar(simVar, SimVarsIndex.intAlg, simVars);
      elseif isParam then
        addSimVar(simVar, SimVarsIndex.intParam, simVars);
      elseif isConst then
        addSimVar(simVar, SimVarsIndex.intConst, simVars);
      end if;
    // Boolean vars
    elseif Types.isBoolean(dlowVar.varType) then
      if isAlg then
        addSimVar(simVar, SimVarsIndex.boolAlg, simVars);
      elseif isParam then
        addSimVar(simVar, SimVarsIndex.boolParam, simVars);
      elseif isConst then
        addSimVar(simVar, SimVarsIndex.boolConst, simVars);
      end if;
    // String vars
    elseif Types.isString(dlowVar.varType) then
      if isAlg then
        addSimVar(simVar, SimVarsIndex.stringAlg, simVars);
      elseif isParam then
        addSimVar(simVar, SimVarsIndex.stringParam, simVars);
      elseif isConst then
        addSimVar(simVar, SimVarsIndex.stringConst, simVars);
      end if;
    else
      Error.addInternalError("Failed to find SimVar list for Var: " + BackendDump.varString(dlowVar), sourceInfo());
    end if;
  // external objects
  elseif BackendVariable.isExtObj(dlowVar) then
    addSimVar(simVar, SimVarsIndex.extObj, simVars);
  // optimize constraints
  elseif BackendVariable.isRealOptimizeConstraintsVars(dlowVar) then
    addSimVar(simVar, SimVarsIndex.realOptimizeConstraints, simVars);
  // optimize final constraints vars
  elseif BackendVariable.isRealOptimizeFinalConstraintsVars(dlowVar) then
    addSimVar(simVar, SimVarsIndex.realOptimizeFinalConstraints, simVars);
  elseif BackendVariable.isOptInputVar(dlowVar) then
    addSimVar(simVar, SimVarsIndex.alg, simVars);
  elseif BackendVariable.isDAEmodeVar(dlowVar) then
    // skip, they are only used localy in daeMode
  else
    Error.addInternalError("Failed to find the correct SimVar list for Var: " + BackendDump.varString(dlowVar), sourceInfo());
  end if;
end extractVarFromVar;

protected function addSimVar
  input SimCodeVar.SimVar simVar;
  input SimVarsIndex index;
  input array<list<SimCodeVar.SimVar>> simVars;
algorithm
  Dangerous.arrayUpdateNoBoundsChecking(simVars, Integer(index), simVar::Dangerous.arrayGetNoBoundsChecking(simVars, Integer(index)));
end addSimVar;

protected function derVarFromStateVar
  input SimCodeVar.SimVar state;
  output SimCodeVar.SimVar deriv = state;
protected
  Unit.Unit unit;
algorithm
  deriv.arrayCref := Util.applyOption(deriv.arrayCref, ComponentReference.crefPrefixDer);
  deriv.name := ComponentReference.crefPrefixDer(deriv.name);
  deriv.varKind := BackendDAE.STATE_DER();
  if deriv.comment <> "" then
    deriv.comment := "der(" + deriv.comment + ")";
  end if;
  try
    unit := Unit.parseUnitString(deriv.unit);
    unit := Unit.unitDiv(unit, Unit.UNIT(1e0, 0, 0, 0, 1, 0, 0, 0));
    deriv.unit := Unit.unitString(unit);
  else
    deriv.unit := "";
  end try;
  deriv.displayUnit := "";
  deriv.minValue := NONE();
  deriv.maxValue := NONE();
  deriv.initialValue := NONE();
  deriv.nominalValue := NONE();
  deriv.isFixed := false;
  deriv.aliasvar := SimCodeVar.NOALIAS();
  deriv.causality := SimCodeVar.INTERNAL();
  deriv.variable_index := NONE();
  deriv.isValueChangeable := false;
end derVarFromStateVar;


public function simVarString
  input SimCodeVar.SimVar inVar;
  output String s;
algorithm
  s := match(inVar)
  local
    Boolean isProtected,hideResult;
    Integer i;
    DAE.ComponentRef name, name2;
    Option<DAE.Exp> init;
    Option<DAE.ComponentRef> arrCref;
    Option<Integer> variable_index;
    SimCodeVar.AliasVariable aliasvar;
    String s1, s2, s3, sProt, sRes;
    list<String> numArrayElement;
    case (SimCodeVar.SIMVAR(name= name, aliasvar = SimCodeVar.NOALIAS(), index = i, initialValue=init, arrayCref=arrCref, variable_index=variable_index, numArrayElement=numArrayElement, isProtected=isProtected, hideResult=hideResult))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        if Util.isSome(arrCref) then s3 = " \tarrCref:"+ComponentReference.printComponentRefStr(Util.getOption(arrCref)); else s3="\tno arrCref"; end if;
        sProt = if isProtected then " protected " else "";
        sRes = if hideResult then " hideResult " else "";
        s = "index: "+intString(i)+": "+s1+" (no alias) "+sProt+sRes+" initial: "+ExpressionDump.printOptExpStr(init) + s3 + " index:("+printVarIndx(variable_index)+")" +" [" + stringDelimitList(numArrayElement,",")+"] ";
     then s;
    case (SimCodeVar.SIMVAR(name= name, aliasvar = SimCodeVar.ALIAS(varName = name2), index = i, initialValue=init, arrayCref=arrCref, variable_index=variable_index, numArrayElement=numArrayElement, isProtected=isProtected, hideResult=hideResult))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        s2 = ComponentReference.printComponentRefStr(name2);
        sProt = if isProtected then " protected "else "";
        sRes = if hideResult then " hideResult " else "";
        if Util.isSome(arrCref) then s3 = " \tarrCref:"+ComponentReference.printComponentRefStr(Util.getOption(arrCref)); else s3="\tno arrCref"; end if;
        s = "index: "+intString(i)+": "+s1+" (alias: "+s2+") "+sProt+sRes+" initial: "+ExpressionDump.printOptExpStr(init) + s3 + " index:("+printVarIndx(variable_index)+")" +" [" + stringDelimitList(numArrayElement,",")+"] ";
    then s;
    case (SimCodeVar.SIMVAR(name= name, aliasvar = SimCodeVar.NEGATEDALIAS(varName = name2), index = i, initialValue=init, arrayCref=arrCref,variable_index=variable_index, numArrayElement=numArrayElement, isProtected=isProtected, hideResult=hideResult))
    equation
        s1 = ComponentReference.printComponentRefStr(name);
        s2 = ComponentReference.printComponentRefStr(name2);
        sProt = if isProtected then " protected "else "";
        sRes = if hideResult then " hideResult " else "";
        if Util.isSome(arrCref) then s3 = " \tarrCref:"+ComponentReference.printComponentRefStr(Util.getOption(arrCref)); else s3="\tno arrCref"; end if;
        s = "index: "+intString(i)+": "+s1+" (negated alias: "+s2+") "+sProt+sRes+" initial: "+ExpressionDump.printOptExpStr(init) + s3 + " index:("+printVarIndx(variable_index)+")" +" [" + stringDelimitList(numArrayElement,",")+"] ";
     then s;
   end match;
end simVarString;


protected function printVarIndx
  input Option<Integer> i;
  output String s;
algorithm
  if Util.isSome(i) then s:=intString(Util.getOption(i)); else s := ""; end if;
end printVarIndx;

public function dumpVarLst"dumps a list of SimVars to stdout.
author:Waurich TUD 2014-05"
  input list<SimCodeVar.SimVar> varLst;
  input String header;
protected
  SimCodeVar.SimVar var;
algorithm
  if not listEmpty(varLst) then
    print(header+"\n----------------------\n");
  for var in varLst loop
    print(simVarString(var)+"\n");
  end for;
  end if;
end dumpVarLst;


public function printVarLstCrefs
    input list<SimCodeVar.SimVar> inVars;
    output String str;
protected
    DAE.ComponentRef cref;
    SimCodeVar.SimVar var;
algorithm
    str := "\t\tcrefs: ";
    for var in inVars loop
        SimCodeVar.SIMVAR(name= cref) := var;
        str := str + ComponentReference.debugPrintComponentRefTypeStr(cref) + " , ";
    end for;
end printVarLstCrefs;

protected function dumpVariablesString "dumps a list of SimCode.Variables to stdout.
author: Waurich TUD 2014-09"
  input list<SimCodeFunction.Variable> vars;
  input String delimiter;
algorithm
  _ := match(vars,delimiter)
    local
      String s1,s2;
      DAE.ComponentRef cref;
      DAE.Type ty;
      DAE.VarKind kind;
      Option<DAE.Exp> val;
      list<DAE.Exp> instDims;
      list<SimCodeFunction.Variable> rest;
    case({},_)
      equation
        then();
    case(SimCodeFunction.VARIABLE(name=cref,ty=ty,kind=kind)::rest,_)
      equation
        (s1,_) = DAEDump.printTypeStr(ty);
        s1 = Types.printTypeStr(ty);
        s2 = DAEDump.dumpKindStr(kind);
        print(ComponentReference.printComponentRefStr(cref)+" ("+s1+", "+s2+") "+delimiter);
        dumpVariablesString(rest,delimiter);
      then ();
  end match;
end dumpVariablesString;

public function dumpModelInfo"dumps the SimVars to stdout
author:Waurich TUD 2014-05"
  input SimCode.ModelInfo modelInfo;
protected
  Integer nsv,nalgv;
  SimCode.VarInfo varInfo;
  SimCodeVar.SimVars simVars;
  list<SimCodeVar.SimVar> stateVars;
  list<SimCodeVar.SimVar> derivativeVars;
  list<SimCodeVar.SimVar> algVars;
  list<SimCodeVar.SimVar> discreteAlgVars;
  list<SimCodeVar.SimVar> intAlgVars;
  list<SimCodeVar.SimVar> boolAlgVars;
  list<SimCodeVar.SimVar> aliasVars;
  list<SimCodeVar.SimVar> intAliasVars;
  list<SimCodeVar.SimVar> paramVars;
  list<SimCodeVar.SimVar> boolParamVars;
  list<SimCodeVar.SimVar> intParamVars;
  list<SimCodeVar.SimVar> extObjVars;
  list<SimCodeVar.SimVar> constVars;
  list<SimCodeVar.SimVar> intConstVars;
  list<SimCodeVar.SimVar> stringConstVars;
  list<SimCodeFunction.Function> functions;
algorithm
  SimCode.MODELINFO(vars=simVars, varInfo=varInfo, functions=functions) := modelInfo;
  SimCodeVar.SIMVARS(stateVars=stateVars,derivativeVars=derivativeVars,algVars=algVars,boolAlgVars=boolAlgVars,intAlgVars=intAlgVars,discreteAlgVars=discreteAlgVars,aliasVars=aliasVars,intAliasVars=intAliasVars,
  paramVars=paramVars,intParamVars=intParamVars,boolParamVars=boolParamVars, extObjVars=extObjVars,constVars=constVars,intConstVars=intConstVars,stringConstVars=stringConstVars) := simVars;
  SimCode.VARINFO(numStateVars=nsv,numAlgVars=nalgv) := varInfo;
  dumpVarLst(stateVars,"stateVars ("+intString(nsv)+")");
  dumpVarLst(derivativeVars,"derivativeVars");
  dumpVarLst(algVars,"algVars ("+intString(nalgv)+")");
  dumpVarLst(discreteAlgVars,"discreteAlgVars");
  dumpVarLst(intAlgVars,"intAlgVars");
  dumpVarLst(boolAlgVars,"boolAlgVars");
  dumpVarLst(aliasVars,"aliasVars");
  dumpVarLst(intAliasVars,"intAliasVars");
  dumpVarLst(paramVars,"paramVars");
  dumpVarLst(intParamVars,"intParamVars");
  dumpVarLst(boolParamVars,"boolParamVars");
  dumpVarLst(extObjVars,"extObjVars");
  dumpVarLst(constVars,"constVars");
  dumpVarLst(intConstVars,"intConstVars");
  dumpVarLst(stringConstVars,"stringConstVars");
  print("functions:\n-----------\n\n");
  dumpFunctions(functions);
end dumpModelInfo;

protected function dumpFunctions
  input list<SimCodeFunction.Function> functions;
algorithm
  _ := match(functions)
  local
    Absyn.Path path;
    list<SimCodeFunction.Function> rest;
    list<SimCodeFunction.Variable> outVars,functionArguments,variableDeclarations,funArgs, locals;
  case({})
    equation
    then ();
  case(SimCodeFunction.FUNCTION(name=path,outVars=outVars,functionArguments=functionArguments,variableDeclarations=variableDeclarations)::rest)
    equation
      print("Function: "+Absyn.pathStringNoQual(path)+"\n");
      print("\toutVars: ");
      dumpVariablesString(outVars," , ");
      print("\n\tfunctionArguments: ");
      dumpVariablesString(functionArguments," , ");
      print("\n\tvariableDeclarations: ");
      dumpVariablesString(variableDeclarations," , ");
      print("\n");
      dumpFunctions(rest);
    then ();
  case(SimCodeFunction.PARALLEL_FUNCTION(name=path)::rest)
    equation
      print("Parallel Function: "+Absyn.pathStringNoQual(path)+"\n");
      dumpFunctions(rest);
    then ();
  case(SimCodeFunction.KERNEL_FUNCTION(name=path)::rest)
    equation
      print("Kernel Function: "+Absyn.pathStringNoQual(path)+"\n");
      dumpFunctions(rest);
    then ();
  case(SimCodeFunction.EXTERNAL_FUNCTION(name=path,outVars=outVars)::rest)
    equation
      print("External Function: "+Absyn.pathStringNoQual(path)+"\n");
      print("\toutVars: ");
      dumpVariablesString(outVars," , ");
      print("\n");
      dumpFunctions(rest);
    then ();
  case(SimCodeFunction.RECORD_CONSTRUCTOR(name=path, funArgs=funArgs, locals=locals)::rest)
    equation
      print("Record: "+Absyn.pathStringNoQual(path)+"\n");
      print("\tfunArgs: ");
      dumpVariablesString(funArgs," , ");
      print("\n\tlocals: ");
      dumpVariablesString(locals," , ");
      print("\n");
      dumpFunctions(rest);
    then ();
  end match;
end dumpFunctions;

public function dumpSimEqSystemLst
  input list<SimCode.SimEqSystem> eqSysLstIn;
  input String delimiter;
protected
  SimCode.SimEqSystem sys;
algorithm
  for sys in eqSysLstIn loop
    dumpSimEqSystem(sys);
    print(delimiter);
  end for;
end dumpSimEqSystemLst;


public function simEqSystemString
"outputs a string representation of the given SimEqSystem.
author:Waurich TUD 2016-04"
  input SimCode.SimEqSystem eqSysIn;
  output String str;
algorithm
  str := matchcontinue(eqSysIn)
    local
      Boolean partMixed,lin,initCall,torn;
      Integer idx,idxLS,idxNLS,idx2,idxLS2,idxNLS2,idxMS;
      String s,s1,s2,s3,s4,s5,s6;
      list<String> sLst;
      DAE.Exp exp,right,lhs,iterator,startIt,endIt;
      DAE.ElementSource source;
      DAE.ComponentRef cref,left;
      SimCode.SimEqSystem cont;
      list<DAE.ComponentRef> crefs,crefs2,conds;
      list<DAE.Statement> stmts;
      list<SimCode.SimEqSystem> elsebranch,discEqs,eqs,eqs2,residual,residual2;
      list<SimCodeVar.SimVar> vars,vars2,discVars;
      list<DAE.Exp> beqs;
      list<tuple<DAE.Exp,list<SimCode.SimEqSystem>>> ifbranches;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac,simJac2;
      Option<SimCode.JacobianMatrix> jac,jac2;
      Option<SimCode.SimEqSystem> elseWhen;
      list<BackendDAE.WhenOperator> whenStmtLst;
      BackendDAE.Constraints cons;

    case(SimCode.SES_RESIDUAL(index=idx,exp=exp))
      equation
        s = intString(idx) +": "+ ExpressionDump.printExpStr(exp)+" (RESIDUAL)";
    then s;

    case(SimCode.SES_SIMPLE_ASSIGN(index=idx,cref=cref,exp=exp))
      equation
        s = intString(idx) +": "+ ComponentReference.printComponentRefStr(cref) + "=" + ExpressionDump.printExpStr(exp) + " [" +DAEDump.daeTypeStr(Expression.typeof(exp))+ "]";
      then s;

    case(SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(index=idx,cref=cref,exp=exp,cons=cons))
      equation
        s = intString(idx) +": "+ ComponentReference.printComponentRefStr(cref) + "=" + ExpressionDump.printExpStr(exp) + " [constraints: " + ExpressionDump.constraintDTlistToString(cons, "") + "]" + " [" +DAEDump.daeTypeStr(Expression.typeof(exp))+ "]";
      then s;

    case(SimCode.SES_ARRAY_CALL_ASSIGN(index=idx,lhs=lhs,exp=exp))
      equation
        s = intString(idx) +": "+ ExpressionDump.printExpStr(lhs) + "=" + ExpressionDump.printExpStr(exp) + " [" +DAEDump.daeTypeStr(Expression.typeof(exp))+ "]";
    then s;

      case(SimCode.SES_IFEQUATION(index=idx))
      equation
        s = intString(idx) +": "+ " (IF)";
    then s;

    case(SimCode.SES_ALGORITHM(index=idx,statements=stmts))
      equation
        sLst = List.map(stmts,DAEDump.ppStatementStr);
        s = intString(idx) +": "+ List.foldr(sLst, stringAppend, "");
    then s;

    case(SimCode.SES_INVERSE_ALGORITHM(index=idx,statements=stmts)) equation
      sLst = List.map(stmts, DAEDump.ppStatementStr);
      s = intString(idx) +": "+ List.foldr(sLst, stringAppend, "");
    then s;

    // no dynamic tearing
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=idx, indexLinearSystem=idxLS, vars=vars, beqs=beqs, residual=residual, jacobianMatrix=jac), NONE()))
      equation
        s = intString(idx) +": "+ " (LINEAR) index:"+intString(idxLS)+" jacobian: "+boolString(Util.isSome(jac))+"\n";
        s = s+"\tvariables:\n"+stringDelimitList(List.map(vars,simVarString),"\n");
        s = s+"\n\tb-vector:\n"+stringDelimitList(List.map(beqs,ExpressionDump.printExpStr),"\n");
        s = s+ "\t";
        s = s+stringDelimitList(List.map(residual,simEqSystemString),"\n\t");
        s = s+"\n";
    then s;

    // dynamic tearing
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=idx, indexLinearSystem=idxLS, vars=vars, beqs=beqs, residual=residual, jacobianMatrix=jac), SOME(SimCode.LINEARSYSTEM())))
      equation
        s = "strict set:\n"+intString(idx) +": "+ " (LINEAR) index:"+intString(idxLS)+" jacobian: "+boolString(Util.isSome(jac))+"\n";
        s = s+"\tvariables:\n\t"+stringDelimitList(List.map(vars,simVarString),"\t\n");
        s = s+"\n\tb-vector:\n"+stringDelimitList(List.map(beqs,ExpressionDump.printExpStr),"\t\n");
        s = s+ "\t";
        s = s+stringDelimitList(List.map(residual,simEqSystemString),"\n\t");
        s = s+"\n";
    then s;

    // no dynamic tearing
    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=idx,indexNonLinearSystem=idxNLS,jacobianMatrix=jac,eqs=eqs, crefs=crefs), NONE()))
      equation
        s = intString(idx) +": "+ " (NONLINEAR) index:"+intString(idxNLS)+" jacobian: "+boolString(Util.isSome(jac))+"\n";
        s = s+"crefs: "+stringDelimitList(List.map(crefs,ComponentReference.printComponentRefStr)," , ")+"\n";
        s = s+"\t";
        s = s+stringDelimitList(List.map(eqs,simEqSystemString),"\n\t");
        s = s+"\n";
    then s;

    // dynamic tearing
    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=idx,indexNonLinearSystem=idxNLS,jacobianMatrix=jac,eqs=eqs, crefs=crefs), SOME(SimCode.NONLINEARSYSTEM())))
      equation
        s = "strict set: \n"+intString(idx) +": "+ " (NONLINEAR) index:"+intString(idxNLS)+" jacobian: "+boolString(Util.isSome(jac))+"\n";
        s = s+"crefs: "+stringDelimitList(List.map(crefs,ComponentReference.printComponentRefStr)," , ")+"\n";
        s = s+"\t";
        s = s+stringDelimitList(List.map(eqs,simEqSystemString),"\n\t");
        s = s+"\n";
    then s;

    case(SimCode.SES_MIXED(index=idx,indexMixedSystem=idxMS, cont=cont, discEqs=eqs))
      equation
        s = intString(idx) +": "+ " (MIXED) index:"+intString(idxMS)+"\n";
        s = s + simEqSystemString(cont);
        s = s+stringDelimitList(List.map(eqs,simEqSystemString),"\n\t");
    then s;

    case(SimCode.SES_WHEN(index=idx, conditions=crefs, whenStmtLst = whenStmtLst, elseWhen=elseWhen))
      equation
        s = intString(idx) +": "+ " WHEN:( ";
        s = s+ stringDelimitList(List.map(crefs,ComponentReference.crefStr),", ") + " ) then: ";
        s = s +dumpWhenOps(whenStmtLst);
        if isSome(elseWhen) then
          s = s + " ELSEWHEN: ";
          dumpSimEqSystem(Util.getOption(elseWhen));
          s = s + simEqSystemString(Util.getOption(elseWhen));
        end if;
      then s;

    case(SimCode.SES_FOR_LOOP(index=idx,iter=iterator, startIt=startIt, endIt=endIt, cref=cref, exp=exp))
      equation
        s = intString(idx) +" FOR-LOOP: "+" for "+ExpressionDump.printExpStr(iterator)+" in ("+ExpressionDump.printExpStr(startIt)+":"+ExpressionDump.printExpStr(endIt)+") loop\n";
        s = s+ComponentReference.printComponentRefStr(cref) + "=" + ExpressionDump.printExpStr(exp)+"[" +DAEDump.daeTypeStr(Expression.typeof(exp))+ "]\n";
        s = s+"end for;";
    then s;

    case SimCode.SES_ALIAS()
      equation
        s = String(eqSysIn.index) +": alias of "+ String(eqSysIn.aliasOf);
    then s;

    case SimCode.SES_ALGEBRAIC_SYSTEM(index=idx, algSysIndex=idx2, partOfMixed=partMixed, tornSystem=torn , linearSystem=lin)
      algorithm
        s := intString(idx) +": "+ " (ALGEBRAIC_SYSTEM) algSysIndex: "+intString(idx2)+"\n";
        s := s+"\tpartOfMixed system: " + boolString(partMixed) + ", tornSystem: " + boolString(torn) + ", linearSystem: "+ boolString(lin) +"\n";

        s := s+omsiFuncEqnString(eqSysIn.residual);
        _ := match eqSysIn.matrix
          local
            SimCode.DerivativeMatrix matrix;
          case SOME(matrix as SimCode.DERIVATIVE_MATRIX(__))
            algorithm
             s := s+derivativeMatrixString(matrix);
            then ();
        end match;
        s := s+"\n";
    then s;

    else
      then
        "SOMETHING DIFFERENT\n";
  end matchcontinue;
end simEqSystemString;


public function dumpSimEqSystem "dumps the given SimEqSystem.
author:Waurich TUD 2013-11"
  input SimCode.SimEqSystem eqSysIn;
algorithm
  _ := matchcontinue(eqSysIn)
    local
      Boolean partMixed,lin,initCall;
      Integer idx,idxLS,idxNLS,idx2,idxLS2,idxNLS2,idxMS;
      String s,s1,s2,s3,s4,s5,s6;
      list<String> sLst;
      DAE.Exp exp,right,lhs,iterator,startIt,endIt;
      DAE.ElementSource source;
      DAE.ComponentRef cref,left;
      SimCode.SimEqSystem cont;
      list<DAE.ComponentRef> crefs,crefs2,conds;
      list<DAE.Statement> stmts;
      list<SimCode.SimEqSystem> elsebranch,discEqs,eqs,eqs2,residual,residual2;
      list<SimCodeVar.SimVar> vars,vars2,discVars;
      list<DAE.Exp> beqs;
      list<tuple<DAE.Exp,list<SimCode.SimEqSystem>>> ifbranches;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac,simJac2;
      Option<SimCode.JacobianMatrix> jac,jac2;
      Option<SimCode.SimEqSystem> elseWhen;
      list<BackendDAE.WhenOperator> whenStmtLst;

    // no dynamic tearing
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(jacobianMatrix=jac, simJac=simJac), NONE()))
      equation
        print(simEqSystemString(eqSysIn));
        dumpJacobianMatrix(jac);
        print("\tsimJac:\n");
        dumpSimJac(simJac);
    then ();

    // dynamic tearing
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(jacobianMatrix=jac, simJac=simJac), SOME(SimCode.LINEARSYSTEM(index=idx2,indexLinearSystem=idxLS2, residual=residual2, jacobianMatrix=jac2, simJac=simJac2))))
      equation
        print(simEqSystemString(eqSysIn));
        print("\n\tsimJac:\n");
        dumpSimJac(simJac);
        dumpJacobianMatrix(jac);
        print("\ncasual set:\n" + intString(idx2) +": "+ " (LINEAR) index:"+intString(idxLS2)+" jacobian: "+boolString(Util.isSome(jac))+"\n");
        print("\t");
        dumpSimEqSystemLst(residual2,"\n\t");
        print("\n\tsimJac:\n");
        dumpSimJac(simJac2);
        dumpJacobianMatrix(jac2);
    then ();

    // no dynamic tearing
    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(jacobianMatrix=jac), NONE()))
      equation
        print(simEqSystemString(eqSysIn));
        dumpJacobianMatrix(jac);
    then ();

    // dynamic tearing
    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(jacobianMatrix=jac), SOME(SimCode.NONLINEARSYSTEM(index=idx2,indexNonLinearSystem=idxNLS2,jacobianMatrix=jac2,eqs=eqs2, crefs=crefs2))))
      equation
        print(simEqSystemString(eqSysIn));
        dumpJacobianMatrix(jac);
        print("\ncasual set:\n" + intString(idx2) +": "+ " (NONLINEAR) index:"+intString(idxNLS2)+" jacobian: "+boolString(Util.isSome(jac2))+"\n");
        print("\t\tcrefs: "+stringDelimitList(List.map(crefs2,ComponentReference.printComponentRefStr)," , ")+"\n");
        print("\t");
        dumpSimEqSystemLst(eqs2,"\n\t");
        print("\n");
        dumpJacobianMatrix(jac2);
    then ();

    else
      equation
        print(simEqSystemString(eqSysIn));
    then ();
  end matchcontinue;
end dumpSimEqSystem;

protected function dumpSimJac
  input list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
protected
  Integer i1, i2;
  String res;
  SimCode.SimEqSystem simEqSys;
  tuple<Integer, Integer, SimCode.SimEqSystem> tpl;
algorithm
  if listEmpty(simJac) then res := "no simJac";
  else res := "";
  end if;
  for tpl in simJac loop
   (i1,i2,simEqSys) := tpl;
    print(res + "["+intString(i1) + ", " + intString(i2)+ "] ->");
    dumpSimEqSystem(simEqSys);
  end for;
  print("\n");
end dumpSimJac;

protected function dumpWhenOps
  input list<BackendDAE.WhenOperator> whenStmtLst;
  output String res;
protected
  BackendDAE.WhenOperator e;
algorithm
  res := "";
  for whenOps in whenStmtLst loop
    res := match whenOps
      case e as BackendDAE.ASSIGN()
      then res + ExpressionDump.printExpStr(e.left) + " = " + ExpressionDump.printExpStr(e.right) + "["+ DAEDump.daeTypeStr(Expression.typeof(e.right)) + "]";
      case e as BackendDAE.REINIT()
      then res + "reinit(" + ComponentReference.debugPrintComponentRefTypeStr(e.stateVar) + ", " + ExpressionDump.printExpStr(e.value) + ") ["+ DAEDump.daeTypeStr(Expression.typeof(e.value)) + "]";
      case e as BackendDAE.ASSERT()
      then res + "assert(" + ExpressionDump.printExpStr(e.condition) +  ExpressionDump.printExpStr(e.message) + ExpressionDump.printExpStr(e.level) + ")";
      case e as BackendDAE.TERMINATE()
      then res + "terminate(" + ExpressionDump.printExpStr(e.message) + ")";
      case e as BackendDAE.NORETCALL()
      then res + ExpressionDump.printExpStr(e.exp) + " ["+ DAEDump.daeTypeStr(Expression.typeof(e.exp)) + "]";
    end match;
  end for;
end dumpWhenOps;

protected function dumpJacobianMatrixLst
  "Takes a list and a function which does not return a value. The function is
   probably a function with side effects, like print."
  input list<SimCode.JacobianMatrix> simjacs;
algorithm
  for jac in simjacs loop
    print("\nsymbolic directional derivative:\n");
    dumpJacobianMatrix(SOME(jac));
    print("\n");
  end for;
end dumpJacobianMatrixLst;

protected function dumpJacobianMatrix
  input Option<SimCode.JacobianMatrix> jacOpt;
algorithm
  _ := match(jacOpt)
    local
      Integer idx;
      String s;
      SimCode.JacobianMatrix jac;
      list<SimCode.JacobianColumn> cols;
      list<SimCode.SimEqSystem> colEqs;
      list<SimCodeVar.SimVar> colVars;
    case(SOME(jac))
      equation
        SimCode.JAC_MATRIX(columns=cols, jacobianIndex=idx) = jac;
        colEqs  = List.flatten(list(a.columnEqns for a in cols));
        colVars = List.flatten(list(a.columnVars for a in cols));
        print("\tJacobian idx: "+intString(idx)+"\n\t");
        dumpSimEqSystemLst(colEqs,"\n\t");
        print("\n");
        dumpVarLst(colVars,"columnVars("+intString(listLength(colVars))+")");
      then ();
    case(NONE())
      then ();
  end match;
end dumpJacobianMatrix;

protected function extObjInfoString
  input SimCode.ExtObjInfo info;
protected
  list<SimCodeVar.SimVar> vars;
  list<SimCode.ExtAlias> aliases;
  DAE.ComponentRef cr1, cr2;
algorithm
  SimCode.EXTOBJINFO(vars=vars, aliases=aliases) := info;
  dumpVarLst(vars,"external object info");
  if not listEmpty(aliases) then
    print("external object aliase ("+intString(listLength(aliases))+")");
    for tpl in aliases loop
    (cr1,cr2) := tpl;
      print(ComponentReference.crefStr(cr1)+" = "+ComponentReference.crefStr(cr2));
    end for;
    print("\n");
  end if;
end extObjInfoString;

protected function dumpClockPartition
  input SimCode.ClockedPartition clockPart;
algorithm
  print("BaseClock:\n"+UNDERLINE+"\n"+ExpressionDump.clockKindString(clockPart.baseClock)+UNDERLINE+"\n\n");
  print(stringDelimitList(List.map(clockPart.subPartitions,subPartitionString),"\n\n")+"\n");
  print("\n");
end dumpClockPartition;

protected function previousString"outputs a string representation if the boolean says the var is a previous var"
  input Boolean isPreviousVar;
  output String s;
algorithm
  if isPreviousVar then
    s := " (PREVIOUS)";
  else
    s := " ";
  end if;
end previousString;

protected function subPartitionString"outputs a string representation of a SimCode.SubPartition"
  input SimCode.SubPartition subPart;
  output String str;
protected
  list<SimCodeVar.SimVar> simVars;
  list<Boolean> arePrevious;
  list<String> simVarStrings;
  String s;
algorithm
  simVars := List.map(subPart.vars,Util.tuple21);
  arePrevious := List.map(subPart.vars,Util.tuple22);
  simVarStrings := List.threadMap(List.map(simVars,simVarString), List.map(arePrevious,previousString),stringAppend);
  str := "SubPartition Vars:\n"+UNDERLINE+"\n";
  str := str + stringDelimitList(simVarStrings,"\n")+"\n";
  str := str + "partition equations:\n"+UNDERLINE+"\n";
  str := str + stringDelimitList(List.map(subPart.equations,simEqSystemString),"\n");
  str := str + "removedEquations equations:\n"+UNDERLINE+"\n";
  str := str + stringDelimitList(List.map(subPart.removedEquations,simEqSystemString),"\n");
  str := str + "SubClock:\n"+ BackendDump.subClockString(subPart.subClock);
  str := str + "Hold Events: "+boolString(subPart.holdEvents);
end subPartitionString;

public function dumpSimCodeDAEmodeDataString
  input Option<SimCode.DaeModeData> inDaeModedata;
  output String str;
algorithm
  _ := match(inDaeModedata)
  local
    SimCode.DaeModeData dmd;
    SimCode.SparsityPattern sparsityT;
  case(SOME(dmd)) algorithm
    print("\ndaeMode: \n" + UNDERLINE + "\n");
    str := "residual Equations:\n"+UNDERLINE+"\n";
    print(str);
    dumpSimEqSystemLst(List.flatten(dmd.daeEquations),"\n");
    dumpVarLst(dmd.residualVars,"residualVars("+intString(listLength(dmd.residualVars))+")");
    dumpVarLst(dmd.algebraicVars,"algebraicDAEVars("+intString(listLength(dmd.algebraicVars))+")");
    dumpVarLst(dmd.auxiliaryVars,"auxVars("+intString(listLength(dmd.auxiliaryVars))+")");
    if isSome(dmd.sparsityPattern) then
      str := "Sparsity Pattern:\n"+UNDERLINE+"\n";
      print(str);
      SimCode.JAC_MATRIX(sparsityT=sparsityT) := Util.getOption(dmd.sparsityPattern);
      dumpSparsePatternInt(sparsityT);
    end if;
  then ();
  case(NONE()) then ();
  end match;
end dumpSimCodeDAEmodeDataString;

public function dumpSimCodeDebug"prints the simcode debug output to std out."
  input SimCode.SimCode simCode;
protected
  list<Option<SimCode.JacobianMatrix>> jacObs;
algorithm
  print("\n\n*********************\n* SimCode Equations *\n*********************\n\n");
  print("\nallEquations: \n" + UNDERLINE + "\n\n");
  dumpSimEqSystemLst(simCode.allEquations,"\n");
  print(UNDERLINE + "\n\n\n");
  print("\nodeEquations ("+intString(listLength(simCode.odeEquations))+" systems): \n" + UNDERLINE + "\n");
  List.map1_0(simCode.odeEquations,dumpSimEqSystemLst,"\n");
  print(UNDERLINE + "\n\n\n");
  print("\nalgebraicEquations ("+intString(listLength(simCode.algebraicEquations))+" systems): \n" + UNDERLINE + "\n");
  List.map1_0(simCode.algebraicEquations,dumpSimEqSystemLst,"\n");
  print(UNDERLINE + "\n\n\n");
  print("clockPartitions ("+intString(listLength(simCode.clockedPartitions))+" systems):\n\n");
  List.map_0(simCode.clockedPartitions,dumpClockPartition);
  print(UNDERLINE + "\n\n\n");
  print("\ninitialEquations: ("+intString(listLength(simCode.initialEquations))+")\n"+ UNDERLINE+"\n");
  dumpSimEqSystemLst(simCode.initialEquations,"\n");
  print(UNDERLINE + "\n\n\n");
  print("\ninitialEquations_lambda0: ("+intString(listLength(simCode.initialEquations_lambda0))+")\n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.initialEquations_lambda0,"\n");
  if (Flags.getConfigEnum(Flags.SYM_SOLVER) > 0) then
    print("\ninlineEquations: ("+intString(listLength(simCode.inlineEquations))+" systems)\n" + UNDERLINE + "\n");
    dumpSimEqSystemLst(simCode.inlineEquations,"\n");
  end if;
  print("\nremovedInitialEquations: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.removedInitialEquations,"\n");
  print("\nstartValueEquations: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.startValueEquations,"\n");
  print("\nnominalValueEquations: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.nominalValueEquations,"\n");
  print("\nminValueEquations: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.minValueEquations,"\n");
  print("\nmaxValueEquations: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.maxValueEquations,"\n");
  print("\nparameterEquations: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.parameterEquations,"\n");
  print("\nremovedEquations: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.removedEquations,"\n");
  print("\nalgorithmAndEquationAsserts: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.algorithmAndEquationAsserts,"\n");
  print("\nequationsForZeroCrossings: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.equationsForZeroCrossings,"\n");
  print("\njacobianEquations: \n" + UNDERLINE + "\n");
  dumpSimEqSystemLst(simCode.jacobianEquations,"\n");
  extObjInfoString(simCode.extObjInfo);
  print("\njacobianMatrices: \n" + UNDERLINE + "\n");
  jacObs := List.map(simCode.jacobianMatrixes,Util.makeOption);
  List.map_0(jacObs,dumpJacobianMatrix);
  print("\nmodelInfo: \n" + UNDERLINE + "\n");
  dumpModelInfo(simCode.modelInfo);
  dumpSimCodeDAEmodeDataString(simCode.daeModeData);
end dumpSimCodeDebug;

protected function isAliasVar
  input SimCodeVar.SimVar var;
  output Boolean res;
algorithm
  res :=
  match (var)
    case (SimCodeVar.SIMVAR(aliasvar=SimCodeVar.NOALIAS()))
    then false;
  else
    then true;
  end match;
end isAliasVar;

protected function sortSimvars
  input array<list<SimCodeVar.SimVar>> simvars;
protected
  Integer i = 0;
  array<Integer> arr;
algorithm
  for i in SimVarsIndex loop
    Dangerous.arrayUpdateNoBoundsChecking(simvars, Integer(i), List.sort(Dangerous.arrayGetNoBoundsChecking(simvars, Integer(i)), simVarCompareByCrefSubsAtEndlLexical));
  end for;
  for v in Dangerous.arrayGetNoBoundsChecking(simvars, Integer(SimVarsIndex.inputs)) loop
    // Set input indexes as they appear in the sorted order; is mutable since we need the same index in the other lists of vars...
    i := match v
      case SimCodeVar.SIMVAR(inputIndex=SOME(arr))
        algorithm
          arrayUpdate(arr, 1, i);
        then i + 1;
      else
        algorithm
          Error.addInternalError("Failed to update indexes of simvars", sourceInfo());
        then fail();
    end match;
  end for;
end sortSimvars;

public function simVarCompareByCrefSubsAtEndlLexical
"mahge:
  Compare two simvars by their name. i.e. component ref.
  we use it to make sure elements of a vectorized array stay contagious
  sto each other in the correct offest/order.
  N.B. subs are pushed to end. They are compared if only
  the two crefs' idents are the same"
  input SimCodeVar.SimVar var1;
  input SimCodeVar.SimVar var2;
  output Boolean outBool;
protected
  DAE.ComponentRef cr1;
  DAE.ComponentRef cr2;
algorithm
  cr1 := varName(var1);
  cr2 := varName(var2);
  outBool := ComponentReference.crefLexicalGreaterSubsAtEnd(cr1,cr2);
end simVarCompareByCrefSubsAtEndlLexical;

protected function extendIncompleteArray
  input array<list<SimCodeVar.SimVar>> simvars;
protected
  list<SimCodeVar.SimVar> simVars;
  HashSet.HashSet set;
algorithm
  // for runtime CPP also the incomplete arrays need one special element to generate the array
  // search all arrays with array information
  set := HashSet.emptyHashSet();

  for i in SimVarsIndex loop
    set := List.fold(Dangerous.arrayGetNoBoundsChecking(simvars, Integer(i)), collectArrayFirstVars, set);
  end for;

  // add array information to incomplete arrays
  for i in SimVarsIndex loop
    (simVars, set) := List.mapFold(Dangerous.arrayGetNoBoundsChecking(simvars, Integer(i)), setArrayElementnoFirst, set);
    Dangerous.arrayUpdateNoBoundsChecking(simvars, Integer(i), simVars);
  end for;
end extendIncompleteArray;

protected function setArrayElementnoFirst
"author: Frenkel TUD 2012-10"
  input SimCodeVar.SimVar iVar;
  input HashSet.HashSet iSet;
  output SimCodeVar.SimVar oVar;
  output HashSet.HashSet oSet;
algorithm
  (oVar, oSet) := matchcontinue(iVar, iSet)
    local
      DAE.ComponentRef cr;
      SimCodeVar.SimVar var;
      HashSet.HashSet set;
    case (SimCodeVar.SIMVAR(arrayCref=SOME(_)), _)
      then
       (iVar, iSet);
    case (SimCodeVar.SIMVAR(name=cr, numArrayElement=_::_, arrayCref=NONE()), _)
      equation
        _::_ = ComponentReference.crefLastSubs(cr);
        cr = ComponentReference.crefStripLastSubs(cr);
        false = BaseHashSet.has(cr, iSet);
        var = addSimVarArrayCref(iVar, cr);
        set = BaseHashSet.add(cr, iSet);
      then
       (var, set);
    else (iVar, iSet);
  end matchcontinue;
end setArrayElementnoFirst;

protected function addSimVarArrayCref
"author: Frenkel TUD 2012-10"
  input SimCodeVar.SimVar iVar;
  input DAE.ComponentRef arrayCref;
  output SimCodeVar.SimVar oVar = iVar;
algorithm
  oVar.arrayCref := SOME(arrayCref);
end addSimVarArrayCref;

protected function collectArrayFirstVars
"author: Frenkel TUD 2012-10"
  input SimCodeVar.SimVar var;
  input HashSet.HashSet iSet;
  output HashSet.HashSet oSet;
algorithm
  oSet := match(var, iSet)
    local
      DAE.ComponentRef cr;
    case (SimCodeVar.SIMVAR(name=cr, arrayCref=SOME(_)), _)
      equation
        cr = ComponentReference.crefStripLastSubs(cr);
      then
        BaseHashSet.add(cr, iSet);
    else iSet;
  end match;
end collectArrayFirstVars;

protected function fixIndex
  input array<list<SimCodeVar.SimVar>> simVars;
protected
  Integer ix=0;
  list<SimCodeVar.SimVar> lst;
  Boolean isCpp = (Config.simCodeTarget() == "Cpp" or Config.simCodeTarget() == "omsicpp");
algorithm
  for i in SimVarsIndex.state : SimVarsIndex.realOptimizeFinalConstraints loop
    lst := Dangerous.arrayGetNoBoundsChecking(simVars,Integer(i));
    Dangerous.arrayUpdateNoBoundsChecking(simVars, Integer(i), rewriteIndex(lst, ix));
    if not isCpp then
      ix := ix + listLength(lst);
    end if;
  end for;
  for i in SimVarsIndex.param : SimVarsIndex.stringConst loop // Skip jacobian, seed
    Dangerous.arrayUpdateNoBoundsChecking(simVars, Integer(i), rewriteIndex(Dangerous.arrayGetNoBoundsChecking(simVars,Integer(i)), 0));
  end for;
end fixIndex;

public function rewriteIndex
  input list<SimCodeVar.SimVar> inVars;
  output list<SimCodeVar.SimVar> outVars = {};
  input output Integer index;
algorithm
  for var in inVars loop
    var.index := index;
    outVars := var::outVars;
    index := index+1;
  end for;
  outVars := Dangerous.listReverseInPlace(outVars);
end rewriteIndex;

protected function setVariableIndex
  input array<list<SimCodeVar.SimVar>> simVars;
protected
  Integer index_=1;
  list<SimCodeVar.SimVar> lst;
algorithm
  //special order for fmi: real => intger => boolean => string => external
  for i in SimVarsIndex.state : SimVarsIndex.stringConst loop
    (lst, index_) := setVariableIndexHelper(Dangerous.arrayGetNoBoundsChecking(simVars, Integer(i)), index_);
    Dangerous.arrayUpdateNoBoundsChecking(simVars, Integer(i), lst);
  end for;
end setVariableIndex;

public function setVariableIndexHelper
  input list<SimCodeVar.SimVar> inVars;
  input Integer inIndex;
  output list<SimCodeVar.SimVar> outVars;
  output Integer outIndex;
algorithm
  (outVars, outIndex) := List.mapFold(inVars, setVariableIndexHelper2, inIndex);
end setVariableIndexHelper;

protected function setVariableIndexHelper2
  input SimCodeVar.SimVar inVar;
  input Integer inIndex;
  output SimCodeVar.SimVar outVar = inVar;
  output Integer outIndex = inIndex + getNumElems(inVar);
algorithm
  outVar.variable_index := SOME(inIndex);
end setVariableIndexHelper2;

public function createCrefToSimVarHT "author: unknown and marcusw
 Create a hash table that maps all variable names (crefs) to the simVar objects."
  input SimCode.ModelInfo modelInfo;
  output SimCode.HashTableCrefToSimVar outHT;
protected
  Integer size;
  SimCode.VarInfo varInfo;
  HashTableCrILst.HashTable arraySimVars;
  SimCodeVar.SimVars vars;
algorithm
  try
    varInfo := modelInfo.varInfo;
    vars := modelInfo.vars;
    size := varInfo.numStateVars + varInfo.numAlgVars + varInfo.numIntAlgVars + varInfo.numBoolAlgVars + varInfo.numAlgAliasVars +
            varInfo.numIntAliasVars + varInfo.numBoolAliasVars + varInfo.numParams + varInfo.numIntParams + varInfo.numBoolParams +
            varInfo.numOutVars + varInfo.numInVars + varInfo.numOptimizeConstraints + varInfo.numOptimizeFinalConstraints;
    size := intMax(size, 1023);
    outHT := HashTableCrefSimVar.emptyHashTableSized(size);
    arraySimVars := HashTableCrILst.emptyHashTableSized(size);

    outHT := List.fold(vars.stateVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    //true := intLt(size, -1);
    outHT := List.fold(vars.derivativeVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.algVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    arraySimVars := List.fold(vars.algVars, getArraySimVars, arraySimVars);
    outHT := List.fold(vars.discreteAlgVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.intAlgVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.boolAlgVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.paramVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    arraySimVars := List.fold(vars.paramVars, getArraySimVars, arraySimVars);
    outHT := List.fold(vars.intParamVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.boolParamVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.aliasVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    arraySimVars := List.fold(vars.aliasVars, getArraySimVars, arraySimVars);
    outHT := List.fold(vars.intAliasVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.boolAliasVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.stringAlgVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.stringParamVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.stringAliasVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.extObjVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.constVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.intConstVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.boolConstVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.stringConstVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.sensitivityVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.jacobianVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.seedVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.realOptimizeConstraintsVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
    outHT := List.fold(vars.realOptimizeFinalConstraintsVars, HashTableCrefSimVar.addSimVarToHashTable, outHT);
  else
    Error.addInternalError("function createCrefToSimVarHT failed", sourceInfo());
  end try;
end createCrefToSimVarHT;

protected function getArraySimVars "author: marcusw
  store the array-cref of the variable in the hash table and add the variable-index as value. The variable is handled as array-variable,
  if it has more than one element as numArrayElement."
  input SimCodeVar.SimVar iSimVar;
  input HashTableCrILst.HashTable iArrayMapping;
  output HashTableCrILst.HashTable oArrayMapping;
protected
  DAE.ComponentRef name;
  DAE.ComponentRef arrayCref;
  HashTableCrILst.HashTable tmpArrayMapping = iArrayMapping;
  list<Integer> arrayVars;
  Integer index;
algorithm
  oArrayMapping := match(iSimVar)
    case(SimCodeVar.SIMVAR(name=name, index=index, numArrayElement=_::_))
      equation
        arrayCref = ComponentReference.crefStripLastSubs(name);
        if(BaseHashTable.hasKey(arrayCref, iArrayMapping)) then
          arrayVars = BaseHashTable.get(arrayCref, iArrayMapping);
          tmpArrayMapping = BaseHashTable.add((arrayCref, index::arrayVars), tmpArrayMapping);
        else
          tmpArrayMapping = BaseHashTable.add((arrayCref, {index}), tmpArrayMapping);
        end if;
        //print("markSimVarArrays: " + ComponentReference.printComponentRefStr(name) + " for " + ComponentReference.printComponentRefStr(ComponentReference.crefStripLastSubs(name)) + "\n");
      then tmpArrayMapping;
    else
      then iArrayMapping;
  end match;
end getArraySimVars;

protected function getAliasVar
  input BackendDAE.Var inVar;
  input Option<BackendDAE.Variables> inAliasVars;
  output SimCodeVar.AliasVariable outAlias;
algorithm
  outAlias :=
  matchcontinue (inVar, inAliasVars)
    local
      DAE.ComponentRef name;
      BackendDAE.Variables aliasVars;
      BackendDAE.Var var;
      DAE.Exp e;
      SimCodeVar.AliasVariable alias;
    case (BackendDAE.VAR(varName=name), SOME(aliasVars))
      equation
        ((var :: _), _) = BackendVariable.getVar(name, aliasVars);
        // does not work
        // e = BaseHashTable.get(name, varMappings);
        e = BackendVariable.varBindExp(var);
        (e, _) = ExpressionSimplify.simplify(e);
        alias = getAliasVar1(e, var);
      then alias;
    else SimCodeVar.NOALIAS();
  end matchcontinue;
end getAliasVar;

protected function getAliasVar1
  input DAE.Exp inExp;
  input BackendDAE.Var inVar;
  output SimCodeVar.AliasVariable outAlias;
algorithm
  outAlias :=
  matchcontinue (inExp, inVar)
    local
      DAE.ComponentRef name;
      Absyn.Path fname;

    case (DAE.CREF(componentRef=name), _) then SimCodeVar.ALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS(_), exp=DAE.CREF(componentRef=name)), _) then SimCodeVar.NEGATEDALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(_), exp=DAE.CREF(componentRef=name)), _) then SimCodeVar.NEGATEDALIAS(name);
    case (DAE.LUNARY(operator=DAE.NOT(_), exp=DAE.CREF(componentRef=name)), _) then SimCodeVar.NEGATEDALIAS(name);
    case (DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)}), _)
      equation
      Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then SimCodeVar.ALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS(_), exp=DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)})), _)
      equation
       Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then SimCodeVar.NEGATEDALIAS(name);
    case (DAE.UNARY(operator=DAE.UMINUS_ARR(_), exp=DAE.CALL(path=fname, expLst={DAE.CREF(componentRef=name)})), _)
      equation
       Builtin.isDer(fname);
       name = ComponentReference.crefPrefixDer(name);
    then SimCodeVar.NEGATEDALIAS(name);
    else SimCodeVar.NOALIAS();
  end matchcontinue;
end getAliasVar1;

protected function unparseCommentOptionNoAnnotationNoQuote
  input Option<SCode.Comment> absynComment;
  output String commentStr;
algorithm
  commentStr := match (absynComment)
    case (SOME(SCode.COMMENT(_, SOME(commentStr)))) then commentStr;
    else "";
  end match;
end unparseCommentOptionNoAnnotationNoQuote;

// =============================================================================
// section for ???
//
// =============================================================================

/*mahge: kernel functions*/

protected function dlowvarToSimvar
  input BackendDAE.Var dlowVar;
  input Option<BackendDAE.Variables> optAliasVars;
  input BackendDAE.Variables inVars;
  output SimCodeVar.SimVar simVar;
algorithm
  simVar := match (dlowVar, optAliasVars, inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.VarKind kind;
      DAE.VarDirection dir;
      list<DAE.Dimension> inst_dims;
      list<String> numArrayElement;
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Exp hideResultExp;
      Option<SCode.Comment> comment;
      BackendDAE.Type tp;
      String  commentStr, unit, displayUnit;
      Option<DAE.Exp> minValue, maxValue;
      Option<DAE.Exp> initVal;
      Option<DAE.Exp> nomVal;
      Boolean isFixed;
      DAE.Type type_;
      Boolean isDiscrete, isValueChangeable;
      Option<DAE.ComponentRef> arrayCref;
      SimCodeVar.AliasVariable aliasvar;
      DAE.ElementSource source;
      BackendDAE.Variables vars;
      SimCodeVar.Causality caus;
      Boolean isProtected;
      Boolean hideResult;

    case ((BackendDAE.VAR(varName = cr,
      varKind = kind as BackendDAE.PARAM(),
      arryDim = inst_dims,
      values = dae_var_attr,
      hideResult = hideResultExp,
      comment = comment,
      varType = tp,
      source = source)), _, vars)
      equation
        commentStr = unparseCommentOptionNoAnnotationNoQuote(comment);
        (unit, displayUnit) = extractVarUnit(dae_var_attr);
        isProtected = getProtected(dae_var_attr);
        hideResult = getHideResult(hideResultExp, isProtected);
        (minValue, maxValue) = getMinMaxValues(dlowVar);
        initVal = getStartValue(dlowVar);
        nomVal = getNominalValue(dlowVar);
        // checkInitVal(initVal, source);
        isFixed = BackendVariable.varFixed(dlowVar);
        type_ = tp;
        isDiscrete = BackendVariable.isVarDiscrete(dlowVar);
        arrayCref = ComponentReference.getArrayCref(cr);
        aliasvar = getAliasVar(dlowVar, optAliasVars);
        caus = getCausality(dlowVar, vars);
        numArrayElement = List.map(inst_dims, ExpressionDump.dimensionIntString);
        // print("name: " + ComponentReference.printComponentRefStr(cr) + "indx: " + intString(indx) + "\n");
        // check if the variable has changeable value
        // parameter which has final = true or evaluate annotation are not changeable
        isValueChangeable = ((not BackendVariable.hasVarEvaluateTrueAnnotationOrFinalOrProtected(dlowVar)
                            and (BackendVariable.varHasConstantBindExp(dlowVar) or not BackendVariable.varHasBindExp(dlowVar))))
                            and isFixed;
      then
        SimCodeVar.SIMVAR(cr, kind, commentStr, unit, displayUnit, -1 /* use -1 to get an error in simulation if something failed */,
        minValue, maxValue, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, caus, NONE(), numArrayElement, isValueChangeable, isProtected, hideResult, NONE(), NONE());

    // Start value of states may be changeable
    case ((BackendDAE.VAR(varName = cr,
      varKind = kind as BackendDAE.STATE(),
      arryDim = inst_dims,
      values = dae_var_attr,
      hideResult = hideResultExp,
      comment = comment,
      varType = tp,
      source = source)), _, vars)
      equation
        _ = match BackendVariable.varStateSelect(dlowVar)
          case DAE.NEVER()
            algorithm
              Error.addSourceMessage(Error.STATE_STATESELECT_NEVER, {ComponentReference.printComponentRefStr(cr)}, source.info);
            then ();
          else ();
        end match;
        commentStr = unparseCommentOptionNoAnnotationNoQuote(comment);
        (unit, displayUnit) = extractVarUnit(dae_var_attr);
        isProtected = getProtected(dae_var_attr);
        hideResult = getHideResult(hideResultExp, isProtected);
        (minValue, maxValue) = getMinMaxValues(dlowVar);
        initVal = getStartValue(dlowVar);
        nomVal = getNominalValue(dlowVar);
        // checkInitVal(initVal, source);
        isFixed = BackendVariable.varFixed(dlowVar);
        type_ = tp;
        isDiscrete = BackendVariable.isVarDiscrete(dlowVar);
        arrayCref = ComponentReference.getArrayCref(cr);
        aliasvar = getAliasVar(dlowVar, optAliasVars);
        caus = getCausality(dlowVar, vars);
        numArrayElement = List.map(inst_dims, ExpressionDump.dimensionIntString);
        isValueChangeable = BackendVariable.varHasConstantStartExp(dlowVar);
        // print("name: " + ComponentReference.printComponentRefStr(cr) + "indx: " + intString(indx) + "\n");
      then
        SimCodeVar.SIMVAR(cr, kind, commentStr, unit, displayUnit, -1 /* use -1 to get an error in simulation if something failed */,
        minValue, maxValue, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, caus, NONE(), numArrayElement, isValueChangeable, isProtected, hideResult, NONE(), NONE());

    case ((BackendDAE.VAR(varName = cr,
      varKind = kind,
      arryDim = inst_dims,
      values = dae_var_attr,
      hideResult = hideResultExp,
      comment = comment,
      varType = tp,
      source = source)), _, vars)
      equation
        _ = match BackendVariable.varStateSelect(dlowVar)
          case DAE.ALWAYS()
            guard valueEq(kind, BackendDAE.VARIABLE()) and not ComponentReference.isPreviousCref(cr) /* TODO: Why are clocked variables continuous and not discrete? */
            algorithm
              Error.addSourceMessage(Error.NON_STATE_STATESELECT_ALWAYS, {ComponentReference.printComponentRefStr(cr)}, source.info);
            then ();
          else ();
        end match;
        commentStr = unparseCommentOptionNoAnnotationNoQuote(comment);
        (unit, displayUnit) = extractVarUnit(dae_var_attr);
        isProtected = getProtected(dae_var_attr);
        hideResult = getHideResult(hideResultExp, isProtected);
        (minValue, maxValue) = getMinMaxValues(dlowVar);
        initVal = getStartValue(dlowVar);
        nomVal = getNominalValue(dlowVar);
        // checkInitVal(initVal, source);
        isFixed = BackendVariable.varFixed(dlowVar);
        type_ = tp;
        isDiscrete = BackendVariable.isVarDiscrete(dlowVar);
        arrayCref = ComponentReference.getArrayCref(cr);
        aliasvar = getAliasVar(dlowVar, optAliasVars);
        caus = getCausality(dlowVar, vars);
        numArrayElement = List.map(inst_dims, ExpressionDump.dimensionIntString);
        isValueChangeable = match caus case SimCodeVar.INPUT() then true; else false; end match;
        // print("name: " + ComponentReference.printComponentRefStr(cr) + "indx: " + intString(indx) + "\n");
      then
        SimCodeVar.SIMVAR(cr, kind, commentStr, unit, displayUnit, -1 /* use -1 to get an error in simulation if something failed */,
        minValue, maxValue, initVal, nomVal, isFixed, type_, isDiscrete, arrayCref, aliasvar, source, caus, NONE(), numArrayElement, isValueChangeable, isProtected, hideResult, NONE(), NONE());
  end match;
end dlowvarToSimvar;

// lochel: This will now be checked in CodegenUtil.tpl (see #2597/#2601)
// protected function checkInitVal
//   input Option<DAE.Exp> oexp;
//   input DAE.ElementSource source;
// algorithm
//   _ := match (oexp, source)
//     local
//       SourceInfo info;
//       String str;
//       DAE.Exp exp;
//     case (NONE(), _) then ();
//     case (SOME(DAE.RCONST(_)), _) then ();
//     case (SOME(DAE.ICONST(_)), _) then ();
//     case (SOME(DAE.SCONST(_)), _) then ();
//     case (SOME(DAE.BCONST(_)), _) then ();
//     // adrpo, 2011-04-18 -> enumeration literal is OK also
//     case (SOME(DAE.ENUM_LITERAL(index = _)), _) then ();
//     case (SOME(DAE.CALL(attr=DAE.CALL_ATTR(ty=DAE.T_COMPLEX(complexClassType=ClassInf.EXTERNAL_OBJ(path=_))))), _) then ();
//     case (SOME(exp), DAE.SOURCE(info=info))
//       equation
//         str = "Initial value of unknown type: " + ExpressionDump.printExpStr(exp);
//         Error.addSourceMessage(Error.INTERNAL_ERROR, {str}, info);
//       then ();
//   end match;
// end checkInitVal;

protected function getCausality
  input BackendDAE.Var dlowVar;
  input BackendDAE.Variables inVars;
  output SimCodeVar.Causality caus;
algorithm
  caus := matchcontinue (dlowVar, inVars)
    local
      DAE.ComponentRef cr;
      BackendDAE.Variables globalKnownVars;
    case (BackendDAE.VAR(varDirection = DAE.OUTPUT()), _) then SimCodeVar.OUTPUT();
    case (BackendDAE.VAR(varName = cr, varDirection = DAE.INPUT()), globalKnownVars)
      equation
        (_, _) = BackendVariable.getVar(cr, globalKnownVars);
      then SimCodeVar.INPUT();
    else SimCodeVar.INTERNAL();
  end matchcontinue;
end getCausality;

protected function traversingdlowvarToSimvarFold
  input BackendDAE.Var v;
  input tuple<list<SimCodeVar.SimVar>, BackendDAE.Variables> inTpl;
  output tuple<list<SimCodeVar.SimVar>, BackendDAE.Variables> outTpl;
algorithm
  (_, outTpl) := traversingdlowvarToSimvar(v, inTpl);
end traversingdlowvarToSimvarFold;

public function traversingdlowvarToSimvar
  input output BackendDAE.Var var;
  input tuple<list<SimCodeVar.SimVar>, BackendDAE.Variables> inTpl;
  output tuple<list<SimCodeVar.SimVar>, BackendDAE.Variables> outTpl;
protected
  list<SimCodeVar.SimVar> sv_lst;
  SimCodeVar.SimVar sv;
  BackendDAE.Variables vars;
algorithm
  (sv_lst, vars) := inTpl;
  sv := dlowvarToSimvar(var, NONE(), vars);
  outTpl := (sv::sv_lst, vars);
end traversingdlowvarToSimvar;

public function getMatchingExpsList
  input list<DAE.Exp> inExps;
  input MatchFn inFn;
  output list<DAE.Exp> outExpLst;
  partial function MatchFn
    input DAE.Exp inExp;
    input list<DAE.Exp> inExps;
    output DAE.Exp outExp;
    output list<DAE.Exp> outExps;
  end MatchFn;
algorithm
  (_, outExpLst) := Expression.traverseExpList(inExps, inFn, {});
end getMatchingExpsList;

protected function extractVarUnit "author: asodja, 2010-03-11
  Extract variable's unit and displayUnit as strings from
  DAE.VariablesAttributes structures."
  input Option<DAE.VariableAttributes> var_attr;
  output String unitStr;
  output String displayUnitStr;
algorithm
  (unitStr, displayUnitStr) := matchcontinue(var_attr)
    local
      Option<DAE.Exp> uexp, duexp;
    case SOME(DAE.VAR_ATTR_REAL(unit = uexp, displayUnit=duexp))
      equation
        unitStr = extractVarUnitStr(uexp);
        displayUnitStr = extractVarUnitStr(duexp);
      then (unitStr, displayUnitStr);
    else ("", "");
  end matchcontinue;
end extractVarUnit;

protected function extractVarUnitStr "author: asodja, 2010-03-11
  Extract variable's unit and displayUnit as strings from
  DAE.VariablesAttributes structures."
  input Option<DAE.Exp> exp;
  output String str;
algorithm
  str := match exp
    local
      DAE.Exp e;
    case SOME(DAE.SCONST(str)) then str;
    case NONE() then "";
    case SOME(e)
      algorithm
        Error.addInternalError("Unexpected expression (should have been handled earlier, probably in the front-end. Unit/displayUnit expression is not a string literal: " + ExpressionDump.printExpStr(e), sourceInfo());
      then "";
  end match;
end extractVarUnitStr;

protected function getMinMaxValues "extract min/max values from BackendDAE.Variable"
  input BackendDAE.Var inDAELowVar;
  output Option<DAE.Exp> outMinValue;
  output Option<DAE.Exp> outMaxValue;
algorithm
  (outMinValue, outMaxValue) := matchcontinue(inDAELowVar)
    local
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Exp minValue, maxValue;

    case(BackendDAE.VAR(varType=DAE.T_REAL(), values=dae_var_attr)) equation
      (SOME(minValue), SOME(maxValue)) = DAEUtil.getMinMaxValues(dae_var_attr);
      // lochel: #2597
      // true = Expression.isConstValue(minValue);
      // true = Expression.isConstValue(maxValue);
    then (SOME(minValue), SOME(maxValue));

    case(BackendDAE.VAR(varType=DAE.T_REAL(), values=dae_var_attr)) equation
      (SOME(minValue), NONE()) = DAEUtil.getMinMaxValues(dae_var_attr);
      // lochel: #2597
      // true = Expression.isConstValue(minValue);
    then (SOME(minValue), NONE());

    case(BackendDAE.VAR(varType=DAE.T_REAL(), values=dae_var_attr)) equation
      (NONE(), SOME(maxValue)) = DAEUtil.getMinMaxValues(dae_var_attr);
      // lochel: #2597
      // true = Expression.isConstValue(maxValue);
    then (NONE(), SOME(maxValue));

    else (NONE(), NONE());
  end matchcontinue;
end getMinMaxValues;

protected function getStartValue "Extract initial value from BackendDAE.Variable, if it has any"
  input BackendDAE.Var daelowVar;
  output Option<DAE.Exp> initVal;
algorithm
  initVal := matchcontinue(daelowVar)
    local
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Exp e;

    case (BackendDAE.VAR(varKind = BackendDAE.VARIABLE(), values = dae_var_attr)) equation
      e = DAEUtil.getStartAttrFail(dae_var_attr);
     then SOME(e);

    case (BackendDAE.VAR(varKind = BackendDAE.DISCRETE(), values = dae_var_attr)) equation
      e = DAEUtil.getStartAttrFail(dae_var_attr);
     then SOME(e);

    case (BackendDAE.VAR(varKind = BackendDAE.STATE(), values = dae_var_attr)) equation
      e = DAEUtil.getStartAttrFail(dae_var_attr);
     then SOME(e);

    case (BackendDAE.VAR(varKind = BackendDAE.ALG_STATE(), values = dae_var_attr)) equation
      e = DAEUtil.getStartAttrFail(dae_var_attr);
     then SOME(e);

    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_DER(), values = dae_var_attr)) equation
      e = DAEUtil.getStartAttrFail(dae_var_attr);
     then SOME(e);

    case (BackendDAE.VAR(varKind = BackendDAE.DUMMY_STATE(), values = dae_var_attr)) equation
      e = DAEUtil.getStartAttrFail(dae_var_attr);
     then SOME(e);

    /* Parameters with constant binding */
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), bindExp = SOME(e))) guard Expression.isConst(e)
     then SOME(e);

    /* Parameters without constant binding. Investigate if it has start value */
    case (BackendDAE.VAR(varKind = BackendDAE.PARAM(), values = dae_var_attr)) equation
      e = DAEUtil.getStartAttrFail(dae_var_attr);
     then SOME(e);

    case (BackendDAE.VAR(varKind = BackendDAE.EXTOBJ(_), bindExp = SOME(e)))
     then SOME(e);

    case (BackendDAE.VAR(values = dae_var_attr)) guard(BackendVariable.isVarNonDiscreteAlg(daelowVar))
     then SOME(DAEUtil.getStartAttrFail(dae_var_attr));

    else NONE();
  end matchcontinue;
end getStartValue;

protected function getNominalValue "Extract nominal value from BackendDAE.Variable, if it has any"
  input BackendDAE.Var daelowVar;
  output Option<DAE.Exp> nomVal;
algorithm
  nomVal := matchcontinue(daelowVar)
    local
      Option<DAE.VariableAttributes> dae_var_attr;
      DAE.Exp e;

    case (BackendDAE.VAR(varType = DAE.T_REAL(), values = dae_var_attr)) equation
      e = DAEUtil.getNominalAttrFail(dae_var_attr);
      // lochel: #2597
      // true = Expression.isConstValue(e);
    then SOME(e);

    else NONE();
  end matchcontinue;
end getNominalValue;

public function functionInfo
  input SimCodeFunction.Function fn;
  output SourceInfo info;
algorithm
  info := match fn
    case SimCodeFunction.FUNCTION(info = info) then info;
    case SimCodeFunction.EXTERNAL_FUNCTION(info = info) then info;
    case SimCodeFunction.RECORD_CONSTRUCTOR(info = info) then info;
  end match;
end functionInfo;

public function functionPath
  input SimCodeFunction.Function fn;
  output Absyn.Path name;
algorithm
  name := match fn
    case SimCodeFunction.FUNCTION(name=name) then name;
    case SimCodeFunction.PARALLEL_FUNCTION(name=name) then name;
    case SimCodeFunction.KERNEL_FUNCTION(name=name) then name;
    case SimCodeFunction.EXTERNAL_FUNCTION(name=name) then name;
    case SimCodeFunction.RECORD_CONSTRUCTOR(name=name) then name;
  end match;
end functionPath;

public function eqInfo
  input SimCode.SimEqSystem eq;
  output SourceInfo info;
algorithm
  info := match eq
    case SimCode.SES_RESIDUAL(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_SIMPLE_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_ARRAY_CALL_ASSIGN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_WHEN(source=DAE.SOURCE(info=info)) then info;
    case SimCode.SES_FOR_LOOP(source=DAE.SOURCE(info=info)) then info;
  end match;
end eqInfo;

public function simEqSystemIndex
  input SimCode.SimEqSystem eq;
  output Integer index;
algorithm
  index := match eq
    case SimCode.SES_RESIDUAL(index=index) then index;
    case SimCode.SES_SIMPLE_ASSIGN(index=index) then index;
    case SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(index=index) then index;
    case SimCode.SES_ARRAY_CALL_ASSIGN(index=index) then index;
    case SimCode.SES_IFEQUATION(index=index) then index;
    case SimCode.SES_ALGORITHM(index=index) then index;
    case SimCode.SES_INVERSE_ALGORITHM(index=index) then index;
    case SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(index=index)) then index;
    case SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(index=index)) then index;
    case SimCode.SES_MIXED(index=index) then index;
    case SimCode.SES_WHEN(index=index) then index;
    case SimCode.SES_FOR_LOOP(index=index) then index;
    case SimCode.SES_ALIAS(index=index) then index;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,{"SimCodeUtil.simEqSystemIndex failed"});
      then fail();
  end match;
end simEqSystemIndex;


protected function adjustStatesForInlineSolver
  input list<SimCodeVar.SimVar> inStates;
  output list<SimCodeVar.SimVar> outStates = {};
algorithm
try
  for var in inStates loop
    var.name := ComponentReference.appendStringLastIdent("$Old", var.name);
    var.varKind := BackendDAE.ALG_STATE_OLD();
    outStates := var::outStates;
  end for;
else
  Error.addMessage(Error.INTERNAL_ERROR,{"SimCodeUtil.adjustStatesForInlineSolver failed"});
  fail();
end try;
end adjustStatesForInlineSolver;

/**************************************/
/************* for index ***************/

protected function setVariableDerIndex "
Author bz 2008-06
This function investigates the system of equations finding an order for derivative variables.
It only selects variables that have an derivative order, order=0 (no derivative) will not be included.
"
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.EqSystems inEqSystems;
  output list<tuple<DAE.ComponentRef, Integer>> outOrder;
algorithm outOrder := matchcontinue(inDlow, inEqSystems)
  local
    list<tuple<DAE.ComponentRef, Integer>> variableIndex;
     list<tuple<DAE.ComponentRef, Integer>> variableIndex2;
      list<tuple<DAE.ComponentRef, Integer>> variableIndex3;
    BackendDAE.EqSystem syst;
    BackendDAE.EqSystems systs;
 case(_, {})
     then
     {};
 case(_, syst::systs)
    equation
      if Flags.isSet(Flags.FAILTRACE) then
        print(" set  variabale der index for eqsystem"+ "\n");
      end if;
      variableIndex =  setVariableDerIndex2(inDlow, syst);
      variableIndex2 = setVariableDerIndex(inDlow, systs);
      variableIndex3 = listAppend(variableIndex, variableIndex2);
    then variableIndex3;
  else
    equation
      print(" Failure in setVariableDerIndex \n");
    then fail();
 end matchcontinue;
end setVariableDerIndex;


protected function setVariableDerIndex2 "
Author bz 2008-06
This function investigates the system of equations finding an order for derivative variables.
It only selects variables that have an derivative order, order=0 (no derivative) will not be included.
"
  input BackendDAE.BackendDAE inDlow;
  input BackendDAE.EqSystem syst;
  output list<tuple<DAE.ComponentRef, Integer>> outOrder;
algorithm outOrder := matchcontinue(inDlow, syst)
  local
    BackendDAE.Variables dovars;
    BackendDAE.EquationArray deqns;
    list<BackendDAE.Equation> eqns;
    list<BackendDAE.Var> vars;
    list<DAE.Exp> derExps;
    list<tuple<DAE.ComponentRef, Integer>> variableIndex;
    list<list<DAE.ComponentRef>> firstOrderVars;
    list<DAE.ComponentRef> firstOrderVarsFiltered;
  case(_, _)
    equation
      if Flags.isSet(Flags.FAILTRACE) then
        print(" set variabale der index"+ "\n");
      end if;
      dovars = BackendVariable.daeVars(syst);
      deqns = BackendEquation.getEqnsFromEqSystem(syst);
      vars = BackendVariable.varList(dovars);
      eqns = BackendEquation.equationList(deqns);
      derExps = makeCallDerExp(vars);
      if Flags.isSet(Flags.FAILTRACE) then
        print(" possible der exp: " + stringDelimitList(List.map(derExps, ExpressionDump.printExpStr), ", ") + "\n");
      end if;
      eqns = flattenEqns(eqns, inDlow);
     // eq_str=dumpEqLst(eqns);
      // fcall(Flags.FAILTRACE, print, "filtered eq's " + eq_str + "\n");
      (variableIndex, firstOrderVars) = List.map2_2(derExps, locateDerAndSerachOtherSide, eqns, eqns);
      if Flags.isSet(Flags.FAILTRACE) then
        print("united variables \n");
      end if;
      firstOrderVarsFiltered = List.fold(firstOrderVars, List.union, {});
      if Flags.isSet(Flags.FAILTRACE) then
        print("list fold variables \n");
      end if;
      variableIndex = setFirstOrderInSecondOrderVarIndex(variableIndex, firstOrderVarsFiltered);
     // fcall(Flags.FAILTRACE, print, "Deriving Variable indexis:\n" + dumpVariableindex(variableIndex) + "\n");
     then
      variableIndex;
  else
      equation
         print(" Failure in setVariableDerIndex2 \n");
         then fail();
 end matchcontinue;
end setVariableDerIndex2;




protected function flattenEqns "
This function flattens all equations
"
input list<BackendDAE.Equation> eqns;
input BackendDAE.BackendDAE dlow;
output list<BackendDAE.Equation> oeqns;
algorithm oeqns := matchcontinue(eqns, dlow)
  local
    BackendDAE.Equation eq;
    list<BackendDAE.Equation> rest, rec;
    String str;
  case({}, _) then {};
    case( (eq as BackendDAE.EQUATION()) ::rest , _)
    equation
      rec = flattenEqns(rest, dlow);
      rec = List.unionElt(eq, rec);
      then
        rec;
     case( (eq as BackendDAE.WHEN_EQUATION()) ::rest , _)
     equation
       str = BackendDump.equationString(eq);
       if Flags.isSet(Flags.FAILTRACE) then
         print("Found When eq " + str + "\n");
        end if;
       rec = flattenEqns(rest, dlow);
       // rec = List.unionElt(eq, rec);
      then
        rec;
     case( (eq as BackendDAE.ALGORITHM()) ::rest , _)
     equation
       // str = DAELow.equationStr(eq);
       rec = flattenEqns(rest, dlow);
       rec = List.unionElt(eq, rec);
      then
        rec;
     case( (eq as BackendDAE.ARRAY_EQUATION()) ::rest , _)
     equation
       // str = DAELow.equationStr(eq);
       rec = flattenEqns(rest, dlow);
       rec = List.unionElt(eq, rec);
      then
        rec;
     case( (eq as BackendDAE.COMPLEX_EQUATION()) ::rest , _)
     equation
       // str = DAELow.equationStr(eq);
       rec = flattenEqns(rest, dlow);
       rec = List.unionElt(eq, rec);
      then
        rec;
  case(_::_, _)
    equation
     // str = BackendDAE.equationStr(eq);
      true = Flags.isSet(Flags.FAILTRACE);
      print(" FAILURE IN flattenEqns possible unsupported equation...\n" /*+ str*/);
    then
      fail();
   end matchcontinue;
end flattenEqns;

protected function makeCallDerExp "
Author bz 2008-06
For all state-variables, generate an der(var) expression.
"
  input list<BackendDAE.Var> inVars;
  output list<DAE.Exp> outDerExps;
algorithm outDerExps := matchcontinue(inVars)
  local
    BackendDAE.Var v;
    list<BackendDAE.Var> vars;
    list<DAE.Exp> rec;
    DAE.ComponentRef cr;
  case({}) then {};
  case((BackendDAE.VAR(varKind = BackendDAE.STATE(), varName = cr))::vars)
    equation
      // true = DAELow.isStateVar(v);
      rec = makeCallDerExp(vars);
    then
      DAE.CALL(Absyn.IDENT("der"), {DAE.CREF(cr, DAE.T_REAL_DEFAULT)}, DAE.callAttrBuiltinReal)::rec;
  // case((v as DAELow.VAR(varKind = DAELow.DUMMY_STATE(), varName = cr))::vars)
   // equation
      // true = DAELow.isStateVar(v);
   // rec = makeCallDerExp(vars);
   // then
    // DAE.CALL(Absyn.IDENT("der"), {DAE.CREF(cr, DAE.T_UNKNOWN_DEFAULT)}, false, false, DAE.T_UNKNOWN_DEFAULT, DAE.NO_INLINE())::rec;
  case(_::vars)
    equation
      rec = makeCallDerExp(vars);
    then
      rec;
end matchcontinue;
end makeCallDerExp;

protected function locateDerAndSerachOtherSide "
Author bz 2008-06
helper function for setVariableDerIndex, locates the equation(/s) containing the current derivate.
From there search for the variable beeing derived, exclude 'current equation'
"
  input DAE.Exp derExp;
  input list<BackendDAE.Equation> inEqns;
  input list<BackendDAE.Equation> inEqnsOrg;
  output tuple<DAE.ComponentRef, Integer> out;
  output list<DAE.ComponentRef> sysOrdOneVars;
algorithm (out, sysOrdOneVars) := matchcontinue(derExp, inEqns, inEqnsOrg)
  local
    DAE.Exp e1, e2, deriveVar;
    list<BackendDAE.Equation> eqs, eqsOrg;
    BackendDAE.Equation eq;
    list<DAE.ComponentRef> crefs;
    DAE.ComponentRef cr;
    Integer rec, i1;
    tuple<DAE.ComponentRef, Integer> highestIndex;

  case( (DAE.CALL( expLst = {DAE.CREF(cr, _)})), {}, _) then ((cr, 0), {});
  case( (DAE.CALL( expLst = {deriveVar as DAE.CREF(cr, _)})), (eq as BackendDAE.EQUATION(exp=e1, scalar=e2))::eqs, _)
    equation
      true = Expression.expEqual(e1, derExp);
      eqsOrg = List.removeOnTrue(eq, valueEq, inEqnsOrg);
      if Flags.isSet(Flags.FAILTRACE) then
        print("\nFound equation containing " + ExpressionDump.printExpStr(derExp) + " Other side: " + ExpressionDump.printExpStr(e2) + ", extracted crefs: " + ExpressionDump.printExpStr(deriveVar) + "\n");
      end if;
      (rec, crefs) = locateDerAndSerachOtherSide2(DAE.CALL(Absyn.IDENT("der"), {e2}, DAE.callAttrBuiltinReal), eqsOrg);
      (highestIndex as (_, i1), _) = locateDerAndSerachOtherSide(derExp, eqs, eqsOrg);
      rec = rec+1;
      highestIndex = if i1>rec then highestIndex else (cr, rec-1);
      // highestIndex = (cr, 1);
    then
      (highestIndex, crefs);
  case( (DAE.CALL( expLst = {deriveVar as DAE.CREF(cr, _)})), (eq as BackendDAE.EQUATION(exp=e1, scalar=e2))::eqs, _)
    equation
      true = Expression.expEqual(e2, derExp);
      eqsOrg = List.removeOnTrue(eq, valueEq, inEqnsOrg);
      if Flags.isSet(Flags.FAILTRACE) then
        print("\nFound equation containing " + ExpressionDump.printExpStr(derExp) + " Other side: " + ExpressionDump.printExpStr(e1) + ", extracted crefs: " + ExpressionDump.printExpStr(deriveVar) + "\n");
      end if;
      (rec, crefs) = locateDerAndSerachOtherSide2(DAE.CALL(Absyn.IDENT("der"), {e1}, DAE.callAttrBuiltinReal), eqsOrg);
      (highestIndex as (_, i1), _) = locateDerAndSerachOtherSide(derExp, eqs, eqsOrg);
      rec = rec+1;
      highestIndex = if i1>rec then highestIndex else (cr, rec-1);
      // highestIndex = (cr, 1);
    then
      (highestIndex, crefs);
  case(_, (BackendDAE.EQUATION(exp=e1, scalar=e2))::eqs, _)
    equation
      false = Expression.expEqual(e1, derExp);
      false = Expression.expEqual(e2, derExp);
      (highestIndex, crefs) = locateDerAndSerachOtherSide(derExp, eqs, inEqnsOrg);
    then
      (highestIndex, crefs);
  case(_, (BackendDAE.ARRAY_EQUATION(left=e1, right=e2))::eqs, _)
    equation
      false = Expression.expEqual(e1, derExp);
      false = Expression.expEqual(e2, derExp);
      (highestIndex, crefs) = locateDerAndSerachOtherSide(derExp, eqs, inEqnsOrg);
    then
      (highestIndex, crefs);
  case(_, (BackendDAE.COMPLEX_EQUATION(left=e1, right=e2))::eqs, _)
    equation
      false = Expression.expEqual(e1, derExp);
      false = Expression.expEqual(e2, derExp);
      (highestIndex, crefs) = locateDerAndSerachOtherSide(derExp, eqs, inEqnsOrg);
    then
      (highestIndex, crefs);
  case(_, (BackendDAE.IF_EQUATION())::eqs, _)
    equation
      if Flags.isSet(Flags.FAILTRACE) then
        print("\nFound  if equation is not supported yet  searching for varibale index  \n");
      end if;
      (highestIndex, crefs) = locateDerAndSerachOtherSide(derExp, eqs, inEqnsOrg);
    then
      (highestIndex, crefs);
 case(_, (BackendDAE.ALGORITHM())::eqs, _)
    equation
      if Flags.isSet(Flags.FAILTRACE) then
        print("\nFound  algorithm is not supported yet  searching for varibale index  \n");
      end if;
      (highestIndex, crefs) = locateDerAndSerachOtherSide(derExp, eqs, inEqnsOrg);
    then
      (highestIndex, crefs);

end matchcontinue;
end locateDerAndSerachOtherSide;

protected function locateDerAndSerachOtherSide2 "
Author bz 2008-06
helper function for locateDerAndSerachOtherSide"
  input DAE.Exp inDer;
  input list<BackendDAE.Equation> inEqns;
  output Integer oi;
  output list<DAE.ComponentRef> firstOrderDers;
algorithm (oi, firstOrderDers) := matchcontinue(inDer, inEqns)
  case(DAE.CALL(expLst = {DAE.CREF(_, _)}), _)
    equation
      (oi, firstOrderDers) = locateDerAndSerachOtherSide22(inDer, inEqns);
    then
      (oi, firstOrderDers);
  else (0, {});
end matchcontinue;
  end locateDerAndSerachOtherSide2;

protected function locateDerAndSerachOtherSide22 "
Author bz 2008-06
recursivly search equations for der(..) expressions.
When found, return 1... this since we are only interested in second order system, at most.
If we do not find any more derivative, 0 is returned.
"
  input DAE.Exp inDer;
  input list<BackendDAE.Equation> inEqns;
  output Integer oi;
  output list<DAE.ComponentRef> firstOrderDers;
algorithm (oi, firstOrderDers) := matchcontinue(inDer, inEqns)
  local
    DAE.Exp e1, e2;
    DAE.ComponentRef cr;
    list<BackendDAE.Equation> rest;
  case(_, {}) then (0, {});
  case(_, (BackendDAE.EQUATION(exp=e1, scalar=e2)::_))
    equation
      true = Expression.expEqual(inDer, e1);
      {cr} = Expression.extractCrefsFromExp(e1);
      if Flags.isSet(Flags.FAILTRACE) then
        BackendDump.debugStrExpStrExpStrExpStr(" found derivative for ", inDer, " in equation ", e1, " = ", e2, "\n");
      end if;
    then
      (1, {cr});
  case(_, (BackendDAE.EQUATION(exp=e1, scalar=e2)::_))
    equation
      true = Expression.expEqual(inDer, e2);
      {cr} = Expression.extractCrefsFromExp(e2);
      if Flags.isSet(Flags.FAILTRACE) then
        BackendDump.debugStrExpStrExpStrExpStr(" found derivative for ", inDer, " in equation ", e1, " = ", e2, "\n");
      end if;
    then
      (1, {cr});
  case(_, (BackendDAE.EQUATION(exp=e1, scalar=e2)::rest))
    equation
      if Flags.isSet(Flags.FAILTRACE) then
        BackendDump.debugExpStrExpStrExpStr(inDer, " NOT contained in ", e1, " = ", e2, "\n");
      end if;
      (oi, firstOrderDers) = locateDerAndSerachOtherSide22(inDer, rest);
    then
      (oi, firstOrderDers);
end matchcontinue;
end locateDerAndSerachOtherSide22;

protected function setFirstOrderInSecondOrderVarIndex "
Author bz 2008-06
"
  input list<tuple<DAE.ComponentRef, Integer>> inRefs;
  input list<DAE.ComponentRef> firstOrderInSec;
  output list<tuple<DAE.ComponentRef, Integer>> outRefs;
algorithm (outRefs) := matchcontinue(inRefs, firstOrderInSec)
  local
    list<tuple<DAE.ComponentRef, Integer>> rest;
    Integer idx;
    DAE.ComponentRef cr;

  case({}, _) then {};
  case((cr, _)::rest, _)
    equation
      true = List.map1BoolOr(firstOrderInSec, ComponentReference.crefEqual, cr);
      rest = setFirstOrderInSecondOrderVarIndex(rest, firstOrderInSec);
    then
      (cr, 2)::rest;
  case((cr, 1)::rest, _)
    equation
      rest = setFirstOrderInSecondOrderVarIndex(rest, firstOrderInSec);
    then
      (cr, 1)::rest;
  case((cr, idx)::rest, _)
    equation
      rest = setFirstOrderInSecondOrderVarIndex(rest, firstOrderInSec);
    then
      (cr, idx)::rest;
end matchcontinue;
end setFirstOrderInSecondOrderVarIndex;

/********* for dimension *******/

protected function calculateVariableDimensions "
Calcuates the dimension of the statevaribale with order 0, 1, 2
"
   input list<tuple<DAE.ComponentRef, Integer>> in_vars;
   input Integer inNvar1;
   input Integer inNvar2;
   output Integer OutInteger1; // number of ordinary differential equations of 1st order
   output Integer OutInteger2; // number of ordinary differential equations of 2st order

algorithm (OutInteger1, OutInteger2) := match(in_vars)
  local
    list<tuple<DAE.ComponentRef, Integer>> rest;
  case({}) then (inNvar1, inNvar2);
  case((_, 0)::rest)
    then
      calculateVariableDimensions(rest,inNvar1+1,inNvar2);
  case((_, _)::rest)
    then
      calculateVariableDimensions(rest,inNvar1,inNvar2+1);
end match;
end calculateVariableDimensions;

/********************/
protected function dimensions

input BackendDAE.BackendDAE dae_low;
output Integer OutInteger1; // number of ordinary differential equations of 1st order
output Integer OutInteger2; // number of ordinary differential equations of 2st order
algorithm (OutInteger1, OutInteger2):= matchcontinue(dae_low)
  local
    Integer nvar1, nvar2;
    list<tuple<DAE.ComponentRef, Integer>> ordered_states;
    BackendDAE.EqSystems eqsystems;
  case(BackendDAE.DAE(eqs=eqsystems))
    equation
       ordered_states=setVariableDerIndex(dae_low, eqsystems);
      (nvar1, nvar2)=calculateVariableDimensions(ordered_states,0,0);
      then
        (nvar1, nvar2);
  else
    equation print(" failure in dimensions  \n"); then fail();
end matchcontinue;
end dimensions;

/******************/
/******************/

protected function compareSimVarName
  input SimCodeVar.SimVar var1;
  input SimCodeVar.SimVar var2;
  output Boolean result;
protected
  DAE.ComponentRef name1, name2;
algorithm
  SimCodeVar.SIMVAR(name = name1) := var1;
  SimCodeVar.SIMVAR(name = name2) := var2;
  result := ComponentReference.crefEqual(name1, name2);
end compareSimVarName;

public function compareVarIndexGt
  input SimCodeVar.SimVar var1;
  input SimCodeVar.SimVar var2;
  output Boolean result;
protected
  Integer index1, index2;
algorithm
  SimCodeVar.SIMVAR(variable_index=SOME(index1)) := var1;
  SimCodeVar.SIMVAR(variable_index=SOME(index2)) := var2;
  result := index1 > index2;
end compareVarIndexGt;

public function compareSimVarTupleIndexGt<anyT>
  input tuple<SimCodeVar.SimVar, anyT> var1;
  input tuple<SimCodeVar.SimVar, anyT> var2;
  output Boolean result;
protected
  Integer index1, index2;
algorithm
  (SimCodeVar.SIMVAR(variable_index=SOME(index1)),_) := var1;
  (SimCodeVar.SIMVAR(variable_index=SOME(index2)),_) := var2;
  result := index1 > index2;
end compareSimVarTupleIndexGt;

public function countDynamicExternalFunctions
  input list<SimCodeFunction.Function> inFncLst;
  output Integer outDynLoadFuncs;
algorithm
  outDynLoadFuncs:= matchcontinue(inFncLst)
  local
     list<SimCodeFunction.Function> rest;
     SimCodeFunction.Function fn;
     Integer i;
  case({})
     then
       0;
  case(SimCodeFunction.EXTERNAL_FUNCTION(dynamicLoad=true)::rest)
     equation
      i = countDynamicExternalFunctions(rest);
    then
      intAdd(i, 1);
  case(_::rest)
    equation
      i = countDynamicExternalFunctions(rest);
    then
      i;
end matchcontinue;
end countDynamicExternalFunctions;

protected function getFilesFromSimVar
  input output SimCodeVar.SimVar var;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := getFilesFromDAEElementSource(var.source, inFiles);
end getFilesFromSimVar;

protected function getFilesFromSimVars
  input SimCodeVar.SimVars inSimVars;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inSimVars, inFiles)
    local
      SimCode.Files files;
      list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars,
                   boolAliasVars, paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars,
                   extObjVars, constVars, intConstVars, boolConstVars, stringConstVars, jacobianVars, seedVars, realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars, sensitivityVars;

    case (SimCodeVar.SIMVARS(stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars,
                  paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars, jacobianVars, seedVars, realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars, sensitivityVars),
          files)
      equation
        (_, files) = List.mapFoldList(
                       {stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars,
                        paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars, jacobianVars, seedVars, realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars, sensitivityVars},
                       getFilesFromSimVar, files);
      then
        files;
  end match;
end getFilesFromSimVars;

protected function getFilesFromFunctions
  input list<SimCodeFunction.Function> functions;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(functions, inFiles)
    local
      SimCode.Files files;
      list<SimCodeFunction.Function> rest;
      SourceInfo info;

    // handle empty
    case ({}, files) then files;

    // handle FUNCTION
    case (SimCodeFunction.FUNCTION(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);
      then
        files;

    // handle EXTERNAL_FUNCTION
    case (SimCodeFunction.EXTERNAL_FUNCTION(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);
      then
        files;

    // handle RECORD_CONSTRUCTOR
    case (SimCodeFunction.RECORD_CONSTRUCTOR(info = info)::rest, files)
      equation
        files = getFilesFromAbsynInfo(info, files);
        files = getFilesFromFunctions(rest, files);
      then
        files;
  end match;
end getFilesFromFunctions;

protected function getFilesFromSimEqSystemOpt
  input Option<SimCode.SimEqSystem> inSimEqSystemOpt;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inSimEqSystemOpt, inFiles)
    local
      SimCode.Files files;
      SimCode.SimEqSystem sys;

    case (NONE(), files) then files;
    case (SOME(sys), files)
      equation
        (_, files) = getFilesFromSimEqSystem(sys, files);
      then
        files;
  end match;
end getFilesFromSimEqSystemOpt;

protected function getFilesFromSimEqSystem
  input SimCode.SimEqSystem inSimEqSystem;
  input SimCode.Files inFiles;
  output SimCode.SimEqSystem outSimEqSystem;
  output SimCode.Files outFiles;
algorithm
  (outSimEqSystem, outFiles) := match(inSimEqSystem, inFiles)
    local
      SimCode.Files files;
      DAE.ElementSource source;
      list<DAE.Statement> statements;
      list<SimCodeVar.SimVar> vars;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      list<SimCode.SimEqSystem> systems;
      SimCode.SimEqSystem system;
      Option<SimCode.SimEqSystem> systemOpt;
      list<BackendDAE.WhenOperator> whenStmtLst;

    case (SimCode.SES_RESIDUAL(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_SIMPLE_ASSIGN(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_ARRAY_CALL_ASSIGN(source = source), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_ALGORITHM(statements=statements), files)
      equation
        files = getFilesFromStatements(statements, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_INVERSE_ALGORITHM(statements=statements), files)
      equation
        files = getFilesFromStatements(statements, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(vars = vars, simJac = simJac)), files)
      equation
        (_, files) = List.mapFold(vars, getFilesFromSimVar, files);
        systems = List.map(simJac, Util.tuple33);
        files = getFilesFromSimEqSystems({systems}, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(eqs = systems)), files)
      equation
        files = getFilesFromSimEqSystems({systems}, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_MIXED(cont = system, discVars = vars, discEqs = systems), files)
      equation
        (_, files) = List.mapFold(vars, getFilesFromSimVar, files);
        files = getFilesFromSimEqSystems({system::systems}, files);
      then
        (inSimEqSystem, files);

    case (SimCode.SES_WHEN(source = source, whenStmtLst = whenStmtLst, elseWhen = systemOpt), files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromWhenOperators(whenStmtLst, files);
        files = getFilesFromSimEqSystemOpt(systemOpt, files);
      then
        (inSimEqSystem, files);

  end match;
end getFilesFromSimEqSystem;

protected function getFilesFromSimEqSystems
  input list<list<SimCode.SimEqSystem>> inSimEqSystems;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  (_, outFiles) := List.mapFoldList(inSimEqSystems, getFilesFromSimEqSystem, inFiles);
end getFilesFromSimEqSystems;

protected function getFilesFromStatementsElse
  input DAE.Else inElse;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inElse, inFiles)
    local
      SimCode.Files files;
      list<DAE.Statement> rest, stmts;
      DAE.Else elsePart;

    case (DAE.NOELSE(), files) then files;

    case (DAE.ELSEIF(statementLst = stmts, else_ = elsePart), files)
      equation
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatementsElse(elsePart, files);
      then
        files;

    case (DAE.ELSE(statementLst = stmts), files)
      equation
        files = getFilesFromStatements(stmts, files);
      then
        files;
  end match;
end getFilesFromStatementsElse;

protected function getFilesFromStatementsElseWhen
  input Option<DAE.Statement> inStatementOpt;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inStatementOpt, inFiles)
    local
      SimCode.Files files;
      DAE.Statement stmt;

    case (NONE(), files) then files;
    case (SOME(stmt), files) then getFilesFromStatements({stmt}, files);
  end match;
end getFilesFromStatementsElseWhen;

protected function getFilesFromStatements
  input list<DAE.Statement> inStatements;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inStatements, inFiles)
    local
      SimCode.Files files;
      DAE.ElementSource source;
      list<DAE.Statement> rest, stmts;
      DAE.Else elsePart;
      Option<DAE.Statement> elseWhen;

    // handle empty
    case ({}, files) then files;

    case (DAE.STMT_ASSIGN(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_TUPLE_ASSIGN(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_ASSIGN_ARR(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_IF(source = source, statementLst = stmts, else_ = elsePart)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatementsElse(elsePart, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_FOR(source = source, statementLst = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_PARFOR(source = source, statementLst = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_WHILE(source = source, statementLst = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_WHEN(source = source, statementLst = stmts, elseWhen = elseWhen)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatementsElseWhen(elseWhen, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_ASSERT(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_TERMINATE(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_REINIT(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_NORETCALL(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_RETURN(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_BREAK(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

    case (DAE.STMT_FAILURE(source = source, body = stmts)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromStatements(stmts, files);
        files = getFilesFromStatements(rest, files);
      then
        files;

  end match;
end getFilesFromStatements;

protected function getFilesFromWhenOperators
  input list<BackendDAE.WhenOperator> inWhenOperators;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inWhenOperators, inFiles)
    local
      SimCode.Files files;
      DAE.ElementSource source;
      list<BackendDAE.WhenOperator> rest;

    // handle empty
    case ({}, files) then files;

    case (BackendDAE.ASSIGN(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromWhenOperators(rest, files);
      then
        files;

    case (BackendDAE.REINIT(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromWhenOperators(rest, files);
      then
        files;

    case (BackendDAE.ASSERT(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromWhenOperators(rest, files);
      then
        files;

    case (BackendDAE.TERMINATE(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromWhenOperators(rest, files);
      then
        files;

    case (BackendDAE.NORETCALL(source = source)::rest, files)
      equation
        files = getFilesFromDAEElementSource(source, files);
        files = getFilesFromWhenOperators(rest, files);
      then
        files;

  end match;
end getFilesFromWhenOperators;

protected function getFilesFromExtObjInfo
  input SimCode.ExtObjInfo inExtObjInfo;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  (_, outFiles) := List.mapFold(inExtObjInfo.vars, getFilesFromSimVar, inFiles);
end getFilesFromExtObjInfo;

protected function getFilesFromJacobianMatrixes
  input list<SimCode.JacobianMatrix> inJacobianMatrixes;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inJacobianMatrixes, inFiles)
    local
      SimCode.Files files;
      list<SimCode.JacobianMatrix> rest;
      list<SimCode.JacobianColumn> onemat;
      list<SimCode.SimEqSystem> systems;
      list<SimCodeVar.SimVar> vars;

    // handle empty
    case ({}, files) then files;

    // handle rest
    case (SimCode.JAC_MATRIX(columns=onemat)::rest, files)
      equation
        files = getFilesFromJacobianMatrix(onemat, files);
        files = getFilesFromJacobianMatrixes(rest, files);
      then
        files;

  end match;
end getFilesFromJacobianMatrixes;

protected function getFilesFromJacobianMatrix
  input list<SimCode.JacobianColumn> inJacobianMatrixes;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := match(inJacobianMatrixes, inFiles)
    local
      SimCode.Files files;
      list<SimCode.JacobianColumn> rest;
      list<SimCode.SimEqSystem> systems;
      list<SimCodeVar.SimVar> vars;

    // handle empty
    case ({}, files) then files;

    // handle rest
    case (SimCode.JAC_COLUMN(columnEqns=systems, columnVars=vars)::rest, files)
      equation
        files = getFilesFromSimEqSystems({systems}, files);
        (_, files) = List.mapFold(vars, getFilesFromSimVar, files);
        files = getFilesFromJacobianMatrix(rest, files);
      then
        files;

  end match;
end getFilesFromJacobianMatrix;

protected function collectAllFiles
  input SimCode.SimCode inSimCode;
  output SimCode.SimCode outSimCode = inSimCode;
protected
  SimCode.ModelInfo modelInfo;
  SimCode.Files files = {} "all the files from SourceInfo and DAE.ELementSource";
algorithm
  if not Config.acceptMetaModelicaGrammar() then
    modelInfo := outSimCode.modelInfo;
    files := getFilesFromSimVars(modelInfo.vars, files);
    files := getFilesFromFunctions(modelInfo.functions, files);
    files := getFilesFromSimEqSystems( outSimCode.allEquations :: outSimCode.startValueEquations :: outSimCode.nominalValueEquations
                                       :: outSimCode.minValueEquations :: outSimCode.maxValueEquations :: outSimCode.parameterEquations
                                       :: outSimCode.removedEquations :: outSimCode.algorithmAndEquationAsserts
                                       :: outSimCode.odeEquations, files );
    files := getFilesFromSimEqSystems(outSimCode.algebraicEquations, files);
    files := getFilesFromExtObjInfo(outSimCode.extObjInfo, files);
    files := getFilesFromJacobianMatrixes(outSimCode.jacobianMatrixes, files);
    files := List.sort(files, greaterFileInfo);
    outSimCode.modelInfo := modelInfo;
  end if;
end collectAllFiles;

protected function getFilesFromDAEElementSource
  input DAE.ElementSource inSource;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
algorithm
  outFiles := getFilesFromAbsynInfo(inSource.info, inFiles);
end getFilesFromDAEElementSource;

protected function getFilesFromAbsynInfo
  input SourceInfo inInfo;
  input SimCode.Files inFiles;
  output SimCode.Files outFiles;
protected
  SimCode.FileInfo fi;
algorithm
  fi := SimCode.FILEINFO(inInfo.fileName, inInfo.isReadOnly);
  // add it only if is not already there!
  outFiles := List.consOnTrue(not listMember(fi, inFiles), fi, inFiles);
end getFilesFromAbsynInfo;

protected function equalFileInfo
"compare to SimCode.FileInfo and return true if the filenames are equal, isReadOnly is ignored here"
  input SimCode.FileInfo inFileInfo1;
  input SimCode.FileInfo inFileInfo2;
  output Boolean isMatch;
protected
  String f1, f2;
algorithm
  SimCode.FILEINFO(f1, _) := inFileInfo1;
  SimCode.FILEINFO(f2, _) := inFileInfo2;
  isMatch := stringEq(f1, f2);
end equalFileInfo;

protected function greaterFileInfo
"compare to SimCode.FileInfo and returns true if the fileName1 is greater than fileName2, isReadOnly is ignored here"
  input SimCode.FileInfo inFileInfo1;
  input SimCode.FileInfo inFileInfo2;
  output Boolean isGreater;
protected
  String f1, f2;
  Integer compare;
algorithm
  SimCode.FILEINFO(f1, _) := inFileInfo1;
  SimCode.FILEINFO(f2, _) := inFileInfo2;
  compare := stringCompare(f1, f2);
  isGreater := intGt(compare, 0);
end greaterFileInfo;

protected function getFileIndexFromFiles
"fetch the index in the list of files"
  input String file;
  input SimCode.Files files;
  output Integer index;
algorithm
  index := List.position1OnTrue(files, equalFileInfo, SimCode.FILEINFO(file, false))-1 "shift to zero-based index";
end getFileIndexFromFiles;

public function fileName2fileIndex
"Used by templates to find a fileIndex for given fileName"
  input String inFileName;
  input SimCode.Files inFiles;
  output Integer outFileIndex;
algorithm
  outFileIndex := matchcontinue(inFileName, inFiles)
    local
      String errstr;
      String file;
      SimCode.Files files;
      Integer index;

    case (file, files)
      equation
        index = getFileIndexFromFiles(file, files);
      then
        index;

    else
      equation
        // errstr = "Template did not find the file: "+ file + " in the SimCode.modelInfo.files.";
        // Error.addInternalError(errstr, sourceInfo());
      then
        -1;
  end matchcontinue;
end fileName2fileIndex;

protected function makeEqualLengthLists
  "Greedy algorithm for scheduling. Very simple:
  Calculate the weight of each eq.system, sort these s.t.
  the most expensive system is treated first. Add
  this eq.system to the block with the least cost at the moment.
  "
  input list<list<SimCode.SimEqSystem>> inLst;
  input Integer i;
  output list<list<SimCode.SimEqSystem>> olst;
algorithm
  olst := matchcontinue (inLst, i)
    local
      list<SimCode.SimEqSystem> l;
      PriorityQueue.T q;
      list<tuple<Integer, list<SimCode.SimEqSystem>>> prios;
      list<list<SimCode.SimEqSystem>> lst;
      String eq_str;

    case (lst, _)
      equation
        false = Flags.isSet(Flags.PTHREADS);
        l = List.flatten(lst);
      then l::{};
    case (lst, 0) then lst;
    case (lst, 1)
      equation
        l = List.flatten(lst);
        /* eq_str = Tpl.tplString2(SimCodeDump.dumpEqsSys, l, false);
        print(eq_str); */
      then l::{};
    case (lst, _)
      equation
        q = List.fold(List.fill((0, {}), i), PriorityQueue.insert, PriorityQueue.empty);
        prios = List.map(lst, calcPriority);
        q = List.fold(prios, makeEqualLengthLists2, q);
        lst = List.map(PriorityQueue.elements(q), Util.tuple22);
      then lst;
  end matchcontinue;
end makeEqualLengthLists;

protected function makeEqualLengthLists2
  input tuple<Integer, list<SimCode.SimEqSystem>> elt;
  input PriorityQueue.T iq;
  output PriorityQueue.T oq;
algorithm
  oq := match (elt, iq)
    local
      list<SimCode.SimEqSystem> l1, l2;
      Integer i1, i2;
      PriorityQueue.T q;

    case ((i1, l1), q)
      equation
        // print("priorities before: " + stringDelimitList(List.mapMap(PriorityQueue.elements(q), Util.tuple21, intString), ", ") + "\n");
        (q, (i2, l2)) = PriorityQueue.deleteAndReturnMin(q);
        // print("priorities (popped): " + stringDelimitList(List.mapMap(PriorityQueue.elements(q), Util.tuple21, intString), ", ") + "\n");
        q = PriorityQueue.insert((i1+i2, listAppend(l2, l1)), q);
        // print("priorities after (i1=" + intString(i1) + "): " + stringDelimitList(List.mapMap(PriorityQueue.elements(q), Util.tuple21, intString), ", ") + "\n");
      then q;
  end match;
end makeEqualLengthLists2;

protected function calcPriority
  input list<SimCode.SimEqSystem> eqs;
  output tuple<Integer, list<SimCode.SimEqSystem>> prio;
protected
  Integer i;
algorithm
  (_, i) := traverseExpsEqSystems(eqs, Expression.complexityTraverse, 1 /* Each system has cost 1 even if it's as simple as der(x)=1.0 */, {});
  prio := (i, eqs);
end calcPriority;

protected function traveseSimVars
  input SimCodeVar.SimVars inSimVars;
  input Func func;
  input tpl iTpl;
  output SimCodeVar.SimVars outSimVars;
  output tpl oTpl;
  replaceable type tpl subtypeof Any;
  partial function Func
    input tuple<SimCodeVar.SimVar, tpl> tpl;
    output tuple<SimCodeVar.SimVar, tpl> otpl;
  end Func;
algorithm
  (outSimVars, oTpl) := match(inSimVars, func, iTpl)
    local
     list<SimCodeVar.SimVar> stateVars, derivativeVars, algVars, discreteAlgVars,
                   intAlgVars, boolAlgVars, stringAlgVars, inputVars, outputVars,
                   aliasVars, intAliasVars, boolAliasVars, stringAliasVars,
                   paramVars, intParamVars, boolParamVars, stringParamVars,
                   constVars, intConstVars, boolConstVars, stringConstVars,
                   sensitivityVars, extObjVars, jacobianVars, seedVars,
                   realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars,setcVars;
     tpl intpl;

    case (SimCodeVar.SIMVARS(stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars,
                  paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars, jacobianVars, seedVars, realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars, sensitivityVars,setcVars), _, intpl)
         equation
           (stateVars, intpl) = List.mapFoldTuple(stateVars, func, intpl);
           (derivativeVars, intpl) = List.mapFoldTuple(derivativeVars, func, intpl);
           (algVars, intpl) = List.mapFoldTuple(algVars, func, intpl);
           (discreteAlgVars, intpl) = List.mapFoldTuple(discreteAlgVars, func, intpl);
           (intAlgVars, intpl) = List.mapFoldTuple(intAlgVars, func, intpl);
           (boolAlgVars, intpl) = List.mapFoldTuple(boolAlgVars, func, intpl);
           (outputVars, intpl) = List.mapFoldTuple(outputVars, func, intpl);
           (aliasVars, intpl) = List.mapFoldTuple(aliasVars, func, intpl);
           (intAliasVars, intpl) = List.mapFoldTuple(intAliasVars, func, intpl);
           (boolAliasVars, intpl) = List.mapFoldTuple(boolAliasVars, func, intpl);
           (paramVars, intpl) = List.mapFoldTuple(intParamVars, func, intpl);
           (intParamVars, intpl) = List.mapFoldTuple(paramVars, func, intpl);
           (boolParamVars, intpl) = List.mapFoldTuple(boolParamVars, func, intpl);
           (stringAlgVars, intpl) = List.mapFoldTuple(stateVars, func, intpl);
           (stateVars, intpl) = List.mapFoldTuple(stringAlgVars, func, intpl);
           (stringParamVars, intpl) = List.mapFoldTuple(stringParamVars, func, intpl);
           (stringAliasVars, intpl) = List.mapFoldTuple(stringAliasVars, func, intpl);
           (extObjVars, intpl) = List.mapFoldTuple(extObjVars, func, intpl);
           (intConstVars, intpl) = List.mapFoldTuple(intConstVars, func, intpl);
           (boolConstVars, intpl) = List.mapFoldTuple(boolConstVars, func, intpl);
           (stringConstVars, intpl) = List.mapFoldTuple(stringConstVars, func, intpl);
           (jacobianVars, intpl) = List.mapFoldTuple(jacobianVars, func, intpl);
           (seedVars, intpl) = List.mapFoldTuple(seedVars, func, intpl);
           (realOptimizeConstraintsVars, intpl) = List.mapFoldTuple(realOptimizeConstraintsVars, func, intpl);
           (realOptimizeFinalConstraintsVars, intpl) = List.mapFoldTuple(realOptimizeFinalConstraintsVars, func, intpl);
           (sensitivityVars, intpl) = List.mapFoldTuple(sensitivityVars, func, intpl);
           (setcVars, intpl) = List.mapFoldTuple(setcVars, func, intpl);


         then (SimCodeVar.SIMVARS(stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, inputVars, outputVars, aliasVars, intAliasVars, boolAliasVars,
                  paramVars, intParamVars, boolParamVars, stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars, stringConstVars, jacobianVars, seedVars, realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars, sensitivityVars,setcVars), intpl);
    case (_, _, _) then fail();
  end match;
end traveseSimVars;


public function traverseExpsSimCode
  input SimCode.SimCode simCode;
  input Func func;
  input A ia;
  output SimCode.SimCode outSimCode = simCode;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output A outA;
  end Func;
protected
  list<DAE.Exp> literals;
  list<SimCode.SimEqSystem> eqs;
  list<list<SimCode.SimEqSystem>> eqs1;
  list<SimCode.ClockedPartition> partitions;
algorithm
  (literals, oa) := List.mapFold(outSimCode.literals, func, ia);
  outSimCode.literals := literals;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.allEquations, func, oa, {});
  outSimCode.allEquations := eqs;
  (partitions, oa) := List.map1Fold(outSimCode.clockedPartitions, traverseExpsPartition, func, oa);
  outSimCode.clockedPartitions := partitions;
  (eqs1, oa) := traverseExpsEqSystemsList(outSimCode.odeEquations, func, oa, {});
  outSimCode.odeEquations := eqs1;
  (eqs1, oa) := traverseExpsEqSystemsList(outSimCode.algebraicEquations, func, oa, {});
  outSimCode.algebraicEquations := eqs1;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.initialEquations, func, oa, {});
  outSimCode.initialEquations := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.removedInitialEquations, func, oa, {});
  outSimCode.removedInitialEquations := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.startValueEquations, func, oa, {});
  outSimCode.startValueEquations := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.nominalValueEquations, func, oa, {});
  outSimCode.nominalValueEquations := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.minValueEquations, func, oa, {});
  outSimCode.minValueEquations := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.maxValueEquations, func, oa, {});
  outSimCode.maxValueEquations := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.parameterEquations, func, oa, {});
  outSimCode.parameterEquations := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.removedEquations, func, oa, {});
  outSimCode.removedEquations := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.algorithmAndEquationAsserts, func, oa, {});
  outSimCode.algorithmAndEquationAsserts := eqs;
  (eqs, oa) := traverseExpsEqSystems(outSimCode.jacobianEquations, func, oa, {});
  outSimCode.jacobianEquations := eqs;
  /* TODO:zeroCrossing */
  /* TODO:discreteModelVars */
  /* TODO:extObjInfo */
  /* TODO:delayedExps */
end traverseExpsSimCode;

protected function traverseExpsPartition
  input SimCode.ClockedPartition simPartition;
  input Func func;
  input A ia;
  output SimCode.ClockedPartition outSimPartition = simPartition;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output A outA;
  end Func;
protected
  DAE.ClockKind clk;
  list<SimCode.SubPartition> subPartitions;
algorithm
  (DAE.CLKCONST(clk), oa) := func(DAE.CLKCONST(simPartition.baseClock), ia);
  (subPartitions, oa) := List.map1Fold(simPartition.subPartitions, traverseExpsSubPartition, func, oa);
  outSimPartition.baseClock := clk;
  outSimPartition.subPartitions := subPartitions;
end traverseExpsPartition;

protected function traverseExpsSubPartition
  input SimCode.SubPartition subPartition;
  input Func func;
  input A ia;
  output SimCode.SubPartition outSubPartition = subPartition;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output A outA;
  end Func;
protected
  list<SimCode.SimEqSystem> eqs;
algorithm
  (eqs, oa) := traverseExpsEqSystems(subPartition.equations, func, ia, {});
  outSubPartition.equations := eqs;
  (eqs, oa) := traverseExpsEqSystems(subPartition.removedEquations, func, oa, {});
  outSubPartition.removedEquations := eqs;
end traverseExpsSubPartition;

protected function traverseExpsEqSystemsList
  input list<list<SimCode.SimEqSystem>> ieqs;
  input Func func;
  input A ia;
  input list<list<SimCode.SimEqSystem>> acc;
  output list<list<SimCode.SimEqSystem>> oeqs;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output A outA;
  end Func;
algorithm
  (oeqs, oa) := match (ieqs, func, ia, acc)
    local
      list<SimCode.SimEqSystem> eq;
      A a;
      list<list<SimCode.SimEqSystem>> eqs;

    case ({}, _, a, _) then (listReverse(acc), a);
    case (eq::eqs, _, a, _)
      equation
        (eq, a) = traverseExpsEqSystems(eq, func, a, {});
        (oeqs, a) = traverseExpsEqSystemsList(eqs, func, a, eq::acc);
      then (oeqs, a);
  end match;
end traverseExpsEqSystemsList;

protected function traverseExpsEqSystems
  input list<SimCode.SimEqSystem> ieqs;
  input Func func;
  input A ia;
  input list<SimCode.SimEqSystem> acc;
  output list<SimCode.SimEqSystem> oeqs;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output A outA;
  end Func;
algorithm
  (oeqs, oa) := match (ieqs, func, ia, acc)
    local
      SimCode.SimEqSystem eq;
      A a;
      list<SimCode.SimEqSystem> eqs;

    case ({}, _, a, _) then (listReverse(acc), a);
    case (eq::eqs, _, a, _)
      equation
        (eq, a) = traverseExpsEqSystem(eq, func, a);
        (oeqs, a) = traverseExpsEqSystems(eqs, func, a, eq::acc);
      then (oeqs, a);
  end match;
end traverseExpsEqSystems;

protected function traverseExpsEqSystem
  input SimCode.SimEqSystem eq;
  input Func func;
  input A ia;
  output SimCode.SimEqSystem oeq;
  output A oa;
  replaceable type A subtypeof Any;
  partial function Func
    input DAE.Exp inExp;
    input A inTypeA;
    output DAE.Exp outExp;
    output A outA;
  end Func;
algorithm
  (oeq, oa) := match (eq, func, ia)
    local
      A a;
      Boolean homotopySupport;
      Boolean initialCall;
      Boolean mixedSystem;
      Boolean partOfMixed;
      DAE.ComponentRef cr, left;
      DAE.ElementSource source;
      DAE.Exp exp, exp_, right, leftexp;
      SimCode.SimEqSystem eq_;
      Integer index, indexSys;
      Option<SimCode.JacobianMatrix> symJac;
      Option<SimCode.LinearSystem> alternativeTearingL;
      Option<SimCode.NonlinearSystem> alternativeTearingNl;
      Option<SimCode.SimEqSystem> elseWhen;
      SimCode.LinearSystem lSystem;
      SimCode.NonlinearSystem nlSystem;
      SimCode.SimEqSystem cont;
      list<DAE.ComponentRef> conditions;
      list<DAE.ComponentRef> crefs;
      list<DAE.ElementSource> sources;
      list<DAE.Exp> beqs;
      list<DAE.Statement> stmts;
      list<SimCode.SimEqSystem> discEqs, eqs;
      list<SimCode.SimEqSystem> elsebranch;
      list<SimCodeVar.SimVar> vars, discVars;
      list<tuple<DAE.Exp, list<SimCode.SimEqSystem>>> ifbranches;
      list<tuple<Integer, Integer, SimCode.SimEqSystem>> simJac;
      list<BackendDAE.WhenOperator> whenStmtLst;
      BackendDAE.Constraints cons;
      BackendDAE.EquationAttributes eqAttr;

    case (SimCode.SES_RESIDUAL(index, exp, source, eqAttr=eqAttr), _, a) equation
      (exp_, a) = func(exp, a);
      if referenceEq(exp,exp_) then
        eq_ = eq;
      else
        eq_ = SimCode.SES_RESIDUAL(index, exp_, source, eqAttr);
      end if;
    then (eq_, a);

    case (SimCode.SES_SIMPLE_ASSIGN(index, cr, exp, source, eqAttr=eqAttr), _, a) equation
      (exp_, a) = func(exp, a);
      if referenceEq(exp,exp_) then
        eq_ = eq;
      else
        eq_ = SimCode.SES_SIMPLE_ASSIGN(index, cr, exp_, source, eqAttr);
      end if;
    then (eq_, a);

    case (SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(index, cr, exp, source, cons, eqAttr=eqAttr), _, a) equation
      (exp_, a) = func(exp, a);
      if referenceEq(exp,exp_) then
        eq_ = eq;
      else
        eq_ = SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(index, cr, exp_, source, cons, eqAttr);
      end if;
    then (eq_, a);

    case (SimCode.SES_ARRAY_CALL_ASSIGN(index, leftexp, exp, source, eqAttr=eqAttr), _, a) equation
      (leftexp, a) = func(leftexp, a);
      (exp, a) = func(exp, a);
    then (SimCode.SES_ARRAY_CALL_ASSIGN(index, leftexp, exp, source, eqAttr), a);

    case (SimCode.SES_IFEQUATION(), _, a)
      /* TODO: Me */
    then (eq, a);

    case (SimCode.SES_ALGORITHM(), _, a)
      /* TODO: Me */
    then (eq, a);

    case (SimCode.SES_INVERSE_ALGORITHM(), _, a)
      /* TODO: Me */
    then (eq, a);

    case (SimCode.SES_LINEAR(), _, a)
      /* TODO: Me */
    then (eq, a);

    case (SimCode.SES_NONLINEAR(), _, a)
      /* TODO: Me */
    then (eq, a);

    case (SimCode.SES_MIXED(), _, a)
      /* TODO: Me */
    then (eq, a);

    case (SimCode.SES_WHEN(), _, a)
      /* TODO: Me */
    then (eq, a);

    case (SimCode.SES_FOR_LOOP(), _, a)
      /* TODO: Me */
    then (eq, a);

    case (SimCode.SES_ALIAS(), _, a)
    then (eq, a);

    else
      algorithm
        Error.addInternalError(getInstanceName() + " got unknown equation", sourceInfo());
      then fail();
  end match;
end traverseExpsEqSystem;

protected function setSimCodeLiterals
  input SimCode.SimCode simCode;
  input list<DAE.Exp> literals;
  output SimCode.SimCode outSimCode = simCode;
algorithm
  outSimCode.literals := literals;
end setSimCodeLiterals;



protected function eqSystemWCET
  "Calculate the estimated worst-case execution time of the system for partitioning"
  input SimCode.SimEqSystem eqs;
  output tuple<SimCode.SimEqSystem, Integer> tpl;
protected
  Integer i;
algorithm
  (_, i) := traverseExpsEqSystems({eqs}, Expression.complexityTraverse, 0, {});
  tpl := (eqs, i);
end eqSystemWCET;

protected function getProtected
  input Option<DAE.VariableAttributes> attr;
  output Boolean b;
algorithm
  b := match attr
    case SOME(DAE.VAR_ATTR_REAL(isProtected=SOME(b))) then b;
    case SOME(DAE.VAR_ATTR_INT(isProtected=SOME(b))) then b;
    case SOME(DAE.VAR_ATTR_BOOL(isProtected=SOME(b))) then b;
    case SOME(DAE.VAR_ATTR_STRING(isProtected=SOME(b))) then b;
    case SOME(DAE.VAR_ATTR_ENUMERATION(isProtected=SOME(b))) then b;
    else false;
  end match;
end getProtected;

protected function getHideResult
  "Returns the value of the hideResult attribute."
  input DAE.Exp hideResultExp;
  input Boolean isProtected;
  output Boolean hideResult;
algorithm
  hideResult := match(hideResultExp)
    case(DAE.BCONST(false)) then false;
    case(DAE.BCONST(true)) then true;
    else
      equation
        Error.addCompilerWarning("The hideResult annotation could not be evaluated, probably due to missing annotation(Evaluate=true). It is set to 'isProtected' (=" + boolString(isProtected) + ") by default.");
     then isProtected;
  end match;
end getHideResult;

protected function createVarToArrayIndexMapping "author: marcusw
  Creates a mapping for each array-cref to the array dimensions (int list) and to the indices (for the code generation) used to store the array content."
  input SimCode.ModelInfo iModelInfo;
  output HashTableCrIListArray.HashTable oVarToArrayIndexMapping;
  output HashTableCrILst.HashTable oVarToIndexMapping; //same as oVarToArrayIndexMapping, but does not merge array variables into one list
protected
  list<SimCodeVar.SimVar> stateVars;
  list<SimCodeVar.SimVar> derivativeVars;
  list<SimCodeVar.SimVar> algVars;
  list<SimCodeVar.SimVar> discreteAlgVars;
  list<SimCodeVar.SimVar> intAlgVars;
  list<SimCodeVar.SimVar> boolAlgVars;
  list<SimCodeVar.SimVar> inputVars;
  list<SimCodeVar.SimVar> outputVars;
  list<SimCodeVar.SimVar> aliasVars;
  list<SimCodeVar.SimVar> intAliasVars;
  list<SimCodeVar.SimVar> boolAliasVars;
  list<SimCodeVar.SimVar> paramVars;
  list<SimCodeVar.SimVar> intParamVars;
  list<SimCodeVar.SimVar> boolParamVars;
  list<SimCodeVar.SimVar> stringAlgVars;
  list<SimCodeVar.SimVar> stringParamVars;
  list<SimCodeVar.SimVar> stringAliasVars;
  //list<SimCodeVar.SimVar> extObjVars;
  list<SimCodeVar.SimVar> constVars;
  list<SimCodeVar.SimVar> intConstVars;
  list<SimCodeVar.SimVar> boolConstVars;
  list<SimCodeVar.SimVar> stringConstVars;
  //list<SimCodeVar.SimVar> jacobianVars;
  //list<SimCodeVar.SimVar> seedVars;
  list<SimCodeVar.SimVar> realOptimizeConstraintsVars;
  list<SimCodeVar.SimVar> realOptimizeFinalConstraintsVars;
  HashTableCrILst.HashTable varIndexMappingHashTable;
  HashTableCrIListArray.HashTable varArrayIndexMappingHashTable;
  array<Integer> currentVarIndices; //current variable index real,int,bool,string
algorithm
  (oVarToArrayIndexMapping,oVarToIndexMapping) := match(iModelInfo)
    case(SimCode.MODELINFO(vars = SimCodeVar.SIMVARS(stateVars=stateVars,derivativeVars=derivativeVars,algVars=algVars,discreteAlgVars=discreteAlgVars,
        intAlgVars=intAlgVars,boolAlgVars=boolAlgVars,stringAlgVars=stringAlgVars,aliasVars=aliasVars,intAliasVars=intAliasVars,boolAliasVars=boolAliasVars,stringAliasVars=stringAliasVars,paramVars=paramVars,
        intParamVars=intParamVars,boolParamVars=boolParamVars,stringParamVars=stringParamVars,inputVars=inputVars,outputVars=outputVars, constVars=constVars, intConstVars=intConstVars, boolConstVars=boolConstVars,
        stringConstVars=stringConstVars,realOptimizeConstraintsVars=realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars=realOptimizeFinalConstraintsVars)))
      equation
        varArrayIndexMappingHashTable = HashTableCrIListArray.emptyHashTableSized(BaseHashTable.biggerBucketSize);
        varIndexMappingHashTable = HashTableCrILst.emptyHashTableSized(BaseHashTable.biggerBucketSize);
        currentVarIndices = arrayCreate(4,1); //0 is reserved for unused variables
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(stateVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(derivativeVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));

        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(algVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(discreteAlgVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(intAlgVars, function addVarToArrayIndexMapping(iVarType=2), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(boolAlgVars, function addVarToArrayIndexMapping(iVarType=3), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(stringAlgVars, function addVarToArrayIndexMapping(iVarType=4), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(paramVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(intParamVars, function addVarToArrayIndexMapping(iVarType=2), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(boolParamVars, function addVarToArrayIndexMapping(iVarType=3), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(stringParamVars, function addVarToArrayIndexMapping(iVarType=4), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        //((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(inputVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        //((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(outputVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(constVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(intConstVars, function addVarToArrayIndexMapping(iVarType=2), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(boolConstVars, function addVarToArrayIndexMapping(iVarType=3), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(stringConstVars, function addVarToArrayIndexMapping(iVarType=4), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(realOptimizeConstraintsVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(realOptimizeFinalConstraintsVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));

        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(aliasVars, function addVarToArrayIndexMapping(iVarType=1), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(intAliasVars, function addVarToArrayIndexMapping(iVarType=2), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(boolAliasVars, function addVarToArrayIndexMapping(iVarType=3), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
        ((currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable)) = List.fold(stringAliasVars, function addVarToArrayIndexMapping(iVarType=4), (currentVarIndices, varArrayIndexMappingHashTable, varIndexMappingHashTable));
      then (varArrayIndexMappingHashTable, varIndexMappingHashTable);
    else
      then (HashTableCrIListArray.emptyHashTableSized(0), HashTableCrILst.emptyHashTableSized(0));
  end match;
end createVarToArrayIndexMapping;

public function addVarToArrayIndexMapping "author: marcusw
  Adds the given variable to the array-mapping and to the var-mapping. If the variable is part of an array 'a' which is not already part of the
  given hash table, a new hash table element with size 'a.length' is allocated. The allocated arrays are row-major based."
  input SimCodeVar.SimVar iVar;
  input Integer iVarType; //1 = real ; 2 = int ; 3 = bool ; 4 = string
  input tuple<array<Integer>, HashTableCrIListArray.HashTable, HashTableCrILst.HashTable> iCurrentVarIndicesHashTable;
  //<current indices, array related mapping, single var related mapping>
  output tuple<array<Integer>, HashTableCrIListArray.HashTable, HashTableCrILst.HashTable> oCurrentVarIndicesHashTable;
protected
  DAE.ComponentRef arrayCref, varName, name, arrayName;
  Integer varIdx, arrayIndex;
  array<Integer> varIndices;
  list<Integer> arrayDimensions;
  list<String> numArrayElement;
  list<DAE.ComponentRef> expandedCrefs;
  list<String> numArrayElement;
  array<Integer> tmpCurrentVarIndices;
  list<DAE.Subscript> arraySubscripts;
  HashTableCrIListArray.HashTable tmpVarToArrayIndexMapping; // Maps each array variable to a list of variable indices
  HashTableCrILst.HashTable tmpVarToIndexMapping; // Maps each variable to a concrete index
algorithm
  oCurrentVarIndicesHashTable := match(iVar, iVarType, iCurrentVarIndicesHashTable)
    case(SimCodeVar.SIMVAR(name=name, numArrayElement=numArrayElement),_,(tmpCurrentVarIndices,tmpVarToArrayIndexMapping,tmpVarToIndexMapping))
      equation
        (tmpCurrentVarIndices,varIdx) = getArrayIdxByVar(iVar, iVarType, tmpVarToIndexMapping, tmpCurrentVarIndices);
        //print("Adding variable " + ComponentReference.printComponentRefStr(name) + " with type " + intString(iVarType) + " to map with index " + intString(varIdx) + "\n");
        tmpVarToIndexMapping = BaseHashTable.add((name, {varIdx}), tmpVarToIndexMapping);
        arraySubscripts = ComponentReference.crefLastSubs(name);
        if(boolOr(listEmpty(numArrayElement), checkIfSubscriptsContainsUnhandlableIndices(arraySubscripts))) then
          arrayName = name;
        else
          arrayName = ComponentReference.crefStripLastSubs(name);
        end if;

        _ = match iVar
        case SimCodeVar.SIMVAR(type_ = DAE.T_ARRAY()) equation
          // store array dimensions and
          // index of first element to indicate a contiguous array
          arrayDimensions = List.map(List.lastN(numArrayElement, listLength(numArrayElement)), stringInt);
          varIndices = arrayCreate(1, varIdx);
          tmpVarToArrayIndexMapping = BaseHashTable.add((arrayName, (arrayDimensions, varIndices)), tmpVarToArrayIndexMapping);
        then ();
        else equation if (ComponentReference.crefEqual(arrayName, name)) then
          // scalar variable
          varIndices = arrayCreate(1, varIdx);
          tmpVarToArrayIndexMapping = BaseHashTable.add((arrayName, ({1},varIndices)), tmpVarToArrayIndexMapping);
        else
          // store array dimensions and build up list of indices for elements
          if(BaseHashTable.hasKey(arrayName, tmpVarToArrayIndexMapping)) then
            ((arrayDimensions,varIndices)) = BaseHashTable.get(arrayName, tmpVarToArrayIndexMapping);
          else
            //print("Try to calculate array dimensions out of " + intString(listLength(numArrayElement)) + " array elements " + "\n");
            arrayDimensions = List.map(List.lastN(numArrayElement,listLength(arraySubscripts)), stringInt);
            //print("Allocating new array with " + intString(List.fold(arrayDimensions, intMul, 1)) + " elements.\n");
            varIndices = arrayCreate(List.fold(arrayDimensions, intMul, 1), 0);
          end if;
          //print("Num of array elements {" + stringDelimitList(List.map(arrayDimensions, intString), ",") + "} : " + intString(listLength(arraySubscripts)) + "  arraySubs "+ExpressionDump.printSubscriptLstStr(arraySubscripts) + "  arrayDimensions[ "+stringDelimitList(List.map(arrayDimensions,intString),",")+"]\n");
          arrayIndex = getScalarElementIndex(arraySubscripts, arrayDimensions);
          //print("VarIndices: " + intString(arrayLength(varIndices)) + " arrayIndex: " + intString(arrayIndex) + " varIndex: " + intString(varIdx) + "\n");
          varIndices = arrayUpdate(varIndices, arrayIndex, varIdx);
          tmpVarToArrayIndexMapping = BaseHashTable.add((arrayName, (arrayDimensions,varIndices)), tmpVarToArrayIndexMapping);
        end if; then ();
        end match;
      then ((tmpCurrentVarIndices, tmpVarToArrayIndexMapping, tmpVarToIndexMapping));
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Unknown case for addVarToArrayIndexMapping.\n"});
      then iCurrentVarIndicesHashTable;
  end match;
end addVarToArrayIndexMapping;

protected function checkIfSubscriptsContainsUnhandlableIndices "author: marcusw
  Returns false if at least one subscript can not be handled as constant index."
  input list<DAE.Subscript> iSubscripts;
  output Boolean oContainsUnhandledSubscripts;
protected
  Boolean containsUnhandledSubscripts = false;
  DAE.Subscript subscript;
algorithm
  for subscript in iSubscripts loop
    containsUnhandledSubscripts := boolOr(containsUnhandledSubscripts, intLt(DAEUtil.getSubscriptIndex(subscript), 0));
  end for;
  oContainsUnhandledSubscripts := containsUnhandledSubscripts;
end checkIfSubscriptsContainsUnhandlableIndices;

protected function getArrayIdxByVar "author: marcusw
  Get the storage-index of the given variable. If the variable is an alias, the storage position of the alias variable is returned.
  If the variable is a negated alias, then the negated storage position of the alias variable is returned."
  input SimCodeVar.SimVar iVar;
  input Integer iVarType;
  input HashTableCrILst.HashTable iVarToIndexMapping;
  input output array<Integer> iCurrentVarIndices;
  output Integer oVarIndex;
protected
  DAE.ComponentRef varName, name;
  Integer varIdx;
  array<Integer> tmpCurrentVarIndices;
algorithm
  oVarIndex := match(iVar, iVarToIndexMapping, iCurrentVarIndices)
    case(SimCodeVar.SIMVAR(name=name, aliasvar=SimCodeVar.NOALIAS()),_,tmpCurrentVarIndices)
      equation
        //print("getArrayIdxByVar: Handling common variable\n");
        (varIdx,tmpCurrentVarIndices) = getVarToArrayIndexByType(iVar, iVarType, tmpCurrentVarIndices);
      then varIdx;
    case(SimCodeVar.SIMVAR(name=name, aliasvar=SimCodeVar.NEGATEDALIAS(varName)),_,_)
      equation
        //print("getArrayIdxByVar: Handling negated alias variable pointing to " + ComponentReference.printComponentRefStr(varName) + "\n");
        if(BaseHashTable.hasKey(varName, iVarToIndexMapping)) then
          varIdx::_ = BaseHashTable.get(varName, iVarToIndexMapping);
          varIdx = intMul(varIdx,-1);
        else
          Error.addMessage(Error.INTERNAL_ERROR, {"Negated alias to unknown variable given."});
          fail();
        end if;
      then varIdx;
    case(SimCodeVar.SIMVAR(name=name, aliasvar=SimCodeVar.ALIAS(varName)),_,_)
      equation
        //print("getArrayIdxByVar: Handling alias variable pointing to " + ComponentReference.printComponentRefStr(varName) + "\n");
        if(BaseHashTable.hasKey(varName, iVarToIndexMapping)) then
          varIdx::_ = BaseHashTable.get(varName, iVarToIndexMapping);
        else
          Error.addMessage(Error.INTERNAL_ERROR, {"Alias to unknown variable given."});
          fail();
        end if;
      then varIdx;
  end match;
end getArrayIdxByVar;

protected function getVarToArrayIndexByType "author: marcusw
  Return the the current variable index of the given tuple, regarding the given type. The index-tuple is incremented and returned."
  input SimCodeVar.SimVar iVar;
  input Integer iVarType; //1 = real ; 2 = int ; 3 = bool ; 4 = string
  output Integer oVarIdx;
  input output array<Integer> iCurrentVarIndices;
algorithm
  try
    oVarIdx := arrayGet(iCurrentVarIndices, iVarType);
    _ := match iVar
      case SimCodeVar.SIMVAR(type_ = DAE.T_ARRAY()) algorithm
        arrayUpdate(iCurrentVarIndices, iVarType, oVarIdx + getNumElems(iVar));
        then ();
      else algorithm
        arrayUpdate(iCurrentVarIndices, iVarType, oVarIdx + 1);
        then ();
    end match;
  else
    Error.addMessage(Error.INTERNAL_ERROR, {"GetVarToArrayIndexByType with unknown type called."});
    oVarIdx := -1;
  end try;
end getVarToArrayIndexByType;

public function getVarIndexListByMapping "author: marcusw
  Return the variable indices stored for the given variable in the mapping-table. If the variable is part of an array, all array indices are returned. This function is used by susan."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  input Boolean iColumnMajor;
  input String iIndexForUndefinedReferences;
  output list<String> oVarIndexList; //if the variable is part of an array, all array indices are returned in this list (the list contains one element if the variable is a scalar)
algorithm
  ((oVarIndexList,_)) := getVarIndexInfosByMapping(iVarToArrayIndexMapping, iVarName, iColumnMajor, iIndexForUndefinedReferences);
end getVarIndexListByMapping;

public function getVarIndexByMapping "author: marcusw
  Return the variable index stored for the given variable in the mapping-table. This function is used by susan."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  input Boolean iColumnMajor;
  input String iIndexForUndefinedReferences;
  output String oConcreteVarIndex; //the scalar index of the variable (this value is always part of oVarIndexList)
algorithm
  ((_,oConcreteVarIndex)) := getVarIndexInfosByMapping(iVarToArrayIndexMapping, iVarName, iColumnMajor, iIndexForUndefinedReferences);
end getVarIndexByMapping;

protected function getVarIndexInfosByMapping "author: marcusw
  Return the variable indices stored for the given variable in the mapping-table. This function is used by susan."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  input Boolean iColumnMajor; //true if the subscripts should be evaluated in column major
  input String iIndexForUndefinedReferences;
  output list<String> oVarIndexList; //if the variable is part of an array, all array indices are returned in this list (the list contains one element if the variable is a scalar)
  output String oConcreteVarIndex; //the scalar index of the variable (this value is always part of oVarIndexList)
protected
  DAE.ComponentRef varName = iVarName;
  Integer arrayIdx, idx, arraySize, concreteVarIndex;
  array<Integer> varIndices;
  list<String> tmpVarIndexListNew = {};
  list<DAE.Subscript> arraySubscripts;
  list<Integer> arrayDimensions, arrayDimensionsReverse;
  Boolean toColumnMajor;
  Boolean isContiguous;
algorithm
  arraySubscripts := ComponentReference.crefLastSubs(varName);
  varName := ComponentReference.crefStripLastSubs(varName);//removeSubscripts(varName);
  if(BaseHashTable.hasKey(varName, iVarToArrayIndexMapping)) then
    ((arrayDimensions,varIndices)) := BaseHashTable.get(varName, iVarToArrayIndexMapping); //varIndices are rowMajorOrder!
    isContiguous := arrayLength(varIndices) == 1;
    if isContiguous then
      arraySize := List.fold(arrayDimensions, intMul, 1);
    else
      arraySize := arrayLength(varIndices);
    end if;
    concreteVarIndex := getScalarElementIndex(arraySubscripts, arrayDimensions);
    toColumnMajor := iColumnMajor and listLength(arrayDimensions) > 1;
    if toColumnMajor then
      concreteVarIndex := convertIndexToColumnMajor(concreteVarIndex, arrayDimensions);
      arrayDimensionsReverse := listReverse(arrayDimensions);
    end if;
    //print("SimCodeUtil.getVarIndexInfosByMapping: Found variable index for '" + ComponentReference.printComponentRefStr(iVarName) + "'. The value is " + intString(concreteVarIndex) + "\n");
    for arrayIdx in 0:(arraySize-1) loop
      idx := arraySize-arrayIdx;
      if toColumnMajor then
        // convert to row major so that column major access will give this idx
        idx := convertIndexToColumnMajor(idx, arrayDimensionsReverse);
      end if;
      if isContiguous then
        idx := arrayGet(varIndices, 1) + idx - 1;
      else
        idx := arrayGet(varIndices, idx);
      end if;
      if(intLt(idx, 0)) then
        tmpVarIndexListNew := intString((intMul(idx, -1) - 1))::tmpVarIndexListNew;
        //print("SimCodeUtil.tmpVarIndexListNew: Warning, negativ aliases (" + ComponentReference.printComponentRefStr(iVarName) + ") are not supported at the moment!\n");
      else
        if(intEq(idx, 0)) then
          tmpVarIndexListNew := iIndexForUndefinedReferences::tmpVarIndexListNew;
        else
          tmpVarIndexListNew := intString(idx - 1)::tmpVarIndexListNew;
        end if;
      end if;
    end for;
    if isVarIndexListConsecutive(iVarToArrayIndexMapping,iVarName) and toColumnMajor then
      //if the array is not completely stuffed (e.g. some array variables have been derived and became dummy-derivatives), the array will not be initialized as a consecutive array, therefore we cannot take the colMajor-indexes
      // otherwise convert to column major for consecutive array
      concreteVarIndex := convertIndexToColumnMajor(concreteVarIndex, arrayDimensions);
    end if;
    oConcreteVarIndex := listGet(tmpVarIndexListNew, concreteVarIndex);
  end if;
  if(listEmpty(tmpVarIndexListNew)) then
    Error.addMessage(Error.INTERNAL_ERROR, {"GetVarIndexListByMapping: No Element for " + ComponentReference.printComponentRefStr(varName) + " found!"});
    tmpVarIndexListNew := {iIndexForUndefinedReferences};
    oConcreteVarIndex := iIndexForUndefinedReferences;
  end if;
  //print("SimCodeUtil.getVarIndexInfosByMapping: Variable " + ComponentReference.printComponentRefStr(iVarName) + " has variable indices {" + stringDelimitList(tmpVarIndexListNew, ",") + "} and concrete index " + oConcreteVarIndex + "\n");
  oVarIndexList := tmpVarIndexListNew;
end getVarIndexInfosByMapping;

protected function convertIndexToColumnMajor
 "Converts row-major unrolled idx to column-major, author: rfranke"
  input Integer idx; // one based, row-major ordered
  input list<Integer> arrayDimensions;
  output Integer idxOut; // one based, column-major ordered
protected
  Integer idx0, ndim, length, idxi, fac;
algorithm
  ndim := listLength(arrayDimensions);
  length := List.fold(arrayDimensions, intMul, 1);
  idx0 := idx - 1; // zero based
  idxOut := 1; // one based
  fac := 1;
  for dimi in arrayDimensions loop
    length := intDiv(length, dimi);
    idxi := intDiv(idx0, length);
    idx0 := idx0 - idxi*length;
    idxOut := idxOut + idxi*fac;
    fac := fac * dimi;
  end for;
end convertIndexToColumnMajor;

public function isVarIndexListConsecutive "author: marcusw
  Check if all variable indices of the given variables, stored in the hash table, are consecutive."
  input HashTableCrIListArray.HashTable iVarToArrayIndexMapping;
  input DAE.ComponentRef iVarName;
  output Boolean oIsConsecutive;
protected
  DAE.ComponentRef varName = iVarName;
  Integer arrayIdx, idx, arraySize;
  Integer currentIndex = -1;
  array<Integer> varIndices;
  Boolean consecutive = true;
algorithm
  varName := ComponentReference.crefStripLastSubs(varName);//removeSubscripts(varName);
  if(BaseHashTable.hasKey(varName, iVarToArrayIndexMapping)) then
    ((_,varIndices)) := BaseHashTable.get(varName, iVarToArrayIndexMapping);
    arraySize := arrayLength(varIndices);
    for arrayIdx in 0:(arraySize-1) loop
      idx := arrayGet(varIndices, arraySize-arrayIdx);
      if(intLt(idx, 0)) then
        if(intEq(currentIndex, -1)) then
          currentIndex := intMul(idx, -1) - 1;
        else
          consecutive := boolAnd(consecutive, intEq(currentIndex, intMul(idx, -1)));
          currentIndex := intMul(idx, -1) - 1;
        end if;
        //print("SimCodeUtil.isVarIndexListConsecutive: Warning, negativ aliases (" + ComponentReference.printComponentRefStr(iVarName) + ") are not supported at the moment!\n");
      else
        if(intEq(idx, 0)) then
          currentIndex := -2;
          consecutive := false;
        else
          if(intEq(currentIndex, -1)) then
            currentIndex := idx - 1;
          else
            //print("SimCodeUtil.isVarIndexListConsecutive: Checking if " + intString(currentIndex) + " is consecutive with " + intString(idx) + "\n");
            consecutive := boolAnd(consecutive, intEq(currentIndex, idx));
            //print("SimCodeUtil.isVarIndexListConsecutive: " + boolString(consecutive) + "\n");
            currentIndex := idx - 1;
          end if;
        end if;
      end if;
    end for;
  end if;
  oIsConsecutive := consecutive;
end isVarIndexListConsecutive;

protected function getScalarElementIndex
 "Calculate the one based memory offset for consecutive row major storage,
  author: rfranke"
  input list<DAE.Subscript> arraySubscripts;
  input list<Integer> arrayDimensions;
  output Integer arrayIndex;
protected
  Integer idx, fac;
algorithm
  arrayIndex := 1; // one based
  fac := 1;
  for i in listLength(arraySubscripts):-1:1 loop
    idx := DAEUtil.getSubscriptIndex(listGet(arraySubscripts, i));
    arrayIndex := arrayIndex + (idx - 1) * fac;
    fac := fac * listGet(arrayDimensions, i);
  end for;
end getScalarElementIndex;

public function createIdxSCVarMapping "author: marcusw
  Create a mapping from the SCVar-Index (array-Index) to the SCVariable, as it is used in the c-runtime."
  input SimCodeVar.SimVars simVars;
  output array<Option<SimCodeVar.SimVar>> outMapping;
protected
  Integer numStateVars;
  list<SimCodeVar.SimVar> stateVars;
  list<SimCodeVar.SimVar> derivativeVars;
  list<SimCodeVar.SimVar> algVars;
  list<SimCodeVar.SimVar> discreteAlgVars;
  list<SimCodeVar.SimVar> intAlgVars;
  list<SimCodeVar.SimVar> boolAlgVars;
  list<SimCodeVar.SimVar> inputVars;
  list<SimCodeVar.SimVar> outputVars;
  list<SimCodeVar.SimVar> aliasVars;
  list<SimCodeVar.SimVar> intAliasVars;
  list<SimCodeVar.SimVar> boolAliasVars;
  list<SimCodeVar.SimVar> paramVars;
  list<SimCodeVar.SimVar> intParamVars;
  list<SimCodeVar.SimVar> boolParamVars;
  list<SimCodeVar.SimVar> stringAlgVars;
  list<SimCodeVar.SimVar> stringParamVars;
  list<SimCodeVar.SimVar> stringAliasVars;
  list<SimCodeVar.SimVar> extObjVars;
  list<SimCodeVar.SimVar> constVars;
  list<SimCodeVar.SimVar> intConstVars;
  list<SimCodeVar.SimVar> boolConstVars;
  list<SimCodeVar.SimVar> stringConstVars;
  list<SimCodeVar.SimVar> jacobianVars;
  list<SimCodeVar.SimVar> seedVars;
  list<SimCodeVar.SimVar> realOptimizeConstraintsVars;
  list<SimCodeVar.SimVar> realOptimizeFinalConstraintsVars;
  list<tuple<Integer,SimCodeVar.SimVar>> idxSimVarMappingTplList;
  Integer highestIdx, varCount;
  array<Option<SimCodeVar.SimVar>> mappingArray;
algorithm
  SimCodeVar.SIMVARS(stateVars, derivativeVars, algVars, discreteAlgVars, intAlgVars, boolAlgVars, inputVars,
      outputVars, aliasVars, intAliasVars, boolAliasVars, paramVars, intParamVars, boolParamVars,
      stringAlgVars, stringParamVars, stringAliasVars, extObjVars, constVars, intConstVars, boolConstVars,
      stringConstVars, jacobianVars, seedVars, realOptimizeConstraintsVars, realOptimizeFinalConstraintsVars,
      _) := simVars;

  numStateVars := listLength(stateVars);
  varCount := 0;
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(stateVars, createAllSCVarMapping0, varCount, {},0);
  varCount := varCount + numStateVars;
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(derivativeVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + numStateVars;
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(algVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(algVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(discreteAlgVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(discreteAlgVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(intAlgVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(intAlgVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(boolAlgVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(boolAlgVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(stringAlgVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(stringAlgVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(inputVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(inputVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(outputVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(outputVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(aliasVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(aliasVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(intAliasVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(intAliasVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(boolAliasVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(boolAliasVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(stringAliasVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(stringAliasVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(paramVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(paramVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(intParamVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(intParamVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(boolParamVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(boolParamVars);
  ((idxSimVarMappingTplList, highestIdx)) := List.fold21(stringParamVars, createAllSCVarMapping0, varCount, idxSimVarMappingTplList,highestIdx);
  varCount := varCount + listLength(stringParamVars);

  mappingArray := arrayCreate(highestIdx, NONE());
  mappingArray := List.fold(idxSimVarMappingTplList, createAllSCVarMapping1, mappingArray);
  outMapping := mappingArray;
end createIdxSCVarMapping;

protected function createAllSCVarMapping0 "author: marcusw
  Append the given variable to the Index/SimVar-List."
  input SimCodeVar.SimVar iSimVar;
  input Integer iOffset; //an offset that should be added to the index (necessary for state derivatives)
  input output list<tuple<Integer,SimCodeVar.SimVar>> iMapping;
  input output Integer highestIdx;
protected
  Integer simVarIdx;
algorithm
  //print("createAllSCVarMapping0: Mapping variable \n");
  //dumpVar(iSimVar);
  //print(" to index " + intString(simVarIdx) + "\n");
  SimCodeVar.SIMVAR(index=simVarIdx) := iSimVar;
  simVarIdx := simVarIdx + 1 + iOffset;
  highestIdx := if intGt(simVarIdx, highestIdx) then simVarIdx else highestIdx;
  iMapping := (simVarIdx, iSimVar)::iMapping;
  //print("createAllSCVarMapping0: Mapping-Length: " + intString(listLength(iMapping)) + "\n");
end createAllSCVarMapping0;

protected function createAllSCVarMapping1 "author: marcusw
  Set the arrayIndex (iMapping) to the value given by the tuple."
  input tuple<Integer,SimCodeVar.SimVar> iSimVarIdxTpl; //<idx, elem>
  input array<Option<SimCodeVar.SimVar>> iMapping;
  output array<Option<SimCodeVar.SimVar>> outMapping;
protected
  Integer simVarIdx;
  SimCodeVar.SimVar simVar;
algorithm
  (simVarIdx,simVar) := iSimVarIdxTpl;
  outMapping := arrayUpdate(iMapping,simVarIdx,SOME(simVar));
end createAllSCVarMapping1;

public function getEnumerationTypes
  input SimCodeVar.SimVars inVars;
  output list<SimCodeVar.SimVar> outVars;
algorithm
  outVars := match (inVars)
    case SimCodeVar.SIMVARS()
      algorithm
        outVars := getEnumerationTypesHelper(inVars.stateVars, {});
        outVars := getEnumerationTypesHelper(inVars.derivativeVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.algVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.discreteAlgVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.intAlgVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.boolAlgVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.inputVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.outputVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.aliasVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.intAliasVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.boolAliasVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.paramVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.intParamVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.boolParamVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.stringAlgVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.stringParamVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.stringAliasVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.extObjVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.constVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.intConstVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.boolConstVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.stringConstVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.sensitivityVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.jacobianVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.seedVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.realOptimizeConstraintsVars, outVars);
        outVars := getEnumerationTypesHelper(inVars.realOptimizeFinalConstraintsVars, outVars);
      then
        listReverse(outVars); // TODO: Is the order actually important?

    else {};
  end match;
end getEnumerationTypes;

protected function getEnumerationTypesHelper
  input list<SimCodeVar.SimVar> inVars;
  input list<SimCodeVar.SimVar> inAccumVars;
  output list<SimCodeVar.SimVar> outVars = inAccumVars;
algorithm
  for var in inVars loop
    _ := match var
      case SimCodeVar.SIMVAR()
        algorithm
          // Add the variable to the list if it's an enumeration variable which
          // doesn't already exist in the list.
          if Types.isEnumeration(var.type_) and not
             List.exist1(outVars, enumerationTypeExists, var.type_) then
            outVars := var :: outVars;
          end if;
        then
          ();

      else ();
    end match;
  end for;
end getEnumerationTypesHelper;

protected function enumerationTypeExists
  input SimCodeVar.SimVar var;
  input DAE.Type inType;
  output Boolean b;
algorithm
  b := match (var, inType)
    local
      DAE.Type ty;

    case (SimCodeVar.SIMVAR(type_ = ty as DAE.T_ENUMERATION()), DAE.T_ENUMERATION())
      then Absyn.pathEqual(ty.path, inType.path);
    else false;
  end match;
end enumerationTypeExists;

public function equationIndexEqual
  input SimCode.SimEqSystem eq1;
  input SimCode.SimEqSystem eq2;
  output Boolean isEqual;
algorithm
  isEqual := intEq(simEqSystemIndex(eq1),simEqSystemIndex(eq2));
end equationIndexEqual;

//--------------------------
// backendMapping section
//--------------------------

protected function setUpBackendMapping"sets up a BackendMapping type with empty eq and varmappings and empty adjacency matrices.
author: Waurich TUD 2014-04"
  input BackendDAE.BackendDAE dae;
  output SimCode.BackendMapping mapping;
algorithm
  mapping := matchcontinue(dae)
    local
      Integer sizeE,sizeV;
      array<Integer> eqMatch, varMatch;
      array<list<Integer>> tree;
      BackendDAE.EqSystems eqs;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      list<BackendDAE.IncidenceMatrix> mLst;
      list<BackendDAE.IncidenceMatrixT> mtLst;
      list<tuple<Integer,Integer>> varMap;
      list<tuple<Integer,list<Integer>>> eqMap;
      array<list<SimCodeVar.SimVar>> simVarMapping;
      list<tuple<Integer,Integer,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT,array<Integer>,array<Integer>>> tpl;
    case(_)
      equation
        BackendDAE.DAE(eqs=eqs) = dae;
        tpl = List.map(eqs,setUpSystMapping);
        sizeE = List.applyAndFold(tpl,intAdd,Util.tuple61,0);
        sizeV = List.applyAndFold(tpl,intAdd,Util.tuple62,0);
        eqMap = {};
        varMap = {};
        simVarMapping = arrayCreate(sizeV,{});
        eqMatch = arrayCreate(sizeE,0);
        varMatch = arrayCreate(sizeV,0);
        m = arrayCreate(sizeE,{});
        mt = arrayCreate(sizeV,{});
        ((_,_,m,mt,eqMatch,varMatch)) = List.fold(tpl,appendAdjacencyMatrices,(0,0,m,mt,eqMatch,varMatch));
        tree = arrayCreate(sizeE,{});
        tree = List.fold4(List.intRange(sizeE),setUpEqTree,m,mt,eqMatch,varMatch,tree);
        tree = Array.map(tree,List.unique);
        mapping = SimCode.BACKENDMAPPING(m,mt,eqMap,varMap,eqMatch,varMatch,tree,simVarMapping);
      then
        mapping;
    else
        SimCode.NO_MAPPING();
  end matchcontinue;
end setUpBackendMapping;

protected function setUpEqTree" builds the tree graph. the index depicts an equation and the entry depicts the direct predecessors.
author:Waurich TUD 2014-04"
  input Integer beq;
  input BackendDAE.IncidenceMatrix m;
  input BackendDAE.IncidenceMatrixT mt;
  input array<Integer> eqMatch;
  input array<Integer> varMatch;
  input array<list<Integer>> treeIn;
  output array<list<Integer>> treeOut;
protected
  Integer assVar;
  list<Integer> preEqs,depVars;
algorithm
  assVar := arrayGet(eqMatch,beq);
  depVars := arrayGet(m,beq);
  depVars := List.filter1OnTrue(depVars,setUpEqTree_Help,assVar);
  preEqs := List.map1(depVars,Array.getIndexFirst,varMatch);
  Array.updateElementListAppend(beq,preEqs,treeIn);
  treeOut := treeIn;
end setUpEqTree;

protected function setUpEqTree_Help
  input Integer iVal;
  input Integer iRef;
  output Boolean oBool;
algorithm
  oBool := intGt(iVal, 0) and intNe(iVal, iRef);
end setUpEqTree_Help;

protected function appendAdjacencyMatrices"appends the adjacencymatrices for the different equation systems.
the indeces are raised according to the number of equations and vars in the previous systems
author:Waurich TUD 2014-04"
  input tuple<Integer,Integer,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT,array<Integer>,array<Integer>> tplIn;
  input tuple<Integer,Integer,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT,array<Integer>,array<Integer>> foldIn;
  output tuple<Integer,Integer,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT,array<Integer>,array<Integer>> foldOut;
algorithm
  foldOut := match(tplIn,foldIn)
    local
      Integer sizeE,sizeV,addV,addE;
      array<Integer> eqMatch,varMatch,eqMatchIn,varMatchIn;
      BackendDAE.IncidenceMatrix mIn,m;
      BackendDAE.IncidenceMatrixT mtIn,mt;
    case((addE,addV,m,mt,eqMatch,varMatch),(sizeE,sizeV,mIn,mtIn,eqMatchIn,varMatchIn))
      equation
        m = Array.map1(m,addIntLst,sizeV);
        mt = Array.map1(mt,addIntLst,sizeE);
        eqMatch = Array.map1(eqMatch,intAdd,sizeV);
        varMatch = Array.map1(varMatch,intAdd,sizeE);
        mIn = List.fold2(List.intRange(addE),updateInAdjacencyMatrix,sizeE,m,mIn);
        mtIn = List.fold2(List.intRange(addV),updateInAdjacencyMatrix,sizeV,mt,mtIn);
        eqMatchIn = List.fold2(List.intRange(addE),updateInMatching,sizeE,eqMatch,eqMatchIn);
        varMatchIn = List.fold2(List.intRange(addV),updateInMatching,sizeV,varMatch,varMatchIn);
      then
        ((sizeE+addE,sizeV+addV,mIn,mtIn,eqMatchIn,varMatchIn));
  end match;
end appendAdjacencyMatrices;

protected function updateInAdjacencyMatrix"updates a row in an adajcency matrix. thw row indeces are raised by the offset
author: Waurich TUD 2014-04"
  input Integer idx;
  input Integer offset;
  input BackendDAE.IncidenceMatrix mAppend;
  input BackendDAE.IncidenceMatrix mIn;
  output BackendDAE.IncidenceMatrix mOut;
protected
  list<Integer> entry;
algorithm
  entry := arrayGet(mAppend,idx);
  mOut := arrayUpdate(mIn,idx+offset,entry);
end updateInAdjacencyMatrix;

protected function updateInMatching"updates an entry in the matching. the indeces are raised by the offset
author: Waurich TUD 2014-04"
  input Integer idx;
  input Integer offset;
  input array<Integer> matchingAppend;
  input array<Integer> matchingIn;
  output array<Integer> matchingOut;
protected
  Integer entry;
algorithm
  entry := arrayGet(matchingAppend,idx);
  matchingOut := arrayUpdate(matchingIn,idx+offset,entry);
end updateInMatching;

protected function addIntLst"add an integer to every entry in the lst
author:Waurich TUD 2014-04"
  input list<Integer> lstIn;
  input Integer x;
  output list<Integer> lstOut;
algorithm
  lstOut := List.map1(lstIn,intAdd,x);
end addIntLst;

protected function setUpSystMapping"gets the mapping information for every system of equations in the backenddae.
author:Waurich TUD 2014-04"
  input BackendDAE.EqSystem dae;
  output tuple<Integer,Integer,BackendDAE.IncidenceMatrix,BackendDAE.IncidenceMatrixT,array<Integer>,array<Integer>> outTpl;
protected
  Integer sizeV,sizeE;
  array<Integer> ass1, ass2;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mt;
  BackendDAE.Matching matching;
algorithm
  outTpl := matchcontinue(dae)
  case(_)
    equation
      BackendDAE.EQSYSTEM(m=SOME(m),mT=SOME(mt),matching=matching)= dae;
      BackendDAE.MATCHING(ass1=ass1,ass2=ass2) = matching;
      sizeE = BackendDAEUtil.equationArraySizeDAE(dae);
      sizeV = BackendVariable.daenumVariables(dae);
    then
      ((sizeE,sizeV,m,mt,ass2,ass1));
  case(_)
    equation
      BackendDAE.EQSYSTEM(m=NONE(),mT=NONE(),matching=matching) = dae;
      BackendDAE.MATCHING(ass1=ass1,ass2=ass2) = matching;
      (_,m,mt) = BackendDAEUtil.getIncidenceMatrix(dae,BackendDAE.NORMAL(),NONE());
      sizeE = BackendDAEUtil.equationArraySizeDAE(dae);
      sizeV = BackendVariable.daenumVariables(dae);
    then
      ((sizeE,sizeV,m,mt,ass2,ass1));
  end matchcontinue;
end setUpSystMapping;

protected function setBackendVarMapping
"sets the varmapping in the backendmapping.
author:Waurich TUD 2014-04"
  input BackendDAE.BackendDAE dae;
  input SimCode.HashTableCrefToSimVar ht;
  input SimCode.ModelInfo modelInfo;
  input SimCode.BackendMapping bmapIn;
  output SimCode.BackendMapping bmapOut;
algorithm
  bmapOut := matchcontinue(dae,ht,modelInfo,bmapIn)
    local
      array<Integer> eqMatch,varMatch;
      array<list<Integer>> tree;
      SimCode.VarInfo varInfo;
      SimCodeVar.SimVars allVars;
      list<Integer> bVarIdcs,simVarIdcs;
      list<BackendDAE.EqSystem> eqs;
      list<BackendDAE.Var> vars;
      list<DAE.ComponentRef> crefs;
      list<SimCodeVar.SimVar> simVars;
      list<tuple<Integer,list<Integer>>> eqMapping;
      list<tuple<Integer,Integer>> varMapping;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<list<SimCodeVar.SimVar>> simVarMapping;
      SimCode.HashTableCrefToSimVar htStates;
      Integer size;
    case(_,_,_,_)
      equation
        SimCode.BACKENDMAPPING(m=m,mT=mt,eqMapping=eqMapping,varMapping=varMapping,eqMatch=eqMatch,varMatch=varMatch,eqTree=tree,simVarMapping=simVarMapping) = bmapIn;
        BackendDAE.DAE(eqs=eqs) = dae;

        //get Backend vars and index
        vars = BackendVariable.equationSystemsVarsLst(eqs);
        crefs = List.map(vars,BackendVariable.varCref);
        size = listLength(crefs);
        bVarIdcs = List.intRange(size);
        simVars = List.map1(crefs,BaseHashTable.get,ht);

        // get states and create hash table
        SimCode.MODELINFO(varInfo=varInfo,vars=allVars) = modelInfo;
        htStates = List.fold(allVars.stateVars, HashTableCrefSimVar.addSimVarToHashTable, HashTableCrefSimVar.emptyHashTableSized(1+integer(1.4*size)));

        // produce mapping
        simVarIdcs = List.map2(simVars,getSimVarIndex,varInfo,htStates);
        varMapping = makeVarMapTuple(simVarIdcs,bVarIdcs,{});
        List.fold1(simVars, fillSimVarMapping, simVarMapping, 1);
        //print(stringDelimitList(List.map(crefs,ComponentReference.printComponentRefStr),"\n")+"\n");
        //List.map_0(simVars,dumpVar);
      then
        SimCode.BACKENDMAPPING(m,mt,eqMapping,varMapping,eqMatch,varMatch,tree,simVarMapping);
    else
      SimCode.NO_MAPPING();
  end matchcontinue;
end setBackendVarMapping;

protected function fillSimVarMapping "adds the given simvar to the mapping.
author:marcusw"
  input SimCodeVar.SimVar iSimVar;
  input array<list<SimCodeVar.SimVar>> iSimVarMapping;
  input Integer iVarIdx;
  output Integer oVarIdx;
algorithm
  _ := arrayUpdate(iSimVarMapping, iVarIdx, {iSimVar});
  oVarIdx := iVarIdx + 1;
end fillSimVarMapping;

protected function getSimVarIndex
"gets the index from a SimVar and calculates the place in the localData array
author:Waurich TUD 2014-04"
  input SimCodeVar.SimVar var;
  input SimCode.VarInfo varInfo;
  input SimCode.HashTableCrefToSimVar htStates;
  output Integer idx;
protected
  Integer offset;
algorithm
  if BaseHashTable.hasKey(var.name, htStates) then
    idx := var.index;
  else
    offset := varInfo.numStateVars;
    idx := var.index;
    idx := idx+2*offset;
  end if;
end getSimVarIndex;

protected function makeVarMapTuple"builds a tuple for the varMapping. ((simvarindex,backendvarindex))
author:Waurich TUD 2014-04"
  input list<Integer> sVar;
  input list<Integer> bVar;
  input list<tuple<Integer,Integer>> foldIn;
  output list<tuple<Integer,Integer>> foldOut;
algorithm
  foldOut := match(sVar,bVar,foldIn)
    local
      Integer i1,i2;
      list<Integer> rest1,rest2;
      list<tuple<Integer,Integer>> fold;
    case({},{},_)
      then
        foldIn;
    case(i1::rest1,i2::rest2,_)
      equation
        fold = makeVarMapTuple(rest1,rest2,(i1,i2)::foldIn);
      then
        fold;
  end match;
end makeVarMapTuple;

protected function setEqMapping"updates the equation mapping for a given pair of simeqs and backend eqs.
author:Waurich TUD 2014-04"
  input list<Integer> simEqs;
  input list<Integer> bEq;
  input SimCode.BackendMapping mapIn;
  output SimCode.BackendMapping mapOut;
algorithm
  mapOut := match(simEqs,bEq,mapIn)
    local
      array<Integer> eqMatch,varMatch;
      array<list<Integer>> tree;
      list<tuple<Integer,list<Integer>>> eqMapping;
      list<tuple<Integer,Integer>> varMapping;
      BackendDAE.IncidenceMatrix m;
      BackendDAE.IncidenceMatrixT mt;
      array<list<SimCodeVar.SimVar>> simVarMapping;
    case(_,_,SimCode.BACKENDMAPPING(m=m,mT=mt,eqMapping=eqMapping,varMapping=varMapping,eqMatch=eqMatch,varMatch=varMatch,eqTree=tree,simVarMapping=simVarMapping))
      equation
        eqMapping = List.fold1(simEqs, appendEqIdcs, bEq, eqMapping);
      then
        SimCode.BACKENDMAPPING(m,mt,eqMapping,varMapping,eqMatch,varMatch,tree,simVarMapping);
    case(_,_,SimCode.NO_MAPPING())
      then
        mapIn;
  end match;
end setEqMapping;

protected function appendEqIdcs"appends an equation mapping tuple to the mapping list.
author:Waurich TUD 2014-04"
  input Integer iCurrentIdx;
  input list<Integer> iEqIdx;
  input list<tuple<Integer, list<Integer>>> iSccIdc;
  output list<tuple<Integer, list<Integer>>> oSccIdc;
algorithm
  oSccIdc:=(iCurrentIdx,iEqIdx)::iSccIdc;
end appendEqIdcs;

public function getSimVarsInSimEq"gets the indeces for the simVars occuring in the given simEq
author:Waurich TUD 2014-04"
  input Integer simEq;
  input SimCode.BackendMapping map;
  input Integer opt; //1: get all indeces from the incidenceMatrix, 2: get only positive entries, 3: get only negative entries
  output list<Integer> simVars;
protected
  list<Integer> bVars,bEqs;
  list<list<Integer>> bVarsLst;
  list<tuple<Integer,list<Integer>>> eqMapping;
  list<tuple<Integer,Integer>> varMapping;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mt;
algorithm
  SimCode.BACKENDMAPPING(m=m,mT=mt,eqMapping=eqMapping,varMapping=varMapping) := map;
  bEqs := getBackendEqsForSimEq(simEq,map);
  bVarsLst := List.map1(bEqs,Array.getIndexFirst,m);
  bVars := List.flatten(bVarsLst);
  bVars := if intEq(opt,2) then List.filter1OnTrue(bVars,intGt,0) else bVars;
  bVars := if intEq(opt,3) then List.filter1OnTrue(bVars,intLt,0) else bVars;
  if not List.isMemberOnTrue(opt,{1,2,3},intEq) then
    print("invalid option for getSimVarsInSimEq\n");
  end if;
  bVars := List.unique(bVars);
  bVars := List.map(bVars,intAbs);
  simVars := List.map1(bVars,getSimVarForBackendVar,map);
end getSimVarsInSimEq;

public function getSimEqsOfSimVar"gets the indeces for the simEqs for the given simVar
author:Waurich TUD 2014-04"
  input Integer simVar;
  input SimCode.BackendMapping map;
  input Integer opt; //1: complete incidence matrix row, 2: only positive entries, 3: only negative entries
  output list<Integer> simEqs;
protected
  Integer bVar;
  list<Integer> bEqs;
  list<tuple<Integer,list<Integer>>> eqMapping;
  list<tuple<Integer,Integer>> varMapping;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mt;
algorithm
  SimCode.BACKENDMAPPING(m=m,mT=mt,eqMapping=eqMapping,varMapping=varMapping) := map;
  bVar := getBackendVarForSimVar(simVar,map);
  bEqs := arrayGet(mt,bVar);
  bEqs := if intEq(opt,2) then List.filter1OnTrue(bEqs,intGt,0) else bEqs;
  bEqs := if intEq(opt,3) then List.filter1OnTrue(bEqs,intLt,0) else bEqs;
  if not List.isMemberOnTrue(opt,{1,2,3},intEq) then
    print("invalid option for getSimEqsOfSimVar\n");
  end if;
  bEqs := List.map(bEqs,intAbs);
  simEqs := List.map1(bEqs,getSimEqsForBackendEqs,map);
  simEqs := List.unique(simEqs);
end getSimEqsOfSimVar;

public function getReqSimEqSysForSimVar
  input Integer simVar;
  input SimCode.SimCode simCode;
  output list<SimCode.SimEqSystem> ses;
protected
  list<Integer> sesIdcs;
  list<SimCode.SimEqSystem> sesLst;
  SimCode.BackendMapping bmap;
  Option<SimCode.BackendMapping> bmapOpt;
algorithm
  SimCode.SIMCODE(allEquations=sesLst, backendMapping=bmapOpt) := simCode;
  bmap := Util.getOption(bmapOpt);
  sesIdcs := getReqSimEqsForSimVar(simVar,bmap);
  ses := List.map1(sesIdcs,getSimEqSysForIndex,sesLst);
end getReqSimEqSysForSimVar;

public function getSimEqSysForIndex
  input Integer idx;
  input list<SimCode.SimEqSystem> allSimEqs;
  output SimCode.SimEqSystem outSimEq;
algorithm
  try
    outSimEq := List.getMemberOnTrue(idx,allSimEqs,indexIsEqual);
  else
    print("getSimEqSysForIndex failed!\n");
    fail();
  end try;
end getSimEqSysForIndex;

public function getSimVarMappingOfBackendMapping "author: mwalther
  Get the sim var mapping that is stored in the given backend-mapping. If the backend-mapping
  has no simVarMapping, an empty array is returned.."
  input Option<SimCode.BackendMapping> iBackendMappingOpt;
  output array<list<SimCodeVar.SimVar>> oSimVarMapping;
protected
  array<list<SimCodeVar.SimVar>> simVarMapping;
algorithm
  oSimVarMapping := match(iBackendMappingOpt)
    case(SOME(SimCode.BACKENDMAPPING(simVarMapping=simVarMapping)))
      then simVarMapping;
    else
      then arrayCreate(0, {});
  end match;
end getSimVarMappingOfBackendMapping;

protected function indexIsEqual
  input Integer idx;
  input SimCode.SimEqSystem ses;
  output Boolean b;
protected
  Integer idx2;
algorithm
  idx2 := simEqSystemIndex(ses);
  b := intEq(idx,idx2);
end indexIsEqual;

public function getReqSimEqsForSimVar"outputs the indeces for the required simEqSys for the indexed SimVar
author:Waurich TUD 2014-04"
  input Integer simVar;
  input SimCode.BackendMapping map;
  output list<Integer> simEqs;
protected
  Integer bVar,bEq;
  list<Integer> beqs;
  array<Integer> eqMatch,varMatch;
  array<list<Integer>> tree;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mt;
algorithm
  SimCode.BACKENDMAPPING(m=m,mT=mt,eqMatch=eqMatch,varMatch=varMatch,eqTree=tree) := map;
  bVar := getBackendVarForSimVar(simVar,map);
  bEq := arrayGet(varMatch,bVar);
  beqs := collectReqSimEqs(bEq,tree,{});
  simEqs := List.map1(beqs,getSimEqsForBackendEqs,map);
  simEqs := List.unique(simEqs);
end getReqSimEqsForSimVar;

public function getAssignedSimEqSysIdx"gets the index of the assigned simEqSys for the given simVar idx
author:Waurich TUD 2014-06"
  input Integer simVarIdx;
  input SimCode.BackendMapping map;
  output Integer simEqSysIdx;
protected
  Integer bVarIdx,bEqIdx;
  array<Integer> varMatch;
algorithm
  bVarIdx := getBackendVarForSimVar(simVarIdx,map);
  SimCode.BACKENDMAPPING(varMatch = varMatch) := map;
  bEqIdx := arrayGet(varMatch,bVarIdx);
  simEqSysIdx := getSimEqsForBackendEqs(bEqIdx,map);
end getAssignedSimEqSysIdx;

protected function collectReqSimEqs"gets the previously required equations from the tree and gets the required equations for them and so on
author:Waurich TUD 2014-04"
  input Integer eq;
  input array<list<Integer>> tree;
  input list<Integer> eqsIn;
  output list<Integer> eqsOut;
protected
  list<Integer> preEqs,reqEqs;
algorithm
  preEqs := arrayGet(tree,eq);
  (_,preEqs,_) := List.intersection1OnTrue(preEqs,eqsIn,intEq);
  reqEqs := listAppend(preEqs,eqsIn);
  eqsOut := List.fold1(preEqs,collectReqSimEqs,tree,reqEqs);
end collectReqSimEqs;

protected function getBackendVarForSimVar"outputs the backendVar indeces for the given SimVar index
author:Waurich TUD 2014-04"
  input Integer simVar;
  input SimCode.BackendMapping map;
  output Integer bVar;
protected
  list<tuple<Integer,Integer>> varMapping;
algorithm
  SimCode.BACKENDMAPPING(varMapping=varMapping) := map;
  ((_,bVar)):= List.getMemberOnTrue(simVar,varMapping,findSimVar);
end getBackendVarForSimVar;

protected function getSimVarForBackendVar"outputs the SimVar indeces for the given backendVar index
author:Waurich TUD 2014-04"
  input Integer bVar;
  input SimCode.BackendMapping map;
  output Integer simVar;
protected
  list<tuple<Integer,Integer>> varMapping;
algorithm
  SimCode.BACKENDMAPPING(varMapping=varMapping) := map;
  ((simVar,_)):= List.getMemberOnTrue(bVar,varMapping,findBackendVar);
end getSimVarForBackendVar;

protected function getBackendEqsForSimEq"outputs the backendEq indeces for the given SimEqSys index
author:Waurich TUD 2014-04"
  input Integer simEq;
  input SimCode.BackendMapping map;
  output list<Integer> bEqs;
protected
  list<tuple<Integer,list<Integer>>> eqMapping;
algorithm
  SimCode.BACKENDMAPPING(eqMapping=eqMapping) := map;
  ((_,bEqs)):= List.getMemberOnTrue(simEq,eqMapping,findSimEqs);
end getBackendEqsForSimEq;

protected function getSimEqsForBackendEqs"outputs the simEqSys index for the given backendEquation index
author:Waurich TUD 2014-04"
  input Integer bEq;
  input SimCode.BackendMapping map;
  output Integer simEq;
protected
  list<tuple<Integer,list<Integer>>> eqMapping;
algorithm
  SimCode.BACKENDMAPPING(eqMapping=eqMapping) := map;
  ((simEq,_)):= List.getMemberOnTrue(bEq,eqMapping,findBEqs);
end getSimEqsForBackendEqs;

protected function findSimVar"outputs true if the tuple contains mapping information about the SimVar
author:Waurich TUD 2014-04"
  input Integer simVar;
  input tuple<Integer,Integer> varTpl;
  output Boolean b;
protected
  Integer simVar1;
algorithm
  (simVar1,_) := varTpl;
  b := intEq(simVar,simVar1);
end findSimVar;

protected function findBackendVar"outputs true if the tuple contains mapping information about the SimVar
author:Waurich TUD 2014-04"
  input Integer bVar;
  input tuple<Integer,Integer> varTpl;
  output Boolean b;
protected
  Integer bVar1;
algorithm
  (_,bVar1) := varTpl;
  b := intEq(bVar,bVar1);
end findBackendVar;

protected function findSimEqs"outputs true if the tuple contains mapping information about the SimEquation
author:Waurich TUD 2014-04"
  input Integer simEq;
  input tuple<Integer,list<Integer>> eqTpl;
  output Boolean b;
protected
  Integer simEq1;
algorithm
  (simEq1,_) := eqTpl;
  b := intEq(simEq,simEq1);
end findSimEqs;

protected function findBEqs"outputs true if the tuple contains mapping information about the backend equation
author:Waurich TUD 2014-04"
  input Integer bEq;
  input tuple<Integer,list<Integer>> eqTpl;
  output Boolean b;
protected
  list<Integer> bEq1;
algorithm
  (_,bEq1) := eqTpl;
  b := listMember(bEq,bEq1);
end findBEqs;

public function getAssignedCrefsOfSimEq"gets the crefs of the vars that are assigned (the lhs) of the simEqSystems
author:Waurich TUD 2014-05"
  input Integer idx;
  input SimCode.SimCode simCode;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := match(idx,simCode)
    local
      SimCode.SimEqSystem simEqSyst;
      list<SimCode.SimEqSystem> allEqs;
      list<DAE.ComponentRef> crefs;
    case(_,SimCode.SIMCODE(allEquations=allEqs))
      equation
        simEqSyst = List.getMemberOnTrue(idx,allEqs,indexIsEqual);
        crefs = getSimEqSystemCrefsLHS(simEqSyst);
      then crefs;
  end match;
end getAssignedCrefsOfSimEq;

protected function getSimEqSystemCrefsLHS "gets the crefs of the vars that are assigned (the lhs) for a simEqSystem
author:Waurich TUD 2014-05"
  input SimCode.SimEqSystem simEqSys;
  output list<DAE.ComponentRef> crefsOut;
algorithm
  crefsOut := match(simEqSys)
    local
      DAE.Exp lhs;
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs,crefs2;
      list<SimCodeVar.SimVar> simVars;
      list<SimCode.SimEqSystem> residual;
    case(SimCode.SES_RESIDUAL())
      equation
        print("implement SES_RESIDUAL in SimCodeUtil.getSimEqSystemCrefsLHS!\n");
      then {};
    case(SimCode.SES_SIMPLE_ASSIGN(cref=cref))
      then {cref};
    case(SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(cref=cref))
      then {cref};
    case(SimCode.SES_ARRAY_CALL_ASSIGN(lhs=lhs))
      then {Expression.expCref(lhs)};
    case(SimCode.SES_IFEQUATION())
      equation
        print("implement SES_IFEQUATION in SimCodeUtil.getSimEqSystemCrefsLHS!\n");
      then {};
    case(SimCode.SES_ALGORITHM()) equation
      print("implement SES_ALGORITHM in SimCodeUtil.getSimEqSystemCrefsLHS!\n");
    then {};
    case(SimCode.SES_INVERSE_ALGORITHM()) equation
      print("implement SES_INVERSE_ALGORITHM in SimCodeUtil.getSimEqSystemCrefsLHS!\n");
    then {};
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(vars=simVars,residual=residual)))
      equation
        _ = List.flatten(List.map(residual,getSimEqSystemCrefsLHS));
        crefs2 = list(SimCodeFunctionUtil.varName(v) for v in simVars);
      then listAppend(crefs2,crefs2);
    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(crefs=crefs)))
      then crefs;
    case(SimCode.SES_MIXED(discVars=simVars))
      then list(SimCodeFunctionUtil.varName(v) for v in simVars);
    case(SimCode.SES_WHEN(whenStmtLst={BackendDAE.ASSIGN(left=lhs)}))
      equation
        crefs = Expression.getAllCrefs(lhs);
      then crefs;
  end match;
end getSimEqSystemCrefsLHS;

public function replaceSimVarName "updates the name of simVarIn.
author:Waurich TUD 2014-05"
  input DAE.ComponentRef cref;
  input SimCodeVar.SimVar simVarIn;
  output SimCodeVar.SimVar simVarOut = simVarIn;
algorithm
  simVarOut.name := cref;
  simVarOut.arrayCref := ComponentReference.getArrayCref(cref);
end replaceSimVarName;

public function replaceSimVarIndex "updates the index of simVarIn.
author:Waurich TUD 2014-05"
  input Integer idx;
  input SimCodeVar.SimVar simVarIn;
  output SimCodeVar.SimVar simVarOut = simVarIn;
algorithm
  simVarOut.index := idx;
end replaceSimVarIndex;

public function addSimVarToAlgVars
  input SimCodeVar.SimVar simVar;
  input SimCode.SimCode simCodeIn;
  output SimCode.SimCode simCodeOut = simCodeIn;
protected
  SimCode.ModelInfo modelInfo;
  SimCodeVar.SimVars vars;
algorithm
  modelInfo := simCodeOut.modelInfo;
  vars := modelInfo.vars;
  vars.algVars := listAppend(vars.algVars, {simVar});
  modelInfo.vars := vars;
  simCodeOut.modelInfo := modelInfo;
end addSimVarToAlgVars;

public function addSimEqSysToODEquations "adds the given simEqSys to both to allEquations and odeEquations"
  input SimCode.SimEqSystem simEqSys;
  input Integer sysIdx;
  input SimCode.SimCode simCodeIn;
  output SimCode.SimCode simCodeOut = simCodeIn;
protected
  list<SimCode.SimEqSystem> odes;
algorithm
  odes := listGet(simCodeOut.odeEquations, sysIdx);
  odes := simEqSys::odes;
  simCodeOut.odeEquations := List.set(simCodeOut.odeEquations, sysIdx, odes);
  simCodeOut.allEquations := simEqSys::simCodeOut.allEquations;
end addSimEqSysToODEquations;

public function addSimEqSysToInitialEquations"adds the given simEqSys to both to the initialEquations"
  input SimCode.SimEqSystem simEqSys;
  input SimCode.SimCode simCodeIn;
  output SimCode.SimCode simCodeOut = simCodeIn;
algorithm
  simCodeOut.initialEquations := listAppend(simCodeOut.initialEquations, {simEqSys});
end addSimEqSysToInitialEquations;

public function replaceODEandALLequations"replaces both allEquations and odeEquations"
  input list<SimCode.SimEqSystem> allEqs;
  input list<list<SimCode.SimEqSystem>> odeEqs;
  input SimCode.SimCode simCodeIn;
  output SimCode.SimCode simCodeOut = simCodeIn;
algorithm
  simCodeOut.allEquations := allEqs;
  simCodeOut.odeEquations := odeEqs;
end replaceODEandALLequations;

public function replaceModelInfo "replaces the ModelInfo in SimCode"
  input SimCode.ModelInfo modelInfoIn;
  input SimCode.SimCode simCodeIn;
  output SimCode.SimCode simCodeOut = simCodeIn;
algorithm
  simCodeOut.modelInfo := modelInfoIn;
end replaceModelInfo;

public function replaceSimEqSysIndex "updated the index of the given SimEqSysIn.
author:Waurich TUD 2014-05"
  input SimCode.SimEqSystem simEqSysIn;
  input Integer inputIndex;
  output SimCode.SimEqSystem simEqSysOut;
algorithm
    simEqSysOut := match(simEqSysIn)
    local
      SimCode.LinearSystem lSystem;
      SimCode.NonlinearSystem nlSystem;
      SimCode.SimEqSystem simEqSys;

    case (simEqSys as SimCode.SES_RESIDUAL())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;

    case (simEqSys as SimCode.SES_SIMPLE_ASSIGN())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;

    case (simEqSys as SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;

    case (simEqSys as SimCode.SES_ARRAY_CALL_ASSIGN())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;

    case (simEqSys as SimCode.SES_IFEQUATION())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;

    case (simEqSys as SimCode.SES_ALGORITHM())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;

    case (simEqSys as SimCode.SES_INVERSE_ALGORITHM())
      equation
      simEqSys.index = inputIndex;
    then simEqSys;

    // WARNING: dynamic tearing not handled
    case (simEqSys as SimCode.SES_LINEAR(lSystem=lSystem))
      equation
        lSystem.index = inputIndex;
        simEqSys.lSystem = lSystem;
    then simEqSys;

    // WARNING: dynamic tearing not handled
    case (simEqSys as SimCode.SES_NONLINEAR(nlSystem=nlSystem))
      equation
        nlSystem.index = inputIndex;
        simEqSys.nlSystem = nlSystem;
    then simEqSys;

    case (simEqSys as SimCode.SES_MIXED())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;

    case (simEqSys as SimCode.SES_WHEN())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;

    case (simEqSys as SimCode.SES_FOR_LOOP())
      equation
        simEqSys.index = inputIndex;
    then simEqSys;
  end match;
end replaceSimEqSysIndex;

public function getMaxSimEqSystemIndex"gets the maximal index of all simEqSystems in the SimCode.
author:Waurich TUD 2014-06"
  input SimCode.SimCode simCode;
  output Integer idxOut = 0;
protected
  list<SimCode.SimEqSystem> allEquations,jacobianEquations,equationsForZeroCrossings,algorithmAndEquationAsserts,removedEquations,parameterEquations,maxValueEquations,minValueEquations,nominalValueEquations,startValueEquations,initialEquations;
  list<list<SimCode.SimEqSystem>> odeEquations, algebraicEquations;
algorithm
  SimCode.SIMCODE(allEquations = allEquations, odeEquations=odeEquations, algebraicEquations=algebraicEquations, initialEquations=initialEquations,
                  startValueEquations=startValueEquations, nominalValueEquations=nominalValueEquations, minValueEquations=minValueEquations, maxValueEquations=maxValueEquations,
                    parameterEquations=parameterEquations, removedEquations=removedEquations, algorithmAndEquationAsserts=algorithmAndEquationAsserts,
                   equationsForZeroCrossings=equationsForZeroCrossings, jacobianEquations=jacobianEquations) := simCode;
  for eq in jacobianEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in equationsForZeroCrossings loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in algorithmAndEquationAsserts loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in removedEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in parameterEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in maxValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in minValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in nominalValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in nominalValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in startValueEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in initialEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in allEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in jacobianEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in jacobianEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
  for eq in jacobianEquations loop idxOut := intMax(idxOut, simEqSystemIndex(eq)); end for;
end getMaxSimEqSystemIndex;

public function getLSindex"outputs the index of the SES_LINEAR or -1"
  input SimCode.SimEqSystem simEqSys;
  output Integer lsIdx;
algorithm
  lsIdx := match(simEqSys)
    local
      Integer idx;
    case(SimCode.SES_LINEAR(SimCode.LINEARSYSTEM(indexLinearSystem=idx)))
      then idx;
    else
      then -1;
  end match;
end getLSindex;

public function getNLSindex"outputs the index of the SES_NONLINEAR or -1"
  input SimCode.SimEqSystem simEqSys;
  output Integer nlsIdx;
algorithm
  nlsIdx := match(simEqSys)
    local
      Integer idx;
    case(SimCode.SES_NONLINEAR(SimCode.NONLINEARSYSTEM(indexNonLinearSystem=idx)))
      then idx;
    else
      then -1;
  end match;
end getNLSindex;

public function getMixedindex"outputs the index of the SES_MIXED or -1"
  input SimCode.SimEqSystem simEqSys;
  output Integer mIdx;
algorithm
  mIdx := match(simEqSys)
    local
      Integer idx;
    case(SimCode.SES_MIXED(indexMixedSystem=idx))
      then idx;
    else
      then -1;
  end match;
end getMixedindex;

public function getRemovedEquationSimEqSysIdxes"gets the simEqSystem - indeces for teh removedEquations
author: Waurich TUD 2014-07"
  input SimCode.SimCode simCode;
  output list<Integer> simEqSysIdcs;
protected
  list<SimCode.SimEqSystem> remEqs;
algorithm
  SimCode.SIMCODE(removedEquations=remEqs) := simCode;
  simEqSysIdcs := List.map(remEqs,simEqSystemIndex);
end getRemovedEquationSimEqSysIdxes;

public function getDaeEqsNotPartOfOdeSystem "Get a list of eqSystem-objects that are solved in DAE, but not in the ODE-system.
author: marcusw"
  input SimCode.SimCode iSimCode;
  output list<SimCode.SimEqSystem> oEqs;
protected
  array<Option<SimCode.SimEqSystem>> allEqs;
  list<tuple<Integer, SimCode.SimEqSystem>> allEqIdxMapping; //mapping SimEqIdx -> SimEqSystem
  list<SimCode.SimEqSystem> allEquations;
  list<list<SimCode.SimEqSystem>> odeEquations;
  Integer highestIdx;
  list<SimCode.SimEqSystem> tmpEqs;
algorithm
  SimCode.SIMCODE(allEquations=allEquations,odeEquations=odeEquations) := iSimCode;
  ((allEqIdxMapping, highestIdx)) := List.fold(allEquations, getDaeEqsNotPartOfOdeSystem0, ({}, 0));
  allEqs := arrayCreate(highestIdx, NONE());
  allEqs := List.fold(allEqIdxMapping, getDaeEqsNotPartOfOdeSystem1, allEqs);
  allEqs := List.fold(odeEquations, getDaeEqsNotPartOfOdeSystem2, allEqs);
  tmpEqs := {};
  tmpEqs := Array.fold(allEqs, getDaeEqsNotPartOfOdeSystem4, tmpEqs);
  oEqs := Dangerous.listReverseInPlace(tmpEqs);
end getDaeEqsNotPartOfOdeSystem;

protected function getDaeEqsNotPartOfOdeSystem0 "Add the given equation system object to the mapping list (simEqIdx -> SimEqSystem).
author: marcusw"
  input SimCode.SimEqSystem iEqSystem;
  input tuple<list<tuple<Integer, SimCode.SimEqSystem>>, Integer> iMappingWithHighestIdx; //<mapping simEqIdx -> SimEqSystem, highestIdx>
  output tuple<list<tuple<Integer, SimCode.SimEqSystem>>, Integer> outMappingWithHighestIdx;
protected
  Integer index, highestIdx;
  list<tuple<Integer, SimCode.SimEqSystem>> allEqIdxMapping;
algorithm
  index := simEqSystemIndex(iEqSystem);
  (allEqIdxMapping, highestIdx) := iMappingWithHighestIdx;
  allEqIdxMapping := (index, iEqSystem)::allEqIdxMapping;
  highestIdx := intMax(highestIdx, index);
  outMappingWithHighestIdx := (allEqIdxMapping, highestIdx);
end getDaeEqsNotPartOfOdeSystem0;

protected function getDaeEqsNotPartOfOdeSystem1 "Set the array at position simEqIdx to the simEqSystem-object.
author: marcusw"
  input tuple<Integer, SimCode.SimEqSystem> iEqSystem; //<simEqIdx, simEqSystem>
  input array<Option<SimCode.SimEqSystem>> iEqArray;
  output array<Option<SimCode.SimEqSystem>> oEqArray;
protected
  Integer eqSysIdx;
  SimCode.SimEqSystem eqSys;
algorithm
  (eqSysIdx, eqSys) := iEqSystem;
  oEqArray := arrayUpdate(iEqArray, eqSysIdx, SOME(eqSys));
end getDaeEqsNotPartOfOdeSystem1;

protected function getDaeEqsNotPartOfOdeSystem2 "Set the array at position simEqIdx to NONE().
author: marcusw"
  input list<SimCode.SimEqSystem> iEqSystem;
  input array<Option<SimCode.SimEqSystem>> iEqArray;
  output array<Option<SimCode.SimEqSystem>> oEqArray;
algorithm
  oEqArray := List.fold(iEqSystem, getDaeEqsNotPartOfOdeSystem3, iEqArray);
end getDaeEqsNotPartOfOdeSystem2;

protected function getDaeEqsNotPartOfOdeSystem3 "Set the array at position simEqIdx to NONE().
author: marcusw"
  input SimCode.SimEqSystem iEqSystem;
  input array<Option<SimCode.SimEqSystem>> iEqArray;
  output array<Option<SimCode.SimEqSystem>> oEqArray;
protected
  Integer eqSysIdx;
  SimCode.SimEqSystem eqSys;
algorithm
  eqSysIdx := simEqSystemIndex(iEqSystem);
  oEqArray := arrayUpdate(iEqArray, eqSysIdx, NONE());
end getDaeEqsNotPartOfOdeSystem3;

protected function getDaeEqsNotPartOfOdeSystem4 "Append the element to the list if it is not NONE().
author: marcusw"
  input Option<SimCode.SimEqSystem> iEqSystemOpt;
  input list<SimCode.SimEqSystem> iResList;
  output list<SimCode.SimEqSystem> oResList;
protected
  SimCode.SimEqSystem eqSys;
algorithm
  oResList := match(iEqSystemOpt, iResList)
    case(SOME(eqSys), _)
      then eqSys::iResList;
    else
      then iResList;
  end match;
end getDaeEqsNotPartOfOdeSystem4;

public function dumpIdxScVarMapping
  input array<Option<SimCodeVar.SimVar>> iMapping;
algorithm
  print("Idx-ScVar-Mapping:\n");
  _ := Array.fold(iMapping, dumpIdxScVarMapping0, 1);
end dumpIdxScVarMapping;

protected function dumpIdxScVarMapping0
  input Option<SimCodeVar.SimVar> iVar;
  input Integer iIdx;
  output Integer oIdx;
protected
  DAE.ComponentRef name;
  String refString;
algorithm
  oIdx := match(iVar, iIdx)
    case(SOME(SimCodeVar.SIMVAR(name=name)), _)
      equation
        print("Idx: " + intString(iIdx) + " -- ");
        refString = ComponentReference.printComponentRefStr(name);
        print(refString + "\n");
      then iIdx + 1;
    else iIdx + 1;
  end match;
end dumpIdxScVarMapping0;

protected function dumpBackendMapping"dump function for the backendmapping
author:Waurich TUD 2014-04"
  input SimCode.BackendMapping mapIn;
protected
  array<Integer> eqMatch,varMatch;
  array<list<Integer>> tree;
  list<tuple<Integer,list<Integer>>> eqMapping;
  list<tuple<Integer,Integer>> varMapping;
  BackendDAE.IncidenceMatrix m;
  BackendDAE.IncidenceMatrixT mt;
  array<list<SimCodeVar.SimVar>> simVarMapping;
algorithm
  SimCode.BACKENDMAPPING(m=m,mT=mt,eqMapping=eqMapping,varMapping=varMapping,eqMatch=eqMatch,varMatch=varMatch,eqTree=tree,simVarMapping=simVarMapping) := mapIn;
  dumpEqMapping(eqMapping);
  /*
  dumpVarMapping(varMapping);
  print("\nthe incidence Matrix (backendIndices)\n");
  BackendDump.dumpIncidenceMatrix(m);
  BackendDump.dumpIncidenceMatrixT(mt);
  print("\nvars matched to eq (backend indeces)\n");
  BackendDump.dumpMatching(varMatch);
  print("\nequations tree (rows:backendEqs, entrys: list of required backend equations)");
  BackendDump.dumpIncidenceMatrix(tree);
  */
end dumpBackendMapping;

protected function dumpEqMapping"dump function for the equation mapping
author:Waurich TUD 2014-04"
  input list<tuple<Integer,list<Integer>>> eqMapping;
protected
  list<tuple<Integer,list<Integer>>> lst;
  list<String> s;
algorithm
  lst := listReverse(eqMapping);
  print("------------\n");
  print("BackendEquation ---> SimEqSys\n");
  (s,_) := List.mapFold(lst,dumpEqMappingTuple,1);
  print(stringDelimitList(s,"\n"));
  print("\n------------\n");
  print("\n");
end dumpEqMapping;

protected function dumpVarMapping"dump function for the variable mapping.
author:Waurich TUD 2014-04"
  input list<tuple<Integer,Integer>> varMapping;
protected
  list<tuple<Integer,Integer>> lst;
  list<String> s;
algorithm
  lst := listReverse(varMapping);
  print("------------\n");
  print("BackendVar ---> SimVar\n");
  (s,_) := List.mapFold(lst,dumpVarMappingTuple,1);
  print(stringDelimitList(s,"\n"));
  print("\n------------\n");
  print("\n");
end dumpVarMapping;

protected function dumpEqMappingTuple"outputs a string for a equation mapping tuple.
author:Waurich TUD 2014-04"
  input tuple<Integer,list<Integer>> tpl;
  input Integer noIn;
  output String s;
  output Integer noOut;
protected
  Integer i1;
  list<Integer> lst;
algorithm
   (i1,lst) := tpl;
   s := intString(noIn)+"): "+stringDelimitList(List.map(lst,intString),",")+" ---> "+intString(i1);
   noOut := noIn+1;
end dumpEqMappingTuple;

protected function dumpVarMappingTuple"outputs a string for a variable mapping tuple.
author:Waurich TUD 2014-04"
  input tuple<Integer,Integer> tpl;
  input Integer noIn;
  output String s;
  output Integer noOut;
protected
  Integer i1, i2;
algorithm
   (i1,i2) := tpl;
   s := intString(noIn)+"): "+intString(i2)+" ---> "+intString(i1);
   noOut := noIn+1;
end dumpVarMappingTuple;


public function dumpOMSIData
"Outputs a SimCode.OMSIData"
  input SimCode.OMSIData omsiData;
  input String head;
algorithm
  print(head+"\n");

  print("OMSIFunction initialization:\n");
  dumpOMSIFunc(omsiData.initialization,"");

  print("----------------------\n");
  print("OMSIFunction simulation:\n");
  dumpOMSIFunc(omsiData.simulation,"");
end dumpOMSIData;


public function dumpOMSIFunc
"Outputs a SimCode.OMSIFunction"
  input SimCode.OMSIFunction omsiFunc;
  input String head;
algorithm
  print(head+"\n");
  try
    print("equations:\n");
    print("----------------------\n");
    dumpSimEqSystemLst(omsiFunc.equations,"\n");
    dumpVarLst(omsiFunc.inputVars,"inputVars");
    dumpVarLst(omsiFunc.innerVars,"innerVars");
    dumpVarLst(omsiFunc.outputVars,"outputVars");
    print("numer of all vars: " + String(omsiFunc.nAllVars)+"\n");
    print("Context\n");    // ToDo: add dump context
    print("number of algebraic systems: " + String(omsiFunc.nAlgebraicSystems)+"\n");
    else
      print("ERROR in dumpOMSIFunc\n");
  end try;
end dumpOMSIFunc;


public function omsiFuncEqnString
"Outputs a string containing SimCode.OMSIFunction informations"
  input SimCode.OMSIFunction omsiFunc;
  output String s="";
algorithm
  for eqs in omsiFunc.equations loop
    s := s+simEqSystemString(eqs) + "\n";
  end for;
end omsiFuncEqnString;


public function derivativeMatrixString
"Outputs a string containing SimCode.OMSIFunction informations"
  input SimCode.DerivativeMatrix matrix;
  output String s="";
algorithm
  for col in matrix.columns loop
    s := s+omsiFuncEqnString(col);
  end for;
end derivativeMatrixString;


public function createFMIModelStructure
" function detectes the model stucture for FMI 2.0
  by analyzing the symbolic jacobian matrixes and sparsity pattern"
  input BackendDAE.SymbolicJacobians inSymjacs;
  input SimCode.ModelInfo inModelInfo;
  input Integer inUniqueEqIndex;
  output list<SimCode.JacobianMatrix> symJacFMI = {};
  output Option<SimCode.FmiModelStructure> outFmiModelStructure;
  output SimCode.ModelInfo outModelInfo = inModelInfo;
  output list<SimCode.JacobianMatrix> symJacs = {};
  output Integer uniqueEqIndex = inUniqueEqIndex;
protected
   list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> spTA, spTB;
   list<tuple<Integer, list<Integer>>> sparseInts;
   list<SimCode.FmiUnknown> allUnknowns, derivatives, outputs, discreteStates;
   list<SimCodeVar.SimVar> varsA, varsB, clockedStates;
   list<DAE.ComponentRef> diffCrefsA, diffedCrefsA, derdiffCrefsA;
   list<DAE.ComponentRef> diffCrefsB, diffedCrefsB;
   DoubleEndedList<SimCodeVar.SimVar> delst;
   SimCode.VarInfo varInfo;
   Option<BackendDAE.SymbolicJacobian> optcontPartDer;
   BackendDAE.SparsePattern spPattern;
   BackendDAE.SparseColoring spColors;
   BackendDAE.SymbolicJacobians contPartDer;
   SimCode.JacobianMatrix contSimJac;
   Option<SimCode.JacobianMatrix> contPartSimDer;
   list<SimCodeVar.SimVar> tempvars;
   SimCodeVar.SimVars vars;
   SimCode.HashTableCrefToSimVar crefSimVarHT;
   list<Integer> intLst;
algorithm
  try
    //print("Start creating createFMIModelStructure\n");
    // combine the transposed sparse pattern of matrix A and B
    // to obtain dependencies for the derivativesq
    SOME((optcontPartDer, spPattern as (_, spTA, (diffCrefsA, diffedCrefsA),_), spColors)) := SymbolicJacobian.getJacobianMatrixbyName(inSymjacs, "FMIDER");

    crefSimVarHT := createCrefToSimVarHT(inModelInfo);
    //print("-- Got matrixes\n");
    (spTA, derdiffCrefsA) := translateSparsePatterCref2DerCref(spTA, crefSimVarHT, {}, {});
    //print("-- translateSparsePatterCref2DerCref matrixes AB\n");

    // collect all variable
    varsA := getSimVars2Crefs(diffedCrefsA, crefSimVarHT);
    varsB := getSimVars2Crefs(derdiffCrefsA, crefSimVarHT);
    varsA := listAppend(varsA, varsB);
    varsB := getSimVars2Crefs(diffCrefsA, crefSimVarHT);
    varsA := listAppend(varsA, varsB);
    //print("-- created vars for AB\n");
    sparseInts := sortSparsePattern(varsA, spTA, true);
    //print("-- sorted vars for AB\n");
    allUnknowns := translateSparsePatterInts2FMIUnknown(sparseInts, {});

    // get derivatives pattern
    intLst := list(getVariableIndex(v) for v in inModelInfo.vars.derivativeVars);
    derivatives := list(fmiUnknown for fmiUnknown guard(Util.boolOrList(list(isFmiUnknown(i, fmiUnknown) for i in intLst))) in allUnknowns);

    // get output pattern
    varsA := List.filterOnTrue(inModelInfo.vars.algVars, isOutputSimVar);
    intLst := list(getVariableIndex(v) for v in varsA);
    outputs := list(fmiUnknown for fmiUnknown guard(Util.boolOrList(list(isFmiUnknown(i, fmiUnknown) for i in intLst))) in allUnknowns);

    // get discrete states pattern
    clockedStates := List.filterOnTrue(inModelInfo.vars.algVars, isClockedStateSimVar);
    intLst := list(getVariableIndex(v) for v in clockedStates);
    discreteStates := list(fmiUnknown for fmiUnknown guard(Util.boolOrList(list(isFmiUnknown(i, fmiUnknown) for i in intLst))) in allUnknowns);

    // discreteStates
    if not checkForEmptyBDAE(optcontPartDer) then
      contPartDer := {(optcontPartDer,spPattern,spColors)};
      ({contSimJac}, uniqueEqIndex) := createSymbolicJacobianssSimCode(contPartDer, crefSimVarHT, uniqueEqIndex, {"FMIDer"}, {});
      // collect algebraic loops and symjacs for FMIDer
      ({contSimJac}, outModelInfo, symJacs) := addAlgebraicLoopsModelInfoSymJacs({contSimJac}, inModelInfo);
      contPartSimDer := SOME(contSimJac);
      // set partition index to number of clocks (max index) for now
      // TODO: use actual clock indices to support multirate systems
      symJacFMI := {rewriteJacPartIdx(contSimJac, inModelInfo.nSubClocks)};
    else
      contPartSimDer := NONE();
    end if;

    outFmiModelStructure :=
      SOME(
        SimCode.FMIMODELSTRUCTURE(
          SimCode.FMIOUTPUTS(outputs),
          SimCode.FMIDERIVATIVES(derivatives),
          contPartSimDer,
          SimCode.FMIDISCRETESTATES(discreteStates),
          SimCode.FMIINITIALUNKNOWNS({})));
else
  // create empty model structure
  try
    // create empty derivatives dependencies
    derivatives := list(SimCode.FMIUNKNOWN(getVariableIndex(v), {}, {})
                        for v in getScalarVars(inModelInfo.vars.derivativeVars));

    // create empty output dependencies
    varsA := List.filterOnTrue(inModelInfo.vars.algVars, isOutputSimVar);
    outputs := list(SimCode.FMIUNKNOWN(getVariableIndex(v), {}, {})
                    for v in getScalarVars(varsA));

    // create empty clockedStates dependencies
    clockedStates := List.filterOnTrue(inModelInfo.vars.algVars, isClockedStateSimVar);
    discreteStates := list(SimCode.FMIUNKNOWN(getVariableIndex(v), {}, {})
                           for v in getScalarVars(clockedStates));

    contPartSimDer := NONE();

    outFmiModelStructure :=
      SOME(
        SimCode.FMIMODELSTRUCTURE(
          SimCode.FMIOUTPUTS(outputs),
          SimCode.FMIDERIVATIVES(derivatives),
          contPartSimDer,
          SimCode.FMIDISCRETESTATES(discreteStates),
          SimCode.FMIINITIALUNKNOWNS({})));
  else
    Error.addInternalError("SimCodeUtil.createFMIModelStructure failed", sourceInfo());
    fail();
  end try;
end try;
end createFMIModelStructure;

protected function isClockedStateSimVar
"Returns true for discrete state variable, false otherwise."
  input SimCodeVar.SimVar inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (SimCodeVar.SIMVAR(varKind = BackendDAE.CLOCKED_STATE(_))) then true;
    else false;
  end match;
end isClockedStateSimVar;

protected function isOutputSimVar
"Returns true for output variable, false otherwise."
  input SimCodeVar.SimVar inVar;
  output Boolean outBoolean;
algorithm
  outBoolean := match (inVar)
    case (SimCodeVar.SIMVAR(causality = SimCodeVar.OUTPUT())) then true;
    else false;
  end match;
end isOutputSimVar;

protected function isFmiUnknown
  input Integer index;
  input SimCode.FmiUnknown inFMIUnknown;
  output Boolean out;
algorithm
  out := match (inFMIUnknown)
    local
      Integer i;
    case (SimCode.FMIUNKNOWN(index=i)) guard (intEq(i,index))  then true;
    else false;
  end match;
end isFmiUnknown;

protected function translateSparsePatterInts2FMIUnknown
"function translates simVar integers to fmi unknowns."
  input list<tuple<Integer, list<Integer>>> inSparsePattern;
  input list<SimCode.FmiUnknown> inAccum;
  output list<SimCode.FmiUnknown> outFmiUnknown;
algorithm
  outFmiUnknown := match(inSparsePattern, inAccum)
    local
      list<tuple<Integer, list<Integer>>> rest;
      Integer unknown;
      list<Integer> dependencies;
      list<String> dependenciesKind;

    case ({}, _) then listReverse(inAccum);

    case ( ((unknown, dependencies))::rest, _)
      equation
        // for now dependenciesKind is set to dependent
        dependenciesKind = List.fill("dependent", listLength(dependencies));
      then
        translateSparsePatterInts2FMIUnknown(rest, SimCode.FMIUNKNOWN(unknown, dependencies, dependenciesKind)::inAccum);

     end match;
end translateSparsePatterInts2FMIUnknown;

protected function translateSparsePatterCref2DerCref
"function translates the first cref of sparse pattern to der(cref)"
  input list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> sparsePattern;
  input SimCode.HashTableCrefToSimVar inSimVarHT;
  input list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> inAccum;
  input list<DAE.ComponentRef> inAccum2;
  output list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> outSparsePattern;
  output list<DAE.ComponentRef> outDerCrefs;
algorithm
  (outSparsePattern, outDerCrefs) := match(sparsePattern)
    local
      DAE.ComponentRef cref;
      list<DAE.ComponentRef> crefs;
      list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> rest;
      SimCodeVar.SimVar simVar;

    case ({}) then (listReverse(inAccum), listReverse(inAccum2));

    case ( ((cref, crefs))::rest)
      equation
        simVar = BaseHashTable.get(cref, inSimVarHT);
        if BackendVariable.isVarKindState(simVar.varKind) then
          cref = ComponentReference.crefPrefixDer(cref);
        end if;
      then
        translateSparsePatterCref2DerCref(rest, inSimVarHT, (cref, crefs)::inAccum, cref::inAccum2);

  end match;
end translateSparsePatterCref2DerCref;

protected function mergeSparsePatter
  input list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> inA;
  input list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> inB;
  input list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> inAccum;
  output list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> out;
algorithm
  out := match(inA, inB, inAccum)
  local
    list<tuple<DAE.ComponentRef, list<DAE.ComponentRef>>> restA, restB;
    DAE.ComponentRef crefA, crefB;
    list<DAE.ComponentRef> listA, listB, listOut;

    case ( {}, {}, _) then listReverse(inAccum);

    case ( {}, _, _) then inB;

    case ( _, {}, _) then inA;

    case (( (crefA, listA) )::restA, ((crefB, listB))::restB, _)
      equation
        true = ComponentReference.crefEqual(crefA, crefB);
        listOut = List.unionOnTrue(listA, listB, ComponentReference.crefEqual);
      then
         mergeSparsePatter(restA, restB, (crefA,listOut)::inAccum);
   end match;
end mergeSparsePatter;

public function getStateSimVarIndexFromIndex
  input list<SimCodeVar.SimVar> inStateVars;
  input Integer inIndex;
  output Integer outVariableIndex;
protected
  SimCodeVar.SimVar stateVar;
algorithm
  stateVar := listGet(inStateVars, inIndex + 1 - (if (Config.simCodeTarget()=="Cpp" or Config.simCodeTarget()=="omsicpp") then 0 else listLength(inStateVars)) /* SimVar indexes start from zero */);
  outVariableIndex := getVariableIndex(stateVar);
end getStateSimVarIndexFromIndex;

protected
function getNumScalars
  "Get number of elements when rolling out all arrays of a variable list.
   author: rfranke"
  input list<SimCodeVar.SimVar> vars;
  output Integer numScalars;
algorithm
  numScalars := List.applyAndFold(vars, intAdd, getNumElems, 0);
end getNumScalars;

protected
function getNumElems
  "Get number of scalar elements of a variable, rolling out arrays.
   author: rfranke"
  input SimCodeVar.SimVar var;
  output Integer numElems;
algorithm
  numElems := match var
    case SimCodeVar.SIMVAR(type_ = DAE.T_ARRAY()) algorithm
      numElems := 1;
      for i in 1:listLength(var.numArrayElement) loop
        numElems := numElems * stringInt(listGet(var.numArrayElement, i));
      end for;
      then numElems;
    else 1;
  end match;
end getNumElems;

public
function getScalarElements
  "Get scalar elements of an array in row major order. This is
   needed by templates for XML files that only support scalar variables.
   author: rfranke"
  input SimCodeVar.SimVar var;
  output list<SimCodeVar.SimVar> elts;
protected
  list<Integer> dims;
  SimCodeVar.SimVar elt;
  Integer index;
algorithm
  // create list of elements
  elts := match var
  case SimCodeVar.SIMVAR(type_ = DAE.T_ARRAY(), variable_index = SOME(index)) algorithm
    dims := List.map(List.lastN(var.numArrayElement, listLength(var.numArrayElement)), stringInt);
    elt := var;
    elt.type_ := Types.arrayElementType(var.type_);
    elts := fillScalarElements(elt, dims, 1, {}, {});
    elts := setVariableIndexHelper(elts, index);
  then elts;
  else {var};
  end match;
end getScalarElements;

protected
function fillScalarElements
  "Helper for getScalarElements, called recursively for each dimension.
   author: rfranke"
  input SimCodeVar.SimVar eltIn;
  input list<Integer> dims;
  input Integer dimIdx;
  input list<DAE.Subscript> subsIn;
  input output list<SimCodeVar.SimVar> elts;
protected
  SimCodeVar.SimVar elt = eltIn;
  list<DAE.Subscript> subs;
algorithm
  for i in listGet(dims, dimIdx):-1:1 loop
    subs := DAE.INDEX(DAE.ICONST(i)) :: subsIn;
    if dimIdx < listLength(dims) then
      elts := fillScalarElements(eltIn, dims, dimIdx + 1, subs, elts);
    else
      // add subscripts to array element
      subs := listReverse(subs);
      elt.name := ComponentReference.crefSetLastSubs(elt.name, subs);
      // add subscripts to previousName
      _ := match elt
        local
          DAE.ComponentRef cref;
          Boolean fixed;
        case SimCodeVar.SIMVAR(varKind = BackendDAE.CLOCKED_STATE(previousName = cref, isStartFixed = fixed))
        algorithm
          elt.varKind := BackendDAE.CLOCKED_STATE(ComponentReference.crefSetLastSubs(cref, subs), fixed);
        then ();
        else ();
      end match;
      elts := elt :: elts;
    end if;
  end for;
end fillScalarElements;

protected
function getScalarVars
"Expand all arrays in a vector of SimVars. author: rfranke"
  input list<SimCodeVar.SimVar> inVars;
  output list<SimCodeVar.SimVar> outVars;
algorithm
  outVars := {};
  for var in inVars loop
    outVars := listAppend(outVars, getScalarElements(var));
  end for;
end getScalarVars;

public function getVariableIndex
  input SimCodeVar.SimVar inVar;
  output Integer outVariableIndex;
algorithm
  outVariableIndex := match (inVar)
    local
      Integer variableIndex;
    case (SimCodeVar.SIMVAR(variable_index = SOME(variableIndex)))
    then variableIndex;
    else 0;
  end match;
end getVariableIndex;

public function getValueReference
  "returns the value reference of a variable for direct memory access
   considering aliases and array storage order
   author: rfranke and mwalther and vwaurich and sjoelund"
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  input Boolean inElimNegAliases "=false to keep negative alias references";
  output String outValueReference;
algorithm
  outValueReference := match (inSimVar, inElimNegAliases, Config.simCodeTarget())
    local
      SimCodeVar.SimVar simVar;
      DAE.ComponentRef cref;
      String valueReference;
    case (SimCodeVar.SIMVAR(aliasvar = SimCodeVar.NEGATEDALIAS(_)), false, _) then
      getDefaultValueReference(inSimVar, inSimCode.modelInfo.varInfo);
    case (_, _, _) guard(stringEqual(Config.simCodeTarget(), "Cpp")
                         or stringEqual(Config.simCodeTarget(), "omsicpp")
                         or stringEqual(Config.simCodeTarget(), "omsic"))
    algorithm
      // resolve aliases to get multi-dimensional arrays right
      // (this should possibly be done in getVarIndexByMapping?)
      simVar := match inSimVar
        local
          DAE.ComponentRef componentRef;
        case SimCodeVar.SIMVAR(aliasvar = SimCodeVar.ALIAS(varName = cref))
          then cref2simvar(cref, inSimCode);
        case SimCodeVar.SIMVAR(aliasvar = SimCodeVar.NEGATEDALIAS(varName = cref))
          then cref2simvar(cref, inSimCode);
        // resolve pre vars
        case SimCodeVar.SIMVAR(name = DAE.CREF_QUAL(ident=DAE.preNamePrefix, componentRef=componentRef))
          then cref2simvar(componentRef, inSimCode);
        else inSimVar;
      end match;

      valueReference := getVarIndexByMapping(inSimCode.varToArrayIndexMapping, simVar.name, true, "-1");
      if stringEqual(valueReference, "-1") then
        Error.addInternalError("invalid return value from getVarIndexByMapping for " + simVarString(simVar), sourceInfo());
      end if;
      then valueReference;
    case (SimCodeVar.SIMVAR(aliasvar = SimCodeVar.ALIAS(varName = cref)), _, _) then
      getDefaultValueReference(cref2simvar(cref, inSimCode), inSimCode.modelInfo.varInfo);
    else
      getDefaultValueReference(inSimVar, inSimCode.modelInfo.varInfo);
  end match;
end getValueReference;


protected function getDefaultValueReference
  "returns the value reference without consideration of aliases,
   starting from zero for each base type
   author: rfranke"
  input SimCodeVar.SimVar inSimVar;
  input SimCode.VarInfo inVarInfo;
  output String outDefaultValueReference;
protected
  Integer reference;
  Integer numReal = 2*inVarInfo.numStateVars + inVarInfo.numAlgVars + inVarInfo.numDiscreteReal + inVarInfo.numParams + inVarInfo.numAlgAliasVars;
  Integer numInteger = inVarInfo.numIntAlgVars + inVarInfo.numIntParams + inVarInfo.numIntAliasVars;
  Integer numBoolean = inVarInfo.numBoolAlgVars + inVarInfo.numBoolParams + inVarInfo.numBoolAliasVars;
algorithm
  reference := getVariableIndex(inSimVar);
  if reference > numReal + numInteger + numBoolean then
    // String variable
    reference := reference - numReal - numInteger - numBoolean;
  elseif reference > numReal + numInteger then
    // Boolean variable
    reference := reference - numReal - numInteger;
  elseif reference > numReal then
    // Integer variable
    reference := reference - numReal;
  elseif reference < 1 then
    Error.addInternalError("invalid return value from getVariableIndex", sourceInfo());
  end if;
  outDefaultValueReference := String(reference - 1);
end getDefaultValueReference;


public function getLocalValueReference
 "returns the local value reference of current OMSIFuncton of a variable for
  direct memory access considering aliases and array storage order."
  input SimCodeVar.SimVar inSimVar;
  input SimCode.SimCode inSimCode;
  input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
  input Boolean inElimNegAliases "=false to keep negative alias references";
  output String outValueReference;
algorithm
  outValueReference := matchcontinue (inSimVar, inElimNegAliases, inCrefToSimVarHT)
    local
      DAE.ComponentRef cref;
      String valueReference;
      HashTableCrefSimVar.HashTable crefToSimVarHT;

    // default case
    case (SimCodeVar.SIMVAR(name=cref), _, crefToSimVarHT)
    algorithm
      valueReference := localCref2Index(cref, crefToSimVarHT);
      // if localy no index was found search globaly
      if stringEqual(valueReference, "-1") then
        valueReference := getValueReference(inSimVar, inSimCode, inElimNegAliases);
      end if;
      then valueReference;
    else
      algorithm
      Error.addInternalError("getLocalValueReference failed.", sourceInfo());
      then "ERROR: getLocalValueReference failed";
  end matchcontinue;
end getLocalValueReference;


protected function getHighestDerivation"computes the highest derivative among all states. this includes derivatives of derivatives as well
author: waurich TUD 2015-05"
  input BackendDAE.BackendDAE inDAE;
  output Integer highestDerivation;
protected
  list<BackendDAE.Var> vars, states;
  list<Integer> idcs;
  array<Integer> ders, depth;
  BackendDAE.Variables allStates;
  BackendDAE.Var var;
  Integer index, pos, length, curIndex;
  DAE.ComponentRef derCref;
algorithm
  vars := BackendDAEUtil.getAllVarLst(inDAE);
  states := List.filterOnTrue(vars, BackendVariable.isStateVar);
  length := listLength(states);
  if length==0 then
    highestDerivation := 0;
    return;
  end if;
  ders := arrayCreate(length,-1 /* Has no derivative */);
  depth := arrayCreate(length,-1 /* Not visited */);
  allStates := BackendVariable.listVar1(states);
  // Setup data structures for a dynamic programming algorithm
  curIndex := 1;
  for state in states loop
    // (_, {curIndex}) := BackendVariable.getVar(state.varName, allStates); // They are all already in order
    _ := matchcontinue state
      case BackendDAE.VAR(varKind=BackendDAE.STATE(index=index /* TODO: Do we need the number of times it was differentiated? */, derName = SOME(derCref)))
        algorithm
          (var,pos) := BackendVariable.getVarSingle(derCref, allStates);
          if not BackendVariable.varEqual(state, var) then
            arrayUpdate(ders, curIndex, pos);
          else
            arrayUpdate(depth, curIndex, 0);
          end if;
        then ();
      case BackendDAE.VAR()
        algorithm
          arrayUpdate(depth, curIndex, 0);
        then ();
    end matchcontinue;
    curIndex := curIndex+1;
  end for;
  // Visit all states, calculating the depth of each one, remembering the result
  for i in 1:length loop
    getHighestDerivationVisit(i, ders, depth);
  end for;
  highestDerivation := max(i for i in depth);
  GC.free(ders);
  GC.free(depth);
end getHighestDerivation;

protected function getHighestDerivationVisit "Uses stack depth of at most max depth"
  input Integer i;
  input array<Integer> ders;
  input array<Integer> depth;
  output Integer d=arrayGet(depth, i);
algorithm
  if d >= 0 then
    return;
  elseif d == -2 then
    d := 0;
    return;
  end if;
  arrayUpdate(depth, i, -2);
  d := getHighestDerivationVisit(arrayGet(ders,i), ders, depth);
  arrayUpdate(depth, i, d);
end getHighestDerivationVisit;

protected function hasLargeEquationSystems "Returns true if the model contains large linear or nonlinear equation
systems that are crucial for performance. If the model has a large linear or nonlinear system, the use of Lapack is prefered.
Otherwise the use of dgesv (OMCompiler/3rdParty/) is prefered.
author: marcusw, mflehmig TUD 2015-12"
  input BackendDAE.BackendDAE iDlow "simulation";
  input BackendDAE.BackendDAE iInitDAE "initialization";
  output Boolean oHasLargeEqSystem;
protected
  Boolean hasLargeEqSystem = false;
  list<BackendDAE.EqSystem> eqs = {};
algorithm
  BackendDAE.DAE(eqs=eqs) := iDlow;
  for eqsys in eqs loop
    if(boolNot(hasLargeEqSystem)) then
      hasLargeEqSystem := hasLargeEquationSystems1(BackendDAEUtil.getStrongComponents(eqsys));
    end if;
  end for;

  // If we found a large system, we do not need to search in iInitDAE.
  if(boolNot(hasLargeEqSystem)) then
    BackendDAE.DAE(eqs=eqs) := iInitDAE;
    for eqsys in eqs loop
      if(boolNot(hasLargeEqSystem)) then
        hasLargeEqSystem := hasLargeEquationSystems1(BackendDAEUtil.getStrongComponents(eqsys));
      end if;
    end for;
  end if;

  // Output information if flag dump_dgesv is set.
  if(Flags.isSet(Flags.DUMP_DGESV)) then
    if(boolNot(hasLargeEqSystem)) then
      print("This model has no large linear or nonlinear equation system, thus the use of dgesv (OMCompiler/3rdParty/) is prefered.\n");
    else
      print("This model has at least one large or nonlinear linear equation system, thus the use of Lapack is prefered.\n");
    end if;
  end if;

  oHasLargeEqSystem := hasLargeEqSystem;
end hasLargeEquationSystems;

protected function hasLargeEquationSystems1 "Helper function, that really returns true if the model
contains large linear or non-linear equation systems that are crucial for performance. Heuristic value: 10.
author: marcusw, mflehmig TUD 2015-12"
  input BackendDAE.StrongComponents iComps;
  output Boolean oHasLargeEquationSystems;
protected
  Boolean hasLargeEqSystem = false;
  list<Integer> vars;
algorithm
  for comp in iComps loop
    if(boolNot(hasLargeEqSystem)) then
      if(boolOr(BackendDAEUtil.isLinearEqSystemComp(comp), BackendDAEUtil.isNonLinearEqSystemComp(comp))) then
        BackendDAE.EQUATIONSYSTEM(vars=vars) := comp;
        hasLargeEqSystem := intGt(listLength(vars), 10);
        //print("DGESV1: " + intString(listLength(vars)) + "\n");
      else
        if(boolOr(BackendDAEUtil.isLinearTornSystemComp(comp), BackendDAEUtil.isNonLinearTornSystemComp(comp))) then
          BackendDAE.TORNSYSTEM(BackendDAE.TEARINGSET(tearingvars=vars)) := comp;
          hasLargeEqSystem := intGt(listLength(vars), 10);
          //print("DGESV2: " + intString(listLength(vars)) + "\n");
        end if;
      end if;
    end if;
  end for;
  oHasLargeEquationSystems := hasLargeEqSystem;
end hasLargeEquationSystems1;


protected function createSimVarsForSensitivities
"Function create variables for sensitivities calculation. It creates for every
 state Np(=size of real primary parameters) variables.
"
  input list<SimCodeVar.SimVar> inStateSimVars;
  input list<SimCodeVar.SimVar> inParamSimVars;
  input Integer nFixedParameters;
  output list<SimCodeVar.SimVar> outSimCodeVars;
  output Integer countSensitivityParams = 0;
protected
  constant Boolean debug = false;
  BackendDAE.Variables tmpVariables, emptyVars;
  BackendDAE.Var var;
  Integer i;
  DAE.ComponentRef cref;
  list<SimCodeVar.SimVar> sensitivityParams = {};
algorithm
  emptyVars := BackendVariable.emptyVars();
  tmpVariables := BackendVariable.emptyVarsSized(listLength(inStateSimVars)*nFixedParameters);

  for param in inParamSimVars loop
    // take for now only parameters that are changeable and topLevel
    if param.isValueChangeable and ComponentReference.crefIsIdent(param.name) then
      countSensitivityParams := countSensitivityParams+1;
      sensitivityParams := param::sensitivityParams;
      for state in inStateSimVars loop
        // create cref
        cref := ComponentReference.makeCrefIdent("$Sensitivities", DAE.T_REAL_DEFAULT, {});
        cref := ComponentReference.joinCrefs(cref, param.name);
        cref := ComponentReference.joinCrefs(cref, state.name);

        if debug then
          print("createSimVarsForSensitivities for Var: " + ComponentReference.crefStr(cref) + "\n");
        end if;
        // create var
        var := BackendVariable.makeVar(cref);

        // add var to varibales
        tmpVariables := BackendVariable.addNewVar(var, tmpVariables);
      end for;
    end if;
  end for;
  // generate SimCode vars
  ((outSimCodeVars, _)) :=  BackendVariable.traverseBackendDAEVars(tmpVariables, traversingdlowvarToSimvar, ({}, emptyVars));
  outSimCodeVars := listReverse(outSimCodeVars);
  outSimCodeVars := listAppend(listReverse(sensitivityParams), outSimCodeVars);
end createSimVarsForSensitivities;

/*****************************************************************************************************
        FMU EXPERIMENTAL
        author: F. Bergero. 12/10/2015
*****************************************************************************************************/

function getNLSysRHS
    input list<SimCode.SimEqSystem> eqs;
    input list<DAE.ComponentRef> res ;
    output list<DAE.ComponentRef> unknowns;
algorithm
    unknowns := matchcontinue (eqs,res)
        local list<SimCode.SimEqSystem> tail;
              SimCode.SimEqSystem head;
              DAE.Exp exp;
        case ({},_)
            then res;
        case (SimCode.SES_RESIDUAL(exp=exp) :: tail,_)
            then getNLSysRHS(tail,listAppend(res,Expression.getAllCrefs(exp)));
        case (_,)
            equation
                print("getNLSysRHS failed\n");
            then
                fail();
    end matchcontinue;
end getNLSysRHS;


function computeDependenciesHelper
    input list<SimCode.SimEqSystem> eqs;
    input list<DAE.ComponentRef> unknowns;
    input list<SimCode.SimEqSystem> res;
    output list<SimCode.SimEqSystem> deps;
algorithm
    deps := matchcontinue (eqs,unknowns,res)
        local list<SimCode.SimEqSystem> tail;
              SimCode.SimEqSystem head;
              list<DAE.ComponentRef> new_unknowns;
              list<SimCode.SimEqSystem> r;
              DAE.ComponentRef cref;
              list<SimCodeVar.SimVar> vars;
              list<DAE.ComponentRef> linsys_unk;
              list<DAE.ComponentRef> nlsys_unk;
              list<SimCode.SimEqSystem> nlsys_eqs;
              DAE.Exp exp;
              list<DAE.Exp> beqs;
    case ({},_,r)
        then r;
    case ( (head as SimCode.SES_SIMPLE_ASSIGN(cref=cref,exp=exp))::tail,_,r)
        equation
            true = List.isMemberOnTrue(cref,unknowns,ComponentReference.crefEqual);
            // We must include this equation in the ODE
            new_unknowns = Expression.getAllCrefs(exp);
            // And include all those one defining the RHS
        then computeDependenciesHelper(tail,listAppend(unknowns,new_unknowns), listAppend(r,{head}));
    case ( (head as SimCode.SES_SIMPLE_ASSIGN_CONSTRAINTS(cref=cref,exp=exp))::tail,_,r)
        equation
            true = List.isMemberOnTrue(cref,unknowns,ComponentReference.crefEqual);
            // We must include this equation in the ODE
            new_unknowns = Expression.getAllCrefs(exp);
            // And include all those one defining the RHS
        then computeDependenciesHelper(tail,listAppend(unknowns,new_unknowns), listAppend(r,{head}));
    case ( (head as SimCode.SES_LINEAR(lSystem = SimCode.LINEARSYSTEM( beqs=beqs)))::tail,_, r)
        equation
            // This linear system defines the following crefs
            linsys_unk = getSimEqSystemCrefsLHS(head);
            // If any of those are in our unkowns me must include this equation system
            false = listEmpty(List.intersectionOnTrue(linsys_unk,unknowns,ComponentReference.crefEqual));
            // And include all the variables of the RHS to the unkowns
            new_unknowns = List.flatten(List.map(beqs, Expression.getAllCrefs));
        then computeDependenciesHelper(tail,listAppend(unknowns,new_unknowns),listAppend(r,{head}));
    case ( (head as SimCode.SES_NONLINEAR(nlSystem=SimCode.NONLINEARSYSTEM(crefs=nlsys_unk, eqs=nlsys_eqs)))::tail,_,r)
        equation
        // If any of the uknwonw of the NL system are in our unkowns me must include this equation system
        false = listEmpty(List.intersectionOnTrue(nlsys_unk,unknowns,ComponentReference.crefEqual));
        new_unknowns = getNLSysRHS(nlsys_eqs,{});
        then computeDependenciesHelper(tail,listAppend(unknowns,new_unknowns),listAppend(r,{head}));
    case (_::tail,_,r)
        then  computeDependenciesHelper(tail,unknowns,r);
    end matchcontinue;
end computeDependenciesHelper;

public function computeDependencies
    input list<SimCode.SimEqSystem> eqs;
    input DAE.ComponentRef cref;
    output list<SimCode.SimEqSystem> deps;
algorithm
    deps := match (eqs,cref)
    case (_,_)
        then listReverse(computeDependenciesHelper(listReverse(eqs),{cref},{}));
    end match;
end computeDependencies;

public function getSimEqSystemsByIndexLst
  input list<Integer> idcs;
  input list<SimCode.SimEqSystem> allSes;
  output list<SimCode.SimEqSystem> sesOut;
algorithm
  sesOut := List.map1(idcs,getSimEqSysForIndex,allSes);
end getSimEqSystemsByIndexLst;

public function getInputIndex
  input SimCodeVar.SimVar var;
  output Integer inputIndex;
protected
  array<Integer> v;
algorithm
  inputIndex := match var
    case SimCodeVar.SIMVAR(inputIndex=SOME(v)) guard arrayLength(v)==1 then arrayGet(v, 1);
    case SimCodeVar.SIMVAR(inputIndex=SOME(_))
      algorithm
        Error.addInternalError("Failed to SimCodeUtil.getInputIndex of variable", sourceInfo());
      then fail();
    else -1;
  end match;
end getInputIndex;

public function resetFunctionIndex
algorithm
  setGlobalRoot(Global.codegenFunctionList, DoubleEndedList.fromList({}));
end resetFunctionIndex;

public function addFunctionIndex
  input String prefix, suffix;
  output String newName;
protected
  DoubleEndedList<String> delst;
algorithm
  delst := getGlobalRoot(Global.codegenFunctionList);
  newName := prefix + String(DoubleEndedList.length(delst)) + suffix;
  DoubleEndedList.push_back(delst, newName);
end addFunctionIndex;

public function getFunctionIndex
  output list<String> files;
protected
  DoubleEndedList<String> delst;
algorithm
  delst := getGlobalRoot(Global.codegenFunctionList);
  files := DoubleEndedList.toListAndClear(delst);
end getFunctionIndex;

public function nVariablesReal
  input SimCode.VarInfo varInfo;
  output Integer n;
algorithm
  n := 2*varInfo.numStateVars+varInfo.numAlgVars+varInfo.numDiscreteReal+varInfo.numOptimizeConstraints+varInfo.numOptimizeFinalConstraints;
end nVariablesReal;


public function getSimCode
  output SimCode.SimCode code;
protected
  Option<SimCode.SimCode> ocode;
algorithm
  ocode := getGlobalRoot(Global.optionSimCode);
  code := match ocode
    case SOME(code) then code;
    else algorithm Error.addInternalError("Tried to generate code that requires the SimCode structure, but this is not set (function context?)", sourceInfo()); then fail();
  end match;
end getSimCode;

public function cref2simvar
"Used by templates to find SIMVAR for given cref (to gain representaion index info mainly)."
  input DAE.ComponentRef inCref;
  input SimCode.SimCode simCode;
  output SimCodeVar.SimVar outSimVar;
protected
  HashTableCrefSimVar.HashTable crefToSimVarHT;
  DAE.ComponentRef badcref;
algorithm
  try
    SimCode.SIMCODE(crefToSimVarHT = crefToSimVarHT)  := simCode;
    outSimVar := simVarFromHT(inCref, crefToSimVarHT);
  else
    //print("cref2simvar: " + ComponentReference.printComponentRefStr(inCref) + " not found!\n");
    badcref := ComponentReference.makeCrefIdent("ERROR_cref2simvar_failed " + ComponentReference.printComponentRefStr(inCref), DAE.T_REAL_DEFAULT, {});
    outSimVar := SimCodeVar.SIMVAR(badcref, BackendDAE.VARIABLE(), "", "", "", -2, NONE(), NONE(), NONE(), NONE(), false, DAE.T_REAL_DEFAULT, false, NONE(), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SimCodeVar.INTERNAL(), NONE(), {}, false, true, false, NONE(), NONE());
  end try;
end cref2simvar;

public function simVarFromHT
"Used by templates to find SIMVAR for given cref (to gain representaion index info mainly)."
  input DAE.ComponentRef inCref;
  input HashTableCrefSimVar.HashTable crefToSimVarHT;
  output SimCodeVar.SimVar outSimVar;
protected
  DAE.ComponentRef cref, badcref;
  SimCodeVar.SimVar sv;
  list<DAE.Subscript> subs;
  Integer index;
algorithm
  try
    if BaseHashTable.hasKey(inCref, crefToSimVarHT) then
      sv := BaseHashTable.get(inCref, crefToSimVarHT);
    else
      // lookup array variable and add offset for array element
      if Flags.isSet(Flags.NF_SCALARIZE) then
        sv := BaseHashTable.get(ComponentReference.crefStripLastSubs(inCref), crefToSimVarHT);
        subs := ComponentReference.crefLastSubs(inCref);
        sv.name := ComponentReference.crefSetLastSubs(sv.name, subs);
      else
        sv := BaseHashTable.get(ComponentReference.crefStripSubs(inCref), crefToSimVarHT);
        subs := ComponentReference.crefSubs(inCref);
        sv.name := ComponentReference.crefApplySubs(sv.name, subs);
      end if;

      sv.variable_index := match sv.variable_index
        case SOME(index)
        then SOME(index + getScalarElementIndex(subs, List.map(sv.numArrayElement, stringInt)) - 1);
      end match;
    end if;
    sv := match sv.aliasvar
      case SimCodeVar.NOALIAS() then sv;
      case SimCodeVar.ALIAS(varName=cref) then simVarFromHT(cref, crefToSimVarHT); /* Possibly not needed; can't really hurt that much though */
      case SimCodeVar.NEGATEDALIAS() then sv;
    end match;
  else
    //print("cref2simvar: " + ComponentReference.printComponentRefStr(inCref) + " not found!\n");
    badcref := ComponentReference.makeCrefIdent("ERROR_cref2simvar_failed " + ComponentReference.printComponentRefStr(inCref), DAE.T_REAL_DEFAULT, {});
    sv := SimCodeVar.SIMVAR(badcref, BackendDAE.VARIABLE(), "", "", "", -2, NONE(), NONE(), NONE(), NONE(), false, DAE.T_REAL_DEFAULT, false, NONE(), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SimCodeVar.INTERNAL(), NONE(), {}, false, true, false, NONE(), NONE());
  end try;
  outSimVar := sv;
end simVarFromHT;

public function createJacContext
  input Option<HashTableCrefSimVar.HashTable> jacHT;
  output SimCodeFunction.Context outContext;
algorithm
  outContext := SimCodeFunction.JACOBIAN_CONTEXT(jacHT);
end createJacContext;


public function localCref2SimVar
"Used by templates to find SIMVAR in given hashTable for given cref
 (to gain representaion index info mainly). Does not check if variable is alias."
  input DAE.ComponentRef inCref;
  input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
  output SimCodeVar.SimVar outSimVar;
algorithm
  outSimVar := matchcontinue (inCref, inCrefToSimVarHT)
    local
      DAE.ComponentRef cref, badcref;
      SimCodeVar.SimVar sv;
      SimCode.HashTableCrefSimVar.HashTable crefToSimVarHT;
    case (cref, crefToSimVarHT)
      equation
        sv = BaseHashTable.get(cref, crefToSimVarHT);
      then sv;

    case (_,_)
      equation
        badcref = ComponentReference.makeCrefIdent("ERROR_localCref2SimVar_failed " + ComponentReference.printComponentRefStr(inCref), DAE.T_REAL_DEFAULT, {});
        then SimCodeVar.SIMVAR(badcref, BackendDAE.VARIABLE(), "", "", "", -2, NONE(), NONE(), NONE(), NONE(), false, DAE.T_REAL_DEFAULT, false, NONE(), SimCodeVar.NOALIAS(), DAE.emptyElementSource, SimCodeVar.INTERNAL(), NONE(), {}, false, true, false, NONE(), NONE());
  end matchcontinue;
end localCref2SimVar;


public function localCref2Index
"Finds local value reference for given cref and hash table"
  input DAE.ComponentRef inCref;
  input HashTableCrefSimVar.HashTable inCrefToSimVarHT;
  output String outIndex;
algorithm
  outIndex:= matchcontinue (inCref, inCrefToSimVarHT)
    local
      DAE.ComponentRef cref;
      HashTableCrefSimVar.HashTable crefToSimVarHT;
      SimCodeVar.SimVar sv;
    case (cref, crefToSimVarHT)
      equation
        sv = BaseHashTable.get(cref, crefToSimVarHT);
      then String(sv.index);
    else
      then "-1";
  end matchcontinue;
end localCref2Index;


public function codegenExpSanityCheck "Handle some things that Susan cannot handle:
* Expand simulation context arrays that contain variables stored in different locations...
* We could move collapsing arrays here since it should be safer to do so when we can lookup which index a variable corresponds to...
"
  input output DAE.Exp e;
  input SimCodeFunction.Context context;
protected
  list<SimCodeVar.SimVar> vars;
  SimCode.SimCode simCode;
  Integer index;
algorithm
  if match context
    case SimCodeFunction.FUNCTION_CONTEXT() then true;
    case SimCodeFunction.PARALLEL_FUNCTION_CONTEXT() then true;
    else false; end match
  then
    return;
  end if;
  e := match e
    case DAE.CREF(ty=DAE.T_ARRAY())
      algorithm
        simCode := getSimCode();
        vars := list(cref2simvar(cr, simCode) for cr in ComponentReference.expandCref(e.componentRef, true));
        if not listEmpty(vars) then
          SimCodeVar.SIMVAR(index=index)::vars := vars;
          for v in vars loop
            // The array needs to be expanded because it's not stored in contiguous memory
            if v.index <> index+1 then
              e := Expression.expandCrefs(e);
              break;
            end if;
            index := v.index;
          end for;
        end if;
      then e;
    else e;
  end match;
end codegenExpSanityCheck;

public function isModelTooBigForCSharpInOneFile
"Used by C# template to determine if the generated code should be split into several files
 to make Visual Studio responsive when the file is opened (C# compiler is OK,
 but VS does not scale well for big C# files)."
  input SimCode.SimCode simCode;
  output Boolean outIsTooBig;
algorithm
  outIsTooBig := match(simCode)
    local
      Integer numAlgVars;

    case (SimCode.SIMCODE(modelInfo = SimCode.MODELINFO(varInfo = SimCode.VARINFO(numAlgVars = numAlgVars))))
      equation
        outIsTooBig = numAlgVars > 1000;
      then outIsTooBig;

  end match;
end isModelTooBigForCSharpInOneFile;

public function absoluteClockIdxForBaseClock
  input Integer baseClockIdx; // one-based
  input list<SimCode.ClockedPartition> allBaseClockPartitions;
  output Integer absBaseClockIdx;
protected
  Integer i = 1;
algorithm
  absBaseClockIdx := 1;
  while i < baseClockIdx loop
    absBaseClockIdx := absBaseClockIdx + listLength(getSubPartition(listGet(allBaseClockPartitions,i)));
    i := i+1;
  end while;
end absoluteClockIdxForBaseClock;

public function getClockedPartitions
  input SimCode.SimCode simcode;
  output list<SimCode.ClockedPartition> clockedPartitions;
algorithm
   clockedPartitions := simcode.clockedPartitions;
end getClockedPartitions;

public function isScalarLiteralAssignment
  input SimCode.SimEqSystem eq;
  output Boolean b;
algorithm
  b := match eq
    case SimCode.SES_SIMPLE_ASSIGN() then Expression.isSimpleLiteralValue(eq.exp);
    else false;
  end match;
end isScalarLiteralAssignment;

public function selectScalarLiteralAssignments
  input output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := list(e for e guard isScalarLiteralAssignment(e) in eqs);
end selectScalarLiteralAssignments;

public function filterScalarLiteralAssignments
  input output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := list(e for e guard not isScalarLiteralAssignment(e) in eqs);
end filterScalarLiteralAssignments;

public function sortSimpleAssignmentBasedOnLhs
  input output list<SimCode.SimEqSystem> eqs;
algorithm
  eqs := List.sort(eqs, function lhsGreaterThan(simCode=getSimCode()));
end sortSimpleAssignmentBasedOnLhs;

protected function lhsGreaterThan
  input SimCode.SimEqSystem eq1,eq2;
  input SimCode.SimCode simCode;
  output Boolean b;
algorithm
  b := match (eq1,eq2)
    case (SimCode.SES_SIMPLE_ASSIGN(),SimCode.SES_SIMPLE_ASSIGN())
      then simvarGraterThan(cref2simvar(eq1.cref, simCode), cref2simvar(eq2.cref, simCode));
    else false;
  end match;
end lhsGreaterThan;

protected function simvarGraterThan
  input SimCodeVar.SimVar v1,v2;
  output Boolean b;
protected
  Integer t1,t2,k1,k2;
  // Sort according to type, varkind, index
algorithm
  k1 := valueConstructor(v1.varKind);
  k2 := valueConstructor(v2.varKind);
  t1 := valueConstructor(v1.type_);
  t2 := valueConstructor(v2.type_);
  b := if t1==t2 then
    (if k1==k2 then v1.index > v2.index else k1>k2)
    else t1>t2;
end simvarGraterThan;

public function getNumContinuousEquations
    input list<SimCode.SimEqSystem> eqns;
    input Integer numStates;
    output Integer n;
    protected
    Integer numEqns =0;
    algorithm
    for eqn in eqns loop

    numEqns := match(eqn)
      local
       SimCode.LinearSystem ls;
       SimCode.NonlinearSystem nls;
      case  SimCode.SES_LINEAR(lSystem = ls as SimCode.LINEARSYSTEM(__)) equation
        numEqns = numEqns + listLength(ls.vars);
        then numEqns;
      case  SimCode.SES_NONLINEAR(nlSystem = nls as SimCode.NONLINEARSYSTEM(__)) equation
       numEqns = numEqns + listLength(nls.crefs);
       then numEqns;
      else numEqns;
      end match;
    end for;
    n:=numEqns+numStates;
  end getNumContinuousEquations;


public function sortCrefBasedOnSimCodeIndex
  input output list<DAE.ComponentRef> crs;
  input SimCode.SimCode simCode;
algorithm
  crs := List.sort(crs, function crefSimCodeIndexGreaterThan(simCode=simCode));
end sortCrefBasedOnSimCodeIndex;

protected function crefSimCodeIndexGreaterThan
  input DAE.ComponentRef cr1, cr2;
  input SimCode.SimCode simCode;
  output Boolean b;
protected
  SimCodeVar.SimVar v1, v2;
algorithm
  v1 := cref2simvar(cr1, simCode);
  v2 := cref2simvar(cr2, simCode);
  b := simvarGraterThan(v1, v2);
end crefSimCodeIndexGreaterThan;

public function lookupVR
  input DAE.ComponentRef cr;
  input SimCode.SimCode simCode;
  output Integer vr;
algorithm
  vr := AvlTreeCRToInt.get(simCode.valueReferences, cr);
end lookupVR;

protected function getValueReferenceMapping
  input SimCode.ModelInfo modelInfo;
  output AvlTreeCRToInt.Tree tree;
protected
  Integer i;
  SimCodeVar.SimVars vars;
algorithm
  tree := AvlTreeCRToInt.EMPTY();
  vars := modelInfo.vars;
  (i,tree) := getValueReferenceMapping2(vars.stateVars, 0, tree);
  (i,tree) := getValueReferenceMapping2(vars.derivativeVars, i, tree);
  (i,tree) := getValueReferenceMapping2(vars.algVars, i, tree);
  (i,tree) := getValueReferenceMapping2(vars.discreteAlgVars, i, tree);
  (i,tree) := getValueReferenceMapping2(vars.paramVars, i, tree);
  (i,tree) := getValueReferenceMapping2(vars.aliasVars, i, tree);

  (i,tree) := getValueReferenceMapping2(vars.intAlgVars, 0, tree);
  (i,tree) := getValueReferenceMapping2(vars.intParamVars, i, tree);
  (i,tree) := getValueReferenceMapping2(vars.intAliasVars, i, tree);

  (i,tree) := getValueReferenceMapping2(vars.boolAlgVars, 0, tree);
  (i,tree) := getValueReferenceMapping2(vars.boolParamVars, i, tree);
  (i,tree) := getValueReferenceMapping2(vars.boolAliasVars, i, tree);

  (i,tree) := getValueReferenceMapping2(vars.stringAlgVars, 0, tree);
  (i,tree) := getValueReferenceMapping2(vars.stringParamVars, i, tree);
  (i,tree) := getValueReferenceMapping2(vars.stringAliasVars, i, tree);
end getValueReferenceMapping;

protected function getValueReferenceMapping2
  input list<SimCodeVar.SimVar> vars;
  input output Integer i;
  input output AvlTreeCRToInt.Tree tree;
algorithm
  for v in vars loop
    tree := AvlTreeCRToInt.add(tree, v.name, i);
    i := i + 1;
  end for;
end getValueReferenceMapping2;

function getResources
  input list<Absyn.Class> classes;
  input BackendDAE.BackendDAE dlow1, dlow2;
  output list<String> resources;
protected
  AvlSetString.Tree tree;
  list<DAE.Function> fns;
  Mutable<Boolean> unknownUri;
partial function Func
  input output DAE.Exp e;
  input output AvlSetString.Tree tree;
end Func;
  Func f1, f2;
  String file;
algorithm
  fns := DAEUtil.getFunctionList(dlow1.shared.functionTree);
  tree := AvlSetString.EMPTY();
  unknownUri := Mutable.create(false);
  f1 := function findResources(unknownUri=unknownUri);
  f2 := function Expression.traverseSubexpressions(func=f1);
  (_,tree) := DAEUtil.traverseDAEFunctions(fns, f2, tree);
  tree := BackendDAEUtil.traverseBackendDAEExpsNoCopyWithUpdate(dlow1, f2, tree);
  tree := BackendDAEUtil.traverseBackendDAEExpsNoCopyWithUpdate(dlow2, f2, tree);
  resources := AvlSetString.listKeys(tree);
  if Mutable.access(unknownUri) then
    for cl in classes loop
      file := cl.info.fileName;
      if System.basename(file)=="package.mo" then
        resources:=System.dirname(file)::resources;
      end if;
    end for;
  end if;
end getResources;

function findResources
  "Finds all literal expressions in the DAE"
  input output DAE.Exp e;
  input output AvlSetString.Tree tree;
  input Mutable<Boolean> unknownUri;
protected
  String f;
algorithm
  tree := match e
    case DAE.CALL(path=Absyn.IDENT("OpenModelica_fmuLoadResource"), expLst={DAE.SCONST(f)}) then AvlSetString.add(tree, f);
    case DAE.CALL(path=Absyn.IDENT("OpenModelica_uriToFilename")) algorithm Mutable.update(unknownUri, true); then tree;
    else tree;
  end match;
end findResources;

function aliasSimEqSystems
  input output list<list<SimCode.SimEqSystem>> eqs;
  input output HashTableSimCodeEqCache.HashTable cache;
algorithm
  (eqs, cache) := List.mapFold(eqs, aliasSimEqs, cache);
end aliasSimEqSystems;

function aliasSimEqs
  input output list<SimCode.SimEqSystem> eqs;
  input output HashTableSimCodeEqCache.HashTable cache;
algorithm
  (eqs, cache) := List.mapFold(eqs, aliasSimEq, cache);
end aliasSimEqs;

function aliasSimEq
  input output SimCode.SimEqSystem eq;
  input output HashTableSimCodeEqCache.HashTable cache;
protected
  Integer ix, aliasOf;
algorithm
  ix := simEqSystemIndex(eq);
  if BaseHashTable.hasKey(eq,cache) then
    aliasOf := BaseHashTable.get(eq,cache);
    if aliasOf <> ix then
      eq := SimCode.SES_ALIAS(ix, BaseHashTable.get(eq,cache));
    end if;
    return;
  end if;
  if match eq
    case SimCode.SES_SIMPLE_ASSIGN() then true;
    case SimCode.SES_ARRAY_CALL_ASSIGN() then true;
    case SimCode.SES_ALGORITHM(statements={DAE.STMT_NORETCALL()}) then true;
    // TODO: Check if LS / NLS are equal and alias the whole systems?
    else false;
  end match then
    cache := BaseHashTable.add((eq,ix), cache);
  end if;
end aliasSimEq;

annotation(__OpenModelica_Interface="backend");
end SimCodeUtil;

/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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
encapsulated package NSimCode
"file:        NSimCode.mo
 package:     NSimCode
 description: This file contains the main data type for the backend containing
              all data. It further contains the lower and solve main function.
"

protected
  // OF imports
  import Absyn;
  import AbsynUtil;
  import OldExpression = Expression;

  // NF imports
  import BuiltinCall = NFBuiltinCall;
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import ConvertDAE = NFConvertDAE;
  import NFTyping.ExpOrigin;
  import Expression = NFExpression;
  import NFFunction.Function;
  import FunctionTree = NFFlatten.FunctionTree;
  import NFInstNode.InstNode;
  import Type = NFType;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BVariable = NBVariable;
  import System = NBSystem;

  // SimCode imports
  import HashTableSimCode;
  import NSimJacobian.SimJacobian;
  import SimStrongComponent = NSimStrongComponent;
  import NSimVar.SimVar;
  import NSimVar.SimVars;
  import SymbolTable;

  // Old SimCode imports
  import HpcOmSimCode;
  import OldSimCode = SimCode;
  import OldSimCodeFunction = SimCodeFunction;
  import OldSimCodeFunctionUtil = SimCodeFunctionUtil;
  import OldSimCodeUtil = SimCodeUtil;

  // Util imports
  import Error;
  import HashTable;
  import HashTableCrIListArray;
  import HashTableCrILst;
  import HashTableCrefSimVar;

  // Script imports
  import CevalScriptBackend;

public
  uniontype SimCodeIndices
    record SIM_CODE_INDICES
      "Unique simulation code indices"
      Integer realVarIndex;
      Integer integerVarIndex;
      Integer booleanVarIndex;
      Integer stringVarIndex;

      Integer realParamIndex;
      Integer integerParamIndex;
      Integer booleanParamIndex;
      Integer stringParamIndex;

      Integer equationIndex;
      Integer linearSystemIndex;
      Integer nonlinearSystemIndex;

      Integer jacobianIndex;
      Integer daeModeResidualIndex;
    end SIM_CODE_INDICES;
  end SimCodeIndices;

  constant SimCodeIndices EMPTY_SIM_CODE_INDICES = SIM_CODE_INDICES(0,0,0,0,0,0,0,0,0,0,0,0,0);

  uniontype SimCode
    record SIM_CODE
      ModelInfo modelInfo;
      list<Expression> literals                         "shared literals";
      list<SimCodeFunction.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes             "Names of all external functions that are called";
      list<SimStrongComponent.Block> independent        "state and strictly input dependent variables. they are not inserted into any partion";
      list<SimStrongComponent.Block> allSim             "All simulation system blocks";
      list<list<SimStrongComponent.Block>> ode          "Only ode blocks for integrator";
      list<list<SimStrongComponent.Block>> algebraic    "Additional purely algebraic blocks";
      //list<ClockedPartition> clockedPartitions;
      list<SimStrongComponent.Block> nominal            "Blocks for nominal value equations";
      list<SimStrongComponent.Block> min                "Blocks for min value equations";
      list<SimStrongComponent.Block> max                "Blocks for max value equations";
      list<SimStrongComponent.Block> param              "Blocks for parameter equations";
      list<SimStrongComponent.Block> no_ret             "Blocks for equations without return value";
      list<SimStrongComponent.Block> algorithms         "Blocks for algorithms and asserts";
      list<SimStrongComponent.Block> zero_cross_blocks         "Blocks for zero crossing functions";
      list<SimStrongComponent.Block> jac_blocks         "Blocks for jacobian equations";
      list<SimStrongComponent.Block> start              "Blocks for start value equations";
      list<SimStrongComponent.Block> init               "Blocks for initial equations";
      list<SimStrongComponent.Block> init_0             "Blocks for initial lambda 0 equations (homotopy)";
      list<SimStrongComponent.Block> init_no_ret        "Blocks for initial equations without return value";
      //list<DAE.Statement> algorithmAndEquationAsserts;
      //list<StateSet> stateSets;
      //list<DAE.Constraint> constraints;
      //list<DAE.ClassAttributes> classAttributes;
      //list<BackendDAE.ZeroCrossing> zeroCrossings;
      //list<BackendDAE.ZeroCrossing> relations "only used by c runtime";
      //list<BackendDAE.TimeEvent> timeEvents "only used by c runtime yet";
      list<ComponentRef> discreteVars                   "List of discrete variables";
      //ExtObjInfo extObjInfo;
      OldSimCodeFunction.MakefileParams makefileParams;
      //DelayedExpression delayedExps;
      list<SimJacobian> jacobians       "List of symbolic jacobians";
      Option<OldSimCode.SimulationSettings> simulationSettingsOpt; // replace this with new struct
      //String fileNamePrefix, fullPathPrefix "Used in FMI where files are generated in a special directory";
      //String fmuTargetName;
      //HpcOmSimCode.HpcOmData hpcomData;
      //AvlTreeCRToInt.Tree valueReferences "Used in FMI";
      //maps each variable to an array of storage indices (with this information, arrays must not be unrolled) and a list for the array-dimensions
      //if the variable is not part of an array (if it is a scalar value), then the array has size 1
      //HashTableCrIListArray.HashTable varToArrayIndexMapping;
      //*** a protected section *** not exported to SimCodeTV
      //HashTableCrILst.HashTable varToIndexMapping;
      HashTableSimCode.HashTable crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      //HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
      //Option<BackendMapping> backendMapping;
      //FMI 2.0 data for model structure
      //Option<FmiModelStructure> modelStructure;
      //PartitionData partitionData;
      Option<DaeModeData> daeModeData                   "Simulation system in case of DAEMode";
      list<SimStrongComponent.Block> inlineEquations; // ToDo: what exactly is this?
      //Option<OMSIData> omsiData "used for OMSI to generate equations code";
    end SIM_CODE;

    function toString
      input SimCode simCode;
      input output String str = "";
    protected
      Integer idx = 1;
    algorithm
      str := StringUtil.headline_1("SimCode " + str + "(" + AbsynUtil.pathString(simCode.modelInfo.name) + ")");
      str := str + ModelInfo.toString(simCode.modelInfo);
      str := str + SimStrongComponent.Block.listToString(simCode.init, "  ", "INIT") + "\n";
      for blck_lst in simCode.ode loop
        str := str + SimStrongComponent.Block.listToString(blck_lst, "  ", "ODE Partition " + intString(idx)) + "\n";
        idx := idx + 1;
      end for;
      if isSome(simCode.daeModeData) then
        str := str + DaeModeData.toString(Util.getOption(simCode.daeModeData)) + "\n";
      end if;
    end toString;

    function create
      input BackendDAE bdae;
      input Absyn.Path name;
      input Option<OldSimCode.SimulationSettings> simSettingsOpt;
      output SimCode simCode;
    algorithm
      simCode := match bdae
        local
          BackendDAE qual;
          FunctionTree funcTree;
          // old SimCode strcutures
          Absyn.Program program;
          list<String> libs, includes, includeDirs, libPaths;
          String directory;
          OldSimCodeFunction.MakefileParams makefileParams;
          list<OldSimCodeFunction.Function> functions;
          list<OldSimCodeFunction.RecordDeclaration> recordDecls;
          //tuple<Integer, HashTableExpToIndex.HashTable, list<DAE.Exp>> literals;
          // New SimCode structures
          ModelInfo modelInfo;
          SimCodeIndices simCodeIndices;
          list<Expression> literals;
          list<String> externalFunctionIncludes;
          list<SimStrongComponent.Block> independent, allSim, nominal, min, max, param, no_ret, algorithms;
          list<SimStrongComponent.Block> zero_cross_blocks, jac_blocks;
          list<SimStrongComponent.Block> init, init_0, init_no_ret, start;
          list<list<SimStrongComponent.Block>> ode, algebraic;
          list<SimStrongComponent.Block> linearLoops, nonlinearLoops;
          list<ComponentRef> discreteVars;
          list<SimJacobian> jacobians;
          HashTableSimCode.HashTable crefToSimVarHT;
          Option<DaeModeData> daeModeData;
          SimJacobian jacA, jacB, jacC, jacD, jacF;
          list<SimStrongComponent.Block> inlineEquations; // ToDo: what exactly is this?

        case qual as BackendDAE.BDAE()
          algorithm
            // somehow this cannot be set at definition (metamodelica bug?)
            simCodeIndices := EMPTY_SIM_CODE_INDICES;
            funcTree := BackendDAE.getFunctionTree(bdae);

            // for now approximate number of equations
            literals := {};
            externalFunctionIncludes := {};
            independent := {};
            nominal := {};
            min := {};
            max := {};
            // all non constant parameter equations will be added to the initial system.
            // There is no actual need for parameter equations block
            param := {};
            no_ret := {};
            algorithms := {};
            zero_cross_blocks := {};
            jac_blocks := {};
            (init, simCodeIndices, funcTree) := SimStrongComponent.Block.createInitialBlocks(qual.init, simCodeIndices, funcTree);
            init_0 := {};
            init_no_ret := {};
            start := {};
            algebraic := {};
            discreteVars := {};
            jacobians := {};
            if isSome(qual.dae) then
              ode := {};
              (daeModeData, simCodeIndices, funcTree) := DaeModeData.create(Util.getOption(qual.dae), simCodeIndices, funcTree);
            else
              (ode, simCodeIndices, funcTree) := SimStrongComponent.Block.createBlocks(qual.ode, simCodeIndices, funcTree);
              daeModeData := NONE();
            end if;
            allSim := List.flatten(ode);

            // ToDo add event system
            inlineEquations := {};

            // ToDo:
            // this has to be adapted at some point SimCodeFuntion needs to be translated
            // to new simcode and literals have to be based on new Expressions.
            // Will probably be mostly the same in all other regards
            program := SymbolTable.getAbsyn();
            directory := CevalScriptBackend.getFileDir(AbsynUtil.pathToCref(name), program);
            (libs, libPaths, _, includeDirs, recordDecls, functions, _) := SimCodeUtil.createFunctions(program, ConvertDAE.convertFunctionTree(funcTree));
            makefileParams := OldSimCodeFunctionUtil.createMakefileParams(includeDirs, libs, libPaths, false, false);

            (linearLoops, nonlinearLoops) := collectAlgebraicLoops(init, daeModeData);
            (modelInfo, simCodeIndices) := ModelInfo.create(qual.varData, name, directory, functions, linearLoops, nonlinearLoops, simCodeIndices);
            crefToSimVarHT := HashTableSimCode.create(modelInfo.vars);

            // This needs to be done after the variables have been created by ModelInfo.create()
            if isSome(qual.dae) then
              (daeModeData, modelInfo, jacA, crefToSimVarHT, simCodeIndices) := DaeModeData.createSparsityJacobian(daeModeData, modelInfo, Util.getOption(qual.dae), crefToSimVarHT, simCodeIndices);
            else
              (jacA, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
            end if;

            (jacB, simCodeIndices) := SimJacobian.empty("B", simCodeIndices);
            (jacC, simCodeIndices) := SimJacobian.empty("C", simCodeIndices);
            (jacD, simCodeIndices) := SimJacobian.empty("D", simCodeIndices);
            (jacF, simCodeIndices) := SimJacobian.empty("F", simCodeIndices);
            jacobians := {jacA, jacB, jacC, jacD, jacF};

            simCode := SIM_CODE(
              modelInfo                 = modelInfo,
              literals                  = literals,
              recordDecls               = recordDecls,
              externalFunctionIncludes  = externalFunctionIncludes,
              independent               = independent,
              allSim                    = allSim,
              ode                       = ode,
              algebraic                 = algebraic,
              nominal                   = nominal,
              min                       = min,
              max                       = max,
              param                     = param,
              no_ret                    = no_ret,
              algorithms                = algorithms,
              zero_cross_blocks         = zero_cross_blocks,
              jac_blocks                = jac_blocks,
              start                     = start,
              init                      = init,
              init_0                    = init_0,
              init_no_ret               = init_no_ret,
              discreteVars              = discreteVars,
              makefileParams            = makefileParams,
              jacobians                 = jacobians,
              simulationSettingsOpt     = simSettingsOpt,
              crefToSimVarHT            = crefToSimVarHT,
              daeModeData               = daeModeData,
              inlineEquations           = inlineEquations);
        then simCode;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end create;

    function convert
      input SimCode simCode;
      output OldSimCode.SimCode oldSimCode;
    protected
      OldSimCode.ModelInfo modelInfo;
      list<DAE.ComponentRef> discreteModelVars = {};
      HashTableCrIListArray.HashTable varToArrayIndexMapping;
      HashTableCrILst.HashTable varToIndexMapping;
      list<OldSimCode.JacobianMatrix> jacobians = {};
      OldSimCode.HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
      list<SimVar> residualVars;
    algorithm
      modelInfo := ModelInfo.convert(simCode.modelInfo);
      (varToArrayIndexMapping, varToIndexMapping) := OldSimCodeUtil.createVarToArrayIndexMapping(modelInfo);
      for jac in listReverse(simCode.jacobians) loop
        jacobians := SimJacobian.convert(jac) :: jacobians;
      end for;
      crefToSimVarHT := OldSimCodeUtil.createCrefToSimVarHT(modelInfo);
      if isSome(simCode.daeModeData) then
          SOME(DAE_MODE_DATA(residualVars = residualVars)) := simCode.daeModeData;
          crefToSimVarHT:= List.fold(SimVar.SimVar.convertList(residualVars), HashTableCrefSimVar.addSimVarToHashTable, crefToSimVarHT);
      end if;
      crefToClockIndexHT := HashTable.emptyHashTable();
      for cref in simCode.discreteVars loop
        discreteModelVars := ComponentRef.toDAE(cref) :: discreteModelVars;
      end for;

      oldSimCode := OldSimCode.SIMCODE(
        modelInfo                     = modelInfo,
        literals                      = {}, // usally set by a traversal below...
        recordDecls                   = simCode.recordDecls, // ToDo: convert this to new structures
        externalFunctionIncludes      = simCode.externalFunctionIncludes,
        localKnownVars                = SimStrongComponent.Block.convertList(simCode.independent),
        allEquations                  = SimStrongComponent.Block.convertList(simCode.allSim),
        odeEquations                  = SimStrongComponent.Block.convertListList(simCode.ode),
        algebraicEquations            = SimStrongComponent.Block.convertListList(simCode.algebraic),
        clockedPartitions             = {}, // ToDo: add this once clocked partitions are supported
        initialEquations              = SimStrongComponent.Block.convertList(simCode.init),
        initialEquations_lambda0      = SimStrongComponent.Block.convertList(simCode.init_0),
        removedInitialEquations       = SimStrongComponent.Block.convertList(simCode.init_no_ret),
        startValueEquations           = SimStrongComponent.Block.convertList(simCode.start),
        nominalValueEquations         = SimStrongComponent.Block.convertList(simCode.nominal),
        minValueEquations             = SimStrongComponent.Block.convertList(simCode.min),
        maxValueEquations             = SimStrongComponent.Block.convertList(simCode.max),
        parameterEquations            = SimStrongComponent.Block.convertList(simCode.param),
        removedEquations              = SimStrongComponent.Block.convertList(simCode.no_ret),
        algorithmAndEquationAsserts   = SimStrongComponent.Block.convertList(simCode.algorithms),
        equationsForZeroCrossings     = SimStrongComponent.Block.convertList(simCode.zero_cross_blocks),
        jacobianEquations             = SimStrongComponent.Block.convertList(simCode.jac_blocks),
        stateSets                     = {}, // ToDo: add this once state sets are supported
        constraints                   = {}, // ToDo: add this once constraints are supported
        classAttributes               = {}, // ToDo: add this once class attributes are supported
        zeroCrossings                 = {}, // ToDo: add this once zero crossings are supported
        relations                     = {}, // ToDo: add this once zero crossings are supported
        timeEvents                    = {}, // ToDo: add this once zero crossings are supported
        discreteModelVars             = discreteModelVars,
        extObjInfo                    = OldSimCode.EXTOBJINFO({}, {}), // ToDo: add this once external object info is supported
        makefileParams                = simCode.makefileParams, // ToDo: convert this to new structures
        delayedExps                   = OldSimCode.DELAYED_EXPRESSIONS({}, 0), // ToDo: add this once delayed expressions are supported
        jacobianMatrixes              = jacobians,
        simulationSettingsOpt         = simCode.simulationSettingsOpt, // replace with new struct later on
        fileNamePrefix                = AbsynUtil.pathString(simCode.modelInfo.name),
        fullPathPrefix                = "", // FMI stuff
        fmuTargetName                 = "", // FMI stuff
        hpcomData                     = HpcOmSimCode.emptyHpcomData,
        valueReferences               = AvlTreeCRToInt.EMPTY(), // change to this with fmu: if isFMU then getValueReferenceMapping(modelInfo) else AvlTreeCRToInt.EMPTY(),
        varToArrayIndexMapping        = varToArrayIndexMapping,
        varToIndexMapping             = varToIndexMapping,
        crefToSimVarHT                = crefToSimVarHT,
        crefToClockIndexHT            = crefToClockIndexHT,
        backendMapping                = NONE(), // This needs to be added?
        modelStructure                = NONE(), // FMI stuff
        fmiSimulationFlags            = NONE(), // FMI stuff
        partitionData                 = OldSimCode.PARTITIONDATA(-1,{},{},{}),
        daeModeData                   = if isSome(simCode.daeModeData) then SOME(DaeModeData.convert(Util.getOption(simCode.daeModeData))) else NONE(),
        inlineEquations               = {},
        omsiData                      = NONE());
    end convert;

    function getDirectoryAndLibs
      input SimCode simCode;
      output String directory;
      output list<String> libs;
    algorithm
      (directory, libs) := match simCode
        case SIM_CODE(modelInfo = MODEL_INFO(directory = directory), makefileParams = OldSimCodeFunction.MAKEFILE_PARAMS(libs = libs)) then (directory, libs);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end getDirectoryAndLibs;
  protected
    function collectAlgebraicLoops
      "Collects algebraic loops from all systems (ode, init, init_0, dae, ...).
      ToDo: Add other systems once implemented!"
      input list<SimStrongComponent.Block> init;
      input Option<DaeModeData> daeModeData;
      output list<SimStrongComponent.Block> linearLoops = {};
      output list<SimStrongComponent.Block> nonlinearLoops = {};
    protected
      list<list<SimStrongComponent.Block>> dae_mode_blcks;
    algorithm
      (linearLoops, nonlinearLoops) := SimStrongComponent.Block.collectAlgebraicLoops({init}, linearLoops, nonlinearLoops);
      if isSome(daeModeData) then
        SOME(DAE_MODE_DATA(blcks = dae_mode_blcks)) := daeModeData;
        (linearLoops, nonlinearLoops) := SimStrongComponent.Block.collectAlgebraicLoops(dae_mode_blcks, linearLoops, nonlinearLoops);
      end if;
    end collectAlgebraicLoops;
  end SimCode;

  uniontype ModelInfo
    record MODEL_INFO
      Absyn.Path name;
      String description;
      String directory;
      SimVars vars;
      VarInfo varInfo;
      list<SimCodeFunction.Function> functions;
      list<String> labels;
      list<String> resourcePaths "Paths of all resources used by the model. Used in FMI2 to package resources in the FMU.";
      list<Absyn.Class> sortedClasses;
      //Files files "all the files from SourceInfo and DAE.ElementSource";
      Integer nClocks;
      Integer nSubClocks;
      Boolean hasLargeLinearEquationSystems; // True if model has large linear eq. systems that are crucial for performance.
      list<SimStrongComponent.Block> linearLoops;
      list<SimStrongComponent.Block> nonlinearLoops;
      //list<UnitDefinition> unitDefinitions "export unitDefintion in modelDescription.xml";
    end MODEL_INFO;

    function toString
      input ModelInfo modelInfo;
      output String str;
    algorithm
      str := SimVars.toString(modelInfo.vars);
    end toString;

    function create
      input BVariable.VarData varData;
      input Absyn.Path name;
      input String directory;
      input list<OldSimCodeFunction.Function> functions;
      input list<SimStrongComponent.Block> linearLoops;
      input list<SimStrongComponent.Block> nonlinearLoops;
      output ModelInfo modelInfo;
      input output SimCodeIndices simCodeIndices;
    protected
      SimVars vars;
      VarInfo info;
    algorithm
      (vars, simCodeIndices) := SimVars.create(varData, simCodeIndices);
      info := VarInfo.create(vars, simCodeIndices);
      modelInfo := MODEL_INFO(name, "", directory, vars, info, functions, {}, {}, {}, 0, 0, true, linearLoops, nonlinearLoops);
    end create;

    function setSeedVars
      input output ModelInfo modelInfo;
      input list<SimVar> seedVars;
    algorithm
      modelInfo := match modelInfo
        local
          SimVars vars;
        case MODEL_INFO(vars = vars) algorithm
          vars.seedVars := seedVars;
          modelInfo.vars := vars;
        then modelInfo;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end setSeedVars;

    function convert
      input ModelInfo modelInfo;
      output OldSimCode.ModelInfo oldModelInfo;
    protected
      OldSimCode.VarInfo varInfo;
    algorithm
      varInfo := VarInfo.convert(modelInfo.varInfo);
      oldModelInfo := OldSimCode.MODELINFO(
        name                            = modelInfo.name,
        description                     = modelInfo.description,
        directory                       = modelInfo.directory,
        varInfo                         = VarInfo.convert(modelInfo.varInfo),
        vars                            = SimVar.SimVars.convert(modelInfo.vars),
        functions                       = {}, // ToDo: add this once functions are supported
        labels                          = modelInfo.labels,
        resourcePaths                   = modelInfo.resourcePaths,
        sortedClasses                   = modelInfo.sortedClasses,
        //Files files "all the files from SourceInfo and DAE.ElementSource";
        nClocks                         = modelInfo.nClocks,
        nSubClocks                      = modelInfo.nSubClocks,
        hasLargeLinearEquationSystems   = modelInfo.hasLargeLinearEquationSystems,
        linearSystems                   = SimStrongComponent.Block.convertList(modelInfo.linearLoops),
        nonLinearSystems                = SimStrongComponent.Block.convertList(modelInfo.nonlinearLoops),
        unitDefinitions                 = {} // ToDo: add this once unit definitions are supported
      );
    end convert;
  end ModelInfo;

  uniontype VarInfo
    record VAR_INFO
      Integer numZeroCrossings;
      Integer numTimeEvents;
      Integer numRelations;
      Integer numMathEventFunctions;
      Integer numStateVars;
      Integer numAlgVars;
      Integer numDiscreteReal;
      Integer numIntAlgVars;
      Integer numBoolAlgVars;
      Integer numAlgAliasVars;
      Integer numIntAliasVars;
      Integer numBoolAliasVars;
      Integer numParams;
      Integer numIntParams;
      Integer numBoolParams;
      Integer numOutVars;
      Integer numInVars;
      Integer numExternalObjects;
      Integer numStringAlgVars;
      Integer numStringParamVars;
      Integer numStringAliasVars;
      Integer numEquations;
      Integer numLinearSystems;
      Integer numNonLinearSystems;
      Integer numMixedSystems;
      Integer numStateSets;
      Integer numJacobians;
      Integer numOptimizeConstraints;
      Integer numOptimizeFinalConstraints;
      Integer numSensitivityParameters;
      Integer numSetcVars;
      Integer numDataReconVars;
    end VAR_INFO;

    function create
      input SimVars vars;
      input SimCodeIndices simCodeIndices;
      output VarInfo varInfo;
    algorithm
      varInfo := VAR_INFO(
        numZeroCrossings            = 0,
        numTimeEvents               = 0,
        numRelations                = 0,
        numMathEventFunctions       = 0,
        numStateVars                = listLength(vars.stateVars),
        numAlgVars                  = listLength(vars.algVars),
        numDiscreteReal             = listLength(vars.discreteAlgVars),
        numIntAlgVars               = listLength(vars.intAlgVars),
        numBoolAlgVars              = listLength(vars.boolAlgVars),
        numAlgAliasVars             = listLength(vars.aliasVars),
        numIntAliasVars             = listLength(vars.intAliasVars),
        numBoolAliasVars            = listLength(vars.boolAliasVars),
        numParams                   = listLength(vars.paramVars),
        numIntParams                = listLength(vars.intParamVars),
        numBoolParams               = listLength(vars.boolParamVars),
        numOutVars                  = listLength(vars.outputVars),
        numInVars                   = listLength(vars.inputVars),
        numExternalObjects          = listLength(vars.extObjVars),
        numStringAlgVars            = listLength(vars.stringAlgVars),
        numStringParamVars          = listLength(vars.stringParamVars),
        numStringAliasVars          = listLength(vars.stringAliasVars),
        numEquations                = simCodeIndices.equationIndex,
        numLinearSystems            = simCodeIndices.linearSystemIndex,
        numNonLinearSystems         = simCodeIndices.nonlinearSystemIndex,
        numMixedSystems             = 0,
        numStateSets                = 0,
        numJacobians                = simCodeIndices.nonlinearSystemIndex + 5, // #nonlinSystems + 5 simulation jacs (add state sets later!)
        numOptimizeConstraints      = 0,
        numOptimizeFinalConstraints = 0,
        numSensitivityParameters    = 0,
        numSetcVars                 = 0,
        numDataReconVars            = 0);
    end create;

    function convert
      input VarInfo varInfo;
      output OldSimCode.VarInfo oldVarInfo;
    algorithm
      oldVarInfo := OldSimCode.VARINFO(
        numZeroCrossings            = varInfo.numZeroCrossings,
        numTimeEvents               = varInfo.numTimeEvents,
        numRelations                = varInfo.numRelations,
        numMathEventFunctions       = varInfo.numMathEventFunctions,
        numStateVars                = varInfo.numStateVars,
        numAlgVars                  = varInfo.numAlgVars,
        numDiscreteReal             = varInfo.numDiscreteReal,
        numIntAlgVars               = varInfo.numIntAlgVars,
        numBoolAlgVars              = varInfo.numBoolAlgVars,
        numAlgAliasVars             = varInfo.numAlgAliasVars,
        numIntAliasVars             = varInfo.numIntAliasVars,
        numBoolAliasVars            = varInfo.numBoolAliasVars,
        numParams                   = varInfo.numParams,
        numIntParams                = varInfo.numIntParams,
        numBoolParams               = varInfo.numBoolParams,
        numOutVars                  = varInfo.numOutVars,
        numInVars                   = varInfo.numInVars,
        numExternalObjects          = varInfo.numExternalObjects,
        numStringAlgVars            = varInfo.numStringAlgVars,
        numStringParamVars          = varInfo.numStringParamVars,
        numStringAliasVars          = varInfo.numStringAliasVars,
        numEquations                = varInfo.numEquations,
        numLinearSystems            = varInfo.numLinearSystems,
        numNonLinearSystems         = varInfo.numNonLinearSystems,
        numMixedSystems             = varInfo.numMixedSystems,
        numStateSets                = varInfo.numStateSets,
        numJacobians                = varInfo.numJacobians,
        numOptimizeConstraints      = varInfo.numOptimizeConstraints,
        numOptimizeFinalConstraints = varInfo.numOptimizeFinalConstraints,
        numSensitivityParameters    = varInfo.numSensitivityParameters,
        numSetcVars                 = varInfo.numSetcVars,
        numDataReconVars            = varInfo.numDataReconVars);
    end convert;
  end VarInfo;

  uniontype DaeModeData
    "contains data that belongs to the dae mode"
    record DAE_MODE_DATA
      list<list<SimStrongComponent.Block>> blcks          "daeMode blocks";
      Option<SimJacobian> sparsityPattern "contains the sparsity pattern for the daeMode";
      list<SimVar> residualVars "variable used to calculate residuals of a DAE form, they are real";
      list<SimVar> algebraicVars;
      list<SimVar> auxiliaryVars;
      DaeModeConfig modeCreated;
    end DAE_MODE_DATA;

    function toString
      input DaeModeData data;
      output String str = "";
    protected
      Integer idx = 1;
    algorithm
      for blck_lst in data.blcks loop
        str := str + SimStrongComponent.Block.listToString(blck_lst, "  ", "DAE Partition " + intString(idx));
        idx := idx + 1;
      end for;
      if isSome(data.sparsityPattern) then
        str := str + "\n" + SimJacobian.toString(Util.getOption(data.sparsityPattern));
      end if;
    end toString;

    function create
      input list<System.System> systems;
      output Option<DaeModeData> data;
      input output SimCodeIndices simCodeIndices;
      input output FunctionTree funcTree;
    protected
      list<list<SimStrongComponent.Block>> blcks;
      list<SimVar> residualVars, algebraicVars;
      Option<SimJacobian> daeModeJac;
    algorithm
      (blcks, residualVars, simCodeIndices, funcTree) := SimStrongComponent.Block.createDAEModeBlocks(systems, simCodeIndices, funcTree);
      (daeModeJac, simCodeIndices, funcTree) := SimJacobian.fromSystems(systems, simCodeIndices, funcTree);
      data := SOME(DAE_MODE_DATA(blcks, daeModeJac, residualVars, {}, {}, DaeModeConfig.ALL));
    end create;

    function convert
      input DaeModeData data;
      output OldSimCode.DaeModeData oldData;
    protected
      list<list<OldSimCode.SimEqSystem>> simEqSystems = {};
    algorithm
      /* is this not needed?
      for sys_lst in listReverse(SimStrongComponent.Block.convertListList(data.blcks)) loop
        simEqSystems := List.map(sys_lst, replaceDerCrefSES) :: simEqSystems;
      end for;
      */
      simEqSystems := SimStrongComponent.Block.convertListList(data.blcks);
      oldData := OldSimCode.DAEMODEDATA(
        daeEquations    = simEqSystems,
        sparsityPattern = SimJacobian.convertOpt(data.sparsityPattern),
        residualVars    = SimVar.SimVar.convertList(data.residualVars),
        algebraicVars   = SimVar.SimVar.convertList(data.algebraicVars),
        auxiliaryVars   = SimVar.SimVar.convertList(data.auxiliaryVars),
        modeCreated     = convertMode(data.modeCreated));
    end convert;

  protected
    function convertMode
      input DaeModeConfig mode;
      output OldSimCode.DaeModeConfig oldMode;
    algorithm
      oldMode := match mode
        case DaeModeConfig.ALL      then OldSimCode.ALL_EQUATIONS();
        case DaeModeConfig.DYNAMIC  then OldSimCode.DYNAMIC_EQUATIONS();
      end match;
    end convertMode;

    function createSparsityJacobian
      input output Option<DaeModeData> daeModeDataOpt;
      input output ModelInfo modelInfo;
      input list<System.System> systems;
      output SimJacobian jacobian;
      input output HashTableSimCode.HashTable simulationHT;
      input output SimCodeIndices simCodeIndices;
    algorithm
      daeModeDataOpt := match daeModeDataOpt
        local
          DaeModeData daeModeData;
          SimJacobian jac;
          Option<SimJacobian> daeModeJac;

        case SOME(daeModeData)
          algorithm
            // get sparsity pattern jacobian and update the hashtable and the jacobian
            simulationHT := HashTableSimCode.addList(daeModeData.residualVars, simulationHT);
            if isSome(daeModeData.sparsityPattern) then
              SOME(jac) := daeModeData.sparsityPattern;
              simulationHT := HashTableSimCode.addList(jac.seedVars, simulationHT);
              modelInfo := ModelInfo.setSeedVars(modelInfo, jac.seedVars);
              daeModeData.algebraicVars := rewriteAlgebraicVarsIdx(modelInfo.vars.algVars, simulationHT);
              daeModeData.auxiliaryVars := {}; // this needs to be updated in the future
              (daeModeJac, simCodeIndices) := SimJacobian.fromSystemsSparsity(systems, daeModeData.sparsityPattern, simulationHT, simCodeIndices);
              daeModeData.sparsityPattern := daeModeJac;
              jacobian := Util.getOption(daeModeJac);
            else
              (jacobian, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
            end if;
        then SOME(daeModeData);

        else
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end createSparsityJacobian;

    function rewriteAlgebraicVarsIdx
      input list<SimVar> simulationAlgVars;
      input HashTableSimCode.HashTable simulationHT;
      output list<SimVar> daeModeAlgVars = {};
    protected
      ComponentRef seedCref, cref;
    algorithm
      BaseHashTable.dumpHashTable(simulationHT);
      seedCref := ComponentRef.fromNode(InstNode.VAR_NODE(NBVariable.SEED_STR + "_A", Pointer.create(NBVariable.DUMMY_VARIABLE)), Type.UNKNOWN());
      for var in listReverse(simulationAlgVars) loop
        cref := ComponentRef.append(var.name, seedCref);
        print("Searching for: " + ComponentRef.toString(cref) + "\n");
        var.index := SimVar.getIndex(BaseHashTable.get(cref, simulationHT));
        daeModeAlgVars := var :: daeModeAlgVars;
      end for;
    end rewriteAlgebraicVarsIdx;

    function replaceDerCrefSES
      input output OldSimCode.SimEqSystem sys;
    algorithm
      sys := match sys
        local
          OldSimCode.SimEqSystem qual;

        case qual as OldSimCode.SES_RESIDUAL() algorithm
          (qual.exp, _) := OldExpression.traverseExpTopDown(qual.exp, replaceDerCref, 0);
        then qual;

        case qual as OldSimCode.SES_SIMPLE_ASSIGN() algorithm
          (qual.exp, _) := OldExpression.traverseExpTopDown(qual.exp, replaceDerCref, 0);
        then qual;
      end match;
    end replaceDerCrefSES;

    function replaceDerCref
      "this is very bad. temporary fix please remove.
      the old structure needs a der() call instead of $DER variable for DAEMode."
      input output DAE.Exp exp;
      output Boolean b;
      input output Integer i;
    algorithm
      (exp, b) := match exp
        local
          DAE.ComponentRef cref;

        case DAE.CREF(componentRef = DAE.CREF_QUAL(ident="$DER",componentRef=cref))
        then (DAE.CALL(Absyn.IDENT("der"), {DAE.CREF(cref, ComponentReference.crefTypeFull(cref))}, DAE.callAttrBuiltinReal), false);

        else (exp, true);
      end match;
    end replaceDerCref;
  end DaeModeData;

  type DaeModeConfig = enumeration(ALL, DYNAMIC);

  annotation(__OpenModelica_Interface="backend");
end NSimCode;

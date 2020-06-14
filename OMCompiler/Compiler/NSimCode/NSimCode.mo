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

  // NF imports
  import ComponentRef = NFComponentRef;
  import Expression = NFExpression;
  import ConvertDAE = NFConvertDAE;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BVariable = NBVariable;
  import System = NBSystem;

  // SimCode imports
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

  // Script imports
  import CevalScriptBackend;

public
  uniontype SimCode
    record SIM_CODE
      ModelInfo modelInfo;
      list<Expression> literals                         "shared literals";
      list<SimCodeFunction.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes             "Names of all external functions that are called";
      list<SimStrongComponent.Block> independent        "state and strictly input dependent variables. they are not inserted into any partion";
      list<SimStrongComponent.Block> allSim             "All simulation system blocks";
      // kabdelhak: why nested lists?
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
      list<SimStrongComponent.Jacobian> jacobians       "List of symbolic jacobians";
      //Option<SimulationSettings> simulationSettingsOpt;
      //String fileNamePrefix, fullPathPrefix "Used in FMI where files are generated in a special directory";
      //String fmuTargetName;
      //HpcOmSimCode.HpcOmData hpcomData;
      //AvlTreeCRToInt.Tree valueReferences "Used in FMI";
      //maps each variable to an array of storage indices (with this information, arrays must not be unrolled) and a list for the array-dimensions
      //if the variable is not part of an array (if it is a scalar value), then the array has size 1
      //HashTableCrIListArray.HashTable varToArrayIndexMapping;
      //*** a protected section *** not exported to SimCodeTV
      //HashTableCrILst.HashTable varToIndexMapping;
      //HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
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
      str := StringUtil.headline_1("SimCode " + str);
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
      output SimCode simCode;
    algorithm
      simCode := match bdae
        local
          BackendDAE qual;
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
          Integer uniqueEquationIndex = 0;
          list<Expression> literals;
          list<String> externalFunctionIncludes;
          list<SimStrongComponent.Block> independent, allSim, nominal, min, max, param, no_ret, algorithms;
          list<SimStrongComponent.Block> zero_cross_blocks, jac_blocks;
          list<SimStrongComponent.Block> init, init_0, init_no_ret, start;
          list<list<SimStrongComponent.Block>> ode, algebraic;
          list<ComponentRef> discreteVars;
          list<SimStrongComponent.Jacobian> jacobians;
          Option<DaeModeData> daeModeData;
          list<SimStrongComponent.Block> inlineEquations; // ToDo: what exactly is this?

        case qual as BackendDAE.BDAE()
          algorithm
            // ToDo:
            // this has to be adapted at some point SimCodeFuntion needs to be translated
            // to new simcode and literals have to be based on new Expressions.
            // Will probably be mostly the same in all other regards
            program := SymbolTable.getAbsyn();
            (libs, libPaths, _, includeDirs, recordDecls, functions, _) := SimCodeUtil.createFunctions(program, ConvertDAE.convertFunctionTree(BackendDAE.getFunctionTree(bdae)));
            makefileParams := OldSimCodeFunctionUtil.createMakefileParams(includeDirs, libs, libPaths, false, false);
            directory := CevalScriptBackend.getFileDir(AbsynUtil.pathToCref(name), program);

            // for now approximate number of equations
            literals := {};
            externalFunctionIncludes := {};
            independent := {};
            allSim := {};
            nominal := {};
            min := {};
            max := {};
            param := {};
            no_ret := {};
            algorithms := {};
            zero_cross_blocks := {};
            jac_blocks := {};
            (init, uniqueEquationIndex) := SimStrongComponent.Block.createInitialBlocks(qual.init, uniqueEquationIndex);
            init_0 := {};
            init_no_ret := {};
            start := {};
            (ode, uniqueEquationIndex) := SimStrongComponent.Block.createBlocks(qual.ode, uniqueEquationIndex);
            algebraic := {};
            discreteVars := {};
            jacobians := {};
            if isSome(qual.dae) then
              (daeModeData, uniqueEquationIndex) := DaeModeData.create(Util.getOption(qual.dae), uniqueEquationIndex);
            else
              daeModeData := NONE();
            end if;
            inlineEquations := {};

            modelInfo := ModelInfo.create(qual.varData, name, directory, functions, uniqueEquationIndex);

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
      OldSimCode.HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
    algorithm
      modelInfo := ModelInfo.convert(simCode.modelInfo);
      (varToArrayIndexMapping, varToIndexMapping) := OldSimCodeUtil.createVarToArrayIndexMapping(modelInfo);
      crefToSimVarHT := OldSimCodeUtil.createCrefToSimVarHT(modelInfo);
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
        jacobianMatrixes              = {}, // ToDo: convert this to new structures
        simulationSettingsOpt         = NONE(),
        fileNamePrefix                = "", // FMI stuff
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
      list<SimStrongComponent.Block> linearSystems;
      list<SimStrongComponent.Block> nonLinearSystems;
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
      input Integer numEquation;
      output ModelInfo modelInfo;
    protected
      SimVars vars;
      VarInfo info;
    algorithm
      vars := SimVars.create(varData);
      info := VarInfo.create(vars, numEquation);
      modelInfo := MODEL_INFO(name, "", directory, vars, info, functions, {}, {}, {}, 0, 0, true, {}, {});
    end create;

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
        linearSystems                   = SimStrongComponent.Block.convertList(modelInfo.linearSystems),
        nonLinearSystems                = SimStrongComponent.Block.convertList(modelInfo.nonLinearSystems),
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
      input Integer numEquations;
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
        numEquations                = numEquations,
        numLinearSystems            = 0,
        numNonLinearSystems         = 1,
        numMixedSystems             = 0,
        numStateSets                = 0,
        numJacobians                = 0,
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
      Option<SimStrongComponent.Jacobian> sparsityPattern "contains the sparsity pattern for the daeMode";
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
    end toString;

    function create
      input list<System.System> systems;
      output Option<DaeModeData> data;
      input output Integer uniqueEquationIndex;
    protected
      list<list<SimStrongComponent.Block>> blcks;
      list<SimVar> residualVars;
    algorithm
      (blcks, residualVars, uniqueEquationIndex) := SimStrongComponent.Block.createDAEModeBlocks(systems, uniqueEquationIndex);
      data := SOME(DAE_MODE_DATA(blcks, NONE(), residualVars, {}, {}, DaeModeConfig.ALL));
    end create;

    function convert
      input DaeModeData data;
      output OldSimCode.DaeModeData oldData;
    algorithm
      oldData := OldSimCode.DAEMODEDATA(
        daeEquations    = SimStrongComponent.Block.convertListList(data.blcks),
        sparsityPattern = NONE(),
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
  end DaeModeData;

  type DaeModeConfig = enumeration(ALL, DYNAMIC);
  annotation(__OpenModelica_Interface="backend");
end NSimCode;

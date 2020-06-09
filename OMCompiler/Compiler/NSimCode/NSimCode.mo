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

  // Old Backend imports
  import HpcOmSimCode;
  import OldSimCode = SimCode;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BVariable = NBVariable;
  import System = NBSystem;

  // SimCode imports
  import SimStrongComponent = NSimStrongComponent;
  import NSimVar.SimVar;
  import NSimVar.SimVars;

  // Util imports
  import Error;

public
  uniontype SimCode
    record SIM_CODE
      ModelInfo modelInfo;
      list<Expression> literals                         "shared literals";
      //list<SimCodeFunction.RecordDeclaration> recordDecls;
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
      list<SimStrongComponent.Block> zero_cross         "Blocks for zero crossing functions";
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
      //SimCodeFunction.MakefileParams makefileParams;
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
      str := str + SimStrongComponent.Block.listToString(simCode.init, "INIT");
      for blck_lst in simCode.ode loop
        str := str + SimStrongComponent.Block.listToString(blck_lst, "ODE Partition " + intString(idx));
        idx := idx + 1;
      end for;
    end toString;

    function create
      input BackendDAE bdae;
      input Absyn.Path name;
      output SimCode simCode;
    algorithm
      // ToDo: fill this with meaningful stuff
      simCode := match bdae
        local
          BackendDAE qual;
          ModelInfo modelInfo;
          Integer uniqueEquationIndex = 0;
          list<Expression> literals;
          list<String> externalFunctionIncludes;
          list<SimStrongComponent.Block> independent, allSim, nominal, min, max, param, no_ret, algorithms;
          list<SimStrongComponent.Block> zero_cross, jac_blocks;
          list<SimStrongComponent.Block> init, init_0, init_no_ret, start;
          list<list<SimStrongComponent.Block>> ode, algebraic;
          list<ComponentRef> discreteVars;
          list<SimStrongComponent.Jacobian> jacobians;
          Option<DaeModeData> daeModeData;
          list<SimStrongComponent.Block> inlineEquations; // ToDo: what exactly is this?

        case qual as BackendDAE.BDAE()
          algorithm
            modelInfo := ModelInfo.create(qual.varData, name);
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
            zero_cross := {};
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

            simCode := SIM_CODE(modelInfo,
                                literals,
                                externalFunctionIncludes,
                                independent,
                                allSim,
                                ode,
                                algebraic,
                                nominal,
                                min,
                                max,
                                param,
                                no_ret,
                                algorithms,
                                zero_cross,
                                jac_blocks,
                                init,
                                init_0,
                                init_no_ret,
                                start,
                                discreteVars,
                                jacobians,
                                daeModeData,
                                inlineEquations
                              );
        then simCode;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end create;

/*
    function toOldSimCode
      input SimCode simCode;
      output OldSimCode.SimCode oldSimCode;
    protected
      ModelInfo modelInfo;
      list<DAE.Exp> literals "shared literals";
      list<SimCodeFunction.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<SimEqSystem> localKnownVars "state and input dependent variables, that are not inserted into any partion";
      list<SimEqSystem> allEquations;
      list<list<SimEqSystem>> odeEquations;
      list<list<SimEqSystem>> algebraicEquations;
      list<ClockedPartition> clockedPartitions;
      list<SimEqSystem> initialEquations;
      list<SimEqSystem> initialEquations_lambda0;
      list<SimEqSystem> removedInitialEquations;
      list<SimEqSystem> startValueEquations;
      list<SimEqSystem> nominalValueEquations;
      list<SimEqSystem> minValueEquations;
      list<SimEqSystem> maxValueEquations;
      list<SimEqSystem> parameterEquations;
      list<SimEqSystem> removedEquations;
      list<SimEqSystem> algorithmAndEquationAsserts;
      list<SimEqSystem> equationsForZeroCrossings;
      list<SimEqSystem> jacobianEquations;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<StateSet> stateSets;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttributes;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<BackendDAE.ZeroCrossing> relations "only used by c runtime";
      list<BackendDAE.TimeEvent> timeEvents "only used by c runtime yet";
      list<DAE.ComponentRef> discreteModelVars;
      ExtObjInfo extObjInfo;
      SimCodeFunction.MakefileParams makefileParams;
      DelayedExpression delayedExps;
      list<JacobianMatrix> jacobianMatrixes;
      Option<SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix, fullPathPrefix "Used in FMI where files are generated in a special directory";
      String fmuTargetName;
      HpcOmSimCode.HpcOmData hpcomData;
      AvlTreeCRToInt.Tree valueReferences "Used in FMI";
      //maps each variable to an array of storage indices (with this information, arrays must not be unrolled) and a list for the array-dimensions
      //if the variable is not part of an array (if it is a scalar value), then the array has size 1
      HashTableCrIListArray.HashTable varToArrayIndexMapping;
      //*** a protected section *** not exported to SimCodeTV
      HashTableCrILst.HashTable varToIndexMapping;
      HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
      Option<BackendMapping> backendMapping;
      //FMI 2.0 data for model structure
      Option<FmiModelStructure> modelStructure;
      PartitionData partitionData;
      Option<DaeModeData> daeModeData;
      list<SimEqSystem> inlineEquations;
      Option<OMSIData> omsiData "used for OMSI to generate equations code";
    algorithm
      ModelInfo modelInfo;
      list<DAE.Exp> literals "shared literals";
      list<SimCodeFunction.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes;
      list<SimEqSystem> localKnownVars "state and input dependent variables, that are not inserted into any partion";
      list<SimEqSystem> allEquations;
      list<list<SimEqSystem>> odeEquations;
      list<list<SimEqSystem>> algebraicEquations;
      list<ClockedPartition> clockedPartitions;
      list<SimEqSystem> initialEquations;
      list<SimEqSystem> initialEquations_lambda0;
      list<SimEqSystem> removedInitialEquations;
      list<SimEqSystem> startValueEquations;
      list<SimEqSystem> nominalValueEquations;
      list<SimEqSystem> minValueEquations;
      list<SimEqSystem> maxValueEquations;
      list<SimEqSystem> parameterEquations;
      list<SimEqSystem> removedEquations;
      list<SimEqSystem> algorithmAndEquationAsserts;
      list<SimEqSystem> equationsForZeroCrossings;
      list<SimEqSystem> jacobianEquations;
      //list<DAE.Statement> algorithmAndEquationAsserts;
      list<StateSet> stateSets;
      list<DAE.Constraint> constraints;
      list<DAE.ClassAttributes> classAttributes;
      list<BackendDAE.ZeroCrossing> zeroCrossings;
      list<BackendDAE.ZeroCrossing> relations "only used by c runtime";
      list<BackendDAE.TimeEvent> timeEvents "only used by c runtime yet";
      list<DAE.ComponentRef> discreteModelVars;
      ExtObjInfo extObjInfo;
      SimCodeFunction.MakefileParams makefileParams;
      DelayedExpression delayedExps;
      list<JacobianMatrix> jacobianMatrixes;
      Option<SimulationSettings> simulationSettingsOpt;
      String fileNamePrefix, fullPathPrefix "Used in FMI where files are generated in a special directory";
      String fmuTargetName;
      HpcOmSimCode.HpcOmData hpcomData;
      AvlTreeCRToInt.Tree valueReferences "Used in FMI";
      //maps each variable to an array of storage indices (with this information, arrays must not be unrolled) and a list for the array-dimensions
      //if the variable is not part of an array (if it is a scalar value), then the array has size 1
      HashTableCrIListArray.HashTable varToArrayIndexMapping;
      //*** a protected section *** not exported to SimCodeTV
      HashTableCrILst.HashTable varToIndexMapping;
      HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
      Option<BackendMapping> backendMapping;
      //FMI 2.0 data for model structure
      Option<FmiModelStructure> modelStructure;
      PartitionData partitionData;
      Option<DaeModeData> daeModeData;
      list<SimEqSystem> inlineEquations;
      Option<OMSIData> omsiData "used for OMSI to generate equations code";



      oldSimCode := SimCode.SIMCODE(modelInfo,
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
                                OldSimCode.DELAYED_EXPRESSIONS(delayedExps, maxDelayedExpIndex),
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
                                OldSimCode.emptyPartitionData,
                                NONE(),
                                inlineEquations,
                                omsiOptData
                                );

    end toOldSimCode;
*/
  end SimCode;

  uniontype ModelInfo
    record MODEL_INFO
      Absyn.Path name;
      String description;
      String directory;
      SimVars vars;
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
      output ModelInfo modelInfo;
    protected
      SimVars vars;
    algorithm
      vars := SimVars.create(varData);
      modelInfo := MODEL_INFO(name, "", "", vars, {}, {}, {}, {}, 0, 0, true, {}, {});
    end create;
  end ModelInfo;

  uniontype DaeModeData
    "contains data that belongs to the dae mode"
    record DAE_MODE_DATA
      list<list<SimStrongComponent.Block>> daeEquations "daeModel residuals equations";
      Option<SimStrongComponent.Jacobian> sparsityPattern "contains the sparsity pattern for the daeMode";
      list<SimVar> residualVars "variable used to calculate residuals of a DAE form, they are real";
      list<SimVar> algebraicVars;
      list<SimVar> auxiliaryVars;
      DaeModeConfig modeCreated;
    end DAE_MODE_DATA;

    function create
      input list<System.System> systems;
      output Option<DaeModeData> data;
      input output Integer uniqueEquationIndex;
    protected
      list<list<SimStrongComponent.Block>> blcks;
    algorithm
      (blcks, uniqueEquationIndex) := SimStrongComponent.Block.createBlocks(systems, uniqueEquationIndex);
      data := SOME(DAE_MODE_DATA(blcks, NONE(), {}, {}, {}, DaeModeConfig.ALL));
    end create;
  end DaeModeData;

  type DaeModeConfig = enumeration(ALL, DYNAMIC);
  annotation(__OpenModelica_Interface="backend");
end NSimCode;

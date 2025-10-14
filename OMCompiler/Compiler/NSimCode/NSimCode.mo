/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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
  import NFFlatten.{FunctionTree, FunctionTreeImpl};
  import NFInstNode.InstNode;
  import Type = NFType;

  // Old Backend imports
  import OldBackendDAE = BackendDAE;

  // Backend imports
  import AliasInfo = NBStrongComponent.AliasInfo;
  import BackendDAE = NBackendDAE;
  import NBPartitioning.ClockedInfo;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointer, EquationPointers, EqData};
  import NBEvents.EventInfo;
  import NBVariable.{VariablePointers, VarData};
  import BVariable = NBVariable;
  import Partition = NBPartition;

  // SimCode imports
  import SimCodeUtil = NSimCodeUtil;
  import NSimJacobian.SimJacobian;
  import SimGenericCall = NSimGenericCall;
  import SimPartition = NSimPartition;
  import SimStrongComponent = NSimStrongComponent;
  import NSimVar.{SimVar, SimVars, VarInfo, ExtObjInfo};
  import SymbolTable;

  // Old SimCode imports
  import HpcOmSimCode;
  import OldSimCode = SimCode;
  import OldSimCodeFunction = SimCodeFunction;
  import OldSimCodeFunctionUtil = SimCodeFunctionUtil;
  import OldSimCodeUtil = SimCodeUtil;

  // Util imports
  import Error;
  import StringUtil;

  // Script imports
  import CevalScriptBackend;

public
  uniontype SimCodeIndices
    record SIM_CODE_INDICES
      "Unique simulation code indices"
      Integer uniqueIndex;

      Integer realVarIndex;
      Integer integerVarIndex;
      Integer booleanVarIndex;
      Integer stringVarIndex;
      Integer enumerationVarIndex;

      Integer realParamIndex;
      Integer integerParamIndex;
      Integer booleanParamIndex;
      Integer stringParamIndex;
      Integer enumerationParamIndex;

      Integer realAliasIndex;
      Integer integerAliasIndex;
      Integer booleanAliasIndex;
      Integer stringAliasIndex;
      Integer enumerationAliasIndex;

      Integer equationIndex;
      Integer linearSystemIndex;
      Integer nonlinearSystemIndex;

      Integer jacobianIndex;
      Integer residualIndex;
      Integer implicitIndex; // this can be removed i think -> moved to solve
      Integer extObjIndex;

      UnorderedMap<AliasInfo, Integer> alias_map;
      UnorderedMap<Identifier, Integer> generic_call_map;
    end SIM_CODE_INDICES;
  end SimCodeIndices;

  uniontype Identifier
    record IDENTIFIER
      Pointer<Equation> eqn;
      ComponentRef var_cref;
      Boolean resizable;
    end IDENTIFIER;

    function toString
      input Identifier ident;
      output String str = "cref: " + ComponentRef.toString(ident.var_cref) + "\neqn: " + Equation.pointerToString(ident.eqn) + "\n(resizable="+boolString(ident.resizable)+")";
    end toString;

    function hash
      input Identifier ident;
      output Integer i = stringHashDjb2(toString(ident));
    end hash;

    function isEqual
      input Identifier ident1;
      input Identifier ident2;
      output Boolean b = Equation.equalName(ident1.eqn, ident2.eqn) and ComponentRef.isEqual(ident1.var_cref, ident2.var_cref);
    end isEqual;
  end Identifier;

  function EMPTY_SIM_CODE_INDICES
    output SimCodeIndices indices = SIM_CODE_INDICES(
      1,
      0,0,0,0,0,
      0,0,0,0,0,
      0,0,0,0,0,
      1,0,0,
      0,0,0,0,
      UnorderedMap.new<Integer>(AliasInfo.hash, AliasInfo.isEqual),
      UnorderedMap.new<Integer>(Identifier.hash, Identifier.isEqual)
    );
  end EMPTY_SIM_CODE_INDICES;

  uniontype SimCode
    record SIM_CODE
      ModelInfo modelInfo;
      list<Expression> literals                         "shared literals";
      list<SimCodeFunction.RecordDeclaration> recordDecls;
      list<String> externalFunctionIncludes             "Names of all external functions that are called";
      list<SimGenericCall> generic_loop_calls           "Generic for-loop and array calls";
      list<SimStrongComponent.Block> independent        "state and strictly input dependent variables. they are not inserted into any partion";
      list<SimStrongComponent.Block> allSim             "All simulation system blocks";
      list<list<SimStrongComponent.Block>> ode          "Only ode blocks for integrator";
      list<list<SimStrongComponent.Block>> algebraic    "Additional purely algebraic blocks";
      list<SimPartition> clockedPartitions              "Clocked Partitions";
      list<SimStrongComponent.Block> nominal            "Blocks for nominal value equations";
      list<SimStrongComponent.Block> min                "Blocks for min value equations";
      list<SimStrongComponent.Block> max                "Blocks for max value equations";
      list<SimStrongComponent.Block> param              "Blocks for parameter equations";
      list<SimStrongComponent.Block> no_ret             "Blocks for equations without return value";
      list<SimStrongComponent.Block> algorithms         "Blocks for algorithms and asserts";
      list<SimStrongComponent.Block> event_blocks       "Blocks for zero crossing functions";
      list<SimStrongComponent.Block> jac_blocks         "Blocks for jacobian equations";
      list<SimStrongComponent.Block> start              "Blocks for start value equations";
      list<SimStrongComponent.Block> init               "Blocks for initial equations";
      list<SimStrongComponent.Block> init_0             "Blocks for initial lambda 0 equations (homotopy)";
      list<SimStrongComponent.Block> init_no_ret        "Blocks for initial equations without return value";
      //list<DAE.Statement> algorithmAndEquationAsserts;
      //list<StateSet> stateSets;
      //list<DAE.Constraint> constraints;
      //list<DAE.ClassAttributes> classAttributes;
      list<ComponentRef> discreteVars                   "List of discrete variables";
      ExtObjInfo extObjInfo;
      OldSimCodeFunction.MakefileParams makefileParams;
      //DelayedExpression delayedExps;
      list<SimJacobian> jacobians       "List of symbolic jacobians";
      Option<OldSimCode.SimulationSettings> simulationSettingsOpt; // replace this with new struct
      String fileNamePrefix;//, fullPathPrefix "Used in FMI where files are generated in a special directory";
      //String fmuTargetName;
      //HpcOmSimCode.HpcOmData hpcomData;
      //AvlTreeCRToInt.Tree valueReferences "Used in FMI";
      //maps each variable to an array of storage indices (with this information, arrays must not be unrolled) and a list for the array-dimensions
      //if the variable is not part of an array (if it is a scalar value), then the array has size 1
      //HashTableCrIListArray.HashTable varToArrayIndexMapping;
      //*** a protected section *** not exported to SimCodeTV
      //HashTableCrILst.HashTable varToIndexMapping;
      UnorderedMap<ComponentRef, SimVar> simcode_map;
      UnorderedMap<ComponentRef, SimStrongComponent.Block> equation_map;
      //HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
      //Option<BackendMapping> backendMapping;
      //FMI 2.0 data for model structure
      //Option<FmiModelStructure> modelStructure;
      //PartitionData partitionData;
      EventInfo eventInfo;
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
      str := StringUtil.headline_1("SimCode " + str + "(" + simCode.fileNamePrefix + ")");
      str := str + ModelInfo.toString(simCode.modelInfo);
      str := str + ExtObjInfo.toString(simCode.extObjInfo);
      if not listEmpty(simCode.init_0) then
        str := str + SimStrongComponent.Block.listToString(simCode.init_0, "  ", "Initial Partition (Lambda = 0)") + "\n";
      end if;
      str := str + SimStrongComponent.Block.listToString(simCode.init, "  ", "Initial Partition") + "\n";
      for blck_lst in simCode.ode loop
        str := str + SimStrongComponent.Block.listToString(blck_lst, "  ", "ODE Partition " + intString(idx)) + "\n";
        idx := idx + 1;
      end for;
      idx := 1;
      for blck_lst in simCode.algebraic loop
        str := str + SimStrongComponent.Block.listToString(blck_lst, "  ", "Algebraic Partition " + intString(idx)) + "\n";
        idx := idx + 1;
      end for;
      str := str + SimStrongComponent.Block.listToString(simCode.allSim, "  ", "Event Partition") + "\n";
      if not listEmpty(simCode.clockedPartitions) then
        str := str + SimPartition.listToString(simCode.clockedPartitions, "  ", "Clocked Partitions") + "\n";
      end if;
      if not listEmpty(simCode.literals) then
        str := str + StringUtil.headline_3("Shared Literals");
        str := str + List.toString(simCode.literals, Expression.toString, "", "  ", "\n  ", "\n\n");
      end if;
      if not listEmpty(simCode.generic_loop_calls) then
        str := str + StringUtil.headline_3("Generic Calls");
        str := str + List.toString(simCode.generic_loop_calls, SimGenericCall.toString, "", "  ", "\n  ", "\n\n");
      end if;
      if isSome(simCode.daeModeData) then
        str := str + DaeModeData.toString(Util.getOption(simCode.daeModeData)) + "\n";
      end if;
      for jac in simCode.jacobians loop
        str := str + SimJacobian.toString(jac);
      end for;
      str := str + EventInfo.toString(simCode.eventInfo);
      //str := str + SimStrongComponent.Block.listToString(simCode.no_ret, "  ", "REMOVED / ALIAS / KNOWN") + "\n";
    end toString;

    function create
      input BackendDAE bdae;
      input Absyn.Path name;
      input String fileNamePrefix;
      input Option<OldSimCode.SimulationSettings> simSettingsOpt;
      output SimCode simCode;
    protected
      partial function mapExp
        input output Expression exp;
      end mapExp;
    algorithm
      simCode := match bdae
        local
          // auxillaries
          VarData varData;
          EqData eqData;
          FunctionTree funcTree;
          VariablePointers residual_vars;
          SimVars vars;
          // old SimCode strcutures
          Absyn.Program program;
          list<String> libs, includes, includeDirs, libPaths;
          String directory;
          OldSimCodeFunction.MakefileParams makefileParams;
          list<OldSimCodeFunction.Function> functions;
          list<OldSimCodeFunction.RecordDeclaration> recordDecls;
          // New SimCode structures
          ModelInfo modelInfo;
          SimCodeIndices simCodeIndices;
          UnorderedMap<Expression, Integer> literals_map = UnorderedMap.new<Integer>(Expression.hash, Expression.isEqual);
          list<SimPartition> clockedPartitions;
          Pointer<Integer> literals_idx = Pointer.create(0);
          list<Expression> literals;
          list<String> externalFunctionIncludes;
          list<SimGenericCall> generic_loop_calls;
          list<SimStrongComponent.Block> independent, allSim = {}, nominal, min, max, param, no_ret, event_clocks, algorithms;
          list<SimStrongComponent.Block> event_blocks = {}, jac_blocks;
          list<SimStrongComponent.Block> init, init_0, init_no_ret, start;
          list<list<SimStrongComponent.Block>> ode, algebraic;
          list<SimStrongComponent.Block> linearLoops, nonlinearLoops;
          list<ComponentRef> discreteVars;
          ExtObjInfo extObjInfo;
          list<SimJacobian> jacobians;
          UnorderedMap<ComponentRef, SimVar> simcode_map;
          UnorderedMap<ComponentRef, SimStrongComponent.Block> equation_map;
          Option<DaeModeData> daeModeData;
          SimJacobian jacA, jacB, jacC, jacD, jacF, jacH;
          list<SimStrongComponent.Block> inlineEquations; // ToDo: what exactly is this?
          mapExp collect_literals;
        case BackendDAE.MAIN(varData = varData as BVariable.VAR_DATA_SIM(), eqData = eqData as BEquation.EQ_DATA_SIM())
          algorithm
            // somehow this cannot be set at definition (metamodelica bug?)
            simCodeIndices := EMPTY_SIM_CODE_INDICES();
            funcTree := BackendDAE.getFunctionTree(bdae);

            // get and replace all literals in functions
            collect_literals    := function Expression.fakeMap(func = function Expression.replaceLiteral(map = literals_map, idx_ptr = literals_idx));
            funcTree            := FunctionTreeImpl.mapExp(funcTree, collect_literals);

            // create sim vars before everything else
            residual_vars                       := BackendDAE.getLoopResiduals(bdae);
            (vars, simCodeIndices)              := SimVars.create(varData, residual_vars, simCodeIndices);
            (extObjInfo, vars, simCodeIndices)  := ExtObjInfo.create(varData.external_objects, vars, simCodeIndices);
            simcode_map                         := SimCodeUtil.createSimCodeMap(vars, extObjInfo);

            // create empty equation map and fill while creating the blocks
            equation_map := UnorderedMap.new<SimStrongComponent.Block>(ComponentRef.hash, ComponentRef.isEqual);

            externalFunctionIncludes := {};

            independent := {};
            nominal := {};
            min := {};
            max := {};
            // all non constant parameter equations will be added to the initial system.
            // There is no actual need for parameter equations block
            param := {};
            algorithms := {};

            // init before everything else!
            (init, simCodeIndices) := SimStrongComponent.Block.createInitialBlocks(bdae.init, simCodeIndices, simcode_map, equation_map);
            if isSome(bdae.init_0) then
              (init_0, simCodeIndices) := SimStrongComponent.Block.createInitialBlocks(Util.getOption(bdae.init_0), simCodeIndices, simcode_map, equation_map);
            else
              init_0 := {};
            end if;

            // create clocked partitions
            (clockedPartitions, event_clocks, simCodeIndices) := SimStrongComponent.Block.createClockedBlocks(bdae.clocked, simCodeIndices, simcode_map, equation_map, bdae.clockedInfo);

            // start allSim with no return equations
            (no_ret, simCodeIndices) := SimStrongComponent.Block.createNoReturnBlocks(eqData.removed, simCodeIndices, NBPartition.Kind.ODE, simcode_map, equation_map);
            init_no_ret := {};
            start := {};
            discreteVars := {};
            jacobians := {};

            if isSome(bdae.dae) then
              // DAEMode
              ode := {};
              algebraic := if listEmpty(no_ret) then {} else {no_ret};
              no_ret := listAppend(event_clocks, no_ret);
              if not listEmpty(no_ret) then
                allSim    := listReverse(listAppend(no_ret, listReverse(allSim)));
              end if;
              (daeModeData, simCodeIndices) := DaeModeData.create(Util.getOption(bdae.dae), simCodeIndices, simcode_map, equation_map);
            else
              // Normal Simulation
              daeModeData := NONE();
              (ode, allSim, simCodeIndices)                     := SimStrongComponent.Block.createBlocks(bdae.ode, allSim, simCodeIndices, simcode_map, equation_map);
              (algebraic, allSim, simCodeIndices)               := SimStrongComponent.Block.createBlocks(bdae.algebraic, allSim, simCodeIndices, simcode_map, equation_map);
              (ode, allSim, event_blocks, simCodeIndices)       := SimStrongComponent.Block.createDiscreteBlocks(bdae.ode_event, ode, allSim, event_blocks, simCodeIndices, simcode_map, equation_map);
              (algebraic, allSim, event_blocks, simCodeIndices) := SimStrongComponent.Block.createDiscreteBlocks(bdae.alg_event, algebraic, allSim, event_blocks, simCodeIndices, simcode_map, equation_map);
              if not listEmpty(no_ret) then
                algebraic := listReverse(no_ret :: listReverse(algebraic));
              end if;
              // append event_clocks to no_return after adding them to algebraic
              no_ret := listAppend(event_clocks, no_ret);
              if not listEmpty(no_ret) then
                // append them to the end, compiler won't let me do it unless i double reverse the lists
                allSim := listReverse(listAppend(no_ret, listReverse(allSim)));
              end if;
            end if;

            // add all entwined equations to all sim
            allSim := listAppend(List.flatten(list(SimStrongComponent.Block.collectEntwinedEquations(blck) for blck in allSim)), allSim);

            // ToDo add event system
            inlineEquations := {};

            // ToDo:
            // this has to be adapted at some point SimCodeFuntion needs to be translated
            // to new simcode and literals have to be based on new Expressions.
            // Will probably be mostly the same in all other regards
            program := SymbolTable.getAbsyn();
            directory := CevalScriptBackend.getFileDir(AbsynUtil.pathToCref(name), program);
            (libs, libPaths, _, includeDirs, recordDecls, functions, _) := OldSimCodeUtil.createFunctions(program, ConvertDAE.convertFunctionTree(funcTree));
            makefileParams := OldSimCodeFunctionUtil.createMakefileParams(includeDirs, libs, libPaths, false, false);

            (linearLoops, nonlinearLoops, jacobians, simCodeIndices) := collectAlgebraicLoops(init, init_0, ode, algebraic, daeModeData, simCodeIndices, simcode_map);

            if isSome(daeModeData) then
              (jacA, simCodeIndices) := SimJacobian.createSimulationJacobian(Util.getOption(bdae.dae), simCodeIndices, simcode_map);
              daeModeData := DaeModeData.addJacobian(daeModeData, jacA);
            else
              (jacA, simCodeIndices) := SimJacobian.createSimulationJacobian(listAppend(bdae.ode, bdae.ode_event), simCodeIndices, simcode_map);
            end if;

            (jacB, simCodeIndices) := SimJacobian.empty("B", simCodeIndices);
            (jacC, simCodeIndices) := SimJacobian.empty("C", simCodeIndices);
            (jacD, simCodeIndices) := SimJacobian.empty("D", simCodeIndices);
            (jacF, simCodeIndices) := SimJacobian.empty("F", simCodeIndices);
            (jacH, simCodeIndices) := SimJacobian.empty("H", simCodeIndices);
            //jacobians := jacA :: jacB :: jacC :: jacD :: jacF :: jacobians;
            jacobians := listReverse(jacH :: jacF :: jacD :: jacC :: jacB :: jacA :: jacobians);

            for jac in jacobians loop
              if Util.isSome(jac.jac_map) then
                vars := SimVars.addSeedAndJacobianVars(vars, UnorderedMap.toList(Util.getOption(jac.jac_map)));
              end if;
            end for;

            // jacobian blocks only from simulation jacobians
            jac_blocks := SimJacobian.getJacobiansBlocks({jacA, jacB, jacC, jacD, jacF, jacH});
            (jac_blocks, simCodeIndices) := SimStrongComponent.Block.fixIndices(jac_blocks, {}, simCodeIndices);

            // generate the generic loop calls and replace literal expressions
            generic_loop_calls  := list(SimGenericCall.fromIdentifier(tpl) for tpl in UnorderedMap.toList(simCodeIndices.generic_call_map));
            generic_loop_calls  := list(SimGenericCall.mapShallow(call, collect_literals) for call in generic_loop_calls);
            literals            := UnorderedMap.keyList(literals_map);

            (modelInfo, simCodeIndices) := ModelInfo.create(vars, name, directory, functions, linearLoops, nonlinearLoops, bdae.eventInfo, bdae.clockedInfo, simCodeIndices);

            simCode := SIM_CODE(
              modelInfo                 = modelInfo,
              literals                  = literals,
              recordDecls               = recordDecls,
              externalFunctionIncludes  = externalFunctionIncludes,
              generic_loop_calls        = generic_loop_calls,
              independent               = independent,
              allSim                    = allSim,
              ode                       = ode,
              algebraic                 = algebraic,
              clockedPartitions         = clockedPartitions,
              nominal                   = nominal,
              min                       = min,
              max                       = max,
              param                     = param,
              no_ret                    = no_ret,
              algorithms                = algorithms,
              event_blocks              = event_blocks,
              jac_blocks                = jac_blocks,
              start                     = start,
              init                      = init,
              init_0                    = init_0,
              init_no_ret               = init_no_ret,
              discreteVars              = discreteVars,
              extObjInfo                = extObjInfo,
              makefileParams            = makefileParams,
              jacobians                 = jacobians,
              simulationSettingsOpt     = simSettingsOpt,
              fileNamePrefix            = fileNamePrefix,
              simcode_map               = simcode_map,
              equation_map              = equation_map,
              eventInfo                 = bdae.eventInfo,
              daeModeData               = daeModeData,
              inlineEquations           = inlineEquations
            );
        then simCode;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end create;

    function convert
      input SimCode simCode;
      output OldSimCode.SimCode oldSimCode;
    protected
      OldSimCode.ModelInfo modelInfo;
      list<DAE.ComponentRef> discreteModelVars = {};
      list<OldBackendDAE.ZeroCrossing> zeroCrossings;
      list<OldBackendDAE.ZeroCrossing> relations     "== zeroCrossings for the most part (only eq pointer different?)";
      list<OldBackendDAE.TimeEvent> timeEvents;
      HashTableCrIListArray.HashTable varToArrayIndexMapping;
      HashTableCrILst.HashTable varToIndexMapping;
      OldSimCode.HashTableCrefToSimVar crefToSimVarHT "hidden from typeview - used by cref2simvar() for cref -> SIMVAR lookup available in templates.";
      HashTable.HashTable crefToClockIndexHT "map variables to clock indices";
      list<SimVar> residualVars;
    algorithm
      modelInfo := ModelInfo.convert(simCode.modelInfo);
      (zeroCrossings, relations, timeEvents) := EventInfo.convert(simCode.eventInfo, simCode.equation_map);

      (varToArrayIndexMapping, varToIndexMapping) := OldSimCodeUtil.createVarToArrayIndexMapping(modelInfo);
      crefToSimVarHT := SimCodeUtil.convertSimCodeMap(simCode.simcode_map);
      // do we still need the following for DAE mode?
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
        literals                      = list(Expression.toDAE(lit) for lit in simCode.literals),
        recordDecls                   = simCode.recordDecls, // ToDo: convert this to new structures
        externalFunctionIncludes      = simCode.externalFunctionIncludes,
        generic_loop_calls            = list(SimGenericCall.convert(gc) for gc in simCode.generic_loop_calls),
        localKnownVars                = SimStrongComponent.Block.convertList(simCode.independent),
        allEquations                  = SimStrongComponent.Block.convertList(simCode.allSim),
        odeEquations                  = SimStrongComponent.Block.convertListList(simCode.ode),
        algebraicEquations            = SimStrongComponent.Block.convertListList(simCode.algebraic),
        clockedPartitions             = list(SimPartition.convertBase(part) for part in simCode.clockedPartitions),
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
        equationsForZeroCrossings     = SimStrongComponent.Block.convertList(simCode.event_blocks),
        jacobianEquations             = SimStrongComponent.Block.convertList(simCode.jac_blocks),
        stateSets                     = {}, // ToDo: add this once state sets are supported
        constraints                   = {}, // ToDo: add this once constraints are supported
        classAttributes               = {}, // ToDo: add this once class attributes are supported
        zeroCrossings                 = zeroCrossings,
        relations                     = relations,
        timeEvents                    = timeEvents,
        discreteModelVars             = discreteModelVars,
        extObjInfo                    = ExtObjInfo.convert(simCode.extObjInfo), // ToDo: add this once external object info is supported
        makefileParams                = simCode.makefileParams, // ToDo: convert this to new structures
        delayedExps                   = OldSimCode.DELAYED_EXPRESSIONS({}, 0), // ToDo: add this once delayed expressions are supported
        spatialInfo                   = OldSimCode.SPATIAL_DISTRIBUTION_INFO({}, 0),
        jacobianMatrices              = list(SimJacobian.convert(jac) for jac in simCode.jacobians),
        simulationSettingsOpt         = simCode.simulationSettingsOpt, // replace with new struct later on
        fileNamePrefix                = simCode.fileNamePrefix,
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
        omsiData                      = NONE(),
        scalarized                    = Flags.getConfigBool(Flags.SIM_CODE_SCALARIZE));
    end convert;

    function getDirectoryAndLibs
      input SimCode simCode;
      output String directory;
      output list<String> libs;
    algorithm
      (directory, libs) := match simCode
        case SIM_CODE(modelInfo = MODEL_INFO(directory = directory), makefileParams = OldSimCodeFunction.MAKEFILE_PARAMS(libs = libs)) then (directory, libs);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end getDirectoryAndLibs;

  protected
    function collectAlgebraicLoops
      "Collects algebraic loops from all systems (ode, init, init_0, dae, ...).
      ToDo: Add other systems once implemented!"
      input list<SimStrongComponent.Block> init;
      input list<SimStrongComponent.Block> init_0;
      input list<list<SimStrongComponent.Block>> ode;
      input list<list<SimStrongComponent.Block>> algebraic;
      input Option<DaeModeData> daeModeData;
      output list<SimStrongComponent.Block> linearLoops = {};
      output list<SimStrongComponent.Block> nonlinearLoops = {};
      output list<SimJacobian> jacobians = {};
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      list<list<SimStrongComponent.Block>> dae_mode_blcks;
    algorithm
      (linearLoops, nonlinearLoops, jacobians, simCodeIndices) := SimStrongComponent.Block.collectAlgebraicLoops({init, init_0}, linearLoops, nonlinearLoops, jacobians, simCodeIndices, simcode_map);
      (linearLoops, nonlinearLoops, jacobians, simCodeIndices) := SimStrongComponent.Block.collectAlgebraicLoops(ode, linearLoops, nonlinearLoops, jacobians, simCodeIndices, simcode_map);
      (linearLoops, nonlinearLoops, jacobians, simCodeIndices) := SimStrongComponent.Block.collectAlgebraicLoops(algebraic, linearLoops, nonlinearLoops, jacobians, simCodeIndices, simcode_map);
      if isSome(daeModeData) then
        SOME(DAE_MODE_DATA(blcks = dae_mode_blcks)) := daeModeData;
        (linearLoops, nonlinearLoops, jacobians, simCodeIndices) := SimStrongComponent.Block.collectAlgebraicLoops(dae_mode_blcks, linearLoops, nonlinearLoops, jacobians, simCodeIndices, simcode_map);
      end if;
    end collectAlgebraicLoops;
  end SimCode;

  uniontype ModelInfo
    record MODEL_INFO
      Absyn.Path name;
      String description;
      String version;
      String author;
      String license;
      String copyright;
      String directory;
      String fileName;
      SimVars vars;
      VarInfo varInfo;
      list<SimCodeFunction.Function> functions;
      list<String> labels;
      list<String> resourcePaths "Paths of all resources used by the model. Used in FMI2 to package resources in the FMU.";
      list<Absyn.Class> sortedClasses;
      //Files files "all the files from SourceInfo and DAE.ElementSource";
      Integer nClocks;
      Integer nSubClocks;
      Integer nSpatialDistributions;
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
      input SimVars vars;
      input Absyn.Path name;
      input String directory;
      input list<OldSimCodeFunction.Function> functions;
      input list<SimStrongComponent.Block> linearLoops;
      input list<SimStrongComponent.Block> nonlinearLoops;
      input EventInfo eventInfo;
      input ClockedInfo clockedInfo;
      output ModelInfo modelInfo;
      input output SimCodeIndices simCodeIndices;
    protected
      VarInfo info;
    algorithm
      info := VarInfo.create(vars, eventInfo, simCodeIndices);
      modelInfo := MODEL_INFO(
        name                            = name,
        description                     = "",
        version                         = "",
        author                          = "",
        license                         = "",
        copyright                       = "",
        directory                       = directory,
        fileName                        = "",
        vars                            = vars,
        varInfo                         = info,
        functions                       = functions,
        labels                          = {},
        resourcePaths                   = {},
        sortedClasses                   = {},
        nClocks                         = UnorderedMap.size(clockedInfo.baseClocks),
        nSubClocks                      = UnorderedMap.size(clockedInfo.subClocks),
        nSpatialDistributions           = 0,
        hasLargeLinearEquationSystems   = true,
        linearLoops                     = linearLoops,
        nonlinearLoops                  = nonlinearLoops);
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
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
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
        version                         = modelInfo.version,
        author                          = modelInfo.author,
        license                         = modelInfo.license,
        copyright                       = modelInfo.copyright,
        directory                       = modelInfo.directory,
        fileName                        = modelInfo.fileName,
        varInfo                         = VarInfo.convert(modelInfo.varInfo),
        vars                            = SimVar.SimVars.convert(modelInfo.vars),
        functions                       = modelInfo.functions,
        labels                          = modelInfo.labels,
        resourcePaths                   = modelInfo.resourcePaths,
        sortedClasses                   = modelInfo.sortedClasses,
        //Files files "all the files from SourceInfo and DAE.ElementSource";
        nClocks                         = modelInfo.nClocks,
        nSubClocks                      = modelInfo.nSubClocks,
        nSpatialDistributions           = modelInfo.nSpatialDistributions,
        hasLargeLinearEquationSystems   = modelInfo.hasLargeLinearEquationSystems,
        linearSystems                   = SimStrongComponent.Block.convertList(modelInfo.linearLoops),
        nonLinearSystems                = SimStrongComponent.Block.convertList(modelInfo.nonlinearLoops),
        unitDefinitions                 = {} // ToDo: add this once unit definitions are supported
      );
    end convert;
  end ModelInfo;

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
      input list<Partition.Partition> systems;
      output Option<DaeModeData> data;
      input output SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      input UnorderedMap<ComponentRef, SimStrongComponent.Block> equation_map;
    protected
      list<list<SimStrongComponent.Block>> blcks;
      list<SimVar> residualVars, algebraicVars;
    algorithm
      (blcks, residualVars, simCodeIndices) := SimStrongComponent.Block.createDAEModeBlocks(systems, simCodeIndices, simcode_map, equation_map);
      data := SOME(DAE_MODE_DATA(blcks, NONE(), residualVars, {}, {}, DaeModeConfig.ALL));
    end create;

    function addJacobian
      input output Option<DaeModeData> data;
      input SimJacobian daeModeJac;
    algorithm
      data := match data
        local
          DaeModeData dmd;
        case SOME(dmd) algorithm
          dmd.sparsityPattern := SOME(daeModeJac);
        then SOME(dmd);
        else NONE();
      end match;
    end addJacobian;

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
        sparsityPattern = Util.applyOption(data.sparsityPattern, SimJacobian.convert),
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
      input list<Partition.Partition> systems;
      output SimJacobian jacobian;
      input output UnorderedMap<ComponentRef, SimVar> simcode_map;
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
            // update to UnorderedMap once reactivated
/*
            simulationHT := HashTableSimCode.addList(daeModeData.residualVars, simulationHT);
            if isSome(daeModeData.sparsityPattern) then
              SOME(jac) := daeModeData.sparsityPattern;
              simulationHT := HashTableSimCode.addList(jac.seedVars, simulationHT);
              modelInfo := ModelInfo.setSeedVars(modelInfo, jac.seedVars);
              daeModeData.algebraicVars := rewriteAlgebraicVarsIdx(modelInfo.vars.algVars, simulationHT);
              daeModeData.auxiliaryVars := {}; // this needs to be updated in the future
              //(daeModeJac, simCodeIndices) := SimJacobian.fromSystemsSparsity(systems, daeModeData.sparsityPattern, simulationHT, simCodeIndices);
              daeModeData.sparsityPattern := daeModeJac;
              jacobian := Util.getOption(daeModeJac);

            else
*/
              (jacobian, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
//            end if;
        then SOME(daeModeData);

        else
          algorithm
            Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end createSparsityJacobian;

    function rewriteAlgebraicVarsIdx
      input list<SimVar> simulationAlgVars;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
      output list<SimVar> daeModeAlgVars = {};
    protected
      ComponentRef seedCref, cref;
    algorithm
      seedCref := ComponentRef.fromNode(InstNode.VAR_NODE(NBVariable.SEED_STR + "_A", Pointer.create(NBVariable.DUMMY_VARIABLE)), Type.UNKNOWN());
      for var in listReverse(simulationAlgVars) loop
        cref := ComponentRef.append(var.name, seedCref);
        print("Searching for: " + ComponentRef.toString(cref) + "\n");
        var.index := SimVar.getIndex(cref, simcode_map);
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

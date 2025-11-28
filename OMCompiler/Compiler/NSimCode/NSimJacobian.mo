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
encapsulated package NSimJacobian
"file:        NSimJacobian.mo
 package:     NSimJacobian
 description: This file contains the functions for creating simcode jaobians and sparsity patterns.
"

public
  // NF imports
  import ComponentRef = NFComponentRef;
  import NFInstNode.InstNode;
  import FunctionTree = NFFlatten.FunctionTree;
  import Subscript = NFSubscript;
  import Type = NFType;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import NBEquation.{Equation, EquationPointer, EquationPointers, EqData};
  import BEquation = NBEquation;
  import NBVariable.{VariablePointers, VarData};
  import BVariable = NBVariable;
  import Jacobian = NBJacobian;
  import Partition = NBPartition;

  // SimCode imports
  import SimCodeUtil = NSimCodeUtil;
  import SimCode = NSimCode;
  import SimGenericCall = NSimGenericCall;
  import NSimCode.Identifier;
  import SimStrongComponent = NSimStrongComponent;
  import NSimVar.{SimVar, SimVars, VarType};

  // Old SimCode imports
  import OldSimCode = SimCode;

  // Util imports
  import StringUtil;

  type SparsityPattern = list<tuple<Integer, list<Integer>>>;
  type SparsityColoring = list<list<Integer>>;

  uniontype SimJacobian
    record SIM_JAC
      String name                                         "unique matrix name";
      Integer jacobianIndex                               "unique jacobian index";
      Integer partitionIndex                              "index of partition it belongs to";
      Integer numberOfResultVars                          "corresponds to the number of rows";
      list<SimStrongComponent.Block> columnEqns           "column equations equals in size to column vars";
      list<SimStrongComponent.Block> constantEqns         "List of constant equations independent of seed variables";
      list<SimVar> columnVars                             "all column vars, none results vars index -1, the other corresponding to rows index";
      list<SimVar> seedVars                               "corresponds to the number of columns";
      SparsityPattern sparsity                            "sparsity pattern in index form";
      SparsityPattern sparsityT                           "transposed sparsity pattern";
      SparsityColoring coloring                           "coloring groups in index form";
      Integer numColors                                   "number of colors";
      list<SimGenericCall> generic_loop_calls             "Generic for-loop and array calls";
      Option<UnorderedMap<ComponentRef, SimVar>> jac_map  "hash table for cref -> simVar";
    end SIM_JAC;

    function toString
      input SimJacobian simJac;
      output String str = "";
    protected
      Integer idx;
      list<Integer> dependencies;
    algorithm
      str := match simJac
        case SIM_JAC() algorithm
          if isEmpty(simJac) then
            str := StringUtil.headline_2("[EMPTY] SimCode Jacobian " + simJac.name + "(idx = " + intString(simJac.jacobianIndex) + ", partition = " + intString(simJac.partitionIndex) + ")") + "\n";
          else
            str := StringUtil.headline_2("SimCode Jacobian " + simJac.name + "(idx = " + intString(simJac.jacobianIndex) + ", partition = " + intString(simJac.jacobianIndex) + ")") + "\n";
            str := str + StringUtil.headline_4("ColumnVars (size = " + intString(simJac.numberOfResultVars) + ")");
            for var in simJac.columnVars loop
              str := str + SimVar.toString(var, "  ") + "\n";
            end for;
            str := str + "\n" + StringUtil.headline_4("SeedVars (size = " + intString(listLength(simJac.seedVars)) + ")");
            for var in simJac.seedVars loop
              str := str + SimVar.toString(var, "  ") + "\n";
            end for;
            str := str + "\n" + StringUtil.headline_3("Column Equations (size = " + intString(simJac.numberOfResultVars) + ")");
            for eq in simJac.columnEqns loop
              str := str + SimStrongComponent.Block.toString(eq, "  ");
            end for;
            if not listEmpty(simJac.constantEqns) then
              str := str + StringUtil.headline_3("Constant Equations");
              for eq in simJac.constantEqns loop
                str := str + SimStrongComponent.Block.toString(eq, "  ");
              end for;
            end if;
            str := str + "\n" + StringUtil.headline_4("Sparsity Pattern Cols");
            if not listEmpty(simJac.sparsityT) then
              for tpl in simJac.sparsityT loop
                (idx, dependencies) := tpl;
                str := str + "  " + intString(idx) + ":\t" + List.toString(dependencies, intString) + "\n";
              end for;
            end if;
            str := str + "\n" + StringUtil.headline_4("Sparsity Pattern Rows");
            if not listEmpty(simJac.sparsity) then
              for tpl in simJac.sparsity loop
                (idx, dependencies) := tpl;
                str := str + "  " + intString(idx) + ":\t" + List.toString(dependencies, intString) + "\n";
              end for;
            end if;
            str := str + "\n" + StringUtil.headline_4("Sparsity Coloring Groups");
            if not listEmpty(simJac.coloring) then
              for lst in simJac.coloring loop
                str := str +  "  " + List.toString(lst, intString) + "\n";
              end for;
            end if;
            if not listEmpty(simJac.generic_loop_calls) then
              str := str + StringUtil.headline_3("Generic Calls");
              str := str + List.toString(simJac.generic_loop_calls, SimGenericCall.toString, "", "  ", "\n  ", "\n");
            end if;
            str := str + "\n";
          end if;
        then str;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end toString;

    function isEmpty
      input SimJacobian simJac;
      output Boolean b;
    algorithm
      b := match simJac
        case SIM_JAC() then simJac.numberOfResultVars == 0;
        else false;
      end match;
    end isEmpty;

/*
    function fromSystems
      input list<System.System> partitions;
      output Option<SimJacobian> simJacobian;
      input output SimCode.SimCodeIndices indices;
    protected
      list<BackendDAE> jacobians = {};
    algorithm
      for partition in partitions loop
        if Util.isSome(partition.jacobian) then
          jacobians := Util.getOption(partition.jacobian) :: jacobians;
        end if;
      end for;

      if listEmpty(jacobians) then
        simJacobian := NONE();
      else
        (simJacobian, indices) := create(Jacobian.combine(jacobians, "A"), indices);
      end if;
    end fromSystems;

    function fromSystemsSparsity
      input list<System.System> partitions;
      input output Option<SimJacobian> simJacobian;
      input UnorderedMap<ComponentRef, SimVar> sim_map;
      input output SimCode.SimCodeIndices indices;
    algorithm
      (simJacobian, indices) := match (partitions, simJacobian)
        local
          BackendDAE jacobian;

        case (_, NONE())                                      then (NONE(), indices);
        case ({System.SYSTEM(jacobian = NONE())}, _)          then (NONE(), indices);
        case ({System.SYSTEM(jacobian = SOME(jacobian))}, _)  then createSparsity(jacobian, Util.getOption(simJacobian), sim_map, indices);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed! Partitioned partitions are not yet supported by this function."});
        then fail();

      end match;
    end fromSystemsSparsity;
*/
    function create
      input BackendDAE jacobian;
      output Option<SimJacobian> simJacobian;
      input output SimCode.SimCodeIndices indices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    algorithm
      simJacobian := match jacobian
        local
          // dummy map for strong component creation (no alias possible here)
          UnorderedMap<ComponentRef, SimVar> dummy_sim_map = UnorderedMap.new<SimVar>(ComponentRef.hash, ComponentRef.isEqual);
          UnorderedMap<ComponentRef, SimStrongComponent.Block> dummy_eqn_map = UnorderedMap.new<SimStrongComponent.Block>(ComponentRef.hash, ComponentRef.isEqual);
          SimStrongComponent.Block columnEqn;
          list<SimStrongComponent.Block> columnEqns = {};
          VarData varData;
          VariablePointers seed_vec, res_vec, tmp_vec;
          Pointer<list<SimVar>> seedVars_ptr = Pointer.create({});
          Pointer<list<SimVar>> resVars_ptr = Pointer.create({});
          Pointer<list<SimVar>> tmpVars_ptr = Pointer.create({});
          list<SimVar> seedVars, resVars, tmpVars;
          UnorderedMap<ComponentRef, SimVar> jac_map;
          UnorderedMap<ComponentRef, Integer> idx_map;
          ComponentRef cref;
          list<Subscript> subscripts;
          SparsityPattern sparsity, sparsityT;
          SparsityColoring coloring;
          SimJacobian jac;
          UnorderedMap<Identifier, Integer> sim_map;
          list<SimGenericCall> generic_loop_calls;

        case BackendDAE.JACOBIAN(varData = varData as BVariable.VAR_DATA_JAC()) algorithm
          // temporarily save the generic call map from simcode to recover it afterwards
          // we use a local map to have seperated generic call lists for each jacobian
          sim_map := indices.generic_call_map;
          indices.generic_call_map := UnorderedMap.new<Integer>(Identifier.hash, Identifier.isEqual);
          for i in arrayLength(jacobian.comps):-1:1 loop
            (columnEqn, indices, _) := SimStrongComponent.Block.fromStrongComponent(jacobian.comps[i], indices, NBPartition.Kind.JAC, dummy_sim_map, dummy_eqn_map);
            columnEqns := columnEqn :: columnEqns;
          end for;

          // extract generic loop calls and put the old generic call map back
          generic_loop_calls := list(SimGenericCall.fromIdentifier(tpl) for tpl in UnorderedMap.toList(indices.generic_call_map));
          indices.generic_call_map := sim_map;

          // scalarize variables for sim code
          if Flags.getConfigBool(Flags.SIM_CODE_SCALARIZE) then
            seed_vec := VariablePointers.scalarize(varData.seedVars);
            res_vec  := VariablePointers.scalarize(varData.resultVars);
            tmp_vec  := VariablePointers.scalarize(varData.tmpVars);
          else
            seed_vec := varData.seedVars;
            res_vec  := varData.resultVars;
            tmp_vec  := varData.tmpVars;
          end if;

          // use dummy simcode indices to always start at 0 for column and seed vars
          VariablePointers.map(seed_vec,  function SimVar.traverseCreate(acc = seedVars_ptr, indices_ptr = Pointer.create(NSimCode.EMPTY_SIM_CODE_INDICES()), varType = VarType.SIMULATION));
          VariablePointers.map(res_vec,   function SimVar.traverseCreate(acc = resVars_ptr,  indices_ptr = Pointer.create(NSimCode.EMPTY_SIM_CODE_INDICES()), varType = VarType.SIMULATION));
          VariablePointers.map(tmp_vec,   function SimVar.traverseCreate(acc = tmpVars_ptr,  indices_ptr = Pointer.create(NSimCode.EMPTY_SIM_CODE_INDICES()), varType = VarType.SIMULATION));
          seedVars  := listReverse(Pointer.access(seedVars_ptr));
          resVars   := listReverse(Pointer.access(resVars_ptr));
          tmpVars   := listReverse(Pointer.access(tmpVars_ptr));

          jac_map := UnorderedMap.new<SimVar>(ComponentRef.hash, ComponentRef.isEqual, listLength(seedVars) + listLength(resVars) + listLength(tmpVars));
          SimCodeUtil.addListSimCodeMap(seedVars, jac_map);
          SimCodeUtil.addListSimCodeMap(resVars, jac_map);
          SimCodeUtil.addListSimCodeMap(tmpVars, jac_map);

          try
            idx_map := UnorderedMap.new<Integer>(ComponentRef.hash, ComponentRef.isEqual, listLength(seedVars) + listLength(resVars));
            if Jacobian.isDynamic(jacobian.jacType) then
              for var in seedVars loop
                cref := SimVar.getName(var);
                if BVariable.checkCref(cref, BVariable.isSeed, sourceInfo()) then
                  // FIXME this should not happen, fix it when collecting seedVars!
                  cref := BVariable.getPartnerCref(cref, BVariable.getVarSeed);
                end if;
                UnorderedMap.add(cref, var.index, idx_map);
                if BVariable.checkCref(cref, BVariable.isState, sourceInfo()) then
                  cref := BVariable.getPartnerCref(cref, BVariable.getVarDer);
                  UnorderedMap.add(cref, var.index, idx_map);
                end if;
              end for;

              // also add residuals if its DAE Mode
              if jacobian.jacType == NBJacobian.JacobianType.DAE then
                for var in resVars loop
                  cref := SimVar.getName(var);
                  UnorderedMap.add(cref, var.index, idx_map);
                  //cref := BVariable.getPartnerCref(cref, BVariable.getVarPDer);
                  //UnorderedMap.add(cref, var.index, idx_map);
                end for;
              end if;
            else
              for var in seedVars loop
                cref := SimVar.getName(var);
                UnorderedMap.add(cref, var.index, idx_map);
                cref := BVariable.getPartnerCref(cref, BVariable.getVarSeed);
                UnorderedMap.add(cref, var.index, idx_map);
              end for;
              for var in resVars loop
                cref := SimVar.getName(var);
                UnorderedMap.add(cref, var.index, idx_map);
                cref := BVariable.getPartnerCref(cref, BVariable.getVarPDer);
                UnorderedMap.add(cref, var.index, idx_map);
              end for;
            end if;

            (sparsity, sparsityT, coloring) := createSparsity(jacobian, idx_map);

            jac := SIM_JAC(
              name                = jacobian.name,
              jacobianIndex       = indices.jacobianIndex,
              partitionIndex      = 0,
              numberOfResultVars  = listLength(resVars),
              columnEqns          = columnEqns,
              constantEqns        = {},
              columnVars          = resVars,
              seedVars            = seedVars,
              sparsity            = sparsity,
              sparsityT           = sparsityT,
              coloring            = coloring,
              numColors           = listLength(coloring),
              generic_loop_calls  = generic_loop_calls,
              jac_map             = SOME(jac_map)
            );

            indices.jacobianIndex := indices.jacobianIndex + 1;
            simJacobian := SOME(jac);
          else
            simJacobian := NONE();
            Error.addCompilerWarning(getInstanceName() + " could not generate sparsity pattern.");
          end try;
        then simJacobian;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end create;

    function createSimulationJacobian
      input list<Partition.Partition> partitions;
      output SimJacobian simJac;
      input output SimCode.SimCodeIndices simCodeIndices;
      input UnorderedMap<ComponentRef, SimVar> simcode_map;
    protected
      list<BackendDAE> jacobians = {};
      BackendDAE simJacobian;
      Option<SimJacobian> simJac_opt;
      Option<BackendDAE> jacobian;
    algorithm
      for partition in partitions loop
        // save jacobian if existent
        jacobian := Partition.Partition.getJacobian(partition);
        if Util.isSome(jacobian) then
          jacobians := Util.getOption(jacobian) :: jacobians;
        end if;
      end for;

      // create empty jacobian as fallback
      if listEmpty(jacobians) then
        (simJac, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
      else
        simJacobian := Jacobian.combine(jacobians, "A");
        (simJac_opt, simCodeIndices) := SimJacobian.create(simJacobian, simCodeIndices, simcode_map);
        if Util.isSome(simJac_opt) then
          simJac := Util.getOption(simJac_opt);
        else
          (simJac, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
        end if;
      end if;
    end createSimulationJacobian;

    function createSparsity
      input BackendDAE jacobian;
      input UnorderedMap<ComponentRef, Integer> idx_map;
      output SparsityPattern sparsity;
      output SparsityPattern sparsityT;
      output SparsityColoring coloring;
    algorithm
      (sparsity, sparsityT, coloring) := match jacobian
        local
          Jacobian.SparsityPattern Bpattern;
          Jacobian.SparsityColoring Bcoloring;

        case BackendDAE.JACOBIAN(sparsityPattern = Bpattern, sparsityColoring = Bcoloring) algorithm
          sparsity  := createSparsityPattern(Bpattern.col_wise_pattern, idx_map);
          sparsityT := createSparsityPattern(Bpattern.row_wise_pattern, idx_map);
          coloring  := createSparsityColoring(Bcoloring, idx_map);
        then (sparsity, sparsityT, coloring);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end createSparsity;

    function createSparsityPattern
      input list<Jacobian.SparsityPatternCol> cols      "columns that need to be generated (can be used for rows too)";
      input UnorderedMap<ComponentRef, Integer> idx_map "hash table cref --> index";
      output SparsityPattern simPattern = {};
    protected
      ComponentRef cref;
      list<ComponentRef> dependencies;
      list<Integer> dep_indices;
    algorithm
      for col in cols loop
        (cref, dependencies) := col;
        dep_indices := List.map(dependencies, function UnorderedMap.getOrFail(map = idx_map));
        simPattern := (UnorderedMap.getOrFail(cref, idx_map), List.sort(dep_indices, intGt)) :: simPattern;
      end for;
      simPattern := List.sort(simPattern, sparsityTplSortGt);
    end createSparsityPattern;

    function sparsityTplSortGt
      input tuple<Integer, list<Integer>> col1 "or row1";
      input tuple<Integer, list<Integer>> col2 "or row2";
      output Boolean b = Util.tuple21(col1) > Util.tuple21(col2);
    end sparsityTplSortGt;

    function createSparsityColoring
      input Jacobian.SparsityColoring coloring;
      input UnorderedMap<ComponentRef, Integer> idx_map;
      output SparsityColoring simColoring;
    algorithm
      simColoring := list(List.map(group, function UnorderedMap.getOrFail(map = idx_map)) for group in coloring.cols);
    end createSparsityColoring;

    function empty
      input String name = "";
      output SimJacobian emptyJac = EMPTY_SIM_JAC;
      input output SimCode.SimCodeIndices indices;
    algorithm
      emptyJac := match emptyJac
        case SIM_JAC() algorithm
          emptyJac.name := name;
          emptyJac.jacobianIndex := indices.jacobianIndex;
          indices.jacobianIndex := indices.jacobianIndex + 1;
        then emptyJac;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end empty;

    function getJacobianBlocks
      input SimJacobian jacobian;
      output list<SimStrongComponent.Block> blcks;
    algorithm
      blcks := match jacobian
        case SIM_JAC() then listAppend(jacobian.constantEqns, jacobian.columnEqns);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end getJacobianBlocks;

    function getJacobiansBlocks
      input list<SimJacobian> jacobians;
      output list<SimStrongComponent.Block> blcks = {};
    algorithm
      for jacobian in jacobians loop
        blcks := listAppend(getJacobianBlocks(jacobian), blcks);
      end for;
    end getJacobiansBlocks;

    function getJacobianHT
      input SimJacobian jacobian;
      output Option<UnorderedMap<ComponentRef, SimVar>> jac_map;
    algorithm
      jac_map := match jacobian
        case SIM_JAC() then jacobian.jac_map;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end getJacobianHT;

    function convert
      input SimJacobian simJac;
      output OldSimCode.JacobianMatrix oldJac;
    protected
      OldSimCode.JacobianColumn oldJacCol;
    algorithm
      oldJac := match simJac
        case SIM_JAC() algorithm
          oldJacCol := OldSimCode.JAC_COLUMN(
            columnEqns          = list(SimStrongComponent.Block.convert(blck) for blck in simJac.columnEqns),
            columnVars          = list(SimVar.convert(var) for var in simJac.columnVars),
            numberOfResultVars  = simJac.numberOfResultVars,
            constantEqns        = list(SimStrongComponent.Block.convert(blck) for blck in simJac.constantEqns)
          );

          oldJac := OldSimCode.JAC_MATRIX(
            columns             = {oldJacCol},
            seedVars            = SimVar.convertList(simJac.seedVars),
            matrixName          = simJac.name,
            sparsity            = simJac.sparsity,
            sparsityT           = simJac.sparsityT,
            nonlinear           = {}, // kabdelhak: these have to be computed in the backend using the jacobian
            nonlinearT          = {},
            coloredCols         = simJac.coloring,
            maxColorCols        = simJac.numColors,
            jacobianIndex       = simJac.jacobianIndex,
            partitionIndex      = simJac.partitionIndex,
            generic_loop_calls  = list(SimGenericCall.convert(gc) for gc in simJac.generic_loop_calls),
            crefsHT             = Util.applyOption(simJac.jac_map, SimCodeUtil.convertSimCodeMap)
          );
        then oldJac;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
        then fail();
      end match;
    end convert;
  end SimJacobian;

  constant SimJacobian EMPTY_SIM_JAC = SIM_JAC("", 0, 0, 0, {}, {}, {}, {}, {}, {}, {}, 0, {}, NONE());

  annotation(__OpenModelica_Interface="backend");
end NSimJacobian;

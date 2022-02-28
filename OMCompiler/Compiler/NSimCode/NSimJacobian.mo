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
 description: This file contains the main data type for the backend containing
              all data. It further contains the lower and solve main function.
"

public
  // NF imports
  import ComponentRef = NFComponentRef;
  import NFInstNode.InstNode;
  import FunctionTree = NFFlatten.FunctionTree;
  import Type = NFType;

  // Backend imports
  import BackendDAE = NBackendDAE;
  import NBEquation.{Equation, EquationPointers, EqData};
  import BEquation = NBEquation;
  import NBVariable.{VariablePointers, VarData};
  import BVariable = NBVariable;
  import Jacobian = NBJacobian;
  import System = NBSystem;

  // SimCode imports
  import HashTableSimCode;
  import SimCode = NSimCode;
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
      String name                                     "unique matrix name";
      Integer jacobianIndex                           "unique jacobian index";
      Integer partitionIndex                          "index of partition it belongs to";
      Integer numberOfResultVars                      "corresponds to the number of rows";
      list<SimStrongComponent.Block> columnEqns       "column equations equals in size to column vars";
      list<SimStrongComponent.Block> constantEqns     "List of constant equations independent of seed variables";
      list<SimVar> columnVars                  "all column vars, none results vars index -1, the other corresponding to rows index";
      list<SimVar> seedVars                    "corresponds to the number of columns";
      SparsityPattern sparsity                        "sparsity pattern in index form";
      SparsityPattern sparsityT                       "transposed sparsity pattern";
      SparsityColoring coloring                       "coloring groups in index form";
      Integer numColors                               "number of colors";
      Option<HashTableSimCode.HashTable> jacobianHT   "hash table for cref -> simVar";
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
            str := str + "\n" + StringUtil.headline_4("SeedVars");
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
            end if;        str := str + "\n" + StringUtil.headline_4("Sparsity Coloring Groups");
            if not listEmpty(simJac.coloring) then
              for lst in simJac.coloring loop
                str := str +  "  " + List.toString(lst, intString) + "\n";
              end for;
            end if;
            str := str + "\n";
          end if;
        then str;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
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
      input list<System.System> systems;
      output Option<SimJacobian> simJacobian;
      input output SimCode.SimCodeIndices indices;
    protected
      list<BackendDAE> jacobians = {};
    algorithm
      for system in systems loop
        if Util.isSome(system.jacobian) then
          jacobians := Util.getOption(system.jacobian) :: jacobians;
        end if;
      end for;

      if listEmpty(jacobians) then
        simJacobian := NONE();
      else
        (simJacobian, indices) := create(Jacobian.combine(jacobians, "A"), indices);
      end if;
    end fromSystems;

    function fromSystemsSparsity
      input list<System.System> systems;
      input output Option<SimJacobian> simJacobian;
      input HashTableSimCode.HashTable simulationHT;
      input output SimCode.SimCodeIndices indices;
    algorithm
      (simJacobian, indices) := match (systems, simJacobian)
        local
          BackendDAE jacobian;

        case (_, NONE())                                      then (NONE(), indices);
        case ({System.SYSTEM(jacobian = NONE())}, _)          then (NONE(), indices);
        case ({System.SYSTEM(jacobian = SOME(jacobian))}, _)  then createSparsity(jacobian, Util.getOption(simJacobian), simulationHT, indices);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed! Partitioned systems are not yet supported by this function."});
        then fail();

      end match;
    end fromSystemsSparsity;
*/
    function create
      input BackendDAE jacobian;
      output Option<SimJacobian> simJacobian;
      input output SimCode.SimCodeIndices indices;
      input HashTableSimCode.HashTable crefToSimVarHT;
    algorithm
      simJacobian := match jacobian
        local
          EqData eqData;
          VarData varData;
          Pointer<list<SimStrongComponent.Block>> columnEqns = Pointer.create({});
          Pointer<SimCode.SimCodeIndices> indices_ptr = Pointer.create(indices);
          Pointer<list<SimVar>> columnVars_ptr = Pointer.create({});
          Pointer<list<SimVar>> seedVars_ptr = Pointer.create({});
          list<SimVar> columnVars, seedVars;
          HashTableSimCode.HashTable jacobianHT;
          SparsityPattern sparsity, sparsityT;
          SparsityColoring coloring;
          SimJacobian jac;

        case BackendDAE.JACOBIAN(varData = varData as BVariable.VAR_DATA_JAC(), eqData = eqData as BEquation.EQ_DATA_JAC()) algorithm
          EquationPointers.map(eqData.equations, function SimStrongComponent.Block.traverseCreateEquation(acc = columnEqns, indices_ptr = indices_ptr, systemType = NBSystem.SystemType.JAC, crefToSimVarHT = crefToSimVarHT));

          // use dummy simcode indices to always start at 0 for column and seed vars
          VariablePointers.map(varData.unknowns, function SimVar.traverseCreate(acc = columnVars_ptr, indices_ptr = Pointer.create(NSimCode.EMPTY_SIM_CODE_INDICES()), varType =  VarType.SIMULATION));
          VariablePointers.map(varData.seedVars, function SimVar.traverseCreate(acc = seedVars_ptr, indices_ptr = Pointer.create(NSimCode.EMPTY_SIM_CODE_INDICES()), varType =  VarType.SIMULATION));
          columnVars := listReverse(Pointer.access(columnVars_ptr));
          seedVars := listReverse(Pointer.access(seedVars_ptr));

          jacobianHT := HashTableSimCode.empty(listLength(columnVars) + listLength(seedVars));
          jacobianHT := HashTableSimCode.addList(columnVars, jacobianHT);
          jacobianHT := HashTableSimCode.addList(seedVars, jacobianHT);

          indices := Pointer.access(indices_ptr);

          jac := SIM_JAC(
            name                = jacobian.name,
            jacobianIndex       = indices.jacobianIndex,
            partitionIndex      = 0,
            numberOfResultVars  = listLength(columnVars),   // needs to be changed once tearing is implmented
            columnEqns          = listReverse(Pointer.access(columnEqns)),
            constantEqns        = {},
            columnVars          = columnVars,
            seedVars            = seedVars,
            sparsity            = {},                //needs to be added later
            sparsityT           = {},                //needs to be added later
            coloring            = {},                //needs to be added later
            numColors           = 0,                 //needs to be added later
            jacobianHT          = SOME(jacobianHT)
          );

          (jac, indices) := createSparsity(jacobian, jac, crefToSimVarHT, indices);

          indices.jacobianIndex := indices.jacobianIndex + 1;
        then SOME(jac);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end create;

    function createSimulationJacobian
      input list<System.System> ode;
      input list<System.System> ode_event;
      output SimJacobian simJac;
      input output SimCode.SimCodeIndices simCodeIndices;
      input HashTableSimCode.HashTable crefToSimVarHT;
    protected
      list<System.System> systems = listAppend(ode, ode_event);
      list<BackendDAE> jacobians = {};
      BackendDAE simJacobian;
      Option<SimJacobian> simJac_opt;
    algorithm
      for system in systems loop
        // save jacobian if existant
        if Util.isSome(system.jacobian) then
          jacobians := Util.getOption(system.jacobian) :: jacobians;
        end if;
      end for;

      // create empty jacobian as fallback
      if listEmpty(jacobians) then
        (simJac, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
      else
        simJacobian := Jacobian.combine(jacobians, "A");
        (simJac_opt, simCodeIndices) := SimJacobian.create(simJacobian, simCodeIndices, crefToSimVarHT);
        if Util.isSome(simJac_opt) then
          simJac := Util.getOption(simJac_opt);
        else
          (simJac, simCodeIndices) := SimJacobian.empty("A", simCodeIndices);
        end if;
      end if;
    end createSimulationJacobian;

    function createSparsity
      input BackendDAE jacobian;
      input output SimJacobian simJacobian;
      input HashTableSimCode.HashTable simulationHT;
      input output SimCode.SimCodeIndices indices;
    algorithm
      simJacobian := match (jacobian, simJacobian)
        local
          Jacobian.SparsityPattern pattern;
          Jacobian.SparsityColoring coloring;

        case (BackendDAE.JACOBIAN(sparsityPattern = pattern, sparsityColoring = coloring), SIM_JAC()) algorithm
          simJacobian.sparsity  := createSparsityPattern(pattern.col_wise_pattern, simulationHT, false);
          simJacobian.sparsityT := createSparsityPattern(pattern.row_wise_pattern, simulationHT, true);
          simJacobian.coloring  := createSparsityColoring(coloring, simulationHT);
          simJacobian.numColors := listLength(coloring);
        then simJacobian;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end createSparsity;

    function createSparsityPattern
      input list<Jacobian.SparsityPatternCol> cols    "columns that need to be generated (can be used for rows too)";
      input HashTableSimCode.HashTable simulationHT   "hash table cr --> simVar";
      input Boolean transposed;
      output SparsityPattern simPattern = {};
    protected
      ComponentRef cref;
      list<ComponentRef> dependencies;
      list<Integer> dep_indices;
    algorithm
      for col in listReverse(cols) loop
        (cref, dependencies) := col;
        try
          // this state derivative -> state transformation is for conversion to the old simcode
          if transposed then
            // get state for cref
            cref := derivativeToStateCref(cref);
          else
            // get states for dependencies
            dependencies := list(derivativeToStateCref(dep) for dep in dependencies);
          end if;
          dep_indices := list(SimVar.getIndex(BaseHashTable.get(dep, simulationHT)) for dep in dependencies);
          simPattern := (SimVar.getIndex(BaseHashTable.get(cref, simulationHT)), List.sort(dep_indices, intGt)) :: simPattern;
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to get index for cref: " + ComponentRef.toString(cref)});
          fail();
        end try;
      end for;
    end createSparsityPattern;

    function createSparsityColoring
      input Jacobian.SparsityColoring coloring;
      input HashTableSimCode.HashTable simulationHT;
      output SparsityColoring simColoring = {};
    protected
      list<Integer> tmp;
    algorithm
      for group in listReverse(coloring) loop
        try
          tmp := list(SimVar.getIndex(BaseHashTable.get(cref, simulationHT)) for cref in group);
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to get indices for crefs:\n"
            + List.toString(group, ComponentRef.toString)});
        end try;
        simColoring := tmp :: simColoring;
      end for;
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
      end match;
    end empty;

    function getJacobianBlocks
      input SimJacobian jacobian;
      output list<SimStrongComponent.Block> blcks;
    algorithm
      blcks := match jacobian
        case SIM_JAC() then listAppend(jacobian.constantEqns, jacobian.columnEqns);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
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
      output Option<HashTableSimCode.HashTable> jacobianHT;
    algorithm
      jacobianHT := match jacobian
        case SIM_JAC() then jacobian.jacobianHT;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
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
            columns         = {oldJacCol},
            seedVars        = SimVar.convertList(simJac.seedVars),
            matrixName      = simJac.name,
            sparsity        = simJac.sparsity,
            sparsityT       = simJac.sparsityT,
            coloredCols     = simJac.coloring,
            maxColorCols    = simJac.numColors,
            jacobianIndex   = simJac.jacobianIndex,
            partitionIndex  = simJac.partitionIndex,
            crefsHT         = if Util.isSome(simJac.jacobianHT) then SOME(HashTableSimCode.convert(Util.getOption(simJac.jacobianHT))) else NONE()
          );
        then oldJac;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end convert;

    function convertOpt
      input Option<SimJacobian> simJac_opt;
      output Option<OldSimCode.JacobianMatrix> oldJac_opt;
    algorithm
      oldJac_opt := match simJac_opt
        local
          SimJacobian simJac;
          OldSimCode.JacobianMatrix oldJac;
        case SOME(simJac) then SOME(convert(simJac));
        case NONE()       then NONE();
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end convertOpt;
  end SimJacobian;

  constant SimJacobian EMPTY_SIM_JAC = SIM_JAC("", 0, 0, 0, {}, {}, {}, {}, {}, {}, {}, 0, NONE());

protected
  function derivativeToStateCref
    "returns the state of a derivative if it is one, otherwise it just returns the cref itself.
    used for getting jacobian dependencies in the sparsity pattern."
    input output ComponentRef cref;
  algorithm
    if BVariable.checkCref(cref, BVariable.isStateDerivative) then
      cref := BVariable.getStateCref(cref);
    end if;
  end derivativeToStateCref;

  annotation(__OpenModelica_Interface="backend");
end NSimJacobian;

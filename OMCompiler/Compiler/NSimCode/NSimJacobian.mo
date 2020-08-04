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
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Jacobian = NBJacobian;
  import System = NBSystem;

  // SimCode imports
  import HashTableSimCode;
  import SimCode = NSimCode;
  import SimStrongComponent = NSimStrongComponent;
  import SimVar = NSimVar;
  import NSimVar.VarType;

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
      list<SimVar.SimVar> columnVars                  "all column vars, none results vars index -1, the other corresponding to rows index";
      list<SimVar.SimVar> seedVars                    "corresponds to the number of columns";
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
      str := StringUtil.headline_2("SimCode Jacobian " + simJac.name + "(idx = " + intString(simJac.jacobianIndex) + ", partition = " + intString(simJac.jacobianIndex) + ")") + "\n";
      str := str + StringUtil.headline_4("ColumnVars (#residuals = " + intString(simJac.numberOfResultVars) + ")");
      for var in simJac.columnVars loop
        str := str + SimVar.SimVar.toString(var, "  ") + "\n";
      end for;
      str := str + StringUtil.headline_4("SeedVars");
      for var in simJac.seedVars loop
        str := str + SimVar.SimVar.toString(var, "  ") + "\n";
      end for;
      str := str + StringUtil.headline_3("Column Equations (#residuals = " + intString(simJac.numberOfResultVars) + ")");
      for eq in simJac.columnEqns loop
        str := str + SimStrongComponent.Block.toString(eq, "  ");
      end for;
      if not listEmpty(simJac.constantEqns) then
        str := str + StringUtil.headline_3("Constant Equations");
        for eq in simJac.constantEqns loop
          str := str + SimStrongComponent.Block.toString(eq, "  ");
        end for;
      end if;
      str := str + StringUtil.headline_4("Sparsity Pattern");
      for tpl in simJac.sparsity loop
        (idx, dependencies) := tpl;
        str := str + "  " + intString(idx) + ":\t" + List.toString(dependencies, intString) + "\n";
      end for;
      str := str + StringUtil.headline_4("Sparsity Coloring Groups");
      for lst in simJac.coloring loop
        str := str +  "  " + List.toString(lst, intString) + "\n";
      end for;
    end toString;

    function fromSystems
      "This is a little bit of an ugly hack. Why do we only have one jacobian for the full DAE and
      not one for each subsystem? For now only create one single if there is only one system."
      input list<System.System> systems;
      output Option<SimJacobian> simJacobian;
      input output SimCode.SimCodeIndices indices;
      input output FunctionTree funcTree;
    algorithm
      (simJacobian, indices, funcTree) := match systems
        local
          BackendDAE jacobian;

        case {System.SYSTEM(jacobian = NONE())}           then (NONE(), indices, funcTree);
        case {System.SYSTEM(jacobian = SOME(jacobian))}   then create(jacobian, indices, funcTree);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed! Partitioned systems are not yet supported by this function."});
        then fail();

      end match;
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
        case ({System.SYSTEM(jacobian = SOME(jacobian))}, _)  then createSparsity(jacobian, simJacobian, simulationHT, indices);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed! Partitioned systems are not yet supported by this function."});
        then fail();

      end match;
    end fromSystemsSparsity;

    function create
      input BackendDAE jacobian;
      output Option<SimJacobian> simJacobian;
      input output SimCode.SimCodeIndices indices;
      input output FunctionTree funcTree;
    algorithm
      simJacobian := match jacobian
        local
          BackendDAE qual;
          BEquation.EqData eqData;
          BVariable.VarData varData;
          Pointer<list<SimStrongComponent.Block>> columnEqns = Pointer.create({});
          Pointer<SimCode.SimCodeIndices> indices_ptr = Pointer.create(indices);
          Pointer<FunctionTree> funcTree_ptr = Pointer.create(funcTree);
          Pointer<list<SimVar.SimVar>> columnVars_ptr = Pointer.create({});
          Pointer<list<SimVar.SimVar>> seedVars_ptr = Pointer.create({});
          list<SimVar.SimVar> columnVars, seedVars;
          HashTableSimCode.HashTable jacobianHT;
          SparsityPattern sparsity, sparsityT;
          SparsityColoring coloring;
          SimJacobian jac;

        case qual as BackendDAE.JAC(varData = varData as BVariable.VAR_DATA_JAC(), eqData = eqData as BEquation.EQ_DATA_JAC()) algorithm
          BEquation.EquationPointers.map(eqData.equations, function SimStrongComponent.Block.traverseCreateEquation(acc = columnEqns, indices_ptr = indices_ptr, funcTree_ptr = funcTree_ptr));

          BVariable.VariablePointers.map(varData.unknowns, function SimVar.SimVar.traverseCreate(acc = columnVars_ptr, indices_ptr = Pointer.create(NSimCode.EMPTY_SIM_CODE_INDICES), varType =  VarType.SIMULATION));
          BVariable.VariablePointers.map(varData.seedVars, function SimVar.SimVar.traverseCreate(acc = seedVars_ptr, indices_ptr = Pointer.create(NSimCode.EMPTY_SIM_CODE_INDICES), varType =  VarType.SIMULATION));
          columnVars := listReverse(Pointer.access(columnVars_ptr));
          seedVars := listReverse(Pointer.access(seedVars_ptr));

          jacobianHT := HashTableSimCode.empty(listLength(columnVars) + listLength(seedVars));
          jacobianHT := HashTableSimCode.addList(columnVars, jacobianHT);
          jacobianHT := HashTableSimCode.addList(seedVars, jacobianHT);

          indices := Pointer.access(indices_ptr);
          funcTree := Pointer.access(funcTree_ptr);

          jac := SIM_JAC(
            name                = qual.name,
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
          indices.jacobianIndex := indices.jacobianIndex + 1;
        then SOME(jac);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end create;

    function createSparsity
      input BackendDAE jacobian;
      input output Option<SimJacobian> simJacobian;
      input HashTableSimCode.HashTable simulationHT;
      input output SimCode.SimCodeIndices indices;

    algorithm
      simJacobian := match (jacobian, simJacobian)
        local
          Jacobian.SparsityPattern pattern;
          Jacobian.SparsityColoring coloring;
          SimJacobian tmp;
          ComponentRef seedCref;

        case (_, NONE()) then NONE();

        case (BackendDAE.JAC(sparsityPattern = pattern, sparsityColoring = coloring), SOME(tmp))
          algorithm
            // the seed cref for correct index lookup
            seedCref := ComponentRef.fromNode(InstNode.VAR_NODE(NBVariable.SEED_STR + "_" + tmp.name, Pointer.create(NBVariable.DUMMY_VARIABLE)), Type.UNKNOWN());
            tmp.sparsity := listReverse(createSparsityPattern(pattern.col_wise_pattern, simulationHT, seedCref, false));
            tmp.sparsityT := createSparsityPattern(pattern.row_wise_pattern, simulationHT, seedCref, true);
            tmp.coloring := createSparsityColoring(coloring, simulationHT, seedCref);
            tmp.numColors := listLength(coloring);
        then SOME(tmp);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end createSparsity;

    function createSparsityPattern
      input list<Jacobian.SparsityPatternCol> cols    "columns that need to be generated (can be used for rows too)";
      input HashTableSimCode.HashTable simulationHT   "hash table cr --> simVar";
      input ComponentRef seedCref                     "if not transposed than it needs the prepending seed cref";
      input Boolean transposed;
      output SparsityPattern simPattern = {};
    protected
      ComponentRef cref;
      list<ComponentRef> dependencies;
      Option<ComponentRef> optSeed;
      list<Integer> dep_indices;
    algorithm
      for col in listReverse(cols) loop
        (cref, dependencies) := col;
        try
          if not transposed then
            cref := ComponentRef.append(cref, seedCref);
          end if;
          optSeed := if transposed then SOME(seedCref) else NONE();
          dep_indices := getCrefListIndices(dependencies, simulationHT, optSeed);
          simPattern := (SimVar.SimVar.getIndex(BaseHashTable.get(cref, simulationHT)), List.sort(dep_indices, intGt)) :: simPattern;
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to get index for cref: " + ComponentRef.toString(cref)});
        end try;
      end for;
    end createSparsityPattern;

    function createSparsityColoring
      input Jacobian.SparsityColoring coloring;
      input HashTableSimCode.HashTable simulationHT;
      input ComponentRef seedCref                     "it needs the prepending seed cref";
      output SparsityColoring simColoring = {};
    protected
      list<Integer> tmp;
    algorithm
      for group in listReverse(coloring) loop
        tmp := {};
        for cref in listReverse(group) loop
          try
            tmp := SimVar.SimVar.getIndex(BaseHashTable.get(ComponentRef.append(cref, seedCref), simulationHT)) :: tmp;
          else
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to get index for cref: " + ComponentRef.toString(cref)});
          end try;
        end for;
        simColoring := tmp :: simColoring;
      end for;
    end createSparsityColoring;

    function empty
      input String name = "";
      output SimJacobian emptyJac = EMPTY_SIM_JAC;
      input output SimCode.SimCodeIndices indices;
    algorithm
      emptyJac.name := name;
      emptyJac.jacobianIndex := indices.jacobianIndex;
      indices.jacobianIndex := indices.jacobianIndex + 1;
    end empty;

    function convert
      input SimJacobian simJac;
      output OldSimCode.JacobianMatrix oldJac;
    algorithm
      oldJac := OldSimCode.JAC_MATRIX(
        columns         = {OldSimCode.JAC_COLUMN({}, {}, simJac.numberOfResultVars, {})},
        seedVars        = SimVar.SimVar.convertList(simJac.seedVars),
        matrixName      = simJac.name,
        sparsity        = simJac.sparsity,
        sparsityT       = simJac.sparsityT,
        coloredCols     = simJac.coloring,
        maxColorCols    = simJac.numColors,
        jacobianIndex   = simJac.jacobianIndex,
        partitionIndex  = simJac.partitionIndex,
        crefsHT         = NONE()
      );
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

  protected
    function getCrefListIndices
      input list<ComponentRef> crefs;
      input HashTableSimCode.HashTable simulationHT   "hash table cr --> simVar";
      input Option<ComponentRef> seedCref;
      output list<Integer> indices = {};
    algorithm
      for cref in listReverse(crefs) loop
        if isSome(seedCref) then
          cref := ComponentRef.append(cref, Util.getOption(seedCref));
        end if;
        indices := SimVar.SimVar.getIndex(BaseHashTable.get(cref, simulationHT)) :: indices;
      end for;
    end getCrefListIndices;
  end SimJacobian;

  constant SimJacobian EMPTY_SIM_JAC = SIM_JAC("", 0, 0, 0, {}, {}, {}, {}, {}, {}, {}, 0, NONE());

  annotation(__OpenModelica_Interface="backend");
end NSimJacobian;

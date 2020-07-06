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

  // Backend imports
  import BackendDAE = NBackendDAE;
  import BEquation = NBEquation;
  import BVariable = NBVariable;
  import Jacobian = NBJacobian;

  // SimCode imports
  import HashTableSimCode;
  import SimCode = NSimCode;
  import SimStrongComponent = NSimStrongComponent;
  import SimVar = NSimVar;

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

    function create
      input BackendDAE jacobian;
      output SimJacobian simJacobian;
      input output SimCode.SimCodeIndices indices;
    algorithm
      simJacobian := match jacobian
        local
          BackendDAE qual;
          BEquation.EqData eqData;
          BVariable.VarData varData;
          Pointer<list<SimStrongComponent.Block>> columnEqns = Pointer.create({});
          Pointer<SimCode.SimCodeIndices> indices_ptr = Pointer.create(indices);
          Pointer<list<SimVar.SimVar>> columnVars_ptr = Pointer.create({});
          Pointer<list<SimVar.SimVar>> seedVars_ptr = Pointer.create({});
          list<SimVar.SimVar> columnVars, seedVars;
          HashTableSimCode.HashTable jacobianHT;
          SparsityPattern sparsity, sparsityT;
          SparsityColoring coloring;

        case qual as BackendDAE.JAC(varData = varData as BVariable.VAR_DATA_JAC(), eqData = eqData as BEquation.EQ_DATA_JAC()) algorithm
          BEquation.EquationPointers.map(eqData.equations, function SimStrongComponent.Block.traverseCreateEquation(acc = columnEqns, indices_ptr = indices_ptr));

          BVariable.VariablePointers.map(varData.unknowns, function SimVar.SimVar.traverseCreate(acc = columnVars_ptr, uniqueIndexPtr = Pointer.create(0)));
          BVariable.VariablePointers.map(varData.seedVars, function SimVar.SimVar.traverseCreate(acc = seedVars_ptr, uniqueIndexPtr = Pointer.create(0)));
          columnVars := Pointer.access(columnVars_ptr);
          seedVars := Pointer.access(seedVars_ptr);

          jacobianHT := HashTableSimCode.empty(listLength(columnVars) + listLength(seedVars));
          jacobianHT := HashTableSimCode.addList(columnVars, jacobianHT);
          jacobianHT := HashTableSimCode.addList(seedVars, jacobianHT);

          (sparsity, sparsityT, coloring) := createSparsity(qual.sparsityPattern, qual.sparsityColoring, jacobianHT);

          indices := Pointer.access(indices_ptr);

          simJacobian := SIM_JAC(
            name                = qual.name,
            jacobianIndex       = indices.jacobianIndex,
            partitionIndex      = 0,
            numberOfResultVars  = ExpandableArray.getNumberOfElements(varData.resultVars.varArr),
            columnEqns          = Pointer.access(columnEqns),
            constantEqns        = {},
            columnVars          = columnVars,
            seedVars            = seedVars,
            sparsity            = sparsity,
            sparsityT           = sparsityT,
            coloring            = coloring,
            numColors           = 0,
            jacobianHT          = NONE()
          );
          indices.jacobianIndex := indices.jacobianIndex + 1;
        then simJacobian;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed!"});
        then fail();
      end match;
    end create;

    function createSparsity
      input Jacobian.SparsityPattern pattern;
      input Jacobian.SparsityColoring coloring;
      input HashTableSimCode.HashTable jacobianHT;
      output SparsityPattern simPattern;
      output SparsityPattern simPatternT;
      output SparsityColoring simColoring;
    algorithm
      simPattern := createSparsityPattern(pattern.col_wise_pattern, jacobianHT);
      simPatternT := createSparsityPattern(pattern.row_wise_pattern, jacobianHT);
      simColoring := createSparsityColoring(coloring, jacobianHT);
    end createSparsity;

    function createSparsityPattern
      input list<Jacobian.SparsityPatternCol> cols  "columns that need to be generated (can be used for rows too)";
      input HashTableSimCode.HashTable jacobianHT   "hash table cr --> simVar";
      output SparsityPattern simPattern = {};
    protected
      ComponentRef cref;
      list<ComponentRef> dependencies;
    algorithm
      for col in listReverse(cols) loop
        (cref, dependencies) := col;
        simPattern := (SimVar.SimVar.getIndex(BaseHashTable.get(cref, jacobianHT)), getCrefListIndices(dependencies, jacobianHT)) :: simPattern;
      end for;
    end createSparsityPattern;

    function createSparsityColoring
      input Jacobian.SparsityColoring coloring;
      input HashTableSimCode.HashTable jacobianHT;
      output SparsityColoring simColoring = {};
    protected
      list<Integer> tmp;
    algorithm
      for group in listReverse(coloring) loop
        tmp := {};
        for cref in listReverse(group) loop
          tmp := SimVar.SimVar.getIndex(BaseHashTable.get(cref, jacobianHT)) :: tmp;
        end for;
        simColoring := tmp :: simColoring;
      end for;
    end createSparsityColoring;

  protected
    function getCrefListIndices
      input list<ComponentRef> crefs;
      input HashTableSimCode.HashTable jacobianHT   "hash table cr --> simVar";
      output list<Integer> indices = {};
    algorithm
      for cref in listReverse(crefs) loop
        indices := SimVar.SimVar.getIndex(BaseHashTable.get(cref, jacobianHT)) :: indices;
      end for;
    end getCrefListIndices;

  end SimJacobian;

  constant SimJacobian EMPTY_SIM_JAC = SIM_JAC("", 0, 0, 0, {}, {}, {}, {}, {}, {}, {}, 0, NONE());

  annotation(__OpenModelica_Interface="backend");
end NSimJacobian;

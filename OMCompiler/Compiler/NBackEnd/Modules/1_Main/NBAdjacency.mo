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
encapsulated package NBAdjacency
"file:        NBAdjacency.mo
 package:     NBAdjacency
 description: This file contains the functions which will create adjacency matrices.
"
public
  // self import
  import Adjacency = NBAdjacency;

protected
  // NF imports
  import Call = NFCall;
  import ComponentRef = NFComponentRef;
  import Dimension = NFDimension;
  import Expression = NFExpression;
  import FunctionTree = NFFlatten.FunctionTree;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Variable = NFVariable;

  // NB imports
  import Differentiate = NBDifferentiate;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationAttributes, EquationPointers, Iterator};
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Util import
  import Array;
  import BackendUtil = NBBackendUtil;
  import BuiltinSystem = System;
  import Slice = NBSlice;
  import StringUtil;

  // SetBased Graph imports
  import SBGraph.BipartiteIncidenceList;
  import SBGraph.VertexDescriptor;
  import SBGraph.SetType;
  import SBInterval;
  import SBMultiInterval;
  import SBPWLinearMap;
  import SBSet;
  import NBGraphUtil.{SetVertex, SetEdge};

public
  type MatrixType        = enumeration(ARRAY, PSEUDO);
  type MatrixStrictness  = enumeration(LINEAR, SOLVABLE, FULL);
  type BipartiteGraph    = BipartiteIncidenceList<SetVertex, SetEdge>;

  uniontype Mapping
    record MAPPING
      array<Integer> eqn_StA                  "eqn: scal_idx -> arr_idx";
      array<Integer> var_StA                  "var: scal_idx -> arr_idx";
      array<tuple<Integer,Integer>> eqn_AtS   "eqn: arr_idx -> start_idx/length";
      array<tuple<Integer,Integer>> var_AtS   "var: arr_idx -> start_idx/length";
    end MAPPING;

    function toString
      input Mapping mapping;
      output String str;
    protected
      Integer start, size;
    algorithm
      str := StringUtil.headline_4("Equation Index Mapping (ARR) -> START | SIZE");
      for i in 1:arrayLength(mapping.eqn_AtS) loop
        (start, size) := mapping.eqn_AtS[i];
        str := str + "(" + intString(i) + ")\t" + intString(start) + " | " + intString(size) + "\n";
      end for;
      str := str + StringUtil.headline_4("Variable Index Mapping (ARR) -> START | SIZE");
      for i in 1:arrayLength(mapping.var_AtS) loop
        (start, size) := mapping.var_AtS[i];
        str := str + "(" + intString(i) + ")\t" + intString(start) + " | " + intString(size) + "\n";
      end for;
    end toString;

    function empty
      output Mapping mapping = MAPPING(arrayCreate(0, 0), arrayCreate(0, 0),arrayCreate(0, (0,0)),arrayCreate(0, (0,0)));
    end empty;

    function create
      input EquationPointers eqns;
      input VariablePointers vars;
      output Mapping mapping;
    protected
      list<Pointer<Equation>> eqn_lst = EquationPointers.toList(eqns);
      list<Pointer<Variable>> var_lst = VariablePointers.toList(vars);
      array<Integer> eqn_StA, var_StA;
      array<tuple<Integer,Integer>> eqn_AtS, var_AtS;
      Integer eqn_scalar_size, var_scalar_size, size;
      Integer eqn_idx_scal = 1, eqn_idx_arr = 1, var_idx_scal = 1, var_idx_arr = 1;
    algorithm
      // prepare the mappings
      eqn_scalar_size := sum(array(Equation.size(eqn) for eqn in eqn_lst));
      var_scalar_size := sum(array(BVariable.size(var) for var in var_lst));
      eqn_StA := arrayCreate(eqn_scalar_size, -1);
      var_StA := arrayCreate(var_scalar_size, -1);
      eqn_AtS := arrayCreate(EquationPointers.size(eqns), (-1, -1));
      var_AtS := arrayCreate(VariablePointers.size(vars), (-1, -1));

      // fill the arrays
      (eqn_StA, var_StA, eqn_AtS, var_AtS) := fill_(eqn_StA, var_StA, eqn_AtS, var_AtS, eqn_lst, var_lst, eqn_idx_scal, eqn_idx_arr, var_idx_scal, var_idx_arr);

      // compile mapping
      mapping := MAPPING(eqn_StA, var_StA, eqn_AtS, var_AtS);
    end create;

    function expand
      input output Mapping mapping;
      input list<Pointer<Equation>> eqn_lst;
      input list<Pointer<Variable>> var_lst;
      input Integer neqn_scal;
      input Integer nvar_scal;
      input Integer neqn_arr;
      input Integer nvar_arr;
    protected
      array<Integer> eqn_StA, var_StA;
      array<tuple<Integer,Integer>> eqn_AtS, var_AtS;
      Integer eqn_scalar_size, var_scalar_size;
      Integer eqn_idx_scal = arrayLength(mapping.eqn_StA) + 1, eqn_idx_arr = arrayLength(mapping.eqn_AtS) + 1;
      Integer var_idx_scal = arrayLength(mapping.var_StA) + 1, var_idx_arr = arrayLength(mapping.var_AtS) + 1;
    algorithm

      // copy all data
      eqn_StA := Array.expandToSize(eqn_idx_scal - 1 + neqn_scal, mapping.eqn_StA, -1);
      var_StA := Array.expandToSize(var_idx_scal - 1 + nvar_scal, mapping.var_StA, -1);
      eqn_AtS := Array.expandToSize(eqn_idx_arr - 1 + neqn_arr, mapping.eqn_AtS, (-1, -1));
      var_AtS := Array.expandToSize(var_idx_arr - 1 + nvar_arr, mapping.var_AtS, (-1, -1));

      // fill the new sections
      (eqn_StA, var_StA, eqn_AtS, var_AtS) := fill_(eqn_StA, var_StA, eqn_AtS, var_AtS, eqn_lst, var_lst, eqn_idx_scal, eqn_idx_arr, var_idx_scal, var_idx_arr);

      // compile mapping
      mapping := MAPPING(eqn_StA, var_StA, eqn_AtS, var_AtS);
    end expand;

    function getEqnScalIndices
      input Integer arr_idx;
      input Mapping mapping;
      input Boolean reverse = false;
      output list<Integer> scal_indices;
    protected
      Integer start, length;
    algorithm
      (start, length) := mapping.eqn_AtS[arr_idx];
      scal_indices := if reverse then
        List.intRange2(start + length - 1, start) else
        List.intRange2(start, start + length - 1);
    end getEqnScalIndices;

    function getVarScalIndices
      input Integer arr_idx;
      input Mapping mapping;
      input list<Subscript> subs;
      input list<Dimension> dims;
      input Boolean reverse = false;
      output list<Integer> scal_indices;
    protected
      Integer start, length;
      function subscriptedIndices
        input Integer start;
        input Integer length;
        input list<Integer> slice;
        output list<Integer> scal_indices;
      algorithm
        scal_indices := List.intRange2(start, start + length - 1);
        if not listEmpty(slice) then
          scal_indices := List.keepPositions(scal_indices, slice);
        end if;
      end subscriptedIndices;
    algorithm
      (start, length) := mapping.var_AtS[arr_idx];

      scal_indices := match subs
        local
          Subscript sub;
          list<list<Subscript>> subs_lst;
          list<Integer> slice = {}, dim_sizes, values;
          list<tuple<Integer, Integer>> ranges;

        // no subscripts -> create full index list
        case {} then subscriptedIndices(start, length, {});

        // all subscripts are whole -> create full index list
        case _ guard(List.all(subs, Subscript.isWhole)) then subscriptedIndices(start, length, {});

        // only one subscript -> apply simple rule
        case {sub} algorithm
          slice := Subscript.toIndexList(sub, length);
        then subscriptedIndices(start, length, slice);

        // multiple subscripts -> apply location to index mapping rules
        case _ algorithm
          subs_lst  := Subscript.scalarizeList(subs, dims);
          subs_lst  := List.combination(subs_lst);
          dim_sizes := list(Dimension.size(dim) for dim in dims);
          for sub_lst in listReverse(subs_lst) loop
            values  := list(Subscript.toInteger(s) for s in sub_lst);
            ranges  := List.zip(dim_sizes, values);
            slice   := Slice.locationToIndex(ranges, start) :: slice;
          end for;
        then slice;

        else fail();
      end match;

      if reverse then
        scal_indices := listReverse(scal_indices);
      end if;
    end getVarScalIndices;

  protected
    function fill_
      input output array<Integer> eqn_StA;
      input output array<Integer> var_StA;
      input output array<tuple<Integer,Integer>> eqn_AtS;
      input output array<tuple<Integer,Integer>> var_AtS;
      input list<Pointer<Equation>> eqn_lst;
      input list<Pointer<Variable>> var_lst;
      input Integer eqn_idx_scal_start;
      input Integer eqn_idx_arr_start;
      input Integer var_idx_scal_start;
      input Integer var_idx_arr_start;
    protected
      Integer size;
      Integer eqn_idx_scal = eqn_idx_scal_start;
      Integer eqn_idx_arr = eqn_idx_arr_start;
      Integer var_idx_scal = var_idx_scal_start;
      Integer var_idx_arr= var_idx_arr_start;
    algorithm
      // fill equation mapping
      for eqn_ptr in eqn_lst loop
        size := Equation.size(eqn_ptr);
        eqn_AtS[eqn_idx_arr] := (eqn_idx_scal, size);
        for i in eqn_idx_scal:eqn_idx_scal+size-1 loop
          eqn_StA[i] := eqn_idx_arr;
        end for;
        eqn_idx_scal := eqn_idx_scal + size;
        eqn_idx_arr := eqn_idx_arr + 1;
      end for;
      // fill variable mapping
      for var_ptr in var_lst loop
        size := BVariable.size(var_ptr);
        var_AtS[var_idx_arr] := (var_idx_scal, size);
        for i in var_idx_scal:var_idx_scal+size-1 loop
          var_StA[i] := var_idx_arr;
        end for;
        var_idx_scal := var_idx_scal + size;
        var_idx_arr := var_idx_arr + 1;
      end for;
    end fill_;
  end Mapping;

  uniontype CausalizeModes
    record CAUSALIZE_MODES
      "for-loop reconstruction information"
      array<array<Integer>> mode_to_var       "scal_eqn:  mode idx -> var";
      array<array<ComponentRef>> mode_to_cref "arr_eqn:   mode idx -> cref to solve for";
      Pointer<list<Integer>> mode_eqns        "array indices of relevant eqns";
    end CAUSALIZE_MODES;

    function empty
      input Integer eqn_scalar_size;
      input Integer eqn_array_size;
      output CausalizeModes modes = CAUSALIZE_MODES(
                                mode_to_var  = arrayCreate(eqn_scalar_size, arrayCreate(0,0)),
                                mode_to_cref = arrayCreate(eqn_array_size, arrayCreate(0,ComponentRef.EMPTY())),
                                mode_eqns    = Pointer.create({})
                              );
    end empty;

    function contains
      "checks if there is a mode for this eqn array index"
      input Integer eqn_scal_idx;
      input CausalizeModes modes;
      output Boolean b = not arrayEmpty(arrayGet(modes.mode_to_var, eqn_scal_idx));
    end contains;

    function get
      "returns the proper mode for an eqn-var index tuple"
      input Integer eqn_scal_idx;
      input Integer var_scal_idx;
      input CausalizeModes modes;
      output Integer mode = -1;
    protected
      array<Integer> mtv = arrayGet(modes.mode_to_var, eqn_scal_idx);
    algorithm
      for i in 1:arrayLength(mtv) loop
        if mtv[i] == var_scal_idx then
          mode := i;
          return;
        end if;
      end for;
    end get;

    function expand
      input output CausalizeModes modes;
      input Mapping mapping;
    protected
      array<array<Integer>> mode_to_var       = arrayCreate(arrayLength(mapping.eqn_StA), arrayCreate(0,0));
      array<array<ComponentRef>> mode_to_cref = arrayCreate(arrayLength(mapping.eqn_AtS), arrayCreate(0,ComponentRef.EMPTY()));
    algorithm
      Array.copy(modes.mode_to_var, mode_to_var);
      Array.copy(modes.mode_to_cref, mode_to_cref);
      modes := CAUSALIZE_MODES(mode_to_var, mode_to_cref, modes.mode_eqns);
    end expand;

    function update
      input CausalizeModes modes;
      input Integer eqn_scal_idx;
      input Integer eqn_arr_idx;
      input array<array<Integer>> mode_to_var_part;
      input list<ComponentRef> unique_dependencies;
    protected
      // get clean pointers -> type checking fails otherwise
      array<array<Integer>> mode_to_var = modes.mode_to_var;
      array<array<ComponentRef>> mode_to_cref = modes.mode_to_cref;
    algorithm
      // if there is no mode yet this equation index has not been added
      if arrayLength(mode_to_cref[eqn_arr_idx]) == 0 then
        Pointer.update(modes.mode_eqns, eqn_arr_idx :: Pointer.access(modes.mode_eqns));
      end if;

      // create scalar mode idx to variable mapping
      for i in 1:arrayLength(mode_to_var_part) loop
        arrayUpdate(mode_to_var, eqn_scal_idx+(i-1), arrayAppend(mode_to_var_part[i], mode_to_var[eqn_scal_idx+(i-1)]));
      end for;

      // create array mode to cref mapping
      arrayUpdate(mode_to_cref, eqn_arr_idx, arrayAppend(listArray(unique_dependencies), mode_to_cref[eqn_arr_idx]));
    end update;

    function clean
      "cleans up all equation causalize modes of given indices
      used for the updating routine."
      input CausalizeModes modes;
      input Mapping mapping;
      input list<Integer> idx_lst;
    protected
      array<array<Integer>> mode_to_var = modes.mode_to_var;
      array<array<ComponentRef>> mode_to_cref = modes.mode_to_cref;
      list<Integer> scal_indices;
    algorithm
      for arr_idx in idx_lst loop
        scal_indices := Mapping.getEqnScalIndices(arr_idx, mapping);
        mode_to_cref[arr_idx] := arrayCreate(0, ComponentRef.EMPTY());
        for scal_idx in scal_indices loop
          mode_to_var[scal_idx] := arrayCreate(0, 0);
        end for;
      end for;
    end clean;

    function toString
      input CausalizeModes modes;
      output String str;
    protected
      array<Integer> mtv;
      array<ComponentRef> mtc;
    algorithm
      str := StringUtil.headline_2("Causalization Modes");

      str := str + StringUtil.headline_3("(scalar) mode index -> variable index");
      for j in 1:arrayLength(modes.mode_to_var) loop
        mtv := modes.mode_to_var[j];
        str := str + "[" + intString(j) + "]\t";
        for i in 1:arrayLength(mtv) loop
          str := str + "(" + intString(i) + "->" + intString(mtv[i]) + ")";
        end for;
        str := str + "\n";
      end for;

      str := str + "\n" + StringUtil.headline_3("(array) mode index -> variable cref");
      for j in 1:arrayLength(modes.mode_to_cref) loop
        mtc := modes.mode_to_cref[j];
        str := str + "[" + intString(j) + "]\t";
        for i in 1:arrayLength(mtc) loop
          str := str + "(" + intString(i) + "->" + ComponentRef.toString(mtc[i]) + ")";
        end for;
        str := str + "\n";
      end for;
    end toString;
  end CausalizeModes;

  uniontype Matrix
    record ARRAY_ADJACENCY_MATRIX
      "no transposed set matrix needed since the graph represents all vertices equally"
      BipartiteGraph graph                        "set based graph";
      UnorderedMap<SetVertex, Integer> vertexMap  "map to get the vertex index";
      UnorderedMap<SetEdge, Integer> edgeMap      "map to get the edge index";
      MatrixStrictness st           "strictness with which it was created";
      /* Maybe add optional markings here */
    end ARRAY_ADJACENCY_MATRIX;

    record PSEUDO_ARRAY_ADJACENCY_MATRIX // ToDo: add optional solvability map for tearing
      array<list<Integer>> m        "eqn -> list<var>";
      array<list<Integer>> mT       "var -> list<eqn>";
      Mapping mapping               "index mapping scalar <-> array";
      CausalizeModes modes          "for-loop reconstruction information";
      MatrixStrictness st           "strictness with which it was created";
    end PSEUDO_ARRAY_ADJACENCY_MATRIX;

    record EMPTY_ADJACENCY_MATRIX
      MatrixType ty;
      MatrixStrictness st;
    end EMPTY_ADJACENCY_MATRIX;

    function create
      input VariablePointers vars;
      input EquationPointers eqns;
      input MatrixType ty;
      input MatrixStrictness st = MatrixStrictness.FULL;
      output Matrix adj;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    algorithm
      try
        (adj, funcTree) := match ty
          case MatrixType.ARRAY  then createArray(vars, eqns, st, funcTree);
          case MatrixType.PSEUDO then createPseudo(vars, eqns, st, funcTree);
          else algorithm
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
          then fail();
        end match;
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to create adjacency matrix for system:\n"
          + VariablePointers.toString(vars, "System") + "\n"
          + EquationPointers.toString(eqns, "System")});
        fail();
      end try;
    end create;

    function update
      "Updates specified rows of the adjacency matrix.
      Updates everything by default and if the index
      list is equal to {-1}.
      Note: take care for pseudo array matrices! this will not update any changes
      in mapping or causalize modes because it assumes same structure.
      Use expand() to change structure!"
      input output Matrix adj;
      input VariablePointers vars;
      input EquationPointers eqns;
      input list<Integer> idx_lst = {-1};
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    algorithm
      (adj, funcTree) := match (adj, idx_lst)
        local
          array<list<Integer>> m, mT;
          Mapping mapping;
          CausalizeModes modes;

        case (ARRAY_ADJACENCY_MATRIX(), {-1})           then create(vars, eqns, MatrixType.ARRAY, adj.st);
        case (PSEUDO_ARRAY_ADJACENCY_MATRIX(), {-1})    then create(vars, eqns, MatrixType.PSEUDO, adj.st);

        case (PSEUDO_ARRAY_ADJACENCY_MATRIX(), _) algorithm
          (m, mT, _) := updatePseudo(adj.m, adj.st, adj.mapping, adj.modes, vars, eqns, idx_lst, funcTree);
          adj.m       := m;
          adj.mT      := mT;
        then (adj, funcTree);

        case (ARRAY_ADJACENCY_MATRIX(), _) algorithm
          // ToDo
        then (adj, funcTree);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end update;

    function expand
      input output Matrix adj                             "adjancency matrix to be expanded";
      input output VariablePointers vars                  "variable array to be expanded";
      input output EquationPointers eqns                  "equation array to be expanded";
      input list<Pointer<Variable>> new_vars              "new variables to be added";
      input list<Pointer<Equation>> new_eqns              "new equations to be added";
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    algorithm
      (adj, vars, eqns, funcTree) := match adj
        local
          array<list<Integer>> m, mT;
          Mapping mapping;
          CausalizeModes modes;

        // if nothing is added, do nothing
        case _ guard(listEmpty(new_vars) and listEmpty(new_eqns)) then (adj, vars, eqns, funcTree);

        case PSEUDO_ARRAY_ADJACENCY_MATRIX() algorithm
          (m, mT, mapping, modes, vars, eqns, _) := expandPseudo(adj.m, adj.st, adj.mapping, adj.modes, vars, eqns, new_vars, new_eqns, funcTree);
          adj.m       := m;
          adj.mT      := mT;
          adj.mapping := mapping;
          adj.modes   := modes;
        then (adj, vars, eqns, funcTree);

        case ARRAY_ADJACENCY_MATRIX() algorithm
          // ToDo
        then (adj, vars, eqns, funcTree);

        case EMPTY_ADJACENCY_MATRIX() algorithm
          vars := VariablePointers.addList(new_vars, vars);
          eqns := EquationPointers.addList(new_eqns, eqns);
          (adj, funcTree) := create(vars, eqns, adj.ty, adj.st, funcTree);
        then (adj, vars, eqns, funcTree);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end expand;

    function expandPseudo
      input output array<list<Integer>> m                 "adjancency matrix to be expanded";
      output array<list<Integer>> mT                      "transposed adjacency matrix";
      input MatrixStrictness st;
      input output Mapping mapping;
      input output CausalizeModes modes;
      input output VariablePointers vars                  "variable array to be expanded";
      input output EquationPointers eqns                  "equation array to be expanded";
      input list<Pointer<Variable>> new_vars              "new variables to expand";
      input list<Pointer<Equation>> new_eqns              "new equations to expand";
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      Pointer<Differentiate.DifferentiationArguments> diffArgs_ptr;
      Integer new_size, old_size = EquationPointers.size(eqns);
      list<Integer> idx_lst;
      UnorderedMap<ComponentRef, Integer> sub_map         "only representing the new variables with shifted indices";
      Variable var;
      Integer eqn_idx_arr;
      Integer neqn_scal = sum(array(Equation.size(eqn) for eqn in new_eqns));
      Integer nvar_scal = sum(array(BVariable.size(var) for var in new_vars));
      Integer neqn_arr = listLength(new_eqns);
      Integer nvar_arr = listLength(new_vars);
    algorithm
      if Util.isSome(funcTree) then
        diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.TIME, Util.getOption(funcTree)));
      else
        diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default());
      end if;

      // #############################################
      //    Step 1: add vars and eqs to meta info
      // #############################################
      m       := expandMatrix(m, neqn_scal);
      mapping := Mapping.expand(mapping, new_eqns, new_vars, neqn_scal, nvar_scal, neqn_arr, nvar_arr);
      modes   := CausalizeModes.expand(modes, mapping);

      // #############################################
      //    Step 2: add variables and update eqns
      // #############################################
      vars := VariablePointers.addList(new_vars, vars);

      // create sub map
      sub_map := UnorderedMap.new<Integer>(ComponentRef.hashStrip, ComponentRef.isEqualStrip, Util.nextPrime(listLength(new_vars)));

      // copy the index for all new variables into the sub map
      for var_ptr in new_vars loop
        var := Pointer.access(var_ptr);
        UnorderedMap.add(var.name, UnorderedMap.getSafe(var.name, vars.map, sourceInfo()), sub_map);
      end for;

      // update the equation rows using only the sub_map
      eqn_idx_arr := 1;
      for eqn_ptr in EquationPointers.toList(eqns) loop
        updateRow(eqn_ptr, diffArgs_ptr, st, sub_map, m, mapping, modes, eqn_idx_arr, funcTree);
        eqn_idx_arr := eqn_idx_arr + 1;
      end for;

      // #############################################
      //    Step 3: add equations and new rows
      // #############################################
      eqns := EquationPointers.addList(new_eqns, eqns);

      new_size := EquationPointers.size(eqns);
      if new_size > old_size then
        // create index list for all new equations and use updating routine to fill them
        idx_lst := List.intRange2(old_size + 1, new_size);
        (m, mT, _) := updatePseudo(m, st, mapping, modes, vars, eqns, idx_lst, funcTree); //update causalize modes!
      else
        // just transpose the matrix, no equations have been added
        mT := transposeScalar(m, VariablePointers.scalarSize(vars));
      end if;
    end expandPseudo;

    function toString
      input Matrix adj;
      input output String str = "";
    algorithm
      str := StringUtil.headline_2(str + "AdjacencyMatrix") + "\n";
      str := match adj
        case ARRAY_ADJACENCY_MATRIX() then str + "\n ARRAY NOT YET SUPPORTED \n";

        case PSEUDO_ARRAY_ADJACENCY_MATRIX() algorithm
          if arrayLength(adj.m) > 0 then
            str := str + StringUtil.headline_4("Normal Adjacency Matrix (row = equation)");
            str := str + toStringSingle(adj.m);
          end if;
          str := str + "\n";
          if arrayLength(adj.mT) > 0 then
            str := str + StringUtil.headline_4("Transposed Adjacency Matrix (row = variable)");
            str := str + toStringSingle(adj.mT);
          end if;
          str := str + "\n" + Mapping.toString(adj.mapping);
        then str;

        case EMPTY_ADJACENCY_MATRIX() then str + StringUtil.headline_4("Empty Adjacency Matrix") + "\n";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end toString;

    function getMappingOpt
      input Matrix adj;
      output Option<Mapping> mapping;
    algorithm
      mapping := match adj
        case PSEUDO_ARRAY_ADJACENCY_MATRIX() then SOME(adj.mapping);
                                             else NONE();
      end match;
    end getMappingOpt;

    function nonZeroCount
      input Matrix adj;
      output Integer count;
    algorithm
      count := match adj
        case PSEUDO_ARRAY_ADJACENCY_MATRIX()  then BackendUtil.countElem(adj.m);
        case EMPTY_ADJACENCY_MATRIX()         then 0;
        case ARRAY_ADJACENCY_MATRIX() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array adjacency matrix is not jet supported."});
        then fail();
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown matrix type."});
        then fail();
      end match;
    end nonZeroCount;

    function expandMatrix
      input output array<list<Integer>> m;
      input Integer shift;
    algorithm
      m := Array.expandToSize(arrayLength(m) + shift, m, {});
    end expandMatrix;

    function transposeScalar
      input array<list<Integer>> m      "original matrix";
      input Integer size                "size of the transposed matrix (does not have to be square!)";
      output array<list<Integer>> mT    "transposed matrix";
    algorithm
      mT := arrayCreate(size, {});
      // loop over all elements and store them in reverse
      for row in 1:arrayLength(m) loop
        for idx in m[row] loop
          try
            if idx > 0 then
              mT[idx] := row :: mT[idx];
            else
              mT[intAbs(idx)] := -row :: mT[intAbs(idx)];
            end if;
          else
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for variable index " + intString(idx) + ".
              The variables have to be dense (without empty spaces) for this to work!"});
          end try;
        end for;
      end for;
      // sort the transposed matrix
      // bigger to lower such that negative entries are at the and
      for row in 1:arrayLength(mT) loop
        mT[row] := List.sort(mT[row], intLt);
      end for;
    end transposeScalar;

  protected
    function toStringSingle
      input array<list<Integer>> m;
      output String str = "";
    algorithm
      for row in 1:arrayLength(m) loop
        str := str + "\t(" + intString(row) + ")\t" + List.toString(m[row], intString) + "\n";
      end for;
    end toStringSingle;

    function createPseudo
      input VariablePointers vars;
      input EquationPointers eqns;
      input MatrixStrictness st = MatrixStrictness.FULL;
      output Matrix adj;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      Pointer<Differentiate.DifferentiationArguments> diffArgs_ptr;
      Differentiate.DifferentiationArguments diffArgs;
      array<list<Integer>> m, mT;
      Integer eqn_scalar_size, var_scalar_size, eqn_idx_arr;
      array<array<Integer>> mode_to_var                                               "scal_eqn:  mode idx -> var";
      array<array<ComponentRef>> mode_to_cref                                         "arr_eqn:   mode idx -> cref to solve for";
      Mapping mapping                                                                 "scalar <-> array index mapping";
      CausalizeModes modes;
    algorithm
      if ExpandableArray.getNumberOfElements(vars.varArr) > 0 or ExpandableArray.getNumberOfElements(eqns.eqArr) > 0 then
        if Util.isSome(funcTree) then
          diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.TIME, Util.getOption(funcTree)));
        else
          diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default());
        end if;

        // create mapping
        mapping         := Mapping.create(eqns, vars);
        eqn_scalar_size := arrayLength(mapping.eqn_StA);
        var_scalar_size := arrayLength(mapping.var_StA);
        // create empty for-loop reconstruction information
        modes           := CausalizeModes.empty(eqn_scalar_size, EquationPointers.size(eqns));

        // create empty adjacency matrix and traverse equations to fill it
        m := arrayCreate(eqn_scalar_size, {});

        eqn_idx_arr := 1;
        for eqn_ptr in EquationPointers.toList(eqns) loop
          try
            updateRow(eqn_ptr, diffArgs_ptr, st, vars.map, m, mapping, modes, eqn_idx_arr, funcTree);
          else
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + Equation.pointerToString(eqn_ptr)});
            fail();
          end try;
          eqn_idx_arr := eqn_idx_arr + 1;
        end for;

        // also sorts the matrix
        mT := transposeScalar(m, var_scalar_size);

        if Util.isSome(funcTree) then
          diffArgs := Pointer.access(diffArgs_ptr);
          funcTree := SOME(diffArgs.funcTree);
        end if;

        adj := PSEUDO_ARRAY_ADJACENCY_MATRIX(m, mT, mapping, modes, st);
      else
        adj := EMPTY_ADJACENCY_MATRIX(MatrixType.PSEUDO, st);
      end if;
    end createPseudo;

    function updatePseudo
      input output array<list<Integer>> m;
      output array<list<Integer>> mT;
      input MatrixStrictness st;
      input Mapping mapping;
      input CausalizeModes modes;
      input VariablePointers vars;
      input EquationPointers eqns;
      input list<Integer> idx_lst;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      Pointer<Differentiate.DifferentiationArguments> diffArgs_ptr;
      Differentiate.DifferentiationArguments diffArgs;
    algorithm
      if Util.isSome(funcTree) then
        diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default(NBDifferentiate.DifferentiationType.TIME, Util.getOption(funcTree)));
      else
        diffArgs_ptr := Pointer.create(Differentiate.DifferentiationArguments.default());
      end if;

      // clean up the matrix and causalize modes of equations to be updated
      cleanMatrix(m, mapping, idx_lst);
      CausalizeModes.clean(modes, mapping, idx_lst);

      for i in idx_lst loop
        updateRow(EquationPointers.getEqnAt(eqns, i), diffArgs_ptr, st, vars.map, m, mapping, modes, i, funcTree);
      end for;

      // also sorts the matrix
      mT := transposeScalar(m, VariablePointers.scalarSize(vars));

      if Util.isSome(funcTree) then
        diffArgs := Pointer.access(diffArgs_ptr);
        funcTree := SOME(diffArgs.funcTree);
      end if;
    end updatePseudo;

    function updateRow
      "updates a row and adds all occurences of variables in the input map
      updates multiple rows for multi-dimensional equations."
      input Pointer<Equation> eqn_ptr;
      input Pointer<Differentiate.DifferentiationArguments> diffArgs_ptr;
      input MatrixStrictness st;
      input UnorderedMap<ComponentRef, Integer> map "hash table to check for relevance";
      input array<list<Integer>> m;
      input Mapping mapping;
      input CausalizeModes modes                    "mutable";
      input Integer eqn_idx;
      input Option<FunctionTree> funcTree = NONE()  "only needed for LINEAR without existing derivatives";
    protected
      Equation eqn;
      UnorderedSet<ComponentRef> unsolvables = UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
      list<ComponentRef> dependencies, nonlinear_dependencies, remove_dependencies = {};
      BEquation.EquationAttributes attr;
      Pointer<Equation> derivative;
      UnorderedMap<ComponentRef, Dependencies> dep_map;
      UnorderedMap<ComponentRef, Solvability> sol_map;
    algorithm
      eqn := Pointer.access(eqn_ptr);

      print(Equation.toString(eqn) + "\n");
      (dep_map, sol_map) := collectDependenciesEquation(eqn);
      print(UnorderedMap.toString(dep_map, ComponentRef.toString, Dependency.toString) + "\n");
      print(UnorderedMap.toString(sol_map, ComponentRef.toString, Solvability.toString) + "\n\n");

      dependencies := match eqn
        case Equation.ALGORITHM() then list(cref for cref guard(UnorderedMap.contains(cref, map)) in listAppend(eqn.alg.inputs, eqn.alg.outputs));
        else Equation.collectCrefs(eqn, function Slice.getDependentCref(map = map, pseudo = true));
      end match;

      if (st < MatrixStrictness.FULL) then
        // SOLVABLE & LINEAR
        // remove all unsolvables
        BEquation.Equation.map(eqn, function Slice.getUnsolvableExpCrefs(acc = unsolvables, map = map, pseudo = true));
        remove_dependencies := UnorderedSet.toList(unsolvables);
      end if;

      if (st < MatrixStrictness.SOLVABLE) then
        // LINEAR
        // if we only want linear dependencies, try to look if there is a derivative saved.
        // remove all dependencies of that equation because those are the nonlinear ones.
        attr := Equation.getAttributes(eqn);
        if Util.isSome(attr.derivative) then
          derivative := Util.getOption(attr.derivative);
        elseif Util.isSome(funcTree) then
          derivative := Differentiate.differentiateEquationPointer(eqn_ptr, diffArgs_ptr);
        else
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because no derivative is saved and no function tree is given for linear adjacency matrix!"});
          fail();
        end if;
        nonlinear_dependencies := BEquation.Equation.collectCrefs(Pointer.access(derivative), function Slice.getDependentCref(map = map, pseudo = true));
        remove_dependencies := listAppend(nonlinear_dependencies, remove_dependencies);
      end if;

      if not listEmpty(remove_dependencies) then
        dependencies := List.setDifferenceOnTrue(dependencies, remove_dependencies, ComponentRef.isEqual);
      end if;

      // create the actual matrix row(s).
      fillMatrix(eqn, m, mapping, modes, eqn_idx, dependencies, map);
    end updateRow;

    function fillMatrix
      "fills one or more rows (depending on equation size) of matrix m, starting from eqn_idx.
      Appends because STATE_SELECT and INIT add matrix entries in two steps to induce a specific ordering.
      For psuedo array matching: also fills mode_to_var."
      input Equation eqn;
      input array<list<Integer>> m;
      input Mapping mapping;
      input CausalizeModes modes                    "mutable";
      input Integer eqn_arr_idx;
      input list<ComponentRef> dependencies         "dependent var crefs";
      input UnorderedMap<ComponentRef, Integer> map "hash table to check for relevance";
    protected
      array<list<Integer>> m_part;
      array<array<Integer>> mode_to_var_part;
      Integer eqn_scal_idx, eqn_size;
      list<ComponentRef> unique_dependencies;
    algorithm
      unique_dependencies := list(ComponentRef.simplifySubscripts(dep) for dep in dependencies);
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print("\nFinding dependencies for:\n" + Equation.toString(eqn) + "\n");
        print("dependencies: " + List.toString(unique_dependencies, ComponentRef.toString) + "\n");
      end if;
      () := match eqn
        local
          list<Integer> row;

        case Equation.FOR_EQUATION() algorithm
          // get expanded matrix rows
          fillMatrixArray(eqn, unique_dependencies, map, mapping, eqn_arr_idx, m, modes, function Slice.getDependentCrefIndicesPseudoFor(iter = eqn.iter));
        then ();

        case Equation.ARRAY_EQUATION() algorithm
          fillMatrixArray(eqn, unique_dependencies, map, mapping, eqn_arr_idx, m, modes, function Slice.getDependentCrefIndicesPseudoFor(iter = Iterator.EMPTY()));
        then ();

        case Equation.RECORD_EQUATION() algorithm
          fillMatrixArray(eqn, unique_dependencies, map, mapping, eqn_arr_idx, m, modes, Slice.getDependentCrefIndicesPseudoFull);
        then ();

        case Equation.ALGORITHM() algorithm
          (eqn_scal_idx, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
          row := Slice.getDependentCrefIndicesPseudoScalar(unique_dependencies, map, mapping);
          for i in 1:eqn_size loop
            updateIntegerRow(m, eqn_scal_idx+(i-1), row);
          end for;
        then ();

        case Equation.IF_EQUATION() algorithm
          fillMatrixArray(eqn, unique_dependencies, map, mapping, eqn_arr_idx, m, modes, Slice.getDependentCrefIndicesPseudoFull);
        then ();

        case Equation.WHEN_EQUATION() algorithm
          fillMatrixArray(eqn, unique_dependencies, map, mapping, eqn_arr_idx, m, modes, Slice.getDependentCrefIndicesPseudoFull);
        then ();

        else algorithm
          (eqn_scal_idx, _) := mapping.eqn_AtS[eqn_arr_idx];
          row := Slice.getDependentCrefIndicesPseudoScalar(unique_dependencies, map, mapping);
          updateIntegerRow(m, eqn_scal_idx, row);
        then ();
      end match;
    end fillMatrix;

    function fillMatrixArray
      "adds multiple rows to the adjacency matrix at once.
      used for equations with size > 1"
      input Equation eqn                              "only for debug purposes";
      input list<ComponentRef> unique_dependencies;
      input UnorderedMap<ComponentRef, Integer> map;
      input Adjacency.Mapping mapping;
      input Integer eqn_arr_idx;
      input array<list<Integer>> m;
      input CausalizeModes modes;
      input Slice.getDependentCrefIndices func;
    protected
      Integer eqn_scal_idx, eqn_size;
      array<list<Integer>> m_part;
      array<array<Integer>> mode_to_var_part;
    algorithm
      (eqn_scal_idx, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
      (m_part, mode_to_var_part) := func(unique_dependencies, map, mapping, eqn_arr_idx);
      // check for arrayLength(m_part) == eqn_size ?
      if not arrayLength(m_part) == eqn_size then
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because equation size " + intString(eqn_size) +
         " differs from adjacency matrix row size " + intString(arrayLength(m_part)) + " for equation:\n" + Equation.toString(eqn)});
        fail();
      end if;
      // add matrix rows to correct locations and update causalize modes
      copyRows(m, eqn_scal_idx, m_part);
      if eqn_size > 1 then
        CausalizeModes.update(modes, eqn_scal_idx, eqn_arr_idx, mode_to_var_part, unique_dependencies);
      end if;
    end fillMatrixArray;

    function cleanMatrix
      input array<list<Integer>> m;
      input Mapping mapping;
      input list<Integer> idx_lst;
    protected
      list<Integer> scal_indices;
    algorithm
      for arr_idx in idx_lst loop
        scal_indices := Mapping.getEqnScalIndices(arr_idx, mapping);
        for scal_idx in scal_indices loop
          arrayUpdate(m, scal_idx, {});
        end for;
      end for;
    end cleanMatrix;

    function createArray
      input VariablePointers vars;
      input EquationPointers eqns;
      input MatrixStrictness st = MatrixStrictness.FULL;
      output Matrix adj;
      input output Option<FunctionTree> funcTree = NONE() "only needed for LINEAR without existing derivatives";
    protected
      BipartiteIncidenceList<SetVertex, SetEdge> graph;
      Pointer<Integer> max_dim = Pointer.create(1);
      Vector<Integer> vCount, eCount;
      UnorderedMap<SetVertex, Integer> vertexMap;
      UnorderedMap<SetEdge, Integer> edgeMap;
    algorithm
      // reset unique tick index to 0
      BuiltinSystem.tmpTickReset(0);

      // create empty set based graph and map
      graph := BipartiteIncidenceList.new(SetVertex.isEqual, SetEdge.isEqual, SetVertex.toString, SetEdge.toString);
      vertexMap := UnorderedMap.new<Integer>(SetVertex.hash, SetVertex.isEqual, VariablePointers.size(vars) + EquationPointers.size(eqns));
      edgeMap := UnorderedMap.new<Integer>(SetEdge.hash, SetEdge.isEqual, VariablePointers.size(vars) + EquationPointers.size(eqns)); // make better size approx here

      // find maximum number of dimensions
      VariablePointers.mapPtr(vars, function maxDimTraverse(max_dim = max_dim));
      EquationPointers.mapRes(eqns, function maxDimTraverse(max_dim = max_dim)); // maybe unnecessary?
      vCount := Vector.newFill(Pointer.access(max_dim), 1);
      eCount := Vector.newFill(Pointer.access(max_dim), 1);

      // create vertices for variables
      VariablePointers.mapPtr(vars, function SetVertex.createTraverse(graph = graph, vCount = vCount, ST = SetType.U, vertexMap = vertexMap));

      // create vertices for equations and create edges
      EquationPointers.map(eqns, function SetEdge.fromEquation(
        graph       = graph,
        vCount      = vCount,
        eCount      = eCount,
        map         = vars.map,
        vertexMap   = vertexMap,
        edgeMap     = edgeMap,
        eqn_tpl_opt = NONE()
      ));

      if Flags.isSet(Flags.DUMP_SET_BASED_GRAPHS) then
        print(BipartiteIncidenceList.toString(graph));
      end if;

      adj := ARRAY_ADJACENCY_MATRIX(graph, vertexMap, edgeMap, st);
    end createArray;

    function maxDimTraverse
      input Pointer<Variable> var_ptr;
      input Pointer<Integer> max_dim;
    protected
      Integer dim_size;
    algorithm
      dim_size := listLength(BVariable.getDimensions(var_ptr));
      if Pointer.access(max_dim) < dim_size then
        Pointer.update(max_dim, dim_size);
      end if;
    end maxDimTraverse;

    function copyRows
      input array<list<Integer>> m;
      input Integer eqn_scal_idx;
      input array<list<Integer>> m_part;
    algorithm
      for i in 1:arrayLength(m_part) loop
        updateIntegerRow(m, eqn_scal_idx+(i-1), m_part[i]);
      end for;
    end copyRows;

    function updateIntegerRow
      input array<list<Integer>> m;
      input Integer idx;
      input list<Integer> row;
    algorithm
      arrayUpdate(m, idx, listAppend(row, m[idx]));
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print("Adding to row " + intString(idx) + " " + List.toString(row, intString) + "\n");
      end if;
    end updateIntegerRow;
  end Matrix;

  uniontype Dependency
    "the dependency kind to show how a component reference occurs in an equation.
    for each dimension there has to be one dependency kind."
    record FULL   end FULL;
    record SINGLE end SINGLE;

    record SLICE
      Integer start;
      Integer step;
      Integer stop;
    end SLICE;

    record SUBSET
      list<Integer> set;
    end SUBSET;

    function toStringSingle
      input Dependency dep;
      output String str;
    algorithm
      str := match dep
        case FULL()   then ":";
        case SINGLE() then ".";
        case SLICE()  then intString(dep.start) + ":" + intString(dep.step) + ":" + intString(dep.stop);
        case SUBSET() then List.toString(dep.set, intString, "", "", ", ", "");
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown dependency kind."});
        then fail();
      end match;
    end toStringSingle;

    function toString
      input Dependencies deps;
      output String str = List.toString(deps, toStringSingle);
    end toString;

    function create
      input tuple<Dimension, Dimension> dim_tpl;
      output Dependency dep;
    algorithm
      dep := match dim_tpl
        local
          Dimension d1, d2;

        case (Dimension.BOOLEAN(), Dimension.BOOLEAN()) then SINGLE();
        case (Dimension.ENUM(), Dimension.ENUM()) then SINGLE();
        case (Dimension.INTEGER(size = 1), Dimension.INTEGER(size = 1)) then SINGLE();
        case (d1 as Dimension.INTEGER(), d2 as Dimension.INTEGER()) guard(d1.size == d2.size) then FULL();

        case (d1, d2) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unhandled dimension tuple: "
          + Dimension.toString(d1) + "-" + Dimension.toString(d2)});
        then fail();
        else algorithm
        then fail();
      end match;
    end create;

    function createList
      input Type sub_ty;
      input Type org_ty;
      output list<Dependency> deps;
    algorithm
      if Type.isArray(sub_ty) then
        deps := list(create(tpl) for tpl in List.zip(Type.arrayDims(sub_ty), Type.arrayDims(org_ty)));
      elseif Type.isArray(org_ty) then
        deps := List.fill(SINGLE(), Type.dimensionCount(org_ty));
      else
        deps := {FULL()};
      end if;
    end createList;
  end Dependency;

  type Dependencies = list<Dependency>;

  uniontype Solvability
    record UNKNOWN end UNKNOWN;
    record UNSOLVABLE end UNSOLVABLE;
    record IMPLICIT end IMPLICIT;

    record EXPLICIT_NONLINEAR
      Boolean unique "true if it has a unique solution when solved";
    end EXPLICIT_NONLINEAR;

    record EXPLICIT_LINEAR
      Boolean param                           "true if we need to devide by a parameter to solve";
      Option<UnorderedSet<ComponentRef>> vars "variables we need to devide by to solve";
    end EXPLICIT_LINEAR;

    function toString
      input Solvability sol;
      output String str;
    protected
      function sgnN
        input Boolean b;
        output String str = if b then "+" else "-";
      end sgnN;
      function sgnL
        input Boolean b1;
        input Boolean b2;
        output String str = if b2 then "V" elseif b1 then "P" else "C";
      end sgnL;
    algorithm
      str := match sol
        case UNSOLVABLE()         then "XX";
        case IMPLICIT()           then "II";
        case EXPLICIT_NONLINEAR() then "N" + sgnN(sol.unique);
        case EXPLICIT_LINEAR()    then "L" + sgnL(sol.param, Util.isSome(sol.vars));
        case UNKNOWN()            then "??";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown solvability kind."});
        then fail();
      end match;
    end toString;

    function strictness
      input Solvability sol;
      output Integer r;
    algorithm
      r := match sol
        case UNSOLVABLE()                                   then 7;
        case IMPLICIT()                                     then 6;
        case EXPLICIT_NONLINEAR(unique = false)             then 5;
        case EXPLICIT_NONLINEAR()                           then 4;
        case EXPLICIT_LINEAR() guard(Util.isSome(sol.vars)) then 3;
        case EXPLICIT_LINEAR(param = true)                  then 2;
        case EXPLICIT_LINEAR()                              then 1;
        case UNKNOWN()                                      then 0;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown solvability kind."});
        then fail();
      end match;
    end strictness;

    function update
      "sets the solvability of a component reference if it is of
      higher strictness than previously determined"
      input ComponentRef cref;
      input Solvability sol;
      input UnorderedMap<ComponentRef, Solvability> map;
    algorithm
      if strictness(sol) > strictness(Util.getOptionOrDefault(UnorderedMap.get(cref, map), UNKNOWN())) then
        UnorderedMap.add(cref, sol, map);
      end if;
    end update;
  end Solvability;

  function collectDependenciesEquation
    input Equation eqn;
    output UnorderedMap<ComponentRef, Dependencies> dep_map = UnorderedMap.new<Dependencies>(ComponentRef.hash, ComponentRef.isEqual);
    output UnorderedMap<ComponentRef, Solvability> sol_map  = UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual);
  algorithm
    _ := match eqn
      case Equation.SCALAR_EQUATION() algorithm
        _ := collectDependencies(eqn.lhs, dep_map, sol_map);
        _ := collectDependencies(eqn.rhs, dep_map, sol_map);
      then ();

      case Equation.ARRAY_EQUATION() algorithm
        _ := collectDependencies(eqn.lhs, dep_map, sol_map);
        _ := collectDependencies(eqn.rhs, dep_map, sol_map);
      then ();

      case Equation.RECORD_EQUATION() algorithm
        _ := collectDependencies(eqn.lhs, dep_map, sol_map);
        _ := collectDependencies(eqn.rhs, dep_map, sol_map);
      then ();

      case Equation.ALGORITHM() algorithm
        /*
        // pass mapFunc because the function itself does not map
        alg := Algorithm.mapExp(eq.alg, function mapFunc(func = funcExp));
        if isSome(funcCrefOpt) then
          SOME(funcCref) := funcCrefOpt;
          // ToDo referenceEq for lists?
          //alg.inputs := List.map(alg.inputs, funcCref);
          alg.outputs := List.map(alg.outputs, funcCref);
        end if;
        eq.alg := alg;
        */
      then ();

      case Equation.IF_EQUATION() algorithm
        /*
        ifEqBody := IfEquationBody.map(eq.body, funcExp, funcCrefOpt, mapFunc);
        if not referenceEq(ifEqBody, eq.body) then
          eq.body := ifEqBody;
        end if;
        */
      then ();

      case Equation.FOR_EQUATION() algorithm
        /*
        iter := Iterator.map(eq.iter, funcExp, funcCrefOpt, mapFunc);
        if not referenceEq(iter, eq.iter) then
          eq.iter := iter;
        end if;
        eq.body := list(map(body_eqn, funcExp, funcCrefOpt) for body_eqn in eq.body);
        */
      then ();

      case Equation.WHEN_EQUATION() algorithm
        /*
        whenEqBody := WhenEquationBody.map(eq.body, funcExp, funcCrefOpt, mapFunc);
        if not referenceEq(whenEqBody, eq.body) then
          eq.body := whenEqBody;
        end if;
        */
      then ();
      else ();
    end match;
  end collectDependenciesEquation;

  /*
  input map cref -> list<dependency>
  input map cref -> solvability

  output set cref
  */

  function collectDependencies
    input Expression exp;
    input UnorderedMap<ComponentRef, Dependencies> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    output UnorderedSet<ComponentRef> set;
  algorithm
    set := match exp
      local
        list<Dependency> deps;
        UnorderedSet<ComponentRef> set1, set2, inter;
        list<UnorderedSet<ComponentRef>> sets = {}, sets_inv = {};
        Expression call_exp;
        Call call;

      // ALL todo:
      case Expression.CREF() algorithm
        deps := Dependency.createList(ComponentRef.getSubscriptedType(exp.cref), ComponentRef.getSubscriptedType(ComponentRef.stripSubscriptsAll(exp.cref)));
        UnorderedMap.add(exp.cref, deps, dep_map);
        Solvability.update(exp.cref, Solvability.EXPLICIT_LINEAR(false, NONE()), sol_map);
      then UnorderedSet.fromList({exp.cref}, ComponentRef.hash, ComponentRef.isEqual);

      case Expression.ARRAY(literal = false) algorithm
        // ToDo: need to update dependencies here
        for elem in exp.elements loop
          sets := collectDependencies(elem, dep_map, sol_map) :: sets;
        end for;
      then UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);

      case Expression.BINARY() algorithm
        set1 := collectDependencies(exp.exp1, dep_map, sol_map);
        set2 := collectDependencies(exp.exp2, dep_map, sol_map);
        inter := UnorderedSet.intersection(set1, set2);
        // + * array/vector/scalar/record
      then UnorderedSet.union(set1, set2);

      case Expression.MULTARY() algorithm
        for arg in exp.arguments loop
          sets := collectDependencies(arg, dep_map, sol_map) :: sets;
        end for;
        for arg in exp.inv_arguments loop
          sets_inv := collectDependencies(arg, dep_map, sol_map) :: sets_inv;
        end for;
      then UnorderedSet.union_list(listAppend(sets, sets_inv), ComponentRef.hash, ComponentRef.isEqual);

      // for reductions set the dependency to full
      case Expression.CALL(call = call as Call.TYPED_REDUCTION(exp = call_exp)) algorithm
        set := collectDependencies(call_exp, dep_map, sol_map);
      then set;

      // for array constructors replace all iterators (temporarily)
      case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR(exp = call_exp)) algorithm
        for iter in call.iters loop
          call_exp := Expression.replaceIterator(call_exp, Util.tuple21(iter), Util.tuple22(iter));
        end for;
      then collectDependencies(call_exp, dep_map, sol_map);



  /*
  record BINARY "Binary operations, e.g. a+4"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end BINARY;


  record MULTARY
    "Multary expressions with the same operator, e.g. a+b+c
    An empty list has to be interpreted as the neutral element of the operator space"
    list<Expression> arguments      "arguments that are chained with the operator (+, *)";
    list<Expression> inv_arguments  "arguments that are chained with the inverse operator (-, :)";
    Operator operator               "Can only be + or * (commutative)";
  end MULTARY;

  record RANGE
    Type ty;
    Expression start;
    Option<Expression> step;
    Expression stop;
  end RANGE;

  record TUPLE
    Type ty;
    list<Expression> elements;
  end TUPLE;

  record RECORD
    Path path; // Maybe not needed since the type contains the name. Prefix?
    Type ty;
    list<Expression> elements;
  end RECORD;

  record CALL
    Call call;
  end CALL;

  record SIZE
    Expression exp;
    Option<Expression> dimIndex;
  end SIZE;

  record END
  end END;



  record UNARY "Unary operations, -(4x)"
    Operator operator;
    Expression exp;
  end UNARY;

  record LBINARY "Logical binary operations: and, or"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end LBINARY;

  record LUNARY "Logical unary operations: not"
    Operator operator;
    Expression exp;
  end LUNARY;

  record RELATION "Relation, e.g. a <= 0"
    Expression exp1;
    Operator operator;
    Expression exp2;
  end RELATION;


  record IF
    Type ty;
    Expression condition;
    Expression trueBranch;
    Expression falseBranch;
  end IF;

  record CAST
    Type ty;
    Expression exp;
  end CAST;

  record BOX "MetaModelica boxed value"
    Expression exp;
  end BOX;

  record UNBOX "MetaModelica value unboxing (similar to a cast)"
    Expression exp;
    Type ty;
  end UNBOX;

  record SUBSCRIPTED_EXP
    Expression exp;
    list<Subscript> subscripts;
    Type ty;
    Boolean split;
  end SUBSCRIPTED_EXP;

  record TUPLE_ELEMENT
    Expression tupleExp;
    Integer index;
    Type ty;
  end TUPLE_ELEMENT;

  record RECORD_ELEMENT
    Expression recordExp;
    Integer index;
    String fieldName;
    Type ty;
  end RECORD_ELEMENT;

  record MUTABLE
    Mutable<Expression> exp;
  end MUTABLE;

  record EMPTY
    Type ty;
  end EMPTY;

  record PARTIAL_FUNCTION_APPLICATION
    ComponentRef fn;
    list<Expression> args;
    list<String> argNames;
    Type ty;
  end PARTIAL_FUNCTION_APPLICATION;
    */
      else UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    end match;
  end collectDependencies;

  annotation(__OpenModelica_Interface="backend");
end NBAdjacency;


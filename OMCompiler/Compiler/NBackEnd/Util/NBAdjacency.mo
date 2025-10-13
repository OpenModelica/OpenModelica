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
  import SimplifyExp = NFSimplifyExp;
  import Subscript = NFSubscript;
  import Type = NFType;
  import Operator = NFOperator;
  import Variable = NFVariable;

  // NB imports
  import Differentiate = NBDifferentiate;
  import NBDifferentiate.{DifferentiationArguments, DifferentiationType};
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationAttributes, EquationPointers, Iterator, IfEquationBody, WhenEquationBody, WhenStatement};
  import Solve = NBSolve;
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;

  // Util import
  import Array;
  import BackendUtil = NBBackendUtil;
  import BuiltinSystem = System;
  import Slice = NBSlice;
  import StringUtil;

public
  type MatrixStrictness  = enumeration(LINEAR, MATCHING, SORTING, FULL);

  function strictnessString
    input MatrixStrictness s;
    output String str;
  algorithm
    str := match s
      case MatrixStrictness.LINEAR    then "linear";
      case MatrixStrictness.MATCHING  then "matching";
      case MatrixStrictness.SORTING   then "sorting";
      case MatrixStrictness.FULL      then "full";
      else                                 "unknown";
    end match;
  end strictnessString;

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
      Integer eqn_scalar_size, var_scalar_size;
      Integer eqn_idx_scal = 1, eqn_idx_arr = 1, var_idx_scal = 1, var_idx_arr = 1;
    algorithm
      // prepare the mappings
      eqn_scalar_size := sum(Equation.size(eqn, true) for eqn in eqn_lst);
      var_scalar_size := sum(BVariable.size(var, true) for var in var_lst);
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
    protected
      array<Integer> eqn_StA, var_StA;
      array<tuple<Integer,Integer>> eqn_AtS, var_AtS;
      Integer eqn_scalar_size, var_scalar_size;
      Integer neqn_scal = sum(Equation.size(eqn, true) for eqn in eqn_lst);
      Integer nvar_scal = sum(BVariable.size(var, true) for var in var_lst);
      Integer neqn_arr = listLength(eqn_lst);
      Integer nvar_arr = listLength(var_lst);
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
          subs_lst  := Subscript.scalarizeList(subs, dims, true);
          subs_lst  := List.combination(subs_lst);
          dim_sizes := list(Dimension.size(dim) for dim in dims);
          for sub_lst in listReverse(subs_lst) loop
            values  := list(Subscript.toInteger(s) for s in sub_lst);
            slice   := Slice.locationToIndex(dim_sizes, values, start) :: slice;
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
        size := Equation.size(eqn_ptr, true);
        eqn_AtS[eqn_idx_arr] := (eqn_idx_scal, size);
        for i in eqn_idx_scal:eqn_idx_scal+size-1 loop
          eqn_StA[i] := eqn_idx_arr;
        end for;
        eqn_idx_scal := eqn_idx_scal + size;
        eqn_idx_arr := eqn_idx_arr + 1;
      end for;
      // fill variable mapping
      for var_ptr in var_lst loop
        size := BVariable.size(var_ptr, true);
        var_AtS[var_idx_arr] := (var_idx_scal, size);
        for i in var_idx_scal:var_idx_scal+size-1 loop
          var_StA[i] := var_idx_arr;
        end for;
        var_idx_scal := var_idx_scal + size;
        var_idx_arr := var_idx_arr + 1;
      end for;
    end fill_;
  end Mapping;

  uniontype Mode
    record MODE
      "most of the time this will only have one cref. if there are multiple crefs
      representing the same variable its a multi mode and the equation needs to
      be split when solved for it"
      ComponentRef eqn_name     "the equation name";
      list<ComponentRef> crefs  "the cref(s) to solve for";
      Boolean scalarize         "true if the equation needs to be scalarized to find the cref to solve for";
    end MODE;

    function toString
      input Mode mode;
      output String str = "[eqn: " + ComponentRef.toString(mode.eqn_name) + ", crefs: " + List.toString(mode.crefs, ComponentRef.toString) + ", scal: " + boolString(mode.scalarize) + "]";
    end toString;

    function hash
      input Mode mode;
      output Integer hash = ComponentRef.hash(mode.eqn_name);
    end hash;

    function isEqual
      input Mode mode1;
      input Mode mode2;
      output Boolean b = ComponentRef.isEqual(mode1.eqn_name, mode2.eqn_name) and mode1.scalarize == mode2.scalarize
        and List.isEqualOnTrue(mode1.crefs, mode2.crefs, ComponentRef.isEqual);
    end isEqual;

    function create
      input ComponentRef eqn_name;
      input list<ComponentRef> crefs;
      input Boolean scalarize;
      output Mode mode = MODE(eqn_name, list(ComponentRef.simplifySubscripts(cref) for cref in crefs), scalarize);
    end create;

    function merge
      input Mode mode1;
      input Mode mode2;
      output Mode oMode = MODE(mode1.eqn_name, listAppend(mode1.crefs, mode2.crefs), mode1.scalarize or mode2.scalarize);
    end merge;

    function mergeCreate
      input Option<Mode> omode;
      input output Mode mode;
    algorithm
      mode := Util.applyOptionOrDefault(omode, function merge(mode1 = mode), mode);
    end mergeCreate;

    type Key = tuple<Integer, Integer>;

    function keyString
      input Key key;
      output String str;
    protected
      Integer e,v;
    algorithm
      (e,v) := key;
      str := intString(e) + "," + intString(v);
    end keyString;

    function keyHash
      input Key key;
      output Integer hash;
    protected
      Integer e,v;
    algorithm
      (e,v) := key;
      hash := e * 31 + v;
    end keyHash;

    function keyEqual
      input Key key1;
      input Key key2;
      output Boolean b;
    protected
      Integer e1,e2,v1,v2;
    algorithm
      (e1,v1) := key1;
      (e2,v2) := key2;
      b := e1 == e2 and v1 == v2;
    end keyEqual;
  end Mode;

  uniontype Matrix
    "used to store adjacency information for the bipartite graph representing the system of equations and variables
    you have to create it in this specific order: EMPTY->FULL->FINAL(LINEAR)->FINAL->(MATCHING)->FINAL(SORTING)
    and store the FULL for further use."

    record EMPTY "placeholder for empty matrices, just stores intended strictness"
      MatrixStrictness st;
    end EMPTY;

    record FULL "contains all information needed. create specific final matrices from this"
      array<ComponentRef> equation_names;
      array<UnorderedSet<ComponentRef>> occurences;
      array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
      array<UnorderedSet<ComponentRef>> repetitions;
      Mapping mapping;
    end FULL;

    record FINAL "specific final matrix, defined by its strictness"
      array<list<Integer>> m              "eqn -> list<var>";
      array<list<Integer>> mT             "var -> list<eqn>";
      Mapping mapping                     "index mapping scalar <-> array";
      UnorderedMap<Mode.Key, Mode> modes  "array reconstruction information";
      MatrixStrictness st                 "strictness with which it was created";
    end FINAL;

    function createFull
      input VariablePointers vars;
      input EquationPointers eqns;
      output Matrix adj;
    protected
      Integer index, size = EquationPointers.size(eqns);
      array<ComponentRef> equation_names;
      array<UnorderedSet<ComponentRef>> occurences;
      array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
      array<UnorderedSet<ComponentRef>> repetitions;
      UnorderedSet<ComponentRef> occ_set, rep_set;
      UnorderedMap<ComponentRef, Dependency> dep_map;
      UnorderedMap<ComponentRef, Solvability> sol_map;
      Mapping mapping;
    algorithm
      // only create matrix if there are any variables or equations
      if ExpandableArray.getNumberOfElements(vars.varArr) > 0 or ExpandableArray.getNumberOfElements(eqns.eqArr) > 0 then
        // create empty arrays for the structures
        equation_names  := arrayCreate(size, ComponentRef.EMPTY());
        occurences      := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
        dependencies    := arrayCreate(size, UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual));
        solvabilities   := arrayCreate(size, UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual));
        repetitions     := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
        // loop over each equation and create the corresponding maps and sets
        for eqn_ptr in EquationPointers.toList(eqns) loop
          index   := UnorderedMap.getSafe(Equation.getEqnName(eqn_ptr), eqns.map, sourceInfo());
          dep_map := UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual);
          sol_map := UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual);
          rep_set := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
          occ_set := collectDependenciesEquation(Pointer.access(eqn_ptr), vars.map, dep_map, sol_map, rep_set);
          equation_names[index] := Equation.getEqnName(eqn_ptr);
          occurences[index]     := occ_set;
          dependencies[index]   := dep_map;
          solvabilities[index]  := sol_map;
          repetitions[index]    := rep_set;
        end for;
        // create the index mapping and the matrix
        mapping := Mapping.create(eqns, vars);
        adj := FULL(equation_names, occurences, dependencies, solvabilities, repetitions, mapping);
      else
        adj := EMPTY(MatrixStrictness.FULL);
      end if;
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(StringUtil.headline_1("Creating Adjacency Matrices") + "\n");
        print(EquationPointers.toString(eqns) + "\n");
        print(VariablePointers.toString(vars) + "\n");
        print(toString(adj, "Full") + "\n");
        print(solvabilityString(adj, "Full") + "\n");
        print(dependencyString(adj, "Full") + "\n");
      end if;
    end createFull;

    function fromFull
      input Matrix full;
      input UnorderedMap<ComponentRef, Integer> vars_map;
      input UnorderedMap<ComponentRef, Integer> eqns_map;
      input EquationPointers eqns;
      input MatrixStrictness st;
      input Iterator iter = Iterator.EMPTY() "optional iterator the whole system might be surrounded by";
      output Matrix adj = upgrade(EMPTY(MatrixStrictness.FULL), full, vars_map, eqns_map, eqns, st, iter);
    end fromFull;

    function upgrade
      "upgrades a matrix using the information provided by the full matrix"
      input output Matrix adj;
      input Matrix full;
      input UnorderedMap<ComponentRef, Integer> vars_map;
      input UnorderedMap<ComponentRef, Integer> eqns_map;
      input EquationPointers eqns;
      input MatrixStrictness st;
      input Iterator iter = Iterator.EMPTY();
    algorithm
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(StringUtil.headline_1("Upgrading from [" + strictnessString(getStrictness(adj)) + "] to [" + strictnessString(st) +"]") + "\n");
      end if;

      adj := match full
        local
          Integer min, max;

        case EMPTY() then EMPTY(st);

        case FULL() algorithm
          // empty matrices can have a strictness if we want to expand them, in this case ignore and overwrite
          if isEmpty(adj) then
            min := 0;
            adj := initialize(full.mapping, st);
          else
            min := Solvability.rank(Solvability.fromStrictness(getStrictness(adj)));
          end if;
          max := Solvability.rank(Solvability.fromStrictness(st));

          adj := match adj
            local
              Matrix result;
              list<ComponentRef> filtered;
              array<UnorderedSet<ComponentRef>> occ;
              array<UnorderedMap<ComponentRef, Dependency>> dep;
              array<UnorderedMap<ComponentRef, Solvability>> sol;
              array<UnorderedSet<ComponentRef>> rep;

            // default case
            case FINAL() algorithm
              // only do if valid upgrade otherwise create from scratch and issue warning if failtrace is activated
              if max == min then
                result := adj;
              elseif max > min then
                (occ, dep, sol, rep) := (full.occurences, full.dependencies, full.solvabilities, full.repetitions);
                for index in UnorderedMap.valueList(eqns_map) loop
                  filtered := Solvability.filter(UnorderedSet.toList(occ[index]), sol[index], vars_map, min, max);
                  // upgrade the row and all meta data
                  upgradeRow(EquationPointers.getEqnAt(eqns, index), index, filtered, dep[index], rep[index], vars_map, vars_map, adj.m, adj.mapping, adj.modes, iter);
                end for;
                adj.mT := transposeScalar(adj.m, arrayLength(adj.mapping.var_StA));
                result := adj;
              else
                if Flags.isSet(Flags.FAILTRACE) then
                  Error.addCompilerWarning("Invalid matrix upgrade request. Cannot upgrade matrix of type "
                    + Solvability.toString(Solvability.fromStrictness(getStrictness(adj))) + " to type "
                    + Solvability.toString(Solvability.fromStrictness(st)) + ". The new matrix will be
                    created from using only the full adjacency matrix.");
                end if;
                result := fromFull(full, vars_map, eqns_map, eqns, st, iter);
              end if;
            then result;

            // if its still empty even after initializing it, there are no variables or equations
            case EMPTY() then adj;

            // cannot upgrade a full matrix
            case FULL() algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for because of wrong matrix type for the 1st input.
                Expected: final or empty, Got :" + strictnessString(getStrictness(adj)) + "."});
            then fail();
          end match;
        then adj;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for because of wrong matrix type for the 2nd input.
            Expected: full, Got :" + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(adj, "Final") + "\n");
      end if;
    end upgrade;

    function expand
      "expands the adjacency matrix adj with new information provided by vn and en.
      If necessary it also expands the full matrix."
      input output Matrix adj                             "adjancency matrix to be expanded";
      input output Matrix full                            "full matrix having all information";
      input UnorderedMap<ComponentRef, Integer> vo, vn    "old and new variable index map";
      input UnorderedMap<ComponentRef, Integer> eo, en    "old and new equation index map";
      input VariablePointers vars                         "all variables, containing new and old";
      input EquationPointers eqns                         "all equations, containing new and old";
    protected
      Integer size_vo, size_vn, size_eo, size_en; //only for debugging
    algorithm
      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        size_vo := sum(ComponentRef.size(var, true) for var in UnorderedMap.keyList(vo));
        size_vn := sum(ComponentRef.size(var, true) for var in UnorderedMap.keyList(vn)) + size_vo;
        size_eo := sum(ComponentRef.size(eqn, true) for eqn in UnorderedMap.keyList(eo));
        size_en := sum(ComponentRef.size(eqn, true) for eqn in UnorderedMap.keyList(en)) + size_eo;
        print(StringUtil.headline_1("Expanding from size [vars: " + intString(size_vo) + "| eqns: " + intString(size_eo) + "] to [vars: " + intString(size_vn) + "| eqns: " + intString(size_en) +  "]") + "\n");
      end if;

      // check if full has to be expanded
      full := match full
        case FULL() guard(EquationPointers.size(eqns) > arrayLength(full.equation_names))
          then expandFull(full, vo, vn, eo, en, vars, eqns);
        else full;
      end match;

      adj := match (adj, full)
        local
          Matrix new;
          Integer rank, max_index_eq, max_index_var;
          list<ComponentRef> filtered;
          UnorderedMap<ComponentRef, Integer> v = vo;

        // if the matrix is empty, initialize it first
        case (EMPTY(), FULL()) algorithm
          new := initialize(full.mapping, adj.st);
          if not isEmpty(new) then
            new := expand(new, full, vo, vn, eo, en, vars, eqns);
          end if;
        then new;

        // default case
        case (FINAL(), FULL()) algorithm
          // 0. expand the integer matrix
          adj.m := expandMatrix(adj.m, EquationPointers.scalarSize(eqns, true) - arrayLength(adj.m));
          adj.mapping := full.mapping;

          // get the strictness ranking
          rank := Solvability.rank(Solvability.fromStrictness(getStrictness(adj)));
          // only merge if there is a second phase
          if not UnorderedMap.isEmpty(vn) and not UnorderedMap.isEmpty(en) then
            v := UnorderedMap.merge(v, vn, sourceInfo());
          end if;

          // I. update all old equations with the new variables
          if not UnorderedMap.isEmpty(vn) then
            for e in UnorderedMap.valueList(eo) loop
              filtered := Solvability.filter(UnorderedSet.toList(full.occurences[e]), full.solvabilities[e], vn, 0, rank);
              upgradeRow(EquationPointers.getEqnAt(eqns, e), e, filtered, full.dependencies[e], full.repetitions[e], vn, vars.map, adj.m, adj.mapping, adj.modes);
            end for;
          end if;

          // II. update new equations with all variables
          if not UnorderedMap.isEmpty(en) then
            for e in UnorderedMap.valueList(en) loop
              filtered := Solvability.filter(UnorderedSet.toList(full.occurences[e]), full.solvabilities[e], v, 0, rank);
              upgradeRow(EquationPointers.getEqnAt(eqns, e), e, filtered, full.dependencies[e], full.repetitions[e], v, vars.map, adj.m, adj.mapping, adj.modes);
            end for;
          end if;

          // transpose the matrix
          if UnorderedMap.isEmpty(vo) and UnorderedMap.isEmpty(vn) then
            max_index_var := 0;
          else
            max_index_var := intMax(max(i for i in UnorderedMap.valueList(vo)), max(i for i in UnorderedMap.valueList(vn)));
          end if;
          adj.mT := transposeScalar(adj.m, VariablePointers.scalarSize(vars, true));
        then adj;

        // fail cases
        case (FINAL(), _) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the full matrix expected to contain all information is instead of type "
            + strictnessString(getStrictness(full)) + "."});
        then fail();

        case (_, FULL()) algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the matrix to be expanded of type "
            + strictnessString(getStrictness(adj)) + " should be of type final."});
        then fail();

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected types final and full, got types " + strictnessString(getStrictness(adj))
            + " and " + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(adj, "Expanded Final") + "\n");
      end if;
    end expand;

    function expandFull
      "usually only called from expand()"
      input output Matrix full                            "full matrix having all information";
      input UnorderedMap<ComponentRef, Integer> vo, vn    "old and new variable index map";
      input UnorderedMap<ComponentRef, Integer> eo, en    "old and new equation index map";
      input VariablePointers vars                         "all variables, containing new and old";
      input EquationPointers eqns                         "all equations, containing new and old";
    algorithm
      full := match full
        local
          list<Pointer<Variable>> new_vars = list(VariablePointers.getVarAt(vars, idx) for idx in UnorderedMap.valueList(vn));
          list<Pointer<Equation>> new_eqns = list(EquationPointers.getEqnAt(eqns, idx) for idx in UnorderedMap.valueList(en));
          Integer index, size = EquationPointers.size(eqns);
          Pointer<Equation> eqn_ptr;
          UnorderedSet<ComponentRef> occ_set;
        case FULL() algorithm
          // 0. enlargen the arrays
          full := FULL(Array.expandToSize(size, full.equation_names, ComponentRef.EMPTY()),
            Array.expandToSize(size, full.occurences, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual)),
            Array.expandToSize(size, full.dependencies, UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual)),
            Array.expandToSize(size, full.solvabilities, UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual)),
            Array.expandToSize(size, full.repetitions, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual)),
            Mapping.expand(full.mapping, new_eqns, new_vars));

          // I. update all old equations with the new variables
          if not UnorderedMap.isEmpty(vn) then
            for e in UnorderedMap.valueList(eo) loop
              eqn_ptr := EquationPointers.getEqnAt(eqns, e);
              index   := UnorderedMap.getSafe(Equation.getEqnName(eqn_ptr), eqns.map, sourceInfo());
              occ_set := collectDependenciesEquation(Pointer.access(eqn_ptr), vn, full.dependencies[index], full.solvabilities[index], full.repetitions[index]);
              full.occurences[index] := UnorderedSet.union(full.occurences[index], occ_set);
            end for;
          end if;

          // II. update new equations with all variables
          if not UnorderedMap.isEmpty(en) then
            for e in UnorderedMap.valueList(en) loop
              eqn_ptr := EquationPointers.getEqnAt(eqns, e);
              index   := UnorderedMap.getSafe(Equation.getEqnName(eqn_ptr), eqns.map, sourceInfo());
              occ_set := collectDependenciesEquation(Pointer.access(eqn_ptr), vars.map, full.dependencies[index], full.solvabilities[index], full.repetitions[index]);
              full.equation_names[index] := Equation.getEqnName(eqn_ptr);
              full.occurences[index] := occ_set;
            end for;
          end if;
        then full;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected type full, got type " + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(full, "Expanded Full") + "\n");
      end if;
    end expandFull;

    function refine
      "refines the solvability kind using differentiation
      Note: only updates the solvabilites of the variables and equations from the maps v and e"
      input output Matrix full;
      input output FunctionTree funcTree;
      input UnorderedMap<ComponentRef, Integer> v    "variables to refine";
      input UnorderedMap<ComponentRef, Integer> e    "equations to refine";
      input VariablePointers vars                    "all variables";
      input EquationPointers eqns                    "all equations";
      input UnorderedSet<ComponentRef> vars_set      "context variables to determine solvability";
      input Boolean init                             "true if initial";
    algorithm
      (full, funcTree) := match full
        local
          DifferentiationArguments diffArgs = DifferentiationArguments.default(NBDifferentiate.DifferentiationType.SIMPLE, funcTree);
          Pointer<Equation> eqn_ptr;
          Expression residual, exp;
          Solve.Status status;
          Solvability sol;
          UnorderedSet<ComponentRef> linear_set, param_set, var_set;
          Boolean eqnIsDiscrete, eqnIsIf;

        case FULL() algorithm
          for eqn_idx in UnorderedMap.valueArray(e) loop
            eqn_ptr := EquationPointers.getEqnAt(eqns, eqn_idx);
            eqnIsDiscrete := Equation.isDiscrete(eqn_ptr) or Equation.isWhenEquation(eqn_ptr);
            eqnIsIf := Equation.isIfEquation(eqn_ptr);
            if not (eqnIsDiscrete or eqnIsIf) then
              residual := Equation.getResidualExp(Pointer.access(eqn_ptr));
            end if;
            for var in UnorderedSet.toArray(full.occurences[eqn_idx]) loop
              // only do something if var is to be refined
              if UnorderedMap.contains(var, v) then
                // only do something if it is not implicit or unsolvable)
                sol := UnorderedMap.getSafe(var, full.solvabilities[eqn_idx], sourceInfo());
                if Solvability.rank(sol) < Solvability.rank(Solvability.IMPLICIT()) then
                  // booleans or (todo: enumerations)
                  if eqnIsDiscrete or not BVariable.checkCref(var, function BVariable.isContinuous(init = init), sourceInfo()) then
                    // if the equation or cref type is boolean, it can only be solved if its isolated in the LHS or RHS
                    // Use solveSimple for this and check if status is EXPLICIT
                    (_, status, _) := Solve.solveSimple(Pointer.access(eqn_ptr), var);
                    sol := if status == NBSolve.Status.EXPLICIT then Solvability.EXPLICIT_LINEAR(NONE(), NONE()) else Solvability.UNSOLVABLE();
                  elseif eqnIsIf then
                    // TODO more thorough analysis
                    sol := Solvability.IMPLICIT();
                  else
                    // get the residual expression, differentiate and simplify it
                    diffArgs.diffCref := var;
                    (exp, diffArgs) := Differentiate.differentiateExpressionDump(residual, diffArgs, getInstanceName());
                    exp             := SimplifyExp.simplifyDump(exp, true, getInstanceName());
                    if Expression.isZero(exp) then
                      sol := Solvability.UNSOLVABLE();
                    elseif Expression.containsCrefSet(exp, vars_set) then
                      // nonlinear -> unique solution if does not contain the variable itself
                      // TODO: might still be unique in some cases, even if contains the variable, e.g. `exp(x)`
                      sol := Solvability.EXPLICIT_NONLINEAR(Expression.containsCref(exp, var));
                    else
                      // linear -> find all contained crefs and split them by kind. remove constants and save params / variables
                      linear_set  := Expression.extractCrefs(exp);
                      linear_set  := UnorderedSet.filterOnFalse(linear_set, function BVariable.checkCref(func = BVariable.isConst, info = sourceInfo()));
                      (param_set, var_set) := UnorderedSet.splitOnTrue(linear_set, function BVariable.checkCref(func = BVariable.isParamOrConst, info = sourceInfo()));
                      sol := Solvability.EXPLICIT_LINEAR(
                        pars = if UnorderedSet.isEmpty(param_set) then NONE() else SOME(param_set),
                        vars = if UnorderedSet.isEmpty(var_set) then NONE() else SOME(var_set));
                    end if;
                  end if;
                  UnorderedMap.add(var, sol, full.solvabilities[eqn_idx]);
                end if;
              end if;
            end for;
          end for;
        then (full, diffArgs.funcTree);
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected type full, got type " + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(full, "Refined Full") + "\n");
      end if;
    end refine;

    function compress
      "use after equations have been removed"
      input output Matrix adj;
      input output Matrix full;
      input EquationPointers eqns;
      input VariablePointers vars;
      input UnorderedMap<ComponentRef, Integer> old_map;
    protected
      Integer index_old, index_new, size = EquationPointers.size(eqns);
      ComponentRef name;
      array<ComponentRef> equation_names;
      array<UnorderedSet<ComponentRef>> occurences;
      array<UnorderedMap<ComponentRef, Dependency>> dependencies;
      array<UnorderedMap<ComponentRef, Solvability>> solvabilities;
      array<UnorderedSet<ComponentRef>> repetitions;
      Mapping mapping;
      array<list<Integer>> m;
      Integer old_start, old_size, new_start, new_size;
    algorithm
      (adj, full) := match (adj, full)
        local
          Matrix new_adj, new_full;
        case (FINAL(), FULL()) algorithm
          // create the index mapping from scratch
          mapping := Mapping.create(eqns, vars);

          // create empty arrays for the structures
          m               := arrayCreate(arrayLength(mapping.eqn_StA), {});
          equation_names  := arrayCreate(size, ComponentRef.EMPTY());
          occurences      := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
          dependencies    := arrayCreate(size, UnorderedMap.new<Dependency>(ComponentRef.hash, ComponentRef.isEqual));
          solvabilities   := arrayCreate(size, UnorderedMap.new<Solvability>(ComponentRef.hash, ComponentRef.isEqual));
          repetitions     := arrayCreate(size, UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual));
          // loop over each equation and copy the corresponding maps and sets
          for eqn_ptr in EquationPointers.toList(eqns) loop
            name        := Equation.getEqnName(eqn_ptr);
            index_new   := UnorderedMap.getSafe(name, eqns.map, sourceInfo());
            index_old   := UnorderedMap.getSafe(name, old_map, sourceInfo());
            // create structures for final matrix
            (old_start, old_size)     := adj.mapping.eqn_AtS[index_old];
            (new_start, new_size)     := mapping.eqn_AtS[index_new];
            if old_size == new_size then
              for i in 0:old_size-1 loop
                m[new_start+i] := adj.m[old_start+i];
              end for;
            else
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " sizes (old: " + intString(old_size) + ", new: "
                + intString(new_size) + " do not mach for equation:\n" + Equation.pointerToString(eqn_ptr)});
              fail();
            end if;
            // create the structures for full matrix
            equation_names[index_new] := name;
            occurences[index_new]     := full.occurences[index_old];
            dependencies[index_new]   := full.dependencies[index_old];
            solvabilities[index_new]  := full.solvabilities[index_old];
            repetitions[index_new]    := full.repetitions[index_old];
          end for;

          new_adj  := FINAL(m, transposeScalar(m, VariablePointers.scalarSize(vars, true)), mapping, adj.modes, adj.st);
          new_full := FULL(equation_names, occurences, dependencies, solvabilities, repetitions, mapping);
        then (new_adj, new_full);

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " expected types final and full, got types " + strictnessString(getStrictness(adj))
            + " and " + strictnessString(getStrictness(full)) + "."});
        then fail();
      end match;

      if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print(toString(adj, "Compressed Final") + "\n");
        print(toString(full, "Compressed Full") + "\n");
      end if;
    end compress;

    function toString
      input Matrix adj;
      input output String str = "";
    algorithm
      str := StringUtil.headline_2(str + "AdjacencyMatrix") + "\n";
      str := match adj
        local
          list<Type> types;
          array<String> names, types_str, complex_sizes;
          Integer length0, length1, length2;

        case FULL() algorithm
          types := list(ComponentRef.getSubscriptedType(name) for name in adj.equation_names);
          complex_sizes := listArray(list(Util.applyOptionOrDefault(Type.complexSize(ty, true), intString, "0") for ty in types));
          types_str := listArray(list(dimsString(Type.arrayDims(ty)) for ty in types));
          names := listArray(list(ComponentRef.toString(name) for name in adj.equation_names));
          length0 := max(stringLength(sz) for sz in complex_sizes);
          length1 := max(stringLength(ty) for ty in types_str) + 1;
          length2 := max(stringLength(name) for name in names) + 3;
          for i in 1:arrayLength(names) loop
            str := str
              + arrayGet(complex_sizes, i) + " " + StringUtil.repeat(" ", length0 - stringLength(arrayGet(complex_sizes, i))) + " | "
              + arrayGet(types_str, i) + " " + StringUtil.repeat(".", length1 - stringLength(arrayGet(types_str, i)))
              + arrayGet(names, i) + " " + StringUtil.repeat(".", length2 - stringLength(arrayGet(names, i)))
              + " " + List.toString(UnorderedSet.toList(adj.occurences[i]), function fullString(dep_map = adj.dependencies[i],
              sol_map = adj.solvabilities[i], rep_set = adj.repetitions[i])) + "\n";
          end for;
        then str;

        case FINAL() algorithm
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

        case EMPTY() then str + StringUtil.headline_4("Empty Adjacency Matrix") + "\n";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end toString;

    function solvabilityString
      input Matrix adj;
      input output String str = "";
    algorithm
      str := match adj
        local
          list<ComponentRef> XX, II, NM, NP, LV, LP, LC, QQ;
          list<String> xx = {}, ii = {}, nm = {}, np = {}, lv = {}, lp = {}, lc = {}, qq = {};
          array<String> names, types, XX_, II_, NM_, NP_, LV_, LP_, LC_, QQ_;
          Integer length1, length2, length_xx, length_ii, length_nm, length_np, length_lv, length_lp, length_lc, length_qq;

        case FULL() algorithm
          str := StringUtil.headline_2(str + " Solvability Adjacency Matrix") + "\n";
          types := listArray(list(intString(Type.sizeOf(ComponentRef.getSubscriptedType(name), true)) for name in adj.equation_names));
          names := listArray(list(ComponentRef.toString(name) for name in adj.equation_names));
          for i in arrayLength(names):-1:1 loop
            (XX, II, NM, NP, LV, LP, LC, QQ) := Solvability.categorize(UnorderedSet.toList(adj.occurences[i]), adj.solvabilities[i]);
            xx := List.toString(XX, ComponentRef.toString, "XX ", "{", ",", "}", false) :: xx;
            ii := List.toString(II, ComponentRef.toString, "II ", "{", ",", "}", false) :: ii;
            nm := List.toString(NM, ComponentRef.toString, "N- ", "{", ",", "}", false) :: nm;
            np := List.toString(NP, ComponentRef.toString, "N+ ", "{", ",", "}", false) :: np;
            lv := List.toString(LV, ComponentRef.toString, "LV ", "{", ",", "}", false) :: lv;
            lp := List.toString(LP, ComponentRef.toString, "LP ", "{", ",", "}", false) :: lp;
            lc := List.toString(LC, ComponentRef.toString, "LC ", "{", ",", "}", false) :: lc;
            qq := List.toString(QQ, ComponentRef.toString, "|| ", "{", ",", "}", false) :: qq;
          end for;
          XX_ := listArray(xx);
          II_ := listArray(ii);
          NM_ := listArray(nm);
          NP_ := listArray(np);
          LV_ := listArray(lv);
          LP_ := listArray(lp);
          LC_ := listArray(lc);
          QQ_ := listArray(qq);
          length1 := max(stringLength(ty) for ty in types) + 1;
          length2 := max(stringLength(name) for name in names) + 3;
          length_xx := max(stringLength(s) for s in XX_);
          length_ii := max(stringLength(s) for s in II_);
          length_nm := max(stringLength(s) for s in NM_);
          length_np := max(stringLength(s) for s in NP_);
          length_lv := max(stringLength(s) for s in LV_);
          length_lp := max(stringLength(s) for s in LP_);
          length_lc := max(stringLength(s) for s in LC_);
          length_qq := max(stringLength(s) for s in QQ_);
          for i in 1:arrayLength(names) loop
            str := str + arrayGet(types, i) + " " + StringUtil.repeat(".", length1 - stringLength(arrayGet(types, i))) + " "
              + arrayGet(names, i) + " " + StringUtil.repeat(".", length2 - stringLength(arrayGet(names, i)))
              + arrayGet(LC_, i) + " " + StringUtil.repeat(".", length_lc - stringLength(arrayGet(LC_, i)))
              + arrayGet(LP_, i) + " " + StringUtil.repeat(".", length_lp - stringLength(arrayGet(LP_, i)))
              + arrayGet(LV_, i) + " " + StringUtil.repeat(".", length_lv - stringLength(arrayGet(LV_, i)))
              + arrayGet(NP_, i) + " " + StringUtil.repeat(".", length_np - stringLength(arrayGet(NP_, i)))
              + arrayGet(NM_, i) + " " + StringUtil.repeat(".", length_nm - stringLength(arrayGet(NM_, i)))
              + arrayGet(II_, i) + " " + StringUtil.repeat(".", length_ii - stringLength(arrayGet(II_, i)))
              + arrayGet(XX_, i) + " " + StringUtil.repeat(".", length_xx - stringLength(arrayGet(XX_, i)))
              + arrayGet(QQ_, i) + " " + StringUtil.repeat(".", length_qq - stringLength(arrayGet(QQ_, i))) + "\n";
          end for;
        then str;
        else toString(adj, str);
      end match;
    end solvabilityString;

    function dependencyString
      input Matrix adj;
      input output String str = "";
    algorithm
      str := match adj
        local
          list<ComponentRef> F, R, E, A, S, K;
          list<String> f = {}, r = {}, e = {}, a = {}, s = {}, k = {};
          array<String> names, types, F_, R_, E_, A_, S_, K_;
          Integer length1, length2, lengthf, lengthr, lengthe, lengtha, lengths, lengthk;

        case FULL() algorithm
          str := StringUtil.headline_2(str + " Dependency Adjacency Matrix") + "\n";
          types := listArray(list(intString(Type.sizeOf(ComponentRef.getSubscriptedType(name), true)) for name in adj.equation_names));
          names := listArray(list(ComponentRef.toString(name) for name in adj.equation_names));
          for i in arrayLength(names):-1:1 loop
            (F, R, E, A, S, K) := Dependency.categorize(UnorderedSet.toList(adj.occurences[i]), adj.dependencies[i], adj.repetitions[i]);
            f := List.toString(F, ComponentRef.toString, "[!]", "{", ",", "}", false) :: f;
            r := List.toString(R, ComponentRef.toString, "[-]", "{", ",", "}", false) :: r;
            e := List.toString(E, ComponentRef.toString, "[+]", "{", ",", "}", false) :: e;
            a := List.toString(A, ComponentRef.toString, "[:]", "{", ",", "}", false) :: a;
            s := List.toString(S, ComponentRef.toString, "[.]", "{", ",", "}", false) :: s;
            k := List.toString(K, ComponentRef.toString, "[o]", "{", ",", "}", false) :: k;
          end for;
          F_ := listArray(f);
          R_ := listArray(r);
          E_ := listArray(e);
          A_ := listArray(a);
          S_ := listArray(s);
          K_ := listArray(k);
          length1 := max(stringLength(ty) for ty in types) + 1;
          length2 := max(stringLength(name) for name in names) + 3;
          lengthf := max(stringLength(st) for st in F_);
          lengthr := max(stringLength(st) for st in R_);
          lengthe := max(stringLength(st) for st in E_);
          lengtha := max(stringLength(st) for st in A_);
          lengths := max(stringLength(st) for st in S_);
          lengthk := max(stringLength(st) for st in K_);
          for i in 1:arrayLength(names) loop
            str := str + arrayGet(types, i) + " " + StringUtil.repeat(".", length1 - stringLength(arrayGet(types, i))) + " "
              + arrayGet(names, i) + " " + StringUtil.repeat(".", length2 - stringLength(arrayGet(names, i)))
              + arrayGet(K_, i) + " " + StringUtil.repeat(".", lengthk - stringLength(arrayGet(K_, i)))
              + arrayGet(S_, i) + " " + StringUtil.repeat(".", lengths - stringLength(arrayGet(S_, i)))
              + arrayGet(A_, i) + " " + StringUtil.repeat(".", lengtha - stringLength(arrayGet(A_, i)))
              + arrayGet(E_, i) + " " + StringUtil.repeat(".", lengthe - stringLength(arrayGet(E_, i)))
              + arrayGet(R_, i) + " " + StringUtil.repeat(".", lengthr - stringLength(arrayGet(R_, i)))
              + arrayGet(F_, i) + " " + StringUtil.repeat(".", lengthf - stringLength(arrayGet(F_, i))) + "\n";
          end for;
        then str;
        else toString(adj, str);
      end match;
    end dependencyString;

    function getStrictness
      input Matrix adj;
      output MatrixStrictness st;
    algorithm
      st := match adj
        case FULL() then MatrixStrictness.FULL;
        case FINAL() then adj.st;
        case EMPTY() then adj.st;
        else fail();
      end match;
    end getStrictness;

    function isEmpty
      input Matrix adj;
      output Boolean b;
    algorithm
      b := match adj
        case EMPTY() then true;
        else              false;
      end match;
    end isEmpty;

    function getMappingOpt
      input Matrix adj;
      output Option<Mapping> mapping;
    algorithm
      mapping := match adj
        case FULL()  then SOME(adj.mapping);
        case FINAL() then SOME(adj.mapping);
        else NONE();
      end match;
    end getMappingOpt;

    function nonZeroCount
      input Matrix adj;
      output Integer count;
    algorithm
      count := match adj
        case FINAL()  then BackendUtil.countElem(adj.m);
        case EMPTY()         then 0;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown matrix type."});
        then fail();
      end match;
    end nonZeroCount;

    function expandMatrix
      input output array<list<Integer>> m;
      input Integer shift;
    algorithm
      if shift > 0 then
        m := Array.expandToSize(arrayLength(m) + shift, m, {});
      end if;
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

    function toStringSingle
      input array<list<Integer>> m;
      output String str = "";
    protected
      Integer skip = stringLength(intString(arrayLength(m))) + 1;
      String tmp;
    algorithm
      for row in 1:arrayLength(m) loop
        tmp := intString(row);
        str := str + "\t(" + tmp + ")" + StringUtil.repeat(" ", skip - stringLength(tmp)) + List.toString(m[row], intString) + "\n";
      end for;
    end toStringSingle;

  protected
    function fullString
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, Dependency> dep_map;
      input UnorderedMap<ComponentRef, Solvability> sol_map;
      input UnorderedSet<ComponentRef> rep_set;
      output String str = ComponentRef.toString(cref) + "[";
    algorithm
      str := str + Solvability.toString(UnorderedMap.getSafe(cref, sol_map, sourceInfo()))
        + "|" + Dependency.toString(UnorderedMap.getSafe(cref, dep_map, sourceInfo()));
      if UnorderedSet.contains(cref, rep_set) then str := str + "+"; end if;
      str := str + "]";
    end fullString;

    function dimsString
      input list<Dimension> dims;
      output String str;
    algorithm
      str := match dims
        case {} then "{1}";
        else List.toString(list(Dimension.size(d, true) for d in dims), intString);
      end match;
    end dimsString;

    function initialize
      input Mapping mapping;
      input MatrixStrictness st;
      output Matrix adj;
    protected
      array<list<Integer>> m, mT;
      Integer eqn_scalar_size, var_scalar_size;
    algorithm
      eqn_scalar_size := arrayLength(mapping.eqn_StA);
      var_scalar_size := arrayLength(mapping.var_StA);
      if eqn_scalar_size > 0 or var_scalar_size > 0 then
        // create empty for-loop reconstruction information
        // create empty matrix and transposed matrix
        m := arrayCreate(eqn_scalar_size, {});
        mT := transposeScalar(m, var_scalar_size);
        // create record
        adj := FINAL(m, mT, mapping, UnorderedMap.new<Mode>(Mode.keyHash, Mode.keyEqual), st);
      else
        adj := EMPTY(st);
      end if;
    end initialize;

    function upgradeRow
      input Pointer<Equation> eqn_ptr;
      input Integer eqn_arr_idx;
      input list<ComponentRef> dependencies             "dependent var crefs";
      input UnorderedMap<ComponentRef, Dependency> dep  "dependency map";
      input UnorderedSet<ComponentRef> rep              "repetition set";
      input UnorderedMap<ComponentRef, Integer> map     "unordered map to check for relevance";
      input UnorderedMap<ComponentRef, Integer> fullmap "unordered map to check for general relevance";
      input array<list<Integer>> m;
      input Mapping mapping;
      input UnorderedMap<Mode.Key, Mode> modes;
      input Iterator iter_ = Iterator.EMPTY();
    protected
      Integer eqn_scal_idx, eqn_size;
      list<Integer> row;
      Equation eqn = Pointer.access(eqn_ptr);
      Iterator iter = Equation.getForIterator(eqn);
      Type ty = Equation.getType(eqn, true);
      list<ComponentRef> names;
      list<Expression> ranges;
      list<Option<Iterator>> maps;
    algorithm
      try
        // don't do this for if equations as soon as we properly split them
        if Equation.isAlgorithm(eqn_ptr) or Equation.isIfEquation(eqn_ptr) then
          // algorithm full dependency
          (eqn_scal_idx, eqn_size) := mapping.eqn_AtS[eqn_arr_idx];
          row := Slice.upgradeRowFull(dependencies, map, mapping);
          for i in 0:eqn_size-1 loop
            updateIntegerRow(m, eqn_scal_idx+i, row);
          end for;
        else
          // todo: if, when single equation (needs to be updated for if)

          // add the optional surrounding iterator frames
          if not Iterator.isEmpty(iter_) then
            (names, ranges, maps) := Iterator.getFrames(iter_);
            iter := Iterator.addFrames(iter, List.zip3(names, ranges, maps));
          end if;

          Slice.upgradeRow(Equation.getEqnName(eqn_ptr), eqn_arr_idx, iter, ty, dependencies, dep, rep, map, fullmap, m, mapping, modes);
        end if;
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed for:\n" + Equation.pointerToString(eqn_ptr)});
        fail();
      end try;
    end upgradeRow;

    function updateIntegerRow
      input array<list<Integer>> m;
      input Integer idx;
      input list<Integer> row;
    algorithm
      arrayUpdate(m, idx, listAppend(row, m[idx]));
      /*if Flags.isSet(Flags.BLT_MATRIX_DUMP) then
        print("Adding to row " + intString(idx) + " " + List.toString(row, intString) + "\n");
      end if;*/
    end updateIntegerRow;
  end Matrix;

  uniontype Dependency
    "the dependency kind to show how a component reference occurs in an equation.
    for each dimension there has to be one dependency kind."
    type Kind = enumeration(REGULAR, REDUCTION);

    record DEPENDENCY
      array<list<Integer>> skips;
      list<Dependency.Kind> kinds;
    end DEPENDENCY;

    function toString
      input Dependency dep;
      output String str;
    protected
      function kindString
        input Kind kind;
        output String str;
      algorithm
        str := match kind
          case Kind.REGULAR then ":";
                            else "-";
        end match;
      end kindString;
      String str1, str2;
    algorithm
      str1 := Array.toString(dep.skips, function List.toString(
        inPrintFunc   = intString,
        inNameStr     = "",
        inBeginStr    = "{",
        inDelimitStr  = ", ",
        inEndStr      = "}",
        inPrintEmpty  = false,
        maxLength     = 0), "", "", ", ", "");
      str2 := List.toString(dep.kinds, kindString, "", "", ", ", "");
      str := if str1 == "" or str2 == "" then str1 + str2 else str1 + ", " + str2;
      str := "{" + str + "}";
    end toString;

    function toBoolean
      "converts the regular/reduction part of the dependency to a boolean list for scalarization"
      input Dependency dep;
      output list<Boolean> b = list(not isReductionKind(k) for k in dep.kinds);
    end toBoolean;

    function create
      input Type sub_ty;
      input Integer depth;
      output Dependency dep;
    algorithm
      dep := DEPENDENCY(arrayCreate(depth, {}), list(Kind.REGULAR for dim guard(not Dimension.isOne(dim)) in Type.arrayDims(sub_ty)));
    end create;

    function update
      "sets the dependency of num dimensions
      REGULAR -> REDUCTION"
      input ComponentRef cref;
      input Integer num     "number of dependencies to turn to reductions. negative means all";
      input Boolean reverse "true = from right, false = from left";
      input UnorderedMap<ComponentRef, Dependency> map;
    protected
      Option<Dependency> opt_dep = UnorderedMap.get(cref, map);
      Dependency dep;
      function makeNewKinds
        input output list<Kind> kinds;
        input Integer num;
      algorithm
        kinds := match (kinds, num)
          local
            list<Kind> rest;
          case (_, 0) then kinds;
          case (_::rest, _) then Kind.REDUCTION :: makeNewKinds(rest, num-1);
          else kinds;
        end match;
      end makeNewKinds;
    algorithm
      if Util.isSome(opt_dep) then
        SOME(dep) := opt_dep;
        if reverse then
          dep.kinds := listReverse(makeNewKinds(listReverse(dep.kinds), num));
        else
          dep.kinds := makeNewKinds(dep.kinds, num);
        end if;
        UnorderedMap.add(cref, dep, map);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because cref "
         + ComponentRef.toString(cref) + " was not found in the map."});
        fail();
      end if;
    end update;

    function skip
      input ComponentRef cref;
      input Integer depth;
      input Integer sk;
      input UnorderedMap<ComponentRef, Dependency> map;
    protected
      Option<Dependency> opt_dep = UnorderedMap.get(cref, map);
      Dependency dep;
    algorithm
      if Util.isSome(opt_dep) then
        SOME(dep) := opt_dep;
        if arrayLength(dep.skips) >= depth then
          // this might scale badly, try to unique the lists in the end or always use sets here
          arrayUpdate(dep.skips, depth, UnorderedSet.unique_list(sk :: dep.skips[depth], Util.id, intEq));
        else
          if Flags.isSet(Flags.FAILTRACE) then
            Error.addCompilerWarning(getInstanceName() + ": Cref " + ComponentRef.toString(cref)
            + " was saved with depth " + intString(arrayLength(dep.skips)) + " but depth " + intString(depth) + " was requested.");
          end if;
        end if;

        UnorderedMap.add(cref, dep, map);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because cref "
         + ComponentRef.toString(cref) + " was not found in the map."});
        fail();
      end if;
    end skip;

    function removeSkips
      input ComponentRef cref;
      input UnorderedMap<ComponentRef, Dependency> map;
    protected
      Option<Dependency> opt_dep = UnorderedMap.get(cref, map);
      Dependency dep;
    algorithm
      if Util.isSome(opt_dep) then
        SOME(dep) := opt_dep;
        for i in 1:arrayLength(dep.skips) loop
          arrayUpdate(dep.skips, i, {});
        end for;
        UnorderedMap.add(cref, dep, map);
      else
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because cref "
         + ComponentRef.toString(cref) + " was not found in the map."});
        fail();
      end if;
    end removeSkips;

    function updateList
      input list<ComponentRef> lst;
      input Integer num;
      input Boolean reverse;
      input UnorderedMap<ComponentRef, Dependency> map;
    algorithm
      for cref in lst loop
        update(cref, num, reverse, map);
      end for;
    end updateList;

    function skipList
      input list<ComponentRef> lst;
      input Integer depth;
      input Integer sk;
      input UnorderedMap<ComponentRef, Dependency> map;
    algorithm
      for cref in lst loop
        skip(cref, depth, sk, map);
      end for;
    end skipList;

    function removeSkipsList
      input list<ComponentRef> lst;
      input UnorderedMap<ComponentRef, Dependency> map;
    algorithm
      for cref in lst loop
        removeSkips(cref, map);
      end for;
    end removeSkipsList;

    function addListFull
      "adds a list and applies full dependency"
      input list<ComponentRef> lst;
      input Integer depth;
      input UnorderedMap<ComponentRef, Dependency> map;
      input UnorderedSet<ComponentRef> rep;
    protected
      Dependency dep;
    algorithm
      for cref in lst loop
        UnorderedMap.add(cref, create(ComponentRef.getSubscriptedType(cref), depth), map);
        UnorderedSet.add(cref, rep);
      end for;
      updateList(lst, -1, false, map);
    end addListFull;

    function isReductionKind
      input Dependency.Kind kind;
      output Boolean b = kind == Kind.REDUCTION;
    end isReductionKind;

    function categorize
      input list<ComponentRef> crefs;
      input UnorderedMap<ComponentRef, Dependency> map;
      input UnorderedSet<ComponentRef> rep_set;
      output list<ComponentRef> F = {};
      output list<ComponentRef> R = {};
      output list<ComponentRef> E = {};
      output list<ComponentRef> A = {};
      output list<ComponentRef> S = {};
      output list<ComponentRef> K = {};
    protected
      Boolean repeats;
    algorithm
      for cref in crefs loop
        repeats := UnorderedSet.contains(cref, rep_set);
        _ := match UnorderedMap.getSafe(cref, map, sourceInfo())
          local
            array<list<Integer>> skips;
            list<Kind> kinds;
          case DEPENDENCY(skips = skips) guard(not Array.all(skips, listEmpty))
            algorithm K := cref :: K; then ();
          case DEPENDENCY(kinds = {}) guard(repeats)
            algorithm E := cref :: E; then ();
          case DEPENDENCY(kinds = {})
            algorithm S := cref :: S; then ();
          case DEPENDENCY(kinds = kinds) algorithm
            if List.any(kinds, isReductionKind) then
              if repeats then
                F := cref :: F;
              else
                R := cref :: R;
              end if;
            else
              A := cref :: A;
            end if;
          then ();
          else ();
        end match;
      end for;
    end categorize;
  end Dependency;

  uniontype Solvability
    record UNKNOWN end UNKNOWN; // do not set, only used as default if unset
    record UNSOLVABLE end UNSOLVABLE;
    record IMPLICIT end IMPLICIT;

    record EXPLICIT_NONLINEAR
      Boolean unique "true if it has a unique solution when solved";
    end EXPLICIT_NONLINEAR;

    record EXPLICIT_LINEAR
      Option<UnorderedSet<ComponentRef>> pars "parameters we need to divide by to solve";
      Option<UnorderedSet<ComponentRef>> vars "variables we need to divide by to solve";
    end EXPLICIT_LINEAR;

    function toString
      input Solvability sol;
      output String str;
    algorithm
      str := match sol
        case UNSOLVABLE()         then "XX";
        case IMPLICIT()           then "II";
        case EXPLICIT_NONLINEAR() then "N" + (if sol.unique then "+" else "-");
        case EXPLICIT_LINEAR()    then "L" + (if Util.isSome(sol.vars) then "V" elseif Util.isSome(sol.pars) then "P" else "C");
        case UNKNOWN()            then "||";
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown solvability kind."});
        then fail();
      end match;
    end toString;

    function rank
      input Solvability sol;
      output Integer r;
    algorithm
      r := match sol
        case UNSOLVABLE()                         then 7;
        case IMPLICIT()                           then 6;
        case EXPLICIT_NONLINEAR(unique = false)   then 5;
        case EXPLICIT_NONLINEAR()                 then 4;
        case EXPLICIT_LINEAR(vars = SOME(_))      then 3;
        case EXPLICIT_LINEAR(pars = SOME(_))      then 2;
        case EXPLICIT_LINEAR()                    then 1;
        case UNKNOWN()                            then 0;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown solvability kind."});
        then fail();
      end match;
    end rank;

    function update
      "sets the solvability of a component reference if it is of
      higher rank than previously determined"
      input ComponentRef cref;
      input Solvability sol;
      input UnorderedMap<ComponentRef, Solvability> map;
    algorithm
      if rank(sol) > rank(Util.getOptionOrDefault(UnorderedMap.get(cref, map), UNKNOWN())) then
        UnorderedMap.add(cref, sol, map);
      end if;
    end update;

    function updateList
      input list<ComponentRef> lst;
      input Solvability sol;
      input UnorderedMap<ComponentRef, Solvability> map;
    algorithm
      for cref in lst loop
        Solvability.update(cref, sol, map);
      end for;
    end updateList;

    function categorize
      input list<ComponentRef> crefs;
      input UnorderedMap<ComponentRef, Solvability> map;
      output list<ComponentRef> XX = {};
      output list<ComponentRef> II = {};
      output list<ComponentRef> NM = {};
      output list<ComponentRef> NP = {};
      output list<ComponentRef> LV = {};
      output list<ComponentRef> LP = {};
      output list<ComponentRef> LC = {};
      output list<ComponentRef> QQ = {};
    algorithm
      for cref in crefs loop
        _ := match UnorderedMap.getSafe(cref, map, sourceInfo())
          case UNSOLVABLE()                       algorithm XX := cref :: XX; then();
          case IMPLICIT()                         algorithm II := cref :: II; then();
          case EXPLICIT_NONLINEAR(unique = false) algorithm NM := cref :: NM; then();
          case EXPLICIT_NONLINEAR()               algorithm NP := cref :: NP; then();
          case EXPLICIT_LINEAR(vars = SOME(_))    algorithm LV := cref :: LV; then();
          case EXPLICIT_LINEAR(pars = SOME(_))    algorithm LP := cref :: LP; then();
          case EXPLICIT_LINEAR()                  algorithm LC := cref :: LC; then();
          else                                    algorithm QQ := cref :: QQ; then();
        end match;
      end for;
    end categorize;

    function filter
      "filters the cref list for all relevant crefs (checked with the rel map)
      and with solvability ranking between (and including) min and max"
      input list<ComponentRef> all_occ;
      input UnorderedMap<ComponentRef, Solvability> map;
      input UnorderedMap<ComponentRef, Integer> rel       "check for relevance";
      input Integer min;
      input Integer max;
      output list<ComponentRef> occ = {};
    protected
      Integer r;
    algorithm
      for cref in all_occ loop
        if UnorderedMap.contains(cref, rel) then
          r := rank(UnorderedMap.getSafe(cref, map, sourceInfo()));
          if r >= min and r <= max then
            occ := cref :: occ;
          end if;
        end if;
      end for;
    end filter;

    function fromStrictness
      input MatrixStrictness st;
      output Solvability sol;
    algorithm
      sol := match st
        case MatrixStrictness.LINEAR    then EXPLICIT_LINEAR(NONE(), SOME(UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual)));
        case MatrixStrictness.MATCHING  then IMPLICIT();
        case MatrixStrictness.SORTING   then UNSOLVABLE();
        else                                 UNKNOWN();
      end match;
    end fromStrictness;

    function isNonlinearOrImplicit
      input Solvability sol;
      output Boolean b;
    algorithm
      b := match sol
        case EXPLICIT_NONLINEAR() then true;
        case IMPLICIT()           then true;
        else false;
      end match;
    end isNonlinearOrImplicit;
  end Solvability;

  function collectDependenciesEquation
    "collects all relevant component references from an equation
    furthermore it collects additional data about dependency and solvability."
    input Equation eqn;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output UnorderedSet<ComponentRef> occurences;
  protected
    list<ComponentRef> inputs, outputs;
  algorithm
    occurences := match eqn
      local
        UnorderedSet<ComponentRef> occ1, occ2;
        Equation body;
        Slice.filterCref filter;

      case Equation.SCALAR_EQUATION() algorithm
        occ1 := collectDependencies(eqn.lhs, 0, map, dep_map, sol_map, rep_set);
        occ2 := collectDependencies(eqn.rhs, 0, map, dep_map, sol_map, rep_set);
      then UnorderedSet.union(occ1, occ2);

      case Equation.ARRAY_EQUATION() algorithm
        occ1 := collectDependencies(eqn.lhs, 0, map, dep_map, sol_map, rep_set);
        occ2 := collectDependencies(eqn.rhs, 0, map, dep_map, sol_map, rep_set);
      then UnorderedSet.union(occ1, occ2);

      case Equation.RECORD_EQUATION() algorithm
        occ1 := collectDependencies(eqn.lhs, 0, map, dep_map, sol_map, rep_set);
        occ2 := collectDependencies(eqn.rhs, 0, map, dep_map, sol_map, rep_set);
      then UnorderedSet.union(occ1, occ2);

      case Equation.ALGORITHM() algorithm
        // collect all crefs expanding potential records
        inputs  := List.flatten(list(collectDependenciesCref(c, 0, map, dep_map, sol_map) for c in eqn.alg.inputs));
        outputs := List.flatten(list(collectDependenciesCref(c, 0, map, dep_map, sol_map) for c in eqn.alg.outputs));
        // create dependencies for inputs and outputs
        Dependency.addListFull(inputs, 0, dep_map, rep_set);
        Dependency.addListFull(outputs, 0, dep_map, rep_set);
        // make inputs unsolvable and outputs solvable (maybe check if algorithm can be reversed)
        Solvability.updateList(inputs, Solvability.IMPLICIT(), sol_map);
        Solvability.updateList(outputs, Solvability.EXPLICIT_LINEAR(NONE(), NONE()), sol_map);
      then UnorderedSet.fromList(listAppend(inputs, outputs), ComponentRef.hash, ComponentRef.isEqual);

      case Equation.FOR_EQUATION(body = {body}) algorithm
        // gather solvables from body
        occ1 := collectDependenciesEquation(body, map, dep_map, sol_map, rep_set);
        // gather unsolvables from iterator
        occ2 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        filter := function Slice.getDependentCref(map = map, pseudo = true);
        _ := Iterator.map(eqn.iter, function Slice.Slice.filterExp(filter = filter, acc = occ2),
          SOME(function filter(acc = occ2)), Expression.mapShallow);
        // update unsolvables
        Solvability.updateList(UnorderedSet.toList(occ2), Solvability.UNSOLVABLE(), sol_map);
      then UnorderedSet.union(occ1, occ2);

      case Equation.IF_EQUATION()
      then collectDependenciesIf(eqn.body, map, dep_map, sol_map, rep_set);

      case Equation.WHEN_EQUATION()
      then collectDependenciesWhen(eqn.body, map, dep_map, sol_map, rep_set);

      else UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    end match;
  end collectDependenciesEquation;

  function collectDependencies
    "collects all relevant component references from an expression
    furthermore it collects additional data about dependency and solvability."
    input Expression exp;
    input Integer depth;
    input UnorderedMap<ComponentRef, Integer> map "unknowns map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output UnorderedSet<ComponentRef> set;
  algorithm
    set := match exp
      local
        Dependency dep;
        UnorderedSet<ComponentRef> set1, set2, diff;
        list<UnorderedSet<ComponentRef>> sets = {};
        Expression call_exp;
        Call call;
        Boolean repeatLeft, repeatRight, reduce;
        Integer ind, new_depth;
        Boolean isTuple;

      // add a cref dependency
      case Expression.CREF() then UnorderedSet.fromList(collectDependenciesCref(exp.cref, depth, map, dep_map, sol_map), ComponentRef.hash, ComponentRef.isEqual);

      // add skips for arrays
      case Expression.ARRAY(literal = false) algorithm
        for i in 1:arrayLength(exp.elements) loop
          set1 := collectDependencies(exp.elements[i], depth + 1, map, dep_map, sol_map, rep_set);
          Dependency.skipList(UnorderedSet.toList(set1), depth + 1, i, dep_map);
          sets := set1 :: sets;
        end for;
      then UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);

      // add skips for tuples
      case Expression.TUPLE() algorithm
        ind := 1;
        for elem in exp.elements loop
          set1 := collectDependencies(elem, depth + 1, map, dep_map, sol_map, rep_set);
          Dependency.skipList(UnorderedSet.toList(set1), depth + 1, ind, dep_map);
          sets := set1 :: sets;
          ind := ind + 1;
        end for;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
      then set;

      // reduce the dependency and remove skips for these
      case Expression.SUBSCRIPTED_EXP() algorithm
        set := collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
        Dependency.updateList(UnorderedSet.toList(set), listLength(exp.subscripts), true, dep_map);
        Dependency.removeSkipsList(UnorderedSet.toList(set), dep_map);
      then set;

      // should not change anything
      case Expression.TUPLE_ELEMENT()   then collectDependencies(exp.tupleExp, depth, map, dep_map, sol_map, rep_set);
      case Expression.RECORD_ELEMENT()  then collectDependencies(exp.recordExp, depth, map, dep_map, sol_map, rep_set);

      case Expression.BINARY() algorithm
        set1  := collectDependencies(exp.exp1, depth, map, dep_map, sol_map, rep_set);
        set2  := collectDependencies(exp.exp2, depth, map, dep_map, sol_map, rep_set);
        // add repetitions if needed (.+, .*)
        (repeatLeft, repeatRight) := Operator.repetition(exp.operator);
        if repeatLeft then addRepetitions(set1, rep_set); end if;
        if repeatRight then addRepetitions(set2, rep_set); end if;
        // add reductions if needed
        reduce := Operator.reduction(exp.operator);
        if reduce then
          Dependency.updateList(UnorderedSet.toList(set1), 1, true, dep_map);
          Dependency.updateList(UnorderedSet.toList(set2), 1, false, dep_map);
        end if;
      then UnorderedSet.union(set1, set2);

      // mostly equal to binary
      case Expression.MULTARY() algorithm
        // add repetitions if needed (.+, .*)
        (repeatLeft, repeatRight) := Operator.repetition(exp.operator);
        repeatLeft := repeatLeft or repeatRight;
        // traverse arguments
        for arg in exp.arguments loop
          set1 := collectDependencies(arg, depth, map, dep_map, sol_map, rep_set);
          // add repetitions if needed
          addRepetitionsCond(set1, arg, repeatLeft, rep_set);
          sets := set1 :: sets;
        end for;
        // traverse inverse arguments
        for arg in exp.inv_arguments loop
          set2 := collectDependencies(arg, depth, map, dep_map, sol_map, rep_set);
          // add repetitions if needed
          addRepetitionsCond(set2, arg, repeatLeft, rep_set);
          sets := set2 :: sets;
        end for;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
      then set;

      // cannot solve from lbinary
      case Expression.LBINARY() algorithm
        set1  := collectDependencies(exp.exp1, depth, map, dep_map, sol_map, rep_set);
        set2  := collectDependencies(exp.exp2, depth, map, dep_map, sol_map, rep_set);
        set   := UnorderedSet.union(set1, set2);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.UNSOLVABLE(), sol_map);
      then set;

      // cannot solve from relation
      case Expression.RELATION() algorithm
        set1  := collectDependencies(exp.exp1, depth, map, dep_map, sol_map, rep_set);
        set2  := collectDependencies(exp.exp2, depth, map, dep_map, sol_map, rep_set);
        set   := UnorderedSet.union(set1, set2);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.UNSOLVABLE(), sol_map);
      then set;

      // these don't really change anything, just pass on the argument
      case Expression.CAST()    then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.BOX()     then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.UNBOX()   then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.UNARY()   then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.LUNARY()  then collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
      case Expression.MUTABLE() then collectDependencies(Mutable.access(exp.exp), depth, map, dep_map, sol_map, rep_set);

      // in the size() operator nothing is solvable
      case Expression.SIZE() algorithm
        set  := collectDependencies(exp.exp, depth, map, dep_map, sol_map, rep_set);
        if Util.isSome(exp.dimIndex) then
          set2  := collectDependencies(Util.getOption(exp.dimIndex), depth, map, dep_map, sol_map, rep_set);
          set := UnorderedSet.union(set, set2);
        end if;
        Solvability.updateList(UnorderedSet.toList(set), Solvability.UNSOLVABLE(), sol_map);
      then set;

      // variables in conditions are unsolvable and variables not occuring in both branches are implicit
      case Expression.IF() algorithm
        set1  := collectDependencies(exp.trueBranch, depth, map, dep_map, sol_map, rep_set);
        set2  := collectDependencies(exp.falseBranch, depth, map, dep_map, sol_map, rep_set);
        // variables not occuring in both branches will be tagged implicit
        diff  := UnorderedSet.sym_difference(set1, set2);
        Solvability.updateList(UnorderedSet.toList(diff), Solvability.IMPLICIT(), sol_map);
        // variables in conditions are unsolvable, their skips have to be removed and they can be repeated
        set   := collectDependencies(exp.condition, depth, map, dep_map, sol_map, rep_set);
        addRepetitions(set, rep_set);
        updateConditionCrefs(UnorderedSet.toList(set), dep_map, sol_map);
      then UnorderedSet.union_list({set, set1, set2}, ComponentRef.hash, ComponentRef.isEqual);

      // for array constructors replace all iterators (temporarily)
      case Expression.CALL(call = call as Call.TYPED_ARRAY_CONSTRUCTOR(exp = call_exp)) algorithm
        for iter in call.iters loop
          call_exp := Expression.replaceIterator(call_exp, Util.tuple21(iter), Util.tuple22(iter));
        end for;
        // if these are not simplified before this step, they can only be solved implicitely
        set := collectDependencies(call_exp, depth, map, dep_map, sol_map, rep_set);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.IMPLICIT(), sol_map);
      then set;

      // for reductions set the dependency to full reduction
      case Expression.CALL(call = call as Call.TYPED_REDUCTION(exp = call_exp)) algorithm
        for iter in call.iters loop
          call_exp := Expression.replaceIterator(call_exp, Util.tuple21(iter), Util.tuple22(iter));
        end for;
        set := collectDependencies(call_exp, depth, map, dep_map, sol_map, rep_set);
        Dependency.updateList(UnorderedSet.toList(set), -1, false, dep_map);
      then set;

      // for functions set the dependency to full reduction (+ repetition) and solvability to implicit
      case Expression.CALL(call = call as Call.TYPED_CALL()) algorithm
        // add depth if return type is tuple
        isTuple := Type.isTuple(call.ty);
        new_depth := if isTuple then depth + 1 else depth;
        for arg in call.arguments loop
          sets := collectDependencies(arg, new_depth, map, dep_map, sol_map, rep_set) :: sets;
        end for;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
        Dependency.updateList(UnorderedSet.toList(set), -1, false, dep_map);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.IMPLICIT(), sol_map);
        addRepetitions(set, rep_set);
        // if the return type has to be skipped - add empty skip
        if isTuple then
          Dependency.skipList(UnorderedSet.toList(set), depth + 1, 0, dep_map);
        end if;
      then set;

      // for not inlined record constructors set the dependency to full reduction (+ repetition) and solvability to implicit
      case Expression.RECORD() algorithm
        for arg in exp.elements loop
          sets := collectDependencies(arg, depth, map, dep_map, sol_map, rep_set) :: sets;
        end for;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
        Dependency.updateList(UnorderedSet.toList(set), -1, false, dep_map);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.IMPLICIT(), sol_map);
        addRepetitions(set, rep_set);
      then set;

      // nothing is solvable from ranges
      case Expression.RANGE() algorithm
        sets := collectDependencies(exp.start, depth, map, dep_map, sol_map, rep_set) :: sets;
        if Util.isSome(exp.step) then
          sets := collectDependencies(Util.getOption(exp.step), depth, map, dep_map, sol_map, rep_set) :: sets;
        end if;
        sets := collectDependencies(exp.stop, depth, map, dep_map, sol_map, rep_set) :: sets;
        set := UnorderedSet.union_list(sets, ComponentRef.hash, ComponentRef.isEqual);
        Solvability.updateList(UnorderedSet.toList(set), Solvability.UNSOLVABLE(), sol_map);
      then set;

      else UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
    end match;
  end collectDependencies;

  function collectDependenciesCref
    input ComponentRef cref;
    input Integer depth;
    input UnorderedMap<ComponentRef, Integer> map "unknowns map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    output list<ComponentRef> crefs;
  protected
    Pointer<Variable> var;
    Integer sk = 1;
    list<Subscript> subs;
  algorithm
    if UnorderedMap.contains(cref, map) then
      if not UnorderedMap.contains(cref, dep_map) then
        UnorderedMap.add(cref, Dependency.create(ComponentRef.getSubscriptedType(cref), depth), dep_map);
      end if;
      Solvability.update(cref, Solvability.EXPLICIT_LINEAR(NONE(), NONE()), sol_map);
      crefs := {cref};
    else
      var := BVariable.getVarPointer(cref, sourceInfo());
      if BVariable.isRecord(var) then
        subs := ComponentRef.subscriptsAllFlat(cref);
        // get all Record children
        crefs := list(BVariable.getVarName(child) for child in BVariable.getRecordChildren(var));
        // add original subscripts
        crefs := list(ComponentRef.mergeSubscripts(subs, child) for child in crefs);
        // collect dependencies
        crefs := List.flatten(list(collectDependenciesCref(child, depth + 1, map, dep_map, sol_map) for child in crefs));
        for cref in crefs loop
          Dependency.skip(cref, depth + 1, sk, dep_map);
          sk := sk + 1;
        end for;
      else
        crefs := {};
      end if;
    end if;
  end collectDependenciesCref;

  function addRepetitionsCond
    "adds component references from a set to the repetition set,
    only if the expression they appear in is of size 1"
    input UnorderedSet<ComponentRef> occ;
    input Expression exp;
    input Boolean isRep;
    input UnorderedSet<ComponentRef> rep_set;
  algorithm
    if isRep and Type.sizeOf(Expression.typeOf(exp)) == 1 then
      addRepetitions(occ, rep_set);
    end if;
  end addRepetitionsCond;

  function addRepetitions
    "adds component references to the repetition set"
    input UnorderedSet<ComponentRef> occ;
    input UnorderedSet<ComponentRef> rep_set;
  algorithm
    for cref in UnorderedSet.toList(occ) loop
      UnorderedSet.add(cref, rep_set);
    end for;
  end addRepetitions;

  function collectDependenciesIf
    "collects all relevant component references from an if equation body
    furthermore it collects additional data about dependency and solvability.
    variables in conditions and variables not contained in all branches are unsolvable"
    input IfEquationBody body;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output UnorderedSet<ComponentRef> set;
  protected
    list<UnorderedSet<ComponentRef>> sets1 = {};
    UnorderedSet<ComponentRef> set1, set2, diff;
  algorithm
    // variables in conditions are unsolvable, repeated and get their skips removed
    set := collectDependencies(body.condition, 0, map, dep_map, sol_map, rep_set);
    addRepetitions(set, rep_set);
    updateConditionCrefs(UnorderedSet.toList(set), dep_map, sol_map);

    // get variables from 'then' branch
    for eqn in body.then_eqns loop
      sets1  := collectDependenciesEquation(Pointer.access(eqn), map, dep_map, sol_map, rep_set) :: sets1;
    end for;

    // if there is an 'else' branch, mark those not occuring in both as implicit (maybe it should be unsolvable?)
    if Util.isSome(body.else_if) then
      set1 := UnorderedSet.union_list(sets1, ComponentRef.hash, ComponentRef.isEqual);
      set2 := collectDependenciesIf(Util.getOption(body.else_if), map, dep_map, sol_map, rep_set);
      diff  := UnorderedSet.sym_difference(set1, set2);
      Solvability.updateList(UnorderedSet.toList(diff), Solvability.IMPLICIT(), sol_map);
      set := UnorderedSet.union_list({set, set1, set2}, ComponentRef.hash, ComponentRef.isEqual);
    else
      set := UnorderedSet.union_list(set :: sets1, ComponentRef.hash, ComponentRef.isEqual);
    end if;
  end collectDependenciesIf;

  function collectDependenciesWhen
    "collects all relevant component references from a when equation body
    furthermore it collects additional data about dependency and solvability.
    variables assigned on the left hand side are solvable,
    variables from the right hand side (-lhs variables) are unsolvable"
    input WhenEquationBody body;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output UnorderedSet<ComponentRef> set;
  protected
    UnorderedSet<ComponentRef> set1 "solvables";
    UnorderedSet<ComponentRef> set2 "potentially unsolvables";
    UnorderedSet<ComponentRef> diff "set2 / set1 unsolvables";
    list<UnorderedSet<ComponentRef>> lst = {}, lst1, lst2;
    list<tuple<UnorderedSet<ComponentRef>, UnorderedSet<ComponentRef>>> tpl_lst = {};
  algorithm
    // variables in conditions are unsolvable, reduced and get their skips removed
    set := collectDependencies(body.condition, 0, map, dep_map, sol_map, rep_set);
    updateConditionCrefs(UnorderedSet.toList(set), dep_map, sol_map);

    // make condition repeat if the body is larger than 1
    if sum(WhenStatement.size(stmt, true) for stmt in body.when_stmts) > 1 then
      addRepetitions(set, rep_set);
    end if;

    // collect all dependencies from the statments
    for stmt in body.when_stmts loop
      tpl_lst := collectDependenciesStmt(stmt, map, dep_map, sol_map, rep_set) :: tpl_lst;
    end for;

    // create the two sets for solvables and potentially unsovables
    (lst1, lst2) := List.unzip(tpl_lst);
    set1 := UnorderedSet.union_list(lst1, ComponentRef.hash, ComponentRef.isEqual);
    set2 := UnorderedSet.union_list(lst2, ComponentRef.hash, ComponentRef.isEqual);

    // get the set difference to determine the unsolvables and tag them as such
    diff := UnorderedSet.difference(set2, set1);
    Solvability.updateList(UnorderedSet.toList(diff), Solvability.UNSOLVABLE(), sol_map);

    // traverse else when if it exists
    if Util.isSome(body.else_when) then
      lst := collectDependenciesWhen(Util.getOption(body.else_when), map, dep_map, sol_map, rep_set) :: lst;
    end if;
    set := UnorderedSet.union_list(set :: set1 :: set2 :: lst, ComponentRef.hash, ComponentRef.isEqual);
  end collectDependenciesWhen;

  function collectDependenciesStmt
    "collects all relevant component references from a when statement
    furthermore it collects additional data about dependency and solvability.
    Returns a tuple of two sets, one containing the solvables and the other
    containing potentially unsolvables"
    input WhenStatement stmt;
    input UnorderedMap<ComponentRef, Integer> map "unordered map to check for relevance";
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
    input UnorderedSet<ComponentRef> rep_set;
    output tuple<UnorderedSet<ComponentRef>, UnorderedSet<ComponentRef>> set_tpl;
  protected
    UnorderedSet<ComponentRef> set1 "solvable";
    UnorderedSet<ComponentRef> set2 "potentially unsolvable";
  algorithm
    set_tpl := match stmt
      case WhenStatement.ASSIGN() algorithm
        set1 := collectDependencies(stmt.lhs, 0, map, dep_map, sol_map, rep_set);
        set2 := collectDependencies(stmt.rhs, 0, map, dep_map, sol_map, rep_set);
      then (set1, set2);

      case WhenStatement.REINIT() algorithm
        set1 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        set2 := collectDependencies(stmt.value, 0, map, dep_map, sol_map, rep_set);
      then (set1, set2);

      case WhenStatement.ASSERT() algorithm
        set1 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        set2 := collectDependencies(stmt.condition, 0, map, dep_map, sol_map, rep_set);
        updateConditionCrefs(UnorderedSet.toList(set2), dep_map, sol_map);
      then (set1, set2);

      else algorithm
        set1 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
        set2 := UnorderedSet.new(ComponentRef.hash, ComponentRef.isEqual);
      then (set1, set2);
    end match;
  end collectDependenciesStmt;

  function updateConditionCrefs
    "variables in conditions are unsolvable, reduced and get their skips removed"
    input list<ComponentRef> crefs;
    input UnorderedMap<ComponentRef, Dependency> dep_map;
    input UnorderedMap<ComponentRef, Solvability> sol_map;
  algorithm
    Dependency.removeSkipsList(crefs, dep_map);
    Dependency.updateList(crefs, -1, false, dep_map);
    Solvability.updateList(crefs, Solvability.UNSOLVABLE(), sol_map);
  end updateConditionCrefs;

  annotation(__OpenModelica_Interface="backend");
end NBAdjacency;

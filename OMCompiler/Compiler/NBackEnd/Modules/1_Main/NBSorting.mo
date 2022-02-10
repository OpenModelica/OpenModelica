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
encapsulated package NBSorting
"file:        NBSorting.mo
 package:     NBSorting
 description: This file contains the functions which perform the sorting process;
"

public
  import StrongComponent = NBStrongComponent;

protected
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers};
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;
  import Adjacency = NBAdjacency;
  import Matching = NBMatching;

  import ComponentRef = NFComponentRef;
  import NFFlatten.FunctionTree;

public
  // ############################################################
  //                Pseudo Bucket Structures
  // ############################################################

  uniontype PseudoBucketKey
    record PSEUDO_BUCKET_KEY
      Integer eqn_start_idx "first scalar equation appearing in the strong components";
      Integer eqn_arr_idx   "array index of equation";
      Integer mode          "solve mode index";
    end PSEUDO_BUCKET_KEY;

    function hash
      input PseudoBucketKey key   "the key to hash";
      input Integer modulo        "modulo value";
      input Integer shift         "has to be statically provided while creating the PseudoBucket.";
      output Integer val          "the hash value";
    algorithm
      val := mod(key.mode*shift*shift + key.eqn_arr_idx*shift + key.eqn_start_idx, modulo);
    end hash;

    function equal
      input PseudoBucketKey key1;
      input PseudoBucketKey key2;
      output Boolean b = intEq(key1.eqn_start_idx, key2.eqn_start_idx) and intEq(key1.eqn_arr_idx, key2.eqn_arr_idx) and intEq(key1.mode, key2.mode);
    end equal;
  end PseudoBucketKey;

  uniontype PseudoBucketValue
    record PSEUDO_BUCKET_SINGLE
      ComponentRef cref_to_solve      "cref to solve for in this mode";
      list<Integer> eqn_scal_indices  "indices of all scalarized equations that have to be solved that way";
      Integer first_comp;
      Integer last_comp;
    end PSEUDO_BUCKET_SINGLE;

    record PSEUDO_BUCKET_ENTWINED
      // reverse order, will be iterated and reversed anyway
      list<tuple<PseudoBucketKey, PseudoBucketValue>> entwined_lst;
      array<list<Integer>> entwined_arr;
    end PSEUDO_BUCKET_ENTWINED;

    function addIndices
      input output PseudoBucketValue val;
      input Integer eqn_scal_idx;
      input Integer comp_idx;
    algorithm
      val := match val
        case PSEUDO_BUCKET_SINGLE() algorithm
          val.eqn_scal_indices := eqn_scal_idx :: val.eqn_scal_indices;
          val.last_comp := comp_idx;
        then val;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " cannot add single index to entwined pseudo bucket."});
        then fail();
      end match;
    end addIndices;
  end PseudoBucketValue;

  uniontype PseudoBucket
    record PSEUDO_BUCKET
      UnorderedMap<PseudoBucketKey, PseudoBucketValue> bucket;
      array<Boolean> marks;
    end PSEUDO_BUCKET;

    function create
      "recollects subsets of multi-dimensional equations that have to be solved in the same way.
      currently only for loops!"
      input list<list<Integer>> comps_indices   "the sorted scalar components";
      input array<Integer> eqn_to_var           "eqn to var matching";
      input Adjacency.Mapping mapping           "scalar <-> array index mapping";
      input Adjacency.CausalizeModes modes      "the causalization modes for all multi-dimensional equations";
      output PseudoBucket bucket                "the bucket containing the equation subsets";
    protected
      array<array<Integer>> current_start_indices = arrayCreate(arrayLength(mapping.eqn_AtS), arrayCreate(0,0));
      array<list<Integer>> entwined_arr, comps_arr = listArray(comps_indices);
      Integer eqn_scal_idx, mode, comps_length = listLength(comps_indices);
      list<tuple<PseudoBucketKey, PseudoBucketValue>> bucket_lst, acc = {};
      array<tuple<PseudoBucketKey, PseudoBucketValue>> bucket_arr;
      PseudoBucketKey key;
      PseudoBucketValue val;
      Integer first, last;
    algorithm
      // 0. initialize start indices
      for i in Pointer.access(modes.mode_eqns) loop
        current_start_indices[i] := arrayCreate(arrayLength(arrayGet(modes.mode_to_cref, i)), 0);
      end for;

      // 1. create empty buckets
      bucket := PSEUDO_BUCKET(
        bucket  = UnorderedMap.new<PseudoBucketValue>(
          hash    = function PseudoBucketKey.hash(shift=arrayLength(modes.mode_to_cref)),
          keyEq   = PseudoBucketKey.equal),
        marks   = arrayCreate(arrayLength(eqn_to_var), false)
      );

      // 2. sort all subsets in buckets depending on causalization mode and equation
      for i in 1:comps_length loop
        _ := match comps_arr[i]
          case {eqn_scal_idx} guard(Adjacency.CausalizeModes.contains(eqn_scal_idx, modes)) algorithm
            // if we have a strong component of only one equation - check if there is a mode for it
            // (only for-equations have modes)
            mode := Adjacency.CausalizeModes.get(eqn_scal_idx, eqn_to_var[eqn_scal_idx], modes);
            PseudoBucket.add(mapping.eqn_StA[eqn_scal_idx], eqn_scal_idx, i, mode, current_start_indices, modes, bucket);
          then ();

          // ToDo: what if partial stuff of for-loops ends up in an algebraic loop?
          else algorithm
            for i in Pointer.access(modes.mode_eqns) loop
              current_start_indices[i] := arrayCreate(arrayLength(arrayGet(current_start_indices, i)), 0);
            end for;
          then();
        end match;
      end for;

      // 3. entwine for loops
      bucket_lst := UnorderedMap.toList(bucket.bucket);
      if not listEmpty(bucket_lst) then
        bucket_arr := listArray(List.sort(bucket_lst, tplSortGt));
        first := tplGetFirstComp(bucket_arr[1]);
        last := tplGetLastComp(bucket_arr[1]);
        for i in 1:arrayLength(bucket_arr) loop
          if tplGetFirstComp(bucket_arr[i]) > last then
            entwined_arr := arrayCreate(last-first+1, {});
            Array.copyRange(comps_arr, entwined_arr, first, last, 1);
            updateEntwined(acc, entwined_arr, bucket);
            first := tplGetFirstComp(bucket_arr[i]);
            acc := {bucket_arr[i]};
          else
            acc := bucket_arr[i] :: acc;
          end if;
          last := intMax(tplGetLastComp(bucket_arr[i]), last);
        end for;
        entwined_arr := arrayCreate(last-first+1, {});
        Array.copyRange(comps_arr, entwined_arr, first, last, 1);
        updateEntwined(acc, entwined_arr, bucket);
      end if;
    end create;

    function add
      input Integer eqn_arr_idx;
      input Integer eqn_scal_idx;
      input Integer comp_idx;
      input Integer mode;
      input array<array<Integer>> current_start_indices;
      input Adjacency.CausalizeModes modes      "the causalization modes for all multi-dimensional equations";
      input PseudoBucket bucket;
    protected
      PseudoBucketKey key;
      PseudoBucketValue val;
    algorithm
      // get or set current start index
      if arrayGet(current_start_indices[eqn_arr_idx], mode) == 0 then
        arrayUpdate(current_start_indices[eqn_arr_idx], mode, eqn_scal_idx);
        key := PSEUDO_BUCKET_KEY(eqn_scal_idx, eqn_arr_idx, mode);
      else
        key := PSEUDO_BUCKET_KEY(arrayGet(current_start_indices[eqn_arr_idx], mode), eqn_arr_idx, mode);
      end if;

      if UnorderedMap.contains(key, bucket.bucket) then
        // if the mode already was found, add this equation to the bucket
        val := PseudoBucketValue.addIndices(UnorderedMap.getSafe(key, bucket.bucket), eqn_scal_idx, comp_idx);
        UnorderedMap.add(key, val, bucket.bucket);
      else
        // create a new bucket containing this equation
        val := PSEUDO_BUCKET_SINGLE(arrayGet(arrayGet(modes.mode_to_cref, eqn_arr_idx), mode), {eqn_scal_idx}, comp_idx, comp_idx);
        UnorderedMap.addNew(key, val, bucket.bucket);
      end if;
    end add;

    function updateEntwined
      input list<tuple<PseudoBucketKey, PseudoBucketValue>> acc;
      input array<list<Integer>> entwined_arr;
      input PseudoBucket bucket;
    protected
      PseudoBucketKey key;
      PseudoBucketValue entwined;
    algorithm
      if listLength(acc) > 1 then
        entwined := PSEUDO_BUCKET_ENTWINED(acc, entwined_arr);
        for tpl in acc loop
          (key, _) := tpl;
          UnorderedMap.add(key, entwined, bucket.bucket);
        end for;
      end if;
    end updateEntwined;

    function get
      input Integer eqn_start_idx;
      input Integer eqn_arr_idx;
      input Integer mode;
      input PseudoBucket bucket;
      output PseudoBucketValue val;
    protected
      PseudoBucketKey key = PSEUDO_BUCKET_KEY(eqn_start_idx, eqn_arr_idx, mode);
    algorithm
      val := UnorderedMap.getSafe(key, bucket.bucket);
    end get;

    function tplSortGt
      input tuple<PseudoBucketKey, PseudoBucketValue> tpl1;
      input tuple<PseudoBucketKey, PseudoBucketValue> tpl2;
      output Boolean less;
    algorithm
      less := match (tpl1, tpl2)
        local
          Integer c1, c2;
        case ((_, PSEUDO_BUCKET_SINGLE(first_comp = c1)), (_, PSEUDO_BUCKET_SINGLE(first_comp = c2))) then c1 > c2;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " cannot compare entwined pseudo bucket."});
        then fail();
      end match;
    end tplSortGt;

    function tplGetLastComp
      input tuple<PseudoBucketKey, PseudoBucketValue> tpl;
      output Integer last_comp;
    algorithm
      last_comp := match tpl
        case (_, PSEUDO_BUCKET_SINGLE(last_comp = last_comp)) then last_comp;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " cannot get last component for entwined pseudo bucket."});
        then fail();
      end match;
    end tplGetLastComp;

    function tplGetFirstComp
      input tuple<PseudoBucketKey, PseudoBucketValue> tpl;
      output Integer first_comp;
    algorithm
      first_comp := match tpl
        case (_, PSEUDO_BUCKET_SINGLE(first_comp = first_comp)) then first_comp;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " cannot get first component for entwined pseudo bucket."});
        then fail();
      end match;
    end tplGetFirstComp;
  end PseudoBucket;

  // ############################################################
  //                      Main Functions
  // ############################################################

  function tarjan
    "author: kabdelhak
    Sorting algorithm for directed graphs by Robert E. Tarjan.
    First published in doi:10.1137/0201010"
    input Adjacency.Matrix adj;
    input Matching matching;
    input VariablePointers vars;
    input EquationPointers eqns;
    output list<StrongComponent> comps = {};
  algorithm
    comps := match (adj, matching)
      local
        list<list<Integer>> comps_indices;
        PseudoBucket bucket;
        Option<StrongComponent> comp_opt;

      case (Adjacency.Matrix.SCALAR_ADJACENCY_MATRIX(), Matching.SCALAR_MATCHING()) algorithm
        comps_indices := tarjanScalar(adj.m, matching.var_to_eqn, matching.eqn_to_var);
        comps := list(StrongComponent.create(idx_lst, matching, vars, eqns) for idx_lst in comps_indices);
      then comps;

      case (Adjacency.Matrix.PSEUDO_ARRAY_ADJACENCY_MATRIX(), Matching.SCALAR_MATCHING()) algorithm
        comps_indices := tarjanScalar(adj.m, matching.var_to_eqn, matching.eqn_to_var);

        // recollect array information
        bucket := PseudoBucket.create(comps_indices, matching.eqn_to_var, adj.mapping, adj.modes);
        for idx_lst in comps_indices loop
          comp_opt := StrongComponent.createPseudo(idx_lst, matching.eqn_to_var, vars, eqns, adj.mapping, adj.modes, bucket);
          if Util.isSome(comp_opt) then
            comps := Util.getOption(comp_opt) :: comps;
          end if;
        end for;
        comps := listReverse(comps);
      then comps;

      case (Adjacency.Matrix.ARRAY_ADJACENCY_MATRIX(), Matching.ARRAY_MATCHING()) algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array sorting is not yet supported."});
      then fail();

      case (Adjacency.Matrix.EMPTY_ADJACENCY_MATRIX(), Matching.EMPTY_MATCHING()) algorithm
      then {};

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because adjacency matrix and matching have different types."});
      then fail();
    end match;
  end tarjan;

  function tarjanScalar
    "author: lochel, kabdelhak
    This sorting algorithm only considers equations e that have a matched variable v with e = var_to_eqn[v]."
    input array<list<Integer>> m          "normal adjacency matrix";
    input array<Integer> var_to_eqn       "eqn := var_to_eqn[var]";
    input array<Integer> eqn_to_var       "var := eqn_to_var[eqn]";
    output list<list<Integer>> comps = {} "eqn indices";
  protected
    Integer index = 0;
    list<Integer> stack = {};
    array<Integer> number, lowlink;
    array<Boolean> onStack;
    Integer N = arrayLength(var_to_eqn);
    Integer M = arrayLength(eqn_to_var);
    Integer eqn;
  algorithm
    number := arrayCreate(M, -1);
    lowlink := arrayCreate(M, -1);
    onStack := arrayCreate(M, false);

    // loop over all variables and find their component
    for var in 1:N loop
      eqn := var_to_eqn[var];
      if eqn > 0 and number[eqn] == -1 then
        (stack, index, comps) := strongConnect(m, var_to_eqn, eqn, stack, index, number, lowlink, onStack, comps);
      end if;
    end for;

    // free auxiliary arrays
    GCExt.free(number);
    GCExt.free(lowlink);
    GCExt.free(onStack);

    // reverse for correct ordering
    comps := listReverse(comps);
  end tarjanScalar;

  // ############################################################
  //                Protected Functions and Types
  // ############################################################

protected
  function strongConnect
    "author: lochel, kabdelhak"
    input array<list<Integer>> m            "normal adjacency matrix";
    input array<Integer> var_to_eqn         "eqn := var_to_eqn[var]";
    input Integer eqn                       "current equation index";
    input output list<Integer> stack        "equation stack";
    input output Integer index              "component index";
    input array<Integer> number             "auxiliary array";
    input array<Integer> lowlink            "represents the component groups";
    input array<Boolean> onStack            "true if eqn index is on the stack";
    input output list<list<Integer>> comps  "accumulator for components";
  protected
    list<Integer> SCC;
    Integer eqn2;
  algorithm
    // Set the depth index for eqn to the smallest unused index
    arrayUpdate(number, eqn, index);
    arrayUpdate(lowlink, eqn, index);
    arrayUpdate(onStack, eqn, true);
    index := index + 1;
    stack := eqn::stack;

    // Consider successors of eqn
    for eqn2 in predecessors(eqn, m, var_to_eqn) loop
      if number[eqn2] == -1 then
        // Successor eqn2 has not yet been visited; recurse on it
        (stack, index, comps) := strongConnect(m, var_to_eqn, eqn2, stack, index, number, lowlink, onStack, comps);
        arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], lowlink[eqn2]));
      elseif onStack[eqn2] then
        // Successor eqn2 is in the stack and hence in the current SCC
        arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], number[eqn2]));
      end if;
    end for;

    // If eqn is a root node, pop the stack and generate an SCC
    if lowlink[eqn] == number[eqn] then
      eqn2::stack := stack;
      arrayUpdate(onStack, eqn2, false);
      SCC := {eqn2};
      while eqn <> eqn2 loop
        eqn2::stack := stack;
        arrayUpdate(onStack, eqn2, false);
        SCC := eqn2::SCC;
      end while;
      comps := MetaModelica.Dangerous.listReverseInPlace(SCC)::comps;
    end if;
  end strongConnect;

  function predecessors "author: lochel, kabdelhak
    Returns a list of incoming nodes, corresponding
    to the adjacency matrix"
    input Integer idx             "node index to get all predecessors for";
    input array<list<Integer>> m  "normal adjacency matrix";
    input array<Integer> mapping  "maps either var to eqn or eqn to var (matching)";
    output list<Integer> pre_lst  "all predecessors";
  algorithm
    pre_lst := list(mapping[cand] for cand guard(cand > 0 and mapping[cand] <> idx and mapping[cand] > 0) in m[idx]);
  end predecessors;

  annotation(__OpenModelica_Interface="backend");
end NBSorting;
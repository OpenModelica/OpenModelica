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

    function toString
      input PseudoBucketKey key;
      output String str = "key: (start[s]: " + intString(key.eqn_start_idx)
        + ", index[a]:" + intString(key.eqn_arr_idx) + ", mode: " + intString(key.mode) + ")";
    end toString;

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

    function toString
      input PseudoBucketValue val;
      output String str;
    algorithm
      str := match val
        local
          PseudoBucketKey k;
          PseudoBucketValue v;
        case PSEUDO_BUCKET_SINGLE() then "\n\tval: (" + ComponentRef.toString(val.cref_to_solve)
          + ", [" + intString(val.first_comp) + ":" + intString(val.last_comp) +"]" + ")";
        case PSEUDO_BUCKET_ENTWINED() algorithm
           str := "\n\tentwined:";
           for tpl in val.entwined_lst loop
            (k, v) := tpl;
            str := str + "\n\t" + PseudoBucketKey.toString(k) + " :: " + PseudoBucketValue.toString(v);
           end for;
        then str;
      end match;
    end toString;

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

    function getIndices
      input PseudoBucketValue val;
      output list<Integer> eqn_scal_indices;
    algorithm
      eqn_scal_indices := match val
        case PSEUDO_BUCKET_SINGLE() then val.eqn_scal_indices;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " cannot add single index to entwined pseudo bucket."});
        then fail();
      end match;
    end getIndices;

    function getCref
      input PseudoBucketValue val;
      output ComponentRef cref_to_solve;
    algorithm
      cref_to_solve := match val
        case PSEUDO_BUCKET_SINGLE() then val.cref_to_solve;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " cannot add single index to entwined pseudo bucket."});
        then fail();
      end match;
    end getCref;
  end PseudoBucketValue;

  uniontype PseudoBucket
    record PSEUDO_BUCKET
      UnorderedMap<PseudoBucketKey, PseudoBucketValue> bucket;
      array<Boolean> marks;
    end PSEUDO_BUCKET;

    function toString
      input PseudoBucket bucket;
      output String str = UnorderedMap.toString(bucket.bucket, PseudoBucketKey.toString, PseudoBucketValue.toString);
    end toString;

    function isEmpty
      input PseudoBucket bucket;
      output Boolean b = UnorderedMap.isEmpty(bucket.bucket);
    end isEmpty;

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

    function create2
      "recollects subsets of multi-dimensional equations that have to be solved in the same way.
      currently only for loops!"
      input array<Integer> eqn_to_var           "eqn to var matching";
      input Adjacency.Mapping mapping           "scalar <-> array index mapping";
      input Adjacency.CausalizeModes modes      "the causalization modes for all multi-dimensional equations";
      output PseudoBucket bucket                "the bucket containing the equation subsets";
    protected
      Integer mode;
    algorithm
      // 1. create empty buckets
      bucket := PSEUDO_BUCKET(
        bucket  = UnorderedMap.new<PseudoBucketValue>(
          hash    = function PseudoBucketKey.hash(shift=arrayLength(modes.mode_to_cref)),
          keyEq   = PseudoBucketKey.equal),
        marks   = arrayCreate(arrayLength(eqn_to_var), false)
      );

      // 2. add each equation to a bucket if solved the same way
      for eqn_scal_idx in 1:arrayLength(eqn_to_var) loop
        if Adjacency.CausalizeModes.contains(eqn_scal_idx, modes) then
          mode := Adjacency.CausalizeModes.get(eqn_scal_idx, eqn_to_var[eqn_scal_idx], modes);
          PseudoBucket.add2(mapping.eqn_StA[eqn_scal_idx], eqn_scal_idx, mode, modes, bucket);
        end if;
      end for;
    end create2;

    function add2
      input Integer eqn_arr_idx;
      input Integer eqn_scal_idx;
      input Integer mode;
      input Adjacency.CausalizeModes modes      "the causalization modes for all multi-dimensional equations";
      input PseudoBucket bucket;
    protected
      PseudoBucketKey key = PSEUDO_BUCKET_KEY(0, eqn_arr_idx, mode);
      PseudoBucketValue val;
    algorithm
      if UnorderedMap.contains(key, bucket.bucket) then
        // if the mode already was found, add this equation to the bucket
        val := PseudoBucketValue.addIndices(UnorderedMap.getSafe(key, bucket.bucket), eqn_scal_idx, 0);
        UnorderedMap.add(key, val, bucket.bucket);
      else
        // create a new bucket containing this equation
        val := PSEUDO_BUCKET_SINGLE(arrayGet(arrayGet(modes.mode_to_cref, eqn_arr_idx), mode), {eqn_scal_idx}, 0, 0);
        UnorderedMap.addNew(key, val, bucket.bucket);
      end if;
    end add2;

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
        val := PseudoBucketValue.addIndices(UnorderedMap.getSafe(key, bucket.bucket, sourceInfo()), eqn_scal_idx, comp_idx);
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
      val := UnorderedMap.getSafe(key, bucket.bucket, sourceInfo());
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
        list<list<Integer>> comps_indices, phase2_indices;
        PseudoBucket bucket;
        Option<StrongComponent> comp_opt;
        Adjacency.Matrix phase2_adj;
        Matching phase2_matching;
        array<SuperNode> super_nodes;

      case (Adjacency.Matrix.SCALAR_ADJACENCY_MATRIX(), Matching.SCALAR_MATCHING()) algorithm
        comps_indices := tarjanScalar(adj.m, matching.var_to_eqn, matching.eqn_to_var);
        comps := list(StrongComponent.create(idx_lst, matching, vars, eqns) for idx_lst in comps_indices);
      then comps;

      case (Adjacency.Matrix.PSEUDO_ARRAY_ADJACENCY_MATRIX(), Matching.SCALAR_MATCHING()) algorithm
        bucket := PseudoBucket.create2(matching.eqn_to_var, adj.mapping, adj.modes);
        comps_indices := tarjanScalar(adj.m, matching.var_to_eqn, matching.eqn_to_var);

        // phase 2 tarjan
        if not PseudoBucket.isEmpty(bucket) then
          (phase2_adj, phase2_matching, super_nodes) := SuperNode.create(adj, matching, comps_indices, bucket);
          // kabdelhak: this matching is superfluous, SuperNode.create always returns these types.
          // it is just safer if something is changed in the future
          _ := match (phase2_adj, phase2_matching)
            case (Adjacency.Matrix.PSEUDO_ARRAY_ADJACENCY_MATRIX(), Matching.SCALAR_MATCHING()) algorithm
              phase2_indices := tarjanScalar(phase2_adj.m, phase2_matching.var_to_eqn, phase2_matching.eqn_to_var);
              /*
              for comp_lst in phase2_indices loop
                print(List.toString(list(super_nodes[i] for i in comp_lst), SuperNode.toString, "", "\t", "\n\t", "\n"));
              end for;
              */
              comps := list(SuperNode.collapse(comp, super_nodes, adj.m, adj.mapping, adj.modes, matching.var_to_eqn, matching.eqn_to_var, vars, eqns) for comp in phase2_indices);
              //print(List.toString(comps, function StrongComponent.toString(index = -1), "comps", "\t", "\n\t", "\n"));
            then ();

            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix or matching type."});
            then fail();
          end match;
        end if;
/*
        // recollect array information
        bucket := PseudoBucket.create(comps_indices, matching.eqn_to_var, adj.mapping, adj.modes);

        if Flags.isSet(Flags.DUMP_SLICE) then
          print("--- BUCKETS:\n" + PseudoBucket.toString(bucket) + "\n\n");
        end if;

        for idx_lst in comps_indices loop
          comp_opt := StrongComponent.createPseudo(idx_lst, matching.eqn_to_var, vars, eqns, adj.mapping, adj.modes, bucket);
          if Util.isSome(comp_opt) then
            comps := Util.getOption(comp_opt) :: comps;
          end if;
        end for;
        comps := listReverse(comps);*/
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


  uniontype SuperNode
    record SINGLE
      "does not belong to an algebraic loop or array"
      Integer index;
    end SINGLE;

    record ELEMENT
      "is part of either an algebraic loop or array"
      Integer index;
      Integer parent;
    end ELEMENT;

    record ALGEBRAIC_LOOP
      "an algebraic loop of equations"
      Integer index;
      list<Integer> eqn_indices;
    end ALGEBRAIC_LOOP;

    record ARRAY_BUCKET
      "a bucket of array equations solved for the same cref"
      Integer index;
      ComponentRef cref_to_solve;
      list<Integer> eqn_indices;
      Integer arr_idx;
    end ARRAY_BUCKET;

    function toString
      input SuperNode node;
      output String str;
    algorithm
      str := match node
        case SINGLE()           then "[" + intString(node.index) + "] single ";
        case ELEMENT()          then "[" + intString(node.index) + "] scalar element of (" + intString(node.parent) + ")";
        case ALGEBRAIC_LOOP()   then "[" + intString(node.index) + "] algebraic loop " + List.toString(node.eqn_indices, intString);
        case ARRAY_BUCKET()     then "[" + intString(node.index) + "] array bucket " + List.toString(node.eqn_indices, intString);
                                else "ERROR";
      end match;
    end toString;

    function isNotArrayBucket
      input SuperNode node;
      output Boolean b;
    algorithm
      b := match node
        case ARRAY_BUCKET() then false;
        else true;
      end match;
    end isNotArrayBucket;

    function getEqnIndices
      input SuperNode node;
      output list<Integer> eqn_indices;
    algorithm
      eqn_indices := match node
        case SINGLE()         then {node.index};
        case ALGEBRAIC_LOOP() then node.eqn_indices;
        case ARRAY_BUCKET()   then node.eqn_indices;
        case ELEMENT() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because elements should not be accessed, only their parrents: " + toString(node)});
        then fail();
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of incorrect super node type."});
        then fail();
      end match;
    end getEqnIndices;

    function create
      input Adjacency.Matrix adj;
      input Matching matching;
      input list<list<Integer>> scc_phase1;
      input PseudoBucket bucket;
      output Adjacency.Matrix phase2_adj = adj;
      output Matching phase2_matching = matching;
      output array<SuperNode> super_nodes;
    protected
      list<list<Integer>> algebraic_loops = list(scc for scc guard(listLength(scc) > 1) in scc_phase1);
      list<tuple<PseudoBucketKey, PseudoBucketValue>> buckets = UnorderedMap.toList(bucket.bucket);
      PseudoBucketKey key;
      PseudoBucketValue val;
      Integer index, shift = listLength(algebraic_loops) + listLength(buckets);
      list<Integer> var_lst;
    algorithm
      phase2_adj := match (phase2_adj, phase2_matching)
        case (Adjacency.PSEUDO_ARRAY_ADJACENCY_MATRIX(), Matching.SCALAR_MATCHING()) algorithm
          //### 0. initialize super nodes ###
          super_nodes := listArray(list(SuperNode.SINGLE(i) for i in 1:arrayLength(phase2_adj.m) + shift));

          // ### 3. expand matching ###
          index := arrayLength(phase2_matching.eqn_to_var);
          phase2_matching.eqn_to_var := Array.expandToSize(arrayLength(phase2_matching.eqn_to_var) + shift, phase2_matching.eqn_to_var, -1);
          for i in index+1:index+shift loop
            phase2_matching.eqn_to_var[i] := i;
          end for;

/*
          for n_idx in 1:arrayLength(super_nodes) loop
            print("node: " + toString(super_nodes[n_idx]) + " -- ");
          end for;
          print("\n\n");
*/

          index := arrayLength(phase2_matching.var_to_eqn);
          phase2_matching.var_to_eqn := Array.expandToSize(arrayLength(phase2_matching.var_to_eqn) + shift, phase2_matching.var_to_eqn, -1);
          for i in index+1:index+shift loop
            phase2_matching.var_to_eqn[i] := i;
          end for;

          //### 1. adjust transposed matrix ###
          // 1.1. enlarge transposed matrix by the maximum possible amount of new nodes
          index := arrayLength(phase2_adj.mT) + 1;
          phase2_adj.mT := Adjacency.Matrix.expandMatrix(phase2_adj.mT, shift);
          // 1.2. merge all algebraic loop variables of one scc to one single variable

          for scc in algebraic_loops loop
            var_lst := list(phase2_matching.eqn_to_var[idx] for idx in scc);
            mergeLoopNodes(super_nodes, var_lst, index, false);
            index := mergeRows(phase2_adj.mT, phase2_matching.var_to_eqn, super_nodes, var_lst, index);
          end for;
        /*
          for n_idx in 1:arrayLength(super_nodes) loop
            print("node: " + toString(super_nodes[n_idx]) + " -- ");
          end for;
          print("\n\n1.3");
        */
          // 1.3. merge all for-loop variables of one bucket to one single variable
          for bucket in buckets loop
            (key, val) := bucket;
            //print("eqn idc: " + List.toString(PseudoBucketValue.getIndices(val), intString)+ "\n");
            var_lst := list(phase2_matching.eqn_to_var[idx] for idx in PseudoBucketValue.getIndices(val));
            //print("var idc: " + List.toString(var_lst, intString)+ "\n");
            mergeArrayNodes(super_nodes, PseudoBucketValue.getCref(val), var_lst, index, key.eqn_arr_idx, false);
            index := mergeRows(phase2_adj.mT, phase2_matching.var_to_eqn, super_nodes, var_lst, index);
          end for;
        /*
          for n_idx in 1:arrayLength(super_nodes) loop
            print("node: " + toString(super_nodes[n_idx]) + " -- ");
          end for;
          print("\n\n");
*/
          /// ### 2. adjust normal matrix ###
          // 2.1. transpose the transposed matrix and enlarge it by the maximum possible amount of new nodes
          index := arrayLength(phase2_adj.m) + 1;
          phase2_adj.m := Adjacency.Matrix.transposeScalar(phase2_adj.mT, arrayLength(phase2_adj.m) + shift);
          // 2.2 merge all algebraic loop equations of one scc to one single equation
          for scc in algebraic_loops loop
            mergeLoopNodes(super_nodes, scc, index, true);
            index := mergeRows(phase2_adj.m, phase2_matching.eqn_to_var, super_nodes, scc, index);
          end for;
          // print("\n\n");
          // 2.3. merge all for-loop equations of one bucket to one single equation
          for bucket in buckets loop
            (key, val) := bucket;
            mergeArrayNodes(super_nodes, PseudoBucketValue.getCref(val), PseudoBucketValue.getIndices(val), index, key.eqn_arr_idx, true);
            index := mergeRows(phase2_adj.m, phase2_matching.eqn_to_var, super_nodes, PseudoBucketValue.getIndices(val), index);
          end for;
        /*
          for n_idx in 1:arrayLength(super_nodes) loop
            print("node: " + toString(super_nodes[n_idx]) + " -- ");
          end for;
          print("\n\n");
         */
          // 2.4. transpose it back to have it consistent (probably not actually necessary for phase2 tarjan but more safe)
          phase2_adj.mT := Adjacency.Matrix.transposeScalar(phase2_adj.m, arrayLength(phase2_adj.mT));

        then phase2_adj;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix or matching type."});
        then fail();
      end match;
    /*
      print(Adjacency.Matrix.toString(adj, "before"));
      print(Matching.toString(matching, "before"));
      print(Adjacency.Matrix.toString(phase2_adj, "after"));
      print(Matching.toString(phase2_matching, "after"));
      */
    end create;

    function collapse
      input list<Integer> comp_indices;
      input array<SuperNode> super_nodes;
      input array<list<Integer>> m;
      input Adjacency.Mapping mapping;
      input Adjacency.CausalizeModes modes;
      input array<Integer> var_to_eqn;
      input array<Integer> eqn_to_var;
      input VariablePointers vars;
      input EquationPointers eqns;
      output StrongComponent comp;
    protected
      list<SuperNode> node_comp = list(super_nodes[i] for i in comp_indices);
      list<list<Integer>> sorted_body_components;
      list<Integer> sorted_body_indices;
    algorithm
      comp := match node_comp
        local
          SuperNode node;
          array<list<Integer>> m_local;
          array<Integer> var_to_eqn_local, eqn_to_var_local;
          list<StrongComponent> local_comps = {};

        // a single scalar equation that has nothing to do with arrays
        case {SINGLE()}
        then StrongComponent.createPseudoScalar(comp_indices, eqn_to_var, mapping, vars, eqns);

        // a single strong component from phase I
        case {node as ALGEBRAIC_LOOP()}
        then StrongComponent.createPseudoScalar(node.eqn_indices, eqn_to_var, mapping, vars, eqns);

        // a single array equation
        case {node as ARRAY_BUCKET()} algorithm
          // create local system to determine in what order the equations have to be solved
          m_local := arrayCreate(arrayLength(m), {});
          var_to_eqn_local := arrayCreate(arrayLength(var_to_eqn), -1);
          eqn_to_var_local := arrayCreate(arrayLength(eqn_to_var), -1);
          // copy adjacency matrix and matching from full system
          for i in node.eqn_indices loop
            m_local[i] := m[i];
            eqn_to_var_local[i] := eqn_to_var[i];
            var_to_eqn_local[eqn_to_var[i]] := var_to_eqn[eqn_to_var[i]];
          end for;
          // sort the scalar components
          sorted_body_components := tarjanScalar(m_local, var_to_eqn_local, eqn_to_var_local);
          sorted_body_indices := List.flatten(sorted_body_components);
          // if new strong components of size > 1 were created it is an error, this should
          // have occured in sorting phase I
          if not listLength(sorted_body_components) == listLength(sorted_body_indices) then
            Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " crucially failed for the following Phase II strong component because
              the body turned out to still have strong components:\n"
              + List.toString(node_comp, SuperNode.toString, "", "\t", "\n\t", "\n")});
          end if;
        then StrongComponent.createPseudoSlice(mapping.eqn_StA[List.first(node.eqn_indices)], node.cref_to_solve, sorted_body_indices, eqns, mapping);

        // entwined array equations
        case _ guard(not List.any(node_comp, isNotArrayBucket)) algorithm
          m_local := arrayCreate(arrayLength(m), {});
          var_to_eqn_local := arrayCreate(arrayLength(var_to_eqn), -1);
          eqn_to_var_local := arrayCreate(arrayLength(eqn_to_var), -1);
          for node in node_comp loop
            for i in getEqnIndices(node) loop
              m_local[i] := m[i];
              eqn_to_var_local[i] := eqn_to_var[i];
              var_to_eqn_local[eqn_to_var[i]] := var_to_eqn[eqn_to_var[i]];
            end for;
          end for;
          sorted_body_components := tarjanScalar(m_local, var_to_eqn_local, eqn_to_var_local);
          sorted_body_indices := List.flatten(sorted_body_components);

          if listLength(sorted_body_components) == listLength(sorted_body_indices) then
            // create entwined for loop if there was no algebraic loop
            comp := StrongComponent.createPseudoEntwined(sorted_body_indices, eqn_to_var, mapping, vars, eqns, node_comp);
          else
            // create algebraic loop
            comp := StrongComponent.createPseudoScalar(sorted_body_indices, eqn_to_var, mapping, vars, eqns);
          end if;

        then comp;

        // create algebraic loop (body components not actually sorted)
        else algorithm
          sorted_body_indices := List.flatten(list(getEqnIndices(n) for n in node_comp));
        then StrongComponent.createPseudoScalar(sorted_body_indices, eqn_to_var, mapping, vars, eqns);
      end match;
    end collapse;

  protected
    function mergeRows
      input array<list<Integer>> m;
      input array<Integer> matching;
      input array<SuperNode> super_nodes;
      input list<Integer> rows_to_merge;
      input output Integer new_idx;
    algorithm
      // merge all rows to one row
      arrayUpdate(m, new_idx, List.unique(List.flatten(list(m[idx] for idx in rows_to_merge))));
      // remove the original rows
      for idx in rows_to_merge loop
        arrayUpdate(m, idx, {});
        arrayUpdate(matching, idx, -1);
      end for;
      new_idx := new_idx + 1;
    end mergeRows;

    function mergeArrayNodes
      input array<SuperNode> super_nodes;
      input ComponentRef cref_to_solve;
      input list<Integer> rows_to_merge;
      input output Integer new_idx;
      input Integer arr_idx;
      input Boolean update_scalar;
    algorithm
      arrayUpdate(super_nodes, new_idx, SuperNode.ARRAY_BUCKET(new_idx, cref_to_solve, rows_to_merge, arr_idx));
      // this is not necessary but better to debug.
      if update_scalar then
        for i in rows_to_merge loop
          arrayUpdate(super_nodes, i, SuperNode.ELEMENT(i, new_idx));
        end for;
      end if;
    end mergeArrayNodes;

    function mergeLoopNodes
      input array<SuperNode> super_nodes;
      input list<Integer> rows_to_merge;
      input output Integer new_idx;
      input Boolean update_scalar;
    algorithm
      arrayUpdate(super_nodes, new_idx, SuperNode.ALGEBRAIC_LOOP(new_idx, rows_to_merge));
      // this is not necessary but better to debug.
      if update_scalar then
        for i in rows_to_merge loop
          arrayUpdate(super_nodes, i, SuperNode.ELEMENT(i, new_idx));
        end for;
      end if;
    end mergeLoopNodes;
  end SuperNode;

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
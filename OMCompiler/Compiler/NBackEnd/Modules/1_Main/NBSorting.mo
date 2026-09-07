/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
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
  // NB imports
  import Adjacency = NBAdjacency;
  import NBAdjacency.Mode;
  import BEquation = NBEquation;
  import NBEquation.{Equation, EquationPointers};
  import BVariable = NBVariable;
  import NBVariable.VariablePointers;
  import Matching = NBMatching;

  // NF imports
  import ComponentRef = NFComponentRef;

  // Util imports
  import BackendUtil = NBBackendUtil;
  import UnorderedMap;

public
  // ############################################################
  //                Pseudo Bucket Structures
  // ############################################################

  uniontype Value
    record SINGLE_VAL
      ComponentRef cref_to_solve      "cref to solve for in this mode";
      list<Integer> eqn_scal_indices  "indices of all scalarized equations that have to be solved that way";
    end SINGLE_VAL;

    record MULTI_VAL
      list<ComponentRef> crefs_to_solve "crefs to solve for in this mode";
      list<Integer> eqn_scal_indices    "indices of all scalarized equations that have to be solved that way";
    end MULTI_VAL;

    function toString
      input Value val;
      output String str;
    algorithm
      str := match val
        case SINGLE_VAL() then "\n\tval: (" + ComponentRef.toString(val.cref_to_solve) + ")";
        case MULTI_VAL()  then "\n\tval: " + List.toString(val.crefs_to_solve, ComponentRef.toString);
      end match;
    end toString;

    function filter
      input output Value val;
      input UnorderedSet<Integer> set;
    algorithm
      val := match val
        case SINGLE_VAL() algorithm val.eqn_scal_indices := list(idx for idx guard(not UnorderedSet.contains(idx, set)) in val.eqn_scal_indices); then val;
        case MULTI_VAL()  algorithm val.eqn_scal_indices := list(idx for idx guard(not UnorderedSet.contains(idx, set)) in val.eqn_scal_indices); then val;
      end match;
    end filter;

    function getEquations
      input Value val;
      output list<Integer> eqn_scal_indices;
    algorithm
      eqn_scal_indices := match val
        case SINGLE_VAL() then val.eqn_scal_indices;
        case MULTI_VAL()  then val.eqn_scal_indices;
      end match;
    end getEquations;

  end Value;

  package PseudoBucket
    // While collecting, a bucket accumulates its equations and crefs in pointers
    // so that adding one costs a single cons.
    type Bucket = tuple<Mode, Boolean, Pointer<list<Integer>>, Pointer<list<ComponentRef>>>;

    function create
      "recollects subsets of multi-dimensional equations that have to be solved in the same way.
      currently only for loops!
      The buckets of one array equation are found by its index instead of by
      hashing the mode, which keys on the equation name only anyway."
      input array<Integer> eqn_to_var           "eqn to var matching";
      input EquationPointers eqns;
      input Adjacency.Mapping mapping           "scalar <-> array index mapping";
      input Adjacency.IntMatrix m               "normal adjacency matrix, holding the mode ids";
      input Adjacency.ModeTable modes;
      output list<tuple<Mode, Value>> buckets = {};
    protected
      array<Integer> data = Adjacency.IntMatrix.entries(m);
      array<Integer> ids = Adjacency.IntMatrix.payload(m);
      array<list<Bucket>> per_eqn = arrayCreate(intMax(arrayLength(mapping.eqn_AtS), 1), {});
      list<Bucket> order = {};
      Option<Mode> mode_opt;
      Mode mode;
      ComponentRef cref;
      Integer eqn_arr_idx;
      Boolean multi, fresh;
      Pointer<list<Integer>> idx_ptr;
      Pointer<list<ComponentRef>> cref_ptr;
      Value val;
    algorithm
      // add each equation to a bucket if solved the same way
      for eqn_scal_idx in 1:arrayLength(eqn_to_var) loop
        mode_opt := Adjacency.Modes.get(modes, m, data, ids, eqn_scal_idx, eqn_to_var[eqn_scal_idx]);
        if isSome(mode_opt) then
          mode := Util.getOption(mode_opt);
          eqn_arr_idx := mapping.eqn_StA[eqn_scal_idx];
          multi := Equation.isRecordOrTupleEquation(EquationPointers.getEqnAt(eqns, eqn_arr_idx));
          cref := ComponentRef.EMPTY();
          if multi then
            // add the cref to the result, but remove it from the modes so all modes of a tuple equations are equal
            cref := listHead(mode.crefs);
            mode.crefs := {};
          end if;

          (idx_ptr, cref_ptr, fresh) := getBucket(mode, multi, eqn_arr_idx, per_eqn);
          if fresh then
            order := (mode, multi, idx_ptr, cref_ptr) :: order;
          elseif multi then
            Pointer.update(cref_ptr, cref :: Pointer.access(cref_ptr));
          end if;
          Pointer.update(idx_ptr, eqn_scal_idx :: Pointer.access(idx_ptr));
        end if;
      end for;

      // order holds the buckets newest first, prepending reverses it back
      for bucket in order loop
        (mode, multi, idx_ptr, cref_ptr) := bucket;
        if multi then
          val := Value.MULTI_VAL(Pointer.access(cref_ptr), Pointer.access(idx_ptr));
        else
          val := Value.SINGLE_VAL(listHead(mode.crefs), Pointer.access(idx_ptr));
        end if;
        buckets := (mode, val) :: buckets;
      end for;

      if Flags.isSet(Flags.DUMP_SORTING) then
        for bucket_tpl in buckets loop
          (mode, val) := bucket_tpl;
          print(Mode.toString(mode) + Value.toString(val) + "\n");
        end for;
      end if;
    end create;

    function getBucket
      "Returns the accumulators of this mode's bucket, creating it if the array
      equation does not have one for the mode yet."
      input Mode mode;
      input Boolean multi;
      input Integer eqn_arr_idx;
      input array<list<Bucket>> per_eqn;
      output Pointer<list<Integer>> idx_ptr;
      output Pointer<list<ComponentRef>> cref_ptr;
      output Boolean fresh = false;
    protected
      Mode m;
      Boolean mu;
    algorithm
      for bucket in per_eqn[eqn_arr_idx] loop
        (m, mu, idx_ptr, cref_ptr) := bucket;
        if mu == multi and Mode.isEqual(m, mode) then
          return;
        end if;
      end for;
      idx_ptr := Pointer.create({});
      cref_ptr := Pointer.create(if multi then mode.crefs else {});
      fresh := true;
      arrayUpdate(per_eqn, eqn_arr_idx, (mode, multi, idx_ptr, cref_ptr) :: per_eqn[eqn_arr_idx]);
    end getBucket;

    function filter
      "filters out the indices that are in in the set"
      input output tuple<Mode, Value> tpl;
      input UnorderedSet<Integer> set;
    protected
      Mode mode;
      Value val;
    algorithm
      (mode, val) := tpl;
      val := Value.filter(val, set);
      tpl := (mode, val);
    end filter;

    function relevant
      "returns true if the value has more than one entry"
      input tuple<Mode, Value> tpl;
      output Boolean b;
    protected
      Value val;
    algorithm
      (_, val) := tpl;
      b := List.hasSeveralElements(Value.getEquations(val));
    end relevant;
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
  protected
    Option<Adjacency.Mapping> mapping_opt;
    Option<array<tuple<Integer,Integer>>> eqn_AtS   "eqn: arr_idx -> start_idx/length";
    Option<array<tuple<Integer,Integer>>> var_AtS   "var: arr_idx -> start_idx/length";
  algorithm
    try
      comps := match adj
        local
          list<list<Integer>> comps_indices, phase2_indices;
          Adjacency.Matrix phase2_adj;
          Matching phase2_matching;
          array<SuperNode> super_nodes;
          array<Integer> var_loc;
          list<tuple<Mode, Value>> buckets;

        case Adjacency.Matrix.FINAL() algorithm
          if Flags.isSet(Flags.DUMP_SORTING) then
            print(StringUtil.headline_1("Sorting"));
          end if;

          // phase 1 tarjan
          buckets := PseudoBucket.create(matching.eqn_to_var, eqns, adj.mapping, adj.m, adj.modes);
          comps_indices := tarjanScalar(adj.m, matching);

          // phase 2 tarjan
          (phase2_adj, phase2_matching, super_nodes) := SuperNode.create(adj, adj.mapping, matching, eqns.map, comps_indices, buckets);

          // kabdelhak: this match-statement is superfluous, SuperNode.create always returns these types.
          // it is just safer if something is changed in the future
          () := match phase2_adj
            case Adjacency.Matrix.FINAL() algorithm
              // phase 3 tarjan
              phase2_indices := tarjanScalar(phase2_adj.m, phase2_matching);
              var_loc := arrayCreate(arrayLength(matching.var_to_eqn), 0);
              comps := list(SuperNode.collapse(comp, super_nodes, adj.m, adj.mapping, matching, vars, eqns, var_loc) for comp in phase2_indices);
              GCExt.free(var_loc);
            then ();

            else algorithm
              Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix or matching type."});
            then fail();
          end match;
        then comps;

        // do nothing for empty matrix (empty system)
        case Adjacency.Matrix.EMPTY() then {};

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because adjacency matrix has unknown type."});
        then fail();
      end match;
    else
      mapping_opt := Adjacency.Matrix.getMappingOpt(adj);
      (eqn_AtS, var_AtS) := match mapping_opt
        local
          Adjacency.Mapping mapping;
        case SOME(mapping) then (SOME(mapping.eqn_AtS), SOME(mapping.var_AtS));
        else (NONE(), NONE());
      end match;
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to sort system:\n"
        + VariablePointers.toString(vars, "System", var_AtS) + "\n"
        + EquationPointers.toString(eqns, "System", eqn_AtS) + "\n"
        + Matching.toString(matching)});
      fail();
    end try;
  end tarjan;

  function tarjanScalar
    "author: lochel, kabdelhak
    This sorting algorithm only considers equations e that have a matched variable v with e = var_to_eqn[v]."
    input Adjacency.IntMatrix m           "normal adjacency matrix";
    input Matching matching               "eqn <-> var";
    output list<list<Integer>> comps = {} "eqn indices";
  protected
    Integer index = 0;
    list<Integer> stack = {};
    array<Integer> number, lowlink;
    array<Boolean> onStack;
    array<Integer> data = Adjacency.IntMatrix.entries(m);
    Integer N = arrayLength(matching.var_to_eqn);
    Integer M = arrayLength(matching.eqn_to_var);
    Integer eqn;
  algorithm
    number := arrayCreate(M, -1);
    lowlink := arrayCreate(M, -1);
    onStack := arrayCreate(M, false);

    // loop over all variables and find their component
    for var in 1:N loop
      eqn := matching.var_to_eqn[var];
      if eqn > 0 and number[eqn] == -1 then
        (stack, index, comps) := strongConnect(m, data, matching.var_to_eqn, eqn, stack, index, number, lowlink, onStack, comps);
      end if;
    end for;

    // free auxiliary arrays
    GCExt.free(number);
    GCExt.free(lowlink);
    GCExt.free(onStack);

    // reverse for correct ordering
    comps := listReverse(comps);
  end tarjanScalar;

  type SCC = list<Integer>;

  uniontype LoopIdentifier
    "used to identify algebraic loops that are structurally equal just differ in local indexing"
    record LOOP_IDENTIFIER
      UnorderedSet<Integer> eqns;
      UnorderedSet<Integer> vars;
    end LOOP_IDENTIFIER;

    function hash
      input LoopIdentifier li;
      output Integer i = stringHashDjb2(toString(li));
    end hash;

    function isEqual
      input LoopIdentifier li1;
      input LoopIdentifier li2;
      output Boolean b = UnorderedSet.isEqual(li1.eqns, li2.eqns) and UnorderedSet.isEqual(li1.vars, li2.vars);
    end isEqual;

    function toString
      input LoopIdentifier li;
      output String str;
    algorithm
      str := " eqns: " + UnorderedSet.toString(li.eqns, intString) + "\n vars:" + UnorderedSet.toString(li.vars, intString) + "\n";
    end toString;

    function fromSCC
      input list<Integer> scc;
      input Adjacency.Mapping mapping;
      input Matching matching;
      output LoopIdentifier li;
    algorithm
      li := LOOP_IDENTIFIER(
        eqns = UnorderedSet.fromList(list(mapping.eqn_StA[i] for i in scc), Util.id, intEq),
        vars = UnorderedSet.fromList(list(mapping.var_StA[matching.eqn_to_var[i]] for i in scc), Util.id, intEq));
    end fromSCC;
  end LoopIdentifier;

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
      "increment index by 1 to have it consistent with index plots"
      input SuperNode node;
      output String str;
    algorithm
      str := match node
        case SINGLE()           then "[" + intString(node.index + 1) + "] single ";
        case ELEMENT()          then "[" + intString(node.index + 1) + "] scalar element of (" + intString(node.parent + 1) + ")";
        case ALGEBRAIC_LOOP()   then "[" + intString(node.index + 1) + "] algebraic loop " + List.toString(list(i + 1 for i in node.eqn_indices), intString);
        case ARRAY_BUCKET()     then "[" + intString(node.index + 1) + "] array bucket " + List.toString(list(i + 1 for i in node.eqn_indices), intString);
                                else "ERROR";
      end match;
    end toString;

    function isArrayBucket
      input SuperNode node;
      output Boolean b;
    algorithm
      b := match node
        case ARRAY_BUCKET() then true;
        else false;
      end match;
    end isArrayBucket;

    function getEqnIndices
      input SuperNode node;
      output list<Integer> eqn_indices;
    algorithm
      eqn_indices := match node
        case SINGLE()         then {node.index};
        case ALGEBRAIC_LOOP() then node.eqn_indices;
        case ARRAY_BUCKET()   then node.eqn_indices;
        case ELEMENT() algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because elements should not be accessed, only their parents: " + toString(node)});
        then fail();
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of incorrect super node type."});
        then fail();
      end match;
    end getEqnIndices;

    function create
      input Adjacency.Matrix adj;
      input Adjacency.Mapping mapping;
      input Matching matching;
      input UnorderedMap<ComponentRef, Integer> eqn_map;
      input list<SCC> scc_phase1;
      input list<tuple<Mode, Value>> buck;
      output Adjacency.Matrix phase2_adj = adj;
      output Matching phase2_matching = matching;
      output array<SuperNode> super_nodes;
    protected
      LoopIdentifier li;
      UnorderedMap<LoopIdentifier, SCC> loop_map = UnorderedMap.new<SCC>(LoopIdentifier.hash, LoopIdentifier.isEqual);
      list<SCC> algebraic_loops = list(scc for scc guard List.hasSeveralElements(scc) in scc_phase1);
      list<tuple<Mode, Value>> buckets = buck;
      Mode mode;
      Value val;
      Integer index, shift;
      list<Integer> var_lst, eqn_lst;
      list<list<Integer>> eqn_rows, var_rows, rest_var_rows "the rows merged into one super node, in merge order";
      UnorderedSet<Integer> alg_loop_set = UnorderedSet.new(Util.id, intEq) "the set of indices appearing in algebraic loops";
    algorithm
      phase2_adj := match phase2_adj
        case Adjacency.FINAL() algorithm
          // merge algebraic loops with identical interface (array based)
          // ToDo: proper handling without merging them all and having a for-loop around instead
          for scc in algebraic_loops loop
            li := LoopIdentifier.fromSCC(scc, mapping, matching);
            UnorderedMap.add(li, listAppend(scc, UnorderedMap.getOrDefault(li, loop_map, {})), loop_map);
          end for;
          algebraic_loops := UnorderedMap.valueList(loop_map);

          //### 1. store all loop indices ###
          for scc in algebraic_loops loop for idx in scc loop
            UnorderedSet.add(idx, alg_loop_set);
          end for; end for;

          // remove loop indices from array buckets (so they are not used twice)
          buckets := list(PseudoBucket.filter(bucket_tpl, alg_loop_set) for bucket_tpl in buckets);
          buckets := list(bucket_tpl for bucket_tpl guard(PseudoBucket.relevant(bucket_tpl)) in buckets);
          shift := listLength(algebraic_loops) + listLength(buckets);

          // ### 2. initialize super nodes ###
          super_nodes := arrayCreate(Adjacency.IntMatrix.rows(phase2_adj.m) + shift, SuperNode.SINGLE(0));
          for i in 1:arrayLength(super_nodes) loop
            arrayUpdate(super_nodes, i, SuperNode.SINGLE(i));
          end for;

          // ### 3. expand matching ###
          index := arrayLength(phase2_matching.eqn_to_var);
          phase2_matching.eqn_to_var := Array.expandToSize(arrayLength(phase2_matching.eqn_to_var) + shift, phase2_matching.eqn_to_var, -1);
          for i in index+1:index+shift loop
            phase2_matching.eqn_to_var[i] := i;
          end for;

          index := arrayLength(phase2_matching.var_to_eqn);
          phase2_matching.var_to_eqn := Array.expandToSize(arrayLength(phase2_matching.var_to_eqn) + shift, phase2_matching.var_to_eqn, -1);
          for i in index+1:index+shift loop
            phase2_matching.var_to_eqn[i] := i;
          end for;

          // ### 4. adjust transposed matrix ###
          // 4.1. enlarge transposed matrix by the maximum possible amount of new nodes
          index := Adjacency.IntMatrix.rows(phase2_adj.mT) + 1;
          phase2_adj.mT := Adjacency.IntMatrix.expandRows(phase2_adj.mT, shift);
          eqn_rows := listAppend(algebraic_loops, list(Value.getEquations(Util.tuple22(bucket)) for bucket in buckets));
          var_rows := list(list(phase2_matching.eqn_to_var[idx] for idx in row) for row in eqn_rows);
          Adjacency.IntMatrix.reserveData(phase2_adj.mT, mergedSize(phase2_adj.mT, var_rows));

          // 4.2. merge all algebraic loop variables of one scc to one single variable
          rest_var_rows := var_rows;
          for scc in algebraic_loops loop
            var_lst :: rest_var_rows := rest_var_rows;
            mergeLoopNodes(super_nodes, var_lst, index, false);
            index := mergeRows(phase2_adj.mT, phase2_matching.var_to_eqn, super_nodes, var_lst, index);
          end for;

          // 4.3. merge all array variables of one bucket to one single variable
          for bucket in buckets loop
            (mode, val) := bucket;
            var_lst :: rest_var_rows := rest_var_rows;
            () := match val
              case Value.SINGLE_VAL() algorithm mergeArrayNodes(super_nodes, val.cref_to_solve, var_lst, index, UnorderedMap.getSafe(mode.eqn_name, eqn_map, sourceInfo()), false); then ();
              case Value.MULTI_VAL()  algorithm mergeLoopNodes(super_nodes, var_lst, index, false); then ();
            end match;
            index := mergeRows(phase2_adj.mT, phase2_matching.var_to_eqn, super_nodes, var_lst, index);
          end for;

          /// ### 5. adjust normal matrix ###
          // 5.1. transpose the transposed matrix and enlarge it by the maximum possible amount of new nodes
          index := Adjacency.IntMatrix.rows(phase2_adj.m) + 1;
          phase2_adj.m := Adjacency.IntMatrix.transpose(phase2_adj.mT, Adjacency.IntMatrix.rows(phase2_adj.m) + shift,
                                                        mergedSize(phase2_adj.m, eqn_rows));
          // 5.2 merge all algebraic loop equations of one scc to one single equation
          for scc in algebraic_loops loop
            mergeLoopNodes(super_nodes, scc, index, true);
            index := mergeRows(phase2_adj.m, phase2_matching.eqn_to_var, super_nodes, scc, index);
          end for;

          // 5.3. merge all for-loop equations of one bucket to one single equation
          for bucket in buckets loop
            (mode, val) := bucket;
            eqn_lst := Value.getEquations(val);
            () := match val
              case Value.SINGLE_VAL() algorithm mergeArrayNodes(super_nodes, val.cref_to_solve, eqn_lst, index, UnorderedMap.getSafe(mode.eqn_name, eqn_map, sourceInfo()), true); then ();
              case Value.MULTI_VAL()  algorithm mergeLoopNodes(super_nodes, eqn_lst, index, true); then ();
            end match;
            index := mergeRows(phase2_adj.m, phase2_matching.eqn_to_var, super_nodes, eqn_lst, index);
          end for;

          // phase 3 tarjan only reads phase2_adj.m, so mT is left as it is

        then phase2_adj;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end create;

    function collapse
      input list<Integer> comp_indices;
      input array<SuperNode> super_nodes;
      input Adjacency.IntMatrix m;
      input Adjacency.Mapping mapping;
      input Matching matching;
      input VariablePointers vars;
      input EquationPointers eqns;
      input array<Integer> var_loc  "scratch for getLocalSystem";
      output StrongComponent comp;
    protected
      list<SuperNode> node_comp = list(super_nodes[i] for i in comp_indices);
      list<list<Integer>> sorted_body_components;
      list<Integer> sorted_body_indices;
    algorithm
      comp := match node_comp
        local
          SuperNode node;
          Adjacency.IntMatrix m_local;
          Matching matching_local;
          Boolean indep = true;
          array<Integer> map_back     "local to global equation indices";
          Integer eqn_arr_idx, var_arr_idx;

        // a single scalar equation that has nothing to do with arrays
        case {SINGLE()}
        then StrongComponent.createPseudoScalar(comp_indices, matching.eqn_to_var, mapping, vars, eqns);

        // a single strong component from phase I
        case {node as ALGEBRAIC_LOOP()}
        then StrongComponent.createPseudoScalar(node.eqn_indices, matching.eqn_to_var, mapping, vars, eqns);

        // a single array equation
        case {node as ARRAY_BUCKET()} algorithm
          // sort local system to determine in what order the equations have to be solved
          (m_local, matching_local, map_back) := getLocalSystem(m, matching, node.eqn_indices, var_loc);
          sorted_body_components := tarjanScalar(m_local, matching_local);
          sorted_body_indices := mapFlatten(sorted_body_components, map_back);

          // if new strong components of size > 1 were created it is an error, this should
          // have occured in sorting phase I
          if List.compareLength(sorted_body_components, sorted_body_indices) <> 0 then
            Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName()
              + " crucially failed for the following Phase II strong component"
              + " because the body turned out to still have strong components:\n"
              + List.toString(node_comp, SuperNode.toString, List.Style.NEWLINE_TAB) + "\n"});
          end if;

          // check for independence of the element equations
          // if locally each variable occurs in only one equation, then they are all independent
          indep := Array.all(m_local.len, function intEq(i2 = 1));

          eqn_arr_idx := mapping.eqn_StA[listHead(node.eqn_indices)];
          var_arr_idx := mapping.var_StA[matching.eqn_to_var[listHead(node.eqn_indices)]];
        then StrongComponent.createPseudoSlice(var_arr_idx, eqn_arr_idx, node.cref_to_solve, sorted_body_indices, matching.eqn_to_var, eqns, mapping, indep);

        // entwined equations: at least one array bucket mixed with scalar equations
        case _ guard(List.any(node_comp, isArrayBucket)) algorithm
          // sort local system to determine in what order the equations have to be solved
          (m_local, matching_local, map_back) := getLocalSystem(m, matching, List.flatten(list(getEqnIndices(n) for n in node_comp)), var_loc);
          sorted_body_components := tarjanScalar(m_local, matching_local);
          sorted_body_indices := mapFlatten(sorted_body_components, map_back);
          comp := StrongComponent.createPseudoEntwined(sorted_body_indices, matching.eqn_to_var, mapping, vars, eqns, node_comp);
        then comp;

        // fallback: pure scalar or algebraic loop phase III nodes (body components not actually sorted)
        else algorithm
          sorted_body_indices := List.flatten(list(getEqnIndices(n) for n in node_comp));
        then StrongComponent.createPseudoScalar(sorted_body_indices, matching.eqn_to_var, mapping, vars, eqns);
      end match;
    end collapse;

  protected
    function mapFlatten
      "flattens the components and maps the local indices back to global ones"
      input list<list<Integer>> components;
      input array<Integer> map_back;
      output list<Integer> indices = {};
    algorithm
      for comp in components loop
        for i in comp loop
          indices := map_back[i] :: indices;
        end for;
      end for;
      indices := MetaModelica.Dangerous.listReverseInPlace(indices);
    end mapFlatten;

    function mergedSize
      "how much buffer the merged rows need at most, so that merging them does
      not have to grow it"
      input Adjacency.IntMatrix m;
      input list<list<Integer>> rows;
      output Integer total = 0;
    algorithm
      for row in rows loop
        for idx in row loop
          total := total + m.len[idx];
        end for;
      end for;
    end mergedSize;

    function mergeRows
      input Adjacency.IntMatrix m;
      input array<Integer> matching;
      input array<SuperNode> super_nodes;
      input list<Integer> rows_to_merge;
      input output Integer new_idx;
    protected
      array<Integer> data = Adjacency.IntMatrix.entries(m);
      Integer total = 0, first;
      UnorderedSet<Integer> set;
    algorithm
      // merge all rows to one row. Same set, and so the same row, as
      // unique_list(List.flatten(...)) built, without copying the rows first.
      for idx in rows_to_merge loop
        total := total + m.len[idx];
      end for;
      set := UnorderedSet.new<Integer>(Util.id, intEq, Util.nextPrime(total));
      for idx in rows_to_merge loop
        first := m.start[idx];
        for k in first:first + m.len[idx] - 1 loop
          UnorderedSet.add(data[k], set);
        end for;
      end for;
      Adjacency.IntMatrix.setRow(m, new_idx, UnorderedSet.toList(set));
      // remove the original rows
      for idx in rows_to_merge loop
        Adjacency.IntMatrix.clearRow(m, idx);
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
  function getLocalSystem
    input Adjacency.IntMatrix m           "global adjacency matrix";
    input Matching matching               "global matching";
    input list<Integer> eqn_indices       "global equation indices to keep";
    input array<Integer> var_loc          "scratch: global -> local variable index, all zero on entry and on exit";
    output Adjacency.IntMatrix m_loc      "local adjacency matrix";
    output Matching matching_loc          "local matching";
    output array<Integer> map_back        "local to global equation indices";
  protected
    constant Integer N = listLength(eqn_indices);
    array<Integer> var_to_eqn = arrayCreate(N, -1);
    array<Integer> eqn_to_var = arrayCreate(N, -1);
    array<Integer> data = Adjacency.IntMatrix.entries(m);
    Adjacency.IntMatrix.Builder builder;
    Integer j = 1, row, first, edges = 0, loc, var;
  algorithm
    // map matching from full system and save eqn map back
    map_back := arrayCreate(N, -1);
    for i in eqn_indices loop
      // set equation map (local -> global)
      map_back[j] := i;

      // set var from matching (global -> local)
      var := matching.eqn_to_var[i];
      if var > 0 then
        arrayUpdate(var_loc, var, j);
      end if;

      // set local matching
      eqn_to_var[j] := j;
      var_to_eqn[j] := j;

      j := j + 1;
    end for;
    matching_loc := MATCHING(var_to_eqn, eqn_to_var);

    // filter only local edges of adjacency matrix
    for j in 1:N loop
      edges := edges + m.len[map_back[j]];
    end for;
    builder := Adjacency.IntMatrix.newBuilder(edges);
    for j in 1:N loop
      row   := map_back[j];
      first := m.start[row];
      for k in first + m.len[row] - 1:-1:first loop
        var := data[k];
        loc := if var > 0 then var_loc[var] else 0;
        if loc > 0 then
          Adjacency.IntMatrix.builderAdd(builder, j, loc);
        end if;
      end for;
    end for;
    m_loc := Adjacency.IntMatrix.fromBuilder(builder, N);

    // leave the scratch clean for the next component
    for i in eqn_indices loop
      var := matching.eqn_to_var[i];
      if var > 0 then
        arrayUpdate(var_loc, var, 0);
      end if;
    end for;
  end getLocalSystem;

  function strongConnect
    "author: lochel, kabdelhak"
    input Adjacency.IntMatrix m             "normal adjacency matrix";
    input array<Integer> data               "its entry buffer";
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
    Integer eqn2, cand;
  algorithm
    // Set the depth index for eqn to the smallest unused index
    arrayUpdate(number, eqn, index);
    arrayUpdate(lowlink, eqn, index);
    arrayUpdate(onStack, eqn, true);
    index := index + 1;
    stack := eqn::stack;

    // Consider successors of eqn, without building a list of them per node
    for k in m.start[eqn]:m.start[eqn] + m.len[eqn] - 1 loop
      cand := data[k];
      if cand > 0 then
        eqn2 := var_to_eqn[cand];
        if eqn2 > 0 and eqn2 <> eqn then
          if number[eqn2] == -1 then
            // Successor eqn2 has not yet been visited; recurse on it
            (stack, index, comps) := strongConnect(m, data, var_to_eqn, eqn2, stack, index, number, lowlink, onStack, comps);
            arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], lowlink[eqn2]));
          elseif onStack[eqn2] then
            // Successor eqn2 is in the stack and hence in the current SCC
            arrayUpdate(lowlink, eqn, intMin(lowlink[eqn], number[eqn2]));
          end if;
        end if;
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


  annotation(__OpenModelica_Interface="nbackend");
end NBSorting;

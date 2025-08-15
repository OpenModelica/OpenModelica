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
  import NFFlatten.FunctionTree;

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

    function addEquation
      input output Value val;
      input Integer eqn_idx;
    algorithm
      val := match val
        case SINGLE_VAL() algorithm val.eqn_scal_indices := eqn_idx :: val.eqn_scal_indices; then val;
        case MULTI_VAL()  algorithm val.eqn_scal_indices := eqn_idx :: val.eqn_scal_indices; then val;
      end match;
    end addEquation;

    function addCref
      input output Value val;
      input ComponentRef cref;
    algorithm
      val := match val
        case MULTI_VAL() algorithm val.crefs_to_solve := cref :: val.crefs_to_solve; then val;
        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because trying to add a cref to a single value."});
        then fail();
      end match;
    end addCref;
  end Value;

  package PseudoBucket
    function create
      "recollects subsets of multi-dimensional equations that have to be solved in the same way.
      currently only for loops!"
      input array<Integer> eqn_to_var           "eqn to var matching";
      input EquationPointers eqns;
      input Adjacency.Mapping mapping           "scalar <-> array index mapping";
      input UnorderedMap<Mode.Key, Mode> modes;
      output UnorderedMap<Mode, Value> buckets = UnorderedMap.new<Value>(Mode.hash, Mode.isEqual);
    protected
      Option<Mode> mode_opt;
      Mode mode;
      ComponentRef cref;
    algorithm
      // add each equation to a bucket if solved the same way
      for eqn_scal_idx in 1:arrayLength(eqn_to_var) loop
        mode_opt := UnorderedMap.get((eqn_scal_idx, eqn_to_var[eqn_scal_idx]), modes);
        if Util.isSome(mode_opt) then
          mode := Util.getOption(mode_opt);
          if Equation.isRecordOrTupleEquation(EquationPointers.getEqnAt(eqns, mapping.eqn_StA[eqn_scal_idx])) then
            // add the cref to the result, but remove it from the modes so all modes of a tuple equations are equal
            cref := listHead(mode.crefs);
            mode.crefs := {};
            addMulti(cref, eqn_scal_idx, mode, buckets);
          else
            add(eqn_scal_idx, mode, buckets);
          end if;
        end if;
      end for;

      if Flags.isSet(Flags.DUMP_SORTING) then
        print(UnorderedMap.toString(buckets, Mode.toString, Value.toString) + "\n");
      end if;
    end create;

    function add
      input Integer eqn_scal_idx;
      input Mode mode;
      input UnorderedMap<Mode, Value> buckets;
    protected
      Option<Value> val_opt = UnorderedMap.get(mode, buckets);
      Value val;
    algorithm
      if Util.isSome(val_opt) then
        SOME(val) := val_opt;
        val := Value.addEquation(val, eqn_scal_idx);
        UnorderedMap.add(mode, val, buckets);
      else
        val := Value.SINGLE_VAL(listHead(mode.crefs), {eqn_scal_idx});
        UnorderedMap.addNew(mode, val, buckets);
      end if;
    end add;

    function addMulti
      input ComponentRef cref;
      input Integer eqn_scal_idx;
      input Mode mode;
      input UnorderedMap<Mode, Value> buckets;
    protected
      Option<Value> val_opt = UnorderedMap.get(mode, buckets);
      Value val;
    algorithm
      if Util.isSome(val_opt) then
        SOME(val) := val_opt;
        val := Value.addCref(val, cref);
        val := Value.addEquation(val, eqn_scal_idx);
        UnorderedMap.add(mode, val, buckets);
      else
        val := Value.MULTI_VAL(mode.crefs, {eqn_scal_idx});
        UnorderedMap.addNew(mode, val, buckets);
      end if;
    end addMulti;

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
          Option<StrongComponent> comp_opt;
          Adjacency.Matrix phase2_adj;
          Matching phase2_matching;
          array<SuperNode> super_nodes;
          UnorderedMap<Mode, Value> buckets;

        case Adjacency.Matrix.FINAL() algorithm
          if Flags.isSet(Flags.DUMP_SORTING) then
            print(StringUtil.headline_1("Sorting"));
          end if;

          // phase 1 tarjan
          buckets := PseudoBucket.create(matching.eqn_to_var, eqns, adj.mapping, adj.modes);
          comps_indices := tarjanScalar(adj.m, matching);

          // phase 2 tarjan
          (phase2_adj, phase2_matching, super_nodes) := SuperNode.create(adj, matching, eqns.map, comps_indices, buckets);

          // kabdelhak: this match-statement is superfluous, SuperNode.create always returns these types.
          // it is just safer if something is changed in the future
          () := match phase2_adj
            case Adjacency.Matrix.FINAL() algorithm
              // phase 3 tarjan
              phase2_indices := tarjanScalar(phase2_adj.m, phase2_matching);
              comps := list(SuperNode.collapse(comp, super_nodes, adj.m, adj.mapping, matching, vars, eqns) for comp in phase2_indices);
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
    input array<list<Integer>> m          "normal adjacency matrix";
    input Matching matching               "eqn <-> var";
    output list<list<Integer>> comps = {} "eqn indices";
  protected
    Integer index = 0;
    list<Integer> stack = {};
    array<Integer> number, lowlink;
    array<Boolean> onStack;
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
        (stack, index, comps) := strongConnect(m, matching.var_to_eqn, eqn, stack, index, number, lowlink, onStack, comps);
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
      input Matching matching;
      input UnorderedMap<ComponentRef, Integer> eqn_map;
      input list<list<Integer>> scc_phase1;
      input UnorderedMap<Mode, Value> buck;
      output Adjacency.Matrix phase2_adj = adj;
      output Matching phase2_matching = matching;
      output array<SuperNode> super_nodes;
    protected
      list<list<Integer>> algebraic_loops = list(scc for scc guard List.hasSeveralElements(scc) in scc_phase1);
      list<tuple<Mode, Value>> buckets = UnorderedMap.toList(buck);
      Mode mode;
      Value val;
      Integer index, shift;
      list<Integer> var_lst, eqn_lst;
      UnorderedSet<Integer> alg_loop_set = UnorderedSet.new(Util.id, intEq) "the set of indices appearing in algebraic loops";
    algorithm
      phase2_adj := match phase2_adj
        case Adjacency.FINAL() algorithm
          //### 1. store all loop indices ###
          for scc in algebraic_loops loop for idx in scc loop
            UnorderedSet.add(idx, alg_loop_set);
          end for; end for;

          // remove loop indices from array buckets (so they are not used twice)
          buckets := list(PseudoBucket.filter(bucket_tpl, alg_loop_set) for bucket_tpl in buckets);
          buckets := list(bucket_tpl for bucket_tpl guard(PseudoBucket.relevant(bucket_tpl)) in buckets);
          shift := listLength(algebraic_loops) + listLength(buckets);

          // ### 2. initialize super nodes ###
          super_nodes := listArray(list(SuperNode.SINGLE(i) for i in 1:arrayLength(phase2_adj.m) + shift));

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
          index := arrayLength(phase2_adj.mT) + 1;
          phase2_adj.mT := Adjacency.Matrix.expandMatrix(phase2_adj.mT, shift);

          // 4.2. merge all algebraic loop variables of one scc to one single variable
          for scc in algebraic_loops loop
            var_lst := list(phase2_matching.eqn_to_var[idx] for idx in scc);
            mergeLoopNodes(super_nodes, var_lst, index, false);
            index := mergeRows(phase2_adj.mT, phase2_matching.var_to_eqn, super_nodes, var_lst, index);
          end for;

          // 4.3. merge all array variables of one bucket to one single variable
          for bucket in buckets loop
            (mode, val) := bucket;
            var_lst := list(phase2_matching.eqn_to_var[idx] for idx in Value.getEquations(val));
            _ := match val
              case Value.SINGLE_VAL() algorithm mergeArrayNodes(super_nodes, val.cref_to_solve, var_lst, index, UnorderedMap.getSafe(mode.eqn_name, eqn_map, sourceInfo()), false); then ();
              case Value.MULTI_VAL()  algorithm mergeLoopNodes(super_nodes, var_lst, index, false); then ();
            end match;
            index := mergeRows(phase2_adj.mT, phase2_matching.var_to_eqn, super_nodes, var_lst, index);
          end for;

          /// ### 5. adjust normal matrix ###
          // 5.1. transpose the transposed matrix and enlarge it by the maximum possible amount of new nodes
          index := arrayLength(phase2_adj.m) + 1;
          phase2_adj.m := Adjacency.Matrix.transposeScalar(phase2_adj.mT, arrayLength(phase2_adj.m) + shift);
          // 5.2 merge all algebraic loop equations of one scc to one single equation
          for scc in algebraic_loops loop
            mergeLoopNodes(super_nodes, scc, index, true);
            index := mergeRows(phase2_adj.m, phase2_matching.eqn_to_var, super_nodes, scc, index);
          end for;

          // 5.3. merge all for-loop equations of one bucket to one single equation
          for bucket in buckets loop
            (mode, val) := bucket;
            eqn_lst := Value.getEquations(val);
            _ := match val
              case Value.SINGLE_VAL() algorithm mergeArrayNodes(super_nodes, val.cref_to_solve, eqn_lst, index, UnorderedMap.getSafe(mode.eqn_name, eqn_map, sourceInfo()), true); then ();
              case Value.MULTI_VAL()  algorithm mergeLoopNodes(super_nodes, eqn_lst, index, true); then ();
            end match;
            index := mergeRows(phase2_adj.m, phase2_matching.eqn_to_var, super_nodes, eqn_lst, index);
          end for;

          // 5.4. transpose it back to have it consistent (probably not actually necessary for phase2 tarjan but more safe)
          phase2_adj.mT := Adjacency.Matrix.transposeScalar(phase2_adj.m, arrayLength(phase2_adj.mT));

        then phase2_adj;

        else algorithm
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because of unknown adjacency matrix type."});
        then fail();
      end match;
    end create;

    function collapse
      input list<Integer> comp_indices;
      input array<SuperNode> super_nodes;
      input array<list<Integer>> m;
      input Adjacency.Mapping mapping;
      input Matching matching;
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
          Matching matching_local;
          Boolean indep = true;
          UnorderedSet<Integer> vars_local;
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
          (m_local, matching_local) := BackendUtil.getLocalSystem(m, matching, node.eqn_indices);
          sorted_body_components := tarjanScalar(m_local, matching_local);
          sorted_body_indices := List.flatten(sorted_body_components);
          // if new strong components of size > 1 were created it is an error, this should
          // have occured in sorting phase I
          if List.compareLength(sorted_body_components, sorted_body_indices) <> 0 then
            Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName()
              + " crucially failed for the following Phase II strong component"
              + " because the body turned out to still have strong components:\n"
              + List.toString(node_comp, SuperNode.toString, "", "\t", "\n\t", "\n")});
          end if;

          // check for independence of the element equations
          // if locally each variable occurs in only one equation, then they are all independent
          for i in node.eqn_indices loop
            indep := indep and List.hasOneElement(m_local[i]);
          end for;
          eqn_arr_idx := mapping.eqn_StA[listHead(node.eqn_indices)];
          var_arr_idx := mapping.var_StA[matching.eqn_to_var[listHead(node.eqn_indices)]];
        then StrongComponent.createPseudoSlice(var_arr_idx, eqn_arr_idx, node.cref_to_solve, sorted_body_indices, matching.eqn_to_var, eqns, mapping, indep);

        // entwined array equations
        case _ guard(List.all(node_comp, isArrayBucket)) algorithm
          // sort local system to determine in what order the equations have to be solved
          (m_local, matching_local) := BackendUtil.getLocalSystem(m, matching, List.flatten(list(getEqnIndices(n) for n in node_comp)));
          sorted_body_components := tarjanScalar(m_local, matching_local);
          sorted_body_indices := List.flatten(sorted_body_components);

          if List.compareLength(sorted_body_components, sorted_body_indices) == 0 then
            // create entwined for loop if there was no algebraic loop
            comp := StrongComponent.createPseudoEntwined(sorted_body_indices, matching.eqn_to_var, mapping, vars, eqns, node_comp);
          else
            // create algebraic loop
            comp := StrongComponent.createPseudoScalar(sorted_body_indices, matching.eqn_to_var, mapping, vars, eqns);
          end if;
        then comp;

        // create algebraic loop (body components not actually sorted)
        else algorithm
          sorted_body_indices := List.flatten(list(getEqnIndices(n) for n in node_comp));
        then StrongComponent.createPseudoScalar(sorted_body_indices, matching.eqn_to_var, mapping, vars, eqns);
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
      arrayUpdate(m, new_idx, UnorderedSet.unique_list(List.flatten(list(m[idx] for idx in rows_to_merge)), Util.id, intEq));
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

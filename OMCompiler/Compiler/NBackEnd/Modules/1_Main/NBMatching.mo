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
encapsulated uniontype NBMatching
"file:        NBMatching.mo
 package:     NBMatching
 description: This file contains the functions which perform the matching process;
"
  // self import
  import Matching = NBMatching;
  import GCExt;

protected
  // NF import
  import NFFlatten.FunctionTree;
  import Variable = NFVariable;

  // NB import
  import Adjacency = NBAdjacency;
  import NBEquation.{Equation, EqData, EquationPointer, EquationPointers};
  import Module = NBModule;
  import ResolveSingularities = NBResolveSingularities;
  import Partition = NBPartition;
  import BVariable = NBVariable;
  import NBVariable.{VarData, VariablePointer, VariablePointers};

  // OB import
  import BackendDAEEXT;

  // Util import
  import BackendUtil = NBBackendUtil;
  import Slice = NBSlice;
  import NBSlice.IntLst;
  import StringUtil;
public
  // =======================================
  //                MATCHING
  // =======================================
  record MATCHING
    array<Integer> var_to_eqn   "eqn := var_to_eqn[var]";
    array<Integer> eqn_to_var   "var := eqn_to_var[eqn]";
  end MATCHING;

  constant Matching EMPTY_MATCHING = MATCHING(listArray({}), listArray({}));

  function toString
    input Matching matching;
    input output String str = "";
  algorithm
    str := StringUtil.headline_2(str + "Scalar Matching") + "\n";
    str := str + toStringSingle(matching.var_to_eqn, false) + "\n";
    str := str + toStringSingle(matching.eqn_to_var, true) + "\n";
  end toString;

  function regular
    "author: kabdelhak
    Regular matching algorithm for bipartite graphs by Constantinos C. Pantelides.
    First published in doi:10.1137/0909014"
    input output Matching matching;
    input Adjacency.Matrix adj;
    input Boolean transposed = false        "transpose matching if true";
    input Boolean partially = false         "do not fail on singular partitions and return partial matching if true";
    input Boolean clear = true              "start from scratch if true";
  protected
    list<list<Integer>> marked_eqns;
  algorithm
    (matching, marked_eqns, _, _) := continue_(matching, adj, transposed, clear);
    if not partially and not listEmpty(List.flatten(marked_eqns)) then
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the partition is structurally singular."});
      fail();
    end if;
  end regular;

  function singular
    "author: kabdelhak
    Matching algorithm for bipartite graphs by Constantinos C. Pantelides.
    First published in doi:10.1137/0909014
    In the case of singular partitions in tries to resolve it by applying index reduction
    using the dummy derivative method by Sven E. Mattsson and Gustaf Söderlind
    First published in doi:10.1137/0914043

    algorithm:
      1. apply pantelides but carry list of singular markings (eqs)
         whenever singular - add all current marks to singular markings
      2. if done and not everything is matched -> index reduction / balance initialization
      3. restart matching if step 2. changed the partition
    "
    input output Matching matching;
    input output Adjacency.Matrix adj;
    input output Adjacency.Matrix full;
    input output VariablePointers vars;
    input output EquationPointers eqns;
    input output FunctionTree funcTree;
    input output VarData varData;
    input output EqData eqData;
    input Partition.Kind Kind;
    input Boolean transposed = false        "transpose matching if true";
    input Boolean clear = true              "start from scratch if true";
  protected
    list<list<Integer>> marked_eqns;
    Option<Adjacency.Mapping> mapping;
    Adjacency.MatrixStrictness matrixStrictness;
    Boolean changed;
  algorithm
    // 1. match the partition
    try
      (matching, marked_eqns, mapping, matrixStrictness) := continue_(matching, adj, transposed, clear);
    else
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed to match partition:\n"
        + VariablePointers.toString(vars, "partition vars") + "\n"
        + EquationPointers.toString(eqns, "partition eqns") + "\n"
        + Adjacency.Matrix.toString(adj)});
      fail();
    end try;

    // 2. Resolve singular partitions if necessary
    if Kind == NBPartition.Kind.INI then
      // ####### BALANCE INITIALIZATION #######
      (adj, full, vars, eqns, varData, eqData, funcTree, changed) := ResolveSingularities.balanceInitialization(adj, full, vars, eqns, varData, eqData, funcTree, matching, mapping);
    else
      // ####### INDEX REDUCTION #######
      (adj, full, vars, eqns, varData, eqData, funcTree, changed) := ResolveSingularities.noIndexReduction(adj, full, vars, eqns, varData, eqData, funcTree, matching, mapping);
    end if;

    // 3. Recompute adjacency and restart matching if something changed in step 2.
    if changed then
      // ToDo: keep more of old information by only updating changed stuff
      adj := Adjacency.Matrix.createFull(vars, eqns);
      adj := Adjacency.Matrix.fromFull(adj, vars.map, eqns.map, eqns, matrixStrictness);
      if Kind == NBPartition.Kind.INI then
        // ####### DO NOT REDO BALANCING INITIALIZATION #######
        matching := regular(EMPTY_MATCHING, adj);
      else
        // ####### REDO INDEX REDUCTION IF NECESSARY #######
        (matching, adj, full, vars, eqns, funcTree, varData, eqData) := singular(EMPTY_MATCHING, adj, full, vars, eqns, funcTree, varData, eqData, Kind, transposed);
      end if;
    end if;
  end singular;

  function continue_
    input output Matching matching;
    input Adjacency.Matrix adj;
    input Boolean transposed;
    input Boolean clear;
    output list<list<Integer>> marked_eqns;
    output Option<Adjacency.Mapping> mapping;
    output Adjacency.MatrixStrictness matrixStrictness;
  protected
    array<Integer> var_to_eqn, eqn_to_var;
  algorithm
    // 1. Match the partition
    (matching, marked_eqns, mapping, matrixStrictness) := match adj
      // PSEUDO ARRAY
      case Adjacency.Matrix.FINAL() algorithm
        (var_to_eqn, eqn_to_var) := getAssignments(matching, adj.m, adj.mT);
        (var_to_eqn, eqn_to_var, marked_eqns) := PFPlusExternal(adj.m, var_to_eqn, eqn_to_var, clear);
        matching := MATCHING(var_to_eqn, eqn_to_var);
      then (matching, marked_eqns, SOME(adj.mapping), adj.st);

      // EMPTY
      case Adjacency.Matrix.EMPTY()
      then (EMPTY_MATCHING, {}, NONE(), NBAdjacency.MatrixStrictness.FULL);

      // FAIL
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR, {getInstanceName() + " failed."});
      then fail();
    end match;
  end continue_;

  function getAssignments
    "expands the assignments with -1 if needed"
    input Matching matching;
    input array<list<Integer>> m;
    input array<list<Integer>> mT;
    output array<Integer> var_to_eqn;
    output array<Integer> eqn_to_var;
  protected
    Integer nVars = arrayLength(mT);
    Integer nEqns = arrayLength(m);
  algorithm
    var_to_eqn := Array.expandToSize(nVars, matching.var_to_eqn, -1);
    eqn_to_var := Array.expandToSize(nEqns, matching.eqn_to_var, -1);
  end getAssignments;

  function getMatches
    input Matching matching;
    input Option<Adjacency.Mapping> mapping_opt;
    input VariablePointers variables;
    input EquationPointers equations;
    output list<Slice<VariablePointer>> matched_vars = {}, unmatched_vars = {};
    output list<Slice<EquationPointer>> matched_eqns = {}, unmatched_eqns = {};
  protected
    Adjacency.Mapping mapping;
    UnorderedMap<VariablePointer, IntLst> var_map_matched, var_map_unmatched;
    UnorderedMap<EquationPointer, IntLst> eqn_map_matched, eqn_map_unmatched;
    Pointer<Variable> arr_var;
    Pointer<Equation> arr_eqn;
    Integer start_idx;
  algorithm
    // pseudo array case
    if isSome(mapping_opt) then
      mapping := Util.getOption(mapping_opt);

      var_map_matched   := UnorderedMap.new<IntLst>(BVariable.hash, BVariable.equalName);
      var_map_unmatched := UnorderedMap.new<IntLst>(BVariable.hash, BVariable.equalName);
      eqn_map_matched   := UnorderedMap.new<IntLst>(Equation.hash, Equation.equalName);
      eqn_map_unmatched := UnorderedMap.new<IntLst>(Equation.hash, Equation.equalName);

      // check if variables are matched and sort them accordingly
      for var in 1:arrayLength(matching.var_to_eqn) loop
        arr_var := ExpandableArray.get(mapping.var_StA[var], variables.varArr);
        (start_idx, _) := mapping.var_AtS[mapping.var_StA[var]];
        if matching.var_to_eqn[var] > 0 then
          Slice.addToSliceMap(arr_var, (var - start_idx), var_map_matched);
        else
          Slice.addToSliceMap(arr_var, (var - start_idx), var_map_unmatched);
        end if;
      end for;

      // check if equations are matched and sort them accordingly
      for eqn in 1:arrayLength(matching.eqn_to_var) loop
        arr_eqn := ExpandableArray.get(mapping.eqn_StA[eqn], equations.eqArr);
        (start_idx, _) := mapping.eqn_AtS[mapping.eqn_StA[eqn]];
        if matching.eqn_to_var[eqn] > 0 then
          Slice.addToSliceMap(arr_eqn, (eqn - start_idx), eqn_map_matched);
        else
          Slice.addToSliceMap(arr_eqn, (eqn - start_idx), eqn_map_unmatched);
        end if;
      end for;

      // get the slice lists while sorting indices and simplifying whole slices to {}
      matched_vars    := list(Slice.simplify(slice, function BVariable.size(resize = true)) for slice in Slice.fromMap(var_map_matched));
      unmatched_vars  := list(Slice.simplify(slice, function BVariable.size(resize = true)) for slice in Slice.fromMap(var_map_unmatched));
      matched_eqns    := list(Slice.simplify(slice, function Equation.size(resize = true)) for slice in Slice.fromMap(eqn_map_matched));
      unmatched_eqns  := list(Slice.simplify(slice, function Equation.size(resize = true)) for slice in Slice.fromMap(eqn_map_unmatched));
    else
      // check if variables are matched and sort them accordingly
      for var in 1:arrayLength(matching.var_to_eqn) loop
        if matching.var_to_eqn[var] > 0 then
          matched_vars    := Slice.SLICE(ExpandableArray.get(var, variables.varArr),{}) :: matched_vars;
        else
          unmatched_vars  := Slice.SLICE(ExpandableArray.get(var, variables.varArr),{}) :: unmatched_vars;
        end if;
      end for;

      // check if equations are matched and sort them accordingly
      for eqn in 1:arrayLength(matching.eqn_to_var) loop
        if matching.eqn_to_var[eqn] > 0 then
          matched_eqns    := Slice.SLICE(ExpandableArray.get(eqn, equations.eqArr),{}) :: matched_eqns;
        else
          unmatched_eqns  := Slice.SLICE(ExpandableArray.get(eqn, equations.eqArr),{}) :: unmatched_eqns;
        end if;
      end for;
    end if;
  end getMatches;

protected
  function toStringSingle
    input array<Integer> mapping;
    input Boolean inverse;
    output String str;
  protected
    String head = if inverse then "equation to variable" else "variable to equation";
    String from = if inverse then "eqn" else "var";
    String to   = if inverse then "var" else "eqn";
  algorithm
    str := StringUtil.headline_4(head);
    for i in 1:arrayLength(mapping) loop
      str := str + "\t" + from + " " + intString(i) + " --> " + to + " " + intString(mapping[i]) + "\n";
    end for;
  end toStringSingle;

  // ######################################
  //            SCALAR MATCHING
  // ######################################
  function scalarMatching
    input array<list<Integer>> m;
    input array<list<Integer>> mT;
    input Boolean transposed = false        "transpose matching if true";
    input Boolean partially = false         "do not fail on singular partitions and return partial matching if true";
    output Matching matching;
    // this needs partially = true to get computed. Otherwise it fails on singular partitions
    output list<list<Integer>> marked_eqns = {}   "marked equations for index reduction in the case of a singular partition";
  protected
    Integer nVars = arrayLength(mT), nEqns = arrayLength(m);
    array<Integer> var_to_eqn;
    array<Integer> eqn_to_var;
    array<Boolean> var_marks;
    array<Boolean> eqn_marks;
    Boolean pathFound;
  algorithm
    var_to_eqn := arrayCreate(nVars, -1);
    // loop over all equations and try to find an augmenting path
    // to match each uniquely to a variable
    for eqn in 1:nEqns loop
      var_marks := arrayCreate(nVars, false);
      eqn_marks := arrayCreate(nEqns, false);
      (var_to_eqn, var_marks, eqn_marks, pathFound) := augmentPath(eqn, m, mT, var_to_eqn, var_marks, eqn_marks);
      // if it is not possible index reduction needs to be applied
      if not pathFound then
        if not partially then
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the partition is structurally singular. Index Reduction is not yet supported"});
        elseif transposed then
          // if transposed the variable marks represent equations
          marked_eqns := BackendUtil.findTrueIndices(var_marks) :: marked_eqns;
        else
          marked_eqns := BackendUtil.findTrueIndices(eqn_marks) :: marked_eqns;
        end if;
      end if;
    end for;

    // create inverse matching
    eqn_to_var := arrayCreate(nEqns, -1);
    for var in 1:nVars loop
      if var_to_eqn[var] > 0 then
        eqn_to_var[var_to_eqn[var]] := var;
      end if;
    end for;

    // free auxiliary arrays
    if nEqns > 0 then
      GCExt.free(var_marks);
      GCExt.free(eqn_marks);
    end if;

    // create the matching structure
    matching := if transposed then MATCHING(eqn_to_var, var_to_eqn) else MATCHING(var_to_eqn, eqn_to_var);
  end scalarMatching;

  function augmentPath
    input Integer eqn;
    input array<list<Integer>> m;
    input array<list<Integer>> mT;
    input output array<Integer> var_to_eqn;
    input output array<Boolean> var_marks;
    input output array<Boolean> eqn_marks;
    output Boolean pathFound = false;
  algorithm
    eqn_marks[eqn] := true;
    // loop over each edge and try to find an unmatched variable
    for var in m[eqn] loop
      if var_to_eqn[var] <= 0 then
        pathFound := true;
        var_to_eqn[var] := eqn;
        return;
      end if;
    end for;

    // if no umatched variable can be found, loop over all edges again
    // and try to recursively revoke an old matching decision
    for var in m[eqn] loop
      if not var_marks[var] then
        var_marks[var] := true;
        // recursive call
        (var_to_eqn, var_marks, eqn_marks, pathFound) := augmentPath(var_to_eqn[var], m, mT, var_to_eqn, var_marks, eqn_marks);
        if pathFound then
          var_to_eqn[var] := eqn;
          return;
        end if;
      end if;
    end for;
  end augmentPath;

  function PFPlusExternal
    input array<list<Integer>> m;
    input output array<Integer> ass1;
    input output array<Integer> ass2;
    input Boolean clear;
    // this needs partially = true to get computed. Otherwise it fails on singular partitions
    output list<list<Integer>> marked_eqns = {}   "marked equations for index reduction in the case of a singular partition";
  protected
    Integer n1 = arrayLength(ass1), n2 = arrayLength(ass2), nonZero = BackendUtil.countElem(m);
    Integer cheap = 0, algIndx = 5 "PFPlusExternal index";
  algorithm
    BackendDAEEXT.setAssignment(n2, n1, ass2, ass1);
    BackendDAEEXT.setAdjacencyMatrix(n1, n2, nonZero, m);
    BackendDAEEXT.matching(n1, n2, algIndx, cheap, 1.0, if clear then 1 else 0);
    BackendDAEEXT.getAssignment(ass2, ass1);
  end PFPlusExternal;

  annotation(__OpenModelica_Interface="backend");
end NBMatching;

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

  // SetBased Graph imports
  import NBAdjacency.BipartiteGraph;
  import SBGraph.BipartiteIncidenceList;
  import SBGraph.VertexDescriptor;
  import SBGraph.SetType;
  import SBInterval;
  import SBMultiInterval;
  import SBPWLinearMap;
  import SBSet;
  import NBGraphUtil.{SetVertex, SetEdge};

protected
  // NF import
  import NFFlatten.FunctionTree;
  import Variable = NFVariable;

  // NB import
  import Adjacency = NBAdjacency;
  import NBEquation.{Equation, EqData, EquationPointer, EquationPointers};
  import Module = NBModule;
  import BVariable = NBVariable;
  import NBVariable.{VarData, VariablePointer, VariablePointers};
  import ResolveSingularities = NBResolveSingularities;

  // OB import
  import BackendDAEEXT;

  // Util import
  import BackendUtil = NBBackendUtil;
  import Slice = NBSlice;
  import NBSlice.IntLst;
public
  // =======================================
  //                MATCHING
  // =======================================
  record SCALAR_MATCHING
    array<Integer> var_to_eqn;
    array<Integer> eqn_to_var;
  end SCALAR_MATCHING;

  record ARRAY_MATCHING
    // to fill
  end ARRAY_MATCHING;

  record LINEAR_MATCHING
    array<VertMark> F_marks;
    array<VertMark> U_marks;
    UnorderedMap<EdgeTpl, EdgeMark> E_marks;
  end LINEAR_MATCHING;

  record EMPTY_MATCHING
  end EMPTY_MATCHING;

  function toString
    input Matching matching;
    input output String str = "";
  algorithm
    str := match matching
      case SCALAR_MATCHING() algorithm
        str := StringUtil.headline_2(str + "Scalar Matching") + "\n";
        str := str + toStringSingle(matching.var_to_eqn, false) + "\n";
        str := str + toStringSingle(matching.eqn_to_var, true) + "\n";
      then str;
      case LINEAR_MATCHING() algorithm
        str := StringUtil.headline_2(str + "Linear Matching") + "\n";
        str := str + vertMarkArrString(matching.F_marks, "F", "EQN") + "\n";
        str := str + vertMarkArrString(matching.U_marks, "U", "VAR") + "\n";
        str := str + edgeMapString(matching.E_marks, arrayLength(matching.F_marks)) + "\n";
      then str;
      case ARRAY_MATCHING() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
      then fail();
      case EMPTY_MATCHING() then StringUtil.headline_2(str + "Empty Matching") + "\n";
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end toString;

  function regular
    "author: kabdelhak
    Regular matching algorithm for bipartite graphs by Constantinos C. Pantelides.
    First published in doi:10.1137/0909014"
    input output Matching matching;
    input Adjacency.Matrix adj;
    input Boolean transposed = false        "transpose matching if true";
    input Boolean partially = false         "do not fail on singular systems and return partial matching if true";
    input Boolean clear = true              "start from scratch if true";
  protected
    list<list<Integer>> marked_eqns;
  algorithm
    (matching, marked_eqns, _, _, _) := continue_(matching, adj, transposed, clear);
    if not partially and not listEmpty(List.flatten(marked_eqns)) then
      Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the system is strcturally singular."});
      fail();
    end if;
  end regular;

  function singular
    "author: kabdelhak
    Matching algorithm for bipartite graphs by Constantinos C. Pantelides.
    First published in doi:10.1137/0909014
    In the case of singular systems in tries to resolve it by applying index reduction
    using the dummy derivative method by Sven E. Mattsson and Gustaf Söderlind
    First published in doi:10.1137/0914043

    algorithm:
      1. apply pantelides but carry list of singular markings (eqs)
         whenever singular - add all current marks to singular markings
      2. if done and not everything is matched -> index reduction / balance initialization
      3. restart matching if step 2. changed the system
    "
    input output Matching matching;
    input output Adjacency.Matrix adj;
    input output VariablePointers vars;
    input output EquationPointers eqns;
    input output FunctionTree funcTree;
    input output VarData varData;
    input output EqData eqData;
    input Boolean transposed = false        "transpose matching if true";
    input Boolean partially = false         "do not resolve singular systems and return partial matching if true";
    input Boolean clear = true              "start from scratch if true";
  protected
    list<list<Integer>> marked_eqns;
    Option<Adjacency.Mapping> mapping;
    Adjacency.MatrixType matrixType;
    Adjacency.MatrixStrictness matrixStrictness;
    Boolean changed;
  algorithm
    // 1. match the system
    (matching, marked_eqns, mapping, matrixType, matrixStrictness) := continue_(matching, adj, transposed, clear);

    // 2. Resolve singular systems if necessary
    changed := match matrixStrictness
      case NBAdjacency.MatrixStrictness.INIT algorithm
        // ####### BALANCE INITIALIZATION #######
        (vars, eqns, varData, eqData, funcTree, changed) := ResolveSingularities.balanceInitialization(vars, eqns, varData, eqData, funcTree, mapping, matrixType, matching);
      then changed;

      else algorithm
        // ####### INDEX REDUCTION #######
        (vars, eqns, varData, eqData, funcTree, changed) := ResolveSingularities.indexReduction(vars, eqns, varData, eqData, funcTree, mapping, matrixType, marked_eqns);
      then changed;
    end match;

    // 3. Recompute adjacency and restart matching if something changed in step 2.
    if changed then
      // ToDo: keep more of old information by only updating changed stuff
      adj := Adjacency.Matrix.create(vars, eqns, matrixType, matrixStrictness);
      (matching, adj, vars, eqns, funcTree, varData, eqData) := singular(EMPTY_MATCHING(), adj, vars, eqns, funcTree, varData, eqData, false, true);
    end if;
  end singular;

  function continue_
    input output Matching matching;
    input Adjacency.Matrix adj;
    input Boolean transposed;
    input Boolean clear;
    output list<list<Integer>> marked_eqns;
    output Option<Adjacency.Mapping> mapping;
    output Adjacency.MatrixType matrixType;
    output Adjacency.MatrixStrictness matrixStrictness;
  protected
    array<Integer> var_to_eqn, eqn_to_var;
  algorithm
    // 1. Match the system
    (matching, marked_eqns, mapping, matrixType, matrixStrictness) := match adj
      // SCALAR
      case Adjacency.Matrix.SCALAR_ADJACENCY_MATRIX() algorithm
        (var_to_eqn, eqn_to_var) := getAssignments(matching, adj.m, adj.mT);
        if not transposed then
          (var_to_eqn, eqn_to_var, marked_eqns) := PFPlusExternal(adj.m, var_to_eqn, eqn_to_var, clear);
        else
          (eqn_to_var, var_to_eqn, marked_eqns) := PFPlusExternal(adj.mT, eqn_to_var, var_to_eqn, clear);
        end if;
        matching := SCALAR_MATCHING(var_to_eqn, eqn_to_var);
      then (matching, marked_eqns, NONE(), NBAdjacency.MatrixType.SCALAR, adj.st);

      // PSEUDO ARRAY
      case Adjacency.Matrix.PSEUDO_ARRAY_ADJACENCY_MATRIX() algorithm
        (var_to_eqn, eqn_to_var) := getAssignments(matching, adj.m, adj.mT);
        //if not transposed then
          (var_to_eqn, eqn_to_var, marked_eqns) := PFPlusExternal(adj.m, var_to_eqn, eqn_to_var, clear);
        //else
          //(eqn_to_var, var_to_eqn, marked_eqns) := PFPlusExternal(adj.mT, eqn_to_var, var_to_eqn, clear);
        //end if;
        matching := SCALAR_MATCHING(var_to_eqn, eqn_to_var);
      then (matching, marked_eqns, SOME(adj.mapping), NBAdjacency.MatrixType.PSEUDO, adj.st);

      // ARRAY
      case Adjacency.Matrix.ARRAY_ADJACENCY_MATRIX() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
      then fail();

      // EMPTY
      case Adjacency.Matrix.EMPTY_ADJACENCY_MATRIX()
      then (EMPTY_MATCHING(), {}, NONE(), NBAdjacency.MatrixType.SCALAR, NBAdjacency.MatrixStrictness.FULL);

      // FAIL
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end continue_;

  function linear
    input Adjacency.Matrix adj;
    output Matching matching;
  algorithm
    matching := match adj

      case Adjacency.Matrix.SCALAR_ADJACENCY_MATRIX()
      then linearScalar(adj.m, adj.mT);

      case Adjacency.Matrix.ARRAY_ADJACENCY_MATRIX() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() +
        " failed because array linear matching is not yet supported."});
      then fail();

      case Adjacency.Matrix.EMPTY_ADJACENCY_MATRIX() then EMPTY_MATCHING();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end linear;

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
    (var_to_eqn, eqn_to_var) := match matching
      case EMPTY_MATCHING()
      then (arrayCreate(nVars, -1), arrayCreate(nEqns, -1));

      case SCALAR_MATCHING(var_to_eqn = var_to_eqn, eqn_to_var = eqn_to_var)
      then(Array.expandToSize(nVars, var_to_eqn, -1), Array.expandToSize(nEqns, eqn_to_var, -1));

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed. Not implemented for: \n" + toString(matching)});
      then fail();
    end match;
  end getAssignments;

  function getMatches
    input Matching matching;
    input Option<Adjacency.Mapping> mapping_opt;
    input VariablePointers variables;
    input EquationPointers equations;
    output list<Slice<VariablePointer>> matched_vars = {}, unmatched_vars = {};
    output list<Slice<EquationPointer>> matched_eqns = {}, unmatched_eqns = {};
  algorithm
    _ := match (matching, mapping_opt)
      local
        Adjacency.Mapping mapping;
        UnorderedMap<VariablePointer, IntLst> var_map_matched, var_map_unmatched;
        UnorderedMap<EquationPointer, IntLst> eqn_map_matched, eqn_map_unmatched;
        Pointer<Variable> arr_var;
        Pointer<Equation> arr_eqn;

      case (SCALAR_MATCHING(), NONE()) algorithm
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
      then ();

      // pseudo array case
      case (SCALAR_MATCHING(), SOME(mapping)) algorithm
        var_map_matched   := UnorderedMap.new<IntLst>(BVariable.hash, BVariable.equalName);
        var_map_unmatched := UnorderedMap.new<IntLst>(BVariable.hash, BVariable.equalName);
        eqn_map_matched   := UnorderedMap.new<IntLst>(Equation.hash, Equation.equalName);
        eqn_map_unmatched := UnorderedMap.new<IntLst>(Equation.hash, Equation.equalName);

        // check if variables are matched and sort them accordingly
        for var in 1:arrayLength(matching.var_to_eqn) loop
          arr_var := ExpandableArray.get(mapping.var_StA[var], variables.varArr);
          if matching.var_to_eqn[var] > 0 then
            Slice.addToSliceMap(arr_var, var, var_map_matched);
          else
            Slice.addToSliceMap(arr_var, var, var_map_unmatched);
          end if;
        end for;

        // check if equations are matched and sort them accordingly
        for eqn in 1:arrayLength(matching.eqn_to_var) loop
          arr_eqn := ExpandableArray.get(mapping.eqn_StA[eqn], equations.eqArr);
          if matching.eqn_to_var[eqn] > 0 then
            Slice.addToSliceMap(arr_eqn, eqn, eqn_map_matched);
          else
            Slice.addToSliceMap(arr_eqn, eqn, eqn_map_unmatched);
          end if;
        end for;

        // get the slice lists while sorting indices and simplifying whole slices to {}
        matched_vars    := list(Slice.simplify(slice, BVariable.size) for slice in Slice.fromMap(var_map_matched));
        unmatched_vars  := list(Slice.simplify(slice, BVariable.size) for slice in Slice.fromMap(var_map_unmatched));
        matched_eqns    := list(Slice.simplify(slice, Equation.size) for slice in Slice.fromMap(eqn_map_matched));
        unmatched_eqns  := list(Slice.simplify(slice, Equation.size) for slice in Slice.fromMap(eqn_map_unmatched));
      then ();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because arrays are not yet supported."});
      then fail();
    end match;
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
    input Boolean partially = false         "do not fail on singular systems and return partial matching if true";
    output Matching matching;
    // this needs partially = true to get computed. Otherwise it fails on singular systems
    output list<list<Integer>> marked_eqns = {}   "marked equations for index reduction in the case of a singular system";
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
          Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because the system is structurally singular. Index Reduction is not yet supported"});
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
    matching := if transposed then SCALAR_MATCHING(eqn_to_var, var_to_eqn) else SCALAR_MATCHING(var_to_eqn, eqn_to_var);
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
    // this needs partially = true to get computed. Otherwise it fails on singular systems
    output list<list<Integer>> marked_eqns = {}   "marked equations for index reduction in the case of a singular system";
  protected
    Integer n1 = arrayLength(ass1), n2 = arrayLength(ass2), nonZero = BackendUtil.countElem(m);
    Integer cheap = 0, algIndx = 5 "PFPlusExternal index";
  algorithm
    BackendDAEEXT.setAssignment(n2, n1, ass2, ass1);
    BackendDAEEXT.setAdjacencyMatrix(n1, n2, nonZero, m);
    BackendDAEEXT.matching(n1, n2, algIndx, cheap, 1.0, if clear then 1 else 0);
    BackendDAEEXT.getAssignment(ass2, ass1);
  end PFPlusExternal;

  // ######################################
  //            LINEAR MATCHING
  // ######################################
  type VertMark = enumeration(UNPROCESSED, VISITED, LOOP, LOOP_END, MATCHED, TRUE_LOOP);
  type EdgeMark = enumeration(UNPROCESSED, VISITED, LOOP, MATCHED, UNMATCHED, TRUE_LOOP);
  type EdgeTpl = tuple<Integer, Integer>;

  function vertMarkString
    input VertMark vm;
    output String str;
  algorithm
    str := match vm
      case VertMark.UNPROCESSED then "(0) UNPROCESSED";
      case VertMark.VISITED     then "(1) VISITED";
      case VertMark.LOOP        then "(2) LOOP";
      case VertMark.LOOP_END    then "(2) LOOP_END";
      case VertMark.MATCHED     then "(3) MATCHED";
      case VertMark.TRUE_LOOP   then "(3) TRUE_LOOP";
                                else "(-) UNKNOWN";
    end match;
  end vertMarkString;

  function edgeMarkString
    input EdgeMark em;
    output String str;
  algorithm
    str := match em
      case EdgeMark.UNPROCESSED then "(0) UNPROCESSED";
      case EdgeMark.VISITED     then "(1) VISITED";
      case EdgeMark.LOOP        then "(2) LOOP";
      case EdgeMark.MATCHED     then "(3) MATCHED";
      case EdgeMark.UNMATCHED   then "(3) UNMATCHED";
      case EdgeMark.TRUE_LOOP   then "(3) TRUE_LOOP";
                                else "(-) UNKNOWN";
    end match;
  end edgeMarkString;

  function vertMarkArrString
    input array<VertMark> vms;
    input String head;
    input String tp;
    output String str = "";
  protected
    String tmp;
  algorithm
    str := StringUtil.headline_4(head + "-Vertices") + "\n";
    for i in 1:arrayLength(vms) loop
      tmp := "[" + tp + ":" + intString(i) + "] ";
      str := str + tmp + StringUtil.repeat(".", 20 - stringLength(tmp)) + " " + vertMarkString(vms[i]) + "\n";
    end for;
  end vertMarkArrString;

  function edgeTplString
    input EdgeTpl et;
    input Integer F_size;
    output String str;
  protected
    Integer l, r;
  algorithm
    (l, r) := et;
    str := "(" + intString(intMin(l,r)) + ", " + intString(intMax(l,r) - F_size) + ")";
  end edgeTplString;

  function edgeMapString
    input UnorderedMap<EdgeTpl, EdgeMark> map;
    input Integer F_size;
    output String str = StringUtil.headline_4(str + "Edges") + "\n" +
      UnorderedMap.toString(map, function edgeTplString(F_size = F_size), edgeMarkString);
  end edgeMapString;

  function hashEdgeTpl
    "returns the hash value of an edge tpl
     (a, b) == (b, a) -> same hash!"
    input EdgeTpl tpl;
    input Integer mod;
    output Integer hash;
  protected
    Integer l, r;
  algorithm
    (l, r) := tpl;
    hash := intMod(intBitXor(l,r), mod);
  end hashEdgeTpl;

  function eqEdgeTpl
    "returns if two edge tuples are equal
     (a, b) == (b, a) !"
    input EdgeTpl tpl1;
    input EdgeTpl tpl2;
    output Boolean b;
  protected
    Integer l1,l2,r1,r2;
  algorithm
    (l1,r1) := tpl1;
    (l2,r2) := tpl2;
    b := ((l1 == l2) and (r1 == r2)) or ((l1 == r2) and (r1 == l2));
  end eqEdgeTpl;

  function linearScalar
    "linear with respect to the number of edges.
    Performs a deep search, matching the disambigous parts first and causalizing the rest on the base
    of it in backwards mode. Does not match the ambigous part, rather keeps it in bulk as an
    algebraic loop. Implicitely also computes the Sorting."
    input array<list<Integer>> m;
    input array<list<Integer>> mT;
    output Matching matching;
  protected
    Integer F_size = arrayLength(m);
    Integer U_size = arrayLength(mT);
    array<VertMark> F_marks = arrayCreate(F_size, VertMark.UNPROCESSED);
    array<VertMark> U_marks = arrayCreate(U_size, VertMark.UNPROCESSED);
    UnorderedMap<EdgeTpl, EdgeMark> E_marks = UnorderedMap.new<EdgeMark>(hashEdgeTpl, eqEdgeTpl);
    array<list<Integer>> F_loop_ind = arrayCreate(F_size, {});
    array<list<Integer>> U_loop_ind = arrayCreate(U_size, {});
  algorithm
    // initialize edge marks
    for f in 1:F_size loop
      for u in m[f] loop
        // all U indices must be shifted to start at the end of the F indices
        UnorderedMap.add((f, u + F_size), EdgeMark.UNPROCESSED, E_marks);
      end for;
    end for;

    // main routine
    for f in 1:F_size loop
      if F_marks[f] == VertMark.UNPROCESSED then
        F_marks[f] := VertMark.VISITED;
        // causalize the cluster containing f
        // output not needed, F_marks, U_marks and E_marks contain relevant information
        LMcluster(f, m, mT, 0, F_size, F_marks, U_marks, E_marks, F_loop_ind, U_loop_ind, {});
      end if;
    end for;

    matching := LINEAR_MATCHING(F_marks, U_marks, E_marks);
  end linearScalar;

  function LMcluster
    "Matches one connected cluster by deep search.
    The vertex and edge marks are mutable and contain the result.
    Every recursive call (LMcluster, LMtrueLoop, LMfalseLoop) swaps the
    objects with 1 or 2 suffixes to change from one side of the
    bipartite graph to the other side.
    SUFFIX 1 -> use node as input
    SUFFIX 2 -> use neighbor as input
    Tail recursive."
    input Integer node                              "head vertex of current stack (F or U)";
    input array<list<Integer>> m1                   "current adjacency matrix (takes node as input)";
    input array<list<Integer>> m2                   "current transposed adjacency matrix (takes neighbors of node as input)";
    input Integer shift1                            "index shift for node";
    input Integer shift2                            "index shift for neighbors of node";
    input array<VertMark> marks1                    "vertex marks for node side";
    input array<VertMark> marks2                    "vertex marks for neigbors of node";
    input UnorderedMap<EdgeTpl, EdgeMark> E_marks   "edge marks";
    input array<list<Integer>> loop_ind1            "loop indices for each vertex (node side)";
    input array<list<Integer>> loop_ind2            "loop indices for each vertex (neighbor of node side)";
    input list<Integer> in_stack                    "current stack of vertices";
  protected
    list<Integer> stack = in_stack;                   // map input to new list so that we can manipulate it
    Boolean foundPath = false, foundLoop = false;
    list<Integer> Alpha = {}, Omega = {}, indices = {};
    Integer neighbor;
  algorithm
    // check if there is an unprocessed path to go from here
    for neighbor in m1[node] loop
      if marks2[neighbor] == VertMark.UNPROCESSED then // check for edge? should not be necessary
        stack := node :: stack;
        arrayUpdate(marks2, neighbor, VertMark.VISITED);
        UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.VISITED, E_marks);
        foundPath := true;
        break;
      end if;
    end for;

    if foundPath then
      // FORWARD STEP
      // do nothing just skip the rest
    elseif listEmpty(stack) then
      // END
      // whole cluster has been traversed and the stack is back to being empty
      // THIS IS THE ONLY EXIT CONDITION BESIDES ERRORS
      return;
    else
      // REVERSE STEP
      // either a loop has been found or a matching path is built backwards
      // take last node from stack
      neighbor :: stack := stack;

      if marks1[node] < VertMark.MATCHED then // TRUE_LOOP mit loop_ind -> do it NO!
        // check if it is a loop
        (Alpha, Omega) := LMgetLoopVertices(node, m1, shift1, shift2, marks2, E_marks);
        foundLoop := not(listEmpty(Alpha) and listEmpty(Omega));
      end if;

      if foundLoop then
        // suspected loop initiator

        // create a unique index for each new created loop and collect the indices
        for recursion_node in Alpha loop
          UnorderedMap.add((node + shift1, recursion_node + shift2), EdgeMark.LOOP, E_marks);
          arrayUpdate(marks2, recursion_node, VertMark.LOOP_END);
          indices := recursion_node :: indices;
        end for;

        // collect all loop indices that are additionally connected
        for recursion_node in Omega loop
          UnorderedMap.add((node + shift1, recursion_node + shift2), EdgeMark.LOOP, E_marks);
          indices := listAppend(loop_ind2[recursion_node], indices);
        end for;

        UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.LOOP, E_marks);
        arrayUpdate(marks1, node, VertMark.LOOP);
        arrayUpdate(loop_ind1, node, indices);
        arrayUpdate(marks2, neighbor, VertMark.LOOP);
        arrayUpdate(loop_ind2, neighbor, indices);
      else
        // general backwards step
        _ := match (marks1[node], marks2[neighbor])
          case (VertMark.LOOP_END, _) algorithm
            // closed a loop
            // -> mark everything as true loop
            arrayUpdate(marks1, node, VertMark.TRUE_LOOP);
            LMtrueLoop(node, m1, m2, shift1, shift2, marks1, marks2, E_marks, loop_ind1, loop_ind2, node);
            if listEmpty(loop_ind1[node]) then
              // just closed a loop in the last step and no unresolved loops left
              // -> normal matching mode starting with UNMATCHED
              UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.UNMATCHED, E_marks);
            else
              // just closed a loop in the last step but there are still unresolved
              // loops on the path saved as indices
              // temporary loop mode and no other paths open
              // -> mark last edge and node as LOOP and carry the loop indices
              UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.LOOP, E_marks);
              arrayUpdate(marks2, neighbor, VertMark.LOOP);
              arrayUpdate(loop_ind2, neighbor, loop_ind1[node]);
            end if;
          then ();

          case (VertMark.LOOP, VertMark.LOOP) algorithm
            // carry a loop to a node that is already part of a loop
            // -> mark last edge LOOP and add the loop indices
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.LOOP, E_marks);
            arrayUpdate(loop_ind2, neighbor, listAppend(loop_ind2[neighbor], loop_ind1[node]));
          then ();

          case (VertMark.LOOP, VertMark.LOOP_END) algorithm
            // carry a loop to a node that is already part of a loop
            // -> mark last edge LOOP and add the loop indices
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.LOOP, E_marks);
            arrayUpdate(loop_ind2, neighbor, listAppend(loop_ind2[neighbor], loop_ind1[node]));
          then ();

          case (VertMark.LOOP, VertMark.MATCHED) algorithm
            // carry a loop to a node that is already matched
            // -> go forward again and resolve the causalization
            LMfalseLoop(neighbor, m2, m1, shift2, shift1, marks2, marks1, E_marks, loop_ind2, loop_ind1, EdgeMark.UNMATCHED);
          then ();

          case (VertMark.LOOP, VertMark.VISITED) algorithm
            // temporary loop mode and no other paths open
            // -> mark last edge and node as LOOP and carry the loop indices
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.LOOP, E_marks);
            arrayUpdate(marks2, neighbor, VertMark.LOOP);
            arrayUpdate(loop_ind2, neighbor, loop_ind1[node]);
          then ();

          case (VertMark.MATCHED , VertMark.VISITED) algorithm
            // just set an edge to MATCHED in the last step and no other paths open
            // -> normal matching mode starting with UNMATCHED
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.UNMATCHED, E_marks);
          then ();

          case (VertMark.MATCHED , VertMark.LOOP_END) algorithm
            // just set an edge to MATCHED in the last step and no other paths open
            // -> normal matching mode starting with UNMATCHED
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.UNMATCHED, E_marks);
          then ();

          case (VertMark.MATCHED , VertMark.MATCHED) algorithm
            // just set an edge to MATCHED in the last step and no other paths open
            // -> normal matching mode starting with UNMATCHED
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.UNMATCHED, E_marks);
          then ();

          case (_, VertMark.MATCHED) algorithm
            // trying to match a variable that is already matched
            // ERROR: -> more analysis needed to decide if index reduction case
            Error.assertion(false, getInstanceName() + " failed. It was trying to match an already matched node.
              Index reduction not yet implemented.", sourceInfo());
          then fail();

          case (_, VertMark.TRUE_LOOP) algorithm
            // trying to match a variable that is already part of an algebraic loop
            // ERROR: -> more analysis needed to decide if index reduction case
            Error.assertion(false, getInstanceName() + " failed. It was trying to match a node already assigned to an algebraic loop.
              Index reduction not yet implemented.", sourceInfo());
          then fail();

          case (VertMark.VISITED, VertMark.LOOP) algorithm
            // suspected loop is not a loop
            // -> break open due to new information causalizing it
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.MATCHED, E_marks);
            arrayUpdate(marks1, node, VertMark.MATCHED);
            arrayUpdate(marks2, neighbor, VertMark.MATCHED);
            LMfalseLoop(neighbor, m2, m1, shift2, shift1, marks2, marks1, E_marks, loop_ind2, loop_ind1, EdgeMark.UNMATCHED);
          then ();

          case (VertMark.VISITED, VertMark.LOOP_END) algorithm
            // suspected loop is not a loop
            // -> break open due to new information causalizing it
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.MATCHED, E_marks);
            arrayUpdate(marks1, node, VertMark.MATCHED);
            arrayUpdate(marks2, neighbor, VertMark.MATCHED);
            LMfalseLoop(neighbor, m2, m1, shift2, shift1, marks2, marks1, E_marks, loop_ind2, loop_ind1, EdgeMark.UNMATCHED);
          then ();

          case (VertMark.VISITED, VertMark.VISITED) algorithm
            // just set an edge to UNMATCHED in the last step and no other paths open
            // -> normal matching mode starting with MATCHED
            UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.MATCHED, E_marks);
            arrayUpdate(marks1, node, VertMark.MATCHED);
            arrayUpdate(marks2, neighbor, VertMark.MATCHED);
          then ();

          else algorithm
            Error.assertion(false, getInstanceName() + " failed. Unknown case of : ("
              + vertMarkString(marks1[node]) + ", " + vertMarkString(marks2[neighbor]) + ")", sourceInfo());
          then fail();

        end match;
      end if;
    end if;

    // NEXT STEP
    // propagate the information, but swap all objects with 1 and 2 suffixes (from F to U and back)
    // no need to implement it twice, the only difference is for a singular case (index reduction)
    LMcluster(neighbor, m2, m1, shift2, shift1, marks2, marks1, E_marks, loop_ind2, loop_ind1, stack);
  end LMcluster;

  function LMgetLoopVertices
    "initiates suspected loop chains by collecting all edges that would close loops"
    input Integer node                              "head vertex of current stack (F or U)";
    input array<list<Integer>> m                    "current adjacency matrix (takes node as input)";
    input Integer shift1                            "index shift for node";
    input Integer shift2                            "index shift for neighbors of node";
    input array<VertMark> marks2                    "vertex marks for neigbors of node";
    input UnorderedMap<EdgeTpl, EdgeMark> E_marks   "edge marks";
    output list<Integer> Alpha = {}                "list of neighbors that will be new loop ends";
    output list<Integer> Omega = {}                "list of neighbors that already are part of a loop";
  algorithm
    for neighbor in m[node] loop
      _ := match UnorderedMap.get((node + shift1, neighbor + shift2), E_marks)
        local
          EdgeMark edgeMark;
        case SOME(edgeMark) guard(edgeMark == EdgeMark.UNPROCESSED) algorithm
          if marks2[neighbor] == VertMark.VISITED then
            Alpha := neighbor :: Alpha;
          elseif marks2[neighbor] == VertMark.LOOP or marks2[neighbor] == VertMark.LOOP_END then
            Omega := neighbor :: Omega;
          end if;
        then ();
        else (); // NONE() case should actually fail because the edge at least has to exist
      end match;
    end for;
  end LMgetLoopVertices;

  function LMtrueLoop
    "Closes loops given by a list of indices starting at node. Marks
    all nodes with any of these indices and connected to the start node
    by LOOP edges with TRUE_LOOP."
    input Integer node                              "node which is part of a loop";
    input array<list<Integer>> m1                   "current adjacency matrix (takes node as input)";
    input array<list<Integer>> m2                   "current transposed adjacency matrix (takes neighbors of node as input)";
    input Integer shift1                            "index shift for node";
    input Integer shift2                            "index shift for neighbors of node";
    input array<VertMark> marks1                    "vertex marks for node side";
    input array<VertMark> marks2                    "vertex marks for neigbors of node";
    input UnorderedMap<EdgeTpl, EdgeMark> E_marks   "edge marks";
    input array<list<Integer>> loop_ind1            "loop indices for each vertex (node side)";
    input array<list<Integer>> loop_ind2            "loop indices for each vertex (neighbor of node side)";
    input Integer index                             "index of current loop that is resolved";
  algorithm
    for next in m1[node] loop
      if List.contains(loop_ind2[next], index, intEq) then
        UnorderedMap.add((node + shift1, next + shift2), EdgeMark.TRUE_LOOP, E_marks);
        arrayUpdate(marks2, next, VertMark.TRUE_LOOP);
        arrayUpdate(loop_ind2, next, {});
        LMtrueLoop(next, m2, m1, shift2, shift1, marks2, marks1, E_marks, loop_ind2, loop_ind1, index);
      end if;
    end for;

  end LMtrueLoop;

  function LMfalseLoop
    "Destroys a chain that was suspected to be a loop but was proven to not be an algebraic loop
    Starts with node and UNMATCHED context, swaps back and forth until it is ambigous."
    input Integer node                              "node which is suspected to not be part of a loop";
    input array<list<Integer>> m1                   "current adjacency matrix (takes node as input)";
    input array<list<Integer>> m2                   "current transposed adjacency matrix (takes neighbors of node as input)";
    input Integer shift1                            "index shift for node";
    input Integer shift2                            "index shift for neighbors of node";
    input array<VertMark> marks1                    "vertex marks for node side";
    input array<VertMark> marks2                    "vertex marks for neigbors of node";
    input UnorderedMap<EdgeTpl, EdgeMark> E_marks   "edge marks";
    input array<list<Integer>> loop_ind1            "loop indices for each vertex (node side)";
    input array<list<Integer>> loop_ind2            "loop indices for each vertex (neighbor of node side)";
    input EdgeMark e_mark                           "edge mark to state the current context (matching or unmatching mode)";
  protected
    list<Integer> Omega = {};
    Integer neighbor;
  algorithm
    // GO DEEPER! destroy all who only have indices of the starting node
    // collect all adjacent LOOP edges
    for neighbor in m1[node] loop
      _ := match UnorderedMap.get((node + shift1, neighbor + shift2), E_marks)
        local
          EdgeMark edgeMark;
        case SOME(edgeMark) guard(edgeMark == EdgeMark.LOOP) algorithm
          Omega := neighbor :: Omega;
        then ();
        else ();
      end match;
    end for;

    if e_mark == EdgeMark.UNMATCHED then
      // unmatching mode
      // set all connected edges to unmatched and recurse for each of them
      for neighbor in Omega loop
        UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.UNMATCHED, E_marks);
        // only go further if node is not known to be part of a loop
        if marks2[neighbor] <> VertMark.TRUE_LOOP then
          LMfalseLoop(neighbor, m2, m1, shift2, shift1, marks2, marks1, E_marks, loop_ind2, loop_ind1, EdgeMark.MATCHED);
        end if;
      end for;
    elseif e_mark == EdgeMark.MATCHED and listLength(Omega) == 1 then
      // matching mode
      // if there is exactly one loop edge match it
      neighbor := List.first(Omega);
      // if TRUE_LOOP node is trying to be matched it is a structurally singular system
      if marks2[neighbor] <> VertMark.TRUE_LOOP then
        UnorderedMap.add((node + shift1, neighbor + shift2), EdgeMark.MATCHED, E_marks);
        arrayUpdate(marks1, node, VertMark.MATCHED);
        arrayUpdate(loop_ind1, node, {});
        arrayUpdate(marks2, neighbor, VertMark.MATCHED);
        arrayUpdate(loop_ind2, neighbor, {});
        LMfalseLoop(neighbor, m2, m1, shift2, shift1, marks2, marks1, E_marks, loop_ind2, loop_ind1, EdgeMark.UNMATCHED);
      else
        // trying to match a variable that is already part of an algebraic loop
        // ERROR: -> more analysis needed to decide if index reduction case
        Error.assertion(false, getInstanceName() + " failed. It was trying to match a node already assigned to an algebraic loop.
          Index reduction not yet implemented.", sourceInfo());
      end if;
    end if;
  end LMfalseLoop;

  // ######################################
  //            ARRAY MATCHING
  // ######################################
  function arrayMatching
    input BipartiteGraph graph;
    output Matching matching;
  algorithm
    matching := ARRAY_MATCHING();
  end arrayMatching;

/*
  function SBGMatching
    input BipartiteGraph graph                               "full bipartite graph";
    input UnorderedMap<SetVertex, Integer> vertexMap  "maps a vertex to its index";
  protected
    SBSet E_M = SBSet.newEmpty()                      "matched edges";
    SBSet F_M = SBSet.newEmpty()                      "matched equation vertices";
    SBSet U_M = SBSet.newEmpty()                      "matched variable vertices";
    SBSet U_V                                         "visited variable vertices";
    Vector<SBSet> F                                   "auxiliary vecor of equation vertices. will be manipulated";
    SBSet F_set                                       "current set of start vertex";
    Integer F_set_index                               "index of current start vertex";
    SetVertex F_vertex                                "current start vertex";
    SBSet F_path                                      "set of vertices on current path";
    Integer w_max                                     "current maximum path width";
    list<SBSet> P                                     "augmenting path";
  algorithm
    // get all sets from equation set vertices
    F := Vector.fromList(list(SetVertex.getSet(v) for v in BipartiteIncidenceList.vertices(graph, SetType.F)));
    // repeat
      (F_set, F_set_index) := SBSet.maxCardinality(F);
      U_V := SBSet.newEmpty();
      w_max := 0;
      F_path := F_set;
      F_vertex := BipartiteIncidenceList.getVertex(graph, F_set_index, SetType.F);
      (P, F_path, U_V, w_max) := augmentPathF(graph, vertexMap, F_vertex, E_M, U_M, F_path, U_V, w_max);
  end SBGMatching;

  function augmentPathF
    "WSAPF
    augmenting a path starting on a set vertex representing an equation F (function)"
    input BipartiteGraph graph                               "full bipartite graph";
    input UnorderedMap<SetVertex, Integer> vertexMap  "maps a vertex to its index";
    input SetVertex F                                 "start vertex";
    input SBSet E_M                                   "matched edges";
    input SBSet U_M                                   "matched variable vertices";
    output list<SBSet> P_max = {}                     "current maximum path";
    input output SBSet F_path                         "set of vertices on current path";
    input output SBSet U_V                            "visited variable vertices";
    input output Integer w_max                        "current maximum path width";
  protected
    Integer F_index, U_card;
    SetEdge E;
    SBSet P_1;
    SBSet U_set, U_set_N, U_set_M;
    SetVertex U;
  algorithm
    try
      SOME(F_index) := UnorderedMap.get(F, vertexMap);
    else
      Error.assertion(false, getInstanceName() + " failed. Vertex index for SetVertex: "
        + SetVertex.toString(F) + " could not be found.", sourceInfo());
    end try;

    // get unmatched edges for U
    for E_index in BipartiteIncidenceList.getRow(graph, F_index) loop
      E := BipartiteIncidenceList.getEdge(graph, E_index);
      // get U from unmatched edges
      U_set := SetEdge.unmatchedU(E, E_M);
      // get unmatched U (skip the unmatched edges part?)
      U_set_N := SBSet.complement(U_set, U_M);
      U_card := SBSet.card(U_set_N);
      if U_card > w_max then
        w_max := U_card;
        P_1 := SetEdge.minInvU(E, U_set);
      end if;
      // kabdelhak: threading for loops otherwise it does not make any sense to me
      U_set_M := SBSet.intersection(U_set, U_M);
      // check if vertex is fully matched already
      if SBSet.isEmpty(SBSet.complement(U_set, U_set_M)) then
        // check if augmenting path is wider
        if SBSet.card(U_set_M) > w_max then
          U_V := SBSet.union(U_V, U_set_M);
          try
            // get SetVertex for our SBSet
            {U} := BipartiteIncidenceList.getVerticesFromSet(graph, U_set_M, SetType.U, SetVertex.getSet);
          else
            Error.assertion(false, getInstanceName() + " failed. Multiple SetVertices got returned for SBSet: "
              + SBSet.toString(U_set_M), sourceInfo());
          end try;
          (P_max, F_path, U_V, w_max) := augmentPathU(graph, vertexMap, U, E_M, U_M, F_path, U_V, w_max);
          (P_max, w_max) := fixPathHead(P_1, P_max, w_max, E, SetType.U);
        end if;
      end if;
    end for;
  end augmentPathF;

  function augmentPathU
    "WASPU
    augmenting a path starting on a set vertex representing a variable U (unknown)"
    input BipartiteGraph graph                               "full bipartite graph";
    input UnorderedMap<SetVertex, Integer> vertexMap  "maps a vertex to its index";
    input SetVertex U                                 "start vertex";
    input SBSet E_M                                   "globally matched edges";
    input SBSet U_M                                   "matched variable vertices";
    output list<SBSet> P_max                          "current maximum path";
    input output SBSet F_path                         "set of vertices on current path";
    input output SBSet U_V                            "visited variable vertices";
    input output Integer w_max                        "current maximum path width";
  protected
    Integer U_index, P1_card;
    SetEdge E;
    SetVertex F;
    SBSet F_set;
    SBSet P_1;
  algorithm
    try
      SOME(U_index) := UnorderedMap.get(U, vertexMap);
    else
      Error.assertion(false, getInstanceName() + " failed. Vertex index for SetVertex: "
        + SetVertex.toString(U) + " could not be found.", sourceInfo());
    end try;

    // get matched F vertices from matched edges
    for E_index in BipartiteIncidenceList.getRow(graph, U_index) loop
      E := BipartiteIncidenceList.getEdge(graph, E_index);
      F_set := SetEdge.matchedF(E, E_M);
      // check matched F vertices for higher cardinality
      if SBSet.card(F_set) > w_max then
        // ToDo: we check only for matched subset not for full F connected by edge. Problem?
        // we could get full set using the mapF on our edge without removing unmatched edge parts
        if SBSet.isEmpty(SBSet.intersection(F_set, F_path)) then
          F_path := SBSet.union(F_path, F_set);
          try
            // get SetVertex for our SBSet
            {F} := BipartiteIncidenceList.getVerticesFromSet(graph, F_set, SetType.F, SetVertex.getSet);
          else
            Error.assertion(false, getInstanceName() + " failed. Multiple SetVertices got returned for SBSet: "
              + SBSet.toString(F_set), sourceInfo());
          end try;
          (P_1 :: P_max, F_path, U_V, w_max) := augmentPathF(graph, vertexMap, F, E_M, U_M, F_path, U_V, w_max);
          F_path := SBSet.complement(F_path, F_set);
          // card of P_1 ? first element? how to map/inverse map that thing? combine both for loops and use edge?
          (P_max, w_max) := fixPathHead(P_1, P_max, w_max, E, SetType.F);
        else
          // solve recursion
        end if;
      end if;
    end for;
  end augmentPathU;

  function fixPathHead
    input SBSet P_1;
    input output list<SBSet> P_max;
    input output Integer w_max;
    input SetEdge E;
    input SetType ST;
  protected
    Integer P1_card;
  algorithm
    P1_card := SBSet.card(P_1);
    if P1_card > w_max then
      w_max := P1_card;
      P_max := SetEdge.maxPath(E, P_1, ST) :: P_max;
    end if;
  end fixPathHead;

  function addMatchedF
    input output SBSet F_M;
    input SBSet path_edge;
    input BipartiteGraph graph;
  protected
    SetEdge edge;
  algorithm
    try
      //{edge} := BipartiteIncidenceList.getEdgesFromSet(graph, path_edge, SetEdge.getDomain);
    else
      Error.assertion(false, getInstanceName() + " failed. Multiple SetEdges got returned for SBSet: "
        + SBSet.toString(path_edge), sourceInfo());
    end try;
  end addMatchedF;
*/
  annotation(__OpenModelica_Interface="backend");
end NBMatching;


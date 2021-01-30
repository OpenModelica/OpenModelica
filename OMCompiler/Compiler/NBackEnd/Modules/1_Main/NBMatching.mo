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
  import GC;

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
  import NBEquation.Equation;
  import NBEquation.EqData;
  import NBEquation.EquationPointers;
  import Module = NBModule;
  import BVariable = NBVariable;
  import NBVariable.VarData;
  import NBVariable.VariablePointers;
  import ResolveSingularities = NBResolveSingularities;

  // Util import
  import BackendUtil = NBBackendUtil;

public
  // =======================================
  //                MATCHING
  // =======================================
  record ARRAY_MATCHING
    // to fill
  end ARRAY_MATCHING;

  record SCALAR_MATCHING
    array<Integer> var_to_eqn;
    array<Integer> eqn_to_var;
  end SCALAR_MATCHING;

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
      case ARRAY_MATCHING() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
      then fail();
      case EMPTY_MATCHING() then str + StringUtil.headline_2(str + "Empty Matching") + "\n";
      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end toString;

  function regular
    "author: kabdelhak
    Regular matching algorithm for bipartite graphs by Constantinos C. Pantelides.
    First published in doi:10.1137/0909014"
    input Adjacency.Matrix adj;
    input Boolean transposed = false        "transpose matching if true";
    input Boolean partially = false         "do not fail on singular systems and return partial matching if true";
    output Matching matching;
  algorithm
     matching := match adj
      case Adjacency.Matrix.SCALAR_ADJACENCY_MATRIX() algorithm
        // marked equations irrelevant for regular matching
        if transposed then
          (matching, _) := scalarMatching(adj.mT, adj.m, transposed, partially);
        else
          (matching, _) := scalarMatching(adj.m, adj.mT, transposed, partially);
        end if;
      then matching;

      case Adjacency.Matrix.ARRAY_ADJACENCY_MATRIX() algorithm
        //Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
        matching := arrayMatching(adj.graph);
      then matching;

      case Adjacency.Matrix.EMPTY_ADJACENCY_MATRIX() then EMPTY_MATCHING();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end regular;

  function singular
    "author: kabdelhak
    Matching algorithm for bipartite graphs by Constantinos C. Pantelides.
    First published in doi:10.1137/0909014
    In the case of singular systems in tries to resolve it by applying index reduction
    using the dummy derivative method by Sven E. Mattsson and Gustaf Söderlind
    First published in doi:10.1137/0914043

    algorithm:
      - apply pantelides but carry list of singular markings (eqs)
      - whenever singular - add all current marks to singular markings
      - if done and list is not empty -> index reduction
    "
    output Matching matching;
    input Adjacency.Matrix adj;
    output Adjacency.Matrix new_adj = adj;
    input output VariablePointers vars;
    input output EquationPointers eqns;
    input output FunctionTree funcTree;
    input output VarData varData;
    input output EqData eqData;
    input Boolean transposed = false        "transpose matching if true";
    input Boolean partially = false         "do not fail on singular systems and return partial matching if true";
  protected
    Module.resolveSingularitiesInterface resolveFunc;
  algorithm
    matching := match adj
      local
        list<list<Integer>> marked_eqns;
        list<Pointer<Variable>> unmatched_vars;
        list<Pointer<Equation>> unmatched_eqns;

      case Adjacency.Matrix.SCALAR_ADJACENCY_MATRIX()  algorithm
        if transposed then
          (matching, marked_eqns) := scalarMatching(adj.mT, adj.m, transposed, partially);
        else
          (matching, marked_eqns) := scalarMatching(adj.m, adj.mT, transposed, partially);
        end if;

        _ := match adj.st
          case NBAdjacency.MatrixStrictness.INIT algorithm
            (_, unmatched_vars, _, unmatched_eqns) := getMatches(matching, vars, eqns);
            if Flags.isSet(Flags.INITIALIZATION) then
              print(StringUtil.headline_1("Balance Initialization") + "\n");
              print(if listEmpty(unmatched_eqns) then "Not overdetermined.\n" else "Stage " + intString(listLength(unmatched_eqns)) + " overdetermined. ");
              print(if listEmpty(unmatched_vars) then "Not underdetermined.\n" else "Stage " + intString(listLength(unmatched_vars)) + " underdetermined.\n");
              print("\n" + StringUtil.headline_4("(" + intString(listLength(unmatched_eqns)) + ") Unmatched equations:")
                + List.toString(unmatched_eqns, Equation.pointerToString, "", "\t", ";\n\t", ";\n", false) + "\n");
              print(StringUtil.headline_4("(" + intString(listLength(unmatched_vars)) + ") Unmatched variables:")
                + List.toString(unmatched_vars, BVariable.pointerToString, "", "\t", ";\n\t", ";\n", false) + "\n");
            end if;
            // some equations or variables could not be matched --> balance initial system
            if not (listEmpty(unmatched_vars) and listEmpty(unmatched_eqns)) then
              (vars, eqns, varData, eqData, funcTree) := ResolveSingularities.balanceInitialization(vars, eqns, varData, eqData, funcTree, unmatched_vars, unmatched_eqns);
              // compute new adjacency matrix (ToDo: keep more of old information)
              new_adj := Adjacency.Matrix.create(vars, eqns, NBAdjacency.MatrixType.SCALAR, adj.st);
              (matching, new_adj, vars, eqns, funcTree, varData, eqData) := Matching.singular(new_adj, vars, eqns, funcTree, varData, eqData, false, true);
            end if;
          then ();

          else algorithm
            // some equations could not be matched --> resolve singular systems
            if not listEmpty(marked_eqns) then
              (vars, eqns, varData, eqData, funcTree) := ResolveSingularities.indexReduction(vars, eqns, varData, eqData, funcTree, List.unique(List.flatten(marked_eqns)));
              // compute new adjacency matrix (ToDo: keep more of old information)
              new_adj := Adjacency.Matrix.create(vars, eqns, NBAdjacency.MatrixType.SCALAR, adj.st);
              (matching, new_adj, vars, eqns, funcTree, varData, eqData) := Matching.singular(new_adj, vars, eqns, funcTree, varData, eqData, false, true);
            end if;
          then ();
        end match;
      then matching;

      case Adjacency.Matrix.ARRAY_ADJACENCY_MATRIX() algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed because array matching is not yet supported."});
      then fail();

      case Adjacency.Matrix.EMPTY_ADJACENCY_MATRIX() then EMPTY_MATCHING();

      else algorithm
        Error.addMessage(Error.INTERNAL_ERROR,{getInstanceName() + " failed."});
      then fail();
    end match;
  end singular;

  function getMatches
    input Matching matching;
    input VariablePointers variables;
    input EquationPointers equations;
    output list<Pointer<Variable>> matched_vars = {}, unmatched_vars = {};
    output list<Pointer<Equation>> matched_eqns = {}, unmatched_eqns = {};
  algorithm
    _ := match matching
      case SCALAR_MATCHING() algorithm
        // check if variables are matched and sort them accordingly
        for var in 1:arrayLength(matching.var_to_eqn) loop
          if matching.var_to_eqn[var] > 0 then
            matched_vars := ExpandableArray.get(var, variables.varArr) :: matched_vars;
          else
            unmatched_vars := ExpandableArray.get(var, variables.varArr) :: unmatched_vars;
          end if;
        end for;

        // check if equations are matched and sort them accordingly
        for eqn in 1:arrayLength(matching.eqn_to_var) loop
          if matching.eqn_to_var[eqn] > 0 then
            matched_eqns := ExpandableArray.get(eqn, equations.eqArr) :: matched_eqns;
          else
            unmatched_eqns := ExpandableArray.get(eqn, equations.eqArr) :: unmatched_eqns;
          end if;
        end for;
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
      GC.free(var_marks);
      GC.free(eqn_marks);
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

  // ######################################
  //            ARRAY MATCHING
  // ######################################
  function arrayMatching
    input BipartiteGraph graph;
    output Matching matching;
  algorithm
    matching := ARRAY_MATCHING();
  end arrayMatching;

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

  annotation(__OpenModelica_Interface="backend");
end NBMatching;


/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

encapsulated package Graph
" file:        Graph.mo
  package:     Graph
  description: Contains various graph algorithms.


  This package contains various graph algorithms such as topological sorting. It
  should also contain a graph type, but such a type would need polymorphic
  records that we don't yet support in MetaModelica."

protected import Error;
protected import List;

public replaceable type NodeType subtypeof Any;
public replaceable type ArgType subtypeof Any;

public function buildGraph
  "This function will build a graph given a list of nodes, an edge function, and
  an extra argument to the edge function. The edge function should generate a
  list of edges for any given node in the list. From this information a graph
  represented by an adjacency list will be built.

  NOTE: There is no check that there is only unique edges for each node.
  This module assumes that you do not build a graph with duplicate edges!"
  input list<NodeType> inNodes;
  input EdgeFunc inEdgeFunc;
  input ArgType inEdgeArg;
  output list<tuple<NodeType, list<NodeType>>> outGraph;

  partial function EdgeFunc
    input NodeType inNode;
    input ArgType inArg;
    output list<NodeType> outEdges;
  end EdgeFunc;
algorithm
  outGraph := List.threadTuple(inNodes, List.map1(inNodes, inEdgeFunc, inEdgeArg));
end buildGraph;

public function emptyGraph
  "This function will build an empty graph given a list of nodes."
  input list<NodeType> inNodes;
  output list<tuple<NodeType, list<NodeType>>> outGraph;
algorithm
  outGraph := List.map(inNodes, emptyGraphHelper);
end emptyGraph;

protected function emptyGraphHelper
  input NodeType nt;
  output tuple<NodeType,list<NodeType>> out;
algorithm
  out := (nt,{});
end emptyGraphHelper;

public function topologicalSort
  "This function will sort a graph topologically. It takes a graph represented
  by an adjacency list and a node equality function, and returns a list of the
  nodes ordered by dependencies (a node x is dependent on y if there is an edge
  from x to y). This function assumes that all edges in the graph are unique.

  It is of course only possible to sort an acyclic graph topologically. If the
  graph contains cycles this function will return the nodes that it could sort
  as the first return value, and the remaining graph that contains cycles as the
  second value."
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output list<NodeType> outNodes;
  output list<tuple<NodeType, list<NodeType>>> outRemainingGraph;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
protected
  list<tuple<NodeType, list<NodeType>>> start_nodes, rest_nodes;
algorithm
  (rest_nodes, start_nodes) := List.splitOnTrue(inGraph, hasOutgoingEdges);
  (outNodes, outRemainingGraph) :=
    topologicalSort2(start_nodes, rest_nodes, {}, inEqualFunc);
end topologicalSort;

protected function topologicalSort2
  "Helper function to topologicalSort, does most of the actual work.
  inStartNodes is a list of start nodes that have no outgoing edges, i.e. no
  dependencies. inRestNodes is the rest of the nodes in the graph."
  input list<tuple<NodeType, list<NodeType>>> inStartNodes;
  input list<tuple<NodeType, list<NodeType>>> inRestNodes;
  input list<NodeType> inAccumNodes;
  input EqualFunc inEqualFunc;
  output list<NodeType> outNodes;
  output list<tuple<NodeType, list<NodeType>>> outRemainingGraph;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  (outNodes, outRemainingGraph) :=
  match(inStartNodes, inRestNodes, inAccumNodes, inEqualFunc)
    local
      NodeType node1;
      list<tuple<NodeType, list<NodeType>>> rest_start, rest_rest, new_start;
      list<NodeType> result;

    // No more nodes to sort, reverse the accumulated nodes (because of
    // accumulation order) and return it with the (hopefully empty) remaining
    // graph.
    case ({}, _, _, _) then (listReverse(inAccumNodes), inRestNodes);

    // If the remaining graph is empty we don't need to do much more, just
    // append the rest of the start nodes to the result.
    case ((node1, {}) :: rest_start, {}, _, _)
      equation
        (result, _) = topologicalSort2(rest_start, {}, node1 :: inAccumNodes,
            inEqualFunc);
      then
        (result, {});

    case ((node1, {}) :: rest_start, rest_rest, _, _)
      equation
        // Remove the first start node from the graph.
        rest_rest = List.map2(rest_rest, removeEdge, node1, inEqualFunc);
        // Fetch any new nodes that has no dependencies.
        (rest_rest, new_start) =
          List.splitOnTrue(rest_rest, hasOutgoingEdges);
        // Append those nodes to the list of start nodes.
        rest_start = List.appendNoCopy(rest_start, new_start);
        // Add the first node to the list of sorted nodes and continue with the
        // rest of the nodes.
        (result, rest_rest) = topologicalSort2(rest_start,  rest_rest,
          node1 :: inAccumNodes, inEqualFunc);
      then
        (result, rest_rest);

  end match;
end topologicalSort2;

protected function hasOutgoingEdges
  "Returns true if the given node has no outgoing edges, otherwise false."
  input tuple<NodeType, list<NodeType>> inNode;
  output Boolean outHasOutEdges;
algorithm
  outHasOutEdges := match(inNode)
    case ((_, {})) then false;
    else true;
  end match;
end hasOutgoingEdges;

protected function removeEdge
  "Takes a node with it's edges and a node that's been removed from the graph,
  and removes the edge if it exists in the edge list."
  input tuple<NodeType, list<NodeType>> inNode;
  input NodeType inRemovedNode;
  input EqualFunc inEqualFunc;
  output tuple<NodeType, list<NodeType>> outNode;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;

protected
  NodeType node;
  list<NodeType> edges;
algorithm
  (node, edges) := inNode;
  (edges, _) := List.deleteMemberOnTrue(inRemovedNode, edges, inEqualFunc);
  outNode := (node, edges);
end removeEdge;

public function findCycles
  "Returns the cycles in a given graph. It will check each node, and if that
  node is part of a cycle it will return the cycle. It will also remove the
  other nodes in the cycle from the list of remaining nodes to check, so the
  result will be a list of unique cycles.

  This function is not very efficient, so it shouldn't be used for any
  performance critical tasks.  It's meant to be used together with
  topologicalSort to print an error message if any cycles are detected."
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output list<list<NodeType>> outCycles;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  outCycles := findCycles2(inGraph, inGraph, inEqualFunc);
end findCycles;

public function findCycles2
  "Helper function to findCycles."
  input list<tuple<NodeType, list<NodeType>>> inNodes;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output list<list<NodeType>> outCycles;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  outCycles := matchcontinue(inNodes, inGraph, inEqualFunc)
    local
      tuple<NodeType, list<NodeType>> node;
      list<tuple<NodeType, list<NodeType>>> rest_nodes;
      list<NodeType> cycle;
      list<list<NodeType>> rest_cycles;

    case ({}, _, _) then {};

    // Try and find a cycle for the first node.
    case (node :: rest_nodes, _, _)
      equation
        SOME(cycle) = findCycleForNode(node, inGraph, {}, inEqualFunc);
        rest_nodes = removeNodesFromGraph(cycle, rest_nodes, inEqualFunc);
        rest_cycles = findCycles2(rest_nodes, inGraph, inEqualFunc);
      then
        cycle :: rest_cycles;

    // If previous case failed we couldn't find a cycle for that node, so
    // continue with the rest of the nodes.
    case (_ :: rest_nodes, _, _)
      equation
        rest_cycles = findCycles2(rest_nodes, inGraph, inEqualFunc);
      then
        rest_cycles;

  end matchcontinue;
end findCycles2;

protected function findCycleForNode
  "Tries to find a cycle in the graph starting from a given node. This function
  returns an optional cycle, because it's possible that it will encounter a
  cycle in which the given node is not a part. This makes it possible to
  continue searching for another cycle. This function will therefore return some
  cycle if one was found, or fail or return NONE() if no cycle could be found. A
  given node might be part of several cycles, but this function will stop as
  soon as it finds one cycle."
  input tuple<NodeType, list<NodeType>> inNode;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input list<NodeType> inVisitedNodes;
  input EqualFunc inEqualFunc;
  output Option<list<NodeType>> outCycle;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  outCycle := matchcontinue(inNode, inGraph, inVisitedNodes, inEqualFunc)
    local
      NodeType node, start_node;
      list<NodeType> edges, visited_nodes, cycle;
      Boolean is_start_node;
      Option<list<NodeType>> opt_cycle;

    case ((node, _), _, _ :: _, _)
      equation
        // Check if we have already visited this node.
        true = List.isMemberOnTrue(node, inVisitedNodes, inEqualFunc);
        // Check if the current node is the start node, in that case we're back
        // where we started and we have a cycle. Otherwise we just encountered a
        // cycle in the graph that the start node is not part of.
        start_node = List.last(inVisitedNodes);
        is_start_node = inEqualFunc(node, start_node);
        opt_cycle = if is_start_node then SOME(inVisitedNodes) else NONE();
      then
        opt_cycle;

    case ((node, edges), _, _, _)
      equation
        // If we have not visited the current node yet we add it to the list of
        // visited nodes, and then call findCycleForNode2 on the edges of the node.
        visited_nodes = node :: inVisitedNodes;
        cycle = findCycleForNode2(edges, inGraph, visited_nodes, inEqualFunc);
      then
        SOME(cycle);

  end matchcontinue;
end findCycleForNode;

protected function findCycleForNode2
  "Helper function to findCycleForNode. Calls findNodeInGraph on each node in
  the given list."
  input list<NodeType> inNodes;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input list<NodeType> inVisitedNodes;
  input EqualFunc inEqualFunc;
  output list<NodeType> outCycle;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  outCycle := matchcontinue(inNodes, inGraph, inVisitedNodes, inEqualFunc)
    local
      NodeType node;
      list<NodeType> rest_nodes, cycle;
      tuple<NodeType, list<NodeType>> graph_node;

    // Try and find a cycle by following this edge.
    case (node :: _, _, _, _)
      equation
        graph_node = findNodeInGraph(node, inGraph, inEqualFunc);
        SOME(cycle) = findCycleForNode(graph_node, inGraph, inVisitedNodes,
          inEqualFunc);
      then
        cycle;

    // No cycle found in previous case, check the rest of the edges.
    case (_ :: rest_nodes, _, _, _)
      equation
        cycle = findCycleForNode2(rest_nodes, inGraph, inVisitedNodes,
          inEqualFunc);
      then
        cycle;

  end matchcontinue;
end findCycleForNode2;

protected function findNodeInGraph
  "Returns a node and its edges from a graph given a node to search for, or
  fails if no such node exists in the graph."
  input NodeType inNode;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output tuple<NodeType, list<NodeType>> outNode;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  outNode := matchcontinue(inNode, inGraph, inEqualFunc)
    local
      NodeType node;
      tuple<NodeType, list<NodeType>> graph_node;
      list<tuple<NodeType, list<NodeType>>> rest_graph;

    case (_, (graph_node as (node, _)) :: _, _)
      equation
        true = inEqualFunc(inNode, node);
      then
        graph_node;

    case (_, _ :: rest_graph, _)
      then findNodeInGraph(inNode, rest_graph, inEqualFunc);

  end matchcontinue;
end findNodeInGraph;

protected function findIndexofNodeInGraph
  "Returns the index in the list of the node  from a graph given a node to search for, or
  fails if no such node exists in the graph."
  input NodeType inNode;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  input Integer inIndex;
  output Integer outIndex;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  outIndex := matchcontinue(inNode, inGraph, inEqualFunc, inIndex)
    local
      NodeType node;
      tuple<NodeType, list<NodeType>> graph_node;
      list<tuple<NodeType, list<NodeType>>> rest_graph;

    case (_, (node, _) :: _, _, _)
      equation
        true = inEqualFunc(inNode, node);
      then
        inIndex;

    case (_, _ :: rest_graph, _, _)
      then findIndexofNodeInGraph(inNode, rest_graph, inEqualFunc, inIndex+1);

  end matchcontinue;
end findIndexofNodeInGraph;

protected function removeNodesFromGraph
  "Removed a list of nodes from the graph. Note that only the nodes are removed
  and not any edges pointing at the nodes."
  input list<NodeType> inNodes;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output list<tuple<NodeType, list<NodeType>>> outGraph;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  outGraph := matchcontinue(inNodes, inGraph, inEqualFunc)
    local
      tuple<NodeType, list<NodeType>> graph_node;
      list<tuple<NodeType, list<NodeType>>> rest_graph;
      list<NodeType> rest_nodes;
      NodeType node;

    case ({}, _, _) then inGraph;
    case (_, {}, _) then {};

    case (_, ((node, _)) :: rest_graph, _)
      equation
        (rest_nodes, SOME(_)) = List.deleteMemberOnTrue(node, inNodes,
          inEqualFunc);
      then
        removeNodesFromGraph(rest_nodes, rest_graph, inEqualFunc);

    case (_, graph_node :: rest_graph, _)
      equation
        rest_graph = removeNodesFromGraph(inNodes, rest_graph, inEqualFunc);
      then
        graph_node :: rest_graph;

  end matchcontinue;
end removeNodesFromGraph;

public function transposeGraph
"This function transposes a graph by given a graph and vertex list.
To call this, use transposeGraph(emptyGraphOnlyNodes,graph,eqFunction).
"
  input list<tuple<NodeType, list<NodeType>>> intmpGraph;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output list<tuple<NodeType, list<NodeType>>> outGraph;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;

algorithm
  outGraph := matchcontinue(intmpGraph,inGraph,inEqualFunc)
    local
      NodeType node;
      list<NodeType> nodeList;
      tuple<NodeType, list<NodeType>> vertex;
      list<tuple<NodeType, list<NodeType>>> restGraph,tmpGraph;
    case(_,{},_) then intmpGraph;
    case(_,(node,nodeList)::restGraph,_)
      equation
        tmpGraph = List.fold2(nodeList,insertNodetoGraph,node,inEqualFunc,intmpGraph);
        tmpGraph = transposeGraph(tmpGraph,restGraph,inEqualFunc);
      then tmpGraph;
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Graph.transpose failed."}, sourceInfo());
      then fail();
  end matchcontinue;
end transposeGraph;

protected function insertNodetoGraph
" This function takes nodes and a vertex and inserts
  the vertex to list of nodes of the graph.
"
  input NodeType inNode;
  input NodeType inVertex;
  input EqualFunc inEqualFunc;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  output list<tuple<NodeType, list<NodeType>>> outGraph;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;

algorithm
  outGraph := matchcontinue(inNode, inVertex, inEqualFunc, inGraph)
  local
    NodeType node;
    list<NodeType> rest;
    list<tuple<NodeType, list<NodeType>>> restGraph;

  case (_, _, _, {}) then {};
  case (_, _, _, (node,rest)::restGraph)
    equation
      true = inEqualFunc(node, inNode);
      rest = List.unionList({rest, {inVertex}});
      restGraph = insertNodetoGraph(inNode, inVertex, inEqualFunc, restGraph);
    then (node,rest)::restGraph;
  case (_, _, _, (node,rest)::restGraph)
    equation
      false = inEqualFunc(node, inNode);
      restGraph = insertNodetoGraph(inNode, inVertex, inEqualFunc, restGraph);
    then (node,rest)::restGraph;
  end matchcontinue;
end insertNodetoGraph;

public function allReachableNodes
"This function searches for a starting node in M
 all reachable nodes. Call with start node in M: allReachableNodes((start,{}),graph,eqFn)."
  input tuple<list<NodeType>,list<NodeType>>  intmpstorage;//(M,L)
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output list<NodeType> reachableNodes "Is NONE() on error to prevent recursion";

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;

algorithm
  SOME(reachableNodes) := allReachableNodesWork(intmpstorage,inGraph,inEqualFunc);
end allReachableNodes;

protected function allReachableNodesWork
"This function searches for a starting node in M
 all reachable nodes. Call with start node in M: allReachableNodes((start,{}),graph,eqFn)."
  input tuple<list<NodeType>,list<NodeType>>  intmpstorage;//(M,L)
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output Option<list<NodeType>> reachableNodes "Is NONE() on error to prevent recursion";

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;

algorithm
  reachableNodes := matchcontinue(intmpstorage,inGraph,inEqualFunc)
    local
      tuple<list<NodeType>, list<NodeType>> tmpstorage;
      NodeType node;
      list<NodeType> edges,M,L;
      list<tuple<NodeType, list<NodeType>>> restGraph;
    case (({},L),_,_)
      equation
        L = listReverse(L);
      then SOME(L);

    case ((node::M,L),_,_)
      equation
        List.getMemberOnTrue(node,L,inEqualFunc);
      then allReachableNodesWork((M,L),inGraph,inEqualFunc);

    case ((node::M,L),_,_)
      equation
        L = node::L;
        //print(" List size 1 " + intString(listLength(L)) + "\n");
        ((_,edges)) = findNodeInGraph(node,inGraph,inEqualFunc);
        //print(" List size 2 " + intString(listLength(edges)) + "\n");
        //print(" List size 3 " + intString(listLength(edges)) + "\n");
        M = listAppend(edges,M);
        //print("Start new round! \n");
      then allReachableNodesWork((M,L),inGraph,inEqualFunc);
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Graph.allReachableNodes failed."}, sourceInfo());
      then NONE();
  end matchcontinue;
end allReachableNodesWork;

public function partialDistance2color
"A greedy partial distance-2 coloring algorithm.
procedure G REEDY PARTIAL D2C OLORING(Gb = (V1 ,V2 , E))
Let u1 , u2 , . . ., un be a given ordering of V2 , where n = |V2 |
Initialize forbiddenColors with some value a in V2
for i = 1 to n do
for each vertex w such that (ui , w) in E do
for each colored vertex x such that (w, x) in E do
forbiddenColors[color[x]] <- ui
color[ui ] <- min{c > 0 : forbiddenColors[c] = ui }
"
  input list<NodeType> toColorNodes;
  input array<Option<list<NodeType>>> inforbiddenColor;
  input list<Integer> inColors;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input list<tuple<NodeType, list<NodeType>>> inGraphT;
  input array<Integer> inColored;
  input EqualFunc inEqualFunc;
  input PrintFunc inPrintFunc;
  output array<Integer> outColored;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;

  partial function PrintFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input list<NodeType> inNode1;
    input String inName;
  end PrintFunc;
algorithm
  outColored := matchcontinue(toColorNodes, inforbiddenColor, inColors, inGraph, inGraphT, inColored, inEqualFunc, inPrintFunc)
  local
    NodeType node;
    list<NodeType> rest, nodes;
    array<Option<list<NodeType>>> forbiddenColor;
    array<Integer> colored;
    Integer color, index;
    case ({},_,_,_,_,_, _, _) then inColored;
    case (node::rest, _, _, _, _, _, _, _)
      equation
        index = arrayLength(inColored) - listLength(rest);
        ((_,nodes)) = findNodeInGraph(node, inGraphT, inEqualFunc);
        forbiddenColor = addForbiddenColors(node, nodes, inColored, inforbiddenColor, inGraph, inEqualFunc, inPrintFunc);
        color = arrayFindMinColorIndex(forbiddenColor, node, 1, arrayLength(inColored)+1, inEqualFunc, inPrintFunc);
        colored = arrayUpdate(inColored, index, color);
        colored = partialDistance2color(rest, forbiddenColor, inColors, inGraph, inGraphT, colored, inEqualFunc, inPrintFunc);
      then colored;
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Graph.partialDistance2color failed."}, sourceInfo());
      then fail();
  end matchcontinue;
end partialDistance2color;

protected function addForbiddenColors
  input NodeType inNode;
  input list<NodeType> inNodes;
  input array<Integer> inColored;
  input array<Option<list<NodeType>>> inForbiddenColor;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  input PrintFunc inPrintFunc;
  output array<Option<list<NodeType>>> outForbiddenColor;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;

  partial function PrintFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input list<NodeType> inNode1;
    input String inName;
  end PrintFunc;

algorithm
  outForbiddenColor := matchcontinue(inNode, inNodes, inColored, inForbiddenColor, inGraph, inEqualFunc, inPrintFunc)
  local
    NodeType node;
    list<NodeType> rest,nodes;
    list<Integer> indexes;
    list<Integer> indexesColor;
    list<String> indexesStr;
    array<Option<list<NodeType>>> forbiddenColor,forbiddenColor1;
    list<Option<list<NodeType>>> listOptFobiddenColors;
    list<list<NodeType>> listFobiddenColors;
    case (_, {}, _, _, _, _, _) then inForbiddenColor;
    case (_, node::rest, _, forbiddenColor, _, _, _)
      equation
        ((_,nodes)) = findNodeInGraph(node, inGraph, inEqualFunc);
        indexes = List.map3(nodes, findIndexofNodeInGraph, inGraph, inEqualFunc, 1);
        indexes = List.select1(indexes, arrayElemetGtZero, inColored);
        indexesColor = List.map1(indexes, getArrayElem, inColored);
        List.map2_0(indexesColor, arrayUpdateListAppend, forbiddenColor, inNode);
        forbiddenColor1 = addForbiddenColors(inNode, rest, inColored, forbiddenColor, inGraph, inEqualFunc, inPrintFunc);
      then forbiddenColor1;
      else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Graph.addForbiddenColors failed."}, sourceInfo());
      then fail();
  end matchcontinue;
end addForbiddenColors;

protected function getArrayElem
  input Integer inIndex;
  input array<Type_a> inArray;
  output Type_a outElem;
  replaceable type Type_a subtypeof Any;
algorithm
  outElem := arrayGet(inArray,inIndex);
end getArrayElem;

protected function arrayUpdateListAppend
  input Integer inIndex;
  input array<Option<list<NodeType>>> inArray;
  input NodeType inNode;
  replaceable type NodeType subtypeof Any;
protected
  list<NodeType> arrayElem;
algorithm
  _ := matchcontinue(inIndex, inArray, inNode)
    local
      list<NodeType> arrElem;
    case (_, _, _)
      equation
        arrayUpdate(inArray, inIndex, SOME({inNode}));
      then ();
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Graph.arrayUpdateListAppend failed."}, sourceInfo());
      then fail();
  end matchcontinue;
end arrayUpdateListAppend;

protected function arrayElemetGtZero
  input Integer inIndex;
  input array<Integer> inArray;
  output Boolean outBoolean;
algorithm
  outBoolean := intGt(arrayGet(inArray, inIndex), 0);
end arrayElemetGtZero;

protected function arrayFindMinColorIndex
  input array<Option<list<NodeType>>> inForbiddenColor;
  input NodeType inNode;
  input Integer inIndex;
  input Integer inmaxIndex;
  input EqualFunc inEqualFunc;
  input PrintFunc inPrintFunc;
  output Integer outColor;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
  partial function PrintFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input list<NodeType> inNode1;
    input String inName;
  end PrintFunc;
algorithm
  outColor := matchcontinue(inForbiddenColor, inNode, inIndex, inmaxIndex, inEqualFunc, inPrintFunc)
  local
    list<NodeType> nodes;
    Integer index;
    case (_, _, _, _, _, _)
      equation
        NONE() = arrayGet(inForbiddenColor, inIndex);
        //print("Found color on index : " + intString(inIndex) + "\n");
      then inIndex;
    case (_, _, _, _, _, _)
      equation
        SOME(nodes) = arrayGet(inForbiddenColor, inIndex);
        //inPrintFunc(nodes,"FobiddenColors:" );
        failure(_ = List.getMemberOnTrue(inNode, nodes, inEqualFunc));
        //print("Found color on index : " + intString(inIndex) + "\n");
      then inIndex;
    else
      equation
        SOME(nodes) = arrayGet(inForbiddenColor, inIndex);
        //inPrintFunc(nodes,"FobiddenColors:" );
        List.getMemberOnTrue(inNode, nodes, inEqualFunc);
        //print("Not found color on index : " + intString(inIndex) + "\n");
        index = arrayFindMinColorIndex(inForbiddenColor, inNode, inIndex+1, inmaxIndex, inEqualFunc, inPrintFunc);
      then index;
  end matchcontinue;
end arrayFindMinColorIndex;

public function printGraph
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input NodeToString inPrintFunc;
  output String outString;

  partial function NodeToString
    input NodeType inNode;
    output String outString;
  end NodeToString;
algorithm
  outString := stringDelimitList(List.map1(inGraph, printNode, inPrintFunc), "\n");
end printGraph;

public function printNode
  input tuple<NodeType, list<NodeType>> inNode;
  input NodeToString inPrintFunc;
  output String outString;

  partial function NodeToString
    input NodeType inNode;
    output String outString;
  end NodeToString;
protected
  NodeType node;
  list<NodeType> edges;
  String node_str;
  String edges_str;
algorithm
  (node, edges) := inNode;
  node_str := inPrintFunc(node);
  edges_str := stringDelimitList(List.map(edges, inPrintFunc), ", ");
  outString := node_str + ": " + edges_str;
end printNode;

/* Functions for Integer graphs */

public function printGraphInt
"This function prints an Integer Graph.
 Useful for debuging."
  input list<tuple<Integer, list<Integer>>> inGraph;
algorithm
 _ := match(inGraph)
   local
     Integer node;
     list<Integer> edges;
     list<String> strEdges;
     list<tuple<Integer, list<Integer>>> restGraph;
     case({}) then ();
     case((node,edges)::restGraph)
       equation
         print("Node : " + intString(node) + " Edges: ");
         strEdges = List.map(edges, intString);
         strEdges = List.map1(strEdges, stringAppend, " ");
         List.map_0(strEdges, print);
         print("\n");
         printGraphInt(restGraph);
      then ();
  end match;
end printGraphInt;

public function printNodesInt
"This function prints an Integer List Nodes.
 Useful for debuging."
  input list<Integer> inListNodes;
  input String inName;
algorithm
 _ := match(inListNodes, inName)
     local
       list<String> strNodes;
     case ({}, _)
       equation
         print(inName + "\n");
       then ();
     case (_, _)
       equation
         print(inName + " : ");
         strNodes = List.map(inListNodes, intString);
         strNodes = List.map1(strNodes, stringAppend, " ");
         List.map_0(strNodes, print);
         print("\n");
      then ();
  end match;
end printNodesInt;

public function allReachableNodesInt
"This function searches for a starting node in M
 all reachabel nodes. Call with start nodes in M. The
 result is collected in L."
  input tuple<list<Integer>,list<Integer>>  intmpstorage;//(M,L)
  input array<tuple<Integer, list<Integer>>> inGraph;
  input Integer inMaxGraphNode;
  input Integer inMaxNodexIndex;
  output list<Integer> reachableNodes;
algorithm
  reachableNodes := matchcontinue(intmpstorage,inGraph,inMaxGraphNode,inMaxNodexIndex)
    local
      tuple<list<Integer>, list<Integer>> tmpstorage;
      Integer node;
      list<Integer> edges,M,L;
    case (({},L),_,_,_) then L;
    case ((node::M,L),_,_,_)
      equation
        L = List.union(L,{node});
        false = intGe(node,inMaxGraphNode);
        ((_,edges)) = arrayGet(inGraph, node);
        edges = List.filter1OnTrue(edges, List.notMember, L);
        M = List.union(M,edges);
        reachableNodes = allReachableNodesInt((M,L),inGraph,inMaxGraphNode,inMaxNodexIndex);
      then reachableNodes;
    case ((node::M,L),_,_,_)
      equation
        L = List.union(L,{node});
        true = intGe(node,inMaxGraphNode);
        reachableNodes = allReachableNodesInt((M,L),inGraph,inMaxGraphNode,inMaxNodexIndex);
      then reachableNodes;
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Graph.allReachableNodesInt failed."}, sourceInfo());
      then fail();
  end matchcontinue;
end allReachableNodesInt;

public function partialDistance2colorInt
"A greedy partial distance-2 coloring algorithm.
procedure GREEDY PARTIAL D2COLORING(Gb = (V1 ,V2 , E))
Let u1 , u2 , . . ., un be a given ordering of V2 , where n = |V2 |
Initialize forbiddenColors with some value a in V2
for i = 1 to n do
for each vertex w such that (ui , w) in E do
for each colored vertex x such that (w, x) in E do
forbiddenColors[color[x]] <- ui
color[ui ] <- min{c > 0 : forbiddenColors[c] = ui }
"
  input list<tuple<Integer, list<Integer>>> inGraphT;
  input array<Option<list<Integer>>> inforbiddenColor;
  input list<Integer> inColors;
  input array<tuple<Integer, list<Integer>>> inGraph;
  input array<Integer> inColored;
  output array<Integer> outColored;
algorithm
  outColored := matchcontinue(inGraphT, inforbiddenColor, inColors, inGraph, inColored)
  local
    Integer node;
    list<Integer>  nodes;
    array<Option<list<Integer>>> forbiddenColor;
    array<Integer> colored;
    Integer color;
    list<tuple<Integer, list<Integer>>> restGraph;
    case ({},_,_,_,_) then inColored;
    case (((node,nodes))::restGraph, _, _, _, _)
      equation
        addForbiddenColorsInt(node, nodes, inColored, inforbiddenColor, inGraph);
        color = arrayFindMinColorIndexInt(inforbiddenColor, node, 1);
        colored = arrayUpdate(inColored, node, color);
    then
      partialDistance2colorInt(restGraph, inforbiddenColor, inColors, inGraph, colored);
    else
      equation
        Error.addSourceMessage(Error.INTERNAL_ERROR, {"Graph.partialDistance2colorInt failed."}, sourceInfo());
      then fail();
  end matchcontinue;
end partialDistance2colorInt;

protected function addForbiddenColorsInt
  input Integer inNode;
  input list<Integer> nodes;
  input array<Integer> inColored;
  input array<Option<list<Integer>>> forbiddenColor;
  input array<tuple<Integer, list<Integer>>> inGraph;
protected
  list<Integer> indexes;
algorithm
  try
    for node in nodes loop
      ((_,indexes)) := arrayGet(inGraph,node);
      updateForbiddenColorArrayInt(indexes, inColored, forbiddenColor, inNode);
    end for;
  else
    Error.addSourceMessage(Error.INTERNAL_ERROR, {"Graph.addForbiddenColors failed."}, sourceInfo());
    fail();
  end try;
end addForbiddenColorsInt;

protected function updateForbiddenColorArrayInt
  input list<Integer> inIndexes;
  input array<Integer> inColored;
  input array<Option<list<Integer>>> inForbiddenColor;
  input Integer inNode;
protected
  Integer colorIndex;
algorithm
  for index in inIndexes loop
    colorIndex := arrayGet(inColored, index);
    if colorIndex > 0 then
      arrayUpdate(inForbiddenColor, colorIndex, SOME({inNode}));
    end if;
  end for;
end updateForbiddenColorArrayInt;

protected function arrayFindMinColorIndexInt
  input array<Option<list<Integer>>> inForbiddenColor;
  input Integer inNode;
  input Integer inIndex;
  output Integer outColor;
algorithm
  outColor := matchcontinue(inForbiddenColor, inNode, inIndex)
  local
    list<Integer> nodes;
    case (_, _, _)
      equation
        NONE() = arrayGet(inForbiddenColor, inIndex);
        //print("Found color on index : " + intString(inIndex) + "\n");
      then inIndex;
    case (_, _, _)
      equation
        SOME(nodes) = arrayGet(inForbiddenColor, inIndex);
        //inPrintFunc(nodes,"FobiddenColors:" );
        failure(_ = List.getMemberOnTrue(inNode, nodes, intEq));
        //print("Found color on index : " + intString(inIndex) + "\n");
      then inIndex;
    case (_, _, _)
      equation
        SOME(nodes) = arrayGet(inForbiddenColor, inIndex);
        //inPrintFunc(nodes,"FobiddenColors:" );
        List.getMemberOnTrue(inNode, nodes, intEq);
        //print("Not found color on index : " + intString(inIndex) + "\n");
      then
        arrayFindMinColorIndexInt(inForbiddenColor, inNode, inIndex+1);
  end matchcontinue;
end arrayFindMinColorIndexInt;

public function filterGraph
  "Removes any node for which the given function evaluates to false, as well as
   any edge pointing at that node."
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input CondFunc inCondFunc;
  output list<tuple<NodeType, list<NodeType>>> outGraph;

  partial function CondFunc
    input NodeType inNode;
    output Boolean outCond;
  end CondFunc;
algorithm
  outGraph := List.accumulateMapAccum1(inGraph, filterGraph2, inCondFunc);
end filterGraph;

protected function filterGraph2
  "Helper function to filterGraph."
  input tuple<NodeType, list<NodeType>> inNode;
  input CondFunc inCondFunc;
  input list<tuple<NodeType, list<NodeType>>> inAccumGraph;
  output list<tuple<NodeType, list<NodeType>>> outNode;

  partial function CondFunc
    input NodeType inNode;
    output Boolean outCond;
  end CondFunc;
algorithm
  outNode := matchcontinue(inNode, inCondFunc, inAccumGraph)
    local
      NodeType node;
      list<NodeType> edges;

    case ((node, _), _, _)
      equation
        false = inCondFunc(node);
      then
        inAccumGraph;

    case ((node, edges), _, _)
      equation
        edges = List.filterOnTrue(edges, inCondFunc);
      then
        (node, edges) :: inAccumGraph;

  end matchcontinue;
end filterGraph2;

public function merge "Merges the nodes of two different graphs. Needs an ordering function in order to be efficient."
  input list<tuple<NodeType, list<NodeType>>> graph1;
  input list<tuple<NodeType, list<NodeType>>> graph2;
  input EqualFunc eqFunc;
  input CompareFunc compareFunc;
  output list<tuple<NodeType, list<NodeType>>> graph;
  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
  partial function CompareFunc
    "Given two nodes, returns true if the first is ordered before the second."
    input tuple<NodeType,list<NodeType>> inNode1;
    input tuple<NodeType,list<NodeType>> inNode2;
    output Boolean isEqual;
  end CompareFunc;
algorithm
  graph := merge2(List.sort(listAppend(graph1,graph2), compareFunc), eqFunc, {});
end merge;

protected function merge2
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc eqFunc;
  input list<tuple<NodeType, list<NodeType>>> inAcc;
  output list<tuple<NodeType, list<NodeType>>> graph;
  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  graph := match (inGraph,eqFunc,inAcc)
    local
      list<tuple<NodeType, list<NodeType>>> rest;
      tuple<NodeType, list<NodeType>> node;
      NodeType n1,n2;
      list<NodeType> e1,e2;
      Boolean b;
    case ({},_,_) then listReverse(inAcc);
    case ({node},_,_) then listReverse(node::inAcc);
    case ((n1,e1)::(n2,e2)::rest,_,_)
      equation
        b = eqFunc(n1,n2);
        (node,rest) = merge3(b,n1,e1,n2,e2,rest,eqFunc);
      then merge2(rest,eqFunc,node::inAcc);
  end match;
end merge2;

protected function merge3
  input Boolean b;
  input NodeType n1;
  input list<NodeType> e1;
  input NodeType n2;
  input list<NodeType> e2;
  input list<tuple<NodeType, list<NodeType>>> rest;
  input EqualFunc eqFunc;
  output tuple<NodeType, list<NodeType>> elt;
  output list<tuple<NodeType, list<NodeType>>> outRest;
  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
algorithm
  (elt,outRest) := match (b,n1,e1,n2,e2,rest,eqFunc)
    case (true,_,_,_,_,_,_) then ((n1,List.unionOnTrue(e1,e2,eqFunc)),rest);
    case (false,_,_,_,_,_,_) then ((n1,e1),(n2,e2)::rest);
  end match;
end merge3;

annotation(__OpenModelica_Interface="util");
end Graph;

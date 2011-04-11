/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package Graph
" file:        Graph.mo
  package:     Graph
  description: Contains various graph algorithms.

  RCS: $Id$

  This package contains various graph algorithms such as topological sorting. It
  should also contain a graph type, but such a type would need polymorphic
  records that we don't yet support in MetaModelica."

protected import Util;

public function buildGraph
  "This function will build a graph given a list of nodes, an edge function, and
  an extra argument to the edge function. The edge function should generate a
  list of edges for any given node in the list. From this information a graph
  represented by an adjacency list will be built."
  input list<NodeType> inNodes;
  input EdgeFunc inEdgeFunc;
  input ArgType inEdgeArg;
  output list<tuple<NodeType, list<NodeType>>> outGraph;

  replaceable type NodeType subtypeof Any;
  replaceable type ArgType subtypeof Any;
  
  partial function EdgeFunc
    input NodeType inNode;
    input ArgType inArg;
    output list<NodeType> outEdges;
  end EdgeFunc;
algorithm
  outGraph := Util.listThreadTuple(inNodes, 
    Util.listMap1(inNodes, inEdgeFunc, inEdgeArg));
end buildGraph;
  
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

  replaceable type NodeType subtypeof Any;

  partial function EqualFunc
    "Given two nodes, returns true if they are equal, otherwise false."
    input NodeType inNode1;
    input NodeType inNode2;
    output Boolean isEqual;
  end EqualFunc;
protected
  list<tuple<NodeType, list<NodeType>>> start_nodes, rest_nodes;
algorithm
  (rest_nodes, start_nodes) := Util.listSplitOnTrue(inGraph, hasOutgoingEdges);
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

  replaceable type NodeType subtypeof Any;

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
        rest_rest = Util.listMap2(rest_rest, removeEdge, node1, inEqualFunc);
        // Fetch any new nodes that has no dependencies.
        (rest_rest, new_start) = 
          Util.listSplitOnTrue(rest_rest, hasOutgoingEdges);
        // Append those nodes to the list of start nodes.
        rest_start = Util.listAppendNoCopy(rest_start, new_start);
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

  replaceable type NodeType subtypeof Any;
algorithm
  outHasOutEdges := match(inNode)
    case ((_, {})) then false;
    else then true;
  end match;
end hasOutgoingEdges;
  
protected function removeEdge
  "Takes a node with it's edges and a node that's been removed from the graph,
  and removes the edge if it exists in the edge list."
  input tuple<NodeType, list<NodeType>> inNode;
  input NodeType inRemovedNode;
  input EqualFunc inEqualFunc;
  output tuple<NodeType, list<NodeType>> outNode;

  replaceable type NodeType subtypeof Any;

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
  edges := Util.listRemoveFirstOnTrue(inRemovedNode, inEqualFunc, edges);
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

  replaceable type NodeType subtypeof Any;

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

  replaceable type NodeType subtypeof Any;

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

  replaceable type NodeType subtypeof Any;

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
      tuple<NodeType, list<NodeType>> last_node;

    case ((node, _), _, _ :: _, _)
      equation
        // Check if we have already visited this node.
        true = Util.listContainsWithCompareFunc(node, inVisitedNodes,
          inEqualFunc);
        // Check if the current node is the start node, in that case we're back
        // where we started and we have a cycle. Otherwise we just encountered a
        // cycle in the graph that the start node is not part of.
        start_node = Util.listLast(inVisitedNodes);
        is_start_node = inEqualFunc(node, start_node);
        opt_cycle = Util.if_(is_start_node, SOME(inVisitedNodes), NONE());
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

  replaceable type NodeType subtypeof Any;

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

  replaceable type NodeType subtypeof Any;

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

protected function removeNodesFromGraph
  "Removed a list of nodes from the graph. Note that only the nodes are removed
  and not any edges pointing at the nodes."
  input list<NodeType> inNodes;
  input list<tuple<NodeType, list<NodeType>>> inGraph;
  input EqualFunc inEqualFunc;
  output list<tuple<NodeType, list<NodeType>>> outGraph;

  replaceable type NodeType subtypeof Any;

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

    case (_, (graph_node as (node, _)) :: rest_graph, _)
      equation
        (rest_nodes, SOME(_)) = Util.listDeleteMemberOnTrue(node, inNodes,
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

end Graph;

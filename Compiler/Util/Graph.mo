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

end Graph;

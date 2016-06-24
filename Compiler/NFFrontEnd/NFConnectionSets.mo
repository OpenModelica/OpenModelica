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

encapsulated package NFConnectionSets
" file:        NFConnectionSets.mo
  package:     NFConnectionSets
  description: Data structure and utilities to store connection sets.


  This module contains an implementation of a disjoint-set data structure using
  a disjoint-set forest. It's made for handling connection sets, but could
  probably be made more general in MetaModelica 2.
"

public import BaseHashTable;
public import NFConnect2;
public import DAE;

protected import Array;
protected import ComponentReference;
protected import NFConnectUtil2;
protected import Debug;
protected import Flags;
protected import List;
protected import System;
protected import Util;

public type Connector = NFConnect2.Connector;
public type Connection = NFConnect2.Connection;

public type HashKey = Connector;
public type HashValue = Integer;

public type IndexTable = tuple<
  array<list<tuple<HashKey, Integer>>>,
  tuple<Integer, Integer, array<Option<tuple<HashKey, HashValue>>>>,
  Integer, Integer, tuple<FuncHash,FuncEq,FuncKeyString,FuncValString>
>;

partial function FuncHash input HashKey key; input Integer mod; output Integer hash; end FuncHash;
partial function FuncEq input HashKey key1; input HashKey key2; output Boolean b; end FuncEq;
partial function FuncKeyString input HashKey key; output String str; end FuncKeyString;
partial function FuncValString input HashValue val; output String str; end FuncValString;

public uniontype DisjointSets
  "The disjoint-set data structure."
  record DISJOINT_SETS
    array<Node> nodes "A collection of all the nodes in the forest.";
    IndexTable indices "A value->node index mapping table.";
    Integer nodeCount "The number of nodes in the forest.";
  end DISJOINT_SETS;
end DisjointSets;

public uniontype Node
  "Represents a node in the disjoint-set forest."
  record NODE
    Connector element "The connector element represented by the node.";
    Integer parent "The index of this nodes parent. If the node does not have a
      parent, i.e. it's the root of a tree, this is instead the height of the
      tree expressed as a negative number.";
    Integer index "The index of this node.";
  end NODE;

  record NO_NODE "Used to fill the node array when it's created." end NO_NODE;
end Node;

protected function connectorHashFunc
  "Hashes a connector."
  input Connector inConnector;
  input Integer inMod;
  output Integer outHash;
protected
  DAE.ComponentRef cref;
  String cref_str;
algorithm
  NFConnect2.CONNECTOR(name = cref) := inConnector;
  /***************************************************************************/
  // TODO: Check if it's better for connectors with different faces to have
  // different hashes or not. Is one way more efficient than the other?
  /***************************************************************************/
  cref_str := ComponentReference.printComponentRefStr(cref);
  outHash := System.stringHashDjb2Mod(cref_str, inMod);
end connectorHashFunc;

protected function emptyIndexTableSized
  "Creates an empty index table with the given size."
  input Integer inSize;
  output IndexTable outTable;
algorithm
  outTable := BaseHashTable.emptyHashTableWork(inSize,
    (connectorHashFunc, NFConnectUtil2.connectorEqual, NFConnectUtil2.connectorStr, intString));
end emptyIndexTableSized;

public function emptySets
  "Creates a new disjoint-sets structure."
  input Integer inConnectionCount;
  output DisjointSets outSets;
protected
  array<Node> nodes;
  IndexTable indices;
  Integer sz;
algorithm
  sz := intMax(inConnectionCount, 3);
  nodes := arrayCreate(sz, NO_NODE());
  indices := emptyIndexTableSized(Util.nextPrime(sz));
  outSets := DISJOINT_SETS(nodes, indices, 0);
end emptySets;

public function add
  "Adds a connector as a node in the disjoint-sets forest. This function assumes
   that the node does not already exist. If the node might exist already, use
   find to add it instead."
  input Connector inConnector;
  input DisjointSets inSets;
  output DisjointSets outSets;
algorithm
  (_, outSets) := add_impl(inConnector, inSets);
end add;

public function update
  "Updates a node in the disjoint sets by replacing the Connector variable."
  input Connector inConnector;
  input DisjointSets inSets;
  output DisjointSets outSets;
protected
  array<Node> nodes;
  IndexTable indices;
  Integer nc, index, parent;
  Node node;
algorithm
  DISJOINT_SETS(nodes, indices, nc) := inSets;
  index := BaseHashTable.get(inConnector, indices);
  NODE(_, parent, _) := arrayGet(nodes, index);
  node := NODE(inConnector, parent, index);
  nodes := arrayUpdate(nodes, index, node);
  outSets := DISJOINT_SETS(nodes, indices, nc);
end update;

protected function find
  "This function finds and returns the node associated with a given connector.
   If the connector does not a have a node in the forest, then a new node will
   be added and returned.

   The reason why this function also returns the sets is because it does path
   compression, and the disjoint-set structure may therefore be changed during
   look up."
  input Connector inConnector;
  input DisjointSets inSets;
  output Node outNode;
  output DisjointSets outSets;
algorithm
  (outNode, outSets) := matchcontinue(inConnector, inSets)
    local
      array<Node> nodes;
      IndexTable indices;
      Integer index;
      Node node;
      DisjointSets sets;

    // A node already exists in the forest, return its root.
    case (_, DISJOINT_SETS(nodes = nodes, indices = indices))
      equation
        // Look up the index for the connector.
        index = BaseHashTable.get(inConnector, indices);
        // Look up the node corresponding to that index.
        node = arrayGet(nodes, index);
      then
        (node, inSets);

    // A node doesn't exist in the forest, create a new node and return it.
    else
      equation
        (node, sets) = add_impl(inConnector, inSets);
      then
        (node, sets);

  end matchcontinue;
end find;

public function findConnector
  "This function finds and returns a connector from the disjoint sets. It might
   seem strange that the input also is a connector, but this function can be
   used to find a connector when you only now e.g. the name of it by
   constructing a dummy connector."
  input Connector inConnector;
  input DisjointSets inSets;
  output Connector outConnector;
  output DisjointSets outSets;
algorithm
  (NODE(element = outConnector), outSets) := find(inConnector, inSets);
end findConnector;

public function findSet
  "This function finds and returns the set that the given connectors belongs to.
   The set is represented by the root-node of the tree. If the connector does
   not have a corresponding node in the forest, then a new set with the
   connector as the only element will be added to the forest and returned.

   The reason why this function also returns the sets is because it does path
   compression, and the disjoint-set structure may therefore be changed during
   look up."
  input Connector inConnector;
  input DisjointSets inSets;
  output Node outNode;
  output DisjointSets outSets;
protected
  array<Node> nodes;
  Node node;
  DisjointSets sets;
algorithm
  (node, outSets) := find(inConnector, inSets);
  DISJOINT_SETS(nodes = nodes) := inSets;
  outNode := findRoot(node, nodes);
end findSet;

public function merge
  "Merges the two sets that the given connectors belong to."
  input Connector inConnector1;
  input Connector inConnector2;
  input DisjointSets inSets;
  output DisjointSets outSets;
algorithm
  outSets := match(inConnector1, inConnector2, inSets)
    local
      Node set1, set2;
      DisjointSets sets;

    case (_, _, sets)
      equation
        (set1, sets) = findSet(inConnector1, sets);
        (set2, sets) = findSet(inConnector2, sets);
      then
        union(set1, set2, sets);

  end match;
end merge;

public function expandAddConnection
  input Connection inConnection;
  input DisjointSets inSets;
  output DisjointSets outSets;
algorithm
  outSets := match(inConnection, inSets)
    local
      Connector lhs, rhs;
      list<Connector> lhs_connl, rhs_connl;
      DisjointSets sets;

    case (NFConnect2.CONNECTION(lhs = lhs, rhs = rhs), sets)
      equation
        lhs_connl = NFConnectUtil2.expandConnector(lhs);
        rhs_connl = NFConnectUtil2.expandConnector(rhs);
        sets = List.threadFold(lhs_connl, rhs_connl, merge, sets);
      then
        sets;

  end match;
end expandAddConnection;

public function getNodeCount
  "Returns the number of nodes in the disjoint-set forest."
  input DisjointSets inSets;
  output Integer outNodeCount;
algorithm
  DISJOINT_SETS(nodeCount = outNodeCount) := inSets;
end getNodeCount;

public function extractSets
  "Extracts a list of all the sets from the disjoint sets structure."
  input DisjointSets inSets;
  output list<list<Connector>> outSets;
algorithm
  outSets := match(inSets)
    local
      array<Node> nodes;
      Integer node_count, set_count;
      list<Node> node_list;
      array<list<Connector>> sets;
      list<list<Connector>> set_list;

    case (DISJOINT_SETS(nodes = nodes, nodeCount = node_count))
      equation
        // For each node, assign it an index which indicates which set it
        // belongs to. Collect the nodes in a list.
        (node_list, set_count) = assignSetIndices(nodes, node_count, 1, 0, {});
        // Create an array of connector lists, and use the nodes' set index to
        // put them in the array.
        sets = arrayCreate(set_count, {});
        sets = List.fold(node_list, collectSets, sets);
        // Finally, convert the array into a list and return it.
        set_list = arrayList(sets);
      then
        set_list;

  end match;
end extractSets;

protected function assignSetIndices
  "Assigns each node an index which indicates which set it belongs to, so that
   they can be sorted into sets by extractSets."
  input array<Node> inNodes;
  input Integer inNodeCount;
  input Integer inPos;
  input Integer inNextIndex;
  input list<Node> inAccumNodes;
  output list<Node> outNodes;
  output Integer outSetCount;
algorithm
  (outNodes, outSetCount) :=
  matchcontinue(inNodes, inNodeCount, inPos, inNextIndex, inAccumNodes)
    local
      Node node;
      Integer next_index, pos;
      list<Node> accum;
      Boolean is_node;

    case (_, _, _, _, _)
      equation
        true = inPos > inNodeCount;
      then
        (inAccumNodes, inNextIndex);

    else
      equation
        node = inNodes[inPos];
        (node, next_index, is_node) = assignSetIndex(node, inNodes, inNextIndex);
        accum = List.consOnTrue(is_node, node, inAccumNodes);
        pos = inPos + 1;
        (accum, next_index) =
          assignSetIndices(inNodes, inNodeCount, pos, next_index, accum);
      then
        (accum, next_index);

  end matchcontinue;
end assignSetIndices;

protected function assignSetIndex
  "Assigns a node an index which indicates which set it belongs to. This is done
   by giving each root node a unique index, and then assigning each node the same
   index as its parent. This function will thus update all the nodes from the
   given node up to the root of its tree."
  input Node inNode;
  input array<Node> inNodes;
  input Integer inNextIndex;
  output Node outNode;
  output Integer outNextIndex;
  output Boolean outIsNode;
algorithm
  (outNode, outNextIndex, outIsNode) := matchcontinue(inNode, inNodes, inNextIndex)
    local
      Integer parent, next_index, index, index2;
      Node node;
      Connector conn;

    // Not a node, should be removed.
    case (NO_NODE(), _, _) then (inNode, inNextIndex, false);

    // A node which has already been assigned an index, nothing to do.
    case (NODE(parent = 0), _, _) then (inNode, inNextIndex, true);

    // A root node, assign it the next available index.
    case (NODE(conn, parent, index), _, _)
      equation
        true = parent < 0;
        next_index = inNextIndex + 1;
        node = NODE(conn, 0, next_index);
        arrayUpdate(inNodes, index, node);
      then
        (node, next_index, true);

    // An unassigned node, assign it the same index as the root of its tree.
    case (NODE(conn, parent, index), _, _)
      equation
        // Find the parent.
        node = inNodes[parent];
        // Assign the parent an index.
        (NODE(index = index2), next_index, _) =
          assignSetIndex(node, inNodes, inNextIndex);
        // Assign this node its parent's index.
        node = NODE(conn, 0, index2);
        arrayUpdate(inNodes, index, node);
      then
        (node, next_index, true);

  end matchcontinue;
end assignSetIndex;

protected function collectSets
  "Adds a connector to the set array at the position indicated by the index of
   its node."
  input Node inNode;
  input array<list<Connector>> inSets;
  output array<list<Connector>> outSets;
protected
  Connector conn;
  Integer set_index;
  list<Connector> set;
algorithm
  NODE(element = conn, index = set_index) := inNode;
  set := inSets[set_index];
  set := conn :: set;
  outSets := arrayUpdate(inSets, set_index, set);
end collectSets;

protected function makeNode
  "Creates a node from a connector and an index."
  input Connector inConnector;
  input Integer inIndex;
  output Node outNode;
algorithm
  outNode := NODE(inConnector, -1, inIndex);
end makeNode;

protected function add_impl
  "Adds a connector as a node in the disjoint-sets forest. This function assumes
   that the node does not already exist. If the node might exist already, use
   find to add it instead."
  input Connector inConnector;
  input DisjointSets inSets;
  output Node outNode;
  output DisjointSets outSets;
algorithm
  (outNode, outSets) := matchcontinue(inConnector, inSets)
    local
      array<Node> nodes;
      IndexTable indices;
      Integer nc;
      Node node;

    case (_, DISJOINT_SETS(nodes, indices, nc))
      equation
        // Increase the node count and use that as the node index.
        nc = nc + 1;
        node = makeNode(inConnector, nc);
        // Make sure that we have space available in the node array.
        nodes = Array.expandOnDemand(nc, nodes, 1.4, NO_NODE());
        // Add the new node to the node array and register its index in the
        // index table.
        nodes = arrayUpdate(nodes, nc, node);
        indices = BaseHashTable.addNoUpdCheck((inConnector, nc), indices);
      then
        (node, DISJOINT_SETS(nodes, indices, nc));

    else
      equation
        true = Flags.isSet(Flags.FAILTRACE);
        Debug.trace("- ConnecionSets.add_impl failed on connector ");
        Debug.traceln(NFConnectUtil2.connectorStr(inConnector));
      then
        fail();

  end matchcontinue;
end add_impl;

protected function findRoot
  "Finds the root of the tree that a node belongs to."
  input Node inNode;
  input array<Node> inNodes;
  output Node outRoot;
algorithm
  outRoot := match(inNode, inNodes)
    local
      Connector conn;
      Integer index, parent_id;
      Node parent;

    // Found the root, return it.
    case (NODE(parent = parent_id), _) guard parent_id < 0
      then
        inNode;

    case (NODE(_, parent_id, _), _)
      equation
        // Look up the parent to this node and continue looking.
        parent = arrayGet(inNodes, parent_id);
        (parent as NODE()) = findRoot(parent, inNodes);

        // Path compression. Any node found while looking for the root may as
        // well be attached to the root node directly so that future look up is
        // faster.
        /*********************************************************************/
        // TODO: This should in theory make the algorithm faster, but
        // constructed tests show that it makes it slower due to the
        // array update overhead. The performance needs to be tested on real
        // models to see how it behaves.
        /*********************************************************************/
        //node = NODE(conn, parent_id, index, rank);
        //arrayUpdate(inNodes, index, node);
      then
        parent;

  end match;
end findRoot;

protected function union
  "Merges two sets into one."
  input Node inSet1;
  input Node inSet2;
  input DisjointSets inSets;
  output DisjointSets outSets;
algorithm
  outSets := match(inSet1, inSet2, inSets)
    local
      Integer index, index2, rank1, rank2, rc, nc;
      array<Node> nodes;
      IndexTable indices;

    // The nodes are the same, do nothing.
    case (NODE(index = index), NODE(index = index2), _) guard intEq(index, index2)
      then
        inSets;

    // Otherwise, merge them.
    case (NODE(parent = rank1), NODE(parent = rank2),
        DISJOINT_SETS(nodes, indices, nc))
      equation
        rc = Util.intCompare(rank1, rank2);
        nodes = union2(rc, inSet1, inSet2, nodes);
      then
        DISJOINT_SETS(nodes, indices, nc);

  end match;
end union;

protected function union2
  "Helper function to union, merges two sets. This is done by attaching one
   set-tree to the other. The ranks are compared to determine which of the trees
   is the smallest, and that one is attached to the larger one to keep the trees
   as flat as possible."
  input Integer inRankCompare;
  input Node inSet1;
  input Node inSet2;
  input array<Node> inNodes;
  output array<Node> outNodes;
algorithm
  outNodes := match(inRankCompare, inSet1, inSet2, inNodes)
    local
      Connector conn, conn2;
      Integer parent, index, index2, rank;
      Node set, set2;
      array<Node> nodes;

    // The first set is the smallest, attach it to the second set.
    case ( 1, NODE(conn, _, index), NODE(index = parent), _)
      equation
        set = NODE(conn, parent, index);
      then
        arrayUpdate(inNodes, index, set);

    // The second set is the smallest, attach it to the first set.
    case (-1, NODE(index = parent), NODE(conn, _, index), _)
      equation
        set = NODE(conn, parent, index);
      then
        arrayUpdate(inNodes, index, set);

    // Both trees are equally high. Attach the second to the first, and increase
    // the rank of the first with one.
    case ( 0, NODE(conn, rank, index),
              NODE(conn2, _, index2), nodes)
      equation
        rank = rank - 1;
        set = NODE(conn, rank, index);
        nodes = arrayUpdate(nodes, index, set);
        set2 = NODE(conn2, index, index2);
        nodes = arrayUpdate(nodes, index2, set2);
      then
        nodes;

  end match;
end union2;

public function printSets
  "Print out the sets for debugging."
  input DisjointSets inSets;
protected
  array<Node> nodes;
  Integer nc;
algorithm
  DISJOINT_SETS(nodes, _, nc) := inSets;
  print(intString(nc) + " sets:\n");
  printNodes(arrayList(nodes));
end printSets;

public function printNodes
  "Prints out a list of nodes for debugging."
  input list<Node> inNodes;
algorithm
  _ := match(inNodes)
    local
      list<Node> rest;
      Node node;

    case (NO_NODE() :: rest) equation printNodes(rest); then ();
    case (node :: rest)
      equation
        printNode(node);
        printNodes(rest);
      then
        ();
    case ({}) then ();

  end match;
end printNodes;

protected function printNode
  "Prints out a node for debugging."
  input Node inNode;
algorithm
  _ := match(inNode)
    local
      Connector conn;
      Integer index, parent_id;
      String conn_str;

    case NODE(conn, parent_id, index)
      equation
        conn_str = NFConnectUtil2.connectorStr(conn);
        print("[" + intString(index) + "] " + conn_str + " -> " +
          intString(parent_id) + "\n");
      then
        ();

  end match;
end printNode;

annotation(__OpenModelica_Interface="frontend");
end NFConnectionSets;

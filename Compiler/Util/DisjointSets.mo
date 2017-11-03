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

encapsulated partial package DisjointSets
import Array;
import BaseHashTable;
import Util;

public
replaceable type Entry = Integer;

replaceable partial function EntryHash
  input Entry entry;
  input Integer mod;
  output Integer hash;
end EntryHash;

replaceable partial function EntryEqual
  input Entry entry1;
  input Entry entry2;
  output Boolean isEqual;
end EntryEqual;

replaceable partial function EntryString
  input Entry entry;
  output String str;
end EntryString;

uniontype Sets
  "This is a disjoint sets data structure. The nodes are stored in an array of
   Integers. The root elements of a set is given a negative value that
   corresponds to its rank, while other elements are given positive values that
   corresponds to the index of their parent in the array. The hashtable is used
   to look up the array index of a entry, and is also used to store the entries."

  record DISJOINT_SETS
    array<Integer> nodes "An array of nodes";
    IndexTable elements "A Entry->Integer hashtable, see bottom of file.";
    Integer nodeCount "The number of nodes stored in the sets.";
  end DISJOINT_SETS;
end Sets;

function emptySets
  "Creates a new disjoint-sets structure."
  input Integer setCount;
  output Sets sets;
protected
  array<Integer> nodes;
  IndexTable elements;
  Integer sz;
algorithm
  // Create an array as large as the number of sets given, or at least 3 to
  // avoid issues.
  sz := max(setCount, 3);
  // Fill the array with -1, which is the value of a newly added element.
  nodes := arrayCreate(sz, -1);
  elements := emptyIndexTableSized(Util.nextPrime(sz));
  sets := Sets.DISJOINT_SETS(nodes, elements, 0);
end emptySets;

function add
  "Adds an entry to the disjoint-sets forest. This function assumes that the
   entry does not already exist in the forest. If the entry might exist already,
   use find instead."
  input Entry entry;
  input output Sets sets;
        output Integer index;
protected
  array<Integer> nodes;
  IndexTable elements;
  Integer node_count;
algorithm
  Sets.DISJOINT_SETS(nodes, elements, node_count) := sets;
  index := node_count + 1;

  // Make sure that we have enough space in the node array. New nodes have the
  // value -1, so we don't actually need to add a node to the array, just expand
  // it and fill the new places with -1.
  if index > arrayLength(nodes) then
    nodes := Array.expand(realInt(intReal(index) * 1.4), nodes, -1);
  end if;

  // Register the node index in the index table.
  elements := BaseHashTable.addNoUpdCheck((entry, index), elements);
  sets := Sets.DISJOINT_SETS(nodes, elements, index);
end add;

function addList
  "Adds a list of entries to the disjoint-sets forest, in a more efficient
   manner than calling add repeatedly. This function assumes that the entries
   does not already exist in the forest. If the entries might exist already, use
   find instead."
  input list<Entry> entries;
  input output Sets sets;
protected
  array<Integer> nodes;
  IndexTable elements;
  Integer node_count, sz, index;
algorithm
  Sets.DISJOINT_SETS(nodes, elements, node_count) := sets;
  sz := listLength(entries);
  index := node_count + 1;
  node_count := node_count + sz;

  if node_count > arrayLength(nodes) then
    nodes := Array.expand(realInt(intReal(node_count) * 1.4), nodes, -1);
  end if;

  for e in entries loop
    elements := BaseHashTable.addNoUpdCheck((e, index), elements);
    index := index + 1;
  end for;

  sets := Sets.DISJOINT_SETS(nodes, elements, node_count);
end addList;

function findSet
  "This function finds and returns the set that the given entry belongs to.
   The set is represented by the root node of the tree. If the entry does not
   have a corresponding node in the forest, then a new set with the entry as the
   only element will be added to the forest and returned.

   The reason why this function also returns the sets is because it does path
   compression, and the disjoint-set structure may therefore be changed during
   look up."
  input Entry entry;
  input Sets sets;
  output Integer set;
  output Sets updatedSets;
protected
  Integer index;
algorithm
  // Look up the index of the entry.
  (updatedSets, index) := find(entry, sets);
  // Return the index of the root of the tree that the entry belongs to.
  set := findRoot(index, updatedSets.nodes);
end findSet;

function findSetArrayIndex
  "Returns the index of the set the entry belongs to, or fails if the
   entry doesn't belong to a set."
  input Entry entry;
  input Sets sets;
  output Integer set;
algorithm
  // Look up the index of the given entry.
  set := BaseHashTable.get(entry, sets.elements);

  // Follow the indices until a negative index is found, which is the set index.
  while set > 0 loop
    set := sets.nodes[set];
  end while;

  // Negate the index to get the actual set index.
  set := -set;
end findSetArrayIndex;

function merge
  "Merges the two sets that the given entry belong to."
  input Entry entry1;
  input Entry entry2;
  input output Sets sets;
protected
  Integer set1, set2;
algorithm
  (set1, sets) := findSet(entry1, sets);
  (set2, sets) := findSet(entry2, sets);
  sets := union(set1, set2, sets);
end merge;

function find
  "This function finds and returns the node associated with a given entry.
   If the entry does not a have a node in the forest, then a new node will be
   added and returned.

   The reason why this function also returns the sets is because it does path
   compression, and the disjoint-set structure may therefore be changed during
   look up."
  input Entry entry;
  input output Sets sets;
        output Integer index;
algorithm
  // TODO: Replace with try once the bootstrapping has been updated.
  _ := matchcontinue () case () algorithm
    // Check if a node already exists in the forest.
    index := BaseHashTable.get(entry, sets.elements);
  then (); else algorithm
    // If a node doesn't already exist, create a new one.
    (sets, index) := add(entry, sets);
  then (); end matchcontinue;
end find;

function findRoot
  "Returns the index of the root of the tree that a node belongs to."
  input Integer nodeIndex;
  input array<Integer> nodes;
  output Integer rootIndex = nodeIndex;
protected
  Integer parent = nodes[nodeIndex], idx = nodeIndex;
algorithm
  // Follow the parent indices until we find a negative index, which indicates a root.
  while parent > 0 loop
    rootIndex := parent;
    parent := nodes[parent];
  end while;

  // Path compression. Attach each of the traversed nodes directly to the root,
  // to speed up repeated calls.
  parent := nodes[nodeIndex];
  while parent > 0 loop
    arrayUpdate(nodes, idx, rootIndex);
    idx := parent;
    parent := nodes[parent];
  end while;
end findRoot;

function union
  "Merges two sets into one. This is done by attaching one set-tree to the
   other. The ranks are compared to determine which of the trees is the
   smallest, and that one is attached to the larger one to keep the trees as
   flat as possible."
  input Integer set1;
  input Integer set2;
  input output Sets sets;
protected
  Integer rank1, rank2;
algorithm
  if set1 <> set2 then
    // Assume that the indices actually point to root nodes, in which case the
    // entries in the node array is actually the ranks of the nodes.
    rank1 := sets.nodes[set1];
    rank2 := sets.nodes[set2];

    if rank1 > rank2 then
      // First set is smallest, attach it to the second set.
      arrayUpdate(sets.nodes, set2, set1);
    elseif rank1 < rank2 then
      // Second set is smallest, attach it to the first set.
      arrayUpdate(sets.nodes, set1, set2);
    else
      // Both sets are the same size. Attach the second to the first, and
      // increase the rank of the first with one (which means decreasing it,
      // since the rank is stored as a negative number).
      arrayUpdate(sets.nodes, set1, sets.nodes[set1] - 1);
      arrayUpdate(sets.nodes, set2, set1);
    end if;
  end if;
end union;

function getNodeCount
  "Returns the number of nodes in the disjoint-set forest."
  input Sets sets;
  output Integer nodeCount = sets.nodeCount;
end getNodeCount;

function extractSets
  "Extracts all the sets from the disjoint sets structure, and returns
   them as an array. The function also returns a new DisjointSets structure where
   all roots have been assigned a set index, which can be used for looking up
   sets in the array with findSetArrayIndex."
  input Sets sets;
  output array<list<Entry>> setsArray "An array with all the sets.";
  output Sets assignedSets "Sets with the roots assigned to sets.";
protected
  array<Integer> nodes;
  Integer set_idx = 0, idx;
  list<tuple<Entry, Integer>> entries;
  Entry e;
algorithm
  nodes := sets.nodes;

  // Go through each node and assign a unique set index to each root node.
  // The index is stored as a negative number to mark the node as a root.
  for i in 1:sets.nodeCount loop
    if nodes[i] < 0 then
      set_idx := set_idx + 1;
      nodes[i] := -set_idx;
    end if;
  end for;

  // Create an array of lists to store the sets in, and fetch the list of
  // entry-index pairs stored in the hashtable.
  setsArray := arrayCreate(set_idx, {});
  entries := BaseHashTable.hashTableListReversed(sets.elements);

  // Go through each entry-index pair.
  for p in entries loop
    (e, idx) := p;
    // Follow the parent indices until we find the root.
    set_idx := nodes[idx];

    while set_idx > 0 loop
      set_idx := nodes[set_idx];
    end while;

    // Negate the set index to get the actual index.
    set_idx := -set_idx;
    // Add the entry to the list pointed to by the set index.
    setsArray[set_idx] := e :: setsArray[set_idx];
  end for;

  assignedSets := Sets.DISJOINT_SETS(nodes, sets.elements, sets.nodeCount);
end extractSets;

function printSets
  "Print out the sets for debugging."
  input Sets sets;
protected
  array<Integer> nodes;
  list<tuple<Entry, Integer>> entries;
  Entry e;
  Integer i;
algorithm
  print(intString(sets.nodeCount) + " sets:\n");
  nodes := sets.nodes;
  entries := BaseHashTable.hashTableList(sets.elements);

  for p in entries loop
    (e, i) := p;
    print("[");
    print(String(i));
    print("]");
    print(EntryString(e));
    print(" -> ");
    print(String(nodes[i]));
    print("\n");
  end for;
end printSets;


// Hashtable used by the DisjointSets structure.
type HashValue = Integer;
type IndexTable = tuple<
  array<list<tuple<Entry, Integer>>>,
  tuple<Integer, Integer, array<Option<tuple<Entry, HashValue>>>>,
  Integer, tuple<FuncHash, FuncEq, FuncKeyString, FuncValString>>;

partial function FuncHash
  input Entry key;
  input Integer mod;
  output Integer hash;
end FuncHash;

partial function FuncEq
  input Entry key1;
  input Entry key2;
  output Boolean res;
end FuncEq;

partial function FuncKeyString
  input Entry key;
  output String str;
end FuncKeyString;

partial function FuncValString
  input HashValue val;
  output String str;
end FuncValString;

protected
function emptyIndexTableSized
  "Creates an empty index table with the given size."
  input Integer tableSize;
  output IndexTable table;
algorithm
  table := BaseHashTable.emptyHashTableWork(tableSize,
    (EntryHash, EntryEqual, EntryString, intString));
end emptyIndexTableSized;

annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end DisjointSets;

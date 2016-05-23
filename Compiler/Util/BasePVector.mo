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

encapsulated partial package BasePVector
"
  This is a base class for a persistent dynamic array. That means that it
  automatically allocates memory as needed, and all operations are
  non-destructive (i.e. a new Vector is created instead of modifying an existing
  one). It is implemented as a persistent bit-partitioned vector trie with tail
  optimization, and lookup and modifications of the Vector are effectively
  constant time (technically log32(N)). To use it, extend the package and
  redeclare the element type T:

    encapsulated package IntVector
      import BasePVector;
      extends BasePVector(redeclare type T = Integer);
      annotation(__OpenModelica_Interface=\"util\");
    end IntVector;
"

replaceable type T = Integer; // Should be Any.

import List;
protected
import MetaModelica.Dangerous;

uniontype Vector
  record VECTOR
    Node root "The tree containing the elements.";
    array<Node> tail "The last added elements.";
    Integer size "The number of elements in the Vector.";
    Integer shift "Height of the tree * 5.";
  end VECTOR;
end Vector;

uniontype Node
  record NODE
    "A node in the tree, containing 32 children."
    array<Node> children;
  end NODE;

  record VALUE
    "A leaf containing the value of an element."
    T value;
  end VALUE;

  record EMPTY
    "An empty leaf."
  end EMPTY;
end Node;

protected
// Some constants used internally by the Vector. Since modifications are
// non-destructive we can have an empty Vector as a constant instead of
// creating a new Vector each time we need an empty one.
constant Node EMPTY_NODE = NODE(arrayCreate(32, EMPTY()));
constant Vector EMPTY_VEC = VECTOR(EMPTY_NODE, arrayCreate(0, EMPTY()), 0, 5);

public
function new
  "Returns a new empty Vector."
  output Vector outVector = EMPTY_VEC;
end new;

function add
  "Appends a value to the end of the Vector."
  input Vector inVector;
  input T inValue;
  output Vector outVector = inVector;
algorithm
  outVector := match outVector
    local
      array<Node> tail, nodes;
      Node root, tail_node;
      Integer sz, shift;

    // Space left in the tail, insert the value in the tail.
    case VECTOR(tail = tail) guard(arrayLength(tail) < 32)
      algorithm
        outVector.tail := tailAdd(tail, VALUE(inValue));
        outVector.size := outVector.size + 1;
      then
        outVector;

    // No space left in the tail. Push the tail into the tree and create a new
    // tail to add the value to.
    case VECTOR(root, tail, sz, shift)
      algorithm
        (root, shift) := pushTail(root, tail, sz, shift);
        tail := arrayCreate(1, VALUE(inValue));
      then
        VECTOR(root, tail, sz + 1, shift);

  end match;
end add;

function addList
  "Appends a list of values to the end of the Vector. This function is more
   efficient than calling add multiple times, since it doesn't need to create a
   new Vector for each added element."
  input Vector inVector;
  input list<T> inList;
  output Vector outVector = inVector;
protected
  array<Node> tail;
  Node root;
  Integer sz, shift, tail_len, list_len, rest_len;
  list<T> rest = inList;
  list<Node> node_lst;
  T e;
algorithm
  VECTOR(root, tail, sz, shift) := inVector;
  tail_len := arrayLength(tail);
  list_len := listLength(inList);

  // Check if we have enough space left in the tail for the whole list.
  if tail_len + list_len <= 32 then
    // Space left in the tail, just append the list to the it.
    node_lst := list(VALUE(v) for v in inList);
    tail := arrayAppend(tail, listArray(node_lst));
    sz := sz + list_len;
  else
    // More elements than can fit in the tail.
    // If the tail isn't already full, fill it up.
    if tail_len < 32 then
      node_lst := {};
      for i in tail_len+1:32 loop
        e :: rest := rest;
        node_lst := VALUE(e) :: node_lst;
      end for;
      tail := arrayAppend(tail, List.listArrayReverse(node_lst));
    end if;

    // Keep track of the size so we know where to push new nodes.
    sz := sz + (32 - tail_len);
    rest_len := list_len - (32 - tail_len);

    // Push the now full tail into the tree.
    (root, shift) := pushTail(root, tail, sz, shift);

    // While we have more than 32 elements left to add, take 32 of them at a
    // time and push them down into the tree.
    while rest_len > 32 loop
      tail := MetaModelica.Dangerous.arrayCreateNoInit(32, EMPTY());

      for i in 1:32 loop
        e :: rest := rest;
        tail[i] := VALUE(e);
      end for;

      sz := sz + 32;
      (root, shift) := pushTail(root, tail, sz, shift);
      rest_len := rest_len - 32;
    end while;

    // Make a new tail of the remaining elements.
    node_lst := list(VALUE(v) for v in rest);
    tail := listArray(node_lst);
    sz := sz + arrayLength(tail);
  end if;

  outVector := VECTOR(root, tail, sz, shift);
end addList;

function get
  "Returns the element at the given index. Fails if the index is out of bounds."
  input Vector inVector;
  input Integer inIndex;
  output T outValue;
protected
  Integer tail_off = tailOffset(length(inVector));
  array<Node> nodes;
algorithm
  if inIndex <= tail_off then
    // Look the element up in the tree.
    NODE(children = nodes) := nodeParent(inVector, inIndex);
    VALUE(outValue) := nodes[intBitAnd(inIndex - 1, 31) + 1];
  else
    // Look the element up in the tail.
    VECTOR(tail = nodes) := inVector;
    VALUE(outValue) := nodes[inIndex - tail_off];
  end if;
end get;

function set
  "Sets the element at the given index to the given value. Fails if the index is
   out of bounds."
  input Vector inVector;
  input Integer inIndex;
  input T inValue;
  output Vector outVector = inVector;
algorithm
  outVector := match outVector
    local
      Integer tail_off;

    case VECTOR()
      algorithm
        true := inIndex > 0 and inIndex <= outVector.size;
        tail_off := tailOffset(outVector.size);

        if inIndex <= tail_off then
          // The element is in the tree.
          outVector.root := nodeSet(outVector.root, inIndex, VALUE(inValue), outVector.shift);
        else
          // The element is in the tail.
          outVector.tail := arrayCopy(outVector.tail);
          arrayUpdate(outVector.tail, inIndex - tail_off, VALUE(inValue));
        end if;
      then
        outVector;
  end match;
end set;

function last
  "Returns the last value in the Vector. Fails if the Vector is empty."
  input Vector inVector;
  output T outValue;
protected
  array<Node> tail;
algorithm
  VECTOR(tail = tail) := inVector;
  VALUE(outValue) := tail[arrayLength(tail)];
end last;

function pop
  "Removes the last value in the Vector. Fails if the Vector is empty."
  input Vector inVector;
  output Vector outVector = inVector;
algorithm
  outVector := match outVector
    local
      array<Node> tail, nodes;
      Node root;
      Integer sz, shift;

    // Fail if the Vector is empty.
    case VECTOR(size = 0) then fail();
    // Vector with one element => empty Vector.
    case VECTOR(size = 1) then EMPTY_VEC;

    // Tail contains more than one element, remove the last of them.
    case VECTOR(tail = tail) guard(arrayLength(tail)) > 1
      algorithm
        outVector.tail := tailPop(tail);
        outVector.size := outVector.size - 1;
      then
        outVector;

    // Tail contains one element. Remove the last added tail from the tree, and
    // use it as the new tail.
    case VECTOR(root, tail, sz, shift)
      algorithm
        NODE(children = tail) := nodeParent(inVector, sz - 2);
        root := popTail(root, shift, sz);

        if isEmptyNode(root) then
          // The node removed from the tree was the last,
          // replace the tree with an empty tree.
          root := EMPTY_NODE;
        end if;

        NODE(children = nodes) := root;

        if shift > 5 and isEmptyNode(nodes[2]) then
          // If the root node only has one child, replace the root with it to
          // reduce the height of the tree.
          root := nodes[1];
          shift := shift - 5;
        end if;
      then
        VECTOR(root, tail, sz - 1, shift);

  end match;
end pop;

function map
  "Returns a new Vector where the given function has been applied to each
   element in sequential order."
  input Vector inVector;
  input MapFunc inFunc;
  output Vector outVector = inVector;

  partial function MapFunc
    input T inValue;
    output T outValue;
  end MapFunc;
algorithm
  outVector := match outVector
    case VECTOR()
      algorithm
        outVector.root := mapNode(outVector.root, inFunc);
        outVector.tail := mapNodeArray(outVector.tail, inFunc);
      then
        outVector;

  end match;
end map;

function fold<FT>
  "Applies the given function to each element in the Vector, updating the given
   argument as it goes along."
  input Vector inVector;
  input FoldFunc inFunc;
  input FT inStartValue;
  output FT outResult;

  partial function FoldFunc
    input T inValue;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
protected
  Node root;
  array<Node> tail;
algorithm
  VECTOR(root = root, tail = tail) := inVector;
  outResult := foldNode(root, inFunc, inStartValue);
  outResult := foldNodeArray(tail, inFunc, outResult);
end fold;

function size
  "Returns the number of elements in the Vector."
  input Vector inVector;
  output Integer outSize;
algorithm
  VECTOR(size = outSize) := inVector;
end size;

// Alias for size, since size can't be used inside this package (the compiler
// mistakes it for the builtin size).
function length = size;

function isEmpty
  "Returns true if the Vector is empty, otherwise false."
  input Vector inVector;
  output Boolean outIsEmpty;
protected
  Integer sz;
algorithm
  VECTOR(size = sz) := inVector;
  outIsEmpty := sz == 0;
end isEmpty;

function fromList
  "Creates a Vector from a list."
  input list<T> inList;
  output Vector outVector = addList(EMPTY_VEC, inList);
end fromList;

function toList
  "Creates a list from a Vector."
  input Vector inVector;
  output list<T> outList = listReverse(toReversedList(inVector));
end toList;

function toReversedList
  input Vector inVector;
  output list<T> outList = fold(inVector, cons, {});
end toReversedList;

function fromArray
  "Creates a Vector from an array."
  input array<T> inArray;
  output Vector outVector = addList(EMPTY_VEC, arrayList(inArray));
end fromArray;

function toArray
  "Creates an array from a Vector."
  input Vector inVector;
  output array<T> outArray = listArray(toList(inVector));
end toArray;

function printDebug
  input Vector inVector;
protected
  Node root;
  array<Node> tail;
  Integer sz, shift;
algorithm
  VECTOR(root, tail, sz, shift) := inVector;
  print("PVector(size = " + intString(sz) + ", shift = " + intString(shift) + "):\n");
  print("  tail: [");
  for e in tail loop
    printDebugNode(e, "");
  end for;
  print("]");
  printDebugNode(root, "  ");
  print("\n");
end printDebug;

function printDebugNode
  input Node inNode;
  input String inIndent;
algorithm
  _ := match inNode
    case NODE()
      algorithm
        print("\n" + inIndent + "[");
        for i in 1:arrayLength(inNode.children) loop
          printDebugNode(arrayGet(inNode.children, i), inIndent + "  ");
        end for;
        print("],");
      then
        ();

    case VALUE()
      algorithm
        print(anyString(inNode.value) + ", ");
      then
        ();

    case EMPTY()
      algorithm
        print("E, ");
      then
        ();

  end match;
end printDebugNode;

protected

function nodeSet
  "Helper function to set."
  input Node inNode;
  input Integer inIndex;
  input Node inValue;
  input Integer inLevel;
  output Node outNode;
protected
  array<Node> children;
  Integer idx;
algorithm
  NODE(children = children) := inNode;
  children := arrayCopy(children);

  if inLevel == 0 then
    // If we reached a leaf, replace its value with the new value.
    arrayUpdate(children, intBitAnd(inIndex - 1, 31) + 1, inValue);
  else
    // Otherwise, continue to traverse the tree until we find the correct leaf.
    idx := intBitAnd(intBitRShift(inIndex - 1, inLevel), 31) + 1;
    arrayUpdate(children, idx, nodeSet(children[idx], inIndex, inValue, inLevel - 5));
  end if;

  outNode := NODE(children);
end nodeSet;

function tailAdd
  "Helper function to add. Adds a node to the end of the tail."
  input array<Node> inTail;
  input Node inNode;
  output array<Node> outTail;
protected
  Integer new_len = arrayLength(inTail) + 1;
algorithm
  outTail := MetaModelica.Dangerous.arrayCreateNoInit(new_len, EMPTY());

  for i in 1:new_len-1 loop
    arrayUpdate(outTail, i, inTail[i]);
  end for;

  outTail[new_len] := inNode;
end tailAdd;

function pushTail
  "Helper function to add. Pushed a tail into the tree as a new node."
  input Node inRoot;
  input array<Node> inTail;
  input Integer inSize;
  input Integer inShift;
  output Node outRoot;
  output Integer outShift;
protected
  Node tail_node = NODE(inTail);
  array<Node> nodes;
algorithm
  // Do we have any space left in the tree?
  if intBitRShift(inSize, 5) > intBitLShift(1, inShift) then
    // No space left, add another level to the tree by creating a new root node
    // with the old root and the pushed tail node as the first and second child.
    nodes := arrayCreate(32, EMPTY());
    arrayUpdate(nodes, 1, inRoot);
    arrayUpdate(nodes, 2, newPath(tail_node, inShift));
    outRoot := NODE(nodes);
    outShift := inShift + 5;
  else
    // Space left in the tree, just push the tail node down to the correct place.
    outRoot := pushTail2(inRoot, inShift, inSize, tail_node);
    outShift := inShift;
  end if;
end pushTail;

function pushTail2
  "Helper function to pushTail. Does the actual pushing."
  input Node inNode;
  input Integer inLevel;
  input Integer inSize;
  input Node inTail;
  output Node outNode;
algorithm
  outNode := match inNode
    local
      Integer idx;
      array<Node> children;
      Node node;

    // A node, push the tail into it.
    case NODE()
      algorithm
        children := arrayCopy(inNode.children);
        idx := intBitAnd(intBitRShift(inSize - 1, inLevel), 31) + 1;

        node := if inLevel == 5 then
          inTail else pushTail2(children[idx], inLevel - 5, inSize, inTail);

        arrayUpdate(children, idx, node);
      then
        NODE(children);

    // An empty leaf, make a new path for the tail node.
    case EMPTY()
      then newPath(inTail, inLevel);

  end match;
end pushTail2;

function tailPop
  "Returns a new tail array with the last element removed."
  input array<Node> inTail;
  output array<Node> outTail;
protected
  Integer new_len = arrayLength(inTail) - 1;
algorithm
  outTail := MetaModelica.Dangerous.arrayCreateNoInit(new_len, EMPTY());

  for i in 1:new_len loop
    arrayUpdate(outTail, i, inTail[i]);
  end for;
end tailPop;

function popTail
  "Removes the last tail added to the given node."
  input Node inNode;
  input Integer inLevel;
  input Integer inSize;
  output Node outNode;
protected
  Integer idx;
  array<Node> children;
  Node child;
algorithm
  idx := intBitAnd(intBitRShift(inSize - 2, inLevel), 31) + 1;

  outNode := match inNode
    // More than one level in the tree, update nodes recursively.
    case NODE(children = children) guard(inLevel > 5)
      algorithm
        outNode := popTail(children[idx], inLevel - 5, inSize);

        if not (isEmptyNode(outNode) and idx == 1) then
          children := arrayCopy(children);
          arrayUpdate(children, idx, outNode);
          outNode := NODE(children);
        end if;
      then
        outNode;

    // Popping the last node, return empty node.
    case _ guard(idx == 1) then EMPTY();

    // Any other case, just replace the node with an empty node.
    case NODE(children = children)
      algorithm
        children := arrayCopy(children);
        arrayUpdate(children, idx, EMPTY());
      then
        NODE(children);

  end match;
end popTail;

function nodeParent
  "Returns the parent to the node with the given index."
  input Vector inVector;
  input Integer inIndex;
  output Node outNode;
protected
  Node node;
  array<Node> children;
  Integer shift;
algorithm
  VECTOR(root = outNode, shift = shift) := inVector;

  for level in shift:-5:1 loop
    NODE(children = children) := outNode;
    outNode := children[intBitAnd(intBitRShift(inIndex - 1, level), 31) + 1];
  end for;
end nodeParent;

function tailOffset
  "Returns the tail offset, i.e. the number of elements in the vector - the
   number of elements in the tail."
  input Integer inSize;
  output Integer outOffset =
    if inSize < 32 then 0 else intBitLShift(intBitRShift(inSize - 1, 5), 5);
end tailOffset;

function liftNode
  "Creates a new node and sets the given node as the first child in the new node."
  input Node inNode;
  output Node outNode;
protected
  array<Node> nodes;
algorithm
  nodes := arrayCreate(32, EMPTY());
  arrayUpdate(nodes, 1, inNode);
  outNode := NODE(nodes);
end liftNode;

function newPath
  "Creates a new path of a given length with the given node as leaf."
  input Node inNode;
  input Integer inLevel;
  output Node outNode;
algorithm
  outNode := if inLevel > 0 then liftNode(newPath(inNode, inLevel - 5)) else inNode;
end newPath;

function isEmptyNode
  "Returns true if the given node is empty, otherwise false."
  input Node inNode;
  output Boolean outIsEmpty;
algorithm
  outIsEmpty := match inNode
    case EMPTY() then true;
    else false;
  end match;
end isEmptyNode;

function mapNode
  "Helper function to map, maps over a single node."
  input Node inNode;
  input MapFunc inFunc;
  output Node outNode;

  partial function MapFunc
    input T inValue;
    output T outValue;
  end MapFunc;
algorithm
  outNode := match inNode
    case NODE() then NODE(mapNodeArray(inNode.children, inFunc));
    case VALUE() then VALUE(inFunc(inNode.value));
    else inNode;
  end match;
end mapNode;

function mapNodeArray
  "Helper function to map, maps over an array of nodes."
  input array<Node> inNodes;
  input MapFunc inFunc;
  output array<Node> outNodes;

  partial function MapFunc
    input T inValue;
    output T outValue;
  end MapFunc;
algorithm
  outNodes := arrayCopy(inNodes);

  for i in 1:arrayLength(outNodes) loop
    MetaModelica.Dangerous.arrayUpdateNoBoundsChecking(outNodes, i,
      mapNode(MetaModelica.Dangerous.arrayGetNoBoundsChecking(outNodes, i), inFunc));
  end for;
end mapNodeArray;

function foldNode<FT>
  "Helper function to fold, folds over a single node."
  input Node inNode;
  input FoldFunc inFunc;
  input FT inStartValue;
  output FT outResult;

  partial function FoldFunc
    input T inValue;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  outResult := match inNode
    case NODE() then foldNodeArray(inNode.children, inFunc, inStartValue);
    case VALUE() then inFunc(inNode.value, inStartValue);
    else inStartValue;
  end match;
end foldNode;

function foldNodeArray<FT>
  "Helper function to fold, folds over an array of nodes."
  input array<Node> inNodes;
  input FoldFunc inFunc;
  input FT inStartValue;
  output FT outResult = inStartValue;

  partial function FoldFunc
    input T inValue;
    input FT inFoldArg;
    output FT outFoldArg;
  end FoldFunc;
algorithm
  for node in inNodes loop
    outResult := foldNode(node, inFunc, outResult);
  end for;
end foldNodeArray;

annotation(__OpenModelica_Interface="util", __OpenModelica_isBaseClass=true);
end BasePVector;

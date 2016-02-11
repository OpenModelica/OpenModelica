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

encapsulated package ConnectionGraph
" file:        ConnectionGraph.mo
  package:     ConnectionGraph
  description: Constant propagation of expressions


  This module contains a connection breaking algorithm and
  related data structures. The input of the algorithm is
  collected to ConnectionGraph record during instantiation.
  The entry point to the algorithm is findResultGraph.

  The algorithm is implemented using a disjoint-set
  data structure that represents the components of
  elements so far connected.
  Each component has an unique canonical element.
  The data structure is implemented by a hash table, that
  contains an entry for each non-canonical element so that
  a path beginning from some element eventually ends to the
  canonical element of the same component.

  Roots are represented as connections to dummy root
  element. In this way, all elements will be in the
  same component after the algorithm finishes assuming
  that the model is valid.

  TODO! FIXME! adrpo 2014-10-05
  - non standard operators: Connections.uniqueRoot and Connections.uniqueRootIndices are only partially implemented
  - Connections.uniqueRoot currently does nothing, only collects information
  - Connections.uniqueRootIndices needs to be implemented, it returns an array of ones (1) of size of first input
  - See specification for these here (Modelica_StateGraph2):
    https://github.com/modelica/Modelica_StateGraph2 and
    https://trac.modelica.org/Modelica/ticket/984 and
    http://www.ep.liu.se/ecp/043/041/ecp09430108.pdf
  - any takers for the actual implementation? :)

"

public import Absyn;
public import DAE;
public import DAEUtil;
public import HashTable;
public import HashTable3;
public import HashTableCG;
public import Connect;


public type Edge  = tuple<DAE.ComponentRef,DAE.ComponentRef> "an edge is a tuple with two component references";
public type Edges = list<Edge> "A list of edges";

public type DaeEdge  = tuple<DAE.ComponentRef,DAE.ComponentRef,list<DAE.Element>>
"a tuple with two crefs and dae elements for equatityConstraint function call";
public type DaeEdges = list<DaeEdge>
"A list of edges, each edge associated with two lists of DAE elements
 (these elements represent equations to be added if the edge
 is broken)";

public type DefiniteRoot  = DAE.ComponentRef "root defined with Connection.root";
public type DefiniteRoots = list<DAE.ComponentRef> "roots defined with Connection.root";
public type UniqueRoots = list<tuple<DAE.ComponentRef,DAE.Exp>> "roots defined with Connection.uniqueRoot";

public type PotentialRoot = tuple<DAE.ComponentRef,Real> "potential root defined with Connections.potentialRoot";
public type PotentialRoots = list<tuple<DAE.ComponentRef,Real>> "potential roots defined with Connections.potentialRoot";

public
uniontype ConnectionGraph "Input structure for connection breaking algorithm. It is collected during instantiation phase."
  record GRAPH
    Boolean updateGraph;
    DefiniteRoots definiteRoots "Roots defined with Connection.root";
    PotentialRoots potentialRoots "Roots defined with Connection.potentialRoot";
    UniqueRoots uniqueRoots "Roots defined with Connection.uniqueRoot";
    Edges branches "Edges defined with Connection.branch";
    DaeEdges connections "Edges defined with connect statement";
  end GRAPH;
end ConnectionGraph;

public constant ConnectionGraph EMPTY = GRAPH( true, {}, {}, {}, {}, {} ) "Initial connection graph with no edges in it.";

public constant ConnectionGraph NOUPDATE_EMPTY = GRAPH( false, {}, {}, {}, {}, {} ) "Initial connection graph with updateGraph set to false.";

public function handleOverconstrainedConnections
"author: adrpo
 this function gets the connection graph and the existing DAE and:
 - returns a list of broken connects and one list of connected connects
 - evaluates Connections.isRoot in the input DAE
 - evaluates Connections.uniqueRootIndices in the input DAE
 - evaluates the rooted operator in the input DAE"
  input ConnectionGraph inGraph;
  input String modelNameQualified;
  input DAE.DAElist inDAE;
  output DAE.DAElist outDAE;
  output DaeEdges outConnected;
  output DaeEdges outBroken;
algorithm
  (outDAE, outConnected, outBroken) := matchcontinue(inGraph, modelNameQualified, inDAE)
    local
      ConnectionGraph graph;
      list<DAE.Element> elts;
      list<DAE.ComponentRef> roots;
      DaeEdges broken, connected;

    // empty graph gives you the same dae
    case (GRAPH(_, {}, {}, {}, {}, {}), _, _) then (inDAE, {}, {});

    // handle the connection braking
    case (graph, _, DAE.DAE(elts))
      equation

        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("Summary: \n\t" +
           "Nr Roots:           " + intString(listLength(getDefiniteRoots(graph))) + "\n\t" +
           "Nr Potential Roots: " + intString(listLength(getPotentialRoots(graph))) + "\n\t" +
           "Nr Unique Roots:    " + intString(listLength(getUniqueRoots(graph))) + "\n\t" +
           "Nr Branches:        " + intString(listLength(getBranches(graph))) + "\n\t" +
           "Nr Connections:     " + intString(listLength(getConnections(graph))));
        end if;

        (roots, connected, broken) = findResultGraph(graph, modelNameQualified);

        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("Roots: " + stringDelimitList(List.map(roots, ComponentReference.printComponentRefStr), ", "));
          Debug.traceln("Broken connections: " + stringDelimitList(List.map1(broken, printConnectionStr, "broken"), ", "));
          Debug.traceln("Allowed connections: " + stringDelimitList(List.map1(connected, printConnectionStr, "allowed"), ", "));
        end if;

        elts = evalConnectionsOperators(roots, graph, elts);
      then
        (DAE.DAE(elts), connected, broken);

    // handle the connection breaking
    else
      equation
        true = Flags.isSet(Flags.CGRAPH);
        Debug.traceln("- ConnectionGraph.handleOverconstrainedConnections failed for model: " + modelNameQualified);
      then
        fail();
  end matchcontinue;
end handleOverconstrainedConnections;

public function addDefiniteRoot
"Adds a new definite root to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.ComponentRef inRoot;
  output ConnectionGraph outGraph;
algorithm
  outGraph := match(inGraph, inRoot)
    local
      Boolean updateGraph;
      DAE.ComponentRef root;
      DefiniteRoots definiteRoots;
      PotentialRoots potentialRoots;
      UniqueRoots uniqueRoots;
      Edges branches;
      DaeEdges connections;

    case (GRAPH(updateGraph = updateGraph,definiteRoots = definiteRoots,potentialRoots = potentialRoots,uniqueRoots = uniqueRoots,branches = branches,connections = connections), root)
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.addDefiniteRoot(" + ComponentReference.printComponentRefStr(root) + ")");
        end if;
      then
        GRAPH(updateGraph,root::definiteRoots,potentialRoots,uniqueRoots,branches,connections);
  end match;
end addDefiniteRoot;

public function addPotentialRoot
"Adds a new potential root to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.ComponentRef inRoot;
  input Real inPriority;
  output ConnectionGraph outGraph;
algorithm
  outGraph := match(inGraph, inRoot, inPriority)
    local
      Boolean updateGraph;
      DAE.ComponentRef root;
      Real priority;
      DefiniteRoots definiteRoots;
      PotentialRoots potentialRoots;
      UniqueRoots uniqueRoots;
      Edges branches;
      DaeEdges connections;

    case (GRAPH(updateGraph = updateGraph,definiteRoots = definiteRoots,potentialRoots = potentialRoots,uniqueRoots = uniqueRoots,branches = branches,connections = connections), root, priority)
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.addPotentialRoot(" + ComponentReference.printComponentRefStr(root) + ", " + realString(priority) + ")");
        end if;
      then
        GRAPH(updateGraph,definiteRoots,(root,priority)::potentialRoots,uniqueRoots,branches,connections);
  end match;
end addPotentialRoot;

public function addUniqueRoots
"Adds a new definite root to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.Exp inRoots;
  input DAE.Exp inMessage;
  output ConnectionGraph outGraph;
algorithm
  outGraph := match(inGraph, inRoots, inMessage)
    local
      Boolean updateGraph;
      DAE.ComponentRef root;
      DAE.Exp roots;
      DefiniteRoots definiteRoots;
      PotentialRoots potentialRoots;
      UniqueRoots uniqueRoots;
      Edges branches;
      DaeEdges connections;
      ConnectionGraph graph;
      DAE.Type ty;
      Boolean scalar;
      list<DAE.Exp> rest;

    // just one component reference
    case (GRAPH(updateGraph = updateGraph,definiteRoots = definiteRoots,potentialRoots = potentialRoots,uniqueRoots = uniqueRoots,
                branches = branches,connections = connections),
                DAE.CREF(root, _), _)
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.addUniqueRoots(" + ComponentReference.printComponentRefStr(root) + ", " + ExpressionDump.printExpStr(inMessage) + ")");
        end if;
      then
        GRAPH(updateGraph,definiteRoots,potentialRoots,(root,inMessage)::uniqueRoots,branches,connections);

    // array of component references, empty case
    case (GRAPH(), DAE.ARRAY(_, _, {}), _)
      then
        inGraph;

    // array of component references, something still there
    case (GRAPH(updateGraph = updateGraph,definiteRoots = definiteRoots,potentialRoots = potentialRoots,uniqueRoots = uniqueRoots,
                branches = branches,connections = connections),
                DAE.ARRAY(ty, scalar, DAE.CREF(root, _)::rest), _)
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.addUniqueRoots(" + ComponentReference.printComponentRefStr(root) + ", " + ExpressionDump.printExpStr(inMessage) + ")");
        end if;
        graph = GRAPH(updateGraph,definiteRoots,potentialRoots,(root,inMessage)::uniqueRoots,branches,connections);
        graph = addUniqueRoots(graph, DAE.ARRAY(ty, scalar, rest), inMessage);
      then
        graph;

    case (_, _, _)
      equation
        // TODO! FIXME! print some meaningful error message here that the input is not an array of roots or a cref
      then
        inGraph;

  end match;
end addUniqueRoots;

public function addBranch
"Adds a new branch to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  output ConnectionGraph outGraph;
algorithm
  outGraph := match(inGraph, inRef1, inRef2)
    local
      Boolean updateGraph;
      DAE.ComponentRef ref1;
      DAE.ComponentRef ref2;
      DefiniteRoots definiteRoots;
      PotentialRoots potentialRoots;
      UniqueRoots uniqueRoots;
      Edges branches;
      DaeEdges connections;

    case (GRAPH(updateGraph = updateGraph, definiteRoots = definiteRoots,potentialRoots = potentialRoots,uniqueRoots = uniqueRoots,branches = branches,connections = connections), ref1, ref2)
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.addBranch(" + ComponentReference.printComponentRefStr(ref1) + ", " + ComponentReference.printComponentRefStr(ref2) + ")");
        end if;
      then
        GRAPH(updateGraph, definiteRoots,potentialRoots,uniqueRoots,(ref1,ref2)::branches,connections);
  end match;
end addBranch;

public function addConnection
"Adds a new connection to ConnectionGraph"
  input ConnectionGraph inGraph;
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  input list<DAE.Element> inDae;
  output ConnectionGraph outGraph;
algorithm
  outGraph := match(inGraph, inRef1, inRef2,inDae)
    local
      Boolean updateGraph;
      DAE.ComponentRef ref1;
      DAE.ComponentRef ref2;
      list<DAE.Element> dae;
      DefiniteRoots definiteRoots;
      PotentialRoots potentialRoots;
      UniqueRoots uniqueRoots;
      Edges branches;
      DaeEdges connections;

    case (GRAPH(updateGraph = updateGraph, definiteRoots = definiteRoots, potentialRoots = potentialRoots, uniqueRoots = uniqueRoots, branches = branches, connections = connections), ref1, ref2, dae)
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.trace("- ConnectionGraph.addConnection(" + ComponentReference.printComponentRefStr(ref1) + ", " + ComponentReference.printComponentRefStr(ref2) + ")\n");
        end if;
      then GRAPH(updateGraph, definiteRoots,potentialRoots,uniqueRoots,branches,(ref1,ref2,dae)::connections);
  end match;
end addConnection;

// ************************************* //
// ********* protected section ********* //
// ************************************* //

protected import BaseHashTable;
protected import ComponentReference;
protected import ConnectUtil;
protected import Debug;
protected import ExpressionDump;
protected import Flags;
protected import List;
protected import Util;
protected import System;
protected import IOStream;
protected import Settings;

protected function canonical
"Returns the canonical element of the component where input element belongs to.
 See explanation at the top of file."
  input HashTableCG.HashTable inPartition;
  input DAE.ComponentRef inRef;
//output HashTableCG.HashTable outPartition;
  output DAE.ComponentRef outCanonical;
algorithm
  (/*outPartition,*/outCanonical) := matchcontinue(inPartition, inRef)
    local
      HashTableCG.HashTable partition;
      DAE.ComponentRef ref, parent, parentCanonical;

    case (partition, ref)
      equation
        parent = BaseHashTable.get(ref, partition);
        parentCanonical = canonical(partition, parent);
        //fprintln(Flags.CGRAPH,
        //  "- ConnectionGraph.canonical_case1(" + ComponentReference.printComponentRefStr(ref) + ") = " +
        //  ComponentReference.printComponentRefStr(parentCanonical));
        //partition2 = BaseHashTable.add((ref, parentCanonical), partition);
      then parentCanonical;

    case (_,ref)
      equation
        //fprintln(Flags.CGRAPH,
        //  "- ConnectionGraph.canonical_case2(" + ComponentReference.printComponentRefStr(ref) + ") = " +
        //  ComponentReference.printComponentRefStr(ref));
      then ref;
  end matchcontinue;
end canonical;

protected function areInSameComponent
"Tells whether the elements belong to the same component.
 See explanation at the top of file."
  input HashTableCG.HashTable inPartition;
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  output Boolean outResult;
algorithm
  // canonical(inPartition,inRef1) = canonical(inPartition,inRef2);
  outResult := matchcontinue(inPartition,inRef1,inRef2)
    local
      HashTableCG.HashTable partition;
      DAE.ComponentRef ref1, ref2, canon1,canon2;

    case(partition,ref1,ref2)
      equation
        canon1 = canonical(partition,ref1);
        canon2 = canonical(partition,ref2);
        true = ComponentReference.crefEqualNoStringCompare(canon1, canon2);
      then true;
    else false;
  end matchcontinue;
end areInSameComponent;


protected function connectBranchComponents
"Tries to connect two components whose elements are given. Depending
 on wheter the connection success or not (i.e are the components already
 connected), adds either inConnectionDae or inBreakDae to the list of
 DAE elements."
  input HashTableCG.HashTable inPartition;
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  output HashTableCG.HashTable outPartition;
algorithm
  outPartition := matchcontinue(inPartition,inRef1,inRef2)
    local
      HashTableCG.HashTable partition;
      DAE.ComponentRef ref1, ref2, canon1, canon2;

    // can connect them
    case(partition,ref1,ref2)
      equation
        canon1 = canonical(partition,ref1);
        canon2 = canonical(partition,ref2);
        (partition, true) = connectCanonicalComponents(partition,canon1,canon2);
      then partition;

    // cannot connect them
    case(partition,_,_)
      equation
      then partition;
  end matchcontinue;
end connectBranchComponents;

protected function connectComponents
"Tries to connect two components whose elements are given. Depending
 on wheter the connection success or not (i.e are the components already
 connected), adds either inConnectionDae or inBreakDae to the list of
 DAE elements."
  input HashTableCG.HashTable inPartition;
  input DaeEdge inDaeEdge;
  output HashTableCG.HashTable outPartition;
  output DaeEdges outConnectedConnections;
  output DaeEdges outBrokenConnections;
algorithm
  (outPartition,outConnectedConnections,outBrokenConnections) := matchcontinue(inPartition,inDaeEdge)
    local
      HashTableCG.HashTable partition;
      DAE.ComponentRef ref1, ref2, canon1, canon2;

    // leave the connect(ref1,ref2)
    case(partition,(ref1,_,_))
      equation
        failure(_ = canonical(partition,ref1)); // no parent
      then (partition, {inDaeEdge}, {});

    // leave the connect(ref1,ref2)
    case(partition,(_,ref2,_))
      equation
        failure(_ = canonical(partition,ref2)); // no parent
      then (partition, {inDaeEdge}, {});

    // leave the connect(ref1,ref2)
    case(partition,(ref1,ref2,_))
      equation
        canon1 = canonical(partition,ref1);
        canon2 = canonical(partition,ref2);
        (partition, true) = connectCanonicalComponents(partition,canon1,canon2);
      then (partition, {inDaeEdge}, {});

    // break the connect(ref1, ref2)
    case(partition,(ref1,ref2,_))
      equation
        // debug print
        if Flags.isSet(Flags.CGRAPH) then
          Debug.trace("- ConnectionGraph.connectComponents: should remove equations generated from: connect(" +
             ComponentReference.printComponentRefStr(ref1) + ", " +
             ComponentReference.printComponentRefStr(ref2) + ") and add {0, ..., 0} = equalityConstraint(cr1, cr2) instead.\n");
        end if;
      then (partition, {}, {inDaeEdge});
  end matchcontinue;
end connectComponents;

protected function connectCanonicalComponents
"Tries to connect two components whose canonical elements are given.
 Helper function for connectionComponents."
  input HashTableCG.HashTable inPartition;
  input DAE.ComponentRef inRef1;
  input DAE.ComponentRef inRef2;
  output HashTableCG.HashTable outPartition;
  output Boolean outReallyConnected;
algorithm
  (outPartition,outReallyConnected) :=  matchcontinue(inPartition,inRef1,inRef2)
    local
      HashTableCG.HashTable partition;
      DAE.ComponentRef ref1, ref2;

    // they are the same
    case(partition,ref1,ref2)
      equation
        true = ComponentReference.crefEqualNoStringCompare(ref1, ref2);
      then (partition, false);

    // not the same, add it
    case(partition,ref1,ref2)
      equation
        partition = BaseHashTable.add((ref1,ref2), partition);
      then (partition, true);
  end matchcontinue;
end connectCanonicalComponents;

protected function addRootsToTable
"Adds a root the the graph. This is implemented by connecting the root to inFirstRoot element."
  input HashTableCG.HashTable inTable;
  input list<DAE.ComponentRef> inRoots;
  input DAE.ComponentRef inFirstRoot;
  output HashTableCG.HashTable outTable;
algorithm
  outTable := match(inTable, inRoots, inFirstRoot)
    local
      HashTableCG.HashTable table;
      DAE.ComponentRef root, firstRoot;
      list<DAE.ComponentRef> tail;

    case(table, (root::tail), firstRoot)
      equation
        table = BaseHashTable.add((root,firstRoot), table);
        table = addRootsToTable(table, tail, firstRoot);
      then table;
    case(table, {}, _) then table;
  end match;
end addRootsToTable;

protected function resultGraphWithRoots
"Creates an initial graph with given definite roots."
  input list<DAE.ComponentRef> roots;
  output HashTableCG.HashTable outTable;
protected
  HashTableCG.HashTable table0;
  DAE.ComponentRef dummyRoot;
algorithm
  dummyRoot := ComponentReference.makeCrefIdent("__DUMMY_ROOT", DAE.T_INTEGER_DEFAULT, {});
  table0 := HashTableCG.emptyHashTable();
  outTable := addRootsToTable(table0, roots, dummyRoot);
end resultGraphWithRoots;

protected function addBranchesToTable
"Adds all branches to the graph."
  input HashTableCG.HashTable inTable;
  input Edges inBranches;
  output HashTableCG.HashTable outTable;
algorithm
  outTable := match(inTable, inBranches)
    local
      HashTableCG.HashTable table, table1, table2;
      DAE.ComponentRef ref1, ref2;
      Edges tail;

    case(table, ((ref1,ref2)::tail))
      equation
        table1 = connectBranchComponents(table, ref1, ref2);
        table2 = addBranchesToTable(table1, tail);
      then table2;
    case(table, {}) then table;
  end match;
end addBranchesToTable;

protected function ord
"An ordering function for potential roots."
  input PotentialRoot inEl1;
  input PotentialRoot inEl2;
  output Boolean outBoolean;
algorithm
  outBoolean := matchcontinue(inEl1, inEl2)
    local
      Real r1, r2;
      DAE.ComponentRef c1, c2;
      String s1, s2;

    case((c1,r1), (c2,r2)) // if equal order by cref
      equation
        true = realEq(r1, r2);
        s1 = ComponentReference.printComponentRefStr(c1);
        s2 = ComponentReference.printComponentRefStr(c2);
        1 = stringCompare(s1, s2);
      then
        true;

    case((_,r1), (_,r2))
      then r1 > r2;
  end matchcontinue;
end ord;

protected function addPotentialRootsToTable
"Adds all potential roots to graph."
  input HashTableCG.HashTable inTable;
  input PotentialRoots inPotentialRoots;
  input DefiniteRoots inRoots;
  input DAE.ComponentRef inFirstRoot;
  output HashTableCG.HashTable outTable;
  output DefiniteRoots outRoots;
algorithm
  (outTable,outRoots) := matchcontinue(inTable, inPotentialRoots, inRoots, inFirstRoot)
    local
      HashTableCG.HashTable table;
      DAE.ComponentRef potentialRoot, firstRoot, canon1, canon2;
      DefiniteRoots roots, finalRoots;
      PotentialRoots tail;

    case(table, {}, roots, _) then (table,roots);
    case(table, ((potentialRoot,_)::tail), roots, firstRoot)
      equation
        canon1 = canonical(table, potentialRoot);
        canon2 = canonical(table, firstRoot);
        (table, true) = connectCanonicalComponents(table, canon1, canon2);
        (table, finalRoots) = addPotentialRootsToTable(table, tail, potentialRoot::roots, firstRoot);
      then (table, finalRoots);
    case(table, (_::tail), roots, firstRoot)
      equation
        (table, finalRoots) = addPotentialRootsToTable(table, tail, roots, firstRoot);
      then (table, finalRoots);
  end matchcontinue;
end addPotentialRootsToTable;

protected function addConnections
"Adds all connections to graph."
  input HashTableCG.HashTable inTable;
  input DaeEdges inConnections;
  output HashTableCG.HashTable outTable;
  output DaeEdges outConnectedConnections;
  output DaeEdges outBrokenConnections;
algorithm
  (outTable, outConnectedConnections, outBrokenConnections) := match(inTable, inConnections)
    local
      HashTableCG.HashTable table;
      DaeEdges tail;
      DaeEdges broken1,broken2,broken,connected1,connected2,connected;
      DaeEdge e;

    // empty case
    case(table, {}) then (table, {}, {});
    // normal case
    case(table, e::tail)
      equation
        (table, connected1, broken1) = connectComponents(table, e);
        (table, connected2, broken2) = addConnections(table, tail);
        connected = listAppend(connected1, connected2);
        broken = listAppend(broken1, broken2);
      then (table, connected, broken);
  end match;
end addConnections;

protected function findResultGraph
"Given ConnectionGraph structure, breaks all connections,
 determines roots and generates a list of dae elements."
  input  ConnectionGraph inGraph;
  input  String modelNameQualified;
  output DefiniteRoots outRoots;
  output DaeEdges outConnectedConnections;
  output DaeEdges outBrokenConnections;
algorithm
  (outRoots, outConnectedConnections, outBrokenConnections) := matchcontinue(inGraph, modelNameQualified)
    local
      DefiniteRoots definiteRoots, finalRoots;
      PotentialRoots potentialRoots, orderedPotentialRoots;
      UniqueRoots uniqueRoots;
      Edges branches;
      DaeEdges connections, broken, connected;
      HashTableCG.HashTable table;
      DAE.ComponentRef dummyRoot;
      String brokenConnectsViaGraphViz;
      list<String> userBrokenLst;
      list<list<String>> userBrokenLstLst;
      list<tuple<String,String>> userBrokenTplLst;

    // deal with empty connection graph
    case (GRAPH(_, definiteRoots = {}, potentialRoots = {}, uniqueRoots = {}, branches = {}, connections = {}), _)
      then ({}, {}, {});

    // we have something in the connection graph
    case (GRAPH(_, definiteRoots = definiteRoots, potentialRoots = potentialRoots, uniqueRoots = uniqueRoots,
                   branches = branches, connections = connections), _)
      equation
        // reverse the conenction list to have them as in the model
        connections = listReverse(connections);
        // add definite roots to the table
        table = resultGraphWithRoots(definiteRoots);
        // add branches to the table
        table = addBranchesToTable(table, branches);
        // order potential roots in the order or priority
        orderedPotentialRoots = List.sort(potentialRoots, ord);

        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("Ordered Potential Roots: " + stringDelimitList(List.map(orderedPotentialRoots, printPotentialRootTuple), ", "));
        end if;

        // add connections to the table and return the broken/connected connections
        (table, connected, broken) = addConnections(table, connections);

        // create a dummy root
        dummyRoot = ComponentReference.makeCrefIdent("__DUMMY_ROOT", DAE.T_INTEGER_DEFAULT, {});
        // select final roots
        (table, finalRoots) = addPotentialRootsToTable(table, orderedPotentialRoots, definiteRoots, dummyRoot);

        // generate the graphviz representation and display
        brokenConnectsViaGraphViz = generateGraphViz(modelNameQualified, definiteRoots, potentialRoots, uniqueRoots, branches, connections, finalRoots, broken);

        if stringEq(brokenConnectsViaGraphViz, "")
        then
          // if brokenConnectsViaGraphViz is empty, the user wants to use the current breaking!
        else
          // interpret brokenConnectsViaGraphViz and pass it to the breaking algorithm again
          // graphviz returns the broken connects as: cr1|cr2#cr3|cr4#
          userBrokenLst = Util.stringSplitAtChar(brokenConnectsViaGraphViz, "#");
          userBrokenLstLst = List.map1(userBrokenLst, Util.stringSplitAtChar, "|");
          userBrokenTplLst = makeTuple(userBrokenLstLst);
          Debug.traceln("User selected the following connect edges for breaking:\n\t" + stringDelimitList(List.map(userBrokenTplLst, printTupleStr), "\n\t"));
          // print("\nBefore ordering:\n");
          printDaeEdges(connections);
          // order the connects with the input given by the user!
          connections = orderConnectsGuidedByUser(connections, userBrokenTplLst);
          // reverse the reverse! uh oh!
          connections = listReverse(connections);
          print("\nAfer ordering:\n");
          // printDaeEdges(connections);
          // call findResultGraph again with ordered connects!
          (finalRoots, connected, broken) =
             findResultGraph(GRAPH(false, definiteRoots, potentialRoots, uniqueRoots, branches, connections), modelNameQualified);
        end if;

      then
        (finalRoots, connected, broken);

  end matchcontinue;
end findResultGraph;

protected function orderConnectsGuidedByUser
  input DaeEdges inConnections;
  input list<tuple<String,String>> inUserSelectedBreaking;
  output DaeEdges outOrderedConnections;
algorithm
  outOrderedConnections := match(inConnections, inUserSelectedBreaking)
    local
      String sc1,sc2;
      DAE.ComponentRef c1, c2;
      DaeEdge e;
      list<DAE.Element> els;
      DaeEdges rest, ordered;
      Boolean  b1, b2;

    // handle empty case
    case ({}, _) then {};

    // handle match and miss
    case ((e as (c1, c2, _))::rest, _)
      equation
        sc1 = ComponentReference.printComponentRefStr(c1);
        sc2 = ComponentReference.printComponentRefStr(c2);
        ordered = orderConnectsGuidedByUser(rest, inUserSelectedBreaking);
        // see both ways!
        b1 = listMember((sc1, sc2), inUserSelectedBreaking);
        b2 = listMember((sc2, sc1), inUserSelectedBreaking);
        if (boolOr(b1, b2))
        then
          // put them at the end to be tried last (more chance to be broken)
          ordered = listAppend(ordered, {e});
        else
          // put them at the front to be tried first (less chance to be broken)
          ordered = e::ordered;
        end if;
      then
        ordered;

  end match;
end orderConnectsGuidedByUser;

protected function printTupleStr
  input tuple<String,String> inTpl;
  output String out;
algorithm
  out := match(inTpl)
    local
      String c1,c2;
    case ((c1,c2)) then c1 + " -- " + c2;
  end match;
end printTupleStr;

protected function makeTuple
  input list<list<String>> inLstLst;
  output list<tuple<String,String>> outLst;
algorithm
  outLst := matchcontinue(inLstLst)
    local
      String c1,c2;
      list<list<String>> rest;
      list<tuple<String,String>> lst;
      list<String> bad;

    // empty case
    case ({}) then {};
    // somthing case
    case ({c1,c2}::rest)
      equation
        lst = makeTuple(rest);
      then
        (c1,c2)::lst;
    // ignore empty strings
    case ({""}::rest)
      equation
        lst = makeTuple(rest);
      then
        lst;
    // ignore empty list
    case ({}::rest)
      equation
        lst = makeTuple(rest);
      then
        lst;
    // somthing case
    case (bad::rest)
      equation
        Debug.traceln("The following output from GraphViz OpenModelica assistant cannot be parsed:" +
            stringDelimitList(bad, ", ") +
            "\nExpected format from GrapViz: cref1|cref2#cref3|cref4#. Ignoring malformed input.");
        lst = makeTuple(rest);
      then
        lst;
  end matchcontinue;
end makeTuple;

protected function printPotentialRootTuple
  input PotentialRoot potentialRoot;
  output String outStr;
algorithm
  outStr := match(potentialRoot)
    local
      DAE.ComponentRef cr;
      Real priority;
      String str;
    case ((cr, priority))
      equation
        str = ComponentReference.printComponentRefStr(cr) + "(" + realString(priority) + ")";
      then str;
  end match;
end printPotentialRootTuple;

protected function setRootDistance
  input list<DAE.ComponentRef> finalRoots;
  input HashTable3.HashTable table;
  input Integer distance;
  input list<DAE.ComponentRef> nextLevel;
  input HashTable.HashTable irooted;
  output HashTable.HashTable orooted;
algorithm
  orooted := matchcontinue(finalRoots,table,distance,nextLevel,irooted)
    local
      HashTable.HashTable rooted;
      list<DAE.ComponentRef> rest,next;
      DAE.ComponentRef cr;
    case({},_,_,{},_) then irooted;
    case({},_,_,_,_)
      then
        setRootDistance(nextLevel,table,distance+1,{},irooted);
    case(cr::rest,_,_,_,_)
      equation
        failure(_ = BaseHashTable.get(cr, irooted));
        rooted = BaseHashTable.add((cr,distance),irooted);
        next = BaseHashTable.get(cr, table);
        //print("- ConnectionGraph.setRootDistance: Set Distance " +
        //   ComponentReference.printComponentRefStr(cr) + " , " + intString(distance) + "\n");
        //print("- ConnectionGraph.setRootDistance: add " +
        //   stringDelimitList(List.map(next,ComponentReference.printComponentRefStr),"\n") + " to the queue\n");
        next = listAppend(nextLevel,next);
      then
        setRootDistance(rest,table,distance,next,rooted);
    case(cr::rest,_,_,_,_)
      equation
        failure(_ = BaseHashTable.get(cr, irooted));
        rooted = BaseHashTable.add((cr,distance),irooted);
        //print("- ConnectionGraph.setRootDistance: Set Distance " +
        //   ComponentReference.printComponentRefStr(cr) + " , " + intString(distance) + "\n");
      then
        setRootDistance(rest,table,distance,nextLevel,rooted);
/*    case(cr::rest,_,_,_,_)
      equation
        i = BaseHashTable.get(cr, irooted);
        print("- ConnectionGraph.setRootDistance: found " +
           ComponentReference.printComponentRefStr(cr) + " twice, value is " + intString(i) + "\n");
      then
        setRootDistance(rest,table,distance,nextLevel,irooted);
*/
    case (_::rest,_,_,_,_)
      //equation
      //  print("- ConnectionGraph.setRootDistance: cannot found " + ComponentReference.printComponentRefStr(cr) + "\n");
      then
        setRootDistance(rest,table,distance,nextLevel,irooted);
  end matchcontinue;
end setRootDistance;

protected function addBranches
  input Edge edge;
  input HashTable3.HashTable itable;
  output HashTable3.HashTable otable;
protected
  DAE.ComponentRef cref1,cref2;
algorithm
  (cref1,cref2) := edge;
  otable := addConnectionRooted(cref1,cref2,itable);
  otable := addConnectionRooted(cref2,cref1,otable);
end addBranches;

protected function addConnectionsRooted
  input DaeEdge connection;
  input HashTable3.HashTable itable;
  output HashTable3.HashTable otable;
protected
  DAE.ComponentRef cref1,cref2;
algorithm
  (cref1,cref2,_) := connection;
  otable := addConnectionRooted(cref1,cref2,itable);
  otable := addConnectionRooted(cref2,cref1,otable);
end addConnectionsRooted;

protected function addConnectionRooted
  input DAE.ComponentRef cref1;
  input DAE.ComponentRef cref2;
  input HashTable3.HashTable itable;
  output HashTable3.HashTable otable;
algorithm
  otable := match(cref1,cref2,itable)
    local
      HashTable3.HashTable table;
      list<DAE.ComponentRef> crefs;

    case(_, _, _)
      equation
          crefs = matchcontinue()
            case () then BaseHashTable.get(cref1,itable);
            else {};
          end matchcontinue;
          table = BaseHashTable.add((cref1,cref2::crefs),itable);
      then
        table;

  end match;
end addConnectionRooted;

protected function evalConnectionsOperators
"evaluation of Connections.rooted, Connections.isRoot, Connections.uniqueRootIndices
 - replaces all [Connections.]rooted calls by true or false depending on wheter branche frame_a or frame_b is closer to root
 - return true or false for Connections.isRoot operator if is a root or not
 - return an array of indices for Connections.uniqueRootIndices, see Modelica_StateGraph2
   See Modelica_StateGraph2:
    https://github.com/modelica/Modelica_StateGraph2 and
    https://trac.modelica.org/Modelica/ticket/984 and
    http://www.ep.liu.se/ecp/043/041/ecp09430108.pdf
   for a specification of this operator"
  input list<DAE.ComponentRef> inRoots;
  input ConnectionGraph graph;
  input list<DAE.Element> inDae;
  output list<DAE.Element> outDae;
algorithm
  outDae := matchcontinue(inRoots,graph,inDae)
    local
      HashTable.HashTable rooted;
      HashTable3.HashTable table;
      Edges branches;
      DaeEdges connections;

    case (_,_, {}) then {};

    else
      equation
        // built table
        table = HashTable3.emptyHashTable();
        // add branches to table
        branches = getBranches(graph);
        table = List.fold(branches,addBranches,table);
        // add connections to table
        connections = getConnections(graph);
        table = List.fold(connections,addConnectionsRooted,table);
        // get distanste to root
        //  print("Roots: " + stringDelimitList(List.map(inRoots,ComponentReference.printComponentRefStr),"\n") + "\n");
        //  BaseHashTable.dumpHashTable(table);
        rooted = setRootDistance(inRoots,table,0,{},HashTable.emptyHashTable());
        //  BaseHashTable.dumpHashTable(rooted);
        (outDae, _) = DAEUtil.traverseDAE2(inDae, evalConnectionsOperatorsHelper, (rooted,inRoots,graph));
      then outDae;

  end matchcontinue;
end evalConnectionsOperators;

protected function evalConnectionsOperatorsHelper
"Helper function for evaluation of Connections.rooted, Connections.isRoot, Connections.uniqueRootIndices"
  input DAE.Exp inExp;
  input tuple<HashTable.HashTable,list<DAE.ComponentRef>,ConnectionGraph> inRoots;
  output DAE.Exp outExp;
  output tuple<HashTable.HashTable,list<DAE.ComponentRef>,ConnectionGraph> outRoots;
algorithm
  (outExp,outRoots) := matchcontinue (inExp,inRoots)
    local
      ConnectionGraph graph;
      DAE.Exp exp, uroots, nodes, message;
      HashTable.HashTable rooted;
      DAE.ComponentRef cref,cref1;
      Boolean result;
      Edges branches;
      list<DAE.ComponentRef> roots;
      list<DAE.Exp> lst;

    // handle rooted - with zero size array
    case (DAE.CALL(path=Absyn.IDENT("rooted"), expLst={DAE.ARRAY(array = {})}), (rooted,roots,graph))
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.evalConnectionsOperatorsHelper: " + ExpressionDump.printExpStr(inExp) + " = false");
        end if;
      then
        (DAE.BCONST(false), (rooted,roots,graph));

    // handle rooted
    case (DAE.CALL(path=Absyn.IDENT("rooted"), expLst={DAE.CREF(componentRef = cref)}), (rooted,roots,graph))
      equation
        // find partner in branches
        branches = getBranches(graph);
        cref1 = getEdge(cref,branches);
        // print("- ConnectionGraph.evalConnectionsOperatorsHelper: Found Branche Partner " +
        //   ComponentReference.printComponentRefStr(cref) + ", " + ComponentReference.printComponentRefStr(cref1) + "\n");
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.evalConnectionsOperatorsHelper: Found Branche Partner " +
           ComponentReference.printComponentRefStr(cref) + ", " + ComponentReference.printComponentRefStr(cref1));
        end if;
        result = getRooted(cref,cref1,rooted);
        //print("- ConnectionGraph.evalRootedAndIsRootHelper: " +
        //   ComponentReference.printComponentRefStr(cref) + " is " + boolString(result) + " rooted\n");
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.evalConnectionsOperatorsHelper: " + ExpressionDump.printExpStr(inExp) + " = " + boolString(result));
        end if;
      then (DAE.BCONST(result), (rooted,roots,graph));

    // no roots, same exp
    case (exp, (rooted,roots as {},graph)) then (exp, (rooted,roots,graph));

    // deal with Connections.isRoot - with zero size array
    case (DAE.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), expLst={DAE.ARRAY(array = {})}), (rooted,roots,graph))
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.evalConnectionsOperatorsHelper: " + ExpressionDump.printExpStr(inExp) + " = false");
        end if;
      then
        (DAE.BCONST(false), (rooted,roots,graph));

    // deal with NOT Connections.isRoot - with zero size array
    case (DAE.LUNARY(DAE.NOT(_), DAE.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), expLst={DAE.ARRAY(array = {})})), (rooted,roots,graph))
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.evalConnectionsOperatorsHelper: " + ExpressionDump.printExpStr(inExp) + " = false");
        end if;
      then
        (DAE.BCONST(false), (rooted,roots,graph));

    // deal with Connections.isRoot
    case (DAE.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), expLst={DAE.CREF(componentRef = cref)}), (rooted,roots,graph))
      equation
        result = List.isMemberOnTrue(cref, roots, ComponentReference.crefEqualNoStringCompare);
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.evalConnectionsOperatorsHelper: " + ExpressionDump.printExpStr(inExp) + " = " + boolString(result));
        end if;
      then (DAE.BCONST(result), (rooted,roots,graph));

    // deal with NOT Connections.isRoot
    case (DAE.LUNARY(DAE.NOT(_), DAE.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("isRoot")), expLst={DAE.CREF(componentRef = cref)})), (rooted,roots,graph))
      equation
        result = List.isMemberOnTrue(cref, roots, ComponentReference.crefEqualNoStringCompare);
        result = boolNot(result);
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.evalConnectionsOperatorsHelper: " + ExpressionDump.printExpStr(inExp) + " = " + boolString(result));
        end if;
      then (DAE.BCONST(result), (rooted,roots,graph));

    // deal with Connections.uniqueRootIndices, TODO! FIXME! actually implement this
    case (DAE.CALL(path=Absyn.QUALIFIED("Connections", Absyn.IDENT("uniqueRootIndices")),
          expLst={uroots as DAE.ARRAY(array = lst),nodes,message}), (rooted,roots,graph))
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.evalConnectionsOperatorsHelper: Connections.uniqueRootsIndicies(" +
            ExpressionDump.printExpStr(uroots) + "," +
            ExpressionDump.printExpStr(nodes) + "," +
            ExpressionDump.printExpStr(message) + ")");
        end if;
        lst = List.fill(DAE.ICONST(1), listLength(lst)); // TODO! FIXME! actually implement this correctly
      then
        (DAE.ARRAY(DAE.T_INTEGER_DEFAULT, false, lst), (rooted,roots,graph));

    // no replacement needed
    else (inExp, inRoots);
    // fprintln(Flags.CGRAPH, ExpressionDump.printExpStr(exp) + " not found in roots!");
  end matchcontinue;
end evalConnectionsOperatorsHelper;

protected function getRooted
  input DAE.ComponentRef cref1;
  input DAE.ComponentRef cref2;
  input HashTable.HashTable rooted;
  output Boolean result;
algorithm
  result := matchcontinue(cref1,cref2,rooted)
    local
      Integer i1,i2;
    case(_,_,_)
      equation
        i1 = BaseHashTable.get(cref1,rooted);
        i2 = BaseHashTable.get(cref2,rooted);
      then
        intLt(i1,i2);
    // in faile case return true
    else
      then
        true;
  end matchcontinue;
end getRooted;

protected function getEdge
"return the Edge partner of a edge, fails if not found"
  input DAE.ComponentRef cr;
  input Edges edges;
  output DAE.ComponentRef ocr;
algorithm
  ocr := matchcontinue(cr,edges)
    local
      Edges rest;
      DAE.ComponentRef cref1,cref2;
    case(_,(cref1,cref2)::_)
      equation
        cref1 = getEdge1(cr,cref1,cref2);
      then
        cref1;
    case(_,_::rest)
      then
        getEdge(cr,rest);
  end matchcontinue;
end getEdge;

protected function getEdge1
"return the Edge partner of a edge, fails if not found"
  input DAE.ComponentRef cr;
  input DAE.ComponentRef cref1;
  input DAE.ComponentRef cref2;
  output DAE.ComponentRef ocr;
algorithm
  ocr := matchcontinue(cr,cref1,cref2)
    case(_,_,_)
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cref1);
      then
        cref2;
    else
      equation
        true = ComponentReference.crefEqualNoStringCompare(cr,cref2);
      then
        cref1;
  end matchcontinue;
end getEdge1;

protected function printConnectionStr
"prints the connection str"
  input DaeEdge connectTuple;
  input String ty;
  output String outStr;
algorithm
  outStr := match(connectTuple, ty)
    local
      DAE.ComponentRef c1, c2;
      String str;

    case ((c1, c2, _), _)
      equation
        str = ty + "(" +
          ComponentReference.printComponentRefStr(c1) +
          ", " +
          ComponentReference.printComponentRefStr(c2) +
          ")";
      then str;
  end match;
end printConnectionStr;

protected function printEdges
"Prints a list of edges to stdout."
  input Edges inEdges;
algorithm
  _ := match(inEdges)
    local
      DAE.ComponentRef c1, c2;
      Edges tail;

    case ({}) then ();
    case ((c1, c2) :: tail)
      equation
        print("    ");
        print(ComponentReference.printComponentRefStr(c1));
        print(" -- ");
        print(ComponentReference.printComponentRefStr(c2));
        print("\n");
        printEdges(tail);
      then ();
  end match;
end printEdges;

protected function printDaeEdges
"Prints a list of dae edges to stdout."
  input DaeEdges inEdges;
algorithm
  _ := match(inEdges)
    local
      DAE.ComponentRef c1, c2;
      DaeEdges tail;

    case ({}) then ();

    case ((c1, c2, _) :: tail)
      equation
        print("    ");
        print(ComponentReference.printComponentRefStr(c1));
        print(" -- ");
        print(ComponentReference.printComponentRefStr(c2));
        print("\n");
        printDaeEdges(tail);
      then ();
  end match;
end printDaeEdges;

protected function printConnectionGraph
  "Prints the content of ConnectionGraph structure."
  input ConnectionGraph inGraph;
algorithm
  _ := match(inGraph)
    local
      DaeEdges connections;
      Edges branches;

    case (GRAPH(connections = connections, branches = branches))
      equation
        print("Connections:\n");
        printDaeEdges(connections);
        print("Branches:\n");
        printEdges(branches);
      then ();
  end match;
end printConnectionGraph;

protected function getDefiniteRoots
"Accessor for ConnectionGraph.definiteRoots."
  input ConnectionGraph inGraph;
  output DefiniteRoots outResult;
algorithm
  outResult := match(inGraph)
    local
      DefiniteRoots result;
    case (GRAPH(definiteRoots = result)) then result;
  end match;
end getDefiniteRoots;

protected function getUniqueRoots
"Accessor for ConnectionGraph.uniqueRoots."
  input ConnectionGraph inGraph;
  output UniqueRoots outResult;
algorithm
  outResult := match(inGraph)
    local
      UniqueRoots result;
    case (GRAPH(uniqueRoots = result)) then result;
  end match;
end getUniqueRoots;

protected function getPotentialRoots
"Accessor for ConnectionGraph.potentialRoots."
  input ConnectionGraph inGraph;
  output PotentialRoots outResult;
algorithm
  outResult := match(inGraph)
    local PotentialRoots result;
    case (GRAPH(potentialRoots = result)) then result;
  end match;
end getPotentialRoots;

protected function getBranches
"Accessor for ConnectionGraph.branches."
  input ConnectionGraph inGraph;
  output Edges outResult;
algorithm
  outResult := match(inGraph)
    local Edges result;
    case (GRAPH(branches = result)) then result;
  end match;
end getBranches;

protected function getConnections
"Accessor for ConnectionGraph.connections."
  input ConnectionGraph inGraph;
  output DaeEdges outResult;
algorithm
  outResult := match(inGraph)
    local DaeEdges result;
    case (GRAPH(connections = result)) then result;
  end match;
end getConnections;

public function merge
"merge two ConnectionGraphs"
  input ConnectionGraph inGraph1;
  input ConnectionGraph inGraph2;
  output ConnectionGraph outGraph;
algorithm
  outGraph := matchcontinue(inGraph1, inGraph2)
    local
      Boolean updateGraph, updateGraph1, updateGraph2;
      DefiniteRoots definiteRoots, definiteRoots1, definiteRoots2;
      UniqueRoots uniqueRoots, uniqueRoots1, uniqueRoots2;
      PotentialRoots potentialRoots, potentialRoots1, potentialRoots2;
      Edges branches, branches1, branches2;
      DaeEdges connections, connections1, connections2;

    // left is empty, return right
    case (_, GRAPH(definiteRoots = {},potentialRoots = {},uniqueRoots = {},branches = {},connections = {}))
      then
        inGraph1;

    // right is empty, return left
    case (GRAPH(definiteRoots = {},potentialRoots = {},uniqueRoots = {},branches = {},connections = {}), _)
      then
        inGraph2;

    // they are equal, return any
    case (_, _)
      equation
        equality(inGraph1 = inGraph2);
      then
        inGraph1;

    // they are NOT equal, merge them
    case (GRAPH(updateGraph = updateGraph1, definiteRoots = definiteRoots1, potentialRoots = potentialRoots1, uniqueRoots=uniqueRoots1,
                branches = branches1, connections = connections1),
          GRAPH(updateGraph = updateGraph2, definiteRoots = definiteRoots2, potentialRoots = potentialRoots2, uniqueRoots=uniqueRoots2,
                branches = branches2,connections = connections2))
      equation
        if Flags.isSet(Flags.CGRAPH) then
          Debug.trace("- ConnectionGraph.merge()\n");
        end if;
        updateGraph    = boolOr(updateGraph1, updateGraph2);
        definiteRoots  = List.union(definiteRoots1, definiteRoots2);
        potentialRoots = List.union(potentialRoots1, potentialRoots2);
        uniqueRoots    = List.union(uniqueRoots1, uniqueRoots2);
        branches       = List.union(branches1, branches2);
        connections    = List.union(connections1, connections2);
      then
        GRAPH(updateGraph,definiteRoots,potentialRoots,uniqueRoots,branches,connections);
  end matchcontinue;
end merge;

/***********************************************************************************************************************/
/******************************************* GraphViz generation *******************************************************/
/***********************************************************************************************************************/

protected function graphVizEdge
  input  Edge inEdge;
  output String out;
algorithm
  out := match(inEdge)
    local DAE.ComponentRef c1, c2; String strEdge;
    case ((c1, c2))
      equation
        strEdge = "\"" + ComponentReference.printComponentRefStr(c1) + "\" -- \"" + ComponentReference.printComponentRefStr(c2) + "\"" +
        " [color = blue, dir = \"none\", fontcolor=blue, label = \"branch\"];\n\t";
      then strEdge;
  end match;
end graphVizEdge;

protected function graphVizDaeEdge
  input  DaeEdge inDaeEdge;
  input  DaeEdges inBrokenDaeEdges;
  output String out;
algorithm
  out := match(inDaeEdge, inBrokenDaeEdges)
    local
      DAE.ComponentRef c1, c2;
      String sc1, sc2, strDaeEdge, label, labelFontSize, decorate, color, style, fontColor;
      Boolean isBroken;

    case ((c1, c2, _), _)
      equation
        isBroken = listMember(inDaeEdge, inBrokenDaeEdges);
        label = if isBroken then "[[broken connect]]" else "connect";
        color = if isBroken then "red" else "green";
        style = if isBroken then "\"bold, dashed\"" else "solid";
        decorate = boolString(isBroken);
        fontColor = if isBroken then "red" else "green";
        labelFontSize = if isBroken then "labelfontsize = 20.0, " else "";
        sc1 = ComponentReference.printComponentRefStr(c1);
        sc2 = ComponentReference.printComponentRefStr(c2);
        strDaeEdge = stringAppendList({
          "\"", sc1, "\" -- \"", sc2, "\" [",
          "dir = \"none\", ",
          "style = ", style,  ", ",
          "decorate = ", decorate,  ", ",
          "color = ", color ,  ", ",
          labelFontSize,
          "fontcolor = ", fontColor ,  ", ",
          "label = \"", label ,"\"",
          "];\n\t"});
      then strDaeEdge;
  end match;
end graphVizDaeEdge;

protected function graphVizDefiniteRoot
  input  DefiniteRoot  inDefiniteRoot;
  input  DefiniteRoots inFinalRoots;
  output String out;
algorithm
  out := match(inDefiniteRoot, inFinalRoots)
    local DAE.ComponentRef c; String strDefiniteRoot; Boolean isSelectedRoot;
    case (c, _)
      equation
        isSelectedRoot = listMember(c, inFinalRoots);
        strDefiniteRoot = "\"" + ComponentReference.printComponentRefStr(c) + "\"" +
           " [fillcolor = red, rank = \"source\", label = " + "\"" + ComponentReference.printComponentRefStr(c) + "\", " +
           (if isSelectedRoot then "shape=polygon, sides=8, distortion=\"0.265084\", orientation=26, skew=\"0.403659\"" else "shape=box") +
           "];\n\t";
      then strDefiniteRoot;
  end match;
end graphVizDefiniteRoot;

protected function graphVizPotentialRoot
  input  PotentialRoot inPotentialRoot;
  input  DefiniteRoots inFinalRoots;
  output String out;
algorithm
  out := match(inPotentialRoot, inFinalRoots)
    local DAE.ComponentRef c; Real priority; String strPotentialRoot; Boolean isSelectedRoot;
    case ((c, priority), _)
      equation
        isSelectedRoot = listMember(c, inFinalRoots);
        strPotentialRoot = "\"" + ComponentReference.printComponentRefStr(c) + "\"" +
           " [fillcolor = orangered, rank = \"min\" label = " + "\"" + ComponentReference.printComponentRefStr(c) + "\\n" + realString(priority) + "\", " +
           (if isSelectedRoot then "shape=ploygon, sides=7, distortion=\"0.265084\", orientation=26, skew=\"0.403659\"" else "shape=box") +
           "];\n\t";
      then strPotentialRoot;
  end match;
end graphVizPotentialRoot;

protected function generateGraphViz
"@author: adrpo
  Generate a graphviz file out of the connection graph"
  input String modelNameQualified;
  input DefiniteRoots definiteRoots;
  input PotentialRoots potentialRoots;
  input UniqueRoots uniqueRoots;
  input Edges branches;
  input DaeEdges connections;
  input DefiniteRoots finalRoots;
  input DaeEdges broken;
  output String brokenConnectsViaGraphViz;
algorithm
  brokenConnectsViaGraphViz := matchcontinue(modelNameQualified, definiteRoots, potentialRoots, uniqueRoots, branches, connections, finalRoots, broken)
    local
      String fileName, i, nrDR, nrPR, nrUR, nrBR, nrCO, nrFR, nrBC, timeStr,  infoNodeStr, brokenConnects;
      Real tStart, tEnd, t;
      IOStream.IOStream graphVizStream;
      list<String> infoNode;

    // don't do anything if we don't have +d=cgraphGraphVizFile or +d=cgraphGraphVizShow
    case(_, _, _, _, _, _, _, _)
      equation
        false = boolOr(Flags.isSet(Flags.CGRAPH_GRAPHVIZ_FILE), Flags.isSet(Flags.CGRAPH_GRAPHVIZ_SHOW));
      then
        "";

    case(_, _, _, _, _, _, _, _)
      equation
        tStart = clock();
        i = "\t";
        fileName = stringAppend(modelNameQualified, ".gv");
        // create a stream
        graphVizStream = IOStream.create(fileName, IOStream.LIST());
        nrDR = intString(listLength(definiteRoots));
        nrPR = intString(listLength(potentialRoots));
        nrUR = intString(listLength(uniqueRoots));
        nrBR = intString(listLength(branches));
        nrCO = intString(listLength(connections));
        nrFR = intString(listLength(finalRoots));
        nrBC = intString(listLength(broken));

        infoNode =
        {
          "// Generated by OpenModelica. \n",
          "// Overconstrained connection graph for model: \n//    ", modelNameQualified, "\n",
          "// \n",
          "// Summary: \n",
          "//   Roots:              ", nrDR, "\n",
          "//   Potential Roots:    ", nrPR, "\n",
          "//   Unique Roots:       ", nrUR, "\n",
          "//   Branches:           ", nrBR, "\n",
          "//   Connections:        ", nrCO, "\n",
          "//   Final Roots:        ", nrFR, "\n",
          "//   Broken Connections: ", nrBC, "\n"
        };
        infoNodeStr = stringAppendList(infoNode);
        // replace \n with \\l (left align), replace \t with " "
        infoNodeStr = System.stringReplace(infoNodeStr, "\n", "\\l"); infoNodeStr = System.stringReplace(infoNodeStr, "\t", " ");
        // replace / with ""
        infoNodeStr = System.stringReplace(infoNodeStr, "/", "");

        // output header
        graphVizStream = IOStream.appendList(graphVizStream,infoNode);
        // output command to be used
        // output graphviz header
        graphVizStream = IOStream.appendList(graphVizStream,{"\n\n"});
        graphVizStream = IOStream.appendList(graphVizStream, {"graph \"", modelNameQualified, "\"\n{\n\n"});

        // output global settings
        graphVizStream = IOStream.appendList(graphVizStream, {i, "overlap=false;\n"});
        graphVizStream = IOStream.appendList(graphVizStream, {i, "layout=dot;\n\n"});

        // output settings for nodes
        graphVizStream = IOStream.appendList(graphVizStream, {i, "node [",
           "fillcolor = \"lightsteelblue1\", ",
           "shape = box, ",
           "style = \"bold, filled\", ",
           "rank = \"max\"","]\n\n"});
        // output settings for edges
        graphVizStream = IOStream.appendList(graphVizStream, {i, "edge [",
           "color = \"black\", ",
           "style = bold",
           "]\n\n"});

        // output summary node
        graphVizStream = IOStream.appendList(graphVizStream, {i, "graph [fontsize=20, fontname = \"Courier Bold\" label= \"\\n\\n", infoNodeStr, "\", size=\"6,6\"];\n", i});

        // output definite roots
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Definite Roots (Connections.root)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, List.map1(definiteRoots, graphVizDefiniteRoot, finalRoots));
        // output potential roots
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Potential Roots (Connections.potentialRoot)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, List.map1(potentialRoots, graphVizPotentialRoot, finalRoots));

        // output branches
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Branches (Connections.branch)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, List.map(branches, graphVizEdge));

        // output connections
        graphVizStream = IOStream.appendList(graphVizStream, {"\n", i, "// Connections (connect)", "\n", i});
        graphVizStream = IOStream.appendList(graphVizStream, List.map1(connections, graphVizDaeEdge, broken));

        // output graphviz footer
        graphVizStream = IOStream.appendList(graphVizStream, {"\n}\n"});
        tEnd = clock();
        t = tEnd - tStart;
        timeStr = realString(t);
        graphVizStream = IOStream.appendList(graphVizStream, {"\n\n\n// graph generation took: ", timeStr, " seconds\n"});
        System.writeFile(fileName, IOStream.string(graphVizStream));
        Debug.traceln("GraphViz with connection graph for model: " + modelNameQualified + " was writen to file: " + fileName);
        brokenConnects = showGraphViz(fileName, modelNameQualified);
      then
        brokenConnects;

  end matchcontinue;
end generateGraphViz;

protected function showGraphViz
  input String fileNameGraphViz;
  input String modelNameQualified;
  output String brokenConnectsViaGraphViz;
algorithm
  brokenConnectsViaGraphViz := matchcontinue(fileNameGraphViz, modelNameQualified)
    local
      String leftyCMD, fileNameTraceRemovedConnections, omhome, brokenConnects;
      Integer leftyExitStatus;

    // do not start graphviz if we don't have +d=cgraphGraphVizShow
    case (_, _)
      equation
        false = Flags.isSet(Flags.CGRAPH_GRAPHVIZ_SHOW);
      then
        "";

    else
      equation
        fileNameTraceRemovedConnections = modelNameQualified + "_removed_connections.txt";
        Debug.traceln("Tyring to start GraphViz *lefty* to visualize the graph. You need to have lefty in your PATH variable");
        Debug.traceln("Make sure you quit GraphViz *lefty* via Right Click->quit to be sure the process will be exited.");
        Debug.traceln("If you quit the GraphViz *lefty* window via X, please kill the process in task manager to continue.");
        omhome = Settings.getInstallationDirectoryPath();
        omhome = System.stringReplace(omhome, "\"", "");
        // omhome = System.stringReplace(omhome, "\\", "/");

        // create a lefty command and execute it
        leftyCMD = "load('" + omhome + "/share/omc/scripts/openmodelica.lefty');" + "openmodelica.init();openmodelica.createviewandgraph('" +
            fileNameGraphViz + "','file',null,null);txtview('off');";
        Debug.traceln("Running command: " + "lefty -e " + leftyCMD + " > " + fileNameTraceRemovedConnections);
        // execute lefty
        leftyExitStatus = System.systemCall("lefty -e " + leftyCMD, fileNameTraceRemovedConnections);
        // show the exit status
        Debug.traceln("GraphViz *lefty* exited with status:" + intString(leftyExitStatus));
        brokenConnects = System.readFile(fileNameTraceRemovedConnections);
        Debug.traceln("GraphViz OpenModelica assistant returned the following broken connects: " + brokenConnects);
      then
        brokenConnects;
  end matchcontinue;
end showGraphViz;

public function removeBrokenConnects
"@author adrpo:
 this function BROKEN removes the connects from the connection set
 and keeps the CONNECTED ones.
 Basically is implmented like this:
 1. remove all the broken connects from the inConnects -> newConnects
 2. add all the connected connects BACK to newConnects"
  input list<Connect.ConnectorElement> inConnects;
  input DaeEdges inConnected;
  input DaeEdges inBroken;
  output list<Connect.ConnectorElement> outConnects;
algorithm
  outConnects := match(inConnects, inConnected, inBroken)
    local
      list<DAE.ComponentRef> toRemove, toKeep, intersect;
      list<Connect.ConnectorElement> cset;

    // if we have no broken then we don't care!
    case (_, _, {}) then inConnects;

    // if we have nothing toRemove then we don't care!
    case (_, _, _)
      equation
        toRemove = filterFromSet(inConnects, inBroken, {});

        if listEmpty(toRemove)
        then
          cset = inConnects;
        else
          toKeep = filterFromSet(inConnects, inConnected, {});
          intersect = List.intersectionOnTrue(toRemove, toKeep, ComponentReference.crefEqualNoStringCompare);

          if Flags.isSet(Flags.CGRAPH)
          then
            Debug.traceln("- ConnectionGraph.removeBrokenConnects: keep: " +
              stringDelimitList(List.map(toKeep, ComponentReference.printComponentRefStr), ", "));
            Debug.traceln("- ConnectionGraph.removeBrokenConnects: delete: " +
              stringDelimitList(List.map(toRemove, ComponentReference.printComponentRefStr), ", "));
            Debug.traceln("- ConnectionGraph.removeBrokenConnects: allow = remove - keep: " +
              stringDelimitList(List.map(intersect, ComponentReference.printComponentRefStr), ", "));
          end if;

          toRemove = List.setDifference(toRemove, intersect);

          if Flags.isSet(Flags.CGRAPH) then
            Debug.traceln("- ConnectionGraph.removeBrokenConnects: allow - delete: " +
              stringDelimitList(List.map(toRemove, ComponentReference.printComponentRefStr), ", "));
          end if;

          cset = removeFromConnects(inConnects, toRemove);
        end if;

      then cset;

  end match;
end removeBrokenConnects;

protected function filterFromSet
"@author: adrpo
 given an EQU set filter the given DaeEdges"
  input list<Connect.ConnectorElement> inConnects;
  input DaeEdges inFilter;
  input list<DAE.ComponentRef> inAcc;
  output list<DAE.ComponentRef> filteredCrefs;
algorithm
  filteredCrefs := matchcontinue(inConnects, inFilter, inAcc)
    local
      DAE.ComponentRef c1, c2;
      DaeEdges rest;
      list<DAE.ComponentRef> filtered;

    case (_, {}, _) then List.unique(inAcc);

    // both are there and append crefs to the filter list!
    case (_, (c1, c2, _)::rest, _)
      equation
        true = ConnectUtil.isReferenceInConnects(inConnects, c1);
        true = ConnectUtil.isReferenceInConnects(inConnects, c2);
        if Flags.isSet(Flags.CGRAPH) then
          Debug.traceln("- ConnectionGraph.removeBroken: removed connect(" + ComponentReference.printComponentRefStr(c1) + ", " + ComponentReference.printComponentRefStr(c2) + ")");
        end if;
        filtered = filterFromSet(inConnects, rest, c1::c2::inAcc);
      then
        filtered;

    // some are not there, move forward ...
    case (_, _::rest, _)
      equation
        filtered = filterFromSet(inConnects, rest, inAcc);
      then
        filtered;
  end matchcontinue;
end filterFromSet;

protected function removeFromConnects
  input list<Connect.ConnectorElement> inConnects;
  input list<DAE.ComponentRef> inToRemove;
  output list<Connect.ConnectorElement> outConnects;
algorithm
  outConnects := match(inConnects, inToRemove)
    local
      DAE.ComponentRef c;
      list<DAE.ComponentRef> rest;
      list<Connect.ConnectorElement> cset;

    case (_, {}) then inConnects;

    case (cset, c::rest)
      equation
        (cset, true) = ConnectUtil.removeReferenceFromConnects(cset, c, {});
        cset = removeFromConnects(cset, rest);
      then
        cset;
  end match;
end removeFromConnects;

public function addBrokenEqualityConstraintEquations
"@author: adrpo
 adds all the equalityConstraint equations from broken connections"
  input DAE.DAElist inDAE;
  input DaeEdges inBroken;
  output DAE.DAElist outDAE;
algorithm
  outDAE := matchcontinue(inDAE, inBroken)
    local
      list<DAE.Element> equalityConstraintElements;
      DAE.DAElist dae;

    case (_, {}) then inDAE;

    else
      equation
        equalityConstraintElements = List.flatten(List.map(inBroken, Util.tuple33));
        dae = DAEUtil.joinDaes(DAE.DAE(equalityConstraintElements), inDAE);
      then
        dae;

  end matchcontinue;
end addBrokenEqualityConstraintEquations;

annotation(__OpenModelica_Interface="frontend");
end ConnectionGraph;
